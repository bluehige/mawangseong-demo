# Full-Grid Room Object Concept - 2026-07-06

Image:

- `docs/concepts/full_grid_room_object_concept_2026-07-06.png`

Purpose:

- Visual target for the corrected room-object concept.
- This is not a sliced runtime atlas yet.
- Use it as reference when authoring final room-object sprites, side-connection overlays, doorway caps, and wall/decor strips.

Current Rule To Preserve:

- Novice Demon King castle dungeon = `4x4` macro grid.
- One macro grid = `5x5` master cells.
- One room/building object occupies the whole `5x5` macro grid.
- Do not shrink room objects back to centered `3x3` props.
- The six room-grid objects are entrance, throne, barracks, recovery, treasure, and build slot.
- `spike_corridor` is a path/trap connector, not one of the six room objects.
- Paths/openings use paired two-cell sockets.
- Connected sides must change the room object's edge/opening visual state.
- A room/building object must be surrounded by walls on every unconnected outer edge.
- Only connected paired socket cells may become open doorways.
- Future image variants are wall/door variants, not just floor/path color variants.

Generated Image Prompt Summary:

- Dark fantasy demon castle cave.
- Wide quarter-view game map.
- Six full-room building objects occupying whole macro-grid cells.
- Two-cell-wide stone paths connect rooms.
- No UI, labels, logos, or text.
- Connected path sides visibly alter room edges/openings.

Next Asset Step:

- Convert this concept into deterministic game-ready assets:
  - room-object base sprites for each facility type,
  - side-connection variants or overlays for `N/E/S/W` combinations,
  - visible wall states for every closed side,
  - proper `2x2` doorway/path sprites,
  - `1xN` wall and decor strips.

## Throne + Dungeon Entrance Proof

Latest proof concept:

- `docs/concepts/full_grid_room_object_proof_throne_entrance_2026-07-06.png`
- Companion note: `docs/concepts/full_grid_room_object_proof_throne_entrance_2026-07-06.md`

Reason:

- The first production proof must not omit the dungeon entrance.
- The new proof structure includes both `throne_f` and `entrance_gate_f` before any mass generation.
- It is still a concept/proof image, not a runtime atlas and not production-approved art.

## Remaining Room Proof

Latest remaining-room proof concept:

- `docs/concepts/full_grid_room_object_proof_remaining_rooms_2026-07-06.png`
- Companion note: `docs/concepts/full_grid_room_object_proof_remaining_rooms_2026-07-06.md`

Rows:

- Barracks / `weapon_rack` / `open_02` east paired doorway.
- Recovery / `recovery_nest_f` / `open_08` west paired doorway.
- Treasure / `treasure_pile_large` / `open_08` west paired doorway.
- Build slot / `foundation_marks` / `open_01` north paired doorway.

This sheet uses the same `NW/NE/SE/SW` column order as the throne plus dungeon entrance proof. It is still a concept/proof image, not a runtime atlas and not production-approved art.

## Path Connection Proof

Latest path-connection proof concepts:

- `docs/concepts/full_grid_path_connection_layout_proof_2026-07-06.png`
- `docs/concepts/full_grid_path_connection_layout_proof_2026-07-06.md`
- `docs/concepts/full_grid_path_component_proof_2026-07-06.png`
- `docs/concepts/full_grid_path_component_proof_2026-07-06.md`

Reason:

- The dungeon should not read as rooms plus a fully filled floor plate.
- Full-grid room objects must be connected by explicit route paths.
- Empty macro cells remain cave void / unbuilt space.
- `PATH_MAIN` is a two-cell-wide path skeleton through `G01_01` and `G01_02`, with branch paths to each room doorway.

These proof images are not runtime atlases and must not be sliced until the path layout and component shapes are visually approved.

## Grid-Accurate Path Concept

Latest grid-accurate concept:

- `docs/concepts/full_grid_path_connection_grid_accurate_concept_2026-07-06.png`
- `docs/concepts/full_grid_path_connection_grid_accurate_concept_overlay_2026-07-06.png`
- Companion note: `docs/concepts/full_grid_path_connection_grid_accurate_concept_2026-07-06.md`
- Generator: `tools/generate_grid_accurate_path_concept.py`

This concept is generated from the actual layout and blueprint JSON, not freehand image generation. Use it to decide whether the current 4x4 macro placement and 5x5 path skeleton are acceptable before producing more polished art.

## Prototype Runtime Sprite Pass

Generated a 2x3 sprite-sheet source:

- `docs/concepts/full_grid_room_object_sprite_sheet_source_2026-07-06.png`

Split and keyed runtime sprites:

- `assets/props/full_grid_rooms/room_entrance_e_full_grid.png`
- `assets/props/full_grid_rooms/room_throne_s_full_grid.png`
- `assets/props/full_grid_rooms/room_barracks_e_full_grid.png`
- `assets/props/full_grid_rooms/room_recovery_w_full_grid.png`
- `assets/props/full_grid_rooms/room_treasure_w_full_grid.png`
- `assets/props/full_grid_rooms/room_build_slot_n_full_grid.png`

Runtime status:

- These six sprites are prototype-only after review.
- They fill the intended `5x5` room-object area, but they read as front-facing rectangular rooms and do not match the runtime `128x64` diamond grid projection.
- `QuarterDungeonRenderer.gd` now ignores connected room sprites unless the manifest declares `connection_sprite_projection: "iso_diamond_5x5"`.
- Missing or projection-unsafe side combinations fall back to a procedural `5x5` diamond footprint plus the existing facing prop marker.
- Future production sprites must be approved in the actual Godot capture before mass generation.
