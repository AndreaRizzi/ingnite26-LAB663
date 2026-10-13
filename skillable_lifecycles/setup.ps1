[CmdletBinding()]
param(
    [string]$RepoRoot = (Split-Path $PSScriptRoot -Parent),
    [string]$Python = (Join-Path $RepoRoot '.venv\Scripts\python.exe'),
    [switch]$CheckOnly
)

. (Join-Path $PSScriptRoot 'common.ps1')
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path

foreach ($tool in @('az', $Python)) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        throw "'$tool' is missing. Prepare the Skillable VM image before running the lifecycle."
    }
}
Invoke-LabAz @('bicep', 'version') | Write-Host

& $Python (Join-Path $RepoRoot 'src\check_environment.py')
if ($LASTEXITCODE -ne 0) {
    throw 'Python prerequisite check failed. No Azure resources were changed.'
}

if (-not $CheckOnly) {
    & $Python -m ipykernel install --user --name lab663 --display-name 'Python (LAB663)'
    if ($LASTEXITCODE -ne 0) { throw 'Could not register the LAB663 notebook kernel.' }
}

Write-Host 'VM prerequisites are ready. Azure deployment and learner sign-in are separate checks.'
