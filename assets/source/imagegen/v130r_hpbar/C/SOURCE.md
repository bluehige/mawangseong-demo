# HP bar C — 2026-10-17 18:22 사용자 선택 / Step12 연결

- Generation model: GPT internal image generation
- Generated date: 2026-10-17
- Target version: v1.3.0
- Source image path: assets/source/imagegen/v130r_hpbar/C/source_C.png
Source SHA256: a98119552da5378246d8ea331e80c5f3a7f8613c161310e2eb1a5af71d650638

- Runtime image path: assets/ui/v130r/hpbar/C/boss_ornament.png
- Runtime image path: assets/ui/v130r/hpbar/C/damage_orange.png
- Runtime image path: assets/ui/v130r/hpbar/C/damage_orange_left.png
- Runtime image path: assets/ui/v130r/hpbar/C/damage_orange_middle.png
- Runtime image path: assets/ui/v130r/hpbar/C/damage_orange_right.png
- Runtime image path: assets/ui/v130r/hpbar/C/damage_white.png
- Runtime image path: assets/ui/v130r/hpbar/C/damage_white_left.png
- Runtime image path: assets/ui/v130r/hpbar/C/damage_white_middle.png
- Runtime image path: assets/ui/v130r/hpbar/C/damage_white_right.png
- Runtime image path: assets/ui/v130r/hpbar/C/fill_ally.png
- Runtime image path: assets/ui/v130r/hpbar/C/fill_ally_left.png
- Runtime image path: assets/ui/v130r/hpbar/C/fill_ally_middle.png
- Runtime image path: assets/ui/v130r/hpbar/C/fill_ally_right.png
- Runtime image path: assets/ui/v130r/hpbar/C/fill_boss.png
- Runtime image path: assets/ui/v130r/hpbar/C/fill_boss_left.png
- Runtime image path: assets/ui/v130r/hpbar/C/fill_boss_middle.png
- Runtime image path: assets/ui/v130r/hpbar/C/fill_boss_right.png
- Runtime image path: assets/ui/v130r/hpbar/C/fill_enemy.png
- Runtime image path: assets/ui/v130r/hpbar/C/fill_enemy_left.png
- Runtime image path: assets/ui/v130r/hpbar/C/fill_enemy_middle.png
- Runtime image path: assets/ui/v130r/hpbar/C/fill_enemy_right.png
- Runtime image path: assets/ui/v130r/hpbar/C/frame_ally.png
- Runtime image path: assets/ui/v130r/hpbar/C/frame_ally_left.png
- Runtime image path: assets/ui/v130r/hpbar/C/frame_ally_middle.png
- Runtime image path: assets/ui/v130r/hpbar/C/frame_ally_right.png
- Runtime image path: assets/ui/v130r/hpbar/C/frame_boss.png
- Runtime image path: assets/ui/v130r/hpbar/C/frame_boss_left.png
- Runtime image path: assets/ui/v130r/hpbar/C/frame_boss_middle.png
- Runtime image path: assets/ui/v130r/hpbar/C/frame_boss_right.png
- Runtime image path: assets/ui/v130r/hpbar/C/frame_enemy.png
- Runtime image path: assets/ui/v130r/hpbar/C/frame_enemy_left.png
- Runtime image path: assets/ui/v130r/hpbar/C/frame_enemy_middle.png
- Runtime image path: assets/ui/v130r/hpbar/C/frame_enemy_right.png
- Runtime image path: assets/ui/v130r/hpbar/C/level_badge.png
- Runtime image path: assets/ui/v130r/hpbar/C/name_ribbon.png
- Runtime image path: assets/ui/v130r/hpbar/C/name_ribbon_compact.png
- Runtime image path: assets/ui/v130r/hpbar/C/name_ribbon_compact_left.png
- Runtime image path: assets/ui/v130r/hpbar/C/name_ribbon_compact_middle.png
- Runtime image path: assets/ui/v130r/hpbar/C/name_ribbon_compact_right.png
- Runtime image path: assets/ui/v130r/hpbar/C/name_ribbon_left.png
- Runtime image path: assets/ui/v130r/hpbar/C/name_ribbon_middle.png
- Runtime image path: assets/ui/v130r/hpbar/C/name_ribbon_right.png
- Runtime image path: assets/ui/v130r/hpbar/C/portrait_frame.png
- Runtime image path: assets/ui/v130r/hpbar/C/shield.png
- Runtime image path: assets/ui/v130r/hpbar/C/shield_left.png
- Runtime image path: assets/ui/v130r/hpbar/C/shield_middle.png
- Runtime image path: assets/ui/v130r/hpbar/C/shield_right.png
- Runtime image path: assets/ui/v130r/hpbar/C/status_socket.png
- Runtime image path: assets/ui/v130r/hpbar/C/status_sockets_4.png

## Prompt

Use case: ui-mockup. Create a production raster GAME UI COMPONENT ATLAS, genuinely transparent RGBA background, no checkerboard painted into the image. Reference image is MATERIAL/STYLE ONLY: cute horror hand-painted dark blue obsidian stone, restrained antique gold rims, same beveled stone and gold rivets, crisp readable at tiny 64px width. No text, no letters, no numbers, no labels, no complete mockup, no backdrop, no drop shadows beyond components.
Canvas square 1024x1024, exact uniform 4 columns x 4 rows, each invisible cell 256x256. Put exactly ONE isolated component centered in every cell. Substantial transparent spacing. Long bars span about 224px wide, roughly 28px high including rims, horizontally straight with long quiet stretchable middles. Rounded corners minimal, no busy middle ornaments. Empty frame interiors MUST BE TRANSPARENT. Fills are separate standalone horizontal rounded gradient strips without rims. This atlas will be cropped by cell and split into left, middle, right sections for 9-slice assembly. Flat orthographic front view.
ROW 1 (left to right): empty ALLY narrow health bar frame, gold rim dark obsidian, tiny cyan end accent; empty ENEMY health bar frame same with tiny crimson end accent; empty BOSS frame slightly more ornate, tiny cute ivory skull and gold crown at left endpoint only, long clear transparent interior; empty circular PORTRAIT frame, dark obsidian and gold, transparent circular interior.
ROW 2: turquoise-to-sky-blue gradient health fill strip; crimson-to-scarlet gradient health fill strip; ruby-to-garnet boss gradient health fill strip; warm white damage trail strip.
ROW 3: orange damage trail strip; pale sky blue translucent shield OVERLAY strip with native partial alpha; FOUR small empty circular status icon sockets in one horizontal row, each obsidian thin gold rim with transparent centers; blank dark obsidian NAME RIBBON with delicate gold edge, long horizontal clear center, no lettering.
ROW 4: one small round LEVEL BADGE with dark opaque obsidian center, gold rim, blank no number; an alternative blank compact name ribbon; a tiny cute ivory skull gold crown ornament; one single small empty status socket.
All details must be original generated artwork. No drawn layout lines. Preserve native transparency.
VARIANT C: circular PORTRAIT MEDALLION plus narrow extending health bar. Frame end caps simple to connect beside a separate circular medallion. Circular portrait frame is the signature: charming slightly chunky rounded obsidian, antique gold rim and tiny gold rivets, completely TRANSPARENT empty center so an existing character portrait can be composited into it. No portrait or face painted inside it. Name ribbon above bar. Same cute horror and restrained material palette. Every component entirely inside its own cell.

## Original candidate processing and limitations

The following notes describe the original candidate session; Step12 integration below supersedes the candidate-only and Godot-not-run statements.

- Native transparent RGBA output requested with transparent_background=true; actual alpha verified.
- Rectangular cell crop and left/middle/right splits only. Alpha threshold locates crop; no pixels are removed inside the crop.
- Runtime paths are requested candidate storage, not engine integration or approved final artwork.
- PIL preview: assembly, resizing, shield opacity, NEXON Maplestory labels only; no coded UI graphics.
- C reuses existing pudding/mori/dolkong portraits as composition samples, not per-enemy final portrait selection.
- Boss sample does not turn the pictured shield bearer into a boss; HP/status values are illustrative.
- Original glyph/bar regions use nearby rectangular capture patches selected by boundary color similarity, excluding all known old UI rectangles; texture seams are mockup limitations.
- Hollow frames have slight generated interior highlights. Boss and fill details vary among proposals.
- Horizontal three-slice; vertical slice margins are zero. Native alpha and small rim glow retained.
- Godot not run; no code/data/save or difficulty edits.

Step12: Original C artwork copied unchanged from e5ba89a0 via codex/v130r-monsters. Selected by the user on 2026-10-17 18:22. Runtime rendering uses horizontal nine-patch frames/fills and cached 64px existing unit portraits; no new image generation, external generation, or background removal.
