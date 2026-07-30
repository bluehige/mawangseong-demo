# v1.2.2 Stage 01 S 2셀 문턱 생성 기록

## 정책 고정 필드

- Generation model: GPT internal image generation
- Generated date: 2026-07-29
- Target version: 1.2.2
- Source image path: assets/source/imagegen/v122_stage01_spatial/threshold_s_2cell/threshold_s_2cell_selected_raw_chroma.png
- Runtime image path: assets/tiles/stage_01/spatial/threshold_stage01_S_2cell.png

선택 alpha 원본은 `tools/prepare_v122_stage01_spatial_assets.py`에서 native `256×128`로 정합되며 Stage 01 S/front 문턱 lookup에 연결된다.

## 상태

- 자산 역할: Stage 01 `threshold_S_2cell`
- 방향: `S`
- 레이어: `front`
- native 목표: `256×128`
- 상태: `RUNTIME_CONNECTED`
- 런타임 연결: Stage 01 `thresholds.S`
- 중간 후보:
  - `threshold_s_2cell_intermediate_green_stain_raw.png`
  - `threshold_s_2cell_intermediate_green_stain_alpha.png`
- 선택 원본:
  - `threshold_s_2cell_selected_raw_chroma.png`
- alpha 승인 후보:
  - `threshold_s_2cell_selected_alpha_preview.png`

## 입력 이미지 역할

1. exact S geometry reference:
   - `C:\Users\LDK-6248\.codex\visualizations\2026\07\27\019fa2ea-5220-7fd2-9355-4b09f55558ad\v122_stage01_spatial_exact_guides_2026-07-29\v122_stage01_threshold_S_2cell_exact_guide.png`
2. 녹갈색 얼룩 제거 edit target:
   - `assets/source/imagegen/v122_stage01_spatial/threshold_s_2cell/threshold_s_2cell_intermediate_green_stain_raw.png`
3. 최초 생성의 family reference:
   - `assets/source/imagegen/v122_stage01_spatial/threshold_n_2cell/threshold_n_2cell_selected_alpha_preview.png`
   - `assets/source/imagegen/v122_stage01_spatial/threshold_e_2cell/threshold_e_2cell_selected_alpha_preview.png`

## 선택 원본 최종 프롬프트

```text
Use case: precise-object-edit
Asset type: production-source 2D isometric game transition tile
Input images:
- Image 1: edit target, the current Stage 01 S-facing threshold candidate. Preserve its entire geometry, exact upper-left-to-lower-right seam, lower-left passage logic, stone layout, brass plates, lighting, camera, and flat chroma background.
- Image 2: mandatory S geometry reference only. Use it to ensure the current seam and passage orientation do not change.
Primary request: change only the small green/olive discoloration on the dark-timber seam just right of the center brass plate. Repaint that stained patch as the same deep worn burgundy-brown timber as the rest of the inlay, with continuous wood grain and no color seam.
Invariants:
- keep the upper-left-to-lower-right backslash seam exactly unchanged;
- keep large orderly room slabs on the upper-right and small rough corridor slabs on the lower-left;
- keep all three brass plates, every stone boundary, outer diamond, thickness, perspective, scale, and lighting unchanged;
- keep both passage cells open and the seam fully embedded;
- preserve the perfectly flat uniform #00ff00 chroma-key background outside the asset.
Style/medium: same polished hand-painted dark-fantasy isometric style as Image 1.
Constraints: no green, olive, moss, slime, glow, stain, or new material inside the asset; do not add, remove, resize, rotate, relight, recrop, or restyle anything else; no text, logo, watermark, shadow, fog, or opaque pixels outside the diamond.
```

## 반복 기록

| 회차 | 결과 | 판정 |
|---:|---|---|
| 1 | S seam, lower-left passage, upper-right 대형 slab·lower-left 소형 slab 반전 확보 | 중앙 목재에 녹갈색 얼룩이 남아 중간 후보로 보존 |
| 2 | 형상·표면 배치를 유지하고 얼룩만 적갈 목재로 교정 | 선택 원본 |

## alpha 후처리

- 도구:
  - `C:\Users\LDK-6248\.codex\skills\.system\imagegen\scripts\remove_chroma_key.py`
- 옵션:
  - `--auto-key border`
  - `--soft-matte`
  - `--transparent-threshold 12`
  - `--opaque-threshold 220`
  - `--despill`
- 감지 key: `#08f00f`
- 이미지: `1254×1254`
- alpha bbox: `(21, 243, 1233, 999)`
- 투명 픽셀: `1,098,954`
- 부분 투명 픽셀: `3,018`
- 불투명 픽셀: `470,544`
- 모서리 alpha: 네 곳 모두 `0`
- 남은 greenish opaque 픽셀: `0`

## exact 정합 상태

- S seam은 좌상단→우하단이며 passage vector는 screen lower-left다.
- room 대형 slab은 upper-right, corridor 소형 slab은 lower-left에 있어 N과 표면 측이 반대다.
- strict 2:1 투영과 center anchor 방향은 승인 기준에 맞는다.
- 생성 결과의 alpha bbox는 guide bbox보다 커 현재 파일을 runtime에 바로 사용하지 않는다.
- 전체 공간 자산 승인 뒤 guide mask 안에 결정적으로 fit하고 native `256×128`로 slicing한다.
- S는 `front` 레이어이므로 실제 room·unit 합성 순서는 runtime 연결 단계에서 별도 확인한다.

## 후속 작업

1. 사용자가 S 문턱의 seam 방향, 표면 반전, 통행 가독성을 승인한다.
2. 승인 뒤 같은 기준으로 W 2셀 문턱 하나를 생성한다.
3. N/E/S/W 승인 뒤 exact contact sheet와 native slicing을 만든다.
4. 실제 runtime 경로와 manifest 연결은 전체 Stage 01 공간 자산 승인 뒤 별도 단계로 수행한다.
