<!-- sync: source=labs/core/02-model-selection.ipynb sections=2.2,2.3,2.4,2.5,2.6,2.8 -->

# Module 2: Choosing a model

**Notebook:** [02-model-selection.ipynb](../../../labs/core/02-model-selection.ipynb) · **Time:** about 8 minutes

**The question:** which model should we use?

We send the same three questions (easy, medium, hard) to both chat models and compare speed, tokens, cost and the answers themselves.

---

## Step 1: Predict (section 2.2)

Open [02-model-selection.ipynb](../../../labs/core/02-model-selection.ipynb) and run the cells up to 2.2. Before going further, guess: which question will the small model get wrong, if any? Which will be fastest?

**Expected:** three questions printed, labeled easy, medium and hard.

## Step 2: Compare speed and tokens (section 2.3)

**Expected:** a six-row table: three questions, two models. Exact numbers vary from run to run.

<!-- TODO(screenshot): m2-speed-tokens.webp | section 2.3 six-row table of seconds and tokens | crop to the cell output -->

Input tokens match for both models, because we sent the same manuals. The model we choose changes what those tokens cost.

## Step 3: Read the answers (section 2.4)

**Expected:** two answers per question. The easy one should read much the same from both models.

Check the prediction. Would a customer be happy with each answer?

## Step 4: Look at cost (section 2.5)

Prices come from `data/pricing.json`, a dated list-price snapshot for one region (`eastus`).

**Expected:** dollar figures if we deployed to `eastus`. In any other region the cell shows no dollars, because a price from another region isn't a verified price. That's the correct result, not a bug.

## Step 5: Skip or try reasoning effort (section 2.6, optional)

This cell makes extra billed calls. Skip it in the timed core. If we run it:

**Expected:** a low and a high row with an answer each, or a one-line message if the deployment doesn't accept the setting.

## The aha (section 2.8)

> "Which model is best?" was the wrong question. The right one is "**which of our questions need the big model?**"

## Checkpoint

- [ ] We compared both models on the same three questions
- [ ] We read the answers, not just the numbers
- [ ] We know why the cost cell may show no dollars

**Next:** [Module 3: Multi-model vs multi-modal](03-multi-model-vs-multimodal.md)
