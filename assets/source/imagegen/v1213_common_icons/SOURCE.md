# Common UI icon atlas

Generation model: GPT internal image generation
Generated date: 2026-10-14
Target version: 1.2.12
Source image path: assets/source/imagegen/v1213_common_icons/common_icons_raw.png
Runtime image path: assets/ui/icons/v1213_common.png

## Prompt
Use case: stylized-concept. Asset type: one raster UI icon atlas for a dark fantasy game. Generate a single 4-column by 3-row grid, 12 separate simple recognizable pale warm ivory flat solid icons, bold consistent strokes and silhouettes that read at 32px. Each icon precisely centered in its own equally sized cell with generous transparent padding. Row 1 left to right: dialogue history (open book), settings (gear), menu (three horizontal bars), automatic dialogue (circular arrow surrounding a small play triangle). Row 2: skip dialogue (two rightward triangles), close (X), resume (rightward play triangle), save (floppy disk). Row 3: load (folder with down arrow), title (house), quit (door with rightward exit arrow), reset (counterclockwise arrow). Fully transparent native alpha background including all spaces and margins, no grid lines, no frames, no labels, no letters, no words, no numbers, no shadows, no decorative details, uniform scale. Rectangular 4:3 composition.

## Processing and verification
Native transparent alpha output, RGBA 1448×1086, alpha range 0–255. Runtime is an exact copy; no background removal, recoloring or alpha editing. AtlasTexture divides it into 4×3 cells and renders at 32px. Actual alpha composite on dark UI inspected: clean silhouettes; near-transparent RGB residue in previews does not appear in the game. Two additional generation/edit candidates were inspected and not adopted; original selected. No external API used.

