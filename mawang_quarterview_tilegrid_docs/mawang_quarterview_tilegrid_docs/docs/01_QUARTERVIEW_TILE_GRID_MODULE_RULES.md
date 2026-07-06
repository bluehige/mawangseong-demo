# 01. 쿼터뷰 가상 타일 그리드 기반 던전 모듈 규칙 v3

## 1. 왜 통짜 방 이미지 방식이 깨지는가

현재 Codex가 “구역당 이미지 1장”을 만들어 연결하려고 하면 다음 문제가 발생한다.

| 문제 | 원인 |
|---|---|
| 방과 복도 경계가 어색함 | 이미지마다 바닥 패턴, 그림자, 벽 두께가 다름 |
| 연결부가 끊겨 보임 | 문/복도/벽의 기준점이 통일되지 않음 |
| 벽이나 공중을 걷는 현상 | 보이는 그래픽과 실제 이동 영역이 분리되어 있지 않음 |
| 방 크기를 늘릴 수 없음 | 큰 방은 매번 새 이미지를 만들어야 함 |
| 업그레이드 때 리소스 폭증 | 등급별로 모든 방 이미지를 다시 만들어야 함 |
| 회전/좌우 변형이 어려움 | 빛 방향, 벽 방향, 입구 방향이 한 이미지 안에 고정됨 |

정규버전에서는 통짜 방 이미지를 금지하고, 아래 구조로 바꾼다.

> **가상 쿼터뷰 그리드 + 오토타일 + 소켓 + 오브젝트 슬롯 + 이동 가능 셀**

즉, 방은 이미지가 아니라 **cell 배열**이다.
이미지는 cell에 얹는 부품이다.

---

## 2. 기본 구조

### 2-1. 논리 좌표

던전 내부는 보이지 않는 2D 그리드로 관리한다.

```gdscript
Vector2i(x, y)
```

화면에는 쿼터뷰로 변환해 그린다.

```gdscript
const TILE_W := 128.0
const TILE_H := 64.0

func grid_to_world(cell: Vector2i, origin: Vector2 = Vector2.ZERO) -> Vector2:
    return Vector2(
        (cell.x - cell.y) * TILE_W * 0.5,
        (cell.x + cell.y) * TILE_H * 0.5
    ) + origin
```

마우스 클릭을 다시 셀로 바꿀 때는 반대 변환을 사용한다.

```gdscript
func world_to_grid(pos: Vector2, origin: Vector2 = Vector2.ZERO) -> Vector2i:
    var local := pos - origin
    var gx := (local.y / (TILE_H * 0.5) + local.x / (TILE_W * 0.5)) * 0.5
    var gy := (local.y / (TILE_H * 0.5) - local.x / (TILE_W * 0.5)) * 0.5
    return Vector2i(roundi(gx), roundi(gy))
```

### 2-2. 방향 명칭

쿼터뷰에서는 화면의 위/아래/좌/우와 그리드 방향이 헷갈리기 쉽다.
프로젝트에서는 아래 네 방향만 쓴다.

| 방향 | 비트 | 의미 |
|---|---:|---|
| NW | 1 | 왼쪽 위 방향 연결 |
| NE | 2 | 오른쪽 위 방향 연결 |
| SE | 4 | 오른쪽 아래 방향 연결 |
| SW | 8 | 왼쪽 아래 방향 연결 |

이 네 방향을 기준으로 연결 마스크를 만든다.

```gdscript
const DIR_NW := Vector2i(-1, 0)
const DIR_NE := Vector2i(0, -1)
const DIR_SE := Vector2i(1, 0)
const DIR_SW := Vector2i(0, 1)

const BIT_NW := 1
const BIT_NE := 2
const BIT_SE := 4
const BIT_SW := 8
```

---

## 3. 핵심 레이어 구조

Godot 씬에서는 하나의 TileMapLayer에 전부 넣지 않는다.
쿼터뷰는 벽, 오브젝트, 유닛의 앞뒤 정렬이 중요하므로 레이어를 분리한다.

```text
QuarterDungeonRoot(Node2D)
  GridOrigin(Node2D)

  FloorLayer(TileMapLayer)          # 바닥 다이아몬드
  EdgeLayer(TileMapLayer)           # 노출된 바닥 가장자리, 높이 스커트
  BackWallLayer(TileMapLayer)       # 유닛보다 뒤에 그릴 벽
  DoorBackLayer(TileMapLayer)       # 뒤쪽 문틀, 아치
  ObjectBackLayer(Node2D)           # 유닛 뒤 소품
  UnitYSortLayer(Node2D)            # 몬스터, 적, 투사체. y_sort_enabled = true
  ObjectFrontLayer(Node2D)          # 유닛 앞 소품
  FrontWallLayer(TileMapLayer)      # 유닛을 가리는 앞벽, 난간, 기둥
  TrapEffectLayer(Node2D)
  DebugOverlayLayer(Node2D)
```

권장 z_index:

| 레이어 | z_index |
|---|---:|
| FloorLayer | -100 |
| EdgeLayer | -90 |
| BackWallLayer | -70 |
| DoorBackLayer | -60 |
| ObjectBackLayer | -40 |
| UnitYSortLayer | 0 |
| ObjectFrontLayer | 30 |
| FrontWallLayer | 50 |
| TrapEffectLayer | 70 |
| DebugOverlayLayer | 200 |

---

## 4. 방은 이미지가 아니라 Blueprint다

방 하나를 이미지 한 장으로 만들지 않는다.
방은 아래 데이터로 만든다.

```json
{
  "id": "barracks_3x3_basic",
  "display_name": "병영",
  "theme": "cave_f",
  "size": [3, 3],
  "floor_cells": [[0,0],[1,0],[2,0],[0,1],[1,1],[2,1],[0,2],[1,2],[2,2]],
  "walk_cells": [[0,0],[1,0],[2,0],[0,1],[1,1],[2,1],[0,2],[1,2],[2,2]],
  "blocked_cells": [],
  "sockets": [
    {"dir": "SW", "cell": [1,2], "type": "corridor_1"}
  ],
  "object_slots": [
    {"id": "weapon_rack", "cell": [0,1], "layer": "back"},
    {"id": "training_dummy", "cell": [2,1], "layer": "front"}
  ],
  "tags": ["room", "monster_spawn", "training"]
}
```

### 4-1. RoomBlueprint 필수 필드

| 필드 | 설명 |
|---|---|
| id | 고유 ID |
| display_name | UI 표시명 |
| theme | cave_f, lair_e, fortress_d 등 |
| size | 방 크기 |
| floor_cells | 그래픽상 바닥 타일이 있는 셀 |
| walk_cells | 유닛이 이동 가능한 셀 |
| blocked_cells | 기둥, 가구, 벽 등 이동 불가 셀 |
| sockets | 다른 모듈과 연결 가능한 위치 |
| object_slots | 소품 배치 위치 |
| tags | 방 기능 태그 |

### 4-2. CorridorBlueprint 필수 필드

복도도 방과 같은 규칙을 따른다.

```json
{
  "id": "corridor_straight_1x4",
  "display_name": "직선 복도",
  "size": [1, 4],
  "floor_cells": [[0,0],[0,1],[0,2],[0,3]],
  "walk_cells": [[0,0],[0,1],[0,2],[0,3]],
  "sockets": [
    {"dir": "NE", "cell": [0,0], "type": "corridor_1"},
    {"dir": "SW", "cell": [0,3], "type": "corridor_1"}
  ],
  "tags": ["corridor"]
}
```

---

## 5. 소켓 연결 규칙

소켓은 방/복도가 서로 붙을 수 있는지만 판단한다.
소켓이 연결됐다고 해서 유닛이 자동으로 지나갈 수 있는 것은 아니다.
실제 이동은 `walk_cells`가 이어져야 가능하다.

### 5-1. 소켓 데이터

```json
{
  "dir": "NE",
  "cell": [1, 0],
  "type": "corridor_1",
  "width": 1,
  "requires_clearance": 1
}
```

| 필드 | 설명 |
|---|---|
| dir | 소켓 방향 |
| cell | 방 내부 기준 연결 셀 |
| type | corridor_1, room_2, gate_1 등 |
| width | 통로 폭 |
| requires_clearance | 연결부 앞뒤 여유 공간 |

### 5-2. 연결 가능 조건

1. 두 소켓의 방향이 반대여야 한다.
2. 두 소켓의 type이 호환되어야 한다.
3. 연결될 cell이 서로 맞닿아야 한다.
4. 연결될 두 cell 모두 walkable이어야 한다.
5. 연결부에 blocked object가 없어야 한다.
6. 연결 후 전체 왕좌의 방까지 경로가 끊기면 안 된다.

---

## 6. 오토타일 연결 마스크

Codex가 반드시 구현해야 하는 부분이다.

각 바닥 셀은 주변 4방향에 같은 바닥이 있는지 검사한다.

```gdscript
func get_floor_mask(cell: Vector2i, floor_set: Dictionary) -> int:
    var mask := 0
    if floor_set.has(cell + DIR_NW): mask |= BIT_NW
    if floor_set.has(cell + DIR_NE): mask |= BIT_NE
    if floor_set.has(cell + DIR_SE): mask |= BIT_SE
    if floor_set.has(cell + DIR_SW): mask |= BIT_SW
    return mask
```

### 6-1. 왜 최소 16장이 필요한가

방향이 4개이고, 각 방향이 연결/비연결 2상태라면 다음과 같다.

```text
2 × 2 × 2 × 2 = 16
```

즉, “연결/비연결 두 장”으로는 부족하다.
연결 상태가 방향별로 다르기 때문이다.

| mask | 의미 |
|---:|---|
| 0 | 주변 연결 없음, 섬 타일 |
| 1 | NW만 연결 |
| 2 | NE만 연결 |
| 3 | NW+NE 연결 |
| 4 | SE만 연결 |
| 5 | NW+SE 연결 |
| 6 | NE+SE 연결 |
| 7 | NW+NE+SE 연결 |
| 8 | SW만 연결 |
| 9 | NW+SW 연결 |
| 10 | NE+SW 연결 |
| 11 | NW+NE+SW 연결 |
| 12 | SE+SW 연결 |
| 13 | NW+SE+SW 연결 |
| 14 | NE+SE+SW 연결 |
| 15 | 4방향 모두 연결, 중앙 타일 |

### 6-2. 자연스러운 바닥을 위한 권장 방식

정규버전에서는 두 가지 중 하나를 선택한다.

| 방식 | 이미지 수 | 장점 | 단점 |
|---|---:|---|---|
| 16마스크 + 코너 오버레이 | 24~32장 | 구현 쉬움, 리소스 적음 | 완벽한 지형 블렌딩은 아님 |
| 47타일 블롭/왕타일 규칙 | 47장 이상 | 자연스러운 연결 | 제작/검수 부담 큼 |

이 프로젝트는 첫 정규버전에서 **16마스크 + 코너 오버레이**를 권장한다.
나중에 마왕성 테마가 늘어나면 47타일 규칙으로 업그레이드한다.

---

## 7. 이동 가능 바닥 규칙

그래픽 타일과 이동 타일은 분리한다.

| 개념 | 설명 |
|---|---|
| floor_cells | 화면에 바닥이 보이는 셀 |
| walk_cells | 유닛이 실제로 걸을 수 있는 셀 |
| blocked_cells | 바닥은 있지만 이동 불가인 셀 |
| prop_block_cells | 소품이 차지하는 이동 불가 셀 |
| socket_entry_cells | 통로 연결부 셀 |

유닛은 반드시 `DungeonWalkMap`에서 경로를 받아 이동한다.

```text
우클릭 위치
  ↓
world_to_grid()
  ↓
nearest_walkable_cell()
  ↓
AStarGrid2D.get_point_path()
  ↓
cell 경로를 world 좌표로 변환
  ↓
CharacterBody2D 이동
```

직선 이동 금지.
웨이포인트 사이도 반드시 walkable cell 경로로 분해한다.

---

## 8. 플레이어가 자유롭게 느끼는 방식

완전 자유건설 대신 아래 선택을 제공한다.

| 플레이어 행동 | 내부 구현 |
|---|---|
| 새 방 붙이기 | 빈 소켓에 RoomBlueprint 배치 |
| 복도 늘리기 | CorridorBlueprint 배치 |
| 방 방향 바꾸기 | Blueprint 회전 후 sockets 재계산 |
| 방 기능 교체 | 같은 footprint의 다른 Blueprint로 교체 |
| 방 확장 | 3×3 → 4×4 또는 5×5 Blueprint 교체 |
| 우회로 만들기 | T자/ㄱ자/십자 복도 배치 |
| 함정길 만들기 | walk_cells는 유지, TrapLayer에 함정 배치 |
| 장식 업그레이드 | floor tile은 유지, overlay/prop 교체 |

즉, 실제로는 안전한 프리셋 조립이지만, 플레이어는 경로와 방 구성을 바꾸는 느낌을 받는다.

---

## 9. Codex 구현 금지 사항

1. 방 하나를 배경 PNG 한 장으로 배치하지 말 것.
2. 복도 하나를 통짜 PNG 한 장으로 배치하지 말 것.
3. 유닛을 소켓 좌표 사이로 직선 이동시키지 말 것.
4. 그래픽 이미지의 투명 영역을 이동 가능 영역으로 추정하지 말 것.
5. 벽, 기둥, 보물더미를 바닥 타일과 같은 레이어에 굽지 말 것.
6. 마왕성 등급별로 모든 방 이미지를 새로 만들지 말 것.
7. 연결/비연결 2개 타일만으로 오토타일을 처리하지 말 것.

---

## 10. 결정 로그

| 항목 | 결정 |
|---|---|
| 기존 통짜 방 이미지 방식 | 폐기 |
| 신규 던전 표현 | 가상 쿼터뷰 그리드 + 타일 조립 |
| 방 데이터 | RoomBlueprint |
| 이동 데이터 | DungeonWalkMap |
| 연결 데이터 | SocketData |
| 바닥 연결 | 4방향 비트마스크 16개 |
| 정규버전 권장 | 16마스크 + 코너 오버레이 |
| 확장판 후보 | 47타일 블롭/왕타일 규칙 |
