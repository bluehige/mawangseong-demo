# Image Generation Contract - Cave Object Facing Atlases 01

This contract defines the direction-aware room-object atlases for the demo-complete Demon King castle dungeon pass.

## Rule Basis

- The dungeon is assembled from logical grid cells, floor masks, wall edges, socket state, room-role objects, and walkable cell data.
- Room-role objects are separate visual sprites. They must not define movement, connection state, or wall state.
- Object choice must support `prop_id + facing + layer`, not only `prop_id + layer`.
- For this project, GPT Image 2 means Codex built-in `image_gen`.

## Facing Directions

Columns are always:

| column | facing |
|---|---|
| 0 | `NW` |
| 1 | `NE` |
| 2 | `SE` |
| 3 | `SW` |

All generated objects must use the same quarter-view camera and the same cave-castle style.

## Major Atlas

- `asset_id`: `cave_object_facing_major_01`
- `asset_type`: `4x4 direction-aware room-role object sprite atlas`
- `grid_size`: `[4, 4]`
- `background`: flat `#00ff00` chroma key
- `source_path`: `output/imagegen/cave_object_facing_major_01_source.png`
- `alpha_path`: `output/imagegen/cave_object_facing_major_01_alpha.png`
- `final_asset_folder`: `assets/props/v3`
- `final_manifest_path`: `data/dungeon_quarter/asset_manifest.json`

Rows:

| row | role/layer | final files |
|---|---|---|
| 0 | `throne_f` back/high throne | `prop_throne_v3_<facing>_back.png` |
| 1 | `throne_f` front/low dais | `prop_throne_v3_<facing>_front.png` |
| 2 | `weapon_rack` / barracks cluster | `prop_weapon_rack_v3_<facing>_back.png` |
| 3 | `treasure_pile_large` | `prop_treasure_pile_v3_<facing>_front.png` |

## Support Atlas

- `asset_id`: `cave_object_facing_support_01`
- `asset_type`: `4x5 direction-aware room-role object sprite atlas`
- `grid_size`: `[4, 5]`
- `background`: flat `#00ff00` chroma key
- `source_path`: `output/imagegen/cave_object_facing_support_01_source.png`
- `alpha_path`: `output/imagegen/cave_object_facing_support_01_alpha.png`
- `final_asset_folder`: `assets/props/v3`
- `final_manifest_path`: `data/dungeon_quarter/asset_manifest.json`

Rows:

| row | role/layer | final files |
|---|---|---|
| 0 | `recovery_nest_f` | `prop_recovery_nest_v3_<facing>_front.png` |
| 1 | `entrance_gate_f` | `prop_entrance_gate_v3_<facing>_back.png` |
| 2 | `watch_post` | `prop_watch_post_v3_<facing>_front.png` |
| 3 | `foundation_marks` | `prop_foundation_marks_v3_<facing>_back.png` |
| 4 | `small_brazier` | `prop_small_brazier_v3_<facing>_back.png` |

## Visual Rules

- No labels, no UI, no characters, no full rooms, no walls that imply movement, no watermark.
- Each slot contains one isolated sprite centered with generous padding.
- Every column must read as the same object facing a different quarter-view direction.
- Keep scale and lighting consistent across a row.
- Use compact cave-stone footprints, but do not draw whole rooms.
- Avoid arbitrary unrelated objects; this is a direction-variant atlas, not a decoration sheet.

## Built-In GPT Image 2 Prompt - Major Atlas

Use case: stylized-concept
Asset type: 2D game quarter-view cave dungeon object atlas
Primary request: Create a 4x4 atlas of direction-aware room-role objects for a Demon King's cave dungeon.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for later alpha removal.
Subject: Four columns are the same object facing NW, NE, SE, SW in that order. Row 1: high demonic throne back. Row 2: low throne dais/front step. Row 3: barracks prop cluster with weapon rack, training gear, banner, bedrolls, and crates. Row 4: treasure vault pile with chests, coins, and dull gold storage.
Style/medium: painterly pixel-adjacent 2D game sprites, quarter-view isometric-down camera, dark cave castle fantasy, readable silhouettes.
Composition/framing: exactly 4 columns and 4 rows, no labels and no panel text. Each object isolated with generous padding and compact footprint.
Lighting/mood: moody cave dungeon with muted violet shadows and small warm torch highlights.
Color palette: dark basalt stone, charcoal, muted violet, dull gold, warm torch orange.
Materials/textures: cracked stone, iron, rough wood, cloth banners, gold coins, moss, carved demonic stone.
Constraints: uniform #00ff00 background only; do not use #00ff00 inside objects; no text, no labels, no UI, no characters, no full rooms, no walls, no doors.
Avoid: flat top-down icons, side-scroller perspective, photorealistic render, repeated identical unrotated props, cropped objects, random decoration sheet.

## Built-In GPT Image 2 Prompt - Support Atlas

Use case: stylized-concept
Asset type: 2D game quarter-view cave dungeon object atlas
Primary request: Create a 4x5 atlas of direction-aware support room objects for a Demon King's cave dungeon.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for later alpha removal.
Subject: Four columns are the same object facing NW, NE, SE, SW in that order. Row 1: recovery nest/healing pool with muted teal glow. Row 2: cave entrance gate marker. Row 3: watch post tower. Row 4: empty build foundation marks. Row 5: small brazier.
Style/medium: painterly pixel-adjacent 2D game sprites, quarter-view isometric-down camera, dark cave castle fantasy, readable silhouettes.
Composition/framing: exactly 4 columns and 5 rows, no labels and no panel text. Each object isolated with generous padding and compact footprint.
Lighting/mood: moody cave dungeon with muted violet shadows and small warm torch highlights.
Color palette: dark basalt stone, charcoal, muted violet, dull gold, warm torch orange, muted teal healing glow.
Materials/textures: cracked stone, iron, rough wood, cloth banners, crystals, moss, carved demonic stone.
Constraints: uniform #00ff00 background only; do not use #00ff00 inside objects; no text, no labels, no UI, no characters, no full rooms, no walls, no doors.
Avoid: flat top-down icons, side-scroller perspective, photorealistic render, repeated identical unrotated props, cropped objects, random decoration sheet.
