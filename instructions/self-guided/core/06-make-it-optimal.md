<!-- sync: source=labs/core/06-make-it-optimal.ipynb sections=6.1,6.2,6.3,6.4,6.5,6.6,6.7,6.8,6.9,6.12 -->

# Module 6: Make it optimal (v2 to v3)

**Notebook:** [06-make-it-optimal.ipynb](../../../labs/core/06-make-it-optimal.ipynb) · **Time:** about 14 minutes (a target until a timed run confirms it)

**The question:** can we cut our model bill without losing quality?

This time we change the **model**, not the instructions. We swap the single model for a **model router** and ask: did quality hold, and did cost go down?

---

## Step 1: Declare the experiment (section 6.1)

Open [06-make-it-optimal.ipynb](../../../labs/core/06-make-it-optimal.ipynb). In the first code cell, decide before running:

- `RUN_ALL_EDITIONS = False` compares `mr-default` only. That's the core path.
- `True` compares all four editions and adds six evaluation runs.

Leave `TOLERANCE` as it is. The rule is fixed before we see any score.

**Expected:** the notebook loads the rubric, datasets and baseline saved in Module 5.

## Step 2: Count the easy questions (section 6.2)

**Expected:** a count of difficulty tags. Five of the twelve test questions are tagged easy. That's a teaching mix, not production traffic.

## Step 3: Watch a router decide (section 6.3)

**Expected:** one row per selected edition, with the model that served each probe.

<!-- TODO(screenshot): m6-router-picks.webp | section 6.3 table of serving models per probe | crop to the cell output -->

Compare with the guess from Module 1.

## Step 4: Score the router (sections 6.4 and 6.5)

6.4 creates a candidate with the baseline's instructions and tools and only the model changed. 6.5 scores it on dev, twice. Read the **While you wait** box; rerunning resumes saved run IDs.

**Expected:** a baseline row and one row per edition. `valid=False` means that batch can't support a comparison. Unknown prices mean unknown cost, not zero.

## Step 5: Find where it slips (section 6.6)

**Expected:** scores by difficulty for the baseline and each edition we ran.

## Step 6: Decide without fooling ourselves (section 6.7)

The rule picks a candidate, then checks it once on held-out questions. Set `REVIEW_APPROVED = True` only after reading the actual answers and judge evidence.

**Expected:** an explicit decision. Invalid coverage, a category regression, unknown cost or pending review all mean we keep the baseline, and that's a legitimate result.

## Step 7: See the whole climb (sections 6.8 and 6.9)

6.8 promotes only after the checks pass. 6.9 draws the climb.

**Expected:** a heatmap of the same held-out questions across versions and the six ways we lose trust.

<!-- TODO(screenshot): m6-climb-heatmap.webp | section 6.9 heatmap | crop to the chart -->

## The aha (section 6.12)

> Routing is a hypothesis, not a guaranteed saving. Complete per-case evidence and verified prices tell us whether the trade-off is acceptable.

<details>
<summary>Optional: see it in the portal</summary>

The staged candidates appear next to `trailmate` in the agent list.

<!-- TODO(screenshot): m6-agent-list.webp | Foundry portal > Agents, trailmate next to the staged optimizer and router candidates | hide account and resource names -->

</details>

## Clean up

When we're done with the core and any live More labs:

```bash
bash infra/cleanup.sh
```

It reads the resource group from `.env`, lists what's inside, and asks us to type the group's name. Then it deletes that one group and nothing else. Add `--purge` to purge the deleted Foundry resource too.

**Expected:** the resource group is deleted. Local `.env` and `.lab-state.json` stay, and are safe to delete.

## Checkpoint

- [ ] We declared the edition and tolerance before scoring
- [ ] We made an explicit keep-or-promote decision for the router
- [ ] We cleaned up, or know when we will

**Next:** [More: Explore Microsoft AI models](../more/00-explore-mai-models.md) (optional)
