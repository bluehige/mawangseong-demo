#!/usr/bin/env python3
"""Create deterministic Steam upload graphics from approved in-repo artwork."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/ui/endings/update4/ending_minion_wears_the_crown.png"
FONT = ROOT / "assets/fonts/NEXON_Maplestory_Bold.otf"
OUTPUT = ROOT / "marketing/steam"

CAPSULES = {
    "store/header_capsule.png": (920, 430),
    "store/small_capsule.png": (462, 174),
    "store/main_capsule.png": (1232, 706),
    "store/vertical_capsule.png": (748, 896),
    "library/capsule.png": (600, 900),
    "library/header.png": (920, 430),
}


def cover(image: Image.Image, size: tuple[int, int], center: tuple[float, float]) -> Image.Image:
    width, height = size
    scale = max(width / image.width, height / image.height)
    resized = image.resize(
        (round(image.width * scale), round(image.height * scale)),
        Image.Resampling.LANCZOS,
    )
    cx = round(center[0] * resized.width)
    cy = round(center[1] * resized.height)
    left = min(max(cx - width // 2, 0), resized.width - width)
    top = min(max(cy - height // 2, 0), resized.height - height)
    return resized.crop((left, top, left + width, top + height))


def centered_text(
    draw: ImageDraw.ImageDraw,
    canvas_width: int,
    y: int,
    text: str,
    font: ImageFont.FreeTypeFont,
    *,
    fill: str,
    stroke_width: int,
    stroke_fill: str,
) -> None:
    box = draw.textbbox((0, 0), text, font=font, stroke_width=stroke_width)
    x = (canvas_width - (box[2] - box[0])) // 2
    draw.text(
        (x + 8, y + 12),
        text,
        font=font,
        fill=(0, 0, 0, 180),
        stroke_width=stroke_width + 3,
        stroke_fill=(0, 0, 0, 150),
    )
    draw.text(
        (x, y),
        text,
        font=font,
        fill=fill,
        stroke_width=stroke_width,
        stroke_fill=stroke_fill,
    )


def make_logo() -> Image.Image:
    logo = Image.new("RGBA", (1280, 720), (0, 0, 0, 0))
    draw = ImageDraw.Draw(logo)
    small = ImageFont.truetype(str(FONT), 128)
    large = ImageFont.truetype(str(FONT), 104)
    centered_text(
        draw,
        logo.width,
        185,
        "마왕님,",
        small,
        fill="#fff1ba",
        stroke_width=12,
        stroke_fill="#311346",
    )
    centered_text(
        draw,
        logo.width,
        335,
        "마왕성은 누가 지켜요?",
        large,
        fill="#f3c767",
        stroke_width=12,
        stroke_fill="#311346",
    )
    return logo


def logo_mark(logo: Image.Image) -> Image.Image:
    alpha_box = logo.getchannel("A").getbbox()
    if alpha_box is None:
        raise RuntimeError("generated logo is empty")
    return logo.crop(alpha_box)


def darken_for_logo(image: Image.Image, vertical: bool) -> Image.Image:
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    pixels = overlay.load()
    for y in range(image.height):
        ratio = y / max(image.height - 1, 1)
        if vertical:
            alpha = round(185 * max(0.0, 1.0 - ratio / 0.58))
        else:
            alpha = round(175 * max(0.0, (ratio - 0.48) / 0.52))
        for x in range(image.width):
            pixels[x, y] = (12, 4, 20, alpha)
    return Image.alpha_composite(image.convert("RGBA"), overlay)


def add_logo(image: Image.Image, mark: Image.Image, vertical: bool) -> Image.Image:
    target_width = round(image.width * (0.88 if vertical else 0.72))
    target_height = round(mark.height * target_width / mark.width)
    if target_height > round(image.height * 0.34):
        target_height = round(image.height * 0.34)
        target_width = round(mark.width * target_height / mark.height)
    resized = mark.resize((target_width, target_height), Image.Resampling.LANCZOS)
    x = (image.width - resized.width) // 2
    y = round(image.height * (0.07 if vertical else 0.64))
    image.alpha_composite(resized, (x, y))
    return image


def make_capsule(source: Image.Image, mark: Image.Image, size: tuple[int, int]) -> Image.Image:
    vertical = size[1] > size[0]
    center = (0.48, 0.50) if vertical else (0.51, 0.50)
    capsule = cover(source, size, center)
    capsule = ImageEnhance.Contrast(capsule).enhance(1.06)
    capsule = darken_for_logo(capsule, vertical)
    return add_logo(capsule, mark, vertical)


def make_icon(source: Image.Image, size: int) -> Image.Image:
    # Crop the crowned slime, the clearest product-identifying character in the art.
    square = cover(source, (700, 700), (0.40, 0.62))
    square = ImageEnhance.Color(square).enhance(1.08)
    square = ImageEnhance.Contrast(square).enhance(1.08)
    return square.resize((size, size), Image.Resampling.LANCZOS)


def save_png(image: Image.Image, relative: str) -> None:
    target = OUTPUT / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target, format="PNG", optimize=True)


def main() -> int:
    if not SOURCE.is_file() or not FONT.is_file():
        raise FileNotFoundError("approved source artwork or title font is missing")

    source = Image.open(SOURCE).convert("RGB")
    logo = make_logo()
    mark = logo_mark(logo)

    save_png(logo, "library/logo.png")
    for relative, size in CAPSULES.items():
        save_png(make_capsule(source, mark, size), relative)

    hero = cover(source, (3840, 1240), (0.50, 0.52))
    save_png(hero, "library/hero.png")
    save_png(make_icon(source, 256), "icons/shortcut.png")

    app_icon = make_icon(source, 184).convert("RGB")
    app_icon_path = OUTPUT / "icons/app_icon.jpg"
    app_icon_path.parent.mkdir(parents=True, exist_ok=True)
    app_icon.save(app_icon_path, format="JPEG", quality=95, optimize=True)

    print("STEAM_GRAPHICS: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
