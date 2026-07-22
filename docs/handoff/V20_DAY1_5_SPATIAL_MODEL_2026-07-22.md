# DAY 1~5 PR 1 단일 공간 모델 핸드오프

## 1. 메타데이터

- 완료일: 2026-07-23 KST
- PR open date 및 고정 파일 날짜: 2026-07-22 KST
- 작업 브랜치: `codex/v20-validation-spatial-model`
- 대상 브랜치: `release/v2.0`
- 기준 SHA: `cc87605eed3a23b8da26a79fa06345fcc05e1999`
- Reviewed SHA: `5d279b6b29db3b4efa620b91eba5bde4d1dd62b3`
- Review range: `cc87605eed3a23b8da26a79fa06345fcc05e1999..5d279b6b29db3b4efa620b91eba5bde4d1dd62b3`
- Draft PR: [#67](https://github.com/bluehige/mawangseong-demo/pull/67)
- 다음 PR 진입 판정: `PENDING`. PR #67의 merge commit이 생기기 전에는 PR 2 브랜치를 만들지 않는다.

## 2. 플레이어 행동 변화

플레이어가 준비 화면에서 선택한 시설 구역과 몬스터 슬롯을 저장·불러오기·전투가 같은 ID와 좌표로 사용한다.

- 방어 구역은 `gate_outpost`, `spike_corridor`, `central_battle_room`, `throne_anteroom` 네 개다.
- 각 방어 구역은 시설 슬롯 1개와 몬스터 슬롯 2개를 가진다. 총 슬롯은 12개다.
- `throne`은 배치 슬롯이 없는 최종 목표다.
- 침입 경로는 `gate_outpost → spike_corridor → central_battle_room → throne_anteroom → throne` 하나다.
- 준비 단계에서 배치한 `slime`, `goblin`, `imp`는 전투에서 각각 저장된 `monster_slot_id`의 world 좌표에 생성된다.

이 PR은 시설·몬스터 위치가 피해나 승패를 바꾸는 PR 3을 구현하지 않았다. 현재 확인한 것은 준비와 전투가 같은 위치를 사용한다는 사실까지다.

## 3. 고정한 공간 수치

| 항목 | 값 |
|---|---|
| active logical grid | 28×26 |
| tile projection | 128×64 |
| room cell | 5×5 |
| corridor gap | 2×2 |
| grid stride | 7×7 |
| world projection origin | `(933.12, 122.56)` |
| basis X / basis Y | `(26.88, 13.44)` / `(-26.88, 13.44)` |
| 관리 보드 world rect | `(480, 250, 1120, 430)` |

| zone | logical origin | world anchor | combat bounds `(x,y,w,h)` | 시설 슬롯 | 몬스터 슬롯 |
|---|---:|---:|---:|---|---|
| `gate_outpost` | `(2,14)` | `(610.56,391.36)` | `(520,330,181,123)` | `gate_outpost_facility` | `gate_outpost_monster_1`, `gate_outpost_monster_2` |
| `spike_corridor` | `(9,14)` | `(798.72,485.44)` | `(708,424,181,123)` | `spike_corridor_facility` | `spike_corridor_monster_1`, `spike_corridor_monster_2` |
| `central_battle_room` | `(9,7)` | `(1067.52,431.68)` | `(900,350,360,175)` | `central_battle_room_facility` | `central_battle_room_monster_1`, `central_battle_room_monster_2` |
| `throne_anteroom` | `(23,7)` | `(1363.2,579.52)` | `(1272,518,182,123)` | `throne_anteroom_facility` | `throne_anteroom_monster_1`, `throne_anteroom_monster_2` |
| `throne` | `(23,0)` | `(1551.36,485.44)` | `(1460,424,183,123)` | 없음 | 없음 |

## 4. 구현 결과와 수정 파일

| 경로 | 구체적 변경 |
|---|---|
| `data/v20/dungeon_layouts.json` | 위 5개 zone, 12개 slot, projection, ModuleGraph module·corridor·connection과 고정 경로를 한 레코드에 저장 |
| `data/v20/encounters.json` | zone·route ID만 canonical ID로 변경. 적 count, HP/ATK scale, start, telegraph, spawn interval은 변경하지 않음 |
| `data/specializations.json` | 기존 v20 역할 6개의 `fallback_node`만 canonical ID로 변경 |
| `scripts/v20/spatial/V20SpatialModel.gd`, `.gd.uid` | zone·slot 조회, logical/world 왕복, 보드 anchor 변환과 ModuleGraph 입력 생성 |
| `scripts/core/DataRegistry.gd` | test layout runtime read 제거, canonical JSON에서 V20 runtime layout 생성. 제품용 quarter layout 목록에는 노출하지 않고 `quarter_layout(V20_RUNTIME_LAYOUT_ID)`로만 조회 |
| `scripts/dungeon_quarter/ModuleGraph.gd` | canonical zone 목록, slot→zone, slot world 좌표, world 좌표→zone 조회 API 추가 |
| `scripts/v20/contracts/V20ContractValidator.gd` | 시작점 `gate_outpost`, route 순서, 5개 zone과 12개 고유 slot 검증 |
| `scripts/v20/path/V20FixedRouteService.gd`, `V20WeightedPathService.gd`, `V20RoutePreview.gd` | 선언된 시작점·고정 경로와 data의 zone 표시명 사용 |
| `scripts/v20/placement/V20PlacementService.gd`, `V20PlacementBoard.gd` | roster에 `monster_slot_id` 저장, 구역 anchor·경로 표시를 canonical data에서 조회 |
| `scripts/v20/session/V20SessionService.gd` | schema 3, 네 방어 구역과 12개 slot으로 초기 배치 생성, 구 section→runtime translation 제거 |
| `scripts/v20/save/V20SaveStore.gd` | envelope·payload schema 3, schema 2 구 ID를 canonical ID로 한 번만 변환하고 변환본 저장 |
| `scripts/v20/encounters/V20EncounterService.gd` | spawn이 선언된 `gate_outpost` 시작점과 canonical 목표를 사용 |
| `scripts/v20/ui/V20InformationHUD.gd`, `scripts/game/ManagementSceneController.gd` | 방어 단계와 배치 보드가 canonical zone data를 사용 |
| `scripts/game/GameRoot.gd` | canonical runtime room 설치·placement 적용, V20 활성 중 제품 autosave 예약·flush 차단 |
| `scripts/game/CombatSceneController.gd` | 몬스터를 저장된 slot world 좌표에 생성하고 route checkpoint·시설·방어 단계를 canonical zone으로 조회 |
| `tools/tests/V20UnifiedSpatialModelTest.gd`, `.gd.uid`, `.tscn` | 12개 slot 왕복, schema 2→3 1회 변환, 저장 격리, 준비→전투 좌표와 1280×720 캡처 검사 |
| 기존 V20 테스트 10개와 `tools/tests/core_verification_suite.json` | canonical ID 기대값으로 갱신하고 신규 공간 검사를 Quick/Full에 등록 |

`GameRoot.gd`에서 수정한 함수는 `_schedule_campaign_autosave`, `_flush_campaign_autosave`, `_v20_prepare_runtime`, `_v20_install_spatial_runtime_rooms`, `_v20_apply_session_placement_to_runtime`, `_v20_spatial_facility_rows`, `_v20_continue_from_result`, `_engineer_target_facility_rooms`다.

`CombatSceneController.gd`에서 수정한 함수는 `_v20_facility_target_for_runtime_room`, `spawn_monsters`, `spawn_enemy`, `_v20_runtime_checkpoints`, `v20_defense_stage_hud_state`, `_apply_v20_role_movement`, `_v20_role_context`, `_v20_spatial_facilities`, `_new_v20_facility_state`, `_treasure_room`이다. 구 translation 함수 `_v20_runtime_room`은 제거했다.

## 5. 제거한 중복과 의도적으로 건드리지 않은 범위

production `scripts/`와 `data/`에서 다음 정의와 호출은 0건이다.

- `V20SessionService.SECTION_DEFINITIONS`
- `V20PlacementBoard.SECTION_OFFSETS`
- `CombatSceneController._v20_runtime_room`
- `GameRoot._v20_runtime_facilities`
- `GameRoot._v20_inject_fallback_runtime_room`
- `DataRegistry.V20_FIXED_RUNTIME_LAYOUT_PATH`
- `DataRegistry.V20_FIXED_RUNTIME_LAYOUT_ID`

다음 항목은 수정하지 않았다.

- `data/dungeon_quarter/test_layouts/role_driven_combat_layout_test_01.json`
- DAY 1~5 적 수, HP/ATK scale, 시작 시각, telegraph, spawn interval
- 신규 스토리·몬스터·적·시설과 DAY 6 이후 콘텐츠
- 모바일 전면 개편, 신규 최종 그래픽, scene·asset·workflow
- `main`, 1.2.1 기반 브랜치, `v1.2.1` tag·Release·제품 저장·PC/모바일 공개본

## 6. 테스트와 객관적 결과

| 검사 | 결과 | 수치·근거 |
|---|---|---|
| `V20UnifiedSpatialModelTest.tscn` headless | PASS | 68 assertions: 5 zone, 12 slot, 좌표 왕복, save/load, migration, autosave 격리, 실제 GameRoot 전투 spawn |
| 기존 V20 테스트 10개 | PASS | 348 assertions |
| V20 테스트 합계 | PASS | 11개 scene, 416 assertions |
| 실제 창 `--capture-v20-spatial` | PASS | 1280×720, 70 assertions. 시설 1개·몬스터 3개 준비 화면과 전투 화면 저장, 준비 slot과 전투 spawn 오차 0.01px 이하 |
| `QuarterModuleSmokeTest.tscn` | PASS | V20 runtime layout을 제품 quarter layout 목록과 분리한 뒤 기존 맵·소켓·렌더 검사 통과 |
| `RunCoreVerification.ps1 -Mode Quick` | PASS | 83/83, 295.46초, `tmp/core_verification/runs/20260723_005300` |
| `git diff --check` | PASS | whitespace error 0건 |
| 금지 translation 검색 | PASS | production 정의·호출 0건 |

캡처는 커밋하지 않았다.

- `user://v20_spatial_preparation_1280x720.png`
- `user://v20_spatial_combat_1280x720.png`

두 PNG를 직접 열어 준비 화면의 네 방어 구역과 왕좌가 한 경로에 표시되고, 전투 화면의 `slime`, `goblin`, `imp`가 서로 다른 canonical slot에서 시작하는 것을 확인했다. 잘림과 zone 표시 불일치는 발견되지 않았다.

## 7. 제품 저장 불변 증거

실제 Godot 사용자 데이터의 제품 저장은 읽기 전용으로 테스트 실행 전후 SHA-256을 대조했다.

| 파일 | 실행 전 | 실행 후 | 결과 |
|---|---|---|---|
| `campaign_save_v1.json` | `28c157c9df84776a37d61ece1a7c58e70465212e2589d84c845d955fef22196c` | 같은 SHA-256 | 불변 |
| `campaign_save_v2.json` | `MISSING` | `MISSING` | 새 파일 0개 |
| `campaign_save_v3.json` | `MISSING` | `MISSING` | 새 파일 0개 |
| `campaign_save_v4.json` | `MISSING` | `MISSING` | 새 파일 0개 |
| `campaign_save_v5.json` | `MISSING` | `MISSING` | 새 파일 0개 |

별도 주입한 test-only v1~v5 sentinel은 V20 활성 중 byte 변경 0건이었다. V20을 비활성화한 뒤 test-only v1 경로에서만 제품 autosave가 다시 기록되는 것도 확인했다. 실제 제품 저장에는 쓰지 않았다.

## 8. 판정과 해석 제한

- PR 1 기술 게이트: `TARGETED_PASS`
- PR 2 진입: `PENDING`. PR #67 merge commit 확인 뒤 `GO`로 바꿀 수 있다.
- `게임 진행이 간단하다`: `PENDING`
- `건물과 몬스터의 배치로 승리하는 재미가 있다`: `PENDING`
- `전투 밸런스가 맞다`: `PENDING`

자동 assertion, 서비스 출력, 문자열 태그, 예상 점수와 1280×720 화면 확인만으로 실제 전투·재미·밸런스를 PASS 처리하지 않았다. 공식 실제 물리 70전, 숙련 QA 24전, 초회 사용자 10명 테스트는 PR 5에서 같은 source SHA와 build hash로 실행한다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 5d279b6b29db3b4efa620b91eba5bde4d1dd62b3
- Review range: cc87605eed3a23b8da26a79fa06345fcc05e1999..5d279b6b29db3b4efa620b91eba5bde4d1dd62b3
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS
- Reviewed SHA 뒤 기능·data·asset 변경: 0건. 이 handoff와 `docs/handoff/CURRENT.md`만 변경

## 9. 롤백

PR #67 merge 뒤 준비·전투 zone/slot/좌표 불일치가 발견되면 PR 2~5를 중단한다. 별도 rollback PR에서 PR #67의 merge commit을 `git revert -m 1 <merge-sha>`로 되돌린다. 강제 푸시, reset, 태그 이동은 하지 않는다.

`release/v2.0`을 `main` 또는 1.2.1 기반 브랜치에 통째로 병합하지 않는다. `v1.2.1` tag·Release·저장·공개본은 변경하지 않는다.

## 10. 다음 차례: PR 2 다섯 상태 DAY 흐름

PR #67이 `release/v2.0`에 merge된 뒤에만 다음 순서로 진행한다.

1. `git fetch origin`과 `gh pr view 67`로 merge commit을 확인한다.
2. 그 merge SHA를 base로 `codex/v20-validation-day-flow` 브랜치와 별도 worktree를 만든다.
3. `INTRUSION_BRIEF → PLACEMENT → DEFENSE_START → COMBAT → RESULT` 다섯 상태와 허용 edge 8개를 `V20DayFlowService`에 구현한다.
4. 시설 설치 총비용 10 이하, `slime`·`goblin`·`imp`의 고유 slot 3개, zone당 최대 2명일 때만 `방어 시작`을 허용한다.
5. `방어 시작` 클릭 시 추가 확인창 없이 배치 snapshot을 저장하고 3초 countdown 뒤 전투를 시작한다.
6. 패배 뒤 `같은 배치 재도전`은 `DEFENSE_START`, `배치 수정`은 `PLACEMENT`로 이동하되 두 경로 모두 전투 직전 snapshot을 먼저 복원한다.
7. retry 100회와 DAY 전환 100회에서 build point, HP·mana, command, cooldown, facility charge, level·EXP와 RNG fingerprint가 계약값을 유지하는지 검사한다.
8. Windows CLI와 debug Web query의 acceptance seed map을 검증하고, 1280×720에서 다섯 상태를 실제 클릭해 뒤로가기·연타로 상태를 건너뛰지 못하는지 확인한다.

PR 2 수정 파일 allowlist는 `docs/design/V20_DAY1_5_IMPLEMENTATION_PR_PLAN.md` 5절만 사용한다. PR 2에서는 적 수치, 실제 배치 인과 hook, DAY 밸런스, 신규 콘텐츠와 그래픽을 수정하지 않는다. 상태 전이가 틀리거나 retry로 자원 파밍이 가능하면 PR 3을 시작하지 않는다.

## 11. 작업 트리 인계

- linked worktree: `마왕성_v20_spatial_model`
- 원본 `게임소스/`의 사용자 작업과 `참고자료/v20_p11r/`는 수정하지 않았다.
- 기능 커밋: `5d279b6b29db3b4efa620b91eba5bde4d1dd62b3`
- 이 문서 커밋 뒤 예상 상태: 원격 `codex/v20-validation-spatial-model`과 동기화, 미커밋 파일 0개
- build·capture·core report는 `tmp/` 또는 `user://`에만 있으며 커밋하지 않았다.
