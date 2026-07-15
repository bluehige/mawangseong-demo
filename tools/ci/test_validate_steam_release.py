#!/usr/bin/env python3
import hashlib
import json
import struct
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "tools" / "release" / "validate_steam_release.py"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fake_pck(paths: list[str]) -> bytes:
    header_size = 4 + (5 * 4) + 8 + 8 + (16 * 4)
    data = bytearray(
        struct.pack(
            "<6IQQ",
            0x43504447,
            3,
            4,
            5,
            2,
            1 << 1,
            header_size,
            header_size,
        )
    )
    data.extend(bytes(16 * 4))
    data.extend(struct.pack("<I", len(paths)))
    for path in paths:
        encoded = path.encode("utf-8")
        padded_length = (len(encoded) + 3) & ~3
        data.extend(struct.pack("<I", padded_length))
        data.extend(encoded)
        data.extend(bytes(padded_length - len(encoded)))
        data.extend(struct.pack("<QQ", 0, 0))
        data.extend(bytes(16))
        data.extend(struct.pack("<I", 0))
    return bytes(data)


class SteamReleaseValidatorTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.build = Path(self.temp_dir.name) / "build"
        (self.build / "licenses").mkdir(parents=True)
        files = {
            "MawangCastle.exe": b"fake-windows-executable",
            "MawangCastle.pck": fake_pck(["project.godot", "scenes/main/Main.tscn"]),
            "THIRD_PARTY_NOTICES.txt": b"third party notices",
            "licenses/NotoSansCJK_LICENSE.txt": b"OFL",
            "licenses/NEXON_Maplestory_LICENSE.txt": "넥슨".encode("utf-8"),
        }
        for relative, content in files.items():
            path = self.build / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(content)
        self._write_manifest()

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def _write_manifest(self) -> None:
        manifest_path = self.build / "steam-build-manifest.json"
        artifacts = []
        for path in sorted(self.build.rglob("*")):
            if not path.is_file() or path == manifest_path:
                continue
            artifacts.append(
                {
                    "path": path.relative_to(self.build).as_posix(),
                    "bytes": path.stat().st_size,
                    "sha256": sha256(path),
                }
            )
        manifest = {
            "schema_version": 1,
            "version": "0.3.0",
            "tag": "v0.3.0",
            "source_commit": "a" * 40,
            "godot_version": "4.5.2.stable.official",
            "built_at_utc": "2026-07-15T00:00:00Z",
            "artifacts": artifacts,
        }
        manifest_path.write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

    def _run(self, *extra: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(SCRIPT), *extra],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
        )

    def test_tracked_setup_passes_with_explicit_pending_items(self) -> None:
        result = self._run()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("STEAM_RELEASE: SETUP_PASS", result.stdout)
        self.assertIn("Steam App ID has not been assigned", result.stdout)

    def test_valid_depot_manifest_passes(self) -> None:
        result = self._run("--build-dir", str(self.build))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("STEAM_RELEASE: SETUP_PASS", result.stdout)

    def test_forbids_shipping_steam_appid_file(self) -> None:
        (self.build / "steam_appid.txt").write_text("480\n", encoding="utf-8")
        self._write_manifest()
        result = self._run("--build-dir", str(self.build))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("forbidden file in Steam depot: steam_appid.txt", result.stderr)

    def test_rejects_manifest_hash_drift(self) -> None:
        (self.build / "MawangCastle.pck").write_bytes(b"changed after manifest")
        result = self._run("--build-dir", str(self.build))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("manifest byte size mismatch: MawangCastle.pck", result.stderr)
        self.assertIn("manifest SHA-256 mismatch: MawangCastle.pck", result.stderr)

    def test_rejects_development_resource_inside_pck(self) -> None:
        (self.build / "MawangCastle.pck").write_bytes(
            fake_pck(["project.godot", "assets/source/imagegen/private.png"])
        )
        self._write_manifest()
        result = self._run("--build-dir", str(self.build))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(
            "development-only resource in Steam PCK: assets/source/imagegen/private.png",
            result.stderr,
        )

    def test_strict_gate_blocks_placeholders_and_requires_build(self) -> None:
        result = self._run("--strict")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Steam App ID has not been assigned", result.stderr)
        self.assertIn("--strict requires --build-dir", result.stderr)


if __name__ == "__main__":
    unittest.main()
