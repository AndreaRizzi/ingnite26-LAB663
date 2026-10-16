"""Check the lab's Python requirements without installing packages or contacting Azure."""

from __future__ import annotations

import argparse
import subprocess
import sys
from importlib.metadata import PackageNotFoundError, version
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def check_environment(root: Path = ROOT) -> list[str]:
    if sys.version_info < (3, 10):
        return ["Python 3.10 or later is required by the notebook helpers."]
    try:
        from packaging.requirements import Requirement
    except ModuleNotFoundError as error:
        if error.name != "packaging":
            raise
        return ["packaging is missing; prepare the Python environment from requirements.txt."]

    failures: list[str] = []

    def check_requirements(path: Path) -> None:
        for line in path.read_text(encoding="utf-8").splitlines():
            line = line.split("#", 1)[0].strip()
            if not line:
                continue
            if line.startswith("-r "):
                check_requirements(path.parent / line[3:].strip())
                continue
            requirement = Requirement(line)
            if requirement.marker and not requirement.marker.evaluate():
                continue
            try:
                installed = version(requirement.name)
            except PackageNotFoundError:
                failures.append(f"{requirement.name}: not installed")
                continue
            if installed not in requirement.specifier:
                failures.append(f"{requirement.name}: {installed} does not satisfy {requirement.specifier}")
            else:
                print(f"PASS {requirement.name} {installed}")

    check_requirements(root / "requirements.txt")
    if failures:
        return failures

    from azure.ai.projects import AIProjectClient
    from azure.identity import DefaultAzureCredential

    # Client construction is local; these capability checks never request a token.
    with DefaultAzureCredential() as credential, AIProjectClient(
        endpoint="https://example.invalid/api/projects/preflight",
        credential=credential,
        allow_preview=True,
    ) as client:
        for capability in (
            "evaluators.begin_create_generation_job",
            "evaluators.get_version",
            "beta.agent_insight_monitors.begin_create_run",
            "agents.begin_create_optimization_job",
            "agents.get_optimization_job",
            "agents.promote_optimization_candidate",
        ):
            operation = client
            for part in capability.split("."):
                operation = getattr(operation, part, None)
            if not callable(operation):
                failures.append(f"Foundry SDK operation is unavailable: {capability}")

    import pandas as pd

    pd.DataFrame({"score": [0.0, 1.0]}).style.background_gradient(cmap="RdYlGn", vmin=0, vmax=1).to_html()
    return failures


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--register-kernel", action="store_true", help="Register Python (LAB663) only after all checks pass.")
    arguments = parser.parse_args()
    print(f"Python interpreter: {sys.executable}")
    issues = check_environment()
    if issues:
        raise SystemExit("Python environment is not ready:\n" + "\n".join(issues))
    if arguments.register_kernel:
        subprocess.run(
            [sys.executable, "-m", "ipykernel", "install", "--user", "--name", "lab663", "--display-name", "Python (LAB663)"],
            check=True,
        )
    print("PASS Python requirements, Foundry SDK capabilities and table rendering; Azure access is checked separately.")
