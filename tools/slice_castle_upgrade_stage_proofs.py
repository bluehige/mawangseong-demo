from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "output" / "imagegen"
OUT_DIR = SOURCE_DIR / "castle_upgrade_tiers"

OBJECT_ATLAS = SOURCE_DIR / "castle_upgrade_object_stage_atlas_gpt_image2_2026-07-08_alpha.png"
BASE_SHEET = SOURCE_DIR / "castle_upgrade_base_stage_sheet_gpt_image2_2026-07-08_alpha.png"

OBJECT_ROWS = [
    "entrance_gate",
    "throne",
    "barracks",
    "recovery_nest",
    "treasure_storage",
    "watch_post",
    "build_foundation",
]

STAGES = ["stage_01_cave", "stage_02_castle", "stage_03_keep", "stage_04_citadel"]


def trim_alpha(image: Image.Image, padding: int = 16) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return image
    left, top, right, bottom = bbox
    return image.crop((
        max(0, left - padding),
        max(0, top - padding),
        min(image.width, right + padding),
        min(image.height, bottom + padding),
    ))


def fit_on_canvas(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    fitted = trim_alpha(image)
    fitted.thumbnail((size[0] - 8, size[1] - 8), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    canvas.alpha_composite(fitted, ((size[0] - fitted.width) // 2, size[1] - fitted.height - 4))
    return canvas


def inset_box(left: int, top: int, right: int, bottom: int, inset_x: int, inset_y: int) -> tuple[int, int, int, int]:
    return (left + inset_x, top + inset_y, right - inset_x, bottom - inset_y)


def slice_object_atlas() -> list[Path]:
    source = Image.open(OBJECT_ATLAS).convert("RGBA")
    cell_w = source.width // 4
    cell_h = source.height // 7
    outputs: list[Path] = []
    for row, object_id in enumerate(OBJECT_ROWS):
        for col, stage in enumerate(STAGES):
            left = col * cell_w
            top = row * cell_h
            right = source.width if col == len(STAGES) - 1 else (col + 1) * cell_w
            bottom = source.height if row == len(OBJECT_ROWS) - 1 else (row + 1) * cell_h
            sprite = fit_on_canvas(source.crop(inset_box(left, top, right, bottom, 18, 28)), (280, 220))
            out = OUT_DIR / f"prop_{object_id}_{stage}_proof.png"
            sprite.save(out)
            outputs.append(out)
    return outputs


def slice_base_sheet() -> list[Path]:
    source = Image.open(BASE_SHEET).convert("RGBA")
    cell_w = source.width // 4
    outputs: list[Path] = []
    for col, stage in enumerate(STAGES):
        left = col * cell_w
        right = source.width if col == len(STAGES) - 1 else (col + 1) * cell_w
        sprite = fit_on_canvas(source.crop(inset_box(left, 0, right, source.height, 22, 12)), (520, 340))
        out = OUT_DIR / f"castle_base_{stage}_proof.png"
        sprite.save(out)
        outputs.append(out)
    return outputs


def make_preview(paths: list[Path]) -> None:
    thumbs: list[tuple[str, Image.Image]] = []
    for path in paths:
        image = Image.open(path).convert("RGBA")
        image.thumbnail((180, 140), Image.Resampling.LANCZOS)
        thumbs.append((path.stem, image))

    cols = 4
    rows = (len(thumbs) + cols - 1) // cols
    tile_w, tile_h = 240, 178
    preview = Image.new("RGBA", (tile_w * cols, tile_h * rows), (18, 15, 22, 255))
    draw = ImageDraw.Draw(preview)
    for index, (name, image) in enumerate(thumbs):
        col = index % cols
        row = index // cols
        x = col * tile_w
        y = row * tile_h
        panel = Image.new("RGBA", (tile_w, tile_h), (32, 28, 40, 255))
        panel.alpha_composite(image, ((tile_w - image.width) // 2, tile_h - image.height - 8))
        preview.alpha_composite(panel, (x, y))
        draw.text((x + 8, y + 8), name[:34], fill=(226, 220, 238, 255))
    preview.save(OUT_DIR / "castle_upgrade_tiers_sliced_preview.png")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    outputs = []
    outputs.extend(slice_object_atlas())
    outputs.extend(slice_base_sheet())
    make_preview(outputs)
    print(f"Wrote {len(outputs)} proof sprites to {OUT_DIR}")
    print(f"Wrote preview: {OUT_DIR / 'castle_upgrade_tiers_sliced_preview.png'}")


if __name__ == "__main__":
    main()
