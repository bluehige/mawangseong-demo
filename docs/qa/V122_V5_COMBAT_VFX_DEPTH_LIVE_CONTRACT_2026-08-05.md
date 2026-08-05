# v1.2.2 V5 전투 VFX live depth·전면 벽 연결 검증

작성일: 2026-08-05
대상 버전: 제품 `1.2.2`
작업 브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 목표

고정 `-30/100/3000` z 값으로만 그리던 VFX를 현재 renderer의 유닛 depth 슬롯과 `wall_front` 경계에 연결했다. 이번 패킷은 VFX depth 연결 한 가지 결함만 다뤘다.

## 구현 내용

- `CombatSceneController._apply_vfx_profile()`에 live depth 적용 인자를 추가했다.
- 투사체·근접·피격·공통 burst 호출이 live depth 경로를 사용하도록 연결했다.
- `unit_fx`: renderer 유닛 슬롯을 사용한다.
- `aerial_fx`: 유닛 슬롯보다 위이고 `wall_front`보다 낮은 슬롯을 사용한다.
- `front_fx`: `wall_front + 1`로 그려 전면 벽 바로 위에 붙인다.
- `FxLayer` 부모 깊이를 빼서 상대 z로 계산하고, 계산된 전역/부모 depth를 메타데이터에 남긴다.
- renderer가 없는 독립 초기화에서는 기존 fallback z 값을 유지한다.

## 직접 테스트

실행:

```text
godot.cmd --headless --path . --script tools/tests/V122CombatVfxDepthLiveContractTest.gd --quit-after 30
```

결과:

```text
V122_COMBAT_VFX_DEPTH_LIVE_CONTRACT_TEST: PASS (21 assertions)
```

확인 항목:

- renderer 유닛 depth·`wall_front` API 연결
- 유닛 슬롯 `-40..44`와 전면 벽 경계 50의 순서
- 몸통·공중·전면 VFX의 전역 depth와 `FxLayer` 상대 z 일치
- 투사체·근접·피격·공통 burst 호출의 live depth 사용

## 대표 화면 확인

다음 장면을 Vulkan으로 1회 실행했다.

```text
godot.cmd --path . --scene tmp/v122_release_polish/i1_5_boss_final/I1BossFinalRepresentative.tscn --quit-after 600
```

- 1280×720 캡처 4개와 상태 단언 11개 생성: PASS
- UI와 회흑색 통로·벽 구조: 확인
- 현재 캡처에서도 중앙 캐릭터 몸체는 전면 벽에 대부분 묻혀 있으며, 보라색 `front_fx` ring은 벽 위에 분리되어 보인다.
- 따라서 live depth 계약 자체는 PASS지만, 캐릭터 표시·anchor 체감까지 포함한 시각 gate는 아직 닫지 않는다.

실행 종료 시 다음 경고가 남았다.

```text
WARNING: 1 RID of type "CanvasItem" was leaked.
WARNING: ObjectDB instances leaked at exit.
```

## 변경 경로

- `scripts/game/CombatSceneController.gd`
- `tools/tests/V122CombatVfxDepthLiveContractTest.gd`
- `docs/qa/V122_V5_COMBAT_VFX_DEPTH_LIVE_CONTRACT_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_V5_COMBAT_VFX_DEPTH_LIVE_CONTRACT_2026-08-05.md`
- `docs/handoff/CURRENT.md`

`data/v122/combat_vfx_catalog.json`, renderer, Unit, 오디오, 그래픽 자산은 변경하지 않았다.

## 판정과 다음 조치

`V5_DEPTH_LIVE_CONTRACT_PASS_SCREEN_PENDING` — VFX depth 연결과 전용 계약 테스트는 통과했지만, 대표 화면에서 캐릭터가 거의 보이지 않아 anchor·가림 체감 승인까지는 진행하지 않는다.

다음 후보는 `I1-5-ACTOR-VISIBILITY-DISCOVERY`다. 캐릭터가 벽에 묻히는 원인을 읽기 전용으로 분리 조사한 뒤에만 재검수한다.

Review task ID: `NOT_REQUESTED`
Reviewed SHA: `N/A`
Remaining P1/P2: `N/A`
Final review result: `TARGETED_PASS_WITH_SCREEN_PENDING`
