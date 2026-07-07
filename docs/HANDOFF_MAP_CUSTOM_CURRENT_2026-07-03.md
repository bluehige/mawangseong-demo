# Map Custom Current Handoff - 2026-07-03

This handoff is mandatory for every resumed, compressed, or new Codex session in the current map-custom work.

## User Correction - Failed Visual Material Quarantine - 2026-07-06

The user explicitly corrected the session after failed/rejected visual materials were presented as if they were current examples. Treat this as a hard rule before reading the older sections below.

Beginner translation: old pictures and captures can stay in the repo as evidence of what failed, but they are not instructions for what to build next.

Quarantined materials:

- `docs/concepts/spaced_grid_source_layout_concept_2026-07-06.png`
- `docs/concepts/spaced_grid_source_layout_concept_overlay_2026-07-06.png`
- `tmp/manual_verification/01_management.png`
- `tmp/manual_verification/03_combat_start.png`
- `docs/concepts/full_grid_room_object_concept_2026-07-06.png`
- `docs/concepts/full_grid_room_object_sprite_sheet_source_2026-07-06.png`
- `docs/concepts/full_grid_room_object_proof_throne_entrance_2026-07-06.png`
- `docs/concepts/full_grid_room_object_proof_remaining_rooms_2026-07-06.png`
- `docs/concepts/full_grid_path_connection_layout_proof_2026-07-06.png`
- `docs/concepts/full_grid_path_component_proof_2026-07-06.png`
- `docs/concepts/full_grid_path_connection_grid_accurate_concept_2026-07-06.png`
- `docs/concepts/full_grid_path_connection_grid_accurate_concept_overlay_2026-07-06.png`
- `docs/concepts/full_grid_path_connection_gpt_image2_concept_2026-07-06.png`
- `docs/concepts/full_grid_path_connection_gpt_image2_grid_repaint_concept_2026-07-06.png`
- `assets/props/full_grid_rooms/room_entrance_e_full_grid.png`
- `assets/props/full_grid_rooms/room_throne_s_full_grid.png`
- `assets/props/full_grid_rooms/room_barracks_e_full_grid.png`
- `assets/props/full_grid_rooms/room_recovery_w_full_grid.png`
- `assets/props/full_grid_rooms/room_treasure_w_full_grid.png`
- `assets/props/full_grid_rooms/room_build_slot_n_full_grid.png`

Rules for these materials:

- Do not present them to the user as examples, targets, approved references, or current direction.
- Do not slice them into runtime sprites.
- Do not use them as production source art.
- Do not load the `assets/props/full_grid_rooms/*_full_grid.png` files as runtime sprites.
- Do not use their layout drift, front-facing rectangular rooms, reduced markers, or procedural/debug look as the next-work basis.
- They may be inspected only as failure evidence or negative examples.
- If a visual review needs to show current runtime state, label it clearly as rejected/current-broken state, not as a proposal.

Current work mode:

- New raster asset work must use Codex built-in `image_gen` only after a numbered grid-position contract is written.
- Do not use API/CLI fallback, `OPENAI_API_KEY`, external generators, or code-drawn replacement art as the final asset route.
- The next useful work is either cleaning active references away from the quarantined materials or creating a fresh built-in `image_gen` proof from a corrected contract.

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
13. `docs/IMAGEGEN_CONTRACT_FULL_GRID_ROOM_OBJECT_VARIANTS_01.md`
14. `docs/IMAGEGEN_CONTRACT_FULL_GRID_PATH_CONNECTIONS_01.md`
15. `docs/WORK_LOG_2026-07-06_OBJECT_FACING_AND_COMPLETE_DUNGEON.md`
16. `docs/WORK_LOG_2026-07-06_OBJECT_PLACEMENT_RULE.md`
17. `docs/WORK_LOG_2026-07-06_VISUAL_READABILITY_TUNING.md`
18. `docs/WORK_LOG_2026-07-06_REFERENCE_6_ROOM_GRID_CONVERSION.md`
19. `docs/WORK_LOG_2026-07-06_4X4_5X5_GRID_PROTOTYPE.md`
20. `docs/WORK_LOG_2026-07-06_FULL_GRID_ROOM_OBJECTS.md`
21. `docs/concepts/full_grid_room_object_concept_2026-07-06.md` - historical failure audit only.
22. `docs/concepts/full_grid_room_object_concept_2026-07-06.png` - quarantined, do not present as current direction.
23. `docs/concepts/full_grid_room_object_proof_throne_entrance_2026-07-06.md` - historical failure audit only.
24. `docs/concepts/full_grid_room_object_proof_throne_entrance_2026-07-06.png` - quarantined, do not slice.
25. `docs/concepts/full_grid_room_object_proof_remaining_rooms_2026-07-06.md` - historical failure audit only.
26. `docs/concepts/full_grid_room_object_proof_remaining_rooms_2026-07-06.png` - quarantined, do not slice.
27. `docs/concepts/full_grid_path_connection_layout_proof_2026-07-06.md` - historical failure audit only.
28. `docs/concepts/full_grid_path_connection_layout_proof_2026-07-06.png` - quarantined.
29. `docs/concepts/full_grid_path_component_proof_2026-07-06.md` - historical failure audit only.
30. `docs/concepts/full_grid_path_component_proof_2026-07-06.png` - quarantined.
31. `docs/concepts/full_grid_path_connection_grid_accurate_concept_2026-07-06.md` - data/debug reference only.
32. `docs/concepts/full_grid_path_connection_grid_accurate_concept_2026-07-06.png` - quarantined as user-facing example.
33. `docs/concepts/full_grid_path_connection_grid_accurate_concept_overlay_2026-07-06.png` - quarantined as user-facing example.
34. `docs/concepts/full_grid_path_connection_gpt_image2_concept_2026-07-06.md` - superseded failure audit only.
35. `docs/concepts/full_grid_path_connection_gpt_image2_concept_2026-07-06.png` - superseded and quarantined.
36. `docs/concepts/full_grid_path_connection_gpt_image2_grid_repaint_concept_2026-07-06.md` - historical failure audit only unless the user explicitly revives it.
37. `docs/concepts/full_grid_path_connection_gpt_image2_grid_repaint_concept_2026-07-06.png` - quarantined as current direction.
38. `tools/generate_grid_accurate_path_concept.py`
38a. `docs/concepts/spaced_grid_path_concept_2026-07-06.md`
38b. `docs/concepts/spaced_grid_source_layout_concept_2026-07-06.png` - quarantined as user-facing example; inspect only as failed/current-broken state.
38c. `docs/concepts/spaced_grid_source_layout_concept_overlay_2026-07-06.png` - quarantined as user-facing example; inspect only as failed/current-broken state.
39. Optional original reference folder, if available on the current PC:
   `C:\Users\LDK-6248\Desktop\AI개발\어시스트프로젝트\마왕성\참고자료\mawang_quarterview_tilegrid_v2_docs\mawang_quarterview_tilegrid_v2`
40. In that reference folder, read the relevant docs for the task if the folder exists. If it does not exist on the current PC, continue from the in-repo handoff, contracts, and work logs above. For map structure/image work, minimum read set:
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
  - `scripts/dungeon_quarter/ModuleGraph.gd` assigns room-object facings from the current room position toward the central corridor/junction; layout `object_facing` is now documentation/fallback, not the primary rule.
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

2026-07-06 visual readability tuning follow-up:

- Session Compass remains unchanged: this is a playable Demon King castle dungeon demo assembled from quarter-view cells, floor tiles, wall/edge/door rules, room-role objects, and walkable cell data, not a decorative background.
- Handoff Writing Rule remains active: every handoff update must include the Session Compass, Handoff Writing Rule, current object-system status, and next concrete dungeon-completion step.
- Runtime changes:
  - `QuarterDungeonRenderer.gd` now clamps wall-edge draw height and further lowers wall-edge scale/alpha so walls read as boundaries instead of full-cell objects.
  - `asset_manifest.json` tightens current room-role prop placement values so props stay visually subordinate to the cell.
  - `GameRoot.gd` adds room-specific actor anchor points for compact 3x3 quarter-view rooms.
  - `DungeonRenderer.gd` and `CombatSceneController.gd` use those room-specific actor anchors for management previews and combat spawns.
  - `Unit.gd` slightly reduces unit sprite and label size.
  - `CombatSceneController.gd` slightly reduces slash/impact effect scale and fade duration.
- Verification:
  - `python -m json.tool data\dungeon_quarter\asset_manifest.json`: PASS.
  - `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`.
  - `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`.
  - `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS, captures updated.
- Current object-system status:
  - Complete enough for the compact 3x3 demo pass.
  - The renderer now has placement clamps, facing sprites, single primary object occupancy, and smaller actor/effect overlays.
  - Still not a production-complete large-castle room system.
- Remaining limitation:
  - Numeric tuning can reduce clutter, but it cannot fully solve the 1-cell-room density problem.
  - The next concrete dungeon-completion step, if visual density is still rejected, is to convert key rooms from one-cell rooms into multi-cell interiors before generating more props.

2026-07-06 4x4 / 5x5 novice dungeon prototype:

- Session Compass remains unchanged: this is a playable Demon King castle dungeon demo assembled from quarter-view cells, floor tiles, wall/edge/door rules, room-role objects, and walkable cell data, not a decorative background.
- Handoff Writing Rule remains active: every handoff update must include the Session Compass, Handoff Writing Rule, current object-system status, and next concrete dungeon-completion step.
- User construction rule now implemented after the latest correction:
  - Demon King castle novice dungeon = `4x4` macro grid.
  - One macro grid = `5x5` master cells.
  - One main room object = the whole `5x5` macro grid, not a small centered prop.
  - One path/opening = paired two-cell sockets, visually intended as a `2x2` path/opening.
  - Connected path sides now drive an object `connection_variant`; current art uses connection marks/socket caps until dedicated per-variant room images exist.
  - A full-grid room is a walled building, not an open floor patch: every outer edge is a wall except connected paired socket cells, which become the doorway/opening.
  - Walls/decor remain future `1xN` cell-strip work.
- Work log:
  - `docs/WORK_LOG_2026-07-06_4X4_5X5_GRID_PROTOTYPE.md`
  - `docs/WORK_LOG_2026-07-06_FULL_GRID_ROOM_OBJECTS.md`
- Visual concept reference:
  - `docs/concepts/full_grid_room_object_concept_2026-07-06.png`
  - `docs/concepts/full_grid_room_object_concept_2026-07-06.md`
  - This image is a concept reference only, not a sliced runtime atlas.
  - It shows the intended scale: each room/building object fills its whole macro grid and paths connect to room edges/openings.
- Runtime full-grid sprites now exist for the current default layout:
  - `assets/props/full_grid_rooms/room_entrance_e_full_grid.png`
  - `assets/props/full_grid_rooms/room_throne_s_full_grid.png`
  - `assets/props/full_grid_rooms/room_barracks_e_full_grid.png`
  - `assets/props/full_grid_rooms/room_recovery_w_full_grid.png`
  - `assets/props/full_grid_rooms/room_treasure_w_full_grid.png`
  - `assets/props/full_grid_rooms/room_build_slot_n_full_grid.png`
  - Source sheet: `docs/concepts/full_grid_room_object_sprite_sheet_source_2026-07-06.png`
  - Important: these six images are now treated as rejected prototype assets. They fill the `5x5` size but read as front-facing rectangular rooms, so they must not be used for production or mass generation.
- Current layout contract:
  - Default layout: `current_demo_v2_master_grid_01`
  - Contract ID: `novice_4x4_grid_5x5_full_grid_object_01`
  - `room_grid.grid_size`: `[4, 4]`
  - `room_grid.cell_size`: `[5, 5]`
  - `room_grid.master_origin`: `[0, 0]`
  - Technical `castle_grade`: `S`, used only because the existing grade table gives full `20x20` active cells at `S`.
  - Player-facing layout label: `layout_label: 초보던전`; the management layout selector prefers this label so it does not show the technical `S급` workaround.
- Current macro placements:
  - `G01_00`, origin `[5, 0]`: `throne`, `5x5`
  - `G00_01`, origin `[0, 5]`: `barracks`, `5x5`
  - `G02_01`, origin `[10, 5]`: `recovery`, `5x5`
  - `G00_02`, origin `[0, 10]`: `entrance`, `5x5`
  - `G02_02`, origin `[10, 10]`: `treasure`, `5x5`
  - `G01_03`, origin `[5, 15]`: `slot_01`, `5x5`
  - `PATH_MAIN`, origin `[5, 5]`: `spike_corridor`, `5x10`, spanning `G01_01` and `G01_02`
- Current paired socket rule:
  - Room openings are not single `to_e` or `to_s` sockets anymore.
  - Use paired IDs such as `to_e_u`, `to_e_d`, `to_s_l`, `to_s_r`.
  - The central corridor uses matching paired IDs such as `to_w_upper_u`, `to_w_upper_d`, `to_s_l`, `to_s_r`.
  - Do not revert this to one socket per room side unless the 2x2 path rule is explicitly changed.
- Runtime changes:
  - `data/dungeon_quarter/room_blueprints.json`: room modules are `5x5`; corridor is `5x10`.
  - `data/dungeon_quarter/starting_layout.json` and `custom_layouts.json`: use `novice_4x4_grid_5x5_full_grid_object_01`.
  - `data/rooms.json`: static room metadata aligned to `5x5` and current exits.
  - `scripts/dungeon_quarter/ModuleGraph.gd`: facility object footprints now cover the full `5x5` macro grid; object slots carry `connected_sides` and `connection_variant`; tile projection can scale below `1.0` so `20x20` fits the viewport.
  - `scripts/dungeon_quarter/QuarterDungeonRenderer.gd`: object draw clamps now allow full-grid room objects; `connection_sprites` load but are used only when the prop declares `connection_sprite_projection: "iso_diamond_5x5"`; missing or projection-unsafe side combinations fall back to facing markers over a procedural `5x5` diamond footprint; full-grid room wall records render all unconnected outer room edges as walls and connected paired socket cells as doorways; `debug_object_connection_variant()` exists for tests; connected path bridge records are generated from `graph.connection_pairs()` and rendered with a path-specific corridor layer.
  - `data/dungeon_quarter/asset_manifest.json`: room prop placement values expanded from small-prop scale to room-object scale; current layout sprites are wired through `connection_sprites`.
  - `scripts/game/ManagementSceneController.gd`: layout selector uses `layout_label` before `castle_grade`, preventing `S급` from leaking into the novice dungeon UI.
  - `tools/QuarterModuleSmokeTest.gd`: updated for full-grid object footprint, 4x4/5x5, object connection variants, projection-safe room footprint rendering, room wall/door segment counts, paired socket validation, and visual path bridge counts.
- Verification:
  - `python -m json.tool data\rooms.json`: PASS.
  - `python -m json.tool data\dungeon_quarter\room_blueprints.json`: PASS.
  - `python -m json.tool data\dungeon_quarter\starting_layout.json`: PASS.
  - `python -m json.tool data\dungeon_quarter\custom_layouts.json`: PASS.
  - `python -m json.tool data\dungeon_quarter\asset_manifest.json`: PASS.
  - `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`.
  - `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`.
  - `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS.
- Latest captures:
  - `tmp/manual_verification/01_management.png`
  - `tmp/manual_verification/01_map_editor_disconnected.png`
  - `tmp/manual_verification/03_combat_start.png`
- Current object-system status:
  - Structure now matches the user's corrected rule as a working prototype.
  - Each of the six room objects occupies a full `5x5` object footprint in runtime data.
  - Facility replacement keeps the full `5x5` object footprint.
  - A full-grid room-object concept image now exists in `docs/concepts/full_grid_room_object_concept_2026-07-06.png`.
  - Current default layout does not use the generated full-grid side-connection sprites because they do not match the iso diamond projection.
  - Runtime now draws six procedural `5x5` diamond room footprints, then places existing facing props as room markers until projection-safe room sprites are generated.
  - Runtime now requests room-object facing keys that should face the dungeon center in screen/iso-facing terms. Current default request map: `throne=SW`, `entrance=SE`, `barracks=SE`, `recovery=NW`, `treasure=NW`, `slot_01=NE`.
  - Important correction: this is only key selection. It does not prove the current PNG visually faces that way. The user observed the current throne image still reads as SE-facing; treat the existing v3 facing sprites as placeholder/legacy assets until visually verified or regenerated.
  - Full-grid room-object production now has a dedicated contract: `docs/IMAGEGEN_CONTRACT_FULL_GRID_ROOM_OBJECT_VARIANTS_01.md`.
  - Production selection key is `prop_id + facing + open_mask + layer`, where `facing` is one of `NW/NE/SE/SW` and `open_mask` is the 16-state N/E/S/W opening mask using `N=1,E=2,S=4,W=8`.
  - Count planning: one full-grid room object needs `4 facings * 16 open masks = 64` variants per layer. A split `back/front` role needs 128 images. The six required novice room roles require 384 composite images, or 448 layer images if matching the current layer structure exactly.
  - Do not mass-generate the full matrix first. Required proof order is now: throne plus dungeon entrance composition proof, four-direction proof for both `throne_f` and `entrance_gate_f`, one 16-mask wall/opening proof, the six default-layout variants, then batch production after visual approval.
  - First proof concept now exists at `docs/concepts/full_grid_room_object_proof_throne_entrance_2026-07-06.png`. It is not production-approved art and must not be sliced as runtime sprites.
  - Remaining-room proof concept now exists at `docs/concepts/full_grid_room_object_proof_remaining_rooms_2026-07-06.png`. It covers `weapon_rack`, `recovery_nest_f`, `treasure_pile_large`, and `foundation_marks` in `NW/NE/SE/SW` columns with their default-layout opening masks.
  - The remaining-room proof is also not production-approved art and must not be sliced as runtime sprites until the user confirms direction labels and paired doorway placement.
  - Full-grid path connection production now has a dedicated contract: `docs/IMAGEGEN_CONTRACT_FULL_GRID_PATH_CONNECTIONS_01.md`.
  - Path connection proof now exists at `docs/concepts/full_grid_path_connection_layout_proof_2026-07-06.png`. It shows the six full-grid room objects connected by a narrow central route network instead of a fully filled floor plate.
  - Path component proof now exists at `docs/concepts/full_grid_path_component_proof_2026-07-06.png`. It identifies reusable path strips, junctions, paired doorway mouths, spike inserts, and rubble boundaries for future slicing.
  - Current path image rule: empty macro cells are cave void/unbuilt space, not floor. `PATH_MAIN` is a two-cell-wide route skeleton through `G01_01` and `G01_02`, not a filled `5x10` rectangle.
  - Grid-accurate path concept now exists at `docs/concepts/full_grid_path_connection_grid_accurate_concept_2026-07-06.png`, with overlay at `docs/concepts/full_grid_path_connection_grid_accurate_concept_overlay_2026-07-06.png`.
  - This grid-accurate concept is generated by `tools/generate_grid_accurate_path_concept.py` from the actual `starting_layout.json` and `room_blueprints.json`, so it should be used to judge whether the current macro placement itself is accepted.
  - First GPT Image 2 path concept at `docs/concepts/full_grid_path_connection_gpt_image2_concept_2026-07-06.png` drifted into a radial/symmetric layout and is superseded.
  - Current GPT Image 2 grid-reference repaint concept exists at `docs/concepts/full_grid_path_connection_gpt_image2_grid_repaint_concept_2026-07-06.png`. Use this as the readable art-direction target, with the grid-accurate concept as placement truth.
  - Runtime now treats each full-grid room as a walled building: six rooms expose 120 outer wall/door segments, with 12 connected doorway segments and 108 wall segments in the default layout.
  - Disconnecting a paired path closes those two doorway segments back into walls.
  - Procedural fallback rooms now fill the macro grid more aggressively: less inset, stronger boundary-ring fill, thicker/taller walls, and larger `4x4` fallback role markers.
  - Latest correction removes the reduced central marker rect for full-grid room fallback art. Unsafe/front-view generated room sprites are still rejected, but the existing facing sprites now draw against the whole `5x5` room object rectangle with room-scale width, height, and bottom-offset clamps.
  - This makes the visible building/object art much closer to the full-grid concept image scale. It is still a temporary fallback, not final integrated room art.
  - Room boundary walls no longer render as clean rectangular rails only. The procedural fallback now adds uneven stone courses, block shade variation, mortar seams, cracks, chipped perimeter highlights, lower shadows, and occasional subtle purple dungeon glow.
  - Latest rough-cave pass pushes this further away from polished castle rails: wall height is lower/uneven, blocks are staggered with varied widths, the top highlight is no longer continuous, and loose rubble appears along the base. The target is a small Demon King castle improvised inside a cave, with hand-stacked stone walls.
  - Required path visuals are now implemented for the default layout: 12 connected socket bridge records collapse into six paired two-cell path mouths.
  - Corridor cells receive a path-specific stone tint/seam layer, room floors are dimmed under a room footprint fill, and connected path mouths are redrawn after room objects so full-grid room sprites do not hide the connection edge.
  - Next visual step is not more random props; it is remaining side-connection variants or reusable overlays, production-quality 2x2 doorway/path sprites, and 1xN wall/decor strips.
- Remaining risk:
  - UI no longer shows `S급`, but the underlying data still uses `castle_grade: S` for active-area sizing. Clean this later by adding an explicit beginner full-grid rule instead of relying on grade `S`.
  - The current generated full-grid side variants are not production-safe because they read as front-facing rectangular rooms on top of a diamond grid.
  - Any future full-grid side variant must declare `connection_sprite_projection: "iso_diamond_5x5"` in `data/dungeon_quarter/asset_manifest.json`; otherwise the renderer ignores it.
  - Any future room image batch must include wall/door states, not just connected-side floor marks. A closed side must be a visible wall; only connected paired socket cells may be open.
  - Any future room image batch must also fill the entire `5x5` macro grid. Do not leave large empty margins inside a macro grid and do not treat the room role as a small centered prop.
  - Any future room image batch must face the dungeon center for its macro-grid position. For the current throne room at `G01_00`, the required image direction is visually `SW`, and the runtime request key is `prop:throne_f:SW:back`. Do not claim this is visually fixed until a verified SW throne image exists.
  - Latest user correction: `NW`, `NE`, `SE`, and `SW` are object-front directions, not camera labels and not arbitrary atlas column names. `NW` means the object front faces northwest and a throne should show its back/away side; `SW` means the object front faces southwest/lower-left; `NE` means northeast; `SE` means southeast/lower-right. The current v3 facing sprites fail this visual QA because some variants read effectively the same/front-ish. Treat them as rejected placeholders until regenerated and contact-sheet approved.
  - Direction and wall state must be produced together. Required variants are room role + center-facing direction + connected-side wall mask. A closed side is rough cave stone wall; only connected paired socket cells are open doorways.
  - Do not restore the reduced `3x3` or `4x4` marker fallback for full-grid rooms. If placeholder art is needed, it must use the whole `5x5` room object rect and read at building scale.
  - Do not restore clean single-line rectangular wall borders. Until a production atlas exists, walls should retain dungeon stone texture: irregular top stones, block courses, cracks, and chipped edges.
  - Do not make the wall atlas look like a polished fortress rail. The accepted direction is rough, cave-built, hand-stacked stone with uneven caps and loose rubble.
  - Paired bridge records prove the required path connection logic, but the bridge/mouth art is still procedural. It should later be replaced or backed by proper 2x2 doorway/path sprites.

2026-07-06 spaced grid source proof update:

- Session Compass remains unchanged: this is a playable Demon King castle dungeon assembled from quarter-view cells, floor tiles, wall/edge/door rules, room-role objects, and walkable cell data, not a decorative background.
- Handoff Writing Rule remains active: future handoffs must state the latest source contract, verification, remaining art limitation, and first concrete next step.
- Latest user decision:
  - The packed `20x20` full-grid-object layout was not enough because there was no physical gap for paths between room grids.
  - The applied structure is now a spaced room lattice: `4x4` room slots, each room slot is `5x5`, with a `2`-cell gap between room slots for corridors.
  - The entrance must also connect to the outside, not only to the internal path network.
- Current applied contract:
  - `room_grid_contract_id`: `novice_4x4_grid_5x5_gap2_paths_01`
  - room lattice origin: `[2, 0]`
  - room stride: `[7, 7]`
  - room lattice size: `[26, 26]`
  - active master size including the west outside approach: `[28, 26]`
  - corridor/path module: `spike_corridor` using `corridor_gap_network_01`
  - exterior module: `outside_approach` using `outside_approach_01`
- Current source placements:
  - `throne`: `G01_00`, origin `[9, 0]`, open `S`
  - `barracks`: `G00_01`, origin `[2, 7]`, open `E`
  - `recovery`: `G02_01`, origin `[16, 7]`, open `W`
  - `entrance`: `G00_02`, origin `[2, 14]`, open `E,W`
  - `treasure`: `G02_02`, origin `[16, 14]`, open `W`
  - `slot_01`: `G01_03`, origin `[9, 21]`, open `N`
  - `outside_approach`: origin `[0, 16]`, `2x2`, connected east to entrance and west to an exterior placeholder/cave mouth.
- Current path counts:
  - `14` connection bridge records.
  - `7` paired two-cell path mouths, including the exterior entrance mouth.
  - `4` outside approach cells.
  - Required path `outside_approach -> throne` is validated.
- Files changed for this update:
  - `data/dungeon_quarter/starting_layout.json`: converted to the spaced gap contract and added the outside approach.
  - `data/dungeon_quarter/custom_layouts.json`: sample layout aligned to the same spaced gap contract so switching layouts does not restore the old packed layout.
  - `data/dungeon_quarter/room_blueprints.json`: added `corridor_gap_network_01` and `outside_approach_01`.
  - `data/dungeon_quarter/castle_grade_rules.json`: max grid now `[28, 26]`.
  - `data/dungeon_quarter/asset_manifest.json`: path contract now `spaced_grid_gap_path_connections_01`; source proof image paths point to the spaced-grid images.
  - `scripts/dungeon_quarter/ModuleGraph.gd`: default and fallback grid size are `[28, 26]`; facing-center calculation ignores the outside module so room object facings still target the dungeon center.
  - `scripts/dungeon_quarter/QuarterDungeonRenderer.gd`: draws outside approach floor cells and a front overlay cave-mouth marker on the west exterior edge.
  - `tools/generate_grid_accurate_path_concept.py`: now generates the concept from real layout/blueprint data, including `master_origin`, `stride`, empty room slots, trap cells, and outside approach cells.
  - `tools/QuarterModuleSmokeTest.gd`: validates the new grid size, bridge counts, outside approach cells, entrance `E,W` variant, exterior socket state, and pathing.
  - `docs/concepts/spaced_grid_path_concept_2026-07-06.md`: current source contract and verification notes.
- Source proof images generated:
  - `docs/concepts/spaced_grid_source_layout_concept_2026-07-06.png`
  - `docs/concepts/spaced_grid_source_layout_concept_overlay_2026-07-06.png`
- Runtime captures refreshed:
  - `tmp/manual_verification/01_management.png`
  - `tmp/manual_verification/01_map_editor.png`
  - `tmp/manual_verification/03_combat_start.png`
- Verification:
  - `python -m py_compile tools\generate_grid_accurate_path_concept.py`: PASS.
  - `python tools\generate_grid_accurate_path_concept.py`: PASS, source proof images regenerated.
  - `python -m json.tool` on starting layout, custom layouts, room blueprints, asset manifest, and castle grade rules: PASS.
  - `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`.
  - `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`.
  - `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS, captures refreshed.
- Current object-system status:
  - Source layout and movement/path graph now support the user's requested spaced room-grid concept.
  - The entrance is physically connected west to a `2x2` outside approach module and east to the internal path network.
  - Room art is still not production-complete. The runtime uses procedural full-grid fallback footprints plus existing facing props, and the exterior marker is a procedural cave-mouth overlay, not a final sliced asset.
- Remaining risk:
  - The generated/procedural runtime view proves feasibility, not final art approval.
  - Dedicated production assets still need to be generated by `room role + facing + open_mask + layer`.
  - Dedicated path/door/exterior-mouth sprites are still needed if the procedural bridge/cave-mouth style is rejected.
  - The UI still shows some mojibake in `starting_layout.display_name`; `layout_label` prevents the worst leakage, but labels should be cleaned later with explicit escaped Korean strings.

## 2026-07-06 Role-Driven Combat Layout Feasibility Test

User correction for combat structure:

- Paths are monster movement lanes.
- Combat fun should come from room interiors, not from fighting on bare path strips.
- Correct novice dungeon role order is:
  1. outside approach / entrance,
  2. trap room that weakens invaders,
  3. barracks as the main interception arena,
  4. recovery as a side fallback room for retired/injured monsters,
  5. treasure as a lure/distraction branch,
  6. throne as the final objective.

Test implementation added:

- `data/dungeon_quarter/test_layouts/role_driven_combat_layout_test_01.json`
  - This is a test layout only. It is not registered as the default playable layout yet.
  - It keeps the current `4x4` room grid, `5x5` room cells, `2x2` path gaps, and `28x26` active grid.
  - It changes the combat structure so the main path is outside -> entrance -> trap room -> barracks -> throne.
  - It adds a treasure branch after barracks and a recovery side branch from barracks.
- `tools/RoleCombatLayoutProbe.gd`
- `tools/RoleCombatLayoutProbe.tscn`

New module blueprints added in `data/dungeon_quarter/room_blueprints.json`:

- `room_trap_01`
  - A true `5x5` trap room.
  - In the test layout it is placed with instance id `spike_corridor` so existing combat code that checks `current_room == "spike_corridor"` still triggers spike damage/animation.
- `room_barracks_arena_2x1_01`
  - A merged `12x5` barracks combat arena.
  - It spans two normal `5x5` room cells plus the `2`-cell gap between them.
  - It is the first serious combat space after the trap room.
- `corridor_gap_ew_2x2_01`
  - A horizontal `2x2` connector for room-to-room gaps.
- `corridor_gap_ns_2x2_01`
  - A vertical `2x2` connector for room-to-room gaps.
- `corridor_barracks_throne_01`
  - A special narrow connector from the merged barracks arena to the throne room.

Critical technical finding:

- Do not implement this combat structure with one global path module.
- If a single shared path module connects every room, room-level BFS can produce shortcuts such as `entrance -> path_network -> throne`, which breaks the intended design even if the visual floor looks connected.
- The correct structure uses separate corridor segment instances between role rooms. This forces `ModuleGraph.path_between()` to include each important room in the route.

Validated routes from `RoleCombatLayoutProbe`:

- Main route:
  - `outside_approach -> entrance -> path_entrance_trap -> spike_corridor -> path_trap_barracks -> barracks -> path_barracks_throne -> throne`
- Treasure lure route:
  - `entrance -> path_entrance_trap -> spike_corridor -> path_trap_barracks -> barracks -> path_barracks_treasure -> treasure`
- Recovery retreat route:
  - `barracks -> path_barracks_recovery -> recovery`

Probe checks:

- Socket validation passes for the test layout.
- Module graph validation passes.
- Active grid remains `28x26`.
- Main route is forced through entrance, trap room, barracks, and throne.
- Treasure lure branch happens after barracks.
- Recovery room is reachable from barracks but is not on the main enemy route.
- World-space AStar paths stay on walkable floor.
- Trap room keeps instance id `spike_corridor`.
- Trap room exposes `spike_floor` trap cells.
- Barracks and treasure still carry full-grid room objects, not tiny centered props.
- `GameRoot` can register the test layout at runtime without persistence.
- `GameRoot` can start combat on this layout.
- A throne-goal enemy receives a path whose room route is entrance -> trap -> barracks -> throne.
- A treasure-goal thief receives a path whose room route is entrance -> trap -> barracks -> treasure.
- `CombatSceneController.update_room_effects()` damages an enemy standing in `spike_corridor`, proving the trap-room compatibility path works with the existing combat code.

Verification:

- `python -m json.tool data\dungeon_quarter\room_blueprints.json`: PASS.
- `python -m json.tool data\dungeon_quarter\test_layouts\role_driven_combat_layout_test_01.json`: PASS.
- `godot --headless --path . --run res://tools/RoleCombatLayoutProbe.tscn`: `ROLE_COMBAT_LAYOUT_PROBE: PASS`.
- `godot --path . --run res://tools/RoleCombatLayoutCapture.tscn`: `ROLE_COMBAT_LAYOUT_CAPTURE: PASS`.
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`.
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`.

Runtime capture files:

- `tmp/role_combat_verification/01_management_role_layout.png`
- `tmp/role_combat_verification/02_management_role_debug_overlay.png`
- `tmp/role_combat_verification/03_combat_explorer_throne_path.png`
- `tmp/role_combat_verification/04_combat_thief_treasure_path.png`
- `tmp/role_combat_verification/05_combat_trap_trigger.png`

Findings from the runtime capture:

- The role combat layout applies correctly in `GameRoot`.
- The route graph and enemy target selection are correct.
- Trap damage can still trigger because the trap room keeps instance id `spike_corridor`.
- Do not treat this as a fixed placement target:
  - The user must be able to place rooms where they want.
  - The current role layout is only a connection proof.
  - Do not solve the next step by hardcoding default room positions or default monster positions.
  - The immediate priority is room-to-room path connection authoring and rendering.
  - A placed room must derive its image from `room role + facing + open_mask + layer`, where `open_mask` comes from actual N/E/S/W connections.
- Visual issue:
  - `path_barracks_throne` is functionally valid but reads too much like a long floor slab in the capture.
  - Before production art, make path connectors visually narrow and distinct from room interiors.
  - The non-debug view still needs stronger walls/rock boundaries around unconnected room sides.

Next work for this branch:

1. Focus only on room/path connection mechanics.
2. Support user-authored room placement, not a fixed demo arrangement.
3. When a room is placed, compute its facing from placement/context and compute its `open_mask` from actual connected sides.
4. When two rooms are connected, create or preview a path segment between their paired sockets.
5. When a side is not connected, render that side as wall/rock, not floor.
6. Keep the rule that connected room sides are open door/path mouths and unconnected room sides are closed walls.

## 2026-07-06 Room-To-Room Path Authoring Pass

User correction:

- Do not solve this by locking the demo layout or changing default monster placement.
- The player/user must be able to place rooms where they want and then connect rooms with paths.
- Four-direction room images and 16 open-mask variants exist because any room role can appear in different positions with different connected sides.
- Immediate priority is only room/path connection mechanics: placed room -> connected side opens -> path segment appears -> unconnected sides stay walls.

Implemented:

- `scripts/game/GameRoot.gd`
  - `_map_editor_connect_adjacent_socket()` still supports the old direct adjacent-socket reconnect flow.
  - It does not create path modules automatically.
  - If no directly adjacent socket pair exists, it fails with `인접한 연결 후보가 없습니다.`
  - A path only exists when a path module has already been placed manually in the gap.
  - The user must connect room -> path and path -> room with paired socket connections.
  - `socket_states` are updated to `connected` only for explicitly authored connections, so `ModuleGraph` derives room `connected_sides` and object `connection_variant` from the user's manual links.
  - Disconnecting a selected room removes only that room's socket connections. It does not delete manually placed path modules.

Verification tool:

- `tools/RoomPathAuthoringProbe.gd`
- `tools/RoomPathAuthoringProbe.tscn`

Probe coverage:

- No automatic path creation:
  - Places `entrance` at `[2,14]` and `treasure` at `[9,14]` with no path module between them.
  - Uses map editor connection flow.
  - Verifies no connection is created.
  - Verifies no path module is created.
- East/west authoring:
  - Places `entrance` at `[2,14]`, manually placed `path_entrance_treasure` at `[7,16]`, and `treasure` at `[9,14]`.
  - Uses map editor connection flow four times to connect the paired sockets.
  - Verifies graph path is `entrance -> path_entrance_treasure -> treasure`.
  - Verifies entrance connection variant includes `e` and treasure includes `w`.
  - Verifies disconnect does not delete the manually placed path module.
- North/south authoring:
  - Places `barracks` at `[2,7]`, manually placed `path_barracks_treasure` at `[4,12]`, and `treasure` at `[2,14]`.
  - Uses map editor connection flow four times to connect the paired sockets.
  - Verifies graph path is `barracks -> path_barracks_treasure -> treasure`.
  - Verifies barracks connection variant includes `s` and treasure includes `n`.
  - Verifies disconnect does not delete the manually placed path module.

## 2026-07-06 User Path Placement UI Pass

This pass continues the room/path authoring work after the failed visual material quarantine.

Implemented:

- `scripts/game/GameRoot.gd`
  - Added `_map_editor_place_gap_path()`.
  - This is a user-triggered edit action, not automatic path creation.
  - It finds the nearest valid `2x2` gap corridor candidate from the selected room to another unconnected room.
  - It places one manual path module:
    - `corridor_gap_ew_2x2_01` for east/west gaps.
    - `corridor_gap_ns_2x2_01` for north/south gaps.
  - Manual path modules are marked with:
    - `grid_id: USER_AUTHORED_PATH`
    - `user_authored: true`
    - `instance_id: user_path_##`
  - The new path is selected immediately so the existing `인접 연결` action can connect its paired sockets.
  - The action does not auto-connect sockets. The user still explicitly connects room -> path -> room.
- `scripts/game/ManagementSceneController.gd`
  - Added the map editor button `통로 배치`.
  - Rearranged the compact editor controls so path placement, adjacent connection, disconnect, save, and cancel remain reachable.
- `tools/RoomPathAuthoringProbe.gd`
  - Added east/west UI path placement coverage.
  - Added north/south UI path placement coverage.
  - Verifies each placed path is user-authored, uses the expected corridor module, adds no automatic connections, and can then be connected into a valid graph path.

Verification:

- `godot --headless --path . --run res://tools/RoomPathAuthoringProbe.tscn`: `ROOM_PATH_AUTHORING_PROBE: PASS`.

## 2026-07-06 Path Candidate Preview / Delete Rules / Click Target Picker / Fresh Proof Pass

Session compass restated:

- We are building a playable Demon King castle dungeon demo, not a decorative background.
- The logical grid, sockets, path modules, walkable cells, and room-role objects are the dungeon. Art must follow those rules.

Beginner translation:

- The editor should let the user decide which path candidate to place.
- Clicking the map canvas should choose a target candidate, not secretly create the path.
- A preview is only a visual hint. It must not secretly add a path to the graph.
- A `system_required` path is a safety path. It can be deleted only when another entrance-to-throne route already exists.

Implemented gameplay/tooling work:

- `scripts/game/GameRoot.gd`
  - Added `map_editor_path_candidate_index`.
  - Added `_map_editor_next_gap_path_candidate()`.
  - Added `_map_editor_gap_path_candidates_for_selected()`.
  - Added `_map_editor_preview_gap_path_candidate()`.
  - Added `_map_editor_select_gap_path_candidate_to(target_instance_id)`.
  - Added duplicate candidate filtering so the same target/origin does not appear multiple times because of paired sockets.
  - Added `_map_editor_delete_selected_path()`.
  - Management-screen left-click now passes the screen position into `_handle_left_click()`.
  - Management HUD panels are ignored by map-canvas picking, so clicking editor buttons does not also retarget the map.
  - In map-editor mode, clicking a room that is a valid gap-path target changes the current path candidate while keeping the source room selected.
  - Clicking a non-candidate room still selects that room as the new source.
  - User-authored paths can be deleted and their socket connections are removed.
  - Opposite room sockets return to `open_placeholder` after path deletion, so the user sees they are available for reconnection.
  - `system_required` paths are protected: deletion is blocked if removing the selected path would break `entrance -> throne`.
- `scripts/game/ManagementSceneController.gd`
  - Expanded the compact map editor panel.
  - Added `후보 변경`.
  - Added `통로 삭제`.
  - Added a candidate status line that shows the current path candidate target and origin.
- `scripts/dungeon_quarter/QuarterDungeonRenderer.gd`
  - Added a non-mutating candidate preview overlay.
  - The preview draws the selected candidate's `2x2` corridor cells as a translucent overlay.
  - This overlay does not write to `map_editor_layout`, `connections`, `socket_states`, or the runtime graph.
- `tools/RoomPathAuthoringProbe.gd`
  - Added coverage for candidate cycling.
  - Added coverage for map-canvas target picking: source room stays selected, clicked target becomes the previewed candidate, and placement uses that preview.
  - Added coverage for deleting a user-authored path.
  - Added coverage that blocks deleting a `system_required` path when no replacement route exists.

Fresh built-in image generation work:

- New numbered contract:
  - `docs/IMAGEGEN_CONTRACT_PATH_DOOR_EXTERIOR_MOUTH_PROOF_01.md`
- Built-in `image_gen` outputs copied into the repo:
  - `docs/concepts/path_door_exterior_mouth_proof_01.png`
  - `docs/concepts/path_door_exterior_mouth_proof_02.png`
- Manifest policy added:
  - `data/dungeon_quarter/asset_manifest.json` -> `proof_only_visual_material_policy`

Visual decision:

- Both fresh proof images are proof-only and must not be sliced or wired into runtime assets.
- Proof 01 has strong mood but reads too much like a large enclosed decorative room; the strict `7x5` / `5x5` / `2x2` contract is not inspectable enough.
- Proof 02 has clearer cells, but the exterior path and room reference still exceed the strict target.
- These are fresh built-in proofs, not quarantined legacy materials, but they are still not approved production assets.

Verification:

- `godot --headless --path . --run res://tools/RoomPathAuthoringProbe.tscn`: `ROOM_PATH_AUTHORING_PROBE: PASS`.
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`.
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`.
- `godot --headless --path . --run res://tools/OnboardingFlowSmokeTest.tscn`: `ONBOARDING_FLOW_SMOKE_TEST: PASS`.
- `godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn`: `TUTORIAL_FLOW_SMOKE_TEST: PASS`.

## 2026-07-07 Path Target Reclick / One-Step Path-End Connect

Session compass restated:

- Keep building the playable dungeon editor, not decorative map art.
- The user-facing authoring flow should make the logical grid, sockets, path modules, and walkability easier to control.
- Do not silently create new path modules during ordinary edit actions.

Beginner translation:

- A socket is a connection opening on the edge of a room or corridor.
- `통로 배치` creates the selected `2x2` corridor module, but does not automatically connect it.
- `통로 연결` now connects the already placed corridor to all adjacent room/corridor sockets it can touch.
- If one clicked target ever has multiple valid placement candidates, clicking that same target again cycles to the next candidate.

Implemented gameplay/tooling work:

- `scripts/game/GameRoot.gd`
  - Added `_map_editor_connect_selected_path_ends()`.
  - It only works when the selected entry is a path module.
  - It connects every currently adjacent, unconnected socket pair touching the selected path.
  - It does not create new path modules.
  - It does not duplicate existing socket connections.
  - `_map_editor_select_gap_path_candidate_to(target_instance_id)` now cycles within the clicked target if that target has multiple matching candidates.
  - `_map_editor_path_candidate_line()` now includes the selected source/target socket ids after the grid origin, so the candidate is easier to audit.
- `scripts/game/ManagementSceneController.gd`
  - Rewrote the controller as valid UTF-8 Korean text after legacy mojibake made patch matching unsafe.
  - Added the `통로 연결` button to the map editor panel.
  - Kept the compact panel inside the existing 342px left-side layout selector area.
- `tools/RoomPathAuthoringProbe.gd`
  - Added coverage for target reclick behavior.
  - Added coverage for `통로 연결`: path starts unconnected, one action creates the four paired socket links, a second action does not duplicate them, and the room-path-room graph route becomes usable.

Important behavior boundary:

- `통로 연결` is a connection action, not a path-generation action.
- It reduces the old repeated `인접 연결` click burden after a path is placed.
- It is still not a full multi-segment route drawing tool.
- Current blueprint data usually leaves one valid candidate per clicked target after duplicate filtering; the reclick cycle is ready for layouts that expose more than one distinct candidate.

Verification:

- `godot --headless --path . --run res://tools/RoomPathAuthoringProbe.tscn`: `ROOM_PATH_AUTHORING_PROBE: PASS`.
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`.
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`.

## 2026-07-07 Path Candidate Socket-Pair Overlay

Session compass restated:

- We are building a playable Demon King castle dungeon demo, not a decorative background.
- The dungeon remains data-first: logical cells, walkable cells, sockets, path modules, wall/door state, and room-role objects define play.
- The corrected data contract is unchanged: `4x4` room grid, `5x5` room footprint, `2x2` path gap width, west exterior entrance connection, user-authored path modules, and protected `system_required` route repair only at save/combat/day boundaries.

Failed Visual Material Quarantine restated:

- Do not open or present quarantined old concept/capture images as current direction.
- Do not slice or wire `docs/concepts/path_door_exterior_mouth_proof_01.png` or `docs/concepts/path_door_exterior_mouth_proof_02.png`; they remain proof-only and are not grid-accurate enough.
- This session did not add or approve production raster assets.

Implemented gameplay/tooling work:

- Pulled the latest GitHub `origin/main` commit into `codex/map-custom-2026-07-03` by fast-forward. The branch now includes `76559cf Improve map editor path authoring flow`.
- `scripts/game/GameRoot.gd`
  - Added `_map_editor_preview_gap_path_socket_markers()`.
  - Added `_map_editor_socket_record_for_ref(reference)`.
  - The current path candidate now exposes source/target socket refs, side, and grid cell positions for non-mutating UI overlays.
- `scripts/dungeon_quarter/QuarterDungeonRenderer.gd`
  - Added a map-editor overlay for the current candidate socket pair.
  - Source and target socket cells are highlighted separately, their socket sides are emphasized, and a thin line connects the pair.
  - The overlay is visual only. It does not mutate `map_editor_layout`, `connections`, `socket_states`, or the runtime graph.
- `tools/RoomPathAuthoringProbe.gd`
  - Added coverage that the socket-pair markers match the preview candidate.
  - Added coverage that map-canvas target picking updates the target socket marker with the selected candidate.

Verification:

- `godot --headless --path . --run res://tools/RoomPathAuthoringProbe.tscn`: `ROOM_PATH_AUTHORING_PROBE: PASS`.
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`.
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`.
- `godot --headless --path . --run res://tools/RoleCombatLayoutProbe.tscn`: `ROLE_COMBAT_LAYOUT_PROBE: PASS`.
- `godot --headless --path . --run res://tools/OnboardingFlowSmokeTest.tscn`: `ONBOARDING_FLOW_SMOKE_TEST: PASS`.
- `godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn`: `TUTORIAL_FLOW_SMOKE_TEST: PASS`.
- `godot --headless --path . --import`: PASS.
- `git diff --check`: PASS with only LF/CRLF working-copy warnings on the edited GDScript files.

Current object-system status:

- No production room/path/exterior-mouth art was added.
- The current object/path system still proves the data contract with procedural/full-grid fallback footprints, existing facing props, user-authored `2x2` path modules, and protected required-route repair.
- The editor now visually identifies the candidate socket pair before the user places the path, reducing the previous text-only ambiguity.

Remaining limitation:

- The overlay shows the candidate socket pair, but it is not yet an interactive per-socket picker.
- The editor still does not route long multi-segment paths across multiple empty gaps or around blockers.
- The editor still does not provide drag-to-draw route authoring or path-to-path extension as a first-class flow.
- Production-approved graphics for path mouths, the exterior cave mouth, and full-grid room variants are still pending a stricter numbered component/contact-sheet proof.

## 2026-07-06 Required Entrance-To-Throne Route Repair

User rule update:

- The user can manually connect and disconnect room/path links.
- While editing, the map must not immediately recreate paths the user just removed.
- However, the dungeon must never be finalized into a state where enemies cannot travel from `entrance` to `throne`.
- Therefore automatic repair is allowed only at commit boundaries:
  - map editor save,
  - combat start,
  - next-day progress from management.

Implemented in `scripts/game/GameRoot.gd`:

- `_repair_required_main_route()` checks `entrance -> throne`.
- If the route already exists, it leaves the layout unchanged.
- If the route is broken but an existing manually placed path module is adjacent, it connects the closest available paired sockets.
- If no path module exists and the two sides have a valid `2x2` gap, it creates one `system_required_path_##` module using:
  - `corridor_gap_ew_2x2_01` for east/west gaps,
  - `corridor_gap_ns_2x2_01` for north/south gaps.
- Auto-created path modules are marked with:
  - `grid_id: SYSTEM_REQUIRED_ROUTE`
  - `system_required: true`
- The repair connects paired two-cell sockets, so a repaired room/path/room chain gets four socket connections, not a single one-cell shortcut.
- The repair refuses to place a path if it would overlap an existing floor cell or leave the active grid bounds.

Important behavior boundary:

- `_map_editor_connect_adjacent_socket()` still does not create path modules.
- Editing remains manual and interruptible.
- Automatic `system_required` path generation happens only during save/combat/day boundary repair.
- Future path delete UI should allow deleting a `system_required` path only after the user has authored another valid `entrance -> throne` route.

New probe coverage in `tools/RoomPathAuthoringProbe.gd`:

- Save with an existing disconnected manual path:
  - `entrance`, `path_entrance_throne`, and `throne` are already placed.
  - Save repairs the route by adding four paired socket connections.
  - No new path module is created.
- Save with no manual path:
  - `entrance` and `throne` are separated by a valid `2x2` gap.
  - Save creates one `system_required_path_##`.
  - The graph route becomes `entrance -> system_required_path_## -> throne`.
- Combat start with no manual path:
  - Runtime repair creates the same required path before entering combat.
  - Combat starts and `GameRoot.graph.path_between("entrance", "throne")` uses the repaired path.

Verification:

- `godot --headless --path . --run res://tools/RoomPathAuthoringProbe.tscn`: `ROOM_PATH_AUTHORING_PROBE: PASS`.
- `godot --headless --path . --run res://tools/RoleCombatLayoutProbe.tscn`: `ROLE_COMBAT_LAYOUT_PROBE: PASS`.
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`.
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`.

Current limitation:

- This pass now supports user-triggered placement of a selected valid `2x2` gap path module from the selected room.
- It supports cycling between unique placement candidates with `후보 변경`.
- It supports first-pass map-canvas target picking for path placement candidates.
- It supports same-target reclick cycling when a clicked target has multiple distinct candidate placements.
- It provides a non-mutating preview overlay for the selected path candidate.
- It provides a non-mutating source/target socket-pair overlay for the selected path candidate.
- It supports deleting user-authored path modules.
- It supports `통로 연결`, which connects the selected placed path to all adjacent unconnected sockets in one action.
- It blocks deleting a `system_required` path when no replacement `entrance -> throne` route exists.
- It supports manual connection of already placed, directly adjacent room/path sockets.
- It does not yet route long multi-segment paths across multiple empty gaps or around other rooms.
- It does not yet provide an interactive socket-pair picker on top of the clicked target; candidate selection/cycling is still button/click/status-line driven.
- It does not yet provide drag-to-draw multi-segment route authoring.
- It does not yet provide production-approved graphics for the path mouth, exterior cave mouth, or full-grid room variants.
- The next concrete step is either:
  - multi-segment path drawing / step-by-step route authoring / path-to-path extension, or
  - stricter component/contact-sheet image generation for the `2x2` path mouth and exterior cave-mouth assets.

First task next session:

1. Restate the Mandatory Session Compass.
2. Restate the Failed Visual Material Quarantine above. Do not open or present the old concept/capture images as examples or targets.
3. Read the new `2026-07-07 Path Candidate Socket-Pair Overlay`, `2026-07-07 Path Target Reclick / One-Step Path-End Connect`, and `2026-07-06 Path Candidate Preview / Delete Rules / Click Target Picker / Fresh Proof Pass` sections.
4. Confirm the corrected data contract in words before visual work: `4x4` room grid, `5x5` room footprint, `2x2` path gap width, west exterior entrance connection, user-authored path modules, and protected `system_required` route behavior.
5. For gameplay/tooling work, continue with multi-segment path drawing, path-to-path extension, or an interactive socket-pair picker. Do not reintroduce automatic path creation during ordinary edit actions.
6. For graphics work, do not slice `docs/concepts/path_door_exterior_mouth_proof_01.png` or `docs/concepts/path_door_exterior_mouth_proof_02.png`. They are proof-only and not grid-accurate enough.
7. The next visual iteration should be a stricter component/contact-sheet proof for:
   - `2x2` exterior approach component,
   - west-side paired doorway mouth component,
   - rough cave-mouth edge component.
8. If creating new raster assets, first update or write a numbered grid-position contract, then use Codex built-in `image_gen` only.
9. If the current structure is rejected, revise only the source layout spacing, path network, entrance exterior connection, or room placement. Do not go back to a packed `20x20` floor slab, centered small props, front-facing rectangular room sprites, procedural/debug target images, or freehand images that ignore the grid contract.

## Next Work Direction

The correct direction is not "make more floor art."

The correct direction is:

1. Define room cells in the logical grid.
2. Define N/E/S/W connections per cell.
3. Render connected sides as readable paths/openings.
4. Render unconnected sides as walls/rock/hidden boundaries.
5. Treat each room-role object as the whole `5x5` macro grid object; do not shrink it back to a small centered prop.
6. Use a cave/dungeon background plate under the grid for atmosphere only.
7. Generate any new image asset only after the numbered grid-position contract is written.
8. For room-role objects, keep using explicit facing/position variants before using the same facility type in arbitrary places.
9. For full-grid room-role production, use `docs/IMAGEGEN_CONTRACT_FULL_GRID_ROOM_OBJECT_VARIANTS_01.md`: generate by `prop_id + facing + open_mask + layer`, not by prop id alone.
10. For path production, use `docs/IMAGEGEN_CONTRACT_FULL_GRID_PATH_CONNECTIONS_01.md`: generate by the route skeleton and paired doorway mouths, not by filling empty macro cells with floor.

## 2026-07-07 Onboarding Portrait Handoff Pointer

Before continuing onboarding, dialogue UI, character illustration, or per-level UI polish, read:

- `docs/HANDOFF_ONBOARDING_PORTRAITS_2026-07-07.md`
- `docs/WORK_LOG_2026-07-07_ONBOARDING_PORTRAITS.md`
- `docs/WORK_LOG_2026-07-07_ONBOARDING_SCENE_ILLUSTRATION.md`

Current status:

- Base portrait images now exist for the demo core speakers.
- `S01_NAME_ENTRY` shows Bati as an actual image.
- `S02_DIALOGUE` shows the current speaker portrait for known `CHR_*` ids.
- `S02_DIALOGUE` now has a base demon-castle `SceneIllustration` behind the dialogue UI.
- `tools/OnboardingPortraitCapture.tscn` captures visual proof images into `tmp/onboarding_portrait_verification/`.

Do not call the onboarding UI complete yet. Emotion-specific portraits, stage-specific art policy, and remaining reference-based polish are still open.
