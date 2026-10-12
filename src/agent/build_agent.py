"""Build the v1 TrailMate agent.

This script:
  1. Connects to our Foundry project.
  2. Uploads the product manuals into a vector store, so the agent can search them.
  3. Creates the TrailMate prompt agent (v1): a frontier model, simple instructions,
     and a file search tool over the manuals.

It is safe to run again. It reuses the vector store and the agent if they exist.

Run it:  python3 src/agent/build_agent.py
"""

import os
from pathlib import Path

from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import FileSearchTool, PromptAgentDefinition
from azure.core.exceptions import ResourceNotFoundError
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parents[1]
MANUALS_DIR = REPO_ROOT / "data" / "manuals"
INSTRUCTIONS_FILE = HERE / "instructions.md"
VECTOR_STORE_NAME = "trailmate-manuals"


def get_or_create_vector_store(openai_client):
    for store in openai_client.vector_stores.list():
        if store.name == VECTOR_STORE_NAME:
            print(f"Reusing the vector store '{VECTOR_STORE_NAME}' ({store.id}).")
            return store

    print("Creating the vector store and uploading the manuals...")
    store = openai_client.vector_stores.create(name=VECTOR_STORE_NAME)
    manuals = sorted(MANUALS_DIR.glob("*.md"))
    streams = [path.open("rb") for path in manuals]
    try:
        openai_client.vector_stores.file_batches.upload_and_poll(
            vector_store_id=store.id, files=streams
        )
    finally:
        for stream in streams:
            stream.close()
    print(f"Uploaded {len(manuals)} manuals.")
    return store


def main() -> None:
    # .env is written by infra/deploy.sh. We sign in with our own Azure identity, so there are no keys.
    load_dotenv(REPO_ROOT / ".env")
    endpoint = os.environ["FOUNDRY_PROJECT_ENDPOINT"]
    model = os.environ["TRAILMATE_MODEL_DEPLOYMENT"]
    agent_name = os.environ.get("TRAILMATE_AGENT_NAME", "trailmate")

    client = AIProjectClient(endpoint=endpoint, credential=DefaultAzureCredential())
    openai_client = client.get_openai_client()

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

    print("\nTrailMate v1 is ready.")
    print(f"  Agent        : {agent_name} (version {version.version})")
    print(f"  Model        : {model}")
    print(f"  Vector store : {vector_store.id}")


if __name__ == "__main__":
    main()
