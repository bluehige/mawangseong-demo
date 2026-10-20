"""Join actual Godot captures and check flat terrain/monster cells against dumps."""
import argparse
import json
from pathlib import Path

from PIL import Image


def audit(out: Path) -> dict:
    images = [Image.open(out / f"defense_{name}.png").convert("RGB") for name in ("ga", "na")]
    if any(image.size != (1920, 1080) for image in images):
        raise ValueError("Expected two actual 1920x1080 management captures")
    combined = Image.new("RGB", (3840, 1080))
    for index, image in enumerate(images):
        combined.paste(image, (index * 1920, 0))
    combined.save(out / "compare_ga_na.png")
    colors = {".": (222, 223, 224), "=": (213, 196, 157), "~": (150, 89, 64), "B": (114, 172, 180)}
    report = {}
    for name, image, cell, grid_x in [("ga", images[0], 44, 282), ("na", images[1], 40, 78)]:
        lines = (out / f"defense_{name}.txt").read_text(encoding="utf8").splitlines()
        grid = [line[3:] for line in lines if len(line) > 3 and line[:2].isdigit() and line[2] == " "]
        expected_size = (18, 16) if name == "ga" else (30, 18)
        if len(grid) != expected_size[1] or any(len(row) != expected_size[0] for row in grid):
            raise ValueError(f"Invalid grid dump: {name}")
        checked, monsters, errors = 0, 0, []
        for y, line in enumerate(grid):
            for x, token in enumerate(line):
                if token not in colors and token != "M":
                    continue
                crop = image.crop((grid_x + x * cell + 5, 220 + y * cell + 5,
                                   grid_x + (x + 1) * cell - 5, 220 + (y + 1) * cell - 5))
                hist = {rgb: count for count, rgb in crop.getcolors(crop.width * crop.height)}
                if token == "M":
                    monsters += 1
                    targets = [tuple(round(base[i] * .55 + (.81, .16, .22)[i] * 255 * .45)
                                     for i in range(3)) for base in (colors["."], colors["="])]
                    matches = sum(count for rgb, count in hist.items()
                                  if any(max(abs(rgb[i] - target[i]) for i in range(3)) <= 2 for target in targets))
                else:
                    matches = hist.get(colors[token], 0)
                checked += 1
                if matches < crop.width * crop.height * .5:
                    errors.append({"x": x, "y": y, "token": token, "match_pixels": matches})
        report[name] = {"resolution": image.size, "checked_cells": checked, "monster_cells": monsters, "errors": errors}
    report["compare_resolution"] = combined.size
    (out / "capture_audit.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf8")
    return report


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, default=Path("C:/Users/blueh/Desktop/진행중인프로젝트/_mockup/graybox2"))
    result = audit(parser.parse_args().out)
    print(json.dumps(result, ensure_ascii=False))
    raise SystemExit(1 if any(result[name]["errors"] for name in ("ga", "na")) else 0)
