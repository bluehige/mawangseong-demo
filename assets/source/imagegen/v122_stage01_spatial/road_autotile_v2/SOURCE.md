# Stage 01 연결형 도로 autotile v2 생성 기록

## 정책 고정 필드

- Generation model: GPT internal image generation
- Generated date: 2026-08-01
- Target version: v1.2.2
- Source image path: assets/source/imagegen/v122_stage01_spatial/road_autotile_v2/road_autotile_material_raw_chroma.png
- Source image path: assets/source/imagegen/v122_stage01_spatial/road_autotile_v2/road_autotile_material_alpha.png
- Runtime image path: assets/tiles/stage_01/spatial_road_autotile_v2/corridor_road_autotile_stage01_atlas.png

## 역할과 상태

- 자산 역할: Stage 01 일반 도로의 N/E/S/W 연결형 16-mask autotile atlas
- 런타임 셀: 128×64
- atlas 구성: 가로 mask 0~15, 세로 좌표 홀짝 재질 변형 `00`, `10`, `01`, `11`
- 상태: `RUNTIME_CANDIDATE`
- 기존 4셀 후보를 대체하며, 구형 `assets/tiles/stage_01/spatial/corridor_surface_stage01_cell_*.png`는 로드 실패 시 fallback으로만 남긴다.

## 생성 입력

- Image 1: 이전 대형 불규칙 석판 도로 재질 참고
- Image 2: 승인된 Stage 01 N 문턱의 색·광원·회화형 재질 참고
- 결과 원본: 1536×1024, 평평한 `#00ff00` chroma 배경
- 투명화: `remove_chroma_key.py --auto-key border --soft-matte --transparent-threshold 12 --opaque-threshold 220 --despill --force`
- exact 변환: `tools/prepare_v122_road_autotiles.py`

## 최종 생성 프롬프트

```text
Use case: stylized-concept
Asset type: master material source for a 2:1 isometric dark-fantasy fortress road autotile set
Input images: Image 1 is the current road-material reference; Image 2 is the approved Stage 01 doorway-threshold style and lighting reference.
Primary request: Create a new clean, flat, walkable fortress road surface master. Keep the believable large irregular slab character from Image 1, but simplify it to only 7–12 broad stone slabs across the full patch so the texture remains readable after heavy downscaling. Match Image 2's painterly dark-fantasy stone, muted charcoal and violet-gray palette, restrained warm highlights from the upper left, and shallow worn seams.
Composition/framing: one centered 2:1 isometric diamond surface, symmetrical usable margins, perfectly flat with no wall height and no perspective rise.
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for local removal; background must have no shadows, gradients, texture, reflections, floor plane, or lighting variation.
Materials/textures: aged basalt and dark fortress flagstone; broad low-frequency forms; subtle cracks; restrained edge wear.
Constraints: preserve a clean continuous material suitable for later N/E/S/W topology masking; no raised outer frame; no checkerboard grid; no tiny cobblestones; no gold route line; no wood; no brass; no props; no runes; no UI; no text; no watermark; do not use #00ff00 inside the road surface; crisp separated silhouette with generous padding.
```

## 구현 계약

- 4비트는 `N=1`, `E=2`, `S=4`, `W=8`이다.
- 런타임은 셀 좌표 홀짝이 아니라 연결 mask를 먼저 선택하고, 홀짝값은 같은 mask 안의 재질 반복을 줄이는 데만 사용한다.
- 길의 형태와 석재 재질은 atlas PNG에 미리 구워 둔다. 런타임에서 `draw_line`이나 `draw_polygon`으로 일반 도로 형상을 만들지 않는다.
- atlas 생성은 생성 원본의 alpha bbox 정규화, exact 2×2 재질 분할, 연결 mask 합성만 수행한다.

## 검수 포인트

- 장거리 직선, 90도 연결, T자, 십자와 끝점이 실제 연결 방향과 일치해야 한다.
- 서로 맞닿는 셀의 포트 폭이 같고 끊긴 검은 틈이 없어야 한다.
- 1280×720에서 석재가 자갈이나 규칙적인 바둑판으로 보이지 않아야 한다.
- 금색 선은 도로 재질에 포함하지 않으며, 전술 경로 안내선은 별도 UI 레이어로 유지한다.
