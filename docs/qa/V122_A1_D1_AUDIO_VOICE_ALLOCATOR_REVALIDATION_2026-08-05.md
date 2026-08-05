# v1.2.2 A1-D1 효과음 voice allocator·catalog API 재검증

검수일: 2026-08-05
대상 브랜치: `codex/v122-ui-simplification`
기준 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 범위

현재 런타임에서 일회성 효과음 동시 재생 상한, 중요도 기반 축출·보호, voice 해제, event·asset catalog 해석을 다시 확인했다. 이번 패킷에서는 실제 호출부 이관, AudioDirector routing, 새 음원 생성·승격, 전체 회귀·빌드는 실행하지 않았다.

## 검증 결과

```text
godot.cmd --headless --path . --scene tools/tests/AudioVoiceAllocatorTest.tscn --quit-after 600
AUDIO_VOICE_ALLOCATOR_TEST: PASS (55 assertions)
```

확인한 조건:

- 전역 일회성 voice 24개 상한을 지킨다.
- 일반 event 4개, UI 2개, 발소리 3개의 그룹·분류별 상한을 지킨다.
- 상한에서 요청보다 낮은 우선순위 중 가장 오래된 voice만 축출한다.
- 같은 우선순위의 보호된 voice만 남으면 새 요청을 거부한다.
- voice release와 active 수 감소가 정상 동작한다.
- 등록된 관리 BGM event와 실제 runtime SFX·Update 4 asset을 해석한다.
- 미등록 event·asset은 빈 결과와 `AUDIO_CATALOG_MISSING_*` 진단으로 차단하며 조용한 폴백을 만들지 않는다.

## 미해결 및 판정 경계

테스트는 미등록 ID를 의도적으로 조회하므로 Godot 출력에 두 개의 `AUDIO_CATALOG_MISSING_*` 오류 로그가 표시된다. 이는 실패가 아니라 진단 경로를 확인하는 기대 출력이며 프로세스 종료 코드 0, 55개 단언은 통과했다. 현재 GameRoot·전투·HUD의 실제 SFX 호출은 아직 allocator를 공통 경로로 사용하지 않으며 A1-D2/A1-D3 범위다. 실제 소유자 청취도 남아 있다.

## 실제 변경 경로

- `docs/qa/V122_A1_D1_AUDIO_VOICE_ALLOCATOR_REVALIDATION_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_A1_D1_AUDIO_VOICE_ALLOCATOR_REVALIDATION_2026-08-05.md`
- `docs/handoff/CURRENT.md`

allocator·catalog 구현과 직접 테스트는 읽기 전용으로 재검증하고 수정하지 않았다.

## 정책 판정

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
