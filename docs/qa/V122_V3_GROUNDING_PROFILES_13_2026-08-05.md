# V122 V3-GROUNDING-PROFILES-13 — dusk_courier 시트 앵커

검수일: 2026-08-05
대상 버전: 제품 1.2.2
패킷: `V3-GROUNDING-PROFILES-13`
판정: **PROFILE_CONNECT_PASS_WITH_SOURCE_PENDING**

## 패킷 카드

```text
PACKET_ID: V3-GROUNDING-PROFILES-13
GOAL: dusk_courier 한 캐릭터의 4×4 런타임 시트 idle/down 셀 앵커를 측정하고 동일한 런타임 연결 경로로 검증
ALLOWED_WRITE_PATHS:
  - data/v122/combat_visual_profiles.json
  - tools/tests/V122CombatVisualRuntimeProfileContractTest.gd
  - docs/qa/V122_V3_GROUNDING_PROFILES_13_2026-08-05.md
  - docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_13_2026-08-05.md
  - docs/handoff/CURRENT.md
FORBIDDEN: Unit.gd·DataRegistry.gd·slime/thief/explorer/trainee_hero/investigator/shieldbearer/engineer/goblin/imp/slime_gate_bulwark/goblin_ambush_captain/imp_flame_adept/coal_spark 프로필·다른 캐릭터·자산 재생성·V4 가림·UI/VFX·오디오·다음 V3 프로필 패킷·전체 회귀·빌드
DIRECT_TEST: dusk_courier runtime profile의 4×4 시트 idle/down 앵커, VisualBody/root 기준, 기존 scale·투명 시트 경로 보존을 직접 확인
UI_OR_AUDIO_CHECK: 없음 — 런타임 프로필 계약만 확인
STOP_AFTER: dusk_courier 한 캐릭터 프로필 1개 패킷과 계약 테스트·QA·핸드오프 기록 후 중단
```

## 측정 기준과 결과

투명 런타임 시트 `enemy_dusk_courier_sheet.png`는 4×4, 셀 크기 192×192다. `Unit.gd`의 시트 매핑에 맞춰 idle은 셀 `(0,0)`, down은 셀 `(2,0)`에서 알파가 있는 영역의 경계 상자(bottom exclusive)를 측정했다. `foot_anchor.y`는 `bbox_bottom / cell_height`로 계산했으며 허용 오차는 2픽셀이다. 비행 캐릭터이므로 기존 `normal_flying` motion mode의 idle/down 기준으로만 주입한다.

| 캐릭터 | 셀 | alpha bbox | 발 y |
|---|---|---|---:|
| `dusk_courier` idle | `(0,0)` | `[37, 43, 163, 189]` | `0.984375` |
| `dusk_courier` down | `(2,0)` | `[16, 79, 171, 183]` | `0.953125` |

## 구현과 런타임 확인

- `data/v122/combat_visual_profiles.json`의 `dusk_courier` override에 셀 기준 프레임 크기, idle/down 앵커, 실제 alpha bbox, 측정식, 허용 오차를 기록했다.
- 기존 `DataRegistry`의 깊은 복사·`motion_entry` 병합 경로를 재사용해 `normal_flying` 공통 사전을 직접 변경하지 않았다.
- 계약 테스트는 `dusk_courier` 하나로만 잠그고 flying motion mode, `VisualBody` 부모, sprite local position 0, idle/down body 위치, 기존 render scale, 투명 시트의 chroma material 미적용·RUNTIME_PREP_PASS·셀 perimeter 보존, 선언된 bbox를 확인했다.
- 원본 JSON의 `runtime_consumption_state`는 전역 프로필 승격 게이트 전까지 `PENDING_V3_PROFILE_CONNECT`로 보존했다. 이번 판정은 런타임 소비 경로가 실제로 동작한다는 의미이며 `NEEDS_NORMALIZATION` 원본 상태를 최종 승격한 것은 아니다.

## 실행한 테스트

- `godot.cmd --headless --path . --scene tools/tests/V122CombatVisualRuntimeProfileContractTest.tscn --quit-after 30`
  - `V122_COMBAT_VISUAL_RUNTIME_PROFILE_CONTRACT_TEST: PASS`
- Python 시트 셀·프로필 JSON 앵커 검사
  - `V122_V3_DUSK_COURIER_PROFILE_JSON_TEST: PASS`
- `git diff --check -- data/v122/combat_visual_profiles.json tools/tests/V122CombatVisualRuntimeProfileContractTest.gd`: PASS

전체 회귀, 전체 플레이, 1280×720 실제 게임 캡처, 빌드, 커밋, 푸시는 이번 패킷 범위가 아니므로 실행하지 않았다.

## 정책 기록

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A` (혼합 미커밋 작업 트리)
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
