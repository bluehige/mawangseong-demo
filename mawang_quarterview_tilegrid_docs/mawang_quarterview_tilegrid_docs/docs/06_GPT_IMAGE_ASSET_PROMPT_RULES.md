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
