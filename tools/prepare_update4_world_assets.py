"""Prepare Update 4 region, outpost, and upper-floor art from GPT sources."""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = ROOT / "assets/source/imagegen/update4_world_phase34"
REGION_ROOT = ROOT / "assets/ui/regions/update4"
OUTPOST_ROOT = ROOT / "assets/ui/outpost/update4"
UPPER_TILE_ROOT = ROOT / "assets/tiles/update4/upper"
UPPER_PROP_ROOT = ROOT / "assets/props/update4/upper"
UPPER_ICON_ROOT = ROOT / "assets/ui/icons/update4"
UPPER_PREVIEW_ROOT = ROOT / "assets/ui/upper_floor/update4"
RESAMPLE = Image.Resampling.LANCZOS

REGIONS = {
    "ironbell_ravine": ("ironbell_ravine_source_2026-07-14.png", (836, 390)),
    "moonbat_aerie": ("moonbat_aerie_source_2026-07-14.png", (1080, 180)),
    "mistcap_marsh": ("mistcap_marsh_source_2026-07-14.png", (840, 270)),
    "bone_lantern_fields": ("bone_lantern_fields_source_2026-07-14.png", (1370, 500)),
    "blackwater_exchange": ("blackwater_exchange_source_2026-07-14.png", (840, 650)),
}

OUTPOSTS = {
    "watch_nest": "watch_nest_states_source_2026-07-14.png",
    "supply_burrow": "supply_burrow_states_source_2026-07-14.png",
    "false_gate": "false_gate_states_source_2026-07-14.png",
}

UPPER_CELLS = [
    ("tile", "upper_floor_tile"),
    ("tile", "upper_wall_tile"),
    ("tile", "upper_stair_landing"),
    ("tile", "upper_threshold"),
    ("prop", "crown_pedestal_empty"),
    ("prop", "crown_pedestal_active"),
    ("prop", "crown_pedestal_damaged"),
    ("prop", "upper_facility_slot"),
    ("prop", "seal_vault_normal"),
    ("prop", "seal_vault_alarm"),
    ("prop", "seal_vault_stolen"),
    ("icon", "floor_switch"),
]


def crop_16_by_9(image: Image.Image) -> Image.Image:
    target_ratio = 16 / 9
    ratio = image.width / image.height
    if ratio > target_ratio:
        width = round(image.height * target_ratio)
        left = (image.width - width) // 2
        return image.crop((left, 0, left + width, image.height))
    height = round(image.width / target_ratio)
    top = (image.height - height) // 2
    return image.crop((0, top, image.width, top + height))


def remove_magenta(image: Image.Image) -> Image.Image:
    rgba = np.array(image.convert("RGBA"), dtype=np.uint8)
    red = rgba[:, :, 0].astype(np.int16)
    green = rgba[:, :, 1].astype(np.int16)
    blue = rgba[:, :, 2].astype(np.int16)
    chroma = (red > 180) & (blue > 165) & (green < 135) & ((red - green) > 85) & ((blue - green) > 75)
    rgba[:, :, 3][chroma] = 0
    return Image.fromarray(rgba, "RGBA")


def fit_visible(image: Image.Image, size: tuple[int, int], padding: int = 10) -> Image.Image:
    rgba = remove_magenta(image)
    bbox = rgba.getbbox()
    if bbox is None:
        return Image.new("RGBA", size, (0, 0, 0, 0))
    visible = rgba.crop(bbox)
    visible.thumbnail((size[0] - padding * 2, size[1] - padding * 2), RESAMPLE)
    output = Image.new("RGBA", size, (0, 0, 0, 0))
    output.alpha_composite(visible, ((size[0] - visible.width) // 2, size[1] - padding - visible.height))
    return output


def prepare_regions() -> None:
    REGION_ROOT.mkdir(parents=True, exist_ok=True)
    for region_id, (source_name, focus) in REGIONS.items():
        source = Image.open(SOURCE_ROOT / "regions" / source_name).convert("RGB")
        background = crop_16_by_9(source).resize((1024, 576), RESAMPLE)
        background.save(REGION_ROOT / f"card_{region_id}.png", optimize=True)
        half = 260
        left = max(0, min(source.width - half * 2, focus[0] - half))
        top = max(0, min(source.height - half * 2, focus[1] - half))
        crop = source.crop((left, top, left + half * 2, top + half * 2)).resize((232, 232), RESAMPLE)
        emblem = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
        mask = Image.new("L", (232, 232), 0)
        ImageDraw.Draw(mask).ellipse((2, 2, 229, 229), fill=255)
        emblem.paste(crop, (12, 12), mask)
        draw = ImageDraw.Draw(emblem)
        draw.ellipse((10, 10, 245, 245), outline=(230, 190, 102, 255), width=8)
        emblem.save(REGION_ROOT / f"emblem_{region_id}.png", optimize=True)
        print(f"prepared region {region_id}")


def prepare_outposts() -> None:
    OUTPOST_ROOT.mkdir(parents=True, exist_ok=True)
    states = ["base", "damaged", "level2"]
    for outpost_id, source_name in OUTPOSTS.items():
        source = Image.open(SOURCE_ROOT / "outposts" / source_name)
        for column, state in enumerate(states):
            left = round(column * source.width / 3) + (6 if column > 0 else 0)
            right = round((column + 1) * source.width / 3) - (6 if column < 2 else 0)
            cell = source.crop((left, 0, right, source.height))
            fit_visible(cell, (512, 320), 8).save(OUTPOST_ROOT / f"outpost_{outpost_id}_{state}.png", optimize=True)
        print(f"prepared outpost {outpost_id}")


def prepare_upper_floor() -> dict[str, Image.Image]:
    for directory in [UPPER_TILE_ROOT, UPPER_PROP_ROOT, UPPER_ICON_ROOT, UPPER_PREVIEW_ROOT]:
        directory.mkdir(parents=True, exist_ok=True)
    source = Image.open(SOURCE_ROOT / "upper_floor" / "upper_floor_atlas_source_2026-07-14.png")
    prepared: dict[str, Image.Image] = {}
    for index, (kind, asset_id) in enumerate(UPPER_CELLS):
        column = index % 4
        row = index // 4
        left = round(column * source.width / 4) + (5 if column > 0 else 0)
        right = round((column + 1) * source.width / 4) - (5 if column < 3 else 0)
        top = round(row * source.height / 3) + (5 if row > 0 else 0)
        bottom = round((row + 1) * source.height / 3) - (5 if row < 2 else 0)
        cell = fit_visible(source.crop((left, top, right, bottom)), (384, 256), 8)
        directory = UPPER_TILE_ROOT if kind == "tile" else UPPER_PROP_ROOT if kind == "prop" else UPPER_ICON_ROOT
        cell.save(directory / f"{asset_id}.png", optimize=True)
        prepared[asset_id] = cell
    prepare_layout_previews(prepared)
    print("prepared upper-floor atlas and previews")
    return prepared


def prepare_layout_previews(assets: dict[str, Image.Image]) -> None:
    layouts = json.loads((ROOT / "data/regular_version/update4/upper_floor_layouts.json").read_text(encoding="utf-8"))
    module_asset = {
        "upper_stair_landing": "upper_stair_landing",
        "crown_sanctum": "crown_pedestal_active",
        "seal_vault": "seal_vault_normal",
        "upper_facility_slot": "upper_facility_slot",
    }
    for layout_id, definition in layouts.items():
        canvas = Image.new("RGBA", (1024, 512), (14, 10, 22, 255))
        floor = assets["upper_floor_tile"].resize((320, 214), RESAMPLE).filter(ImageFilter.GaussianBlur(0.5))
        for y in range(0, 512, 190):
            for x in range(-60, 1024, 250):
                canvas.alpha_composite(floor, (x, y))
        draw = ImageDraw.Draw(canvas)
        centers: dict[str, tuple[int, int]] = {}
        for placement in definition.get("placed_modules", []):
            origin = placement.get("grid_origin", [0, 0])
            centers[placement["instance_id"]] = (105 + int(origin[0]) * 235, 90 + int(origin[1]) * 140)
        for left_id, right_id in definition.get("connections", []):
            draw.line((centers[left_id], centers[right_id]), fill=(221, 179, 92, 210), width=12)
            draw.line((centers[left_id], centers[right_id]), fill=(90, 63, 112, 255), width=5)
        for placement in definition.get("placed_modules", []):
            center = centers[placement["instance_id"]]
            asset = assets[module_asset[placement["module_id"]]].copy()
            asset.thumbnail((210, 142), RESAMPLE)
            canvas.alpha_composite(asset, (center[0] - asset.width // 2, center[1] - asset.height // 2))
        canvas.convert("RGB").save(UPPER_PREVIEW_ROOT / f"layout_{layout_id}.png", optimize=True)


def main() -> None:
    prepare_regions()
    prepare_outposts()
    prepare_upper_floor()


if __name__ == "__main__":
    main()
