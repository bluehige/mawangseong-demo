# Quarter Module GPT Image 2 Batch

This folder stores the project-bound GPT Image 2 prompts for the quarter-view socket module map.

## Rule Locked Into The Prompts

- Connected module sockets must be open two-cell-wide doorways.
- Unconnected sides must be sealed with stone wall, cave rock, columns, or rubble.
- The visual resource is not authoritative for navigation. `data/dungeon_quarter/modules.json` remains authoritative for `walk_cells`, `block_cells`, `prop_block_cells`, and `socket_entry_cells`.
- GPT Image 2 does not support native transparent background in this CLI path, so prompts use a flat `#00ff00` chroma-key background for local alpha extraction.

## Generate With CLI Fallback

This is the explicit API/CLI fallback path. It requires `OPENAI_API_KEY`; do not paste the key into chat.

```powershell
$env:IMAGE_GEN = "C:\Users\LDK-6248\.codex\skills\.system\imagegen\scripts\image_gen.py"
python $env:IMAGE_GEN generate-batch `
  --input tools\imagegen\quarter_modules_gpt_image2_prompts.jsonl `
  --out-dir output\imagegen\quarter_modules\source `
  --concurrency 2 `
  --force
```

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

