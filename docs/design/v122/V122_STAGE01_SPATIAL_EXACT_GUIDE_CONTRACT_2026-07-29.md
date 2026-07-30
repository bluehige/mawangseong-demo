# v1.2.2 Stage 01 공간 자산 exact 투영 guide 계약

## 상태

- 작성일: 2026-07-29
- 대상: 제품 기본 이중 전선 Stage 01
- 선행 승인: Stage 01 시각 비교 보드 승인
- 현재 단계: 왕좌 5×5와 N/E/S/W 2셀 문턱의 제작 좌표 고정
- 런타임 코드·데이터·그래픽 변경: 없음
- 모바일 웹: 제외

이 문서는 과거 단일 경로 `starting_layout.json`의 수치를 제작 기준으로 사용하지 않는다. 현재 제품 기본값인 `data/dungeon_quarter/layouts/stage01_dual_front_01.json`과 실제 `IsoMath`·`QuarterDungeonRenderer` 좌표를 기준으로 한다.

## 단일 좌표 기준

| 항목 | 고정값 |
|---|---:|
| 셀 | 128×64 |
| half tile | 64×32 |
| 셀 중심 X | `(cell_x - cell_y) × 64` |
| 셀 중심 Y | `(cell_x + cell_y) × 32` |
| 셀 꼭짓점 순서 | top → right → bottom → left |
| 셀 상대 꼭짓점 | `[0,-32] [64,0] [0,32] [-64,0]` |

모든 제작·슬라이스 좌표는 `visual_scale = 1`인 native 투영 좌표를 사용한다. 현재 전체 28×26 그리드에서 계산되는 화면 표시 scale `0.42`는 진단값일 뿐 원본에 bake하지 않는다. full-canvas 카메라 배율이 바뀌어도 원본 비율은 유지되어야 한다.

정밀 데이터 원본은 `docs/design/v122/guides/stage01_spatial_exact_guide.json`이다.

## 왕좌 5×5

### 런타임 정합

| 항목 | 값 |
|---|---|
| instance | `throne` |
| module | `room_throne_01` |
| grid origin | `[23,0]` |
| object | `throne_f` |
| anchor cell | `[2,2]` |
| facing | `SW` |
| layer | `back` |
| open mask | `04` |
| 열린 면 | `S` |
| 막힌 면 | `N`, `E`, `W` |
| S socket | `[2,4]`, `[3,4]` |
| 연결 corridor | `path_merge_throne`, origin `[25,5]` |

### native 투영

- 5×5 footprint bounds: `x -320..320`, `y -32..288`
- footprint 크기: `640×320`
- footprint 꼭짓점:
  - top `[0,-32]`
  - right `[320,128]`
  - bottom `[0,288]`
  - left `[-320,128]`
- 남쪽 2셀 개구부 polyline:
  - `[-192,192] → [-128,224] → [-64,256]`

### 1024 제작 guide

- canvas: `1024×1024`, 투명
- guide scale: `1.5`
- iso origin: `[512,552]`
- 바닥 다이아몬드 bounds: `[32,504,960,480]`
- 바닥 꼭짓점:
  - `[512,504]`
  - `[992,744]`
  - `[512,984]`
  - `[32,744]`
- 남쪽 2셀 개구부:
  - `[224,840] → [320,888] → [416,936]`
- 최소 alpha 여백:
  - 좌·우 32px
  - 아래 40px
  - 세로 실루엣은 상단 32px 안쪽

왕좌의 높은 등받이와 장식은 바닥 투영 위쪽 alpha 영역을 사용한다. 바닥 다이아몬드 밖에 보행 가능한 석판을 추가하지 않는다. 결과는 정면 직사각형이나 픽셀아트가 아니라 Stage 01 입구와 같은 회화형 재질 밀도로 읽혀야 한다.

## N/E/S/W 2셀 문턱

### 공통 footprint

| 항목 | 값 |
|---|---:|
| 논리 patch | 2×2 cells |
| native bounds | `[-128,-32,256,128]` |
| native 크기 | 256×128 |
| socket 한 칸 edge | 71.554 |
| paired opening | 143.108 |
| 제작 canvas | 1024×1024 |
| guide scale | 3.0 |
| iso origin | `[512,416]` |
| 제작 patch bounds | `[128,320,768,384]` |

문턱은 선이나 안내 표시가 아니라 방 바닥과 복도 바닥 사이의 같은 높이 석재 transition이다. 황금색은 guide에서 정확한 seam을 표시하기 위한 색일 뿐 런타임 제작물의 재질색이 아니다.

### 방향별 방·복도·레이어

| 방향 | 방 셀 | 복도 셀 | 방/복도 side | 합성 레이어 |
|---|---|---|---|---|
| N | `[0,1] [1,1]` | `[0,0] [1,0]` | `N ↔ S` | `back` |
| E | `[0,0] [0,1]` | `[1,0] [1,1]` | `E ↔ W` | `front` |
| S | `[0,0] [1,0]` | `[0,1] [1,1]` | `S ↔ N` | `front` |
| W | `[1,0] [1,1]` | `[0,0] [0,1]` | `W ↔ E` | `back` |

`N/W = back`, `E/S = front`는 현재 `QuarterDungeonRenderer._socket_render_layer()`와 일치한다. 방향별 자산을 단순 회전만 해서 레이어 의미를 잃으면 안 된다.

## 산출물

- 비교 보드:
  - `C:\Users\LDK-6248\.codex\visualizations\2026\07\27\019fa2ea-5220-7fd2-9355-4b09f55558ad\v122_stage01_spatial_exact_guides_2026-07-29\v122_stage01_spatial_exact_guide_board_2026-07-29.png`
- 개별 guide:
  - `v122_stage01_throne_5x5_exact_guide.png`
  - `v122_stage01_threshold_N_2cell_exact_guide.png`
  - `v122_stage01_threshold_E_2cell_exact_guide.png`
  - `v122_stage01_threshold_S_2cell_exact_guide.png`
  - `v122_stage01_threshold_W_2cell_exact_guide.png`
- 재생성 도구:
  - `tools/build_stage01_spatial_exact_guide.mjs`

개별 PNG는 제작 좌표 reference이며 런타임 자산이 아니다.

## 다음 생성 단계의 합격 조건

1. 왕좌 바닥의 5×5 다이아몬드와 S 2셀 입구가 guide에 맞는다.
2. 왕좌의 N/E/W는 막힌 암벽으로 읽히며 가짜 출구가 없다.
3. 문턱 4종은 각각 정확한 2×2 patch와 2셀 seam을 사용한다.
4. N/W는 후면, E/S는 전면 폐색 관계를 유지한다.
5. 문턱은 황금 선이 아니라 저채도 보라 회색·철색 석재로 읽힌다.
6. 방과 복도의 바닥 높이, 좌상단 온광, 보라 반사광, 접촉 그림자 방향이 같다.
7. 생성 원본을 바로 런타임에 넣지 않고 alpha·scale·socket 정합 뒤 별도 승인한다.

## 이번 단계에서 하지 않은 것

- GPT 내부 이미지 생성
- 런타임 asset manifest 연결
- renderer 변경
- 화면 실행·플레이·전체 QA
- 빌드·커밋·푸시
