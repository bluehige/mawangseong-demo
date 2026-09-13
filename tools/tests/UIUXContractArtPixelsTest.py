"""Read-only pixel/provenance checks for the four native contract atlases. Never edits PNGs."""
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PAIRS = {"stone_sentinel": "dolkong", "war_drummer": "dudum", "moon_tracker": "moon", "mimic_porter": "mimi"}
checks = 0


def expect(ok, label):
    global checks
    checks += 1
    assert ok, label


def main():
    catalog = json.loads((ROOT / "data/uiux_actor_art.json").read_text(encoding="utf8"))
    report = {}
    for unit, portrait in PAIRS.items():
        for relative in [f"assets/sprites/uiux3d/{unit}_sheet.png", f"assets/sprites/portraits/uiux3d/{portrait}_base.png"]:
            path = ROOT / relative
            original = ROOT / "assets/source/imagegen/uiux_contract_art_20260913" / path.name
            image = Image.open(path)
            expect(image.mode == "RGBA", relative + " native RGBA, no painted checkerboard")
            alpha = np.asarray(image)[:, :, 3]
            expect(max(alpha[0, 0], alpha[-1, -1], alpha[-1, 0], alpha[0, -1]) <= 1, relative + " corners transparent within one alpha quantum")
            expect(alpha.max() == 255 and (alpha == 0).mean() > .1, relative + " real foreground and transparent area")
            expect(min(image.size) >= 1024, relative + " original resolution retained")
            expect(hashlib.sha256(path.read_bytes()).digest() == hashlib.sha256(original.read_bytes()).digest(), relative + " source/runtime identical bytes")
            settings = Path(str(path) + ".import").read_text(encoding="utf8")
            expect(all(x in settings for x in ["compress/mode=0", "mipmaps/generate=true", "process/size_limit=0"]), relative + " lossless mipmap without shrinking")
        info = catalog[unit]
        alpha = np.asarray(Image.open(ROOT / info["path"].removeprefix("res://")))[:, :, 3]
        heights = []
        feet = []
        expect(len(info["regions"]) == len(info["margins"]) == len(info["visible_bounds"]) == 16, unit + " 16 frames")
        for index, (region, margin, visible) in enumerate(zip(info["regions"], info["margins"], info["visible_bounds"])):
            x, y, w, h = region
            expect(0 <= x < x+w <= alpha.shape[1] and 0 <= y < y+h <= alpha.shape[0], f"{unit}/{index} source bounds")
            expect(w + margin[2] == h + margin[3] == 384, f"{unit}/{index} logical frame")
            yy, xx = np.where(alpha[y:y+h, x:x+w] > 160)
            expect(len(xx) > 1000, f"{unit}/{index} actual opaque character pixels")
            actual = [xx.min()+margin[0], yy.min()+margin[1], xx.max()-xx.min()+1, yy.max()-yy.min()+1]
            vx, vy, vw, vh = visible
            expect(actual[0] >= vx and actual[1] >= vy and actual[0]+actual[2] <= vx+vw and actual[1]+actual[3] <= vy+vh, f"{unit}/{index} no opaque neighbor in halo")
            expect(0 <= actual[0] < actual[0]+actual[2] <= 384 and 0 <= actual[1] < actual[1]+actual[3] <= 384, f"{unit}/{index} body fits logical frame")
            if index < 4:
                foot = float(actual[1]+actual[3])
                feet.append(foot)
                expect(abs(foot-346) <= 3, f"{unit}/{index} idle/down actual pixel feet")
            if index < 2:
                heights.append(float(actual[3]))
        expect(abs(float(np.median(heights))-info["idle_height"]) <= 4, unit + " declared idle height follows actual pixels with two-pixel padding")
        if unit == "moon_tracker":
            expect(info["regions"][11][0] >= 964, "moon last attack excludes prior-frame arrow fragment")
        if unit == "war_drummer":
            expect(info["regions"][2][0] + info["regions"][2][2] <= 939, "drummer down excludes next-frame edge fragment")
        report[unit] = {"pixel_idle_heights": heights, "pixel_idle_down_feet": feet, "declared_idle_height": info["idle_height"]}
    print(json.dumps(report, ensure_ascii=False))
    print(f"UIUX_CONTRACT_ART_PIXELS_TEST: PASS ({checks} assertions)")


if __name__ == "__main__":
    main()
