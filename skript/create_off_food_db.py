#!/usr/bin/env python3
import argparse
import datetime
import json
import numbers
import os
import sqlite3
import sys
import uuid
from dataclasses import dataclass
from typing import Any, Dict, List, Sequence, Tuple

import numpy as np
import pandas as pd
import pyarrow.parquet as pq

SOURCE_ID = "off_food_catalog"
DEFAULT_BATCH_SIZE = 50000
NAMESPACE_FOOD = uuid.UUID("6ba7b810-9dad-11d1-80b4-00c04fd430c8")

COUNTRY_CONFIG: Dict[str, Dict[str, Any]] = {
    "de": {
        "preferred_languages": ("de", "en"),
        "country_tags": ("en:germany",),
    },
    "us": {
        "preferred_languages": ("en",),
        "country_tags": (
            "en:united-states",
            "en:united-states-of-america",
            "en:usa",
        ),
    },
    "uk": {
        "preferred_languages": ("en",),
        "country_tags": (
            "en:united-kingdom",
            "en:uk",
            "en:great-britain",
        ),
    },
}

NUTRIENT_NAME_MAP = {
    "energy-kcal": "calories",
    "proteins": "protein",
    "carbohydrates": "carbs",
    "fat": "fat",
    "sugars": "sugar",
    "fiber": "fiber",
    "salt": "salt",
}


@dataclass(frozen=True)
class BuildContext:
    country_code: str
    country_tags: Tuple[str, ...]
    preferred_languages: Tuple[str, ...]
    parquet_path: str
    source_url: str
    db_out: str
    report_json_out: str
    batch_size: int
    min_product_count: int


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Generate a country-specific Hypertrack OFF catalog SQLite DB from the "
            "Open Food Facts bulk parquet export."
        )
    )
    parser.add_argument(
        "--country-code",
        required=True,
        help="Country code (de/us/uk)",
    )
    parser.add_argument(
        "--parquet-path",
        required=True,
        help="Path to OFF food.parquet bulk export",
    )
    parser.add_argument(
        "--source-url",
        default="",
        help="Source URL used to obtain parquet (for report metadata)",
    )
    parser.add_argument(
        "--db-out",
        required=True,
        help="Output SQLite DB path",
    )
    parser.add_argument(
        "--report-json-out",
        required=True,
        help="Output build report JSON path",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=DEFAULT_BATCH_SIZE,
        help=f"Parquet batch size (default: {DEFAULT_BATCH_SIZE})",
    )
    parser.add_argument(
        "--min-product-count",
        type=int,
        default=0,
        help="Fail when imported product count is below this value",
    )
    parser.add_argument(
        "--country-tag",
        action="append",
        default=[],
        help=(
            "Optional override/additional OFF country tag filter. "
            "Can be provided multiple times."
        ),
    )
    return parser.parse_args()


def normalize_country_code(raw: str) -> str:
    value = raw.strip().lower()
    aliases = {
        "deu": "de",
        "ger": "de",
        "germany": "de",
        "usa": "us",
        "united-states": "us",
        "united_states": "us",
        "uk": "uk",
        "gbr": "uk",
        "united-kingdom": "uk",
        "united_kingdom": "uk",
    }
    return aliases.get(value, value)


def build_context(args: argparse.Namespace) -> BuildContext:
    country_code = normalize_country_code(args.country_code)
    if country_code not in COUNTRY_CONFIG:
        raise ValueError(
            "Unsupported country code. Expected one of: "
            + ", ".join(sorted(COUNTRY_CONFIG.keys()))
        )

    if args.batch_size <= 0:
        raise ValueError("--batch-size must be > 0")

    if args.min_product_count < 0:
        raise ValueError("--min-product-count must be >= 0")

    if not os.path.exists(args.parquet_path):
        raise FileNotFoundError(f"Parquet file not found: {args.parquet_path}")

    cfg = COUNTRY_CONFIG[country_code]
    configured_tags: List[str] = list(cfg["country_tags"])
    if args.country_tag:
        configured_tags.extend(
            [tag.strip().lower() for tag in args.country_tag if tag.strip()]
        )

    deduped_tags = tuple(sorted(set(configured_tags)))
    if not deduped_tags:
        raise ValueError("No country tags configured for filter")

    preferred_languages = tuple(cfg["preferred_languages"])

    return BuildContext(
        country_code=country_code,
        country_tags=deduped_tags,
        preferred_languages=preferred_languages,
        parquet_path=args.parquet_path,
        source_url=args.source_url.strip(),
        db_out=args.db_out,
        report_json_out=args.report_json_out,
        batch_size=args.batch_size,
        min_product_count=args.min_product_count,
    )


def now_iso_utc() -> str:
    return (
        datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat()
    )


def normalize_text(value: Any) -> str:
    if value is None:
        return ""
    text = value if isinstance(value, str) else str(value)
    return text.strip()


def to_tag_values(raw: Any) -> Tuple[str, ...]:
    if raw is None:
        return tuple()

    if isinstance(raw, str):
        stripped = raw.strip()
        if not stripped:
            return tuple()
        if "," in stripped:
            return tuple(
                token.strip().lower() for token in stripped.split(",") if token.strip()
            )
        return (stripped.lower(),)

    if isinstance(raw, (list, tuple, set, np.ndarray)):
        normalized: List[str] = []
        for item in raw:
            token = normalize_text(item).lower()
            if token:
                normalized.append(token)
        return tuple(normalized)

    return tuple()


def has_country_tag(raw_tags: Any, allowed_tags: Sequence[str]) -> bool:
    tag_values = to_tag_values(raw_tags)
    if not tag_values:
        return False
    tags = set(tag_values)
    for allowed in allowed_tags:
        if allowed in tags:
            return True
    return False


def _extract_name_from_dict(
    value: Dict[str, Any], preferred_languages: Sequence[str]
) -> str:
    # Variant 1: {"de": "Name", "en": "Name"}
    for lang in preferred_languages:
        candidate = normalize_text(value.get(lang))
        if candidate:
            return candidate

    # Variant 2: {"lang": "de", "text": "Name"}
    lang = normalize_text(value.get("lang")).lower()
    text = normalize_text(value.get("text"))
    if lang in preferred_languages and text:
        return text

    # Fallback to common alternate keys.
    for key in ("value", "name", "product_name"):
        candidate = normalize_text(value.get(key))
        if candidate:
            return candidate

    # Last fallback: first non-empty string value.
    for raw in value.values():
        candidate = normalize_text(raw)
        if candidate:
            return candidate

    return ""


def extract_product_name(raw: Any, preferred_languages: Sequence[str]) -> str:
    if raw is None:
        return ""

    if isinstance(raw, str):
        return normalize_text(raw)

    if isinstance(raw, dict):
        return _extract_name_from_dict(raw, preferred_languages)

    if isinstance(raw, (list, tuple, np.ndarray)):
        # Pass 1: explicit preferred language match.
        for lang in preferred_languages:
            for item in raw:
                if not isinstance(item, dict):
                    continue
                item_lang = normalize_text(item.get("lang")).lower()
                item_text = normalize_text(item.get("text"))
                if item_lang == lang and item_text:
                    return item_text

        # Pass 2: EN fallback.
        for item in raw:
            if not isinstance(item, dict):
                continue
            if normalize_text(item.get("lang")).lower() == "en":
                item_text = normalize_text(item.get("text"))
                if item_text:
                    return item_text

        # Pass 3: first usable candidate.
        for item in raw:
            if isinstance(item, dict):
                candidate = _extract_name_from_dict(item, preferred_languages)
            else:
                candidate = normalize_text(item)
            if candidate:
                return candidate

    return ""


def _parse_float(raw: Any) -> float:
    if raw is None:
        return 0.0
    if isinstance(raw, numbers.Number):
        return float(raw)
    if isinstance(raw, str):
        text = raw.strip().replace(",", ".")
        if not text:
            return 0.0
        try:
            return float(text)
        except ValueError:
            return 0.0
    return 0.0


def extract_nutrients(raw: Any) -> Dict[str, float]:
    result = {
        "calories": 0.0,
        "protein": 0.0,
        "carbs": 0.0,
        "fat": 0.0,
        "sugar": 0.0,
        "fiber": 0.0,
        "salt": 0.0,
    }

    if raw is None:
        result["calories"] = int(result["calories"])
        return result

    if isinstance(raw, dict):
        for source_name, target_name in NUTRIENT_NAME_MAP.items():
            candidates = [
                raw.get(f"{source_name}_100g"),
                raw.get(source_name),
            ]
            chosen = 0.0
            for candidate in candidates:
                if isinstance(candidate, dict):
                    value = _parse_float(
                        candidate.get("100g") or candidate.get("value")
                    )
                else:
                    value = _parse_float(candidate)
                if value != 0.0:
                    chosen = value
                    break
            result[target_name] = chosen

    elif isinstance(raw, (list, tuple, np.ndarray)):
        for item in raw:
            if not isinstance(item, dict):
                continue
            name = normalize_text(item.get("name"))
            target = NUTRIENT_NAME_MAP.get(name)
            if not target:
                continue
            value = _parse_float(item.get("100g"))
            if value == 0.0:
                value = _parse_float(item.get("value"))
            if value != 0.0:
                result[target] = value

    result["calories"] = int(result["calories"])
    return result


def generate_id(barcode: str) -> str:
    normalized = normalize_text(barcode)
    if not normalized:
        return str(uuid.uuid4())
    return str(uuid.uuid5(NAMESPACE_FOOD, normalized))


def ensure_parent_dir(path: str) -> None:
    parent = os.path.dirname(path)
    if parent:
        os.makedirs(parent, exist_ok=True)


def initialize_output_db(db_path: str) -> sqlite3.Connection:
    ensure_parent_dir(db_path)
    if os.path.exists(db_path):
        os.remove(db_path)

    conn = sqlite3.connect(db_path)
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA synchronous=NORMAL")
    conn.execute("PRAGMA temp_store=MEMORY")

    conn.execute("""
        CREATE TABLE products (
          id TEXT PRIMARY KEY,
          barcode TEXT NOT NULL UNIQUE,
          brand TEXT NOT NULL DEFAULT '',
          name TEXT NOT NULL,
          calories INTEGER NOT NULL DEFAULT 0,
          protein REAL NOT NULL DEFAULT 0,
          carbs REAL NOT NULL DEFAULT 0,
          fat REAL NOT NULL DEFAULT 0,
          sugar REAL NOT NULL DEFAULT 0,
          fiber REAL NOT NULL DEFAULT 0,
          salt REAL NOT NULL DEFAULT 0,
          source TEXT NOT NULL DEFAULT 'base',
          is_liquid INTEGER NOT NULL DEFAULT 0
        )
        """)
    conn.execute("""
        CREATE TABLE metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
        """)
    conn.execute("CREATE INDEX idx_products_barcode ON products(barcode)")
    conn.execute("CREATE INDEX idx_products_id ON products(id)")
    return conn


def build_records(
    df: pd.DataFrame,
    preferred_languages: Sequence[str],
) -> Tuple[List[Tuple[Any, ...]], Dict[str, int]]:
    stats = {
        "country_rows": len(df),
        "barcode_rows": 0,
        "named_rows": 0,
        "nutrition_rows": 0,
    }

    if df.empty:
        return [], stats

    working = df.copy()

    # Barcode filter.
    working = working.dropna(subset=["code"])
    working["barcode"] = working["code"].astype(str).str.strip()
    working = working[working["barcode"] != ""]
    stats["barcode_rows"] = len(working)
    if working.empty:
        return [], stats

    # Name extraction.
    working["name"] = working["product_name"].apply(
        lambda value: extract_product_name(value, preferred_languages)
    )
    working = working[working["name"] != ""]
    stats["named_rows"] = len(working)
    if working.empty:
        return [], stats

    # Nutrient extraction.
    nutrient_df = working["nutriments"].apply(extract_nutrients).apply(pd.Series)

    # Keep rows with meaningful energy or macros.
    has_energy = nutrient_df["calories"] > 0
    has_macros = (
        nutrient_df["protein"] + nutrient_df["carbs"] + nutrient_df["fat"]
    ) > 0
    valid_mask = has_energy | has_macros

    working = working.loc[valid_mask].copy()
    nutrient_df = nutrient_df.loc[valid_mask].copy()
    stats["nutrition_rows"] = len(working)
    if working.empty:
        return [], stats

    combined = pd.concat(
        [
            working[["barcode", "brands", "name"]].reset_index(drop=True),
            nutrient_df.reset_index(drop=True),
        ],
        axis=1,
    )
    combined.rename(columns={"brands": "brand"}, inplace=True)
    combined["brand"] = combined["brand"].fillna("").astype(str)

    records: List[Tuple[Any, ...]] = []
    for row in combined.itertuples(index=False):
        barcode = normalize_text(getattr(row, "barcode"))
        if not barcode:
            continue

        calories = int(_parse_float(getattr(row, "calories", 0)))
        protein = float(_parse_float(getattr(row, "protein", 0)))
        carbs = float(_parse_float(getattr(row, "carbs", 0)))
        fat = float(_parse_float(getattr(row, "fat", 0)))
        sugar = float(_parse_float(getattr(row, "sugar", 0)))
        fiber = float(_parse_float(getattr(row, "fiber", 0)))
        salt = float(_parse_float(getattr(row, "salt", 0)))

        records.append(
            (
                generate_id(barcode),
                barcode,
                normalize_text(getattr(row, "brand", "")),
                normalize_text(getattr(row, "name", "")),
                calories,
                protein,
                carbs,
                fat,
                sugar,
                fiber,
                salt,
                "base",
                0,
            )
        )

    return records, stats


def upsert_metadata(conn: sqlite3.Connection, metadata: Dict[str, Any]) -> None:
    entries = [
        (str(key), "" if value is None else str(value))
        for key, value in metadata.items()
    ]
    conn.executemany(
        "INSERT OR REPLACE INTO metadata (key, value) VALUES (?, ?)",
        entries,
    )


def write_report(path: str, payload: Dict[str, Any]) -> None:
    ensure_parent_dir(path)
    with open(path, "w", encoding="utf-8") as file:
        json.dump(payload, file, indent=2, ensure_ascii=False)


def process(ctx: BuildContext) -> int:
    print(f"Starting OFF bulk import for country={ctx.country_code}")
    print(f"Parquet source path: {ctx.parquet_path}")
    if ctx.source_url:
        print(f"Parquet source URL: {ctx.source_url}")

    parquet = pq.ParquetFile(ctx.parquet_path)
    total_rows = parquet.metadata.num_rows
    print(f"Parquet rows (raw): {total_rows:,}")

    conn = initialize_output_db(ctx.db_out)

    scanned_rows = 0
    country_rows = 0
    barcode_rows = 0
    named_rows = 0
    nutrition_rows = 0
    duplicate_rows = 0
    imported_count = 0

    columns = ["code", "brands", "product_name", "nutriments", "countries_tags"]

    try:
        cursor = conn.cursor()
        insert_sql = """
            INSERT OR IGNORE INTO products (
              id, barcode, brand, name, calories, protein, carbs, fat, sugar, fiber, salt, source, is_liquid
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """

        for batch_index, batch in enumerate(
            parquet.iter_batches(batch_size=ctx.batch_size, columns=columns),
            start=1,
        ):
            batch_df = batch.to_pandas()
            batch_rows = len(batch_df)
            scanned_rows += batch_rows

            if batch_index == 1:
                print(f"Batch 1 columns: {', '.join(batch_df.columns.tolist())}")
                for column in ("countries_tags", "product_name", "nutriments"):
                    if column in batch_df.columns and batch_rows > 0:
                        sample = next(
                            (
                                value
                                for value in batch_df[column].tolist()
                                if value is not None
                            ),
                            None,
                        )
                        if sample is not None:
                            print(
                                f"Batch 1 sample type {column}: {type(sample).__name__}"
                            )

            filtered = batch_df[
                batch_df["countries_tags"].apply(
                    lambda tags: has_country_tag(tags, ctx.country_tags)
                )
            ]
            if batch_index == 1:
                print(
                    "Batch 1 country filter rows: "
                    f"before={batch_rows:,}, after={len(filtered):,}"
                )

            records, stats = build_records(filtered, ctx.preferred_languages)

            country_rows += stats["country_rows"]
            barcode_rows += stats["barcode_rows"]
            named_rows += stats["named_rows"]
            nutrition_rows += stats["nutrition_rows"]

            if records:
                before_changes = conn.total_changes
                cursor.executemany(insert_sql, records)
                conn.commit()
                inserted = conn.total_changes - before_changes
                imported_count += inserted
                duplicate_rows += max(0, len(records) - inserted)

            if batch_index % 10 == 0 or scanned_rows >= total_rows:
                progress = (
                    (scanned_rows / total_rows) * 100 if total_rows > 0 else 100.0
                )
                print(
                    f"Batch {batch_index}: scanned={scanned_rows:,}/{total_rows:,} "
                    f"({progress:.1f}%), imported={imported_count:,}"
                )

        version = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%d%H%M")
        generated_at = now_iso_utc()

        upsert_metadata(
            conn,
            {
                "version": version,
                "generated_at": generated_at,
                "source_id": SOURCE_ID,
                "country_code": ctx.country_code,
                "country_tags": ",".join(ctx.country_tags),
                "source_url": ctx.source_url,
            },
        )
        conn.commit()

    finally:
        conn.close()

    rejected_count = max(0, scanned_rows - imported_count)

    report = {
        "build": {
            "source_id": SOURCE_ID,
            "country_code": ctx.country_code,
            "country_tags": list(ctx.country_tags),
            "parquet_path": ctx.parquet_path,
            "parquet_source_url": ctx.source_url,
            "batch_size": ctx.batch_size,
            "db_version": version,
            "generated_at": generated_at,
            "db_path": ctx.db_out,
        },
        "summary": {
            "total_rows_scanned": scanned_rows,
            "country_filtered_rows": country_rows,
            "rows_with_barcode": barcode_rows,
            "rows_with_name": named_rows,
            "rows_with_nutrition": nutrition_rows,
            "imported_count": imported_count,
            "duplicate_barcode_skipped": duplicate_rows,
            "rows_outside_country_filter": max(0, scanned_rows - country_rows),
            "rows_missing_barcode": max(0, country_rows - barcode_rows),
            "rows_missing_name": max(0, barcode_rows - named_rows),
            "rows_missing_nutrition": max(0, named_rows - nutrition_rows),
            "rejected_count": rejected_count,
        },
    }

    write_report(ctx.report_json_out, report)

    print(f"Completed OFF import for {ctx.country_code}. imported={imported_count:,}")
    print(f"DB written to: {ctx.db_out}")
    print(f"Build report: {ctx.report_json_out}")

    if ctx.min_product_count > 0 and imported_count < ctx.min_product_count:
        print(
            f"ERROR: imported_count={imported_count} is below required minimum {ctx.min_product_count}",
            file=sys.stderr,
        )
        return 3

    return 0


def main() -> int:
    try:
        args = parse_args()
        ctx = build_context(args)
        return process(ctx)
    except Exception as exc:
        print(f"OFF catalog build failed: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
