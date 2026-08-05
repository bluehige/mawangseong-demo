# v1.2.2 C1 접촉 피드백 동기화 재검증

검수일: 2026-08-05
대상 브랜치: `codex/v122-ui-simplification`
기준 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 범위

일반 공격·투사체·돌진·광역 피해의 접촉 시점에 피해, 피격 동작, 피해 숫자, 타격음, VFX가 하나의 사건으로 기록되는지 재검증했다. 배속에 따른 피해량·simulation frame 불변성과 중복 사건 방지도 직접 확인했다. 이번 패킷에서는 V5 VFX catalog, 새 음원, 전체 회귀·빌드는 실행하지 않았다.

## 검증 결과

```text
godot.cmd --headless --path . --scene tools/tests/ContactFeedbackSyncTest.tscn --quit-after 1800
CONTACT_FEEDBACK_SYNC_TEST: PASS (23 assertions)
```

확인한 조건:

- 일반 공격·투사체·돌진·광역이 각각 하나의 접촉 event로 기록된다.
- event에 접촉 종류, 피해량, 대상 HP, 다섯 피드백 채널이 함께 남는다.
- 다섯 채널 순서는 `damage → hit_reaction → damage_number → audio → vfx`로 고정된다.
- x1·x2·x3 배속에서도 고정 피해량과 동일 simulation frame을 유지한다.
- 접촉 token과 사건 배열을 초기화한 뒤에도 중복 없는 단일 사건이 생성된다.

## 미해결 및 판정 경계

이번 직접 테스트에서는 실패·오류·teardown 경고가 없었다. 실제 Windows 1280×720 화면 캡처, x1·x2·x3 장시간 플레이와 소유자 체감은 별도 검수다. V5 VFX catalog 연결은 다음 순서다.

## 실제 변경 경로

- `docs/qa/V122_C1_CONTACT_FEEDBACK_SYNC_REVALIDATION_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_C1_CONTACT_FEEDBACK_SYNC_REVALIDATION_2026-08-05.md`
- `docs/handoff/CURRENT.md`

CombatSceneController, ContactFeedbackSyncTest, suite JSON와 오디오·VFX 자산은 재검증만 수행하고 수정하지 않았다.

## 정책 판정

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
