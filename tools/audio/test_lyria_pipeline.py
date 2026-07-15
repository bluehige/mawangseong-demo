from __future__ import annotations

import hashlib
import json
import re
import sys
import tempfile
import unittest
import wave
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
        self.assertEqual(76, len(assets))
        self.assertEqual(runtime_paths, manifest_paths)

    def test_default_two_take_plan_matches_documented_cost(self) -> None:
        assets = self.manifest["assets"]
        self.assertEqual(73, sum(asset["model"] == "lyria-3-clip-preview" for asset in assets))
        self.assertEqual(3, sum(asset["model"] == "lyria-3-pro-preview" for asset in assets))
        self.assertAlmostEqual(6.32, pipeline.estimate_cost(self.manifest, assets, 2))

    def test_prompts_enforce_original_instrumental_or_isolated_audio(self) -> None:
        for asset in self.manifest["assets"]:
            prompt = pipeline.build_prompt(asset)
            self.assertIn("not an imitation of any artist", prompt)
            self.assertIn("vocals", prompt.lower())
            if asset["kind"] != "music_loop":
                self.assertIn("source reel, not a song", prompt)
                self.assertIn("0:02", prompt)
                self.assertIn("three clearly audible layers", prompt)

    def test_every_direct_combat_skill_has_a_unique_manifest_asset_and_runtime_mapping(self) -> None:
        active_skills: set[str] = set()
        for relative_path in ("data/monsters.json", "data/regular_version/update3/monsters.json"):
            monsters = json.loads((pipeline.ROOT / relative_path).read_text(encoding="utf-8"))
            for monster in monsters.values():
                active_skills.update(str(skill_id) for skill_id in monster.get("skill_slots", []) if skill_id)

        manifested = {
            str(asset["id"]).removeprefix("skill_")
            for asset in self.manifest["assets"]
            if str(asset["id"]).startswith("skill_")
        }
        self.assertEqual(active_skills, manifested)
        self.assertEqual(24, len(manifested))

        controller = (pipeline.ROOT / "scripts/game/CombatSceneController.gd").read_text(encoding="utf-8")
        for skill_id in active_skills:
            mapping = f'"{skill_id}": preload("res://assets/audio/sfx/skills/{skill_id}.wav")'
            self.assertIn(mapping, controller)
        self.assertIn("_play_skill_sfx(skill_id)", controller)

    def test_management_normal_combat_and_boss_music_have_distinct_tracks(self) -> None:
        music_assets = {
            str(asset["id"]): str(asset["runtime_path"])
            for asset in self.manifest["assets"]
            if asset["kind"] == "music_loop"
        }
        self.assertEqual(
            {
                "management_castle_bustle": "assets/audio/bgm/management_castle_bustle.wav",
                "combat_dungeon_pressure": "assets/audio/bgm/combat_dungeon_pressure.wav",
                "combat_boss_council": "assets/audio/bgm/combat_boss_council.wav",
            },
            music_assets,
        )
        game_root = (pipeline.ROOT / "scripts/game/GameRoot.gd").read_text(encoding="utf-8")
        self.assertIn("COMBAT_BOSS_MUSIC", game_root)
        self.assertIn("MANAGEMENT_MUSIC_SCREENS", game_root)
        self.assertIn("_combat_music_has_boss()", game_root)

    def test_promoted_skill_and_music_audio_has_expected_format_and_unique_files(self) -> None:
        skill_hashes: set[str] = set()
        music_hashes: set[str] = set()
        for asset in self.manifest["assets"]:
            asset_id = str(asset["id"])
            if not asset_id.startswith("skill_") and asset["kind"] != "music_loop":
                continue
            runtime = pipeline.ROOT / str(asset["runtime_path"])
            with wave.open(str(runtime), "rb") as wav:
                self.assertEqual(44100, wav.getframerate(), asset_id)
                self.assertEqual(int(asset["render"]["channels"]), wav.getnchannels(), asset_id)
                self.assertGreater(wav.getnframes(), 0, asset_id)
                if asset["kind"] == "music_loop":
                    self.assertGreater(wav.getnframes() / wav.getframerate(), 110.0, asset_id)
            digest = hashlib.sha256(runtime.read_bytes()).hexdigest()
            if asset_id.startswith("skill_"):
                skill_hashes.add(digest)
            else:
                music_hashes.add(digest)
        self.assertEqual(24, len(skill_hashes))
        self.assertEqual(3, len(music_hashes))

    def test_promoted_source_records_are_complete_and_key_free(self) -> None:
        source_root = pipeline.ROOT / "assets/source/audio/lyria/v0.5"
        source_dirs = sorted(path for path in source_root.iterdir() if path.is_dir())
        self.assertEqual(28, len(source_dirs))
        key_pattern = re.compile(r"AIza[0-9A-Za-z_-]{30,}")
        for source_dir in source_dirs:
            source = source_dir / "source.mp3"
            record_path = source_dir / "SOURCE.md"
            generation_path = source_dir / "generation.json"
            self.assertTrue(source.is_file(), source_dir.name)
            self.assertTrue(record_path.is_file(), source_dir.name)
            self.assertTrue(generation_path.is_file(), source_dir.name)
            generation = json.loads(generation_path.read_text(encoding="utf-8"))
            self.assertEqual(source_dir.name, generation["asset_id"])
            self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(), generation["source_sha256"])
            record = record_path.read_text(encoding="utf-8")
            self.assertNotIn("Interaction ID: ``", record)
            self.assertIsNone(key_pattern.search(record), record_path)
            self.assertIsNone(key_pattern.search(generation_path.read_text(encoding="utf-8")), generation_path)

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

    def test_source_record_marks_missing_preview_interaction_id_explicitly(self) -> None:
        asset = self.manifest["assets"][0]
        generation = {
            "model": asset["model"],
            "generated_at_utc": "2026-07-15T00:00:00+00:00",
            "target_version": "v0.5",
            "interaction_id": "",
            "source_sha256": "source-hash",
            "prompt_sha256": "prompt-hash",
        }
        record = pipeline.source_record(asset, generation, "source.mp3", asset["runtime_path"])
        self.assertIn("not returned by the Lyria preview response", record)
        self.assertNotIn("Interaction ID: ``", record)

    def test_tools_do_not_contain_a_google_api_key_literal(self) -> None:
        key_pattern = re.compile(r"AIza[0-9A-Za-z_-]{30,}")
        for path in TOOLS_DIR.glob("*"):
            if path.is_file() and path.suffix in {".py", ".ps1", ".json", ".txt"}:
                self.assertIsNone(key_pattern.search(path.read_text(encoding="utf-8")), path)


if __name__ == "__main__":
    unittest.main()
