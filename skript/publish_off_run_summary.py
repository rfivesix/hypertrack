#!/usr/bin/env python3
import json
import os


def load_json(path: str):
    with open(path, "r", encoding="utf-8") as file:
        return json.load(file)


def main() -> int:
    country_code = os.environ.get("COUNTRY_CODE", "").strip().lower()
    build_path = os.environ["BUILD_REPORT_PATH"]
    diff_path = os.environ["DIFF_REPORT_PATH"]

    release_page_url = os.environ.get("RELEASE_PAGE_URL", "")
    publish_outcome = os.environ.get("PUBLISH_OUTCOME", "skipped")
    generator_success = os.environ.get("GENERATOR_SUCCESS", "false")
    generate_outcome = os.environ.get("GENERATE_OUTCOME", "unknown")
    summary_path = os.environ["GITHUB_STEP_SUMMARY"]

    lines = [f"## OFF Catalog Refresh Summary ({country_code.upper()})", ""]
    lines.append(f"- Catalog generation: `{generate_outcome}`")

    if generator_success == "true" and os.path.exists(build_path):
        build = load_json(build_path)
        bmeta = build.get("build", {})
        summary = build.get("summary", {})
        lines.append(f"- DB version: `{bmeta.get('db_version', 'n/a')}`")
        lines.append(f"- Generated at: `{bmeta.get('generated_at', 'n/a')}`")
        lines.append(f"- Imported products: `{summary.get('imported_count', 'n/a')}`")
        lines.append(f"- Rejected rows: `{summary.get('rejected_count', 'n/a')}`")
    else:
        lines.append(
            "- Catalog artifacts were not generated; downstream steps were skipped."
        )

    if generator_success == "true" and os.path.exists(diff_path):
        diff = load_json(diff_path)
        if diff.get("skipped"):
            lines.append("- Diff: skipped (published reference DB missing)")
        else:
            dsum = diff.get("summary", {})
            lines.append(f"- Removed barcodes: `{dsum.get('removed_count', 'n/a')}`")
            lines.append(f"- Added barcodes: `{dsum.get('added_count', 'n/a')}`")
            lines.append(f"- Changed barcodes: `{dsum.get('changed_count', 'n/a')}`")

    lines.append(f"- Release publication: `{publish_outcome}`")
    lines.append(f"- Catalog release page: {release_page_url}")

    with open(summary_path, "a", encoding="utf-8") as file:
        file.write("\n".join(lines) + "\n")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
