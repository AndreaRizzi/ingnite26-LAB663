"""Small helpers for the lab notebooks.

The notebooks show every important Foundry call so we can see what is happening.
This file only holds the plumbing: reading .env, connecting, calling an agent,
running a batch of evals, and turning results into numbers.
"""

import os
import time
import json
from pathlib import Path

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
SMALL_MODEL = "gpt-5.4-mini"
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


def connect():
    """Return (project_client, openai_client). We sign in with our own Azure identity, so there are no keys."""
    project_client = AIProjectClient(
        endpoint=os.environ["FOUNDRY_PROJECT_ENDPOINT"],
        credential=DefaultAzureCredential(),
        per_call_policies=[EnsureEvalPreviewHeader()],
    )
    return project_client, project_client.get_openai_client()


def load_cases(split: str) -> list[dict]:
    path = DATA / f"{split}.jsonl"
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def manual_text(number: int) -> str:
    return (DATA / "manuals" / f"product_info_{number}.md").read_text(encoding="utf-8")


def ask_agent(openai_client, question: str, agent_name: str = AGENT_NAME, agent_version=None):
    """Ask a registered agent a question. Every call leaves a trace we can look at later."""
    reference = {"name": agent_name, "type": "agent_reference"}
    if agent_version is not None:
        reference["version"] = str(agent_version)
    return openai_client.responses.create(
        model=FRONTIER_MODEL,
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


def wait_for_runs(openai_client, eval_id, runs, poll_seconds: int = 5):
    """Wait for every run to finish. Starting them together keeps repeats fast."""
    done = {}
    while len(done) < len(runs):
        for run in runs:
            if run.id in done:
                continue
            latest = openai_client.evals.runs.retrieve(run_id=run.id, eval_id=eval_id)
            if latest.status in ("completed", "failed", "canceled"):
                done[run.id] = latest
        if len(done) < len(runs):
            time.sleep(poll_seconds)
    return [done[run.id] for run in runs]


def item_scores(openai_client, eval_id, run) -> dict[str, float]:
    """Map each question to its rubric score (1 to 5) for one run."""
    scores = {}
    for item in openai_client.evals.runs.output_items.list(run_id=run.id, eval_id=eval_id):
        query = _get(_get(item, "datasource_item", {}) or {}, "query")
        for result in _get(item, "results", []) or []:
            # Custom evaluators report the number in one entry and the reason in another.
            if _get(result, "metric") == "custom_score" and _get(result, "score") is not None:
                scores[query] = float(_get(result, "score"))
    return scores


def run_repeated_eval(openai_client, eval_id, dataset_id, agent_name, agent_version, label, repeats: int = 2):
    """Run the same eval `repeats` times and average, so one lucky or unlucky run doesn't fool us."""
    started = time.perf_counter()
    runs = [
        start_eval_run(openai_client, eval_id, dataset_id, agent_name, agent_version, f"{label} (repeat {i + 1})")
        for i in range(repeats)
    ]
    runs = wait_for_runs(openai_client, eval_id, runs)
    seconds = round(time.perf_counter() - started, 1)

    per_repeat = [item_scores(openai_client, eval_id, run) for run in runs]
    repeat_means = [round(sum(s.values()) / len(s), 2) for s in per_repeat if s]
    per_item = {}
    for scores in per_repeat:
        for query, score in scores.items():
            per_item.setdefault(query, []).append(score)
    per_item = {query: sum(v) / len(v) for query, v in per_item.items()}

    usage = [u for run in runs for u in (run.per_model_usage or [])]
    return {
        "label": label,
        "agent_version": agent_version,
        "repeat_means": repeat_means,
        "score": round(sum(repeat_means) / len(repeat_means), 2) if repeat_means else None,
        "spread": round(max(repeat_means) - min(repeat_means), 2) if len(repeat_means) > 1 else None,
        "tokens": sum(_get(u, "total_tokens", 0) or 0 for u in usage) // max(len(runs), 1),
        "models": sorted({_get(u, "run_model_name", "?") for u in usage}) or ["?"],
        "seconds": seconds,
        "errored": sum((_get(run.result_counts, "errored", 0) or 0) for run in runs),
        "per_item": per_item,
        "status": [run.status for run in runs],
    }


def scores_by(per_item: dict[str, float], cases: list[dict], key: str) -> dict[str, float]:
    """Average the rubric score for each value of `key` (for example `way` or `difficulty`)."""
    groups: dict[str, list[float]] = {}
    for case in cases:
        if case["query"] in per_item:
            groups.setdefault(case[key], []).append(per_item[case["query"]])
    return {name: round(sum(v) / len(v), 2) for name, v in groups.items()}


def scores_by_way(per_item: dict[str, float], cases: list[dict]) -> dict[str, float]:
    """Average the rubric score for each of the six ways, so we can see where we are weak."""
    by_way = scores_by(per_item, cases, "way")
    return {way: by_way.get(way) for way in WAYS}


STATE_FILE = REPO / ".lab-state.json"


def save_state(**values) -> None:
    """Remember a few facts between notebooks (rubric name, versions, scores). The file stays local."""
    state = load_state()
    state.update(values)
    STATE_FILE.write_text(json.dumps(state, indent=2), encoding="utf-8")


def load_state() -> dict:
    return json.loads(STATE_FILE.read_text(encoding="utf-8")) if STATE_FILE.exists() else {}


def price_table() -> dict:
    return json.loads((DATA / "pricing.json").read_text(encoding="utf-8"))["models"]


def cost_of(model: str, input_tokens: int, output_tokens: int):
    """Return dollars, or None if we haven't filled in that model's prices yet."""
    price = price_table().get(model, {})
    if price.get("input_per_million") is None or price.get("output_per_million") is None:
        return None
    return (input_tokens * price["input_per_million"] + output_tokens * price["output_per_million"]) / 1_000_000
