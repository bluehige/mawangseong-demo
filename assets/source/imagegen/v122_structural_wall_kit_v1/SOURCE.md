# V1.2.2 구조용 연속 벽 키트 V1

- Generation model: GPT internal image generation
- Generated date: 2026-08-01
- Target version: v1.2.2

- Source image path: assets/source/imagegen/v122_structural_wall_kit_v1/segment_axis_ne_sw_selected_raw_chroma.png
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v1/segment_axis_ne_sw_selected_alpha.png
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v1/segment_axis_nw_se_selected_raw_chroma.png
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v1/segment_axis_nw_se_selected_alpha.png
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v1/segment_run_long_selected_raw_chroma.png
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v1/segment_run_long_selected_alpha.png
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v1/vertex_corner_selected_raw_chroma.png
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v1/vertex_corner_selected_alpha.png
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v1/vertex_end_selected_raw_chroma.png
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v1/vertex_end_selected_alpha.png
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v1/vertex_junction_selected_raw_chroma.png
- Source image path: assets/source/imagegen/v122_structural_wall_kit_v1/vertex_junction_selected_alpha.png

- Runtime image path: assets/tiles/cave_v2/structural_walls_v1/wall_segment_axis_ne_sw.png
- Runtime image path: assets/tiles/cave_v2/structural_walls_v1/wall_segment_axis_nw_se.png
- Runtime image path: assets/tiles/cave_v2/structural_walls_v1/wall_vertex_corner.png
- Runtime image path: assets/tiles/cave_v2/structural_walls_v1/wall_vertex_end.png
- Runtime image path: assets/tiles/cave_v2/structural_walls_v1/wall_vertex_junction.png

## 제작 목적

기존 `wall_edges`는 독립 장식 오브젝트를 `straight/end/corner`로 잘못 분류한 자산이다. 이 키트는 닫힌 격자 변을 채우는 벽 본체와 정점 전용 모서리·끝·교차 블록을 별도 역할로 분리하기 위해 새로 만들었다.

## 선택 프롬프트 요약

- 벽 본체 원본: 장식이 없는 어두운 현무암 벽을 12블록 이상 길게 생성하고, 양쪽 종단면에서 멀리 떨어진 중앙 반복 구간만 사용
- 반대 축 본체: 같은 중앙 반복 구간을 수평 반전해 반대 화면 대각선 축으로 사용. 두 방향 모두 같은 원본 높이·두께·벽돌 간격을 공유
- 모서리: 벽과 동일한 높이의 작은 정사각 접합 블록, 악마상·횃불·받침대 금지
- 끝마감: 한쪽 연결면과 한쪽 닫힌 면을 가진 좁은 구조 블록
- 교차: 모서리보다 약간 넓지만 같은 높이인 중립 접합 블록

## 제외 조건

- 독립 바닥 그림자와 바닥 잔해
- 종단 기둥이 포함된 완성형 벽
- 악마 얼굴, 횃불, 깃발, 해골, 뿔, 수정, 문양
- 문틀, 아치, 건설 소켓
- 벽 높이보다 큰 장식 탑

## 후처리

1. 설치된 imagegen `remove_chroma_key.py`로 녹색 배경을 제거했다.
2. `tools/prepare_v122_structural_wall_kit.py`가 긴 벽 원본의 중앙 `x=420..740` 구간만 잘라 종단면을 완전히 제외했다. 이 절단 구간의 양끝은 벽돌 몸체가 열린 상태이며 모서리·끝 부품이 별도로 마감한다.
3. 중앙 벽 바닥선은 실제 타일 변과 같은 `+0.5` 기울기가 되도록 투영 오차만 보정했고, 반대 축은 같은 구간을 수평 반전해 정확히 `-0.5`로 맞췄다.
4. 두 축 벽의 연결선은 런타임 알파 기준 각각 `+0.5`, `-0.5`이며, 기존처럼 파일명만 방향을 바꾼 그림을 허용하지 않는다.
5. 모든 런타임 자산은 공통 `256×256` 투명 캔버스를 쓴다. 직선 본체 anchor는 두 바닥 연결점의 중점 `[128, 196]`, 정점 부품 anchor는 바닥 중심 `[128, 232]`로 역할에 맞게 분리했다.
6. 후처리는 자산을 새로 그리지 않고 생성된 벽 그림의 배경 제거·중앙 절단·투영 보정·축소·반전·고정 캔버스 정렬만 수행한다.

## 자산 역할

| 런타임 자산 | 역할 |
|---|---|
| `wall_segment_axis_ne_sw.png` | N/S 격자 변의 구조용 벽 본체 |
| `wall_segment_axis_nw_se.png` | E/W 격자 변의 구조용 벽 본체 |
| `wall_vertex_corner.png` | 두 축이 꺾여 만나는 실제 모서리 정점 |
| `wall_vertex_end.png` | 벽 사슬의 끝 정점 |
| `wall_vertex_junction.png` | T자 또는 십자 정점 |

## 선택 과정

- 첫 벽 본체는 한 변에 쓰기에는 지나치게 길어 제외했다.
- 두 번째 본체는 벽돌 반복 수가 많아 제외했다.
- 네 블록짜리 본체 시안은 장식은 없지만 오른쪽 종단면이 보여, 반복하면 타일마다 벽이 끊겨 보이므로 런타임 본체에서 제외했다.
- 최종 본체는 긴 연속벽 원본의 중앙만 절단했다. 따라서 직선 부품에는 종단면이 없고 `corner/cap/junction` 부품만 정점을 마감한다.
- 첫 모서리 블록은 벽보다 높아 장식 기둥처럼 보여 제외했다.
- 최종 모서리는 벽과 동일한 네 단계 높이로 줄인 버전을 선택했다.
