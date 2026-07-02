이 파일이 왜 필요한지: `cave_f` 쿼터뷰 던전의 가장자리, 벽, 문, 코너 장식 PNG가 어떤 생성 이미지에서 나왔고 어떻게 후처리됐는지 남겨 재생성 기준을 유지한다.

# Cave F Tile Add-On Source

## 생성 원본

사용자가 요청한 그래픽 제작 경로에 맞춰 GPT 이미지 생성으로 제작했다.

```text
C:\Users\blueh\.codex\generated_images\019f1d97-678f-73e1-9106-3e8b68f3c791\ig_00e2a7b6118541d1016a464f3949748191915528583f62d149.png
```

프로젝트에 보존한 원본 atlas:

```text
assets/tiles/cave_f/gpt2_cave_f_addon_source_atlas.png
```

## 후처리 규칙

- 초록 배경을 투명 alpha로 변환했다.
- 4x4 atlas를 셀 단위로 나눈 뒤, 각 셀의 실제 석재 픽셀만 잘라냈다.
- `edge`와 `overlay`는 바닥 타일 위에 얹히도록 낮은 높이로 맞췄다.
- `wall`은 뒤쪽 벽 레이어에서 쓰기 위해 `128x96`으로 맞췄다.
- `door`는 문 아치가 세로로 읽히도록 `128x128`로 맞췄다.

## 최종 파일

```text
assets/tiles/cave_f/edge/edge_cave_f_nw_lip.png
assets/tiles/cave_f/edge/edge_cave_f_ne_lip.png
assets/tiles/cave_f/edge/edge_cave_f_se_lip.png
assets/tiles/cave_f/edge/edge_cave_f_sw_lip.png
assets/tiles/cave_f/overlay/floor_cave_f_corner_inner_nw.png
assets/tiles/cave_f/overlay/floor_cave_f_corner_inner_ne.png
assets/tiles/cave_f/overlay/floor_cave_f_corner_inner_se.png
assets/tiles/cave_f/overlay/floor_cave_f_corner_inner_sw.png
assets/tiles/cave_f/overlay/floor_cave_f_corner_outer_nw.png
assets/tiles/cave_f/overlay/floor_cave_f_corner_outer_ne.png
assets/tiles/cave_f/overlay/floor_cave_f_corner_outer_se.png
assets/tiles/cave_f/overlay/floor_cave_f_corner_outer_sw.png
assets/tiles/cave_f/wall/wall_cave_f_ne_straight_00.png
assets/tiles/cave_f/wall/wall_cave_f_nw_straight_00.png
assets/tiles/cave_f/door/door_cave_f_ne_open.png
assets/tiles/cave_f/door/door_cave_f_nw_open.png
```

## 2026-07-02 추가: wall 0~15 mask variant 원본

사용자 피드백에 따라 “16개”를 서로 다른 소품 atlas로 해석하지 않고, 같은 동굴 벽/통로 구조가 `NW/NE/SE/SW` 연결 상태에 따라 달라지는 16개 방향 variant로 다시 제작했다.

방향 bit 기준:

```text
NW = 1
NE = 2
SE = 4
SW = 8
```

따라서 `wall_cave_f_mask_00.png`부터 `wall_cave_f_mask_15.png`는 `AutoTileMask.gd`의 0~15 mask 값과 1:1로 대응하기 위한 파일명이다. 여기서 mask는 “네 방향 중 어느 쪽이 연결되어 있는지 표시하는 숫자”다.

생성 원본:

```text
C:\Users\blueh\.codex\generated_images\019f1d97-678f-73e1-9106-3e8b68f3c791\ig_0896faf24d3f9297016a46701a32348191bd7f27c6271d78e9.png
```

프로젝트 보존 파일:

```text
assets/tiles/cave_f/gpt2_cave_f_wall_mask_source_atlas_chroma.png
assets/tiles/cave_f/gpt2_cave_f_wall_mask_source_atlas_alpha.png
```

최종 분할 파일:

```text
assets/tiles/cave_f/wall/wall_cave_f_mask_00.png
assets/tiles/cave_f/wall/wall_cave_f_mask_01.png
assets/tiles/cave_f/wall/wall_cave_f_mask_02.png
assets/tiles/cave_f/wall/wall_cave_f_mask_03.png
assets/tiles/cave_f/wall/wall_cave_f_mask_04.png
assets/tiles/cave_f/wall/wall_cave_f_mask_05.png
assets/tiles/cave_f/wall/wall_cave_f_mask_06.png
assets/tiles/cave_f/wall/wall_cave_f_mask_07.png
assets/tiles/cave_f/wall/wall_cave_f_mask_08.png
assets/tiles/cave_f/wall/wall_cave_f_mask_09.png
assets/tiles/cave_f/wall/wall_cave_f_mask_10.png
assets/tiles/cave_f/wall/wall_cave_f_mask_11.png
assets/tiles/cave_f/wall/wall_cave_f_mask_12.png
assets/tiles/cave_f/wall/wall_cave_f_mask_13.png
assets/tiles/cave_f/wall/wall_cave_f_mask_14.png
assets/tiles/cave_f/wall/wall_cave_f_mask_15.png
```

주의:

- 이 atlas는 “방향 variant 자산”의 원본이다.
- GPT 이미지 생성은 0~15 mask 의미를 수학적으로 보장하지 않으므로, 렌더러에 연결하기 전 F4 floor mask/F5 socket overlay와 함께 실제 방향이 맞는지 검수해야 한다.
- `tile_variant_manifest.json`에는 `wall_mask` 항목으로 파일명을 등록했다.
- 아직 `QuarterDungeonRenderer.gd`가 이 16장을 실제 wall variant 선택에 사용하도록 연결한 상태는 아니다.

## 렌더러 연결

- `tile_variant_manifest.json`에 `edges`, `corner_overlays`, `walls`, `doors` 파일명을 연결했다.
- `QuarterDungeonRenderer.gd`가 위 네 묶음을 로드한다.
- 누락 파일은 `debug_missing_addon_tiles()`로 확인할 수 있다.
- `QuarterModuleSmokeTest.gd`가 16개 add-on 리소스 로딩을 검증한다.
