# 0.1 Sign in to your lab

**What we'll do:** Sign in to the virtual machine, then to GitHub, so GitHub Copilot works in VS Code.

1. [] Check that you see the **Instructions** and **Resources** tabs on the right, and the virtual machine's sign-in screen on the left.

    <!-- TODO screenshot: 00-start-01-lab-tabs.png | Lab interface with the Instructions and Resources tabs and the VM sign-in screen -->

1. [] Click in the password field on the virtual machine, then click the password below to type it in.

    +++@lab.VirtualMachine(Win11-Pro-Base).Password+++

1. [] On the virtual machine, open **Microsoft Edge** and go to the GitHub Enterprise sign-in page.

    +++https://github.com/enterprises/skillable-events/sso+++

1. [] Sign in with your lab credentials. We use the same ones for GitHub and Azure.

    | Credential | Value |
    |:-----------|:------|
    | Username | +++@lab.CloudPortalCredential(User1).Username+++ |
    | TAP | +++@lab.CloudPortalCredential(User1).AccessToken+++ |

    <!-- TODO screenshot: 00-start-01-github-signed-in.png | GitHub showing the signed-in lab account after SSO -->

1. [] Leave Edge open. We'll come back to it.

> [!Alert] Use the lab credentials, **not** a personal GitHub or Azure account. If sign-in fails, raise your hand.

---

> [!Note] **Success:** We just signed in to the virtual machine and to GitHub with our lab identity.
