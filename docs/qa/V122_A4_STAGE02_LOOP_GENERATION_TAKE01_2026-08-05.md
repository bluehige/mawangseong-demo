# v1.2.2 A4 Stage 02 ambience loop generation take 01 QA

검수일: 2026-08-05
목표 버전: `1.2.2`
작업 브랜치: `codex/v122-ui-simplification`
패킷: `A4-STAGE-02-LOOP-GENERATION-TAKE01`

## 목적

승인된 범위에서 `ambience_stage02_indoor` Lyria 3 Pro take 1개를 생성하고, 후보 MP3·preview WAV·generation 기록을 검증한다. 후보는 `tmp/` 아래에만 남기며 사람 청취 승인 전에는 제품 source/runtime으로 승격하지 않는다.

## 생성 결과

- 실제 Lyria 3 Pro 요청: 1회
- 예상 비용: `$0.08`
- 생성 모델: `lyria-3-pro-preview`
- 실행 ID: `20260805_stage02_loop_take01`
- 후보 디렉터리: `tmp/lyria_audio_v122/20260805_stage02_loop_take01/ambience_stage02_indoor/take-01/`

| 파일 | 크기 | SHA-256 | 결과 |
|---|---:|---|---|
| `source.mp3` | 2,800,342 bytes | `2e30b35e5803d6a26c4a7b08c9e1c08c190e9c05762d609a42eaa2d1d192f25a` | PASS |
| `preview.wav` | 20,185,100 bytes | `7cf16c84d1f53c7502334fc5f06ff51eb65cc350580017b63748d964fb80f909` | PASS |
| `generation.json` | 1,430 bytes | 메타데이터 기록 | PASS |
| `preview.json` | 507 bytes | 렌더·해시 기록 | PASS |

## 후보 WAV 검증

- 채널: 2
- 샘플레이트: 44,100Hz
- 샘플 폭: 16-bit
- 실제 길이: 114.428초
- manifest 렌더 목표: 120초, 2초 crossfade, -8dBFS
- `preview.json`의 preview SHA-256과 실제 WAV 해시 일치
- `generation.json`의 source SHA-256과 실제 MP3 해시 일치
- 후보 파일 전체의 Google API 키 패턴: 0건
- API 키는 환경 변수로만 전달했고 실행 후 클립보드를 일반 문구로 덮었다.

## 직접 검수

```text
tmp/lyria_audio_venv/Scripts/python.exe tools/audio/lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json generate --asset ambience_stage02_indoor --takes 1 --run-id 20260805_stage02_loop_take01 --execute
generating asset=ambience_stage02_indoor take=1 model=lyria-3-pro-preview
preview=tmp/lyria_audio_v122/20260805_stage02_loop_take01/ambience_stage02_indoor/take-01/preview.wav

WAV 메타데이터·MP3/WAV SHA-256·키 패턴 검사
PASS
```

- 유료 요청: PASS — 1회, 예상 `$0.08`
- 후보 변환 및 기록: PASS
- 해시·WAV 구조·키 패턴: PASS
- runtime/source 승격: 실행하지 않음
- event catalog·GameRoot 연결: 실행하지 않음
- 전체 회귀·검수 에이전트·빌드·커밋·푸시: NOT_REQUESTED

## 결과

`A4_STAGE02_LOOP_GENERATION_TAKE01_PASS_PENDING_LISTENING`

후보 생성과 기계 검증은 통과했다. 사람 청취로 실내 공기·목재·금속 장치의 분위기, loop 이음새, 전투 타격·경고음과의 충돌, x3 밀도를 확인하기 전까지 최종 승인이나 승격으로 기록하지 않는다.

Review task ID: `NOT_REQUESTED`
Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
Remaining P1/P2: `N/A`
Final review result: `TARGETED_PASS`

## 다음 단계

- 다음 단일 패킷은 `A4-STAGE-02-LOOP-LISTENING-GATE`다.
- 사용자는 아래 preview WAV를 직접 듣고 `승인`, `재생성`, `폐기` 중 하나를 결정한다.
- 승인 전 `promote --confirm`, `assets/source/` 복사, runtime WAV 생성, catalog·GameRoot 연결은 금지한다.
