# 2026-07-05 Cave Room Object Atlas

Purpose: record the first room-role object pass for the cave-type Demon King castle map.

## Rule Checked Before Work

- A room is not one image.
- A room is assembled from quarter-view cells, floor tiles, wall/edge tiles, doors, props, and walkable cell data.
- Room-role props are visual markers only. They do not decide movement, connection state, wall state, or collision.
- In this project, GPT Image 2 means Codex built-in `image_gen`; no API/CLI fallback and no procedural placeholder art for final raster resources.

Beginner translation: the throne, barracks, treasure, recovery, and watch post are decorations placed on top of the real tile grid. The grid and socket data still decide where a unit can walk.

## Generated Object Atlas

Built-in `image_gen` was used to create one 3x3 object atlas on a chroma-key background.

- Contract: `docs/IMAGEGEN_CONTRACT_CAVE_OBJECT_ATLAS_01.md`
- Source: `output/imagegen/cave_object_atlas_01_source.png`
- Chroma alpha: `output/imagegen/cave_object_atlas_01_alpha.png`
- Sliced preview: `output/imagegen/cave_object_atlas_01_sliced_preview.png`
- Room icon preview: `output/imagegen/cave_object_atlas_01_room_icon_preview.png`
- Slicer: `tools/slice_cave_object_atlas.py`

Final prop sprites:

- `assets/props/v2/prop_entrance_gate_v2_back.png`
- `assets/props/v2/prop_throne_v2_back.png`
- `assets/props/v2/prop_throne_v2_front.png`
- `assets/props/v2/prop_weapon_rack_v2_back.png`
- `assets/props/v2/prop_treasure_pile_v2_front.png`
- `assets/props/v2/prop_recovery_nest_v2_front.png`
- `assets/props/v2/prop_foundation_marks_v2_back.png`
- `assets/props/v2/prop_watch_post_v2_front.png`
- `assets/props/v2/prop_small_brazier_v2_back.png`

Room selection UI icons were regenerated from the same prop set:

- `assets/ui/room_v2/room_v2_entrance.png`
- `assets/ui/room_v2/room_v2_throne.png`
- `assets/ui/room_v2/room_v2_barracks.png`
- `assets/ui/room_v2/room_v2_treasure.png`
- `assets/ui/room_v2/room_v2_recovery.png`
- `assets/ui/room_v2/room_v2_build_slot.png`
- `assets/ui/room_v2/room_v2_watch_post.png`
- `assets/ui/room_v2/room_v2_center.png`
- `assets/ui/room_v2/room_v2_spike_corridor.png`

## Renderer Adjustment

`scripts/dungeon_quarter/QuarterDungeonRenderer.gd` keeps the same rule-based object placement, but the draw scale for several room-role props was increased so they remain visible inside the wall/edge assembly.

Important: this is only visual scale. It does not change floor masks, walkable cells, graph links, or socket rules.

## Audit After Slicing

The nine generated room props are all:

- present in `assets/props/v2`,
- non-empty after alpha removal,
- unique bitmaps,
- referenced by `data/dungeon_quarter/asset_manifest.json`,
- visible in the generated UI room icons.

## Visual Output

Updated captures:

- `tmp/manual_verification/01_management.png`
- `tmp/manual_verification/01_watch_post_facility.png`
- `tmp/manual_verification/01_map_editor.png`
- `tmp/manual_verification/04_combat_trap_trigger.png`

Current visual state:

- The default map now shows room-role props for entrance, barracks, treasure, recovery, throne, build slot, watch post, brazier, and spike corridor.
- The props are placed on top of the tile-grid dungeon rather than being baked into one room image.
- This is a first assembled cave object pass. Further polish should tune anchors and occlusion if the user wants a closer match to the reference style.

## Explicit Limitation

This pass must not be mistaken for a complete modular object system.

- Runtime does not use one big atlas image directly. The atlas was sliced into separate prop PNG files before use.
- However, each room role currently has only one main visual variant, except the throne which has back/front layers.
- The current renderer chooses sprites by `prop_id` and layer only, for example `prop:throne_f:front`.
- It does not yet choose object variants by room grid position, facing direction, wall side, open socket side, or near/far occlusion case.

Beginner translation: the objects are no longer one pasted room image, but they are still mostly "one picture per room role." That is enough for a first readable demo view, but it is not enough for a scalable quarter-view dungeon where the same room can rotate, move, or attach to walls in many directions.

## Required Next Object-System Work

The next object pass should create and wire an object variant rule before generating more art.

Minimum required structure:

- Add an object variant manifest or extend `data/dungeon_quarter/asset_manifest.json`.
- Each object should declare at least `facing` variants: `NW`, `NE`, `SE`, `SW`, or explicitly declare `directionless` if rotation does not matter.
- Large room objects should declare `back` and `front` slices when they can overlap units or walls.
- Room blueprints should be able to request a variant, for example `{"id": "throne_f", "facing": "SW", "layer": "front"}`.
- The renderer should choose the correct sprite from `prop_id + facing + layer`, not only `prop_id + layer`.
- Generated art contracts must say which slot corresponds to which direction and which room placement case.

This is the correct path before expanding to many rooms or moving the same facility type to arbitrary grid positions.

## Verification

Commands run on 2026-07-05:

```powershell
python -m py_compile tools\slice_cave_object_atlas.py
python tools\slice_cave_object_atlas.py
godot --headless --path . --import
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --path . --run res://tools/ManualVerificationCapture.tscn
```

Results:

- `QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`
- `DemoSmokeTest.tscn`: exit code 0 in this run.
- `ManualVerificationCapture.tscn`: exit code 0; captures updated in `tmp/manual_verification`.
