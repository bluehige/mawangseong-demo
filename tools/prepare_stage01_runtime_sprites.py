from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
ALPHA_DIR = ROOT / "output" / "imagegen" / "stage01_runtime_alpha"
ASSET_DIR = ROOT / "assets" / "props" / "stage_01"
PREVIEW_PATH = ROOT / "output" / "imagegen" / "stage01_runtime_applied_preview.png"

SPRITES = [
    ("entrance_gate_f", "SE", "back", "prop_entrance_gate_stage01_SE_alpha.png", "prop_entrance_gate_stage01_SE_back.png"),
    ("throne_f", "SW", "back", "prop_throne_stage01_SW_alpha.png", "prop_throne_stage01_SW_back.png"),
    ("weapon_rack", "SE", "back", "prop_weapon_rack_stage01_SE_alpha.png", "prop_weapon_rack_stage01_SE_back.png"),
    ("recovery_nest_f", "NW", "front", "prop_recovery_nest_stage01_NW_alpha.png", "prop_recovery_nest_stage01_NW_front.png"),
    ("treasure_pile_large", "NW", "front", "prop_treasure_pile_stage01_NW_alpha.png", "prop_treasure_pile_stage01_NW_front.png"),
    ("foundation_marks", "NE", "back", "prop_foundation_marks_stage01_NE_alpha.png", "prop_foundation_marks_stage01_NE_back.png"),
]


def trim_alpha(image: Image.Image, padding: int = 18) -> Image.Image:
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


def write_sprite(source_name: str, out_name: str) -> Path:
    source = Image.open(ALPHA_DIR / source_name).convert("RGBA")
    trimmed = trim_alpha(source)
    out_path = ASSET_DIR / out_name
    out_path.parent.mkdir(parents=True, exist_ok=True)
    trimmed.save(out_path)
    return out_path


def make_preview(outputs: list[tuple[str, Path]]) -> None:
    tile_w, tile_h = 260, 230
    preview = Image.new("RGBA", (tile_w * 3, tile_h * 2), (20, 17, 26, 255))
    draw = ImageDraw.Draw(preview)
    font = ImageFont.load_default()
    for index, (label, path) in enumerate(outputs):
        image = Image.open(path).convert("RGBA")
        image.thumbnail((tile_w - 18, tile_h - 44), Image.Resampling.LANCZOS)
        col = index % 3
        row = index // 3
        x = col * tile_w
        y = row * tile_h
        panel = Image.new("RGBA", (tile_w, tile_h), (34, 29, 42, 255))
        panel.alpha_composite(image, ((tile_w - image.width) // 2, tile_h - image.height - 10))
        preview.alpha_composite(panel, (x, y))
        draw.text((x + 8, y + 8), label[:36], fill=(232, 224, 242, 255), font=font)
    PREVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)
    preview.save(PREVIEW_PATH)


def main() -> None:
    outputs: list[tuple[str, Path]] = []
    for prop_id, facing, layer, source_name, out_name in SPRITES:
        out = write_sprite(source_name, out_name)
        outputs.append((f"{prop_id} {facing} {layer}", out))
    make_preview(outputs)
    print(f"Wrote {len(outputs)} stage-01 runtime sprites to {ASSET_DIR}")
    print(f"Wrote preview: {PREVIEW_PATH}")


if __name__ == "__main__":
    main()

