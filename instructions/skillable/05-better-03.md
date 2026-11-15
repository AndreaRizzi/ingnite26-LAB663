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
