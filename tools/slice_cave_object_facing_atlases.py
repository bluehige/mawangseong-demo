from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "output" / "imagegen"
PROP_DIR = ROOT / "assets" / "props" / "v3"
PREVIEW = OUTPUT_DIR / "cave_object_facing_atlases_01_sliced_preview.png"

FACINGS = ["NW", "NE", "SE", "SW"]

# This script only slices columns and assigns file names. It cannot verify visual
# facing. A generated atlas must still pass contact-sheet review:
# NW = object front faces northwest/back-away, NE = northeast,
# SE = southeast, SW = southwest/lower-left.


@dataclass(frozen=True)
class RowSpec:
    row: int
    file_pattern: str
    size: tuple[int, int]
    fit_ratio: float = 0.96


@dataclass(frozen=True)
class AtlasSpec:
    source: Path
    columns: int
    rows: int
    row_specs: tuple[RowSpec, ...]


MAJOR_ATLAS = AtlasSpec(
    source=OUTPUT_DIR / "cave_object_facing_major_01_alpha.png",
    columns=4,
    rows=4,
    row_specs=(
        RowSpec(0, "prop_throne_v3_{facing}_back.png", (250, 240), 0.98),
        RowSpec(1, "prop_throne_v3_{facing}_front.png", (230, 150), 0.98),
        RowSpec(2, "prop_weapon_rack_v3_{facing}_back.png", (250, 195), 0.98),
        RowSpec(3, "prop_treasure_pile_v3_{facing}_front.png", (240, 180), 0.98),
    ),
)

SUPPORT_ATLAS = AtlasSpec(
    source=OUTPUT_DIR / "cave_object_facing_support_01_alpha.png",
    columns=4,
    rows=5,
    row_specs=(
        RowSpec(0, "prop_recovery_nest_v3_{facing}_front.png", (240, 180), 0.98),
        RowSpec(1, "prop_entrance_gate_v3_{facing}_back.png", (270, 205), 0.98),
        RowSpec(2, "prop_watch_post_v3_{facing}_front.png", (225, 270), 0.98),
        RowSpec(3, "prop_foundation_marks_v3_{facing}_back.png", (220, 150), 0.98),
        RowSpec(4, "prop_small_brazier_v3_{facing}_back.png", (180, 190), 0.98),
    ),
)


def alpha_bbox(image: Image.Image, padding: int = 12) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return (0, 0, image.width, image.height)
    left, top, right, bottom = bbox
    return (
        max(0, left - padding),
        max(0, top - padding),
        min(image.width, right + padding),
        min(image.height, bottom + padding),
    )


def trim_alpha(image: Image.Image, padding: int = 0) -> Image.Image:
    return image.crop(alpha_bbox(image, padding))


def fit_sprite(source: Image.Image, size: tuple[int, int], fit_ratio: float) -> Image.Image:
    cropped = trim_alpha(source, 12)
    target_w, target_h = size
    max_w = max(1, int(target_w * fit_ratio))
    max_h = max(1, int(target_h * fit_ratio))
    fitted = cropped.copy()
    fitted.thumbnail((max_w, max_h), Image.Resampling.LANCZOS)
    sprite = Image.new("RGBA", size, (0, 0, 0, 0))
    x = (target_w - fitted.width) // 2
    y = target_h - fitted.height
    sprite.alpha_composite(fitted, (x, y))
    return sprite


def slice_atlas(spec: AtlasSpec) -> list[tuple[str, Image.Image]]:
    if not spec.source.exists():
        raise FileNotFoundError(spec.source)
    source = Image.open(spec.source).convert("RGBA")
    cell_w = source.width // spec.columns
    cell_h = source.height // spec.rows
    PROP_DIR.mkdir(parents=True, exist_ok=True)

    outputs: list[tuple[str, Image.Image]] = []
    for row_spec in spec.row_specs:
        for col, facing in enumerate(FACINGS):
            left = col * cell_w
            top = row_spec.row * cell_h
            right = source.width if col == spec.columns - 1 else (col + 1) * cell_w
            bottom = source.height if row_spec.row == spec.rows - 1 else (row_spec.row + 1) * cell_h
            sprite = fit_sprite(source.crop((left, top, right, bottom)), row_spec.size, row_spec.fit_ratio)
            file_name = row_spec.file_pattern.format(facing=facing)
            sprite.save(PROP_DIR / file_name)
            outputs.append((file_name, sprite))
    return outputs


def make_preview(outputs: list[tuple[str, Image.Image]]) -> None:
    thumb_w = 230
    thumb_h = 210
    cols = 4
    rows = (len(outputs) + cols - 1) // cols
    preview = Image.new("RGBA", (thumb_w * cols, thumb_h * rows), (22, 19, 27, 255))
    draw = ImageDraw.Draw(preview)
    for index, (name, image) in enumerate(outputs):
        row = index // cols
        col = index % cols
        panel_x = col * thumb_w
        panel_y = row * thumb_h
        panel = Image.new("RGBA", (thumb_w, thumb_h), (34, 30, 40, 255))
        scaled = image.copy()
        scaled.thumbnail((thumb_w - 14, thumb_h - 30), Image.Resampling.LANCZOS)
        panel.alpha_composite(scaled, ((thumb_w - scaled.width) // 2, thumb_h - scaled.height - 8))
        preview.alpha_composite(panel, (panel_x, panel_y))
        draw.text((panel_x + 6, panel_y + 5), name.replace(".png", ""), fill=(220, 214, 235, 255))
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    preview.save(PREVIEW)


def main() -> None:
    outputs: list[tuple[str, Image.Image]] = []
    outputs.extend(slice_atlas(MAJOR_ATLAS))
    outputs.extend(slice_atlas(SUPPORT_ATLAS))
    make_preview(outputs)
    print(f"Wrote {len(outputs)} facing object sprites to {PROP_DIR}")
    print(f"Wrote preview: {PREVIEW}")
    print("WARNING: column labels are not visual validation; approve only after contact-sheet direction QA.")


if __name__ == "__main__":
    main()
