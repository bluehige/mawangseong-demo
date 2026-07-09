# Handoff: DAY 05-07 Campaign, Cast Timing, And Assets

Date: 2026-07-09

## Scope

This pass implements the next regular-campaign bundle after DAY 04:

- DAY 05: first reaction to the signpost expedition.
- DAY 06: Nia's treasure-security retry.
- DAY 07: first facility upgrade consultation and one Lv.2 facility upgrade.

It also adds the missing dialogue portrait variants needed for these appearances.

## Cast And Enemy Timing

| Day | Timing | Cast | Enemy Balance | Asset Coverage |
|---:|---|---|---|---|
| 05 | Management intro and combat start | Bati explains the expedition effect. Milo appears as the lost explorer beat. | Explorer-only pressure: 5 explorers split into an early group and a delayed follow-up. No thief, so the player can feel the DAY 04 expedition modifier without extra treasure pressure. DAY 05 follow-up raid effects are stored for DAY 06+. | `assets/sprites/portraits/onboarding/CHR_EXPLORER_MILO_portrait_panic.png` |
| 06 | Management intro and result emphasis | Nia returns as a teasing security auditor. Goldin reacts to treasury risk. | 3 explorers open the path, then 2 thieves pressure the treasure room. If `d05_supply_tag` was completed on DAY 05, its delayed modifier can add one extra thief here. | `assets/sprites/portraits/onboarding/CHR_THIEF_NIA_portrait_teasing.png`, `assets/sprites/portraits/onboarding/CHR_GOLDIN_portrait_accounting.png` |
| 07 | Management intro before battle | Goldin quotes the upgrade cost. Bati recommends which facility to reinforce. | 4 explorers plus 2 thieves. Slightly stronger than DAY 06 so the new Lv.2 facility is worth noticing. | Goldin accounting portrait reused for cost consultation. |

The runtime data lives in `data/campaign_days.json`. Keep future DAY 08-10 work there first, then wire only the UI/mechanics that the new day actually needs.

## Implemented

- `data/campaign_days.json`
  - Added DAY 05-07 story summaries, management hints, cast timing, enemy plan, combat-start lines, and asset notes.
- `data/waves.json`
  - Added DAY 05, DAY 06, and DAY 07 wave definitions.
- `data/raid_missions.json`
  - `d05_supply_tag` now marks `supply_suspicion.apply_on_day = 6`, so its thief pressure cannot leak into the explorer-only DAY 05 defense.
- `data/characters.json`
  - Registered generated portrait variants for Milo `panic`, Nia `teasing`, and Goldin `accounting`.
- `scripts/core/DataRegistry.gd`
  - Loads `campaign_days` and exposes `campaign_day(day)`.
- `scripts/game/GameRoot.gd`
  - DAY 04+ result flow now advances regular campaign days instead of falling back to management without incrementing.
  - DAY 03 demo-clear victory is reset when entering DAY 04 regular flow.
  - Raid modifiers can declare `apply_on_day`; `d05_supply_tag` is delayed to DAY 06 so DAY 05 stays explorer-only.
  - Active raid modifiers are consumed only when their apply day has arrived.
  - Campaign day intros and combat-start lines are logged once per day.
  - DAY 07 facility upgrade unlock added.
  - Selected facility can be upgraded to Lv.2 once: cost `gold 90 / mana 30`, HP `+80`, max monsters `+1`.
  - Facility replacement resets `facility_level` to `1`.
- `scripts/game/CombatSceneController.gd`
  - Tracks the actual stolen treasure gold during combat, including low-gold clamp cases.
  - Result screen now includes `보물 손실` from DAY 06 onward.
- `scripts/game/ManagementSceneController.gd`
  - Management screen shows campaign notice with day summary, cast, and enemy roster.
  - Campaign notice renders the cast portrait variants from `data/campaign_days.json`.
  - Result screen button copy now distinguishes DAY 04+ regular campaign progression.
- `scripts/ui/HUDController.gd`
  - Selected room panel shows facility level after upgrade unlock.
  - DAY 07+ changeable facilities show `시설 변경` and `시설 강화`.
- `tools/DemoSmokeTest.gd`
  - Added coverage for DAY 04 result -> DAY 05 management progression, DAY 05 raid availability/deferred modifier, DAY 06 thief/treasure result, DAY 07 facility upgrade, and upgrade button state.

## Generated Assets

Generated source folder:

- `C:\Users\LDK-6248\.codex\generated_images\019f441b-2196-7203-bb56-614de18b6132`

Project copies:

- `assets/sprites/portraits/onboarding/CHR_EXPLORER_MILO_portrait_panic.png`
- `assets/sprites/portraits/onboarding/CHR_THIEF_NIA_portrait_teasing.png`
- `assets/sprites/portraits/onboarding/CHR_GOLDIN_portrait_accounting.png`

These were generated as square 1254px dialogue bust portraits. Existing combat sprites for `explorer` and `thief` are already present, so no new enemy combat sheet was needed for DAY 05-07.

## Verification

Local verification completed on 2026-07-09:

- PASS: `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`
- PASS: `godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn`
- PASS: `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`
- PASS: `git diff --check`

`git diff --check` prints CRLF conversion warnings for existing text files, but no whitespace errors.

Review-agent result should be appended by the worker who runs final review for this bundle.

First review-agent pass found five issues and all were addressed:

- DAY 05 follow-up raid modifier now waits for DAY 06+.
- Treasure loss result now reports actual lost gold.
- DAY 05-07 campaign notice now renders cast portrait images.
- DAY 07 upgrade button active/done states are covered by `DemoSmokeTest`.
- Generated portrait size metadata corrected to square 1254px.

Second review-agent pass result:

- PASS: `No findings. 통과입니다.`

## Next Recommended Work

DAY 08-10 should follow this shape:

Use `docs/HANDOFF_NEXT_SESSION_DAY08_10_PLAN_2026-07-09.md` as the next session entry point.

DAY 08-10 has since been implemented. Use `docs/HANDOFF_DAY08_10_CAMPAIGN_INVESTIGATOR_ASSETS_2026-07-09.md` for the completed state and verification record.

1. Put day plan, cast timing, monster usage, enemy roster, balance target, and asset status into `data/campaign_days.json`.
2. Audit `data/monsters.json` and `data/enemies.json` before editing waves. Rolo / `kobold_scout` is the current extra monster candidate; DAY 09 should add a real new enemy class such as `investigator`.
3. Add wave definitions before UI/mechanics, with a target difficulty for DAY 08 growth-read, DAY 09 new-class pressure, and DAY 10 chapter close.
4. Produce and register the required graphics resources. Portrait-only story characters need portrait variants; spawned monster/enemy classes need combat sprites or an explicit tested fallback.
5. Only add a mechanic when the day needs it. DAY 08 likely needs monster growth preview, DAY 09 needs investigator/mixed-role pressure, DAY 10 needs the chapter-end boss/event.
