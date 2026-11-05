#!/usr/bin/env python3
"""Check that the self-guided and Skillable instructions match the notebooks and each other.

    python3 instructions/scripts/check_sync.py            # check, then count screenshot TODOs
    python3 instructions/scripts/check_sync.py --todos    # also list each screenshot TODO

Every module page starts with a header such as
    <!-- sync: source=labs/core/04-make-it-work.ipynb sections=4.1,4.2 -->
The self-guided page and the Skillable page for the same source must declare the same
sections. Exit code 0 when every check passes, 1 otherwise. Standard library only.
"""

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INSTRUCTIONS = ROOT / "instructions"
SELF_GUIDED = INSTRUCTIONS / "self-guided"
SKILLABLE = INSTRUCTIONS / "skillable"
GENERATOR = SKILLABLE / "scripts" / "generate-skillable-copy.sh"

SYNC_HEADER = re.compile(r"^<!-- sync: (.*?) -->$", re.M)
SECTION_MENTION = re.compile(r"[Ss]ections? (\d+\.\d+(?:(?:, and |, | and )\d+\.\d+)*)")
SECTION_NUMBER = re.compile(r"\d+\.\d+")
NOTEBOOK_HEADING = re.compile(r"^## (\d+\.\d+) ", re.M)
NOTEBOOK_TIME = re.compile(r"\*\*Time:\*\* about (\d+) minutes")
MARKDOWN_LINK = re.compile(r"!?\[[^\]]*\]\(([^)\s]+)")
LAB_TOKEN = re.compile(r"@lab\.[A-Za-z]+(?:\([^)]*\))?(?:\.[A-Za-z]+)?")
SCREENSHOT_TODO = re.compile(r"<!-- TODO\(screenshot\): (\S+) \| (.+?) -->")
SCREENSHOTS = SELF_GUIDED / "screenshots"
SECRET_PATTERNS = {
    "a GUID": re.compile(r"\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b", re.I),
    "an Azure endpoint": re.compile(r"[a-z0-9-]+\.(?:services\.ai|cognitiveservices|openai)\.azure\.com", re.I),
    "a connection string or key": re.compile(r"(?:AccountKey|InstrumentationKey|SharedAccessKey)=", re.I),
    "an email address": re.compile(r"\b[\w.+-]+@(?!lab\.)[\w-]+\.[\w.]+\b"),
}
# Add a token here only after confirming it in Skillable Studio's @lab picker.
KNOWN_TOKENS = {
    "@lab.VirtualMachine(Win11-Pro-Base).Password",
    "@lab.CloudPortalCredential(User1).Username",
    "@lab.CloudPortalCredential(User1).Password",
    "@lab.CloudSubscription.TenantId",
}
MAX_TITLE = 40

problems: list[str] = []


def fail(path: Path, message: str) -> None:
    problems.append(f"{path.relative_to(ROOT)}: {message}")


def read_header(path: Path, text: str):
    match = SYNC_HEADER.search(text)
    if not match or not text.startswith(match.group(0)):
        fail(path, "first line must be a <!-- sync: source=... sections=... --> header")
        return None, []
    fields = dict(part.split("=", 1) for part in match.group(1).split() if "=" in part)
    sections = [s for s in fields.get("sections", "").split(",") if s]
    return fields.get("source"), sections


def notebook_facts(source: Path):
    """Section numbers and the 'about N minutes' time from a notebook's markdown cells."""
    cells = json.loads(source.read_text(encoding="utf-8"))["cells"]
    markdown = "\n".join("".join(c["source"]) for c in cells if c["cell_type"] == "markdown")
    time = NOTEBOOK_TIME.search(markdown)
    return set(NOTEBOOK_HEADING.findall(markdown)), time.group(1) if time else None


def check_links(path: Path, text: str) -> None:
    for target in MARKDOWN_LINK.findall(text):
        if target.startswith(("http://", "https://", "mailto:", "#")):
            continue
        if not (path.parent / target.split("#", 1)[0]).exists():
            fail(path, f"broken relative link: {target}")


def check_common(path: Path, text: str) -> None:
    for label, pattern in SECRET_PATTERNS.items():
        if pattern.search(text):
            fail(path, f"contains {label}; use a @lab token or a placeholder description")
    if re.search(r"^\s*[2-9]\. ", text, re.M):
        fail(path, "number every list item 1. so Skillable and GitHub auto-number")


def check_skillable_page(path: Path, body: str) -> None:
    for target in MARKDOWN_LINK.findall(body):
        if not target.startswith(("http://", "https://")):
            fail(path, f"relative link {target} won't resolve in Skillable; name the file instead")
    for token in LAB_TOKEN.findall(body):
        if token not in KNOWN_TOKENS:
            fail(path, f"unknown token {token}; confirm it in Studio, then add it to KNOWN_TOKENS")
    for number, page in enumerate(re.split(r"^===$", body, flags=re.M), 1):
        lines = [line for line in page.strip().splitlines() if line.strip()]
        if not lines or not lines[0].startswith("# "):
            fail(path, f"Skillable page {number} must start with a '# ' heading")
            continue
        title = lines[0][2:].strip()
        if len(title) > MAX_TITLE:
            fail(path, f"page title '{title}' is {len(title)} characters; keep it to {MAX_TITLE}")
        if title.endswith("."):
            fail(path, f"page title '{title}' must not end with a period")
        if "[!Note] *Success:*" not in lines[-1]:
            fail(path, f"page '{title}' must end with '> [!Note] *Success:* ...'")


def pages(folder: Path, pattern: str) -> list[Path]:
    return sorted(folder.glob(pattern))


def main() -> int:
    self_guided = pages(SELF_GUIDED, "core/*.md") + pages(SELF_GUIDED, "more/*.md")
    skillable = pages(SKILLABLE, "core-*.md") + pages(SKILLABLE, "more-*.md")
    by_source: dict[str, dict[str, tuple[Path, list[str]]]] = {}

    for track, files in (("self-guided", self_guided), ("skillable", skillable)):
        for path in files:
            text = path.read_text(encoding="utf-8")
            source, sections = read_header(path, text)
            if source is None:
                continue
            if source in by_source.get(track, {}):
                fail(path, f"another {track} page already covers {source}")
            by_source.setdefault(track, {})[source] = (path, sections)
            body = SYNC_HEADER.sub("", text, count=1)
            check_common(path, body)
            source_path = ROOT / source
            if not source_path.exists():
                fail(path, f"source {source} does not exist")
                continue
            mentioned = {n for group in SECTION_MENTION.findall(body) for n in SECTION_NUMBER.findall(group)}
            if mentioned - set(sections):
                fail(path, f"mentions sections {sorted(mentioned - set(sections))} missing from its sync header")
            if source_path.suffix == ".ipynb":
                headings, minutes = notebook_facts(source_path)
                if set(sections) - headings:
                    fail(path, f"sections {sorted(set(sections) - headings)} are not headings in {source}")
                if minutes and f"{minutes} min" not in body:
                    fail(path, f"notebook says about {minutes} minutes; the page doesn't")
            if track == "self-guided":
                check_links(path, body)
            else:
                check_skillable_page(path, body)

    sg, sk = by_source.get("self-guided", {}), by_source.get("skillable", {})
    for notebook in sorted((ROOT / "labs" / "core").glob("*.ipynb")):
        key = str(notebook.relative_to(ROOT))
        for track, found in (("self-guided", sg), ("skillable", sk)):
            if key not in found:
                problems.append(f"{key}: no {track} page has source={key}")
    for source in sorted(set(sg) | set(sk)):
        if source in sg and source in sk and sg[source][1] != sk[source][1]:
            problems.append(
                f"{source}: section lists differ. self-guided {sg[source][1]} vs skillable {sk[source][1]}"
            )
        elif (source in sg) != (source in sk):
            problems.append(f"{source}: covered by only one track")

    for readme, files, relative_to in (
        (SELF_GUIDED / "README.md", self_guided, SELF_GUIDED),
        (SKILLABLE / "README.md", skillable, SKILLABLE),
        (INSTRUCTIONS / "README.md", self_guided + skillable, INSTRUCTIONS),
    ):
        text = readme.read_text(encoding="utf-8")
        check_links(readme, text)
        check_common(readme, text)
        for path in files:
            if f"({path.relative_to(relative_to).as_posix()})" not in text:
                fail(readme, f"doesn't link {path.relative_to(relative_to).as_posix()}")

    result = subprocess.run(["bash", str(GENERATOR), "--check"], capture_output=True, text=True)
    if result.returncode != 0:
        problems.append((result.stderr or result.stdout).strip())

    todos = []
    for path in self_guided:
        for name, what in SCREENSHOT_TODO.findall(path.read_text(encoding="utf-8")):
            todos.append((path, name, what))
            if (SCREENSHOTS / name).exists():
                fail(path, f"{name} exists; replace its TODO with an image link")

    if problems:
        print(f"{len(problems)} problem(s):")
        for problem in problems:
            print(f"  - {problem}")
        return 1
    print(f"All checks passed: {len(self_guided)} self-guided and {len(skillable)} Skillable pages in sync.")
    if todos:
        print(f"{len(todos)} screenshot TODO(s) remaining." + ("" if "--todos" in sys.argv else " List them with --todos."))
    if "--todos" in sys.argv:
        for path, name, what in todos:
            print(f"  - {path.relative_to(ROOT)}: {name}: {what}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
