# V122 A4 Stage 02 환경 loop 승격 QA

## 패킷과 범위

- 패킷 ID: `A4-STAGE-02-LOOP-PROMOTE`
- 목표 버전: `v1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 작업 시작 기준 HEAD/마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 결과: `A4_STAGE02_LOOP_PROMOTE_PASS`

사용자가 청취 승인한 `ambience_stage02_indoor` take 01만 제품 source/runtime으로 승격했다. 추가 Lyria 호출, 추가 take, 다른 Stage 자산, event catalog, GameRoot, AudioDirector 변경은 수행하지 않았다.

## 승격 결과

| 구분 | 경로 | 상태 |
|---|---|---|
| 원본 | `assets/source/audio/lyria/v1.2.2/ambience_stage02_indoor/source.mp3` | 존재·해시 기록 |
| 출처 기록 | `assets/source/audio/lyria/v1.2.2/ambience_stage02_indoor/SOURCE.md` | 생성 모델·날짜·버전·경로·해시·SynthID 기록 |
| 생성 기록 | `assets/source/audio/lyria/v1.2.2/ambience_stage02_indoor/generation.json` | `store=false`, prompt/source SHA 기록 |
| 런타임 | `assets/audio/ambience/stage02_indoor.wav` | 활성 런타임 파일 |
| 매니페스트 | `tools/audio/lyria_v122_manifest.json` | `ambience_stage02_indoor.status=active` |

- Source MP3 SHA-256: `2e30b35e5803d6a26c4a7b08c9e1c08c190e9c05762d609a42eaa2d1d192f25a`
- Runtime WAV SHA-256: `7cf16c84d1f53c7502334fc5f06ff51eb65cc350580017b63748d964fb80f909`
- Runtime WAV: stereo, 44,100 Hz, 16-bit, 114.428초
- 생성 모델: `lyria-3-pro-preview`
- 원본 생성 요청: 기존 승인된 take 01을 사용했으며 승격 명령에 `--confirm`을 명시했다.

## 직접 검증

| 검사 | 명령 또는 방법 | 결과 |
|---|---|---|
| 승격 | `lyria_pipeline.py ... promote --asset ambience_stage02_indoor --take 1 --confirm` | PASS |
| 매니페스트 | `lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json validate` | PASS — `assets=78`, `coverage=all-current-wav` |
| 파이프라인 단위 테스트 | `tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_lyria_pipeline -v` | PASS — 14/14 |
| 제품 파일 대조 | source/runtime SHA, WAV 메타데이터, `manifest active`, `generation store=false` | PASS |
| 비밀값 점검 | source/generation 기록의 API 키 패턴 검사 및 기존 파이프라인 보안 테스트 | PASS — 0건 |
| 전체 회귀·전체 플레이·검수 에이전트 | 이번 패킷에서 요청되지 않음 | `NOT_REQUESTED` |
| runtime 대표 화면·실제 청취 | 다음 별도 연결 패킷 범위 | `NOT_REQUESTED` |

## 미해결과 다음 순서

현재 Stage 02 음원은 제품 source/runtime에 있지만 event catalog 및 게임 runtime 재생에는 아직 연결하지 않았다. 다음은 `A4-STAGE-02-LOOP-CATALOG-CONNECT` 단일 패킷으로, catalog에 이 자산의 이벤트 한 개를 등록하고 catalog 계약 테스트만 실행한다. GameRoot 연결과 대표 화면·청취 확인은 그 이후 별도 패킷이다.

## 정책 기록

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A` — 전체 검수 미요청
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
