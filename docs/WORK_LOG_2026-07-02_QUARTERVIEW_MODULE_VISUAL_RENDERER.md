# Work Log: Quarter-View Module Visual Renderer

Date: 2026-07-02

## Request

Open the demo and make the quarter-view module connection test visible to the player.

## Finding

The generated module PNGs existed, but `QuarterDungeonRenderer` only drew debug overlays. The actual module visual PNGs were not being drawn, so opening the demo did not show the new module map.

The module documentation already says the dungeon should use room/corridor prefabs, sockets, `walk_cells`, and separated layers. It also states that open doorway sockets must be specified in prompts. However, it did not state the practical production rule strongly enough: one room image is not enough for every possible connection state.

## Implementation

- `QuarterDungeonRenderer.gd`
  - Loads final module PNGs from `assets/sprites/dungeon_quarter/modules/`.
  - Draws module visuals in map order before debug overlays.
  - Keeps F1/F2/F3/F7/F8 debug overlays on top for connection and walk/block verification.
  - Supports socket-variant filenames:

```text
module_id_visual_[open_socket_sides].png
```

Examples:

```text
room_entrance_01_visual_ne_se.png
room_treasure_01_visual_nw.png
room_treasure_01_visual_nw_sw.png
corridor_spike_ne_sw_01_visual_ne_sw.png
```

If the exact variant is missing, the renderer falls back to `module_id_visual.png`.

- `QuarterModuleSmokeTest.gd`
  - Verifies module visual textures load.
  - Verifies generated socket-variant keys for representative modules.

## Verification

Passed:

```powershell
godot --headless --path . --import
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --path . --run res://tools/ManualVerificationCapture.tscn
```

Manual capture confirmed that the visible management map now shows the quarter-view module PNGs.

Capture:

```text
tmp/manual_verification/01_management.png
```

## Remaining Work

1. Generate real socket-variant art sets for modules that can be placed with multiple connection states.
2. Split visuals into bg/fg layers so front walls and columns can sort around units.
3. Replace the current legacy `rooms.json` rect projection with true module world coordinates.
4. Add visual tests for variant selection after room/module replacement.

