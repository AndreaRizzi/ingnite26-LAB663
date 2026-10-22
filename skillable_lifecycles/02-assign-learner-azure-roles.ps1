# Post-Build: Execute Script in Cloud Platform; PowerShell; blocking. Add it after action 1.
# Paste this complete file into the matching Skillable cloud-platform action.
$ErrorActionPreference = 'Stop'
$env:LAB663_CLIENT_ID = '@lab.CloudSubscription.AppId'
$env:LAB663_CLIENT_SECRET = '@lab.CloudSubscription.AppSecret'
$statusResult = 'FAILED'
try {
    $learnerObjectId = [guid]::Empty
    if (-not [guid]::TryParse('@lab.Variable(Lab663LearnerObjectId)', [ref]$learnerObjectId) -or $learnerObjectId -eq [guid]::Empty) {
        throw 'Lab663LearnerObjectId is missing or invalid. Run the updated blocking action 1 first; it resolves the allocated learner and records this variable.'
    }
    & {
        [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
        param(
            [Parameter(Mandatory)][ValidateSet('Assign', 'Remove')][string]$Action,
            [Parameter(Mandatory)][guid]$TenantId,
            [Parameter(Mandatory)][guid]$SubscriptionId,
            [Parameter(Mandatory)][guid]$LearnerObjectId,
            [guid]$ConfirmLearnerObjectId = [guid]::Empty
        )

        $ErrorActionPreference = 'Stop'
        Set-StrictMode -Version Latest

        # Built-in role IDs never change. Display names can, so roles are never looked up by name.
        $assignRoles = [ordered]@{
            '53ca6127-db72-4b80-b1b0-d745d6d5456d' = 'Foundry User'
            '25fbc0a9-bd7c-42a3-aa1a-3b75d497ee68' = 'Cognitive Services Contributor'
        }
        # Cleanup also removes the Log Analytics Reader role that infra/modules/roles.bicep grants the learner.
        $removeRoles = [ordered]@{
            '53ca6127-db72-4b80-b1b0-d745d6d5456d' = 'Foundry User'
            '25fbc0a9-bd7c-42a3-aa1a-3b75d497ee68' = 'Cognitive Services Contributor'
            '73c42c96-874c-492b-b04d-ab87d138a893' = 'Log Analytics Reader'
        }
        $subscriptionScope = "/subscriptions/$SubscriptionId"
        $armRoot = 'https://management.azure.com'
        $apiVersion = 'api-version=2022-04-01'

        function Get-LabSubscriptionHeaders {
            param(
                [ValidateSet('https://management.azure.com', 'https://graph.microsoft.com')]
                [string]$Resource = 'https://management.azure.com'
            )
            $clientId = [guid]::Empty
            if (-not [guid]::TryParse($env:LAB663_CLIENT_ID, [ref]$clientId) -or $clientId -eq [guid]::Empty -or
                -not $env:LAB663_CLIENT_SECRET -or $env:LAB663_CLIENT_SECRET.StartsWith('@' + 'lab.')) {
                throw 'Supply the subscription application ID and secret in LAB663_CLIENT_ID and LAB663_CLIENT_SECRET.'
            }
            $body = @{
                grant_type = 'client_credentials'
                client_id = $env:LAB663_CLIENT_ID
                client_secret = $env:LAB663_CLIENT_SECRET
                scope = "$Resource/.default"
            }
            $token = Invoke-RestMethod -Method Post `
                -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
                -ContentType 'application/x-www-form-urlencoded' -Body $body -TimeoutSec 60
            if (-not ($token.PSObject.Properties['access_token'] -and $token.access_token)) {
                throw "Authentication for $Resource returned no access token."
            }
            return @{ Authorization = "Bearer $($token.access_token)" }
        }

        function Get-LabBootstrapObjectId {
            $graphHeaders = Get-LabSubscriptionHeaders -Resource 'https://graph.microsoft.com'
            try {
                # An application can read its own service principal without directory-wide read permissions.
                $appId = [guid]$env:LAB663_CLIENT_ID
                $principal = Invoke-RestMethod -Method Get -Headers $graphHeaders -TimeoutSec 60 `
                    -Uri "https://graph.microsoft.com/v1.0/servicePrincipals(appId='$appId')?`$select=id,appId"
                $id = [guid]::Empty
                if (-not $principal -or -not $principal.PSObject.Properties['id'] -or
                    -not $principal.PSObject.Properties['appId'] -or [string]$principal.appId -ne "$appId" -or
                    -not [guid]::TryParse([string]$principal.id, [ref]$id) -or $id -eq [guid]::Empty) {
                    throw 'Microsoft Graph did not return the object ID of the subscription application. No learner roles were changed.'
                }
                return $id
            }
            finally {
                $graphHeaders.Clear()
            }
        }

        function Get-LabArmError {
            param([Parameter(Mandatory)]$ErrorRecord)
            $status = 0
            $code = ''
            if ($ErrorRecord.Exception.PSObject.Properties['Response'] -and $ErrorRecord.Exception.Response) {
                $status = [int]$ErrorRecord.Exception.Response.StatusCode
            }
            if ($ErrorRecord.ErrorDetails -and $ErrorRecord.ErrorDetails.Message) {
                try {
                    $details = $ErrorRecord.ErrorDetails.Message | ConvertFrom-Json
                    if ($details.PSObject.Properties['error'] -and $details.error.PSObject.Properties['code']) {
                        $code = [string]$details.error.code
                    }
                }
                catch {
                    $code = ''
                }
            }
            return [pscustomobject]@{ Status = $status; Code = $code }
        }

        function Get-LabLearnerRoleAssignment {
            # The principal filter returns this learner's direct assignments at, above and below the subscription.
            $filter = [Uri]::EscapeDataString("principalId eq '$LearnerObjectId'")
            $uri = "$armRoot$subscriptionScope/providers/Microsoft.Authorization/roleAssignments?$apiVersion&`$filter=$filter"
            while ($uri) {
                $page = Invoke-RestMethod -Method Get -Headers $headers -Uri $uri -TimeoutSec 60
                foreach ($assignment in @($page.value)) {
                    $scope = [string]$assignment.properties.scope
                    $inSubscription = $scope.Equals($subscriptionScope, [StringComparison]::OrdinalIgnoreCase) -or
                        $scope.StartsWith("$subscriptionScope/", [StringComparison]::OrdinalIgnoreCase)
                    if ([string]$assignment.properties.principalId -eq "$LearnerObjectId" -and $inSubscription) {
                        [pscustomobject]@{
                            Id = [string]$assignment.id
                            Scope = $scope
                            RoleId = ([string]$assignment.properties.roleDefinitionId).Split('/')[-1].ToLowerInvariant()
                        }
                    }
                }
                $uri = if ($page.PSObject.Properties['nextLink'] -and $page.nextLink) { [string]$page.nextLink } else { '' }
            }
        }

        function New-LabRoleAssignmentName {
            param([Parameter(Mandatory)][string]$RoleId)
            # The same learner, subscription and role always get the same name, so reruns can't add duplicates.
            $sha = [Security.Cryptography.SHA256]::Create()
            try {
                $hash = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes("lab663|$SubscriptionId|$LearnerObjectId|$RoleId"))
            }
            finally {
                $sha.Dispose()
            }
            return [guid]::new([byte[]]$hash[0..15])
        }

        function Add-LabRoleAssignment {
            param([Parameter(Mandatory)][string]$RoleId)
            $name = New-LabRoleAssignmentName $RoleId
            $uri = "$armRoot$subscriptionScope/providers/Microsoft.Authorization/roleAssignments/${name}?$apiVersion"
            $body = @{
                properties = @{
                    roleDefinitionId = "$subscriptionScope/providers/Microsoft.Authorization/roleDefinitions/$RoleId"
                    principalId = "$LearnerObjectId"
                    principalType = 'User'
                }
            } | ConvertTo-Json -Depth 4
            for ($attempt = 1; ; $attempt++) {
                try {
                    Invoke-RestMethod -Method Put -Headers $headers -ContentType 'application/json' -Body $body -Uri $uri -TimeoutSec 60 | Out-Null
                    return
                }
                catch {
                    $armError = Get-LabArmError $_
                    # A conflict usually means the role is already assigned. The check after assignment decides.
                    if ($armError.Status -eq 409) { return }
                    if ($armError.Code -ne 'PrincipalNotFound' -or $attempt -ge 8) { throw }
                    Write-Host "Azure can't see the learner account yet. Retrying in 15 seconds (attempt $attempt of 8)."
                    Start-Sleep -Seconds 15
                }
            }
        }

        foreach ($id in @($TenantId, $SubscriptionId, $LearnerObjectId)) {
            if ($id -eq [guid]::Empty) { throw 'TenantId, SubscriptionId and LearnerObjectId must be real IDs, not an empty GUID.' }
        }
        if ($Action -eq 'Remove' -and $ConfirmLearnerObjectId -ne $LearnerObjectId) {
            throw 'ConfirmLearnerObjectId must match the learner whose Azure role assignments will be removed.'
        }

        $headers = Get-LabSubscriptionHeaders
        try {
            if ($Action -eq 'Assign') {
                if ($PSCmdlet.ShouldProcess('later LAB663 actions', 'Record the subscription service principal object ID')) {
                    $bootstrapObjectId = Get-LabBootstrapObjectId
                    Set-LabVariable -Name 'Lab663BootstrapObjectId' -Value "$bootstrapObjectId" -ErrorAction Stop
                    Write-Host 'Recorded Lab663BootstrapObjectId for action 3.'
                }
                elseif (-not $WhatIfPreference) {
                    throw 'Recording the deployment identity was not confirmed. No learner roles were changed.'
                }
                $existing = @(Get-LabLearnerRoleAssignment | Where-Object { $_.Scope -eq $subscriptionScope } | ForEach-Object { $_.RoleId })
                foreach ($roleId in @($assignRoles.Keys)) {
                    $roleName = $assignRoles[$roleId]
                    if ($existing -contains $roleId) {
                        Write-Host "$roleName is already assigned to the learner at subscription scope."
                        continue
                    }
                    if (-not $PSCmdlet.ShouldProcess("learner $LearnerObjectId at $subscriptionScope", "Assign $roleName")) {
                        if ($WhatIfPreference) { continue }
                        throw 'The learner role assignment was not confirmed.'
                    }
                    Add-LabRoleAssignment $roleId
                    Write-Host "Requested $roleName for the learner at subscription scope."
                }
                if ($WhatIfPreference) { return }

                for ($check = 1; ; $check++) {
                    $current = @(Get-LabLearnerRoleAssignment | Where-Object { $_.Scope -eq $subscriptionScope } | ForEach-Object { $_.RoleId })
                    $missing = @($assignRoles.Keys | Where-Object { $current -notcontains $_ } | ForEach-Object { $assignRoles[$_] })
                    if (-not $missing.Count) { break }
                    if ($check -ge 6) {
                        throw "Azure doesn't list these learner roles at subscription scope: $($missing -join ', '). Rerun this idempotent action, and check that the subscription application can create role assignments."
                    }
                    Start-Sleep -Seconds 10
                }
                Write-Host "SUCCEEDED: Azure lists Foundry User and Cognitive Services Contributor for learner $LearnerObjectId on subscription $SubscriptionId. New role assignments can take up to 10 minutes to apply."
                return
            }

            $targets = @(Get-LabLearnerRoleAssignment | Where-Object { $removeRoles.Contains($_.RoleId) })
            if (-not $targets.Count) {
                Write-Host "SUCCEEDED: learner $LearnerObjectId has no LAB663 roles in subscription $SubscriptionId. Nothing to remove."
                return
            }
            foreach ($assignment in $targets) {
                $label = "$($removeRoles[$assignment.RoleId]) at $($assignment.Scope)"
                if (-not $PSCmdlet.ShouldProcess("learner $LearnerObjectId", "Remove $label")) {
                    if ($WhatIfPreference) { continue }
                    throw 'The learner role removal was not confirmed.'
                }
                try {
                    Invoke-RestMethod -Method Delete -Headers $headers -Uri "$armRoot$($assignment.Id)?$apiVersion" -TimeoutSec 60 | Out-Null
                    Write-Host "Removed $label."
                }
                catch {
                    if ((Get-LabArmError $_).Status -ne 404) { throw }
                    Write-Host "$label was already removed."
                }
            }
            if ($WhatIfPreference) { return }

            for ($check = 1; ; $check++) {
                $remaining = @(Get-LabLearnerRoleAssignment | Where-Object { $removeRoles.Contains($_.RoleId) })
                if (-not $remaining.Count) { break }
                if ($check -ge 6) {
                    throw "Azure still lists $($remaining.Count) LAB663 role assignment(s) for the learner. Rerun this idempotent action before reusing the account or subscription."
                }
                Start-Sleep -Seconds 10
            }
            Write-Host "SUCCEEDED: Azure lists no LAB663 roles for learner $LearnerObjectId in subscription $SubscriptionId."
        }
        finally {
            $headers.Clear()
        }
    } -Action Assign `
        -TenantId '@lab.CloudSubscription.TenantId' `
        -SubscriptionId '@lab.CloudSubscription.Id' `
        -LearnerObjectId $learnerObjectId `
        -Confirm:$false
    $statusResult = 'SUCCEEDED'
}
finally {
    Remove-Item Env:\LAB663_CLIENT_ID, Env:\LAB663_CLIENT_SECRET -ErrorAction SilentlyContinue
    # Action 3 shows this result on the VM. Recording it never replaces this action's own error.
    try {
        Set-LabVariable -Name 'Lab663AzureRolesStatus' -Value ('{0} at {1}' -f $statusResult, [DateTime]::UtcNow.ToString('u'))
    }
    catch {
        Write-Warning 'Lab663AzureRolesStatus was not recorded. Check action 2 on the lab instance details page.'
    }
}
