# v1.2.2 A4 Stage 01 runtime 연결 QA

- 검수일: 2026-08-05
- 목표 버전: `v1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 패킷: `A4-STAGE-01-LOOP-RUNTIME-CONNECT`
- 결과: `TARGETED_BLOCKED`

## 목적

catalog에 등록된 `ambience_stage01_cave`를 실제 Stage 01 runtime 재생 경로와 연결하려고 현재 계약 테스트와 패킷 허용 범위를 확인했다.

## 확인 결과

- 현재 catalog 계약 테스트는 7/7 PASS한다.
- 현재 `MusicStateAudioTest`는 27/27 PASS한다.
- runtime 연결을 완료하려면 catalog의 `ambience_stage01_cave`를 `actual_runtime`으로 바꾸고 event 1개를 추가해야 한다.
- 그 변경은 catalog 요약을 `actual_runtime=67`, `unconnected=10`, `event_count=69`로 바꾸므로 `tools/audio/test_audio_event_catalog.py`의 고정 snapshot도 함께 갱신해야 한다.
- 해당 테스트 파일은 이번 패킷의 `ALLOWED_WRITE_PATHS`에 없어, catalog·GameRoot만 수정하면 관련 계약 테스트가 깨진 상태로 남는다. 따라서 이번 패킷에서는 runtime 연결을 실행하지 않았다.

## 직접 검증

| 검증 | 결과 |
|---|---|
| `tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_audio_event_catalog -v` | PASS — 7개 테스트 |
| `godot.cmd --headless --path . --scene tools/tests/MusicStateAudioTest.tscn --quit-after 1800` | PASS — 27 assertions |
| UI/청취 확인 | NOT_REQUESTED — runtime 연결 구현 전 기준 확인 |
| 전체 회귀/별도 검수 에이전트 | NOT_REQUESTED |

## 범위 준수

- `data/audio/audio_event_catalog.json`, `scripts/game/GameRoot.gd`, `tools/tests/MusicStateAudioTest.gd`는 변경하지 않았다.
- 음원, runtime WAV, source, manifest, AudioDirector는 변경하지 않았다.
- 다음 패킷에는 `tools/audio/test_audio_event_catalog.py`를 추가해 catalog와 runtime 연결을 함께 정렬해야 한다.

Review task ID: `NOT_REQUESTED`
Reviewed SHA: `N/A`
Remaining P1/P2: `N/A`
Final review result: `TARGETED_BLOCKED`
