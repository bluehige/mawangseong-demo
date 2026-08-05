# V1.2.2 릴리스 폴리시 핸드오프 — A4 Stage 03 환경 loop 승격

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `v1.2.2`
- 패킷 ID: `A4-STAGE-03-LOOP-PROMOTE`
- 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치와 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 푸시 여부: 하지 않음
- 관련 PR 또는 태그: 없음
- 작업 결과: `TARGETED_PASS`

## 2. 목표와 완료 조건

사용자가 청취 승인한 Stage 03 환경음 take 01 하나를 제품 source/runtime으로 승격하고, 출처 기록·생성 기록·v1.2.2 manifest·직접 테스트를 일치시켰다. 추가 생성이나 게임 연결은 이 패킷의 범위가 아니다.

## 3. 완료 내용

- `ambience_stage03_keep`를 `--confirm` 승격 명령으로 처리했다.
- 원본 MP3, `SOURCE.md`, `generation.json`, 런타임 WAV를 보존했다.
- manifest의 Stage 03 항목을 `planned`에서 `active`로 바꿨다.
- Lyria 파이프라인 테스트를 승격 후 Stage 03 runtime 계약에 맞게 정렬했다.
- manifest validate와 15개 Lyria 파이프라인 단위 테스트를 통과했다.
- source/runtime SHA-256, WAV 형식, `store=false`, 비밀값 패턴 0건을 재검증했다.

## 4. 변경 경로

- `assets/audio/ambience/stage03_keep.wav`
- `assets/source/audio/lyria/v1.2.2/ambience_stage03_keep/source.mp3`
- `assets/source/audio/lyria/v1.2.2/ambience_stage03_keep/SOURCE.md`
- `assets/source/audio/lyria/v1.2.2/ambience_stage03_keep/generation.json`
- `tools/audio/lyria_v122_manifest.json`
- `tools/audio/test_lyria_pipeline.py`
- `docs/qa/V122_A4_STAGE03_LOOP_PROMOTE_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_A4_STAGE03_LOOP_PROMOTE_2026-08-05.md`
- `docs/handoff/CURRENT.md`

## 5. 오디오 자산과 출처

- 자산 ID: `ambience_stage03_keep`
- 생성 모델: `lyria-3-pro-preview`
- 원본 경로: `assets/source/audio/lyria/v1.2.2/ambience_stage03_keep/source.mp3`
- 런타임 경로: `assets/audio/ambience/stage03_keep.wav`
- 원본 SHA-256: `e0a9292ca72fa882509b19df068913c05ead1880628e01409e39c991ef730348`
- 런타임 SHA-256: `6abaec6c11e9a152b0f161ab8a73dd2f4a7d4c1f1467c7e321f65e8088b436f9`
- 런타임 형식: stereo / 44,100 Hz / 16-bit / 112.285714초
- `SOURCE.md`에는 `Generation model`, `Generated date`, `Target version`, `Source audio path`, `Runtime audio path`, SHA-256, SynthID watermark, 명시적 promote 승인 기록이 있다.
- `generation.json`에는 `store=false`와 prompt/source SHA가 있다.

## 6. 테스트와 검수

- `tmp/lyria_audio_venv/Scripts/python.exe tools/audio/lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json validate` — PASS (`assets=79`, `coverage=all-current-wav`)
- `tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_lyria_pipeline -v` — PASS (15/15)
- 제품 파일 대조 — PASS (manifest active, source/runtime 해시 일치, stereo 44.1kHz 16-bit)
- 비밀값 점검 — PASS (source/generation 기록 API 키 패턴 0건)
- 전체 회귀·전체 플레이·검수 에이전트 — `NOT_REQUESTED`
- catalog·GameRoot 연결 및 runtime 대표 화면 — 다음 패킷으로 분리, 이번 패킷에서는 `NOT_REQUESTED`

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | NOT_REQUESTED | N/A | N/A | 없음 | 없음 | QA 문서 | NOT_REQUESTED |

- 남은 P1/P2 지적: `N/A`
- 실행하지 못한 필수 검수와 이유: 전체 회귀·전체 플레이·검수 에이전트는 사용자 요청 범위가 아님
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이번 패킷의 승격과 문서 변경만 반영

### 정책 CI용 최종 승인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 미해결 문제

- Stage 03 음원 event catalog 등록 전이다.
- GameRoot/AudioDirector runtime 재생 연결 전이다.
- 대표 화면과 실제 게임 청취 확인 전이다.
- 전체 출시 검수와 최종 커밋·푸시는 별도 범위다.

## 8. 다음 작업 순서

다음 단일 패킷만 제안한다.

`A4-STAGE-03-LOOP-CATALOG-CONNECT`

- 목표: `ambience_stage03_keep` 이벤트 한 개를 catalog에 등록하고 catalog 계약 테스트를 통과시킨다.
- 허용 경로: `data/audio/audio_event_catalog.json`, `tools/audio/test_audio_event_catalog.py`, 해당 QA/핸드오프 문서, `docs/handoff/CURRENT.md`
- 금지: 추가 음원 생성, source/runtime 변경, GameRoot, AudioDirector, Stage 01/02/04, 발소리, 다음 패킷 자동 실행
- runtime 재생과 대표 청취는 catalog 패킷 완료 후 별도 연결 패킷에서 진행한다.

## 9. 작업 트리

- 혼합 작업 트리이며 기존 사용자·Luna 변경을 보존했다.
- 이번 패킷은 커밋·스테이징·푸시하지 않았다.
- 이번 패킷의 후보·제품 산출물은 `tmp/lyria_audio_v122/20260805_stage03_loop_take01/` 및 위 변경 경로에 있다.
- 다음 세션은 `docs/handoff/CURRENT.md`의 `A4-STAGE-03-LOOP-CATALOG-CONNECT`에서 시작한다.
