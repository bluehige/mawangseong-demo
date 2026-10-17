# Step8 adopted 0103 crumpled map

- Generation model: GPT internal image generation
- Generated date: 2026-10-17
- Target version: 1.3.0
- Source image path: assets/source/imagegen/v130r_step8_crumpled_map/generated_attempt_2.png
- Source image path: assets/source/imagegen/v130r_step8_crumpled_map/generated_attempt_3.png
- Source image path: assets/source/imagegen/v130r_step8_crumpled_map/generated_attempt_4.png
- Runtime image path: assets/sprites/v130r/quarter_final/crumpled_map/crumpled_map_sheet.png
- Runtime image path: assets/sprites/v130r/quarter_final/crumpled_map/crumpled_map_sheet_ne.png
- Runtime image path: assets/sprites/v130r/quarter_final/crumpled_map/crumpled_map_hurt_sw.png
- Runtime image path: assets/sprites/v130r/quarter_final/crumpled_map/crumpled_map_hurt_ne.png

Reused, not generated in this session. User-adopted 0103 source: a34444eb (codex/v130r-monsters). Runtime directory copied with the exact requested git checkout command. All four runtime PNGs remain byte-identical to that commit.

Raw selected attempts 2/3/4, exact prompts and the historical assembly script are copied unchanged from the same commit. The original offline evidence is APPROVED_SOURCE_0103.txt; its old source paths are historical and map to these preserved raw PNGs by SHA-256.

Original processing: rectangular crop, one uniform size normalization per generated sheet, translation and direct alpha composition. No additional image processing, background removal, generation or geometry change in Step8. Native RGBA alpha 0..255 checked. SW/NE frames plus the established runtime horizontal flip provide four directions.

The older assets/source/imagegen/v130r_step7_crumpled_map/HISTORICAL_SOURCE.md documents the superseded 0102 candidate at its historical commit. It is not the source of these adopted images.

Integration record: these adopted paths are loaded by ApprovedBattleUnit in Step8. The copied art_review.json status ACCEPTED_OFFLINE_NOT_INTEGRATED describes the source branch at0103; it is historical, not the current integration result.
