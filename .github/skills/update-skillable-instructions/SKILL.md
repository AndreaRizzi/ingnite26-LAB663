---
name: update-skillable-instructions
description: 'Create and maintain the LAB663 Skillable lab manual in instructions/skillable/ using Skillable Markdown syntax, validated against https://docs.skillable.com/docs/creating-instructions-with-markdown-syntax. Use when: adding, editing, reordering, or reviewing the NN-stage-NN.md Skillable page files; adding dry-run screenshots; regenerating skillable-copy.md and skillable-copy-images.md with scripts/generate-skillable-copy.sh so they can be pasted into the Skillable VM instructions panel; checking Skillable syntax (page breaks, blocks, copyable text, @lab tokens, images).'
---

# Update Skillable instructions

Maintain `instructions/skillable/`: one small page file per Skillable page, a generator script, and two generated files the owner pastes into Skillable Studio (**Edit Instructions**).

Use the Skillable authoring guide to validate every page. Append `.md` to a URL for plain Markdown.
- https://docs.skillable.com/docs/creating-instructions-with-markdown-syntax (syntax, the source of truth)
- https://docs.skillable.com/docs/creating-lab-instructions
- https://docs.skillable.com/docs/instructions-writing-best-practices

Voice and structure come from [workshop-content.instructions.md](../../instructions/workshop-content.instructions.md) and [AGENTS.md](../../../AGENTS.md). The facilitator guide, stage table and page index are in `instructions/skillable/README.md`. Read all three before writing.

## Folder layout

```text
instructions/skillable/
  README.md                          facilitator guide: overview, stages, hero products, risks, page index
  NN-stage-NN.md                     one Skillable page each, e.g. 04-concepts-02.md; name order = page order
  screenshots/                       dry-run captures, named after their page (04-concepts-02-router-easy.png)
  scripts/generate-skillable-copy.sh joins the pages into the two generated files
  skillable-copy-images.md           generated; images as <!-- IMAGE: file | alt --> comments (paste now)
  skillable-copy.md                  generated; images as raw GitHub URLs on main (after the repo is public)
```

Stages: `00-start`, `01-setup`, `02-meet`, `03-kickoff`, `04-concepts`, `05-work`, `06-better`, `07-improve`, `08-wrap`, `09-more`, `10-ref`. Each page file is one Skillable page, so it contains no `===`; the generator adds the breaks and the leading `@lab.Title`.

## Page shape

Every page is one small task, modeled on the LAB540 Skillable pages.

```markdown
# 4.2 Let a router choose

**What we'll do:** Send the same two questions to a model router and see which model it picks for each.

1. [] In the playground, switch the deployment to **mr-default**.
1. [] Send the easy question.

    ++question text++

    <!-- TODO screenshot: 04-concepts-02-router-easy.png | Router response details showing the chosen model -->

> [+Hint] Copilot prompt: how does routing decide?
>
> ++Prompt the learner can paste into Copilot Chat++

---

> [!Note] **Success:** We just watched one deployment pick a model per question.
```

Rules:
- Title `# N.N Title`: the stage and page number, then a sentence-case title, 40 characters or fewer in total, no period. It labels the **Next** button. More pages use `N.N More: Title`.
- First line after the title is always `**What we'll do:** ...`. The last line is always `> [!Note] **Success:** We just ...`. These bookends state the value of the page.
- Keep pages small: one task, a handful of `1. []` steps, and at most one or two blocks. Don't stack alerts and notes.
- One sentence per step, ordered where, what, why. Name notebook sections explicitly ("jump to section **4.8**"), because page numbers and notebook section numbers differ.
- Put help in collapsible `> [+Hint]` blocks. Each page ends with one optional `> [+Hint] Ask Copilot: <label>` block whose copy-text prompt explains or summarizes that page in one to three sentences or bullets. Troubleshooting hints are separate. Prompts that touch Azure must say "Do not change anything."
- Indent blocks and comments under the step they belong to (four spaces).
- Never give away a decision the learner must make (for example `REVIEW_APPROVED`). Never invent results, timings, links, or scores.

## LAB663 specifics

- Wording: frame the lab as **continuous improvement**. "Climb" means a positive trend toward a goal across measured versions. Never write "hill climbing" or "up the hill".
- Story: Setup → Meet TrailMate (try v0 in the portal, plan the climb) → Kick-off (create v1, start the optimizer early) → Know the concepts (portal: start insights, models, router) → Make it work (portal: v0 vs v1, monitor, insights) → Make it better (notebook 05) → Keep improving (notebook 06) → Wrap.
- Version names: "climb versions" (v0–v3) are the lab's steps and appear in the notebooks; "agent versions" are Foundry's deployed versions, numbered from 1 (v0 = `trailmate` Version 1, v1 = Version 2). Portal steps name both. Candidates live in separate agents (`trailmate-optimizer-candidate`, `trailmate-mr-default-candidate`). Versions climb v0 → v1 → v2 → v3, one lever at a time, measured with a frozen eval set and rubric.
- Steps must match the notebook cells in `labs/core/`. Check section numbers and printed output in the `.ipynb` files before writing a step.
- Skillable learners never run `infra/deploy.sh` or `infra/cleanup.sh`, and never delete resources. Keep `instructions/self-guided/` separate; when shared setup changes, update both.
- Kernel: `.venv (3.13.14) (Python 3.13.14)`, selected via Select Kernel > Python Environments. Status files on the desktop: `LAB663-deployment-output.txt` (look for `Result: SUCCEEDED`) and `lab663-deploy-<timestamp>.txt` (look for `Populated .env`). Agent: `trailmate`. Deployments: `gpt-5.4`, `gpt-5.4-mini`, `mr-default`, `mr-cost`, `mr-quality`, `mr-subset`.
- Per-attendee values use `@lab` tokens only: `@lab.VirtualMachine(Win11-Pro-Base).Password`, `@lab.CloudPortalCredential(User1).Username`, `.Password`, `.AccessToken`, `@lab.CloudSubscription.TenantId`.

## Screenshots

- Mark each needed capture with `<!-- TODO screenshot: <page-file-stem>-<slug>.png | <alt text> -->`, and mark anything the dry run must confirm with `<!-- VERIFY: ... -->`.
- When the owner supplies captures, rename each one to the name in its TODO comment, move it to `screenshots/`, and replace the comment with `![<alt text>](screenshots/<file>.png)`. Remove a VERIFY comment once the owner confirms it.
- Once an image is uploaded to the Skillable profile, add `["screenshots/<file>.png"]="instructionsNNNNNN/<id>.png"` to `SKILLABLE_MEDIA` in the generator.

## Workflow

1. Read `README.md`, the existing page files, and the matching notebooks.
1. Create, edit, rename, or delete page files. Keep page numbers contiguous within each stage and the file name in step with the title number.
1. Update the stage table and page index in `README.md`.
1. Run `bash instructions/skillable/scripts/generate-skillable-copy.sh`.
1. Run the checklist below and fix any failures.

## Syntax quick reference

| Need | Syntax |
|------|--------|
| Page break (added by the generator) | `===` on its own line |
| Copy to clipboard | `++text++` |
| Type into a VM | `+++text+++` |
| Code block modifiers | fence language plus `-nocolor`, `-notab`, `-nocode`, `-nocopy`, `-wrap`, `-linenums` |
| Blocks | `> [!Knowledge]`, `> [!Alert]`, `> [!Hint]`, `> [!Help]`, `> [!Note]` |
| Expandable blocks | `> [+Hint] Title`, then a `>` line, then more `> ` text |
| Uploaded image | `!IMAGE[file.png](instructionsNNNNNN/file.png)` |
| Repo image | `![alt text](screenshots/file.png)` |
| Lab title | `@lab.Title` (added by the generator) |
| Attendee input | `@lab.TextBox(name)`, `@lab.Variable(name)`, `@lab.MaskedTextBox(name)` |

## Checklist

- Every page file is in the `README.md` page index, with a matching title.
- Each page starts with `# N.N` (40 characters or fewer) and `**What we'll do:**`, and ends with `> [!Note] **Success:** We just`.
- Both generated files were regenerated after the last page change.
- Steps, section numbers, and expected output match the notebooks.
- Nothing tells learners to deploy, clean up, or delete infrastructure.
- Every `screenshots/` image referenced exists; every remaining TODO and VERIFY comment is intentional.
- No secrets, hardcoded per-attendee values, or placeholder text.
