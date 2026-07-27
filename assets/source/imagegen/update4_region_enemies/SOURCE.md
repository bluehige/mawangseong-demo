# Update 4 지역 일반 적 6종 생성 기록

- Generation model: GPT internal image generation
- Generated date: 2026-07-27
- Target version: v1.2.2
- Style/layout reference: `assets/sprites/enemies/update3_atlas/enemy_bounty_tracker_sheet.png`
- Runtime format: 1254×1254 PNG, 4×4, 16 frames, flat `#ff00ff` chroma background
- Frame order: `idle_down:2`, `down:2`, `move_down:4`, `attack_down:4`, `skill_down:4`
- Post-processing: 없음. Godot의 기존 sprite-sheet chroma shader와 fractional 4×4 region reader를 사용한다.

## 파일 대응

| 적 | 생성 원본 | 런타임 |
|---|---|---|
| 숯불 정령 | `coal_spark_combat_sheet_chroma_2026-07-27.png` | `assets/sprites/enemies/update4/region/enemy_coal_spark_sheet.png` |
| 황혼 전령 | `dusk_courier_combat_sheet_chroma_2026-07-27.png` | `assets/sprites/enemies/update4/region/enemy_dusk_courier_sheet.png` |
| 청동 자동병 | `bronze_automaton_combat_sheet_chroma_2026-07-27.png` | `assets/sprites/enemies/update4/region/enemy_bronze_automaton_sheet.png` |
| 그림자 결투사 | `shadow_duelist_combat_sheet_chroma_2026-07-27.png` | `assets/sprites/enemies/update4/region/enemy_shadow_duelist_sheet.png` |
| 포자 인형 | `spore_doll_combat_sheet_chroma_2026-07-27.png` | `assets/sprites/enemies/update4/region/enemy_spore_doll_sheet.png` |
| 뿌리 정원사 | `root_tender_combat_sheet_chroma_2026-07-27.png` | `assets/sprites/enemies/update4/region/enemy_root_tender_sheet.png` |

## 정책 경로 대응

- Source image path: `assets/source/imagegen/update4_region_enemies/coal_spark_combat_sheet_chroma_2026-07-27.png`
- Runtime image path: `assets/sprites/enemies/update4/region/enemy_coal_spark_sheet.png`
- Source image path: `assets/source/imagegen/update4_region_enemies/dusk_courier_combat_sheet_chroma_2026-07-27.png`
- Runtime image path: `assets/sprites/enemies/update4/region/enemy_dusk_courier_sheet.png`
- Source image path: `assets/source/imagegen/update4_region_enemies/bronze_automaton_combat_sheet_chroma_2026-07-27.png`
- Runtime image path: `assets/sprites/enemies/update4/region/enemy_bronze_automaton_sheet.png`
- Source image path: `assets/source/imagegen/update4_region_enemies/shadow_duelist_combat_sheet_chroma_2026-07-27.png`
- Runtime image path: `assets/sprites/enemies/update4/region/enemy_shadow_duelist_sheet.png`
- Source image path: `assets/source/imagegen/update4_region_enemies/spore_doll_combat_sheet_chroma_2026-07-27.png`
- Runtime image path: `assets/sprites/enemies/update4/region/enemy_spore_doll_sheet.png`
- Source image path: `assets/source/imagegen/update4_region_enemies/root_tender_combat_sheet_chroma_2026-07-27.png`
- Runtime image path: `assets/sprites/enemies/update4/region/enemy_root_tender_sheet.png`

## 공통 프롬프트

```text
Use case: stylized-concept
Asset type: production game enemy animation sprite sheet
Image 1 is a style and exact 4x4 layout reference only; do not copy its character.
Create an exact 4 columns × 4 rows sheet on a perfectly flat uniform #ff00ff chroma-key background.
Row 1: idle_down 2, defeated/down 2.
Row 2: move_down 4.
Row 3: attack_down 4.
Row 4: signature skill_down 4.
Match the reference's polished hand-painted dark-fantasy game sprite style and three-quarter top-down camera.
Keep one consistent centered full-body design per cell with generous padding.
No extra characters, text, watermark, cropped limbs, cell dividers, shadows, gradient, texture, or floor plane.
Flat #ff00ff reaches every outer corner.
```

## 개별 프롬프트 차이

- 숯불 정령: compact charcoal-and-flame elemental, glowing coal body, orange-red plume, fiery claw/overheat leap/residual heat.
- 황혼 전령: slim bat-winged twilight courier, dark violet hood, mail satchel, sealed envelopes, seal-theft wind trail.
- 청동 자동병: bulky bronze-and-iron clockwork soldier, bell chest, rivets, gears, weighted feet, brace-wedge impact.
- 그림자 결투사: lean masked duelist, midnight armor, curved blade, cyan-violet eyes, teleport/ambush trail.
- 포자 인형: non-gory stitched cloth-and-bark mushroom puppet, blue-gray cap, wet-spore satchel, staff, teal healing zone.
- 뿌리 정원사: stocky bark-and-root keeper, moss hood, pruning-hook polearm, amber seed eyes, root-threshold barrier.
