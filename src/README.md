# Source

The notebooks keep the important Foundry calls visible. These files handle shared connection, measurement and setup details.

| File | Purpose |
|---|---|
| [`check_environment.py`](check_environment.py) | Check package versions, required SDK operations and heatmap rendering before any Azure deployment |
| [`lab.py`](lab.py) | Read settings, connect, record actual deployment configuration, resume bounded evaluation waits and summarize complete results |
| [`agent/01_build_agent.py`](agent/01_build_agent.py) | Upload the ten manuals and create or reuse a matching v0; save the actual agent/index IDs |
| [`02_validate_data.py`](02_validate_data.py) | Validate case structure, split separation and quoted manual evidence |
| [`agent/requirements.txt`](agent/requirements.txt) | Foundry SDK and authentication requirements |

Use the repository's `.venv` for scripts and the registered **Python (LAB663)** notebook kernel. The shared environment check does not install packages or contact Azure; its optional `--register-kernel` flag registers the kernel only after a successful check. Both deployment paths run the check before provisioning unless an operator explicitly selects infrastructure-only mode.

## How we protect a comparison

Each evaluation repeat must contain exactly one finite 0-to-1 rubric score per expected query. Failed, cancelled, skipped, duplicate or missing items invalidate the batch. The result retains its errors and evidence path, but publishes no aggregate score or cost for promotion.

`.lab-state.json` binds saved IDs to the project, agent and frozen data fingerprints. `.lab-results/` holds raw service records, SDK versions and the deployment snapshot. These files are local and ignored by Git; do not commit them. Main notebooks run sequentially, while the practice decisions notebook in `labs/more/` only reads local evidence.

Run IDs are saved as soon as the service returns them. A rerun resumes that batch; after repairing a failed run, an explicit higher `attempt` starts a new one. A timeout stops local waiting, not the remote service job.

The usage helper subtracts measured judge usage from each model and reconciles the remaining totals with the agent aggregate. Missing attribution, missing cached-input prices or mismatched pricing regions make estimated model cost unknown. Request latency and local wait time for the current cell execution are reported separately. A resumed cell can finish quickly because its service job already ran; that is not a faster model.
