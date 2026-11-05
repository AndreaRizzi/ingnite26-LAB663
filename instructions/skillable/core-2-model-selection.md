<!-- sync: source=labs/core/02-model-selection.ipynb sections=2.2,2.3,2.4,2.5,2.6,2.8 -->
# Compare two models

Send the same three questions to two models and compare speed, tokens, cost and answers. This takes about 8 minutes.

1. [] In VS Code, press **Ctrl+P**, open this notebook, and select the **Python (LAB663)** kernel.

   ++02-model-selection.ipynb++

1. [] Run the cells up to section 2.2, then guess which question the small model will get wrong, if any.
1. [] In section 2.3, confirm you see a six-row table: three questions, two models.
1. [] In section 2.4, read both answers to each question and check your guess.
1. [] In section 2.5, run the cost cell.

   > [!Knowledge] Prices in data/pricing.json are a dated snapshot for one region, eastus. In any other region the cell shows no dollar figures, because a price from another region isn't a verified price. That's the correct result.

1. [] Skip section 2.6 in the timed lab. It makes extra billed calls.

> [!Knowledge] The aha in section 2.8: the right question isn't "which model is best?" but "which of our questions need the big model?"

> [!Note] *Success:* you compared both models on the same questions and read the answers, not just the numbers.
