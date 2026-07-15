from __future__ import annotations

import re
import sys
import tempfile
import unittest
from array import array
from pathlib import Path


TOOLS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS_DIR))

import lyria_pipeline as pipeline  # noqa: E402


class LyriaPipelineTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.manifest = pipeline.load_manifest()

    def test_manifest_covers_every_current_runtime_wav(self) -> None:
        assets = self.manifest["assets"]
        manifest_paths = {asset["runtime_path"] for asset in assets}
        runtime_paths = {
            path.relative_to(pipeline.ROOT).as_posix()
            for path in (pipeline.ROOT / "assets" / "audio").rglob("*.wav")
        }
        self.assertEqual(50, len(assets))
        self.assertEqual(runtime_paths, manifest_paths)

    def test_default_two_take_plan_matches_documented_cost(self) -> None:
        assets = self.manifest["assets"]
        self.assertEqual(49, sum(asset["model"] == "lyria-3-clip-preview" for asset in assets))
        self.assertEqual(1, sum(asset["model"] == "lyria-3-pro-preview" for asset in assets))
        self.assertAlmostEqual(4.08, pipeline.estimate_cost(self.manifest, assets, 2))

    def test_prompts_enforce_original_instrumental_or_isolated_audio(self) -> None:
        for asset in self.manifest["assets"]:
            prompt = pipeline.build_prompt(asset)
            self.assertIn("not an imitation of any artist", prompt)
            self.assertIn("vocals", prompt.lower())
            if asset["kind"] != "music_loop":
                self.assertIn("source reel, not a song", prompt)
                self.assertIn("0:02", prompt)

    def test_one_shot_extraction_finds_transient_near_anchor(self) -> None:
        sample_rate = 1000
        samples = array("h", [0] * 4000)
        samples[2050:2060] = array("h", [12000] * 10)
        cue = pipeline.extract_one_shot(samples, 1, sample_rate, 2.0, 0.14)
        self.assertEqual(140, len(cue))
        self.assertGreater(max(cue), 10000)
        self.assertLess(cue.index(max(cue)), 10)

    def test_loop_crossfade_shortens_by_overlap(self) -> None:
        samples = array("h", range(20))
        result = pipeline.loop_crossfade(samples, channels=1, crossfade_frames=4)
        self.assertEqual(16, len(result))

    def test_promote_requires_explicit_confirmation_before_file_checks(self) -> None:
        asset = self.manifest["assets"][0]
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaisesRegex(pipeline.PipelineError, "--confirm"):
                pipeline.promote_asset(
                    self.manifest,
                    Path(directory),
                    asset,
                    1,
                    confirm=False,
                    force=False,
                )

    def test_tools_do_not_contain_a_google_api_key_literal(self) -> None:
        key_pattern = re.compile(r"AIza[0-9A-Za-z_-]{30,}")
        for path in TOOLS_DIR.glob("*"):
            if path.is_file() and path.suffix in {".py", ".ps1", ".json", ".txt"}:
                self.assertIsNone(key_pattern.search(path.read_text(encoding="utf-8")), path)


if __name__ == "__main__":
    unittest.main()
