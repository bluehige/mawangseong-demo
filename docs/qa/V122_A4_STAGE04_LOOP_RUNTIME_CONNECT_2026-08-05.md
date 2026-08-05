# V1.2.2 Stage 04 환경음 loop runtime 연결 QA

## 1. 패킷과 범위

- 패킷 ID: `A4-STAGE-04-LOOP-RUNTIME-CONNECT`
- 목표 버전: `v1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 작업 시작 기준 HEAD/마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 결과: `A4_STAGE04_LOOP_RUNTIME_CONNECT_PASS`

Stage 04 환경음 `ambience_stage04_citadel`을 GameRoot의 단계별 ambience owner에 연결했다. catalog의 실제 이벤트와 GameRoot 호출 locator를 맞추고, Stage 01부터 Stage 04까지 stream 교체·Ambience 버스·반복 갱신 중복 방지를 직접 검증했다.

## 2. 연결 결과

- GameRoot 상수:
  - `STAGE04_AMBIENCE_ASSET_ID = ambience_stage04_citadel`
  - `STAGE04_AMBIENCE_EVENT_ID = ambience.stage04.citadel`
- Stage 분기: `CASTLE_STAGE_FOUR_ID` → `ambience.stage04.citadel`
- catalog 자산 상태: `actual_runtime`
- catalog 이벤트 owner: `scripts/game/GameRoot.gd`
- catalog 이벤트 locator: `_update_stage_ambience`
- runtime 경로: `assets/audio/ambience/stage04_citadel.wav`
- 재생 버스: `AudioSettings.AMBIENCE_BUS`
- 단계 전환: Stage 03 stream에서 Stage 04 stream으로 교체
- 반복 갱신: 동일 Stage 04 stream과 재생 상태 유지, 중복 player 생성 없음

catalog 요약은 자산 80개, event 72개, actual runtime 70개, data-only 0개, unconnected 10개로 정렬했다. Stage 04를 위해 실제 runtime event `ambience.stage04.citadel` 하나만 추가했으며 synthetic event는 만들지 않았다.

## 3. 직접 검증

| 검사 | 명령 또는 방법 | 결과 |
|---|---|---|
| catalog 계약 | `tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_audio_event_catalog -v` | PASS — 10/10 |
| catalog JSON 구문·요약 | `python -c "import json; ..."` | PASS — 80 assets / 72 events / 70 actual runtime / 10 unresolved |
| Godot runtime 계약 | `godot.cmd --headless --path . --scene tools/tests/MusicStateAudioTest.tscn --quit-after 1800` | PASS — 54 assertions |
| Stage 04 event | event asset·owner·locator·connected 상태 확인 | PASS |
| Stage 04 stream | Stage 03에서 Stage 04 stream 교체 및 WAV 로드 | PASS |
| 버스·재생 | Stage 04 stream의 Ambience 버스와 world-render 재생 확인 | PASS |
| 중복 방지 | 반복 `_update_stage_ambience()` 호출 시 동일 stream·player 유지 | PASS |
| UI·실제 청취 | runtime 연결 패킷 | `NOT_REQUESTED` |
| 전체 회귀·전체 플레이·검수 에이전트 | 이번 패킷에서 요청되지 않음 | `NOT_REQUESTED` |

## 4. 변경 경로

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/game/GameRoot.gd` | Stage 04 ambience 상수·단계 분기 연결 | 완료 |
| `data/audio/audio_event_catalog.json` | Stage 04 actual runtime/event 정렬 및 unresolved 제거 | 완료 |
| `tools/audio/test_audio_event_catalog.py` | Stage 04 connected catalog 계약 단언과 snapshot 갱신 | 완료 |
| `tools/tests/MusicStateAudioTest.gd` | Stage 04 event·stream·버스·중복 방지 직접 단언 추가 | 완료 |
| `docs/qa/V122_A4_STAGE04_LOOP_RUNTIME_CONNECT_2026-08-05.md` | runtime 연결 QA 기록 | 완료 |
| `docs/handoff/V122_RELEASE_POLISH_A4_STAGE04_LOOP_RUNTIME_CONNECT_2026-08-05.md` | 세션 핸드오프 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 대표 화면·청취 패킷 갱신 | 완료 |

추가 음원 생성, source/runtime 음원, manifest, AudioDirector, Stage 01·02·03 코드는 변경하지 않았다.

## 5. 미해결과 다음 순서

코드·catalog runtime 연결은 완료했지만 Stage 04 대표 화면에서 실제 ambience가 화면과 함께 재생되는지, 사용자가 음원을 청취해 승인하는지는 아직 확인하지 않았다. 다음 단일 패킷은 `A4-STAGE-04-LOOP-REPRESENTATIVE-CHECK`이며 1280×720 Stage 04 대표 화면, runtime 재확인, 실제 청취 기록만 수행한다.

## 6. 정책 기록

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
