"""One side-by-side sheet: untouched Style B reference and four actual pages."""
import sys
import json
from pathlib import Path
from PIL import Image, ImageDraw


def main():
    directory = Path(sys.argv[1])
    reference = Path("docs/design/v1213_uiux/kit/kit_B_cute_dark.png")
    sheet = Image.new("RGB", (2400, 1420), "#100c19")
    draw = ImageDraw.Draw(sheet)
    draw.text((24, 16), "STYLE B REFERENCE (unchanged)", fill="#ffe4a0")
    draw.text((1220, 16), "GODOT 4.6.3 / ko / 1920x1080 / content crops / placeholders", fill="#ffe4a0")
    source = Image.open(reference).convert("RGB")
    source.thumbnail((1160, 1360))
    sheet.paste(source, (24, 55 + (1320-source.height)//2))
    for page in range(1, 5):
        rendered = Image.open(directory / f"1920x1080_desktop_ko_p{page}_0.png").convert("RGB")
        measurement = json.loads((directory / f"1920x1080_desktop_ko_p{page}_0.json").read_text(encoding="utf-8"))
        leaves = [r for r in measurement["controls"] if r["type"] in ("Label", "Button", "OptionButton", "CheckBox", "ProgressBar", "TextureRect", "HSlider")]
        bottom = min(rendered.height, int(max(r["rect"][1] + r["rect"][3] for r in leaves)) + 24)
        rendered = rendered.crop((0, 0, rendered.width, bottom))
        rendered.thumbnail((1150, 300))
        y = 60 + (page-1)*335
        draw.text((1220, y-20), ["Actions / resources / tabs / dock", "Card / HP / EXP / chips", "Tooltip / modal / toast", "Drawer / native controls"][page-1], fill="#d0bddc")
        sheet.paste(rendered, (1220, y))
    destination = directory / "kit_B_comparison.png"
    sheet.save(destination)
    print(destination)


if __name__ == "__main__":
    main()
