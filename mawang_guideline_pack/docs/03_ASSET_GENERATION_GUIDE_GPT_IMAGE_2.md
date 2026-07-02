# 03. gpt-image-2 리소스 생성 지침

이 문서는 「마왕님, 마왕성은 누가 지켜요?」의 이미지 리소스를 gpt-image-2로 만들 때 사용하는 기준이다.

---

## 1. 공통 아트 방향

| 항목 | 기준 |
|---|---|
| 스타일 | 큐트 호러 판타지 |
| 시점 | 2D 쿼터뷰 게임용 스프라이트. 3/4 하향 시점에서 얼굴, 몸통, 발밑 위치가 함께 읽혀야 함 |
| 분위기 | 어두운 동굴, 보라색 마력 조명, 귀여운 몬스터, 작은 해골 장식 |
| 대상 연령 느낌 | 잔혹하지 않은 코믹 판타지 |
| 형태 | SD 비율, 큰 머리, 작은 몸, 명확한 실루엣 |
| 배경 | 캐릭터/아이콘은 투명 배경으로 후처리 가능해야 함 |
| 금지 | 기존 IP와 닮은 캐릭터, 성인 요소, 고어, UI 텍스트가 박힌 이미지 |

---

## 2. 리소스 생성 원칙

1. **게임 화면용 UI 텍스트는 이미지에 넣지 않는다.**
   텍스트는 Godot Label로 표시한다.

2. **스프라이트시트는 한 번에 완성하려 하지 않는다.**
   먼저 캐릭터 기준 이미지 → 포즈별 이미지 → 프레임 정리 → SpriteFrames 구성 순서로 진행한다.

3. **한 캐릭터는 항상 같은 조명과 비율을 유지한다.**
   슬라임, 고블린, 임프의 크기와 명암이 크게 흔들리면 전투 가독성이 떨어진다.

4. **실루엣과 발밑 기준이 먼저다.**
   쿼터뷰 전투에서는 작은 유닛이 앞뒤로 겹친다. 색, 윤곽선, 머리/무기/뿔 모양으로 즉시 구분되어야 하고, 이동/선택/충돌 기준이 될 발밑 위치가 분명해야 한다.

---

## 3. 기본 파일 규칙

```text
monster_slime_idle_down_00.png
monster_slime_walk_down_00.png
monster_slime_attack_down_00.png
monster_slime_hit_down_00.png
monster_slime_down_00.png

monster_goblin_idle_down_00.png
monster_goblin_walk_side_00.png
monster_goblin_attack_side_00.png

monster_imp_idle_down_00.png
monster_imp_cast_down_00.png
monster_imp_walk_side_00.png

enemy_explorer_walk_down_00.png
enemy_thief_walk_side_00.png
enemy_trainee_hero_attack_down_00.png

tile_cave_floor_01.png
tile_cave_wall_top_01.png
prop_throne_01.png
prop_treasure_pile_01.png
prop_recovery_nest_01.png
trap_spike_idle_01.png
trap_spike_trigger_01.png
fx_fireball_00.png
fx_fire_impact_00.png
ui_icon_gold.png
ui_icon_mana.png
ui_icon_infamy.png
```

---

## 4. 캐릭터 스프라이트 기준

| 항목 | 기준 |
|---|---|
| 캔버스 | 128×128px per frame |
| 실제 캐릭터 높이 | 70~95px |
| 피벗 | 발밑 중앙 |
| 방향 | front/down, back/up, side. side는 Godot에서 flip_h로 반전 가능 |
| 필수 애니메이션 | idle, walk, attack/cast, hit, down |
| 배경 | 투명 또는 단색 배경 후 제거 가능 |

### 권장 프레임 수

| 애니메이션 | 프레임 |
|---|---:|
| idle | 4 |
| walk | 6 |
| attack | 4 |
| cast | 6 |
| hit | 2 |
| down | 3 |

---

## 5. 공통 캐릭터 프롬프트 템플릿

```text
Create a cute horror fantasy quarter-view 2D game sprite of [캐릭터 설명].
The character should be an original SD/chibi monster or human invader for an indie dungeon defense game.
Style: cute but slightly spooky, dark cave fantasy, purple magical rim light, clean silhouette, readable at small size, not pixel art.
View: 3/4 overhead quarter-view game sprite, camera looking slightly down at the character so the face, torso, and foot anchor are visible, transparent background, centered character, no text, no UI, no logo.
Canvas should work for 128x128 game sprite frames.
Pose: [idle/walk/attack/cast/hit/down].
Important: keep the design simple enough for animation, with clear outline and separated limbs/weapons.
```

---

## 6. 몬스터별 기준 프롬프트

### 6-1. 슬라임

```text
Create a cute horror fantasy quarter-view 2D game sprite of a blue slime tank monster.
It is a friendly minion of a rookie Demon King, round glossy body, tiny eyes, small smile, slightly spooky purple cave lighting, cute but sturdy.
It should look like it can block a narrow corridor.
No text, no logo, transparent background, clean silhouette, 128x128 sprite frame.
```

### 6-2. 고블린

```text
Create a cute horror fantasy quarter-view 2D game sprite of a small green goblin melee fighter.
Original design, SD/chibi proportions, leather scraps, tiny sword or club, mischievous face, readable silhouette, purple cave rim light.
It should look like a fast melee damage dealer for a Demon King castle defense game.
No text, no logo, transparent background, 128x128 sprite frame.
```

### 6-3. 임프

```text
Create a cute horror fantasy quarter-view 2D game sprite of a small red imp ranged magic dealer.
Original design, SD/chibi proportions, tiny horns, small bat wings, yellow eyes, holding a small flame, adorable but mischievous.
Dark cave fantasy lighting with purple rim light and orange fire glow.
No text, no logo, transparent background, 128x128 sprite frame.
```

---

## 7. 적 캐릭터 프롬프트

### 7-1. 탐험가

```text
Create a cute horror fantasy quarter-view 2D game sprite of a rookie human explorer invading a demon cave castle.
Original SD/chibi character, simple adventurer hat, backpack, small torch or short sword, slightly nervous expression.
Readable at small size, transparent background, no text, no logo, 128x128 sprite frame.
```

### 7-2. 도적

```text
Create a cute horror fantasy quarter-view 2D game sprite of a small human thief sneaking toward a treasure room.
Original SD/chibi design, dark hood, small dagger, tiny loot sack, quick sneaky pose.
Readable silhouette, transparent background, no text, no logo, 128x128 sprite frame.
```

### 7-3. 견습 용사

```text
Create a cute horror fantasy quarter-view 2D game sprite of a trainee hero invading a rookie Demon King castle.
Original SD/chibi design, small sword, bright but inexperienced hero outfit, determined expression, not too serious.
Readable silhouette, transparent background, no text, no logo, 128x128 sprite frame.
```

---

## 8. 방/오브젝트 리소스 프롬프트

### 8-1. 동굴 바닥 타일

```text
Create a seamless 64x64 quarter-view 2D cave floor tile for a cute horror fantasy dungeon game.
Dark stone floor plane, subtle cracks, slight purple ambient light, readable in a 3/4 overhead room, clean hand-painted style, no text, no characters.
```

### 8-2. 가시 함정

```text
Create a 64x64 quarter-view 2D spike trap tile for a cute horror fantasy dungeon game.
Dark metal spikes emerging from cracked cave floor, angled for a 3/4 overhead dungeon room, readable shape, slightly spooky but not gore, purple cave light, no text.
```

### 8-3. 왕좌

```text
Create a quarter-view 2D prop sprite of a small rookie Demon King throne for a cute horror fantasy cave castle.
Dark stone throne with visible front and side faces, tiny skull decorations, purple magical candles, charming but spooky, no text, transparent background.
```

### 8-4. 보물 보관실 오브젝트

```text
Create a quarter-view 2D prop sprite of a treasure pile for a cute horror fantasy Demon King cave castle.
Gold coins, small chest, purple crystals, visible front/side depth, readable from a 3/4 overhead game view, no text, transparent background.
```

---

## 9. 이펙트 프롬프트

### 9-1. 임프 화염구

```text
Create a small 2D game projectile effect: a cute fantasy fireball for a quarter-view game.
Orange flame core, small trail, readable on dark cave background, transparent background, no text.
```

### 9-2. 화염 명중

```text
Create a small 2D impact effect for a fireball hitting a target in a cute horror fantasy quarter-view game.
Short orange burst, sparks, readable on dark cave floor, transparent background, no text.
```

### 9-3. 선택 링

```text
Create a simple 2D selection ring for a quarter-view fantasy game unit.
Purple magical circle outline, transparent center, readable under small characters, transparent background, no text.
```

---

## 10. UI 아이콘 프롬프트

```text
Create a clean fantasy UI icon for [gold/mana/food/infamy/throne HP/command] in a cute horror Demon King castle game.
Style: dark gothic UI, purple accent, readable at 64x64, no text, transparent background.
```

아이콘별 키워드:

| 아이콘 | 키워드 |
|---|---|
| 금화 | gold coin, small demon mark |
| 마력 | blue-purple mana droplet |
| 식량 | cartoon meat bone |
| 악명 | purple horned skull |
| 왕좌 체력 | red heart with tiny crown |
| 사수 | blue shield |
| 총공격 | crossed red swords |
| 생존 우선 | green heart |
| 함정 유도 | purple trap teeth |
| 직접 조종 | orange demon hand |

---

## 11. 품질 체크 기준

| 체크 | 기준 |
|---|---|
| 실루엣 | 축소해도 캐릭터 종류가 구분됨 |
| 톤 | 큐트 호러, 보라색 마력 조명 유지 |
| 방향 | 쿼터뷰 게임에서 앞/뒤/좌우 이동에 쓸 수 있는 각도 |
| 배경 | 제거 가능하거나 투명 |
| 텍스트 | 이미지 안에 텍스트 없음 |
| 원본성 | 기존 캐릭터와 닮지 않음 |
| 애니메이션 가능성 | 팔/무기/날개 등 동작 부위가 명확함 |

---

## 12. Godot 적용 순서

1. PNG를 `assets/sprites/...`에 저장한다.
2. AnimatedSprite2D용 SpriteFrames를 만든다.
3. 피벗을 발밑 중앙으로 맞춘다.
4. 캐릭터별 크기를 전투 화면에서 비교한다.
5. 너무 크거나 작으면 스케일을 통일한다.
6. Placeholder와 교체한다.
7. 전투 중 겹침, 방향, 공격 이펙트 위치를 확인한다.
8. 앞쪽 오브젝트가 유닛을 가릴 경우 투명도, z_index, 배치 높이를 조정한다.
