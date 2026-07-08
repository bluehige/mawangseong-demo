from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "output" / "imagegen"
OUT_DIR = SOURCE_DIR / "castle_contract_proofs"
QA_DIR = SOURCE_DIR / "castle_contract_qa"

BITS = {"N": 1, "E": 2, "S": 4, "W": 8}
FACING_KEYS = ["NW", "NE", "SE", "SW"]
OBJECT_ROWS = [
    "entrance_gate",
    "throne",
    "barracks",
    "recovery_nest",
    "treasure_storage",
    "watch_post",
    "build_foundation",
]

DEFAULT_ROOM_VARIANTS = [
    ("entrance", "entrance_gate_f", "SE", 10, ["E", "W"]),
    ("throne", "throne_f", "SW", 4, ["S"]),
    ("barracks", "weapon_rack", "SE", 2, ["E"]),
    ("recovery", "recovery_nest_f", "NW", 8, ["W"]),
    ("treasure", "treasure_pile_large", "NW", 8, ["W"]),
    ("slot_01", "foundation_marks", "NE", 1, ["N"]),
]

PATH_COMPONENTS = [
    "path_strip_ns_2w",
    "path_strip_ew_2w",
    "path_junction_2x2",
    "path_mouth_N_2cell",
    "path_mouth_E_2cell",
    "path_mouth_S_2cell",
    "path_mouth_W_2cell",
    "path_spike_insert_2x2",
]

SOURCES = {
    "direction_atlas": SOURCE_DIR / "castle_upgrade_direction_facing_atlas_stage01_gpt_image2_2026-07-08_alpha.png",
    "default_rooms": SOURCE_DIR / "castle_upgrade_default_room_variants_stage01_gpt_image2_2026-07-08_alpha.png",
    "open_masks": SOURCE_DIR / "castle_upgrade_throne_open_mask_16_stage01_gpt_image2_2026-07-08_alpha.png",
    "path_components": SOURCE_DIR / "castle_upgrade_path_component_atlas_stage01_gpt_image2_2026-07-08_alpha.png",
    "throne_facing_atlas": SOURCE_DIR / "castle_upgrade_throne_facing_atlas_stage01_gpt_image2_2026-07-08_alpha.png",
    "throne_sw_single": SOURCE_DIR / "castle_upgrade_throne_sw_stage01_gpt_image2_2026-07-08_alpha.png",
}


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def trim_alpha(image: Image.Image, padding: int = 16) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return image
    left, top, right, bottom = bbox
    return image.crop(
        (
            max(0, left - padding),
            max(0, top - padding),
            min(image.width, right + padding),
            min(image.height, bottom + padding),
        )
    )


def fit_on_canvas(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    fitted = trim_alpha(image)
    fitted.thumbnail((size[0] - 10, size[1] - 10), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    canvas.alpha_composite(fitted, ((size[0] - fitted.width) // 2, size[1] - fitted.height - 5))
    return canvas


def inset_box(left: int, top: int, right: int, bottom: int, inset_x: int = 8, inset_y: int = 8) -> tuple[int, int, int, int]:
    return (left + inset_x, top + inset_y, right - inset_x, bottom - inset_y)


def slice_grid(source_path: Path, rows: int, cols: int, names: list[str], out_subdir: str, canvas: tuple[int, int]) -> list[Path]:
    source = Image.open(source_path).convert("RGBA")
    cell_w = source.width // cols
    cell_h = source.height // rows
    out_dir = OUT_DIR / out_subdir
    out_dir.mkdir(parents=True, exist_ok=True)
    outputs: list[Path] = []
    for index, name in enumerate(names):
        row = index // cols
        col = index % cols
        left = col * cell_w
        top = row * cell_h
        right = source.width if col == cols - 1 else (col + 1) * cell_w
        bottom = source.height if row == rows - 1 else (row + 1) * cell_h
        sprite = fit_on_canvas(source.crop(inset_box(left, top, right, bottom)), canvas)
        out_path = out_dir / f"{name}_proof.png"
        sprite.save(out_path)
        outputs.append(out_path)
    return outputs


def make_preview(paths: list[Path], out_path: Path, cols: int, tile_size: tuple[int, int] = (230, 180)) -> None:
    thumbs: list[tuple[str, Image.Image]] = []
    for path in paths:
        image = Image.open(path).convert("RGBA")
        image.thumbnail((tile_size[0] - 12, tile_size[1] - 38), Image.Resampling.LANCZOS)
        thumbs.append((path.stem.replace("_proof", ""), image))

    rows = (len(thumbs) + cols - 1) // cols
    preview = Image.new("RGBA", (tile_size[0] * cols, tile_size[1] * rows), (18, 15, 22, 255))
    draw = ImageDraw.Draw(preview)
    font = ImageFont.load_default()
    for index, (name, image) in enumerate(thumbs):
        col = index % cols
        row = index // cols
        x = col * tile_size[0]
        y = row * tile_size[1]
        panel = Image.new("RGBA", tile_size, (32, 28, 40, 255))
        panel.alpha_composite(image, ((tile_size[0] - image.width) // 2, tile_size[1] - image.height - 8))
        preview.alpha_composite(panel, (x, y))
        draw.text((x + 8, y + 8), name[:34], fill=(226, 220, 238, 255), font=font)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    preview.save(out_path)


def slice_proofs() -> dict[str, int]:
    counts: dict[str, int] = {}

    direction_names = [
        f"prop_{object_id}_stage01_facing_{facing}"
        for object_id in OBJECT_ROWS
        for facing in FACING_KEYS
    ]
    direction_paths = slice_grid(SOURCES["direction_atlas"], 7, 4, direction_names, "direction_facing_stage01", (280, 220))
    make_preview(direction_paths, OUT_DIR / "direction_facing_stage01_preview.png", 4)
    counts["direction_facing_stage01"] = len(direction_paths)

    room_names = [
        f"room_{instance}_{object_id}_stage01_{facing}_open_{open_mask:02d}"
        for instance, object_id, facing, open_mask, _sides in DEFAULT_ROOM_VARIANTS
    ]
    room_paths = slice_grid(SOURCES["default_rooms"], 2, 3, room_names, "default_room_variants_stage01", (360, 270))
    make_preview(room_paths, OUT_DIR / "default_room_variants_stage01_preview.png", 3, (300, 240))
    counts["default_room_variants_stage01"] = len(room_paths)

    open_mask_names = [f"room_throne_f_stage01_SW_open_{mask:02d}" for mask in range(16)]
    open_mask_paths = slice_grid(SOURCES["open_masks"], 4, 4, open_mask_names, "throne_open_masks_stage01", (330, 250))
    make_preview(open_mask_paths, OUT_DIR / "throne_open_masks_stage01_preview.png", 4, (260, 210))
    counts["throne_open_masks_stage01"] = len(open_mask_paths)

    path_paths = slice_grid(SOURCES["path_components"], 2, 4, PATH_COMPONENTS, "path_components_stage01", (300, 220))
    make_preview(path_paths, OUT_DIR / "path_components_stage01_preview.png", 4)
    counts["path_components_stage01"] = len(path_paths)

    throne_atlas_names = [f"throne_f_stage01_requested_facing_{facing}" for facing in FACING_KEYS]
    throne_atlas_paths = slice_grid(SOURCES["throne_facing_atlas"], 1, 4, throne_atlas_names, "throne_direction_target_stage01", (300, 260))
    single = fit_on_canvas(Image.open(SOURCES["throne_sw_single"]).convert("RGBA"), (360, 320))
    single_dir = OUT_DIR / "throne_direction_target_stage01"
    single_dir.mkdir(parents=True, exist_ok=True)
    single_path = single_dir / "throne_f_stage01_SW_single_target_proof.png"
    single.save(single_path)
    throne_paths = throne_atlas_paths + [single_path]
    make_preview(throne_paths, OUT_DIR / "throne_direction_target_stage01_preview.png", 5, (260, 230))
    counts["throne_direction_target_stage01"] = len(throne_paths)

    return counts


def open_mask_from_sides(sides: list[str]) -> int:
    mask = 0
    for side in sides:
        mask += BITS.get(str(side), 0)
    return mask


def find_room_grid_cell(layout: dict[str, Any], instance_id: str) -> dict[str, Any]:
    for cell in layout.get("room_grid", {}).get("cells", []):
        if str(cell.get("instance_id", "")) == instance_id:
            return cell
    return {}


def add_check(checks: list[dict[str, Any]], check_id: str, ok: bool, detail: str) -> None:
    checks.append({"id": check_id, "ok": bool(ok), "detail": detail})


def validate_contracts() -> tuple[list[dict[str, Any]], dict[str, Any]]:
    layout = load_json(ROOT / "data" / "dungeon_quarter" / "starting_layout.json")
    modules = load_json(ROOT / "data" / "dungeon_quarter" / "room_blueprints.json")
    manifest = load_json(ROOT / "data" / "dungeon_quarter" / "asset_manifest.json")
    checks: list[dict[str, Any]] = []

    production_contract = manifest.get("room_object_production_contract", {})
    default_variants = production_contract.get("default_layout_required_variants", {})
    for instance, object_id, facing, open_mask, sides in DEFAULT_ROOM_VARIANTS:
        cell = find_room_grid_cell(layout, instance)
        actual_sides = [str(side) for side in cell.get("connected_sides", [])]
        actual_mask = open_mask_from_sides(actual_sides)
        manifest_variant = default_variants.get(instance, {})
        add_check(checks, f"{instance}.exists", bool(cell), f"room_grid cell found for {instance}")
        add_check(checks, f"{instance}.object", str(cell.get("object_id", "")) == object_id, f"{cell.get('object_id', '')} == {object_id}")
        add_check(checks, f"{instance}.facing", str(cell.get("object_facing", "")) == facing, f"{cell.get('object_facing', '')} == {facing}")
        add_check(checks, f"{instance}.open_mask", actual_mask == open_mask, f"{actual_sides} -> open_{actual_mask:02d}, expected open_{open_mask:02d}")
        add_check(checks, f"{instance}.manifest_variant", str(manifest_variant.get("facing", "")) == facing and int(manifest_variant.get("open_mask", -1)) == open_mask, f"manifest default variant {manifest_variant}")

    path_contract = manifest.get("path_connection_production_contract", {})
    connection_count = len(layout.get("connections", []))
    expected_connection_count = int(path_contract.get("required_connection_bridge_count", 14))
    expected_group_count = int(path_contract.get("required_path_mouth_group_count", 7))
    add_check(checks, "path.connection_segments", connection_count == expected_connection_count, f"{connection_count} bridge segments, expected {expected_connection_count}")
    add_check(checks, "path.mouth_groups", connection_count // 2 == expected_group_count, f"{connection_count // 2} paired mouths, expected {expected_group_count}")
    add_check(checks, "path.empty_macro_cells", not bool(path_contract.get("empty_macro_cells_are_floor", True)), "empty macro cells are not floor")
    add_check(checks, "path.width", int(path_contract.get("path_width_cells", 0)) == 2, f"path width {path_contract.get('path_width_cells', '')}")

    canonical = {
        "N": [[2, 0], [3, 0]],
        "E": [[4, 2], [4, 3]],
        "S": [[2, 4], [3, 4]],
        "W": [[0, 2], [0, 3]],
    }
    room_module_ids = [
        str(module.get("module_id", ""))
        for module in layout.get("placed_modules", [])
        if str(module.get("instance_id", "")) in {"entrance", "throne", "barracks", "recovery", "treasure", "slot_01"}
    ]
    for module_id in room_module_ids:
        module = modules.get(module_id, {})
        socket_entries = module.get("socket_entries", {})
        for side, expected_cells in canonical.items():
            actual = sorted([entry.get("cell", []) for entry in socket_entries.values() if str(entry.get("side", "")) == side])
            add_check(checks, f"{module_id}.socket_{side}", actual == expected_cells, f"{actual} == {expected_cells}")

    corridor_module_id = ""
    for module in layout.get("placed_modules", []):
        if str(module.get("instance_id", "")) == "spike_corridor":
            corridor_module_id = str(module.get("module_id", ""))
            break
    corridor = modules.get(corridor_module_id, {})
    add_check(checks, "corridor.module_exists", bool(corridor), f"spike corridor module {corridor_module_id}")
    add_check(checks, "corridor.module_matches_manifest", corridor_module_id == str(path_contract.get("corridor_module_id", "")), f"{corridor_module_id} == {path_contract.get('corridor_module_id', '')}")
    corridor_size = corridor.get("size", [0, 0])
    corridor_area = int(corridor_size[0]) * int(corridor_size[1]) if len(corridor_size) >= 2 else 0
    corridor_floor_count = len(corridor.get("floor_cells", []))
    add_check(checks, "corridor.floor_cells_sparse", 0 < corridor_floor_count < corridor_area, f"{corridor_floor_count} floor cells inside {corridor_area} cell module")
    add_check(checks, "corridor.trap_cells", len(corridor.get("trap_cells", [])) == 4, f"{len(corridor.get('trap_cells', []))} trap cells, expected 4")

    summary = {
        "ok": all(check["ok"] for check in checks),
        "total": len(checks),
        "passed": sum(1 for check in checks if check["ok"]),
        "failed": sum(1 for check in checks if not check["ok"]),
    }
    return checks, summary


def write_validation_report(checks: list[dict[str, Any]], summary: dict[str, Any], counts: dict[str, int]) -> None:
    QA_DIR.mkdir(parents=True, exist_ok=True)
    (QA_DIR / "castle_visual_contract_validation.json").write_text(
        json.dumps({"summary": summary, "slice_counts": counts, "checks": checks}, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )

    lines = [
        "# Castle Visual Contract Validation",
        "",
        "Generated: 2026-07-08",
        "",
        "## Summary",
        "",
        f"- Contract data check: {'PASS' if summary['ok'] else 'FAIL'}",
        f"- Passed: {summary['passed']} / {summary['total']}",
        f"- Failed: {summary['failed']}",
        "",
        "## Sliced Proof Counts",
        "",
    ]
    for key, value in counts.items():
        lines.append(f"- `{key}`: {value}")
    lines.extend(["", "## Contract Checks", ""])
    for check in checks:
        status = "PASS" if check["ok"] else "FAIL"
        lines.append(f"- `{status}` `{check['id']}`: {check['detail']}")
    lines.extend(
        [
            "",
            "## Manual Visual QA Notes",
            "",
            "- Data-level direction keys, open masks, socket pairs, and path segment counts pass when checked against JSON.",
            "- GPT image proofs are not automatically runtime-approved. They still need human visual approval for facing, doorway exactness, and 5x5 projection fit.",
            "- The broad 7x4 direction atlas is useful as visual exploration but not direction-accurate enough for production slicing.",
            "- The single `throne_f_stage01_SW_single_target_proof.png` is the strongest current SW-facing throne correction proof.",
            "- The 16-open-mask throne sheet is a proof only; several cells are visually too similar and should not be used as production open-mask sprites.",
        ]
    )
    (QA_DIR / "castle_visual_contract_validation.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def draw_room_grid_overlay() -> None:
    layout = load_json(ROOT / "data" / "dungeon_quarter" / "starting_layout.json")
    width, height = 1120, 760
    cell_w, cell_h = 250, 150
    origin_x, origin_y = 60, 70
    image = Image.new("RGBA", (width, height), (16, 14, 20, 255))
    draw = ImageDraw.Draw(image)
    font = ImageFont.load_default()
    title = "4x4 room contract QA: facing + open_mask + connected sides"
    draw.text((40, 24), title, fill=(238, 228, 190, 255), font=font)

    cells = layout.get("room_grid", {}).get("cells", [])
    for cell in cells:
        grid_id = str(cell.get("grid_id", ""))
        if not grid_id.startswith("G"):
            continue
        gx = int(grid_id[1:3])
        gy = int(grid_id[4:6])
        x = origin_x + gx * cell_w
        y = origin_y + gy * cell_h
        instance = str(cell.get("instance_id", ""))
        sides = [str(side) for side in cell.get("connected_sides", [])]
        mask = open_mask_from_sides(sides)
        is_room = instance != ""
        fill = (42, 36, 52, 255) if is_room else (24, 22, 28, 255)
        outline = (216, 170, 64, 255) if is_room else (72, 66, 82, 255)
        draw.rounded_rectangle((x, y, x + cell_w - 18, y + cell_h - 18), radius=8, fill=fill, outline=outline, width=2)
        draw.text((x + 10, y + 8), grid_id, fill=(160, 150, 176, 255), font=font)
        if is_room:
            lines = [
                instance,
                str(cell.get("object_id", "")),
                f"facing={cell.get('object_facing', '')}",
                f"open_{mask:02d} sides={','.join(sides)}",
            ]
            for idx, line in enumerate(lines):
                draw.text((x + 10, y + 32 + idx * 20), line, fill=(236, 230, 242, 255), font=font)

    # Draw a simple route skeleton between the occupied cells for QA readability.
    route_color = (232, 186, 66, 220)
    centers = {}
    for cell in cells:
        instance = str(cell.get("instance_id", ""))
        grid_id = str(cell.get("grid_id", ""))
        if instance and grid_id.startswith("G"):
            gx = int(grid_id[1:3])
            gy = int(grid_id[4:6])
            centers[instance] = (origin_x + gx * cell_w + cell_w * 0.5 - 9, origin_y + gy * cell_h + cell_h * 0.5 - 9)
    for a, b in [
        ("entrance", "barracks"),
        ("barracks", "throne"),
        ("barracks", "recovery"),
        ("entrance", "treasure"),
        ("treasure", "slot_01"),
    ]:
        if a in centers and b in centers:
            draw.line((centers[a], centers[b]), fill=route_color, width=5)
    out = QA_DIR / "castle_contract_room_grid_overlay.png"
    QA_DIR.mkdir(parents=True, exist_ok=True)
    image.save(out)


def draw_path_skeleton_overlay() -> None:
    layout = load_json(ROOT / "data" / "dungeon_quarter" / "starting_layout.json")
    modules = load_json(ROOT / "data" / "dungeon_quarter" / "room_blueprints.json")
    corridor_module_id = ""
    for module in layout.get("placed_modules", []):
        if str(module.get("instance_id", "")) == "spike_corridor":
            corridor_module_id = str(module.get("module_id", ""))
            break
    corridor = modules.get(corridor_module_id, {})
    module_size = corridor.get("size", [28, 26])
    module_w = int(module_size[0]) if len(module_size) >= 1 else 28
    module_h = int(module_size[1]) if len(module_size) >= 2 else 26
    tile = 24
    ox, oy = 46, 78
    width = ox * 2 + module_w * tile
    height = oy + module_h * tile + 92
    image = Image.new("RGBA", (width, height), (16, 14, 20, 255))
    draw = ImageDraw.Draw(image)
    font = ImageFont.load_default()
    draw.text((30, 24), f"Path skeleton QA: {corridor_module_id}", fill=(238, 228, 190, 255), font=font)
    floor = {tuple(cell) for cell in corridor.get("floor_cells", [])}
    traps = {tuple(cell) for cell in corridor.get("trap_cells", [])}
    socket_cells: dict[tuple[int, int], list[str]] = {}
    for socket_id, socket in corridor.get("socket_entries", {}).items():
        cell = tuple(socket.get("cell", []))
        socket_cells.setdefault(cell, []).append(str(socket.get("side", "")))
    for y in range(module_h):
        for x in range(module_w):
            px = ox + x * tile
            py = oy + y * tile
            key = (x, y)
            fill = (34, 30, 40, 255)
            if key in floor:
                fill = (80, 70, 62, 255)
            if key in traps:
                fill = (118, 50, 48, 255)
            draw.rectangle((px, py, px + tile - 4, py + tile - 4), fill=fill, outline=(76, 70, 86, 255))
            if key in socket_cells:
                draw.text((px + 6, py + 14), "".join(socket_cells[key]), fill=(245, 208, 80, 255), font=font)
    draw.text(
        (30, height - 70),
        f"{len(floor)} floor cells, {len(traps)} trap cells, paired socket mouths only",
        fill=(210, 202, 220, 255),
        font=font,
    )
    out = QA_DIR / "castle_contract_path_skeleton_overlay.png"
    QA_DIR.mkdir(parents=True, exist_ok=True)
    image.save(out)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    QA_DIR.mkdir(parents=True, exist_ok=True)
    counts = slice_proofs()
    checks, summary = validate_contracts()
    write_validation_report(checks, summary, counts)
    draw_room_grid_overlay()
    draw_path_skeleton_overlay()
    print(f"Sliced proof groups into {OUT_DIR}")
    print(f"Wrote QA outputs into {QA_DIR}")
    print(f"Contract validation: {'PASS' if summary['ok'] else 'FAIL'} ({summary['passed']}/{summary['total']})")


if __name__ == "__main__":
    main()
