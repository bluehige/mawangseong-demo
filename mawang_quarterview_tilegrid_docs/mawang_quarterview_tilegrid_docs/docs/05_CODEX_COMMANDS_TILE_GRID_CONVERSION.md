# 05. Codex 작업 명령문 — 통짜 방 이미지에서 쿼터뷰 타일 그리드로 전환

## 명령 1. 기존 통짜 모듈 방식 폐기

```text
현재 쿼터뷰 던전이 구역당 통짜 이미지 1장을 배치하는 방식으로 되어 있다면 이 방식을 폐기해라.

새 구조는 가상 쿼터뷰 그리드 기반이다. 방은 이미지가 아니라 RoomBlueprint JSON으로 정의하고, floor_cells, walk_cells, blocked_cells, sockets, object_slots를 가진다. 그래픽은 FloorLayer, EdgeLayer, BackWallLayer, ObjectBackLayer, UnitYSortLayer, ObjectFrontLayer, FrontWallLayer에 분리 배치한다.

이번 작업에서는 통짜 방 배경 PNG를 직접 배치하는 코드를 제거하거나 사용하지 않도록 비활성화하고, RoomBlueprint를 읽어 cell 단위로 바닥 타일을 배치하는 구조를 추가해라.
```

완료 조건:
- 방 이미지 1장으로 던전을 그리는 코드가 메인 경로에서 사라진다.
- RoomBlueprint JSON을 읽어 바닥 셀을 배치한다.
- 바닥 cell을 디버그 오버레이로 확인할 수 있다.

---

## 명령 2. 오토타일 4방향 마스크 구현

```text
FloorLayer에 바닥 타일을 배치할 때, 각 floor cell 주변의 NW, NE, SE, SW 4방향 연결 여부를 검사해 0~15 mask를 계산해라.

방향 비트는 NW=1, NE=2, SE=4, SW=8로 한다.
tile_variant_manifest.json에서 theme_id와 mask를 기준으로 사용할 atlas 좌표를 읽어 TileMapLayer에 배치해라.

연결/비연결 2장으로 처리하지 말고, 최소 16개 mask를 모두 지원해라.
```

완료 조건:
- mask 0~15가 정상 출력된다.
- 직선, 코너, T자, 십자 연결이 다른 타일로 보인다.
- F4로 각 cell의 mask 숫자를 볼 수 있다.

---

## 명령 3. walkable cell 이동 제한 연결

```text
RoomBlueprint의 walk_cells와 blocked_cells를 합쳐 DungeonWalkMap을 생성해라.
모든 몬스터와 적 이동, 직접 조종 우클릭 이동, 웨이브 이동은 DungeonWalkMap의 AStarGrid2D 경로만 사용해야 한다.

유닛은 floor image가 있는 곳이 아니라 walk_cells로 허용된 곳만 걸을 수 있다. blocked_cells와 prop_block_cells는 walkable에서 제외한다.
```

완료 조건:
- 벽/공중을 걷지 않는다.
- 바닥이 있지만 blocked인 보물더미/기둥 위로 이동하지 않는다.
- F3/F7/F9 디버그 표시가 작동한다.

---

## 명령 4. 벽/문/오브젝트 레이어 분리

```text
쿼터뷰 던전 렌더링을 레이어로 분리해라.

필수 레이어:
FloorLayer
EdgeLayer
BackWallLayer
DoorBackLayer
ObjectBackLayer
UnitYSortLayer
ObjectFrontLayer
FrontWallLayer
TrapEffectLayer
DebugOverlayLayer

유닛은 UnitYSortLayer에 배치하고 y_sort_enabled를 활성화해라.
큰 오브젝트는 back/front 스프라이트로 분리할 수 있게 구조를 만들어라.
```

완료 조건:
- 유닛이 벽/왕좌/보물더미 앞뒤로 자연스럽게 정렬된다.
- FrontWallLayer가 유닛을 가릴 수 있다.
- z_index 규칙이 코드 또는 주석에 명확히 적혀 있다.

---

## 명령 5. 마왕성 등급 확장 구조 추가

```text
마왕성 등급에 따라 grid_size, unlocked_sockets, max_room_slots, theme_id를 바꿀 수 있는 castle_grade_rules.json을 추가해라.

F급은 8x8, E급은 10x10, D급은 12x12, C급은 14x14, B급은 16x16, A급은 18x18을 기준으로 한다.

등급이 올라가도 새 방 배경 이미지를 만들지 말고, 같은 타일 세트 또는 theme_id 교체로 더 큰 그리드를 그려라.
```

완료 조건:
- castle grade를 바꾸면 그리드 크기가 바뀐다.
- 기존 방은 유지된다.
- 신규 소켓/슬롯이 열린다.
- DungeonWalkMap이 재빌드된다.

---

## 명령 6. GPT Image 리소스 적용 규칙 반영

```text
assets/tiles 아래에 테마별 타일 폴더를 만들고, floor, edge, wall, door, overlay를 분리해라.
assets/props 아래에는 room prop을 종류별로 분리해라.

이미지 파일명은 mask, direction, state, frame을 포함해야 한다.
예:
floor_cave_f_mask_00.png
floor_cave_f_mask_15_var_01.png
wall_cave_f_ne_straight_00.png
door_cave_f_ne_closed.png
trap_spike_idle_00.png
prop_throne_f_back.png
prop_throne_f_front.png

Codex는 파일명만으로도 어떤 용도인지 알 수 있게 asset manifest를 작성해라.
```

완료 조건:
- asset_manifest.json에서 모든 타일/오브젝트를 참조한다.
- 파일명 규칙이 적용된다.
- 누락된 mask나 방향이 있으면 경고 로그가 나온다.
