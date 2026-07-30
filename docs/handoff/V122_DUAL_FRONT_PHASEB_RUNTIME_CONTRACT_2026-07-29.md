# v1.2.2 이중 전선 Phase B 런타임 계약 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-29
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 아니오
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: Phase A의 이중 전선 후보를 실제 전투가 소비할 수 있도록 복수 전선, 방어구역, 교체식 시설 슬롯, 구역 효과, 명령 대상, 저장 호환 계약을 한 묶음으로 구현한다.
- 완료 조건: A/B 경로와 5개 방어구역이 전투 계획에 보존되고, 4개 시설 슬롯과 몬스터 배치가 분리되며, 시설 구역 효과와 직접 명령 대상이 실제 전투 계산 및 저장·retry에 연결된다.
- 범위에서 제외한 사항: 후보 레이아웃의 제품 기본값 활성화, 전선별 적 spawn·telegraph, DAY 1~5 웨이브 개편, DAY 3 연결로, Stage 01 그래픽, 전체 회귀·실플레이 QA, 빌드·배포.

## 3. 완료한 작업

### 구현

- `V122BattlePlanAdapter`가 단일 `active_route` 호환값과 함께 `lane_routes`, `route_starts`, `primary_lane_id`, `defense_zones`, `facility_slot_contracts`를 전투 snapshot에 보존하도록 확장했다.
- 몬스터 배치는 고정 방어구역 5개를 기준으로, 시설은 독립 슬롯 4개를 기준으로 저장한다. 기존 room 기반 데이터는 결정적으로 변환하되 존재하지 않는 이중 전선 topology를 임의 생성하지 않는다.
- 고정 구조는 두 외부 입구, 두 통로, 왕좌와 왕좌 직전 합류부다. 병영·회복실·금고·건설 슬롯 같은 시설 내용은 고정 위치가 아니며 네 시설 슬롯 사이에서 교체할 수 있다.
- 시설 효과 해석기를 추가해 `local`, `adjacent`, `lane`, `global` 범위를 구역 연결 관계로 판정한다. 같은 대상·같은 효과 계열은 가장 강한 하나만 적용하고 서로 다른 계열은 조합한다.
- 병영 공격·방어, 회복실 지속 회복, 감시 시설 감속·탐지·노출 추가 피해, 수호핵 전역 방어를 실제 전투 계산에 연결했다.
- 무력화된 시설은 즉시 효과에서 빠지며, 시설 발동 명령은 같은 역할명의 다른 시설이 아니라 정확한 `facility_slot_id` 한 곳만 강화한다.
- 통로 중간 room은 해당 전선의 가장 가까운 방어구역으로 결정적으로 연결하고, 양 전선 공유 노드는 왕좌 전실 구역으로 연결한다.
- 기존 단일 경로 제품 계획에는 종전 room 거리 기반 시설 계산을 유지해 후보 활성화 전 회귀를 차단했다.

### 명령 대상

- 집결과 비상 후퇴의 대상은 `defense_zone`이다. 전장에 표시된 구역을 클릭하면 즉시 발동하고, 여러 room으로 구성된 같은 구역 안에서는 불필요하게 역이동하지 않는다.
- 집중 공격의 대상은 정확한 적 instance ID다.
- 시설 발동의 대상은 정확한 시설 슬롯 ID이며 `room_id`, `facility_instance_id`, 시설 object anchor를 함께 보존한다.
- 시설 피해 감소와 명령 피해 감소는 서로 다른 계산 단계와 통계 항목으로 분리했다.

### 저장 및 호환성

- 저장 schema version은 변경하지 않고 optional additive field로 `defense_zone_id`, `assigned_defense_zone_id`, `facility_slot_id`, `facility_instance_id`를 추가했다.
- 기존 `room_id`는 호환 alias로 유지한다.
- retry는 현재 battle plan을 사용해 zone·slot에서 runtime anchor room을 복원하며, legacy room 기반 배치도 그대로 읽는다.
- 잘못된 optional 식별자 타입과 잘못된 plan collection 타입은 저장 검사에서 거부한다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/v122/command_rules.json` | 집결·후퇴 대상을 방어구역으로 고정 | 완료 |
| `data/v122/facility_zone_effects.json` | 시설별 구역 효과 catalog | 완료 |
| `scripts/v122/spatial/V122BattlePlanAdapter.gd` | A/B 전선·방어구역·시설 슬롯 snapshot | 완료 |
| `scripts/v122/spatial/V122PlacementSlotAdapter.gd` | 몬스터 zone 배치와 시설 slot 배치 분리 | 완료 |
| `scripts/v122/spatial/V122FacilityZoneEffectResolver.gd` | 구역 범위·최강 중첩 규칙 해석 | 완료 |
| `scripts/v122/combat/V122CommandService.gd` | typed 명령 대상·다중 room 구역 이동 | 완료 |
| `scripts/v122/save/V122SaveProgressionAdapter.gd` | zone·slot optional 저장과 legacy/retry 복원 | 완료 |
| `scripts/game/CombatSceneController.gd` | 시설 효과와 명령 후보의 실제 전투 소비 | 완료 |
| `scripts/game/GameRoot.gd` | 전장 직접 클릭·구역 표시·retry plan 전달 | 완료 |
| `tools/tests/V122DualFrontLayoutContractTest.gd` | 다중 전선 runtime snapshot 계약 | 완료 |
| `tools/tests/V122FacilityZoneEffectResolverTest.gd` | 범위·중첩·무력화 규칙 | 완료 |
| `tools/tests/V122FacilityZoneCombatConsumerTest.gd` | 실제 공격·방어·회복·감속·명령 소비 | 완료 |
| `tools/tests/V122SaveZonePlacementCompatibilityTest.gd` | zone·slot 저장 및 legacy 호환 | 완료 |
| `tools/tests/V122CombatRuleAdapterTest.gd` 외 직접 영향 테스트 | 명령 UI·직접 대상 계약 회귀 | 완료 |

각 신규 `.gd` 테스트에는 같은 이름의 `.tscn` 실행 scene이 있다.

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 해당 없음
- 프롬프트/후처리/크롭/알파 처리 요약: 해당 없음
- 게임 연결 및 실제 렌더 확인 결과: 그래픽 작업과 실플레이 검수는 이번 Phase B 범위에서 요청되지 않았다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V122DualFrontLayoutContractTest.tscn` | PASS | `.godot/V122DualFrontLayoutContractTest-phaseb-final.log` |
| 2 | `V122SpatialPlacementTest.tscn` | PASS | `.godot/V122SpatialPlacementTest-phaseb-final.log` |
| 3 | `V122FacilityZoneEffectResolverTest.tscn` | PASS | Godot headless 출력 |
| 4 | `V122FacilityZoneCombatConsumerTest.tscn` | PASS | `.godot/V122FacilityZoneCombatConsumerTest-phaseb-final.log` |
| 5 | `V122CombatRuleAdapterTest.tscn` | PASS | Godot headless 출력 |
| 6 | `V122SaveZonePlacementCompatibilityTest.tscn` | PASS | Godot headless 출력 |
| 7 | `V122SaveProgressionTest.tscn` | PASS | `.godot/V122SaveProgressionTest-phaseb-final-escalated.log` |
| 8 | `V122CombatUISimplificationTest.tscn` | PASS, 77 assertions | Godot headless 출력 |
| 9 | `V122CommandButtonIntegrationTest.tscn` | PASS, 40 assertions | Godot headless 출력 |
| 10 | 명령 결과·DAY 2 직접 영향 테스트 | PASS | `V122CombatResultUIContractTest`, `V122Day02FeedbackTest` |
| 11 | `git diff --check` | PASS | 줄 끝 변환 경고만 존재 |
| 12 | 전체 회귀 테스트 | NOT_REQUESTED | 사용자 지시에 따라 보류 |
| 13 | 시각/실플레이 검수 | NOT_REQUESTED | 사용자 지시에 따라 보류 |

`V122SaveProgressionTest`의 첫 샌드박스 실행은 Godot `user://` 임시 저장소 쓰기가 차단되어 실패했다. 같은 작업 트리를 실제 저장 권한으로 재실행해 PASS를 확인했다. Windows root certificate store 경고는 모든 대상 테스트의 판정과 무관하다.

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
- 신규 후보 room의 제품 runtime descriptor와 전선별 spawn이 아직 없으므로 지금 기본값으로 켜면 안 된다.
- 일반 적의 고정 전선과 도둑·공병의 목표 시설 전선 선택·예고·귀환은 Phase C 작업이다.
- DAY 3 방어자 전용 연결로는 비용과 위치만 확정됐으며 traversal과 저장은 아직 없다.
- 전체 플레이에서 전선 분산이 실제로 전투 재미를 높이는지는 Phase C 이후 사용자 검수 대상이다.
- 기존 작업 트리에 이번 작업과 무관한 대량 자산 import·UI 변경이 남아 있으므로 후속 커밋 시 범위를 분리해야 한다.

## 8. 다음 작업 순서

1. `CombatSceneController.gd`, 적 wave/runtime 데이터, 후보 room descriptor에 일반 적의 고정 A/B 전선 spawn과 전선 예고를 연결한다.
2. 도둑·공병이 목표 시설의 현재 `facility_slot_id`가 속한 전선으로 진입하고 목표 달성 또는 이탈 시 같은 전선으로 귀환하도록 구현한다.
3. DAY 1~5의 양면 웨이브와 DAY 3 금화 1000·마나 100 방어자 전용 연결로를 연결한다.
4. 구저장·retry·Stage 2~4에서 후보 구조를 결정적으로 재생성하는 마이그레이션을 추가한다.
5. 위 항목의 직접 영향 테스트가 통과한 뒤에만 `stage01_dual_front_candidate_01`을 제품 기본값으로 활성화한다.
6. 구조가 고정된 후 Stage 01 그래픽 제작과 전투 HUD 시각 개편을 재개한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: `codex/v122-ui-simplification`에 미커밋 변경이 존재한다.
- 미커밋 파일: 위 Phase B 코드·데이터·테스트·문서와 이전 세션 변경.
- 의도하지 않은 기존 변경: 대량 `.import` 및 기존 UI·설정 변경을 보존했으며 이번 작업에서 정리하거나 되돌리지 않았다.
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
