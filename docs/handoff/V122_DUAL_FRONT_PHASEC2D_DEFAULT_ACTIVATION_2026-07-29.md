# v1.2.2 이중 전선 Phase C-2d 제품 기본값 활성화 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-29
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 아니요
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: Phase A~C-2c에서 완성한 이중 전선 구조를 새 게임의 제품 기본 레이아웃으로 활성화하고 기존 캠페인을 안전하게 전환한다.
- 완료 조건:
  - 새 게임은 즉시 이중 전선 제품 기본값을 사용한다.
  - 구형 제품 기본 레이아웃을 사용한 안전 체크포인트 저장만 이중 전선으로 전환한다.
  - 사용자 제작·선택 레이아웃은 자동 전환하지 않는다.
  - 전환 후보가 구조 검증에 실패하면 원본 저장의 유효한 구형 레이아웃을 유지한다.
  - 입력 저장 payload는 검사 과정에서 변경하지 않는다.
- 범위에서 제외한 사항: 전체 QA, 실제 플레이·시각·밸런스 검수, 그래픽 개편, 빌드·배포, 커밋·푸시.

## 3. 확정한 제품 정책

- 제품 기본값 파일은 `data/dungeon_quarter/layouts/stage01_dual_front_01.json`이다.
- 런타임 레이아웃 ID는 이전 단계와 저장·웨이브 계약 호환을 위해 `stage01_dual_front_candidate_01`을 유지한다. 파일 위치와 활성 상태만 제품용으로 승격했다.
- 신규 게임:
  - `DataRegistry.quarter_default_layout_id`가 이중 전선 ID를 가리킨다.
  - `GameRoot` 초기화와 새 게임 초기화는 이 제품 기본값을 사용한다.
- 기존 캠페인:
  - `CampaignSaveStore`가 허용하는 안전 화면의 저장만 자동 전환 대상이다.
  - 저장 레이아웃 ID가 구형 제품 기본값 `current_demo_v2_master_grid_01`일 때만 전환한다.
  - 사용자 레이아웃과 다른 카탈로그 레이아웃은 그대로 유지한다.
  - 이중 전선으로 교체한 복사본을 Stage 확장까지 재생성·검증한 뒤에만 복원한다.
  - 전환 복사본이 실패하고 원본 저장이 유효하면 원본을 복원한다.
  - 실제 저장 파일은 이후 정상 자동 저장 시점에 갱신되며, 로드 검사 자체는 입력 payload를 변경하지 않는다.
- 구형 회귀 픽스처:
  - `quarter_starting_layout`은 과거 6개 방의 정밀 좌표·소켓·Stage 확장 회귀 검사용으로 유지한다.
  - 제품 런타임 기본값과 구형 회귀 픽스처를 같은 의미로 사용하지 않는다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/dungeon_quarter/layouts/stage01_dual_front_01.json` | 후보 레이아웃을 제품 데이터 경로와 `product_default` 활성 상태로 승격 | 완료 |
| `scripts/core/DataRegistry.gd` | 제품 기본 레이아웃 로드·등록·기본 ID 선택, 구형 기본 ID 허용 목록 | 완료 |
| `scripts/game/GameRoot.gd` | 안전 체크포인트 구형 기본 저장 전환, 구조 검증, 원본 fallback, 복원 로그 | 완료 |
| `tools/tests/V122DualFrontDefaultActivationTest.gd` | 신규 기본값·구저장·사용자 레이아웃·불변성·fallback 계약 | 완료 |
| `tools/tests/V122DualFrontDefaultActivationTest.tscn` | 전용 headless 테스트 scene | 완료 |
| `tools/QuarterModuleSmokeTest.gd` | 제품 기본값 검사와 구형 6개 방 정밀 회귀 검사를 분리 | 완료 |
| `tools/tests/V122SaveProgressionTest.gd` | 이중 전선 확정 방어구역 anchor 기준 retry snapshot 계약 반영 | 완료 |
| `tools/tests/V122CombatRuleAdapterTest.gd` 외 이중 전선 전용 테스트 | 승격된 제품 레이아웃 경로 사용 | 완료 |
| `docs/design/v122/V122_STAGE01_DUAL_FRONT_COMBAT_STRUCTURE_CONTRACT_2026-07-29.md` | 승격된 제품 레이아웃 경로 기록 | 완료 |
| `docs/handoff/V122_DUAL_FRONT_PHASEA_LAYOUT_CANDIDATE_2026-07-29.md` | 후보의 제품 승격 경로 기록 | 완료 |
| `docs/handoff/V122_DUAL_FRONT_PHASEC2C_STAGE_MIGRATION_2026-07-29.md` | 승격된 제품 레이아웃 경로 기록 | 완료 |
| `docs/handoff/V122_DUAL_FRONT_PHASEC2D_DEFAULT_ACTIVATION_2026-07-29.md` | 이번 단계 정책·구현·검증 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 단일 진입점과 다음 작업 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- 신규 이미지 생성: 없음
- 런타임 그래픽·오디오 자산 변경: 없음
- 빌드·캡처 산출물: 없음

## 6. 테스트 및 검수

| 순서 | 테스트 | 결과 | 근거 |
|---:|---|---|---|
| 1 | `V122DualFrontDefaultActivationTest.tscn` | PASS | `.godot/V122DualFrontDefaultActivationTest-phasec2d-final.log` |
| 2 | `V122SpatialPlacementTest.tscn` | PASS | `.godot/V122SpatialPlacementTest-phasec2d-final.log` |
| 3 | `V122DualFrontLayoutContractTest.tscn` | PASS | `.godot/V122DualFrontLayoutContractTest-phasec2d.log` |
| 4 | `V122DualFrontStageMigrationTest.tscn` | PASS | `.godot/V122DualFrontStageMigrationTest-phasec2d.log` |
| 5 | `V122EnemyLaneRoutingTest.tscn` | PASS | `.godot/V122EnemyLaneRoutingTest-phasec2d.log` |
| 6 | `V122DefenderConnectorTest.tscn` | PASS | `.godot/V122DefenderConnectorTest-phasec2d.log` |
| 7 | `V122DualFrontDay01To05WaveTest.tscn` | PASS | `.godot/V122DualFrontDay01To05WaveTest-phasec2d.log` |
| 8 | `V122FacilityZoneCombatConsumerTest.tscn` | PASS | `.godot/V122FacilityZoneCombatConsumerTest-phasec2d.log` |
| 9 | `V122SaveZonePlacementCompatibilityTest.tscn` | PASS | `.godot/V122SaveZonePlacementCompatibilityTest-phasec2d.log` |
| 10 | `V122ManagementUIContractTest.tscn` | PASS | `.godot/V122ManagementUIContractTest-phasec2d.log` |
| 11 | `V122CombatRuleAdapterTest.tscn` | PASS | `.godot/V122CombatRuleAdapterTest-phasec2d.log` |
| 12 | `V122Day01To05ParityTest.tscn` | PASS | `.godot/V122Day01To05ParityTest-phasec2d.log` |
| 13 | `V122SaveProgressionTest.tscn` | PASS | `.godot/V122SaveProgressionTest-phasec2d-final.log` |
| 14 | `V122BuildingCompatibilityTest.tscn` | PASS | `.godot/V122BuildingCompatibilityTest-phasec2d.log` |
| 15 | `QuarterModuleSmokeTest.tscn` | PASS | `.godot/QuarterModuleSmokeTest-phasec2d-final.log` |
| 16 | 전체 QA·실제 플레이·시각 검수 | NOT_REQUESTED | 사용자 지시에 따라 보류 |

- Windows root certificate store 경고와 일부 fixture의 종료 시 ObjectDB/resource 정리 경고는 기존 headless 환경 경고다. 위 테스트의 선언 결과와 종료 코드는 PASS다.
- `V122SaveProgressionTest`의 의도적인 corrupt JSON fixture 오류 출력은 손상 저장 거부 계약의 일부다.
- 전체 회귀·전체 플레이·빌드는 실행하지 않았다.

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | NOT_REQUESTED | N/A | 미커밋 작업 트리 | 전체 검수 미요청 | 직접 영향 계약 테스트만 수행 | 위 테스트 로그 | TARGETED_PASS |

- 잔여 P1/P2 지적: N/A
- PASS 이후 기능·데이터·자산 변경 여부: 핸드오프 문서와 `CURRENT.md`만 갱신

### 정책 CI용 최종 영문 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 이중 전선은 이제 소스의 실제 제품 기본값이다. 코드·구조 계약은 통과했지만 실제 전투 재미, 양면 압력 밸런스, 1920/1280 시각 구성은 아직 사용자 플레이 검수 전이다.
- 저장 전환은 로드 시 메모리 복사본에 적용되고 다음 정상 저장에서 파일에 반영된다. 사용자 제작·선택 레이아웃은 자동 전환하지 않는다.
- 레이아웃 ID의 `candidate` 문자열은 데이터·웨이브·저장 호환을 위한 내부 ID다. 사용자 표시명에는 후보 표현을 사용하지 않는다.
- 기존 전투 P2, `trap` 내부 ID 노출 P3, DAY 1 선택·결산 인과 문제는 이번 단계 범위가 아니다.

## 8. 다음 작업 순서

1. 구조가 제품 기본값으로 고정됐으므로 Stage 01 시각 개편 comparison board를 먼저 만든다.
2. 한 장에서 1920 full-canvas·1280 compact, UI 프레임 3등급, 팔레트 역할, 방 모듈·DAY 1 캐릭터 contact sheet, 전투 합성 순서를 비교한다.
3. 승인된 방향으로 왕좌·두 전선의 4방향 문턱·복도 표면·공통 폐색 그림자·가장자리 마스크를 셀 정합형으로 제작한다.
4. 캐릭터 접지·배경 융화와 전투 HUD 레이어 중첩을 순차 수정한다.
5. 전체 QA와 실제 플레이 검수는 사용자가 별도로 요청할 때까지 보류한다.

## 9. 작업 트리 상태

- 브랜치: `codex/v122-ui-simplification`
- 미커밋 변경: 이번 Phase C-2d와 앞선 Phase A~C-2c, 시각·UI 작업이 같은 작업 트리에 남아 있다.
- 기존 사용자 변경과 다수 `.import`는 되돌리거나 정리하지 않았다.
- 커밋·푸시·빌드·배포: 수행하지 않음

## 10. 종료 체크리스트

- [x] 새 게임 제품 기본값 활성화
- [x] 구형 제품 기본 저장의 안전 체크포인트 전환
- [x] 사용자·커스텀 레이아웃 자동 전환 방지
- [x] 구조 검증 실패 시 원본 fallback
- [x] 관련 집중 테스트 통과
- [x] 전체 QA·실제 플레이·빌드 미수행 사실 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 커밋·푸시
