import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT_CLEAN = ROOT / "docs" / "concepts" / "spaced_grid_path_concept_2026-07-06.png"
OUT_OVERLAY = ROOT / "docs" / "concepts" / "spaced_grid_path_concept_overlay_2026-07-06.png"

GRID_ROOM_COUNT = 4
ROOM_CELLS = 5
GAP_CELLS = 2
STRIDE = ROOM_CELLS + GAP_CELLS
MASTER_CELLS = GRID_ROOM_COUNT * ROOM_CELLS + (GRID_ROOM_COUNT - 1) * GAP_CELLS

TILE_W = 68
TILE_H = 34
CANVAS_W = 2350
CANVAS_H = 1520
TOP_MARGIN = 120


ROOMS = {
    "throne": {
        "grid": (1, 0),
        "label": "왕좌",
        "role": "throne",
        "open": {"S"},
        "fill": (72, 42, 57),
    },
    "barracks": {
        "grid": (0, 1),
        "label": "병영",
        "role": "barracks",
        "open": {"E"},
        "fill": (76, 64, 49),
    },
    "recovery": {
        "grid": (2, 1),
        "label": "회복 둥지",
        "role": "recovery",
        "open": {"W"},
        "fill": (42, 70, 64),
    },
    "entrance": {
        "grid": (0, 2),
        "label": "입구",
        "role": "entrance",
        "open": {"E"},
        "fill": (59, 62, 75),
    },
    "treasure": {
        "grid": (2, 2),
        "label": "보물 보관실",
        "role": "treasure",
        "open": {"W"},
        "fill": (86, 67, 38),
    },
    "slot_01": {
        "grid": (1, 3),
        "label": "건설 가능지",
        "role": "slot",
        "open": {"N"},
        "fill": (61, 47, 79),
    },
}


def load_font(size: int, bold: bool = False):
    candidates = [
        Path("C:/Windows/Fonts/malgunbd.ttf" if bold else "C:/Windows/Fonts/malgun.ttf"),
        Path("C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf"),
    ]
    for path in candidates:
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


FONT_TITLE = load_font(32, True)
FONT_LABEL = load_font(23, True)
FONT_SMALL = load_font(17)
FONT_TINY = load_font(13)


def room_origin(grid: tuple[int, int]) -> tuple[int, int]:
    gx, gy = grid
    return gx * STRIDE, gy * STRIDE


def iso_center(x: float, y: float) -> tuple[float, float]:
    sx = (x - y) * (TILE_W / 2.0) + CANVAS_W / 2.0
    sy = (x + y) * (TILE_H / 2.0) + TOP_MARGIN
    return sx, sy


def diamond(x: int, y: int) -> list[tuple[float, float]]:
    cx, cy = iso_center(x, y)
    return [
        (cx, cy - TILE_H / 2.0),
        (cx + TILE_W / 2.0, cy),
        (cx, cy + TILE_H / 2.0),
        (cx - TILE_W / 2.0, cy),
    ]


def edge_points(x: int, y: int, side: str) -> tuple[tuple[float, float], tuple[float, float]]:
    top, right, bottom, left = diamond(x, y)
    if side == "N":
        return top, right
    if side == "E":
        return right, bottom
    if side == "S":
        return bottom, left
    if side == "W":
        return left, top
    raise ValueError(side)


def blend(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(int(a[index] + (b[index] - a[index]) * t) for index in range(3))


def draw_background(draw: ImageDraw.ImageDraw) -> None:
    rng = random.Random(701)
    for _ in range(820):
        gx = rng.uniform(-4, MASTER_CELLS + 4)
        gy = rng.uniform(-4, MASTER_CELLS + 4)
        sx, sy = iso_center(gx, gy)
        radius = rng.uniform(5, 27)
        color = blend((18, 16, 23), (55, 49, 60), rng.random() * 0.7)
        draw.ellipse(
            (sx - radius, sy - radius * 0.58, sx + radius, sy + radius * 0.58),
            fill=color + (120,),
            outline=(8, 7, 10, 80),
        )


def draw_tile(draw: ImageDraw.ImageDraw, cell: tuple[int, int], fill, outline=None, inset: float = 0.0) -> None:
    pts = diamond(*cell)
    if inset > 0.0:
        cx, cy = iso_center(*cell)
        scale = max(0.0, 1.0 - inset / 36.0)
        pts = [(cx + (px - cx) * scale, cy + (py - cy) * scale) for px, py in pts]
    draw.polygon(pts, fill=fill)
    if outline is not None:
        draw.line(pts + [pts[0]], fill=outline, width=1)


def add_rect(target: set[tuple[int, int]], x0: int, y0: int, w: int, h: int) -> None:
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            if 0 <= x < MASTER_CELLS and 0 <= y < MASTER_CELLS:
                target.add((x, y))


def build_path_cells() -> set[tuple[int, int]]:
    cells: set[tuple[int, int]] = set()
    # Main vertical gap corridors.
    add_rect(cells, 5, 5, 2, 16)
    add_rect(cells, 12, 5, 2, 13)
    # Horizontal gap connectors. These are the only walkable "streets" between room blocks.
    add_rect(cells, 5, 5, 9, 2)
    add_rect(cells, 5, 12, 9, 2)
    add_rect(cells, 5, 19, 7, 2)
    return cells


def room_cells(origin: tuple[int, int]) -> set[tuple[int, int]]:
    x0, y0 = origin
    return {(x, y) for y in range(y0, y0 + ROOM_CELLS) for x in range(x0, x0 + ROOM_CELLS)}


def socket_cells(origin: tuple[int, int], side: str) -> set[tuple[int, int]]:
    x0, y0 = origin
    if side == "N":
        return {(x0 + 2, y0), (x0 + 3, y0)}
    if side == "S":
        return {(x0 + 2, y0 + ROOM_CELLS - 1), (x0 + 3, y0 + ROOM_CELLS - 1)}
    if side == "E":
        return {(x0 + ROOM_CELLS - 1, y0 + 2), (x0 + ROOM_CELLS - 1, y0 + 3)}
    if side == "W":
        return {(x0, y0 + 2), (x0, y0 + 3)}
    return set()


def draw_rough_wall(draw: ImageDraw.ImageDraw, cell: tuple[int, int], side: str, color=(82, 73, 83)) -> None:
    start, end = edge_points(*cell, side)
    draw.line([start, end], fill=(8, 6, 10, 230), width=8)
    draw.line([start, end], fill=color + (235,), width=5)
    length = math.dist(start, end)
    count = max(2, int(length / 14))
    rng = random.Random(cell[0] * 401 + cell[1] * 503 + ord(side[0]) * 29)
    for index in range(count + 1):
        t = index / count
        px = start[0] + (end[0] - start[0]) * t + rng.uniform(-3.6, 3.6)
        py = start[1] + (end[1] - start[1]) * t + rng.uniform(-3.0, 3.0)
        radius = rng.uniform(2.5, 5.6)
        shade = blend((44, 39, 48), (103, 93, 98), rng.random())
        draw.ellipse(
            (px - radius, py - radius * 0.72, px + radius, py + radius * 0.72),
            fill=shade + (245,),
            outline=(10, 8, 12, 210),
        )


def draw_path_edges(draw: ImageDraw.ImageDraw, path_cells: set[tuple[int, int]], floor_cells: set[tuple[int, int]]) -> None:
    directions = {
        "N": (0, -1),
        "E": (1, 0),
        "S": (0, 1),
        "W": (-1, 0),
    }
    for cell in sorted(path_cells, key=lambda value: (value[0] + value[1], value[0])):
        for side, delta in directions.items():
            neighbor = (cell[0] + delta[0], cell[1] + delta[1])
            if neighbor in path_cells:
                continue
            if neighbor in floor_cells:
                continue
            start, end = edge_points(*cell, side)
            draw.line([start, end], fill=(15, 12, 17, 190), width=4)
            draw.line([start, end], fill=(63, 56, 64, 175), width=2)


def draw_room_walls(draw: ImageDraw.ImageDraw, origin: tuple[int, int], open_sides: set[str]) -> None:
    x0, y0 = origin
    cells = room_cells(origin)
    for cell in sorted(cells, key=lambda value: (value[0] + value[1], value[0])):
        x, y = cell
        boundary_sides = []
        if y == y0:
            boundary_sides.append("N")
        if x == x0 + ROOM_CELLS - 1:
            boundary_sides.append("E")
        if y == y0 + ROOM_CELLS - 1:
            boundary_sides.append("S")
        if x == x0:
            boundary_sides.append("W")
        for side in boundary_sides:
            if side in open_sides and cell in socket_cells(origin, side):
                start, end = edge_points(*cell, side)
                draw.line([start, end], fill=(215, 157, 72, 230), width=5)
                continue
            draw_rough_wall(draw, cell, side)


def text_center(draw: ImageDraw.ImageDraw, xy: tuple[float, float], text: str, font, fill, anchor="mm") -> None:
    draw.text(xy, text, font=font, fill=fill, anchor=anchor, stroke_width=2, stroke_fill=(7, 6, 9, 220))


def draw_prop(draw: ImageDraw.ImageDraw, room_id: str, room: dict) -> None:
    x0, y0 = room_origin(room["grid"])
    cx, cy = iso_center(x0 + 2, y0 + 2)
    role = room["role"]
    shadow = (7, 5, 9, 180)
    draw.ellipse((cx - 74, cy + 21, cx + 74, cy + 46), fill=shadow)
    if role == "throne":
        draw.polygon([(cx - 60, cy + 22), (cx + 56, cy + 22), (cx + 40, cy - 76), (cx - 42, cy - 76)], fill=(103, 28, 38, 235), outline=(20, 12, 15, 245))
        draw.rectangle((cx - 38, cy - 98, cx + 38, cy - 37), fill=(133, 35, 45, 245), outline=(24, 13, 18, 250), width=4)
        draw.line((cx - 64, cy + 20, cx - 43, cy - 92), fill=(191, 143, 57, 240), width=6)
        draw.line((cx + 64, cy + 20, cx + 43, cy - 92), fill=(191, 143, 57, 240), width=6)
    elif role == "barracks":
        for index in range(6):
            ox = cx - 82 + index * 31
            draw.line((ox, cy - 57, ox + 8, cy + 20), fill=(124, 94, 58, 245), width=5)
            draw.line((ox - 11, cy - 19, ox + 23, cy - 9), fill=(160, 153, 139, 245), width=3)
        draw.rectangle((cx - 84, cy + 28, cx - 18, cy + 55), fill=(82, 45, 44, 240), outline=(24, 16, 17, 245), width=3)
        draw.rectangle((cx + 18, cy + 18, cx + 86, cy + 44), fill=(88, 73, 59, 240), outline=(24, 17, 18, 245), width=3)
    elif role == "recovery":
        draw.ellipse((cx - 88, cy - 32, cx + 88, cy + 63), fill=(32, 84, 73, 240), outline=(12, 34, 31, 245), width=4)
        for ox, oy, radius in [(-34, -8, 25), (0, -27, 30), (34, -8, 23), (-7, 19, 27)]:
            draw.ellipse((cx + ox - radius, cy + oy - radius * 1.22, cx + ox + radius, cy + oy + radius * 1.22), fill=(158, 170, 119, 245), outline=(45, 62, 45, 245), width=3)
    elif role == "entrance":
        draw.rectangle((cx - 84, cy - 54, cx + 84, cy + 37), fill=(42, 34, 42, 245), outline=(16, 11, 16, 250), width=5)
        draw.arc((cx - 84, cy - 124, cx + 84, cy + 44), 180, 360, fill=(96, 80, 86, 250), width=17)
        for index in range(8):
            ox = cx - 56 + index * 16
            draw.line((ox, cy - 48, ox, cy + 32), fill=(15, 12, 16, 245), width=5)
        draw.rectangle((cx - 72, cy - 52, cx + 72, cy + 37), outline=(105, 88, 92, 240), width=4)
    elif role == "treasure":
        draw.ellipse((cx - 102, cy - 14, cx + 102, cy + 57), fill=(91, 62, 16, 235), outline=(34, 23, 10, 245), width=3)
        rng = random.Random(406)
        for _ in range(90):
            px = cx + rng.uniform(-87, 87)
            py = cy + rng.uniform(-4, 47)
            draw.ellipse((px - 4, py - 2, px + 4, py + 2), fill=(214, 159, 47, 245), outline=(83, 57, 18, 220))
        draw.rectangle((cx + 13, cy - 56, cx + 101, cy + 12), fill=(132, 73, 23, 245), outline=(43, 25, 13, 245), width=4)
        draw.arc((cx + 13, cy - 92, cx + 101, cy + 22), 180, 360, fill=(180, 113, 38, 245), width=12)
    elif role == "slot":
        pts = [iso_center(x0 + 1, y0 + 1), iso_center(x0 + 3, y0 + 1), iso_center(x0 + 3, y0 + 3), iso_center(x0 + 1, y0 + 3)]
        draw.line(pts + [pts[0]], fill=(199, 180, 141, 245), width=5)
        for ox, oy in [(1, 1), (3, 1), (3, 3), (1, 3)]:
            px, py = iso_center(x0 + ox, y0 + oy)
            draw.line((px, py - 35, px, py + 13), fill=(124, 90, 55, 245), width=6)
        draw.rectangle((cx - 61, cy + 37, cx + 51, cy + 54), fill=(102, 74, 47, 230), outline=(36, 25, 16, 245), width=3)
    label_y = cy - 122 if role in {"throne", "entrance"} else cy - 104
    text_center(draw, (cx, label_y), room["label"], FONT_LABEL, (239, 219, 172, 245))


def draw_macro_overlay(draw: ImageDraw.ImageDraw) -> None:
    for gy in range(GRID_ROOM_COUNT):
        for gx in range(GRID_ROOM_COUNT):
            origin = room_origin((gx, gy))
            x0, y0 = origin
            corners = [
                edge_points(x0, y0, "N")[0],
                edge_points(x0 + ROOM_CELLS - 1, y0, "N")[1],
                edge_points(x0 + ROOM_CELLS - 1, y0 + ROOM_CELLS - 1, "E")[1],
                edge_points(x0, y0 + ROOM_CELLS - 1, "S")[1],
            ]
            draw.line(corners + [corners[0]], fill=(142, 120, 164, 100), width=2)
            cx, cy = iso_center(x0 + 2, y0 + 2)
            text_center(draw, (cx, cy + 78), f"G{gx:02d}_{gy:02d}", FONT_TINY, (214, 198, 164, 170))
    for gx in range(1, GRID_ROOM_COUNT):
        x = gx * ROOM_CELLS + (gx - 1) * GAP_CELLS
        sx, sy = iso_center(x + 0.5, -1.5)
        text_center(draw, (sx, sy), "간격 2셀", FONT_SMALL, (184, 158, 219, 220))
    draw.text(
        (38, 34),
        "4x4 방 그리드 / 방 1개 = 5x5 셀 / 방 사이 간격 = 2셀 길 전용 / 총 26x26",
        font=FONT_TITLE,
        fill=(241, 225, 183, 245),
        stroke_width=2,
        stroke_fill=(5, 4, 8, 235),
    )
    draw.text(
        (42, 82),
        "노란 테두리 = 열린 문, 돌벽 = 막힌 면, 회색 바닥 = 실제 이동 가능한 길",
        font=FONT_SMALL,
        fill=(202, 191, 203, 230),
        stroke_width=1,
        stroke_fill=(5, 4, 8, 220),
    )


def render(out_path: Path, overlay: bool) -> None:
    image = Image.new("RGBA", (CANVAS_W, CANVAS_H), (12, 10, 16, 255))
    draw = ImageDraw.Draw(image, "RGBA")
    draw_background(draw)

    path_cells = build_path_cells()
    occupied_room_cells: set[tuple[int, int]] = set()
    for room in ROOMS.values():
        occupied_room_cells |= room_cells(room_origin(room["grid"]))
    floor_cells = occupied_room_cells | path_cells

    if overlay:
        for y in range(MASTER_CELLS):
            for x in range(MASTER_CELLS):
                draw_tile(draw, (x, y), (0, 0, 0, 0), (88, 81, 104, 35), inset=0.0)

    for cell in sorted(path_cells, key=lambda value: (value[0] + value[1], value[0])):
        shade = 0.09 * ((cell[0] + cell[1]) % 4)
        fill = blend((47, 44, 48), (76, 68, 67), shade)
        draw_tile(draw, cell, fill + (235,), (18, 15, 20, 170), inset=2.2)

    for room_id, room in ROOMS.items():
        origin = room_origin(room["grid"])
        base = room["fill"]
        for cell in sorted(room_cells(origin), key=lambda value: (value[0] + value[1], value[0])):
            local_edge = cell[0] in {origin[0], origin[0] + 4} or cell[1] in {origin[1], origin[1] + 4}
            fill = blend(base, (28, 26, 31), 0.18 if local_edge else 0.03)
            draw_tile(draw, cell, fill + (228,), (17, 14, 19, 165), inset=1.4)

    draw_path_edges(draw, path_cells, floor_cells)

    for room in ROOMS.values():
        draw_room_walls(draw, room_origin(room["grid"]), room["open"])

    for room_id, room in ROOMS.items():
        draw_prop(draw, room_id, room)

    # Door mouths are drawn after props so they stay readable.
    for room in ROOMS.values():
        origin = room_origin(room["grid"])
        for side in room["open"]:
            for cell in socket_cells(origin, side):
                draw_tile(draw, cell, (100, 73, 53, 148), (226, 162, 72, 230), inset=5.0)

    if overlay:
        draw_macro_overlay(draw)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    image.convert("RGB").save(out_path)


def main() -> None:
    render(OUT_CLEAN, overlay=False)
    render(OUT_OVERLAY, overlay=True)
    print(OUT_CLEAN)
    print(OUT_OVERLAY)


if __name__ == "__main__":
    main()
