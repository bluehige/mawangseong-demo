#!/usr/bin/env python3
"""Create deterministic STOVE upload graphics from approved in-repo artwork."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFont


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/ui/endings/update4/ending_minion_wears_the_crown.png"
FONT = ROOT / "assets/fonts/NEXON_Maplestory_Bold.otf"
SCREENSHOT_SOURCE = ROOT / "marketing/steam/screenshots"
OUTPUT = ROOT / "marketing/stove"


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
    width: int,
    y: int,
    text: str,
    font: ImageFont.FreeTypeFont,
    *,
    fill: str,
    stroke_width: int,
) -> None:
    box = draw.textbbox((0, 0), text, font=font, stroke_width=stroke_width)
    x = (width - (box[2] - box[0])) // 2
    draw.text(
        (x + 3, y + 5),
        text,
        font=font,
        fill=(0, 0, 0, 180),
        stroke_width=stroke_width + 2,
        stroke_fill=(0, 0, 0, 145),
    )
    draw.text(
        (x, y),
        text,
        font=font,
        fill=fill,
        stroke_width=stroke_width,
        stroke_fill="#311346",
    )


def add_title(image: Image.Image, *, square: bool) -> Image.Image:
    canvas = image.convert("RGBA")
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw_overlay = ImageDraw.Draw(overlay)
    if square:
        draw_overlay.rectangle((0, 0, canvas.width, round(canvas.height * 0.43)), fill=(12, 4, 20, 165))
        first_y = round(canvas.height * 0.07)
        second_y = round(canvas.height * 0.21)
        first_size = max(28, round(canvas.width * 0.095))
        second_size = max(24, round(canvas.width * 0.068))
    else:
        draw_overlay.rectangle((0, round(canvas.height * 0.57), canvas.width, canvas.height), fill=(12, 4, 20, 175))
        first_y = round(canvas.height * 0.62)
        second_y = round(canvas.height * 0.76)
        first_size = max(28, round(canvas.width * 0.068))
        second_size = max(24, round(canvas.width * 0.050))
    canvas = Image.alpha_composite(canvas, overlay)
    draw = ImageDraw.Draw(canvas)
    centered_text(
        draw,
        canvas.width,
        first_y,
        "마왕님,",
        ImageFont.truetype(str(FONT), first_size),
        fill="#fff1ba",
        stroke_width=max(2, round(first_size * 0.08)),
    )
    centered_text(
        draw,
        canvas.width,
        second_y,
        "마왕성은 누가 지켜요?",
        ImageFont.truetype(str(FONT), second_size),
        fill="#f3c767",
        stroke_width=max(2, round(second_size * 0.08)),
    )
    return canvas


def make_icon(source: Image.Image) -> Image.Image:
    icon = cover(source, (720, 720), (0.40, 0.62))
    icon = ImageEnhance.Color(icon).enhance(1.08)
    icon = ImageEnhance.Contrast(icon).enhance(1.08)
    return icon.resize((256, 256), Image.Resampling.LANCZOS)


def save_png(image: Image.Image, relative: str) -> None:
    target = OUTPUT / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target, format="PNG", optimize=True)


def main() -> int:
    if not SOURCE.is_file() or not FONT.is_file():
        raise FileNotFoundError("approved artwork or title font is missing")
    screenshots = sorted(SCREENSHOT_SOURCE.glob("*.png"))
    if len(screenshots) < 5:
        raise FileNotFoundError("at least five approved gameplay screenshots are required")

    source = Image.open(SOURCE).convert("RGB")
    square = add_title(cover(source, (500, 500), (0.47, 0.55)), square=True)
    landscape = add_title(cover(source, (757, 426), (0.51, 0.50)), square=False)
    save_png(square, "store/title_square_500.png")
    save_png(landscape, "store/title_landscape_757x426.png")
    save_png(square, "store/pc_thumbnail_500.png")

    icon = make_icon(source).convert("RGBA")
    icon_path = OUTPUT / "icons/windows_desktop.ico"
    icon_path.parent.mkdir(parents=True, exist_ok=True)
    icon.save(icon_path, format="ICO", sizes=[(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)])

    for screenshot in screenshots:
        with Image.open(screenshot) as image:
            resized = cover(image.convert("RGB"), (860, 483), (0.50, 0.50))
            save_png(resized, f"screenshots/{screenshot.name}")

    print(f"STOVE_GRAPHICS: PASS ({len(screenshots)} screenshots)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
