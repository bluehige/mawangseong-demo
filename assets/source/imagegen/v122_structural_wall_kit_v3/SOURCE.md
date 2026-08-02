# V1.2.2 구조 벽 V3 생성 기록

Generation model: GPT internal image generation
Generated date: 2026-08-02
Target version: 1.2.2
Source image path: assets/source/imagegen/v122_structural_wall_kit_v3/segment_run_long_selected_raw_chroma.png
Source image path: assets/source/imagegen/v122_structural_wall_kit_v3/segment_run_long_selected_alpha.png
Source image path: assets/source/imagegen/v122_structural_wall_kit_v3/vertex_corner_directional_sheet_selected_raw_chroma.png
Source image path: assets/source/imagegen/v122_structural_wall_kit_v3/vertex_corner_directional_sheet_selected_alpha.png
Source image path: assets/source/imagegen/v122_structural_wall_kit_v3/vertex_end_directional_sheet_selected_raw_chroma.png
Source image path: assets/source/imagegen/v122_structural_wall_kit_v3/vertex_end_directional_sheet_selected_alpha.png
Source image path: assets/source/imagegen/v122_structural_wall_kit_v3/vertex_junction_directional_sheet_selected_raw_chroma.png
Source image path: assets/source/imagegen/v122_structural_wall_kit_v3/vertex_junction_directional_sheet_selected_alpha.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_segment_axis_ne_sw.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_segment_axis_ne_sw_front_occluder.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_segment_axis_nw_se.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_segment_axis_nw_se_front_occluder.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_vertex_corner_wn.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_vertex_corner_ne.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_vertex_corner_ne_front_occluder.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_vertex_corner_sw.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_vertex_corner_sw_front_occluder.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_vertex_corner_es.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_vertex_corner_es_front_occluder.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_vertex_end_n.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_vertex_end_e.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_vertex_end_e_front_occluder.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_vertex_end_w.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_vertex_end_s.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_vertex_end_s_front_occluder.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_vertex_junction_new.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_vertex_junction_new_front_occluder.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_vertex_junction_nes.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_vertex_junction_nes_front_occluder.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_vertex_junction_nsw.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_vertex_junction_nsw_front_occluder.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_vertex_junction_esw.png
Runtime image path: assets/tiles/cave_v2/structural_walls_v3/wall_vertex_junction_esw_front_occluder.png

## 제작 목적과 기준

- 사용자가 승인한 던전 통로 레퍼런스를 기준으로, 기존 V2의 낮은 2단 벽을 높은 4단 구조 벽으로 교체한다.
- 절대 화면 픽셀이 아니라 맵의 논리 셀 사선 변 `E`를 기준으로 크기를 정한다.
- 직선 벽의 중심 단면 전체 높이는 `1.50E~1.75E`, 벽 수직면 높이는 `1.10E~1.35E`, 상판 깊이는 `0.40E~0.50E` 범위를 목표로 한다. 대각선 진행으로 더 커지는 전체 bitmap 외곽 높이는 벽 높이 판정에 사용하지 않는다.
- 연결 통로는 완전한 빈 공간으로 남기며, 구조 벽에는 문틀·횃불·기둥·문양·바닥 장식을 넣지 않는다.
- 색은 보라색이 아닌 그을린 회흑색과 중성 회색으로 통일한다.

## 생성 프롬프트 요약

1. 직선: 2:1 아이소메트릭, 장식 없는 긴 반복 석벽, 네 단의 큰 벽돌과 두꺼운 상판, 회흑색, 녹색 크로마 배경.
2. 모서리: WN/NE/SW/ES 네 방향 L자 구조 모서리를 2×2 시트에 각각 분리, 직선과 같은 높이·단수·재질.
3. 끝막음: N/E/W/S 네 방향의 닫힌 종단을 2×2 시트에 각각 분리, 돌출 기둥이나 문 장식 없음.
4. T분기: 빠진 방향이 서로 다른 NEW/NES/NSW/ESW 네 종류를 2×2 시트에 각각 분리, 동일한 연결 단면 유지.

## 후처리

1. `remove_chroma_key.py --auto-key border --soft-matte --transparent-threshold 12 --opaque-threshold 220 --despill`로 녹색 배경을 투명화했다.
2. `tools/prepare_v122_structural_wall_kit_v3.py`가 직선 connector를 `96×48`의 2:1 사선으로 정규화하고, 원본 캔버스 안에서 벽 외곽/connector/anchor 메타데이터를 만든다.
3. 화면 크기는 connector와 실제 맵 한 변의 비율로만 결정된다. 256×256과 위 좌표는 PNG를 조립하기 위한 원본 좌표이며 화면 합격값이 아니다.
4. 전체 높은 벽은 유닛 뒤에 그리며, E/S 방향의 최하단 약 `0.45E`만 별도 `front_occluder`로 잘라 유닛 앞에 그린다.
5. 생성된 모서리·끝·T분기 시트는 방향 분류 원본으로 보존한다. 각 조각에 한 칸 길이의 팔이 포함되어 있어 직선과 그대로 중복 합성하면 벽이 겹치므로, 현재 활성 세트는 `vertex_render_policy=edge_overlap`으로 직선 connector의 겹침만 사용한다. 접합 전용으로 국소화한 새 정점 자산이 생기기 전에는 이 원본을 구조 벽 위에 임의로 올리지 않는다.
