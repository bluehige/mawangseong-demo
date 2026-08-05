# v1.2.2 출시 마무리 A1-D3 전투·HUD AudioDirector routing 재검증 핸드오프

목표 버전: `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
검수일: 2026-08-05
패킷: `A1-D3-COMBAT-HUD-AUDIO-ROUTING`
QA: `docs/qa/V122_A1_D3_COMBAT_HUD_AUDIO_ROUTING_REVALIDATION_2026-08-05.md`

## 완료 내용

선행 A1-D3 구현을 현재 런타임에서 다시 확인했다. CombatSceneController의 타격·스킬음과 MultiFloorHUD의 층 경보가 공통 AudioDirector·catalog·voice allocator를 사용하고, cooldown·voice 교체·HUD 제거 시 정리가 유지된다. 직접 라우팅 테스트 9개가 통과했다.

## 실제 변경 경로

- `docs/qa/V122_A1_D3_COMBAT_HUD_AUDIO_ROUTING_REVALIDATION_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_A1_D3_COMBAT_HUD_AUDIO_ROUTING_REVALIDATION_2026-08-05.md`
- `docs/handoff/CURRENT.md`

CombatSceneController·MultiFloorHUD·AudioDirector·catalog·직접 테스트와 기존 사용자/Luna 미커밋 변경은 수정하거나 되돌리지 않았다.

## 실행한 직접 테스트

- `CombatAudioDirectorRoutingTest.tscn` — 9/9 PASS

종료 경고와 오류는 없었다.

## 코드·데이터·스토리·밸런스·그래픽·오디오

- 코드/데이터/스토리/밸런스/그래픽/오디오 자산: 변경 없음.
- 새 음원 생성·승격과 실제 소유자 청취는 별도 gate다.

## 미해결 문제와 다음 작업 순서

- 다음 잠금 후보는 `A1-E-AUDIO-SUITE-REGISTRATION`이며 이번 turn에는 시작하지 않는다.
- 이후 계획 순서에 C1 접촉 피드백 동기화가 남아 있다.

## 작업 트리 및 원격 상태

- 기존 사용자/Luna 미커밋 변경은 되돌리거나 정리하지 않았다.
- 커밋·푸시·빌드: 수행하지 않음.

## 정책 판정

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
