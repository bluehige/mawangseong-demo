from pathlib import Path
from collections import deque

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "docs" / "concepts" / "combat_animation_sources"
OUTPUT_DIR = ROOT / "assets" / "sprites" / "monsters"

SHEETS = {
    "slime": SOURCE_DIR / "monster_slime_attack_sheet_alpha_2026-07-10.png",
    "goblin": SOURCE_DIR / "monster_goblin_attack_sheet_alpha_2026-07-10.png",
    "imp": SOURCE_DIR / "monster_imp_attack_sheet_alpha_2026-07-10.png",
}

try:
    RESAMPLE = Image.Resampling.LANCZOS
except AttributeError:
    RESAMPLE = Image.LANCZOS


def remove_edge_fragments(frame: Image.Image) -> Image.Image:
    alpha = frame.getchannel("A")
    pixels = alpha.load()
    width, height = alpha.size
    visited: set[tuple[int, int]] = set()
    components: list[list[tuple[int, int]]] = []

    for y in range(height):
        for x in range(width):
            if pixels[x, y] <= 8 or (x, y) in visited:
                continue
            component: list[tuple[int, int]] = []
            queue = deque([(x, y)])
            visited.add((x, y))
            while queue:
                current_x, current_y = queue.popleft()
                component.append((current_x, current_y))
                for offset_y in (-1, 0, 1):
                    for offset_x in (-1, 0, 1):
                        if offset_x == 0 and offset_y == 0:
                            continue
                        next_x = current_x + offset_x
                        next_y = current_y + offset_y
                        point = (next_x, next_y)
                        if not (0 <= next_x < width and 0 <= next_y < height):
                            continue
                        if point in visited or pixels[next_x, next_y] <= 8:
                            continue
                        visited.add(point)
                        queue.append(point)
            components.append(component)

    if not components:
        return frame
    largest = max(components, key=len)
    output_alpha = alpha.copy()
    output_pixels = output_alpha.load()
    for component in components:
        touches_edge = any(x <= 8 or y <= 8 or x >= width - 9 or y >= height - 9 for x, y in component)
        if component is largest or not touches_edge:
            continue
        for x, y in component:
            output_pixels[x, y] = 0
    output_alpha = output_alpha.point(lambda value: 0 if value <= 8 else value)
    cleaned = frame.copy()
    cleaned.putalpha(output_alpha)
    return cleaned


def split_sheet(monster_key: str, source_path: Path) -> list[Path]:
    sheet = Image.open(source_path).convert("RGBA")
    width, height = sheet.size
    if width != height or width % 2 != 0:
        raise ValueError(f"{source_path.name}: expected an even square 2x2 sheet, got {width}x{height}")

    cell_size = width // 2
    cells = [
        (0, 0, cell_size, cell_size),
        (cell_size, 0, width, cell_size),
        (0, cell_size, cell_size, height),
        (cell_size, cell_size, width, height),
    ]
    outputs: list[Path] = []
    for index, crop_box in enumerate(cells):
        frame = sheet.crop(crop_box).resize((192, 192), RESAMPLE)
        frame = remove_edge_fragments(frame)
        bbox = frame.getchannel("A").getbbox()
        if bbox is None:
            raise ValueError(f"{source_path.name}: frame {index} is fully transparent")

        bbox_width = bbox[2] - bbox[0]
        bbox_height = bbox[3] - bbox[1]
        if bbox_width > 186 or bbox_height > 186:
            scale = min(186.0 / bbox_width, 186.0 / bbox_height)
            subject = frame.crop(bbox)
            scaled_size = (
                max(1, round(subject.width * scale)),
                max(1, round(subject.height * scale)),
            )
            subject = subject.resize(scaled_size, RESAMPLE)
            center_x = (bbox[0] + bbox[2]) * 0.5
            center_y = (bbox[1] + bbox[3]) * 0.5
            position = (
                round(center_x - subject.width * 0.5),
                round(center_y - subject.height * 0.5),
            )
            fitted = Image.new("RGBA", frame.size, (0, 0, 0, 0))
            fitted.alpha_composite(subject, position)
            frame = fitted
            bbox = frame.getchannel("A").getbbox()

        shift_x = 0
        shift_y = 0
        if bbox[0] < 3:
            shift_x = 3 - bbox[0]
        elif bbox[2] > 189:
            shift_x = 189 - bbox[2]
        if bbox[1] < 3:
            shift_y = 3 - bbox[1]
        elif bbox[3] > 189:
            shift_y = 189 - bbox[3]
        if shift_x != 0 or shift_y != 0:
            shifted = Image.new("RGBA", frame.size, (0, 0, 0, 0))
            shifted.alpha_composite(frame, (shift_x, shift_y))
            frame = shifted
            bbox = frame.getchannel("A").getbbox()

        if bbox[0] < 3 or bbox[1] < 3 or bbox[2] > 189 or bbox[3] > 189:
            raise ValueError(f"{source_path.name}: frame {index} touches the canvas edge: {bbox}")

        output_path = OUTPUT_DIR / f"monster_{monster_key}_attack_down_{index:02d}.png"
        frame.save(output_path, optimize=True)
        outputs.append(output_path)
        print(f"{output_path.relative_to(ROOT)}: bbox={bbox}")
    return outputs


def main() -> None:
    missing = [str(path) for path in SHEETS.values() if not path.exists()]
    if missing:
        raise FileNotFoundError("Missing alpha sprite sheets:\n" + "\n".join(missing))
    for monster_key, source_path in SHEETS.items():
        split_sheet(monster_key, source_path)


if __name__ == "__main__":
    main()
