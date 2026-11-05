<!-- sync: source=labs/more/README.md sections= -->

# More: Explore Microsoft AI models (optional)

**Notebooks:** [labs/more/](../../../labs/more/README.md) · **Time:** your choice. Each notebook shows its own review and run time

**The question:** what can MAI models do for a real product launch?

The same company, Contoso Outdoors, relaunches the TrailMaster X4 tent. Each notebook gives one job to one MAI model family: pictures, a voice, transcripts and a website.

---

## Step 1: Read them in replay mode

Open [labs/more/README.md](../../../labs/more/README.md), then [00-set-the-stage.ipynb](../../../labs/more/00-set-the-stage.ipynb).

Every notebook comes pre-run. Reading the saved results needs no Azure and costs nothing, so it's a good use of a long wait in the core lab.

**Expected:** saved images, audio and tables appear without running any cell.

<!-- TODO(screenshot): more-replay.webp | a More notebook in replay mode showing saved results | crop to one section -->

## Step 2: Run one live (at home)

`deploy.sh` already deployed the image models and gave us access to voice and transcription.

1. In the notebook's **Before you start** section, set `DEMO_MODE = "live"` in the mode cell. To switch every notebook at once, add `DEMO_MODE=live` to the repo's `.env` instead.
1. Run the cells in order with **Shift+Enter**.

Notebook 04 builds a website, so it also needs Node.js and npm. The dev container includes them.

**Expected:** our own results saved under `labs/more/output/`, shown before the saved examples.

> [!NOTE]
> We pay per picture, per character spoken and per hour transcribed. Every run differs from ours, so judge results with each section's checklist.

## Checkpoint

- [ ] We read at least one More notebook in replay mode
- [ ] We know how to switch a notebook to live

**Back to:** [Self-guided walkthrough](../README.md)
