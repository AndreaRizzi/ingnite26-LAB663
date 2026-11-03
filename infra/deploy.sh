#!/usr/bin/env bash
#
# Deploys the LAB663 environment into your own Azure subscription.
#
# What we get:
#   - A Foundry resource and project, with tracing wired up
#   - Chat models and four model router editions
#   - The access (RBAC) we need, assigned to us
#   - A local .env file and the v0 TrailMate agent
#
# Run it from anywhere:  bash infra/deploy.sh
#
# The resource group is always new, named rg-lab663-NNNN with a number that isn't in use.
# To remove everything later:  bash infra/cleanup.sh
#
# We ask a few questions. To skip a question, set its variable first:
#   AZURE_SUBSCRIPTION_ID, AZURE_LOCATION,
#   LAB663_CHAT_MODELS (for example "gpt-5.4@2026-03-05,gpt-5.4-mini@2026-03-17"),
#   LAB663_CAPACITY
#
# Flags:
#   --yes          accept every default without asking
#   --skip-agent   deploy the infrastructure only, skip the v0 agent

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"

ASSUME_YES=false
SKIP_AGENT=false
for arg in "$@"; do
  case "$arg" in
    --yes) ASSUME_YES=true ;;
    --skip-agent) SKIP_AGENT=true ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

DEFAULT_LOCATION="eastus"
DEFAULT_CHAT_MODELS="gpt-5.4@2026-03-05,gpt-5.4-mini@2026-03-17"
DEFAULT_CAPACITY="250"

step() { printf '\n==> %s\n' "$*"; }

# Ask a question, show a default, and keep the default when we press Enter.
ask() {
  local prompt="$1" default="$2" reply
  if $ASSUME_YES; then echo "$default"; return; fi
  read -r -p "$prompt [$default]: " reply
  echo "${reply:-$default}"
}

command -v az >/dev/null || { echo "We need the Azure CLI (az). The dev container has it."; exit 1; }
PYTHON="$REPO_ROOT/.venv/bin/python"
if [[ ! -x "$PYTHON" && -x "$REPO_ROOT/.venv/Scripts/python.exe" ]]; then
  PYTHON="$REPO_ROOT/.venv/Scripts/python.exe"
fi
[[ -x "$PYTHON" ]] || { echo "The repository .venv is missing. Prepare it from requirements.txt before deploying."; exit 1; }

if $SKIP_AGENT; then
  echo "Infrastructure-only rehearsal: Python package and agent checks are skipped; this is not learner-ready."
else
  "$PYTHON" "$REPO_ROOT/src/check_environment.py"
fi

# --- 1. Sign in ---
step "Checking our Azure sign-in"
if ! az account show >/dev/null 2>&1; then
  echo "We're not signed in yet. Follow the device code steps."
  az login --use-device-code >/dev/null
fi

# --- 2. Subscription ---
if [[ -z "${AZURE_SUBSCRIPTION_ID:-}" ]]; then
  CURRENT_SUB="$(az account show --query id -o tsv)"
  if ! $ASSUME_YES; then
    echo
    echo "Our subscriptions:"
    az account list --query "[].{Name:name, Id:id}" -o table
  fi
  AZURE_SUBSCRIPTION_ID="$(ask "Subscription ID to deploy into" "$CURRENT_SUB")"
fi
az account set --subscription "$AZURE_SUBSCRIPTION_ID"
echo "Using subscription: $(az account show --query name -o tsv)"

# --- 3. Location, resource group, models ---
LOCATION="${AZURE_LOCATION:-$(ask "Azure region" "$DEFAULT_LOCATION")}"
if ! az account list-locations --query "[].name" -o tsv | grep -qxF "$LOCATION"; then
  echo "'$LOCATION' isn't an Azure region name. Examples: eastus, swedencentral, westus3."
  exit 1
fi

# A new group every run keeps old attempts from clashing with new ones (deleted Foundry resources linger for a while).
RESOURCE_GROUP=""
while [[ -z "$RESOURCE_GROUP" ]]; do
  candidate="rg-lab663-$((RANDOM % 9000 + 1000))"
  [[ "$(az group exists --name "$candidate")" == "false" ]] && RESOURCE_GROUP="$candidate"
done
CHAT_MODELS="${LAB663_CHAT_MODELS:-$(ask "Chat models to deploy (name@version, comma separated)" "$DEFAULT_CHAT_MODELS")}"
CAPACITY="${LAB663_CAPACITY:-$DEFAULT_CAPACITY}"

# Turn "name@version,name@version" into the JSON array the template wants.
CHAT_MODELS_JSON="$(CHAT_MODELS="$CHAT_MODELS" "$PYTHON" - <<'PY'
import json, os, sys
items = []
for part in os.environ["CHAT_MODELS"].split(","):
    name, _, version = part.strip().partition("@")
    if not name or not version:
        sys.exit(f"'{part}' should look like name@version")
    items.append({"name": name, "version": version})
if len(items) != 2 or len({item["name"] for item in items}) != 2:
    sys.exit("This lab needs exactly two distinct chat models: frontier first, smaller model second.")
print(json.dumps(items))
PY
)"
read -r FRONTIER_MODEL SMALL_MODEL < <(CHAT_MODELS_JSON="$CHAT_MODELS_JSON" "$PYTHON" -c \
  'import json, os; print(*(m["name"] for m in json.loads(os.environ["CHAT_MODELS_JSON"])))')

# --- 4. Check the models exist in this region ---
step "Checking the models are available in $LOCATION"
# The full catalog is big, so we keep only names and versions and hand them over in a file.
CATALOG_FILE="$(mktemp)"
trap 'rm -f "$CATALOG_FILE"' EXIT
az cognitiveservices model list --location "$LOCATION" \
  --query "[].{name:model.name, version:model.version}" -o json > "$CATALOG_FILE"
MISSING="$(CATALOG_FILE="$CATALOG_FILE" CHAT_MODELS_JSON="$CHAT_MODELS_JSON" "$PYTHON" - <<'PY'
import json, os
with open(os.environ["CATALOG_FILE"], encoding="utf-8") as f:
    catalog = {(m["name"], m["version"]) for m in json.load(f)}
wanted = [(m["name"], m["version"]) for m in json.loads(os.environ["CHAT_MODELS_JSON"])]
wanted.append(("model-router", "2025-11-18"))
print("\n".join(f"{n}@{v}" for n, v in wanted if (n, v) not in catalog))
PY
)"
if [[ -n "$MISSING" ]]; then
  echo "These models aren't in the $LOCATION catalog:"
  echo "$MISSING" | sed 's/^/  - /'
  echo "We can pick another region, or change the model list. Nothing was deployed."
  exit 1
fi
echo "All models found."

# --- 5. Who gets access ---
PRINCIPAL_TYPE="User"
if ! PRINCIPAL_ID="${LAB663_PRINCIPAL_ID:-$(az ad signed-in-user show --query id -o tsv 2>/dev/null)}" || [[ -z "$PRINCIPAL_ID" ]]; then
  echo "We couldn't read our own user ID (are we signed in as a service principal?)."
  echo "Set LAB663_PRINCIPAL_ID to the object ID that needs access, and LAB663_PRINCIPAL_TYPE if it isn't a User."
  exit 1
fi
PRINCIPAL_TYPE="${LAB663_PRINCIPAL_TYPE:-$PRINCIPAL_TYPE}"

echo
echo "We're about to create:"
echo "  Resource group : $RESOURCE_GROUP"
echo "  Region         : $LOCATION"
echo "  Chat models    : $CHAT_MODELS"
echo "  Router editions: mr-default, mr-cost, mr-quality, mr-subset"
if ! $ASSUME_YES; then
  read -r -p "Go ahead? [y/N] " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Cancelled. Nothing was created."; exit 0; }
fi

# --- 6. Deploy ---
step "Registering the Azure services we need"
for ns in Microsoft.CognitiveServices Microsoft.Insights Microsoft.OperationalInsights; do
  state="$(az provider show --namespace "$ns" --query registrationState -o tsv)"
  [[ "$state" == "Registered" ]] || az provider register --namespace "$ns" --wait
done

step "Creating the resource group"
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none

step "Deploying with Bicep (this takes a few minutes)"
DEPLOYMENT_NAME="lab663-$(date +%Y%m%d%H%M%S)"
az deployment group create \
  --name "$DEPLOYMENT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$SCRIPT_DIR/main.bicep" \
  --parameters location="$LOCATION" \
               principalId="$PRINCIPAL_ID" \
               principalType="$PRINCIPAL_TYPE" \
               capacity="$CAPACITY" \
               chatModels="$CHAT_MODELS_JSON" \
  --output none

# --- 7. Write .env ---
step "Writing $ENV_FILE"
output() { az deployment group show -g "$RESOURCE_GROUP" -n "$DEPLOYMENT_NAME" --query "properties.outputs.$1.value" -o tsv; }
ACCOUNT_NAME="$(output accountName)"
PROJECT_NAME="$(output projectName)"
PROJECT_ENDPOINT="$(output projectEndpoint)"
APPI_NAME="$(output applicationInsightsName)"
APPI_CONNECTION_STRING="$(az resource show -g "$RESOURCE_GROUP" -n "$APPI_NAME" \
  --resource-type Microsoft.Insights/components --query properties.ConnectionString -o tsv)"

umask 077
cat > "$ENV_FILE" <<EOF
# Written by infra/deploy.sh. It stays on our machine and is never committed.
FOUNDRY_PROJECT_ENDPOINT=$PROJECT_ENDPOINT
TRAILMATE_AGENT_NAME=trailmate
TRAILMATE_MODEL_DEPLOYMENT=$FRONTIER_MODEL
TRAILMATE_SMALL_MODEL_DEPLOYMENT=$SMALL_MODEL
APPLICATIONINSIGHTS_CONNECTION_STRING=$APPI_CONNECTION_STRING
AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID
AZURE_RESOURCE_GROUP=$RESOURCE_GROUP
AZURE_AI_ACCOUNT_NAME=$ACCOUNT_NAME
AZURE_AI_PROJECT_NAME=$PROJECT_NAME
AZURE_LOCATION=$LOCATION
LAB663_DELIVERY_MODE=self-guided
EOF
echo "Done. Project endpoint: $PROJECT_ENDPOINT"

# --- 8. Create the v0 agent ---
if $SKIP_AGENT; then
  echo
  echo "Skipped the agent. When we're ready:  \"$PYTHON\" \"$REPO_ROOT/src/agent/01_build_agent.py\""
  exit 0
fi

step "Creating the v0 TrailMate agent"
# The agent script waits for a new project to become reachable. We retry once in case something else hiccups.
for attempt in 1 2; do
  if "$PYTHON" "$REPO_ROOT/src/agent/01_build_agent.py"; then
    echo
    echo "All set. Next, open labs/core/ and start with the first notebook."
    exit 0
  fi
  if [[ $attempt -lt 2 ]]; then
    echo "The agent step didn't finish (attempt $attempt of 2). Trying once more in 30 seconds..."
    sleep 30
  fi
done

echo "The agent step didn't finish. Our infrastructure is fine. Run this when ready:"
echo "  \"$PYTHON\" \"$REPO_ROOT/src/agent/01_build_agent.py\""
exit 1
