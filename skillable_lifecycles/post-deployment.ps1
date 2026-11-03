[CmdletBinding()]
param(
    [Parameter(Mandatory)][guid]$TenantId,
    [Parameter(Mandatory)][guid]$SubscriptionId,
    [Parameter(Mandatory)][string]$ResourceGroup,
    [Parameter(Mandatory)][string]$Location,
    [Parameter(Mandatory)][string]$LabInstanceId,
    [Parameter(Mandatory)][guid]$LearnerObjectId,
    [Parameter(Mandatory)][guid]$BootstrapObjectId,
    [Parameter(Mandatory)][string]$ResourceDeploymentName,
    [string]$RepoRoot = (Split-Path $PSScriptRoot -Parent),
    [string]$Python = (Join-Path $RepoRoot '.venv\Scripts\python.exe'),
    [switch]$UseCurrentAzureLogin,
    [switch]$InfrastructureOnly
)

. (Join-Path $PSScriptRoot 'common.ps1')
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$manifestPath = Get-LabManifestPath $RepoRoot $LabInstanceId
$Location = $Location.ToLowerInvariant()
if ($Location -ne 'eastus') {
    throw 'LAB663 requires an eastus resource deployment. Existing resources in another region are not migrated by this script.'
}
$manifest = $null

if (Test-Path -LiteralPath $manifestPath) {
    $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    if ($manifest.schemaVersion -ne 1 -or $manifest.labInstanceId -cne $LabInstanceId -or
        $manifest.subscriptionId -ne "$SubscriptionId" -or $manifest.tenantId -ne "$TenantId" -or
        $manifest.resourceGroup -ne $ResourceGroup -or $manifest.location -ne $Location -or
        $manifest.learnerObjectId -ne "$LearnerObjectId" -or $manifest.deploymentName -ne $ResourceDeploymentName -or
        $manifest.ownsResourceGroup) {
        throw 'The saved lifecycle belongs to different deployment settings. It was not changed.'
    }
    if ($manifest.phase -in @('deleting', 'deleted', 'purge-pending')) {
        throw 'This lab instance has entered teardown. Use a new lab instance ID.'
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot '.env.sample') -PathType Leaf)) {
    throw 'The checkout is missing .env.sample. Restore it before running the deployment lifecycle.'
}
if (-not $InfrastructureOnly) {
    & (Join-Path $PSScriptRoot 'setup.ps1') -RepoRoot $RepoRoot -Python $Python -CheckOnly -SkipBicep
}
else {
    Write-Warning 'Infrastructure-only rehearsal: notebook prerequisites and agent setup are NOT being verified.'
}

try {
    Start-LabAuthentication -TenantId "$TenantId" -SubscriptionId "$SubscriptionId" `
        -StateDirectory (Split-Path $manifestPath -Parent) -UseCurrentAzureLogin:$UseCurrentAzureLogin

    Write-Host 'Reading the completed Skillable resource-template deployment. No Azure resources will be deployed.'
    $deployment = Invoke-LabAz @('deployment', 'group', 'show', '--resource-group', $ResourceGroup,
        '--subscription', "$SubscriptionId", '--name', $ResourceDeploymentName, '--output', 'json') | ConvertFrom-Json
    if ($deployment.properties.provisioningState -ne 'Succeeded') {
        throw 'The resource-template deployment has not succeeded. Repair it before preparing the VM.'
    }
    $outputs = $deployment.properties.outputs
    foreach ($name in @('accountName', 'projectName', 'projectEndpoint', 'applicationInsightsName',
        'chatModelDeploymentNames', 'managedResourceIds', 'labInstanceId', 'learnerObjectId',
        'bootstrapObjectId', 'location', 'capacity')) {
        if (-not $outputs -or -not $outputs.PSObject.Properties[$name] -or
            -not $outputs.$name.PSObject.Properties['value'] -or $null -eq $outputs.$name.value) {
            throw "The resource deployment is missing output $name. Deploy infra\skillable.bicep, not infra\main.bicep."
        }
    }
    if ($outputs.labInstanceId.value -cne $LabInstanceId -or
        $outputs.learnerObjectId.value -ne "$LearnerObjectId" -or
        $outputs.bootstrapObjectId.value -ne "$BootstrapObjectId" -or
        $outputs.location.value -ne $Location -or $outputs.capacity.value -lt 1) {
        throw 'The resource deployment belongs to a different lab instance, identity or region. Local settings were not changed.'
    }
    $chatModels = @($outputs.chatModelDeploymentNames.value)
    if ($chatModels.Count -ne 2 -or @($chatModels | Select-Object -Unique).Count -ne 2) {
        throw 'The resource deployment must publish exactly two distinct chat deployment names.'
    }
    $scope = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup"
    $accountId = "$scope/providers/Microsoft.CognitiveServices/accounts/$($outputs.accountName.value)"
    $appInsightsId = "$scope/providers/Microsoft.Insights/components/$($outputs.applicationInsightsName.value)"
    $managedIds = @($outputs.managedResourceIds.value)
    $idPattern = '^' + [regex]::Escape($scope) +
        '/providers/(Microsoft\.CognitiveServices/accounts|Microsoft\.Insights/components|Microsoft\.OperationalInsights/workspaces)/[^/]+$'
    if ($managedIds.Count -ne 3 -or @($managedIds | Select-Object -Unique).Count -ne 3 -or
        $accountId -notin $managedIds -or $appInsightsId -notin $managedIds -or
        @($managedIds | Where-Object { $_ -match '/providers/Microsoft\.OperationalInsights/workspaces/[^/]+$' }).Count -ne 1 -or
        @($managedIds | Where-Object { $_ -notmatch $idPattern }).Count) {
        throw 'The deployment resource IDs do not match the allocated group and expected LAB663 resources.'
    }
    $endpoint = "https://$($outputs.accountName.value).services.ai.azure.com/api/projects/$($outputs.projectName.value)"
    if ($outputs.projectEndpoint.value -cne $endpoint -or $outputs.projectName.value -match '[/\\]') {
        throw 'The project endpoint does not match the deployed Foundry account and project.'
    }
    foreach ($id in @($managedIds) + @("$accountId/projects/$($outputs.projectName.value)")) {
        $resource = Invoke-LabAz @('resource', 'show', '--ids', $id, '--subscription', "$SubscriptionId",
            '--output', 'json') | ConvertFrom-Json
        Assert-LabResourceOwnership $resource $LabInstanceId
        if ($resource.location -ne $Location -or $resource.id -ne $id) {
            throw 'A deployed resource has an unexpected region or resource ID.'
        }
    }
    if ($manifest -and ($manifest.capacity -ne $outputs.capacity.value -or
        $manifest.accountName -ne $outputs.accountName.value -or $manifest.projectEndpoint -cne $endpoint -or
        @($manifest.managedResourceIds | Where-Object { $_ -notin $managedIds }).Count -or
        @($managedIds | Where-Object { $_ -notin $manifest.managedResourceIds }).Count)) {
        throw 'The resource deployment changed since this instance was recorded. Preserve the lab state before proceeding.'
    }

    if (-not $manifest) {
        $manifest = [pscustomobject]@{
            schemaVersion = 1; labInstanceId = $LabInstanceId; tenantId = "$TenantId"
            subscriptionId = "$SubscriptionId"; resourceGroup = $ResourceGroup; location = $Location
            learnerObjectId = "$LearnerObjectId"; capacity = $outputs.capacity.value
            ownsResourceGroup = $false; deploymentName = $ResourceDeploymentName
            phase = 'infrastructure-ready'; managedResourceIds = $managedIds
            accountName = $outputs.accountName.value; projectEndpoint = $endpoint
        }
        Write-LabJson $manifestPath $manifest
    }
    Complete-LabDeployment -RepoRoot $RepoRoot -ManifestPath $manifestPath -Manifest $manifest `
        -Outputs $outputs -ChatModelNames $chatModels -Python $Python -InfrastructureOnly:$InfrastructureOnly
}
finally {
    Stop-LabAuthentication
}
