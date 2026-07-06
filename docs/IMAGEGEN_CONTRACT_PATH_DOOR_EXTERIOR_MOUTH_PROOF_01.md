# Image Generation Contract - Path Door Exterior Mouth Proof 01

This is the first fresh visual proof after the failed visual material quarantine.

It must not reuse, copy, trace, repaint, slice, or present any quarantined concept/capture image as a current direction.

## Session Compass

We are building a playable Demon King castle dungeon demo, not a decorative background. The dungeon is data-first: logical grid cells, walkable cells, floor tiles, wall/door state, room-role objects, and path connections define the dungeon. Generated art must follow that data.

Beginner translation: the art is attached to the grid. It must not invent paths, rooms, or walkable floor that the data does not have.

## Built-In Image Generation Rule

- Use Codex built-in `image_gen`.
- Do not use API/CLI fallback.
- Do not ask for `OPENAI_API_KEY`.
- Do not use external generators.
- Do not treat this proof as runtime art until the user approves it.

## Proof Purpose

Create one production-style proof image for the path/door/exterior-mouth visual language:

1. A two-cell-wide exterior approach path.
2. A rough cave-mouth / dungeon entrance edge.
3. A paired two-cell doorway mouth aligned to the west side of a `5x5` entrance room footprint.
4. Dark cave void around unbuilt cells.

This proof is deliberately smaller than a full dungeon image. Its job is to prove whether the two-cell mouth and rough exterior path style are readable before slicing any runtime atlas.

## Numbered Grid-Position Contract

```json
{
  "asset_id": "path_door_exterior_mouth_proof_01",
  "grid_size": [7, 5],
  "tile_size": [128, 64],
  "projection": "iso_diamond_quarter_view",
  "grid_cells": {
    "G00_00": "void",
    "G01_00": "void",
    "G02_00": "entrance_room_reference_northwest",
    "G03_00": "entrance_room_reference_north",
    "G04_00": "entrance_room_reference_north",
    "G05_00": "entrance_room_reference_north",
    "G06_00": "entrance_room_reference_northeast",
    "G00_01": "void",
    "G01_01": "void",
    "G02_01": "entrance_room_reference_west_wall",
    "G03_01": "entrance_room_reference_floor",
    "G04_01": "entrance_room_reference_floor",
    "G05_01": "entrance_room_reference_floor",
    "G06_01": "entrance_room_reference_east_wall",
    "G00_02": "outside_approach_path",
    "G01_02": "outside_approach_path",
    "G02_02": "paired_west_doorway_upper",
    "G03_02": "entrance_room_reference_floor",
    "G04_02": "entrance_room_reference_floor",
    "G05_02": "entrance_room_reference_floor",
    "G06_02": "entrance_room_reference_floor",
    "G00_03": "outside_approach_path",
    "G01_03": "outside_approach_path",
    "G02_03": "paired_west_doorway_lower",
    "G03_03": "entrance_room_reference_floor",
    "G04_03": "entrance_room_reference_floor",
    "G05_03": "entrance_room_reference_floor",
    "G06_03": "entrance_room_reference_floor",
    "G00_04": "void",
    "G01_04": "void",
    "G02_04": "entrance_room_reference_southwest",
    "G03_04": "entrance_room_reference_south",
    "G04_04": "entrance_room_reference_south",
    "G05_04": "entrance_room_reference_south",
    "G06_04": "entrance_room_reference_southeast"
  },
  "anchor_cell": "G02_02",
  "connected_sides": {
    "entrance_room_reference": ["W"],
    "outside_approach_path": ["E"]
  },
  "blocked_sides": {
    "entrance_room_reference": ["N", "E", "S"],
    "outside_approach_path": ["N", "S", "W"]
  },
  "layer": "path",
  "final_manifest_path": "not_yet_runtime; proof only",
  "proof_output_path": "docs/concepts/path_door_exterior_mouth_proof_01.png"
}
```

## Visual Requirements

- Quarter-view / isometric-down diamond projection.
- The outside approach is exactly two cells wide and must visually align with `G00_02`, `G01_02`, `G00_03`, and `G01_03`.
- The doorway mouth opens only at `G02_02` and `G02_03`.
- The entrance reference room must read as a full `5x5` macro-room edge, not a front-facing rectangle.
- Closed north/east/south room sides must read as rough cave stone wall or blocked edge.
- Empty cells must read as dark cave void, rubble, or unbuilt negative space, not normal floor.
- Path floor must look different from room floor: darker worn stone, rubble edges, dust, or cracks.
- No UI labels, no text, no characters, no watermark.

## Built-In Image Prompt

```text
Use case: stylized-concept
Asset type: game asset proof for a quarter-view dungeon path doorway and exterior cave mouth
Primary request: Create a production-style proof image for a two-cell-wide exterior approach path entering the west side of a 5x5 Demon King dungeon entrance room.
Scene/backdrop: dark cave void around unbuilt cells, rough stone dungeon edge, compact readable game asset proof.
Subject: a two-cell-wide worn stone path from the exterior, a rough cave-mouth threshold, and a paired two-cell doorway opening on the west side of a 5x5 entrance room footprint.
Style/medium: hand-painted 2D quarter-view/isometric-down game art, readable at strategy-game zoom, dark fantasy demon castle.
Composition/framing: show the whole 7x5 logical grid footprint in quarter-view, with the 2x2 exterior path on the left and the 5x5 entrance room reference footprint on the right.
Lighting/mood: moody cave lighting with subtle purple magic rim light and warm torch-like highlights, but no characters or UI.
Color palette: dark stone, muted violet shadows, warm amber edge highlights, dusty worn path stones.
Materials/textures: chipped cave stone, uneven rubble edges, cracked path slabs, rough blocked walls, darker void around unbuilt cells.
Constraints: outside path is exactly two cells wide; doorway opens only at the two west-side socket cells; empty cells stay void/unbuilt; closed sides read as wall; no filled floor in void cells; no labels; no text; no watermark.
Avoid: front-facing rectangular room, full-floor board, decorative paths not in the contract, clean UI frame, characters, icons, text, old/quarantined visual direction.
```

## Approval Boundary

This proof can be reviewed visually, but it must not be sliced into runtime assets or referenced from `asset_manifest.json` as production art until the user approves the visual direction.

## Generated Proof Outputs - 2026-07-06

Generated through Codex built-in `image_gen` only:

| proof | path | status | notes |
|---|---|---|---|
| proof 01 | `docs/concepts/path_door_exterior_mouth_proof_01.png` | proof-only, not runtime | Strong hand-painted stone mood, but the entrance reads too much like a large enclosed decorative room. The exact `7x5` / `5x5` / `2x2` grid contract is not inspectable enough. Do not slice. |
| proof 02 | `docs/concepts/path_door_exterior_mouth_proof_02.png` | proof-only, not runtime | Cell readability improved, but the outside approach is larger than the required `2x2`, and the room reference expands beyond the strict `5x5` proof target. Do not slice. |

Current decision:

- Keep both files as fresh proof evidence only.
- Do not load them as runtime sprites.
- Do not wire them to `props`, `socket_caps`, `path_connection_production_contract`, or tile atlases.
- The next visual iteration should constrain the output further as a component/contact-sheet proof, not as a decorated room scene:
  - `2x2` exterior approach component,
  - west-side paired doorway mouth component,
  - rough cave-mouth edge component,
  - visible grid guide/contact sheet created separately by code if needed.
