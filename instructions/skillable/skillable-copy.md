<!--
  LAB663 Skillable instructions (full text). GENERATED - do not edit by hand.
  Regenerate with: bash instructions/skillable/scripts/generate-skillable-copy.sh

  Paste this file into Edit Instructions. Images load from the public repo.

  Source pages: nitya/ignite26-LAB663 instructions/skillable/NN-stage-NN.md
  Published to: nitya/skillable-labs (branch ignite26-lab663, folder ignite26-lab663/v1)
  To target a different location: PUBLISH_REPO=<owner/name> PUBLISH_BRANCH=<branch> PUBLISH_PATH=<folder>
-->

@lab.Title

# 0.1 Welcome and sign in

**What we'll do:** Find out what this lab is about, then sign in to the virtual machine, GitHub, the Foundry portal, and the Azure portal, all with the lab credentials.

## About this lab

**Build smarter AI systems with model router and agent optimizer.** Getting a first agent working is the easy part. Keeping it accurate and affordable as real questions come in is harder. This lab is about that second part.

**The scenario.** TrailMate is a support agent for an outdoor-gear store. It answers customer questions from the store's product manuals. It works, but it sometimes overstates what a product can do, it answers questions that aren't its job, and it sends every question to the same model, whether the question is easy or hard.

**What we'll learn.** We improve TrailMate one change at a time and measure each change in Microsoft Foundry:

| Tool | What it does for us |
|:-----|:--------------------|
| Traces, evaluations, and insights | Show what the agent did and where it went wrong |
| A rubric evaluator | Scores answers against our own definition of a good TrailMate answer |
| Agent optimizer | Rewrites the agent's instructions and scores each candidate with our rubric |
| Model router | Picks a model for each question, so easy questions can use a cheaper model |

**How we apply it.** The same loop works for any agent we build: measure where we are, change one thing, compare the result, and keep the change only when the evidence says it helped. For the business, that means quality and cost we can show, not guess. For engineering, it means every change is small, measured, and easy to undo.

---

## Sign in to the virtual machine

1. [] Check that you see the **Instructions** and **Resources** tabs on the right, and the virtual machine's sign-in screen on the left. The blue bar at the bottom right shows the time left in the lab.

    ![Lab interface with the Instructions and Resources tabs and the VM sign-in screen](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/00-start-01-lab-tabs.png)

1. [] Click in the password field on the virtual machine, then click the password below to type it in.

    +++@lab.VirtualMachine(Win11-Pro-Base).Password+++

1. [] Check that the desktop appears, then tick the boxes for the steps you've done. Ticking boxes tracks our progress.

    ![The VM desktop after sign-in, with the first two steps checked off in the instructions](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/00-start-01-desktop.png)

## Sign in to GitHub

1. [] Open **Microsoft Edge** and go to the GitHub Enterprise sign-in page. Select **Continue**.

    +++https://github.com/enterprises/skillable-events/sso+++

    ![The Single sign-on to Skillable Events page with the Continue button](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/00-start-01-sso-continue.png)

1. [] At the Microsoft sign-in, use these lab credentials, **not** your own account.

    | Credential | Value |
    |:-----------|:------|
    | Username | +++@lab.CloudPortalCredential(User1).Username+++ |
    | TAP | +++@lab.CloudPortalCredential(User1).AccessToken+++ |

    ![The Microsoft Sign in page asking for an email](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/00-start-01-microsoft-signin.png)

1. [] Check that you see the **Skillable Events** enterprise page. Leave this tab open.

    ![The Skillable Events GitHub Enterprise overview page after sign-in](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/00-start-01-github-signed-in.png)

> [+Hint] I see an error instead
>
> The GitHub license may still be registering. Wait a few minutes and try again. If it still fails, raise your hand to ask a proctor for help.

## Sign in to the Foundry portal

1. [] Open a new tab, go to the Foundry portal, and select **Sign in**. It reuses the lab credentials.

    +++https://ai.azure.com+++

    ![The Microsoft Foundry home page with the Sign in button, and tab groups in Edge](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/00-start-01-foundry-signin.png)

    > [!Hint] Edge may already have tab groups such as **GitHub Login**, **Foundry Portal**, and **Azure Portal**. Use them to keep your tabs tidy.

1. [] Check that **All resources** lists one project, **trailmate**. Leave this tab open.

    ![The Foundry portal All resources list showing the trailmate project](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/00-start-01-foundry-trailmate.png)

## Sign in to the Azure portal

1. [] Open a new tab and go to the Azure portal. If it doesn't sign you in, select **Sign in** or refresh the page.

    +++https://portal.azure.com+++

    ![The Azure portal home page after automatic sign-in](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/00-start-01-azure-home.png)

1. [] Select **Resource groups** and check that **LAB663** is the only one listed. Leave this tab open.

    ![Resource groups in the Azure portal listing LAB663](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/00-start-01-azure-resource-groups.png)

---

> [!Note] **Success:** We just signed in to the virtual machine, GitHub, Foundry, and Azure with the lab credentials. Next, we set up our development environment.

===

# 0.2 How this lab works

**What we'll do:** See the climb ahead of us, and learn the small conventions that keep us moving.

## The climb

Building the first agent is easy. Keeping it reliable and cost-effective takes continuous improvement. Today we practise continuous improvement on **TrailMate**, an outdoor-gear support agent. We change one thing at a time and measure each change. Each step that moves us toward our goal is part of the **climb**.

| Stage | Where | What we do | Agent version |
|:------|:------|:-----------|:--------|
| 1 Setup | VS Code | Get ready, check everything works | |
| 2 Meet TrailMate | Foundry portal | Try the starting agent and plan the climb | Version 1 |
| 3 Kick-off | VS Code | Create Version 2 and start the optimizer, so it works while we explore | Version 2 |
| 4 Know the concepts | Foundry portal | Start insights, compare models, try the model router | |
| 5 See it work | Foundry portal | Compare Versions 1 and 2, check the monitor, read the insights | Version 2 |
| 6 Make it better | Foundry portal | Read the optimizer results, promote the winner | Version 3 |
| 7 Keep improving | Foundry portal | Switch to the model router, compare, and score it | Version 4 |
| 8 Wrap | | Look back at the climb | |

## How to use these pages

1. [] Note the page number in each title, like **3.2**. If we get stuck, we raise a hand and say "page 4.3, step 4".
1. [] Text shown +++like this+++ is **type text**: click it to type it into the virtual machine where the cursor is.
1. [] Text shown ++like this++ is **copy text**: click it to copy, then paste it yourself.
1. [] Each step has a checkbox. Checking the last box on a page checks the ones above it.

> [!Hint] **Stuck? Ask Copilot first.** Most pages end with an **OPTIONAL - Ask Copilot** hint: a prompt to paste into Copilot Chat that explains or summarizes what just happened, so we can skip reading long notebook output. Skip these if you're short on time. We set up Copilot Chat in the next stage, on page 1.2.

---

> [!Note] **Success:** We just learned the route of our climb and how to say exactly where we are. Next, we set up our development environment and GitHub Copilot Chat.

===

# 1.1 Set up the local environment

**What we'll do:** Confirm the lab deployed our Azure resources and set up our local `.env` file, open the lab in VS Code, and sign in to Azure.

## Check the environment status

The desktop has two text files: one starting with **LAB663** and one with **lab663**. Double-click each to open it in an editor.

1. [] Open **LAB663-deployment-output.txt**, the deployment summary. Check that it says **Result: SUCCEEDED**.

    ![The deployment summary showing Result: SUCCEEDED and the Foundry project details](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/01-setup-01-status-file.png)

1. [] Open the **lab663-deploy-...** file, the run log. Find the line **Populated .env with the deployment settings**.

    ![The run log with the Populated .env line highlighted](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/01-setup-01-run-log.png)

> [+Hint] It says RUNNING or FAILED
>
> **RUNNING:** the lab is still preparing. Wait a few minutes and open the file again. **FAILED:** don't continue. Raise your hand and share the **Stage** line.

## Open the lab in VS Code

1. [] Open **Visual Studio Code** from the desktop and check that the Explorer shows the **LAB663** folder. If a pop-up offers to install the **Dev Containers** extension, close it. If asked whether you trust the authors, select **Yes**.

    ![VS Code open on the LAB663 folder, with the Dev Containers pop-up at the bottom right](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/01-setup-01-vscode-open.png)

1. [] Open a terminal with **Terminal > New Terminal**, or press **Ctrl+Shift+backtick**. If you don't see the **Terminal** menu, it's under **...** in the menu bar.

## Sign in to Azure

1. [] In the terminal, run this command. It prints a link and a code.

    ++az login --tenant @lab.CloudSubscription.TenantId --use-device-code++

    ![The terminal showing the device login link and code](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/01-setup-01-az-login-code.png)

1. [] Copy the code, then open the link in Edge and paste it. Pick the lab account you used on page 0.1.
1. [] When asked to approve the sign-in, select **Approve**. Then close the browser tab and return to VS Code.

    ![The Approve sign-in on another device page, with the Approve button](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/01-setup-01-az-login-approve.png)

1. [] In the terminal, type **1**, or press **Enter**, to keep the default subscription marked with **\***.

    ![The terminal listing the lab subscription, marked as the default](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/01-setup-01-az-login.png)

---

> [!Note] **Success:** We just confirmed our resources and `.env` are ready, opened the lab, and signed in to Azure.

===

# 1.2 Set up GitHub Copilot Chat

**What we'll do:** Sign in to GitHub Copilot in VS Code, connect it to Foundry, and check it can see our project.

## Sign in to GitHub Copilot

1. [] In VS Code, click the blue **Sign in** button in the top bar, then select **Continue with GitHub**.

    ![The Sign in to use GitHub Copilot dialog with Continue with GitHub](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/01-setup-02-continue-with-github.png)

1. [] In the browser, select **Continue**, then authorize **Visual Studio Code**.
1. [] When the browser offers to open VS Code, select **Open**, or just switch back to VS Code.
1. [] Check that the profile icon at the bottom left shows your GitHub sign-in.

## Get Copilot Chat ready

1. [] In the Copilot Chat window, send just this message and wait for a reply.

    ++Hello++

1. [] In the chat box, switch the model to **Claude Opus 5.5**.
1. [] Switch **Default permissions** to **Allow all**, so Copilot doesn't stop to ask before each tool call. Select **Enable** when asked to confirm.

    ![The permissions menu with Allow all selected](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/01-setup-02-allow-all.png)

## Connect Copilot to Foundry

1. [] Above Copilot's reply, click **Completed 2 steps** to expand it, then click **Start it now?** next to **Foundry MCP**.

    ![The expanded steps with the Start it now link for the Foundry MCP server](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/01-setup-02-start-foundry-mcp.png)

1. [] Select **Allow**, then **Work or school account**.
1. [] Sign in with the lab credentials. Select **Yes** to stay signed in, and wait until the device is confirmed.

    | Credential | Value |
    |:-----------|:------|
    | Username | +++@lab.CloudPortalCredential(User1).Username+++ |
    | TAP | +++@lab.CloudPortalCredential(User1).AccessToken+++ |

## Check Copilot can reach Foundry

1. [] Send this message. It takes up to a minute while Copilot installs anything missing.

    ++/microsoft-foundry List the agents in my Foundry project. Do not change anything.++

1. [] Check that the reply lists the **trailmate** agent.

    ![Copilot Chat listing the trailmate agent in the Foundry project](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/01-setup-02-copilot-agents.png)

> [+Hint] Copilot shows an error
>
> If you see a license or access error, check that you signed in with the lab account, not a personal one. If it persists, raise your hand. The license server can take a few minutes to start.

---

> [!Note] **Success:** We just set up GitHub Copilot Chat. It can explain things and talk to our Foundry project whenever we get stuck.

===

# 1.3 Validate the Azure environment

**What we'll do:** Run one notebook that checks every part of the setup, so any failure points at exactly one fix.

1. [] In the VS Code **Explorer**, open **labs > core** and select **01-setup-and-validate.ipynb**.
1. [] Expand **Outline** at the bottom of the Explorer. It lists the notebook's numbered sections, so we can jump between them.
1. [] Click **Select Kernel** at the top right, then **Python Environments**, and pick **.venv (3.13.14)**. We do this for every notebook we open.

    ![The notebook open with the kernel picker showing .venv (3.13.14) and the Outline listing sections 1.1 to 1.10](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/01-setup-03-select-kernel.png)

1. [] Click **Run All** at the top of the notebook.
1. [] In the Outline, click **1.10 So, is my camp ready?** and wait there until it prints **Overall: PASS. Our camp is ready.** This takes a minute or two.

    ![Section 1.10 showing 27 of 27 checks passed and Overall: PASS](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/01-setup-03-scorecard.png)

> [!Knowledge] The "Error we expected" line in section 1.11 is there on purpose. It shows what a failure looks like.

> [+Hint] A check failed
>
> New role assignments can take up to 10 minutes. Wait, then rerun the failed cell. To understand the error, paste this into Copilot Chat with the message:
>
> ++In notebook 01, this check failed with the message below. What does it mean, and what should I try? Don't change any files.++

> [+Hint] OPTIONAL - Ask Copilot: what did we check?
>
> ++Summarize what labs/core/01-setup-and-validate.ipynb checked, in three bullets. Don't change any files.++

---

> [!Note] **Success:** We just proved our project, models, router editions, agent, and tracing all work under our lab account.

===

# 2.1 Meet TrailMate

**What we'll do:** Meet the agent we'll improve today. TrailMate is already deployed in Foundry. Let's see what it's made of.

1. [] In Edge, switch to the **Foundry portal** tab. Under **All resources**, select **trailmate** to open the project.
1. [] In the left menu, select **Agents**. You see one agent, also called **trailmate**.

    ![The Agents list in the Foundry portal showing the trailmate agent at version 1](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/02-meet-01-agents-list.png)

1. [] Select **trailmate** to open its playground, then look at the left side:
    - **Version 1** is selected. That's the agent version deployed in Foundry, the baseline for our climb. Each change we make creates a new version.
    - The **Model** is **gpt-5.4**, a large frontier model.
    - The **Instructions** are just one line: "You are a helpful agent."
    - **File search** under **Tools** lets it search ten product manuals.

1. [] To make room for the chat, collapse the left menu with the button at its bottom left, highlighted in red. If a **Create toolbox** banner appears under **Tools**, close it with its **X**. We won't use it.

    ![The trailmate playground with Version 1 selected, the model, the one-line instructions, the file search tool, and the collapse-menu button highlighted](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/02-meet-01-version-1.png)

1. [] Open **Metrics** at the top right of the chat and turn on the evaluators you want. The playground now scores every answer for us.

    ![The Metrics menu with evaluators such as Intent resolution, Coherence, and Relevance](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/02-meet-01-metrics.png)

> [+Hint] OPTIONAL - Ask Copilot: what is this agent?
>
> ++What is a prompt agent in Microsoft Foundry, and what does its file search tool do? Answer in two sentences.++

---

> [!Note] **Success:** We just met TrailMate Version 1: one model, one tool, and one line of instructions, with live evaluation turned on.

===

# 2.2 Test-drive TrailMate

**What we'll do:** Ask Version 1 two questions, then look behind an answer at its sources, its scores, and its trace.

## Ask two questions

> [!Note] Agents are non-deterministic, so your answers, times, and scores may differ from the screenshots on these pages.

1. [] In **Message the agent**, ask a question about the manuals.

    ++Which tent sleeps 8 people, the TrailMaster X4 or the Alpine Explorer?++

1. [] Look under the answer. The numbered **citations** show the manual files it used, so the answer is grounded in our data. The row below shows the model, time, tokens, tools used, and evaluation scores.

    ![TrailMate's answer about the tents, with citations to product files and a row showing time, tokens, AI Quality, and Safety](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/02-meet-02-tent-answer.png)

1. [] Click a citation to read the manual passage behind it, then close it.
1. [] Start a new chat with the **+** icon at the top right of the chat, so the next question doesn't carry over the first one. Then ask something a gear-support agent shouldn't answer.

    ++Give me a recipe for hot chocolate I can drink while wrapped in my CozyNights Sleeping Bag.++

    ![TrailMate Version 1 answering the hot chocolate request with a full recipe](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/02-meet-02-off-topic.png)

1. [] Scroll to the end of the answer. It even adds a safety tip, citing the manual's warning to keep the bag away from open flames. Grounded, but it still answered a question that isn't TrailMate's job.

## Look behind an answer

1. [] Hover over **AI Quality** in the row under the answer. Every built-in evaluator passed the recipe.

    ![The hover card for AI Quality showing Coherence, Fluency, Relevance, and Task adherence all Pass](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/02-meet-02-quick-scores.png)

1. [] Select **AI Quality** to open the details. On the left, see each step with its time and tokens. On the right, read why each evaluator passed it.

    ![The details for the hot chocolate answer, with the file_search and message steps and evaluator reasons](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/02-meet-02-evaluations.png)

1. [] Close the details. Select **Traces**, then **User view**. Open the **Span tree** with its toggle on the left, then select **Play** at the bottom. It replays what the user saw next to the calls the agent made.

    ![The trace user view with the span tree, the agent response, and the replay bar](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/02-meet-02-trace.png)

> [!Knowledge] A **trace** is the step-by-step record of one answer. Its **tokens** tell us what the answer cost, and its **duration** how long it took. The built-in evaluators judge general quality, so a well-written recipe passes. They don't know TrailMate's job. In stage 6 we build our own rubric that does.

> [+Hint] OPTIONAL - Ask Copilot: what are traces?
>
> ++What are agent traces in Microsoft Foundry? Explain in one sentence.++

---

> [!Note] **Success:** We just saw that Version 1 answers with citations, gets scored live, and leaves a trace. We also saw that "it answers" isn't the same as "it's reliable".

===

# 2.3 Plan the climb

**What we'll do:** Decide what "better" means for TrailMate, see how we'll improve it one change at a time, and why we start the slowest step first.

## 2.3.1 What can we improve?

On page 2.2, every answer came with three kinds of numbers. These are the dials we'll turn:

| Dial | What we saw on 2.2 | Why it matters | How we improve it |
|:-----|:-------------------|:---------------|:------------------|
| **Quality** | AI Quality and Safety scores | Wrong or off-topic answers lose customers | Better instructions (Versions 2 and 3) |
| **Cost** | Tokens per answer | Every token is billed, on every question | A routed model (Version 4) |
| **Latency** | Seconds per answer | Slow answers frustrate customers | A faster model where it's good enough (Version 4) |

Foundry's observability features keep these numbers visible as we climb:

- **Evaluations** score answers for quality, live in the playground or on a whole question set.
- **Traces** record each step of an answer, with its tokens and duration.
- **Insights** read many traces at once and point to the biggest problems.
- **Monitor** tracks runs, tokens, and failures over time.

1. [] Read the two lists. Quality, cost, and latency often pull against each other, so we measure all three every time we change something.

---

## 2.3.2 One lever at a time

Continuous improvement means we keep measuring and keep changing one thing at a time. Each change becomes a new **agent version** in Foundry, and the **climb** is the trend toward our goal across those versions.

| Agent version | What changes | Where we make it |
|:--------------|:-------------|:-----------------|
| **Version 1** | Nothing, it's our starting point | Already deployed |
| **Version 2** | Better instructions, written by hand | Notebook 04 |
| **Version 3** | Instructions rewritten by the **agent optimizer** | Notebook 05, promoted in the portal |
| **Version 4** | The model, swapped for a **model router** | The portal playground |

1. [] Read the table. Each version changes one lever, so we always know what moved the score.

---

## 2.3.3 Why we start the optimizer now

> [!Knowledge] The **agent optimizer** rewrites an agent's instructions, tries several versions, and scores each one with an AI judge on our test questions. It's thorough, so it takes a while, often longer than any other step in this lab.

1. [] Next, on pages 3.1 and 3.2, we create Version 2 and start the optimizer. Then, while it works, we explore the concepts behind the climb in the portal, and come back to its results on page 6.1.

> [+Hint] OPTIONAL - Ask Copilot: what is the agent optimizer?
>
> ++What does the Microsoft Foundry agent optimizer do? Explain in one sentence.++

---

> [!Note] **Success:** We just named the three dials we'll improve, the Foundry features that track them, and the climb from Version 1 to Version 4.

===

# 3.1 Create Version 2

**What we'll do:** Change one lever, the instructions, to create TrailMate agent **Version 2**, then ask it 12 practice questions so it leaves traces for Foundry to analyze. The optimizer on the next page learns from these.

1. [] Close the Copilot Chat pane to make room for the notebook: click the **chat icon** in the top bar, next to the search box. Click it again any time to reopen the chat.
1. [] In the Explorer, open **labs > core > 04-make-it-work.ipynb**.
1. [] Select the **.venv (3.13.14)** kernel, the same way as on page 1.3.
1. [] In the **Outline**, click **4.8 What does Foundry think is wrong?**, then click the first code cell below that heading.
1. [] Hover over that cell and click the **Execute Above Cells** icon in its toolbar. This runs sections 4.1 to 4.7 in order and stops before 4.8.

    ![The first section 4.8 code cell with the Execute Above Cells icon highlighted in its toolbar](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/03-kickoff-01-execute-above.png)

1. [] Use the Outline to follow along. The first cell prints **Connected. 12 practice questions ready.**, and section **4.4** prints **Saved. TrailMate v1 is Foundry version 2**. The notebook calls it v1; in the portal it's **Version 2**.

    ![The first cell printing Connected. 12 practice questions ready.](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/03-kickoff-01-connected.png)

1. [] This is the moment **trailmate** moves to agent **Version 2**. Switch to the Foundry portal tab and refresh the page (**F5**) so it loads the new version. Then open the **Version** menu at the top of the trailmate playground. **Version 2** is now **Active**, and Version 1, our baseline, is still listed below it.

    ![The trailmate Version menu with Version 2 active above Version 1](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/03-kickoff-01-version-2.png)

1. [] Wait for section **4.7** to count down. It pauses one minute so the traces can arrive. The whole run takes a couple of minutes.

    ![Section 4.7 counting down Waiting for traces](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/03-kickoff-01-waiting.png)

1. [] While it waits, switch to the Foundry portal. Expand the left menu with its toggle at the bottom left, then select **Traces**. The 12 practice conversations appear one by one, each with its duration and tokens.

    ![The Foundry Traces list filling with trailmate traces, with duration and tokens](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/03-kickoff-01-portal-traces.png)

> [+Hint] OPTIONAL - Ask Copilot: what just ran?
>
> ++Summarize what sections 4.1 to 4.7 of labs/core/04-make-it-work.ipynb did, in three bullets. Don't change any files.++

---

> [!Note] **Success:** We just finished **Make it work** (notebook 04): agent Version 2 is created, and Foundry has 12 conversations' worth of traces to learn from.

===

# 3.2 Start the optimizer

**What we'll do:** Give Foundry a starting gap list, build a rubric from it, and start the **agent optimizer** so it can improve **Version 2** while we explore.

## Save a starting gap list

1. [] In **04-make-it-work.ipynb**, jump to section **4.9** and find the code cell that starts with `our_gaps = [`.
1. [] Replace the three `"Replace me..."` lines so the list matches the one below. Copy it with the button on the code block.

    ```python
    our_gaps = [
        "Overclaiming: may call the Summit Breeze Jacket waterproof when the manual says water-resistant",
        "Making things up: may give an exact per-shoe weight for the TrailWalker Hiking Shoes when the manual gives none",
        "Out of lane: may answer off-topic requests, like a hot chocolate recipe, instead of redirecting to our products",
    ]
    ```

1. [] Run the cell and confirm it prints the three gaps.

    ![The section 4.9 cell with our three gaps and its output listing them](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/03-kickoff-02-gaps-saved.png)

> [!Knowledge] These are risks we expect, written ahead of time so the optimizer can start early. On page 5.3 we'll check them against what Foundry actually finds.

## Start the optimizer

Notebook 04 was **Make it work**: we got Version 2 running and leaving traces. Notebook 05 is **Make it better**: we let the optimizer improve Version 2's instructions.

> [!Knowledge] We're starting the optimizer now because it takes a while, often longer than any other step in this lab. It keeps running in Foundry on its own. While it works, we explore the concepts behind the climb in the portal, then come back for its results on page 6.1.

1. [] In the Explorer, open **labs > core > 05-make-it-better.ipynb**.
1. [] Select the **.venv (3.13.14)** kernel, the same way as on page 1.3.
1. [] Run the first code cell. It prints **v0 = Foundry version 1   v1 = Foundry version 2**. The notebooks call Versions 1 and 2 "v0" and "v1".

    ![The first notebook 05 cell printing v0 = Foundry version 1 and v1 = Foundry version 2](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/03-kickoff-02-versions.png)
1. [] Jump to section **5.2** and run its code cell. It drafts a rubric from our traces and gap list, printing **Rubric generation: queued** every 15 seconds. Wait for **Rubric created**, which takes about two minutes.

    ![Section 5.2 printing queued progress lines, then Rubric created: trailmate-rubric version 1](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/03-kickoff-02-rubric-created.png)

1. [] Switch to the Foundry portal. Select **Evaluations** in the left menu, then the **Evaluator catalog** tab. **Our TrailMate rubric** is listed as a **Custom** rubric, above Microsoft's built-in evaluators.

    ![The Evaluator catalog listing Our TrailMate rubric as a custom rubric above the built-in evaluators](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/03-kickoff-02-evaluator-catalog.png)

1. [] Select **Our TrailMate rubric** and scroll to **Dimensions**. This is our definition of a good TrailMate answer.

    ![The rubric's seven weighted dimensions, from source_grounded_answer to general_quality](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/03-kickoff-02-rubric-dimensions.png)

    > [!Knowledge] A **rubric** is an AI judge with a checklist. Each **dimension** is one check, scored from 1 to 5, and its **weight** says how much it counts. The judge combines them into one score from 0 to 1, so "good" becomes a number we can compare across versions. Foundry drafted these from our traces and gaps. Yours may differ, but you'll likely see similar ideas:
    >
    > - **source_grounded_answer** (weight 10): facts must come from the product files. It catches making things up.
    > - **semantic_claim_precision**: don't upgrade claims, like "water-resistant" to "waterproof". That's our overclaiming gap.
    > - **missing_or_conflicting_evidence_handling**: say so when the files don't answer the question.
    > - **scope_and_role_adherence**: decline off-topic requests and redirect to our products. That's our out-of-lane gap.
    >
    > The optimizer uses this rubric to score every candidate it tries.

1. [] Back in VS Code, jump to section **5.4** and run **both** of its code cells. Confirm you see **Datasets** and **Evaluation ready**.
1. [] Jump to section **5.6** and run the estimate cell. It shows how many agent, evaluation, and optimization calls the job may make, and a cost range. In our test run, the typical estimate was about 62 agent calls and about $1.46, within a range of about $0.97 to $4.88. Yours may differ.
1. [] Run the next code cell to start the job. When it prints **Optimization job:** and status lines, **leave it running**.

    ![Section 5.6 printing the optimization job ID and an in_progress status line](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/03-kickoff-02-optimizer-running.png)

1. [] In the Foundry portal, open **trailmate** and select the **Optimize** tab. Our run is listed **In progress**, with **Version 2** as its baseline.

    ![The trailmate Optimize tab with one run in progress and Version 2 as its baseline](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/03-kickoff-02-optimize-tab.png)

> [+Hint] Rubric generation fails or finds no traces
>
> The traces may still be arriving. Wait one minute, then run the section 5.2 cell again. Don't rerun section 4.5.

> [+Hint] OPTIONAL - Ask Copilot: what is a rubric?
>
> ++What is a rubric evaluator in Microsoft Foundry, and how does the agent optimizer use it? Explain in two sentences.++

---

> [!Note] **Success:** We just started **Make it better**: the agent optimizer is improving Version 2 in Foundry. Next, page 4.1.

===

# 4.1 Start an insights run

**What we'll do:** Ask Foundry to read all of TrailMate's traces and find what's going wrong. It takes 2 to 5 minutes, so we start it now and read the results on page 5.3.

## The loop so far

- **Make it work:** we deployed an agent and asked it questions.
- **Traces** showed how it answered, with the cost (tokens), quality (scores), and latency (time) of each answer.
- From those traces, we built a **rubric** that defines what good looks like, as a score.
- **Make it better:** we started the **agent optimizer** and gave it that rubric to score its candidates.

While the optimizer works, let's look at another tool. **Insights** read our recent traces, find problematic patterns, and propose fixes.

---

> [!Knowledge] A trace records one answer. **Insights** read many traces at once and group the problems they find, with evidence. It's how we spot patterns no single answer shows.

1. [] In the Foundry portal, open **Agents** and select **trailmate**. It now uses **Version 2**, which we created on page 3.1, marked **Active** in the **Version** menu. If the page was already open, it may still show Version 1 until you pick Version 2. Select the **Insights** tab.
1. [] Select **Run now** to scan the agent's recent traces for problems with failures, performance, cost, and quality.

    ![The trailmate Insights tab with no insights yet and the Run now button](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/04-concepts-01-start-insights.png)

1. [] Check that it shows **Run in progress** and **Finding insights...**. It typically takes 2 to 5 minutes, so move on. We don't need to wait.

    ![The Insights tab showing Run in progress and Finding insights, collecting and analyzing traces](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/04-concepts-01-insights-running.png)

> [+Hint] OPTIONAL - Ask Copilot: what are insights?
>
> ++What do agent insights in Microsoft Foundry do? Explain in one sentence.++

---

> [!Note] **Success:** We just asked Foundry to look for problems across every TrailMate trace, while we keep learning.

===

# 4.2 Under the hood: model selection

**What we'll do:** While the optimizer and insights work, let's look under the hood. On the next few pages, we explore how model choice affects the three dials: cost, quality, and latency. First, we send the same two questions to a big and a small model.

1. [] In the Foundry portal, select **Models** in the left menu, then **gpt-5.4**. Its playground opens.

    > [!Note] Here we test the **models** directly, not the TrailMate agent. There's no file search, so each question includes the product facts it needs.

1. [] Open **Compare models** at the top right and select **gpt-5.4-mini**. The two models now sit side by side, and a message goes to both.

    ![The Compare models menu listing deployments, including gpt-5.4-mini and the four mr- routers](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/04-concepts-02-compare-setup.png)

1. [] Send this easy question.

    ++TrailLite Daypack specs: Weight 1.5 lbs, Dimensions 20in x 12in x 6in, Water-resistant fabric. How much does the TrailLite Daypack weigh?++

1. [] Compare the row under each answer. Both are right in about a second, but look at the token counts.

    ![Both models answering 1.5 lbs, with gpt-5.4 using about 4,300 tokens and gpt-5.4-mini about 60](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/04-concepts-02-easy-answers.png)

1. [] Send this harder question, with a trap: one TrailMaster X4 can't sleep six.

    ++TrailMaster X4 Tent: 4-person, 12 lbs, $250, rainfly rated 2000mm. Alpine Explorer Tent: 8-person, 17 lbs, $350, rainfly rated 3000mm. A family of six is camping in heavy rain, wants the lightest setup possible, and has a tight budget. Weigh the trade-offs and recommend one.++

1. [] Scroll to the end of both answers and compare the recommendation, the time, and the tokens.

    ![Both models recommending the Alpine Explorer, with gpt-5.4 taking 4 seconds and about 4,600 tokens and gpt-5.4-mini 1 second and about 440](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/04-concepts-02-compare-answers.png)

> [!Knowledge] In our test, both models picked the Alpine Explorer, but the small one was faster and used a fraction of the tokens. The real question isn't "which model is best?" but "which questions need the big one?"

> [+Hint] OPTIONAL - Ask Copilot: big or small model?
>
> ++When should I pick gpt-5.4-mini over gpt-5.4? Answer in two sentences.++

---

> [!Note] **Success:** We just saw that a smaller model can give the same answer faster and with far fewer tokens, at least on these two questions.

===

# 4.3 Let a router choose

**What we'll do:** Send the same two questions to **gpt-5.4** and to a **model router**, and see which model the router picks for each.

> [!Knowledge] A **model router** is one deployment that looks at each request and sends it to a model from a pool. Easy work can go to a small model, and hard work to a bigger one.

1. [] Clear both panes to start fresh conversations: select the **+** (new chat) icon at the top of each pane.
1. [] In the right pane, open the **Model** menu and switch **gpt-5.4-mini** to **mr-default**. Keep **gpt-5.4** on the left.
1. [] Send the easy daypack question again.

    ++TrailLite Daypack specs: Weight 1.5 lbs, Dimensions 20in x 12in x 6in, Water-resistant fabric. How much does the TrailLite Daypack weigh?++

1. [] Look at the row under the router's answer. It names the model the router chose, here **DeepSeek-V4.1-Flash**, a small, fast model.

    ![gpt-5.4 and mr-default both answering 1.5 lbs, with the router's answer from DeepSeek-V4.1-Flash using 61 tokens](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/04-concepts-03-router-easy.png)

1. [] Send the harder tent question and compare the two answers, times, and tokens.

    ++TrailMaster X4 Tent: 4-person, 12 lbs, $250, rainfly rated 2000mm. Alpine Explorer Tent: 8-person, 17 lbs, $350, rainfly rated 3000mm. A family of six is camping in heavy rain, wants the lightest setup possible, and has a tight budget. Weigh the trade-offs and recommend one.++

    ![Both recommending the Alpine Explorer, with gpt-5.4 taking 4 seconds and about 4,600 tokens and the router's model under a second and about 660](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/04-concepts-03-router-hard.png)

1. [] Now compare cost in dollars. In the left menu, select **Models**, then **mr-default**. Open the **Monitor** tab and scroll down to **Estimated cost: model router vs. single-model baselines**. Use **Baseline models** to pick which models to compare against.

    ![Estimated cost chart with the model router far cheaper than single-model baselines such as gpt-5.5 and claude-opus-4-6](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/04-concepts-03-router-cost.png)

    > [!Knowledge] This chart prices the same traffic in **dollars**, not tokens. A router can sometimes use more tokens and still cost less, because it sends much of the work to cheaper models, so its average cost per token is lower. Our test traffic was tiny, so every bar shows under one cent, but the bar heights show the gap.

> [!Note] Routers pick per request, so yours may choose a different model. In our test, the default router sent both questions to the small model and still got both right.

> [+Hint] OPTIONAL - Ask Copilot: how does a router choose?
>
> ++How does Microsoft Foundry model router decide which model answers a request? Explain in two sentences.++

---

> [!Note] **Success:** We just watched one deployment pick a model per question, and match gpt-5.4's answers for a fraction of the tokens.

===

# 4.4 Turn the cost-quality dial

**What we'll do:** Send the hard question to a router in **cost** mode and one in **quality** mode, and compare their choices.

1. [] In the left pane, open the **Model** menu and select **mr-cost**. In the right pane, select **mr-quality**.
1. [] Send the tent question.

    ++TrailMaster X4 Tent: 4-person, 12 lbs, $250, rainfly rated 2000mm. Alpine Explorer Tent: 8-person, 17 lbs, $350, rainfly rated 3000mm. A family of six is camping in heavy rain, wants the lightest setup possible, and has a tight budget. Weigh the trade-offs and recommend one.++

1. [] Scroll to the end of both answers. Note which model each router picked, and check that both recommend the Alpine Explorer.

    ![mr-cost answering with DeepSeek-V4.1-Flash in 0.3 seconds and mr-quality with gpt-5.4 in 3.1 seconds, both recommending the Alpine Explorer](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/04-concepts-04-cost-vs-quality.png)

> [!Knowledge] In our test, cost mode picked **DeepSeek-V4.1-Flash**, a small, fast, and cheap model, and quality mode picked **gpt-5.4**, a frontier model. Both gave the same recommendation. With gpt-5.4, we paid more and waited longer for frontier quality this question didn't need. The routing mode is a dial between cost and quality. A cheaper pick only wins if the answer stays right across many questions, and that's what we measure on page 7.3.

> [+Hint] OPTIONAL - Ask Copilot: cost or quality mode?
>
> ++What is the difference between the cost and quality routing modes in Microsoft Foundry model router? Explain in one sentence.++

---

> [!Note] **Success:** We just saw how one setting shifts a router between cheaper and stronger models.

===

# 5.1 Compare Versions 1 and 2

**What we'll do:** Put TrailMate Versions 1 and 2 side by side in the playground, and see what better instructions changed.

1. [] In the Foundry portal, open **Agents** and select **trailmate**.
1. [] Open the **Version** menu at the top. You see **Version 2** from page 3.1 next to **Version 1**, our baseline.

    ![The trailmate Version menu listing Version 2, marked Active, above Version 1](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/05-work-01-version-menu.png)

1. [] In the same menu, select **Compare versions** and pick **Version 1** and **Version 2**.
1. [] Send the off-topic question from page 2.2 to both.

    ++Give me a recipe for hot chocolate I can drink while wrapped in my CozyNights Sleeping Bag.++

1. [] Compare the two answers. Which one uses our product files?

    ![Version 1 and Version 2 both giving a hot chocolate recipe; Version 2 adds file-grounded care tips with citations and uses about 18,500 tokens](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/05-work-01-compare-versions.png)

    > [!Note] In our test, both versions still gave a recipe, so we still need to optimize. But look at the difference: **Version 2** used **file search** and grounded its answer in our product files, with citations and care tips for the CozyNights bag. Version 1 answered from general knowledge. The cost went up, about 18,500 tokens versus 1,800, but the agent now connects its answers to our products.

> [+Hint] OPTIONAL - Ask Copilot: what did Version 2 change?
>
> ++Compare src/agent/instructions-v0.md with src/agent/instructions-v1.md. In three bullets, what changed and why might it help?++

---

> [!Note] **Success:** We just saw one lever, the instructions, change how TrailMate answers the same question.

===

# 5.2 Check the monitor

**What we'll do:** Zoom out from one answer to all of them, then check on the optimizer.

1. [] On the trailmate agent page, open the **Monitor** tab. **Operational metrics** show the total token usage, our cost dial, across every run.

    ![The Monitor overview with total token usage and panels for evaluations and scheduled runs](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/05-work-02-monitor-overview.png)

1. [] Scroll to the charts. **Agent runs** counts every conversation, including our practice questions and the optimizer's test runs. **Gen AI errors** shows any failed calls. Select **View agent traces** to jump to the traces behind a point.

    ![The Agent runs chart rising to over 100 runs and the Gen AI errors chart with a handful of errors](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/05-work-02-monitor.png)

1. [] Check on the optimizer. Select the **Optimize** tab and open our run. It first scores the baseline, Version 2, then generates and scores candidates one at a time.

    ![The optimizer run with the baseline scored at 0.759, candidate 1 generating, and candidates 2 and 3 queued](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/05-work-02-optimizer-baseline.png)

    > [!Note] If your run has already finished, that's fine. We look at the results on page 6.1. For now, use the screenshot above to see how a run progresses: baseline first, then each candidate in turn.

    > [!Knowledge] Every run is different. Your scores won't match ours, a different candidate may win, and it's possible none beats the baseline. The process is still valid: we measure, compare, and only promote what the evidence supports.

> [!Knowledge] Our agent works, but "works" isn't the same as "reliable". From here on we stop judging answers one at a time and start measuring them all.

> [+Hint] OPTIONAL - Ask Copilot: is the optimizer done?
>
> ++/microsoft-foundry What is the status of my latest agent optimization job for trailmate? Answer in one sentence. Do not change anything.++

---

> [!Note] **Success:** We just saw the whole agent at a glance and checked our optimizer is still climbing.

===

# 5.3 Read the insights

**What we'll do:** Read what Foundry found across TrailMate's traces, and check it against the three gaps we expected on page 3.2.

> [!Note] Insights come from your own traces, so yours will differ from ours. If a finding is hard to follow, use the **OPTIONAL - Ask Copilot** prompt at the end of this page to have it explained.

1. [] On the **trailmate** agent, open the **Insights** tab. The run we started on page 4.1 lists its findings, each with a category, a severity, and the agent version it was found in.

    ![The Insights tab listing five findings in the Hallucinations and Cost and tokens categories, with the first one open](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/05-work-03-insights-list.png)

1. [] Select a **Hallucinations** finding and read its description. It explains the pattern and links to the traces that show it.
1. [] Select the finding about the **recipe request**, if your run has one, and scroll down. Under **Highlighted traces** is the hot chocolate conversation, and under **Proposed fix** is a suggested change to the instructions.

    ![The recipe finding with its highlighted trace and a proposed fix that edits the agent instructions](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/05-work-03-proposed-fix.png)

1. [] Compare the findings with our three gaps: overclaiming, making things up, and out of lane. Which did Foundry confirm? What did it see differently?

> [!Knowledge] In our test run, Foundry flagged the recipe as a **cost** problem: an unneeded file search. It didn't call it out of lane, because it doesn't know TrailMate's job. Your findings may differ. Insights give us evidence and a starting fix, and we still decide what "good" means. That's what our rubric in stage 6 is for.

> [+Hint] Still running? Read ours
>
> The screenshots on this page come from a completed run in our test. Read them now, and check yours again on page 6.1.

> [+Hint] OPTIONAL - Ask Copilot: which finding first?
>
> ++/microsoft-foundry Summarize the latest insights for my trailmate agent in three bullets. Which should we fix first? Do not change anything.++

---

> [!Note] **Success:** We just read Foundry's findings across every trace, saw a proposed fix, and checked our guesses against the evidence.

===

# 6.1 Read the optimizer results

**What we'll do:** See what the agent optimizer found: how each candidate scored with our rubric, what it changed, and what the run cost.

1. [] In the Foundry portal, open **trailmate**, select the **Optimize** tab, and open our run. When it finishes, **Candidate results** show each candidate's rubric score next to the baseline, agent Version 2, with average tokens and latency.

    ![Final optimizer results: baseline 0.759, candidate_1 0.822 marked Best, candidate_2 0.802, and candidate_3 0.76](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/06-better-01-candidates.png)

    > [!Note] Your results will differ. A different candidate may win, or none may beat the baseline. If none does, keeping Version 2 is the right decision. In our test, the run took about 10 minutes, and all three candidates beat the baseline of 0.759.

1. [] On the best candidate, select **View changes**. The short Version 2 instructions became a detailed set of rules, for example to only make claims the product files support.

    ![The changes for candidate_1, comparing the short baseline prompt with the much longer candidate prompt](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/06-better-01-view-changes.png)

1. [] Scroll up to **Run overview** and select **View details** next to **Total tokens**. It shows what the run itself cost, by phase.

    ![Token usage for the run: about 1.9 million tokens and an estimated $5.37, mostly from running the agent and scoring responses](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/06-better-01-token-usage.png)

    > [!Note] Our run used about 1.9 million tokens, an estimated $5.37, above the $4.88 ceiling estimated on page 3.2. Optimizing costs real money, so we check the measured cost, not just the estimate.

1. [] Recall the rubric dimensions from page 3.2. Your rubric may have different ones, so look for the same ideas:
    - Grounding dimensions, like **source_grounded_answer**, cover the hallucination insights from page 5.3.
    - A claim-precision dimension catches "water-resistant" becoming "waterproof".
    - A scope dimension says off-topic requests should be declined. The built-in evaluators passed the hot chocolate recipe, but our rubric knows TrailMate's job.

> [+Hint] I see "Ran into a deserialization error" in the notebook
>
> The optimizer cell in VS Code may print this Azure SDK warning. It tried to read a reply that had no body and ignored it. If the run finished on the **Optimize** tab, it's safe to ignore. If something else looks wrong, paste the message into Copilot Chat and ask what it means.

> [+Hint] OPTIONAL - Ask Copilot: what did the optimizer do?
>
> ++/microsoft-foundry Summarize my latest agent optimization run for trailmate in three bullets: the baseline score, the best candidate, and what it changed. Do not change anything.++

---

> [!Note] **Success:** We just read how the optimizer turned "good" into a score, which candidate won, and what it cost.

===

# 6.2 Promote the winner

**What we'll do:** Make the best candidate our new agent version, then check what changed on the hot chocolate question.

1. [] On the run page, select **Promote candidate**. Check that the best candidate is selected, then select **Promote to agent version**.

    ![The Promote candidate dialog with candidate_1 selected, showing its score of 0.822 against the Version 2 baseline of 0.759](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/06-better-02-promote-dialog.png)

1. [] Read the banner. The candidate is now agent **Version 3**, the active version. Version 2 stays available.

    ![The banner confirming candidate_1 is now Version 3, with Version 2 still available](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/06-better-02-promoted.png)

1. [] Open the **trailmate** playground and refresh the page (**F5**). The **Version** menu now shows **Version 3** as **Active**.

    ![The trailmate Version menu with Version 3 active above Versions 2 and 1](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/06-better-02-version-3.png)

1. [] Select **Compare versions**, pick **Version 1** and **Version 3**, and send the hot chocolate question to both.

    ++Give me a recipe for hot chocolate I can drink while wrapped in my CozyNights Sleeping Bag.++

    ![Version 1 handing out a recipe with AI Quality 100%, and Version 3 declining and redirecting to the sleeping bag with AI Quality 50%](https://raw.githubusercontent.com/nitya/skillable-labs/refs/heads/ignite26-lab663/ignite26-lab663/v1/screenshots/06-better-02-compare-v1-v3.png)

1. [] Notice the scores. In our test, Version 3 declined and redirected to the sleeping bag, yet the built-in **AI Quality** gave the recipe 100% and the refusal 50%. Built-in evaluators don't know TrailMate's job. Our rubric does.

> [!Knowledge] We saw one optimization run, with one lever: the instructions. A real team would also check the candidate on questions it never saw before promoting it. The More lab on page 9.2 walks through that.

> [+Hint] OPTIONAL - Ask Copilot: why did Version 3 decline?
>
> ++/microsoft-foundry Show the instructions for trailmate Version 3 and explain, in two sentences, which rule makes it decline off-topic requests. Do not change anything.++

---

> [!Note] **Success:** We just promoted one optimization run. We now have agent Version 3.

===

# 7.1 Switch to the model router

**What we'll do:** Keep Version 3's instructions and change one lever, the model, to the **mr-default** router. Saving it creates agent **Version 4**.

1. [] In the **trailmate** playground, check that **Version 3** is selected.
1. [] Open the **Model** menu and change **gpt-5.4** to **mr-default**.

    <!-- TODO screenshot: 07-improve-01-model-menu.png | The trailmate Model menu with mr-default selected on Version 3 -->

1. [] Select **Save**. Foundry saves the change as a new agent version.
1. [] Open the **Version** menu. **Version 4**, the router version, is now **Active**, above Version 3.

    <!-- TODO screenshot: 07-improve-01-version-4.png | The trailmate Version menu with Version 4 active above Version 3 -->
    <!-- VERIFY: Save creates Version 4 rather than overwriting Version 3 -->

> [!Knowledge] Versions 3 and 4 have the same instructions and tools. Only the model differs, so any change in quality, cost, or latency comes from the router.

> [+Hint] OPTIONAL - Ask Copilot: router in an agent?
>
> ++How does a Microsoft Foundry agent behave when its model is a model router deployment? Explain in two sentences.++

---

> [!Note] **Success:** We just created agent Version 4: the optimized instructions, now on the model router.

===

# 7.2 Compare with and without the router

**What we'll do:** Ask Version 3 and Version 4 the same three questions side by side, and compare quality, model, tokens, and time.

1. [] In the **Version** menu, select **Compare versions** and pick **Version 3** and **Version 4**.
1. [] Send the first question. It tests overclaiming: the manual says water-resistant.

    ++Is the Summit Breeze Jacket waterproof?++

1. [] Start a new chat in both panes with **+**, then send the second. It tests making things up: the manual gives no exact weight.

    ++What is the exact per-shoe weight of the TrailWalker Hiking Shoes?++

1. [] Start a new chat again, then send the third. It tests staying in lane.

    ++Give me a recipe for hot chocolate I can drink while wrapped in my CozyNights Sleeping Bag.++

1. [] For each answer, compare the quality, then read the row under it: the model that answered, the tokens, and the time.

    <!-- TODO screenshot: 07-improve-02-compare.png | Version 3 and Version 4 answering the same question, with the model, tokens, and time for each -->
    <!-- VERIFY: the row under a router agent's answer names the model the router picked -->

> [!Note] Three questions are a spot check, not a measurement, and the router may pick different models each time. On page 7.3 we score Version 4 on all 12 questions with our rubric.

> [+Hint] OPTIONAL - Ask Copilot: quality or cost?
>
> ++In two sentences, what should I look for when comparing an agent on a single model with the same agent on a model router?++

---

> [!Note] **Success:** We just saw the router answer our questions with comparable quality, often from a cheaper model.

===

# 7.3 Score the router and its cost

**What we'll do:** Score Version 4 with our rubric on the same 12 questions the optimizer used, then see what the router saved in dollars.

## 7.3.1 Run an evaluation

1. [] On **trailmate**, open the **Evaluation** tab and select **Create**.
1. [] Choose the **Agent** target and select **trailmate**, **Version 4**.
1. [] For the dataset, select **trailmate-dev**, the 12 questions the optimizer scored on page 6.1.
1. [] For the evaluator, select **Our TrailMate rubric**, then start the run.

    <!-- TODO screenshot: 07-improve-03-create-eval.png | Creating an evaluation of trailmate Version 4 with trailmate-dev and Our TrailMate rubric -->
    <!-- VERIFY: the agent version can be selected, the custom rubric is listed, and how long the run takes -->

1. [] When it finishes, compare its score with the best candidate's score on page 6.1. That candidate became Version 3.

    <!-- TODO screenshot: 07-improve-03-eval-results.png | The completed evaluation with the rubric score for Version 4 -->

---

## 7.3.2 See the cost

1. [] Select **Models** in the left menu, then **mr-default**, then the **Monitor** tab.
1. [] Scroll to **Estimated cost: model router vs. single-model baselines**. It now prices the evaluation's agent traffic, and **Baseline models** lets us compare against single models.

    <!-- TODO screenshot: 07-improve-03-router-cost.png | Estimated cost chart for mr-default after the evaluation, against single-model baselines -->

> [!Knowledge] If Version 4 scores about as well as Version 3 while the router costs less than a single frontier model, we've right-sized the model without losing quality. If it scores clearly lower, keeping Version 3 is the right call. Either way, we decided with evidence.

> [+Hint] OPTIONAL - Ask Copilot: was it worth it?
>
> ++/microsoft-foundry Summarize my latest evaluation of trailmate Version 4 in two sentences: its rubric score and any weak areas. Do not change anything.++

---

> [!Note] **Success:** We just measured the router version with our own rubric and saw its cost next to single-model baselines.

===

# 8.1 Finish the lab

**What we'll do:** Look back at the four agent versions we built, and hand the environment back.

1. [] In the **trailmate** playground, open the **Version** menu. Each version is one step of our continuous improvement:

    | Agent version | One lever | Dial it moved |
    |:--------------|:----------|:--------------|
    | **Version 1** | Starting point: one line of instructions | Baseline |
    | **Version 2** | Instructions written by hand | Grounding in our product files |
    | **Version 3** | Instructions rewritten by the agent optimizer | Quality, measured by our rubric |
    | **Version 4** | Model swapped for the model router | Cost and latency, at similar quality |

    <!-- TODO screenshot: 08-wrap-01-versions.png | The trailmate Version menu listing Versions 1 to 4 -->

1. [] Think about what you'd change next, and which dial it would move.
1. [] End the lab when your proctor says so, using the normal Skillable controls.

> [!Alert] Don't run infra/cleanup.sh or delete any resources. The lab removes them when it ends.

> [!Knowledge] We went from a working agent to a measured, cheaper, more reliable one: one lever at a time, with traces, insights, a rubric, and an optimizer giving us the evidence. Keeping a version is often the right call.

> [+Hint] OPTIONAL - Ask Copilot: what did we build?
>
> ++/microsoft-foundry List the versions of my trailmate agent and summarize, in one line each, what changed between them. Do not change anything.++

---

> [!Note] **Success:** We just improved TrailMate from Version 1 to Version 4, and we can explain what each version changed and why.

===

# 9.1 More: explore MAI models

**What we'll do:** Read how Microsoft AI (MAI) models handle a product launch: pictures, a voice, transcripts, and a website. This lab is optional.

1. [] In the Explorer, open **labs > more > README.md**.
1. [] Open **00-set-the-stage.ipynb** from the **labs/more** folder and read the story.
1. [] Open any of notebooks **01** to **04** and read the saved results.

> [!Note] Every More notebook comes pre-run, so reading one needs no setup and costs nothing. The image models aren't in this lab environment, so run them live later with your own subscription.

> [+Hint] OPTIONAL - Ask Copilot: what are MAI models?
>
> ++Summarize labs/more/README.md in three bullets.++

---

> [!Note] **Success:** We just read at least one More notebook in replay mode.

===

# 9.2 More: measure the climb in code

**What we'll do:** Repeat the measurements from the portal more rigorously in the notebooks: held-out questions, repeated runs, and every router edition. This lab is optional.

> [!Note] These notebooks run their own measured path, separate from what we promoted in the portal. Read each section's notes before running it, and expect each evaluation to take a few minutes.

1. [] In **05-make-it-better.ipynb**, run section **5.5** to score Versions 1 and 2 twice each with our rubric.
1. [] Run sections **5.7** to **5.9** to read every candidate and check the guard cases: questions the manuals do answer, which a timid candidate fails.
1. [] Run sections **5.10** and **5.11** to score on test questions the optimizer never saw.
1. [] In section **5.12**, leave `REVIEW_APPROVED = False` if you already promoted in the portal, so the notebook doesn't create another version.

    <!-- VERIFY: notebook 06 runs after a portal promotion with REVIEW_APPROVED left False -->

1. [] In **06-make-it-optimal.ipynb**, set `RUN_ALL_EDITIONS = True` to score all four router editions, then run sections **6.1** to **6.9**.

    > [+Hint] Section 6.3 fails with "Error code: 400"
    >
    > In our test, the router probe in section 6.3 returned a 400 error. That cell only illustrates routing, which pages 4.3 and 4.4 already showed, so skip it and continue with section 6.4. If later sections fail too, paste the error into Copilot Chat, or share the `request_id` with a proctor.

    <!-- VERIFY: root cause of the 400 from notebook 06 section 6.3, and whether sections 6.4 onward run -->

> [!Knowledge] The gain on questions the optimizer trained on is the gain it wanted. The gain on unseen questions is the gain we can trust. Deciding the rule before seeing the scores keeps us honest.

> [+Hint] OPTIONAL - Ask Copilot: summarize the measurement
>
> ++Summarize the results of section 5.11 of labs/core/05-make-it-better.ipynb in two sentences: did the gain hold on unseen questions? Don't change any files.++

---

> [!Note] **Success:** We just measured the climb with held-out questions and repeated runs, the way a team would before a release.
