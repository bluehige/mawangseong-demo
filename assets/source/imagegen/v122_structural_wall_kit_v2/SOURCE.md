# V1.2.2 구조벽 V2 생성 기록

- Generation model: GPT internal image generation
- Generated date: 2026-08-01
- Target version: v1.2.2
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v2/segment_run_long_selected_raw_chroma.png
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v2/segment_run_long_selected_alpha.png
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v2/vertex_corner_selected_raw_chroma.png
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v2/vertex_corner_selected_alpha.png
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v2/vertex_corner_directional_sheet_selected_raw_chroma.png
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v2/vertex_corner_directional_sheet_selected_alpha.png
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v2/vertex_end_selected_raw_chroma.png
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v2/vertex_end_selected_alpha.png
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v2/vertex_end_directional_sheet_selected_raw_chroma.png
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v2/vertex_end_directional_sheet_selected_alpha.png
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v2/vertex_junction_selected_raw_chroma.png
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v2/vertex_junction_selected_alpha.png
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v2/vertex_junction_directional_sheet_selected_raw_chroma.png
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v2/vertex_junction_directional_sheet_selected_alpha.png
- Runtime image path: assets/tiles/cave_v2/structural_walls_v2/wall_segment_axis_ne_sw.png
- Runtime image path: assets/tiles/cave_v2/structural_walls_v2/wall_segment_axis_nw_se.png
- Runtime image path: assets/tiles/cave_v2/structural_walls_v2/wall_vertex_corner_wn.png
- Runtime image path: assets/tiles/cave_v2/structural_walls_v2/wall_vertex_corner_ne.png
- Runtime image path: assets/tiles/cave_v2/structural_walls_v2/wall_vertex_corner_es.png
- Runtime image path: assets/tiles/cave_v2/structural_walls_v2/wall_vertex_corner_sw.png
- Runtime image path: assets/tiles/cave_v2/structural_walls_v2/wall_vertex_end_n.png
- Runtime image path: assets/tiles/cave_v2/structural_walls_v2/wall_vertex_end_e.png
- Runtime image path: assets/tiles/cave_v2/structural_walls_v2/wall_vertex_end_s.png
- Runtime image path: assets/tiles/cave_v2/structural_walls_v2/wall_vertex_end_w.png
- Runtime image path: assets/tiles/cave_v2/structural_walls_v2/wall_vertex_junction_new.png
- Runtime image path: assets/tiles/cave_v2/structural_walls_v2/wall_vertex_junction_nes.png
- Runtime image path: assets/tiles/cave_v2/structural_walls_v2/wall_vertex_junction_esw.png
- Runtime image path: assets/tiles/cave_v2/structural_walls_v2/wall_vertex_junction_nsw.png

## 제작 목적

- 기존 보라색 5단 구조벽과 독립 석탑형 정점을 폐기한다.
- 타일 경계를 따라 이어지는 낮은 2단 회색 석벽으로 통일한다.
- 직선 2축과 방향별 모서리·끝마감·T분기를 별도 자산으로 관리한다.
- 횃불, 문틀, 문양, 기둥, 바닥판 같은 장식을 구조벽에 섞지 않는다.

## 최종 프롬프트 요약

공통 조건은 `2:1 isometric`, `exactly two masonry courses`, `soot-dark charcoal gray`, `no purple/magenta/gold`, `no torch/door/ornament/emblem/floor`, `flat #00FF00 chroma-key background`이다. 직선은 장식과 종단면이 없는 긴 반복 구간, 모서리는 2×2 배열의 네 방향 L자 연결부, 끝마감은 네 방향 종단부, 분기는 빠진 방향이 서로 다른 네 종류의 짧은 T 연결부로 생성했다.

초기 단일 모서리·끝·분기 이미지는 재질과 높이를 확인한 중간 후보로만 보존했다. 런타임에는 방향을 명확히 나눈 2×2 시트만 절단해 사용했다.

목표 팔레트는 깊은 그림자 `#121416`, 벽면 `#24272A`, 윗면 `#34383B`, 가장자리 빛 `#51565A`로 지정했다.

## 후처리

Postprocessed date: 2026-08-02

1. `remove_chroma_key.py`의 border 자동 키, soft matte, despill을 사용해 녹색 배경을 투명화했다.
2. `tools/prepare_v122_structural_wall_kit_v2.py`가 긴 직선 원본에서 장식 없는 중앙 약 3블록 구간 `(730, 250, 1030, 680)`만 자르고 두 화면 대각축을 만든다. 과거 8블록 구간을 같은 한 칸 폭으로 압축해 벽 몸체가 약 4px로 납작해진 절단은 사용하지 않는다.
3. 직선 연결선을 2:1 등각 격자의 `+0.5/-0.5` 기울기로 보정한다.
4. 방향별 시트는 사분면별로 분리하고 실제 물리 접점을 공통 anchor에 맞춘다.
5. 모든 런타임 PNG는 `256×256` 투명 캔버스에 배치한다.
6. 직선 본체 폭은 원본 캔버스에서 `177px`, 모서리·끝·T분기 본체 폭은 각각 `132px`, `90px`, `156px`로 맞춘다. 접속점 좌표는 바꾸지 않아 한 칸 경계 길이는 유지한다.
7. 최종 측정값은 `1280×720`에서 셀 경계 반복 간격 `20.04px`, 겹침 포함 한 bitmap connector span `22.28px`, 벽 중심의 벽축 직각 두께 `9.16px`, 벽 중심의 세로 alpha 외곽 `10.41px`, 대각 위치 차이를 포함한 전체 bitmap 세로 외곽 `20.60px`다. 원본 anchor 범위를 벽 높이나 화면 크기로 해석하지 않는다.

생성 모델 원본은 보존하며 런타임 파일에는 녹색 배경이나 보라색 조명이 남지 않는다.
