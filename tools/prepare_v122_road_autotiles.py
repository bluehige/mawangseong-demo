"""Bake the Stage 01 road material into a topology-aware autotile atlas.

The generated image supplies the painted stone material. This script only
normalizes it to the project's exact 128x64 isometric cell contract and bakes
the sixteen N/E/S/W connection masks. Runtime code therefore draws bitmap
road tiles instead of constructing road geometry with lines or polygons.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = (
    ROOT
    / "assets"
    / "source"
    / "imagegen"
    / "v122_stage01_spatial"
    / "road_autotile_v2"
    / "road_autotile_material_alpha.png"
)
OUT = (
    ROOT
    / "assets"
    / "tiles"
    / "stage_01"
    / "spatial_road_autotile_v2"
    / "corridor_road_autotile_stage01_atlas.png"
)

CELL_SIZE = (128, 64)
PATCH_SIZE = (256, 128)
SUPERSAMPLE = 4
MASK_COUNT = 16
VARIANT_ORDER = ("00", "10", "01", "11")
BIT_BY_SIDE = {"N": 1, "E": 2, "S": 4, "W": 8}

DIAMOND_POINTS = {
    "top": (64.0, 0.0),
    "right": (128.0, 32.0),
    "bottom": (64.0, 64.0),
    "left": (0.0, 32.0),
}
PORTS = {
    "N": (96.0, 16.0),
    "E": (96.0, 48.0),
    "S": (32.0, 48.0),
    "W": (32.0, 16.0),
}


def _alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("road material contains no visible pixels")
    return bbox


def _scaled(point: tuple[float, float]) -> tuple[int, int]:
    return (round(point[0] * SUPERSAMPLE), round(point[1] * SUPERSAMPLE))


def _branch_polygon(side: str, seed: int) -> list[tuple[int, int]]:
    rng = random.Random(seed)
    center = (64.0, 32.0)
    port = PORTS[side]
    dx = port[0] - center[0]
    dy = port[1] - center[1]
    length = math.hypot(dx, dy)
    nx = -dy / length
    ny = dx / length
    samples = 6
    left: list[tuple[float, float]] = []
    right: list[tuple[float, float]] = []
    for index in range(samples):
        t = index / float(samples - 1)
        width = 24.0 + (19.0 - 24.0) * t
        if 0 < index < samples - 1:
            width += rng.uniform(-2.2, 2.2)
        lateral = 0.0 if index in (0, samples - 1) else rng.uniform(-1.3, 1.3)
        x = center[0] + dx * t + nx * lateral
        y = center[1] + dy * t + ny * lateral
        left.append((x + nx * width, y + ny * width))
        right.append((x - nx * width, y - ny * width))
    return [_scaled(point) for point in left + list(reversed(right))]


def _topology_mask(mask_value: int) -> Image.Image:
    size = (CELL_SIZE[0] * SUPERSAMPLE, CELL_SIZE[1] * SUPERSAMPLE)
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    diamond = [_scaled(DIAMOND_POINTS[key]) for key in ("top", "right", "bottom", "left")]

    rng = random.Random(9103 + mask_value * 131)
    hub: list[tuple[int, int]] = []
    for index in range(12):
        angle = math.tau * index / 12.0
        radius_x = 26.0 + rng.uniform(-2.0, 2.0)
        radius_y = 15.5 + rng.uniform(-1.4, 1.4)
        hub.append(_scaled((64.0 + math.cos(angle) * radius_x, 32.0 + math.sin(angle) * radius_y)))
    draw.polygon(hub, fill=255)

    for side, bit in BIT_BY_SIDE.items():
        if mask_value & bit:
            draw.polygon(_branch_polygon(side, 1409 + mask_value * 97 + bit * 17), fill=255)

    diamond_mask = Image.new("L", size, 0)
    ImageDraw.Draw(diamond_mask).polygon(diamond, fill=255)
    mask = ImageChops.multiply(mask, diamond_mask)
    mask = mask.filter(ImageFilter.GaussianBlur(radius=0.42 * SUPERSAMPLE))
    gate_draw = ImageDraw.Draw(mask)
    gate_radius = 6.0 * SUPERSAMPLE
    for side, bit in BIT_BY_SIDE.items():
        if mask_value & bit:
            continue
        port_x, port_y = _scaled(PORTS[side])
        gate_draw.ellipse(
            (
                port_x - gate_radius,
                port_y - gate_radius,
                port_x + gate_radius,
                port_y + gate_radius,
            ),
            fill=0,
        )
    return mask.resize(CELL_SIZE, Image.Resampling.LANCZOS)


def _material_cells(source: Image.Image) -> dict[str, Image.Image]:
    patch = source.crop(_alpha_bbox(source)).resize(PATCH_SIZE, Image.Resampling.LANCZOS)
    crop_boxes = {
        "00": (64, 0, 192, 64),
        "10": (128, 32, 256, 96),
        "01": (0, 32, 128, 96),
        "11": (64, 64, 192, 128),
    }
    return {cell_id: patch.crop(box) for cell_id, box in crop_boxes.items()}


def _bake_tile(material: Image.Image, topology: Image.Image) -> Image.Image:
    material = material.copy().convert("RGBA")
    material_alpha = ImageChops.multiply(material.getchannel("A"), topology)

    expanded = topology.filter(ImageFilter.MaxFilter(3))
    shadow_alpha = ImageChops.subtract(expanded, topology).point(lambda value: round(value * 0.46))
    shadow = Image.new("RGBA", CELL_SIZE, (12, 9, 16, 0))
    shadow.putalpha(shadow_alpha)

    material.putalpha(material_alpha)
    return Image.alpha_composite(shadow, material)


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    materials = _material_cells(source)
    atlas = Image.new("RGBA", (CELL_SIZE[0] * MASK_COUNT, CELL_SIZE[1] * len(VARIANT_ORDER)), (0, 0, 0, 0))

    for variant_index, variant in enumerate(VARIANT_ORDER):
        material = materials[variant]
        for mask_value in range(MASK_COUNT):
            tile = _bake_tile(material, _topology_mask(mask_value))
            atlas.alpha_composite(tile, (mask_value * CELL_SIZE[0], variant_index * CELL_SIZE[1]))

    OUT.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(OUT, optimize=True)
    print(f"{OUT.relative_to(ROOT).as_posix()}: {atlas.width}x{atlas.height} {atlas.mode}")


if __name__ == "__main__":
    main()
