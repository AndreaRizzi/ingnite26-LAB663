# Post-Build > Execute Script in Cloud Platform > Azure > PowerShell; blocking.
# Run before the VM deployment. Paste this complete file into the action editor.
# Requires subscription-level provider read/register permission, not Entra directory read.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$tenantId = '@lab.CloudSubscription.TenantId'
$subscriptionId = '@lab.CloudSubscription.Id'
$clientId = '@lab.CloudSubscription.AppId'
$clientSecret = '@lab.CloudSubscription.AppSecret'
$tokenPrefix = '@' + 'lab.'
$headers = $null
$token = $null
$body = $null
$providers = @(
    'Microsoft.CognitiveServices'
    'Microsoft.Insights'
    'Microsoft.OperationalInsights'
    'Microsoft.AlertsManagement'
)

function Invoke-ProviderRequest {
    param(
        [Parameter(Mandatory)][ValidateSet('Get', 'Post')][string]$Method,
        [Parameter(Mandatory)][string]$Namespace
    )

    $remaining = [int][Math]::Floor(($deadline - [DateTime]::UtcNow).TotalSeconds)
    if ($remaining -le 0) { throw 'Provider registration exceeded eight minutes. Review the subscription provider states before retrying.' }
    $uri = "https://management.azure.com/subscriptions/$subscriptionId/providers/$Namespace"
    if ($Method -eq 'Post') { $uri += '/register' }
    $uri += '?api-version=2021-04-01'
    try {
        return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers `
            -TimeoutSec ([Math]::Min(30, $remaining))
    }
    catch {
        $status = 0
        if ($_.Exception.PSObject.Properties['Response'] -and $_.Exception.Response) {
            $status = [int]$_.Exception.Response.StatusCode
        }
        if ($status -eq 403) {
            throw "Access denied for $Method $Namespace (HTTP 403). The Skillable subscription application needs subscription-level provider read/register permission. Ask the subscription administrator to register the providers or authorize this action."
        }
        throw "Azure provider request failed for $Method $Namespace (HTTP $status; 0 means no HTTP response). Check the cloud-action connection and subscription access. No success was recorded."
    }
}

function Get-ProviderState {
    param([Parameter(Mandatory)][string]$Namespace)

    $provider = Invoke-ProviderRequest -Method Get -Namespace $Namespace
    if (-not $provider -or -not $provider.PSObject.Properties['registrationState'] -or
        -not $provider.registrationState) {
        throw "Azure returned no registration state for $Namespace."
    }
    $state = [string]$provider.registrationState
    if ($state -notin @('Registered', 'Registering', 'NotRegistered', 'Unregistered')) {
        throw "Unexpected registration state for ${Namespace}: $state. Review it before retrying."
    }
    return $state
}

try {
    foreach ($value in @($tenantId, $subscriptionId, $clientId, $clientSecret)) {
        if ([string]::IsNullOrWhiteSpace($value) -or $value.Contains($tokenPrefix)) {
            throw 'Skillable did not resolve the allocated subscription credentials. Check the CloudSubscription settings.'
        }
    }
    foreach ($value in @($tenantId, $subscriptionId, $clientId)) {
        $id = [guid]::Empty
        if (-not [guid]::TryParse($value, [ref]$id) -or $id -eq [guid]::Empty) {
            throw 'TenantId, subscription Id and AppId must be valid GUIDs.'
        }
    }

    $body = @{
        grant_type = 'client_credentials'
        client_id = $clientId
        client_secret = $clientSecret
        scope = 'https://management.azure.com/.default'
    }
    try {
        $token = Invoke-RestMethod -Method Post `
            -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
            -ContentType 'application/x-www-form-urlencoded' -Body $body -TimeoutSec 60
    }
    catch {
        throw 'Azure authentication failed. Check the Skillable subscription application, secret and tenant. Authentication response details were withheld to protect credentials.'
    }
    if (-not $token -or -not $token.PSObject.Properties['access_token'] -or -not $token.access_token) {
        throw 'Azure authentication returned no access token.'
    }
    $headers = @{ Authorization = "Bearer $($token.access_token)" }
    $deadline = [DateTime]::UtcNow.AddMinutes(8)
    $pending = @()
    foreach ($namespace in $providers) {
        $state = Get-ProviderState $namespace
        Write-Host "${namespace}: $state"
        if ($state -eq 'Registered') { continue }
        if ($state -ne 'Registering') {
            Invoke-ProviderRequest -Method Post -Namespace $namespace | Out-Null
            Write-Host "Registration requested: $namespace"
        }
        $pending += $namespace
    }

    while ($pending.Count) {
        $remainingProviders = @()
        foreach ($namespace in $pending) {
            $state = Get-ProviderState $namespace
            Write-Host "${namespace}: $state"
            if ($state -ne 'Registered') { $remainingProviders += $namespace }
        }
        $pending = $remainingProviders
        if ($pending.Count) {
            if ([DateTime]::UtcNow -ge $deadline) {
                throw "Provider registration timed out. Still pending: $($pending -join ', '). Do not start the VM deployment."
            }
            Start-Sleep -Seconds 10
        }
    }
    Write-Host 'SUCCEEDED: all four LAB663 Azure resource providers are registered. The VM deployment can now run.'
}
finally {
    # Registration persists in the subscription; credentials remain only in this action's memory.
    Remove-Variable -Name headers, token, body, clientSecret -ErrorAction SilentlyContinue
}
