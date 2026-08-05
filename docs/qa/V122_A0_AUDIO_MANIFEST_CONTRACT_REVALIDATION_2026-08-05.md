# v1.2.2 A0 오디오 manifest 계약 재검증

검수일: 2026-08-05
대상 브랜치: `codex/v122-ui-simplification`
기준 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 범위

A0 선행 작업을 승인된 출시 결과로 승격하지 않고, v1.2.2 manifest의 선언·현재 런타임 WAV 범위·생성 안전장치를 다시 확인했다. 네트워크 요청, 유료 생성, 후보 청취, `promote --confirm`, 런타임 WAV 덮어쓰기는 실행하지 않았다.

## 검증 결과

```text
python tools/audio/lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json validate
manifest=OK assets=76 coverage=all-current-wav

python tools/audio/lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json plan
target_version=v1.2.2 assets=76 takes=2
lyria-3-clip-preview: requests=146
lyria-3-pro-preview: requests=6
estimated_cost_usd=6.32
Interactions API calls are not made unless generate --execute is present.

python -m json.tool tools/audio/lyria_v122_manifest.json
PASS

godot.cmd --headless --path . --script tools/tests/V122A0AudioManifestContractTest.gd --quit-after 30
V122_A0_AUDIO_MANIFEST_CONTRACT_TEST: PASS (13 checks)
```

추가로 이전 `tools/audio/lyria_v05_manifest.json`의 SHA-256은 다음과 같이 유지된다.

```text
B3D17C58746448439F92886C81D01DCAC129E059FEA663AA02024F77D04C47F3
```

manifest가 선언한 자산 수와 `assets/audio/**/*.wav` 실제 파일 수는 모두 76개다. `assets/source/audio/lyria/v1.2.2/`는 향후 생성 승인 전용 경로이므로 현재 존재하지 않으며, 이를 검증 실패로 처리하지 않는다.

## 실제 변경 경로

- `tools/tests/V122A0AudioManifestContractTest.gd`
- `docs/qa/V122_A0_AUDIO_MANIFEST_CONTRACT_REVALIDATION_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_A0_AUDIO_MANIFEST_CONTRACT_REVALIDATION_2026-08-05.md`
- `docs/handoff/CURRENT.md`

manifest와 파이프라인 구현 자체는 이번 재검증에서 수정하지 않았다.

## 미해결 및 다음 순서

- 76개 음원의 사람 청취·승인 상태는 여전히 `pending`이다.
- 실제 생성·승격은 사용자 비용·청취 승인 뒤 별도 패킷에서만 실행한다.
- 다음 패킷은 계획 순서의 `A1-A-AUDIO-EVENT-CATALOG`이며, manifest 자산과 실제 호출 event를 양방향으로 다시 검증한다.

## 정책 판정

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
