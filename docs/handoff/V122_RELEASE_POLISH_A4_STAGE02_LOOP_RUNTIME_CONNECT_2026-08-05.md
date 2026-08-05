# V122 A4 Stage 02 runtime 연결 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `v1.2.2`
- 패킷 ID: `A4-STAGE-02-LOOP-RUNTIME-CONNECT`
- 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치와 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 작업 결과: `TARGETED_PASS`

## 2. 목표와 완료 조건

Stage 02 ambience의 실제 runtime owner와 catalog 이벤트 한 개를 연결하고, Stage 01·Stage 02 stream 전환 및 반복 갱신을 직접 검증했다. 추가 음원 생성·승격, AudioDirector 변경, 대표 화면·실제 청취는 제외했다.

## 3. 완료 내용

- `GameRoot.gd`에 Stage 02 ambience asset/event 상수를 추가했다.
- 기존 `StageAmbiencePlayer`가 성 단계별 catalog 이벤트를 선택하도록 확장했다.
- Stage 01에서 Stage 02로 바뀌면 기존 stream을 멈추고 Stage 02 stream으로 교체한다.
- Stage 02에서 반복 갱신해도 player와 stream을 중복 생성하지 않는다.
- 성 진화 직후 ambience 갱신을 호출한다.
- catalog에서 Stage 02 자산을 `actual_runtime`으로 바꾸고 `ambience.stage02.indoor` 이벤트를 연결했다.
- Python catalog 계약과 Godot runtime 계약에 Stage 02 전용 단언을 추가했다.

## 4. 변경 경로

- `data/audio/audio_event_catalog.json`
- `scripts/game/GameRoot.gd`
- `tools/audio/test_audio_event_catalog.py`
- `tools/tests/MusicStateAudioTest.gd`
- `docs/qa/V122_A4_STAGE02_LOOP_RUNTIME_CONNECT_2026-08-05.md`
- `docs/handoff/CURRENT.md`

## 5. 오디오 자산과 runtime 연결

- 자산 ID: `ambience_stage02_indoor`
- 이벤트 ID: `ambience.stage02.indoor`
- Runtime 경로: `assets/audio/ambience/stage02_indoor.wav`
- 출처 기록: `assets/source/audio/lyria/v1.2.2/ambience_stage02_indoor/SOURCE.md`
- catalog 상태: `actual_runtime`
- owner: `scripts/game/GameRoot.gd`
- locator: `_update_stage_ambience`
- 버스: catalog는 `SFX`, 실제 dedicated player는 `AudioSettings.AMBIENCE_BUS`
- Stage 01과 같은 dedicated player를 재사용하며 단계가 바뀔 때만 stream을 교체한다.
- 기존 WAV, source MP3, manifest, AudioDirector는 변경하지 않았다.

## 6. 테스트와 검수

- `tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_audio_event_catalog -v` — PASS (8/8)
- `godot.cmd --headless --path . --scene tools/tests/MusicStateAudioTest.tscn --quit-after 1800` — PASS (42 assertions)
- 확인 항목: Stage 02 catalog event, connected 상태, stream 교체, Ambience 버스, 반복 갱신 중복 방지 — PASS
- 대표 화면·실제 청취 — `NOT_REQUESTED`, 다음 패킷
- 전체 회귀·전체 플레이·검수 에이전트 — `NOT_REQUESTED`

정책 필드:

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 미해결 문제

- 1280×720 대표 화면에서 Stage 02 ambience가 실제 장면과 함께 재생되는지 확인 전이다.
- 실제 소유자 청취 gate 전이다.
- 전체 출시 검수와 최종 커밋·푸시는 별도 범위다.

## 8. 다음 작업 순서

다음 단일 패킷만 제안한다.

`A4-STAGE-02-LOOP-REPRESENTATIVE-CHECK`

- 목표: 대표 화면 부팅·Stage 02 runtime 단언·실제 청취를 확인하고 결과를 기록한다.
- 허용 경로: 해당 QA/핸드오프 문서, `docs/handoff/CURRENT.md`
- 금지: 코드·catalog·manifest/source/runtime 변경, 추가 음원 생성·승격, AudioDirector, Stage 01/03/04, 발소리, 다음 패킷 자동 실행
- 직접 확인: Godot 대표 화면 부팅, `MusicStateAudioTest`, Stage 02 ambience 실제 청취

## 9. 작업 트리

- 혼합 작업 트리이며 기존 사용자 변경을 보존했다.
- 이번 패킷은 커밋·스테이징·푸시하지 않았다.
- 작업 종료 시점의 브랜치와 HEAD는 위 메타데이터에 기록한 값이다.
