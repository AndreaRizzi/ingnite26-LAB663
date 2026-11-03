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
    [string]$Python = (Join-Path $RepoRoot '.venv\Scripts\python.exe'),
    [switch]$UseCurrentAzureLogin,
    [switch]$CreateResourceGroup,
    [switch]$InfrastructureOnly
)

. (Join-Path $PSScriptRoot 'common.ps1')
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$manifestPath = Get-LabManifestPath $RepoRoot $LabInstanceId
$stateDirectory = Split-Path $manifestPath -Parent
$Location = $Location.ToLowerInvariant()
if ($Location -notin $LabRegions) {
    throw "LAB663 resources must be deployed to $($LabRegions -join ' or '). The allocated group metadata location does not select the resource region."
}
$deploymentName = "lab663-$LabInstanceId"
$compiledTemplate = Join-Path $stateDirectory "$LabInstanceId.template.json"
$parameterFile = Join-Path $stateDirectory "$LabInstanceId.parameters.json"
$manifest = $null

if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot '.env.sample') -PathType Leaf)) {
    throw 'The checkout is missing .env.sample. Restore it before running the deployment lifecycle.'
}

if (-not $UseCurrentAzureLogin -and $BootstrapObjectId -eq [guid]::Empty) {
    throw 'Supply the service principal OBJECT ID in BootstrapObjectId, not its application/client ID.'
}
if ($CreateResourceGroup -and $ResourceGroup -notmatch '^rg-lab663-[a-zA-Z0-9-]+$') {
    throw 'A lifecycle-created group must have an explicit rg-lab663- name.'
}
if (Test-Path -LiteralPath $manifestPath) {
    $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    if ($manifest.schemaVersion -ne 1 -or $manifest.labInstanceId -cne $LabInstanceId -or
        $manifest.subscriptionId -ne "$SubscriptionId" -or $manifest.tenantId -ne "$TenantId" -or
        $manifest.resourceGroup -ne $ResourceGroup -or $manifest.location -ne $Location -or
        $manifest.learnerObjectId -ne "$LearnerObjectId" -or $manifest.capacity -ne $Capacity -or
        $manifest.ownsResourceGroup -ne [bool]$CreateResourceGroup) {
        throw 'The saved lifecycle belongs to different deployment settings. Use a new lab instance ID.'
    }
    if ($manifest.phase -in @('deleting', 'deleted', 'purge-pending')) { throw 'This lab instance has entered teardown. Use a new lab instance ID.' }
}

if (-not $InfrastructureOnly) {
    & (Join-Path $PSScriptRoot 'setup.ps1') -RepoRoot $RepoRoot -Python $Python -CheckOnly
}
else {
    Write-Warning 'Infrastructure-only rehearsal: notebook prerequisites and agent setup are NOT being verified.'
}
Invoke-LabAz @('bicep', 'version') | Out-Null
Invoke-LabAz @('bicep', 'build', '--file', (Join-Path $RepoRoot 'infra\main.bicep'), '--outfile', $compiledTemplate) | Out-Null
$template = Get-Content -Raw -LiteralPath $compiledTemplate | ConvertFrom-Json
$defaults = $template.parameters
if ($defaults.chatModels.defaultValue.Count -ne 2) {
    throw 'LAB663 requires two chat deployments: the frontier model first and the smaller model second.'
}
$wanted = @(
    foreach ($model in $defaults.chatModels.defaultValue) {
        [pscustomobject]@{ name = $model.name; version = $model.version; deploymentName = $model.name }
    }
    foreach ($edition in $defaults.routerEditions.defaultValue) {
        [pscustomobject]@{
            name = $defaults.routerModelName.defaultValue
            version = $defaults.routerModelVersion.defaultValue
            deploymentName = $edition.name
        }
    }
)
$skuName = $defaults.skuName.defaultValue

try {
    Start-LabAuthentication -TenantId "$TenantId" -SubscriptionId "$SubscriptionId" `
        -StateDirectory $stateDirectory -UseCurrentAzureLogin:$UseCurrentAzureLogin

    foreach ($provider in @('Microsoft.CognitiveServices', 'Microsoft.Insights', 'Microsoft.OperationalInsights', 'Microsoft.AlertsManagement')) {
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
        $resources = @((Invoke-LabAz @('resource', 'list', '--resource-group', $ResourceGroup, '--subscription', "$SubscriptionId",
            '--output', 'json') | ConvertFrom-Json))
        foreach ($resource in $resources | Where-Object { $_.name -match '^(aif|appi|log)-lab663-' }) {
            Assert-LabResourceOwnership $resource $LabInstanceId
        }
    }
    elseif (-not $CreateResourceGroup) {
        throw 'The allocated Skillable resource group does not exist. The lifecycle does not create groups unless explicitly requested.'
    }

    $catalog = @((Invoke-LabAz @('cognitiveservices', 'model', 'list', '--location', $Location,
        '--subscription', "$SubscriptionId", '--output', 'json') | ConvertFrom-Json))
    $usage = @((Invoke-LabAz @('cognitiveservices', 'usage', 'list', '--location', $Location,
        '--subscription', "$SubscriptionId", '--output', 'json') | ConvertFrom-Json))
    $existingDeployments = @()
    if ($exists) {
        foreach ($account in $resources | Where-Object { $_.type -eq 'Microsoft.CognitiveServices/accounts' -and $_.name -match '^aif-lab663-' }) {
            $existingDeployments += @((Invoke-LabAz @('cognitiveservices', 'account', 'deployment', 'list',
                '--resource-group', $ResourceGroup, '--name', $account.name, '--subscription', "$SubscriptionId", '--output', 'json') | ConvertFrom-Json))
        }
    }
    $quotaRequirements = @{}
    foreach ($model in $wanted) {
        $available = @($catalog | Where-Object { $_.model.name -eq $model.name -and $_.model.version -eq $model.version })
        $sku = @($available | ForEach-Object { $_.model.skus } | Where-Object { $_.name -eq $skuName }) | Select-Object -First 1
        if (-not $sku) { throw "$($model.name)@$($model.version) is unavailable as $skuName in $Location." }
        if (-not $sku.usageName) { throw "No quota usage name was returned for $($model.name)." }
        $existing = @($existingDeployments | Where-Object {
            $_.name -eq $model.deploymentName -and $_.properties.model.name -eq $model.name -and
            $_.properties.model.version -eq $model.version -and $_.sku.name -eq $skuName
        })
        if ($existing.Count -gt 1) { throw "More than one existing deployment matches $($model.deploymentName)." }
        $allocated = 0
        if ($existing.Count) { $allocated = [Math]::Min($Capacity, $existing[0].sku.capacity) }
        if (-not $quotaRequirements.ContainsKey($sku.usageName)) { $quotaRequirements[$sku.usageName] = 0 }
        $quotaRequirements[$sku.usageName] += $Capacity - $allocated
        Write-Host "PASS catalog: $($model.deploymentName)"
    }
    foreach ($usageName in $quotaRequirements.Keys) {
        $additional = $quotaRequirements[$usageName]
        $quota = $usage | Where-Object { $_.name.value -eq $usageName } | Select-Object -First 1
        if (-not $quota) { throw "No quota record was returned for $usageName." }
        if ($quota.currentValue + $additional -gt $quota.limit) {
            throw "Insufficient quota for ${usageName}: need $additional more capacity units; $($quota.limit - $quota.currentValue) available."
        }
        Write-Host "PASS quota: $usageName"
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

    Complete-LabDeployment -RepoRoot $RepoRoot -ManifestPath $manifestPath -Manifest $manifest `
        -Outputs $outputs -ChatModelNames @($defaults.chatModels.defaultValue | ForEach-Object { $_.name }) `
        -Python $Python -InfrastructureOnly:$InfrastructureOnly
}
finally {
    Stop-LabAuthentication
}
