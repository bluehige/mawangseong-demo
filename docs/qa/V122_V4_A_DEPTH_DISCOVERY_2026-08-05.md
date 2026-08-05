# V122 V4-A-01-DISCOVERY QA

검수일: 2026-08-05
목표 버전: 제품 `1.2.2`
패킷: `V4-A-01-DISCOVERY`
판정: **DEPTH_DISCOVERY_PASS_WITH_IMPLEMENTATION_PENDING**

## 패킷 카드

```text
PACKET_ID: V4-A-01-DISCOVERY
GOAL: 전면 벽 깊이 구조의 현재 Unit·FrontWallLayer·방향별 벽 계층을 읽기 전용으로 조사하고 구현 경계를 잠금
ALLOWED_WRITE_PATHS:
  - docs/qa/V122_V4_A_DEPTH_DISCOVERY_2026-08-05.md
  - docs/handoff/V122_RELEASE_POLISH_V4_A_DEPTH_DISCOVERY_2026-08-05.md
  - docs/handoff/CURRENT.md
FORBIDDEN: Unit.gd·DataRegistry.gd·FrontWallLayer·벽 renderer·VFX 깊이·UI 앵커·오디오·다른 캐릭터 프로필·자산 재생성·V5·다음 패킷·전체 회귀·빌드
DIRECT_TEST: Unit z_index·FrontWallLayer·방향별 벽 draw 계층의 읽기 전용 구조 조사 1종
UI_OR_AUDIO_CHECK: 없음
STOP_AFTER: V4-A 깊이 구조 발견·문서화 후 중단
```

## 조사 결론

현재 전면 벽의 방향 분리는 이미 맞다. 문제는 `Unit`이 월드 Y를 제한 없이 `z_index`로 사용해 정적인 `FrontWallLayer` 깊이값을 넘어설 수 있다는 점이다. 따라서 벽 자산을 다시 만들거나 E/S와 N/W의 방향 규칙을 바꾸는 것이 아니라, 유닛 깊이를 유한한 슬롯으로 제한하고 벽의 낮은 앞가림만 그 슬롯 위에 두는 구조 보정이 다음 구현의 경계다.

## 현재 구조 증거

| 영역 | 현재 동작 | 근거 |
|---|---|---|
| Unit 깊이 | 이동 후 `z_index = int(global_position.y)`를 그대로 대입한다. 맵 좌표에 따른 상한·벽 기준 clamp가 없다. | `scripts/units/Unit.gd:349-354` |
| Unit 부모 | `UnitYSortLayer`가 `y_sort_enabled = true`, `z_index = 0`으로 생성된다. 유닛은 이 레이어의 자식이다. | `scripts/game/GameRoot.gd:3945-3949`, `scripts/game/GameRoot.gd:11219-11222` |
| FrontWallLayer | 공용 레이어 값은 `50`; `FxLayer`는 `70`, Unit 레이어는 `0`이다. | `scripts/dungeon_quarter/QuarterDungeonRenderer.gd:721-740` |
| 전면 벽 Canvas | `FrontWallLayer/CorridorFrontWallCanvas`를 만들고 `wall_front`만 그린다. | `scripts/dungeon_quarter/QuarterDungeonRenderer.gd:580-590`, `scripts/dungeon_quarter/QuarterDungeonWallCanvas.gd:14-17` |
| 벽 방향 | N/W는 `wall_back`, E/S는 `wall_front`로 결정된다. | `scripts/dungeon_quarter/CorridorTopologyBuilder.gd:548-550`, `scripts/dungeon_quarter/QuarterDungeonRenderer.gd:2539-2541` |
| 벽 본체 | `draw()` 중 `_draw_back_wall_layer()`가 모든 구조 벽 본체와 정점을 한 번 그린다. | `scripts/dungeon_quarter/QuarterDungeonRenderer.gd:126-147`, `scripts/dungeon_quarter/QuarterDungeonRenderer.gd:1656-1663` |
| 낮은 앞가림 | E/S 구조 벽만 별도 `front_occluder` texture로 `FrontWallLayer`에서 다시 그린다. 높은 본체를 앞층 fallback으로 올리지는 않는다. | `scripts/dungeon_quarter/QuarterDungeonRenderer.gd:1893-1903`, `scripts/dungeon_quarter/QuarterDungeonRenderer.gd:2662-2679` |
| VFX 깊이 | VFX는 `FxLayer` 아래에서 일반 `unit_fx=-30`, 공중 `aerial_fx=100` 같은 고정 자식 z값을 쓴다. 현재 Unit·벽 슬롯과의 관계 API는 없다. | `scripts/game/GameRoot.gd:3950-3953`, `scripts/game/CombatSceneController.gd:6921-6928` |

### 현재 가림이 깨지는 원인

1. `FrontWallLayer`는 `50`으로 고정되어 있는데 Unit의 `z_index`는 월드 Y값이라 범위가 무제한이다. 유닛이 Y 50을 넘으면 E/S 앞가림 Canvas보다 높은 깊이로 올라갈 수 있다.
2. N/W와 E/S의 방향 분리는 정확하지만, 방향 판정만으로는 같은 E/S 벽 앞에서 유닛 몸을 어느 깊이 슬롯에 둘지 결정하지 못한다.
3. 구조 벽 본체와 낮은 앞가림을 분리한 자산 구조는 이미 있으므로, 전체 벽을 더 높은 숫자로 올리는 방식은 몸 전체를 가리고 다른 방향의 정렬을 깨뜨릴 위험이 있다.
4. VFX의 `-30/100`은 `FxLayer` 기준 고정값이다. V4-A에서 VFX ID를 직접 연결하지 않더라도, 후속 V5가 사용할 제한된 depth 슬롯·가림 API를 먼저 정의해야 한다.

## 구현 경계 잠금

다음 구현 패킷은 아래만 다룬다.

- `UnitYSortLayer` 내부에서만 동작하는 제한된 유닛 depth 슬롯을 정의한다.
- 유닛의 유효 깊이가 `FrontWallLayer`를 넘지 않도록 한다. 월드 Y를 `z_index`에 직접 대입하지 않는다.
- 기존 N/W 후면 벽과 E/S 전면 낮은 occluder의 방향 매핑·자산·상대 비율은 유지한다.
- 높은 벽 본체를 전면층에 복제하지 않고, E/S 앞가림 texture만 유닛 앞에 둔다.
- 후속 V5가 지면·몸·공중 VFX를 연결할 수 있는 depth/occlusion 조회 계약만 준비한다. V4-A에서는 실제 VFX ID 연결·효과 가림 판정을 하지 않는다.
- 이름·HP·피해 숫자 위치, 오디오, UI 앵커, 자산 재생성은 이 범위에 포함하지 않는다.

## 직접 검증

구조·방향·레이어 존재를 확인하는 기존 읽기 전용 행렬 테스트:

```text
godot.cmd --headless --path . --scene tools/tests/V122CorridorTopologyLayoutMatrixTest.tscn --quit-after 30
V122_CORRIDOR_TOPOLOGY_LAYOUT_MATRIX_TEST: PASS
```

정적 소스 조사(7개 항목)도 통과했다.

```text
V122_V4_A_DEPTH_DISCOVERY_STATIC_AUDIT: PASS (7 checks)
```

행렬 테스트의 PASS는 구조 벽 topology, 4개 Stage와 custom 맵, FrontWallLayer 및 방향별 자산 연결이 유효하다는 뜻이다. 실제 Unit 깊이 clamp나 `1280×720` 전면 벽 가림 화면은 아직 검증하지 않았으며, 그것은 다음 구현·대표 화면 패킷의 범위다.

## 미해결 및 다음 순서

- 미해결: Unit 깊이 슬롯 구현, 실제 E/S 앞가림 대표 화면, V5 지면·몸·공중 VFX의 최종 가림 검증.
- 다음 제안: `V4-A-02-DEPTH-SLOT-CONTRACT` — Unit·QuarterDungeonRenderer·FrontWallCanvas와 전용 계약 테스트만 수정.

## 정책 기록

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A` (미커밋 혼합 작업 트리)
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
