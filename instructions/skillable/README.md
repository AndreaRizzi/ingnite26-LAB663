# LAB663 Skillable manual

The in-venue version of LAB663. Attendees follow a paged manual inside a Skillable lab, with the environment prepared for them: GitHub Copilot access, a Foundry project, two chat models, four router editions, tracing and the starting TrailMate agent. They run the same code-first notebooks as the [self-guided walkthrough](../self-guided/README.md), but **they don't deploy or delete infrastructure**.

Each page file below holds one module, split into Skillable pages by `===`. The build script joins them into [skillable-copy.md](skillable-copy.md), the single file pasted into Skillable Studio.

## Prerequisites

The lab profile must give every attendee these before the lab starts. Operators set them up with the [Skillable lifecycle actions](../../skillable_lifecycles/README.md).

| Attendee needs | For | Notes |
|---|---|---|
| A Windows 11 VM (`Win11-Pro-Base`) with VS Code, the LAB663 folder on the desktop, and a prepared `.venv` registered as **Python (LAB663)** | All modules | Attendees don't install or clone anything |
| A desktop status file that says `Result: SUCCEEDED` | All modules | Written by lifecycle action 3 (`LAB663-03-environment-status.txt`) or the `deploy-pwsh.ps1` route (`LAB663-deployment-output.txt`) |
| GitHub Enterprise sign-in with Copilot, using the lab credentials | Module 0 onward | Lifecycle action 1 grants the entitlement |
| `@lab.CloudPortalCredential(User1)` with Foundry User and Cognitive Services Contributor | Module 0 onward | Lifecycle action 2 assigns the roles. They can take up to 10 minutes to apply |
| A `.env` file at the repository root, with no keys | Module 0 onward | Lifecycle action 3 writes it |

## Modules

| Page file | Skillable pages | Time |
|---|---|---|
| [core-0-get-ready.md](core-0-get-ready.md) | Sign in to your lab, Check your lab environment, Meet TrailMate | Before the clock, about 5 min of reading |
| [core-1-setup-and-validate.md](core-1-setup-and-validate.md) | Validate your setup | 4 min |
| [core-2-model-selection.md](core-2-model-selection.md) | Compare two models | 8 min |
| [core-3-multi-model-vs-multimodal.md](core-3-multi-model-vs-multimodal.md) | Separate multi-model from multi-modal | 8 min |
| [core-4-make-it-work.md](core-4-make-it-work.md) | Create v1 and leave traces, Read the insights | 12 min |
| [core-5-make-it-better.md](core-5-make-it-better.md) | Turn good into a number, Let the optimizer climb, Decide whether to promote | 14 min target |
| [core-6-make-it-optimal.md](core-6-make-it-optimal.md) | Try a model router, Decide on the router, Finish the lab | 14 min target |
| [more-0-explore-mai-models.md](more-0-explore-mai-models.md) | More: Explore MAI models | Optional, replay only |

The times are planning targets, not measured service guarantees. Rehearse the whole schedule on the actual Skillable image before delivery; the 60-minute plan hasn't been demonstrated there yet.

## If something goes wrong

Attendees raise a hand for a proctor. Proctors check the desktop status file first, then the [handover checks](../../skillable_lifecycles/README.md#hand-over-to-the-learner). Attendees never run `infra/deploy.sh` or `infra/cleanup.sh` on the VM.

## Maintainer notes

### Keep both paths in step

The notebooks in `labs/` are the source of truth. Every Skillable page file has a matching self-guided page with the same `<!-- sync: ... -->` header, which names the notebook and the sections both pages cover. Use the [update-lab-instructions skill](../../.github/skills/update-lab-instructions/SKILL.md) when notebooks, setup or lifecycle actions change, then run:

```bash
python3 instructions/scripts/check_sync.py
```

It checks that both paths cover the same notebook sections and times, that every Skillable page follows the conventions below, that links resolve, and that `skillable-copy.md` is current.

### Syntax

Write every page in Skillable Markdown. The references are [Creating instructions with Markdown syntax](https://docs.skillable.com/docs/creating-instructions-with-markdown-syntax) and [Instructions writing best practices](https://docs.skillable.com/docs/instructions-writing-best-practices). GitHub doesn't render Skillable-only syntax such as `> [!Knowledge]`, `1. []` checkboxes or `++copy text++`, so check the result in the Studio preview.

- Start each Skillable page with a `# ` heading of 40 characters or fewer, starting with a verb. It labels the **Next** button.
- One sentence per step, in where-what-why order. Use `1. []` for every step.
- Use `++text++` for text to copy and `+++text+++` to type credentials into the VM.
- Bold only UI elements the attendee selects. Inside blocks, use italics instead.
- Indent blocks that sit between steps under the step before them, and keep it to one block, occasionally two.
- Put answers and recovery steps in expandable `> [+Hint]` or `> [+Help]` blocks.
- End every page with `> [!Note] *Success:* ...` stating the visible result.
- Don't link to repo files with relative paths; they don't resolve in Skillable. Name the file and use **Ctrl+P** instead.
- Only use `@lab` tokens listed in the check script, and confirm new ones in Studio's **@lab** picker.

### Build the manual

```bash
bash instructions/skillable/scripts/generate-skillable-copy.sh
```

It writes [skillable-copy.md](skillable-copy.md): every page, core then More, joined by `===`, with the sync headers removed. Paste the whole file into the lab profile (**Edit Instructions**).

To have Skillable pull each page live from GitHub instead, use include mode. It writes one `[!include]` line per page and needs the repository to be public.

```bash
MODE=include BRANCH=main bash instructions/skillable/scripts/generate-skillable-copy.sh
```
