from __future__ import annotations

import hashlib
import copy
import io
import json
import re
import sys
import tempfile
import unittest
import wave
from array import array
from collections import Counter
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch


TOOLS_DIR = Path(__file__).resolve().parent
V122_MANIFEST = TOOLS_DIR / "lyria_v122_manifest.json"
V130_MANIFEST = TOOLS_DIR / "lyria_v130_manifest.json"
sys.path.insert(0, str(TOOLS_DIR))

import lyria_pipeline as pipeline  # noqa: E402


class V130PreparationTest(unittest.TestCase):
    def setUp(self) -> None:
        self.manifest = pipeline.load_manifest(V130_MANIFEST)

    def test_fifteen_new_tracks_fill_every_scene_to_five(self) -> None:
        playlists = json.loads((pipeline.ROOT / "data/audio/music_playlists.json").read_text(encoding="utf-8"))
        catalog = json.loads((pipeline.ROOT / "data/audio/audio_event_catalog.json").read_text(encoding="utf-8"))
        paths = {asset["id"]: asset["runtime_path"] for asset in catalog["assets"]}
        events = {event["id"]: paths[event["asset_id"]] for event in catalog["events"]}
        counts = Counter(asset["scene"] for asset in self.manifest["assets"])
        self.assertEqual({"title": 3, "management": 3, "combat": 2, "result": 3, "final_ending": 4}, counts)
        for scene, count in counts.items():
            self.assertEqual(5, len({events[event] for event in playlists["scenes"][scene]["events"]}) + count)
        self.assertEqual(15, len({a["playlist_event"] for a in self.manifest["assets"]}))
        self.assertTrue(all(a["playlist_event"] not in events for a in self.manifest["assets"]))

    def test_one_take_plan_cost_and_instrumental_loop_contract(self) -> None:
        self.assertEqual(1, self.manifest["defaults"]["takes"])
        self.assertAlmostEqual(1.20, pipeline.estimate_cost(self.manifest, self.manifest["assets"], 1))
        for asset in self.manifest["assets"]:
            self.assertEqual("planned", asset["status"])
            self.assertEqual("lyria-3-pro-preview", asset["model"])
            self.assertEqual("music_loop", asset["kind"])
            self.assertTrue(asset["runtime_path"].startswith("assets/audio/bgm/v130/"))
            self.assertEqual((44100, 2), (asset["render"]["sample_rate"], asset["render"]["channels"]))
            self.assertLessEqual(90, asset["render"]["duration_seconds"] - 2)
            self.assertLessEqual(asset["render"]["duration_seconds"], 150)
            self.assertEqual(2.0, asset["render"]["loop_crossfade_seconds"])
            prompt = pipeline.build_prompt(asset)
            self.assertIn("not an imitation of any artist", prompt)
            self.assertIn("No vocals, spoken words, choir syllables", prompt)
            self.assertIn("crossfaded into a seamless loop", prompt)
            self.assertIn(str(asset["bpm"]), prompt)
            self.assertIn(asset["key"], prompt)

    def test_subset_does_not_disable_active_file_or_duplicate_path_checks(self) -> None:
        missing = copy.deepcopy(self.manifest)
        missing["assets"][0]["status"] = "active"
        with patch.object(pipeline.Path, "is_file", return_value=False):
            with self.assertRaisesRegex(pipeline.PipelineError, "current runtime file is missing"):
                pipeline.validate_manifest(missing)
        duplicate = copy.deepcopy(self.manifest)
        duplicate["assets"][1]["runtime_path"] = duplicate["assets"][0]["runtime_path"]
        with self.assertRaisesRegex(pipeline.PipelineError, "Duplicate runtime path"):
            pipeline.validate_manifest(duplicate)

    def test_legacy_full_coverage_still_rejects_missing_entries(self) -> None:
        legacy = pipeline.load_manifest(V122_MANIFEST)
        legacy["assets"] = legacy["assets"][:-1]
        with self.assertRaisesRegex(pipeline.PipelineError, "coverage mismatch"):
            pipeline.validate_manifest(legacy)
        invalid = copy.deepcopy(self.manifest)
        invalid["coverage"] = "anything"
        with self.assertRaisesRegex(pipeline.PipelineError, "Unsupported manifest coverage"):
            pipeline.validate_manifest(invalid)

    def test_v05_manifest_retains_full_coverage_on_its_original_inventory(self) -> None:
        legacy = json.loads((TOOLS_DIR / "lyria_v05_manifest.json").read_text(encoding="utf-8"))
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for asset in legacy["assets"]:
                if asset.get("status", "active") == "active":
                    runtime = root / asset["runtime_path"]
                    runtime.parent.mkdir(parents=True, exist_ok=True)
                    runtime.touch()
            with patch.object(pipeline, "ROOT", root):
                pipeline.validate_manifest(legacy)
                extra = root / "assets/audio/extra.wav"
                extra.touch()
                with self.assertRaisesRegex(pipeline.PipelineError, "coverage mismatch"):
                    pipeline.validate_manifest(legacy)

    def test_offline_commands_never_reach_generation_or_decoder(self) -> None:
        prefix = ["--manifest", str(V130_MANIFEST)]
        with patch.object(pipeline, "generate_assets") as generate, patch.object(pipeline, "decode_audio") as decode:
            for command in (["validate"], ["doctor"], ["plan"], ["generate", "--all"]):
                output = io.StringIO()
                with redirect_stdout(output):
                    self.assertEqual(0, pipeline.main(prefix + command))
                if command[0] in {"plan", "generate"}:
                    self.assertIn("requests=15", output.getvalue())
                    self.assertIn("estimated_cost_usd=1.20", output.getvalue())
            generate.assert_not_called()
            decode.assert_not_called()


class LyriaPipelineTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.manifest = pipeline.load_manifest(V122_MANIFEST)

    def test_manifest_covers_every_current_runtime_wav(self) -> None:
        assets = self.manifest["assets"]
        manifest_paths = {
            asset["runtime_path"]
            for asset in assets
            if asset.get("status", "active") == "active"
        }
        runtime_paths = {
            path.relative_to(pipeline.ROOT).as_posix()
            for path in (pipeline.ROOT / "assets" / "audio").rglob("*.wav")
        }
        self.assertEqual(116, len(assets))
        self.assertEqual(116, sum(asset.get("status", "active") == "active" for asset in assets))
        self.assertEqual(0, sum(asset.get("status", "active") == "planned" for asset in assets))
        self.assertEqual(runtime_paths, manifest_paths)

    def test_default_two_take_plan_matches_documented_cost(self) -> None:
        assets = self.manifest["assets"]
        self.assertEqual(106, sum(asset["model"] == "lyria-3-clip-preview" for asset in assets))
        self.assertEqual(10, sum(asset["model"] == "lyria-3-pro-preview" for asset in assets))
        self.assertAlmostEqual(10.08, pipeline.estimate_cost(self.manifest, assets, 2))

    def test_a2_a3_a5_one_take_source_reel_plan_is_capped_at_56_cents(self) -> None:
        source_reels = [
            "sfx_silky_stitch",
            "combat_attack_blade_01",
            "combat_attack_blunt_shield_01",
            "combat_attack_claw_bite_01",
            "combat_attack_fire_magic_01",
            "combat_impact_body",
            "combat_outcome_down",
            "ui_click",
            "music_title_demon_castle_overture",
            "music_combat_late_siege_pressure",
            "music_final_ending_crown_of_ashes",
        ]
        selected = pipeline.select_assets(self.manifest, source_reels, allow_default_all=False)
        self.assertEqual(8, sum(asset["model"] == "lyria-3-clip-preview" for asset in selected))
        self.assertEqual(3, sum(asset["model"] == "lyria-3-pro-preview" for asset in selected))
        self.assertAlmostEqual(0.56, pipeline.estimate_cost(self.manifest, selected, 1))
        self.assertTrue(all(asset.get("status", "active") == "active" for asset in selected))
        self.assertTrue(all((pipeline.ROOT / asset["runtime_path"]).is_file() for asset in selected))

    def test_prompts_enforce_original_instrumental_or_isolated_audio(self) -> None:
        for asset in self.manifest["assets"]:
            prompt = pipeline.build_prompt(asset)
            self.assertIn("not an imitation of any artist", prompt)
            self.assertIn("vocals", prompt.lower())
            if asset["kind"] not in {"music_loop", "ambience_loop"}:
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

    def test_v122_active_stage01_ambience_has_runtime_after_promotion(self) -> None:
        manifest = pipeline.load_manifest(V122_MANIFEST)
        self.assertEqual(116, len(manifest["assets"]))
        asset = pipeline.select_assets(manifest, ["ambience_stage01_cave"], allow_default_all=False)[0]
        self.assertEqual("active", asset["status"])
        self.assertEqual("ambience_loop", asset["kind"])
        self.assertTrue((pipeline.ROOT / str(asset["runtime_path"])).is_file())
        prompt = pipeline.build_prompt(asset)
        self.assertIn("environmental game ambience loop", prompt)
        self.assertNotIn("source reel, not a song", prompt)
        active_assets = [asset for asset in manifest["assets"] if asset.get("status", "active") == "active"]
        self.assertAlmostEqual(10.08, pipeline.estimate_cost(manifest, active_assets, 2))

    def test_v122_active_stage02_ambience_has_runtime_after_promotion(self) -> None:
        manifest = pipeline.load_manifest(V122_MANIFEST)
        asset = pipeline.select_assets(manifest, ["ambience_stage02_indoor"], allow_default_all=False)[0]
        self.assertEqual("active", asset["status"])
        self.assertEqual("ambience_loop", asset["kind"])
        self.assertEqual("stage_02_indoor", asset["stage_id"])
        self.assertTrue((pipeline.ROOT / str(asset["runtime_path"])).is_file())
        prompt = pipeline.build_prompt(asset)
        self.assertIn("environmental game ambience loop", prompt)
        self.assertIn("wooden creaks", prompt)
        self.assertNotIn("source reel, not a song", prompt)

    def test_v122_active_stage03_ambience_has_runtime_after_promotion(self) -> None:
        manifest = pipeline.load_manifest(V122_MANIFEST)
        asset = pipeline.select_assets(manifest, ["ambience_stage03_keep"], allow_default_all=False)[0]
        self.assertEqual("active", asset["status"])
        self.assertEqual("ambience_loop", asset["kind"])
        self.assertEqual("stage_03_keep", asset["stage_id"])
        self.assertTrue((pipeline.ROOT / str(asset["runtime_path"])).is_file())
        prompt = pipeline.build_prompt(asset)
        self.assertIn("environmental game ambience loop", prompt)
        self.assertIn("stone echoes", prompt)
        self.assertNotIn("source reel, not a song", prompt)

    def test_v122_active_stage04_ambience_has_runtime_after_promotion(self) -> None:
        manifest = pipeline.load_manifest(V122_MANIFEST)
        asset = pipeline.select_assets(manifest, ["ambience_stage04_citadel"], allow_default_all=False)[0]
        self.assertEqual("active", asset["status"])
        self.assertEqual("ambience_loop", asset["kind"])
        self.assertEqual("stage_04_citadel", asset["stage_id"])
        self.assertEqual("assets/audio/ambience/stage04_citadel.wav", asset["runtime_path"])
        self.assertEqual("lyria-3-pro-preview", asset["model"])
        self.assertTrue((pipeline.ROOT / str(asset["runtime_path"])).is_file())
        prompt = pipeline.build_prompt(asset)
        self.assertIn("environmental game ambience loop", prompt)
        self.assertIn("heart-like mechanical low end", prompt)
        self.assertNotIn("source reel, not a song", prompt)
        self.assertEqual(2, int(asset["render"]["channels"]))
        self.assertEqual(44100, int(asset["render"]["sample_rate"]))
        self.assertEqual(120.0, float(asset["render"]["duration_seconds"]))
        self.assertEqual(2.0, float(asset["render"]["loop_crossfade_seconds"]))
        active_assets = [asset for asset in manifest["assets"] if asset.get("status", "active") == "active"]
        self.assertAlmostEqual(10.08, pipeline.estimate_cost(manifest, active_assets, 2))

    def test_v122_active_footstep_cave_rough_01_has_runtime_contract(self) -> None:
        manifest = pipeline.load_manifest(V122_MANIFEST)
        asset = pipeline.select_assets(manifest, ["footstep_cave_rough_01"], allow_default_all=False)[0]
        self.assertEqual("active", asset["status"])
        self.assertEqual("one_shot", asset["kind"])
        self.assertEqual("lyria-3-clip-preview", asset["model"])
        self.assertEqual("assets/audio/sfx/footsteps/footstep_cave_rough_01.wav", asset["runtime_path"])
        self.assertTrue((pipeline.ROOT / str(asset["runtime_path"])).is_file())
        prompt = pipeline.build_prompt(asset)
        self.assertIn("rough cave stone", prompt)
        self.assertIn("source reel, not a song", prompt)
        self.assertIn("no background music", prompt.lower())
        self.assertEqual(1, int(asset["render"]["channels"]))
        self.assertEqual(44100, int(asset["render"]["sample_rate"]))
        self.assertEqual(0.28, float(asset["render"]["duration_seconds"]))
        self.assertEqual(2.0, float(asset["render"]["anchor_seconds"]))
        self.assertEqual(-6.0, float(asset["render"]["peak_dbfs"]))
        self.assertAlmostEqual(0.04, pipeline.estimate_cost(manifest, [asset], 1))

    def test_v122_active_footstep_batch_has_three_surfaces_and_three_variations(self) -> None:
        manifest = pipeline.load_manifest(V122_MANIFEST)
        expected = {
            f"footstep_{surface}_{variation:02d}"
            for surface in ("cave_rough", "castle_stone", "metal_passage")
            for variation in range(1, 4)
        }
        footsteps = {
            str(asset["id"]): asset
            for asset in manifest["assets"]
            if str(asset["id"]).startswith("footstep_")
        }
        self.assertEqual(expected, set(footsteps))
        self.assertAlmostEqual(0.36, pipeline.estimate_cost(manifest, list(footsteps.values()), 1))
        runtime_hashes: set[str] = set()
        key_pattern = re.compile(r"AIza[0-9A-Za-z_-]{30,}")
        for asset_id, asset in footsteps.items():
            expected_surface = asset_id.removeprefix("footstep_").rsplit("_", 1)[0]
            expected_variation = int(asset_id.rsplit("_", 1)[1])
            self.assertEqual("active", asset["status"])
            self.assertEqual("one_shot", asset["kind"])
            self.assertEqual("lyria-3-clip-preview", asset["model"])
            self.assertEqual(expected_surface, asset["surface"])
            self.assertEqual(expected_variation, int(asset["variation"]))
            self.assertIn(str(asset["source_asset"]), expected)
            self.assertEqual(expected_surface, str(asset["source_asset"]).removeprefix("footstep_").rsplit("_", 1)[0])
            self.assertEqual(
                f"assets/audio/sfx/footsteps/{asset_id}.wav",
                asset["runtime_path"],
            )
            runtime = pipeline.ROOT / str(asset["runtime_path"])
            self.assertTrue(runtime.is_file())
            with wave.open(str(runtime), "rb") as wav:
                self.assertEqual(1, wav.getnchannels(), asset_id)
                self.assertEqual(44100, wav.getframerate(), asset_id)
                self.assertGreater(wav.getnframes(), 0, asset_id)
            runtime_hashes.add(hashlib.sha256(runtime.read_bytes()).hexdigest())

            source_dir = pipeline.ROOT / f"assets/source/audio/lyria/v1.2.2/{asset_id}"
            source = source_dir / "source.mp3"
            record_path = source_dir / "SOURCE.md"
            generation_path = source_dir / "generation.json"
            self.assertTrue(source.is_file(), asset_id)
            self.assertTrue(record_path.is_file(), asset_id)
            self.assertTrue(generation_path.is_file(), asset_id)
            generation = json.loads(generation_path.read_text(encoding="utf-8"))
            self.assertEqual(asset_id, generation["derived_asset_id"])
            self.assertEqual(asset["source_asset"], generation["source_asset_id"])
            self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(), generation["source_sha256"])
            record = record_path.read_text(encoding="utf-8")
            self.assertIn(f"Source reel asset: `{asset['source_asset']}`", record)
            self.assertIn(f"Source reel anchor seconds: `{asset['render']['anchor_seconds']}`", record)
            self.assertIsNone(key_pattern.search(record), asset_id)
            self.assertIsNone(key_pattern.search(generation_path.read_text(encoding="utf-8")), asset_id)
            self.assertEqual(1, int(asset["render"]["channels"]))
            self.assertEqual(44100, int(asset["render"]["sample_rate"]))
            self.assertGreaterEqual(float(asset["render"]["duration_seconds"]), 0.20)
            self.assertLessEqual(float(asset["render"]["duration_seconds"]), 0.35)
            expected_anchor = {1: 2.0, 2: 7.0, 3: 12.0}[expected_variation]
            if expected_surface == "castle_stone" and expected_variation > 1:
                expected_anchor += 0.5
            self.assertEqual(expected_anchor, float(asset["render"]["anchor_seconds"]))
            self.assertEqual(-6.0, float(asset["render"]["peak_dbfs"]))
            prompt = pipeline.build_prompt(asset)
            self.assertIn("source reel, not a song", prompt)
            self.assertIn("No background music", prompt)
        self.assertEqual(9, len(runtime_hashes))

    def test_all_approved_music_states_have_distinct_tracks(self) -> None:
        music_assets = {
            str(asset["id"]): str(asset["runtime_path"])
            for asset in self.manifest["assets"]
            if asset["kind"] == "music_loop" and asset.get("status", "active") == "active"
        }
        self.assertEqual(
            {
                "management_castle_bustle": "assets/audio/bgm/management_castle_bustle.wav",
                "combat_dungeon_pressure": "assets/audio/bgm/combat_dungeon_pressure.wav",
                "combat_boss_council": "assets/audio/bgm/combat_boss_council.wav",
                "music_title_demon_castle_overture": "assets/audio/bgm/title_demon_castle_overture.wav",
                "music_combat_late_siege_pressure": "assets/audio/bgm/combat_late_siege_pressure.wav",
                "music_final_ending_crown_of_ashes": "assets/audio/bgm/final_ending_crown_of_ashes.wav",
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
            if asset.get("status", "active") != "active":
                continue
            if not asset_id.startswith("skill_") and asset["kind"] != "music_loop":
                continue
            runtime = pipeline.ROOT / str(asset["runtime_path"])
            with wave.open(str(runtime), "rb") as wav:
                self.assertEqual(44100, wav.getframerate(), asset_id)
                self.assertEqual(int(asset["render"]["channels"]), wav.getnchannels(), asset_id)
                self.assertGreater(wav.getnframes(), 0, asset_id)
                if asset["kind"] == "music_loop":
                    self.assertGreaterEqual(wav.getnframes() / wav.getframerate(), 96.0, asset_id)
            digest = hashlib.sha256(runtime.read_bytes()).hexdigest()
            if asset_id.startswith("skill_"):
                skill_hashes.add(digest)
            else:
                music_hashes.add(digest)
        self.assertEqual(24, len(skill_hashes))
        self.assertEqual(6, len(music_hashes))

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

    def test_derived_take_reuses_one_paid_source_reel_with_lineage(self) -> None:
        source_asset = pipeline.select_assets(
            self.manifest, ["ui_click"], allow_default_all=False
        )[0]
        derived_asset = pipeline.select_assets(
            self.manifest, ["ui_select"], allow_default_all=False
        )[0]
        work_root = pipeline.ROOT / self.manifest["defaults"]["work_root"]
        work_root.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=work_root) as directory:
            run_dir = Path(directory)
            source_take = run_dir / source_asset["id"] / "take-01"
            source_take.mkdir(parents=True)
            (source_take / "source.mp3").write_bytes(b"shared-source-reel")
            pipeline.write_json(
                source_take / "generation.json",
                {
                    "asset_id": source_asset["id"],
                    "model": source_asset["model"],
                    "target_version": "v1.2.2",
                },
            )

            pipeline.materialize_derived_takes(
                self.manifest, run_dir, derived_asset, take=1
            )

            derived_take = run_dir / derived_asset["id"] / "take-01"
            self.assertEqual(b"shared-source-reel", (derived_take / "source.mp3").read_bytes())
            generation = json.loads(
                (derived_take / "generation.json").read_text(encoding="utf-8")
            )
            self.assertEqual(derived_asset["id"], generation["derived_asset_id"])
            self.assertEqual(source_asset["id"], generation["source_asset_id"])
            self.assertEqual(run_dir.relative_to(pipeline.ROOT).as_posix(), generation["source_run"])

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

    def test_source_record_preserves_derived_clip_lineage(self) -> None:
        asset = pipeline.select_assets(
            pipeline.load_manifest(V122_MANIFEST),
            ["footstep_cave_rough_03"],
            allow_default_all=False,
        )[0]
        generation = {
            "asset_id": "footstep_cave_rough_01",
            "source_asset_id": "footstep_cave_rough_01",
            "source_run": "tmp/lyria_audio_v122/source-run",
            "model": asset["model"],
            "generated_at_utc": "2026-08-05T00:00:00+00:00",
            "target_version": "v1.2.2",
            "interaction_id": "",
            "source_sha256": "source-hash",
            "prompt_sha256": "prompt-hash",
        }
        record = pipeline.source_record(asset, generation, "source.mp3", asset["runtime_path"])
        self.assertIn("Source reel asset: `footstep_cave_rough_01`", record)
        self.assertIn("Source reel run: `tmp/lyria_audio_v122/source-run`", record)
        self.assertIn("Source reel anchor seconds: `12.0`", record)

    def test_tools_do_not_contain_a_google_api_key_literal(self) -> None:
        key_pattern = re.compile(r"AIza[0-9A-Za-z_-]{30,}")
        for path in TOOLS_DIR.glob("*"):
            if path.is_file() and path.suffix in {".py", ".ps1", ".json", ".txt"}:
                self.assertIsNone(key_pattern.search(path.read_text(encoding="utf-8")), path)


if __name__ == "__main__":
    unittest.main()
