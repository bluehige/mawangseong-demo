from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "output" / "imagegen" / "spike_floor_v2_trap_sheet_01_alpha.png"
PROP_DIR = ROOT / "assets" / "props" / "v2"
PREVIEW = ROOT / "output" / "imagegen" / "spike_floor_v2_trap_sheet_01_sliced_preview.png"

FRAME_SIZE = (128, 96)
FRAME_NAMES = [
    "trap_spike_v2_idle_00.png",
    "trap_spike_v2_trigger_00.png",
    "trap_spike_v2_trigger_01.png",
    "trap_spike_v2_trigger_02.png",
    "trap_spike_v2_trigger_03.png",
]


def alpha_bbox(image: Image.Image, padding: int = 14) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return (0, 0, image.width, image.height)
    left, top, right, bottom = bbox
    return (
        max(0, left - padding),
        max(0, top - padding),
        min(image.width, right + padding),
        min(image.height, bottom + padding),
    )


def fit_frame(source: Image.Image) -> Image.Image:
    cropped = source.crop(alpha_bbox(source))
    fitted = cropped.copy()
    fitted.thumbnail((FRAME_SIZE[0], FRAME_SIZE[1]), Image.Resampling.LANCZOS)
    frame = Image.new("RGBA", FRAME_SIZE, (0, 0, 0, 0))
    x = (FRAME_SIZE[0] - fitted.width) // 2
    y = FRAME_SIZE[1] - fitted.height
    frame.alpha_composite(fitted, (x, y))
    return frame


def make_preview(outputs: list[tuple[str, Image.Image]]) -> None:
    thumb_w = 150
    thumb_h = 116
    preview = Image.new("RGBA", (thumb_w * len(outputs), thumb_h), (22, 19, 27, 255))
    for index, (_name, image) in enumerate(outputs):
        tile = Image.new("RGBA", (thumb_w, thumb_h), (34, 30, 40, 255))
        scaled = image.copy()
        scaled.thumbnail((thumb_w - 14, thumb_h - 14), Image.Resampling.LANCZOS)
        tile.alpha_composite(scaled, ((thumb_w - scaled.width) // 2, thumb_h - scaled.height - 6))
        preview.alpha_composite(tile, (index * thumb_w, 0))
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    preview.save(PREVIEW)


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(SOURCE)
    source = Image.open(SOURCE).convert("RGBA")
    frame_w = source.width // len(FRAME_NAMES)
    PROP_DIR.mkdir(parents=True, exist_ok=True)
    outputs: list[tuple[str, Image.Image]] = []
    for index, name in enumerate(FRAME_NAMES):
        left = index * frame_w
        right = source.width if index == len(FRAME_NAMES) - 1 else (index + 1) * frame_w
        frame = fit_frame(source.crop((left, 0, right, source.height)))
        frame.save(PROP_DIR / name)
        outputs.append((name, frame))
    make_preview(outputs)
    print(f"Wrote {len(outputs)} spike trap frames to {PROP_DIR}")
    print(f"Wrote preview: {PREVIEW}")


if __name__ == "__main__":
    main()
