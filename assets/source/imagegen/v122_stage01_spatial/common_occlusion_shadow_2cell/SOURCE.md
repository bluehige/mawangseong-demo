# v1.2.2 Stage 01 공통 2셀 폐색 그림자 생성 기록

## 정책 고정 필드

- Generation model: GPT internal image generation
- Generated date: 2026-07-30
- Target version: v1.2.2
- Source image path: assets/source/imagegen/v122_stage01_spatial/common_occlusion_shadow_2cell/common_occlusion_shadow_2cell_selected_raw_chroma.png
- Source image path: assets/source/imagegen/v122_stage01_spatial/common_occlusion_shadow_2cell/common_occlusion_shadow_2cell_selected_alpha_preview.png
- Runtime image path: assets/tiles/stage_01/spatial/common_occlusion_shadow_stage01_2cell.png

선택 alpha 원본은 승인된 복도 footprint bbox로 등록한 뒤 native `256×128`로 출력되며 문턱과 같은 rect에 낮은 alpha로 합성된다.

## 상태

- 자산 역할: Stage 01 `common_occlusion_shadow_2cell`
- 방향: 화면 하단 두 변
- 광원 기준: 화면 좌상단
- native 목표: `256×128`
- 상태: `RUNTIME_CONNECTED`
- 런타임 연결: Stage 01 `common_occlusion_shadow`
- 선택 원본:
  - `common_occlusion_shadow_2cell_selected_raw_chroma.png`
- alpha 승인 후보:
  - `common_occlusion_shadow_2cell_selected_alpha_preview.png`

## 입력 이미지 역할

1. 승인된 복도 표면의 projection·canvas reference:
   - `assets/source/imagegen/v122_stage01_spatial/corridor_surface_2cell/corridor_surface_2cell_selected_alpha_preview.png`
2. 2×2 exact footprint reference:
   - `C:\Users\LDK-6248\.codex\visualizations\2026\07\27\019fa2ea-5220-7fd2-9355-4b09f55558ad\v122_stage01_spatial_exact_guides_2026-07-29\v122_stage01_threshold_W_2cell_exact_guide.png`

## 선택 원본 최종 프롬프트

```text
Use case: stylized-concept
Asset type: reusable Stage 01 2D isometric environmental occlusion-shadow overlay for room and corridor bases
Input images: Image 1 is the approved 2-by-2 corridor surface reference for exact viewing angle, full diamond footprint, canvas placement, lighting direction, and painterly edge softness. Image 2 is the mandatory projection reference only. Do not reproduce either image's floor stones, seam, arrow, colored halves, dashed guides, or text.
Primary request: Create a separate shadow-only overlay that visually grounds room bases, corridor edges, and transition tiles into the same cavern floor. The overlay consists only of a thin irregular ambient-occlusion band following the two screen-lower perimeter edges of the exact 2-by-2 isometric diamond, meeting naturally at the bottom vertex. The lower-right side may be slightly deeper than the lower-left because the shared light comes from screen upper-left.
Composition/framing: preserve the same centered diamond registration as Image 1. Keep the central 70 to 80 percent of the diamond fully empty chroma background. Keep both upper perimeter edges fully empty. Shadow must remain inside or immediately under the two lower footprint edges, extend inward only about 8 to 12 percent of the diamond height, and feather softly toward the center. Do not create a complete outline.
Style/medium: restrained hand-painted dark-fantasy ambient occlusion, soft charcoal-violet brush texture, subtle broken edge, no hard vector line, no object silhouette.
Color palette: near-black charcoal, very dark desaturated violet-gray, tiny muted brown only. No gold, bright purple, cyan, green, olive, or glow.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for local background removal. The background must be uniform with no gradient, texture, reflection, floor plane, fog, or lighting variation. Do not use #00ff00 in the shadow.
Constraints: shadow-only asset; no floor fill; no stone slabs; no room, wall, rock, rubble, crack, decal, timber, metal, door, stairs, spikes, props, characters, UI, symbols, labels, text, logos, or watermark; no upper-edge shadow; no full diamond outline; no large opaque black plate; no cast shadow extending far outside the footprint; crisp isolated outer silhouette with soft inward feather; generous padding.
```

## 반복 기록

| 회차 | 결과 | 판정 |
|---:|---|---|
| 1 | 하단 두 변 V형 폐색, 우하단 심도 차, 중앙·상단 비움 확보 | 선택 원본 |

## alpha 후처리

- 도구:
  - `C:\Users\LDK-6248\.codex\skills\.system\imagegen\scripts\remove_chroma_key.py`
- 옵션:
  - `--auto-key border`
  - `--soft-matte`
  - `--transparent-threshold 12`
  - `--opaque-threshold 220`
  - `--despill`
- 감지 key: `#03f802`
- 이미지: `1254×1254`
- alpha bbox: `(21, 655, 1235, 1054)`
- 투명 픽셀: `1,490,541`
- 부분 투명 픽셀: `64,885`
- 불투명 픽셀: `17,090`
- 모서리 alpha: 네 곳 모두 `0`
- 남은 greenish alpha 픽셀: `0`

## 시각 계약 상태

- 좌상단 광원과 반대인 화면 하단 두 변에만 폐색이 있다.
- 중앙 70% 이상과 상단 두 변은 비어 있어 바닥 재질·캐릭터를 덮지 않는다.
- 완전한 다이아몬드 테두리나 이동 경계선으로 읽히는 hard outline이 없다.
- 방·복도·문턱의 공통 접지 계층으로 쓸 수 있는 무재질 shadow-only 원본이다.
- exact guide보다 넓은 source canvas이므로 runtime에 직접 사용하지 않는다.
- native slicing 뒤 합성 alpha는 renderer에서 낮은 값으로 제한한다.

## 후속 작업

1. 같은 full-canvas 방향으로 암벽·보라 안개 불규칙 가장자리 마스크 한 종을 제작한다.
2. 왕좌·문턱·복도·폐색·마스크 전체를 exact contact sheet로 정합한다.
3. 승인 자산을 runtime lookup에 연결하고 1920·1280에서 보이는 길과 walk map을 확인한다.
