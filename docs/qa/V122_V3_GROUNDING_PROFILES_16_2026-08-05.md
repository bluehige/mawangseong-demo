# V122 V3-GROUNDING-PROFILES-16 — spore_doll 시트 앵커

검수일: 2026-08-05
대상 버전: 제품 `1.2.2`
패킷: `V3-GROUNDING-PROFILES-16`
판정: **PROFILE_CONNECT_PASS_WITH_SOURCE_PENDING**

## 패킷 카드

```text
PACKET_ID: V3-GROUNDING-PROFILES-16
GOAL: spore_doll 한 캐릭터의 4×4 런타임 시트 idle/down 셀 앵커를 측정하고 동일한 런타임 연결 경로로 검증
ALLOWED_WRITE_PATHS:
  - data/v122/combat_visual_profiles.json
  - tools/tests/V122CombatVisualRuntimeProfileContractTest.gd
  - docs/qa/V122_V3_GROUNDING_PROFILES_16_2026-08-05.md
  - docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_16_2026-08-05.md
  - docs/handoff/CURRENT.md
FORBIDDEN: Unit.gd·DataRegistry.gd·다른 캐릭터·자산 재생성·V4 가림·UI/VFX·오디오·다음 V3 패킷·전체 회귀·빌드
DIRECT_TEST: spore_doll runtime profile의 4×4 시트 idle/down 앵커, VisualBody/root 기준, 기존 scale·투명 시트 경로 보존
UI_OR_AUDIO_CHECK: 없음 — 프로필·계약만 확인
STOP_AFTER: spore_doll 한 캐릭터 프로필 1개와 계약 테스트·QA·핸드오프 기록 후 중단
```

## 측정 결과

런타임 시트 `enemy_spore_doll_sheet.png`는 4×4, 셀 크기 192×192이다. `Unit.gd`의 시트 매핑에 따라 idle은 `(0,0)`, down은 `(2,0)` 셀을 측정했다. 알파 bbox의 bottom-exclusive 값을 셀 높이로 나눠 발 앵커 y를 계산했으며 허용 오차는 2px이다.

| 캐릭터 동작 | 셀 | alpha bbox | 발 앵커 |
|---|---|---|---:|
| `spore_doll` idle | `(0,0)` | `[46, 35, 160, 170]` | `0.885417` |
| `spore_doll` down | `(2,0)` | `[21, 87, 176, 177]` | `0.921875` |

## 런타임 연결 확인

- `data/v122/combat_visual_profiles.json`의 `spore_doll` override에 프레임 크기, idle/down 앵커, 두 셀 bbox, 측정 방식과 `PENDING_V3_PROFILE_CONNECT` 상태를 기록했다.
- 기존 `DataRegistry`의 `normal_grounded` motion entry 병합 경로를 그대로 사용하며 `Unit.gd`·`DataRegistry.gd`는 수정하지 않았다.
- 계약 테스트는 `spore_doll` 한 캐릭터만 대상으로 삼아 기존 render scale, `VisualBody` 부모, sprite local position 0, idle/down body 위치, 투명 런타임 시트와 chroma material 미사용, 셀 perimeter 보존을 확인했다.
- 원본과 프로필의 `NEEDS_NORMALIZATION` 상태는 최종 자산 승격 전까지 유지한다.

## 실행한 직접 테스트

- `godot.cmd --headless --path . --scene tools/tests/V122CombatVisualRuntimeProfileContractTest.tscn --quit-after 30`
  - `V122_COMBAT_VISUAL_RUNTIME_PROFILE_CONTRACT_TEST: PASS`
- 실제 PNG 셀 bbox와 JSON 앵커를 비교한 Python 검사
  - `V122_V3_SPORE_DOLL_PROFILE_JSON_TEST: PASS`
- `git diff --check -- docs/handoff/CURRENT.md data/v122/combat_visual_profiles.json tools/tests/V122CombatVisualRuntimeProfileContractTest.gd`
  - PASS (기존 줄바꿈 형식 경고만 출력)

전체 회귀, 전체 플레이 검수, 대표 화면 캡처, 빌드, 커밋, 푸시는 이번 패킷 범위가 아니므로 실행하지 않았다.

## 정책 기록

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A` (커밋하지 않은 작업 트리)
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
