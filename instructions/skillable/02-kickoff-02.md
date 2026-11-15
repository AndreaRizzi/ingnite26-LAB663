# 2.2 Start the optimizer

**What we'll do:** Give Foundry a starting gap list, build a rubric from it, and start the **agent optimizer** so it can work on **v2** while we explore.

## Save a starting gap list

1. [] In **04-make-it-work.ipynb**, jump to section **4.9** and find the code cell that starts with `our_gaps = [`.
1. [] Replace the three `"Replace me..."` lines so the list matches the one below. Copy it with the button on the code block.

    ```python
    our_gaps = [
        "Overclaiming: may call the Summit Breeze Jacket waterproof when the manual says water-resistant",
        "Making things up: may give an exact per-shoe weight for the TrailWalker Hiking Shoes when the manual gives none",
        "Out of lane: may answer off-topic requests, like a hot chocolate recipe, instead of redirecting to our products",
    ]
    ```

1. [] Run the cell and confirm it prints the three gaps.

> [!Knowledge] These are risks we expect, written ahead of time so the optimizer can start early. On page 5.1 we'll check them against what Foundry actually finds.

## Start the optimizer

1. [] In the Explorer, open **labs > core > 05-make-it-better.ipynb**.
1. [] Select the **.venv (3.13.14)** kernel, the same way as on page 1.3.

1. [] Run the first code cell. Confirm it prints the v0 and v1 version numbers.
1. [] Jump to section **5.2** and run its code cell. Wait for **Rubric created**.
1. [] Jump to section **5.4** and run its two code cells. Confirm you see **Datasets** and **Evaluation ready**.
1. [] Jump to section **5.6** and run the estimate cell. It shows call counts and a cost range.
1. [] Run the next code cell to start the job. When it prints **Optimization job:** and status lines, **leave it running**.

    <!-- TODO screenshot: 02-kickoff-02-optimizer-running.png | Section 5.6 printing the optimization job ID and running status lines -->

> [+Hint] Rubric generation fails or finds no traces
>
> The traces may still be arriving. Wait one minute, then run the section 5.2 cell again. Don't rerun section 4.5.

---

> [!Note] **Success:** We just started the agent optimizer. It keeps working in Foundry while we head to the portal.
