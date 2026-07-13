"""Build ending emblems/thumbnails and legacy HUD icons from approved sources."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = ROOT / "assets" / "source" / "imagegen"
ENDING_OUTPUT = ROOT / "assets" / "ui" / "endings"
LEGACY_OUTPUT = ROOT / "assets" / "sprites" / "ui" / "legacy"
ENDING_IDS = [
    "true_demon_castle",
    "monster_family_castle",
    "impregnable_demon_citadel",
    "dread_overlord_rises",
    "demon_hero_rival_pact",
]
LEGACY_ICON_IDS = ["bond", "memory", "style"]

try:
    RESAMPLE = Image.Resampling.LANCZOS
except AttributeError:
    RESAMPLE = Image.LANCZOS


def slice_row(sheet: Image.Image, count: int, index: int) -> Image.Image:
    left = round(index * sheet.width / count)
    right = round((index + 1) * sheet.width / count)
    cell = sheet.crop((left, 0, right, sheet.height))
    side = min(cell.width, cell.height)
    crop_left = (cell.width - side) // 2
    crop_top = (cell.height - side) // 2
    return cell.crop((crop_left, crop_top, crop_left + side, crop_top + side))


def main() -> None:
    ENDING_OUTPUT.mkdir(parents=True, exist_ok=True)
    LEGACY_OUTPUT.mkdir(parents=True, exist_ok=True)

    emblem_sheet = Image.open(SOURCE_ROOT / "endings" / "ending_emblems_5x1_alpha.png").convert("RGBA")
    for index, ending_id in enumerate(ENDING_IDS):
        emblem = slice_row(emblem_sheet, len(ENDING_IDS), index).resize((192, 192), RESAMPLE)
        emblem.save(ENDING_OUTPUT / f"emblem_{ending_id}.png", optimize=True)

        illustration_path = ENDING_OUTPUT / f"ending_{ending_id}.png"
        if not illustration_path.exists():
            raise FileNotFoundError(illustration_path)
        illustration = Image.open(illustration_path).convert("RGB")
        thumbnail = ImageOps.fit(illustration, (320, 180), method=RESAMPLE, centering=(0.5, 0.5))
        thumbnail.save(ENDING_OUTPUT / f"thumbnail_{ending_id}.png", optimize=True, quality=92)

    legacy_sheet = Image.open(SOURCE_ROOT / "evolutions" / "legacy_ui_icons_3x1_alpha.png").convert("RGBA")
    for index, icon_id in enumerate(LEGACY_ICON_IDS):
        icon = slice_row(legacy_sheet, len(LEGACY_ICON_IDS), index).resize((128, 128), RESAMPLE)
        icon.save(LEGACY_OUTPUT / f"ui_icon_{icon_id}.png", optimize=True)

    print(f"ending emblems: {len(ENDING_IDS)}")
    print(f"ending thumbnails: {len(ENDING_IDS)}")
    print(f"legacy UI icons: {len(LEGACY_ICON_IDS)}")


if __name__ == "__main__":
    main()
