<!-- sync: source=labs/core/03-multi-model-vs-multimodal.ipynb sections=3.2,3.3,3.4,3.5,3.6 -->
# Separate multi-model from multi-modal

Use one model to look at a photo and another to answer from the manuals, then build a tiny router by hand. This takes about 8 minutes.

1. [] In VS Code, press **Ctrl+P**, open this notebook, and select the **Python (LAB663)** kernel.

   ++03-multi-model-vs-multimodal.ipynb++

1. [] In section 3.2, set COMPARE_ALL_PHOTOS in the first code cell before you run it.

   | Value | What runs |
   |:------|:----------|
   | ++False++ | The core path: one photo, two rows |
   | ++True++ | All three photos: six rows and extra billed calls |

1. [] Run section 3.2 and confirm each row has a guess and a correctness flag.

   > [!Knowledge] A wrong identification is part of the lesson, not a failed lab.

1. [] In section 3.3, confirm you see the photo guess, a warning if it disagrees with the lab label, and an answer about the confirmed product.
1. [] In section 3.4, confirm you see a six-row table, then compare the router's label with the tagged column.
1. [] In section 3.5, read why a hand-built router is costly, subjective and hard to trust.

> [!Knowledge] The aha in section 3.6: multi-modal is about what comes in; multi-model is about who handles which step.

> [!Note] *Success:* you chained two models on a photo question and measured your own router.
