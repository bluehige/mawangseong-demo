"""Bake v1.2.5 castle-stage progression art into deterministic runtime assets.

The source paintings are generated and approved separately.  This script only
performs geometry-preserving post-processing: PNG optimization, exact 2:1
isometric registration, four parity-cell crops, and the existing sixteen-mask
corridor autotile bake.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops

import prepare_v122_road_autotiles as road
import prepare_v122_stage01_spatial_assets as stage01


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = ROOT / "assets" / "source" / "imagegen" / "v125_stage_progression"

STAGES = {
    "stage02_castle": {
        "stage_dir": "stage_02",
        "stage_number": "02",
        "background_source": "stage02_castle_selected.png",
        "background_output": "bg_stage02_castle.png",
    },
    "stage03_keep": {
        "stage_dir": "stage_03",
        "stage_number": "03",
        "background_source": "stage03_keep_selected.png",
        "background_output": "bg_stage03_keep.png",
    },
    "stage04_citadel": {
        "stage_dir": "stage_04",
        "stage_number": "04",
        "background_source": "stage04_citadel_selected.png",
        "background_output": "bg_stage04_citadel.png",
    },
}

CELL_CROPS = {
    "00": (64, 0, 192, 64),
    "10": (128, 32, 256, 96),
    "01": (0, 32, 128, 96),
    "11": (64, 64, 192, 128),
}


def _alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("corridor source contains no visible pixels")
    return bbox


def _save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)


def _bake_background(stage: dict[str, str]) -> Path:
    source_path = SOURCE_ROOT / "backgrounds" / stage["background_source"]
    output_path = ROOT / "assets" / "backgrounds" / "v125" / stage["background_output"]
    with Image.open(source_path) as source:
        image = source.convert("RGB")
        if image.size != (1536, 1024):
            image = image.resize((1536, 1024), Image.Resampling.LANCZOS)
        _save(image, output_path)
    return output_path


def _bake_corridor(stage_id: str, stage: dict[str, str]) -> list[Path]:
    source_path = (
        SOURCE_ROOT
        / "corridor_surfaces"
        / f"{stage_id}_selected_alpha.png"
    )
    source = Image.open(source_path).convert("RGBA")
    patch = source.crop(_alpha_bbox(source)).resize(road.PATCH_SIZE, Image.Resampling.LANCZOS)

    stage_dir = ROOT / "assets" / "tiles" / stage["stage_dir"]
    spatial_dir = stage_dir / "spatial"
    atlas_dir = stage_dir / "spatial_road_autotile_v1"
    number = stage["stage_number"]
    outputs: list[Path] = []

    base_path = spatial_dir / f"corridor_surface_stage{number}_2cell.png"
    _save(patch, base_path)
    outputs.append(base_path)

    diamond_mask = stage01._diamond_mask(road.CELL_SIZE)
    for cell_id, crop_box in CELL_CROPS.items():
        cell = patch.crop(crop_box)
        cell.putalpha(ImageChops.multiply(cell.getchannel("A"), diamond_mask))
        cell_path = spatial_dir / f"corridor_surface_stage{number}_cell_{cell_id}.png"
        _save(cell, cell_path)
        outputs.append(cell_path)

    material_cells = road._material_cells(source)
    atlas = Image.new(
        "RGBA",
        (road.CELL_SIZE[0] * road.MASK_COUNT, road.CELL_SIZE[1] * len(road.VARIANT_ORDER)),
        (0, 0, 0, 0),
    )
    for variant_index, variant in enumerate(road.VARIANT_ORDER):
        material = material_cells[variant]
        for mask_value in range(road.MASK_COUNT):
            tile = road._bake_tile(material, road._topology_mask(mask_value))
            atlas.alpha_composite(
                tile,
                (mask_value * road.CELL_SIZE[0], variant_index * road.CELL_SIZE[1]),
            )
    atlas_path = atlas_dir / f"corridor_road_autotile_stage{number}_atlas.png"
    _save(atlas, atlas_path)
    outputs.append(atlas_path)
    return outputs


def main() -> None:
    outputs: list[Path] = []
    for stage_id, stage in STAGES.items():
        outputs.append(_bake_background(stage))
        outputs.extend(_bake_corridor(stage_id, stage))
    for path in outputs:
        with Image.open(path) as image:
            print(f"{path.relative_to(ROOT).as_posix()}: {image.width}x{image.height} {image.mode}")


if __name__ == "__main__":
    main()
