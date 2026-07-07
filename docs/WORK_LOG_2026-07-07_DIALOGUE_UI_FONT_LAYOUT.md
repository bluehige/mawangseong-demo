# Work Log: Dialogue UI Font And Layout Fix (2026-07-07)

## Goal

Fix the onboarding dialogue UI so dialogue text stays inside the dialogue frame and the box can handle up to four visible lines.

Also connect the requested NEXON MapleStory font split:

- Normal dialogue/body text: light font
- Emphasis and buttons: bold font

## Font Changes

Added project font assets copied from `참고자료/font/NEXON_Maplestory.zip`:

- `assets/fonts/NEXON_Maplestory_Light.otf`
- `assets/fonts/NEXON_Maplestory_Bold.otf`

Added import sidecars:

- `assets/fonts/NEXON_Maplestory_Light.otf.import`
- `assets/fonts/NEXON_Maplestory_Bold.otf.import`

Added `scripts/ui/UIFont.gd` as the central role map:

- `body -> NEXON_Maplestory_Light.otf`
- `dialogue -> NEXON_Maplestory_Light.otf`
- `emphasis -> NEXON_Maplestory_Bold.otf`
- `button -> NEXON_Maplestory_Bold.otf`
- `fallback -> NotoSansCJKkr-Regular.otf`

Added `assets/fonts/README.md` so future font swaps start from `scripts/ui/UIFont.gd`.

## Dialogue Layout Changes

Updated `S02_DIALOGUE` runtime rects in `참고자료/onboarding_flow_dialogue_v0.4.json` and the matching reference table in `참고자료/01_onboarding_level_dialogue_ui_v0.4.md`:

- `SpeakerPortrait`: `[96, 656, 270, 340]`
- `DialogueBox`: `[380, 672, 1444, 324]`
- `SpeakerName`: `[560, 724, 520, 42]`
- `DialogueText`: `[560, 786, 1048, 144]`
- `NextIndicator`: `[1688, 932, 100, 32]`

The dialogue body now uses a `RichTextLabel` helper (`HUDController.rich_label`) instead of the generic single-label path, because the old label path could visually overrun the right side of the frame for long dialogue.

## Capture Tool Update

`tools/OnboardingPortraitCapture.gd` now also writes:

- `tmp/onboarding_portrait_verification/11_dialogue_four_line_layout_check.png`

This is a layout stress shot with four explicit dialogue lines to verify that the text stays inside the frame.

## Verification

- `Get-Content -Raw -Encoding UTF8 참고자료/onboarding_flow_dialogue_v0.4.json | ConvertFrom-Json`: PASS
- `godot --headless --path . --import --quit`: PASS after removing temporary extracted font files from `tmp/`.
- `godot --headless --path . --run res://tools/CharacterDataSmokeTest.tscn`: `CHARACTER_DATA_SMOKE_TEST: PASS`
- `godot --headless --path . --run res://tools/OnboardingFlowSmokeTest.tscn`: `ONBOARDING_FLOW_SMOKE_TEST: PASS`
- `godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn`: `TUTORIAL_FLOW_SMOKE_TEST: PASS`
- `godot --path . --run res://tools/OnboardingPortraitCapture.tscn`: `ONBOARDING_PORTRAIT_CAPTURE` completed with exit code 0.

Manual visual check:

- `tmp/onboarding_portrait_verification/11_dialogue_four_line_layout_check.png` shows four dialogue lines inside the dialogue frame.
- Speaker names and title text use the bold role.
- Dialogue body text uses the light role.
- Buttons use the bold role.

## Next Work

Continue character emotion variants. The user requested moving to the goblin image after this UI/font fix.
