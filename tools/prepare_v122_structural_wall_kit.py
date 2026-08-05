from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets" / "source" / "imagegen" / "v122_structural_wall_kit_v1"
RUNTIME_DIR = ROOT / "assets" / "tiles" / "cave_v2" / "structural_walls_v1"

CANVAS_SIZE = (256, 256)
ANCHOR = (128, 232)
TARGET_HEIGHT = 168

ASSETS = {
    "segment_axis_ne_sw": {
        "source": "segment_run_long_selected_alpha.png",
        "output": "wall_segment_axis_ne_sw.png",
        "max_width": 232,
        # 긴 원본의 중앙만 잘라 양쪽 종단면이 런타임 본체에 들어오지 않게 한다.
        # 좌우 절단선의 alpha가 열린 채 남는 것이 의도된 연결 포트다.
        "source_crop": (420, 442, 740, 791),
        "axis_slope": 0.5,
        "mirror": False,
    },
    "segment_axis_nw_se": {
        "source": "segment_run_long_selected_alpha.png",
        "output": "wall_segment_axis_nw_se.png",
        "max_width": 232,
        "source_crop": (420, 442, 740, 791),
        "axis_slope": 0.5,
        "mirror": True,
    },
    "vertex_corner": {
        "source": "vertex_corner_selected_alpha.png",
        "output": "wall_vertex_corner.png",
        "max_width": 96,
    },
    "vertex_end": {
        "source": "vertex_end_selected_alpha.png",
        "output": "wall_vertex_end.png",
        "max_width": 72,
    },
    "vertex_junction": {
        "source": "vertex_junction_selected_alpha.png",
        "output": "wall_vertex_junction.png",
        "max_width": 112,
    },
}


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("source image has no visible pixels")
    return bbox


def shear_run_to_axis_slope(image: Image.Image, target_slope: float) -> Image.Image:
    """벽 바닥선이 2:1 아이소메트릭 타일 변의 기울기와 정확히 같게 맞춘다."""
    alpha = image.getchannel("A")
    edge_x = [0, image.width - 1]
    edge_bottoms: list[int] = []
    for x in edge_x:
        visible_y = [y for y in range(image.height) if alpha.getpixel((x, y)) > 16]
        if not visible_y:
            raise ValueError("segment connection cut has no visible masonry")
        edge_bottoms.append(max(visible_y))
    current_slope = (edge_bottoms[1] - edge_bottoms[0]) / max(1, image.width - 1)
    shear = target_slope - current_slope
    if abs(shear) < 0.001:
        return image
    extra_height = int(math.ceil(abs(shear) * (image.width - 1)))
    y_offset = extra_height if shear < 0.0 else 0
    transformed = image.transform(
        (image.width, image.height + extra_height),
        Image.Transform.AFFINE,
        (1.0, 0.0, 0.0, -shear, 1.0, -y_offset),
        resample=Image.Resampling.BICUBIC,
        fillcolor=(0, 0, 0, 0),
    )
    return transformed.crop(alpha_bbox(transformed))


def prepare(
    source_path: Path,
    output_path: Path,
    max_width: int,
    source_crop: tuple[int, int, int, int] | None = None,
    mirror: bool = False,
    axis_slope: float | None = None,
) -> tuple[int, int]:
    source = Image.open(source_path).convert("RGBA")
    if source_crop is None:
        cropped = source.crop(alpha_bbox(source))
    else:
        cropped = source.crop(source_crop)
        cropped = cropped.crop(alpha_bbox(cropped))
        crop_bbox = cropped.getchannel("A").getbbox()
        if crop_bbox is None or crop_bbox[0] != 0 or crop_bbox[2] != cropped.width:
            raise ValueError(
                f"segment crop must expose masonry on both connection cuts: {output_path.name}"
            )
    if axis_slope is not None:
        cropped = shear_run_to_axis_slope(cropped, axis_slope)
    if mirror:
        cropped = ImageOps.mirror(cropped)
    scale = min(TARGET_HEIGHT / cropped.height, max_width / cropped.width)
    size = (
        max(1, round(cropped.width * scale)),
        max(1, round(cropped.height * scale)),
    )
    resized = cropped.resize(size, Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    position = (ANCHOR[0] - size[0] // 2, ANCHOR[1] - size[1])
    canvas.alpha_composite(resized, position)

    if canvas.getchannel("A").getpixel((0, 0)) != 0:
        raise ValueError(f"top-left corner is not transparent: {output_path.name}")
    if canvas.getchannel("A").getpixel((CANVAS_SIZE[0] - 1, CANVAS_SIZE[1] - 1)) != 0:
        raise ValueError(f"bottom-right corner is not transparent: {output_path.name}")
    runtime_bbox = alpha_bbox(canvas)
    if runtime_bbox[0] <= 0 or runtime_bbox[1] <= 0:
        raise ValueError(f"sprite touches the runtime canvas edge: {output_path.name}")
    if runtime_bbox[2] >= CANVAS_SIZE[0] or runtime_bbox[3] >= CANVAS_SIZE[1]:
        raise ValueError(f"sprite touches the runtime canvas edge: {output_path.name}")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output_path, optimize=True)
    return size


def main() -> None:
    for asset_id, spec in ASSETS.items():
        source_path = SOURCE_DIR / str(spec["source"])
        output_path = RUNTIME_DIR / str(spec["output"])
        if not source_path.exists():
            raise FileNotFoundError(source_path)
        size = prepare(
            source_path,
            output_path,
            int(spec["max_width"]),
            spec.get("source_crop"),
            bool(spec.get("mirror", False)),
            float(spec["axis_slope"]) if "axis_slope" in spec else None,
        )
        print(f"{asset_id}: {size[0]}x{size[1]} -> {output_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
