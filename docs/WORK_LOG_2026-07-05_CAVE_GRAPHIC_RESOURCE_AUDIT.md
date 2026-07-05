# 2026-07-05 Cave Graphic Resource Audit And First Assembly

Purpose: record the first pass that combines the current rule-based graphic resources into a cave-type Demon King castle view, and records which generated assets now satisfy the rule set.

## User Direction Captured

- The map must not be a single room image.
- The dungeon must be assembled from rule-based floor cells, edge/wall pieces, doors/openings, props, and walkable cell data.
- For this project, GPT Image 2 means Codex built-in `image_gen`; do not use API/CLI fallback or procedural placeholder art as the final map resource path.

## Audit Before Fix

The resource audit found these failures:

- `assets/tiles/cave_v2/floor/floor_cave_v2_mask_00~15`: 16 files existed, but only 4 unique bitmaps.
- `assets/tiles/cave_v2/edge/edge_cave_v2_*_lip.png`: 4 files existed, but all reused the same bitmap.
- `assets/tiles/cave_v2/overlay/floor_cave_v2_corner_*`: 8 files existed, but they were transparent/empty.
- `assets/props/v2/trap_spike_v2_idle_00.png` and `trap_spike_v2_trigger_00.png`: exact duplicate bitmap.

Wall edge assets from the previous pass were already valid:

- `assets/tiles/cave_v2/wall_edges`: 32 files, 32 unique, non-empty alpha.

## Generated Assets

Built-in `image_gen` was used for every new raster source in this pass.

Floor mask atlas:

- Source: `output/imagegen/floor_mask_atlas_cave_f_01_source.png`
- Chroma alpha: `output/imagegen/floor_mask_atlas_cave_f_01_alpha.png`
- Sliced preview: `output/imagegen/floor_mask_atlas_cave_f_01_sliced_preview.png`
- Final folder: `assets/tiles/cave_v2/floor`
- Contract: `docs/IMAGEGEN_CONTRACT_CAVE_F_FLOOR_EDGE_ATLAS_01.md`

Edge/corner atlas:

- Source: `output/imagegen/edge_corner_atlas_cave_f_01_source.png`
- Chroma alpha: `output/imagegen/edge_corner_atlas_cave_f_01_alpha.png`
- Sliced preview: `output/imagegen/edge_corner_atlas_cave_f_01_sliced_preview.png`
- Final folders:
  - `assets/tiles/cave_v2/edge`
  - `assets/tiles/cave_v2/overlay`
- Contract: `docs/IMAGEGEN_CONTRACT_CAVE_F_FLOOR_EDGE_ATLAS_01.md`

Spike trap sheet:

- Source: `output/imagegen/spike_floor_v2_trap_sheet_01_source.png`
- Chroma alpha: `output/imagegen/spike_floor_v2_trap_sheet_01_alpha.png`
- Sliced preview: `output/imagegen/spike_floor_v2_trap_sheet_01_sliced_preview.png`
- Final files:
  - `assets/props/v2/trap_spike_v2_idle_00.png`
  - `assets/props/v2/trap_spike_v2_trigger_00.png`
  - `assets/props/v2/trap_spike_v2_trigger_01.png`
  - `assets/props/v2/trap_spike_v2_trigger_02.png`
  - `assets/props/v2/trap_spike_v2_trigger_03.png`

## Slicers Added

- `tools/slice_cave_floor_edge_atlas.py`
  - Slices the floor atlas into 16 mask tiles.
  - Slices the edge/corner atlas into 4 directional edge lips and 8 corner overlays.
- `tools/slice_spike_trap_sheet.py`
  - Slices the 5-frame spike trap sheet into 1 idle frame and 4 trigger frames.

## Renderer Change

`scripts/dungeon_quarter/QuarterDungeonRenderer.gd` now:

- loads `corner_overlays` from `data/dungeon_quarter/tile_variant_manifest.json`;
- checks that edge and corner overlay textures are loaded before `has_addon_tile_textures()` passes;
- draws outer corner overlays when two adjacent sides are closed;
- draws inner corner overlays when two adjacent sides are open but the tile still has a closed neighboring side;
- uses slightly smaller wall edge draw scales so floor, doors, and room props remain readable.

Beginner translation: each floor cell now checks the four sides around it. If a side is blocked, it can draw a wall or rim. If two blocked sides meet, it draws a corner detail. If two open sides form a turn, it draws a smaller inside corner detail.

## Audit After Fix

Final resource audit:

- `floor`: 16 files, 16 unique, no empty alpha.
- `edge`: 4 files, 4 unique, no empty alpha.
- `overlay`: 8 files, 8 unique, no empty alpha.
- `wall_edges`: 32 files, 32 unique, no empty alpha.
- `spike`: 5 files, 5 unique, no empty alpha.

Manifest prop audit:

- All prop/trap sprite references in `data/dungeon_quarter/asset_manifest.json` exist.
- No prop sprite is empty.
- The previous idle/trigger_00 trap duplicate is gone.

## Visual Output

Updated captures:

- `tmp/manual_verification/01_management.png`
- `tmp/manual_verification/01_map_editor.png`
- `tmp/manual_verification/01_map_editor_disconnected.png`
- `tmp/manual_verification/03_combat_start.png`
- `tmp/manual_verification/04_combat_trap_trigger.png`
- `tmp/manual_verification/05_combat_controls.png`
- `tmp/manual_verification/06_result.png`

Current first-pass result:

- Cave background plate provides atmosphere only.
- Rule-based floor masks, edge lips, corner overlays, wall edge records, socket caps, room props, units, and trap frames are all layered together.
- The result is still a first assembly pass, not final art polish.

## Verification

Commands run on 2026-07-05:

```powershell
python -m py_compile tools\slice_cave_floor_edge_atlas.py tools\slice_wall_edge_atlas.py tools\slice_spike_trap_sheet.py
python -m json.tool data\dungeon_quarter\tile_variant_manifest.json
python -m json.tool data\dungeon_quarter\asset_manifest.json
godot --headless --path . --import
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --path . --run res://tools/ManualVerificationCapture.tscn
```

Results:

- `QuarterModuleSmokeTest.tscn`: PASS, including floor, corner overlay, wall edge, socket cap, and layout assertions.
- `DemoSmokeTest.tscn`: exit code 0 in this run.
- `ManualVerificationCapture.tscn`: exit code 0; captures updated in `tmp/manual_verification`.

Note: do not use `--script tools/DemoSmokeTest.gd` or `--script tools/QuarterModuleSmokeTest.gd`; that mode does not reliably load Godot autoload singletons in this project. Use the `.tscn` runners with `--run`.
