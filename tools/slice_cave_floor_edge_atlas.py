from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
FLOOR_SOURCE = ROOT / "output" / "imagegen" / "floor_mask_atlas_cave_f_01_alpha.png"
EDGE_SOURCE = ROOT / "output" / "imagegen" / "edge_corner_atlas_cave_f_01_alpha.png"
FLOOR_DIR = ROOT / "assets" / "tiles" / "cave_v2" / "floor"
EDGE_DIR = ROOT / "assets" / "tiles" / "cave_v2" / "edge"
OVERLAY_DIR = ROOT / "assets" / "tiles" / "cave_v2" / "overlay"
FLOOR_PREVIEW = ROOT / "output" / "imagegen" / "floor_mask_atlas_cave_f_01_sliced_preview.png"
EDGE_PREVIEW = ROOT / "output" / "imagegen" / "edge_corner_atlas_cave_f_01_sliced_preview.png"

TILE_SIZE = (128, 64)

EDGE_FILES = [
    "edge_cave_v2_nw_lip.png",
    "edge_cave_v2_ne_lip.png",
    "edge_cave_v2_se_lip.png",
    "edge_cave_v2_sw_lip.png",
]

OVERLAY_ROWS = [
    [
        "floor_cave_v2_corner_outer_nw.png",
        "floor_cave_v2_corner_outer_ne.png",
        "floor_cave_v2_corner_outer_se.png",
        "floor_cave_v2_corner_outer_sw.png",
    ],
    [
        "floor_cave_v2_corner_inner_nw.png",
        "floor_cave_v2_corner_inner_ne.png",
        "floor_cave_v2_corner_inner_se.png",
        "floor_cave_v2_corner_inner_sw.png",
    ],
]


def alpha_bbox(image: Image.Image, padding: int = 8) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return (0, 0, image.width, image.height)
    left, top, right, bottom = bbox
    return (
        max(0, left - padding),
        max(0, top - padding),
        min(image.width, right + padding),
        min(image.height, bottom + padding),
    )


def detect_slot_boxes(image: Image.Image, cols: int, rows: int, padding: int = 14) -> dict[tuple[int, int], tuple[int, int, int, int]]:
    alpha = image.getchannel("A")
    width, height = image.size
    cell_w = width / cols
    cell_h = height / rows
    data = alpha.load()
    seen = bytearray(width * height)
    boxes: dict[tuple[int, int], tuple[int, int, int, int]] = {}

    for y in range(height):
        for x in range(width):
            index = y * width + x
            if seen[index] or data[x, y] <= 12:
                continue
            stack = [(x, y)]
            seen[index] = 1
            area = 0
            left = right = x
            top = bottom = y
            while stack:
                px, py = stack.pop()
                area += 1
                left = min(left, px)
                right = max(right, px)
                top = min(top, py)
                bottom = max(bottom, py)
                for nx, ny in ((px + 1, py), (px - 1, py), (px, py + 1), (px, py - 1)):
                    if nx < 0 or ny < 0 or nx >= width or ny >= height:
                        continue
                    n_index = ny * width + nx
                    if seen[n_index] or data[nx, ny] <= 12:
                        continue
                    seen[n_index] = 1
                    stack.append((nx, ny))

            if area < 64:
                continue
            cx = (left + right) * 0.5
            cy = (top + bottom) * 0.5
            col = max(0, min(cols - 1, int(cx / cell_w)))
            row = max(0, min(rows - 1, int(cy / cell_h)))
            key = (row, col)
            padded = (
                max(0, left - padding),
                max(0, top - padding),
                min(width, right + padding + 1),
                min(height, bottom + padding + 1),
            )
            if key in boxes:
                current = boxes[key]
                boxes[key] = (
                    min(current[0], padded[0]),
                    min(current[1], padded[1]),
                    max(current[2], padded[2]),
                    max(current[3], padded[3]),
                )
            else:
                boxes[key] = padded
    return boxes


def fit_tile(source: Image.Image, preserve_aspect: bool) -> Image.Image:
    cropped = source.crop(alpha_bbox(source))
    tile = Image.new("RGBA", TILE_SIZE, (0, 0, 0, 0))
    if preserve_aspect:
        fitted = cropped.copy()
        fitted.thumbnail((TILE_SIZE[0], TILE_SIZE[1]), Image.Resampling.LANCZOS)
    else:
        fitted = cropped.resize(TILE_SIZE, Image.Resampling.LANCZOS)
    x = (TILE_SIZE[0] - fitted.width) // 2
    y = TILE_SIZE[1] - fitted.height
    tile.alpha_composite(fitted, (x, y))
    return tile


def slice_floor() -> list[tuple[str, Image.Image]]:
    source = Image.open(FLOOR_SOURCE).convert("RGBA")
    boxes = detect_slot_boxes(source, 4, 4, padding=18)
    outputs: list[tuple[str, Image.Image]] = []
    cell_w = source.width // 4
    cell_h = source.height // 4
    FLOOR_DIR.mkdir(parents=True, exist_ok=True)
    for mask in range(16):
        row = mask // 4
        col = mask % 4
        box = boxes.get((row, col), (col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h))
        tile = fit_tile(source.crop(box), preserve_aspect=False)
        name = f"floor_cave_v2_mask_{mask:02d}.png"
        tile.save(FLOOR_DIR / name)
        outputs.append((name, tile))
    make_preview(outputs, FLOOR_PREVIEW, cols=4)
    return outputs


def slice_edge_corner() -> list[tuple[str, Image.Image]]:
    source = Image.open(EDGE_SOURCE).convert("RGBA")
    boxes = detect_slot_boxes(source, 4, 3, padding=18)
    outputs: list[tuple[str, Image.Image]] = []
    cell_w = source.width // 4
    cell_h = source.height // 3
    EDGE_DIR.mkdir(parents=True, exist_ok=True)
    OVERLAY_DIR.mkdir(parents=True, exist_ok=True)

    for col, name in enumerate(EDGE_FILES):
        box = boxes.get((0, col), (col * cell_w, 0, (col + 1) * cell_w, cell_h))
        tile = fit_tile(source.crop(box), preserve_aspect=False)
        tile.save(EDGE_DIR / name)
        outputs.append((name, tile))

    for row_offset, row_files in enumerate(OVERLAY_ROWS, start=1):
        for col, name in enumerate(row_files):
            box = boxes.get((row_offset, col), (col * cell_w, row_offset * cell_h, (col + 1) * cell_w, (row_offset + 1) * cell_h))
            tile = fit_tile(source.crop(box), preserve_aspect=False)
            tile.save(OVERLAY_DIR / name)
            outputs.append((name, tile))
    make_preview(outputs, EDGE_PREVIEW, cols=4)
    return outputs


def make_preview(outputs: list[tuple[str, Image.Image]], path: Path, cols: int) -> None:
    thumb_w = 164
    thumb_h = 98
    rows = (len(outputs) + cols - 1) // cols
    preview = Image.new("RGBA", (cols * thumb_w, rows * thumb_h), (22, 19, 27, 255))
    for index, (_name, image) in enumerate(outputs):
        row = index // cols
        col = index % cols
        tile = Image.new("RGBA", (thumb_w, thumb_h), (34, 30, 40, 255))
        scaled = image.copy()
        scaled.thumbnail((thumb_w - 14, thumb_h - 14), Image.Resampling.LANCZOS)
        tile.alpha_composite(scaled, ((thumb_w - scaled.width) // 2, (thumb_h - scaled.height) // 2))
        preview.alpha_composite(tile, (col * thumb_w, row * thumb_h))
    path.parent.mkdir(parents=True, exist_ok=True)
    preview.save(path)


def main() -> None:
    if not FLOOR_SOURCE.exists():
        raise FileNotFoundError(FLOOR_SOURCE)
    if not EDGE_SOURCE.exists():
        raise FileNotFoundError(EDGE_SOURCE)
    floor_outputs = slice_floor()
    edge_outputs = slice_edge_corner()
    print(f"Wrote {len(floor_outputs)} floor mask tiles to {FLOOR_DIR}")
    print(f"Wrote {len(edge_outputs)} edge/corner tiles to {EDGE_DIR} and {OVERLAY_DIR}")
    print(f"Wrote previews: {FLOOR_PREVIEW}, {EDGE_PREVIEW}")


if __name__ == "__main__":
    main()
