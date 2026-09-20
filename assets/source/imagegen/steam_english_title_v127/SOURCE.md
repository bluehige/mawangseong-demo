# Steam English title artwork

- Generation model: GPT internal image generation
- Generated date: 2026-09-20
- Target version: v1.2.7
- Source image path: assets/source/imagegen/steam_english_title_v127/english_logo_generated.png
- Runtime image path: marketing/steam/english/library/logo.png
- Runtime image path: marketing/steam/english/library/capsule.png
- Runtime image path: marketing/steam/english/library/header.png
- Runtime image path: marketing/steam/english/store/header_capsule.png
- Runtime image path: marketing/steam/english/store/small_capsule.png
- Runtime image path: marketing/steam/english/store/main_capsule.png
- Runtime image path: marketing/steam/english/store/vertical_capsule.png

## Prompt and provenance

Built-in image generation, text-localization edit. Reference: existing Korean Steam library logo.
Replace only the lettering with two lines, exactly **Who Guards** / **the Demon Castle?**.
Preserve the rounded heavy lettering, cream upper line (#fff1ba), gold lower line (#f3c767), purple outline (#311346), and shadow. True transparent background. No additional illustration, slogan, symbols, or watermark.

Generated original: 1672 × 941 RGBA. Original retained unchanged. The existing code-native Steam layout generator imports this wordmark, fits it into a transparent 1280 × 720 logo canvas, bounds its visible lettering using alpha > 32 (without painting over the generated pixels), and composites it into the six established capsule layouts. This threshold avoids almost-transparent stray pixels shrinking the wordmark. Runtime PNGs are optimized losslessly.

The underlying approved illustration is unchanged: `assets/ui/endings/update4/ending_minion_wears_the_crown.png`; original art provenance is `assets/source/imagegen/update4_endings_phase32/SOURCE.md`.

## Reproduction

`python tools/release/generate_steam_graphics.py --english-logo assets/source/imagegen/steam_english_title_v127/english_logo_generated.png`

Only the English sibling directory is written. The Korean artwork remains available.
Verified exact English title, real alpha in the standalone logo, six target sizes, and visual placement.
These are promotional assets, not an in-game language texture switch. Runtime title/UI text uses Godot labels.
