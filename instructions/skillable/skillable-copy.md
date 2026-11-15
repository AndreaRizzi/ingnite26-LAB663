@lab.Title

<!--
  LAB663 Skillable instructions. GENERATED, do not edit by hand.
  Regenerate with: bash instructions/skillable/scripts/generate-skillable-copy.sh
  Mode: full. Images: github. Source: instructions/skillable/NN-stage-NN.md
  Paste everything in this file into the Skillable lab profile (Edit Instructions).
-->

# 0.1 Sign in to your lab

**What we'll do:** Sign in to the virtual machine, then to GitHub, the Foundry portal, and the Azure portal, all with the lab credentials.

## Sign in to the virtual machine

1. [] Check that you see the **Instructions** and **Resources** tabs on the right, and the virtual machine's sign-in screen on the left. The blue bar at the bottom right shows the time left in the lab.

    ![Lab interface with the Instructions and Resources tabs and the VM sign-in screen](https://raw.githubusercontent.com/nitya/ignite26-LAB663/main/instructions/skillable/screenshots/00-start-01-lab-tabs.png)

1. [] Click in the password field on the virtual machine, then click the password below to type it in.

    +++@lab.VirtualMachine(Win11-Pro-Base).Password+++

1. [] Check that the desktop appears, then tick the boxes for the steps you've done. Ticking boxes tracks our progress.

    ![The VM desktop after sign-in, with the first two steps checked off in the instructions](https://raw.githubusercontent.com/nitya/ignite26-LAB663/main/instructions/skillable/screenshots/00-start-01-desktop.png)

## Sign in to GitHub

1. [] Open **Microsoft Edge** and go to the GitHub Enterprise sign-in page. Select **Continue**.

    +++https://github.com/enterprises/skillable-events/sso+++

    ![The Single sign-on to Skillable Events page with the Continue button](https://raw.githubusercontent.com/nitya/ignite26-LAB663/main/instructions/skillable/screenshots/00-start-01-sso-continue.png)

1. [] At the Microsoft sign-in, use these lab credentials, **not** your own account.

    | Credential | Value |
    |:-----------|:------|
    | Username | +++@lab.CloudPortalCredential(User1).Username+++ |
    | TAP | +++@lab.CloudPortalCredential(User1).AccessToken+++ |

    ![The Microsoft Sign in page asking for an email](https://raw.githubusercontent.com/nitya/ignite26-LAB663/main/instructions/skillable/screenshots/00-start-01-microsoft-signin.png)

1. [] Check that you see the **Skillable Events** enterprise page. Leave this tab open.

    ![The Skillable Events GitHub Enterprise overview page after sign-in](https://raw.githubusercontent.com/nitya/ignite26-LAB663/main/instructions/skillable/screenshots/00-start-01-github-signed-in.png)

> [+Hint] I see an error instead
>
> The GitHub license may still be registering. Wait a few minutes and try again. If it still fails, raise your hand to ask a proctor for help.

## Sign in to the Foundry portal

1. [] Open a new tab, go to the Foundry portal, and select **Sign in**. It reuses the lab credentials.

    +++https://ai.azure.com+++

    ![The Microsoft Foundry home page with the Sign in button, and tab groups in Edge](https://raw.githubusercontent.com/nitya/ignite26-LAB663/main/instructions/skillable/screenshots/00-start-01-foundry-signin.png)

    > [!Hint] Edge may already have tab groups such as **GitHub Login**, **Foundry Portal**, and **Azure Portal**. Use them to keep your tabs tidy.

1. [] Check that **All resources** lists one project, **trailmate**. Leave this tab open.

    ![The Foundry portal All resources list showing the trailmate project](https://raw.githubusercontent.com/nitya/ignite26-LAB663/main/instructions/skillable/screenshots/00-start-01-foundry-trailmate.png)

## Sign in to the Azure portal

1. [] Open a new tab and go to the Azure portal. If it doesn't sign you in, select **Sign in** or refresh the page.

    +++https://portal.azure.com+++

    ![The Azure portal home page after automatic sign-in](https://raw.githubusercontent.com/nitya/ignite26-LAB663/main/instructions/skillable/screenshots/00-start-01-azure-home.png)

1. [] Select **Resource groups** and check that **LAB663** is the only one listed. Leave this tab open.

    ![Resource groups in the Azure portal listing LAB663](https://raw.githubusercontent.com/nitya/ignite26-LAB663/main/instructions/skillable/screenshots/00-start-01-azure-resource-groups.png)

---

> [!Note] **Success:** We just signed in to the virtual machine, GitHub, Foundry, and Azure with the lab credentials. Next, we set up our development environment.

===

# 0.2 How this lab works

**What we'll do:** See the climb ahead of us, and learn the small conventions that keep us moving.

## The climb

Building the first agent is easy. Keeping it reliable and cost-effective takes continuous improvement. Today we take **TrailMate**, an outdoor-gear support agent, up the hill one change at a time.

| Stage | Where | What we do | Version |
|:------|:------|:-----------|:--------|
| 1 Setup | VS Code | Get ready, check everything works | v0 |
| 2 Kick-off | VS Code | Create v1 and start the optimizer, so it works while we explore | v1 |
| 3 Know the concepts | Foundry portal | Compare models, try the model router | |
| 4 Make it work | Foundry portal | Take TrailMate for a spin, read traces | v1 |
| 5 Make it better | VS Code | Insights, a rubric, the agent optimizer | v2 |
| 6 Keep improving | VS Code | Right-size models with the model router | v3 |
| 7 Wrap | | Look back at the climb | |

## How to use these pages

1. [] Note the page number in each title, like **3.2**. If we get stuck, we raise a hand and say "page 3.2, step 4".
1. [] Text shown +++like this+++ is **type text**: click it to type it into the virtual machine where the cursor is.
1. [] Text shown ++like this++ is **copy text**: click it to copy, then paste it yourself.
1. [] Each step has a checkbox. Checking the last box on a page checks the ones above it.

> [!Hint] **Stuck? Ask Copilot first.** Many pages have a **Copilot prompt** to paste into Copilot Chat. It can explain an error or a result faster than waiting for help. We set up Copilot Chat in the next stage, on page 1.2.

---

> [!Note] **Success:** We just learned the route up the hill and how to say exactly where we are. Next, we set up our development environment and GitHub Copilot Chat.

===

# 1.1 Set up the local environment

**What we'll do:** Confirm the lab deployed our Azure resources and set up our local `.env` file, open the lab in VS Code, and sign in to Azure.

## Check the environment status

The desktop has two text files: one starting with **LAB663** and one with **lab663**. Double-click each to open it in an editor.

1. [] Open **LAB663-deployment-output.txt**, the deployment summary. Check that it says **Result: SUCCEEDED**.

    ![The deployment summary showing Result: SUCCEEDED and the Foundry project details](https://raw.githubusercontent.com/nitya/ignite26-LAB663/main/instructions/skillable/screenshots/01-setup-01-status-file.png)

1. [] Open the **lab663-deploy-...** file, the run log. Find the line **Populated .env with the deployment settings**.

    ![The run log with the Populated .env line highlighted](https://raw.githubusercontent.com/nitya/ignite26-LAB663/main/instructions/skillable/screenshots/01-setup-01-run-log.png)

> [+Hint] It says RUNNING or FAILED
>
> **RUNNING:** the lab is still preparing. Wait a few minutes and open the file again. **FAILED:** don't continue. Raise your hand and share the **Stage** line.

## Open the lab in VS Code

1. [] Open **Visual Studio Code** from the desktop and check that the Explorer shows the **LAB663** folder. If a pop-up offers to install the **Dev Containers** extension, close it. If asked whether you trust the authors, select **Yes**.

    ![VS Code open on the LAB663 folder, with the Dev Containers pop-up at the bottom right](https://raw.githubusercontent.com/nitya/ignite26-LAB663/main/instructions/skillable/screenshots/01-setup-01-vscode-open.png)

1. [] Open a terminal with **Terminal > New Terminal**, or press **Ctrl+Shift+backtick**. If you don't see the **Terminal** menu, it's under **...** in the menu bar.

## Sign in to Azure

1. [] In the terminal, run this command. It prints a link and a code.

    ++az login --tenant @lab.CloudSubscription.TenantId --use-device-code++

    ![The terminal showing the device login link and code](https://raw.githubusercontent.com/nitya/ignite26-LAB663/main/instructions/skillable/screenshots/01-setup-01-az-login-code.png)

1. [] Copy the code, then open the link in Edge and paste it. Pick the lab account you used on page 0.1.
1. [] When asked to approve the sign-in, select **Approve**. Then close the browser tab and return to VS Code.

    ![The Approve sign-in on another device page, with the Approve button](https://raw.githubusercontent.com/nitya/ignite26-LAB663/main/instructions/skillable/screenshots/01-setup-01-az-login-approve.png)

1. [] In the terminal, type **1**, or press **Enter**, to keep the default subscription marked with **\***.

    ![The terminal listing the lab subscription, marked as the default](https://raw.githubusercontent.com/nitya/ignite26-LAB663/main/instructions/skillable/screenshots/01-setup-01-az-login.png)

---

> [!Note] **Success:** We just confirmed our resources and `.env` are ready, opened the lab, and signed in to Azure.

===

# 1.2 Set up GitHub Copilot Chat

**What we'll do:** Sign in to GitHub Copilot in VS Code, connect it to Foundry, and check it can see our project.

## Sign in to GitHub Copilot

1. [] In VS Code, click the blue **Sign in** button in the top bar, then select **Continue with GitHub**.

    ![The Sign in to use GitHub Copilot dialog with Continue with GitHub](https://raw.githubusercontent.com/nitya/ignite26-LAB663/main/instructions/skillable/screenshots/01-setup-02-continue-with-github.png)

1. [] In the browser, select **Continue**, then authorize **Visual Studio Code**.
1. [] When the browser offers to open VS Code, select **Open**, or just switch back to VS Code.
1. [] Check that the profile icon at the bottom left shows your GitHub sign-in.

## Get Copilot Chat ready

1. [] In the Copilot Chat window, send just this message and wait for a reply.

    ++Hello++

1. [] In the chat box, switch the model to **Claude Opus 5.5**.
1. [] Switch **Default permissions** to **Allow all**, so Copilot doesn't stop to ask before each tool call. Select **Enable** when asked to confirm.

    ![The permissions menu with Allow all selected](https://raw.githubusercontent.com/nitya/ignite26-LAB663/main/instructions/skillable/screenshots/01-setup-02-allow-all.png)

## Connect Copilot to Foundry

1. [] Above Copilot's reply, click **Completed 2 steps** to expand it, then click **Start it now?** next to **Foundry MCP**.

    ![The expanded steps with the Start it now link for the Foundry MCP server](https://raw.githubusercontent.com/nitya/ignite26-LAB663/main/instructions/skillable/screenshots/01-setup-02-start-foundry-mcp.png)

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

    ![Copilot Chat listing the trailmate agent in the Foundry project](https://raw.githubusercontent.com/nitya/ignite26-LAB663/main/instructions/skillable/screenshots/01-setup-02-copilot-agents.png)

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

    ![The notebook open with the kernel picker showing .venv (3.13.14) and the Outline listing sections 1.1 to 1.10](https://raw.githubusercontent.com/nitya/ignite26-LAB663/main/instructions/skillable/screenshots/01-setup-03-select-kernel.png)

1. [] Click **Run All** at the top of the notebook.
1. [] In the Outline, click **1.10 So, is my camp ready?** and wait there until it prints **Overall: PASS. Our camp is ready.** This takes a minute or two.

    ![Section 1.10 showing 27 of 27 checks passed and Overall: PASS](https://raw.githubusercontent.com/nitya/ignite26-LAB663/main/instructions/skillable/screenshots/01-setup-03-scorecard.png)

> [!Knowledge] The "Error we expected" line in section 1.11 is there on purpose. It shows what a failure looks like.

> [+Hint] Copilot prompt: a check failed
>
> New role assignments can take up to 10 minutes. Wait, then rerun the failed cell. To understand the error, paste this into Copilot Chat with the message:
>
> ++In notebook 01, this check failed with the message below. What does it mean, and what should I try? Don't change any files.++

---

> [!Note] **Success:** We just proved our project, models, router editions, agent, and tracing all work under our lab account.

===

# 2.1 Create v1 and leave traces

**What we'll do:** Change one lever, the instructions, to create TrailMate **v1**, then ask it 12 practice questions so it leaves traces for Foundry to analyze.

> [!Knowledge] **Why now?** The agent optimizer takes several minutes. On these two pages we get it started, so it works while we explore the Foundry portal.

1. [] In the Explorer, open **labs > core > 04-make-it-work.ipynb**.
1. [] Select the **.venv (3.13.14)** kernel, the same way as on page 1.3. We use the **Outline** to jump to each section below.
1. [] Run the first code cell (click it, then **Shift+Enter**). Confirm it prints **Connected. 12 practice questions ready.**
1. [] Jump to section **4.3** and run its code cell to create the insights monitor.
1. [] Jump to section **4.4** and run its code cell. Confirm it prints **Saved. TrailMate v1 is Foundry version** followed by a number.
1. [] Jump to section **4.5** and run its code cell. Wait until all 12 questions print **done**.

    <!-- TODO screenshot: 02-kickoff-01-practice-done.png | Section 4.5 output with all 12 practice questions marked done -->

1. [] Jump to section **4.7** and run its code cell. It pauses for one minute so the traces can arrive.

> [+Hint] Copilot prompt: what did v1 change?
>
> ++Compare src/agent/instructions-v0.md with src/agent/instructions-v1.md. In three bullets, what changed and why might it help?++

---

> [!Note] **Success:** We just created TrailMate v1 and gave Foundry 12 conversations' worth of traces to learn from.

===

# 2.2 Start the optimizer

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

> [!Knowledge] These are risks we expect, written ahead of time so the optimizer can start early. On page 5.1 we'll check them against what Foundry actually finds.

## Start the optimizer

1. [] In the Explorer, open **labs > core > 05-make-it-better.ipynb**.
1. [] Select the **.venv (3.13.14)** kernel, the same way as on page 1.3.

1. [] Run the first code cell. Confirm it prints the v0 and v1 version numbers.
1. [] Jump to section **5.2** and run its code cell. Wait for **Rubric created**.
1. [] Jump to section **5.4** and run its two code cells. Confirm you see **Datasets** and **Evaluation ready**.
1. [] Jump to section **5.6** and run the estimate cell. It shows call counts and a cost range.
1. [] Run the next code cell to start the job. When it prints **Optimization job:** and status lines, **leave it running**.

    <!-- TODO screenshot: 02-kickoff-02-optimizer-running.png | Section 5.6 printing the optimization job ID and running status lines -->

> [+Hint] Rubric generation fails or finds no traces
>
> The traces may still be arriving. Wait one minute, then run the section 5.2 cell again. Don't rerun section 4.5.

---

> [!Note] **Success:** We just started the agent optimizer. It keeps working in Foundry while we head to the portal.

===

# 3.1 Compare a big and a small model

**What we'll do:** Send the same two questions to a big and a small model, and see how model choice changes speed, tokens, and quality.

1. [] In Edge, switch to the **Foundry portal** tab we opened on page 0.1 and select the **trailmate** project.
1. [] Open the model playground for **gpt-5.4** and turn on **Compare** with **gpt-5.4-mini**.

    <!-- TODO screenshot: 03-concepts-01-compare-setup.png | The model playground in compare view with gpt-5.4 and gpt-5.4-mini -->
    <!-- VERIFY: exact navigation to the model playground and the Compare button -->

1. [] Send this easy question.

    ++TrailLite Daypack specs: Weight 1.5 lbs, Dimensions 20in x 12in x 6in, Water-resistant fabric. How much does the TrailLite Daypack weigh?++

1. [] Send this harder question. Watch for the trap: one TrailMaster X4 can't sleep six.

    ++TrailMaster X4 Tent: 4-person, 12 lbs, $250, rainfly rated 2000mm. Alpine Explorer Tent: 8-person, 17 lbs, $350, rainfly rated 3000mm. A family of six is camping in heavy rain, wants the lightest setup possible, and has a tight budget. Weigh the trade-offs and recommend one.++

1. [] Compare the two answers, response times, and token counts.

    <!-- TODO screenshot: 03-concepts-01-compare-answers.png | Both models answering the tent question, with time and tokens visible -->

> [!Knowledge] The best answer is one Alpine Explorer: two X4s weigh 24 lbs and cost $500. Did the small model catch that? The real question isn't "which model is best?" but "which questions need the big one?"

---

> [!Note] **Success:** We just saw that a small model can be faster and cheaper, and where it can fall short.

===

# 3.2 Let a router choose

**What we'll do:** Send the same two questions to a **model router** and see which model it picks for each.

> [!Knowledge] A **model router** is one deployment that looks at each request and sends it to a model from a pool. Easy work can go to a small model, and hard work to a bigger one.

1. [] In the playground, switch the deployment to **mr-default** and turn off compare.

    <!-- VERIFY: how to switch deployments in the playground -->

1. [] Send the easy daypack question again.

    ++TrailLite Daypack specs: Weight 1.5 lbs, Dimensions 20in x 12in x 6in, Water-resistant fabric. How much does the TrailLite Daypack weigh?++

1. [] Find which model answered. Look in the response details for the **model** name.

    <!-- TODO screenshot: 03-concepts-02-router-easy.png | Router response details showing the model chosen for the easy question -->
    <!-- VERIFY: where the playground shows the routed model -->

1. [] Send the harder tent question and find which model answered it.

    ++TrailMaster X4 Tent: 4-person, 12 lbs, $250, rainfly rated 2000mm. Alpine Explorer Tent: 8-person, 17 lbs, $350, rainfly rated 3000mm. A family of six is camping in heavy rain, wants the lightest setup possible, and has a tight budget. Weigh the trade-offs and recommend one.++

    <!-- TODO screenshot: 03-concepts-02-router-hard.png | Router response details showing the model chosen for the hard question -->

> [+Hint] Copilot prompt: how does routing decide?
>
> ++In two short paragraphs, how does Microsoft Foundry model router decide which model handles a request?++

---

> [!Note] **Success:** We just watched one deployment pick a model per question, without us choosing.

===

# 3.3 Turn the cost-quality dial

**What we'll do:** Send the hard question to a router in **cost** mode and one in **quality** mode, and compare their choices.

1. [] Open **mr-cost** in the playground and turn on **Compare** with **mr-quality**.
1. [] Send the tent question.

    ++TrailMaster X4 Tent: 4-person, 12 lbs, $250, rainfly rated 2000mm. Alpine Explorer Tent: 8-person, 17 lbs, $350, rainfly rated 3000mm. A family of six is camping in heavy rain, wants the lightest setup possible, and has a tight budget. Weigh the trade-offs and recommend one.++

1. [] Note which model each router picked.
1. [] Check that both recommend one Alpine Explorer.

    <!-- TODO screenshot: 03-concepts-03-cost-vs-quality.png | mr-cost and mr-quality answering side by side, with the model each one chose -->
    <!-- VERIFY: mr-cost and mr-quality pick different models for this prompt -->

> [!Knowledge] The routing mode is a dial between cost and quality. If both picked the same model, that's a real result too. A cheaper pick only wins if the answer stays right, and that's exactly what we'll measure on page 6.1.

---

> [!Note] **Success:** We just saw how one setting shifts a router between cheaper and stronger models.

===

# 4.1 Take TrailMate for a spin

**What we'll do:** Meet TrailMate in the agent playground. It's already built and deployed on **gpt-5.4**, and it answers from ten product manuals.

1. [] In the Foundry portal, open **Agents** and select **trailmate**.
1. [] Check the version selector and switch to the newest version. That's the **v1** we created on page 2.1.

    <!-- TODO screenshot: 04-work-01-version-v1.png | The trailmate agent with the version selector set to v1 -->
    <!-- VERIFY: the agent page shows a version selector, and the newest version is v1. Check that the optimizer's candidate agent doesn't confuse this view. -->

1. [] In the playground, ask a question it should handle well.

    ++Which tent sleeps 8 people, the TrailMaster X4 or the Alpine Explorer?++

1. [] Now ask a question where agents often overclaim. The manual says **water-resistant**, not waterproof.

    ++Is the Summit Breeze Jacket waterproof?++

    <!-- TODO screenshot: 04-work-01-playground-answers.png | The agent playground with TrailMate's answers to both questions -->

1. [] Decide for yourself: did TrailMate keep the word "water-resistant", or did it upgrade the claim?

---

> [!Note] **Success:** We just tried TrailMate v1 and judged two answers against the manual ourselves.

===

# 4.2 Read a trace

**What we'll do:** Open the trace behind an answer to see how TrailMate produced it: what it searched, what it found, and what it cost.

1. [] In the agent playground, open the trace for the jacket answer.

    <!-- VERIFY: where to open the trace from a playground response -->

1. [] Find the **file search** step and read which manual passages it retrieved.
1. [] Note the token count and latency for the response.

    <!-- TODO screenshot: 04-work-02-trace.png | The trace for the jacket answer, with the file search step, tokens, and latency -->

> [!Knowledge] A **trace** is the step-by-step record of one answer. If an answer is wrong, the trace tells us whether the search missed the right passage or the model misread it. Those are two different fixes.

> [+Hint] Copilot prompt: read the trace with me
>
> ++/microsoft-foundry Find the most recent trace for my trailmate agent and explain, step by step, how it answered. Do not change anything.++

---

> [!Note] **Success:** We just traced one answer back to the manual passages it came from.

===

# 4.3 Check the monitor

**What we'll do:** Zoom out from one answer to all of them, then check on the optimizer.

1. [] On the trailmate agent page, open the **Monitor** tab.
1. [] Look at runs, token usage, and any failures. The 12 practice questions from page 2.1 are in here too.

    <!-- TODO screenshot: 04-work-03-monitor.png | The Monitor tab with agent runs and token usage -->
    <!-- VERIFY: Monitor tab location and whether data appears within a few minutes -->

1. [] Switch to VS Code and look at the running cell in **05-make-it-better.ipynb**. Its latest line shows the optimizer's status.

    <!-- VERIFY: add a periodic status check here if the dry run shows it's useful -->

> [!Knowledge] Our agent works, but "works" isn't the same as "reliable". From here on we stop judging answers one at a time and start measuring them all.

---

> [!Note] **Success:** We just saw the whole agent at a glance and checked our optimizer is still climbing.

===

# 5.1 Read the insights

**What we'll do:** Ask Foundry what's wrong across all of TrailMate's traces, and compare its findings with our starting gap list.

1. [] In VS Code, switch to **04-make-it-work.ipynb**.
1. [] Jump to section **4.8** and run its first code cell. The analysis usually takes a few minutes.

    <!-- TODO screenshot: 05-better-01-insights-complete.png | A completed insights run, to read while yours finishes -->

1. [] Run the next two code cells to see the findings table and Foundry's descriptions.

    <!-- TODO screenshot: 05-better-01-insights-table.png | The findings table with severity, category, and trace counts -->

1. [] Compare the findings with the three gaps we saved on page 2.2. Which did Foundry confirm? What did it find that we missed?
1. [] Jump to section **4.10** and run its code cell.

> [!Alert] Don't rerun the section 4.9 cell. Our rubric and optimizer already use the gaps saved there.

> [+Hint] Copilot prompt: explain the findings
>
> ++Explain the insights in section 4.8 of notebook 04 in plain language. Which finding should we fix first, and why?++

---

> [!Note] **Success:** We just let Foundry find patterns across every trace, and checked our guesses against its evidence.

===

# 5.2 Turn good into a number

**What we'll do:** Read the rubric Foundry drafted from our traces and gaps, then use it to score **v0** and **v1** on the same questions.

1. [] Switch to **05-make-it-better.ipynb**. If the optimizer cell in section 5.6 is still running, click the **stop** button next to it.

    > [!Note] Stopping the cell only stops the notebook from waiting. The optimizer job keeps running in Foundry, and we'll pick it up again on page 5.3.

    <!-- VERIFY: interrupting the wait doesn't cancel the optimizer job -->

1. [] Jump to section **5.3** and run its two code cells. Read the generated rubric next to our reference rubric.
1. [] Ask yourself: would it catch "water-resistant" becoming "waterproof"?
1. [] Jump to section **5.5** and run its two code cells to score v0 and v1 twice each. It takes a few minutes.
1. [] Confirm the scoreboard has two rows, each with a score, a spread, and **errored** at 0.

    <!-- TODO screenshot: 05-better-02-scoreboard.png | The v0 and v1 scoreboard and the per-category table -->

> [+Hint] Copilot prompt: what does the rubric measure?
>
> ++Explain each dimension of the rubric printed in section 5.3 of notebook 05, in one line each.++

---

> [!Note] **Success:** We just turned "good" into a number, using a ruler we checked ourselves.

===

# 5.3 Let the optimizer climb

**What we'll do:** Pick up the optimizer job, read the instructions it proposed, and check that the winner isn't just more cautious.

1. [] Jump to section **5.6** and run the job cell again. It resumes the saved job without starting a new one, and prints **Finished** with the best and baseline scores.

    <!-- TODO screenshot: 05-better-03-optimizer-finished.png | The optimizer cell printing Finished with best and baseline scores -->

    > [+Hint] Still running? Read a finished run
    >
    > Here's what a completed run looks like. Read it while ours finishes.
    >
    > <!-- TODO screenshot: 05-better-03-completed-candidates.png | A completed optimizer run in the portal, listing its candidates and scores -->

1. [] Jump to section **5.7** and run its two code cells. Read each candidate's score, then read the winning instructions in full.
1. [] Jump to section **5.8** and run its code cell. It stages the winner as a separate candidate agent. Nothing is promoted yet.
1. [] Jump to section **5.9** and run its code cell. Check the guard-case answers against the manual.

> [!Knowledge] A timid agent never invents anything, but it's also useless. Guard cases are questions the manuals *do* answer, so a candidate that just refuses fails them.

> [+Hint] Copilot prompt: check the optimizer
>
> ++/microsoft-foundry What is the status of the most recent agent optimization job for my trailmate agent? Do not change anything.++

---

> [!Note] **Success:** We just read what the optimizer changed and checked it still answers what it should.

===

# 5.4 Decide whether to promote

**What we'll do:** Test v0, v1, and the candidate on questions the optimizer never saw, then make an explicit promote-or-retain decision for **v2**.

1. [] Jump to section **5.10** and run its two code cells. It takes a few minutes. Confirm the board has rows for v0, v1, and the v2 candidate.
1. [] Run section **5.11** and compare the gain on questions the optimizer trained on with the gain on questions it never saw.

    <!-- TODO screenshot: 05-better-04-heldout.png | Section 5.11 comparing dev gain with test gain -->

1. [] In section **5.12**, set `REVIEW_APPROVED = True` only if the instructions, guard answers, and scores hold up. Then run the cell and read the decision.

> [!Knowledge] The gain on trained questions is the gain the optimizer wanted. The gain on unseen questions is the gain we can trust. If the candidate doesn't pass, keeping v1 as our v2 checkpoint is a correct result.

---

> [!Note] **Success:** We just made a promote-or-retain decision backed by evidence, not by a single score.

===

# 6.1 Try a model router

**What we'll do:** Keep v2's instructions and change only the model, to the **mr-default** router. Then score it with the same rubric and questions.

1. [] In the Explorer, open **labs > core > 06-make-it-optimal.ipynb**.
1. [] Select the **.venv (3.13.14)** kernel, the same way as on page 1.3.

1. [] In the first code cell, leave `RUN_ALL_EDITIONS = False` and `TOLERANCE` as they are, then run it.
1. [] Run section **6.2** and note how many test questions are tagged easy.
1. [] Run section **6.3** and compare the models it shows with what you saw in the playground on pages 3.2 and 3.3.
1. [] Run section **6.4** to create the router candidate, then section **6.5** to score it. Scoring takes a few minutes.

    > [+Hint] While you wait: all four router editions
    >
    > We score only mr-default today. Here's a completed run with all four editions side by side.
    >
    > <!-- TODO screenshot: 06-improve-01-all-editions.png | A completed board comparing the baseline with all four router editions -->

1. [] Confirm the board has a baseline row and an **mr-default** row. If `valid` is False, that batch can't support a comparison.

    <!-- TODO screenshot: 06-improve-01-board.png | The section 6.5 board with the baseline and mr-default rows -->

---

> [!Note] **Success:** We just measured a router candidate with the same ruler as every earlier version.

===

# 6.2 Decide on the router

**What we'll do:** Find where the router slips, apply the decision rule we wrote before seeing any score, and decide on **v3**.

1. [] Run section **6.6** and compare scores by difficulty for the baseline and mr-default.
1. [] Run section **6.7**, then the held-out check cell below it.
1. [] Set `REVIEW_APPROVED = True` only after reading the actual answers and judge reasons. Then run the cell and read the decision.
1. [] Run section **6.8** to make a winner official, if there is one.

> [!Knowledge] Invalid coverage, a category that got worse, an unknown cost, or a pending review all mean we keep the baseline. That's a legitimate result, not a failed lab.

> [+Hint] Copilot prompt: help me decide
>
> ++Based on the outputs of sections 6.5 to 6.7 in notebook 06, explain the quality and cost trade-off of the router candidate in plain language.++

---

> [!Note] **Success:** We just made a router decision from complete evidence.

===

# 7.1 Finish the lab

**What we'll do:** Look back at the whole climb in one chart, and hand the environment back.

1. [] In **06-make-it-optimal.ipynb**, run section **6.9** to see the heatmap of v0, v1, v2, and v3 on the same held-out questions.

    <!-- TODO screenshot: 07-wrap-01-heatmap.png | The section 6.9 heatmap of the whole climb -->

1. [] Find the row that improved most from v0 to v2. That's the **quality** climb, from the instructions.
1. [] Check whether v3 held that line. That's the **cost** climb, from the router.
1. [] Find the lowest row. That's where our next experiment should go.
1. [] End the lab when your proctor says so, using the normal Skillable controls.

> [!Alert] Don't run infra/cleanup.sh or delete any resources. The lab removes them when it ends.

> [!Knowledge] We went from plan to prototype to production, then kept improving: one lever at a time, measured with a frozen ruler, with an explicit decision at every step. Keeping a version is often the right call.

---

> [!Note] **Success:** We just climbed from v0 to a measured decision, and we can explain why each step moved the score or didn't.

===

# 8.1 More: multi-model vs multi-modal

**What we'll do:** Use one model to look at a product photo and another to answer from the manuals, then build a tiny router by hand. This lab is optional.

1. [] In the Explorer, open **labs > core > 03-multi-model-vs-multimodal.ipynb**.
1. [] Select the **.venv (3.13.14)** kernel, the same way as on page 1.3.

1. [] In section **3.2**, leave `COMPARE_ALL_PHOTOS = False` to keep it to one photo, then run the section.
1. [] Run sections **3.3** to **3.5** and compare your homemade router's labels with the tagged ones.

> [!Knowledge] Multi-modal is about what comes in, like a photo. Multi-model is about who handles which step. The model router does the second part for us.

---

> [!Note] **Success:** We just chained two models on a photo question and measured a router we built ourselves.

===

# 8.2 More: explore MAI models

**What we'll do:** Read how Microsoft AI (MAI) models handle a product launch: pictures, a voice, transcripts, and a website. This lab is optional.

1. [] In the Explorer, open **labs > more > README.md**.
1. [] Open **00-set-the-stage.ipynb** from the **labs/more** folder and read the story.
1. [] Open any of notebooks **01** to **04** and read the saved results.

> [!Note] Every More notebook comes pre-run, so reading one needs no setup and costs nothing. The image models aren't in this lab environment, so run them live later with your own subscription.

---

> [!Note] **Success:** We just read at least one More notebook in replay mode.

===

# 9.1 Lab credentials and links

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
