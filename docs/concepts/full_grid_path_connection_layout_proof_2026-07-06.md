# Full-Grid Path Connection Layout Proof - 2026-07-06

Image:

- `docs/concepts/full_grid_path_connection_layout_proof_2026-07-06.png`

Status:

- Proof/concept image only.
- Not a sliced runtime atlas.
- Not production-approved art.
- Created to verify that full-grid room objects connect through explicit path corridors instead of a fully filled floor plate.

## Rule Being Tested

- The novice dungeon remains a `4x4` macro grid.
- Each room object occupies a full `5x5` macro room.
- Empty macro cells stay cave void / unbuilt space.
- Only the connected route graph gets path floor.
- `PATH_MAIN` is a narrow two-cell-wide path skeleton, not a `5x10` filled floor slab.
- Each room side opens only at its paired two-cell doorway.

## Intended Layout

| macro cell | room |
|---|---|
| `G01_00` | throne |
| `G00_01` | barracks |
| `G02_01` | recovery |
| `G00_02` | entrance |
| `G02_02` | treasure |
| `G01_03` | build slot |
| `G01_01` + `G01_02` | central path / spike corridor |

## Current Review Notes

- The proof successfully separates room masses from path surfaces.
- It shows dark cave void between rooms instead of a full floor fill.
- It includes a central spike-trap insert.
- It is still a single proof composition; production slicing must wait for user approval.

## Generation Prompt

```text
Use case: stylized-concept
Asset type: game asset proof image for a 4x4 macro-grid dungeon layout
Primary request: Create a connected-layout proof for a small Demon King cave castle dungeon. It must show six large full-grid room objects connected by narrow route paths, not by fully filled floor.

Scene/backdrop: dark cave interior with unbuilt void space between rooms, rough basalt rock, scattered rubble, muted violet shadows, warm torch accents.

Grid/layout contract: quarter-view / isometric-down projection. The layout is a 4x4 macro grid. Each room occupies one full 5x5 isometric diamond macro cell. Empty macro cells must remain dark cave void/unbuilt space, not floor.

Room positions in the 4x4 macro grid:
- Top center G01_00: throne room, full 5x5 diamond room, front faces SW, only south paired doorway open.
- Upper left G00_01: barracks room, full 5x5 diamond room, front faces SE, only east paired doorway open.
- Upper right G02_01: recovery nest room, full 5x5 diamond room, front faces NW, only west paired doorway open.
- Lower left G00_02: dungeon entrance room, full 5x5 diamond room, front faces SE, only east paired doorway open.
- Lower right G02_02: treasure vault room, full 5x5 diamond room, front faces NW, only west paired doorway open.
- Bottom center G01_03: build slot room, full 5x5 diamond room, front faces NE, only north paired doorway open.

Path network: A narrow two-cell-wide central route occupies only the middle macro column between the rooms, not the entire empty cells. It has a vertical north-south spine through G01_01 and G01_02, an upper horizontal branch connecting barracks to recovery, a lower horizontal branch connecting entrance to treasure, and a south connection down to the build slot. Include a small 2x2 spike-trap insert in the middle of the vertical route. All path branches should visibly connect to the paired two-cell doorways.

Visual rules: Each room is enclosed by rough hand-stacked cave stone walls except at its connected paired doorway. The connected path floor is visually distinct from room floor: darker worn stones, clear seams, rubble edges, slightly lower and narrower than room floors. Empty macro cells are black cave void, rock, rubble, or shadow, never ordinary walkable floor. The layout should read as rooms connected by specific corridors, not a filled board.

Style/medium: painterly pixel-adjacent 2D game asset concept, dark fantasy dungeon, readable silhouettes, isometric diamond grid logic.
Composition/framing: one complete overhead quarter-view composition, centered, with slight margin around the 4x4 macro layout. No panel grid lines, no labels.
Constraints: no UI, no text, no labels, no watermark, no characters, no decorative random paths, no fully filled empty floor, no rectangular front-view rooms, no large empty white margins.
```
