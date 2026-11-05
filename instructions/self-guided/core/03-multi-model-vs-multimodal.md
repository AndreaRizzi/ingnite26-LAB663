<!-- sync: source=labs/core/03-multi-model-vs-multimodal.ipynb sections=3.2,3.3,3.4,3.5,3.6 -->

# Module 3: Multi-model vs multi-modal

**Notebook:** [03-multi-model-vs-multimodal.ipynb](../../../labs/core/03-multi-model-vs-multimodal.ipynb) · **Time:** about 8 minutes

**The question:** what's the difference between multi-model and multi-modal, and when do we need each?

A customer sends a photo and asks whether the product is waterproof. One model looks, another answers from the manuals. Then we build a tiny router by hand.

---

## Step 1: Choose the photo path (section 3.2)

Open [03-multi-model-vs-multimodal.ipynb](../../../labs/core/03-multi-model-vs-multimodal.ipynb). Before running 3.2, check `COMPARE_ALL_PHOTOS` in its first code cell:

- `False` keeps to the core path: one photo, two rows.
- `True` compares all three photos: six rows and extra billed calls.

**Expected:** a table with a guess and a correctness flag per row.

A wrong identification is part of the lesson, not a failed lab.

## Step 2: Chain two models (section 3.3)

A small vision model names the product, then TrailMate answers from the manuals.

**Expected:** the photo guess, an explicit warning if it disagrees with the lab label, and an answer about the **confirmed** product.

<!-- TODO(screenshot): m3-photo-chain.webp | section 3.3 output: photo guess, any warning, and the confirmed-product answer | crop to the cell output -->

## Step 3: Build a router by hand (section 3.4)

A small model labels each question `easy` or `hard`, and hard ones go to the big model.

**Expected:** a six-row table. Most rows tagged `easy` go to the small model.

Compare the router's label with the hand-written `tagged` column. Where they disagree, who's right?

## Step 4: Weigh the homemade router (section 3.5)

Read the four drawbacks: extra cost per request, our own opinion of "easy", ours to maintain, hard to trust. Module 6 replaces it with a managed model router and measures it.

## The aha (section 3.6)

> **Multi-modal** is about *what comes in*. **Multi-model** is about *who handles which step*.

## Checkpoint

- [ ] We saw a vision model identify (or misidentify) a product
- [ ] We chained two models and confirmed the product before answering
- [ ] We know why a hand-built router isn't enough

**Next:** [Module 4: Make it work](04-make-it-work.md)
