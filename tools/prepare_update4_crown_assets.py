"""Build Update 4 crown runtime art and SFX from approved GPT image sources.

The generated source sheets intentionally stay versioned under
``assets/source/imagegen/update4_crowns``.  This tool performs only repeatable
local post-processing: chroma removal, framing, atlas assembly, portrait/VFX
extraction, and a short deterministic ascension cue for each crown form.
"""

from __future__ import annotations

import math
import struct
import wave
from hashlib import sha256
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = ROOT / "assets/source/imagegen/update4_crowns"
MONSTER_ROOT = ROOT / "assets/sprites/monsters/update4/crowns"
PORTRAIT_ROOT = ROOT / "assets/sprites/portraits/update4/crowns"
EFFECT_ROOT = ROOT / "assets/sprites/effects/update4/crowns"
SFX_ROOT = ROOT / "assets/audio/sfx/update4/crowns"
PREVIEW_PATH = ROOT / "tmp/asset_previews/update4_crown_assets.png"

FRAME_SIZE = 192
PORTRAIT_SIZE = 512
EFFECT_SIZE = 256

try:
    RESAMPLE = Image.Resampling.LANCZOS
except AttributeError:  # Pillow < 9.1
    RESAMPLE = Image.LANCZOS


def _grid_row(y0: int, y1: int) -> list[tuple[int, int, int, int]]:
    edges = [0, 314, 627, 941, 1254]
    return [(edges[index], y0, edges[index + 1], y1) for index in range(4)]


def _entry(box: tuple[int, int, int, int], flip: bool = False) -> dict[str, object]:
    return {"box": box, "flip": flip}


CONFIGS: dict[str, dict[str, object]] = {
    "pudding": {
        "runtime_id": "slime_crown_bastion",
        "sheet": "crown_pudding_combat_sheet_chroma_2026-07-14.png",
        "portraits": "crown_pudding_portraits_chroma_2026-07-14.png",
        "idle": [_entry(box) for box in _grid_row(0, 300)[:2]],
        "move": [_entry(box) for box in _grid_row(0, 300)[2:] + _grid_row(285, 570)[:2]],
        "attack": [_entry(box) for box in _grid_row(555, 835)],
        "skill": [_entry(box) for box in _grid_row(815, 1070)],
        "down": [_entry((180, 1080, 650, 1254)), _entry((610, 1080, 1100, 1254))],
        "tone": 392.0,
    },
    "gob": {
        "runtime_id": "goblin_crown_marshal",
        "sheet": "crown_gob_combat_sheet_chroma_2026-07-14.png",
        "portraits": "crown_gob_portraits_chroma_2026-07-14.png",
        "idle": [_entry(box) for box in _grid_row(0, 305)[:2]],
        "move": [_entry(box) for box in _grid_row(0, 305)[2:]]
        + [_entry((0, 280, 315, 585)), _entry((285, 280, 625, 585))],
        "attack": [_entry(box) for box in _grid_row(535, 820)],
        "skill": [_entry(box) for box in _grid_row(785, 1050)],
        "down": [_entry((205, 1070, 660, 1254)), _entry((590, 1070, 1035, 1254))],
        "tone": 329.63,
    },
    "pynn": {
        "runtime_id": "imp_crown_flame_sage",
        "sheet": "crown_pynn_combat_sheet_chroma_2026-07-14.png",
        "portraits": "crown_pynn_portraits_chroma_2026-07-14.png",
        "idle": [_entry(box) for box in _grid_row(0, 325)[:2]],
        "move": [_entry(box) for box in _grid_row(0, 325)[2:]]
        + [_entry(_grid_row(300, 635)[0], True), _entry(_grid_row(300, 635)[3], True)],
        "attack": [_entry(box) for box in _grid_row(300, 635)],
        "skill": [_entry(box) for box in _grid_row(600, 975)],
        "down": [_entry((90, 950, 620, 1254)), _entry((575, 950, 1160, 1254))],
        "tone": 523.25,
    },
    "mori": {
        "runtime_id": "mori_crown_priest",
        "sheet": "crown_mori_combat_sheet_chroma_2026-07-14.png",
        "portraits": "crown_mori_portraits_chroma_2026-07-14.png",
        "idle": [_entry(box) for box in _grid_row(0, 300)[:2]],
        "move": [_entry(box) for box in _grid_row(0, 300)[2:] + _grid_row(275, 565)[:2]],
        "attack": [_entry(box) for box in _grid_row(535, 810)],
        "skill": [_entry(box) for box in _grid_row(775, 1055)],
        "down": [_entry((95, 1065, 520, 1254)), _entry((430, 1065, 1050, 1254))],
        "tone": 440.0,
    },
    "toktok": {
        "runtime_id": "toktok_crown_armorer",
        "sheet": "crown_toktok_combat_sheet_chroma_2026-07-14.png",
        "portraits": "crown_toktok_portraits_chroma_2026-07-14.png",
        "idle": [_entry(box) for box in _grid_row(0, 315)[:2]],
        "move": [_entry(box) for box in _grid_row(0, 315)[2:] + _grid_row(295, 630)[:2]],
        "attack": [_entry(box) for box in _grid_row(295, 630)[2:] + _grid_row(605, 945)[:2]],
        "skill": [_entry(box) for box in _grid_row(605, 945)[2:] + _grid_row(915, 1254)[:2]],
        "down": [_entry(box) for box in _grid_row(915, 1254)[2:]],
        "tone": 261.63,
    },
    "popo": {
        "runtime_id": "popo_crown_courier",
        "sheet": "crown_popo_combat_sheet_chroma_2026-07-14.png",
        "portraits": "crown_popo_portraits_chroma_2026-07-14.png",
        "idle": [_entry(box) for box in _grid_row(0, 310)[:2]],
        "move": [_entry(box) for box in _grid_row(0, 310)[2:] + _grid_row(285, 575)[:2]],
        "attack": [_entry(box) for box in _grid_row(545, 825)],
        "skill": [_entry(box) for box in _grid_row(790, 1060)],
        "down": [_entry((0, 1015, 610, 1254)), _entry((285, 1015, 960, 1254))],
        "tone": 587.33,
    },
}


def remove_chroma(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    output: list[tuple[int, int, int, int]] = []
    pixels = rgba.get_flattened_data() if hasattr(rgba, "get_flattened_data") else rgba.getdata()
    for red, green, blue, _ in pixels:
        dominance = green - max(red, blue)
        if green >= 185 and dominance >= 92 and green >= red * 1.75 and green >= blue * 1.75:
            alpha = 0
        elif green >= 145 and dominance >= 75 and green >= red * 1.55 and green >= blue * 1.55:
            alpha = max(0, min(255, int((185 - green) * 6.4)))
        else:
            alpha = 255
        output.append((red, green, blue, alpha))
    rgba.putdata(output)
    alpha = rgba.getchannel("A").filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.55))
    rgba.putalpha(alpha.point(lambda value: 0 if value < 10 else value))
    return rgba


def fit_visible(image: Image.Image, size: tuple[int, int], padding: int, bottom_align: bool = True) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("crop contains no visible subject")
    subject = image.crop(bbox)
    subject.thumbnail((size[0] - padding * 2, size[1] - padding * 2), RESAMPLE)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    x = (size[0] - subject.width) // 2
    y = size[1] - padding - subject.height if bottom_align else (size[1] - subject.height) // 2
    canvas.alpha_composite(subject, (x, y))
    return canvas


def extract_frame(sheet: Image.Image, item: dict[str, object]) -> Image.Image:
    frame = sheet.crop(item["box"])
    if bool(item.get("flip", False)):
        frame = ImageOps.mirror(frame)
    return fit_visible(frame, (FRAME_SIZE, FRAME_SIZE), 9)


def assemble_atlas(frames: dict[str, list[Image.Image]]) -> Image.Image:
    atlas = Image.new("RGBA", (FRAME_SIZE * 4, FRAME_SIZE * 4), (0, 0, 0, 0))
    # Unit.gd's runtime sheet contract: idle/down, move, attack, skill.
    ordered = frames["idle"] + frames["down"] + frames["move"] + frames["attack"] + frames["skill"]
    if len(ordered) != 16:
        raise ValueError(f"expected 16 frames, got {len(ordered)}")
    hashes: set[str] = set()
    for index, frame in enumerate(ordered):
        digest = sha256(frame.tobytes()).hexdigest()
        if digest in hashes:
            raise ValueError(f"duplicate runtime frame at index {index}")
        hashes.add(digest)
        atlas.alpha_composite(frame, ((index % 4) * FRAME_SIZE, (index // 4) * FRAME_SIZE))
    return atlas


def extract_portraits(path: Path) -> list[Image.Image]:
    sheet = remove_chroma(Image.open(path))
    portraits: list[Image.Image] = []
    for index in range(2):
        left = round(index * sheet.width / 2)
        right = round((index + 1) * sheet.width / 2)
        portraits.append(fit_visible(sheet.crop((left, 0, right, sheet.height)), (PORTRAIT_SIZE, PORTRAIT_SIZE), 18, False))
    return portraits


def extract_effect(sheet: Image.Image, item: dict[str, object], frame_index: int) -> Image.Image:
    effect = sheet.crop(item["box"])
    if bool(item.get("flip", False)):
        effect = ImageOps.mirror(effect)
    alpha = effect.getchannel("A")
    suppress = Image.new("L", effect.size, 255)
    draw = ImageDraw.Draw(suppress)
    inset_x = int(effect.width * (0.28 + frame_index * 0.015))
    draw.ellipse((inset_x, int(effect.height * 0.20), effect.width - inset_x, int(effect.height * 0.91)), fill=42)
    effect.putalpha(Image.composite(alpha, Image.new("L", effect.size, 0), suppress))
    return fit_visible(effect, (EFFECT_SIZE, EFFECT_SIZE), 8, False)


def write_sfx(path: Path, base_frequency: float) -> None:
    sample_rate = 22_050
    duration = 0.42
    frame_count = int(sample_rate * duration)
    samples = bytearray()
    for index in range(frame_count):
        time = index / sample_rate
        attack = min(1.0, time / 0.035)
        release = max(0.0, min(1.0, (duration - time) / 0.16))
        envelope = attack * release
        shimmer = 0.54 * math.sin(2.0 * math.pi * base_frequency * time)
        shimmer += 0.30 * math.sin(2.0 * math.pi * base_frequency * 1.5 * time)
        shimmer += 0.16 * math.sin(2.0 * math.pi * base_frequency * 2.0 * time)
        sample = int(max(-1.0, min(1.0, shimmer * envelope * 0.42)) * 32767)
        samples.extend(struct.pack("<h", sample))
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)
        wav.writeframes(samples)


def transparent_corners(image: Image.Image) -> bool:
    points = [(0, 0), (image.width - 1, 0), (0, image.height - 1), (image.width - 1, image.height - 1)]
    return all(image.getpixel(point)[3] == 0 for point in points)


def write_preview(assets: list[tuple[str, Image.Image, list[Image.Image]]]) -> None:
    cell = 96
    gap = 12
    width = gap + 10 * (cell + gap)
    row_height = cell * 2 + gap * 3
    height = gap + len(assets) * row_height
    preview = Image.new("RGBA", (width, height), (25, 21, 32, 255))
    draw = ImageDraw.Draw(preview)
    for row, (species, atlas, portraits) in enumerate(assets):
        y = gap + row * row_height
        draw.text((gap, y + 4), species, fill=(242, 222, 175, 255))
        frames = [
            atlas.crop(
                (
                    (index % 4) * FRAME_SIZE,
                    (index // 4) * FRAME_SIZE,
                    (index % 4 + 1) * FRAME_SIZE,
                    (index // 4 + 1) * FRAME_SIZE,
                )
            )
            for index in range(16)
        ]
        for index, image in enumerate(frames):
            thumb = image.copy()
            thumb.thumbnail((cell, cell), RESAMPLE)
            x = gap + (index % 8 + 1) * (cell + gap) + (cell - thumb.width) // 2
            frame_y = y + (index // 8) * (cell + gap) + (cell - thumb.height) // 2
            preview.alpha_composite(thumb, (x, frame_y))
        for index, image in enumerate(portraits):
            thumb = image.copy()
            thumb.thumbnail((cell, cell), RESAMPLE)
            x = gap + 9 * (cell + gap) + (cell - thumb.width) // 2
            frame_y = y + index * (cell + gap) + (cell - thumb.height) // 2
            preview.alpha_composite(thumb, (x, frame_y))
    PREVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)
    preview.convert("RGB").save(PREVIEW_PATH, quality=94)


def main() -> None:
    for directory in [MONSTER_ROOT, PORTRAIT_ROOT, EFFECT_ROOT, SFX_ROOT]:
        directory.mkdir(parents=True, exist_ok=True)
    preview_assets: list[tuple[str, Image.Image, list[Image.Image]]] = []
    for species, config in CONFIGS.items():
        source_dir = SOURCE_ROOT / species
        source_path = source_dir / str(config["sheet"])
        portrait_path = source_dir / str(config["portraits"])
        if not source_path.exists() or not portrait_path.exists():
            raise FileNotFoundError(f"missing source art for {species}")
        sheet = remove_chroma(Image.open(source_path))
        frames = {
            state: [extract_frame(sheet, item) for item in config[state]]
            for state in ["idle", "move", "attack", "skill", "down"]
        }
        expected = {"idle": 2, "move": 4, "attack": 4, "skill": 4, "down": 2}
        if {state: len(values) for state, values in frames.items()} != expected:
            raise ValueError(f"{species}: frame contract mismatch")
        atlas = assemble_atlas(frames)
        runtime_id = str(config["runtime_id"])
        atlas_path = MONSTER_ROOT / f"monster_{runtime_id}_sheet.png"
        atlas.save(atlas_path, optimize=True)
        portraits = extract_portraits(portrait_path)
        for variant, portrait in zip(["council", "victory"], portraits, strict=True):
            portrait.save(PORTRAIT_ROOT / f"portrait_{runtime_id}_{variant}.png", optimize=True)
        for index, item in enumerate(config["skill"]):
            effect = extract_effect(sheet, item, index)
            effect.save(EFFECT_ROOT / f"fx_{runtime_id}_crown_{index:02d}.png", optimize=True)
        write_sfx(SFX_ROOT / f"sfx_crown_{species}_ascend.wav", float(config["tone"]))
        if not transparent_corners(atlas):
            raise ValueError(f"{species}: runtime atlas has an opaque outer corner")
        preview_assets.append((species, atlas, portraits))
        print(f"prepared {species}: 16 frames, 2 portraits, 4 VFX, 1 SFX")
    write_preview(preview_assets)
    print(PREVIEW_PATH.relative_to(ROOT))


if __name__ == "__main__":
    main()
