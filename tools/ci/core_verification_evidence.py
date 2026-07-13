#!/usr/bin/env python3
import hashlib
import json
import re
from datetime import datetime
from pathlib import Path


COMMIT_RE = re.compile(r"^[0-9a-f]{40}$")
RUNNER_PATH = "tools/tests/RunCoreVerification.ps1"


class EvidenceError(ValueError):
    pass


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_json_object(path: Path, label: str) -> dict:
    try:
        data = json.loads(path.read_text(encoding="utf-8-sig"))
    except (OSError, json.JSONDecodeError) as error:
        raise EvidenceError(f"invalid {label} JSON: {error}") from error
    if not isinstance(data, dict):
        raise EvidenceError(f"{label} must be a JSON object")
    return data


def full_catalog_ids(catalog_path: Path) -> list[str]:
    catalog = load_json_object(catalog_path, "verification catalog")
    checks = catalog.get("checks")
    if not isinstance(checks, list):
        raise EvidenceError("verification catalog requires a checks array")

    all_ids = []
    full_ids = []
    for check in checks:
        if (
            not isinstance(check, dict)
            or not isinstance(check.get("id"), str)
            or not check["id"]
        ):
            raise EvidenceError("every catalog check requires a non-empty string id")
        check_id = check["id"]
        all_ids.append(check_id)
        modes = check.get("modes", [])
        if not isinstance(modes, list) or not all(
            isinstance(mode, str) for mode in modes
        ):
            raise EvidenceError(f"catalog check modes must be strings: {check_id}")
        if "full" in modes:
            full_ids.append(check_id)

    if len(all_ids) != len(set(all_ids)):
        raise EvidenceError("verification catalog check IDs must be unique")
    if not full_ids:
        raise EvidenceError("verification catalog has no Full checks")
    return full_ids


def _require_aware_timestamp(value: object, field: str) -> None:
    if not isinstance(value, str) or not value:
        raise EvidenceError(f"runner report {field} must be an ISO-8601 timestamp")
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise EvidenceError(
            f"runner report {field} must be an ISO-8601 timestamp"
        ) from error
    if parsed.tzinfo is None:
        raise EvidenceError(f"runner report {field} must include a timezone")


def validate_runner_report(
    report_path: Path,
    catalog_path: Path,
    expected_commit: str,
) -> tuple[dict, list[str]]:
    if not COMMIT_RE.fullmatch(expected_commit):
        raise EvidenceError("expected commit must be a lowercase 40-character SHA")

    full_ids = full_catalog_ids(catalog_path)
    report = load_json_object(report_path, "core verification report")
    required_keys = {
        "version",
        "runner",
        "commit_sha",
        "catalog_sha256",
        "source_tree_clean",
        "generated_at",
        "mode",
        "passed",
        "counts",
        "checks",
    }
    missing = sorted(required_keys - set(report))
    if missing:
        raise EvidenceError(
            "runner report is missing fields: " + ", ".join(missing)
        )
    if type(report["version"]) is not int or report["version"] != 1:
        raise EvidenceError("runner report version must be 1")
    if report["runner"] != RUNNER_PATH:
        raise EvidenceError(f"runner report must identify {RUNNER_PATH}")
    if report["commit_sha"] != expected_commit:
        raise EvidenceError("runner report commit_sha does not match the build")
    if report["catalog_sha256"] != sha256_file(catalog_path):
        raise EvidenceError("runner report catalog hash does not match the catalog")
    if report["source_tree_clean"] is not True:
        raise EvidenceError("runner report requires a clean source tree")
    _require_aware_timestamp(report["generated_at"], "generated_at")
    if report["mode"] != "full":
        raise EvidenceError("runner report mode must be full")
    if report["passed"] is not True:
        raise EvidenceError("runner report overall result must be true")

    counts = report["counts"]
    if not isinstance(counts, dict):
        raise EvidenceError("runner report counts must be an object")
    for key in ("total", "passed", "failed"):
        if type(counts.get(key)) is not int:
            raise EvidenceError(f"runner report counts.{key} must be an integer")
    if (
        counts["total"] != len(full_ids)
        or counts["passed"] != len(full_ids)
        or counts["failed"] != 0
    ):
        raise EvidenceError("runner report counts do not match the Full catalog")

    checks = report["checks"]
    if not isinstance(checks, list):
        raise EvidenceError("runner report checks must be an array")
    check_by_id = {}
    for check in checks:
        if (
            not isinstance(check, dict)
            or not isinstance(check.get("id"), str)
            or not check["id"]
        ):
            raise EvidenceError("every runner report check requires a string id")
        check_id = check["id"]
        if check_id in check_by_id:
            raise EvidenceError(f"duplicate runner report check: {check_id}")
        check_by_id[check_id] = check

    if set(check_by_id) != set(full_ids):
        raise EvidenceError(
            "runner report checks must exactly match the Full catalog"
        )

    for check_id in full_ids:
        check = check_by_id[check_id]
        if check.get("passed") is not True:
            raise EvidenceError(f"runner report check did not pass: {check_id}")
        if type(check.get("exit_code")) is not int or check["exit_code"] != 0:
            raise EvidenceError(
                f"runner report check exit_code must be 0: {check_id}"
            )
        if check.get("launch_error") != "":
            raise EvidenceError(
                f"runner report check has a launch error: {check_id}"
            )
        artifacts = check.get("artifacts")
        if not isinstance(artifacts, list):
            raise EvidenceError(
                f"runner report check artifacts must be an array: {check_id}"
            )
        for artifact in artifacts:
            if not isinstance(artifact, dict):
                raise EvidenceError(
                    f"runner report artifact must be an object: {check_id}"
                )
            if (
                artifact.get("exists") is not True
                or artifact.get("fresh") is not True
                or artifact.get("status") != "fresh"
            ):
                raise EvidenceError(
                    f"runner report contains missing or stale evidence: {check_id}"
                )

    return report, full_ids
