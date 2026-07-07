# Handoff: Onboarding Portrait Dialogue UI (2026-07-07)

This file is the required next-session handoff for the onboarding/dialogue portrait work. Read it before continuing UI, dialogue, or character-art work.

## Current Status

- Onboarding level flow and dialogue data were already connected before this pass.
- This pass added actual character portrait assets and connected them to the onboarding name-entry and dialogue UI.
- The dialogue UI now renders a portrait image for known `CHR_*` speakers instead of a placeholder text-only panel.
- Follow-up work added a base `SceneIllustration` background for `S02_DIALOGUE`.
- The implementation still uses one base portrait per character. Emotion-specific portrait variants are not implemented yet.
- The dialogue scene illustration is currently one shared demon-castle interior image, not stage-specific background art.

## Files Added

- `assets/sprites/portraits/onboarding/portrait_sheet_onboarding_core.png`
- `assets/sprites/portraits/onboarding/portrait_darklord_player.png`
- `assets/sprites/portraits/onboarding/portrait_bati.png`
- `assets/sprites/portraits/onboarding/portrait_goldin.png`
- `assets/sprites/portraits/onboarding/portrait_pudding.png`
- `assets/sprites/portraits/onboarding/portrait_gob.png`
- `assets/sprites/portraits/onboarding/portrait_pynn.png`
- `assets/sprites/portraits/onboarding/portrait_explorer_milo.png`
- `assets/sprites/portraits/onboarding/portrait_thief_nia.png`
- `assets/sprites/portraits/onboarding/portrait_hero_leon.png`
- Matching `.png.import` files for the new portrait PNGs.
- `assets/ui/onboarding/scenes/scene_demon_castle_dialogue.png`
- `assets/ui/onboarding/scenes/scene_demon_castle_dialogue.png.import`
- `tools/OnboardingPortraitCapture.gd`
- `tools/OnboardingPortraitCapture.tscn`

## Files Changed

- `scripts/game/GameRoot.gd`
  - Added `ONBOARDING_PORTRAIT_PATHS`.
  - Added speaker accent mapping for portrait frames.
  - Replaced name-entry `BatiPortrait` placeholder with the Bati portrait image.
  - Replaced dialogue `SpeakerPortrait` placeholder with character portrait rendering.
  - Added `ONBOARDING_SCENE_ILLUSTRATIONS`.
  - Added `S02_DIALOGUE.SceneIllustration` rendering behind the dialogue UI.
  - Added `_onboarding_add_portrait()`, `_onboarding_speaker_portrait_path()`, and `_onboarding_speaker_accent()`.
  - Added `_onboarding_add_scene_illustration()` and `_onboarding_dialogue_scene_path()`.
  - Strengthened `_load_png()` so fresh PNG assets can be used before/without editor import cache, while still preferring `ResourceLoader` when available.

## Verification Performed

- `godot --headless --path . --run res://tools/OnboardingFlowSmokeTest.tscn`
  - Result: `ONBOARDING_FLOW_SMOKE_TEST: PASS`
- `godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn`
  - Result: `TUTORIAL_FLOW_SMOKE_TEST: PASS`
- `godot --path . --run res://tools/OnboardingPortraitCapture.tscn`
  - Result: `ONBOARDING_PORTRAIT_CAPTURE` wrote screenshots to `tmp/onboarding_portrait_verification`.
- `git diff --check -- scripts/game/GameRoot.gd`
  - Result: no whitespace errors; Git printed only the existing CRLF normalization warning.

## Screenshot Evidence

The screenshot folder is ignored by Git, but exists locally:

- `tmp/onboarding_portrait_verification/01_title.png`
- `tmp/onboarding_portrait_verification/02_name_entry_bati_portrait.png`
- `tmp/onboarding_portrait_verification/03_dialogue_first_portrait.png`
- `tmp/onboarding_portrait_verification/04_dialogue_bati_portrait.png`
- `tmp/onboarding_portrait_verification/05_dialogue_goldin_portrait.png`

Observed manually:

- Name-entry screen shows Bati portrait.
- Dialogue screen shows player/darklord portrait.
- Dialogue screen shows Bati portrait.
- Dialogue screen shows Goldin portrait.
- Dialogue screen shows the new demon-castle `SceneIllustration` behind the UI.

## Required Next Work

1. Add emotion-specific portrait variants, or define an explicit rule that the demo uses one base portrait per character.
2. Move portrait metadata out of `GameRoot.gd` into a data file if the project starts using `characters.json` / `dialogue_lines.json`.
3. Add stage-specific scene illustrations if the demo needs different backgrounds for management, battle, result, or raid-preview dialogue beats. The current implementation uses one shared demon-castle interior.
4. Continue reference-based polish for `S00_TITLE`, `S01_NAME_ENTRY`, `S02_DIALOGUE`, and `S06_RAID_PREVIEW`.
5. Re-run `tools/OnboardingPortraitCapture.tscn` after any dialogue UI layout changes and inspect the PNGs before reporting completion.

## Do Not Forget

- Do not report the onboarding UI as complete until emotion handling, stage-specific art policy, and per-screen reference polish are explicitly addressed or intentionally scoped out.
- Do not remove the capture tool unless another visual verification path replaces it.
- Do not rely only on smoke tests for UI work. The screenshot pass is required for this area.
