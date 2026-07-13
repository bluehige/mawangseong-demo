"""Split six approved 2x1 expression sheets into square runtime portraits."""

from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets" / "source" / "imagegen" / "evolutions"
OUTPUT_DIR = ROOT / "assets" / "sprites" / "portraits" / "evolution"
SIZE = 1024
EVOLUTION_IDS = [
    "slime_gate_bulwark",
    "slime_rescue_alchemy_gel",
    "goblin_ambush_captain",
    "goblin_vault_keeper",
    "imp_flame_adept",
    "imp_ember_shaman",
]
VARIANTS = ["victory", "wounded"]

try:
    RESAMPLE = Image.Resampling.LANCZOS
except AttributeError:
    RESAMPLE = Image.LANCZOS


def square_center_crop(image: Image.Image) -> Image.Image:
    side = min(image.width, image.height)
    left = (image.width - side) // 2
    top = (image.height - side) // 2
    return image.crop((left, top, left + side, top + side))


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for evolution_id in EVOLUTION_IDS:
        source = SOURCE_DIR / f"expressions_{evolution_id}_2x1.png"
        if not source.exists():
            raise FileNotFoundError(source)
        sheet = Image.open(source).convert("RGBA")
        for index, variant in enumerate(VARIANTS):
            left = round(index * sheet.width / 2)
            right = round((index + 1) * sheet.width / 2)
            portrait = square_center_crop(sheet.crop((left, 0, right, sheet.height)))
            portrait = portrait.resize((SIZE, SIZE), RESAMPLE)
            output = OUTPUT_DIR / f"portrait_{evolution_id}_{variant}.png"
            portrait.save(output, optimize=True)
            print(output.relative_to(ROOT))


if __name__ == "__main__":
    main()
