# v1.2.2 출시 마무리 핸드오프 — V3 개별 발 앵커 01

## 기본 정보

- 대상 버전: 제품 `1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준/현재 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (미커밋 혼합 작업 트리)
- 패킷: `V3-GROUNDING-PROFILES-01`
- 결과: `PROFILE_ANCHOR_DATA_PASS_WITH_RUNTIME_CONNECT_PENDING`
- QA 문서: `docs/qa/V122_V3_GROUNDING_PROFILES_01_2026-08-04.md`

## 이번 패킷에서 한 일

`slime`과 `thief`의 192×192 idle/down 프레임을 실제로 읽어 캐릭터별 발 기준을 측정했다. slime은 idle `0.942708`, down `0.963542`, 도둑은 idle `0.901042`, down `0.718750`이다. 두 캐릭터의 실제 alpha bbox와 측정식을 함께 전투 시각 프로필에 기록했다.

이번 패킷은 데이터·직접 테스트만 다뤘다. 공통 렌더 코드는 금지되어 있어 런타임 `motion_entry` 병합은 다음 연결 패킷으로 분리했다. 따라서 현재 두 캐릭터의 런타임은 공통 앵커를 사용하며, 이 핸드오프의 결과는 자산 측정·프로필 데이터 기준선 통과와 런타임 연결 대기다.

## 변경 파일

- `data/v122/combat_visual_profiles.json`
- `tools/tests/V122CombatVisualHierarchyTest.gd`
- `docs/qa/V122_V3_GROUNDING_PROFILES_01_2026-08-04.md`
- `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_01_2026-08-04.md`
- `docs/handoff/CURRENT.md`

## 검증 증거

- `V122_COMBAT_VISUAL_HIERARCHY_TEST: PASS`
- `V122_COMBAT_VISUAL_PROFILE_CONTRACT_TEST: PASS`
- 프로필 JSON 구문 검사: PASS
- `git diff --check`: PASS
- 기존 `V122CombatVisualRuntimeProfileContractTest`: FAIL — 공통 V3 구조 이전의 sprite 직접 위치 기대와 현재 구조가 불일치. 이번 패킷의 허용 경로 밖이라 수정하지 않음.

## 미해결과 다음 순서

1. 다음 단일 패킷 `V3-GROUNDING-PROFILES-CONNECT-01`에서 `slime`·`thief`의 `grounding_anchors`를 런타임 `motion_entry`에 병합한다.
2. 같은 패킷에서 두 캐릭터의 runtime profile 계약 테스트가 새 body/root 구조와 개별 idle/down 앵커를 검사하도록 보정한다.
3. 다른 캐릭터, V4 가림, VFX/UI 앵커는 이 순서가 끝난 뒤에만 연다.

## 작업 트리와 정책

- 커밋: 생성하지 않음
- 원격 푸시: 하지 않음
- 작업 트리: 기존 미커밋 파일 포함, 혼합 상태 유지
- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
