"""Build the v0 TrailMate agent, our starting camp.

This script:
  1. Connects to our Foundry project.
  2. Uploads the product manuals into a vector store, so the agent can search them.
  3. Creates the TrailMate prompt agent (v0): a frontier model, a file search tool over
     the manuals, and deliberately generic instructions ("You are a helpful agent.").

In Module 4 we use the SDK to give it better instructions. That is v1.

It is safe to run again. It reuses the vector store and the agent if they exist.

Run it:  python3 src/agent/01_build_agent.py
"""

import os
import sys
import time
from pathlib import Path

from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import FileSearchTool, PromptAgentDefinition
from azure.core.exceptions import HttpResponseError, ResourceNotFoundError
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv
from openai import NotFoundError

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parents[1]
MANUALS_DIR = REPO_ROOT / "data" / "manuals"
INSTRUCTIONS_FILE = HERE / "instructions-v0.md"
VECTOR_STORE_NAME = "trailmate-manuals"
sys.path.insert(0, str(REPO_ROOT / "src"))
import lab


def wait_for_project(client, timeout_seconds=600):
    """A new project can take several minutes before its endpoint answers, so we wait and say so."""
    started = time.time()
    while True:
        try:
            next(iter(client.agents.list()), None)
            return
        except HttpResponseError as error:
            if error.status_code not in (403, 404):
                raise
            waited = int(time.time() - started)
            if waited >= timeout_seconds:
                raise TimeoutError(
                    f"The project still isn't reachable after {waited // 60} minutes. "
                    "Check the deployment and this identity's Foundry role, then run this script again."
                ) from error
            print(f"Project access returned HTTP {error.status_code} ({waited}s). "
                  "New projects and role assignments can take a few minutes. Checking again in 30 seconds...")
            time.sleep(30)


def wait_until_indexed(openai_client, store_id, expected, timeout_seconds=300):
    """Wait until every manual is indexed. Right after an upload the status call can briefly 404, so we retry."""
    deadline = time.time() + timeout_seconds
    while time.time() < deadline:
        try:
            counts = openai_client.vector_stores.retrieve(store_id).file_counts
            if counts.failed or counts.cancelled:
                raise RuntimeError(f"Manual indexing failed={counts.failed}, cancelled={counts.cancelled}.")
            if counts.completed > expected:
                raise RuntimeError("The index contains more than the expected frozen manuals. It was not changed.")
            if counts.completed == expected and counts.total == expected and counts.in_progress == 0:
                return
        except NotFoundError:
            print("The new vector store is not visible yet; checking again in 5 seconds...")
        time.sleep(5)
    raise TimeoutError("The manuals were not fully indexed in time.")


def get_or_create_vector_store(openai_client):
    manuals = sorted(MANUALS_DIR.glob("*.md"))
    if len(manuals) != 10:
        raise RuntimeError(f"Expected the 10 frozen product manuals; found {len(manuals)}.")
    state = lab.load_state()

    for store in openai_client.vector_stores.list():
        if store.name != VECTOR_STORE_NAME:
            continue
        if state.get("vector_store_id") != store.id:
            raise RuntimeError("A manuals index already exists without a matching local record. "
                               "Verify its files and recover the matching state before reusing it; it was not changed.")
        if store.file_counts.completed == len(manuals) and store.file_counts.total == len(manuals):
            print(f"Reusing the vector store '{VECTOR_STORE_NAME}' ({store.id}).")
            return store
        raise RuntimeError(
            f"Vector store '{store.id}' exists but is incomplete. Inspect its indexing errors "
            "before retrying; it may already be attached to an agent, so it was not deleted."
        )

    print("Creating the vector store and uploading the manuals...")
    store = openai_client.vector_stores.create(name=VECTOR_STORE_NAME)
    lab.save_state(vector_store_id=store.id)
    file_ids = []
    for path in manuals:
        with path.open("rb") as handle:
            file_ids.append(openai_client.files.create(file=handle, purpose="assistants").id)
    openai_client.vector_stores.file_batches.create(vector_store_id=store.id, file_ids=file_ids)
    wait_until_indexed(openai_client, store.id, len(manuals))
    print(f"Uploaded and indexed {len(manuals)} manuals.")
    return store


def main() -> None:
    # Delivery setup writes .env; Azure identity supplies access without model API keys.
    load_dotenv(REPO_ROOT / ".env")
    endpoint = os.environ["FOUNDRY_PROJECT_ENDPOINT"]
    model = os.environ["TRAILMATE_MODEL_DEPLOYMENT"]
    agent_name = os.environ.get("TRAILMATE_AGENT_NAME", "trailmate")
    lab.load_state()

    client = AIProjectClient(endpoint=endpoint, credential=DefaultAzureCredential())
    openai_client = client.get_openai_client()

    wait_for_project(client)
    vector_store = get_or_create_vector_store(openai_client)

    try:
        existing = list(client.agents.list_versions(agent_name))
    except ResourceNotFoundError:
        existing = []

    if existing:
        expected = INSTRUCTIONS_FILE.read_text(encoding="utf-8").strip()
        baselines = [
            version for version in existing
            if isinstance(version.definition, PromptAgentDefinition)
            and version.definition.model == model and (version.definition.instructions or "").strip() == expected
            and any(vector_store.id in (getattr(tool, "vector_store_ids", None) or []) for tool in (version.definition.tools or []))
        ]
        if not baselines:
            raise RuntimeError("The agent exists, but no version matches v0 and this vector store. It was not overwritten.")
        baseline = min(baselines, key=lambda version: int(version.version))
        lab.save_state(v0_version=str(baseline.version), vector_store_id=vector_store.id)
        print(f"TrailMate v0 is ready. Reusing the pinned Foundry version {baseline.version}; other versions are unchanged.")
        return

    definition = PromptAgentDefinition(
        model=model,
        instructions=INSTRUCTIONS_FILE.read_text(encoding="utf-8"),
        tools=[FileSearchTool(vector_store_ids=[vector_store.id])],
    )
    print(f"Creating the agent '{agent_name}' on '{model}'...")
    version = client.agents.create_version(agent_name, definition=definition)
    lab.save_state(v0_version=str(version.version), vector_store_id=vector_store.id)

    print("\nTrailMate v0 is ready.")
    print(f"  Agent        : {agent_name} (version {version.version})")
    print(f"  Model        : {model}")
    print(f"  Vector store : {vector_store.id}")


if __name__ == "__main__":
    main()
