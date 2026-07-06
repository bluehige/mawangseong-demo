# 2026-07-06 Reference 6-Room Grid Conversion

## Session Compass

We are building a playable Demon King castle dungeon demo, not a decorative background. The dungeon must be assembled from quarter-view cells, floor tiles, wall/edge/door rules, room-role objects, and walkable cell data. The immediate goal is to complete the dungeon objects, complete the required rooms, connect them into a finished demo dungeon, and verify it in Godot.

## User Correction

The user clarified that the reference image's "one room" should be treated as one large grid-room module. The desired default castle is six large room grids:

- throne room,
- barracks,
- recovery nest,
- entrance,
- treasure storage,
- buildable slot.

The path/corridor connecting those rooms is part of the completed room layout, but it is not another room-grid slot. The previous implementation still treated one room as one tiny cell, so walls, props, units, and labels competed for the same visual center.

## Decision

Keep the quarter-view logical grid system, but change the default layout contract:

- A room-grid slot is now a multi-cell room module.
- Each visible room uses a `3x3` internal footprint.
- `spike_corridor` remains as a locked path/trap connector module, not a room-grid cell.
- `watch_post` is no longer a default room. It remains only as a constructible facility option.

## Layout Coordinates

Default layout: `current_demo_v2_master_grid_01`

Contract: `reference_6_room_grid_with_paths_01`

Castle grade remains `E`, so all floor cells fit inside the active rect `[5, 5, 10, 10]`.

Room-grid modules:

- `throne`: module `room_throne_01`, grid `G01_00`, origin `[9, 5]`, size `3x3`.
- `barracks`: module `room_barracks_01`, grid `G00_01`, origin `[5, 8]`, size `3x3`.
- `recovery`: module `room_recovery_01`, grid `G02_01`, origin `[12, 8]`, size `3x3`.
- `entrance`: module `room_entrance_01`, grid `G00_02`, origin `[5, 12]`, size `3x3`.
- `slot_01`: module `room_empty_slot_01`, grid `G01_02`, origin `[9, 12]`, size `3x3`.
- `treasure`: module `room_treasure_01`, grid `G02_02`, origin `[12, 12]`, size `3x3`.

Path module:

- `spike_corridor`: module `corridor_spike_ns_01`, grid `PATH_MAIN`, origin `[6, 8]`, size `8x4`.

Connections:

- `throne:to_s` <-> `spike_corridor:to_n`
- `barracks:to_e` <-> `spike_corridor:to_w_upper`
- `recovery:to_w` <-> `spike_corridor:to_e_upper`
- `entrance:to_n` <-> `spike_corridor:to_s_left`
- `slot_01:to_n` <-> `spike_corridor:to_s_mid`
- `treasure:to_n` <-> `spike_corridor:to_s_right`

## Files Changed

- `data/dungeon_quarter/room_blueprints.json`
  - Converted major room blueprints from `1x1` to `3x3`.
  - Converted `corridor_spike_ns_01` into an `8x4` connector path with six sockets.
  - Added `theme` and `default_socket_states` to keep validator contract intact.
  - Corrected object slot IDs to prop/trap IDs such as `throne_f` and `spike_floor`.
- `data/dungeon_quarter/starting_layout.json`
  - Replaced old 8-room compact chain with the six-room reference layout plus path module.
- `data/dungeon_quarter/custom_layouts.json`
  - Updated `expanded_right_branch_layout_01` to the same six-room/path contract.
- `data/rooms.json`
  - Updated display names and exits to match the new path graph.
  - Removed `watch_post` as a default room entry.
- `scripts/dungeon_quarter/ModuleGraph.gd`
  - Facility-generated objects now anchor at the center of a multi-cell room.
  - Facility object footprints now span the room module footprint for better scaling.
- `scripts/ui/HUDController.gd`
  - Room list now shows the six room-grid rooms only.
- `tools/QuarterModuleSmokeTest.gd`
  - Updated schema, socket, renderer, and map-editor expectations for the new six-room contract.

This work builds on the earlier visual readability changes in:

- `data/dungeon_quarter/asset_manifest.json`
- `scripts/dungeon_quarter/QuarterDungeonRenderer.gd`
- `scripts/game/GameRoot.gd`
- `scripts/game/CombatSceneController.gd`
- `scripts/map/DungeonRenderer.gd`
- `scripts/units/Unit.gd`

## Verification

Commands run:

```powershell
python -m json.tool data\rooms.json
python -m json.tool data\dungeon_quarter\room_blueprints.json
python -m json.tool data\dungeon_quarter\starting_layout.json
python -m json.tool data\dungeon_quarter\custom_layouts.json
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

## Current Object-System Status

The object system now supports the current reference-style six-room demo better than the old compact pass:

- six large room modules,
- one central path/trap module,
- facing prop sprites,
- placement clamps,
- room-scale object slot footprints,
- smaller unit and effect overlays.

It is still not a production-complete large-castle interior system. The visual style still uses tiled floors, doorway caps, wall edges, and existing prop sprites; the next quality pass should tune room/platform art and object anchors after the user accepts the room-scale interpretation.

## Remaining Risks

- Door/socket caps are visually prominent because each room connects through a large doorway marker.
- The path module is logically correct but still uses the same floor tile language as rooms; if the user wants stronger "corridor" readability, tune corridor floor/edge visuals instead of shrinking rooms back down.
- `watch_post` remains available as a buildable facility choice, but it is no longer a default room-grid slot.

## Next Concrete Step

Open `tmp/manual_verification/01_management.png` with the user and confirm the room-scale interpretation first. If accepted, the next pass should tune visual hierarchy: corridor floor readability, doorway cap scale, and object anchors. Do not revert to the old "one room = one tiny tile" model.
