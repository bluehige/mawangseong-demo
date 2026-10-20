# glue_snail / 0101a

- Generation model: GPT internal image generation
- Generated date: 2026-10-17
- Target version: v1.3.0
- Status: ACCEPTED_OFFLINE_NOT_INTEGRATED
- Engine integration: none; Godot not launched.

- Source image path: assets/source/imagegen/v130r_quarter_final/glue_snail/generated_attempt_1.png
- Historical source location: _mockup/monsters_v130r/quarter_final/glue_snail/generated_attempt_1.png
- Source SHA-256: 061c809018a2c1b7a2cb112890170409eee7c0d7a349aa21084b9155ff32c99a
- Source image path: assets/source/imagegen/v130r_quarter_final/glue_snail/generated_attempt_2.png
- Historical source location: _mockup/monsters_v130r/quarter_final/glue_snail/generated_attempt_2.png
- Source SHA-256: b6c4635212d4dc0209c9819e07cecd4ec1d6932acac38f5c36cb63847ee76d52
- Source image path: assets/source/imagegen/v130r_quarter_final/glue_snail/generated_attempt_3.png
- Historical source location: _mockup/monsters_v130r/quarter_final/glue_snail/generated_attempt_3.png
- Source SHA-256: 646e5e260843755c5cff47ff90186ff14fcfb5e29070910e5fcc6b7ba68f901c
- Source image path: _mockup/monsters_v130r/quarter_final/glue_snail/reference.png
- Source image path: _mockup/monsters_v130r/quarter_final/glue_snail/approved_C_camera.png
- Runtime image path: assets/sprites/v130r/quarter_final/glue_snail/glue_snail_sheet.png
- Runtime image path: assets/sprites/v130r/quarter_final/glue_snail/glue_snail_hurt_sw.png
- Runtime image path: assets/sprites/v130r/quarter_final/glue_snail/glue_snail_sheet_ne.png
- Runtime image path: assets/sprites/v130r/quarter_final/glue_snail/glue_snail_hurt_ne.png

Exact prompts and supplied reference roles: _mockup/monsters_v130r/quarter_final/glue_snail/prompts.md
Reference images are crop/resize montages of approved portraits, real v7d map parts and 0098 C originals, not newly painted art. Original image_gen file paths/hashes: generation_attempt_*.json in same mockup species folder.
Processing: rectangular crop, uniform per-image resizing, translation and montage assembly only. Native alpha retained; no painting, warp, mirror or background removal. Patch sources are normalized uniformly to the replaced pose body height; full NE source normalized by idle body height. Faint detached residue outside rectangular significant-component bounds may be omitted; own-body alpha96 loss=0 and foreign primary bodies=0 for all adopted frames.
0096 contract: combat1254x1254;4x4;edges[0,313,627,940,1254];logical frame384x384;logical contact192,345;atlas contact156.5,289. Separate SW/NE hurt1254x313,4frames. Source generation alpha max may be254; never forced opaque.
T/F/H/E/S are visual decisions, not a solved3D camera. Ellipse is partially occluded generated contact shadow; no exact2:1 pixel proof. Details such as tiny moss/flower placement, sheet holes/seams, dotted routes and throne marks vary across generated poses. Existing portraits/cards and historical combat sheets unchanged.
Selected source rectangles and alignment: runtime art_review.json; selection/visual decisions/validation in mockup folder.
