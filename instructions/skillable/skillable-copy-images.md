<!--
  LAB663 Skillable instructions (full text, image placeholders). GENERATED - do not edit by hand.
  Regenerate with: bash instructions/skillable/scripts/generate-skillable-copy.sh

  Paste this file into Edit Instructions, then upload each named screenshot to the profile
  and insert it where its IMAGE comment is.

  Source pages: nitya/ignite26-LAB663 instructions/skillable/NN-stage-NN.md
  Published to: nitya/skillable-labs (branch ignite26-lab663, folder ignite26-lab663/v1)
  To target a different location: PUBLISH_REPO=<owner/name> PUBLISH_BRANCH=<branch> PUBLISH_PATH=<folder>
-->

@lab.Title

# 0.1 Sign in to your lab

**What we'll do:** Sign in to the virtual machine, then to GitHub, the Foundry portal, and the Azure portal, all with the lab credentials.

## Sign in to the virtual machine

1. [] Check that you see the **Instructions** and **Resources** tabs on the right, and the virtual machine's sign-in screen on the left. The blue bar at the bottom right shows the time left in the lab.

    <!-- IMAGE: 00-start-01-lab-tabs.png | Lab interface with the Instructions and Resources tabs and the VM sign-in screen -->

1. [] Click in the password field on the virtual machine, then click the password below to type it in.

    +++@lab.VirtualMachine(Win11-Pro-Base).Password+++

1. [] Check that the desktop appears, then tick the boxes for the steps you've done. Ticking boxes tracks our progress.

    <!-- IMAGE: 00-start-01-desktop.png | The VM desktop after sign-in, with the first two steps checked off in the instructions -->

## Sign in to GitHub

1. [] Open **Microsoft Edge** and go to the GitHub Enterprise sign-in page. Select **Continue**.

    +++https://github.com/enterprises/skillable-events/sso+++

    <!-- IMAGE: 00-start-01-sso-continue.png | The Single sign-on to Skillable Events page with the Continue button -->

1. [] At the Microsoft sign-in, use these lab credentials, **not** your own account.

    | Credential | Value |
    |:-----------|:------|
    | Username | +++@lab.CloudPortalCredential(User1).Username+++ |
    | TAP | +++@lab.CloudPortalCredential(User1).AccessToken+++ |

    <!-- IMAGE: 00-start-01-microsoft-signin.png | The Microsoft Sign in page asking for an email -->

1. [] Check that you see the **Skillable Events** enterprise page. Leave this tab open.

    <!-- IMAGE: 00-start-01-github-signed-in.png | The Skillable Events GitHub Enterprise overview page after sign-in -->

> [+Hint] I see an error instead
>
> The GitHub license may still be registering. Wait a few minutes and try again. If it still fails, raise your hand to ask a proctor for help.

## Sign in to the Foundry portal

1. [] Open a new tab, go to the Foundry portal, and select **Sign in**. It reuses the lab credentials.

    +++https://ai.azure.com+++

    <!-- IMAGE: 00-start-01-foundry-signin.png | The Microsoft Foundry home page with the Sign in button, and tab groups in Edge -->

    > [!Hint] Edge may already have tab groups such as **GitHub Login**, **Foundry Portal**, and **Azure Portal**. Use them to keep your tabs tidy.

1. [] Check that **All resources** lists one project, **trailmate**. Leave this tab open.

    <!-- IMAGE: 00-start-01-foundry-trailmate.png | The Foundry portal All resources list showing the trailmate project -->

## Sign in to the Azure portal

1. [] Open a new tab and go to the Azure portal. If it doesn't sign you in, select **Sign in** or refresh the page.

    +++https://portal.azure.com+++

    <!-- IMAGE: 00-start-01-azure-home.png | The Azure portal home page after automatic sign-in -->

1. [] Select **Resource groups** and check that **LAB663** is the only one listed. Leave this tab open.

    <!-- IMAGE: 00-start-01-azure-resource-groups.png | Resource groups in the Azure portal listing LAB663 -->

---

> [!Note] **Success:** We just signed in to the virtual machine, GitHub, Foundry, and Azure with the lab credentials. Next, we set up our development environment.

===

# 0.2 How this lab works

**What we'll do:** See the climb ahead of us, and learn the small conventions that keep us moving.

## The climb

Building the first agent is easy. Keeping it reliable and cost-effective takes continuous improvement. Today we practise continuous improvement on **TrailMate**, an outdoor-gear support agent. We change one thing at a time and measure each change. Each step that moves us toward our goal is part of the **climb**.

| Stage | Where | What we do | Version |
|:------|:------|:-----------|:--------|
| 1 Setup | VS Code | Get ready, check everything works | |
| 2 Meet TrailMate | Foundry portal | Try the starting agent and plan the climb | v0 |
| 3 Kick-off | VS Code | Create v1 and start the optimizer, so it works while we explore | v1 |
| 4 Know the concepts | Foundry portal | Start insights, compare models, try the model router | |
| 5 See it work | Foundry portal | Compare v0 and v1, check the monitor, read the insights | v1 |
| 6 Make it better | VS Code | A rubric, the agent optimizer, promote or keep | v2 |
| 7 Keep improving | VS Code | Right-size models with the model router | v3 |
| 8 Wrap | | Look back at the climb | |

## How to use these pages

1. [] Note the page number in each title, like **3.2**. If we get stuck, we raise a hand and say "page 4.3, step 4".
1. [] Text shown +++like this+++ is **type text**: click it to type it into the virtual machine where the cursor is.
1. [] Text shown ++like this++ is **copy text**: click it to copy, then paste it yourself.
1. [] Each step has a checkbox. Checking the last box on a page checks the ones above it.

> [!Hint] **Stuck? Ask Copilot first.** Most pages end with an optional **Ask Copilot** hint: a prompt to paste into Copilot Chat that explains or summarizes what just happened, so we can skip reading long notebook output. We set up Copilot Chat in the next stage, on page 1.2.

---

> [!Note] **Success:** We just learned the route of our climb and how to say exactly where we are. Next, we set up our development environment and GitHub Copilot Chat.

===

# 1.1 Set up the local environment

**What we'll do:** Confirm the lab deployed our Azure resources and set up our local `.env` file, open the lab in VS Code, and sign in to Azure.

## Check the environment status

The desktop has two text files: one starting with **LAB663** and one with **lab663**. Double-click each to open it in an editor.

1. [] Open **LAB663-deployment-output.txt**, the deployment summary. Check that it says **Result: SUCCEEDED**.

    <!-- IMAGE: 01-setup-01-status-file.png | The deployment summary showing Result: SUCCEEDED and the Foundry project details -->

1. [] Open the **lab663-deploy-...** file, the run log. Find the line **Populated .env with the deployment settings**.

    <!-- IMAGE: 01-setup-01-run-log.png | The run log with the Populated .env line highlighted -->

> [+Hint] It says RUNNING or FAILED
>
> **RUNNING:** the lab is still preparing. Wait a few minutes and open the file again. **FAILED:** don't continue. Raise your hand and share the **Stage** line.

## Open the lab in VS Code

1. [] Open **Visual Studio Code** from the desktop and check that the Explorer shows the **LAB663** folder. If a pop-up offers to install the **Dev Containers** extension, close it. If asked whether you trust the authors, select **Yes**.

    <!-- IMAGE: 01-setup-01-vscode-open.png | VS Code open on the LAB663 folder, with the Dev Containers pop-up at the bottom right -->

1. [] Open a terminal with **Terminal > New Terminal**, or press **Ctrl+Shift+backtick**. If you don't see the **Terminal** menu, it's under **...** in the menu bar.

## Sign in to Azure

1. [] In the terminal, run this command. It prints a link and a code.

    ++az login --tenant @lab.CloudSubscription.TenantId --use-device-code++

    <!-- IMAGE: 01-setup-01-az-login-code.png | The terminal showing the device login link and code -->

1. [] Copy the code, then open the link in Edge and paste it. Pick the lab account you used on page 0.1.
1. [] When asked to approve the sign-in, select **Approve**. Then close the browser tab and return to VS Code.

    <!-- IMAGE: 01-setup-01-az-login-approve.png | The Approve sign-in on another device page, with the Approve button -->

1. [] In the terminal, type **1**, or press **Enter**, to keep the default subscription marked with **\***.

    <!-- IMAGE: 01-setup-01-az-login.png | The terminal listing the lab subscription, marked as the default -->

---

> [!Note] **Success:** We just confirmed our resources and `.env` are ready, opened the lab, and signed in to Azure.

===

# 1.2 Set up GitHub Copilot Chat

**What we'll do:** Sign in to GitHub Copilot in VS Code, connect it to Foundry, and check it can see our project.

## Sign in to GitHub Copilot

1. [] In VS Code, click the blue **Sign in** button in the top bar, then select **Continue with GitHub**.

    <!-- IMAGE: 01-setup-02-continue-with-github.png | The Sign in to use GitHub Copilot dialog with Continue with GitHub -->

1. [] In the browser, select **Continue**, then authorize **Visual Studio Code**.
1. [] When the browser offers to open VS Code, select **Open**, or just switch back to VS Code.
1. [] Check that the profile icon at the bottom left shows your GitHub sign-in.

## Get Copilot Chat ready

1. [] In the Copilot Chat window, send just this message and wait for a reply.

    ++Hello++

1. [] In the chat box, switch the model to **Claude Opus 5.5**.
1. [] Switch **Default permissions** to **Allow all**, so Copilot doesn't stop to ask before each tool call. Select **Enable** when asked to confirm.

    <!-- IMAGE: 01-setup-02-allow-all.png | The permissions menu with Allow all selected -->

## Connect Copilot to Foundry

1. [] Above Copilot's reply, click **Completed 2 steps** to expand it, then click **Start it now?** next to **Foundry MCP**.

    <!-- IMAGE: 01-setup-02-start-foundry-mcp.png | The expanded steps with the Start it now link for the Foundry MCP server -->

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

    <!-- IMAGE: 01-setup-02-copilot-agents.png | Copilot Chat listing the trailmate agent in the Foundry project -->

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

    <!-- IMAGE: 01-setup-03-select-kernel.png | The notebook open with the kernel picker showing .venv (3.13.14) and the Outline listing sections 1.1 to 1.10 -->

1. [] Click **Run All** at the top of the notebook.
1. [] In the Outline, click **1.10 So, is my camp ready?** and wait there until it prints **Overall: PASS. Our camp is ready.** This takes a minute or two.

    <!-- IMAGE: 01-setup-03-scorecard.png | Section 1.10 showing 27 of 27 checks passed and Overall: PASS -->

> [!Knowledge] The "Error we expected" line in section 1.11 is there on purpose. It shows what a failure looks like.

> [+Hint] A check failed
>
> New role assignments can take up to 10 minutes. Wait, then rerun the failed cell. To understand the error, paste this into Copilot Chat with the message:
>
> ++In notebook 01, this check failed with the message below. What does it mean, and what should I try? Don't change any files.++

> [+Hint] Ask Copilot: what did we check?
>
> ++Summarize what labs/core/01-setup-and-validate.ipynb checked, in three bullets. Don't change any files.++

---

> [!Note] **Success:** We just proved our project, models, router editions, agent, and tracing all work under our lab account.

===

# 2.1 Meet TrailMate v0

**What we'll do:** Meet the agent we'll improve today. TrailMate is already deployed in Foundry. Let's see what it's made of.

1. [] In Edge, switch to the **Foundry portal** tab. In the left menu, select **Agents**. You see one agent, **trailmate**.

    <!-- IMAGE: 02-meet-01-agents-list.png | The Agents list in the Foundry portal showing the trailmate agent at version 1 -->

1. [] Select **trailmate** to open its playground, then look at the left side:
    - **Version 1** is selected. That's the agent version deployed in Foundry, which we call **v0**, the baseline for our climb.
    - The **Model** is **gpt-5.4**, a large frontier model.
    - The **Instructions** are just one line: "You are a helpful agent."
    - **File search** under **Tools** lets it search ten product manuals.

1. [] To make room for the chat, collapse the left menu with the button at its bottom left, highlighted in red.

    <!-- IMAGE: 02-meet-01-version-1.png | The trailmate playground with Version 1 selected, the model, the one-line instructions, the file search tool, and the collapse-menu button highlighted -->

1. [] Open **Metrics** at the top right of the chat and turn on the evaluators you want. The playground now scores every answer for us.

    <!-- IMAGE: 02-meet-01-metrics.png | The Metrics menu with evaluators such as Intent resolution, Coherence, and Relevance -->

> [+Hint] Ask Copilot: what is this agent?
>
> ++What is a prompt agent in Microsoft Foundry, and what does its file search tool do? Answer in two sentences.++

---

> [!Note] **Success:** We just met TrailMate v0: one model, one tool, and one line of instructions, with live evaluation turned on.

===

# 2.2 Test-drive TrailMate v0

**What we'll do:** Ask v0 two questions, then look behind an answer at its sources, its scores, and its trace.

## Ask two questions

1. [] In **Message the agent**, ask a question about the manuals.

    ++Which tent sleeps 8 people, the TrailMaster X4 or the Alpine Explorer?++

1. [] Look under the answer. The numbered **citations** show the manual files it used, so the answer is grounded in our data. The row below shows the model, time, tokens, tools used, and evaluation scores.

    <!-- IMAGE: 02-meet-02-tent-answer.png | TrailMate's answer about the tents, with citations to product files and a row showing time, tokens, AI Quality, and Safety -->

1. [] Click a citation to read the manual passage behind it, then close it.
1. [] Now ask something a gear-support agent shouldn't answer.

    ++Give me a recipe for hot chocolate I can drink while wrapped in my CozyNights Sleeping Bag.++

    <!-- IMAGE: 02-meet-02-off-topic.png | TrailMate v0 answering the hot chocolate request with a full recipe -->

1. [] Scroll to the end of the answer. It even adds a safety tip, citing the manual's warning to keep the bag away from open flames. Grounded, but it still answered a question that isn't TrailMate's job.

## Look behind an answer

1. [] Hover over **AI Quality** in the row under the answer. Every built-in evaluator passed the recipe.

    <!-- IMAGE: 02-meet-02-quick-scores.png | The hover card for AI Quality showing Coherence, Fluency, Relevance, and Task adherence all Pass -->

1. [] Select **AI Quality** to open the details. On the left, see each step with its time and tokens. On the right, read why each evaluator passed it.

    <!-- IMAGE: 02-meet-02-evaluations.png | The details for the hot chocolate answer, with the file_search and message steps and evaluator reasons -->

1. [] Close the details. Select **Traces**, then **User view**. Open the **Span tree** with its toggle on the left, then select **Play** at the bottom. It replays what the user saw next to the calls the agent made.

    <!-- IMAGE: 02-meet-02-trace.png | The trace user view with the span tree, the agent response, and the replay bar -->

> [!Knowledge] A **trace** is the step-by-step record of one answer. Its **tokens** tell us what the answer cost, and its **duration** how long it took. The built-in evaluators judge general quality, so a well-written recipe passes. They don't know TrailMate's job. In stage 6 we build our own rubric that does.

> [+Hint] Ask Copilot: what are traces?
>
> ++What are agent traces in Microsoft Foundry? Explain in one sentence.++

---

> [!Note] **Success:** We just saw that v0 answers with citations, gets scored live, and leaves a trace. We also saw that "it answers" isn't the same as "it's reliable".

===

# 2.3 Plan the climb

**What we'll do:** Decide what "better" means for TrailMate, see how we'll improve it one change at a time, and why we start the slowest step first.

## What can we improve?

On page 2.2, every answer came with three kinds of numbers. These are the dials we'll turn:

| Dial | What we saw on 2.2 | Why it matters | How we improve it |
|:-----|:-------------------|:---------------|:------------------|
| **Quality** | AI Quality and Safety scores | Wrong or off-topic answers lose customers | Better instructions (v1, v2) |
| **Cost** | Tokens per answer | Every token is billed, on every question | A smaller or routed model (v3) |
| **Latency** | Seconds per answer | Slow answers frustrate customers | A faster model where it's good enough (v3) |

Foundry's observability features keep these numbers visible as we climb:

- **Evaluations** score answers for quality, live in the playground or on a whole question set.
- **Traces** record each step of an answer, with its tokens and duration.
- **Insights** read many traces at once and point to the biggest problems.
- **Monitor** tracks runs, tokens, and failures over time.

1. [] Read the two lists. Quality, cost, and latency often pull against each other, so we measure all three every time we change something.

## One lever at a time

Continuous improvement means we keep measuring and keep changing one thing at a time. The **climb** is the trend toward our goal across those changes, from **v0** to **v3**. We call these **climb versions**. Each one changes just one thing, and we measure each with the same questions, so we always know what moved the score. Foundry has its own **agent versions** (Version 1, Version 2, ...) for what's deployed.

| Climb version | What changes | Who makes it | Agent version in Foundry |
|:--------|:-------------|:-------------|:-----------|
| **v0** | Nothing, it's our starting point | Already deployed | **trailmate**, Version 1 |
| **v1** | Better instructions, written by hand | Notebook 04 | **trailmate**, Version 2 |
| **v2** | Instructions rewritten by the **agent optimizer** | Notebook 05 | Tested as **trailmate-optimizer-candidate** first |
| **v3** | The model, swapped for a **model router** | Notebook 06 | Tested as **trailmate-mr-default-candidate** first |

1. [] Read the table. The notebooks use climb versions (v0 to v3). The portal shows agent versions, numbered from 1, so v0 is **Version 1**.
1. [] Note that v2 and v3 start as separate **candidate** agents. Only a promotion, after we check the evidence, changes **trailmate** itself.

## Why we start the optimizer now

> [!Knowledge] The **agent optimizer** rewrites an agent's instructions, tries several versions, and scores each one with an AI judge on our test questions. It's thorough, so it takes a while, often longer than any other step in this lab.

1. [] Next, on pages 3.1 and 3.2, we create v1 and start the optimizer. Then, while it works, we explore the concepts behind the climb in the portal, and come back to its results on page 6.2.

> [+Hint] Ask Copilot: what is the agent optimizer?
>
> ++What does the Microsoft Foundry agent optimizer do? Explain in one sentence.++

---

> [!Note] **Success:** We just named the three dials we'll improve, the Foundry features that track them, and the climb from v0 to v3.

===

# 3.1 Create v1 and leave traces

**What we'll do:** Change one lever, the instructions, to create TrailMate **v1**, then ask it 12 practice questions so it leaves traces for Foundry to analyze. The optimizer on the next page learns from these.

1. [] In the Explorer, open **labs > core > 04-make-it-work.ipynb**.
1. [] Select the **.venv (3.13.14)** kernel, the same way as on page 1.3.
1. [] In the **Outline**, click **4.8 What does Foundry think is wrong?**, then click the first code cell below that heading.
1. [] Hover over that cell and click the **Execute Above Cells** icon in its toolbar. This runs sections 4.1 to 4.7 in order and stops before 4.8.

    <!-- IMAGE: 03-kickoff-01-execute-above.png | The first section 4.8 code cell with the Execute Above Cells icon highlighted in its toolbar -->

1. [] Use the Outline to follow along. The first cell prints **Connected. 12 practice questions ready.**, and section **4.4** prints **Saved. TrailMate v1 is Foundry version 2**.

    > [!Note] This is the moment **trailmate** moves to agent **Version 2** in Foundry. From here on, the portal opens trailmate at Version 2, our climb version **v1**. Version 1, our baseline **v0**, is still there in the **Version** menu.

    <!-- IMAGE: 03-kickoff-01-connected.png | The first cell printing Connected. 12 practice questions ready. -->

1. [] Wait for section **4.7** to count down. It pauses one minute so the traces can arrive. The whole run takes a couple of minutes.

    <!-- IMAGE: 03-kickoff-01-waiting.png | Section 4.7 counting down Waiting for traces -->

1. [] While it waits, switch to the Foundry portal. Expand the left menu with its toggle at the bottom left, then select **Traces**. The 12 practice conversations appear one by one, each with its duration and tokens.

    <!-- IMAGE: 03-kickoff-01-portal-traces.png | The Foundry Traces list filling with trailmate traces, with duration and tokens -->

> [+Hint] Ask Copilot: what just ran?
>
> ++Summarize what sections 4.1 to 4.7 of labs/core/04-make-it-work.ipynb did, in three bullets. Don't change any files.++

---

> [!Note] **Success:** We just finished **Make it work** (notebook 04): TrailMate v1 is created, and Foundry has 12 conversations' worth of traces to learn from.

===

# 3.2 Start the optimizer

**What we'll do:** Give Foundry a starting gap list, build a rubric from it, and start the **agent optimizer** so it can work on **v2** while we explore.

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

    <!-- IMAGE: 03-kickoff-02-gaps-saved.png | The section 4.9 cell with our three gaps and its output listing them -->

> [!Knowledge] These are risks we expect, written ahead of time so the optimizer can start early. On page 5.3 we'll check them against what Foundry actually finds.

## Start the optimizer

Notebook 04 was **Make it work**: we got v1 running and leaving traces. Notebook 05 is **Make it better**: we let the optimizer improve v1's instructions to find v2.

> [!Knowledge] We're starting the optimizer now because it takes a while, often longer than any other step in this lab. It keeps running in Foundry on its own. While it works, we explore the concepts behind the climb in the portal, then come back for its results on page 6.2.

1. [] In the Explorer, open **labs > core > 05-make-it-better.ipynb**.
1. [] Select the **.venv (3.13.14)** kernel, the same way as on page 1.3.
1. [] Run the first code cell. It prints **v0 = Foundry version 1   v1 = Foundry version 2**, linking our climb versions to the agent versions.

    <!-- IMAGE: 03-kickoff-02-versions.png | The first notebook 05 cell printing v0 = Foundry version 1 and v1 = Foundry version 2 -->
1. [] Jump to section **5.2** and run its code cell. It drafts a rubric from our traces and gap list, printing **Rubric generation: queued** every 15 seconds. Wait for **Rubric created**, which takes about two minutes.

    <!-- IMAGE: 03-kickoff-02-rubric-created.png | Section 5.2 printing queued progress lines, then Rubric created: trailmate-rubric version 1 -->
1. [] Jump to section **5.4** and run its two code cells. Confirm you see **Datasets** and **Evaluation ready**.
1. [] Jump to section **5.6** and run the estimate cell. It shows how many agent, evaluation, and optimization calls the job may make, and a cost range. In our test run, the typical estimate was about 62 agent calls and about $1.46, within a range of about $0.97 to $4.88. Yours may differ.
1. [] Run the next code cell to start the job. When it prints **Optimization job:** and status lines, **leave it running**.

    <!-- IMAGE: 03-kickoff-02-optimizer-running.png | Section 5.6 printing the optimization job ID and an in_progress status line -->

1. [] In the Foundry portal, open **trailmate** and select the **Optimize** tab. Our run is listed **In progress**, with **Version 2**, our v1, as its baseline.

    <!-- IMAGE: 03-kickoff-02-optimize-tab.png | The trailmate Optimize tab with one run in progress and Version 2 as its baseline -->

> [+Hint] Rubric generation fails or finds no traces
>
> The traces may still be arriving. Wait one minute, then run the section 5.2 cell again. Don't rerun section 4.5.

> [+Hint] Ask Copilot: what is a rubric?
>
> ++What is a rubric evaluator in Microsoft Foundry, and how does the agent optimizer use it? Explain in two sentences.++

---

> [!Note] **Success:** We just started **Make it better**: the agent optimizer is working on v2 in Foundry. Next, page 4.1.

===

# 4.1 Start an insights run

**What we'll do:** Ask Foundry to read all of TrailMate's traces and find what's going wrong. It takes 2 to 5 minutes, so we start it now and read the results on page 5.3.

> [!Knowledge] A trace records one answer. **Insights** read many traces at once and group the problems they find, with evidence. It's how we spot patterns no single answer shows.

1. [] In the Foundry portal, open **Agents** and select **trailmate**. It now uses **Version 2**, the v1 we created on page 3.1, marked **Active** in the **Version** menu. If the page was already open, it may still show Version 1 until you pick Version 2. Select the **Insights** tab.
1. [] Select **Run now** to scan the agent's recent traces for problems with failures, performance, cost, and quality.

    <!-- IMAGE: 04-concepts-01-start-insights.png | The trailmate Insights tab with no insights yet and the Run now button -->

1. [] Check that it shows **Run in progress** and **Finding insights...**. It typically takes 2 to 5 minutes, so move on. We don't need to wait.

    <!-- IMAGE: 04-concepts-01-insights-running.png | The Insights tab showing Run in progress and Finding insights, collecting and analyzing traces -->

> [+Hint] Ask Copilot: what are insights?
>
> ++What do agent insights in Microsoft Foundry do? Explain in one sentence.++

---

> [!Note] **Success:** We just asked Foundry to look for problems across every TrailMate trace, while we keep learning.

===

# 4.2 Compare a big and a small model

**What we'll do:** While the optimizer and insights work, let's learn the ideas behind the climb. First, send the same two questions to a big and a small model, and see how model choice changes speed, tokens, and quality.

1. [] In the Foundry portal, select **Models** in the left menu, then **gpt-5.4**. Its playground opens.

    > [!Note] Here we test the **models** directly, not the TrailMate agent. There's no file search, so each question includes the product facts it needs.

1. [] Open **Compare models** at the top right and select **gpt-5.4-mini**. The two models now sit side by side, and a message goes to both.

    <!-- IMAGE: 04-concepts-02-compare-setup.png | The Compare models menu listing deployments, including gpt-5.4-mini and the four mr- routers -->

1. [] Send this easy question.

    ++TrailLite Daypack specs: Weight 1.5 lbs, Dimensions 20in x 12in x 6in, Water-resistant fabric. How much does the TrailLite Daypack weigh?++

1. [] Compare the row under each answer. Both are right in about a second, but look at the token counts.

    <!-- IMAGE: 04-concepts-02-easy-answers.png | Both models answering 1.5 lbs, with gpt-5.4 using about 4,300 tokens and gpt-5.4-mini about 60 -->

1. [] Send this harder question, with a trap: one TrailMaster X4 can't sleep six.

    ++TrailMaster X4 Tent: 4-person, 12 lbs, $250, rainfly rated 2000mm. Alpine Explorer Tent: 8-person, 17 lbs, $350, rainfly rated 3000mm. A family of six is camping in heavy rain, wants the lightest setup possible, and has a tight budget. Weigh the trade-offs and recommend one.++

1. [] Scroll to the end of both answers and compare the recommendation, the time, and the tokens.

    <!-- IMAGE: 04-concepts-02-compare-answers.png | Both models recommending the Alpine Explorer, with gpt-5.4 taking 4 seconds and about 4,600 tokens and gpt-5.4-mini 1 second and about 440 -->

> [!Knowledge] In our test, both models picked the Alpine Explorer, but the small one was faster and used a fraction of the tokens. The real question isn't "which model is best?" but "which questions need the big one?"

> [+Hint] Ask Copilot: big or small model?
>
> ++When should I pick gpt-5.4-mini over gpt-5.4? Answer in two sentences.++

---

> [!Note] **Success:** We just saw that a smaller model can give the same answer faster and with far fewer tokens, at least on these two questions.

===

# 4.3 Let a router choose

**What we'll do:** Send the same two questions to **gpt-5.4** and to a **model router**, and see which model the router picks for each.

> [!Knowledge] A **model router** is one deployment that looks at each request and sends it to a model from a pool. Easy work can go to a small model, and hard work to a bigger one.

1. [] In the right pane, open the **Model** menu and switch **gpt-5.4-mini** to **mr-default**. Keep **gpt-5.4** on the left.
1. [] Send the easy daypack question again.

    ++TrailLite Daypack specs: Weight 1.5 lbs, Dimensions 20in x 12in x 6in, Water-resistant fabric. How much does the TrailLite Daypack weigh?++

1. [] Look at the row under the router's answer. It names the model the router chose, here **DeepSeek-V4.1-Flash**, a small, fast model.

    <!-- IMAGE: 04-concepts-03-router-easy.png | gpt-5.4 and mr-default both answering 1.5 lbs, with the router's answer from DeepSeek-V4.1-Flash using 61 tokens -->

1. [] Send the harder tent question and compare the two answers, times, and tokens.

    ++TrailMaster X4 Tent: 4-person, 12 lbs, $250, rainfly rated 2000mm. Alpine Explorer Tent: 8-person, 17 lbs, $350, rainfly rated 3000mm. A family of six is camping in heavy rain, wants the lightest setup possible, and has a tight budget. Weigh the trade-offs and recommend one.++

    <!-- IMAGE: 04-concepts-03-router-hard.png | Both recommending the Alpine Explorer, with gpt-5.4 taking 4 seconds and about 4,600 tokens and the router's model under a second and about 660 -->

> [!Note] Routers pick per request, so yours may choose a different model. In our test, the default router sent both questions to the small model and still got both right.

> [+Hint] Ask Copilot: how does a router choose?
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

    <!-- IMAGE: 04-concepts-04-cost-vs-quality.png | mr-cost answering with DeepSeek-V4.1-Flash in 0.3 seconds and mr-quality with gpt-5.4 in 3.1 seconds, both recommending the Alpine Explorer -->

> [!Knowledge] In our test, cost mode picked a small model and quality mode picked gpt-5.4, and both got it right. The routing mode is a dial between cost and quality. A cheaper pick only wins if the answer stays right across many questions, and that's what we measure on page 7.1.

> [+Hint] Ask Copilot: cost or quality mode?
>
> ++What is the difference between the cost and quality routing modes in Microsoft Foundry model router? Explain in one sentence.++

---

> [!Note] **Success:** We just saw how one setting shifts a router between cheaper and stronger models.

===

# 5.1 Compare v0 and v1

**What we'll do:** Put TrailMate v0 and v1 side by side in the playground, and see what better instructions changed.

1. [] In the Foundry portal, open **Agents** and select **trailmate**.
1. [] Open the **Version** menu at the top. You now see agent **Version 2**, our climb version **v1** from page 3.1, next to **Version 1**, our baseline **v0**.

    <!-- IMAGE: 05-work-01-version-menu.png | The trailmate Version menu listing Version 2, marked Active, above Version 1 -->

1. [] In the same menu, select **Compare versions** and pick **Version 1** and **Version 2**.

1. [] Send the off-topic question from page 2.2 to both.

    ++Give me a recipe for hot chocolate I can drink while wrapped in my CozyNights Sleeping Bag.++

1. [] Compare the two answers. Did v1 stay closer to TrailMate's job? One question is just a hint, so in stage 6 we measure all of them.

    <!-- TODO screenshot: 05-work-01-compare-versions.png | Version 1 and Version 2 answering the hot chocolate request side by side -->

> [!Knowledge] Later, the Agents list also shows **trailmate-optimizer-candidate** and **trailmate-mr-default-candidate**. They're test copies. Only a promotion changes **trailmate** itself.

> [+Hint] Ask Copilot: what did v1 change?
>
> ++Compare src/agent/instructions-v0.md with src/agent/instructions-v1.md. In three bullets, what changed and why might it help?++

---

> [!Note] **Success:** We just saw one lever, the instructions, change how TrailMate answers the same question.

===

# 5.2 Check the monitor

**What we'll do:** Zoom out from one answer to all of them, then check on the optimizer.

1. [] On the trailmate agent page, open the **Monitor** tab. **Operational metrics** show the total token usage, our cost dial, across every run.

    <!-- IMAGE: 05-work-02-monitor-overview.png | The Monitor overview with total token usage and panels for evaluations and scheduled runs -->

1. [] Scroll to the charts. **Agent runs** counts every conversation, including our practice questions and the optimizer's test runs. **Gen AI errors** shows any failed calls. Select **View agent traces** to jump to the traces behind a point.

    <!-- IMAGE: 05-work-02-monitor.png | The Agent runs chart rising to over 100 runs and the Gen AI errors chart with a handful of errors -->

1. [] Check on the optimizer. Select the **Optimize** tab and open our run. It first scores the baseline, our v1, then generates and scores candidates one at a time.

    <!-- IMAGE: 05-work-02-optimizer-baseline.png | The optimizer run with the baseline scored at 0.759, candidate 1 generating, and candidates 2 and 3 queued -->

> [!Knowledge] Our agent works, but "works" isn't the same as "reliable". From here on we stop judging answers one at a time and start measuring them all.

> [+Hint] Ask Copilot: is the optimizer done?
>
> ++/microsoft-foundry What is the status of my latest agent optimization job for trailmate? Answer in one sentence. Do not change anything.++

---

> [!Note] **Success:** We just saw the whole agent at a glance and checked our optimizer is still climbing.

===

# 5.3 Read the insights

**What we'll do:** Read what Foundry found across TrailMate's traces, and check it against the three gaps we expected on page 3.2.

1. [] On the **trailmate** agent, open the **Insights** tab. The run we started on page 4.1 lists its findings, each with a category, a severity, and the agent version it was found in.

    <!-- IMAGE: 05-work-03-insights-list.png | The Insights tab listing five findings in the Hallucinations and Cost and tokens categories, with the first one open -->

1. [] Select a **Hallucinations** finding and read its description. It explains the pattern and links to the traces that show it.
1. [] Select the finding about the **recipe request** and scroll down. Under **Highlighted traces** is the hot chocolate conversation, and under **Proposed fix** is a suggested change to the instructions.

    <!-- IMAGE: 05-work-03-proposed-fix.png | The recipe finding with its highlighted trace and a proposed fix that edits the agent instructions -->

1. [] Compare the findings with our three gaps: overclaiming, making things up, and out of lane. Which did Foundry confirm? What did it see differently?

> [!Knowledge] Foundry flagged the recipe as a **cost** problem: an unneeded file search. It didn't call it out of lane, because it doesn't know TrailMate's job. Insights give us evidence and a starting fix, and we still decide what "good" means. That's what our rubric in stage 6 is for.

> [+Hint] Still running? Read ours
>
> The screenshots on this page come from a completed run in our test. Read them now, and check yours again on page 6.1.

> [+Hint] Ask Copilot: which finding first?
>
> ++/microsoft-foundry Summarize the latest insights for my trailmate agent in three bullets. Which should we fix first? Do not change anything.++

---

> [!Note] **Success:** We just read Foundry's findings across every trace, saw a proposed fix, and checked our guesses against the evidence.

===

# 6.1 Turn good into a number

**What we'll do:** Read the rubric Foundry drafted from our traces and gaps, see how it connects to the insights, then use it to score **v0** and **v1** on the same questions.

1. [] Switch to **05-make-it-better.ipynb**. If the optimizer cell in section 5.6 is still running, click the **stop** button next to it.

    > [!Note] Stopping the cell only stops the notebook from waiting. The optimizer job keeps running in Foundry, and we'll pick it up again on page 6.2.

    <!-- VERIFY: interrupting the wait doesn't cancel the optimizer job -->

1. [] In the Foundry portal, open **Evaluations**, then the **Evaluator catalog** tab. **Our TrailMate rubric** is listed as a custom rubric, next to Microsoft's built-in evaluators.

    <!-- IMAGE: 06-better-01-evaluator-catalog.png | The Evaluator catalog listing Our TrailMate rubric as a custom rubric above the built-in evaluators -->

1. [] Select **Our TrailMate rubric** and scroll to **Dimensions**. Each one is a weighted check the judge scores from 1 to 5.

    <!-- IMAGE: 06-better-01-rubric-dimensions.png | The rubric's seven weighted dimensions, from source_grounded_answer to general_quality -->

1. [] Match the dimensions to what we've seen:
    - **source_grounded_answer** and **missing_or_conflicting_evidence_handling** cover the hallucination insights and our "making things up" gap.
    - **semantic_claim_precision** names our overclaiming gap: "water-resistant" becoming "waterproof".
    - **scope_and_role_adherence** says off-topic requests should be declined. The built-in evaluators and insights missed that the hot chocolate recipe was out of lane. Our rubric knows TrailMate's job.
1. [] Jump to section **5.5** and run its two code cells to score v0 and v1 twice each. It takes a few minutes.
1. [] Confirm the scoreboard has two rows, each with a score, a spread, and **errored** at 0.

    <!-- TODO screenshot: 06-better-01-scoreboard.png | The v0 and v1 scoreboard and the per-category table -->

> [+Hint] Ask Copilot: summarize the scores
>
> ++In three bullets, summarize what the rubric in section 5.3 of labs/core/05-make-it-better.ipynb checks and how v0 and v1 scored in section 5.5. Don't change any files.++

---

> [!Note] **Success:** We just turned "good" into a number, using a ruler we checked ourselves.

===

# 6.2 Let the optimizer climb

**What we'll do:** Pick up the optimizer job, read the instructions it proposed, and check that the winner isn't just more cautious.

1. [] In the Foundry portal, open **trailmate**, select the **Optimize** tab, and open our run. When it finishes, the **Candidate results** show each candidate's score next to the v1 baseline, with its average tokens and latency.

    <!-- IMAGE: 06-better-02-candidates.png | Final optimizer results: baseline 0.759, candidate_1 0.822 marked Best, candidate_2 0.802, and candidate_3 0.76 -->

    > [+Hint] Still running? Read our test run
    >
    > Ours took about 10 minutes. All three candidates beat the v1 baseline of 0.759, and candidate_1 scored best at 0.822, with slightly fewer tokens and lower latency too. Follow along with the screenshots on this page while yours finishes.

1. [] On the best candidate, select **View changes**. The one-line v1 instructions became a detailed set of rules, for example to only make claims the product files support.

    <!-- IMAGE: 06-better-02-view-changes.png | The changes for candidate_1, comparing the short baseline prompt with the much longer candidate prompt -->

1. [] Scroll up to **Run overview** and select **View details** next to **Total tokens**. It shows what the run itself cost, by phase.

    <!-- IMAGE: 06-better-02-token-usage.png | Token usage for the run: about 1.9 million tokens and an estimated $5.37, mostly from running the agent and scoring responses -->

    > [!Note] Our run used about 1.9 million tokens, an estimated $5.37. That's above the $4.88 ceiling the notebook estimated on page 3.2. Optimizing costs real money, so we check the measured cost, not just the estimate.

    > [!Alert] Don't select **Promote candidate** in the portal. We decide on page 6.3, after checking the candidate on questions it never saw.

1. [] Back in VS Code, in **05-make-it-better.ipynb**, jump to section **5.6** and run the job cell again. It resumes the saved job and prints **Finished** with the best and baseline scores.
1. [] Jump to section **5.7** and run its two code cells. Read each candidate's score, then read the winning instructions in full.
1. [] Jump to section **5.8** and run its code cell. It stages the winner as a separate candidate agent. Nothing is promoted yet.
1. [] Jump to section **5.9** and run its code cell. Check the guard-case answers against the manual.

> [!Knowledge] A timid agent never invents anything, but it's also useless. Guard cases are questions the manuals *do* answer, so a candidate that just refuses fails them.

> [+Hint] Ask Copilot: what did the optimizer change?
>
> ++Summarize what the winning candidate changed in section 5.7 of labs/core/05-make-it-better.ipynb, in three bullets. Don't change any files.++

---

> [!Note] **Success:** We just read what the optimizer changed and checked it still answers what it should.

===

# 6.3 Decide whether to promote

**What we'll do:** Test v0, v1, and the candidate on questions the optimizer never saw, then make an explicit promote-or-retain decision for **v2**.

1. [] Jump to section **5.10** and run its two code cells. It takes a few minutes. Confirm the board has rows for v0, v1, and the v2 candidate.
1. [] Run section **5.11** and compare the gain on questions the optimizer trained on with the gain on questions it never saw.

    <!-- TODO screenshot: 06-better-03-heldout.png | Section 5.11 comparing dev gain with test gain -->

1. [] In section **5.12**, set `REVIEW_APPROVED = True` only if the instructions, guard answers, and scores hold up. Then run the cell and read the decision.

    > [+Hint] What does promotion do?
    >
    > Promotion turns the candidate into a new **trailmate** agent version and makes it active. In our test, the candidate became **Version 3**, our climb version **v2**, and the portal confirmed it. The notebook promotes the same way, but only after the checks pass.
    >
    > <!-- IMAGE: 06-better-03-promoted.png | The portal banner confirming candidate_1 is now Version 3, with Version 2 still available -->

1. [] If the candidate was promoted, open **trailmate** in the portal. The **Version** menu now shows the new version as **Active**.

    <!-- IMAGE: 06-better-03-version-3.png | The trailmate Version menu with Version 3 active above Versions 2 and 1 -->

1. [] Select **Compare versions**, pick **Version 1** and the new version, and send the hot chocolate question to both.

    ++Give me a recipe for hot chocolate I can drink while wrapped in my CozyNights Sleeping Bag.++

    <!-- IMAGE: 06-better-03-compare-v0-v3.png | Version 1 handing out a recipe with AI Quality 100%, and Version 3 declining and redirecting to the sleeping bag with AI Quality 50% -->

1. [] Notice the scores. In our test, the built-in **AI Quality** gave the recipe 100% and the correct refusal 50%. Built-in evaluators don't know TrailMate's job. Our rubric does, and that's why we measure with it.

> [!Knowledge] The gain on trained questions is the gain the optimizer wanted. The gain on unseen questions is the gain we can trust. If the candidate doesn't pass, keeping v1 as our v2 checkpoint is a correct result, and the comparison steps above don't apply.

> [+Hint] Ask Copilot: explain the decision
>
> ++Explain the decision printed in section 5.12 of labs/core/05-make-it-better.ipynb in two sentences: was the candidate promoted, and why? Don't change any files.++

---

> [!Note] **Success:** We just made a promote-or-retain decision backed by evidence, not by a single score.

===

# 7.1 Try a model router

**What we'll do:** Keep v2's instructions and change only the model, to the **mr-default** router. Then score it with the same rubric and questions.

1. [] In the Explorer, open **labs > core > 06-make-it-optimal.ipynb**.
1. [] Select the **.venv (3.13.14)** kernel, the same way as on page 1.3.

1. [] In the first code cell, leave `RUN_ALL_EDITIONS = False` and `TOLERANCE` as they are, then run it.
1. [] Run section **6.2** and note how many test questions are tagged easy.
1. [] Run section **6.3** and compare the models it shows with what you saw in the playground on pages 4.3 and 4.4. It mentions a hand-built router from Module 3. That's an optional More lab (page 9.1), so skip that line.
1. [] Run section **6.4** to create the router candidate, then section **6.5** to score it. Scoring takes a few minutes.

    > [+Hint] While you wait: all four router editions
    >
    > We score only mr-default today. Here's a completed run with all four editions side by side.
    >
    > <!-- TODO screenshot: 07-improve-01-all-editions.png | A completed board comparing the baseline with all four router editions -->

1. [] Confirm the board has a baseline row and an **mr-default** row. If `valid` is False, that batch can't support a comparison.

    <!-- TODO screenshot: 07-improve-01-board.png | The section 6.5 board with the baseline and mr-default rows -->

> [+Hint] Ask Copilot: summarize the router board
>
> ++Summarize the board in section 6.5 of labs/core/06-make-it-optimal.ipynb in three bullets: quality, cost, and errors. Don't change any files.++

---

> [!Note] **Success:** We just measured a router candidate with the same ruler as every earlier version.

===

# 7.2 Decide on the router

**What we'll do:** Find where the router slips, apply the decision rule we wrote before seeing any score, and decide on **v3**.

1. [] Run section **6.6** and compare scores by difficulty for the baseline and mr-default.
1. [] Run section **6.7**, then the held-out check cell below it.
1. [] Set `REVIEW_APPROVED = True` only after reading the actual answers and judge reasons. Then run the cell and read the decision.
1. [] Run section **6.8** to make a winner official, if there is one.

> [!Knowledge] Invalid coverage, a category that got worse, an unknown cost, or a pending review all mean we keep the baseline. That's a legitimate result, not a failed lab.

> [+Hint] Ask Copilot: explain the router decision
>
> ++Explain the router decision in section 6.7 of labs/core/06-make-it-optimal.ipynb in two sentences. Don't change any files.++

---

> [!Note] **Success:** We just made a router decision from complete evidence.

===

# 8.1 Finish the lab

**What we'll do:** Look back at the whole climb in one chart, and hand the environment back.

1. [] In **06-make-it-optimal.ipynb**, run section **6.9** to see the heatmap of v0, v1, v2, and v3 on the same held-out questions.

    <!-- TODO screenshot: 08-wrap-01-heatmap.png | The section 6.9 heatmap of the whole climb -->

1. [] Find the row that improved most from v0 to v2. That's the **quality** climb, from the instructions.
1. [] Check whether v3 held that line. That's the **cost** climb, from the router.
1. [] Find the lowest row. That's where our next experiment should go.
1. [] End the lab when your proctor says so, using the normal Skillable controls.

> [!Alert] Don't run infra/cleanup.sh or delete any resources. The lab removes them when it ends.

> [!Knowledge] We went from plan to prototype to production, then kept improving: one lever at a time, measured with a frozen ruler, with an explicit decision at every step. Keeping a version is often the right call.

> [+Hint] Ask Copilot: summarize the climb
>
> ++Summarize the whole climb shown in the heatmap in section 6.9 of labs/core/06-make-it-optimal.ipynb, in three bullets. Don't change any files.++

---

> [!Note] **Success:** We just climbed from v0 to a measured decision, and we can explain why each step moved the score or didn't.

===

# 9.1 More: multi-model vs multi-modal

**What we'll do:** Build a tiny router by hand to see what model router does for us. One model looks at a product photo, another answers from the manuals, and our own rules decide which questions go where. This lab is optional.

1. [] In the Explorer, open **labs > core > 03-multi-model-vs-multimodal.ipynb**.
1. [] Select the **.venv (3.13.14)** kernel, the same way as on page 1.3.
1. [] In section **3.2**, leave `COMPARE_ALL_PHOTOS = False` to keep it to one photo, then run the section.
1. [] Run sections **3.3** to **3.5** and compare your homemade router's labels with the tagged ones.

> [!Knowledge] Multi-modal is about what comes in, like a photo. Multi-model is about who handles which step. Our hand-built rules work, but someone has to write and maintain them. Model router makes that choice for us, per request.

> [+Hint] Ask Copilot: multi-model or multi-modal?
>
> ++What's the difference between multi-model and multi-modal AI? Explain in one sentence.++

---

> [!Note] **Success:** We just chained two models on a photo question and measured a router we built ourselves.

===

# 9.2 More: explore MAI models

**What we'll do:** Read how Microsoft AI (MAI) models handle a product launch: pictures, a voice, transcripts, and a website. This lab is optional.

1. [] In the Explorer, open **labs > more > README.md**.
1. [] Open **00-set-the-stage.ipynb** from the **labs/more** folder and read the story.
1. [] Open any of notebooks **01** to **04** and read the saved results.

> [!Note] Every More notebook comes pre-run, so reading one needs no setup and costs nothing. The image models aren't in this lab environment, so run them live later with your own subscription.

> [+Hint] Ask Copilot: what are MAI models?
>
> ++Summarize labs/more/README.md in three bullets.++

---

> [!Note] **Success:** We just read at least one More notebook in replay mode.

===

# 10.1 Lab credentials and links

**What we'll do:** Keep the values and links we need in one place. Come back to this page any time.

## For lab learners

Click the first column to type a value into the virtual machine where the cursor is. Click the second to copy it to the clipboard.

|  | Type into VM | Copy |
|:---|:---|:---|
| **Virtual machine** | | |
| Password | +++@lab.VirtualMachine(Win11-Pro-Base).Password+++ | ++@lab.VirtualMachine(Win11-Pro-Base).Password++ |
| **Azure sign-in** | | |
| Username | +++@lab.CloudPortalCredential(User1).Username+++ | ++@lab.CloudPortalCredential(User1).Username++ |
| Password | +++@lab.CloudPortalCredential(User1).Password+++ | ++@lab.CloudPortalCredential(User1).Password++ |
| TAP | +++@lab.CloudPortalCredential(User1).AccessToken+++ | ++@lab.CloudPortalCredential(User1).AccessToken++ |
| **GitHub sign-in** | | |
| Sign in with SSO | +++https://github.com/enterprises/skillable-events/sso+++ | ++https://github.com/enterprises/skillable-events/sso++ |
| **Foundry portal** | +++https://ai.azure.com+++ | ++https://ai.azure.com++ |
| **Azure portal** | +++https://portal.azure.com+++ | ++https://portal.azure.com++ |

!IMAGE[eu2xtqsr.png](instructions359314/eu2xtqsr.png)

## For lab instructors

| | Link |
|:---|:---|
| Markdown syntax | ++https://docs.skillable.com/docs/creating-instructions-with-markdown-syntax++ |
| Committing VM changes | ++https://docs.skillable.com/docs/committing-changes-to-a-lab++ |
| Instructions outside Studio | ++https://docs.skillable.com/docs/manage-instructions-outside-of-studio++ |

---

> [!Note] **Success:** We just found every credential and link for this lab in one place.
