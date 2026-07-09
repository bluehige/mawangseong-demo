# Handoff: DAY 12 First Monster Promotion

Date: 2026-07-09

## Summary

DAY 12 now implements the first playable monster evolution slice from the evolution reference plan.

Decision from `docs/design/EVOLUTION_SYSTEM_REFERENCE_OPTIONS_2026-07-07.md`:

- Use promotion-style evolution first.
- Do not start branching evolution or fusion yet.
- Keep existing monster combat forms and provide strong UI feedback through badges.
- Balance chapter 2 around one promoted monster first, not around direct enemy level scaling.

DAY 12 is therefore a first-promotion choice among the three current defense monsters:

| Monster | Promotion | Role | Balance Purpose |
|---|---|---|---|
| `slime` | `slime_gate_bulwark` / 성문 방벽 푸딩 | `blocker` | Stable front-line choice. |
| `goblin` | `goblin_ambush_captain` / 매복대장 고브 | `chaser` | Treasure/thief pressure answer. |
| `imp` | `imp_flame_adept` / 화염 숙련자 핀 | `caster` | Investigator/explorer cleanup. |

Rolo / `kobold_scout` remains scout/raid support only.

## Data Changes

- `data/evolution_rules.json`
  - New file.
  - Defines one stage-1 promotion for `slime`, `goblin`, and `imp`.
  - Requirements: level 3, DAY 12 unlock, `campaign_chapter_two_started`, gold/mana/infamy cost.
  - Effects: stat multipliers/bonuses, role tag, and one real skill-upgrade modifier per promotion.
- `data/campaign_days.json`
  - Added `day_12`.
  - Added `promotion_unlocked`, `requires_first_promotion`, and `first_promotion_limit`.
  - DAY 12 blocks combat until one promotion is complete.
  - DAY 12 limits the player to one first promotion for the day.
- `data/waves.json`
  - Added `day_12`.
  - Wave budget: explorer x4, investigator x1, thief x2, weak trainee_hero x1.
  - Tuned for one promoted monster, not for three promoted monsters.

## Runtime Changes

- `scripts/core/DataRegistry.gd`
  - Loads `data/evolution_rules.json`.
  - Adds `evolution_rule(rule_id)`.
- `scripts/game/GameRoot.gd`
  - Adds promotion state and helpers.
  - Applies promotion stat multipliers/bonuses in `_scaled_monster_stats()`.
  - Replaces displayed monster name and combat `role` with promoted name/role tag when promoted.
  - Blocks DAY 12 combat until first promotion is complete.
  - Blocks extra DAY 12 promotions after the first one.
  - Exposes skill-upgrade lookup helpers for combat.
- `scripts/game/CombatSceneController.gd`
  - Applies promoted skill-upgrade values in the real skill paths:
    - `slime_shield`: longer duration and stronger damage reduction.
    - `quick_slash`: higher damage multiplier.
    - `fireball`: higher damage and longer targeting range.
- `scripts/game/ManagementSceneController.gd`
  - Adds promotion badge/summary/button to monster management.
  - Shows promoted names and role tags.
  - Keeps Rolo excluded from normal monster management.
- `scripts/ui/HUDController.gd`
  - Uses promoted scaled stats in the monster stat list.
  - Tightened monster stat spacing so training and promotion controls do not overlap.

## Asset Changes

Promotion UI badges were generated and imported:

- `assets/sprites/ui/evolution/badge_slime_gate_bulwark.png`
- `assets/sprites/ui/evolution/badge_goblin_ambush_captain.png`
- `assets/sprites/ui/evolution/badge_imp_flame_adept.png`
- `.png.import` files for all three.
- Source note: `assets/sprites/ui/evolution/SOURCE.md`
- Generator: `tools/generate_evolution_badges.py`

No full evolved combat sprite sheets were generated in this pass. That is intentional. The first playable scope keeps monster forms intact and uses badges plus promoted names/roles for feedback.

## Test Changes

- `tools/DemoSmokeTest.gd`
  - Extends campaign progression through DAY 12.
  - Verifies DAY 12 blocks combat before first promotion.
  - Verifies training once can bring Pudding to Lv.3 in the DAY 11 -> DAY 12 flow.
  - Verifies promotion cost, ID, stage, role tag, stats, duplicate prevention, result line, and DAY 13 no-wave block.
  - Adds a promotion-choice matrix for all three promotions.
  - Uses promoted units in combat and verifies actual skill-upgrade behavior, not only data lookup.
- `tools/BalanceSimulation.gd`
  - Adds:
    - `DAY12_FIRST_PROMOTION`
    - `DAY12_FIRST_PROMOTION_SLIME`
    - `DAY12_FIRST_PROMOTION_GOBLIN`
    - `DAY12_FIRST_PROMOTION_IMP`

## Balance Results

Regular campaign setup:

- Slime/Goblin/Imp start at Lv.2 except the promoted choice, which is set to Lv.3 for the scenario.
- DAY 07 barracks Lv.2 upgrade is present.
- Watch post is built in `slot_01`.
- Active skills are used by the simulation helper.

Measured results after final tuning:

| Scenario | Result | Time | Monster Down | Enemies | Thief Reached | Thief Stole |
|---|---:|---:|---:|---:|---:|---:|
| `DAY11_KINGDOM_NOTICE` | WIN | 87.7s | 2 | 7/7 | N | N |
| `DAY12_FIRST_PROMOTION` | WIN | 82.7s | 1 | 8/8 | N | N |
| `DAY12_FIRST_PROMOTION_SLIME` | WIN | 82.7s | 1 | 8/8 | N | N |
| `DAY12_FIRST_PROMOTION_GOBLIN` | WIN | 78.1s | 1 | 8/8 | N | N |
| `DAY12_FIRST_PROMOTION_IMP` | WIN | 76.5s | 1 | 8/8 | N | N |

Interpretation:

- All three first-promotion choices are viable.
- No DAY 12 run allowed thief treasure contact.
- DAY 12 is a first-promotion teaching day, not a punishment spike.

## Verification

Passed:

- `python -m json.tool data/evolution_rules.json`
- `python -m json.tool data/campaign_days.json`
- `python -m json.tool data/waves.json`
- `git diff --check`
- `godot --headless --path . --import --quit-after 1`
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`
- `godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn`
- `godot --headless --path . --run res://tools/CharacterDataSmokeTest.tscn`
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`
- `godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY11_KINGDOM_NOTICE`
- `godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY12_FIRST_PROMOTION`
- `godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY12_FIRST_PROMOTION_SLIME`
- `godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY12_FIRST_PROMOTION_GOBLIN`
- `godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY12_FIRST_PROMOTION_IMP`

Review agent loop:

- First review found missing real skill-upgrade effect, missing DAY12 promotion gate, missing non-slime coverage, and UI overlap.
- Second review found skill-upgrade tests only checked data and combat role tag did not reach the selected-unit panel.
- Both were fixed.
- Final review result: `No findings`.

## Next Recommended Work

1. DAY 13 should decide when the second promotion becomes available. Do not silently allow multiple promotions on DAY 12; the current day intentionally limits the first choice to one monster.
2. Add the next enemy role only after choosing what it counters:
   - anti-blocker if Slime promotion becomes dominant,
   - anti-chaser or decoy if Goblin promotion trivializes thieves,
   - fire-resistant or ranged-pressure unit if Imp promotion dominates.
3. If adding a spawned enemy class, produce/import combat sprites and add smoke assertions before tuning waves.
4. Full branching evolution should remain deferred until catalyst/material inventory and branch UI are scoped.
5. Full evolved monster combat sprite sheets are not required for this promotion-style pass, but should be planned before branch evolution.
