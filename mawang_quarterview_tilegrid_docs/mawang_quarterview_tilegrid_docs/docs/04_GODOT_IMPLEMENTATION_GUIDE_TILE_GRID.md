# 04. Godot 4.5 구현 가이드 — 쿼터뷰 그리드 타일 방식

## 1. 구현 목표

현재 쿼터뷰 던전 모듈이 구역별 통짜 이미지를 사용하고 있다면 이를 폐기하고, 아래 구조로 바꾼다.

```text
RoomBlueprint JSON
  ↓
DungeonGrid 생성
  ↓
cell별 floor/wall/edge mask 계산
  ↓
TileMapLayer에 타일 배치
  ↓
ObjectSlot에 props 배치
  ↓
DungeonWalkMap 생성
  ↓
AStarGrid2D 경로 탐색
```

---

## 2. 파일 구조

```text
res://
  scripts/
    dungeon/
      DungeonGrid.gd
      IsoCoord.gd
      AutoTileMask.gd
      DungeonTilePainter.gd
      DungeonWalkMap.gd
      RoomBlueprintLoader.gd
      DungeonBuilder.gd
      SocketConnector.gd

  data/
    dungeon/
      room_blueprints.json
      corridor_blueprints.json
      tile_variant_manifest.json
      castle_grade_rules.json

  assets/
    tiles/
      cave_f/
        floor/
        edge/
        wall/
        door/
        overlay/
      lair_e/
      fortress_d/
    props/
      throne/
      treasure/
      barracks/
      recovery/
      traps/
```

---

## 3. 필수 클래스

### 3-1. IsoCoord.gd

```gdscript
class_name IsoCoord

const TILE_W := 128.0
const TILE_H := 64.0

static func grid_to_world(cell: Vector2i, origin: Vector2 = Vector2.ZERO) -> Vector2:
    return Vector2(
        (cell.x - cell.y) * TILE_W * 0.5,
        (cell.x + cell.y) * TILE_H * 0.5
    ) + origin

static func world_to_grid(pos: Vector2, origin: Vector2 = Vector2.ZERO) -> Vector2i:
    var local := pos - origin
    var gx := (local.y / (TILE_H * 0.5) + local.x / (TILE_W * 0.5)) * 0.5
    var gy := (local.y / (TILE_H * 0.5) - local.x / (TILE_W * 0.5)) * 0.5
    return Vector2i(roundi(gx), roundi(gy))
```

### 3-2. AutoTileMask.gd

```gdscript
class_name AutoTileMask

const DIRS := {
    "NW": Vector2i(-1, 0),
    "NE": Vector2i(0, -1),
    "SE": Vector2i(1, 0),
    "SW": Vector2i(0, 1)
}

const BITS := {
    "NW": 1,
    "NE": 2,
    "SE": 4,
    "SW": 8
}

static func get_4bit_mask(cell: Vector2i, floor_cells: Dictionary) -> int:
    var mask := 0
    for dir_name in DIRS.keys():
        if floor_cells.has(cell + DIRS[dir_name]):
            mask |= BITS[dir_name]
    return mask
```

### 3-3. DungeonTilePainter.gd

```gdscript
class_name DungeonTilePainter
extends Node

@export var floor_layer: TileMapLayer
@export var edge_layer: TileMapLayer
@export var wall_back_layer: TileMapLayer
@export var front_wall_layer: TileMapLayer

var tile_manifest: Dictionary

func paint_floor(floor_cells: Dictionary, theme_id: String) -> void:
    for cell in floor_cells.keys():
        var mask := AutoTileMask.get_4bit_mask(cell, floor_cells)
        var tile_info := tile_manifest[theme_id]["floor_mask"][str(mask)]
        floor_layer.set_cell(cell, tile_info.source_id, Vector2i(tile_info.atlas_x, tile_info.atlas_y), 0)
```

실제 Godot에서는 Dictionary 접근 타입을 프로젝트 코드 스타일에 맞게 정리한다.

---

## 4. TileMapLayer 사용 규칙

### 4-1. 레이어 분리

Godot의 TileMapLayer는 한 레이어만 담당한다.
따라서 바닥, 벽, 앞벽을 분리한다.

| 레이어 | 용도 |
|---|---|
| FloorLayer | 바닥 |
| EdgeLayer | 바닥 가장자리 |
| BackWallLayer | 뒤쪽 벽 |
| DoorBackLayer | 뒤쪽 문틀 |
| FrontWallLayer | 앞쪽 벽/오클루더 |

### 4-2. TileSet 설정

권장:

| 항목 | 값 |
|---|---|
| Tile Shape | Isometric |
| Tile Size | 128×64 |
| Texture Region | floor는 128×64, 벽/오브젝트는 별도 canvas |
| Physics Layer | 필요한 경우만 |
| Custom Data | walkable, terrain_type, damage, room_tag |

큰 벽이나 왕좌, 보물더미는 TileMapLayer보다 Sprite2D/Scene Tile로 배치하는 것이 안전하다.

---

## 5. ObjectSlot 배치 규칙

RoomBlueprint의 object_slots를 읽어 오브젝트를 배치한다.

```gdscript
func spawn_prop(slot: Dictionary, room_origin: Vector2i) -> void:
    var cell := room_origin + Vector2i(slot.cell[0], slot.cell[1])
    var world_pos := IsoCoord.grid_to_world(cell)
    var prop_scene := load_prop_scene(slot.id)
    var prop := prop_scene.instantiate()
    prop.global_position = world_pos + get_prop_offset(slot.id)
    add_child_to_layer(prop, slot.layer)
```

오브젝트는 반드시 footprint와 block_cells를 가진다.

```json
{
  "id": "treasure_pile_large",
  "footprint": [[0,0],[1,0],[0,1],[1,1]],
  "block_cells": [[0,0],[1,0]],
  "anchor": "front_center",
  "layer": "front"
}
```

---

## 6. 이동 제한

DungeonWalkMap은 그래픽과 별개로 관리한다.

```gdscript
func rebuild_walk_map(all_walk_cells: Dictionary, all_block_cells: Dictionary) -> void:
    astar_grid.clear()
    astar_grid.region = Rect2i(Vector2i.ZERO, grid_size)
    astar_grid.cell_size = Vector2(TILE_W, TILE_H)
    astar_grid.cell_shape = AStarGrid2D.CELL_SHAPE_ISOMETRIC_RIGHT
    astar_grid.update()

    for x in range(grid_size.x):
        for y in range(grid_size.y):
            var cell := Vector2i(x, y)
            var solid := not all_walk_cells.has(cell) or all_block_cells.has(cell)
            astar_grid.set_point_solid(cell, solid)
```

유닛 이동은 반드시 아래 흐름을 따른다.

```gdscript
func request_move(unit: Unit, world_target: Vector2) -> void:
    var target_cell := IsoCoord.world_to_grid(world_target, dungeon_origin)
    target_cell = walk_map.get_nearest_walkable_cell(target_cell)
    var start_cell := IsoCoord.world_to_grid(unit.global_position, dungeon_origin)
    var path := walk_map.get_cell_path(start_cell, target_cell)
    unit.follow_cell_path(path)
```

---

## 7. 벽/오브젝트 정렬

UnitYSortLayer에는 `y_sort_enabled = true`를 켠다.
유닛, 투사체, 일부 앞/뒤 소품은 Y 좌표를 기준으로 정렬한다.

큰 오브젝트는 아래처럼 나누는 것을 권장한다.

```text
왕좌
  throne_back.png   # 유닛 뒤
  throne_front.png  # 유닛 앞 난간/장식

보물더미
  treasure_back.png
  treasure_front.png

성문
  gate_back.png
  gate_front.png
```

이렇게 해야 캐릭터가 오브젝트 앞/뒤를 자연스럽게 지나간다.

---

## 8. 디버그 오버레이

반드시 구현한다.

| 키 | 표시 |
|---|---|
| F3 | walkable cell 초록 |
| F4 | floor mask 숫자 |
| F5 | socket 위치 |
| F6 | room id |
| F7 | blocked cell 빨강 |
| F8 | 선택 유닛의 현재 cell |
| F9 | 경로 라인 |

이 오버레이가 없으면 쿼터뷰 던전 버그를 잡기 어렵다.

---

## 9. 구현 완료 조건

| 체크 | 항목 |
|---|---|
| ☐ | 통짜 방 배경 이미지를 쓰지 않는다 |
| ☐ | RoomBlueprint로 방을 생성한다 |
| ☐ | floor_cells를 기반으로 바닥 타일을 깐다 |
| ☐ | 4방향 mask 16개 중 하나를 선택한다 |
| ☐ | 벽/문/오브젝트가 별도 레이어에 배치된다 |
| ☐ | 유닛은 walk_cells 위에서만 이동한다 |
| ☐ | 소켓 연결 후 DungeonWalkMap이 재생성된다 |
| ☐ | 마왕성 등급 상승 시 그리드가 확장된다 |
| ☐ | 같은 타일 세트를 반복해 더 큰 방을 만들 수 있다 |
| ☐ | F3~F9 디버그 표시가 작동한다 |
