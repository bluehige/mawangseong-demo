# V122 V3 — 바닥 root·visual body 공통 구조 검수

검수일: 2026-08-04
대상 버전: 제품 1.2.2
패킷: `V3-GROUNDING-STRUCTURE`
판정: **GROUNDING_STRUCTURE_PASS_WITH_PROFILE_FOLLOWUP**

## 패킷 카드

```text
PACKET_ID: V3-GROUNDING-STRUCTURE
GOAL: 유닛의 바닥 root와 움직이는 body·그림자·선택 표시 기준을 공통 구조로 고정하고 직접 계약 테스트로 확인
ALLOWED_WRITE_PATHS:
  - scripts/units/Unit.gd
  - data/v122/combat_visual_profiles.json
  - tools/tests/V122CombatVisualHierarchyTest.gd
  - docs/qa/V122_V3_GROUNDING_STRUCTURE_2026-08-04.md
  - docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_STRUCTURE_2026-08-04.md
  - docs/handoff/CURRENT.md
FORBIDDEN: V2 자산 재생성·저알파 크로마 보정·V4 가림·UI/VFX·오디오·다음 V3 프로필 패킷·전체 회귀·빌드
DIRECT_TEST: 유닛 월드 위치=바닥 root, body 이동과 그림자·선택 표시 기준 분리, grounded/flying 프로필 기준 및 발 흔들림 계약을 기존 계층 테스트로 직접 확인
UI_OR_AUDIO_CHECK: 없음 — 공통 구조 계약 테스트만 실행
STOP_AFTER: 공통 접지 구조 1개와 직접 테스트·QA·핸드오프 기록 후 중단
```

## 구현 내용

- `UnitActor`의 월드 위치를 바닥 root로 유지하고, `VisualBody` 자식 노드 아래에 스프라이트를 배치했다. 따라서 이동·공격·피격·스킬 포즈는 body에만 적용되고 root의 그림자·선택 표시는 흔들리지 않는다.
- 스프라이트의 기준 위치를 절대 화면 픽셀이 아니라 전투 시각 프로필의 `foot_anchor`와 원본 프레임 크기로 계산한다. 스프라이트 확대·축소 때도 발 앵커를 다시 계산해 발이 root에서 분리되지 않게 했다.
- 지상 이동에서 의미 없는 수직 bob을 제거하고 `bob_limit_px: 2.0`으로 지상 포즈의 수직 오차를 제한했다. 비행형은 프로필의 `flying` 태그와 4픽셀 bob 제한을 유지한다.
- 쓰러짐은 `down_foot_anchor`를 사용한다. 그림자 오프셋·타원 비율도 프로필의 `shadow_offset_px`와 `shadow_scale`을 읽어 root에서 그린다.
- 사망 전환 순간에도 down 포즈를 즉시 적용해 다음 물리 프레임까지 기존 서 있는 위치가 남지 않게 했다.

이번 패킷은 공통 구조만 다뤘다. 모든 활성 캐릭터의 개별 down 프레임 발 앵커를 재측정하거나 자산을 다시 만드는 일은 다음 V3 프로필 패킷으로 남겼다.

## 직접 검수 결과

`V122CombatVisualHierarchyTest`에서 다음을 실제 `UnitActor` 인스턴스로 확인했다.

- `thief`의 월드 root 좌표가 이동 포즈에서도 바뀌지 않는다.
- `sprite`의 부모가 `VisualBody`이고 스프라이트 자체의 월드 기준 오프셋은 0이다.
- 지상 idle→move 발 위치 차이가 2픽셀 이내다.
- 지상 attack 발 위치 차이가 2픽셀 이내다.
- down 전용 앵커를 사용했을 때 쓰러짐 발도 root에서 2픽셀 이내다.
- `imp`는 데이터 프로필의 `motion_mode: flying`을 읽는다.

## 실행한 테스트

- `godot.cmd --headless --path . --scene tools/tests/V122CombatVisualHierarchyTest.tscn --quit-after 30`
  - `V122_COMBAT_VISUAL_HIERARCHY_TEST: PASS`
- `godot.cmd --headless --path . --scene tools/tests/V122CombatVisualProfileContractTest.tscn --quit-after 30`
  - `V122_COMBAT_VISUAL_PROFILE_CONTRACT_TEST: PASS`
- Python JSON 구문 확인: `data/v122/combat_visual_profiles.json` 로드 PASS
- `git diff --check`: PASS

전체 회귀, 전체 플레이, 1280×720 실제 게임 캡처, 빌드, 커밋, 푸시는 이번 패킷 범위가 아니므로 실행하지 않았다.

## 남은 항목

- `slime`·`thief` 등 개별 자산의 down 프레임 발 앵커를 프로필에 채우는 후속 패킷이 필요하다.
- V2에서 기록한 일부 저알파 녹색 잔여는 자산 패킷에서만 처리한다.
- V4 전면 벽 가림과 UI/VFX 앵커는 아직 시작하지 않는다.

## 정책 기록

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A` (혼합 미커밋 작업 트리)
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
