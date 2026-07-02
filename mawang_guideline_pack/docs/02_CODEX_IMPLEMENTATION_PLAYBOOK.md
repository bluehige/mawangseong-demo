# 02. Codex 구현 플레이북

이 문서는 Codex에 넣어 Godot 4.5 데모를 제작할 때 사용하는 구현 지시서다. 핵심 원칙은 “작게 만들고, 실행되게 만들고, 그다음 확장한다”이다.

---

## 1. Codex 공통 지시문

```text
Godot 4.5와 GDScript로 2D 쿼터뷰 데모 게임을 구현해줘.

게임명은 「마왕님, 마왕성은 누가 지켜요?」다. 장르는 큐트 호러 판타지 마왕성 방어 시뮬레이션이다.

이번 목표는 3일짜리 기능 테스트 데모다. 플레이어는 신입 마왕이며, 초라한 동굴 마왕성에서 슬라임, 고블린, 임프 3종의 몬스터를 배치하고 실시간으로 지휘해 탐험가, 도적, 견습 용사의 침공을 막는다.

우선 Placeholder 그래픽으로 구현한다. 실제 이미지 리소스는 나중에 assets 폴더에 교체할 수 있게 구조화한다.

반드시 지킬 것:
1. Godot 4.5 / GDScript 사용.
2. PC 16:9, 1920×1080 기준 UI.
3. 쿼터뷰 2D.
4. 2D 좌표계, 발밑 피벗, Y-sort로 쿼터뷰를 구현한다.
5. CharacterBody2D 기반 유닛.
6. TileMapLayer 또는 Node2D 기반 맵 레이어.
7. CanvasLayer 기반 HUD.
8. 데이터는 ID 기반으로 구성하고 추후 JSON 분리 가능하게 작성.
9. 데모 핵심 범위 밖의 기능은 구현하지 말고 TODO로 남김.
10. 각 작업 완료 후 실행 방법과 테스트 방법을 적음.
```

---

## 2. 추천 프로젝트 구조

```text
res://
  scenes/
    main/
      Main.tscn
    game/
      GameRoot.tscn
      CombatScene.tscn
      ManagementScene.tscn
    map/
      DungeonMap.tscn
      RoomNode.tscn
      TrapNode.tscn
    units/
      Unit.tscn
      MonsterUnit.tscn
      EnemyUnit.tscn
      Projectile.tscn
    ui/
      HUD.tscn
      TopBar.tscn
      BattleCommandPanel.tscn
      RoomListPanel.tscn
      SelectedUnitPanel.tscn
      CombatLogPanel.tscn
      ManagementPanel.tscn
      MonsterPanel.tscn
      ResultPanel.tscn

  scripts/
    core/
      GameState.gd
      SignalBus.gd
      Constants.gd
      DataRegistry.gd
    map/
      DungeonMap.gd
      RoomNode.gd
      RoomGraph.gd
      TrapNode.gd
      BuildSlot.gd
    units/
      Unit.gd
      MonsterUnit.gd
      EnemyUnit.gd
      UnitAI.gd
      Skill.gd
      Projectile.gd
    combat/
      CombatManager.gd
      TargetingService.gd
      DamageService.gd
      DirectiveManager.gd
      WaveManager.gd
    ui/
      HUD.gd
      TopBar.gd
      BattleCommandPanel.gd
      RoomListPanel.gd
      SelectedUnitPanel.gd
      CombatLogPanel.gd
      ManagementPanel.gd
      MonsterPanel.gd
      ResultPanel.gd

  data/
    monsters.json
    enemies.json
    skills.json
    rooms.json
    waves.json

  assets/
    sprites/
      monsters/
      enemies/
      rooms/
      tiles/
      effects/
      ui/
    audio/
      sfx/
      bgm/
```

---

## 3. Phase 0 — 프로젝트 초기화

### 목표

실행 가능한 빈 프로젝트와 기본 전환 구조를 만든다.

### 생성/수정 파일

```text
scenes/main/Main.tscn
scenes/game/GameRoot.tscn
scripts/core/GameState.gd
scripts/core/SignalBus.gd
scripts/core/Constants.gd
scripts/core/DataRegistry.gd
```

### 구현 내용

- 1920×1080 기준 윈도우 설정.
- Main.tscn에서 GameRoot 로드.
- GameState에 현재 일차, 자원, 마왕성 HP 저장.
- SignalBus에 UI/전투 이벤트 신호 정의.
- 임시 관리 화면 또는 전투 화면 전환 버튼 배치.

### 완료 조건

- 프로젝트 실행 시 메인 씬이 열린다.
- 콘솔 오류가 없다.
- 관리 화면과 전투 화면을 임시 버튼으로 전환할 수 있다.

---

## 4. Phase 1 — 맵과 방 구조

### 목표

쿼터뷰 마왕성 방 구조를 만든다.

### 생성/수정 파일

```text
scenes/map/DungeonMap.tscn
scenes/map/RoomNode.tscn
scripts/map/DungeonMap.gd
scripts/map/RoomNode.gd
scripts/map/RoomGraph.gd
scripts/map/BuildSlot.gd
data/rooms.json
```

### 구현 내용

- 방 6개와 건설 슬롯 1개 생성.
- 방마다 중심 좌표와 연결 방 정보를 가진다.
- RoomGraph에서 방 간 이동 경로를 반환한다.
- 방 클릭 시 선택 이벤트 발생.
- 쿼터뷰 배경은 방의 바닥, 뒤쪽 벽, 출입구, 소품이 3/4 하향 시점으로 읽히게 구성한다.
- 유닛 이동/충돌/선택 기준은 방의 시각 중심이 아니라 발밑 기준점에 맞춘다.

### 방 데이터

```json
[
  {"id":"entrance","display_name":"입구","type":"entry","exits":["spike_corridor"]},
  {"id":"spike_corridor","display_name":"가시 복도","type":"trap","exits":["entrance","central","treasure"]},
  {"id":"central","display_name":"중앙 통로","type":"corridor","exits":["spike_corridor","barracks","recovery","throne"]},
  {"id":"barracks","display_name":"병영","type":"support","exits":["central"]},
  {"id":"treasure","display_name":"보물 보관실","type":"bait","exits":["spike_corridor"]},
  {"id":"recovery","display_name":"회복 둥지","type":"support","exits":["central"]},
  {"id":"throne","display_name":"왕좌의 방","type":"core","exits":["central"]}
]
```

### 완료 조건

- 방이 화면에 보인다.
- 방 이름을 표시할 수 있다.
- 입구에서 왕좌의 방까지 경로가 반환된다.

---

## 5. Phase 2 — 유닛 생성과 이동

### 목표

몬스터와 적을 생성하고 방 사이를 이동시킨다.

### 생성/수정 파일

```text
scenes/units/Unit.tscn
scenes/units/MonsterUnit.tscn
scenes/units/EnemyUnit.tscn
scripts/units/Unit.gd
scripts/units/MonsterUnit.gd
scripts/units/EnemyUnit.gd
scripts/units/UnitAI.gd
data/monsters.json
data/enemies.json
```

### 구현 내용

- CharacterBody2D 기반 Unit.
- HP, ATK, DEF, move_speed, attack_range, attack_interval.
- 현재 방, 목표 방, 이동 경로.
- 우선 Placeholder 원형/색상 스프라이트 사용.

### 완료 조건

- 슬라임, 고블린, 임프가 지정 방에 생성된다.
- 탐험가가 입구에서 왕좌의 방으로 이동한다.
- 도적이 보물 보관실로 이동한다.
- 견습 용사가 왕좌의 방으로 이동한다.

---

## 6. Phase 3 — 기본 전투

### 목표

자동 전투와 HP 감소를 구현한다.

### 생성/수정 파일

```text
scripts/combat/CombatManager.gd
scripts/combat/TargetingService.gd
scripts/combat/DamageService.gd
scripts/units/Projectile.gd
scenes/units/Projectile.tscn
data/skills.json
```

### 구현 내용

- 사거리 안의 적 탐색.
- 기본 공격.
- 피해 계산: `max(1, ATK - DEF * 0.5)`.
- HP 0이면 DOWN 상태.
- 임프 화염구 투사체.

### 완료 조건

- 몬스터가 적을 공격한다.
- 적이 몬스터를 공격한다.
- HP가 감소한다.
- 전투불능 처리가 된다.
- 임프 화염구가 날아가고 명중 시 피해를 준다.

---

## 7. Phase 4 — 행동지침

### 목표

전체 지침과 방 지침이 AI에 영향을 주게 만든다.

### 생성/수정 파일

```text
scripts/combat/DirectiveManager.gd
scripts/units/UnitAI.gd
scripts/ui/BattleCommandPanel.gd
```

### 전체 지침

| ID | 표시명 | 효과 |
|---|---|---|
| hold | 사수 | 현재 방을 지키고 추격하지 않음 |
| assault | 총공격 | 적극 추격, 스킬 적극 사용 |
| survive | 생존 우선 | HP 35% 이하이면 회복 둥지로 후퇴 |

### 방 지침

| ID | 표시명 | 효과 |
|---|---|---|
| block_entry | 입구 봉쇄 | 선택 방의 입구 지점에 탱커 우선 배치 |
| lure_trap | 함정 유도 | 적을 가시 복도 중앙으로 유도 |
| keep_retreat_line | 후퇴선 유지 | HP 낮은 유닛이 후방으로 빠짐 |

### 완료 조건

- UI 버튼으로 전체 지침을 변경할 수 있다.
- 방을 선택하고 방 지침을 적용할 수 있다.
- 사수/총공격/생존 우선이 실제 행동 차이를 만든다.

---

## 8. Phase 5 — 직접 조종

### 목표

선택 몬스터 1마리를 플레이어가 직접 조종한다.

### 구현 내용

- 몬스터 클릭 선택.
- 직접 조종 버튼.
- 우클릭 위치 이동.
- 우클릭 적 공격 지정.
- 숫자키 1~3 또는 스킬 버튼으로 스킬 사용.
- 직접 조종 해제 시 AI 복귀.

### 완료 조건

- 선택한 몬스터가 UI에 표시된다.
- 직접 조종 상태에서 우클릭 이동이 가능하다.
- 임프를 직접 조종해 화염구를 사용할 수 있다.
- 직접 조종 해제 후 기존 지침에 따라 움직인다.

---

## 9. Phase 6 — UI 완성

### 목표

전투 HUD와 관리 화면의 필수 UI를 만든다.

### 생성/수정 파일

```text
scenes/ui/HUD.tscn
scenes/ui/TopBar.tscn
scenes/ui/BattleCommandPanel.tscn
scenes/ui/RoomListPanel.tscn
scenes/ui/SelectedUnitPanel.tscn
scenes/ui/CombatLogPanel.tscn
scenes/ui/ManagementPanel.tscn
scenes/ui/MonsterPanel.tscn
scenes/ui/ResultPanel.tscn
```

### 완료 조건

- 상단 자원바가 표시된다.
- 좌측 방 목록이 표시된다.
- 전투 로그가 표시된다.
- 선택 유닛 정보가 표시된다.
- 하단 지침 버튼이 작동한다.
- 결과 화면이 표시된다.

---

## 10. Phase 7 — 3일 루프

### 목표

3일짜리 데모 루프를 완성한다.

### 웨이브

```json
[
  {"day":1,"enemies":[{"id":"enemy_explorer","count":2}]},
  {"day":2,"enemies":[{"id":"enemy_explorer","count":2},{"id":"enemy_thief","count":1}]},
  {"day":3,"enemies":[{"id":"enemy_explorer","count":2},{"id":"enemy_thief","count":1},{"id":"enemy_trainee_hero","count":1}]}
]
```

### 완료 조건

- 1일차 전투 후 결산.
- 2일차 전투 후 결산.
- 3일차 견습 용사 격퇴 시 클리어.
- 왕좌의 방 HP 0이면 패배.

---

## 11. Phase 8 — 리소스 교체 준비

### 목표

Placeholder를 실제 이미지로 교체할 수 있게 만든다.

### 구현 내용

- `assets/sprites/monsters/` 경로 사용.
- `assets/sprites/enemies/` 경로 사용.
- `assets/sprites/rooms/` 경로 사용.
- `assets/sprites/effects/` 경로 사용.
- 유닛 ID에 따라 SpriteFrames 로드 가능하게 구조화.

### 완료 조건

- Placeholder로 계속 실행된다.
- 이미지 파일을 넣으면 특정 유닛의 스프라이트를 교체할 수 있다.

---

## 12. 구현 금지 목록

데모 제작 중 아래 기능은 구현하지 않는다.

- 자유건설 전체 에디터.
- 다층 마왕성.
- 장비.
- 진화.
- 특수 몬스터.
- 세력별 악명.
- 복잡한 스토리 이벤트.
- 온라인 기능.
- 세이브 슬롯 다중 관리.
- 확률형 뽑기.

필요하면 TODO 주석으로만 남긴다.

---

## 13. Codex에 매 Phase 끝마다 요구할 보고 형식

```text
이번 Phase 완료 보고:
1. 생성/수정 파일
2. 구현된 기능
3. 테스트 방법
4. 현재 제한사항
5. 다음 Phase를 시작하기 전에 확인할 점
```
