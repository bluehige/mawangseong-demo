"""Prepare the final Silky and Popo Update 4 runtime assets."""

from __future__ import annotations

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
    write_sfx,
)


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = ROOT / "assets/source/imagegen/update4_contract_monsters"
MONSTER_ROOT = ROOT / "assets/sprites/monsters/update4"
PORTRAIT_ROOT = ROOT / "assets/sprites/portraits/update4"
EFFECT_ROOT = ROOT / "assets/sprites/effects/update4/contract_monsters"
SFX_ROOT = ROOT / "assets/audio/sfx/update4/contract_monsters"
PREVIEW_PATH = ROOT / "tmp/asset_previews/update4_contract_monsters.png"


CONFIGS: dict[str, dict[str, object]] = {
    "silky": {
        "runtime_id": "spider_tailor",
        "sheet": "silky_combat_sheet_chroma_2026-07-14.png",
        "portraits": "silky_portraits_chroma_2026-07-14.png",
        "idle": [_entry(box) for box in _grid_row(0, 300)[:2]],
        "move": [_entry(box) for box in _grid_row(0, 300)[2:] + _grid_row(270, 545)[:2]],
        "attack": [_entry(box) for box in _grid_row(520, 800)],
        "skill": [_entry(box) for box in _grid_row(775, 1045)],
        "down": [_entry(_grid_row(1015, 1254)[0]), _entry(_grid_row(1015, 1254)[2])],
        "effect_id": "silky_thread",
        "sfx": {"stitch": 440.0, "rescue": 659.25},
    },
    "popo": {
        "runtime_id": "bat_courier",
        "sheet": "popo_combat_sheet_chroma_2026-07-14.png",
        "portraits": "popo_portraits_chroma_2026-07-14.png",
        "idle": [_entry(box) for box in _grid_row(0, 305)[:2]],
        "move": [_entry(box) for box in _grid_row(0, 305)[2:] + _grid_row(280, 565)[:2]],
        "attack": [_entry(box) for box in _grid_row(535, 820)],
        "skill": [_entry(box) for box in _grid_row(785, 1050)],
        "down": [_entry((0, 1015, 620, 1254)), _entry((300, 1015, 1000, 1254))],
        "effect_id": "popo_relay",
        "sfx": {"relay": 587.33, "alarm": 783.99},
    },
}


def extract_portraits(path: Path) -> list[Image.Image]:
    sheet = remove_chroma(Image.open(path))
    portraits: list[Image.Image] = []
    for index in range(3):
        left = round(index * sheet.width / 3)
        right = round((index + 1) * sheet.width / 3)
        portraits.append(fit_visible(sheet.crop((left, 0, right, sheet.height)), (512, 512), 18, False))
    return portraits


def write_preview(entries: list[tuple[str, Image.Image, list[Image.Image]]]) -> None:
    cell = 112
    gap = 12
    row_height = cell * 2 + gap * 3
    preview = Image.new("RGBA", (gap + 12 * (cell + gap), gap + row_height * len(entries)), (24, 20, 31, 255))
    draw = ImageDraw.Draw(preview)
    for row, (species, atlas, portraits) in enumerate(entries):
        y = gap + row * row_height
        draw.text((gap, y + 4), species, fill=(242, 222, 175, 255))
        for index in range(16):
            frame = atlas.crop(((index % 4) * FRAME_SIZE, (index // 4) * FRAME_SIZE, (index % 4 + 1) * FRAME_SIZE, (index // 4 + 1) * FRAME_SIZE))
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
    for directory in [MONSTER_ROOT, PORTRAIT_ROOT, EFFECT_ROOT, SFX_ROOT]:
        directory.mkdir(parents=True, exist_ok=True)
    previews: list[tuple[str, Image.Image, list[Image.Image]]] = []
    for species, config in CONFIGS.items():
        source_dir = SOURCE_ROOT / species
        sheet = remove_chroma(Image.open(source_dir / str(config["sheet"])))
        frames = {
            state: [extract_frame(sheet, item) for item in config[state]]
            for state in ["idle", "move", "attack", "skill", "down"]
        }
        contract = {"idle": 2, "move": 4, "attack": 4, "skill": 4, "down": 2}
        if {state: len(values) for state, values in frames.items()} != contract:
            raise ValueError(f"{species}: 16-frame contract mismatch")
        atlas = assemble_atlas(frames)
        runtime_id = str(config["runtime_id"])
        atlas.save(MONSTER_ROOT / f"monster_{runtime_id}_sheet.png", optimize=True)
        portraits = extract_portraits(source_dir / str(config["portraits"]))
        for variant, portrait in zip(["base", "happy", "determined"], portraits, strict=True):
            portrait.save(PORTRAIT_ROOT / f"portrait_{runtime_id}_{variant}.png", optimize=True)
        effect_id = str(config["effect_id"])
        for index, item in enumerate(config["skill"]):
            extract_effect(sheet, item, index).save(EFFECT_ROOT / f"fx_{effect_id}_{index:02d}.png", optimize=True)
        for cue, frequency in config["sfx"].items():
            write_sfx(SFX_ROOT / f"sfx_{species}_{cue}.wav", float(frequency))
        previews.append((species, atlas, portraits))
        print(f"prepared {species}: 16 frames, 3 portraits, 4 VFX, 2 SFX")
    write_preview(previews)
    print(PREVIEW_PATH.relative_to(ROOT))


if __name__ == "__main__":
    main()
