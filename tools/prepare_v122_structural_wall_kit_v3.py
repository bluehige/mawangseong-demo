from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets" / "source" / "imagegen" / "v122_structural_wall_kit_v3"
RUNTIME_DIR = ROOT / "assets" / "tiles" / "cave_v2" / "structural_walls_v3"

# 캔버스와 crop 좌표는 원본을 담는 제작 좌표일 뿐, 화면 합격 기준이 아니다.
# 화면에서는 connector(맵의 한 사선 변)를 1.0으로 두고 모든 크기를 비율로 검증한다.
CANVAS_SIZE = (256, 256)
EDGE_BOTTOM_Y = 232
VERTEX_ANCHOR = (128, 208)

# 중앙 4단 반복부 210 source px를 connector 96x48 source px로 정규화한다.
# catalog overlap까지 포함한 실제 맵 한 변 E로 환산하면 중앙 높이가 약 1.60E다.
SEGMENT_SOURCE_CROP = (782, 100, 992, 780)
SEGMENT_WIDTH = 97
VERTEX_TARGET_HEIGHT = {
    "corner": 168,
    "cap": 160,
    "junction": 168,
}
FRONT_OCCLUDER_DEPTH = 42


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("source image has no visible pixels")
    return bbox


def crop_visible(image: Image.Image) -> Image.Image:
    return image.crop(alpha_bbox(image))


def visible_edge_bottoms(image: Image.Image) -> tuple[int, int]:
    alpha = image.getchannel("A")
    bottoms: list[int] = []
    for x in (0, image.width - 1):
        visible = [y for y in range(image.height) if alpha.getpixel((x, y)) > 16]
        if not visible:
            raise ValueError("segment connection cut has no visible masonry")
        bottoms.append(max(visible))
    return bottoms[0], bottoms[1]


def shear_run_to_axis_slope(image: Image.Image, target_slope: float) -> Image.Image:
    left_bottom, right_bottom = visible_edge_bottoms(image)
    current_slope = (right_bottom - left_bottom) / max(1, image.width - 1)
    shear = target_slope - current_slope
    if abs(shear) < 0.001:
        return crop_visible(image)
    extra_height = int(math.ceil(abs(shear) * (image.width - 1)))
    y_offset = extra_height if shear < 0.0 else 0
    transformed = image.transform(
        (image.width, image.height + extra_height),
        Image.Transform.AFFINE,
        (1.0, 0.0, 0.0, -shear, 1.0, -y_offset),
        resample=Image.Resampling.BICUBIC,
        fillcolor=(0, 0, 0, 0),
    )
    return crop_visible(transformed)


def resize_to_width(image: Image.Image, width: int) -> Image.Image:
    height = max(1, round(image.height * width / image.width))
    return image.resize((width, height), Image.Resampling.LANCZOS)


def resize_to_height(image: Image.Image, height: int) -> Image.Image:
    width = max(1, round(image.width * height / image.height))
    return image.resize((width, height), Image.Resampling.LANCZOS)


def composite_at_anchor(
    image: Image.Image,
    source_anchor: tuple[float, float],
    target_anchor: tuple[int, int],
) -> Image.Image:
    canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    position = (
        round(target_anchor[0] - source_anchor[0]),
        round(target_anchor[1] - source_anchor[1]),
    )
    canvas.alpha_composite(image, position)
    bbox = alpha_bbox(canvas)
    if bbox[0] <= 0 or bbox[1] <= 0 or bbox[2] >= CANVAS_SIZE[0] or bbox[3] >= CANVAS_SIZE[1]:
        raise ValueError(f"runtime sprite touches canvas edge: {bbox}")
    return canvas


def save_front_occluder(
    canvas: Image.Image,
    output_path: Path,
    baseline_y_by_x,
) -> tuple[int, int, int, int]:
    occluder = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    source_pixels = canvas.load()
    target_pixels = occluder.load()
    for y in range(canvas.height):
        for x in range(canvas.width):
            pixel = source_pixels[x, y]
            if pixel[3] == 0:
                continue
            baseline_y = baseline_y_by_x(x)
            if y >= baseline_y - FRONT_OCCLUDER_DEPTH:
                target_pixels[x, y] = pixel
    output_path.parent.mkdir(parents=True, exist_ok=True)
    occluder.save(output_path, optimize=True)
    return alpha_bbox(occluder)


def prepare_segment(mirror: bool, output_name: str) -> dict[str, object]:
    source = Image.open(SOURCE_DIR / "segment_run_long_selected_alpha.png").convert("RGBA")
    run = crop_visible(source.crop(SEGMENT_SOURCE_CROP))
    run = shear_run_to_axis_slope(run, 0.5)
    run = resize_to_width(run, SEGMENT_WIDTH)
    if mirror:
        run = ImageOps.mirror(run)
    left_bottom, right_bottom = visible_edge_bottoms(run)
    source_anchor = ((run.width - 1) * 0.5, (left_bottom + right_bottom) * 0.5)
    target_anchor_y = EDGE_BOTTOM_Y - max(left_bottom, right_bottom) + source_anchor[1]
    target_anchor = (128, round(target_anchor_y))
    canvas = composite_at_anchor(run, source_anchor, target_anchor)
    output_path = RUNTIME_DIR / output_name
    output_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output_path, optimize=True)

    x0 = round(target_anchor[0] - source_anchor[0])
    y0 = round(target_anchor[1] - source_anchor[1])
    connector_start = [x0, y0 + left_bottom]
    connector_end = [x0 + run.width - 1, y0 + right_bottom]
    delta_x = connector_end[0] - connector_start[0]
    delta_y = connector_end[1] - connector_start[1]

    def baseline_y_by_x(x: int) -> float:
        t = (x - connector_start[0]) / max(1, delta_x)
        return connector_start[1] + delta_y * t

    occluder_path = output_path.with_name(f"{output_path.stem}_front_occluder.png")
    occluder_bbox = save_front_occluder(canvas, occluder_path, baseline_y_by_x)
    bbox = list(alpha_bbox(canvas))
    return {
        "path": output_path.relative_to(ROOT).as_posix(),
        "front_occluder_path": occluder_path.relative_to(ROOT).as_posix(),
        "anchor": [
            round((connector_start[0] + connector_end[0]) / 2),
            round((connector_start[1] + connector_end[1]) / 2),
        ],
        "connector_start": connector_start,
        "connector_end": connector_end,
        "bbox": bbox,
        "front_occluder_bbox": list(occluder_bbox),
    }


def prepare_sheet_vertices(
    source_name: str,
    output_prefix: str,
    piece_group: str,
    quadrant_orientations: list[str],
    anchor_ratios: dict[str, tuple[float, float]],
    incident_directions: dict[str, list[str]],
) -> dict[str, dict[str, object]]:
    source = Image.open(SOURCE_DIR / source_name).convert("RGBA")
    half_width = source.width // 2
    half_height = source.height // 2
    quadrants = [
        (0, 0, half_width, half_height),
        (half_width, 0, source.width, half_height),
        (0, half_height, half_width, source.height),
        (half_width, half_height, source.width, source.height),
    ]
    results: dict[str, dict[str, object]] = {}
    for orientation, quadrant in zip(quadrant_orientations, quadrants, strict=True):
        piece = crop_visible(source.crop(quadrant))
        piece = resize_to_height(piece, VERTEX_TARGET_HEIGHT[piece_group])
        anchor_ratio = anchor_ratios.get(orientation, (0.5, 0.85))
        source_anchor = (
            (piece.width - 1) * anchor_ratio[0],
            (piece.height - 1) * anchor_ratio[1],
        )
        canvas = composite_at_anchor(piece, source_anchor, VERTEX_ANCHOR)
        output_path = RUNTIME_DIR / f"{output_prefix}_{orientation.lower()}.png"
        output_path.parent.mkdir(parents=True, exist_ok=True)
        canvas.save(output_path, optimize=True)
        result: dict[str, object] = {
            "path": output_path.relative_to(ROOT).as_posix(),
            "anchor": list(VERTEX_ANCHOR),
            "bbox": list(alpha_bbox(canvas)),
        }
        if any(direction in ["E", "S"] for direction in incident_directions[orientation]):
            occluder_path = output_path.with_name(f"{output_path.stem}_front_occluder.png")
            occluder_bbox = save_front_occluder(
                canvas,
                occluder_path,
                lambda _x: float(VERTEX_ANCHOR[1]),
            )
            result["front_occluder_path"] = occluder_path.relative_to(ROOT).as_posix()
            result["front_occluder_bbox"] = list(occluder_bbox)
        results[orientation] = result
    return results


def main() -> None:
    metadata: dict[str, object] = {
        "segments": {
            "NE_SW": prepare_segment(False, "wall_segment_axis_ne_sw.png"),
            "NW_SE": prepare_segment(True, "wall_segment_axis_nw_se.png"),
        },
        "corners": prepare_sheet_vertices(
            "vertex_corner_directional_sheet_selected_alpha.png",
            "wall_vertex_corner",
            "corner",
            ["WN", "NE", "SW", "ES"],
            {
                "WN": (0.50, 0.98),
                "NE": (0.50, 0.78),
                "ES": (0.50, 0.88),
                "SW": (0.72, 0.78),
            },
            {"WN": ["W", "N"], "NE": ["N", "E"], "SW": ["S", "W"], "ES": ["E", "S"]},
        ),
        "caps": prepare_sheet_vertices(
            "vertex_end_directional_sheet_selected_alpha.png",
            "wall_vertex_end",
            "cap",
            ["N", "E", "W", "S"],
            {direction: (0.50, 0.86) for direction in ["N", "E", "S", "W"]},
            {direction: [direction] for direction in ["N", "E", "S", "W"]},
        ),
        "junctions": prepare_sheet_vertices(
            "vertex_junction_directional_sheet_selected_alpha.png",
            "wall_vertex_junction",
            "junction",
            ["NEW", "NES", "NSW", "ESW"],
            {key: (0.50, 0.78) for key in ["NEW", "NES", "ESW", "NSW"]},
            {
                "NEW": ["N", "E", "W"],
                "NES": ["N", "E", "S"],
                "NSW": ["N", "S", "W"],
                "ESW": ["E", "S", "W"],
            },
        ),
    }
    for group, entries in metadata.items():
        print(group)
        for key, value in entries.items():
            print(f"  {key}: {value}")


if __name__ == "__main__":
    main()
