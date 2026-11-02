<!-- sync: source=labs/core/04-make-it-work.ipynb sections=4.1,4.2,4.3,4.4,4.5,4.6,4.7,4.8,4.9,4.10 -->
# Create v1 and leave traces

Change one lever, the instructions, to make v1, then send it practice questions so it leaves traces. Module 4 takes about 12 minutes.

1. [] In VS Code, press **Ctrl+P**, open this notebook, and select the **Python (LAB663)** kernel.

   ++04-make-it-work.ipynb++

1. [] In section 4.2, guess which of the three questions v0 gets wrong, then run sections 4.1 and 4.2.
1. [] Note which answers had wrong facts, invented facts, or should have been declined.
1. [] Run section 4.3 to create or reuse the insights monitor.
1. [] Press **Ctrl+P** and open ++instructions-v1.md++ to read what changed, then run section 4.4.
1. [] Confirm section 4.4 prints a saved v1 version ID.
1. [] Run section 4.5 so v1 answers all twelve practice questions.

   > [!Knowledge] While you wait, read the box about case pr-04. Its manual says both "Rain cover included" and "Rain Cover: No". Don't edit practice.jsonl.

1. [] In section 4.6, write down two or three problems you see, in your own words.

> [!Alert] Modules 4, 5 and 6 share .lab-state.json. Run them in order, one notebook at a time.

> [!Note] *Success:* v1 is saved, v0 is unchanged, and you have your own list of problems.

===

# Read the insights

Ask Foundry what's wrong, compare it with your own list, and write down the gaps.

1. [] Run section 4.7. It pauses for one minute so traces can arrive.
1. [] Run section 4.8 to start the insights run. It usually takes about 3 minutes.

   > [!Knowledge] Long wait? Open any notebook in labs/more and read it in replay mode. It needs no setup.

1. [] Confirm you see findings with severity and evidence counts, or an explicitly empty result.

   > [+Hint] The result is empty.
   >
   > An empty result isn't a pass. Check traces_analyzed first. Set START_NEW_INSIGHT_RUN to True only after a completed run saw no traces and ingestion has caught up. Don't resend the practice questions.

1. [] In section 4.9, compare Foundry's findings with your list from section 4.6.
1. [] In the next code cell, replace the three "Replace me" lines in our_gaps with gaps you actually saw, each starting with one of the six ways we lose trust.
1. [] Run the cell and confirm it prints and saves your gaps.

   > [+Hint] You're not sure what to write.
   >
   > Paste the insights output into Copilot Chat and ask for three gaps. Check each one against the answer and the manual, then rewrite it in your own words.

> [!Knowledge] The aha in section 4.10: reading answers and inspecting traces give different views of the same problem. Foundry groups traces into patterns with evidence; you decide which to treat first.

> [!Note] *Success:* our_gaps holds real gaps from your traces, ready to become a rubric.
