# Map Custom Current Handoff - 2026-07-03

This handoff is mandatory for every resumed, compressed, or new Codex session in the current map-custom work.

## Read Order Before Any Work

Before making changes, the next agent must read this file first, then read the relevant reference material below. Do not start from memory.

1. `docs/HANDOFF_MAP_CUSTOM_CURRENT_2026-07-03.md`
2. `docs/PLAN_2026-07-03_MAP_CUSTOM_ONLY.md`
3. `docs/WORK_LOG_2026-07-03_QUARTERVIEW_CUSTOM_LAYOUTS.md`
4. `docs/WORK_LOG_2026-07-03_SMALL_DUNGEON_OBJECTS.md`
5. `docs/WALL_EDGE_ATLAS_RULE_2026-07-03.md`
6. Reference folder:
   `C:\Users\LDK-6248\Desktop\AI개발\어시스트프로젝트\마왕성\참고자료\mawang_quarterview_tilegrid_v2_docs\mawang_quarterview_tilegrid_v2`
7. In that reference folder, read the relevant docs for the task. For map structure/image work, minimum read set:
   - `docs/08_COPYPASTE_FOR_CODEX.txt`
   - `docs/00_README.md`
   - `docs/01_CORE_SYSTEM_RULES.md`
   - `docs/03_16_TILE_MASK_RULES.md`
   - `docs/04_BACKGROUND_VOID_UNCONNECTED_RULES.md`
   - `docs/06_CODEX_IMPLEMENTATION_SPEC.md`
   - `templates/room_blueprint_v2.json`
   - `templates/tile_mask_mapping.json`

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
