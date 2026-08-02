# V1.2.2 그래픽 통일 Phase 4 — 도로 런타임 미리보기

- 작업일: 2026-08-01
- 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `f9a912b8217f58b1e023dae4739cf37bc307d49b`
- 마지막 커밋 SHA: `f9a912b8217f58b1e023dae4739cf37bc307d49b` (이번 미리보기 변경은 미커밋)
- 원격 푸시: 하지 않음

## 목표

도로 표면 후보를 기존 도로 파일에 덮어쓰지 않고 별도 후보 경로로 분리한 뒤 Stage 01 실제 관리 화면에 연결했다. 사용자가 게임 화면에서 방·통로·도로의 재질과 해상도 조화를 판단할 수 있도록 1920×1080 및 1280×720 캡처를 생성했다.

## 변경 범위

- `data/dungeon_quarter/asset_manifest.json`
  - Stage 01 `corridor_cells`를 `assets/tiles/stage_01/spatial_road_candidate/`의 후보 셀 4종으로 연결했다.
- `tools/prepare_v122_road_candidate.py`
  - 생성 원본의 투명 여백을 제거하고 256×128 기준으로 맞춘 뒤 아이소메트릭 4분할 셀을 만드는 결정적 변환 도구다.
- `assets/source/imagegen/v122_stage01_spatial/road_surface_2cell/`
  - GPT 내부 이미지 생성 원본, 투명화 미리보기, 출처 문서를 보존했다.
- `assets/tiles/stage_01/spatial_road_candidate/`
  - 실제 런타임에서 읽는 후보 도로 전체 표면과 셀 4종이다.
- `tools/V122RoadCandidateCapture.gd`, `tools/V122RoadCandidateCapture.tscn`
  - 실제 GameRoot를 Stage 01 관리 화면으로 초기화해 1280×720 캡처를 만드는 검수 장면이다.
- `tools/tests/V122VisualTextureConsistencyTest.gd`, `tools/tests/V122VisualTextureConsistencyTest.tscn`
  - 대표 후보 텍스처 크기와 필터 기준을 검사한다.

## 생성·런타임 출처

- Generation model: `GPT internal image generation`
- Generated date: `2026-08-01`
- Target version: `1.2.2`
- Source image path: `assets/source/imagegen/v122_stage01_spatial/road_surface_2cell/road_surface_2cell_generated_raw_black.png`
- Source image path: `assets/source/imagegen/v122_stage01_spatial/road_surface_2cell/road_surface_2cell_alpha_preview.png`
- Runtime image path: `assets/tiles/stage_01/spatial_road_candidate/corridor_surface_stage01_2cell_candidate.png`
- Runtime image path: `assets/tiles/stage_01/spatial_road_candidate/corridor_surface_stage01_cell_00_candidate.png`
- Runtime image path: `assets/tiles/stage_01/spatial_road_candidate/corridor_surface_stage01_cell_01_candidate.png`
- Runtime image path: `assets/tiles/stage_01/spatial_road_candidate/corridor_surface_stage01_cell_10_candidate.png`
- Runtime image path: `assets/tiles/stage_01/spatial_road_candidate/corridor_surface_stage01_cell_11_candidate.png`

## 확인 결과

- `V122_VISUAL_TEXTURE_CONSISTENCY_TEST`: PASS
- `V122_STAGE01_SPATIAL_VISUAL_RUNTIME_TEST`: PASS
- 실제 캡처 장면: `CASTLE_STAGE_VISUAL_REVIEW`: PASS
- 실제 캡처 장면: `V122_ROAD_CANDIDATE_CAPTURE`: PASS
- 1920×1080 캡처: `tmp/castle_stage_review/stage_01_cave_1920x1080.png`
- 1280×720 캡처: `tmp/v122_road_candidate_review/stage_01_cave_1280x720.png`

## 사용자 확인 포인트

후보 도로는 어두운 대형 석재 판이 길 방향으로 이어지는 형태다. 현재 화면에는 기존 금색 경로 안내선과 일부 코드 기반 연결선이 함께 보이므로 도로 재질의 어울림은 판단할 수 있지만, 통로 교체 작업은 아직 완료되지 않았다. 승인 뒤에는 도로 색·판 크기·반복 간격을 다듬고, 다음 Phase에서 일반 연결 통로와 DAY 3 방어자 지름길의 선·원 도형을 동일한 자산 체계로 교체한다.

## 검수·인계 필드

Related tests: `V122_VISUAL_TEXTURE_CONSISTENCY_TEST`, `V122_STAGE01_SPATIAL_VISUAL_RUNTIME_TEST`, 실제 캡처 장면 — 모두 PASS
UI check: 실제 Stage 01 관리 화면 1920×1080 및 1280×720 캡처 생성 PASS
Unresolved issues: 사용자 최종 판단 전이며, 통로 연결선·DAY 3 지름길은 아직 코드 도형이다.

전체 회귀 검수, 전체 플레이 검수, Windows/Web 빌드와 커밋·푸시는 사용자가 요청하지 않아 수행하지 않았다.
