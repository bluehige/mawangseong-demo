# Image Generation Contract - Full-Grid Path Connections 01

This contract defines the path artwork that connects full-grid room objects in the corrected `4x4` novice Demon King castle dungeon.

It complements `docs/IMAGEGEN_CONTRACT_FULL_GRID_ROOM_OBJECT_VARIANTS_01.md`.

## Session Compass

We are building a playable Demon King castle dungeon demo, not a decorative background. The dungeon is data-first: logical grid cells, walkable cells, floor tiles, wall/door state, room-role objects, and path connections define the dungeon. Generated art must follow that data.

## Core Correction

The user rejected proof images that read as rooms plus fully filled floor.

Correct rule:

- Full-grid room objects occupy their own `5x5` macro room.
- Empty macro cells are cave void / unbuilt space, not generic floor.
- Path art exists only where the route graph says there is a connected path.
- Path art must visually connect object doorways, not fill all available negative space.
- Room interior floor and corridor/path floor must be visually distinct.

## Grid Contract

- Novice dungeon macro grid: `4x4`.
- One macro grid: `5x5` master cells.
- Room object footprint: full `5x5` macro room.
- Path width: paired two-cell sockets, visually reading as a `2x2` path mouth at each room edge.
- Current path module: `spike_corridor`, `corridor_spike_ns_01`.
- Current path module footprint: `5x10`, spanning macro cells `G01_01` and `G01_02`.

## Current Macro Layout

| macro cell | instance | role | connected side |
|---|---|---|---|
| `G01_00` | `throne` | throne | `S` |
| `G00_01` | `barracks` | barracks | `E` |
| `G02_01` | `recovery` | recovery | `W` |
| `G00_02` | `entrance` | entrance | `E` |
| `G02_02` | `treasure` | treasure | `W` |
| `G01_03` | `slot_01` | build slot | `N` |
| `G01_01` + `G01_02` | `spike_corridor` | path/trap corridor | all connected branches listed below |

All other macro cells are unbuilt cave void in this proof. Do not render them as ordinary floor tiles.

## Current Path Skeleton

The current `spike_corridor` path is not a `5x10` filled floor plate. It is a two-cell-wide route skeleton:

| path part | local cells in `corridor_spike_ns_01` | purpose |
|---|---|---|
| north mouth | `[2,0]`, `[3,0]` | connects to throne `S` |
| vertical upper spine | `[2,1]`, `[3,1]`, `[2,4]`, `[3,4]` | carries vertical flow |
| upper west branch | `[0,2]`, `[1,2]`, `[0,3]`, `[1,3]` | connects to barracks `E` |
| upper center junction | `[2,2]`, `[3,2]`, `[2,3]`, `[3,3]` | joins upper branch and spine |
| upper east branch | `[4,2]`, `[4,3]` | connects to recovery `W` |
| middle trap spine | `[2,4]`, `[3,4]`, `[2,5]`, `[3,5]` | spike trap corridor cells |
| vertical lower spine | `[2,6]`, `[3,6]` | joins lower branch |
| lower west branch | `[0,7]`, `[1,7]`, `[0,8]`, `[1,8]` | connects to entrance `E` |
| lower center junction | `[2,7]`, `[3,7]`, `[2,8]`, `[3,8]` | joins lower branch and spine |
| lower east branch | `[4,7]`, `[4,8]` | connects to treasure `W` |
| south mouth | `[2,9]`, `[3,9]` | connects to build slot `N` |

Visually this should read as a narrow connected route network inside the cave, not as a rectangular floor block.

## Required Doorway Connections

Each room connection is a paired two-cell doorway:

| room | room side | room socket cells | corridor socket cells |
|---|---|---|---|
| `throne` | `S` | `[2,4]`, `[3,4]` | `[2,0]`, `[3,0]` |
| `barracks` | `E` | `[4,2]`, `[4,3]` | `[0,2]`, `[0,3]` |
| `recovery` | `W` | `[0,2]`, `[0,3]` | `[4,2]`, `[4,3]` |
| `entrance` | `E` | `[4,2]`, `[4,3]` | `[0,7]`, `[0,8]` |
| `treasure` | `W` | `[0,2]`, `[0,3]` | `[4,7]`, `[4,8]` |
| `slot_01` | `N` | `[2,0]`, `[3,0]` | `[2,9]`, `[3,9]` |

Closed sides stay rough cave stone walls.

## Production Asset Classes

### A. Connected Layout Proof

Use this before slicing any runtime assets.

Path:

- `docs/concepts/full_grid_path_connection_layout_proof_2026-07-06.png`

Purpose:

- Prove that six full-grid room objects are connected by the intended narrow route network.
- Prove empty macro cells are void/unbuilt, not floor.
- Prove path surfaces are distinct from room interiors.
- Prove each doorway opens only at the paired socket cells.

### A2. Grid-Accurate Concept

Use this when checking whether a concept actually matches the current project grid.

Paths:

- `docs/concepts/full_grid_path_connection_grid_accurate_concept_2026-07-06.png`
- `docs/concepts/full_grid_path_connection_grid_accurate_concept_overlay_2026-07-06.png`
- `docs/concepts/full_grid_path_connection_grid_accurate_concept_2026-07-06.md`

Generator:

- `tools/generate_grid_accurate_path_concept.py`

Purpose:

- Draw the concept from actual `starting_layout.json` and `room_blueprints.json`.
- Lock room positions to the real `4x4` macro grid and `20x20` master-cell coordinates.
- Lock path surfaces to the real `corridor_spike_ns_01.floor_cells`.
- Show whether the current macro layout itself is acceptable before producing more freehand AI art.

### A3. GPT Image 2 Art-Direction Concept

Use this when the user wants a polished readable concept art image rather than a grid-debug render.

Path:

- `docs/concepts/full_grid_path_connection_gpt_image2_grid_repaint_concept_2026-07-06.png`
- `docs/concepts/full_grid_path_connection_gpt_image2_grid_repaint_concept_2026-07-06.md`

Purpose:

- Show the intended art direction with rooms connected by paths.
- Avoid the fully filled floor-board interpretation.
- Keep empty macro space as cave void / unbuilt rock.

Important:

- This concept is GPT Image 2 generated art and is not pixel-perfect production data.
- If accepted visually, slice/regenerate deterministic path pieces against the grid-accurate concept and runtime data.
- The earlier radial/symmetric GPT Image 2 concept at `docs/concepts/full_grid_path_connection_gpt_image2_concept_2026-07-06.png` is superseded and must not be used as the current layout target.

### B. Path Component Proof

Use this to prepare actual path art.

Path:

- `docs/concepts/full_grid_path_component_proof_2026-07-06.png`

Required components:

- two-cell-wide north/south path strip,
- two-cell-wide east/west path strip,
- 2x2 junction pad,
- 2x2 doorway mouth for `N`, `E`, `S`, `W`,
- spike corridor insert for the middle path,
- rough edge rubble that marks path boundary without becoming a wall.

### C. Future Runtime Path Atlases

Preferred future files:

```text
path_floor_cave_fg5_ns_2w.png
path_floor_cave_fg5_ew_2w.png
path_junction_cave_fg5_2x2.png
path_mouth_cave_fg5_N_2cell.png
path_mouth_cave_fg5_E_2cell.png
path_mouth_cave_fg5_S_2cell.png
path_mouth_cave_fg5_W_2cell.png
path_spike_insert_cave_fg5_2x2.png
```

These are future production assets. Proof images are not runtime atlases until reviewed and sliced.

## Visual Requirements

- Use the same quarter-view / isometric-down diamond projection as the runtime grid.
- Do not fill every empty macro cell with floor.
- Empty cells must read as cave void, dark rock, rubble, or unbuilt negative space.
- The connected path should be narrower than a room and clearly route-shaped.
- Path floor must be visually different from room floor: more worn, darker seams, rubble edges, or lit path stones.
- Doorway mouths must align to paired two-cell sockets.
- Closed room sides must remain visibly walled.
- Corridors may have low edge stones or rubble, but not full room walls unless a side is closed.
- No labels, UI, characters, watermarks, or decorative paths that do not exist in data.

## Rejection Criteria

Reject the proof if any of these happen:

- Empty macro cells are filled with normal walkable floor.
- The `PATH_MAIN` corridor reads as one large rectangular floor slab.
- Doorway openings are wider than the paired two-cell sockets.
- A closed side looks walkable.
- A path connects to the wrong side of a room.
- Room interiors and corridor paths use the same visual language and cannot be distinguished.
- The image reads as a decorative board instead of a data-driven dungeon layout.
