---
name: update-skillable-instructions
description: 'Create and maintain the LAB663 Skillable lab manual in instructions/skillable/ using Skillable Markdown syntax, validated against https://docs.skillable.com/docs/creating-instructions-with-markdown-syntax. Use when: adding, editing, reordering, or reviewing the core-N, more-N, and ref-N Skillable page files; regenerating skillable-copy.md with scripts/generate-skillable-copy.sh so it can be pasted into the Skillable VM instructions panel; checking Skillable syntax (page breaks, blocks, copyable text, @lab tokens, images).'
---

# Update Skillable instructions

Maintain `instructions/skillable/`: one authored page file per module, a generator script, and the generated `skillable-copy.md` that the owner pastes into Skillable Studio (**Edit Instructions**). It can also be built as `[!include]` lines that pull each page from GitHub.

Use the Skillable authoring guide to validate every page. Append `.md` to a URL for plain Markdown.
- https://docs.skillable.com/docs/creating-instructions-with-markdown-syntax (syntax, the source of truth)
- https://docs.skillable.com/docs/instructions-writing-best-practices
- https://docs.skillable.com/docs/github-instructions-source

Voice and structure come from [workshop-content.instructions.md](../../instructions/workshop-content.instructions.md) and [AGENTS.md](../../../AGENTS.md). Read both before writing.

## How Skillable consumes this folder

- A lab profile uses exactly one Markdown file, pasted into Studio or synced from the repo. Here that file is `skillable-copy.md`.
- The generated file starts with `@lab.Title`, so the profile's title renders at the top of the first page.
- `[!include [label](raw-github-url)]` pulls a page live from GitHub. It needs a public repo and is pinned to a branch.
- GitHub previews do not render Skillable-only syntax (blocks, checkboxes, copy text). Check the rendering in Skillable.
- Images uploaded to the lab profile use `!IMAGE[name.png](instructionsNNNNNN/name.png)`. Local images under `media/` can be mapped to uploaded paths in the generator's `SKILLABLE_MEDIA` table.
- Repo size limit is 500 MB. Keep videos out of the repo.

## Folder layout

```text
instructions/skillable/
  README.md                         facilitator guide: environment, notebooks, timings, finish safely
  core-0-<slug>.md ...              one file per core module; the number sets the order
  more-0-<slug>.md ...              optional More/bonus pages, after the core
  ref-0-<slug>.md ...               reference pages (credentials table, instructor links), last
  scripts/generate-skillable-copy.sh  joins the pages into skillable-copy.md
  skillable-copy.md                 generated; never edit by hand
  media/                            images used by the pages, if any
  screenshots/                      screenshots for the README
```

Each page file holds one module. Split it into Skillable pages with a line containing only `===`.

## LAB663 specifics

- The labs are Jupyter notebooks in `labs/core/`, `labs/more/` and `labs/bonus/`. Each Skillable core page should map to one notebook (or one section of one), with the same cell order, commands, and expected results.
- The companion guide is `instructions/self-guided/`. Never mix the two modes. Skillable attendees never run `infra/deploy.sh` or `infra/cleanup.sh`, and never delete resources. When shared setup changes, update both.
- Environment preparation is done by the lifecycle scripts in `skillable_lifecycles/`. The status file on the VM desktop (`LAB663-03-environment-status.txt`) is how attendees check that preparation finished.
- The notebook kernel is the prepared `.venv` (**Python (LAB663)**).
- Keep the climbing story: versions (v0, v1, …), one change at a time, the frozen eval set and rubric, and an explicit promote-or-retain decision.
- The slowest learner finishes the core in 60 minutes. Note the time target per module in `README.md`.

## Workflow

1. Read `README.md`, the existing page files, and the matching notebooks to learn the current list and order.
2. Create, edit, rename, or delete page files as requested. Keep numbers contiguous within `core-`, `more-` and `ref-`, and keep slugs lowercase with hyphens.
3. Keep each page in step with its notebook and with `instructions/self-guided/README.md`: same steps, same expected output.
4. Update the tables in `README.md`, then run `bash instructions/skillable/scripts/generate-skillable-copy.sh` (or `MODE=include` for the GitHub include form).
5. Run the checklist below and fix any failures before finishing.

## Module shape

Each module is one page group and follows the lab pattern: build, break, fix, learn.

```markdown
# Let the optimizer climb

One sentence stating the result the attendee will see.

## Run the optimizer

1. [] In VS Code, open ++labs/core/05-make-it-better.ipynb++ and select the **Python (LAB663)** kernel.
1. [] Run the cells under **Submit the optimizer job** and note the job ID.

## Read what it changed

1. [] Run the comparison cell and compare the candidate score with v1.

    > [+Hint] Where do I look?
    >
    > Scroll to the scoreboard table printed by the comparison cell.

> [!Knowledge] Why this matters: one or two sentences giving the takeaway.

> [!Note] **Success:** state the visible result, for example the scoreboard with v1 and the candidate side by side.
```

Rules:
- Start each Skillable page with a `# ` heading of 40 characters or fewer, in sentence case, with no period. It labels the **Next** button. More pages start with `More: `.
- One sentence per step. Order each step as where, what, why.
- Number every step `1.`. Add `[]` for a progress checkbox on actions the attendee performs.
- Indent blocks that sit between steps to the same level as the step before them.
- Use simple, conversational language aimed at the attendee. Never invent results, links, or scores.
- Never give away the fix in the main text of a break step. Put help in hint blocks.
- End every Skillable page with a `> [!Note] **Success:**` line stating the visible result.
- Use `-nocopy` on code blocks that show expected output.

## Syntax quick reference

| Need | Syntax |
|------|--------|
| Page break | `===` on its own line |
| Copy to clipboard | `++text++` |
| Type into a VM | `+++text+++` |
| Code block modifiers | fence language plus `-nocolor`, `-notab`, `-nocode`, `-nocopy`, `-wrap`, `-linenums` |
| Blocks | `> [!Knowledge]`, `> [!Alert]`, `> [!Hint]`, `> [!Help]`, `> [!Note]` |
| Expandable blocks | `> [+Hint]`, `> [+Help]`, `> [+Alert]`, `> [+Note]`; continue with a `>` line, then more `> ` text |
| Uploaded image | `!IMAGE[file.png](instructionsNNNNNN/file.png)` |
| Repo image | `![alt text](media/file.png "title"){width}` |
| Dialog link | `^[text](url)` |
| Portal link | `<[text](url)` |
| Section by variable | `:::name(variable=value)` ... `:::` |
| Lab title | `@lab.Title` |
| VM password | `@lab.VirtualMachine(Win11-Pro-Base).Password` |
| Cloud credentials | `@lab.CloudPortalCredential(User1).Username`, `.Password`, `.AccessToken` |
| Attendee input | `@lab.TextBox(name)` to set, `@lab.Variable(name)` to recall, `@lab.MaskedTextBox(name)` for secrets |
| Activities | add in Studio, then paste the token, such as `@lab.Activity(Question1)` |

Use `@lab` tokens for any per-attendee value. Never hardcode credentials, tenant or subscription IDs, or emails.

## Checklist

- Every `core-*.md`, `more-*.md` and `ref-*.md` file is listed in `README.md`, and the tables match the files on disk and their `# ` page titles.
- `skillable-copy.md` was regenerated after the last page change.
- Each Skillable page starts with a valid `# ` heading of 40 characters or fewer and ends with a success note (reference pages are exempt).
- Steps and expected output match the notebook and the self-guided guide.
- Nothing tells Skillable attendees to deploy, clean up, or delete infrastructure.
- Images referenced exist under `media/` or are mapped to uploaded Skillable paths.
- No secrets, hardcoded per-attendee values, or placeholder text.
- Syntax matches the Skillable authoring guide, and blocks inside lists are indented.
- Links to repo files outside `skillable/` are relative and exist.
