# Tearing Down: Execute Script in Cloud Platform; PowerShell; blocking.
# Paste this complete file into the matching Skillable cloud-platform action.
$ErrorActionPreference = 'Stop'
try {
    & {
        [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
        param(
            [Parameter(Mandatory)][ValidateSet('Prepare', 'Cleanup')][string]$Action,
            [Parameter(Mandatory)][guid]$TenantId,
            [Parameter(Mandatory)][guid]$GroupObjectId,
            [Parameter(Mandatory)][guid]$LearnerObjectId,
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
        
        if ($Action -eq 'Prepare' -and
            ($ServicePrincipalObjectId -eq [guid]::Empty -or [string]::IsNullOrWhiteSpace($JobId) -or $RuleId -eq [guid]::Empty)) {
            throw 'Prepare requires the GitHub enterprise service principal OBJECT ID, synchronization job ID and rule ID.'
        }
        if ($Action -eq 'Cleanup' -and $ConfirmLearnerObjectId -ne $LearnerObjectId) {
            throw 'ConfirmLearnerObjectId must match the learner whose GitHub/Copilot group membership will be removed.'
        }
        if (-not $PSCmdlet.ShouldProcess("learner $LearnerObjectId in group $GroupObjectId", "$Action GitHub/Copilot access")) {
            if (-not $WhatIfPreference) { throw 'The GitHub/Copilot access action was not confirmed.' }
            return
        }
        
        $headers = Get-LabGraphHeaders
        try {
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
    } -Action Cleanup `
        -TenantId '@lab.CloudSubscription.TenantId' `
        -GroupObjectId '@lab.Variable(Lab663LicenseGroupObjectId)' `
        -LearnerObjectId '@lab.Variable(Lab663LearnerObjectId)' `
        -ConfirmLearnerObjectId '@lab.Variable(Lab663LearnerObjectId)' `
        -Confirm:$false
}
finally {
    Remove-Item Env:\LAB663_DIRECTORY_CLIENT_ID, Env:\LAB663_DIRECTORY_CLIENT_SECRET -ErrorAction SilentlyContinue
}
