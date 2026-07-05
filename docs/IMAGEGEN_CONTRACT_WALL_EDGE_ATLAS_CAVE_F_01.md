# Image Generation Contract - wall_edge_atlas_cave_f_01

이 문서는 cave F 등급 3x3 기본 던전의 벽 edge atlas를 내장 GPT Image 2로 만들기 전에 고정해야 하는 배치 계약이다.

## Placement Contract

- `asset_id`: `wall_edge_atlas_cave_f_01`
- `asset_type`: `wall edge atlas sheet`
- `grid_size`: `[3, 3]`
- `master_grid_origin`: `[8, 8]`
- `grid_cells`: `G00_00`, `G01_00`, `G02_00`, `G00_01`, `G01_01`, `G02_01`, `G00_02`, `G01_02`, `G02_02`
- `anchor_cell`: each wall edge uses the floor cell that owns the edge record.
- `layer`: `wall_back` for `N/W`, `wall_front` for `E/S`
- `final_manifest_path`:
  - `data/dungeon_quarter/tile_variant_manifest.json`
  - `data/dungeon_quarter/asset_manifest.json`
- `final_asset_folder`: `assets/tiles/cave_v2/wall_edges`

## Open Edge Records

These edges must stay visually open. The renderer must not draw closed walls on them.

| edge_id | cell | side | neighbor | role |
|---|---|---|---|---|
| `O_G00_01_E` | `G00_01` | `E` | `G01_01` | entrance to spike corridor |
| `O_G01_01_W` | `G01_01` | `W` | `G00_01` | spike corridor to entrance |
| `O_G01_01_E` | `G01_01` | `E` | `G02_01` | spike corridor to barracks |
| `O_G02_01_W` | `G02_01` | `W` | `G01_01` | barracks to spike corridor |
| `O_G02_01_N` | `G02_01` | `N` | `G02_00` | barracks to recovery |
| `O_G02_00_S` | `G02_00` | `S` | `G02_01` | recovery to barracks |
| `O_G02_00_W` | `G02_00` | `W` | `G01_00` | recovery to treasure |
| `O_G01_00_E` | `G01_00` | `E` | `G02_00` | treasure to recovery |
| `O_G01_00_W` | `G01_00` | `W` | `G00_00` | treasure to throne |
| `O_G00_00_E` | `G00_00` | `E` | `G01_00` | throne to treasure |

## Closed Edge Records For Default Layout

These numbered edge slots must render as wall/blocked boundaries unless the layout changes.

| edge_id | cell | side | layer | reason |
|---|---|---|---|---|
| `E_G00_00_N` | `G00_00` | `N` | `wall_back` | throne north boundary |
| `E_G00_00_S` | `G00_00` | `S` | `wall_front` | throne to entrance is blocked |
| `E_G00_00_W` | `G00_00` | `W` | `wall_back` | throne west boundary |
| `E_G01_00_N` | `G01_00` | `N` | `wall_back` | treasure north boundary |
| `E_G01_00_S` | `G01_00` | `S` | `wall_front` | treasure to spike corridor is blocked |
| `E_G02_00_N` | `G02_00` | `N` | `wall_back` | recovery north boundary |
| `E_G02_00_E` | `G02_00` | `E` | `wall_front` | recovery east boundary |
| `E_G00_01_N` | `G00_01` | `N` | `wall_back` | entrance to throne is blocked |
| `E_G00_01_S` | `G00_01` | `S` | `wall_front` | entrance south boundary |
| `E_G00_01_W` | `G00_01` | `W` | `wall_back` | entrance west boundary |
| `E_G01_01_N` | `G01_01` | `N` | `wall_back` | spike corridor to treasure is blocked |
| `E_G01_01_S` | `G01_01` | `S` | `wall_front` | spike corridor south boundary |
| `E_G02_01_E` | `G02_01` | `E` | `wall_front` | barracks east boundary |
| `E_G02_01_S` | `G02_01` | `S` | `wall_front` | barracks south boundary |

The table above lists 14 logical closed sides from the room contract. The renderer de-duplicates shared physical walls, so the default layout emits 12 rendered wall edge records. For example, `E_G00_00_S` and `E_G00_01_N` describe the same physical wall between throne and entrance; the renderer keeps the canonical `N` owner, `E_G00_01_N`.

## Renderer Algorithm

The renderer must derive wall placement from the logical floor grid.

1. Iterate every floor cell.
2. Check the four logical sides in this order: `N`, `E`, `S`, `W`.
3. If `open_edge_set` contains `cell:side`, skip the closed wall for that side.
4. If the side is closed and the neighboring cell is also a floor cell, emit only the canonical owner edge:
   - `N` and `W` sides own shared closed edges.
   - `E` and `S` sides are skipped because the neighbor's opposite `W` or `N` side owns the same physical wall.
5. If the neighbor is not a floor cell, emit the current cell side as a boundary wall.
6. For every emitted wall record, compute its two diamond endpoints from the tile rect.
7. Count how many wall records touch each endpoint.
8. `join_prev` and `join_next` are true when the matching endpoint is shared by another wall record.
9. Select a sprite key from `side + variant`:
   - `straight`: both endpoints join another wall.
   - `end_a`: only the first endpoint is open.
   - `end_b`: only the second endpoint is open.
   - `cap`: neither endpoint joins.
10. Render `N/W` records in `BackWallLayer`; render `E/S` records in `FrontWallLayer`.

초보자식으로 말하면, 바닥 타일 그림을 보고 벽을 추측하지 않고 "바닥 한 칸의 테두리 네 줄"을 실제 데이터로 검사한다. 통로로 연결된 줄은 비워두고, 막힌 줄만 벽 후보로 만든 뒤, 같은 줄을 두 번 그리지 않게 한 번만 그린다.

## Required Atlas Keys

The generated sheet must support these logical keys. The visual source may alias similar shapes internally, but the manifest must expose the keys separately.

- `wall_N_straight`, `wall_N_end_a`, `wall_N_end_b`, `wall_N_cap`
- `wall_E_straight`, `wall_E_end_a`, `wall_E_end_b`, `wall_E_cap`
- `wall_S_straight`, `wall_S_end_a`, `wall_S_end_b`, `wall_S_cap`
- `wall_W_straight`, `wall_W_end_a`, `wall_W_end_b`, `wall_W_cap`
- `wall_corner_NE`, `wall_corner_ES`, `wall_corner_SW`, `wall_corner_WN`
- `wall_cap_closed_N`, `wall_cap_closed_E`, `wall_cap_closed_S`, `wall_cap_closed_W`
- `door_open_N`, `door_open_E`, `door_open_S`, `door_open_W`
- `socket_placeholder_N`, `socket_placeholder_E`, `socket_placeholder_S`, `socket_placeholder_W`

## Built-In GPT Image 2 Prompt

Use case: stylized-concept
Asset type: 2D game isometric dungeon wall edge atlas sheet
Primary request: Create a modular quarter-view cave dungeon wall edge atlas for a Godot 2D tile map.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for later alpha removal.
Subject: isolated dark stone wall edge sprites, doorway sprites, and construction placeholder socket sprites for a Demon King's cave dungeon.
Style/medium: painterly pixel-adjacent 2D game sprites, top-down isometric/quarter-view, rugged basalt blocks, moss, cracks, warm torch highlights, no characters.
Composition/framing: one clean contact sheet with 8 columns and 4 rows, each tile isolated with generous padding, consistent camera angle and lighting. Row 1 N wall variants, row 2 E wall variants, row 3 S wall variants, row 4 W wall variants. Columns: straight, end_a, end_b, cap, closed_cap, door_open, placeholder, corner accent.
Lighting/mood: moody cave dungeon, readable silhouettes, high contrast edges.
Materials/textures: rough dark stone, chipped masonry, carved cave wall lips, small shadow under each wall piece but no shadow on the green background.
Constraints: the background must be one uniform #00ff00 color with no texture, gradients, shadows, text, labels, watermarks, UI, characters, or floor tiles. Do not use #00ff00 in the sprites. Keep every sprite fully inside its cell with transparent-friendly crisp edges.
Avoid: perspective mismatch, full room images, mini-map symbols, text labels, rotated duplicates that do not respect N/E/S/W directions.
