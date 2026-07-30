# v1.2.2 Stage 01 저채도 2셀 복도 표면 생성 기록

## 정책 고정 필드

- Generation model: GPT internal image generation
- Generated date: 2026-07-30
- Target version: 1.2.2
- Source image path: assets/source/imagegen/v122_stage01_spatial/corridor_surface_2cell/corridor_surface_2cell_selected_raw_chroma.png
- Runtime image path: assets/tiles/stage_01/spatial/corridor_surface_stage01_2cell.png

선택 alpha 원본은 native `256×128` 공통 patch와 번호가 고정된 `128×64` 셀 4종으로 정합된다. 런타임은 좌표 parity에 따라 네 셀을 반복해 임의 길이 복도를 구성한다.

## 상태

- 자산 역할: Stage 01 `corridor_surface_2cell_base`
- 방향: 무방향 공통 표면
- 합성 역할: 방 바닥보다 낮은 시각 우선도의 상시 복도 바닥
- native 목표: `256×128`
- 상태: `RUNTIME_CONNECTED`
- 런타임 연결: Stage 01 `corridor_cells.00/10/01/11`
- 중간 후보:
  - `corridor_surface_2cell_intermediate_dense_raw_chroma.png`
- 선택 원본:
  - `corridor_surface_2cell_selected_raw_chroma.png`
- alpha 승인 후보:
  - `corridor_surface_2cell_selected_alpha_preview.png`

## 입력 이미지 역할

1. 2×2 isometric footprint 기준:
   - `C:\Users\LDK-6248\.codex\visualizations\2026\07\27\019fa2ea-5220-7fd2-9355-4b09f55558ad\v122_stage01_spatial_exact_guides_2026-07-29\v122_stage01_threshold_W_2cell_exact_guide.png`
2. 승인된 W 문턱의 corridor 재질 reference:
   - `assets/source/imagegen/v122_stage01_spatial/threshold_w_2cell/threshold_w_2cell_selected_alpha_preview.png`
3. 석판 밀도 교정 edit target:
   - `corridor_surface_2cell_intermediate_dense_raw_chroma.png`

## 기초 생성 프롬프트

```text
Use case: stylized-concept
Asset type: Stage 01 game environment floor tile source candidate; continuous low-saturation 2-by-2-cell isometric corridor surface
Input images: Image 1 is the mandatory exact projection and footprint guide only. Image 2 is the approved material, painterly-detail, lighting, and edge-treatment reference; use only its upper-left corridor-side small rough slabs as the surface language.
Primary request: Create one continuous 2-by-2-cell isometric corridor floor patch for a rough unfinished cavern fortress. Fill the entire diamond footprint with small, irregular, worn corridor slabs. This is ordinary always-visible walkable floor, not a selected route or a threshold.
Composition/framing: Match Image 1's full projected diamond footprint, aspect, viewing angle, and generous padding. The patch must read as one flat continuous floor at a single height. Keep the internal stone layout non-directional and repeat-friendly with no central focal symbol. Use restrained medium-small slab groupings that will remain legible after later downscaling to native 256x128.
Style/medium: Match Image 2's hand-painted dark fantasy game asset style, charcoal stone density, chipped hand-laid masonry, fine but restrained cracks, and slim natural edge treatment. Do not copy Image 2's timber transition, brass plates, or room-side large slabs.
Lighting/mood: very restrained warm light from upper-left, subtle low-value violet cave bounce from lower-right, soft contact darkening inside joints; no cast shadow outside the asset.
Color palette: low-saturation violet-gray, iron-gray, charcoal, tiny muted brown mineral notes only. Keep it visibly darker and less orderly than a room floor. No gold route color, no bright purple, no cyan, no green, no olive, no moss.
Materials/textures: rough small stone slabs with modest wear, a few hairline cracks and shallow chips; no rubble piles that block walking; no deep holes.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for local background removal. The background must be one uniform color with no shadows, gradients, texture, reflections, floor plane, or lighting variation.
Constraints: use Image 1 only for footprint geometry and ignore its arrow, seam, colored halves, dashed guides, border box, and labels; full diamond must be entirely corridor surface; crisp silhouette with generous padding; do not use #00ff00 anywhere in the asset; no opaque pixels or cast shadow outside the diamond; no seam across the patch; no threshold; no room-floor half; no timber; no metal plates; no perimeter rail or raised curb; no walls, gate, door, stairs, ramp, spikes, chains, props, characters, UI, grid overlay, arrows, boxes, labels, text, logos, or watermark.
```

## 선택 원본 최종 교정 프롬프트

```text
Use case: precise-object-edit
Asset type: Stage 01 game environment floor tile source candidate; continuous low-saturation 2-by-2-cell isometric corridor surface
Input images: Image 1 is the edit target. Image 2 is the approved material-scale reference, especially its upper-left corridor-side slabs.
Primary request: Change only the stone slab scale and layout inside Image 1. Reduce the number of individual stones substantially and replace the dense small cobble pattern with about 40 to 55 moderately sized, irregular, hand-laid worn corridor slabs across the full diamond. Make the layout rougher and less gridded, closer to Image 2's upper-left corridor-side material, while still reading as a flat continuous walkable floor after downscaling to native 256x128.
Invariants: preserve Image 1's exact full diamond silhouette, projection, viewing angle, canvas placement, flat single-height construction, low-saturation charcoal/violet-gray palette, subtle warm upper-left light, restrained violet lower-right bounce, flat solid #00ff00 chroma-key background, crisp separation, and no shadow outside the asset. Keep the surface non-directional and repeat-friendly with no central focal symbol.
Constraints: no seam across the patch; no threshold; no room-floor half; no timber; no metal plates; no perimeter rail or raised curb; no walls, gate, door, stairs, ramp, spikes, chains, rubble piles, deep holes, props, characters, UI, arrows, grid overlay, boxes, labels, text, logos, or watermark. Do not use #00ff00 anywhere in the floor asset. Keep everything else unchanged.
```

## 반복 기록

| 회차 | 결과 | 판정 |
|---:|---|---|
| 1 | 저채도·무방향·연속 표면과 W 문턱 재질 family 확보 | 석재 수가 지나치게 많아 native 축소 시 자갈 무늬로 뭉칠 위험, 중간본 보존 |
| 2 | 형상·색·조명을 유지하고 석판 수를 줄여 중간 크기 불규칙 slab으로 교정 | 선택 원본 |

## alpha 후처리

- 도구:
  - `C:\Users\LDK-6248\.codex\skills\.system\imagegen\scripts\remove_chroma_key.py`
- 옵션:
  - `--auto-key border`
  - `--soft-matte`
  - `--transparent-threshold 12`
  - `--opaque-threshold 220`
  - `--despill`
- 감지 key: `#03f010`
- 이미지: `1254×1254`
- alpha bbox: `(16, 219, 1241, 967)`
- 투명 픽셀: `1,107,075`
- 부분 투명 픽셀: `3,004`
- 불투명 픽셀: `462,437`
- 모서리 alpha: 네 곳 모두 `0`
- 남은 greenish alpha 픽셀: `0`

## 시각 계약 상태

- 2×2 전체 다이아몬드가 문턱 seam 없는 연속 복도 표면으로 채워졌다.
- 방 바닥보다 어둡고 저채도인 charcoal·violet-gray·iron-gray 재질을 사용했다.
- 황금 경로선, 목재, 황동판, 선택 표시와 중앙 문양은 없다.
- slab 배열은 방향성이 약하고 중앙 초점이 없어 직선·코너·교차 파생의 공통 재질 기준으로 사용할 수 있다.
- 생성 결과의 alpha bbox는 exact guide bbox보다 크므로 현재 파일을 runtime에 바로 사용하지 않는다.
- 전체 공간 자산 승인 뒤 guide mask 안에 결정적으로 fit하고 native `256×128`로 slicing한다.

## 후속 작업

1. 사용자가 저채도, 석판 크기, 방 바닥과의 구분을 승인한다.
2. 승인 뒤 같은 투영·광원 기준으로 공통 폐색 그림자 한 종을 제작한다.
3. 폐색 그림자 승인 뒤 암벽·보라 안개 가장자리 마스크 한 종을 제작한다.
4. 전체 Stage 01 공간 자산 승인 뒤 exact contact sheet·native slicing·runtime lookup을 적용한다.
