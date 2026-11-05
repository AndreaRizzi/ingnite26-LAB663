<!-- sync: source=labs/core/06-make-it-optimal.ipynb sections=6.1,6.2,6.3,6.4,6.5,6.6,6.7,6.8,6.9,6.12 -->
# Try a model router

Change the model, not the instructions: swap the single model for a model router and measure it. Module 6 targets about 14 minutes.

1. [] In VS Code, press **Ctrl+P**, open this notebook, and select the **Python (LAB663)** kernel.

   ++06-make-it-optimal.ipynb++

1. [] In section 6.1, leave RUN_ALL_EDITIONS set to False so you compare mr-default only, and leave TOLERANCE as it is.

   > [!Knowledge] The rule is fixed before you see any score. True compares all four editions and adds six evaluation runs, so save it for later.

1. [] Run section 6.1 and confirm it loads the rubric, datasets and baseline from Module 5.
1. [] In section 6.2, confirm five of the twelve test questions are tagged easy.
1. [] In section 6.3, confirm you see the model that served each probe, and compare it with your guess from Module 1.
1. [] Run section 6.4 to create the router candidate, then section 6.5 to score it.

   > [!Knowledge] While you wait, read the box about failed requests. A case that never got a score isn't a cheap answer.

1. [] Confirm you see a baseline row and an mr-default row. valid=False means that batch can't support a comparison.

> [!Note] *Success:* you have a router candidate scored with the same rubric and questions as the baseline.

===

# Decide on the router

Find where the router slips, then make an explicit keep-or-promote decision.

1. [] In section 6.6, compare scores by difficulty for the baseline and mr-default.
1. [] In section 6.7, run the decision rule and the held-out check.
1. [] Set REVIEW_APPROVED to True only after reading the actual answers and judge evidence, then run the cell.
1. [] Confirm you see an explicit decision.

   > [!Knowledge] Invalid coverage, a category regression, unknown cost or pending review all mean you keep the baseline. That's a legitimate result.

1. [] Run sections 6.8 and 6.9 and read the heatmap of the whole climb.

> [!Knowledge] The aha in section 6.12: routing is a hypothesis, not a guaranteed saving. Complete evidence and verified prices tell you whether the trade-off is acceptable.

> [!Note] *Success:* you made a router decision from complete evidence and saw the whole climb in one chart.

===

# Finish the lab

Wrap up and hand the environment back.

1. [] Read the final scoreboard. Retaining the original baseline is the correct outcome when the evidence doesn't support a change.
1. [] Tell the proctor your timings and any failed check messages.
1. [] End the lab when instructed, using the normal Skillable controls.

> [!Alert] Don't run infra/cleanup.sh, purge accounts, or delete the resource group. The lab removes your resources when it ends.

> [!Note] *Success:* you climbed from v0 to a measured decision, and you can explain why each step moved the score or didn't.
