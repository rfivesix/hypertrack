import json
import os
import sys
from urllib.parse import urlparse


def main() -> int:
    manifest_path = os.environ["RELEASE_REFERENCE_MANIFEST_PATH"]
    github_output = os.environ["GITHUB_OUTPUT"]

    with open(manifest_path, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    db_url = manifest.get("db_url", "").strip()
    if not db_url:
        asset_base_url = manifest.get("asset_base_url", "").strip()
        db_file = manifest.get("db_file", "").strip()
        if asset_base_url and db_file:
            db_url = asset_base_url + db_file

    if not db_url:
        print("No db_url could be resolved from release manifest.", file=sys.stderr)
        return 1

    parsed = urlparse(db_url)
    if parsed.scheme != "https":
        print(f"Release db_url must be https, got: {db_url}", file=sys.stderr)
        return 1

    with open(github_output, "a", encoding="utf-8") as out:
        out.write(f"reference_db_url={db_url}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
