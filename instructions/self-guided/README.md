# Self-guided walkthrough

We run the lab on our own, in our own Azure subscription. We deploy once, then work through seven notebooks in order. Each notebook starts with a question and ends with an "aha" that answers it.

This walkthrough has the same modules as the in-venue [Skillable manual](../skillable/README.md). The difference is setup: here we deploy and clean up ourselves.

> **Check the evidence, not just the happy path.** Some features are in preview and can fail in ways the notebooks don't predict. When something differs from its **Expected** result, keep the exact message and run ID.

## Before we start

| We need | For | Notes |
|---|---|---|
| A GitHub account with active Copilot access, signed in to Copilot in our editor | All modules | Our GitHub and Azure sign-ins are separate checks |
| An Azure subscription where we can create resources and role assignments | All modules | Owner, or Contributor plus User Access Administrator |
| Quota for `gpt-5.4`, `gpt-5.4-mini`, the model router and the MAI image models in `eastus` or `westus` | All modules | `deploy.sh` checks before it creates anything |
| This repo in the dev container or a Codespace | All modules | It brings Python, the Azure CLI and Bicep, and prepares `.venv` with `azure-ai-projects>=2.8.0` |
| Access to the preview rubric, insights and optimizer APIs | Modules 4 to 6 | Notebook 01 stops if the SDK is too old |

Basic Python helps; previous agent or evaluation experience isn't required. The required workflow stays in code. Portal views are optional.

## Modules

Work through these in order. Each page tells us what to run, what to expect and what to take away.

| Module | Page | The question | Time |
|---|---|---|---|
| 0 | [Get ready](core/00-get-ready.md) | What are we building? | Before the clock: deploy, then about 5 min of reading |
| 1 | [Set up and validate](core/01-setup-and-validate.md) | How do we know our setup really works? | 4 min |
| 2 | [Choosing a model](core/02-model-selection.md) | Which model should we use? | 8 min |
| 3 | [Multi-model vs multi-modal](core/03-multi-model-vs-multimodal.md) | What's the difference, and when do we need each? | 8 min |
| 4 | [Make it work](core/04-make-it-work.md) | How do we find what's wrong without reading every answer? | 12 min |
| 5 | [Make it better](core/05-make-it-better.md) | How do we know it got *better*, not just different? | 14 min target |
| 6 | [Make it optimal](core/06-make-it-optimal.md) | Can we cut the model bill without losing quality? | 14 min target |
| More | [Explore Microsoft AI models](more/00-explore-mai-models.md) | What can MAI models do for a product launch? | Optional |

The times are a planning budget, not a measured promise. The core uses one router edition; choose all four **before** starting Module 6 for a longer experiment. Reasoning-effort and full photo comparisons are optional. Don't cut cases or repeats to meet the clock.

Notebooks 04, 05 and 06 share `.lab-state.json`, so run them in order, not at the same time. The file records pinned versions, dataset fingerprints and service job IDs. Raw evaluation evidence stays in the ignored `.lab-results` directory.

## While a service job runs

Each core notebook has a **While you wait** box next to its long-running cells. It needs no code, so it doesn't compete with the busy kernel or spend model quota.

Longer wait, or finished early? Read the optional [More labs](../../labs/more/README.md) in replay mode.

**Expected:** progress and a saved run ID in the core notebook. A bounded wait may end while the service job continues. Resume that ID as the cell explains; don't resubmit the batch.

## What to verify in our subscription

- **Feature access:** insights, rubric generation and the optimizer must work in our own subscription and region.
- **Tracing:** a connection string isn't proof of ingestion. Confirm the analysis actually saw the practice traces.
- **Evaluation inputs:** retrieval criteria need structured tool evidence. Read the judge's per-dimension reasons before trusting the aggregate.
- **Coverage:** every repeat must score all twelve questions. An incomplete batch can't earn promotion.
- **Cost:** fill verified regional prices, source and date in `data/pricing.json` before claiming savings. Missing prices stay unknown, not zero.
- **Timing:** record elapsed job time and request latency separately.

## Clean up

```bash
bash infra/cleanup.sh
```

It deletes only the resource group named in `.env`, after we type its name. See the end of [Module 6](core/06-make-it-optimal.md#clean-up).

## What to tell us

- Where did we get stuck, and what did the message say?
- Did each notebook's **aha** land? Did we feel we learned something, or just clicked?
- Where was the text too long, too short, or too technical (or not technical enough)?
- How long did each notebook take?
- What did we expect to see that wasn't there?
