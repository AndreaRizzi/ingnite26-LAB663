#!/usr/bin/env bash
# Join the Skillable page files into skillable-copy.md, the one file pasted into
# Skillable Studio (Edit Instructions). Run it after adding, removing or editing a page.
#
#   bash instructions/skillable/scripts/generate-skillable-copy.sh           # full text (default)
#   MODE=include bash instructions/skillable/scripts/generate-skillable-copy.sh
#   bash instructions/skillable/scripts/generate-skillable-copy.sh --check   # exit 1 if stale
#
# Pages are core-N-*.md then more-N-*.md in number order, joined by the === page break.
# MODE=full     copies each page's text, without its <!-- sync: --> header.
# MODE=include  writes one [!include] per page so Skillable pulls it live from GitHub.
#               Set REPO and BRANCH to choose the source; the repo must be public.
set -euo pipefail

cd "$(dirname "$0")/.."

MODE="${MODE:-full}"
REPO="${REPO:-microsoft/ignite26-LAB663}"
BRANCH="${BRANCH:-main}"
RAW_BASE="https://raw.githubusercontent.com/${REPO}/${BRANCH}/instructions/skillable"
OUT="skillable-copy.md"
CHECK=0
[[ "${1:-}" == "--check" ]] && CHECK=1

PAGES=()
while IFS= read -r page; do PAGES+=("${page}"); done < <(
    { ls -1 core-[0-9]*-*.md 2>/dev/null | sort -V; ls -1 more-[0-9]*-*.md 2>/dev/null | sort -V; } || true
)
if [[ ${#PAGES[@]} -eq 0 ]]; then
    echo "No page files (core-N-*.md or more-N-*.md) found; aborting." >&2
    exit 1
fi

case "${MODE}" in
    full)    SOURCE="the page files in instructions/skillable/" ;;
    include) SOURCE="${RAW_BASE}" ;;
    *)       echo "MODE must be full or include, not '${MODE}'." >&2; exit 1 ;;
esac

render() {
    cat <<EOF
<!--
  LAB663 Skillable instructions. GENERATED, do not edit by hand.
  Regenerate with: bash instructions/skillable/scripts/generate-skillable-copy.sh
  Mode: ${MODE}. Source: ${SOURCE}
  Paste everything in this file into the Skillable lab profile (Edit Instructions).
-->
EOF
    local first=1
    for page in "${PAGES[@]}"; do
        if [[ ${first} -eq 1 ]]; then first=0; else printf '\n===\n'; fi
        printf '\n'
        if [[ "${MODE}" == "include" ]]; then
            printf '[!include[%s](%s/%s)]\n' "${page%.md}" "${RAW_BASE}" "${page}"
        else
            sed '/^<!-- sync:.*-->$/d' "${page}"
        fi
    done
}

if [[ ${CHECK} -eq 1 ]]; then
    if render | cmp -s - "${OUT}"; then
        echo "${OUT} is up to date (${#PAGES[@]} page files, mode: ${MODE})."
    else
        echo "${OUT} is stale. Run: bash instructions/skillable/scripts/generate-skillable-copy.sh" >&2
        exit 1
    fi
else
    render > "${OUT}"
    echo "Wrote ${OUT} with ${#PAGES[@]} page files (mode: ${MODE})."
fi
