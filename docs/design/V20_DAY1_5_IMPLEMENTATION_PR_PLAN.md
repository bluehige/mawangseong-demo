# DAY 1~5 최초 구현 및 출시 이식 PR 계획

- 작성일: 2026-07-22
- 상위 계약: `docs/design/V20_DAY1_5_VALIDATION_CONTRACT.md`
- 검증 대상: `release/v2.0`
- 시작 SHA: `cd4be74bcd34c9ae9b1260fd84ada30b0b6537d3`
- 상태: 문서 PR 뒤 구현 대기

## 1. 순서 규칙

아래 PR은 번호 순서대로 진행한다. 앞 PR이 대상 브랜치에 merge되고 해당 차단 게이트를 통과하기 전에는 다음 PR을 만들지 않는다.

1. 준비와 전투의 방·슬롯·좌표를 하나의 모델로 통합
2. DAY 진행을 침입 확인 → 배치 → 방어 시작 → 전투 → 결과로 단순화
3. 시설·몬스터 배치를 실제 이동·교전·피해·목표 결과에 연결
4. DAY 1~5 적 구성과 밸런스 조정
5. 실제 물리 프레임, 숙련 수동과 초회 사용자 테스트
6. 수용 결과를 기준 패키지로 동결
7. 그 뒤에만 1.2.1 안정판 기반 새 출시 브랜치로 선별 이식

구현 PR에서 신규 스토리, 몬스터, 적, 시설, DAY 6 이후 콘텐츠, 모바일 전면 개편과 신규 최종 그래픽을 추가하지 않는다.

## 2. 공통 PR 계약

각 PR은 다음을 본문과 핸드오프에 적는다.

- base SHA와 head SHA
- 바꾼 플레이어 행동 1개
- 수정 파일 allowlist
- 의도적으로 수정하지 않은 파일
- 변경 전 실패 또는 부재를 재현하는 검사
- 변경 뒤 관련 자동·실제 실행 결과
- `user://campaign_save_v*.json` 실행 전후 SHA-256
- 다음 PR 진입 여부: `GO`, `PENDING`, `NO_GO`
- 롤백할 merge commit과 롤백 순서

`GameRoot.gd`와 `CombatSceneController.gd` 전체 교체를 금지한다. 해당 파일은 PR 목적에 필요한 함수 hunk만 수정하고 PR 본문에 함수명을 열거한다.

신규 `.gd`를 추가할 때 Godot이 생성한 같은 이름의 `.gd.uid`만 함께 추가할 수 있다. 아래 allowlist에 없는 import 산출물, `.godot/`, build와 capture는 커밋하지 않는다.

각 PR의 관련 테스트가 통과해도 `진행이 간단하다`, `배치가 재미있다`, `밸런스가 맞다`를 PASS로 쓰지 않는다. PR 6 수용 패키지 전에는 세 가설 상태가 모두 `PENDING`이다.

PR 1~5의 각 수정 파일 allowlist에는 아래 표의 날짜별 handoff 한 개와 `docs/handoff/CURRENT.md`가 마지막 두 항목으로 자동 포함된다. `<PR_OPEN_DATE>`는 해당 브랜치 생성일의 KST `YYYY-MM-DD`이며 PR 설명에 첫 runtime commit 전에 실제 날짜를 적어 경로를 고정한다. 고정 뒤 다른 날짜·handoff 경로는 추가하지 않고, `Reviewed SHA` 뒤에는 이 두 `docs/handoff/` 파일만 수정한다.

| PR | 고정 handoff 경로 |
|---:|---|
| 1 | `docs/handoff/V20_DAY1_5_SPATIAL_MODEL_<PR_OPEN_DATE>.md` |
| 2 | `docs/handoff/V20_DAY1_5_DAY_FLOW_<PR_OPEN_DATE>.md` |
| 3 | `docs/handoff/V20_DAY1_5_PLACEMENT_CAUSALITY_<PR_OPEN_DATE>.md` |
| 4 | `docs/handoff/V20_DAY1_5_BALANCE_<PR_OPEN_DATE>.md` |
| 5 | `docs/handoff/V20_DAY1_5_ACCEPTANCE_EXECUTION_<PR_OPEN_DATE>.md` |

## 3. PR 0 — 제품 계약 고정

- 브랜치: `codex/v20-day1-5-product-contract`
- 대상: `release/v2.0`
- 변경 종류: 문서만

### 수정 파일

- `AGENTS.md`
- `docs/design/V20_DAY1_5_VALIDATION_CONTRACT.md`
- `docs/design/V20_DAY1_5_IMPLEMENTATION_PR_PLAN.md`
- `docs/playtest/v20/DAY1_5_ACCEPTANCE_PROTOCOL.md`
- `docs/design/V20_CORE_REBUILD_MASTER_SPEC.md`
- `docs/design/V20_KEEP_REWORK_DEFER_MATRIX.md`
- `docs/PRODUCT_VERSIONING.md`
- `docs/GIT_VERSIONING_WORKFLOW.md`
- `docs/handoff/CURRENT.md`
- `docs/handoff/V20_DAY1_5_VALIDATION_CONTRACT_2026-07-22.md`

### 완료 게이트

- 코드, data, scene, asset, workflow 변경 0개
- `release/v2.0`의 역할이 검증선으로 명시됨
- DAY 1~5 각 두 대응, 목표 시간, 테스트 수, PASS·중단·롤백 기준이 숫자로 고정됨
- `release/v2.0 → main`과 DAY 6 이후 구현이 금지됨
- 기존 v1.2.1 태그·Release·저장·공개본이 불변으로 명시됨

## 4. PR 1 — 단일 공간 모델

- 권장 브랜치: `codex/v20-validation-spatial-model`
- base: PR 0이 merge된 최신 `origin/release/v2.0`
- 대상: `release/v2.0`
- 플레이어 변화: 준비 화면에 놓은 시설·몬스터가 전투의 정확히 같은 구역과 슬롯에서 시작한다.

### 현재 실패 원인

현재 공간 정보는 세 계층에 중복돼 있다.

- `data/v20/dungeon_layouts.json`: normalized 보드 anchor와 `north_gate/south_gate/treasure/fallback`
- `data/dungeon_quarter/test_layouts/role_driven_combat_layout_test_01.json`: 28×26 `logical_grid_v2` 실제 전투 layout
- 코드 translation:
  - `V20SessionService.SECTION_DEFINITIONS`
  - `V20PlacementBoard.SECTION_OFFSETS`
  - `CombatSceneController._v20_runtime_room()`
  - `GameRoot._v20_runtime_facilities()`
  - `GameRoot._v20_inject_fallback_runtime_room()`

이 구조에서는 준비의 `treasure`가 전투의 `barracks`가 되고, Z1 `north_gate`가 `entrance`가 된다. 첫 PR에서 이 translation을 제거한다.

### 수정 파일 allowlist

- `data/v20/dungeon_layouts.json`
- `data/v20/encounters.json`의 zone·route 식별자 canonical migration만. 적 수치·spawn 변경 금지
- `data/specializations.json`의 기존 v20 role 6개 `fallback_node` migration만
- `scripts/core/DataRegistry.gd`
- `scripts/dungeon_quarter/ModuleGraph.gd`의 canonical zone·slot 조회 API만
- 신규 `scripts/v20/spatial/V20SpatialModel.gd`
- 신규 `scripts/v20/spatial/V20SpatialModel.gd.uid`
- `scripts/v20/contracts/V20ContractValidator.gd`의 canonical start·zone 검증만
- `scripts/v20/path/V20FixedRouteService.gd`
- `scripts/v20/path/V20WeightedPathService.gd`의 구 ID 제거·고정 경로 호환 hunk만
- `scripts/v20/path/V20RoutePreview.gd`의 data-driven zone 표시만
- `scripts/v20/placement/V20PlacementService.gd`
- `scripts/v20/placement/V20PlacementBoard.gd`
- `scripts/v20/placement/V20PlacementRoomButton.gd`
- `scripts/v20/session/V20SessionService.gd`
- `scripts/v20/save/V20SaveStore.gd`의 v2→v3 envelope·payload migration만
- `scripts/v20/encounters/V20EncounterService.gd`의 spawn route canonical ID migration만
- `scripts/v20/ui/V20InformationHUD.gd`의 zone 목록 data 조회만
- `scripts/game/GameRoot.gd`의 v20 runtime 준비·placement adapter와 `_schedule_campaign_autosave`·`_flush_campaign_autosave` v20 차단 hunk만
- `scripts/game/ManagementSceneController.gd`의 v20 board setup만
- `scripts/game/CombatSceneController.gd`의 v20 zone lookup만
- 신규 `tools/tests/V20UnifiedSpatialModelTest.gd`
- 신규 `tools/tests/V20UnifiedSpatialModelTest.gd.uid`
- 신규 `tools/tests/V20UnifiedSpatialModelTest.tscn`
- `tools/tests/V20DecisionContractsTest.gd`
- `tools/tests/V20DecisionContractsTest.tscn`
- `tools/tests/V20InformationArchitectureTest.gd`
- `tools/tests/V20InformationArchitectureTest.tscn`
- `tools/tests/V20PlacementUxTest.gd`
- `tools/tests/V20PlacementUxTest.tscn`
- `tools/tests/V20StrategicRoutingTest.gd`
- `tools/tests/V20StrategicRoutingTest.tscn`
- `tools/tests/V20FacilityReworkTest.gd`
- `tools/tests/V20FacilityReworkTest.tscn`
- `tools/tests/V20MonsterRoleGrowthTest.gd`
- `tools/tests/V20MonsterRoleGrowthTest.tscn`
- `tools/tests/V20TacticalCommandsTest.gd`
- `tools/tests/V20TacticalCommandsTest.tscn`
- `tools/tests/V20DayOneToFiveEncountersTest.gd`
- `tools/tests/V20DayOneToFiveEncountersTest.tscn`
- `tools/tests/V20DifficultyEconomyTest.gd`
- `tools/tests/V20DifficultyEconomyTest.tscn`
- `tools/tests/V20OnboardingRetrySaveTest.gd`
- `tools/tests/V20OnboardingRetrySaveTest.tscn`
- `tools/tests/core_verification_suite.json`

`data/dungeon_quarter/test_layouts/role_driven_combat_layout_test_01.json`은 기존 테스트 기록으로 남길 수 있으나 v20 runtime이 읽지 못하게 한다. 삭제나 대규모 재작성은 이 PR 범위가 아니다.

### 구현 계약

- canonical ID는 `gate_outpost`, `spike_corridor`, `central_battle_room`, `throne_anteroom`, `throne`이다.
- 네 defense zone 레코드가 board anchor, world anchor, combat bounds, route entry·exit, 시설 슬롯 1개와 몬스터 슬롯 2개를 소유한다. `throne`은 slot 없는 goal zone이다.
- `data/v20/dungeon_layouts.json` 하나가 `logical_grid_v2`의 28×26 active grid, 128×64 tile, module·corridor origin, connection, zone bounds와 slot anchor를 함께 소유한다.
- `V20SpatialModel.to_module_graph_layout()`이 이 한 파일에서 `ModuleGraph.load_layout()` 입력을 메모리에서 만든다. `DataRegistry.V20_FIXED_RUNTIME_LAYOUT_PATH`와 test layout runtime read는 제거한다.
- v20 save schema와 `V20SaveStore` envelope를 모두 3으로 올리고 v2 payload의 이전 실험 ID를 한 번 변환한다.
- 변환 뒤 dictionary와 save JSON의 `zone_id`, `home_zone`, `target_zone`, `slot_zone`에 `north_gate`, `north_cross`, `south_gate`, `south_cross`, placement 의미의 `treasure`·`fallback`, `entrance`, runtime room 의미의 `barracks`가 남으면 실패한다.
- 준비 drop → save → load → combat spawn → result zone이 같은 canonical ID를 반환한다.
- board/world projection 왕복 뒤 logical cell x·y 오차는 각각 0.5칸 이하이다.
- v20 mode에서는 product autosave 예약·flush가 no-op이고 v20 종료 뒤 product mode에서만 다시 활성화된다.

### 테스트와 완료 게이트

- 5 zone, 시설 슬롯 4개, 몬스터 슬롯 8개의 ID 중복 0건
- `throne`의 placement slot 0개
- 모든 slot이 실제 combat bounds 안에 있음
- 12개 slot의 준비→저장→전투 왕복이 모두 동일
- 위 다섯 하드코딩 translation 함수·상수의 정의와 호출 0건, validator의 deprecated zone-key 값 0건
- 모든 deprecated ID를 넣은 schema 2 save fixture를 schema 3 envelope·payload로 변환해 저장·재로드하고 deprecated ID 0건 확인. 같은 파일을 두 번째 load했을 때 migration count 0, normalized payload fingerprint 동일
- 실제 `GameRoot.tscn`에서 v20 시작→관리→결과→종료를 실행해 sentinel `campaign_save_v1.json`~`campaign_save_v5.json` hash 변화 0건
- 별도 disposable OS profile에서 test가 만든 product save로 v20 종료 뒤 product mode 일반 autosave를 1회 실행해 hash가 정확히 1회 바뀌고 변경 field가 재로드됨. 위 sentinel hash는 계속 불변
- 신규 spatial test와 위 10개 V20 테스트 PASS
- 격리 test OS profile의 관리 1280×720에서 시설 1개·몬스터 3개를 유효 슬롯에 놓고 전투 진입해 동일 zone 표시를 실제 확인

하나라도 실패하면 PR 2를 시작하지 않는다.

## 5. PR 2 — 다섯 상태 DAY 흐름

- 권장 브랜치: `codex/v20-validation-day-flow`
- base: PR 1 merge SHA
- 플레이어 변화: 하루에 침입 확인, 배치, 방어 시작, 전투, 결과만 순서대로 실행한다.

### 수정 파일 allowlist

- 신규 `scripts/v20/flow/V20DayFlowService.gd`
- 신규 `scripts/v20/flow/V20DayFlowService.gd.uid`
- `scripts/v20/session/V20SessionService.gd`
- `scripts/v20/save/V20SaveStore.gd`
- `scripts/v20/onboarding/V20OnboardingService.gd`
- `scripts/v20/placement/V20PlacementService.gd`의 제거·이동·교체와 비용 재계산만
- `scripts/v20/placement/V20PlacementBoard.gd`의 배치 유효성·Undo만
- `scripts/v20/economy/V20EconomyService.gd`의 검증선 settlement 0 처리만
- `data/v20/economy.json`의 `v20_tactician` DAY 1~5 income·salvage 0만
- `scripts/game/GameRoot.gd`의 v20 screen transition, v20 mode lifecycle, 격리 acceptance-case 진입 함수만
- `scripts/game/ManagementSceneController.gd`의 다섯 상태 입력·표시만
- `scripts/game/CombatSceneController.gd`의 start·finish callback만
- `scripts/v20/ui/V20TitleEntryPanel.gd`
- `scripts/v20/ui/V20InformationHUD.gd`
- `scripts/v20/ui/V20ResultScreen.gd`
- `scenes/v20/ui/V20TitleEntryPanel.tscn`
- `scenes/v20/ui/V20InformationHUD.tscn`
- `scenes/v20/ui/V20ResultScreen.tscn`
- `data/v20/onboarding.json`
- 신규 `tools/tests/V20DayFlowStateMachineTest.gd`
- 신규 `tools/tests/V20DayFlowStateMachineTest.gd.uid`
- 신규 `tools/tests/V20DayFlowStateMachineTest.tscn`
- `tools/tests/V20InformationArchitectureTest.gd`
- `tools/tests/V20InformationArchitectureTest.tscn`
- `tools/tests/V20PlacementUxTest.gd`
- `tools/tests/V20PlacementUxTest.tscn`
- `tools/tests/V20DifficultyEconomyTest.gd`
- `tools/tests/V20DifficultyEconomyTest.tscn`
- `tools/tests/V20OnboardingRetrySaveTest.gd`
- `tools/tests/V20OnboardingRetrySaveTest.tscn`
- `tools/tests/core_verification_suite.json`

### 구현 계약

- 허용 상태는 `INTRUSION_BRIEF`, `PLACEMENT`, `DEFENSE_START`, `COMBAT`, `RESULT` 다섯 개다.
- 건설과 몬스터 배치는 `PLACEMENT` 안의 두 도구다. 별도 관리 화면이나 방 inspector로 이동하지 않는다.
- `방어 시작`은 시설 총비용 10 이하, 슬라임·고블린·임프가 각기 하나의 고유 monster slot을 가지며 zone당 최대 2명일 때만 활성화한다.
- `방어 시작` 뒤 추가 확인창 없이 배치 snapshot을 저장하고 3초 countdown 뒤 전투를 시작한다.
- loss의 `같은 배치 재도전`과 `배치 수정`은 모두 저장된 전투 직전 snapshot의 배치·HP·mana·command·cooldown·시설 charge·`encounter_seed`·전투 첫 physics frame 직전 RNG state를 먼저 복원한다.
- `같은 배치 재도전`은 편집 없이 `DEFENSE_START`, `배치 수정`은 복원한 배치를 편집할 수 있는 `PLACEMENT`로 간다. 전투 종료 시점의 소모·피해 상태는 어느 경로에도 남기지 않는다.
- 실패 salvage와 승리 income은 검증선에서 0으로 고정한다. 반복 패배로 build point를 얻지 못한다.
- DAY 1~5 검증 중 몬스터 level·EXP는 변하지 않는다. 새 DAY 시작 때 몬스터는 level 1·EXP 0과 catalog max HP·mana로 초기화한다.
- 시설 설치 총비용은 10 이하여야 한다. `available_build_points=10-sum(installed_facility.cost)`로 계산하며 승패·DAY 전환 때 재화를 지급하거나 이월하지 않는다.
- 새 DAY에는 직전 시설·몬스터 배치를 유지하고 같은 총비용 상한 안에서 제거·이동·교체한다. 몬스터 배치는 건설 점수를 소비하지 않는다.
- 새 DAY는 command 3/3, recharge progress 0, 모든 command·monster cooldown 0, 시설 charge catalog max, active·disable 0, 몬스터 status 0으로 시작한다.
- `OS.is_debug_build()`가 true이고 검증된 Windows user args의 `--v20-acceptance` 또는 검증된 Web query의 `v20_acceptance=1` 중 정확히 하나가 있을 때만 acceptance entrypoint를 연다. `begin_acceptance_case(day, seed, scenario_id)`는 `INTRUSION_BRIEF` 전에 DAY 1~5·protocol seed와 `A/B/C/D/FREE`만 허용하고 release export, 두 입력 동시 사용과 `COMBAT` 이후 호출은 실패한다. `FREE`는 배치를 주입하지 않으며 숙련 QA와 초회 사용자 관찰에만 쓴다.
- 숙련 QA와 초회 사용자는 DAY 1 전에 `begin_acceptance_campaign({1:2001,2:2002,3:2003,4:2004,5:2005}, FREE)`를 한 번 호출한다. Windows는 `OS.get_cmdline_user_args()`의 `--v20-seed-map`, debug Web export는 `JavaScriptBridge`로 읽은 `v20_acceptance`, `v20_seed_map`, `v20_scenario` query만 허용한다. 둘 다 같은 parser와 validator를 거치며 release export에서는 entrypoint와 query를 거부한다.
- `scenario_id=FREE`는 배치·명령·승패를 주입하지 않는다. 수동 C→A/B 분류는 raw placement·command event로만 정하고 retry는 같은 DAY의 seed와 RNG 초기 state를 복구한다.
- 기존 product save는 읽거나 쓰지 않는다.

### 테스트와 완료 게이트

- 상위 계약의 허용 edge 8개와 그 밖의 상태 조합을 모두 검사
- 100회 retry와 100회 DAY 전환 뒤에도 시설 총비용 상한은 10이고 `available_build_points`는 설치 비용 식과 일치
- 유효 배치는 몬스터 3종의 slot이 모두 고유하고 zone당 2개 이하이며, 한 조건이라도 깨지면 `DEFENSE_START` 거부
- 100회 DAY 전환마다 command·recharge·cooldown·facility charge/active/disable·level/EXP·HP/mana가 상위 계약 5.1 초기값과 일치
- 종료·이어하기 전후 day, 배치, HP·mana, command, facility charge가 계약과 일치
- 같은 snapshot의 전투 전 상태 fingerprint가 동일
- `begin_acceptance_case()`가 허용 15개 DAY/seed 조합과 `A/B/C/D/FREE`만 보존하고 product mode·잘못된 seed·미등록 scenario·COMBAT 이후 호출을 모두 거부하며, `FREE` 호출 전후 placement fingerprint가 빈 값으로 같음
- Windows user args와 Web query의 고정 seed map이 같은 canonical dictionary가 되며, `begin_acceptance_campaign()`은 FREE 외 scenario·누락 DAY·중복 seed·release export를 거부
- Windows CLI와 Web query를 각각 실제 `GameRoot.tscn`에 넣어 DAY 1 `DEFENSE_START → COMBAT`를 진행했을 때 `WaveManager`가 seed 2001을 받고 FREE placement fingerprint가 빈 값인 end-to-end test PASS
- C 패배 뒤 `RESULT → PLACEMENT → DEFENSE_START` 재도전의 `encounter_seed`와 전투 첫 physics frame 직전 RNG state hash가 C와 동일
- 1280×720에서 다섯 상태를 실제 클릭하고 뒤로가기·연타로 상태를 건너뛰지 못함
- 기존 저장 hash 변화 0건

상태 전이가 틀리거나 retry 자원 파밍이 가능하면 PR 3을 시작하지 않는다.

## 6. PR 3 — 배치의 실제 전투 인과 연결

- 권장 브랜치: `codex/v20-validation-placement-causality`
- base: PR 2 merge SHA
- 플레이어 변화: 시설·몬스터 위치를 바꾸면 실제 spawn, 이동, 교전, 피해와 목표 결과가 달라진다.

### 현재 실패 원인

- role service는 `manual_anchor_node`를 반환하지만 여러 runtime alias를 거친다.
- Encounter `response_tags`와 예상 outcome은 실제 전투 결과가 아니다.
- `V20EncounterService.resolve_phase()`와 DAY별 `record_metric()`이 실제 전투 종료 경로에서 완전히 연결되지 않았다.
- 일부 role 우선순위 테스트는 synthetic enemy tag를 사용하지만 실제 enemy data에는 같은 tag가 없다.

### 수정 파일 allowlist

- `data/v20/facilities.json`
- `data/v20/commands.json`
- `data/specializations.json`의 기존 6개 v20 role 블록만
- `data/enemies.json`의 현재 DAY 1~5 적 `tags` 보완만. 새 enemy ID와 기존 수치 변경 금지
- `scripts/v20/facilities/V20FacilityService.gd`
- `scripts/v20/monsters/V20MonsterRoleService.gd`
- `scripts/v20/commands/V20CommandService.gd`
- `scripts/v20/encounters/V20EncounterService.gd`의 실제 metric·phase resolution
- 신규 `scripts/v20/combat/V20BattleEvidence.gd`
- 신규 `scripts/v20/combat/V20BattleEvidence.gd.uid`
- `scripts/combat/TargetingService.gd`의 v20 tag 우선순위만
- `scripts/units/Unit.gd`의 v20 `home_zone`·slot·이동 사건 필드만
- `scripts/game/CombatSceneController.gd`의 v20 이동·표적·효과·metric hook만
- `scripts/game/GameRoot.gd`의 v20 result 합성만
- `scripts/v20/ui/V20ResultScreen.gd`
- `scenes/v20/ui/V20ResultScreen.tscn`
- 신규 `tools/tests/V20PlacementCausalityTest.gd`
- 신규 `tools/tests/V20PlacementCausalityTest.gd.uid`
- 신규 `tools/tests/V20PlacementCausalityTest.tscn`
- `tools/tests/V20FacilityReworkTest.gd`
- `tools/tests/V20FacilityReworkTest.tscn`
- `tools/tests/V20MonsterRoleGrowthTest.gd`
- `tools/tests/V20MonsterRoleGrowthTest.tscn`
- `tools/tests/V20TacticalCommandsTest.gd`
- `tools/tests/V20TacticalCommandsTest.tscn`
- `tools/tests/V20DayOneToFiveEncountersTest.gd`
- `tools/tests/V20DayOneToFiveEncountersTest.tscn`
- `tools/tests/core_verification_suite.json`

### 구현 계약

- 시설 effect는 actual world position이 설치 zone bounds 안일 때만 적용한다. 감시 초소 발동 reveal만 시설 anchor와 적 world position의 거리 420px 이하를 사용하고, 둔화·피해 배율은 bounds 안에서만 적용한다.
- 몬스터는 실제 monster slot에서 spawn하고 home zone을 지킨다.
- target priority는 실제 enemy catalog tag와 unit state에서 계산한다.
- first engagement, zone entry·exit, facility effect, damage, heal, disable, loot, breach event를 실제 발생 시각과 world position으로 기록한다.
- 결과 지표는 상위 계약 7.4의 start/end·union·중복 규칙으로 event ledger에서 만든다.
- 감시 초소 reveal과 적 집중의 보호 무시는 상위 계약 7.2·7.3의 대상·반경·지속을 실제 target selection에 적용한다. `imp_artillery`는 감시 초소가 노출한 인접 구간 후열을 사거리 안에서 전열보다 먼저 선택한다.
- 집결·비상 후퇴는 모든 생존 몬스터에게 적용하며 단일 몬스터 명령으로 축소하지 않는다.
- response tag는 설명 metadata로만 남기고 승패와 유효 대응 판정에 사용하지 않는다.

### 테스트와 완료 게이트

- 시설 5종을 한 구역씩 이동했을 때 effect event의 zone도 동일하게 이동
- DAY 1 seed 2001에서 A와 슬라임 slot 하나만 바꾼 D를 자연 전투로 실행해 상위 계약 7.5의 두 조건을 모두 만족
- 몬스터 한 마리를 `gate_outpost_monster_1`과 `throne_anteroom_monster_1`에 각각 배치했을 때 실제 spawn과 첫 이동 경로가 달라짐
- 시설·몬스터 실제 기여 지표가 의도한 run에서 0보다 큼
- 공병 무력화 중 시설 effect event 0건, 종료 뒤 복구
- 도둑의 실제 목표·약탈·도주가 미끼 유무에 따라 달라짐
- direct HP 수정, teleport, 직접 result 호출 없이 DAY 1 A/D 두 전투를 x1 60 Hz 물리 프레임으로 완주

인과 차이가 문자열·예상 수치에만 있으면 PR 4를 시작하지 않는다.

## 7. PR 4 — DAY 1~5 적 구성과 밸런스

- 권장 브랜치: `codex/v20-validation-day01-05-balance`
- base: PR 3 merge SHA
- 플레이어 변화: 매일 다른 전략 질문과 두 실제 대응이 생기며 전투 시간이 범위 안에 들어온다.

### 수정 파일 allowlist

- `data/v20/encounters.json`: 기존 적별 v20 전용 HP·ATK·spawn override만. `data/enemies.json` 공용 수치 변경 금지
- 신규 `tools/tests/fixtures/v20/day_response_scenarios.json`
- `scripts/v20/encounters/V20EncounterService.gd`
- `scripts/combat/WaveManager.gd`의 v20 adapter만
- `scripts/game/CombatSceneController.gd`의 v20 enemy behavior adapter만
- `scripts/game/GameRoot.gd`의 acceptance seed 전달 hunk만
- `scripts/core/DataRegistry.gd`
- `tools/tests/V20DayOneToFiveEncountersTest.gd`
- `tools/tests/V20DayOneToFiveEncountersTest.tscn`
- `tools/tests/V20DifficultyEconomyTest.gd`
- `tools/tests/V20DifficultyEconomyTest.tscn`
- `tools/tests/V20PlacementCausalityTest.gd`
- `tools/tests/V20PlacementCausalityTest.tscn`
- `tools/tests/core_verification_suite.json`

### 구현 계약

- 적 ID와 시설 ID를 추가하지 않는다.
- `flank_route`, `opposite_first_engagement`, 북·남 route 같은 고정 1경로와 모순되는 key를 제거한다.
- 각 DAY의 A/B/C/D placement, command event, `primary_success`, `secondary_success`, `mechanism_assertions`와 C 불이익을 test fixture JSON으로 선언한다. product runtime과 `DataRegistry`는 이 fixture를 읽지 않는다.
- HP·ATK 배율만 올려 시간을 맞추지 않는다. 우선순위는 적 수·spawn 간격·telegraph·특수 행동 지속 시간이다.
- 보통 난이도만 수용 기준으로 사용한다.
- `begin_acceptance_case(day, seed, scenario_id)`의 seed를 `WaveManager`까지 전달하고 현재 `2000+day` 덮어쓰기를 acceptance mode에서 금지한다.
- spawn schedule은 상위 계약 8절의 0.1초 단위 표와 일치시킨다. DAY 1은 탐험가 6명, DAY 2는 도둑 1명 뒤 탐험가 4명, DAY 3은 공병 1명 뒤 탐험가 4명, DAY 4는 첫 강화 방패병 1명·궁수 1명·후속 방패병 3명, DAY 5는 용사 1명 뒤 45초부터 탐험가 4명·도둑 1명이다.
- DAY 2 도난, DAY 3 시설 무력화 중 다른 시설 effect 부재, DAY 4 후열 압박 6.0초 이상, DAY 5 후퇴 돌파·2차 누수·도난은 실제 event ledger에서 필수 목표 실패를 만들고 제품 `RESULT.win=false`에 반영한다.
- `비상 후퇴` 중 몬스터는 대상 구역 이름이 먼저 바뀌어도 실제 world position이 대상 `combat_bounds`에 들어가기 전에는 이동을 멈추지 않는다. 5초 active 종료 뒤에도 수련생 용사가 살아 있으면 같은 목표를 유지하고, 용사 사망 뒤 각 home slot으로 복귀한다.
- 이 PR의 개발 중 물리 run은 수치 탐색 근거이며 공식 `PHYSICAL_COMBAT_PASS`가 아니다.

### 완료 게이트

- DAY 1~5 모두 A/B/C/D fixture가 존재하고 D는 A의 monster slot 하나만 다름
- schema·참조·고정 seed schedule PASS
- `DAY d(1..5) × A/B/C/D × 해당 DAY 첫 seed(2000+d)` = 20개 x1 60 Hz 후보 run 실행
- 20개 후보에서 A/B `primary_success`·`secondary_success`·mechanism true, C `primary_success == false`와 DAY별 불이익 true, A/D가 7.5 두 조건 true
- A/B 후보 전투 시간이 각 DAY 범위 안에 있음. 벗어나면 원인과 적 수·spawn·telegraph·특수 지속 조정값을 PR에 기록하고 재실행
- 신규 콘텐츠·자산 0개

첫 seed 20개 후보의 실제 수치는 상위 계약 9.1에 기록한다. 이 표는 PR 4 구현 전 계약 입력이며, PR 5의 70전·수동 24전·초회 사용자 10명 결과로 대체되기 전에는 어떤 PASS 등급도 부여하지 않는다.

PR 4는 밸런스 후보를 만드는 단계다. 공식 PASS는 PR 5에서만 판정한다.

## 8. PR 5 — 실제 물리·수동·초회 사용자 수용

- 권장 브랜치: `test/v20-day1-5-acceptance`
- base: PR 4 merge SHA
- 소스 대상: 테스트 도구는 `release/v2.0` PR, 실행 빌드는 `test/web-*` 정책에 따라 별도 보존

### 수정 파일 allowlist

- 신규 `tools/tests/V20DayOneToFivePhysicalCombatTrial.gd`
- 신규 `tools/tests/V20DayOneToFivePhysicalCombatTrial.gd.uid`
- 신규 `tools/tests/V20DayOneToFivePhysicalCombatTrial.tscn`
- 신규 `tools/tests/V20DayOneToFivePhysicalCombatSummary.gd`
- 신규 `tools/tests/V20DayOneToFivePhysicalCombatSummary.gd.uid`
- 신규 `tools/tests/V20DayOneToFivePhysicalCombatSummary.tscn`
- 신규 `tools/tests/RunV20DayOneToFiveAcceptance.ps1`
- `tools/tests/core_verification_suite.json`
- 신규 `docs/playtest/v20/PHYSICAL_RUN_RECORD.schema.json`
- 신규 `docs/playtest/v20/MANUAL_RUN_TEMPLATE.md`
- 신규 `docs/playtest/v20/FIRST_USER_SESSION_TEMPLATE.md`
- 신규 `docs/playtest/v20/ACCEPTANCE_MANIFEST_TEMPLATE.json`

### 실행 순서

1. test tooling commit까지 포함한 source 후보 full SHA를 고정하고 이후 파일 변경을 금지
2. 관련 자동 계약과 `tools/tests/RunCoreVerification.ps1 -Mode Full`
3. 실제 물리 70전
4. 같은 source SHA에서 Windows·Web debug acceptance export를 각각 생성하고 플랫폼별 build flavor·hash 고정
5. 숙련 QA 2명의 공식 A/B 성공 20전과 선행 C 패배 4전, 총 24전
6. 같은 Windows native debug acceptance build로 초회 사용자 10명 무설명 테스트
7. 모든 원본과 hash 집계

테스트 중 product code·data 결함을 발견하면 이 PR에서 함께 고치지 않는다. PR 1~4의 소유 범위에 새 수정 PR을 만들고 merge한 뒤 새 SHA에서 PR 5 전체를 다시 시작한다.

### 완료 게이트

- `AUTOMATED_CONTRACT_PASS`
- `PHYSICAL_COMBAT_PASS`
- `MANUAL_PLAY_PASS`
- `FIRST_USER_PASS`
- 세 가설 수치 전부 충족
- source SHA 1개, debug acceptance build flavor 1개, Windows ZIP·EXE·PCK hash 각 1개, Web PCK·WASM hash 각 1개로 통일

하나라도 없으면 `PENDING`, 기준 미달이면 `NO_GO`다.

## 9. PR 6 — 수용 기준 패키지 동결

- 권장 브랜치: `codex/v20-day1-5-acceptance-freeze`
- base: PR 5가 검증한 정확한 source SHA
- 변경 종류: 문서와 작은 비식별 evidence manifest만

### 패키지 파일

- 신규 `docs/acceptance/v20-day1-5/README.md`
- 신규 `docs/acceptance/v20-day1-5/manifest.json`
- 신규 `docs/acceptance/v20-day1-5/physical_summary.json`
- 신규 `docs/acceptance/v20-day1-5/manual_summary.md`
- 신규 `docs/acceptance/v20-day1-5/first_user_summary.md`
- 신규 `docs/acceptance/v20-day1-5/transplant_allowlist.json`
- 신규 `docs/handoff/V20_DAY1_5_ACCEPTANCE_FREEZE_<PR_OPEN_DATE>.md`. `<PR_OPEN_DATE>`는 PR 6 브랜치 생성일의 KST `YYYY-MM-DD`로 PR 설명에 첫 commit 전에 한 번 고정하며, 그 한 경로와 `docs/handoff/CURRENT.md`만 allowlist에 넣음

원본 영상, 대형 log, PCK, WASM과 실행 파일은 source 브랜치에 커밋하지 않는다. 별도 artifact 위치, SHA-256, byte 수와 보존 기간만 manifest에 기록한다.

### 완료 게이트

- 모든 evidence가 같은 source SHA를 가리키고 각 실행 platform의 고정 build hash와 일치
- 10명 표본에 PII가 없음
- 검증된 함수·data key allowlist와 금지 경로가 있음
- 가설별 계산을 원본 수치에서 재현할 수 있음
- protocol 2절의 v1.2.1 tag object·Release asset·PC/모바일 Pages provenance와 sentinel save hash가 PR 1 전 기준과 같음
- `release/v2.0`의 상태는 `DAY1_5_ACCEPTED` 또는 `NO_GO`로 명시됨
- `main` PR, 태그와 Release 생성 없음

## 10. 검증 뒤 새 출시 브랜치

PR 6이 `DAY1_5_ACCEPTED`를 기록하기 전에는 이 절을 실행하지 않는다.

### 10.1 기준과 계보

- 새 브랜치: `release/v2.0-product`
- 분기 기준: `origin/main` `7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 런타임 기준: 불변 `v1.2.1` commit `c483d135b13cf9771ee43b045ba2c3dde51573ee`
- 필수 계보 검사:
  - `v1.2.1`은 새 브랜치의 조상이어야 함
  - `git merge-base <product-head> <accepted-v20-sha>`는 정확히 `7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`여야 함
  - `git rev-list 7ee0b50965dd3944a7ab737c0eca76d2df2a82ad..<accepted-v20-sha>`의 모든 commit은 새 브랜치의 조상이 아니어야 함

`origin/main` 기준 SHA를 바꾸려면 먼저 docs 전용 PR에서 v1.2.1 이후 runtime diff가 0인지 다시 기록한다.

### 10.2 금지 명령과 금지 방법

- `git merge release/v2.0`
- `git cherry-pick`으로 실험선 merge commit 이식
- commit range 전체 cherry-pick
- `git checkout release/v2.0 -- .`
- `GameRoot.gd`, controller, data 디렉터리 전체 덮어쓰기

### 10.3 출시선 PR 순서

| 순서 | 브랜치 | 이식 단위 | 완료 게이트 |
|---:|---|---|---|
| L0 | `codex/v20-product-acceptance-baseline` | 수용 SHA·행동 계약 ID·allowlist·기존 저장 hash만 문서화 | runtime 변경 0 |
| L1 | `codex/v20-product-spatial-model` | canonical zone·slot·좌표와 projection | 준비·전투 공간 왕복 PASS |
| L2 | `codex/v20-product-day-flow` | 다섯 상태, 격리 저장, retry snapshot | 금지 전이·save 불변 PASS |
| L3 | `codex/v20-product-placement-effects` | 시설·몬스터 위치의 실제 전투 effect, 전술 명령과 event ledger | 통제 encounter에서 monster slot 하나만 바꿔 첫 교전·경로와 7.5 결과 threshold가 달라짐. 공식 DAY A/D 판정은 하지 않음 |
| L4 | `codex/v20-product-day01-05-balance` | DAY별 기존 적 구성·수치와 A/B/C/D fixture | 20개 후보 run의 A/B·C·A/D·시간 gate PASS |
| L5 | `codex/v20-product-physical-acceptance` | 자동·물리 runner와 Windows·Web 수동 검수 | 실제 물리 70전·수동 24전 PASS |
| L6 | `codex/v20-product-first-user-acceptance` | 새 출시선 build의 초회 사용자 10명 | `FIRST_USER_PASS` |
| L7 | `codex/v20-product-acceptance-freeze` | 새 출시선 수용 package | 네 등급과 세 가설 재PASS |

각 PR은 실험선의 파일을 복사하는 작업이 아니라 수용 allowlist의 행동을 안정판 구조에 맞춰 구현하는 작업이다. L7 뒤에도 사용자가 별도로 출시를 승인하기 전에는 `main` 병합, `v2.0.0` 태그, GitHub Release와 공개 URL 교체를 하지 않는다.

## 11. 롤백 책임표

| 발견된 문제 | 돌아갈 PR | 후속 처리 |
|---|---:|---|
| 준비·전투 구역/좌표 불일치 | PR 1 | PR 2~5 중단, 필요하면 역순 revert |
| 화면 전이·retry·save 문제 | PR 2 | PR 3~5 증거 무효, PR 2 수정 |
| 배치가 실제 결과를 바꾸지 않음 | PR 3 | 수치 조정 금지, 인과 hook부터 수정 |
| 두 대응 중 하나가 실제로 실패 | PR 4 또는 원인 소유 PR | 적 수·spawn·telegraph·특수 행동 지속이면 PR 4에서 조정. 시설·명령 수치나 scenario 정의가 원인이면 PR 4를 중단하고 선행 docs 전용 계약 PR 뒤 PR 3 소유범위 수정 PR을 만든 다음 PR 4 후보 run부터 재실행 |
| 물리 harness가 직접 결과를 조작 | PR 5 | 해당 evidence 폐기, runner 수정 뒤 70전 재실행 |
| 초회 기준 미달 | 원인에 따라 PR 1~4 | `NO_GO`, 새 SHA에서 네 등급 재실행 |
| 기존 v1.2.1 자산·저장 변경 | 해당 PR 즉시 revert | 이식·테스트 전부 중단 |

롤백은 마지막 승인 SHA 뒤 merge commit을 별도 PR에서 `git revert -m 1`로 되돌린다. 강제 푸시, reset과 태그 이동은 사용하지 않는다.
