import json
import os


def main() -> int:
    build_path = os.environ["BUILD_REPORT_PATH"]
    diff_path = os.environ["DIFF_REPORT_PATH"]
    out_path = os.environ["RELEASE_NOTES_PATH"]

    with open(build_path, "r", encoding="utf-8") as f:
        build = json.load(f)

    diff = {}
    if os.path.exists(diff_path):
        with open(diff_path, "r", encoding="utf-8") as f:
            diff = json.load(f)

    bmeta = build.get("build", {})
    bsum = build.get("summary", {})
    dsum = diff.get("summary", {}) if isinstance(diff, dict) else {}

    lines = [
        "# Wger Catalog Data Refresh",
        "",
        f"- Version: `{bmeta.get('db_version', 'n/a')}`",
        f"- Generated at: `{bmeta.get('generated_at', 'n/a')}`",
        f"- Imported exercises: `{bsum.get('imported_count', 'n/a')}`",
        f"- Rejected exercises: `{bsum.get('rejected_count', 'n/a')}`",
    ]

    if diff.get("skipped"):
        lines.append("- Diff: skipped (published reference DB missing)")
    elif dsum:
        lines.append(f"- Diff removed IDs: `{dsum.get('removed_count', 'n/a')}`")
        lines.append(f"- Diff added IDs: `{dsum.get('added_count', 'n/a')}`")
    else:
        lines.append("- Diff summary unavailable")

    lines.append("")
    lines.append("This is a data-artifact release channel used by app-side catalog refresh.")

    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
