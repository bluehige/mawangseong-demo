# V1.2.2 Q1-I 입력·IME 상세 감사

작성일: 2026-08-02
대상 버전: 제품 `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 감사 목적과 범위

Q1-I는 새 입력 기능을 추가하는 단계가 아니라, 현재 구현이 텍스트 입력·전역 단축키·화면 전환·터치·가로 화면에서 어떤 소유권을 갖는지 확인하는 단계다. 실제 Windows 후보와 모바일 기기가 아직 제공되지 않았으므로, 코드 계약과 headless 합성 입력만 확인하고 물리 장치 검수는 `OWNER_QA_PENDING`으로 남겼다. 런타임 코드·데이터·그래픽·오디오·빌드는 수정하지 않았다.

기계 판독 결과는 [Q1-I 인벤토리 JSON](../../tmp/v122_release_polish/q1_i/q1_i_inventory.json)과 [Q1-I 인벤토리 TSV](../../tmp/v122_release_polish/q1_i/q1_i_inventory.tsv)다.

## 현재 입력 계약

### 1. 이름 입력과 IME

- `scripts/game/GameRoot.gd:1250`의 `_input`은 포커스 소유자가 `LineEdit` 또는 `TextEdit`이면 즉시 반환한다(`_text_input_owns_keyboard`, 1350행). 따라서 한글 조합, 조합 중 Backspace, 커서 이동, Enter 확정은 전역 게임 단축키가 아니라 Godot 텍스트 컨트롤이 처리한다.
- 이름 화면은 `LineEdit`을 만들고 `text_submitted`를 `_onboarding_name_submitted`에 연결한다(`GameRoot.gd:4844`, `6327`). 제출 시 양 끝 공백을 제거하고 빈 문자열과 12자 초과를 검사한다(`GameRoot.gd:6330`).
- `max_length = 0`으로 두어 조합 중 입력을 잘라내지 않고, 확정 시점의 제품 규칙으로 12자를 판정한다. 자동 검사는 영어 이름·빈 이름·13자 입력과 화면 구성까지 통과했다.

### 2. 한/영 전환과 전역 단축키

- `scripts/core/InputSettings.gd:39`의 기본 조작은 `physical_keycode`로 저장한다.
- `event_matches`는 `InputMap.event_is_action`을 사용하고, 저장 시 물리 키를 우선한다(`InputSettings.gd:75`, `190`, `213`). 그래서 한글 자판의 표시 문자보다 실제 키 위치를 기준으로 전투 단축키를 비교한다.
- 포커스된 이름 `LineEdit`에서 합성 Backspace를 GameRoot에 직접 전달해도 화면 전환이나 전역 명령이 발생하지 않는지 확인했다. 실제 GUI 삭제는 LineEdit이 담당하므로 합성 테스트에서는 문자열이 보존되는 것이 정상이다.

### 3. 터치와 세로 화면 차단

- `UISettings.is_touch_ui`는 모바일 feature, 터치스크린, `--mobile-touch-ui`를 모두 인식한다(`scripts/core/UISettings.gd:27`, `132`).
- `GameRoot._refresh_touch_orientation_notice`(`GameRoot.gd:3963`)는 세로 화면에서 회전 안내를 만들고 `mouse_filter = STOP`으로 둔다. 안내가 존재하는 동안 `_touch_orientation_notice_blocks_pointer`(`GameRoot.gd:1340`)가 터치·드래그·마우스 입력을 차단한다.
- `390×844` 합성 세로 화면에서는 안내와 차단이 생겼고, `844×390` 가로 화면에서는 안내가 제거되고 포인터가 풀렸다. 가로 전환 뒤 관리 화면으로 이동하는 것도 통과했다.

## 대상 테스트 결과

| 테스트 | 결과 | 확인 내용 | 증거 |
|---|---|---|---|
| `V122Stage10LocalizationTest` | PASS | 41개 PASS 줄; 이름 `LineEdit`, 빈 이름·13자 검증, 설정·튜토리얼 locale 전환 | `tmp/v122_release_polish/q1_i/q1_i_stage10_localization.log` |
| `V122ManagementUIContractTest` | PASS | 데스크톱·Compact·가로 모바일 배치, 세로 회전 안내 | `tmp/v122_release_polish/q1_i/q1_i_management_ui_contract.log` |
| `V122CombatUISimplificationTest` | PASS | 85 assertions; 전투 명령 대상과 가로 화면 입력 영역 | `tmp/v122_release_polish/q1_i/q1_i_combat_ui_contract.log` |
| `V122CombatResultUIContractTest` | PASS | 결과 화면 가로 영역과 세로 회전 안내 | `tmp/v122_release_polish/q1_i/q1_i_combat_result_ui_contract.log` |
| `V122ReleaseReadinessTest` | PASS | 84 assertions; Mobile Web landscape 설정과 4개 preset | `tmp/v122_release_polish/q1_i/q1_i_release_readiness.log` |
| `Q1IInputImeRepro` | PASS | 12 assertions; touch 인자, LineEdit 키보드 소유권, Backspace 격리, 물리 H, 세로 차단·가로 해제, 이름→관리 전환 | `tmp/v122_release_polish/q1_i/q1_i_input_ime_repro.log` |

Godot headless 실행에서 ObjectDB 리소스 정리 경고가 한 번 출력됐지만 테스트 종료 코드는 0이고 입력 판정과 무관하다. 전체 회귀·전체 플레이·실제 모바일 브라우저는 실행하지 않았다.

## 발견 사항과 출시 경계

1. 자동·합성 범위에서는 P0/P1/P2 런타임 결함을 재현하지 못했다. 텍스트 입력 소유권과 물리 키 매칭, 세로 차단·가로 해제 계약은 PASS다.
2. **`Q1-I-OWNER-01` — `OWNER_QA_PENDING`, RELEASE_GATE:** 실제 Windows 후보에서 한국어 조합 확정, 조합 중 Backspace·커서 이동, 한/영 전환 뒤 전역 단축키 차단을 아직 확인하지 않았다.
3. **`Q1-I-OWNER-02` — `OWNER_QA_PENDING`, RELEASE_GATE:** 실제 Mobile Web/Android/iOS에서 회전 이벤트, 손가락 탭, 관리·전투·결과 화면 전환을 아직 확인하지 않았다.
4. 현재 코드에서 story 입력 분기 아래의 도달 불가능한 포인터 보조 분기는 동작 결함으로 재현되지 않았다. 이번 감사에서는 범위를 넓혀 정리하지 않는다.

따라서 Q1-I의 자동 결과는 `TARGETED_PASS_WITH_OWNER_QA_PENDING`이며, 물리 장치 검수 전에는 출시 완료나 후보 빌드 승인을 표시하지 않는다. 다음 순서는 계획표대로 Q1-L UI·현지화·placeholder 감사다.

## 범위 밖 작업

- Windows 후보 export·실행·커밋·푸시
- 실제 IME 장치와 Mobile Web/Android/iOS 조작
- 입력 동작 변경, 키 바인딩 변경, UI 자산 변경
- Full 회귀와 전체 DAY 1~30 플레이

Related tests: `V122Stage10LocalizationTest` PASS, `V122ManagementUIContractTest` PASS, `V122CombatUISimplificationTest` PASS(85), `V122CombatResultUIContractTest` PASS, `V122ReleaseReadinessTest` PASS(84), `Q1IInputImeRepro` PASS(12)
UI check: `--mobile-touch-ui` headless 합성에서 `390×844` 회전 안내·포인터 차단과 `844×390` 해제를 확인했으며 실제 장치 화면은 미검수
Unresolved issues: Windows 물리 한/영 IME·Backspace·Enter 제출, 실제 모바일 회전·탭, 사용자 최종 입력 체크리스트
