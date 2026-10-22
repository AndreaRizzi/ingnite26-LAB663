# Skillable lifecycles

LAB663 requires both **GitHub Copilot access** and the **Azure Foundry environment**. These Skillable lifecycle actions assign the learner's GitHub/Copilot entitlement group, provision their enterprise identity, grant the learner's Azure roles, prepare the Windows VM and starting TrailMate agent, and clean up at lab end.

Deployment uses LAB663's [`infra/main.bicep`](../infra/main.bicep) to create the Foundry project, model deployments and monitoring, then runs [`src/agent/01_build_agent.py`](../src/agent/01_build_agent.py) to index the TrailMate manuals and create or reuse the starting agent.

## Configure six actions in Skillable

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

The unnumbered `setup.ps1`, `deployment.ps1`, `teardown.ps1` and `common.ps1` are required VM implementation files, not additional Skillable actions. Keep them in the VM checkout: file 03 calls setup and deployment, file 05 calls teardown, and all three implementations load `common.ps1`. The cloud files need no separate cloud source or export utility. Files 01 and 06 embed the same directory implementation, and files 02 and 04 embed the same role implementation. When you change one file of a pair, make the same change in the other.

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

Create the following **non-secret tenant settings** through the profile's [Variables panel](https://docs.skillable.com/docs/variables). These are names defined for this lab, not additional built-in Skillable tokens.

| Custom variable | Value and timing |
|---|---|
| `Lab663LicenseGroupObjectId` | Object ID of the static GitHub/Copilot entitlement group configured by the tenant administrator; the supplied group name was `_Skillable Events GHE w/ Copilot` |
| `Lab663GitHubServicePrincipalObjectId` | Object ID of the GitHub enterprise application's service principal, not its client/application ID |
| `Lab663GitHubSyncJobId` | Existing synchronization job in that enterprise application |
| `Lab663GitHubSyncRuleId` | Existing user-provisioning rule for that job |

The startup actions resolve the two instance-specific identities themselves. Do **not** enter static learner or deployment-principal IDs in the Variables panel.

| Generated variable | Written by | Used by |
|---|---|---|
| `Lab663LearnerObjectId` | Action 1 looks up the exact `@lab.CloudPortalCredential(User1).Username` in Entra and records its user object ID before changing group membership | Actions 2, 3, 4 and 6 |
| `Lab663BootstrapObjectId` | Action 2 authenticates as `@lab.CloudSubscription.AppId`, reads that application's own service principal and records its object ID before assigning roles | Action 3 |
| `Lab663CopilotAccessStatus` | Action 1 records `SUCCEEDED` or `FAILED` and a UTC timestamp | Action 3 |
| `Lab663AzureRolesStatus` | Action 2 records `SUCCEEDED` or `FAILED` and a UTC timestamp | Action 3 |

Keep actions 1 and 2 **blocking and in that order**. [Skillable variables](https://docs.skillable.com/docs/variables-1) set with `Set-LabVariable` become available to later actions, not replacement tokens inside the action that sets them. Action 1 therefore uses its resolved ID directly, then publishes it for the other actions. A user principal name (UPN, the learner's sign-in name) is not an object ID. Do not invent a `.ObjectId` property on `CloudPortalCredential` or use the application/client ID as the bootstrap object ID.

Supply `LAB663_DIRECTORY_CLIENT_ID` and `LAB663_DIRECTORY_CLIENT_SECRET` as process environment variables in **actions 1 and 6**, using the operator's approved protected secret-injection mechanism. Skillable does not create these variables automatically. Actions 2 and 4 use the subscription credentials instead. Keep the dedicated Entra provisioning application from the supplied lifecycle separate from the subscription deployment application. Do not put its secret in Git, `.env`, ordinary lab variables or learner credential pools. Confirm this secret binding with the Skillable administrator before testing; actions 1 and 6 fail if it is missing.

The directory app needs admin-consented Microsoft Graph **application permissions**: `User.Read.All` for action 1's [learner lookup](https://learn.microsoft.com/en-us/graph/api/user-get?view=graph-rest-1.0) and `GroupMember.ReadWrite.All` for membership changes. **Updating the scripts does not grant that consent**; a tenant administrator must configure it before launch. For on-demand synchronization, the [Graph API reference](https://learn.microsoft.com/en-us/graph/api/synchronization-synchronizationjob-provisionondemand?view=graph-rest-1.0) lists `Application.ReadWrite.OwnedBy` for an application it owns, or `Synchronization.ReadWrite.All`. Configure the intended enterprise application's group assignment, provisioning scope and Copilot seat policy beforehand. A group name alone does not configure those services.

Action 2 uses the subscription application's own credentials for its [service principal lookup](https://learn.microsoft.com/en-us/graph/api/serviceprincipal-get?view=graph-rest-1.0#permissions-for-specific-scenarios). An application can read its own service principal without application permissions. This does not require `Application.Read.All` or `Directory.Read.All` on the subscription application.

**Expected:** the four tenant settings resolve correctly, actions 1 and 2 publish the allocated identity IDs, and privileged directory credentials are available only to actions 1 and 6.

## Action 1: Prepare GitHub Copilot access

Paste the complete [`01-prepare-github-copilot-access.ps1`](01-prepare-github-copilot-access.ps1) file into the **Post-Build** cloud action. It is self-contained: it needs no repository checkout, helper file, Az module or Graph PowerShell SDK on the cloud host. The file already selects `Prepare`, supplies the profile replacement tokens and clears directory credentials on exit. Do not replace it with a path to a file on the VM.

This action first resolves the allocated learner's UPN and publishes `Lab663LearnerObjectId`. It checks that the returned UPN matches and that the object ID is valid, retries a not-yet-visible user for up to eight attempts, and explains a missing `User.Read.All` permission. Publishing the ID must succeed before any membership change, so cleanup still has the exact identity if synchronization later fails.

It then adds and verifies direct group membership and runs the configured Entra synchronization job. Rerunning it does not add duplicate membership. An HTTP 200 with failed or out-of-scope provisioning still throws; only `Success` or unchanged `RedundantExport` with a target identity passes. It records `SUCCEEDED` or `FAILED` in `Lab663CopilotAccessStatus` for action 3's status file. If that status can't be recorded, the action logs a warning; its own result doesn't change.

**Expected:** the learner belongs to the configured entitlement group and Entra reports a provisioned GitHub identity. Actual GitHub sign-in and a usable Copilot response remain required handover checks; there is no fixed delay that proves a seat is ready.

## Action 2: Assign the learner's Azure roles

Paste the complete [`02-assign-learner-azure-roles.ps1`](02-assign-learner-azure-roles.ps1) file into a second **Post-Build** cloud action, after action 1. It replaces the profile's original Role Assignment action and uses the subscription credentials Skillable already supplies, `@lab.CloudSubscription.AppId` and `.AppSecret`. It needs no directory app, Az module or VM checkout.

The action requires the learner ID published by action 1. Before changing roles, it reads its own service principal through Microsoft Graph, checks the returned client ID against the supplied application ID and publishes `Lab663BootstrapObjectId` for action 3. A lookup or variable-publication failure stops the action without assigning roles.

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

The image must already contain Azure CLI, Bicep, VS Code with Python/Jupyter and GitHub Copilot support, and a Python environment satisfying [`requirements.txt`](../requirements.txt). In particular, the lab requires `azure-ai-projects>=2.8.0`; an older SDK can create an agent but cannot run the newer rubric, insights and optimizer calls. Confirm preview feature access in the **Skillable subscription**, not just the development subscription.

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

The Skillable lifecycle service principal needs resource deployment and role-assignment rights **on the allocated lab resource group**. Actions 2 and 4 also read, create and delete the learner's role assignments at **subscription scope**, so the principal needs those rights there too: for example Owner, or Role Based Access Control Administrator with a condition that allows the role IDs in [action 2](#action-2-assign-the-learners-azure-roles) and Log Analytics Reader. The subscription administrator must register `Microsoft.CognitiveServices`, `Microsoft.Insights` and `Microsoft.OperationalInsights` beforehand. Normal Skillable deployment does not create a resource group or register providers.

Preflight also needs subscription-level read access to provider registration and regional model/quota metadata. Authorize the soft-deleted-account purge operation used by teardown separately; resource-group deployment rights alone must not be assumed to include purge. Verify both against the actual lifecycle principal without broadening the learner's permissions.

The platform must allocate the learner account before action 1. Action 1 resolves its Entra **object ID**, and action 2 resolves the lifecycle service principal's **object ID**. An application/client ID identifies the application, not its tenant-specific service principal. The VM deployment still accepts both object IDs explicitly; it never needs directory-app credentials or directory read permissions.

| Input | Source |
|---|---|
| Tenant and subscription | `@lab.CloudSubscription.TenantId`, `@lab.CloudSubscription.Id` |
| Resource group and region | `@lab.CloudResourceGroup(ResourceGroup1).Name`, `.Location` |
| Lab instance ID | `@lab.LabInstance.Id` |
| Client ID and secret | `@lab.CloudSubscription.AppId`, `.AppSecret`, injected into **process-only** variables |
| Learner object ID | `@lab.Variable(Lab663LearnerObjectId)`, published by action 1 from `@lab.CloudPortalCredential(User1).Username` |
| Bootstrap object ID | `@lab.Variable(Lab663BootstrapObjectId)`, published by action 2 from the subscription application's own service principal |

The macro names must match the resource group and credential aliases configured in the Skillable lab profile. Validate substitution in a real Skillable rehearsal; a successful local PowerShell run does not prove that mapping.

Bicep gives the learner and bootstrap principal Foundry access separately. The bootstrap identity authenticates using an isolated Azure CLI cache, which is removed afterwards. It is never left signed in for the learner, and its secret is never written to `.env`, a transcript or a committed file.

## Check Azure Policy in each learner subscription

Each learner gets their own subscription, and the platform applies Azure Policy to that subscription and the allocated resource group. A policy can deny a deployment, change a resource as it's created, or block cleanup. Compare the assigned policies with what LAB663 creates before opening the lab.

| LAB663 creates | What a policy must allow |
|---|---|
| Foundry account `aif-lab663-<token>` | Kind `AIServices`, SKU `S0`, a system-assigned identity, project management, a custom subdomain and public network access. LAB663 doesn't set `disableLocalAuth`, so a policy that denies accounts without it blocks the deployment. |
| Foundry project `trailmate` | A system-assigned identity |
| Six model deployments | `GlobalStandard` SKU at 250 capacity units each |
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

Before it starts, the action checks that Skillable replaced every value it needs, that the identity IDs are valid and that actions 1 and 2 reported success. Missing learner or bootstrap IDs name the action that must publish them. A failed or unreported earlier action stops setup and deployment even if the profile accidentally allows action 3 to run. The action also checks that the checkout exists and writes `LAB663-03-environment-status.txt` to the desktop as it goes; see [Check each action's result](#check-each-actions-result).

Setup and deployment are deliberately in one blocking action: a failed prerequisite check stops deployment, and no ordering between separate script processes is assumed.

**Expected:** `Python (LAB663)` is registered; six model deployments, a project and monitoring resources exist; the VM has a local `.env`, ten indexed manuals and a pinned v0 in `.lab-state.json`. The scripts retain a manifest under the ignored `.lab-lifecycle` directory. A failed action throws rather than reporting success.

An existing VS Code interpreter selection can override a new workspace default. Select the prepared `.venv` and **Python (LAB663)** explicitly when updating an existing image; notebook 01 prints the interpreter it actually uses.

Capacity defaults to 250 units for **each** deployment. Quota is shared at subscription, region, model and SKU scope, and each learner has their own subscription. So **every learner subscription** needs this `GlobalStandard` quota in the lab region: 250 for `gpt-5.4`, 250 for `gpt-5.4-mini` and 1,000 for `model-router`, which serves four router editions. Existing deployments and soft-deleted accounts that haven't been purged also count against it. Catalog and quota checks do not reserve capacity or guarantee preview feature access.

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

It removes this learner's Foundry User, Cognitive Services Contributor and Log Analytics Reader assignments anywhere in their subscription. That covers the subscription-scope roles from action 2 and the resource-scoped roles from `roles.bicep`. It only touches the learner whose saved ID it confirms, and never deletes a user, group or role definition. If action 1 did not publish a valid ID, cleanup fails explicitly; it never searches for a substitute learner.

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

Paste the complete [`06-remove-github-copilot-entitlement.ps1`](06-remove-github-copilot-entitlement.ps1) file into this cloud action. It embeds the implementation, selects `Cleanup`, confirms the learner object ID saved by action 1 and clears directory credentials on exit. It does not resolve the UPN again or substitute another account if the saved ID is missing.

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
- "not reported" for action 1 or 2 means action 3 couldn't read that action's result variable. Check that action on the lab instance details page. A PowerShell parser error happens before the script runs, so even its status-recording code cannot run.
- Writing the file never changes an action's result. If the file can't be written, the action logs a warning and carries on.
- Action 5's file is only visible if the VM is kept after teardown.
- During a rehearsal, you can temporarily set actions 1 to 3 to **Notify User** instead of ending the lab, so you can read the file after a forced failure. Set them back before opening the lab.

`SUCCEEDED` doesn't replace the handover checks: Copilot must answer, and notebook 01 must pass as the learner.

**Expected:** a facilitator can tell from the desktop whether the environment is ready, which stage failed and why, without opening the Skillable logs.

### Repair an older profile with missing identity variables

The earlier scripts expected another integration to populate `Lab663LearnerObjectId` and `Lab663BootstrapObjectId`, but none of the six actions did so. The current scripts resolve those IDs in actions 1 and 2; no seventh action is needed.

| Error in the lab instance details | Meaning and correction |
|---|---|
| Action 1: `Unexpected token '.id'` beside `$details.targetIdentity .id` | The saved action has a space or line break inside the property expression. It must be `$details.targetIdentity.id`. Replace the complete saved action with the raw `.ps1` file, rather than copying formatted output. A parser failure explains why action 1's status is "not reported". |
| Action 2: cannot convert `@lab.Variable(Lab663LearnerObjectId)` to `System.Guid` | Skillable passed an unresolved variable, not an Entra ID. The updated action 1 publishes it before action 2 starts. |
| Action 3: missing `BootstrapObjectId, LearnerObjectId` | The earlier actions have not supplied their IDs. Repair and rerun actions 1 and 2 before retrying action 3; changing VM paths cannot fix this. |

Replace the complete contents of actions **1, 2, 3, 4 and 6** with the corresponding files in this folder, and check the `User1` and `ResourceGroup1` aliases. Action 5 is unchanged. Have the administrator consent `User.Read.All` on the dedicated directory app, keep its protected credentials bound to actions 1 and 6, and retain the four tenant settings above. Keep all startup actions blocking and configured to end the lab on failure.

Launch a fresh instance, or rerun the repaired startup actions in order on the same allocated identities. Check that action 1 reports the learner ID was recorded and action 2 reports the bootstrap ID was recorded before action 3 starts. Do not enter a previous learner's ID or the application/client ID to get past the error.

**Expected:** both cloud startup actions succeed before VM preparation. Only `LAB663-03-environment-status.txt` is created on the desktop during startup; `.env` and state files appear inside the LAB663 checkout after deployment progresses. The cleanup status file is written only during teardown.

## Rehearse before opening the lab

Run the following checks on the actual Skillable image and subscription. A development-subscription pass is useful evidence, but it does not replace them.

- Confirm the pinned commit, package versions, macro substitution, directory application permissions, subscription role-assignment rights and preview feature access.
- Confirm action 1 resolves this instance's learner, action 2 resolves its own service principal, and their published IDs reach action 3. Check missing consent, an unknown learner and variable-publication failure: the failing action must not change access, and action 3 must not deploy.
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
