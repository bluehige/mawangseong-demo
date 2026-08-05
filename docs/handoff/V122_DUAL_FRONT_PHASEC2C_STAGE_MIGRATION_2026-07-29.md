# v1.2.2 이중 전선 Phase C-2c 단계 확장·배치 이관 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-29
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 아니오
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 이중 전선 후보의 Stage 2~4 확장 충돌을 제거하고 기존 시설·몬스터 배치를 후보의 시설 슬롯과 방어구역에 결정적으로 이관한다.
- 완료 조건:
  - Stage 1~4에서 모듈 겹침·socket·필수 경로·경계 오류가 없어야 한다.
  - 두 입구·두 주 통로·왕좌의 고정 구조와 Stage 1 전선 경로를 유지해야 한다.
  - 기존 확장 room ID를 보존하면서 교체식 시설 슬롯과 방어구역을 결정적으로 부여해야 한다.
  - 관리 확정 저장과 retry가 이관된 방·시설 슬롯·방어구역을 보존해야 한다.
- 범위에서 제외한 사항: 후보의 제품 기본값 활성화, 기존 캠페인의 자동 레이아웃 전환 정책 확정, 전체 QA·실플레이·밸런스 확정, 그래픽 개편, 빌드·배포.

## 3. 완료한 작업

- 후보 전용 단계 확장:
  - 공용 Stage 확장 데이터는 바꾸지 않고 후보 레이아웃의 `castle_stage_expansion_overrides`에서만 좌표·연결·필수 경로·방 그리드·시설 슬롯 계약을 교체한다.
  - Stage 2는 심장실과 감시 초소를 A/B 전선의 별도 측면 가지에 배치했다.
  - Stage 3은 수호핵과 `slot_02`, Stage 4는 정예 병영과 `slot_03`을 기존 가지의 후속 확장으로 배치했다.
  - Stage 3~4의 후보 전용 세로 경계를 28×33으로 확장해 기존 Stage 확장 모듈과 후보 주 통로의 좌표 중복을 제거했다.
- 고정 구조 보존:
  - Stage 1의 `lane_a`·`lane_b` 경로는 Stage 2~4에서도 좌표와 순서를 바꾸지 않는다.
  - 두 입구·두 주 통로·왕좌는 고정이고 추가 시설은 교체 가능 시설로 유지한다.
  - 공용 레이아웃과 기존 제품 Stage 확장 좌표는 변경하지 않았다.
- 저장 배치 이관:
  - `watch_post_01` → `facility_b_watch` / `zone_b_rear`
  - `ward_core_01` → `facility_b_ward` / `zone_b_front`
  - `slot_02` → `facility_b_stage3` / `zone_b_rear`
  - `elite_garrison_01` → `facility_b_elite` / `zone_b_front`
  - `slot_03` → `facility_b_stage4` / `zone_b_front`
  - 기존 room ID를 `legacy_instance_ids_preserved`로 유지해 시설·몬스터 배치의 room 기준을 잃지 않으며, 정규화 뒤 시설 슬롯·방어구역 ID를 함께 저장한다.
  - 일반 저장과 retry가 정규화된 room·slot·zone을 같은 값으로 복원한다.
- 런타임 재생성:
  - `DataRegistry`가 레이아웃별 Stage override를 해석한다.
  - `GameRoot`가 현재 레이아웃에 맞는 확장 room·module·facility contract를 합성하고 저장 복원 전에 후보 레이아웃 ID를 확정한다.
  - 저장 복원 가능성 검사는 현재 실행 상태가 아니라 저장 파일의 Update 3 상태를 기준으로 심장실 전용 module·path·room-grid cell을 포함한다.
  - `ModuleGraph`는 레이아웃별 `max_grid_size`와 `active_rect`를 사용하되 기존 레이아웃에는 기존 등급 규칙을 그대로 적용한다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/dungeon_quarter/layouts/stage01_dual_front_01.json` | 후보에서 제품 기본값으로 승격된 Stage 2~4 room·branch corridor·facility slot·grid override | 완료 |
| `scripts/core/DataRegistry.gd` | 레이아웃별 Stage 확장 override 해석 | 완료 |
| `scripts/dungeon_quarter/ModuleGraph.gd` | 후보 전용 확장 경계 적용 | 완료 |
| `scripts/game/GameRoot.gd` | 후보 단계 합성·room 동기화·저장 복원 순서와 검증 | 완료 |
| `tools/tests/V122DualFrontStageMigrationTest.gd` | Stage 1~4 구조·배치·저장·retry 이관 계약 검증 | 완료 |
| `tools/tests/V122DualFrontStageMigrationTest.tscn` | 전용 headless 테스트 scene | 완료 |
| `docs/handoff/V122_DUAL_FRONT_PHASEC2C_STAGE_MIGRATION_2026-07-29.md` | 세션 인계 | 완료 |
| `docs/handoff/CURRENT.md` | 단일 진입점 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 해당 없음
- 프롬프트/후처리/크롭/알파 처리 요약: 해당 없음
- 게임 연결 및 실제 렌더 확인 결과: 구조·데이터·저장 계약만 수정했다. 실제 렌더와 플레이 감각은 이번 범위에서 검수하지 않았다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V122DualFrontStageMigrationTest.tscn` | PASS | `.godot/V122DualFrontStageMigrationTest-phasec2c-final2.log` |
| 2 | `V122SpatialPlacementTest.tscn` | PASS | `.godot/V122SpatialPlacementTest-phasec2c.log` |
| 3 | `V122SaveZonePlacementCompatibilityTest.tscn` | PASS | `.godot/V122SaveZonePlacementCompatibilityTest-phasec2c.log` |
| 4 | `V122DualFrontLayoutContractTest.tscn` | PASS | `.godot/V122DualFrontLayoutContractTest-phasec2c.log` |
| 5 | `V122EnemyLaneRoutingTest.tscn` | PASS | `.godot/V122EnemyLaneRoutingTest-phasec2c.log` |
| 6 | `V122DefenderConnectorTest.tscn` | PASS | `.godot/V122DefenderConnectorTest-phasec2c-final.log` |
| 7 | `V122DualFrontDay01To05WaveTest.tscn` | PASS | `.godot/V122DualFrontDay01To05WaveTest-phasec2c.log` |
| 8 | `V122FacilityZoneCombatConsumerTest.tscn` | PASS | `.godot/V122FacilityZoneCombatConsumerTest-phasec2c.log` |
| 9 | `V122ManagementUIContractTest.tscn` | PASS | `.godot/V122ManagementUIContractTest-phasec2c.log` |
| 10 | `V122CombatRuleAdapterTest.tscn` | PASS | `.godot/V122CombatRuleAdapterTest-phasec2c.log` |
| 11 | `V122SaveProgressionTest.tscn` | PASS | `.godot/V122SaveProgressionTest-phasec2c-escalated.log` |
| 12 | `SaveV4MigrationTest.tscn` | PASS, 42 assertions | `.godot/SaveV4MigrationTest-phasec2c-escalated.log` |
| 13 | `SaveV5MigrationTest.tscn` | PASS, 37 assertions | `.godot/SaveV5MigrationTest-phasec2c-escalated.log` |
| 14 | `V122Day01To05ParityTest.tscn` | PASS | `.godot/V122Day01To05ParityTest-phasec2c.log` |
| 15 | 직접 영향 파일 `git diff --check` | PASS | 작업 종료 시 확인 |
| 16 | 전체 회귀 테스트 | NOT_REQUESTED | 사용자 지시에 따라 보류 |
| 17 | 시각/실플레이 검수 | NOT_REQUESTED | 사용자 최종 테스트 전까지 보류 |

Windows root certificate store 읽기 경고는 기존 headless 환경 경고이며 테스트의 종료 코드와 단언 결과에는 영향을 주지 않았다. 일부 fixture는 종료 시 ObjectDB/resource 정리 경고가 있으나 단언과 종료 코드는 PASS다. Save V4/V5의 최초 sandbox 실행에서 `user://` 쓰기가 차단되어 파일 기반 단언이 실패했으며, 사용자 저장 경로 쓰기가 허용된 동일 테스트 재실행에서는 전부 통과했다.

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | NOT_REQUESTED | N/A | 미커밋 작업 트리 | 전체 검수 미요청 | 직접 영향 계약 테스트만 수행 | 위 테스트 로그 | TARGETED_PASS |

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. 전체 회귀·실플레이는 이번 작업의 필수 범위가 아니다.
- PASS 이후 기능·데이터·자산 변경 여부: 저장 파일 Update 3 상태 기준 room-grid 필터 보강 뒤 전용 Stage 이관 테스트와 Day 1~5 parity를 다시 PASS했다. 이후 핸드오프 문서와 `CURRENT.md`만 변경했다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 후보 레이아웃은 아직 제품 기본값이 아니므로 일반 새 게임은 기존 기본 레이아웃을 사용한다.
- 후보를 기본값으로 바꿀 때 새 게임만 즉시 적용할지, 기존 캠페인도 안전 체크포인트에서 자동 전환할지 제품 정책을 먼저 고정해야 한다.
- Stage 3~4 후보는 세로 28×33으로 확장됐다. 실제 화면 구도·카메라·가독성·전투 동선 체감은 검수하지 않았다.
- 추가 시설 가지는 고정 주 통로를 보존하기 위해 B 전선 측면에 배치했다. 실제 밸런스와 시설 방어 압력은 사용자 플레이 피드백으로 확정해야 한다.
- 전체 플레이·렌더·빌드는 실행하지 않았다.

## 8. 다음 작업 순서

1. 후보 기본값 활성화 정책을 고정한다. 최소 결정 항목은 새 게임 적용 시점, 기존 캠페인 전환 시점, 전환 실패 시 기존 레이아웃 유지 규칙이다.
2. 정책 확정 뒤에만 `stage01_dual_front_candidate_01`의 제품 기본값 활성화와 기존 캠페인 전환을 구현한다.
3. 기본값 전환·구저장·retry·Day 1~5·전선·시설 계약 집중 테스트를 실행한다.
4. 전체 QA·전체 플레이 검수는 사용자가 요청할 때까지 보류한다.
5. 구조가 제품 기본값으로 고정된 뒤 Stage 01 셀 정합형 그래픽 제작과 캐릭터·배경 융화를 재개한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: `codex/v122-ui-simplification`에 미커밋 변경이 존재한다.
- 미커밋 파일: 이번 Phase C-2c 구현·테스트·핸드오프 외에 Phase A/B/C-1/C-2a/C-2b 및 이전 UI·설정 변경이 함께 남아 있다.
- 의도하지 않은 기존 변경: 다수 `.import`와 이전 UI·오디오·설정 변경을 보존했으며 정리하거나 되돌리지 않았다.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: 없음. 전용 테스트 로그만 `.godot/`에 있다.

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
