<!-- sync: source=labs/core/05-make-it-better.ipynb sections=5.1,5.2,5.3,5.4,5.5,5.6,5.7,5.8,5.9,5.10,5.11,5.12 -->

# Module 5: Make it better (v1 to v2)

**Notebook:** [05-make-it-better.ipynb](../../../labs/core/05-make-it-better.ipynb) · **Time:** about 14 minutes (a target until a timed run confirms it)

**The question:** how do we know our agent got *better*, and not just *different*?

We turn "good" into a number with a **rubric evaluator**, then let the **agent optimizer** propose rewrites and score them with our rubric. The promotion rule is declared before we see any score.

---

## Step 1: Generate the rubric (section 5.2)

Open [05-make-it-better.ipynb](../../../labs/core/05-make-it-better.ipynb) and run 5.1 and 5.2. Foundry drafts a rubric from our Module 4 traces and our gap list. It takes about 1 minute.

**Expected:** a rubric evaluator is created. Placeholder gaps are rejected before they reach the service.

## Step 2: Read the rubric (section 5.3)

Compare the generated rubric with our hand-written reference. Does it catch "water-resistant" becoming "waterproof"? Does it punish answering something that should have been declined?

## Step 3: Score v0 and v1 (sections 5.4 and 5.5)

Run 5.4 to upload the datasets and create the evaluation, then 5.5. Each version runs twice on the dev set. It takes about 3 minutes; read the **While you wait** box.

**Expected:** two rows (v0 and v1), each with a score, a spread, a token count and `errored` at 0.

<!-- TODO(screenshot): m5-baseline-scores.webp | section 5.5 two-row table for v0 and v1 | crop to the cell output -->

A gain smaller than the spread could just be noise. Every repeat must score all twelve questions; rerunning the cell resumes saved run IDs.

## Step 4: Let the optimizer climb (section 5.6)

First the cost estimate.

**Expected:** call counts and a cost range.

Then start the job once. It takes about 11 minutes. The helper saves its ID, reports progress and stops waiting after twenty minutes without cancelling. Rerun the cell to resume; don't resubmit.

## Step 5: Read what it changed (section 5.7)

**Expected:** each candidate with its score, and the winner's instructions in full.

Could a candidate score well by refusing too much? That's the trap.

## Step 6: Check for over-caution (sections 5.8 and 5.9)

5.8 stages the candidate as a separate agent; nothing is promoted yet. 5.9 runs the guard cases, which the manuals do answer.

**Expected:** answers to the guard cases. A hedge word is a review hint, not a verdict: check the answer against the manual.

## Step 7: Test on unseen questions (sections 5.10 and 5.11)

**Expected:** one column per version (v0, v1, v2) and one row per way we lose trust, then the gain on trained questions next to the gain on unseen ones.

## Step 8: Decide (section 5.12)

Read the instructions, guard answers and judge reasons. Set `REVIEW_APPROVED = True` only if they hold up.

**Expected:** an explicit decision. If the candidate doesn't pass, keeping v1 **is** the v2 checkpoint, and that's a correct result.

## The aha (section 5.11)

> The gain on questions the optimizer trained on is the gain it *wanted*. The gain on questions it never saw is the gain we can *trust*.

<details>
<summary>Optional: see it in the portal</summary>

The optimizer run appears under the agent's **Optimize** tab, with each candidate's score and changes.

<!-- TODO(screenshot): m5-rubric.webp | Foundry portal > Evaluators, the generated rubric's dimensions | hide the publisher or user alias -->

<!-- TODO(screenshot): m5-optimizer-candidates.webp | Foundry portal > trailmate agent > Optimize, the run's candidates with scores | hide account and resource names -->

</details>

## Checkpoint

- [ ] We read the rubric before trusting it
- [ ] Every batch scored all twelve questions, or we know which run failed
- [ ] We made an explicit promote-or-retain decision

**Next:** [Module 6: Make it optimal](06-make-it-optimal.md)
