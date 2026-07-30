# V122 Story Dialogue Phase 0 Source Gate

Date: 2026-07-30
Branch: `codex/v122-ui-simplification`
Base commit: `53facedfa5cbbc67385b9cb42134b7ceac455fe2`

## Owner approval

The owner explicitly approved integrating the current dialogue book:

> 그냥 지금대사집으로 작업하자 진행해

This approval changes the working source status from `OWNER_EDIT_DRAFT` to the
approved integration source for DAY 1-5. It does not authorize rewriting,
correcting, or expanding any spoken line.

## Locked source

- Source: `작업문서/시나리오_v122/V122_MAIN_SCENARIO_DIALOGUE_BOOK_DRAFT_2026-07-30.md`
- SHA-256: `6753f68e5cfb4662ee2ff978af5d39c73d5157bd595995438c1b4bf2de821f58`
- Size: `175141` bytes
- Replacement characters: `0`
- Full-book spoken lines: `1728`
- DAY 1-5 spoken lines: `183`

The repository copy and generated story data must retain this hash in their
manifest. Spoken text and directions are copied verbatim.

## Phase 1-2 scope

In scope:

- Story catalog/director and optional backward-compatible save state
- Full-screen dialogue outside battle
- Battle dialogue overlay that pauses the complete battle simulation
- `대화 알람`, archive/replay, manual advance, read-state skip, opt-in Auto
- DAY 1-5 management, placement, pre-battle, battle, result, and raid triggers
- Direct-impact tests, one 1280x720 Web boot, and quick test publish

Out of scope until owner playtest approval:

- DAY 6-30 integration
- New or rewritten dialogue
- Balance or combat-rule changes
- Update 3/4 expansion work
- Windows/release/Steam builds and broad release QA

## Source-only resolution of known gaps

- DAY 2 treasure-damage branch replaces the conflicting final two common result
  cues. Both variants must never play together.
- DAY 4 selected-monster reactions are additive.
- No new Rolo-only DAY 4 line is authored.
- Missing DAY 2, DAY 4, and DAY 5 defeat/regular-defense result lines continue
  to use the existing legacy path. The new catalog does not fabricate text.
- DAY 4 `전투 중` raid text is delivered as the immediate raid-resolution
  vignette because the raid system has no simulated battle.
- DAY 5 supply-tag text plays immediately after `d05_supply_tag` succeeds.

## Safety and rollback

- Existing tutorial stage IDs remain unchanged.
- The save version remains unchanged; `story` is an optional top-level field.
- Existing onboarding dialogue has priority when restoring an old save.
- Battle dialogue stays on `SCREEN_COMBAT`, sets `combat_paused`, disables unit
  processing, and restores the previous pause/speed state afterward.
- Existing saves do not replay past days automatically.
- The feature can be disabled without deleting legacy dialogue or save fields.

Current battle state is not serialized by the game. An application exit during
a battle therefore restarts that battle and may replay its current short story
group; exact in-memory pause/resume is guaranteed, but exact disk restoration of
the battle itself is outside this phase.
