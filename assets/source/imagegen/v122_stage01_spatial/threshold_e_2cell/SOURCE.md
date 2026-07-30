# v1.2.2 Stage 01 E 2셀 문턱 생성 기록

## 정책 고정 필드

- Generation model: GPT internal image generation
- Generated date: 2026-07-29
- Target version: 1.2.2
- Source image path: assets/source/imagegen/v122_stage01_spatial/threshold_e_2cell/threshold_e_2cell_selected_raw_chroma.png
- Runtime image path: assets/tiles/stage_01/spatial/threshold_stage01_E_2cell.png

선택 alpha 원본은 `tools/prepare_v122_stage01_spatial_assets.py`에서 native `256×128`로 정합되며 Stage 01 E/front 문턱 lookup에 연결된다.

## 상태

- 자산 역할: Stage 01 `threshold_E_2cell`
- 방향: `E`
- 레이어: `front`
- native 목표: `256×128`
- 상태: `RUNTIME_CONNECTED`
- 런타임 연결: Stage 01 `thresholds.E`
- 원본 보존:
  - `threshold_e_2cell_intermediate_wrong_seam.png`
  - `threshold_e_2cell_selected_raw_chroma.png`
- alpha 승인 후보:
  - `threshold_e_2cell_selected_alpha_preview.png`

## 입력 이미지 역할

1. exact E geometry edit target:
   - `C:\Users\LDK-6248\.codex\visualizations\2026\07\27\019fa2ea-5220-7fd2-9355-4b09f55558ad\v122_stage01_spatial_exact_guides_2026-07-29\v122_stage01_threshold_E_2cell_exact_guide.png`
2. 잘못된 seam 후보의 재질 reference:
   - `assets/source/imagegen/v122_stage01_spatial/threshold_e_2cell/threshold_e_2cell_intermediate_wrong_seam.png`
3. 승인된 N 문턱 family reference:
   - `assets/source/imagegen/v122_stage01_spatial/threshold_n_2cell/threshold_n_2cell_selected_alpha_preview.png`
4. 승인된 Stage 01 재질·광원 reference:
   - `assets/source/imagegen/v122_stage01_spatial/throne_sw_open04/throne_sw_open04_selected_alpha_preview.png`

## 선택 원본 최종 프롬프트

```text
Use case: sketch-to-render
Asset type: production-source 2D isometric game transition tile
Input images:
- Image 1: edit target and mandatory E geometry. Its black/yellow boundary line is the only allowed seam direction: lower-left to upper-right, approximately (31%,59%) -> center (50%,50%) -> (69%,41%). Its arrow points across the seam toward screen lower-right. Preserve this exactly.
- Image 2: failed E attempt used only for material, stone layout density, flush dark-timber inlay, restrained brass plates, edge finish, and color. Do NOT preserve Image 2's seam orientation; Image 2 incorrectly runs upper-left to lower-right and must be mirrored to the opposite diagonal.
Primary request: Correct Image 2 into the Stage 01 E-facing two-cell threshold, runtime role threshold_E_2cell, front layer. Change only the transition orientation and necessary slab division; keep the approved material family.
Mandatory orientation correction:
- seam endpoints must be lower-left and upper-right, never upper-left and lower-right;
- the dark-timber inlay must visibly rise from screen lower-left to screen upper-right like a forward slash `/` in image coordinates;
- traversable direction crosses it toward screen lower-right;
- room-side and corridor-side surface distinction follows Image 1, not the failed attempt;
- preserve a strict 2:1 isometric diamond and centered anchor;
- keep the seam fully embedded and both passage cells open.
Scene/backdrop: perfectly flat uniform solid #00ff00 outside the diamond, with no gradient, texture, shadow, reflection, floor plane, fog, or lighting variation. Do not use #00ff00 inside the asset.
Subject: hand-laid charcoal stone transition with orderly room slabs, rougher worn corridor slabs, one fully flush dark-timber inlay, and no more than three small aged-brass plates level with the floor.
Style/medium: polished hand-painted high-resolution 2D dark-fantasy isometric game asset matching Image 2; warm upper-left lighting remains physically consistent after the orientation correction; subtle violet cave bounce; low saturation; not pixel art, not 3D render, not cartoon.
Constraints: no N-direction backslash seam; no walls, gate, door, stairs, ramp, raised rail, curb, spikes, chains, characters, props, UI, grid, arrows, dashed boxes, labels, text, logos, watermark, smoke, fog, particles, cast shadow, contact shadow, or opaque pixels outside the diamond.
```

## 반복 기록

| 회차 | 결과 | 판정 |
|---:|---|---|
| 1 | N 문턱과 같은 석재·목재·황동 재질 밀도 확보 | seam이 N과 같은 좌상단→우하단으로 생성돼 E 방향 불일치로 탈락 |
| 2 | seam을 좌하단→우상단으로 반전하고 lower-right 통행 방향 확보 | 선택 원본 |

## alpha 후처리

- 도구:
  - `C:\Users\LDK-6248\.codex\skills\.system\imagegen\scripts\remove_chroma_key.py`
- 옵션:
  - `--auto-key border`
  - `--soft-matte`
  - `--transparent-threshold 12`
  - `--opaque-threshold 220`
  - `--despill`
- 감지 key: `#06eb03`
- 이미지: `1254×1254`
- alpha bbox: `(16, 250, 1240, 995)`
- 투명 픽셀: `1,101,074`
- 부분 투명 픽셀: `3,091`
- 불투명 픽셀: `468,351`
- 모서리 alpha: 네 곳 모두 `0`
- 남은 greenish opaque 픽셀: `0`

## exact 정합 상태

- E seam은 좌하단→우상단이며 passage vector는 screen lower-right다.
- strict 2:1 투영과 center anchor 방향은 승인 기준에 맞는다.
- 생성 결과의 alpha bbox는 guide bbox보다 커 현재 파일을 runtime에 바로 사용하지 않는다.
- 전체 공간 자산 승인 뒤 guide mask 안에 결정적으로 fit하고 native `256×128`로 slicing한다.
- E는 `front` 레이어이므로 실제 room·unit 합성 순서는 runtime 연결 단계에서 별도 확인한다.

## 후속 작업

1. 사용자가 E 문턱의 seam 방향, 재질 구분, 통행 가독성을 승인한다.
2. 승인 뒤 같은 기준으로 S 2셀 문턱 하나를 생성한다.
3. N/E/S/W 승인 뒤 exact contact sheet와 native slicing을 만든다.
4. 실제 runtime 경로와 manifest 연결은 전체 Stage 01 공간 자산 승인 뒤 별도 단계로 수행한다.
