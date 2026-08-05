# v1.2.2 출시 마무리 핸드오프 — V3 coal_spark 시트 앵커 12

## 기본 정보

- 대상 버전: 제품 `1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준/현재 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (미커밋 혼합 작업 트리)
- 패킷: `V3-GROUNDING-PROFILES-12`
- 결과: `PROFILE_CONNECT_PASS_WITH_SOURCE_PENDING`
- QA 문서: `docs/qa/V122_V3_GROUNDING_PROFILES_12_2026-08-05.md`

## 이번 패킷에서 한 일

`coal_spark` 투명 4×4 런타임 시트의 192×192 셀을 직접 측정했다. `Unit.gd` 시트 매핑에 따라 idle 셀 `(0,0)`의 발 앵커는 `0.90625`, down 셀 `(2,0)`의 발 앵커는 `0.942708`이며 alpha bbox는 각각 `[58,58,151,174]`, `[40,103,153,181]`이다.

기존 `DataRegistry`의 `normal_grounded` 런타임 병합 경로와 `Unit.gd`의 투명 시트 AtlasTexture 경로를 그대로 사용해 `motion_entry`와 `VisualBody` 위치가 이 값을 소비하는지 확인했다. 투명 시트의 chroma material 미적용과 기존 render scale은 유지했다.

원본 JSON의 `normalization_state`는 `NEEDS_NORMALIZATION`, `runtime_consumption_state`는 `PENDING_V3_PROFILE_CONNECT`로 남겼다. 따라서 이번 결과는 시트 런타임 연결·접지 앵커 검증 통과이며 원본 정규화 상태의 최종 승격을 의미하지 않는다.

## 변경 파일

- `data/v122/combat_visual_profiles.json`
- `tools/tests/V122CombatVisualRuntimeProfileContractTest.gd`
- `docs/qa/V122_V3_GROUNDING_PROFILES_12_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_12_2026-08-05.md`
- `docs/handoff/CURRENT.md`

## 검증 증거

- `V122_COMBAT_VISUAL_RUNTIME_PROFILE_CONTRACT_TEST: PASS`
- `V122_V3_COAL_SPARK_PROFILE_JSON_TEST: PASS`
- `git diff --check`: PASS

전체 회귀·전체 플레이·정식 빌드·커밋·원격 푸시는 이번 패킷에서 실행하지 않았다. 기존 사용자와 Luna의 미커밋 변경은 되돌리거나 정리하지 않았다.

## 미해결과 다음 순서

1. 다음 단일 패킷은 `V3-GROUNDING-PROFILES-13`으로 `dusk_courier` 한 캐릭터의 4×4 런타임 시트 idle/down 셀 앵커를 같은 경로로 처리한다.
2. `coal_spark`를 포함한 Update 4 원본 `NEEDS_NORMALIZATION` 상태의 최종 승격, 나머지 계약 캐릭터의 개별 프로필, 대표 동작, V4 전면 벽 가림은 이후 별도 패킷으로 남긴다.
3. V3 전체 동작과 대표 화면 검수가 끝나기 전에는 최종 `NORMALIZED_PASS`로 승격하지 않는다.

## 작업 트리와 정책

- 커밋: 생성하지 않음
- 원격 푸시: 하지 않음
- 작업 트리: 기존 미커밋 파일 포함, 혼합 상태 유지
- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
