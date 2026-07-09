# Handoff: DAY 15 Selen Boss / Stage 02 Unlock Gate (2026-07-09)

## Summary

DAY 15 is now implemented as the Chapter 2 boss slice:

- New boss enemy: `selen_trainee_paladin` / `성기사 견습 셀렌`.
- New character metadata: `CHR_SELEN`.
- New DAY 15 campaign data and wave.
- Stage 02 unlock gate now requires both:
  - DAY 14 funded flag: `campaign_stage_two_upgrade_funded`.
  - Current resources still meeting the Stage 02 review budget: `gold 720 / infamy 720`.
- DAY 15 victory sets `campaign_stage_two_unlock_ready`.
- Stage 02 visuals are still not switched. The current result is only an unlock-ready flag.
- Second promotion remains locked. DAY 15 is balanced around exactly one first promotion.

## Files Changed

Core data:

- `data/campaign_days.json`
  - Adds `day_15`.
  - Marks `requires_stage_two_upgrade_funded: true`.
  - Marks `stage_two_unlock_review: true`.
  - Keeps `promotion_limit: 1`.
  - Records evolution reference and second-promotion deferral.
- `data/waves.json`
  - Adds `day_15` wave:
    - explorer x2
    - investigator x1
    - shieldbearer x1
    - thief x1
    - selen_trainee_paladin x1
- `data/enemies.json`
  - Adds `selen_trainee_paladin`.
- `data/characters.json`
  - Adds `CHR_SELEN`, linked to `selen_trainee_paladin`.

Runtime:

- `scripts/game/GameRoot.gd`
  - Adds `campaign_stage_two_unlock_ready`.
  - Adds `_stage_two_upgrade_budget_ready()`.
  - DAY 15 combat start now blocks if the funded flag is missing or current `gold/infamy` no longer meet the Stage 02 cost.
  - DAY 15 result line is dynamic:
    - ready: `stage_two_unlock_ready`
    - blocked: `stage_two_unlock_blocked`

Tests and tools:

- `tools/DemoSmokeTest.gd`
  - Validates DAY 15 campaign data, Selen enemy/character/assets, Stage 02 cost gate, actual Selen wave HP > explorer wave HP, result flag, and DAY 16 no-wave block.
- `tools/CharacterDataSmokeTest.gd`
  - Adds `CHR_SELEN` to required character validation.
- `tools/BalanceSimulation.gd`
  - Adds:
    - `DAY15_SELEN_BOSS_SLIME`
    - `DAY15_SELEN_BOSS_GOBLIN`
    - `DAY15_SELEN_BOSS_IMP`
  - DAY 15 setup now includes enough gold/infamy to pay first promotion, build watch post, and still meet Stage 02 budget.

Assets:

- `assets/source/imagegen/selen/CHR_SELEN_design_sheet_imagegen.png`
- `assets/source/imagegen/selen/SOURCE.md`
- `tools/generate_selen_paladin_assets.py`
- `assets/sprites/enemies/SOURCE_SELEN_PALADIN.md`
- `assets/sprites/enemies/enemy_selen_paladin_*.png`
- `assets/sprites/enemies/enemy_selen_paladin_*.png.import`
- `assets/sprites/portraits/onboarding/CHR_SELEN_portrait_checklist.png`
- `assets/sprites/portraits/onboarding/CHR_SELEN_portrait_checklist.png.import`

Selen design source was generated with the built-in `image_gen` tool and copied into the workspace. The runtime portrait is cropped from that imagegen sheet. The 192px combat frames are simplified runtime sprites derived from the same design direction, not the authoritative design source. Stage 02 room/castle visual proof assets are still governed by the imagegen/approval contract and were not touched.

## Balance Results

Final DAY 15 balance after review fixes:

| Scenario | Result | Time | Throne HP | Monster Down | Enemies | Thief | Stage 02 |
|---|---:|---:|---:|---:|---:|---:|---:|
| DAY15_SELEN_BOSS_SLIME | WIN | 89.4s | 1500 | 1 | 6/6 | no reach / no steal | unlock ready |
| DAY15_SELEN_BOSS_GOBLIN | WIN | 73.7s | 1500 | 1 | 6/6 | no reach / no steal | unlock ready |
| DAY15_SELEN_BOSS_IMP | WIN | 75.4s | 1500 | 1 | 6/6 | no reach / no steal | unlock ready |

Selen practical DAY 15 HP is higher than the DAY 15 explorer practical HP:

- explorer: `90 * 4.1 = 369`
- Selen: `360 * 1.12 = 403`

## Verification

Passed:

```powershell
python -m json.tool data\campaign_days.json > $null; python -m json.tool data\waves.json > $null; python -m json.tool data\enemies.json > $null; python -m json.tool data\characters.json > $null; python -m json.tool data\evolution_rules.json > $null
git diff --check
godot --headless --path . --import --quit-after 1
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --headless --path . --run res://tools/CharacterDataSmokeTest.tscn
godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY15_SELEN_BOSS_SLIME
godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY15_SELEN_BOSS_GOBLIN
godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY15_SELEN_BOSS_IMP
```

`git diff --check` only reported existing line-ending warnings.

Imagegen correction re-check, after replacing the Selen portrait source with a
built-in `image_gen` design sheet, also passed on 2026-07-09:

```powershell
python -m json.tool data\campaign_days.json > $null
python -m json.tool data\characters.json > $null
python -m json.tool data\enemies.json > $null
python -m json.tool data\waves.json > $null
git diff --check
godot --headless --path . --run res://tools/CharacterDataSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY15_SELEN_BOSS_SLIME
godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY15_SELEN_BOSS_GOBLIN
godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --scenario=DAY15_SELEN_BOSS_IMP
```

## Review Loop

First review agent findings:

1. DAY 15 gate only checked the prior funded flag, not current resource budget.
2. DAY 15 balance simulation forced the funded flag while resources were below `720/720`.
3. Selen practical HP was lower than DAY 15 explorer practical HP.

Fixes applied:

1. Added `_stage_two_upgrade_budget_ready()` and used it for combat start, result flagging, and result lines.
2. Raised DAY 15 balance setup resources and sets the funded flag only when `GameState.can_pay(game._stage_two_upgrade_cost())` is true after promotion.
3. Raised Selen DAY 15 wave scaling to `hp_scale 1.12`, `atk_scale 0.42`, and added a smoke assertion that practical Selen HP is higher than practical explorer HP.

Pre-imagegen-correction re-review status:

- Final review agent result: `No findings`.
- Remaining risk: the re-review was static, while runtime validation is covered by the commands listed above.

Imagegen correction re-review:

- Review agent result: Selen source correction is valid.
- Confirmed by review:
  - Workspace design source matches the recorded built-in `image_gen` output.
  - `CHR_SELEN` portrait visually matches the source sheet crop.
  - `tools/generate_selen_paladin_assets.py` writes combat frames only and does
    not overwrite the portrait.
  - DAY 15 gate, victory flag, promotion lock, and smoke/balance coverage are
    adequate.
- Residual risk: provenance/crop is verified statically and visually, not by an
  automated image comparison test.
- Follow-up handoff-doc fixes were re-reviewed after stale next-work text was
  replaced with DAY16 guidance. Final review agent result: `No findings`.

## Next Work Plan

Recommended next slice: DAY 16 regional supply route expedition.

Order:

1. DAY 16: add one or two Stage 02 unlock follow-up management lines and a new regional supply route raid choice.
2. Keep Stage 02 visual switch deferred unless approved runtime room/path assets are ready.
3. Do not unlock second promotion before DAY 23.
4. Add only one new pressure concept at a time:
   - preferred DAY 16 focus: expedition choice affects next defense resources or enemy composition.
   - defer new full boss class until DAY 20.
5. If adding a new DAY 16 enemy or NPC, include character/enemy data, sprite/portrait assets, import files, smoke test, balance simulation, review agent pass, and this handoff update pattern.

Forward-looking chapter plan:

| Day | Focus | Notes |
|---:|---|---|
| 16 | Regional supply route expedition | Choice/reward/risk, no second promotion |
| 17 | Nia advanced theft pressure | Treasure defense and watch post value |
| 18 | Monster role specialization reminder | First-promotion roles remain the main player choice |
| 19 | Kingdom supply pressure | Resource risk, longer defense prep |
| 20 | Chapter 3 boss candidate Roman | Add boss only with full data/assets/tests |
