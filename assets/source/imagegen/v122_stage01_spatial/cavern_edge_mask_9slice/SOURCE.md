# v1.2.2 Stage 01 암벽 가장자리 9-slice 마스크 생성 기록

## 정책 고정 필드

- Generation model: GPT internal image generation
- Generated date: 2026-07-30
- Target version: 1.2.2
- Source image path: assets/source/imagegen/v122_stage01_spatial/cavern_edge_mask_9slice/cavern_edge_mask_9slice_selected_raw_chroma.png
- Runtime image path: assets/ui/stage_01/cavern_edge_mask_stage01_9slice.png

선택 alpha 원본은 `1024×1024` 9-slice runtime PNG로 최적화되며 stretch strip과 중앙의 고립 chroma alpha는 결정적으로 제거된다.

## 상태

- 자산 역할: Stage 01 `cavern_edge_mask_9slice`
- 형태: 정사각형 9-slice 암벽 프레임
- 대상 화면: 1920 full-canvas, 1366/1280 compact
- 상태: `RUNTIME_CONNECTED`
- 런타임 연결: Stage 01 비입력 `CanvasLayer`의 `NinePatchRect`
- 중간 후보:
  - `cavern_edge_mask_9slice_intermediate_thick_raw_chroma.png`
  - `cavern_edge_mask_9slice_intermediate_key_mixed_raw_chroma.png`
  - `cavern_edge_mask_9slice_intermediate_key_mixed_alpha.png`
  - `cavern_edge_mask_9slice_intermediate_haze_raw_chroma.png`
  - `cavern_edge_mask_9slice_intermediate_haze_alpha.png`
  - `cavern_edge_mask_9slice_intermediate_haze_alpha_contracted.png`
- 선택 원본:
  - `cavern_edge_mask_9slice_selected_raw_chroma.png`
- alpha 후보:
  - `cavern_edge_mask_9slice_selected_alpha_preview.png`

## 입력 이미지 역할

1. Stage 01 암벽·팔레트 reference:
   - `assets/backgrounds/v2/bg_cave_f_3x3_01.png`
2. 1920 full-canvas·1280 compact layout context:
   - `C:\Users\LDK-6248\.codex\visualizations\2026\07\27\019fa2ea-5220-7fd2-9355-4b09f55558ad\v122_stage01_visual_comparison_board_2026-07-29.png`

## 기초 생성 프롬프트

```text
Use case: stylized-concept
Asset type: reusable 9-slice full-canvas irregular cavern edge-mask overlay for Stage 01 management, placement, and combat maps
Input images: Image 1 is the mandatory Stage 01 cave-rock, low-saturation violet haze, painterly material, and darkness reference. Use only its outer cave-edge language; do not copy its floor, architecture, torches, chains, platforms, or central scene. Image 2 is layout context only: the world map must remain fully readable in the large center while the mask replaces dead black at the outer canvas edges. Do not reproduce any UI or text.
Primary request: Create one square 1:1 transparent-frame source designed for 9-slice stretching to both 1920 full-canvas and 1366/1280 compact layouts. Place irregular dark cave rock silhouettes and extremely restrained desaturated violet mist only around the outer perimeter. The frame should make the map fade naturally into a cavern instead of ending as a rectangular image.
Composition/framing: square canvas. Keep the central 70 to 74 percent of both width and height perfectly empty chroma background with a large clean rectangular opening. Keep all important detail inside the outer 8 to 14 percent border band. Four corners may be slightly heavier irregular rock clusters; horizontal and vertical middle edge strips must be visually simple and stretch-safe. Bottom edge should be sparse and low so the command rail remains unobstructed. Inner edge must be irregular and softly feathered by about 4 to 7 percent, never a clean rectangle or hard vignette line.
Style/medium: polished hand-painted dark-fantasy cavern edge overlay matching Image 1; coarse charcoal rock, subtle chipped silhouettes, faint low-value violet cave mist tucked between rocks; no scenery inside the opening.
Color palette: near-black charcoal, iron-gray, desaturated violet-gray, tiny deep burgundy-brown mineral notes. Violet mist must remain very dark and subtle. No bright purple, gold, orange torchlight, cyan, green, olive, or glow.
Scene/backdrop: every unused pixel, including the entire center opening, must be a perfectly flat solid #00ff00 chroma-key background for local background removal. Background must have no gradient, texture, reflection, floor plane, shadow, fog, or lighting variation. Do not use #00ff00 in the frame art.
Constraints: frame/edge-mask only; central opening entirely clear; no floor, path, room, wall architecture, gate, door, throne, stairs, bridge, torch, flame, chain, crystals, props, characters, UI, grid, labels, text, logos, or watermark; no opaque black center; no closed cave tunnel; no regular rectangular border; no bright focal point; no cast shadow into the central opening; generous clean center and stretch-safe edge middles.
```

## 두께·채도 교정 프롬프트

```text
Use case: precise-object-edit
Asset type: reusable 9-slice full-canvas irregular cavern edge-mask overlay for Stage 01
Input images: Image 1 is the edit target. Image 2 is the mandatory darkness and low-saturation Stage 01 material reference.
Primary request: Change only the border thickness distribution and violet intensity of Image 1. Make the bottom middle edge substantially thinner and lower, about 6 to 8 percent of canvas height outside the corners, so it cannot compete with the command rail. Make the left and right middle edge strips about 8 to 10 percent of canvas width. Keep the top edge around 10 to 12 percent and preserve slightly heavier irregular corners. Reduce the brightness and saturation of all violet rock reflections and mist by about 45 percent to match Image 2's darkest outer cave edges. Simplify the middle stretches of all four edges so they are stretch-safe for 9-slice.
Invariants: preserve the square canvas, huge perfectly flat solid #00ff00 central opening, irregular hand-painted cave-rock silhouette, four-corner continuity, crisp isolated outer boundary, absence of cast shadow into the center, and absence of scenery or UI. Do not change the center opening into a smaller or rounded tunnel.
Constraints: frame-only asset; no floor, path, room, architecture, torch, flame, chain, crystals, props, characters, UI, text, logos, or watermark; no bright purple glow; no regular hard rectangular border; no opaque center; do not use #00ff00 in the rock art. Keep everything else unchanged.
```

## 안개 혼색 교정 프롬프트

```text
Use case: precise-object-edit
Asset type: reusable 9-slice full-canvas irregular cavern edge-mask overlay for Stage 01
Input images: Image 1 is the edit target.
Primary request: Change only the loose smoke, fog, haze, and feather patches protruding from the inner rock boundary into the green center. Remove every such patch completely and replace it with the exact same perfectly flat solid #00ff00 as the central chroma background. Keep the purple reflections painted on the solid rock surfaces themselves, but no mist or translucent-looking material may extend beyond the rock silhouette.
Invariants: preserve every solid rock silhouette, border thickness, 9-slice-safe middle strips, thinner bottom middle, top profile, side widths, four corners, square canvas, crop, darkness, and restrained violet reflections on rock. Preserve the entire central opening and outside unused area as uniform #00ff00.
Constraints: no smoke, mist, fog, glow, cyan, teal, mint, green-gray, olive, or pale patches inside the frame art; no new objects; no floor, architecture, torches, props, characters, UI, text, logos, or watermark; do not change any solid rock geometry or lighting; keep everything else unchanged.
```

## 반복 기록

| 회차 | 결과 | 판정 |
|---:|---|---|
| 1 | 중앙 개방·불규칙 암벽 frame 확보 | 하단이 두껍고 보라 휘도가 높아 중간본 |
| 2 | 하단·측면을 줄이고 9-slice middle strip 단순화 | key 혼색 안개가 남아 중간본 |
| 3 | 안개를 저채도 보라회색으로 교정 시도 | chroma alpha에서 청록회색 잔여가 보여 중간본 |
| 4 | 안개 protrusion을 제거하고 solid rock의 보라 반사광만 유지 | 선택 원본 |

## alpha 후처리

- 도구:
  - `C:\Users\LDK-6248\.codex\skills\.system\imagegen\scripts\remove_chroma_key.py`
- 옵션:
  - `--key-color #00ff00`
  - `--auto-key none`
  - `--soft-matte`
  - `--transparent-threshold 12`
  - `--opaque-threshold 220`
  - `--despill`
- 명시 key: `#00ff00`
- 이유: 암벽이 canvas 외곽 전체에 닿아 border auto-key가 검은 암벽을 잘못 감지함
- 이미지: `1254×1254`
- alpha bbox: `(0, 0, 1254, 1254)`
- 투명 픽셀: `1,254,028`
- 부분 투명 픽셀: `12,200`
- 불투명 픽셀: `306,288`
- 네 모서리 alpha: 모두 `255`, 의도된 frame corner
- 남은 greenish alpha 픽셀: `0`

## 9-slice 계약

- source 전체 frame은 1:1 정사각형이다.
- runtime은 중앙을 그리지 않는 `draw_center=false`를 사용한다.
- 중앙 chroma 편차로 생긴 고립 alpha는 center slice가 렌더되지 않아 화면에 나타나지 않는다.
- corner rock은 고정하고 horizontal·vertical middle strip만 확장한다.
- runtime에서는 암벽 뒤에 저채도 보라 feather를 code-native gradient로 별도 그려 색과 강도를 해상도별로 고정한다.
- bottom middle은 top·corner보다 얇아 명령 rail과 경쟁하지 않는다.

## 후속 작업

1. 왕좌·문턱 4종·복도·폐색·frame을 runtime 크기로 exact slicing한다.
2. asset manifest와 QuarterDungeonRenderer lookup에 연결한다.
3. 1920·1280에서 path·unit·UI를 가리지 않는지 직접 영향 검증한다.
