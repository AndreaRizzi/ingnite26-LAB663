[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string]$LabInstanceId,
    [Parameter(Mandatory)][string]$ConfirmInstanceId,
    [string]$RepoRoot = (Split-Path $PSScriptRoot -Parent),
    [switch]$UseCurrentAzureLogin,
    [switch]$DeleteResourceGroup,
    [switch]$PurgeDeletedAccount
)

. (Join-Path $PSScriptRoot 'common.ps1')
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$manifestPath = Get-LabManifestPath $RepoRoot $LabInstanceId
if ($ConfirmInstanceId -cne $LabInstanceId) { throw 'ConfirmInstanceId must exactly match the requested lab instance.' }
if (-not (Test-Path -LiteralPath $manifestPath)) { throw 'No lifecycle manifest exists. Refusing to guess which resources to delete.' }
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
if ($manifest.labInstanceId -cne $LabInstanceId -or $manifest.schemaVersion -ne 1) { throw 'The lifecycle manifest does not match this request.' }
$scope = "/subscriptions/$($manifest.subscriptionId)/resourceGroups/$($manifest.resourceGroup)"
$ownedIds = @()
$managedIdPattern = '^' + [regex]::Escape($scope) +
    '/providers/(Microsoft\.CognitiveServices/accounts|Microsoft\.Insights/components|Microsoft\.OperationalInsights/workspaces)/[^/]+$'
foreach ($id in $manifest.managedResourceIds) {
    if ($id -notmatch $managedIdPattern) {
        throw 'A manifest resource ID has an unexpected scope or resource type. Refusing teardown.'
    }
}

function Get-DeletedLabAccount {
    $deleted = @(Invoke-LabAz @('cognitiveservices', 'account', 'list-deleted',
        '--subscription', $manifest.subscriptionId, '--output', 'json') | ConvertFrom-Json)
    $groupSegment = '/resourceGroups/' + [regex]::Escape($manifest.resourceGroup) + '/'
    return @($deleted | Where-Object {
        $_.name -eq $manifest.accountName -and $_.location -eq $manifest.location -and $_.id -match $groupSegment
    })
}

try {
    Start-LabAuthentication -TenantId $manifest.tenantId -SubscriptionId $manifest.subscriptionId `
        -StateDirectory (Split-Path $manifestPath -Parent) -UseCurrentAzureLogin:$UseCurrentAzureLogin
    $exists = (Invoke-LabAz @('group', 'exists', '--name', $manifest.resourceGroup,
        '--subscription', $manifest.subscriptionId, '--output', 'tsv')) -eq 'true'
    if ($exists) {
        $resources = @(Invoke-LabAz @('resource', 'list', '--resource-group', $manifest.resourceGroup,
            '--subscription', $manifest.subscriptionId, '--output', 'json') | ConvertFrom-Json)
        $owned = @($resources | Where-Object {
            $_.PSObject.Properties['tags'] -and $_.tags -and
            $_.tags.PSObject.Properties['lab663Instance'] -and $_.tags.lab663Instance -eq $LabInstanceId
        })
        $ownedIds = @($owned | ForEach-Object { $_.id })
        $allowedTypes = @('Microsoft.CognitiveServices/accounts', 'Microsoft.CognitiveServices/accounts/projects',
            'Microsoft.Insights/components', 'Microsoft.OperationalInsights/workspaces')
        foreach ($resource in $owned) {
            if (-not $resource.id.StartsWith("$scope/", [StringComparison]::OrdinalIgnoreCase) -or $resource.type -notin $allowedTypes) {
                throw "Unexpected resource in the deletion set: $($resource.id)"
            }
            Assert-LabResourceOwnership $resource $LabInstanceId
        }
        # The tagged set also covers a deployment that stopped before publishing its outputs.
        $accounts = @($owned | Where-Object { $_.type -eq 'Microsoft.CognitiveServices/accounts' })
        if ($accounts.Count -gt 1) { throw 'More than one Foundry account is tagged for this instance. Review the resources manually.' }
        if ($accounts.Count -eq 1) {
            $manifest.accountName = $accounts[0].name
            if (-not $WhatIfPreference) { Write-LabJson $manifestPath $manifest }
        }
        foreach ($id in $manifest.managedResourceIds) {
            $resource = $resources | Where-Object { $_.id -eq $id }
            if ($resource) { Assert-LabResourceOwnership $resource $LabInstanceId }
        }

        $appInsightsIds = @($manifest.managedResourceIds | Where-Object { $_ -like '*/providers/Microsoft.Insights/components/*' })
        $appInsightsIds += @($owned | Where-Object { $_.type -eq 'Microsoft.Insights/components' } | ForEach-Object { $_.id })
        $generatedAlertIds = @()
        foreach ($alert in $resources | Where-Object { $_.type -eq 'microsoft.alertsmanagement/smartDetectorAlertRules' }) {
            $expectedNames = @($appInsightsIds | ForEach-Object { "Failure Anomalies - $($_.Split('/')[-1])" })
            if ($alert.name -in $expectedNames) {
                $details = Invoke-LabAz @('resource', 'show', '--ids', $alert.id,
                    '--subscription', $manifest.subscriptionId, '--output', 'json') | ConvertFrom-Json
                if (@($details.properties.scope).Count -eq 1 -and $details.properties.scope[0] -in $appInsightsIds) {
                    $generatedAlertIds += $alert.id
                }
            }
        }

        if ($DeleteResourceGroup) {
            if (-not $manifest.ownsResourceGroup) { throw 'This group belongs to Skillable, not this lifecycle. Omit DeleteResourceGroup.' }
            $group = Invoke-LabAz @('group', 'show', '--name', $manifest.resourceGroup,
                '--subscription', $manifest.subscriptionId, '--output', 'json') | ConvertFrom-Json
            Assert-LabResourceOwnership $group $LabInstanceId
            $unexpected = @($resources | Where-Object { $_.id -notin $ownedIds -and $_.id -notin $generatedAlertIds })
            if ($unexpected.Count) { throw 'The group now contains resources outside this lab. Refusing group deletion.' }
            if ($PSCmdlet.ShouldProcess($scope, 'Delete the lifecycle-owned lab resource group')) {
                Invoke-LabAz @('group', 'delete', '--name', $manifest.resourceGroup,
                    '--subscription', $manifest.subscriptionId, '--yes') | Out-Null
            }
        }
        else {
            foreach ($id in $generatedAlertIds) {
                if ($PSCmdlet.ShouldProcess($id, 'Delete the generated alert for this lab Application Insights resource')) {
                    Invoke-LabAz @('resource', 'delete', '--ids', $id, '--subscription', $manifest.subscriptionId) | Out-Null
                }
            }
            foreach ($type in @('Microsoft.CognitiveServices/accounts/projects', 'Microsoft.CognitiveServices/accounts',
                'Microsoft.Insights/components', 'Microsoft.OperationalInsights/workspaces')) {
                foreach ($resource in $owned | Where-Object { $_.type -eq $type }) {
                    if ($PSCmdlet.ShouldProcess($resource.id, 'Delete this tagged lab resource')) {
                        Invoke-LabAz @('resource', 'delete', '--ids', $resource.id, '--subscription', $manifest.subscriptionId) | Out-Null
                    }
                }
            }
        }
        $ownedIds += $generatedAlertIds
    }
    if ($WhatIfPreference) {
        if ($PurgeDeletedAccount -and $manifest.accountName) {
            $PSCmdlet.ShouldProcess($manifest.accountName, 'Permanently purge this lab account after deletion') | Out-Null
        }
        return
    }
    $stillExists = (Invoke-LabAz @('group', 'exists', '--name', $manifest.resourceGroup,
        '--subscription', $manifest.subscriptionId, '--output', 'tsv')) -eq 'true'
    if ($stillExists) {
        $remaining = @(Invoke-LabAz @('resource', 'list', '--resource-group', $manifest.resourceGroup,
            '--subscription', $manifest.subscriptionId, '--output', 'json') | ConvertFrom-Json)
        if ($remaining | Where-Object { $_.id -in $manifest.managedResourceIds -or $_.id -in $ownedIds }) {
            throw 'Some lab resources still exist. Teardown is not complete.'
        }
    }
    if ($PurgeDeletedAccount -and $manifest.accountName) {
        $alreadyVerified = $manifest.PSObject.Properties['purgeVerified'] -and $manifest.purgeVerified
        $manifest.phase = 'purge-pending'
        Write-LabJson $manifestPath $manifest
        $deadline = [DateTime]::UtcNow.AddMinutes(2)
        $match = @(Get-DeletedLabAccount)
        while (-not $match.Count -and -not $alreadyVerified -and [DateTime]::UtcNow -lt $deadline) {
            Write-Host 'Waiting for the deleted account record before verifying purge.'
            Start-Sleep -Seconds 10
            $match = @(Get-DeletedLabAccount)
        }
        if ($match.Count -gt 1) { throw 'More than one deleted account matched this instance. Review the records before purging.' }
        if ($match.Count) {
            if (-not $PSCmdlet.ShouldProcess($manifest.accountName, 'Permanently purge this lab account to release quota')) {
                throw 'Purge was not confirmed. The account remains soft-deleted.'
            }
            Invoke-LabAz @('cognitiveservices', 'account', 'purge', '--name', $manifest.accountName, '--location', $manifest.location,
                '--resource-group', $manifest.resourceGroup, '--subscription', $manifest.subscriptionId, '--output', 'none') | Out-Null
            $deadline = [DateTime]::UtcNow.AddMinutes(2)
            do {
                $remainingDeleted = @(Get-DeletedLabAccount)
                if (-not $remainingDeleted.Count) { break }
                Start-Sleep -Seconds 10
            } while ([DateTime]::UtcNow -lt $deadline)
            if ($remainingDeleted.Count) {
                throw 'The deleted Foundry account is still listed. Purge has not completed; retain the manifest and retry.'
            }
            $manifest | Add-Member -NotePropertyName purgeVerified -NotePropertyValue $true -Force
            Write-Host 'Confirmed: the lab account is no longer in the soft-deleted account list.'
        }
        elseif (-not $alreadyVerified) {
            throw 'No deleted account record appeared. Resource deletion finished, but purge is unverified. Retain the manifest and recheck before relying on released quota.'
        }
        else {
            Write-Host 'The previously verified account purge is still complete.'
        }
    }
    $manifest.phase = 'deleted'
    Write-LabJson $manifestPath $manifest
    Write-Host 'Recorded lab resources are deleted. Local .env, results and state were preserved; do not reuse them for a new project.'
}
finally {
    Stop-LabAuthentication
}
