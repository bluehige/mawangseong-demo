# v1.2.2 C1 접촉 피드백 동기화 핸드오프

## 목표 버전·브랜치·기준

- 목표 버전: `1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: 변경 후 미커밋

## 구현 완료

- `scripts/game/CombatSceneController.gd`
  - 일반 공격·투사체·돌진·광역 피해를 접촉 피드백 단일 입구로 통합
  - 피격 동작, 피해 숫자, 타격음, VFX를 동일 simulation 사건에서 시작
  - 중복 토큰 차단과 접촉 사건 기록 추가
  - 산성 장판·함정·베베 빗자루·돌콩 파동·루미 스킬·등껍질 돌진을 공통 입구로 이관
  - 공격 시작 시 직접 재생하던 베기·화염구 충돌음을 접촉 시점으로 이동
- `tools/tests/ContactFeedbackSyncTest.gd/.tscn`
  - 일반·투사체·돌진·광역과 x1·x2·x3 고정 사건 검증 23 assertions
- `tools/tests/core_verification_suite.json`
  - `contact_feedback_sync`를 quick/full에 등록

## Related tests

`ContactFeedbackSyncTest` 23/23, `CombatAudioDirectorRoutingTest` 9/9, `V122ContentCompatibilityTest` coverage 85/85·500 assertions, JSON 문법 검사를 PASS했다.

## UI check

실제 Windows 1280×720 3프레임 캡처는 실행하지 않았고, headless 런타임에서 접촉 이벤트 순서·종류·simulation 프레임을 확인했다.

## Unresolved issues

Godot 종료 시 기존과 같은 ObjectDB/resource leak 경고가 있으나 테스트 종료 코드는 0이다. 실제 x1·x2·x3 장시간 전투와 화면 캡처는 I1/최종 OWNER 검수에서 남아 있다.

## 다음 작업

V5 VFX catalog·런타임 연결을 시작한다. 커밋·푸시하지 않았으며 기존 작업 트리 변경은 그대로 보존한다.
