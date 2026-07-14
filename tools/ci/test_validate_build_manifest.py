#!/usr/bin/env python3
import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("validate_build_manifest.py")
PREPARER = Path(__file__).with_name("prepare_release_evidence.py")
COMMIT_SHA = "a" * 40
TAG = "v0.4.0"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path: Path, data: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
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
        self.raw_report = self.root / "tmp" / "core_verification" / "latest.json"
        self.manifest_path = self.build / "build-manifest.json"
        self._create_valid_build()

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def _runner_check(self, check_id: str) -> dict:
        return {
            "id": check_id,
            "name": check_id.replace("_", " ").title(),
            "passed": True,
            "exit_code": 0,
            "launch_error": "",
            "started_at": "2026-07-14T03:00:00+00:00",
            "completed_at": "2026-07-14T03:01:00+00:00",
            "duration_seconds": 60.0,
            "command": "godot --headless --path .",
            "log": f"tmp/core_verification/{check_id}.log",
            "artifacts": [],
        }

    def _create_valid_build(self) -> None:
        catalog = {
            "version": 1,
            "checks": [
                {"id": "project_import", "modes": ["quick", "full"]},
                {
                    "id": "campaign_save_load",
                    "modes": ["full"],
                    "cases": [
                        {"id_suffix": "legacy"},
                        {"id_suffix": "current"},
                    ],
                },
                {"id": "self_test", "modes": ["selftest"]},
            ],
        }
        write_json(self.canonical_catalog, catalog)
        catalog_hash = sha256(self.canonical_catalog)

        raw_report = {
            "version": 1,
            "runner": "tools/tests/RunCoreVerification.ps1",
            "commit_sha": COMMIT_SHA,
            "catalog_sha256": catalog_hash,
            "source_tree_clean": True,
            "generated_at": "2026-07-14T03:02:00+00:00",
            "mode": "full",
            "passed": True,
            "started_at": "2026-07-14T03:00:00+00:00",
            "completed_at": "2026-07-14T03:02:00+00:00",
            "duration_seconds": 120.0,
            "godot_path": "godot",
            "counts": {"total": 3, "passed": 3, "failed": 0},
            "checks": [
                self._runner_check("project_import"),
                self._runner_check("campaign_save_load_legacy"),
                self._runner_check("campaign_save_load_current"),
            ],
        }
        write_json(self.raw_report, raw_report)
        conversion = self._run_preparer()
        if conversion.returncode != 0:
            self.fail(conversion.stderr)

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
                "expected_checks": 3,
                "passed": 3,
                "failed": 0,
                "catalog_path": "verification-catalog.json",
                "catalog_sha256": sha256(
                    self.build / "verification-catalog.json"
                ),
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

    def _run_preparer(
        self,
        raw_report: Path | None = None,
        output_dir: Path | None = None,
    ) -> subprocess.CompletedProcess:
        return subprocess.run(
            [
                sys.executable,
                str(PREPARER),
                "--raw-report",
                str(raw_report or self.raw_report),
                "--catalog",
                str(self.canonical_catalog),
                "--output-dir",
                str(output_dir or self.build),
                "--expected-commit",
                COMMIT_SHA,
            ],
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
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

    def test_accepts_actual_full_runner_evidence(self) -> None:
        self.assertEqual(
            self.raw_report.read_bytes(),
            (self.build / "verification-report.json").read_bytes(),
        )
        result = self._run()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("BUILD_MANIFEST: PASS", result.stdout)

    def test_preparer_rejects_quick_runner_report(self) -> None:
        report = json.loads(self.raw_report.read_text(encoding="utf-8"))
        report["mode"] = "quick"
        quick_report = self.root / "quick-report.json"
        write_json(quick_report, report)
        result = self._run_preparer(
            raw_report=quick_report,
            output_dir=self.root / "quick-output",
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("runner report mode must be full", result.stderr)

    def test_preparer_rejects_dirty_source_tree(self) -> None:
        report = json.loads(self.raw_report.read_text(encoding="utf-8"))
        report["source_tree_clean"] = False
        dirty_report = self.root / "dirty-report.json"
        write_json(dirty_report, report)
        result = self._run_preparer(
            raw_report=dirty_report,
            output_dir=self.root / "dirty-output",
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("runner report requires a clean source tree", result.stderr)

    def test_preparer_rejects_duplicate_expanded_case_id(self) -> None:
        catalog = json.loads(self.canonical_catalog.read_text(encoding="utf-8"))
        catalog["checks"][1]["cases"] = [
            {"id_suffix": "duplicate"},
            {"id_suffix": "duplicate"},
        ]
        write_json(self.canonical_catalog, catalog)
        result = self._run_preparer(output_dir=self.root / "duplicate-output")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(
            "expanded Full catalog check IDs must be unique",
            result.stderr,
        )

    def test_rejects_unlisted_runtime_file(self) -> None:
        (self.build / "unexpected.worker.js").write_text(
            "console.log('unexpected');\n",
            encoding="utf-8",
        )
        self.assert_validation_fails("unlisted files: unexpected.worker.js")

    def test_rejects_non_full_manifest_suite(self) -> None:
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

    def test_rejects_runner_check_set_mismatch(self) -> None:
        report_path = self.build / "verification-report.json"
        report = json.loads(report_path.read_text(encoding="utf-8"))
        report["checks"][1]["id"] = "unexpected_check"
        write_json(report_path, report)
        manifest = self._read_manifest()
        self._refresh_artifacts(manifest)
        self._write_manifest(manifest)
        self.assert_validation_fails(
            "runner report checks must exactly match the Full catalog"
        )

    def test_rejects_stale_runner_artifact(self) -> None:
        report_path = self.build / "verification-report.json"
        report = json.loads(report_path.read_text(encoding="utf-8"))
        report["checks"][0]["artifacts"] = [
            {
                "path": "tmp/example.json",
                "exists": True,
                "fresh": False,
                "status": "stale",
            }
        ]
        write_json(report_path, report)
        manifest = self._read_manifest()
        self._refresh_artifacts(manifest)
        self._write_manifest(manifest)
        self.assert_validation_fails(
            "runner report contains missing or stale evidence"
        )


if __name__ == "__main__":
    unittest.main()
