# 06. Codex 구현 명세

이 문서는 Codex가 실제로 어떤 순서로 무엇을 구현해야 하는지 명령형으로 정리한 것이다.

## 1. 구현 목표

기존 "구역당 이미지 1장" 방식의 쿼터뷰 맵을 폐기하고,
아래 구조로 전환한다.

- 고정 최대 logical grid
- 등급별 active/unlock cell
- floor bitmask 16타일 규칙
- background + floor + edge + wall + object 다층 레이어
- socket 상태 3단계
- walkable cell 기반 이동

---

## 2. 필수 데이터 구조

### CastleGradeRules

```json
{
  "F": {"active_rect": {"x": 6, "y": 6, "w": 8, "h": 8}},
  "E": {"active_rect": {"x": 5, "y": 5, "w": 10, "h": 10}},
  "D": {"active_rect": {"x": 4, "y": 4, "w": 12, "h": 12}}
}
```

### CellData

```json
{
  "gx": 0,
  "gy": 0,
  "active": false,
  "cell_type": "void",
  "walkable": false,
  "room_id": null,
  "theme": "cave_f",
  "socket_state": "none"
}
```

### RoomBlueprint

```json
{
  "id": "room_treasure_small",
  "size": [3,3],
  "floor_cells": [[0,0],[1,0],[2,0],[0,1],[1,1],[2,1],[0,2],[1,2],[2,2]],
  "walk_cells": [[0,0],[1,0],[2,0],[0,1],[1,1],[2,1],[0,2],[1,2],[2,2]],
  "socket_entries": {
    "north": [1,0],
    "east": [2,1],
    "south": [1,2],
    "west": [0,1]
  },
  "default_socket_states": {
    "north": "closed",
    "east": "open_placeholder",
    "south": "closed",
    "west": "closed"
  }
}
```

---

## 3. 타일 결정 알고리즘

각 `floor` 셀에 대해:

1. logical grid 기준 N,E,S,W 인접 셀을 조사한다.
2. 인접 셀이 연결 가능한 floor류면 연결로 판정한다.
3. bitmask를 계산한다.
4. `floor_<theme>_mask_<mask>`를 선택한다.
5. 노출된 방향이 있으면 `EdgeSkirtLayer`에 해당 edge를 배치한다.

### pseudo code

```gdscript
func compute_floor_mask(gx:int, gy:int) -> int:
    var mask := 0
    if is_floor_connected(gx, gy - 1): mask += 1 # N
    if is_floor_connected(gx + 1, gy): mask += 2 # E
    if is_floor_connected(gx, gy + 1): mask += 4 # S
    if is_floor_connected(gx - 1, gy): mask += 8 # W
    return mask
```

---

## 4. 소켓 상태 변경 알고리즘

### 연결 전

- socket cell = `closed` 또는 `open_placeholder`
- 해당 방향 floor는 비연결로 처리
- doorway 대신 cap/wall sprite 배치

### 연결 후

- corridor 또는 room blueprint를 target cell에 배치
- 양쪽 socket 상태를 `connected`로 변경
- 관련 floor tile 재계산
- 관련 edge/wall sprite 제거 또는 교체
- walkable true로 변경

---

## 5. 배경 처리 규칙

- 맵 전체 뒤에는 배경 이미지 1장을 깐다.
- 등급별로 교체 가능하다.
- 배경 이미지는 `BackgroundVoidLayer` 전용이다.
- 바닥이 없는 셀에는 floor tile을 그리지 않는다.
- 대신 배경이 보이게 한다.

즉, 배경은 빈 공간 채우기용이다.

---

## 6. 그리드 확장 알고리즘

등급 업그레이드 시:

1. `CastleGradeRules`에서 새 active 영역 또는 unlock cells를 가져온다.
2. 해당 cell들의 `active = true`로 변경한다.
3. 새롭게 열린 cell는 기본적으로 `rock` 상태다.
4. 건설 가능한 슬롯만 `open_placeholder`로 바꾼다.
5. 전체 맵 렌더를 재생성한다.
6. 카메라 최대 범위만 확장한다.

기존 room 좌표는 옮기지 않는다.

---

## 7. Codex에 직접 넣을 명령문

```text
현재 쿼터뷰 커스텀 맵 시스템을 다음 규칙으로 전환해라.

1. 최대 20x20 logical grid를 먼저 만든다.
2. 마왕성 등급에 따라 active cell만 늘어난다. grid 배열 자체를 재생성하지 않는다.
3. 각 cell은 active, cell_type, walkable, room_id, socket_state를 가진다.
4. floor cell은 N/E/S/W 4방향 연결 여부를 비트마스크(1,2,4,8)로 계산한다.
5. 계산된 값 0~15를 그대로 floor tile 번호에 대응한다.
6. floor tile은 floor_<theme>_mask_00~15 파일명을 사용한다.
7. 연결되지 않은 방향은 exposed edge로 판단하고 EdgeSkirtLayer에 edge sprite를 추가한다.
8. 소켓은 closed, open_placeholder, connected 3상태를 가진다.
9. connected로 바뀌면 corridor blueprint를 추가하고 양쪽 타일을 재계산한다.
10. 배경 이미지는 BackgroundVoidLayer에만 사용하고, 연결/이동 판정에는 절대 사용하지 않는다.
11. 모든 AI 이동과 직접 조종 이동은 walkable cell 기반 경로만 사용한다.
12. 구역당 통짜 이미지 1장 배치 방식은 사용하지 않는다.
```
