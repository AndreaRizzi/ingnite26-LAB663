# 6.1 Turn good into a number

**What we'll do:** Connect our rubric to the insights, then use it to score **v0** and **v1** on the same questions.

1. [] Switch to **05-make-it-better.ipynb**. If the optimizer cell in section 5.6 is still running, click the **stop** button next to it.

    > [!Note] Stopping the cell only stops the notebook from waiting. The optimizer job keeps running in Foundry, and we'll pick it up again on page 6.2.

    > [+Hint] I see "Ran into a deserialization error"
    >
    > This is a warning from the Azure SDK, not a failure. It tried to read a reply that had no body and ignored it. If the optimizer run still finished on the **Optimize** tab, it's safe to ignore. If something else looks wrong, paste the message into Copilot Chat and ask what it means.

1. [] Recall the rubric dimensions from page 3.2, and match them to what we've seen since. Your rubric may have different dimensions from ours, so look for the same ideas:
    - **source_grounded_answer** and **missing_or_conflicting_evidence_handling** cover the hallucination insights and our "making things up" gap.
    - **semantic_claim_precision** names our overclaiming gap: "water-resistant" becoming "waterproof".
    - **scope_and_role_adherence** says off-topic requests should be declined. The built-in evaluators and insights missed that the hot chocolate recipe was out of lane. Our rubric knows TrailMate's job.
1. [] Jump to section **5.5** and run its two code cells to score v0 and v1 twice each. It takes a few minutes. While it runs, switch to the Foundry portal and select **Evaluations** in the left menu to watch the runs appear under **TrailMate rubric evaluation**.

    > [+Hint] Section 5.5 shows an error
    >
    > Section **5.4** has two code cells, and both must run first. Jump back to 5.4, run the cell you missed, then run 5.5 again.
1. [] Confirm the scoreboard has two rows, each with a score, a spread, and **errored** at 0.

    <!-- TODO screenshot: 06-better-01-scoreboard.png | The v0 and v1 scoreboard and the per-category table -->

> [+Hint] OPTIONAL - Ask Copilot: summarize the scores
>
> ++In three bullets, summarize what the rubric in section 5.3 of labs/core/05-make-it-better.ipynb checks and how v0 and v1 scored in section 5.5. Don't change any files.++

---

> [!Note] **Success:** We just turned "good" into a number, using a ruler we checked ourselves.
