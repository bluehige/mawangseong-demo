# v1.2.2 출시 마무리 A1-D2 AudioDirector routing 재검증 핸드오프

목표 버전: `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
검수일: 2026-08-05
패킷: `A1-D2-AUDIO-DIRECTOR-ROUTING`
QA: `docs/qa/V122_A1_D2_AUDIO_DIRECTOR_ROUTING_REVALIDATION_2026-08-05.md`

## 완료 내용

선행 A1-D2 구현을 현재 런타임에서 다시 확인했다. GameRoot의 단일 AudioDirector가 Update 3 경보와 Update 4 스킬·왕관·경쟁 보스 사건을 catalog와 voice allocator를 통해 재생하며, 동일 instance token 중복 재생을 차단한다. 직접 라우팅 테스트 126개가 통과했다.

## 실제 변경 경로

- `docs/qa/V122_A1_D2_AUDIO_DIRECTOR_ROUTING_REVALIDATION_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_A1_D2_AUDIO_DIRECTOR_ROUTING_REVALIDATION_2026-08-05.md`
- `docs/handoff/CURRENT.md`

AudioDirector·GameRoot·catalog·SkillAudioPaletteTest와 기존 사용자/Luna 미커밋 변경은 수정하거나 되돌리지 않았다.

## 실행한 직접 테스트

- `SkillAudioPaletteTest.tscn` — 126/126 PASS

종료 시 4개 오디오 자원 teardown 경고가 있었지만 프로세스 종료 코드는 0이다. 경고는 별도 수명 정리 항목으로 남긴다.

## 코드·데이터·스토리·밸런스·그래픽·오디오

- 코드/데이터/스토리/밸런스/그래픽/오디오 자산: 변경 없음.
- CombatSceneController·MultiFloorHUD 직접 SFX 호출부 이관은 A1-D3에서 별도 처리한다.

## 미해결 문제와 다음 작업 순서

- AudioDirector의 테스트 종료 시 WAV/playback 자원 정리 경고가 남아 있다.
- 전투·HUD의 직접 AudioStreamPlayer 경로와 실제 소유자 청취는 미완료다.
- 다음 잠금 후보는 `A1-D3-COMBAT-HUD-AUDIO-ROUTING`이며 이번 turn에는 시작하지 않는다.

## 작업 트리 및 원격 상태

- 기존 사용자/Luna 미커밋 변경은 되돌리거나 정리하지 않았다.
- 커밋·푸시·빌드: 수행하지 않음.

## 정책 판정

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
