#!/usr/bin/env bash
#
# Phase one Skillable test: deploy LAB663 as the Skillable learner, the way Skillable will.
#
# What it does:
#   - Checks the Skillable resource group (LAB663 by default) and the roles Skillable grants the learner
#   - Checks services are registered and models and quota are available in the chosen region
#   - Deploys instructions/skillable/lab663-skillable.bicep with assignRoles=false (the learner can't assign roles)
#   - Runs setenv.sh to write .env from what was deployed
#
# It does not create the v0 agent, register services or assign roles.
# For testing only: in the real lab, Skillable deploys the Bicep file and learners run setenv.sh.
#
# Run from anywhere:  bash instructions/skillable/test-deploy.sh
#
# Settings (environment variables, defaults in brackets):
#   LAB663_LOCATION            [swedencentral]  one of: swedencentral eastus eastus2
#   LAB663_FRONTIER_CAPACITY   [250]            gpt-5.4: runs the agent and the evaluation judge
#   LAB663_SMALL_CAPACITY      [150]            gpt-5.4-mini
#   LAB663_ROUTER_CAPACITY     [150]            each of the four model router editions
#   LAB663_RESOURCE_GROUP      [LAB663]

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
PYTHON="$REPO_ROOT/.venv/bin/python"
TEMPLATE="$SCRIPT_DIR/lab663-skillable.bicep"

ALLOWED_LOCATIONS=(swedencentral eastus eastus2)
RESOURCE_GROUP="${LAB663_RESOURCE_GROUP:-LAB663}"
LOCATION="${LAB663_LOCATION:-swedencentral}"
FRONTIER_CAPACITY="${LAB663_FRONTIER_CAPACITY:-250}"
SMALL_CAPACITY="${LAB663_SMALL_CAPACITY:-150}"
ROUTER_CAPACITY="${LAB663_ROUTER_CAPACITY:-150}"
DEPLOYMENT_NAME="lab663-skillable-test"

step() { printf '\n==> %s\n' "$*"; }
pass() { printf 'PASS %s\n' "$*"; }
fail() { printf 'FAIL %s\n' "$*"; }
info() { printf 'INFO %s\n' "$*"; }

command -v az >/dev/null || { echo "We need the Azure CLI (az). The dev container has it."; exit 1; }
[[ -x "$PYTHON" ]] || { echo "The repository .venv is missing. Rebuild the dev container first."; exit 1; }
[[ " ${ALLOWED_LOCATIONS[*]} " == *" $LOCATION "* ]] \
  || { echo "LAB663_LOCATION must be one of: ${ALLOWED_LOCATIONS[*]} (got '$LOCATION')."; exit 1; }

step "Checking our Python environment"
"$PYTHON" "$REPO_ROOT/src/check_environment.py"

# --- 1. Sign in ---
step "Checking our Azure sign-in"
if ! az account show >/dev/null 2>&1; then
  echo "We're not signed in yet. Follow the device code steps with the Skillable lab account."
  az login --use-device-code >/dev/null
fi
echo "Subscription: $(az account show --query name -o tsv)"
echo "Signed in as: $(az account show --query user.name -o tsv)"
PRINCIPAL_ID="$(az ad signed-in-user show --query id -o tsv 2>/dev/null || true)"
[[ -n "$PRINCIPAL_ID" ]] || { echo "We couldn't read our user object ID. Sign in as the Skillable user, not a service principal."; exit 1; }

# --- 2. Resource group ---
step "Checking the resource group $RESOURCE_GROUP"
if [[ "$(az group exists --name "$RESOURCE_GROUP")" != "true" ]]; then
  echo "ERROR: resource group '$RESOURCE_GROUP' doesn't exist in this subscription."
  echo "Skillable should create it with the lab instance. Check we're signed in to the right subscription."
  echo "Nothing was deployed."
  exit 1
fi
RG_LOCATION="$(az group show --name "$RESOURCE_GROUP" --query location -o tsv)"
LAB_INSTANCE="$(az group show --name "$RESOURCE_GROUP" --query "tags.LabInstance" -o tsv)"
pass "resource group $RESOURCE_GROUP exists (group region: $RG_LOCATION, lab instance: ${LAB_INSTANCE:-none})"
info "resources deploy to $LOCATION; the group's own region doesn't limit that"
EXISTING_ACCOUNT="$(az resource list -g "$RESOURCE_GROUP" --resource-type Microsoft.CognitiveServices/accounts \
  --query "[?starts_with(name, 'aif-lab663-')] | [0].{name:name, location:location}" -o tsv)"
if [[ -n "$EXISTING_ACCOUNT" ]]; then
  read -r EXISTING_NAME EXISTING_LOCATION <<<"$EXISTING_ACCOUNT"
  if [[ "$EXISTING_LOCATION" != "$LOCATION" ]]; then
    echo "ERROR: $EXISTING_NAME already exists in $EXISTING_LOCATION, and a Foundry resource can't move region."
    echo "Use LAB663_LOCATION=$EXISTING_LOCATION, or delete and purge it first. Nothing was deployed."
    exit 1
  fi
  info "updating the existing $EXISTING_NAME"
fi

# --- 3. Default roles ---
step "Checking the roles Skillable granted us"
ROLES="$(az role assignment list --assignee "$PRINCIPAL_ID" --resource-group "$RESOURCE_GROUP" \
  --include-inherited --query "[].roleDefinitionName" -o tsv | sort -u)"
echo "$ROLES" | sed 's/^/  - /'
has_role() { grep -qxF "$1" <<<"$ROLES"; }
ROLE_FAILURES=0
if has_role "Owner" || has_role "Contributor" || has_role "LOD Contributor"; then
  pass "can create resources (Owner, Contributor or LOD Contributor)"
else
  fail "can't create resources: needs Owner, Contributor or LOD Contributor"; ROLE_FAILURES=1
fi
if has_role "Foundry User" || has_role "Azure AI User"; then
  pass "can use Foundry projects and agents (Foundry User)"
else
  fail "can't use Foundry projects and agents: needs Foundry User"; ROLE_FAILURES=1
fi
if has_role "Cognitive Services Contributor"; then
  pass "Cognitive Services Contributor"
else
  info "no Cognitive Services Contributor (not required when we have a contributor role)"
fi
if has_role "Owner" || has_role "User Access Administrator" || has_role "Role Based Access Control Administrator"; then
  info "we can assign roles, but this test still skips role assignments"
else
  info "we can't assign roles, so role assignments are skipped"
fi
[[ $ROLE_FAILURES -eq 0 ]] || { echo "Missing roles. Nothing was deployed."; exit 1; }

# --- 4. Services ---
step "Checking the Azure services are registered"
SERVICE_FAILURES=0
for ns in Microsoft.CognitiveServices Microsoft.Insights Microsoft.OperationalInsights; do
  state="$(az provider show --namespace "$ns" --query registrationState -o tsv)"
  if [[ "$state" == "Registered" ]]; then pass "$ns"; else fail "$ns is $state"; SERVICE_FAILURES=1; fi
done
[[ $SERVICE_FAILURES -eq 0 ]] || { echo "Skillable should register these before the lab. Nothing was deployed."; exit 1; }

# --- 5. Models and quota ---
step "Checking models and quota in $LOCATION (gpt-5.4 $FRONTIER_CAPACITY, gpt-5.4-mini $SMALL_CAPACITY, routers $ROUTER_CAPACITY each)"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
az cognitiveservices model list --location "$LOCATION" -o json > "$WORK_DIR/catalog.json"
az cognitiveservices usage list --location "$LOCATION" -o json > "$WORK_DIR/usage.json"
if [[ -n "$EXISTING_ACCOUNT" ]]; then
  az cognitiveservices account deployment list -g "$RESOURCE_GROUP" -n "$EXISTING_NAME" -o json > "$WORK_DIR/existing.json"
else
  echo "[]" > "$WORK_DIR/existing.json"
fi
WORK_DIR="$WORK_DIR" FRONTIER="$FRONTIER_CAPACITY" SMALL="$SMALL_CAPACITY" ROUTER="$ROUTER_CAPACITY" "$PYTHON" - <<'PY'
import json, os, sys
d = os.environ["WORK_DIR"]
catalog = json.load(open(f"{d}/catalog.json"))
usage = {u["name"]["value"]: u for u in json.load(open(f"{d}/usage.json"))}
existing = json.load(open(f"{d}/existing.json"))
wanted = [
    ("gpt-5.4", "2026-03-05", int(os.environ["FRONTIER"])),
    ("gpt-5.4-mini", "2026-03-17", int(os.environ["SMALL"])),
    ("model-router", "2025-11-18", 4 * int(os.environ["ROUTER"])),
]
failed = False
for name, version, total in wanted:
    skus = [s for m in catalog if m["model"]["name"] == name and m["model"]["version"] == version
            for s in m["model"].get("skus", []) if s["name"] == "GlobalStandard"]
    if not skus:
        print(f"FAIL {name}@{version} isn't available as GlobalStandard"); failed = True; continue
    quota = usage.get(skus[0]["usageName"])
    if not quota:
        print(f"FAIL no quota record for {skus[0]['usageName']}"); failed = True; continue
    already = sum(x["sku"]["capacity"] for x in existing if x["properties"]["model"]["name"] == name)
    needed = max(0, total - already)
    free = quota["limit"] - quota["currentValue"]
    if needed > free:
        print(f"FAIL {name}: need {needed:g} more units, {free:g} free"); failed = True
    else:
        print(f"PASS {name}@{version}: need {needed:g} more units, {free:g} free")
sys.exit(1 if failed else 0)
PY

# --- 6. Deploy the Skillable template without role assignments ---
step "Deploying $(basename "$TEMPLATE") into $RESOURCE_GROUP (this takes a few minutes)"
TAGS="{\"lab663Instance\": \"${LAB_INSTANCE:-unknown}\", \"lab663ManagedBy\": \"skillable-test\"}"
az deployment group create \
  --name "$DEPLOYMENT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$TEMPLATE" \
  --parameters location="$LOCATION" assignRoles=false \
               frontierCapacity="$FRONTIER_CAPACITY" smallCapacity="$SMALL_CAPACITY" routerCapacity="$ROUTER_CAPACITY" \
               resourceTags="$TAGS" \
  --output none
ACCOUNT_NAME="$(az deployment group show -g "$RESOURCE_GROUP" -n "$DEPLOYMENT_NAME" --query properties.outputs.accountName.value -o tsv)"
pass "deployed $ACCOUNT_NAME"
az cognitiveservices account deployment list -g "$RESOURCE_GROUP" -n "$ACCOUNT_NAME" \
  --query "[].{deployment:name, model:properties.model.name, capacity:sku.capacity, state:properties.provisioningState}" -o table

# --- 7. Write .env the same way learners will ---
LAB663_RESOURCE_GROUP="$RESOURCE_GROUP" bash "$SCRIPT_DIR/setenv.sh"
