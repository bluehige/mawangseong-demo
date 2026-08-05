# V122 V3-GROUNDING-PROFILES-22 QA

검수일: 2026-08-05
목표 버전: 제품 `1.2.2`
패킷: `V3-GROUNDING-PROFILES-22`
판정: **PROFILE_CONNECT_PASS_WITH_SOURCE_PENDING**

## 패킷 카드

```text
PACKET_ID: V3-GROUNDING-PROFILES-22
GOAL: moon_tracker 한 캐릭터의 4×4 idle/down 알파 범위와 비행 앵커를 프로필에 연결하고 동일 경로를 런타임 계약으로 검증
ALLOWED_WRITE_PATHS:
  - data/v122/combat_visual_profiles.json
  - tools/tests/V122CombatVisualRuntimeProfileContractTest.gd
  - docs/qa/V122_V3_GROUNDING_PROFILES_22_2026-08-05.md
  - docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_22_2026-08-05.md
  - docs/handoff/CURRENT.md
FORBIDDEN: import sidecar 재수정, 다른 캐릭터, DataRegistry.gd·Unit.gd, 자산 재생성, V4/V5, UI/VFX, 오디오, 다음 패킷, 전체 회귀·빌드
DIRECT_TEST: moon_tracker runtime profile 4×4 idle/down bbox·비행 앵커·VisualBody/root·scale·투명 경로
UI_OR_AUDIO_CHECK: 없음
STOP_AFTER: moon_tracker 한 프로필·직접 테스트·QA·핸드오프 기록 후 중단
```

## 측정값과 연결

대상 런타임 시트는 `res://assets/sprites/monsters/update4/monster_moon_sheet.png`이며 768×768 RGBA, 셀은 192×192다. 실제 알파 범위와 비행 기준 앵커는 다음과 같다.

| 동작 | 셀 | alpha bbox (bottom-exclusive) | 비행 앵커 |
|---|---:|---:|---:|
| idle | `(0,0)` | `[29, 38, 162, 183]` | `[0.5, 1.0]` |
| down | `(2,0)` | `[24, 60, 167, 183]` | `[0.5, 0.94]` |

`data/v122/combat_visual_profiles.json`의 `unit_overrides.moon_tracker.grounding_anchors`에 위 값을 연결했다. `frame_size_px`, 측정식, 허용 오차 2px, `runtime_consumption_state: PENDING_V3_PROFILE_CONNECT`도 함께 기록했다. 비행 앵커는 지상 캐릭터와 같은 발바닥 의미가 아니라 공중 sprite의 기준점을 유지하기 위한 값이며, 이번 패킷에서 최종 `NORMALIZED_PASS`로 승격하지 않았다.

## 직접 테스트

실행:

```text
godot.cmd --headless --path . --scene tools/tests/V122CombatVisualRuntimeProfileContractTest.tscn --quit-after 30
```

결과:

```text
V122_COMBAT_VISUAL_RUNTIME_PROFILE_CONTRACT_TEST: PASS
```

확인 항목:

- JSON 프로필 키·small flying 동작·runtime 경로: PASS
- `monster_moon_sheet.png` 파일과 import 결과 로드: PASS
- 선언된 render scale과 Unit scale 일치: PASS
- 투명 시트에 chroma-key material 미적용: PASS
- `AnimatedSprite2D`가 `VisualBody` 아래에 있고 local position이 zero: PASS
- idle/down 비행 앵커가 실제 `visual_body` Y 위치에 반영: PASS
- 선언한 idle/down alpha bbox·비행 앵커가 JSON과 계약 테스트에서 일치: PASS

## 남은 범위

이번 패킷은 `moon_tracker` 한 프로필만 처리했다. 원본 상태 승격, 대표 동작 화면 검수, 다른 캐릭터, V4 깊이·가림, 전체 회귀는 실행하지 않았다. 다음 패킷은 `CURRENT.md`의 `NEXT_PACKET_ID`를 따른다.

## 정책 기록

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A` (미커밋 혼합 작업 트리)
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
