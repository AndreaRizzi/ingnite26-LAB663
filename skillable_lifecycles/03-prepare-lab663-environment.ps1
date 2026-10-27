# First Displayable: Execute Script in Virtual Machine on Win11-Pro-Base; blocking.
# Paste this complete file into the matching Skillable VM action.
# Deploys infra\main.bicep, or finishes an existing infra\skillable.bicep deployment.
# Populates the existing .env and creates the starting TrailMate agent.
# Run on the VM, not in Execute Script in Cloud Platform: the learner needs these local files.
$env:PSExecutionPolicyPreference = 'Bypass'
$ErrorActionPreference = 'Stop'
$repoRoot = 'C:\Users\LabUser\Desktop\LAB663'
# For the resource-template path, set this to its exact ARM deployment name.
# Leave empty for the original all-in-one lifecycle deployment.
$resourceDeploymentName = ''
# Leave empty to write the status file to the desktop of the account that runs this action.
$statusDirectory = ''
$python = Join-Path $repoRoot '.venv\Scripts\python.exe'
$clientSecret = '@lab.CloudSubscription.AppSecret'
$env:LAB663_CLIENT_ID = '@lab.CloudSubscription.AppId'
$env:LAB663_CLIENT_SECRET = $clientSecret
$deploymentArguments = @{
    TenantId = '@lab.CloudSubscription.TenantId'
    SubscriptionId = '@lab.CloudSubscription.Id'
    ResourceGroup = '@lab.CloudResourceGroup(ResourceGroup1).Name'
    Location = 'eastus2'
    LabInstanceId = '@lab.LabInstance.Id'
    LearnerObjectId = '@lab.Variable(Lab663LearnerObjectId)'
    BootstrapObjectId = '@lab.Variable(Lab663BootstrapObjectId)'
}
$earlierResults = [ordered]@{
    'GitHub Copilot access (action 1)' = '@lab.Variable(Lab663CopilotAccessStatus)'
    'Learner Azure roles (action 2)' = '@lab.Variable(Lab663AzureRolesStatus)'
}
# Split so Skillable never treats it as a replacement token.
$tokenPrefix = '@' + 'lab.'
$statusStarted = [DateTime]::UtcNow.ToString('u')
$statusStage = 'Checking the action inputs and LAB663 checkout'

function Write-Lab663Status {
    param([Parameter(Mandatory)][string]$Result, $ErrorRecord)
    # A status file problem only warns. It never replaces the action's own result.
    try {
        $lines = New-Object System.Collections.Generic.List[string]
        $lines.Add('LAB663 environment preparation (Skillable action 3)')
        $lines.Add("Result: $Result")
        $lines.Add("Stage: $statusStage")
        foreach ($name in $earlierResults.Keys) {
            $value = [string]$earlierResults[$name]
            if (-not $value -or $value.StartsWith($tokenPrefix)) { $value = 'not reported; check this action on the lab instance details page' }
            $lines.Add("${name}: $value")
        }
        $lines.Add("Lab instance: $($deploymentArguments.LabInstanceId)")
        $lines.Add("Checkout: $repoRoot")
        $lines.Add("Run as: $([Security.Principal.WindowsIdentity]::GetCurrent().Name)")
        $lines.Add("Started (UTC): $statusStarted")
        $lines.Add("Updated (UTC): $([DateTime]::UtcNow.ToString('u'))")
        if ($ErrorRecord) {
            $message = [string]$ErrorRecord.Exception.Message
            if ($clientSecret) { $message = $message.Replace($clientSecret, '[redacted]') }
            $lines.Add('Error: ' + ($message -replace '\s*[\r\n]+\s*', ' ').Trim())
        }
        if ($Result -eq 'SUCCEEDED') {
            $envPath = Join-Path $repoRoot '.env'
            if (Test-Path -LiteralPath $envPath -PathType Leaf) {
                foreach ($line in [IO.File]::ReadAllLines($envPath)) {
                    if ($line -match '^AZURE_AI_ACCOUNT_NAME=(.+)$') { $lines.Add("Foundry account: $($Matches[1].Trim())") }
                    elseif ($line -match '^AZURE_AI_PROJECT_NAME=(.+)$') { $lines.Add("Foundry project: $($Matches[1].Trim())") }
                }
            }
            $lines.Add('Foundry portal: open the project above. Do not create a new project.')
            $lines.Add('Next step: follow Step 1 of the Skillable walkthrough.')
        }
        elseif ($Result -eq 'FAILED') {
            $lines.Add('Next step: do not start the lab. Ask the facilitator to review action 3 on the lab instance details page.')
        }
        else {
            $lines.Add("Next step: wait. If this still says RUNNING after the action's timeout, Skillable stopped the action; tell the facilitator.")
        }
        $directory = $statusDirectory
        if (-not $directory) {
            $folder = if ([Security.Principal.WindowsIdentity]::GetCurrent().IsSystem) { 'CommonDesktopDirectory' } else { 'Desktop' }
            $directory = [Environment]::GetFolderPath($folder)
        }
        if (-not $directory) { throw 'No desktop folder is available for this account.' }
        [void][IO.Directory]::CreateDirectory($directory)
        [IO.File]::WriteAllText((Join-Path $directory 'LAB663-03-environment-status.txt'),
            (($lines -join "`r`n") + "`r`n"), [Text.UTF8Encoding]::new($false))
    }
    catch {
        Write-Warning "The LAB663 status file was not written: $($_.Exception.Message)"
    }
}

try {
    Write-Lab663Status -Result RUNNING
    $missing = @($deploymentArguments.Keys | Where-Object {
        $value = [string]$deploymentArguments[$_]
        -not $value -or $value.StartsWith($tokenPrefix)
    })
    if (-not $env:LAB663_CLIENT_ID -or $env:LAB663_CLIENT_ID.StartsWith($tokenPrefix)) { $missing += 'AppId' }
    if (-not $clientSecret -or $clientSecret.StartsWith($tokenPrefix)) { $missing += 'AppSecret' }
    if ($missing.Count) {
        throw "Skillable did not supply these values: $(($missing | Sort-Object) -join ', '). Check the profile's credential and resource group aliases and custom variables."
    }
    $setup = Join-Path $repoRoot 'skillable_lifecycles\setup.ps1'
    $deploymentScript = if ($resourceDeploymentName) { 'post-deployment.ps1' } else { 'deployment.ps1' }
    $deployment = Join-Path $repoRoot "skillable_lifecycles\$deploymentScript"
    if ($resourceDeploymentName) {
        if ($resourceDeploymentName.Contains($tokenPrefix)) {
            throw 'The resource deployment name is an unresolved Skillable token. Supply the exact completed ARM deployment name.'
        }
        $deploymentArguments.ResourceDeploymentName = $resourceDeploymentName
    }
    foreach ($path in @($setup, $deployment, (Join-Path $repoRoot '.env.sample'))) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Cannot find $path. Set `$repoRoot in this action to the pinned LAB663 checkout on the VM."
        }
    }

    $statusStage = 'Checking VM prerequisites (setup.ps1)'
    Write-Lab663Status -Result RUNNING
    & $setup -RepoRoot $repoRoot -Python $python -SkipBicep:([bool]$resourceDeploymentName)

    $statusStage = if ($resourceDeploymentName) {
        'Reading deployed Azure resources, populating .env and preparing the starting agent (post-deployment.ps1)'
    }
    else {
        'Deploying Azure resources and the starting agent (deployment.ps1)'
    }
    Write-Lab663Status -Result RUNNING
    & $deployment @deploymentArguments -RepoRoot $repoRoot -Python $python

    $statusStage = 'Complete'
    Write-Lab663Status -Result SUCCEEDED
}
catch {
    Write-Lab663Status -Result FAILED -ErrorRecord $_
    throw
}
finally {
    Remove-Item Env:\LAB663_CLIENT_ID, Env:\LAB663_CLIENT_SECRET -ErrorAction SilentlyContinue
    Remove-Variable -Name clientSecret -ErrorAction SilentlyContinue
}
