# Image Generation Contract - cave_object_atlas_01

This contract defines the object atlas required for the first cave-type Demon King castle assembly pass.

## Rule Basis

- The dungeon is assembled from logical floor cells, wall/edge rules, socket state, and object slots.
- Room-role objects must not define movement, floor connectivity, or wall state.
- Objects are visual role markers placed inside the room cell by `data/dungeon_quarter/asset_manifest.json` and `data/dungeon_quarter/room_blueprints.json`.
- For this project, GPT Image 2 means Codex built-in `image_gen`.

## Atlas Contract

- `asset_id`: `cave_object_atlas_01`
- `asset_type`: `3x3 room-role object sprite atlas`
- `grid_size`: `[3, 3]`
- `background`: flat `#00ff00` chroma key
- `final_asset_folder`: `assets/props/v2`
- `final_manifest_path`: `data/dungeon_quarter/asset_manifest.json`

Atlas slots:

| slot | prop id / role | final file |
|---|---|---|
| `P00` | `entrance_gate_f` | `prop_entrance_gate_v2_back.png` |
| `P01` | `throne_f` back/high throne | `prop_throne_v2_back.png` |
| `P02` | `throne_f` front/low dais | `prop_throne_v2_front.png` |
| `P03` | `weapon_rack` / barracks role | `prop_weapon_rack_v2_back.png` |
| `P04` | `treasure_pile_large` | `prop_treasure_pile_v2_front.png` |
| `P05` | `recovery_nest_f` | `prop_recovery_nest_v2_front.png` |
| `P06` | `foundation_marks` | `prop_foundation_marks_v2_back.png` |
| `P07` | `watch_post` | `prop_watch_post_v2_front.png` |
| `P08` | `small_brazier` | `prop_small_brazier_v2_back.png` |

## Visual Rules

- All objects must share the same quarter-view/isometric-down camera.
- Objects must sit on a compact cave-stone floor footprint and have transparent output after chroma removal.
- Do not include labels, UI, text, characters, monsters, enemies, walls, doors, or full rooms.
- Keep silhouettes readable at in-game size.
- The throne must face SW for the current upper-left throne-room placement.
- The barracks object must read as a barracks, not only a single weapon rack: include rack, training gear, banner, bedrolls, or crates as one compact prop cluster.
- The treasure object must read as a storage/vault pile, not scattered coins only.
- The recovery object must read as a healing nest/pool with muted teal or mint glow that is not `#00ff00`.
- The foundation object must read as an empty build slot/foundation, not a finished facility.

## Built-In GPT Image 2 Prompt

Use case: stylized-concept
Asset type: 2D game quarter-view cave dungeon object atlas
Primary request: Create a 3x3 atlas of room-role objects for a Demon King's cave dungeon.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for later alpha removal.
Subject: Nine isolated object sprites, one centered in each atlas slot. Row 1: entrance gate, SW-facing demon throne high back, low throne dais/front step. Row 2: barracks prop cluster, treasure vault pile, recovery nest/healing pool. Row 3: empty build foundation marks, watch post tower, small central brazier.
Style/medium: painterly pixel-adjacent 2D game sprites, quarter-view isometric-down camera, dark cave castle fantasy, readable silhouettes.
Composition/framing: exactly 3 columns and 3 rows, no labels and no panel text. Each object is isolated with generous padding and a compact footprint, suitable for slicing into transparent PNG sprites.
Lighting/mood: moody cave dungeon with muted violet shadows and small warm torch highlights.
Color palette: dark basalt stone, charcoal, muted violet, dull gold, warm torch orange, muted teal healing glow.
Materials/textures: cracked stone, iron, rough wood, cloth banners, gold coins, crystals, moss, carved demonic stone.
Constraints: uniform #00ff00 background only; do not use #00ff00 inside the objects; no text, no labels, no UI, no characters, no full rooms, no walls, no doors, no watermark.
Avoid: flat top-down icons, side-scroller perspective, photorealistic render, giant objects that fill an entire room, repeated identical props, cropped objects.
