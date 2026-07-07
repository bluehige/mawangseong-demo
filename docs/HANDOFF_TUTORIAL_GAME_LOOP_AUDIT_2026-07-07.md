# Handoff: Tutorial Gameplay Loop Audit (2026-07-07)

This file is the required next-session handoff for checking and continuing the tutorial gameplay loop. Read it before adding tutorial help text, changing combat balance, or claiming the tutorial is complete.

## Mandatory Session Compass

We are building a playable Demon King castle dungeon demo, not a decorative background. The dungeon must be assembled from quarter-view cells, floor tiles, wall/edge/door rules, room-role objects, and walkable cell data. The immediate gameplay goal is to make the tutorial loop play as a real game loop: prepare the dungeon, deploy monsters, fight, settle rewards and growth, progress events, then enter the next battle.

Beginner translation: the tutorial is not complete just because dialogue screens advance. The player must experience the full defend-grow-repeat loop.

## Handoff Writing Rule

Every next-session handoff must preserve:

1. current goal and latest decision,
2. files changed this session,
3. completed or verified features,
4. commands run and verification results,
5. unfinished or deferred items,
6. first task for the next session,
7. risks and files not to disturb,
8. exact start sentence for the next session.

## Current Goal And Latest Decision

The user asked whether these seven tutorial gameplay requirements are actually covered:

1. pre-combat dungeon composition,
2. pre-combat troop deployment,
3. monster level-up and skill check,
4. combat fun,
5. post-combat settlement and growth,
6. event progression,
7. next battle.

Latest decision:

- Do not move on to tutorial help text yet.
- Fix combat pacing/resolution first, because DAY1 and DAY2 representative balance simulations can time out at 120 seconds without killing enemies.
- After combat pacing is fixed, add clearer post-combat monster growth presentation and a tutorial step that explicitly teaches level/EXP/skills.

## Files Changed This Session

- `docs/HANDOFF_TUTORIAL_GAME_LOOP_AUDIT_2026-07-07.md`
- `docs/HANDOFF_MAP_CUSTOM_CURRENT_2026-07-03.md`

No gameplay code, data balance, scenes, or assets were changed in this documentation pass.

## Current Object-System Status

- The dungeon object/path system is still data-first.
- Default and edited layouts are verified through Godot probes, not by static background images.
- The current map/editor system supports room/path layout validation, protected `entrance -> throne` route repair at save/combat/day boundaries, user-authored path modules, path-end connection, and socket-pair preview overlays.
- Production-approved graphics for some path-mouth/exterior/room-object variants remain pending, but that is separate from the tutorial gameplay-loop audit.

## Seven-Point Tutorial Audit

| Requirement | Status | Evidence | Gap |
|---|---|---|---|
| 1. Pre-combat dungeon composition | Partial | Quarter module, room path, role route, map editor, and default dungeon probes pass. | Tutorial mostly uses the default dungeon. It does not yet make the player actively compose/build the dungeon as a required tutorial action. |
| 2. Pre-combat troop deployment | Near complete | Initial roster has slime, goblin, and imp; room assignment and tutorial gates are verified. | Needs final UX polish only if the user wants a clearer placement lesson. |
| 3. Monster level-up and skill check | Partial | Monster UI shows level/EXP/stats/skills. Training can add EXP and level up. Combat skill use exists and is tested. | Battle EXP accumulates, but post-battle automatic level-up/conversion and visible growth settlement are weak. Tutorial teaches skill use more than growth review. |
| 4. Combat fun | Not complete | Core combat features exist: auto combat, direct control, directives, skills, traps, projectiles, logs. | Representative DAY1 and DAY2 balance simulations timed out at 120 seconds with zero enemy kills, so pacing and resolution are not acceptable yet. |
| 5. Post-combat settlement and growth | Partial | Result screen and reward application exist; gold/mana/infamy/reward lines are handled. | Monster EXP/level growth is not presented strongly enough, and there is no satisfying growth choice or level-up result beat. |
| 6. Event progression | Partial | Onboarding dialogue/event triggers exist for management, battle, result, traps, boss thresholds, low HP, treasure, and retreat beats. | General data-driven event system is not implemented yet; `scripts/systems/events` and `data/regular_version/events` are still placeholder folders. |
| 7. Next battle | Near complete for demo | DAY1 -> DAY2 -> DAY3 -> DAY4 raid preview progression is verified by onboarding/tutorial smoke tests. | Regular campaign continuation after DAY4 preview is outside the current demo loop. |

## Verification Results Already Observed

Flow and structure checks passed:

```powershell
godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn
godot --headless --path . --run res://tools/OnboardingFlowSmokeTest.tscn
godot --headless --path . --run res://tools/RoleCombatLayoutProbe.tscn
godot --headless --path . --run res://tools/RoomPathAuthoringProbe.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
```

Observed results:

- `TUTORIAL_FLOW_SMOKE_TEST: PASS`
- `ONBOARDING_FLOW_SMOKE_TEST: PASS`
- `ROLE_COMBAT_LAYOUT_PROBE: PASS`
- `ROOM_PATH_AUTHORING_PROBE: PASS`
- `DEMO_SMOKE_TEST: PASS`
- `QUARTER_MODULE_SMOKE_TEST: PASS`

Representative balance checks revealed the critical problem:

```text
DAY1_AUTO: TIMEOUT at 120.0s, enemy_down 0/2
DAY2_TRAP_DIRECTIVE: TIMEOUT at 120.0s, enemy_down 0/3
DAY3_ASSISTED: WIN at 119.9s, enemy_down 5/5
```

The full `BalanceSimulation` run timed out at 180 seconds because the scenario tool can simulate up to 120 seconds per scenario across multiple scenarios.

## Important Code Areas To Inspect Next

- `scripts/game/GameRoot.gd`
  - `_init_roster`
  - `_start_combat`
  - `_continue_from_result`
  - `_advance_day_from_management`
  - `_train_selected_monster`
  - `_assign_monster_to_room`
  - `_use_selected_skill`
  - onboarding battle/result hooks
- `scripts/game/CombatSceneController.gd`
  - enemy spawn, movement, auto targeting, direct control, skill handling, `finish_combat`, `on_unit_downed`
- `scripts/game/ManagementSceneController.gd`
  - monster UI, result UI, deployment and training controls
- `scripts/units/Unit.gd`
- `scripts/combat/DamageService.gd`
- `scripts/core/GameState.gd`
- `data/monsters.json`
- `data/skills.json`
- `data/waves.json`
- `data/enemies.json`
- `tools/BalanceSimulation.gd`
- `tools/DemoSmokeTest.gd`
- `tools/TutorialFlowSmokeTest.gd`

## First Task For The Next Session

Fix tutorial combat resolution before writing tutorial help text.

Recommended order:

1. Re-run focused balance scenarios for DAY1 and DAY2.
2. Identify whether the timeout is caused by low monster damage, poor targeting/chase behavior, enemy pathing, trap damage frequency, defense/HP numbers, or skill cooldown/value.
3. Apply the smallest balance/AI/data change that makes DAY1 and DAY2 resolve naturally.
4. Add or update an automated balance assertion so DAY1/DAY2 cannot silently regress into 120-second stalls.
5. Only after combat resolves, add post-combat EXP/level-up visibility and a tutorial step that makes the player check monster growth and skills.

## Suggested Acceptance Criteria

- DAY1 automatic or lightly guided combat ends in win or loss within 60-90 seconds.
- DAY2 trap/directive tutorial combat ends within 60-90 seconds.
- DAY3 assisted combat remains winnable without pushing right against the 120-second cap.
- Result screen clearly shows reward and monster growth information.
- Tutorial flow explicitly covers: skill check, skill use, battle result, growth review, next-day transition.
- Existing smoke tests still pass.

## Do Not Forget

- Do not claim the tutorial is complete while DAY1/DAY2 can stall for 120 seconds.
- Do not add tutorial help overlays before the underlying gameplay loop works.
- Do not remove or weaken the onboarding dialogue triggers while fixing balance.
- Do not disturb the untracked font source reference folder under the Korean reference-materials directory unless the user explicitly asks.
- Keep the current `data/characters.json` and `docs/design/CHARACTER_EMOTION_IMAGE_RULES.md` rules for character/monster portrait generation.

## Exact Start Sentence For Next Session

Read `docs/HANDOFF_TUTORIAL_GAME_LOOP_AUDIT_2026-07-07.md` first. The next task is to fix DAY1/DAY2 tutorial combat pacing so battles resolve naturally before adding tutorial help text.
