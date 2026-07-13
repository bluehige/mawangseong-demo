#!/usr/bin/env python3
import argparse
import hashlib
import json
import re
import sys
from datetime import datetime, timedelta
from pathlib import Path

from core_verification_evidence import EvidenceError, validate_runner_report


REQUIRED_WEB_FILES = {"index.html", "index.js", "index.pck", "index.wasm"}
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
COMMIT_RE = re.compile(r"^[0-9a-f]{40}$")
SEMVER_TAG_RE = re.compile(r"^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$")
VERSION_RE = re.compile(r"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$")


def fail(message: str) -> None:
    print(f"BUILD_MANIFEST: FAIL - {message}", file=sys.stderr)
    raise SystemExit(1)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--expected-tag", default="")
    parser.add_argument("--expected-commit", default="")
    parser.add_argument("--expected-catalog", type=Path, required=True)
    args = parser.parse_args()

    if not args.manifest.is_file():
        fail(f"manifest does not exist: {args.manifest}")
    if not args.expected_catalog.is_file():
        fail(f"expected verification catalog does not exist: {args.expected_catalog}")

    try:
        data = json.loads(args.manifest.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(f"invalid JSON: {error}")

    required_keys = {
        "schema_version",
        "version",
        "tag",
        "commit_sha",
        "godot_version",
        "built_at_utc",
        "verification",
        "artifacts",
    }
    missing = sorted(required_keys - set(data))
    if missing:
        fail(f"missing keys: {', '.join(missing)}")
    if type(data["schema_version"]) is not int or data["schema_version"] != 1:
        fail("schema_version must be 1")
    if not isinstance(data["tag"], str) or not SEMVER_TAG_RE.fullmatch(data["tag"]):
        fail("tag must be a stable SemVer tag such as v0.4.0")
    if not isinstance(data["version"], str) or not VERSION_RE.fullmatch(data["version"]):
        fail("version must be stable SemVer without the v prefix")
    if args.expected_tag and data["tag"] != args.expected_tag:
        fail(f"tag mismatch: expected {args.expected_tag}, got {data['tag']}")
    if not isinstance(data["commit_sha"], str) or not COMMIT_RE.fullmatch(data["commit_sha"]):
        fail("commit_sha must be a lowercase 40-character SHA")
    if args.expected_commit and data["commit_sha"] != args.expected_commit:
        fail(
            f"commit mismatch: expected {args.expected_commit}, "
            f"got {data['commit_sha']}"
        )
    if data["version"] != data["tag"][1:]:
        fail("version must match the SemVer tag without its v prefix")
    if not isinstance(data["godot_version"], str) or not data["godot_version"].strip():
        fail("godot_version must be a non-empty string")
    built_at = data["built_at_utc"]
    if not isinstance(built_at, str) or not built_at.endswith("Z"):
        fail("built_at_utc must use an explicit UTC Z suffix")
    try:
        parsed_built_at = datetime.fromisoformat(built_at[:-1] + "+00:00")
    except ValueError:
        fail("built_at_utc must be an ISO-8601 UTC timestamp")
    if parsed_built_at.utcoffset() != timedelta(0):
        fail("built_at_utc must be UTC")

    verification = data["verification"]
    if not isinstance(verification, dict):
        fail("verification must be an object")
    for key in (
        "suite",
        "expected_checks",
        "passed",
        "failed",
        "catalog_path",
        "catalog_sha256",
        "report_path",
        "report_sha256",
    ):
        if key not in verification:
            fail(f"verification.{key} is required")
    if verification["suite"] != "Full":
        fail("verification.suite must be Full for a release")
    if type(verification["expected_checks"]) is not int or verification["expected_checks"] < 1:
        fail("verification.expected_checks must be a positive integer")
    if type(verification["passed"]) is not int or verification["passed"] < 1:
        fail("verification.passed must be a positive integer")
    if type(verification["failed"]) is not int or verification["failed"] != 0:
        fail("verification.failed must be 0 for a release")
    if not isinstance(verification["report_path"], str) or not verification["report_path"]:
        fail("verification.report_path must be a non-empty relative path")
    if not isinstance(verification["report_sha256"], str) or not SHA256_RE.fullmatch(verification["report_sha256"]):
        fail("verification.report_sha256 must be a lowercase SHA-256")
    if not isinstance(verification["catalog_path"], str) or not verification["catalog_path"]:
        fail("verification.catalog_path must be a non-empty relative path")
    if not isinstance(verification["catalog_sha256"], str) or not SHA256_RE.fullmatch(verification["catalog_sha256"]):
        fail("verification.catalog_sha256 must be a lowercase SHA-256")

    artifacts = data["artifacts"]
    if not isinstance(artifacts, list) or not artifacts:
        fail("artifacts must be a non-empty array")

    root = args.manifest.parent.resolve()
    seen = set()
    artifact_by_path = {}
    for item in artifacts:
        if not isinstance(item, dict) or not {"path", "bytes", "sha256"} <= set(item):
            fail("each artifact requires path, bytes, and sha256")
        if not isinstance(item["path"], str) or not item["path"]:
            fail("artifact path must be a non-empty string")
        relative = Path(item["path"])
        if relative.is_absolute() or ".." in relative.parts:
            fail(f"artifact path must stay inside the build root: {relative}")
        normalized = relative.as_posix()
        if normalized in seen:
            fail(f"duplicate artifact path: {normalized}")
        seen.add(normalized)
        artifact_by_path[normalized] = item
        full_path = (root / relative).resolve()
        if root not in full_path.parents:
            fail(f"artifact escapes the build root: {normalized}")
        if not full_path.is_file():
            fail(f"artifact does not exist: {normalized}")
        if type(item["bytes"]) is not int or item["bytes"] < 0:
            fail(f"artifact bytes must be a non-negative integer: {normalized}")
        if full_path.stat().st_size != item["bytes"]:
            fail(f"byte size mismatch: {normalized}")
        if not isinstance(item["sha256"], str) or not SHA256_RE.fullmatch(item["sha256"]):
            fail(f"invalid SHA-256 format: {normalized}")
        if sha256(full_path) != item["sha256"]:
            fail(f"SHA-256 mismatch: {normalized}")

    missing_web = sorted(REQUIRED_WEB_FILES - seen)
    if missing_web:
        fail(f"required Web artifacts are missing: {', '.join(missing_web)}")

    actual_files = {
        path.relative_to(root).as_posix()
        for path in root.rglob("*")
        if path.is_file() and path.resolve() != args.manifest.resolve()
    }
    if actual_files != seen:
        unlisted = sorted(actual_files - seen)
        absent = sorted(seen - actual_files)
        details = []
        if unlisted:
            details.append(f"unlisted files: {', '.join(unlisted)}")
        if absent:
            details.append(f"listed but absent files: {', '.join(absent)}")
        fail("artifact list must exactly match extracted files; " + "; ".join(details))

    catalog_path = Path(verification["catalog_path"])
    if catalog_path.is_absolute() or ".." in catalog_path.parts:
        fail("verification.catalog_path must stay inside the build root")
    normalized_catalog = catalog_path.as_posix()
    if normalized_catalog not in artifact_by_path:
        fail("verification catalog must be included in artifacts")
    catalog_artifact = artifact_by_path[normalized_catalog]
    if catalog_artifact["sha256"] != verification["catalog_sha256"]:
        fail("verification catalog hash must match its artifact hash")
    if sha256(args.expected_catalog) != verification["catalog_sha256"]:
        fail("verification catalog does not match the canonical catalog")
    catalog_file = root / catalog_path

    report_path = Path(verification["report_path"])
    if report_path.is_absolute() or ".." in report_path.parts:
        fail("verification.report_path must stay inside the build root")
    normalized_report = report_path.as_posix()
    if normalized_report not in artifact_by_path:
        fail("verification report must be included in artifacts")
    report_artifact = artifact_by_path[normalized_report]
    if report_artifact["sha256"] != verification["report_sha256"]:
        fail("verification report hash must match its artifact hash")
    report_file = root / report_path
    try:
        _, full_check_ids = validate_runner_report(
            report_file,
            catalog_file,
            data["commit_sha"],
        )
    except EvidenceError as error:
        fail(str(error))
    if verification["expected_checks"] != len(full_check_ids):
        fail("verification.expected_checks does not match the Full catalog")
    if verification["passed"] != len(full_check_ids):
        fail("verification.passed must equal the Full catalog check count")

    print(f"BUILD_MANIFEST: PASS ({len(artifacts)} artifacts, {data['tag']})")


if __name__ == "__main__":
    main()
