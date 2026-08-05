# v1.2.2 A4 Stage 04 ambience loop manifest contract QA

검수일: 2026-08-05
목표 버전: `1.2.2`
작업 브랜치: `codex/v122-ui-simplification`
패킷: `A4-STAGE-04-LOOP-MANIFEST-CONTRACT`

## 목적

Stage 04 환경음 1개를 Lyria 생성 전 `planned` 상태로 manifest에 등록하고, 기존 runtime WAV coverage·프롬프트·비용 계약을 확인한다. 이번 패킷에서는 유료 API 호출, 음원 생성, source/runtime 승격, event catalog 연결, GameRoot 연결, 대표 화면 확인을 하지 않는다.

## 변경 내용

- `ambience_stage04_citadel`을 `stage_04_citadel`용 `ambience_loop` planned 항목으로 등록했다.
- 예정 runtime 경로는 `assets/audio/ambience/stage04_citadel.wav`이며, 이번 패킷에서는 파일을 생성하지 않았다.
- brief는 깊은 석조 공명의 거대한 공간, 심장처럼 느껴지는 기계성 저음, 기초부의 느린 압력, 고대 장치의 드문 금속 움직임으로 고정했다.
- 렌더 계약은 스테레오, 44.1kHz, 120초, 2초 crossfade, -8dBFS로 Stage 01~03과 맞췄다.
- manifest는 총 80개 항목(활성 79개·planned 1개), Lyria Pro 7개, 기본 2-take 예상 비용 `$6.96`으로 정렬했다.

## 직접 검수

```text
tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_lyria_pipeline -v

tmp/lyria_audio_venv/Scripts/python.exe tools/audio/lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json validate

tmp/lyria_audio_venv/Scripts/python.exe tools/audio/lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json generate --asset ambience_stage04_citadel --takes 1 --run-id 20260805_stage04_contract_dryrun
```

## 결과

`A4_STAGE04_LOOP_MANIFEST_CONTRACT_PASS`

- 단위 테스트: 16개 PASS
- manifest 검증: `assets=80`, `active runtime coverage=79`, `planned=1`
- Stage 04 dry-run: 유료 호출 0회, 예상 1회 `$0.08`
- Stage 04 runtime WAV: 아직 없음
- Stage 04 source 기록: 아직 없음

Review task ID: `NOT_REQUESTED`
Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
Remaining P1/P2: `N/A`
Final review result: `TARGETED_PASS`

## 미해결 및 다음 순서

- `ambience_stage04_citadel` 후보 음원, source 기록, runtime WAV는 아직 없다.
- 다음 단일 패킷은 `A4-STAGE-04-LOOP-GENERATION-TAKE01`이다.
- 다음 패킷은 사용자 승인 후 Lyria Pro 유료 요청 1회만 실행하고, 후보 MP3/WAV·생성 기록·해시·형식·민감정보 패턴을 확인한다.
- 사용자 청취·승인, 승격, catalog 연결, runtime 연결은 각각 별도 패킷으로 유지한다.
