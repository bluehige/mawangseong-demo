"""Slice approved 4x4 evolution sheets into 192px runtime combat frames."""

from __future__ import annotations

from hashlib import sha256
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets" / "source" / "imagegen" / "evolutions"
OUTPUT_DIR = ROOT / "assets" / "sprites" / "monsters"
EFFECT_DIR = ROOT / "assets" / "sprites" / "effects"
PREVIEW_PATH = ROOT / "tmp" / "asset_previews" / "evolution_combat_sequences.png"
VFX_PREVIEW_PATH = ROOT / "tmp" / "asset_previews" / "evolution_vfx_sequences.png"
SIZE = 192

SHEETS = {
    "slime_gate_bulwark": SOURCE_DIR / "sheet_slime_gate_bulwark_4x4_alpha.png",
    "slime_rescue_alchemy_gel": SOURCE_DIR / "sheet_slime_rescue_alchemy_gel_4x4_alpha.png",
    "goblin_ambush_captain": SOURCE_DIR / "sheet_goblin_ambush_captain_4x4_alpha.png",
    "goblin_vault_keeper": SOURCE_DIR / "sheet_goblin_vault_keeper_4x4_alpha.png",
    "imp_flame_adept": SOURCE_DIR / "sheet_imp_flame_adept_4x4_alpha.png",
    "imp_ember_shaman": SOURCE_DIR / "sheet_imp_ember_shaman_4x4_alpha.png",
}

VFX_SHEETS = {
    "fx_slime_gate_bulwark": SOURCE_DIR / "vfx_slime_gate_bulwark_2x2_alpha.png",
    "fx_slime_rescue_alchemy": SOURCE_DIR / "vfx_slime_rescue_alchemy_2x2_alpha.png",
    "fx_goblin_ambush_captain": SOURCE_DIR / "vfx_goblin_ambush_captain_2x2_alpha.png",
    "fx_goblin_vault_keeper": SOURCE_DIR / "vfx_goblin_vault_keeper_2x2_alpha.png",
    "fx_imp_flame_adept": SOURCE_DIR / "vfx_imp_flame_adept_2x2_alpha.png",
    "fx_imp_ember_shaman": SOURCE_DIR / "vfx_imp_ember_shaman_2x2_alpha.png",
}

# Cell order is fixed by the generation prompt, left-to-right and top-to-bottom.
CELL_SEQUENCE = [
    ("idle_down", 0),
    ("idle_down", 1),
    ("move_down", 0),
    ("move_down", 1),
    ("move_down", 2),
    ("move_down", 3),
    ("attack_down", 0),
    ("attack_down", 1),
    ("attack_down", 2),
    ("attack_down", 3),
    ("skill_down", 0),
    ("skill_down", 1),
    ("skill_down", 2),
    ("skill_down", 3),
    ("down", 0),
    ("down", 1),
]

try:
    RESAMPLE = Image.Resampling.LANCZOS
except AttributeError:
    RESAMPLE = Image.LANCZOS


def _checkerboard(size: tuple[int, int], block: int = 12) -> Image.Image:
    image = Image.new("RGBA", size, (24, 21, 30, 255))
    draw = ImageDraw.Draw(image)
    for y in range(0, size[1], block):
        for x in range(0, size[0], block):
            if (x // block + y // block) % 2 == 0:
                draw.rectangle((x, y, x + block - 1, y + block - 1), fill=(38, 34, 45, 255))
    return image


def _slice_sheet(sheet_path: Path) -> list[Image.Image]:
    sheet = Image.open(sheet_path).convert("RGBA")
    if abs(sheet.width - sheet.height) > 2:
        raise ValueError(f"{sheet_path.name}: expected a square 4x4 sheet, got {sheet.size}")

    frames: list[Image.Image] = []
    hashes: set[str] = set()
    for cell_index in range(16):
        column = cell_index % 4
        row = cell_index // 4
        left = round(column * sheet.width / 4)
        top = round(row * sheet.height / 4)
        right = round((column + 1) * sheet.width / 4)
        bottom = round((row + 1) * sheet.height / 4)
        frame = sheet.crop(
            (left, top, right, bottom)
        ).resize((SIZE, SIZE), RESAMPLE)
        alpha = frame.getchannel("A").point(lambda value: 0 if value <= 8 else value)
        frame.putalpha(alpha)
        bbox = alpha.getbbox()
        if bbox is None:
            raise ValueError(f"{sheet_path.name}: cell {cell_index} is transparent")
        if any(frame.getpixel(point)[3] != 0 for point in [(0, 0), (SIZE - 1, 0), (0, SIZE - 1), (SIZE - 1, SIZE - 1)]):
            raise ValueError(f"{sheet_path.name}: cell {cell_index} has a non-transparent corner")
        digest = sha256(frame.tobytes()).hexdigest()
        if digest in hashes:
            raise ValueError(f"{sheet_path.name}: duplicate frame at cell {cell_index}")
        hashes.add(digest)
        frames.append(frame)
    return frames


def _write_preview(all_frames: dict[str, list[Image.Image]]) -> None:
    gap = 12
    label_height = 30
    row_height = label_height + (SIZE + gap) * 2
    canvas = _checkerboard((gap + (SIZE + gap) * 8, gap + row_height * len(all_frames)))
    draw = ImageDraw.Draw(canvas)
    for row, (evolution_id, frames) in enumerate(all_frames.items()):
        top = gap + row * row_height
        draw.text((gap, top), evolution_id, fill=(242, 222, 175, 255))
        for index, frame in enumerate(frames):
            x = gap + (index % 8) * (SIZE + gap)
            y = top + label_height + (index // 8) * (SIZE + gap)
            canvas.alpha_composite(frame, (x, y))
    PREVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(PREVIEW_PATH, quality=94)


def _slice_vfx_sheet(sheet_path: Path) -> list[Image.Image]:
    sheet = Image.open(sheet_path).convert("RGBA")
    if abs(sheet.width - sheet.height) > 2:
        raise ValueError(f"{sheet_path.name}: expected a square 2x2 sheet, got {sheet.size}")
    frames: list[Image.Image] = []
    for index in range(4):
        column = index % 2
        row = index // 2
        left = round(column * sheet.width / 2)
        top = round(row * sheet.height / 2)
        right = round((column + 1) * sheet.width / 2)
        bottom = round((row + 1) * sheet.height / 2)
        frame = sheet.crop((left, top, right, bottom)).resize((SIZE, SIZE), RESAMPLE)
        alpha = frame.getchannel("A").point(lambda value: 0 if value <= 8 else value)
        frame.putalpha(alpha)
        if alpha.getbbox() is None:
            raise ValueError(f"{sheet_path.name}: cell {index} is transparent")
        frames.append(frame)
    return frames


def _write_vfx_preview(all_frames: dict[str, list[Image.Image]]) -> None:
    gap = 16
    label_width = 240
    canvas = _checkerboard((label_width + (SIZE + gap) * 4, gap + (SIZE + gap) * len(all_frames)))
    draw = ImageDraw.Draw(canvas)
    for row, (effect_id, frames) in enumerate(all_frames.items()):
        y = gap + row * (SIZE + gap)
        draw.text((12, y + SIZE // 2 - 8), effect_id, fill=(242, 222, 175, 255))
        for column, frame in enumerate(frames):
            canvas.alpha_composite(frame, (label_width + column * (SIZE + gap), y))
    VFX_PREVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(VFX_PREVIEW_PATH, quality=94)


def main() -> None:
    missing = [str(path) for path in list(SHEETS.values()) + list(VFX_SHEETS.values()) if not path.exists()]
    if missing:
        raise FileNotFoundError("Missing alpha evolution sheets:\n" + "\n".join(missing))

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    all_frames: dict[str, list[Image.Image]] = {}
    for evolution_id, sheet_path in SHEETS.items():
        frames = _slice_sheet(sheet_path)
        all_frames[evolution_id] = frames
        for frame, (animation, animation_index) in zip(frames, CELL_SEQUENCE, strict=True):
            output = OUTPUT_DIR / f"monster_{evolution_id}_{animation}_{animation_index:02d}.png"
            frame.save(output, optimize=True)
            print(f"{output.relative_to(ROOT)}: bbox={frame.getchannel('A').getbbox()}")

    _write_preview(all_frames)
    print(PREVIEW_PATH.relative_to(ROOT))

    EFFECT_DIR.mkdir(parents=True, exist_ok=True)
    all_vfx_frames: dict[str, list[Image.Image]] = {}
    for effect_id, sheet_path in VFX_SHEETS.items():
        frames = _slice_vfx_sheet(sheet_path)
        all_vfx_frames[effect_id] = frames
        for index, frame in enumerate(frames):
            output = EFFECT_DIR / f"{effect_id}_{index:02d}.png"
            frame.save(output, optimize=True)
            print(f"{output.relative_to(ROOT)}: bbox={frame.getchannel('A').getbbox()}")
    _write_vfx_preview(all_vfx_frames)
    print(VFX_PREVIEW_PATH.relative_to(ROOT))


if __name__ == "__main__":
    main()
