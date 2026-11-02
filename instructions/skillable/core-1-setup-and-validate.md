<!-- sync: source=labs/core/01-setup-and-validate.ipynb sections=1.2,1.4,1.5,1.6,1.9,1.10,1.11,1.12 -->
# Validate your setup

Check every piece of the setup on its own, so a failure names exactly what to fix. This takes about 4 minutes.

1. [] In VS Code, press **Ctrl+P**, open this notebook, and select the **Python (LAB663)** kernel.

   ++01-setup-and-validate.ipynb++

1. [] Run the first cells and confirm the printed interpreter is the repository .venv, not a system Python.
1. [] In section 1.2, confirm the .env check says PASS.
1. [] In section 1.4, confirm six deployments are listed: two chat models and four mr- router editions.

   > [!Knowledge] Guess now: which router edition will be cheapest, and which will be strongest? You check that guess in Module 6.

1. [] In section 1.5, confirm each model replies, and note which model the router says it picked.
1. [] In section 1.6, read the v0 instructions. They're one short sentence, on purpose.
1. [] In section 1.9, confirm the data checks pass.
1. [] In section 1.10, read the scoreboard and confirm every check passes.

   > [+Hint] Some checks are red.
   >
   > New role assignments can take up to 10 minutes to apply. Wait a few minutes and rerun the failed cell. If it stays red, keep the exact message and raise your hand. Don't install packages or change the deployment.

1. [] In section 1.11, run the broken call and read the one-line error.

> [!Knowledge] The aha in section 1.12: "it doesn't work" is useless; "check 5 failed" is a fix.

> [!Note] *Success:* every check in section 1.10 passes under your lab account.
