# Handoff: Management UI Compact Loop (2026-07-08)

## User Problem

The management screen had too many equal-weight controls:

- Left `시설 배치` panel looked central but only selected rooms, so it felt important without doing enough.
- Bottom `건설` button did not directly let the player build.
- `침공 작전`, `방어 준비`, and `다음 날` were confusing in the current demo loop.
- The correct loop for the tutorial demo is: prepare rooms and routes, place monsters, set directives, then start combat. Day advancement belongs after battle results, not on the management screen.

## Decision Taken

Chose the medium-scope fix instead of a full screen rewrite:

- Keep the current map, right inspector, and tutorial gates.
- Make the bottom action bar compact.
- Make `건설` open a real left-side construction workflow.
- Remove management-screen buttons that do not map to the current loop.

Rejected options:

- Only adding explanatory text would not solve the dead-button feeling.
- Full layout rebuild would be higher risk while tutorial flow and map authoring are still active.

## Implemented

### Bottom Action Bar

File: `scripts/game/ManagementSceneController.gd`

- Replaced five buttons with three primary actions:
  - `건설`
  - `몬스터`
  - `전투 시작`
- Removed management-screen `침공 작전`.
- Removed management-screen `다음 날`.
- Renamed `방어 준비` to `전투 시작`.
- Added a short prep-order explanation in the remaining space.
- `다음 날` still exists on the result screen through `NextDayButton`; it was not removed from the battle result loop.

### Construction Flow

Files:

- `scripts/game/GameRoot.gd`
- `scripts/ui/HUDController.gd`
- `scripts/game/ManagementSceneController.gd`

New flow:

1. Player presses `건설`.
2. Left panel changes from room list to construction menu.
3. Player selects one of:
   - `감시 초소`
   - `병영`
   - `보물 보관실`
   - `회복 둥지`
   - `비우기`
4. Valid map rooms/slots are highlighted in purple.
5. Player clicks a valid room/slot.
6. Facility applies immediately and construction mode exits.

Important state/methods:

- Added `build_pick_facility_id`.
- Added `_build_facility_choices()`.
- Added `_default_build_facility_choice()`.
- Added `_set_build_facility(facility_id)`.
- Refactored facility application into `_change_room_facility(room_id, facility_id) -> bool`.
- `_change_selected_room_facility(facility_id)` now delegates to `_change_room_facility`.

Default selected build item is `watch_post` because it gives the construction button an immediately useful defensive action.

### Left Facility Panel

File: `scripts/ui/HUDController.gd`

- Normal management mode title is now `시설 관리`.
- Room rows now show practical status:
  - locked rooms: `고정`
  - build slots: `건설 가능`
  - mutable rooms: monster capacity such as `1/4`
- In build mode, left panel becomes `건설` and shows facility choices plus costs.
- The lower `맵 커스텀` panel no longer repeats build instructions during build mode; it now says path editing is locked until construction is done.

### Monster Flow

No large rewrite was needed. Existing direct placement remains:

- Right panel monster names start placement mode.
- Map monster drag placement still works.
- `몬스터` bottom button opens monster management for stats/training.

## Verification

Passed:

```powershell
godot --headless --path . --scene tools/DemoSmokeTest.tscn
godot --headless --path . --scene tools/TutorialFlowSmokeTest.tscn
godot --headless --path . --scene tools/RoomPathAuthoringProbe.tscn
godot --path . --scene tools/ManualVerificationCapture.tscn
```

Updated screenshots:

- `tmp/manual_verification/01_management.png`
- `tmp/manual_verification/01_build_pick_mode.png`

Headless screenshot capture still fails under the dummy renderer because viewport texture images are null. Normal renderer capture works.

Expected existing warning:

- `Loaded resource as image file, this will not work on export`
- This is from the existing UI PNG skin loading path in `HUDController.gd`, not from the compact-loop change.

## Test Updates

File: `tools/DemoSmokeTest.gd`

- Updated construction expectation:
  - old: click target, then facility modal opens
  - new: click target, selected facility applies immediately
- Updated combat assertion wording from `방어 준비` to `전투 시작`.

## Current UX Result

Management screen now reads as:

- left: facility state or construction choices
- center: map and route
- right: selected room, directives, monster placement
- bottom: only core loop actions

This matches the current playable tutorial loop better than the previous button-heavy bar.

## Not Done

- No web export/deploy was performed in this pass.
- The regular campaign `침공 작전` event system is still future work; do not re-add it as a main management button until it has actual event scheduling and choices.
- UI skin loading warnings remain a separate technical cleanup.

## Next Suggested Work

1. Play the management loop manually as a first-time user:
   - press `건설`
   - pick `보물 보관실` or `회복 둥지`
   - click a valid room
   - place a monster
   - press `전투 시작`
2. Decide whether facility changes should stay single-use or keep construction mode open for batch building.
3. Later, make `침공 작전` a conditional event panel only on days where an invasion event actually exists.
4. Clean up UI PNG loading so export warnings are removed.

