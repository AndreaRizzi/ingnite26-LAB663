# First Displayable > Execute Script in Virtual Machine > PowerShell.
# Paste this file into Skillable instead of action 03. Do not run both.
# Skillable may start this launcher in 5.1; deployment always runs in PowerShell 7.
$env:PSExecutionPolicyPreference = 'Bypass'
$ErrorActionPreference = 'Stop'
$repoRoot = 'C:\Users\LabUser\Desktop\LAB663'
$outputDirectory = 'C:\Users\LabUser\Desktop'
$powerShell7 = 'C:\Program Files\PowerShell\7\pwsh.exe'
$skipAgent = $false
# Set true only to finish a previous deployment in this same instance; restore false for new labs.
$resumeDeployment = $false

$tenantId = '@lab.CloudSubscription.TenantId'
$subscriptionId = '@lab.CloudSubscription.Id'
$resourceGroup = '@lab.CloudResourceGroup(ResourceGroup1).Name'
# Resource deployment region (eastus or westus), independent of the allocated resource group's metadata location.
$location = 'eastus'
$labInstanceId = '@lab.LabInstance.Id'
# Learner access is granted by the profile's existing role action, not this deployment.
$clientId = '@lab.CloudSubscription.AppId'
$clientSecret = '@lab.CloudSubscription.AppSecret'
$tokenPrefix = '@' + 'lab.'
$authenticationStarted = $false
$savedEnvironment = @{}
$summaryPath = Join-Path $outputDirectory 'LAB663-deployment-output.txt'

function Write-LifecycleFailure([string]$Message) {
    if ($clientSecret) { $Message = $Message.Replace($clientSecret, '[redacted]') }
    $Message = $Message -replace '[\r\n]+', ' '
    $content = if (Test-Path -LiteralPath $summaryPath) {
        [IO.File]::ReadAllText($summaryPath) -replace '(?m)^Result: [^\r\n]*', 'Result: FAILED'
    }
    else { "LAB663 deployment`r`nResult: FAILED`r`n" }
    [IO.File]::WriteAllText($summaryPath, ($content + "Lifecycle error: $Message`r`n"), [Text.UTF8Encoding]::new($false))
}

try {
    [void][IO.Directory]::CreateDirectory($outputDirectory)
    [IO.File]::WriteAllText($summaryPath,
        "LAB663 deployment`r`nResult: RUNNING`r`nStage: Checking PowerShell 7 and Skillable inputs`r`n",
        [Text.UTF8Encoding]::new($false))
    $inputs = @{
        TenantId = $tenantId; SubscriptionId = $subscriptionId; ResourceGroup = $resourceGroup
        Location = $location; LabInstanceId = $labInstanceId
        AppId = $clientId; AppSecret = $clientSecret
    }
    foreach ($key in $inputs.Keys) {
        if ([string]::IsNullOrWhiteSpace($inputs[$key]) -or $inputs[$key].Contains($tokenPrefix)) {
            throw "Skillable did not supply $key. Check the profile's aliases and custom variables."
        }
    }
    foreach ($key in @('TenantId', 'SubscriptionId', 'AppId')) {
        $id = [guid]::Empty
        if (-not [guid]::TryParse($inputs[$key], [ref]$id) -or $id -eq [guid]::Empty) {
            throw "Skillable supplied an invalid $key. Object IDs must be GUIDs, not usernames."
        }
    }
    $deploy = Join-Path $repoRoot 'infra\pwsh\deploy.ps1'
    $common = Join-Path $repoRoot 'skillable_lifecycles\common.ps1'
    foreach ($path in @($deploy, $common, (Join-Path $repoRoot '.env.sample'))) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Missing $path. Set repoRoot to the prepared LAB663 checkout."
        }
    }
    if (-not (Test-Path -LiteralPath $powerShell7 -PathType Leaf)) {
        throw "PowerShell 7 is required at $powerShell7. Install it in the VM image or correct powerShell7 in this action. Windows PowerShell 5.1 will not be used for deployment."
    }
    $ErrorActionPreference = 'Continue'
    $PSNativeCommandUseErrorActionPreference = $false
    $global:LASTEXITCODE = 1
    $majorVersion = & $powerShell7 -NoLogo -NoProfile -NonInteractive -Command '$PSVersionTable.PSVersion.Major'
    $versionExitCode = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($versionExitCode -ne 0 -or "$majorVersion" -notmatch '^\d+$' -or [int]$majorVersion -lt 7) {
        throw "Could not verify PowerShell 7 or later at $powerShell7. Repair the VM image before deployment."
    }
    Write-Host "Deployment host: $powerShell7 (PowerShell $majorVersion)"
    . $common
    $manifestPath = Get-LabManifestPath $repoRoot $labInstanceId
    $environment = @{
        LAB663_CLIENT_ID = $clientId
        LAB663_CLIENT_SECRET = $clientSecret
        AZURE_SUBSCRIPTION_ID = $subscriptionId
        AZURE_LOCATION = $location.ToLowerInvariant()
    }
    foreach ($key in $environment.Keys) {
        $savedEnvironment[$key] = [Environment]::GetEnvironmentVariable($key, 'Process')
        [Environment]::SetEnvironmentVariable($key, $environment[$key], 'Process')
    }
    # Authenticate before deploy.ps1 starts its transcript. Never print the credentials.
    $authenticationStarted = $true
    Start-LabAuthentication -TenantId $tenantId -SubscriptionId $subscriptionId `
        -StateDirectory (Split-Path $manifestPath -Parent)
    $bootstrapObjectId = Get-LabBootstrapObjectId -TenantId $tenantId -ClientId $clientId -SubscriptionId $subscriptionId

    # The child inherits the isolated Azure cache and process-only credentials, not command-line secrets.
    $deploymentArguments = @(
        '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
        '-File', $deploy, '-Yes', '-LearnerAccessManagedExternally',
        '-ResourceGroup', $resourceGroup, '-LabInstanceId', $labInstanceId,
        '-BootstrapPrincipalId', "$bootstrapObjectId", '-OutputDirectory', $outputDirectory
    )
    if ($skipAgent) { $deploymentArguments += '-SkipAgent' }
    if ($resumeDeployment) { $deploymentArguments += '-ResumeDeployment' }
    $ErrorActionPreference = 'Continue'
    $global:LASTEXITCODE = 1
    & $powerShell7 @deploymentArguments | Out-Host
    $deploymentExitCode = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($deploymentExitCode -ne 0) {
        throw 'LAB663 deployment failed. Read LAB663-deployment-output.txt and its run log on the desktop.'
    }
}
catch {
    Write-LifecycleFailure $_.Exception.Message
    throw
}
finally {
    try {
        if ($authenticationStarted) { Stop-LabAuthentication }
    }
    catch {
        Write-LifecycleFailure 'Could not clean up the temporary Azure sign-in. Ask the operator to inspect this VM before handover.'
        throw
    }
    finally {
        foreach ($key in $savedEnvironment.Keys) {
            if ($null -eq $savedEnvironment[$key]) {
                Remove-Item -LiteralPath "Env:\$key" -ErrorAction SilentlyContinue
            }
            else {
                [Environment]::SetEnvironmentVariable($key, $savedEnvironment[$key], 'Process')
            }
        }
        Remove-Variable -Name clientSecret, inputs, environment -ErrorAction SilentlyContinue
    }
}
