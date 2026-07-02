# Work Log: Quarter-View Module Image Resource Prep

Date: 2026-07-02

## Request

Create module map resources while accounting for the socket rule:

- connected module sides are open;
- unconnected sides are blocked;
- GPT Image 2 must be used.

## Confirmed Rule Source

- `data/dungeon_quarter/modules.json`
  - Defines each module's sockets, walk cells, block cells, prop block cells, and socket entry cells.
- `data/dungeon_quarter/starting_layout.json`
  - Defines which module sockets are connected in the current demo layout.

## Prepared Output

- `tools/imagegen/quarter_modules_gpt_image2_prompts.jsonl`
  - GPT Image 2 batch prompts for 8 current modules.
  - Each prompt explicitly states which socket sides are open and which are sealed.
- `tools/imagegen/README_QUARTER_MODULES.md`
  - Generation and chroma-key post-processing commands.
- `assets/sprites/dungeon_quarter/modules/SOURCE.md`
  - Target asset naming and source notes.

## GPT Image 2 Status

Initial live generation was blocked because I interpreted the request as the explicit API/CLI `gpt-image-2` path, which requires `OPENAI_API_KEY`.

The user clarified that the intended path is the internal GPT image generation tool. I then generated all 8 module visuals with that internal tool, copied the chroma sources into the project output folder, and removed the chroma key into final transparent PNGs.

Generated final assets:

```text
assets/sprites/dungeon_quarter/modules/room_entrance_01_visual.png
assets/sprites/dungeon_quarter/modules/corridor_spike_ne_sw_01_visual.png
assets/sprites/dungeon_quarter/modules/junction_center_01_visual.png
assets/sprites/dungeon_quarter/modules/room_throne_01_visual.png
assets/sprites/dungeon_quarter/modules/room_barracks_01_visual.png
assets/sprites/dungeon_quarter/modules/room_recovery_01_visual.png
assets/sprites/dungeon_quarter/modules/room_empty_slot_01_visual.png
assets/sprites/dungeon_quarter/modules/room_treasure_01_visual.png
```

Source chroma copies:

```text
output/imagegen/quarter_modules/source/
```

Visual QA contact sheet:

```text
output/imagegen/quarter_modules/contact_sheet.png
```

Alpha validation:

- All 8 final PNGs are `RGBA`.
- All 8 final PNGs have transparent corner alpha (`corner_alpha=0`).

## Verification

Passed:

```powershell
godot --headless --path . --import
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
```

Results:

- Godot imported the module PNGs and generated `.import` files.
- `QuarterModuleSmokeTest.tscn` PASS.
- `DemoSmokeTest.tscn` PASS.

Local note:

- `mawang_quarterview_walkarea_update_docs/` contains reference `.gd` templates that collide with project script class names if Godot scans them.
- I added local untracked `.gdignore` files under `mawang_quarterview_walkarea_update_docs/` and `output/` so Godot import can run cleanly in this workspace. These helper files are intentionally not part of the committed resource change.

## Next Steps

1. Connect `QuarterDungeonRenderer` to these final module visuals.
2. Verify F3/F7 overlays still align with visible floor/walls.
3. If a module's generated socket is visually ambiguous, regenerate that single module with a stricter prompt.
