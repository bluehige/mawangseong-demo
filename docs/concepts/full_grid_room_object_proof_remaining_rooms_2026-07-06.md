# Full-Grid Room Object Proof - Remaining Rooms - 2026-07-06

Image:

- `docs/concepts/full_grid_room_object_proof_remaining_rooms_2026-07-06.png`

Status:

- Proof/concept image only.
- Not a sliced runtime atlas.
- Not production-approved art.
- Direction correctness and opening placement still require user visual review before slicing or batch generation.

## Sheet Structure

The sheet is a `4 x 4` proof image.

Columns:

| column | facing meaning |
|---|---|
| 1 | `NW`: object front faces northwest |
| 2 | `NE`: object front faces northeast |
| 3 | `SE`: object front faces southeast |
| 4 | `SW`: object front faces southwest/lower-left |

Rows:

| row | room role | object id | proof opening |
|---:|---|---|---|
| 1 | barracks | `weapon_rack` | `open_02`, east paired doorway |
| 2 | recovery | `recovery_nest_f` | `open_08`, west paired doorway |
| 3 | treasure | `treasure_pile_large` | `open_08`, west paired doorway |
| 4 | build slot | `foundation_marks` | `open_01`, north paired doorway |

## Rule Being Tested

- Every room object fills one complete `5x5` macro-room diamond.
- Closed sides must read as rough, hand-stacked cave stone walls.
- Only the connected paired socket side may open.
- The room floor/path connection must be visually distinct from the walled room body.
- The four facing columns must not collapse into duplicate-looking variants.

## Generation Prompt

```text
Create a production proof-sheet concept image for a quarter-view 2D game dungeon. The sheet has 4 rows and 4 columns, no text labels. Each panel shows one complete 5x5 isometric diamond macro-room object inside a small Demon King cave castle.

Rows:
1) Barracks room: weapon rack, training gear, banner, bedrolls, crates. East-side paired two-cell doorway opening (open_02).
2) Recovery nest room: healing nest/pool, eggs/cocoon shapes, muted teal healing glow. West-side paired two-cell doorway opening (open_08).
3) Treasure vault room: chests, coins, dull gold storage, purple crystals. West-side paired two-cell doorway opening (open_08).
4) Build slot room: empty construction foundation markings, stakes, chalk/stone outlines, early construction materials. North-side paired two-cell doorway opening (open_01).

Columns show the same room facing NW, NE, SE, SW respectively; the object front direction must visibly change in every column. NW should read as facing away/northwest with back/rear side visible where applicable. NE faces northeast, SE faces southeast, SW faces southwest/lower-left.

Every panel must show the room object filling the whole 5x5 diamond footprint, not a tiny prop. Unconnected sides are surrounded by rough hand-stacked cave stone walls with uneven caps, cracks, chipped edges, and rubble. Only the connected paired doorway cells are open; all other sides are visibly walled.

Style: painterly pixel-adjacent 2D game asset concept, quarter-view/isometric-down projection, dark basalt cave stone, muted violet dungeon shadows, warm torch accents, readable silhouettes. Constraints: no UI, no characters, no text, no watermark, no front-facing rectangular rooms, no polished clean frame borders, no large empty margins.
```
