from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "source" / "imagegen" / "engineer" / "CHR_ENGINEER_design_imagegen.png"
OUTPUT_DIR = ROOT / "assets" / "sprites" / "enemies"
SIZE = 192


def _base_sprite() -> Image.Image:
    source = Image.open(SOURCE).convert("RGBA")
    bounds = source.getbbox()
    if bounds is None:
        raise RuntimeError(f"No visible pixels in {SOURCE}")
    subject = source.crop(bounds)
    subject.thumbnail((150, 168), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    x = (SIZE - subject.width) // 2
    y = 180 - subject.height
    canvas.alpha_composite(subject, (x, y))
    return canvas


def _transform(base: Image.Image, scale: float, rotation: float, offset: tuple[int, int]) -> Image.Image:
    width = max(1, round(base.width * scale))
    height = max(1, round(base.height * scale))
    resized = base.resize((width, height), Image.Resampling.LANCZOS)
    rotated = resized.rotate(rotation, resample=Image.Resampling.BICUBIC, expand=True)
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    x = (SIZE - rotated.width) // 2 + offset[0]
    y = (SIZE - rotated.height) // 2 + offset[1]
    canvas.alpha_composite(rotated, (x, y))
    return canvas


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    base = _base_sprite()
    frames = {
        "idle_down": [(1.00, 0.0, (0, 0)), (1.00, 0.0, (0, -1))],
        "move_down": [
            (1.00, -1.2, (-2, 1)),
            (1.01, 1.0, (2, -2)),
            (1.00, 1.2, (2, 1)),
            (1.01, -1.0, (-2, -2)),
        ],
        "attack_down": [
            (1.00, -2.0, (-2, 1)),
            (0.98, -4.0, (-5, 2)),
            (1.04, 4.0, (7, 0)),
            (1.01, 1.0, (2, 0)),
        ],
        "skill_down": [
            (1.00, 0.0, (0, 0)),
            (1.03, -1.0, (0, -2)),
            (1.06, 1.0, (0, -5)),
            (1.02, 0.0, (0, -1)),
        ],
        "down": [(0.92, 76.0, (8, 18)), (0.90, 88.0, (10, 22))],
    }
    for animation, transforms in frames.items():
        for index, (scale, rotation, offset) in enumerate(transforms):
            output = OUTPUT_DIR / f"enemy_engineer_{animation}_{index:02d}.png"
            _transform(base, scale, rotation, offset).save(output)


if __name__ == "__main__":
    main()
