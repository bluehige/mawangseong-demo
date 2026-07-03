from __future__ import annotations

from pathlib import Path
from random import Random

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
TILE_ROOT = ROOT / "assets" / "tiles" / "cave_v2"
PROP_ROOT = ROOT / "assets" / "props" / "v2"
ROOM_ICON_ROOT = ROOT / "assets" / "ui" / "room_v2"
PREVIEW_PATH = ROOT / "output" / "quarter_v2_asset_preview.png"

SCALE = 3
TILE_W = 128
TILE_H = 64
DIAMOND = [(64, 4), (124, 32), (64, 60), (4, 32)]
SIDE_POINTS = {
    "N": (DIAMOND[0], DIAMOND[1]),
    "E": (DIAMOND[1], DIAMOND[2]),
    "S": (DIAMOND[2], DIAMOND[3]),
    "W": (DIAMOND[3], DIAMOND[0]),
}
MASK_BITS = {"N": 1, "E": 2, "S": 4, "W": 8}


def rgba(hex_value: str, alpha: int = 255) -> tuple[int, int, int, int]:
    hex_value = hex_value.strip("#")
    return (
        int(hex_value[0:2], 16),
        int(hex_value[2:4], 16),
        int(hex_value[4:6], 16),
        alpha,
    )


def scale_points(points: list[tuple[int, int]]) -> list[tuple[int, int]]:
    return [(x * SCALE, y * SCALE) for x, y in points]


def make_canvas(size: tuple[int, int], scale: bool = True) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    if scale:
        image = Image.new("RGBA", (size[0] * SCALE, size[1] * SCALE), (0, 0, 0, 0))
    else:
        image = Image.new("RGBA", size, (0, 0, 0, 0))
    return image, ImageDraw.Draw(image)


def downsample(image: Image.Image) -> Image.Image:
    return image.resize((image.width // SCALE, image.height // SCALE), Image.Resampling.LANCZOS)


def draw_line(draw: ImageDraw.ImageDraw, points, fill, width=1) -> None:
    draw.line([(x * SCALE, y * SCALE) for x, y in points], fill=fill, width=max(1, width * SCALE), joint="curve")


def draw_polygon(draw: ImageDraw.ImageDraw, points, fill, outline=None) -> None:
    draw.polygon(scale_points(points), fill=fill, outline=outline)


def save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


def lerp(a: tuple[int, int], b: tuple[int, int], t: float) -> tuple[int, int]:
    return (round(a[0] + (b[0] - a[0]) * t), round(a[1] + (b[1] - a[1]) * t))


def draw_floor(mask: int, path: Path) -> None:
    image, draw = make_canvas((TILE_W, TILE_H))
    draw_polygon(draw, DIAMOND, rgba("2f3038"), rgba("6a6272", 180))
    draw_polygon(draw, [(64, 8), (116, 32), (64, 56), (12, 32)], rgba("3b3a43", 245))

    rng = Random(mask + 420)
    for _ in range(9):
        x = rng.randint(22, 106)
        y = rng.randint(18, 46)
        dx = rng.randint(-14, 14)
        dy = rng.randint(-6, 6)
        draw_line(draw, [(x, y), (x + dx, y + dy)], rgba("17151d", 80), 1)

    for side, bit in MASK_BITS.items():
        start, end = SIDE_POINTS[side]
        open_edge = (mask & bit) != 0
        if open_edge:
            a = lerp(start, end, 0.26)
            b = lerp(start, end, 0.74)
            draw_line(draw, [a, b], rgba("988872", 180), 3)
            draw_line(draw, [a, b], rgba("c5ad7b", 120), 1)
        else:
            draw_line(draw, [start, end], rgba("0c0a10", 205), 3)
            draw_line(draw, [lerp(start, end, 0.08), lerp(start, end, 0.92)], rgba("504756", 120), 1)

    save(downsample(image), path)


def draw_edge(side: str, path: Path) -> None:
    image, draw = make_canvas((TILE_W, TILE_H))
    start, end = SIDE_POINTS[side]
    center = lerp(start, end, 0.5)
    lower = (center[0], center[1] + 16)
    draw_polygon(draw, [start, end, lower], rgba("100d14", 190), rgba("392a42", 155))
    draw_line(draw, [start, end], rgba("16101a", 230), 4)
    draw_line(draw, [lerp(start, end, 0.12), lerp(start, end, 0.88)], rgba("76657d", 120), 1)
    save(downsample(image), path)


def draw_wall_mask(mask: int, path: Path) -> None:
    image, draw = make_canvas((TILE_W, 96))
    draw_polygon(draw, DIAMOND, rgba("1d1a23", 90))
    if mask & MASK_BITS["N"]:
        draw_riser(draw, DIAMOND[0], DIAMOND[1], -25)
    if mask & MASK_BITS["W"]:
        draw_riser(draw, DIAMOND[3], DIAMOND[0], -22)
    if mask & MASK_BITS["E"]:
        draw_riser(draw, DIAMOND[1], DIAMOND[2], -20)
    if mask & MASK_BITS["S"]:
        draw_riser(draw, DIAMOND[2], DIAMOND[3], -20)
    save(downsample(image), path)


def draw_riser(draw: ImageDraw.ImageDraw, start: tuple[int, int], end: tuple[int, int], height: int) -> None:
    top_start = (start[0], start[1] + height)
    top_end = (end[0], end[1] + height)
    draw_polygon(draw, [top_start, top_end, end, start], rgba("211b29", 218), rgba("4e4058", 150))
    draw_line(draw, [top_start, top_end], rgba("80738a", 120), 1)


def draw_door(kind: str, path: Path) -> None:
    image, draw = make_canvas((128, 120))
    base = [(28, 98), (100, 98), (110, 112), (18, 112)]
    draw.polygon(scale_points(base), fill=rgba("201923", 230), outline=rgba("6d5d73", 180))
    arch = [38 * SCALE, 26 * SCALE, 90 * SCALE, 112 * SCALE]
    draw.rounded_rectangle(arch, radius=20 * SCALE, fill=rgba("251f2c", 235), outline=rgba("8c7b8e", 200), width=3 * SCALE)
    inner = [50 * SCALE, 42 * SCALE, 78 * SCALE, 112 * SCALE]
    draw.rounded_rectangle(inner, radius=12 * SCALE, fill=rgba("08070b", 245), outline=rgba("3b3142", 220), width=2 * SCALE)
    glow = rgba("7bc7ff" if kind == "ne" else "b58cff", 115)
    draw.arc([48 * SCALE, 40 * SCALE, 80 * SCALE, 98 * SCALE], 180, 360, fill=glow, width=2 * SCALE)
    save(downsample(image), path)


def draw_floor_prop_base(draw: ImageDraw.ImageDraw, y: int = 112) -> None:
    points = [(64, y - 28), (116, y - 4), (64, y + 20), (12, y - 4)]
    draw_polygon(draw, points, rgba("1d1b22", 90), rgba("6b5f74", 80))


def make_prop(size=(160, 150)):
    return make_canvas(size)


def draw_entrance_gate(path: Path) -> None:
    image, draw = make_prop((190, 160))
    draw_floor_prop_base(draw, 130)
    for x in (48, 142):
        draw.rounded_rectangle([x * SCALE - 12 * SCALE, 46 * SCALE, x * SCALE + 12 * SCALE, 132 * SCALE], 5 * SCALE, fill=rgba("2b2431"), outline=rgba("85748e", 190), width=2 * SCALE)
    draw.arc([42 * SCALE, 22 * SCALE, 148 * SCALE, 134 * SCALE], 180, 360, fill=rgba("88788d", 230), width=8 * SCALE)
    draw.rectangle([58 * SCALE, 78 * SCALE, 132 * SCALE, 132 * SCALE], fill=rgba("09070b", 235))
    for x in range(64, 130, 14):
        draw.line([(x * SCALE, 70 * SCALE), (x * SCALE, 134 * SCALE)], fill=rgba("5d5065", 220), width=2 * SCALE)
    save(downsample(image), path)


def draw_brazier(path: Path) -> None:
    image, draw = make_prop((110, 130))
    draw_floor_prop_base(draw, 108)
    draw.ellipse([36 * SCALE, 78 * SCALE, 74 * SCALE, 102 * SCALE], fill=rgba("3d2831"), outline=rgba("9b7e60", 210), width=2 * SCALE)
    draw.polygon(scale_points([(44, 80), (54, 34), (66, 82)]), fill=rgba("ff8a28", 220))
    draw.polygon(scale_points([(50, 76), (57, 44), (65, 78)]), fill=rgba("ffd56b", 210))
    save(downsample(image), path)


def draw_throne_back(path: Path) -> None:
    image, draw = make_prop((170, 160))
    draw_floor_prop_base(draw, 130)
    draw.rounded_rectangle([48 * SCALE, 36 * SCALE, 122 * SCALE, 132 * SCALE], 10 * SCALE, fill=rgba("31263a"), outline=rgba("8a7892", 210), width=3 * SCALE)
    draw.polygon(scale_points([(52, 42), (84, 18), (118, 42)]), fill=rgba("4a3554"), outline=rgba("aa91a8", 200))
    draw.ellipse([72 * SCALE, 56 * SCALE, 98 * SCALE, 86 * SCALE], fill=rgba("7440a0", 210))
    save(downsample(image), path)


def draw_throne_front(path: Path) -> None:
    image, draw = make_prop((170, 100))
    draw.polygon(scale_points([(42, 48), (128, 48), (142, 74), (84, 96), (28, 74)]), fill=rgba("211923", 230), outline=rgba("9a7d95", 180))
    draw.rectangle([54 * SCALE, 28 * SCALE, 116 * SCALE, 60 * SCALE], fill=rgba("392a44", 230), outline=rgba("806d84", 180), width=2 * SCALE)
    save(downsample(image), path)


def draw_treasure(path: Path) -> None:
    image, draw = make_prop((150, 120))
    draw_floor_prop_base(draw, 98)
    draw.ellipse([38 * SCALE, 48 * SCALE, 118 * SCALE, 96 * SCALE], fill=rgba("493220", 235), outline=rgba("a98745", 210), width=2 * SCALE)
    for x, y, color in [(54, 58, "ffd56b"), (74, 48, "d88a2c"), (92, 62, "f7e389"), (104, 54, "b66cff")]:
        draw.ellipse([x * SCALE, y * SCALE, (x + 12) * SCALE, (y + 10) * SCALE], fill=rgba(color, 230))
    save(downsample(image), path)


def draw_weapon_rack(path: Path) -> None:
    image, draw = make_prop((150, 150))
    draw_floor_prop_base(draw, 126)
    draw.rectangle([42 * SCALE, 54 * SCALE, 108 * SCALE, 118 * SCALE], fill=rgba("2b2225", 210), outline=rgba("806855", 190), width=2 * SCALE)
    for x in (54, 72, 90):
        draw.line([(x * SCALE, 42 * SCALE), ((x + 18) * SCALE, 118 * SCALE)], fill=rgba("a0a8a6", 220), width=2 * SCALE)
        draw.polygon(scale_points([(x - 3, 43), (x + 4, 34), (x + 9, 46)]), fill=rgba("d1d4cb", 230))
    save(downsample(image), path)


def draw_recovery(path: Path) -> None:
    image, draw = make_prop((150, 130))
    draw_floor_prop_base(draw, 106)
    draw.ellipse([38 * SCALE, 48 * SCALE, 116 * SCALE, 98 * SCALE], fill=rgba("17362f", 230), outline=rgba("54d6a5", 210), width=3 * SCALE)
    draw.ellipse([54 * SCALE, 58 * SCALE, 100 * SCALE, 88 * SCALE], fill=rgba("32b68b", 170))
    draw.arc([44 * SCALE, 38 * SCALE, 110 * SCALE, 104 * SCALE], 10, 340, fill=rgba("a1ffe0", 130), width=2 * SCALE)
    save(downsample(image), path)


def draw_foundation(path: Path) -> None:
    image, draw = make_prop((130, 90))
    draw_floor_prop_base(draw, 56)
    draw.line([(30 * SCALE, 54 * SCALE), (100 * SCALE, 54 * SCALE)], fill=rgba("c8b88e", 180), width=2 * SCALE)
    draw.line([(44 * SCALE, 38 * SCALE), (84 * SCALE, 72 * SCALE)], fill=rgba("c8b88e", 160), width=2 * SCALE)
    draw.line([(84 * SCALE, 38 * SCALE), (44 * SCALE, 72 * SCALE)], fill=rgba("c8b88e", 160), width=2 * SCALE)
    save(downsample(image), path)


def draw_watch_post(path: Path) -> None:
    image, draw = make_prop((150, 150))
    draw_floor_prop_base(draw, 126)
    draw.rectangle([60 * SCALE, 62 * SCALE, 90 * SCALE, 122 * SCALE], fill=rgba("312421", 230), outline=rgba("8a6b55", 200), width=2 * SCALE)
    draw.polygon(scale_points([(40, 64), (76, 30), (112, 64)]), fill=rgba("4a2c35", 235), outline=rgba("a88974", 200))
    draw.ellipse([66 * SCALE, 70 * SCALE, 84 * SCALE, 88 * SCALE], fill=rgba("65d8ff", 210))
    save(downsample(image), path)


def draw_spike_frame(path: Path, frame: int) -> None:
    image, draw = make_canvas((128, 64))
    draw_polygon(draw, DIAMOND, rgba("282832", 210), rgba("695f74", 140))
    height = [8, 20, 28, 14][frame]
    for x, y in [(45, 32), (62, 27), (80, 34), (68, 42)]:
        draw.polygon(scale_points([(x - 5, y + 9), (x, y - height), (x + 5, y + 9)]), fill=rgba("c7c7bd", 230), outline=rgba("544d55", 180))
    save(downsample(image), path)


def draw_straight_wall(path: Path, side: str) -> None:
    image, draw = make_canvas((160, 96))
    x0 = 18 if side == "nw" else 42
    draw.rounded_rectangle([x0 * SCALE, 22 * SCALE, (x0 + 94) * SCALE, 80 * SCALE], 5 * SCALE, fill=rgba("211a27", 230), outline=rgba("6c6073", 180), width=2 * SCALE)
    for x in range(x0 + 10, x0 + 88, 18):
        draw.line([(x * SCALE, 28 * SCALE), (x * SCALE, 76 * SCALE)], fill=rgba("302536", 160), width=1 * SCALE)
    save(downsample(image), path)


def generate_tiles() -> None:
    for folder in ["floor", "edge", "wall", "door", "overlay"]:
        (TILE_ROOT / folder).mkdir(parents=True, exist_ok=True)
    for mask in range(16):
        draw_floor(mask, TILE_ROOT / "floor" / f"floor_cave_v2_mask_{mask:02d}.png")
        draw_wall_mask(mask, TILE_ROOT / "wall" / f"wall_cave_v2_mask_{mask:02d}.png")
    for key, side in [("ne_lip", "N"), ("se_lip", "E"), ("sw_lip", "S"), ("nw_lip", "W")]:
        draw_edge(side, TILE_ROOT / "edge" / f"edge_cave_v2_{key}.png")
    draw_straight_wall(TILE_ROOT / "wall" / "wall_cave_v2_ne_straight_00.png", "ne")
    draw_straight_wall(TILE_ROOT / "wall" / "wall_cave_v2_nw_straight_00.png", "nw")
    draw_door("ne", TILE_ROOT / "door" / "door_cave_v2_ne_open.png")
    draw_door("nw", TILE_ROOT / "door" / "door_cave_v2_nw_open.png")

    for corner in ["inner_nw", "inner_ne", "inner_se", "inner_sw", "outer_nw", "outer_ne", "outer_se", "outer_sw"]:
        img, draw = make_canvas((128, 64))
        draw.ellipse([50 * SCALE, 24 * SCALE, 78 * SCALE, 42 * SCALE], fill=rgba("8a6fa0", 120))
        save(downsample(img), TILE_ROOT / "overlay" / f"floor_cave_v2_corner_{corner}.png")


def generate_props() -> None:
    PROP_ROOT.mkdir(parents=True, exist_ok=True)
    draw_entrance_gate(PROP_ROOT / "prop_entrance_gate_v2_back.png")
    draw_brazier(PROP_ROOT / "prop_small_brazier_v2_back.png")
    draw_throne_back(PROP_ROOT / "prop_throne_v2_back.png")
    draw_throne_front(PROP_ROOT / "prop_throne_v2_front.png")
    draw_treasure(PROP_ROOT / "prop_treasure_pile_v2_front.png")
    draw_weapon_rack(PROP_ROOT / "prop_weapon_rack_v2_back.png")
    draw_recovery(PROP_ROOT / "prop_recovery_nest_v2_front.png")
    draw_foundation(PROP_ROOT / "prop_foundation_marks_v2_back.png")
    draw_watch_post(PROP_ROOT / "prop_watch_post_v2_front.png")
    draw_spike_frame(PROP_ROOT / "trap_spike_v2_idle_00.png", 0)
    for frame in range(4):
        draw_spike_frame(PROP_ROOT / f"trap_spike_v2_trigger_{frame:02d}.png", frame)


def paste_fit(canvas: Image.Image, source_path: Path, box: tuple[int, int, int, int]) -> None:
    source = Image.open(source_path).convert("RGBA")
    max_w = box[2] - box[0]
    max_h = box[3] - box[1]
    scale = min(max_w / source.width, max_h / source.height)
    size = (max(1, int(source.width * scale)), max(1, int(source.height * scale)))
    source = source.resize(size, Image.Resampling.LANCZOS)
    x = box[0] + (max_w - size[0]) // 2
    y = box[1] + (max_h - size[1]) // 2
    canvas.alpha_composite(source, (x, y))


def make_room_icon(file_name: str, prop_specs: list[tuple[str, tuple[int, int, int, int]]], mask: int = 15) -> None:
    ROOM_ICON_ROOT.mkdir(parents=True, exist_ok=True)
    canvas = Image.new("RGBA", (160, 160), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (160, 160), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.ellipse((24, 104, 136, 142), fill=rgba("050407", 120))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(3)))
    floor = Image.open(TILE_ROOT / "floor" / f"floor_cave_v2_mask_{mask:02d}.png").convert("RGBA")
    floor = floor.resize((142, 71), Image.Resampling.LANCZOS)
    canvas.alpha_composite(floor, (9, 78))
    for prop_name, box in prop_specs:
        paste_fit(canvas, PROP_ROOT / prop_name, box)
    save(canvas, ROOM_ICON_ROOT / file_name)


def generate_room_icons() -> None:
    make_room_icon("room_v2_entrance.png", [("prop_entrance_gate_v2_back.png", (16, 14, 144, 142))], 5)
    make_room_icon("room_v2_spike_corridor.png", [("trap_spike_v2_trigger_02.png", (32, 72, 128, 132))], 5)
    make_room_icon("room_v2_center.png", [("prop_small_brazier_v2_back.png", (50, 30, 110, 124))], 15)
    make_room_icon("room_v2_throne.png", [("prop_throne_v2_back.png", (20, 10, 140, 142))], 4)
    make_room_icon("room_v2_barracks.png", [("prop_weapon_rack_v2_back.png", (30, 26, 132, 144))], 2)
    make_room_icon("room_v2_treasure.png", [("prop_treasure_pile_v2_front.png", (22, 50, 138, 140))], 1)
    make_room_icon("room_v2_recovery.png", [("prop_recovery_nest_v2_front.png", (24, 42, 136, 140))], 8)
    make_room_icon("room_v2_build_slot.png", [("prop_foundation_marks_v2_back.png", (28, 58, 132, 132))], 5)
    make_room_icon("room_v2_watch_post.png", [("prop_watch_post_v2_front.png", (30, 24, 130, 146))], 15)


def generate_preview() -> None:
    PREVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)
    sheet = Image.new("RGBA", (1400, 900), rgba("0b0910"))
    for i in range(16):
        tile = Image.open(TILE_ROOT / "floor" / f"floor_cave_v2_mask_{i:02d}.png")
        x = 40 + (i % 4) * 145
        y = 36 + (i // 4) * 86
        sheet.alpha_composite(tile, (x, y))
    sample_cells = [(0, 1, 15), (1, 1, 15), (2, 1, 12), (1, 0, 13), (1, 2, 7), (3, 1, 8)]
    for gx, gy, mask in sample_cells:
        tile = Image.open(TILE_ROOT / "floor" / f"floor_cave_v2_mask_{mask:02d}.png")
        sx = 760 + (gx - gy) * 64
        sy = 150 + (gx + gy) * 32
        sheet.alpha_composite(tile, (sx, sy))
    for name, pos in [
        ("prop_entrance_gate_v2_back.png", (700, 430)),
        ("prop_throne_v2_back.png", (900, 405)),
        ("prop_treasure_pile_v2_front.png", (1070, 442)),
        ("prop_recovery_nest_v2_front.png", (1185, 450)),
        ("prop_weapon_rack_v2_back.png", (690, 620)),
        ("prop_watch_post_v2_front.png", (850, 615)),
        ("trap_spike_v2_trigger_02.png", (1010, 660)),
        ("prop_foundation_marks_v2_back.png", (1160, 690)),
    ]:
        prop = Image.open(PROP_ROOT / name)
        sheet.alpha_composite(prop, pos)
    save(sheet.convert("RGB"), PREVIEW_PATH)


def main() -> None:
    generate_tiles()
    generate_props()
    generate_room_icons()
    generate_preview()
    print(f"generated quarter v2 assets under {TILE_ROOT}, {PROP_ROOT}, and {ROOM_ICON_ROOT}")
    print(f"preview: {PREVIEW_PATH}")


if __name__ == "__main__":
    main()
