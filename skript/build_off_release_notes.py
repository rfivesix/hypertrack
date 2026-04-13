#!/usr/bin/env python3
import json
import os


def load_json(path: str):
    with open(path, "r", encoding="utf-8") as file:
        return json.load(file)


def main() -> int:
    build_path = os.environ["BUILD_REPORT_PATH"]
    diff_path = os.environ["DIFF_REPORT_PATH"]
    out_path = os.environ["RELEASE_NOTES_PATH"]
    country_code = os.environ.get("COUNTRY_CODE", "").strip().lower()

    build = load_json(build_path)
    diff = load_json(diff_path) if os.path.exists(diff_path) else {}

    bmeta = build.get("build", {})
    bsum = build.get("summary", {})
    dsum = diff.get("summary", {}) if isinstance(diff, dict) else {}

    lines = [
        f"# OFF Food Catalog Refresh ({country_code.upper()})",
        "",
        f"- Version: `{bmeta.get('db_version', 'n/a')}`",
        f"- Generated at: `{bmeta.get('generated_at', 'n/a')}`",
        f"- Country code: `{country_code}`",
        f"- Country filter tags: `{', '.join(bmeta.get('country_tags', []))}`",
        f"- Imported products: `{bsum.get('imported_count', 'n/a')}`",
        f"- Rejected rows: `{bsum.get('rejected_count', 'n/a')}`",
        f"- Duplicate barcodes skipped: `{bsum.get('duplicate_barcode_skipped', 'n/a')}`",
    ]

    if diff.get("skipped"):
        lines.append("- Diff: skipped (published reference DB missing)")
    elif dsum:
        lines.append(f"- Diff removed barcodes: `{dsum.get('removed_count', 'n/a')}`")
        lines.append(f"- Diff added barcodes: `{dsum.get('added_count', 'n/a')}`")
        lines.append(f"- Diff changed barcodes: `{dsum.get('changed_count', 'n/a')}`")
    else:
        lines.append("- Diff summary unavailable")

    lines.append("")
    lines.append(
        "This is a data-artifact release channel used by app-side Open Food Facts catalog refresh."
    )

    out_dir = os.path.dirname(out_path)
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)

    with open(out_path, "w", encoding="utf-8") as file:
        file.write("\n".join(lines) + "\n")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
