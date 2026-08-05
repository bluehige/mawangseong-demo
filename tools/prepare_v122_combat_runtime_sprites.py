"""Prepare the V1-C/V1-D batches of Update 4 combat sheets.

The source sheets are 1254x1254 4x4 chroma-key images.  This tool removes
the generated magenta plate from the complete sheet, assigns connected art
back to the frame where most of it originated, and applies one shared crop
and scale to all 16 frames.  That keeps foot placement stable while rescuing
art that crosses the generated grid boundaries.
The resulting 768x768 sheets are intentionally not connected to gameplay in
V1-C and V1-D; V2 owns the runtime profile and lookup change.
"""

from __future__ import annotations

import argparse
import json
from collections import deque
from hashlib import sha256
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets" / "source" / "imagegen" / "update4_region_enemies"
RUNTIME_DIR = ROOT / "assets" / "sprites" / "enemies" / "update4" / "region" / "normalized"
TMP_ROOT = ROOT / "tmp" / "v122_release_polish"
CELL_SIZE = 192
GRID_SIZE = 4
SOURCE_SIZE = 1254
RUNTIME_PADDING = 6
ALPHA_THRESHOLD = 32
MIN_CROSSING_COMPONENT_DOMINANCE = 0.90
# Detached glints and dust motes can sit exactly on a generated grid line.
# They are recorded for visual review; only a larger ambiguous body component
# is unsafe enough to stop preparation automatically.
MAX_AMBIGUOUS_PARTICLE_PIXELS = 2048

V1_C_TARGETS = (
    ("coal_spark", "coal_spark_combat_sheet_chroma_2026-07-27.png"),
    ("dusk_courier", "dusk_courier_combat_sheet_chroma_2026-07-27.png"),
    ("bronze_automaton", "bronze_automaton_combat_sheet_chroma_2026-07-27.png"),
)
V1_D_TARGETS = (
    ("shadow_duelist", "shadow_duelist_combat_sheet_chroma_2026-07-27.png"),
    ("spore_doll", "spore_doll_combat_sheet_chroma_2026-07-27.png"),
    ("root_tender", "root_tender_combat_sheet_chroma_2026-07-27.png"),
)
PACKETS = {
    "v1-c": V1_C_TARGETS,
    "v1-d": V1_D_TARGETS,
}
FRAME_ORDER = (
    "idle_down_00",
    "idle_down_01",
    "down_00",
    "down_01",
    "move_down_00",
    "move_down_01",
    "move_down_02",
    "move_down_03",
    "attack_down_00",
    "attack_down_01",
    "attack_down_02",
    "attack_down_03",
    "skill_down_00",
    "skill_down_01",
    "skill_down_02",
    "skill_down_03",
)

try:
    RESAMPLE = Image.Resampling.LANCZOS
except AttributeError:  # pragma: no cover - Pillow compatibility fallback
    RESAMPLE = Image.LANCZOS


def _relative(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def _packet_dir(packet: str) -> Path:
    if packet not in PACKETS:
        raise ValueError(f"unknown packet: {packet}")
    return TMP_ROOT / packet.replace("-", "_")


def _manifest_path(packet: str) -> Path:
    return _packet_dir(packet) / f"{packet.replace('-', '_')}_runtime_sprite_manifest.json"


def _digest(path: Path) -> str:
    return sha256(path.read_bytes()).hexdigest()


def _is_background_like(pixel: tuple[int, int, int, int]) -> bool:
    """Classify the generated magenta background, not arbitrary purple art."""

    red, green, blue, alpha = pixel
    if alpha == 0:
        return True
    return (
        red >= 130
        and blue >= 105
        and green <= 140
        and abs(red - blue) <= 150
        and min(red, blue) - green >= 45
    )


def _is_high_confidence_background(pixel: tuple[int, int, int, int]) -> bool:
    """Match only the near-flat hot-pink plate, including enclosed gaps."""

    red, green, blue, alpha = pixel
    return (
        alpha > 0
        and red >= 185
        and blue >= 180
        and green <= 70
        and abs(red - blue) <= 90
        and min(red, blue) - green >= 120
    )


def _border_connected_background(image: Image.Image) -> bytearray:
    """Return a mask of chroma pixels connected to the cell border.

    Flood filling instead of globally deleting magenta preserves isolated
    magenta details inside a character while removing the generated backdrop.
    """

    rgba = image.convert("RGBA")
    width, height = rgba.size
    pixels = rgba.load()
    visited = bytearray(width * height)
    queue: deque[tuple[int, int]] = deque()

    def enqueue(x: int, y: int) -> None:
        index = y * width + x
        if visited[index] or not _is_background_like(pixels[x, y]):
            return
        visited[index] = 1
        queue.append((x, y))

    for x in range(width):
        enqueue(x, 0)
        enqueue(x, height - 1)
    for y in range(height):
        enqueue(0, y)
        enqueue(width - 1, y)

    while queue:
        x, y = queue.popleft()
        if x > 0:
            enqueue(x - 1, y)
        if x + 1 < width:
            enqueue(x + 1, y)
        if y > 0:
            enqueue(x, y - 1)
        if y + 1 < height:
            enqueue(x, y + 1)
    return visited


def _remove_chroma_background(cell: Image.Image) -> Image.Image:
    rgba = cell.convert("RGBA")
    mask = _border_connected_background(rgba)
    width, height = rgba.size
    pixels = rgba.load()
    for y in range(height):
        for x in range(width):
            # The broad key is restricted to the edge-connected plate. A much
            # narrower exact-background key also clears hot-pink gaps enclosed
            # between limbs, while retaining darker purple highlights and VFX.
            if mask[y * width + x] or _is_high_confidence_background(pixels[x, y]):
                pixels[x, y] = (0, 0, 0, 0)
    alpha = rgba.getchannel("A").point(lambda value: 0 if value <= ALPHA_THRESHOLD else value)
    rgba.putalpha(alpha)
    return rgba


def _resize_premultiplied(image: Image.Image) -> Image.Image:
    """Resize RGBA without smearing transparent magenta RGB into edges."""

    rgba = image.convert("RGBA")
    red, green, blue, alpha = rgba.split()
    premultiplied = Image.merge(
        "RGBA",
        (
            ImageChops.multiply(red, alpha),
            ImageChops.multiply(green, alpha),
            ImageChops.multiply(blue, alpha),
            alpha,
        ),
    ).resize((CELL_SIZE, CELL_SIZE), RESAMPLE)
    red, green, blue, alpha = premultiplied.split()
    output = Image.new("RGBA", (CELL_SIZE, CELL_SIZE), (0, 0, 0, 0))
    source_pixels = (red.load(), green.load(), blue.load(), alpha.load())
    output_pixels = output.load()
    for y in range(CELL_SIZE):
        for x in range(CELL_SIZE):
            value = source_pixels[3][x, y]
            if value <= 0:
                continue
            output_pixels[x, y] = tuple(
                min(255, (source_pixels[channel][x, y] * 255 + value // 2) // value)
                for channel in range(3)
            ) + (value,)
    return _despill_transparent_edges(output)


def _despill_transparent_edges(image: Image.Image) -> Image.Image:
    """Neutralize magenta RGB bleed on the outer two runtime pixels."""

    rgba = image.convert("RGBA")
    width, height = rgba.size
    pixels = rgba.load()
    visited = {(x, y) for y in range(height) for x in range(width) if pixels[x, y][3] == 0}
    frontier = set(visited)
    for strength in (0.85, 0.45):
        candidates: set[tuple[int, int]] = set()
        for x, y in frontier:
            for offset_y in (-1, 0, 1):
                for offset_x in (-1, 0, 1):
                    if offset_x == 0 and offset_y == 0:
                        continue
                    candidate = (x + offset_x, y + offset_y)
                    if not (0 <= candidate[0] < width and 0 <= candidate[1] < height):
                        continue
                    if candidate in visited or pixels[candidate[0], candidate[1]][3] == 0:
                        continue
                    candidates.add(candidate)
        for x, y in candidates:
            red, green, blue, alpha = pixels[x, y]
            spill = max(0, min(red, blue) - green)
            reduction = int(round(spill * strength))
            pixels[x, y] = (max(0, red - reduction), green, max(0, blue - reduction), alpha)
        visited.update(candidates)
        frontier = candidates
    return rgba


def _validate_border_only_contract() -> None:
    """Guard against reintroducing a global magenta deletion pass."""

    sample = Image.new("RGBA", (9, 9), (235, 5, 235, 255))
    pixels = sample.load()
    for y in range(2, 7):
        for x in range(2, 7):
            pixels[x, y] = (24, 22, 30, 255)
    pixels[4, 4] = (155, 35, 165, 255)
    keyed = _remove_chroma_background(sample)
    if keyed.getpixel((0, 0))[3] != 0:
        raise ValueError("border-connected chroma must become transparent")
    prepared = _resize_premultiplied(keyed)
    if prepared.getpixel((CELL_SIZE // 2, CELL_SIZE // 2))[3] == 0:
        raise ValueError("enclosed purple artwork must remain visible")


def _nominal_cell_index(x: int, y: int, width: int, height: int) -> int:
    column = min(GRID_SIZE - 1, x * GRID_SIZE // width)
    row = min(GRID_SIZE - 1, y * GRID_SIZE // height)
    return row * GRID_SIZE + column


def _assigned_frame_layers(source: Image.Image) -> tuple[list[Image.Image], list[dict]]:
    """Assign each 8-connected foreground component to its majority frame.

    Generated characters and effects occasionally cross a nominal 4x4 cell
    edge.  Cropping first cuts those pixels off.  Assigning a connected
    component by the cell containing most of its pixels recovers that art
    without mixing in a neighbouring frame.
    """

    rgba = source.convert("RGBA")
    width, height = rgba.size
    source_pixels = rgba.load()
    alpha = rgba.getchannel("A")
    alpha_pixels = alpha.load()
    visited = bytearray(width * height)
    layers = [Image.new("RGBA", rgba.size, (0, 0, 0, 0)) for _index in range(GRID_SIZE * GRID_SIZE)]
    layer_pixels = [layer.load() for layer in layers]
    component_records: list[dict] = []

    for start_y in range(height):
        for start_x in range(width):
            start = start_y * width + start_x
            if visited[start] or alpha_pixels[start_x, start_y] <= ALPHA_THRESHOLD:
                continue
            visited[start] = 1
            queue: deque[int] = deque((start,))
            component: list[int] = []
            overlaps = [0] * (GRID_SIZE * GRID_SIZE)
            while queue:
                position = queue.popleft()
                y, x = divmod(position, width)
                component.append(position)
                overlaps[_nominal_cell_index(x, y, width, height)] += 1
                for offset_y in (-1, 0, 1):
                    for offset_x in (-1, 0, 1):
                        if offset_x == 0 and offset_y == 0:
                            continue
                        candidate_x = x + offset_x
                        candidate_y = y + offset_y
                        if not (0 <= candidate_x < width and 0 <= candidate_y < height):
                            continue
                        candidate = candidate_y * width + candidate_x
                        if visited[candidate] or alpha_pixels[candidate_x, candidate_y] <= ALPHA_THRESHOLD:
                            continue
                        visited[candidate] = 1
                        queue.append(candidate)

            assigned = max(range(len(overlaps)), key=lambda index: overlaps[index])
            occupied_cells = sum(1 for count in overlaps if count > 0)
            dominance = overlaps[assigned] / len(component)
            if (
                occupied_cells > 1
                and dominance < MIN_CROSSING_COMPONENT_DOMINANCE
                and len(component) > MAX_AMBIGUOUS_PARTICLE_PIXELS
            ):
                raise ValueError(
                    "ambiguous foreground component "
                    f"pixels={len(component)} dominance={dominance:.4f} overlaps={overlaps}"
                )
            destination = layer_pixels[assigned]
            for position in component:
                y, x = divmod(position, width)
                destination[x, y] = source_pixels[x, y]
            component_records.append(
                {
                    "frame": assigned,
                    "pixels": len(component),
                    "occupied_cells": occupied_cells,
                    "dominance": round(dominance, 6),
                }
            )

    return layers, component_records


def _shared_source_window(layers: list[Image.Image]) -> tuple[int, int, int]:
    """Return one square relative crop used by every nominal source cell."""

    relative_left: float | None = None
    relative_top: float | None = None
    relative_right: float | None = None
    relative_bottom: float | None = None
    for index, layer in enumerate(layers):
        bbox = layer.getchannel("A").getbbox()
        if bbox is None:
            raise ValueError(f"frame {index} is fully transparent after component assignment")
        column = index % GRID_SIZE
        row = index // GRID_SIZE
        center_x = (column + 0.5) * SOURCE_SIZE / GRID_SIZE
        center_y = (row + 0.5) * SOURCE_SIZE / GRID_SIZE
        left, top, right, bottom = bbox
        frame_left = left - center_x
        frame_top = top - center_y
        frame_right = right - center_x
        frame_bottom = bottom - center_y
        relative_left = frame_left if relative_left is None else min(relative_left, frame_left)
        relative_top = frame_top if relative_top is None else min(relative_top, frame_top)
        relative_right = frame_right if relative_right is None else max(relative_right, frame_right)
        relative_bottom = frame_bottom if relative_bottom is None else max(relative_bottom, frame_bottom)

    assert relative_left is not None and relative_top is not None
    assert relative_right is not None and relative_bottom is not None
    content_width = relative_right - relative_left
    content_height = relative_bottom - relative_top
    usable_fraction = (CELL_SIZE - 2 * RUNTIME_PADDING) / CELL_SIZE
    window_size = int(max(content_width, content_height) / usable_fraction + 0.999999)
    padding_source = window_size * RUNTIME_PADDING / CELL_SIZE
    center_x = (relative_left + relative_right) / 2.0
    left = int(round(center_x - window_size / 2.0))
    # Keep a common bottom reference instead of independently centring frames;
    # this preserves the source animation's foot placement.
    bottom = int(round(relative_bottom + padding_source))
    top = bottom - window_size
    return left, top, window_size


def _cell_perimeter_is_clear(alpha: Image.Image) -> bool:
    width, height = alpha.size
    return all(
        alpha.getpixel((x, 0)) <= ALPHA_THRESHOLD
        and alpha.getpixel((x, height - 1)) <= ALPHA_THRESHOLD
        for x in range(width)
    ) and all(
        alpha.getpixel((0, y)) <= ALPHA_THRESHOLD
        and alpha.getpixel((width - 1, y)) <= ALPHA_THRESHOLD
        for y in range(height)
    )


def _median(values: list[int]) -> float:
    ordered = sorted(values)
    midpoint = len(ordered) // 2
    if len(ordered) % 2:
        return float(ordered[midpoint])
    return (ordered[midpoint - 1] + ordered[midpoint]) / 2.0


def _cell_metrics(cells: list[Image.Image]) -> dict:
    bboxes = [cell.getchannel("A").point(lambda value: 255 if value > ALPHA_THRESHOLD else 0).getbbox() for cell in cells]
    if any(bbox is None for bbox in bboxes):
        raise ValueError("runtime sheet contains a fully transparent frame")
    typed_bboxes = [bbox for bbox in bboxes if bbox is not None]
    heights = [bbox[3] - bbox[1] for bbox in typed_bboxes]
    bottoms = [bbox[3] for bbox in typed_bboxes]
    return {
        "cell_alpha_bbox": [list(bbox) for bbox in typed_bboxes],
        "median_art_height_px": _median(heights),
        "foot_bottom_px": bottoms,
        "foot_bottom_spread_px": max(bottoms) - min(bottoms),
        "cell_perimeter_clear": all(_cell_perimeter_is_clear(cell.getchannel("A")) for cell in cells),
    }


def _source_cells(source: Image.Image) -> tuple[list[Image.Image], dict]:
    if source.size != (SOURCE_SIZE, SOURCE_SIZE):
        raise ValueError(f"expected {SOURCE_SIZE}x{SOURCE_SIZE}, got {source.size}")
    keyed = _remove_chroma_background(source)
    layers, component_records = _assigned_frame_layers(keyed)
    relative_left, relative_top, window_size = _shared_source_window(layers)
    cells: list[Image.Image] = []
    for index in range(GRID_SIZE * GRID_SIZE):
        column = index % GRID_SIZE
        row = index // GRID_SIZE
        center_x = (column + 0.5) * SOURCE_SIZE / GRID_SIZE
        center_y = (row + 0.5) * SOURCE_SIZE / GRID_SIZE
        left = int(round(center_x + relative_left))
        top = int(round(center_y + relative_top))
        cell = layers[index].crop((left, top, left + window_size, top + window_size))
        cell = _resize_premultiplied(cell)
        alpha = cell.getchannel("A")
        if alpha.getbbox() is None:
            raise ValueError(f"cell {index} is fully transparent")
        if not _cell_perimeter_is_clear(alpha):
            raise ValueError(f"cell {index} foreground touches the runtime perimeter")
        cells.append(cell)
    metrics = _cell_metrics(cells)
    metrics["source_window_size_px"] = window_size
    metrics["component_count"] = len(component_records)
    metrics["crossing_component_count"] = sum(1 for record in component_records if record["occupied_cells"] > 1)
    metrics["minimum_crossing_component_dominance"] = min(
        (record["dominance"] for record in component_records if record["occupied_cells"] > 1),
        default=1.0,
    )
    metrics["ambiguous_particle_count"] = sum(
        1
        for record in component_records
        if record["occupied_cells"] > 1
        and record["dominance"] < MIN_CROSSING_COMPONENT_DOMINANCE
        and record["pixels"] <= MAX_AMBIGUOUS_PARTICLE_PIXELS
    )
    return cells, metrics


def _runtime_sheet(cells: Iterable[Image.Image]) -> Image.Image:
    sheet = Image.new("RGBA", (GRID_SIZE * CELL_SIZE, GRID_SIZE * CELL_SIZE), (0, 0, 0, 0))
    for index, cell in enumerate(cells):
        sheet.alpha_composite(cell, ((index % GRID_SIZE) * CELL_SIZE, (index // GRID_SIZE) * CELL_SIZE))
    return sheet


def _record_for(asset_id: str, cells: list[Image.Image], metrics: dict, runtime_path: Path, source_path: Path) -> dict:
    return {
        "id": asset_id,
        "source_path": _relative(source_path),
        "source_sha256": _digest(source_path),
        "runtime_path": _relative(runtime_path),
        "runtime_sha256": _digest(runtime_path),
        "source_size_px": [SOURCE_SIZE, SOURCE_SIZE],
        "runtime_size_px": [GRID_SIZE * CELL_SIZE, GRID_SIZE * CELL_SIZE],
        "cell_size_px": [CELL_SIZE, CELL_SIZE],
        "frame_order": list(FRAME_ORDER),
        "cell_perimeter_clear": metrics["cell_perimeter_clear"],
        "median_art_height_px": metrics["median_art_height_px"],
        "foot_bottom_px": metrics["foot_bottom_px"],
        "foot_bottom_spread_px": metrics["foot_bottom_spread_px"],
        "cell_alpha_bbox": metrics["cell_alpha_bbox"],
        "source_window_size_px": metrics["source_window_size_px"],
        "component_count": metrics["component_count"],
        "crossing_component_count": metrics["crossing_component_count"],
        "minimum_crossing_component_dominance": metrics["minimum_crossing_component_dominance"],
        "ambiguous_particle_count": metrics["ambiguous_particle_count"],
    }


def _selected_targets(packet: str, ids: list[str] | None) -> tuple[tuple[str, str], ...]:
    targets = PACKETS[packet]
    if not ids:
        return targets
    by_id = dict(targets)
    unknown = sorted(set(ids) - set(by_id))
    if unknown:
        raise ValueError(f"unknown {packet.upper()} asset id(s): {', '.join(unknown)}")
    return tuple((asset_id, by_id[asset_id]) for asset_id in ids)


def _build_manifest(records: list[dict], packet: str) -> dict:
    return {
        "schema_version": 1,
        "packet": packet.upper(),
        "source_contract": "1254x1254 4x4 chroma-key sheet",
        "runtime_contract": "768x768 RGBA sheet with integer 192x192 cells",
        "algorithm": "full-sheet border-connected chroma removal; 8-connected majority-frame component assignment; shared padded source window; premultiplied LANCZOS resize; alpha-preserving 2px edge despill; full-cell perimeter validation",
        "cell_size_px": CELL_SIZE,
        "frame_order": list(FRAME_ORDER),
        "records": records,
    }


def _write_manifest(manifest: dict, packet: str) -> None:
    packet_dir = _packet_dir(packet)
    packet_dir.mkdir(parents=True, exist_ok=True)
    _manifest_path(packet).write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def prepare(packet: str, targets: tuple[tuple[str, str], ...]) -> dict:
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    records: list[dict] = []
    for asset_id, source_name in targets:
        source_path = SOURCE_DIR / source_name
        if not source_path.exists():
            raise FileNotFoundError(source_path)
        runtime_path = RUNTIME_DIR / f"enemy_{asset_id}_sheet.png"
        with Image.open(source_path) as source:
            cells, metrics = _source_cells(source)
        _runtime_sheet(cells).save(runtime_path, optimize=True)
        records.append(_record_for(asset_id, cells, metrics, runtime_path, source_path))
        print(f"prepared {_relative(runtime_path)}")
    manifest = _build_manifest(records, packet)
    _write_manifest(manifest, packet)
    return manifest


def check(packet: str) -> dict:
    manifest_path = _manifest_path(packet)
    if not manifest_path.exists():
        raise FileNotFoundError(f"missing manifest: {_relative(manifest_path)}")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    expected_packet = packet.upper()
    if manifest.get("schema_version") != 1 or manifest.get("packet") != expected_packet:
        raise ValueError(f"unexpected {expected_packet} manifest schema")
    records = manifest.get("records")
    expected_targets = PACKETS[packet]
    expected_ids = [asset_id for asset_id, _source_name in expected_targets]
    if not isinstance(records, list) or [record.get("id") for record in records] != expected_ids:
        raise ValueError(f"{expected_packet} manifest must contain the expected three records in order")
    for record in records:
        source_path = ROOT / str(record.get("source_path", ""))
        if not source_path.exists() or _digest(source_path) != record.get("source_sha256"):
            raise ValueError(f"source digest mismatch: {_relative(source_path)}")
        runtime_path = ROOT / str(record.get("runtime_path", ""))
        if not runtime_path.exists():
            raise FileNotFoundError(runtime_path)
        with Image.open(runtime_path) as image:
            if image.mode != "RGBA" or image.size != (GRID_SIZE * CELL_SIZE, GRID_SIZE * CELL_SIZE):
                raise ValueError(f"invalid runtime sheet: {_relative(runtime_path)} {image.mode} {image.size}")
            alpha = image.getchannel("A")
            for index in range(GRID_SIZE * GRID_SIZE):
                left = (index % GRID_SIZE) * CELL_SIZE
                top = (index // GRID_SIZE) * CELL_SIZE
                cell = alpha.crop((left, top, left + CELL_SIZE, top + CELL_SIZE))
                if cell.getbbox() is None:
                    raise ValueError(f"runtime cell {record.get('id')}:{index} is transparent")
                if not _cell_perimeter_is_clear(cell):
                    raise ValueError(f"runtime cell {record.get('id')}:{index} foreground touches perimeter")
            expected_metrics = _cell_metrics(
                [
                    image.crop(
                        (
                            (index % GRID_SIZE) * CELL_SIZE,
                            (index // GRID_SIZE) * CELL_SIZE,
                            (index % GRID_SIZE + 1) * CELL_SIZE,
                            (index // GRID_SIZE + 1) * CELL_SIZE,
                        )
                    )
                    for index in range(GRID_SIZE * GRID_SIZE)
                ]
            )
            for key in ("median_art_height_px", "foot_bottom_px", "foot_bottom_spread_px", "cell_alpha_bbox"):
                if expected_metrics[key] != record.get(key):
                    raise ValueError(f"runtime metric mismatch: {record.get('id')} {key}")
        if _digest(runtime_path) != record.get("runtime_sha256"):
            raise ValueError(f"runtime digest mismatch: {_relative(runtime_path)}")
    print(f"V122_COMBAT_RUNTIME_SPRITE_PREP: PASS packet={expected_packet} records={len(records)}")
    return manifest


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="verify existing packet outputs without writing")
    parser.add_argument("--packet", choices=tuple(PACKETS), default="v1-c", help="asset packet to prepare/check")
    parser.add_argument("--ids", help="comma-separated subset of the selected packet for local diagnosis")
    args = parser.parse_args()
    try:
        _validate_border_only_contract()
        if args.check:
            check(args.packet)
        else:
            ids = [value.strip() for value in args.ids.split(",") if value.strip()] if args.ids else None
            manifest = prepare(args.packet, _selected_targets(args.packet, ids))
            print(f"V122_COMBAT_RUNTIME_SPRITE_PREP: PASS packet={args.packet.upper()} records={len(manifest['records'])}")
    except (FileNotFoundError, OSError, ValueError) as error:
        print(f"V122_COMBAT_RUNTIME_SPRITE_PREP: FAIL {error}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
