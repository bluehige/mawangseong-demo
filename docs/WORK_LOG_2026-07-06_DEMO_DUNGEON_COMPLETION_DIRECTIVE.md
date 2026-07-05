# 2026-07-06 Demo Dungeon Completion Directive

Purpose: fix the current work direction before continuing the Demon King castle dungeon object and room-completion pass.

## Session Compass

Every resumed, compressed, or new session must restate this before doing work:

> We are building a playable Demon King castle dungeon demo, not a decorative background. The dungeon must be assembled from quarter-view cells, floor tiles, wall/edge/door rules, room-role objects, and walkable cell data. The immediate goal is to complete the dungeon objects, complete the required rooms, connect them into a finished demo dungeon, and verify it in Godot.

Beginner translation: the map is data first. Art is attached to the data. A pretty single image is not the dungeon.

## Handoff Writing Rule

Before writing or updating a handoff, check the existing example/reference documents:

- `mawang_guideline_pack/docs/01_SESSION_START_COMMANDS.md`
- `mawang_guideline_pack/docs/06_DECISION_LOG_TEMPLATE.md`
- `docs/HANDOFF_DEMO_FOUNDATION.md`
- `docs/HANDOFF_NEXT_SESSION_QUARTERVIEW_VARIANTS_2026-07-02.md`

If a reference document is mojibake/partially unreadable, still preserve the readable structure:

1. current goal and latest decision,
2. files changed this session,
3. completed features,
4. commands run and verification results,
5. unfinished or deferred items,
6. first task for the next session,
7. risks and files not to disturb,
8. exact start sentence for the next session.

## Mandatory Carry-Forward Rule

Every handoff update from now on must explicitly include:

- the Session Compass above,
- the Handoff Writing Rule above,
- the current object-system limitation or completion status,
- the next concrete dungeon-completion step.

Do not leave these rules only in a work log. They must be present in the active handoff document too.

## Current Implementation Direction

The next implementation phase is:

1. Convert room-role object selection from `prop_id + layer` to `prop_id + facing + layer`.
2. Generate or wire direction-aware variants for throne, barracks, treasure, recovery, entrance, watch post, brazier, build slot, and trap where needed.
3. Complete the required demo rooms and connect them into one readable dungeon route.
4. Verify with Godot import, smoke tests, and manual capture.
