---
name: update-lab-instructions
description: 'Create, update and keep in sync the LAB663 self-guided and Skillable lab instructions in instructions/. Use when: a notebook in labs/core or labs/more changes; setup, infra/deploy.sh or skillable_lifecycles change; adding, editing, reordering or reviewing module pages; regenerating skillable-copy.md; checking Skillable Markdown syntax (page breaks, checkboxes, copy text, @lab tokens, blocks); running the instructions sync check.'
---

# Update lab instructions

LAB663 has two delivery paths that teach the same notebooks:

- **Self-guided** (`instructions/self-guided/`): our own subscription, Codespace or dev container, we deploy and clean up.
- **Skillable** (`instructions/skillable/`): a prepared Windows VM, the lab deploys and removes everything.

The notebooks are the source of truth. Each path has one page per notebook, and a shared sync header keeps the pair honest. This skill updates both pages together, rebuilds the Skillable copy, and runs the check.

Read these first:

- [workshop-content.instructions.md](../../instructions/workshop-content.instructions.md) for voice and teaching order.
- [AGENTS.md](../../../AGENTS.md) for the ground rules. Never mix the two delivery paths.
- Skillable syntax and style. Append `.md` to each URL for plain Markdown:
  - https://docs.skillable.com/docs/creating-lab-instructions
  - https://docs.skillable.com/docs/creating-instructions-with-markdown-syntax
  - https://docs.skillable.com/docs/instructions-writing-best-practices

## Layout

```text
instructions/
  README.md                         choose-your-path overview and module map
  scripts/check_sync.py             the sync check (stdlib Python)
  self-guided/
    README.md                       prerequisites, module table, cleanup, feedback
    core/NN-<slug>.md               one page per labs/core notebook, NN = notebook number
    more/00-explore-mai-models.md   one page for labs/more
    screenshots/                    images for self-guided pages
  skillable/
    README.md                       lab profile prerequisites, module table, maintainer notes
    core-N-<slug>.md                one file per labs/core notebook, split into pages by ===
    more-0-explore-mai-models.md
    scripts/generate-skillable-copy.sh
    skillable-copy.md               GENERATED; never edit by hand
```

## The sync contract

The first line of every module page, in both paths, is:

```markdown
<!-- sync: source=labs/core/04-make-it-work.ipynb sections=4.1,4.2,4.3 -->
```

- `source` is the notebook (or `labs/more/README.md`) the page teaches.
- `sections` lists every `N.k` notebook section the page mentions as "section N.k".
- The self-guided and Skillable pages for one source declare the **same** sections, so both paths cover the same ground.
- Each page states the notebook's "about N minutes" time.

The generator strips the header from `skillable-copy.md`.

## Workflow

1. **Find what changed.** Compare against the last instructions update, for example `git diff --stat <base> -- labs/ src/ infra/ skillable_lifecycles/ data/`. For each changed notebook, list new, removed or renumbered `## N.k` sections, changed **Expected** lines, times, learner-edited variables (such as `our_gaps`, `REVIEW_APPROVED`, `RUN_ALL_EDITIONS`, `COMPARE_ALL_PHOTOS`, `START_NEW_INSIGHT_RUN`) and wait times.
2. **Update the self-guided page first.** It's the fuller version: objective, steps with **Expected** results, the aha, a checkpoint and a link to the next page. Copy expected results from the notebook; never invent numbers or outputs.
3. **Mirror it on the Skillable page.** Same sections, same commands, same expected results, rewritten as short checkbox steps (rules below).
4. **Update the sync headers** on both pages.
5. **Update the tables** in `instructions/README.md`, `self-guided/README.md` and `skillable/README.md` if a page was added, renamed or retitled.
6. **Rebuild and check:**

   ```bash
   bash instructions/skillable/scripts/generate-skillable-copy.sh
   python3 instructions/scripts/check_sync.py
   ```

7. Fix every reported problem and rerun until it prints `All checks passed`.
8. Tell the maintainer to paste `skillable-copy.md` into Skillable Studio (**Edit Instructions**) and review it in the preview, since GitHub doesn't render Skillable syntax.

When a **new notebook** appears in `labs/core`, add `self-guided/core/NN-<slug>.md` and `skillable/core-N-<slug>.md`. The check fails until both exist. Keep numbers matching the notebook.

When **setup** changes, decide which path it affects. `infra/deploy.sh` and `infra/cleanup.sh` changes go to the self-guided Module 0 and Module 6 pages. Lifecycle, VM, status-file or sign-in changes go to Skillable `core-0` and the Skillable README prerequisites. Shared changes go to both.

## Rebuild from scratch

Use this to regenerate both paths for a new lab or after a large notebook rewrite. It's how the current pages were first built.

1. **Gather the facts.** Read the Skillable docs above, `skillable_lifecycles/README.md` (VM name, status files, roles, `@lab` tokens used by the actions), `infra/README.md`, `labs/more/README.md` and the current READMEs.
2. **Outline every notebook.** Print each notebook's headings so the pages follow its sections:

   ```bash
   python3 - <<'EOF'
   import json, glob, re
   for f in sorted(glob.glob('labs/core/*.ipynb')) + sorted(glob.glob('labs/more/*.ipynb')):
       print('=====', f)
       for c in json.load(open(f))['cells']:
           if c['cell_type'] == 'markdown':
               for line in ''.join(c['source']).splitlines():
                   if re.match(r'^#{1,3} ', line) or line.startswith(('**Time:**', '**Expected:**', '> **Aha:**')):
                       print('  ', line[:160])
   EOF
   ```

   Then read each notebook's markdown in full for **Expected** lines, **While you wait** boxes, wait times, learner-edited variables and the aha. Take expected results only from there.
3. **Map pages to notebooks**, one per notebook per path. Module 0 also carries setup: deploy and Copilot check (self-guided), or VM, GitHub and Azure sign-in plus the status file (Skillable). Module 6 also carries the ending: clean up (self-guided) or finish the lab (Skillable). Split a Skillable file into extra `===` pages when a notebook has a natural break, such as a long wait or a decision.
4. **Write the self-guided pages**, then the Skillable pages, then the three READMEs, following the workflow above.
5. **Rebuild and check**, then prove the check still catches drift: copy `instructions/`, `.github/`, `labs/core/`, `labs/more/README.md`, `labs/more/00-set-the-stage.ipynb`, `infra/README.md` and `skillable_lifecycles/README.md` into a temp folder, inject faults (change a header's sections, lengthen a title past 40 characters, mention an undeclared section, use an unknown `@lab` token, change a time, break a link, add a fake `labs/core/07-*.ipynb`, drop a success note), and confirm each one is reported. Delete the temp folder afterwards.

Pitfalls seen while building this:

- Run the check **after** file edits finish, not in parallel with them, or it reports links to files that don't exist yet.
- `create_file` can't overwrite an existing README. Write to `README.md.new` and move it into place.
- A version string like `gpt-5.4` looks like a section number. The check only reads section numbers after the word "section" or "sections".
- Number every list item `1.`; the check flags `2.` and up.

## Open items to confirm before delivery

Check these each time the pages are regenerated, and remove an item once it's confirmed:

- `@lab.CloudSubscription.TenantId` is used by the lifecycle scripts, but Skillable's token table lists only `TenantName`. Confirm it resolves in the Studio preview.
- The desktop status file is `LAB663-03-environment-status.txt` (action 3) or `LAB663-deployment-output.txt` (`deploy-pwsh.ps1` route). Name the one the profile uses once it's settled.
- Notebook 03 sets `COMPARE_ALL_PHOTOS = True` while its text calls the one-photo run the core path. Both pages ask the learner to choose. Update the pages if the notebook default changes.
- The 60-minute plan and the Module 5 and 6 times are targets until a timed rehearsal on the Skillable image confirms them.

## Screenshots (self-guided only)

Self-guided pages mark each wanted screenshot with a hidden marker:

```markdown
<!-- TODO(screenshot): m4-trace-list.webp | what to capture | what to crop or hide -->
```

The file name sets the module (`m0` to `m6`, or `more`) and the slug. `python3 instructions/scripts/check_sync.py --todos` lists every open marker.

When the maintainer shares captures during a test run:

1. **Match** each capture to its TODO by what it shows. If it doesn't match one, propose a new `mN-<slug>.webp` name and where it goes before adding it.
2. **Check for personal data** before saving: subscription and tenant IDs, resource and account names, endpoints, emails, user aliases and tokens. Ask for a recrop rather than committing them.
3. **Convert** with the repository `.venv` (it has Pillow): WebP quality 90, at most 1600 px wide.

   ```bash
   .venv/bin/python - <<'EOF'
   from PIL import Image
   src, dst = "<capture.png>", "instructions/self-guided/screenshots/<mN-slug>.webp"
   image = Image.open(src)
   if image.width > 1600:
       image = image.resize((1600, round(image.height * 1600 / image.width)), Image.LANCZOS)
   image.save(dst, "WEBP", quality=90, method=6)
   EOF
   ```

4. **Replace the marker** with an image line using descriptive alt text, for example `![Foundry portal trace list for the trailmate agent](../screenshots/m4-trace-list.webp)`. Put portal views inside the page's optional `<details>` block.
5. **Run the check.** It fails if a captured file still has its TODO, or if an image link is broken.

Don't keep unused screenshots; delete any file no page links to.

## Path-specific rules

| | Self-guided | Skillable |
|---|---|---|
| Shell | bash in the dev container; PowerShell only for the Windows alternative | PowerShell on the Windows VM |
| Kernel | **.venv** (Recommended) | **Python (LAB663)** |
| Deploy and clean up | `bash infra/deploy.sh`, `bash infra/cleanup.sh` | Never. The lab does it. Say so with an `> [!Alert]` |
| Links to repo files | Relative links, checked by the script | None; they don't resolve. Name the file and open it with **Ctrl+P** |
| Images | `../screenshots/mN-<slug>.webp`, placed where a `TODO(screenshot)` marker asks for one | Avoid. Upload to Studio first if one is essential |
| Credentials | Our own accounts | `@lab` tokens only, never literal values |
| GitHub sign-in | Our own Copilot-enabled account | The lab credentials through `https://github.com/enterprises/skillable-events/sso` (confirmed for LAB663) |
| More labs | Replay or live | Replay only; image models aren't in the lab environment |

## Skillable page rules

From the Skillable writing guide, enforced where possible by `check_sync.py`:

- Split pages with `===` on its own line. Each page starts with a `# ` heading of 40 characters or fewer, starting with a verb, sentence case, no period. It labels the **Next** button.
- Open each page with one sentence stating the outcome.
- One sentence per step, in where, what, why order: "In section 4.8, confirm you see findings...". Use `1. []` for every step so it shows a checkbox and auto-numbers.
- `++text++` copies to the clipboard (commands, file names, values). `+++text+++` types into the VM (passwords, URLs typed into the VM browser). Don't bold copy text.
- Bold only UI elements the attendee selects. Inside blocks, avoid bold; use italics.
- Blocks: `> [!Knowledge]` for the why and the aha, `> [!Note]` for the lab environment, `> [!Alert]` for "don't do this", `> [+Hint]` or `> [+Help]` (expandable) for recovery steps. Indent a block under the step it follows. Keep to one block between steps, occasionally two.
- End every page with `> [!Note] *Success:* <visible result>`.
- Use `-nocopy` on code blocks that only show output.
- Only use `@lab` tokens listed in `KNOWN_TOKENS` in `check_sync.py`. Confirm a new token in Studio's **@lab** picker before adding it there.

## Voice

Both paths follow the workshop content guide: friendly, concise, "we" and "let's" on self-guided pages, direct "you" on Skillable steps. Plain words, no marketing language. Be honest about waits, preview features and results that may legitimately end in "keep the baseline".

## Checklist

- `python3 instructions/scripts/check_sync.py` prints `All checks passed`.
- Each changed notebook's sections, times, **Expected** results and editable variables are reflected on both pages.
- No secrets, endpoints, subscription or tenant IDs, emails or personal names in pages or screenshots.
- Skillable pages render correctly in the Studio preview, including indented blocks and tables.
- Self-guided screenshots still match the portal; replace or drop any that changed.
