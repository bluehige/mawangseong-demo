# v1.2.2 A1-A 오디오 자산·이벤트 catalog 계약

검수일: 2026-08-02
대상 브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 범위

v1.2.2 manifest의 76개 WAV를 자산 목록으로 고정하고, 실제 재생 호출이 확인된 사건만 이벤트로 연결했다. 파일이 JSON에만 있거나 소비자를 찾지 못한 경우에는 가짜 이벤트를 만들지 않고 `data_only` 또는 `unconnected`로 남겼다.

## 변경 내용

- `data/audio/audio_event_catalog.json` 추가
- `tools/audio/test_audio_event_catalog.py` 추가
- 자산 76개, 실제 runtime event 54개, data-only 12개, unconnected 10개를 분리
- provenance `lyria` 28개와 `procedural` 48개, 사람 청취 상태 `pending`을 별도 기록
- 각 실제 이벤트에 소유 코드 파일과 함수 위치를 기록

## 검증 결과

- `python -m unittest tools.audio.test_audio_event_catalog -v`: 6/6 PASS
- `python -m json.tool data/audio/audio_event_catalog.json`: PASS
- manifest 자산 ID·runtime 경로와 catalog 일치: 76/76
- 실제 이벤트와 자산의 양방향 연결·중복 ID·소유 함수 위치: PASS
- 미연결 22개는 `data_only` 12개와 `unconnected` 10개로만 기록: PASS
- 런타임 코드·오디오 WAV·import 설정·빌드는 변경하지 않음

Related tests: `python -m unittest tools.audio.test_audio_event_catalog -v` 6/6 PASS; `python -m json.tool data/audio/audio_event_catalog.json` PASS.
UI check: 화면 변경 없음. catalog JSON과 계약 테스트만 확인했다.
Unresolved issues: A1-B 버스·limiter·설정, A1-C loop transport, A1-D Update 3/4 routing과 data-only 12개 이벤트 연결이 남아 있다. 76개 청취·권리 승인은 아직 `pending`이다.
