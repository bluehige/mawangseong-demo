# Image Generation Contract - cave_f_floor_edge_atlas_01

이 문서는 1차 동굴형 마왕성에 필요한 바닥/edge/corner atlas를 Codex 내장 GPT Image 2로 만들기 전에 고정하는 배치 계약이다.

This contract defines the required placement and slicing rules before generating the floor, edge, and corner atlas for the first cave-type Demon King castle pass with Codex built-in GPT Image 2.

## Why This Exists

Current audit found these rule failures:

- `floor_cave_v2_mask_00~15`: only 4 unique images for 16 logical masks.
- `edge_cave_v2_*_lip`: 4 directions reuse the same image.
- `floor_cave_v2_corner_*`: all 8 files are fully transparent.

These are not enough to build a readable quarter-view cave dungeon. The fix is to generate project-bound raster assets, then slice/post-process them into the existing manifest paths.

## Floor Mask Contract

- `asset_id`: `floor_mask_atlas_cave_f_01`
- `asset_type`: `4x4 floor connection atlas`
- `grid_size`: `[4, 4]`
- `tile_size`: `[128, 64]`
- `bit_rule`: `N=1`, `E=2`, `S=4`, `W=8`
- `grid_cells`: `M00` through `M15`, row-major order.
- `final_asset_folder`: `assets/tiles/cave_v2/floor`
- `final_manifest_path`: `data/dungeon_quarter/tile_variant_manifest.json`

Mask slots:

| slot | mask | connected sides |
|---|---:|---|
| `M00` | 0 | none |
| `M01` | 1 | N |
| `M02` | 2 | E |
| `M03` | 3 | N,E |
| `M04` | 4 | S |
| `M05` | 5 | N,S |
| `M06` | 6 | E,S |
| `M07` | 7 | N,E,S |
| `M08` | 8 | W |
| `M09` | 9 | N,W |
| `M10` | 10 | E,W |
| `M11` | 11 | N,E,W |
| `M12` | 12 | S,W |
| `M13` | 13 | N,S,W |
| `M14` | 14 | E,S,W |
| `M15` | 15 | N,E,S,W |

Visual rule:

- Connected sides have a visible stone path continuation/open edge to that side.
- Unconnected sides have chipped broken floor rim and cave darkness/void edge.
- All 16 slots must be visually distinguishable.
- The atlas must remain quarter-view/isometric-down, not flat top-down UI icons.

## Edge And Corner Contract

- `asset_id`: `edge_corner_atlas_cave_f_01`
- `asset_type`: edge lip and corner overlay atlas
- `grid_size`: `[4, 3]`
- `tile_size`: `[128, 64]`
- `final_asset_folders`:
  - `assets/tiles/cave_v2/edge`
  - `assets/tiles/cave_v2/overlay`
- `final_manifest_path`: `data/dungeon_quarter/tile_variant_manifest.json`

Atlas slots:

| slot | output key | final file |
|---|---|---|
| `E00` | `nw_lip` | `edge_cave_v2_nw_lip.png` |
| `E01` | `ne_lip` | `edge_cave_v2_ne_lip.png` |
| `E02` | `se_lip` | `edge_cave_v2_se_lip.png` |
| `E03` | `sw_lip` | `edge_cave_v2_sw_lip.png` |
| `C00` | `outer_nw` | `floor_cave_v2_corner_outer_nw.png` |
| `C01` | `outer_ne` | `floor_cave_v2_corner_outer_ne.png` |
| `C02` | `outer_se` | `floor_cave_v2_corner_outer_se.png` |
| `C03` | `outer_sw` | `floor_cave_v2_corner_outer_sw.png` |
| `C04` | `inner_nw` | `floor_cave_v2_corner_inner_nw.png` |
| `C05` | `inner_ne` | `floor_cave_v2_corner_inner_ne.png` |
| `C06` | `inner_se` | `floor_cave_v2_corner_inner_se.png` |
| `C07` | `inner_sw` | `floor_cave_v2_corner_inner_sw.png` |

Visual rule:

- Edge lips must be directional. `nw_lip`, `ne_lip`, `se_lip`, and `sw_lip` cannot be the same bitmap.
- Corner overlays must contain non-empty transparent PNG art.
- The art should look like chipped cave-floor rims, shadowed broken stone, moss, cracks, and small rim highlights.

## Built-In GPT Image 2 Prompt - Floor

Use case: stylized-concept
Asset type: 2D game isometric floor connection atlas
Primary request: Create a 4x4 atlas of modular quarter-view cave dungeon floor tiles for a Godot 2D tile map.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for later alpha removal.
Subject: 16 isolated isometric diamond stone floor tiles for a Demon King's cave dungeon, mask order 0 through 15 in row-major order using bit rule N=1, E=2, S=4, W=8.
Style/medium: painterly pixel-adjacent 2D game sprites, dark basalt slabs, cracked stone, moss, worn path centers, readable silhouettes.
Composition/framing: exactly 4 columns and 4 rows, no labels, each tile centered in its slot with generous padding. Each tile is a 2:1 isometric diamond floor footprint.
Directional rule: connected sides show a visible stone path continuation to that side; unconnected sides show chipped broken rim and cave void.
Lighting/mood: moody cave dungeon with subtle purple shadows and warm torch glints.
Constraints: uniform #00ff00 background only; no text, no labels, no room objects, no walls, no doors, no characters, no UI, no watermark. Do not use #00ff00 in the tiles.
Avoid: identical repeated tiles, orthographic top-down squares, full room images, mini-map symbols.

## Built-In GPT Image 2 Prompt - Edge/Corner

Use case: stylized-concept
Asset type: 2D game isometric edge and corner overlay atlas
Primary request: Create a 4x3 atlas of directional cave floor edge lips and corner overlays for a quarter-view dungeon.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for later alpha removal.
Subject: 4 directional edge lip overlays and 8 corner overlay sprites for a Demon King's cave dungeon floor.
Style/medium: painterly pixel-adjacent 2D game sprites, chipped basalt rim, moss, cracks, cave shadow, small purple ambient highlights.
Composition/framing: exactly 4 columns and 3 rows, no labels, each sprite centered in its slot. Row 1: NW lip, NE lip, SE lip, SW lip. Row 2: outer NW corner, outer NE corner, outer SE corner, outer SW corner. Row 3: inner NW corner, inner NE corner, inner SE corner, inner SW corner.
Constraints: uniform #00ff00 background only; no text, no labels, no floor full tiles, no walls, no doors, no characters, no UI, no watermark. Do not use #00ff00 in the sprites.
Avoid: identical repeated directions, top-down square corners, full room images, mini-map symbols.
