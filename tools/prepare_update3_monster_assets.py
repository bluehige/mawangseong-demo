from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[1]


CONFIGS = {
    "ghost_housemaid": {
        "source": ROOT / "assets/source/imagegen/bebe/bebe_asset_sheet_2026-07-13.png",
        "frames": {
            "idle_down": [(25, 65, 180, 285), (185, 65, 350, 285)],
            "move_down": [(335, 70, 510, 290), (500, 70, 675, 290), (385, 700, 610, 905), (555, 700, 810, 905)],
            "attack_down": [(20, 300, 205, 520), (180, 295, 400, 520), (370, 300, 600, 520), (555, 300, 815, 520)],
            "skill_down": [(20, 490, 220, 720), (175, 490, 405, 720), (385, 485, 620, 720), (555, 490, 820, 720)],
            "down": [(15, 690, 220, 910), (175, 690, 410, 910)],
        },
        "portraits": {
            "base": (835, 35, 1250, 355),
            "happy": (835, 350, 1250, 655),
            "determined": (835, 645, 1250, 910),
        },
        "badges": {
            "bebe_night_steward": (735, 900, 1010, 1254),
            "bebe_poltergeist_cleaner": (980, 900, 1254, 1254),
        },
        "vfx": {
            "ghost_glide": (0, 900, 275, 1254),
            "broom_interrupt": (230, 900, 520, 1254),
            "rescue_ring": (440, 875, 755, 1254),
        },
    },
    "graveyard_hound": {
        "source": ROOT / "assets/source/imagegen/koko/koko_asset_sheet_2026-07-13.png",
        "frames": {
            "idle_down": [(20, 25, 255, 290), (250, 25, 470, 290)],
            "move_down": [(445, 25, 690, 290), (650, 25, 950, 290), (465, 755, 715, 955), (690, 755, 950, 955)],
            "attack_down": [(15, 275, 255, 525), (235, 275, 485, 525), (455, 275, 720, 525), (690, 275, 955, 525)],
            "skill_down": [(10, 515, 255, 765), (235, 515, 485, 765), (460, 515, 720, 765), (690, 515, 955, 765)],
            "down": [(5, 745, 255, 955), (230, 745, 490, 955)],
        },
        "portraits": {
            "base": (955, 0, 1254, 315),
            "happy": (955, 290, 1254, 630),
            "determined": (955, 610, 1254, 950),
        },
        "badges": {
            "koko_bounty_sniffer": (800, 945, 1040, 1254),
            "koko_throne_shepherd": (1010, 945, 1254, 1254),
        },
        "vfx": {
            "scent_lock": (0, 945, 335, 1254),
            "grave_bark": (280, 945, 610, 1254),
            "return_trail": (575, 945, 830, 1254),
        },
    },
    "armored_beetle": {
        "source": ROOT / "assets/source/imagegen/toktok/toktok_asset_sheet_2026-07-13.png",
        "frames": {
            "idle_down": [(25, 35, 240, 275), (225, 35, 455, 275)],
            "move_down": [(435, 35, 660, 275), (630, 35, 875, 275), (440, 720, 665, 955), (635, 720, 875, 955)],
            "attack_down": [(15, 265, 245, 505), (220, 265, 460, 505), (440, 265, 685, 505), (640, 265, 875, 505)],
            "skill_down": [(10, 485, 245, 735), (220, 485, 465, 735), (440, 485, 685, 735), (640, 485, 875, 735)],
            "down": [(10, 710, 245, 955), (220, 710, 460, 955)],
        },
        "portraits": {
            "base": (850, 20, 1254, 380),
            "happy": (850, 370, 1254, 710),
            "determined": (850, 695, 1254, 990),
        },
        "badges": {
            "toktok_shell_breaker": (805, 970, 1045, 1254),
            "toktok_castle_mason": (1010, 970, 1254, 1254),
        },
        "vfx": {
            "carapace_impact": (0, 935, 335, 1254),
            "patch_shield": (305, 935, 575, 1254),
            "scrap_rivets": (545, 935, 815, 1254),
        },
    },
}


def remove_neutral_background(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    output = []
    for red, green, blue, _ in rgba.getdata():
        maximum = max(red, green, blue)
        minimum = min(red, green, blue)
        saturation = maximum - minimum
        brightness = (red + green + blue) / 3.0
        # Image generation exports the transparency preview as two nearly-white
        # checker colors. Remove those neutral cells completely before applying
        # the softer edge formula; otherwise the dark game UI reveals the grid.
        if brightness >= 180.0 and saturation <= 10:
            output.append((red, green, blue, 0))
            continue
        darkness = 250 - brightness
        alpha = int(max(0.0, min(255.0, darkness * 11.0 + saturation * 7.0)))
        if maximum < 232:
            alpha = max(alpha, 220)
        output.append((red, green, blue, alpha))
    rgba.putdata(output)
    alpha = rgba.getchannel("A").filter(ImageFilter.GaussianBlur(0.55)).point(lambda value: 0 if value < 10 else value)
    rgba.putalpha(alpha)
    return rgba


def fitted_crop(sheet: Image.Image, box: tuple[int, int, int, int], size: tuple[int, int], padding: int) -> Image.Image:
    crop = sheet.crop(box)
    alpha = crop.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        raise ValueError(f"Crop contains no visible subject: {box}")
    subject = crop.crop(bbox)
    limit = (size[0] - padding * 2, size[1] - padding * 2)
    subject.thumbnail(limit, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    x = (size[0] - subject.width) // 2
    y = size[1] - padding - subject.height
    canvas.alpha_composite(subject, (x, y))
    return canvas


def prepare(species_id: str) -> None:
    config = CONFIGS[species_id]
    source = Path(config["source"])
    if not source.exists():
        raise FileNotFoundError(source)
    sheet = remove_neutral_background(Image.open(source))

    monster_dir = ROOT / "assets/sprites/monsters"
    portrait_dir = ROOT / "assets/sprites/portraits/update3"
    badge_dir = ROOT / "assets/ui/specializations/update3"
    effect_dir = ROOT / "assets/sprites/effects"
    for directory in [monster_dir, portrait_dir, badge_dir, effect_dir]:
        directory.mkdir(parents=True, exist_ok=True)

    frame_count = 0
    for state, boxes in config["frames"].items():
        for index, box in enumerate(boxes):
            frame = fitted_crop(sheet, box, (192, 192), 10)
            frame.save(monster_dir / f"monster_{species_id}_{state}_{index:02d}.png")
            frame_count += 1

    for expression, box in config["portraits"].items():
        fitted_crop(sheet, box, (512, 512), 18).save(portrait_dir / f"portrait_{species_id}_{expression}.png")
    for badge_id, box in config["badges"].items():
        fitted_crop(sheet, box, (192, 192), 6).save(badge_dir / f"badge_{badge_id}.png")
    for effect_id, box in config["vfx"].items():
        fitted_crop(sheet, box, (256, 256), 8).save(effect_dir / f"fx_{species_id}_{effect_id}_00.png")

    print(f"prepared {species_id}: {frame_count} combat frames, 3 portraits, 2 badges, 3 VFX")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("species_id", choices=sorted(CONFIGS))
    args = parser.parse_args()
    prepare(args.species_id)
