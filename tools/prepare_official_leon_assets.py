"""Slice the approved built-in imagegen sheets into Leon's runtime frames.

The chroma-key alpha sheets are produced first with the shared imagegen helper.
This script only performs deterministic cell slicing and size normalization.
"""

from __future__ import annotations

import hashlib
from pathlib import Path

from PIL import Image, ImageChops, ImageStat


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "source" / "imagegen" / "official_leon"
OUTPUT = ROOT / "assets" / "sprites" / "enemies"
PORTRAIT_PATH = (
    ROOT
    / "assets"
    / "sprites"
    / "portraits"
    / "campaign"
    / "CHR_HERO_LEON_OFFICIAL_portrait_final.png"
)
FRAME_SIZE = (192, 192)
CONTENT_LIMIT = (180, 178)

ANIMATIONS = {
    "idle": 2,
    "move": 4,
    "attack": 4,
    "skill": 4,
    "down": 2,
}


def _cell_frames(state: str, count: int) -> list[Image.Image]:
    sheet_path = SOURCE / f"CHR_HERO_LEON_OFFICIAL_{state}_sheet_alpha.png"
    sheet = Image.open(sheet_path).convert("RGBA")
    if sheet.width % count != 0:
        raise ValueError(f"{sheet_path.name}: width {sheet.width} is not divisible by {count}")
    cell_width = sheet.width // count
    result: list[Image.Image] = []
    for index in range(count):
        cell = sheet.crop((index * cell_width, 0, (index + 1) * cell_width, sheet.height))
        bounds = cell.getchannel("A").getbbox()
        if bounds is None:
            raise ValueError(f"{sheet_path.name}: frame {index} has no opaque pixels")
        result.append(cell.crop(bounds))
    return result


def _normalize_animation(frames: list[Image.Image]) -> list[Image.Image]:
    max_width = max(frame.width for frame in frames)
    max_height = max(frame.height for frame in frames)
    scale = min(CONTENT_LIMIT[0] / max_width, CONTENT_LIMIT[1] / max_height)
    result: list[Image.Image] = []
    for frame in frames:
        resized = frame.resize(
            (max(1, round(frame.width * scale)), max(1, round(frame.height * scale))),
            Image.Resampling.LANCZOS,
        )
        canvas = Image.new("RGBA", FRAME_SIZE, (0, 0, 0, 0))
        x = (FRAME_SIZE[0] - resized.width) // 2
        y = FRAME_SIZE[1] - resized.height - 5
        canvas.alpha_composite(resized, (x, y))
        result.append(canvas)
    return result


def _difference_score(left: Image.Image, right: Image.Image) -> float:
    difference = ImageChops.difference(left, right)
    values = ImageStat.Stat(difference).mean
    return sum(values) / (len(values) * 255.0)


def _normalized_subject(frame: Image.Image, size: int = 96) -> Image.Image:
    bounds = frame.getchannel("A").getbbox()
    if bounds is None:
        raise ValueError("Cannot normalize an empty Leon frame")
    return frame.crop(bounds).resize((size, size), Image.Resampling.LANCZOS)


def _alpha_difference(left: Image.Image, right: Image.Image) -> float:
    difference = ImageChops.difference(left.getchannel("A"), right.getchannel("A"))
    return ImageStat.Stat(difference).mean[0] / 255.0


def _simple_transforms(image: Image.Image) -> list[Image.Image]:
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


def _validate_runtime_frame(state: str, index: int, frame: Image.Image) -> str:
    if frame.mode != "RGBA" or frame.size != FRAME_SIZE:
        raise ValueError(
            f"{state}[{index}]: expected {FRAME_SIZE[0]}x{FRAME_SIZE[1]} RGBA, "
            f"got {frame.size} {frame.mode}"
        )
    alpha = frame.getchannel("A")
    minimum, maximum = alpha.getextrema()
    if minimum != 0 or maximum != 255:
        raise ValueError(
            f"{state}[{index}]: alpha range must include 0 and 255, got {minimum}..{maximum}"
        )
    for point in (
        (0, 0),
        (FRAME_SIZE[0] - 1, 0),
        (0, FRAME_SIZE[1] - 1),
        (FRAME_SIZE[0] - 1, FRAME_SIZE[1] - 1),
    ):
        if alpha.getpixel(point) != 0:
            raise ValueError(f"{state}[{index}]: corner {point} is not transparent")
    return hashlib.sha256(frame.tobytes()).hexdigest()


def _validate_independent_poses(state: str, frames: list[Image.Image]) -> None:
    normalized = [_normalized_subject(frame) for frame in frames]
    for first_index in range(len(normalized)):
        for second_index in range(first_index + 1, len(normalized)):
            variants = _simple_transforms(normalized[second_index])
            closest_rgba = min(
                _difference_score(normalized[first_index], variant) for variant in variants
            )
            closest_alpha = min(
                _alpha_difference(normalized[first_index], variant) for variant in variants
            )
            if closest_rgba < 0.025 or closest_alpha < 0.025:
                raise ValueError(
                    f"{state}[{first_index}:{second_index}]: frames are too close to a "
                    f"copy/transform (rgba={closest_rgba:.4f}, alpha={closest_alpha:.4f})"
                )


def _validate_portrait() -> None:
    portrait = Image.open(PORTRAIT_PATH)
    if portrait.width != portrait.height or portrait.width < 1024:
        raise ValueError(f"Portrait must be square and at least 1024px, got {portrait.size}")


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    all_hashes: set[str] = set()
    for state, count in ANIMATIONS.items():
        frames = _normalize_animation(_cell_frames(state, count))
        for index, frame in enumerate(frames):
            digest = _validate_runtime_frame(state, index, frame)
            if digest in all_hashes:
                raise ValueError(f"{state}[{index}]: duplicates another Leon runtime frame")
            all_hashes.add(digest)
            animation_suffix = "down" if state == "down" else f"{state}_down"
            output_path = OUTPUT / f"enemy_official_hero_leon_{animation_suffix}_{index:02d}.png"
            frame.save(output_path, optimize=True)
        scores = [
            _difference_score(frames[index], frames[index + 1])
            for index in range(len(frames) - 1)
        ]
        if any(score < 0.01 for score in scores):
            raise ValueError(f"{state}: adjacent frames are too similar: {scores}")
        _validate_independent_poses(state, frames)
        print(f"{state}: {count} frames, adjacent difference {scores}")
    _validate_portrait()
    print(f"validated {len(all_hashes)} unique RGBA frames and portrait {PORTRAIT_PATH.name}")


if __name__ == "__main__":
    main()
