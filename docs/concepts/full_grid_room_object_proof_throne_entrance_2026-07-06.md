# Full-Grid Room Object Proof - Throne + Dungeon Entrance - 2026-07-06

Image:

- `docs/concepts/full_grid_room_object_proof_throne_entrance_2026-07-06.png`

Purpose:

- First production-proof concept for the corrected full-grid room-object rule.
- Confirms the example structure includes both:
  - `throne_f` as the core/hero room object,
  - `entrance_gate_f` as the actual dungeon entrance room object.
- This prevents the first proof set from accidentally focusing only on the throne while omitting the dungeon entrance.

Contract:

- `docs/IMAGEGEN_CONTRACT_FULL_GRID_ROOM_OBJECT_VARIANTS_01.md`

Intended proof composition:

- 2 rows x 4 columns.
- Top row: throne room variants.
- Bottom row: dungeon entrance gate variants.
- Columns: `NW`, `NE`, `SE`, `SW` object-front facing directions.
- Throne row demonstrates a south-side paired two-cell doorway, equivalent to `open_04`.
- Dungeon entrance row demonstrates an east-side paired two-cell doorway, equivalent to `open_02`.
- Every panel should read as a complete `5x5` iso-diamond room object with rough cave stone walls on all unconnected sides.

Status:

- This is a visual proof/concept image only.
- It is not sliced into runtime sprites.
- It is not approved production art.
- Direction correctness still requires a follow-up contact sheet with unambiguous labels and user review.
- Full production still requires `prop_id + facing + open_mask + layer` variants.

Prompt used:

```text
Create a production proof-sheet concept image for a quarter-view 2D game dungeon. The sheet has 2 rows and 4 columns, no text labels. Each panel shows one complete 5x5 isometric diamond macro-room object inside a small Demon King cave castle.

Top row: demonic throne room variants. Bottom row: dungeon entrance gate variants. Columns show the same room facing NW, NE, SE, and SW respectively; the object front direction must visibly change in every column. NW should read as facing away/northwest with the back or rear side visible. NE faces northeast, SE faces southeast, SW faces southwest/lower-left.

Every panel must show the room object filling the whole 5x5 diamond footprint, not a tiny prop. Unconnected sides are surrounded by rough hand-stacked cave stone walls with uneven caps, cracks, chipped edges, and small rubble. The throne row uses a south-side paired two-cell doorway opening. The dungeon entrance row uses an east-side paired two-cell doorway opening. Only the connected paired doorway cells are open; all other sides are visibly walled.

Style: painterly pixel-adjacent 2D game asset concept, quarter-view/isometric-down projection, dark basalt cave stone, muted violet dungeon shadows, warm torch accents, readable silhouettes. Constraints: no UI, no characters, no text, no watermark, no front-facing rectangular rooms, no polished clean frame borders, no large empty margins.
```
