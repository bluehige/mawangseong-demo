# Work Log: Onboarding Portrait Dialogue UI (2026-07-07)

## Goal

The onboarding dialogue UI was still using placeholder panels where the reference required `SpeakerPortrait` / `BatiPortrait` image slots. This pass added actual portrait assets and connected them to the name-entry and dialogue screens.

## Asset Generation

Used Codex built-in `image_gen` to create a 3x3 portrait sheet, then cropped it into individual 512x512 portrait PNGs.

Prompt summary:

- Dark fantasy comedy, polished painterly 2D game dialogue portraits.
- 3x3 grid in this order: rookie demon lord player, Bati, Goldin, Pudding, Gob, Pynn, explorer Milo, thief Nia, hero Leon.
- No labels, no watermark, one bust portrait per tile.

Generated source was copied from:

- `C:\Users\LDK-6248\.codex\generated_images\019f39bf-e0cb-7791-be8a-bfd263475e9b\ig_0f5c67893bd2d4e7016a4c3e61ff208191abbf04e945b4980b.png`

Project assets were saved under:

- `assets/sprites/portraits/onboarding/`

## Code Changes

- `scripts/game/GameRoot.gd`
  - Added speaker-to-portrait mapping.
  - Added speaker accent mapping.
  - Added `_onboarding_add_portrait()`.
  - Name-entry `BatiPortrait` now uses the Bati image.
  - Dialogue `SpeakerPortrait` now uses the current line's `speaker` id.
  - `emotion` is passed through the portrait path function, but currently falls back to a base portrait.
  - `_load_png()` now prefers `ResourceLoader` and only falls back to direct image loading when needed.

## Visual Verification

Added a dedicated capture scene:

- `tools/OnboardingPortraitCapture.tscn`
- `tools/OnboardingPortraitCapture.gd`

Capture output:

- `tmp/onboarding_portrait_verification/02_name_entry_bati_portrait.png`
- `tmp/onboarding_portrait_verification/03_dialogue_first_portrait.png`
- `tmp/onboarding_portrait_verification/04_dialogue_bati_portrait.png`
- `tmp/onboarding_portrait_verification/05_dialogue_goldin_portrait.png`

Manual inspection confirmed portraits are visible in the expected slots.

## Verification Commands

```powershell
godot --headless --path . --run res://tools/OnboardingFlowSmokeTest.tscn
godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn
godot --path . --run res://tools/OnboardingPortraitCapture.tscn
git diff --check -- scripts/game/GameRoot.gd
```

Results:

- `ONBOARDING_FLOW_SMOKE_TEST: PASS`
- `TUTORIAL_FLOW_SMOKE_TEST: PASS`
- `ONBOARDING_PORTRAIT_CAPTURE` wrote screenshots successfully.
- `git diff --check` had no whitespace errors.

## Remaining Work

- No emotion-specific portraits yet.
- A base `SceneIllustration` background for `S02_DIALOGUE` was added in `docs/WORK_LOG_2026-07-07_ONBOARDING_SCENE_ILLUSTRATION.md`; stage-specific scene backgrounds are still not implemented.
- Character metadata is still hardcoded in `GameRoot.gd`; move it to data once `characters.json` / `dialogue_lines.json` is introduced.
- The broader level-by-level UI reference polish is still incomplete.
