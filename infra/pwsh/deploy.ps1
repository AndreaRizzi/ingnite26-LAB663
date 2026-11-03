<#
.SYNOPSIS
Deploys the LAB663 environment into your own Azure subscription (PowerShell version of infra/deploy.sh).

.DESCRIPTION
What we get:
  - A Foundry resource and project, with tracing wired up
  - Chat models and four model router editions
  - The access (RBAC) we need, assigned to us
  - A local .env file and the v0 TrailMate agent

Run with PowerShell 7 or later:  pwsh -NoProfile -File .\infra\pwsh\deploy.ps1

For self-guided runs the resource group is new, named rg-lab663-NNNN.
The Skillable lifecycle supplies its allocated ResourceGroup and LabInstanceId instead.
To remove everything later:  ./infra/pwsh/cleanup.ps1

A log of the run is saved to the desktop as lab663-deploy-<timestamp>.txt.
A readable result is saved as LAB663-deployment-output.txt in the same directory.

We ask a few questions. To skip a question, set its variable first:
  AZURE_SUBSCRIPTION_ID, AZURE_LOCATION,
  LAB663_CHAT_MODELS (for example "gpt-5.4@2026-03-05,gpt-5.4-mini@2026-03-17"),
  LAB663_CAPACITY

.PARAMETER Yes
Accept every default without asking.

.PARAMETER SkipAgent
Deploy the infrastructure only, skip the v0 agent.

.PARAMETER Skillable
Skip the role assignments in the Bicep template, because Skillable lifecycle actions grant the learner's roles.
Use this when signed in as a Skillable learner who can't create role assignments.

.PARAMETER LearnerAccessManagedExternally
Use existing Skillable learner roles without an Entra lookup. Lifecycle runs only.
Bootstrap and project-identity roles are still deployed.

.PARAMETER ResumeDeployment
Finish the existing Skillable deployment without submitting resources again.
Requires the matching local ownership manifest and matching Azure deployment parameters.
#>
[CmdletBinding()]
param(
    [switch]$Yes,
    [switch]$SkipAgent,
    [switch]$Skillable,
    [switch]$LearnerAccessManagedExternally,
    [switch]$ResumeDeployment,
    [string]$ResourceGroup = '',
    [string]$LabInstanceId = '',
    [guid]$BootstrapPrincipalId = [guid]::Empty,
    [string]$OutputDirectory = ''
)

$ErrorActionPreference = 'Stop'

$InfraDir = Split-Path -Parent $PSScriptRoot
$RepoRoot = Split-Path -Parent $InfraDir
$EnvFile = Join-Path $RepoRoot '.env'
$OnWindows = $env:OS -eq 'Windows_NT'
. (Join-Path $RepoRoot 'skillable_lifecycles\common.ps1')
$Lifecycle = -not [string]::IsNullOrWhiteSpace($LabInstanceId)
$Result = 'RUNNING'
$Stage = 'Checking prerequisites'
$EnvWritten = $false
$AgentReady = $false
$Manifest = $null
$OriginalSettings = @{}
$SubscriptionId = ''
$TenantId = ''
$Location = ''
$AccountName = ''
$ProjectName = ''
$ProjectEndpoint = ''
$DeploymentName = ''
$FrontierModel = ''
$SmallModel = ''
$FailureMessage = ''
$CompiledTemplate = ''
$BicepExecutable = ''
$StartedAt = [DateTime]::UtcNow.ToString('u')

$DefaultLocation = 'eastus'
$DefaultChatModels = 'gpt-5.4@2026-03-05,gpt-5.4-mini@2026-03-17'
$DefaultCapacity = '250'

function Write-Step([string]$Message) {
    $script:Stage = $Message
    Write-Host "`n==> $Message"
}

# Ask a question, show a default, and keep the default when we press Enter.
function Read-WithDefault([string]$Prompt, [string]$Default) {
    if ($Yes) { return $Default }
    $reply = Read-Host "$Prompt [$Default]"
    if ([string]::IsNullOrWhiteSpace($reply)) { return $Default }
    return $reply.Trim()
}

# Keep native stderr separate from values consumed as JSON, TSV and .env settings.
function Invoke-DeploymentCommand {
    param([string]$FilePath, [string[]]$Arguments, [switch]$SensitiveOutput)

    Get-Command $FilePath -ErrorAction Stop | Out-Null
    $stderrFile = [IO.Path]::GetTempFileName()
    try {
        # PowerShell 5.1 treats native warnings as errors; the exit code determines success.
        $ErrorActionPreference = 'Continue'
        $PSNativeCommandUseErrorActionPreference = $false
        $output = & $FilePath @Arguments 2> $stderrFile
        $exitCode = $LASTEXITCODE
        $ErrorActionPreference = 'Stop'
        $diagnostics = Get-Content -LiteralPath $stderrFile -Raw
        if ($diagnostics -and -not $SensitiveOutput) { Write-Host $diagnostics.TrimEnd() }
        if ($exitCode -ne 0) {
            $detail = if ($SensitiveOutput) { 'Response output withheld because this read may contain a connection string.' }
                else { "$diagnostics`n$($output -join [Environment]::NewLine)" }
            $failure = [InvalidOperationException]::new("Command failed (exit $exitCode): $FilePath $($Arguments -join ' ')`n$detail")
            $failure.Data['NativeExitCode'] = $exitCode
            throw $failure
        }
        return $output
    }
    finally {
        Remove-Item -LiteralPath $stderrFile -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-Az {
    Invoke-DeploymentCommand -FilePath 'az' -Arguments $args
}

function Invoke-AzRead {
    param([string[]]$Arguments, [switch]$SensitiveOutput)

    $operation = ($Arguments | Select-Object -First 3) -join ' '
    if ($operation -ne 'deployment group show' -and
        (($Arguments | Select-Object -First 2) -join ' ') -ne 'resource show') {
        throw 'Read retries are only permitted for deployment group show and resource show.'
    }
    foreach ($attempt in 1..3) {
        try {
            return Invoke-DeploymentCommand -FilePath 'az' -Arguments $Arguments -SensitiveOutput:$SensitiveOutput
        }
        catch {
            if (-not $_.Exception.Data.Contains('NativeExitCode') -or
                $_.Exception.Data['NativeExitCode'] -ne -1 -or $attempt -eq 3) {
                throw
            }
            Write-Host "Azure CLI read exited -1 (attempt $attempt of 3). Retrying the read only; no resources will be submitted."
            Start-Sleep -Seconds (5 * $attempt)
        }
    }
}

function Get-DeploymentFailureDetails {
    $checks = @(
        @{
            Label = 'Azure deployment status and error'
            Arguments = @(
                'deployment', 'group', 'show', '--subscription', $SubscriptionId,
                '--resource-group', $ResourceGroup, '--name', $DeploymentName,
                '--query', '{state:properties.provisioningState,correlationId:properties.correlationId,error:properties.error}',
                '--output', 'json'
            )
        },
        @{
            Label = 'Failed Azure deployment operations'
            Arguments = @(
                'deployment', 'operation', 'group', 'list', '--subscription', $SubscriptionId,
                '--resource-group', $ResourceGroup, '--name', $DeploymentName,
                '--query', "[?properties.provisioningState=='Failed'].{target:properties.targetResource.id,statusCode:properties.statusCode,error:properties.statusMessage}",
                '--output', 'json'
            )
        }
    )
    $details = foreach ($check in $checks) {
        try {
            $arguments = $check.Arguments
            $text = (Invoke-Az @arguments) -join [Environment]::NewLine
            if ([string]::IsNullOrWhiteSpace($text)) {
                throw 'Azure CLI returned no diagnostic output.'
            }
            "$($check.Label): $text"
        }
        catch {
            "Could not read $($check.Label): $($_.Exception.Message)"
        }
    }
    return ($details -join [Environment]::NewLine)
}

function Wait-DeploymentSuccess {
    param(
        [DateTimeOffset]$NotBefore = [DateTimeOffset]::MinValue,
        [int]$TimeoutSeconds = 1800
    )

    $deadline = [DateTimeOffset]::UtcNow.AddSeconds($TimeoutSeconds)
    do {
        $json = Invoke-Az deployment group show --subscription $SubscriptionId `
            --resource-group $ResourceGroup --name $DeploymentName `
            --query '{state:properties.provisioningState,timestamp:properties.timestamp}' --output json
        $deployment = ($json -join "`n") | ConvertFrom-Json
        if (-not $deployment -or -not $deployment.PSObject.Properties['state'] -or -not $deployment.state) {
            throw 'Azure returned no deployment provisioning state. Local setup was not continued.'
        }
        if ($NotBefore -ne [DateTimeOffset]::MinValue) {
            $timestamp = [DateTimeOffset]::MinValue
            if ($deployment.PSObject.Properties['timestamp']) {
                if ($deployment.timestamp -is [DateTime]) { $timestamp = [DateTimeOffset]$deployment.timestamp }
                else { [void][DateTimeOffset]::TryParse([string]$deployment.timestamp, [ref]$timestamp) }
            }
            if ($timestamp -lt $NotBefore) {
                throw 'Azure has not confirmed a deployment from this submission. An older deployment cannot establish success; inspect the named deployment before retrying.'
            }
        }
        Write-Host "Azure deployment $DeploymentName state: $($deployment.state)"
        switch ($deployment.state) {
            'Succeeded' { return }
            { $_ -in @('Accepted', 'Running', 'Creating', 'Updating') } { break }
            default { throw "Azure deployment ended in state '$($deployment.state)'. Local setup was not continued." }
        }
        if ([DateTimeOffset]::UtcNow -ge $deadline) {
            throw 'Timed out waiting for Azure deployment. It may still be running; inspect it before retrying or resuming.'
        }
        Start-Sleep -Seconds 10
    } while ($true)
}

function Assert-ResumeParameters {
    param([System.Collections.IDictionary]$Expected)

    $json = Invoke-Az deployment group show --subscription $SubscriptionId `
        --resource-group $ResourceGroup --name $DeploymentName --query properties.parameters --output json
    $actual = ($json -join "`n") | ConvertFrom-Json
    foreach ($key in $Expected.Keys) {
        if (-not $actual -or -not $actual.PSObject.Properties[$key] -or
            -not $actual.$key.PSObject.Properties['value']) {
            throw "Cannot resume: Azure deployment parameter $key is missing."
        }
        $value = $actual.$key.value
        $wanted = $Expected[$key].value
        if ($key -eq 'chatModels') {
            if (@($value).Count -ne @($wanted).Count) { throw 'Cannot resume: chat models differ.' }
            for ($i = 0; $i -lt @($wanted).Count; $i++) {
                if ($value[$i].name -cne $wanted[$i].name -or $value[$i].version -cne $wanted[$i].version) {
                    throw 'Cannot resume: chat model names, versions or order differ.'
                }
            }
        }
        elseif ($key -eq 'extraModels') {
            $have = @($value | ForEach-Object { "$($_.name)@$($_.version)" }) -join ','
            $need = @($wanted | ForEach-Object { "$($_.name)@$($_.version)" }) -join ','
            if ($have -cne $need) { throw 'Cannot resume: extra models differ.' }
        }
        elseif ($key -eq 'resourceTags') {
            foreach ($tag in $wanted.Keys) {
                if (-not $value -or -not $value.PSObject.Properties[$tag] -or $value.$tag -cne $wanted[$tag]) {
                    throw "Cannot resume: ownership tag $tag differs."
                }
            }
        }
        elseif ($value -cne $wanted) { throw "Cannot resume: Azure deployment parameter $key differs." }
    }
}

function Get-BicepExecutable {
    $command = Get-Command bicep -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { return $command.Source }

    $binaryName = if ($OnWindows) { 'bicep.exe' } else { 'bicep' }
    # The lifecycle's isolated Azure login must not hide the image's existing compiler.
    $directories = @((Join-Path $HOME '.azure'))
    if ($env:AZURE_CONFIG_DIR) { $directories += $env:AZURE_CONFIG_DIR }
    foreach ($directory in $directories) {
        $candidate = Join-Path (Join-Path $directory 'bin') $binaryName
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    throw "The prepared Bicep compiler was not found on PATH or in the user's Azure CLI bin directory. Install and verify Bicep in the VM image as the lab user before retrying. No compiler will be downloaded during deployment."
}

# Run az quietly and report whether it worked.
function Test-Az {
    $ErrorActionPreference = 'Continue'
    $PSNativeCommandUseErrorActionPreference = $false
    & az @args *> $null
    return $LASTEXITCODE -eq 0
}

function Test-PythonPrerequisites {
    param([string]$Interpreter, [string]$CheckScript)

    # Windows PowerShell must collect every stderr line before checking the native exit code.
    $ErrorActionPreference = 'Continue'
    $PSNativeCommandUseErrorActionPreference = $false
    $output = @(& $Interpreter $CheckScript 2>&1)
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    $lines = @($output | ForEach-Object { $_.ToString() })
    $lines | ForEach-Object { Write-Host $_ }
    if ($exitCode -ne 0) {
        throw "Python prerequisite checks failed (exit $exitCode). Interpreter: $Interpreter. No resources were deployed.`n$($lines -join "`n")"
    }
}

function Invoke-AgentBootstrap {
    param([string]$Interpreter, [string]$ScriptPath)

    Get-Command $Interpreter -ErrorAction Stop | Out-Null
    if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {
        throw "The agent script is missing: $ScriptPath"
    }
    $tail = [Collections.Generic.Queue[string]]::new()
    $redact = @($env:LAB663_CLIENT_SECRET, $env:AZURE_CLIENT_SECRET, $env:APPLICATIONINSIGHTS_CONNECTION_STRING)
    $ErrorActionPreference = 'Continue'
    $PSNativeCommandUseErrorActionPreference = $false
    $global:LASTEXITCODE = 1
    # Stream both channels into the transcript; -u prevents Python buffering under the VM action.
    & $Interpreter -u $ScriptPath 2>&1 | ForEach-Object {
        $line = $_.ToString()
        foreach ($value in $redact) {
            if ($value) { $line = $line.Replace($value, '[redacted]') }
        }
        Write-Host $line
        $tail.Enqueue($line)
        if ($tail.Count -gt 20) { [void]$tail.Dequeue() }
    }
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($tail.Count -eq 0) {
        $line = 'Python returned no stdout or stderr. This does not identify the cause; inspect VM process/security events if it persists.'
        Write-Host $line
        $tail.Enqueue($line)
    }
    Write-Host "Agent Python exit code: $exitCode"
    return [pscustomobject]@{ ExitCode = $exitCode; LastOutput = ($tail -join [Environment]::NewLine) }
}

function Exit-WithMessage([string]$Message, [int]$Code = 1) {
    if ($Code -ne 0) { throw $Message }
    $script:Result = 'CANCELLED'
    Write-Host $Message
    exit $Code
}

function Write-DeploymentSummary {
    $lines = @(
        'LAB663 deployment'
        "Result: $Result"
        "Stage: $Stage"
        "PowerShell version: $($PSVersionTable.PSVersion)"
        "Bicep compiler: $BicepExecutable"
        "Started (UTC): $StartedAt"
        "Updated (UTC): $([DateTime]::UtcNow.ToString('u'))"
        "Subscription: $SubscriptionId"
        "Tenant: $TenantId"
        "Resource group: $ResourceGroup"
        "Region: $Location"
        "Deployment: $DeploymentName"
        "Foundry account: $AccountName"
        "Foundry project: $ProjectName"
        "Project endpoint: $ProjectEndpoint"
        "Frontier model: $FrontierModel"
        "Small model: $SmallModel"
        "Environment file: $EnvFile"
        "Environment populated this run: $EnvWritten"
        "TrailMate agent ready: $AgentReady"
        "Learner access managed by existing Skillable action: $LearnerAccessManagedExternally"
        "Run log: $LogFile"
    )
    if ($FailureMessage) { $lines += "Error: $FailureMessage" }
    if ($Result -eq 'FAILED') { $lines += 'Do not start the lab. Ask the facilitator to review the run log.' }
    if ($Result -eq 'INFRASTRUCTURE_READY') { $lines += 'Agent setup was skipped. This is not a learner-ready result.' }
    [IO.File]::WriteAllText($SummaryFile, ($lines -join "`r`n") + "`r`n", [Text.UTF8Encoding]::new($false))
}

# Save a copy of everything shown on screen to the desktop. Native output is piped through Out-Host so it lands in the log too.
$Desktop = if ($OutputDirectory) { $OutputDirectory } else { [Environment]::GetFolderPath('Desktop') }
if ($OutputDirectory) { [void][IO.Directory]::CreateDirectory($Desktop) }
elseif (-not $Desktop -or -not (Test-Path $Desktop)) { $Desktop = $HOME }
$LogFile = Join-Path $Desktop "lab663-deploy-$(Get-Date -Format 'yyyyMMdd-HHmmss-fff').txt"
$SummaryFile = Join-Path $Desktop 'LAB663-deployment-output.txt'
Start-Transcript -Path $LogFile | Out-Null

try {
    Write-DeploymentSummary
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        throw 'PowerShell 7 or later is required. Run pwsh -NoProfile -File .\infra\pwsh\deploy.ps1, or repaste the updated Skillable deploy-pwsh.ps1 launcher. Do not run deployment with powershell.exe.'
    }
    Write-Host "Deployment PowerShell version: $($PSVersionTable.PSVersion)"
    if ($Lifecycle -and (-not $Yes -or $Skillable -or -not $ResourceGroup -or
        $BootstrapPrincipalId -eq [guid]::Empty -or -not $env:AZURE_SUBSCRIPTION_ID -or
        -not $env:AZURE_LOCATION -or (-not $LearnerAccessManagedExternally -and -not $env:LAB663_PRINCIPAL_ID))) {
        throw 'Use the Skillable deploy-pwsh lifecycle wrapper: it supplies explicit IDs, the allocated group and -Yes. Do not combine it with -Skillable.'
    }
    if ($ResourceGroup -and -not $Lifecycle) {
        throw 'An allocated ResourceGroup requires the Skillable lifecycle and a LabInstanceId.'
    }
    if ($LearnerAccessManagedExternally -and -not $Lifecycle) {
        throw 'LearnerAccessManagedExternally is only supported with the Skillable lifecycle.'
    }
    if ($ResumeDeployment -and -not $Lifecycle) {
        throw 'ResumeDeployment is only supported with the Skillable lifecycle and its saved ownership manifest.'
    }
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        Exit-WithMessage 'We need the Azure CLI (az). The dev container has it.'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot '.env.sample') -PathType Leaf)) {
        throw 'The checkout is missing .env.sample. Restore it before deploying.'
    }

    $Python = Join-Path $RepoRoot '.venv/Scripts/python.exe'
    if (-not (Test-Path $Python)) { $Python = Join-Path $RepoRoot '.venv/bin/python' }
    if (-not (Test-Path $Python)) {
        Exit-WithMessage 'The repository .venv is missing. Prepare it from requirements.txt before deploying.'
    }

    if ($SkipAgent) {
        Write-Host 'Infrastructure-only rehearsal: Python package and agent checks are skipped; this is not learner-ready.'
    } else {
        Test-PythonPrerequisites -Interpreter $Python -CheckScript (Join-Path $RepoRoot 'src\check_environment.py')
    }

    Write-Step 'Checking the installed Bicep compiler'
    $BicepExecutable = Get-BicepExecutable
    Write-Host "Bicep compiler: $BicepExecutable"
    Invoke-DeploymentCommand -FilePath $BicepExecutable -Arguments @('--version') | Out-Host

    Write-Step 'Compiling Bicep to an ARM template'
    $CompiledTemplate = Join-Path ([IO.Path]::GetTempPath()) ("lab663-" + [guid]::NewGuid().ToString('N') + '.json')
    Invoke-DeploymentCommand -FilePath $BicepExecutable -Arguments @(
        'build', (Join-Path $InfraDir 'main.bicep'), '--outfile', $CompiledTemplate
    ) | Out-Host
    if (-not (Test-Path -LiteralPath $CompiledTemplate -PathType Leaf)) {
        throw 'Bicep returned success without writing the ARM template. No Azure deployment was submitted.'
    }
    $compiled = Get-Content -LiteralPath $CompiledTemplate -Raw | ConvertFrom-Json
    if (-not $compiled -or -not $compiled.PSObject.Properties['$schema'] -or
        -not $compiled.PSObject.Properties['resources']) {
        throw 'Bicep did not produce an ARM template with a schema and resources. No Azure deployment was submitted.'
    }

    # --- 1. Sign in ---
    Write-Step 'Checking our Azure sign-in'
    if (-not (Test-Az account show)) {
        if ($Lifecycle) { throw 'Skillable authentication is missing. Interactive sign-in is disabled for lifecycle runs.' }
        Write-Host "We're not signed in yet. Follow the device code steps."
        Invoke-Az login --use-device-code | Out-Null
    }

    # --- 2. Subscription ---
    $SubscriptionId = $env:AZURE_SUBSCRIPTION_ID
    if ([string]::IsNullOrWhiteSpace($SubscriptionId)) {
        $currentSub = Invoke-Az account show --query id --output tsv
        if (-not $Yes) {
            Write-Host "`nOur subscriptions:"
            Invoke-Az account list --query "[].{Name:name, Id:id}" --output table | Out-Host
        }
        $SubscriptionId = Read-WithDefault 'Subscription ID to deploy into' $currentSub
    }
    Invoke-Az account set --subscription $SubscriptionId | Out-Null
    $TenantId = Invoke-Az account show --query tenantId --output tsv
    Write-Host "Using subscription: $(Invoke-Az account show --query name --output tsv)"

    # --- 3. Location, resource group, models ---
    $Location = $env:AZURE_LOCATION
    if ([string]::IsNullOrWhiteSpace($Location)) { $Location = Read-WithDefault 'Azure region' $DefaultLocation }
    $Location = $Location.Trim().ToLowerInvariant()
    if (($Lifecycle -or $Skillable) -and $Location -ne 'eastus') {
        throw 'Skillable LAB663 resources must be deployed to eastus. Set AZURE_LOCATION=eastus; the allocated resource group can have a different metadata location.'
    }
    $regions = Invoke-Az account list-locations --query "[].name" --output tsv
    if ($regions -notcontains $Location) {
        Exit-WithMessage "'$Location' was not returned in the subscription's Azure region list."
    }

    # A new group every run keeps old attempts from clashing with new ones (deleted Foundry resources linger for a while).
    while (-not $ResourceGroup) {
        $candidate = "rg-lab663-$(Get-Random -Minimum 1000 -Maximum 10000)"
        if ((Invoke-Az group exists --name $candidate) -eq 'false') { $ResourceGroup = $candidate }
    }

    $ChatModels = $env:LAB663_CHAT_MODELS
    if ([string]::IsNullOrWhiteSpace($ChatModels)) {
        $ChatModels = Read-WithDefault 'Chat models to deploy (name@version, comma separated)' $DefaultChatModels
    }
    $Capacity = if ($env:LAB663_CAPACITY) { $env:LAB663_CAPACITY } else { $DefaultCapacity }
    if ($Capacity -notmatch '^\d+$' -or [long]$Capacity -lt 1 -or [long]$Capacity -gt 1000000) {
        Exit-WithMessage 'LAB663_CAPACITY must be between 1 and 1000000.'
    }

    # Turn "name@version,name@version" into the list the template wants.
    $ChatModelItems = @(foreach ($part in $ChatModels.Split(',')) {
        $name, $version = $part.Trim() -split '@', 2
        if (-not $name -or -not $version) { Exit-WithMessage "'$part' should look like name@version" }
        [pscustomobject]@{ name = $name; version = $version }
    })
    if ($ChatModelItems.Count -ne 2 -or @($ChatModelItems.name | Select-Object -Unique).Count -ne 2) {
        Exit-WithMessage 'This lab needs exactly two distinct chat models: frontier first, smaller model second.'
    }
    $FrontierModel = $ChatModelItems[0].name
    $SmallModel = $ChatModelItems[1].name

    # --- 4. Check the models exist in this region ---
    Write-Step "Checking the models are available in $Location"
    $catalogJson = Invoke-Az cognitiveservices model list --location $Location `
        --query "[].{name:model.name, version:model.version}" --output json
    $catalog = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($m in (($catalogJson -join "`n") | ConvertFrom-Json)) { [void]$catalog.Add("$($m.name)@$($m.version)") }

    $wanted = @($ChatModelItems | ForEach-Object { "$($_.name)@$($_.version)" }) + 'model-router@2025-11-18'
    $missing = @($wanted | Where-Object { -not $catalog.Contains($_) })
    if ($missing.Count -gt 0) {
        Write-Host "These models aren't in the $Location catalog:"
        $missing | ForEach-Object { Write-Host "  - $_" }
        Exit-WithMessage "Check model availability and subscription access in $Location. Nothing was deployed."
    }
    Write-Host 'All models found.'

    # Extra models are optional: deploy the ones this region offers and skip the rest.
    $ExtraModelItems = @()
    foreach ($m in @((Get-Content -Raw -LiteralPath (Join-Path $InfraDir 'extra-models.json')) | ConvertFrom-Json)) {
        if ($catalog.Contains("$($m.name)@$($m.version)")) { $ExtraModelItems += $m }
        else { Write-Host "  - $($m.name)@$($m.version) isn't offered in $Location, so we'll skip it. The core lab doesn't need it." }
    }
    $ExtraModelNames = if ($ExtraModelItems.Count) { ($ExtraModelItems.name) -join ', ' } else { 'none in this region' }

    # --- 5. Who gets access ---
    $PrincipalId = if ($LearnerAccessManagedExternally) { '' } else { $env:LAB663_PRINCIPAL_ID }
    if (-not $LearnerAccessManagedExternally -and [string]::IsNullOrWhiteSpace($PrincipalId)) {
        $ErrorActionPreference = 'Continue'
        $PrincipalId = & az ad signed-in-user show --query id --output tsv 2>$null
        $lookupFailed = $LASTEXITCODE -ne 0
        $ErrorActionPreference = 'Stop'
        if ($lookupFailed -or [string]::IsNullOrWhiteSpace($PrincipalId)) {
            Write-Host "We couldn't read our own user ID (are we signed in as a service principal?)."
            Exit-WithMessage "Set LAB663_PRINCIPAL_ID to the object ID that needs access, and LAB663_PRINCIPAL_TYPE if it isn't a User."
        }
    }
    $PrincipalType = if ($env:LAB663_PRINCIPAL_TYPE) { $env:LAB663_PRINCIPAL_TYPE } else { 'User' }
    if ($Lifecycle) {
        if ((Invoke-Az group exists --name $ResourceGroup) -ne 'true') {
            throw 'The allocated Skillable resource group does not exist.'
        }
        $ManifestPath = Get-LabManifestPath $RepoRoot $LabInstanceId
        if (Test-Path -LiteralPath $ManifestPath) {
            $Manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
            if ($Manifest.schemaVersion -ne 1 -or $Manifest.labInstanceId -cne $LabInstanceId -or
                $Manifest.subscriptionId -ne $SubscriptionId -or $Manifest.tenantId -ne $TenantId -or
                $Manifest.resourceGroup -ne $ResourceGroup -or $Manifest.location -ne $Location -or
                $Manifest.learnerObjectId -ne $PrincipalId -or $Manifest.capacity -ne [int]$Capacity -or
                $Manifest.deploymentName -ne "lab663-$LabInstanceId" -or
                $Manifest.ownsResourceGroup -or $Manifest.phase -in @('deleting', 'deleted', 'purge-pending')) {
                throw 'The saved lifecycle does not match this active Skillable deployment.'
            }
        }
        if ($ResumeDeployment -and -not $Manifest) {
            throw 'Cannot resume without the matching local lifecycle manifest. Do not reconstruct or delete ownership state.'
        }
        $resourceJson = Invoke-Az resource list --resource-group $ResourceGroup --output json
        # Enumerate the parsed array, not ConvertFrom-Json's pipeline output (nested in PowerShell 5.1).
        $resources = @((ConvertFrom-Json -InputObject ($resourceJson -join "`n")))
        foreach ($resource in $resources | Where-Object { $_.name -match '^(aif|appi|log)-lab663-' }) {
            Assert-LabResourceOwnership $resource $LabInstanceId
        }
    }

    Write-Host ''
    if ($ResumeDeployment) { Write-Host "We're about to finish local setup without resubmitting Azure resources:" }
    else { Write-Host "We're about to create:" }
    Write-Host "  Resource group : $ResourceGroup"
    Write-Host "  Region         : $Location"
    Write-Host "  Chat models    : $ChatModels"
    Write-Host '  Router editions: mr-default, mr-cost, mr-quality, mr-subset'
    Write-Host "  Extra models   : $ExtraModelNames"
    if ($Skillable) { Write-Host '  Role assignments: skipped (granted by Skillable lifecycle actions)' }
    if ($LearnerAccessManagedExternally) {
        Write-Host '  Learner roles: supplied by the existing Skillable role action; no directory lookup.'
        if ($ResumeDeployment) { Write-Host '  Bootstrap and project-identity roles: retained from the existing deployment.' }
        else { Write-Host '  Bootstrap and project-identity roles: deployed by this script.' }
    }
    if (-not $Yes) {
        $confirm = Read-Host 'Go ahead? [y/N]'
        if ($confirm -notmatch '^[Yy]$') { Exit-WithMessage 'Cancelled. Nothing was created.' 0 }
    }

    # --- 6. Deploy ---
    Write-Step 'Registering the Azure services we need'
    foreach ($ns in 'Microsoft.CognitiveServices', 'Microsoft.Insights', 'Microsoft.OperationalInsights', 'Microsoft.AlertsManagement') {
        $state = Invoke-Az provider show --namespace $ns --query registrationState --output tsv
        if ($state -ne 'Registered') {
            if ($Lifecycle) { throw "$ns must be registered by the subscription administrator before the lab." }
            Invoke-Az provider register --namespace $ns --wait | Out-Null
        }
    }

    if (-not $Lifecycle) {
        Write-Step 'Creating the resource group'
        Invoke-Az group create --name $ResourceGroup --location $Location --output none | Out-Null
    }

    if ($ResumeDeployment) { Write-Step 'Resuming local setup from the existing Azure deployment' }
    else { Write-Step 'Deploying the compiled ARM template (this takes a few minutes)' }
    $DeploymentName = if ($Lifecycle) { "lab663-$LabInstanceId" } else { "lab663-$(Get-Date -Format 'yyyyMMddHHmmss')" }
    if ($Lifecycle) {
        if (-not $Manifest) {
            $Manifest = [pscustomobject]@{
                schemaVersion = 1; labInstanceId = $LabInstanceId; tenantId = $TenantId
                subscriptionId = $SubscriptionId; resourceGroup = $ResourceGroup; location = $Location
                learnerObjectId = $PrincipalId; capacity = [int]$Capacity
                ownsResourceGroup = $false; deploymentName = $DeploymentName
                phase = 'planned'; managedResourceIds = @(); accountName = $null; projectEndpoint = $null
            }
        }
        if (-not $ResumeDeployment) {
            $Manifest.phase = 'deploying'
            Write-LabJson $ManifestPath $Manifest
        }
    }
    # Passing JSON inline to az on Windows mangles the quotes, so the parameters go in a file.
    $ParamsFile = [System.IO.Path]::GetTempFileName()
    $submissionFailure = ''
    try {
        $parameterDocument = @{
            '$schema'      = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
            contentVersion = '1.0.0.0'
            parameters     = @{
                location      = @{ value = $Location }
                principalId   = @{ value = $PrincipalId }
                principalType = @{ value = $PrincipalType }
                capacity      = @{ value = [int]$Capacity }
                chatModels    = @{ value = $ChatModelItems }
                extraModels   = @{ value = @($ExtraModelItems) }
                assignRoles   = @{ value = -not $Skillable }
                assignLearnerRoles = @{ value = -not $LearnerAccessManagedExternally }
                bootstrapPrincipalId = @{ value = $(if ($Lifecycle) { "$BootstrapPrincipalId" } else { '' }) }
                resourceTags = @{ value = $(if ($Lifecycle) {
                    @{ lab663Instance = $LabInstanceId; lab663ManagedBy = 'lifecycle' }
                } else { @{} }) }
            }
        }
        $parameterDocument | ConvertTo-Json -Depth 10 | Set-Content -Path $ParamsFile -Encoding ascii

        if ($ResumeDeployment) {
            Assert-ResumeParameters -Expected $parameterDocument.parameters
            Wait-DeploymentSuccess
        }
        else {
            $submissionStarted = [DateTimeOffset]::UtcNow
            try {
                Invoke-Az deployment group create `
                    --name $DeploymentName `
                    --resource-group $ResourceGroup `
                    --template-file $CompiledTemplate `
                    --parameters "@$ParamsFile" `
                    --no-wait --output none | Out-Null
            }
            catch {
                $submissionFailure = $_.Exception.Message
                Write-Host "Azure CLI submission did not complete normally: $submissionFailure"
                Write-Host 'Checking whether Azure accepted this submission; resources will not be submitted again.'
            }
            Wait-DeploymentSuccess -NotBefore $submissionStarted
            if ($submissionFailure) { Write-Host 'Azure confirmed this submission succeeded despite the CLI exit. Continuing local setup.' }
        }
    } catch {
        $deploymentFailure = $_.Exception.Message
        Write-Host 'Reading Azure deployment status and failed operations before sign-out...'
        $details = Get-DeploymentFailureDetails
        throw "$submissionFailure`n$deploymentFailure`n$details`nDeployment completion was not verified. Inspect this deployment before retrying or resuming. No automatic resubmission was attempted."
    } finally {
        Remove-Item -Path $ParamsFile -Force -ErrorAction SilentlyContinue
    }

    # --- 7. Write .env ---
    Write-Step 'Reading the completed deployment outputs'
    $outputJson = Invoke-AzRead -Arguments @(
        'deployment', 'group', 'show', '--subscription', $SubscriptionId,
        '--resource-group', $ResourceGroup, '--name', $DeploymentName,
        '--query', 'properties.outputs', '--output', 'json'
    )
    $outputs = ($outputJson -join "`n") | ConvertFrom-Json
    foreach ($name in @('accountName', 'projectName', 'projectEndpoint', 'applicationInsightsName',
        'chatModelDeploymentNames', 'managedResourceIds')) {
        if (-not $outputs -or -not $outputs.PSObject.Properties[$name] -or
            -not $outputs.$name.PSObject.Properties['value'] -or $null -eq $outputs.$name.value) {
            throw "The deployment is missing output $name. The existing .env has not been changed."
        }
    }
    $AccountName = $outputs.accountName.value
    $ProjectName = $outputs.projectName.value
    $ProjectEndpoint = $outputs.projectEndpoint.value
    $AppiName = $outputs.applicationInsightsName.value
    $deployedModels = @($outputs.chatModelDeploymentNames.value)
    if ($deployedModels.Count -ne 2 -or $deployedModels[0] -cne $FrontierModel -or $deployedModels[1] -cne $SmallModel) {
        throw 'The deployment model outputs do not match this run. The existing .env has not been changed.'
    }
    $managedIds = @($outputs.managedResourceIds.value)
    if ($managedIds.Count -ne 3 -or @($managedIds | Select-Object -Unique).Count -ne 3 -or
        @($managedIds | Where-Object { $_ -isnot [string] -or [string]::IsNullOrWhiteSpace($_) }).Count) {
        throw 'The deployment must return three distinct managed resource IDs. The existing .env has not been changed.'
    }
    if ($AppiName -isnot [string] -or [string]::IsNullOrWhiteSpace($AppiName)) {
        throw 'The deployment returned no valid Application Insights name. The existing .env has not been changed.'
    }
    Write-Step 'Reading the Application Insights connection'
    $AppiConnectionString = Invoke-AzRead -SensitiveOutput -Arguments @(
        'resource', 'show', '--subscription', $SubscriptionId,
        '--resource-group', $ResourceGroup, '--name', $AppiName,
        '--resource-type', 'Microsoft.Insights/components',
        '--query', 'properties.ConnectionString', '--output', 'tsv'
    )

    $settings = [ordered]@{
        FOUNDRY_PROJECT_ENDPOINT = $ProjectEndpoint
        TRAILMATE_AGENT_NAME = 'trailmate'
        TRAILMATE_MODEL_DEPLOYMENT = $FrontierModel
        TRAILMATE_SMALL_MODEL_DEPLOYMENT = $SmallModel
        APPLICATIONINSIGHTS_CONNECTION_STRING = $AppiConnectionString
        AZURE_SUBSCRIPTION_ID = $SubscriptionId
        AZURE_TENANT_ID = $TenantId
        AZURE_RESOURCE_GROUP = $ResourceGroup
        AZURE_AI_ACCOUNT_NAME = $AccountName
        AZURE_AI_PROJECT_NAME = $ProjectName
        AZURE_LOCATION = $Location
        LAB663_DELIVERY_MODE = $(if ($Skillable -or $Lifecycle) { 'skillable' } else { 'self-guided' })
    }
    # Each deployed extra model names its own .env variable in infra/extra-models.json.
    foreach ($m in $ExtraModelItems) {
        if (-not $m.PSObject.Properties['envVar'] -or -not $m.envVar) { continue }
        if ($m.envVar -notmatch '^[A-Z][A-Z0-9_]*$') { throw "Invalid envVar '$($m.envVar)' in infra/extra-models.json." }
        $settings[$m.envVar] = $m.name
    }
    Write-Step "Writing $EnvFile"
    Write-LabEnvironment -RepoRoot $RepoRoot -Values $settings
    $EnvWritten = $true
    if ($Lifecycle) {
        $Manifest.managedResourceIds = $managedIds
        $Manifest.accountName = $AccountName
        $Manifest.projectEndpoint = $ProjectEndpoint
        $Manifest.phase = 'infrastructure-ready'
        Write-LabJson $ManifestPath $Manifest
    }
    # Keep .env readable by us only (matches umask 077 in the bash script).
    if (-not $OnWindows) { & chmod 600 $EnvFile }
    Write-Host "Done. Project endpoint: $ProjectEndpoint"

    # --- 8. Create the v0 agent ---
    $AgentScript = Join-Path $RepoRoot 'src/agent/01_build_agent.py'
    if ($SkipAgent) {
        $Result = 'INFRASTRUCTURE_READY'
        Write-Host ''
        Write-Host "Skipped the agent. When we're ready:  & `"$Python`" `"$AgentScript`""
        exit 0
    }

    Write-Step 'Creating the v0 TrailMate agent'
    foreach ($key in $settings.Keys) {
        $OriginalSettings[$key] = [Environment]::GetEnvironmentVariable($key, 'Process')
        [Environment]::SetEnvironmentVariable($key, [string]$settings[$key], 'Process')
    }
    # The agent script waits for a new project to become reachable. We retry once in case something else hiccups.
    foreach ($attempt in 1, 2) {
        Write-Host "Agent attempt $attempt of 2. Interpreter: $Python"
        $agentResult = Invoke-AgentBootstrap -Interpreter $Python -ScriptPath $AgentScript
        if ($agentResult.ExitCode -eq 0) {
            $AgentReady = $true
            if ($Lifecycle) {
                $Manifest.phase = 'agent-ready'
                Write-LabJson $ManifestPath $Manifest
            }
            $Result = 'SUCCEEDED'
            $Stage = 'Complete'
            Write-Host ''
            Write-Host 'All set. Next, open labs/core/ and start with the first notebook.'
            exit 0
        }
        if ($attempt -lt 2) {
            Write-Host "The agent step didn't finish (attempt $attempt of 2). Trying once more in 30 seconds..."
            Start-Sleep -Seconds 30
        }
    }

    if ($Lifecycle) {
        Write-Host 'Agent setup stopped. Use the Skillable wrapper with resumeDeployment=true on this same instance to authenticate and retry local setup.'
    }
    else {
        Write-Host "Agent setup stopped. After checking Azure sign-in, run: & `"$Python`" -u `"$AgentScript`""
    }
    throw "Agent setup failed (Python exit $($agentResult.ExitCode)). The deployed resources and populated .env have been retained.`n$($agentResult.LastOutput)"
} catch {
    $Result = 'FAILED'
    $FailureMessage = [string]$_.Exception.Message
    foreach ($secret in @($env:LAB663_CLIENT_SECRET, $env:AZURE_CLIENT_SECRET)) {
        if ($secret) { $FailureMessage = $FailureMessage.Replace($secret, '[redacted]') }
    }
    $FailureMessage = $FailureMessage -replace '[\r\n]+', ' '
    Write-Host "The deployment stopped: $FailureMessage"
    exit 1
} finally {
    if ($CompiledTemplate -and (Test-Path -LiteralPath $CompiledTemplate)) {
        Remove-Item -LiteralPath $CompiledTemplate -Force -ErrorAction SilentlyContinue
    }
    foreach ($key in $OriginalSettings.Keys) {
        if ($null -eq $OriginalSettings[$key]) {
            Remove-Item -LiteralPath "Env:\$key" -ErrorAction SilentlyContinue
        }
        else {
            [Environment]::SetEnvironmentVariable($key, $OriginalSettings[$key], 'Process')
        }
    }
    try {
        Write-DeploymentSummary
        Write-Host "`nDeployment summary saved to: $SummaryFile"
        Write-Host "Installation log saved to: $LogFile"
    }
    finally { Stop-Transcript | Out-Null }
}
