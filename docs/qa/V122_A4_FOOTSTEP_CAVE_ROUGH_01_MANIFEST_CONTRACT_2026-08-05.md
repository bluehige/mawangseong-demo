# v1.2.2 A4 거친 동굴석 발소리 01 manifest 계약 QA

검사일: 2026-08-05
목표 버전: `1.2.2`
작업 브랜치: `codex/v122-ui-simplification`
패킷: `A4-FOOTSTEP-CAVE-ROUGH-01-MANIFEST-CONTRACT`

## 목적

최대 품질 발소리 9개 중 첫 후보 `footstep_cave_rough_01` 한 개를 v1.2.2 Lyria manifest에 `planned`로 등록하고, 생성 모델·프롬프트·render·비용 계약을 유료 호출 없이 검증한다.

## 구현 결과

| 필드 | 값 |
|---|---|
| asset ID | `footstep_cave_rough_01` |
| runtime path | `assets/audio/sfx/footsteps/footstep_cave_rough_01.wav` |
| 상태 | `planned` |
| kind | `one_shot` |
| 모델 | `lyria-3-clip-preview` |
| render | mono, 44.1kHz, 0.28초, anchor 2.0초 |
| peak | -6.0 dBFS |
| 한 take 예상 비용 | `$0.04` |

프롬프트 계약은 거친 동굴석의 가벼운 한 걸음, 짧은 자갈 질감, 비음악적 저역 돌 울림을 요구하고 금속·목재·음성·멜로디·배경 ambience·긴 tail을 금지한다.

## 직접 테스트

```text
python tools/audio/test_lyria_pipeline.py
```

결과: `17 tests`, PASS.

```text
python tools/audio/lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json validate
```

결과: `manifest=OK assets=81 coverage=all-current-wav`.

```text
python tools/audio/lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json plan --asset footstep_cave_rough_01 --takes 1
python tools/audio/lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json generate --asset footstep_cave_rough_01 --takes 1
```

결과:

```text
lyria-3-clip-preview: requests=1
estimated_cost_usd=0.04
Dry run complete. Add --execute to make paid API calls.
```

`--execute`를 사용하지 않았으므로 Interactions API 호출·비용·후보 파일 생성은 모두 0회다.

## 회귀 경계

- manifest 총 항목: 81개 = active 80개 + planned 1개
- 2-take 전체 계획 비용: `$7.04`
- 새 runtime WAV가 없으므로 현재 runtime coverage 80개와 active manifest 경로가 일치한다.
- catalog·runtime·source·게임 코드·scheduler는 변경하지 않았다.
- 전체 회귀·전체 플레이·검수 에이전트는 아직 실행하지 않았다. 정식 후보 단계에서 수행한다.

## 판정

`A4_FOOTSTEP_CAVE_ROUGH_01_MANIFEST_CONTRACT_PASS_PENDING_GENERATION_APPROVAL`

다음 `A4-FOOTSTEP-CAVE-ROUGH-01-GENERATION-TAKE01`은 사용자에게 `$0.04` 유료 요청 1회 승인을 받은 뒤에만 실행한다.

정책 필드:

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 현재 작업 트리 미커밋`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
