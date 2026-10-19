# Skillable lifecycles

LAB663 requires both **GitHub Copilot access** and the **Azure Foundry environment**. These Skillable lifecycle actions assign the learner's GitHub/Copilot entitlement group, provision their enterprise identity, prepare the Windows VM and starting TrailMate agent, and clean up at lab end.

Deployment uses LAB663's [`infra/main.bicep`](../infra/main.bicep) to create the Foundry project, model deployments and monitoring, then runs [`src/agent/01_build_agent.py`](../src/agent/01_build_agent.py) to index the TrailMate manuals and create or reuse the starting agent.

## Configure four actions in Skillable

In **Edit Profile**, open **Advanced > Life Cycle Actions** and select **Add Life Cycle Action**. Existing actions can also be managed on the **Life Cycle** tab. Add the four actions below, keeping the listed order within each event. The [Skillable lifecycle reference](https://docs.skillable.com/docs/life-cycle-actions-5) explains these controls.

| Order and name | Event | Action type and target | File to copy into the action editor | Blocking | Timeout budget | Error action |
|---|---|---|---|---|---|---|
| 1. Prepare GitHub Copilot access | Post-Build | Execute Script in Cloud Platform; Azure; PowerShell | [`01-prepare-github-copilot-access.ps1`](01-prepare-github-copilot-access.ps1) | Yes | 10 minutes | End the lab on failure |
| 2. Prepare LAB663 environment | First Displayable | Execute Script in Virtual Machine; `Win11-Pro-Base`; PowerShell | [`02-prepare-lab663-environment.ps1`](02-prepare-lab663-environment.ps1) | Yes | 60 minutes | End the lab on failure |
| 3. Remove LAB663 Azure resources | Tearing Down | Execute Script in Virtual Machine; same VM; PowerShell | [`03-remove-lab663-azure-resources.ps1`](03-remove-lab663-azure-resources.ps1) | Yes | 30 minutes | Notify User; retain the error for the operator |
| 4. Remove GitHub Copilot entitlement | Tearing Down | Execute Script in Cloud Platform; Azure; PowerShell | [`04-remove-github-copilot-entitlement.ps1`](04-remove-github-copilot-entitlement.ps1) | Yes | 10 minutes | Notify User; retain the error for the operator |

Copy the **complete contents** of each numbered file into its matching Skillable action editor. The filenames are the action order. Files 01 and 04 include their cloud implementation; no manual insertion of another script is needed. In files 02 and 03, change `$repoRoot` to the same pinned checkout path on the VM.

The unnumbered `setup.ps1`, `deployment.ps1`, `teardown.ps1` and `common.ps1` are required VM implementation files, not additional Skillable actions. Keep them in the VM checkout: file 02 calls setup and deployment, file 03 calls teardown, and all three implementations load `common.ps1`. Files 01 and 04 are maintained directly as self-contained cloud actions; no separate cloud source or export utility is needed.

For every action, set **Enabled = Yes**, **Delay = 0**, **Retries = 0**, and leave **Repeat disabled**. These scripts throw on failure; they do not implement a true/false polling contract. Do not use **Log** alone for startup failures. For cleanup notifications, say that cleanup failed and the facilitator must review the lab instance error before reusing the account or subscription.

Timeouts are operator budgets, not measured service guarantees. Verify the effective VM/integration-service execution timeout in your Skillable host; Skillable's general documentation describes the Timeout control specifically for cloud/custom scripts. Project access can wait ten minutes and indexing another five, before counting infrastructure deployment. Do not retain the supplied ten-minute VM deployment limit without a rehearsal proving it sufficient.

**Post-Build** can occur while VMs are still starting, so only the cloud identity action runs there. **First Displayable** targets the running VM; blocking setup and deployment must finish before learner handover. The cloud fabric must finish allocating the learner and resource group first; configure **Fabric Build Sequence** accordingly instead of relying on a fixed sleep.

These four actions cover all six required steps: entitlement assignment, enterprise synchronization, VM setup, Foundry deployment, Azure cleanup and entitlement removal. `common.ps1` is a VM helper, not an action. Do not add standalone subscription-wide role assignment/removal: [`roles.bicep`](../infra/modules/roles.bicep) already assigns the required resource-scoped roles, and deleting those resources removes their assignments.

**Expected:** both GitHub/Copilot and Foundry are prepared, and a failure cannot silently hand over an incomplete lab.

## Supply the profile configuration

Use the actual credential alias `User1`, resource group alias `ResourceGroup1` and VM name from your profile. The table uses the names in the supplied lifecycle; change every corresponding wrapper reference if your profile differs. Check available built-in tokens with the instructions editor's **@lab** picker.

Create the following **non-secret** custom variables through the profile's [Variables panel](https://docs.skillable.com/docs/variables). These are names defined for this lab, not additional built-in Skillable tokens.

| Custom variable | Value and timing |
|---|---|
| `Lab663LearnerObjectId` | This instance's Entra user object ID for `@lab.CloudPortalCredential(User1).Username`; supplied by identity provisioning before Post-Build, never a static ID shared across learners |
| `Lab663BootstrapObjectId` | Service principal object ID corresponding to `@lab.CloudSubscription.AppId`; supplied for the allocated subscription before VM startup |
| `Lab663LicenseGroupObjectId` | Object ID of the static GitHub/Copilot entitlement group configured by the tenant administrator; the supplied group name was `_Skillable Events GHE w/ Copilot` |
| `Lab663GitHubServicePrincipalObjectId` | Object ID of the GitHub enterprise application's service principal, not its client/application ID |
| `Lab663GitHubSyncJobId` | Existing synchronization job in that enterprise application |
| `Lab663GitHubSyncRuleId` | Existing user-provisioning rule for that job |

The identity provisioning integration must set the first two variables for the allocated identities. If it sets them using `Set-LabVariable`, do so in an earlier action/event; replacement tokens cannot consume a variable created inside the same action. A UPN is not an object ID. Do not invent a `.ObjectId` property on `CloudPortalCredential` or reuse IDs from the example tenant.

Supply `LAB663_DIRECTORY_CLIENT_ID` and `LAB663_DIRECTORY_CLIENT_SECRET` as process environment variables in **each cloud action**, using the operator's approved protected secret-injection mechanism. Skillable does not create these variables automatically. Keep the dedicated Entra provisioning application from the supplied lifecycle separate from the subscription deployment application. Do not put its secret in Git, `.env`, ordinary lab variables or learner credential pools. Confirm this secret binding with the Skillable administrator before testing; the wrappers fail if it is missing.

The directory app needs admin-consented `GroupMember.ReadWrite.All`. For on-demand synchronization, the [Graph API reference](https://learn.microsoft.com/en-us/graph/api/synchronization-synchronizationjob-provisionondemand?view=graph-rest-1.0) lists `Application.ReadWrite.OwnedBy` for an application it owns, or `Synchronization.ReadWrite.All`. Configure the intended enterprise application's group assignment, provisioning scope and Copilot seat policy beforehand. A group name alone does not configure those services.

**Expected:** every custom variable resolves to the correct instance or tenant setting, and privileged directory credentials are available only to the cloud actions.

## Action 1: Prepare GitHub Copilot access

Paste the complete [`01-prepare-github-copilot-access.ps1`](01-prepare-github-copilot-access.ps1) file into the **Post-Build** cloud action. It is self-contained: it needs no repository checkout, helper file, Az module or Graph PowerShell SDK on the cloud host. The file already selects `Prepare`, supplies the profile replacement tokens and clears directory credentials on exit. Do not replace it with a path to a file on the VM.

This single action adds and verifies direct group membership, then runs the configured Entra synchronization job. Rerunning it does not add duplicate membership. An HTTP 200 with failed or out-of-scope provisioning still throws; only `Success` or unchanged `RedundantExport` with a target identity passes.

**Expected:** the learner belongs to the configured entitlement group and Entra reports a provisioned GitHub identity. Actual GitHub sign-in and a usable Copilot response remain required handover checks; there is no fixed delay that proves a seat is ready.

## Prepare the VM image

Use a reviewed, pinned repository commit on the VM, for example at `C:\Users\LabUser\Desktop\LAB663`. Do not download a moving `main` branch when each learner starts. Record the commit, image version and package versions used in the rehearsal.

The image must already contain Azure CLI, Bicep, VS Code with Python/Jupyter and GitHub Copilot support, and a Python environment satisfying [`requirements.txt`](../requirements.txt). In particular, the lab requires `azure-ai-projects>=2.8.0`; an older SDK can create an agent but cannot run the newer rubric, insights and optimizer calls. Confirm preview feature access in the **Skillable subscription**, not just the development subscription.

Install the Skillable integration service in the image and configure Windows automatic sign-in for the intended lab VM account. Skillable's **Execute Script in Virtual Machine** action requires that service and a signed-in VM user. Do not bake a personal GitHub login, Azure login or access token into the image.

The scripts deliberately do not install packages or update tools during a timed lab. Repair the image when a prerequisite check fails. Run the actions as the learner's Windows VM user so the notebook kernel and `.env` are available to that user.

Prepare the root `.venv` from `requirements.txt` while building the image, before learners arrive. `setup.ps1` and `deployment.ps1` default to `.venv\Scripts\python.exe`; `-Python` still supports an explicitly prepared image interpreter. The shared check verifies all declared packages, the SDK operations used by the lab and heatmap rendering without contacting Azure.

| Action | When | Result |
|---|---|---|
| `setup.ps1` | First command inside action 2 | Checks the repository's package requirements and Bicep; registers `Python (LAB663)` |
| `deployment.ps1` | Second command inside action 2, only after setup succeeds | Checks catalog/quota, deploys Bicep, writes local settings, indexes ten manuals and creates/pins v0 |
| Notebook 01 | After signing in as the **learner** | Checks learner access, every model endpoint, the pinned agent, index, tracing connection and data |
| `teardown.ps1` | Action 3 on the same VM, before VM disposal | Deletes the instance's tagged resources; preserves the platform's resource group and VM |

**Expected:** no learner starts while setup, deployment or the learner identity check is pending or failing.

## Supply the cloud identity and scope

The Skillable lifecycle service principal needs resource deployment and role-assignment rights **on the allocated lab resource group**. The subscription administrator must register `Microsoft.CognitiveServices`, `Microsoft.Insights` and `Microsoft.OperationalInsights` beforehand. Normal Skillable deployment does not create a resource group or register providers.

Preflight also needs subscription-level read access to provider registration and regional model/quota metadata. Authorize the soft-deleted-account purge operation used by teardown separately; resource-group deployment rights alone must not be assumed to include purge. Verify both against the actual lifecycle principal without broadening the learner's permissions.

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

## Action 2: Prepare the VM and Foundry environment

Paste the complete [`02-prepare-lab663-environment.ps1`](02-prepare-lab663-environment.ps1) file into the **First Displayable** VM action. Change `$repoRoot` to the pinned checkout path in your image; the example is `C:\Users\LabUser\Desktop\LAB663`. The file injects the subscription credentials, runs setup followed by deployment and clears the credentials on exit.

Setup and deployment are deliberately in one blocking action: a failed prerequisite check stops deployment, and no ordering between separate script processes is assumed.

**Expected:** `Python (LAB663)` is registered; six model deployments, a project and monitoring resources exist; the VM has a local `.env`, ten indexed manuals and a pinned v0 in `.lab-state.json`. The scripts retain a manifest under the ignored `.lab-lifecycle` directory. A failed action throws rather than reporting success.

An existing VS Code interpreter selection can override a new workspace default. Select the prepared `.venv` and **Python (LAB663)** explicitly when updating an existing image; notebook 01 prints the interpreter it actually uses.

Capacity defaults to 250 units for **each** deployment. Four router editions therefore require 1,000 available router capacity units per concurrently provisioned lab instance. Quota is shared at subscription/region/model/SKU scope; include all concurrent learners and existing allocations in the capacity plan. Catalog and quota checks do not reserve capacity or guarantee preview feature access.

The preflight reads model names, versions, deployment names and SKU from the compiled `infra/main.bicep` defaults rather than a separate hard-coded list. It combines requirements sharing a quota bucket and credits only matching existing deployments, capped at the requested capacity for each.

Azure JSON arrays are explicitly enumerated so an empty resource group and multi-item catalog behave consistently in Windows PowerShell 5.1 and PowerShell 7.

Rerun a failed deployment with the **same instance ID and settings**. It reuses the resource group and deterministic Bicep names. It rejects unowned lab-named resources and settings that conflict with its manifest. Agent setup reuses the locally recorded index and matching v0; it refuses to adopt an unrecorded index or delete an incomplete one. Preserve `.lab-state.json` when recovering a failed setup.

`-InfrastructureOnly` is for an operator's deployment rehearsal. It explicitly skips package and agent checks and must **never** be treated as a learner-ready result.

## Hand over to the learner

After both startup actions succeed, the learner signs into GitHub/Copilot using the assigned enterprise identity and into Azure using the assigned Skillable account, following the [Skillable walkthrough](../instructions/skillable/README.md). GitHub group membership, a provisioning success response or an installed Copilot extension alone is not a handover pass: confirm enterprise access and an actual Copilot response. Notebook 01 must also pass under the learner's Azure identity, not merely under the more privileged deployment principal.

The `.env` file has the same settings as self-guided delivery, plus `LAB663_DELIVERY_MODE=skillable`. It has no client secret or model API key. Do not run `infra/deploy.sh` from a Skillable VM: that script creates another resource group and uses a different ownership model.

**Expected:** Copilot answers under the assigned GitHub account, notebook 01 passes under the learner's Azure account, and learners can start the shared core notebooks.

## Action 3: Remove the Azure resources

Paste the complete [`03-remove-lab663-azure-resources.ps1`](03-remove-lab663-azure-resources.ps1) file into the first **Tearing Down** action, targeting the **same VM** as action 2. Set `$repoRoot` to the same checkout path. The file supplies and clears the subscription credentials and invokes teardown with instance confirmation and account purge.

Keep the ignored lifecycle manifest until cleanup finishes, with the repository still present. A cloud-platform action cannot read VM-local files; do not paste file 03 there or register `common.ps1` as an independent action.

**Expected:** only this instance's tagged resources and the generated anomaly alert scoped to its Application Insights resource are removed. Teardown deletes the Foundry project and its agents/indexes before deleting the parent account and model deployments; Azure refuses account deletion while a nested project remains. The allocated Skillable resource group and VM are preserved. Local `.env`, state and evidence files remain for review; discard the VM through the normal Skillable lifecycle afterwards.

Use `-WhatIf` to inspect the deletion targets first. Teardown requires a matching manifest, instance confirmation and live ownership tags; it does not search other subscriptions or guess a group from a prefix. Purging the exact soft-deleted account releases retained quota. It is permanent, so use it only for disposable lab environments. If the deleted record does not appear or purge cannot be verified within the bounded wait, the action fails with `purge-pending` in the manifest. Recheck and rerun teardown; do not claim quota was released or reuse that instance ID.

Before the first confirmed deletion, teardown records `deleting` in the manifest. A deployment cannot resume an instance once cleanup has started. A declined deletion fails rather than reporting completed cleanup. Manifest writes use a temporary file before replacing the saved record.

For a separate operator rehearsal, `deployment.ps1 -UseCurrentAzureLogin -CreateResourceGroup` creates a tagged `rg-lab663-...` group. Only such a lifecycle-owned group is eligible for `teardown.ps1 -DeleteResourceGroup`; the script refuses that option for a platform-allocated group or a group containing unrelated resources.

## Action 4: Remove the GitHub Copilot entitlement

Add a **separate cloud-platform action** at **Tearing Down**, after the VM cleanup action. It must not depend on reading the VM or on successful Azure cleanup. Configure cleanup errors to notify and log, and rehearse that Skillable still attempts this cloud action when VM cleanup fails or the VM is unavailable.

Paste the complete [`04-remove-github-copilot-entitlement.ps1`](04-remove-github-copilot-entitlement.ps1) file into this cloud action. It embeds the implementation, selects `Cleanup`, confirms the same learner object ID and clears directory credentials on exit.

Inject the dedicated directory app credentials again; environment variables and PowerShell variables from startup do not carry over.

**Expected:** the learner's direct entitlement-group membership is absent. The script never deletes a directory user or group. Cleanup is idempotent and intentionally removes that dedicated lab account's membership even if it was already present before startup. Do not target personal or shared accounts.

Group-based license removal and GitHub deprovisioning follow the tenant's configured policies and schedules; membership removal is not proof that the enterprise seat has already been reclaimed. Confirm downstream removal before recycling the identity. Keep Azure and directory cleanup failures visible to the operator.

## Rehearse before opening the lab

Run the following checks on the actual Skillable image and subscription. A development-subscription pass is useful evidence, but it does not replace them.

- Confirm the pinned commit, package versions, macro substitution, directory application permissions and preview feature access.
- Exercise directory preparation and cleanup twice, a wrong learner confirmation, a synchronization failure and actual GitHub/Copilot access. Do not use a personal account.
- Verify both startup actions block handover and end the lab on failure. Verify cloud entitlement cleanup still runs after a failed VM cleanup.
- Start a fresh instance; run notebook 01 as the learner and verify actual trace ingestion with notebook 04.
- Complete one rubric, optimizer and router path. Record wall time, error counts, complete per-case coverage and the promotion decision.
- Interrupt a wait and resume the saved run ID. Rerun setup without creating duplicate infrastructure or replacing authored agents.
- Exercise an invalid instance ID and `-WhatIf`; neither may delete anything.
- Tear down the tagged resources, verify removal and quota release, and confirm the allocated VM/resource group remain.

Keep the 60-minute schedule as a rehearsal target until it has been timed with beginner learners. Extra router editions and model experiments belong outside the core budget; never reduce the question set to make a run look faster.

### What has been rehearsed

On 13 October 2026, an isolated Azure deployment passed infrastructure provisioning and rerun, six model endpoint checks, ten-manual indexing and baseline reuse. Invalid confirmation and both teardown dry runs preserved resources. Resource-only teardown removed the generated alert, project, account and monitoring while retaining the group; a subsequent action removed the owned disposable group. Account purge was verified. The existing development group was not changed.

That rehearsal used the signed-in review account, not Skillable's service principal and learner identities. The local prerequisite check correctly rejected `azure-ai-projects` 2.1.0 and missing `matplotlib`; no packages were installed. Full notebook execution, the actual Skillable image/macros and learner timing still need a prepared-environment rehearsal. The [router/file-search service failure](../docs/narrative.md#what-the-isolated-rehearsal-tells-us) also remains unresolved.

For the four-action configuration on 19 October 2026, 51 isolated checks passed in each of Windows PowerShell 5.1 and PowerShell 7. They exercised all four documented action bodies, including the pasted self-contained cloud script, group assignment before synchronization, reruns, failed provisioning, cleanup confirmation, dry runs, VM command ordering and credential cleanup. Azure and Graph responses were simulated; these checks did not contact the cloud or prove live Copilot entitlement. Bicep CLI was absent locally, so compilation of the actual template and live Skillable identity, entitlement and deployment behavior still need the prepared-image rehearsal.
