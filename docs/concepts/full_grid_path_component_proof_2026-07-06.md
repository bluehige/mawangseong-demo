# Full-Grid Path Component Proof - 2026-07-06

Image:

- `docs/concepts/full_grid_path_component_proof_2026-07-06.png`

Status:

- Proof/concept image only.
- Not a sliced runtime atlas.
- Not production-approved art.
- Created to identify path components needed after the connected-layout proof is approved.

## Component Intent

The sheet shows reusable path components for the `4x4` / `5x5` novice dungeon:

- two-cell-wide north/south path strip,
- two-cell-wide east/west path strip,
- 2x2 junction pad,
- 2x2 spike-trap insert,
- paired doorway mouths for `N`, `E`, `S`, `W`,
- macro-cell branch pieces that do not fill the whole macro cell,
- rough rubble/edge strips for path boundary readability.

## Rule Being Tested

- Path surfaces are narrower than room interiors.
- Path art sits on cave void / rock, not a full room floor.
- Doorway mouths are paired two-cell openings only.
- Path edge rubble is a low boundary, not a room wall.

## Generation Prompt

```text
Use case: stylized-concept
Asset type: game path component proof sheet
Primary request: Create a no-label proof sheet of reusable path components for a small Demon King cave castle dungeon, matching an isometric-down / quarter-view 5x5 room grid.

Sheet layout: 3 rows x 4 columns, no text labels. Each panel shows one path component on dark cave void, with generous separation. The components should be readable as game asset concepts, not UI icons.

Components to show:
1) two-cell-wide north-south stone path strip, rough cave edges.
2) two-cell-wide east-west stone path strip, rough cave edges.
3) 2x2 central junction pad where paths meet.
4) 2x2 spike-trap insert embedded in a corridor floor.
5) north doorway mouth: paired two-cell room opening leading into a path.
6) east doorway mouth: paired two-cell room opening leading into a path.
7) south doorway mouth: paired two-cell room opening leading into a path.
8) west doorway mouth: paired two-cell room opening leading into a path.
9) upper branch crossing through a 5x5 macro path cell, not filling the whole cell.
10) lower branch crossing through a 5x5 macro path cell, not filling the whole cell.
11) narrow vertical spine through a 5x10 corridor module, with empty cave void around it.
12) rough path boundary rubble strip, low stones only, not a wall.

Visual rules: The path surfaces are narrower than room interiors. They are dark worn stone, cracked slabs, rubble-edged, with subtle violet cave shadows and a few warm torch highlights. The path should clearly differ from room floor. Empty space around every component is cave void/rock, not floor. Doorway mouths are paired two-cell openings only, not a full open wall. Use rough hand-stacked cave stone at the doorway edges.

Style/medium: painterly pixel-adjacent 2D game asset concept, dark fantasy dungeon, isometric diamond projection, readable silhouettes.
Constraints: no labels, no UI, no text, no watermark, no characters, no clean rectangular frames, no fully filled floor panels, no front-view rectangles.
```
