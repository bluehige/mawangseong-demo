# Handoff: Facility Combat Balance Pass

Date: 2026-07-08

## User Problem

The user clarified that current building objects still feel like monster start points only. Facilities need direct combat value so placement decisions matter during battle, not only during setup.

## Implemented Direction

Facility roles are now connected to combat modifiers and the early tutorial waves were retuned so active use of facilities, directives, and skills can cut a roughly one-minute battle down to the low 30-second range.

- Barracks is the main holdout room.
- Watch post is the front-line control room.
- Treasure remains the thief objective and defense-risk room.
- Recovery remains the retreat/healing room.
- Build slot remains an empty/temporary state and should not accept monster deployment.

## Combat Effects Added

- Barracks
  - Monsters fighting inside the barracks deal `+25%` damage.
  - Monsters inside the barracks take `-18%` incoming damage.
  - Trap-lure support logic now resolves the active barracks room dynamically instead of assuming the original hardcoded room forever.

- Watch post
  - Enemies inside the watch post room or any adjacent room are slowed to `72%` movement speed.
  - Monsters deal `+18%` damage to enemies inside that watch-post pressure area.

- Recovery
  - Existing combat healing remains active: monsters in the recovery room heal `8 HP/sec`.
  - This is now covered by smoke-test assertions.

- Treasure
  - Existing thief objective behavior remains active.
  - The UI description now states the real risk: thieves target the room and can steal gold if ignored.

## Files Changed

- `scripts/game/CombatSceneController.gd`
  - Added facility combat constants.
  - Added dynamic barracks room helper.
  - Added facility attack and damage-taken modifiers.
  - Added watch-post pressure-area slow application.
  - Increased active-skill payoff:
    - Goblin quick slash multiplier `1.6 -> 1.9`.
    - Imp fireball damage `38 -> 52`.
    - Imp flame zone damage `22 -> 34`.
  - Increased trap payoff:
    - Basic spike trap damage `12 -> 14`.
    - Trap-lure spike trap damage `24 -> 30`.
  - Updated flame-zone and trap-lure references to use the active barracks facility room.

- `scripts/game/GameRoot.gd`
  - Updated facility descriptions so the UI states actual combat effects:
    - Barracks: attack bonus and damage reduction.
    - Watch post: slow aura and damage bonus.
    - Treasure: thief target and steal risk.
    - Recovery: combat healing.
    - Build slot: empty state, no monster placement.

- `data/waves.json`
  - Shortened early tutorial wave pacing.
  - Moved Day 2 thief pressure earlier so a good defense can resolve in the 30-second range instead of being hard-blocked by a 42-second thief spawn.
  - Reduced Day 3 assisted-wave HP scales and moved the trainee hero spawn earlier.

- `data/skills.json`
  - Reduced active attack skill cooldowns:
    - Goblin quick slash `6s -> 5s`.
    - Imp fireball `5s -> 4s`.
    - Imp flame zone `14s -> 10s`.

- `tools/BalanceSimulation.gd`
  - Retuned assert ranges:
    - Day 1 auto is allowed to remain a longer baseline.
    - Day 2 trap/directive and Day 3 assisted are expected to land in 30-45 seconds.
  - Day 3 assisted now uses active skills instead of imp-only skill usage.
  - Trap-lure setup builds a watch post on `slot_01` to represent a player using construction plus directives together.

- `tools/DemoSmokeTest.gd`
  - Added direct assertions for:
    - Barracks attack bonus.
    - Barracks damage reduction.
    - Watch-post enemy slow.
    - Watch-post damage bonus.
    - Recovery-room healing.

## Verification

Passed:

- `godot --headless --path . --scene tools/DemoSmokeTest.tscn`
- `godot --headless --path . --scene tools/TutorialFlowSmokeTest.tscn`
- `godot --headless --path . --scene tools/RoleCombatLayoutProbe.tscn`
- `godot --headless --path . --scene tools/QuarterModuleSmokeTest.tscn`
- `godot --headless --path . --scene tools/BalanceSimulation.tscn -- --assert-tutorial-balance`

Balance assert results:

| Scenario | Result | Time | Throne HP | Monster Down | Enemies | Notes |
|---|---:|---:|---:|---:|---:|---|
| DAY1_AUTO | WIN | 56.7s | 1500 | 1 | 2/2 | Baseline auto defense |
| DAY2_TRAP_DIRECTIVE | WIN | 33.8s | 1500 | 0 | 3/3 | Trap lure + watch post |
| DAY3_ASSISTED | WIN | 32.2s | 1500 | 1 | 5/5 | Trap lure + watch post + active skills |

## Known Existing Warning

Godot still prints `Loaded resource as image file, this will not work on export` for several UI skin PNGs loaded through `HUDController.gd:_skin_texture()`. This warning existed before this pass and did not block the tests above.

## Not Done

- No web export or GitHub Pages deploy was done in this pass.
- Facility effects are no longer purely conservative. They are tuned to be clearly felt in tutorial combat, but still avoid rewriting the wave/combat system.
- Longer-term balance still needs player-feel tuning after manual playtests, especially once more facility types or enemy abilities are added.

## Suggested Next Work

- Add visible combat feedback when a facility effect is active, such as a small room label or enemy status marker.
- Add post-battle stat lines showing how much each facility contributed.
- Add more risk/reward for treasure defense, for example bonus gold if thieves are stopped before reaching the treasure room.
- Consider watch-post upgrades later instead of increasing the base slow too much.
