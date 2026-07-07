# Work Log: Onboarding Scene Illustration (2026-07-07)

## Goal

The onboarding dialogue screen had character portraits, but still lacked the reference-required `SceneIllustration` background slot. This pass adds a dedicated demon-castle illustration behind the dialogue UI.

## Asset Generation

Used Codex built-in `image_gen` to generate a 16:9 dark fantasy demon castle interior.

Prompt summary:

- Korean indie game dialogue background.
- Rookie demon lord castle interior with throne platform, black stone, purple torchlight, old banners, ledgers, and slightly comedic shabby details.
- No characters, no portraits, no text, no UI, no watermark.
- Lower 35 percent should remain dark and low-detail so dialogue UI can sit on top.

Generated source was copied from:

- `C:\Users\LDK-6248\.codex\generated_images\019f39bf-e0cb-7791-be8a-bfd263475e9b\ig_0d9a83376c662cb4016a4c4190dfd081919f0afbad34bdf926.png`

Project asset:

- `assets/ui/onboarding/scenes/scene_demon_castle_dialogue.png`
- `assets/ui/onboarding/scenes/scene_demon_castle_dialogue.png.import`

The source was resized/cropped to `1920x1080`.

## Code Changes

- `scripts/game/GameRoot.gd`
  - Added `ONBOARDING_SCENE_BASE`.
  - Added `ONBOARDING_SCENE_ILLUSTRATIONS`.
  - Added `_onboarding_add_scene_illustration()`.
  - Added `_onboarding_dialogue_scene_path()`.
  - `_build_onboarding_dialogue_ui()` now renders `S02_DIALOGUE.SceneIllustration` first, then the tutorial label, portrait, dialogue box, speaker name, text, and next button.

## Verification

Commands:

```powershell
godot --headless --path . --run res://tools/OnboardingFlowSmokeTest.tscn
godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn
godot --path . --run res://tools/OnboardingPortraitCapture.tscn
git diff --check -- scripts/game/GameRoot.gd
```

Results:

- `ONBOARDING_FLOW_SMOKE_TEST: PASS`
- `TUTORIAL_FLOW_SMOKE_TEST: PASS`
- `ONBOARDING_PORTRAIT_CAPTURE` wrote updated screenshots.
- `git diff --check` had no whitespace errors.

Manual screenshot inspection:

- `tmp/onboarding_portrait_verification/04_dialogue_bati_portrait.png` shows the demon-castle scene illustration, Bati portrait, dialogue frame, and readable dialogue text.

## Remaining Work

- Current scene background is shared for all dialogue stages.
- Add stage-specific backgrounds only if the demo needs clear location changes.
- Emotion-specific portrait variants are still not implemented.
- Broader screen polish remains open for `S00_TITLE`, `S01_NAME_ENTRY`, and `S06_RAID_PREVIEW`.
