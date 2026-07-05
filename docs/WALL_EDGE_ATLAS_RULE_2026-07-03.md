# Wall Edge Atlas Rule - 2026-07-03

Purpose: record the correction that the current socket wall pass is not the final wall-edge system.

## Current Audit

The current cave v2 wall assets are not a complete rule-based wall atlas.

- `wall_cave_v2_ne_straight_00.png`
- `wall_cave_v2_nw_straight_00.png`
- `wall_cave_v2_mask_00.png` through `wall_cave_v2_mask_15.png`

The `wall_mask_00~15` files are not true directional wall-mask variants. They currently repeat the two straight wall source images. They are usable only as temporary visual caps, not as final grid-edge wall rules.

The current socket cap pass proves only this:

- connected sockets can draw doorway caps,
- open placeholder sockets can draw build-slot caps,
- closed sockets can draw wall caps.

It does not yet prove that walls continue correctly along grid edges.

## Required Final Rule

Walls must be selected from logical edge data, not from visual guesswork.

For every floor cell:

1. For each side `N`, `E`, `S`, `W`, check `open_edge_set`.
2. If the side is open, no closed wall is drawn on that edge.
3. If the side is closed, create one wall-edge record:
   - `cell`: logical grid cell
   - `side`: `N`, `E`, `S`, or `W`
   - `state`: `closed`, `open_placeholder`, or `connected`
   - `layer`: `wall_back` for `N/W`, `wall_front` for `E/S`
   - `join_prev`: whether the edge continues at the first vertex
   - `join_next`: whether the edge continues at the second vertex
   - `variant`: derived from joins and socket state
4. Select a wall sprite by `side + variant`.

The renderer must not freely reuse one wall image for multiple logical sides unless the manifest explicitly declares an alias.

## Minimum Atlas Needed

For the first correct F-grade cave atlas, generate or slice at least:

- `wall_N_straight`
- `wall_E_straight`
- `wall_S_straight`
- `wall_W_straight`
- `wall_N_end_a`, `wall_N_end_b`
- `wall_E_end_a`, `wall_E_end_b`
- `wall_S_end_a`, `wall_S_end_b`
- `wall_W_end_a`, `wall_W_end_b`
- `wall_corner_NE`
- `wall_corner_ES`
- `wall_corner_SW`
- `wall_corner_WN`
- `wall_cap_closed_N`, `wall_cap_closed_E`, `wall_cap_closed_S`, `wall_cap_closed_W`
- `door_open_N`, `door_open_E`, `door_open_S`, `door_open_W`
- `socket_placeholder_N`, `socket_placeholder_E`, `socket_placeholder_S`, `socket_placeholder_W`

This can be optimized later, but the manifest must still expose logical `N/E/S/W` keys even when two images are aliased internally.

## Mandatory Image Generation Contract

Before generating this atlas with built-in GPT Image 2, write a numbered contract with:

- `asset_id`: `wall_edge_atlas_cave_f_01`
- `grid_size`: `[3, 3]` for the current default dungeon test layout
- `grid_cells`: `G00_00` through `G02_02`
- `edge_records`: numbered logical edge slots such as `E_G00_01_E`, `E_G01_01_N`
- `anchor_cell`: the cell each edge belongs to
- `connected_sides`: edges that must stay open
- `blocked_sides`: edges that must show wall or cap
- `layer`: `wall_back` or `wall_front`
- `final_manifest_path`: `data/dungeon_quarter/tile_variant_manifest.json` and `data/dungeon_quarter/asset_manifest.json`

Generated or sliced contact sheets must show the edge record numbers.

## Required Tests

The smoke test must verify:

- every closed edge resolves to a wall atlas key,
- every connected edge resolves to no closed wall and a doorway/bridge where appropriate,
- every open placeholder edge resolves to a placeholder cap,
- no missing wall atlas key exists for `N/E/S/W`,
- disconnecting a room creates placeholder caps and removes walkable edge connections,
- default 3x3 layout has visible closed walls around unconnected sides.

## 2026-07-05 Implementation Update

The first rule-based wall edge pass has been implemented.

- Image contract: `docs/IMAGEGEN_CONTRACT_WALL_EDGE_ATLAS_CAVE_F_01.md`
- Work log: `docs/WORK_LOG_2026-07-05_WALL_EDGE_ATLAS.md`
- Generated built-in GPT Image 2 source:
  - `output/imagegen/wall_edge_atlas_cave_f_01_source.png`
  - `output/imagegen/wall_edge_atlas_cave_f_01_alpha.png`
- Sliced wall assets:
  - `assets/tiles/cave_v2/wall_edges`
- Slicer:
  - `tools/slice_wall_edge_atlas.py`

Implemented renderer behavior:

- closed walls are now calculated from logical floor edges,
- connected edges do not emit closed wall records,
- shared adjacent closed edges are de-duplicated through canonical `N/W` ownership,
- endpoint joins select `straight`, `end_a`, `end_b`, or `cap`,
- `N/W` walls render in `BackWallLayer`,
- `E/S` walls render in `FrontWallLayer`.

Current default 3x3 result:

- 14 logical closed sides in the room contract,
- 12 rendered physical wall edge records after de-duplication.

Verified on 2026-07-05:

- `godot --headless --path . --import`: PASS
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: PASS
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: PASS
- `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS

Remaining risk:

- The current atlas is visually strong and readable, but wall scale/anchor offsets may still need review after user feedback.
- Corner accent sprites are generated and registered, but the renderer currently uses endpoint joins to choose side variants; separate corner overlay drawing can be added later if needed.

