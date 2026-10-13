# Infrastructure

Everything we need in Azure, in one command:

```bash
bash infra/deploy.sh
```

The script asks for a subscription, region and chat models. It names a fresh resource group `rg-lab663-NNNN` every run, deploys with Bicep, writes `.env` and creates the v0 TrailMate agent.

## What we get

| Piece | What it is |
|-------|------------|
| Foundry resource and project | Where our agent and models live |
| `gpt-5.4`, `gpt-5.4-mini` | The chat models we compare |
| `mr-default`, `mr-cost`, `mr-quality`, `mr-subset` | Four model router editions. Each one picks models differently |
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
- To skip the questions, set `AZURE_SUBSCRIPTION_ID`, `AZURE_LOCATION` or `LAB663_CHAT_MODELS` first, or pass `--yes` to accept the defaults.
- To remove everything, run `bash infra/cleanup.sh`. It deletes only the resource group named in `.env`, after we type its name to confirm. Add `--purge` to also purge the deleted Foundry resource. Local files are left alone.
- To deploy the infrastructure without the agent, pass `--skip-agent`.
- `.env` holds our project details. It stays on our machine and is never committed.
