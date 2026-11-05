<!-- sync: source=labs/core/00-set-the-stage.ipynb sections=0.1,0.3,0.4,0.5,0.7,0.8 -->
# Sign in to your lab

Sign in to the virtual machine, then to GitHub, so GitHub Copilot works in VS Code.

1. [] Sign in to the virtual machine with this password.

   +++@lab.VirtualMachine(Win11-Pro-Base).Password+++

1. [] Note your lab credentials. You use them for GitHub and Azure.

   | Credential | Value |
   |:-----------|:------|
   | Username | +++@lab.CloudPortalCredential(User1).Username+++ |
   | Password | +++@lab.CloudPortalCredential(User1).Password+++ |

1. [] In the browser on the virtual machine, open the GitHub Enterprise sign-in page and sign in with your lab credentials.

   +++https://github.com/enterprises/skillable-events/sso+++

1. [] Open VS Code, select **Continue with GitHub**, and finish the sign-in through the same page.
1. [] In VS Code, open Copilot Chat and ask it to explain a Python list comprehension.

> [!Alert] Sign in to GitHub with your lab credentials, not a personal GitHub account. Copilot works only through this enterprise sign-in.

> [+Help] Copilot shows a missing-license or access-denied message.
>
> Raise your hand for a proctor. Don't switch to a personal account.

> [!Note] *Success:* Copilot answers your question under your lab account.

===

# Check your lab environment

Confirm the lab finished preparing your Foundry project before you start.

1. [] On the desktop, open the LAB663 status file. It's named LAB663-03-environment-status.txt or LAB663-deployment-output.txt, depending on the lab profile.
1. [] Confirm it says Result: SUCCEEDED and names your Foundry account and project.

   > [+Hint] It says RUNNING or FAILED.
   >
   > RUNNING means preparation is still going, so wait a few minutes and reopen the file. FAILED means don't start the lab: raise your hand and share the Stage and Error lines.

1. [] On the desktop, open the LAB663 folder in VS Code.
1. [] In VS Code, open a terminal with **Terminal > New Terminal**.
1. [] Sign in to Azure with your lab credentials, not a personal account.

   ++az login --tenant @lab.CloudSubscription.TenantId --use-device-code++

1. [] Check which account and subscription you're using.

   ++az account show --query "{subscription:name, tenant:tenantId, user:user.name}"++

> [!Knowledge] The lab already wrote a .env file at the repository root. It holds your project endpoint and model names, and no keys or passwords. You sign in with your own Azure identity instead.

> [!Alert] Don't run infra/deploy.sh or infra/cleanup.sh here. The lab environment deploys and removes everything for you.

> [!Note] *Success:* the status file says SUCCEEDED and az account show lists your lab account.

===

# Meet TrailMate

Read the story behind the lab before the timed modules start.

1. [] In VS Code, press **Ctrl+P**, paste this file name, and press **Enter**.

   ++00-set-the-stage.ipynb++

1. [] Select **Select Kernel** in the top-right corner, then select **Python (LAB663)**.
1. [] Run one cell at a time with **Shift+Enter**, and open the **Outline** view to see the numbered sections.
1. [] In section 0.1, meet TrailMate: an assistant that answers from ten product manuals and must never make things up.
1. [] In section 0.3, read the six ways an agent loses a customer's trust.
1. [] In section 0.4, run the cell and check the table has six rows, three columns, and two cases in every cell.
1. [] In section 0.5, read how the climb works: insights, a rubric, the optimizer and the router, one lever at a time.
1. [] In section 0.7, run the readiness check and confirm it finds your .env file.

> [!Knowledge] The aha in section 0.8: we aren't here to build a better agent. We're here to build a repeatable way to prove an agent got better.

> [!Note] *Success:* notebook 00 runs on Python (LAB663) and section 0.7 finds your .env file. This took about 5 minutes of reading.
