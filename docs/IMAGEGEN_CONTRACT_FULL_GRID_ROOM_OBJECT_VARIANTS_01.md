# Image Generation Contract - Full-Grid Room Object Variants 01

This is the production contract for room-object image generation after the 4x4 / 5x5 novice dungeon correction.

It supersedes the older prop-only direction atlas for any full-grid room object. The older `assets/props/v3/prop_*_<facing>_*` sprites remain placeholder direction/key-selection assets until visually approved.

Path/corridor image generation is defined separately in `docs/IMAGEGEN_CONTRACT_FULL_GRID_PATH_CONNECTIONS_01.md`. Do not solve path readability by filling empty macro cells with floor inside room-object art.

## Session Compass

We are building a playable Demon King castle dungeon demo, not a decorative background. The dungeon is data-first: logical grid cells, walkable cells, floor tiles, wall/door state, room-role objects, and path connections define the dungeon. Generated art must follow that data.

## Core Grid Rule

- Novice Demon King castle dungeon: `4x4` macro room grid.
- One macro room grid: `5x5` master cells.
- One main room-role object occupies the full `5x5` macro grid.
- One path/opening uses paired two-cell sockets, visually reading as a `2x2` path mouth.
- Characters move on floor/walk cells only. Image art must not invent walkable space.
- Background cave art is atmosphere only and never defines navigation.

## Two Separate Direction Systems

Do not mix these two systems:

| system | keys | meaning |
|---|---|---|
| Room side / wall state | `N`, `E`, `S`, `W` | Logical side of the `5x5` room. Determines wall, doorway, and path connection. |
| Object facing | `NW`, `NE`, `SE`, `SW` | Direction the object's front is facing in the quarter-view image. |

Facing labels are object-front directions:

| facing | required visual read |
|---|---|
| `NW` | Object front faces northwest. For front/back-readable objects, the back/away side must be visible. |
| `NE` | Object front faces northeast. |
| `SE` | Object front faces southeast. |
| `SW` | Object front faces southwest/lower-left. |

If two facing variants look identical or the front direction is unclear, the set fails visual QA.

## Connection Mask Rule

Room-object wall/opening state is encoded as an opening mask, not as arbitrary filenames.

Canonical bits:

| side | bit |
|---|---:|
| `N` | `1` |
| `E` | `2` |
| `S` | `4` |
| `W` | `8` |

Formula:

```text
open_mask = (N_open ? 1 : 0) + (E_open ? 2 : 0) + (S_open ? 4 : 0) + (W_open ? 8 : 0)
wall_mask = 15 - open_mask
```

Rendering meaning:

- A side is open only when the room has a real connected paired socket on that side.
- `closed` side = rough cave stone wall.
- `open_placeholder` side = still a wall for movement and image generation; optional construction markings may be overlaid later, but the wall is not open.
- `connected` side = paired two-cell doorway/opening. Both socket cells on that side must visually open.

All 16 opening masks:

| open_mask | open sides | wall sides | suffix |
|---:|---|---|---|
| 0 | none | `N,E,S,W` | `open_00` |
| 1 | `N` | `E,S,W` | `open_01` |
| 2 | `E` | `N,S,W` | `open_02` |
| 3 | `N,E` | `S,W` | `open_03` |
| 4 | `S` | `N,E,W` | `open_04` |
| 5 | `N,S` | `E,W` | `open_05` |
| 6 | `E,S` | `N,W` | `open_06` |
| 7 | `N,E,S` | `W` | `open_07` |
| 8 | `W` | `N,E,S` | `open_08` |
| 9 | `N,W` | `E,S` | `open_09` |
| 10 | `E,W` | `N,S` | `open_10` |
| 11 | `N,E,W` | `S` | `open_11` |
| 12 | `S,W` | `N,E` | `open_12` |
| 13 | `N,S,W` | `E` | `open_13` |
| 14 | `E,S,W` | `N` | `open_14` |
| 15 | `N,E,S,W` | none | `open_15` |

## Paired Socket Placement

For every standard `5x5` room, side openings are paired socket cells:

| side | socket cells |
|---|---|
| `N` | `[2,0]`, `[3,0]` |
| `E` | `[4,2]`, `[4,3]` |
| `S` | `[2,4]`, `[3,4]` |
| `W` | `[0,2]`, `[0,3]` |

A generated room image must show the doorway/opening at these paired cells only. Do not make the whole side open unless the mask and future rules explicitly require it.

## Production Asset Classes

### A. Full-Grid Room-Role Objects

These occupy the whole `5x5` macro grid and require `facing + open_mask` variants:

| room role | current object id | required now |
|---|---|---|
| entrance | `entrance_gate_f` | yes |
| throne | `throne_f` | yes |
| barracks | `weapon_rack` | yes |
| recovery | `recovery_nest_f` | yes |
| treasure | `treasure_pile_large` | yes |
| build slot | `foundation_marks` | yes |
| watch post | `watch_post` | future/full-grid-capable |

The current default novice layout needs only these first-pass variants, but production must be able to generate all masks:

| instance | object id | facing | open sides | open mask |
|---|---|---|---|---:|
| `throne` | `throne_f` | `SW` | `S` | `04` |
| `barracks` | `weapon_rack` | `SE` | `E` | `02` |
| `recovery` | `recovery_nest_f` | `NW` | `W` | `08` |
| `entrance` | `entrance_gate_f` | `SE` | `E` | `02` |
| `treasure` | `treasure_pile_large` | `NW` | `W` | `08` |
| `slot_01` | `foundation_marks` | `NE` | `N` | `01` |

The dungeon entrance is not optional. Even when the first art proof focuses on the throne, `entrance_gate_f` must appear in the same first proof set so the production structure proves both a core room and the actual dungeon entry point.

Current proof artifacts:

| proof | path | roles |
|---|---|---|
| throne plus dungeon entrance | `docs/concepts/full_grid_room_object_proof_throne_entrance_2026-07-06.png` | `throne_f`, `entrance_gate_f` |
| remaining room roles | `docs/concepts/full_grid_room_object_proof_remaining_rooms_2026-07-06.png` | `weapon_rack`, `recovery_nest_f`, `treasure_pile_large`, `foundation_marks` |

Both proof sheets are concept-review images only. They are not sliced runtime atlases and are not production-approved art until the user confirms the visual direction, facing labels, and paired opening placement.

### B. Small Decor / Local Props

Examples: `small_brazier`.

- These do not get `open_mask` variants.
- They may be `directionless` or use the four facing directions if the object has a readable front.
- They must not imply walls, paths, or movement state.
- They can be placed as `1x1`, `1xN`, or decorative overlays according to the manifest.

### C. Traps And Corridor Objects

Examples: `spike_floor`.

- These are walk/floor objects, not full-room walls.
- They use trap animation frames or path-object rules, not `facing + open_mask`.
- They may occupy `2x2` cells when they are part of a path.

### D. Wall / Door / Path Overlays

These can be shared across room roles:

- rough cave wall strips,
- wall corners,
- paired doorway mouths,
- path bridge overlays,
- construction placeholder overlays.

They are allowed to use `side`, `open_mask`, or `wall_mask`, but they must not change gameplay data.

## Image Count Planning

For a baked full-room image set:

```text
variants_per_role_per_layer = 4 facings * 16 open masks = 64
```

If a role uses one composite layer:

```text
1 role = 64 images
6 current required roles = 384 images
7 full-grid-capable roles including watch_post = 448 images
```

If a role uses split `back` and `front` layers:

```text
1 role = 128 images
6 current required roles = 768 images
7 full-grid-capable roles including watch_post = 896 images
```

Current prop layer count, if generated exactly from existing layer structure:

| object id | layers | layer count | full-grid production count |
|---|---|---:|---:|
| `entrance_gate_f` | `back` | 1 | 64 |
| `throne_f` | `back`, `front` | 2 | 128 |
| `weapon_rack` | `back` | 1 | 64 |
| `recovery_nest_f` | `front` | 1 | 64 |
| `treasure_pile_large` | `front` | 1 | 64 |
| `foundation_marks` | `back` | 1 | 64 |
| required subtotal |  | 7 | 448 |
| `watch_post` future | `front` | 1 | 64 |
| full-grid-capable subtotal |  | 8 | 512 |

This count is large enough that blind mass generation is not allowed. Use the production sequence below.

## Recommended Modular Strategy

Preferred production path:

1. Generate and approve role/facing interiors:
   - `room_role + facing + layer`
   - no wall mask baked into the role art unless necessary.
2. Generate and approve shared rough cave wall shells:
   - `open_mask + layer`
   - walls closed everywhere except connected paired openings.
3. Generate and approve shared doorway/path-mouth overlays:
   - `side` or `open_mask`
   - paired two-cell openings only.
4. Compose role interior + wall shell + doorway/path overlay in runtime or a slicing/composition tool.

This keeps visual state correct without hand-authoring hundreds of nearly identical complete room images.

Baked full-room variants are allowed only for hero rooms that need unique integrated art, such as the throne.

## Naming Convention

Full-grid baked room sprite:

```text
room_<object_id>_fg5_<facing>_open_<mask2>_<layer>.png
```

Examples:

```text
room_throne_f_fg5_SW_open_04_back.png
room_throne_f_fg5_SW_open_04_front.png
room_entrance_gate_f_fg5_SE_open_02_back.png
room_recovery_nest_f_fg5_NW_open_08_front.png
```

Shared wall shell:

```text
room_wall_cave_fg5_open_<mask2>_<layer>.png
```

Shared doorway/path mouth:

```text
path_mouth_cave_fg5_<side>_<layer>.png
path_mouth_cave_fg5_open_<mask2>_<layer>.png
```

Direction proof sheet:

```text
proof_<object_id>_facing_4dir_01.png
```

Mask proof sheet:

```text
proof_<object_id>_<facing>_open_masks_00_15_01.png
```

## Required Metadata

Any production full-grid room sprite must declare:

```json
{
  "projection": "iso_diamond_5x5",
  "grid_size": [5, 5],
  "tile_size": [128, 64],
  "facing": "SW",
  "open_mask": 4,
  "open_sides": ["S"],
  "wall_sides": ["N", "E", "W"],
  "paired_socket_cells": {
    "S": [[2, 4], [3, 4]]
  },
  "layer": "back"
}
```

The renderer must not use a full-grid room sprite as production art unless `projection` is `iso_diamond_5x5`.

## Visual Requirements

- The image must read as a `5x5` diamond room object, not a front-facing rectangle.
- The room object must visually fill the macro grid. Do not leave large empty margins.
- Walls must be rough, cave-built, hand-stacked stone with uneven caps, cracks, rubble, and chipped edges.
- Do not use clean rectangular UI frames, polished fortress rails, or straight front-view facades.
- Closed sides must clearly read as blocked walls.
- Open sides must show the paired two-cell doorway/opening at the correct side.
- Corridor/path art must be visually distinct from room floor art.
- Interior role art must face the requested `NW/NE/SE/SW` direction.
- No labels, UI text, characters, or watermarks inside production sprites.

## Built-In Image Generation Rule

For this project, GPT Image 2 means Codex built-in `image_gen`.

- Do not use API/CLI fallback.
- Do not ask for `OPENAI_API_KEY`.
- Code can crop, alpha-remove, slice, resize, compose, import, and wire manifests.
- Code-drawn placeholder art is allowed only as temporary runtime fallback, never as approved final production art.

## Production Sequence

Do not generate the full matrix first.

0. Composition proof:
   - Generate a proof image that includes both `throne_f` and `entrance_gate_f`.
   - Purpose: prove that the core room and the dungeon entrance both use full `5x5` diamond rooms, rough walls, and paired socket openings.
   - Current example path: `docs/concepts/full_grid_room_object_proof_throne_entrance_2026-07-06.png`.
   - This proof image is not a sliced runtime atlas and is not production-approved by itself.
0.5. Remaining-room proof:
   - Generate a proof image for `weapon_rack`, `recovery_nest_f`, `treasure_pile_large`, and `foundation_marks`.
   - Current example path: `docs/concepts/full_grid_room_object_proof_remaining_rooms_2026-07-06.png`.
   - Use the same `NW/NE/SE/SW` facing columns and default-layout opening masks: barracks `open_02`, recovery `open_08`, treasure `open_08`, build slot `open_01`.
   - This proof image is also concept-only and must not be sliced until reviewed.
1. Direction proof:
   - Generate `NW`, `NE`, `SE`, `SW` for `throne_f`.
   - Generate `NW`, `NE`, `SE`, `SW` for `entrance_gate_f`.
   - User must approve that all four directions are distinct and correctly labeled for both objects.
2. Wall/opening proof:
   - Start with `throne_f + SW + open_04`.
   - Also prove `entrance_gate_f + SE + open_02`, because dungeon entrance structure must not be skipped.
   - Generate all `open_00` through `open_15` variants or modular wall overlays for one approved role/facing before scaling to the rest.
   - User must approve closed walls and paired doorway locations.
3. Default-layout production slice:
   - Generate only the six current required variants listed in this contract.
   - Verify in `tmp/manual_verification/01_management.png`.
4. Batch production:
   - Generate the remaining masks/facings only after the proof sheets pass.
   - Every batch must include a numbered contact sheet with `object_id`, `facing`, `open_mask`, `open_sides`, and `layer`.

## Rejection Criteria

Reject the batch if any of the following occurs:

- `NW/NE/SE/SW` are visually duplicated or mislabeled.
- The object faces the wrong direction for its label.
- A closed side looks open or walkable.
- An open side lacks the paired two-cell doorway.
- The room reads as a small prop inside empty floor instead of a full-grid building.
- The projection reads as front-view or rectangular rather than iso/quarter diamond.
- The walls look too clean, UI-like, or fortress-polished.
- The generated image adds unrelated objects, characters, labels, or non-data-driven paths.
- The asset is connected to the manifest without `projection: "iso_diamond_5x5"` or equivalent approved metadata.
