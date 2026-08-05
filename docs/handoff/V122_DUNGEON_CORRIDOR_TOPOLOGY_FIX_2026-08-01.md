# V1.2.2 Stage 01 던전 통로 구조·연속 석벽 수정

## 1. 메타데이터

- 작성일: 2026-08-01
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `codex/v122-ui-simplification` / `f9a912b8217f58b1e023dae4739cf37bc307d49b`
- 마지막 커밋 SHA: `f9a912b8217f58b1e023dae4739cf37bc307d49b` (이번 변경은 미커밋)
- 원격 푸시 여부: 하지 않음
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 길 위에 벽 조각이 흩어진 기존 화면을 폐기하고, 바닥 양옆에 연속된 벽과 열린 출입구가 있는 실제 던전 통로로 다시 구현한다.
- 완료 조건: Stage 01 전체 통로가 같은 바닥·벽 구조를 사용하고, DAY 3 건설 연결부가 실제 2×2 통로로 보이며, 관련 구조 검사와 1280×720 실제 화면 확인을 통과한다.
- 범위에서 제외한 사항: 전투 이동 규칙 변경, 다른 스테이지 미술 교체, 전체 회귀·전체 플레이, Windows/Web 패키지 빌드.

## 3. 원인과 완료한 작업

- 원인: 첫 구현은 16방향 바닥만 연결 정보에 맞췄고, 벽은 각 칸에 작은 bitmap을 약 30~34% 크기와 56% 투명도로 따로 그렸다. 그래서 벽이 통로 외곽이 아니라 길 위의 떨어진 장식처럼 보였다.
- 원인: Stage 01 방 벽은 코드로 만든 도형 벽과 bitmap 벽이 동시에 그려져 높이·재질·위치 기준이 충돌했다.
- 원인: 일반 연결부와 DAY 3 연결로는 두 점 사이에 긴 바닥 이미지를 회전·확대했으므로, 바닥과 벽이 같은 연결 구조를 공유하지 못했다.
- 구현: Stage 01 렌더 전용 시각 격자를 추가하고 바닥 mask와 벽이 동일한 열린 가장자리 정보를 사용하게 했다.
- 구현: 열린 가장자리에는 벽을 만들지 않고, 닫힌 외곽에는 기존 Stage 01 석벽 bitmap을 크게 겹쳐 배치해 벽이 끊기지 않게 했다.
- 구현: Stage 01의 코드 도형 방 벽과 회전형 연결 strip을 끄고, bitmap 석벽 한 체계로 통일했다.
- 구현: DAY 3 연결로 건설 후 `(18,12)`, `(19,12)`, `(18,13)`, `(19,13)` 네 칸을 시각 격자에 추가했다. 내부와 위·아래 출입구는 열고 좌우에는 벽을 두었다.
- 호환성: 이 네 칸은 화면용 `visual_only`이며 실제 적 이동 그래프에는 넣지 않았다. 방어자 전용 연결 규칙, 건설 비용, 저장 상태는 기존 로직을 유지한다.
- 검수 도구: 캡처가 PNG 저장만 성공해도 PASS하던 문제를 고쳐, 열린 길 위 벽 존재와 DAY 3 네 칸의 건설 전·후 상태를 실제 구조로 검사한 뒤에만 화면을 저장한다.

## 4. 주요 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` | 시각 격자, 열린 가장자리, 연속 석벽, DAY 3 2×2 통로 | 완료 |
| `data/dungeon_quarter/asset_manifest.json` | 폐기한 회전형 bridge 자산 연결 제거 | 완료 |
| `tools/tests/V122CorridorWallTopologyTest.gd` | 실제 레이아웃의 바닥·벽·출입구·끝점 피복 검사 | 완료 |
| `tools/tests/V122Stage01SpatialVisualRuntimeTest.gd` | 회전형 bridge 재도입 금지와 2×2 격자 계약 검사 | 완료 |
| `tools/V122RoadAutotileCapture.gd` | 건설 전·후 구조 검증 및 전체·지도·상세 캡처 | 완료 |
| `docs/design/v122/V122_ROAD_AND_PASSAGE_RESOURCE_IMPLEMENTATION_BRIEF_2026-08-01.md` | 최종 구현 기준으로 브리핑 정정 | 완료 |

## 5. 그래픽 자산 및 폐기 내역

- GPT 내부 이미지 생성 사용 여부: 이번 구조 수정에서는 새 이미지를 생성하지 않았다.
- 생성 모델: 해당 없음. 기존 자산의 기록은 각 `SOURCE.md`에 유지한다.
- 재사용한 런타임 자산: `assets/tiles/cave_v2/wall_edges/`의 기존 Stage 01 석벽 bitmap, `assets/tiles/stage_01/spatial_road_autotile_v2/corridor_road_autotile_stage01_atlas.png`, `assets/tiles/stage_01/spatial_passage_v1/defender_connector_junction_stage01.png`.
- 게임 연결 및 실제 렌더 확인 결과: 기존 석벽 bitmap의 표시 크기와 불투명도를 조정해 방과 통로 외곽이 끊김 없이 연결됨을 확인했다.
- 삭제: `connection_bridge_v1`의 원본 PNG 2개와 `SOURCE.md`, 런타임 PNG와 `.import`, `tools/prepare_v122_connection_bridge.py`, 빈 원본 폴더를 제거했다.
- 복구 가능성: 삭제 대상은 Git에 추적되지 않은 잘못된 첫 시안이어서 Git 이력으로 복구할 수 없다. 필요하면 새로 생성해야 한다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V122Stage01SpatialVisualRuntimeTest.tscn` | PASS | bridge 제거·atlas·시각 격자 계약 |
| 2 | `V122VisualTextureConsistencyTest.tscn` | PASS | Stage 01 월드 필터·밉맵 일관성 |
| 3 | `V122CorridorWallTopologyTest.tscn` | PASS | 열린 가장자리 벽 0, 닫힌 외곽 벽 1, 벽 양 끝점 피복, DAY 3 2×2 mask |
| 4 | `V122DefenderConnectorTest.tscn` | PASS | 방어자 전용 연결로의 전투·저장 계약 |
| 5 | `V122RoadAutotileCapture.tscn` | PASS | Vulkan/RTX 3060 Ti, 실제 1280×720 DAY 3 건설 전·후 |
| 6 | 전체 회귀·전체 플레이 | NOT_REQUESTED | 사용자 요청 범위 밖 |

- 1280×720 전체 화면: `tmp/v122_road_autotile_review/stage_01_day03_connector_built_1280x720.png`
- 지도 중심 화면: `tmp/v122_road_autotile_review/stage_01_day03_connector_built_map_crop.png`
- DAY 3 연결부 상세: `tmp/v122_road_autotile_review/stage_01_day03_connector_built_detail.png`
- 기존 테스트 종료 시 ObjectDB/resource 잔존 경고가 출력되는 경우가 있으나, 네 관련 테스트와 캡처의 종료 코드는 모두 0이다.

Related tests: Stage 01 공간 자산, 텍스처 일관성, 통로 벽 구조, 방어자 연결로 테스트와 실제 캡처가 모두 통과함
UI check: 실제 Vulkan 1280×720 DAY 3 관리 화면에서 연속 외곽 석벽, 열린 통로 내부, 건설 전·후 연결부를 확인함
Unresolved issues: 기능상 미해결 항목은 없으며 현재 화면에 대한 사용자 최종 미술 판정이 남아 있음

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: N/A
- Review range: N/A
- Remaining P1/P2: 0
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 렌더 전용 시각 격자와 실제 이동 그래프를 의도적으로 분리했다. 테스트가 DAY 3 네 칸이 적 이동 그래프에 들어가지 않는 것을 고정한다.
- 임시 구현 또는 대체 자산: 없음.
- 외부 환경/도구 제약: 사용자 최종 미술 판정 전이며, 다른 스테이지에는 아직 같은 벽 구조를 적용하지 않았다.

## 8. 다음 작업 순서

1. 사용자가 현재 1280×720 화면에서 통로의 폭·벽 높이·명암을 판정한다.
2. 지적이 있으면 구조는 유지하고 해당 시각 속성만 작은 범위로 조정한 뒤 같은 구조 테스트와 대표 화면을 다시 확인한다.
3. 사용자가 빌드 또는 커밋을 요청하면 저장소 규칙에 따라 태그 기준 빌드와 의도한 파일만 명시적 스테이징한다.

## 9. 작업 트리 상태

- `git status --short --branch`: `codex/v122-ui-simplification`, 원격보다 1커밋 앞섬, 이번 그래픽 통일 작업은 미커밋.
- 미커밋 파일: renderer, manifest, 도로·접속석 원본/런타임, 텍스처 import, 관련 도구·테스트·문서.
- 의도하지 않은 기존 변경: `assets/sprites/enemies/update4/region/*.png.import`는 기존 작업으로 판단해 건드리지 않았다.
- 스태시 또는 별도 작업공간: 사용하지 않음.
- 빌드/캡처 산출물 위치: `tmp/v122_road_autotile_review/`이며 커밋 대상이 아니다.
- 커밋·푸시·PR: 수행하지 않음.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 실제 1280×720 화면 확인
- [x] 잘못된 미사용 bridge 자산·도구 제거
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 전체 회귀·전체 플레이 (요청 없음)
- [ ] 의도한 파일만 커밋 (요청 없음)
- [ ] 원격 푸시 및 PR/태그 (요청 없음)
