# Castle Visual Contract QA Report

Date: 2026-07-08

## Scope

This pass checked and generated proof material for the remaining castle upgrade asset risks:

- `NW/NE/SE/SW` object-facing direction values;
- room `open_mask` and doorway side rules;
- current road/path connection data;
- 5x5 full-grid room socket placement;
- gpt-image-2 proof images for review.

## Data Contract Result

Automated contract validation passed:

```text
PASS 62 / 62
```

Validation output:

- `output/imagegen/castle_contract_qa/castle_visual_contract_validation.md`
- `output/imagegen/castle_contract_qa/castle_visual_contract_validation.json`
- `output/imagegen/castle_contract_qa/castle_contract_room_grid_overlay.png`
- `output/imagegen/castle_contract_qa/castle_contract_path_skeleton_overlay.png`

Confirmed data rules:

- Throne: `throne_f`, facing `SW`, open mask `04`, open side `S`.
- Barracks: `weapon_rack`, facing `SE`, open mask `02`, open side `E`.
- Recovery: `recovery_nest_f`, facing `NW`, open mask `08`, open side `W`.
- Entrance: `entrance_gate_f`, facing `SE`, open mask `10`, open sides `E,W`.
- Treasure: `treasure_pile_large`, facing `NW`, open mask `08`, open side `W`.
- Build slot: `foundation_marks`, facing `NE`, open mask `01`, open side `N`.
- Path bridge segments: `14`.
- Paired path-mouth groups: `7`.
- Current path module: `corridor_gap_network_01`.
- Current path floor cells: `88` sparse route cells inside a `28x26` module.
- Current trap cells: `4`.

## Generated Proof Assets

All images were generated with built-in imagegen/gpt-image-2 route and copied into the workspace.

Source files:

- `docs/concepts/castle_upgrade_direction_facing_atlas_stage01_gpt_image2_2026-07-08_source.png`
- `docs/concepts/castle_upgrade_default_room_variants_stage01_gpt_image2_2026-07-08_source.png`
- `docs/concepts/castle_upgrade_throne_open_mask_16_stage01_gpt_image2_2026-07-08_source.png`
- `docs/concepts/castle_upgrade_full_path_layout_stage01_gpt_image2_2026-07-08_source.png`
- `docs/concepts/castle_upgrade_path_component_atlas_stage01_gpt_image2_2026-07-08_source.png`
- `docs/concepts/castle_upgrade_throne_facing_atlas_stage01_gpt_image2_2026-07-08_source.png`
- `docs/concepts/castle_upgrade_throne_sw_stage01_gpt_image2_2026-07-08_source.png`

Alpha-processed files:

- `output/imagegen/castle_upgrade_direction_facing_atlas_stage01_gpt_image2_2026-07-08_alpha.png`
- `output/imagegen/castle_upgrade_default_room_variants_stage01_gpt_image2_2026-07-08_alpha.png`
- `output/imagegen/castle_upgrade_throne_open_mask_16_stage01_gpt_image2_2026-07-08_alpha.png`
- `output/imagegen/castle_upgrade_path_component_atlas_stage01_gpt_image2_2026-07-08_alpha.png`
- `output/imagegen/castle_upgrade_throne_facing_atlas_stage01_gpt_image2_2026-07-08_alpha.png`
- `output/imagegen/castle_upgrade_throne_sw_stage01_gpt_image2_2026-07-08_alpha.png`

Sliced proof folder:

- `output/imagegen/castle_contract_proofs/`

Sliced proof counts:

- direction-facing object proofs: `28`;
- default room variant proofs: `6`;
- throne open-mask proofs: `16`;
- path component proofs: `8`;
- throne direction target proofs: `5`.

Tool:

- `tools/slice_and_validate_castle_contract_proofs.py`

## Visual QA Decision

### 1. Direction-Facing Atlas

Status: **proof-only, not production-approved**.

The broad 7x4 atlas is useful for visual exploration, but it is not reliable enough for production direction slicing.

Issues:

- Some objects read more like stage variants than true rotations.
- Some facings are visually too similar.
- Direction labels are not guaranteed by the image; they are only inferred from the prompt and sheet order.

Do not wire these into runtime.

### 2. Throne Direction

Status: **single SW proof accepted for direction reference only**.

The four-facing throne sheet failed strict column accuracy. The model repeated or confused directions.

The single target file is the strongest current correction for the user's repeated throne complaint:

- `output/imagegen/castle_contract_proofs/throne_direction_target_stage01/throne_f_stage01_SW_single_target_proof.png`

It clearly reads as lower-left/SW-facing. However, it is still too ornate for a final Stage 01 asset and should be restyled before runtime use.

### 3. Default Room Variants

Status: **composition proof only**.

The six default room proofs show the intended full-grid room scale and role composition, but they should not be used as runtime sprites yet.

Reasons:

- doorway openings are not exact enough for the paired two-cell socket contract;
- generated rooms still trend closer to Stage 02 polish than rough Stage 01 cave;
- no split back/front layer validation;
- no exact projection fit against Godot 5x5 room bounds.

### 4. Throne 16 Open-Mask Sheet

Status: **failed for production use**.

The data contract for all 16 masks is correct, but the generated image sheet is not visually reliable enough.

Issues:

- several masks look too similar;
- some openings are ambiguous;
- exact paired socket positions cannot be trusted.

Conclusion: do not mass-generate all open masks as complete room images. Use modular wall shells and doorway overlays.

### 5. Path Component Atlas

Status: **best current production direction, still proof-only**.

The generated path components are readable:

- north-south strip;
- east-west strip;
- 2x2 junction;
- N/E/S/W doorway mouths;
- 2x2 spike insert.

They still need exact grid slicing and scale checks before runtime.

### 6. Full Path Layout Concept

Status: **concept pass, not grid-exact**.

The full layout proof communicates the intended player-facing idea: six rooms connected by a narrow path network inside cave void.

It is not a production map because it is not derived from exact `corridor_gap_network_01.floor_cells`.

## Updated Contract Notes

`docs/IMAGEGEN_CONTRACT_FULL_GRID_PATH_CONNECTIONS_01.md` was updated to the current path module:

- old reference: `corridor_spike_ns_01`, `5x10`;
- current reference: `corridor_gap_network_01`, `28x26`, sparse route cells.

The old 5x10 table should not be used for future generation.

## QA Rejection Fix Applied

After the proof-only QA decision, a separate limited runtime pass was made for the current default Stage 01 layout. This pass does not approve the broad direction atlas or 16-open-mask sheet. It only approves six single-target sprites that match the current default layout contract:

- Entrance: `entrance_gate_f`, facing `SE`, runtime layer `back`.
- Throne: `throne_f`, facing `SW`, runtime layer `back`.
- Barracks: `weapon_rack`, facing `SE`, runtime layer `back`.
- Recovery: `recovery_nest_f`, facing `NW`, runtime layer `front`.
- Treasure: `treasure_pile_large`, facing `NW`, runtime layer `front`.
- Build slot: `foundation_marks`, facing `NE`, runtime layer `back`.

Runtime assets:

- `assets/props/stage_01/prop_entrance_gate_stage01_SE_back.png`
- `assets/props/stage_01/prop_throne_stage01_SW_back.png`
- `assets/props/stage_01/prop_weapon_rack_stage01_SE_back.png`
- `assets/props/stage_01/prop_recovery_nest_stage01_NW_front.png`
- `assets/props/stage_01/prop_treasure_pile_stage01_NW_front.png`
- `assets/props/stage_01/prop_foundation_marks_stage01_NE_back.png`

Runtime wiring:

- `GameRoot.castle_art_stage` defaults to `stage_01_cave`.
- `asset_manifest.json` uses `stage_facing_sprites.stage_01_cave` for the six approved default-layout sprites.
- `QuarterDungeonRenderer` resolves `propstage:<prop>:<stage>:<facing>:<layer>` before the legacy `facing_sprites` fallback.
- `_complete_override: true` suppresses old fallback layers for these six stage sprites. This is especially important for `throne_f`, because the previous front layer could visually contradict the corrected SW-facing throne.

Preview and visual capture:

- Runtime-prepared sprite preview: `output/imagegen/stage01_runtime_applied_preview.png`
- Applied management capture: `tmp/manual_verification/01_management.png`

Additional visual correction:

- The first runtime throne candidate was direction-correct but still too polished for `stage_01_cave`.
- It was replaced with a lower-tier cave throne: rough stone, wood, bones, torn cloth, and small crystals, still facing `SW`.

## Next Production Step

Recommended next work:

1. Keep the six Stage 01 default-layout sprites connected while production art is expanded.
2. Use `path_components_stage01` as the next user-facing visual candidate.
3. Build deterministic path sprite slicing against actual `corridor_gap_network_01` cells.
4. Generate Stage 01 wall-shell overlays separately:
   - closed side wall;
   - paired doorway mouth `N/E/S/W`;
   - open-placeholder construction marker.
5. Regenerate the Stage 01 throne as a simpler cave asset:
   - same SW direction as the accepted single proof;
   - less gold, fewer crystals, more crude rock/wood/bone.
6. Expand stage-aware runtime lookup from the default six sprites to the full upgrade/facing/open-mask matrix.

## Runtime Safety

The broad generated proof sheets from this pass should still not be referenced from `data/dungeon_quarter/asset_manifest.json`.

Safe to use now:

- generated images as design review references;
- validation report;
- QA overlays;
- slicing/validation script.
- the six separately generated and alpha-processed Stage 01 default-layout runtime sprites listed above.

Unsafe to use now:

- generated full room sprites as runtime production assets;
- generated 16-mask throne sheet;
- broad direction atlas as final facing source.
- any generated asset outside the six approved Stage 01 default-layout runtime sprites.
