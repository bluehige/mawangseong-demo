#!/usr/bin/env python3
"""Validate repository-owned STOVE release inputs and report external gates."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONFIG = ROOT / "stove/release_config.json"
REQUIRED_DOCUMENTS = (
    "docs/release/STOVE_RELEASE_MASTER_PLAN.md",
    "docs/release/STOVE_OWNER_ACTIONS.md",
    "stove/store/STUDIO_PORTAL_VALUES.md",
    "stove/store/STORE_PAGE_COPY.md",
    "stove/ratings/GAME_MANUAL.md",
    "stove/ratings/RATING_SUBMISSION_DRAFT.md",
    "stove/ratings/VIDEO_CAPTURE_PLAN.md",
    "stove/ratings/language_text.tsv",
    "stove/ratings/illustration_manifest.tsv",
    "marketing/stove/README.md",
    "marketing/stove/ARTWORK_PROVENANCE.md",
)
REQUIRED_IMAGES = {
    "marketing/stove/store/title_square_500.png": (500, 500),
    "marketing/stove/store/title_landscape_757x426.png": (757, 426),
    "marketing/stove/store/pc_thumbnail_500.png": (500, 500),
    "marketing/stove/icons/windows_desktop.ico": (256, 256),
}


def load_config(path: Path = DEFAULT_CONFIG) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def placeholder_paths(value: Any, prefix: str = "$") -> list[str]:
    found: list[str] = []
    if isinstance(value, str) and "REPLACE_" in value:
        found.append(prefix)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            found.extend(placeholder_paths(child, f"{prefix}[{index}]"))
    elif isinstance(value, dict):
        for key, child in value.items():
            found.extend(placeholder_paths(child, f"{prefix}.{key}"))
    return found


def image_size(path: Path) -> tuple[int, int]:
    with Image.open(path) as image:
        return image.size


def line_count(path: Path) -> int:
    with path.open(encoding="utf-8-sig") as handle:
        return sum(1 for _ in handle)


def validate(root: Path = ROOT, config_path: Path | None = None) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    pending: list[str] = []
    selected_config = config_path or root / "stove/release_config.json"
    if not selected_config.is_file():
        return [f"missing config: {selected_config}"], []
    config = load_config(selected_config)

    if config.get("schema_version") != 1:
        errors.append("unsupported stove/release_config.json schema_version")
    if config.get("product", {}).get("product_type") != "BASIC":
        errors.append("the paid base game must use product_type BASIC")
    if config.get("build", {}).get("status") != "blocked_until_audio_is_final" and not config.get("release_gates", {}).get("audio_finalized"):
        errors.append("build status must remain blocked until audio_finalized is true")

    for relative in REQUIRED_DOCUMENTS:
        path = root / relative
        if not path.is_file() or path.stat().st_size == 0:
            errors.append(f"missing or empty required document: {relative}")

    for relative, expected in REQUIRED_IMAGES.items():
        path = root / relative
        if not path.is_file():
            errors.append(f"missing required image: {relative}")
            continue
        actual = image_size(path)
        if actual != expected:
            errors.append(f"wrong image size: {relative}: expected {expected}, got {actual}")

    screenshot_dir = root / "marketing/stove/screenshots"
    screenshots = sorted(screenshot_dir.glob("*.png")) if screenshot_dir.is_dir() else []
    if len(screenshots) < 5:
        errors.append(f"at least five STOVE screenshots required, found {len(screenshots)}")
    for screenshot in screenshots:
        actual = image_size(screenshot)
        if actual != (860, 483):
            errors.append(f"wrong screenshot size: {screenshot.relative_to(root)}: {actual}")

    language_file = root / config.get("rating", {}).get("language_file", "")
    illustration_file = root / config.get("rating", {}).get("illustration_manifest", "")
    if language_file.is_file() and line_count(language_file) < 2:
        errors.append("language_text.tsv contains no reviewable text")
    if illustration_file.is_file() and line_count(illustration_file) < 2:
        errors.append("illustration_manifest.tsv contains no runtime images")

    pending.extend(f"placeholder:{path}" for path in placeholder_paths(config))
    for gate, complete in config.get("release_gates", {}).items():
        if complete is not True:
            pending.append(f"gate:{gate}")
    return errors, pending


def exit_code(errors: list[str], pending: list[str], strict: bool) -> int:
    if errors:
        return 1
    if strict and pending:
        return 1
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--strict", action="store_true", help="fail on placeholders and incomplete external gates")
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    args = parser.parse_args()

    errors, pending = validate(ROOT, args.config)
    for item in errors:
        print(f"ERROR: {item}")
    for item in pending:
        print(f"PENDING: {item}")
    if errors:
        print(f"STOVE_RELEASE: FAIL ({len(errors)} setup errors)")
    elif pending:
        print(f"STOVE_RELEASE: SETUP_PASS ({len(pending)} external/final gates pending)")
    else:
        print("STOVE_RELEASE: PASS")
    return exit_code(errors, pending, args.strict)


if __name__ == "__main__":
    raise SystemExit(main())
