# 0101c war_drummer provenance

- Generation model: GPT internal image generation
- Generated date: 2026-10-17
- Target version: v1.3.0
- Source image path: assets/source/imagegen/v130r_quarter_final/war_drummer/selected_original.png
- Source image path: _mockup/monsters_v130r/quarter_final/war_drummer/attempt_1.png
- Source image path: _mockup/monsters_v130r/quarter_final/war_drummer/attempt_1_review.png
- Source image path: _mockup/monsters_v130r/quarter_final/war_drummer/identity_idle.png
- Source image path: _mockup/monsters_v130r/quarter_final/war_drummer/reference.png
- Runtime image path: assets/sprites/v130r/quarter_final/war_drummer/war_drummer_hurt_ne.png
- Runtime image path: assets/sprites/v130r/quarter_final/war_drummer/war_drummer_hurt_sw.png
- Runtime image path: assets/sprites/v130r/quarter_final/war_drummer/war_drummer_sheet.png
- Runtime image path: assets/sprites/v130r/quarter_final/war_drummer/war_drummer_sheet_ne.png

Selected attempt: 1; 1 total attempts, maximum 4.
Source originals and exact prompts: `_mockup/monsters_v130r/quarter_final/war_drummer/`.
References: existing uiux3d portrait and combat idle for identity; four real approved map pieces and the three user-approved 0098 C originals for angle.
Processing: rectangular crop, one uniform LANCZOS scale per species, contact translation, non-overlapping direct pixel copy to atlas. No character pixel painting, alpha cleanup, background removal, warping or synthetic animation.
For Rolo and Dudum, connected components determine only rectangle coordinates; the full native original rectangle is copied without applying a mask.
Native transparency verified from RGBA alpha, not from extension or checkerboard.
Frames: SW16 + NE16 + SW hurt4 + NE hurt4. 1254x1254 combat / 1254x313 hurt; cell edges [0,313,627,940,1254]; logical 384x384 anchor (192,345), atlas support (156.5,289).
Candidate final atlas assets, not registered with gameplay. Godot prohibited and never invoked.
Angle T/F/H/E/S judgement is visual; 42 degrees is a generation instruction, not a measured 3D reconstruction. Ellipse is generated partial contact, not a measured perfect 2:1 ellipse.
Map body proxy follows 0098: alpha>=96 and max(R,G,B)>=52, includes visible props, ignores nearly black contact shadow. Uniform target 72 capture pixels for 96px tile width (0.75).
Known generated differences: particles/protective sphere on Pudding; attached flame/healing trails; recoil may rotate faces, and generated rear details/cloth/stone facets are not pixel-identical reconstructions. Original portrait/card/eye-level sheets untouched.
