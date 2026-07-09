from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "sprites" / "ui" / "evolution"
SIZE = 128


BADGES = {
    "badge_slime_gate_bulwark.png": {
        "base": (80, 206, 184, 255),
        "accent": (255, 231, 142, 255),
        "shadow": (28, 76, 82, 255),
        "symbol": "shield",
    },
    "badge_goblin_ambush_captain.png": {
        "base": (126, 212, 84, 255),
        "accent": (255, 189, 86, 255),
        "shadow": (38, 82, 34, 255),
        "symbol": "dagger",
    },
    "badge_imp_flame_adept.png": {
        "base": (231, 96, 66, 255),
        "accent": (255, 221, 96, 255),
        "shadow": (92, 38, 66, 255),
        "symbol": "flame",
    },
}


def draw_badge(path: Path, spec: dict[str, object]) -> None:
    image = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    base = spec["base"]
    accent = spec["accent"]
    shadow = spec["shadow"]

    draw.ellipse((12, 14, 116, 118), fill=shadow)
    draw.ellipse((10, 8, 118, 116), fill=base, outline=accent, width=5)
    draw.ellipse((26, 24, 102, 100), outline=(255, 255, 255, 72), width=3)

    symbol = spec["symbol"]
    if symbol == "shield":
        draw.polygon([(64, 28), (94, 42), (88, 82), (64, 102), (40, 82), (34, 42)], fill=accent)
        draw.polygon([(64, 40), (82, 48), (78, 76), (64, 90), (50, 76), (46, 48)], fill=(46, 136, 132, 255))
        draw.rectangle((58, 42, 70, 88), fill=(234, 255, 244, 220))
    elif symbol == "dagger":
        draw.polygon([(72, 24), (88, 36), (56, 84), (42, 72)], fill=accent)
        draw.polygon([(42, 72), (56, 84), (48, 94), (32, 88)], fill=(247, 236, 206, 255))
        draw.rectangle((36, 78, 80, 90), fill=(54, 74, 44, 255))
        draw.ellipse((24, 82, 42, 100), fill=accent)
    elif symbol == "flame":
        draw.polygon([(64, 22), (82, 48), (92, 72), (78, 100), (50, 100), (36, 76), (48, 52)], fill=accent)
        draw.polygon([(64, 46), (76, 68), (70, 92), (52, 92), (46, 70)], fill=(255, 118, 76, 255))
        draw.polygon([(62, 66), (70, 84), (62, 98), (54, 84)], fill=(255, 246, 170, 255))

    image.save(path)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for filename, spec in BADGES.items():
        draw_badge(OUT_DIR / filename, spec)


if __name__ == "__main__":
    main()
