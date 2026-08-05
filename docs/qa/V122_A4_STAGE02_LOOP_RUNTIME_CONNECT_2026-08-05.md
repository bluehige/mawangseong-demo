# V122 A4 Stage 02 runtime 연결 QA

## 패킷과 범위

- 패킷 ID: `A4-STAGE-02-LOOP-RUNTIME-CONNECT`
- 목표 버전: `v1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 작업 시작 기준 HEAD/마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 결과: `A4_STAGE02_LOOP_RUNTIME_CONNECT_PASS`

Stage 02 ambience를 기존 `StageAmbiencePlayer`에 연결했다. 성 단계가 Stage 01이면 기존 이벤트를, Stage 02이면 새 이벤트를 선택하며, 성 단계가 바뀌는 순간 stream을 교체한다. `AudioDirector`나 다른 Stage 자산은 변경하지 않았다.

## 연결 결과

- GameRoot 상수:
  - `STAGE02_AMBIENCE_ASSET_ID = ambience_stage02_indoor`
  - `STAGE02_AMBIENCE_EVENT_ID = ambience.stage02.indoor`
- catalog 자산 상태: `actual_runtime`
- catalog 이벤트: `ambience.stage02.indoor`
- 이벤트 owner: `scripts/game/GameRoot.gd`
- 이벤트 locator: `_update_stage_ambience`
- stream 로더: `AudioCatalogApiScript.resolve_event()` 기반, imported resource가 없으면 WAV fallback 로드
- 재생 버스: `AudioSettings.AMBIENCE_BUS`
- 반복 갱신: 같은 이벤트에서는 기존 player를 재사용하고, Stage 01↔02 전환에서만 stream을 교체
- 성 진화 직후 `_update_stage_ambience()`를 호출해 화면 전환을 기다리지 않고 새 ambience를 반영

## 직접 검증

| 검사 | 명령 또는 방법 | 결과 |
|---|---|---|
| catalog 계약 | `tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_audio_event_catalog -v` | PASS — 8/8 |
| Godot runtime 계약 | `godot.cmd --headless --path . --scene tools/tests/MusicStateAudioTest.tscn --quit-after 1800` | PASS — 42 assertions |
| Stage 02 이벤트 | catalog asset/event, connected 상태, owner locator 확인 | PASS |
| Stage 02 stream | Stage 01 stream과 다른 Stage 02 stream으로 교체 | PASS |
| 버스·재생 | Stage 02 stream이 Ambience 버스에서 재생 | PASS |
| 중복 방지 | 반복 `_update_stage_ambience()`에서 동일 player·stream 유지 | PASS |
| 대표 화면·실제 청취 | 다음 별도 패킷 | `NOT_REQUESTED` |
| 전체 회귀·전체 플레이·검수 에이전트 | 이번 패킷에서 요청되지 않음 | `NOT_REQUESTED` |

## 미해결과 다음 순서

코드·catalog 연결은 끝났지만 1280×720 대표 화면에서 실제 Stage 02 장면과 ambience를 확인하는 절차는 아직 남아 있다. 다음은 `A4-STAGE-02-LOOP-REPRESENTATIVE-CHECK` 단일 패킷으로 대표 화면 부팅·runtime 단언·실제 청취 확인을 기록한다.

## 정책 기록

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A` — 전체 검수 미요청
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
