# v1.2.2 A4 Stage 01 runtime·catalog 계약 정렬 QA

- 검수일: 2026-08-05
- 목표 버전: `v1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 패킷: `A4-STAGE-01-LOOP-RUNTIME-CONNECT-TEST-ALIGNMENT`
- 결과: `TARGETED_PASS`

## 목적

Stage 01 ambience event, catalog runtime 상태, GameRoot 재생 경로와 관련 계약 테스트를 한 패킷에서 정렬했다.

## 변경 결과

- catalog에 `ambience.stage01.cave` event를 추가했다.
- `ambience_stage01_cave`를 `actual_runtime`으로 전환하고 요약 수치를 `actual_runtime=67`, `unconnected=10`, `event_count=69`로 갱신했다.
- `GameRoot`에 전용 `StageAmbiencePlayer`를 추가했다.
- catalog event를 통해 runtime WAV를 해석하고 `Ambience` 버스로 재생한다.
- Stage 01이고 World Render 화면일 때만 재생하며, 설정 화면 등에서는 정지하고 복귀 시 다시 재생한다.
- 동일 상태에서 반복 갱신해도 중복 player를 만들지 않는다.
- Godot import 파일이 아직 없는 WAV는 `AudioStreamWAV.load_from_file` fallback으로 읽도록 했다. `.import` 파일은 만들지 않았다.
- `AudioDirector`는 수정하지 않았다. 지속 loop의 수명은 GameRoot 전용 player가 관리한다.

## 직접 검증

| 검증 | 결과 |
|---|---|
| `tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_audio_event_catalog -v` | PASS — 7개 테스트 |
| `godot.cmd --headless --path . --scene tools/tests/MusicStateAudioTest.tscn --quit-after 1800` | PASS — 36 assertions |
| Godot 종료 누수/loader 오류 | PASS — 최종 실행에서 경고 없음 |
| UI/청취 확인 | NOT_REQUESTED — headless runtime 계약 패킷 |
| 전체 회귀/별도 검수 에이전트 | NOT_REQUESTED |

## 범위 밖 및 미해결

- 추가 음원 생성·승격은 하지 않았다.
- Stage 02~04와 발소리 자산은 건드리지 않았다.
- 실제 1280×720 화면에서의 소유자 청취 확인은 다음 대표 검수 패킷으로 남겼다.
- 커밋·푸시는 하지 않았다.

Review task ID: `NOT_REQUESTED`
Reviewed SHA: `N/A`
Remaining P1/P2: `N/A`
Final review result: `TARGETED_PASS`
