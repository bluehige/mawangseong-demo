# v1.2.2 출시 마무리 핸드오프 — V3 개별 발 앵커 런타임 연결 01

## 기본 정보

- 대상 버전: 제품 `1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준/현재 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (미커밋 혼합 작업 트리)
- 패킷: `V3-GROUNDING-PROFILES-CONNECT-01`
- 결과: `PROFILE_CONNECT_PASS`
- QA 문서: `docs/qa/V122_V3_GROUNDING_PROFILES_CONNECT_01_2026-08-04.md`

## 이번 패킷에서 한 일

`DataRegistry`가 `slime`·`thief`의 프로필별 `grounding_anchors`를 런타임 `motion_entry`로 병합하도록 연결했다. 깊은 복사한 motion entry에만 적용해 공통 grounded 모드가 오염되지 않도록 했으며, idle/down 앵커를 모두 반환 프로필에 노출했다.

원본 JSON의 `runtime_consumption_state`는 JSON 자산값을 건드리지 않는 이번 패킷 계약에 따라 `PENDING_V3_PROFILE_CONNECT`로 남겨 두었다. 따라서 이번 결과는 런타임 연결 경로의 `PROFILE_CONNECT_PASS`이고, 원본 상태를 `READY` 등으로 승격하는 일은 다음 개별 프로필 패킷의 별도 범위다.

기존 runtime profile 계약 테스트는 이번 패킷의 두 대상만 실행하도록 범위를 잠그고, `VisualBody` 부모·sprite local position 0·idle/down body 위치·기존 sprite path·render scale을 확인한다. 다른 캐릭터의 구형 기대값을 한 번에 고치지 않았다.

## 변경 파일

- `scripts/core/DataRegistry.gd`
- `tools/tests/V122CombatVisualRuntimeProfileContractTest.gd`
- `docs/qa/V122_V3_GROUNDING_PROFILES_CONNECT_01_2026-08-04.md`
- `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_CONNECT_01_2026-08-04.md`
- `docs/handoff/CURRENT.md`

## 검증 증거

- `V122_COMBAT_VISUAL_RUNTIME_PROFILE_CONTRACT_TEST: PASS`
- `V122_COMBAT_VISUAL_HIERARCHY_TEST: PASS`
- `V122_COMBAT_VISUAL_PROFILE_CONTRACT_TEST: PASS`
- 프로필 JSON 검사: PASS
- `git diff --check`: PASS

전체 회귀·전체 플레이·정식 빌드·커밋·원격 푸시는 이번 패킷에서 실행하지 않았다. 기존 사용자와 Luna의 미커밋 변경은 되돌리거나 정리하지 않았다.

## 미해결과 다음 순서

1. 다음 단일 패킷은 `V3-GROUNDING-PROFILES-02`이며 `explorer` 한 캐릭터의 개별 idle/down 발 앵커를 측정하고 같은 연결 경로를 재사용한다.
2. 다른 캐릭터의 발·UI/VFX 앵커, V4 전면 벽 가림은 이후 패킷에서 처리한다.
3. V3 전체 동작과 대표 화면 검수가 끝나기 전에는 최종 `NORMALIZED_PASS`로 승격하지 않는다.

## 작업 트리와 정책

- 커밋: 생성하지 않음
- 원격 푸시: 하지 않음
- 작업 트리: 기존 미커밋 파일 포함, 혼합 상태 유지
- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
