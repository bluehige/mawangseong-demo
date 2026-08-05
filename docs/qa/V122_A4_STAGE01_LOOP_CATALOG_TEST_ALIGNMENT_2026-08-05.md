# v1.2.2 A4 Stage 01 catalog·계약 테스트 정렬 QA

- 검수일: 2026-08-05
- 목표 버전: `v1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 패킷: `A4-STAGE-01-LOOP-CATALOG-TEST-ALIGNMENT`
- 결과: `TARGETED_PASS`

## 목적

승격된 `ambience_stage01_cave`를 v1.2.2 audio event catalog에 등록하고, catalog 계약 테스트의 고정 snapshot을 현재 manifest 기준으로 정렬했다.

## 변경 결과

- catalog 자산 수를 76개에서 77개로 정렬했다.
- `ambience_stage01_cave`를 `lyria`, `SFX`, `unconnected`, `events=[]`로 등록했다.
- source record를 `assets/source/audio/lyria/v1.2.2/ambience_stage01_cave/SOURCE.md`로 연결했다.
- 실제 게임 호출 이벤트는 만들지 않았다. 재생 연결은 다음 패킷에서 진행한다.
- catalog 요약을 `actual_runtime=66`, `data_only=0`, `unconnected=11`, `event_count=68`, Lyria 29개, SFX 71개로 갱신했다.
- 직접 테스트의 unconnected snapshot 기대값을 11로 갱신했다.

## 직접 검증

| 검증 | 결과 |
|---|---|
| `tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_audio_event_catalog -v` | PASS — 7개 테스트 |
| `audio_event_catalog.json` JSON 파싱 | PASS |
| UI/청취 확인 | NOT_REQUESTED — catalog·계약 테스트 패킷 |
| 전체 회귀/별도 검수 에이전트 | NOT_REQUESTED |

## 범위 밖 및 미해결

- `assets/audio/ambience/stage01_cave.wav`와 source 원본은 변경하지 않았다.
- `tools/audio/lyria_v122_manifest.json`은 변경하지 않았다.
- Stage 01 환경음의 실제 게임 재생 연결과 runtime 호출 owner는 다음 패킷이다.
- 커밋·푸시는 하지 않았다.

Review task ID: `NOT_REQUESTED`
Reviewed SHA: `N/A`
Remaining P1/P2: `N/A`
Final review result: `TARGETED_PASS`
