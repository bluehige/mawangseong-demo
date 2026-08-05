# V1.2.2 Stage 03 환경음 loop 승격 QA

## 1. 패킷과 범위

- 패킷 ID: `A4-STAGE-03-LOOP-PROMOTE`
- 목표 버전: `v1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 작업 시작 기준 HEAD/마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 결과: `A4_STAGE03_LOOP_PROMOTE_PASS`

사용자가 청취 승인한 `ambience_stage03_keep` take 01만 제품 source/runtime으로 승격했다. 추가 Lyria 호출·추가 take·다른 Stage 자산·event catalog·GameRoot·AudioDirector 변경은 수행하지 않았다.

## 2. 승격 결과

| 구분 | 경로 | 상태 |
|---|---|---|
| 원본 | `assets/source/audio/lyria/v1.2.2/ambience_stage03_keep/source.mp3` | 존재·해시 기록 |
| 출처 기록 | `assets/source/audio/lyria/v1.2.2/ambience_stage03_keep/SOURCE.md` | 필수 출처 필드 기록 |
| 생성 기록 | `assets/source/audio/lyria/v1.2.2/ambience_stage03_keep/generation.json` | `store=false`, prompt/source SHA 기록 |
| 런타임 | `assets/audio/ambience/stage03_keep.wav` | 활성 런타임 파일 |
| 매니페스트 | `tools/audio/lyria_v122_manifest.json` | `ambience_stage03_keep.status=active` |

- Source MP3 SHA-256: `e0a9292ca72fa882509b19df068913c05ead1880628e01409e39c991ef730348`
- Runtime WAV SHA-256: `6abaec6c11e9a152b0f161ab8a73dd2f4a7d4c1f1467c7e321f65e8088b436f9`
- Runtime WAV: stereo, 44,100 Hz, 16-bit, 112.285714초
- 생성 모델: `lyria-3-pro-preview`
- 원본 생성 요청: 이전 청취 승인 패킷의 take 01을 사용했으며 새 유료 호출은 하지 않았다.

## 3. 직접 검증

| 검사 | 명령 또는 방법 | 결과 |
|---|---|---|
| 승격 | `lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json promote --run tmp/lyria_audio_v122/20260805_stage03_loop_take01 --asset ambience_stage03_keep --take 1 --confirm` | PASS |
| 매니페스트 | `lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json validate` | PASS — `assets=79`, `coverage=all-current-wav` |
| 파이프라인 단위 테스트 | `tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_lyria_pipeline -v` | PASS — 15/15 |
| 제품 파일 대조 | source/runtime SHA, WAV 메타데이터, `manifest active`, `generation store=false` | PASS |
| 출처 필드 | `SOURCE.md` 모델·날짜·버전·source/runtime 경로·SynthID·승인 명령 기록 | PASS |
| 비밀값 점검 | source 기록·생성 기록의 API 키 패턴 검사 | PASS — 0건 |
| catalog 연결 | `data/audio/audio_event_catalog.json`의 Stage 03 ID 검색 | 미실행 — 다음 패킷 범위 |
| 전체 회귀·전체 플레이·검수 에이전트 | 이번 패킷에서 요청되지 않음 | `NOT_REQUESTED` |
| runtime 대표 화면·실제 게임 청취 | catalog·GameRoot 연결 이후 별도 범위 | `NOT_REQUESTED` |

## 4. 변경 경로

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `assets/audio/ambience/stage03_keep.wav` | 승인 preview를 제품 runtime으로 승격 | 완료 |
| `assets/source/audio/lyria/v1.2.2/ambience_stage03_keep/source.mp3` | 승인 source 보존 | 완료 |
| `assets/source/audio/lyria/v1.2.2/ambience_stage03_keep/SOURCE.md` | 생성 출처·권리·승인 기록 | 완료 |
| `assets/source/audio/lyria/v1.2.2/ambience_stage03_keep/generation.json` | 생성 메타데이터 보존 | 완료 |
| `tools/audio/lyria_v122_manifest.json` | Stage 03 자산 상태를 `active`로 전환 | 완료 |
| `tools/audio/test_lyria_pipeline.py` | 승격 후 Stage 03 runtime 계약 반영 | 완료 |
| `docs/qa/V122_A4_STAGE03_LOOP_PROMOTE_2026-08-05.md` | 승격 QA 기록 | 완료 |
| `docs/handoff/V122_RELEASE_POLISH_A4_STAGE03_LOOP_PROMOTE_2026-08-05.md` | 세션 핸드오프 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 catalog 패킷 갱신 | 완료 |

## 5. 미해결과 다음 순서

현재 Stage 03 음원은 제품 source/runtime과 manifest에 있지만 event catalog 및 게임 runtime 재생에는 아직 연결하지 않았다. 다음은 `A4-STAGE-03-LOOP-CATALOG-CONNECT` 단일 패킷으로 catalog 이벤트 한 개를 등록하고 catalog 계약 테스트만 실행한다. GameRoot 연결과 대표 화면·실제 청취는 그 이후 별도 패킷이다.

## 6. 정책 기록

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
