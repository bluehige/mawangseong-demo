# Image Generation Contract - Castle Upgrade Tiers

Date: 2026-07-08

## Goal

Create a four-stage visual progression for the Demon King castle and core room/facility objects.

The current castle art direction is too strong for a starting base, so the current dark fortress style is reclassified as Stage 02. Stage 01 must be a rough cave dungeon.

## Stage Columns

All sheets use the same four columns:

| column | stage id | visual brief |
|---:|---|---|
| 1 | `stage_01_cave` | rookie cave dungeon, rough stone, wood braces, rope, bones, weak torches |
| 2 | `stage_02_castle` | current compact dark fantasy castle, black basalt, purple crystals, organized rooms |
| 3 | `stage_03_keep` | fortified demon keep, reinforced walls, larger banners, stronger magic |
| 4 | `stage_04_citadel` | supreme demon citadel, obsidian, gold trim, grand crystals, final prestige |

## Object Rows

The object stage atlas uses seven rows:

| row | proof object id | intended runtime role |
|---:|---|---|
| 1 | `entrance_gate` | `entrance_gate_f` |
| 2 | `throne` | `throne_f` |
| 3 | `barracks` | `weapon_rack` / barracks room |
| 4 | `recovery_nest` | `recovery_nest_f` |
| 5 | `treasure_storage` | `treasure_pile_large` |
| 6 | `watch_post` | `watch_post` |
| 7 | `build_foundation` | `foundation_marks` |

## Generated Proof Sheets

Source sheets created in this pass:

- `docs/concepts/castle_upgrade_object_stage_atlas_gpt_image2_2026-07-08_source.png`
- `docs/concepts/castle_upgrade_base_stage_sheet_gpt_image2_2026-07-08_source.png`

Alpha-processed sheets:

- `output/imagegen/castle_upgrade_object_stage_atlas_gpt_image2_2026-07-08_alpha.png`
- `output/imagegen/castle_upgrade_base_stage_sheet_gpt_image2_2026-07-08_alpha.png`

Sliced proof output:

- `output/imagegen/castle_upgrade_tiers/`

## Prompt Template - Object Atlas

Use this structure for future correction passes:

```text
Create a game asset concept sheet for an isometric dark fantasy Demon King dungeon.

Canvas: one sprite atlas, 7 rows by 4 columns, no text, no labels, no UI, no characters.
Background: flat pure chroma green (#00ff00) only.
Style: high-detail hand-painted 2D game asset, isometric three-quarter view, transparent-ready silhouettes, readable at small size, dark fantasy but not overly noisy.

Columns from left to right:
1. stage_01_cave: rookie cave dungeon, rough stone, wood planks, rope, bones, weak torches, improvised and low-status.
2. stage_02_castle: compact dark Demon King castle, black basalt, purple crystals, organized rooms, similar to a first real fortress.
3. stage_03_keep: fortified demon keep, reinforced walls, banners, bigger magic crystals, stronger and more dangerous.
4. stage_04_citadel: supreme demon citadel, obsidian, gold trim, grand purple magic, final prestige.

Rows from top to bottom:
1. entrance gate
2. throne
3. barracks or monster training room
4. recovery nest / healing pool
5. treasure storage
6. watch post / command tower
7. build foundation / construction slot

Each cell must contain exactly one centered object. Keep consistent camera angle, lighting family, and object scale progression. Do not include captions, letters, numbers, arrows, humans, monsters, or decorative borders.
```

## Prompt Template - Castle/Base Sheet

Use this structure for future correction passes:

```text
Create a four-stage isometric Demon King base progression sheet.

Canvas: one row with 4 columns, no text, no labels, no UI, no characters.
Background: flat pure chroma green (#00ff00) only.
Style: high-detail hand-painted 2D game asset, isometric three-quarter view, readable as a game base icon or management-map centerpiece.

Column 1: stage_01_cave, rookie demon cave base, crude rooms carved into rock, wood beams, rope, bones, weak torches, small and vulnerable.
Column 2: stage_02_castle, compact dark castle inside a cave, black basalt, purple crystals, organized but not huge.
Column 3: stage_03_keep, reinforced demon keep, larger walls, banners, magic pylons, battle-ready.
Column 4: stage_04_citadel, supreme demon citadel, grand obsidian architecture, gold trim, strong purple magic, final-stage prestige.

The stage 1 base must look clearly weaker and more cave-like than stage 2. Keep all four bases from the same game and same camera angle. Do not include captions, letters, numbers, arrows, humans, monsters, or decorative borders.
```

## Processing Pipeline

1. Generate source sheet through built-in imagegen/gpt-image-2.
2. Copy the selected source into both `docs/concepts/` and `output/imagegen/`.
3. Remove chroma key with:

```powershell
python $env:USERPROFILE\.codex\skills\.system\imagegen\scripts\remove_chroma_key.py --input <source.png> --out <alpha.png> --auto-key border --soft-matte --transparent-threshold 12 --opaque-threshold 220 --despill
```

4. Slice proof sprites with:

```powershell
python tools/slice_castle_upgrade_stage_proofs.py
```

## Approval Rule

These are proof assets only.

Do not wire them into `data/dungeon_quarter/asset_manifest.json` or runtime renderers until the user approves:

- stage language;
- object identity;
- facing direction;
- open-mask/path compatibility.

