# Handoff: Facility Role Panel Pass

Date: 2026-07-08

## User Problem

The user felt the building/facility panels still looked meaningless. They needed clearer role explanations so each facility choice communicates why it exists, when to use it, and what risk it creates.

## Implemented Direction

The chosen direction was to make the construction panel a decision surface:

- Facility rows stay compact for quick selection.
- The selected facility gets a dedicated explanation area.
- Descriptions come from the facility definition data, not hardcoded one-off UI copy.
- Right-side selected room labels now show the facility role title instead of generic type labels where available.
- Existing facility-change modal also shows a one-line role explanation.

## Files Changed

- `scripts/game/GameRoot.gd`
  - Added semantic metadata to `_facility_definition()`:
    - `role_title`
    - `role_summary`
    - `effect_summary`
    - `recommend_summary`
    - `caution_summary`
  - Facilities now have player-facing meanings:
    - `watch_post`: 전방 차단
    - `barracks`: 주력 방어선
    - `treasure`: 도둑 유인 목표
    - `recovery`: 후퇴 거점
    - `build_slot`: 철거 / 예비지

- `scripts/game/ManagementSceneController.gd`
  - In build mode, the left panel now uses the full management-side height:
    - `hud.build_facility_build_panel(16, 92, 300, 780)`
  - The old map-custom panel is hidden while building, because the build panel now needs the space for explanation.

- `scripts/ui/HUDController.gd`
  - Rebuilt `build_facility_build_panel()`:
    - Compact facility buttons with icon, name, cost, and role title.
    - Bottom detail section with selected facility role, effect, recommended placement, and caution.
  - Added `_facility_detail_text()`.
  - Added `_room_role_label()` so selected-room header shows a meaningful role title.
  - Facility-change modal now includes role summary text per facility.

## Current UX

When the player presses `건설`:

1. The left panel becomes a full-height construction panel.
2. Each facility row shows name, cost, icon, and short role.
3. The selected facility shows:
   - what it is for
   - actual gameplay effect
   - recommended placement
   - caution/risk
4. Clicking a highlighted room or build slot applies the facility immediately.

## Verification

Passed:

- `godot --headless --path . --scene tools/DemoSmokeTest.tscn`
- `godot --headless --path . --scene tools/TutorialFlowSmokeTest.tscn`

Manual capture regenerated:

- `tmp/manual_verification/01_management.png`
- `tmp/manual_verification/01_build_pick_mode.png`

Visual check:

- Build-mode panel text is readable.
- Detail section does not overlap the facility rows.
- Right selected-room panel shows role labels such as `주력 방어선`.

## Known Existing Warning

Godot still prints `Loaded resource as image file, this will not work on export` for UI skin PNGs loaded through `_skin_texture()`. This warning existed before this pass and was not caused by the facility-role panel changes.

## Not Done

- No web export or GitHub Pages deployment was done for this pass.
- Facility roles are now better explained, but not all roles have unique deep mechanics yet. Current explanations mostly reflect existing mechanics:
  - recovery heals in combat
  - treasure is thief target
  - barracks/watch post are capacity and placement-based defense rooms
  - build slot is a reset/empty state

## Suggested Next Work

Add stronger mechanical differentiation if the user still feels buildings lack meaning:

- Watch post: reveal/slow first enemy entering nearby path.
- Barracks: temporary attack or defense aura for stationed monsters.
- Treasure: risk-reward bonus if defended successfully.
- Recovery: limited healing charge or retreat behavior tuning.
- Build slot: construction preview and refund rules.
