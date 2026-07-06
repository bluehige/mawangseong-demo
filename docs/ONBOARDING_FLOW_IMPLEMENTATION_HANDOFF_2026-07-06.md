# 온보딩 플로우 구현 핸드오프 (2026-07-06)

## 구현 범위

- 기준 엔진: Godot 4.5 / GDScript.
- 기준 데이터: `res://참고자료/onboarding_flow_dialogue_v0.4.json`.
- 연결 흐름:
  - 게임 실행 -> 타이틀
  - 새 게임 -> 마왕명 입력
  - 이름 확정 -> 오프닝 대사
  - DAY 01 관리/전투/결산
  - DAY 02 관리/전투/결산
  - DAY 03 관리/전투/결산
  - DAY 04 악명 원정 예고 화면

## 주요 파일

- `scripts/systems/tutorial/OnboardingFlow.gd`
  - JSON 로더.
  - `screens`의 1920x1080 Rect 조회.
  - `dialogue`의 `stage` + `trigger` 필터링.
- `scripts/systems/tutorial/TutorialManager.gd`
  - `tutorial_steps` 상태 머신.
  - `block_until` -> action id 매핑.
  - focus별 payload 검증.
  - 현재 단계의 입력 허용 여부 판단.
- `scripts/game/GameRoot.gd`
  - 온보딩 화면 빌드와 stage 전환의 중심.
  - 타이틀/이름 입력/DialogueScreen/DAY04 예고 화면 추가.
  - 전투 trigger를 BattleHUD 로그 또는 DialogueScreen으로 라우팅.
  - 튜토리얼 포커스 오버레이와 핵심 입력 게이트 연결.
- `scripts/game/CombatSceneController.gd`
  - 적 등장, 함정 발동, 보물 도난, 유닛 피해, 전투 종료 이벤트를 `GameRoot` 온보딩 훅으로 통지.
  - 고블린 공격 1회 등 전투 중 튜토리얼 action 통지.
- `scripts/game/ManagementSceneController.gd`
  - 결산 화면의 후속 버튼을 `_continue_from_result()`로 연결.
  - 결산 UI는 JSON `S05_RESULT` Rect를 사용.
- `scripts/ui/HUDController.gd`
  - HUD 생성 helper(`panel`, `label`, `button`)가 optional tutorial target id를 받는다.
  - 버튼/패널 생성 직후 `GameRoot.register_tutorial_target_control()`로 실제 화면 Rect를 등록한다.
- `tools/OnboardingFlowSmokeTest.gd`
  - 타이틀부터 DAY04 예고까지 자동 연결 검증.
- `tools/TutorialFlowSmokeTest.gd`
  - `tutorial_steps.block_until` 게이트와 단계 전환 검증.

## Screen Rect 적용 상태

JSON `screens`의 1920x1080 좌표를 사용한 화면:

- `S00_TITLE`: 타이틀 메뉴.
- `S01_NAME_ENTRY`: 이름 입력 폼.
- `S02_DIALOGUE`: DialogueScreen.
- `S05_RESULT`: 결산 화면.
- `S06_RAID_PREVIEW`: DAY04 악명 원정 예고.

기존 관리/전투 UI(`S03_MANAGEMENT`, `S04_BATTLE`)는 기존 HUD/맵 렌더러를 유지한다. 단, 온보딩 대사는 stage/trigger 기준으로 연결되어 있다.

## Dialogue 출력 규칙

- 비전투 화면:
  - `DialogueScreen`으로 출력.
  - 이름 입력 검증 대사는 이름 입력 화면의 바티 코멘트 영역에 출력.
- 전투 화면:
  - BattleHUD 로그로 출력.
  - 로그 포맷: `화자: 대사`.
- `{{player_name}}`은 `GameState.player_name`으로 치환.
- 이미 출력된 dialogue id는 중복 출력하지 않는다.

## Tutorial Step / Gate 규칙

- `SignalBus.tutorial_action(action_id, payload)`을 사용한다.
- `TutorialManager`가 현재 `tutorial_steps` index를 소유한다.
- 현재 stage와 tutorial step stage가 일치할 때만 overlay와 gate가 활성화된다.
- 모든 입력을 막지는 않는다. 다음 행동을 건너뛰게 만드는 핵심 액션만 막는다.
  - 전투 시작
  - 날짜 진행
  - 몬스터 배치
  - 전체 지침 변경
  - 방 지침 변경
  - 직접 조종
  - 스킬 사용
- 방 선택, 화면 확인, 로그 표시 같은 탐색성 행동은 가능한 한 허용한다.
- 포커스 overlay는 기존 HUD 위에 `TutorialOverlay` 패널로 그린다.
- `DialogueScreen` 위에는 overlay를 띄우지 않는다. 해당 단계는 `dialogue_closed` action으로 처리한다.

## Tutorial Focus Target 규칙

- `GameRoot.tutorial_targets`는 현재 화면의 focus id -> `Rect2` 등록 테이블이다.
- `_set_screen()`마다 `tutorial_targets.clear()` 후 해당 화면 UI 빌드 과정에서 다시 등록한다.
- `_tutorial_focus_rect()`는 등록된 target id를 먼저 사용하고, 없을 때만 fallback 계산을 사용한다.
- UI 컨트롤 기반 focus는 가능한 한 `HUDController` helper 호출에 target id를 넘겨 등록한다.
  - 예: `NameInput`, `BossHpBar`, `BattleLogPanel`, `GLOBAL_DIRECTIVE_DEFEND`, `ROOM_DIRECTIVE_*`, `DirectControlButton`, `NextDayButton`.
- 맵/전투 위치 기반 focus는 실제 던전 그래프와 유닛 위치가 필요하므로 계산식을 유지한다.
  - 예: `ROOM_THRONE`, `ROOM_ENTRANCE`, `ROOM_TREASURE`, `ROOM_RECOVERY_NEST`, 전투 중 `CHR_*`.
- 몬스터 관리 화면의 리스트 버튼은 `CHR_PUDDING`, `CHR_GOB`, `CHR_PYNN` target id로 등록한다.

현재 연결된 `block_until`:

- `name_valid`
- `dialogue_closed`
- `unit_selected`
- `unit_deployed`
- `global_directive_set`
- `room_directive_set`
- `direct_control_once`
- `log_event_seen`
- `room_selected`
- `goblin_attacks_once`
- `imp_casts_fireball`
- `boss_hp_50`

## Stage 전환 규칙

- `LV00_TITLE_BOOT`: 게임 실행 타이틀.
- `LV01_NAME_ENTRY`: 새 게임 후 이름 입력.
- `LV02_OPENING_CUTSCENE`: 이름 확정 후 오프닝 대사.
- `LV03_DAY01_MANAGEMENT_TUTORIAL`: DAY 01 관리.
- `LV04_DAY01_BATTLE_EXPLORER`: DAY 01 전투.
- `LV05_DAY01_RESULT`: DAY 01 결산.
- `LV06_DAY02_MANAGEMENT_TREASURE`: DAY 02 관리.
- `LV07_DAY02_BATTLE_THIEF`: DAY 02 전투.
- `LV08_DAY02_RESULT`: DAY 02 결산.
- `LV09_DAY03_MANAGEMENT_HERO`: DAY 03 관리.
- `LV10_DAY03_BATTLE_HERO`: DAY 03 전투.
- `LV11_DAY03_RESULT_DEMO_CLEAR`: DAY 03 결산/데모 클리어.
- `LV12_DAY04_RAID_PREVIEW`: DAY 04 악명 원정 예고.

## 연결된 주요 Trigger

- 이름 입력: `screen_open`, `invalid_empty`, `invalid_too_long`, `confirm_name`.
- 오프닝: `opening_start`, `after_narration`, `after_player`, `after_bati`, `goldin_intro`, `throne_reveal`, `opening_end`.
- 관리: `management_open`, `enemy_preview`, `recovery_nest_unlock`, `select_slime`, `select_goblin`, `select_imp`, `global_directive_defend`, `room_directive_block`, `survival_priority`, `retreat_line`.
- 전투: `direct_control_prompt`, `direct_control_start`, `enemy_spawn`, `boss_spawn`, `trap_triggered`, `treasure_stolen`, `low_hp`, `boss_hp_75`, `boss_hp_50`, `boss_hp_25`, `imp_fireball`, `unit_retreat`, `slime_low_hp_retreat`.
- 결산/예고: `win`, `win_no_treasure_loss`, `lose`, `raid_preview_open`.

## 테스트

실행한 테스트:

```powershell
godot --headless --path . --run res://tools/OnboardingFlowSmokeTest.tscn
godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --headless --path . --run res://tools/RoomPathAuthoringProbe.tscn
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/RoleCombatLayoutProbe.tscn
git diff --check -- scripts/core/Constants.gd scripts/core/GameState.gd scripts/systems/tutorial/OnboardingFlow.gd scripts/game/GameRoot.gd scripts/game/CombatSceneController.gd scripts/game/ManagementSceneController.gd tools/OnboardingFlowSmokeTest.gd tools/OnboardingFlowSmokeTest.tscn tools/DemoSmokeTest.gd tools/QuarterModuleSmokeTest.gd tools/RoomPathAuthoringProbe.gd tools/RoleCombatLayoutProbe.gd tools/BalanceSimulation.gd tools/ManualVerificationCapture.gd tools/RoleCombatLayoutCapture.gd
```

## 남은 작업

- `tutorial_steps.block_until`의 1차 하드 게이트와 포커스 하이라이트는 구현됐다.
- HUD/온보딩 UI의 주요 focus는 stable target id 등록 방식으로 고도화했다.
- 아직 남은 fallback 좌표는 대부분 맵/전투처럼 실제 그래프/유닛 위치 계산이 필요한 항목이다. 새 UI 버튼을 추가하면 하드코딩 좌표를 늘리지 말고 target id 등록을 우선 사용해야 한다.
- 현재 입력 게이트는 핵심 액션만 막는다. 더 강한 튜토리얼을 원하면 `allowed_actions`를 JSON에 추가해 단계별 허용 목록을 데이터화해야 한다.
- 관리/전투 기본 HUD는 기존 레이아웃을 유지한다. JSON `S03_MANAGEMENT`, `S04_BATTLE`을 완전 적용하려면 기존 HUDController 레이아웃 재배치가 별도 작업이다.
- 저장/이어하기와 옵션 화면은 아직 실제 기능에 연결하지 않았다.
