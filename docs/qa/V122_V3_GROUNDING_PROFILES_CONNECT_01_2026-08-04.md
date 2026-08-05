# V122 V3-GROUNDING-PROFILES-CONNECT-01 — slime·thief 런타임 연결

검수일: 2026-08-04
대상 버전: 제품 1.2.2
패킷: `V3-GROUNDING-PROFILES-CONNECT-01`
판정: **PROFILE_CONNECT_PASS**

## 패킷 카드

```text
PACKET_ID: V3-GROUNDING-PROFILES-CONNECT-01
GOAL: slime·thief의 grounding_anchors를 런타임 motion_entry에 병합하고 새 body/root 구조 기준으로 계약 테스트를 보정
ALLOWED_WRITE_PATHS:
  - scripts/core/DataRegistry.gd
  - tools/tests/V122CombatVisualRuntimeProfileContractTest.gd
  - docs/qa/V122_V3_GROUNDING_PROFILES_CONNECT_01_2026-08-04.md
  - docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_CONNECT_01_2026-08-04.md
  - docs/handoff/CURRENT.md
FORBIDDEN: Unit.gd·JSON 자산값 변경·다른 캐릭터 프로필·자산 재생성·V4 가림·UI/VFX·오디오·다음 V3 프로필 패킷·전체 회귀·빌드
DIRECT_TEST: slime·thief runtime profile의 idle/down 앵커가 VisualBody/root 기준에 병합되는지와 기존 scale·sprite 경로 보존을 직접 확인
UI_OR_AUDIO_CHECK: 없음 — 런타임 프로필 계약만 확인
STOP_AFTER: 두 캐릭터 런타임 연결 1개 패킷과 계약 테스트·QA·핸드오프 기록 후 중단
```

## 구현 내용

- `DataRegistry.combat_visual_profile_for_unit()`가 `unit_overrides.<id>.grounding_anchors`를 읽어 반환 프로필의 `motion_entry.foot_anchor`와 `motion_entry.down_foot_anchor`에 병합한다.
- 공통 `motion_modes` 사전을 직접 변경하지 않도록 깊은 복사한 motion entry에만 적용한다. 따라서 slime·thief 보정이 다른 캐릭터에 번지지 않는다.
- 반환 프로필에도 `grounding_anchors` 원본을 함께 노출해 테스트와 후속 감사가 측정 근거를 추적할 수 있게 했다.
- 원본 JSON의 `runtime_consumption_state`는 이번 패킷에서 JSON 자산값을 수정하지 않는 규칙 때문에 `PENDING_V3_PROFILE_CONNECT`로 보존했다. 이번 패킷의 판정은 런타임 병합 경로가 실제로 소비하는지에 대한 `PROFILE_CONNECT_PASS`이며, 원본 상태 승격은 다음 프로필 패킷에서 별도로 다룬다.
- 런타임 계약 테스트는 이번 소형 패킷의 대상인 `slime`·`thief`만 실행한다. 전체 roster의 옛 기대값을 임의로 고치거나 다른 캐릭터를 연결하지 않았다.

## 직접 검수 결과

- `slime` runtime profile이 `idle_foot_anchor.y = 0.942708`, `down_foot_anchor.y = 0.963542`를 `motion_entry`에 반영한다.
- `thief` runtime profile이 `idle_foot_anchor.y = 0.901042`, `down_foot_anchor.y = 0.718750`을 `motion_entry`에 반영한다.
- 두 캐릭터 모두 `VisualBody`가 유닛 root의 자식이고, 스프라이트 local position은 0이다.
- 기존 runtime sprite 경로와 render scale은 그대로 유지된다.
- down 상태에서 body position이 전용 down 앵커로 계산되는 것을 확인했다.

## 실행한 테스트

- `godot.cmd --headless --path . --scene tools/tests/V122CombatVisualRuntimeProfileContractTest.tscn --quit-after 30`
  - `V122_COMBAT_VISUAL_RUNTIME_PROFILE_CONTRACT_TEST: PASS`
- `godot.cmd --headless --path . --scene tools/tests/V122CombatVisualHierarchyTest.tscn --quit-after 30`
  - `V122_COMBAT_VISUAL_HIERARCHY_TEST: PASS`
- `godot.cmd --headless --path . --scene tools/tests/V122CombatVisualProfileContractTest.tscn --quit-after 30`
  - `V122_COMBAT_VISUAL_PROFILE_CONTRACT_TEST: PASS`
- Python 프로필 JSON 검사: `V122_V3_PROFILE_JSON_TEST: PASS`
- `git diff --check`: PASS

전체 회귀, 전체 플레이, 1280×720 실제 게임 캡처, 빌드, 커밋, 푸시는 이번 패킷 범위가 아니므로 실행하지 않았다.

## 정책 기록

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A` (혼합 미커밋 작업 트리)
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
