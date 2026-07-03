# 2026-07-03 Small Dungeon Object Completion

Purpose: record the object implementation pass for the current small Demon King castle dungeon so a compressed or resumed session can continue without re-discovering the required asset rules.

## Required Object Set

Current prop IDs required by `data/dungeon_quarter/room_blueprints.json`, facility replacement, and `data/dungeon_quarter/asset_manifest.json`:

- `entrance_gate_f`
- `small_brazier`
- `throne_f`
- `treasure_pile_large`
- `weapon_rack`
- `recovery_nest_f`
- `foundation_marks`
- `watch_post`

Current trap ID:

- `spike_floor`

`watch_post` is not in the default starting layout, but it is required because the management facility menu can replace a room with the watch post role.

## Changes Made

- Re-generated the v2 project assets from the built-in GPT Image 2 source sheets through `tools/slice_quarter_v2_gpt_sheet.py`.
- Fixed `assets/props/v2/prop_throne_v2_front.png`, which was previously an empty transparent PNG.
- Updated `tools/slice_quarter_v2_gpt_sheet.py` so the throne front layer is sliced from the lower part of the built-in generated throne source.
- Updated `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` so props with both `back` and `front` manifest sprites render on both `ObjectBackLayer` and `ObjectFrontLayer`.
- Added `tmp/manual_verification/01_watch_post_facility.png` capture generation in `tools/ManualVerificationCapture.gd`.

## Verified Asset Outputs

All v2 object and trap PNGs have non-empty alpha:

- `assets/props/v2/prop_entrance_gate_v2_back.png`
- `assets/props/v2/prop_small_brazier_v2_back.png`
- `assets/props/v2/prop_throne_v2_back.png`
- `assets/props/v2/prop_throne_v2_front.png`
- `assets/props/v2/prop_weapon_rack_v2_back.png`
- `assets/props/v2/prop_recovery_nest_v2_front.png`
- `assets/props/v2/prop_foundation_marks_v2_back.png`
- `assets/props/v2/prop_treasure_pile_v2_front.png`
- `assets/props/v2/prop_watch_post_v2_front.png`
- `assets/props/v2/trap_spike_v2_idle_00.png`
- `assets/props/v2/trap_spike_v2_trigger_00.png`
- `assets/props/v2/trap_spike_v2_trigger_01.png`
- `assets/props/v2/trap_spike_v2_trigger_02.png`
- `assets/props/v2/trap_spike_v2_trigger_03.png`

Specific regression fixed:

- `prop_throne_v2_front.png`: `bbox=(2, 6, 178, 77)`, alpha coverage `0.563`

## Visual Check Files

- `tmp/manual_verification/v2_object_contact_sheet.png`
- `tmp/manual_verification/01_management.png`
- `tmp/manual_verification/01_watch_post_facility.png`
- `tmp/manual_verification/03_combat_start.png`
- `tmp/manual_verification/04_combat_trap_trigger.png`

## Verification Commands

```powershell
python -m py_compile tools\slice_quarter_v2_gpt_sheet.py
python tools\slice_quarter_v2_gpt_sheet.py
godot --headless --path . --import
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --path . --run res://tools/ManualVerificationCapture.tscn
```

All commands above passed on 2026-07-03.

## Mandatory Continuation Rules

- Before any resumed/compressed/new work in this map-custom session, read `docs/HANDOFF_MAP_CUSTOM_CURRENT_2026-07-03.md` first, then read the reference docs listed in that handoff. Do not proceed from memory.
- In this project, `GPT Image 2` means Codex built-in `image_gen`.
- Do not use API/CLI fallback, `OPENAI_API_KEY` checks, or code-drawn substitute art for map assets.
- Code may only post-process built-in generated images: copy, crop, alpha removal, slicing, resizing, Godot import, and manifest wiring.
- Before generating any map image, define and number the grid positions it will be placed on. Required fields: `asset_id`, `grid_size`, numbered `grid_cells` such as `G00_00`, `anchor_cell`, `connected_sides`, `blocked_sides`, `layer`, and `final_manifest_path`.
- For generated sheets, preserve the numbering in the slicer/manifest/contact sheet so the user can verify which generated region maps to which grid position.
- Until new facilities are added, use the Required Object Set above as the complete small-dungeon object checklist.

## 2026-07-03 Visual Correction After User Review

User review identified that the previous pass still failed the actual visual bar:

- walls were not readable,
- the connected paths did not read as paths,
- room objects were too small or buried, so barracks, throne room, and treasure storage were not obvious.

Corrections made in `scripts/dungeon_quarter/QuarterDungeonRenderer.gd`:

- Added a visible connection bridge layer for connected sockets.
- Moved connection bridge rendering after back-wall rendering so paths are not buried under wall/edge sprites.
- Switched closed N/W back-wall edges from low polygon risers to actual v2 wall PNGs where available.
- Increased room-object render scale for entrance gate, brazier, throne, treasure pile, weapon rack, recovery nest, foundation marks, spike trap, and watch post.
- Re-captured `tmp/manual_verification/01_management.png` after the correction.

Verification after this visual correction:

- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`
- `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS

Continuation rule added from this review: do not call object work complete just because assets load or manifests pass. For this map-custom session, completion must include a visual capture where walls, paths, and the room-role objects are immediately readable.

## 2026-07-03 Room-Grid Process Correction

User review clarified that the important process is the dungeon grid, not making more floor art. The implementation was corrected to follow that process.

Structural changes:

- Replaced the old hub layout with a numbered `3x3` room-grid contract in `data/dungeon_quarter/starting_layout.json`.
- Default chain is now `entrance -> spike_corridor -> barracks -> recovery -> treasure -> throne`.
- The six default occupied cells are `G00_01`, `G01_01`, `G02_01`, `G02_00`, `G01_00`, and `G00_00`.
- Each room has N/E/S/W sockets; only layout connections open paths.
- Unconnected sides remain closed and render as walls/blocked edges.
- Room-role objects sit inside the grid cell and no longer block the full room cell.
- The optional expanded layout adds `slot_01` at `G01_02` while keeping the main six-room chain.
- Runtime references to the old `center` route were moved to real rooms in the new chain.

Files changed in this correction:

- `data/dungeon_quarter/room_blueprints.json`
- `data/dungeon_quarter/starting_layout.json`
- `data/dungeon_quarter/custom_layouts.json`
- `data/rooms.json`
- `data/monsters.json`
- `scripts/dungeon_quarter/ModuleGraph.gd`
- `scripts/game/GameRoot.gd`
- `scripts/game/CombatSceneController.gd`
- `tools/QuarterModuleSmokeTest.gd`
- `tools/DemoSmokeTest.gd`

Latest verification after this correction:

- `godot --headless --path . --import`: PASS
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`
- `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS

Latest capture folder:

- `tmp/manual_verification`

## 2026-07-03 Background Plate Pass

The current 3x3 small dungeon now has a built-in GPT Image 2 background plate under the grid.

- Contract written before generation: `docs/IMAGEGEN_CONTRACT_BG_CAVE_F_3X3_01.md`
- Generated asset copied to: `assets/backgrounds/v2/bg_cave_f_3x3_01.png`
- Manifest entry added: `data/dungeon_quarter/asset_manifest.json` under `backgrounds.bg_cave_f_3x3_01`
- Renderer loading and missing-asset checks added in `scripts/dungeon_quarter/QuarterDungeonRenderer.gd`
- Smoke test assertions added in `tools/QuarterModuleSmokeTest.gd`

Important constraint:

- This background plate is only `BackgroundVoidLayer` atmosphere. It does not decide movement, path connectivity, wall state, socket state, exposed edge state, collision, or object placement.

Visual correction after capture review:

- Active non-floor rock cells now render as a translucent grid instead of an opaque black platform.
- This keeps the 20x20 active grid readable while allowing the cave background to show through.

Verification after this pass:

- `godot --headless --path . --import`: PASS
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`
- `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS

Latest visual checks:

- `tmp/manual_verification/01_management.png`
- `tmp/manual_verification/01_map_editor.png`

## 2026-07-03 Socket Wall / Object Rule Pass

User requested that room objects, walls, and paths follow the documented v2 rules, especially that a wall is raised when a path is not connected.

Implemented rule:

- `connected` socket:
  - Opens only the matching N/E/S/W logical edge.
  - Uses `asset_manifest.socket_caps.connected` doorway caps.
  - Keeps the visible connection bridge.
- `open_placeholder` socket:
  - Does not open the edge.
  - Uses `asset_manifest.socket_caps.open_placeholder` foundation/build-slot cap.
  - This is now used when map editor disconnects an existing connection.
- `closed` socket:
  - Does not open the edge.
  - Uses `asset_manifest.socket_caps.closed` wall cap.
  - This is the explicit "no connected path means wall/blocked cap on that room side" rule.

Files changed in this pass:

- `data/dungeon_quarter/asset_manifest.json`
  - Added `socket_caps.closed`, `socket_caps.open_placeholder`, and `socket_caps.connected`.
  - These reuse built-in GPT Image 2 generated wall, door, and foundation assets already present in the project.
- `scripts/dungeon_quarter/QuarterDungeonRenderer.gd`
  - Added socket cap loading and missing-asset checks.
  - Added state-based cap rendering split across back/front wall passes.
  - Added debug APIs for socket state and cap key verification.
- `tools/QuarterModuleSmokeTest.gd`
  - Added assertions for socket cap loading.
  - Added assertions that closed sockets resolve to wall caps and disconnected sockets resolve to placeholder caps.
- `tools/ManualVerificationCapture.gd`
  - Added `tmp/manual_verification/01_map_editor_disconnected.png` capture.

Verification after this pass:

- `godot --headless --path . --import`: PASS
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`
- `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS

Visual checks:

- `tmp/manual_verification/01_management.png`
- `tmp/manual_verification/01_map_editor_disconnected.png`
