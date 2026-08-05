# V122 A4 Stage 02 catalog 연결 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `v1.2.2`
- 패킷 ID: `A4-STAGE-02-LOOP-CATALOG-CONNECT`
- 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치와 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 작업 결과: `TARGETED_PASS`

## 2. 목표와 완료 조건

승격된 Stage 02 환경음 `ambience_stage02_indoor`를 v1.2.2 audio event catalog의 매니페스트 자산 목록과 출처 목록에 등록하고, 실제 runtime 호출이 없는 상태를 명시적으로 기록했다. GameRoot와 AudioDirector의 재생 연결은 이번 패킷에서 제외했다.

## 3. 완료 내용

- catalog 자산 수를 77개에서 78개로 매니페스트와 맞췄다.
- `ambience_stage02_indoor`를 `lyria`·`SFX`·`ambience_loop`·`unconnected`·`events=[]`로 등록했다.
- Stage 02 `SOURCE.md`를 catalog의 `source_record`로 연결했다.
- `unresolved_assets`에 Stage 02 항목을 추가했다.
- catalog 요약을 Lyria 30개, SFX 72개, 미연결 11개로 갱신했다.
- Stage 02가 실제 runtime 이벤트 없이 남아 있어야 한다는 전용 계약 단언을 추가했다.

실제 호출 이벤트 수는 69개로 유지했다. catalog 정책상 실제 owner locator가 생기기 전에는 synthetic event를 추가하지 않는다.

## 4. 변경 경로

- `data/audio/audio_event_catalog.json`
- `tools/audio/test_audio_event_catalog.py`
- `docs/qa/V122_A4_STAGE02_LOOP_CATALOG_CONNECT_2026-08-05.md`
- `docs/handoff/CURRENT.md`

## 5. 오디오 자산과 연결 상태

- 자산 ID: `ambience_stage02_indoor`
- Runtime 경로: `assets/audio/ambience/stage02_indoor.wav`
- 출처 기록: `assets/source/audio/lyria/v1.2.2/ambience_stage02_indoor/SOURCE.md`
- catalog 연결 상태: `unconnected`
- 이벤트 목록: `[]`
- 미해결 목록: 게임 호출 owner가 아직 없어 runtime 이벤트가 연결되지 않음
- 기존 WAV, source MP3, manifest, GameRoot, AudioDirector는 변경하지 않았다.

## 6. 테스트와 검수

- `tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_audio_event_catalog -v` — PASS (8/8)
- catalog JSON UTF-8 파싱 — PASS
- 매니페스트 자산 순서·runtime 경로·출처 파일·미해결 목록 양방향 검증 — PASS
- UI·실제 청취 — `NOT_REQUESTED`
- 전체 회귀·전체 플레이·검수 에이전트 — `NOT_REQUESTED`

정책 필드:

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 미해결 문제

- Stage 02 runtime 이벤트와 GameRoot 재생 owner가 아직 없다.
- 대표 화면·실제 게임 청취 확인 전이다.
- 전체 출시 검수와 최종 커밋·푸시는 별도 범위다.

## 8. 다음 작업 순서

다음 단일 패킷만 제안한다.

`A4-STAGE-02-LOOP-RUNTIME-CONNECT`

- 목표: Stage 02 ambience runtime 재생 owner와 catalog 이벤트 한 개를 연결하고 관련 직접 테스트를 통과시킨다.
- 허용 경로: `data/audio/audio_event_catalog.json`, `scripts/game/GameRoot.gd`, `tools/audio/test_audio_event_catalog.py`, `tools/tests/MusicStateAudioTest.gd`, 해당 QA/핸드오프 문서, `docs/handoff/CURRENT.md`
- 금지: 추가 음원 생성·승격, manifest/source/runtime 변경, AudioDirector, Stage 01/03/04, 발소리, 대표 화면 검수, 다음 패킷 자동 실행
- runtime 연결 후 대표 화면·실제 청취는 별도 후속 패킷에서 진행한다.

## 9. 작업 트리

- 혼합 작업 트리이며 기존 사용자 변경을 보존했다.
- 이번 패킷은 커밋·스테이징·푸시하지 않았다.
- 작업 종료 시점의 브랜치와 HEAD는 위 메타데이터에 기록한 값이다.
