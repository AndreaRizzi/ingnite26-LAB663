#!/usr/bin/env bash
# Combine the Skillable pages in instructions/skillable/ into the files we paste into
# Skillable Studio (Edit Instructions). Run it whenever you add, remove, or edit a page:
#
#   bash instructions/skillable/scripts/generate-skillable-copy.sh
#   MODE=include bash instructions/skillable/scripts/generate-skillable-copy.sh
#
# Pages are files named NN-stage-NN.md (for example 03-concepts-02.md), joined in name
# order by the === page break. The output starts with @lab.Title. It writes two files:
#
#   skillable-copy.md         images point at raw GitHub URLs (works once the repo is public)
#   skillable-copy-images.md  each image becomes an <!-- IMAGE: file | alt --> comment, so we
#                             can upload the screenshot to the Skillable profile by hand
#
# Images that are already uploaded can be listed in SKILLABLE_MEDIA below; both files then
# use the uploaded !IMAGE[...] path instead.
#
# MODE=full     copies every page's text (default).
# MODE=include  writes one [!include] per page in skillable-copy.md so Skillable pulls each
#               page live from GitHub. Needs a public repo. Set REPO and BRANCH to choose it.
set -euo pipefail

cd "$(dirname "$0")/.."

MODE="${MODE:-full}"
REPO="${REPO:-nitya/ignite26-LAB663}"
BRANCH="${BRANCH:-main}"
RAW_BASE="https://raw.githubusercontent.com/${REPO}/${BRANCH}/instructions/skillable"

# screenshots/<file>.png -> path of the same image uploaded to the Skillable profile,
# for example ["screenshots/03-concepts-01-compare.png"]="instructions359314/abcd1234.png"
declare -A SKILLABLE_MEDIA=(
)

mapfile -t PAGES < <(ls -1 [0-9][0-9]-*-[0-9][0-9].md 2>/dev/null | sort)
if [[ ${#PAGES[@]} -eq 0 ]]; then
    echo "No page files (NN-stage-NN.md) found in $(pwd); aborting." >&2
    exit 1
fi

case "${MODE}" in
    full|include) ;;
    *) echo "MODE must be full or include, not '${MODE}'." >&2; exit 1 ;;
esac

# Rewrite ![alt](screenshots/file.png...) lines for one output flavor: "github" or "comment".
render_page() {
    local page="$1" flavor="$2"
    python3 - "$page" "$flavor" "$RAW_BASE" "$(declare -p SKILLABLE_MEDIA)" <<'PY'
import re, sys
page, flavor, raw_base, media_decl = sys.argv[1:5]
media = dict(re.findall(r'\["([^"]+)"\]="([^"]*)"', media_decl))
text = open(page, encoding="utf-8").read()

def swap(match):
    indent, alt, path = match.group(1), match.group(2), match.group(3)
    name = path.split("/")[-1]
    if path in media:
        return f"{indent}!IMAGE[{name}]({media[path]})"
    if flavor == "comment":
        return f"{indent}<!-- IMAGE: {name} | {alt} -->"
    return f"{indent}![{alt}]({raw_base}/{path})"

text = re.sub(r'^([ \t]*(?:>[ \t]*)?)!\[([^\]]*)\]\((screenshots/[^)\s"]+)[^)]*\)(\{[^}]*\})?', swap, text, flags=re.M)
sys.stdout.write(text if text.endswith("\n") else text + "\n")
PY
}

write_output() {
    local out="$1" flavor="$2" include="$3"
    {
        cat <<EOF
@lab.Title

<!--
  LAB663 Skillable instructions. GENERATED, do not edit by hand.
  Regenerate with: bash instructions/skillable/scripts/generate-skillable-copy.sh
  Mode: ${include}. Images: ${flavor}. Source: instructions/skillable/NN-stage-NN.md
  Paste everything in this file into the Skillable lab profile (Edit Instructions).
-->
EOF
        local first=1
        for page in "${PAGES[@]}"; do
            if [[ ${first} -eq 1 ]]; then first=0; else printf '\n===\n'; fi
            printf '\n'
            if [[ "${include}" == "include" ]]; then
                printf '[!include[%s](%s/%s)]\n' "${page%.md}" "${RAW_BASE}" "${page}"
            else
                render_page "${page}" "${flavor}"
            fi
        done
    } > "${out}"
    echo "Wrote instructions/skillable/${out} (${#PAGES[@]} pages, ${include}, images: ${flavor})."
}

write_output skillable-copy.md github "${MODE}"
write_output skillable-copy-images.md comment full
