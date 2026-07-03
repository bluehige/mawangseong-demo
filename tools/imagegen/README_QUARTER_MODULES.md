# Quarter Module GPT Image 2 Built-In Generation

This folder stores the project-bound GPT Image 2 prompts for the quarter-view socket module map.

## Non-Negotiable Generation Rule

- In this project, "GPT Image 2" means Codex's built-in `image_gen` image generation tool.
- Do not switch to the API/CLI fallback for these map assets.
- Do not ask for `OPENAI_API_KEY` for these map assets.
- Do not replace requested image assets with procedural/vector/code-drawn placeholder art.
- Generate image assets with the built-in tool first, then copy the generated file from `C:\Users\LDK-6248\.codex\generated_images\...` into the project.
- Use code only for post-processing generated images: copying, cropping, alpha extraction, slicing, resizing, import, and manifest wiring.

## Mandatory Grid-Position Contract

Before generating any map image, define where it will sit on the logical grid and number that placement. Do not generate art first and decide placement afterward.

Every prompt/spec must include:

- `asset_id`
- `grid_size`
- numbered `grid_cells` in `Gxx_yy` format
- `anchor_cell`
- `connected_sides`
- `blocked_sides`
- `layer`
- `final_manifest_path`

For asset sheets, every slice region must be numbered before generation, and the numbering must be preserved in the slicing script, manifest notes, or contact sheet.

Before continuing after a session handoff or context compression, read `docs/HANDOFF_MAP_CUSTOM_CURRENT_2026-07-03.md` first, then read the reference docs listed there. This is mandatory for this map-custom work.

## Rule Locked Into The Prompts

- Connected module sockets must be open two-cell-wide doorways.
- Unconnected sides must be sealed with stone wall, cave rock, columns, or rubble.
- The visual resource is not authoritative for navigation. `data/dungeon_quarter/modules.json` remains authoritative for `walk_cells`, `block_cells`, `prop_block_cells`, and `socket_entry_cells`.
- For transparent sprites, use the built-in image generation path with a flat `#00ff00` chroma-key background, then remove the chroma key locally.

## Generate With Built-In Image Generation

Use Codex's built-in image generation tool. The prompt JSONL is a prompt/spec source, not an instruction to run the CLI.

For multiple assets, issue separate built-in generation calls or generate an asset sheet with clearly separated tiles/props. After generation, copy the chosen output into `output/imagegen/quarter_modules/source/` or another explicit project path.

## Post-Process

After generation, remove the chroma key and save final alpha PNGs under:

```text
assets/sprites/dungeon_quarter/modules/
```

Use the installed helper:

```powershell
$env:CHROMA = "C:\Users\LDK-6248\.codex\skills\.system\imagegen\scripts\remove_chroma_key.py"
python $env:CHROMA --input output\imagegen\quarter_modules\source\room_entrance_01_visual_chroma.png --out assets\sprites\dungeon_quarter\modules\room_entrance_01_visual.png --auto-key border --soft-matte --transparent-threshold 12 --opaque-threshold 220 --despill
```

Repeat for the remaining generated source images.

## Current Generated Assets

The current checked-in final assets were generated with the internal GPT image generation tool after the user clarified that this was the intended GPT Image 2 path.

Final transparent PNGs:

```text
assets/sprites/dungeon_quarter/modules/*_visual.png
```
