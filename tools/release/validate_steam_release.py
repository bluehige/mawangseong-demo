#!/usr/bin/env python3
"""Validate repository, storefront, and Windows depot Steam release readiness."""

from __future__ import annotations

import argparse
import configparser
import hashlib
import json
import re
import struct
import sys
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
PLACEHOLDER_PREFIX = "REPLACE_WITH_"
EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
COMMIT_RE = re.compile(r"^[0-9a-f]{40}$")
SEMVER_RE = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$")

EXACT_ASSETS = {
    "store/header_capsule.png": (920, 430),
    "store/small_capsule.png": (462, 174),
    "store/main_capsule.png": (1232, 706),
    "store/vertical_capsule.png": (748, 896),
    "library/capsule.png": (600, 900),
    "library/hero.png": (3840, 1240),
    "library/header.png": (920, 430),
    "icons/shortcut.png": (256, 256),
    "icons/app_icon.jpg": (184, 184),
}
REQUIRED_REPOSITORY_FILES = (
    "steam/store/STORE_PAGE_COPY.md",
    "steam/store/CONTENT_SURVEY_DRAFT.md",
    "steam/store/STEAMWORKS_PORTAL_VALUES.md",
    "docs/release/STEAM_RELEASE_MASTER_PLAN.md",
    "docs/release/OWNER_ACTIONS.md",
    "legal/PRIVACY_POLICY_KO_EN.md",
    "legal/THIRD_PARTY_NOTICES.txt",
    "assets/fonts/NotoSansCJK_LICENSE.txt",
    "assets/fonts/NEXON_Maplestory_LICENSE.txt",
)
REQUIRED_GATE_FLAGS = (
    "legal_name_confirmed",
    "support_contact_confirmed",
    "rights_audit_complete",
    "content_survey_reviewed",
    "store_copy_approved",
    "store_graphics_reviewed",
    "system_requirements_measured",
    "steam_cloud_tested_on_two_pcs",
    "steam_install_launch_uninstall_tested",
    "valve_store_review_approved",
    "valve_build_review_approved",
)
FORBIDDEN_BUILD_NAMES = {
    "steam_appid.txt",
    ".git",
    ".godot",
}
FORBIDDEN_BUILD_SUFFIXES = {
    ".pdb",
    ".gd",
    ".tscn",
    ".import",
    ".uid",
}
FORBIDDEN_PCK_PREFIXES = (
    "addons/steam_release_export_filter/",
    "assets/source/",
    "docs/",
    "legal/",
    "marketing/",
    "output/",
    "steam/",
    "tmp/",
    "tools/",
    "web_Demo/",
    "참고자료/",
    "mawang_guideline_pack/",
    "mawang_quarterview_tilegrid_docs/",
)
FORBIDDEN_PCK_FILES = {
    "castle_management_ui_reference.png",
    "monster_management_ui_reference.png",
    "topview_battle_ui_reference.png",
}
REQUIRED_PCK_AUDIO_SAMPLES = (
    "combat_boss_council.wav",
    "combat_dungeon_pressure.wav",
    "management_castle_bustle.wav",
)
PCK_HEADER_MAGIC = 0x43504447
PCK_DIR_ENCRYPTED = 1 << 0


class ValidationResult:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []

    def require(self, condition: bool, message: str) -> None:
        if not condition:
            self.errors.append(message)

    def pending(self, condition: bool, message: str, strict: bool) -> None:
        if condition:
            return
        (self.errors if strict else self.warnings).append(message)


def load_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise ValueError(f"configuration does not exist: {path}") from error
    except json.JSONDecodeError as error:
        raise ValueError(f"configuration is not valid JSON: {error}") from error
    if not isinstance(data, dict):
        raise ValueError("configuration root must be an object")
    return data


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _read_exact(file: Any, size: int) -> bytes:
    data = file.read(size)
    if len(data) != size:
        raise ValueError("truncated PCK directory")
    return data


def list_pck_paths(path: Path) -> list[str]:
    """Read unencrypted Godot PCK v2/v3 directory entries."""
    with path.open("rb") as file:
        magic = struct.unpack("<I", _read_exact(file, 4))[0]
        if magic != PCK_HEADER_MAGIC:
            raise ValueError("invalid Godot PCK magic")
        version, _major, _minor, _patch, flags = struct.unpack(
            "<5I", _read_exact(file, 20)
        )
        _read_exact(file, 8)  # File data base offset.
        if flags & PCK_DIR_ENCRYPTED:
            raise ValueError("encrypted PCK directories cannot be audited")
        if version == 3:
            directory_offset = struct.unpack("<Q", _read_exact(file, 8))[0]
            file.seek(directory_offset)
        elif version == 2:
            _read_exact(file, 16 * 4)  # Reserved header fields.
        else:
            raise ValueError(f"unsupported Godot PCK version: {version}")

        file_count = struct.unpack("<I", _read_exact(file, 4))[0]
        if file_count > 10_000_000:
            raise ValueError("implausible Godot PCK file count")
        paths: list[str] = []
        for _ in range(file_count):
            string_length = struct.unpack("<I", _read_exact(file, 4))[0]
            if string_length > 16 * 1024 * 1024:
                raise ValueError("implausible Godot PCK path length")
            raw_path = _read_exact(file, string_length).rstrip(b"\0")
            try:
                paths.append(raw_path.decode("utf-8"))
            except UnicodeDecodeError as error:
                raise ValueError("invalid UTF-8 path in Godot PCK directory") from error
            _read_exact(file, 8 + 8 + 16 + 4)  # Offset, size, MD5, flags.
        return paths


def _jpeg_size(data: bytes) -> tuple[int, int]:
    if not data.startswith(b"\xff\xd8"):
        raise ValueError("not a JPEG file")
    position = 2
    while position + 9 <= len(data):
        if data[position] != 0xFF:
            position += 1
            continue
        marker = data[position + 1]
        position += 2
        if marker in (0xD8, 0xD9):
            continue
        if position + 2 > len(data):
            break
        length = struct.unpack(">H", data[position : position + 2])[0]
        if length < 2 or position + length > len(data):
            break
        if marker in {
            0xC0,
            0xC1,
            0xC2,
            0xC3,
            0xC5,
            0xC6,
            0xC7,
            0xC9,
            0xCA,
            0xCB,
            0xCD,
            0xCE,
            0xCF,
        }:
            height, width = struct.unpack(">HH", data[position + 3 : position + 7])
            return width, height
        position += length
    raise ValueError("JPEG dimensions could not be read")


def image_info(path: Path) -> tuple[int, int, bool]:
    data = path.read_bytes()
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        if len(data) < 26 or data[12:16] != b"IHDR":
            raise ValueError("invalid PNG header")
        width, height = struct.unpack(">II", data[16:24])
        color_type = data[25]
        return width, height, color_type in (4, 6)
    if data.startswith(b"\xff\xd8"):
        width, height = _jpeg_size(data)
        return width, height, False
    raise ValueError("only PNG and JPEG assets are supported")


def _is_positive_id(value: Any) -> bool:
    return type(value) is int and value > 0


def _is_placeholder(value: Any) -> bool:
    return not isinstance(value, str) or not value or value.startswith(PLACEHOLDER_PREFIX)


def _project_metadata(root: Path, result: ValidationResult) -> tuple[str, str, str]:
    project_file = root / "project.godot"
    if not project_file.is_file():
        result.errors.append("project.godot is missing")
        return "", "", ""
    text = project_file.read_text(encoding="utf-8")
    name_match = re.search(r'^config/name="([^"]+)"$', text, re.MULTILINE)
    version_match = re.search(r'^config/version="([^"]+)"$', text, re.MULTILINE)
    custom_dir_match = re.search(r'^config/custom_user_dir_name="([^"]+)"$', text, re.MULTILINE)
    uses_custom_dir = re.search(r'^config/use_custom_user_dir=true$', text, re.MULTILINE) is not None
    result.require(name_match is not None, "project.godot config/name is missing")
    result.require(version_match is not None, "project.godot config/version is missing")
    project_name = name_match.group(1) if name_match else ""
    user_dir = (
        custom_dir_match.group(1)
        if uses_custom_dir and custom_dir_match
        else project_name if uses_custom_dir
        else f"Godot/app_userdata/{project_name}"
    )
    return (
        project_name,
        version_match.group(1) if version_match else "",
        user_dir,
    )


def _validate_export_preset(
    root: Path,
    expected_name: str,
    project_version: str,
    result: ValidationResult,
) -> None:
    path = root / "export_presets.cfg"
    if not path.is_file():
        result.errors.append("export_presets.cfg is missing")
        return
    parser = configparser.RawConfigParser(strict=False)
    parser.read(path, encoding="utf-8")
    preset_section = ""
    for section in parser.sections():
        if not re.fullmatch(r"preset\.\d+", section):
            continue
        if parser.get(section, "name", fallback="").strip('"') == expected_name:
            preset_section = section
            break
    if not preset_section:
        result.errors.append(f"Godot export preset is missing: {expected_name}")
        return
    custom_features = parser.get(preset_section, "custom_features", fallback="").strip('"')
    result.require(
        "steam" in {feature.strip() for feature in custom_features.split(",")},
        f"{expected_name} must include the steam custom feature",
    )
    result.require(
        parser.get(preset_section, "export_filter", fallback="").strip('"') == "exclude",
        f"{expected_name} must use the resource exclusion export mode",
    )
    export_files = parser.get(preset_section, "export_files", fallback="")
    for resource in (
        "res://addons/steam_release_export_filter/plugin.gd",
        "res://addons/steam_release_export_filter/steam_release_export_filter.gd",
    ):
        result.require(
            resource in export_files,
            f"{expected_name} must exclude its export plugin resource: {resource}",
        )
    options = f"{preset_section}.options"
    result.require(parser.has_section(options), f"{expected_name} options are missing")
    if not parser.has_section(options):
        return
    expected_windows_version = f"{project_version}.0"
    file_version = parser.get(options, "application/file_version", fallback="").strip('"')
    product_version = parser.get(options, "application/product_version", fallback="").strip('"')
    result.require(
        file_version == expected_windows_version,
        f"{expected_name} file version must be {expected_windows_version}",
    )
    result.require(
        product_version == expected_windows_version,
        f"{expected_name} product version must be {expected_windows_version}",
    )
    result.require(
        parser.get(options, "binary_format/embed_pck", fallback="true").lower() == "false",
        f"{expected_name} must keep the PCK separate for signing and depot inspection",
    )


def _validate_assets(
    root: Path,
    assets_root: Path,
    result: ValidationResult,
    strict: bool,
) -> None:
    for relative, expected in EXACT_ASSETS.items():
        path = assets_root / relative
        result.pending(path.is_file(), f"required Steam asset is missing: {path.relative_to(root)}", strict)
        if not path.is_file():
            continue
        try:
            width, height, _ = image_info(path)
        except ValueError as error:
            result.errors.append(f"invalid Steam asset {path.relative_to(root)}: {error}")
            continue
        result.require(
            (width, height) == expected,
            f"{path.relative_to(root)} must be {expected[0]}x{expected[1]}, got {width}x{height}",
        )

    logo = assets_root / "library/logo.png"
    result.pending(logo.is_file(), f"required Steam asset is missing: {logo.relative_to(root)}", strict)
    if logo.is_file():
        try:
            width, height, has_alpha = image_info(logo)
            result.require(
                width == 1280 or height == 720,
                f"{logo.relative_to(root)} must be 1280 px wide or 720 px tall",
            )
            result.require(has_alpha, f"{logo.relative_to(root)} must be a transparent PNG")
        except ValueError as error:
            result.errors.append(f"invalid Steam asset {logo.relative_to(root)}: {error}")

    screenshots_dir = assets_root / "screenshots"
    screenshots = []
    if screenshots_dir.is_dir():
        screenshots = sorted(
            path
            for path in screenshots_dir.iterdir()
            if path.is_file() and path.suffix.lower() in {".png", ".jpg", ".jpeg"}
        )
    result.pending(
        len(screenshots) >= 5,
        f"at least five gameplay screenshots are required in {screenshots_dir.relative_to(root)}",
        strict,
    )
    for path in screenshots:
        try:
            width, height, _ = image_info(path)
        except ValueError as error:
            result.errors.append(f"invalid screenshot {path.relative_to(root)}: {error}")
            continue
        result.require(
            width >= 1920 and height >= 1080,
            f"{path.relative_to(root)} must be at least 1920x1080",
        )
        result.require(
            abs(width / height - 16 / 9) <= 0.02,
            f"{path.relative_to(root)} must use a 16:9 aspect ratio",
        )


def _validate_build(
    root: Path,
    build_dir: Path,
    executable: str,
    pck: str,
    project_version: str,
    result: ValidationResult,
) -> None:
    if not build_dir.is_dir():
        result.errors.append(f"Steam build directory does not exist: {build_dir}")
        return
    result.require((build_dir / executable).is_file(), f"Steam build is missing {executable}")
    result.require((build_dir / pck).is_file(), f"Steam build is missing {pck}")
    pck_path = build_dir / pck
    if pck_path.is_file():
        try:
            pck_paths = list_pck_paths(pck_path)
        except (OSError, ValueError) as error:
            result.errors.append(f"Steam PCK could not be audited: {error}")
        else:
            normalized_pck_paths = {
                packed_path.removeprefix("res://").replace("\\", "/")
                for packed_path in pck_paths
            }
            for normalized in normalized_pck_paths:
                if normalized in FORBIDDEN_PCK_FILES or normalized.startswith(FORBIDDEN_PCK_PREFIXES):
                    result.errors.append(f"development-only resource in Steam PCK: {normalized}")
            for audio_name in REQUIRED_PCK_AUDIO_SAMPLES:
                sample_prefix = f".godot/imported/{audio_name}-"
                result.require(
                    any(
                        packed_path.startswith(sample_prefix)
                        and packed_path.endswith(".sample")
                        for packed_path in normalized_pck_paths
                    ),
                    f"Steam PCK is missing required runtime audio sample: {audio_name}",
                )
    for relative in (
        "THIRD_PARTY_NOTICES.txt",
        "licenses/NotoSansCJK_LICENSE.txt",
        "licenses/NEXON_Maplestory_LICENSE.txt",
    ):
        result.require((build_dir / relative).is_file(), f"Steam build is missing {relative}")

    for path in build_dir.rglob("*"):
        if not path.is_file():
            continue
        relative = path.relative_to(build_dir)
        lower_parts = {part.lower() for part in relative.parts}
        if path.name.lower() in FORBIDDEN_BUILD_NAMES or lower_parts & FORBIDDEN_BUILD_NAMES:
            result.errors.append(f"forbidden file in Steam depot: {relative.as_posix()}")
        if path.suffix.lower() in FORBIDDEN_BUILD_SUFFIXES:
            result.errors.append(f"source/debug file in Steam depot: {relative.as_posix()}")

    manifest_path = build_dir / "steam-build-manifest.json"
    if not manifest_path.is_file():
        result.errors.append("Steam build is missing steam-build-manifest.json")
        return
    try:
        manifest = load_json(manifest_path)
    except ValueError as error:
        result.errors.append(str(error))
        return
    result.require(manifest.get("schema_version") == 1, "Steam build manifest schema_version must be 1")
    result.require(manifest.get("version") == project_version, "Steam build version must match project.godot")
    result.require(manifest.get("tag") == f"v{project_version}", "Steam build tag must match the project version")
    result.require(
        isinstance(manifest.get("source_commit"), str)
        and COMMIT_RE.fullmatch(manifest["source_commit"]) is not None,
        "Steam build source_commit must be a full lowercase commit SHA",
    )
    artifacts = manifest.get("artifacts")
    if not isinstance(artifacts, list) or not artifacts:
        result.errors.append("Steam build manifest artifacts must be a non-empty array")
        return
    listed: set[str] = set()
    for row in artifacts:
        if not isinstance(row, dict) or not {"path", "bytes", "sha256"} <= row.keys():
            result.errors.append("each Steam build artifact requires path, bytes, and sha256")
            continue
        relative = Path(str(row["path"]))
        normalized = relative.as_posix()
        if relative.is_absolute() or ".." in relative.parts:
            result.errors.append(f"manifest artifact escapes build root: {normalized}")
            continue
        if normalized in listed:
            result.errors.append(f"duplicate manifest artifact: {normalized}")
            continue
        listed.add(normalized)
        full = build_dir / relative
        if not full.is_file():
            result.errors.append(f"manifest artifact does not exist: {normalized}")
            continue
        if type(row["bytes"]) is not int or row["bytes"] != full.stat().st_size:
            result.errors.append(f"manifest byte size mismatch: {normalized}")
        if not isinstance(row["sha256"], str) or not SHA256_RE.fullmatch(row["sha256"]):
            result.errors.append(f"manifest SHA-256 is invalid: {normalized}")
        elif row["sha256"] != sha256(full):
            result.errors.append(f"manifest SHA-256 mismatch: {normalized}")
    actual = {
        path.relative_to(build_dir).as_posix()
        for path in build_dir.rglob("*")
        if path.is_file() and path != manifest_path
    }
    result.require(actual == listed, "Steam build manifest must list every depot file exactly once")


def validate(
    config: dict[str, Any],
    root: Path = REPO_ROOT,
    strict: bool = False,
    build_dir: Path | None = None,
    today: date | None = None,
) -> ValidationResult:
    result = ValidationResult()
    result.require(config.get("schema_version") == 1, "schema_version must be 1")
    for key in ("product", "build", "store", "cloud", "release_gates"):
        result.require(isinstance(config.get(key), dict), f"{key} must be an object")
    if result.errors:
        return result

    product = config["product"]
    build = config["build"]
    store = config["store"]
    cloud = config["cloud"]
    gates = config["release_gates"]

    result.require(product.get("name_ko") == "마왕님, 마왕성은 누가 지켜요?", "canonical Korean title is inconsistent")
    result.require(product.get("release_model") == "full_release", "release_model must be full_release")
    result.require(product.get("supported_os") == ["windows"], "initial release must truthfully list Windows only")
    languages = product.get("supported_languages")
    result.require(isinstance(languages, dict) and bool(languages.get("koreana", {}).get("interface")), "Korean interface support must be declared")
    result.pending(_is_positive_id(product.get("app_id")), "Steam App ID has not been assigned", strict)
    result.pending(_is_positive_id(product.get("windows_depot_id")), "Windows Depot ID has not been assigned", strict)
    if product.get("coming_soon_then_demo"):
        result.pending(_is_positive_id(product.get("demo_app_id")), "Steam Demo App ID has not been assigned", strict)

    project_name, project_version, expected_cloud_subdir = _project_metadata(root, result)
    result.require(project_name == product.get("name_ko"), "runtime project title must match the Korean Steam title")
    result.require(SEMVER_RE.fullmatch(project_version) is not None, "project version must be stable SemVer without a v prefix")
    result.require(build.get("godot_version") == "4.5.2", "Steam build must pin Godot 4.5.2")
    result.require(build.get("architecture") == "x86_64", "Steam build architecture must be x86_64")
    result.require(build.get("steamworks_runtime_api") is False, "runtime Steamworks API declaration must match the current unintegrated build")
    executable = build.get("executable")
    pck = build.get("pck")
    result.require(isinstance(executable, str) and Path(executable).name == executable and executable.lower().endswith(".exe"), "build.executable must be a depot-root .exe filename")
    result.require(isinstance(pck, str) and Path(pck).name == pck and pck.lower().endswith(".pck"), "build.pck must be a depot-root .pck filename")
    _validate_export_preset(root, str(build.get("export_preset", "")), project_version, result)

    result.require(cloud.get("root") == "WinAppDataRoaming", "Steam Auto-Cloud root must be WinAppDataRoaming")
    result.require(cloud.get("subdirectory") == expected_cloud_subdir, "Steam Auto-Cloud subdirectory must match Godot user://")
    patterns = cloud.get("patterns")
    result.require(isinstance(patterns, list) and "campaign_save_v5.json" in patterns, "Steam Cloud must include the current v5 save")
    result.require(isinstance(patterns, list) and "quarter_custom_layouts.json" in patterns, "Steam Cloud must include custom layouts")
    result.require(isinstance(patterns, list) and "settings.cfg" not in patterns, "machine/user preference settings must not be synced")
    result.require(type(cloud.get("byte_quota")) is int and cloud["byte_quota"] >= 1024 * 1024, "Steam Cloud byte quota is too small")
    result.require(type(cloud.get("file_quota")) is int and cloud["file_quota"] >= len(patterns or []), "Steam Cloud file quota is too small")

    for relative in REQUIRED_REPOSITORY_FILES:
        result.require((root / relative).is_file(), f"required release file is missing: {relative}")
    project_text = (root / "project.godot").read_text(encoding="utf-8")
    plugin_path = "res://addons/steam_release_export_filter/plugin.cfg"
    result.require(plugin_path in project_text, "Steam release export filter plugin is not enabled")
    for relative in (
        "addons/steam_release_export_filter/plugin.cfg",
        "addons/steam_release_export_filter/plugin.gd",
        "addons/steam_release_export_filter/steam_release_export_filter.gd",
    ):
        result.require((root / relative).is_file(), f"Steam release export filter is missing: {relative}")
    source_docs = list((root / "assets/source/imagegen").rglob("SOURCE.md"))
    result.require(bool(source_docs), "AI-generated art provenance records are missing")
    content_survey_path = root / str(store.get("content_survey", ""))
    if content_survey_path.is_file():
        survey = content_survey_path.read_text(encoding="utf-8")
        result.require("Pre-Generated" in survey and "SOURCE.md" in survey, "content survey must disclose pre-generated AI and provenance")

    email = store.get("support_email")
    result.pending(
        isinstance(email, str) and not _is_placeholder(email) and EMAIL_RE.fullmatch(email) is not None,
        "public support email is still a placeholder",
        strict,
    )
    privacy_path = root / str(store.get("privacy_policy", ""))
    if privacy_path.is_file():
        privacy = privacy_path.read_text(encoding="utf-8")
        result.pending(PLACEHOLDER_PREFIX not in privacy, "privacy policy still contains public placeholders", strict)

    assets_root = root / str(store.get("assets_root", ""))
    result.require(root in assets_root.resolve().parents or assets_root.resolve() == root, "store assets root must stay inside the repository")
    _validate_assets(root, assets_root, result, strict)

    for flag in REQUIRED_GATE_FLAGS:
        result.pending(gates.get(flag) is True, f"release gate is incomplete: {flag}", strict)
    coming_since = gates.get("coming_soon_since")
    if not isinstance(coming_since, str) or not coming_since:
        result.pending(False, "Coming Soon publication date has not been recorded", strict)
    else:
        try:
            published = date.fromisoformat(coming_since)
            elapsed = (today or datetime.now(timezone.utc).date()) - published
            result.pending(elapsed.days >= 14, "Coming Soon page has not been public for 14 days", strict)
        except ValueError:
            result.errors.append("coming_soon_since must use YYYY-MM-DD")

    if build_dir is not None:
        _validate_build(root, build_dir.resolve(), str(executable), str(pck), project_version, result)
    elif strict:
        result.errors.append("--strict requires --build-dir for the final Steam depot")
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--config",
        type=Path,
        default=REPO_ROOT / "steam/release_config.json",
        help="tracked Steam release configuration",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="treat every external placeholder and release gate as blocking",
    )
    parser.add_argument(
        "--build-dir",
        type=Path,
        help="validate an exported Windows Steam depot directory",
    )
    args = parser.parse_args()
    try:
        config = load_json(args.config.resolve())
    except ValueError as error:
        print(f"STEAM_RELEASE: FAIL: {error}", file=sys.stderr)
        raise SystemExit(1) from error
    result = validate(config, REPO_ROOT, args.strict, args.build_dir)
    for warning in result.warnings:
        print(f"STEAM_RELEASE: PENDING: {warning}")
    if result.errors:
        for error in result.errors:
            print(f"STEAM_RELEASE: FAIL: {error}", file=sys.stderr)
        raise SystemExit(1)
    status = "READY" if args.strict else "SETUP_PASS"
    print(f"STEAM_RELEASE: {status} ({len(result.warnings)} pending external items)")


if __name__ == "__main__":
    main()
