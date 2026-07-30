# v1.2.2 Stage 01 W 2셀 문턱 생성 기록

## 정책 고정 필드

- Generation model: GPT internal image generation
- Generated date: 2026-07-30
- Target version: 1.2.2
- Source image path: assets/source/imagegen/v122_stage01_spatial/threshold_w_2cell/threshold_w_2cell_selected_raw_chroma.png
- Runtime image path: assets/tiles/stage_01/spatial/threshold_stage01_W_2cell.png

선택 alpha 원본은 `tools/prepare_v122_stage01_spatial_assets.py`에서 native `256×128`로 정합되며 Stage 01 W/back 문턱 lookup에 연결된다.

## 상태

- 자산 역할: Stage 01 `threshold_W_2cell`
- 방향: `W`
- 레이어: `back`
- native 목표: `256×128`
- 상태: `RUNTIME_CONNECTED`
- 런타임 연결: Stage 01 `thresholds.W`
- 선택 원본:
  - `threshold_w_2cell_selected_raw_chroma.png`
- alpha 승인 후보:
  - `threshold_w_2cell_selected_alpha_preview.png`

## 입력 이미지 역할

1. exact W geometry edit target:
   - `C:\Users\LDK-6248\.codex\visualizations\2026\07\27\019fa2ea-5220-7fd2-9355-4b09f55558ad\v122_stage01_spatial_exact_guides_2026-07-29\v122_stage01_threshold_W_2cell_exact_guide.png`
2. 승인된 E 문턱 family reference:
   - `assets/source/imagegen/v122_stage01_spatial/threshold_e_2cell/threshold_e_2cell_selected_alpha_preview.png`
3. 승인된 N 문턱 back-layer reference:
   - `assets/source/imagegen/v122_stage01_spatial/threshold_n_2cell/threshold_n_2cell_selected_alpha_preview.png`

## 선택 원본 최종 프롬프트

```text
Use case: sketch-to-render
Asset type: production-source 2D isometric game transition tile
Input images:
- Image 1: edit target and mandatory W-direction geometry guide. Preserve its square canvas registration, exact 2x2 isometric footprint, center anchor, W seam direction, and passage vector toward screen upper-left. Replace only the abstract guide art.
- Image 2: approved E threshold family reference only. Match its charcoal stone scale, lower-left-to-upper-right seam, flush dark-timber inlay, restrained aged-brass plates, material density, and edge treatment. Keep the same seam slope, but reverse the room/corridor surface sides because W is the opposite passage direction.
- Image 3: approved N threshold back-layer reference only. Match its low-profile back-layer treatment and restrained contrast. Do not copy its upper-left-to-lower-right seam orientation.
Primary request: Render a finished Stage 01 W-facing two-cell room-to-corridor threshold transition, runtime role threshold_W_2cell, back layer, in the same family as Images 2 and 3.
Exact composition invariant:
- square canvas;
- one low flat 2x2 isometric floor patch with strict 2:1 projection;
- outer diamond vertices remain approximately top (50%,31%), right (88%,50%), bottom (50%,69%), left (12%,50%);
- preserve the W boundary seam from approximately lower-left (31%,59%) through center (50%,50%) to upper-right (69%,41%);
- the embedded seam must rise from screen lower-left to upper-right like a forward slash `/`;
- traversable direction crosses the seam toward screen upper-left;
- both passage cells remain visibly open and walkable;
- no element may hide units or imply collision.
Surface-side invariant: unlike Image 2, place rougher, smaller worn corridor slabs on the upper-left side of the seam, and place slightly more orderly, larger rectangular room slabs on the lower-right side. This swap is mandatory for W.
Scene/backdrop: replace every unused area outside the exact diamond with a perfectly flat solid #00ff00 chroma-key background. The background must be uniform with no gradient, texture, shadow, reflection, floor plane, fog, or lighting variation. Do not use #00ff00 inside the asset.
Subject: hand-laid charcoal stone transition with one ankle-flat, fully embedded deep burgundy-brown dark-timber inlay and no more than three small aged-brass plates level with the floor. Preserve the full two-cell passage width.
Style/medium: polished hand-painted high-resolution 2D dark-fantasy isometric game asset matching Images 2 and 3; warm upper-left lighting, subtle violet cave bounce, low saturation, restrained contrast; not pixel art, not 3D render, not cartoon.
Constraints: Image 1's W seam, upper-left passage vector, and surface-side swap are mandatory; no S/N-direction backslash seam; no green, olive, moss, or glow in the asset; no walls, gate, door, stairs, ramp, raised rail, curb, spikes, chains, characters, props, UI, grid overlay, arrows, dashed boxes, labels, text, logos, watermark, smoke, fog, particles, cast shadow, contact shadow, or opaque pixels outside the diamond.
```

## 반복 기록

| 회차 | 결과 | 판정 |
|---:|---|---|
| 1 | W seam, upper-left passage, upper-left 소형 slab·lower-right 대형 slab 반전 확보 | 선택 원본 |

## alpha 후처리

- 도구:
  - `C:\Users\LDK-6248\.codex\skills\.system\imagegen\scripts\remove_chroma_key.py`
- 옵션:
  - `--auto-key border`
  - `--soft-matte`
  - `--transparent-threshold 12`
  - `--opaque-threshold 220`
  - `--despill`
- 감지 key: `#03f905`
- 이미지: `1254×1254`
- alpha bbox: `(13, 264, 1245, 1020)`
- 투명 픽셀: `1,092,516`
- 부분 투명 픽셀: `3,168`
- 불투명 픽셀: `476,832`
- 모서리 alpha: 네 곳 모두 `0`
- 남은 greenish opaque 픽셀: `0`

## exact 정합 상태

- W seam은 좌하단→우상단이며 passage vector는 screen upper-left다.
- corridor 소형 slab은 upper-left, room 대형 slab은 lower-right에 있어 E와 표면 측이 반대다.
- strict 2:1 투영과 center anchor 방향은 승인 기준에 맞는다.
- 생성 결과의 alpha bbox는 guide bbox보다 커 현재 파일을 runtime에 바로 사용하지 않는다.
- 전체 공간 자산 승인 뒤 guide mask 안에 결정적으로 fit하고 native `256×128`로 slicing한다.
- W는 `back` 레이어이므로 실제 room·unit 합성 순서는 runtime 연결 단계에서 별도 확인한다.

## 후속 작업

1. 사용자가 W 문턱의 seam 방향, 표면 반전, 통행 가독성을 승인한다.
2. 승인 뒤 같은 재질 체계로 저채도 2셀 복도 표면을 제작한다.
3. 복도·폐색 그림자·가장자리 마스크 승인 뒤 exact contact sheet와 native slicing을 만든다.
4. 실제 runtime 경로와 manifest 연결은 전체 Stage 01 공간 자산 승인 뒤 별도 단계로 수행한다.
