# Castle And Facility Upgrade Stage Plan

Date: 2026-07-08

## User Problem

The current beginner Demon King castle reads too advanced. It already looks like a polished fortress, so it does not leave enough visual or mechanical room for base upgrades.

Decision for the current art direction:

- The current dark basalt / purple crystal castle style should become **Stage 02**, not the starting state.
- The new starting state should be a rough cave dungeon: improvised, smaller, lower-status, and visibly weak.
- The castle, room objects, and facility objects should progress together across four user-facing upgrade stages.

## Four User-Facing Stages

| stage id | display intent | visual rule | progression role |
|---|---|---|---|
| `stage_01_cave` | Rookie cave dungeon | rough stone, wood braces, rope, bones, weak torches, small magic traces | tutorial / first base |
| `stage_02_castle` | Small Demon King castle | current black stone, purple crystals, organized rooms, compact fortress feel | first major upgrade |
| `stage_03_keep` | Fortified demon keep | taller walls, stronger banners, bigger crystal pylons, reinforced facilities | mid-game power spike |
| `stage_04_citadel` | Supreme demon citadel | grand obsidian, gold trim, dense magic, elite throne/citadel architecture | late-game / final fantasy |

The important readability rule is that stage upgrades must be visible at a glance. A player should understand "my base got stronger" before reading stats.

## Existing System Fit

The current dungeon asset pipeline has two relevant layers:

- Internal castle grade rules in `data/dungeon_quarter/castle_grade_rules.json`.
- Room object and facing sprite contracts in `data/dungeon_quarter/asset_manifest.json`.

These should not be collapsed into one concept. Recommended structure:

```text
gameplay grade/rules -> what bonuses and unlocks exist
art stage           -> what visual tier should be shown
```

Initial mapping if the existing F-S grade system stays:

| internal grade | proposed art stage |
|---|---|
| `F`, `E` | `stage_01_cave` |
| `D`, `C` | `stage_02_castle` |
| `B`, `A` | `stage_03_keep` |
| `S` | `stage_04_citadel` |

If the game later gets explicit base levels, prefer a direct `castle_art_stage` value in save/state data and let grade only affect rules.

## Manifest Direction

Do not replace the current runtime sprite references with generated proofs yet. The manifest already marks imagegen proofs as proof-only until approved. Keep that policy.

Recommended future manifest shape:

```json
{
  "castle_art_stages": {
    "stage_01_cave": {
      "name": "Rookie Cave",
      "base_sprite": "assets/castle/stages/stage_01/castle_base_stage_01.png"
    },
    "stage_02_castle": {
      "name": "Small Castle",
      "base_sprite": "assets/castle/stages/stage_02/castle_base_stage_02.png"
    }
  },
  "props": {
    "throne_f": {
      "upgrade_stage_sprites": {
        "stage_01_cave": {
          "SW": {
            "open_04": {
              "back": "assets/props/stages/stage_01/room_throne_f_fg5_SW_open_04_back.png",
              "front": "assets/props/stages/stage_01/room_throne_f_fg5_SW_open_04_front.png"
            }
          }
        }
      }
    }
  }
}
```

Renderer lookup should be:

```text
stage-specific full-grid sprite
-> stage-specific facing sprite
-> existing facing_sprites fallback
-> placeholder/failure texture
```

That keeps the demo playable while individual stage assets are approved and wired in.

## Facility Upgrade Meaning

The building upgrade system should not be visual-only. Each object needs a combat or loop reason to exist.

| object | stage 1 meaning | stage 2 meaning | stage 3 meaning | stage 4 meaning |
|---|---|---|---|---|
| entrance gate | weak choke, short warning | sturdier choke and clearer spawn control | invasion delay / trap prep bonus | elite gate with strong breach resistance |
| throne | basic core HP | core HP plus small command aura | larger aura / emergency rally | final core, major command and survival value |
| barracks | basic monster holdout | current attack/defense room role | higher capacity / faster response | elite garrison and strongest defensive anchor |
| recovery nest | slow heal room | current combat healing | better retreat recovery | cleanse / emergency recovery identity |
| treasure storage | small thief target | current risk/reward economy room | better reward but higher raid priority | major economy room, high defense incentive |
| watch post | small detection point | current slow/damage support | wider command/slow area | major control room and trap coordination |
| build foundation | empty slot marker | proper construction slot | faster construction / trap socket | advanced construction platform |

This should connect to the existing combat balance pass where barracks, watch post, recovery, and treasure already have active battle effects.

## Production Strategy

Blindly generating every full-grid variant is too expensive and too error-prone:

```text
4 stages * 7 full-grid-capable roles * 4 facings * 16 open masks = 1792 role/mask combinations
```

If back/front layers are split, the real image count can be even higher.

Use this sequence instead:

1. Generate proof sheets for the four-stage visual language.
2. Approve the stage language with the user.
3. Generate stage-specific role/facing interiors without baking every wall opening.
4. Generate shared wall shells per stage and `open_mask`.
5. Generate shared doorway/path-mouth overlays per stage.
6. Compose role interior + wall shell + doorway overlay in a tool or renderer.
7. Bake only hero rooms manually when the integrated look is worth the cost.

The current generated proof set completes step 1 only.

## Current Generated Proofs

Created with the built-in gpt-image-2/imagegen route:

- `docs/concepts/castle_upgrade_object_stage_atlas_gpt_image2_2026-07-08_source.png`
- `docs/concepts/castle_upgrade_base_stage_sheet_gpt_image2_2026-07-08_source.png`
- `output/imagegen/castle_upgrade_object_stage_atlas_gpt_image2_2026-07-08_source.png`
- `output/imagegen/castle_upgrade_base_stage_sheet_gpt_image2_2026-07-08_source.png`
- `output/imagegen/castle_upgrade_object_stage_atlas_gpt_image2_2026-07-08_alpha.png`
- `output/imagegen/castle_upgrade_base_stage_sheet_gpt_image2_2026-07-08_alpha.png`
- `output/imagegen/castle_upgrade_tiers/`

The sliced proof folder contains:

- 28 facility/object proof sprites: 7 objects * 4 stages.
- 4 castle/base proof sprites.
- 1 preview sheet: `castle_upgrade_tiers_sliced_preview.png`.

Slicing tool:

- `tools/slice_castle_upgrade_stage_proofs.py`

## Runtime Integration Plan

1. Add stage state:
   - demo default should be `stage_01_cave`;
   - existing current look should be assigned to `stage_02_castle`.
2. Add stage-aware asset lookup:
   - `QuarterDungeonRenderer.gd` should receive or infer the active castle art stage;
   - prop lookup should prefer `upgrade_stage_sprites` before existing fallback sprites.
3. Add upgrade data:
   - stage cost;
   - unlocks;
   - facility effect scaling.
4. Add UI:
   - show castle/facility stage in the selected-room panel;
   - expose upgrade action only where it affects a selected building;
   - avoid adding another global bottom button unless it is a major loop action.
5. Add QA:
   - screenshot stage 1 default management view;
   - screenshot stage 2 upgraded management view;
   - verify throne facing stays `SW` where required;
   - verify object images do not imply wrong path openings.

## QA Status

The proof preview was visually inspected after chroma-key removal and slicing. The stage direction is acceptable for planning:

- Stage 1 reads as rough cave/rookie dungeon.
- Stage 2 reads close to the current polished dark fantasy castle.
- Stage 3 and 4 increase scale and prestige.

Follow-up visual-contract QA was completed in:

- `docs/CASTLE_VISUAL_CONTRACT_QA_REPORT_2026-07-08.md`
- `output/imagegen/castle_contract_qa/castle_visual_contract_validation.md`

Data contract result:

- `62 / 62` checks passed for direction keys, default open masks, paired sockets, and road/path connection counts.

Generated visual proof result:

- path component atlas is the strongest next production candidate;
- single throne `SW` proof is direction-correct but too ornate for final Stage 01;
- broad direction atlas and 16-open-mask room sheet are proof-only and not runtime-approved.

Not approved yet:

- final runtime sprites;
- exact `NW/NE/SE/SW` facing sets;
- all `open_mask` room variants;
- Godot renderer wiring.
