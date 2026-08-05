# v1.2.2 V4-B UI 앵커 계약 검수

검수일: 2026-08-05
대상 브랜치: `codex/v122-ui-simplification`
기준 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 범위

이번 패킷은 유닛의 공통 `foot/body/head` 기준점을 만들고 이름·HP·피해 숫자가 같은 `head` 기준을 읽도록 연결하는 작업만 다뤘다. 전면 벽 렌더러, VFX ID, 오디오, 그래픽 자산은 수정하지 않았다.

## 변경 내용

- `scripts/units/Unit.gd`
  - `combat_anchor_local()`과 `combat_anchor_global()`로 발·몸·머리 기준점을 제공한다.
  - 프로필의 몸체 위치와 프레임 높이를 사용해 머리 기준점을 계산한다.
  - 유닛 이름과 HP 막대가 머리 기준점에서 배치되고, 포즈 갱신 때마다 다시 계산된다.
  - `debug_ui_anchor_contract()`로 소비자별 기준점 계약을 확인할 수 있다.
- `scripts/game/CombatSceneController.gd`
  - 접촉 피드백이 대상 유닛을 피해 숫자 생성기에 전달한다.
  - 피해 숫자는 대상의 `head` 전역 기준점에서 시작하며 기존 유닛 원점 고정 `-112` 오프셋을 제거했다.
- `tools/tests/V122V4BUIAnchorContractTest.gd`
  - 위 계약과 소비 경로를 읽기 전용으로 확인하는 12개 정적 검사를 추가했다.

## 직접 검수

```text
godot.cmd --headless --path . --check-only --quit
PASS

godot.cmd --headless --path . --script tools/tests/V122V4BUIAnchorContractTest.gd --quit-after 30
V122_V4_B_UI_ANCHOR_CONTRACT_TEST: PASS (12 checks)
```

실제 화면 캡처·전체 회귀·빌드는 이번 패킷 범위가 아니므로 실행하지 않았다. 이 결과는 코드 계약과 직접 정적 검사에 대한 `TARGETED_PASS`이며, 전면 벽 가림과 실제 1280×720 화면 검수까지 완료했다는 뜻은 아니다.

## 미해결 및 다음 순서

- Unit·전면 벽·VFX가 실제 화면에서 함께 가려지는지 확인하는 V5 전제는 남아 있다.
- 공통 UI 앵커는 완료했지만 이름/HP/피해 숫자의 시각적 간격은 대표 화면 확인에서 조정할 수 있다.
- 정식 순서상 다음 패킷은 선행 미커밋 구현을 승인으로 승격하지 않고 다시 확인하는 `A0-AUDIO-MANIFEST-CONTRACT`다.

## 정책 판정

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
