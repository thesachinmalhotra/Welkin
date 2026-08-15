#!/usr/bin/env python3
import argparse
import json
import sys
from pathlib import Path

ALLOWED_STATUSES = {"implemented", "scaffolded", "planned", "verified"}


def load_catalog(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def ensure(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def validate_catalog(catalog: dict) -> None:
    ensure("guarantees" in catalog, "catalog missing guarantees")
    ensure("scenarios" in catalog, "catalog missing scenarios")

    guarantees = catalog["guarantees"]
    scenarios = catalog["scenarios"]
    ensure(isinstance(guarantees, dict), "guarantees must be an object")
    ensure(isinstance(scenarios, dict), "scenarios must be an object")

    guarantee_public_ids = {guarantee.get("id") for guarantee in guarantees.values()}
    scenario_public_ids = {scenario.get("id") for scenario in scenarios.values()}

    for key, guarantee in guarantees.items():
        ensure(
            guarantee.get("id") == key.replace("_", "-"),
            f"guarantee key mismatch for {key}",
        )
        ensure(
            guarantee.get("status") in ALLOWED_STATUSES,
            f"guarantee {key} has invalid status",
        )
        ensure(
            guarantee.get("scenarios"),
            f"guarantee {key} must reference at least one scenario",
        )
        for scenario_id in guarantee["scenarios"]:
            ensure(
                scenario_id in scenario_public_ids,
                f"guarantee {key} references unknown scenario {scenario_id}",
            )

    for key, scenario in scenarios.items():
        ensure(
            scenario.get("id") == key.replace("_", "-"),
            f"scenario key mismatch for {key}",
        )
        ensure(
            scenario.get("status") in ALLOWED_STATUSES,
            f"scenario {key} has invalid status",
        )
        ensure(
            scenario.get("guarantees"),
            f"scenario {key} must reference at least one guarantee",
        )
        for guarantee_id in scenario["guarantees"]:
            ensure(
                guarantee_id in guarantee_public_ids,
                f"scenario {key} references unknown guarantee {guarantee_id}",
            )

    covered_guarantees = {
        guarantee_id
        for scenario in scenarios.values()
        for guarantee_id in scenario.get("guarantees", [])
    }
    ensure(
        covered_guarantees == guarantee_public_ids,
        "not every guarantee is covered by a scenario",
    )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Validate the Welkin certification catalog"
    )
    parser.add_argument(
        "--catalog", required=True, type=Path, help="Path to the exported catalog JSON"
    )
    parser.add_argument(
        "--matrix", action="store_true", help="Emit implemented scenario ids as JSON"
    )
    parser.add_argument("--scenario", help="Select a single implemented scenario by id")
    parser.add_argument(
        "--output", type=Path, help="Write the selected scenario JSON to this path"
    )
    args = parser.parse_args()

    catalog = load_catalog(args.catalog)
    validate_catalog(catalog)

    if args.matrix:
        matrix = [
            scenario["id"]
            for scenario in catalog["scenarios"].values()
            if scenario.get("status") == "implemented"
        ]
        print(json.dumps(matrix))
        return

    if args.scenario:
        selected = next(
            (
                scenario
                for scenario in catalog["scenarios"].values()
                if scenario["id"] == args.scenario
            ),
            None,
        )
        ensure(selected is not None, f"unknown scenario {args.scenario}")
        ensure(
            selected.get("status") == "implemented",
            f"scenario {args.scenario} is not implemented yet",
        )
        if args.output:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            with args.output.open("w", encoding="utf-8") as handle:
                json.dump(selected, handle, indent=2)
                handle.write("\n")
        return


if __name__ == "__main__":
    main()
