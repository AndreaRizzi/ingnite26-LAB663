<#
.SYNOPSIS
Deletes the resource group that infra/pwsh/deploy.ps1 (or infra/deploy.sh) created. By default, that is all it does.

.DESCRIPTION
Run it:                 ./infra/pwsh/cleanup.ps1
Name a group yourself:  ./infra/pwsh/cleanup.ps1 rg-lab663-1234
Also purge the deleted Foundry resource (frees its model quota):  ./infra/pwsh/cleanup.ps1 -Purge

Safety:
  - It deletes only the one resource group, in one named subscription.
  - It lists what's inside and makes us type the group's name to confirm.
  - It never touches our local files. Delete .env and .lab-state.json yourself if you want to.

.PARAMETER ResourceGroup
The resource group to delete. Defaults to AZURE_RESOURCE_GROUP in .env.

.PARAMETER Purge
Also purge the deleted Foundry resource so its model quota is freed.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ResourceGroup,
    [switch]$Purge
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$EnvFile = Join-Path $RepoRoot '.env'

function Invoke-Az {
    $output = & az @args
    if ($LASTEXITCODE -ne 0) { throw "This command failed: az $($args -join ' ')" }
    return $output
}

function Exit-WithMessage([string]$Message, [int]$Code = 1) {
    Write-Host $Message
    exit $Code
}

# Read one value from .env without running it as code.
function Get-EnvValue([string]$Name) {
    if (-not (Test-Path $EnvFile)) { return '' }
    $line = Get-Content -Path $EnvFile | Where-Object { $_.StartsWith("$Name=") } | Select-Object -First 1
    if ($line) { return $line.Substring($Name.Length + 1) }
    return ''
}

$EnvGroup = Get-EnvValue 'AZURE_RESOURCE_GROUP'
if (-not $ResourceGroup) { $ResourceGroup = $EnvGroup }
if (-not $ResourceGroup) { Exit-WithMessage 'No resource group found. Pass one:  ./infra/pwsh/cleanup.ps1 rg-lab663-1234' }

$ErrorActionPreference = 'Continue'
& az account show *> $null
$signedIn = $LASTEXITCODE -eq 0
$ErrorActionPreference = 'Stop'
if (-not $signedIn) { Exit-WithMessage "We're not signed in. Run:  az login --use-device-code" }

# Use the subscription we deployed into, but only when the group is the one in .env.
$SubscriptionId = ''
if ($ResourceGroup -eq $EnvGroup) { $SubscriptionId = Get-EnvValue 'AZURE_SUBSCRIPTION_ID' }
if (-not $SubscriptionId) { $SubscriptionId = Invoke-Az account show --query id --output tsv }
$SubscriptionName = Invoke-Az account show --subscription $SubscriptionId --query name --output tsv

if ((Invoke-Az group exists --name $ResourceGroup --subscription $SubscriptionId) -ne 'true') {
    Exit-WithMessage "The resource group '$ResourceGroup' doesn't exist in subscription '$SubscriptionName'. Nothing to delete." 0
}

Write-Host "Subscription  : $SubscriptionName ($SubscriptionId)"
Write-Host "Resource group: $ResourceGroup"
Write-Host ''
Write-Host 'This is everything inside it:'
Invoke-Az resource list --resource-group $ResourceGroup --subscription $SubscriptionId `
    --query "[].{Name:name, Type:type}" --output table | Out-Host
Write-Host ''

# For -Purge we need the Foundry resource's name and region, and the group is the only place to look them up.
$AccountName = ''
$Location = ''
if ($Purge) {
    $AccountName = Invoke-Az cognitiveservices account list --resource-group $ResourceGroup --subscription $SubscriptionId `
        --query "[?kind=='AIServices'].name | [0]" --output tsv
    $Location = Invoke-Az cognitiveservices account list --resource-group $ResourceGroup --subscription $SubscriptionId `
        --query "[?kind=='AIServices'].location | [0]" --output tsv
}

Write-Host "Deleting the group removes all of it, and can't be undone."
$typed = Read-Host 'To confirm, type the resource group name'
if ($typed -cne $ResourceGroup) { Exit-WithMessage "That doesn't match. Nothing was deleted." 0 }

Write-Host 'Deleting (this takes a few minutes)...'
Invoke-Az group delete --name $ResourceGroup --subscription $SubscriptionId --yes | Out-Null
Write-Host "Deleted '$ResourceGroup' from '$SubscriptionName'."

if ($Purge -and $AccountName -and $Location) {
    $deleted = Invoke-Az cognitiveservices account list-deleted --subscription $SubscriptionId `
        --query "[?name=='$AccountName'] | [0].name" --output tsv
    if ($deleted) {
        Write-Host "Purging the deleted Foundry resource '$AccountName'..."
        Invoke-Az cognitiveservices account purge --location $Location --resource-group $ResourceGroup `
            --name $AccountName --subscription $SubscriptionId --output none | Out-Null
        Write-Host 'Purged.'
    } else {
        Write-Host "No deleted Foundry resource named '$AccountName' to purge."
    }
}

Write-Host 'Nothing else was changed. Our local .env and .lab-state.json are still here.'
