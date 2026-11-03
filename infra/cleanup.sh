#!/usr/bin/env bash
#
# Deletes the resource group that infra/deploy.sh created. By default, that is all it does.
#
# Run it:                 bash infra/cleanup.sh
# Name a group yourself:  bash infra/cleanup.sh rg-lab663-1234
# Also purge the deleted Foundry resource (frees its model quota):  bash infra/cleanup.sh --purge
#
# Safety:
#   - It deletes only the one resource group, in one named subscription.
#   - It lists what's inside and makes us type the group's name to confirm.
#   - It never touches our local files. Delete .env and .lab-state.json yourself if you want to.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"

PURGE=false
RESOURCE_GROUP=""
for arg in "$@"; do
  case "$arg" in
    --purge) PURGE=true ;;
    -*) echo "Unknown option: $arg"; exit 1 ;;
    *) RESOURCE_GROUP="$arg" ;;
  esac
done

# Read one value from .env without running it as code.
env_value() { grep -E "^$1=" "$ENV_FILE" 2>/dev/null | head -n1 | cut -d= -f2- || true; }

ENV_GROUP="$(env_value AZURE_RESOURCE_GROUP)"
RESOURCE_GROUP="${RESOURCE_GROUP:-$ENV_GROUP}"
[[ -n "$RESOURCE_GROUP" ]] || { echo "No resource group found. Pass one:  bash infra/cleanup.sh rg-lab663-1234"; exit 1; }
az account show >/dev/null 2>&1 || { echo "We're not signed in. Run:  az login --use-device-code"; exit 1; }

# Use the subscription we deployed into, but only when the group is the one in .env.
SUBSCRIPTION_ID=""
if [[ "$RESOURCE_GROUP" == "$ENV_GROUP" ]]; then
  SUBSCRIPTION_ID="$(env_value AZURE_SUBSCRIPTION_ID)"
fi
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-$(az account show --query id -o tsv)}"
SUBSCRIPTION_NAME="$(az account show --subscription "$SUBSCRIPTION_ID" --query name -o tsv)"

if [[ "$(az group exists --name "$RESOURCE_GROUP" --subscription "$SUBSCRIPTION_ID")" != "true" ]]; then
  echo "The resource group '$RESOURCE_GROUP' doesn't exist in subscription '$SUBSCRIPTION_NAME'. Nothing to delete."
  exit 0
fi

echo "Subscription  : $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
echo "Resource group: $RESOURCE_GROUP"
echo
echo "This is everything inside it:"
az resource list --resource-group "$RESOURCE_GROUP" --subscription "$SUBSCRIPTION_ID" \
  --query "[].{Name:name, Type:type}" -o table
echo

# For --purge we need the Foundry resource's name and region, and the group is the only place to look them up.
ACCOUNT_NAME=""
LOCATION=""
if $PURGE; then
  ACCOUNT_NAME="$(az cognitiveservices account list --resource-group "$RESOURCE_GROUP" --subscription "$SUBSCRIPTION_ID" \
    --query "[?kind=='AIServices'].name | [0]" -o tsv)"
  LOCATION="$(az cognitiveservices account list --resource-group "$RESOURCE_GROUP" --subscription "$SUBSCRIPTION_ID" \
    --query "[?kind=='AIServices'].location | [0]" -o tsv)"
fi

echo "Deleting the group removes all of it, and can't be undone."
read -r -p "To confirm, type the resource group name: " typed
[[ "$typed" == "$RESOURCE_GROUP" ]] || { echo "That doesn't match. Nothing was deleted."; exit 0; }

echo "Deleting (this takes a few minutes)..."
az group delete --name "$RESOURCE_GROUP" --subscription "$SUBSCRIPTION_ID" --yes
echo "Deleted '$RESOURCE_GROUP' from '$SUBSCRIPTION_NAME'."

if $PURGE && [[ -n "$ACCOUNT_NAME" && -n "$LOCATION" ]]; then
  if az cognitiveservices account list-deleted --subscription "$SUBSCRIPTION_ID" \
       --query "[?name=='$ACCOUNT_NAME'] | [0].name" -o tsv | grep -q .; then
    echo "Purging the deleted Foundry resource '$ACCOUNT_NAME'..."
    az cognitiveservices account purge --location "$LOCATION" --resource-group "$RESOURCE_GROUP" \
      --name "$ACCOUNT_NAME" --subscription "$SUBSCRIPTION_ID" --output none
    echo "Purged."
  else
    echo "No deleted Foundry resource named '$ACCOUNT_NAME' to purge."
  fi
fi

echo "Nothing else was changed. Our local .env and .lab-state.json are still here."
