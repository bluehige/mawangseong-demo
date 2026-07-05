from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "output" / "imagegen" / "cave_object_atlas_01_alpha.png"
PROP_DIR = ROOT / "assets" / "props" / "v2"
TILE_DIR = ROOT / "assets" / "tiles" / "cave_v2"
ROOM_ICON_DIR = ROOT / "assets" / "ui" / "room_v2"
PREVIEW = ROOT / "output" / "imagegen" / "cave_object_atlas_01_sliced_preview.png"
ICON_PREVIEW = ROOT / "output" / "imagegen" / "cave_object_atlas_01_room_icon_preview.png"


@dataclass(frozen=True)
class Slot:
    row: int
    col: int
    file_name: str
    size: tuple[int, int]
    fit_ratio: float = 0.96


SLOTS = [
    Slot(0, 0, "prop_entrance_gate_v2_back.png", (260, 190), 0.98),
    Slot(0, 1, "prop_throne_v2_back.png", (240, 230), 0.98),
    Slot(0, 2, "prop_throne_v2_front.png", (220, 145), 0.98),
    Slot(1, 0, "prop_weapon_rack_v2_back.png", (240, 190), 0.98),
    Slot(1, 1, "prop_treasure_pile_v2_front.png", (230, 170), 0.98),
    Slot(1, 2, "prop_recovery_nest_v2_front.png", (230, 170), 0.98),
    Slot(2, 0, "prop_foundation_marks_v2_back.png", (210, 140), 0.98),
    Slot(2, 1, "prop_watch_post_v2_front.png", (210, 260), 0.98),
    Slot(2, 2, "prop_small_brazier_v2_back.png", (170, 180), 0.98),
]


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


def create_room_icons() -> list[tuple[str, Image.Image]]:
    mapping = {
        "room_v2_entrance.png": "prop_entrance_gate_v2_back.png",
        "room_v2_throne.png": "prop_throne_v2_back.png",
        "room_v2_barracks.png": "prop_weapon_rack_v2_back.png",
        "room_v2_treasure.png": "prop_treasure_pile_v2_front.png",
        "room_v2_recovery.png": "prop_recovery_nest_v2_front.png",
        "room_v2_build_slot.png": "prop_foundation_marks_v2_back.png",
        "room_v2_watch_post.png": "prop_watch_post_v2_front.png",
        "room_v2_center.png": "prop_small_brazier_v2_back.png",
        "room_v2_spike_corridor.png": "trap_spike_v2_trigger_02.png",
    }
    floor_path = TILE_DIR / "floor" / "floor_cave_v2_mask_15.png"
    floor = Image.open(floor_path).convert("RGBA")
    ROOM_ICON_DIR.mkdir(parents=True, exist_ok=True)
    outputs: list[tuple[str, Image.Image]] = []
    for icon_name, prop_name in mapping.items():
        canvas = Image.new("RGBA", (160, 160), (0, 0, 0, 0))
        base = floor.resize((142, 71), Image.Resampling.LANCZOS)
        canvas.alpha_composite(base, (9, 82))
        prop_path = PROP_DIR / prop_name
        if prop_path.exists():
            prop = trim_alpha(Image.open(prop_path).convert("RGBA"), 2)
            scale = min(132 / max(1, prop.width), 114 / max(1, prop.height))
            prop = prop.resize((max(1, int(prop.width * scale)), max(1, int(prop.height * scale))), Image.Resampling.LANCZOS)
            canvas.alpha_composite(prop, ((160 - prop.width) // 2, 130 - prop.height))
        canvas.save(ROOM_ICON_DIR / icon_name)
        outputs.append((icon_name, canvas))
    make_icon_preview(outputs)
    return outputs


def slice_atlas() -> list[tuple[str, Image.Image]]:
    if not SOURCE.exists():
        raise FileNotFoundError(SOURCE)
    source = Image.open(SOURCE).convert("RGBA")
    cell_w = source.width // 3
    cell_h = source.height // 3
    PROP_DIR.mkdir(parents=True, exist_ok=True)

    outputs: list[tuple[str, Image.Image]] = []
    for slot in SLOTS:
        left = slot.col * cell_w
        top = slot.row * cell_h
        right = source.width if slot.col == 2 else (slot.col + 1) * cell_w
        bottom = source.height if slot.row == 2 else (slot.row + 1) * cell_h
        sprite = fit_sprite(source.crop((left, top, right, bottom)), slot.size, slot.fit_ratio)
        sprite.save(PROP_DIR / slot.file_name)
        outputs.append((slot.file_name, sprite))
    make_preview(outputs)
    return outputs


def make_preview(outputs: list[tuple[str, Image.Image]]) -> None:
    thumb_w = 244
    thumb_h = 218
    preview = Image.new("RGBA", (thumb_w * 3, thumb_h * 3), (22, 19, 27, 255))
    for index, (_name, image) in enumerate(outputs):
        row = index // 3
        col = index % 3
        panel = Image.new("RGBA", (thumb_w, thumb_h), (34, 30, 40, 255))
        scaled = image.copy()
        scaled.thumbnail((thumb_w - 14, thumb_h - 14), Image.Resampling.LANCZOS)
        panel.alpha_composite(scaled, ((thumb_w - scaled.width) // 2, thumb_h - scaled.height - 6))
        preview.alpha_composite(panel, (col * thumb_w, row * thumb_h))
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    preview.save(PREVIEW)


def make_icon_preview(outputs: list[tuple[str, Image.Image]]) -> None:
    thumb = 170
    cols = 3
    rows = (len(outputs) + cols - 1) // cols
    preview = Image.new("RGBA", (thumb * cols, thumb * rows), (22, 19, 27, 255))
    for index, (_name, image) in enumerate(outputs):
        row = index // cols
        col = index % cols
        panel = Image.new("RGBA", (thumb, thumb), (34, 30, 40, 255))
        panel.alpha_composite(image, (5, 5))
        preview.alpha_composite(panel, (col * thumb, row * thumb))
    ICON_PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    preview.save(ICON_PREVIEW)


def main() -> None:
    outputs = slice_atlas()
    icon_outputs = create_room_icons()
    print(f"Wrote {len(outputs)} cave object sprites to {PROP_DIR}")
    print(f"Wrote {len(icon_outputs)} room icons to {ROOM_ICON_DIR}")
    print(f"Wrote preview: {PREVIEW}")
    print(f"Wrote icon preview: {ICON_PREVIEW}")


if __name__ == "__main__":
    main()
