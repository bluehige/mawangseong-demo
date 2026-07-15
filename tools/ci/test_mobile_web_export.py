from __future__ import annotations

import importlib.util
from pathlib import Path
import tempfile
import unittest


PROJECT_ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = PROJECT_ROOT / "tools" / "mobile_web_export.py"
SPEC = importlib.util.spec_from_file_location("mobile_web_export", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
mobile_export = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(mobile_export)


class MobileWebExportTest(unittest.TestCase):
    def test_current_mobile_illustration_scope_is_fixed(self) -> None:
        imports = mobile_export.discover_mobile_imports(PROJECT_ROOT)
        self.assertEqual(len(imports), mobile_export.EXPECTED_IMPORT_COUNT)
        paths = [path.relative_to(PROJECT_ROOT).as_posix() for path in imports]
        self.assertFalse(any("assets/fonts/" in path for path in paths))
        self.assertFalse(any("assets/sprites/enemies/" in path for path in paths))
        self.assertFalse(any("assets/sprites/monsters/" in path for path in paths))

    def test_only_mobile_illustration_import_is_rewritten(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            portrait = root / "assets/sprites/portraits/test.png.import"
            enemy = root / "assets/sprites/enemies/test.png.import"
            portrait.parent.mkdir(parents=True)
            enemy.parent.mkdir(parents=True)
            original = "compress/mode=0\ncompress/lossy_quality=0.7\n"
            portrait.write_text(original, encoding="utf-8")
            enemy.write_text(original, encoding="utf-8")

            changed = mobile_export.apply_mobile_import_overrides(root)

            self.assertEqual(changed, 1)
            self.assertIn("compress/mode=1", portrait.read_text(encoding="utf-8"))
            self.assertIn(
                "compress/lossy_quality=0.9",
                portrait.read_text(encoding="utf-8"),
            )
            self.assertEqual(enemy.read_text(encoding="utf-8"), original)

    def test_replace_directory_rejects_outside_path(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            allowed = root / "tmp"
            allowed.mkdir()
            with self.assertRaises(ValueError):
                mobile_export._replace_directory(root / "elsewhere", allowed)


if __name__ == "__main__":
    unittest.main()
