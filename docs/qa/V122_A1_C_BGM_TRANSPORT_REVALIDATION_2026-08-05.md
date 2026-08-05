# v1.2.2 A1-C BGM transport 재검증

검수일: 2026-08-05
대상 브랜치: `codex/v122-ui-simplification`
기준 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 범위

관리·일반 전투·보스 BGM의 가져오기 loop 설정, 게임 상태 전환 crossfade, 설정 화면 미리듣기를 현재 작업 트리에서 다시 확인했다. 이번 패킷에서는 새 음원을 생성·승격하지 않았고, 오디오 버스·voice allocator·다음 A1 패킷·전체 회귀·빌드는 실행하지 않았다.

## 검증 결과

```text
management_castle_bustle.wav.import: edit/loop_mode=2
combat_dungeon_pressure.wav.import: edit/loop_mode=2
combat_boss_council.wav.import: edit/loop_mode=2

godot.cmd --headless --path . --scene tools/tests/MusicStateAudioTest.tscn --quit-after 1200
MUSIC_STATE_AUDIO_TEST: PASS (27 assertions)

python -m unittest tools.audio.test_audio_event_catalog -v
Ran 7 tests ... OK

python -m json.tool data/audio/audio_event_catalog.json
AUDIO_EVENT_CATALOG_JSON: PASS
```

확인한 동작:

- 관리·일반 전투·보스 스트림이 서로 다른 실제 파일을 선택한다.
- 보스 진입 및 일반 전투 복귀가 대상 플레이어를 교체하며 crossfade한다.
- 같은 전투 상태를 다시 요청해도 플레이어를 중복 생성·교체하지 않는다.
- 관리 화면 전환은 관리 BGM을 선택한다.
- 설정 미리듣기는 관리 BGM을 한 번만 시작하고 짧은 preview 창 뒤 정지한다.
- 세 BGM import sidecar가 모두 `LOOP_FORWARD`에 해당하는 `edit/loop_mode=2`다.

## 미해결 및 판정 경계

Godot 종료 시 `management_castle_bustle.wav`의 `AudioStreamWAV`/재생 인스턴스가 남았다는 비치명적 ObjectDB/resource teardown 경고가 출력됐다. 프로세스 종료 코드 0과 27개 직접 단언은 통과했지만, 이 경고는 별도 정리 패킷에서 다룰 항목으로 남긴다. 130초 전체 재생·loop seam의 사람 청취와 소유자 청취는 자동 검증 범위 밖이다.

## 실제 변경 경로

- `docs/qa/V122_A1_C_BGM_TRANSPORT_REVALIDATION_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_A1_C_BGM_TRANSPORT_REVALIDATION_2026-08-05.md`
- `docs/handoff/CURRENT.md`

GameRoot, 음악 import, catalog, MusicStateAudioTest 구현은 재검증만 수행하고 수정하지 않았다.

## 정책 판정

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
