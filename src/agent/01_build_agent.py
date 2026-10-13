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
import time
from pathlib import Path

from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import FileSearchTool, PromptAgentDefinition
from azure.core.exceptions import ResourceNotFoundError
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv
from openai import NotFoundError

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parents[1]
MANUALS_DIR = REPO_ROOT / "data" / "manuals"
INSTRUCTIONS_FILE = HERE / "instructions-v0.md"
VECTOR_STORE_NAME = "trailmate-manuals"


def wait_for_project(client, timeout_seconds=600):
    """A new project can take several minutes before its endpoint answers, so we wait and say so."""
    started = time.time()
    while True:
        try:
            next(iter(client.agents.list()), None)
            return
        except ResourceNotFoundError:
            waited = int(time.time() - started)
            if waited >= timeout_seconds:
                raise TimeoutError(
                    f"The project still isn't reachable after {waited // 60} minutes. "
                    "Check that it exists in the Foundry portal, then run this script again."
                )
            print(f"The project isn't reachable yet ({waited}s). New projects can take a few minutes. Checking again in 30 seconds...")
            time.sleep(30)


def wait_until_indexed(openai_client, store_id, expected, timeout_seconds=300):
    """Wait until every manual is indexed. Right after an upload the status call can briefly 404, so we retry."""
    deadline = time.time() + timeout_seconds
    while time.time() < deadline:
        try:
            counts = openai_client.vector_stores.retrieve(store_id).file_counts
            if counts.failed:
                raise RuntimeError(f"{counts.failed} manual(s) failed to index.")
            if counts.completed >= expected:
                return
        except NotFoundError:
            pass
        time.sleep(5)
    raise TimeoutError("The manuals were not fully indexed in time.")


def get_or_create_vector_store(openai_client):
    manuals = sorted(MANUALS_DIR.glob("*.md"))

    for store in openai_client.vector_stores.list():
        if store.name != VECTOR_STORE_NAME:
            continue
        if store.file_counts.completed >= len(manuals):
            print(f"Reusing the vector store '{VECTOR_STORE_NAME}' ({store.id}).")
            return store
        # An earlier run stopped halfway, so we start clean.
        print("Found a half-finished vector store from an earlier run. Replacing it.")
        openai_client.vector_stores.delete(store.id)

    print("Creating the vector store and uploading the manuals...")
    store = openai_client.vector_stores.create(name=VECTOR_STORE_NAME)
    file_ids = []
    for path in manuals:
        with path.open("rb") as handle:
            file_ids.append(openai_client.files.create(file=handle, purpose="assistants").id)
    openai_client.vector_stores.file_batches.create(vector_store_id=store.id, file_ids=file_ids)
    wait_until_indexed(openai_client, store.id, len(manuals))
    print(f"Uploaded and indexed {len(manuals)} manuals.")
    return store


def main() -> None:
    # .env is written by infra/deploy.sh. We sign in with our own Azure identity, so there are no keys.
    load_dotenv(REPO_ROOT / ".env")
    endpoint = os.environ["FOUNDRY_PROJECT_ENDPOINT"]
    model = os.environ["TRAILMATE_MODEL_DEPLOYMENT"]
    agent_name = os.environ.get("TRAILMATE_AGENT_NAME", "trailmate")

    client = AIProjectClient(endpoint=endpoint, credential=DefaultAzureCredential())
    openai_client = client.get_openai_client()

    wait_for_project(client)
    vector_store = get_or_create_vector_store(openai_client)

    try:
        existing = list(client.agents.list_versions(agent_name))
    except ResourceNotFoundError:
        existing = []

    if existing:
        print(f"The agent '{agent_name}' already exists, so we're keeping it as is.")
        return

    definition = PromptAgentDefinition(
        model=model,
        instructions=INSTRUCTIONS_FILE.read_text(encoding="utf-8"),
        tools=[FileSearchTool(vector_store_ids=[vector_store.id])],
    )
    print(f"Creating the agent '{agent_name}' on '{model}'...")
    version = client.agents.create_version(agent_name, definition=definition)

    print("\nTrailMate v0 is ready.")
    print(f"  Agent        : {agent_name} (version {version.version})")
    print(f"  Model        : {model}")
    print(f"  Vector store : {vector_store.id}")


if __name__ == "__main__":
    main()
