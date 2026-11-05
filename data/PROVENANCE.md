# Provenance and attribution

## Product manuals and images

The 10 product manuals in [`manuals/`](manuals/) and the product images in
[`images/`](images/) come from the MIT-licensed
[`Azure-Samples/contoso-web`](https://github.com/Azure-Samples/contoso-web)
sample (`public/manuals/` and `public/images/`), as used in the
[Model Mastery agent-builder workshop](https://github.com/microsoft-foundry/model-mastery/tree/main/foundry/agent-builder).
The MIT license text is in [`contoso-web-MIT-LICENSE.md`](contoso-web-MIT-LICENSE.md).

Products used (Contoso Outdoors catalog):

| # | Product | Manual | Image |
|---|---------|--------|-------|
| 1 | TrailMaster X4 Tent | `product_info_1.md` | `trailmaster-x4-tent.png` |
| 8 | Alpine Explorer Tent | `product_info_8.md` | `alpine-explorer-tent.png` |
| 2 | Adventurer Pro Backpack | `product_info_2.md` | `adventurer-pro-backpack.png` |
| 16 | TrailLite Daypack | `product_info_16.md` | `traillite-daypack.png` |
| 4 | TrekReady Hiking Boots | `product_info_4.md` | `trekready-hiking-boots.png` |
| 11 | TrailWalker Hiking Shoes | `product_info_11.md` | `trailwalker-hiking-shoes.png` |
| 3 | Summit Breeze Jacket | `product_info_3.md` | `summit-breeze-jacket.png` |
| 17 | RainGuard Hiking Jacket | `product_info_17.md` | `rainguard-hiking-jacket.png` |
| 7 | CozyNights Sleeping Bag | `product_info_7.md` | `cozynights-sleeping-bag.png` |
| 6 | EcoFire Camping Stove | `product_info_6.md` | `ecofire-camping-stove.png` |

The catalog is fictional. Brands, contact details and email addresses in the
manuals are sample data, and we use them only for grounding examples.

## Test data and rubric (authored for LAB663)

[`practice.jsonl`](practice.jsonl), [`dev.jsonl`](dev.jsonl) and
[`test.jsonl`](test.jsonl), and the reference rubric in
[`evaluators/trailmate-quality.yaml`](evaluators/trailmate-quality.yaml), were
written for this lab. They were inspired by the evaluation cases and rubric in
the agent-builder workshop above, and a few ideas (like the shoe-weight and
EcoFire-tent questions) started there. Every expected answer cites a verbatim
quote from the manuals, and `src/02_validate_data.py` checks that each quote exists.

The original manuals and images are untouched. We don't edit them.

## Pricing

[`pricing.json`](pricing.json) is empty on purpose. Prices come from the Azure
pricing page, and we fill them in before the lab quotes any cost.
