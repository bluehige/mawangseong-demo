# Image Generation Contract - bg_cave_f_3x3_01

This contract must be used before generating the cave background plate with built-in GPT Image 2.

## Placement Contract

- `asset_id`: `bg_cave_f_3x3_01`
- `asset_type`: `background plate`
- `grid_size`: `[3, 3]`
- `master_grid_origin`: `[8, 8]`
- `grid_cells`: `G00_00`, `G01_00`, `G02_00`, `G00_01`, `G01_01`, `G02_01`, `G00_02`, `G01_02`, `G02_02`
- `anchor_cell`: `G01_01`
- `connected_sides`: background must visually allow the default chain but must not encode walkability:
  - `G00_01`: `E`
  - `G01_01`: `W`, `E`
  - `G02_01`: `W`, `N`
  - `G02_00`: `S`, `W`
  - `G01_00`: `E`, `W`
  - `G00_00`: `E`
- `blocked_sides`: all non-listed N/E/S/W sides are closed by rock, shadow, or cave wall atmosphere.
- `layer`: `background`
- `final_asset_path`: `assets/backgrounds/v2/bg_cave_f_3x3_01.png`
- `final_manifest_path`: `data/dungeon_quarter/asset_manifest.json`

## Generation Constraints

- The image is atmosphere only. It must not contain hard gameplay paths, collision marks, labels, grid lines, UI, text, room names, characters, props, treasure, throne, barracks furniture, trap spikes, or doors.
- The 3x3 logical room positions may be suggested by broad cave excavation shape, but exact room boundaries must be left to the renderer's floor, edge, wall, socket, and object layers.
- Keep the central playable area darker and readable behind floor tiles; avoid bright clutter under objects.
- Use quarter-view / isometric-down composition matching a 2D dungeon map.
- Leave margins around the 3x3 area for void/rock atmosphere.
