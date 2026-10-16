"""Small helpers for the lab notebooks.

The notebooks show every important Foundry call so we can see what is happening.
This file only holds the plumbing: reading .env, connecting, calling an agent,
running a batch of evals, and turning results into numbers.
"""

import os
import time
import json
import hashlib
import math
import re
import shutil
import subprocess
from collections import Counter
from datetime import datetime, timezone
from importlib.metadata import version
from pathlib import Path
from statistics import median, quantiles

from dotenv import load_dotenv
from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient
from azure.core.pipeline.policies import SansIOHTTPPolicy

REPO = Path(__file__).resolve().parents[1]
DATA = REPO / "data"
AGENT_DIR = REPO / "src" / "agent"

load_dotenv(REPO / ".env")

AGENT_NAME = os.environ.get("TRAILMATE_AGENT_NAME", "trailmate")
FRONTIER_MODEL = os.environ.get("TRAILMATE_MODEL_DEPLOYMENT", "gpt-5.4")
SMALL_MODEL = os.environ.get("TRAILMATE_SMALL_MODEL_DEPLOYMENT", "gpt-5.4-mini")
ROUTERS = ["mr-default", "mr-cost", "mr-quality", "mr-subset"]
REQUIRED_ENV = [
    "FOUNDRY_PROJECT_ENDPOINT",
    "TRAILMATE_AGENT_NAME",
    "TRAILMATE_MODEL_DEPLOYMENT",
    "APPLICATIONINSIGHTS_CONNECTION_STRING",
]
WAYS = ["wrong_product", "overclaiming", "making_things_up", "wrong_premise", "out_of_lane", "not_useful"]


class EnsureEvalPreviewHeader(SansIOHTTPPolicy):
    """The evaluators API is in preview and needs an opt-in header on every call."""

    def on_request(self, request):
        headers = request.http_request.headers
        current = headers.get("Foundry-Features")
        if not current:
            headers["Foundry-Features"] = "Evaluations=V1Preview"
        elif "Evaluations=" not in current:
            headers["Foundry-Features"] = current + ",Evaluations=V1Preview"


def missing_env() -> list[str]:
    return [name for name in REQUIRED_ENV if not os.environ.get(name)]


def record_deployment_configuration() -> dict:
    """Record actual routing modes, model versions and capacity through the signed-in Azure CLI."""
    azure_cli = shutil.which("az")
    if azure_cli is None:
        raise FileNotFoundError("Azure CLI is required to record the deployed routing configuration.")
    command = [
        azure_cli, "cognitiveservices", "account", "deployment", "list",
        "--subscription", os.environ["AZURE_SUBSCRIPTION_ID"],
        "--resource-group", os.environ["AZURE_RESOURCE_GROUP"],
        "--name", os.environ["AZURE_AI_ACCOUNT_NAME"],
        "--query", "[].{name:name,model:properties.model,sku:sku,routing:properties.routing}",
        "--output", "json", "--only-show-errors",
    ]
    try:
        response = subprocess.run(command, check=True, capture_output=True, text=True, encoding="utf-8")
    except subprocess.CalledProcessError as error:
        raise RuntimeError(f"Cannot read deployed routing settings. Check the learner's resource access:\n{error.stderr}") from error
    configuration = sorted(json.loads(response.stdout), key=lambda deployment: deployment["name"])
    names = {deployment["name"] for deployment in configuration}
    if not {FRONTIER_MODEL, SMALL_MODEL, *ROUTERS} <= names:
        raise RuntimeError("The deployment snapshot is missing a required chat model or router edition.")
    state = load_state()
    if "deployment_configuration" in state and state["deployment_configuration"] != configuration:
        raise RuntimeError("Deployed model settings changed during the experiment. Preserve the results and remeasure every baseline.")
    snapshot = {"recorded_at": datetime.now(timezone.utc).isoformat(), "deployments": configuration}
    save_state(deployment_configuration=configuration, deployment_snapshot=snapshot)
    return snapshot


def connect():
    """Return (project_client, openai_client). We sign in with our own Azure identity, so there are no keys."""
    project_client = AIProjectClient(
        endpoint=os.environ["FOUNDRY_PROJECT_ENDPOINT"],
        credential=DefaultAzureCredential(),
        allow_preview=True,
        per_call_policies=[EnsureEvalPreviewHeader()],
    )
    return project_client, project_client.get_openai_client()


def load_cases(split: str) -> list[dict]:
    path = DATA / f"{split}.jsonl"
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def manual_text(number: int) -> str:
    return (DATA / "manuals" / f"product_info_{number}.md").read_text(encoding="utf-8")


def ask_agent(openai_client, question: str, agent_name: str = AGENT_NAME, agent_version=None, model: str = FRONTIER_MODEL):
    """Ask a registered agent a question. Every call leaves a trace we can look at later."""
    reference = {"name": agent_name, "type": "agent_reference"}
    if agent_version is not None:
        reference["version"] = str(agent_version)
    return openai_client.responses.create(
        model=model,  # must match the agent's own model, for example a router edition
        input=question,
        extra_body={"agent_reference": reference},
    )


def _get(obj, key, default=None):
    """Read a field from an SDK object or a plain dict."""
    if isinstance(obj, dict):
        return obj.get(key, default)
    return getattr(obj, key, default)


def start_eval_run(openai_client, eval_id, dataset_id, agent_name, agent_version, label):
    """Start one eval run. The service asks the agent every question, then the judge scores each answer."""
    return openai_client.evals.runs.create(
        eval_id=eval_id,
        name=label,
        data_source={
            "type": "azure_ai_target_completions",
            "source": {"type": "file_id", "id": dataset_id},
            "input_messages": {
                "type": "template",
                "template": [
                    {"type": "message", "role": "user", "content": {"type": "input_text", "text": "{{item.query}}"}}
                ],
            },
            "target": {"type": "azure_ai_agent", "name": agent_name, "version": str(agent_version)},
        },
    )


def wait_for_runs(openai_client, eval_id, runs, poll_seconds: int = 15, timeout_seconds: int = 1200):
    """Bound the wait, not the service job. Saved run IDs let the same cell resume."""
    if poll_seconds <= 0 or timeout_seconds <= 0:
        raise ValueError("Polling interval and timeout must be positive.")
    started = time.monotonic()
    done = {}
    while len(done) < len(runs):
        statuses = []
        for run in runs:
            if run.id in done:
                continue
            latest = openai_client.evals.runs.retrieve(run_id=run.id, eval_id=eval_id)
            statuses.append(f"{run.id}: {latest.status}")
            if latest.status in ("completed", "failed", "canceled", "cancelled"):
                done[run.id] = latest
        if len(done) < len(runs):
            elapsed = int(time.monotonic() - started)
            print(f"{elapsed}s waiting; {len(done)}/{len(runs)} finished. " + "; ".join(statuses), flush=True)
            if elapsed >= timeout_seconds:
                raise TimeoutError(
                    "Evaluation is still running. Its IDs are saved in .lab-state.json. "
                    "Rerun this cell to resume, not submit another batch. "
                    "While waiting, open labs/bonus/wait-time-challenges.ipynb."
                )
            time.sleep(poll_seconds)
    return [done[run.id] for run in runs]


def wait_for_poller(poller, label: str, timeout_seconds: int = 900):
    """Show progress for a long-running SDK operation without claiming a time guarantee."""
    started = time.monotonic()
    while not poller.done():
        elapsed = int(time.monotonic() - started)
        print(f"{label}: {poller.status()} ({elapsed}s). The bonus notebook needs no Azure calls.", flush=True)
        if elapsed >= timeout_seconds:
            raise TimeoutError(
                f"{label} is still running. Keep this kernel open and call "
                "lab.wait_for_poller(poller, ...) again; do not resubmit the job."
            )
        time.sleep(15)
    return poller.result()


def wait_for_optimization_job(project_client, job_id: str, timeout_seconds: int = 1200):
    """Resume an optimizer job by its saved ID, including after a kernel restart."""
    started = time.monotonic()
    while True:
        job = project_client.agents.get_optimization_job(job_id)
        status = _get(job.status, "value", job.status)
        if status == "succeeded":
            return job.result
        if status in ("failed", "cancelled", "canceled"):
            raise RuntimeError(f"Optimization {job_id} {status}: {job.error}")
        elapsed = int(time.monotonic() - started)
        print(f"Optimizer {job_id}: {status} ({elapsed}s). Try a local wait-time challenge.", flush=True)
        if elapsed >= timeout_seconds:
            raise TimeoutError(f"Optimizer {job_id} is still running. Rerun this cell to resume the saved job.")
        time.sleep(15)


def item_scores(items, cases: list[dict]) -> dict[str, float]:
    """Accept exactly one finite rubric score for every expected question."""
    expected = {case["query"] for case in cases}
    if not cases or len(expected) != len(cases):
        raise ValueError("Evaluation cases must be nonempty and have unique queries.")
    scores = {}
    for item in items:
        query = _get(_get(item, "datasource_item", {}) or {}, "query")
        if query not in expected or query in scores:
            raise ValueError(f"Unexpected or duplicate evaluation query: {query!r}")
        sample = _get(item, "sample")
        if _get(item, "status") != "completed" or _get(sample, "error"):
            raise ValueError(f"Unscored query {query!r}: {_get(sample, 'error') or _get(item, 'status')}")
        results = [r for r in (_get(item, "results", []) or []) if _get(r, "type") == "azure_ai_evaluator"]
        if len(results) != 1 or _get(results[0], "score") is None:
            raise ValueError(f"Expected one rubric score for {query!r}.")
        if _get(results[0], "status") not in (None, "completed"):
            raise ValueError(f"The judge did not finish scoring {query!r}.")
        score = float(_get(results[0], "score"))
        if not math.isfinite(score) or not 0 <= score <= 1:
            raise ValueError(f"Rubric score outside 0..1 for {query!r}: {score}")
        scores[query] = score
    if scores.keys() != expected:
        raise ValueError(f"Only {len(scores)}/{len(expected)} questions received a score.")
    return scores


def agent_usage(run, items) -> dict:
    """Subtract measured judge usage, then reconcile model totals with the target aggregate."""
    fields = ("prompt_tokens", "completion_tokens", "cached_tokens", "total_tokens")
    rows = {}
    for usage in _get(run, "per_model_usage", []) or []:
        name = _get(usage, "model_name") or _get(usage, "run_model_name")
        if not name or name in rows:
            return {"tokens": None, "dollars": None, "reason": "Missing or duplicate model usage rows."}
        rows[name] = {field: _get(usage, field) for field in fields}
    target = rows.pop("azure_ai_agent_target", None)
    rows.pop("azure_ai_evaluation", None)
    tokens = _get(target, "total_tokens")
    unknown = {"tokens": tokens, "dollars": None}
    if not target or any(value is None for row in [target, *rows.values()] for value in row.values()):
        return {**unknown, "reason": "Token/cache attribution is incomplete; cost is unknown."}
    for item in items:
        for result in _get(item, "results", []) or []:
            sample = _get(result, "sample")
            name, usage = _get(sample, "model"), _get(sample, "usage")
            if name not in rows or any(_get(usage, field) is None for field in fields):
                return {**unknown, "reason": "Judge usage cannot be separated by model; cost is unknown."}
            for field in fields:
                rows[name][field] -= _get(usage, field)
    if any(value < 0 for row in rows.values() for value in row.values()) or any(
        sum(row[field] for row in rows.values()) != target[field] for field in fields
    ):
        return {**unknown, "reason": "Model usage does not reconcile with agent totals; cost is unknown."}
    rows = {name: row for name, row in rows.items() if row["total_tokens"]}
    costs = [
        cost_of(name, row["prompt_tokens"], row["completion_tokens"], row["cached_tokens"])
        for name, row in rows.items()
    ]
    dollars = sum(costs) if costs and all(cost is not None for cost in costs) else None
    return {
        "tokens": tokens,
        "dollars": dollars,
        "models": rows,
        "reason": None if dollars is not None else "Verified prices for this region and every serving model are required.",
    }


def run_repeated_eval(
    openai_client, eval_id, dataset_id, agent_name, agent_version, label, *,
    cases: list[dict], repeats: int = 2, attempt: int = 1,
):
    """Resume a measured batch; incomplete batches are diagnostic evidence, never a score."""
    if repeats < 2 or attempt < 1:
        raise ValueError("Use at least two repeats and a positive attempt number.")
    if not cases or len({case["query"] for case in cases}) != len(cases):
        raise ValueError("Provide the complete, unique question set for coverage checks.")
    started = time.perf_counter()
    key = hashlib.sha256(json.dumps(
        [eval_id, dataset_id, agent_name, str(agent_version), label, repeats, attempt, cases], sort_keys=True
    ).encode()).hexdigest()[:20]
    batches = load_state().get("eval_batches", {})
    run_ids = batches.get(key, [])
    runs = [openai_client.evals.runs.retrieve(run_id=run_id, eval_id=eval_id) for run_id in run_ids]
    for i in range(len(runs), repeats):
        run = start_eval_run(openai_client, eval_id, dataset_id, agent_name, agent_version, f"{label} (repeat {i + 1}, attempt {attempt})")
        runs.append(run)
        batches[key] = [r.id for r in runs]
        save_state(eval_batches=batches)
        print(f"Started {label}: {run.id}", flush=True)
    runs = wait_for_runs(openai_client, eval_id, runs)
    seconds = round(time.perf_counter() - started, 1)
    outputs = [list(openai_client.evals.runs.output_items.list(run_id=run.id, eval_id=eval_id)) for run in runs]
    artifact = REPO / ".lab-results" / f"{key}.json"
    artifact.parent.mkdir(exist_ok=True)
    artifact.write_text(json.dumps({
        "context": measurement_context(), "label": label, "evaluation_id": eval_id,
        "recorded_at": datetime.now(timezone.utc).isoformat(),
        "deployment_snapshot": load_state().get("deployment_snapshot"),
        "sdk_versions": {name: version(name) for name in ("azure-ai-projects", "openai", "azure-identity")},
        "dataset_id": dataset_id, "agent_name": agent_name, "agent_version": str(agent_version),
        "runs": [{"run": run.model_dump(mode="json"), "items": [item.model_dump(mode="json") for item in items]}
                 for run, items in zip(runs, outputs)],
    }, indent=2), encoding="utf-8")

    reasons, per_repeat, details, usage = [], [], [], []
    coverage = []
    for run, items in zip(runs, outputs):
        counts = run.result_counts
        if run.status != "completed" or _get(counts, "errored", 0) or _get(counts, "skipped", 0):
            reasons.append(f"{run.id}: status={run.status}, counts={counts}")
        try:
            scores = item_scores(items, cases)
            per_repeat.append(scores)
            coverage.append(len(scores))
        except ValueError as error:
            reasons.append(f"{run.id}: {error}")
            coverage.append(sum(
                not _get(_get(item, "sample"), "error") and any(
                    _get(result, "score") is not None for result in (_get(item, "results", []) or [])
                ) for item in items
            ))
        usage.append(agent_usage(run, items))
        for item in items:
            source, sample = _get(item, "datasource_item", {}), _get(item, "sample")
            result = next(iter(_get(item, "results", []) or []), {})
            details.append({
                "run_id": run.id, "id": _get(source, "id"), "query": _get(source, "query"),
                "model": _get(sample, "model"), "score": _get(result, "score"),
                "error": str(_get(sample, "error")) if _get(sample, "error") else None,
                "reason": _get(result, "reason"), "latency_ms": _get(sample, "latency_ms"),
            })
    valid = not reasons
    repeat_means = [sum(scores.values()) / len(cases) for scores in per_repeat] if valid else []
    per_item = {
        case["query"]: sum(scores[case["query"]] for scores in per_repeat) / repeats for case in cases
    } if valid else {}
    tokens = [u["tokens"] for u in usage]
    costs = [u["dollars"] for u in usage]
    latencies = [d["latency_ms"] / 1000 for d in details if d["latency_ms"] is not None]
    if not valid:
        print(f"INVALID {label}: no comparable score or cost.\n" + "\n".join(reasons), flush=True)
        print(f"Inspect {artifact.relative_to(REPO)}. Fix the error before explicitly requesting attempt={attempt + 1}.")
    for reason in sorted({u["reason"] for u in usage if u["reason"]}):
        print(f"{label}: {reason}")
    return {
        "label": label, "valid": valid, "invalid_reasons": reasons,
        "agent_name": agent_name, "agent_version": str(agent_version),
        "run_ids": [run.id for run in runs], "artifact": str(artifact.relative_to(REPO)),
        "repeat_means": repeat_means,
        "score": sum(repeat_means) / repeats if valid else None,
        "spread": max(repeat_means) - min(repeat_means) if valid else None,
        "tokens": sum(tokens) / repeats if valid and all(t is not None for t in tokens) else None,
        "dollars": sum(costs) / repeats if valid and all(c is not None for c in costs) else None,
        "models": sorted({d["model"] for d in details if d["model"]}),
        "model_counts": dict(Counter(d["model"] for d in details if d["model"] and not d["error"])),
        "usage": usage,
        "seconds": seconds,
        "p50_seconds": median(latencies) if valid and len(latencies) == len(details) else None,
        "p95_seconds": quantiles(latencies, n=20, method="inclusive")[18]
        if valid and len(latencies) == len(details) and len(latencies) >= 2 else None,
        "errored": sum((_get(run.result_counts, "errored", 0) or 0) for run in runs),
        "expected_per_repeat": len(cases),
        "scored_per_repeat": coverage,
        "per_item": per_item, "items": details, "status": [run.status for run in runs],
    }


def scores_by(per_item: dict[str, float], cases: list[dict], key: str) -> dict[str, float]:
    """Average the rubric score for each value of `key` (for example `way` or `difficulty`)."""
    groups: dict[str, list[float]] = {}
    for case in cases:
        if case["query"] in per_item:
            groups.setdefault(case[key], []).append(per_item[case["query"]])
    return {name: sum(v) / len(v) for name, v in groups.items()}


def scores_by_way(per_item: dict[str, float], cases: list[dict]) -> dict[str, float | None]:
    """Average the rubric score for each of the six ways, so we can see where we are weak."""
    by_way = scores_by(per_item, cases, "way")
    return {way: by_way.get(way) for way in WAYS}


STATE_FILE = REPO / ".lab-state.json"


def measurement_context() -> dict:
    paths = [DATA / f"{split}.jsonl" for split in ("practice", "dev", "test")]
    paths += sorted((DATA / "manuals").glob("*.md"))
    return {
        "schema": 2,
        "project_endpoint": os.environ.get("FOUNDRY_PROJECT_ENDPOINT", "").rstrip("/"),
        "agent_name": AGENT_NAME,
        "data_sha256": {str(path.relative_to(DATA)): hashlib.sha256(path.read_bytes()).hexdigest() for path in paths},
    }


def save_state(**values) -> None:
    """Remember a few facts between notebooks (rubric name, versions, scores). The file stays local."""
    state = load_state()
    state.update(values)
    state["_context"] = measurement_context()
    temporary = STATE_FILE.with_suffix(".json.tmp")
    temporary.write_text(json.dumps(state, indent=2), encoding="utf-8")
    temporary.replace(STATE_FILE)


def load_state() -> dict:
    if not STATE_FILE.exists():
        return {}
    state = json.loads(STATE_FILE.read_text(encoding="utf-8"))
    if state.get("_context") != measurement_context():
        raise RuntimeError(
            "Saved state belongs to a different project, dataset or lab format. "
            "Preserve .lab-state.json and .lab-results elsewhere, then start a fresh measurement. "
            "Do not compare old scores with this run."
        )
    return state


def require_valid(*results) -> None:
    invalid = [r["label"] for r in results if not r.get("valid")]
    if invalid:
        raise RuntimeError("Incomplete evaluations cannot be compared or promoted: " + ", ".join(invalid))


def quality_failures(candidate: dict, baseline: dict, cases: list[dict], tolerance: float) -> list[str]:
    """A teaching gate: protect the overall score, each category and each answerable guard case."""
    if not 0 <= tolerance <= 1:
        raise ValueError("Quality tolerance must be between 0 and 1.")
    if not candidate.get("valid") or not baseline.get("valid"):
        return ["Incomplete evaluation coverage."]
    expected = {case["query"] for case in cases}
    if not expected or any(set(result["per_item"]) != expected for result in (candidate, baseline)):
        return ["The results do not cover the same complete question set."]
    failures = []
    if candidate["score"] + tolerance + 1e-12 < baseline["score"]:
        failures.append("Overall quality fell beyond the predeclared tolerance.")
    for key in ("difficulty", "way"):
        before, after = (scores_by(r["per_item"], cases, key) for r in (baseline, candidate))
        for name in before:
            if name not in after or after[name] + tolerance + 1e-12 < before[name]:
                failures.append(f"{key}={name}: quality fell beyond tolerance.")
    for case in cases:
        if case["guard"] and candidate["per_item"][case["query"]] + 1e-12 < baseline["per_item"][case["query"]]:
            failures.append(f"Guard {case['id']}: the answerable question got worse.")
    return failures


def price_table() -> dict:
    return json.loads((DATA / "pricing.json").read_text(encoding="utf-8"))["models"]


def cost_of(model: str, input_tokens: int, output_tokens: int, cached_tokens: int = 0):
    """Return dollars, or None if we haven't filled in that model's prices yet."""
    if any(value is None for value in (input_tokens, output_tokens, cached_tokens)):
        return None
    if any(not math.isfinite(value) for value in (input_tokens, output_tokens, cached_tokens)):
        raise ValueError("Token counts must be finite.")
    if not 0 <= cached_tokens <= input_tokens or output_tokens < 0:
        raise ValueError("Invalid input, output or cached token counts.")
    pricing = json.loads((DATA / "pricing.json").read_text(encoding="utf-8"))
    if (pricing["currency"] != "USD" or pricing["region"] != os.environ.get("AZURE_LOCATION")
            or not pricing.get("as_of") or not pricing.get("source_url")):
        return None
    prices = pricing["models"]
    name = model if model in prices else re.sub(r"-\d{4}-\d{2}-\d{2}$", "", model)
    price = prices.get(name, {})
    fields = ["input_per_million", "output_per_million"]
    if cached_tokens:
        fields.append("cached_input_per_million")
    if any(price.get(field) is None for field in fields):
        return None
    if any(not math.isfinite(price[field]) or price[field] < 0 for field in fields):
        raise ValueError(f"Invalid price for {name}.")
    return (
        (input_tokens - cached_tokens) * price["input_per_million"]
        + output_tokens * price["output_per_million"]
        + cached_tokens * (price.get("cached_input_per_million") or 0)
    ) / 1_000_000
