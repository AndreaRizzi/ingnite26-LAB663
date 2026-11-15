# 1.1 Set up the local environment

**What we'll do:** Confirm the lab prepared our Azure resources, open the lab in VS Code, and sign in to Azure.

## Check the environment status

1. [] On the virtual machine desktop, open **LAB663-03-environment-status.txt**.
1. [] Confirm it says **Result: SUCCEEDED** and names a Foundry account and project.

    <!-- TODO screenshot: 01-setup-01-status-file.png | The status file showing Result: SUCCEEDED -->

> [+Hint] It says RUNNING or FAILED
>
> **RUNNING:** the lab is still preparing. Wait a few minutes and open the file again. **FAILED:** don't continue. Raise your hand and share the **Stage** and **Error** lines.

## Open the lab in VS Code

1. [] On the desktop, open the **LAB663** folder in VS Code. If asked, select **Yes, I trust the authors**.
1. [] Open a terminal with **Terminal > New Terminal**.

## Sign in to Azure

1. [] In the terminal, run this command.

    ++az login --tenant @lab.CloudSubscription.TenantId --use-device-code++

1. [] Follow the prompt: open the link in Edge, paste the code, and pick the lab account you used on page 0.1.
1. [] Back in the terminal, confirm it shows the lab tenant and subscription.

    <!-- TODO screenshot: 01-setup-01-az-login.png | Terminal after az login showing the lab subscription -->

---

> [!Note] **Success:** We just confirmed our resources are ready, opened the lab, and signed in to Azure.
