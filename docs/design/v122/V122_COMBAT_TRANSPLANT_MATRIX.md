# v1.2.2 전투 규칙 이식 대응표

| 2.0 기능 | 근거 SHA·함수 | 검증 행동 | 1.2.1 대응 | 처리 | 제품 ID·adapter | 관련 테스트 | 완료 조건 |
|---|---|---|---|---|---|---|---|
| 공간 snapshot | `7e61cc9:scripts/v20/spatial/V20SpatialModel.gd` | 준비·전투가 같은 좌표계 사용 | `ModuleGraph.setup_quarter`, `center`, `path_between`, `debug_object_slots` | `ADAPT_TO_121` | `V122BattlePlanAdapter` | `V122SpatialPlacementTest` | 관리 room·slot과 전투 spawn 일치 |
| 방어 구간 | `V20SpatialModel`, `V20FixedRouteService` | 활성 route를 단계로 표시 | 실제 `ModuleGraph.path_between` | `PORT_RULE` | `V122DefenseSegmentBuilder` | 동일 테스트 | DAY 1~5 4구간, 이후 3~6구간 |
| 시설 배치 | `V20PlacementService.new_state/serialize/restore` | click·drag·undo와 slot 인과 | 기존 room/facility ID, 건설·업그레이드 | `ADAPT_TO_121` | `V122PlacementSlotAdapter` | placement adapter test | 제품 ID로 저장·복원 |
| 시설 효과 | `V20FacilityService` | 범위·목표·상태가 결과를 변경 | `GameRoot._facility_room_is_active`, room HP·disable | `PORT_RULE` | `V122FacilityEffectAdapter` | facility causality test | 실제 world anchor에서만 적용 |
| 몬스터 역할 | `V20MonsterRoleService` | home·표적·route·시설 synergy | `CombatSceneController.update_monster_ai`, 기존 스킬 | `ADAPT_TO_121` | `V122CombatRuleAdapter` | monster role test | 기존 스킬 뒤 배치 역할 적용 |
| 적 역할 | `V20EncounterService` | 도둑·공병·보호·후열·돌파 | 기존 `spawn_enemy`, engineer/thief/boss handlers | `ADAPT_TO_121` | 같은 combat adapter | enemy behavior test | 기존 고유 행동·보스 우선 |
| 제한 명령 | `V20CommandService.issue/tick` | 비용·target·duration·cooldown·ledger | `DirectiveManager`, `Unit` 이동·공격 | `PORT_RULE` | `V122CommandService` | tactical command test | 집결·집중·시설 발동·비상 후퇴 실제 결과 차이 |
| encounter 예고 | `V20EncounterService.telegraph/evaluate` | 목표·경로·새 패턴·대응 표시 | `campaign_days`, `waves`, 기존 timed lines | `ADAPT_TO_121` | `V122EncounterAdapter` | DAY 1~5 parity | 모든 기존 적·보스에 실제 상태 연결 |
| event ledger | `V20BattleEvidence.record_event/summarize` | 도난·무력화·후열·돌파·명령 기여 | 기존 result metrics와 `RunMetricsTracker` | `PORT_RULE` | `V122BattleLedger` | evidence test | UI 문구와 실제 event 수치 일치 |
| A/B/C/D | `V20PlacementCausalityTest`, `day_response_scenarios.json` | 두 승리·오답 불이익·한 slot 인과 | 캠페인 초기 상태 fixture | `ADAPT_TO_121` | `tools/fixtures/v122` | DAY 1~5 parity suite | D가 위치·첫 교전·피해 중 2개 변경 |
| DAY 1~5 수치 | `V20DifficultyEconomyTest`, balance candidate SHA | 전투 시간·피해 기준 | 실제 성장·재화·보상 | `RECALCULATE` | balance model | parity suite | 기준 오차 ±10% |
| v20 독립 경제·저장 | `data/v20/economy.json`, `V20SaveStore` | 시험 격리 | 제품 캠페인 경제·저장 | `REMOVE_TEST_ONLY` | 없음 | static closure | 정식 진입점·저장 소비자 0 |

## AI 우선순위

몬스터는 사망/강제 이탈 → 제한 명령 → 보스·스토리 강제 상태 → 긴급 방어 → 기존 스킬·역할 → 배치 역할 → 현재 교전 → home 복귀 → 정체 복구 순이다. 적은 사망/시전 → 기존 보스·특수 행동 → 작전 목표 → 역할 목표 → 방어 구간 → 교전 → 돌파 → 최종 목표 → 정체 복구 순이다.

모든 행은 구현 또는 명시적 제거 계약으로 분류됐다.

## P3 공간·배치 이식 결과

- `V122BattlePlanAdapter`는 별도 v20 지도 없이 현재 제품 `ModuleGraph`에서 room, corridor, 실제 route, world anchor, combat bounds와 배치 snapshot을 만든다.
- 적의 실제 진입점 `outside_approach`부터 목표까지의 제품 route를 사용하며 DAY 1~5는 4구간, DAY 6~30은 실제 route 길이에 따라 3~6구간을 만든다.
- `V122PlacementSlotAdapter`는 제품 room 수용량과 object slot을 facility·monster slot view model로 변환한다. 몬스터 spawn과 home anchor는 관리 화면의 assigned room center에서 결정된다.
- Stage 1~4, 저장 재생성, user custom layout 명시 지원을 `V122SpatialPlacementTest`로 검증했다.
- 관리와 전투 간 별도 zone translation table은 추가하지 않았다.
