# V1.2.2 그래픽 통일 Phase 5~8 — 연결 도로·통로 런타임 교체

> 최종 정정(2026-08-01): 이 문서의 첫 구현에 포함됐던 회전·확대형 `connection_bridge`는 던전 벽 구조를 표현하지 못해 폐기했다. 최종 구현과 검증 결과는 `V122_DUNGEON_CORRIDOR_TOPOLOGY_FIX_2026-08-01.md`를 기준으로 한다.

- 작업일: 2026-08-01
- 목표 버전: 제품 1.2.2
- 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `f9a912b8217f58b1e023dae4739cf37bc307d49b`
- 마지막 커밋 SHA: `f9a912b8217f58b1e023dae4739cf37bc307d49b` (이번 변경은 미커밋)
- 원격 푸시: 하지 않음

## 목표와 완료 조건

Stage 01 도로를 실제 연결 방향에 맞는 자산으로 교체하고, 선·원 도형으로 그리던 일반 연결 통로와 DAY 3 방어자 지름길을 같은 석재 그림체의 이미지 자산으로 바꾼다. 실제 DAY 3 관리 화면에서 건설 전·후를 확인하고 관련 자동 테스트를 통과하면 완료로 본다.

## 완료한 작업

- 도로 선택을 좌표 홀짝 네 종류 반복에서 북·동·남·서 16방향 연결값 기반 atlas 선택으로 변경했다.
- 16개 연결 모양마다 네 가지 재질 변형을 가진 2048×256 atlas를 생성했다.
- 도로 atlas의 연결된 출구와 막힌 출구를 픽셀 단위로 검사하는 테스트를 추가했다.
- 첫 구현에서는 일반 연결 통로용 256×64 석재 strip을 두 끝점 사이에 회전·확대했으나, 최종 정정에서 이 방식과 자산을 폐기했다.
- DAY 3 방어자 지름길용 128×64 중앙 접속석은 미건설 위치 표시에만 남기고, 건설 후 통로는 실제 2×2 격자와 외곽 벽으로 교체했다.
- 금색 주요 경로 안내선을 더 얇고 흐리게 조정해 실제 석재 도로를 가리지 않도록 했다.
- 이전 Phase 4의 잘못된 후보 런타임 폴더와 후보 전용 변환·캡처 도구를 제거했다. 생성 원본과 출처 문서는 감사 기록으로 보존했다.
- 실제 GameRoot를 DAY 3으로 초기화하고 지름길 건설 전·후 1280×720 캡처를 생성하는 검수 장면을 만들었다.
- 상세 구조와 후속 수정 규칙은 `docs/design/v122/V122_ROAD_AND_PASSAGE_RESOURCE_IMPLEMENTATION_BRIEF_2026-08-01.md`에 기록했다.

## 주요 변경 파일

| 경로 | 변경 목적 |
|---|---|
| `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` | 연결값 기반 도로, bitmap 통로·지름길, 약해진 경로 안내선 |
| `data/dungeon_quarter/asset_manifest.json` | 도로 atlas·일반 통로·지름길 자산 등록 |
| `tools/prepare_v122_road_autotiles.py` | 16방향×4변형 도로 atlas 생성 |
| `tools/prepare_v122_defender_connector.py` | 지름길 교차판 런타임 자산 생성 |
| `tools/V122RoadAutotileCapture.gd` | 실제 DAY 3 건설 전·후 1280×720 캡처 |
| `tools/tests/V122Stage01SpatialVisualRuntimeTest.gd` | manifest·atlas 출구·렌더러 계약 검사 |
| `tools/tests/V122VisualTextureConsistencyTest.gd` | 대표 자산 크기·필터 일관성 검사 |

## 생성 그래픽과 출처

- Generation model: `GPT internal image generation`
- Generated date: `2026-08-01`
- Target version: `1.2.2`
- Source image path: `assets/source/imagegen/v122_stage01_spatial/road_autotile_v2/road_autotile_material_raw_chroma.png`
- Source image path: `assets/source/imagegen/v122_stage01_spatial/defender_connector_junction_v1/defender_connector_junction_raw_chroma.png`
- Runtime image path: `assets/tiles/stage_01/spatial_road_autotile_v2/corridor_road_autotile_stage01_atlas.png`
- Runtime image path: `assets/tiles/stage_01/spatial_passage_v1/defender_connector_junction_stage01.png`

남아 있는 생성 자산의 프롬프트·알파 제거·후처리 내역은 해당 원본 폴더의 `SOURCE.md`에 기록했다. 폐기한 `connection_bridge` 원본·런타임·변환 도구는 미추적 파일이어서 함께 삭제했다.

## 검증 결과

- `V122_VISUAL_TEXTURE_CONSISTENCY_TEST`: PASS
- `V122_STAGE01_SPATIAL_VISUAL_RUNTIME_TEST`: PASS
- `V122_DEFENDER_CONNECTOR_TEST`: PASS
- `V122_ROAD_AUTOTILE_CAPTURE`: PASS
- Stage 01 실제 도로 연결값 분포: 6, 3, 14, 11, 7, 13, 15, 12, 9 — 고립값 0 없음
- 기존 N/E/S/W 256×128 문턱이 새 128×64 도로 출구를 덮어 연결하며, 실제 화면에서 검은 틈이나 반대 방향 누출이 없음을 확인했다.
- 1280×720 건설 전: `tmp/v122_road_autotile_review/stage_01_day03_connector_unbuilt_1280x720.png`
- 1280×720 건설 후: `tmp/v122_road_autotile_review/stage_01_day03_connector_built_1280x720.png`
- 건설 전·후 맵 변화 범위: 중앙 지름길 약 92×97px, 나머지 지도 타일 변화 없음

`V122_DEFENDER_CONNECTOR_TEST` 종료 시 기존 ObjectDB/resource 잔존 경고가 출력됐으나 테스트 결과와 프로세스 종료 코드는 PASS/0이었다.

Related tests: `V122_VISUAL_TEXTURE_CONSISTENCY_TEST`, `V122_STAGE01_SPATIAL_VISUAL_RUNTIME_TEST`, `V122_DEFENDER_CONNECTOR_TEST`, `V122_ROAD_AUTOTILE_CAPTURE` — 모두 PASS
UI check: 실제 Stage 01 DAY 3 관리 화면 1280×720에서 지름길 건설 전·후와 도로 안내선 대비를 확인함
Unresolved issues: 나머지 이질적인 해상도·명암·그림체 그래픽 자산 통일은 다음 Phase에서 진행해야 함

## 다음 작업 순서

1. 서로 다른 해상도·명암·그림체를 가진 대표 그래픽을 목록화하고 종류별로 교체한다.
2. 변경 종류마다 가장 작은 관련 테스트와 1280×720 대표 화면 한 번만 확인한다.
3. 사용자 최종검수 요청 전에는 전체 회귀, 전체 플레이, Windows/Web 빌드를 실행하지 않는다.

## 작업 트리 상태

- 이번 도로·통로 변경은 미커밋 상태다.
- 로컬 캡처는 `tmp/v122_road_autotile_review/`에만 있으며 소스 브랜치에 커밋하지 않는다.
- 빌드, 커밋, 푸시, PR은 수행하지 않았다.
