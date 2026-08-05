"""Contract checks for the v1.2.2 audio asset/event catalog."""

from __future__ import annotations

import json
import re
import unittest
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CATALOG_PATH = ROOT / "data" / "audio" / "audio_event_catalog.json"
MANIFEST_PATH = ROOT / "tools" / "audio" / "lyria_v122_manifest.json"
ID_RE = re.compile(r"^[a-z0-9_.]+$")


class AudioEventCatalogContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
        cls.manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        cls.assets = cls.catalog["assets"]
        cls.events = cls.catalog["events"]
        cls.asset_by_id = {asset["id"]: asset for asset in cls.assets}
        cls.event_by_id = {event["id"]: event for event in cls.events}

    def test_catalog_is_manifest_backed_and_covers_all_runtime_wav(self) -> None:
        self.assertEqual(self.catalog["target_version"], "v1.2.2")
        self.assertEqual(self.catalog["manifest"], "tools/audio/lyria_v122_manifest.json")
        manifest_assets = [
            asset
            for asset in self.manifest["assets"]
            if asset.get("status", "active") == "active"
        ]
        planned_assets = [
            asset for asset in self.manifest["assets"] if asset.get("status") == "planned"
        ]
        self.assertEqual([asset["id"] for asset in manifest_assets], [asset["id"] for asset in self.assets])
        self.assertEqual(
            {asset["runtime_path"] for asset in manifest_assets},
            {asset["runtime_path"] for asset in self.assets},
        )
        self.assertEqual([], planned_assets)
        self.assertEqual(len(self.assets), len(self.asset_by_id))
        for asset in self.assets:
            self.assertTrue((ROOT / asset["runtime_path"]).is_file(), asset["id"])
            self.assertNotIn("res://", asset["runtime_path"])

    def test_asset_classification_summary_matches_catalog(self) -> None:
        summary = self.catalog["summary"]
        connection_counts = Counter(asset["runtime_connection"] for asset in self.assets)
        provenance_counts = Counter(asset["provenance"] for asset in self.assets)
        bus_counts = Counter(asset["bus"] for asset in self.assets)
        self.assertLessEqual(
            set(connection_counts), {"actual_runtime", "data_only", "unconnected"}
        )
        self.assertEqual(summary["asset_count"], len(self.assets))
        self.assertEqual(summary["event_count"], len(self.events))
        self.assertEqual(
            summary["actual_runtime_asset_count"],
            connection_counts["actual_runtime"],
        )
        self.assertEqual(summary["data_only_asset_count"], connection_counts["data_only"])
        self.assertEqual(summary["unconnected_asset_count"], connection_counts["unconnected"])
        self.assertEqual(summary["provenance_count"], dict(provenance_counts))
        self.assertEqual(summary["bus_count"], dict(bus_counts))

    def test_current_connection_snapshot_is_explicit(self) -> None:
        connection_counts = Counter(asset["runtime_connection"] for asset in self.assets)
        self.assertEqual(connection_counts["actual_runtime"], 106)
        self.assertEqual(connection_counts["data_only"], 0)
        self.assertEqual(connection_counts["unconnected"], 10)
        self.assertEqual(len(self.events), 108)
        self.assertEqual(self.catalog["summary"]["event_count"], 108)

    def test_stage02_ambience_has_runtime_event_after_connection(self) -> None:
        asset = self.asset_by_id["ambience_stage02_indoor"]
        self.assertEqual(asset["runtime_path"], "assets/audio/ambience/stage02_indoor.wav")
        self.assertEqual(asset["kind"], "ambience_loop")
        self.assertEqual(asset["bus"], "SFX")
        self.assertEqual(asset["provenance"], "lyria")
        self.assertEqual(asset["runtime_connection"], "actual_runtime")
        self.assertEqual(asset["events"], ["ambience.stage02.indoor"])
        self.assertEqual(
            asset["source_record"],
            "assets/source/audio/lyria/v1.2.2/ambience_stage02_indoor/SOURCE.md",
        )
        event = self.event_by_id["ambience.stage02.indoor"]
        self.assertEqual(event["asset_id"], "ambience_stage02_indoor")
        self.assertEqual(event["owner"], "scripts/game/GameRoot.gd")
        self.assertEqual(event["locator"], "_update_stage_ambience")
        self.assertEqual(event["runtime_status"], "connected")

    def test_stage03_ambience_has_runtime_event_after_connection(self) -> None:
        asset = self.asset_by_id["ambience_stage03_keep"]
        self.assertEqual(asset["runtime_path"], "assets/audio/ambience/stage03_keep.wav")
        self.assertEqual(asset["kind"], "ambience_loop")
        self.assertEqual(asset["bus"], "SFX")
        self.assertEqual(asset["provenance"], "lyria")
        self.assertEqual(asset["runtime_connection"], "actual_runtime")
        self.assertEqual(asset["events"], ["ambience.stage03.keep"])
        self.assertEqual(
            asset["source_record"],
            "assets/source/audio/lyria/v1.2.2/ambience_stage03_keep/SOURCE.md",
        )
        self.assertEqual(asset["source_record_status"], "present")
        event = self.event_by_id["ambience.stage03.keep"]
        self.assertEqual(event["asset_id"], "ambience_stage03_keep")
        self.assertEqual(event["owner"], "scripts/game/GameRoot.gd")
        self.assertEqual(event["locator"], "_update_stage_ambience")
        self.assertEqual(event["runtime_status"], "connected")

    def test_stage04_ambience_has_runtime_event_after_connection(self) -> None:
        asset = self.asset_by_id["ambience_stage04_citadel"]
        self.assertEqual(asset["runtime_path"], "assets/audio/ambience/stage04_citadel.wav")
        self.assertEqual(asset["kind"], "ambience_loop")
        self.assertEqual(asset["bus"], "SFX")
        self.assertEqual(asset["provenance"], "lyria")
        self.assertEqual(asset["runtime_connection"], "actual_runtime")
        self.assertEqual(asset["events"], ["ambience.stage04.citadel"])
        self.assertEqual(
            asset["source_record"],
            "assets/source/audio/lyria/v1.2.2/ambience_stage04_citadel/SOURCE.md",
        )
        self.assertEqual(asset["source_record_status"], "present")
        event = self.event_by_id["ambience.stage04.citadel"]
        self.assertEqual(event["asset_id"], "ambience_stage04_citadel")
        self.assertEqual(event["owner"], "scripts/game/GameRoot.gd")
        self.assertEqual(event["locator"], "_update_stage_ambience")
        self.assertEqual(event["runtime_status"], "connected")

    def test_provenance_review_and_source_contract(self) -> None:
        for asset in self.assets:
            self.assertIn(asset["provenance"], {"lyria", "procedural"})
            self.assertIn(asset["review_status"], {"pending", "approved"})
            expected_status = "present" if asset["provenance"] == "lyria" else "shared"
            self.assertEqual(asset["source_record_status"], expected_status, asset["id"])
            self.assertIsNotNone(asset["source_record"])
            self.assertTrue((ROOT / asset["source_record"]).is_file(), asset["id"])

    def test_events_are_unique_bidirectional_and_have_real_owner_locators(self) -> None:
        self.assertEqual(len(self.events), len(self.event_by_id))
        events_by_asset: dict[str, list[str]] = {asset_id: [] for asset_id in self.asset_by_id}
        for event in self.events:
            self.assertRegex(event["id"], ID_RE)
            self.assertIn(event["asset_id"], self.asset_by_id)
            self.assertEqual(event["runtime_status"], "connected")
            self.assertIn(event["bus"], {"Music", "SFX"})
            owner = ROOT / event["owner"]
            self.assertTrue(owner.is_file(), event["owner"])
            self.assertIn(event["locator"], owner.read_text(encoding="utf-8"), event["id"])
            events_by_asset[event["asset_id"]].append(event["id"])
        for asset in self.assets:
            self.assertEqual(sorted(asset["events"]), sorted(events_by_asset[asset["id"]]))
            if asset["runtime_connection"] == "actual_runtime":
                self.assertTrue(asset["events"], asset["id"])
            else:
                self.assertFalse(asset["events"], asset["id"])

    def test_runtime_assets_use_export_safe_resource_lookup(self) -> None:
        api_source = (ROOT / "scripts/audio/AudioCatalogApi.gd").read_text(encoding="utf-8")
        self.assertIn("ResourceLoader.exists(runtime_path)", api_source)
        self.assertNotIn("FileAccess.file_exists(runtime_path)", api_source)

    def test_missing_events_are_listed_without_synthetic_fallbacks(self) -> None:
        unresolved = self.catalog["unresolved_assets"]
        unresolved_by_id = {item["asset_id"]: item for item in unresolved}
        expected_ids = {
            asset["id"] for asset in self.assets if asset["runtime_connection"] != "actual_runtime"
        }
        self.assertEqual(set(unresolved_by_id), expected_ids)
        self.assertEqual(len(unresolved), len(expected_ids))
        for asset_id, item in unresolved_by_id.items():
            self.assertEqual(item["status"], self.asset_by_id[asset_id]["runtime_connection"])
            self.assertTrue(item["reason"])

    def test_expected_direct_skill_and_update3_event_groups_exist(self) -> None:
        skill_assets = [asset for asset in self.assets if asset["id"].startswith("skill_")]
        self.assertTrue(skill_assets)
        self.assertEqual(
            {asset["events"][0] for asset in skill_assets},
            {f"combat.skill.{asset['id'][6:]}" for asset in skill_assets},
        )
        update3_connected = [
            asset
            for asset in self.assets
            if asset["runtime_path"].startswith("assets/audio/update3/")
            and asset["runtime_connection"] == "actual_runtime"
        ]
        self.assertTrue(update3_connected)
        for asset in update3_connected:
            self.assertTrue(asset["events"], asset["id"])
            self.assertTrue(
                all(event_id.startswith("update3.") for event_id in asset["events"]),
                asset["id"],
            )

    def test_approved_footsteps_have_three_surfaces_and_runtime_events(self) -> None:
        expected_ids = {
            f"footstep_{surface}_{variation:02d}"
            for surface in ("cave_rough", "castle_stone", "metal_passage")
            for variation in range(1, 4)
        }
        footsteps = {
            asset_id: self.asset_by_id[asset_id]
            for asset_id in expected_ids
        }
        self.assertEqual(expected_ids, set(footsteps))
        for asset_id, asset in footsteps.items():
            surface, variation = asset_id.removeprefix("footstep_").rsplit("_", 1)
            event_id = f"footstep.{surface}.{variation}"
            self.assertEqual(asset["review_status"], "approved")
            self.assertEqual(asset["runtime_connection"], "actual_runtime")
            self.assertEqual(asset["voice_category"], "footstep")
            self.assertEqual(asset["voice_priority"], 50)
            self.assertEqual(asset["events"], [event_id])
            event = self.event_by_id[event_id]
            self.assertEqual(event["asset_id"], asset_id)
            self.assertEqual(event["owner"], "scripts/audio/FootstepScheduler.gd")
            self.assertEqual(event["locator"], "play_footstep_for_unit")

    def test_final_lyria_batch_is_approved_and_runtime_connected(self) -> None:
        expected_event_ids = {
            *(f"combat.attack.{family}.{variation:02d}" for family in ("blade", "blunt_shield", "claw_bite", "fire_magic") for variation in range(1, 4)),
            "combat.impact.body",
            "combat.impact.metal",
            "combat.impact.stone",
            "combat.outcome.down",
            "combat.outcome.critical",
            "combat.outcome.reward",
            "ui.click",
            "ui.select",
            "ui.confirm",
            "ui.cancel",
            "ui.fail",
            "ui.danger",
            "music.screen.title",
            "music.combat.late_risk",
            "music.final.ending",
        }
        self.assertEqual(27, len(expected_event_ids))
        for event_id in expected_event_ids:
            event = self.event_by_id[event_id]
            asset = self.asset_by_id[event["asset_id"]]
            self.assertEqual(asset["review_status"], "approved", event_id)
            self.assertEqual(asset["runtime_connection"], "actual_runtime", event_id)
            self.assertEqual(asset["provenance"], "lyria", event_id)
            self.assertEqual(asset["source_record_status"], "present", event_id)
            self.assertEqual(asset["events"], [event_id])
            self.assertTrue((ROOT / asset["runtime_path"]).is_file(), event_id)
            self.assertTrue((ROOT / asset["source_record"]).is_file(), event_id)


if __name__ == "__main__":
    unittest.main()
