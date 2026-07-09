from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
ENEMY_OUT_DIR = ROOT / "assets" / "sprites" / "enemies"
PORTRAIT_OUT_DIR = ROOT / "assets" / "sprites" / "portraits" / "onboarding"
SIZE = 192
PORTRAIT_SIZE = 512


PALETTE = {
    "shadow": (32, 30, 42, 88),
    "boot": (48, 45, 60, 255),
    "under": (62, 75, 102, 255),
    "cloth": (88, 112, 148, 255),
    "armor_dark": (82, 94, 118, 255),
    "armor": (168, 183, 196, 255),
    "armor_light": (230, 235, 231, 255),
    "gold": (230, 180, 78, 255),
    "paper": (238, 226, 196, 255),
    "ink": (58, 54, 68, 255),
    "skin": (220, 166, 122, 255),
    "hair": (215, 196, 114, 255),
    "hair_dark": (118, 92, 56, 255),
    "red": (172, 68, 76, 255),
    "blue": (72, 118, 172, 255),
    "glow": (255, 232, 150, 112),
}


def ellipse(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], fill: tuple[int, int, int, int]) -> None:
    draw.ellipse(box, fill=fill)


def polygon(draw: ImageDraw.ImageDraw, points: list[tuple[int, int]], fill: tuple[int, int, int, int]) -> None:
    draw.polygon(points, fill=fill)


def rounded(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    radius: int,
    fill: tuple[int, int, int, int],
    outline: tuple[int, int, int, int] | None = None,
    width: int = 1,
) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def draw_body(draw: ImageDraw.ImageDraw, bob: int, step: int, attack: int, inspect: int) -> None:
    p = PALETTE
    cx = 96
    base_y = 133 + bob
    leg_spread = 5 + abs(step)

    ellipse(draw, (40, 149, 152, 176), p["shadow"])

    rounded(draw, (cx - 29 - leg_spread, base_y - 7, cx - 12 - step, base_y + 35), 8, p["boot"])
    rounded(draw, (cx + 12 - step, base_y - 7, cx + 29 + leg_spread, base_y + 35), 8, p["boot"])
    polygon(draw, [(cx - 42, base_y - 46), (cx - 30, base_y + 24), (cx + 30, base_y + 24), (cx + 42, base_y - 46)], p["cloth"])
    rounded(draw, (cx - 34, base_y - 82, cx + 34, base_y + 1), 17, p["armor_dark"])
    rounded(draw, (cx - 29, base_y - 86, cx + 29, base_y - 10), 14, p["armor"])
    polygon(draw, [(cx - 22, base_y - 82), (cx, base_y - 20), (cx + 22, base_y - 82)], p["armor_light"])
    rounded(draw, (cx - 34, base_y - 10, cx + 34, base_y + 2), 5, p["gold"])
    rounded(draw, (cx - 44, base_y - 78, cx - 25, base_y - 27), 8, p["armor"])
    rounded(draw, (cx + 25, base_y - 78, cx + 44, base_y - 27), 8, p["armor"])

    sword_x = cx + 36 + attack
    draw.line((sword_x, base_y - 118, sword_x - 6, base_y + 4), fill=p["armor_light"], width=7)
    draw.line((sword_x + 4, base_y - 114, sword_x - 2, base_y + 4), fill=(255, 255, 248, 185), width=2)
    rounded(draw, (sword_x - 12, base_y - 10, sword_x + 10, base_y - 2), 4, p["gold"])
    polygon(draw, [(sword_x - 9, base_y - 118), (sword_x + 3, base_y - 138), (sword_x + 11, base_y - 116)], p["armor_light"])

    board_x = cx - 48 + inspect - attack // 3
    board_y = base_y - 78
    rounded(draw, (board_x, board_y, board_x + 34, board_y + 52), 4, p["paper"], p["ink"], 2)
    rounded(draw, (board_x + 8, board_y - 5, board_x + 26, board_y + 5), 3, p["gold"])
    for offset in [14, 27, 40]:
        draw.line((board_x + 10, board_y + offset, board_x + 27, board_y + offset), fill=p["ink"], width=2)
        draw.line((board_x + 5, board_y + offset - 2, board_x + 8, board_y + offset + 2), fill=p["blue"], width=2)

    rounded(draw, (cx - 24, base_y - 122, cx + 24, base_y - 78), 15, p["skin"])
    polygon(draw, [(cx - 30, base_y - 112), (cx, base_y - 135), (cx + 30, base_y - 112)], p["hair_dark"])
    polygon(draw, [(cx - 25, base_y - 119), (cx - 3, base_y - 137), (cx + 28, base_y - 109), (cx + 12, base_y - 105)], p["hair"])
    rounded(draw, (cx - 21, base_y - 116, cx + 21, base_y - 104), 5, p["armor_dark"])
    rounded(draw, (cx - 13, base_y - 105, cx + 13, base_y - 98), 3, (40, 42, 52, 255))
    rounded(draw, (cx - 26, base_y - 126, cx + 26, base_y - 116), 5, p["gold"])
    polygon(draw, [(cx - 4, base_y - 130), (cx + 5, base_y - 130), (cx + 1, base_y - 120)], p["red"])


def draw_down(draw: ImageDraw.ImageDraw, frame: int) -> None:
    p = PALETTE
    offset = frame * 4
    ellipse(draw, (38, 144, 154, 172), p["shadow"])
    rounded(draw, (58 + offset, 119, 136 + offset, 150), 14, p["cloth"])
    rounded(draw, (72 + offset, 102, 124 + offset, 136), 14, p["armor"])
    rounded(draw, (52 + offset, 126, 88 + offset, 157), 6, p["paper"], p["ink"], 2)
    draw.line((58 + offset, 136, 80 + offset, 141), fill=p["ink"], width=2)
    rounded(draw, (120 + offset, 101, 156 + offset, 128), 12, p["skin"])
    polygon(draw, [(117 + offset, 100), (142 + offset, 82), (160 + offset, 109)], p["hair"])
    draw.line((144 + offset, 88, 150 + offset, 150), fill=p["armor_light"], width=5)


def draw_frame(animation: str, index: int) -> Image.Image:
    image = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    if animation == "down":
        draw_down(draw, index)
        return image

    bob = 0
    step = 0
    attack = 0
    inspect = 0
    if animation == "idle_down":
        bob = -1 if index % 2 == 1 else 0
    elif animation == "move_down":
        bob = -2 if index % 2 == 1 else 1
        step = [-6, 4, 6, -4][index]
    elif animation == "attack_down":
        bob = [0, -2, -1, 0][index]
        attack = [0, 9, 22, 4][index]
    elif animation == "skill_down":
        bob = [-1, -3, -2, 0][index]
        inspect = [0, 8, 16, 6][index]
        glow_size = [0, 8, 16, 10][index]
        if glow_size > 0:
            ellipse(draw, (48 - glow_size, 40 - glow_size, 146 + glow_size, 156 + glow_size), PALETTE["glow"])

    draw_body(draw, bob, step, attack, inspect)
    return image


def _portrait_glow(size: int) -> Image.Image:
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.ellipse((42, 40, 470, 486), fill=(82, 128, 190, 70))
    draw.ellipse((120, 70, 410, 430), fill=(245, 218, 126, 65))
    return layer.filter(ImageFilter.GaussianBlur(36))


def draw_portrait() -> Image.Image:
    image = Image.new("RGBA", (PORTRAIT_SIZE, PORTRAIT_SIZE), (0, 0, 0, 0))
    image.alpha_composite(_portrait_glow(PORTRAIT_SIZE))
    draw = ImageDraw.Draw(image)
    p = PALETTE

    rounded(draw, (128, 238, 384, 500), 44, p["armor_dark"])
    polygon(draw, [(132, 280), (256, 500), (380, 280)], p["cloth"])
    rounded(draw, (150, 214, 362, 474), 40, p["armor"])
    polygon(draw, [(184, 230), (256, 452), (328, 230)], p["armor_light"])
    rounded(draw, (138, 336, 374, 372), 13, p["gold"])
    rounded(draw, (84, 230, 168, 420), 26, p["armor"])
    rounded(draw, (344, 230, 428, 420), 26, p["armor"])

    rounded(draw, (160, 98, 352, 304), 70, p["skin"])
    polygon(draw, [(128, 138), (222, 38), (388, 160), (324, 216), (194, 190)], p["hair_dark"])
    polygon(draw, [(142, 132), (236, 42), (378, 154), (320, 196), (210, 174)], p["hair"])
    rounded(draw, (170, 128, 342, 170), 20, p["armor_dark"])
    rounded(draw, (184, 90, 328, 136), 20, p["gold"])
    polygon(draw, [(239, 78), (273, 78), (256, 126)], p["red"])
    rounded(draw, (178, 168, 334, 204), 12, (39, 42, 54, 255))
    draw.rectangle((205, 181, 223, 190), fill=(248, 248, 236, 255))
    draw.rectangle((289, 181, 307, 190), fill=(248, 248, 236, 255))
    draw.line((222, 246, 290, 246), fill=(112, 62, 58, 255), width=5)

    rounded(draw, (52, 268, 204, 478), 16, p["paper"], p["ink"], 5)
    rounded(draw, (96, 244, 160, 284), 12, p["gold"], p["ink"], 4)
    for y in [324, 366, 408]:
        draw.line((104, y, 174, y), fill=p["ink"], width=5)
        draw.line((78, y - 8, 92, y + 8), fill=p["blue"], width=5)
    draw.line((384, 138, 436, 456), fill=p["armor_light"], width=12)
    rounded(draw, (356, 314, 414, 342), 12, p["gold"])
    polygon(draw, [(370, 112), (396, 44), (426, 112)], p["armor_light"])

    return image


def main() -> None:
    ENEMY_OUT_DIR.mkdir(parents=True, exist_ok=True)
    PORTRAIT_OUT_DIR.mkdir(parents=True, exist_ok=True)
    animations = {
        "idle_down": 2,
        "move_down": 4,
        "attack_down": 4,
        "skill_down": 4,
        "down": 2,
    }
    for animation, frame_count in animations.items():
        for index in range(frame_count):
            path = ENEMY_OUT_DIR / f"enemy_selen_paladin_{animation}_{index:02d}.png"
            draw_frame(animation, index).save(path)
    # The runtime portrait is cropped from the built-in image_gen design sheet at
    # assets/source/imagegen/selen/CHR_SELEN_design_sheet_imagegen.png.
    # Do not overwrite it here with a procedural placeholder.


if __name__ == "__main__":
    main()
