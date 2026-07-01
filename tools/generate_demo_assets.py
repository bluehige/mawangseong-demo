from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
random.seed(17)


def ensure_dirs() -> None:
    for part in [
        "assets/sprites/monsters",
        "assets/sprites/enemies",
        "assets/sprites/rooms",
        "assets/sprites/tiles",
        "assets/sprites/effects",
        "assets/sprites/ui",
    ]:
        (ROOT / part).mkdir(parents=True, exist_ok=True)


def rgba(hex_color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    hex_color = hex_color.strip("#")
    return tuple(int(hex_color[i : i + 2], 16) for i in (0, 2, 4)) + (alpha,)


def canvas(size: int = 128, scale: int = 4) -> tuple[Image.Image, ImageDraw.ImageDraw, int]:
    img = Image.new("RGBA", (size * scale, size * scale), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img), scale


def save_scaled(img: Image.Image, path: Path, size: int = 128) -> None:
    img = img.resize((size, size), Image.Resampling.LANCZOS)
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)


def ellipse(draw: ImageDraw.ImageDraw, box, fill, outline=None, width=1) -> None:
    draw.ellipse(box, fill=fill, outline=outline, width=width)


def polygon(draw: ImageDraw.ImageDraw, points, fill, outline=None) -> None:
    draw.polygon(points, fill=fill, outline=outline)


def glow_layer(size: int, circles: list[tuple[tuple[int, int], int, str, int]], scale: int = 4) -> Image.Image:
    layer = Image.new("RGBA", (size * scale, size * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    for center, radius, color, alpha in circles:
        cx, cy = center[0] * scale, center[1] * scale
        r = radius * scale
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=rgba(color, alpha))
    return layer.filter(ImageFilter.GaussianBlur(8 * scale))


def character_slime() -> None:
    img, d, s = canvas()
    img.alpha_composite(glow_layer(128, [((64, 75), 50, "6bc7ff", 70)]))
    ellipse(d, (28*s, 44*s, 100*s, 104*s), rgba("2fa8e8"), rgba("0d3150"), 4*s)
    ellipse(d, (38*s, 34*s, 88*s, 80*s), rgba("48c6ff"), rgba("0d3150"), 3*s)
    ellipse(d, (43*s, 52*s, 53*s, 63*s), rgba("07111e"))
    ellipse(d, (75*s, 52*s, 85*s, 63*s), rgba("07111e"))
    ellipse(d, (47*s, 55*s, 50*s, 58*s), rgba("ffffff"))
    ellipse(d, (79*s, 55*s, 82*s, 58*s), rgba("ffffff"))
    d.arc((50*s, 61*s, 78*s, 80*s), 10, 170, fill=rgba("07111e"), width=2*s)
    ellipse(d, (43*s, 39*s, 63*s, 50*s), rgba("c7f4ff", 120))
    d.arc((19*s, 32*s, 109*s, 112*s), 205, 335, fill=rgba("95e7ff", 160), width=5*s)
    save_scaled(img, ROOT / "assets/sprites/monsters/monster_slime_idle_down_00.png")


def character_goblin() -> None:
    img, d, s = canvas()
    img.alpha_composite(glow_layer(128, [((63, 76), 46, "8bd450", 52)]))
    polygon(d, [(32*s, 52*s), (10*s, 46*s), (34*s, 67*s)], rgba("5ca235"), rgba("17350d"))
    polygon(d, [(96*s, 52*s), (118*s, 46*s), (94*s, 67*s)], rgba("5ca235"), rgba("17350d"))
    ellipse(d, (33*s, 34*s, 95*s, 91*s), rgba("5faf38"), rgba("17350d"), 4*s)
    ellipse(d, (42*s, 50*s, 55*s, 61*s), rgba("ffd35a"))
    ellipse(d, (73*s, 50*s, 86*s, 61*s), rgba("ffd35a"))
    ellipse(d, (47*s, 53*s, 51*s, 57*s), rgba("0d0a0c"))
    ellipse(d, (78*s, 53*s, 82*s, 57*s), rgba("0d0a0c"))
    d.arc((48*s, 63*s, 83*s, 82*s), 12, 168, fill=rgba("2a0b0b"), width=3*s)
    polygon(d, [(45*s, 92*s), (82*s, 92*s), (92*s, 118*s), (35*s, 118*s)], rgba("5a3b1e"), rgba("1f1309"))
    d.line((82*s, 88*s, 111*s, 58*s), fill=rgba("dfe8ed"), width=4*s)
    d.line((78*s, 91*s, 88*s, 82*s), fill=rgba("7b4b24"), width=5*s)
    save_scaled(img, ROOT / "assets/sprites/monsters/monster_goblin_idle_down_00.png")


def character_imp() -> None:
    img, d, s = canvas()
    img.alpha_composite(glow_layer(128, [((75, 72), 58, "ff5a2f", 64), ((42, 72), 32, "8d3cff", 42)]))
    polygon(d, [(34*s, 29*s), (45*s, 10*s), (51*s, 42*s)], rgba("a50e1d"), rgba("2e0608"))
    polygon(d, [(94*s, 29*s), (83*s, 10*s), (77*s, 42*s)], rgba("a50e1d"), rgba("2e0608"))
    polygon(d, [(35*s, 66*s), (10*s, 56*s), (22*s, 91*s)], rgba("7c1d2d", 210), rgba("2e0608"))
    polygon(d, [(93*s, 66*s), (118*s, 56*s), (106*s, 91*s)], rgba("7c1d2d", 210), rgba("2e0608"))
    ellipse(d, (31*s, 27*s, 97*s, 92*s), rgba("d8282e"), rgba("36070b"), 4*s)
    ellipse(d, (44*s, 49*s, 56*s, 61*s), rgba("ffe25d"))
    ellipse(d, (72*s, 49*s, 84*s, 61*s), rgba("ffe25d"))
    d.arc((48*s, 61*s, 81*s, 80*s), 20, 160, fill=rgba("1f0508"), width=3*s)
    polygon(d, [(60*s, 88*s), (78*s, 116*s), (50*s, 116*s)], rgba("b81f2a"), rgba("36070b"))
    ellipse(d, (16*s, 68*s, 42*s, 94*s), rgba("ff9b2e"), rgba("fff0a6"), 2*s)
    ellipse(d, (22*s, 74*s, 36*s, 89*s), rgba("ffd65a"))
    save_scaled(img, ROOT / "assets/sprites/monsters/monster_imp_idle_down_00.png")


def enemy_explorer() -> None:
    img, d, s = canvas()
    img.alpha_composite(glow_layer(128, [((39, 68), 34, "ffb13d", 48)]))
    ellipse(d, (41*s, 31*s, 87*s, 77*s), rgba("e7b886"), rgba("442c1a"), 3*s)
    d.rectangle((34*s, 27*s, 94*s, 39*s), fill=rgba("b58a43"), outline=rgba("422a14"), width=3*s)
    d.rectangle((47*s, 16*s, 80*s, 33*s), fill=rgba("d0a556"), outline=rgba("422a14"), width=3*s)
    ellipse(d, (49*s, 50*s, 55*s, 57*s), rgba("1e1511"))
    ellipse(d, (73*s, 50*s, 79*s, 57*s), rgba("1e1511"))
    d.arc((52*s, 58*s, 78*s, 77*s), 190, 350, fill=rgba("522017"), width=2*s)
    polygon(d, [(45*s, 79*s), (83*s, 79*s), (94*s, 115*s), (34*s, 115*s)], rgba("60758a"), rgba("18222f"))
    d.line((24*s, 68*s, 19*s, 102*s), fill=rgba("603b1e"), width=5*s)
    ellipse(d, (12*s, 54*s, 28*s, 72*s), rgba("ffb32b"), rgba("ffed9e"), 2*s)
    save_scaled(img, ROOT / "assets/sprites/enemies/enemy_explorer_idle_down_00.png")


def enemy_thief() -> None:
    img, d, s = canvas()
    img.alpha_composite(glow_layer(128, [((67, 82), 44, "171a24", 110)]))
    polygon(d, [(64*s, 19*s), (99*s, 110*s), (29*s, 110*s)], rgba("11131a"), rgba("050509"))
    ellipse(d, (43*s, 35*s, 85*s, 78*s), rgba("20222d"), rgba("07070b"), 3*s)
    ellipse(d, (49*s, 53*s, 58*s, 60*s), rgba("d9d2bd"))
    ellipse(d, (70*s, 53*s, 79*s, 60*s), rgba("d9d2bd"))
    d.line((44*s, 65*s, 84*s, 65*s), fill=rgba("050509"), width=3*s)
    ellipse(d, (79*s, 76*s, 115*s, 111*s), rgba("b78a4e"), rgba("513114"), 4*s)
    d.line((85*s, 80*s, 106*s, 106*s), fill=rgba("66431e"), width=3*s)
    save_scaled(img, ROOT / "assets/sprites/enemies/enemy_thief_idle_down_00.png")


def enemy_hero() -> None:
    img, d, s = canvas()
    img.alpha_composite(glow_layer(128, [((64, 78), 45, "fff2a8", 42)]))
    ellipse(d, (39*s, 28*s, 89*s, 78*s), rgba("e8bd8a"), rgba("3c2415"), 3*s)
    polygon(d, [(36*s, 39*s), (64*s, 12*s), (92*s, 39*s)], rgba("f3c236"), rgba("7a4a16"))
    ellipse(d, (48*s, 49*s, 56*s, 56*s), rgba("1b1710"))
    ellipse(d, (72*s, 49*s, 80*s, 56*s), rgba("1b1710"))
    d.arc((50*s, 59*s, 79*s, 77*s), 15, 165, fill=rgba("5e2518"), width=2*s)
    polygon(d, [(45*s, 78*s), (83*s, 78*s), (95*s, 116*s), (33*s, 116*s)], rgba("6f89aa"), rgba("18263b"))
    d.line((94*s, 49*s, 117*s, 96*s), fill=rgba("d8e1e8"), width=5*s)
    ellipse(d, (19*s, 70*s, 44*s, 102*s), rgba("a9b8d8"), rgba("27334b"), 4*s)
    save_scaled(img, ROOT / "assets/sprites/enemies/enemy_trainee_hero_idle_down_00.png")


def tile_floor() -> None:
    size = 64
    img = Image.new("RGBA", (size, size), rgba("241f2b"))
    d = ImageDraw.Draw(img)
    for _ in range(13):
        x = random.randint(-8, 58)
        y = random.randint(-8, 58)
        w = random.randint(12, 34)
        h = random.randint(8, 24)
        color = random.choice([rgba("2e2935"), rgba("1d1924"), rgba("342d3c")])
        d.rounded_rectangle((x, y, x + w, y + h), radius=5, fill=color, outline=rgba("100e14", 100))
    for _ in range(7):
        x = random.randint(0, 63)
        y = random.randint(0, 63)
        d.line((x, y, min(63, x + random.randint(6, 20)), min(63, y + random.randint(-8, 8))), fill=rgba("725c8e", 80), width=1)
    img.save(ROOT / "assets/sprites/tiles/tile_cave_floor_01.png")


def tile_wall() -> None:
    size = 64
    img = Image.new("RGBA", (size, size), rgba("17131d"))
    d = ImageDraw.Draw(img)
    for _ in range(10):
        x = random.randint(-4, 56)
        y = random.randint(-6, 48)
        d.rounded_rectangle((x, y, x + random.randint(16, 30), y + random.randint(14, 28)), radius=4, fill=random.choice([rgba("2a2530"), rgba("38303e"), rgba("1f1b25")]), outline=rgba("0c0a0f"))
    d.rectangle((0, 54, 64, 64), fill=rgba("0d0b10", 230))
    d.line((0, 55, 64, 55), fill=rgba("895bff", 110), width=2)
    img.save(ROOT / "assets/sprites/tiles/tile_cave_wall_top_01.png")


def tile_spike() -> None:
    img = Image.new("RGBA", (64, 64), rgba("211a24"))
    d = ImageDraw.Draw(img)
    for x in range(8, 64, 16):
        for y in range(10, 64, 20):
            d.polygon([(x, y + 18), (x + 7, y), (x + 14, y + 18)], fill=rgba("736a76"), outline=rgba("161118"))
    img.save(ROOT / "assets/sprites/tiles/tile_spike_floor_01.png")


def room_prop(name: str, drawer) -> None:
    img, d, s = canvas()
    drawer(img, d, s)
    save_scaled(img, ROOT / f"assets/sprites/rooms/{name}.png")


def make_props() -> None:
    def gate(img, d, s):
        d.rounded_rectangle((35*s, 33*s, 93*s, 107*s), radius=8*s, fill=rgba("17131d"), outline=rgba("7a5f36"), width=4*s)
        for x in [45, 59, 73, 87]:
            d.line((x*s, 38*s, x*s, 104*s), fill=rgba("3b3339"), width=5*s)
        d.arc((34*s, 21*s, 94*s, 78*s), 180, 360, fill=rgba("9e6cff"), width=5*s)

    def spike(img, d, s):
        for x in [30, 48, 66, 84]:
            polygon(d, [(x*s, 96*s), ((x+8)*s, 38*s), ((x+16)*s, 96*s)], rgba("77717b"), rgba("17131d"))
        d.rectangle((20*s, 94*s, 108*s, 106*s), fill=rgba("271f28"), outline=rgba("7a5f36"), width=3*s)

    def brazier(img, d, s):
        d.rectangle((45*s, 72*s, 83*s, 98*s), fill=rgba("59402b"), outline=rgba("17100b"), width=3*s)
        d.ellipse((35*s, 65*s, 93*s, 88*s), fill=rgba("7c5731"), outline=rgba("1b100a"), width=3*s)
        d.polygon([(64*s, 22*s), (48*s, 70*s), (82*s, 70*s)], fill=rgba("933cff", 180))
        d.polygon([(64*s, 34*s), (55*s, 70*s), (76*s, 70*s)], fill=rgba("ff9b2d", 220))

    def throne(img, d, s):
        d.rounded_rectangle((31*s, 31*s, 97*s, 111*s), radius=8*s, fill=rgba("4b1f28"), outline=rgba("b28b45"), width=5*s)
        d.rectangle((43*s, 49*s, 85*s, 103*s), fill=rgba("762b37"), outline=rgba("1f0d12"), width=3*s)
        d.ellipse((51*s, 18*s, 77*s, 44*s), fill=rgba("c6b0a6"), outline=rgba("1e1720"), width=3*s)
        d.rectangle((35*s, 95*s, 93*s, 114*s), fill=rgba("6d5330"), outline=rgba("1f1408"), width=3*s)

    def barracks(img, d, s):
        for x in [32, 51, 70, 89]:
            d.line((x*s, 30*s, x*s, 104*s), fill=rgba("7b5631"), width=5*s)
            d.polygon([((x-6)*s, 44*s), (x*s, 27*s), ((x+6)*s, 44*s)], fill=rgba("b7b8b0"), outline=rgba("1d1c1c"))
        d.rectangle((23*s, 96*s, 105*s, 110*s), fill=rgba("49351d"), outline=rgba("1a1108"), width=3*s)

    def treasure(img, d, s):
        for _ in range(28):
            x = random.randint(26, 100) * s
            y = random.randint(62, 104) * s
            d.ellipse((x, y, x + 10*s, y + 7*s), fill=rgba("e6b03a"), outline=rgba("6d4310"))
        d.rounded_rectangle((44*s, 35*s, 100*s, 78*s), radius=8*s, fill=rgba("8c521d"), outline=rgba("1c1008"), width=4*s)
        d.arc((44*s, 20*s, 100*s, 70*s), 180, 360, fill=rgba("d09b38"), width=7*s)
        d.rectangle((67*s, 50*s, 78*s, 67*s), fill=rgba("f5dc68"), outline=rgba("5f3a0d"), width=2*s)

    def recovery(img, d, s):
        d.ellipse((34*s, 66*s, 94*s, 111*s), fill=rgba("5b3d24"), outline=rgba("1b1009"), width=3*s)
        for x, y in [(46, 52), (64, 40), (82, 53)]:
            d.ellipse((x*s, y*s, (x+22)*s, (y+32)*s), fill=rgba("b8c78f"), outline=rgba("29321f"), width=3*s)
        d.arc((20*s, 26*s, 108*s, 116*s), 210, 330, fill=rgba("85ffb1", 170), width=4*s)

    def build_slot(img, d, s):
        d.rounded_rectangle((24*s, 27*s, 104*s, 105*s), radius=12*s, outline=rgba("bb75ff"), width=5*s)
        d.line((64*s, 45*s, 64*s, 87*s), fill=rgba("bb75ff"), width=7*s)
        d.line((43*s, 66*s, 85*s, 66*s), fill=rgba("bb75ff"), width=7*s)

    def watch_post(img, d, s):
        d.rectangle((42*s, 50*s, 86*s, 108*s), fill=rgba("51371d"), outline=rgba("17100a"), width=4*s)
        d.polygon([(33*s, 55*s), (64*s, 24*s), (95*s, 55*s)], fill=rgba("5d4b57"), outline=rgba("151017"))
        d.ellipse((52*s, 70*s, 76*s, 94*s), fill=rgba("9d6cff"), outline=rgba("1b1225"), width=3*s)

    room_prop("prop_gate_01", gate)
    room_prop("prop_spike_floor_01", spike)
    room_prop("prop_brazier_01", brazier)
    room_prop("prop_throne_01", throne)
    room_prop("prop_barracks_01", barracks)
    room_prop("prop_treasure_pile_01", treasure)
    room_prop("prop_recovery_nest_01", recovery)
    room_prop("prop_build_slot_01", build_slot)
    room_prop("prop_watch_post_01", watch_post)


def make_effects() -> None:
    def save_effect(name: str, draw_fn) -> None:
        img, d, s = canvas()
        draw_fn(img, d, s)
        save_scaled(img, ROOT / f"assets/sprites/effects/{name}.png")

    save_effect("fx_fireball_00", lambda img, d, s: (
        img.alpha_composite(glow_layer(128, [((64, 64), 34, "ff5d24", 120), ((64, 64), 20, "ffd65a", 160)])),
        d.ellipse((40*s, 41*s, 88*s, 89*s), fill=rgba("ff7a24"), outline=rgba("fff1a2"), width=3*s),
        d.polygon([(40*s, 64*s), (17*s, 49*s), (43*s, 49*s)], fill=rgba("ffb339", 200))
    ))
    save_effect("fx_hit_slash_00", lambda img, d, s: (
        d.arc((24*s, 20*s, 112*s, 112*s), 215, 334, fill=rgba("ffe7a1"), width=8*s),
        d.arc((30*s, 28*s, 105*s, 104*s), 215, 330, fill=rgba("ff8a34"), width=4*s)
    ))
    save_effect("fx_fire_impact_00", lambda img, d, s: (
        img.alpha_composite(glow_layer(128, [((64, 70), 40, "ff6530", 90)])),
        d.ellipse((36*s, 43*s, 92*s, 99*s), outline=rgba("ffdc70"), width=6*s),
        d.ellipse((48*s, 55*s, 80*s, 87*s), fill=rgba("ff6b29", 190))
    ))
    save_effect("fx_selection_ring_00", lambda img, d, s: (
        d.ellipse((25*s, 55*s, 103*s, 103*s), outline=rgba("b15dff"), width=5*s),
        d.ellipse((34*s, 61*s, 94*s, 96*s), outline=rgba("ffe0ff", 120), width=2*s)
    ))


def icon(name: str, draw_fn) -> None:
    img, d, s = canvas()
    draw_fn(img, d, s)
    save_scaled(img, ROOT / f"assets/sprites/ui/{name}.png")


def make_icons() -> None:
    icon("ui_icon_gold", lambda img, d, s: (
        d.ellipse((28*s, 29*s, 100*s, 101*s), fill=rgba("e6ad31"), outline=rgba("fff2a0"), width=5*s),
        d.ellipse((43*s, 44*s, 85*s, 86*s), outline=rgba("8b5413"), width=4*s)
    ))
    icon("ui_icon_mana", lambda img, d, s: (
        d.polygon([(64*s, 18*s), (94*s, 68*s), (64*s, 108*s), (34*s, 68*s)], fill=rgba("3aa7ff"), outline=rgba("c2e9ff")),
        d.ellipse((51*s, 48*s, 72*s, 77*s), fill=rgba("92dcff", 130))
    ))
    icon("ui_icon_food", lambda img, d, s: (
        d.ellipse((32*s, 45*s, 92*s, 92*s), fill=rgba("a55f32"), outline=rgba("2b160d"), width=4*s),
        d.rectangle((80*s, 64*s, 111*s, 77*s), fill=rgba("d6c5a9"), outline=rgba("412718"), width=3*s)
    ))
    icon("ui_icon_infamy", lambda img, d, s: (
        d.ellipse((31*s, 29*s, 97*s, 94*s), fill=rgba("7b32c8"), outline=rgba("241039"), width=4*s),
        d.polygon([(46*s, 28*s), (29*s, 10*s), (34*s, 47*s)], fill=rgba("7b32c8"), outline=rgba("241039")),
        d.polygon([(82*s, 28*s), (99*s, 10*s), (94*s, 47*s)], fill=rgba("7b32c8"), outline=rgba("241039")),
        d.ellipse((48*s, 53*s, 58*s, 64*s), fill=rgba("0d0714")),
        d.ellipse((70*s, 53*s, 80*s, 64*s), fill=rgba("0d0714"))
    ))
    icon("ui_icon_shield", lambda img, d, s: (
        d.polygon([(64*s, 18*s), (99*s, 33*s), (93*s, 79*s), (64*s, 110*s), (35*s, 79*s), (29*s, 33*s)], fill=rgba("347ecf"), outline=rgba("d8f1ff"), width=4*s)
    ))
    icon("ui_icon_attack", lambda img, d, s: (
        d.line((32*s, 96*s, 94*s, 34*s), fill=rgba("ff5050"), width=9*s),
        d.line((37*s, 34*s, 96*s, 93*s), fill=rgba("ffb149"), width=9*s)
    ))
    icon("ui_icon_survival", lambda img, d, s: (
        d.pieslice((28*s, 28*s, 100*s, 100*s), 200, -20, fill=rgba("6bd556"), outline=rgba("eaffdf"), width=4*s),
        d.polygon([(64*s, 101*s), (28*s, 60*s), (100*s, 60*s)], fill=rgba("6bd556"))
    ))
    icon("ui_icon_trap", lambda img, d, s: (
        d.polygon([(32*s, 100*s), (45*s, 35*s), (58*s, 100*s)], fill=rgba("bfc0c8"), outline=rgba("1b1920")),
        d.polygon([(70*s, 100*s), (83*s, 35*s), (96*s, 100*s)], fill=rgba("bfc0c8"), outline=rgba("1b1920"))
    ))
    icon("ui_icon_direct_control", lambda img, d, s: (
        d.ellipse((32*s, 28*s, 96*s, 92*s), fill=rgba("e58a2a"), outline=rgba("fff0a6"), width=5*s),
        d.polygon([(64*s, 18*s), (76*s, 48*s), (106*s, 50*s), (81*s, 67*s), (91*s, 99*s), (64*s, 78*s), (37*s, 99*s), (47*s, 67*s), (22*s, 50*s), (52*s, 48*s)], fill=rgba("25110a"))
    ))


def main() -> None:
    ensure_dirs()
    character_slime()
    character_goblin()
    character_imp()
    enemy_explorer()
    enemy_thief()
    enemy_hero()
    tile_floor()
    tile_wall()
    tile_spike()
    make_props()
    make_effects()
    make_icons()
    print("Generated demo PNG assets.")


if __name__ == "__main__":
    main()
