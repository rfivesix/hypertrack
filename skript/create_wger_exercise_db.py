#!/usr/bin/env python3
import argparse
import datetime
import json
import os
import re
import sqlite3
from collections import Counter
from typing import Any, Dict, List, Optional

import requests

CATEGORY_OTHER = "Andere"

SOURCE_ENDPOINTS = {
    "categories": "https://wger.de/api/v2/exercisecategory/",
    "muscles": "https://wger.de/api/v2/muscle/",
    "exerciseinfo": "https://wger.de/api/v2/exerciseinfo/?limit=9999",
}

REJECTION_REASON_KEYS = (
    "missing_usable_title",
    "missing_usable_localized_title_after_fallback",
    "malformed_payload",
    "missing_required_source_fields",
    "duplicate_conflicting_id",
    "other",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate hypertrack_training.db from wger and optionally emit a build report."
    )
    parser.add_argument(
        "--db-out",
        default="hypertrack_training.db",
        help="Output SQLite DB path (default: hypertrack_training.db)",
    )
    parser.add_argument(
        "--report-json-out",
        help="Optional output path for machine-readable build report JSON.",
    )
    parser.add_argument(
        "--report-max-examples",
        type=int,
        default=25,
        help="Max rejected examples to store in report (default: 25)",
    )
    return parser.parse_args()


def clean_html(raw_html: Any) -> str:
    if not isinstance(raw_html, str):
        return ""
    cleanr = re.compile("<.*?>")
    cleantext = re.sub(cleanr, "", raw_html)
    return cleantext.strip()


def normalize_text(value: Any) -> str:
    if not isinstance(value, str):
        return ""
    return value.strip()


def get_id(x: Any) -> Any:
    if isinstance(x, dict):
        return x.get("id")
    return x


def now_iso_utc() -> str:
    return datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat()


def fetch_endpoint(url: str) -> Dict[str, Any]:
    response = requests.get(url, timeout=30)
    response.raise_for_status()
    payload = response.json()
    if not isinstance(payload, dict):
        raise ValueError(f"Unexpected payload shape from {url}: expected JSON object")
    results = payload.get("results", [])
    if not isinstance(results, list):
        raise ValueError(f"Unexpected payload shape from {url}: 'results' is not a list")
    return {
        "results": results,
        "status_code": response.status_code,
        "fetched_at": now_iso_utc(),
        "source_date_header": response.headers.get("Date", ""),
    }


def add_rejection(
    rejected_examples: List[Dict[str, Any]],
    reason_counts: Counter,
    reason: str,
    max_examples: int,
    example: Dict[str, Any],
) -> None:
    reason_counts[reason] += 1
    if len(rejected_examples) < max_examples:
        rejected_examples.append(example)


def process_and_create_db(
    db_out: str = "hypertrack_training.db",
    report_json_out: Optional[str] = None,
    report_max_examples: int = 25,
) -> int:
    print("Starte: Lade Daten von wger.de ...")

    try:
        categories_payload = fetch_endpoint(SOURCE_ENDPOINTS["categories"])
        muscles_payload = fetch_endpoint(SOURCE_ENDPOINTS["muscles"])
        exercises_payload = fetch_endpoint(SOURCE_ENDPOINTS["exerciseinfo"])
    except requests.RequestException as e:
        print(f"Fehler beim Download: {e}")
        return 2
    except Exception as e:
        print(f"Kritischer Fehler beim Laden der Quellen: {e}")
        return 2

    categories_data = categories_payload["results"]
    muscles_data = muscles_payload["results"]
    exercises_info_data = exercises_payload["results"]

    print(
        f"Geladen: {len(exercises_info_data)} Übungen, "
        f"{len(categories_data)} Kategorien, {len(muscles_data)} Muskeln."
    )

    category_map = {
        cat["id"]: cat.get("name")
        for cat in categories_data
        if isinstance(cat, dict) and "id" in cat
    }
    muscle_map = {
        m["id"]: m.get("name_en") or m.get("name")
        for m in muscles_data
        if isinstance(m, dict) and "id" in m
    }

    processed_exercises: Dict[str, Dict[str, Any]] = {}
    reason_counts: Counter = Counter({key: 0 for key in REJECTION_REASON_KEYS})
    rejected_examples: List[Dict[str, Any]] = []

    duplicate_payload_count = 0
    duplicate_conflict_count = 0
    malformed_translation_count = 0

    for raw_index, exercise_info in enumerate(exercises_info_data):
        if not isinstance(exercise_info, dict):
            add_rejection(
                rejected_examples,
                reason_counts,
                "malformed_payload",
                report_max_examples,
                {
                    "id": None,
                    "reason": "malformed_payload",
                    "details": "exercise payload is not an object",
                    "raw_index": raw_index,
                },
            )
            continue

        raw_id = exercise_info.get("id")
        if raw_id is None:
            add_rejection(
                rejected_examples,
                reason_counts,
                "missing_required_source_fields",
                report_max_examples,
                {
                    "id": None,
                    "reason": "missing_required_source_fields",
                    "details": "missing source field: id",
                    "raw_index": raw_index,
                },
            )
            continue

        exercise_id = normalize_text(str(raw_id))
        if not exercise_id:
            add_rejection(
                rejected_examples,
                reason_counts,
                "missing_required_source_fields",
                report_max_examples,
                {
                    "id": str(raw_id),
                    "reason": "missing_required_source_fields",
                    "details": "blank source field: id",
                    "raw_index": raw_index,
                },
            )
            continue

        translations = exercise_info.get("translations", [])
        if translations is None:
            translations = []
        if not isinstance(translations, list):
            add_rejection(
                rejected_examples,
                reason_counts,
                "malformed_payload",
                report_max_examples,
                {
                    "id": exercise_id,
                    "reason": "malformed_payload",
                    "details": "translations is not a list",
                    "raw_index": raw_index,
                },
            )
            continue

        raw_muscles = exercise_info.get("muscles", [])
        raw_muscles_secondary = exercise_info.get("muscles_secondary", [])
        if raw_muscles is None:
            raw_muscles = []
        if raw_muscles_secondary is None:
            raw_muscles_secondary = []
        if not isinstance(raw_muscles, list) or not isinstance(raw_muscles_secondary, list):
            add_rejection(
                rejected_examples,
                reason_counts,
                "malformed_payload",
                report_max_examples,
                {
                    "id": exercise_id,
                    "reason": "malformed_payload",
                    "details": "muscles or muscles_secondary is not a list",
                    "raw_index": raw_index,
                },
            )
            continue

        prim_muscles = sorted(
            {
                muscle_map.get(get_id(m))
                for m in raw_muscles
                if muscle_map.get(get_id(m))
            }
        )
        sec_muscles = sorted(
            {
                muscle_map.get(get_id(m))
                for m in raw_muscles_secondary
                if muscle_map.get(get_id(m))
            }
        )
        category_name = category_map.get(get_id(exercise_info.get("category")), CATEGORY_OTHER)

        is_duplicate_payload = exercise_id in processed_exercises
        if is_duplicate_payload:
            duplicate_payload_count += 1
            existing = processed_exercises[exercise_id]
            existing_category = existing.get("category_name", CATEGORY_OTHER)
            existing_prim = existing.get("muscles_primary", "[]")
            existing_sec = existing.get("muscles_secondary", "[]")
            if (
                existing_category != category_name
                or existing_prim != json.dumps(prim_muscles)
                or existing_sec != json.dumps(sec_muscles)
            ):
                duplicate_conflict_count += 1
        else:
            processed_exercises[exercise_id] = {
                "id": exercise_id,
                "category_name": category_name,
                "muscles_primary": json.dumps(prim_muscles),
                "muscles_secondary": json.dumps(sec_muscles),
                "name_de": "",
                "description_de": "",
                "name_en": "",
                "description_en": "",
                "is_custom": 0,
                "created_by": "system",
                "source": "base",
                "image_path": "",
            }

        target = processed_exercises[exercise_id]

        raw_name_de = normalize_text(target.get("name_de"))
        raw_name_en = normalize_text(target.get("name_en"))
        saw_any_non_empty_title_any_lang = bool(raw_name_de or raw_name_en)

        for t in translations:
            if not isinstance(t, dict):
                malformed_translation_count += 1
                continue

            lang = t.get("language")
            name = normalize_text(t.get("name"))
            desc = clean_html(t.get("description"))

            if name:
                saw_any_non_empty_title_any_lang = True

            if lang == 1:
                if name:
                    target["name_de"] = name
                if desc:
                    target["description_de"] = desc
            elif lang == 2:
                if name:
                    target["name_en"] = name
                if desc:
                    target["description_en"] = desc

        previous_any_title = bool(target.get("_debug_has_any_title_any_lang", False))
        target["_debug_has_any_title_any_lang"] = (
            previous_any_title or saw_any_non_empty_title_any_lang
        )

    final_rows: List[Dict[str, Any]] = []

    fallback_stats = {
        "used_en_for_de": 0,
        "used_de_for_en": 0,
        "both_present": 0,
        "de_only": 0,
        "en_only": 0,
        "neither_present": 0,
        "original_de_present": 0,
        "original_en_present": 0,
    }

    for exercise_id in sorted(processed_exercises.keys(), key=lambda x: int(x) if x.isdigit() else x):
        row = processed_exercises[exercise_id]

        orig_name_de = normalize_text(row.get("name_de"))
        orig_name_en = normalize_text(row.get("name_en"))

        if orig_name_de:
            fallback_stats["original_de_present"] += 1
        if orig_name_en:
            fallback_stats["original_en_present"] += 1

        final_name_de = orig_name_de if orig_name_de else orig_name_en
        final_name_en = orig_name_en if orig_name_en else orig_name_de

        if not orig_name_de and final_name_de:
            fallback_stats["used_en_for_de"] += 1
        if not orig_name_en and final_name_en:
            fallback_stats["used_de_for_en"] += 1

        row["name_de"] = final_name_de
        row["name_en"] = final_name_en

        orig_description_de = normalize_text(row.get("description_de"))
        orig_description_en = normalize_text(row.get("description_en"))
        row["description_de"] = orig_description_de if orig_description_de else orig_description_en
        row["description_en"] = orig_description_en if orig_description_en else orig_description_de

        has_de = bool(row["name_de"])
        has_en = bool(row["name_en"])

        if has_de and has_en:
            fallback_stats["both_present"] += 1
        elif has_de:
            fallback_stats["de_only"] += 1
        elif has_en:
            fallback_stats["en_only"] += 1
        else:
            fallback_stats["neither_present"] += 1
            reason = "missing_usable_title"
            if row.get("_debug_has_any_title_any_lang"):
                reason = "missing_usable_localized_title_after_fallback"

            add_rejection(
                rejected_examples,
                reason_counts,
                reason,
                report_max_examples,
                {
                    "id": exercise_id,
                    "reason": reason,
                    "name_de_raw": orig_name_de,
                    "name_en_raw": orig_name_en,
                    "category_name": row.get("category_name", ""),
                },
            )
            continue

        row.pop("_debug_has_any_title_any_lang", None)
        final_rows.append(row)

    generated_at = now_iso_utc()
    db_version = datetime.datetime.now().strftime("%Y%m%d%H%M")

    db_dir = os.path.dirname(db_out)
    if db_dir:
        os.makedirs(db_dir, exist_ok=True)

    if os.path.exists(db_out):
        os.remove(db_out)

    conn = sqlite3.connect(db_out)
    cursor = conn.cursor()

    cursor.execute(
        """
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        name_de TEXT,
        name_en TEXT,
        description_de TEXT,
        description_en TEXT,
        category_name TEXT,
        muscles_primary TEXT,
        muscles_secondary TEXT,
        image_path TEXT,
        is_custom INTEGER DEFAULT 0,
        created_by TEXT DEFAULT 'system',
        source TEXT DEFAULT 'base'
      )"""
    )

    cursor.execute("CREATE TABLE metadata (key TEXT PRIMARY KEY, value TEXT)")
    cursor.execute("INSERT INTO metadata VALUES ('version', ?)", (db_version,))

    insert_columns = [
        "id",
        "name_de",
        "name_en",
        "description_de",
        "description_en",
        "category_name",
        "muscles_primary",
        "muscles_secondary",
        "image_path",
        "is_custom",
        "created_by",
        "source",
    ]
    insert_values = [tuple(row[col] for col in insert_columns) for row in final_rows]
    cursor.executemany(
        """
        INSERT INTO exercises (
            id, name_de, name_en, description_de, description_en,
            category_name, muscles_primary, muscles_secondary,
            image_path, is_custom, created_by, source
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        insert_values,
    )

    conn.commit()
    conn.close()

    raw_exercise_count = len(exercises_info_data)
    imported_count = len(final_rows)
    rejected_count = sum(reason_counts.values())

    import_rate = (imported_count / raw_exercise_count) if raw_exercise_count else 0.0
    rejection_rate = (rejected_count / raw_exercise_count) if raw_exercise_count else 0.0

    report = {
        "build": {
            "generated_at": generated_at,
            "db_version": db_version,
            "db_output_path": db_out,
            "source_endpoints": [
                {
                    "name": "categories",
                    "url": SOURCE_ENDPOINTS["categories"],
                    "status_code": categories_payload["status_code"],
                    "fetched_at": categories_payload["fetched_at"],
                    "source_date_header": categories_payload["source_date_header"],
                },
                {
                    "name": "muscles",
                    "url": SOURCE_ENDPOINTS["muscles"],
                    "status_code": muscles_payload["status_code"],
                    "fetched_at": muscles_payload["fetched_at"],
                    "source_date_header": muscles_payload["source_date_header"],
                },
                {
                    "name": "exerciseinfo",
                    "url": SOURCE_ENDPOINTS["exerciseinfo"],
                    "status_code": exercises_payload["status_code"],
                    "fetched_at": exercises_payload["fetched_at"],
                    "source_date_header": exercises_payload["source_date_header"],
                },
            ],
            "source_timestamp": exercises_payload["source_date_header"] or "",
        },
        "summary": {
            "raw_exercise_count": raw_exercise_count,
            "imported_count": imported_count,
            "rejected_count": rejected_count,
            "import_rate": round(import_rate, 6),
            "rejection_rate": round(rejection_rate, 6),
        },
        "import_metadata": {
            "categories_loaded": len(categories_data),
            "muscles_loaded": len(muscles_data),
            "duplicate_payload_count": duplicate_payload_count,
            "duplicate_conflict_count": duplicate_conflict_count,
            "malformed_translation_count": malformed_translation_count,
        },
        "language_fallbacks": fallback_stats,
        "rejection_reasons": {reason: int(reason_counts[reason]) for reason in REJECTION_REASON_KEYS},
        "rejected_examples": rejected_examples,
    }

    print("")
    print(f"ERFOLG: '{db_out}' erstellt (Version: {db_version}).")
    print("Build summary:")
    print(f"  raw exercises: {raw_exercise_count}")
    print(f"  imported: {imported_count}")
    print(f"  rejected: {rejected_count}")
    print(f"  import rate: {import_rate:.2%}")
    print(f"  rejection rate: {rejection_rate:.2%}")
    print("Rejection reasons:")
    for reason in REJECTION_REASON_KEYS:
        print(f"  - {reason}: {reason_counts[reason]}")

    if report_json_out:
        report_dir = os.path.dirname(report_json_out)
        if report_dir:
            os.makedirs(report_dir, exist_ok=True)
        with open(report_json_out, "w", encoding="utf-8") as f:
            json.dump(report, f, ensure_ascii=False, indent=2)
        print(f"Report JSON geschrieben: {report_json_out}")

    print("Kopiere die DB-Datei jetzt nach 'assets/db/' falls gewünscht.")

    return 0


def main() -> int:
    args = parse_args()
    return process_and_create_db(
        db_out=args.db_out,
        report_json_out=args.report_json_out,
        report_max_examples=max(1, args.report_max_examples),
    )


if __name__ == "__main__":
    raise SystemExit(main())
