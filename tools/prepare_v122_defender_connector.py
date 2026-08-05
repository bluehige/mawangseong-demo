"""Prepare the Stage 01 defender-connector junction bitmap."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = (
    ROOT
    / "assets"
    / "source"
    / "imagegen"
    / "v122_stage01_spatial"
    / "defender_connector_junction_v1"
    / "defender_connector_junction_alpha.png"
)
OUT = (
    ROOT
    / "assets"
    / "tiles"
    / "stage_01"
    / "spatial_passage_v1"
    / "defender_connector_junction_stage01.png"
)
RUNTIME_SIZE = (128, 64)


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    bbox = source.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("defender connector source contains no visible pixels")
    runtime = source.crop(bbox).resize(RUNTIME_SIZE, Image.Resampling.LANCZOS)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    runtime.save(OUT, optimize=True)
    print(f"{OUT.relative_to(ROOT).as_posix()}: {runtime.width}x{runtime.height} {runtime.mode}")


if __name__ == "__main__":
    main()
