# Infrastructure

Everything we need in Azure, in one command:

```bash
bash infra/deploy.sh
```

The script asks for a subscription, region and chat models. Use `eastus` (the default) or `westus`: both offer every model below, including the MAI image models. It names a fresh resource group `rg-lab663-NNNN` every run, deploys with Bicep, writes `.env` and creates the v0 TrailMate agent.

It uses the repository `.venv` and checks Python requirements, SDK capabilities and table rendering **before** Azure sign-in or resource creation. Prepare that environment first; the [self-guided walkthrough](../instructions/self-guided/README.md#use-the-repository-python-environment) explains the dev-container and Windows paths.

For a pre-provisioned Windows Skillable VM, use the [Skillable lifecycle scripts](../skillable_lifecycles/README.md) instead. They call the same Bicep, take explicit tenant/subscription/learner IDs, and track resource ownership for safe teardown. Learners must not mix the two deployment paths.

## What we get

| Piece | What it is |
|-------|------------|
| Foundry resource and project | Where our agent and models live |
| `gpt-5.4`, `gpt-5.4-mini` | The chat models we compare |
| `mr-default`, `mr-cost`, `mr-quality`, `mr-subset` | Four model router editions. Each one picks models differently |
| `MAI-Image-2.6`, `MAI-Image-2.6-Flash` | Image models for the optional image lab. Self-guided only for now |
| Application Insights | Where traces land, so we can see what the agent did |
| Role assignments | Access for us and for the project identity |

## Files

| File | Purpose |
|------|---------|
| [`deploy.sh`](deploy.sh) | Asks the questions, deploys, writes `.env`, builds the agent |
| [`main.bicep`](main.bicep) | Ties the modules together and holds the defaults |
| [`modules/foundry.bicep`](modules/foundry.bicep) | Foundry resource, project, model deployments and the tracing connection |
| [`modules/monitoring.bicep`](modules/monitoring.bicep) | Log Analytics and Application Insights |
| [`modules/roles.bicep`](modules/roles.bicep) | Who can do what |

## Good to know

- We need permission to create role assignments (Owner or User Access Administrator) on the resource group.
- We get three roles on the new resources: Foundry User (models and agents), Cognitive Services User (MAI voice and transcription) and Log Analytics Reader (traces). `deploy.sh` first checks which of these we already hold, directly, through a group or inherited from the subscription, and skips those, so reruns don't warn.
- Both Bicep role controls default to `true`, so self-guided deployment creates learner and project-identity roles. The Skillable PowerShell lifecycle passes `assignLearnerRoles=false`: only learner roles are skipped, while bootstrap and project-identity roles remain. `assignRoles=false` skips the entire roles module.
- The `chatModelDeploymentNames` output returns the deployed chat model names in input order (frontier first, smaller model second). The PowerShell and Skillable setup helpers use it to check or populate the learner's environment.
- To skip the questions, set `AZURE_SUBSCRIPTION_ID`, `AZURE_LOCATION` or `LAB663_CHAT_MODELS` first, or pass `--yes` to accept the defaults. Set `LAB663_IMAGE_MODELS=""` to skip the image models.
- To remove everything, run `bash infra/cleanup.sh`. It deletes only the resource group named in `.env`, after we type its name to confirm. Add `--purge` to also purge the deleted Foundry resource. Local files are left alone.
- To deploy the infrastructure without the agent, pass `--skip-agent`.
- `--skip-agent` still creates a **new** group and explicitly skips package/agent checks; it needs the `.venv` interpreter for local JSON handling. If only agent setup failed, rerun `src/agent/01_build_agent.py` with the same `.venv` interpreter, not the infrastructure deployment.
- `.env` holds our project details. It stays on our machine and is never committed.
- The bootstrap pins the actual v0 version and index in `.lab-state.json`. It reuses a matching baseline and refuses to replace an incomplete index that might already be attached to an agent.
- The six chat and router deployments default to the same capacity; each image deployment uses capacity 1. Check subscription/region quota for the total number of concurrent learner instances, not just one VM. Global Standard does not promise in-region processing.
