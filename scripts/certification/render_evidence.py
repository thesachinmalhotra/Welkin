#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description="Render a Welkin certification evidence summary")
    parser.add_argument("--catalog", required=True, type=Path)
    parser.add_argument("--scenario", required=True, type=Path)
    parser.add_argument("--artifact-dir", required=True, type=Path)
    parser.add_argument("--result", required=True, choices=["passed", "failed", "planned"])
    args = parser.parse_args()

    with args.catalog.open("r", encoding="utf-8") as handle:
        catalog = json.load(handle)
    with args.scenario.open("r", encoding="utf-8") as handle:
        scenario = json.load(handle)

    notes = []
    context_path = args.artifact_dir / "context.json"
    if context_path.exists():
        with context_path.open("r", encoding="utf-8") as handle:
            context = json.load(handle)
        notes = context.get("notes", [])

    args.artifact_dir.mkdir(parents=True, exist_ok=True)

    summary = {
        "scenario": scenario["id"],
        "title": scenario["title"],
        "result": args.result,
        "mode": scenario["mode"],
        "status": scenario["status"],
        "guarantees": scenario["guarantees"],
        "evidence": scenario["evidence"],
        "verification": scenario["verification"],
        "notes": notes,
        "catalog_guarantees": list(catalog["guarantees"].keys()),
    }

    with (args.artifact_dir / "summary.json").open("w", encoding="utf-8") as handle:
        json.dump(summary, handle, indent=2)
        handle.write("\n")

    summary_md = [
        f"# Certification Result: {scenario['title']}",
        "",
        f"- Scenario: `{scenario['id']}`",
        f"- Result: `{args.result}`",
        f"- Mode: `{scenario['mode']}`",
        f"- Status: `{scenario['status']}`",
        "",
        "## Guarantees",
    ]
    summary_md.extend([f"- `{guarantee}`" for guarantee in scenario["guarantees"]])
    summary_md.append("")
    summary_md.append("## Evidence")
    summary_md.extend([f"- `{item}`" for item in scenario["evidence"]])
    summary_md.append("")
    summary_md.append("## Verification")
    summary_md.extend([f"- {step}" for step in scenario["verification"]])
    if notes:
        summary_md.append("")
        summary_md.append("## Notes")
        summary_md.extend([f"- {note}" for note in notes])

    (args.artifact_dir / "summary.md").write_text("\n".join(summary_md) + "\n", encoding="utf-8")

    print("\n".join(summary_md))


if __name__ == "__main__":
    main()
