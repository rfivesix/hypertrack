#!/usr/bin/env python3
import argparse
import json
import os
import sqlite3
import sys
from typing import Any, Dict, List

REQUIRED_TABLES = ("products", "metadata")
REQUIRED_PRODUCT_COLUMNS = (
    "barcode",
    "name",
    "brand",
    "calories",
    "protein",
    "carbs",
    "fat",
    "sugar",
    "fiber",
    "salt",
)
COMPARE_FIELDS = REQUIRED_PRODUCT_COLUMNS[1:]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Compare two generated Hypertrack OFF SQLite catalogs by barcode."
    )
    parser.add_argument("--old", required=True, help="Path to previous OFF DB")
    parser.add_argument("--new", required=True, help="Path to new OFF DB")
    parser.add_argument(
        "--json-out", help="Optional path to machine-readable JSON diff"
    )
    parser.add_argument(
        "--examples",
        type=int,
        default=20,
        help="Example sample count for removed/added/changed barcode lists (default: 20)",
    )
    parser.add_argument(
        "--removed-severe-threshold",
        type=int,
        default=5000,
        help="Removed barcode count at or above this threshold is severe (default: 5000)",
    )
    parser.add_argument(
        "--row-drop-warn-percent",
        type=float,
        default=10.0,
        help="Warn when total row count drop is at least this percent (default: 10)",
    )
    parser.add_argument(
        "--row-drop-severe-percent",
        type=float,
        default=35.0,
        help="Severe when total row count drop is at least this percent (default: 35)",
    )
    parser.add_argument(
        "--fail-on-breaking",
        action="store_true",
        help="Exit non-zero when severe or disallowed breaking changes are detected",
    )
    parser.add_argument(
        "--fail-on-removed-threshold",
        type=int,
        default=0,
        help="With --fail-on-breaking, fail if removed_count is above this value",
    )
    return parser.parse_args()


def require_file(path: str) -> None:
    if not os.path.exists(path):
        raise FileNotFoundError(f"Database not found: {path}")


def ensure_schema(conn: sqlite3.Connection, alias: str, db_path: str) -> None:
    table_rows = conn.execute(
        f"SELECT name FROM {alias}.sqlite_master WHERE type='table'"
    ).fetchall()
    tables = {row[0] for row in table_rows}

    missing_tables = [table for table in REQUIRED_TABLES if table not in tables]
    if missing_tables:
        raise ValueError(f"Missing tables in {db_path}: {', '.join(missing_tables)}")

    pragma_rows = conn.execute(f"PRAGMA {alias}.table_info(products)").fetchall()
    columns = {row[1] for row in pragma_rows}
    missing_columns = [col for col in REQUIRED_PRODUCT_COLUMNS if col not in columns]
    if missing_columns:
        raise ValueError(
            f"Missing required product columns in {db_path}: {', '.join(missing_columns)}"
        )


def read_version(conn: sqlite3.Connection, alias: str) -> str:
    row = conn.execute(
        f"SELECT value FROM {alias}.metadata WHERE key = 'version' LIMIT 1"
    ).fetchone()
    if not row:
        return ""
    return (row[0] or "").strip()


def scalar_int(conn: sqlite3.Connection, sql: str) -> int:
    row = conn.execute(sql).fetchone()
    if not row:
        return 0
    value = row[0]
    if value is None:
        return 0
    return int(value)


def sample_values(conn: sqlite3.Connection, sql: str, limit: int) -> List[str]:
    rows = conn.execute(f"{sql} LIMIT {limit}").fetchall()
    return [str(row[0]) for row in rows if row and row[0] is not None]


def build_field_change_count_query(field: str) -> str:
    # Cast to text for deterministic comparison across numeric/text SQLite affinity.
    return (
        "SELECT COUNT(*) "
        "FROM olddb.products o "
        "JOIN newdb.products n ON n.barcode = o.barcode "
        f"WHERE COALESCE(CAST(o.{field} AS TEXT), '') != COALESCE(CAST(n.{field} AS TEXT), '')"
    )


def compare_catalogs(
    old_path: str, new_path: str, args: argparse.Namespace
) -> Dict[str, Any]:
    conn = sqlite3.connect(":memory:")
    try:
        conn.execute("ATTACH DATABASE ? AS olddb", (old_path,))
        conn.execute("ATTACH DATABASE ? AS newdb", (new_path,))

        ensure_schema(conn, "olddb", old_path)
        ensure_schema(conn, "newdb", new_path)

        old_version = read_version(conn, "olddb")
        new_version = read_version(conn, "newdb")

        old_count = scalar_int(conn, "SELECT COUNT(*) FROM olddb.products")
        new_count = scalar_int(conn, "SELECT COUNT(*) FROM newdb.products")

        removed_count = scalar_int(
            conn,
            """
            SELECT COUNT(*)
            FROM olddb.products o
            LEFT JOIN newdb.products n ON n.barcode = o.barcode
            WHERE n.barcode IS NULL
            """,
        )
        added_count = scalar_int(
            conn,
            """
            SELECT COUNT(*)
            FROM newdb.products n
            LEFT JOIN olddb.products o ON o.barcode = n.barcode
            WHERE o.barcode IS NULL
            """,
        )

        changed_count = scalar_int(
            conn,
            """
            SELECT COUNT(*)
            FROM olddb.products o
            JOIN newdb.products n ON n.barcode = o.barcode
            WHERE
              COALESCE(o.name, '') != COALESCE(n.name, '') OR
              COALESCE(o.brand, '') != COALESCE(n.brand, '') OR
              COALESCE(CAST(o.calories AS TEXT), '') != COALESCE(CAST(n.calories AS TEXT), '') OR
              COALESCE(CAST(o.protein AS TEXT), '') != COALESCE(CAST(n.protein AS TEXT), '') OR
              COALESCE(CAST(o.carbs AS TEXT), '') != COALESCE(CAST(n.carbs AS TEXT), '') OR
              COALESCE(CAST(o.fat AS TEXT), '') != COALESCE(CAST(n.fat AS TEXT), '') OR
              COALESCE(CAST(o.sugar AS TEXT), '') != COALESCE(CAST(n.sugar AS TEXT), '') OR
              COALESCE(CAST(o.fiber AS TEXT), '') != COALESCE(CAST(n.fiber AS TEXT), '') OR
              COALESCE(CAST(o.salt AS TEXT), '') != COALESCE(CAST(n.salt AS TEXT), '')
            """,
        )

        field_change_counts = {
            field: scalar_int(conn, build_field_change_count_query(field))
            for field in COMPARE_FIELDS
        }
        field_change_counts = {
            key: value for key, value in field_change_counts.items() if value > 0
        }

        removed_samples = sample_values(
            conn,
            """
            SELECT o.barcode
            FROM olddb.products o
            LEFT JOIN newdb.products n ON n.barcode = o.barcode
            WHERE n.barcode IS NULL
            ORDER BY o.barcode
            """,
            args.examples,
        )
        added_samples = sample_values(
            conn,
            """
            SELECT n.barcode
            FROM newdb.products n
            LEFT JOIN olddb.products o ON o.barcode = n.barcode
            WHERE o.barcode IS NULL
            ORDER BY n.barcode
            """,
            args.examples,
        )
        changed_samples = sample_values(
            conn,
            """
            SELECT o.barcode
            FROM olddb.products o
            JOIN newdb.products n ON n.barcode = o.barcode
            WHERE
              COALESCE(o.name, '') != COALESCE(n.name, '') OR
              COALESCE(o.brand, '') != COALESCE(n.brand, '') OR
              COALESCE(CAST(o.calories AS TEXT), '') != COALESCE(CAST(n.calories AS TEXT), '') OR
              COALESCE(CAST(o.protein AS TEXT), '') != COALESCE(CAST(n.protein AS TEXT), '') OR
              COALESCE(CAST(o.carbs AS TEXT), '') != COALESCE(CAST(n.carbs AS TEXT), '') OR
              COALESCE(CAST(o.fat AS TEXT), '') != COALESCE(CAST(n.fat AS TEXT), '') OR
              COALESCE(CAST(o.sugar AS TEXT), '') != COALESCE(CAST(n.sugar AS TEXT), '') OR
              COALESCE(CAST(o.fiber AS TEXT), '') != COALESCE(CAST(n.fiber AS TEXT), '') OR
              COALESCE(CAST(o.salt AS TEXT), '') != COALESCE(CAST(n.salt AS TEXT), '')
            ORDER BY o.barcode
            """,
            args.examples,
        )

        row_drop_percent = 0.0
        if old_count > 0 and new_count < old_count:
            row_drop_percent = ((old_count - new_count) / old_count) * 100.0

        warnings: List[Dict[str, Any]] = []

        if removed_count > 0:
            warnings.append(
                {
                    "code": "REMOVED_BARCODES",
                    "severity": "warning",
                    "value": removed_count,
                    "message": f"Products removed: {removed_count}",
                }
            )

        if removed_count >= args.removed_severe_threshold:
            warnings.append(
                {
                    "code": "REMOVED_BARCODES_SEVERE",
                    "severity": "severe",
                    "value": removed_count,
                    "message": (
                        "Removed product count exceeds severe threshold "
                        f"({removed_count} >= {args.removed_severe_threshold})"
                    ),
                }
            )

        if row_drop_percent >= args.row_drop_warn_percent:
            severity = (
                "severe"
                if row_drop_percent >= args.row_drop_severe_percent
                else "warning"
            )
            warnings.append(
                {
                    "code": "ROW_COUNT_DROP",
                    "severity": severity,
                    "value": row_drop_percent,
                    "message": (
                        f"Row count dropped by {row_drop_percent:.2f}% "
                        f"({old_count} -> {new_count})"
                    ),
                }
            )

        severe_warning_count = len([w for w in warnings if w["severity"] == "severe"])
        breaking = severe_warning_count > 0
        if args.fail_on_breaking and removed_count > args.fail_on_removed_threshold:
            breaking = True

        report: Dict[str, Any] = {
            "old": {
                "path": old_path,
                "version": old_version,
                "product_count": old_count,
            },
            "new": {
                "path": new_path,
                "version": new_version,
                "product_count": new_count,
            },
            "summary": {
                "removed_count": removed_count,
                "added_count": added_count,
                "changed_count": changed_count,
                "old_product_count": old_count,
                "new_product_count": new_count,
                "count_delta": new_count - old_count,
                "row_drop_percent": row_drop_percent,
                "severe_warning_count": severe_warning_count,
            },
            "changed_field_counts": field_change_counts,
            "samples": {
                "removed_barcodes": removed_samples,
                "added_barcodes": added_samples,
                "changed_barcodes": changed_samples,
            },
            "warnings": warnings,
            "breaking": breaking,
        }

        return report
    finally:
        conn.close()


def print_report(report: Dict[str, Any], args: argparse.Namespace) -> None:
    old = report["old"]
    new = report["new"]
    summary = report["summary"]

    print("OFF catalog diff summary")
    print(
        f"- old version={old.get('version') or 'n/a'} rows={old.get('product_count', 0)}"
    )
    print(
        f"- new version={new.get('version') or 'n/a'} rows={new.get('product_count', 0)}"
    )
    print(
        f"- removed={summary['removed_count']} added={summary['added_count']} "
        f"changed={summary['changed_count']}"
    )

    if summary.get("row_drop_percent", 0) > 0:
        print(f"- row drop: {summary['row_drop_percent']:.2f}%")

    warnings = report.get("warnings", [])
    if warnings:
        print("- warnings:")
        for warning in warnings[: args.examples]:
            print(
                f"  - [{warning['severity']}] {warning['code']}: {warning['message']}"
            )


def main() -> int:
    args = parse_args()

    try:
        require_file(args.old)
        require_file(args.new)
        report = compare_catalogs(args.old, args.new, args)
        print_report(report, args)

        if args.json_out:
            out_dir = os.path.dirname(args.json_out)
            if out_dir:
                os.makedirs(out_dir, exist_ok=True)
            with open(args.json_out, "w", encoding="utf-8") as file:
                json.dump(report, file, indent=2, ensure_ascii=False)

        if args.fail_on_breaking and report.get("breaking"):
            print(
                "Breaking changes detected with --fail-on-breaking enabled.",
                file=sys.stderr,
            )
            return 1

        return 0
    except Exception as exc:
        print(f"OFF catalog diff failed: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
