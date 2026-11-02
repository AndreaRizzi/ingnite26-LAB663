<!-- sync: source=labs/core/00-set-the-stage.ipynb sections=0.1,0.3,0.4,0.5,0.7,0.8 -->

# Module 0: Get ready

**Notebook:** [00-set-the-stage.ipynb](../../../labs/core/00-set-the-stage.ipynb) · **Time:** deployment happens before the clock starts, then about 5 minutes of reading

**The question:** what are we building, and how will we know it got better?

We build our environment once, check that GitHub Copilot answers, then read the story behind the lab. Nothing here is timed.

---

## Step 1: Open the repository

Open this repository in a GitHub Codespace, or in VS Code with **Dev Containers: Reopen in Container**. The container brings Python, the Azure CLI and Bicep, and prepares the root `.venv`.

**Expected:** container setup finishes and reports a Bicep version.

If setup stops with `az bicep is not available`, rebuild the container with **Codespaces: Rebuild Container** or **Dev Containers: Rebuild Container**.

## Step 2: Check GitHub Copilot

Open Copilot Chat and ask it to explain a Python list comprehension.

**Expected:** Copilot answers without a missing-license or access-denied message. Our GitHub sign-in and our Azure sign-in are separate, so a working deployment doesn't prove Copilot works.

<!-- TODO(screenshot): m0-copilot-answer.webp | Copilot Chat answering the list comprehension question | crop to the chat panel; hide the account name -->

## Step 3: Deploy

From the repository root, run:

```bash
bash infra/deploy.sh
```

It asks for a subscription, a region (`eastus` by default, or `westus`) and the chat models. Then it builds a Foundry project in a fresh `rg-lab663-NNNN` resource group, the model and router deployments, tracing, our access, a `.env` file and our first agent, **TrailMate v0**. Details are in [infra/README.md](../../../infra/README.md).

**Expected:** the script ends with `TrailMate v0 is ready.`

<!-- TODO(screenshot): m0-deploy-done.webp | last lines of bash infra/deploy.sh ending with "TrailMate v0 is ready." | crop out subscription, tenant, resource names and endpoints -->

> [!IMPORTANT]
> `deploy.sh` creates a new resource group every time it runs, even with `--skip-agent`. If the infrastructure succeeded and only agent setup failed, rerun just `.venv/bin/python src/agent/01_build_agent.py`. Keep the existing `.env` and `.lab-state.json`.

<details>
<summary>On a prepared Windows checkout instead of the dev container</summary>

Create the environment before deploying:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe .\src\check_environment.py --register-kernel
```

**Expected:** the environment check passes and **Python (LAB663)** is registered. A failed check stops before any Azure resource is created.

</details>

## Step 4: Open notebook 00 and pick the kernel

Open [00-set-the-stage.ipynb](../../../labs/core/00-set-the-stage.ipynb). Choose **Select Kernel** in the top-right corner and pick the starred **.venv** entry marked **Recommended**.

<!-- TODO(screenshot): m0-select-kernel.webp | Select Kernel > Python Environments list with .venv marked Recommended | crop to the picker -->

**Expected:** the top-right corner shows **.venv (Python 3.13.x)**.

<!-- TODO(screenshot): m0-notebook-ready.webp | notebook toolbar showing .venv (Python 3.13.x) as the kernel | crop to the top-right toolbar -->

Run one cell at a time with **Shift+Enter**, and keep the **Outline** view open. The numbered sections tell the story.

## Step 5: Read the story

Work through the notebook. Slow down on these sections:

| Section | What to take away |
|---|---|
| 0.1 | TrailMate answers from ten product manuals and must never make things up |
| 0.3 | The six ways an agent loses a customer's trust. Every score maps back to them |
| 0.4 | Three question sets: practice, dev and test. **Expected:** a table with six rows and three columns, two cases in every cell |
| 0.5 | The climb: insights, a rubric, the optimizer and the router, one lever at a time |
| 0.7 | A quick readiness check. **Expected:** it finds the `.env` file that `deploy.sh` wrote |

## The aha (section 0.8)

> We aren't here to build a better agent. We're here to build a **repeatable way to prove an agent got better.**

## Checkpoint

- [ ] Copilot answers in Copilot Chat
- [ ] `deploy.sh` ended with `TrailMate v0 is ready.`
- [ ] Notebook 00 runs on the `.venv` kernel and section 0.7 finds `.env`

**Next:** [Module 1: Set up and validate](01-setup-and-validate.md)
