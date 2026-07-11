from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets" / "source" / "imagegen" / "engineer"
IDLE_SOURCE = SOURCE_DIR / "CHR_ENGINEER_design_imagegen.png"
ATTACK_SOURCE = SOURCE_DIR / "CHR_ENGINEER_attack_pose_imagegen.png"
SKILL_SOURCE = SOURCE_DIR / "CHR_ENGINEER_skill_pose_imagegen.png"
OUTPUT_DIR = ROOT / "assets" / "sprites" / "enemies"
SIZE = 192


def _base_sprite(source_path: Path) -> Image.Image:
    source = Image.open(source_path).convert("RGBA")
    bounds = source.getbbox()
    if bounds is None:
        raise RuntimeError(f"No visible pixels in {source_path}")
    subject = source.crop(bounds)
    subject.thumbnail((156, 168), Image.Resampling.LANCZOS)
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
    idle = _base_sprite(IDLE_SOURCE)
    attack = _base_sprite(ATTACK_SOURCE)
    skill = _base_sprite(SKILL_SOURCE)
    frames = {
        "idle_down": [(idle, 1.00, 0.0, (0, 0)), (idle, 1.00, 0.0, (0, -1))],
        "move_down": [
            (idle, 1.00, -1.2, (-2, 1)),
            (idle, 1.01, 1.0, (2, -2)),
            (idle, 1.00, 1.2, (2, 1)),
            (idle, 1.01, -1.0, (-2, -2)),
        ],
        "attack_down": [
            (idle, 0.98, -3.0, (-4, 1)),
            (attack, 0.98, -2.0, (-3, 2)),
            (attack, 1.05, 2.0, (4, -1)),
            (idle, 1.00, 1.0, (2, 0)),
        ],
        "skill_down": [
            (idle, 1.00, 0.0, (0, 0)),
            (skill, 0.96, -1.0, (0, 3)),
            (skill, 1.04, 1.0, (0, -2)),
            (idle, 1.00, 0.0, (0, 0)),
        ],
        "down": [(idle, 0.92, 76.0, (8, 18)), (idle, 0.90, 88.0, (10, 22))],
    }
    for animation, transforms in frames.items():
        for index, (source, scale, rotation, offset) in enumerate(transforms):
            output = OUTPUT_DIR / f"enemy_engineer_{animation}_{index:02d}.png"
            _transform(source, scale, rotation, offset).save(output)


if __name__ == "__main__":
    main()
