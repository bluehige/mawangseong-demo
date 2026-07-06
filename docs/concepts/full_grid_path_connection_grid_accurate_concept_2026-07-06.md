# Full-Grid Path Connection Grid-Accurate Concept - 2026-07-06

Images:

- Clean concept: `docs/concepts/full_grid_path_connection_grid_accurate_concept_2026-07-06.png`
- Overlay concept: `docs/concepts/full_grid_path_connection_grid_accurate_concept_overlay_2026-07-06.png`

Generator:

- `tools/generate_grid_accurate_path_concept.py`

Status:

- Grid-accurate concept image.
- Generated from `data/dungeon_quarter/starting_layout.json` and `data/dungeon_quarter/room_blueprints.json`.
- Not a production atlas.
- Not AI-freehand composition.

## What This Proves

This image is locked to the current project data:

- `4x4` macro grid.
- Each macro cell is `5x5` master cells.
- Global master grid is `20x20`.
- Rooms use their current `grid_origin` values from `starting_layout.json`.
- The path uses the actual `floor_cells` of `corridor_spike_ns_01`.
- Doorway highlights use actual `socket_entries` and `connections`.

## Current Data Layout

| instance | macro cell | master origin | role |
|---|---|---:|---|
| `throne` | `G01_00` | `[5,0]` | full-grid throne room |
| `barracks` | `G00_01` | `[0,5]` | full-grid barracks |
| `recovery` | `G02_01` | `[10,5]` | full-grid recovery nest |
| `entrance` | `G00_02` | `[0,10]` | full-grid dungeon entrance |
| `treasure` | `G02_02` | `[10,10]` | full-grid treasure vault |
| `slot_01` | `G01_03` | `[5,15]` | full-grid build slot |
| `spike_corridor` | `G01_01` + `G01_02` | `[5,5]` | path / trap corridor |

## Important Visual Judgment

In this grid-accurate view, macro grid coordinates are projected through the engine's isometric-down basis:

```text
screen_x = (grid_x - grid_y) * half_tile_width
screen_y = (grid_x + grid_y) * half_tile_height
```

Therefore the logical position `G01_00` does not read as a flat top-center room in screen space the same way a front-facing reference mockup does. If the user wants the throne to appear visually top-center like the reference image, that is a macro placement / camera framing decision, not just an image-generation issue.

## Current Path Shape

The current path shape comes from `corridor_spike_ns_01`:

- North paired mouth to throne.
- Upper two-cell-high branch to barracks and recovery.
- Two-cell-wide vertical spine.
- Middle `2x2` spike trap area.
- Lower two-cell-high branch to entrance and treasure.
- South paired mouth to build slot.

This is not a filled `5x10` slab. It is the current route skeleton encoded in `room_blueprints.json`.

## Review Question

Use this concept to decide whether the current logical grid layout itself is acceptable.

If accepted:

- Use this as the hard placement reference for future AI art and slicing.

If rejected:

- Change the macro layout or camera/framing rule first.
- Do not keep regenerating freehand art against the wrong structure.
