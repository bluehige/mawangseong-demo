# v1.2.2 출시 마무리 핸드오프 — V3 공통 접지 구조

## 기본 정보

- 대상 버전: 제품 `1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준/현재 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (미커밋 혼합 작업 트리)
- 패킷: `V3-GROUNDING-STRUCTURE`
- 결과: `GROUNDING_STRUCTURE_PASS_WITH_PROFILE_FOLLOWUP`
- QA 문서: `docs/qa/V122_V3_GROUNDING_STRUCTURE_2026-08-04.md`

## 완료 내용

유닛의 월드 위치를 바닥 root로 고정하고 `VisualBody` 자식 노드를 새로 둬 스프라이트만 포즈를 수행하도록 구조를 분리했다. root가 직접 그리는 접지 그림자와 선택 표시는 이동·공격·피격·스킬 포즈와 독립적이다.

전투 시각 프로필의 `foot_anchor`, `down_foot_anchor`, `bob_limit_px`, `shadow_offset_px`, `shadow_scale`을 사용하도록 연결했다. 지상 이동의 수직 bob은 제거하고 지상 포즈 오차를 2픽셀 이내로 제한했으며, 비행형은 프로필 태그와 비행 bob을 유지한다.

사망 전환 시 down 포즈와 전용 발 앵커를 즉시 적용해 기존 서 있는 포즈가 한 프레임 남는 문제도 막았다.

## 변경 파일

- `scripts/units/Unit.gd`
- `data/v122/combat_visual_profiles.json`
- `tools/tests/V122CombatVisualHierarchyTest.gd`
- `docs/qa/V122_V3_GROUNDING_STRUCTURE_2026-08-04.md`
- `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_STRUCTURE_2026-08-04.md`
- `docs/handoff/CURRENT.md`

## 검증 증거

- `V122_COMBAT_VISUAL_HIERARCHY_TEST: PASS`
- `V122_COMBAT_VISUAL_PROFILE_CONTRACT_TEST: PASS`
- 프로필 JSON 구문 검사: PASS
- `git diff --check`: PASS

실제 1280×720 게임 캡처, 전체 회귀·전체 플레이·정식 빌드·커밋·푸시는 이번 패킷에서 실행하지 않았다. 현재 작업 트리에는 사용자와 Luna의 기존 미커밋 변경이 섞여 있으므로 되돌리거나 정리하지 않았다.

## 남은 작업과 다음 순서

1. 공통 구조는 통과했지만 모든 활성 캐릭터의 개별 down 프레임 발 앵커는 아직 채우지 않았다.
2. 다음 단일 패킷은 `V3-GROUNDING-PROFILES-01`이며 `slime`·`thief` 두 캐릭터의 개별 발 앵커만 프로필과 직접 테스트에 추가한다.
3. V3 프로필 패킷을 모두 끝내기 전에는 V2 자산을 최종 `NORMALIZED_PASS`로 올리지 않는다.

## 작업 트리와 정책

- 커밋: 생성하지 않음
- 원격 푸시: 하지 않음
- 작업 트리: 기존 미커밋 파일 포함, 혼합 상태 유지
- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
