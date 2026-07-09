from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "sprites" / "enemies"
SIZE = 192


PALETTE = {
    "shadow": (32, 29, 39, 84),
    "boot": (52, 50, 58, 255),
    "cloth_dark": (58, 68, 89, 255),
    "cloth": (78, 96, 126, 255),
    "armor_dark": (86, 94, 108, 255),
    "armor": (142, 154, 166, 255),
    "armor_light": (210, 218, 220, 255),
    "gold": (226, 176, 80, 255),
    "skin": (180, 130, 96, 255),
    "shield_dark": (84, 82, 94, 255),
    "shield": (124, 134, 148, 255),
    "shield_face": (180, 190, 198, 255),
    "red": (158, 58, 62, 255),
    "glow": (250, 224, 134, 112),
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


def draw_body(draw: ImageDraw.ImageDraw, bob: int, step: int, attack: int, guard: int) -> None:
    p = PALETTE
    cx = 96
    base_y = 132 + bob
    leg_spread = 6 + abs(step)

    ellipse(draw, (42, 148, 150, 174), p["shadow"])

    rounded(draw, (cx - 30 - leg_spread, base_y - 6, cx - 12 - step, base_y + 35), 8, p["boot"])
    rounded(draw, (cx + 12 - step, base_y - 6, cx + 30 + leg_spread, base_y + 35), 8, p["boot"])
    rounded(draw, (cx - 40, base_y - 68, cx + 40, base_y + 10), 18, p["cloth_dark"])
    polygon(draw, [(cx - 46, base_y - 38), (cx - 28, base_y + 26), (cx + 28, base_y + 26), (cx + 46, base_y - 38)], p["cloth"])

    rounded(draw, (cx - 32, base_y - 78, cx + 32, base_y - 8), 16, p["armor_dark"])
    rounded(draw, (cx - 28, base_y - 84, cx + 28, base_y - 12), 14, p["armor"])
    polygon(draw, [(cx - 20, base_y - 80), (cx, base_y - 18), (cx + 20, base_y - 80)], p["armor_light"])
    rounded(draw, (cx - 32, base_y - 10, cx + 32, base_y + 2), 5, p["gold"])

    spear_x = cx + 34 + attack
    draw.line((spear_x, base_y - 104, spear_x + 8, base_y + 10), fill=p["cloth_dark"], width=6)
    polygon(draw, [(spear_x - 8, base_y - 108), (spear_x + 4, base_y - 132), (spear_x + 16, base_y - 108)], p["armor_light"])
    polygon(draw, [(spear_x - 5, base_y - 110), (spear_x + 4, base_y - 124), (spear_x + 13, base_y - 110)], p["gold"])

    shield_x = cx - 34 + guard - attack // 2
    shield_y = base_y - 70 - guard // 2
    polygon(
        draw,
        [
            (shield_x, shield_y),
            (shield_x + 34, shield_y + 13),
            (shield_x + 28, shield_y + 74),
            (shield_x, shield_y + 92),
            (shield_x - 28, shield_y + 74),
            (shield_x - 34, shield_y + 13),
        ],
        p["shield_dark"],
    )
    polygon(
        draw,
        [
            (shield_x, shield_y + 8),
            (shield_x + 25, shield_y + 18),
            (shield_x + 20, shield_y + 66),
            (shield_x, shield_y + 80),
            (shield_x - 20, shield_y + 66),
            (shield_x - 25, shield_y + 18),
        ],
        p["shield_face"],
    )
    rounded(draw, (shield_x - 6, shield_y + 12, shield_x + 6, shield_y + 72), 3, p["red"])
    draw.arc((shield_x - 21, shield_y + 18, shield_x + 21, shield_y + 58), 200, 340, fill=p["gold"], width=4)

    rounded(draw, (cx - 25, base_y - 116, cx + 25, base_y - 72), 16, p["armor_dark"])
    rounded(draw, (cx - 21, base_y - 120, cx + 21, base_y - 78), 14, p["armor"])
    polygon(draw, [(cx - 30, base_y - 98), (cx + 30, base_y - 98), (cx + 22, base_y - 82), (cx - 22, base_y - 82)], p["armor_light"])
    rounded(draw, (cx - 14, base_y - 95, cx + 14, base_y - 86), 4, (35, 36, 42, 255))
    rounded(draw, (cx - 30, base_y - 124, cx + 30, base_y - 112), 6, p["gold"])


def draw_down(draw: ImageDraw.ImageDraw, frame: int) -> None:
    p = PALETTE
    offset = frame * 4
    ellipse(draw, (38, 142, 154, 170), p["shadow"])
    rounded(draw, (60 + offset, 118, 136 + offset, 148), 14, p["cloth_dark"])
    rounded(draw, (74 + offset, 104, 124 + offset, 134), 14, p["armor"])
    rounded(draw, (50 + offset, 128, 92 + offset, 154), 12, p["shield_dark"])
    polygon(draw, [(70 + offset, 108), (122 + offset, 112), (132 + offset, 130), (76 + offset, 136)], p["shield_face"])
    rounded(draw, (120 + offset, 104, 154 + offset, 132), 12, p["armor_dark"])
    rounded(draw, (126 + offset, 96, 156 + offset, 118), 10, p["armor"])


def draw_frame(animation: str, index: int) -> Image.Image:
    image = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    if animation == "down":
        draw_down(draw, index)
        return image

    bob = 0
    step = 0
    attack = 0
    guard = 0
    if animation == "idle_down":
        bob = -1 if index % 2 == 1 else 0
    elif animation == "move_down":
        bob = -2 if index % 2 == 1 else 1
        step = [-6, 4, 6, -4][index]
    elif animation == "attack_down":
        bob = [0, -2, -1, 0][index]
        attack = [0, 8, 18, 2][index]
    elif animation == "skill_down":
        bob = [-1, -3, -2, 0][index]
        guard = [0, 10, 18, 8][index]
        glow_size = [0, 8, 16, 10][index]
        if glow_size > 0:
            ellipse(draw, (46 - glow_size, 38 - glow_size, 146 + glow_size, 156 + glow_size), PALETTE["glow"])

    draw_body(draw, bob, step, attack, guard)
    return image


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    animations = {
        "idle_down": 2,
        "move_down": 4,
        "attack_down": 4,
        "skill_down": 4,
        "down": 2,
    }
    for animation, frame_count in animations.items():
        for index in range(frame_count):
            path = OUT_DIR / f"enemy_shieldbearer_{animation}_{index:02d}.png"
            draw_frame(animation, index).save(path)


if __name__ == "__main__":
    main()
