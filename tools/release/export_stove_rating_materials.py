#!/usr/bin/env python3
"""Export a reviewable text snapshot and runtime illustration manifest for STOVE."""

from __future__ import annotations

import csv
import json
import re
from pathlib import Path
from typing import Any, Iterator

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "stove/ratings"
STRING_PATTERN = re.compile(r'"((?:\\.|[^"\\])*)"')
HUMAN_TEXT_PATTERN = re.compile(r"[가-힣]|[A-Za-z]{3,}\s+[A-Za-z]{3,}")
IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp"}


def json_strings(value: Any, pointer: str = "$") -> Iterator[tuple[str, str]]:
    if isinstance(value, str):
        yield pointer, value
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from json_strings(child, f"{pointer}[{index}]")
    elif isinstance(value, dict):
        for key, child in value.items():
            yield from json_strings(child, f"{pointer}.{key}")


def clean_text(text: str) -> str:
    return text.replace("\t", " ").replace("\r", " ").replace("\n", " ").strip()


def decode_gd_string(raw: str) -> str:
    try:
        return json.loads(f'"{raw}"')
    except json.JSONDecodeError:
        return raw.replace(r'\"', '"').replace(r"\n", " ").replace(r"\t", " ")


def collect_language_rows() -> list[tuple[str, str, str]]:
    rows: list[tuple[str, str, str]] = []
    for path in sorted((ROOT / "data").rglob("*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        for pointer, text in json_strings(data):
            cleaned = clean_text(text)
            if cleaned and HUMAN_TEXT_PATTERN.search(cleaned):
                rows.append((path.relative_to(ROOT).as_posix(), pointer, cleaned))

    code_files = sorted((ROOT / "scripts").rglob("*.gd")) + sorted((ROOT / "scenes").rglob("*.gd"))
    code_files.append(ROOT / "project.godot")
    for path in code_files:
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            for match in STRING_PATTERN.finditer(line):
                cleaned = clean_text(decode_gd_string(match.group(1)))
                if cleaned and HUMAN_TEXT_PATTERN.search(cleaned):
                    rows.append((path.relative_to(ROOT).as_posix(), f"line:{line_number}", cleaned))
    return rows


def write_language_file(rows: list[tuple[str, str, str]]) -> Path:
    target = OUTPUT / "language_text.tsv"
    target.parent.mkdir(parents=True, exist_ok=True)
    with target.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
        writer.writerow(("source", "locator", "text"))
        writer.writerows(rows)
    return target


def write_illustration_manifest() -> tuple[Path, int]:
    target = OUTPUT / "illustration_manifest.tsv"
    rows: list[tuple[str, int, int, str]] = []
    for path in sorted((ROOT / "assets").rglob("*")):
        if not path.is_file() or path.suffix.lower() not in IMAGE_SUFFIXES:
            continue
        relative = path.relative_to(ROOT).as_posix()
        if relative.startswith("assets/source/"):
            continue
        with Image.open(path) as image:
            rows.append((relative, image.width, image.height, image.mode))
    with target.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
        writer.writerow(("runtime_path", "width", "height", "mode"))
        writer.writerows(rows)
    return target, len(rows)


def main() -> int:
    language_rows = collect_language_rows()
    language_path = write_language_file(language_rows)
    illustration_path, illustration_count = write_illustration_manifest()
    print(
        "STOVE_RATING_MATERIALS: PASS "
        f"({len(language_rows)} strings -> {language_path.relative_to(ROOT)}, "
        f"{illustration_count} images -> {illustration_path.relative_to(ROOT)})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
