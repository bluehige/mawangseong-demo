# V1.2.2 Q1-I 입력·IME 상세 감사 핸드오프

## 1. 기본 정보

- 목표 버전: 제품 `1.2.2`
- 작업 패킷: `Q1-I 입력·IME`
- 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (이번 패킷은 커밋하지 않음)
- PR·푸시: 없음

## 2. 완료 내용

입력 소유권과 화면 방향 계약을 코드에서 추적하고, Stage 10·관리·전투·결과 UI·출시 준비 자동 계약과 `--mobile-touch-ui` 합성 입력 재현을 실행했다. 이름 `LineEdit`은 포커스 중 GameRoot 전역 키 처리를 받지 않으며, 물리 키 바인딩은 `physical_keycode`를 유지한다. 세로 터치 화면에서는 포인터를 막는 회전 안내가 나타나고 가로 전환 뒤 해제된다.

자동·합성 검수에서는 런타임 결함을 찾지 못했지만, 실제 Windows 한/영 IME와 실제 모바일 기기 검수는 실행 환경에 없어 `OWNER_QA_PENDING`으로 남겼다. 입력 기능이나 자산은 변경하지 않았다.

## 3. 산출물과 변경 파일

- `docs/qa/V122_Q1I_INPUT_IME_AUDIT_2026-08-02.md`
- `docs/handoff/V122_RELEASE_POLISH_Q1I_INPUT_IME_AUDIT_2026-08-02.md`
- `tmp/v122_release_polish/q1_i/q1_i_inventory.json`
- `tmp/v122_release_polish/q1_i/q1_i_inventory.tsv`
- `tmp/v122_release_polish/q1_i/*.log`
- `tmp/v122_release_polish/q1_i/Q1IInputImeRepro.gd`
- `tmp/v122_release_polish/q1_i/Q1IInputImeRepro.tscn`
- `docs/plans/V122_RELEASE_POLISH_LUNA_EXECUTION_PLAN_2026-08-02.md` 및 `docs/handoff/CURRENT.md`는 아래 순서 갱신에 포함한다.

임시 재현기와 로그는 `tmp/` 아래에만 두며 소스 브랜치에 커밋하지 않는다. 기존 사용자의 `.png.import` 6개와 `.uid` 7개 변경은 건드리지 않았다.

## 4. 검수

| 항목 | 결과 |
|---|---|
| Stage 10 현지화·이름 입력 | PASS (41 PASS 줄) |
| 관리 UI 입력·방향 계약 | PASS |
| 전투 UI 입력·방향 계약 | PASS (85 assertions) |
| 결과 UI 방향 계약 | PASS |
| 출시 준비·Mobile Web landscape preset | PASS (84 assertions) |
| 합성 touch/IME 경계 재현 | PASS (12 assertions) |
| 실제 Windows IME | 미실행 — 소유자 검수 필요 |
| 실제 모바일 브라우저/기기 | 미실행 — 소유자 검수 필요 |

## 5. 다음 작업

1. 사용자가 Windows 후보에서 한/영 조합 확정, 조합 중 Backspace, 커서 수정, Enter 제출과 이름 등록 뒤 화면 전환을 수행한다.
2. 사용자가 Mobile Web 또는 터치 장치에서 세로 회전 안내·가로 해제·관리/전투/결과 대표 탭을 확인한다.
3. 물리 검수 전까지 Q1-I 상태는 `OWNER_QA_PENDING`으로 유지한다.
4. 계획 순서에 따라 다음 패킷 `Q1-L UI·현지화·placeholder 상세 감사`를 시작한다.

## 6. 정책 고정 필드

Related tests: `V122Stage10LocalizationTest` PASS, `V122ManagementUIContractTest` PASS, `V122CombatUISimplificationTest` PASS(85), `V122CombatResultUIContractTest` PASS, `V122ReleaseReadinessTest` PASS(84), `Q1IInputImeRepro` PASS(12)
UI check: headless touch 모드에서 세로 회전 안내·입력 차단과 가로 해제를 확인했으며 실제 장치 화면은 미검수
Unresolved issues: Windows 물리 한/영 IME·Backspace·Enter 제출, 실제 모바일 회전·탭, 사용자 최종 입력 체크리스트

## 7. 범위 경계

- 코드·데이터·그래픽·오디오 변경: 0
- 빌드·export: 실행하지 않음
- Full 회귀·전체 플레이·별도 검수 에이전트: 실행하지 않음
- 커밋·푸시: 실행하지 않음
