from __future__ import annotations

import hashlib
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageStat


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets" / "source" / "imagegen" / "roman"
OUTPUT_DIR = ROOT / "assets" / "sprites" / "enemies"
PORTRAIT_PATH = (
    ROOT
    / "assets"
    / "sprites"
    / "portraits"
    / "campaign"
    / "CHR_ROMAN_portrait_command.png"
)
PREVIEW_PATH = ROOT / "tmp" / "asset_previews" / "roman_animation_sequences.png"
SIZE = 192
SOURCE_PADDING = 16
TARGET_CENTER_X = SIZE // 2
TARGET_BASELINE_Y = 180

ANIMATIONS = {
    "idle_down": (SOURCE_DIR / "CHR_ROMAN_idle_sheet_imagegen.png", 2, 1),
    "move_down": (SOURCE_DIR / "CHR_ROMAN_move_sheet_imagegen.png", 2, 2),
    "attack_down": (SOURCE_DIR / "CHR_ROMAN_attack_sheet_imagegen.png", 2, 2),
    "skill_down": (SOURCE_DIR / "CHR_ROMAN_skill_sheet_imagegen.png", 2, 2),
    "down": (SOURCE_DIR / "CHR_ROMAN_down_sheet_imagegen.png", 2, 1),
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

    frames: list[Image.Image] = []
    for row in range(rows):
        for column in range(columns):
            left = column * cell_width
            top = row * cell_height
            cell = sheet.crop((left, top, left + cell_width, top + cell_height))

            # Keep the generated camera and cell-local baseline intact. A small transparent
            # margin protects the most energetic command poses from resampling onto an edge.
            padded = Image.new(
                "RGBA",
                (cell_width + SOURCE_PADDING * 2, cell_height + SOURCE_PADDING * 2),
                (0, 0, 0, 0),
            )
            padded.alpha_composite(cell, (SOURCE_PADDING, SOURCE_PADDING))
            frame = padded.resize((SIZE, SIZE), RESAMPLE)
            alpha = frame.getchannel("A").point(lambda value: 0 if value <= 8 else value)
            frame.putalpha(alpha)
            frame = _register_runtime_frame(frame)

            bbox = frame.getchannel("A").getbbox()
            if bbox is None:
                raise ValueError(f"{source_path.name}: cell {len(frames)} is fully transparent")
            if bbox[0] <= 0 or bbox[1] <= 0 or bbox[2] >= SIZE or bbox[3] >= SIZE:
                raise ValueError(f"{source_path.name}: cell {len(frames)} touches canvas edge: {bbox}")
            frames.append(frame)
    return frames


def _register_runtime_frame(frame: Image.Image) -> Image.Image:
    """Place each independently drawn pose on the shared combat origin and floor line."""
    bbox = frame.getchannel("A").getbbox()
    if bbox is None:
        return frame
    center_x = (bbox[0] + bbox[2]) // 2
    offset_x = TARGET_CENTER_X - center_x
    offset_y = TARGET_BASELINE_Y - bbox[3]
    registered = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    registered.alpha_composite(frame, (offset_x, offset_y))
    return registered


def _normalized_subject(frame: Image.Image, size: int = 96) -> Image.Image:
    bbox = frame.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("Cannot normalize an empty frame")
    return frame.crop(bbox).resize((size, size), RESAMPLE)


def _mean_absolute_difference(first: Image.Image, second: Image.Image) -> float:
    difference = ImageChops.difference(first, second)
    means = ImageStat.Stat(difference).mean
    return sum(means) / (len(means) * 255.0)


def _alpha_difference(first: Image.Image, second: Image.Image) -> float:
    first_alpha = first.getchannel("A")
    second_alpha = second.getchannel("A")
    return ImageStat.Stat(ImageChops.difference(first_alpha, second_alpha)).mean[0] / 255.0


def _simple_transforms(image: Image.Image) -> list[Image.Image]:
    """Return transforms that would expose a pose made from a reused cutout."""
    transpose = getattr(Image, "Transpose", Image)
    mirrored = image.transpose(transpose.FLIP_LEFT_RIGHT)
    return [
        image,
        image.rotate(90),
        image.rotate(180),
        image.rotate(270),
        mirrored,
        mirrored.rotate(90),
        mirrored.rotate(180),
        mirrored.rotate(270),
    ]


def _validate_frame_pixels(animation: str, index: int, frame: Image.Image) -> None:
    if frame.mode != "RGBA" or frame.size != (SIZE, SIZE):
        raise ValueError(f"{animation}[{index}]: expected 192x192 RGBA, got {frame.size} {frame.mode}")

    alpha = frame.getchannel("A")
    minimum, maximum = alpha.getextrema()
    if minimum != 0 or maximum != 255:
        raise ValueError(f"{animation}[{index}]: alpha range must include 0 and 255, got {minimum}..{maximum}")
    for point in ((0, 0), (SIZE - 1, 0), (0, SIZE - 1), (SIZE - 1, SIZE - 1)):
        if alpha.getpixel(point) != 0:
            raise ValueError(f"{animation}[{index}]: corner {point} is not transparent")

    # Roman's approved palette contains no bright green. Opaque green-dominant pixels
    # therefore indicate chroma spill rather than intentional costume color.
    opaque_green_pixels = 0
    for red, green, blue, opacity in frame.getdata():
        if opacity >= 240 and green >= 120 and green > red * 1.55 and green > blue * 1.55:
            opaque_green_pixels += 1
    if opaque_green_pixels:
        raise ValueError(f"{animation}[{index}]: {opaque_green_pixels} opaque chroma-green pixels remain")


def _validate_independence(animation: str, frames: list[Image.Image]) -> list[str]:
    diagnostics: list[str] = []
    hashes = [hashlib.sha256(frame.tobytes()).hexdigest() for frame in frames]
    if len(set(hashes)) != len(hashes):
        raise ValueError(f"{animation}: duplicate runtime frames detected")

    normalized = [_normalized_subject(frame) for frame in frames]
    for first_index in range(len(frames)):
        for second_index in range(first_index + 1, len(frames)):
            transform_variants = _simple_transforms(normalized[second_index])
            rgba_differences = [
                _mean_absolute_difference(normalized[first_index], variant)
                for variant in transform_variants
            ]
            alpha_differences = [
                _alpha_difference(normalized[first_index], variant)
                for variant in transform_variants
            ]
            direct_rgba = rgba_differences[0]
            direct_alpha = alpha_differences[0]
            closest_rgba_transform = min(rgba_differences)
            closest_alpha_transform = min(alpha_differences)
            if closest_rgba_transform < 0.025 or closest_alpha_transform < 0.025:
                raise ValueError(
                    f"{animation}[{first_index}:{second_index}]: frames are too close to a "
                    f"copy/transform (direct_rgba={direct_rgba:.4f}, "
                    f"closest_rgba={closest_rgba_transform:.4f}, "
                    f"direct_alpha={direct_alpha:.4f}, "
                    f"closest_alpha={closest_alpha_transform:.4f})"
                )
            diagnostics.append(
                f"{animation}[{first_index}:{second_index}] "
                f"direct_rgba={direct_rgba:.4f} closest_rgba={closest_rgba_transform:.4f} "
                f"direct_alpha={direct_alpha:.4f} closest_alpha={closest_alpha_transform:.4f}"
            )
    return diagnostics


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


def _validate_portrait() -> None:
    portrait = Image.open(PORTRAIT_PATH)
    if portrait.width != portrait.height or portrait.width < 1024:
        raise ValueError(f"Portrait must be a square high-resolution image, got {portrait.size}")


def main() -> None:
    missing = [str(path) for path, _, _ in ANIMATIONS.values() if not path.exists()]
    if not PORTRAIT_PATH.exists():
        missing.append(str(PORTRAIT_PATH))
    if missing:
        raise FileNotFoundError("Missing Roman imagegen source assets:\n" + "\n".join(missing))

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    all_frames: dict[str, list[Image.Image]] = {}
    diagnostics: list[str] = []
    all_hashes: set[str] = set()
    for animation, (source_path, columns, rows) in ANIMATIONS.items():
        frames = _split_sheet(source_path, columns, rows)
        all_frames[animation] = frames
        for index, frame in enumerate(frames):
            _validate_frame_pixels(animation, index, frame)
            digest = hashlib.sha256(frame.tobytes()).hexdigest()
            if digest in all_hashes:
                raise ValueError(f"{animation}[{index}]: duplicates a frame in another animation")
            all_hashes.add(digest)
            output = OUTPUT_DIR / f"enemy_roman_{animation}_{index:02d}.png"
            frame.save(output, optimize=True)
            print(f"{output.relative_to(ROOT)}: bbox={frame.getchannel('A').getbbox()}")
        diagnostics.extend(_validate_independence(animation, frames))

    _validate_portrait()
    _write_preview(all_frames)
    print("Frame independence metrics (normalized 0..1; higher means more different):")
    for diagnostic in diagnostics:
        print(f"  {diagnostic}")
    print(f"portrait: {PORTRAIT_PATH.relative_to(ROOT)}")
    print(f"preview: {PREVIEW_PATH.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
