# Work Log: Character Art Rules And Classification (2026-07-07)

## Goal

The project is about to add many characters and monsters, so portrait metadata and emotion handling should not keep growing inside `GameRoot.gd`.

This pass creates a data-backed character classification file and a written image-generation rule file for future emotion variants.

## Added

- `data/characters.json`
  - Classifies the current 9 demo core speakers.
  - Separates player avatar, castle staff, monster units, human intruders, and boss rival.
  - Records current base portrait paths, frame accent colors, observed emotions, priority emotion variants, aliases, and generation identity anchors.
- `docs/design/CHARACTER_EMOTION_IMAGE_RULES.md`
  - Defines the project rule for base portraits, emotion variants, naming, prompt shape, transparency, and acceptance checks.
- `tools/CharacterDataSmokeTest.gd`
- `tools/CharacterDataSmokeTest.tscn`
  - Validates that all demo characters are classified.
  - Validates that dialogue speaker emotions are covered by `data/characters.json`.
  - Validates that portrait base files and referenced monster/enemy data exist.

## Changed

- `scripts/core/DataRegistry.gd`
  - Loads `res://data/characters.json`.
  - Adds `character(character_id)`.
- `scripts/game/GameRoot.gd`
  - Removed hard-coded onboarding portrait path and accent dictionaries.
  - Speaker display names, portrait base paths, emotion aliases, and frame accents now come from `DataRegistry.character()`.
  - Emotion variants are supported through `portrait.variants`; current data intentionally falls back to base portraits until variants are generated.
- `assets/sprites/portraits/README.md`
  - Replaced the old placeholder note with the active portrait metadata and naming rules.

## Current Character Classification

- `CHR_DARKLORD_PLAYER`: `player_avatar`
- `CHR_BATI`: `castle_staff`
- `CHR_GOLDIN`: `castle_staff`
- `CHR_PUDDING`: `monster_unit`, references `data/monsters.json -> slime`
- `CHR_GOB`: `monster_unit`, references `data/monsters.json -> goblin`
- `CHR_PYNN`: `monster_unit`, references `data/monsters.json -> imp`
- `CHR_EXPLORER_MILO`: `human_intruder`, references `data/enemies.json -> explorer`
- `CHR_THIEF_NIA`: `human_intruder`, references `data/enemies.json -> thief`
- `CHR_HERO_LEON`: `boss_rival`, references `data/enemies.json -> trainee_hero`

## Verification

Commands run:

```powershell
godot --headless --path . --run res://tools/CharacterDataSmokeTest.tscn
godot --headless --path . --run res://tools/OnboardingFlowSmokeTest.tscn
godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn
godot --path . --run res://tools/OnboardingPortraitCapture.tscn
```

Results:

- `CHARACTER_DATA_SMOKE_TEST: PASS`
- `ONBOARDING_FLOW_SMOKE_TEST: PASS`
- `TUTORIAL_FLOW_SMOKE_TEST: PASS`
- `ONBOARDING_PORTRAIT_CAPTURE` wrote updated screenshots to `tmp/onboarding_portrait_verification`.

Manual visual check:

- `tmp/onboarding_portrait_verification/04_dialogue_bati_portrait.png` still shows Bati portrait, speaker name, dialogue box, and demon-castle scene illustration after moving portrait metadata into `data/characters.json`.

## Remaining Work

- Generate actual emotion variants for high-priority characters.
- Add stage-specific scene illustrations only if the same demon-castle dialogue background becomes unclear.
- Continue reference-based polish for title, name entry, dialogue, and raid preview screens.
