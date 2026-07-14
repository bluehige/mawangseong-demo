"""Prepare Update 4 rival boss presentation assets from GPT image sources."""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

from PIL import Image, ImageDraw

from prepare_update4_crown_assets import (
    FRAME_SIZE,
    RESAMPLE,
    _entry,
    _grid_row,
    assemble_atlas,
    extract_effect,
    extract_frame,
    fit_visible,
    remove_chroma,
)


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = ROOT / "assets/source/imagegen/update4_rivals"
BOSS_ROOT = ROOT / "assets/sprites/enemies/update4/rivals"
PORTRAIT_ROOT = ROOT / "assets/sprites/portraits/update4/rivals"
EFFECT_ROOT = ROOT / "assets/sprites/effects/update4/rivals"
MOTIF_ROOT = ROOT / "assets/audio/music/update4/rivals"
PREVIEW_PATH = ROOT / "tmp/asset_previews/update4_rivals.png"

CONFIGS: dict[str, dict[str, object]] = {
    "brassa": {
        "boss_id": "rival_brassa_council_champion",
        "combat": "brassa_combat_sheet_chroma_2026-07-14.png",
        "portraits": "brassa_portraits_chroma_2026-07-14.png",
        "tones": [196.0, 246.94, 293.66, 392.0],
    },
    "vesper": {
        "boss_id": "rival_vesper_council_champion",
        "combat": "vesper_combat_sheet_chroma_2026-07-14.png",
        "portraits": "vesper_portraits_chroma_2026-07-14.png",
        "tones": [293.66, 369.99, 440.0, 587.33],
    },
    "mirella": {
        "boss_id": "rival_mirella_council_champion",
        "combat": "mirella_combat_sheet_chroma_2026-07-14.png",
        "portraits": "mirella_portraits_chroma_2026-07-14.png",
        "tones": [220.0, 261.63, 329.63, 392.0],
    },
}


def extract_portraits(path: Path) -> list[Image.Image]:
    sheet = remove_chroma(Image.open(path))
    portraits: list[Image.Image] = []
    for row in range(2):
        for column in range(2):
            box = (
                round(column * sheet.width / 2),
                round(row * sheet.height / 2),
                round((column + 1) * sheet.width / 2),
                round((row + 1) * sheet.height / 2),
            )
            portraits.append(fit_visible(sheet.crop(box), (512, 512), 18, False))
    return portraits


def write_motif(path: Path, tones: list[float]) -> None:
    sample_rate = 22_050
    note_duration = 0.34
    tail = 0.22
    duration = len(tones) * note_duration + tail
    samples = bytearray()
    for index in range(int(sample_rate * duration)):
        time = index / sample_rate
        note_index = min(len(tones) - 1, int(time / note_duration))
        local_time = time - note_index * note_duration
        frequency = tones[note_index]
        attack = min(1.0, local_time / 0.025)
        release = max(0.0, min(1.0, (note_duration + tail - local_time) / 0.24))
        envelope = attack * release
        value = 0.58 * math.sin(2.0 * math.pi * frequency * local_time)
        value += 0.27 * math.sin(2.0 * math.pi * frequency * 1.5 * local_time)
        value += 0.15 * math.sin(2.0 * math.pi * frequency * 2.0 * local_time)
        sample = int(max(-1.0, min(1.0, value * envelope * 0.38)) * 32767)
        samples.extend(struct.pack("<h", sample))
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)
        wav.writeframes(samples)


def write_preview(entries: list[tuple[str, Image.Image, list[Image.Image]]]) -> None:
    cell = 104
    gap = 12
    row_height = cell * 2 + gap * 3
    preview = Image.new("RGBA", (gap + 13 * (cell + gap), gap + row_height * len(entries)), (23, 19, 30, 255))
    draw = ImageDraw.Draw(preview)
    for row, (rival_id, atlas, portraits) in enumerate(entries):
        y = gap + row * row_height
        draw.text((gap, y + 4), rival_id, fill=(242, 222, 175, 255))
        for index in range(16):
            frame = atlas.crop(((index % 4) * 192, (index // 4) * 192, (index % 4 + 1) * 192, (index // 4 + 1) * 192))
            frame.thumbnail((cell, cell), RESAMPLE)
            x = gap + (index % 8 + 1) * (cell + gap) + (cell - frame.width) // 2
            frame_y = y + (index // 8) * (cell + gap) + (cell - frame.height) // 2
            preview.alpha_composite(frame, (x, frame_y))
        for index, portrait in enumerate(portraits):
            thumb = portrait.copy()
            thumb.thumbnail((cell, cell), RESAMPLE)
            x = gap + (9 + index) * (cell + gap) + (cell - thumb.width) // 2
            frame_y = y + (cell - thumb.height) // 2
            preview.alpha_composite(thumb, (x, frame_y))
    PREVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)
    preview.convert("RGB").save(PREVIEW_PATH, quality=94)


def main() -> None:
    for directory in [BOSS_ROOT, PORTRAIT_ROOT, EFFECT_ROOT, MOTIF_ROOT]:
        directory.mkdir(parents=True, exist_ok=True)
    previews: list[tuple[str, Image.Image, list[Image.Image]]] = []
    for rival_id, config in CONFIGS.items():
        source_dir = SOURCE_ROOT / rival_id
        sheet = remove_chroma(Image.open(source_dir / str(config["combat"])))
        first_row = _grid_row(0, 314)
        frames = {
            "idle": [extract_frame(sheet, _entry(box)) for box in first_row[:2]],
            "down": [extract_frame(sheet, _entry(box)) for box in first_row[2:]],
            "move": [extract_frame(sheet, _entry(box)) for box in _grid_row(314, 627)],
            "attack": [extract_frame(sheet, _entry(box)) for box in _grid_row(627, 941)],
            "skill": [extract_frame(sheet, _entry(box)) for box in _grid_row(941, 1254)],
        }
        atlas = assemble_atlas(frames)
        boss_id = str(config["boss_id"])
        atlas.save(BOSS_ROOT / f"enemy_{boss_id}_sheet.png", optimize=True)
        portraits = extract_portraits(source_dir / str(config["portraits"]))
        for variant, portrait in zip(["council", "respect", "challenge", "victory"], portraits, strict=True):
            portrait.save(PORTRAIT_ROOT / f"portrait_{rival_id}_{variant}.png", optimize=True)
        for index, box in enumerate(_grid_row(941, 1254)):
            extract_effect(sheet, _entry(box), index).save(EFFECT_ROOT / f"fx_{rival_id}_boss_{index:02d}.png", optimize=True)
        write_motif(MOTIF_ROOT / f"boss_{rival_id}_motif.wav", list(config["tones"]))
        previews.append((rival_id, atlas, portraits))
        print(f"prepared {rival_id}: 16 frames, 4 portraits, 4 VFX, 1 motif")
    write_preview(previews)
    print(PREVIEW_PATH.relative_to(ROOT))


if __name__ == "__main__":
    main()
