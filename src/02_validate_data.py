"""Check that our test data is sound before we trust any score built on it.

What we check:
  - every line is valid JSON with the fields we expect
  - ids and queries are unique, and the three sets don't overlap
  - every "way we lose trust" shows up in every set
  - every fact quote appears word for word in the manual it cites

Run it:  python3 src/02_validate_data.py
"""

import json
import re
import sys
from pathlib import Path

DATA = Path(__file__).resolve().parents[1] / "data"
SETS = ["practice", "dev", "test"]
WAYS = [
    "wrong_product",
    "overclaiming",
    "making_things_up",
    "wrong_premise",
    "out_of_lane",
    "not_useful",
]
DIFFICULTIES = {"easy", "medium", "hard"}
REQUIRED = ["id", "split", "way", "difficulty", "guard", "products", "query", "expected_behavior", "facts", "must_not"]


def squash(text: str) -> str:
    """Collapse whitespace so line wraps and trailing spaces don't hide a match."""
    return re.sub(r"\s+", " ", text).strip()


def validate() -> list[tuple[str, bool, str]]:
    """Return a list of (check name, passed, detail)."""
    results: list[tuple[str, bool, str]] = []

    def check(name: str, ok: bool, detail: str = "") -> None:
        results.append((name, ok, detail))

    manuals = {p.name: squash(p.read_text(encoding="utf-8")) for p in (DATA / "manuals").glob("*.md")}
    check("10 manuals found", len(manuals) == 10, f"found {len(manuals)}")

    cases: dict[str, list[dict]] = {}
    for name in SETS:
        path = DATA / f"{name}.jsonl"
        rows, bad = [], []
        if not path.exists():
            check(f"{name}.jsonl exists", False, "file is missing")
            continue
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if not line.strip():
                continue
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError as error:
                bad.append(f"line {number}: {error}")
        check(f"{name}: every line is valid JSON", not bad, "; ".join(bad))
        cases[name] = rows

    for name, rows in cases.items():
        problems = []
        for row in rows:
            missing = [field for field in REQUIRED if field not in row]
            if missing:
                problems.append(f"{row.get('id', '?')} is missing {missing}")
                continue
            if row["split"] != name:
                problems.append(f"{row['id']} says split={row['split']}")
            if row["way"] not in WAYS:
                problems.append(f"{row['id']} has unknown way '{row['way']}'")
            if row["difficulty"] not in DIFFICULTIES:
                problems.append(f"{row['id']} has unknown difficulty '{row['difficulty']}'")
            if row["way"] == "out_of_lane" and row["facts"]:
                problems.append(f"{row['id']} is out of lane but cites facts")
            if row["way"] != "out_of_lane" and not row["facts"]:
                problems.append(f"{row['id']} needs at least one fact")
        check(f"{name}: fields look right", not problems, "; ".join(problems))

        counts = {way: sum(1 for r in rows if r.get("way") == way) for way in WAYS}
        thin = [way for way, n in counts.items() if n < 2]
        check(f"{name}: every way has 2+ cases", not thin, f"thin: {thin}" if thin else str(counts))

    all_rows = [row for rows in cases.values() for row in rows]
    ids = [row.get("id") for row in all_rows]
    queries = [squash(row.get("query", "")).lower() for row in all_rows]
    check("ids are unique across all sets", len(ids) == len(set(ids)))
    check("queries are unique across all sets", len(queries) == len(set(queries)))

    missing_quotes = []
    for row in all_rows:
        for fact in row.get("facts", []):
            text = manuals.get(fact.get("manual", ""))
            if text is None:
                missing_quotes.append(f"{row['id']}: no manual named {fact.get('manual')}")
            elif squash(fact.get("quote", "")) not in text:
                missing_quotes.append(f"{row['id']}: '{fact.get('quote')}' not in {fact['manual']}")
    check("every fact quote appears in its manual", not missing_quotes, "; ".join(missing_quotes))

    return results


def main() -> int:
    results = validate()
    for name, ok, detail in results:
        print(f"  {'PASS' if ok else 'FAIL'}  {name}" + (f"  ({detail})" if detail and not ok else ""))
    failed = sum(1 for _, ok, _ in results if not ok)
    print(f"\n{'PASS' if not failed else 'FAIL'}: {len(results) - failed} of {len(results)} checks passed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
