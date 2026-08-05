# v1.2.2 출시 마무리 A1-D1 voice allocator·catalog 재검증 핸드오프

목표 버전: `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
검수일: 2026-08-05
패킷: `A1-D1-AUDIO-VOICE-ALLOCATOR`
QA: `docs/qa/V122_A1_D1_AUDIO_VOICE_ALLOCATOR_REVALIDATION_2026-08-05.md`

## 완료 내용

선행 A1-D1 구현을 현재 런타임에서 다시 확인했다. 전역·분류·event별 voice 상한, 중요도에 따른 오래된 낮은 우선순위 축출, 보호된 voice 거부와 해제 동작이 유지된다. catalog API는 연결된 event·runtime asset을 해석하고 미등록 ID를 진단과 함께 차단한다.

## 실제 변경 경로

- `docs/qa/V122_A1_D1_AUDIO_VOICE_ALLOCATOR_REVALIDATION_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_A1_D1_AUDIO_VOICE_ALLOCATOR_REVALIDATION_2026-08-05.md`
- `docs/handoff/CURRENT.md`

`scripts/audio/AudioVoiceAllocator.gd`, `scripts/audio/AudioCatalogApi.gd`, `tools/tests/AudioVoiceAllocatorTest.gd/.tscn`은 수정하지 않았다. 기존 사용자/Luna 미커밋 변경도 보존했다.

## 실행한 직접 테스트

- `AudioVoiceAllocatorTest.tscn` — 55/55 PASS

미등록 ID 진단 로그는 테스트가 의도적으로 확인하는 기대 출력이다. 프로세스 종료 코드는 0이다.

## 코드·데이터·스토리·밸런스·그래픽·오디오

- 코드/데이터/스토리/밸런스/그래픽/오디오 자산: 변경 없음.
- allocator·catalog의 실제 호출부 이관은 다음 A1-D2/A1-D3 패킷으로 분리한다.

## 미해결 문제와 다음 작업 순서

- GameRoot·전투·HUD가 아직 공통 allocator를 통해 실제 AudioStreamPlayer를 만들지는 않는다.
- 실제 소유자 청취와 새 음원 승격은 별도 gate다.
- 다음 잠금 후보는 `A1-D2-AUDIO-DIRECTOR-ROUTING`이며 이번 turn에는 시작하지 않는다.

## 작업 트리 및 원격 상태

- 기존 사용자/Luna 미커밋 변경은 되돌리거나 정리하지 않았다.
- 커밋·푸시·빌드: 수행하지 않음.

## 정책 판정

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
