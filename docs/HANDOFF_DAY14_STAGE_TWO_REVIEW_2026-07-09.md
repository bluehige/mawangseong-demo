# Handoff: DAY 14 Stage Two Review (2026-07-09)

## Scope

Implemented DAY 14 from `docs/STORY_PLAN_AFTER_TUTORIAL_2026-07-08.md`.

DAY 14 plan reference:

- Story goal: castle upgrade review.
- Play goal: prepare transition from Stage 01 to Stage 02.
- New thing shown: castle stage / visual-change preview.
- Cast: Goldin, Bati.
- Completion: upgrade cost secured.

## Design Decision

DAY 14 is not the Stage 02 visual switch.

Reason:

- Existing Stage 02 runtime room/path asset matrix is not approved or wired.
- Existing docs explicitly say not to switch visuals until approved Stage 02 assets exist.
- The next playable slice should be an upgrade review and resource gate, not a visual conversion.

Implemented instead:

- DAY 14 campaign data and wave.
- Stage 02 review cost gate.
- Result flag `campaign_stage_two_upgrade_funded`.
- Result marker `stage_two_upgrade_funded`.
- Result marker `stage_two_visual_deferred`.

Second promotion remains locked:

- `promotion_limit: 1` is still declared for DAY 14.
- The existing `SECOND_PROMOTION_UNLOCK_DAY = 23` default remains the long-term guard.

## Stage Two Review Cost

Cost:

```json
{
  "gold": 720,
  "infamy": 720
}
```

No mana cost is included.

Reason:

- DAY 14 asks the player to preserve treasury and reputation.
- Requiring a high mana balance punished caster/skill-heavy play and made `imp_flame_adept` fail the review despite winning the fight.
- Gold and infamy better match the story beat: formal castle review, reputation, and treasury security.

## Data Added

- `data/campaign_days.json`
  - Added `day_14`.
  - Added `stage_two_upgrade_review: true`.
  - Added `stage_two_upgrade_cost`.
  - Explicitly records `asset_decision: stage_two_visual_deferred_runtime_assets_missing`.
- `data/waves.json`
  - Added `day_14`.

DAY 14 wave:

| Enemy | Count | Timing | Purpose |
|---|---:|---|---|
| explorer | 3 | 0.0s, 4.1s interval | baseline pressure |
| investigator | 1 | 16.0s | kingdom record pressure |
| shieldbearer | 1 | 28.0s | limited repeat of DAY13 frontliner |
| thief | 2 | 40.0s, 10.0s interval | treasury pressure |

No new enemy class or raster art was added in this slice.

## Code Added

`scripts/game/GameRoot.gd`

- Added `campaign_stage_two_upgrade_funded`.
- Reset the flag with other campaign state.
- Added dynamic campaign result line for `stage_two_upgrade_review`.
- Added `_stage_two_upgrade_cost()` and `_stage_two_upgrade_cost_label()`.
- Sets `campaign_stage_two_upgrade_funded = true` after a winning result if resources meet the DAY14 cost.

Important flow:

1. Combat rewards are applied first in `CombatSceneController.finish_combat()`.
2. `_campaign_result_lines(win)` checks current resources and appends either funded or unfunded result marker.
3. `_apply_campaign_result_flags(win)` sets `campaign_stage_two_upgrade_funded` if funded.

## Tests Updated

`tools/DemoSmokeTest.gd`

Now verifies:

- DAY 14 campaign data loads.
- DAY 14 still blocks second promotion.
- Stage 02 review cost is `gold 720 / infamy 720`.
- DAY 14 wave starts.
- DAY 14 schedules 7 enemies:
  - explorer 3
  - investigator 1
  - shieldbearer 1
  - thief 2
- DAY 14 result sets `campaign_stage_two_upgrade_funded`.
- DAY 14 result includes `stage_two_upgrade_funded`.
- DAY 14 result includes `stage_two_visual_deferred`.
- DAY 14 advances to DAY 15 management.
- DAY 15 still keeps promotion limit 1 and preserves the funded flag.
- DAY 15 combat remains blocked because no DAY 15 wave is implemented yet.

`tools/BalanceSimulation.gd`

Added:

- `DAY14_STAGE_TWO_REVIEW_SLIME`
- `DAY14_STAGE_TWO_REVIEW_GOBLIN`
- `DAY14_STAGE_TWO_REVIEW_IMP`

Simulation JSON now includes `stage_two_upgrade_funded`.

## Verification

Passed:

```powershell
python -m json.tool data\campaign_days.json > $null; python -m json.tool data\waves.json > $null; python -m json.tool data\enemies.json > $null; python -m json.tool data\evolution_rules.json > $null
git diff --check
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --headless --path . --run res://tools/CharacterDataSmokeTest.tscn
godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY13_SHIELDBEARER_IMP
godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY14_STAGE_TWO_REVIEW_SLIME
godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY14_STAGE_TWO_REVIEW_GOBLIN
godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY14_STAGE_TWO_REVIEW_IMP
```

`git diff --check` passed with line-ending warnings only.

DAY14 balance:

| Scenario | Result | Time | Throne HP | Monster Down | Enemies | Thief | Stage 02 funded |
|---|---|---:|---:|---:|---:|---|---|
| DAY14_STAGE_TWO_REVIEW_SLIME | WIN | 86.1s | 1500 | 1 | 7/7 | reached N, stole N | true |
| DAY14_STAGE_TWO_REVIEW_GOBLIN | WIN | 73.8s | 1500 | 1 | 7/7 | reached N, stole N | true |
| DAY14_STAGE_TWO_REVIEW_IMP | WIN | 81.7s | 1500 | 1 | 7/7 | reached N, stole N | true |

Tuning note:

- First DAY14 attempt used 3 thieves and a high mana cost. It caused one stolen-treasure case and one timeout.
- Final tuning reduced thieves to 2, reduced shieldbearer/thief HP scale, and removed the mana cost.

## Review Status

Implementation self-check passed. External review agent still needs to run after this handoff, then findings must be fixed and re-reviewed.

## Next Work

Recommended next slice: DAY 15 Selen trainee paladin boss / Stage 02 unlock gate.

Do:

- Add DAY 15 campaign data and wave.
- Introduce Selen only if character data and portrait scope are included.
- Decide whether DAY 15 consumes the DAY14 `campaign_stage_two_upgrade_funded` flag or only requires it.
- If Stage 02 visuals are still not approved, keep visual switch deferred and only set a future unlock flag.
- If switching visuals, first read the castle upgrade visual contracts and quarantine rules, then add runtime assets with tests.
- Keep second promotion locked; DAY23 remains the planned second-promotion point.
