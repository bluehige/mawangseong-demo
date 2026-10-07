# Simplified Chinese Steam title, local candidate

- Generation model: GPT internal image generation
- Generated date: 2026-10-07
- Target version: v1.2.10
- Source image path: assets/source/imagegen/steam_chinese_title_local_candidate/chinese_logo_generated.png
- Runtime image path: marketing/steam/schinese/library/logo.png
- Runtime image path: marketing/steam/schinese/library/capsule.png
- Runtime image path: marketing/steam/schinese/library/header.png
- Runtime image path: marketing/steam/schinese/store/header_capsule.png
- Runtime image path: marketing/steam/schinese/store/small_capsule.png
- Runtime image path: marketing/steam/schinese/store/main_capsule.png
- Runtime image path: marketing/steam/schinese/store/vertical_capsule.png

This is an unpublished local Chinese addition based on v1.2.9. The immutable v1.2.9 tag and approved Steam binaries are unchanged. The user confirmed v1.2.10 on 2026-10-07; Steam publication is recorded separately.

## Prompt and provenance

Text-localization edit of the existing, publicly used English title wordmark `marketing/steam/english/library/logo.png`. Exact two-line wording: **谁来守护** / **魔王城？**. Preserve playful heavy rounded lettering, cream upper line #fff1ba, gold lower line #f3c767, thick purple outline #311346, soft shadow and centered hierarchy. Real transparent background, clean alpha, no extra illustration or lettering.

The image was viewed before editing. The parent session was informed of the exact public promotional reference and purpose before generation. The built-in tool rejected the Windows reference-path format before dispatch; the already-viewed conversation image was then used as the reference. No private saves, account details or Steam server documents were sent. No external image service, API key or background removal was used.

Original generated PNG retained unchanged. The PowerShell/.NET native layout tool `tools/release/GenerateSteamChineseGraphics.ps1` validates actual alpha-zero pixels, computes visible bounds with alpha >32, resizes onto a transparent 1280×720 library canvas and composites into six capsule sizes. Horizontal layouts give the shorter Chinese two-line wordmark half the image height so the small capsule remains legible. This is native layout and resizing, not a second generated illustration. Underlying approved illustration: `assets/ui/endings/update4/ending_minion_wears_the_crown.png`; art provenance: `assets/source/imagegen/update4_endings_phase32/SOURCE.md`.

The six capsules use the established source artwork and target dimensions; the native Windows compositor uses high-quality bicubic resizing. Korean and English graphics are untouched. These files are promotional siblings, not an in-game texture switch.

## Reproduction

Run `tools/release/GenerateSteamChineseGraphics.ps1` in the selected Windows workspace. It writes only the Chinese sibling graphics and the separate Chinese promo sibling. Keep both generated originals and their source documents. Exact title and dimensions were inspected locally; native-speaker visual acceptance and Steam publication are separate pending decisions.
