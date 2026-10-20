# Post-Build: Execute Script in Cloud Platform; PowerShell; blocking.
# Paste this complete file into the matching Skillable cloud-platform action.
$ErrorActionPreference = 'Stop'
$statusResult = 'FAILED'
try {
    $learnerUserPrincipalName = @'
@lab.CloudPortalCredential(User1).Username
'@
    & {
        [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
        param(
            [Parameter(Mandatory)][ValidateSet('Prepare', 'Cleanup')][string]$Action,
            [Parameter(Mandatory)][guid]$TenantId,
            [Parameter(Mandatory)][guid]$GroupObjectId,
            [guid]$LearnerObjectId = [guid]::Empty,
            [string]$LearnerUserPrincipalName,
            [guid]$ServicePrincipalObjectId = [guid]::Empty,
            [string]$JobId,
            [guid]$RuleId = [guid]::Empty,
            [guid]$ConfirmLearnerObjectId = [guid]::Empty
        )
        
        $ErrorActionPreference = 'Stop'
        Set-StrictMode -Version Latest
        
        function Get-LabGraphHeaders {
            if (-not $env:LAB663_DIRECTORY_CLIENT_ID -or -not $env:LAB663_DIRECTORY_CLIENT_SECRET) {
                throw 'Supply LAB663_DIRECTORY_CLIENT_ID and LAB663_DIRECTORY_CLIENT_SECRET as process-only variables in this cloud action.'
            }
            $body = @{
                grant_type = 'client_credentials'
                client_id = $env:LAB663_DIRECTORY_CLIENT_ID
                client_secret = $env:LAB663_DIRECTORY_CLIENT_SECRET
                scope = 'https://graph.microsoft.com/.default'
            }
            $token = Invoke-RestMethod -Method Post `
                -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
                -ContentType 'application/x-www-form-urlencoded' -Body $body -TimeoutSec 60
            if (-not $token.access_token) { throw 'Microsoft Graph authentication returned no access token.' }
            return @{ Authorization = "Bearer $($token.access_token)" }
        }
        
        function Get-LabGroupMember {
            try {
                return Invoke-RestMethod -Method Get -Headers $headers -TimeoutSec 60 `
                    -Uri "https://graph.microsoft.com/v1.0/groups/$GroupObjectId/members/$LearnerObjectId"
            }
            catch {
                if ($_.Exception.PSObject.Properties['Response'] -and $_.Exception.Response -and
                    [int]$_.Exception.Response.StatusCode -eq 404) { return $null }
                throw
            }
        }

        function Get-LabLearnerObjectId {
            $userSegment = [Uri]::EscapeDataString($LearnerUserPrincipalName.Replace("'", "''"))
            $uri = "https://graph.microsoft.com/v1.0/users('$userSegment')?`$select=id,userPrincipalName"
            for ($attempt = 1; ; $attempt++) {
                try {
                    $user = Invoke-RestMethod -Method Get -Headers $headers -Uri $uri -TimeoutSec 60
                    break
                }
                catch {
                    $status = 0
                    if ($_.Exception.PSObject.Properties['Response'] -and $_.Exception.Response) {
                        $status = [int]$_.Exception.Response.StatusCode
                    }
                    if ($status -eq 403) {
                        throw 'The directory app cannot read the allocated learner. An administrator must consent Microsoft Graph User.Read.All for action 1.'
                    }
                    if ($status -ne 404) { throw }
                    if ($attempt -ge 8) {
                        throw 'The allocated learner was not found in Entra. Check the User1 credential alias, tenant and cloud fabric build sequence before rerunning action 1.'
                    }
                    Write-Host "Entra cannot see the allocated learner yet. Retrying in 15 seconds (attempt $attempt of 8)."
                    Start-Sleep -Seconds 15
                }
            }
            $id = [guid]::Empty
            if (-not $user -or -not $user.PSObject.Properties['id'] -or
                -not $user.PSObject.Properties['userPrincipalName'] -or
                [string]$user.userPrincipalName -ine $LearnerUserPrincipalName -or
                -not [guid]::TryParse([string]$user.id, [ref]$id) -or $id -eq [guid]::Empty) {
                throw 'Entra did not return a valid object ID for the exact allocated learner. No GitHub/Copilot access was changed.'
            }
            return $id
        }
        
        if ($TenantId -eq [guid]::Empty -or $GroupObjectId -eq [guid]::Empty) {
            throw 'TenantId and GroupObjectId must be real IDs, not an empty GUID.'
        }
        if ($Action -eq 'Prepare' -and
            ($ServicePrincipalObjectId -eq [guid]::Empty -or [string]::IsNullOrWhiteSpace($JobId) -or $RuleId -eq [guid]::Empty)) {
            throw 'Prepare requires the GitHub enterprise service principal OBJECT ID, synchronization job ID and rule ID.'
        }
        if ($Action -eq 'Prepare' -and $LearnerUserPrincipalName -notmatch '^[^@\s]+@[^@\s]+$') {
            throw 'Skillable must supply the allocated learner UPN through CloudPortalCredential(User1).Username. Check the credential alias and cloud fabric build sequence.'
        }
        if ($Action -eq 'Cleanup' -and
            ($LearnerObjectId -eq [guid]::Empty -or $ConfirmLearnerObjectId -ne $LearnerObjectId)) {
            throw 'ConfirmLearnerObjectId must match the learner whose GitHub/Copilot group membership will be removed.'
        }
        $learnerLabel = if ($Action -eq 'Prepare') { $LearnerUserPrincipalName } else { "$LearnerObjectId" }
        if (-not $PSCmdlet.ShouldProcess("learner $learnerLabel in group $GroupObjectId", "$Action GitHub/Copilot access")) {
            if (-not $WhatIfPreference) { throw 'The GitHub/Copilot access action was not confirmed.' }
            return
        }
        
        $headers = Get-LabGraphHeaders
        try {
            if ($Action -eq 'Prepare') {
                $LearnerObjectId = Get-LabLearnerObjectId
                # Save the exact identity before changing access, so teardown can recover a partial startup.
                Set-LabVariable -Name 'Lab663LearnerObjectId' -Value "$LearnerObjectId" -ErrorAction Stop
                Write-Host 'Resolved the allocated learner and recorded Lab663LearnerObjectId for later actions.'
            }
            $group = Invoke-RestMethod -Method Get -Headers $headers -TimeoutSec 60 `
                -Uri "https://graph.microsoft.com/v1.0/groups/${GroupObjectId}?`$select=id,securityEnabled,groupTypes,isAssignableToRole"
            if (-not $group.securityEnabled -or 'DynamicMembership' -in $group.groupTypes -or $group.isAssignableToRole) {
                throw 'Use a static, non-role-assignable security group dedicated to disposable Skillable learners.'
            }
            $member = Get-LabGroupMember
            if ($Action -eq 'Prepare' -and -not $member) {
                $body = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$LearnerObjectId" } | ConvertTo-Json
                Invoke-RestMethod -Method Post -Headers $headers -ContentType 'application/json' -Body $body -TimeoutSec 60 `
                    -Uri "https://graph.microsoft.com/v1.0/groups/$GroupObjectId/members/`$ref" | Out-Null
            }
            elseif ($Action -eq 'Cleanup' -and $member) {
                # The $ref suffix removes membership, never the directory user.
                Invoke-RestMethod -Method Delete -Headers $headers -TimeoutSec 60 `
                    -Uri "https://graph.microsoft.com/v1.0/groups/$GroupObjectId/members/$LearnerObjectId/`$ref" | Out-Null
            }
            $member = Get-LabGroupMember
            if (($Action -eq 'Prepare' -and -not $member) -or ($Action -eq 'Cleanup' -and $member)) {
                throw 'The membership change is not visible yet. Retry this idempotent action before continuing.'
            }
            if ($Action -eq 'Cleanup') {
                Write-Host 'The learner is no longer a member of the GitHub/Copilot entitlement group. Confirm downstream entitlement removal before recycling the account.'
                return
            }
        
            $body = @{
                parameters = @(
                    @{
                        subjects = @(@{ objectId = "$LearnerObjectId"; objectTypeName = 'User' })
                        ruleId = "$RuleId"
                    }
                )
            } | ConvertTo-Json -Depth 5
            $jobSegment = [Uri]::EscapeDataString($JobId)
            $response = Invoke-RestMethod -Method Post -Headers $headers -ContentType 'application/json' -Body $body -TimeoutSec 120 `
                -Uri "https://graph.microsoft.com/v1.0/servicePrincipals/$ServicePrincipalObjectId/synchronization/jobs/$jobSegment/provisionOnDemand"
            # HTTP 200 can contain a failed or out-of-scope provisioning result.
            $result = $response.key | ConvertFrom-Json
            $details = $response.value | ConvertFrom-Json
            $unchanged = $result.result -eq 'Skipped' -and $result.details.errorCode -eq 'RedundantExport'
            if ($result.result -ne 'Success' -and -not $unchanged) {
                throw 'Entra did not report successful provisioning or RedundantExport. Check the enterprise application provisioning logs before continuing.'
            }
            if ($details.statusInfo.status -ne $result.result -or
                -not $details.targetIdentity.id -or
                @($details.provisioningSteps | Where-Object { $_.status -in @('Failure', 'Failed') }).Count) {
                throw 'The provisioning result has no verified target identity or contains a failed step. Check the enterprise application provisioning logs.'
            }
            Write-Host 'Group membership is verified and Entra reports a provisioned target identity. Check actual GitHub/Copilot access before learner handover.'
        }
        finally {
            $headers.Clear()
        }
    } -Action Prepare `
        -TenantId '@lab.CloudSubscription.TenantId' `
        -GroupObjectId '@lab.Variable(Lab663LicenseGroupObjectId)' `
        -LearnerUserPrincipalName $learnerUserPrincipalName `
        -ServicePrincipalObjectId '@lab.Variable(Lab663GitHubServicePrincipalObjectId)' `
        -JobId '@lab.Variable(Lab663GitHubSyncJobId)' `
        -RuleId '@lab.Variable(Lab663GitHubSyncRuleId)' `
        -Confirm:$false
    $statusResult = 'SUCCEEDED'
}
finally {
    Remove-Item Env:\LAB663_DIRECTORY_CLIENT_ID, Env:\LAB663_DIRECTORY_CLIENT_SECRET -ErrorAction SilentlyContinue
    # Action 3 shows this result on the VM. Recording it never replaces this action's own error.
    try {
        Set-LabVariable -Name 'Lab663CopilotAccessStatus' -Value ('{0} at {1}' -f $statusResult, [DateTime]::UtcNow.ToString('u'))
    }
    catch {
        Write-Warning 'Lab663CopilotAccessStatus was not recorded. Check action 1 on the lab instance details page.'
    }
}
