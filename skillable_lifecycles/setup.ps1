[CmdletBinding()]
param(
    [string]$RepoRoot = (Split-Path $PSScriptRoot -Parent),
    [string]$Python = 'python',
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

# Use the repository requirements as the version contract; do not silently upgrade a classroom VM.
@'
import importlib.metadata
import sys
from pathlib import Path
from packaging.requirements import Requirement

root = Path(sys.argv[1])
failures = []

def check(path):
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.split("#", 1)[0].strip()
        if not line:
            continue
        if line.startswith("-r "):
            check(path.parent / line[3:].strip())
            continue
        requirement = Requirement(line)
        if requirement.marker and not requirement.marker.evaluate():
            continue
        try:
            installed = importlib.metadata.version(requirement.name)
        except importlib.metadata.PackageNotFoundError:
            failures.append(f"{requirement.name}: not installed")
            continue
        if installed not in requirement.specifier:
            failures.append(f"{requirement.name}: {installed} does not satisfy {requirement.specifier}")
        else:
            print(f"PASS {requirement.name} {installed}")

check(root / "requirements.txt")
if failures:
    raise SystemExit("VM image dependencies need attention:\n" + "\n".join(failures))
print("PASS repository Python requirements")
'@ | & $Python - $RepoRoot
if ($LASTEXITCODE -ne 0) {
    throw 'Python prerequisite check failed. No Azure resources were changed.'
}

if (-not $CheckOnly) {
    & $Python -m ipykernel install --user --name lab663 --display-name 'Python (LAB663)'
    if ($LASTEXITCODE -ne 0) { throw 'Could not register the LAB663 notebook kernel.' }
}

Write-Host 'VM prerequisites are ready. Azure deployment and learner sign-in are separate checks.'
