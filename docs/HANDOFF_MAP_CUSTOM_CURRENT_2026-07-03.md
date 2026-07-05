# Map Custom Current Handoff - 2026-07-03

This handoff is mandatory for every resumed, compressed, or new Codex session in the current map-custom work.

## Read Order Before Any Work

Before making changes, the next agent must read this file first, then read the relevant reference material below. Do not start from memory.

1. `docs/HANDOFF_MAP_CUSTOM_CURRENT_2026-07-03.md`
2. `docs/PLAN_2026-07-03_MAP_CUSTOM_ONLY.md`
3. `docs/WORK_LOG_2026-07-03_QUARTERVIEW_CUSTOM_LAYOUTS.md`
4. `docs/WORK_LOG_2026-07-03_SMALL_DUNGEON_OBJECTS.md`
5. `docs/WALL_EDGE_ATLAS_RULE_2026-07-03.md`
6. `docs/WORK_LOG_2026-07-05_WALL_EDGE_ATLAS.md`
7. `docs/IMAGEGEN_CONTRACT_CAVE_F_FLOOR_EDGE_ATLAS_01.md`
8. `docs/WORK_LOG_2026-07-05_CAVE_GRAPHIC_RESOURCE_AUDIT.md`
9. `docs/IMAGEGEN_CONTRACT_CAVE_OBJECT_ATLAS_01.md`
10. `docs/WORK_LOG_2026-07-05_CAVE_OBJECT_ATLAS.md`
11. `docs/WORK_LOG_2026-07-06_DEMO_DUNGEON_COMPLETION_DIRECTIVE.md`
12. `docs/IMAGEGEN_CONTRACT_CAVE_OBJECT_FACING_ATLASES_01.md`
13. `docs/WORK_LOG_2026-07-06_OBJECT_FACING_AND_COMPLETE_DUNGEON.md`
14. `docs/WORK_LOG_2026-07-06_OBJECT_PLACEMENT_RULE.md`
15. Optional original reference folder, if available on the current PC:
   `C:\Users\LDK-6248\Desktop\AI개발\어시스트프로젝트\마왕성\참고자료\mawang_quarterview_tilegrid_v2_docs\mawang_quarterview_tilegrid_v2`
16. In that reference folder, read the relevant docs for the task if the folder exists. If it does not exist on the current PC, continue from the in-repo handoff, contracts, and work logs above. For map structure/image work, minimum read set:
   - `docs/08_COPYPASTE_FOR_CODEX.txt`
   - `docs/00_README.md`
   - `docs/01_CORE_SYSTEM_RULES.md`
   - `docs/03_16_TILE_MASK_RULES.md`
   - `docs/04_BACKGROUND_VOID_UNCONNECTED_RULES.md`
   - `docs/06_CODEX_IMPLEMENTATION_SPEC.md`
   - `templates/room_blueprint_v2.json`
   - `templates/tile_mask_mapping.json`

## Mandatory Session Compass - 2026-07-06

Every resumed, compressed, or new session must restate this before doing work:

> We are building a playable Demon King castle dungeon demo, not a decorative background. The dungeon must be assembled from quarter-view cells, floor tiles, wall/edge/door rules, room-role objects, and walkable cell data. The immediate goal is to complete the dungeon objects, complete the required rooms, connect them into a finished demo dungeon, and verify it in Godot.

Beginner translation: the map is data first. Art is attached to the data. A pretty single image is not the dungeon.

## Mandatory Handoff Writing Rule - 2026-07-06

Before writing or updating a handoff, check the existing example/reference documents:

- `mawang_guideline_pack/docs/01_SESSION_START_COMMANDS.md`
- `mawang_guideline_pack/docs/06_DECISION_LOG_TEMPLATE.md`
- `docs/HANDOFF_DEMO_FOUNDATION.md`
- `docs/HANDOFF_NEXT_SESSION_QUARTERVIEW_VARIANTS_2026-07-02.md`

If a reference document is mojibake/partially unreadable, still preserve the readable structure:

1. current goal and latest decision,
2. files changed this session,
3. completed features,
4. commands run and verification results,
5. unfinished or deferred items,
6. first task for the next session,
7. risks and files not to disturb,
8. exact start sentence for the next session.

Every handoff update from now on must explicitly include this Session Compass, this Handoff Writing Rule, the current object-system limitation or completion status, and the next concrete dungeon-completion step.

## Non-Negotiable Map Principle

The logical grid is the real dungeon.

- Rooms occupy grid cells.
- Each room cell has a room role, object placement, and N/E/S/W connection state.
- Connected sides render as paths/openings.
- Unconnected sides render as walls, blocked rock, or are hidden only for readability.
- Background cave/dungeon art is atmosphere only. It must not decide navigation, wall state, object placement, or collision.

## Mandatory Grid-Position Contract For Image Generation

Before generating any map image, tile sheet, prop sheet, background plate, wall/path piece, or room object with built-in GPT Image 2, define the grid position contract first.

Every generated image request must include a numbered placement spec:

- `asset_id`: stable ID, for example `bg_cave_f_3x3_01`, `room_throne_cell_2_0`, `path_n_to_s_01`.
- `grid_size`: total logical grid size the image is designed to sit on, for example `[3, 3]`, `[8, 8]`, `[20, 20]`.
- `grid_cells`: numbered cells the image occupies or decorates. Use `Gxx_yy` format, for example `G00_00`, `G01_00`, `G02_00`.
- `anchor_cell`: the main cell used for placement.
- `connected_sides`: N/E/S/W openings this asset must visually respect.
- `blocked_sides`: N/E/S/W walls/rock/hidden sides this asset must visually respect.
- `layer`: `background`, `floor`, `path`, `wall_back`, `object_back`, `object_front`, `wall_front`, or `fx`.
- `final_manifest_path`: where the slice or final image will be referenced.

For asset sheets, each tile/prop region must be numbered before generation and kept in the slicing manifest. A final visual contact sheet must show the numbers so the user can verify placement.

Do not generate a "nice dungeon image" first and decide grid placement afterward. Grid placement and numbering come first.

## GPT Image 2 Rule

In this project, `GPT Image 2` means Codex built-in `image_gen`.

- Do not use API/CLI fallback.
- Do not ask for `OPENAI_API_KEY`.
- Do not replace requested raster assets with procedural/vector/code-drawn placeholder art.
- Code may only copy, crop, remove alpha/chroma, slice, resize, import to Godot, and wire manifests for built-in generated images.

## Current Visual Bar

Do not call map work complete just because manifests load or automated tests pass.

Completion requires a visual capture where:

- grid-space room roles are readable,
- connected paths are visible,
- unconnected sides read as walls/blocked/hidden,
- entrance, trap, barracks, recovery, treasure, throne, build slot, and watch post objects are visible when their room/facility is active,
- movement still follows grid/walkable data, not background art.

Required verification commands:

```powershell
godot --headless --path . --import
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --path . --run res://tools/ManualVerificationCapture.tscn
```

## Current Implemented State - 2026-07-03

The old hub-style default layout has been overwritten with the new room-grid process.

- Default layout: `current_demo_v2_master_grid_01`
- Contract ID: `cave_f_3x3_chain_01`
- Grid size: `3x3`, mapped into the 20x20 master grid at `master_origin: [8, 8]`
- Main sequence: `entrance -> spike_corridor -> barracks -> recovery -> treasure -> throne`
- Occupied default cells:
  - `G00_01`: `entrance`, connected `E`
  - `G01_01`: `spike_corridor`, connected `W,E`
  - `G02_01`: `barracks`, connected `W,N`
  - `G02_00`: `recovery`, connected `S,W`
  - `G01_00`: `treasure`, connected `E,W`
  - `G00_00`: `throne`, connected `E`
- Empty default cells: `G00_02`, `G01_02`, `G02_02`
- Custom sample layout: `expanded_right_branch_layout_01`
  - Same main chain.
  - Adds `slot_01` at `G01_02`, connected north to `spike_corridor`.

Runtime and data changes:

- `data/dungeon_quarter/room_blueprints.json` now defines 1-cell rooms with N/E/S/W sockets.
- `data/dungeon_quarter/starting_layout.json` embeds the numbered room-grid contract.
- `data/dungeon_quarter/custom_layouts.json` embeds the expanded slot contract.
- Facility/room objects no longer block the whole cell; they sit inside the room cell.
- `center` remains only as a legacy data key/icon reference. It is not part of the default path.
- Display names in JSON files use ASCII `\u` escapes where needed. Godot renders them as Korean, while PowerShell JSON checks remain stable. The structure IDs are the source of truth.

Latest verification on 2026-07-03:

- `godot --headless --path . --import`: PASS
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`
- `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS

Latest visual captures:

- `tmp/manual_verification/01_management.png`
- `tmp/manual_verification/01_map_editor.png`
- `tmp/manual_verification/01_watch_post_facility.png`

## Current Background Plate State - 2026-07-03

The current 3x3 default dungeon now uses a built-in GPT Image 2 background plate as atmosphere under the logical grid.

- Image generation contract: `docs/IMAGEGEN_CONTRACT_BG_CAVE_F_3X3_01.md`
- Generated asset path: `assets/backgrounds/v2/bg_cave_f_3x3_01.png`
- Manifest entry: `data/dungeon_quarter/asset_manifest.json`, key `backgrounds.bg_cave_f_3x3_01`
- Renderer: `scripts/dungeon_quarter/QuarterDungeonRenderer.gd`
- Layer: `BackgroundVoidLayer`
- Role: atmosphere/void fill only. It does not define walkable cells, paths, walls, sockets, exposed edges, collisions, or room placement.

Visual adjustment made after capture review:

- Active non-floor rock cells are drawn as a translucent grid over the background plate instead of an opaque black platform.
- This keeps the buildable grid readable while allowing the cave/dungeon background to remain visible.
- The real rooms, connected paths, walls, sockets, and objects are still rendered by the logical grid layers above the background.

Latest verification after this background pass:

- `godot --headless --path . --import`: PASS
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`
- `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS

Latest visual captures after the background pass:

- `tmp/manual_verification/01_management.png`
- `tmp/manual_verification/01_map_editor.png`

## Current Socket Wall / Object Rule - 2026-07-03

Socket state now has an explicit visual object rule in addition to floor mask and edge rules.

- `connected`
  - Opens the N/E/S/W edge in `ModuleGraph.open_edge_set`.
  - Draws a doorway cap from `asset_manifest.socket_caps.connected`.
  - Draws a visible connection bridge between the connected socket pair.
  - Movement may pass only because the edge is open in logical grid data.
- `open_placeholder`
  - Does not open the edge and does not count toward the floor mask.
  - Draws a build-slot/foundation cap from `asset_manifest.socket_caps.open_placeholder`.
  - Used by the map editor when an existing connection is disconnected.
- `closed`
  - Does not open the edge and does not count toward the floor mask.
  - Draws a wall cap from `asset_manifest.socket_caps.closed`.
  - This is the rule the user requested: if a path is not connected, that object/room side receives a wall or blocked cap.

Layer behavior:

- N/W socket caps render in the back wall pass before room objects.
- E/S socket caps render in the front wall pass after room objects.
- This keeps walls readable without changing room-role object placement or walkable data.

Latest verification after this socket wall pass:

- `godot --headless --path . --import`: PASS
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`
- `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS

Latest visual captures after the socket wall pass:

- `tmp/manual_verification/01_management.png`
- `tmp/manual_verification/01_map_editor_disconnected.png`

Important correction after user review:

- The current wall pass is not a complete edge-continuous wall atlas.
- Current `wall_cave_v2_mask_00~15` assets repeat two straight wall images and must not be treated as real directional wall-mask variants.
- The next wall task must follow `docs/WALL_EDGE_ATLAS_RULE_2026-07-03.md`.
- Do not keep freely reusing one wall image across logical sides unless the manifest explicitly declares that alias.

2026-07-05 update:

- A first rule-based wall edge atlas pass has been implemented.
- Built-in GPT Image 2 source and sliced assets:
  - `output/imagegen/wall_edge_atlas_cave_f_01_source.png`
  - `output/imagegen/wall_edge_atlas_cave_f_01_alpha.png`
  - `assets/tiles/cave_v2/wall_edges`
- Contract and work log:
  - `docs/IMAGEGEN_CONTRACT_WALL_EDGE_ATLAS_CAVE_F_01.md`
  - `docs/WORK_LOG_2026-07-05_WALL_EDGE_ATLAS.md`
- Renderer now calculates closed wall edge records from `open_edge_set` and the floor grid.
- Default 3x3 layout emits 12 de-duplicated rendered wall edge records.
- Remaining risk is visual tuning of wall scale/anchor offsets, not the basic logical wall/no-wall rule.

2026-07-05 cave graphic resource audit and first assembly update:

- Work log:
  - `docs/WORK_LOG_2026-07-05_CAVE_GRAPHIC_RESOURCE_AUDIT.md`
- Contract:
  - `docs/IMAGEGEN_CONTRACT_CAVE_F_FLOOR_EDGE_ATLAS_01.md`
- Built-in GPT Image 2 sources and sliced outputs:
  - `output/imagegen/floor_mask_atlas_cave_f_01_source.png`
  - `output/imagegen/floor_mask_atlas_cave_f_01_alpha.png`
  - `output/imagegen/floor_mask_atlas_cave_f_01_sliced_preview.png`
  - `output/imagegen/edge_corner_atlas_cave_f_01_source.png`
  - `output/imagegen/edge_corner_atlas_cave_f_01_alpha.png`
  - `output/imagegen/edge_corner_atlas_cave_f_01_sliced_preview.png`
  - `output/imagegen/spike_floor_v2_trap_sheet_01_source.png`
  - `output/imagegen/spike_floor_v2_trap_sheet_01_alpha.png`
  - `output/imagegen/spike_floor_v2_trap_sheet_01_sliced_preview.png`
- New slicers:
  - `tools/slice_cave_floor_edge_atlas.py`
  - `tools/slice_spike_trap_sheet.py`
- Final resource audit:
  - `floor`: 16 files, 16 unique, no empty alpha.
  - `edge`: 4 files, 4 unique, no empty alpha.
  - `overlay`: 8 files, 8 unique, no empty alpha.
  - `wall_edges`: 32 files, 32 unique, no empty alpha.
  - `spike`: 5 files, 5 unique, no empty alpha.
- Renderer now loads and draws corner overlays in addition to floor masks, edge lips, wall edges, socket caps, props, units, and trap frames.
- `assets/props/v2/trap_spike_v2_idle_00.png` and `trap_spike_v2_trigger_00.png` are no longer duplicate bitmaps.
- Latest captures after first assembly:
  - `tmp/manual_verification/01_management.png`
  - `tmp/manual_verification/01_map_editor_disconnected.png`
  - `tmp/manual_verification/04_combat_trap_trigger.png`

2026-07-05 room object atlas update:

- Contract:
  - `docs/IMAGEGEN_CONTRACT_CAVE_OBJECT_ATLAS_01.md`
- Work log:
  - `docs/WORK_LOG_2026-07-05_CAVE_OBJECT_ATLAS.md`
- Built-in GPT Image 2 source and sliced outputs:
  - `output/imagegen/cave_object_atlas_01_source.png`
  - `output/imagegen/cave_object_atlas_01_alpha.png`
  - `output/imagegen/cave_object_atlas_01_sliced_preview.png`
  - `output/imagegen/cave_object_atlas_01_room_icon_preview.png`
- New slicer:
  - `tools/slice_cave_object_atlas.py`
- Final prop sprites:
  - `assets/props/v2/prop_entrance_gate_v2_back.png`
  - `assets/props/v2/prop_throne_v2_back.png`
  - `assets/props/v2/prop_throne_v2_front.png`
  - `assets/props/v2/prop_weapon_rack_v2_back.png`
  - `assets/props/v2/prop_treasure_pile_v2_front.png`
  - `assets/props/v2/prop_recovery_nest_v2_front.png`
  - `assets/props/v2/prop_foundation_marks_v2_back.png`
  - `assets/props/v2/prop_watch_post_v2_front.png`
  - `assets/props/v2/prop_small_brazier_v2_back.png`
- Room selection UI icons in `assets/ui/room_v2` were regenerated from the same prop set.
- Renderer prop scales were tuned so throne, barracks, treasure, recovery, watch post, entrance, brazier, and build slot are readable in the assembled cave map.
- The generated object sprites are role markers only; they do not define room connectivity, walls, movement, or collision.
- Important limitation: runtime uses sliced individual prop PNGs, not one big atlas image, but the object system is still mostly one visual variant per room role.
- The next object pass must add direction/position-aware variants before the same facility types are reused freely across many grid positions.
- Required next object rule: select sprites by `prop_id + facing + layer`, not only by `prop_id + layer`.
- Large or wall-adjacent objects must declare `NW`, `NE`, `SE`, `SW`, or `directionless`; do not silently reuse one image in every orientation.
- Latest captures after the object pass:
  - `tmp/manual_verification/01_management.png`
  - `tmp/manual_verification/01_watch_post_facility.png`

## Current Implemented State - 2026-07-06 Complete Demo Dungeon Pass

This section supersedes the older 6-room default-chain notes above.

The default layout is now an 8-room connected cave Demon King castle demo:

- Default layout: `current_demo_v2_master_grid_01`
- Contract ID: still `cave_f_3x3_chain_01` for compatibility with existing tests, but the current content is a complete 3x3 demo pass.
- Castle grade: `E`
- Grid size: `3x3`, mapped into the 20x20 master grid.
- Occupied cells:
  - `G00_00`: `throne`, connected `E`, object facing `SW`.
  - `G01_00`: `treasure`, connected `E,W`, object facing `SW`.
  - `G02_00`: `recovery`, connected `S,W`, object facing `SW`.
  - `G00_01`: `entrance`, connected `E`, object facing `SE`.
  - `G01_01`: `spike_corridor`, connected `W,E,S`.
  - `G02_01`: `barracks`, connected `W,N,S`, object facing `SW`.
  - `G01_02`: `slot_01`, connected `N,E`, object facing `NE`.
  - `G02_02`: `watch_post`, connected `N,W`, object facing `SW`.
- Empty cells:
  - `G00_02`
- Main route:
  - `entrance -> spike_corridor -> barracks -> recovery -> treasure -> throne`
- Support/build branch:
  - `spike_corridor -> slot_01 -> watch_post -> barracks`

Room-role objects now resolve by `prop_id + facing + layer`:

- Contract:
  - `docs/IMAGEGEN_CONTRACT_CAVE_OBJECT_FACING_ATLASES_01.md`
- Work log:
  - `docs/WORK_LOG_2026-07-06_OBJECT_FACING_AND_COMPLETE_DUNGEON.md`
- Generated/sliced preview:
  - `output/imagegen/cave_object_facing_atlases_01_sliced_preview.png`
- Final v3 object sprites:
  - `assets/props/v3/`
- Runtime changes:
  - `data/dungeon_quarter/asset_manifest.json` contains `facing_sprites`.
  - `scripts/dungeon_quarter/ModuleGraph.gd` assigns object facings from layout data or role fallback.
  - `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` selects facing sprites before legacy one-variant props.
  - `scripts/units/Unit.gd` now chooses a better walkable detour around blocking units.

Current object-system completion status:

- Complete enough for the demo-complete dungeon pass.
- Direction variants exist for throne, barracks, treasure, recovery, entrance, watch post, build-slot foundation, and brazier.
- v2 props remain as fallback.
- Not yet a production-complete large-castle prop system. Future larger maps should add more variants per room size and wall adjacency.

Latest verification on 2026-07-06:

- JSON checks for `asset_manifest`, `starting_layout`, `custom_layouts`, `room_blueprints`, and `rooms`: PASS.
- `python -m py_compile tools\slice_cave_object_facing_atlases.py`: PASS.
- `godot --headless --path . --import`: PASS.
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`.
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`.
- `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS.

Latest visual captures after the complete demo dungeon pass:

- `tmp/manual_verification/01_management.png`
- `tmp/manual_verification/01_watch_post_facility.png`
- `tmp/manual_verification/03_combat_start.png`
- `tmp/manual_verification/04_combat_trap_trigger.png`
- `tmp/manual_verification/06_result.png`

2026-07-06 object placement rule update:

- Work log:
  - `docs/WORK_LOG_2026-07-06_OBJECT_PLACEMENT_RULE.md`
- Root cause:
  - Direction-aware sprites existed, but placement rules were incomplete.
  - The renderer knew `cell`, `layer`, and `facing`, but not prop foot anchor, allowed width, allowed height, bottom offset, or multi-layer permission.
  - Generated sprites with stone bases were therefore treated like generic full-cell images and could visually collide with walls or neighboring room art.
- New rule:
  - Room-role objects must use manifest `placement` data.
  - `placement.fit_width`, `bottom_offset`, `x_offset`, and `max_height` define how the sprite is fitted onto the cell.
  - Props that intentionally render more than one layer must declare `stack_layers`.
- Runtime changes:
  - `data/dungeon_quarter/asset_manifest.json` now contains placement rules for the current room-role props.
  - `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` reads placement data and limits object draw size.
  - Front room-role objects are drawn after front walls in the current 1-cell demo layout so role objects remain readable.
- Verification:
  - `python -m json.tool data\dungeon_quarter\asset_manifest.json`: PASS.
  - `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`.
  - `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`.
  - `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS.
- Remaining visual risk:
  - The demo still uses 1-cell rooms with tall wall-edge art, so dense combat views can still feel crowded.
  - If the user rejects density, the correct next fix is to expand important rooms to multi-cell interiors or tune wall height/opacity, not to generate unrelated replacement props.

2026-07-06 follow-up single-cell occupancy clamp:

- User feedback:
  - The first placement-rule pass still looked too overlapped.
  - A grid cell should not visually carry several large objects.
- Additional rule:
  - One global grid cell may keep only one primary room-role object slot.
  - Static room-role props must be clamped to cell-safe width/height at draw time.
  - Wall edges are edge markers, not additional full-cell objects, so wall-edge draw scale and opacity must stay lower than room-role object scale.
  - Management monster previews are unit markers, not room-role objects, so they must stay smaller than props.
- Runtime changes:
  - `ModuleGraph.gd` now tracks `occupied_object_cells` and skips duplicate object slots on the same global cell.
  - `QuarterDungeonRenderer.gd` clamps object `fit_width`, `max_height`, and `bottom_offset`, and reduces wall-edge scale/opacity.
  - `asset_manifest.json` placement values were tightened for all current room-role props.
  - `DungeonRenderer.gd` and `GameRoot.gd` reduced management preview/spawn marker offsets and size.
- Verification:
  - `python -m json.tool data\dungeon_quarter\asset_manifest.json`: PASS.
  - `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`.
  - `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: exit code 0.
  - `godot --path . --run res://tools/ManualVerificationCapture.tscn`: exit code 0, captures updated.
- Honest remaining limitation:
  - This reduces overdraw, but it does not fully solve the 1-cell-room density problem.
  - The next real quality jump is to convert important rooms from "one room = one cell" to "one room = multiple internal cells" so props, units, and walkable cells do not compete for the same visual center.

First task next session:

1. Restate the Mandatory Session Compass.
2. Open `tmp/manual_verification/01_management.png` and `tmp/manual_verification/03_combat_start.png` with the user.
3. If the user accepts the current dungeon pass, move to the next gameplay priority.
4. If the user rejects it visually, tune wall/object scale, object anchors, and per-room readability before adding unrelated systems.

## Next Work Direction

The correct direction is not "make more floor art."

The correct direction is:

1. Define room cells in the logical grid.
2. Define N/E/S/W connections per cell.
3. Render connected sides as readable paths/openings.
4. Render unconnected sides as walls/rock/hidden boundaries.
5. Place room-role objects inside their grid cell without filling the whole cell.
6. Use a cave/dungeon background plate under the grid for atmosphere only.
7. Generate any new image asset only after the numbered grid-position contract is written.
8. For room-role objects, keep using explicit facing/position variants before using the same facility type in arbitrary places.
