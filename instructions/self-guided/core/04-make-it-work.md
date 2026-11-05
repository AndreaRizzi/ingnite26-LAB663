<!-- sync: source=labs/core/04-make-it-work.ipynb sections=4.1,4.2,4.3,4.4,4.5,4.6,4.7,4.8,4.9,4.10 -->

# Module 4: Make it work (v0 to v1)

**Notebook:** [04-make-it-work.ipynb](../../../labs/core/04-make-it-work.ipynb) · **Time:** about 12 minutes

**The question:** how do we find out what's wrong with our agent without reading every answer?

We change one lever (the instructions) to make v1, send it practice questions so it leaves traces, and ask Foundry for **insights**.

> [!IMPORTANT]
> Modules 4, 5 and 6 share `.lab-state.json`. Run them in order, one at a time.

---

## Step 1: Watch v0 stumble (section 4.2)

Open [04-make-it-work.ipynb](../../../labs/core/04-make-it-work.ipynb). Predict which of the three questions v0 gets wrong, then run 4.1 and 4.2.

**Expected:** three answers. Note which were wrong facts, invented facts, or answers it should have declined.

## Step 2: Create v1 (section 4.4)

Run 4.3 to create or reuse the insights monitor. Then open `src/agent/instructions-v1.md`, read what changed, and run 4.4.

**Expected:** a saved v1 version ID, or the same ID on a rerun. v0 stays available.

## Step 3: Leave traces (section 4.5)

v1 answers all twelve practice questions.

**Expected:** progress for twelve questions.

While it runs, read the **While you wait** box about case `pr-04`: the manual says both "Rain cover included" and "Rain Cover: No". Don't edit `practice.jsonl`.

## Step 4: Form our own opinion (section 4.6)

Read the answers that worry us most and write down two or three problems in our own words. This list is what we compare with Foundry's.

## Step 5: Ask Foundry what's wrong (sections 4.7 and 4.8)

Section 4.7 pauses for one minute so traces can arrive. Then 4.8 starts an insights run. It usually takes about 3 minutes; use the wait to open a [More lab](../../../labs/more/README.md) in replay mode.

**Expected:** findings with severity and evidence counts, or an explicitly empty result.

An empty result is not a pass. Check `traces_analyzed` first. Set `START_NEW_INSIGHT_RUN = True` only after a completed run saw no traces and ingestion has caught up. Don't resend the practice questions.

## Step 6: Write down the gaps (section 4.9)

Compare our list with Foundry's. Then edit `our_gaps` in the next code cell: replace the three `"Replace me"` lines with gaps we actually saw, each starting with one of the six ways we lose trust.

**Expected:** the cell prints our gaps and saves them. It refuses to run while placeholder text remains, on purpose.

<!-- TODO(screenshot): m4-our-gaps.webp | section 4.9 our_gaps cell edited with three real gaps, and its output | crop to the cell -->

Stuck? Paste the insights output into Copilot Chat and ask for three gaps, then check each one against the answer and the manual before rewriting it in our own words.

## The aha (section 4.10)

> Reading answers and inspecting traces give different views of the same problem. Foundry groups the traces into **patterns with evidence**; we decide which pattern to treat first.

<details>
<summary>Optional: see it in the portal</summary>

In the `trailmate` agent, **Traces** lists every practice run and **Insights** shows each finding with its linked traces.

<!-- TODO(screenshot): m4-trace-list.webp | Foundry portal > trailmate agent > Traces after section 4.5 | hide account and resource names -->

<!-- TODO(screenshot): m4-insight.webp | Foundry portal > trailmate agent > Insights, one finding with its linked traces | hide account and resource names -->

</details>

## Checkpoint

- [ ] v1 is saved and v0 is unchanged
- [ ] The insights run analyzed our traces (or we know why it didn't)
- [ ] `our_gaps` holds real gaps, not placeholders

**Next:** [Module 5: Make it better](05-make-it-better.md)
