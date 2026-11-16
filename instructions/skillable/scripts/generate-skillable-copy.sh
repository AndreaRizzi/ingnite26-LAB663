#!/usr/bin/env bash
# Build the Skillable manual from the page files in instructions/skillable/ (NN-stage-NN.md).
#
#   bash instructions/skillable/scripts/generate-skillable-copy.sh
#   PUBLISH_DIR=../skillable-labs/ignite26-lab663/v1 bash instructions/skillable/scripts/generate-skillable-copy.sh
#
# Always writes, in instructions/skillable/:
#   skillable-copy.md         every page's full text; images point at the public repo's raw URLs
#   skillable-copy-images.md  every page's full text; images become <!-- IMAGE: file | alt --> comments,
#                             for uploading screenshots to the Skillable profile by hand
#   skillable-include.md      the master file to paste into Skillable: one [!include] per page, pulling
#                             each page live from the public repo
#
# With PUBLISH_DIR set, also writes the folder to commit to the public repo: every page with image
# links rewritten to raw URLs, the screenshots/ folder, and skillable-include.md.
#
# The public location is set by PUBLISH_REPO, PUBLISH_BRANCH and PUBLISH_PATH (defaults below).
# Screenshots already uploaded to the Skillable profile can be listed in SKILLABLE_MEDIA; every
# output then uses the uploaded !IMAGE[...] path for them.
set -euo pipefail

cd "$(dirname "$0")/.."

PUBLISH_REPO="${PUBLISH_REPO:-nitya/skillable-labs}"
PUBLISH_BRANCH="${PUBLISH_BRANCH:-ignite26-lab663}"
PUBLISH_PATH="${PUBLISH_PATH:-ignite26-lab663/v1}"
PUBLISH_DIR="${PUBLISH_DIR:-}"
RAW_BASE="https://raw.githubusercontent.com/${PUBLISH_REPO}/refs/heads/${PUBLISH_BRANCH}/${PUBLISH_PATH}"

# screenshots/<file>.png -> path of the same image uploaded to the Skillable profile,
# for example ["screenshots/04-concepts-02-compare-setup.png"]="instructions359314/abcd1234.png"
declare -A SKILLABLE_MEDIA=(
)

export PUBLISH_REPO PUBLISH_BRANCH PUBLISH_PATH PUBLISH_DIR RAW_BASE
export SKILLABLE_MEDIA_DECL="$(declare -p SKILLABLE_MEDIA)"

python3 - <<'PY'
import glob, os, re, shutil

raw_base = os.environ["RAW_BASE"]
publish_dir = os.environ["PUBLISH_DIR"]
media = dict(re.findall(r'\["([^"]+)"\]="([^"]*)"', os.environ["SKILLABLE_MEDIA_DECL"]))

pages = sorted(glob.glob("[0-9][0-9]-*-[0-9][0-9].md"))
if not pages:
    raise SystemExit("No page files (NN-stage-NN.md) found; aborting.")

image = re.compile(r'^([ \t]*(?:>[ \t]*)?)!\[([^\]]*)\]\((screenshots/[^)\s"]+)[^)]*\)(\{[^}]*\})?', re.M)

def render(text, flavor):
    def swap(m):
        indent, alt, path = m.group(1), m.group(2), m.group(3)
        name = path.split("/")[-1]
        if path in media:
            return f"{indent}!IMAGE[{name}]({media[path]})"
        if flavor == "comment":
            return f"{indent}<!-- IMAGE: {name} | {alt} -->"
        return f"{indent}![{alt}]({raw_base}/{path})"
    text = image.sub(swap, text)
    return text if text.endswith("\n") else text + "\n"

def header(kind, how):
    return f"""<!--
  LAB663 Skillable instructions ({kind}). GENERATED - do not edit by hand.
  Regenerate with: bash instructions/skillable/scripts/generate-skillable-copy.sh

  {how}

  Source pages: nitya/ignite26-LAB663 instructions/skillable/NN-stage-NN.md
  Published to: {os.environ['PUBLISH_REPO']} (branch {os.environ['PUBLISH_BRANCH']}, folder {os.environ['PUBLISH_PATH']})
  To target a different location: PUBLISH_REPO=<owner/name> PUBLISH_BRANCH=<branch> PUBLISH_PATH=<folder>
-->

@lab.Title
"""

def write(path, text):
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)

def full(flavor, kind, how):
    body = "\n===\n\n".join(render(open(p, encoding="utf-8").read(), flavor) for p in pages)
    return header(kind, how) + "\n" + body

include = header("include", "Paste this file into the Skillable lab profile (Edit Instructions). Skillable pulls\n  each page live from the public repo, in order, separated by the === page break.") + "\n" + \
    "\n===\n\n".join(f"[!include[]({raw_base}/{p})]\n" for p in pages)

write("skillable-copy.md", full("github", "full text", "Paste this file into Edit Instructions. Images load from the public repo."))
write("skillable-copy-images.md", full("comment", "full text, image placeholders", "Paste this file into Edit Instructions, then upload each named screenshot to the profile\n  and insert it where its IMAGE comment is."))
write("skillable-include.md", include)
print(f"Wrote skillable-copy.md, skillable-copy-images.md and skillable-include.md ({len(pages)} pages).")

if publish_dir:
    os.makedirs(publish_dir, exist_ok=True)
    for old in glob.glob(os.path.join(publish_dir, "[0-9][0-9]-*-[0-9][0-9].md")):
        os.remove(old)
    for p in pages:
        write(os.path.join(publish_dir, p), render(open(p, encoding="utf-8").read(), "github"))
    shots = os.path.join(publish_dir, "screenshots")
    shutil.rmtree(shots, ignore_errors=True)
    shutil.copytree("screenshots", shots, ignore=shutil.ignore_patterns(".gitkeep"))
    shutil.copy("skillable-include.md", publish_dir)
    print(f"Published {len(pages)} pages, {len(os.listdir(shots))} screenshots and skillable-include.md to {publish_dir}.")
PY
