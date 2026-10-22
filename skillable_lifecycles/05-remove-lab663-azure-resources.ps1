# Tearing Down: Execute Script in Virtual Machine on the same VM as action 3; blocking. Add it after action 4.
# Paste this complete file into the matching Skillable VM action.
$ErrorActionPreference = 'Stop'
$repoRoot = 'C:\Users\LabUser\Desktop\LAB663'
# Leave empty to write the status file to the desktop of the account that runs this action.
$statusDirectory = ''
$labInstanceId = '@lab.LabInstance.Id'
$clientSecret = '@lab.CloudSubscription.AppSecret'
$env:LAB663_CLIENT_ID = '@lab.CloudSubscription.AppId'
$env:LAB663_CLIENT_SECRET = $clientSecret
# Split so Skillable never treats it as a replacement token.
$tokenPrefix = '@' + 'lab.'
$statusStarted = [DateTime]::UtcNow.ToString('u')
$statusStage = 'Checking the action inputs and LAB663 checkout'

function Write-Lab663Status {
    param([Parameter(Mandatory)][string]$Result, $ErrorRecord)
    # A status file problem only warns. It never replaces the action's own result.
    try {
        $lines = New-Object System.Collections.Generic.List[string]
        $lines.Add('LAB663 Azure cleanup (Skillable action 5)')
        $lines.Add("Result: $Result")
        $lines.Add("Stage: $statusStage")
        $lines.Add("Lab instance: $labInstanceId")
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
            $lines.Add('Next step: none. This instance''s tagged LAB663 resources are gone and any Foundry account purge is verified.')
        }
        elseif ($Result -eq 'FAILED') {
            $lines.Add('Next step: review action 5 on the lab instance details page. Rerun teardown on this VM, or remove this instance''s lab663Instance-tagged resources, before reusing the subscription.')
        }
        else {
            $lines.Add("Next step: wait. If this still says RUNNING after the action's timeout, Skillable stopped the action; review action 5 on the lab instance details page.")
        }
        $directory = $statusDirectory
        if (-not $directory) {
            $folder = if ([Security.Principal.WindowsIdentity]::GetCurrent().IsSystem) { 'CommonDesktopDirectory' } else { 'Desktop' }
            $directory = [Environment]::GetFolderPath($folder)
        }
        if (-not $directory) { throw 'No desktop folder is available for this account.' }
        [void][IO.Directory]::CreateDirectory($directory)
        [IO.File]::WriteAllText((Join-Path $directory 'LAB663-05-azure-cleanup-status.txt'),
            (($lines -join "`r`n") + "`r`n"), [Text.UTF8Encoding]::new($false))
    }
    catch {
        Write-Warning "The LAB663 status file was not written: $($_.Exception.Message)"
    }
}

try {
    Write-Lab663Status -Result RUNNING
    $missing = @()
    if (-not $labInstanceId -or $labInstanceId.StartsWith($tokenPrefix)) { $missing += 'LabInstanceId' }
    if (-not $env:LAB663_CLIENT_ID -or $env:LAB663_CLIENT_ID.StartsWith($tokenPrefix)) { $missing += 'AppId' }
    if (-not $clientSecret -or $clientSecret.StartsWith($tokenPrefix)) { $missing += 'AppSecret' }
    if ($missing.Count) {
        throw "Skillable did not supply these values: $(($missing | Sort-Object) -join ', '). Check the lab instance and cloud subscription settings in the lab profile."
    }
    $teardown = Join-Path $repoRoot 'skillable_lifecycles\teardown.ps1'
    if (-not (Test-Path -LiteralPath $teardown -PathType Leaf)) {
        throw "Cannot find $teardown. Set `$repoRoot in this action to the same checkout path as action 3."
    }

    $statusStage = 'Removing Azure resources (teardown.ps1)'
    Write-Lab663Status -Result RUNNING
    & $teardown `
        -LabInstanceId '@lab.LabInstance.Id' `
        -ConfirmInstanceId '@lab.LabInstance.Id' `
        -RepoRoot $repoRoot `
        -PurgeDeletedAccount `
        -Confirm:$false

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
