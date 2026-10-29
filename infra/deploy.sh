#!/usr/bin/env bash
#
# Deploys the LAB663 environment into your own Azure subscription.
#
# What we get:
#   - A Foundry resource and project, with tracing wired up
#   - Chat models and four model router editions
#   - MAI-Image-2.6 and MAI-Image-2.6-Flash, for the optional image lab
#   - The access (RBAC) we need, assigned to us
#   - A local .env file and the v0 TrailMate agent
#
# Regions: use eastus (the default) or westus. Both offer every model this lab deploys,
# including the MAI image models; eastus2 does not offer MAI-Image-2.6.
#
# Run it from anywhere:  bash infra/deploy.sh
#
# The resource group is always new, named rg-lab663-NNNN with a number that isn't in use.
# To remove everything later:  bash infra/cleanup.sh
#
# We ask a few questions. To skip a question, set its variable first:
#   AZURE_SUBSCRIPTION_ID, AZURE_LOCATION,
#   LAB663_CHAT_MODELS (for example "gpt-5.4@2026-03-05,gpt-5.4-mini@2026-03-17"),
#   LAB663_IMAGE_MODELS (set it to "" to skip the image models),
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

# Valid regions: eastus and westus. Checked against the model catalog on 2026-10-29.
DEFAULT_LOCATION="eastus"
DEFAULT_CHAT_MODELS="gpt-5.4@2026-03-05,gpt-5.4-mini@2026-03-17"
DEFAULT_IMAGE_MODELS="MAI-Image-2.6@2026-07-31,MAI-Image-2.6-Flash@2026-07-31"
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
LOCATION="${AZURE_LOCATION:-$(ask "Azure region (eastus or westus)" "$DEFAULT_LOCATION")}"
if ! az account list-locations --query "[].name" -o tsv | grep -qxF "$LOCATION"; then
  echo "'$LOCATION' isn't an Azure region name. This lab supports eastus and westus."
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

IMAGE_MODELS="${LAB663_IMAGE_MODELS-$DEFAULT_IMAGE_MODELS}"
IMAGE_MODELS_JSON="$(IMAGE_MODELS="$IMAGE_MODELS" "$PYTHON" - <<'PY'
import json, os, sys
items = []
for part in filter(None, (p.strip() for p in os.environ["IMAGE_MODELS"].split(","))):
    name, _, version = part.partition("@")
    if not name or not version:
        sys.exit(f"'{part}' should look like name@version")
    items.append({"name": name, "version": version})
if items and len(items) != 2:
    sys.exit("The image lab needs two image models: best quality first, faster second. Set LAB663_IMAGE_MODELS=\"\" to skip them.")
print(json.dumps(items))
PY
)"
read -r IMAGE_HERO IMAGE_BULK < <(IMAGE_MODELS_JSON="$IMAGE_MODELS_JSON" "$PYTHON" -c \
  'import json, os; print(*(m["name"] for m in json.loads(os.environ["IMAGE_MODELS_JSON"])))')

# --- 4. Check the models exist in this region ---
step "Checking the models are available in $LOCATION"
# The full catalog is big, so we keep only names and versions and hand them over in a file.
CATALOG_FILE="$(mktemp)"
trap 'rm -f "$CATALOG_FILE"' EXIT
az cognitiveservices model list --location "$LOCATION" \
  --query "[].{name:model.name, version:model.version}" -o json > "$CATALOG_FILE"
MISSING="$(CATALOG_FILE="$CATALOG_FILE" CHAT_MODELS_JSON="$CHAT_MODELS_JSON" IMAGE_MODELS_JSON="$IMAGE_MODELS_JSON" "$PYTHON" - <<'PY'
import json, os
with open(os.environ["CATALOG_FILE"], encoding="utf-8") as f:
    catalog = {(m["name"], m["version"]) for m in json.load(f)}
wanted = [(m["name"], m["version"]) for m in json.loads(os.environ["CHAT_MODELS_JSON"])]
wanted += [(m["name"], m["version"]) for m in json.loads(os.environ["IMAGE_MODELS_JSON"])]
wanted.append(("model-router", "2025-11-18"))
print("\n".join(f"{n}@{v}" for n, v in wanted if (n, v) not in catalog))
PY
)"
if [[ -n "$MISSING" ]]; then
  echo "These models aren't in the $LOCATION catalog:"
  echo "$MISSING" | sed 's/^/  - /'
  echo "Use eastus or westus, or change the model list. Nothing was deployed."
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

# Roles we already hold (directly, through a group, or inherited from the subscription) are skipped, so reruns stay quiet.
LEARNER_ROLE_IDS="53ca6127-db72-4b80-b1b0-d745d6d5456d a97b65f3-24c7-4388-baec-2e87135dc908 73c42c96-874c-492b-b04d-ab87d138a893"
HELD_ROLE_IDS="$(az role assignment list --assignee "$PRINCIPAL_ID" --scope "/subscriptions/$AZURE_SUBSCRIPTION_ID" \
  --include-inherited --include-groups --query "[].roleDefinitionId" -o tsv 2>/dev/null | awk -F/ '{print $NF}' || true)"
SKIP_ROLE_IDS_JSON="$(LEARNER="$LEARNER_ROLE_IDS" HELD="$HELD_ROLE_IDS" "$PYTHON" -c \
  'import json, os; held = set(os.environ["HELD"].split()); print(json.dumps([r for r in os.environ["LEARNER"].split() if r in held]))')"
[[ "$SKIP_ROLE_IDS_JSON" == "[]" ]] || echo "Already held, so not assigned again: $SKIP_ROLE_IDS_JSON"

echo
echo "We're about to create:"
echo "  Resource group : $RESOURCE_GROUP"
echo "  Region         : $LOCATION"
echo "  Chat models    : $CHAT_MODELS"
echo "  Router editions: mr-default, mr-cost, mr-quality, mr-subset"
echo "  Image models   : ${IMAGE_MODELS:-none}"
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
               imageModels="$IMAGE_MODELS_JSON" \
               skipLearnerRoleIds="$SKIP_ROLE_IDS_JSON" \
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
MODEL_IMAGE_HERO=${IMAGE_HERO:-}
MODEL_IMAGE_BULK=${IMAGE_BULK:-}
# MAI voice and transcription come with the Foundry resource; nothing to deploy.
MODEL_VOICE_HERO=MAI-Voice-2.1
MODEL_VOICE_FAST=MAI-Voice-2.1-Flash
MODEL_TRANSCRIBE=MAI-Transcribe-2
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
