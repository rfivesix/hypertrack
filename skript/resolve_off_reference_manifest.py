#!/usr/bin/env python3
import json
import os
import sys
from urllib.parse import urlparse

EXPECTED_SOURCE_ID = "off_food_catalog"


def main() -> int:
    manifest_path = os.environ["RELEASE_REFERENCE_MANIFEST_PATH"]
    github_output = os.environ["GITHUB_OUTPUT"]
    expected_country = os.environ.get("COUNTRY_CODE", "").strip().lower()

    with open(manifest_path, "r", encoding="utf-8") as file:
        manifest = json.load(file)

    source_id = str(manifest.get("source_id", "")).strip()
    if source_id and source_id != EXPECTED_SOURCE_ID:
        print(
            f"Unexpected source_id in reference manifest: {source_id}",
            file=sys.stderr,
        )
        return 1

    manifest_country = str(manifest.get("country_code", "")).strip().lower()
    if expected_country and manifest_country and manifest_country != expected_country:
        print(
            (
                "Reference manifest country mismatch: "
                f"expected={expected_country} actual={manifest_country}"
            ),
            file=sys.stderr,
        )
        return 1

    db_url = str(manifest.get("db_url", "")).strip()
    if not db_url:
        asset_base_url = str(manifest.get("asset_base_url", "")).strip()
        db_file = str(manifest.get("db_file", "")).strip()
        if asset_base_url and db_file:
            db_url = asset_base_url + db_file

    if not db_url:
        print("No db_url could be resolved from reference manifest.", file=sys.stderr)
        return 1

    parsed = urlparse(db_url)
    if parsed.scheme != "https" or not parsed.netloc:
        print(f"Reference db_url must be https: {db_url}", file=sys.stderr)
        return 1

    with open(github_output, "a", encoding="utf-8") as output:
        output.write(f"reference_db_url={db_url}\n")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
