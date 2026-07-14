"""Prepare Update 4 ending illustrations from GPT image sources."""

from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = ROOT / "assets/source/imagegen"
RUNTIME_ROOT = ROOT / "assets/ui/endings/update4"
RESAMPLE = Image.Resampling.LANCZOS
ENDINGS = {
    "update4_endings_phase32/ending_e17_council_seat_source_2026-07-14.png": "ending_council_seat.png",
    "update4_endings_phase32/ending_e18_two_floors_source_2026-07-14.png": "ending_two_floors_one_throne.png",
    "update4_endings_phase32/ending_e19_minion_crown_source_2026-07-14.png": "ending_minion_wears_the_crown.png",
    "update4_endings_phase33/ending_e20_outpost_home_source_2026-07-14.png": "ending_outpost_becomes_home.png",
    "update4_endings_phase33/ending_e21_three_rivals_source_2026-07-14.png": "ending_three_rivals_cosign.png",
    "update4_endings_phase33/ending_e22_council_dissolved_source_2026-07-14.png": "ending_council_dissolved.png",
}


def fit_16_by_9(source: Image.Image) -> Image.Image:
    image = source.convert("RGB")
    target_ratio = 16 / 9
    current_ratio = image.width / image.height
    if current_ratio > target_ratio:
        width = round(image.height * target_ratio)
        left = (image.width - width) // 2
        image = image.crop((left, 0, left + width, image.height))
    elif current_ratio < target_ratio:
        height = round(image.width / target_ratio)
        top = (image.height - height) // 2
        image = image.crop((0, top, image.width, top + height))
    return image.resize((1920, 1080), RESAMPLE)


def main() -> None:
    RUNTIME_ROOT.mkdir(parents=True, exist_ok=True)
    for source_name, runtime_name in ENDINGS.items():
        target = RUNTIME_ROOT / runtime_name
        fit_16_by_9(Image.open(SOURCE_ROOT / source_name)).save(target, optimize=True)
        print(f"prepared {target.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
