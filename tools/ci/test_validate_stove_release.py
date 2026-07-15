from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools.release import validate_stove_release as validator


class ValidateStoveReleaseTests(unittest.TestCase):
    def test_current_repository_owned_setup_is_complete(self) -> None:
        errors, pending = validator.validate()
        self.assertEqual(errors, [])
        self.assertIn("gate:audio_finalized", pending)
        self.assertTrue(any(item.startswith("placeholder:") for item in pending))

    def test_default_mode_allows_external_pending_gates(self) -> None:
        self.assertEqual(validator.exit_code([], ["gate:audio_finalized"], strict=False), 0)

    def test_strict_mode_blocks_external_pending_gates(self) -> None:
        self.assertEqual(validator.exit_code([], ["gate:audio_finalized"], strict=True), 1)

    def test_missing_config_is_a_setup_error(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            errors, pending = validator.validate(root, root / "missing.json")
        self.assertEqual(pending, [])
        self.assertEqual(len(errors), 1)
        self.assertIn("missing config", errors[0])


if __name__ == "__main__":
    unittest.main()
