# v1.2.2 A1-D3 전투·HUD AudioDirector routing 재검증

검수일: 2026-08-05
대상 브랜치: `codex/v122-ui-simplification`
기준 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 범위

CombatSceneController의 일반 타격·스킬 효과음과 MultiFloorHUD의 층 경보가 GameRoot의 공통 AudioDirector·catalog·voice allocator를 사용하는지 현재 런타임에서 재검증했다. 이번 패킷에서는 새 음원 생성·승격, A1-E suite 등록, C1 접촉 동기화, 전체 회귀·빌드는 실행하지 않았다.

## 검증 결과

```text
godot.cmd --headless --path . --scene tools/tests/CombatAudioDirectorRoutingTest.tscn --quit-after 1800
COMBAT_AUDIO_DIRECTOR_ROUTING_TEST: PASS (9 assertions)
```

확인한 동작:

- GameRoot가 전투와 HUD에 공통 AudioDirector를 제공한다.
- 전투 타격음이 catalog voice 경로를 사용하고, 짧은 cooldown 동안 같은 타격이 중복되지 않는다.
- 전투 스킬음이 catalog event를 통해 정확히 한 voice를 만든다.
- 숨은 층 경보가 공통 catalog voice 경로를 사용한다.
- 같은 HUD 경보 반복은 기존 voice를 교체해 stacking을 막는다.
- HUD가 제거될 때 자신의 alert voice만 해제한다.

## 미해결 및 판정 경계

이번 직접 테스트에서는 실패·오류·자원 teardown 경고가 없었다. 실제 소유자 청취와 새 음원 승격은 별도 gate다. A1-E suite 등록과 C1 접촉 피드백 동기화는 다음 순서다.

## 실제 변경 경로

- `docs/qa/V122_A1_D3_COMBAT_HUD_AUDIO_ROUTING_REVALIDATION_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_A1_D3_COMBAT_HUD_AUDIO_ROUTING_REVALIDATION_2026-08-05.md`
- `docs/handoff/CURRENT.md`

CombatSceneController, MultiFloorHUD, AudioDirector, catalog와 직접 테스트는 재검증만 수행하고 수정하지 않았다.

## 정책 판정

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
