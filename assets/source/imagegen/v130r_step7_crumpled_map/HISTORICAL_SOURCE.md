> 2026-10-20 release/v1.3.0 exclusion: the two historical PNGs were removed from the branch by user approval. Both remain at tag `v1.3.0`, commit `f048a2b2c870b30c878d56ffab7061e1bb0cd9e5`, under the same paths. The preservation statements below describe the historical commit. Exact SHA-256 values and rationale: `docs/handoff/V130_PR110_MERGE_2026-10-20.md`. PROMPT_V1.txt and PROMPT_V2.txt remain here. Current adopted runtime provenance belongs to Step8.

> Historical 0102 candidate at commit35de2147, superseded by adopted0103 in Step8. The runtime paths below describe that historical commit, not the current pixels. Raw originals and exact prompts remain preserved here. Current provenance: `../v130r_step8_crumpled_map/SOURCE.md`.

# Step7 crumpled map
Generation model: GPT internal image generation
Generated date: 2026-10-17
Target version: 1.3.0
Source image path: assets/source/imagegen/v130r_step7_crumpled_map/generated_atlas_v2.png
Historical runtime image path at 35de2147: assets/sprites/v130r/quarter_final/crumpled_map/crumpled_map_sheet.png
Historical runtime image path at 35de2147: assets/sprites/v130r/quarter_final/crumpled_map/crumpled_map_sheet_ne.png
Historical runtime image path at 35de2147: assets/sprites/v130r/quarter_final/crumpled_map/crumpled_map_hurt_sw.png
Historical runtime image path at 35de2147: assets/sprites/v130r/quarter_final/crumpled_map/crumpled_map_hurt_ne.png

GPT built-in image_gen, two calls, transparent_background=true both. Native v2 alpha is 0..254 (preserved, never forced opaque); 32 poses, 16 per direction. Reference: existing GPT base portrait. PROMPT_V2.txt is the exact adopted prompt. The generator did not use equal row spacing, so equal-grid cropping was rejected before adoption. Only 32 separated body-component bounds with3px raw rectangular padding, alpha-bounds rectangular cropping, proportional resize and sheet composition. No background removal, drawing, opacity changes or external generator. V2 SW is substantially more side-on; one spread-paper skill pose exposes the back fold more prominently. NE shows the back. In-game motion and scale are separately tested.

V1 generated_atlas.png and PROMPT_V1.txt are retained as unadopted process evidence: too frontal and only8 unique poses per direction. Prior 0096/0098/quarter_pilot and 0101 rejected sheets were never imported.
