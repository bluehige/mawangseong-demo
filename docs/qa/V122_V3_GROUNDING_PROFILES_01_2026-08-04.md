# V122 V3-GROUNDING-PROFILES-01 — slime·thief 개별 발 앵커 측정

검수일: 2026-08-04
대상 버전: 제품 1.2.2
패킷: `V3-GROUNDING-PROFILES-01`
판정: **PROFILE_ANCHOR_DATA_PASS_WITH_RUNTIME_CONNECT_PENDING**

## 패킷 카드

```text
PACKET_ID: V3-GROUNDING-PROFILES-01
GOAL: slime·thief 두 캐릭터의 개별 down 발 앵커만 프로필에 채우고 직접 테스트로 확인
ALLOWED_WRITE_PATHS:
  - data/v122/combat_visual_profiles.json
  - tools/tests/V122CombatVisualHierarchyTest.gd
  - docs/qa/V122_V3_GROUNDING_PROFILES_01_2026-08-04.md
  - docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_01_2026-08-04.md
  - docs/handoff/CURRENT.md
FORBIDDEN: Unit.gd·공통 렌더 구조·다른 캐릭터 프로필·V2 자산 재생성·V4 가림·UI/VFX·오디오·다음 V3 프로필 패킷·전체 회귀·빌드
DIRECT_TEST: slime·thief의 idle/move/attack/skill/down 발 기준, 개별 down 앵커 root 고정, 기존 계층 테스트 직접 확인
UI_OR_AUDIO_CHECK: 없음 — 두 원본의 알파 경계 측정과 계약 테스트만 확인
STOP_AFTER: 두 캐릭터의 프로필 앵커 1개 패킷과 직접 테스트·QA·핸드오프 기록 후 중단
```

## 측정 기준

두 캐릭터의 192×192 런타임 프레임에서 알파가 0보다 큰 영역의 경계 상자(bottom exclusive)를 읽었다. `foot_anchor.y`는 `bbox_bottom / frame_height`로 계산했으며, 발 기준 허용 오차는 2픽셀이다.

| 캐릭터 | idle bbox | idle 발 y | down bbox | down 발 y | 상태 |
|---|---|---:|---|---:|---|
| `slime` | `[29, 71, 169, 181]` | `0.942708` | `[76, 25, 181, 185]` | `0.963542` | 측정 완료, 연결 대기 |
| `thief` | `[35, 24, 155, 173]` | `0.901042` | `[24, 51, 172, 138]` | `0.718750` | 측정 완료, 연결 대기 |

이 값은 공통 `grounded` 모드의 기본 앵커와 별개로 캐릭터별 포즈 차이를 보존한다. 특히 도둑의 down 프레임은 쓰러진 자세라 bottom이 idle보다 크게 위로 올라가므로 공통 앵커를 그대로 사용하면 몸이 바닥에서 뜬다.

## 변경 내용

`data/v122/combat_visual_profiles.json`의 `unit_overrides.slime`과 `unit_overrides.thief`에 `grounding_anchors`를 추가했다. 각 항목에는 프레임 크기, idle/down 앵커, 실제 alpha bbox, 측정식, 허용 오차와 `PENDING_V3_PROFILE_CONNECT` 상태를 함께 기록했다.

공통 렌더 코드가 금지된 패킷이므로 이 turn에서는 새 데이터를 `motion_entry`로 병합하지 않았다. 현재 런타임은 공통 앵커를 계속 사용하며, 다음 별도 연결 패킷에서 두 캐릭터 데이터만 런타임 프로필로 주입한다.

## 직접 실행한 검수

- `godot.cmd --headless --path . --scene tools/tests/V122CombatVisualHierarchyTest.tscn --quit-after 30`
  - `V122_COMBAT_VISUAL_HIERARCHY_TEST: PASS`
  - 두 원본의 alpha bbox 재측정, 프로필 값 일치, 개별 앵커 상태를 확인했다.
- `godot.cmd --headless --path . --scene tools/tests/V122CombatVisualProfileContractTest.tscn --quit-after 30`
  - `V122_COMBAT_VISUAL_PROFILE_CONTRACT_TEST: PASS`
- Python JSON 구문 확인: `V122_V3_PROFILE_JSON_TEST: PASS`
- `git diff --check`: PASS

참고로 기존 `V122CombatVisualRuntimeProfileContractTest`는 공통 V3 구조 이전의 `unit.sprite.position`과 프로필 키를 기대해 실패했다. 이번 패킷의 허용 경로 밖인 공통 연결·기존 계약 테스트 보정 문제이며 이번 데이터 패킷에서는 수정하지 않았다.

전체 회귀, 전체 플레이, 1280×720 실제 게임 캡처, 빌드, 커밋, 푸시는 이번 패킷 범위가 아니므로 실행하지 않았다.

## 정책 기록

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A` (혼합 미커밋 작업 트리)
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
