# V1.2.2 연결 통로 공백·회흑색 구조 벽 V2 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-01
- 목표 버전: 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 작업 시작 SHA: `f9a912b8217f58b1e023dae4739cf37bc307d49b`
- 마지막 커밋 SHA: `f9a912b8217f58b1e023dae4739cf37bc307d49b` (이번 변경은 미커밋)
- 원격 푸시 여부: 미푸시
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 연결 통로의 빈 공간에 잘못 그려진 예전 문틀·횃불 자산을 제거한다.
- 방향과 모서리를 구분하는 공용 벽 구조를 다시 만든다.
- 높은 보라색 벽을 낮은 회흑색 던전 석벽으로 교체한다.
- 같은 문제가 Stage 01~04와 구조가 다른 맵에서 다시 생기지 않도록 자동 검증한다.

## 3. 완료한 작업

- `connected` 소켓에 portal marker를 그리던 런타임 경로와 로더를 비활성화했다.
- `open_placeholder`도 예전 석주 marker 없이 낮은 구조 벽만 유지하도록 바꿨다.
- 2단 회흑색 벽의 직선 2종, 방향별 모서리 4종, 끝 4종, T분기 4종을 새로 만들었다.
- 정점의 실제 접속 방향으로 자산을 선택하고, 대각선 점 접촉은 서로 다른 모서리로 분리했다.
- 기존 문틀·횃불·석주와 V1 장식형 벽을 catalog의 격리 목록으로 옮겼다.
- Stage 01~04와 분기형 사용자 맵이 같은 공용 topology와 V2 자산 세트를 사용하도록 연결했다.

## 4. 주요 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/dungeon_quarter/CorridorTopologyBuilder.gd` | 물리 벽 사슬, 방향별 정점, 대각선 점 접촉 분리 | 완료 |
| `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` | V2 방향 자산 배치, 구형 marker 로드·그리기 제거 | 완료 |
| `scripts/dungeon_quarter/WallAssetCatalog.gd` | V2 구조·팔레트·연결 정책 검증 | 완료 |
| `data/dungeon_quarter/wall_asset_catalog.json` | 14종 활성 구조 자산과 legacy 격리 목록 | 완료 |
| `data/dungeon_quarter/asset_manifest.json` | 활성 벽 세트를 `cave_v2_boundary_v2`로 전환 | 완료 |
| `assets/tiles/cave_v2/structural_walls_v2/` | 낮은 회흑색 런타임 벽 PNG 14종 | 완료 |
| `tools/prepare_v122_structural_wall_kit_v2.py` | 원본에서 방향별 런타임 자산을 만드는 결정적 변환 | 완료 |
| `tools/tests/V122StructuralWallPixelContractTest.gd` | 높이·2단·색·연결점 픽셀 계약 | 완료 |
| `tools/tests/V122WallAssetCatalogTest.gd` | catalog 역할·방향·격리 정책 | 완료 |
| `tools/tests/CorridorTopologyBuilderTest.gd` | 점 접촉 분리와 벽 사슬 회귀 | 완료 |
| `tools/tests/V122CorridorWallTopologyTest.gd` | 연결 통로 공백과 구조 벽 배치 | 완료 |
| `tools/tests/V122CorridorTopologyLayoutMatrixTest.gd` | Stage 01~04·사용자 맵 공용 적용 | 완료 |

## 5. 그래픽 자산

- GPT 내부 이미지 생성 사용 여부: 사용
- 생성 모델: GPT internal image generation
- 생성 원본 경로: `assets/source/imagegen/v122_structural_wall_kit_v2/`
- `SOURCE.md` 경로: `assets/source/imagegen/v122_structural_wall_kit_v2/SOURCE.md`
- 런타임 최종 자산 경로: `assets/tiles/cave_v2/structural_walls_v2/`
- 후처리: 녹색 chroma 제거, 긴 직선 반복부 절단, 2:1 접속선 보정, 방향별 정점 분리, `256×256` 공통 캔버스 정렬
- 실제 렌더: Stage 01~04와 custom branch map을 각각 `1280×720`로 캡처했다.

## 6. 테스트 및 검수

| 검수 | 결과 |
|---|---|
| `CorridorTopologyBuilderTest.tscn` | PASS |
| `V122WallAssetCatalogTest.tscn` | PASS |
| `V122StructuralWallPixelContractTest.tscn` | PASS, 223 assertions |
| `V122CorridorWallTopologyTest.tscn` | PASS |
| `V122CorridorTopologyLayoutMatrixTest.tscn` | PASS |
| `V122StructuralWallCapture.tscn` | PASS, Stage 01~04 + custom map 1280×720 |
| `QuarterModuleSmokeTest.tscn` | 벽 관련 신규 항목은 모두 PASS. 범위 밖 기존 `front-view generated room sprite` 메타데이터 항목 1건으로 최종 FAIL |

Related tests: 구조 생성기, 자산 catalog, 픽셀 계약, 벽 topology, Stage 01~04·사용자 맵 matrix 테스트 통과
UI check: `tmp/v122_structural_wall_review/`의 Stage 01~04 및 custom map을 1280×720 실제 렌더로 확인
Unresolved issues: 이번 벽 변경과 무관한 기존 QuarterModuleSmoke의 front-view room sprite 메타데이터 검사 1건

- 전체 회귀·전체 플레이·출시 빌드: 요청되지 않아 실행하지 않음
- Review task ID: NOT_REQUESTED
- Reviewed SHA: N/A
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 사용자가 여러 작업을 이어 온 혼합 작업 트리이므로 이번 벽 변경만 별도 커밋하지 않았다.
- Stage 02~04의 방 건물 자체에 남은 보라색은 이번 요청의 구조 벽 범위가 아니며 변경하지 않았다.
- 전체 회귀·전체 플레이 검수는 수행하지 않았다.

## 8. 다음 작업 순서

1. 사용자에게 Stage 01 실제 화면을 제시해 연결 통로 공백과 벽 높이·색을 확인받는다.
2. 추가 수정 요청이 없으면 의도 파일을 기존 작업과 구분해 명시적으로 스테이징한다.
3. 사용자가 요청할 때만 빌드·커밋·푸시를 진행한다.

## 9. 작업 트리 상태

- 브랜치: `codex/v122-ui-simplification`, 원격보다 1커밋 앞선 상태에서 미커밋 변경 존재
- 미커밋 파일: 이번 구조 벽 코드·데이터·자산·테스트·문서와 이전 시각 개편 변경이 함께 존재
- 빌드/캡처 산출물: `tmp/v122_structural_wall_review/` (커밋 대상 아님)
- 원격 푸시: 하지 않음

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] Stage 01~04·사용자 맵 공용 적용 확인
- [x] 그래픽 생성 출처와 런타임 연결 기록 완료
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 전체 회귀·전체 플레이 (요청되지 않음)
- [ ] 커밋·푸시 (요청되지 않음)
