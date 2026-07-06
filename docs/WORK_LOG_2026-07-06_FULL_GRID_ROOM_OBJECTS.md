# 2026-07-06 Full-Grid Room Objects

## Session Compass

We are building a playable Demon King castle dungeon demo, not a decorative background. The dungeon must be assembled from quarter-view cells, floor tiles, wall/edge/door rules, room-role objects, and walkable cell data.

## User Correction

The user rejected the centered `3x3` room-object rule because the building objects still looked too small.

Current rule:

- Demon King castle novice dungeon = `4x4` macro grid.
- One macro grid = `5x5` master cells.
- One room/building object occupies the whole `5x5` macro grid.
- Paths still use paired two-cell socket openings.
- Connected path sides must drive the room-object visual state.

## Implemented Contract

Current contract ID:

- `novice_4x4_grid_5x5_full_grid_object_01`

Important distinction:

- `spike_corridor` is still a path/trap connector and is not counted as one of the six room-grid objects.
- The six room-grid objects are entrance, throne, barracks, recovery, treasure, and build slot.

## Runtime Changes

- `data/dungeon_quarter/room_blueprints.json`
  - Entry/core static object slots now use a full centered `5x5` footprint around local `[2, 2]`.
- `scripts/dungeon_quarter/ModuleGraph.gd`
  - Facility-generated room objects now receive the full module footprint instead of being capped to `3x3`.
  - Room object slots now carry `connected_sides` and `connection_variant`.
- `scripts/dungeon_quarter/QuarterDungeonRenderer.gd`
  - Object draw width and max-height clamps now allow room objects to fill their full grid footprint.
  - The renderer draws connection marks on the room object footprint based on connected sides.
  - Added `debug_object_connection_variant()` for tests.
- `data/dungeon_quarter/asset_manifest.json`
  - Room prop placement values were expanded so current sprites read as room-scale objects.
- `data/dungeon_quarter/starting_layout.json`
  - Uses the new full-grid object contract ID and wording.
- `data/dungeon_quarter/custom_layouts.json`
  - Mirrors the new full-grid object contract.
- `tools/QuarterModuleSmokeTest.gd`
  - Verifies all six room objects have at least 25 footprint cells.
  - Verifies object connection variants for entrance, throne, and recovery.
  - Verifies facility replacement keeps the full `5x5` object footprint.

## Verification

Commands run:

```powershell
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

The current implementation follows the user's corrected rule: the building object is the macro grid object, not a small prop placed inside the macro grid.

## Concept Image

Generated a visual reference for the corrected concept:

- `docs/concepts/full_grid_room_object_concept_2026-07-06.png`
- Companion note: `docs/concepts/full_grid_room_object_concept_2026-07-06.md`

Purpose:

- Reference for full-grid room-object scale and room/path readability.
- Not a runtime atlas and not sliced into individual sprites yet.
- Future art should use it to author deterministic room-object bases, side-connection variants, `2x2` doorway/path sprites, and `1xN` wall/decor strips.

## Runtime Sprite Connection Pass

The user accepted the concept direction and asked to proceed.

Generated a 2x3 full-grid room sprite sheet, then split it into six alpha PNGs:

- `assets/props/full_grid_rooms/room_entrance_e_full_grid.png`
- `assets/props/full_grid_rooms/room_throne_s_full_grid.png`
- `assets/props/full_grid_rooms/room_barracks_e_full_grid.png`
- `assets/props/full_grid_rooms/room_recovery_w_full_grid.png`
- `assets/props/full_grid_rooms/room_treasure_w_full_grid.png`
- `assets/props/full_grid_rooms/room_build_slot_n_full_grid.png`

Source sheet:

- `docs/concepts/full_grid_room_object_sprite_sheet_source_2026-07-06.png`

Runtime wiring:

- `data/dungeon_quarter/asset_manifest.json` now supports `connection_sprites` entries for room props.
- `QuarterDungeonRenderer.gd` loads `connection_sprites` into texture keys shaped as `prop:<prop_id>:<connection_variant>:<layer>`.
- The renderer now prefers the connected variant sprite when `slot.connection_variant` matches a `connection_sprites` key.
- If a connected variant is missing, it falls back to the existing prop sprite and connection marks.
- `QuarterModuleSmokeTest.gd` verifies current default layout variants:
  - entrance `e`
  - throne `s`
  - barracks `e`
  - recovery `w`
  - treasure `w`
  - build slot `n`

Verification after this pass:

- `python -m json.tool data\dungeon_quarter\asset_manifest.json`: PASS.
- `godot --headless --path . --import`: PASS, generated import metadata for the six new runtime sprites.
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`.
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`.
- `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS, captures updated.

Remaining visual limitation:

- The current default layout has real connected room sprites.
- The project still does not have dedicated bitmap variants for every possible `N/E/S/W` side combination.
- The next art pass should generate remaining side combinations or reusable overlays, then add proper `2x2` doorway/path sprites and `1xN` wall/decor strips.

## Required Path Connection Pass

User asked to implement the required images and connected paths first, then review the result visually.

Implemented:

- `QuarterDungeonRenderer.gd` now builds `connection_bridge_records` directly from `root.graph.connection_pairs()`.
- Every connected socket pair produces one bridge record only when both endpoint sockets are currently `connected`.
- The default layout has 12 connected socket bridges:
  - six logical two-cell room openings,
  - two bridge records per two-cell opening.
- Bridge records are grouped by endpoint instance and side; the default layout has six visible path-mouth groups.
- Corridor cells now receive a path-specific stone tint/seam layer so the center path reads as a corridor, not ordinary room floor.
- Connected socket mouths are redrawn after room objects so the doorway/path edge remains visible even when a full-grid room sprite covers most of the macro grid.

Tests added:

- `debug_connection_bridge_count()` verifies the default layout draws 12 bridge records.
- `debug_connection_bridge_group_count()` verifies those records collapse into six paired two-cell openings.
- Map editor disconnect now verifies the selected room removes two visual socket bridges.
- Map editor reconnect verifies the 12 visual socket bridges are restored.

Verification after this pass:

- `python -m json.tool data\dungeon_quarter\asset_manifest.json`: PASS.
- `python -m json.tool data\dungeon_quarter\starting_layout.json`: PASS.
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`.
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`.
- `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS, captures updated.

Updated captures to review:

- `tmp/manual_verification/01_management.png`
- `tmp/manual_verification/01_map_editor_disconnected.png`
- `tmp/manual_verification/03_combat_start.png`

## Projection Correction Pass

User caught a production-blocking issue: the current runtime grid is an isometric diamond grid, but the generated full-grid room sprites read as front-facing rectangular rooms. This cannot be used for mass production.

Decision:

- A room sprite is not acceptable just because it fills a `5x5` footprint.
- A production room sprite must match the engine projection:
  - `128x64` diamond cell basis,
  - visible footprint aligned to the same N/E/S/W diamond edges as the tile grid,
  - no front-facing rectangular room box,
  - no straight-on camera or orthographic front facade,
  - all walls, floors, and connection mouths must sit on the same iso/quarter-view perspective.

Runtime guard implemented:

- `QuarterDungeonRenderer.gd` no longer uses `connection_sprites` just because the variant key exists.
- A connected room sprite is used only when the prop metadata declares `connection_sprite_projection: "iso_diamond_5x5"`.
- The six generated full-grid PNGs currently do not have that metadata and are therefore rejected at runtime.
- Until projection-safe assets are generated, the renderer draws a procedural `5x5` diamond room footprint from the actual tile cells and draws the existing facing prop as a smaller room marker on top.
- This keeps the layout, path connectivity, and room scale testable without showing wrong front-view room art.

Tests added/updated:

- `debug_full_grid_room_projection_count()` verifies the six room footprints are drawn through the projection-safe path.
- `debug_object_uses_projection_safe_connection_sprite()` verifies the old front-view generated room sprite is not being used.
- Object texture tests now expect facing marker sprites such as `prop:throne_f:SW:back` over the iso footprint, not `prop:throne_f:s:back`.

Production rule for the next image batch:

- Do not generate more full-grid room sprites until a projection-safe sample is approved in `tmp/manual_verification/01_management.png`.
- Future accepted assets must add `connection_sprite_projection: "iso_diamond_5x5"` in `data/dungeon_quarter/asset_manifest.json`; otherwise the renderer will deliberately ignore them.

## Building Wall / Door Correction Pass

User clarified the intended rule:

- A building object is not an open patch of floor.
- Every full-grid `5x5` building must be surrounded by walls except where a connected path opens a paired two-cell doorway.
- Therefore every building image/variant is really a wall-state variant:
  - closed side = wall,
  - connected side = two-cell doorway/opening,
  - unconnected/open-placeholder side = wall until an actual path is connected.
- The reason for separating floor tiles and walls is gameplay: characters move on floor/walk cells, while wall edges control which floor cells can be reached.

Implemented runtime guard:

- `QuarterDungeonRenderer.gd` now builds room wall records for each full-grid room footprint.
- Each `5x5` room has 20 outer edge segments.
- Default six rooms expose 120 outer segments.
- The current default layout has 12 connected doorway segments, because six paired openings have two socket cells each.
- The remaining 108 outer segments render as walls.
- Disconnecting the selected barracks path changes the counts to 10 doorway segments and 110 wall segments.
- Room floor rendering is dimmed and overlaid by a room footprint fill, while corridor cells keep a stronger path-specific stone layer. This makes room interior vs path/corridor visually distinct before final art exists.

Tests added/updated:

- `debug_room_wall_segment_count()` verifies total, wall, and door segment counts.
- Map editor disconnect verifies the two removed path sockets become wall segments again.
- Map editor reconnect verifies doorway segments are restored.

Verification after this pass:

- `python -m json.tool data\dungeon_quarter\asset_manifest.json`: PASS.
- `python -m json.tool data\dungeon_quarter\room_blueprints.json`: PASS.
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`.
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`.
- `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS.

Updated captures:

- `tmp/manual_verification/01_management.png`
- `tmp/manual_verification/01_map_editor_disconnected.png`

## Building Footprint Fill Tuning

User clarified that even with walls, the building still looked too small inside one macro grid. The full-grid room must visually occupy the whole grid, not read as a small prop or a thin wall outline around empty space.

Implemented:

- Full-grid room footprint cells now draw with less inset, so the room mass fills the `5x5` macro grid more completely.
- Boundary ring cells receive a stronger wall-base fill, reducing the "empty floor patch" look.
- Room perimeter lines are thicker.
- Procedural wall risers are taller and wider.
- Fallback facing prop markers now use a larger `4x4` central draw rect instead of the previous `3x3` marker rect.

Important:

- This is still a procedural fallback until approved projection-safe room sprites exist.
- The production asset target remains: one room image must occupy the full `5x5` macro grid with walls, door openings, and interior role art integrated in the same iso projection.

Verification after this tuning:

- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`.
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`.
- `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS, captures updated.

## Center-Facing Object Direction Rule

User clarified that every room object image must face the dungeon center. The facing is not the same as the logical socket side. It is the screen-facing direction after the iso/quarter projection.

Implemented:

- `ModuleGraph.gd` now computes room-object facing from the placed room center to the central corridor/junction center.
- Existing blueprint/layout `facing` values no longer silently win over the center-facing rule.
- `directionless` objects such as traps are preserved.
- Current 4x4 novice layout facing map:
  - `throne` at top center -> `SW`.
  - `entrance` on lower-left -> `SE`.
  - `barracks` on upper-left -> `SE`.
  - `recovery` on upper-right -> `NW`.
  - `treasure` on lower-right -> `NW`.
  - `slot_01` at bottom center -> `NE`.
- `starting_layout.json` and `custom_layouts.json` were updated so their visible `object_facing` fields match the same rule.

Important:

- For the user's explicit throne example, the center-facing runtime request key is `prop:throne_f:SW:back`.
- This only proves that the runtime selected the requested facing key. It does not prove that the PNG visually faces SW.
- The current v3 facing PNGs are placeholder/legacy facing assets, not validated production room images. The user observed the current throne image still reads as SE-facing, and that observation is valid.
- Future production room images must be generated in the center-facing direction for their macro-grid position, not in a generic front-facing or arbitrary side variant.

Latest correction after user review:

- The previous direction rule was incomplete because it treated `NW`, `NE`, `SE`, and `SW` mostly as runtime keys.
- Correct rule: the facing name is the direction the object's front points toward.
  - `NW`: front points northwest; for a throne, the back/away side must be visible.
  - `NE`: front points northeast.
  - `SE`: front points southeast.
  - `SW`: front points southwest/lower-left.
- Current contact-sheet review shows the existing v3 throne variants do not satisfy this rule; at least two facings read effectively the same/front-ish. They are rejected for production direction art.
- `asset_manifest.json` now marks the v3 facing sprites as `unverified_direction_placeholder` and rejects duplicate or near-identical facing variants.
- Do not tell the user that direction is visually fixed until a new contact sheet proves all four direction images are distinct and correctly oriented.

Required asset work before claiming visual direction is correct:

- Make verified center-facing images for each room role and facing direction.
- Make wall/door state variants for each connected-side mask:
  - closed side = rough cave stone wall,
  - connected paired side = two-cell doorway/opening,
  - unconnected placeholder = wall until actually connected.
- Worst-case baked set is `room_role * facing * connection_mask`, for example six room roles * four facings * sixteen N/E/S/W wall masks = 384 full-room images.
- Prefer a modular production atlas if possible:
  - room-role interior/facing base,
  - rough cave wall overlays,
  - paired doorway overlays,
  - path-mouth overlays.
  This avoids hand-authoring every full baked combination while still making the visual state depend on facing and connections.

## Full-Grid Room Object Production Contract

User asked to combine the existing image work with the corrected rules and prepare the object-image generation rules for mass production.

New contract:

- `docs/IMAGEGEN_CONTRACT_FULL_GRID_ROOM_OBJECT_VARIANTS_01.md`

Production rule:

- Full-grid room-role object selection is now conceptually `prop_id + facing + open_mask + layer`.
- `facing` uses `NW`, `NE`, `SE`, `SW` as object-front directions.
- `open_mask` uses canonical bits `N=1`, `E=2`, `S=4`, `W=8`.
- There are 16 wall/opening states per facing:
  - open side = real connected paired socket,
  - closed side = rough cave stone wall,
  - open placeholder = still blocked/walled for movement and generation.
- One full-grid room object therefore needs `4 facings * 16 open masks = 64` variants per layer.
- Split-layer production doubles that to 128 images per role when both `back` and `front` layers are required.

Current production count estimate:

- Six required novice room objects as one composite layer each: `6 * 64 = 384` images.
- If split into `back/front` for every required role: `6 * 128 = 768` images.
- Matching the current prop layer structure exactly gives 448 required layer images:
  - entrance `64`,
  - throne `128`,
  - barracks `64`,
  - recovery `64`,
  - treasure `64`,
  - build slot `64`.
- Including future `watch_post` adds 64 more, for 512 full-grid-capable layer images.

Mass production guard:

- Do not generate all images at once.
- First proof composition must include both `throne_f` and `entrance_gate_f`; the dungeon entrance is not optional.
- First approve four-direction proof sheets for both throne and dungeon entrance.
- Then approve a `throne_f + SW` 16-mask wall/opening proof sheet.
- Also prove `entrance_gate_f + SE + open_02` before generating the default-layout slice.
- Then generate only the six default-layout required variants:
  - throne `SW/open_04`,
  - barracks `SE/open_02`,
  - recovery `NW/open_08`,
  - entrance `SE/open_02`,
  - treasure `NW/open_08`,
  - build slot `NE/open_01`.
- Batch production starts only after those proof sheets pass visual QA.

Data update:

- `data/dungeon_quarter/asset_manifest.json` now declares `room_object_production_contract`.
- `tools/QuarterModuleSmokeTest.gd` verifies the contract id, projection, mask bits, variant count, and six default-layout production variants.

## First Proof Image With Dungeon Entrance

User clarified that the example composition must include the dungeon entrance before mass-production rules continue.

Generated proof concept:

- `docs/concepts/full_grid_room_object_proof_throne_entrance_2026-07-06.png`
- Companion note: `docs/concepts/full_grid_room_object_proof_throne_entrance_2026-07-06.md`

Structure correction:

- The proof sequence now starts with `composition_throne_plus_dungeon_entrance`.
- `room_object_production_contract.first_proof_object_ids` now includes both `throne_f` and `entrance_gate_f`.
- The generated image is proof/concept only, not production-approved runtime art.
- Direction correctness still requires a labeled contact sheet and user review before slicing or batch generation.

Verification after this rule:

- `python -m json.tool data\dungeon_quarter\starting_layout.json`: PASS.
- `python -m json.tool data\dungeon_quarter\custom_layouts.json`: PASS.
- `python -m json.tool data\dungeon_quarter\asset_manifest.json`: PASS.
- `python -m json.tool data\dungeon_quarter\room_blueprints.json`: PASS.
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`, checked with ERROR/FAIL filtering.
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`, checked with ERROR/FAIL filtering.
- `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS, checked with ERROR filtering and captures updated.

## Remaining Room Proof Image

User asked to create proof imagery for the remaining rooms using the same production rule.

Generated proof concept:

- `docs/concepts/full_grid_room_object_proof_remaining_rooms_2026-07-06.png`
- Companion note: `docs/concepts/full_grid_room_object_proof_remaining_rooms_2026-07-06.md`

Sheet structure:

- 4 rows x 4 columns, no labels in the image.
- Columns are `NW`, `NE`, `SE`, `SW` object-front directions.
- Row 1: barracks / `weapon_rack` / `open_02` east paired doorway.
- Row 2: recovery / `recovery_nest_f` / `open_08` west paired doorway.
- Row 3: treasure / `treasure_pile_large` / `open_08` west paired doorway.
- Row 4: build slot / `foundation_marks` / `open_01` north paired doorway.

Important:

- This is proof/concept only, not a sliced runtime atlas.
- The image should be visually reviewed for direction correctness and paired doorway placement before any slicing or batch generation.
- `asset_manifest.json` now records this as `remaining_proof_image_path` and lists the four remaining proof object IDs.
- `QuarterModuleSmokeTest.gd` verifies that the proof image exists and that the remaining proof object IDs are declared.

## Full-Grid Path Connection Proof

User clarified another key visual rule:

- The desired dungeon is not rooms plus a fully filled floor plate.
- The six full-grid room objects must be connected by visible route/path corridors.
- Empty macro cells should stay cave void or unbuilt space.
- The path must exist only where the data route says it exists.

New path contract:

- `docs/IMAGEGEN_CONTRACT_FULL_GRID_PATH_CONNECTIONS_01.md`

Current path rule:

- `PATH_MAIN` uses `spike_corridor`, module `corridor_spike_ns_01`.
- It spans `G01_01` and `G01_02`.
- It is a two-cell-wide route skeleton, not a filled `5x10` floor slab.
- The route connects six paired door mouths:
  - throne `S`,
  - barracks `E`,
  - recovery `W`,
  - entrance `E`,
  - treasure `W`,
  - build slot `N`.
- The default layout still has 12 bridge segments, grouped into six paired path mouths.

Generated proof images:

- `docs/concepts/full_grid_path_connection_layout_proof_2026-07-06.png`
- `docs/concepts/full_grid_path_connection_layout_proof_2026-07-06.md`
- `docs/concepts/full_grid_path_component_proof_2026-07-06.png`
- `docs/concepts/full_grid_path_component_proof_2026-07-06.md`

Important:

- These images are proof/concept only, not sliced runtime atlases.
- The layout proof is the current target for "objects connected by paths, not floor fill."
- The component proof identifies future path strips, 2x2 junctions, doorway mouths, spike inserts, and rubble boundaries.
- `asset_manifest.json` now declares `path_connection_production_contract`.
- `QuarterModuleSmokeTest.gd` verifies the path contract id, proof file paths, two-cell width, empty-cell policy, and six connected room sides.

## Grid-Accurate Path Concept

User asked whether the previous concept actually matched the current grid structure.

Answer:

- The previous AI proof followed the intended layout, but it was not guaranteed to be grid-accurate.
- A deterministic grid-accurate concept was generated from the actual project data.

Generated files:

- `docs/concepts/full_grid_path_connection_grid_accurate_concept_2026-07-06.png`
- `docs/concepts/full_grid_path_connection_grid_accurate_concept_overlay_2026-07-06.png`
- `docs/concepts/full_grid_path_connection_grid_accurate_concept_2026-07-06.md`
- `tools/generate_grid_accurate_path_concept.py`

What it uses:

- `data/dungeon_quarter/starting_layout.json`
- `data/dungeon_quarter/room_blueprints.json`
- actual `grid_origin` values,
- actual `corridor_spike_ns_01.floor_cells`,
- actual paired socket entries and connections.

Important judgment point:

- In the real isometric projection, logical macro cells project along diagonal screen axes.
- If the user wants the throne or rooms to sit in a different screen composition, the correct fix is to revise the macro layout/camera framing rule before generating more freehand art.

Verification:

- `asset_manifest.json` now records the grid-accurate concept paths and generator.
- `QuarterModuleSmokeTest.gd` verifies those files exist.

## GPT Image 2 Path Concept Resubmission

User rejected the grid-debug render as not readable enough and asked to use GPT Image 2.

Generated with built-in `image_gen`:

- Superseded first pass:
  - `docs/concepts/full_grid_path_connection_gpt_image2_concept_2026-07-06.png`
  - `docs/concepts/full_grid_path_connection_gpt_image2_concept_2026-07-06.md`
- Current grid-reference repaint pass:
  - `docs/concepts/full_grid_path_connection_gpt_image2_grid_repaint_concept_2026-07-06.png`
  - `docs/concepts/full_grid_path_connection_gpt_image2_grid_repaint_concept_2026-07-06.md`

Purpose:

- Present a polished concept art target using the same current path/room structure.
- Show six large full-grid rooms connected by explicit corridors.
- Keep empty macro areas as cave void, not filled floor.
- Show paired doorway mouths and a central spike corridor.

Important:

- This image is for art-direction review.
- It is GPT Image 2 art, not a deterministic grid render and not a runtime atlas.
- If accepted, future production should use this as the look target and the grid-accurate concept as the placement target.
- The first GPT Image 2 pass drifted into a radial/symmetric layout and is no longer the current target.
- The current repaint pass was prompted from the grid-accurate reference and should be reviewed instead.

## Rough Cave Stone Wall Pass

User clarified that the dungeon is a small Demon King castle inside a cave, so the walls should not read as clean castle rails. They should look like roughly stacked cave stones or an improvised stone fence around each room.

Implemented:

- Reduced the clean rail feel of the room wall fallback.
- Wall height is slightly lower and more uneven.
- Regular stone courses were replaced with more irregular stones:
  - varied block widths,
  - staggered offsets,
  - uneven top lifts,
  - lumpy cap stones drawn with thick irregular strokes,
  - spilled rubble/loose stones along the base.
- Removed the clean continuous top highlight that made the wall feel too polished.
- Door/path logic and wall segment counts are unchanged.

Current visual target:

- Procedural fallback should read as "roughly stacked stone wall in a cave," not "clean rectangular castle border."
- Final production wall art should use this same mood: low, chunky, uneven, cave-built, and visibly hand-stacked.

Verification after this pass:

- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`, checked with ERROR filtering.
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`, checked with ERROR filtering.
- `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS, checked with ERROR filtering and captures updated.

## Full-Grid Room Art Scale Correction

User rejected the previous result because the building art was still too small. The prior fallback made the floor/wall footprint larger, but the actual room-role art still used a reduced central marker rectangle, so each room continued to read like a small prop sitting in a large empty grid.

Implemented:

- Full-grid room fallback drawing no longer uses the reduced marker rectangle.
- Unsafe/front-view generated full-room connection sprites are still rejected, but the existing facing sprites now draw against the whole `5x5` room object rectangle.
- Full-grid room fallback has its own scale clamps:
  - width can scale up to room-object scale instead of normal prop scale,
  - max height is allowed to exceed the floor rect for tall room/building silhouettes,
  - bottom offsets are room-specific so large art remains seated inside the room.
- This keeps the current connection/wall logic unchanged while making the visible building art much closer to the approved concept scale.

Current limitation:

- This is still enlarged existing facing prop art, not final integrated room art.
- Final production sprites must be authored as one complete `5x5` room image per wall/door state. Do not rely on a tiny prop plus empty floor.

Verification after this correction:

- `python -m json.tool data\dungeon_quarter\asset_manifest.json`: PASS.
- `python -m json.tool data\dungeon_quarter\room_blueprints.json`: PASS.
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`.
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`.
- `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS, captures updated.

## Dungeon Stone Wall Tuning

User accepted the larger room/building scale, then rejected the wall material as too clean and rectangular. The wall should read as dungeon stone, not a neat UI frame.

Implemented:

- Room boundary walls still use the same wall/door records and do not change path connectivity.
- The flat wall face now draws procedural stone courses:
  - per-edge uneven top height,
  - stacked stone blocks with varied shade,
  - mortar lines and dark lower shadows,
  - occasional cracks and subtle purple dungeon glow.
- The room footprint perimeter no longer draws one clean bright outline. It now draws a darker base edge plus broken stone-edge highlights and chipped spots.

Current limitation:

- This is procedural placeholder wall dressing. It improves readability and mood, but production should eventually replace it with a dedicated iso-diamond `5x5` room wall/door atlas.
- Future atlas work must preserve the same logic: closed room edges are walls, connected paired socket cells are door openings.

Verification after this tuning:

- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`.
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`.
- `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS, captures updated.
