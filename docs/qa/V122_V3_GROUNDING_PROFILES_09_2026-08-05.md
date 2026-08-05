# V122 V3-GROUNDING-PROFILES-09 — slime_gate_bulwark 승급 앵커

검수일: 2026-08-05
대상 버전: 제품 1.2.2
패킷: `V3-GROUNDING-PROFILES-09`
판정: **PROFILE_CONNECT_PASS_WITH_SOURCE_PENDING**

## 패킷 카드

```text
PACKET_ID: V3-GROUNDING-PROFILES-09
GOAL: slime_gate_bulwark 한 캐릭터의 개별 idle/down 발 앵커를 측정하고 동일한 런타임 연결 경로로 검증
ALLOWED_WRITE_PATHS:
  - data/v122/combat_visual_profiles.json
  - tools/tests/V122CombatVisualRuntimeProfileContractTest.gd
  - docs/qa/V122_V3_GROUNDING_PROFILES_09_2026-08-05.md
  - docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_09_2026-08-05.md
  - docs/handoff/CURRENT.md
FORBIDDEN: Unit.gd·DataRegistry.gd·slime/thief/explorer/trainee_hero/investigator/shieldbearer/engineer/goblin/imp 프로필·다른 캐릭터·자산 재생성·V4 가림·UI/VFX·오디오·다음 V3 프로필 패킷·전체 회귀·빌드
DIRECT_TEST: slime_gate_bulwark runtime profile의 idle/down 앵커, VisualBody/root 기준, 기존 scale·sprite 경로 보존을 직접 확인
UI_OR_AUDIO_CHECK: 없음 — 런타임 프로필 계약만 확인
STOP_AFTER: slime_gate_bulwark 한 캐릭터 프로필 1개 패킷과 계약 테스트·QA·핸드오프 기록 후 중단
```

## 측정 기준과 결과

승급 런타임 자산 `monster_slime_gate_bulwark_idle_down_00.png`와 `monster_slime_gate_bulwark_down_00.png`의 192×192 프레임에서 알파가 있는 영역의 경계 상자(bottom exclusive)를 직접 측정했다. `foot_anchor.y`는 `bbox_bottom / frame_height`로 계산했으며 허용 오차는 2픽셀이다.

| 캐릭터 | idle bbox | idle 발 y | down bbox | down 발 y |
|---|---|---:|---|---:|
| `slime_gate_bulwark` | `[13, 24, 189, 190]` | `0.989583` | `[2, 41, 192, 172]` | `0.895833` |

## 구현과 런타임 확인

- `data/v122/combat_visual_profiles.json`의 승급 override에 프레임 크기, idle/down 앵커, 실제 alpha bbox, 측정식, 허용 오차를 기록했다.
- 기존 `DataRegistry`의 깊은 복사·`motion_entry` 병합 경로를 재사용해 `normal_grounded` 공통 사전을 직접 변경하지 않았다.
- 계약 테스트는 `slime_gate_bulwark` 하나로만 잠그고 grounded motion mode, `VisualBody` 부모, sprite local position 0, idle/down body 위치, 기존 sprite 경로·render scale, 선언된 bbox를 확인했다.
- 원본 JSON의 `runtime_consumption_state`는 전역 프로필 승격 게이트 전까지 `PENDING_V3_PROFILE_CONNECT`로 보존했다. 이번 판정은 런타임 소비 경로가 실제로 동작한다는 의미이며 상태값의 일괄 승격은 별도 범위다.

## 실행한 테스트

- `godot.cmd --headless --path . --scene tools/tests/V122CombatVisualRuntimeProfileContractTest.tscn --quit-after 30`
  - `V122_COMBAT_VISUAL_RUNTIME_PROFILE_CONTRACT_TEST: PASS`
- Python 프로필 JSON·앵커 계산 검사
  - `V122_V3_SLIME_GATE_BULWARK_PROFILE_JSON_TEST: PASS`
- `git diff --check -- data/v122/combat_visual_profiles.json tools/tests/V122CombatVisualRuntimeProfileContractTest.gd`: PASS

전체 회귀, 전체 플레이, 1280×720 실제 게임 캡처, 빌드, 커밋, 푸시는 이번 패킷 범위가 아니므로 실행하지 않았다.

## 정책 기록

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A` (혼합 미커밋 작업 트리)
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
