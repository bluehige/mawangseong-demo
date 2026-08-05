# v1.2.2 SOL 발소리 9종 묶음 청취 gate

검사일: 2026-08-05
목표 버전: `1.2.2`
작업 브랜치: `codex/v122-ui-simplification`
작업흐름: `SOL-V122-FOOTSTEPS-BATCH`

## 목적

Luna 전용 소형 패킷 제한을 SOL 연속 실행 방식으로 전환한 뒤, 거친 동굴석·다듬은 성벽석·금속 기계 통로의 발소리를 표면별 3변형, 총 9개 후보로 한 번에 준비한다. 이번 gate는 후보 생성·추출·기계 검증까지 수행하고, 사람 청취 승인 전에는 source/runtime 승격과 게임 연결을 하지 않는다.

## 생성 계약

| 항목 | 값 |
|---|---|
| 표면 | `cave_rough`, `castle_stone`, `metal_passage` |
| 표면별 변형 | 3개 |
| 후보 합계 | 9개 |
| 모델 | `lyria-3-clip-preview` |
| 출력 계약 | mono, 44.1kHz, 16bit, 약 0.26~0.32초, peak -6 dBFS |
| source reel 추출 지점 | 변형 01=`0:02`, 02=`0:07`, 03=`0:12` |
| 최초 공개 상한 | 9회, 예상 `$0.36` |
| 실제 성공 요청 | 4회, 예상 `$0.16` |
| 필터 차단 | 2회, 결과 파일 없음; 실제 과금 여부는 단정하지 않음 |

Lyria Clip 응답은 한 요청에 여러 변형을 담는 30초 source reel이다. 세 번째 동굴 cue가 두 번 연속 일반 콘텐츠 필터에 걸려 추가 재호출하지 않고, 성공한 4개 reel의 서로 다른 앵커를 사용해 9개 고유 후보를 추출했다. 이 방식은 최초 공개한 비용 상한을 넘지 않으며 같은 표면의 질감을 일관되게 유지한다.

## 후보와 청취 순서

표면별 review WAV에서는 `01 → 02 → 03` 순서로 각 cue가 두 번씩 재생된다.

| 표면 | review 파일 | 길이 | SHA-256 |
|---|---|---:|---|
| 거친 동굴석 | `tmp/lyria_audio_v122/20260805_footsteps_batch_listening/review_cave_rough.wav` | 3.800초 | `408c730fe20414b98d9e86ccca0e5c2eb030f596c469e011affc3774cdd4dee8` |
| 다듬은 성벽석 | `tmp/lyria_audio_v122/20260805_footsteps_batch_listening/review_castle_stone.wav` | 3.760초 | `dba45e0913cee18aa166afd67a38d564e6d0755fddedbdc2fee15425ddaabcfb` |
| 금속 기계 통로 | `tmp/lyria_audio_v122/20260805_footsteps_batch_listening/review_metal_passage.wav` | 3.960초 | `83e733aa176d745ffafab33dea8b1715178c1e08bd10ca4f219f86b7778db1af` |

개별 후보와 생성 매핑·해시는 `tmp/lyria_audio_v122/20260805_footsteps_batch_listening/verification.json`에 기록했다.

## 직접 검증 결과

| 검사 | 결과 |
|---|---|
| `python tools/audio/test_lyria_pipeline.py` | PASS, 19 tests |
| v1.2.2 manifest validate | PASS, 89 assets, active runtime coverage 일치 |
| 후보 수 | PASS, 9개 |
| 개별 preview SHA-256 | PASS, 9개 모두 고유 |
| source reel SHA-256 | PASS, 4개 고유 |
| WAV 형식 | PASS, 전부 mono·44.1kHz·16bit |
| 무음 후보 | PASS, 0개 |
| API 키 형식 문자열 | PASS, 후보 텍스트·JSON 0건 |
| 프로세스 환경·시스템 클립보드 정리 | PASS |

## 사용자 판정과 승격 결과

- 사용자 판정: `전체 승인`
- 승인 범위: 거친 동굴석·다듬은 성벽석·금속 기계 통로, 각 3변형 총 9개
- source/runtime 승격: 완료
- manifest 상태: 9개 모두 `active`
- catalog 상태: 9개 모두 `approved`·`actual_runtime`
- 런타임 연결: Stage별 surface, normal/heavy, 정지·비행 무음, 동시 voice 3개, x3 밀도 감소
- 대표 엔진 검증: `FootstepSchedulerTest` 31 assertions PASS

## 판정

`SOL_V122_FOOTSTEPS_RUNTIME_AND_SCHEDULER_TARGETED_PASS`

묶음 청취 승인과 source/runtime 승격, catalog 연결, 발소리 scheduler의 직접 검증까지 완료됐다. 전체 출시 검수와 Windows 후보 검증은 아직 기능 작업이 계속되는 다음 단계에서 수행한다.

정책 필드:

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 현재 작업 트리 미커밋`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
