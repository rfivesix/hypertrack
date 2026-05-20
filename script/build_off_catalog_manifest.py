#!/usr/bin/env python3
import hashlib
import json
import math
import os
import sys
from typing import Any, Dict

SOURCE_ID = "off_food_catalog"


def sha256_file(path: str) -> str:
    digest = hashlib.sha256()
    with open(path, "rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_json(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as file:
        payload = json.load(file)
    if not isinstance(payload, dict):
        raise ValueError(f"JSON payload must be an object: {path}")
    return payload


def parse_int_env(name: str, default: int) -> int:
    raw = os.environ.get(name)
    if raw is None or raw.strip() == "":
        return default
    return int(raw)


def main() -> int:
    build_path = os.environ["BUILD_REPORT_PATH"]
    diff_path = os.environ["DIFF_REPORT_PATH"]
    manifest_path = os.environ["MANIFEST_PATH"]
    generated_db_path = os.environ["GENERATED_DB_PATH"]
    release_base = os.environ["RELEASE_DOWNLOAD_BASE"]
    country_code = os.environ["COUNTRY_CODE"].strip().lower()

    build_report = read_json(build_path)

    diff_report: Dict[str, Any] = {}
    if os.path.exists(diff_path):
        diff_report = read_json(diff_path)

    build = build_report.get("build", {}) if isinstance(build_report, dict) else {}
    summary = build_report.get("summary", {}) if isinstance(build_report, dict) else {}

    imported_count = int(summary.get("imported_count", 0) or 0)
    floor_from_imported = math.floor(imported_count * 0.7)
    configured_min = parse_int_env("OFF_MIN_PRODUCT_COUNT", 1000)
    min_product_count = max(configured_min, floor_from_imported)
    if imported_count > 0:
        min_product_count = min(min_product_count, imported_count)

    db_file = os.path.basename(generated_db_path)
    build_report_file = os.path.basename(build_path)

    manifest: Dict[str, Any] = {
        "source_id": SOURCE_ID,
        "channel": os.environ.get("RELEASE_CHANNEL", "stable"),
        "country_code": country_code,
        "release_tag": os.environ.get("RELEASE_TAG", ""),
        "release_page_url": os.environ.get("RELEASE_PAGE_URL", ""),
        "asset_base_url": release_base,
        "version": str(build.get("db_version", "")).strip(),
        "generated_at": build.get("generated_at"),
        "db_file": db_file,
        "db_url": f"{release_base}{db_file}",
        "db_sha256": sha256_file(generated_db_path),
        "build_report_file": build_report_file,
        "build_report_url": f"{release_base}{build_report_file}",
        "build_report_sha256": sha256_file(build_path),
        "product_count": imported_count,
        "min_product_count": int(min_product_count),
        "safety": {
            "diff_skipped": bool(diff_report.get("skipped", False)),
            "diff_removed_count": (
                diff_report.get("summary", {}).get("removed_count")
                if isinstance(diff_report, dict)
                else None
            ),
            "diff_added_count": (
                diff_report.get("summary", {}).get("added_count")
                if isinstance(diff_report, dict)
                else None
            ),
        },
    }

    diff_is_available = bool(diff_report) and not bool(
        diff_report.get("skipped", False)
    )
    if diff_is_available and os.path.exists(diff_path):
        diff_report_file = os.path.basename(diff_path)
        manifest["diff_report_file"] = diff_report_file
        manifest["diff_report_url"] = f"{release_base}{diff_report_file}"
        manifest["diff_report_sha256"] = sha256_file(diff_path)

    if not manifest["version"]:
        print("Build report missing build.db_version", file=sys.stderr)
        return 1

    out_dir = os.path.dirname(manifest_path)
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)

    with open(manifest_path, "w", encoding="utf-8") as file:
        json.dump(manifest, file, indent=2, ensure_ascii=False)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
