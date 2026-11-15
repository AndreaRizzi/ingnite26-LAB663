# 6.1 Try a model router

**What we'll do:** Keep v2's instructions and change only the model, to the **mr-default** router. Then score it with the same rubric and questions.

1. [] Press **Ctrl+P**, open this notebook, and select the **.venv(3.13.14)(Python3.13.14)** kernel.

    ++06-make-it-optimal.ipynb++

1. [] In the first code cell, leave `RUN_ALL_EDITIONS = False` and `TOLERANCE` as they are, then run it.
1. [] Run section **6.2** and note how many test questions are tagged easy.
1. [] Run section **6.3** and compare the models it shows with what you saw in the playground on pages 3.2 and 3.3.
1. [] Run section **6.4** to create the router candidate, then section **6.5** to score it. Scoring takes a few minutes.

    > [+Hint] While you wait: all four router editions
    >
    > We score only mr-default today. Here's a completed run with all four editions side by side.
    >
    > <!-- TODO screenshot: 06-improve-01-all-editions.png | A completed board comparing the baseline with all four router editions -->

1. [] Confirm the board has a baseline row and an **mr-default** row. If `valid` is False, that batch can't support a comparison.

    <!-- TODO screenshot: 06-improve-01-board.png | The section 6.5 board with the baseline and mr-default rows -->

---

> [!Note] **Success:** We just measured a router candidate with the same ruler as every earlier version.
