# v1.2.2 A4 Stage 03 ambience loop manifest contract QA

검수일: 2026-08-05
목표 버전: `1.2.2`
작업 브랜치: `codex/v122-ui-simplification`
패킷: `A4-STAGE-03-LOOP-MANIFEST-CONTRACT`

## 목적

Stage 03 환경음 1개를 Lyria 생성 전 `planned` 상태로 manifest에 등록하고, 기존 runtime WAV coverage·프롬프트·비용 계약을 확인한다. 이번 패킷에서는 유료 API 호출, 음원 생성, source/runtime 승격, event catalog 연결, GameRoot 연결을 하지 않는다.

## 변경 내용

- `ambience_stage03_keep`를 `stage_03_keep`용 `ambience_loop` planned 항목으로 등록했다.
- 예정 runtime 경로는 `assets/audio/ambience/stage03_keep.wav`이며, 이번 패킷에서는 생성하지 않는다.
- brief는 높은 석조 성채의 차가운 공기, 먼 깃발·사슬 움직임, 드문 석조 잔향으로 고정했다.
- 렌더 계약은 스테레오, 44.1kHz, 120초, 2초 crossfade, -8dBFS로 Stage 01·02와 맞춘다.
- 전체 manifest 수량·Lyria Pro 수량·2-take 예상 비용을 Stage 03 planned 항목에 맞춰 갱신했다.

## 직접 검수

```text
tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_lyria_pipeline -v

tmp/lyria_audio_venv/Scripts/python.exe tools/audio/lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json validate

tmp/lyria_audio_venv/Scripts/python.exe tools/audio/lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json generate --asset ambience_stage03_keep --takes 1 --run-id 20260805_stage03_contract_dryrun
```

예상 결과:

- 단위 테스트: 15개 PASS
- manifest 검증: 79개 항목, active runtime WAV coverage 일치
- Stage 03 dry-run: 유료 호출 0회, 예상 1회 `$0.08`

## 결과

`A4_STAGE03_LOOP_MANIFEST_CONTRACT_PASS`

Stage 03 환경 loop 1개가 생성 가능한 planned manifest 항목으로 등록됐다. 이번 패킷은 계약만 다루며 실제 생성·청취·승격은 다음 패킷으로 분리한다.

Review task ID: `NOT_REQUESTED`
Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
Remaining P1/P2: `N/A`
Final review result: `TARGETED_PASS`

## 미해결 및 다음 순서

- `ambience_stage03_keep` 후보 음원, source 기록, runtime WAV는 아직 없다.
- 다음 단일 패킷은 `A4-STAGE-03-LOOP-GENERATION-TAKE01`이며 Stage 03 take 1개 생성만 다룬다.
- 생성 후보의 청취·승인, 승격, catalog 연결, runtime 연결은 각각 별도 패킷으로 유지한다.
