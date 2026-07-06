# 03. 16타일 마스크 규칙

## 1. 왜 16개가 필요한가

바닥 cell 하나는 주변 4방향의 연결 여부에 따라 다른 이미지를 써야 한다.
논리 그리드 기준으로 인접 방향은 다음이다.

- N = 위
- E = 오른쪽
- S = 아래
- W = 왼쪽

각 방향은 연결 또는 비연결 2상태다.

따라서 경우의 수는:

`2^4 = 16`

즉, 최소 16개 바닥 변형이 필요하다.

---

## 2. 비트 규칙

비트는 반드시 아래처럼 고정한다.

| 방향 | 값 |
|---|---:|
| N | 1 |
| E | 2 |
| S | 4 |
| W | 8 |

마스크 값 계산은 다음과 같다.

```text
mask = 0
if north is connected: mask += 1
if east is connected:  mask += 2
if south is connected: mask += 4
if west is connected:  mask += 8
```

즉, `mask = 13` 이면 `N + S + W` 연결이다.

---

## 3. 타일 번호 규칙

Codex는 **반드시 아래 파일명/번호 규칙을 쓴다.**

```text
floor_cave_f_mask_00.png
floor_cave_f_mask_01.png
floor_cave_f_mask_02.png
...
floor_cave_f_mask_15.png
```

이 규칙이면 계산 결과를 그대로 파일 번호로 연결할 수 있다.

---

## 4. 마스크별 의미표

| mask | 연결 방향 | 의미 |
|---:|---|---|
| 0 | 없음 | 고립 바닥 / 단독 셀 |
| 1 | N | 북쪽만 연결 |
| 2 | E | 동쪽만 연결 |
| 3 | N,E | 북동 코너 |
| 4 | S | 남쪽만 연결 |
| 5 | N,S | 세로 직선 |
| 6 | E,S | 남동 코너 |
| 7 | N,E,S | 동쪽 T자 |
| 8 | W | 서쪽만 연결 |
| 9 | N,W | 북서 코너 |
| 10 | E,W | 가로 직선 |
| 11 | N,E,W | 위쪽 T자 |
| 12 | S,W | 남서 코너 |
| 13 | N,S,W | 서쪽 T자 |
| 14 | E,S,W | 아래쪽 T자 |
| 15 | N,E,S,W | 십자 / 중앙 |

---

## 5. 연결 판정 기준

### floor 연결로 인정되는 이웃

다음 셀 타입은 연결로 인정한다.

- `floor`
- `door` (문이 열려 있고 walkable일 때)
- `socket_marker` 중 `connected`

다음은 연결로 인정하지 않는다.

- `void`
- `rock`
- `closed` socket
- `open_placeholder` socket
- 큰 오브젝트로 막힌 비통행 셀

---

## 6. 예시

### 예시 A. 직선 통로

```text
. . .
X X X
. . .
```

가운데 세 셀의 마스크는 다음과 같다.

- 왼쪽 셀: E만 연결 → `02`
- 가운데 셀: E,W 연결 → `10`
- 오른쪽 셀: W만 연결 → `08`

### 예시 B. 방 입구가 막힌 상태

```text
방 셀 - 입구 셀 - 빈 공간
```

입구 셀이 아직 closed socket이라면,
방 셀은 그 방향을 연결로 계산하지 않는다.
즉, 해당 방향은 비연결 edge를 가진 타일을 써야 한다.

---

## 7. 16개만으로 부족한 경우

16개 바닥 마스크는 "기본 floor silhouette" 규칙이다.
여기에 아래 오버레이를 추가할 수 있다.

- crack overlay
- border shadow overlay
- slime stain overlay
- magic rune overlay
- grade-specific decal overlay

즉, 기본 floor tile은 16개만으로 계산하고,
분위기 차이는 오버레이로 늘리는 것이 정답이다.
