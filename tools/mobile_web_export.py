#!/usr/bin/env python3
"""Build an isolated, illustration-optimized Web PCK for mobile browsers."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys


MOBILE_ILLUSTRATION_PREFIXES = (
    Path("assets/sprites/portraits"),
    Path("assets/ui/endings"),
    Path("assets/ui/regions"),
    Path("assets/ui/onboarding"),
    Path("assets/backgrounds"),
)
MOBILE_LOSSY_QUALITY = 0.90
MOBILE_ILLUSTRATION_SIZE_LIMIT = 1280
EXPECTED_IMPORT_COUNT = 134
ROOT_COPY_EXCLUDES = {
    ".git",
    ".godot",
    "builds",
    "docs",
    "output",
    "tmp",
    "tools",
    "web_Demo",
}


def discover_mobile_imports(project_root: Path) -> list[Path]:
    imports: list[Path] = []
    for relative_prefix in MOBILE_ILLUSTRATION_PREFIXES:
        imports.extend((project_root / relative_prefix).rglob("*.png.import"))
    return sorted(imports)


def apply_mobile_import_overrides(project_root: Path) -> int:
    changed = 0
    for import_path in discover_mobile_imports(project_root):
        content = import_path.read_text(encoding="utf-8")
        if "compress/mode=0" not in content:
            raise ValueError(f"mobile illustration is not lossless before staging: {import_path}")
        updated = content.replace("compress/mode=0", "compress/mode=1", 1)
        updated = updated.replace(
            "compress/lossy_quality=0.7",
            f"compress/lossy_quality={MOBILE_LOSSY_QUALITY}",
            1,
        )
        updated = updated.replace(
            "process/size_limit=0",
            f"process/size_limit={MOBILE_ILLUSTRATION_SIZE_LIMIT}",
            1,
        )
        if updated == content:
            raise ValueError(f"mobile import override did not change: {import_path}")
        import_path.write_text(updated, encoding="utf-8", newline="\n")
        changed += 1
    return changed


def _copy_ignore(project_root: Path):
    assets_root = project_root / "assets"

    def ignore(directory: str, names: list[str]) -> set[str]:
        current = Path(directory)
        ignored: set[str] = set()
        if current == project_root:
            ignored.update(name for name in names if name in ROOT_COPY_EXCLUDES)
        if current == assets_root and "source" in names:
            ignored.add("source")
        ignored.update(name for name in names if name == "__pycache__")
        return ignored

    return ignore


def _replace_directory(path: Path, allowed_parent: Path) -> None:
    resolved = path.resolve()
    parent = allowed_parent.resolve()
    if not resolved.is_relative_to(parent) or resolved == parent:
        raise ValueError(f"refusing to replace path outside {parent}: {resolved}")
    if resolved.exists():
        shutil.rmtree(resolved)


def prepare_staging_project(project_root: Path, staging_root: Path) -> int:
    tmp_root = project_root / "tmp"
    _replace_directory(staging_root, tmp_root)
    shutil.copytree(project_root, staging_root, ignore=_copy_ignore(project_root))
    changed = apply_mobile_import_overrides(staging_root)
    if changed != EXPECTED_IMPORT_COUNT:
        raise ValueError(
            f"expected {EXPECTED_IMPORT_COUNT} mobile illustration imports, found {changed}"
        )
    return changed


def _run(command: list[str]) -> None:
    print("+", subprocess.list2cmdline(command), flush=True)
    subprocess.run(command, check=True)


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build_mobile_web(
    project_root: Path,
    godot: str,
    output_root: Path,
    keep_stage: bool,
) -> dict[str, object]:
    tmp_root = project_root / "tmp"
    staging_root = tmp_root / "mobile_web_stage"
    output_root = output_root.resolve()
    _replace_directory(output_root, tmp_root)
    output_root.mkdir(parents=True)

    changed = prepare_staging_project(project_root, staging_root)
    try:
        _run([godot, "--headless", "--editor", "--path", str(staging_root), "--import"])
        output_html = output_root / "index.html"
        _run(
            [
                godot,
                "--headless",
                "--path",
                str(staging_root),
                "--export-release",
                "Web Mobile",
                str(output_html),
            ]
        )
        pck_path = output_root / "index.pck"
        wasm_path = output_root / "index.wasm"
        if not output_html.is_file() or not pck_path.is_file() or not wasm_path.is_file():
            raise FileNotFoundError("mobile Web export did not produce HTML, PCK, and WASM")
        result: dict[str, object] = {
            "optimized_imports": changed,
            "lossy_quality": MOBILE_LOSSY_QUALITY,
            "illustration_size_limit": MOBILE_ILLUSTRATION_SIZE_LIMIT,
            "pck_bytes": pck_path.stat().st_size,
            "pck_sha256": _sha256(pck_path),
            "wasm_bytes": wasm_path.stat().st_size,
            "output": str(output_root),
        }
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return result
    finally:
        if not keep_stage and staging_root.exists():
            _replace_directory(staging_root, tmp_root)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
    )
    parser.add_argument("--godot", default=os.environ.get("GODOT", "godot"))
    parser.add_argument("--output", type=Path)
    parser.add_argument("--keep-stage", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    project_root = args.project_root.resolve()
    output_root = (
        args.output.resolve()
        if args.output
        else project_root / "tmp" / "mobile_web_export"
    )
    try:
        build_mobile_web(project_root, args.godot, output_root, args.keep_stage)
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f"mobile Web export failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
