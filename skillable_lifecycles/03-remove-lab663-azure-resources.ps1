# Tearing Down: Execute Script in Virtual Machine on the same VM; blocking.
$ErrorActionPreference = 'Stop'
$repoRoot = 'C:\Users\LabUser\Desktop\LAB663'
$env:LAB663_CLIENT_ID = '@lab.CloudSubscription.AppId'
$env:LAB663_CLIENT_SECRET = '@lab.CloudSubscription.AppSecret'
try {
    & (Join-Path $repoRoot 'skillable_lifecycles\teardown.ps1') `
        -LabInstanceId '@lab.LabInstance.Id' `
        -ConfirmInstanceId '@lab.LabInstance.Id' `
        -RepoRoot $repoRoot `
        -PurgeDeletedAccount `
        -Confirm:$false
}
finally {
    Remove-Item Env:\LAB663_CLIENT_ID, Env:\LAB663_CLIENT_SECRET -ErrorAction SilentlyContinue
}
