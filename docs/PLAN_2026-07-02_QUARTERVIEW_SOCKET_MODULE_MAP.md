# 개발 계획: 쿼터뷰 소켓 연결식 모듈 조립형 맵 전환

작성일: 2026-07-02

## 1. 확인한 문서

기준 문서 위치:

`C:\Users\LDK-6248\Desktop\AI개발\어시스트프로젝트\마왕성\mawang_quarterview_walkarea_update_docs\mawang_quarterview_walkarea_update_docs`

확인한 파일:

- `QUARTERVIEW_DUNGEON_MODULE_SPEC_FULL.md`
- `docs/00_QUICK_COPYPASTE_RULES.txt`
- `docs/01_QUARTERVIEW_DUNGEON_MODULE_RULES.md`
- `docs/02_QUARTERVIEW_GRAPHIC_ASSET_RULES.md`
- `docs/03_GODOT_IMPLEMENTATION_GUIDE.md`
- `docs/04_CODEX_COMMANDS.md`
- `docs/05_WALKABLE_FLOOR_NAVIGATION_RULES.md`
- `templates/module_data_example.json`
- `templates/module_data_walkable_example.json`
- `templates/layout_template_example.json`
- `templates/dungeon_walkmap_gd_snippet.gd`

백업 위치:

`C:\Users\LDK-6248\Desktop\AI개발\어시스트프로젝트\마왕성_backups\2026-07-02_1f7fc62_walkarea_plan`

백업 산출물:

- `mawang_git_all_2026-07-02_1f7fc62.bundle`
- `mawang_source_2026-07-02_1f7fc62.zip`
- `BACKUP_MANIFEST.txt`

## 2. 결론

이번 전환은 기존 “한 장짜리 연결 맵 + `rooms.json` + `RoomGraph`” 구조를 바로 삭제하지 않고, 새 쿼터뷰 모듈 시스템을 병렬로 만들고 검증한 뒤 교체한다.

채택 구조:

```text
상위 구조: 소켓 연결식 ModuleGraph
실제 이동: walk_cells 기반 DungeonWalkMap + AStarGrid2D
표시 구조: 쿼터뷰 모듈 bg/fg 레이어 + UnitSortLayer
호환 구조: 기존 room_id를 module_instance_id로 점진 전환
```

중요 원칙:

- 소켓은 “연결 가능성”만 판단한다.
- 실제 이동 가능 여부의 단일 진실 데이터는 `walk_cells`, `block_cells`, `prop_block_cells`, `socket_entry_cells`다.
- 모든 이동 요청은 최종적으로 `DungeonWalkMap.get_path_world()`를 통과해야 한다.
- 웨이포인트는 목표점일 뿐이며, 웨이포인트 사이도 AStar 경로로 쪼갠다.
- 기존 전투, 직접 조종, 방 지침, 도적/용사 목표 AI는 유지한다.

## 3. 현재 코드와 충돌 지점

현재 주요 의존:

- `GameRoot.gd`
  - `rooms`, `selected_room`, `room_directives`, `monster_roster[*].room`
  - `graph.center()`, `graph.path_points()`, `graph.closest_room()`, `graph.clamp_to_walkable()`
- `CombatSceneController.gd`
  - 적/몬스터 스폰, AI 이동, 함정 유도, 도둑 목표, 회복실 후퇴가 모두 room_id 기준
- `DungeonRenderer.gd`
  - `rooms.json`의 `grid_position`, `grid_size`, `rect`, `center`, `exits` 기반으로 맵을 그림
  - 현재는 연결된 전체 맵 이미지가 있으면 그 이미지를 먼저 그림
- `HUDController.gd`
  - 방 목록, 방 지침, 방 용도 변경이 room_id 기준
- `RoomGraph.gd`
  - 최근 추가한 `is_walkable()`/`clamp_to_walkable()`은 임시 보행 보정으로는 유효하지만, 최종 쿼터뷰 모듈 시스템에서는 `DungeonWalkMap`으로 대체해야 함

따라서 전환 중간에는 다음 호환 계층이 필요하다.

```text
room_id == module_instance_id
RoomGraph API 일부를 ModuleGraph/DungeonWalkMap이 같은 이름으로 제공
기존 CombatSceneController는 초기에는 최소 수정으로 새 API를 호출
```

## 4. 목표 데이터 구조

새 데이터 위치:

```text
data/dungeon_quarter/
  modules.json
  starting_layout.json
  layout_templates.json
```

새 스크립트 위치:

```text
scripts/dungeon_quarter/
  IsoMath.gd
  SocketData.gd
  DungeonModuleData.gd
  PlacedModule.gd
  DungeonModuleRegistry.gd
  ModuleGraph.gd
  SocketValidator.gd
  DungeonWalkMap.gd
  DungeonBuilder.gd
  QuarterDungeonRenderer.gd
  WalkDebugOverlay.gd
```

최소 모듈 데이터 필드:

```json
{
  "id": "room_treasure_01",
  "display_name": "보물 보관실",
  "module_type": "room",
  "footprint": [8, 8],
  "scene_path": "res://scenes/dungeon_quarter/modules/rooms/RoomTreasure01.tscn",
  "build_tags": ["room", "treasure", "lure", "economy"],
  "room_function": "treasure",
  "max_monsters": 2,
  "sockets": [],
  "walk_cells": [],
  "block_cells": [],
  "prop_block_cells": [],
  "socket_entry_cells": {},
  "spawn_cells": [],
  "combat_cells": [],
  "trap_cells": [],
  "retreat_cells": []
}
```

## 5. 첫 버전 모듈 구성

기존 데모 기능을 유지하려면 문서의 12개 전체보다 현재 맵을 바로 대체할 수 있는 8개 모듈을 먼저 만든다.

1. `room_entrance_01`
2. `corridor_spike_ne_sw_01`
3. `junction_center_01` 또는 `corridor_center_hub_01`
4. `room_throne_01`
5. `room_barracks_01`
6. `room_recovery_01`
7. `room_empty_slot_01`
8. `room_treasure_01`

그 다음 확장:

9. `corridor_straight_ne_sw_01`
10. `corridor_straight_nw_se_01`
11. `corridor_elbow_ne_se_01`
12. `junction_t_01`

이 순서가 맞는 이유:

- 현재 전투 루프가 입구, 가시 복도, 중앙 통로, 왕좌, 병영, 회복, 건설 슬롯, 보물방에 이미 의존한다.
- 먼저 같은 의미의 module_instance_id로 치환해야 기존 AI/밸런스를 덜 흔든다.
- 직선/꺾임 복도 자유 교체는 기본 루프가 안정화된 뒤 붙이는 편이 안전하다.

## 6. 단계별 구현 계획

### Phase 0. 백업과 기능 플래그

목표:

- 현재 데모를 언제든 복구 가능하게 한다.
- 새 쿼터뷰 모듈 시스템을 기존 맵과 병렬로 켤 수 있게 한다.

작업:

- 오늘자 백업 완료.
- `GameRoot`에 `use_quarter_module_map` 플래그 추가.
- 기존 `DungeonRenderer`는 유지.
- 새 시스템은 플래그가 켜졌을 때만 사용.

검증:

- 플래그 OFF에서 현재 `DemoSmokeTest.tscn` PASS.

### Phase 1. 데이터/그래프 기반 만들기

목표:

- 화면 변경 없이 모듈 데이터, 소켓, 레이아웃, 그래프, 보행 맵을 읽고 검증한다.

작업:

- `IsoMath.gd` 작성.
- `DungeonModuleRegistry.gd`로 `modules.json` 로드.
- `PlacedModule.gd`는 `local_to_global_cell()` 제공.
- `ModuleGraph.gd`는 `find_path(start_instance_id, target_instance_id)` 제공.
- `SocketValidator.gd`는 방향, 폭, 태그, footprint, 필수 경로, socket_entry 연결을 검증.
- `DungeonWalkMap.gd`는 모든 placed module의 `walk_cells`/`block_cells`를 전역 셀로 합치고 AStarGrid2D 생성.

검증:

- `QuarterModuleDataTest.tscn` 또는 `QuarterDungeonSmokeTest.tscn` 추가.
- 입구→왕좌 경로 존재.
- 입구→보물 경로 존재.
- socket_entry_cells가 서로 이어지지 않으면 validation fail.
- walk_cells 밖 좌표는 nearest walkable로 보정.

### Phase 2. Placeholder 쿼터뷰 렌더러

목표:

- 실제 아트 없이도 쿼터뷰 모듈 조립 구조가 화면에 보이게 한다.

작업:

- `QuarterDungeonRenderer.gd` 또는 `QuarterDungeonRoot` 생성.
- 각 모듈 footprint를 2:1 다이아몬드 셀로 그린다.
- 모듈별 bg/fg 레이어 노드 구조를 만든다.
- `UnitSortLayer`는 y-sort 가능하게 분리한다.
- F1/F2/F3/F4/F5/F6/F7/F8 디버그 토글을 구현한다.

검증:

- 플래그 ON에서 입구→가시 복도→중앙→왕좌가 쿼터뷰로 보인다.
- F3 walkable cell이 모듈 바닥과 맞는다.
- F7 blocked cell이 벽/소품 위치와 맞는다.
- F8 선택 유닛 현재 cell 표시.

### Phase 3. 기존 전투 이동을 DungeonWalkMap으로 연결

목표:

- 모든 유닛 이동이 실제 바닥 셀 경로를 사용하게 한다.

작업:

- `GameRoot._clamp_to_combat_walkable()`를 플래그 ON이면 `DungeonWalkMap`으로 위임.
- `graph.center(room_id)`에 해당하는 값을 `module target cell` 기반 world position으로 제공.
- `graph.path_points()`에 해당하는 값을 `ModuleGraph path + DungeonWalkMap cell path`로 제공.
- `CombatSceneController.move_unit_to_room()`과 `move_unit_to_point()`가 raw point가 아니라 `DungeonWalkMap.get_path_world()` 결과를 `unit.set_path()`에 넣게 한다.
- `Unit.gd`의 마지막 안전장치는 `DungeonWalkMap.is_world_position_walkable()` 기준으로 바꾼다.

검증:

- 도적이 보물방으로 갈 때 모든 중간 위치가 F3 초록 영역 안에 있다.
- 견습 용사가 왕좌까지 벽/공중을 통과하지 않는다.
- 직접 조종 우클릭이 벽이면 nearest walkable로 보정되거나 로그를 남긴다.
- 기존 유닛 충돌 우회 테스트 유지.

### Phase 4. room_id를 module_instance_id로 점진 전환

목표:

- UI와 AI의 “방” 개념을 모듈 인스턴스로 바꾼다.

작업:

- `selected_room`은 당분간 유지하되 의미를 `selected_module_instance_id`로 전환.
- `room_directives`를 module_instance_id 기준으로 저장.
- `monster_roster[*].room`을 `module_instance_id` 기준으로 해석.
- `_room_by_facility()`, `_room_by_type()`는 모듈 데이터의 `room_function`, `module_type`, `build_tags`를 조회.
- `HUDController`의 방 목록은 placed module 목록에서 생성.

검증:

- 기존 방 지침 변경 테스트 통과.
- 몬스터 드래그 배치가 모듈 인스턴스로 동작.
- 방 용도 변경이 module data override로 동작.

### Phase 5. 소켓 건설/교체 UI

목표:

- 플레이어가 빈 소켓과 교체 가능 모듈을 통해 던전을 설계한다고 느끼게 한다.

작업:

- F1/관리 화면에서 빈 소켓 hover 표시.
- 소켓 클릭 시 연결 가능한 후보 목록 표시.
- 후보 선택 시 preview footprint와 socket alignment 표시.
- 배치 전 `SocketValidator`와 `DungeonWalkMap` 필수 경로 검증.
- 직선 복도→가시 복도 같은 방향 교체.
- 빈 방→보물/병영/회복 교체.
- 실패 사유 로그/툴팁 표시.

검증:

- 입구→왕좌 경로가 끊기는 배치는 거부.
- 보물방이 있으면 입구→보물 경로가 없을 때 거부.
- 교체 후 ModuleGraph와 DungeonWalkMap이 재빌드.
- 적 경로 미리보기가 갱신.

### Phase 6. 실제 쿼터뷰 그래픽 교체

목표:

- placeholder에서 실제 쿼터뷰 모듈 이미지로 교체한다.

작업:

- 모듈별 최소 리소스 세트 제작:
  - `module_id_visual.png`
  - `module_id_foreground.png`
  - `module_id_walk_debug.png`
  - `module_id_data.json`
- 첫 제작 순서:
  1. 테스트 방 1개
  2. 직선 복도 1개
  3. 입구
  4. 왕좌
  5. 보물
  6. 가시 복도
  7. 병영
  8. 회복 둥지
  9. T자 분기
- 앞벽/기둥은 foreground로 분리.
- 방 이미지 안에 유닛/UI/텍스트 금지.

검증:

- F3/F7 overlay와 `walk_debug` 이미지가 일치.
- foreground가 유닛을 과도하게 가리지 않음.
- y-sort 기준점이 발밑과 일치.

### Phase 7. 테스트/밸런스/구 시스템 제거

목표:

- 기존 `rooms.json` 기반 임시 구조를 제거하거나 legacy fallback으로만 남긴다.

작업:

- `DemoSmokeTest`를 쿼터뷰 모듈 기준으로 확장.
- `BalanceSimulation` 결과 비교.
- `ManualVerificationCapture` 쿼터뷰 화면 캡처 추가.
- 기존 `RoomGraph`와 `DungeonRenderer` 사용 지점을 정리.

검증:

- `DemoSmokeTest.tscn` PASS.
- `BalanceSimulation.tscn` 기존 의도 유지.
- 쿼터뷰 캡처에서 캐릭터가 바닥 위에 있음.
- 직접 조종, 방 지침, 도둑 보물 목표, 회복실 후퇴가 모두 module 기준으로 동작.

## 7. 구현 우선순위

가장 먼저 해야 할 작업:

1. `data/dungeon_quarter/modules.json`와 `starting_layout.json` 초안 작성.
2. `IsoMath`, `PlacedModule`, `ModuleGraph`, `DungeonWalkMap`만 먼저 구현.
3. `QuarterDungeonSmokeTest`로 데이터 검증.
4. 그 다음 화면 표시와 기존 전투 연결.

바로 하지 말 것:

- 완전 자유 타일 배치.
- 모듈 회전/미러링 전체 지원.
- NavigationRegion2D.
- 8방향 애니메이션.
- 다층 던전.
- 실제 아트 전체 제작.

## 8. 현재 맵의 모듈 전환 초안

현재 `rooms.json`의 의미를 유지한 starting layout 초안:

```text
m_entrance  -> room_entrance_01
m_spike     -> corridor_spike_ne_sw_01
m_center    -> junction_center_01
m_throne    -> room_throne_01
m_barracks  -> room_barracks_01
m_recovery  -> room_recovery_01
m_slot_01   -> room_empty_slot_01
m_treasure  -> room_treasure_01
```

연결 초안:

```text
m_entrance <-> m_spike
m_spike    <-> m_center
m_center   <-> m_throne
m_center   <-> m_barracks
m_center   <-> m_recovery
m_center   <-> m_slot_01
m_slot_01  <-> m_treasure
```

기존 기능 매핑:

| 기존 | 새 구조 |
|---|---|
| `room_id` | `module_instance_id` |
| `rooms[room_id].facility_role` | placed module override 또는 module function |
| `RoomGraph.path_points()` | `ModuleGraph.find_path()` + `DungeonWalkMap.get_path_world()` |
| `RoomGraph.clamp_to_walkable()` | `DungeonWalkMap.get_nearest_walkable_cell()` |
| `DungeonRenderer.draw()` | `QuarterDungeonRenderer` |
| 방 목록 UI | placed module list |
| 방 지침 | module_instance_id directive |

## 9. 주요 리스크와 대응

| 리스크 | 영향 | 대응 |
|---|---|---|
| 좌표계 혼동 | 클릭/이동/렌더 위치 불일치 | `IsoMath`만 좌표 변환 담당, 테스트 추가 |
| 기존 전투 코드와 room_id 결합 | 대규모 수정 위험 | room_id와 module_instance_id를 초기에는 동일하게 유지 |
| walk_cells 데이터 누락 | 벽/공중 이동 재발 | 모든 모듈 로드 시 필수 필드 validation |
| 소켓 시각 위치와 데이터 불일치 | 조립 오차 | F1/F3/F7 overlay와 walk_debug 이미지로 검수 |
| foreground 가림 | 전투 가독성 저하 | fg 분리, 실루엣 hook 확보 |
| 경로 재계산 비용 | 전투 프레임 저하 | 건설/목표 변경 시에만 경로 재계산 |
| 아트 제작량 증가 | 일정 지연 | placeholder 우선, 실제 아트는 모듈별 순차 교체 |

## 10. 완료 기준

1. 쿼터뷰 모듈 레이아웃이 화면에 정상 표시된다.
2. 소켓 방향/폭/태그/footprint/walk 연결 검증이 동작한다.
3. `DungeonWalkMap`이 모든 모듈의 walk/block cell을 합쳐 AStar 경로를 만든다.
4. 탐험가, 도적, 견습 용사가 벽/공중을 통과하지 않는다.
5. 직접 조종 우클릭이 이동 불가 영역을 통과하지 않는다.
6. 기존 전투 루프와 3일 데모가 깨지지 않는다.
7. 관리 화면에서 최소한 소켓 후보/교체 후보가 동작한다.
8. F1~F8 디버그 오버레이로 소켓, footprint, walk/block cell, 경로, 전투 슬롯, Y-sort, 현재 유닛 cell을 확인할 수 있다.

