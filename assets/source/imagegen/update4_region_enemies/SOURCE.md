# Update 4 지역 일반 적 6종 생성 기록

- Generation model: GPT internal image generation
- Generated date: 2026-07-27
- Target version: v1.2.2
- Style/layout reference: `assets/sprites/enemies/update3_atlas/enemy_bounty_tracker_sheet.png`
- Source format: 1254×1254 PNG, 4×4, 16 frames, flat `#ff00ff` chroma background
- Connected runtime format: 768×768 RGBA PNG, 4×4, 192×192 per frame, chroma shader disabled
- Frame order: `idle_down:2`, `down:2`, `move_down:4`, `attack_down:4`, `skill_down:4`
- Post-processing: 원본 1254×1254는 보존한다. V1-C와 V1-D에서 `tools/prepare_v122_combat_runtime_sprites.py`가 전체 시트의 배경 연결 크로마를 제거하고, 셀 경계를 넘는 연결 성분을 주 프레임에 다시 배정한 뒤 자산별 공통 정사각 창·공통 축소율·6px 여백으로 16프레임을 재포장한다. 마지막에는 premultiplied LANCZOS resize와 알파를 보존하는 RGB despill을 적용하고 192×192 셀 전체 둘레를 검사한다. 이 별도 RGBA runtime sheet에는 크로마 셰이더를 다시 적용하지 않는다.

## 파일 대응

| 적 | 생성 원본 | 런타임 |
|---|---|---|
| 숯불 정령 | `coal_spark_combat_sheet_chroma_2026-07-27.png` | `assets/sprites/enemies/update4/region/enemy_coal_spark_sheet.png` |
| 황혼 전령 | `dusk_courier_combat_sheet_chroma_2026-07-27.png` | `assets/sprites/enemies/update4/region/enemy_dusk_courier_sheet.png` |
| 청동 자동병 | `bronze_automaton_combat_sheet_chroma_2026-07-27.png` | `assets/sprites/enemies/update4/region/enemy_bronze_automaton_sheet.png` |
| 그림자 결투사 | `shadow_duelist_combat_sheet_chroma_2026-07-27.png` | `assets/sprites/enemies/update4/region/enemy_shadow_duelist_sheet.png` |
| 포자 인형 | `spore_doll_combat_sheet_chroma_2026-07-27.png` | `assets/sprites/enemies/update4/region/enemy_spore_doll_sheet.png` |
| 뿌리 정원사 | `root_tender_combat_sheet_chroma_2026-07-27.png` | `assets/sprites/enemies/update4/region/enemy_root_tender_sheet.png` |

## V1-C 전처리 출력

V1-C는 동일 변환 도구의 첫 3개 자산만 처리한다. 아래 출력은 768×768 RGBA 4×4 sheet이며, 각 셀은 192×192 정수 크기다. V1-C에서는 데이터·Unit lookup을 바꾸지 않는다.

| ID | Source image path | Runtime image path |
|---|---|---|
| `coal_spark` | `assets/source/imagegen/update4_region_enemies/coal_spark_combat_sheet_chroma_2026-07-27.png` | `assets/sprites/enemies/update4/region/normalized/enemy_coal_spark_sheet.png` |
| `dusk_courier` | `assets/source/imagegen/update4_region_enemies/dusk_courier_combat_sheet_chroma_2026-07-27.png` | `assets/sprites/enemies/update4/region/normalized/enemy_dusk_courier_sheet.png` |
| `bronze_automaton` | `assets/source/imagegen/update4_region_enemies/bronze_automaton_combat_sheet_chroma_2026-07-27.png` | `assets/sprites/enemies/update4/region/normalized/enemy_bronze_automaton_sheet.png` |

## V1-D 전처리 출력

V1-D는 V1-C와 같은 변환 도구를 수정 없이 사용해 나머지 3개 자산을 처리한다. 아래 출력도 768×768 RGBA 4×4 sheet이며, 각 셀은 192×192 정수 크기다. V1-D에서도 데이터·Unit lookup을 바꾸지 않는다.

| ID | Source image path | Runtime image path |
|---|---|---|
| `shadow_duelist` | `assets/source/imagegen/update4_region_enemies/shadow_duelist_combat_sheet_chroma_2026-07-27.png` | `assets/sprites/enemies/update4/region/normalized/enemy_shadow_duelist_sheet.png` |
| `spore_doll` | `assets/source/imagegen/update4_region_enemies/spore_doll_combat_sheet_chroma_2026-07-27.png` | `assets/sprites/enemies/update4/region/normalized/enemy_spore_doll_sheet.png` |
| `root_tender` | `assets/source/imagegen/update4_region_enemies/root_tender_combat_sheet_chroma_2026-07-27.png` | `assets/sprites/enemies/update4/region/normalized/enemy_root_tender_sheet.png` |

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
- Runtime image path: `assets/sprites/enemies/update4/region/normalized/enemy_coal_spark_sheet.png`
- Runtime image path: `assets/sprites/enemies/update4/region/normalized/enemy_dusk_courier_sheet.png`
- Runtime image path: `assets/sprites/enemies/update4/region/normalized/enemy_bronze_automaton_sheet.png`
- Runtime image path: `assets/sprites/enemies/update4/region/normalized/enemy_shadow_duelist_sheet.png`
- Runtime image path: `assets/sprites/enemies/update4/region/normalized/enemy_spore_doll_sheet.png`
- Runtime image path: `assets/sprites/enemies/update4/region/normalized/enemy_root_tender_sheet.png`

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
