#!/usr/bin/env python3
import argparse
import json
import os
import sqlite3
import sys
from typing import Any, Dict, List, Tuple

REQUIRED_TABLES = ("exercises", "metadata")
REQUIRED_EXERCISE_COLUMNS = (
    "id",
    "name_de",
    "name_en",
    "description_de",
    "description_en",
    "category_name",
    "muscles_primary",
    "muscles_secondary",
)
OPTIONAL_EXERCISE_COLUMNS = (
    "image_path",
    "source",
    "created_by",
    "is_custom",
)
MAIN_COMPARE_FIELDS = (
    "name_de",
    "name_en",
    "description_de",
    "description_en",
    "category_name",
    "muscles_primary",
    "muscles_secondary",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Compare two generated hypertrack_training.db catalogs."
    )
    parser.add_argument("--old", required=True, help="Path to old database file")
    parser.add_argument("--new", required=True, help="Path to new database file")
    parser.add_argument("--json-out", help="Write full machine-readable diff report to JSON")
    parser.add_argument(
        "--examples",
        type=int,
        default=10,
        help="How many example IDs/rows to print in console output (default: 10)",
    )
    parser.add_argument(
        "--removed-severe-threshold",
        type=int,
        default=25,
        help="Removed ID count at or above this threshold is severe (default: 25)",
    )
    parser.add_argument(
        "--row-drop-warn-percent",
        type=float,
        default=5.0,
        help="Warn when total row count drop is at least this percent (default: 5.0)",
    )
    parser.add_argument(
        "--row-drop-severe-percent",
        type=float,
        default=20.0,
        help="Severe when total row count drop is at least this percent (default: 20.0)",
    )
    parser.add_argument(
        "--category-regression-threshold",
        type=int,
        default=10,
        help="Warn when category regressions reach this count (default: 10)",
    )
    parser.add_argument(
        "--muscle-regression-threshold",
        type=int,
        default=10,
        help="Warn when muscle regressions reach this count (default: 10)",
    )
    parser.add_argument(
        "--de-fallback-shift-threshold",
        type=int,
        default=10,
        help="Warn when DE-name losses with EN still present reach this count (default: 10)",
    )
    parser.add_argument(
        "--fail-on-breaking",
        action="store_true",
        help=(
            "Exit with non-zero status on dangerous changes "
            "(removed IDs or severe/suspicious regressions)."
        ),
    )
    parser.add_argument(
        "--fail-on-removed-threshold",
        type=int,
        default=0,
        help=(
            "With --fail-on-breaking, fail if removed ID count is above this value "
            "(default: 0)."
        ),
    )
    return parser.parse_args()


def normalize_value(value: Any) -> Any:
    if value is None:
        return ""
    if isinstance(value, str):
        return value.strip()
    return value


def is_blank(value: Any) -> bool:
    return normalize_value(value) == ""


def load_catalog(db_path: str) -> Dict[str, Any]:
    if not os.path.exists(db_path):
        raise FileNotFoundError(f"Database not found: {db_path}")

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    try:
        cursor = conn.cursor()

        cursor.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
        )
        tables = {row["name"] for row in cursor.fetchall()}
        missing_tables = [table for table in REQUIRED_TABLES if table not in tables]
        if missing_tables:
            raise ValueError(
                f"Missing required tables in {db_path}: {', '.join(missing_tables)}"
            )

        cursor.execute("PRAGMA table_info(exercises)")
        exercise_columns = {row["name"] for row in cursor.fetchall()}
        missing_columns = [
            column for column in REQUIRED_EXERCISE_COLUMNS if column not in exercise_columns
        ]
        if missing_columns:
            raise ValueError(
                f"Missing required exercise columns in {db_path}: {', '.join(missing_columns)}"
            )

        compare_fields = list(MAIN_COMPARE_FIELDS)
        for optional_field in OPTIONAL_EXERCISE_COLUMNS:
            if optional_field in exercise_columns:
                compare_fields.append(optional_field)

        cursor.execute("SELECT key, value FROM metadata")
        metadata = {row["key"]: row["value"] for row in cursor.fetchall()}

        select_columns = ["id"] + compare_fields
        column_sql = ", ".join(select_columns)
        cursor.execute(f"SELECT {column_sql} FROM exercises")
        rows = cursor.fetchall()

        exercises: Dict[str, Dict[str, Any]] = {}
        for row in rows:
            row_dict = dict(row)
            exercise_id = str(row_dict["id"])
            normalized = {
                field: normalize_value(row_dict.get(field)) for field in compare_fields
            }
            exercises[exercise_id] = normalized

        return {
            "path": db_path,
            "version": metadata.get("version", ""),
            "metadata": metadata,
            "compare_fields": compare_fields,
            "exercise_count": len(exercises),
            "exercises": exercises,
        }
    finally:
        conn.close()


def compare_catalogs(
    old_catalog: Dict[str, Any], new_catalog: Dict[str, Any], args: argparse.Namespace
) -> Dict[str, Any]:
    old_ids = set(old_catalog["exercises"].keys())
    new_ids = set(new_catalog["exercises"].keys())

    removed_ids = sorted(old_ids - new_ids)
    added_ids = sorted(new_ids - old_ids)
    shared_ids = sorted(old_ids & new_ids)

    compare_fields = sorted(set(old_catalog["compare_fields"]) | set(new_catalog["compare_fields"]))
    changed_fields_by_id: Dict[str, Dict[str, Dict[str, Any]]] = {}
    changed_field_counts = {field: 0 for field in compare_fields}

    regressions = {
        "name_de_became_blank": 0,
        "name_en_became_blank": 0,
        "description_de_became_blank": 0,
        "description_en_became_blank": 0,
        "category_became_blank": 0,
        "muscles_primary_became_blank": 0,
        "muscles_secondary_became_blank": 0,
        "de_name_lost_en_still_present": 0,
    }

    for exercise_id in shared_ids:
        old_row = old_catalog["exercises"][exercise_id]
        new_row = new_catalog["exercises"][exercise_id]
        field_changes: Dict[str, Dict[str, Any]] = {}

        for field in compare_fields:
            old_value = normalize_value(old_row.get(field))
            new_value = normalize_value(new_row.get(field))
            if old_value != new_value:
                field_changes[field] = {"old": old_value, "new": new_value}
                changed_field_counts[field] += 1

            if field == "name_de" and not is_blank(old_value) and is_blank(new_value):
                regressions["name_de_became_blank"] += 1
            elif field == "name_en" and not is_blank(old_value) and is_blank(new_value):
                regressions["name_en_became_blank"] += 1
            elif field == "description_de" and not is_blank(old_value) and is_blank(new_value):
                regressions["description_de_became_blank"] += 1
            elif field == "description_en" and not is_blank(old_value) and is_blank(new_value):
                regressions["description_en_became_blank"] += 1
            elif field == "category_name" and not is_blank(old_value) and is_blank(new_value):
                regressions["category_became_blank"] += 1
            elif field == "muscles_primary" and not is_blank(old_value) and is_blank(new_value):
                regressions["muscles_primary_became_blank"] += 1
            elif field == "muscles_secondary" and not is_blank(old_value) and is_blank(new_value):
                regressions["muscles_secondary_became_blank"] += 1

        if not is_blank(old_row.get("name_de")) and is_blank(new_row.get("name_de")) and not is_blank(
            new_row.get("name_en")
        ):
            regressions["de_name_lost_en_still_present"] += 1

        if field_changes:
            changed_fields_by_id[exercise_id] = field_changes

    old_count = old_catalog["exercise_count"]
    new_count = new_catalog["exercise_count"]
    count_delta = new_count - old_count
    row_drop_percent = 0.0
    if old_count > 0 and new_count < old_count:
        row_drop_percent = ((old_count - new_count) / old_count) * 100.0

    warnings: List[Dict[str, Any]] = []

    if len(removed_ids) > 0:
        warnings.append(
            {
                "code": "REMOVED_IDS",
                "severity": "warning",
                "value": len(removed_ids),
                "message": f"Exercises removed: {len(removed_ids)}",
            }
        )

    if len(removed_ids) >= args.removed_severe_threshold:
        warnings.append(
            {
                "code": "REMOVED_IDS_SEVERE",
                "severity": "severe",
                "value": len(removed_ids),
                "message": (
                    f"Exercises removed exceeds severe threshold "
                    f"({len(removed_ids)} >= {args.removed_severe_threshold})"
                ),
            }
        )

    if regressions["name_de_became_blank"] > 0 or regressions["name_en_became_blank"] > 0:
        warnings.append(
            {
                "code": "NAME_REGRESSION",
                "severity": "warning",
                "value": {
                    "name_de_became_blank": regressions["name_de_became_blank"],
                    "name_en_became_blank": regressions["name_en_became_blank"],
                },
                "message": "Previously non-empty exercise names became blank.",
            }
        )

    category_loss = regressions["category_became_blank"]
    if category_loss > 0:
        severity = (
            "severe"
            if category_loss >= max(1, args.category_regression_threshold * 2)
            else "warning"
        )
        warnings.append(
            {
                "code": "CATEGORY_REGRESSION",
                "severity": severity,
                "value": category_loss,
                "message": f"Categories became blank for {category_loss} exercises.",
            }
        )

    muscle_loss = (
        regressions["muscles_primary_became_blank"]
        + regressions["muscles_secondary_became_blank"]
    )
    if muscle_loss > 0:
        severity = (
            "severe" if muscle_loss >= max(1, args.muscle_regression_threshold * 2) else "warning"
        )
        warnings.append(
            {
                "code": "MUSCLE_REGRESSION",
                "severity": severity,
                "value": {
                    "muscles_primary_became_blank": regressions["muscles_primary_became_blank"],
                    "muscles_secondary_became_blank": regressions["muscles_secondary_became_blank"],
                },
                "message": "Muscle lists became blank unexpectedly for shared IDs.",
            }
        )

    if regressions["de_name_lost_en_still_present"] >= args.de_fallback_shift_threshold:
        warnings.append(
            {
                "code": "DE_FALLBACK_SHIFT",
                "severity": "warning",
                "value": regressions["de_name_lost_en_still_present"],
                "message": (
                    "Large fallback shift detected: many DE names disappeared while EN remains."
                ),
            }
        )

    if row_drop_percent >= args.row_drop_warn_percent:
        severity = "severe" if row_drop_percent >= args.row_drop_severe_percent else "warning"
        warnings.append(
            {
                "code": "ROW_COUNT_DROP",
                "severity": severity,
                "value": row_drop_percent,
                "message": (
                    f"Total exercise row count dropped by {row_drop_percent:.2f}% "
                    f"({old_count} -> {new_count})."
                ),
            }
        )

    changed_exercise_count = len(changed_fields_by_id)
    changed_field_counts = {
        field: count for field, count in changed_field_counts.items() if count > 0
    }

    report = {
        "old": {
            "path": old_catalog["path"],
            "version": old_catalog["version"],
            "exercise_count": old_count,
        },
        "new": {
            "path": new_catalog["path"],
            "version": new_catalog["version"],
            "exercise_count": new_count,
        },
        "delta": {"exercise_count": count_delta},
        "removed_ids": removed_ids,
        "added_ids": added_ids,
        "changed_fields_by_id": changed_fields_by_id,
        "summary": {
            "shared_id_count": len(shared_ids),
            "removed_count": len(removed_ids),
            "added_count": len(added_ids),
            "changed_exercise_count": changed_exercise_count,
            "changed_field_counts": changed_field_counts,
            "row_drop_percent": row_drop_percent,
            "regressions": regressions,
        },
        "warning_flags": warnings,
        "examples": {
            "removed_ids": removed_ids[: args.examples],
            "added_ids": added_ids[: args.examples],
            "changed_ids": sorted(changed_fields_by_id.keys())[: args.examples],
            "changed_rows": build_changed_row_examples(changed_fields_by_id, args.examples),
        },
    }
    return report


def build_changed_row_examples(
    changed_fields_by_id: Dict[str, Dict[str, Dict[str, Any]]], limit: int
) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    for exercise_id in sorted(changed_fields_by_id.keys())[:limit]:
        for field, values in changed_fields_by_id[exercise_id].items():
            rows.append(
                {
                    "id": exercise_id,
                    "field": field,
                    "old": values["old"],
                    "new": values["new"],
                }
            )
            if len(rows) >= limit:
                return rows
    return rows


def print_console_report(report: Dict[str, Any], examples: int) -> None:
    old = report["old"]
    new = report["new"]
    summary = report["summary"]
    warnings = report["warning_flags"]

    print("=" * 72)
    print("WGER CATALOG DIFF REPORT")
    print("=" * 72)
    print("Metadata / Version:")
    print(f"  Old version: {old['version'] or '(missing)'}")
    print(f"  New version: {new['version'] or '(missing)'}")
    print(f"  Old row count: {old['exercise_count']}")
    print(f"  New row count: {new['exercise_count']}")
    delta = report["delta"]["exercise_count"]
    print(f"  Total delta: {delta:+d}")
    print("")

    print("ID-level catalog diff:")
    print(f"  Removed IDs: {summary['removed_count']}")
    print(f"  Added IDs: {summary['added_count']}")
    if report["examples"]["removed_ids"]:
        print(f"  Removed examples ({min(examples, summary['removed_count'])}):")
        for exercise_id in report["examples"]["removed_ids"]:
            print(f"    - {exercise_id}")
    if report["examples"]["added_ids"]:
        print(f"  Added examples ({min(examples, summary['added_count'])}):")
        for exercise_id in report["examples"]["added_ids"]:
            print(f"    - {exercise_id}")
    print("")

    print("Field-level changes (shared IDs):")
    print(f"  Shared IDs: {summary['shared_id_count']}")
    print(f"  Exercises with any field changes: {summary['changed_exercise_count']}")
    changed_field_counts = summary["changed_field_counts"]
    if changed_field_counts:
        for field in sorted(changed_field_counts.keys()):
            print(f"  - {field}: {changed_field_counts[field]}")
    else:
        print("  No field changes detected on shared IDs.")
    print("")

    print("Suspicious regressions:")
    regressions = summary["regressions"]
    print(f"  name_de became blank: {regressions['name_de_became_blank']}")
    print(f"  name_en became blank: {regressions['name_en_became_blank']}")
    print(f"  description_de became blank: {regressions['description_de_became_blank']}")
    print(f"  description_en became blank: {regressions['description_en_became_blank']}")
    print(f"  category became blank: {regressions['category_became_blank']}")
    print(f"  muscles_primary became blank: {regressions['muscles_primary_became_blank']}")
    print(f"  muscles_secondary became blank: {regressions['muscles_secondary_became_blank']}")
    print(
        f"  de_name lost while en still present: {regressions['de_name_lost_en_still_present']}"
    )
    print(f"  Row drop percent: {summary['row_drop_percent']:.2f}%")
    print("")

    if warnings:
        print("Warning flags:")
        for warning in warnings:
            print(
                f"  [{warning['severity'].upper()}] {warning['code']}: {warning['message']}"
            )
    else:
        print("Warning flags: none")
    print("")

    if report["examples"]["changed_rows"]:
        print("Changed field examples:")
        for row in report["examples"]["changed_rows"][:examples]:
            print(
                f"  id={row['id']} field={row['field']} "
                f"old={json.dumps(row['old'], ensure_ascii=False)} "
                f"new={json.dumps(row['new'], ensure_ascii=False)}"
            )
        print("")


def should_fail(report: Dict[str, Any], args: argparse.Namespace) -> Tuple[bool, List[str]]:
    reasons: List[str] = []
    removed_count = report["summary"]["removed_count"]
    regressions = report["summary"]["regressions"]
    warnings = report["warning_flags"]

    if removed_count > args.fail_on_removed_threshold:
        reasons.append(
            f"removed_count={removed_count} > fail_on_removed_threshold={args.fail_on_removed_threshold}"
        )

    if regressions["name_de_became_blank"] > 0 or regressions["name_en_became_blank"] > 0:
        reasons.append("name regression detected (non-empty name became blank)")

    if any(warning["severity"] == "severe" for warning in warnings):
        reasons.append("severe warning present")

    return len(reasons) > 0, reasons


def main() -> int:
    args = parse_args()
    try:
        old_catalog = load_catalog(args.old)
        new_catalog = load_catalog(args.new)
        report = compare_catalogs(old_catalog, new_catalog, args)
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    print_console_report(report, args.examples)

    if args.json_out:
        with open(args.json_out, "w", encoding="utf-8") as f:
            json.dump(report, f, ensure_ascii=False, indent=2)
        print(f"JSON report written to: {args.json_out}")

    if args.fail_on_breaking:
        fail, reasons = should_fail(report, args)
        if fail:
            print("")
            print("FAIL-ON-BREAKING triggered:")
            for reason in reasons:
                print(f"  - {reason}")
            return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
