# Self-guided walkthrough

This is the full pass through the lab. We deploy once, then work through seven notebooks in order. Each notebook starts with a question, and ends with an "aha" that answers it.

> **This is the first end-to-end run.** None of this has been run against a live Azure subscription yet, so parts of it will probably surprise us. When something doesn't match its **Expected** result, that's exactly the feedback we want.

## Before we start

We need:

- An Azure subscription where we can create resources and role assignments (Owner, or Contributor plus User Access Administrator).
- Quota for `gpt-5.4`, `gpt-5.4-mini` and the model router in the region we pick.
- This repo open in the dev container or a Codespace. It brings Python, the Azure CLI and Bicep.

## Step 1: Deploy (this happens before the clock starts)

```bash
bash infra/deploy.sh
```

It asks for a subscription, region and chat models, then builds our Foundry project in a fresh `rg-lab663-NNNN` resource group, six model deployments (two chat models and four router editions), tracing, access, a `.env` file and our first agent, **v0**. Details are in [infra/README.md](../../infra/README.md).

**Expected:** it ends with `TrailMate v0 is ready.`

**If it fails:** send us the last few lines. A model missing from the region, or access that hasn't arrived yet, are the usual suspects.

## Step 2: Work through the notebooks

Open each notebook in [`labs/core/`](../../labs/core/), pick the **Python 3** kernel, and run one cell at a time with **Shift+Enter**. Keep the **Outline** view open: the numbered sections tell the story.

| Notebook | The question it starts with | Time | The aha |
|---|---|---|---|
| [00 · What are we building?](../../labs/core/00-set-the-stage.ipynb) | What are we building, and how will we know it got better? | read | We're building a repeatable way to *prove* improvement |
| [01 · Set up and validate](../../labs/core/01-setup-and-validate.ipynb) | How do I know my setup really works? | 4 min | "It doesn't work" is useless. "Check 5 failed" is a fix |
| [02 · Choosing a model](../../labs/core/02-model-selection.ipynb) | Which model should I use? | 8 min | The real question is which of my questions need the big model |
| [03 · Multi-model vs multi-modal](../../labs/core/03-multi-model-vs-multimodal.ipynb) | What's the difference, and when do I need each? | 8 min | One is about what comes in, the other about who handles which step |
| [04 · Make it work](../../labs/core/04-make-it-work.ipynb) | How do I find what's wrong without reading every answer? | 12 min | Insights turn opinions into patterns with evidence |
| [05 · Make it better](../../labs/core/05-make-it-better.ipynb) | How do I know it got *better*, not just different? | 14 min | The gain we can trust is the one on questions the optimizer never saw |
| [06 · Make it optimal](../../labs/core/06-make-it-optimal.ipynb) | Can I cut my model bill without losing quality? | 14 min | Savings and risk live in different places: easy vs hard questions |

Notebooks 05 and 06 pick up where the one before left off, so run them in order. They save a few facts in `.lab-state.json`, a local file that is never committed.

## What we haven't been able to test

So we know where to look first:

- **Everything live.** No notebook has run against Azure yet.
- **Insights and the rubric from traces** (notebooks 04 and 05): these use newer SDK calls that we checked against the package, not against a service.
- **The optimizer** (05): the exact settings, and whether our rubric works as its judge.
- **Router editions** (03 and 06): the router version we deploy, and how each edition behaves.
- **Tracing**: whether the Application Insights connection that Bicep creates is enough for traces to show up.
- **Costs:** `data/pricing.json` is empty on purpose, so notebooks compare tokens until we fill in real prices.
- **Timing:** we don't know yet how long the evals and the optimizer take. We have a 60-minute budget to protect.

## Step 3: Clean up

```bash
bash infra/cleanup.sh
```

It finds our resource group in `.env`, lists what's inside, and asks us to type the group's name to confirm. Then it deletes that one resource group and nothing else. Our local `.env` and `.lab-state.json` stay, and it's safe to delete them. Add `--purge` if we want the deleted Foundry resource purged too.

## What to tell us

- Where did we get stuck, and what did the message say?
- Did each notebook's **aha** land? Did we feel we learned something, or just clicked?
- Where was the text too long, too short, or too technical (or not technical enough)?
- How long did each notebook take?
- What did we expect to see that wasn't there?
