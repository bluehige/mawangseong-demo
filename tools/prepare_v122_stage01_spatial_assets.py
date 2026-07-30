"""Build deterministic v1.2.2 Stage 01 runtime spatial assets.

This script performs geometry-only post-processing on approved ImageGen alpha
sources: crop, resize, exact isometric cell masking, and PNG optimization.
It does not paint or synthesize replacement artwork.
"""

from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = ROOT / "assets" / "source" / "imagegen" / "v122_stage01_spatial"
TILE_OUT = ROOT / "assets" / "tiles" / "stage_01" / "spatial"
PROP_OUT = ROOT / "assets" / "props" / "stage_01"
UI_OUT = ROOT / "assets" / "ui" / "stage_01"

PATCH_SIZE = (256, 128)
CELL_SIZE = (128, 64)


def _load_alpha(relative_path: str) -> Image.Image:
    path = SOURCE_ROOT / relative_path
    return Image.open(path).convert("RGBA")


def _alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("source contains no visible pixels")
    return bbox


def _fit_visible_patch(image: Image.Image) -> Image.Image:
    """Fit a generated 2x2 diamond's visible bounds to exact 256x128."""

    return image.crop(_alpha_bbox(image)).resize(PATCH_SIZE, Image.Resampling.LANCZOS)


def _save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)


def _diamond_mask(size: tuple[int, int]) -> Image.Image:
    width, height = size
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.polygon(
        [
            (width // 2, 0),
            (width - 1, height // 2),
            (width // 2, height - 1),
            (0, height // 2),
        ],
        fill=255,
    )
    return mask


def _keep_border_connected_alpha(image: Image.Image, threshold: int = 8) -> Image.Image:
    """Remove chroma-removal specks not connected to the frame's outer edge."""

    alpha = image.getchannel("A")
    width, height = image.size
    alpha_values = list(alpha.get_flattened_data())
    visible = bytearray(1 if value > threshold else 0 for value in alpha_values)
    keep = bytearray(width * height)
    pending: deque[int] = deque()

    def seed(index: int) -> None:
        if visible[index] and not keep[index]:
            keep[index] = 1
            pending.append(index)

    for x in range(width):
        seed(x)
        seed((height - 1) * width + x)
    for y in range(height):
        seed(y * width)
        seed(y * width + width - 1)

    while pending:
        index = pending.popleft()
        x = index % width
        y = index // width
        if x > 0:
            seed(index - 1)
        if x + 1 < width:
            seed(index + 1)
        if y > 0:
            seed(index - width)
        if y + 1 < height:
            seed(index + width)

    cleaned_alpha = Image.new("L", image.size, 0)
    cleaned_alpha.putdata(
        [value if keep[index] else 0 for index, value in enumerate(alpha_values)]
    )
    cleaned = image.copy()
    cleaned.putalpha(cleaned_alpha)
    return cleaned


def _clear_nine_patch_stretch_regions(image: Image.Image) -> Image.Image:
    """Keep only the intended simple rock bands in 1024px 9-slice middles."""

    if image.size != (1024, 1024):
        raise ValueError("Stage 01 edge-mask cleanup expects 1024x1024")
    alpha = image.getchannel("A")
    clear = ImageDraw.Draw(alpha)
    # draw_center=false hides the middle at runtime; clearing it here also
    # removes chroma-removal specks from previews and future consumers.
    clear.rectangle((256, 256, 768, 768), fill=0)
    clear.rectangle((256, 160, 768, 256), fill=0)
    clear.rectangle((256, 768, 768, 940), fill=0)
    clear.rectangle((130, 256, 256, 768), fill=0)
    clear.rectangle((768, 256, 894, 768), fill=0)
    cleaned = image.copy()
    cleaned.putalpha(alpha)
    return cleaned


def _write_corridor_tiles() -> list[Path]:
    source = _load_alpha(
        "corridor_surface_2cell/corridor_surface_2cell_selected_alpha_preview.png"
    )
    patch = _fit_visible_patch(source)
    _save(patch, TILE_OUT / "corridor_surface_stage01_2cell.png")

    # Four numbered cells preserve the approved 2x2 material variation while
    # allowing the runtime tile-grid renderer to compose arbitrary corridors.
    cells = {
        "00": (64, 0, 192, 64),
        "10": (128, 32, 256, 96),
        "01": (0, 32, 128, 96),
        "11": (64, 64, 192, 128),
    }
    mask = _diamond_mask(CELL_SIZE)
    outputs: list[Path] = [TILE_OUT / "corridor_surface_stage01_2cell.png"]
    for cell_id, crop_box in cells.items():
        cell = patch.crop(crop_box)
        cell.putalpha(ImageChops.multiply(cell.getchannel("A"), mask))
        out = TILE_OUT / f"corridor_surface_stage01_cell_{cell_id}.png"
        _save(cell, out)
        outputs.append(out)
    return outputs


def _write_thresholds() -> list[Path]:
    outputs: list[Path] = []
    for side in ("n", "e", "s", "w"):
        source = _load_alpha(
            f"threshold_{side}_2cell/threshold_{side}_2cell_selected_alpha_preview.png"
        )
        out = TILE_OUT / f"threshold_stage01_{side.upper()}_2cell.png"
        _save(_fit_visible_patch(source), out)
        outputs.append(out)
    return outputs


def _write_occlusion_shadow() -> Path:
    source = _load_alpha(
        "common_occlusion_shadow_2cell/"
        "common_occlusion_shadow_2cell_selected_alpha_preview.png"
    )
    registration = _load_alpha(
        "corridor_surface_2cell/corridor_surface_2cell_selected_alpha_preview.png"
    )
    # Crop with the approved corridor footprint rather than the shadow bbox;
    # this keeps the V shadow registered to the lower two diamond edges.
    out = TILE_OUT / "common_occlusion_shadow_stage01_2cell.png"
    _save(
        source.crop(_alpha_bbox(registration)).resize(
            PATCH_SIZE, Image.Resampling.LANCZOS
        ),
        out,
    )
    return out


def _write_throne_room() -> Path:
    source = _load_alpha(
        "throne_sw_open04/throne_sw_open04_selected_alpha_preview.png"
    )
    # The selected source's floor guide is approximately x=3..97% and
    # y=49..96%. A single uniform scale maps it to a 640x320 native diamond.
    # The 16px lower canvas margin prevents filtered alpha from clipping.
    scaled_size = 681
    scaled = source.resize((scaled_size, scaled_size), Image.Resampling.LANCZOS)
    runtime = scaled.crop((20, 30, 660, 670))
    out = PROP_OUT / "room_throne_stage01_SW_open_s_back.png"
    _save(runtime, out)
    return out


def _write_cavern_edge_mask() -> Path:
    source = _load_alpha(
        "cavern_edge_mask_9slice/cavern_edge_mask_9slice_selected_alpha_preview.png"
    )
    out = UI_OUT / "cavern_edge_mask_stage01_9slice.png"
    resized = source.resize((1024, 1024), Image.Resampling.LANCZOS)
    connected = _keep_border_connected_alpha(resized)
    _save(_clear_nine_patch_stretch_regions(connected), out)
    return out


def main() -> None:
    outputs: list[Path] = []
    outputs.extend(_write_corridor_tiles())
    outputs.extend(_write_thresholds())
    outputs.append(_write_occlusion_shadow())
    outputs.append(_write_throne_room())
    outputs.append(_write_cavern_edge_mask())
    for path in outputs:
        relative = path.relative_to(ROOT).as_posix()
        with Image.open(path) as image:
            print(f"{relative}: {image.width}x{image.height} {image.mode}")


if __name__ == "__main__":
    main()
