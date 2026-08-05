# v1.2.2 A1-A 오디오 자산·이벤트 catalog 계약 재검증

검수일: 2026-08-05
대상 브랜치: `codex/v122-ui-simplification`
기준 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 범위

v1.2.2 manifest와 오디오 event catalog의 양방향 연결을 다시 확인했다. 실제 소유 코드와 locator가 없는 event를 새로 만들지 않았으며, `data_only`·`unconnected` 자산을 임의로 재생 경로에 연결하지 않았다. 버스·limiter·routing·새 음원은 이번 패킷에서 다루지 않았다.

## 현재 catalog 사실값

- manifest/catalog 자산: 76개
- catalog event: 68개
- 실제 runtime 연결 자산: 66개
- `data_only`: 0개
- `unconnected`: 10개 (`heart_ready`, `monster_signature_01`~`monster_signature_09`)
- provenance: `lyria` 28개, `procedural` 48개
- review status: 76개 모두 `pending`
- 버스 분류: `Music` 6개, `SFX` 70개

이 수치는 2026-08-02 선행 문서에 적힌 `54/12/10` 분류와 다르다. 현재 작업 트리의 catalog를 기준으로 재계산한 값이며, 이번 패킷에서는 임의로 과거 수치에 맞추지 않았다.

## 검증 결과

```text
python -m unittest tools.audio.test_audio_event_catalog -v
Ran 7 tests in 0.126s
OK

python -m json.tool data/audio/audio_event_catalog.json
PASS
```

검사는 manifest ID·runtime 경로 76/76 일치, 실제 WAV 존재, event ID 중복 없음, event↔asset 양방향 연결, owner 파일·locator 존재, 미연결 목록의 이유 기록, 현재 분류 snapshot을 확인한다.

## 실제 변경 경로

- `tools/audio/test_audio_event_catalog.py`
- `docs/qa/V122_A1_A_AUDIO_EVENT_CATALOG_REVALIDATION_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_A1_A_AUDIO_EVENT_CATALOG_REVALIDATION_2026-08-05.md`
- `docs/handoff/CURRENT.md`

`data/audio/audio_event_catalog.json`은 이번 재검증에서 수정하지 않았다. 런타임 코드·WAV·import 설정·빌드도 변경하지 않았다.

## 미해결 및 다음 순서

- 10개 미연결 자산은 실제 호출 소유자가 확인되기 전까지 event를 만들지 않는다.
- 76개 오디오의 사람 청취·권리 검수는 여전히 `pending`이다.
- 다음 패킷은 `A1-B-AUDIO-BUS-CONTRACT` 재검증이며, Music/SFX/UI/Ambience 버스와 Master limiter만 확인한다.

## 정책 판정

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
