from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SHEET_PATH = ROOT / "output" / "imagegen" / "quarter_v2_gpt_image2_asset_sheet.png"
SPIKE_SHEET_PATH = ROOT / "output" / "imagegen" / "spike_floor_v2_gpt_image2_sheet.png"
TILE_ROOT = ROOT / "assets" / "tiles" / "cave_v2"
PROP_ROOT = ROOT / "assets" / "props" / "v2"
ROOM_ICON_ROOT = ROOT / "assets" / "ui" / "room_v2"
PREVIEW_PATH = ROOT / "output" / "imagegen" / "quarter_v2_gpt_sliced_preview.png"


FLOOR_SOURCES = [
    (28, 34, 312, 158),
    (410, 28, 724, 166),
    (780, 28, 1098, 164),
    (1120, 24, 1500, 166),
    (44, 198, 280, 300),
    (320, 180, 616, 300),
    (644, 182, 856, 294),
    (980, 186, 1240, 300),
]

ASSET_BOXES = {
    "edge": (38, 336, 264, 448),
    "wall_nw": (150, 480, 372, 594),
    "wall_ne": (472, 478, 635, 594),
    "door_ne": (965, 458, 1098, 604),
    "door_nw": (1142, 462, 1275, 604),
    "entrance": (28, 610, 318, 764),
    "brazier": (18, 782, 178, 972),
    "throne": (190, 792, 372, 960),
    "treasure": (392, 794, 620, 948),
    "weapon_rack": (666, 792, 842, 954),
    "recovery": (870, 794, 1086, 950),
    "foundation": (1108, 826, 1290, 940),
    "watch_post": (1290, 676, 1518, 974),
    "spike_proxy": (1325, 470, 1494, 596),
}


def ensure_dirs() -> None:
    for folder in [
        TILE_ROOT / "floor",
        TILE_ROOT / "edge",
        TILE_ROOT / "wall",
        TILE_ROOT / "door",
        TILE_ROOT / "overlay",
        PROP_ROOT,
        ROOM_ICON_ROOT,
        PREVIEW_PATH.parent,
    ]:
        folder.mkdir(parents=True, exist_ok=True)


def remove_sheet_bg(crop: Image.Image, threshold: int = 18, feather: float = 0.8) -> Image.Image:
    image = crop.convert("RGBA")
    rgb = image.convert("RGB")
    w, h = rgb.size
    samples = [
        rgb.getpixel((0, 0)),
        rgb.getpixel((w - 1, 0)),
        rgb.getpixel((0, h - 1)),
        rgb.getpixel((w - 1, h - 1)),
    ]
    bg = tuple(sum(sample[i] for sample in samples) // len(samples) for i in range(3))
    bg_image = Image.new("RGB", rgb.size, bg)
    diff = ImageChops.difference(rgb, bg_image).convert("L")
    alpha = diff.point(lambda value: 0 if value < threshold else min(255, int((value - threshold) * 5)))
    alpha = alpha.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(feather))
    image.putalpha(alpha)
    return image


def trim_alpha(image: Image.Image, margin: int = 2) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox == None:
        return image
    left, top, right, bottom = bbox
    left = max(0, left - margin)
    top = max(0, top - margin)
    right = min(image.width, right + margin)
    bottom = min(image.height, bottom + margin)
    return image.crop((left, top, right, bottom))


def fit_to_canvas(image: Image.Image, size: tuple[int, int], fill_ratio: float = 0.94, y_bias: float = 0.5) -> Image.Image:
    image = trim_alpha(image)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    if image.width <= 0 or image.height <= 0:
        return canvas
    max_w = int(size[0] * fill_ratio)
    max_h = int(size[1] * fill_ratio)
    scale = min(max_w / image.width, max_h / image.height)
    scaled = image.resize((max(1, int(image.width * scale)), max(1, int(image.height * scale))), Image.Resampling.LANCZOS)
    x = (size[0] - scaled.width) // 2
    y = int((size[1] - scaled.height) * y_bias)
    canvas.alpha_composite(scaled, (x, y))
    return canvas


def lower_alpha_slice(image: Image.Image, start_ratio: float) -> Image.Image:
    image = trim_alpha(image, margin=0)
    top = max(0, min(image.height - 1, int(image.height * start_ratio)))
    return trim_alpha(image.crop((0, top, image.width, image.height)))


def make_diamond_floor(source: Image.Image, size: tuple[int, int] = (128, 64)) -> Image.Image:
    texture = ImageOps.fit(source.convert("RGBA"), size, method=Image.Resampling.LANCZOS, centering=(0.5, 0.52))
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.polygon([(size[0] // 2, 2), (size[0] - 3, size[1] // 2), (size[0] // 2, size[1] - 3), (2, size[1] // 2)], fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(0.35))
    original_alpha = texture.getchannel("A")
    texture.putalpha(ImageChops.multiply(original_alpha, mask))
    return texture


def crop_asset(sheet: Image.Image, box: tuple[int, int, int, int], threshold: int = 18) -> Image.Image:
    return remove_sheet_bg(sheet.crop(box), threshold)


def remove_chroma_key(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = pixels[x, y]
            if g > 145 and r < 95 and b < 95 and g > r * 1.45 and g > b * 1.45:
                pixels[x, y] = (r, g, b, 0)
    alpha = rgba.getchannel("A").filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.45))
    rgba.putalpha(alpha)
    return rgba


def save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


def create_floor_tiles(sheet: Image.Image) -> None:
    boxes = FLOOR_SOURCES[:4]
    for mask in range(16):
        tile = make_diamond_floor(sheet.crop(boxes[mask % len(boxes)]))
        save(tile, TILE_ROOT / "floor" / f"floor_cave_v2_mask_{mask:02d}.png")


def create_addon_tiles(sheet: Image.Image) -> None:
    edge = fit_to_canvas(crop_asset(sheet, ASSET_BOXES["edge"], 16), (128, 64), 0.98, 0.52)
    for key in ["nw", "ne", "se", "sw"]:
        save(edge, TILE_ROOT / "edge" / f"edge_cave_v2_{key}_lip.png")

    wall_nw = fit_to_canvas(crop_asset(sheet, ASSET_BOXES["wall_nw"], 18), (160, 96), 0.98, 0.62)
    wall_ne = fit_to_canvas(crop_asset(sheet, ASSET_BOXES["wall_ne"], 18), (160, 96), 0.98, 0.62)
    save(wall_ne, TILE_ROOT / "wall" / "wall_cave_v2_ne_straight_00.png")
    save(wall_nw, TILE_ROOT / "wall" / "wall_cave_v2_nw_straight_00.png")
    for mask in range(16):
        save(wall_ne if mask % 2 == 0 else wall_nw, TILE_ROOT / "wall" / f"wall_cave_v2_mask_{mask:02d}.png")

    save(fit_to_canvas(crop_asset(sheet, ASSET_BOXES["door_ne"], 18), (128, 120), 0.98, 0.58), TILE_ROOT / "door" / "door_cave_v2_ne_open.png")
    save(fit_to_canvas(crop_asset(sheet, ASSET_BOXES["door_nw"], 18), (128, 120), 0.98, 0.58), TILE_ROOT / "door" / "door_cave_v2_nw_open.png")

    transparent = Image.new("RGBA", (128, 64), (0, 0, 0, 0))
    for corner in ["inner_nw", "inner_ne", "inner_se", "inner_sw", "outer_nw", "outer_ne", "outer_se", "outer_sw"]:
        save(transparent, TILE_ROOT / "overlay" / f"floor_cave_v2_corner_{corner}.png")


def create_props(sheet: Image.Image) -> dict[str, Image.Image]:
    throne_source = crop_asset(sheet, ASSET_BOXES["throne"], 18)
    props = {
        "prop_entrance_gate_v2_back.png": fit_to_canvas(crop_asset(sheet, ASSET_BOXES["entrance"], 18), (220, 170), 0.98, 0.62),
        "prop_small_brazier_v2_back.png": fit_to_canvas(crop_asset(sheet, ASSET_BOXES["brazier"], 18), (130, 150), 0.98, 0.65),
        "prop_throne_v2_back.png": fit_to_canvas(throne_source, (180, 160), 0.98, 0.64),
        "prop_throne_v2_front.png": fit_to_canvas(lower_alpha_slice(throne_source, 0.56), (180, 80), 0.98, 0.74),
        "prop_treasure_pile_v2_front.png": fit_to_canvas(crop_asset(sheet, ASSET_BOXES["treasure"], 18), (190, 130), 0.98, 0.60),
        "prop_weapon_rack_v2_back.png": fit_to_canvas(crop_asset(sheet, ASSET_BOXES["weapon_rack"], 18), (170, 150), 0.98, 0.62),
        "prop_recovery_nest_v2_front.png": fit_to_canvas(crop_asset(sheet, ASSET_BOXES["recovery"], 18), (190, 130), 0.98, 0.60),
        "prop_foundation_marks_v2_back.png": fit_to_canvas(crop_asset(sheet, ASSET_BOXES["foundation"], 18), (160, 100), 0.98, 0.58),
        "prop_watch_post_v2_front.png": fit_to_canvas(crop_asset(sheet, ASSET_BOXES["watch_post"], 18), (200, 230), 0.98, 0.70),
    }
    for name, image in props.items():
        save(image, PROP_ROOT / name)

    spike = fit_to_canvas(crop_asset(sheet, ASSET_BOXES["spike_proxy"], 18), (128, 64), 0.96, 0.56)
    save(spike, PROP_ROOT / "trap_spike_v2_idle_00.png")
    for index, opacity in enumerate([160, 205, 255, 190]):
        frame = spike.copy()
        alpha = frame.getchannel("A").point(lambda value, op=opacity: min(value, op))
        frame.putalpha(alpha)
        save(frame, PROP_ROOT / f"trap_spike_v2_trigger_{index:02d}.png")
    create_spike_frames_from_sheet()
    return props


def create_spike_frames_from_sheet() -> None:
    if not SPIKE_SHEET_PATH.exists():
        return
    sheet = Image.open(SPIKE_SHEET_PATH).convert("RGBA")
    frame_w = sheet.width // 4
    frames = []
    for index in range(4):
        left = index * frame_w
        right = sheet.width if index == 3 else (index + 1) * frame_w
        frame = remove_chroma_key(sheet.crop((left, 0, right, sheet.height)))
        frame = fit_to_canvas(frame, (128, 64), 0.98, 0.58)
        frames.append(frame)
    save(frames[0], PROP_ROOT / "trap_spike_v2_idle_00.png")
    for index, frame in enumerate(frames):
        save(frame, PROP_ROOT / f"trap_spike_v2_trigger_{index:02d}.png")


def create_room_icons(props: dict[str, Image.Image]) -> None:
    mapping = {
        "room_v2_entrance.png": "prop_entrance_gate_v2_back.png",
        "room_v2_spike_corridor.png": "trap_spike_v2_trigger_02.png",
        "room_v2_center.png": "prop_small_brazier_v2_back.png",
        "room_v2_throne.png": "prop_throne_v2_back.png",
        "room_v2_barracks.png": "prop_weapon_rack_v2_back.png",
        "room_v2_treasure.png": "prop_treasure_pile_v2_front.png",
        "room_v2_recovery.png": "prop_recovery_nest_v2_front.png",
        "room_v2_build_slot.png": "prop_foundation_marks_v2_back.png",
        "room_v2_watch_post.png": "prop_watch_post_v2_front.png",
    }
    floor = Image.open(TILE_ROOT / "floor" / "floor_cave_v2_mask_15.png").convert("RGBA")
    for icon_name, prop_name in mapping.items():
        canvas = Image.new("RGBA", (160, 160), (0, 0, 0, 0))
        base = floor.resize((142, 71), Image.Resampling.LANCZOS)
        canvas.alpha_composite(base, (9, 82))
        source_path = PROP_ROOT / prop_name
        if source_path.exists():
            prop = Image.open(source_path).convert("RGBA")
        else:
            prop = props.get(prop_name, Image.new("RGBA", (64, 64), (0, 0, 0, 0)))
        prop = trim_alpha(prop)
        scale = min(130 / max(1, prop.width), 112 / max(1, prop.height))
        prop = prop.resize((max(1, int(prop.width * scale)), max(1, int(prop.height * scale))), Image.Resampling.LANCZOS)
        canvas.alpha_composite(prop, ((160 - prop.width) // 2, 126 - prop.height))
        save(canvas, ROOM_ICON_ROOT / icon_name)


def create_preview() -> None:
    sheet = Image.new("RGBA", (1400, 900), (11, 9, 16, 255))
    for index in range(16):
        tile = Image.open(TILE_ROOT / "floor" / f"floor_cave_v2_mask_{index:02d}.png").convert("RGBA")
        sheet.alpha_composite(tile, (36 + (index % 4) * 146, 34 + (index // 4) * 84))
    for gx, gy, mask in [(0, 1, 15), (1, 1, 15), (2, 1, 12), (1, 0, 13), (1, 2, 7), (3, 1, 8)]:
        tile = Image.open(TILE_ROOT / "floor" / f"floor_cave_v2_mask_{mask:02d}.png").convert("RGBA")
        x = 760 + (gx - gy) * 64
        y = 148 + (gx + gy) * 32
        sheet.alpha_composite(tile, (x, y))
    for name, pos in [
        ("prop_entrance_gate_v2_back.png", (690, 392)),
        ("prop_throne_v2_back.png", (870, 420)),
        ("prop_treasure_pile_v2_front.png", (1040, 458)),
        ("prop_recovery_nest_v2_front.png", (1172, 462)),
        ("prop_weapon_rack_v2_back.png", (690, 616)),
        ("prop_watch_post_v2_front.png", (835, 550)),
        ("trap_spike_v2_trigger_02.png", (1040, 662)),
        ("prop_foundation_marks_v2_back.png", (1170, 690)),
    ]:
        image = Image.open(PROP_ROOT / name).convert("RGBA")
        sheet.alpha_composite(image, pos)
    save(sheet.convert("RGB"), PREVIEW_PATH)


def main() -> None:
    if not SHEET_PATH.exists():
        raise FileNotFoundError(SHEET_PATH)
    ensure_dirs()
    sheet = Image.open(SHEET_PATH).convert("RGB")
    create_floor_tiles(sheet)
    create_addon_tiles(sheet)
    props = create_props(sheet)
    create_room_icons(props)
    create_preview()
    print(f"sliced GPT image sheet: {SHEET_PATH}")
    print(f"updated assets under {TILE_ROOT}, {PROP_ROOT}, {ROOM_ICON_ROOT}")
    print(f"preview: {PREVIEW_PATH}")


if __name__ == "__main__":
    main()
