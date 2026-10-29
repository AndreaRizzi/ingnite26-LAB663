<!--
## Before you're done

This repo has been created for your Microsoft Ignite 2026 session. Here's how to get it ready.

**Easiest path — use the agent (recommended):**

- Open GitHub Copilot Chat and say `help me initialize repo`. The agent will walk you through getting the README populated.
- When you're ready to publish, say `help me finalize repo`. The agent will clean up unused folders, validate everything, and remove this "Before you're done" section and other extra stuff that attendees don't need to see.
- Curious how it works? Read the [agent workflow](.github/AGENT-WORKFLOW.md).

**Doing it manually?**

Fill in the sections below yourself, then:

- Delete any placeholder folders you don't need (`data/`, `infra/`, etc.)
- Delete this "Before you're done" section
- Delete `.github/agents/`, `.github/tests/`, `.github/copilot-instructions.md`, and `.github/AGENT-WORKFLOW.md` — these are template tooling, not part of your published repo

**Folder conventions:**

- Attendee step-by-step guidance goes in `instructions/`. If you use MkDocs or a docs site instead, put it in `docs/` and link to it from this README.
- Reference material and background reading go in `docs/`.
- You can add a `.devcontainer/` folder if needed.

---
-->

<a name="start-building"></a>

<p align="center">
<img src="img/banner-ignite-26.png" alt="Microsoft Ignite 2026" width="100%"/>
</p>

# [Microsoft Ignite 2026](https://ignite.microsoft.com)

## 🔥 [LAB663: Build smarter AI systems with model router and agent optimizer](https://ignite.microsoft.com/sessions/LAB663)

### Session description

As organizations scale AI, choosing a single model for every workload can lead to unnecessary costs and missed opportunities. In this lab, explore how model router in Foundry Models and agent optimizer can help organizations balance quality, performance, and cost across diverse use cases. We will break down popular design patterns that developers can use to optimize and scale agentic applications.


<br/>

### 🚀 Getting started

#### In a guided session

Follow the [guided Skillable walkthrough](instructions/skillable/README.md). The environment is pre-provisioned; learners do not deploy or delete Azure resources. Lab operators use the [Skillable lifecycle instructions](skillable_lifecycles/README.md) and must rehearse on the actual Skillable image and subscription before delivery.

#### On your own

If you're learning at your own pace:

1. Open this repository in the dev container or a Codespace. It brings Python, the Azure CLI and Bicep.
2. Run `bash infra/deploy.sh` from the repo root. It builds everything we need in our own Azure subscription and creates our first agent.
3. Follow the [self-guided walkthrough](instructions/self-guided/README.md). It takes us through the notebooks in [`labs/core/`](labs/core/), starting at `00-set-the-stage.ipynb`.

The core lab targets 60 minutes: 20 to set the stage and 40 for the climb. Deployment, VM preparation and the introductory reading happen before the clock starts. Service waits still need a timed rehearsal; additional model experiments and router editions are optional. While jobs run, try the [practice decisions](labs/more/00-practice-decisions.ipynb) without spending more model quota.

This is a code-first lab for beginner and intermediate participants. Basic Python helps; prior agent experience is not required. We measure one change at a time, keep the datasets and rubric fixed, and retain the baseline when the evidence does not support promotion. Unknown prices are not a cost saving.

<br/>
### 🎯 Learning outcomes

By the end of this session, you will be able to:

- Use model router in Foundry to automate model selection for reliable, cost-effective AI agents
- Use Rubric evaluator and insights in Foundry to assess agent behavior and identify optimization opportunities from production evidence
- Use agent optimizer in Foundry Agent Service to turn production evidence into continuous improvements in agent reliability and cost-effectiveness

### 💻 Technologies used

- Microsoft Foundry platform
- Rubric evaluator
- model router in Foundry
- insights in Foundry
- agent optimizer in Foundry Agent Service

### 📚 Continue your learning

Pick your next step based on your learning style:

| Resource | What you'll get |
|----------|-----------------|
| **[Ignite 2026 Next Steps](https://aka.ms/ignite26-next-steps)** | Additional session repos and materials from Microsoft Ignite 2026 |
| **[Microsoft AI Skills Navigator](https://aka.ms/ignite26-asn)** | Discover AI skills, learning paths, and resources for your next step |
| **[Microsoft Learn](https://aka.ms/ignite26-learn)** | Official documentation and guided learning paths on these topics |
| **[Microsoft Foundry Community](https://aka.ms/MicrosoftFoundryDiscord-Ignite26)** | Connect with other learners and experts in our Discord community |

### 🌟 Microsoft Learn MCP Server

<!-- Remove this section if the Microsoft Learn MCP Server is not relevant to the session. -->

The Microsoft Learn MCP Server gives your AI agent direct access to Microsoft's official documentation — grounded, up-to-date answers about the topics in this session.

**GitHub Copilot CLI** — Install with:

```shell
copilot plugin install microsoftdocs/mcp
```

**VS Code** — One-click install:  
[![Install in VS Code](https://img.shields.io/badge/VS_Code-Install_Microsoft_Learn_MCP-0098FF?style=flat-square&logo=visualstudiocode&logoColor=white)](https://vscode.dev/redirect/mcp/install?name=microsoft-learn&config=%7B%22type%22%3A%22http%22%2C%22url%22%3A%22https%3A%2F%2Flearn.microsoft.com%2Fapi%2Fmcp%22%7D)

For more information, visit the [Learn MCP Server repo](https://aka.ms/learnmcp).

### 👥 Content owners

<!-- TODO: Add yourself as a content owner
1. Change the src in the image tag to {your github url}.png
2. Change INSERT NAME HERE to your name
3. Change the github url in the final href to your url. -->

<table>
<tr>
    <td align="center"><a href="http://github.com/nitya">
        <img src="https://github.com/nitya.png" width="100px;" alt="Nitya Narasimhan"/><br />
        <sub><b>Nitya Narasimhan</b></sub></a><br />
            <a href="https://github.com/nitya" title="talk">📢</a>
    </td>
    <td align="center"><a href="http://github.com/leestott">
        <img src="https://github.com/leestott.png" width="100px;" alt="Lee Stott"/><br />
        <sub><b>Lee Stott</b></sub></a><br />
            <a href="https://github.com/leestott" title="talk">📢</a>
    </td>
</tr></table>

### ⚖️ Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/legal/intellectualproperty/trademarks/usage/general). Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.

Any use of third-party trademarks or logos are subject to those third-party's policies.
