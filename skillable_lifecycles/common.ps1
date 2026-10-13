$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-LabAz {
    param([Parameter(Mandatory)][string[]]$Arguments)

    $output = & az @Arguments --only-show-errors 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI failed (exit $LASTEXITCODE): $($output -join [Environment]::NewLine)"
    }
    return ($output -join [Environment]::NewLine)
}

function Write-LabJson {
    param([string]$Path, [object]$Value)

    $json = $Value | ConvertTo-Json -Depth 30
    [IO.File]::WriteAllText($Path, $json, [Text.UTF8Encoding]::new($false))
}

function Start-LabAuthentication {
    param(
        [string]$TenantId,
        [string]$SubscriptionId,
        [string]$StateDirectory,
        [switch]$UseCurrentAzureLogin
    )

    $script:OriginalEnvironment = @{}
    foreach ($name in @('AZURE_CONFIG_DIR', 'AZURE_CLIENT_ID', 'AZURE_CLIENT_SECRET', 'AZURE_TENANT_ID', 'AZURE_TOKEN_CREDENTIALS')) {
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
