# Step3 monster inspection panel

Generation model: GPT internal image generation
Generated date: 2026-10-16
Target version: 1.3.0
Source image path: assets/source/imagegen/v130r_step3/monster_info_panel_source.png
Runtime image path: assets/maps/v130r_step3/monster_info_panel.png

Built-in image_gen with transparent_background=true. Native alpha verified 0..255.
Postprocessing: crop transparent outer margin, resize to 800px, crop the painted
rectangular body (0,78,800,548) without the protruding horn margin; no background removal,
generated drawing, text, shape, or button added by code.

Prompt: One empty rectangular dark fantasy monster inspection panel, front-on
flat 2D UI painting, landscape 4:3. Charcoal obsidian interior, narrow worn warm
brass border, restrained purple accents and tiny sculpted monster-horn ornaments
at top corners. Interior almost uniformly dark and uncluttered for Korean game
data. No text, letters, icons, symbols, numbers, buttons, portraits, controls,
grid or partitions. Actual native transparent background outside silhouette,
no checkerboard. Cozy dark fantasy isometric dungeon, entirely contained.

Existing GPT assets reused unchanged: v130r_step2 UI icons/highlight;
uiux_obsidian_20260912 panel/button; v1213_ui_icons role/food/lock/warning icons;
uiux_portraits_20260913, uiux_contract_art_20260913, uiux_completion_20260913,
bebe/koko/toktok, update4_contract_monsters/silky and popo portraits;
uiux_actors3d_20260912 and UIUX completion combat sheets. See their SOURCE.md.
