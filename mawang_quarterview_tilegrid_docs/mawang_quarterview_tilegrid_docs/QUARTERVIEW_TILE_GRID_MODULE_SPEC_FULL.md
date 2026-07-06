# 쿼터뷰 타일 그리드 전환 통합 문서 v3



---

# 마왕성 쿼터뷰 던전 제작 핵심 규칙 v3 — 바로 붙여넣기용

프로젝트 「마왕님, 마왕성은 누가 지켜요?」의 쿼터뷰 던전은 더 이상 “구역당 통짜 이미지 1장”으로 만들지 않는다.

핵심 규칙:
1. 던전은 반드시 가상 쿼터뷰 그리드 위에 만든다.
2. 방/복도는 통짜 배경 이미지가 아니라 floor tile, edge tile, wall tile, door/arch tile, prop object를 조립해 만든다.
3. 소켓은 방 연결 가능 여부만 판단한다. 실제 이동 가능 여부는 DungeonWalkMap의 walkable cell만 따른다.
4. 모든 바닥 셀은 4방향 연결 상태를 계산해 오토타일을 고른다.
5. 연결/비연결은 한 장/두 장 문제가 아니다. 4방향 각각 연결 여부가 있으므로 최소 2^4 = 16개 마스크가 필요하다.
6. 더 자연스러운 바닥 전환은 8방향 모서리까지 고려해 47타일 블롭 규칙 또는 16마스크 + 코너 오버레이 규칙을 쓴다.
7. 마왕성 규모가 커져도 같은 타일 이미지를 반복 배치하면 된다. 그리드가 커진다고 이미지 수가 선형으로 늘어나지는 않는다.
8. 마왕성 등급이 바뀔 때는 같은 타일 개수의 테마 세트를 교체하거나, 기존 타일 위에 업그레이드 오버레이를 얹는다.
9. 오브젝트 이미지는 종류별로 필요한 방향, 상태, 애니메이션 프레임 수를 계산해서 만든다.
10. 모든 캐릭터/오브젝트의 기준점은 “발밑 중앙” 또는 “점유 셀의 앞쪽 중심”으로 통일한다.
11. Godot에서는 FloorLayer, EdgeLayer, BackWallLayer, ObjectBackLayer, UnitYSortLayer, FrontWallLayer, DebugOverlayLayer를 분리한다.
12. Codex는 방 이미지를 새로 생성하지 말고, RoomBlueprint의 cell 배열을 읽어 타일을 깔고 오브젝트를 배치해야 한다.

권장 기준:
- 논리 셀: Vector2i(x, y)
- 쿼터뷰 타일: 128×64px diamond
- 벽/문/큰 오브젝트 캔버스: 128×128, 256×192, 256×256px
- 방향 명칭: NW, NE, SE, SW
- 연결 마스크 비트: NW=1, NE=2, SE=4, SW=8
- 이동 경로: AStarGrid2D + walkable cell
- 렌더 정렬: Y-sort + z_index 레이어 분리


---

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


---

# 02. 쿼터뷰 오브젝트별 필요 이미지 수와 변형 계산 규칙

## 1. 핵심 공식

이미지 수는 감으로 정하지 않는다.
아래 공식으로 계산한다.

```text
필요 이미지 수 =
방향 수 × 상태 수 × 애니메이션 프레임 수 × 테마 수 × 피해/업그레이드 변형 수
```

예시:

```text
문 이미지 =
2방향 × 3상태(닫힘/열림/파손) × 1프레임 × 5테마 = 30장
```

하지만 실제 제작에서는 모든 항목에 테마 수를 곱하지 않는다.
문틀은 테마별로 바꾸고, 문짝은 공용으로 쓰는 식으로 줄일 수 있다.

---

## 2. 타일/오브젝트 분류

쿼터뷰 던전 리소스는 크게 7종으로 나눈다.

| 분류 | 예시 | 연결 계산 필요 |
|---|---|---|
| Floor Tile | 동굴 바닥, 성채 바닥 | 필요 |
| Edge/Skirt Tile | 바닥 가장자리, 절벽/단차 | 필요 |
| Wall Tile | 뒤쪽 벽, 앞쪽 벽 | 필요 |
| Door/Gate Tile | 문, 아치, 성문 | 방향/상태 필요 |
| Room Prop | 왕좌, 보물더미, 무기대 | 방향/상태 선택 |
| Trap Tile | 가시, 마법진, 독안개 | 상태/애니메이션 필요 |
| Unit Sprite | 몬스터, 적 | 방향/애니메이션 필요 |

---

## 3. Floor Tile 필요 수

### 3-1. 최소 방식

| 항목 | 이미지 수 |
|---|---:|
| 중앙 바닥 변형 | 4 |
| 4방향 연결 마스크 | 16 |
| 코너 보정 오버레이 | 8 |
| 균열/얼룩/작은 해골 데칼 | 8~12 |
| 합계 | 36~40 |

이 방식이 정규버전 1.0에 적합하다.

### 3-2. 고급 방식

| 항목 | 이미지 수 |
|---|---:|
| 47타일 블롭/왕타일 규칙 | 47 |
| 중앙 바닥 변형 | 6~10 |
| 코너/데칼 오버레이 | 12~20 |
| 합계 | 65~77 |

확장판 또는 후반 폴리싱용이다.

### 3-3. 왜 16장이 최소인가

4방향이 각각 연결/비연결을 가진다.

```text
NW = 연결/비연결
NE = 연결/비연결
SE = 연결/비연결
SW = 연결/비연결

2^4 = 16
```

“연결 타일 1장 + 비연결 타일 1장”은 방향을 표현할 수 없다.
직선 복도, 코너 복도, T자 연결, 십자 연결이 전부 다른 모양이어야 한다.

---

## 4. Edge/Skirt Tile 필요 수

Edge/Skirt는 바닥이 끊긴 외곽을 표현한다.
쿼터뷰에서는 바닥의 앞쪽/옆쪽 단차가 특히 중요하다.

### MVP

| 항목 | 이미지 수 |
|---|---:|
| 단일 노출 edge 4방향 | 4 |
| 바깥 코너 4방향 | 4 |
| 안쪽 코너 4방향 | 4 |
| 합계 | 12 |

### 정규버전

| 항목 | 이미지 수 |
|---|---:|
| 단일 노출 edge 4방향 × 2변형 | 8 |
| 바깥 코너 4방향 × 2변형 | 8 |
| 안쪽 코너 4방향 × 2변형 | 8 |
| 짧은 단차/긴 단차 | 4~8 |
| 합계 | 28~32 |

---

## 5. Wall Tile 필요 수

벽은 방향이 중요하다.
쿼터뷰에서 벽은 보통 두 축으로 충분하다.

| 방향 | 의미 |
|---|---|
| NW wall | 오른쪽 아래를 향해 보이는 벽면 |
| NE wall | 왼쪽 아래를 향해 보이는 벽면 |

반대 방향 벽은 앞벽/전경 오클루더로 따로 처리한다.

### MVP 벽 세트

| 항목 | 계산 | 이미지 수 |
|---|---|---:|
| 직선 벽 | 2방향 × 1 | 2 |
| 벽 끝 | 2방향 × 2끝 | 4 |
| 외곽 코너 | 4방향 | 4 |
| 안쪽 코너 | 4방향 | 4 |
| 문 연결 벽 | 2방향 | 2 |
| 합계 | 16 |

### 정규버전 벽 세트

| 항목 | 계산 | 이미지 수 |
|---|---|---:|
| 직선 벽 | 2방향 × 3변형 | 6 |
| 벽 끝 | 2방향 × 2끝 × 2변형 | 8 |
| 외곽 코너 | 4방향 × 2변형 | 8 |
| 안쪽 코너 | 4방향 × 2변형 | 8 |
| 문 연결 벽 | 2방향 × 2변형 | 4 |
| 파손/균열 오버레이 | 8~12 | 8~12 |
| 합계 | 42~46 |

---

## 6. Door/Gate 필요 수

문은 반드시 방향과 상태가 필요하다.

### 일반 방문

| 요소 | 수 |
|---|---:|
| 방향 | 2 |
| 상태 | 닫힘, 열림, 잠김, 파손 = 4 |
| 기본 이미지 수 | 2 × 4 = 8 |

### 성문

| 요소 | 수 |
|---|---:|
| 방향 | 1~2 |
| 상태 | 닫힘, 열림, 파손, 강화 = 4 |
| 애니메이션 | 열림 4프레임 |
| 기본 이미지 수 | 정지 4~8장 + 열림 4~8프레임 |

성문은 큰 오브젝트이므로 통짜 이미지로 만들어도 된다.
단, 성문은 **방 전체 배경**이 아니라 **그리드 위에 놓는 오브젝트**다.

---

## 7. Room Prop 필요 수

소품은 연결 계산이 필요 없는 경우가 많다.
하지만 방향과 상태는 필요할 수 있다.

| 오브젝트 | 권장 방향 수 | 상태 수 | 필요 이미지 |
|---|---:|---:|---:|
| 왕좌 | 1 | 3등급 | 3 |
| 보물더미 | 1 | 4단계 | 4 |
| 무기대 | 2 | 1 | 2 |
| 회복 둥지 | 1 | 3단계 | 3 |
| 버섯 농장 | 1 | 3성장 | 3 |
| 마력 수정 | 1 | 3발광 | 3 |
| 기둥 | 1 | 2파손 | 2 |
| 횃불 | 1 | 4프레임 | 4 |
| 깃발 | 2 | 4프레임 | 8 |

### 소품 제작 원칙

- 1×1 footprint 소품은 128×128px.
- 2×1 footprint 소품은 256×128 또는 256×192px.
- 2×2 footprint 소품은 256×256px.
- 발밑/점유 기준점은 반드시 셀 중심에 맞춘다.
- 큰 소품은 이동을 막는 `prop_block_cells`를 가져야 한다.

---

## 8. Trap 필요 수

함정은 상태와 애니메이션이 중요하다.

| 함정 | 방향 | 상태/프레임 | 필요 이미지 |
|---|---:|---:|---:|
| 가시 바닥 | 1 | idle, trigger 4프레임, cooldown | 6 |
| 낙석 | 1 | idle, falling 5프레임, debris | 7 |
| 독안개 | 1 | loop 6프레임 | 6 |
| 마법진 | 1 | idle 1, charge 4, burst 4 | 9 |
| 끈끈이 점액 | 1 | idle, active 4프레임 | 5 |

복도 방향에 따라 긴 함정이 필요하면 2방향을 곱한다.

```text
긴 가시줄 = 2방향 × 6상태/프레임 = 12장
```

---

## 9. Unit Sprite 필요 수

쿼터뷰 캐릭터는 최소 4방향이 필요하다.

| 방향 | 설명 |
|---|---|
| down_left | 화면 왼쪽 아래 방향 |
| down_right | 화면 오른쪽 아래 방향 |
| up_left | 화면 왼쪽 위 방향 |
| up_right | 화면 오른쪽 위 방향 |

좌우 반전을 허용하면 2방향만 제작하고 flip으로 줄일 수 있다.
하지만 무기 방향이나 비대칭 디자인이 있으면 4방향을 권장한다.

### 9-1. 최소 유닛 스프라이트

| 애니메이션 | 방향 | 프레임 | 이미지 수 |
|---|---:|---:|---:|
| idle | 4 | 4 | 16 |
| walk | 4 | 6 | 24 |
| attack/cast | 4 | 6 | 24 |
| hit | 4 | 2 | 8 |
| down | 1 | 3 | 3 |
| 합계 |  |  | 75 |

### 9-2. 절약형 유닛 스프라이트

| 애니메이션 | 방향 | 프레임 | 이미지 수 |
|---|---:|---:|---:|
| idle | 2 + flip | 4 | 8 |
| walk | 2 + flip | 6 | 12 |
| attack/cast | 2 + flip | 6 | 12 |
| hit | 2 + flip | 2 | 4 |
| down | 1 | 3 | 3 |
| 합계 |  |  | 39 |

정규버전 1.0에서는 **중요 유닛 4방향**, 일반 적/소형 몬스터는 **2방향+flip**으로 시작해도 된다.

---

## 10. 마왕성 등급별 이미지 수 계산

마왕성 등급은 F, E, D, C, B, A로 잡는다.
모든 등급에 모든 타일을 새로 그리면 폭발한다.

### 나쁜 방식

```text
방 24종 × 등급 6개 × 방 이미지 1장 = 144장
```

겉으로는 적어 보이지만, 연결부가 맞지 않아 결국 각 입구/복도 방향별로 다시 만들게 된다.
방마다 입구 방향, 연결부, 크기, 회전까지 고려하면 금방 수백 장이 된다.

### 좋은 방식

```text
테마 타일 세트 1개 =
바닥 40 + edge 24 + 벽 32 + 문 8 + 데칼 20 = 약 124장

등급 6개 전부 독립 제작 =
124 × 6 = 744장

현실적 1.0 제작 =
F/E/D/A 4개 테마만 직접 제작 + B/C는 overlay와 색 보정으로 대체
124 × 4 + overlay 80 = 약 576장
```

하지만 실제로는 모든 타일을 처음부터 다 만들지 않는다.
1.0 권장 범위는 아래다.

| 테마 | 용도 | 직접 제작 수준 |
|---|---|---|
| F 동굴 | 초반 핵심 | 완성 |
| E 소굴 | 2챕터 | 완성 |
| D 지하요새 | 중반 | 완성 |
| C 흑철성채 | 후반 | 축약 |
| A 마왕성 | 최종전 | 핵심 방 중심 |

---

## 11. 그리드가 커질 때 이미지 수가 늘어나는가

결론:

> **그리드가 커져도 같은 타일 이미지를 반복해서 쓰면 된다. 이미지 수는 그리드 크기와 비례하지 않는다.**

예시:

| 마왕성 크기 | 필요한 바닥 타일 이미지 수 |
|---|---:|
| 8×8 | 16~40장 |
| 16×16 | 16~40장 |
| 32×32 | 16~40장 |
| 64×64 | 16~40장 |

단, 큰 맵일수록 반복 티가 난다.
그래서 큰 맵에는 **추가 이미지**가 아니라 **변형/데칼/오버레이**를 넣는다.

| 문제 | 해결 |
|---|---|
| 같은 바닥 반복 | 중앙 바닥 변형 4~10개 |
| 빈 방이 심심함 | 해골, 균열, 촛농, 마력 문양 데칼 |
| 등급 변화가 약함 | 색상 팔레트 + 장식 오버레이 |
| 큰 방이 단조로움 | 2×2 대형 패턴 오버레이 |
| 통로가 밋밋함 | 벽등, 깃발, 사슬, 작은 뼈더미 |

---

## 12. 정규버전 1.0 권장 리소스 수

### 12-1. F급 동굴 테마

| 분류 | 권장 수 |
|---|---:|
| 바닥 오토타일 | 24~40 |
| edge/skirt | 12~24 |
| 벽 | 16~32 |
| 문/입구 | 6~8 |
| 방 소품 | 25~35 |
| 함정 | 12~20 |
| 데칼 | 20 |
| 합계 | 115~179 |

### 12-2. E급 소굴 테마

F급 타일을 재활용하고 장식만 강화한다.

| 분류 | 권장 수 |
|---|---:|
| 신규 바닥/벽 | 40~60 |
| 신규 장식 | 20~30 |
| 신규 문/깃발 | 8~12 |
| 합계 | 68~102 |

### 12-3. 전체 1.0 권장

| 분류 | 권장 수 |
|---|---:|
| 던전 타일/벽/문 | 250~350 |
| 방 소품 | 100~160 |
| 함정/이펙트 | 50~80 |
| 몬스터/적 스프라이트 | 유닛당 39~75 |
| UI 아이콘 | 80~120 |
| 아이템 아이콘 | 60~80 |

---

## 13. 결론

1. 구역 이미지 1장 방식은 폐기한다.
2. 바닥은 최소 16마스크를 사용한다.
3. 자연스러운 연결은 16마스크 + 코너 오버레이부터 시작한다.
4. 오브젝트는 방향 × 상태 × 프레임으로 계산한다.
5. 마왕성 크기가 커져도 같은 타일 세트를 반복 사용한다.
6. 업그레이드는 테마 교체 + 오버레이로 처리한다.
7. 모든 이동은 walkable cell로 제한한다.


---

# 03. 마왕성 업그레이드와 그리드 확장 규칙

## 1. 목표

마왕성은 F급 동굴에서 A급 마왕성까지 커져야 한다.
하지만 그리드가 커질 때마다 새 이미지를 무한히 만들면 제작이 불가능하다.

따라서 정규버전에서는 아래 원칙을 따른다.

> **규모는 그리드/방 수로 키우고, 품질은 테마/오버레이로 바꾼다.**

---

## 2. 마왕성 등급별 그리드 크기

| 등급 | 이름 | 권장 그리드 | 방 슬롯 | 핵심 변화 |
|---|---|---:|---:|---|
| F | 비 새는 동굴 | 8×8 | 6 | 기본 방어 |
| E | 수상한 소굴 | 10×10 | 8 | 보물고/함정 강화 |
| D | 지하 요새 | 12×12 | 10 | 복도 분기, 병영 확장 |
| C | 흑철 성채 | 14×14 | 12 | 마력로, 특수 방 |
| B | 마력 왕성 | 16×16 | 14 | 고급 장식, 강한 침입자 |
| A | 정식 마왕성 | 18×18 | 16 | 최종전 규모 |

정규버전 1.0에서는 18×18 이상을 권장하지 않는다.
실시간 전투와 경로 탐색, UI 가독성을 먼저 안정화해야 한다.

---

## 3. 같은 이미지 수로 커지는 방법

타일맵은 같은 이미지를 반복해서 넓은 맵을 만든다.
따라서 8×8에서 쓰던 바닥 타일은 18×18에서도 그대로 쓴다.

```text
F급 8×8 = floor tile 64개 배치
A급 18×18 = floor tile 324개 배치

이미지 파일 수 = 동일
배치 횟수 = 증가
```

이미지 수를 늘리는 기준은 “크기”가 아니라 “반복 티”다.

| 맵 크기 | 추가 필요 |
|---|---|
| 8×8 | 중앙 바닥 변형 3~4개면 충분 |
| 12×12 | 바닥 변형 6개, 데칼 10개 권장 |
| 16×16 | 바닥 변형 8개, 대형 데칼 필요 |
| 18×18 | 구역별 색조/조명 오버레이 권장 |

---

## 4. 업그레이드 시각 변화 방식

마왕성 등급 상승은 세 가지 레이어로 표현한다.

### 4-1. 구조 확장

- 신규 소켓 개방
- 빈 건설 슬롯 증가
- 복도 길이 증가
- 왕좌의 방 주변 방 추가

### 4-2. 테마 교체

- F: 흙, 나무, 조잡한 횃불
- E: 보라 깃발, 작은 해골, 보물더미
- D: 석벽, 철문, 병영 장식
- C: 흑철 벽, 마력 수정, 사슬
- B: 마력 회로, 검은 장막, 고급 카펫
- A: 왕좌홀, 거대 문장, 첨탑 장식

### 4-3. 오버레이 추가

- 깃발
- 사슬
- 마력 문양
- 벽등
- 해골 장식
- 보라색 안개
- 금화 더미
- 균열/수리 흔적

---

## 5. 등급별 타일 세트 제작 전략

### 5-1. 권장 제작 순서

| 순서 | 제작 대상 | 이유 |
|---:|---|---|
| 1 | F급 동굴 완성 | 데모/초반 핵심 |
| 2 | D급 지하요새 완성 | 중반 체감 변화 |
| 3 | A급 마왕성 핵심 완성 | 최종 목표 시각화 |
| 4 | E급 소굴 | F와 D 사이 연결 |
| 5 | C/B급 | 오버레이 중심으로 보강 |

### 5-2. 등급별 직접 제작/재활용 기준

| 등급 | 바닥 | 벽 | 문 | 소품 | 설명 |
|---|---|---|---|---|---|
| F | 직접 | 직접 | 직접 | 직접 | 완전 제작 |
| E | F 변형 | F 변형 | 일부 직접 | 직접 | 소굴 장식 추가 |
| D | 직접 | 직접 | 직접 | 직접 | 중반 핵심 |
| C | D 변형 | 직접 일부 | 직접 | 직접 | 흑철 느낌 |
| B | C 오버레이 | C 오버레이 | 직접 일부 | 직접 | 마력 장식 |
| A | 직접 핵심 | 직접 핵심 | 직접 | 직접 | 최종전용 |

---

## 6. 방 크기 확장 규칙

방은 이미지 크기로 늘리지 않고 cell 수로 늘린다.

| 방 등급 | 크기 | 설명 |
|---|---:|---|
| 소형 방 | 3×3 | 초반 기본 방 |
| 중형 방 | 4×4 | 병영, 보물고 확장 |
| 대형 방 | 5×5 | 왕좌의 방, 보스방 |
| 긴 복도 | 1×3~1×6 | 적 지연용 |
| 넓은 복도 | 2×3~2×6 | 대규모 전투용 |

방이 커질 때 필요한 것은 새 통짜 이미지가 아니라 다음 데이터다.

```json
{
  "id": "treasure_room_5x5",
  "size": [5, 5],
  "floor_cells": [[0,0], [1,0], "..."],
  "walk_cells": [[0,0], [1,0], "..."],
  "object_slots": [
    {"id": "treasure_pile_large", "cell": [2,2]},
    {"id": "gold_crate", "cell": [1,3]},
    {"id": "mimic_hide_spot", "cell": [3,3]}
  ]
}
```

---

## 7. 확장 가능한 마왕성 레이아웃 규칙

정규버전에서는 플레이어가 완전 자유 타일 편집을 하지 않는다.
대신 아래 확장을 제공한다.

| 확장 방식 | 체감 |
|---|---|
| 신규 소켓 개방 | “새 구역이 열렸다” |
| 복도 방향 선택 | “침입자 경로를 바꿨다” |
| 방 크기 업그레이드 | “방이 커졌다” |
| 방 기능 교체 | “내가 원하는 빌드로 바꿨다” |
| 우회로 추가 | “함정길을 설계했다” |
| 왕좌 주변 확장 | “진짜 마왕성에 가까워졌다” |

---

## 8. 성능 기준

마왕성 최대 18×18 기준:

| 항목 | 목표 |
|---|---:|
| 바닥 셀 | 최대 324 |
| 활성 유닛 | 아군 30 이하, 적 50 이하 |
| 활성 투사체 | 40 이하 |
| Y-sort 대상 | 150 이하 |
| 전투 FPS | 60 목표, 최소 45 |
| AStarGrid 재빌드 | 건설/철거 시만 |

AStarGrid는 매 프레임 재빌드하지 않는다.
방을 짓거나 철거하거나 큰 오브젝트가 바뀔 때만 재빌드한다.

---

## 9. 마왕성 업그레이드 체크리스트

| 체크 | 항목 |
|---|---|
| ☐ | 등급 상승 시 그리드 크기가 증가한다 |
| ☐ | 신규 소켓이 열린다 |
| ☐ | 방 슬롯 수가 증가한다 |
| ☐ | 기존 방은 유지된다 |
| ☐ | 타일 테마 또는 오버레이가 바뀐다 |
| ☐ | 기존 저장 데이터가 깨지지 않는다 |
| ☐ | DungeonWalkMap이 재빌드된다 |
| ☐ | 모든 적 경로가 왕좌의 방까지 연결된다 |


---

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


---

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


---

# 06. GPT Image 리소스 생성 규칙 — 쿼터뷰 타일/오브젝트

## 1. 기본 프롬프트 원칙

이미지 생성 시 절대 “방 전체”를 만들지 않는다.
항상 개별 타일 또는 개별 오브젝트로 만든다.

금지:
- complete dungeon room background
- full room map
- connected room screenshot
- one big cave room image

허용:
- single isometric floor tile
- seamless isometric cave floor tile
- isometric wall segment
- isometric doorway object
- transparent background prop
- individual trap animation frame

---

## 2. 공통 스타일

```text
cute horror fantasy, rookie demon king castle, dark cave, purple magic torchlight, small skull decorations, adorable monster-friendly style, clean readable 2D isometric game asset, orthographic isometric projection, no text, no logo, transparent background
```

### 고정 시점

```text
2:1 isometric diamond tile, orthographic, camera looking from upper front, consistent lighting from upper left, transparent background
```

---

## 3. 바닥 타일 프롬프트 예시

```text
Create a single seamless 2D isometric diamond floor tile for a cute horror fantasy demon king cave castle. Tile size target 128x64, 2:1 isometric diamond, dark stone cave floor, subtle purple magic glow, tiny cracks and small skull pebble details, clean edges that can connect seamlessly to adjacent tiles, orthographic isometric projection, transparent background, no text, no characters.
```

Mask 타일은 직접 이미지 생성만으로 정확히 만들기 어렵다.
권장 작업은 다음이다.

1. 중앙 바닥 타일 여러 개 생성
2. edge/코너 오버레이를 별도로 생성
3. Codex 또는 이미지 편집으로 16마스크 타일시트 구성
4. 사람이 검수

---

## 4. 벽 타일 프롬프트 예시

```text
Create a single isometric wall segment for a cute horror fantasy demon king cave castle. Direction: NE wall segment. It should fit a 128x128 transparent canvas and align with a 128x64 isometric floor diamond. Dark rough cave stone wall, purple torch glow, small skull decoration, clean game asset, orthographic isometric, transparent background, no text, no characters.
```

방향별로 반드시 나눠 생성한다.

| 방향 | 프롬프트에 넣을 문구 |
|---|---|
| NE | Direction: NE wall segment |
| NW | Direction: NW wall segment |
| front NE | front occluding wall segment, Direction NE |
| front NW | front occluding wall segment, Direction NW |

---

## 5. 문/아치 프롬프트 예시

```text
Create an isometric dungeon doorway arch object for a cute horror fantasy rookie demon king castle. Direction: NE. State: closed. Dark cave stone doorway with small purple magic lamp and tiny skull ornament, 2D isometric game asset, transparent background, fits on a 128x128 canvas, no text, no characters.
```

상태별로 생성:

- closed
- open
- locked
- broken

---

## 6. 소품 프롬프트 예시

### 왕좌

```text
Create a cute horror fantasy demon king throne prop for a 2D isometric game. Small rookie demon king throne made of dark stone and bones, purple magic glow, adorable spooky style, transparent background, no text, no characters, object footprint 2x2 isometric cells, canvas 256x256, anchor at front center.
```

### 보물더미

```text
Create an isometric treasure pile prop for a cute horror fantasy demon king castle. Gold coins, small chest, purple crystals, tiny skull decoration, transparent background, no text, no characters, 2D isometric game asset, footprint 2x2 cells, canvas 256x192.
```

### 병영 무기대

```text
Create an isometric weapon rack prop for a cute horror fantasy demon king cave barracks. Small goblin-sized weapons, wooden rack, bones and purple cloth, transparent background, no text, no characters, 2D isometric game asset, footprint 1x1 cell.
```

---

## 7. 스프라이트 방향 프롬프트

유닛은 최소 2방향 + flip 또는 4방향이 필요하다.

```text
Create a 2D isometric game character sprite frame, cute horror fantasy style, transparent background. Character: blue slime tank monster, direction down_right, animation idle frame 1 of 4, orthographic isometric, consistent top-left purple cave lighting, no text, no shadow outside character footprint.
```

방향:
- down_right
- down_left
- up_right
- up_left

애니메이션:
- idle
- walk
- attack/cast
- hit
- down

---

## 8. 이미지 검수 규칙

| 체크 | 기준 |
|---|---|
| ☐ | 투명 배경인가 |
| ☐ | 텍스트가 없는가 |
| ☐ | 2:1 쿼터뷰 방향인가 |
| ☐ | 타일 가장자리가 다른 타일과 이어지는가 |
| ☐ | 그림자가 셀 밖으로 과하게 삐져나오지 않는가 |
| ☐ | 기준점이 발밑/앞중앙에 맞는가 |
| ☐ | 같은 테마의 조명 방향이 같은가 |
| ☐ | 벽/문/소품이 바닥과 스케일이 맞는가 |


---

# 07. 참고 자료 요약

이 문서는 프로젝트 내부 기준을 위한 참고 요약이다.

## 1. 엔진/툴 문서에서 확인한 점

- Godot 4.5의 TileMapLayer는 TileSet을 사용하는 2D 타일 기반 맵 노드이며, 여러 TileMapLayer를 나눠 기존 TileMap처럼 여러 레이어를 구성할 수 있다.
- Godot TileSet은 atlas source, scene source, physics layer 등 타일 속성 레이어를 지원한다.
- Godot AStarGrid2D는 diamond cell shape을 제공하므로 isometric look의 그리드 경로 탐색에 사용할 수 있다.
- Godot CanvasItem은 y_sort_enabled와 z_index를 제공하므로 쿼터뷰 유닛/오브젝트 앞뒤 정렬에 사용할 수 있다.
- Tiled는 orthogonal, isometric, hexagonal 등 여러 projection의 타일맵을 지원하고, Terrain Brush는 Terrain Set 정보를 기반으로 지형 전환을 칠한다.
- Unity 2D Tilemap도 isometric tilemap과 tile palette 워크플로우를 제공한다.
- Unity 공식 블로그는 isometric/hexagonal grid layout 기반 2D 환경 제작 방식을 Diablo, Fallout, Civilization, Age of Empires 같은 고전 사례와 연결해 설명한다.
- MDN도 isometric tilemap이 2D simulation, strategy, RPG에서 널리 쓰이며 SimCity 2000, Pharaoh, Final Fantasy Tactics 같은 예시를 든다.

## 2. 이 프로젝트에 적용한 결론

1. 쿼터뷰 방을 통짜 이미지로 만들지 않는다.
2. 논리 그리드 위에 타일과 오브젝트를 얹는다.
3. 바닥 연결은 최소 4방향 16마스크가 필요하다.
4. 자연스러운 연결은 terrain/wang/autotile 계열 규칙으로 해결한다.
5. 마왕성 규모 확장은 새 이미지 생성이 아니라 같은 타일 반복 배치와 소켓/그리드 확장으로 해결한다.
6. 등급 상승은 테마 교체와 오버레이로 해결한다.
7. 이동 가능 영역은 이미지 모양이 아니라 walkable cell 데이터로 관리한다.

## 3. 참조 URL

- Godot TileMapLayer: https://docs.godotengine.org/en/4.5/classes/class_tilemaplayer.html
- Godot TileSet: https://docs.godotengine.org/en/4.5/classes/class_tileset.html
- Godot AStarGrid2D: https://docs.godotengine.org/en/4.4/classes/class_astargrid2d.html
- Godot CanvasItem: https://docs.godotengine.org/en/stable/classes/class_canvasitem.html
- Tiled Terrain: https://doc.mapeditor.org/en/stable/manual/terrain/
- Tiled editor overview: https://thorbjorn.itch.io/tiled
- Unity Isometric Tilemap: https://docs.unity3d.com/6000.1/Documentation/Manual/tilemaps/work-with-tilemaps/isometric-tilemaps/create-tile-palette-isometric-tilemap.html
- Unity Isometric Tilemap blog: https://unity.com/blog/engine-platform/isometric-2d-environments-with-tilemap
- MDN Tilemaps overview: https://developer.mozilla.org/en-US/docs/Games/Techniques/Tilemaps
