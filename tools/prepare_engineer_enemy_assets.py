from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets" / "source" / "imagegen" / "engineer"
OUTPUT_DIR = ROOT / "assets" / "sprites" / "enemies"
PREVIEW_PATH = ROOT / "tmp" / "asset_previews" / "engineer_animation_sequences.png"
SIZE = 192

ANIMATIONS = {
    "idle_down": (SOURCE_DIR / "CHR_ENGINEER_idle_sheet_imagegen.png", 2, 1),
    "move_down": (SOURCE_DIR / "CHR_ENGINEER_move_sheet_imagegen.png", 2, 2),
    "attack_down": (SOURCE_DIR / "CHR_ENGINEER_attack_sheet_imagegen.png", 2, 2),
    "skill_down": (SOURCE_DIR / "CHR_ENGINEER_skill_sheet_imagegen.png", 2, 2),
    "down": (SOURCE_DIR / "CHR_ENGINEER_down_sheet_imagegen.png", 2, 1),
}

try:
    RESAMPLE = Image.Resampling.LANCZOS
except AttributeError:
    RESAMPLE = Image.LANCZOS


def _split_sheet(source_path: Path, columns: int, rows: int) -> list[Image.Image]:
    sheet = Image.open(source_path).convert("RGBA")
    if sheet.width % columns != 0 or sheet.height % rows != 0:
        raise ValueError(
            f"{source_path.name}: {sheet.size} cannot be divided into {columns}x{rows} cells"
        )

    cell_width = sheet.width // columns
    cell_height = sheet.height // rows
    if abs(cell_width - cell_height) > 1:
        raise ValueError(f"{source_path.name}: expected square cells, got {cell_width}x{cell_height}")

    crop_boxes: list[tuple[int, int, int, int]] = []
    if columns == 2 and rows == 1:
        # Image generation may let a wide fall pose cross the mathematical midpoint.
        # Center each square crop on the two largest character silhouettes instead.
        components = sorted(_alpha_components(sheet.getchannel("A")), key=len, reverse=True)[:2]
        components.sort(key=lambda component: sum(point[0] for point in component) / len(component))
        for component in components:
            center_x = round((min(point[0] for point in component) + max(point[0] for point in component)) / 2)
            left = max(0, min(sheet.width - cell_height, center_x - cell_height // 2))
            crop_boxes.append((left, 0, left + cell_height, cell_height))
    else:
        for row in range(rows):
            for column in range(columns):
                left = column * cell_width
                top = row * cell_height
                crop_boxes.append((left, top, left + cell_width, top + cell_height))

    frames: list[Image.Image] = []
    for crop_box in crop_boxes:
        frame = sheet.crop(crop_box)
        # The generated sheets already keep a stable camera and cell-local ground line.
        # Resizing the complete cell preserves those hand-drawn spatial relationships.
        frame = frame.resize((SIZE, SIZE), RESAMPLE)
        alpha = frame.getchannel("A").point(lambda value: 0 if value <= 8 else value)
        frame.putalpha(alpha)
        frame = _remove_edge_fragments(frame)
        bbox = frame.getchannel("A").getbbox()
        if bbox is None:
            raise ValueError(f"{source_path.name}: cell {len(frames)} is fully transparent")
        if bbox[0] <= 0 or bbox[1] <= 0 or bbox[2] >= SIZE or bbox[3] >= SIZE:
            raise ValueError(f"{source_path.name}: cell {len(frames)} touches the canvas edge: {bbox}")
        frames.append(frame)
    return frames


def _alpha_components(alpha: Image.Image) -> list[list[tuple[int, int]]]:
    pixels = alpha.load()
    visited: set[tuple[int, int]] = set()
    components: list[list[tuple[int, int]]] = []
    for y in range(alpha.height):
        for x in range(alpha.width):
            if pixels[x, y] == 0 or (x, y) in visited:
                continue
            component: list[tuple[int, int]] = []
            queue = deque([(x, y)])
            visited.add((x, y))
            while queue:
                current_x, current_y = queue.popleft()
                component.append((current_x, current_y))
                for offset_y in (-1, 0, 1):
                    for offset_x in (-1, 0, 1):
                        next_x = current_x + offset_x
                        next_y = current_y + offset_y
                        point = (next_x, next_y)
                        if not (0 <= next_x < alpha.width and 0 <= next_y < alpha.height):
                            continue
                        if point in visited or pixels[next_x, next_y] == 0:
                            continue
                        visited.add(point)
                        queue.append(point)
            components.append(component)
    return components


def _remove_edge_fragments(frame: Image.Image) -> Image.Image:
    """Drop chroma-removal scraps at a cell boundary without touching detached tools."""
    alpha = frame.getchannel("A")
    components = _alpha_components(alpha)
    largest = max(components, key=len) if components else []

    cleaned_alpha = alpha.copy()
    cleaned_pixels = cleaned_alpha.load()
    for component in components:
        touches_edge = any(
            x == 0 or y == 0 or x == frame.width - 1 or y == frame.height - 1
            for x, y in component
        )
        if component is largest or not touches_edge:
            continue
        for x, y in component:
            cleaned_pixels[x, y] = 0
    cleaned = frame.copy()
    cleaned.putalpha(cleaned_alpha)
    return cleaned


def _checkerboard(size: tuple[int, int], block: int = 12) -> Image.Image:
    image = Image.new("RGBA", size, (24, 21, 30, 255))
    draw = ImageDraw.Draw(image)
    for y in range(0, size[1], block):
        for x in range(0, size[0], block):
            if (x // block + y // block) % 2 == 0:
                draw.rectangle((x, y, x + block - 1, y + block - 1), fill=(38, 34, 45, 255))
    return image


def _write_preview(all_frames: dict[str, list[Image.Image]]) -> None:
    gap = 16
    label_width = 150
    canvas_width = label_width + (SIZE + gap) * 4 + gap
    canvas_height = gap + (SIZE + gap) * len(ANIMATIONS)
    canvas = _checkerboard((canvas_width, canvas_height))
    draw = ImageDraw.Draw(canvas)
    for row, animation in enumerate(ANIMATIONS):
        y = gap + row * (SIZE + gap)
        draw.text((12, y + SIZE // 2 - 8), animation, fill=(242, 222, 175, 255))
        for column, frame in enumerate(all_frames[animation]):
            x = label_width + column * (SIZE + gap)
            canvas.alpha_composite(frame, (x, y))
    PREVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(PREVIEW_PATH, quality=94)


def main() -> None:
    missing = [str(path) for path, _, _ in ANIMATIONS.values() if not path.exists()]
    if missing:
        raise FileNotFoundError("Missing imagegen animation sheets:\n" + "\n".join(missing))

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    all_frames: dict[str, list[Image.Image]] = {}
    for animation, (source_path, columns, rows) in ANIMATIONS.items():
        frames = _split_sheet(source_path, columns, rows)
        all_frames[animation] = frames
        for index, frame in enumerate(frames):
            output = OUTPUT_DIR / f"enemy_engineer_{animation}_{index:02d}.png"
            frame.save(output, optimize=True)
            print(f"{output.relative_to(ROOT)}: bbox={frame.getchannel('A').getbbox()}")

    _write_preview(all_frames)
    print(PREVIEW_PATH.relative_to(ROOT))


if __name__ == "__main__":
    main()
