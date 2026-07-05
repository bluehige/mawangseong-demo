# 2026-07-05 Wall Edge Atlas Pass

Purpose: record the first rule-based wall edge atlas implementation for the quarter-view dungeon.

## What Changed

- Added a numbered image-generation contract before making the atlas:
  - `docs/IMAGEGEN_CONTRACT_WALL_EDGE_ATLAS_CAVE_F_01.md`
- Generated the wall atlas with Codex built-in `image_gen`.
  - Source copied to `output/imagegen/wall_edge_atlas_cave_f_01_source.png`
  - Chroma-key alpha output: `output/imagegen/wall_edge_atlas_cave_f_01_alpha.png`
  - Sliced preview: `output/imagegen/wall_edge_atlas_cave_f_01_sliced_preview.png`
- Added slicer:
  - `tools/slice_wall_edge_atlas.py`
  - The slicer assigns detected alpha components to the nearest 8x4 atlas slot instead of blindly cropping exact grid lines. This avoids neighbor-sprite slivers when the generated contact sheet is not mathematically aligned.
- Added 32 generated wall edge sprites under:
  - `assets/tiles/cave_v2/wall_edges`
- Added `wall_edges` keys to:
  - `data/dungeon_quarter/tile_variant_manifest.json`
- Rewired socket caps in:
  - `data/dungeon_quarter/asset_manifest.json`

## Renderer Algorithm

The renderer now builds wall edge records from the logical floor grid.

1. Iterate every floor cell.
2. For each side `N/E/S/W`, skip the side if `open_edge_set` says the edge is connected.
3. If the side is closed and the neighbor is also a floor cell, render only canonical `N/W` owners so the same physical wall is not drawn twice.
4. If the neighbor is not a floor cell, render the current side as a boundary wall.
5. Compute start/end points from the tile diamond.
6. Count endpoint sharing to derive:
   - `straight`
   - `end_a`
   - `end_b`
   - `cap`
7. Resolve a texture key like `wall_N_straight`.
8. Render `N/W` records in `BackWallLayer`; render `E/S` records in `FrontWallLayer`.

Beginner translation: each floor tile has four border lines. If a border line is an open doorway/path, no wall is drawn there. If the line is closed, the renderer makes exactly one wall record for that line and chooses the wall image based on whether its ends touch other walls.

## Default 3x3 Result

- The room contract has 14 logical closed sides.
- Two pairs are shared physical walls between adjacent rooms.
- After de-duplication the renderer emits 12 actual wall edge records for the default 3x3 layout.

Examples:

- `G00_01 N` renders the blocked wall between entrance and throne.
- `G01_01 N` renders the blocked wall between spike corridor and treasure.
- `G00_00 S` is intentionally not emitted because it is the same physical wall as `G00_01 N`.
- `G00_01 E` is connected to the spike corridor and does not render a closed wall.

## Verification

Commands run on 2026-07-05:

```powershell
python -m py_compile tools\slice_wall_edge_atlas.py
python -m json.tool data\dungeon_quarter\tile_variant_manifest.json
python -m json.tool data\dungeon_quarter\asset_manifest.json
godot --headless --path . --import
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --path . --run res://tools/ManualVerificationCapture.tscn
```

Results:

- `QuarterModuleSmokeTest`: PASS
- `DemoSmokeTest`: PASS
- Manual captures generated in `tmp/manual_verification`

Important smoke assertions added:

- wall edge atlas loads with no missing keys,
- default layout emits 12 de-duplicated closed wall edges,
- blocked entrance north edge resolves to a north wall,
- blocked spike corridor north edge resolves to a north wall,
- shared throne south edge is de-duplicated to entrance north,
- connected entrance east edge does not resolve to a closed wall.

## Remaining Visual Risk

The generated walls are intentionally readable and large for this pass. The next visual review may still tune:

- wall sprite scale,
- per-side anchor offsets,
- door/bridge visibility through dense wall clusters,
- whether corner accent overlays should be drawn separately.
