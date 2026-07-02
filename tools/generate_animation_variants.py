from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
MONSTER_DIR = ROOT / "assets" / "sprites" / "monsters"
EFFECT_DIR = ROOT / "assets" / "sprites" / "effects"

try:
    RESAMPLE = Image.Resampling.BICUBIC
except AttributeError:
    RESAMPLE = Image.BICUBIC


MONSTER_GLOW = {
    "slime": (71, 218, 255, 150),
    "goblin": (137, 255, 78, 140),
    "imp": (255, 91, 36, 155),
}


def transparent(size):
    return Image.new("RGBA", size, (0, 0, 0, 0))


def alpha_bbox(image):
    return image.split()[-1].getbbox()


def tint_subject(subject, color, strength):
    if strength <= 0.0:
        return subject
    alpha = subject.split()[-1].point(lambda value: int(value * strength))
    tint = Image.new("RGBA", subject.size, color)
    tint.putalpha(alpha)
    return Image.alpha_composite(subject, tint)


def transform_subject(image, sx=1.0, sy=1.0, dx=0, dy=0, rotate=0.0, alpha=1.0, tint=None, tint_strength=0.0, glow=None):
    bbox = alpha_bbox(image)
    if bbox is None:
        return transparent(image.size)
    canvas = transparent(image.size)
    subject = image.crop(bbox)
    if tint is not None:
        subject = tint_subject(subject, tint, tint_strength)
    if alpha < 1.0:
        r, g, b, a = subject.split()
        subject = Image.merge("RGBA", (r, g, b, a.point(lambda value: int(value * alpha))))
    scaled_size = (max(1, int(subject.size[0] * sx)), max(1, int(subject.size[1] * sy)))
    subject = subject.resize(scaled_size, RESAMPLE)
    if abs(rotate) > 0.01:
        subject = subject.rotate(rotate, RESAMPLE, expand=True)

    anchor = ((bbox[0] + bbox[2]) * 0.5 + dx, (bbox[1] + bbox[3]) * 0.5 + dy)
    position = (int(anchor[0] - subject.size[0] * 0.5), int(anchor[1] - subject.size[1] * 0.5))

    if glow is not None:
        glow_color, blur_radius, glow_alpha = glow
        mask = transparent(image.size)
        mask.alpha_composite(subject, position)
        glow_mask = mask.split()[-1].filter(ImageFilter.GaussianBlur(blur_radius)).point(lambda value: int(value * glow_alpha))
        glow_layer = Image.new("RGBA", image.size, glow_color)
        glow_layer.putalpha(glow_mask)
        canvas.alpha_composite(glow_layer)

    canvas.alpha_composite(subject, position)
    return canvas


def draw_skill_aura(image, monster_key, pulse):
    bbox = alpha_bbox(image)
    if bbox is None:
        return image
    canvas = transparent(image.size)
    center_x = (bbox[0] + bbox[2]) * 0.5
    feet_y = bbox[3] - 12
    color = MONSTER_GLOW.get(monster_key, (190, 115, 255, 140))
    draw = ImageDraw.Draw(canvas)
    ring_w = 52 + pulse * 8
    ring_h = 20 + pulse * 4
    ring = [center_x - ring_w, feet_y - ring_h * 0.5, center_x + ring_w, feet_y + ring_h * 0.5]
    draw.ellipse(ring, outline=color, width=4)
    draw.ellipse([ring[0] + 16, ring[1] + 5, ring[2] - 16, ring[3] - 5], outline=(255, 238, 190, 70), width=2)
    canvas = canvas.filter(ImageFilter.GaussianBlur(0.35))
    canvas.alpha_composite(image)
    return canvas


def monster_key_from_name(name):
    for key in MONSTER_GLOW.keys():
        if key in name:
            return key
    return ""


def generate_monster_frames():
    specs = {
        "idle_down": [
            {"sx": 0.98, "sy": 1.035, "dy": -2},
        ],
        "move_down": [
            {"sx": 1.03, "sy": 0.97, "dx": -4, "dy": 2, "rotate": -2.2},
            {"sx": 0.98, "sy": 1.04, "dy": -3},
            {"sx": 1.03, "sy": 0.97, "dx": 4, "dy": 2, "rotate": 2.2},
        ],
        "attack_down": [
            {"sx": 0.96, "sy": 1.03, "dx": -3, "dy": -1, "rotate": -3.0},
            {"sx": 1.09, "sy": 0.94, "dx": 7, "dy": 2, "rotate": 4.0, "tint": (255, 196, 82, 255), "tint_strength": 0.16},
            {"sx": 1.02, "sy": 0.99, "dx": 2, "dy": 1},
        ],
        "skill_down": [
            {"sx": 0.98, "sy": 1.04, "dy": -3, "skill_pulse": 0, "tint": (255, 235, 160, 255), "tint_strength": 0.10},
            {"sx": 1.04, "sy": 1.04, "dy": -4, "skill_pulse": 1, "tint": (255, 235, 160, 255), "tint_strength": 0.18},
            {"sx": 1.0, "sy": 1.0, "skill_pulse": 2, "tint": (255, 235, 160, 255), "tint_strength": 0.08},
        ],
        "down": [
            {"sx": 1.08, "sy": 0.90, "dy": 8, "alpha": 0.86},
        ],
    }

    for source in sorted(MONSTER_DIR.glob("monster_*_00.png")):
        stem = source.stem
        action = None
        for candidate in specs.keys():
            if stem.endswith(f"_{candidate}_00"):
                action = candidate
                break
        if action is None:
            continue
        image = Image.open(source).convert("RGBA")
        monster_key = monster_key_from_name(stem)
        glow_color = MONSTER_GLOW.get(monster_key, (190, 115, 255, 150))
        base = source.with_name(stem[:-3])
        for index, spec in enumerate(specs[action], start=1):
            frame = transform_subject(
                image,
                sx=spec.get("sx", 1.0),
                sy=spec.get("sy", 1.0),
                dx=spec.get("dx", 0),
                dy=spec.get("dy", 0),
                rotate=spec.get("rotate", 0.0),
                alpha=spec.get("alpha", 1.0),
                tint=spec.get("tint"),
                tint_strength=spec.get("tint_strength", 0.0),
                glow=(glow_color, 5, 0.34) if action == "skill_down" else None,
            )
            if action == "skill_down":
                frame = draw_skill_aura(frame, monster_key, spec.get("skill_pulse", 0))
            frame.save(f"{base}_{index:02d}.png")


def effect_transform(source, scale=1.0, rotate=0.0, alpha=1.0, tint=None, tint_strength=0.0):
    image = Image.open(source).convert("RGBA")
    return transform_subject(image, sx=scale, sy=scale, rotate=rotate, alpha=alpha, tint=tint, tint_strength=tint_strength)


def save_effect_sequence(prefix, frames, start_index=0):
    for index, frame in enumerate(frames, start=start_index):
        frame.save(EFFECT_DIR / f"{prefix}_{index:02d}.png")


def radial_glow(size, circles):
    image = transparent(size)
    draw = ImageDraw.Draw(image)
    for center, radius, color in circles:
        x, y = center
        draw.ellipse([x - radius, y - radius, x + radius, y + radius], fill=color)
    return image.filter(ImageFilter.GaussianBlur(4))


def make_ring_frame(color, radius, alpha, spokes=False):
    image = transparent((128, 128))
    draw = ImageDraw.Draw(image)
    glow = radial_glow((128, 128), [((64, 68), radius + 10, color[:3] + (max(20, int(alpha * 0.28)),))])
    image.alpha_composite(glow)
    draw.ellipse([64 - radius, 68 - radius * 0.42, 64 + radius, 68 + radius * 0.42], outline=color[:3] + (alpha,), width=5)
    draw.ellipse([64 - radius * 0.63, 68 - radius * 0.27, 64 + radius * 0.63, 68 + radius * 0.27], outline=(255, 242, 190, int(alpha * 0.44)), width=2)
    if spokes:
        for x, y in [(64, 28), (92, 50), (37, 51), (64, 103)]:
            draw.ellipse([x - 4, y - 4, x + 4, y + 4], fill=(255, 232, 150, int(alpha * 0.72)))
    return image


def make_buff_effects():
    save_effect_sequence("fx_shield_pulse", [
        make_ring_frame((81, 219, 255, 255), 32, 90),
        make_ring_frame((81, 219, 255, 255), 40, 155),
        make_ring_frame((180, 245, 255, 255), 48, 120),
        make_ring_frame((81, 219, 255, 255), 58, 50),
    ])
    save_effect_sequence("fx_guard_pulse", [
        make_ring_frame((178, 103, 255, 255), 31, 85, True),
        make_ring_frame((178, 103, 255, 255), 39, 150, True),
        make_ring_frame((255, 212, 111, 255), 47, 120, True),
        make_ring_frame((178, 103, 255, 255), 57, 48, True),
    ])
    loot_frames = []
    for step, radius in enumerate([24, 31, 39, 48]):
        image = make_ring_frame((255, 210, 74, 255), radius, [80, 145, 110, 45][step], True)
        draw = ImageDraw.Draw(image)
        for x, y in [(42, 44), (84, 43), (50, 87), (79, 88)]:
            offset = step * 2
            draw.polygon([(x, y - 5 - offset), (x + 4, y), (x, y + 5 + offset), (x - 4, y)], fill=(255, 240, 148, max(30, 155 - step * 34)))
        loot_frames.append(image)
    save_effect_sequence("fx_loot_spark", loot_frames)


def generate_effect_frames():
    fireball = EFFECT_DIR / "fx_fireball_00.png"
    slash = EFFECT_DIR / "fx_hit_slash_00.png"
    impact = EFFECT_DIR / "fx_fire_impact_00.png"

    save_effect_sequence("fx_fireball", [
        effect_transform(fireball, scale=0.92, rotate=-8, alpha=0.92),
        effect_transform(fireball, scale=1.04, rotate=4, tint=(255, 242, 155, 255), tint_strength=0.12),
        effect_transform(fireball, scale=0.98, rotate=12, tint=(255, 102, 37, 255), tint_strength=0.10),
    ], start_index=1)
    save_effect_sequence("fx_hit_slash", [
        effect_transform(slash, scale=0.72, rotate=-9, alpha=0.72),
        effect_transform(slash, scale=1.00, rotate=0, alpha=1.0),
        effect_transform(slash, scale=1.18, rotate=6, tint=(255, 255, 220, 255), tint_strength=0.14),
    ], start_index=1)
    save_effect_sequence("fx_fire_impact", [
        effect_transform(impact, scale=0.72, alpha=0.70),
        effect_transform(impact, scale=1.00, tint=(255, 235, 120, 255), tint_strength=0.12),
        effect_transform(impact, scale=1.25, tint=(255, 95, 35, 255), tint_strength=0.12),
    ], start_index=1)
    make_buff_effects()


def make_preview_sheet():
    preview_dir = ROOT / "tmp" / "asset_previews"
    preview_dir.mkdir(parents=True, exist_ok=True)

    monster_files = []
    for monster in ["slime", "goblin", "imp"]:
        for action in ["idle_down", "move_down", "attack_down", "skill_down"]:
            monster_files.extend(sorted(MONSTER_DIR.glob(f"monster_{monster}_{action}_*.png")))
    sheet = transparent((384, 720))
    x = y = 0
    for path in monster_files:
        image = Image.open(path).convert("RGBA").resize((64, 64), RESAMPLE)
        sheet.alpha_composite(image, (x + 16, y + 4))
        x += 96
        if x >= sheet.size[0]:
            x = 0
            y += 72
    sheet.crop((0, 0, sheet.size[0], min(sheet.size[1], y + 80))).save(preview_dir / "monster_animation_variants.png")

    effect_files = []
    for prefix in ["fx_fireball", "fx_hit_slash", "fx_fire_impact", "fx_shield_pulse", "fx_guard_pulse", "fx_loot_spark"]:
        effect_files.extend(sorted(EFFECT_DIR.glob(f"{prefix}_*.png")))
    effect_sheet = transparent((384, 520))
    x = y = 0
    for path in effect_files:
        image = Image.open(path).convert("RGBA").resize((64, 64), RESAMPLE)
        effect_sheet.alpha_composite(image, (x + 16, y + 4))
        x += 96
        if x >= effect_sheet.size[0]:
            x = 0
            y += 72
    effect_sheet.crop((0, 0, effect_sheet.size[0], min(effect_sheet.size[1], y + 80))).save(preview_dir / "skill_effect_variants.png")


def main():
    generate_monster_frames()
    generate_effect_frames()
    make_preview_sheet()
    print("Generated monster animation variants and skill effect frames.")


if __name__ == "__main__":
    main()
