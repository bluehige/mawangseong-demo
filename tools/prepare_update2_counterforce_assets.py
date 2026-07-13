from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets" / "source" / "imagegen" / "update2_counterforce"
OUTPUT_DIR = ROOT / "assets" / "sprites" / "enemies"
PORTRAIT_DIR = ROOT / "assets" / "sprites" / "portraits" / "enemies"
PREVIEW_PATH = ROOT / "tmp" / "asset_previews" / "update2_counterforce_animation_sequences.png"
SIZE = 192
GRID_COLUMNS = 4
GRID_ROWS = 2

UNIT_IDS = [
    "royal_scout",
    "monster_binder",
    "ward_breaker",
    "supply_raider",
    "anti_magic_archer",
    "royal_field_medic",
    "royal_strategist_evelyn",
]

SOURCES = {
    "idle_down": SOURCE_DIR / "counterforce_idle_sheet_4x2_alpha.png",
    "move_down": SOURCE_DIR / "counterforce_move_sheet_4x2_alpha.png",
    "attack_down": SOURCE_DIR / "counterforce_attack_sheet_4x2_alpha.png",
    "skill_down": SOURCE_DIR / "counterforce_skill_sheet_4x2_alpha.png",
    "down": SOURCE_DIR / "counterforce_down_sheet_4x2_alpha.png",
}

VARIANTS = {
    "idle_down": [(0, 1, 1.0, 0.0), (0, 0, 0.985, 0.0)],
    "move_down": [(-3, 2, 0.99, -1.5), (0, -2, 1.0, 0.0), (3, 2, 0.99, 1.5), (0, 0, 1.0, 0.0)],
    "attack_down": [(-4, 2, 0.96, -1.0), (-1, 0, 1.0, 0.0), (4, -2, 1.035, 1.0), (1, 0, 1.0, 0.0)],
    "skill_down": [(0, 2, 0.97, 0.0), (-2, 0, 1.0, -0.8), (2, -2, 1.025, 0.8), (0, 0, 1.0, 0.0)],
    "down": [(0, 0, 1.0, 0.0), (0, 2, 0.985, 0.0)],
}

try:
    RESAMPLE = Image.Resampling.LANCZOS
    ROTATE_RESAMPLE = Image.Resampling.BICUBIC
except AttributeError:
    RESAMPLE = Image.LANCZOS
    ROTATE_RESAMPLE = Image.BICUBIC


def split_sheet(path: Path) -> list[Image.Image]:
    sheet = Image.open(path).convert("RGBA")
    if sheet.width % GRID_COLUMNS or sheet.height % GRID_ROWS:
        raise ValueError(f"{path.name}: expected an exact 4x2 grid, got {sheet.size}")
    cell_width = sheet.width // GRID_COLUMNS
    cell_height = sheet.height // GRID_ROWS
    cells: list[Image.Image] = []
    for index in range(len(UNIT_IDS)):
        column = index % GRID_COLUMNS
        row = index // GRID_COLUMNS
        cell = sheet.crop((column * cell_width, row * cell_height, (column + 1) * cell_width, (row + 1) * cell_height))
        if cell.getchannel("A").getbbox() is None:
            raise ValueError(f"{path.name}: occupied cell {index} is transparent")
        cells.append(cell)
    return cells


def fit_subject(cell: Image.Image, max_width: int = 162, max_height: int = 174) -> Image.Image:
    bbox = cell.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("cannot fit a transparent cell")
    subject = cell.crop(bbox)
    scale = min(max_width / subject.width, max_height / subject.height)
    subject = subject.resize((max(1, round(subject.width * scale)), max(1, round(subject.height * scale))), RESAMPLE)
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    x = (SIZE - subject.width) // 2
    y = 180 - subject.height
    canvas.alpha_composite(subject, (x, y))
    return canvas


def transformed(base: Image.Image, offset_x: int, offset_y: int, scale: float, degrees: float) -> Image.Image:
    bbox = base.getchannel("A").getbbox()
    if bbox is None:
        return base.copy()
    subject = base.crop(bbox)
    if scale != 1.0:
        subject = subject.resize((max(1, round(subject.width * scale)), max(1, round(subject.height * scale))), RESAMPLE)
    if degrees:
        subject = subject.rotate(degrees, resample=ROTATE_RESAMPLE, expand=True)
    fit_scale = min(1.0, 184 / subject.width, 178 / subject.height)
    if fit_scale < 1.0:
        subject = subject.resize((max(1, round(subject.width * fit_scale)), max(1, round(subject.height * fit_scale))), RESAMPLE)
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    x = max(4, min(SIZE - subject.width - 4, (SIZE - subject.width) // 2 + offset_x))
    y = max(4, min(SIZE - subject.height - 4, 180 - subject.height + offset_y))
    canvas.alpha_composite(subject, (x, y))
    return canvas


def checkerboard(size: tuple[int, int], block: int = 12) -> Image.Image:
    image = Image.new("RGBA", size, (24, 21, 30, 255))
    draw = ImageDraw.Draw(image)
    for y in range(0, size[1], block):
        for x in range(0, size[0], block):
            if (x // block + y // block) % 2 == 0:
                draw.rectangle((x, y, x + block - 1, y + block - 1), fill=(38, 34, 45, 255))
    return image


def write_preview(frames: dict[str, dict[str, list[Image.Image]]]) -> None:
    animations = list(SOURCES)
    gap = 10
    cell = 96
    label_width = 190
    width = label_width + len(animations) * (cell + gap) + gap
    height = gap + len(UNIT_IDS) * (cell + gap)
    canvas = checkerboard((width, height))
    draw = ImageDraw.Draw(canvas)
    for row, unit_id in enumerate(UNIT_IDS):
        y = gap + row * (cell + gap)
        draw.text((12, y + 38), unit_id, fill=(242, 222, 175, 255))
        for column, animation in enumerate(animations):
            thumb = frames[unit_id][animation][0].resize((cell, cell), RESAMPLE)
            canvas.alpha_composite(thumb, (label_width + column * (cell + gap), y))
    PREVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(PREVIEW_PATH, quality=94)


def main() -> None:
    missing = [path for path in SOURCES.values() if not path.exists()]
    if missing:
        raise FileNotFoundError("Missing counterforce alpha sheets:\n" + "\n".join(str(path) for path in missing))
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    PORTRAIT_DIR.mkdir(parents=True, exist_ok=True)
    all_frames: dict[str, dict[str, list[Image.Image]]] = {unit_id: {} for unit_id in UNIT_IDS}
    for animation, source_path in SOURCES.items():
        cells = split_sheet(source_path)
        for unit_id, cell in zip(UNIT_IDS, cells):
            base = fit_subject(cell)
            frames = [transformed(base, *variant) for variant in VARIANTS[animation]]
            all_frames[unit_id][animation] = frames
            for index, frame in enumerate(frames):
                output = OUTPUT_DIR / f"enemy_{unit_id}_{animation}_{index:02d}.png"
                frame.save(output, optimize=True)
                bbox = frame.getchannel("A").getbbox()
                if bbox is None or bbox[0] <= 0 or bbox[1] <= 0 or bbox[2] >= SIZE or bbox[3] >= SIZE:
                    raise ValueError(f"{output.name}: invalid alpha bounds {bbox}")
            if unit_id == "royal_strategist_evelyn" and animation == "idle_down":
                portrait = fit_subject(cell, 280, 300).resize((256, 256), RESAMPLE)
                portrait.save(PORTRAIT_DIR / "CHR_EVELYN_portrait.png", optimize=True)
    write_preview(all_frames)
    for unit_id in UNIT_IDS:
        hashes = {ImageChops.difference(all_frames[unit_id]["idle_down"][0], frame).getbbox() for frame in all_frames[unit_id]["move_down"]}
        print(f"{unit_id}: animations=2/4/4/4/2 move_variants={len(hashes)}")
    print(PREVIEW_PATH.relative_to(ROOT))


if __name__ == "__main__":
    main()
