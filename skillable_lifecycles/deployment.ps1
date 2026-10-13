[CmdletBinding()]
param(
    [Parameter(Mandatory)][guid]$TenantId,
    [Parameter(Mandatory)][guid]$SubscriptionId,
    [Parameter(Mandatory)][string]$ResourceGroup,
    [Parameter(Mandatory)][string]$Location,
    [Parameter(Mandatory)][string]$LabInstanceId,
    [Parameter(Mandatory)][guid]$LearnerObjectId,
    [guid]$BootstrapObjectId = [guid]::Empty,
    [ValidateRange(1, 1000000)][int]$Capacity = 250,
    [string]$RepoRoot = (Split-Path $PSScriptRoot -Parent),
    [string]$Python = 'python',
    [switch]$UseCurrentAzureLogin,
    [switch]$CreateResourceGroup,
    [switch]$InfrastructureOnly
)

. (Join-Path $PSScriptRoot 'common.ps1')
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$manifestPath = Get-LabManifestPath $RepoRoot $LabInstanceId
$stateDirectory = Split-Path $manifestPath -Parent
$Location = $Location.ToLowerInvariant()
$deploymentName = "lab663-$LabInstanceId"
$compiledTemplate = Join-Path $stateDirectory "$LabInstanceId.template.json"
$parameterFile = Join-Path $stateDirectory "$LabInstanceId.parameters.json"
$envPath = Join-Path $RepoRoot '.env'
$manifest = $null

if (-not $UseCurrentAzureLogin -and $BootstrapObjectId -eq [guid]::Empty) {
    throw 'Supply the service principal OBJECT ID in BootstrapObjectId, not its application/client ID.'
}
if ($CreateResourceGroup -and $ResourceGroup -notmatch '^rg-lab663-[a-zA-Z0-9-]+$') {
    throw 'A lifecycle-created group must have an explicit rg-lab663- name.'
}
if (Test-Path -LiteralPath $manifestPath) {
    $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    if ($manifest.subscriptionId -ne "$SubscriptionId" -or $manifest.tenantId -ne "$TenantId" -or
        $manifest.resourceGroup -ne $ResourceGroup -or $manifest.location -ne $Location -or
        $manifest.learnerObjectId -ne "$LearnerObjectId" -or $manifest.capacity -ne $Capacity) {
        throw 'The saved lifecycle belongs to different deployment settings. Use a new lab instance ID.'
    }
    if ($manifest.phase -in @('deleted', 'purge-pending')) { throw 'This lab instance has entered teardown. Use a new lab instance ID.' }
    if (Test-Path -LiteralPath $envPath) {
        $savedSettings = Get-Content -LiteralPath $envPath
        if ("AZURE_RESOURCE_GROUP=$ResourceGroup" -notin $savedSettings -or
            "AZURE_SUBSCRIPTION_ID=$SubscriptionId" -notin $savedSettings) {
            throw 'The current .env belongs to another environment. Preserve it before resuming this deployment.'
        }
    }
}
elseif (Test-Path -LiteralPath $envPath) {
    throw 'An existing .env has no matching lifecycle manifest. Preserve it before deploying a different environment.'
}

if (-not $InfrastructureOnly) {
    & (Join-Path $PSScriptRoot 'setup.ps1') -RepoRoot $RepoRoot -Python $Python -CheckOnly
}
else {
    Write-Warning 'Infrastructure-only rehearsal: notebook prerequisites and agent setup are NOT being verified.'
}
Invoke-LabAz @('bicep', 'version') | Out-Null
Invoke-LabAz @('bicep', 'build', '--file', (Join-Path $RepoRoot 'infra\main.bicep'), '--outfile', $compiledTemplate) | Out-Null

try {
    Start-LabAuthentication -TenantId "$TenantId" -SubscriptionId "$SubscriptionId" `
        -StateDirectory $stateDirectory -UseCurrentAzureLogin:$UseCurrentAzureLogin

    foreach ($provider in @('Microsoft.CognitiveServices', 'Microsoft.Insights', 'Microsoft.OperationalInsights')) {
        $registration = Invoke-LabAz @('provider', 'show', '--namespace', $provider, '--subscription', "$SubscriptionId",
            '--query', 'registrationState', '--output', 'tsv')
        if ($registration -ne 'Registered') {
            throw "$provider is not registered. The subscription administrator must register it before the lab."
        }
    }

    $exists = (Invoke-LabAz @('group', 'exists', '--name', $ResourceGroup, '--subscription', "$SubscriptionId", '--output', 'tsv')) -eq 'true'
    if ($exists) {
        $group = Invoke-LabAz @('group', 'show', '--name', $ResourceGroup, '--subscription', "$SubscriptionId", '--output', 'json') | ConvertFrom-Json
        if ($CreateResourceGroup) { Assert-LabResourceOwnership $group $LabInstanceId }
        $resources = @(Invoke-LabAz @('resource', 'list', '--resource-group', $ResourceGroup, '--subscription', "$SubscriptionId",
            '--output', 'json') | ConvertFrom-Json)
        foreach ($resource in $resources | Where-Object { $_.name -match '^(aif|appi|log)-lab663-' }) {
            Assert-LabResourceOwnership $resource $LabInstanceId
        }
    }
    elseif (-not $CreateResourceGroup) {
        throw 'The allocated Skillable resource group does not exist. The lifecycle does not create groups unless explicitly requested.'
    }

    $catalog = @(Invoke-LabAz @('cognitiveservices', 'model', 'list', '--location', $Location,
        '--subscription', "$SubscriptionId", '--output', 'json') | ConvertFrom-Json)
    $usage = @(Invoke-LabAz @('cognitiveservices', 'usage', 'list', '--location', $Location,
        '--subscription', "$SubscriptionId", '--output', 'json') | ConvertFrom-Json)
    $wanted = @(
        @{ name = 'gpt-5.4'; version = '2026-03-05'; count = 1 },
        @{ name = 'gpt-5.4-mini'; version = '2026-03-17'; count = 1 },
        @{ name = 'model-router'; version = '2025-11-18'; count = 4 }
    )
    $existingDeployments = @()
    if ($exists) {
        foreach ($account in $resources | Where-Object { $_.type -eq 'Microsoft.CognitiveServices/accounts' -and $_.name -match '^aif-lab663-' }) {
            $existingDeployments += @(Invoke-LabAz @('cognitiveservices', 'account', 'deployment', 'list',
                '--resource-group', $ResourceGroup, '--name', $account.name, '--subscription', "$SubscriptionId", '--output', 'json') | ConvertFrom-Json)
        }
    }
    foreach ($model in $wanted) {
        $available = @($catalog | Where-Object { $_.model.name -eq $model.name -and $_.model.version -eq $model.version })
        $sku = @($available | ForEach-Object { $_.model.skus } | Where-Object { $_.name -eq 'GlobalStandard' }) | Select-Object -First 1
        if (-not $sku) { throw "$($model.name)@$($model.version) is unavailable as GlobalStandard in $Location." }
        $quota = $usage | Where-Object { $_.name.value -eq $sku.usageName } | Select-Object -First 1
        if (-not $quota) { throw "No quota record was returned for $($sku.usageName)." }
        $allocated = ($existingDeployments | Where-Object { $_.properties.model.name -eq $model.name } |
            ForEach-Object { $_.sku.capacity } | Measure-Object -Sum).Sum
        $additional = [Math]::Max(0, $Capacity * $model.count - $allocated)
        if ($quota.currentValue + $additional -gt $quota.limit) {
            throw "Insufficient quota for $($model.name): need $additional more capacity units; $($quota.limit - $quota.currentValue) available."
        }
        Write-Host "PASS catalog and quota: $($model.name)"
    }

    if (-not $manifest) {
        $manifest = [pscustomobject]@{
            schemaVersion = 1; labInstanceId = $LabInstanceId; tenantId = "$TenantId"
            subscriptionId = "$SubscriptionId"; resourceGroup = $ResourceGroup; location = $Location
            learnerObjectId = "$LearnerObjectId"; capacity = $Capacity
            ownsResourceGroup = [bool]$CreateResourceGroup; deploymentName = $deploymentName
            phase = 'planned'; managedResourceIds = @(); accountName = $null; projectEndpoint = $null
        }
        Write-LabJson $manifestPath $manifest
    }
    if (-not $exists) {
        Invoke-LabAz @('group', 'create', '--name', $ResourceGroup, '--location', $Location, '--subscription', "$SubscriptionId",
            '--tags', "lab663Instance=$LabInstanceId", 'lab663ManagedBy=lifecycle', '--output', 'none') | Out-Null
    }

    $parameters = @{
        location = @{ value = $Location }
        principalId = @{ value = "$LearnerObjectId" }
        bootstrapPrincipalId = @{ value = $(if ($UseCurrentAzureLogin) { '' } else { "$BootstrapObjectId" }) }
        capacity = @{ value = $Capacity }
        resourceTags = @{ value = @{ lab663Instance = $LabInstanceId; lab663ManagedBy = 'lifecycle' } }
    }
    Write-LabJson $parameterFile @{ parameters = $parameters }
    $deploymentArguments = @('--resource-group', $ResourceGroup, '--subscription', "$SubscriptionId",
        '--name', $deploymentName, '--template-file', $compiledTemplate, '--parameters', "@$parameterFile", '--output', 'none')
    Invoke-LabAz (@('deployment', 'group', 'validate') + $deploymentArguments) | Out-Null
    $manifest.phase = 'deploying'
    Write-LabJson $manifestPath $manifest
    Write-Host 'Deploying the Foundry project, models and monitoring.'
    Invoke-LabAz (@('deployment', 'group', 'create') + $deploymentArguments) | Out-Null

    $outputs = Invoke-LabAz @('deployment', 'group', 'show', '--resource-group', $ResourceGroup, '--subscription', "$SubscriptionId",
        '--name', $deploymentName, '--query', 'properties.outputs', '--output', 'json') | ConvertFrom-Json
    $manifest.managedResourceIds = @($outputs.managedResourceIds.value)
    $manifest.accountName = $outputs.accountName.value
    $manifest.projectEndpoint = $outputs.projectEndpoint.value
    $manifest.phase = 'infrastructure-ready'
    Write-LabJson $manifestPath $manifest

    $connection = Invoke-LabAz @('resource', 'show', '--resource-group', $ResourceGroup, '--subscription', "$SubscriptionId",
        '--name', $outputs.applicationInsightsName.value, '--resource-type', 'Microsoft.Insights/components',
        '--query', 'properties.ConnectionString', '--output', 'tsv')
    $settings = @(
        '# Generated locally by the LAB663 lifecycle. Never commit this file.'
        "FOUNDRY_PROJECT_ENDPOINT=$($outputs.projectEndpoint.value)"
        'TRAILMATE_AGENT_NAME=trailmate'
        'TRAILMATE_MODEL_DEPLOYMENT=gpt-5.4'
        'TRAILMATE_SMALL_MODEL_DEPLOYMENT=gpt-5.4-mini'
        "APPLICATIONINSIGHTS_CONNECTION_STRING=$connection"
        "AZURE_SUBSCRIPTION_ID=$SubscriptionId"
        "AZURE_TENANT_ID=$TenantId"
        "AZURE_RESOURCE_GROUP=$ResourceGroup"
        "AZURE_AI_ACCOUNT_NAME=$($outputs.accountName.value)"
        "AZURE_AI_PROJECT_NAME=$($outputs.projectName.value)"
        "AZURE_LOCATION=$Location"
        'LAB663_DELIVERY_MODE=skillable'
    )
    [IO.File]::WriteAllText($envPath, ($settings -join "`n") + "`n", [Text.UTF8Encoding]::new($false))

    if ($InfrastructureOnly) {
        Write-Host 'Infrastructure is ready. Agent creation and notebook validation were skipped; this is not a learner-ready result.'
    }
    else {
        & $Python (Join-Path $RepoRoot 'src\agent\01_build_agent.py')
        if ($LASTEXITCODE -ne 0) { throw 'Agent setup failed. Infrastructure is retained; rerun with the same lab instance ID after correcting the error.' }
        $manifest.phase = 'agent-ready'
        Write-LabJson $manifestPath $manifest
        Write-Host 'Agent setup is complete. Sign in as the learner and run notebook 01 before opening the lab to attendees.'
    }
}
finally {
    Stop-LabAuthentication
}
