# v1.2.2 A4 Stage 02 ambience loop manifest contract QA

검수일: 2026-08-05
목표 버전: `1.2.2`
작업 브랜치: `codex/v122-ui-simplification`
패킷: `A4-STAGE-02-LOOP-MANIFEST-CONTRACT`

## 목적

Stage 02 환경음 1개를 Lyria 생성 전 `planned` 상태로 v1.2.2 manifest에 등록하고, 기존 77개 runtime WAV coverage를 유지하면서 환경 loop 계약과 비용 dry-run을 확인한다. 이번 패킷에서는 유료 API 호출, source/runtime 승격, event catalog 연결, 게임 연결을 하지 않는다.

## 변경 내용

- `ambience_stage02_indoor`를 `stage_02_indoor`용 `ambience_loop` planned 항목으로 등록했다.
- 예정 runtime 경로는 `assets/audio/ambience/stage02_indoor.wav`이며, 아직 파일을 만들지 않았다.
- Stage 02 brief는 낮은 실내 공기, 드문 목재 삐걱임, 절제된 목재·금속 장치음으로 고정했다.
- 환경 loop 렌더 계약은 Stage 01과 동일하게 스테레오, 44.1kHz, 120초, 2초 crossfade, -8dBFS로 설정했다.
- 테스트가 planned 항목을 runtime coverage에 포함시키지 않도록 active 경로만 비교하고, 전체 manifest 78개와 Lyria Pro 5개 비용을 검증하도록 정렬했다.

## 직접 검수

```text
tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_lyria_pipeline -v
Ran 14 tests ... OK

tmp/lyria_audio_venv/Scripts/python.exe tools/audio/lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json validate
manifest=OK assets=78 coverage=all-current-wav

tmp/lyria_audio_venv/Scripts/python.exe tools/audio/lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json generate --asset ambience_stage02_indoor --takes 1 --run-id 20260805_stage02_contract_dryrun
target_version=v1.2.2 assets=1 takes=1
lyria-3-pro-preview: requests=1
estimated_cost_usd=0.08
Dry run complete. Add --execute to make paid API calls.
```

- 단위 테스트: PASS — 14개
- manifest 검증: PASS — 78개 항목, 현재 runtime WAV coverage 일치
- Stage 02 dry-run: PASS — 유료 호출 0회, 예상 1회 `$0.08`
- dry-run 산출물: 생성되지 않음
- UI·실플레이·청취: NOT_REQUESTED — 아직 runtime 자산이 없는 계획 계약 패킷
- 전체 회귀·검수 에이전트·빌드·커밋·푸시: NOT_REQUESTED

## 결과

`A4_STAGE02_LOOP_MANIFEST_CONTRACT_PASS`

Stage 02 환경 loop 1개가 생성 가능한 planned manifest 항목으로 등록됐고, 현재 77개 WAV와의 coverage·프롬프트·비용 계약이 통과했다. 이번 패킷에서는 API 키를 사용하지 않았고 외부 네트워크·유료 호출도 없었다.

Review task ID: `NOT_REQUESTED`
Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
Remaining P1/P2: `N/A`
Final review result: `TARGETED_PASS`

## 미해결 및 다음 순서

- `ambience_stage02_indoor` 후보 음원, source 기록, runtime WAV는 아직 없다.
- 다음 단일 패킷은 `A4-STAGE-02-LOOP-GENERATION-TAKE01`이며 Lyria 3 Pro take 1개 생성만 다룬다.
- 생성 예상 비용은 1회 `$0.08`이다. `--execute` 유료 호출은 별도 승인 범위로 남긴다.
- 생성 후에는 후보 청취·승인, promote, catalog 연결, Stage 02 runtime 연결을 각각 별도 패킷으로 나눈다.
