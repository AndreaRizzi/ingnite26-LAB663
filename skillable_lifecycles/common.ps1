$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-LabAz {
    param([Parameter(Mandatory)][string[]]$Arguments)

    Get-Command az -ErrorAction Stop | Out-Null
    # Windows PowerShell can turn native stderr into a terminating error before we check the exit code.
    $ErrorActionPreference = 'Continue'
    $output = & az @Arguments --only-show-errors 2>&1
    if ($LASTEXITCODE -ne 0) {
        if ($Arguments[0] -eq 'login') {
            throw "Azure CLI authentication failed (exit $LASTEXITCODE). Check the lifecycle identity and tenant; login output was withheld to protect credentials."
        }
        throw "Azure CLI failed (exit $LASTEXITCODE): $($output -join [Environment]::NewLine)"
    }
    return ($output -join [Environment]::NewLine)
}

function Write-LabJson {
    param([string]$Path, [object]$Value)

    $json = $Value | ConvertTo-Json -Depth 30
    $temporaryPath = "$Path.tmp"
    [IO.File]::WriteAllText($temporaryPath, $json, [Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporaryPath -Destination $Path -Force -WhatIf:$false -Confirm:$false
}

function Write-LabEnvironment {
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][System.Collections.IDictionary]$Values
    )

    $samplePath = Join-Path $RepoRoot '.env.sample'
    if (-not (Test-Path -LiteralPath $samplePath -PathType Leaf)) {
        throw "Cannot find $samplePath. Restore the LAB663 environment template before deploying."
    }
    foreach ($key in $Values.Keys) {
        $value = [string]$Values[$key]
        if ($key -cnotmatch '^[A-Z][A-Z0-9_]+$' -or [string]::IsNullOrWhiteSpace($value) -or
            $value -match '[\r\n]' -or $value.Contains('@' + 'lab.')) {
            throw "No valid deployment value was supplied for $key. The existing .env was not changed."
        }
    }
    $sampleLines = [IO.File]::ReadAllLines($samplePath)
    $sampleKeys = @{}
    foreach ($line in $sampleLines) {
        if ($line -cmatch '^([A-Z][A-Z0-9_]+)=') {
            $key = $Matches[1]
            if ($sampleKeys.ContainsKey($key)) {
                throw "Duplicate setting $key in .env.sample. The existing .env was not changed."
            }
            $sampleKeys[$key] = $true
        }
    }
    $missing = @($Values.Keys | Where-Object { -not $sampleKeys.ContainsKey($_) })
    if ($missing.Count) {
        throw ".env.sample is missing these deployment settings: $($missing -join ', '). The existing .env was not changed."
    }

    $envPath = Join-Path $RepoRoot '.env'
    $sourceLines = if (Test-Path -LiteralPath $envPath -PathType Leaf) {
        [IO.File]::ReadAllLines($envPath)
    }
    else {
        $sampleLines
    }
    $seen = @{}
    $lines = @(
        foreach ($line in $sourceLines) {
            if ($line -cmatch '^\s*(?:export\s+)?([A-Z][A-Z0-9_]+)\s*=') {
                $key = $Matches[1]
                if ($seen.ContainsKey($key)) {
                    throw "Duplicate setting $key in .env. The existing .env was not changed."
                }
                $seen[$key] = $true
                if ($Values.Contains($key)) {
                    "$key=$($Values[$key])"
                }
                else {
                    $line
                }
            }
            else {
                $line
            }
        }
        foreach ($key in $Values.Keys) {
            if (-not $seen.ContainsKey($key)) {
                "$key=$($Values[$key])"
            }
        }
        foreach ($line in $sampleLines) {
            if ($line -cmatch '^([A-Z][A-Z0-9_]+)=' -and
                -not $seen.ContainsKey($Matches[1]) -and -not $Values.Contains($Matches[1])) {
                $line
            }
        }
    )
    $temporaryPath = "$envPath.tmp"
    [IO.File]::WriteAllText($temporaryPath, ($lines -join "`n") + "`n", [Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporaryPath -Destination $envPath -Force -WhatIf:$false -Confirm:$false
    Write-Host 'Populated .env with the deployment settings. Existing comments and unrelated settings were preserved.'
}

function Complete-LabDeployment {
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$ManifestPath,
        [Parameter(Mandatory)][object]$Manifest,
        [Parameter(Mandatory)][object]$Outputs,
        [Parameter(Mandatory)][string[]]$ChatModelNames,
        [Parameter(Mandatory)][string]$Python,
        [switch]$InfrastructureOnly
    )

    if ($ChatModelNames.Count -ne 2 -or @($ChatModelNames | Select-Object -Unique).Count -ne 2) {
        throw 'LAB663 requires two distinct chat deployments: the frontier model first and the smaller model second.'
    }
    $connection = Invoke-LabAz @('resource', 'show', '--resource-group', $Manifest.resourceGroup,
        '--subscription', $Manifest.subscriptionId, '--name', $Outputs.applicationInsightsName.value,
        '--resource-type', 'Microsoft.Insights/components', '--query', 'properties.ConnectionString', '--output', 'tsv')
    $settings = [ordered]@{
        FOUNDRY_PROJECT_ENDPOINT = $Outputs.projectEndpoint.value
        TRAILMATE_AGENT_NAME = 'trailmate'
        TRAILMATE_MODEL_DEPLOYMENT = $ChatModelNames[0]
        TRAILMATE_SMALL_MODEL_DEPLOYMENT = $ChatModelNames[1]
        APPLICATIONINSIGHTS_CONNECTION_STRING = $connection
        AZURE_SUBSCRIPTION_ID = $Manifest.subscriptionId
        AZURE_TENANT_ID = $Manifest.tenantId
        AZURE_RESOURCE_GROUP = $Manifest.resourceGroup
        AZURE_AI_ACCOUNT_NAME = $Outputs.accountName.value
        AZURE_AI_PROJECT_NAME = $Outputs.projectName.value
        AZURE_LOCATION = $Manifest.location
        LAB663_DELIVERY_MODE = 'skillable'
    }
    Write-LabEnvironment -RepoRoot $RepoRoot -Values $settings

    if ($InfrastructureOnly) {
        Write-Host 'Infrastructure is ready. Agent creation and notebook validation were skipped; this is not a learner-ready result.'
        return
    }

    $originalSettings = @{}
    try {
        # python-dotenv preserves inherited values; use this deployment during bootstrap.
        foreach ($key in $settings.Keys) {
            $originalSettings[$key] = [Environment]::GetEnvironmentVariable($key, 'Process')
            [Environment]::SetEnvironmentVariable($key, [string]$settings[$key], 'Process')
        }
        & $Python (Join-Path $RepoRoot 'src\agent\01_build_agent.py')
        if ($LASTEXITCODE -ne 0) {
            throw 'Agent setup failed. Infrastructure is retained; rerun with the same lab instance ID after correcting the error.'
        }
        $Manifest.phase = 'agent-ready'
        Write-LabJson $ManifestPath $Manifest
        Write-Host 'Agent setup is complete. Sign in as the learner and run notebook 01 before opening the lab to attendees.'
    }
    finally {
        foreach ($key in $originalSettings.Keys) {
            [Environment]::SetEnvironmentVariable($key, $originalSettings[$key], 'Process')
        }
    }
}

function Start-LabAuthentication {
    param(
        [string]$TenantId,
        [string]$SubscriptionId,
        [string]$StateDirectory,
        [switch]$UseCurrentAzureLogin
    )

    $script:OriginalEnvironment = @{}
    foreach ($name in @('AZURE_CONFIG_DIR', 'AZURE_CORE_COLLECT_TELEMETRY', 'AZURE_CLIENT_ID', 'AZURE_CLIENT_SECRET', 'AZURE_TENANT_ID', 'AZURE_TOKEN_CREDENTIALS')) {
        $script:OriginalEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    }
    $script:AuthenticationDirectory = $null
    if ($UseCurrentAzureLogin) {
        $env:AZURE_TOKEN_CREDENTIALS = 'AzureCliCredential'
    }
    else {
        if (-not $env:LAB663_CLIENT_ID -or -not $env:LAB663_CLIENT_SECRET) {
            throw 'Set LAB663_CLIENT_ID and LAB663_CLIENT_SECRET as process variables in the Skillable action. Never write credentials to .env.'
        }
        $script:AuthenticationDirectory = Join-Path $StateDirectory ("azure-auth-" + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:AuthenticationDirectory -WhatIf:$false -Confirm:$false | Out-Null
        $env:AZURE_CONFIG_DIR = $script:AuthenticationDirectory
        $env:AZURE_CORE_COLLECT_TELEMETRY = 'no'
        $env:AZURE_CLIENT_ID = $env:LAB663_CLIENT_ID
        $env:AZURE_CLIENT_SECRET = $env:LAB663_CLIENT_SECRET
        $env:AZURE_TENANT_ID = $TenantId
        $env:AZURE_TOKEN_CREDENTIALS = 'EnvironmentCredential'
        # Do not start a transcript or print command arguments around authentication.
        Invoke-LabAz @('login', '--service-principal', '--username', $env:LAB663_CLIENT_ID,
            '--password', $env:LAB663_CLIENT_SECRET, '--tenant', $TenantId, '--output', 'none') | Out-Null
    }
    $account = Invoke-LabAz @('account', 'show', '--subscription', $SubscriptionId, '--output', 'json') | ConvertFrom-Json
    if ($account.tenantId -ne $TenantId -or $account.state -ne 'Enabled') {
        throw 'The selected subscription is not enabled in the requested tenant.'
    }
    $current = Invoke-LabAz @('account', 'show', '--output', 'json') | ConvertFrom-Json
    if ($current.tenantId -ne $TenantId) {
        throw 'The current Azure login belongs to a different tenant. Sign in to the requested tenant before continuing.'
    }
}

function Get-LabBootstrapObjectId {
    param(
        [Parameter(Mandatory)][guid]$TenantId,
        [Parameter(Mandatory)][guid]$ClientId,
        [Parameter(Mandatory)][guid]$SubscriptionId
    )

    # Read only the identity claims in our own CLI-issued ARM token, never another user's token.
    # ARM still authorizes every deployment; decoding this payload is not signature validation.
    $token = $null
    $claims = $null
    try {
        Get-Command az -ErrorAction Stop | Out-Null
        $ErrorActionPreference = 'Continue'
        $token = & az account get-access-token --subscription "$SubscriptionId" --resource-type arm `
            --query accessToken --output tsv --only-show-errors 2>$null
        $exitCode = $LASTEXITCODE
        $ErrorActionPreference = 'Stop'
        if ($exitCode -ne 0) { throw 'Token request failed.' }
        $parts = ([string]$token).Trim().Split('.')
        if ($parts.Count -ne 3) { throw 'Unsupported token format.' }
        $payload = $parts[1].Replace('-', '+').Replace('_', '/')
        $payload = $payload.PadRight($payload.Length + ((4 - $payload.Length % 4) % 4), '=')
        $claims = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload)) | ConvertFrom-Json
        $applicationId = if ($claims.PSObject.Properties['appid']) { $claims.appid }
            elseif ($claims.PSObject.Properties['azp']) { $claims.azp }
            else { '' }
        $objectId = [guid]::Empty
        if (-not $claims.PSObject.Properties['tid'] -or $claims.tid -ne "$TenantId" -or
            $applicationId -ne "$ClientId" -or -not $claims.PSObject.Properties['oid'] -or
            -not [guid]::TryParse([string]$claims.oid, [ref]$objectId) -or $objectId -eq [guid]::Empty -or
            $claims.PSObject.Properties['scp']) {
            throw 'Token identity does not match the lifecycle application.'
        }
        return $objectId.ToString()
    }
    catch {
        # Do not forward parser or CLI errors that could contain the access token.
        throw 'Cannot identify the signed-in lifecycle service principal from its ARM token. Check the application and tenant; no directory lookup was attempted. Token details were withheld.'
    }
    finally {
        Remove-Variable -Name token, claims, parts, payload -ErrorAction SilentlyContinue
    }
}

function Stop-LabAuthentication {
    if (Get-Variable OriginalEnvironment -Scope Script -ErrorAction SilentlyContinue) {
        foreach ($name in $script:OriginalEnvironment.Keys) {
            if ($null -eq $script:OriginalEnvironment[$name]) {
                if (Test-Path -LiteralPath "Env:\$name") {
                    Remove-Item -LiteralPath "Env:\$name" -WhatIf:$false -Confirm:$false
                }
            }
            else {
                [Environment]::SetEnvironmentVariable($name, $script:OriginalEnvironment[$name], 'Process')
            }
        }
    }
    if ((Get-Variable AuthenticationDirectory -Scope Script -ErrorAction SilentlyContinue) -and $script:AuthenticationDirectory) {
        $directory = Get-Item -LiteralPath $script:AuthenticationDirectory
        if ($directory.Name -notmatch '^azure-auth-[a-f0-9]{32}$' -or $directory.Attributes.HasFlag([IO.FileAttributes]::ReparsePoint)) {
            throw 'Refusing to remove an unexpected authentication directory.'
        }
        # A resource dry run must still remove its temporary credentials.
        Remove-Item -LiteralPath $directory.FullName -Recurse -Force -WhatIf:$false -Confirm:$false
    }
}

function Get-LabManifestPath {
    param([string]$RepoRoot, [string]$LabInstanceId)

    if ($LabInstanceId -notmatch '^[a-zA-Z0-9][a-zA-Z0-9-]{0,39}$') {
        throw 'LabInstanceId must contain 1-40 letters, digits or hyphens, starting with a letter or digit.'
    }
    $directory = Join-Path $RepoRoot '.lab-lifecycle'
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    return Join-Path $directory "$LabInstanceId.json"
}

function Assert-LabResourceOwnership {
    param([object]$Resource, [string]$LabInstanceId)

    if (-not $Resource.PSObject.Properties['tags'] -or
        -not $Resource.tags -or
        -not $Resource.tags.PSObject.Properties['lab663Instance'] -or
        $Resource.tags.lab663Instance -ne $LabInstanceId -or
        -not $Resource.tags.PSObject.Properties['lab663ManagedBy'] -or
        $Resource.tags.lab663ManagedBy -ne 'lifecycle') {
        throw "Resource '$($Resource.id)' is not tagged for this lab instance. Nothing will be deleted or overwritten."
    }
}
