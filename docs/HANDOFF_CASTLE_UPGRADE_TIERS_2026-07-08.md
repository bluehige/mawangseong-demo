# Handoff: Castle Upgrade Tiers And Stage Assets

Date: 2026-07-08

## User Request

The user said the current beginner Demon King castle looks too advanced. They want buildings and the base to support upgrade stages. The current castle should become around Stage 02, and Stage 01 should look more like a cave dungeon. They asked to use gpt-image-2/imagegen, make the object progression from start to final stage, and leave a clear handoff because this is a longer asset/system task.

## Completed In This Pass

Created a four-stage visual plan:

- `stage_01_cave`: rookie cave dungeon.
- `stage_02_castle`: current polished dark castle direction.
- `stage_03_keep`: reinforced demon keep.
- `stage_04_citadel`: final demon citadel.

Generated proof images with the built-in imagegen route:

- One 7x4 object atlas covering:
  - entrance gate;
  - throne;
  - barracks;
  - recovery nest;
  - treasure storage;
  - watch post;
  - build foundation.
- One 1x4 castle/base progression sheet.

Processed both sheets:

- copied source proofs into `docs/concepts/`;
- copied source proofs into `output/imagegen/`;
- removed chroma green background into alpha PNGs;
- sliced 32 proof sprites:
  - 28 object proofs;
  - 4 castle/base proofs.

Added the slicing tool:

- `tools/slice_castle_upgrade_stage_proofs.py`

Added planning/contract docs:

- `docs/CASTLE_UPGRADE_STAGE_PLAN_2026-07-08.md`
- `docs/IMAGEGEN_CONTRACT_CASTLE_UPGRADE_TIERS_2026-07-08.md`
- `docs/HANDOFF_CASTLE_UPGRADE_TIERS_2026-07-08.md`

Follow-up contract QA and generation pass:

- generated direction-facing, default room, open-mask, path-layout, path-component, and throne-SW proof sources;
- alpha-processed chroma-key sheets;
- sliced proof sets into `output/imagegen/castle_contract_proofs/`;
- generated QA overlays and validation outputs in `output/imagegen/castle_contract_qa/`;
- added `tools/slice_and_validate_castle_contract_proofs.py`;
- added `docs/CASTLE_VISUAL_CONTRACT_QA_REPORT_2026-07-08.md`;
- updated `docs/IMAGEGEN_CONTRACT_FULL_GRID_PATH_CONNECTIONS_01.md` from old `corridor_spike_ns_01` notes to current `corridor_gap_network_01`.

QA rejection fix and limited runtime application:

- generated six separate Stage 01 default-layout sprites instead of reusing the rejected broad proof sheets;
- alpha-processed and trimmed them with `tools/prepare_stage01_runtime_sprites.py`;
- added runtime PNGs under `assets/props/stage_01/`;
- added `GameRoot.castle_art_stage = "stage_01_cave"`;
- added `stage_facing_sprites.stage_01_cave` entries to `data/dungeon_quarter/asset_manifest.json`;
- added renderer lookup for `propstage:<prop>:<stage>:<facing>:<layer>`;
- added `_complete_override` handling so a corrected stage sprite can suppress old mismatched fallback layers;
- updated `tools/QuarterModuleSmokeTest.gd` to require the six Stage 01 runtime keys.
- regenerated the runtime throne once more after capture review, because the first runtime candidate was direction-correct but still too palace-like for the beginner cave tier.

## Important Asset Paths

Source proofs:

- `docs/concepts/castle_upgrade_object_stage_atlas_gpt_image2_2026-07-08_source.png`
- `docs/concepts/castle_upgrade_base_stage_sheet_gpt_image2_2026-07-08_source.png`

Alpha processed sheets:

- `output/imagegen/castle_upgrade_object_stage_atlas_gpt_image2_2026-07-08_alpha.png`
- `output/imagegen/castle_upgrade_base_stage_sheet_gpt_image2_2026-07-08_alpha.png`

Sliced proofs:

- `output/imagegen/castle_upgrade_tiers/`

Preview:

- `output/imagegen/castle_upgrade_tiers/castle_upgrade_tiers_sliced_preview.png`

Contract QA outputs:

- `output/imagegen/castle_contract_proofs/`
- `output/imagegen/castle_contract_qa/castle_visual_contract_validation.md`
- `output/imagegen/castle_contract_qa/castle_contract_room_grid_overlay.png`
- `output/imagegen/castle_contract_qa/castle_contract_path_skeleton_overlay.png`

Stage 01 runtime outputs:

- `assets/props/stage_01/prop_entrance_gate_stage01_SE_back.png`
- `assets/props/stage_01/prop_throne_stage01_SW_back.png`
- `assets/props/stage_01/prop_weapon_rack_stage01_SE_back.png`
- `assets/props/stage_01/prop_recovery_nest_stage01_NW_front.png`
- `assets/props/stage_01/prop_treasure_pile_stage01_NW_front.png`
- `assets/props/stage_01/prop_foundation_marks_stage01_NE_back.png`
- `output/imagegen/stage01_runtime_applied_preview.png`
- `tmp/manual_verification/01_management.png`

## Visual QA Result

The sliced preview was inspected.

Findings:

- Stage 01 reads as a weaker cave/dungeon state.
- Stage 02 reads close to the current dark castle direction.
- Stage 03 and Stage 04 increase visual strength clearly.
- The proof sprites are good enough for planning and user review.

Limitations:

- These are not production runtime sprites yet.
- Facing directions are not validated.
- Open-mask room states are not validated.
- They are not tied to the `5x5` full-grid room object contract yet.
- They should not be referenced in `asset_manifest.json` until approved.

Follow-up contract QA result:

- Data-level direction/open-mask/socket/path validation passes `62 / 62`.
- The single `throne_f_stage01_SW_single_target_proof.png` is the current best SW-facing throne correction reference.
- The broad 7x4 direction atlas is not production-safe because some cells read as style/stage changes rather than true rotations.
- The 16-open-mask throne sheet is not production-safe because several openings are ambiguous or too similar.
- The path component atlas is the strongest candidate for the next production pass, but still needs exact grid slicing and runtime scale validation.

Limited runtime result:

- The six current default-layout Stage 01 sprites are now wired and verified in the management scene.
- The throne renders from the lower-tier cave SW-facing stage sprite and suppresses the old front fallback.
- Full four-stage, four-facing, 16-open-mask production coverage is still not complete.

## Recommended Next Implementation

1. Get user approval for the four-stage visual language.
2. Map the current polished look to `stage_02_castle` after Stage 02 assets are ready.
3. Extend the current stage-aware renderer path from default-layout `stage_facing_sprites` to the full production matrix:
   - stage;
   - facing;
   - open mask;
   - back/front layer.
4. Generate production-ready assets after approval:
   - stage-specific role/facing interiors;
   - shared wall shells by stage and `open_mask`;
   - shared doorway/path-mouth overlays.
5. Wire upgrade UI only after the data path exists:
   - selected building panel should show current stage;
   - upgrade action should live inside the selected building panel;
   - avoid adding more bottom-bar global buttons.

## Facility Upgrade Role Notes

Facility upgrades should affect both visuals and combat loop:

- Entrance gate: choke strength, invasion delay, warning time.
- Throne: core HP, command aura, emergency rally.
- Barracks: monster attack/defense, capacity, response speed.
- Recovery: healing, retreat recovery, later cleanse/emergency recovery.
- Treasure: economy reward, thief target, defense incentive.
- Watch post: detection, enemy slow, command/trap coordination.
- Build foundation: construction readiness, trap socket, expansion unlock.

This connects to the existing facility combat balance work from `docs/HANDOFF_FACILITY_COMBAT_BALANCE_2026-07-08.md`.

## Verification Commands

Use these after any changes to the slicer or generated proof folder:

```powershell
python tools/slice_castle_upgrade_stage_proofs.py
python tools/slice_and_validate_castle_contract_proofs.py
python tools/prepare_stage01_runtime_sprites.py
python -m py_compile tools/slice_castle_upgrade_stage_proofs.py
python -m py_compile tools/slice_and_validate_castle_contract_proofs.py
godot --headless --path . --scene tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --scene tools/DemoSmokeTest.tscn
godot --headless --path . --scene tools/TutorialFlowSmokeTest.tscn
```

Expected sliced proof count:

```text
28 object proof sprites + 4 castle/base proof sprites + 1 preview = 33 PNG files
```

## Do Not Do Yet

- Do not overwrite existing runtime `assets/props/v3` sprites with these proofs.
- Do not treat the broad proof images as direction-correct `NW/NE/SE/SW` production assets.
- Do not generate all full-grid variants blindly. Use the modular wall/opening composition plan from `docs/CASTLE_UPGRADE_STAGE_PLAN_2026-07-08.md`.
- Do not use the old `corridor_spike_ns_01` / `5x10` path skeleton for current default layout work. The active path module is `corridor_gap_network_01`.
