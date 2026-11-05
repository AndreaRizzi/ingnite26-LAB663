<!-- sync: source=labs/core/01-setup-and-validate.ipynb sections=1.2,1.4,1.5,1.6,1.9,1.10,1.11,1.12 -->

# Module 1: Set up and validate

**Notebook:** [01-setup-and-validate.ipynb](../../../labs/core/01-setup-and-validate.ipynb) · **Time:** about 4 minutes

**The question:** how do we know our setup really works before we build on top of it?

We check every seam (settings, access, models, agent, tracing, data) on its own, so a failure names exactly what to fix.

---

## Step 1: Open the notebook

Open [01-setup-and-validate.ipynb](../../../labs/core/01-setup-and-validate.ipynb) and select the **.venv** kernel.

**Expected:** the notebook prints the Python interpreter it uses, and it's the repository `.venv`.

## Step 2: Run the checks one at a time

| Section | What we check | Expected |
|---|---|---|
| 1.2 | `.env` holds every setting | `PASS` |
| 1.4 | The two chat models and four `mr-` router editions exist | All six deployments listed |
| 1.5 | We're allowed to call a model and a router | A reply from each. The router's reply names the model it picked |
| 1.6 | TrailMate v0 exists | Its instructions are one short sentence, on purpose |
| 1.9 | Our test data is trustworthy | Every quote exists in a manual and the sets don't overlap |

Before section 1.4, the notebook asks us to guess which router edition will be cheapest and which will be strongest. Keep that guess for Module 6.

## Step 3: Read the scoreboard (section 1.10)

**Expected:** every check passes.

<!-- TODO(screenshot): m1-scoreboard.webp | section 1.10 output with every check PASS | crop to the cell output -->

A few red lines on a first run are normal: role assignments can take a few minutes to arrive. Rerun the failed cell, and move on once it's green.

> [!NOTE]
> If 1.2 fails, recover the settings from the completed deployment before retrying. Don't rerun `deploy.sh`: it would create another resource group.

## Step 4: Break it on purpose (section 1.11)

The notebook calls a deployment that doesn't exist.

**Expected:** a one-line error. We'll recognize its shape when something breaks later.

## The aha (section 1.12)

> "It doesn't work" is useless. "Check 5 failed" is a fix.

<details>
<summary>Optional: see it in the portal</summary>

The same deployments appear in the Foundry portal under **Models**, in the `trailmate` project.

<!-- TODO(screenshot): m1-model-deployments.webp | Foundry portal > trailmate project > Models, listing the two chat models and four mr- routers | hide account and resource names -->

</details>

## Checkpoint

- [ ] Section 1.10 shows every check passing
- [ ] We saw which model the router picked in 1.5
- [ ] We know what a failed call looks like

**Next:** [Module 2: Choosing a model](02-model-selection.md)
