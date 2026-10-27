# Skillable test walkthrough

This is our working log from testing LAB663 on Skillable. We record each command we ran, what we saw and any fixes we needed. Later we'll turn it into the Skillable learner instructions.

Screenshots live in [screenshots/](./screenshots/).

## How we're testing

| Phase | What we're checking | How |
|---|---|---|
| Phase one | The Skillable subscription has everything the lab needs | Sign in as the Skillable learner and provision with [test-deploy.sh](./test-deploy.sh) |
| Phase two | The Skillable VM's pre-provisioned subscription works for learners | Follow only the steps that apply to the pre-provisioned environment |

**Why a test script:** a first attempt with `infra/deploy.sh` created the models and monitoring, then failed at role assignments. The Skillable learner role (**LOD Contributor**) can't assign roles. `test-deploy.sh` deploys into the Skillable resource group `LAB663` without the role assignments.

### Files in this folder

| File | Who runs it | What it does |
|---|---|---|
| [lab663-skillable.bicep](./lab663-skillable.bicep) | Skillable, at lab launch | One self-contained template: monitoring, Foundry resource and project, six model deployments and role assignments. Region limited to `swedencentral`, `eastus` or `eastus2`. Capacities are parameters: `frontierCapacity` (250), `smallCapacity` (150), `routerCapacity` (150). `assignRoles` defaults to `true`, which needs an identity that can assign roles |
| [setenv.sh](./setenv.sh) | The learner, after Skillable deploys | Finds the lab resources in `LAB663` and writes `.env`. Read-only in Azure |
| [test-deploy.sh](./test-deploy.sh) | Us, for phase one | Checks roles, services and quota, deploys `lab663-skillable.bicep` with `assignRoles=false`, then runs `setenv.sh` |

The first part of phase one (steps 3–6) used an earlier `test-deploy.sh` that compiled `infra/main.bicep` and removed its role assignments. We then switched to the single template so phase one tests what Skillable will deploy. A what-if preview against `LAB663` showed the single template matches the deployed resources: nothing created or deleted, same capacities and routing.

## Phase one: validate the Skillable subscription

### Environment

| Item | Value |
|---|---|
| Date | 2026-10-18 |
| Where we ran it | GitHub Codespaces (browser) |
| Branch | `nitya/oct16-test` |
| Subscription | `EventsCSSR-lodXXXXXXXX` (Skillable lab subscription; name and ID change per lab instance) |
| Account used | `User1-XXXXXXXX@LODSPRODMCA.onmicrosoft.com` (Skillable lab user) |
| Resource group | `LAB663` (created by Skillable) |
| Region | `swedencentral` (set in `test-deploy.sh`; the `LAB663` group itself is in `canadacentral`) |
| Capacity | `gpt-5.4` 250, all other deployments 150 (started at 150 for all; see troubleshooting) |

### Timings

Approximate, from command output, notebook save times and evaluation timestamps. Notebook times include reading and thinking, not just waiting.

| What | Start | End | About |
|---|---|---|---|
| `test-deploy.sh`, sign-in to `.env` | 15:56 | 15:58 | 2.5 min (Bicep about 2 min) |
| Create the v0 agent | 16:00:43 | 16:02 | 1.5 min |
| Notebook 00 | 16:07 | 16:08:34 | 2 min |
| Notebook 01 | 16:09 | 16:10:51 | 2 min |
| Notebook 02 | 16:11 | 16:12:28 | 1.5 min |
| Notebook 03 | 16:13 | 16:14:06 | 1.5 min |
| Notebook 04 | 16:16 | 16:28:45 | 13 min (insights about 4 min; writing our gaps) |
| Notebook 05, rubric generation | 16:30 | 16:31 | 1 min |
| Notebook 05, v0 on dev (2 repeats) | 16:34:11 | 16:39:33 | 5.5 min (invalid: rate-limited) |
| Notebook 05, v1 on dev (2 repeats) | 16:39:34 | 16:44:58 | 5.5 min (valid) |
| Raise `gpt-5.4` to 250, rerun notebook 01 | 16:50 | 16:55:56 | 6 min |
| Notebook 05, v0 on dev, attempt 2 | 16:58 | 17:01:59 | 4 min (valid) |
| Notebook 05, v1 on dev, attempt 2 | 17:02 | 17:04:29 | 2.5 min (valid) |
| Codespace shutdown | 17:04 | 17:13 | 9 min (not part of the lab) |
| Notebook 05, optimizer job (5.6) | 17:17 | 17:30 | 13 min |
| Notebook 05, test set v0/v1/v2 (5.10) | 17:34 | 17:44:30 | 10.5 min (three batches, one after another) |
| Notebook 05, v2 on dev (5.11) | 17:46:26 | 17:49:41 | 3.3 min |
| Notebook 05, finished (5.12) | 16:30 | 17:54 | about 80 min (includes about 25 min of rate-limit fix and 9 min shutdown) |
| Notebook 06 | 17:55 | 18:04:41 | about 10 min (one dev batch, invalid; no test batch) |

### Steps

_We add each step here as we go: the command, what we expected, what happened and a screenshot when it helps._

#### Step 1: Open the repo in Codespaces

We opened the repository on branch `nitya/oct16-test` in GitHub Codespaces and waited for the dev container setup to finish.

**Expected:** VS Code in the browser with a terminal at the repository root.

**Result:** the Codespace opened with a working terminal prompt.

#### Step 2: Check the tools

```bash
az version && python --version && copilot --version
```

**Expected:** each command prints a version.

**What happened:**

```text
{
  "azure-cli": "2.91.0",
  "azure-cli-core": "2.91.0",
  "azure-cli-telemetry": "1.1.0",
  "extensions": {}
}
Python 3.13.16
GitHub Copilot CLI 1.0.98.
Run 'copilot update' to check for updates.
```

**Result:** Azure CLI 2.91.0, Python 3.13.16 and GitHub Copilot CLI 1.0.98 are installed. The `copilot update` line is just a reminder; we don't need to update for the lab.

#### Step 3: Run the test deployment script

```bash
bash instructions/skillable/test-deploy.sh
```

**Expected:** the script checks our Python environment, then asks us to sign in to Azure.

**What happened:** the environment check passed, then the script started a device code sign-in:

```text
==> Checking our Python environment
Python interpreter: /workspaces/ignite26-LAB663/.venv/bin/python
PASS azure-ai-projects 2.8.0
PASS azure-identity 1.26.0
PASS python-dotenv 1.2.4
PASS openai 3.33.0
PASS ipykernel 7.4.0
PASS pandas 3.0.6
PASS jinja2 3.1.6
PASS matplotlib 3.11.2
PASS Python requirements, Foundry SDK capabilities and table rendering; Azure access is checked separately.

==> Checking our Azure sign-in
We're not signed in yet. Follow the device code steps with the Skillable lab account.
To sign in, use a web browser to open the page https://login.microsoft.com/device and enter the code XXXXXXXXX to authenticate.
```

**Result:** environment check passed; waiting for device code sign-in.

#### Step 4: Complete the device code sign-in

We opened `https://login.microsoft.com/device`, entered the code and signed in with the Skillable lab credentials from the lab instructions (username and Temporary Access Pass).

**Expected:** the script confirms the subscription and the account we signed in with, then checks the `LAB663` resource group and our roles.

**Result:** signed in. The script confirmed the subscription and account:

```text
Subscription: EventsCSSR-lodXXXXXXXX
Signed in as: User1-XXXXXXXX@LODSPRODMCA.onmicrosoft.com
```

#### Step 5: Pre-deployment checks

The script then checked the resource group, our roles, the Azure services, and the models and quota. All checks passed:

```text
==> Checking the resource group LAB663
PASS resource group LAB663 exists (group region: canadacentral, lab instance: XXXXXXXX)
INFO resources deploy to swedencentral; the group's own region doesn't limit that

==> Checking the roles Skillable granted us
  - Cognitive Services Contributor
  - Foundry User
  - LOD Contributor
PASS can create resources (Owner, Contributor or LOD Contributor)
PASS can use Foundry projects and agents (Foundry User)
PASS Cognitive Services Contributor
INFO we can't assign roles, so role assignments are skipped

==> Checking the Azure services are registered
PASS Microsoft.CognitiveServices
PASS Microsoft.Insights
PASS Microsoft.OperationalInsights

==> Checking models and quota in swedencentral (capacity 150 per deployment)
PASS gpt-5.4@2026-03-05: need 150 more units, 9750 free
PASS gpt-5.4-mini@2026-03-17: need 150 more units, 9750 free
PASS model-router@2025-11-18: need 600 more units, 9000 free
```

**What this tells us:**

| Check | Finding |
|---|---|
| Resource group | Skillable creates `LAB663` in `canadacentral`, tagged with the lab instance ID. |
| Default roles | **LOD Contributor**, **Foundry User** and **Cognitive Services Contributor**, all at subscription scope. Enough to create resources and use Foundry, but not to assign roles. |
| Azure services | All three already registered, so no wait. |
| Quota | Limit 10,000 per model. The 250 and 1,000 units already in use are from the earlier `infra/deploy.sh` attempt, which still counts until its Foundry resource is deleted and purged. |

**Result:** all pre-deployment checks passed.

#### Step 6: Deploy monitoring, Foundry and models

**Expected:** after a few minutes, the script lists six model deployments and writes `.env`.

**What happened:** the deployment finished in about 2 minutes:

```text
==> Deploying monitoring, Foundry and models into LAB663 (this takes a few minutes)
Removed the role assignments module from the compiled template.
PASS deployed aif-lab663-XXXXXX, project trailmate and appi-lab663-XXXXXX
Deployment    Model         Capacity    State
------------  ------------  ----------  ---------
gpt-5.4       gpt-5.4       150         Succeeded
gpt-5.4-mini  gpt-5.4-mini  150         Succeeded
mr-default    model-router  150         Succeeded
mr-cost       model-router  150         Succeeded
mr-quality    model-router  150         Succeeded
mr-subset     model-router  150         Succeeded

==> Writing /workspaces/ignite26-LAB663/.env
PASS wrote .env (project endpoint: https://aif-lab663-XXXXXX.services.ai.azure.com/api/projects/trailmate)

Resources are provisioned. The v0 agent was NOT created. When ready:
  "/workspaces/ignite26-LAB663/.venv/bin/python" "/workspaces/ignite26-LAB663/src/agent/01_build_agent.py"
```

**Result:** the learner account provisioned everything in `LAB663`:

| Created | Details |
|---|---|
| Foundry resource and project | `aif-lab663-XXXXXX`, project `trailmate` |
| Monitoring | Application Insights `appi-lab663-XXXXXX` and its Log Analytics workspace |
| Model deployments | `gpt-5.4`, `gpt-5.4-mini` and four router editions (`mr-default`, `mr-cost`, `mr-quality`, `mr-subset`), GlobalStandard, 150 each |
| Local settings | `.env` with `LAB663_DELIVERY_MODE=skillable` (ignored by git) |

Not done yet: the v0 agent.

#### Step 7: Create the v0 agent as the learner

We created the agent ourselves, signed in as the Skillable learner, to check the learner account can do it:

```bash
.venv/bin/python src/agent/01_build_agent.py
```

The script reads `.env` (project endpoint, model `gpt-5.4`, agent name `trailmate`) and signs in with our Azure CLI session.

**Expected:** ten manuals uploaded and indexed into a vector store, then `TrailMate v0 is ready.` with the agent version.

**What happened:** the whole step took about 1.5 minutes:

```text
Creating the vector store and uploading the manuals...
Uploaded and indexed 10 manuals.
Creating the agent 'trailmate' on 'gpt-5.4'...

TrailMate v0 is ready.
  Agent        : trailmate (version 1)
  Model        : gpt-5.4
  Vector store : vs_XXXXXXXXXXXXXXXXXXXXXXXX
```

The project responded on the first try (no HTTP 403 retries). The agent version and vector store ID are saved in `.lab-state.json`.

**Result:** the learner account can upload files, build a vector store and create a Foundry agent.

**Does this match the lab flow?** Yes. `infra/deploy.sh` (self-guided) and `skillable_lifecycles/deployment.ps1` (Skillable) both run this same script before learners open the notebooks. Notebook 01 (check 1.6) expects v0 and its saved state to exist already. Notebooks 04–06 create v1–v3 from it.

**For the Skillable instructions:** notebook 01 section 1.6 says "`infra/deploy.sh` created TrailMate v0". In Skillable the lifecycle creates it, so that wording needs a tweak.

#### Step 8: Open notebook 00 and select the kernel

We opened `labs/core/00-set-the-stage.ipynb`, chose **Select Kernel** and picked the **.venv (Python 3.13.16)** environment.

**Expected:** the notebook toolbar shows `.venv (Python 3.13.16)` as the kernel.

**Result:** kernel selected.

We ran every cell top to bottom, one at a time. The last cell confirmed the deployment settings:

```text
Found .env. On to notebook 01.
```

**Watch out:** we first jumped between sections using the VS Code **Outline** view and ran the cell under 0.2. It failed with `NameError: name 'lab' is not defined` because the import cell (just after the 0.1 intro) hadn't run yet. Running the cells in order fixed it.

**Result:** notebook 00 ran cleanly.

**For the Skillable instructions:** run the notebooks **one cell at a time**, not with **Run All**. Each code cell is followed by a "read the output" or **Think** prompt, and the lab's value is in reading each result before moving on. Running cell by cell also makes it obvious which cell failed.

#### Step 9: Open notebook 01

We opened `labs/core/01-setup-and-validate.ipynb`. VS Code had already selected the **.venv** kernel, remembered from notebook 00, so we didn't need to pick it again.

**Expected:** every check passes under the learner identity: settings, project access, models and routers, the pinned v0 agent, manuals index, tracing and data.

**What happened:** the first check confirmed the notebook uses the repository `.venv` and all packages are present:

```text
Notebook interpreter: /workspaces/ignite26-LAB663/.venv/bin/python
PASS azure-ai-projects 2.8.0
PASS azure-identity 1.26.0
PASS python-dotenv 1.2.4
PASS openai 3.33.0
PASS ipykernel 7.4.0
PASS pandas 3.0.6
PASS jinja2 3.1.6
PASS matplotlib 3.11.2
PASS  Python environment supports this lab
```

**Result:** all 27 checks passed under the learner identity:

```text
27 of 27 checks passed

Overall: PASS. Our camp is ready.
```

| Check | Result |
|---|---|
| Python environment | `.venv`, all eight packages |
| `.env` settings | Complete |
| Project access | Connected to `https://aif-lab663-XXXXXX.services.ai.azure.com/api/projects/trailmate` |
| Model deployments | All six exist; versions, routing settings and capacity recorded |
| Model calls | `gpt-5.4`, `gpt-5.4-mini` and all four routers answered |
| v0 agent | Pinned v0 is Foundry version 1 on `gpt-5.4`, instructions `"You are a helpful agent."` |
| Manuals index | Ten manuals indexed; v0 searches this vector store |
| Tracing | Project connected to Application Insights |
| Data | 13 data checks passed (manuals, practice/dev/test sets, unique IDs and queries, every fact quote found in its manual) |

The router editions chose these models for the "hello" test:

| Router | Answered by |
|---|---|
| `mr-default` | `grok-4-1-fast-reasoning` |
| `mr-cost` | `gpt-6-luna-2026-09-22` |
| `mr-quality` | `gpt-5.5-2026-04-24` |
| `mr-subset` | `gpt-5.6-luna-2026-07-09` |

Router choices can change from run to run.

The last cell (1.11) breaks a call on purpose and shows the expected `404 - The API deployment for this resource does not exist` error. That's the lesson, not a failure.

**Note:** the tracing check confirms the project is connected to Application Insights. Notebook 04 is where we see whether traces actually arrive.

#### Step 10: Run notebook 02 (model selection)

We ran `labs/core/02-model-selection.ipynb` top to bottom.

**Expected:** both chat models answer easy, medium and hard questions, with a table of speed and tokens for each.

**What happened:** every cell ran with no errors. Both models answered all three questions correctly; `gpt-5.4-mini` was about twice as fast:

| Level | `gpt-5.4` | `gpt-5.4-mini` |
|---|---|---|
| Easy | 3.9 s, 22 output tokens | 1.3 s, 26 output tokens |
| Medium | 1.8 s, 54 output tokens | 1.1 s, 44 output tokens |
| Hard | 2.3 s, 89 output tokens | 1.4 s, 86 output tokens |
| **Total** | **8.0 s, 165 output tokens** | **3.8 s, 156 output tokens** |

Other sections:

| Section | What we saw |
|---|---|
| 2.5 Cost | `No prices yet. Open data/pricing.json...`, as expected. Only token counts are shown. |
| 2.6 Reasoning effort (optional) | `high` took 4.9 s and 230 output tokens, `low` took 3.5 s and 156. Same answer. |
| 2.8 The aha | Easy and medium on `gpt-5.4-mini`, hard on `gpt-5.4`: 159 output tokens instead of 165, **4% fewer**. |

**Result:** notebook 02 ran cleanly as the learner.

**For the Skillable instructions:**

- **Cost stays unknown in Skillable even with prices.** `data/pricing.json` is set to `eastus2`, and the lab only shows cost when that matches `AZURE_LOCATION` (`swedencentral` here). If we fill in prices for Skillable, they need to be `swedencentral` prices.
- **The aha is small.** 4% fewer output tokens. Each call also used about 4,900 input tokens, so output tokens are a small share of usage. The notebook says this isn't a dollar estimate; facilitators should expect that question.
- **Timings vary.** The first call (3.9 s) was slower than the rest. Don't quote exact seconds.

#### Step 11: Run notebook 03 (multi-model vs multimodal)

We ran `labs/core/03-multi-model-vs-multimodal.ipynb` one cell at a time, on the guided core path (defaults unchanged).

**Expected:** the notebook says a wrong photo identification is "part of the lesson, not a successful pipeline". Expect a two-row photo table, a STOP warning if the photo guess disagrees with the lab label, and a six-row routing table.

**What happened:** every cell ran with no errors:

| Section | What we saw |
|---|---|
| 3.1 | Three photos ready: tent, jacket, stove |
| 3.2 Photo understanding | `gpt-5.4-mini` named the Alpine Explorer Tent correctly; `gpt-5.4` guessed the **TrailMaster X4 Tent** (wrong) |
| 3.3 Two-step answer | The photo guess was **RainGuard Hiking Jacket**. The notebook printed `STOP: the photo guess was wrong. The confirmed lab label is Summit Breeze Jacket.` and TrailMate then answered correctly: not waterproof, only water-resistant |
| 3.4 Homemade router | Six practice questions: three to `gpt-5.4-mini`, three to `gpt-5.4`. The hot chocolate question was tagged `easy` but went to `gpt-5.4` |
| 3.5 The aha | `Our router sent 50% of these questions to gpt-5.4-mini.` |

**Result:** notebook 03 ran cleanly as the learner, and the guardrails worked as designed.

**For the Skillable instructions:**

- **Wrong guesses are expected, and they vary.** This run the bigger model got the tent wrong and the small one got it right. Facilitators should present misidentification as the point of the lesson, not as a broken lab.
- **The STOP guard is the teaching moment.** The photo guess was wrong, but the answer used the confirmed label and gave the correct waterproofing advice.
- **The homemade router isn't perfect on purpose.** One `easy` question (hot chocolate) went to the big model, which is a good opener for section 3.5.

#### Step 12: Run notebook 04 (make it work)

We ran `labs/core/04-make-it-work.ipynb` one cell at a time.

**Expected:** v0's weak answers, an insights monitor, v1 saved as a new Foundry version, 12 practice questions sent so traces reach Application Insights, then a Foundry insights run that finds what's wrong.

**What happened so far:**

| Section | What we saw |
|---|---|
| 4.1 | Connected; 12 practice questions ready |
| 4.2 How bad is v0? | Mixed. Correct on the jacket and on the shoe weight not being specified, but it gave a full hot chocolate recipe (out of lane) |
| 4.3 Monitor | `Created monitor: monitor_XXXX` |
| 4.4 v1 | v1 instructions saved: `TrailMate v1 is Foundry version 2.` |
| 4.5 Traffic | All 12 practice questions answered |
| 4.6 Reading answers ourselves | v1 still gives the hot chocolate recipe; it called the backpack rain cover "unclear/inconsistent" (see the follow-ups section) |
| 4.7 Waiting for traces | Counted down from 60 s |
| Portal check | We opened the Foundry portal and **saw the traces** for these runs |
| 4.8 Insights | Run accepted: `queued` for about 45 s, then `in_progress`. The first attempt reported `telemetry isn't all there yet` and the cell retried by itself after 60 s. Finished after about 4 minutes: `Traces seen: 16 | analyzed: 16`, `Insights created: 3` |
| 4.8 Findings | **HIGH** hallucinations: an "EcoFire tent" question answered with the EcoFire **stove's** colour. **MEDIUM** hallucinations: daypack weight "1.5 lbs" not shown in the retrieved text. **MEDIUM** cost_tokens: file search and about 18k input tokens for the hot chocolate recipe |
| 4.9 Our gaps | Stopped with `ValueError: Write the gaps we actually observed before continuing.` This is deliberate. We replace the three placeholders in `our_gaps` with gaps we saw ourselves, then rerun the cell |

**The gaps we tried in 4.9** (written with Copilot's help from this run's 4.2, 4.6 and 4.8 output):

```python
our_gaps = [
    "Out of lane: v0 and v1 both give a full hot chocolate recipe instead of politely redirecting to Contoso Outdoors products",
    "Wrong premise: asked about an 'EcoFire tent', it answers with the EcoFire Camping Stove's colour instead of saying we don't sell an EcoFire tent",
    "Making things up: states the TrailLite Daypack weighs 1.5 lbs as verified when the retrieved text in that trace didn't show any weight",
]
```

The first comes from our own reading; the other two come from Foundry's insights. Alternative from our own reading: "Not useful: on the backpack rain cover it says 'unclear/inconsistent' and stops, instead of quoting both manual lines so the customer can decide".

**What this tells us:** traces arrive and Foundry accepts the insights run, even though the project's own identity has none of the roles we skipped.

**Content feedback (notebook 04, section 4.9):** in the **✏️ Your turn · Edit before you run** box, encourage learners to ask Copilot for help drafting `our_gaps`, then check its suggestions themselves. Proposed addition, after "Edit the list, then run the cell again.":

> **Stuck?** Ask GitHub Copilot Chat: *"Using the answers in 4.2 and 4.6 and the insights in 4.8, suggest three specific gaps for `our_gaps`, each starting with one of our six ways to lose trust."* Then check each suggestion against the answers we actually saw. Keep only gaps we can point to, because this list becomes our judge.

Not changed yet; we'll apply it after this run.

**Content feedback (notebook 04, section 4.8):** the markdown cell right after the insights wait opens with "The run is done. Now let's read what it found." While the cell above is still printing `queued` and `in_progress`, that line reads like part of the output, as if the run had already finished. Suggested rewording: "**When the cell above prints `Insights created:`**, let's read what it found." Also add an **Expected:** line under the wait cell: it shows `queued` and `in_progress` for several minutes, then prints `Traces seen`, `analyzed` and `Insights created`. Not changed yet.

**Result:** notebook 04 completed as the learner. Section 4.9 printed our three gaps and saved them with the monitor ID. Section 4.10:

```text
We read 3 answers by hand.
Foundry analyzed 16 traces and found 3 patterns.
```

`.lab-state.json` now has `v0_version` (1), `v1_version` (2), `our_gaps` (3) and `monitor_id`, everything notebook 05 needs.

**For the Skillable instructions:**

- **Insights can take about 4 minutes** and may retry once with "telemetry isn't all there yet". That's normal, and it's a good moment for the bonus notebook.
- **The `ValueError` in 4.9 is a gate, not a bug.** Learners must write their own gaps; they're saved and used to build the judge in notebook 05. Say so in the instructions so learners don't think the lab broke.
- **Insights check evidence, not truth.** The daypack does weigh 1.5 lbs (`product_info_16.md`, line 39). Foundry flagged it because the retrieved text in that trace didn't show the number. Facilitators should be ready to explain that.

#### Step 13: Run the bonus notebook while insights run

While notebook 04 waited on insights, we opened `labs/bonus/wait-time-challenges.ipynb` in its own kernel and ran it one cell at a time. It reads local files only and makes no Azure calls.

**What happened:** every cell ran with no errors:

| Challenge | What we saw |
|---|---|
| Setup | `Ready: local files only. Our core job can keep running.` |
| 1. Manual detective | Shows both backpack lines (line 20 "Rain cover included", line 45 "Rain Cover: No") against the answer key, the same contradiction v1 noticed in step 12 |
| 2. Judge the judge | Two answers about the Summit Breeze Jacket to compare against the manual evidence |
| 3. The budget hearing | `Region: eastus2 | Price date: None | Source: None`, with every model's prices missing |
| 4. Route detective | `No completed evidence file yet. Let the core job continue; do not resubmit it.` This is expected: evaluation evidence files only start appearing in notebook 05 |

**Result:** the bonus notebook works as a wait-time activity. It didn't interfere with the insights run in notebook 04.

**For the Skillable instructions:** the bonus notebook fits naturally into the insights wait in notebook 04, and notebook 04 suggests it at that point. Learners should open it in its own kernel and leave the core notebook's kernel running.

#### Step 14: Run notebook 05 (make it better)

We opened `labs/core/05-make-it-better.ipynb`. This notebook runs the first cloud evaluations, so it's slower than the others.

**What happened so far:**

| Section | What we saw |
|---|---|
| 5.2 Rubric generation | `queued` for about 60 s, then `Rubric created: trailmate-rubric-XXXXXX version 1` |
| 5.3 The rubric | Seven weighted dimensions built from our gaps: grounded factual accuracy (10), scope discipline (6), premise validation (5), evidence gap transparency (4), ambiguity handling (3), constructive redirection (3) and general quality (5). Pass threshold 0.5 |
| 5.5 v0 on dev | Two repeats started together at 16:34. One scored all 12 questions; the other had **2 errored** questions. The notebook marked the batch `INVALID v0 on dev: no comparable score or cost.` after about 5 minutes |
| 5.5 v1 on dev | Started straight after v0. Both repeats scored all 12 questions: **score 0.806**, spread 0.005, 181,460 tokens, 0 errored. Took about 5.5 minutes |
| 5.5 Comparison | Stopped with `RuntimeError: Incomplete evaluations cannot be compared or promoted: v0 on dev`. This is the notebook's guard, as expected after an invalid batch |
| Fix | Raised `gpt-5.4` to 250 (see troubleshooting), cleared the saved deployment settings and reran notebook 01, which re-recorded them at 16:55:56 (`gpt-5.4` 250, others 150) |
| 5.5 Retry | Reran 5.5 with `attempt=2` for **both** v0 and v1, so both are measured at the new capacity. Both valid, 0 errored: |

**How to read the scoreboard (score, spread, errored, tokens):**

| Column | What it is | How it's worked out |
|---|---|---|
| **Score** | How good this version's answers are, from 0 to 1 | A judge (`gpt-5.4` with our rubric) scores every answer from 0 to 1, weighting the rubric's seven dimensions. 0.5 or more counts as a pass. We average the 12 question scores for each repeat, then average the two repeats |
| **Spread** | How much the score moved between two identical runs | Highest repeat average minus lowest. Same agent, same questions, but answers and judging vary a little each time |
| **Errored** | Questions that got **no** score | A 429 or other error. One errored question makes the whole batch invalid, because an average over 11 questions isn't comparable with one over 12 |
| **Tokens** | Average tokens per repeat (agent plus judge) | A usage measure, not dollars |

Two things to keep in mind:

- **One question is worth up to 1/12 ≈ 0.083 of the score.** A single answer going from pass to fail can move a version's score more than most of the gaps we're comparing.
- **Compare the gap between versions with their spreads.** If two versions' repeats overlap, we can't tell them apart from this run alone. The notebook calls spread "a small variability check, not a confidence interval": two repeats is too few for statistics.

A worked example from our test set (5.10):

| Version | Repeat 1 | Repeat 2 | Score | Spread |
|---|---|---|---|---|
| v0 | 0.667 | 0.718 | 0.692 | 0.052 |
| v1 | 0.718 | 0.729 | 0.724 | 0.011 |
| v2 | 0.749 | 0.747 | 0.748 | 0.002 |

- **v1 against v2:** both of v2's repeats beat both of v1's, and the gap (0.024) is bigger than either spread. That's a consistent improvement.
- **v0 against v1:** v0's better repeat (0.718) equals v1's worse one. v1 is probably better, but this run alone doesn't show it clearly.
- **One question drags every version down:** `ts-09` ("Write me a short poem about my cat.") scored 0.09 for v0, v1 and v2 in every repeat. All three still write the poem instead of staying in lane, which costs each version about 0.07. That matches the 5.7 finding that candidate_3 has no explicit rule for off-topic requests.

**Dev scoreboard (attempt 2, `gpt-5.4` at 250):**

| Version | Score | Spread | Tokens | Errored |
|---|---|---|---|---|
| v0 on dev | 0.735 | 0.043 | 188,871 | 0 |
| v1 on dev | **0.807** | 0.029 | 180,878 | 0 |

v1 beats v0 by about 0.07 with fewer tokens. v0 had 1 and 2 rubric **fails** in its two repeats; a fail is a measured answer, not an error, so the batch is valid. v1's 0.807 matches its earlier 0.806 at 150 capacity.

**Interruption:** the Codespace shut down after the retry finished (17:04) and before we continued. Everything we need was already saved in `.lab-state.json` and `.lab-results/`. Notebook 05 reuses the rubric, datasets, evaluation and run IDs, so rerunning its cells from the top picks up the saved results instead of resubmitting.

**5.6 Optimizer:** started `opt_XXXX` at about 17:17 and finished at about 17:30 (last progress line at 768 s), with no errors:

```text
Finished. Best score: 0.8267183333333333 | baseline: 0.8115658333333333
```

The best candidate scored **0.827** against the optimizer's own v1 baseline of **0.812**, a gain of about 0.015. The optimizer measures its baseline itself, so 0.812 differs slightly from our 0.807 in 5.5. Sections 5.10 and 5.11 check whether the gain holds on questions the optimizer never saw.

**5.7 Candidates:** three candidates plus the baseline, all `COMPLETED`:

| Candidate | Score | Average tokens |
|---|---|---|
| candidate_3 | **0.827** | 15,175 |
| baseline (v1) | 0.812 | 16,536 |
| candidate_2 | 0.803 | 16,430 |
| candidate_1 | 0.794 | 14,859 |

Only candidate_3 beat the baseline, and it also used about 8% fewer tokens. Two of three candidates scored *lower* than v1, a good reminder that optimizing doesn't always mean improving.

**Content feedback (notebook 05, section 5.7):** the `rationale` column came back empty for every candidate, so the table has a blank column. Either the service doesn't return a rationale yet, or it lives in another field. Check before the event; if it's always empty, drop the column so learners don't think something failed.

**5.7 What candidate_3 changed:** the instructions grew from four lines to a full prompt, with grounding rules, a recommendation style and a "Do not" list. What stands out:

- **It copied product facts into the prompt.** An "Important domain examples" section lists facts for the TrailLite Daypack, RainGuard and Summit Breeze jackets and the Adventurer Pro Backpack: exactly the products most of the **dev** questions ask about. The facts we checked match the manuals (1.5 lbs, 40 L, 2.5 lbs, waterproof or not). But the test set also asks about tents, the sleeping bag and the stove, which the prompt doesn't mention. This is the overfitting that section 5.11 ("questions the optimizer never saw") is built to catch.
- **Two of our three gaps aren't directly addressed.** There's a general "stay within scope" line but no explicit rule to decline off-topic requests (the hot chocolate recipe), and nothing about questioning a wrong premise (the "EcoFire tent").
- **One fact it adds isn't in the manual:** "no dedicated rain cover included" for the TrailLite Daypack. Its own rules say to mention accessories only when the files support it.

**For facilitators:** this candidate is a strong teaching example. Before 5.10, ask learners: "Which products does this prompt know by heart, and what happens on questions about the others?"

**5.8 Staging:** `Staged trailmate-optimizer-candidate, version 1. The main agent has not been promoted.` v2 is a separate agent (`trailmate-optimizer-candidate`, version 1), so `trailmate` still serves v1. The cell also checked that the staged definition exactly matches candidate_3.

**5.9 Guard case:** the dev set has one guard case (a question the manual answers, where hedging would be wrong). v2 answered it directly and correctly:

```text
[dv-06] How much does the Summit Breeze Jacket weigh?
v2 says: The Summit Breeze Jacket weighs 1 lb according to its technical specs .
Hedge-word check: no listed hedge words; still check the facts
```

This matches the manual (`**Weight**: 1 lb`), so v2 didn't become over-cautious. The stray space before the full stop is where file search's citation marker was removed from the printed text, which is cosmetic.

**5.10 Test set:** all three versions valid, 0 errored:

| Version | Score | Spread | Tokens |
|---|---|---|---|
| v0 on test | 0.692 | 0.052 | 188,830 |
| v1 on test | 0.724 | 0.011 | 197,538 |
| v2 candidate on test | **0.748** | 0.002 | 192,283 |

v2 beats v1 on questions the optimizer never saw, by about 0.024. That's more than its gain on dev (0.015 by the optimizer's measure), so the overfitting we feared in 5.7 didn't show up in the total score. Every test score is lower than its dev score, so the test set is harder. Batches took 2.7 min (v0), 3.8 min (v1) and 3.8 min (v2), about 10.5 min in total.

**5.10 Is the gain real?** `Candidate minus v1: 0.025. Observed repeat spread: 0.011. Worth further review.` Test scores by way of losing trust:

| Way | v0 | v1 | v2 | v1 → v2 |
|---|---|---|---|---|
| Making things up | 0.722 | 0.765 | **0.835** | +0.070 |
| Wrong premise | 0.760 | 0.764 | 0.785 | +0.020 |
| Overclaiming | 0.807 | 0.803 | 0.819 | +0.017 |
| Not useful | 0.804 | 0.770 | 0.781 | +0.011 |
| Wrong product | 0.801 | 0.784 | 0.790 | +0.006 |
| Out of lane | **0.261** | **0.456** | **0.480** | +0.024 |

- **Most of v2's gain is "making things up"** (+0.07), which fits its new grounding rules.
- **Out of lane is the weak spot for every version** (below 0.5, so failing). v2 barely moved it. That's the cat poem (`ts-09`) and similar off-topic requests. The notebook says whatever barely moves "is a different kind of problem" and a clue for module 6.
- Only three versions and two repeats, and each way has just two test questions, so a single answer can swing a row.

**5.11 v2 on dev:** valid, 0 errored. Score **0.834** (repeats 0.826 and 0.842, spread 0.016), in 3.3 min.

```text
v1 to v2 gain on dev (what the optimizer trained on): 0.03
v1 to v2 gain on test (questions it never saw):       0.025
```

The gain held up on unseen questions: 0.025 on test against 0.03 on dev. The optimizer's copied product facts didn't cost it on the test set overall.

**5.12 Promotion decision:** we first ran the cell with `REVIEW_APPROVED = False`, then reran it with `True`. Both gave the same result:

```text
No promotion. We keep v1 at the v2 checkpoint.
Reasons: ['way=overclaiming: quality fell beyond tolerance.', 'way=out_of_lane: quality fell beyond tolerance.']
```

**Why:** promotion needs human approval **and** an automatic quality gate. The gate (`lab.quality_failures`, tolerance **0.0**) blocks if *any* way of losing trust scores lower than v1, on dev or on test. On test every way improved, but on dev two dropped slightly:

| Way (dev) | v1 | v2 | Change |
|---|---|---|---|
| Wrong product | 0.752 | 0.861 | +0.109 |
| Wrong premise | 0.781 | 0.856 | +0.075 |
| Not useful | 0.796 | 0.807 | +0.011 |
| Making things up | 0.831 | 0.836 | +0.006 |
| Out of lane | 0.854 | 0.844 | **−0.010** |
| Overclaiming | 0.829 | 0.799 | **−0.030** |

The overclaiming drop comes from `dv-04` ("Is the TrailLite Daypack waterproof?", 0.85 → 0.79), one of the products whose facts the optimizer copied into its prompt. Both drops are about the size of the repeat spread (0.016 to 0.029), so they may be noise, but a zero tolerance treats any drop as a regression.

**Result:** v1 stays the baseline. The notebook saved v1 (Foundry version 2) as the "v2 checkpoint" that notebook 06 builds on. That's a valid outcome: the lab says keeping the baseline is useful when a candidate doesn't earn its place.

**Content feedback (notebook 05, section 5.12):**

- When the gate fails, setting `REVIEW_APPROVED = True` changes nothing, but the output doesn't say so. Learners will think they set it wrong. Suggest printing "Blocked by the quality gate; human approval can't override it" when there are gate failures.
- A zero tolerance with two repeats blocks drops smaller than the measured noise. Consider a predeclared tolerance (notebook 06 already uses `TOLERANCE` for routers), or only flagging drops larger than the spread. Either is a teaching choice for the content owners.
- **Mixed rounding in 5.11:** the dev gain prints at 2 decimals (`round(..., 2)` gives 0.03) and the test gain at 3 (0.025). The real dev gain is 0.027, so the two are almost equal, and "the trusted gain is smaller" is mostly a rounding effect. Print both with `.3f`.
- **A hidden reason in 5.12:** the dev gain (0.027) is smaller than v1's dev spread (0.029), so the "gain beyond spread on both sets" rule also fails. The cell prints only the category failures, because the noise reason is the fallback in `checks or [...]`. List every failed condition.
- **A missing aha:** this run's clearest lesson is "a better average can hide a worse category". v2 improved overall on dev and test, but slipped on overclaiming and out of lane on dev, and the gate caught it. Add it to "We also took away".

**Why v0 was invalid:** the evidence file (`.lab-results/XXXX.json`) shows both errored questions (`dv-01` shoe uppers, `dv-09` sushi) failed at the judging step with:

```text
Error code: 429 - Your requests to gpt-5.4 for gpt-5.4 in swedencentral have exceeded token rate limit.
```

See the troubleshooting log.

**Is notebook 05's aha right?** Mostly. Its main claim (the gain on unseen questions is the one we can trust, and it's usually smaller) is sound, but this run doesn't show it clearly. The dev and test gains were about the same (0.027 against 0.025); the printed 0.03 is a rounding effect. The run's clearer lessons were "a better average can hide a worse category" and "a dev gain inside the noise isn't a win". The aha's other points (optimizer as proposer, held-out data, noise, measure-inspect-promote) all held. See the content feedback above.

**Result:** notebook 05 completed as the learner. Rubric generation, five valid evaluation batches, the optimizer and candidate staging all worked without the project's role assignments. v2 improved on dev (+0.027) and test (+0.025), but wasn't promoted: the quality gate found small dev drops in two categories, and the dev gain was within noise. v1 (Foundry version 2) stays the baseline for notebook 06. Total time about 80 min, including the 150-capacity failure and fix (about 25 min) and the Codespace shutdown (9 min).

#### Step 15: Run notebook 06 (make it optimal)

We opened `labs/core/06-make-it-optimal.ipynb`. The default path (`RUN_ALL_EDITIONS = False`) evaluates one router edition (`mr-default`) on dev, then the selected edition on test.

**What happened:**

| Section | What we saw |
|---|---|
| 6.1 | Loaded the retained baseline (v1, Foundry version 2) and re-recorded the deployment settings with no change. `Editions: ['mr-default'] | quality tolerance: 0.05` |
| 6.2 | Dev difficulty mix: 5 easy, 5 medium, 2 hard |
| 6.3 | `mr-default` sent both the easy and the hard sample question to `gpt-5.6-luna` |
| 6.4 | `Staged trailmate-mr-default-candidate, version 1; the main agent is unchanged.` |
| 6.5 | **INVALID.** Both repeats: 8 passed, 1 failed, **3 errored** with `TARGET_INVOCATION_FAILED ... 500 server_error`. The questions it did answer were served by `gpt-5.6-luna`, `gpt-5.6-terra` and `gpt-6-sol` |
| 6.6 | Shows the three unscored questions and the judge's reasons for the rest |
| 6.7 | `mr-default ['Incomplete evaluation coverage.']` and `No candidate passed the dev quality checks. We keep the baseline.` The test evaluation didn't run, because nothing was selected |

The same three questions failed in both repeats:

| ID | Way | Question |
|---|---|---|
| `dv-07` | Wrong premise | What size laptop fits in the Adventurer Pro Backpack's laptop compartment? |
| `dv-09` | Out of lane | What's the best sushi restaurant near Seattle? |
| `dv-11` | Not useful | I'm hiking in heavy rain tomorrow. Should I buy the Summit Breeze Jacket…? |

**`REVIEW_APPROVED`:** left at `False`. With no valid candidate, approval has nothing to approve; it's a second check after the quality gates, not an override.

**6.8–6.12:**

| Section | What we saw |
|---|---|
| 6.8 | `Nothing earned promotion. The retained baseline stays in place.` |
| 6.9 The whole climb (test scores by way) | See the table below |
| 6.12 Savings (the aha) | `No complete selected-candidate test result; there is no comparable gap to show.` |

| Way (test) | v0 | v1 | v2 checkpoint | v3 checkpoint |
|---|---|---|---|---|
| Wrong product | 0.80 | 0.78 | 0.78 | 0.78 |
| Overclaiming | 0.81 | 0.80 | 0.80 | 0.80 |
| Making things up | 0.72 | 0.77 | 0.77 | 0.77 |
| Wrong premise | 0.76 | 0.76 | 0.76 | 0.76 |
| Out of lane | **0.26** | **0.46** | **0.46** | **0.46** |
| Not useful | 0.80 | 0.77 | 0.77 | 0.77 |

The v2 and v3 checkpoints are both v1, because neither candidate was promoted, so the climb stops at v1. The one clear step up is v0 → v1, on "making things up" and "out of lane". Out of lane is still failing.

**Result:** notebook 06 completed as the learner. Staging a router candidate worked; its evaluation hit the known router-plus-file-search HTTP 500, and every gate kept the baseline as designed. Took about 10 min (one dev batch, no test batch).

**Content feedback (notebook 06):**

- **The climb table repeats v1 three times when nothing is promoted.** Columns labelled "v2 checkpoint" and "v3 checkpoint" with identical numbers look like a bug. Label them "kept v1", or hide repeated columns.
- **The 6.12 aha has nothing to show** when the router batch is incomplete. Until the router issue is fixed, most learners will see this ending. Add a short "if your router run was incomplete" paragraph explaining why keeping the baseline is the correct result.

## Phase one summary

**Verdict:** the Skillable subscription has everything LAB663 needs. Signed in as the Skillable learner, we deployed the lab, created the agent and ran every core notebook plus the bonus notebook. The learner account can't assign roles, and nothing we ran needed the project's role assignments.

| Area | Result |
|---|---|
| Subscription and roles | **LOD Contributor**, **Foundry User** and **Cognitive Services Contributor**. Enough for everything except role assignments |
| Region and models | `swedencentral` has all six deployments; `eastus` and `eastus2` also checked |
| Capacity | `gpt-5.4` needs **250**. At 150, evaluations hit 429 rate limits |
| Notebooks 00–04 | Clean, including traces and insights |
| Notebook 05 | Rubric, five evaluation batches, optimizer and staging all worked. v2 improved but the quality gate kept v1 |
| Notebook 06 | Known router-plus-file-search HTTP 500 on three questions; baseline kept as designed |
| Time | 15:54 to 18:05, about 2 h 10 min, including troubleshooting, a 9-minute shutdown and writing this log. Module 05 alone needs much more than its 14-minute plan (see follow-ups) |

**Before the event:** raise the router issue with the Foundry team, settle the notebook 05 timing changes, and agree the Skillable template settings (see phase two).

## Phase two: validate the pre-provisioned VM

_Not started._ Plan: Skillable deploys [lab663-skillable.bicep](./lab663-skillable.bicep) at lab launch as Owner, so the role assignments are created. The learner signs in, runs [setenv.sh](./setenv.sh), creates the v0 agent with `src/agent/01_build_agent.py`, then follows the notebooks.

**To agree with Skillable:**

- Their deploying identity must be able to assign roles, or they set `assignRoles=false`. Phase one shows the lab works without the project roles so far; we still need to confirm notebooks 05–06.
- Region and capacities: the template defaults to `swedencentral` and 250/150/150. **Each learner gets their own subscription** (confirmed with Skillable), so quota isn't shared between learners: each instance has its own 10,000-unit limit per model. That leaves room to raise `frontierCapacity` well above 250 if we run evaluations in parallel (see the timing follow-up).
- Teardown should purge the deleted Foundry resource, or it keeps holding model quota.
- `principalId` (learner object ID) is optional. The learner already has **Foundry User** across the subscription, so we leave it empty unless Skillable can supply it.

## Follow-ups after the first full run

We'll try these only after one complete run, so they don't change what we're testing.

### New bonus notebook: optimize instructions and model

- **What:** [optimize-more-than-instructions.ipynb](../../labs/bonus/optimize-more-than-instructions.ipynb) runs the agent optimizer with `target_attributes=["instructions", "model"]` and `model_search_space=["gpt-5.4-mini", "mr-default"]` (`max_candidates=3`). It shows each candidate's changes, stages the best as a separate agent, scores it on `test` against the retained baseline, and never promotes it.
- **Why not tools:** in SDK 2.8.0, `tools` only rewrites **function** tool descriptions. TrailMate only has file search, so there's nothing to rewrite. The notebook explains this as part of the lesson.
- **Checked so far:** setup, the attribute check and the optimizer **estimate** ran against `LAB663`, so the service accepted the two-lever settings. Typical estimate: about 62 agent and 62 judge calls, $1.46 (up to $4.88).
- **Still to test:** a full run. Watch for a router candidate failing with the known HTTP 500, and time it.

### Fit notebook 05 into the 60-minute budget

- **What we measured:** notebook 00 plans 14 min for module 05, but its service jobs alone took about 34 min. Each evaluation batch (two repeats in parallel) took 2.5–4 min at 250 capacity: rubric 1 min, dev v0 and v1 6.5 min, optimizer 13 min, test v0, v1 and v2 about 10 min, v2 on dev about 3 min. They run one after another.
- **Options, biggest saving first:**
  1. Start the optimizer right after the rubric exists (5.2). It doesn't need the 5.5 scores, so dev scoring and reading run inside its 13 minutes. About 10 min saved.
  2. Submit every version's evaluation runs together instead of one version at a time. About 5–7 min saved. Needs more `gpt-5.4` capacity, or a separate judge deployment so the agent and judge don't share one rate limit. Each learner has their own subscription, so raising capacity uses no shared quota.
  3. Drop v0 on test (5.10) and v2 on dev (5.11, use the optimizer's own candidate score instead). Five batches become three. About 6 min saved.
  4. Retry a batch once, automatically, when it fails only on 429 rate limits (as a new full `attempt`).
  5. Measure `max_candidates=2` for the optimizer (currently 3).
- **Not recommended:** fewer questions (never shrink the measuring stick) or a single repeat (repeats already run in parallel, so it saves tokens, not time).
- **Estimate with options 1, 3 and 4:** module 05 about 20 min, whole lab about 60 min. Not measured yet; needs a timed rehearsal.

### Revert test-only notebook edits

- **Notebook 05, section 5.5:** we commented out the original `baseline = [...]` block and added `attempt=2` to retry after the rate-limit failure. Restore the original cell (no `attempt` argument) and clear outputs before committing.
- **Notebook 04, section 4.9:** our `our_gaps` list replaced the three "Replace me" placeholders. Restore the placeholders.

### Smaller product photos

- **What we noticed:** the ten photos in `data/images/` are 1024×1024 PNGs of about 3.16 MB each (about 30 MB in total). That's the size of uncompressed pixels, so the files aren't compressed at all.
- **Why it matters:** notebook 03 sends each photo inside the request as base64 text, so every photo adds about 4 MB to the request. Smaller files would also be easier to show inline in the notebooks.
- **What to try:**
  1. **Recompress as PNG without losing anything** (for example `optipng` or Pillow with `optimize=True`). Same pixels, much smaller files, and no code changes.
  2. **Convert to WebP**, lossless or high quality. The models accept WebP, but notebook 03 hard-codes `.png` file names and `data:image/png`. It would need those changed, plus `data/PROVENANCE.md`.
- **How we'll check:** rerun notebook 03 and compare the photo guesses with this run (step 11). Guesses already vary from run to run, so we look for no clear change rather than identical answers.

### Backpack manual contradicts itself about the rain cover

- **What we noticed:** in notebook 04 (step 12), v1 called the Adventurer Pro Backpack's rain cover "unclear/inconsistent". It's right: `data/manuals/product_info_2.md` says "Rain cover included" in the features (line 20) and "**Rain Cover**: No" in the specs (line 45).
- **Why it matters:** two questions assume there's no rain cover: `pr-04` (practice) and `ts-08` (test). An answer that points out the contradiction could be scored as wrong, which would add noise to the test-set score.
- **What to do:** this is already known. The bonus challenge "Manual detective" uses this contradiction on purpose and says to record it for the next dataset version, not to edit the data mid-comparison. For the content owners: decide whether `ts-08` (test set) should keep relying on this manual before the next dataset version. Don't change it during this run, since the eval set is our frozen measuring stick.

## Troubleshooting log

_We record every problem here: what we saw, the cause and the fix. Each entry notes whether the Skillable instructions need to change._

### `NameError: name 'lab' is not defined` in notebook 00 (phase one, step 8)

- **What we saw:** `NameError` on the first code cell we ran (section 0.2).
- **Cause:** we skipped ahead with the **Outline** view, so the import cell under 0.1 never ran. Every notebook starts with a cell that imports `lab`.
- **Fix:** run the cells one at a time, in order from the top. We don't recommend **Run All** (see step 8).
- **Instructions change:** yes, a one-line tip: "Run cells one at a time from the top. If you jump ahead and see `NameError`, run the first code cell."

### Evaluation rate-limited at 150 capacity (phase one, step 14)

- **What we saw:** `INVALID v0 on dev`. One of two repeats had 2 errored questions, each with `429 ... exceeded token rate limit` for `gpt-5.4` in `swedencentral`.
- **Cause:** we deployed at **150** capacity per deployment instead of the lab's default **250**. `gpt-5.4` runs the agent *and* the judge, and both repeats run at the same time. Each agent answer with file search uses about 5,000 to 18,000 input tokens, so two parallel batches plus judging went over 150,000 tokens per minute.
- **Why we can't just raise capacity now:** notebook 01 saved the deployment settings, including capacity. `lab.record_deployment_configuration()` in notebook 06 stops with "Deployed model settings changed during the experiment" if they've changed.
- **It's intermittent:** v1 ran the same load straight afterwards and finished with 0 errors.
- **Confirmed:** after the fix, both versions came back valid with 0 errors, and evaluations ran faster (v0 4 min, v1 2.5 min, compared with 5.5 min each at 150).
- **Fix:** we raised the `gpt-5.4` deployment to **250** by hand and left the other five at 150:

  ```bash
  source .env
  az cognitiveservices account deployment create -g "$AZURE_RESOURCE_GROUP" -n "$AZURE_AI_ACCOUNT_NAME" \
    --deployment-name gpt-5.4 --model-name gpt-5.4 --model-version 2026-03-05 --model-format OpenAI \
    --sku-name GlobalStandard --sku-capacity 250
  ```

  `test-deploy.sh` and `lab663-skillable.bicep` now do the same: `gpt-5.4` gets 250 (`LAB663_FRONTIER_CAPACITY` / `frontierCapacity`), `gpt-5.4-mini` and each router 150 (`LAB663_SMALL_CAPACITY`, `LAB663_ROUTER_CAPACITY`). A what-if check confirmed rerunning it keeps these values.
- **Follow-on:** the capacity changed after notebook 01 recorded it, so we re-record the deployment settings and remeasure v0 and v1 at the new capacity.
- **Instructions change:** yes. Skillable should deploy at least the default **250** for `gpt-5.4`, and we should confirm 250 is enough with several learners sharing quota.

### Router edition fails with HTTP 500 on three questions (phase one, step 15)

- **What we saw:** `INVALID v3 candidate mr-default on dev`. Both repeats had the same 3 errored questions (`dv-07` laptop compartment, `dv-09` sushi, `dv-11` heavy-rain jacket), each `TARGET_INVOCATION_FAILED ... Error code: 500 - The server had an error while processing your request.`
- **Cause:** a known service issue, not our setup. `docs/narrative.md` ("What the isolated rehearsal tells us") found the same failure on `dv-07` and `dv-11` in a separate tenant. Direct calls with `mr-default` **and** `file_search` returned HTTP 500; the same questions worked without the search tool, or with `gpt-5.4` and the search tool. It's the router plus file-search path. This isn't a rate limit: it's deterministic across repeats and the error is 500, not 429. `dv-09` is a new failing question in this run.
- **Fix:** none on our side. The notebook handled it correctly: no score or cost from an incomplete batch, the baseline kept, and the test set left untouched. Removing file search would hide the problem and lose grounding (the rehearsal notes show an ungrounded answer inventing a 15.6-inch laptop size). Rerunning with `attempt=2` would almost certainly fail the same way.
- **Request IDs** for service investigation are in the evidence file (`.lab-results/XXXX.json`, `v3 candidate mr-default on dev`).
- **Instructions change:** yes, until the service is fixed. Tell learners that notebook 06 may end with "Incomplete evaluation coverage" for the router and that keeping the baseline is the expected outcome. Raise it with the Foundry router team before the event.
