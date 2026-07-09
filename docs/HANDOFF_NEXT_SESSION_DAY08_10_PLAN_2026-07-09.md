# Handoff: Next Session DAY 08-10 Plan

Date: 2026-07-09

Implementation note:

- This plan has been executed. See `docs/HANDOFF_DAY08_10_CAMPAIGN_INVESTIGATOR_ASSETS_2026-07-09.md` for the completed DAY 08-10 implementation, generated investigator assets, balance results, and verification status.

## Current Baseline

Read these first, in this order:

1. `docs/HANDOFF_DAY05_07_CAMPAIGN_AND_ASSETS_2026-07-09.md`
2. `data/monsters.json`
3. `data/enemies.json`
4. `data/campaign_days.json`
5. `data/waves.json`
6. `data/raid_missions.json`
7. `data/characters.json`
8. `data/skills.json`
9. `scripts/game/GameRoot.gd`
10. `scripts/game/ManagementSceneController.gd`
11. `scripts/game/CombatSceneController.gd`
12. `scripts/ui/HUDController.gd`
13. `tools/DemoSmokeTest.gd`
14. `tools/CharacterDataSmokeTest.gd`
15. `tools/BalanceSimulation.gd`

DAY 05-07 is now the working baseline:

- DAY 05 is explorer-only defense pressure.
- `d05_supply_tag` is available on DAY 05, but its `supply_suspicion` modifier has `apply_on_day = 6`.
- DAY 06 reintroduces Nia/thieves and shows actual treasure loss in the result screen.
- DAY 07 unlocks one Lv.2 facility upgrade.
- Campaign notices render cast portraits from `data/campaign_days.json`.
- This planning handoff has been superseded by the completed implementation handoff. Use `docs/HANDOFF_DAY08_10_CAMPAIGN_INVESTIGATOR_ASSETS_2026-07-09.md` for current verification and review status.

## Next Goal

Implement DAY 08-10 as the end of chapter 1:

- DAY 08: monster growth preview and next-growth tease.
- DAY 09: investigator / mixed-role pressure so placement choices matter more.
- DAY 10: first chapter boss/event, guild-board incident, and Stage 02 preparation flag or notice.

Do not try to build the whole long-term evolution or Stage 02 visual system in one pass. The goal is a playable, testable chapter-1 closure.

## Mandatory Expanded Scope

The next pass must not be a text-only story continuation. It needs to cover content, systems, balance, and art together:

- Additional monster audit: existing playable monster data is `slime` / Pudding, `goblin` / Gob, `imp` / Pynn, and `kobold_scout` / Rolo. Rolo is already the first extra monster data entry, but he currently needs a defense-combat asset check before being used as a normal deployed defender.
- Additional monster decision: DAY 08 must explicitly decide whether Rolo joins the defense/growth story, stays raid-support only, or whether a new monster is truly needed. If a new monster is added, add the full chain in the same pass: `data/monsters.json`, `data/characters.json`, unlock/roster code, portrait, combat sprite assets, imports, and tests.
- Story line: DAY 08 growth preview, DAY 09 kingdom investigation, and DAY 10 guild-board/chapter boss must read as one connected story line. Do not add monsters or enemies as isolated data rows without campaign-day cast lines and result/notice text.
- Enemy class addition: add at least one real new enemy class for this bundle. The recommended minimum is `investigator` on DAY 09, with its own `data/enemies.json` entry, character profile, portrait, wave usage, and combat sprite/fallback plan. Do not merely rename `explorer` in story text and call that complete.
- Balance confirmation: every new monster/enemy must have a wave budget and a target difficulty before implementation, then smoke/balance verification after implementation.
- Graphics production: every newly visible named character or spawned class needs an asset decision. Portrait-only story characters need portraits and `data/characters.json` registration. Spawned combat classes need enemy/monster sprites imported and verified in Godot.

## Plan Table

| Order | Day | Player-Facing Goal | Implementation Work | Assets | Exit Criteria |
|---:|---:|---|---|---|---|
| 1 | 08 | The player sees that monster growth is becoming a real system, not just result text. | Add DAY 08 entry to `data/campaign_days.json`; add `day_8` waves; audit Pudding/Gob/Pynn/Rolo roles; decide whether `kobold_scout` becomes a deployed defender or remains raid-support; add a growth-preview notice/panel only as far as it is tested. | Check Pudding/Gob/Pynn/Rolo portrait variants. If Rolo appears in defense combat, verify/generate combat animation frames beyond idle or add a documented fallback. | DAY 08 management shows growth/monster timing; combat starts and ends; smoke test asserts data load, cast, wave, and any monster unlock/fallback decision. |
| 2 | 09 | The kingdom starts investigating, so mixed enemy roles force better room/facility placement. | Add DAY 09 entry and `day_9` waves; add a real `investigator` enemy class to `data/enemies.json`; wire character metadata and wave usage; keep the first class mechanically simple unless tests cover a special behavior. | Generate/register investigator portrait. Generate/import enemy combat sprite set or implement a deliberate sprite fallback and document it. | DAY 09 wave includes `investigator`; no DAY 05/06/07 regressions; tests verify enemy class data, spawn, route, and result progression. |
| 3 | 10 | Chapter 1 closes with the guild-board incident and a stronger fight. | Add DAY 10 entry and `day_10` wave; decide whether the climax uses existing `trainee_hero` or a second new class such as `guild_champion` / `chapter_boss`; add chapter-clear result line/flag and Stage 02 preparation notice. | Generate guild-board/chapter-boss portrait only if shown. If adding a new boss class, generate/import combat sprite assets and register character data. | DAY 10 result marks chapter clear/prep; next screen returns to management cleanly; smoke test asserts chapter flag/notice and boss/enemy roster. |
| 4 | 08-10 | Balance is checked before and after content changes. | Define wave budgets before coding; extend `DemoSmokeTest` and, if practical, `BalanceSimulation` scenarios for DAY 08-10. | No new art in this row; it validates the assets/classes added above. | DAY 08 is a moderate growth-read day, DAY 09 is mixed-role pressure, DAY 10 is a harder but winnable chapter close. |
| 5 | 08-10 | Keep the loop coherent. | Extend `DemoSmokeTest` with DAY 08-10 progression checks; add targeted assertions for data, waves, chapter flag, new enemy class, and any new UI button/state. | Import any generated PNGs with Godot so `.import` files are present. | `DemoSmokeTest`, `TutorialFlowSmokeTest`, `QuarterModuleSmokeTest`, `CharacterDataSmokeTest`, `git diff --check` pass. |
| 6 | 08-10 | Leave the next session clean. | Update or add a DAY 08-10 handoff after implementation. | Record generated image source folder and project copy paths. | Run review agent, fix findings, rerun review until `No findings`. |

## Suggested DAY Details

### DAY 08: Growth Preview

Purpose:

- Make the player understand that monsters will continue to grow after the first week.
- Keep it as a preview or lightweight unlock, unless the implementation is already simple and well covered.

Suggested cast:

- Pudding / slime: growth concern or brave reaction.
- Gob: eager reaction.
- Pynn: caster pride or teasing.
- Rolo / kobold_scout: scout support or "not ready for defense deployment yet" explanation.
- Goldin: cost/resource reminder if growth has a resource cost.

Suggested enemy balance:

- Mostly explorers, one thief late only if the growth preview needs a treasure-pressure reminder.
- Target budget: 5-6 total enemies, close to DAY 07 pressure but not sharply higher.
- Target result: winnable without perfect manual control; no more than 1-2 monsters down in the expected setup.

Implementation notes:

- Extend `data/campaign_days.json` first.
- If adding a growth preview panel, keep it read-only unless a real upgrade action is implemented and tested.
- Reuse existing `last_growth_summary` / result-growth concepts where possible.
- Check whether `kobold_scout` has enough combat animation frames before putting Rolo into normal defense combat. If not, either generate the missing frames or keep him as story/raid support and record that decision.
- If a brand-new monster is introduced instead of Rolo, do not stop at data. Add character metadata, unlock flow, portrait, combat sprite assets, import files, and tests in the same bundle.

### DAY 09: Investigator Pressure

Purpose:

- The outside world begins to respond intelligently.
- The player should need a coherent route/facility setup, not just raw stats.

Suggested cast:

- A new named investigator character backed by a real `investigator` enemy class.
- Milo can appear as supporting explorer commentary, but should not replace the new class.
- Bati explains that the enemy is mapping the castle.

Suggested enemy balance:

- Explorer front group.
- One `investigator` in the middle window to make this day distinct.
- Thief pressure after the player is committed.
- Optional trainee hero / stronger explorer as a late probe if balance allows.
- Target budget: 5-7 total enemies, with only one new-class enemy at first.
- Target result: 70-95 seconds if automated; treasure loss possible but not guaranteed.

Implementation notes:

- First inspect `data/enemies.json` and existing enemy sprites.
- Add `investigator` to `data/enemies.json` with a distinct stat profile. Suggested first pass: throne target, HP slightly above explorer, ATK near explorer or lower, morale above explorer, move speed between explorer and trainee hero.
- Add a `CHR_INVESTIGATOR_*` entry to `data/characters.json` with generation profile and portrait paths.
- If the first implementation uses an existing sprite as a temporary fallback, the fallback must be explicit in the handoff and covered by a spawn/render check. Prefer generating the new enemy sprite set in the same pass.

### DAY 10: Guild Board Incident

Purpose:

- Close chapter 1 with a clear event: the castle name appears on the guild board.
- Prepare Stage 02 without switching visual stage unless approved runtime assets are ready.

Suggested cast:

- Bati: official warning / dry summary.
- Goldin: reward and cost reaction.
- Nia: optional rival commentary if the treasure-pressure thread continues.
- Leon or trainee hero: boss/rival pressure if reusing existing assets.
- New guild-board or boss representative if a second new enemy class is added.

Suggested enemy balance:

- Mixed wave, then a stronger `trainee_hero` or chapter boss entry.
- If DAY 09 already added `investigator`, DAY 10 can reuse `trainee_hero` for scope control. If adding a `guild_champion` / `chapter_boss` class, generate the full data/art/test chain.
- Use `hp_scale` and `atk_scale` before adding new boss mechanics.
- Target budget: 6-8 total enemies, one clear climax unit, 90-120 seconds target, winnable without ending the whole game.

Implementation notes:

- Add a chapter-clear or chapter-prep flag in `GameRoot.gd` only if it is used by UI/tests.
- Result UI can show a chapter-clear line through `result_summary` or campaign day data.
- Do not mark `GameState.victory` for DAY 10 unless the whole game should stop. Keep regular campaign continuation clean.

## Balance Checklist

Before implementing each day, write the intended budget into the day data or handoff:

- DAY 08: growth-read day. Similar to DAY 07, not a sudden spike. Prefer 5-6 enemies and no more than one thief.
- DAY 09: new-class teaching day. Add one `investigator`, then support it with explorers/thieves. Do not also add a boss spike unless the test proves it is still winnable.
- DAY 10: chapter close. Strongest fight of this bundle, but it should end with continuation/prep, not a full game victory state.

After implementation, confirm:

- Each new class spawns and routes to the intended goal room.
- `thief` treasure loss still reports the actual stolen amount.
- Added monster roster/unlock state does not break DAY 01-07 tests.
- Result/notice text explains why the new monster or enemy appears at that point in the story.

## Asset Rules

- For new cast portraits, use built-in image generation and copy outputs into `assets/sprites/portraits/onboarding/`.
- Run `godot --headless --path . --import --quit-after 1` after adding PNGs.
- Register portrait variants in `data/characters.json`.
- New combat enemy sprites are required when a new spawned enemy class is added, unless a temporary fallback is explicitly implemented, tested, and documented.
- Current combat sprite naming convention uses prefixes such as `enemy_explorer_idle_down_00.png`, `enemy_explorer_move_down_00.png`, `enemy_explorer_attack_down_00.png`, `enemy_explorer_skill_down_00.png`, and `enemy_explorer_down_00.png`. Mirror that convention for `investigator` or any boss class so the loader can find frames.
- If Rolo / `kobold_scout` becomes a normal deployed defender, verify whether `monster_kobold_scout_*` has enough idle/move/attack/skill/down frames. Generate the missing frames or keep Rolo out of defense combat.
- New monster additions must include both portrait assets and combat assets. Do not add a roster entry that points to a missing sprite.
- Record generated source folder and project copy paths in the handoff.

## Verification Commands

Run at minimum:

```powershell
python -m json.tool data\campaign_days.json > $null
python -m json.tool data\monsters.json > $null
python -m json.tool data\enemies.json > $null
python -m json.tool data\waves.json > $null
python -m json.tool data\raid_missions.json > $null
python -m json.tool data\characters.json > $null
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/CharacterDataSmokeTest.tscn
git diff --check
```

If DAY 08-10 balance scenarios are added to `tools/BalanceSimulation.gd`, also run the new balance scenarios and record the time / monster-down / enemy-down results in the implementation handoff.

Then run a review agent. Fix every actionable finding and rerun review until it passes.

## Do Not Break

- DAY 03 tutorial victory must still route to DAY 04 raid preview.
- DAY 04+ regular campaign wins must advance to the next management day.
- DAY 05 follow-up raid modifier must not add thieves to DAY 05 defense.
- DAY 07 facility upgrade must remain one Lv.2 upgrade with cost `gold 90 / mana 30`, unless a larger upgrade system is explicitly implemented and tested.
- New enemy class work must not silently reuse `explorer` while claiming a new class exists. The data/test path must prove the new class exists.
- New monster work must not leave missing sprites or unregistered portraits.
- Do not revert unrelated dirty worktree changes.

## Exact Start Sentence For Next Session

This section is historical. DAY 08-10 has been implemented, so do not use the original start sentence as the current task. Start from the completed implementation handoff instead:

> 최신 핸드오프는 `docs/HANDOFF_DAY08_10_CAMPAIGN_INVESTIGATOR_ASSETS_2026-07-09.md`입니다. DAY 08-10 구현은 완료되었고, 다음 작업은 해당 문서의 Review Status와 Next Recommended Work를 기준으로 이어가면 됩니다.

Additional required start note:

> 추가 몬스터/스토리/밸런스/적 클래스/그래픽 리소스 요구사항은 DAY 08-10 구현 핸드오프에 반영되어 있습니다. 다음에는 DAY 11 이후 콘텐츠와 Stage 02 준비 범위를 새로 잡으세요.
