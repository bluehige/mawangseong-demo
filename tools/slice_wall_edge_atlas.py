from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "output" / "imagegen" / "wall_edge_atlas_cave_f_01_alpha.png"
OUT_DIR = ROOT / "assets" / "tiles" / "cave_v2" / "wall_edges"
PREVIEW = ROOT / "output" / "imagegen" / "wall_edge_atlas_cave_f_01_sliced_preview.png"

SIDES = ["N", "E", "S", "W"]
VARIANT_COLUMNS = {
    0: "straight",
    1: "end_a",
    2: "end_b",
    3: "cap",
}
CORNER_BY_SIDE = {
    "N": "NE",
    "E": "ES",
    "S": "SW",
    "W": "WN",
}


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


def save_trimmed(cell: Image.Image, path: Path) -> Image.Image:
    cropped = cell.crop(alpha_bbox(cell))
    path.parent.mkdir(parents=True, exist_ok=True)
    cropped.save(path)
    return cropped


def keep_main_alpha_components(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    width, height = image.size
    data = alpha.load()
    seen = bytearray(width * height)
    components: list[list[tuple[int, int]]] = []

    for y in range(height):
        for x in range(width):
            index = y * width + x
            if seen[index] or data[x, y] <= 12:
                continue
            stack = [(x, y)]
            seen[index] = 1
            pixels: list[tuple[int, int]] = []
            while stack:
                px, py = stack.pop()
                pixels.append((px, py))
                for nx, ny in ((px + 1, py), (px - 1, py), (px, py + 1), (px, py - 1)):
                    if nx < 0 or ny < 0 or nx >= width or ny >= height:
                        continue
                    n_index = ny * width + nx
                    if seen[n_index] or data[nx, ny] <= 12:
                        continue
                    seen[n_index] = 1
                    stack.append((nx, ny))
            components.append(pixels)

    if not components:
        return image

    largest = max(len(component) for component in components)
    threshold = max(96, int(largest * 0.035))
    keep = {pixel for component in components if len(component) >= threshold for pixel in component}
    if not keep:
        return image

    cleaned = image.copy()
    cleaned_alpha = cleaned.getchannel("A")
    alpha_out = cleaned_alpha.load()
    for y in range(height):
        for x in range(width):
            if (x, y) not in keep:
                alpha_out[x, y] = 0
    cleaned.putalpha(cleaned_alpha)
    return cleaned


def output_name(key: str) -> str:
    return f"wall_edge_cave_v2_{key}.png"


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(SOURCE)

    source = Image.open(SOURCE).convert("RGBA")
    cell_w = source.width // 8
    cell_h = source.height // 4
    slot_boxes = detect_slot_boxes(source, 8, 4)
    outputs: list[tuple[str, Image.Image]] = []

    for row, side in enumerate(SIDES):
        for col, variant in VARIANT_COLUMNS.items():
            box = slot_boxes.get((row, col), (col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h))
            cell = source.crop(box)
            key = f"wall_{side}_{variant}"
            saved = save_trimmed(cell, OUT_DIR / output_name(key))
            outputs.append((key, saved))

        for col, key_prefix in [(4, "wall_cap_closed"), (5, "door_open"), (6, "socket_placeholder")]:
            box = slot_boxes.get((row, col), (col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h))
            cell = source.crop(box)
            key = f"{key_prefix}_{side}"
            saved = save_trimmed(cell, OUT_DIR / output_name(key))
            outputs.append((key, saved))

        corner = CORNER_BY_SIDE[side]
        box = slot_boxes.get((row, 7), (7 * cell_w, row * cell_h, 8 * cell_w, (row + 1) * cell_h))
        cell = source.crop(box)
        key = f"wall_corner_{corner}"
        saved = save_trimmed(cell, OUT_DIR / output_name(key))
        outputs.append((key, saved))

    make_preview(outputs)
    print(f"Wrote {len(outputs)} wall edge sprites to {OUT_DIR}")
    print(f"Wrote preview to {PREVIEW}")


def make_preview(outputs: list[tuple[str, Image.Image]]) -> None:
    thumb_w = 160
    thumb_h = 140
    cols = 8
    rows = (len(outputs) + cols - 1) // cols
    preview = Image.new("RGBA", (cols * thumb_w, rows * thumb_h), (20, 18, 24, 255))
    for index, (key, sprite) in enumerate(outputs):
        row = index // cols
        col = index % cols
        tile = Image.new("RGBA", (thumb_w, thumb_h), (32, 28, 38, 255))
        scaled = sprite.copy()
        scaled.thumbnail((thumb_w - 18, thumb_h - 18), Image.Resampling.LANCZOS)
        x = (thumb_w - scaled.width) // 2
        y = (thumb_h - scaled.height) // 2
        tile.alpha_composite(scaled, (x, y))
        preview.alpha_composite(tile, (col * thumb_w, row * thumb_h))
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    preview.save(PREVIEW)


def detect_slot_boxes(image: Image.Image, cols: int, rows: int, padding: int = 10) -> dict[tuple[int, int], tuple[int, int, int, int]]:
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

            if area < 32:
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


if __name__ == "__main__":
    main()
