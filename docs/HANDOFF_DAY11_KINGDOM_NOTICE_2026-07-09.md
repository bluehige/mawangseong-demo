# Handoff: DAY 11 Kingdom Notice

Date: 2026-07-09

## Summary

DAY 11 is implemented as the first playable slice after the chapter-1 close.

- Theme: the kingdom posts an official warning after the guild-board incident.
- Gameplay role: a shorter chapter-2 opener that reuses existing assets while testing route discipline and treasure defense.
- Scope control: no Stage 02 visual conversion and no new character/enemy art in this pass.

Rolo / `kobold_scout` remains raid/scout support only. He is mentioned in the DAY 11 management text but is still excluded from defense placement, defense spawn, renderer previews, normal monster training, and normal monster management buttons.

## Data Changes

- `data/campaign_days.json`
  - Added `day_11`.
  - Added `chapter_two_started = true`.
  - Added `asset_decision = "reuse_existing_chapter_one_assets"`.
  - Cast uses `CHR_BATI`, `CHR_INVESTIGATOR_IRIS`, and `CHR_ROLO`.
  - Result lines include `(chapter_two_started)` for testable progression.
- `data/waves.json`
  - Added `day_11`.
  - Wave budget:
    - `explorer` x4
    - `investigator` x1
    - `thief` x2

## Runtime Changes

- `scripts/game/GameRoot.gd`
  - Added `campaign_chapter_two_started`.
  - `_apply_campaign_result_flags()` now sets `campaign_chapter_two_started` from campaign day data.
  - `_reset_raid_state()` resets chapter campaign flags for clean new-game state.

## Test Changes

- `tools/DemoSmokeTest.gd`
  - Renamed the campaign coverage block to DAY 08-11.
  - Verifies DAY 11 campaign data loads.
  - Verifies DAY 10 continues into DAY 11 management.
  - Verifies DAY 11 combat starts because wave data now exists.
  - Verifies DAY 11 schedule count: 7 total, 1 investigator, 2 thieves.
  - Verifies Rolo still does not spawn in DAY 11 defense.
  - Verifies DAY 11 victory sets `campaign_chapter_two_started`.
  - Verifies DAY 12 still blocks combat start when no wave data exists.
- `tools/BalanceSimulation.gd`
  - Added `DAY11_KINGDOM_NOTICE`.

## Asset Decision

No new raster asset was generated for this pass.

This is intentional:

- DAY 11 reuses existing Bati, Rolo, Iris, explorer, thief, and investigator assets.
- Stage 02 visual conversion remains deferred until room/path art is approved and imported.
- If Rolo becomes a normal defender later, produce and import the missing `monster_kobold_scout_move/attack/skill/down` frames first.

## Balance Result

Regular-campaign baseline in `tools/BalanceSimulation.gd`:

- Pudding/Gob/Pynn are Lv.2.
- DAY 07 barracks Lv.2 upgrade is present.
- Watch post is built in `slot_01`.
- Active skills are used by the simulation helper.

Measured result:

| Scenario | Result | Time | Monster Down | Enemies | Thief Reached | Thief Stole |
|---|---:|---:|---:|---:|---:|---:|
| `DAY11_KINGDOM_NOTICE` | WIN | 87.7s | 2 | 7/7 | N | N |

Balance interpretation:

- DAY 11 is easier than the DAY 10 chapter close but still tests mixed-role defense.
- Treasure pressure exists through two thieves but did not become unavoidable in the regular-campaign setup.
- No throne damage occurred in the measured run.

## Verification

Passed before review:

- JSON parsing for `campaign_days`, `waves`, `characters`, `enemies`, and `raid_missions`
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`
- `godot --headless --path . --run res://tools/CharacterDataSmokeTest.tscn`
- `godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn`
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`
- `godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY11_KINGDOM_NOTICE`
- `git diff --check`

`git diff --check` prints existing LF/CRLF conversion warnings only.

## Review Status

Review agent pass returned `No findings`.

Review-agent rerun verification:

- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn` passed.
- `godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY11_KINGDOM_NOTICE` -> WIN, 87.7s, monster down 2, enemies 7/7, thief reached/stole N/N.
- `git diff --check` prints existing LF/CRLF conversion warnings only.

Current review status: complete.

## Next Recommended Work

- DAY 12 can introduce the first choice around monster promotion/evolution, but keep it read-only or one-step unless the full upgrade chain is tested.
- Do not start Stage 02 visual conversion until approved Stage 02 room/path assets exist.
- Rolo should remain support-only until full defense animation frames are produced and imported.
