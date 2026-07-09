# Handoff: DAY 08-10 Campaign, Investigator, And Assets

Date: 2026-07-09

## Summary

DAY 08-10 is now implemented as the chapter-1 close bundle:

- DAY 08: monster growth preview and Rolo usage decision.
- DAY 09: new `investigator` enemy class and mixed-role pressure.
- DAY 10: guild-board chapter close, chapter-one-clear flag, and Stage 02 preparation flag.

Rolo / `kobold_scout` remains raid/scout support in this pass. He has only `monster_kobold_scout_idle_down_00.png`, so normal defense deployment is intentionally deferred until the missing move/attack/skill/down frames are produced.

## Data Changes

- `data/campaign_days.json`
  - Added `day_8`, `day_9`, `day_10`.
  - Added `monster_plan`, `enemy_plan`, `balance_goal`, `result_lines`, and asset notes.
  - DAY 08 has `asset_decision = "rolo_raid_scout_support"`.
  - DAY 10 has `chapter_one_clear = true` and `stage_two_prepared = true`.
- `data/enemies.json`
  - Added `investigator`.
  - Role: throne-targeting durable investigator, between explorer and trainee hero.
- `data/characters.json`
  - Added `CHR_INVESTIGATOR_IRIS`.
  - Registered portrait variant `inquisitive`.
- `data/waves.json`
  - Added tuned `day_8`, `day_9`, `day_10` waves.

## Runtime Changes

- `scripts/game/GameRoot.gd`
  - Added campaign chapter flags:
    - `campaign_chapter_one_clear`
    - `campaign_stage_two_prepared`
  - Added `monster_plan` notice support through `_campaign_notice_monster_line()`.
  - Added data-driven campaign result lines and campaign result flags.
  - Added `_monster_available_for_defense()` so Rolo can remain in the roster as raid/scout support without being deployed in normal defense.
  - Added a no-wave guard so DAY 11 management does not start an empty auto-win combat before the next content slice exists.
- `scripts/game/ManagementSceneController.gd`
  - Expanded the campaign notice panel and added the monster usage line.
- `scripts/game/CombatSceneController.gd`
  - Skips support-only monsters when spawning defense units and awarding defense EXP.
  - Appends campaign `result_lines` to the result screen.
  - Applies campaign result flags after a win.
- `tools/DemoSmokeTest.gd`
  - Added DAY 08-10 coverage:
    - Campaign data loads.
    - Rolo support-only decision is recorded.
    - Rolo remains in the roster but is defense-disabled and not spawned in DAY 08 combat.
    - `investigator` data, spawn, route, and sprite frames are valid.
    - DAY 10 sets chapter flags and continues to DAY 11 management.
    - DAY 11 combat start is blocked until real wave data exists.
- `tools/CharacterDataSmokeTest.gd`
  - Added `CHR_INVESTIGATOR_IRIS` to required character validation.
- `tools/BalanceSimulation.gd`
  - Added regular-campaign scenarios:
    - `DAY8_GROWTH_PREVIEW`
    - `DAY9_INVESTIGATOR`
    - `DAY10_CHAPTER_CLOSE`

## Generated Assets

Built-in `image_gen` was used.

Generated source folder:

- `C:\Users\LDK-6248\.codex\generated_images\019f441b-2196-7203-bb56-614de18b6132`

Generated source files used:

- Portrait source: `ig_05c0c72059e7a7c9016a4efac8b1a88199abc4d72384a4c627.png`
- Combat sprite source: `ig_05c0c72059e7a7c9016a4efb092ba48199b58486c934b0a6ea.png`

Project assets:

- `assets/sprites/portraits/onboarding/CHR_INVESTIGATOR_IRIS_portrait_inquisitive.png`
- `assets/sprites/enemies/enemy_investigator_idle_down_00.png`
- `assets/sprites/enemies/enemy_investigator_idle_down_01.png`
- `assets/sprites/enemies/enemy_investigator_move_down_00.png`
- `assets/sprites/enemies/enemy_investigator_move_down_01.png`
- `assets/sprites/enemies/enemy_investigator_move_down_02.png`
- `assets/sprites/enemies/enemy_investigator_move_down_03.png`
- `assets/sprites/enemies/enemy_investigator_attack_down_00.png`
- `assets/sprites/enemies/enemy_investigator_attack_down_01.png`
- `assets/sprites/enemies/enemy_investigator_attack_down_02.png`
- `assets/sprites/enemies/enemy_investigator_attack_down_03.png`
- `assets/sprites/enemies/enemy_investigator_skill_down_00.png`
- `assets/sprites/enemies/enemy_investigator_skill_down_01.png`
- `assets/sprites/enemies/enemy_investigator_skill_down_02.png`
- `assets/sprites/enemies/enemy_investigator_skill_down_03.png`
- `assets/sprites/enemies/enemy_investigator_down_00.png`
- `assets/sprites/enemies/enemy_investigator_down_01.png`

Godot import was run and `.import` files exist for the new portrait and 16 combat frames.

## Balance Results

Regular-campaign baseline in `tools/BalanceSimulation.gd` assumes:

- Pudding/Gob/Pynn are Lv.2.
- DAY 07 barracks Lv.2 upgrade is present.
- Watch post is built in `slot_01`.
- Active skills are used by the simulation helper.

Final measured results:

| Scenario | Result | Time | Monster Down | Enemies | Thief Reached | Thief Stole |
|---|---:|---:|---:|---:|---:|---:|
| `DAY8_GROWTH_PREVIEW` | WIN | 61.2s | 2 | 5/5 | N | N |
| `DAY9_INVESTIGATOR` | WIN | 70.8s | 1 | 6/6 | N | N |
| `DAY10_CHAPTER_CLOSE` | WIN | 107.1s | 3 | 6/6 | N | N |

Balance interpretation:

- DAY 08 is a readable growth-preview fight.
- DAY 09 introduces `investigator` without making treasure loss inevitable.
- DAY 10 is the hardest fight in this bundle but clears before timeout.

## Verification

Passed:

- `python -m json.tool data\campaign_days.json > $null`
- `python -m json.tool data\monsters.json > $null`
- `python -m json.tool data\enemies.json > $null`
- `python -m json.tool data\waves.json > $null`
- `python -m json.tool data\raid_missions.json > $null`
- `python -m json.tool data\characters.json > $null`
- `godot --headless --path . --import --quit-after 1`
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`
- `godot --headless --path . --run res://tools/CharacterDataSmokeTest.tscn`
- `godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn`
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`
- `godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY8_GROWTH_PREVIEW`
- `godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY9_INVESTIGATOR`
- `godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY10_CHAPTER_CLOSE`
- `git diff --check`

`git diff --check` prints existing LF/CRLF conversion warnings only.

## Review Status

First review agent run completed and returned two actionable findings:

1. P1: Rolo was documented as raid/scout support but still entered normal defense through `monster_roster`.
   - Fixed by marking `kobold_scout` with `defense_enabled = false` and `raid_support = true`.
   - Defense placement UI, combat spawning, management previews, relocation, and defense EXP now filter through `_monster_available_for_defense()`.
   - `DemoSmokeTest` verifies Rolo remains in the roster but is not defense deployable and does not spawn in DAY 08.
2. P2: DAY 10 advanced to DAY 11 management, but DAY 11 has no wave data yet.
   - Fixed by blocking non-onboarding combat start when no defense wave exists for the current day.
   - `DemoSmokeTest` verifies DAY 11 remains in management instead of starting empty combat.

Post-fix verification passed:

- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`
- `godot --headless --path . --run res://tools/CharacterDataSmokeTest.tscn`
- `godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn`
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`
- JSON parsing for `campaign_days`, `characters`, `enemies`, `waves`, and `raid_missions`
- `godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY8_GROWTH_PREVIEW`
- `godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY9_INVESTIGATOR`
- `godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY10_CHAPTER_CLOSE`
- `git diff --check`

Second review agent run completed and returned two additional P2 findings:

1. `DungeonRenderer.draw_roster_preview()` still drew every `monster_roster` entry, so support-only Rolo could appear on the management map.
   - Fixed by adding `DungeonRenderer._roster_preview_monster_ids()` and filtering through `_monster_available_for_defense()`.
   - `DemoSmokeTest` now verifies Rolo is absent from the renderer preview id list.
2. The normal monster management screen still exposed Rolo as a selectable/trainable monster.
   - Fixed by adding `GameRoot._defense_monster_ids()`, `_support_only_monster_line()`, and `_ensure_selected_monster_available_for_defense()`.
   - `ManagementSceneController.build_monster_ui()` now lists only defense-enabled monsters and shows support-only units as an informational line.
   - `_select_monster()` and `_train_selected_monster()` now block support-only monsters without spending gold or changing EXP.
   - `DemoSmokeTest` verifies Rolo cannot be selected/trained through the normal defense management path and appears only in the support-only notice.

Post-second-review-fix verification passed:

- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`
- `godot --headless --path . --run res://tools/CharacterDataSmokeTest.tscn`
- `godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn`
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`
- JSON parsing for `campaign_days`, `characters`, `enemies`, `waves`, and `raid_missions`
- `git diff --check`

Third review agent pass returned `No findings`.

Final post-review verification passed:

- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`
- `godot --headless --path . --run res://tools/CharacterDataSmokeTest.tscn`
- `godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn`
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`
- JSON parsing for `campaign_days`, `characters`, `enemies`, `waves`, and `raid_missions`
- `godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY8_GROWTH_PREVIEW` -> WIN, 61.2s, monster down 2, enemies 5/5, thief reached/stole N/N
- `godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY9_INVESTIGATOR` -> WIN, 70.8s, monster down 1, enemies 6/6, thief reached/stole N/N
- `godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY10_CHAPTER_CLOSE` -> WIN, 107.1s, monster down 3, enemies 6/6, thief reached/stole N/N
- `git diff --check`

Current review status: complete.

## Next Recommended Work

- DAY 11 kingdom-response slice has been implemented. See `docs/HANDOFF_DAY11_KINGDOM_NOTICE_2026-07-09.md`.
- If Rolo should become a normal defender, produce the missing `monster_kobold_scout_move/attack/skill/down` frames first.
- Stage 02 should not start by changing castle visuals unless Stage 02 room/path art is approved and imported.
- The next playable content slice can start at DAY 12 with a small monster promotion/evolution decision.
