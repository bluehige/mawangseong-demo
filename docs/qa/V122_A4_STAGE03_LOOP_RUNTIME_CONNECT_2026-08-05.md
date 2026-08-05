# V1.2.2 Stage 03 환경음 loop runtime 연결 QA

## 1. 패킷과 범위

- 패킷 ID: `A4-STAGE-03-LOOP-RUNTIME-CONNECT`
- 목표 버전: `v1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 작업 시작 기준 HEAD/마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 결과: `A4_STAGE03_LOOP_RUNTIME_CONNECT_PASS`

Stage 03 ambience를 기존 `StageAmbiencePlayer`에 연결했다. 성 단계가 Stage 03이면 새 catalog 이벤트를 선택하며, Stage 01·02·03 전환 시 같은 dedicated player의 stream만 교체한다. 추가 음원 생성·승격, AudioDirector, 대표 화면·실제 청취는 수행하지 않았다.

## 2. 연결 결과

- GameRoot 상수:
  - `STAGE03_AMBIENCE_ASSET_ID = ambience_stage03_keep`
  - `STAGE03_AMBIENCE_EVENT_ID = ambience.stage03.keep`
- 단계 분기: `CASTLE_STAGE_THREE_ID` → `ambience.stage03.keep`
- catalog 자산 상태: `actual_runtime`
- catalog 이벤트: `ambience.stage03.keep`
- 이벤트 owner: `scripts/game/GameRoot.gd`
- 이벤트 locator: `_update_stage_ambience`
- stream 로더: `AudioCatalogApiScript.resolve_event()` 기반, imported resource가 없으면 WAV fallback 로드
- 재생 버스: `AudioSettings.AMBIENCE_BUS`
- 반복 갱신: 같은 이벤트에서는 기존 player·stream을 재사용하고, 단계가 바뀔 때만 stream을 교체

## 3. 직접 검증

| 검사 | 명령 또는 방법 | 결과 |
|---|---|---|
| catalog 계약 | `tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_audio_event_catalog -v` | PASS — 9/9 |
| Godot runtime 계약 | `godot.cmd --headless --path . --scene tools/tests/MusicStateAudioTest.tscn --quit-after 1800` | PASS — 48 assertions |
| Stage 03 이벤트 | catalog asset/event, `actual_runtime`, owner locator 확인 | PASS |
| Stage 03 stream | Stage 02 stream과 다른 Stage 03 stream으로 교체 | PASS |
| 버스·재생 | Stage 03 stream이 Ambience 버스에서 재생 | PASS |
| 중복 방지 | 반복 `_update_stage_ambience()`에서 동일 player·stream 유지 | PASS |
| JSON 구문 | `data/audio/audio_event_catalog.json` UTF-8 JSON 파싱 | PASS |
| 대표 화면·실제 청취 | 다음 별도 패킷 | `NOT_REQUESTED` |
| 전체 회귀·전체 플레이·검수 에이전트 | 이번 패킷에서 요청되지 않음 | `NOT_REQUESTED` |

Godot verbose 종료 시 기존 `management_castle_bustle.wav`의 `AudioStreamWAV`·`AudioStreamPlaybackWAV` 누수 경고가 1건 출력됐지만 종료 코드는 0이고 모든 직접 단언은 PASS했다. Stage 03 연결 실패나 새 Stage 03 리소스 누수로 식별되지는 않았으며, 대표 패킷의 미해결 관찰 항목으로 보존한다.

## 4. 변경 경로

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/audio/audio_event_catalog.json` | Stage 03 자산을 `actual_runtime`으로 전환하고 이벤트 추가 | 완료 |
| `scripts/game/GameRoot.gd` | Stage 03 ambience 단계 분기·stream 교체 연결 | 완료 |
| `tools/audio/test_audio_event_catalog.py` | Stage 03 actual runtime/event 계약 단언 | 완료 |
| `tools/tests/MusicStateAudioTest.gd` | Stage 03 이벤트·stream·버스·중복 방지 단언 | 완료 |
| `docs/qa/V122_A4_STAGE03_LOOP_RUNTIME_CONNECT_2026-08-05.md` | runtime 연결 QA 기록 | 완료 |
| `docs/handoff/V122_RELEASE_POLISH_A4_STAGE03_LOOP_RUNTIME_CONNECT_2026-08-05.md` | 세션 핸드오프 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 대표 확인 패킷 갱신 | 완료 |

manifest, source/runtime 오디오 파일, AudioDirector, Stage 01·02 자산은 변경하지 않았다.

## 5. 미해결과 다음 순서

코드·catalog runtime 연결은 끝났지만 1280×720 대표 화면에서 Stage 03 장면과 ambience가 함께 재생되는지, 사용자가 실제 소리를 승인하는지는 아직 확인하지 않았다. 기존 management 음악 teardown warning도 관찰 항목으로 남아 있다.

다음은 `A4-STAGE-03-LOOP-REPRESENTATIVE-CHECK` 단일 패킷으로 대표 화면 부팅·runtime 단언·실제 청취를 확인한다.

## 6. 정책 기록

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
