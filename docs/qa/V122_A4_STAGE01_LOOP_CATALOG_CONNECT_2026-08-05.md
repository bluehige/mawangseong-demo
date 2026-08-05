# v1.2.2 A4 Stage 01 catalog 연결 QA

- 검수일: 2026-08-05
- 목표 버전: `v1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 패킷: `A4-STAGE-01-LOOP-CATALOG-CONNECT`
- 결과: `TARGETED_BLOCKED`

## 목적

승격된 `ambience_stage01_cave`를 v1.2.2 audio event catalog에 등록하려고 현재 catalog 계약과 직접 테스트를 확인했다.

## 확인 결과

- 현재 manifest에는 `ambience_stage01_cave`가 포함되어 있지만 catalog에는 아직 없다.
- 따라서 catalog를 정상적으로 77개로 늘리려면 `data/audio/audio_event_catalog.json`에 자산 1개와 `unresolved_assets` 항목 1개를 추가해야 한다.
- 이 자산은 게임 호출이 아직 없으므로 `runtime_connection=unconnected`, `events=[]`로 등록해야 하며, 현재 catalog 정책상 버스는 기존 Ambience 라우팅 계약에 맞춰 `SFX`로 기록해야 한다.
- 그 변경 뒤에는 기존 직접 테스트의 고정 기대값도 함께 갱신해야 한다: `asset_count=77`, Lyria `29`, SFX `71`, `unconnected=11`, `event_count=68`.
- 그러나 `tools/audio/test_audio_event_catalog.py`가 이번 패킷의 `ALLOWED_WRITE_PATHS`에 없어 테스트를 함께 정렬할 수 없다. 허용 범위를 임의로 넓히지 않고 catalog 변경을 실행하지 않았다.

## 직접 테스트

| 검증 | 결과 |
|---|---|
| `tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_audio_event_catalog -v` | BLOCKED — 7개 중 6개 통과, catalog가 manifest의 `ambience_stage01_cave`를 아직 포함하지 않아 1개 실패 |
| UI/청취 확인 | NOT_REQUESTED — catalog 계약 확인 범위 |
| 전체 회귀/별도 검수 에이전트 | NOT_REQUESTED |

실패 핵심:

```text
AssertionError: manifest assets contain an additional 'ambience_stage01_cave'
```

## 범위 준수

- 이번 패킷에서 `data/audio/audio_event_catalog.json`은 변경하지 않았다.
- 음원, runtime, source, manifest, 게임 코드 및 테스트 파일은 변경하지 않았다.
- 다음 패킷에서 catalog와 직접 테스트를 함께 정렬해야 한다.

Review task ID: `NOT_REQUESTED`
Reviewed SHA: `N/A`
Remaining P1/P2: `N/A`
Final review result: `TARGETED_BLOCKED`
