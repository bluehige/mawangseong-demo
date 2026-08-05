# V122 A4 Stage 02 환경 loop 승격 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `v1.2.2`
- 패킷 ID: `A4-STAGE-02-LOOP-PROMOTE`
- 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치와 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 작업 결과: `TARGETED_PASS`

## 2. 목표와 완료 조건

사용자가 청취 승인한 Stage 02 환경음 take 01 하나를 제품 source/runtime 경로로 승격하고, 출처 기록·생성 기록·v1.2.2 매니페스트·직접 테스트를 일치시켰다. 추가 생성이나 게임 연결은 이 패킷의 범위가 아니다.

## 3. 완료 내용

- `ambience_stage02_indoor`를 `--confirm` 승격 명령으로 처리했다.
- 원본 MP3, `SOURCE.md`, `generation.json`, 런타임 WAV를 보존했다.
- 매니페스트의 Stage 02 항목을 `planned`에서 `active`로 바꿨다.
- Lyria 파이프라인 테스트가 활성 runtime coverage를 검사하도록 Stage 02 승격 기대값을 정렬했다.
- source/runtime SHA-256과 WAV 형식을 재검증했다.

## 4. 변경 경로

- `assets/audio/ambience/stage02_indoor.wav`
- `assets/source/audio/lyria/v1.2.2/ambience_stage02_indoor/source.mp3`
- `assets/source/audio/lyria/v1.2.2/ambience_stage02_indoor/SOURCE.md`
- `assets/source/audio/lyria/v1.2.2/ambience_stage02_indoor/generation.json`
- `tools/audio/lyria_v122_manifest.json`
- `tools/audio/test_lyria_pipeline.py`
- `docs/qa/V122_A4_STAGE02_LOOP_PROMOTE_2026-08-05.md`
- `docs/handoff/CURRENT.md`

## 5. 오디오 자산과 출처

- 자산 ID: `ambience_stage02_indoor`
- 생성 모델: `lyria-3-pro-preview`
- 원본 경로: `assets/source/audio/lyria/v1.2.2/ambience_stage02_indoor/source.mp3`
- 런타임 경로: `assets/audio/ambience/stage02_indoor.wav`
- 원본 SHA-256: `2e30b35e5803d6a26c4a7b08c9e1c08c190e9c05762d609a42eaa2d1d192f25a`
- 런타임 SHA-256: `7cf16c84d1f53c7502334fc5f06ff51eb65cc350580017b63748d964fb80f909`
- 런타임 형식: stereo / 44,100 Hz / 16-bit / 114.428초
- `SOURCE.md`에는 `Generation model`, `Generated date`, `Target version`, `Source audio path`, `Runtime audio path`와 SHA-256, SynthID watermark, 명시적 promote 승인 기록이 있다.
- `generation.json`에는 `store=false`와 prompt/source SHA가 있다.

## 6. 테스트와 검수

- `tmp/lyria_audio_venv/Scripts/python.exe tools/audio/lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json validate` — PASS (`assets=78`, `coverage=all-current-wav`)
- `tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_lyria_pipeline -v` — PASS (14/14)
- 제품 파일 대조 — PASS (매니페스트 active, source/runtime 해시 일치, stereo 44.1kHz 16-bit)
- 전체 회귀·전체 플레이·검수 에이전트 — `NOT_REQUESTED`
- runtime 대표 화면·실제 청취 — 다음 연결 패킷으로 분리, 이번 패킷에서는 `NOT_REQUESTED`

정책 필드:

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 미해결 문제

- Stage 02 음원 event catalog 등록 전이다.
- GameRoot/AudioDirector runtime 재생 연결 전이다.
- 대표 화면과 실제 게임 청취 확인 전이다.
- 전체 출시 검수와 최종 커밋·푸시는 별도 범위다.

## 8. 다음 작업 순서

다음 단일 패킷만 제안한다.

`A4-STAGE-02-LOOP-CATALOG-CONNECT`

- 목표: `ambience_stage02_indoor` 이벤트 한 개를 catalog에 등록하고 catalog 계약 테스트를 통과시킨다.
- 허용 경로: `data/audio/audio_event_catalog.json`, `tools/audio/test_audio_event_catalog.py`, 해당 QA/핸드오프 문서, `docs/handoff/CURRENT.md`
- 금지: 추가 음원 생성, source/runtime 변경, GameRoot, AudioDirector, Stage 01/03/04, 발소리, 다음 패킷 자동 실행
- runtime 재생과 대표 청취는 catalog 패킷 완료 후 별도 연결 패킷에서 진행한다.

## 9. 작업 트리

- 혼합 작업 트리이며 기존 사용자 변경을 보존했다.
- 이번 패킷은 커밋·스테이징·푸시하지 않았다.
- 작업 종료 시점의 브랜치와 HEAD는 위 메타데이터에 기록한 값이다.
