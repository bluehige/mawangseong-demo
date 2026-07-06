import json
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
LAYOUT_PATH = ROOT / "data" / "dungeon_quarter" / "starting_layout.json"
BLUEPRINTS_PATH = ROOT / "data" / "dungeon_quarter" / "room_blueprints.json"
OUT_CLEAN = ROOT / "docs" / "concepts" / "spaced_grid_source_layout_concept_2026-07-06.png"
OUT_OVERLAY = ROOT / "docs" / "concepts" / "spaced_grid_source_layout_concept_overlay_2026-07-06.png"

TILE_W = 96
TILE_H = 48
GRID_W = 28
GRID_H = 26
MARGIN_X = 220
MARGIN_Y = 170
CANVAS_W = 2800
CANVAS_H = 1700


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def iso_center(x: int, y: int) -> tuple[float, float]:
    sx = (x - y) * (TILE_W / 2) + CANVAS_W / 2
    sy = (x + y) * (TILE_H / 2) + MARGIN_Y
    return sx, sy


def diamond(x: int, y: int) -> list[tuple[float, float]]:
    cx, cy = iso_center(x, y)
    return [
        (cx, cy - TILE_H / 2),
        (cx + TILE_W / 2, cy),
        (cx, cy + TILE_H / 2),
        (cx - TILE_W / 2, cy),
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
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def poly(draw: ImageDraw.ImageDraw, pts, fill, outline=None, width=1) -> None:
    draw.polygon(pts, fill=fill)
    if outline:
        draw.line(pts + [pts[0]], fill=outline, width=width, joint="curve")


def draw_tile(draw: ImageDraw.ImageDraw, x: int, y: int, fill, outline=None, inset: int = 0) -> None:
    pts = diamond(x, y)
    if inset:
        cx, cy = iso_center(x, y)
        pts = [
            (cx + (px - cx) * (1 - inset / 48.0), cy + (py - cy) * (1 - inset / 48.0))
            for px, py in pts
        ]
    poly(draw, pts, fill, outline)


def draw_rough_line(draw: ImageDraw.ImageDraw, p0, p1, fill, width=8, stones=True) -> None:
    draw.line([p0, p1], fill=(15, 12, 17), width=width + 4)
    draw.line([p0, p1], fill=fill, width=width)
    if not stones:
        return
    steps = max(2, int(math.dist(p0, p1) / 18))
    rng = random.Random(int(p0[0] * 17 + p0[1] * 31 + p1[0] * 43 + p1[1] * 59))
    for i in range(steps + 1):
        t = i / steps
        px = p0[0] + (p1[0] - p0[0]) * t + rng.uniform(-4, 4)
        py = p0[1] + (p1[1] - p0[1]) * t + rng.uniform(-3, 3)
        r = rng.randint(4, 7)
        color = blend((83, 70, 86), (39, 34, 45), rng.random())
        draw.ellipse((px - r, py - r, px + r, py + r), fill=color, outline=(16, 13, 19))


def draw_macro_outline(draw: ImageDraw.ImageDraw, origin: tuple[int, int], cell_size: tuple[int, int], color, width=3) -> None:
    x0, y0 = origin
    w, h = cell_size
    corners = [
        edge_points(x0, y0, "N")[0],
        edge_points(x0 + w - 1, y0, "N")[1],
        edge_points(x0 + w - 1, y0 + h - 1, "E")[1],
        edge_points(x0, y0 + h - 1, "S")[1],
    ]
    draw.line(corners + [corners[0]], fill=color, width=width)


def draw_background(img: Image.Image) -> None:
    px = img.load()
    rng = random.Random(106)
    for y in range(img.height):
        for x in range(img.width):
            dx = (x - img.width / 2) / img.width
            dy = (y - img.height / 2) / img.height
            vignette = min(1.0, math.sqrt(dx * dx + dy * dy) * 1.7)
            noise = rng.randint(-5, 5)
            base = 20 - int(vignette * 12) + noise
            px[x, y] = (max(5, base), max(5, base - 2), max(8, base + 3))


def draw_cave_rocks(draw: ImageDraw.ImageDraw) -> None:
    rng = random.Random(307)
    for _ in range(350):
        gx = rng.uniform(-2, GRID_W + 2)
        gy = rng.uniform(-2, GRID_H + 2)
        sx, sy = iso_center(gx, gy)
        if rng.random() < 0.55:
            sx += rng.uniform(-40, 40)
            sy += rng.uniform(-25, 25)
        r = rng.uniform(4, 18)
        c = blend((31, 29, 38), (72, 63, 78), rng.random() * 0.55)
        draw.ellipse((sx - r, sy - r * 0.58, sx + r, sy + r * 0.58), fill=c, outline=(13, 12, 17))


def draw_floor_cracks(draw: ImageDraw.ImageDraw, cells: set[tuple[int, int]], color) -> None:
    rng = random.Random(511)
    for x, y in sorted(cells):
        cx, cy = iso_center(x, y)
        if rng.random() < 0.45:
            draw.line(
                [
                    (cx + rng.uniform(-18, -4), cy + rng.uniform(-7, 4)),
                    (cx + rng.uniform(2, 18), cy + rng.uniform(-5, 8)),
                ],
                fill=color,
                width=1,
            )


def connected_side_for_room(room_grid: dict) -> dict[str, set[str]]:
    result: dict[str, set[str]] = {}
    for cell in room_grid.get("cells", []):
        instance = str(cell.get("instance_id", ""))
        if instance:
            result[instance] = set(cell.get("connected_sides", []))
    return result


def grid_size_from_layout(layout: dict, blueprints: dict) -> tuple[int, int]:
    room_grid = layout.get("room_grid", {})
    active_size = room_grid.get("active_master_size", [])
    if isinstance(active_size, list) and len(active_size) >= 2:
        return int(active_size[0]), int(active_size[1])

    max_x = 0
    max_y = 0
    lattice_size = room_grid.get("room_lattice_master_size", [])
    if isinstance(lattice_size, list) and len(lattice_size) >= 2:
        max_x = max(max_x, int(lattice_size[0]) - 1)
        max_y = max(max_y, int(lattice_size[1]) - 1)

    for module in layout.get("placed_modules", []):
        bp = blueprints.get(str(module.get("module_id", "")), {})
        origin = tuple(module.get("grid_origin", [0, 0]))
        for local in bp.get("floor_cells", []):
            if not isinstance(local, list) or len(local) < 2:
                continue
            max_x = max(max_x, int(origin[0]) + int(local[0]))
            max_y = max(max_y, int(origin[1]) + int(local[1]))
    return max_x + 1, max_y + 1


def module_lookup(layout: dict) -> dict[str, dict]:
    return {str(module.get("instance_id", "")): module for module in layout.get("placed_modules", [])}


def socket_world_cell(module: dict, socket_id: str, blueprints: dict) -> tuple[int, int]:
    bp = blueprints[str(module["module_id"])]
    socket = bp["socket_entries"][socket_id]
    origin = module["grid_origin"]
    return int(origin[0]) + int(socket["cell"][0]), int(origin[1]) + int(socket["cell"][1])


def connection_bridge_cells(layout: dict, blueprints: dict) -> set[tuple[int, int]]:
    placed = module_lookup(layout)
    cells: set[tuple[int, int]] = set()
    for conn in layout.get("connections", []):
        refs = [str(conn.get("from", "")), str(conn.get("to", ""))]
        for ref in refs:
            if ":" not in ref:
                continue
            inst, socket_id = ref.split(":", 1)
            module = placed.get(inst)
            if module is None:
                continue
            cells.add(socket_world_cell(module, socket_id, blueprints))
    return cells


def draw_room_object(draw: ImageDraw.ImageDraw, instance: str, origin: tuple[int, int]) -> None:
    x0, y0 = origin
    cx, cy = iso_center(x0 + 2, y0 + 2)
    shadow = (10, 8, 12)
    if instance == "throne":
        draw.ellipse((cx - 78, cy + 20, cx + 78, cy + 44), fill=shadow)
        draw.polygon([(cx - 45, cy + 18), (cx + 45, cy + 18), (cx + 35, cy - 58), (cx - 35, cy - 58)], fill=(86, 22, 28), outline=(20, 10, 12))
        draw.rectangle((cx - 30, cy - 84, cx + 30, cy - 34), fill=(116, 30, 35), outline=(24, 14, 13), width=3)
        draw.line((cx - 50, cy + 18, cx - 38, cy - 70), fill=(173, 133, 55), width=5)
        draw.line((cx + 50, cy + 18, cx + 38, cy - 70), fill=(173, 133, 55), width=5)
    elif instance == "barracks":
        for i in range(5):
            ox = cx - 70 + i * 32
            draw.line((ox, cy - 52, ox + 8, cy + 10), fill=(116, 91, 62), width=5)
            draw.line((ox - 10, cy - 12, ox + 22, cy - 4), fill=(151, 143, 134), width=3)
        draw.rectangle((cx - 80, cy + 28, cx - 18, cy + 52), fill=(75, 43, 47), outline=(25, 18, 21))
        draw.rectangle((cx + 18, cy + 18, cx + 82, cy + 42), fill=(87, 73, 61), outline=(25, 18, 21))
    elif instance == "recovery":
        draw.ellipse((cx - 88, cy - 30, cx + 88, cy + 64), fill=(31, 86, 75), outline=(11, 35, 35), width=4)
        for ox, oy, r in [(-32, -8, 24), (0, -24, 28), (34, -6, 22), (-6, 20, 25)]:
            draw.ellipse((cx + ox - r, cy + oy - r * 1.25, cx + ox + r, cy + oy + r * 1.25), fill=(153, 165, 116), outline=(44, 59, 45), width=3)
        draw.ellipse((cx - 54, cy + 30, cx + 56, cy + 62), outline=(83, 177, 151), width=3)
    elif instance == "entrance":
        draw.ellipse((cx - 86, cy + 24, cx + 86, cy + 50), fill=shadow)
        draw.rectangle((cx - 74, cy - 45, cx + 74, cy + 35), fill=(46, 36, 44), outline=(18, 13, 17), width=4)
        draw.arc((cx - 74, cy - 105, cx + 74, cy + 43), 180, 360, fill=(92, 77, 84), width=16)
        for i in range(7):
            ox = cx - 48 + i * 16
            draw.line((ox, cy - 40, ox, cy + 30), fill=(18, 15, 18), width=5)
        draw.rectangle((cx - 64, cy - 44, cx + 64, cy + 35), outline=(96, 80, 86), width=4)
    elif instance == "treasure":
        draw.ellipse((cx - 100, cy - 12, cx + 100, cy + 58), fill=(91, 62, 16), outline=(33, 23, 10), width=3)
        for i in range(70):
            rng = random.Random(i * 19)
            px = cx + rng.uniform(-84, 82)
            py = cy + rng.uniform(-4, 48)
            draw.ellipse((px - 4, py - 2, px + 4, py + 2), fill=(204, 150, 45), outline=(84, 58, 18))
        draw.rectangle((cx + 16, cy - 50, cx + 96, cy + 10), fill=(126, 70, 22), outline=(42, 25, 13), width=4)
        draw.arc((cx + 16, cy - 82, cx + 96, cy + 18), 180, 360, fill=(169, 105, 35), width=11)
        for ox in [-92, 92]:
            draw.polygon([(cx + ox, cy - 58), (cx + ox + 18, cy - 10), (cx + ox, cy + 16), (cx + ox - 18, cy - 10)], fill=(116, 55, 176), outline=(48, 25, 73))
    elif instance == "slot_01":
        pts = [
            iso_center(x0 + 1, y0 + 1),
            iso_center(x0 + 3, y0 + 1),
            iso_center(x0 + 3, y0 + 3),
            iso_center(x0 + 1, y0 + 3),
        ]
        draw.line(pts + [pts[0]], fill=(179, 169, 151), width=4)
        for ox, oy in [(1, 1), (3, 1), (3, 3), (1, 3)]:
            px, py = iso_center(x0 + ox, y0 + oy)
            draw.line((px, py - 32, px, py + 10), fill=(113, 83, 54), width=5)
        draw.rectangle((cx - 58, cy + 36, cx + 42, cy + 50), fill=(96, 70, 46), outline=(37, 25, 17))


def draw_door_mouth(draw: ImageDraw.ImageDraw, cells: list[tuple[int, int]], side: str) -> None:
    for x, y in cells:
        draw_tile(draw, x, y, (59, 54, 57), (118, 96, 84), inset=5)
        p0, p1 = edge_points(x, y, side)
        draw.line([p0, p1], fill=(181, 135, 82), width=4)


def draw_outside_mouth(draw: ImageDraw.ImageDraw, cells: set[tuple[int, int]]) -> None:
    west_cells = sorted([cell for cell in cells if (cell[0] - 1, cell[1]) not in cells], key=lambda c: c[1])
    for x, y in west_cells:
        p0, p1 = edge_points(x, y, "W")
        mid = ((p0[0] + p1[0]) * 0.5, (p0[1] + p1[1]) * 0.5)
        top = (mid[0], mid[1] - 42)
        draw.line([p0, p1], fill=(4, 3, 6), width=16)
        draw.line([p0, top], fill=(7, 5, 9), width=9)
        draw.line([top, p1], fill=(7, 5, 9), width=9)
        draw.line([p0, p1], fill=(186, 136, 80), width=4)
        draw.ellipse((mid[0] - 18, mid[1] - 30, mid[0] + 18, mid[1] + 6), fill=(105, 72, 168, 80))


def room_grid_cell_origin(cell: dict) -> tuple[int, int]:
    master_cell = cell.get("master_cell", [0, 0])
    return int(master_cell[0]), int(master_cell[1])


def room_grid_cell_size(room_grid: dict) -> tuple[int, int]:
    cell_size = room_grid.get("cell_size", [5, 5])
    return int(cell_size[0]), int(cell_size[1])


def draw_empty_room_slot(draw: ImageDraw.ImageDraw, origin: tuple[int, int], cell_size: tuple[int, int]) -> None:
    x0, y0 = origin
    w, h = cell_size
    rng = random.Random(x0 * 131 + y0 * 197)
    for x in range(x0, x0 + w):
        for y in range(y0, y0 + h):
            if rng.random() < 0.42:
                fill = blend((18, 16, 21), (39, 34, 43), rng.random())
                draw_tile(draw, x, y, fill, (10, 9, 13), inset=8)
    draw_macro_outline(draw, origin, cell_size, (48, 41, 58, 130), width=1)


def draw_trap_cells(draw: ImageDraw.ImageDraw, placed: list[dict], blueprints: dict) -> None:
    for module in placed:
        bp = blueprints[str(module["module_id"])]
        origin = module["grid_origin"]
        for local in bp.get("trap_cells", []):
            gx = int(origin[0]) + int(local[0])
            gy = int(origin[1]) + int(local[1])
            cx, cy = iso_center(gx, gy)
            draw_tile(draw, gx, gy, (36, 32, 37), (88, 72, 75), inset=4)
            draw.polygon(
                [(cx, cy - 17), (cx + 8, cy + 8), (cx, cy + 2), (cx - 8, cy + 8)],
                fill=(128, 125, 120),
                outline=(37, 35, 36),
            )


def render(with_overlay: bool, out_path: Path) -> None:
    global GRID_W, GRID_H
    random.seed(1001)
    layout = load_json(LAYOUT_PATH)
    blueprints = load_json(BLUEPRINTS_PATH)
    GRID_W, GRID_H = grid_size_from_layout(layout, blueprints)
    room_grid = layout["room_grid"]
    connected_sides = connected_side_for_room(room_grid)
    bridge_cells = connection_bridge_cells(layout, blueprints)

    image = Image.new("RGB", (CANVAS_W, CANVAS_H), (15, 13, 19))
    draw_background(image)
    draw = ImageDraw.Draw(image, "RGBA")
    draw_cave_rocks(draw)

    placed = layout["placed_modules"]
    path_cells: set[tuple[int, int]] = set()
    outside_cells: set[tuple[int, int]] = set()
    room_cells: dict[str, set[tuple[int, int]]] = {}
    room_origins: dict[str, tuple[int, int]] = {}
    room_module_ids: dict[str, str] = {}

    for module in placed:
        instance = str(module["instance_id"])
        module_id = str(module["module_id"])
        origin = tuple(module["grid_origin"])
        bp = blueprints[module_id]
        cells = {(origin[0] + c[0], origin[1] + c[1]) for c in bp.get("floor_cells", [])}
        module_type = str(bp.get("module_type", ""))
        room_function = str(bp.get("room_function", ""))
        if room_function == "outside":
            outside_cells |= cells
            path_cells |= cells
        elif module_type in {"corridor", "junction"}:
            path_cells |= cells
        elif bp.get("module_type") == "room":
            room_cells[instance] = cells
            room_origins[instance] = origin
            room_module_ids[instance] = module_id

    cell_size = room_grid_cell_size(room_grid)
    room_grid_cells = room_grid.get("cells", [])
    for cell in room_grid_cells:
        origin = room_grid_cell_origin(cell)
        if not str(cell.get("instance_id", "")):
            draw_empty_room_slot(draw, origin, cell_size)
        elif with_overlay:
            draw_macro_outline(draw, origin, cell_size, (80, 69, 92, 86), width=2)

    if with_overlay:
        for x in range(GRID_W):
            for y in range(GRID_H):
                draw_tile(draw, x, y, (0, 0, 0, 0), (95, 88, 110, 32), inset=0)

    for x, y in sorted(path_cells):
        shade = 0.09 * ((x + y) % 3)
        fill = blend((42, 39, 43), (65, 58, 60), shade)
        draw_tile(draw, x, y, fill, (22, 20, 24), inset=3)
    draw_floor_cracks(draw, path_cells, (21, 19, 22, 190))
    if outside_cells:
        draw_outside_mouth(draw, outside_cells)

    # Low rubble on exposed path edges.
    for x, y in sorted(path_cells):
        for side, dx, dy in [("N", 0, -1), ("E", 1, 0), ("S", 0, 1), ("W", -1, 0)]:
            if (x + dx, y + dy) not in path_cells:
                p0, p1 = edge_points(x, y, side)
                draw_rough_line(draw, p0, p1, (50, 43, 54), width=3, stones=True)

    for instance, cells in room_cells.items():
        for x, y in sorted(cells):
            fill = (50, 45, 50) if instance != "treasure" else (55, 46, 39)
            if instance == "recovery":
                fill = (37, 55, 55)
            elif instance == "throne":
                fill = (54, 43, 52)
            draw_tile(draw, x, y, fill, (27, 23, 29), inset=2)
        draw_floor_cracks(draw, cells, (26, 23, 28, 170))

    draw_trap_cells(draw, placed, blueprints)

    for instance, origin in room_origins.items():
        bp = blueprints[room_module_ids[instance]]
        for side in ["N", "E", "S", "W"]:
            side_cells = []
            for socket in bp["socket_entries"].values():
                if socket["side"] == side:
                    side_cells.append((origin[0] + socket["cell"][0], origin[1] + socket["cell"][1]))
            connected = side in connected_sides.get(instance, set())
            if connected:
                draw_door_mouth(draw, side_cells, side)
            for x, y in sorted(room_cells[instance]):
                if side == "N" and y != origin[1]:
                    continue
                if side == "S" and y != origin[1] + 4:
                    continue
                if side == "W" and x != origin[0]:
                    continue
                if side == "E" and x != origin[0] + 4:
                    continue
                if connected and (x, y) in side_cells:
                    continue
                p0, p1 = edge_points(x, y, side)
                draw_rough_line(draw, p0, p1, (74, 63, 77), width=7, stones=True)

    for instance, origin in room_origins.items():
        draw_room_object(draw, instance, origin)

    # Door/path bridge highlights after walls and objects.
    for conn in layout["connections"]:
        from_inst, from_socket = str(conn["from"]).split(":")
        to_inst, to_socket = str(conn["to"]).split(":")
        for inst, socket_id in [(from_inst, from_socket), (to_inst, to_socket)]:
            module = next((m for m in placed if m["instance_id"] == inst), None)
            if not module:
                continue
            bp = blueprints[module["module_id"]]
            socket = bp["socket_entries"][socket_id]
            origin = module["grid_origin"]
            gx, gy = origin[0] + socket["cell"][0], origin[1] + socket["cell"][1]
            if (gx, gy) in bridge_cells:
                draw_tile(draw, gx, gy, (72, 61, 58, 150), (173, 129, 78, 190), inset=8)

    if with_overlay:
        font = ImageFont.load_default()
        for cell in room_grid_cells:
            origin = room_grid_cell_origin(cell)
            cx, cy = iso_center(origin[0] + cell_size[0] // 2, origin[1] + cell_size[1] // 2)
            label = str(cell.get("grid_id", ""))
            draw.text((cx - 20, cy - 8), label, font=font, fill=(220, 205, 160, 190))
        for module in placed:
            if module["instance_id"] == "spike_corridor":
                continue
            ox, oy = module["grid_origin"]
            offset_y = -44 if module["instance_id"] == "outside_approach" else -96
            cx, cy = iso_center(ox + 2, oy + 2)
            draw.text((cx - 26, cy + offset_y), module["instance_id"], font=font, fill=(242, 218, 153, 230))
        draw.text((28, 28), "Source layout: 4x4 rooms, 5x5 room blocks, 2-cell gaps, west outside entrance approach", font=font, fill=(237, 220, 172, 230))

    out_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(out_path)


def main() -> None:
    render(False, OUT_CLEAN)
    render(True, OUT_OVERLAY)
    print(OUT_CLEAN)
    print(OUT_OVERLAY)


if __name__ == "__main__":
    main()
