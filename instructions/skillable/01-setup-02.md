# 1.2 Set up GitHub Copilot Chat

**What we'll do:** Sign in to GitHub Copilot in VS Code and check it can reach our Foundry project.

1. [] In VS Code, click the **Sign in** button in the top bar, next to the Copilot Chat icon.
1. [] Select **Continue with GitHub** and finish sign-in with the same lab credentials. Approve the browser prompts to authorize and return to VS Code.

    <!-- TODO screenshot: 01-setup-02-continue-with-github.png | The Sign in to use GitHub Copilot menu with Continue with GitHub highlighted -->

1. [] Open Copilot Chat and send this message.

    ++Hello! In two sentences, what is this repository about?++

1. [] Check that Copilot answers. If it asks to sign in to Azure, use the lab account.
1. [] Now check Copilot can reach Foundry. Send this message and wait for a list of agents.

    ++/microsoft-foundry List the agents in my Foundry project. Do not change anything.++

    <!-- TODO screenshot: 01-setup-02-copilot-agents.png | Copilot Chat listing the trailmate agent from the Foundry project -->
    <!-- VERIFY: the Foundry skill and Azure MCP sign-in work on the VM with this prompt -->

> [+Hint] Copilot shows an error
>
> If you see a license or access error, check that you signed in with the lab account, not a personal one. If it persists, raise your hand. The license server can take a few minutes to start.

---

> [!Note] **Success:** We just set up GitHub Copilot Chat. It can explain things and talk to our Foundry project whenever we get stuck.
