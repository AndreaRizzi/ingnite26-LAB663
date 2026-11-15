# 1.3 Validate the Azure environment

**What we'll do:** Run one notebook that checks every part of the setup, so any failure points at exactly one fix.

1. [] In VS Code, press **Ctrl+P**, paste this name, and press **Enter**.

    ++01-setup-and-validate.ipynb++

1. [] Click **Select Kernel** at the top right and select **.venv(3.13.14)(Python3.13.14)**.
1. [] Click **Run All** at the top of the notebook. It takes a minute or two.
1. [] Scroll to section **1.10 So, is my camp ready?** and confirm it prints **Overall: PASS. Our camp is ready.** The "Error we expected" line in section 1.11 is there on purpose.

    <!-- TODO screenshot: 01-setup-03-scorecard.png | The section 1.10 scorecard with every check passing -->

> [+Hint] Copilot prompt: a check failed
>
> New role assignments can take up to 10 minutes. Wait, then rerun the failed cell. To understand the error, paste this into Copilot Chat with the message:
>
> ++In notebook 01, this check failed with the message below. What does it mean, and what should I try? Don't change any files.++

---

> [!Note] **Success:** We just proved our project, models, router editions, agent, and tracing all work under our lab account.
