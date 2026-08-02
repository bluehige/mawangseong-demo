# V1.2.2 구조 벽 자산 분류·연결 시스템 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-01
- 목표 버전: 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: 현재 작업 브랜치 `f9a912b8217f58b1e023dae4739cf37bc307d49b`
- 마지막 커밋 SHA: `f9a912b8217f58b1e023dae4739cf37bc307d49b` (이번 변경은 아직 미커밋)
- 원격 푸시 여부: 미푸시, 현재 브랜치는 원격보다 1커밋 앞섬
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 기존 장식용 독립 오브젝트를 방향과 역할 구분 없이 벽으로 재사용하던 문제를 바로잡고, 통로 외곽을 실제로 이어지는 구조 벽 자산만 따라가게 만든다.
- 완료 조건: 구조 벽과 장식물을 데이터에서 분리하고, 벽 본체·모서리·끝·분기 자산을 새로 마련하며, 닫힌 변은 구조 자산만 사용하고 Stage 01~04 및 구조가 다른 맵에서도 같은 규칙으로 렌더한다.
- 범위에서 제외한 사항: 전체 그래픽 교체, 전투 전체 회귀, 출시 빌드, 기존 장식 자산 파일의 물리적 삭제.

## 3. 완료한 작업

- 구현: 기존 `wall_edges` PNG 32개를 픽셀 형태와 용도로 다시 감사했다. 구조 본체로 쓸 수 있는 것은 0개였고, 문틀 4개와 건설 소켓 표지 4개만 비구조 marker로 분류했으며 나머지 독립 장식물 20개와 문양 벽판 4개는 구조 사용 금지로 격리했다.
- 구현: `wall_asset_catalog.json`과 검증기를 추가해 구조 벽 슬롯에는 새 `structural_boundary` 자산 5개만 들어갈 수 있게 했다. 문틀·건설 소켓 marker 8개도 이 catalog 한 곳에서만 소유하며 모두 `structural_allowed=false`다.
- 구현: 활성 `tile_variant_manifest.json`에서는 `wall_edges`, `walls`, `wall_mask`, `doors` 목록을 제거하고 구조 catalog 경로만 남겼다. `asset_manifest.json`의 중복 `socket_caps`도 제거했다. 과거 장식물 24개, 임시 straight 2개, 반복 wall mask 16개는 `legacy_quarantined_wall_resources`에만 남아 런타임 구조 벽으로 로드되지 않는다.
- 구현: 닫힌 socket의 옛 문양 벽판 fallback과 절차식 점 marker를 제거했다. `open_placeholder`는 아직 뚫리지 않은 구조 벽을 유지하고 건설 표지만 정확히 한 번 별도 겹침 표시한다.
- 구현: 닫힌 격자 변은 실제 연결점의 거리와 중점으로 벽 본체를 맞추고, 정점 연결 형태에 따라 `corner`, `end`, `junction`을 따로 배치한다.
- 구현: N/W는 뒷벽, E/S는 앞벽으로 분리하고, `connected` 열린 변은 닫힌 벽으로 메우지 않는다. E/S 문틀·소켓 표지는 앞벽 전용 Canvas에서 구조 벽·정점 뒤에 그려 가려지거나 중복되지 않게 했다.
- 스토리 및 데이터: 스토리·밸런스 데이터 변경 없음. Stage 01~04는 같은 `cave_v2_boundary_v1` 구조 벽 세트를 참조한다.
- UI/UX: 기존 악마상·횃불·종단 기둥이 직선과 모서리에 무작위로 반복되던 화면을 중립 현무암 벽 본체와 역할별 접합 블록으로 교체했다.
- 저장 및 호환성: 저장 데이터 형식 변경 없음. 렌더링용 자산 manifest만 확장했다.

## 4. 주요 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/dungeon_quarter/wall_asset_catalog.json` | 구조·장식 역할, 방향, 연결점, 별칭, 격리 목록 등록 | 완료 |
| `data/dungeon_quarter/tile_variant_manifest.json` | 활성 벽 목록을 제거하고 catalog 경로와 과거 자산 quarantine만 유지 | 완료 |
| `data/dungeon_quarter/asset_manifest.json` | 중복 marker 목록을 제거하고 구조 벽 catalog 전용으로 고정 | 완료 |
| `scripts/dungeon_quarter/WallAssetCatalog.gd` | 장식 자산 혼입과 잘못된 방향·역할·anchor를 거부 | 완료 |
| `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` | 닫힌 변에 새 구조 벽만 배치하고 정점 종류를 분리 | 완료 |
| `assets/tiles/cave_v2/structural_walls_v1/` | 벽 본체 2축과 corner/end/junction 런타임 자산 | 완료 |
| `assets/source/imagegen/v122_structural_wall_kit_v1/` | 생성 원본, 알파 처리본, 출처 문서 | 완료 |
| `docs/design/v122/V122_STRUCTURAL_WALL_RESOURCE_CONTRACT_2026-08-01.md` | 벽 자산 접합 규격과 금지 역할 고정 | 완료 |
| `tools/tests/V122WallAssetCatalogTest.*` | 장식 자산을 구조 슬롯에 넣는 회귀를 차단 | 완료 |
| `tools/tests/V122StructuralWallPixelContractTest.*` | PNG 실제 알파·절단면·기울기·역할 차이를 검사 | 완료 |
| `tools/tests/V122CorridorWallTopologyTest.*` | 통로 외곽 벽의 실제 연결과 정점 배치를 검사 | 완료 |
| `tools/V122StructuralWallCapture.*` | Stage 01~04와 분기형 맵 1280×720 비교 캡처 | 완료 |

## 5. 그래픽 자산

- GPT 내부 이미지 생성 사용 여부: 사용
- 생성 모델: GPT internal image generation
- 생성 원본 경로: `assets/source/imagegen/v122_structural_wall_kit_v1/`
- `SOURCE.md` 경로: `assets/source/imagegen/v122_structural_wall_kit_v1/SOURCE.md`
- 런타임 최종 자산 경로: `assets/tiles/cave_v2/structural_walls_v1/`
- 프롬프트/후처리/크롭/알파 처리 요약: 장식 없는 긴 현무암 연속벽을 생성한 뒤 종단면에서 떨어진 중앙만 잘라 열린 양끝을 만들었다. 녹색 배경 제거, 2:1 아이소메트릭 기울기 보정, 수평 반전, 256×256 고정 캔버스 정렬만 수행했다.
- 게임 연결 및 실제 렌더 확인 결과: 벽 본체는 통로와 방 외곽의 닫힌 변을 따라 이어지며, 기존 악마상·횃불·문양 벽판은 구조 벽으로 반복되지 않는다. Stage 01~04와 별도 분기형 맵에서 같은 조립 규칙을 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V122WallAssetCatalogTest.tscn` | PASS | `tmp/V122WallAssetCatalogTest.final_wall_audit.log` |
| 2 | `CorridorTopologyBuilderTest.tscn` | PASS | `tmp/CorridorTopologyBuilderTest.final_wall_audit.log` |
| 3 | `V122StructuralWallPixelContractTest.tscn` | PASS, 52 assertions | `tmp/V122StructuralWallPixelContractTest.final_wall_audit.log` |
| 4 | `V122CorridorWallTopologyTest.tscn` | PASS | `tmp/V122CorridorWallTopologyTest.final_wall_audit.log` |
| 5 | `V122CorridorTopologyLayoutMatrixTest.tscn` | PASS, E/S 표지의 실제 앞벽 Canvas 기록 포함 | `tmp/V122CorridorTopologyLayoutMatrixTest.final_wall_audit.log` |
| 6 | `V122Stage01SpatialVisualRuntimeTest.tscn` | PASS | `tmp/V122Stage01SpatialVisualRuntimeTest.final_wall_audit.log` |
| 7 | `V122StructuralWallCapture.tscn`, 1280×720 실제 GPU 렌더 | PASS | `tmp/v122_structural_wall_multimap_capture.final_wall_audit.log`, `tmp/v122_structural_wall_review/` |
| 8 | `QuarterModuleSmokeTest.tscn` | 벽 관련 항목 PASS, 범위 밖 기존 room sprite 격리 항목 1건 FAIL | `tmp/QuarterModuleSmokeTest.final_wall_audit.log` |
| 9 | 구조 자산·renderer 범위 재감사 | 남은 P1/P2 0건 | `wall_asset_inventory`, `wall_renderer_mapping` 범위 감사 |
| 10 | 전체 회귀 테스트 | NOT_REQUESTED | 실행하지 않음 |

Related tests: 구조 자산 catalog 단일 소유권, 활성 manifest 격리, 실제 PNG 픽셀 접합, placeholder 구조벽 유지, 앞쪽 표지 Canvas 순서, 통로 벽 위상, Stage 01~04·분기형 맵 행렬, Stage 01 런타임 테스트가 모두 통과했다.
UI check: 최종 코드로 Stage 01~04와 별도 분기형 맵을 각각 1280×720에서 다시 실제 렌더하여 통로 외곽의 연속 벽, 꺾임, 끝, 분기 및 앞벽 합성을 확인했다.
Unresolved issues: 구조 벽 범위 재감사 결과 남은 P1/P2는 0건이다. 전체 스모크의 room sprite 격리 실패 1건은 구조 벽과 무관한 기존 항목이며 이번 범위에서 수정하지 않았다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: N/A
- Review range: N/A
- Remaining P1/P2: 구조 벽 범위 0건
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 이후 테마별 벽 키트를 추가할 때 같은 연결점·anchor 계약을 지키지 않으면 검증기가 거부한다.
- 시각 관찰 항목: 현재 V1은 구조가 읽히도록 장식을 의도적으로 배제했다. 장식은 구조 벽 조립 뒤 별도 패스로 제한 배치해야 한다.
- 임시 구현 또는 대체 자산: 없음. 기존 `wall_edges` 32개 중 8개는 catalog에서 비구조 문·소켓 표지로만 사용하고, 24개는 감사 기록으로만 격리한다. 닫힌 구조 벽에는 어느 것도 사용하지 않는다.
- 외부 환경/도구 제약: 전체 회귀·출시 빌드는 요청받지 않아 실행하지 않았다.

## 8. 다음 작업 순서

1. 사용자가 Stage 01과 분기형 맵 캡처에서 벽 높이·밝기·밀도를 판정한다.
2. 조정이 필요하면 구조 자산 5개 또는 공용 wall profile 한 곳만 수정하고 같은 6개 대상 테스트와 멀티맵 캡처를 재실행한다.
3. 승인 뒤에만 장식 패스를 별도로 설계하며, 장식 자산은 구조 벽 슬롯과 계속 분리한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: `codex/v122-ui-simplification`, 원격보다 1커밋 앞섬, 앞선 통로·그래픽 작업을 포함한 다수 미커밋 변경이 존재한다.
- 미커밋 파일: 위 구조 벽 관련 코드·데이터·자산·테스트·문서와 앞선 그래픽 통일 작업 파일.
- 의도하지 않은 기존 변경: 다수 `.import`, Stage 01 공간 자산, 이전 핸드오프 변경은 사용자 요청에 따라 이어서 진행한 기존 작업이며 되돌리지 않았다.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: `tmp/v122_structural_wall_review/`, 저장소에 커밋하지 않음.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 요청받은 경우에만 전체 회귀·검수 에이전트 완료
- [x] 검수 대상 최종 SHA와 작업 ID 기록
- [x] 그래픽 생성 출처와 런타임 연결 기록 완료
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR/태그 상태 기록
