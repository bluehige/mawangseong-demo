# v1.2.2 V4-B UI 앵커 화면 재검수

- 작성일: 2026-08-05
- 대상 버전: 제품 `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 패킷: `V4-B-03-UI-ANCHOR-SCREEN-REVALIDATION`
- 범위: `foot/body/head` 공통 앵커의 대표 1280×720 화면 적용

## 목표

이름·HP·피해 숫자가 유닛 원점의 고정 오프셋이 아니라 공통 `head` 앵커를 따라가며, 캐릭터 몸체·벽·다른 UI와 겹치지 않는지 확인한다. 이번 패킷에서는 코드·데이터·자산을 수정하지 않는다.

## 직접 실행

### UI 앵커 계약

```text
godot.cmd --headless --path . --script tools/tests/V122V4BUIAnchorContractTest.gd --quit-after 30
V122_V4_B_UI_ANCHOR_CONTRACT_TEST: PASS (12 checks)
```

공통 발·몸·머리 기준점, 이름·HP의 `head` 소비, 포즈 갱신, 피해 숫자의 대상 `head` 전달과 기존 원점 고정 오프셋 제거를 확인했다.

### 대표 화면

보스 대표 화면에서 이름·HP·캐릭터와 벽의 관계를 확인했다.

```text
godot.cmd --path . --scene tmp/v122_release_polish/i1_5_boss_final/I1BossFinalRepresentative.tscn --quit-after 600
I1_5_BOSS_FINAL_REPRESENTATIVE: assertions=11, failures=0
CAPTURE: 1280x720 4 stages
```

피해 숫자가 실제로 발생하는 후반 전투 대표 화면도 같은 1280×720으로 보완 확인했다. 보스 장면에는 피해 숫자 이벤트가 없기 때문에, UI 앵커의 피해 숫자 소비는 이 장면으로 판정했다.

```text
godot.cmd --path . --scene tmp/v122_release_polish/i1_4_late_combat/I1LateCombatRepresentative.tscn --quit-after 600
I1_4_LATE_COMBAT_REPRESENTATIVE: assertions=13, failures=0
CAPTURE: 1280x720 5 stages
```

## 화면 판정

- 이름·HP: 보스·아군·일반 적의 이름과 HP 표시가 각 캐릭터 머리 위에 붙고 몸체 중심에서 크게 밀리지 않는다.
- 피해 숫자: 기본 공격과 화염구 적중 캡처에서 `-17`, `-52` 등의 피해 숫자가 대상 머리 위에서 시작하며 바닥이나 벽 원점에 뜨지 않는다.
- 겹침: 피해 숫자·이름·HP가 캐릭터 몸체를 통째로 덮거나 구조 벽 뒤로 밀리지 않는다. 전투 정보 패널은 우측 고정 영역에서 분리되어 있다.
- 크기 차이: 슬라임·고블린·임프·탐험가·조사관·기술자처럼 체격이 다른 유닛도 동일한 머리 기준을 사용한다.

## 판정

`V4_B_UI_ANCHOR_SCREEN_REVALIDATION_PASS`.

공통 UI 앵커 계약과 실제 1280×720 전투 화면을 함께 통과했다. 정식 출시 승인 SHA·전체 회귀·빌드는 아직 진행하지 않았다.

## 정책 상태

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
