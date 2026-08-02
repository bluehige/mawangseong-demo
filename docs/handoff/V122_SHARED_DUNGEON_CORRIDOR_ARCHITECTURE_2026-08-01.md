# V1.2.2 공용 던전 통로·연속 벽 구조

## 1. 메타데이터

- 작성일: 2026-08-01
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `codex/v122-ui-simplification` / `f9a912b8217f58b1e023dae4739cf37bc307d49b`
- 마지막 커밋 SHA: `f9a912b8217f58b1e023dae4739cf37bc307d49b` (이번 변경은 미커밋)
- 원격 푸시 여부: 하지 않음
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 승인된 던전 구조처럼 길을 따라 바닥과 벽이 이어지게 만들고, 같은 규칙을 Stage 01뿐 아니라 다른 스테이지와 사용자 배치 맵에도 재사용한다.
- 완료 조건: 맵 고유 좌표를 공용 생성기에 넣지 않고, 최종 `ModuleGraph` 결과만으로 바닥 mask·열린 출입구·닫힌 벽·코너·벽 사슬을 계산하며 Stage 01~04와 구조가 다른 시험 맵에서 동일한 자동 검사를 통과한다.
- 범위에서 제외한 사항: 전투 이동 규칙 변경, 전체 회귀·전체 플레이, Windows/Web 패키지 빌드, 새 그래픽 생성, 커밋·푸시·PR.

## 3. 완료한 작업

- 구현: 순수 계산기 `CorridorTopologyBuilder`를 추가했다. 입력 바닥·열린 변·셀 정보를 복사한 뒤 엄격한 4방향 mask, 중복 없는 물리 벽, 벽 끝점·코너·사슬, 출입구를 계산한다.
- 구현: 서로 붙어 있어도 실제 연결되지 않은 두 바닥 사이에는 벽을 정확히 한 번 남기고, 열린 변에는 벽을 만들지 않는다.
- 구현: 특수 시각 통로는 `visual_patches` 계약으로 추가한다. 패치 내부만 자동 연결하고 기존 맵과 만나는 출입구는 명시된 변만 열어 우연한 옆방 관통을 막는다.
- 구현: DAY 3 방어자 연결로를 Stage 01 하드코딩 렌더가 아니라 공용 builder에 넘기는 2×2 시각 패치로 전환했다. 적 이동 그래프는 바꾸지 않는다.
- 구현: Stage 01~04가 `cave_v2_grid` 공용 공간 프로필을 사용한다. 절차 도형 방 벽과 셀 중심을 잇는 회전 선형 도로는 끄고 bitmap 바닥·경계 벽을 사용한다.
- 구현: 벽 bitmap 폭을 모든 맵에서 같은 `0.56` 이음매 값으로 고정하고, 굽이마다 큰 장식 기둥을 반복하지 않게 했다. 끝 벽의 높이 제한은 양 끝점을 덮도록 조정했다.
- 구현: E/S 앞벽을 `FrontWallLayer/CorridorFrontWallCanvas`에서 실제로 그려 `UnitYSortLayer`보다 앞에서 유닛을 가리게 했다. N/W 뒷벽은 기존 부모 draw 순서상 유닛 뒤에 유지한다.
- 호환성: 공용 builder는 스테이지, DAY, 방 이름, 고정 좌표를 알지 않는다. 최종 `ModuleGraph` snapshot과 호출자가 넘긴 선택적 시각 패치만 사용한다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/dungeon_quarter/CorridorTopologyBuilder.gd` | 재사용 가능한 순수 통로·벽 topology 계산 | 완료 |
| `scripts/dungeon_quarter/QuarterDungeonWallCanvas.gd` | 유닛 앞에서 그리는 실제 앞벽 CanvasItem | 완료 |
| `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` | 공용 builder·프로필·DAY 3 patch·앞벽 층 연결 | 완료 |
| `data/dungeon_quarter/asset_manifest.json` | Stage 01~04 공용 `cave_v2_grid` 프로필과 벽 표시값 | 완료 |
| `tools/tests/CorridorTopologyBuilderTest.gd/.tscn` | 16 mask·닫힌 공유 변·코너·구멍·patch 단위 검사 | 완료 |
| `tools/tests/V122CorridorTopologyLayoutMatrixTest.gd/.tscn` | Stage 01~04·구조가 다른 custom 맵 공통 invariant 검사 | 완료 |
| `tools/tests/V122CorridorWallTopologyTest.gd/.tscn` | 실제 Stage 01 벽 중복·열림·bitmap 끝점 피복 검사 | 완료 |
| `tools/tests/V122Stage01SpatialVisualRuntimeTest.gd` | 공용 구조와 Stage 01 런타임 계약 검사 | 완료 |
| `tools/tests/core_verification_suite.json` | 신규 두 테스트를 Quick/Full 목록에 등록 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 이번 공용 구조 작업에서는 사용하지 않음
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 신규 문서 없음
- 런타임 최종 자산 경로: 기존 `assets/tiles/cave_v2/wall_edges/`, Stage 01 corridor atlas와 문턱 자산을 재사용
- 프롬프트/후처리/크롭/알파 처리 요약: 신규 처리 없음
- 게임 연결 및 실제 렌더 확인 결과: Stage 01~04가 같은 벽 생성 규칙과 같은 bitmap 벽 프로필을 사용하며, 연결된 출입구는 열리고 외곽벽은 이어진다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `CorridorTopologyBuilderTest.tscn` | PASS | 16 mask·공유 벽·코너·고리·visual patch |
| 2 | `V122CorridorWallTopologyTest.tscn` | PASS | 실제 Stage 01 벽 1회 생성·열린 변 0벽·끝점 피복 |
| 3 | `V122Stage01SpatialVisualRuntimeTest.tscn` | PASS | Stage 01 공용 프로필·DAY 3 연결로 |
| 4 | `V122CorridorTopologyLayoutMatrixTest.tscn` | PASS | Stage 01~04와 `role_driven_combat_layout_test_01` |
| 5 | OpenGL 1280×720 실제 렌더 | PASS | `tmp/v122_road_autotile_review/stage_01_day03_connector_built_1280x720.png` |
| 6 | OpenGL Stage 01~04 비교 렌더 | PASS | `tmp/castle_stage_review/stage_01_cave_1920x1080.png` ~ `stage_04_citadel_1920x1080.png` |
| 7 | 전체 회귀·전체 플레이 | NOT_REQUESTED | 사용자 요청 범위 밖 |

Related tests: 공용 builder 단위 검사, Stage 01 실제 벽 검사, Stage 01 런타임 검사, Stage 01~04·custom 배치 행렬 검사가 모두 통과함
UI check: OpenGL 1280×720 DAY 3 화면과 Stage 01~04 비교 화면에서 통로 외곽벽·열린 출입구·앞벽 폐색을 확인함
Unresolved issues: 기능상 미해결 항목은 없으며 최종 미술 취향 판정은 사용자 확인 대상으로 남음

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: N/A
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: `FrontWallLayer`는 공용 bitmap 벽만 옮겼다. 바닥 픽셀을 포함할 수 있는 문턱·socket 자산은 유닛 전체를 덮지 않도록 기존 층에 유지했다.
- 밸런스 관찰 항목: 없음. 전투 이동·건설 비용·저장 데이터는 변경하지 않았다.
- 임시 구현 또는 대체 자산: 없음. 기존 출처 기록이 있는 cave_v2 자산을 재사용했다.
- 외부 환경/도구 제약: 전체 회귀와 패키지 빌드는 요청되지 않아 실행하지 않았다.

## 8. 다음 작업 순서

1. 사용자가 첨부된 Stage 01 실제 화면과 Stage 02~04 비교 화면의 벽 높이·밝기·밀도를 판정한다.
2. 시각 피드백이 있으면 `spatial_asset_profiles.cave_v2_grid.wall_render` 한 곳만 조정하고 동일 행렬 테스트와 1280×720 화면을 다시 확인한다.
3. 사용자 최종검수 요청이 있을 때만 전체 검증과 Windows 후보 빌드를 진행한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: `codex/v122-ui-simplification`, 원격보다 1커밋 앞섬, 이번 통로 구조 작업 미커밋
- 미커밋 파일: renderer, 공용 builder·wall canvas, manifest, 관련 테스트·도구·문서와 앞선 그래픽 통일 작업 파일
- 의도하지 않은 기존 변경: `assets/sprites/enemies/update4/region/*.png.import`는 다른 작업 소유로 판단해 수정·되돌림하지 않음
- 스태시 또는 별도 작업공간: 사용하지 않음
- 빌드/캡처 산출물 위치: 기존 표준 폴더 `tmp/v122_road_autotile_review/`, `tmp/castle_stage_review/` (커밋 대상 아님)

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 Stage 01~04·custom 배치 확인
- [x] 그래픽 생성 출처 확인 (신규 생성 없음)
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 전체 회귀·전체 플레이 (요청되지 않음)
- [ ] 의도한 파일만 커밋 (요청되지 않음)
- [ ] 원격 푸시 및 PR/태그 (요청되지 않음)
