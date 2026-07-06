# Role-Driven Combat Room Layout Concept - 2026-07-06

This concept corrects the room layout priority: paths are monster travel lanes, while combat should happen inside rooms.

## Core Combat Route

The novice dungeon combat loop should read in this order:

1. `outside_approach`
2. `entrance`
3. `trap_room`
4. `barracks`
5. `treasure_lure_branch`
6. `throne`

The recovery room is not a main-route battle room. It is a protected side/rear room for retired or injured monsters.

## Room Roles

### Entrance

- Role: invasion start and funnel.
- It should connect clearly to the outside.
- It should not be the main combat room.
- It should narrow enemy movement into the trap room.

### Trap Room

- Role: weaken enemies before the real fight.
- It should contain spikes, damaged floor, slow zones, or debuff objects.
- The room should be compact and hard to avoid.
- Its goal is not to kill everything, but to reduce enemy HP/formation before barracks.

### Barracks

- Role: main interception room.
- This is the first serious combat space.
- It should be larger than a basic room when possible, ideally a 2-grid merged combat room.
- It needs monster staging positions, cover, barricades, weapon racks, and a central melee pocket.
- The room should let defenders block the enemy after the trap room.

### Recovery Nest

- Role: safe recovery and fallback.
- It should sit behind or beside the barracks, connected by a narrow side doorway.
- It should not be on the direct enemy route.
- Retired or injured monsters should be able to leave barracks and rest here.

### Treasure Vault

- Role: lure and distraction.
- It should be visible or tempting after the barracks, but not on the shortest throne route.
- Enemy AI can choose this branch when greed/raid goals override throne rush.
- It should force attackers to move around treasure piles instead of fighting in an empty square.

### Throne Room

- Role: final defense.
- It must be the deepest major chamber, not near the entrance.
- It should be larger, fortified, and readable as the last stand.
- It needs layered defensive positions before the throne.

## Layout Rule

- Corridor/path cells are movement lanes only.
- Room interiors are battle arenas.
- Basic support rooms can stay `1` room grid.
- Core combat rooms may merge `2` room grids.
- Each combat room should define:
  - entry choke,
  - defender staging point,
  - objective/role object,
  - obstacle or cover pattern,
  - retreat or side-door behavior when relevant.

## Generated Concept Image

- Image: `docs/concepts/role_driven_combat_room_layout_concept_2026-07-06.png`
- This is a design-direction image, not a sliced runtime atlas.
- Use it to evaluate the combat role sequence before generating final room assets.

## Source Feasibility Test

- Test layout: `data/dungeon_quarter/test_layouts/role_driven_combat_layout_test_01.json`
- Test runner: `tools/RoleCombatLayoutProbe.tscn`
- Probe script: `tools/RoleCombatLayoutProbe.gd`
- New test-only modules in `data/dungeon_quarter/room_blueprints.json`:
  - `room_trap_01`: a true `5x5` trap room using the existing combat-compatible instance id `spike_corridor`.
  - `room_barracks_arena_2x1_01`: a merged `12x5` barracks arena spanning two `5x5` room cells plus the `2`-cell gap.
  - `corridor_gap_ew_2x2_01`: a horizontal `2x2` path-gap segment.
  - `corridor_gap_ns_2x2_01`: a vertical `2x2` path-gap segment.
  - `corridor_barracks_throne_01`: a narrow connector from the merged barracks arena to the throne room.
- Important implementation rule: do not use one global path network for this combat test. Each path between rooms must be its own corridor instance so `ModuleGraph.path_between()` cannot shortcut from entrance to throne through a single shared connector.

Verified routes:

1. Main enemy route: `outside_approach -> entrance -> path_entrance_trap -> spike_corridor -> path_trap_barracks -> barracks -> path_barracks_throne -> throne`
2. Treasure lure route: `entrance -> path_entrance_trap -> spike_corridor -> path_trap_barracks -> barracks -> path_barracks_treasure -> treasure`
3. Recovery retreat route: `barracks -> path_barracks_recovery -> recovery`

Verification commands:

- `godot --headless --path . --run res://tools/RoleCombatLayoutProbe.tscn`: `ROLE_COMBAT_LAYOUT_PROBE: PASS`
- `godot --path . --run res://tools/RoleCombatLayoutCapture.tscn`: `ROLE_COMBAT_LAYOUT_CAPTURE: PASS`
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`

Status:

- The current grid and movement graph can support the requested combat flow.
- `GameRoot` can temporarily register this layout, start combat, route throne-target enemies through trap and barracks, route treasure-target thieves through the lure branch, and apply trap damage in the `spike_corridor` trap room.
- This is not yet the production/default layout.
- This is only a connection proof layout. The production requirement is user-authored placement: the player must be able to place rooms where they want, then connect those rooms with path segments.
- The next product step is not to lock this layout. The next product step is to make room-to-room connection authoring reliable: connected sides open, unconnected sides become walls/rock, and the correct facing/open-mask image variant is selected from the room's placement and connections.

## Runtime Capture Findings

Capture output: `tmp/role_combat_verification/`

- `01_management_role_layout.png`: role layout is applied in the management screen.
- `02_management_role_debug_overlay.png`: room instances, sockets, walkable cells, and path gaps are visible for inspection.
- `03_combat_explorer_throne_path.png`: throne-target enemy receives the throne route.
- `04_combat_thief_treasure_path.png`: treasure-target thief receives the treasure lure route.
- `05_combat_trap_trigger.png`: trap damage can trigger in the `spike_corridor` trap room.

Issues found during visual testing:

1. The graph route is correct, but this test layout must not become a fixed placement rule.
2. The player must be able to choose room placement and then connect rooms manually or through an editor action.
3. Four-direction room/object images exist because the same room role must support arbitrary placement and face the correct direction from that placement.
4. Open-mask variants exist because the same room role must visually change based on which N/E/S/W sides are connected.
5. The `path_barracks_throne` connector is functionally valid, but visually it still reads too much like a long floor slab. It needs a narrower/clearer path art treatment before production approval.
6. Debug overlays confirm walkability, but the non-debug view still needs stronger visual separation between room interiors, paths, closed walls, and empty rock.

## Room/Path Authoring Update

- The first authoring pass is implemented in `GameRoot`.
- The map editor connection action does not create path modules automatically.
- If two rooms have a gap but no manually placed path module between them, connection fails.
- If the user has manually placed `corridor_gap_ew_2x2_01` or `corridor_gap_ns_2x2_01` between rooms, the editor can connect the paired room -> path -> room sockets.
- Disconnecting a selected room removes only authored socket links. It does not delete manually placed path modules.
- `RoomPathAuthoringProbe` verifies no-auto-connect behavior, manual east/west path authoring, manual north/south path authoring, graph pathing, and room `connection_variant` open masks.
- This is still only direct adjacent socket authoring. Manual path placement UI and multi-segment arbitrary route drawing are next steps.

## Required Main Route Repair

- The user can freely connect and disconnect links while editing.
- Automatic path creation is still forbidden during normal edit actions.
- At commit boundaries only, `GameRoot` now repairs the required `entrance -> throne` route:
  - map editor save,
  - combat start,
  - next-day progress from management.
- Repair first connects existing manually placed adjacent path modules.
- If no path module exists and a valid `2x2` gap is available, repair creates one `system_required_path_##` with `system_required: true`.
- The repair connects paired two-cell sockets, preserving the two-cell doorway/path rule.
- This is not a replacement for manual path placement UI. It is a safety rule so the dungeon cannot enter combat or the next day with the main enemy route broken.
