<!-- sync: source=labs/core/05-make-it-better.ipynb sections=5.1,5.2,5.3,5.4,5.5,5.6,5.7,5.8,5.9,5.10,5.11,5.12 -->
# Turn good into a number

Build a rubric from your traces and gaps, then score v0 and v1 with it. Module 5 targets about 14 minutes.

1. [] In VS Code, press **Ctrl+P**, open this notebook, and select the **Python (LAB663)** kernel.

   ++05-make-it-better.ipynb++

1. [] Read the promotion rule at the top. It's declared before any score.
1. [] Run sections 5.1 and 5.2 to generate the rubric. It takes about 1 minute.
1. [] In section 5.3, compare the generated rubric with the reference rubric.

   > [!Knowledge] Ask yourself: does it catch "water-resistant" becoming "waterproof"? Does it punish answering something that should have been declined?

1. [] Run section 5.4 to upload the datasets and create the evaluation.
1. [] Run section 5.5 to score v0 and v1 twice each. It takes about 3 minutes.
1. [] Confirm you see two rows, each with a score, a spread, a token count, and errored at 0.

   > [!Knowledge] A gain smaller than the spread could just be noise. Rerunning the cell resumes saved run IDs.

> [!Note] *Success:* you have a rubric you've read and a measured score for v0 and v1.

===

# Let the optimizer climb

Let the agent optimizer propose new instructions, then check it didn't win by being timid.

1. [] In section 5.6, run the cost estimate and confirm it shows call counts and a cost range.
1. [] Start the optimizer once. It takes about 11 minutes.

   > [+Hint] The cell stopped waiting.
   >
   > The helper stops waiting after twenty minutes without cancelling the job. Rerun the cell to resume the saved ID. Don't resubmit.

1. [] In section 5.7, read each candidate's score and the winner's instructions in full.
1. [] Run section 5.8 to stage the candidate as a separate agent. Nothing is promoted yet.
1. [] In section 5.9, read the guard-case answers and check them against the manual.

> [!Knowledge] A cautious agent never invents anything, and it's also useless. Guard cases are questions the manuals do answer, so a timid candidate fails them.

> [!Note] *Success:* you read the winning instructions and checked the guard cases yourself.

===

# Decide whether to promote

Test on questions the optimizer never saw, then make an explicit decision.

1. [] Run section 5.10 and confirm you see one column per version, v0, v1 and v2, and one row per way we lose trust.
1. [] Run section 5.11 and compare the gain on trained questions with the gain on unseen questions.
1. [] In section 5.12, set REVIEW_APPROVED to True only if the instructions, guard answers and judge reasons hold up.
1. [] Run the cell and read the decision.

> [!Knowledge] If the candidate doesn't pass, keeping v1 is the v2 checkpoint, and that's a correct result.

> [!Knowledge] The aha in section 5.11: the gain on trained questions is the gain the optimizer wanted; the gain on unseen questions is the gain you can trust.

> [!Note] *Success:* you made an explicit promote-or-retain decision backed by complete evidence.
