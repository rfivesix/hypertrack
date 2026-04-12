import json
import os


def main() -> int:
    build_path = os.environ["BUILD_REPORT_PATH"]
    diff_path = os.environ["DIFF_REPORT_PATH"]
    release_page_url = os.environ.get("RELEASE_PAGE_URL", "")
    publish_outcome = os.environ.get("PUBLISH_OUTCOME", "skipped")
    generator_success = os.environ.get("GENERATOR_SUCCESS", "false")
    generate_outcome = os.environ.get("GENERATE_OUTCOME", "unknown")
    summary_path = os.environ["GITHUB_STEP_SUMMARY"]

    lines = ["## Wger Catalog Refresh Summary", ""]
    lines.append(f"- Catalog generation: `{generate_outcome}`")

    if generator_success == "true" and os.path.exists(build_path):
        with open(build_path, "r", encoding="utf-8") as f:
            build = json.load(f)
        bmeta = build.get("build", {})
        summary = build.get("summary", {})
        lines.append(f"- DB version: `{bmeta.get('db_version', 'n/a')}`")
        lines.append(f"- Generated at: `{bmeta.get('generated_at', 'n/a')}`")
        lines.append(f"- Imported: `{summary.get('imported_count', 'n/a')}`")
        lines.append(f"- Rejected: `{summary.get('rejected_count', 'n/a')}`")
    else:
        lines.append("- Catalog artifacts were not generated; downstream steps were skipped.")

    if generator_success == "true" and os.path.exists(diff_path):
        with open(diff_path, "r", encoding="utf-8") as f:
            diff = json.load(f)
        if diff.get("skipped"):
            lines.append("- Diff: skipped (published reference DB missing)")
        else:
            dsum = diff.get("summary", {})
            lines.append(f"- Removed IDs: `{dsum.get('removed_count', 'n/a')}`")
            lines.append(f"- Added IDs: `{dsum.get('added_count', 'n/a')}`")

    lines.append(f"- Release publication: `{publish_outcome}`")
    lines.append(f"- Catalog release page: {release_page_url}")

    with open(summary_path, "a", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
