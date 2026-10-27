#!/usr/bin/env bash
#
# LAB663 learner setup for Skillable: find the pre-provisioned lab resources and write .env.
#
# Skillable deploys instructions/skillable/lab663-skillable.bicep into the lab resource group.
# This script only reads what's there. It doesn't deploy, change or delete anything in Azure.
#
# Run from anywhere:  bash instructions/skillable/setenv.sh
# Other group:        LAB663_RESOURCE_GROUP=my-group bash instructions/skillable/setenv.sh

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"
PYTHON="$REPO_ROOT/.venv/bin/python"

RESOURCE_GROUP="${LAB663_RESOURCE_GROUP:-LAB663}"
PROJECT_NAME="trailmate"
FRONTIER_MODEL="gpt-5.4"
SMALL_MODEL="gpt-5.4-mini"
REQUIRED_DEPLOYMENTS=("$FRONTIER_MODEL" "$SMALL_MODEL" mr-default mr-cost mr-quality mr-subset)

step() { printf '\n==> %s\n' "$*"; }
pass() { printf 'PASS %s\n' "$*"; }
stop() { printf 'ERROR %s\n' "$*"; exit 1; }

command -v az >/dev/null || stop "We need the Azure CLI (az). The dev container has it."

step "Checking our Azure sign-in"
if ! az account show >/dev/null 2>&1; then
  echo "We're not signed in yet. Follow the device code steps with the Skillable lab account."
  az login --use-device-code >/dev/null
fi
SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
TENANT_ID="$(az account show --query tenantId -o tsv)"
echo "Subscription: $(az account show --query name -o tsv)"
echo "Signed in as: $(az account show --query user.name -o tsv)"

step "Finding the lab resources in $RESOURCE_GROUP"
[[ "$(az group exists --name "$RESOURCE_GROUP")" == "true" ]] \
  || stop "Resource group '$RESOURCE_GROUP' doesn't exist. Check we're signed in to the lab subscription."

find_one() {
  local type="$1" prefix="$2" names count
  names="$(az resource list -g "$RESOURCE_GROUP" --resource-type "$type" \
    --query "[?starts_with(name, '$prefix')].name" -o tsv)"
  count="$(grep -c . <<<"$names" || true)"
  [[ "$count" -eq 1 ]] || stop "Expected one $type named $prefix* in $RESOURCE_GROUP, found $count. Ask the facilitator."
  echo "$names"
}
ACCOUNT_NAME="$(find_one Microsoft.CognitiveServices/accounts aif-lab663-)"
APPI_NAME="$(find_one Microsoft.Insights/components appi-lab663-)"
LOCATION="$(az resource show -g "$RESOURCE_GROUP" -n "$ACCOUNT_NAME" \
  --resource-type Microsoft.CognitiveServices/accounts --query location -o tsv)"
pass "Foundry resource $ACCOUNT_NAME in $LOCATION"
pass "Application Insights $APPI_NAME"

PROJECT_URL="https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.CognitiveServices/accounts/$ACCOUNT_NAME/projects/$PROJECT_NAME?api-version=2025-06-01"
PROJECT_ENDPOINT="$(az rest --method get --url "$PROJECT_URL" --query 'properties.endpoints."AI Foundry API"' -o tsv 2>/dev/null || true)"
[[ -n "$PROJECT_ENDPOINT" ]] || stop "Project '$PROJECT_NAME' wasn't found on $ACCOUNT_NAME. Ask the facilitator."
pass "project $PROJECT_NAME"

DEPLOYED="$(az cognitiveservices account deployment list -g "$RESOURCE_GROUP" -n "$ACCOUNT_NAME" \
  --query "[?properties.provisioningState=='Succeeded'].name" -o tsv)"
MISSING=()
for name in "${REQUIRED_DEPLOYMENTS[@]}"; do
  grep -qxF "$name" <<<"$DEPLOYED" || MISSING+=("$name")
done
[[ ${#MISSING[@]} -eq 0 ]] || stop "Missing model deployments: ${MISSING[*]}. Ask the facilitator."
pass "all six model deployments: ${REQUIRED_DEPLOYMENTS[*]}"

step "Writing $ENV_FILE"
if [[ -f "$ENV_FILE" ]] && { ! grep -qxF "AZURE_RESOURCE_GROUP=$RESOURCE_GROUP" "$ENV_FILE" \
    || ! grep -qxF "AZURE_AI_ACCOUNT_NAME=$ACCOUNT_NAME" "$ENV_FILE"; }; then
  stop ".env already exists for other lab resources. Move it aside and run this again."
fi
APPI_CONNECTION_STRING="$(az resource show -g "$RESOURCE_GROUP" -n "$APPI_NAME" \
  --resource-type Microsoft.Insights/components --query properties.ConnectionString -o tsv)"
umask 077
cat > "$ENV_FILE" <<EOF
# Written by instructions/skillable/setenv.sh. It stays on our machine and is never committed.
FOUNDRY_PROJECT_ENDPOINT=$PROJECT_ENDPOINT
TRAILMATE_AGENT_NAME=trailmate
TRAILMATE_MODEL_DEPLOYMENT=$FRONTIER_MODEL
TRAILMATE_SMALL_MODEL_DEPLOYMENT=$SMALL_MODEL
APPLICATIONINSIGHTS_CONNECTION_STRING=$APPI_CONNECTION_STRING
AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
AZURE_TENANT_ID=$TENANT_ID
AZURE_RESOURCE_GROUP=$RESOURCE_GROUP
AZURE_AI_ACCOUNT_NAME=$ACCOUNT_NAME
AZURE_AI_PROJECT_NAME=$PROJECT_NAME
AZURE_LOCATION=$LOCATION
LAB663_DELIVERY_MODE=skillable
EOF
pass "wrote .env (project endpoint: $PROJECT_ENDPOINT)"

echo
echo "Next, create the v0 agent (skip if it already exists):"
echo "  \"$PYTHON\" \"$REPO_ROOT/src/agent/01_build_agent.py\""
