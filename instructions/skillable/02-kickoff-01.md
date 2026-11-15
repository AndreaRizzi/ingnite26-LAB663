# 2.1 Create v1 and leave traces

**What we'll do:** Change one lever, the instructions, to create TrailMate **v1**, then ask it 12 practice questions so it leaves traces for Foundry to analyze.

> [!Knowledge] **Why now?** The agent optimizer takes several minutes. On these two pages we get it started, so it works while we explore the Foundry portal.

1. [] In VS Code, press **Ctrl+P**, open this notebook, and select the **.venv(3.13.14)(Python3.13.14)** kernel.

    ++04-make-it-work.ipynb++

1. [] Open the **Outline** view in the Explorer sidebar. We use it to jump between numbered sections.
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
