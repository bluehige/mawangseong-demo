# 2026-07-06 Visual Readability Tuning

## Session Compass

We are building a playable Demon King castle dungeon demo, not a decorative background. The dungeon must be assembled from quarter-view cells, floor tiles, wall/edge/door rules, room-role objects, and walkable cell data. The immediate goal is to complete the dungeon objects, complete the required rooms, connect them into a finished demo dungeon, and verify it in Godot.

## Handoff Rule Carried Forward

The active handoff must keep the Session Compass, the Handoff Writing Rule, the current object-system status, and the next concrete dungeon-completion step. This work log is only supporting context; `docs/HANDOFF_MAP_CUSTOM_CURRENT_2026-07-03.md` was updated too.

## Issue

The latest complete 3x3 demo dungeon passed logic tests, but the visual read still felt crowded:

- wall-edge sprites were visually competing with room-role props,
- management monster previews and combat units were too close to room centers,
- slash/impact effects could hide the compact dungeon structure in captures,
- the underlying 1-cell-room design still forces walls, props, units, and labels into the same small visual area.

## Changes

- Tightened current prop placement in `data/dungeon_quarter/asset_manifest.json`.
- Added wall-edge height clamping and lowered wall-edge scale/alpha in `scripts/dungeon_quarter/QuarterDungeonRenderer.gd`.
- Added room-specific actor anchor points in `scripts/game/GameRoot.gd`.
- Routed management previews and combat spawns through those anchors in `scripts/map/DungeonRenderer.gd` and `scripts/game/CombatSceneController.gd`.
- Reduced unit sprite/label size in `scripts/units/Unit.gd`.
- Reduced slash/impact effect scale and fade duration in `scripts/game/CombatSceneController.gd`.

## Verification

Commands run:

```powershell
python -m json.tool data\dungeon_quarter\asset_manifest.json
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --path . --run res://tools/ManualVerificationCapture.tscn
```

Results:

- Asset manifest JSON: PASS.
- `QuarterModuleSmokeTest`: `QUARTER_MODULE_SMOKE_TEST: PASS`.
- `DemoSmokeTest`: `DEMO_SMOKE_TEST: PASS`.
- Manual capture: PASS.

Updated captures:

- `tmp/manual_verification/01_management.png`
- `tmp/manual_verification/03_combat_start.png`

## Current Object-System Status

The compact demo object system is usable: facing sprites, placement clamps, single primary object occupancy, smaller actor anchors, and reduced combat effects are all wired. It is still not a production-complete large-castle prop/interior system.

## Remaining Limitation

This pass improves readability but cannot fully solve density because each important room is still one logical cell. The next real quality step is to convert important rooms into multi-cell interiors, then place walls, props, walkable points, and units on separate internal cells.
