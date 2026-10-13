# Skillable lifecycles

These actions prepare a Windows lab VM, deploy the existing LAB663 Bicep, create the starting agent, and remove only this lab's resources. They do not use `azd`, create a hosted application, or send learners through a portal workflow.

The lifecycle pattern is informed by the [ILL335 example supplied for this lab](https://github.com/microsoft/aitour27-ILL335-building-deploying-ai-agents-with-microsoft-foundry/tree/main/skillable_lifecycles). LAB663 uses its own Bicep and prompt-agent bootstrap rather than that example's hosted-agent deployment.

## Prepare the VM image

Use a reviewed, pinned repository commit on the VM, for example at `C:\Users\LabUser\Desktop\LAB663`. Do not download a moving `main` branch when each learner starts. Record the commit, image version and package versions used in the rehearsal.

The image must already contain Azure CLI, Bicep, VS Code with Python/Jupyter support, and a Python environment satisfying [`requirements.txt`](../requirements.txt). In particular, the lab requires `azure-ai-projects>=2.8.0`; an older SDK can create an agent but cannot run the newer rubric, insights and optimizer calls. Confirm preview feature access in the **Skillable subscription**, not just the development subscription.

The scripts deliberately do not install packages or update tools during a timed lab. Repair the image when a prerequisite check fails. Run the actions as the learner's Windows VM user so the notebook kernel and `.env` are available to that user.

| Action | When | Result |
|---|---|---|
| `setup.ps1` | VM startup, before learners arrive | Checks the repository's package requirements and Bicep; registers `Python (LAB663)` |
| `deployment.ps1` | After the Skillable cloud account and allocated resource group exist | Checks catalog/quota, deploys Bicep, writes local settings, indexes ten manuals and creates/pins v0 |
| Notebook 01 | After signing in as the **learner** | Checks learner access, every model endpoint, the pinned agent, index, tracing connection and data |
| `teardown.ps1` | Lab end or explicit failed-deployment cleanup | Deletes the instance's tagged resources; preserves the platform's resource group and VM |

**Expected:** no learner starts while setup, deployment or the learner identity check is pending or failing.

## Supply the cloud identity and scope

The Skillable lifecycle service principal needs resource deployment and role-assignment rights **on the allocated lab resource group**. The subscription administrator must register `Microsoft.CognitiveServices`, `Microsoft.Insights` and `Microsoft.OperationalInsights` beforehand. Normal Skillable deployment does not create a resource group or register providers.

Supply the learner's Entra **object ID** and the lifecycle service principal's **object ID** from the lab's identity provisioning step. An application/client ID is not a service principal object ID. The scripts accept these explicitly and do not require broad directory permissions just to look them up.

| Input | Source |
|---|---|
| Tenant and subscription | `@lab.CloudSubscription.TenantId`, `@lab.CloudSubscription.Id` |
| Resource group and region | `@lab.CloudResourceGroup(ResourceGroup1).Name`, `.Location` |
| Lab instance ID | `@lab.LabInstance.Id` |
| Client ID and secret | `@lab.CloudSubscription.AppId`, `.AppSecret`, injected into **process-only** variables |
| Learner object ID | Identity provisioning for `@lab.CloudPortalCredential(User1).Username` |
| Bootstrap object ID | Identity provisioning for the lifecycle service principal |

The macro names must match the resource group and credential aliases configured in the Skillable lab profile. Validate substitution in a real Skillable rehearsal; a successful local PowerShell run does not prove that mapping.

Bicep gives the learner and bootstrap principal Foundry access separately. The bootstrap identity authenticates using an isolated Azure CLI cache, which is removed afterwards. It is never left signed in for the learner, and its secret is never written to `.env`, a transcript or a committed file.

## Configure the startup actions

First run the VM prerequisite action with the interpreter prepared in the image:

```powershell
& C:\Users\LabUser\Desktop\LAB663\skillable_lifecycles\setup.ps1 `
    -Python C:\Users\LabUser\Desktop\LAB663\.venv\Scripts\python.exe
```

**Expected:** all package checks pass and `Python (LAB663)` is registered. `-CheckOnly` performs the checks without registering a kernel.

Then invoke deployment. In the following action wrapper, `$learnerObjectId` and `$bootstrapObjectId` must already have been supplied by the lab's identity provisioning. Do not replace them with invented Skillable macros.

```powershell
$env:LAB663_CLIENT_ID = '@lab.CloudSubscription.AppId'
$env:LAB663_CLIENT_SECRET = '@lab.CloudSubscription.AppSecret'
try {
    & C:\Users\LabUser\Desktop\LAB663\skillable_lifecycles\deployment.ps1 `
        -TenantId '@lab.CloudSubscription.TenantId' `
        -SubscriptionId '@lab.CloudSubscription.Id' `
        -ResourceGroup '@lab.CloudResourceGroup(ResourceGroup1).Name' `
        -Location '@lab.CloudResourceGroup(ResourceGroup1).Location' `
        -LabInstanceId '@lab.LabInstance.Id' `
        -LearnerObjectId $learnerObjectId `
        -BootstrapObjectId $bootstrapObjectId `
        -Python C:\Users\LabUser\Desktop\LAB663\.venv\Scripts\python.exe
}
finally {
    Remove-Item Env:\LAB663_CLIENT_ID, Env:\LAB663_CLIENT_SECRET -ErrorAction SilentlyContinue
}
```

**Expected:** six deployments, a project and monitoring resources; a local `.env`; ten indexed manuals; and a pinned v0 in `.lab-state.json`. The scripts retain failure details and a manifest under the ignored `.lab-lifecycle` directory. A failed action throws rather than reporting success.

Capacity defaults to 250 units for **each** deployment. Four router editions therefore require 1,000 available router capacity units per concurrently provisioned lab instance. Quota is shared at subscription/region/model/SKU scope; include all concurrent learners and existing allocations in the capacity plan. Catalog and quota checks do not reserve capacity or guarantee preview feature access.

Rerun a failed deployment with the **same instance ID and settings**. It reuses the resource group and deterministic Bicep names. It rejects unowned lab-named resources and settings that conflict with its manifest. Agent setup reuses the locally recorded index and matching v0; it refuses to adopt an unrecorded index or delete an incomplete one. Preserve `.lab-state.json` when recovering a failed setup.

`-InfrastructureOnly` is for an operator's deployment rehearsal. It explicitly skips package and agent checks and must **never** be treated as a learner-ready result.

## Hand over to the learner

After lifecycle authentication ends, the learner signs in using the assigned Skillable identity and follows the [Skillable walkthrough](../instructions/skillable/README.md). Notebook 01 must pass under that identity, not merely under the more privileged deployment principal.

The `.env` file has the same settings as self-guided delivery, plus `LAB663_DELIVERY_MODE=skillable`. It has no client secret or model API key. Do not run `infra/deploy.sh` from a Skillable VM: that script creates another resource group and uses a different ownership model.

**Expected:** learners open the shared core notebooks and can complete the hill-climbing workflow entirely in code.

## Configure teardown

Keep the ignored lifecycle manifest until cleanup finishes. Inject the same process-only lifecycle credentials, call teardown, then clear those variables as in the startup wrapper.

```powershell
& C:\Users\LabUser\Desktop\LAB663\skillable_lifecycles\teardown.ps1 `
    -LabInstanceId '@lab.LabInstance.Id' `
    -ConfirmInstanceId '@lab.LabInstance.Id' `
    -PurgeDeletedAccount `
    -Confirm:$false
```

**Expected:** only this instance's tagged resources and the generated anomaly alert scoped to its Application Insights resource are removed. Teardown deletes the Foundry project and its agents/indexes before deleting the parent account and model deployments; Azure refuses account deletion while a nested project remains. The allocated Skillable resource group and VM are preserved. Local `.env`, state and evidence files remain for review; discard the VM through the normal Skillable lifecycle afterwards.

Use `-WhatIf` to inspect the deletion targets first. Teardown requires a matching manifest, instance confirmation and live ownership tags; it does not search other subscriptions or guess a group from a prefix. Purging the exact soft-deleted account releases retained quota. It is permanent, so use it only for disposable lab environments. If the deleted record does not appear or purge cannot be verified within the bounded wait, the action fails with `purge-pending` in the manifest. Recheck and rerun teardown; do not claim quota was released or reuse that instance ID.

For a separate operator rehearsal, `deployment.ps1 -UseCurrentAzureLogin -CreateResourceGroup` creates a tagged `rg-lab663-...` group. Only such a lifecycle-owned group is eligible for `teardown.ps1 -DeleteResourceGroup`; the script refuses that option for a platform-allocated group or a group containing unrelated resources.

## Rehearse before opening the lab

Run the following checks on the actual Skillable image and subscription. A development-subscription pass is useful evidence, but it does not replace them.

- Confirm the pinned commit, package versions, macro substitution and preview feature access.
- Start a fresh instance; run notebook 01 as the learner and verify actual trace ingestion with notebook 04.
- Complete one rubric, optimizer and router path. Record wall time, error counts, complete per-case coverage and the promotion decision.
- Interrupt a wait and resume the saved run ID. Rerun setup without creating duplicate infrastructure or replacing authored agents.
- Exercise an invalid instance ID and `-WhatIf`; neither may delete anything.
- Tear down the tagged resources, verify removal and quota release, and confirm the allocated VM/resource group remain.

Keep the 60-minute schedule as a rehearsal target until it has been timed with beginner learners. Extra router editions and model experiments belong outside the core budget; never reduce the question set to make a run look faster.

### What has been rehearsed

On 13 October 2026, an isolated Azure deployment passed infrastructure provisioning and rerun, six model endpoint checks, ten-manual indexing and baseline reuse. Invalid confirmation and both teardown dry runs preserved resources. Resource-only teardown removed the generated alert, project, account and monitoring while retaining the group; a subsequent action removed the owned disposable group. Account purge was verified. The existing development group was not changed.

That rehearsal used the signed-in review account, not Skillable's service principal and learner identities. The local prerequisite check correctly rejected `azure-ai-projects` 2.1.0 and missing `matplotlib`; no packages were installed. Full notebook execution, the actual Skillable image/macros and learner timing still need a prepared-environment rehearsal. The [router/file-search service failure](../docs/narrative.md#what-the-isolated-rehearsal-tells-us) also remains unresolved.
