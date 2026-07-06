# Tutorial System Feasibility Review - 2026-07-06

## Verdict

The current map structure is ready enough to start the first tutorial system.

Recommended scope for the first tutorial:

1. Management screen orientation.
2. Room selection.
3. Monster placement.
4. Basic facility or directive choice.
5. Start combat.
6. Watch enemies route from entrance toward throne.
7. Use one monster command or skill.
8. Resolve battle and advance to the next day.

Do not start with a full freeform map-editor tutorial yet. The room/path graph is usable, but path placement UI, target-specific connection selection, and multi-segment path drawing are still incomplete.

## Map Completion Assessment

Current map completion for tutorial use: about 75%.

What is solid enough:

- The novice dungeon has a stable `4x4` macro grid with `5x5` room cells and `2x2` path gaps.
- Core room IDs are stable: `entrance`, `throne`, `barracks`, `recovery`, `treasure`, `slot_01`, plus path/trap modules such as `spike_corridor`.
- `ModuleGraph` can validate layouts, compute room-to-room paths, expose walkable cells, and clamp units onto walkable floor.
- Connected sides drive room `connection_variant` / open-mask behavior.
- Unconnected sides render as wall/closed socket states.
- The required `entrance -> throne` route is now protected at commit boundaries: map save, combat start, and next-day progress.
- Existing tests cover default map validity, pathing, room walls/doors, route repair, combat start, trap damage, monster placement, combat controls, battle result, and three-day demo completion.

What is still prototype-level:

- Full-grid room art is still not production-approved. Current facing sprites are treated as visual placeholders.
- The room/path editor can connect already adjacent sockets, but it cannot yet let the user place arbitrary path modules through UI.
- The editor cannot yet select a specific target room/path when several connection candidates exist.
- Multi-segment route drawing across several empty gaps is not implemented.
- Required-route repair can generate a safety path, but it is not a substitute for a player-facing path-building tool.

## Tutorial Feasibility

The first tutorial is technically feasible with the current system because the game already exposes enough state and events:

- `SignalBus.screen_changed(screen_name)`
- `SignalBus.room_selected(room_id)`
- `SignalBus.unit_selected(unit)`
- `SignalBus.resources_changed`
- `SignalBus.battle_finished(summary)`
- `SignalBus.log_added(message)`
- Stable GameRoot actions such as `_select_room`, `_start_combat`, `_change_selected_room_facility`, `_set_room_directive`, `_set_global_directive`, `_start_management_monster_drag`, `_finish_management_monster_drag`, and `_advance_after_result`.

However, these are not a tutorial engine yet. They are enough hooks to build one.

## Required Tutorial Infrastructure

Before implementing tutorial content, add a small tutorial layer.

1. `TutorialManager`
   - Tracks current tutorial id, step id, completed steps, and blocked/skipped state.
   - Listens to `SignalBus` and explicit `GameRoot` tutorial events.
   - Owns step progression conditions.

2. Tutorial data file
   - Suggested path: `data/tutorials/first_day_tutorial.json`.
   - Each step should define:
     - `id`
     - `screen`
     - `target_id`
     - `message`
     - `advance_condition`
     - optional `allowed_actions`

3. UI target registry
   - Current buttons are created inline in `HUDController` / scene controllers without stable tutorial IDs.
   - Add a target registry such as `root.register_tutorial_target("start_combat_button", button)`.
   - Required first targets:
     - room list rows,
     - monster management button,
     - build/facility buttons,
     - defense ready/start combat button,
     - next day button,
     - map editor buttons if included later.

4. Tutorial overlay
   - CanvasLayer above the HUD.
   - Dim background.
   - Highlight registered target rect.
   - Message panel.
   - Optional next/skip button.
   - Must not be part of the map renderer.

5. Input gating
   - Tutorial needs to allow only the currently requested action when a step is blocking.
   - Current buttons call root methods directly, so add an action guard inside GameRoot methods or wrap button callbacks through a tutorial-aware dispatcher.
   - Do not rely only on a visual overlay to block input.

6. Tutorial-specific action events
   - Add explicit emits for important actions because the current signals are too broad.
   - Suggested event shape:
     - `SignalBus.tutorial_action(action_id: String, payload: Dictionary)`
   - Suggested action IDs:
     - `room_selected`
     - `monster_drag_started`
     - `monster_placed`
     - `facility_changed`
     - `room_directive_changed`
     - `global_directive_changed`
     - `combat_started`
     - `skill_used`
     - `battle_finished`
     - `day_advanced`
     - `map_editor_opened`
     - `map_connection_changed`
     - `map_saved`

7. Save/progress persistence
   - Current `GameState` resets every run and does not persist tutorial completion.
   - Add at least an in-memory tutorial flag first.
   - Add save support later when the save system is introduced.

8. Tutorial tests
   - Add `tools/TutorialFlowSmokeTest.gd/.tscn`.
   - First test should simulate the first-day tutorial path through management, monster placement, combat start, battle finish, and next-day transition.
   - Later add a map-editor tutorial test after path placement UI exists.

## Current Risks For Tutorial Work

### P0 - No Tutorial State Machine

There is no system that owns tutorial step state. Implementing tutorial copy directly inside `GameRoot` or `HUDController` would create another hardcoded flow that will be hard to revise.

Required fix:

- Add `scripts/systems/tutorial/TutorialManager.gd`.
- Keep tutorial steps in data.

### P0 - No Stable UI Target IDs

The HUD is rebuilt every screen change, and buttons are anonymous. A tutorial cannot reliably highlight "Start Combat" or "Monster Management" without stable target IDs.

Required fix:

- Add target registration during HUD build.
- Clear and rebuild target registry whenever `_set_screen()` rebuilds UI.

### P1 - Input Is Not Tutorial-Gated

Players can currently press any visible button. A blocking tutorial needs to stop unrelated actions until the current step is complete.

Required fix:

- Add `GameRoot._tutorial_allows(action_id, payload)` or route UI button callbacks through `GameRoot._run_action(action_id, callable, payload)`.

### P1 - Map Editor Is Not Ready For A Full Tutorial

The map editor supports move, disconnect, adjacent connect, save, and required route repair. It does not yet support manual path placement UI or target-specific connection selection.

Required fix before map-editor tutorial:

- Path module placement UI.
- Connection target selection or preview.
- Visual distinction between user-authored path and `system_required` repaired path.
- Delete/replace rules for `system_required` paths.

### P1 - Tutorial Text Should Not Be Hardcoded In Current UI Files

Several current UI text literals are hardcoded in controller scripts. Tutorial text will be revised often, so it should live in data and be loaded as UTF-8.

Required fix:

- Put tutorial copy in JSON or CSV-like data.
- Keep UI button labels separate from tutorial instructional copy.

### P2 - Tutorial Completion Is Not Persisted

This is acceptable for the first prototype, but it will be annoying as soon as the game restarts.

Required fix:

- Add tutorial completion fields to a future save system.
- Until then, use `GameState.tutorial_flags`.

## Recommended First Tutorial Flow

Use this as the first implementation target:

1. `intro_management`
   - Trigger: screen is `management`.
   - Target: top/center map area.
   - Goal: explain that enemies enter from `entrance` and try to reach `throne`.

2. `select_barracks`
   - Target: `barracks` room list row or map room.
   - Advance: `room_selected == barracks`.

3. `place_goblin`
   - Target: goblin preview / barracks room.
   - Advance: `monster_placed` with `monster_id == goblin` and `room_id == barracks`.

4. `set_entry_block_or_trap_lure`
   - Target: room directive button.
   - Advance: `room_directive_changed`.

5. `start_combat`
   - Target: defense ready/start combat button.
   - Advance: `combat_started`.

6. `watch_enemy_route`
   - Trigger: first enemy spawned.
   - Advance: enemy has non-empty path toward `throne` or after a short timer.

7. `use_skill`
   - Target: skill button or keyboard key.
   - Advance: `skill_used`.

8. `finish_battle`
   - Trigger: `battle_finished`.
   - Target: result panel.

9. `advance_day`
   - Target: next day button.
   - Advance: `day_advanced`.

## Recommended Implementation Order

1. Add `SignalBus.tutorial_action`.
2. Add `TutorialManager` with data-driven step loading.
3. Add target registry and tutorial overlay.
4. Add action gating for blocking steps.
5. Wire first-day tutorial actions.
6. Add `TutorialFlowSmokeTest`.
7. Only after that, consider map-editor tutorial steps.

## Verification Run

Run these after the tutorial skeleton is added:

- `godot --headless --path . --run res://tools/RoomPathAuthoringProbe.tscn`
- `godot --headless --path . --run res://tools/RoleCombatLayoutProbe.tscn`
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`
- `godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn`

Current review run before tutorial implementation:

- `RoomPathAuthoringProbe`: PASS
- `RoleCombatLayoutProbe`: PASS
- `QuarterModuleSmokeTest`: PASS
- `DemoSmokeTest`: PASS

## Bottom Line

Start the tutorial system now, but keep the first tutorial focused on the existing stable game loop.

Do not make the first tutorial depend on freeform map editing. The map structure is strong enough for route explanation, room roles, monster placement, combat start, and battle resolution. It is not yet complete enough for a polished "build your own path network" tutorial.
