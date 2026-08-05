# v1.2.2 출시 마무리 C1 접촉 피드백 동기화 재검증 핸드오프

목표 버전: `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
검수일: 2026-08-05
패킷: `C1-CONTACT-FEEDBACK-SYNC`
QA: `docs/qa/V122_C1_CONTACT_FEEDBACK_SYNC_REVALIDATION_2026-08-05.md`

## 완료 내용

선행 C1 구현을 현재 런타임에서 다시 확인했다. 일반 공격·투사체·돌진·광역 피해가 접촉 시점에 피해·피격·피해 숫자·오디오·VFX를 하나의 사건으로 기록하며, 다섯 채널 순서와 배속 불변성이 유지된다. 직접 테스트 23개가 통과했다.

## 실제 변경 경로

- `docs/qa/V122_C1_CONTACT_FEEDBACK_SYNC_REVALIDATION_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_C1_CONTACT_FEEDBACK_SYNC_REVALIDATION_2026-08-05.md`
- `docs/handoff/CURRENT.md`

CombatSceneController·ContactFeedbackSyncTest·suite JSON와 기존 사용자/Luna 미커밋 변경은 수정하거나 되돌리지 않았다.

## 실행한 직접 테스트

- `ContactFeedbackSyncTest.tscn` — 23/23 PASS

종료 오류와 resource teardown 경고는 없었다.

## 코드·데이터·스토리·밸런스·그래픽·오디오

- 코드/데이터/스토리/밸런스/그래픽/오디오 자산: 변경 없음.
- 실제 화면 캡처와 장시간 배속 플레이는 OWNER 검수로 남겼다.

## 미해결 문제와 다음 작업 순서

- 다음 잠금 후보는 `V5-COMBAT-VFX-CATALOG`이며 이번 turn에는 시작하지 않는다.
- 실제 Windows 1280×720 화면과 x1·x2·x3 장시간 플레이는 별도 검수다.

## 작업 트리 및 원격 상태

- 기존 사용자/Luna 미커밋 변경은 되돌리거나 정리하지 않았다.
- 커밋·푸시·빌드: 수행하지 않음.

## 정책 판정

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
