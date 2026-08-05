# v1.2.2 출시 마무리 A1-C BGM transport 재검증 핸드오프

목표 버전: `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
검수일: 2026-08-05
패킷: `A1-C-BGM-TRANSPORT`
QA: `docs/qa/V122_A1_C_BGM_TRANSPORT_REVALIDATION_2026-08-05.md`

## 완료 내용

선행 A1-C 구현을 현재 런타임 기준으로 다시 확인했다. 세 BGM import가 전진 반복으로 설정되어 있고, 관리·일반 전투·보스 상태 전환의 crossfade와 설정 미리듣기 중복 방지·자동 정지가 유지된다. 직접 음악 상태 테스트 27개, catalog 보조 단위 테스트 7개, JSON 구문 검사를 통과했다.

## 실제 변경 경로

- `docs/qa/V122_A1_C_BGM_TRANSPORT_REVALIDATION_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_A1_C_BGM_TRANSPORT_REVALIDATION_2026-08-05.md`
- `docs/handoff/CURRENT.md`

GameRoot, BGM import, catalog, MusicStateAudioTest 코드는 수정하지 않았다. 기존 사용자/Luna 변경과 섞인 작업 트리는 그대로 보존했다.

## 실행한 직접 테스트

- `MusicStateAudioTest.tscn` — 27/27 PASS
- `python -m unittest tools.audio.test_audio_event_catalog -v` — 7/7 PASS
- `python -m json.tool data/audio/audio_event_catalog.json` — PASS

## 코드·데이터·스토리·밸런스·그래픽·오디오

- 코드/데이터/스토리/밸런스/그래픽: 변경 없음.
- 오디오: 세 BGM import의 `edit/loop_mode=2`를 읽기 전용으로 확인했으며 WAV와 manifest/catalog는 변경하지 않았다.

## 미해결 문제와 다음 작업 순서

- Godot 종료 시 관리 BGM `AudioStreamWAV`/재생 인스턴스 teardown 경고가 남는다. 실행 실패는 아니지만 별도 정리 대상으로 기록한다.
- 130초 loop seam과 실제 소유자 청취는 남아 있다.
- 다음 잠금 후보는 `A1-D1-AUDIO-VOICE-ALLOCATOR`이며 이번 turn에는 시작하지 않는다.

## 작업 트리 및 원격 상태

- 기존 사용자/Luna 미커밋 변경은 되돌리거나 정리하지 않았다.
- 커밋·푸시·빌드: 수행하지 않음.

## 정책 판정

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
