#!/usr/bin/env bash
# Dev container setup for LAB663: checks the tooling and installs Python requirements.
# Non-interactive and credential-free; it never signs in to Azure.

set -uo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

FAILURES=()

log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
ok()   { printf '    \033[0;32mOK\033[0m   %s\n' "$*"; }
warn() { printf '    \033[0;33mWARN\033[0m %s\n' "$*"; }
fail() { printf '    \033[0;31mFAIL\033[0m %s\n' "$*"; FAILURES+=("$1"); }

# ---------------------------------------------------------------- python ----
log "Python"
if command -v python3 >/dev/null 2>&1; then
    ok "python $(python3 -c 'import platform; print(platform.python_version())')"
    if [[ ! -x .venv/bin/python ]]; then
        python3 -m venv .venv || fail "could not create the repository .venv"
    fi
else
    fail "python3 not found"
fi
PYTHON="$PWD/.venv/bin/python"

# ------------------------------------------------------------- azure cli ----
log "Azure CLI"
if command -v az >/dev/null 2>&1; then
    az config set core.collect_telemetry=false --only-show-errors >/dev/null 2>&1
    ok "az $(az version --query '"azure-cli"' -o tsv 2>/dev/null)"
else
    fail "az not found"
fi

# ------------------------------------------------------------- az bicep ----
log "Bicep"
if command -v az >/dev/null 2>&1; then
    BICEP_VERSION="$(az bicep version --only-show-errors 2>/dev/null | head -n1)"
    if [[ -n "${BICEP_VERSION}" ]]; then
        ok "${BICEP_VERSION}"
    else
        fail "az bicep is not available"
    fi
else
    fail "az bicep skipped because az is missing"
fi

# ------------------------------------------------------ azure dev cli ----
log "Azure Developer CLI"
if command -v azd >/dev/null 2>&1; then
    # The feature can lag behind a cached image; updates are best-effort so offline builds still pass.
    azd update --no-prompt >/dev/null 2>&1 \
        || warn "could not update azd; using the installed version"
    ok "$(azd version 2>/dev/null | head -n1)"
    if azd extension list --installed 2>/dev/null | grep -q '^microsoft\.foundry\b'; then
        azd extension update microsoft.foundry --no-prompt >/dev/null 2>&1 \
            && ok "microsoft.foundry extension up to date" \
            || warn "could not update the microsoft.foundry extension"
    else
        azd extension install microsoft.foundry --no-prompt >/dev/null 2>&1 \
            && ok "installed microsoft.foundry extension" \
            || warn "could not install the microsoft.foundry extension"
    fi
else
    fail "azd not found"
fi

# --------------------------------------------------------- dependencies ----
log "Python dependencies"
if [[ ! -x "$PYTHON" ]]; then
    fail "the repository .venv is unavailable"
elif [[ -f requirements.txt ]]; then
    "$PYTHON" -m pip install --quiet --disable-pip-version-check -r requirements.txt \
        && ok "installed requirements.txt" \
        || fail "could not install requirements.txt"
    "$PYTHON" src/check_environment.py \
        && ok "Python requirements and Foundry SDK capabilities" \
        || fail "Python environment check failed"
    if [[ ${#FAILURES[@]} -eq 0 ]]; then
        "$PYTHON" -m ipykernel install --user --name lab663 --display-name "Python (LAB663)" \
            && ok "registered Python (LAB663)" \
            || fail "could not register the notebook kernel"
    fi
else
    fail "requirements.txt is missing"
fi

# -------------------------------------------------------------- summary -----
log "Summary"
if [[ ${#FAILURES[@]} -eq 0 ]]; then
    printf '    \033[0;32mAll required tools are present.\033[0m\n\n'
    exit 0
fi

printf '    \033[0;31m%d check(s) failed:\033[0m\n' "${#FAILURES[@]}"
for failure in "${FAILURES[@]}"; do
    printf '      - %s\n' "${failure}"
done
printf '\n'
exit 1
