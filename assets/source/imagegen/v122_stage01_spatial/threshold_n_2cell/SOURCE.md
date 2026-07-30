# v1.2.2 Stage 01 N 2셀 문턱 생성 기록

## 정책 고정 필드

- Generation model: GPT internal image generation
- Generated date: 2026-07-29
- Target version: 1.2.2
- Source image path: assets/source/imagegen/v122_stage01_spatial/threshold_n_2cell/threshold_n_2cell_selected_raw_chroma.png
- Runtime image path: assets/tiles/stage_01/spatial/threshold_stage01_N_2cell.png

선택 alpha 원본은 `tools/prepare_v122_stage01_spatial_assets.py`에서 native `256×128`로 정합되며 Stage 01 N/back 문턱 lookup에 연결된다.

## 상태

- 자산 역할: Stage 01 `threshold_N_2cell`
- 방향: `N`
- 레이어: `back`
- native 목표: `256×128`
- 상태: `RUNTIME_CONNECTED`
- 런타임 연결: Stage 01 `thresholds.N`
- 원본 보존:
  - `threshold_n_2cell_intermediate_raised_seam.png`
  - `threshold_n_2cell_selected_raw_chroma.png`
- alpha 승인 후보:
  - `threshold_n_2cell_selected_alpha_preview.png`

## 입력 이미지 역할

1. exact geometry edit target:
   - `C:\Users\LDK-6248\.codex\visualizations\2026\07\27\019fa2ea-5220-7fd2-9355-4b09f55558ad\v122_stage01_spatial_exact_guides_2026-07-29\v122_stage01_threshold_N_2cell_exact_guide.png`
2. 첫 생성 결과의 재질·구분 reference:
   - `assets/source/imagegen/v122_stage01_spatial/threshold_n_2cell/threshold_n_2cell_intermediate_raised_seam.png`
3. 승인된 Stage 01 재질·광원 reference:
   - `assets/source/imagegen/v122_stage01_spatial/throne_sw_open04/throne_sw_open04_selected_alpha_preview.png`

## 선택 원본 최종 프롬프트

```text
Use case: sketch-to-render
Asset type: production-source 2D isometric game transition tile
Input images:
- Image 1: edit target and mandatory geometry. Preserve its square canvas registration and exact guide footprint: outer diamond top (50%,31%), right (88%,50%), bottom (50%,69%), left (12%,50%), with the N seam from about (31%,41%) through (50%,50%) to (69%,59%). Replace only the abstract guide art; keep all unused canvas outside that exact diamond as chroma key.
- Image 2: previous material/design attempt only. Preserve its charcoal stone distinction between orderly room slabs and rough corridor slabs, but shrink it to Image 1's exact diamond and change the raised brass/timber bar into a fully flush, worn floor inlay.
- Image 3: approved Stage 01 throne style and lighting reference only. Match its painterly charcoal stone, restrained aged brass, warm upper-left light, and subtle violet cave bounce. Do not copy any room objects.
Primary request: Produce a corrected Stage 01 N-facing two-cell room-to-corridor threshold, runtime role threshold_N_2cell, back layer.
Required targeted corrections:
- the entire asset must fit Image 1's exact 2x2 diamond bounds, not the larger/deeper diamond from Image 2;
- preserve strict 2:1 isometric projection and Image 1's center anchor;
- the N seam stays exactly on Image 1's diagonal;
- replace the raised crossbar with an ankle-flat, fully embedded seam: dark worn timber and very restrained aged-brass corner plates level with the surrounding slabs;
- leave both passage cells visibly open and walkable across the seam toward screen upper-right;
- no visual element may read as a rail, barrier, curb, or collision object.
Scene/backdrop: perfectly flat uniform solid #00ff00 outside the exact diamond, with no gradient, texture, shadow, reflection, floor plane, fog, or lighting variation. Do not use #00ff00 inside the asset.
Style/medium: polished hand-painted high-resolution 2D dark-fantasy isometric game asset matching Image 3; crisp restrained detail; not pixel art, not 3D render, not cartoon.
Constraints: no walls, gate, door, stairs, ramp, raised rail, spikes, chains, characters, props, UI, grid overlay, arrows, dashed boxes, labels, text, logos, watermark, smoke, fog, particles, cast shadow, contact shadow, or opaque pixels outside the exact guide diamond.
```

## 반복 기록

| 회차 | 결과 | 판정 |
|---:|---|---|
| 1 | 왕좌와 맞는 석재, 방·복도 표면 차이, 황동·목재 경계 확보 | patch가 guide보다 크고 황동 띠가 낮은 장애물처럼 보여 탈락 |
| 2 | 경계를 바닥 매입형 목재와 제한된 황동 plate로 평탄화 | 선택 원본. 통행 가능한 2셀 문턱 표현 확보 |

## alpha 후처리

- 도구:
  - `C:\Users\LDK-6248\.codex\skills\.system\imagegen\scripts\remove_chroma_key.py`
- 옵션:
  - `--auto-key border`
  - `--soft-matte`
  - `--transparent-threshold 12`
  - `--opaque-threshold 220`
  - `--despill`
- 감지 key: `#08e804`
- 이미지: `1254×1254`
- alpha bbox: `(25, 249, 1229, 972)`
- 투명 픽셀: `1,124,189`
- 부분 투명 픽셀: `3,034`
- 불투명 픽셀: `445,293`
- 모서리 alpha: 네 곳 모두 `0`
- 남은 greenish opaque 픽셀: `0`

## exact 정합 상태

- 방향, seam 기울기, strict 2:1 투영은 승인 기준에 맞는다.
- 생성 모델이 guide의 캔버스 점유율을 정확히 유지하지 않아 현재 alpha bbox는 guide bbox보다 크다.
- 이 파일은 시각 승인 후보이며 runtime에 바로 사용하지 않는다.
- 전체 공간 자산 승인 뒤 guide mask 안에 결정적으로 fit하고 native `256×128`로 slicing한다.
- 정합 단계에서는 seam center와 N passage vector를 다시 비교하고 확대·축소로 재질 밀도가 무너지면 원본을 재생성한다.

## 후속 작업

1. 사용자가 N 문턱의 재질 구분, 매입형 seam, 통행 가독성을 승인한다.
2. 승인 뒤 같은 기준으로 E 2셀 문턱 하나를 생성한다.
3. N/E/S/W 승인 뒤 exact contact sheet와 native slicing을 만든다.
4. 실제 runtime 경로와 manifest 연결은 전체 Stage 01 공간 자산 승인 뒤 별도 단계로 수행한다.
