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
| [`pricing.json`](pricing.json) | Model prices for cost math (empty until we fill them from the Azure pricing page) |
| [`PROVENANCE.md`](PROVENANCE.md) | Where the data comes from and its license |

Each case belongs to one of six ways an agent can lose a customer's trust (`way`), has a difficulty, and cites verbatim manual quotes as `facts`. Check everything with `python3 src/02_validate_data.py`.
