from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets" / "source" / "imagegen" / "v122_structural_wall_kit_v2"
RUNTIME_DIR = ROOT / "assets" / "tiles" / "cave_v2" / "structural_walls_v2"

CANVAS_SIZE = (256, 256)
EDGE_BOTTOM_Y = 232
VERTEX_ANCHOR = (128, 208)
SEGMENT_WIDTH = 177
# 1280×720 최종 화면에서 셀 경계 간격은 약 20px, 벽 중심의 벽축 직각 두께는 9~10px로 보이게 한다.
# 긴 생성 원본 전체를 한 셀로 축소하면 벽돌과 높이까지 함께 눌리므로 중앙 3블록 분량만 쓴다.
SEGMENT_SOURCE_CROP = (730, 250, 1030, 680)
CORNER_WIDTH = 132
END_WIDTH = 90
JUNCTION_WIDTH = 156


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


def prepare_segment(mirror: bool, output_name: str) -> dict[str, object]:
    source = Image.open(SOURCE_DIR / "segment_run_long_selected_alpha.png").convert("RGBA")
    # 생성 이미지의 장식 없는 중앙 반복부만 사용한다. 양 끝 절단면에는 실제 석재 alpha가 남아야 한다.
    run = source.crop(SEGMENT_SOURCE_CROP)
    run = crop_visible(run)
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
    bbox = list(alpha_bbox(canvas))
    return {
        "path": output_path.relative_to(ROOT).as_posix(),
        "anchor": [round((connector_start[0] + connector_end[0]) / 2), round((connector_start[1] + connector_end[1]) / 2)],
        "connector_start": connector_start,
        "connector_end": connector_end,
        "bbox": bbox,
    }


def iso_quarter_turn(
    image: Image.Image,
    anchor: tuple[float, float],
    turns: int,
) -> tuple[Image.Image, tuple[float, float]]:
    turns %= 4
    if turns == 0:
        return image, anchor
    matrices = {
        1: ((0.0, -2.0), (0.5, 0.0)),
        2: ((-1.0, 0.0), (0.0, -1.0)),
        3: ((0.0, 2.0), (-0.5, 0.0)),
    }
    matrix = matrices[turns]
    points = []
    for x, y in ((0.0, 0.0), (image.width, 0.0), (0.0, image.height), (image.width, image.height)):
        dx = x - anchor[0]
        dy = y - anchor[1]
        points.append((matrix[0][0] * dx + matrix[0][1] * dy, matrix[1][0] * dx + matrix[1][1] * dy))
    min_x = math.floor(min(point[0] for point in points)) - 2
    max_x = math.ceil(max(point[0] for point in points)) + 2
    min_y = math.floor(min(point[1] for point in points)) - 2
    max_y = math.ceil(max(point[1] for point in points)) + 2
    out_size = (max_x - min_x, max_y - min_y)

    det = matrix[0][0] * matrix[1][1] - matrix[0][1] * matrix[1][0]
    inverse = (
        (matrix[1][1] / det, -matrix[0][1] / det),
        (-matrix[1][0] / det, matrix[0][0] / det),
    )
    # 출력 좌표를 회전 전 원본 좌표로 되돌리는 PIL affine 계수.
    c = inverse[0][0] * min_x + inverse[0][1] * min_y + anchor[0]
    f = inverse[1][0] * min_x + inverse[1][1] * min_y + anchor[1]
    transformed = image.transform(
        out_size,
        Image.Transform.AFFINE,
        (inverse[0][0], inverse[0][1], c, inverse[1][0], inverse[1][1], f),
        resample=Image.Resampling.BICUBIC,
        fillcolor=(0, 0, 0, 0),
    )
    transformed_anchor = (-min_x, -min_y)
    bbox = alpha_bbox(transformed)
    cropped = transformed.crop(bbox)
    return cropped, (transformed_anchor[0] - bbox[0], transformed_anchor[1] - bbox[1])


def prepare_directional_vertices(
    source_name: str,
    output_prefix: str,
    base_width: int,
    orientation_by_turn: list[str],
) -> dict[str, dict[str, object]]:
    source = Image.open(SOURCE_DIR / source_name).convert("RGBA")
    base = crop_visible(source)
    base = resize_to_width(base, base_width)
    # 선택 원본은 물리 접점이 하단 중앙에 오도록 생성했다.
    base_anchor = ((base.width - 1) * 0.5, base.height - 1.0)
    results: dict[str, dict[str, object]] = {}
    for turns, orientation in enumerate(orientation_by_turn):
        oriented, oriented_anchor = iso_quarter_turn(base, base_anchor, turns)
        canvas = composite_at_anchor(oriented, oriented_anchor, VERTEX_ANCHOR)
        output_path = RUNTIME_DIR / f"{output_prefix}_{orientation.lower()}.png"
        output_path.parent.mkdir(parents=True, exist_ok=True)
        canvas.save(output_path, optimize=True)
        results[orientation] = {
            "path": output_path.relative_to(ROOT).as_posix(),
            "anchor": list(VERTEX_ANCHOR),
            "bbox": list(alpha_bbox(canvas)),
        }
    return results


def prepare_sheet_vertices(
    source_name: str,
    output_prefix: str,
    base_width: int,
    quadrant_orientations: list[str],
    anchor_ratios: dict[str, tuple[float, float]],
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
        piece = resize_to_width(piece, base_width)
        anchor_ratio = anchor_ratios.get(orientation, (0.5, 0.85))
        source_anchor = (
            (piece.width - 1) * anchor_ratio[0],
            (piece.height - 1) * anchor_ratio[1],
        )
        canvas = composite_at_anchor(piece, source_anchor, VERTEX_ANCHOR)
        output_path = RUNTIME_DIR / f"{output_prefix}_{orientation.lower()}.png"
        output_path.parent.mkdir(parents=True, exist_ok=True)
        canvas.save(output_path, optimize=True)
        results[orientation] = {
            "path": output_path.relative_to(ROOT).as_posix(),
            "anchor": list(VERTEX_ANCHOR),
            "bbox": list(alpha_bbox(canvas)),
        }
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
            CORNER_WIDTH,
            ["WN", "NE", "SW", "ES"],
            {
                "WN": (0.50, 0.98),
                "NE": (0.50, 0.78),
                "ES": (0.50, 0.88),
                "SW": (0.78, 0.78),
            },
        ),
        "caps": prepare_sheet_vertices(
            "vertex_end_directional_sheet_selected_alpha.png",
            "wall_vertex_end",
            END_WIDTH,
            ["N", "E", "W", "S"],
            {direction: (0.50, 0.86) for direction in ["N", "E", "S", "W"]},
        ),
        "junctions": prepare_sheet_vertices(
            "vertex_junction_directional_sheet_selected_alpha.png",
            "wall_vertex_junction",
            JUNCTION_WIDTH,
            ["NEW", "NES", "NSW", "ESW"],
            {key: (0.50, 0.78) for key in ["NEW", "NES", "ESW", "NSW"]},
        ),
    }
    for group, entries in metadata.items():
        print(group)
        for key, value in entries.items():
            print(f"  {key}: {value}")


if __name__ == "__main__":
    main()
