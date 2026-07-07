# Handoff: Onboarding Portrait Dialogue UI (2026-07-07)

This file is the required next-session handoff for the onboarding/dialogue portrait work. Read it before continuing UI, dialogue, or character-art work.

## Current Status

- Onboarding level flow and dialogue data were already connected before this pass.
- This pass added actual character portrait assets and connected them to the onboarding name-entry and dialogue UI.
- The dialogue UI now renders a portrait image for known `CHR_*` speakers instead of a placeholder text-only panel.
- Follow-up work added a base `SceneIllustration` background for `S02_DIALOGUE`.
- Follow-up work moved character display names, portrait paths, frame accents, observed emotions, and classification into `data/characters.json`.
- Follow-up work added the first real emotion portrait batch for `CHR_DARKLORD_PLAYER` and `CHR_BATI`.
- Follow-up work added the second real emotion portrait batch for `CHR_HERO_LEON`.
- Follow-up work fixed the `S02_DIALOGUE` dialogue frame so body text stays inside the frame, then made the frame taller so four visible lines have breathing room.
- Follow-up work added NEXON MapleStory font roles: light for normal body/dialogue text and bold for emphasis/buttons.
- Follow-up work added the `CHR_GOB` `eager` emotion portrait variant and verified it in the dialogue UI.
- Characters without generated variants still fall back to base portraits through the data-backed rule.
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
- `assets/sprites/portraits/onboarding/CHR_HERO_LEON_portrait_heroic.png`
- `assets/sprites/portraits/onboarding/CHR_HERO_LEON_portrait_flustered.png`
- `assets/sprites/portraits/onboarding/CHR_HERO_LEON_portrait_manual.png`
- `assets/sprites/portraits/onboarding/CHR_HERO_LEON_portrait_determined.png`
- `assets/sprites/portraits/onboarding/CHR_HERO_LEON_portrait_defeated.png`
- Matching `.png.import` files for the Leon emotion variants.
- `assets/ui/onboarding/scenes/scene_demon_castle_dialogue.png`
- `assets/ui/onboarding/scenes/scene_demon_castle_dialogue.png.import`
- `data/characters.json`
- `docs/design/CHARACTER_EMOTION_IMAGE_RULES.md`
- `docs/WORK_LOG_2026-07-07_CHARACTER_ART_RULES.md`
- `docs/WORK_LOG_2026-07-07_ONBOARDING_EMOTION_VARIANTS_BATCH1.md`
- `docs/WORK_LOG_2026-07-07_ONBOARDING_EMOTION_VARIANTS_BATCH2.md`
- `docs/WORK_LOG_2026-07-07_DIALOGUE_UI_FONT_LAYOUT.md`
- `docs/WORK_LOG_2026-07-07_ONBOARDING_EMOTION_VARIANTS_GOB.md`
- `tools/CharacterDataSmokeTest.gd`
- `tools/CharacterDataSmokeTest.tscn`
- `tools/OnboardingPortraitCapture.gd`
- `tools/OnboardingPortraitCapture.tscn`
- `assets/fonts/NEXON_Maplestory_Light.otf`
- `assets/fonts/NEXON_Maplestory_Bold.otf`
- Matching `.otf.import` files for the NEXON fonts.
- `assets/fonts/README.md`
- `scripts/ui/UIFont.gd`
- `assets/sprites/portraits/onboarding/CHR_GOB_portrait_eager.png`
- `assets/sprites/portraits/onboarding/CHR_GOB_portrait_eager.png.import`

## Files Changed

- `scripts/game/GameRoot.gd`
  - Added initial portrait rendering, then moved speaker names, portrait paths, frame accents, emotion aliases, and base fallback behavior to `DataRegistry.character()`.
  - Replaced name-entry `BatiPortrait` placeholder with the Bati portrait image.
  - Replaced dialogue `SpeakerPortrait` placeholder with character portrait rendering.
  - Emotion-specific portrait variants are now selected through `portrait.variants` and `portrait.emotion_aliases`.
  - Added `ONBOARDING_SCENE_ILLUSTRATIONS`.
  - Added `S02_DIALOGUE.SceneIllustration` rendering behind the dialogue UI.
  - Added `_onboarding_add_portrait()`, `_onboarding_speaker_portrait_path()`, and `_onboarding_speaker_accent()`.
  - Added `_onboarding_add_scene_illustration()` and `_onboarding_dialogue_scene_path()`.
  - Strengthened `_load_png()` so fresh PNG assets can be used before/without editor import cache, while still preferring `ResourceLoader` when available.
- `tools/OnboardingPortraitCapture.gd`
  - Added five Leon dialogue UI capture shots for `heroic`, `flustered`, `manual`, `determined`, and `defeated`.
  - The Leon capture helper selects real dialogue lines by stage, trigger, speaker, and emotion.
  - Added `11_dialogue_four_line_layout_check.png` to verify four-line dialogue text stays inside the frame.
  - Added `12_dialogue_gob_eager_portrait.png` to verify `CHR_GOB.eager` in the dialogue UI.
- `scripts/ui/HUDController.gd`
  - Added font-role support and `rich_label()` for dialogue body text.
  - Buttons now use the bold UI font role.
- `scripts/ui/UIFont.gd`
  - Centralizes `body`, `dialogue`, `emphasis`, `button`, and `fallback` font roles.
- `참고자료/onboarding_flow_dialogue_v0.4.json`
  - Updated `S02_DIALOGUE` rects for a larger dialogue box and frame-safe text area.
- `참고자료/01_onboarding_level_dialogue_ui_v0.4.md`
  - Updated the matching `S02_DIALOGUE` rect reference table.
- `scripts/core/DataRegistry.gd`
  - Added `characters` loading from `res://data/characters.json`.
  - Added `character(character_id)`.
- `assets/sprites/portraits/README.md`
  - Documents current base portrait files and future emotion-variant naming.

## Verification Performed

- `godot --headless --path . --run res://tools/OnboardingFlowSmokeTest.tscn`
  - Result: `ONBOARDING_FLOW_SMOKE_TEST: PASS`
- `godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn`
  - Result: `TUTORIAL_FLOW_SMOKE_TEST: PASS`
- `godot --headless --path . --run res://tools/CharacterDataSmokeTest.tscn`
  - Result: `CHARACTER_DATA_SMOKE_TEST: PASS`
- `godot --path . --run res://tools/OnboardingPortraitCapture.tscn`
  - Result: `ONBOARDING_PORTRAIT_CAPTURE` wrote screenshots to `tmp/onboarding_portrait_verification`.
  - Latest run completed with exit code 0 after Leon emotion variants were wired.
- `python -m json.tool data/characters.json`
  - Result: PASS after Leon variant data was added.
- `godot --headless --path . --import --quit`
  - Result: completed; new Leon `.png.import` files generated.
- `godot --headless --path . --import --quit`
  - Result: completed after the NEXON MapleStory font files were added.
- `git diff --check -- scripts/game/GameRoot.gd`
  - Result: no whitespace errors; Git printed only the existing CRLF normalization warning.

## Screenshot Evidence

The screenshot folder is ignored by Git, but exists locally:

- `tmp/onboarding_portrait_verification/01_title.png`
- `tmp/onboarding_portrait_verification/02_name_entry_bati_portrait.png`
- `tmp/onboarding_portrait_verification/03_dialogue_first_portrait.png`
- `tmp/onboarding_portrait_verification/04_dialogue_bati_portrait.png`
- `tmp/onboarding_portrait_verification/05_dialogue_goldin_portrait.png`
- `tmp/onboarding_portrait_verification/06_dialogue_leon_heroic_portrait.png`
- `tmp/onboarding_portrait_verification/07_dialogue_leon_flustered_portrait.png`
- `tmp/onboarding_portrait_verification/08_dialogue_leon_manual_portrait.png`
- `tmp/onboarding_portrait_verification/09_dialogue_leon_determined_portrait.png`
- `tmp/onboarding_portrait_verification/10_dialogue_leon_defeated_portrait.png`
- `tmp/onboarding_portrait_verification/11_dialogue_four_line_layout_check.png`
- `tmp/onboarding_portrait_verification/12_dialogue_gob_eager_portrait.png`
- `tmp/portrait_variant_leon_contact_sheet_2026-07-07.png`
- `tmp/onboarding_leon_dialogue_capture_contact_sheet_2026-07-07.png`
- `tmp/portrait_variant_gob_contact_sheet_2026-07-07.png`

Observed manually:

- Name-entry screen shows Bati portrait.
- Dialogue screen shows player/darklord portrait.
- Dialogue screen shows Bati portrait.
- Latest screenshots show the Darklord `proud` emotion variant and Bati `dry` emotion variant.
- Dialogue screen shows Goldin portrait.
- Dialogue screen now shows Leon's `heroic`, `flustered`, `manual`, `determined`, and `defeated` emotion portraits.
- Dialogue screen text now sits inside the dialogue frame.
- Four-line dialogue layout was visually checked in `11_dialogue_four_line_layout_check.png`, with the taller frame applied.
- Normal dialogue text uses the NEXON MapleStory light font; speaker/emphasis/button text uses the bold font role.
- Dialogue screen now shows the `CHR_GOB` `eager` portrait variant for the real `select_goblin` line.
- Dialogue screen shows the new demon-castle `SceneIllustration` behind the UI.

## Required Next Work

1. Continue actual emotion-specific portrait variants for the remaining `variant_priority` entries in `data/characters.json`; next recommended target is `CHR_GOLDIN` (`accounting`, `panic`, `relieved`) unless UI polish gets reprioritized.
2. Add new characters only through `data/characters.json` first; do not add new hard-coded `CHR_*` branches in `GameRoot.gd`.
3. Add stage-specific scene illustrations if the demo needs different backgrounds for management, battle, result, or raid-preview dialogue beats. The current implementation uses one shared demon-castle interior.
4. Continue reference-based polish for `S00_TITLE`, `S01_NAME_ENTRY`, `S02_DIALOGUE`, and `S06_RAID_PREVIEW`.
5. Re-run `tools/CharacterDataSmokeTest.tscn` and `tools/OnboardingPortraitCapture.tscn` after any character, portrait, or dialogue UI changes.

## Do Not Forget

- Do not report the onboarding UI as complete until the remaining high-priority emotion variants, stage-specific art policy, and per-screen reference polish are explicitly addressed or intentionally scoped out.
- Do not remove the capture tool unless another visual verification path replaces it.
- Do not rely only on smoke tests for UI work. The screenshot pass is required for this area.
