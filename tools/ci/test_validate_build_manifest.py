#!/usr/bin/env python3
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("validate_build_manifest.py")
COMMIT_SHA = "a" * 40
TAG = "v0.4.0"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path: Path, data: object) -> None:
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


class BuildManifestValidatorTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        self.build = self.root / "build"
        self.build.mkdir()
        self.canonical_catalog = self.root / "core_verification_suite.json"
        self.manifest_path = self.build / "build-manifest.json"
        self._create_valid_build()

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def _create_valid_build(self) -> None:
        catalog = {
            "version": 1,
            "checks": [
                {"id": "project_import", "modes": ["quick", "full"]},
                {"id": "campaign_save_load", "modes": ["full"]},
                {"id": "self_test", "modes": ["selftest"]},
            ],
        }
        write_json(self.canonical_catalog, catalog)
        shutil.copyfile(
            self.canonical_catalog,
            self.build / "verification-catalog.json",
        )
        catalog_hash = sha256(self.canonical_catalog)

        report = {
            "commit_sha": COMMIT_SHA,
            "suite": "Full",
            "catalog_sha256": catalog_hash,
            "expected_checks": 2,
            "passed": 2,
            "failed": 0,
            "checks": [
                {"id": "project_import", "result": "PASS"},
                {"id": "campaign_save_load", "result": "PASS"},
            ],
        }
        write_json(self.build / "verification-report.json", report)

        runtime_files = {
            "index.html": b"<!doctype html>\n",
            "index.js": b"console.log('ok');\n",
            "index.pck": b"pck",
            "index.wasm": b"wasm",
            "index.audio.worklet.js": b"registerProcessor('audio', class {});\n",
        }
        for relative, content in runtime_files.items():
            (self.build / relative).write_bytes(content)

        manifest = {
            "schema_version": 1,
            "version": "0.4.0",
            "tag": TAG,
            "commit_sha": COMMIT_SHA,
            "godot_version": "4.5.2-stable",
            "built_at_utc": "2026-07-14T03:20:00Z",
            "verification": {
                "suite": "Full",
                "expected_checks": 2,
                "passed": 2,
                "failed": 0,
                "catalog_path": "verification-catalog.json",
                "catalog_sha256": catalog_hash,
                "report_path": "verification-report.json",
                "report_sha256": sha256(
                    self.build / "verification-report.json"
                ),
            },
            "artifacts": [],
        }
        self._refresh_artifacts(manifest)
        self._write_manifest(manifest)

    def _read_manifest(self) -> dict:
        return json.loads(self.manifest_path.read_text(encoding="utf-8"))

    def _write_manifest(self, manifest: dict) -> None:
        write_json(self.manifest_path, manifest)

    def _refresh_artifacts(self, manifest: dict) -> None:
        catalog_path = self.build / manifest["verification"]["catalog_path"]
        report_path = self.build / manifest["verification"]["report_path"]
        manifest["verification"]["catalog_sha256"] = sha256(catalog_path)
        manifest["verification"]["report_sha256"] = sha256(report_path)
        manifest["artifacts"] = []
        for path in sorted(self.build.rglob("*")):
            if not path.is_file() or path == self.manifest_path:
                continue
            manifest["artifacts"].append(
                {
                    "path": path.relative_to(self.build).as_posix(),
                    "bytes": path.stat().st_size,
                    "sha256": sha256(path),
                }
            )

    def _run(self, include_expected_tag: bool = True) -> subprocess.CompletedProcess:
        command = [
            sys.executable,
            str(SCRIPT),
            str(self.manifest_path),
            "--expected-commit",
            COMMIT_SHA,
            "--expected-catalog",
            str(self.canonical_catalog),
        ]
        if include_expected_tag:
            command.extend(["--expected-tag", TAG])
        return subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
        )

    def assert_validation_fails(self, expected_message: str, **kwargs: object) -> None:
        result = self._run(**kwargs)
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn(expected_message, result.stderr)

    def test_accepts_complete_full_release(self) -> None:
        result = self._run()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("BUILD_MANIFEST: PASS", result.stdout)

    def test_rejects_unlisted_runtime_file(self) -> None:
        (self.build / "unexpected.worker.js").write_text(
            "console.log('unexpected');\n",
            encoding="utf-8",
        )
        self.assert_validation_fails("unlisted files: unexpected.worker.js")

    def test_rejects_non_full_suite(self) -> None:
        manifest = self._read_manifest()
        manifest["verification"]["suite"] = "Smoke"
        self._write_manifest(manifest)
        self.assert_validation_fails("verification.suite must be Full")

    def test_rejects_boolean_check_count(self) -> None:
        manifest = self._read_manifest()
        manifest["verification"]["expected_checks"] = True
        self._write_manifest(manifest)
        self.assert_validation_fails(
            "verification.expected_checks must be a positive integer"
        )

    def test_rejects_wrong_report_hash(self) -> None:
        manifest = self._read_manifest()
        manifest["verification"]["report_sha256"] = "0" * 64
        self._write_manifest(manifest)
        self.assert_validation_fails(
            "verification report hash must match its artifact hash"
        )

    def test_rejects_non_semver_tag(self) -> None:
        manifest = self._read_manifest()
        manifest["tag"] = "v0.4"
        manifest["version"] = "0.4"
        self._write_manifest(manifest)
        self.assert_validation_fails(
            "tag must be a stable SemVer tag",
            include_expected_tag=False,
        )

    def test_rejects_non_utc_timestamp(self) -> None:
        manifest = self._read_manifest()
        manifest["built_at_utc"] = "2026-07-14T12:20:00+09:00"
        self._write_manifest(manifest)
        self.assert_validation_fails(
            "built_at_utc must use an explicit UTC Z suffix"
        )

    def test_rejects_catalog_other_than_canonical(self) -> None:
        changed_catalog = {
            "version": 1,
            "checks": [{"id": "single_check", "modes": ["full"]}],
        }
        write_json(self.build / "verification-catalog.json", changed_catalog)
        manifest = self._read_manifest()
        self._refresh_artifacts(manifest)
        self._write_manifest(manifest)
        self.assert_validation_fails(
            "verification catalog does not match the canonical catalog"
        )

    def test_rejects_report_check_set_mismatch(self) -> None:
        report_path = self.build / "verification-report.json"
        report = json.loads(report_path.read_text(encoding="utf-8"))
        report["checks"][1]["id"] = "unexpected_check"
        write_json(report_path, report)
        manifest = self._read_manifest()
        self._refresh_artifacts(manifest)
        self._write_manifest(manifest)
        self.assert_validation_fails(
            "verification report checks must exactly match the Full catalog"
        )


if __name__ == "__main__":
    unittest.main()
