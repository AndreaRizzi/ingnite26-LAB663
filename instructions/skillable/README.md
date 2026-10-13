# Guided Skillable walkthrough

Our environment is prepared before the session: a Foundry project, two chat models, four router editions, tracing and the starting TrailMate agent. We use the same code-first notebooks as the self-guided lab, but **we do not deploy or delete infrastructure ourselves**.

Basic Python is helpful; previous agent or evaluation experience is not required. Run one cell at a time, read the expected result, and keep the notebook outline open. Business decision makers can concentrate on the customer failure, the evidence and the promotion decision; developers and AI engineers can inspect the SDK calls and saved results.

## Step 1: Sign in and check our environment

Open the prepared LAB663 folder in VS Code. In the VM terminal, sign in with the **assigned Skillable learner account**, not a personal account or the lifecycle service principal:

```powershell
az login --tenant '<tenant ID supplied by the lab>' --use-device-code
az account show --query "{subscription:name, tenant:tenantId, user:user.name}"
```

Select the subscription supplied by the lab if the displayed one differs. Never paste a password, client secret or access token into a notebook.

**Expected:** the assigned learner identity and subscription are shown, and a local `.env` already exists in the repository root. If not, ask the facilitator to repair the lifecycle. Do not run `infra/deploy.sh`.

Open [01 · Set up and validate](../../labs/core/01-setup-and-validate.ipynb), select **Python (LAB663)**, and run its checks.

**Expected:** every check passes under our learner identity, including the SDK version, model calls and indexed manuals. If a check fails, keep its exact message and ask the facilitator; do not install packages or change the deployment during the session.

Notebook 01 prints its Python interpreter before connecting. It should be the prepared `.venv` used by **Python (LAB663)**, not a system interpreter left selected in VS Code.

## Step 2: Follow the climb

Read [00 · What are we building?](../../labs/core/00-set-the-stage.ipynb) before the timed session. It explains our six failure categories, separate practice/dev/test sets, and the rule that a candidate must earn promotion.

Then follow the notebooks in order. The times below are planning targets, not measured service guarantees.

| Notebook | Our question | Core target |
|---|---|---|
| [01 · Set up and validate](../../labs/core/01-setup-and-validate.ipynb) | Can we trust the setup? | 4 minutes |
| [02 · Choosing a model](../../labs/core/02-model-selection.ipynb) | What changes with model choice? | 8 minutes; reasoning-effort experiment optional |
| [03 · Multi-model vs multi-modal](../../labs/core/03-multi-model-vs-multimodal.ipynb) | Can we trust each step in the pipeline? | 8 minutes; full photo/router experiments optional |
| [04 · Make it work](../../labs/core/04-make-it-work.ipynb) | Which failures do the traces show? | 12 minutes |
| [05 · Make it better](../../labs/core/05-make-it-better.ipynb) | Did the rewrite earn promotion? | 14 minutes |
| [06 · Make it optimal](../../labs/core/06-make-it-optimal.ipynb) | Did routing improve an acceptable trade-off? | 14 minutes; one router edition |

**Expected:** pinned agent IDs, a frozen rubric, complete evaluation results and an explicit promote-or-retain decision. A lower score, pending job, invalid batch or unknown cost is not a success to hide.

**Facilitator note:** the [isolated rehearsal](../../docs/narrative.md#what-the-isolated-rehearsal-tells-us) found router/file-search failures, and one complete evaluation pair took 213 seconds. Resolve the service issue and rehearse the whole schedule on the actual Skillable image; the 60-minute plan has not yet been demonstrated.

## Step 3: Use the waits

Open [the wait-time challenges](../../labs/bonus/wait-time-challenges.ipynb) in a **separate kernel** while a service job runs. They use local files only and do not spend model quota or change the measuring stick.

The core helpers print progress and save evaluation/optimizer IDs. If a bounded wait expires, resume the existing job as the cell explains. Do not click the submit cell repeatedly, restart its kernel unnecessarily, or launch all notebooks at once.

**Expected:** we can discuss an answer-key contradiction, judge evidence, unknown pricing or missing evaluation cases while the core job continues. If the service runs past the session, retain its ID and record the decision as pending.

## Step 4: Finish safely

Read the final scoreboard together. We may retain the original baseline; that is the correct outcome when the evidence does not support a change. Twelve teaching cases and two repeats are not a production release guarantee.

End the Skillable lab when instructed. The platform's teardown action removes this instance's tagged resources. Learners must not run the self-guided cleanup script, purge accounts, or delete the allocated resource group.

**Expected:** the facilitator has our observed timings and any failed check messages, and the lab ends through the normal Skillable controls.
