# Full-Grid Path Connection GPT Image 2 Concept - 2026-07-06

Image:

- `docs/concepts/full_grid_path_connection_gpt_image2_concept_2026-07-06.png`

Status:

- GPT Image 2 / built-in `image_gen` concept art.
- Intended for visual judgment by the user.
- Not a sliced runtime atlas.
- Not production-approved until explicitly accepted.

## Intent

This concept is the corrected visual target after the user rejected code-drawn/grid-debug imagery.

The image should communicate:

- six full-grid room objects,
- connected by explicit path corridors,
- no fully filled floor plate,
- empty macro areas as cave void / rock,
- paired doorway mouths rather than whole-wall openings.

## Grid Structure Requested In Prompt

- Dungeon macro grid: `4x4`.
- One macro grid: full `5x5` isometric room footprint.
- Total logical grid: `20x20` master cells.
- Six full-grid room objects:
  - `G01_00`: throne, connected `S`.
  - `G00_01`: barracks, connected `E`.
  - `G02_01`: recovery nest, connected `W`.
  - `G00_02`: dungeon entrance, connected `E`.
  - `G02_02`: treasure vault, connected `W`.
  - `G01_03`: build slot/foundation, connected `N`.
- `PATH_MAIN` / spike corridor:
  - occupies the middle macro column `G01_01` and `G01_02`,
  - must read as a two-cell-wide route skeleton,
  - not a filled `5x10` floor slab,
  - has upper and lower horizontal branches,
  - has a small `2x2` spike trap insert in the middle.

## Visual QA Notes

- This image is more useful for art-direction review than the grid-debug concept.
- It is still generated art, so it is not guaranteed to be pixel-perfect to the `20x20` master grid.
- If accepted, the next production step is to build/slice deterministic path and doorway assets against the grid-accurate reference.

## Prompt Used

```text
Use case: stylized-concept
Asset type: polished game concept art generated with GPT Image 2 for a Demon King cave castle dungeon layout
Primary request: Create a polished concept art image that follows this exact project grid structure. It should be understandable as the target visual direction for the game, not a diagram and not a UI mockup.

Critical grid structure to obey:
- The dungeon is a 4x4 macro grid.
- Each macro grid cell is a full 5x5 isometric diamond room footprint.
- The total logical grid is 20x20 master cells.
- Do NOT fill all macro cells with floor. Empty macro cells are dark cave void, rock, rubble, and unbuilt space.
- Six full-grid room objects exist, each occupying exactly one 5x5 macro-room footprint.
- The room positions are:
  1. G01_00 top-center-ish macro position: throne room, connected only on south side.
  2. G00_01 upper-left macro position: barracks room, connected only on east side.
  3. G02_01 upper-right macro position: recovery nest room, connected only on west side.
  4. G00_02 lower-left macro position: dungeon entrance room, connected only on east side.
  5. G02_02 lower-right macro position: treasure vault room, connected only on west side.
  6. G01_03 bottom-center macro position: build slot/foundation room, connected only on north side.
- The central path module is PATH_MAIN / spike corridor. It occupies the middle macro column cells G01_01 and G01_02, but it is NOT a filled 5x10 slab.
- PATH_MAIN is a narrow two-cell-wide route skeleton:
  - vertical north-south spine connecting throne to build slot,
  - upper horizontal branch connecting barracks to recovery,
  - lower horizontal branch connecting entrance to treasure,
  - small 2x2 spike trap insert in the middle of the vertical route.
- Every room connects to the path through paired two-cell doorway mouths only. Do not open an entire wall.

Visual requirements:
- Quarter-view / isometric-down dungeon art.
- Six large room objects are full-grid rooms with rough hand-stacked cave stone walls.
- Closed room sides are visibly walled.
- Only connected doorway mouths are open.
- Corridors are narrow route paths, clearly different from room floors: darker worn stone, cracked slabs, rubble edge, lower profile.
- Empty macro cells are dark cave void or rough rock, not walkable floor.
- The image should communicate "objects connected by specific paths" rather than "buildings placed on a fully tiled floor".
- Keep the room silhouettes large and readable: throne, barracks weapon racks, recovery nest with eggs/glow, entrance gate, treasure vault, build-slot foundation.

Style/medium: polished painterly pixel-adjacent 2D game concept art, dark fantasy Demon King cave castle, muted violet shadows, warm torch accents, rough basalt stone, readable game-map silhouettes.
Composition/framing: one complete 4x4 macro layout in a single image, centered, no labels, no UI, no grid text, no watermark. Use the real isometric grid feel, but prioritize readability for deciding the art direction.
Avoid: no plain diagram, no labels, no UI panels, no characters, no fully filled board floor, no front-facing rectangular rooms, no decorative paths that do not exist in the structure, no clean polished castle walls.
```
