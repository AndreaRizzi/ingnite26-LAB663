# Data

Everything TrailMate needs to answer questions and be measured.

| Path | What it is |
|------|------------|
| [`manuals/`](manuals/) | The 10 Contoso Outdoors product manuals TrailMate searches |
| [`images/`](images/) | Product images that match the manuals |
| [`practice.jsonl`](practice.jsonl) | 12 cases for Module 4: we generate traces and insights from these |
| [`dev.jsonl`](dev.jsonl) | 12 cases for Module 5: the rubric baseline and the optimizer's target |
| [`test.jsonl`](test.jsonl) | 12 held-out cases, used only for the scoreboard. The optimizer never sees them |
| [`evaluators/trailmate-quality.yaml`](evaluators/trailmate-quality.yaml) | Our reference rubric, to compare with the one we build |
| [`pricing.json`](pricing.json) | A dated snapshot of westus list prices for cost math, with its source |
| [`PROVENANCE.md`](PROVENANCE.md) | Where the data comes from and its license |

Each case belongs to one of six ways an agent can lose a customer's trust (`way`), has a difficulty, and cites verbatim manual quotes as `facts`. Check everything with `python3 src/02_validate_data.py`.

Keep the three case files and manuals frozen during a measurement campaign. A verbatim quote check is not a semantic review of the answer key; see the [rain-cover ambiguity in the narrative](../docs/narrative.md#keep-the-beginner-journey-focused).

The hand-written reference rubric describes a 1-to-5 scale. The generated Foundry rubric emits a normalized 0-to-1 aggregate; compare definitions, not raw scores across these two formats. Uploading `expected_behavior` and `facts` does not automatically map them into a judge. The core evaluation supplies the agent's structured retrieval evidence and pins the generated evaluator version.

For model cost estimates, `pricing.json` needs the deployment region, a source URL, price date, and input/output/cached-input rates for every serving model. It holds one region (westus), taken from the Azure Retail Prices API on the date in `as_of`; its `_note` lists the meters used and what isn't covered. Deployed in another region? Cost shows as **unknown**. Missing attribution or prices mean unknown cost, not zero cost or proof of savings.
