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

Live generation was not run because `OPENAI_API_KEY` is not set in the process, user, or machine environment.

Do not paste the key into chat. Set it locally as an environment variable, then run:

```powershell
$env:IMAGE_GEN = "C:\Users\LDK-6248\.codex\skills\.system\imagegen\scripts\image_gen.py"
python $env:IMAGE_GEN generate-batch `
  --input tools\imagegen\quarter_modules_gpt_image2_prompts.jsonl `
  --out-dir output\imagegen\quarter_modules\source `
  --concurrency 2 `
  --force
```

After that, remove the chroma key into `assets/sprites/dungeon_quarter/modules/`.

## Next Steps

1. Set `OPENAI_API_KEY` locally.
2. Run the GPT Image 2 batch.
3. Convert chroma-key source PNGs to transparent final PNGs.
4. Import assets in Godot.
5. Connect `QuarterDungeonRenderer` to these final module visuals.
6. Verify F3/F7 overlays still align with visible floor/walls.

