# First Displayable: Execute Script in Virtual Machine on Win11-Pro-Base; blocking.
$ErrorActionPreference = 'Stop'
$repoRoot = 'C:\Users\LabUser\Desktop\LAB663'
$python = Join-Path $repoRoot '.venv\Scripts\python.exe'
$env:LAB663_CLIENT_ID = '@lab.CloudSubscription.AppId'
$env:LAB663_CLIENT_SECRET = '@lab.CloudSubscription.AppSecret'
try {
    & (Join-Path $repoRoot 'skillable_lifecycles\setup.ps1') `
        -RepoRoot $repoRoot -Python $python

    & (Join-Path $repoRoot 'skillable_lifecycles\deployment.ps1') `
        -TenantId '@lab.CloudSubscription.TenantId' `
        -SubscriptionId '@lab.CloudSubscription.Id' `
        -ResourceGroup '@lab.CloudResourceGroup(ResourceGroup1).Name' `
        -Location '@lab.CloudResourceGroup(ResourceGroup1).Location' `
        -LabInstanceId '@lab.LabInstance.Id' `
        -LearnerObjectId '@lab.Variable(Lab663LearnerObjectId)' `
        -BootstrapObjectId '@lab.Variable(Lab663BootstrapObjectId)' `
        -RepoRoot $repoRoot -Python $python
}
finally {
    Remove-Item Env:\LAB663_CLIENT_ID, Env:\LAB663_CLIENT_SECRET -ErrorAction SilentlyContinue
}
