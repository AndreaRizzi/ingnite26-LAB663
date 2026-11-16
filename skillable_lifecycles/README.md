# Skillable lifecycles

LAB663 requires both **GitHub Copilot access** and the **Azure Foundry environment**. These Skillable lifecycle actions assign the learner's GitHub/Copilot entitlement group, provision their enterprise identity, grant the learner's Azure roles, prepare the Windows VM and starting TrailMate agent, and clean up at lab end.

Deployment uses LAB663's [`infra/main.bicep`](../infra/main.bicep) to create the Foundry project, model deployments and monitoring, then runs [`src/agent/01_build_agent.py`](../src/agent/01_build_agent.py) to index the TrailMate manuals and create or reuse the starting agent.

## Deploy and fill the learner's environment

**Using the validated `infra\pwsh\deploy.ps1`:** paste [`deploy-pwsh.ps1`](deploy-pwsh.ps1) into the VM lifecycle **instead of action 03**. It authenticates using the Skillable subscription application, calls that PowerShell deployment without prompts, populates the existing `.env`, and writes `LAB663-deployment-output.txt` plus a timestamped run log to the learner's desktop. Set its checkout and desktop paths before pasting. Keep the other lifecycle actions, including teardown, unchanged. See the [PowerShell lifecycle configuration](../infra/README.md#run-the-powershell-deployment-as-a-skillable-lifecycle). This wrapper does not use the resource-template split.

**For a profile that already grants learner access:** `deploy-pwsh.ps1` now relies on your existing learner-role action and requires neither `Lab663LearnerObjectId` nor `Lab663BootstrapObjectId`. It gets only the deployment application's own object ID from its ARM token, without a directory lookup. It skips learner role assignments but keeps bootstrap and project-identity roles. Ensure your existing action covers Foundry User and the learner's monitoring/query access; verify access as the learner before handover. The variable requirements below still apply to the original action 03, resource-template split, and repository-supplied actions 02/04. Do not replace your working role actions with those scripts just to use this wrapper.

The `deploy-pwsh.ps1` wrapper deploys the lab resources to **`eastus`**, independently of `ResourceGroup1.Location`. The existing group may have its metadata in France; resource location is passed explicitly to Bicep. Allow East US 2 in subscription policy and quota. To allocate the group itself there, change the Skillable profile's resource-group region for new instances. Existing deployments are not moved; use normal teardown and a fresh instance if a previous run recorded another region.

Use [`03-prepare-lab663-environment.ps1`](03-prepare-lab663-environment.ps1) as the deployment lifecycle action. Paste the complete file into **First Displayable > Execute Script in Virtual Machine > PowerShell** and set `$repoRoot` to the pinned checkout on the learner's Windows VM, for example `C:\Users\LabUser\Desktop\LAB663`. Keep startup blocking and end the lab on failure.

This action uses the subscription credentials and allocated resource group supplied by Skillable. It calls the existing setup and deployment helpers, not `azd`, and does not create a second resource group. Supply the custom learner/bootstrap object IDs and earlier-action status variables described below before running it.

After deployment, the helper automatically populates the **existing `.env`** in that checkout. It preserves comments and unrelated settings, replaces all 12 deployment settings, and appends any missing ones. If `.env` does not exist, it starts from [`.env.sample`](../.env.sample). No manual copying or editing is needed. It fails rather than writing missing values, duplicate settings or unresolved Skillable tokens. Project endpoint, account and project names, tracing connection, tenant, subscription, resource group and region come from this deployment. The two model deployment names come from the Bicep defaults, not a separate hard-coded list. `LAB663_DELIVERY_MODE` is `skillable`.

The agent bootstrap receives those same settings in its process environment, so an older inherited endpoint cannot override the new `.env`. The helper restores process settings and removes the isolated bootstrap sign-in afterwards. Client secrets and access tokens are never written to `.env`; learners sign in with their assigned Azure identity.

Run this on the VM, not in a cloud-platform action: a remote cloud script cannot write the learner's local `.env` or register their notebook kernel. The VM image must already contain the CLI, Bicep and required Python packages. Keep the separate GitHub/Copilot and learner-role actions below.

**Expected:** the desktop status file says `SUCCEEDED`, `.env` contains this instance's settings, and TrailMate v0 and its indexed manuals are ready. If preparation fails, the status file names the stage and error; repair the cause and rerun with the same instance ID. Do not rerun the self-guided deployment.

## Use a resource template for Azure provisioning

This is an alternative to deploying Azure resources from action 3. Keep the six lifecycle actions below, but let the resource template provision the Azure environment before VM preparation.

1. Use [`infra/skillable.bicep`](../infra/skillable.bicep) as the Bicep entry point. For an ARM-only resource-template editor, export it with `az bicep build --file infra\skillable.bicep --outfile infra\skillable.json` on the prepared authoring machine and upload that JSON. All modules are embedded in the export.
2. Map the parameters using [`skillable.parameters.json`](../infra/skillable.parameters.json). The allocated group is `ResourceGroup1`, and the region, instance ID, learner **object ID** and bootstrap **object ID** must belong to this instance. The platform must resolve the tokens before sending parameters to ARM. The identity provisioning integration must supply the object IDs before this template runs, not in a later Post-Build action.
3. Configure the resource deployment to finish successfully before First Displayable. Record its exact ARM deployment name. For example, if the profile lets us choose `lab663-<instance ID>` as the name, use that same name in the VM action. Do not assume Skillable's generated name or invent a replacement token for it.
4. In [`03-prepare-lab663-environment.ps1`](03-prepare-lab663-environment.ps1), set `$resourceDeploymentName` to that exact name. The rest of its credential, identity and checkout settings stay the same. Action 3 then calls [`post-deployment.ps1`](post-deployment.ps1), which reads the deployment and does not create or update Azure resources.

The template creates Foundry, the two chat deployments, four router editions, the extra models in [`infra/extra-models.json`](../infra/extra-models.json), Log Analytics, Application Insights, the tracing connection and the resource-scoped roles. It tags the account, project and monitoring resources for this instance. It does not create a resource group, grant subscription-wide roles, configure GitHub/Copilot, install packages, upload manuals or create the agent.

The VM action checks the deployment's `Succeeded` state, instance ID, both identities, resource IDs, region and ownership tags. It uses the **deployed** model-name outputs when filling `.env`, not the current checkout's defaults. It fetches the Application Insights connection string directly from the deployed resource rather than exposing it in deployment outputs. It then indexes the manuals and prepares TrailMate using the shared completion code used by the all-in-one lifecycle.

The VM still needs Azure CLI and the prepared Python environment, but this path does not compile Bicep on the VM. Bicep is needed on the authoring machine when exporting the resource template, or on the VM when using the original all-in-one deployment path.

The action records the same `.lab-lifecycle` ownership manifest as the original deployment path, with `ownsResourceGroup=false`. Existing teardown can remove the recorded, tagged resources without deleting Skillable's group or VM. If the resource template fails, or the VM action never reaches the manifest-writing step, automated VM teardown deliberately refuses to guess. The operator must inspect the template failure and clean up that instance through the platform's allocated-resource cleanup or a reviewed manual operation. Configure and rehearse that failure path before publishing the profile.

Resource provisioning now happens before the VM's model-catalog and quota preflight from the all-in-one path. Check provider registration, all six model deployments' regional availability, combined quota and Azure Policy with the actual resource-template deployment identity before enabling the profile. The template identity needs deployment and role-assignment rights; the VM bootstrap identity needs ARM read access plus the Foundry role assigned by the template.

Leave `$resourceDeploymentName` empty to retain the original action-3 infrastructure deployment. Do not switch provisioning modes for an instance that already has a manifest.

**Expected:** one Azure provisioner runs, the VM action only completes local and agent setup, and the existing `.env` contains the allocated environment's settings. A mismatched deployment or ownership tag stops preparation before `.env` is changed.

## Configure six actions in Skillable

### Register providers when the subscription pool is not prepared

If the VM deployment reports that `Microsoft.CognitiveServices` must be registered, add [`00-register-azure-providers.ps1`](00-register-azure-providers.ps1) as an **additional** lifecycle action before the existing startup actions:

| Setting | Value |
|---------|-------|
| Name | Register LAB663 Azure providers |
| Event | Post-Build, before the other Post-Build actions |
| Action type | Execute Script in Cloud Platform |
| Cloud platform / language | Azure / PowerShell |
| Script | Paste the complete `00-register-azure-providers.ps1` file |
| Enabled / blocking | Yes / Yes |
| Timeout | 15 minutes; the script permits up to eight minutes for provider registration after authentication |
| Error action | End the lab on failure |
| Delay / retries / repeat | 0 / 0 / disabled |

This cloud action uses only the built-in `CloudSubscription` tenant, subscription ID, AppId and AppSecret tokens. It needs no VM files, Azure CLI, Az modules, directory lookup or custom variables. The subscription must already be allocated when the action runs. Make sure it completes before the First Displayable VM deployment.

It registers `Microsoft.CognitiveServices`, `Microsoft.Insights`, `Microsoft.OperationalInsights` and `Microsoft.AlertsManagement` through Azure Resource Manager, then checks all four reach `Registered`. Alerts Management supports Application Insights smart-detection alert rules, including the separate Failure Anomalies alert-rule deployment. Already registered providers are left alone; an in-progress registration is waited on. No resource group, model or role assignment is created. Provider registration is subscription-wide and does not change the East US 2 resource location. Do not unregister the providers during teardown.

The application identified by `@lab.CloudSubscription.AppId` needs **subscription-level provider read/register permission**. Resource-group permissions and Entra directory permissions do not provide it. If this action reports HTTP 403, the subscription administrator must pre-register the providers for the subscription pool or authorize this cloud action. The script does not grant itself permissions or fall back to learner credentials.

**Expected:** the cloud action logs `SUCCEEDED: all four LAB663 Azure resource providers are registered`, then the existing VM deployment passes its provider check. When providers are already registered throughout the subscription pool, this extra action is unnecessary.

For an existing instance that reports `MissingSubscriptionRegistration` for `Microsoft.AlertsManagement`, repaste the updated cloud script and explicitly run that registration action against the same allocated subscription, or ask the subscription administrator to register the provider. Updating the action does not rerun it on an already-started instance. Registration does not automatically repair a previously failed alert-rule deployment; after registration, an authorized operator can redeploy that specific alert rule. Do not recreate successful Foundry resources to repair this separate alert.

In **Edit Profile**, open **Advanced > Life Cycle Actions** and select **Add Life Cycle Action**. Existing actions can also be managed on the **Life Cycle** tab. Add the six actions below, keeping the listed order within each event. The [Skillable lifecycle reference](https://docs.skillable.com/docs/life-cycle-actions-5) explains these controls.

| Order and name | Event | Action type and target | File to copy into the action editor | Blocking | Timeout budget | Error action |
|---|---|---|---|---|---|---|
| 1. Prepare GitHub Copilot access | Post-Build | Execute Script in Cloud Platform; Azure; PowerShell | [`01-prepare-github-copilot-access.ps1`](01-prepare-github-copilot-access.ps1) | Yes | 10 minutes | End the lab on failure |
| 2. Assign the learner's Azure roles | Post-Build, after action 1 | Execute Script in Cloud Platform; Azure; PowerShell | [`02-assign-learner-azure-roles.ps1`](02-assign-learner-azure-roles.ps1) | Yes | 10 minutes | End the lab on failure |
| 3. Prepare LAB663 environment | First Displayable | Execute Script in Virtual Machine; `Win11-Pro-Base`; PowerShell | [`03-prepare-lab663-environment.ps1`](03-prepare-lab663-environment.ps1) | Yes | 60 minutes | End the lab on failure |
| 4. Remove the learner's Azure roles | Tearing Down, first | Execute Script in Cloud Platform; Azure; PowerShell | [`04-remove-learner-azure-roles.ps1`](04-remove-learner-azure-roles.ps1) | Yes | 10 minutes | Notify User; retain the error for the operator |
| 5. Remove LAB663 Azure resources | Tearing Down, after action 4 | Execute Script in Virtual Machine; same VM as action 3; PowerShell | [`05-remove-lab663-azure-resources.ps1`](05-remove-lab663-azure-resources.ps1) | Yes | 30 minutes | Notify User; retain the error for the operator |
| 6. Remove GitHub Copilot entitlement | Tearing Down, after action 5 | Execute Script in Cloud Platform; Azure; PowerShell | [`06-remove-github-copilot-entitlement.ps1`](06-remove-github-copilot-entitlement.ps1) | Yes | 10 minutes | Notify User; retain the error for the operator |

Copy the **complete contents** of each numbered file into its matching Skillable action editor. The filenames are the action order. Files 01, 02, 04 and 06 are self-contained cloud actions; no manual insertion of another script is needed. In files 03 and 05, change `$repoRoot` to the same pinned checkout path on the VM.

The unnumbered `setup.ps1`, `deployment.ps1`, `post-deployment.ps1`, `teardown.ps1` and `common.ps1` are VM implementation files, not additional Skillable actions. Keep them in the VM checkout: file 03 calls setup and either deployment or post-deployment, file 05 calls teardown, and the implementations load `common.ps1`. The cloud files need no separate cloud source or export utility. Files 01 and 06 embed the same directory implementation, and files 02 and 04 embed the same role implementation. When you change one file of a pair, make the same change in the other.

For every action, set **Enabled = Yes**, **Delay = 0**, **Retries = 0**, and leave **Repeat disabled**. These scripts throw on failure; they do not implement a true/false polling contract. Do not use **Log** alone for startup failures. For cleanup notifications, say that cleanup failed and the facilitator must review the lab instance error before reusing the account or subscription.

Timeouts are operator budgets, not measured service guarantees. Verify the effective VM/integration-service execution timeout in your Skillable host; Skillable's general documentation describes the Timeout control specifically for cloud/custom scripts. Project access can wait ten minutes and indexing another five, before counting infrastructure deployment. Do not retain the supplied ten-minute VM deployment limit without a rehearsal proving it sufficient.

**Post-Build** can occur while VMs are still starting, so only the two cloud actions run there. **First Displayable** targets the running VM; blocking setup and deployment must finish before learner handover. The cloud fabric must finish allocating the learner and resource group first; configure **Fabric Build Sequence** accordingly instead of relying on a fixed sleep.

These six actions cover every required step: entitlement assignment, enterprise synchronization, learner Azure roles, VM setup, Foundry deployment, role removal, Azure cleanup and entitlement removal. `common.ps1` is a VM helper, not an action. [`roles.bicep`](../infra/modules/roles.bicep) grants the learner the resource-scoped roles the notebooks use. Action 2 adds Foundry User and Cognitive Services Contributor at subscription scope, as the original profile intended, so the Foundry portal works for the learner across their subscription. Action 4 removes both sets explicitly before action 5 deletes the resources.

**Expected:** both GitHub/Copilot and Foundry are prepared, and a failure cannot silently hand over an incomplete lab.

### Replace the profile's original actions

The supplied profile export has nine actions. Remove or disable them once the six actions above are in place. Running both sets assigns and removes the same access twice, and hides which action failed.

| Original action | Event | Replaced by |
|---|---|---|
| M365 License Assignment and Force Entra GH-Sync | Post-Build | Action 1 |
| Role Assignment | Post-Build | Action 2 |
| setup, common and deployment | First Displayable | Action 3 |
| Tear Down Roles | Tearing Down | Action 4 |
| Tear Down | Tearing Down | Action 5 |
| Tear Down License | Tearing Down | Action 6 |

The original actions ran with **Blocking = No** and **Error Action = Log**, so a failed deployment still handed the lab over. The learner then reached the Foundry portal with no LAB663 project to open. The original role actions also looked roles up by display name, which breaks when Azure renames a role; Azure AI User is now Foundry User. The original Tear Down Roles action removed both roles from every user in the subscription, while action 4 removes only this learner's LAB663 roles.

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

Actions 1 and 2 also set `Lab663CopilotAccessStatus` and `Lab663AzureRolesStatus` with `Set-LabVariable`, so action 3 can show their results on the VM. Don't supply values for these two; the actions set them.

Supply `LAB663_DIRECTORY_CLIENT_ID` and `LAB663_DIRECTORY_CLIENT_SECRET` as process environment variables in **actions 1 and 6**, using the operator's approved protected secret-injection mechanism. Skillable does not create these variables automatically. Actions 2 and 4 use the subscription credentials instead. Keep the dedicated Entra provisioning application from the supplied lifecycle separate from the subscription deployment application. Do not put its secret in Git, `.env`, ordinary lab variables or learner credential pools. Confirm this secret binding with the Skillable administrator before testing; actions 1 and 6 fail if it is missing.

The directory app needs admin-consented `GroupMember.ReadWrite.All`. For on-demand synchronization, the [Graph API reference](https://learn.microsoft.com/en-us/graph/api/synchronization-synchronizationjob-provisionondemand?view=graph-rest-1.0) lists `Application.ReadWrite.OwnedBy` for an application it owns, or `Synchronization.ReadWrite.All`. Configure the intended enterprise application's group assignment, provisioning scope and Copilot seat policy beforehand. A group name alone does not configure those services.

**Expected:** every custom variable resolves to the correct instance or tenant setting, and privileged directory credentials are available only to actions 1 and 6.

## Action 1: Prepare GitHub Copilot access

Paste the complete [`01-prepare-github-copilot-access.ps1`](01-prepare-github-copilot-access.ps1) file into the **Post-Build** cloud action. It is self-contained: it needs no repository checkout, helper file, Az module or Graph PowerShell SDK on the cloud host. The file already selects `Prepare`, supplies the profile replacement tokens and clears directory credentials on exit. Do not replace it with a path to a file on the VM.

This single action adds and verifies direct group membership, then runs the configured Entra synchronization job. Rerunning it does not add duplicate membership. An HTTP 200 with failed or out-of-scope provisioning still throws; only `Success` or unchanged `RedundantExport` with a target identity passes. It then records `SUCCEEDED` or `FAILED` in `Lab663CopilotAccessStatus` for action 3's status file. If that can't be recorded, the action logs a warning; its own result doesn't change.

**Expected:** the learner belongs to the configured entitlement group and Entra reports a provisioned GitHub identity. Actual GitHub sign-in and a usable Copilot response remain required handover checks; there is no fixed delay that proves a seat is ready.

## Action 2: Assign the learner's Azure roles

Paste the complete [`02-assign-learner-azure-roles.ps1`](02-assign-learner-azure-roles.ps1) file into a second **Post-Build** cloud action, after action 1. It replaces the profile's original Role Assignment action and uses the subscription credentials Skillable already supplies, `@lab.CloudSubscription.AppId` and `.AppSecret`. It needs no directory app, Az module or VM checkout.

It assigns two built-in roles to the learner at subscription scope:

| Role | Role ID | Why the learner needs it |
|---|---|---|
| Foundry User | `53ca6127-db72-4b80-b1b0-d745d6d5456d` | Build and run agents in the Foundry portal. Without it, the portal says "You don't have permission to build agents in this project". |
| Cognitive Services Contributor | `25fbc0a9-bd7c-42a3-aa1a-3b75d497ee68` | See and manage the Foundry account and its model deployments, as the original profile allowed |

The action finds roles by ID, never by display name, because names can change and IDs don't. Each assignment gets a fixed name made from the learner, subscription and role, so a rerun never adds a duplicate. If Azure can't see a newly created learner account yet, the action retries for about two minutes. It then checks that Azure lists both roles, and fails if it doesn't. Finally, it records `SUCCEEDED` or `FAILED` in `Lab663AzureRolesStatus` for action 3's status file.

Cognitive Services Contributor is broad: it can manage any Cognitive Services account in the subscription, including its keys. Grant it only in a disposable per-learner subscription, which is how this lab is delivered.

The subscription application needs to read, create and delete role assignments at subscription scope; see [Supply the cloud identity and scope](#supply-the-cloud-identity-and-scope). New role assignments can take up to 10 minutes to apply.

**Expected:** Azure lists Foundry User and Cognitive Services Contributor for the learner at subscription scope, and the lab instance details show action 2 succeeded.

## Prepare the VM image

Use a reviewed, pinned repository commit on the VM, for example at `C:\Users\LabUser\Desktop\LAB663`. Do not download a moving `main` branch when each learner starts. Record the commit, image version and package versions used in the rehearsal.

For the `deploy-pwsh.ps1` route, include **PowerShell 7** at `C:\Program Files\PowerShell\7\pwsh.exe` (or set `$powerShell7` in the pasted action to its installed path). Skillable can still start the action with `powershell.exe`; the wrapper verifies and invokes `pwsh.exe` for deployment. Missing PowerShell 7 ends the action before Azure sign-in, with a desktop failure summary. Keep Windows PowerShell 5.1 installed. Update the VM's `infra\pwsh\deploy.ps1` and repaste the launcher together. **Expected:** the deployment summary reports PowerShell version 7 or later.

Keep `$resumeDeployment = $false` for new instances. If Azure succeeded but the same instance stopped before local setup, use the [recovery instructions](../infra/README.md#run-the-powershell-deployment-as-a-skillable-lifecycle) to resume without resubmitting resources. Resume requires the existing ownership manifest and matching deployment parameters; it is not a substitute for normal startup.

The image must already contain Azure CLI, Bicep, VS Code with Python/Jupyter and GitHub Copilot support, and a Python environment satisfying [`requirements.txt`](../requirements.txt). In particular, the lab requires `azure-ai-projects>=2.8.0,<2.11.0`; an older SDK can create an agent but cannot run the newer rubric, insights and optimizer calls, and 2.11.0 removed the insight monitor API that notebook 04 uses. Confirm preview feature access in the **Skillable subscription**, not just the development subscription.

For the `deploy-pwsh.ps1` route, verify the Bicep executable under the **lab VM user**, not only an administrator account. Deployment finds it on `PATH` or in that user's `.azure\bin` directory and compiles the template directly before submitting ARM JSON. The fresh lifecycle sign-in cache must not trigger a compiler download. For a CLI-managed image installation, check `& "$HOME\.azure\bin\bicep.exe" --version`; for a standalone installation, check `bicep --version`. **Expected:** the prepared compiler prints its version, and the deployment log separates compilation from Azure submission.

Install the Skillable integration service in the image and configure Windows automatic sign-in for the intended lab VM account. Skillable's **Execute Script in Virtual Machine** action requires that service and a signed-in VM user. Do not bake a personal GitHub login, Azure login or access token into the image.

The scripts deliberately do not install packages or update tools during a timed lab. Repair the image when a prerequisite check fails. Run the actions as the learner's Windows VM user so the notebook kernel and `.env` are available to that user.

Prepare the root `.venv` from `requirements.txt` while building the image, before learners arrive. `setup.ps1` and `deployment.ps1` default to `.venv\Scripts\python.exe`; `-Python` still supports an explicitly prepared image interpreter. The shared check verifies all declared packages, the SDK operations used by the lab and heatmap rendering without contacting Azure.

| Action | When | Result |
|---|---|---|
| `setup.ps1` | First command inside action 3 | Checks the repository's package requirements and Bicep; registers `Python (LAB663)` |
| `deployment.ps1` | Second command inside action 3, only after setup succeeds | Checks catalog/quota, deploys Bicep, writes local settings, indexes ten manuals and creates/pins v0 |
| Notebook 01 | After signing in as the **learner** | Checks learner access, every model endpoint, the pinned agent, index, tracing connection and data |
| `teardown.ps1` | Action 5 on the same VM, before VM disposal | Deletes the instance's tagged resources; preserves the platform's resource group and VM |

**Expected:** no learner starts while setup, deployment or the learner identity check is pending or failing.

## Supply the cloud identity and scope

The Skillable lifecycle service principal needs resource deployment and role-assignment rights **on the allocated lab resource group**. Actions 2 and 4 also read, create and delete the learner's role assignments at **subscription scope**, so the principal needs those rights there too: for example Owner, or Role Based Access Control Administrator with a condition that allows the role IDs in [action 2](#action-2-assign-the-learners-azure-roles) and Log Analytics Reader. The subscription administrator must register `Microsoft.CognitiveServices`, `Microsoft.Insights`, `Microsoft.OperationalInsights` and `Microsoft.AlertsManagement` beforehand. The VM deployment does not create a resource group or register providers; use the separate cloud registration action when authorized.

Preflight also needs subscription-level read access to provider registration and regional model/quota metadata. Authorize the soft-deleted-account purge operation used by teardown separately; resource-group deployment rights alone must not be assumed to include purge. Verify both against the actual lifecycle principal without broadening the learner's permissions.

Supply the learner's Entra **object ID** and the lifecycle service principal's **object ID** from the lab's identity provisioning step. An application/client ID is not a service principal object ID. The scripts accept these explicitly and do not require broad directory permissions just to look them up.

| Input | Source |
|---|---|
| Tenant and subscription | `@lab.CloudSubscription.TenantId`, `@lab.CloudSubscription.Id` |
| Resource group | `@lab.CloudResourceGroup(ResourceGroup1).Name` |
| Lab resource region | `eastus`, independent of the group's metadata location; enforced by Bicep and deployment scripts |
| Lab instance ID | `@lab.LabInstance.Id` |
| Client ID and secret | `@lab.CloudSubscription.AppId`, `.AppSecret`, injected into **process-only** variables |
| Learner object ID | Identity provisioning for `@lab.CloudPortalCredential(User1).Username` |
| Bootstrap object ID | Identity provisioning for the lifecycle service principal |

The macro names must match the resource group and credential aliases configured in the Skillable lab profile. Validate substitution in a real Skillable rehearsal; a successful local PowerShell run does not prove that mapping.

Bicep gives the learner and bootstrap principal Foundry access separately. The bootstrap identity authenticates using an isolated Azure CLI cache, which is removed afterwards. It is never left signed in for the learner, and its secret is never written to `.env`, a transcript or a committed file.

## Check Azure Policy in each learner subscription

Each learner gets their own subscription, and the platform applies Azure Policy to that subscription and the allocated resource group. A policy can deny a deployment, change a resource as it's created, or block cleanup. Compare the assigned policies with what LAB663 creates before opening the lab.

| LAB663 creates | What a policy must allow |
|---|---|
| Foundry account `aif-lab663-<token>` | Kind `AIServices`, SKU `S0`, a system-assigned identity, project management, a custom subdomain and public network access. LAB663 doesn't set `disableLocalAuth`, so a policy that denies accounts without it blocks the deployment. |
| Foundry project `trailmate` | A system-assigned identity |
| Six model deployments | `GlobalStandard` SKU at 250 capacity units each |
| Extra model deployments | From [`infra/extra-models.json`](../infra/extra-models.json), each with its own SKU and capacity. Today: `MAI-Image-2.6` and `MAI-Image-2.6-Flash`, `GlobalStandard` at 10 each |
| Project connection to Application Insights | A connection that stores the Application Insights connection string (`ApiKey` auth type) |
| Log Analytics workspace `log-lab663-<token>` | SKU `PerGB2018` with 30-day retention |
| Application Insights `appi-lab663-<token>` | Kind `web`, workspace-based. Tracing sends data with the connection string, so local authentication must stay enabled. |
| Role assignments | Foundry User and Cognitive Services Contributor for the learner at subscription scope (action 2), plus the resource-scoped roles in `roles.bicep` for the learner, lifecycle principal and project identity |
| Tags | `lab663Instance` and `lab663ManagedBy` on the account, project, workspace and Application Insights. A policy can add tags, but must not change or remove these two: teardown deletes only resources that carry them. |

Azure also creates a Failure Anomalies alert rule for Application Insights, which teardown removes.

The allocated resource group's region must be allowed. Policies must also allow cleanup: a `denyAction` effect can block deleting resources, and teardown also needs to purge the soft-deleted Foundry account. Rehearse a full lab, including teardown, with the policies applied.

**Expected:** a fresh instance deploys and tears down with the subscription's policies in place, and no policy changes the LAB663 tags.

## Action 3: Prepare the VM and Foundry environment

Paste the complete [`03-prepare-lab663-environment.ps1`](03-prepare-lab663-environment.ps1) file into the **First Displayable** VM action. Change `$repoRoot` to the pinned checkout path in your image; the example is `C:\Users\LabUser\Desktop\LAB663`. The file injects the subscription credentials, runs setup followed by deployment and clears the credentials on exit.

Before it starts, the action checks that Skillable replaced every value it needs and that the checkout exists. If anything is missing, it fails straight away and names the missing values. It writes `LAB663-03-environment-status.txt` to the desktop as it goes; see [Check each action's result](#check-each-actions-result).

Setup and deployment are deliberately in one blocking action: a failed prerequisite check stops deployment, and no ordering between separate script processes is assumed.

**Expected:** `Python (LAB663)` is registered; six chat and router deployments, the extra MAI model deployments, a project and monitoring resources exist; the VM has a local `.env` (including `MAI_IMAGE_DEPLOYMENT` and `MAI_IMAGE_FLASH_DEPLOYMENT`), ten indexed manuals and a pinned v0 in `.lab-state.json`. The scripts retain a manifest under the ignored `.lab-lifecycle` directory. A failed action throws rather than reporting success.

An existing VS Code interpreter selection can override a new workspace default. Select the prepared `.venv` and **Python (LAB663)** explicitly when updating an existing image; notebook 01 prints the interpreter it actually uses.

Capacity defaults to 250 units for **each** deployment. Quota is shared at subscription, region, model and SKU scope, and each learner has their own subscription. So **every learner subscription** needs this `GlobalStandard` quota in the lab region: 250 for `gpt-5.4`, 250 for `gpt-5.4-mini` and 1,000 for `model-router`, which serves four router editions. Existing deployments and soft-deleted accounts that haven't been purged also count against it. Catalog and quota checks do not reserve capacity or guarantee preview feature access.

Each learner subscription also needs `GlobalStandard` quota for the extra models: 10 for `MAI-Image-2.6` and 10 for `MAI-Image-2.6-Flash`. The preflight below does not check extra models; confirm their quota when you rehearse.

The preflight reads model names, versions, deployment names and SKU from the compiled `infra/main.bicep` defaults rather than a separate hard-coded list. It combines requirements sharing a quota bucket and credits only matching existing deployments, capped at the requested capacity for each.

Azure JSON arrays are explicitly enumerated so an empty resource group and multi-item catalog behave consistently in Windows PowerShell 5.1 and PowerShell 7.

Rerun a failed deployment with the **same instance ID and settings**. It reuses the resource group and deterministic Bicep names. It rejects unowned lab-named resources and settings that conflict with its manifest. Agent setup reuses the locally recorded index and matching v0; it refuses to adopt an unrecorded index or delete an incomplete one. Preserve `.lab-state.json` when recovering a failed setup.

`-InfrastructureOnly` is for an operator's deployment rehearsal. It explicitly skips package and agent checks and must **never** be treated as a learner-ready result.

## Hand over to the learner

After all three startup actions succeed, the learner signs into GitHub/Copilot using the assigned enterprise identity and into Azure using the assigned Skillable account, following the [Skillable walkthrough](../instructions/skillable/README.md). GitHub group membership, a provisioning success response or an installed Copilot extension alone is not a handover pass: confirm enterprise access and an actual Copilot response. Notebook 01 must also pass under the learner's Azure identity, not merely under the more privileged deployment principal.

The `.env` file has the same settings as self-guided delivery, plus `LAB663_DELIVERY_MODE=skillable`. It has no client secret or model API key. Do not run `infra/deploy.sh` from a Skillable VM: that script creates another resource group and uses a different ownership model.

In the Foundry portal, the learner opens the `trailmate` project in the `aif-lab663-<token>` account; action 3's status file shows both names. A project the learner creates in the portal has none of the lab's models, router editions or agent. Teardown doesn't remove it either, because it carries no LAB663 tags, so remove it yourself if the platform doesn't reset the subscription.

If the portal says **You don't have permission to build agents in this project**, check the project name first:

- A name made from the user name and numbers, such as `user1-12345678-1234`, belongs to a project someone created in the portal, not the lab's. Open `trailmate` instead.
- If the message appears in `trailmate`, check action 2 on the lab instance details page. New role assignments can take up to 10 minutes to apply.

**Expected:** Copilot answers under the assigned GitHub account, notebook 01 passes under the learner's Azure account, and learners can start the shared core notebooks.

## Action 4: Remove the learner's Azure roles

Paste the complete [`04-remove-learner-azure-roles.ps1`](04-remove-learner-azure-roles.ps1) file into the first **Tearing Down** action, a cloud-platform action that runs before action 5. It replaces the profile's original Tear Down Roles action and embeds the same role implementation as action 2.

It removes this learner's Foundry User, Cognitive Services Contributor and Log Analytics Reader assignments anywhere in their subscription. That covers the subscription-scope roles from action 2 and the resource-scoped roles from `roles.bicep`. It only touches the learner whose ID it confirms, and never deletes a user, group or role definition.

An assignment that's already gone counts as removed, and with nothing to remove the action succeeds without changes. It then checks that Azure no longer lists any of the three roles for the learner. It needs no VM, so it still runs if the VM is unavailable. Use it only with dedicated lab accounts, as with action 6.

**Expected:** Azure lists none of the three roles for the learner anywhere in the subscription.

## Action 5: Remove the Azure resources

Paste the complete [`05-remove-lab663-azure-resources.ps1`](05-remove-lab663-azure-resources.ps1) file into the second **Tearing Down** action, after action 4, targeting the **same VM** as action 3. Set `$repoRoot` to the same checkout path. The file supplies and clears the subscription credentials, checks its inputs and invokes teardown with instance confirmation and account purge. It writes `LAB663-05-azure-cleanup-status.txt` to the desktop as it goes.

Keep the ignored lifecycle manifest until cleanup finishes, with the repository still present. A cloud-platform action cannot read VM-local files; do not paste file 05 there or register `common.ps1` as an independent action.

**Expected:** only this instance's tagged resources and the generated anomaly alert scoped to its Application Insights resource are removed. Teardown deletes the Foundry project and its agents/indexes before deleting the parent account and model deployments; Azure refuses account deletion while a nested project remains. The allocated Skillable resource group and VM are preserved. Local `.env`, state and evidence files remain for review; discard the VM through the normal Skillable lifecycle afterwards.

Use `-WhatIf` to inspect the deletion targets first. Teardown requires a matching manifest, instance confirmation and live ownership tags; it does not search other subscriptions or guess a group from a prefix. Purging the exact soft-deleted account releases retained quota. It is permanent, so use it only for disposable lab environments. If the deleted record does not appear or purge cannot be verified within the bounded wait, the action fails with `purge-pending` in the manifest. Recheck and rerun teardown; do not claim quota was released or reuse that instance ID.

Before the first confirmed deletion, teardown records `deleting` in the manifest. A deployment cannot resume an instance once cleanup has started. A declined deletion fails rather than reporting completed cleanup. Manifest writes use a temporary file before replacing the saved record.

If action 3 stopped before it planned a deployment, there's no manifest, and this action fails with "No lifecycle manifest exists". LAB663 created nothing from that checkout in that case. Confirm the resource group has no resources tagged `lab663Instance` before reusing the subscription.

For a separate operator rehearsal, `deployment.ps1 -UseCurrentAzureLogin -CreateResourceGroup` creates a tagged `rg-lab663-...` group. Only such a lifecycle-owned group is eligible for `teardown.ps1 -DeleteResourceGroup`; the script refuses that option for a platform-allocated group or a group containing unrelated resources.

## Action 6: Remove the GitHub Copilot entitlement

Add a **separate cloud-platform action** at **Tearing Down**, after action 5. It must not depend on reading the VM or on successful Azure cleanup. Configure cleanup errors to notify and log, and rehearse that Skillable still attempts this cloud action when action 4 or 5 fails or the VM is unavailable.

Paste the complete [`06-remove-github-copilot-entitlement.ps1`](06-remove-github-copilot-entitlement.ps1) file into this cloud action. It embeds the implementation, selects `Cleanup`, confirms the same learner object ID and clears directory credentials on exit.

Inject the dedicated directory app credentials again; environment variables and PowerShell variables from startup do not carry over.

**Expected:** the learner's direct entitlement-group membership is absent. The script never deletes a directory user or group. Cleanup is idempotent and intentionally removes that dedicated lab account's membership even if it was already present before startup. Do not target personal or shared accounts.

Group-based license removal and GitHub deprovisioning follow the tenant's configured policies and schedules; membership removal is not proof that the enterprise seat has already been reclaimed. Confirm downstream removal before recycling the identity. Keep Azure and directory cleanup failures visible to the operator.

## Check each action's result

Actions 3 and 5 write a plain-text status file on the VM. Actions 1, 2, 4 and 6 run in Skillable's cloud platform, which has no desktop, so check their results on the lab instance details page. Action 3's file repeats the results of actions 1 and 2.

| File | Written by | What it shows |
|---|---|---|
| `LAB663-03-environment-status.txt` | Action 3 | Result, current stage, the results of actions 1 and 2, the Foundry account and project to open, and the error message on failure |
| `LAB663-05-azure-cleanup-status.txt` | Action 5 | Result, current stage and the error message on failure |

- The file goes to the desktop of the account that runs the action. If Skillable runs the action as SYSTEM, it goes to the Public Desktop, which every user sees. To use another folder, set `$statusDirectory` at the top of the file.
- `Result: RUNNING` is rewritten at each stage. If it still says RUNNING after the action's timeout, Skillable stopped the action before it could record a result.
- `Result: FAILED` includes the error message with the subscription secret redacted. The full output is still on the lab instance details page.
- "not reported" for action 1 or 2 means action 3 couldn't read that action's result variable. Check that action on the lab instance details page.
- Writing the file never changes an action's result. If the file can't be written, the action logs a warning and carries on.
- Action 5's file is only visible if the VM is kept after teardown.
- During a rehearsal, you can temporarily set actions 1 to 3 to **Notify User** instead of ending the lab, so you can read the file after a forced failure. Set them back before opening the lab.

`SUCCEEDED` doesn't replace the handover checks: Copilot must answer, and notebook 01 must pass as the learner.

**Expected:** a facilitator can tell from the desktop whether the environment is ready, which stage failed and why, without opening the Skillable logs.

## Rehearse before opening the lab

Run the following checks on the actual Skillable image and subscription. A development-subscription pass is useful evidence, but it does not replace them.

- Confirm the pinned commit, package versions, macro substitution, directory application permissions, subscription role-assignment rights and preview feature access.
- Confirm the profile's nine original actions are removed or disabled.
- Exercise directory preparation and cleanup twice, a wrong learner confirmation, a synchronization failure and actual GitHub/Copilot access. Do not use a personal account.
- Run actions 2 and 4 twice each with the subscription's policies applied. The second run must change nothing.
- Verify all three startup actions block handover and end the lab on failure. Verify actions 5 and 6 still run after action 4 fails, and action 6 still runs after action 5 fails.
- Start a fresh instance; run notebook 01 as the learner and verify actual trace ingestion with notebook 04. Sign in to the Foundry portal as the learner and open the agent in `trailmate` without a permission message.
- Read both status files after a successful run and after a forced failure.
- Complete one rubric, optimizer and router path. Record wall time, error counts, complete per-case coverage and the promotion decision.
- Interrupt a wait and resume the saved run ID. Rerun setup without creating duplicate infrastructure or replacing authored agents.
- Exercise an invalid instance ID and `-WhatIf`; neither may delete anything.
- Tear down the tagged resources, verify removal and quota release, and confirm the allocated VM/resource group remain.

Keep the 60-minute schedule as a rehearsal target until it has been timed with beginner learners. Extra router editions and model experiments belong outside the core budget; never reduce the question set to make a run look faster.

### What has been rehearsed

On 13 October 2026, an isolated Azure deployment passed infrastructure provisioning and rerun, six model endpoint checks, ten-manual indexing and baseline reuse. Invalid confirmation and both teardown dry runs preserved resources. Resource-only teardown removed the generated alert, project, account and monitoring while retaining the group; a subsequent action removed the owned disposable group. Account purge was verified. The existing development group was not changed.

That rehearsal used the signed-in review account, not Skillable's service principal and learner identities. The local prerequisite check correctly rejected `azure-ai-projects` 2.1.0 and missing `matplotlib`; no packages were installed. Full notebook execution, the actual Skillable image/macros and learner timing still need a prepared-environment rehearsal. The [router/file-search service failure](../docs/narrative.md#what-the-isolated-rehearsal-tells-us) also remains unresolved.

For the six-action configuration on 19 October 2026, 63 isolated checks passed in each of Windows PowerShell 5.1 and PowerShell 7. They ran all six pasted action bodies against simulated Azure, Graph and helper scripts. They covered group assignment before synchronization, both learner roles at subscription scope with stable assignment names, reruns that change nothing, retries while a new learner identity replicates, failed provisioning, cleanup confirmation, dry runs, role removal limited to the learner and subscription, VM command ordering, status files with the secret redacted, and credential cleanup. To confirm the checks can fail, we injected 17 known faults into copies of the actions; every one was caught. Nothing contacted Azure, Graph or Skillable, so these checks don't prove live Copilot entitlement, role propagation or policy behavior. Bicep CLI was absent locally, so compilation of the actual template and live Skillable identity, entitlement and deployment behavior still need the prepared-image rehearsal.
