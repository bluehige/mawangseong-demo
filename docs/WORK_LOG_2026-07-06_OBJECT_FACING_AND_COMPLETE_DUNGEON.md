# 2026-07-06 Object Facing And Complete Demo Dungeon Pass

## Session Compass

We are building a playable Demon King castle dungeon demo, not a decorative background. The dungeon must be assembled from quarter-view cells, floor tiles, wall/edge/door rules, room-role objects, and walkable cell data. The immediate goal is to complete the dungeon objects, complete the required rooms, connect them into a finished demo dungeon, and verify it in Godot.

Beginner translation: the map is data first. Art is attached to the data. A pretty single image is not the dungeon.

## Handoff References Checked

Before updating the active handoff, these reference/example documents were checked:

- `mawang_guideline_pack/docs/01_SESSION_START_COMMANDS.md`
- `mawang_guideline_pack/docs/06_DECISION_LOG_TEMPLATE.md`
- `docs/HANDOFF_DEMO_FOUNDATION.md`
- `docs/HANDOFF_NEXT_SESSION_QUARTERVIEW_VARIANTS_2026-07-02.md`

The active handoff must continue to carry the session compass, handoff writing rule, object-system status, and next concrete dungeon-completion step.

## Completed Work

- Added a built-in GPT Image 2 contract for direction-aware cave object atlases:
  - `docs/IMAGEGEN_CONTRACT_CAVE_OBJECT_FACING_ATLASES_01.md`
- Generated two chroma-key source sheets with Codex built-in `image_gen`, removed the green background, and sliced them into 36 final transparent sprites:
  - `output/imagegen/cave_object_facing_major_01_source.png`
  - `output/imagegen/cave_object_facing_major_01_alpha.png`
  - `output/imagegen/cave_object_facing_support_01_source.png`
  - `output/imagegen/cave_object_facing_support_01_alpha.png`
  - `output/imagegen/cave_object_facing_atlases_01_sliced_preview.png`
  - `assets/props/v3/`
- Added the slicer:
  - `tools/slice_cave_object_facing_atlases.py`
- Updated the prop manifest so runtime room objects can resolve by `prop_id + facing + layer`.
- Updated `ModuleGraph` so object slots carry explicit facing from room-grid data or role fallback.
- Updated `QuarterDungeonRenderer` so it loads and selects facing sprites before legacy one-variant props.
- Expanded the default dungeon layout into an 8-room complete demo structure:
  - `G00_00`: throne, connected E, throne facing SW.
  - `G01_00`: treasure, connected E/W, treasure facing SW.
  - `G02_00`: recovery, connected S/W, recovery facing SW.
  - `G00_01`: entrance, connected E, entrance facing SE.
  - `G01_01`: spike corridor, connected W/E/S.
  - `G02_01`: barracks, connected W/N/S, barracks facing SW.
  - `G01_02`: build slot/foundation, connected N/E, foundation facing NE.
  - `G02_02`: watch post, connected N/W, watch post facing SW.
- Added `watch_post` as a default room/facility in `data/rooms.json`.
- Updated `QuarterModuleSmokeTest` for the complete 8-room layout, 14 de-duplicated closed wall edges, v3 facing sprite keys, and watch-post path.
- Stabilized unit collision detours in `scripts/units/Unit.gd` by choosing the best walkable detour candidate around blocking units instead of only one side candidate.

## Current Object-System Status

The project now has a first usable direction-aware object system for demo room roles.

- Runtime supports `prop_id + facing + layer`.
- Direction variants exist for throne, barracks weapon rack, treasure, recovery, entrance gate, watch post, build-slot foundation, and brazier.
- The v2 one-variant props remain in the manifest as fallback.
- This is complete enough for the demo-complete dungeon pass, but it is not an exhaustive production asset set. Future larger castles should add more variants per room size and wall adjacency.

## Verification

Commands run:

```powershell
python -m json.tool data\dungeon_quarter\asset_manifest.json
python -m json.tool data\dungeon_quarter\starting_layout.json
python -m json.tool data\dungeon_quarter\custom_layouts.json
python -m json.tool data\dungeon_quarter\room_blueprints.json
python -m json.tool data\rooms.json
python -m py_compile tools\slice_cave_object_facing_atlases.py
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --headless --path . --import
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --headless --path . --run res://tools/DemoSmokeTest.tscn
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --path . --run res://tools/ManualVerificationCapture.tscn
```

Results:

- JSON checks: PASS.
- Python compile: PASS.
- Godot import: PASS.
- `QuarterModuleSmokeTest`: `QUARTER_MODULE_SMOKE_TEST: PASS`.
- `DemoSmokeTest`: `DEMO_SMOKE_TEST: PASS`.
- Manual capture: PASS.

Latest visual captures:

- `tmp/manual_verification/01_management.png`
- `tmp/manual_verification/01_watch_post_facility.png`
- `tmp/manual_verification/03_combat_start.png`
- `tmp/manual_verification/04_combat_trap_trigger.png`
- `tmp/manual_verification/06_result.png`

## First Task Next Session

Start by restating the Session Compass above, then open `tmp/manual_verification/01_management.png` and `tmp/manual_verification/03_combat_start.png` with the user. If the user accepts the current dungeon pass, proceed to the next gameplay priority. If the user rejects it visually, tune wall/object scale, object anchors, and per-room readability before adding unrelated systems.
