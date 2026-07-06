# 2026-07-06 4x4 / 5x5 Grid Prototype

## Session Compass

We are building a playable Demon King castle dungeon demo, not a decorative background. The dungeon must be assembled from quarter-view cells, floor tiles, wall/edge/door rules, room-role objects, and walkable cell data. The immediate goal is to complete the dungeon objects, complete the required rooms, connect them into a finished demo dungeon, and verify it in Godot.

## User Rule Implemented

Correction note: this log records the first 4x4/5x5 prototype. It was superseded later on 2026-07-06 by `docs/WORK_LOG_2026-07-06_FULL_GRID_ROOM_OBJECTS.md`, after the user clarified that one room/building object must occupy the whole `5x5` macro grid, not a centered `3x3` area.

The user proposed a clearer novice dungeon construction rule:

- Demon King castle novice dungeon = `4x4` macro grid.
- One macro grid = `5x5` master cells.
- One main room object = `3x3` cells.
- One path/opening = `2x2` cells.
- Walls and decoration objects can use `1xN` cell strips.

This pass implements that as data and renderer-compatible logic.

## Decision

Use the first model, not "one grid equals one object."

The implemented contract is:

- `1 macro grid = 1 room module area`.
- A room module is `5x5` internal cells.
- The room's primary facility prop is centered in a `3x3` footprint.
- Room-to-path openings are represented by paired sockets, for example `to_e_u` and `to_e_d`.
- The central path/trap module is `5x10`, spanning two macro grid rows, with a two-cell-wide spine and two-cell-wide branches.
- `spike_corridor` remains the gameplay trap/path connector, but it is not counted as one of the six room-grid rooms.

## Layout

Default layout: `current_demo_v2_master_grid_01`

Contract: `novice_4x4_grid_5x5_cells_01`

Technical active area:

- `castle_grade` is currently set to `S` only to activate the full `20x20` grid.
- This is a technical workaround. Product naming says novice dungeon through `layout_label`, so the layout selector does not expose `S급` to the player.
- Future cleanup should decouple "beginner dungeon size" from the old grade active-rect naming, or add a beginner rule with full 20x20 active cells.

Macro grid placements:

- `G01_00`, origin `[5, 0]`: `throne`, module `room_throne_01`, size `5x5`.
- `G00_01`, origin `[0, 5]`: `barracks`, module `room_barracks_01`, size `5x5`.
- `G02_01`, origin `[10, 5]`: `recovery`, module `room_recovery_01`, size `5x5`.
- `G00_02`, origin `[0, 10]`: `entrance`, module `room_entrance_01`, size `5x5`.
- `G02_02`, origin `[10, 10]`: `treasure`, module `room_treasure_01`, size `5x5`.
- `G01_03`, origin `[5, 15]`: `slot_01`, module `room_empty_slot_01`, size `5x5`.
- `PATH_MAIN`, origin `[5, 5]`: `spike_corridor`, module `corridor_spike_ns_01`, size `5x10`, spans `G01_01` and `G01_02`.

Paired socket connections:

- `throne:to_s_l` <-> `spike_corridor:to_n_l`
- `throne:to_s_r` <-> `spike_corridor:to_n_r`
- `barracks:to_e_u` <-> `spike_corridor:to_w_upper_u`
- `barracks:to_e_d` <-> `spike_corridor:to_w_upper_d`
- `recovery:to_w_u` <-> `spike_corridor:to_e_upper_u`
- `recovery:to_w_d` <-> `spike_corridor:to_e_upper_d`
- `entrance:to_e_u` <-> `spike_corridor:to_w_lower_u`
- `entrance:to_e_d` <-> `spike_corridor:to_w_lower_d`
- `treasure:to_w_u` <-> `spike_corridor:to_e_lower_u`
- `treasure:to_w_d` <-> `spike_corridor:to_e_lower_d`
- `slot_01:to_n_l` <-> `spike_corridor:to_s_l`
- `slot_01:to_n_r` <-> `spike_corridor:to_s_r`

## Files Changed

- `data/dungeon_quarter/room_blueprints.json`
  - Major room modules are now `5x5`.
  - Room sockets are now paired two-cell openings.
  - `corridor_spike_ns_01` is now `5x10` with a two-cell-wide path spine/branches.
- `data/dungeon_quarter/starting_layout.json`
  - Default layout converted to `novice_4x4_grid_5x5_cells_01`.
- `data/dungeon_quarter/custom_layouts.json`
  - Custom sample layout mirrors the new 4x4/5x5 structure.
- `data/dungeon_quarter/asset_manifest.json`
  - Background metadata updated from 3x3 to 4x4.
- `data/rooms.json`
  - Static room metadata updated to `5x5` room sizes and current exits.
- `scripts/dungeon_quarter/ModuleGraph.gd`
  - Facility object footprints now cap at centered `3x3` instead of spanning the whole room.
  - Tile visual scale can now shrink below `1.0` so full `20x20` layouts fit the viewport.
- `scripts/game/ManagementSceneController.gd`
  - Layout selector now prefers `layout_label` over raw `castle_grade`, preventing the technical `S` active-area workaround from displaying as `S급`.
- `tools/QuarterModuleSmokeTest.gd`
  - Updated schema, socket, map-editor, and renderer expectations for the 4x4/5x5 contract.

## Verification

Commands run:

```powershell
python -m json.tool data\rooms.json
python -m json.tool data\dungeon_quarter\room_blueprints.json
python -m json.tool data\dungeon_quarter\starting_layout.json
python -m json.tool data\dungeon_quarter\custom_layouts.json
python -m json.tool data\dungeon_quarter\asset_manifest.json
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --path . --run res://tools/ManualVerificationCapture.tscn
```

Results:

- JSON checks: PASS.
- `QuarterModuleSmokeTest`: `QUARTER_MODULE_SMOKE_TEST: PASS`.
- `DemoSmokeTest`: `DEMO_SMOKE_TEST: PASS`.
- Manual capture: PASS.

Updated captures:

- `tmp/manual_verification/01_management.png`
- `tmp/manual_verification/03_combat_start.png`

## Current Status

The requested construction rule is now working as a prototype:

- 4x4 macro grid exists in layout data.
- 5x5 room modules exist in blueprint data.
- 3x3 room object footprints exist for entry/core and facility-generated objects.
- 2-cell-wide paired path openings are validated by the socket validator and pathfinding.
- The full 20x20 projection now fits inside the management/combat viewport.

## Remaining Risks

- The current art assets were originally tuned for smaller rooms, so the prototype is structurally correct but still visually rough.
- Door/socket caps are repeated per socket pair; they prove the 2-cell opening logic but need a dedicated 2x2 doorway visual later.
- `castle_grade` still technically uses `S` for full active-area sizing, but UI naming is now decoupled through `layout_label`. A future data cleanup should still add an explicit beginner full-grid rule.
- Corridor floor readability should be improved with path-specific floor visuals instead of relying only on ordinary floor tiles and connection bridges.

## Next Concrete Step

Review `tmp/manual_verification/01_management.png` with the user. If this structure is accepted, the next pass should replace paired one-cell doorway caps with a proper 2x2 doorway/path visual and tune room-object anchors for the larger 5x5 rooms.
