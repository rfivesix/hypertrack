import hashlib
import json
import math
import os


def sha256_file(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    build_path = os.environ["BUILD_REPORT_PATH"]
    diff_path = os.environ["DIFF_REPORT_PATH"]
    manifest_path = os.environ["MANIFEST_PATH"]
    release_base = os.environ["RELEASE_DOWNLOAD_BASE"]

    with open(build_path, "r", encoding="utf-8") as f:
        build_report = json.load(f)

    diff_report = {}
    if os.path.exists(diff_path):
        with open(diff_path, "r", encoding="utf-8") as f:
            diff_report = json.load(f)

    build = build_report.get("build", {})
    summary = build_report.get("summary", {})

    db_file = os.path.basename(os.environ["GENERATED_DB_PATH"])
    build_report_file = os.path.basename(build_path)
    diff_report_file = os.path.basename(diff_path)

    db_sha256 = sha256_file(os.environ["GENERATED_DB_PATH"])
    build_report_sha256 = sha256_file(build_path)
    diff_report_sha256 = sha256_file(diff_path) if os.path.exists(diff_path) else None

    imported_count = int(summary.get("imported_count", 0) or 0)
    min_exercise_count = max(50, math.floor(imported_count * 0.85))

    manifest = {
        "source_id": "wger_catalog",
        "channel": os.environ.get("RELEASE_CHANNEL", "stable"),
        "release_tag": os.environ.get("RELEASE_TAG", ""),
        "release_page_url": os.environ.get("RELEASE_PAGE_URL", ""),
        "asset_base_url": release_base,
        "version": build.get("db_version", ""),
        "generated_at": build.get("generated_at"),
        "db_file": db_file,
        "db_url": f"{release_base}{db_file}",
        "db_sha256": db_sha256,
        "build_report_file": build_report_file,
        "build_report_url": f"{release_base}{build_report_file}",
        "build_report_sha256": build_report_sha256,
        "diff_report_file": diff_report_file,
        "diff_report_url": f"{release_base}{diff_report_file}",
        "diff_report_sha256": diff_report_sha256,
        "expected_exercise_count": imported_count,
        "min_exercise_count": int(min_exercise_count),
        "safety": {
            "diff_skipped": bool(diff_report.get("skipped", False)),
            "diff_removed_count": diff_report.get("summary", {}).get("removed_count"),
            "diff_added_count": diff_report.get("summary", {}).get("added_count"),
        },
    }

    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
