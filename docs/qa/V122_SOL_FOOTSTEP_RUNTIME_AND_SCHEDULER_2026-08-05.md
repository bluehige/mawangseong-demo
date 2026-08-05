# v1.2.2 SOL 발소리 runtime·scheduler 검증

검사일: 2026-08-05
목표 버전: `1.2.2`
작업 브랜치: `codex/v122-ui-simplification`
작업흐름: `SOL-V122-FOOTSTEPS-BATCH`

## 결과

사용자가 표면별 review WAV 3개를 `전체 승인`했다. 승인된 9개 cue를 source/runtime로 승격하고, manifest·event catalog·GameRoot에 지형 및 유닛 체급 기반 발소리 scheduler를 연결했다.

## 구현 계약

| 항목 | 결과 |
|---|---|
| Stage 01 | `cave_rough` 3변형 |
| Stage 02·03 | `castle_stone` 3변형 |
| Stage 04 | `metal_passage` 3변형 |
| normal | -18.5dB, pitch 0.96/1.00/1.04 |
| heavy | -14.0dB, pitch 0.82/0.86/0.90 |
| heavy 판정 | `large`·`boss`, 또는 boss/tank/guardian role |
| 무음 조건 | 정지·사망·down·비행·화면 밖 |
| 동시 voice | 기존 allocator의 footstep 최대 3개 |
| x3 | 보폭 거리와 최소 간격을 늘려 실제 시간당 접촉 밀도 감소 |

변형은 유닛 instance ID에서 시작해 접촉마다 `01 → 02 → 03`으로 결정적 순환한다. 같은 실행을 다시 재현할 수 있고 무작위 난사로 반복 피로가 달라지지 않는다.

## 자산·출처

- 런타임: `assets/audio/sfx/footsteps/footstep_*.wav` 9개
- 원본·기록: `assets/source/audio/lyria/v1.2.2/footstep_*/`
- 생성 원본 lineage: 각 `SOURCE.md`에 source reel asset·run·anchor seconds 기록
- manifest: 89 assets, 발소리 9개 `active`
- catalog: 89 assets, 81 events, 발소리 9개 `approved`·`actual_runtime`
- 민감정보: source record·generation JSON에서 Google API 키 패턴 0건

## 직접 검증

| 검사 | 결과 |
|---|---|
| `python tools/audio/test_lyria_pipeline.py` | PASS, 19 tests |
| Lyria v1.2.2 manifest validate | PASS, 89 assets·전체 WAV coverage |
| `python tools/audio/test_audio_event_catalog.py` | PASS, 11 tests |
| `FootstepSchedulerTest.tscn` | PASS, 31 assertions |
| `MusicStateAudioTest.tscn` | PASS, 54 assertions |
| `AudioVoiceAllocatorTest.tscn` | PASS, 55 assertions |
| `CombatAudioDirectorRoutingTest.tscn` | PASS, 9 assertions |
| `git diff --check` 관련 범위 | PASS, 줄바꿈 경고만 있음 |

`AudioVoiceAllocatorTest`의 의도된 missing event/asset 진단은 테스트 계약에 포함된 예상 오류 로그이며 종료 코드는 0이다.

## 판정

`TARGETED_PASS`

발소리 승인·승격·연결은 완료됐다. 전체 회귀와 정식 Windows 후보는 남은 제품 작업을 닫고 기능 SHA를 고정한 뒤 수행한다.

정책 필드:

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 현재 작업 트리 미커밋`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
