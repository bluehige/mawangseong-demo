# v1.2.2 출시 마무리 A1-A 오디오 자산·이벤트 catalog 핸드오프

목표 버전: `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
검수일: 2026-08-02

## 완료 내용

`tools/audio/lyria_v122_manifest.json`을 기준으로 `data/audio/audio_event_catalog.json`을 만들었다. 76개 WAV를 자산으로 한 번씩 선언하고, 실제 코드에서 재생 호출을 확인한 54개만 사건으로 연결했다. 데이터에만 선언된 12개와 현재 소비자를 찾지 못한 10개는 별도 상태로 남겼다.

- provenance: Lyria 28개, procedural 48개
- review status: 76개 모두 `pending`
- 기본 버스 분류: Music 6개, SFX 70개
- event 소유 파일·함수 위치와 자산↔event 양방향 관계 고정
- 가짜 event와 조용한 누락 무시 금지 계약 추가

## 검증과 파일

- QA 보고서: `docs/qa/V122_A1_A_AUDIO_EVENT_CATALOG_2026-08-02.md`
- catalog: `data/audio/audio_event_catalog.json`
- 계약 테스트: `tools/audio/test_audio_event_catalog.py`
- 검증 로그: `tmp/v122_release_polish/a1_audio_catalog_json_check.log`

Related tests: `python -m unittest tools.audio.test_audio_event_catalog -v` 6/6 PASS; JSON syntax PASS.
UI check: 화면·런타임 동작은 변경하지 않았고 catalog·분류 계약만 확인했다.
Unresolved issues: 다음은 A1-B 버스·limiter·설정이다. A1-C loop transport, A1-D routing, A1-E suite 등록과 22개 미연결 자산의 후속 결정은 남아 있다.

## 다음 작업

A1-B에서 `Music / SFX / UI / Ambience` 버스 계층과 Master limiter, 설정값 전파 계약을 작은 범위로 추가한다. 새 음원 생성·승격은 계속 별도 승인 전까지 실행하지 않는다.

## Git 상태

- 커밋·푸시: 수행하지 않음
- 기존 사용자 변경과 이전 패킷 문서를 보존함
