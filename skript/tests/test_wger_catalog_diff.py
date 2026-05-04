import argparse
import importlib.util
import sqlite3
import tempfile
import unittest
from pathlib import Path
from typing import Any, Dict, Iterable, Optional, Set

MODULE_PATH = (
    Path(__file__).resolve().parents[1] / "wger_catalog_diff.py"
)
SPEC = importlib.util.spec_from_file_location("wger_catalog_diff", MODULE_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(MODULE)


def _create_catalog(
    path: Path,
    ids: Iterable[str],
    overrides: Optional[Dict[str, Dict[str, Any]]] = None,
) -> None:
    overrides = overrides or {}
    conn = sqlite3.connect(path)
    try:
        conn.execute("CREATE TABLE metadata (key TEXT, value TEXT)")
        conn.execute(
            """
            CREATE TABLE exercises (
                id TEXT PRIMARY KEY,
                name_de TEXT,
                name_en TEXT,
                description_de TEXT,
                description_en TEXT,
                category_name TEXT,
                muscles_primary TEXT,
                muscles_secondary TEXT
            )
            """
        )
        conn.execute(
            "INSERT INTO metadata(key, value) VALUES ('version', 'test-version')"
        )
        for raw_id in ids:
            exercise_id = str(raw_id)
            override = overrides.get(exercise_id, {})
            conn.execute(
                """
                INSERT INTO exercises(
                    id,
                    name_de,
                    name_en,
                    description_de,
                    description_en,
                    category_name,
                    muscles_primary,
                    muscles_secondary
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    exercise_id,
                    override.get("name_de", f"DE {exercise_id}"),
                    override.get("name_en", f"EN {exercise_id}"),
                    override.get("description_de", "desc de"),
                    override.get("description_en", "desc en"),
                    override.get("category_name", "cat"),
                    override.get("muscles_primary", "[]"),
                    override.get("muscles_secondary", "[]"),
                ),
            )
        conn.commit()
    finally:
        conn.close()


class WgerCatalogDiffThresholdTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        base = Path(self.tmp.name)
        self.old_db = base / "old.db"
        self.new_db = base / "new.db"

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def _args(self) -> argparse.Namespace:
        return argparse.Namespace(
            examples=10,
            removed_severe_threshold=25,
            row_drop_warn_percent=1000.0,
            row_drop_severe_percent=1000.0,
            category_regression_threshold=1,
            muscle_regression_threshold=1,
            de_fallback_shift_threshold=10,
            fail_on_removed_threshold=30,
        )

    def _report(
        self,
        old_ids: Set[str],
        new_ids: Set[str],
        *,
        new_overrides: Optional[Dict[str, Dict[str, Any]]] = None,
        fail_on_removed_threshold: Optional[int] = None,
    ):
        _create_catalog(self.old_db, old_ids)
        _create_catalog(self.new_db, new_ids, overrides=new_overrides)

        old_catalog = MODULE.load_catalog(str(self.old_db))
        new_catalog = MODULE.load_catalog(str(self.new_db))

        args = self._args()
        if fail_on_removed_threshold is not None:
            args.fail_on_removed_threshold = fail_on_removed_threshold

        return MODULE.compare_catalogs(
            old_catalog,
            new_catalog,
            args,
        )

    def test_removed_count_below_threshold_does_not_fail(self):
        old_ids = {str(i) for i in range(1, 35)}
        new_ids = {str(i) for i in range(1, 10)}
        report = self._report(
            old_ids,
            new_ids,
            fail_on_removed_threshold=30,
        )
        should_fail, reasons = MODULE.should_fail(
            report,
            argparse.Namespace(fail_on_removed_threshold=30),
        )
        self.assertEqual(25, report["summary"]["removed_count"])
        self.assertFalse(report["summary"]["removed_threshold_exceeded"])
        self.assertFalse(should_fail)
        self.assertEqual([], reasons)

    def test_removed_count_above_removed_severe_warning_but_below_fail_threshold_does_not_fail(self):
        old_ids = {str(i) for i in range(1, 37)}
        new_ids = {str(i) for i in range(1, 11)}
        report = self._report(
            old_ids,
            new_ids,
            fail_on_removed_threshold=30,
        )
        should_fail, reasons = MODULE.should_fail(
            report,
            argparse.Namespace(fail_on_removed_threshold=30),
        )
        self.assertEqual(26, report["summary"]["removed_count"])
        self.assertFalse(report["summary"]["removed_threshold_exceeded"])
        self.assertFalse(should_fail)
        self.assertEqual([], reasons)

    def test_removed_count_equal_threshold_does_not_fail(self):
        old_ids = {str(i) for i in range(1, 41)}
        new_ids = {str(i) for i in range(1, 11)}
        report = self._report(
            old_ids,
            new_ids,
            fail_on_removed_threshold=30,
        )
        should_fail, reasons = MODULE.should_fail(
            report,
            argparse.Namespace(fail_on_removed_threshold=30),
        )
        self.assertEqual(30, report["summary"]["removed_count"])
        self.assertFalse(report["summary"]["removed_threshold_exceeded"])
        self.assertFalse(should_fail)
        self.assertEqual([], reasons)

    def test_removed_count_above_threshold_fails(self):
        old_ids = {str(i) for i in range(1, 42)}
        new_ids = {str(i) for i in range(1, 10)}
        report = self._report(
            old_ids,
            new_ids,
            fail_on_removed_threshold=30,
        )
        should_fail, reasons = MODULE.should_fail(
            report,
            argparse.Namespace(fail_on_removed_threshold=30),
        )
        self.assertTrue(should_fail)
        self.assertTrue(report["summary"]["removed_threshold_exceeded"])
        self.assertTrue(any("removed_count=" in r for r in reasons))

    def test_severe_regressions_fail_even_when_removed_below_threshold(self):
        report = self._report(
            {"1", "2", "3", "4"},
            {"1", "2", "3"},
            new_overrides={
                "1": {"name_de": ""},
                "2": {"category_name": ""},
                "3": {"muscles_primary": ""},
            },
            fail_on_removed_threshold=30,
        )
        should_fail, reasons = MODULE.should_fail(
            report,
            argparse.Namespace(fail_on_removed_threshold=30),
        )
        self.assertEqual(1, report["summary"]["removed_count"])
        self.assertFalse(report["summary"]["removed_threshold_exceeded"])
        self.assertTrue(should_fail)
        self.assertTrue(
            any(
                "name regression detected" in reason
                or "severe warning present" in reason
                for reason in reasons
            )
        )


if __name__ == "__main__":
    unittest.main()
