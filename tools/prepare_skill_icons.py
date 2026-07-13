"""Slice the approved 4x2 skill icon sheet into 128px runtime icons."""

from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "source" / "imagegen" / "evolutions" / "skill_icons_4x2_alpha.png"
OUTPUT_DIR = ROOT / "assets" / "sprites" / "ui" / "skills"
SIZE = 128
SKILL_IDS = [
    "slime_shield",
    "hold_corridor",
    "quick_slash",
    "loot_instinct",
    "fireball",
    "flame_zone",
    "false_footprints",
    "rumor_boost",
]

try:
    RESAMPLE = Image.Resampling.LANCZOS
except AttributeError:
    RESAMPLE = Image.LANCZOS


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(SOURCE)
    sheet = Image.open(SOURCE).convert("RGBA")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for index, skill_id in enumerate(SKILL_IDS):
        column = index % 4
        row = index // 4
        left = round(column * sheet.width / 4)
        top = round(row * sheet.height / 2)
        right = round((column + 1) * sheet.width / 4)
        bottom = round((row + 1) * sheet.height / 2)
        icon = sheet.crop((left, top, right, bottom)).resize((SIZE, SIZE), RESAMPLE)
        alpha = icon.getchannel("A").point(lambda value: 0 if value <= 8 else value)
        icon.putalpha(alpha)
        if alpha.getbbox() is None:
            raise ValueError(f"{skill_id}: empty icon")
        output = OUTPUT_DIR / f"skill_{skill_id}.png"
        icon.save(output, optimize=True)
        print(f"{output.relative_to(ROOT)}: bbox={alpha.getbbox()}")


if __name__ == "__main__":
    main()
