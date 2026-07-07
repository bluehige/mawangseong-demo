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

## 2026-07-07 Combat Balance Update

The immediate combat-resolution blocker has been fixed.

Changed files:

- `scripts/units/Unit.gd`
- `scripts/game/CombatSceneController.gd`
- `scripts/combat/WaveManager.gd`
- `data/waves.json`
- `tools/BalanceSimulation.gd`
- `docs/WORK_LOG_2026-07-07_TUTORIAL_COMBAT_BALANCE.md`

Implemented:

- Units now treat a path point as reached at a radius that matches the combat collision size better.
- Enemy and monster room movement now starts from the unit's actual world position, not only from room centers.
- Same-room pursuit now moves directly toward the target point.
- Defense behavior is anchored to the assigned room and adjacent rooms so future larger monster rosters do not collapse into a full-dungeon dogpile.
- Trap-lure behavior now still engages enemies already in the same room.
- Wave entries can carry stat scaling fields such as `hp_scale`, `atk_scale`, and `spawn_interval`.
- `BalanceSimulation` now supports `--assert-tutorial-balance`.

Fresh verification:

```powershell
godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --assert-tutorial-balance
```

Result:

```text
DAY1_AUTO: WIN 56.4s, monster_down 0, enemy_down 2/2
DAY2_TRAP_DIRECTIVE: WIN 54.1s, monster_down 1, enemy_down 3/3
DAY3_ASSISTED: WIN 70.0s, monster_down 2, enemy_down 5/5
BALANCE_ASSERT: PASS
```

Current decision:

- The old 120-second combat stall is no longer the next blocker.
- Do not tune DAY1/DAY2 by adding empty waiting time. DAY1 around 56s and DAY2 around 54s are accepted as tutorial-friendly pacing candidates unless the user explicitly asks for slower battles.
- Post-combat monster EXP/level-up visibility and the DAY1 result growth-review tutorial step are now implemented.
- 2026-07-07 user playtest feedback makes management-screen readability the next blocker before evolution/invasion work.
- Accepted direction: day-settlement resource economy, fixed entrance-to-throne main route plus visible socket connection editing, and a simplified three-zone selected-room inspector.

Latest growth loop update:

- Combat start captures each monster's starting level/EXP.
- Combat end finalizes pending EXP into level-ups with the same level-up rule used by training.
- Result screen now shows monster growth lines and a `성장 확인` button.
- DAY1 tutorial now blocks result progression until the player reviews growth.
- `TutorialFlowSmokeTest` now asserts that DAY1 result cannot advance before growth review.

Fresh verification after the growth update:

```powershell
godot --headless --path . --import
godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn
godot --headless --path . --run res://tools/OnboardingFlowSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --assert-tutorial-balance
```

Result:

```text
TUTORIAL_FLOW_SMOKE_TEST: PASS
ONBOARDING_FLOW_SMOKE_TEST: PASS
DEMO_SMOKE_TEST: PASS
BALANCE_ASSERT: PASS
```

## Urgent Management UI / Map Rule Rework

This is now higher priority than evolution, invasion, or additional tutorial content.

User-approved recommendations:

1. Resource economy: use a day-settlement model, not mobile-style per-minute income.
2. Map structure: keep only entrance and throne fixed; make the middle rooms and path modules readable through a fixed main-route plus visible socket-connection editing rule.
3. Selected-room UI: replace the crowded right inspector with a simple summary / connection / action structure.

Beginner terms:

- Day-settlement means resources are paid out at battle/result/day transitions, not ticking every minute.
- Socket means a room/path doorway that can connect to another doorway.
- Main route means the required valid path from entrance to throne.
- Inspector means the panel that explains the currently selected room.

### Priority 1: Resource Bar And Economy Rules

Problem:

- Top resource labels currently show `+N/분`, which reads like a mobile idle game.
- The top plaques are visually misaligned.
- Resource purpose is unclear.

Required changes:

- In `scripts/ui/HUDController.gd`, change `build_top_bar()` so the top bar shows only current state:
  - `금화 1245`
  - `마력 320`
  - `식량 18/30`
  - `악명 620`
  - `DAY 01 밤`
  - `마왕성 체력 1500 / 1500`
- Remove `/분` from normal top-bar presentation.
- In `scripts/core/GameState.gd`, keep income values only as day/result settlement values, or rename them later to `*_daily` / `*_settlement` if touching save/data compatibility.
- Show income sources in result/day settlement UI, not in the always-visible top bar.
- Re-check resource roles:
  - Gold: construction, room conversion, training.
  - Mana: skill use, rituals, evolution costs.
  - Food: monster upkeep, roster/dispatch pressure.
  - Infamy: story unlocks, invasion bait, stronger enemy attention.

Acceptance criteria:

- No management or combat top bar text uses `/분`.
- Top resource text is centered within each plaque at 1920x1080.
- Result/day settlement remains the place where gained resources are explained.

### Priority 2: Always-Visible Room Selection Feedback

Problem:

- Clicking a room does not clearly show which room is selected.
- The player cannot tell whether a click succeeded.

Required changes:

- In `scripts/dungeon_quarter/QuarterDungeonRenderer.gd`, draw a selected-room highlight even outside map-editor mode.
- Use a clear but non-destructive visual:
  - gold outline around selected room footprint,
  - subtle inner tint,
  - small room-name tag if it does not overlap combat/tutorial overlays.
- Keep drag-drop hover colors separate from selected-room highlight.
- Ensure build slots, path modules, entrance, and throne can all show selection feedback.

Acceptance criteria:

- Selecting a room changes the map immediately.
- The selected room remains visible after UI rebuilds.
- Highlight does not hide monsters or room art.

### Priority 3: Make Map Connection Rules Visible

Problem:

- The system has path modules and sockets, but the player cannot understand how rooms connect.
- The editor has buttons such as path candidate, path placement, adjacent connect, and path-end connect, but the visual rules are not clear enough.

Required changes:

- Keep the accepted rule: entrance and throne are fixed, middle rooms and corridors are player-authored.
- In normal management view, show the current valid entrance-to-throne main route as a thin gold path overlay.
- In map editor mode:
  - mark connectable sockets in blue,
  - mark invalid/blocked sockets in red,
  - show the currently previewed path candidate in yellow,
  - show source and target room names in the map editor panel.
- Rename or group map-editor controls so the order is understandable:
  1. Select source room.
  2. Pick target/candidate.
  3. Place path.
  4. Connect path ends.
  5. Save.
- Do not silently recreate deleted paths while editing. Auto-repair may only happen on save/combat/day-boundary validation, and it must be communicated.

Relevant files:

- `scripts/game/GameRoot.gd`
- `scripts/game/ManagementSceneController.gd`
- `scripts/dungeon_quarter/QuarterDungeonRenderer.gd`
- `scripts/dungeon_quarter/ModuleGraph.gd`
- `data/dungeon_quarter/starting_layout.json`
- `data/dungeon_quarter/custom_layouts.json`

Acceptance criteria:

- A player can explain, from the screen alone, which path connects entrance to throne.
- In edit mode, the player can see what will be connected before pressing the final connect/save button.
- If the layout is invalid, the UI tells the user why in plain Korean.

### Priority 4: Simplify The Selected-Room Inspector

Problem:

- The current right panel crams title, art, stats, connection ids, facility conversion, costs, and directives into one narrow frame.
- Text overlaps or looks misaligned.

Required changes:

- In `scripts/ui/HUDController.gd`, refactor `build_selected_room_info()` into three clear zones:
  1. Summary: room name, role, HP, capacity.
  2. Connection: route status and connected rooms using display names, not raw ids such as `spike_corridor`.
  3. Actions: room directive buttons and one `시설 변경` button.
- Move facility conversion options and cost text into a separate small panel/modal opened by `시설 변경`.
- Remove tiny cost footnotes from the default inspector.
- Use smaller, aligned labels and no overlapping buttons.

Acceptance criteria:

- No text overlaps in the right inspector at 1920x1080.
- Raw room ids are not shown to the player unless debug mode is on.
- The inspector can be understood by scanning only headings and values.

### Priority 5: Verification And Documentation

Required checks after implementation:

```powershell
godot --headless --path . --import
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn
godot --headless --path . --run res://tools/RoomPathAuthoringProbe.tscn
godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --assert-tutorial-balance
```

Also manually verify the management screen at 1920x1080:

- top resource labels centered,
- selected room visibly highlighted,
- main route visible,
- map editor candidate/connection rules visible,
- right inspector readable.

Lower-priority candidates after this:

1. Add monster skill/growth detail visibility from the result screen into the monster management screen.
2. Decide the evolution system direction using `docs/design/EVOLUTION_SYSTEM_REFERENCE_OPTIONS_2026-07-07.md`.
3. Prepare invasion scaling data around `chapter tier + enemy role scaling`, with growth-responsive scaling reserved for repeat/endgame content.

### 2026-07-07 Implementation Status

Implemented:

- Top resource bar now shows current stock only:
  - `금화 1245`
  - `마력 320`
  - `식량 18 / 30`
  - `악명 620`
  - no top-bar resource text uses `/분`.
- Selected room/path/build-slot feedback now draws directly on the map in management view:
  - selected footprint tint,
  - gold outline,
  - small display-name tag.
- The current entrance-to-throne main route now draws as a gold route overlay in management view.
- Map editor mode now shows connection readability markers:
  - blue = connectable socket,
  - red = blocked socket on the selected source,
  - green = already connected socket on the selected source,
  - current path candidate remains highlighted.
- Map editor controls now follow the intended order:
  - source,
  - target/candidate,
  - path placement,
  - connection,
  - save.
- The selected-room inspector is now split into:
  - summary,
  - connection,
  - actions.
- Facility conversion choices and costs moved behind the `시설 변경` modal.
- Player-facing selected-room text now uses display names instead of raw ids for connected rooms and candidate targets.
- Map editor validation errors now use plain Korean display-name text instead of raw English/internal ids.

Files changed:

- `scripts/ui/HUDController.gd`
- `scripts/game/ManagementSceneController.gd`
- `scripts/game/GameRoot.gd`
- `scripts/dungeon_quarter/QuarterDungeonRenderer.gd`

Visual proof:

- `tmp/manual_verification/01_management.png`
- `tmp/manual_verification/01_map_editor.png`
- `tmp/manual_verification/01_map_editor_disconnected.png`

Verification:

- `godot --headless --path . --import`: PASS
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: PASS
- `godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn`: PASS
- `godot --headless --path . --run res://tools/RoomPathAuthoringProbe.tscn`: PASS
- `godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --assert-tutorial-balance`: PASS

Known warning:

- Godot still prints existing PNG image-load export warnings for the dark-fantasy UI skin. This predates the management readability pass and did not fail the tests.

### 2026-07-07 User Playtest Follow-Up Fixes

The user immediately re-tested the readability pass and rejected six remaining usability problems. Treat these follow-up fixes as part of the same urgent management UI/map readability task.

User feedback and implemented response:

1. Top text was still not centered.
   - Resource, day, and demon-castle HP labels were changed to use the full plaque width instead of offset inner rectangles.
2. Tutorial says to set the global directive to `사수`, but the screen did not show where the `사수` button is.
   - The management selected-room inspector now includes `전체 지침` buttons directly, including a tutorial target id on `사수`.
   - Tutorial copy for `TUT_050_GLOBAL_DEFEND` now points the player to the right selected-room panel's `전체 지침 -> 사수` button.
3. The route is visible, but the screen did not explain how to change it.
   - The left `맵 커스텀` panel now shows the route-edit order:
     `경로 편집 -> 방 선택 -> 후보 보기 -> 통로 배치 -> 연결 -> 저장`.
   - The right selected-room connection zone now repeats the short route-change instruction without raw ids.
4. The selected-room UI was still too crowded and text did not fit.
   - Long inspector text was shortened and forced into explicit line breaks.
   - Bottom helper text was shortened to a three-line placement hint.
5. The unexplained square image between `몬스터 관리` and `침공 작전` was visually confusing.
   - The bottom navigation now uses a flat panel skin instead of the ornate inspector skin, removing the unexplained central ornament.
6. Monster placement felt meaningless because the desired placement was unclear and appeared limited.
   - The selected-room inspector now exposes direct `몬스터 배치` buttons for each owned monster.
   - Room capacity is shown as current/max, for example `배치 1 / 4`.
   - Tutorial gating now allows exploratory monster placement, room selection, and directive changes without blocking the player from trying them.

Files changed in this follow-up:

- `scripts/ui/HUDController.gd`
- `scripts/game/ManagementSceneController.gd`
- `scripts/game/GameRoot.gd`
- `scripts/systems/tutorial/TutorialManager.gd`
- `docs/HANDOFF_TUTORIAL_GAME_LOOP_AUDIT_2026-07-07.md`
- `docs/HANDOFF_MAP_CUSTOM_CURRENT_2026-07-03.md`

Fresh visual verification:

- `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS
- Checked `tmp/manual_verification/01_management.png` and `tmp/manual_verification/01_map_editor.png`.
- Confirmed top-bar text is centered, the global `사수` button is visible in management, route-edit instructions fit, right-panel long text no longer runs out of the panel, the bottom ornament is gone, and direct monster placement buttons are visible.

Fresh regression verification:

```powershell
godot --headless --path . --import
godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --headless --path . --run res://tools/RoomPathAuthoringProbe.tscn
```

Result:

- `TUTORIAL_FLOW_SMOKE_TEST: PASS`
- `DEMO_SMOKE_TEST: PASS`
- `ROOM_PATH_AUTHORING_PROBE: PASS`

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

Have the user playtest the implemented management-screen readability rework before moving to evolution/invasion work.

Recommended order:

1. Open the current build and test:
   - top resource bar,
   - selected-room highlight,
   - entrance-to-throne route overlay,
   - map editor socket/candidate colors,
   - selected-room inspector,
   - `시설 변경` modal.
2. If the user rejects readability:
   - adjust visual weight, label size, or panel spacing first.
   - Do not add new systems before this is accepted.
3. If the user accepts readability:
   - move to monster growth detail visibility, then evolution system implementation planning.

## Suggested Acceptance Criteria

- No top-bar resource text uses `/분`.
- Top resource labels are centered and readable at 1920x1080.
- Selecting any room/path/build slot/entrance/throne gives immediate visible feedback.
- The normal management map shows the current entrance-to-throne route.
- Map editor mode shows connectable sockets, blocked sockets, and the current path candidate before saving.
- The right inspector has no overlapping text and does not expose raw ids such as `spike_corridor` to the player.
- Result/day settlement still explains gained resources and monster growth.
- Existing smoke tests still pass, especially `DemoSmokeTest`, `TutorialFlowSmokeTest`, `RoomPathAuthoringProbe`, and tutorial balance simulation.

## Do Not Forget

- Do not continue evolution/invasion implementation before this management readability pass is complete.
- Do not claim the tutorial or management loop is complete while resource meaning, selected-room feedback, or path rules remain unclear.
- Do not add tutorial help overlays before the underlying gameplay/UI rules are readable.
- Do not remove or weaken the onboarding dialogue triggers while fixing management UI or balance.
- Do not expose raw room/path ids to the player outside debug UI.
- Do not hide path rules inside debug-only overlays.
- Do not disturb the untracked font source reference folder under the Korean reference-materials directory unless the user explicitly asks.
- Keep the current `data/characters.json` and `docs/design/CHARACTER_EMOTION_IMAGE_RULES.md` rules for character/monster portrait generation.

## Exact Start Sentence For Next Session

Read `docs/HANDOFF_TUTORIAL_GAME_LOOP_AUDIT_2026-07-07.md` first. The urgent management-screen resource, map-connection, selected-room inspector, tutorial directive guidance, bottom navigation ornament, and direct monster placement follow-up fixes have been implemented; the next task is user playtest and only then moving to monster growth/evolution work.
