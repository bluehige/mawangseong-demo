# Handoff: DAY 13 Shieldbearer Counter (2026-07-09)

## Scope

Implemented the DAY 13 campaign slice from `docs/STORY_PLAN_AFTER_TUTORIAL_2026-07-08.md`.

DAY 13 plan reference:

- Story goal: enemy brings a role counter.
- Play goal: defeat the counter enemy.
- New thing shown: counter enemy explanation.
- Cast: Bati plus kingdom-side procedural pressure.
- Completion: counter enemy defeated.

## Design Decision

The monster evolution plan places the second promotion/second evolution at DAY 23, not DAY 13. For that reason DAY 13 keeps the Chapter 2 early-game rule:

- One first-promotion monster only.
- No second promotion yet.
- DAY 13 is used to test enemy role pressure against the first promotion choice.

Implementation detail:

- Added generic `promotion_limit` support in `scripts/game/GameRoot.gd`.
- DAY 12 still declares `first_promotion_limit: true` for compatibility and now also declares `promotion_limit: 1`.
- DAY 13 declares `promotion_limit: 1`.
- Dates after DAY 13 that do not yet have campaign data still default to `promotion_limit: 1` until `SECOND_PROMOTION_UNLOCK_DAY` / DAY 23.
- The block reason remains `오늘은 1명만` so existing UI/tests stay readable.

## Added Enemy

Enemy id: `shieldbearer`

Display name: `왕국 방패병`

Role:

- Slow and sturdy throne-targeting frontliner.
- Counters pure front-line blocking by increasing contact time.
- Does not introduce special AI yet; this keeps DAY 13 focused on balance and lets later boss/special-unit work add active patterns deliberately.

Base stats:

```json
{
  "max_hp": 135,
  "atk": 8,
  "def": 6,
  "move_speed": 82,
  "attack_range": 44,
  "attack_interval": 1.25
}
```

## Graphics

Generated deterministic local combat sprites:

- `enemy_shieldbearer_idle_down_00..01.png`
- `enemy_shieldbearer_move_down_00..03.png`
- `enemy_shieldbearer_attack_down_00..03.png`
- `enemy_shieldbearer_skill_down_00..03.png`
- `enemy_shieldbearer_down_00..01.png`

Source/rebuild path:

- `tools/generate_shieldbearer_enemy_assets.py`
- `assets/sprites/enemies/SOURCE_SHIELDBEARER.md`

Import:

- Ran `godot --headless --path . --import --quit-after 1`.
- 16 PNG files and 16 `.png.import` files are present for `enemy_shieldbearer_*`.

## Data Added

- `data/enemies.json`
  - Added `shieldbearer`.
- `data/waves.json`
  - Added `day_13`.
- `data/campaign_days.json`
  - Added `day_13` story, monster plan, enemy plan, result markers, and art notes.
  - Added `promotion_limit: 1` to DAY 12 and DAY 13.

DAY 13 wave:

| Enemy | Count | Timing | Purpose |
|---|---:|---|---|
| explorer | 3 | 0.0s, 4.3s interval | baseline pressure |
| shieldbearer | 1 | 12.0s | new role counter |
| investigator | 1 | 23.0s | kingdom record pressure |
| thief | 2 | 37.0s, 8.0s interval | treasure pressure while shieldbearer occupies attention |

## Tests Updated

`tools/DemoSmokeTest.gd` now verifies:

- DAY 13 campaign data loads.
- `shieldbearer` enemy data is registered.
- Shieldbearer idle sprite exists.
- DAY 12 advances to DAY 13 instead of stopping at missing wave.
- DAY 13 blocks the second promotion with `promotion_limit: 1`.
- DAY 13 wave starts and schedules 7 total enemies.
- Shieldbearer spawns with target room.
- Shieldbearer has idle/move/attack/skill animation frame counts.
- Shieldbearer has `down` animation frames and the down sprite resource exists.
- Shieldbearer is slower than explorer and has higher defense than investigator.
- Result lines include `shieldbearer_class` and `second_promotion_deferred`.
- DAY 14 still blocks the second promotion through the DAY23 default limit.
- DAY 14 remains blocked because no wave has been implemented yet.

`tools/BalanceSimulation.gd` now includes:

- `DAY13_SHIELDBEARER_SLIME`
- `DAY13_SHIELDBEARER_GOBLIN`
- `DAY13_SHIELDBEARER_IMP`

## Verification

Passed:

```powershell
python -m json.tool data\campaign_days.json > $null; python -m json.tool data\waves.json > $null; python -m json.tool data\enemies.json > $null; python -m json.tool data\evolution_rules.json > $null
godot --headless --path . --import --quit-after 1
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --headless --path . --run res://tools/CharacterDataSmokeTest.tscn
godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
git diff --check
```

Balance results:

| Scenario | Result | Time | Throne HP | Monster Down | Enemies | Thief |
|---|---|---:|---:|---:|---:|---|
| DAY12_FIRST_PROMOTION_SLIME | WIN | 82.7s | 1500 | 1 | 8/8 | reached N, stole N |
| DAY12_FIRST_PROMOTION_GOBLIN | WIN | 78.1s | 1500 | 1 | 8/8 | reached N, stole N |
| DAY12_FIRST_PROMOTION_IMP | WIN | 76.5s | 1500 | 1 | 8/8 | reached N, stole N |
| DAY13_SHIELDBEARER_SLIME | WIN | 86.1s | 1500 | 1 | 7/7 | reached N, stole N |
| DAY13_SHIELDBEARER_GOBLIN | WIN | 76.1s | 1500 | 1 | 7/7 | reached N, stole N |
| DAY13_SHIELDBEARER_IMP | WIN | 75.9s | 1500 | 1 | 7/7 | reached N, stole N |

Note:

- `godot --headless --path . --script ...` fails in this project because autoload singletons are not reliably available in that mode. Use `.tscn` runners with `--run`.
- `git diff --check` passed with only line-ending warnings.

## Review Status

Review agent `Beauvoir` found two issues:

- DAY 14+ would lose the promotion limit because those dates do not yet have campaign data.
- The shieldbearer `down` animation was documented as required but not covered by the smoke test.

Fixes applied:

- Added `SECOND_PROMOTION_UNLOCK_DAY = 23` and made `_promotion_limit_for_current_day()` default to 1 while promotions are unlocked but DAY is before 23.
- Extended `DemoSmokeTest` to assert DAY 14 still blocks a second promotion.
- Extended `DemoSmokeTest` to assert the shieldbearer down sprite resource and `down` animation frame count.

Post-fix verification:

```powershell
python -m json.tool data\campaign_days.json > $null; python -m json.tool data\waves.json > $null; python -m json.tool data\enemies.json > $null; python -m json.tool data\evolution_rules.json > $null
git diff --check
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY13_SHIELDBEARER_SLIME
godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY13_SHIELDBEARER_GOBLIN
godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY13_SHIELDBEARER_IMP
```

All passed. `git diff --check` only printed line-ending warnings.

## Next Work

Recommended next slice: DAY 14 Stage 02 upgrade review.

Do:

- Keep `promotion_limit: 1` through DAY 15 unless there is an explicit design change.
- Implement DAY 14 as castle upgrade/resource-prep, not another promotion day.
- Decide whether DAY 14 should add upgrade cost gating or only a review/event gate.
- If adding Stage 02 visuals, follow the quarantine/proof rules in the map handoff before slicing runtime assets.
- Carry over the shieldbearer as a possible repeat enemy only if DAY 14/15 needs role pressure; do not overuse it immediately.
