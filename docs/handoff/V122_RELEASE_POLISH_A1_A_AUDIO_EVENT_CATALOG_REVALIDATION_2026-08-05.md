# v1.2.2 출시 마무리 A1-A 오디오 event catalog 재검증 핸드오프

목표 버전: `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
검수일: 2026-08-05
패킷: `A1-A-AUDIO-EVENT-CATALOG`
QA: `docs/qa/V122_A1_A_AUDIO_EVENT_CATALOG_REVALIDATION_2026-08-05.md`

## 완료 내용

선행 A1-A catalog를 현재 manifest와 다시 대조했다. 자산 76개와 runtime 경로가 일치하고, event 68개가 66개 실제 연결 자산에만 연결되어 있다. 10개 미연결 자산에는 가짜 event를 만들지 않고 이유를 유지했다. 이전 문서의 54개 실제 연결·12개 data-only 수치는 현재 catalog와 달라 현재 재검증 결과에 사용하지 않았다.

## 실제 변경 경로

- `tools/audio/test_audio_event_catalog.py`
- `docs/qa/V122_A1_A_AUDIO_EVENT_CATALOG_REVALIDATION_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_A1_A_AUDIO_EVENT_CATALOG_REVALIDATION_2026-08-05.md`
- `docs/handoff/CURRENT.md`

catalog JSON과 런타임 오디오 연결 코드는 수정하지 않았다.

## 실행한 직접 테스트

- `python -m unittest tools.audio.test_audio_event_catalog -v` — 7/7 PASS
- `python -m json.tool data/audio/audio_event_catalog.json` — PASS

## 코드·데이터·스토리·밸런스·그래픽·오디오

- 코드: 현재 분류 snapshot(실제 66·data-only 0·미연결 10·event 68)을 고정하는 테스트 1개를 추가했다.
- 데이터: `data/audio/audio_event_catalog.json`은 변경하지 않았다.
- 오디오: 음원·import·버스·limiter·routing은 변경하지 않았다.
- 스토리·밸런스·그래픽: 변경 없음.

## 미해결 문제와 다음 작업 순서

- 미연결 10개는 실제 호출 owner가 발견될 때까지 보류한다.
- 76개 음원의 청취·권리 승인은 별도 gate다.
- 다음 잠금 후보는 `A1-B-AUDIO-BUS-CONTRACT` 재검증이다. 이번 turn에는 시작하지 않는다.

## 작업 트리 및 원격 상태

- 기존 사용자/Luna 미커밋 변경은 보존했으며 되돌리거나 정리하지 않았다.
- 커밋·푸시: 수행하지 않음.

## 정책 판정

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
