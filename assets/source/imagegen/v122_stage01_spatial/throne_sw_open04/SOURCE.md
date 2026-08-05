# v1.2.2 Stage 01 왕좌 SW / open_04 생성 기록

## 정책 고정 필드

- Generation model: GPT internal image generation
- Generated date: 2026-07-29
- Target version: v1.2.2
- Source image path: assets/source/imagegen/v122_stage01_spatial/throne_sw_open04/throne_sw_open04_selected_raw_chroma.png
- Source image path: assets/source/imagegen/v122_stage01_spatial/throne_sw_open04/throne_sw_open04_selected_alpha_preview.png
- Source image path: assets/source/imagegen/v122_stage01_spatial/throne_sw_open04/throne_sw_open04_intermediate_projection_reference.png
- Runtime image path: assets/props/stage_01/room_throne_stage01_SW_open_s_back.png

선택 alpha 원본은 `tools/prepare_v122_stage01_spatial_assets.py`의 단일 비율 exact 정합을 거쳐 별도 runtime PNG로 출력되며 Stage 01 `SW` 왕좌 lookup에만 연결된다.

## 상태

- 자산 역할: Stage 01 `throne_f`
- facing: `SW`
- open mask: `04`
- open side: `S`
- 상태: `RUNTIME_CONNECTED`
- 런타임 연결: Stage 01 `stage_facing_sprites.SW.back`
- 원본 보존:
  - `throne_sw_open04_intermediate_projection_reference.png`
  - `throne_sw_open04_selected_raw_chroma.png`
- alpha 승인 후보:
  - `throne_sw_open04_selected_alpha_preview.png`

## 입력 이미지 역할

1. exact geometry:
   - `C:\Users\LDK-6248\.codex\visualizations\2026\07\27\019fa2ea-5220-7fd2-9355-4b09f55558ad\v122_stage01_spatial_exact_guides_2026-07-29\v122_stage01_throne_5x5_exact_guide.png`
2. 중간 왕좌 디자인 reference:
   - `assets/source/imagegen/v122_stage01_spatial/throne_sw_open04/throne_sw_open04_intermediate_projection_reference.png`
3. Stage 01 주 화풍 reference:
   - `assets/props/stage_01/prop_entrance_gate_stage01_SE_back.png`
4. 초기 실내 재질 보조 reference:
   - `assets/props/stage_01/prop_weapon_rack_stage01_SE_back.png`

## 선택 원본 최종 프롬프트

```text
Use case: sketch-to-render
Asset type: production-source 2D game throne room asset
Input images:
- Image 1: edit target and mandatory geometry. Preserve its square canvas registration, exact 5x5 2:1 diamond footprint, outer diamond vertices, center anchor, and highlighted S two-cell opening. Replace the abstract guide drawing with finished art, but do not move or distort its floor boundary.
- Image 2: subject/design reference only. Reuse its improvised charcoal-stone and lashed-timber throne design, bone/horn ornament, restrained burgundy cloth, modest purple crystals, and warm lighting. Do not reuse its deeper floor perspective or wider opening.
- Image 3: primary finish/style reference for painterly dark stone, material scale, crisp isolated silhouette, and Stage 01 color grading.
Primary request: Render Image 1 as a finished Stage 01 Demon King's throne room, throne_f, facing SW, open_mask 04.
Exact composition invariant:
- square canvas;
- floor diamond vertices remain at approximately top (50%,49%), right (97%,73%), bottom (50%,96%), left (3%,73%), giving a strict 2:1 floor diamond;
- floor uses the lower half of the canvas exactly as Image 1;
- tall throne and rear walls rise into the upper transparent/chroma area without changing the floor vertices;
- only the highlighted S boundary span, approximately (22%,82%) -> (31%,87%) -> (41%,91%), is open and flush to the floor;
- the remaining N, E, and W boundaries and both ends of the S boundary are blocked.
Scene/backdrop: replace all unused/transparent and black areas of Image 1 with a perfectly flat solid #00ff00 chroma-key background. It must be uniform with no gradient, texture, shadow, reflection, floor plane, fog, or lighting variation. Do not use #00ff00 inside the asset.
Subject: one tall rough throne around the center/back anchor, clearly facing screen lower-left (SW), made from hand-stacked charcoal stone and lashed dark timber with restrained bone and horn structure, torn burgundy cloth, small muted purple crystal accents, and limited aged brass. Keep a clear worn floor route from the exact S opening to the throne.
Style/medium: polished hand-painted high-resolution 2D dark-fantasy isometric game asset matching Image 3; crisp readable detail; not pixel art, not 3D render, not cartoon.
Lighting/mood: warm upper-left light with subtle violet cave bounce; low saturation; consistent floor/object light direction.
Constraints: no opaque floor outside Image 1's diamond; no extra exits, corridors, stairs, characters, enemies, UI, grid lines, arrows, dashed boxes, labels, text, logos, watermark, smoke, fog, glass, or particles.
```

## 반복 기록

| 회차 | 결과 | 판정 |
|---:|---|---|
| 1 | 화풍·왕좌 실루엣 확보 | S 2셀 입구가 통나무 경계로 막혀 탈락 |
| 2 | 통나무 경계를 제거해 입구 가독성 확보 | S 개방 폭이 너무 넓어 탈락 |
| 3 | 양 끝 경계를 복원 | floor 투영이 guide보다 깊어 중간 디자인 reference로만 보존 |
| 4 | guide를 edit target으로 사용해 다시 렌더 | 선택 원본. 지정 구간의 낮은 평면 문턱과 화풍 기준 확보 |

## alpha 후처리

- 도구:
  - `C:\Users\LDK-6248\.codex\skills\.system\imagegen\scripts\remove_chroma_key.py`
- 옵션:
  - `--auto-key border`
  - `--soft-matte`
  - `--transparent-threshold 12`
  - `--opaque-threshold 220`
  - `--despill`
- 감지 key: `#08ea0c`
- 이미지: `1254×1254`
- 투명 픽셀: `764,893`
- 부분 투명 픽셀: `4,990`
- 불투명 픽셀: `802,633`
- 모서리 alpha: 네 곳 모두 `0`
- 남은 greenish opaque 픽셀: `0`

## 후속 작업

1. 사용자가 왕좌의 화풍·재질·밀도·실루엣을 승인한다.
2. 승인 뒤 exact guide와 합성한 정합 contact sheet에서 floor·S socket을 확정한다.
3. 문턱 N/E/S/W 4종은 이 후보의 석재·목재·광원을 기준으로 생성한다.
4. 실제 runtime 경로와 manifest 연결은 전체 자산 승인 뒤 별도 단계로 수행한다.
