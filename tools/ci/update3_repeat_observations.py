#!/usr/bin/env python3
"""Validate and summarize Update 3 human free-choice observations."""

from __future__ import annotations

import argparse
import json
import re
import sys
import tempfile
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Callable


SCHEMA_VERSION = 1
EVIDENCE_KIND = "human_update3_repeat_observation"
SUMMARY_EVIDENCE_KIND = "human_update3_repeat_observation_summary"

FRONT_IDS = (
    "front_hero_oath",
    "front_holy_purification",
    "front_guild_repossession",
)
HEART_IDS = (
    "heart_stonebone",
    "heart_hungry_maw",
    "heart_dream_lantern",
)
DUO_LINK_IDS = (
    "link_spore_jelly_shelter",
    "link_ghostly_evacuate",
    "link_moon_scent_hunt",
    "link_molten_carapace",
    "link_stone_march",
    "link_false_beacon_vault",
)
MONSTER_INSTANCE_IDS = (
    "mon_core_pudding",
    "mon_core_gob",
    "mon_core_pynn",
    "mon_core_rolo",
    "mon_contract_mori",
    "mon_contract_dolkong",
    "mon_contract_dudum",
    "mon_contract_lumi",
    "monster_bebe",
    "monster_koko",
    "monster_toktok",
    "mon_contract_mimi",
)
DUO_MEMBERS = {
    "link_spore_jelly_shelter": ("mon_core_pudding", "mon_contract_mori"),
    "link_ghostly_evacuate": ("mon_core_pudding", "monster_bebe"),
    "link_moon_scent_hunt": ("mon_core_gob", "monster_koko"),
    "link_molten_carapace": ("mon_core_pynn", "monster_toktok"),
    "link_stone_march": ("mon_contract_dolkong", "mon_contract_dudum"),
    "link_false_beacon_vault": ("mon_contract_lumi", "mon_contract_mimi"),
}
OUTCOMES = ("win", "loss", "abandoned")

MIN_SESSIONS = 18
MIN_OBSERVERS = 6
MAX_SESSIONS_PER_OBSERVER = 3
MIN_DUO_OPPORTUNITIES = 10
MIN_COMPLETED_FOR_GROUP_RATE = 5
COMMIT_RE = re.compile(r"^[0-9a-f]{40}$")
ENDING_CATALOG_CODE_RE = re.compile(r"^E\d{2}$")


def _is_int(value: object) -> bool:
    return type(value) is int


def _is_number(value: object) -> bool:
    return type(value) in (int, float)


def _validate_string_list(
    value: object,
    field: str,
    allowed: tuple[str, ...] | None = None,
) -> list[str]:
    errors: list[str] = []
    if not isinstance(value, list) or not all(
        isinstance(item, str) and item for item in value
    ):
        return [f"{field} must be an array of non-empty strings"]
    if len(value) != len(set(value)):
        errors.append(f"{field} must not contain duplicates")
    if allowed is not None:
        unknown = sorted(set(value) - set(allowed))
        if unknown:
            errors.append(f"{field} contains unknown IDs: {', '.join(unknown)}")
    return errors


def _validate_available_ids(
    value: object,
    field: str,
    expected: tuple[str, ...],
) -> list[str]:
    errors = _validate_string_list(value, field, expected)
    if isinstance(value, list) and set(value) != set(expected):
        errors.append(f"{field} must contain every configured option exactly once")
    return errors


def validate_report(report: object, expected_sha: str) -> list[str]:
    if not isinstance(report, dict):
        return ["root must be a JSON object"]

    errors: list[str] = []
    if report.get("schema_version") != SCHEMA_VERSION or not _is_int(
        report.get("schema_version")
    ):
        errors.append("schema_version must be 1")
    if report.get("evidence_kind") != EVIDENCE_KIND:
        errors.append(f"evidence_kind must be {EVIDENCE_KIND}")
    if not isinstance(report.get("session_id"), str) or not report["session_id"]:
        errors.append("session_id must be a non-empty string")
    if not isinstance(report.get("observer_id"), str) or not report["observer_id"]:
        errors.append("observer_id must be a non-empty pseudonymous string")
    run_number = report.get("run_number_for_observer")
    if not _is_int(run_number) or run_number < 1:
        errors.append("run_number_for_observer must be a positive integer")
    commit_sha = report.get("commit_sha")
    if not isinstance(commit_sha, str) or not COMMIT_RE.fullmatch(commit_sha):
        errors.append("commit_sha must be a lowercase 40-character SHA")
    if commit_sha != expected_sha:
        errors.append("commit_sha must exactly match --expected-sha")

    available = report.get("available")
    if not isinstance(available, dict):
        errors.append("available must be an object")
    else:
        errors.extend(
            _validate_available_ids(
                available.get("front_ids"), "available.front_ids", FRONT_IDS
            )
        )
        errors.extend(
            _validate_available_ids(
                available.get("heart_ids"), "available.heart_ids", HEART_IDS
            )
        )
        errors.extend(
            _validate_available_ids(
                available.get("duo_link_ids"),
                "available.duo_link_ids",
                DUO_LINK_IDS,
            )
        )

    choices = report.get("choices")
    if not isinstance(choices, dict):
        errors.append("choices must be an object")
    else:
        front_id = choices.get("front_id")
        heart_id = choices.get("heart_id")
        if front_id not in FRONT_IDS:
            errors.append("choices.front_id must be a configured front ID")
        if heart_id not in HEART_IDS:
            errors.append("choices.heart_id must be a configured heart ID")

        equipped = choices.get("equipped_duo_link_ids")
        used = choices.get("used_duo_link_ids")
        errors.extend(
            _validate_string_list(
                equipped, "choices.equipped_duo_link_ids", DUO_LINK_IDS
            )
        )
        errors.extend(
            _validate_string_list(used, "choices.used_duo_link_ids", DUO_LINK_IDS)
        )
        errors.extend(
            _validate_string_list(
                choices.get("deployed_instance_ids"),
                "choices.deployed_instance_ids",
                MONSTER_INSTANCE_IDS,
            )
        )
        deployed = choices.get("deployed_instance_ids")
        if isinstance(equipped, list) and len(equipped) > 2:
            errors.append("choices.equipped_duo_link_ids may contain at most 2 links")
        if isinstance(deployed, list) and not 1 <= len(deployed) <= 5:
            errors.append("choices.deployed_instance_ids must contain 1 to 5 instances")
        if isinstance(equipped, list) and isinstance(used, list):
            not_equipped = sorted(set(used) - set(equipped))
            if not_equipped:
                errors.append(
                    "choices.used_duo_link_ids must be a subset of equipped links"
                )
        if isinstance(used, list) and isinstance(deployed, list):
            for duo_id in used:
                if duo_id not in DUO_MEMBERS:
                    continue
                missing_members = sorted(set(DUO_MEMBERS[duo_id]) - set(deployed))
                if missing_members:
                    errors.append(
                        "choices.used_duo_link_ids requires deployed members for "
                        f"{duo_id}: {', '.join(missing_members)}"
                    )
        if type(choices.get("heart_active_used")) is not bool:
            errors.append("choices.heart_active_used must be a boolean")

    outcome = report.get("outcome")
    if not isinstance(outcome, dict):
        errors.append("outcome must be an object")
    else:
        result = outcome.get("result")
        if result not in OUTCOMES:
            errors.append("outcome.result must be win, loss, or abandoned")
        completed_day = outcome.get("completed_day")
        completed_day_valid = _is_int(completed_day) and 0 <= completed_day <= 30
        if not completed_day_valid:
            errors.append("outcome.completed_day must be an integer from 0 to 30")
        ending_catalog_code = outcome.get("ending_catalog_code")
        ending_catalog_code_valid = isinstance(ending_catalog_code, str) and not (
            ending_catalog_code and not ENDING_CATALOG_CODE_RE.fullmatch(ending_catalog_code)
        )
        if not ending_catalog_code_valid:
            errors.append(
                "outcome.ending_catalog_code must be empty or an E00-style catalog code"
            )
        combat_time = outcome.get("day30_combat_time_seconds")
        combat_time_valid = combat_time is None or not (
            not _is_number(combat_time) or combat_time < 0
        )
        if not combat_time_valid:
            errors.append(
                "outcome.day30_combat_time_seconds must be null or non-negative"
            )
        if result in OUTCOMES and completed_day_valid and ending_catalog_code_valid and combat_time_valid:
            if result == "win" and completed_day != 30:
                errors.append("outcome win requires completed_day 30")
            if completed_day < 30 and ending_catalog_code:
                errors.append("outcome before DAY 30 cannot include an ending_catalog_code")
            if completed_day < 30 and combat_time is not None:
                errors.append("outcome before DAY 30 requires null day30_combat_time_seconds")
            if ending_catalog_code and (completed_day != 30 or result == "abandoned"):
                errors.append(
                    "outcome.ending_catalog_code requires a completed DAY 30 win or loss"
                )
            if combat_time is not None and completed_day != 30:
                errors.append(
                    "outcome.day30_combat_time_seconds requires completed_day 30"
                )
            if result in ("win", "loss") and completed_day == 30 and combat_time is None:
                errors.append(
                    "completed DAY 30 win or loss requires day30_combat_time_seconds"
                )
            if result == "win" and not ending_catalog_code:
                errors.append("outcome win requires an ending_catalog_code")
            if result == "abandoned" and ending_catalog_code:
                errors.append("outcome abandoned cannot include an ending_catalog_code")

    reason_tags = report.get("reason_tags")
    if reason_tags is not None:
        if not isinstance(reason_tags, dict):
            errors.append("reason_tags must be an object when supplied")
        else:
            for category in ("front", "heart", "duo"):
                errors.extend(
                    _validate_string_list(
                        reason_tags.get(category, []), f"reason_tags.{category}"
                    )
                )
    if "notes" in report and not isinstance(report["notes"], str):
        errors.append("notes must be a string")
    return errors


def load_reports(input_dir: Path, expected_sha: str) -> dict:
    reports: list[dict] = []
    invalid_files: list[dict] = []
    duplicate_files: list[dict] = []
    seen_sessions: set[str] = set()
    seen_observer_runs: set[tuple[str, int]] = set()
    schema_mismatch_count = 0
    sha_mismatch_count = 0
    availability_mismatch_count = 0

    candidates = sorted(input_dir.glob("session_*.json"))
    for path in candidates:
        try:
            parsed = json.loads(path.read_text(encoding="utf-8-sig"))
        except (OSError, json.JSONDecodeError) as error:
            invalid_files.append({"path": str(path), "errors": [str(error)]})
            continue

        errors = validate_report(parsed, expected_sha)
        if "schema_version must be 1" in errors:
            schema_mismatch_count += 1
        if any(error.startswith("commit_sha must") for error in errors):
            sha_mismatch_count += 1
        if any(error.startswith("available.") for error in errors):
            availability_mismatch_count += 1
        if errors:
            invalid_files.append({"path": str(path), "errors": errors})
            continue

        report: dict = parsed
        session_id = report["session_id"]
        observer_run = (
            report["observer_id"],
            report["run_number_for_observer"],
        )
        if session_id in seen_sessions:
            duplicate_files.append(
                {
                    "path": str(path),
                    "reason": "duplicate session_id",
                    "session_id": session_id,
                }
            )
            continue
        if observer_run in seen_observer_runs:
            duplicate_files.append(
                {
                    "path": str(path),
                    "reason": "duplicate observer_id/run_number_for_observer",
                    "session_id": session_id,
                }
            )
            continue
        seen_sessions.add(session_id)
        seen_observer_runs.add(observer_run)
        reports.append(report)

    return {
        "candidate_count": len(candidates),
        "reports": reports,
        "invalid_files": invalid_files,
        "duplicate_files": duplicate_files,
        "schema_mismatch_count": schema_mismatch_count,
        "sha_mismatch_count": sha_mismatch_count,
        "availability_mismatch_count": availability_mismatch_count,
    }


def _round_ratio(numerator: int, denominator: int) -> float:
    return round(numerator / denominator, 4) if denominator else 0.0


def _outcome_stats(selected: list[dict]) -> dict:
    completed = [
        report
        for report in selected
        if report["outcome"]["result"] in ("win", "loss")
    ]
    wins = sum(report["outcome"]["result"] == "win" for report in completed)
    completed_count = len(completed)
    return {
        "completed_win_loss_count": completed_count,
        "wins": wins,
        "losses": completed_count - wins,
        "win_rate": (
            _round_ratio(wins, completed_count)
            if completed_count >= MIN_COMPLETED_FOR_GROUP_RATE
            else "insufficient"
        ),
    }


def _choice_rows(
    ids: tuple[str, ...],
    reports: list[dict],
    selected: Callable[[dict, str], bool],
) -> list[dict]:
    rows: list[dict] = []
    for choice_id in ids:
        matching = [report for report in reports if selected(report, choice_id)]
        row = {
            "id": choice_id,
            "selected_session_count": len(matching),
            "selection_rate": _round_ratio(len(matching), len(reports)),
        }
        row.update(_outcome_stats(matching))
        rows.append(row)
    return rows


def _readiness(scan: dict) -> dict:
    reports: list[dict] = scan["reports"]
    observer_counts = Counter(report["observer_id"] for report in reports)
    duo_opportunities = {
        duo_id: sum(
            duo_id in report["available"]["duo_link_ids"] for report in reports
        )
        for duo_id in DUO_LINK_IDS
    }
    max_observer_count = max(observer_counts.values(), default=0)
    checks = {
        "minimum_valid_sessions": {
            "required": MIN_SESSIONS,
            "actual": len(reports),
            "passed": len(reports) >= MIN_SESSIONS,
        },
        "minimum_observers": {
            "required": MIN_OBSERVERS,
            "actual": len(observer_counts),
            "passed": len(observer_counts) >= MIN_OBSERVERS,
        },
        "maximum_sessions_per_observer": {
            "required": MAX_SESSIONS_PER_OBSERVER,
            "actual": max_observer_count,
            "passed": max_observer_count <= MAX_SESSIONS_PER_OBSERVER,
        },
        "all_options_available_each_session": {
            "required": True,
            "actual": scan["availability_mismatch_count"] == 0,
            "passed": scan["availability_mismatch_count"] == 0,
        },
        "minimum_duo_opportunities": {
            "required_each": MIN_DUO_OPPORTUNITIES,
            "actual_by_duo": duo_opportunities,
            "passed": all(
                count >= MIN_DUO_OPPORTUNITIES
                for count in duo_opportunities.values()
            ),
        },
        "same_schema_and_commit": {
            "required": True,
            "schema_mismatch_count": scan["schema_mismatch_count"],
            "sha_mismatch_count": scan["sha_mismatch_count"],
            "passed": (
                scan["schema_mismatch_count"] == 0
                and scan["sha_mismatch_count"] == 0
            ),
        },
    }
    blockers = [name for name, check in checks.items() if not check["passed"]]
    return {"ready": not blockers, "checks": checks, "blockers": blockers}


def build_summary(input_dir: Path, expected_sha: str) -> dict:
    scan = load_reports(input_dir, expected_sha)
    reports: list[dict] = scan["reports"]
    observer_counts = Counter(report["observer_id"] for report in reports)
    outcome_counts = Counter(report["outcome"]["result"] for report in reports)

    front_rows = _choice_rows(
        FRONT_IDS,
        reports,
        lambda report, choice_id: report["choices"]["front_id"] == choice_id,
    )
    heart_rows = _choice_rows(
        HEART_IDS,
        reports,
        lambda report, choice_id: report["choices"]["heart_id"] == choice_id,
    )
    duo_rows = _choice_rows(
        DUO_LINK_IDS,
        reports,
        lambda report, choice_id: choice_id
        in report["choices"]["equipped_duo_link_ids"],
    )
    for row in duo_rows:
        duo_id = row["id"]
        row["opportunity_count"] = sum(
            duo_id in report["available"]["duo_link_ids"] for report in reports
        )
        row["used_session_count"] = sum(
            duo_id in report["choices"]["used_duo_link_ids"] for report in reports
        )

    reason_tag_counts: dict[str, dict[str, int]] = {}
    for category in ("front", "heart", "duo"):
        counts: Counter[str] = Counter()
        for report in reports:
            counts.update(report.get("reason_tags", {}).get(category, []))
        reason_tag_counts[category] = dict(sorted(counts.items()))

    return {
        "schema_version": SCHEMA_VERSION,
        "evidence_kind": SUMMARY_EVIDENCE_KIND,
        "source_evidence_kind": EVIDENCE_KIND,
        "evidence_scope": "human_free_choice_only",
        "generated_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "expected_sha": expected_sha,
        "catalogs": {
            "front_ids": list(FRONT_IDS),
            "heart_ids": list(HEART_IDS),
            "duo_link_ids": list(DUO_LINK_IDS),
        },
        "source": {
            "input_dir": str(input_dir),
            "candidate_file_count": scan["candidate_count"],
            "valid_file_count": len(reports),
            "invalid_file_count": len(scan["invalid_files"]),
            "duplicate_file_count": len(scan["duplicate_files"]),
            "invalid_files": scan["invalid_files"],
            "duplicate_files": scan["duplicate_files"],
        },
        "readiness": _readiness(scan),
        "summary": {
            "valid_session_count": len(reports),
            "observer_count": len(observer_counts),
            "max_sessions_per_observer": max(observer_counts.values(), default=0),
            "observer_session_counts": dict(sorted(observer_counts.items())),
            "outcome_counts": {
                outcome: outcome_counts.get(outcome, 0) for outcome in OUTCOMES
            },
        },
        "selections": {
            "fronts": front_rows,
            "hearts": heart_rows,
            "duo_links": duo_rows,
        },
        "reason_tag_counts": reason_tag_counts,
        "limitations": [
            "This report summarizes human free-choice observations only.",
            "The forced 54-run automated proxy does not measure player selection rates.",
            "These observations do not replace the original 15 full-campaign proxies.",
            "Group win rates are withheld until at least five completed win/loss observations exist.",
        ],
    }


def _win_rate_text(value: object) -> str:
    if value == "insufficient":
        return "표본 부족 (<5)"
    return f"{float(value) * 100:.1f}%"


def _selection_table(title: str, rows: list[dict], include_duo: bool = False) -> list[str]:
    lines = [f"## {title}", ""]
    if include_duo:
        lines.extend(
            [
                "| ID | 선택 | 사용 | 기회 | 완료 승/패 | 승률 |",
                "|---|---:|---:|---:|---:|---:|",
            ]
        )
        for row in rows:
            lines.append(
                "| {id} | {selected_session_count} | {used_session_count} | "
                "{opportunity_count} | {completed_win_loss_count} | {rate} |".format(
                    rate=_win_rate_text(row["win_rate"]), **row
                )
            )
    else:
        lines.extend(
            [
                "| ID | 선택 | 완료 승/패 | 승률 |",
                "|---|---:|---:|---:|",
            ]
        )
        for row in rows:
            lines.append(
                "| {id} | {selected_session_count} | {completed_win_loss_count} | "
                "{rate} |".format(rate=_win_rate_text(row["win_rate"]), **row)
            )
    lines.append("")
    return lines


def build_markdown(report: dict) -> str:
    source = report["source"]
    summary = report["summary"]
    readiness = report["readiness"]
    outcome = summary["outcome_counts"]
    lines = [
        "# Update 3 반복 플레이 자유 선택 관찰 요약",
        "",
        "> 이 보고서는 사람이 모든 선택지를 보고 자유롭게 고른 관찰만 집계합니다. "
        "강제 배정 자동 proxy 결과와 섞지 않습니다.",
        "",
        f"- 생성 시각: {report['generated_at']}",
        f"- 대상 SHA: `{report['expected_sha']}`",
        f"- 유효 세션: {summary['valid_session_count']} / 관찰자: {summary['observer_count']}",
        f"- 파일: 후보 {source['candidate_file_count']}, 유효 {source['valid_file_count']}, "
        f"중복 제외 {source['duplicate_file_count']}, 형식 제외 {source['invalid_file_count']}",
        f"- readiness: {'READY' if readiness['ready'] else 'NOT READY'}",
        "",
        "## Readiness",
        "",
        "| 조건 | 결과 |",
        "|---|---|",
    ]
    for name, check in readiness["checks"].items():
        lines.append(f"| `{name}` | {'PASS' if check['passed'] else 'FAIL'} |")
    if readiness["blockers"]:
        lines.extend(
            [
                "",
                "미충족 조건: " + ", ".join(f"`{name}`" for name in readiness["blockers"]),
            ]
        )
    lines.extend(
        [
            "",
            "## 결과 분포",
            "",
            f"- 승리 {outcome['win']} / 패배 {outcome['loss']} / 중도 종료 {outcome['abandoned']}",
            "",
        ]
    )
    lines.extend(_selection_table("전선 자유 선택", report["selections"]["fronts"]))
    lines.extend(_selection_table("심장 자유 선택", report["selections"]["hearts"]))
    lines.extend(
        _selection_table(
            "연계기 자유 선택", report["selections"]["duo_links"], include_duo=True
        )
    )
    lines.extend(
        [
            "## 해석 제한",
            "",
            "- 54회 자동 proxy는 조합을 강제 배정하므로 플레이어 선택률을 측정하지 않습니다.",
            "- 이 자유 선택 관찰은 원 계획의 전체 캠페인 proxy 15회를 대체하지 않습니다.",
            "- 그룹별 완료 승/패가 5건 미만이면 승률을 계산하지 않고 `표본 부족`으로 표시합니다.",
            "- 자동 proxy와 사람 관찰의 분모·목적이 다르므로 수치를 합산하지 않습니다.",
            "",
        ]
    )
    return "\n".join(lines)


def write_summary(report: dict, output_dir: Path) -> tuple[Path, Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    json_path = output_dir / "latest.json"
    markdown_path = output_dir / "latest.md"
    json_path.write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    markdown_path.write_text(build_markdown(report), encoding="utf-8")
    return json_path, markdown_path


def _fixture(index: int, observer_id: str, run_number: int, commit_sha: str) -> dict:
    duo_id = DUO_LINK_IDS[index % len(DUO_LINK_IDS)]
    return {
        "schema_version": SCHEMA_VERSION,
        "evidence_kind": EVIDENCE_KIND,
        "session_id": f"session_test_{index:03d}",
        "observer_id": observer_id,
        "commit_sha": commit_sha,
        "run_number_for_observer": run_number,
        "available": {
            "front_ids": list(FRONT_IDS),
            "heart_ids": list(HEART_IDS),
            "duo_link_ids": list(DUO_LINK_IDS),
        },
        "choices": {
            "front_id": FRONT_IDS[index % len(FRONT_IDS)],
            "heart_id": HEART_IDS[index % len(HEART_IDS)],
            "equipped_duo_link_ids": [duo_id],
            "deployed_instance_ids": list(DUO_MEMBERS[duo_id]),
            "used_duo_link_ids": [duo_id],
            "heart_active_used": True,
        },
        "outcome": {
            "result": "win",
            "completed_day": 30,
            "ending_catalog_code": "E01",
            "day30_combat_time_seconds": 90.0,
        },
        "reason_tags": {"front": [], "heart": [], "duo": []},
        "notes": "",
    }


def _write_fixture(path: Path, report: dict) -> None:
    path.write_text(json.dumps(report, ensure_ascii=False), encoding="utf-8")


def run_self_tests() -> int:
    commit_sha = "a" * 40
    try:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)

            duplicate_dir = root / "duplicate"
            duplicate_dir.mkdir()
            duplicate = _fixture(0, "observer_00", 1, commit_sha)
            _write_fixture(duplicate_dir / "session_00.json", duplicate)
            _write_fixture(duplicate_dir / "session_01.json", duplicate)
            scan = load_reports(duplicate_dir, commit_sha)
            assert len(scan["reports"]) == 1
            assert len(scan["duplicate_files"]) == 1

            cap_dir = root / "observer_cap"
            cap_dir.mkdir()
            index = 0
            for observer_index, count in enumerate((4, 3, 3, 3, 3, 3)):
                for run_number in range(1, count + 1):
                    report = _fixture(
                        index, f"observer_{observer_index:02d}", run_number, commit_sha
                    )
                    _write_fixture(cap_dir / f"session_{index:03d}.json", report)
                    index += 1
            cap_summary = build_summary(cap_dir, commit_sha)
            cap_check = cap_summary["readiness"]["checks"][
                "maximum_sessions_per_observer"
            ]
            assert cap_check["actual"] == 4
            assert cap_check["passed"] is False
            assert cap_summary["readiness"]["ready"] is False

            insufficient_dir = root / "insufficient"
            insufficient_dir.mkdir()
            for index in range(4):
                report = _fixture(index, f"observer_{index:02d}", 1, commit_sha)
                report["choices"]["front_id"] = FRONT_IDS[0]
                _write_fixture(
                    insufficient_dir / f"session_{index:03d}.json", report
                )
            insufficient = build_summary(insufficient_dir, commit_sha)
            assert insufficient["readiness"]["ready"] is False
            assert insufficient["selections"]["fronts"][0]["win_rate"] == "insufficient"

            too_many_links = _fixture(20, "observer_impossible", 1, commit_sha)
            too_many_links["choices"]["equipped_duo_link_ids"] = list(
                DUO_LINK_IDS[:3]
            )
            assert any(
                "at most 2 links" in error
                for error in validate_report(too_many_links, commit_sha)
            )

            invalid_deployment = _fixture(21, "observer_impossible", 2, commit_sha)
            invalid_deployment["choices"]["deployed_instance_ids"] = [
                "mon_core_pudding",
                "mon_core_gob",
                "mon_core_pynn",
                "mon_contract_mori",
                "monster_koko",
                "unknown_monster",
            ]
            deployment_errors = validate_report(invalid_deployment, commit_sha)
            assert any("unknown IDs" in error for error in deployment_errors)
            assert any("1 to 5 instances" in error for error in deployment_errors)

            missing_pair = _fixture(22, "observer_impossible", 3, commit_sha)
            missing_pair["choices"]["deployed_instance_ids"] = ["mon_core_gob"]
            assert any(
                "requires deployed members" in error
                for error in validate_report(missing_pair, commit_sha)
            )

            wrong_ending_field = _fixture(23, "observer_ending", 1, commit_sha)
            wrong_ending_field["outcome"].pop("ending_catalog_code")
            wrong_ending_field["outcome"]["ending_id"] = "E01"
            assert any(
                "ending_catalog_code" in error
                for error in validate_report(wrong_ending_field, commit_sha)
            )

            impossible_early_win = _fixture(24, "observer_outcome", 1, commit_sha)
            impossible_early_win["outcome"]["completed_day"] = 5
            early_win_errors = validate_report(impossible_early_win, commit_sha)
            assert any("win requires completed_day 30" in error for error in early_win_errors)
            assert any("before DAY 30" in error for error in early_win_errors)

            incomplete_win_evidence = _fixture(25, "observer_outcome", 2, commit_sha)
            incomplete_win_evidence["outcome"]["ending_catalog_code"] = ""
            incomplete_win_evidence["outcome"]["day30_combat_time_seconds"] = None
            incomplete_win_errors = validate_report(incomplete_win_evidence, commit_sha)
            assert any("win requires an ending_catalog_code" in error for error in incomplete_win_errors)
            assert any(
                "requires day30_combat_time_seconds" in error
                for error in incomplete_win_errors
            )
    except AssertionError:
        print("UPDATE3_REPEAT_OBSERVATIONS_SELF_TEST: FAIL", file=sys.stderr)
        return 1
    print("UPDATE3_REPEAT_OBSERVATIONS_SELF_TEST: PASS (9/9)")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-dir")
    parser.add_argument("--output-dir")
    parser.add_argument("--expected-sha")
    parser.add_argument("--self-test", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.self_test:
        return run_self_tests()
    missing = [
        option
        for option, value in (
            ("--input-dir", args.input_dir),
            ("--output-dir", args.output_dir),
            ("--expected-sha", args.expected_sha),
        )
        if not value
    ]
    if missing:
        print("required arguments: " + ", ".join(missing), file=sys.stderr)
        return 2

    input_dir = Path(args.input_dir)
    if not input_dir.is_dir():
        print(f"input directory does not exist: {input_dir}", file=sys.stderr)
        return 2
    if not COMMIT_RE.fullmatch(args.expected_sha):
        print(
            "--expected-sha must be a lowercase 40-character SHA",
            file=sys.stderr,
        )
        return 2
    report = build_summary(input_dir, args.expected_sha)
    json_path, markdown_path = write_summary(report, Path(args.output_dir))
    status = "READY" if report["readiness"]["ready"] else "NOT_READY"
    print(f"UPDATE3_REPEAT_OBSERVATIONS: {status}")
    print(json_path)
    print(markdown_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
