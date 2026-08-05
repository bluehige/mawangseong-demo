# v1.2.2 이중 전선 Phase C-1 전선 진입 런타임 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-29
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 아니오
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: Phase B의 복수 전선 snapshot을 실제 적 생성과 이동이 소비하게 한다.
- 완료 조건: 일반 적은 지정된 A/B 전선에서 생성되어 전투 중 임의로 바꾸지 않고, 도둑과 공병은 목표 시설 슬롯의 전선에서 생성되며, 출현 전 전선·진입점·목표를 예고한다.
- 범위에서 제외한 사항: DAY 1~5 양면 웨이브 수치, DAY 3 연결로, 후보 기본값 활성화, Stage 01 그래픽, 전체 회귀·실플레이 QA, 빌드·배포.

## 3. 완료한 작업

### 전선 snapshot

- `V122BattlePlanAdapter`에 전선별 실제 전투 진입점 `lane_entries`와 사용자 표시명 `lane_labels`를 추가했다.
- A 전선 진입점은 `entrance`, B 전선 진입점은 `service_entrance`다. 외부 접근 통로인 `outside_approach*`와 실제 unit 생성 위치를 구분한다.
- 기존 단일 전선 계획은 새 필드가 비어 있어도 기존 `entrance`와 `active_route`로 동작한다.

### 웨이브와 예고

- 웨이브 schedule 각 항목에 `lane_id`, `spawn_room_id`, `exit_room_id`, 목표 room·시설 slot, `telegraph_id`를 결정적으로 붙인다.
- 일반 적의 명시적 `lane_id`를 보존한다. 아직 전선 값이 없는 기존 웨이브는 호환용 주 전선 A를 사용한다.
- 같은 적 종류라도 전선이나 목표 시설이 다르면 별도 예고 그룹으로 표시한다.
- 실제 출현 6초 전부터 적, 전선, 진입점, 목표를 전투 위협 HUD에 표시한다. 6초보다 이전에는 해당 사전 경고를 노출하지 않는다.
- 공병의 예정 시설이 출현 전에 이미 무력화됐다면 6초 경고 시점에 실제 유효 시설을 다시 선택하고, 갱신된 경고와 spawn이 같은 계약을 사용한다.

### 실제 적 생성과 경로

- 일반 적은 schedule에 고정된 전선 진입 room에서 실제 생성되며 unit metadata에 전선을 보존한다.
- 일반 왕좌 공격대는 해당 전선의 주 경로를 사용하고 시설 가지로 이탈하지 않는다.
- 다중 전선 후보의 신규 graph room은 전역 `rooms.json`에 임시로 섞지 않고도 실제 생성 위치로 사용할 수 있도록 combat actor point와 이동 room 판정을 graph instance까지 허용했다.
- 돌파 깊이와 결과 ledger가 더 이상 정문 `entrance`만 기준으로 계산되지 않는다. 각 적의 고정 전선 진입점을 기준으로 깊이를 계산하고 시설 가지는 연결 방어구역 깊이를 사용한다.

### 도둑과 공병

- 도둑은 현재 금고가 들어 있는 시설 슬롯의 전선에서 출현한다.
- 금고를 다른 슬롯으로 옮기면 도둑의 전선, 진입점, 목표 slot, 예고가 함께 바뀐다.
- 도둑은 약탈 후 하드코딩된 정문이 아니라 자신이 들어온 전선 진입점으로 이탈한다.
- 공병은 예정된 실제 시설 슬롯의 전선에서 출현하고 정확한 시설 room과 slot ID를 보존한다.
- 공병은 시설 무력화 뒤 같은 전선에서 왕좌 공격에 합류한다.
- 다중 전선에서 공병 목표가 출현 후 사라졌을 때 다른 전선 시설로 순간 재지정하지 않고 원래 전선의 왕좌 공격에 합류한다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/v122/spatial/V122BattlePlanAdapter.gd` | 전선별 실제 진입점과 표시명 snapshot | 완료 |
| `scripts/v122/combat/V122EncounterAdapter.gd` | schedule 전선·목표 annotation과 예고·spawn 계약 | 완료 |
| `scripts/game/CombatSceneController.gd` | 실제 lane spawn, 6초 경고, specialist 목표·이탈, lane별 돌파 깊이 | 완료 |
| `scripts/game/GameRoot.gd` | 후보 graph room의 combat actor 생성 위치 허용 | 완료 |
| `scripts/ui/HUDController.gd` | 전투 위협에 전선 표시 | 완료 |
| `tools/tests/V122DualFrontLayoutContractTest.gd` | lane entry·label snapshot 계약 | 완료 |
| `tools/tests/V122EnemyLaneRoutingTest.gd` | 순수 계약과 실제 spawn 소비자 검증 | 완료 |
| `tools/tests/V122EnemyLaneRoutingTest.tscn` | 전용 headless 실행 scene | 완료 |

기존 세션에서 이미 변경된 위 대형 runtime 파일의 Phase B·UI 변경은 보존했으며, 이번 작업과 무관한 줄을 정리하거나 되돌리지 않았다.

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 해당 없음
- 프롬프트/후처리/크롭/알파 처리 요약: 해당 없음
- 게임 연결 및 실제 렌더 확인 결과: 시각·실플레이 검수는 이번 작업 범위에서 요청되지 않았다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V122EnemyLaneRoutingTest.tscn` | PASS | `.godot/V122EnemyLaneRoutingTest-phasec-final.log` |
| 2 | `V122DualFrontLayoutContractTest.tscn` | PASS | `.godot/V122DualFrontLayoutContractTest-phasec-final1.log` |
| 3 | `V122FacilityZoneCombatConsumerTest.tscn` | PASS | `.godot/V122FacilityZoneCombatConsumerTest-phasec-final1.log` |
| 4 | `V122CombatRuleAdapterTest.tscn` | PASS | `.godot/V122CombatRuleAdapterTest-phasec-consumer.log` |
| 5 | `V122CommandButtonIntegrationTest.tscn` | PASS, 40 assertions | `.godot/V122CommandButtonIntegrationTest-phasec-final1.log` |
| 6 | `V122CombatUISimplificationTest.tscn` | PASS, 77 assertions | `.godot/V122CombatUISimplificationTest-phasec-consumer.log` |
| 7 | `V122CombatResultUIContractTest.tscn` | PASS | `.godot/V122CombatResultUIContractTest-phasec-rerun.log` |
| 8 | `V122Day01To05ParityTest.tscn` | PASS | `.godot/V122Day01To05ParityTest-phasec.log` |
| 9 | `V122Day02FeedbackTest.tscn` | PASS | `.godot/V122Day02FeedbackTest-phasec.log` |
| 10 | `V122SaveZonePlacementCompatibilityTest.tscn` | PASS | `.godot/V122SaveZonePlacementCompatibilityTest-phasec.log` |
| 11 | `V122SaveProgressionTest.tscn` | PASS | `.godot/V122SaveProgressionTest-phasec.log` |
| 12 | `git diff --check` 직접 영향 경로 | PASS | 줄 끝 변환 경고만 존재 |
| 13 | 전체 회귀 테스트 | NOT_REQUESTED | 사용자 지시에 따라 보류 |
| 14 | 시각/실플레이 검수 | NOT_REQUESTED | 사용자 지시에 따라 보류 |

`V122SaveProgressionTest`는 Godot `user://` 저장소 쓰기가 필요해 해당 테스트에만 실제 저장 권한을 사용했다. Windows root certificate store 경고와 기존 명령 통합 테스트 종료 시 resource leak 경고는 테스트 판정과 무관하다.

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | NOT_REQUESTED | N/A | 미커밋 작업 트리 | 전체 검수 미요청 | 직접 영향 계약 테스트만 수행 | 위 테스트 표 | TARGETED_PASS |

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. 전체 회귀·실플레이는 이번 작업에서 필수로 요청되지 않았다.
- PASS 이후 기능·데이터·자산 변경 여부: 핸드오프 문서와 `CURRENT.md`만 변경.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 후보 레이아웃은 계속 `candidate_not_product_default`다.
- 현재 제품 DAY 1~5 wave에는 `lane_id`가 없으므로 후보 구조에 그대로 적용하면 일반 적은 안전한 호환값인 A 전선만 사용한다. B 전선 학습은 다음 단계의 후보 전용 wave 데이터가 필요하다.
- 6초 위협 HUD의 데이터·문구 계약은 검증했지만 실제 렌더와 플레이 가독성은 확인하지 않았다.
- DAY 3 연결로의 건설 상태, 비용, 방어자 전용 traversal과 저장은 아직 없다.
- 신규 후보 room의 관리 화면용 descriptor와 Stage 2~4 마이그레이션은 제품 기본값 활성화 전에 추가해야 한다.
- 기존 작업 트리에 이번 작업과 무관한 대량 자산 import·UI 변경이 남아 있다.

## 8. 다음 작업 순서

1. 후보 구조에서만 사용하는 DAY 1~5 전선 wave 데이터를 추가하고 DAY 1 A 단독, DAY 2 B 경고·도둑·8~10초 양면전, DAY 3~5 점진 압박을 구현한다.
2. DAY 3 금화 1000·마나 100 연결로 건설 상태와 방어자 전용 traversal을 구현한다.
3. 연결로와 후보 room descriptor를 save·retry·구저장·Stage 2~4에 결정적으로 이식한다.
4. 직접 영향 테스트가 통과한 뒤에만 `stage01_dual_front_candidate_01`을 제품 기본값으로 활성화한다.
5. 구조 활성화 후 사용자 플레이 피드백을 받고 Stage 01 그래픽 작업을 재개한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: `codex/v122-ui-simplification`에 미커밋 변경이 존재한다.
- 미커밋 파일: 위 Phase C-1 코드·테스트·문서, Phase A/B 및 이전 시각·UI 작업.
- 의도하지 않은 기존 변경: 대량 `.import`와 기존 UI·설정 변경을 보존했으며 이번 작업에서 정리하거나 되돌리지 않았다.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: 없음. 대상 테스트 로그만 `.godot/`에 있다.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 요청받은 경우에만 전체 회귀·검수 에이전트 완료
- [x] 검수 대상 상태와 작업 ID 기록
- [x] 그래픽 생성 출처 해당 없음 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR/태그 상태 기록
