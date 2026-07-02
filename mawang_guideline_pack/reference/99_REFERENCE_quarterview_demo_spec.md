# 「마왕님, 마왕성은 누가 지켜요?」 쿼터뷰 데모 제작용 상세 기획서 v0.4

## 0. 확정 기준

- 게임 엔진: Godot 4.5, GDScript 중심.
- 화면 기준: PC 16:9, 1920×1080 기준 UI 배치. 최소 대응 해상도 1280×720.
- 시점: 2D 쿼터뷰. 기존 평면 기준은 폐기하고, 쿼터뷰만 제작 기준으로 사용한다.
- 구현 방식: 3D가 아니라 2D 좌표계, 발밑 피벗, Y-sort, 쿼터뷰 배경/스프라이트로 구현한다.
- 그래픽 톤: 큐트 호러 판타지. 어두운 동굴 마왕성, 보라색 마력 조명, 귀여운 SD 몬스터.
- 데모 목적: 완성 게임이 아니라 기능 검증. “몬스터 자동 전투 + 행동지침 변경 + 직접 조종 + 간단 마왕성 운영”이 실제로 재미있는지 검증한다.
- 데모 길이: 3일짜리 초소형 기능 테스트. 플레이 시간 10~15분.
- 마왕성 구조: 슬롯 기반 건설. 단, 내부 데이터 구조는 추후 자유건설로 확장 가능하게 만든다.
- 직접 조종: 마우스 클릭 이동 + 스킬 버튼 사용.
- 행동지침: 전체 지침 + 방 단위 지침까지만 구현. 개별 지침은 데모 이후 확장.
- 초기 몬스터: 슬라임, 고블린, 임프 3종.
- 초기 적: 탐험가, 도적, 견습 용사 3종.
- 핵심 화면: 전투 화면, 마왕성 관리 화면, 몬스터 관리 화면.

## 1. 데모 목표

### 1.1 핵심 플레이 문장

플레이어는 신입 마왕이 되어 초라한 동굴 마왕성에 슬라임, 고블린, 임프를 배치하고, 침입해 오는 탐험가·도적·견습 용사를 실시간으로 지휘해 막아낸다.

### 1.2 데모에서 검증할 것

1. 쿼터뷰 마왕성 안에서 몬스터와 적이 실시간으로 움직이며 싸우는가.
2. 전체 지침과 방 지침을 바꾸면 전투 결과가 체감될 만큼 달라지는가.
3. 특정 몬스터를 직접 조종했을 때 전황을 바꾸는 느낌이 있는가.
4. 전투 후 결산, 레벨업, 스킬 확인, 다음 날 진행 루프가 끊기지 않는가.
5. 슬롯 기반 방 배치가 추후 자유건설로 확장 가능한 구조인가.

## 2. 데모 플레이 흐름

### 2.1 전체 진행

데모는 총 3일로 구성한다.

| 일차 | 목적 | 적 구성 | 해금/학습 |
|---:|---|---|---|
| 1일차 | 기본 전투 학습 | 탐험가 2명 | 사수, 총공격, 생존 우선 |
| 2일차 | 보물고 방어 학습 | 탐험가 2명, 도적 1명 | 방 지침: 함정 유도, 입구 봉쇄 |
| 3일차 | 미니 보스전 | 탐험가 2명, 도적 1명, 견습 용사 1명 | 직접 조종, 임프 스킬 사용 |

### 2.2 하루 루프

1. 아침 보고
   - 오늘 침입 예고 표시.
   - 현재 금화, 마력, 식량, 악명, 마왕성 체력 표시.

2. 마왕성 관리
   - 슬롯에 방 배치 또는 확인.
   - 데모에서는 방 1개만 건설/교체 가능.

3. 몬스터 관리
   - 몬스터 능력치, HP, 스킬 슬롯 확인.
   - 2일차 이후 레벨업 결과 확인.

4. 방어 준비
   - 몬스터를 방에 배치.
   - 전체 지침 기본값 선택.

5. 실시간 방어전
   - 적이 입구에서 등장.
   - 몬스터가 행동지침에 따라 자동 이동/전투.
   - 플레이어는 전투 중 전체 지침/방 지침 변경 가능.
   - 플레이어는 몬스터 하나를 선택해 직접 조종 가능.

6. 결산
   - 적 격퇴 수, 도망간 적, 방 피해, 마왕성 체력, 획득 자원 표시.
   - 몬스터 경험치 지급.
   - 악명 증가.

## 3. Godot 프로젝트 구조

### 3.1 폴더 구조

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

### 3.2 핵심 씬 구조

#### Main.tscn

```text
Main(Node)
  GameRoot(Node)
```

#### GameRoot.tscn

```text
GameRoot(Node)
  ManagementScene(Node2D)
  CombatScene(Node2D)
  HUD(CanvasLayer)
  ResultPanel(CanvasLayer)
```

#### CombatScene.tscn

```text
CombatScene(Node2D)
  DungeonMap(Node2D)
    GroundLayer(TileMapLayer)
    WallLayer(TileMapLayer)
    DecorLayer(TileMapLayer)
    BuildSlotLayer(Node2D)
    RoomNodes(Node2D)
    TrapNodes(Node2D)
  Units(Node2D)  # y_sort_enabled = true
  Projectiles(Node2D)
  Effects(Node2D)
  Camera2D
  CombatManager(Node)
  WaveManager(Node)
```

#### Unit.tscn

```text
Unit(CharacterBody2D)
  SpriteRoot(Node2D)
    AnimatedSprite2D
    SelectionRing(Sprite2D)
    StatusIconRoot(Node2D)
  CollisionShape2D
  AttackRange(Area2D)
    CollisionShape2D
  Hurtbox(Area2D)
    CollisionShape2D
  NavigationMarker(Node2D)  # 데모에서는 RoomGraph 이동 좌표용
  UnitAI(Node)
```

#### HUD.tscn

```text
HUD(CanvasLayer)
  TopBar(Control)
  RoomListPanel(Control)
  MinimapPanel(Control)
  SelectedUnitPanel(Control)
  BattleCommandPanel(Control)
  CombatLogPanel(Control)
```

## 4. 기술 구현 기준

### 4.1 쿼터뷰 맵 구현

- 맵은 TileMapLayer 여러 개로 구성한다.
- 레이어는 GroundLayer, WallLayer, DecorLayer로 분리한다.
- Tile size는 64×64px로 시작한다.
- 방 하나는 5×5~7×7 타일 크기로 제작한다.
- 통로 폭은 2타일 기준으로 만든다.
- 추후 자유건설 확장을 위해 모든 방은 grid_position, grid_size, exits 배열을 가진다.

데모에서는 고정된 맵을 사용하지만, 코드상으로는 다음 구조를 유지한다.

```gdscript
class_name RoomData
var id: String
var display_name: String
var room_type: String
var grid_position: Vector2i
var grid_size: Vector2i
var exits: Array[String]
var build_slot_id: String
var max_monsters: int
var is_core_room: bool
```

### 4.2 이동 구현

데모 버전은 자유 타일 경로탐색보다 안정적인 RoomGraph 기반으로 구현한다.

- 각 방에는 center_point, entrance_points, exit_points를 둔다.
- 적은 목표 방까지 RoomGraph 경로를 따라 이동한다.
- 몬스터는 현재 지침에 따라 목표 방 또는 적 위치로 이동한다.
- 전투 중 세밀한 이동은 CharacterBody2D의 velocity와 move_and_slide()로 처리한다.
- 방 내부에서 적에게 접근할 때는 직선 이동 + 충돌 슬라이딩을 사용한다.

추후 자유건설 확장 시 RoomGraph를 AStarGrid2D 또는 NavigationAgent2D 기반으로 교체한다.

### 4.3 좌표 기준

- 월드 좌표 원점은 맵 좌상단.
- UI는 CanvasLayer에서 고정 좌표로 표시.
- 유닛 피벗은 발밑 중앙 기준.
- 캐릭터 스프라이트는 128×128px 캔버스에 그리되, 실제 충돌 반경은 18~24px.
- y_sort_enabled를 사용하거나 각 프레임마다 z_index = int(global_position.y)를 적용한다.

## 5. 데모 마왕성 구조

### 5.1 방 목록

| ID | 이름 | 역할 | 데모 구현 |
|---|---|---|---|
| entrance | 입구 | 적 등장 지점 | 고정 |
| spike_corridor | 가시 복도 | 함정/지연 | 고정 |
| barracks | 병영 | 몬스터 대기 | 고정 |
| treasure | 보물 보관실 | 도적 유인 | 고정 |
| recovery | 회복 둥지 | 전투 후 회복 | 고정 |
| throne | 왕좌의 방 | 핵심 목표 | 고정 |
| slot_01 | 건설 슬롯 | 확장용 빈방 | 데모에서 선택 건설 |

### 5.2 방 연결 구조

```text
입구 -> 가시 복도 -> 중앙 통로 -> 왕좌의 방
                  ├-> 병영
                  ├-> 보물 보관실
                  └-> 회복 둥지
```

도적은 보물 보관실을 우선 목표로 삼는다. 견습 용사는 왕좌의 방을 우선 목표로 삼는다. 탐험가는 가장 가까운 몬스터와 교전하되, 막히지 않으면 왕좌의 방으로 이동한다.

### 5.3 방 데이터 예시

```json
{
  "entrance": {
    "display_name": "입구",
    "type": "entry",
    "hp": 9999,
    "max_monsters": 3,
    "exits": ["spike_corridor"]
  },
  "spike_corridor": {
    "display_name": "가시 복도",
    "type": "trap",
    "hp": 300,
    "max_monsters": 2,
    "exits": ["entrance", "center"],
    "trap_id": "spike_floor"
  },
  "treasure": {
    "display_name": "보물 보관실",
    "type": "bait",
    "hp": 250,
    "max_monsters": 2,
    "exits": ["center"],
    "bait_priority": 80
  },
  "throne": {
    "display_name": "왕좌의 방",
    "type": "core",
    "hp": 1500,
    "max_monsters": 4,
    "exits": ["center"],
    "is_core_room": true
  }
}
```

## 6. 몬스터 설계

### 6.1 공통 능력치

| 능력치 | 설명 |
|---|---|
| hp | 체력 |
| max_hp | 최대 체력 |
| atk | 기본 공격력 |
| def | 방어력 |
| move_speed | 이동 속도, px/s |
| attack_range | 공격 사거리, px |
| attack_interval | 공격 간격, 초 |
| int | 지능. 지침 반응과 스킬 사용 판단에 영향 |
| loyalty | 충성도. 데모에서는 표시만 하고 전투 보정은 최소화 |
| role | tank, melee, caster |
| skill_slots | 일반 몬스터 3칸 |

### 6.2 슬라임

| 항목 | 값 |
|---|---|
| ID | slime |
| 이름 | 슬라임 |
| 역할 | 근접 탱커 |
| HP | 180 |
| ATK | 8 |
| DEF | 8 |
| 이동속도 | 90 |
| 공격 사거리 | 42 |
| 공격 간격 | 1.4초 |
| 지능 | 8 |
| 충성도 | 70 |
| 배치 추천 | 입구, 가시 복도 |

스킬:

| 스킬 | 타입 | 효과 |
|---|---|---|
| 점액 방패 | 액티브 | 5초 동안 받는 피해 40% 감소. 쿨타임 12초. |
| 끈적한 바닥 | 액티브 | 주변 96px 적 이동속도 4초간 35% 감소. 쿨타임 10초. |
| 통로 막기 | 패시브 | 사수 지침 중 넉백 면역, DEF +3. |

데모 시작 스킬: 점액 방패, 통로 막기.

### 6.3 고블린

| 항목 | 값 |
|---|---|
| ID | goblin |
| 이름 | 고블린 |
| 역할 | 근접 딜러 |
| HP | 140 |
| ATK | 16 |
| DEF | 4 |
| 이동속도 | 130 |
| 공격 사거리 | 46 |
| 공격 간격 | 0.9초 |
| 지능 | 12 |
| 충성도 | 65 |
| 배치 추천 | 병영, 입구 뒤쪽 |

스킬:

| 스킬 | 타입 | 효과 |
|---|---|---|
| 재빠른 베기 | 액티브 | 즉시 ATK×1.6 피해. 쿨타임 6초. |
| 약탈 본능 | 패시브 | 전투 승리 시 금화 +10%. |
| 단체 야유 | 액티브 | 주변 적 사기 -10. 쿨타임 12초. |

데모 시작 스킬: 재빠른 베기, 약탈 본능.

### 6.4 임프

| 항목 | 값 |
|---|---|
| ID | imp |
| 이름 | 임프 |
| 역할 | 원거리 마법 딜러 |
| HP | 120 |
| ATK | 18 |
| DEF | 3 |
| 이동속도 | 115 |
| 공격 사거리 | 180 |
| 공격 간격 | 1.2초 |
| 지능 | 24 |
| 충성도 | 85 |
| 배치 추천 | 가시 복도 뒤쪽, 왕좌의 방 앞 |

스킬:

| 스킬 | 타입 | 효과 |
|---|---|---|
| 화염구 | 액티브 | 단일 대상에게 30 화염 피해. 쿨타임 5초. 마력 20. |
| 화염 지대 | 액티브 | 지정 위치 96px 범위에 4초간 초당 6 피해. 쿨타임 14초. 마력 40. |
| 조롱의 불씨 | 액티브 | 적 1명을 3초간 자신 쪽으로 유도. 쿨타임 10초. |

데모 시작 스킬: 화염구, 화염 지대.

## 7. 적 설계

### 7.1 탐험가

| 항목 | 값 |
|---|---|
| ID | explorer |
| 이름 | 탐험가 |
| 목표 | 왕좌의 방 이동, 가까운 몬스터와 교전 |
| HP | 90 |
| ATK | 10 |
| DEF | 2 |
| 이동속도 | 105 |
| 공격 사거리 | 45 |
| 공격 간격 | 1.1초 |
| 사기 | 60 |

특징: 기본 적. 슬라임에게 막히고 고블린에게 약하다.

### 7.2 도적

| 항목 | 값 |
|---|---|
| ID | thief |
| 이름 | 도적 |
| 목표 | 보물 보관실 |
| HP | 70 |
| ATK | 8 |
| DEF | 1 |
| 이동속도 | 155 |
| 공격 사거리 | 40 |
| 공격 간격 | 0.8초 |
| 사기 | 50 |

특징:

- 보물 보관실에 도달하면 5초간 약탈 게이지를 채운다.
- 약탈 완료 시 금화 -100, 전투 로그에 표시.
- 공격받으면 도망보다 회피 이동을 우선한다.

### 7.3 견습 용사

| 항목 | 값 |
|---|---|
| ID | trainee_hero |
| 이름 | 견습 용사 |
| 목표 | 왕좌의 방 |
| HP | 220 |
| ATK | 20 |
| DEF | 6 |
| 이동속도 | 110 |
| 공격 사거리 | 55 |
| 공격 간격 | 1.0초 |
| 사기 | 100 |

스킬:

| 스킬 | 효과 |
|---|---|
| 용사의 돌진 | 현재 목표 방향으로 120px 돌진, 충돌한 몬스터에게 20 피해. |
| 겁없는 외침 | 자기 사기 +20, 주변 탐험가 사기 +10. |

보스 판정: 3일차 등장. 격퇴하면 데모 클리어.

## 8. 전투 시스템

### 8.1 전투 상태

전투는 CombatManager가 관리한다.

```text
PREPARE -> SPAWN_WAVE -> COMBAT -> RESULT -> MANAGEMENT
```

### 8.2 유닛 상태 머신

모든 Unit은 다음 상태를 가진다.

| 상태 | 설명 |
|---|---|
| IDLE | 대기 |
| MOVE_TO_ROOM | 특정 방으로 이동 |
| SEEK_TARGET | 공격 대상 탐색 |
| MOVE_TO_TARGET | 사거리 안으로 접근 |
| ATTACK | 기본 공격 |
| CAST_SKILL | 스킬 사용 |
| RETREAT | 후퇴 방으로 이동 |
| DIRECT_CONTROL | 플레이어 직접 조종 |
| STUNNED | 일시 행동 불가 |
| DOWN | 전투 불능 |

### 8.3 피해 공식

데모는 단순 공식으로 시작한다.

```text
최종 피해 = max(1, 공격력 - 방어력 × 0.5)
치명타, 속성, 명중률은 데모에서 제외한다.
```

### 8.4 공격 주기

- 각 유닛은 attack_interval마다 공격한다.
- 사거리 안에 타깃이 있으면 ATTACK.
- 사거리 밖이면 MOVE_TO_TARGET.
- 원거리 공격은 Projectile.tscn을 생성한다.
- 근접 공격은 즉시 피해 + 타격 이펙트.

### 8.5 타깃 우선순위

#### 몬스터 기본 우선순위

1. 왕좌의 방에 가까운 적.
2. 현재 방 안의 적.
3. 체력이 낮은 적.
4. 가장 가까운 적.

#### 사수 지침

- 현재 배치 방을 벗어나지 않는다.
- 적이 방 밖으로 나가면 추격하지 않는다.
- 왕좌의 방 근처에서는 추격 허용.

#### 총공격 지침

- 적을 적극 추격한다.
- 임프도 사거리를 유지하며 전진한다.
- 체력이 낮아도 후퇴하지 않는다.

#### 생존 우선 지침

- HP 35% 이하일 때 recovery 방으로 후퇴한다.
- 후퇴 중에는 공격하지 않는다.
- 회복 둥지에 도착하면 초당 HP 8 회복.

### 8.6 방 지침

| 지침 | 적용 대상 | 효과 |
|---|---|---|
| 입구 봉쇄 | 입구, 가시 복도 | 탱커형 몬스터가 입구 쪽 chokepoint로 이동 |
| 함정 유도 | 가시 복도 | 몬스터가 적을 가시 복도 중앙으로 끌어들이는 위치를 잡음 |
| 후퇴선 유지 | 모든 방 | HP 45% 이하 유닛이 다음 안전 방으로 이동 |

### 8.7 직접 조종

- 플레이어가 아군 몬스터 클릭 후 “직접 조종” 버튼을 누르면 DIRECT_CONTROL 상태가 된다.
- 마우스 우클릭 또는 좌클릭 이동 명령으로 목표 위치를 설정한다.
- 스킬 버튼을 클릭한 뒤 적 또는 위치를 클릭하면 스킬 사용.
- 직접 조종 중 해당 유닛은 자동 AI를 중지한다.
- 직접 조종 해제 시 이전 전체 지침으로 복귀한다.

조작 규칙:

| 입력 | 기능 |
|---|---|
| 좌클릭 유닛 | 선택 |
| 우클릭 위치 | 선택 유닛 이동 |
| 우클릭 적 | 선택 유닛 공격 목표 지정 |
| 1, 2, 3 | 스킬 사용 |
| Space | 일시정지/재개 |
| Tab | 다음 몬스터 선택 |

## 9. 함정 시스템

### 9.1 데모 함정: 가시 바닥

| 항목 | 값 |
|---|---|
| ID | spike_floor |
| 위치 | 가시 복도 |
| 발동 조건 | 적이 Area2D에 진입 |
| 피해 | 12 |
| 쿨타임 | 2초 |
| 추가 효과 | 이동속도 2초간 20% 감소 |

### 9.2 구현 방식

```text
TrapNode(Area2D)
  CollisionShape2D
  AnimatedSprite2D
  CooldownTimer
```

- 적이 Area2D에 들어오면 발동.
- 쿨타임 중에는 발동하지 않는다.
- 발동 시 spike_trigger 애니메이션 재생.
- 전투 로그에 “가시 함정이 도적에게 피해를 입혔습니다.” 출력.

## 10. 악명과 결산

### 10.1 악명 증가

| 조건 | 악명 증가 |
|---|---:|
| 탐험가 격퇴 | +5 |
| 도적 격퇴 | +8 |
| 견습 용사 격퇴 | +25 |
| 보물고를 지켜냄 | +5 |
| 왕좌의 방 피해 없이 승리 | +10 |
| 적이 도망감 | +10 |

데모에서는 “목격자 남기기” 지침은 구현하지 않고, 적이 사기 0으로 도망가면 악명 보너스를 준다.

### 10.2 결산 화면

표시 항목:

- 격퇴한 적 수.
- 도망간 적 수.
- 마왕성 체력 변화.
- 보물고 피해 여부.
- 획득 금화.
- 획득 마력.
- 증가 악명.
- 몬스터 경험치.
- 레벨업 발생 여부.

## 11. 몬스터 성장과 스킬 슬롯

### 11.1 데모 규칙

- 일반 몬스터는 스킬 슬롯 3칸.
- 데모 시작 시 각 몬스터는 2개 스킬 보유.
- 2일차 결산 후 몬스터 1마리 이상 레벨업 가능.
- 레벨업 시 후보 스킬 3개 중 1개를 선택한다.
- 실제 데모 구현이 빠듯하면 레벨업 후보 선택 UI는 결과 화면에서 표시만 해도 된다.

### 11.2 경험치

| 적 | EXP |
|---|---:|
| 탐험가 | 20 |
| 도적 | 30 |
| 견습 용사 | 80 |

레벨업 필요 경험치:

```text
레벨 1 -> 2: 50
레벨 2 -> 3: 80
레벨 3 -> 4: 120
```

### 11.3 스킬 후보 예시

| 몬스터 | 후보 스킬 |
|---|---|
| 슬라임 | 끈적한 바닥, 젤리 흡수, 강한 점성 |
| 고블린 | 단체 야유, 뒷치기, 함정 손보기 |
| 임프 | 조롱의 불씨, 작은 저주, 불씨 확산 |

## 12. UI 구조

### 12.1 전투 화면

기준 해상도 1920×1080.

| 위치 | UI | 크기 기준 | 기능 |
|---|---|---|---|
| 상단 | TopBar | 1920×80 | 금화, 마력, 식량, 악명, 일차, 마왕성 체력 |
| 좌상단 | MinimapPanel | 300×260 | 방 구조와 유닛 위치 축약 표시 |
| 좌중단 | RoomListPanel | 300×320 | 방 상태, 전투 중 여부 |
| 좌하단 | CombatLogPanel | 420×230 | 전투 로그 |
| 중앙 | DungeonMap | 남은 영역 | 실시간 전투 |
| 우측 | SelectedUnitPanel | 330×760 | 선택 유닛 정보, HP, 스킬 |
| 하단 중앙 | BattleCommandPanel | 900×190 | 전체 지침, 방 지침, 직접 조종 |
| 우하단 | SpeedPanel | 120×180 | 일시정지, 배속 |

### 12.2 전투 화면 버튼

전체 지침 버튼:

| 버튼 | 기능 |
|---|---|
| 사수 | 현재 방 방어 |
| 총공격 | 적극 추격 및 공격 |
| 생존 우선 | 체력 낮으면 후퇴 |

방 지침 버튼:

| 버튼 | 기능 |
|---|---|
| 입구 봉쇄 | 선택 방 입구를 막음 |
| 함정 유도 | 적을 함정 방향으로 유인 |
| 후퇴선 유지 | 체력이 낮은 유닛이 후방 이동 |

공통 버튼:

| 버튼 | 기능 |
|---|---|
| 직접 조종 | 선택 몬스터 직접 조종 토글 |
| 일시정지 | 전투 정지 |
| x1 / x1.5 / x2 | 배속 변경 |

### 12.3 마왕성 관리 화면

필수 패널:

- TopBar.
- 방 목록.
- 중앙 마왕성 맵.
- 우측 선택 슬롯/방 정보.
- 하단 메뉴: 건설, 몬스터, 침공 작전, 방어 준비, 다음 날.

데모에서 실제 동작하는 버튼:

| 버튼 | 동작 |
|---|---|
| 건설 | 선택 슬롯에 방 건설 |
| 몬스터 | 몬스터 관리 화면 열기 |
| 방어 준비 | 전투 준비 화면으로 이동 |
| 다음 날 | 현재 날 진행 |

“침공 작전”은 데모에서는 비활성화하고, 툴팁에 “정식 버전에서 사용” 표시.

### 12.4 몬스터 관리 화면

필수 표시:

- 몬스터 목록 카드: 슬라임, 고블린, 임프.
- 선택 몬스터 대형 이미지.
- HP, 공격력, 방어력, 이동속도, 지능, 충성도.
- 스킬 슬롯 3칸.
- 버튼: 훈련, 배치, 스킬 교체, 돌아가기.

데모에서 실제 동작하는 버튼:

| 버튼 | 동작 |
|---|---|
| 훈련 | 금화 30 소비, EXP +20 |
| 배치 | 선택 방에 배치 |
| 돌아가기 | 관리 화면으로 복귀 |

스킬 교체는 데모에서는 표시만 하고 비활성화 가능.

## 13. 그래픽 리소스 기준

### 13.1 스타일 기준

- 쿼터뷰 2D SD 캐릭터.
- 귀엽지만 배경은 살짝 무서운 큐트 호러.
- 검정/보라/짙은 회색 동굴 배경.
- 몬스터는 둥글고 귀여운 실루엣.
- 인간 적은 밝은 색 옷을 입혀 몬스터와 구분.
- UI는 어두운 패널 + 보라색 강조선 + 금색 자원 아이콘.

### 13.2 캐릭터 리소스 규격

| 항목 | 기준 |
|---|---|
| 원본 캔버스 | 128×128px per frame |
| 실제 캐릭터 크기 | 70~95px 높이 |
| 피벗 | 발밑 중앙, x=64, y=96 |
| 방향 | 4방향: down, up, side, side_flip |
| 애니메이션 | idle, walk, attack, cast, hit, down |
| 포맷 | PNG, 투명 배경 |

필수 프레임 수:

| 애니메이션 | 프레임 |
|---|---:|
| idle | 4 |
| walk | 6 |
| attack | 4 |
| cast | 6 |
| hit | 2 |
| down | 3 |

데모에서 최소 구현은 down 방향만 먼저 만들고, 좌우 이동은 side, 위쪽 이동은 up으로 확장한다. 빠른 구현이 필요하면 방향별 스프라이트 없이 단일 방향 + flip_h로 시작해도 된다.

### 13.3 방/타일 리소스 규격

| 리소스 | 기준 |
|---|---|
| 타일 크기 | 64×64px |
| 바닥 타일 | 동굴 바닥 6종 |
| 벽 타일 | 상/하/좌/우/코너 12종 |
| 장식 | 보라 횃불, 해골, 상자, 마력 수정 |
| 방 오브젝트 | 왕좌, 보물더미, 병영 무기대, 회복 둥지, 입구문 |
| 함정 | 가시 바닥 idle/trigger 4프레임 |

### 13.4 이펙트 리소스

| 이펙트 | 용도 | 프레임 |
|---|---|---:|
| hit_slash | 고블린 공격 | 4 |
| fireball | 임프 투사체 | 4 반복 |
| fire_impact | 화염구 명중 | 6 |
| slime_shield | 슬라임 방패 | 6 반복 |
| spike_trigger | 가시 함정 발동 | 4 |
| selection_ring | 선택 표시 | 1 또는 4 반복 |

## 14. gpt-image-2 리소스 생성법

### 14.1 원칙

1. 게임 내 텍스트가 들어간 UI 이미지는 생성하지 않는다. UI 텍스트는 Godot Control/Text로 만든다.
2. 캐릭터는 먼저 “캐릭터 기준 시트”를 만들고, 이후 애니메이션 프레임을 만든다.
3. 스프라이트시트를 한 번에 완벽하게 만들려고 하지 않는다. 개별 포즈를 생성한 뒤 수작업 또는 스크립트로 시트화한다.
4. 모든 캐릭터와 오브젝트는 투명 배경 PNG를 목표로 한다.
5. 리소스 이름 규칙을 먼저 고정한다.

### 14.2 파일명 규칙

```text
monster_slime_idle_down_00.png
monster_slime_walk_down_00.png
monster_goblin_attack_side_00.png
monster_imp_cast_down_00.png

enemy_explorer_walk_down_00.png
enemy_thief_walk_side_00.png
enemy_trainee_hero_attack_down_00.png

tile_cave_floor_01.png
tile_cave_wall_top_01.png
prop_throne_01.png
prop_treasure_pile_01.png
fx_fireball_00.png
ui_icon_gold.png
```

### 14.3 공통 스타일 프롬프트

```text
cute horror fantasy quarter-view 2D game asset, charming spooky cave demon castle style, dark stone, purple magical glow, adorable SD proportions, readable silhouette, clean hand-painted indie game style, transparent background, no text, no logo, no watermark
```

### 14.4 슬라임 프롬프트

```text
Create a quarter-view 2D game character sprite for a cute blue slime monster, tank role, adorable round body, glossy jelly surface, tiny determined face, small shield-like aura, cute horror fantasy demon castle style, 128x128 canvas, transparent background, centered, readable silhouette, no text, no watermark.
Animation pose: idle down direction, frame 1 of 4.
```

### 14.5 고블린 프롬프트

```text
Create a quarter-view 2D game character sprite for a cute green goblin warrior, melee damage dealer, small dagger, mischievous expression, SD proportions, cute horror fantasy demon castle style, 128x128 canvas, transparent background, centered, readable silhouette, no text, no watermark.
Animation pose: walk side direction, frame 1 of 6.
```

### 14.6 임프 프롬프트

```text
Create a quarter-view 2D game character sprite for a cute red imp magic caster, small horns, tiny bat wings, yellow eyes, holding a little fireball, adorable but spooky, SD proportions, cute horror fantasy demon castle style, 128x128 canvas, transparent background, centered, readable silhouette, no text, no watermark.
Animation pose: cast down direction, frame 1 of 6.
```

### 14.7 적 프롬프트 기본형

```text
Create a quarter-view 2D game enemy sprite for a cute human explorer invading a demon castle, small hat, torch, backpack, nervous expression, readable silhouette, SD proportions, cute horror fantasy style, 128x128 canvas, transparent background, centered, no text, no watermark.
Animation pose: walk down direction, frame 1 of 6.
```

도적과 견습 용사는 explorer 부분만 thief / trainee hero로 바꾼다.

### 14.8 방 타일 프롬프트

```text
Create a seamless 64x64 quarter-view 2D cave floor tile for a cute horror fantasy demon castle, dark stone floor, subtle cracks, purple ambient light, hand-painted indie game style, no text, no objects, tileable, no watermark.
```

```text
Create a 64x64 quarter-view 2D cave wall tile for a cute horror fantasy demon castle, dark stone wall, purple magical rim light, readable edges, hand-painted indie game style, tileable, no text, no watermark.
```

### 14.9 UI 아이콘 프롬프트

```text
Create a small 128x128 game UI icon for gold coins, cute horror fantasy demon castle style, dark outline, bright readable icon, transparent background, no text, no logo, no watermark.
```

같은 구조로 mana droplet, food meat, infamy purple skull, shield command, attack command, survival command, trap lure command, direct control command를 만든다.

## 15. 데이터 파일 초안

### 15.1 monsters.json

```json
{
  "slime": {
    "display_name": "슬라임",
    "role": "tank",
    "max_hp": 180,
    "atk": 8,
    "def": 8,
    "move_speed": 90,
    "attack_range": 42,
    "attack_interval": 1.4,
    "int": 8,
    "loyalty": 70,
    "skill_slots": ["slime_shield", "hold_corridor", null]
  },
  "goblin": {
    "display_name": "고블린",
    "role": "melee",
    "max_hp": 140,
    "atk": 16,
    "def": 4,
    "move_speed": 130,
    "attack_range": 46,
    "attack_interval": 0.9,
    "int": 12,
    "loyalty": 65,
    "skill_slots": ["quick_slash", "loot_instinct", null]
  },
  "imp": {
    "display_name": "임프",
    "role": "caster",
    "max_hp": 120,
    "atk": 18,
    "def": 3,
    "move_speed": 115,
    "attack_range": 180,
    "attack_interval": 1.2,
    "int": 24,
    "loyalty": 85,
    "skill_slots": ["fireball", "flame_zone", null]
  }
}
```

### 15.2 enemies.json

```json
{
  "explorer": {
    "display_name": "탐험가",
    "goal_type": "throne",
    "max_hp": 90,
    "atk": 10,
    "def": 2,
    "move_speed": 105,
    "attack_range": 45,
    "attack_interval": 1.1,
    "morale": 60
  },
  "thief": {
    "display_name": "도적",
    "goal_type": "treasure",
    "max_hp": 70,
    "atk": 8,
    "def": 1,
    "move_speed": 155,
    "attack_range": 40,
    "attack_interval": 0.8,
    "morale": 50
  },
  "trainee_hero": {
    "display_name": "견습 용사",
    "goal_type": "throne",
    "max_hp": 220,
    "atk": 20,
    "def": 6,
    "move_speed": 110,
    "attack_range": 55,
    "attack_interval": 1.0,
    "morale": 100,
    "skills": ["hero_dash", "brave_shout"]
  }
}
```

### 15.3 waves.json

```json
{
  "day_1": [
    {"enemy_id": "explorer", "count": 2, "spawn_delay": 0.0}
  ],
  "day_2": [
    {"enemy_id": "explorer", "count": 2, "spawn_delay": 0.0},
    {"enemy_id": "thief", "count": 1, "spawn_delay": 5.0}
  ],
  "day_3": [
    {"enemy_id": "explorer", "count": 2, "spawn_delay": 0.0},
    {"enemy_id": "thief", "count": 1, "spawn_delay": 4.0},
    {"enemy_id": "trainee_hero", "count": 1, "spawn_delay": 8.0}
  ]
}
```

## 16. 제작 순서

### Phase 0. 프로젝트 초기화

목표: Godot 프로젝트가 실행되고 빈 메인 화면이 뜬다.

작업:

1. Godot 4.5 프로젝트 생성.
2. 해상도 1920×1080 설정.
3. stretch mode canvas_items, aspect keep 설정.
4. Main.tscn, GameRoot.tscn 생성.
5. SignalBus.gd, GameState.gd Autoload 등록.
6. 입력 액션 등록: select, command_move, skill_1, skill_2, skill_3, pause, next_unit.

완료 조건:

- 실행 시 빈 맵과 HUD 자리 표시자가 보인다.
- ESC 또는 Space로 일시정지 토글 로그가 찍힌다.

### Phase 1. 맵과 방 구조

목표: 쿼터뷰 동굴 마왕성 맵과 방 슬롯이 보인다.

작업:

1. DungeonMap.tscn 생성.
2. TileMapLayer 3개 배치: GroundLayer, WallLayer, DecorLayer.
3. RoomNode.tscn 생성.
4. 입구, 가시 복도, 병영, 보물 보관실, 회복 둥지, 왕좌의 방을 배치.
5. RoomGraph.gd로 방 연결 정의.
6. 방 클릭 시 SelectedRoom 정보가 HUD에 표시되게 한다.

완료 조건:

- 맵에서 방을 클릭하면 방 이름이 우측 또는 로그에 표시된다.
- 방 연결 데이터가 출력된다.

### Phase 2. 유닛 생성과 이동

목표: 슬라임, 고블린, 임프와 적이 맵 위에서 움직인다.

작업:

1. Unit.tscn 생성.
2. CharacterBody2D 기반 Unit.gd 작성.
3. Placeholder Sprite로 몬스터/적 구분.
4. RoomGraph 경로를 따라 이동하는 move_to_room 구현.
5. 적은 입구에서 등장해 목표 방으로 이동.
6. 몬스터는 기본 배치 방에서 대기.

완료 조건:

- 적이 입구에서 왕좌의 방까지 이동한다.
- 몬스터가 지정 방으로 이동한다.
- 충돌 시 서로 겹치지 않고 밀린다.

### Phase 3. 기본 전투

목표: 유닛이 적을 찾아 공격하고 HP가 줄어든다.

작업:

1. TargetingService.gd 작성.
2. DamageService.gd 작성.
3. 공격 사거리 판정.
4. 공격 쿨타임.
5. 근접 공격과 원거리 투사체 구현.
6. HP bar 표시.
7. DOWN 상태 처리.

완료 조건:

- 슬라임이 탐험가를 막고, 고블린이 공격한다.
- 임프가 원거리 투사체를 발사한다.
- HP 0이 되면 유닛이 사라지거나 down 애니메이션 상태가 된다.

### Phase 4. 행동지침

목표: 전체 지침과 방 지침이 전투에 영향을 준다.

작업:

1. DirectiveManager.gd 작성.
2. 전체 지침: 사수, 총공격, 생존 우선 구현.
3. 방 지침: 입구 봉쇄, 함정 유도, 후퇴선 유지 구현.
4. UI 버튼과 연결.
5. 전투 로그 출력.

완료 조건:

- 사수 선택 시 몬스터가 방을 벗어나지 않는다.
- 총공격 선택 시 적을 추격한다.
- 생존 우선 선택 시 HP가 낮은 몬스터가 회복 둥지로 후퇴한다.

### Phase 5. 직접 조종

목표: 선택 몬스터 하나를 직접 움직이고 스킬을 쓴다.

작업:

1. 유닛 클릭 선택.
2. 직접 조종 버튼.
3. 우클릭 이동.
4. 우클릭 적 공격 지정.
5. 스킬 버튼 1, 2, 3.
6. 직접 조종 해제.

완료 조건:

- 임프를 직접 조종해 화염구를 원하는 적에게 사용한다.
- 직접 조종 중 자동 AI가 개입하지 않는다.
- 해제하면 지침 AI로 복귀한다.

### Phase 6. UI 완성

목표: 데모 플레이에 필요한 HUD가 작동한다.

작업:

1. TopBar 구현.
2. RoomListPanel 구현.
3. SelectedUnitPanel 구현.
4. BattleCommandPanel 구현.
5. CombatLogPanel 구현.
6. ResultPanel 구현.
7. ManagementPanel, MonsterPanel 최소 구현.

완료 조건:

- 전투 중 자원, 마왕성 HP, 선택 유닛, 명령 버튼이 모두 보인다.
- 결산 화면에서 다음 날로 넘어간다.

### Phase 7. 3일 루프

목표: 3일 데모가 처음부터 끝까지 진행된다.

작업:

1. GameState.day 구현.
2. waves.json 로드.
3. day별 WaveManager 스폰.
4. 승리/패배 조건.
5. 3일차 견습 용사 격퇴 시 데모 클리어.

완료 조건:

- 1일차, 2일차, 3일차가 순서대로 진행된다.
- 3일차 승리 시 “데모 클리어” 표시.
- 왕좌의 방 HP가 0이면 “마왕성 함락” 표시.

### Phase 8. 이미지 리소스 적용

목표: Placeholder를 실제 GPT 이미지 기반 리소스로 교체한다.

작업:

1. 캐릭터 기준 이미지 생성.
2. idle/walk/attack/cast/hit/down 프레임 제작.
3. AnimatedSprite2D SpriteFrames 구성.
4. 타일셋 제작.
5. UI 아이콘 제작.
6. 이펙트 제작.

완료 조건:

- 슬라임, 고블린, 임프가 서로 시각적으로 명확히 구분된다.
- 탐험가, 도적, 견습 용사가 목표에 맞게 구분된다.
- 쿼터뷰 맵과 UI가 예시 이미지와 같은 큐트 호러 톤을 가진다.

## 17. 자유건설 확장 대비

데모는 슬롯 기반이지만, 다음 구조를 지키면 자유건설로 확장할 수 있다.

### 17.1 지금부터 지킬 것

- 방은 반드시 grid_position과 grid_size를 가진다.
- 방 연결은 하드코딩하지 않고 RoomGraph에서 관리한다.
- 유닛은 “방 ID”와 “월드 좌표”를 모두 가진다.
- 적 목표는 좌표가 아니라 goal_type으로 지정한다.
- 건설 가능 여부는 BuildSlot 또는 GridBuildValidator에서 판정한다.

### 17.2 추후 확장 방식

| 현재 데모 | 확장 버전 |
|---|---|
| 고정 방 슬롯 | 플레이어가 타일 격자에 방 배치 |
| RoomGraph 수동 연결 | 출입구 타일 기반 자동 연결 |
| 고정 경로 | AStarGrid2D 또는 NavigationAgent2D |
| 방 6종 | 방 40종 이상 |
| 1층 | 다층 구조 |

## 18. Codex 작업 지시문

아래 문장을 Codex에 그대로 입력해도 된다.

```text
Godot 4.5와 GDScript로 2D 쿼터뷰 데모 게임을 구현해줘. 게임명은 「마왕님, 마왕성은 누가 지켜요?」이고, 장르는 큐트 호러 판타지 마왕성 방어 시뮬레이션이다.

목표는 3일짜리 기능 테스트 데모다. 플레이어는 신입 마왕이며, 초라한 동굴 마왕성에서 슬라임, 고블린, 임프 3종의 몬스터를 배치하고 실시간으로 지휘해 탐험가, 도적, 견습 용사의 침공을 막는다.

반드시 구현할 기능:
1. PC 16:9, 1920x1080 기준 UI.
2. 쿼터뷰 2D 맵.
3. TileMapLayer 기반 동굴 맵 레이어: Ground, Wall, Decor.
4. 슬롯 기반 마왕성 구조: 입구, 가시 복도, 병영, 보물 보관실, 회복 둥지, 왕좌의 방, 건설 슬롯.
5. RoomGraph 기반 이동 경로.
6. CharacterBody2D 기반 Unit.
7. 몬스터 3종: 슬라임, 고블린, 임프.
8. 적 3종: 탐험가, 도적, 견습 용사.
9. 실시간 자동 전투: 타깃 탐색, 이동, 공격, HP 감소, 전투 불능.
10. 원거리 투사체: 임프 화염구.
11. 가시 복도 함정: 적 진입 시 피해와 둔화.
12. 전체 지침: 사수, 총공격, 생존 우선.
13. 방 지침: 입구 봉쇄, 함정 유도, 후퇴선 유지.
14. 직접 조종: 선택 몬스터 하나를 우클릭 이동시키고 스킬 버튼으로 스킬 사용.
15. 전투 HUD: 상단 자원바, 좌측 미니맵/방 목록/전투 로그, 우측 선택 유닛 정보, 하단 지침 버튼.
16. 관리 화면: 방 확인, 몬스터 관리 화면, 다음 날 진행.
17. 3일 웨이브: 1일차 탐험가, 2일차 탐험가+도적, 3일차 탐험가+도적+견습 용사.
18. 승리 조건: 3일차 견습 용사 격퇴.
19. 패배 조건: 왕좌의 방 HP 0.
20. 결산 화면: 획득 금화, 마력, 악명, 몬스터 경험치 표시.

우선 Placeholder 그래픽으로 구현하고, assets 폴더 구조와 SpriteFrames 교체 구조를 만들어줘. 코드는 data JSON을 로드할 수 있게 설계하고, 추후 자유건설로 확장할 수 있도록 RoomData에 grid_position, grid_size, exits를 포함해줘. 각 Phase별로 커밋 가능한 단위로 작업해줘.
```

## 19. 완료 판정 체크리스트

### 필수 통과

- [ ] 프로젝트 실행 시 관리 화면이 뜬다.
- [ ] 방어 준비 후 전투 화면으로 이동한다.
- [ ] 적이 입구에서 등장해 목표 방으로 이동한다.
- [ ] 슬라임, 고블린, 임프가 자동으로 적을 공격한다.
- [ ] 임프가 화염구 투사체를 발사한다.
- [ ] 가시 복도 함정이 적에게 피해를 준다.
- [ ] 전체 지침 변경이 전투 행동에 반영된다.
- [ ] 방 지침 변경이 특정 방 행동에 반영된다.
- [ ] 몬스터 하나를 직접 조종할 수 있다.
- [ ] 왕좌의 방 HP가 0이면 패배한다.
- [ ] 3일차 견습 용사를 잡으면 데모 클리어가 뜬다.
- [ ] 결산 화면이 표시된다.

### 후순위

- [ ] 미니맵에 유닛 위치 표시.
- [ ] 몬스터 레벨업 스킬 후보 선택.
- [ ] 마왕성 관리 화면에서 방 건설.
- [ ] 실제 이미지 리소스 적용.
- [ ] 사운드 이펙트.
- [ ] 튜토리얼 대사.
