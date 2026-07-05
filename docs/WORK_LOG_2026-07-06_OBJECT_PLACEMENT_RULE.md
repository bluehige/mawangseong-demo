# 2026-07-06 Object Placement Rule Pass

## Session Compass

We are building a playable Demon King castle dungeon demo, not a decorative background. The dungeon must be assembled from quarter-view cells, floor tiles, wall/edge/door rules, room-role objects, and walkable cell data.

## Why Objects Were Overlapping

The previous object system had direction-aware sprites, but it did not have a complete placement rule.

It knew:

- `cell`
- `layer`
- `facing`
- rough width scale hard-coded in the renderer

It did not know:

- the prop's foot anchor,
- the maximum allowed visual width inside one cell,
- the maximum allowed visual height,
- the bottom offset needed to keep the prop on the cell floor,
- whether a prop may draw on multiple layers,
- whether a front prop must remain readable after front walls are drawn.

Because of that, generated props with their own stone bases were treated like generic full-cell images. Large bases, walls, and front-wall overlays could visually collide even though the logical grid and tests were valid.

Beginner translation: the code knew where the room cell was, but not where the object's feet should touch the floor.

## New Rule

Room-role objects are no longer placed by image size alone.

Each prop may define `placement` in `data/dungeon_quarter/asset_manifest.json`:

- `fit_width`: allowed width relative to the target cell rect.
- `bottom_offset`: foot/bottom position relative to the cell bottom.
- `x_offset`: side offset relative to the cell width.
- `max_height`: maximum height relative to the cell height.
- `alpha`: optional draw alpha.

Props that intentionally draw on multiple layers must declare `stack_layers`.

Example:

```json
"placement": {
  "default": {"fit_width": 0.66, "bottom_offset": 0.00, "x_offset": 0.00, "max_height": 1.35}
}
```

## Code Changes

- `data/dungeon_quarter/asset_manifest.json`
  - Added `placement` rules for entrance, brazier, throne, treasure, barracks, recovery, foundation, and watch post.
  - Added `stack_layers` for the throne because it is intentionally split into back/front visual parts.
- `scripts/dungeon_quarter/QuarterDungeonRenderer.gd`
  - Uses manifest `placement` instead of only hard-coded width scale.
  - Limits draw height with `max_height`.
  - Uses `stack_layers` to decide whether a prop may render on a layer different from its slot layer.
  - Draws front room-role objects after front walls so the room role remains readable in the current 1-cell demo layout.

## Verification

Commands run:

```powershell
python -m json.tool data\dungeon_quarter\asset_manifest.json
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --headless --path . --run res://tools/DemoSmokeTest.tscn
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --path . --run res://tools/ManualVerificationCapture.tscn
```

Results:

- Asset manifest JSON: PASS.
- `QuarterModuleSmokeTest`: `QUARTER_MODULE_SMOKE_TEST: PASS`.
- `DemoSmokeTest`: `DEMO_SMOKE_TEST: PASS`.
- Manual capture: PASS.

Latest captures:

- `tmp/manual_verification/01_management.png`
- `tmp/manual_verification/01_watch_post_facility.png`
- `tmp/manual_verification/03_combat_start.png`

## Remaining Visual Risk

The current demo still uses 1-cell rooms with relatively tall wall-edge art. This is acceptable for the first demo pass, but it is naturally dense. If the user still rejects the visual density, the next correct fix is not "generate more object images." The next fix is one of:

1. expand important rooms to multi-cell interiors,
2. reduce wall-edge height/opacity for selected rooms,
3. add per-room object anchors instead of only per-prop placement,
4. split room-role objects into wall-mounted, floor-decal, and center-prop placement classes.

## 2026-07-06 Follow-up: Single-Cell Occupancy Clamp

User feedback after the first pass: the screen still looked unchanged, and one grid cell should not visually carry several large objects.

Follow-up rule:

- A room cell may have only one primary room-role object.
- If duplicate primary objects resolve to the same global cell, `ModuleGraph` keeps only the first object slot for that cell.
- A prop image may not use its raw image size to spill over neighboring cells.
- Wall-edge art is an edge marker, not a second full-cell object, so its draw scale must stay below the room-role object scale.
- Management monster previews are unit markers, not room-role objects, so they are smaller than static props.

Follow-up code changes:

- `scripts/dungeon_quarter/ModuleGraph.gd`
  - Added `occupied_object_cells` during blueprint application.
  - Duplicate object slots on the same global cell are skipped.
- `scripts/dungeon_quarter/QuarterDungeonRenderer.gd`
  - Clamps object `fit_width`, `max_height`, and `bottom_offset` at draw time.
  - Reduced wall-edge width, bottom offset, and opacity so wall art no longer reads like a full second object stacked over the cell.
- `data/dungeon_quarter/asset_manifest.json`
  - Tightened every current room-role object's `placement` values to stay visually inside one cell.
- `scripts/map/DungeonRenderer.gd`
  - Reduced management monster preview marker size.
- `scripts/game/GameRoot.gd`
  - Reduced management/combat unit spawn offsets to match the smaller unit markers.

Follow-up verification:

- `python -m json.tool data\dungeon_quarter\asset_manifest.json`: PASS.
- `& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`.
- `& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --headless --path . --run res://tools/DemoSmokeTest.tscn`: exit code 0.
- `& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --path . --run res://tools/ManualVerificationCapture.tscn`: exit code 0, captures updated.

Current honest state:

- The immediate overdraw is reduced.
- The current 1-cell-room blueprint still makes the dungeon cluster visually dense.
- If the user wants the next real quality jump, convert key rooms from "one room = one cell" to "one room = multiple internal cells" and place props/units on separate internal cells.
