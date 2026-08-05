# v1.2.2 A1-D2 GameRoot·Update 3/4 AudioDirector routing 재검증

검수일: 2026-08-05
대상 브랜치: `codex/v122-ui-simplification`
기준 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 범위

GameRoot가 공통 `AudioDirector`를 소유하고, Update 3 경보와 Update 4 스킬·왕관·경쟁 보스 사건이 catalog event와 voice allocator를 거쳐 실제 runtime 음원으로 라우팅되는지 재검증했다. 이번 패킷에서는 전투·HUD 직접 호출부 이관, catalog 수정, 새 음원 생성·승격, 전체 회귀·빌드는 실행하지 않았다.

## 검증 결과

```text
godot.cmd --headless --path . --scene tools/tests/SkillAudioPaletteTest.tscn --quit-after 2500
SKILL_AUDIO_PALETTE_TEST: PASS (126 assertions)
```

확인한 동작:

- GameRoot에 공통 AudioDirector가 하나 생성된다.
- Update 4 스킬 사건은 catalog event와 runtime asset을 통해 한 voice를 만든다.
- 같은 instance token의 재호출은 `duplicate_voice`로 차단되고 voice 수가 늘지 않는다.
- 왕관 진화 효과음과 경쟁 보스 모티프가 각각 catalog 경로로 재생된다.
- Update 3 보스 경보도 AudioDirector로 라우팅되며 중복 token이 억제된다.
- Update 4 13개 event의 asset 연결과 실제 runtime 파일 존재를 함께 확인했다.

## 미해결 및 판정 경계

테스트는 종료 시 `AudioStreamWAV`/`AudioStreamPlaybackWAV` 자원 4개가 남았다는 비치명적 ObjectDB/resource teardown 경고를 출력했다. 프로세스 종료 코드 0과 126개 직접 단언은 통과했지만, 플레이어 수명 정리는 별도 보정 패킷으로 남긴다. CombatSceneController 일반·스킬 SFX와 MultiFloorHUD 층 경보의 공통 경로 이관은 다음 A1-D3 범위이며, 실제 소유자 청취도 미완료다.

## 실제 변경 경로

- `docs/qa/V122_A1_D2_AUDIO_DIRECTOR_ROUTING_REVALIDATION_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_A1_D2_AUDIO_DIRECTOR_ROUTING_REVALIDATION_2026-08-05.md`
- `docs/handoff/CURRENT.md`

AudioDirector, GameRoot, catalog, SkillAudioPaletteTest는 재검증만 수행하고 수정하지 않았다.

## 정책 판정

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
