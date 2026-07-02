이 파일이 왜 필요한지: 2026-07-02 현재까지 구현한 데모 상태, 최신 수정 내용, 검증 방법, 다음 작업 우선순위를 다음 작업자가 바로 이어받을 수 있게 정리한다.

# 마왕성 데모 현재 상태 핸드오프

작성일: 2026-07-02

## 결론

현재 프로젝트는 Godot 4.5.2에서 실행 가능한 마왕성 방어 데모이며, 최신 목표는 2D 쿼터뷰 기준으로 전환/개선하는 것이다.

관리 화면에서 방과 몬스터를 확인하고, 몬스터를 드래그 배치하고, 선택 방의 용도를 바꾼 뒤 방어 준비로 전투에 들어가며, 전투 후 결과 화면까지 이어지는 기본 플레이 루프는 연결되어 있다. 최근 작업으로 던전 배경, 방 클릭 좌표, 방 용도 표시, 전투 상태 UI, 간단한 전술 전투, 캐릭터 애니메이션 구조까지 들어갔다.

다만 상용 완성판은 아니다. 지금 기준은 "검수 가능한 데모"이며, 다음 단계는 사람이 직접 플레이하면서 재미, 템포, 가독성, 방 용도 변경 비용과 밸런스를 다듬는 것이다.

## 실행 환경

- 엔진: Godot 4.5.2
- 확인한 버전 출력: `4.5.2.stable.official.6ce3de25a`
- 현재 사용 중인 실행 파일:
  `C:\Users\LDK-6248\AppData\Roaming\npm\godot.cmd`
- 프로젝트 루트:
  `C:\Users\LDK-6248\Desktop\AI개발\어시스트프로젝트\마왕성`
- 원격 저장소:
  `https://github.com/bluehige/mawangseong-demo.git`

## 현재 주요 흐름

1. 실행하면 관리 화면이 열린다.
2. 던전 맵에서 방을 클릭해 선택한다.
3. 왼쪽 시설 배치 목록과 오른쪽 선택 방 정보가 갱신된다.
4. 선택 방 패널에서 병영, 보물고, 회복, 감시, 빈 슬롯으로 방 용도를 바꿀 수 있다.
5. 관리 화면의 몬스터 프리뷰를 드래그해서 원하는 방에 놓으면 바로 배치된다.
6. 몬스터 관리 화면에서는 슬라임, 고블린, 임프의 정보와 훈련을 확인한다.
7. `방어 준비`를 누르면 전투가 시작된다.
8. 침입자는 입구에서 등장해 왕좌 또는 현재 보물 보관실을 목표로 이동한다.
9. 몬스터는 전체 지침과 방 지침에 따라 방어, 추격, 후퇴, 함정 유도 등을 수행한다.
10. 전투 중 유닛 상태 UI에서 아군과 침입자의 체력, 행동 상태, 목표를 확인할 수 있다.
11. 유닛 선택 후 직접 조종, 스킬 입력, AI 복귀를 사용할 수 있다.
12. 전투가 끝나면 결과 화면으로 넘어간다.

## 지금까지 완료한 큰 작업

### 1. 프로젝트 기반

- Godot 프로젝트 구조 생성
- `Main.tscn`에서 `GameRoot.tscn` 실행
- 데이터 파일 분리:
  - `data/rooms.json`
  - `data/monsters.json`
  - `data/enemies.json`
  - `data/skills.json`
  - `data/waves.json`
- 자동 검증 씬 추가:
  - `tools/DemoSmokeTest.tscn`
  - `tools/ManualVerificationCapture.tscn`

### 2. 화면 구조

- 관리 화면
- 몬스터 관리 화면
- 전투 화면
- 결과 화면
- 상단 자원 바
- 방 목록과 선택 방 정보 패널
- 전투 로그
- 선택 유닛 정보 패널
- 전체 지침, 방 지침, 속도 조절 UI

### 3. 코드 구조 정리

`GameRoot.gd` 하나에 모든 기능이 몰리지 않도록 다음 컨트롤러로 나눴다. 여기서 컨트롤러는 특정 화면이나 기능 묶음을 관리하는 코드 파일이라고 보면 된다.

- `scripts/game/GameRoot.gd`: 전체 상태, 씬 전환, 공통 입력의 중심
- `scripts/game/ManagementSceneController.gd`: 관리, 몬스터, 결과 화면 구성
- `scripts/game/CombatSceneController.gd`: 전투 진행, AI, 공격, 스킬, 보상 처리
- `scripts/ui/HUDController.gd`: 공통 UI 부품 생성
- `scripts/map/DungeonRenderer.gd`: 던전 배경, 방 영역, 라벨, 아이콘 렌더링
- `scripts/units/Unit.gd`: 유닛 능력치, 상태, 이동, 애니메이션

### 4. 던전 맵

초기에는 방 사각형을 UI처럼 얹은 형태였고, 이후 레퍼런스를 기준으로 실제 던전처럼 보이게 수정했다.

현재 던전은 GPT 이미지 생성으로 만든 연결형 던전 배경을 사용한다.

- 입구: 좌하단
- 가시 복도: 중앙 하단
- 중앙 통로: 중앙
- 왕좌의 방: 상단
- 병영: 좌중단
- 회복 둥지: 우중단
- 건설 슬롯: 회복 둥지 아래쪽
- 보물 보관실: 우하단

최신 수정으로 실제 방 클릭 영역과 라벨 위치를 새 배경 이미지 기준으로 다시 맞췄다.

중요한 점:

- 방의 물리적 위치는 `data/rooms.json`의 `rect`, `center`가 결정한다.
- 방의 용도 표시는 `icon`, `icon_offset`, `icon_size`가 결정한다.
- 이제 보관실/병영/회복둥지 같은 용도 이미지는 배경 이미지에 고정된 것이 아니라 별도 레이어로 그려진다.
- 따라서 나중에 방 용도를 바꾸려면 `rooms.json`의 `icon`과 `type`을 바꾸는 방향으로 확장하면 된다.

### 5. 방 용도 아이콘

사용자 요청에 맞춰 그래픽 제작은 GPT 이미지 생성 경로를 사용했다.

추가된 위치:

- `assets/sprites/room_markers/gpt2_room_marker_sheet.png`
- `assets/sprites/room_markers/marker_gate_gpt2.png`
- `assets/sprites/room_markers/marker_spike_corridor_gpt2.png`
- `assets/sprites/room_markers/marker_brazier_passage_gpt2.png`
- `assets/sprites/room_markers/marker_throne_gpt2.png`
- `assets/sprites/room_markers/marker_barracks_gpt2.png`
- `assets/sprites/room_markers/marker_treasure_gpt2.png`
- `assets/sprites/room_markers/marker_recovery_nest_gpt2.png`
- `assets/sprites/room_markers/marker_recovery_room_gpt2.png`
- `assets/sprites/room_markers/marker_build_slot_gpt2.png`
- `assets/sprites/room_markers/SOURCE.md`

원본 GPT 생성 파일은 다음 위치에 남아 있다.

```text
C:\Users\blueh\.codex\generated_images\019f1d97-678f-73e1-9106-3e8b68f3c791\ig_0f8e0a9ce186c6cb016a4533e4852c819192fb8a1b61f733d2.png
```

### 6. 전투 시스템

현재 전투는 복잡한 완성형 전략 게임은 아니지만, 데모의 철학을 보여주기 위한 최소 전술 흐름은 들어가 있다.

구현된 방향:

- 입구 봉쇄
- 가시 복도 함정 유도
- 배치 방 사수
- 체력이 낮은 몬스터의 회복 둥지 후퇴
- 침입자의 왕좌 압박
- 도둑의 보물 보관실 침투와 약탈
- 수련생 용사의 돌진형 행동
- 몬스터의 우선 타깃 판단
- 방어 스킬 사용 시 방어력 보너스
- 스킬 사용 시 위협 대상 지정

유닛 상태는 다음처럼 표시된다.

- 대기
- 방 이동
- 목표 추적
- 공격
- 스킬 사용
- 후퇴
- 직접 조종
- 약탈
- 쓰러짐

### 7. 애니메이션

캐릭터는 단일 이미지 표시에서 `AnimatedSprite2D`와 `SpriteFrames` 기반 구조로 확장했다.

현재 각 캐릭터는 아래 슬롯을 가진다.

- `idle_down`
- `move_down`
- `attack_down`
- `skill_down`
- `down`

그래픽은 GPT 이미지 생성으로 만든 캐릭터 애니메이션 시트를 잘라 사용했다.

관련 위치:

- `assets/sprites/animation_gpt2/gpt2_character_animation_sheet.png`
- `assets/sprites/monsters/*_idle_down_00.png`
- `assets/sprites/monsters/*_move_down_00.png`
- `assets/sprites/monsters/*_attack_down_00.png`
- `assets/sprites/monsters/*_skill_down_00.png`
- `assets/sprites/monsters/*_down_00.png`
- `assets/sprites/enemies/*_idle_down_00.png`
- `assets/sprites/enemies/*_move_down_00.png`
- `assets/sprites/enemies/*_attack_down_00.png`
- `assets/sprites/enemies/*_skill_down_00.png`
- `assets/sprites/enemies/*_down_00.png`

현재 몬스터 3종은 추가 파생 프레임을 붙여 다중 프레임으로 재생된다.

- 몬스터 `idle_down`: 2프레임
- 몬스터 `move_down`: 4프레임
- 몬스터 `attack_down`: 4프레임
- 몬스터 `skill_down`: 4프레임
- 몬스터 `down`: 2프레임

적 캐릭터는 아직 `_00` 중심이다. 적 움직임을 더 살리려면 다음 단계에서 같은 방식으로 `assets/sprites/enemies`에도 파생 프레임을 추가하면 된다.

스킬 이펙트도 `AnimatedSprite2D` 시퀀스로 재생된다.

- `fx_fireball_00~03.png`
- `fx_hit_slash_00~03.png`
- `fx_fire_impact_00~03.png`
- `fx_shield_pulse_00~03.png`
- `fx_guard_pulse_00~03.png`
- `fx_loot_spark_00~03.png`

## 최신 수정 내용

이번 2026-07-02 작업에서 바뀐 내용:

- 관리 화면의 방 표시를 새 던전 배경 좌표에 맞게 수정
- `rooms.json`의 `rect`, `center`를 실제 방 위치 기준으로 재조정
- 방 용도 표시 이미지를 `assets/sprites/room_markers`로 분리
- `GameRoot.gd`에 `room_icon_path()` 추가
- `DungeonRenderer.gd`가 연결형 던전 배경 위에도 방 용도 아이콘을 별도 레이어로 그리게 수정
- 전투 화면에서는 방 아이콘 투명도를 낮춰 유닛을 덜 가리도록 조정
- `HUDController.gd`의 왼쪽 방 목록을 아이콘이 있는 시설 배치 UI로 변경
- 방 클릭 영역이 겹칠 때 작은 방이 우선 선택되도록 `_room_at()` 판정 수정

추가 UI 가독성 보정:

- 전투 화면에서 관리용 몬스터 배치 프리뷰를 숨겨 실제 전투 유닛과 중복 표시되지 않게 수정
- 전투 화면의 방 용도 마커, 라벨, 선택 테두리 투명도와 크기를 낮춰 유닛과 교전 지점이 더 잘 보이게 조정
- 전투 하단의 전체 지침/방 지침 패널을 맵 아래쪽으로 내리고 높이를 줄여 중앙 하단 맵을 덜 가리게 수정
- 전투 속도 패널도 하단 안전 영역으로 내려 지침 패널과 정렬
- 왼쪽 전장 상태/전투 로그 패널 폭을 줄여 입구 쪽 맵 침범을 줄임
- 이번 작업의 별도 작업 로그 백업은 `docs/WORK_LOG_2026-07-02_UI_READABILITY.md`에 남김

추가 배치 UX 변경:

- 관리 화면에서 방 위에 표시되는 몬스터 프리뷰를 마우스로 드래그해 원하는 방에 놓으면 즉시 배치되도록 수정
- 드래그 중에는 대상 방이 노란색으로 하이라이트되고, 배치 불가 방은 붉은색으로 표시됨
- 비어 있는 건설 슬롯과 배치 한도가 찬 방에는 드롭해도 배치되지 않음
- 몬스터 관리 화면의 기존 `배치` 버튼과 `선택 방 배치` 버튼을 제거하고 훈련/정보 확인 전용 화면으로 분리
- 관리 화면의 `몬스터` 버튼은 `몬스터 관리`로 이름을 바꿈
- `DemoSmokeTest.tscn`에 관리 화면 몬스터 드래그 시작과 드래그 배치 검증을 추가
- 이번 작업의 별도 작업 로그 백업은 `docs/WORK_LOG_2026-07-02_DRAG_PLACEMENT.md`에 남김

추가 방 용도 변경 시스템:

- 선택 방 정보 패널에 `시설 변경` 버튼을 추가
- 변경 가능한 용도:
  - 병영
  - 보물고
  - 회복
  - 감시
  - 빈 슬롯
- 입구, 가시 복도, 중앙 통로, 왕좌의 방은 고정 시설로 두고 변경 불가 처리
- 병영, 보물고, 회복, 감시는 비용을 지불하고 변경
- 빈 슬롯 전환은 무료 처리
- 보물고와 회복은 고유 시설로 처리해서 새 위치로 옮기면 기존 위치는 빈 슬롯으로 전환
- 변경 후 빈 슬롯이 되거나 최대 배치 수를 넘는 방에 있던 몬스터는 자동으로 유효한 방으로 재배치
- 기존 하단 `건설` 버튼은 선택된 빈 슬롯을 감시 초소로 바꾸는 빠른 동작으로 유지
- 전투 로직에서 도둑 목표, 약탈 판정, 몬스터 우선 타깃, 회복 후퇴가 현재 시설 역할을 조회하도록 변경
- `DemoSmokeTest.tscn`에 병영을 보물 보관실로 바꾸고 도둑 목표가 새 보물방을 추적하는 검증을 추가
- `ManualVerificationCapture.tscn`의 첫 관리 화면 캡처는 병영 선택 상태로 찍어 시설 변경 버튼을 바로 확인하게 변경
- 이번 작업의 별도 작업 로그 백업은 `docs/WORK_LOG_2026-07-02_ROOM_PURPOSE_SYSTEM.md`에 남김

추가 배경 이미지 보정:

- 방 용도 변경 후에도 우하단 방이 배경 자체에서 보물방처럼 보이는 문제를 수정
- GPT Image 2 편집으로 `assets/sprites/dungeon_gpt2/gpt2_dungeon_connected_map.png`의 우하단 보물더미/상자를 제거
- 우하단 방은 중립적인 빈 방/보관 공간처럼 보이게 변경
- 전체 던전 구조, 통로, 벽, 조명, 다른 방의 분위기는 유지
- 생성 원본 경로와 편집 이유는 `assets/sprites/dungeon_gpt2/SOURCE.md`에 추가
- 이번 작업의 별도 작업 로그 백업은 `docs/WORK_LOG_2026-07-02_NEUTRAL_DUNGEON_BACKGROUND.md`에 남김

추가 회복방 분리 보정:

- 우상단 회복 둥지도 배경에서 제거해 중립 방처럼 보이게 수정
- 새 회복 시설 전용 아이콘 `assets/sprites/room_markers/marker_recovery_room_gpt2.png` 추가
- `data/rooms.json`과 `GameRoot.gd`의 회복 시설 정의가 새 아이콘을 사용하도록 변경
- 생성 원본 경로와 처리 방식은 `assets/sprites/room_markers/SOURCE.md`에 추가
- 이번 작업의 별도 작업 로그 백업은 `docs/WORK_LOG_2026-07-02_RECOVERY_ROOM_DECOUPLE.md`에 남김

## 검증 방법

Godot import:

```powershell
godot --headless --path . --import
```

자동 스모크 테스트:

```powershell
godot --headless --path . --scene res://tools/DemoSmokeTest.tscn
```

수동 검증 캡처:

```powershell
godot --path . --scene res://tools/ManualVerificationCapture.tscn
```

캡처 결과:

```text
tmp/manual_verification/01_management.png
tmp/manual_verification/02_monster.png
tmp/manual_verification/03_combat_start.png
tmp/manual_verification/04_combat_controls.png
tmp/manual_verification/05_result.png
```

최근 확인 결과:

- Godot import 성공
- `DemoSmokeTest.tscn` 종료 코드 0, `DEMO_SMOKE_TEST: PASS`
- 수동 검증 캡처 성공
- 캡처 기준 전투 하단 지침 패널이 맵 영역 밖으로 내려갔고, 전투 중 방 마커/라벨이 유닛을 덜 가림
- 캡처 기준 관리 화면 하단에 드래그 배치 안내가 보이고, 몬스터 관리 화면은 배치 버튼 없이 훈련 중심으로 표시됨
- 캡처 기준 선택 방 패널에 시설 변경 버튼 5개와 비용 문구가 겹침 없이 표시됨
- 자동 테스트 기준 방 용도 변경 비용 차감, 기존 보물고의 빈 슬롯 전환, 도둑 목표 동적 추적이 통과됨
- 캡처 기준 우하단 방 배경에서 고정 보물더미가 제거되어 용도 변경 후 시각 충돌이 줄어듦
- 캡처 기준 우상단 방 배경에서 고정 회복 둥지가 제거되고, 회복 시설은 별도 아이콘으로 표시됨
- 자동 테스트 기준 직접 조종 시작 시 기존 AI 이동 경로가 즉시 정지하고, 적 우클릭 공격 대상 추적이 통과됨
- 자동 테스트 기준 전투 중 맵 바닥 좌클릭은 더 이상 방 선택으로 처리되지 않음
- 캡처 기준 전투 맵 위 방 마커/방 라벨/방 선택 테두리는 숨겨지고, 왼쪽 방 목록을 통한 방 지침 선택은 유지됨
- 자동 테스트 기준 몬스터 이동/공격/스킬 애니메이션 다중 프레임 로딩이 통과됨
- 자동 테스트 기준 화염구/방어 스킬 이펙트 다중 프레임 로딩과 방어 스킬 이펙트 생성이 통과됨

## 이어서 볼 주요 파일

- `data/rooms.json`: 방 위치, 방 연결, 방 용도, 아이콘 설정
- `scripts/map/DungeonRenderer.gd`: 던전 배경, 방 영역, 방 아이콘, 라벨 렌더링
- `scripts/ui/HUDController.gd`: 관리/전투 UI 패널과 버튼
- `scripts/game/GameRoot.gd`: 전체 상태, 입력, 씬 전환
- `scripts/game/CombatSceneController.gd`: 전투 흐름, AI, 스킬, 보상
- `scripts/units/Unit.gd`: 유닛 상태, 이동, 애니메이션

## 다음 작업 우선순위

1. 실제 플레이로 몬스터 드래그 배치의 클릭/드롭 감각을 검수
2. 실제 플레이로 방 용도 변경 비용과 고유 시설 이동 규칙을 검수
3. 용도 변경 후 몬스터 자동 재배치가 플레이어에게 충분히 잘 전달되는지 확인
4. 실제 플레이로 전투 HUD 조작감을 검수
5. 방 아이콘을 더 작고 상징적인 게임 UI 마커로 추가 개선할지 판단
6. 전투에서 방 지침과 몬스터 행동의 체감 차이를 더 크게 만들기
7. 적 캐릭터 애니메이션도 몬스터와 같은 방식으로 2~4프레임으로 늘릴지 판단
8. UI 검수
   - 텍스트 넘침
   - 버튼 클릭 범위
   - 전투 중 유닛과 패널 겹침
9. 밸런스 검수
   - 1일차 쉬움
   - 2일차 압박
   - 3일차 데모 보스 느낌

## 추가 전투 밸런스/충돌 작업

2026-07-02 추가 작업:

- 도둑이 몬스터 유닛을 관통하지 못하도록 유닛 충돌체를 구현했다.
- 유닛 충돌체는 근접 전투가 붙어서 보이도록 반경 14px 원형으로 축소했다.
- 몬스터와 적은 서로 물리 충돌하고, 같은 진영은 물리 충돌 대신 소프트 회피만 적용해 적 무리가 입구에서 교통 정체로 멈추는 문제를 줄였다.
- 충돌 시 옆 방향 우회 지점을 잠시 잡아 도둑이 막힌 유닛을 돌아가도록 했다.
- 다운된 유닛의 충돌체를 비활성화해 길막 잔상이 남지 않게 했다.
- 적이 현재 방 몬스터를 추격할 때 최종 목표 방을 덮어쓰던 문제를 수정했다. 이 문제 때문에 탐험가가 입구 몬스터를 잡은 뒤 왕좌로 가지 않고 `goal_room=entrance`로 남을 수 있었다.
- 3일차 난이도를 올리기 위해 수련생 용사 수치와 3일차 웨이브를 조정했다.
- 2일차/3일차에서 지시와 임프 스킬의 가치가 보이도록 함정 유도 상태의 가시 복도 효과와 임프 스킬 피해를 보정했다.
- 밸런스 측정용 `tools/BalanceSimulation.tscn` / `tools/BalanceSimulation.gd`를 추가했다.
- 이번 작업의 별도 작업 로그 백업은 `docs/WORK_LOG_2026-07-02_BALANCE_AND_COLLISION.md`에 남겼다.

최종 밸런스 시뮬레이션 결과:

| scenario | result | time | throne hp | monster down | enemies | thief reached | thief stole | skill uses |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| DAY1_AUTO | WIN | 36.5 | 1500 | 1 | 2/2 | N | N | 0 |
| DAY2_AUTO | WIN | 27.1 | 1500 | 0 | 3/3 | N | N | 0 |
| DAY2_TRAP_DIRECTIVE | WIN | 19.4 | 1500 | 0 | 3/3 | N | N | 0 |
| DAY3_AUTO | LOSS | 59.6 | 0 | 3 | 1/5 | N | N | 0 |
| DAY3_ASSISTED | WIN | 25.1 | 1500 | 2 | 5/5 | N | N | 8 |

추가 검증 명령:

```powershell
godot --headless --path . --scene res://tools/BalanceSimulation.tscn
godot --headless --path . --scene res://tools/BalanceSimulation.tscn -- --scenario=DAY3_AUTO
```

다음 작업 우선순위 갱신:

1. 실제 플레이로 1일차 자동 전투에서 슬라임이 쓰러지는 체감이 "쉬움" 범위인지 확인.
2. 도둑 훔치기 게이지/남은 시간 UI를 추가해 2일차 위협을 명확하게 전달.
3. 스킬 피해량과 함정 지시 보정값을 `data/skills.json` 또는 별도 밸런스 데이터로 분리.
4. 3일차 직접 조종/임프 스킬 사용 흐름을 실제 플레이로 확인하고, 스킬 선택/쿨다운 피드백을 보강.

## 추가 지침 패키지 정리 작업

2026-07-02 추가 작업:

- `mawang_guideline_pack` 전체 문서를 확인하고, 현재 목표인 2D 쿼터뷰 기준으로 전환했다.
- 기존 탑뷰 기준 문구와 top-down 프롬프트를 쿼터뷰/quarter-view 기준으로 변경했다.
- `reference/99_REFERENCE_topview_demo_spec.md`를 `reference/99_REFERENCE_quarterview_demo_spec.md`로 변경했다.
- `docs/08_CURRENT_QUARTERVIEW_GUIDELINES.md`를 추가했다. 다음 세션은 이 문서를 먼저 읽고 진행한다.
- 쿼터뷰 구현 기준은 완전 3D가 아니라 2D 좌표계, 발밑 피벗, Y-sort, 쿼터뷰 배경/스프라이트다.
- `docs/01_SESSION_START_COMMANDS.md`와 `docs/06_DECISION_LOG_TEMPLATE.md`에 핸드오프 작성 기준을 명확히 추가했다.
- 이번 작업의 별도 작업 로그 백업은 `docs/WORK_LOG_2026-07-02_GUIDELINE_QUARTERVIEW_UPDATE.md`에 남겼다.

다음 세션 시작 문장:

```text
현재 목표는 「마왕님, 마왕성은 누가 지켜요?」 데모를 2D 쿼터뷰 기준으로 전환/개선하는 것이다.

반드시 `mawang_guideline_pack/docs/08_CURRENT_QUARTERVIEW_GUIDELINES.md`를 먼저 확인하고, 현재 핸드오프 문서와 작업 로그를 읽은 뒤 진행해라.

쿼터뷰는 완전 3D가 아니라 2D 좌표계, 발밑 피벗, Y-sort, 쿼터뷰 배경/스프라이트로 구현한다.

작업이 끝나면 핸드오프 문서와 별도 작업 로그를 갱신하고, 실행/테스트 명령과 결과를 남겨라.
```

## 추가 직접 조종 보정 작업

2026-07-02 추가 작업:

- 직접 조종을 시작해도 기존 AI `path_points`가 남아 있어 몬스터가 사용자의 의도와 다르게 계속 움직일 수 있던 문제를 수정했다.
- 몬스터 선택 후 직접 조종을 시작하면 기존 이동 경로, 우회 지점, 이전 명령 대상이 즉시 초기화된다.
- 전투 화면에서 몬스터 선택 후 맵 바닥을 우클릭하면 지정 위치로 이동한다.
- 전투 화면에서 몬스터 선택 후 적을 우클릭하면 `command_target`이 지정되고, 적이 움직여도 현재 위치를 계속 추적한다.
- 직접 조종 중 공격 판정은 사거리 안에 있는 수동 지정 대상을 우선 공격한다.
- 전투 UI 패널 위 우클릭은 이동 명령으로 처리하지 않아, 패널 조작 중 의도치 않은 이동 명령을 줄였다.
- `DemoSmokeTest.tscn`에 직접 조종 시작 시 AI 경로 정지, 적 우클릭 대상 지정, 대상 추적 이동 검증을 추가했다.
- 이번 작업의 별도 작업 로그 백업은 `docs/WORK_LOG_2026-07-02_DIRECT_CONTROL_FIX.md`에 남겼다.

이번 세션에서 변경한 파일:

- `scripts/units/Unit.gd`
- `scripts/game/GameRoot.gd`
- `scripts/game/CombatSceneController.gd`
- `tools/DemoSmokeTest.gd`
- `docs/HANDOFF_CURRENT_STATE_2026-07-02.md`
- `docs/WORK_LOG_2026-07-02_DIRECT_CONTROL_FIX.md`

검증한 명령과 결과:

```powershell
godot --headless --path . --scene res://tools/DemoSmokeTest.tscn
godot --headless --path . --import
```

결과:

- `DemoSmokeTest.tscn` 종료 코드 0, `DEMO_SMOKE_TEST: PASS`
- Godot import 종료 코드 0

다음 세션 첫 작업:

1. 실제 플레이로 몬스터 선택 후 우클릭 이동 감각을 확인.
2. 이동 중인 적을 우클릭했을 때 계속 따라붙는지 확인.
3. 패널 위 우클릭이 명령으로 들어가지 않는지 확인.
4. 필요하면 직접 조종 모드 표시와 커서 피드백을 더 명확하게 보강.

## 추가 전투 맵 방 선택 비활성화 작업

2026-07-02 추가 작업:

- 전투 중 맵 바닥을 좌클릭했을 때 `selected_room`이 바뀌던 문제를 수정했다.
- 전투 화면의 좌클릭은 이제 유닛 선택 전용으로 동작하고, 유닛이 없는 바닥 클릭은 아무 방도 선택하지 않는다.
- 전투 중 맵 위 방 선택 테두리, 방 용도 마커, 방 라벨을 숨겼다.
- 방별 전투 지침은 기존처럼 왼쪽 방 목록에서 방을 선택한 뒤 하단 방 지침 버튼으로 변경한다.
- `DemoSmokeTest.tscn`에 전투 중 맵 바닥 클릭이 방 선택을 바꾸지 않는 검증을 추가했다.
- 일반 렌더러로 `ManualVerificationCapture.tscn`을 실행해 전투 화면 캡처를 확인했다.
- 이번 작업의 별도 작업 로그 백업은 `docs/WORK_LOG_2026-07-02_COMBAT_ROOM_SELECTION_FIX.md`에 남겼다.

이번 세션에서 변경한 파일:

- `scripts/game/GameRoot.gd`
- `scripts/map/DungeonRenderer.gd`
- `tools/DemoSmokeTest.gd`
- `docs/HANDOFF_CURRENT_STATE_2026-07-02.md`
- `docs/WORK_LOG_2026-07-02_COMBAT_ROOM_SELECTION_FIX.md`

검증한 명령과 결과:

```powershell
godot --headless --path . --scene res://tools/DemoSmokeTest.tscn
godot --headless --path . --import
godot --path . --scene res://tools/ManualVerificationCapture.tscn
```

결과:

- `DemoSmokeTest.tscn` 종료 코드 0, `DEMO_SMOKE_TEST: PASS`
- Godot import 종료 코드 0
- 일반 렌더러 수동 검증 캡처 성공
- `--headless` 수동 캡처는 Godot dummy 렌더러에서 뷰포트 텍스처가 null이라 실패하므로, 캡처 검증은 일반 렌더러로 실행해야 한다.

다음 세션 첫 작업:

1. 실제 플레이로 전투 중 맵 바닥 좌클릭이 유닛 선택 외에는 아무 동작도 하지 않는지 확인.
2. 왼쪽 방 목록에서 방 선택 후 하단 `방 지침` 버튼으로 지침 변경이 충분히 직관적인지 확인.
3. 필요하면 왼쪽 방 목록 제목을 `방 지침 선택`처럼 더 명확한 문구로 바꿀지 판단.

## 추가 몬스터 애니메이션/스킬 이펙트 보강 작업

2026-07-02 추가 작업:

- 현재 몬스터 애니메이션과 스킬 이펙트 에셋/코드 연결 상태를 확인했다.
- 확인 결과 몬스터 애니메이션 슬롯은 있었지만 대부분 액션당 `_00` 1프레임만 있어 실제 움직임이 제한적이었다.
- 확인 결과 화염구/베기/충격 이펙트도 1프레임 텍스처에 tween만 붙은 상태였다.
- `tools/generate_animation_variants.py`를 추가해 기존 PNG 기반 파생 프레임을 생성하도록 했다.
- 슬라임, 고블린, 임프의 `idle_down`, `move_down`, `attack_down`, `skill_down`, `down` 프레임을 보강했다.
- 화염구, 베기, 충격, 방어막, 가드, 약탈 스파크 이펙트를 4프레임 시퀀스로 추가했다.
- `GameRoot.gd`에 `effect_frame_sets` 로더를 추가했다.
- `CombatSceneController.gd`의 전투 이펙트를 `AnimatedSprite2D` 시퀀스로 재생하도록 바꿨다.
- 슬라임 점액 방패, 슬라임 통로 막기, 고블린 약탈 본능에도 버프 이펙트를 연결했다.
- 화염구 착탄 이펙트가 발사 즉시 뜨지 않고 투사체 도착 후 발생하도록 타이밍을 수정했다.
- 에셋 생성 방식은 `assets/sprites/animation_gpt2/SOURCE.md`와 `assets/sprites/effects/SOURCE.md`에 남겼다.
- 이번 작업의 별도 작업 로그 백업은 `docs/WORK_LOG_2026-07-02_MONSTER_ANIMATION_EFFECTS.md`에 남겼다.

이번 세션에서 변경한 주요 파일:

- `assets/sprites/monsters/*_01~03.png`
- `assets/sprites/effects/fx_*_01~03.png`
- `assets/sprites/effects/fx_shield_pulse_00~03.png`
- `assets/sprites/effects/fx_guard_pulse_00~03.png`
- `assets/sprites/effects/fx_loot_spark_00~03.png`
- `scripts/game/GameRoot.gd`
- `scripts/game/CombatSceneController.gd`
- `tools/generate_animation_variants.py`
- `tools/DemoSmokeTest.gd`
- `assets/sprites/animation_gpt2/SOURCE.md`
- `assets/sprites/effects/SOURCE.md`
- `docs/HANDOFF_CURRENT_STATE_2026-07-02.md`
- `docs/WORK_LOG_2026-07-02_MONSTER_ANIMATION_EFFECTS.md`

검증한 명령과 결과:

```powershell
python tools/generate_animation_variants.py
godot --headless --path . --import
godot --headless --path . --scene res://tools/DemoSmokeTest.tscn
```

결과:

- PNG 파생 프레임 생성 성공
- Godot import 종료 코드 0
- `DemoSmokeTest.tscn` 종료 코드 0, `DEMO_SMOKE_TEST: PASS`

다음 세션 첫 작업:

1. 실제 전투에서 몬스터 이동/공격/스킬 프레임이 과하거나 튀지 않는지 확인.
2. 스킬 이펙트 크기와 지속 시간이 유닛을 너무 가리지 않는지 확인.
3. 적 캐릭터도 같은 방식으로 다중 프레임을 추가할지 판단.
4. 필요하면 `tools/generate_animation_variants.py`의 scale/offset 값을 조정해 프레임 차이를 더 자연스럽게 만든다.

## 주의할 점

- 현재 던전 배경은 이미지 한 장이지만, 방 용도 표시는 분리했다. 배경 자체의 방 구조를 바꾸면 `rooms.json` 좌표도 같이 바꿔야 한다.
- `rect`는 클릭 영역이고, `center`는 유닛 배치와 이동 목표 기준이다.
- 작은 방과 큰 방 영역이 겹칠 수 있어서 `_room_at()`은 작은 영역을 우선 선택한다.
- 방 용도 변경은 런타임의 `rooms` 딕셔너리를 바꾼다. 지금은 저장/불러오기 시스템이 없으므로 앱을 재실행하면 초기 배치로 돌아간다.
- `tmp/manual_verification`은 검수용 캡처 결과이며, 일반적으로 커밋 대상이 아니다.
- `.import` 파일은 Godot가 PNG를 읽기 위해 만든 설정 파일이므로 새 PNG와 함께 커밋해야 한다.

## 추가 전투 캐릭터 축소/휠 줌/보행 영역 보정 작업

2026-07-02 추가 작업:

- 데모 체험 피드백에 따라 전투 기본 화면의 캐릭터 시각 배율을 크게 줄였다.
- 지상 유닛 기본 스프라이트 배율은 `0.42`, 임프 같은 비행 유닛은 `0.44`로 조정했다.
- 지상 유닛은 이동 중 전체 sprite bobbing을 제거해 바닥을 밟고 뛰는 느낌을 우선했고, 임프만 작은 hover bobbing을 유지한다.
- 전투 전용 `Camera2D`를 추가해 마우스 휠로 전투 지역을 `0.78~1.85` 범위에서 확대/축소할 수 있게 했다.
- 휠 줌 중에도 마우스 포인터 아래 월드 좌표가 유지되도록 카메라 위치를 보정했다.
- 전투 입력은 화면 좌표를 카메라 기준 월드 좌표로 변환해서 처리한다. 직접 이동/공격 지정은 줌 상태에서도 어긋나지 않아야 한다.
- `RoomGraph`에 보행 가능 영역 판정과 클램프를 추가했다. 방 내부 안전 마진과 방 중심 연결 통로 폭을 기준으로 캐릭터 중심점이 던전 바닥 안에 남도록 한다.
- 몬스터/적 스폰, AI 방 이동 경로, 직접 이동 명령, 함정 유도 위치, 용사 돌진 도착점, 도둑 복귀 경로를 모두 보행 가능 영역으로 보정했다.
- 축소된 캐릭터 크기에 맞춰 유닛/적 클릭 판정 반경을 `58`에서 `36`으로 줄였다.
- 적 캐릭터도 이동 중 뛰는 느낌이 나도록 `tools/generate_animation_variants.py`를 확장해 탐험가/도둑/수련생 용사의 다중 프레임을 생성했다.
- 이번 작업의 별도 작업 로그 백업은 `docs/WORK_LOG_2026-07-02_COMBAT_SCALE_ZOOM_GROUNDED.md`에 남겼다.

이번 세션에서 변경한 주요 파일:

- `scripts/units/Unit.gd`
- `scripts/game/GameRoot.gd`
- `scripts/map/RoomGraph.gd`
- `scripts/game/CombatSceneController.gd`
- `tools/generate_animation_variants.py`
- `tools/DemoSmokeTest.gd`
- `assets/sprites/enemies/enemy_explorer_*_01~03.png`
- `assets/sprites/enemies/enemy_thief_*_01~03.png`
- `assets/sprites/enemies/enemy_trainee_hero_*_01~03.png`
- `assets/sprites/enemies/*.png.import`
- `docs/HANDOFF_CURRENT_STATE_2026-07-02.md`
- `docs/WORK_LOG_2026-07-02_COMBAT_SCALE_ZOOM_GROUNDED.md`

검증한 명령과 결과:

```powershell
python tools/generate_animation_variants.py
godot --headless --import
godot --headless --path . --scene res://tools/DemoSmokeTest.tscn
godot --headless --path . --scene res://tools/BalanceSimulation.tscn
godot --path . --scene res://tools/ManualVerificationCapture.tscn
```

결과:

- PNG 파생 프레임 생성 성공
- Godot import 종료 코드 0
- `DemoSmokeTest.tscn` 종료 코드 0, `DEMO_SMOKE_TEST: PASS`
- `BalanceSimulation.tscn` 종료 코드 0, DAY1/DAY2 자동 승리, DAY3 자동 패배, DAY3 보조 승리 유지
- 일반 렌더러 수동 캡처 성공, `tmp/manual_verification/03_combat_start.png`와 `04_combat_controls.png`에서 축소 캐릭터와 바닥 배치 확인

주의:

- 테스트는 `godot --headless --path . --scene res://tools/DemoSmokeTest.tscn`으로 실행해야 한다. `--script tools/DemoSmokeTest.gd` 방식은 오토로드가 잡히지 않아 `DataRegistry`, `GameState` 미정의 오류가 난다.
- 현재 줌은 휠 줌만 있고 카메라 드래그/팬은 없다.
- 보행 영역 체감값은 `RoomGraph.gd`의 `WALKABLE_ROOM_MARGIN = 34.0`, `WALKABLE_CORRIDOR_HALF_WIDTH = 44.0`이다.

다음 세션 첫 작업:

1. 실제 플레이에서 휠 줌 감도와 최대/최소 배율이 편한지 확인.
2. 캐릭터가 작아진 뒤 선택이 어렵다면 유닛 클릭 판정을 줌 배율에 따라 보정할지 판단.
3. 통로 보행 폭이 너무 넓거나 좁으면 `RoomGraph.gd` 상수를 조정.
4. 임프 비행 이동은 유지했지만, 장기적으로 비행 유닛 전용 move frame을 따로 만들지 판단.

## 추가 쿼터뷰 소켓 연결식 모듈 맵 전환 계획

2026-07-02 추가 작업:

- 새 기준 문서 묶음 `mawang_quarterview_walkarea_update_docs/mawang_quarterview_walkarea_update_docs`를 확인했다.
- 현재까지의 작업을 오늘자 백업으로 남겼다.
- 백업 위치는 `C:\Users\LDK-6248\Desktop\AI개발\어시스트프로젝트\마왕성_backups\2026-07-02_1f7fc62_walkarea_plan`이다.
- 백업 산출물은 `mawang_git_all_2026-07-02_1f7fc62.bundle`, `mawang_source_2026-07-02_1f7fc62.zip`, `BACKUP_MANIFEST.txt`다.
- 개발 계획은 `docs/PLAN_2026-07-02_QUARTERVIEW_SOCKET_MODULE_MAP.md`에 작성했다.
- 이번 작업의 별도 작업 로그 백업은 `docs/WORK_LOG_2026-07-02_QUARTERVIEW_SOCKET_MODULE_PLAN.md`에 남겼다.

핵심 결정:

- 기존 `rooms.json + RoomGraph + DungeonRenderer`를 즉시 삭제하지 않는다.
- 새 `ModuleGraph + DungeonWalkMap + QuarterDungeonRenderer`를 병렬로 만든 뒤 기능 플래그로 전환한다.
- 초기에는 `room_id == module_instance_id` 호환 규칙을 유지해 기존 전투/방 지침/몬스터 배치를 덜 흔든다.
- 소켓은 연결 검사용이고, 실제 이동 가능 여부는 `walk_cells`, `block_cells`, `prop_block_cells`, `socket_entry_cells` 기반 `DungeonWalkMap`이 결정한다.
- 모든 이동 요청은 최종적으로 `DungeonWalkMap.get_path_world()`를 통과해야 한다.

다음 구현 턴 첫 작업:

1. `data/dungeon_quarter/modules.json`와 `data/dungeon_quarter/starting_layout.json` 초안 작성.
2. `scripts/dungeon_quarter/IsoMath.gd`, `PlacedModule.gd`, `ModuleGraph.gd`, `SocketValidator.gd`, `DungeonWalkMap.gd` 생성.
3. `QuarterDungeonSmokeTest.tscn`으로 입구→왕좌, 입구→보물 경로와 walkable 보정을 먼저 검증.
4. 그 다음 placeholder 쿼터뷰 렌더러와 F1/F2/F3/F7/F8 디버그 오버레이를 붙인다.

## 추가 쿼터뷰 모듈 맵 Phase 1 구현 완료

2026-07-02 추가 구현:

- `data/dungeon_quarter/modules.json`와 `starting_layout.json` 초안 작성 완료.
- `scripts/dungeon_quarter/`에 `IsoMath`, `PlacedModule`, `DungeonModuleRegistry`, `SocketValidator`, `DungeonWalkMap`, `ModuleGraph` 추가.
- `DataRegistry`에서 쿼터뷰 모듈/레이아웃 데이터를 로딩한다.
- `GameRoot.use_quarter_module_map` 기본값을 `true`로 두고, 데이터가 있으면 `ModuleGraph`를 사용한다.
- `ModuleGraph`는 기존 `RoomGraph` 호환 API인 `center`, `rect`, `exits`, `path_between`, `path_points`, `is_walkable`, `clamp_to_walkable`, `closest_room`를 제공한다.
- 전투 점 이동과 직접 공격 접근은 `path_to_point()` 경로를 사용할 수 있게 연결했다.
- 전용 테스트 `tools/QuarterModuleSmokeTest.tscn` 추가.
- 작업 로그는 `docs/WORK_LOG_2026-07-02_QUARTERVIEW_MODULE_PHASE1.md`에 남겼다.

검증:

```powershell
godot --headless --path . --import
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
```

결과:

- `QuarterModuleSmokeTest.tscn` PASS
- `DemoSmokeTest.tscn` PASS

다음 세션 첫 작업:

1. `QuarterDungeonRenderer` 또는 placeholder 쿼터뷰 모듈 렌더러를 추가한다.
2. 현재 `DungeonWalkMap`은 기존 방 rect/corridor 기반이므로, 실제 쿼터뷰 렌더러 단계에서 `walk_cells/block_cells/prop_block_cells` 전역 셀 병합 기반으로 전환한다.
3. F3 walkable, F7 blocked, F8 selected cell 디버그 오버레이를 추가한다.
4. 그 다음 소켓 교체/건설 UI를 붙인다.

## 추가 쿼터뷰 디버그 렌더러 구현 완료

2026-07-02 추가 구현:

- `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` 추가.
- 기존 `DungeonRenderer`는 유지하고, 별도 overlay 렌더러로 쿼터뷰 모듈 디버그 표시를 얹었다.
- 모든 디버그 overlay는 기본 OFF라 일반 플레이 화면을 덮지 않는다.
- F1: 소켓 연결 표시.
- F2: 모듈 placeholder 외곽선 표시.
- F3: 보행 가능 셀 표시.
- F7: 차단 셀 표시.
- F8: 현재 커서 셀 표시.
- `DungeonWalkMap`과 `ModuleGraph`에 렌더러/디버그용 조회 API를 추가했다.
- `tools/QuarterModuleSmokeTest.gd`가 overlay 토글과 redraw 호출까지 확인한다.
- 작업 로그는 `docs/WORK_LOG_2026-07-02_QUARTERVIEW_DEBUG_RENDERER.md`에 남겼다.

검증:

```powershell
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --headless --path . --run res://tools/BalanceSimulation.tscn
godot --path . --run res://tools/ManualVerificationCapture.tscn
```

결과:

- `QuarterModuleSmokeTest.tscn` PASS
- `DemoSmokeTest.tscn` PASS
- 일반 렌더러 캡처 성공

다음 세션 첫 작업:

1. `DungeonWalkMap`을 현재 legacy room rect 기반에서 `walk_cells/block_cells/prop_block_cells` 기반 전역 셀 병합으로 전환한다.
2. F3/F7 overlay로 실제 모듈 데이터의 보행/차단 셀이 화면과 맞는지 검증한다.
3. 그 다음 쿼터뷰 그래픽 리소스를 제작한다. 즉, 그래픽 리소스 제작은 지금 단계 이후가 맞다.

## 추가 쿼터뷰 보행맵 모듈 셀 전환 완료

2026-07-02 추가 구현:

- `DungeonWalkMap.rebuild_from_modules()`를 추가했다.
- `ModuleGraph`가 더 이상 `rebuild_from_legacy_rooms()`를 쓰지 않고, 모듈 데이터 기반 `rebuild_from_modules()`를 호출한다.
- 배치된 모듈의 `walk_cells`를 전역 보행 셀로 병합한다.
- `block_cells`, `prop_block_cells`를 전역 차단 셀로 병합한다.
- `socket_entry_cells`와 `starting_layout.connections`를 이용해 모듈 사이 연결부를 보행 셀로 생성한다.
- 현재 레이아웃은 `legacy_world_grid`이므로 모듈 local cell을 기존 room rect 내부에 투영한다. 화면 호환을 유지하면서 이동 판정의 원천만 모듈 셀 데이터로 옮긴 상태다.
- `QuarterModuleSmokeTest`가 `debug_source_mode() == "module_cells"`와 block cell 비보행 처리를 검증한다.
- 작업 로그는 `docs/WORK_LOG_2026-07-02_QUARTERVIEW_WALKMAP_MODULE_CELLS.md`에 남겼다.

검증:

```powershell
godot --headless --path . --import
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
```

결과:

- `QuarterModuleSmokeTest.tscn` PASS
- `DemoSmokeTest.tscn` PASS

## 추가 쿼터뷰 모듈 이미지 리소스 제작 완료

2026-07-02 추가 작업:

- 현재 8개 쿼터뷰 소켓 모듈에 대한 GPT Image 2 프롬프트를 준비했다.
- 프롬프트 파일은 `tools/imagegen/quarter_modules_gpt_image2_prompts.jsonl`에 있다.
- 생성/후처리 실행법은 `tools/imagegen/README_QUARTER_MODULES.md`에 정리했다.
- 최종 리소스 대상 폴더와 파일명은 `assets/sprites/dungeon_quarter/modules/SOURCE.md`에 남겼다.
- 각 프롬프트에는 `starting_layout.json`의 연결 규칙을 반영했다. 연결된 소켓은 열린 문으로, 연결되지 않은 쪽은 벽/암석/기둥/잔해로 막히도록 명시했다.
- 처음에는 API/CLI `gpt-image-2` 경로로 해석해서 `OPENAI_API_KEY` 부재로 막혔지만, 사용자가 의도한 경로가 내부 GPT 이미지 생성 툴임을 확인한 뒤 내부 생성 툴로 실제 PNG를 생성했다.
- 생성된 chroma 원본은 `output/imagegen/quarter_modules/source/`에 복사했다.
- 최종 alpha PNG 8개는 `assets/sprites/dungeon_quarter/modules/`에 저장했다.
- 8개 최종 PNG는 모두 `RGBA`이고 좌상단 alpha가 0임을 확인했다.
- 육안 확인용 contact sheet는 `output/imagegen/quarter_modules/contact_sheet.png`에 저장했다.
- Godot import, `QuarterModuleSmokeTest.tscn`, `DemoSmokeTest.tscn`를 통과했다.
- 로컬 참고문서 패키지 `mawang_quarterview_walkarea_update_docs/` 안에는 `class_name DungeonWalkMap` 템플릿이 있어 Godot 스캔 시 프로젝트 클래스와 충돌한다. 이 워크스페이스에는 로컬 untracked `.gdignore`를 넣어 import를 통과시켰고, 해당 참고문서 폴더 자체는 커밋 대상에서 제외했다.
- 작업 로그는 `docs/WORK_LOG_2026-07-02_QUARTERVIEW_IMAGE_RESOURCE_PREP.md`에 남겼다.

다음 세션 첫 작업:

1. `QuarterDungeonRenderer`에 모듈 PNG를 실제 맵 좌표로 그리는 단계를 붙인다.
2. F3/F7 overlay로 `walk_cells/block_cells/prop_block_cells`와 실제 바닥/벽/장식 위치를 맞춘다.
3. 필요하면 시각적으로 애매한 소켓이 있는 단일 모듈만 재생성한다.
4. 그래픽 리소스가 안정되면 `legacy_world_grid` 투영을 실제 쿼터뷰 모듈 월드 좌표로 전환한다.

## 추가 쿼터뷰 모듈 시각 렌더러 연결

2026-07-02 추가 작업:

- `QuarterDungeonRenderer`가 이제 `assets/sprites/dungeon_quarter/modules/*_visual.png`를 실제 화면에 그린다.
- F1/F2/F3/F7/F8 디버그 오버레이는 모듈 이미지 위에 표시된다.
- 현재 연결된 소켓 조합에 따라 `module_id_visual_[open_socket_sides].png`를 먼저 찾고, 없으면 `module_id_visual.png`를 fallback으로 쓴다.
- 예: `room_entrance_01_visual_ne_se.png`, `room_treasure_01_visual_nw.png`, `room_treasure_01_visual_nw_sw.png`
- 지금 들어간 8개 이미지는 현재 데모 레이아웃 기준 기본 이미지다. 같은 방을 다른 연결 상태로 배치하려면 소켓 조합별 변형 이미지를 추가 제작해야 한다.
- 작업 로그는 `docs/WORK_LOG_2026-07-02_QUARTERVIEW_MODULE_VISUAL_RENDERER.md`에 남겼다.

검증:

```powershell
godot --headless --path . --import
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --path . --run res://tools/ManualVerificationCapture.tscn
```

결과:

- `QuarterModuleSmokeTest.tscn` PASS
- `DemoSmokeTest.tscn` PASS
- `tmp/manual_verification/01_management.png`에서 모듈 PNG가 화면에 표시되는 것을 확인했다.

다음 세션 첫 작업:

1. 실제 플레이 창에서 F1/F2/F3/F7을 켜고 소켓/보행/차단 위치가 이미지와 맞는지 확인한다.
2. 연결 상태가 바뀔 수 있는 방부터 소켓 변형 리소스를 추가 제작한다.
3. bg/fg 분리 리소스를 제작해 유닛이 앞벽/기둥에 자연스럽게 가려지도록 만든다.

## 추가 정규버전 폴더 구조 정리

2026-07-02 추가 작업:

- 첨부된 정규버전 목표 문서를 확인했다.
- 정규버전 1.0은 30일, 5챕터, 4~6시간 규모의 소규모 정규판으로 잡는다.
- 핵심 제작 방식은 웹GPT가 기획 문서를 만들고, Codex가 그 문서를 JSON과 Godot 코드로 흡수하는 구조다.
- 기존 데모 실행 경로는 깨지지 않도록 `scripts/core`, `scripts/game`, `scripts/combat`, `data/*.json`은 이동하지 않았다.
- 새 콘텐츠와 시스템이 들어갈 확장용 폴더를 추가했다.
- 정규버전 목표 요약은 `docs/regular_version/REGULAR_VERSION_TARGET_SUMMARY.md`에 정리했다.
- 정규버전 폴더 정책은 `docs/regular_version/FOLDER_STRUCTURE.md`에 정리했다.
- 웹GPT 기획 산출물 작성 위치와 형식은 `docs/design/README.md`에 정리했다.
- 작업 로그 백업은 `docs/WORK_LOG_2026-07-02_REGULAR_VERSION_STRUCTURE.md`에 남겼다.

이번 세션에서 추가/변경한 주요 위치:

- `docs/design/`
- `docs/regular_version/`
- `data/regular_version/`
- `scripts/data/`
- `scripts/systems/`
- `scenes/ui/`
- `scenes/dungeon_quarter/modules/`
- `assets/sprites/portraits/`
- `assets/sprites/items/`
- `assets/sprites/ui/icons/`
- `assets/audio/`
- `assets/vfx/`
- `tools/content/`
- `tools/tests/`
- `web_Demo/.gdignore`
- `README.md`

검증:

```powershell
godot --headless --path . --import
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
```

결과:

- Godot import 종료 코드 0
- `QuarterModuleSmokeTest.tscn` 종료 코드 0, `QUARTER_MODULE_SMOKE_TEST: PASS`
- `DemoSmokeTest.tscn` 종료 코드 0, `DEMO_SMOKE_TEST: PASS`

다음 세션 첫 작업:

1. `scripts/data`에 공통 JSON 로더/검증 유틸을 만든다.
2. 기존 Day 1~3 데모 진행을 `data/regular_version/campaign/campaign_days.json` 초안으로 옮긴다.
3. `scripts/systems/campaign`에 CampaignManager 기본 구조를 만든다.
4. 저장 데이터 스키마를 문서화한 뒤 `scripts/systems/save`에 SaveManager를 추가한다.
5. F1/F2/F3/F7 디버그로 현재 모듈 이미지와 walk/block cell이 맞는지 계속 확인한다.

## 추가 쿼터뷰 타일그리드 규칙 전환

2026-07-02 추가 작업:

- `mawang_quarterview_tilegrid_docs/mawang_quarterview_tilegrid_docs/docs`의 8개 문서를 전부 확인했다.
- 패키지 루트의 통합 스펙과 템플릿 JSON도 확인했다.
- 새 규칙에 따라 기존 "모듈당 통짜 PNG 1장" 렌더 방식을 메인 경로에서 비활성화했다.
- `data/dungeon_quarter/room_blueprints.json`을 추가해 방/복도를 `floor_cells`, `walk_cells`, `blocked_cells`, `sockets`, `object_slots` 기반 Blueprint로 정의했다.
- `starting_layout.json`을 F급 8×8 `tile_grid` 좌표 기준으로 변경했다.
- `tile_variant_manifest.json`에 floor mask 0~15를 모두 정의했다.
- `castle_grade_rules.json`에 F 8×8부터 A 18×18까지 등급별 grid/theme/slot 규칙을 추가했다.
- `asset_manifest.json`에 prop/trap footprint와 block cell 구조를 추가했다.
- `AutoTileMask.gd`를 추가해 NW=1, NE=2, SE=4, SW=8 기준 4방향 마스크를 계산한다.
- `QuarterDungeonRenderer.gd`는 이제 모듈 PNG를 로드하지 않고, Blueprint 셀을 절차적 다이아몬드 타일로 그린다.
- `GameRoot.gd`는 쿼터뷰 모드에서 기존 `DungeonRenderer` 배경을 그리지 않는다.
- F3 walkable, F4 floor mask, F5 socket, F6 room id, F7 blocked, F8 selected unit/cursor cell, F9 path 디버그를 사용할 수 있다.
- `UnitYSortLayer` 이름과 y-sort 활성화를 추가했다.
- 작업 로그 백업은 `docs/WORK_LOG_2026-07-02_TILEGRID_CONVERSION.md`에 남겼다.

중요한 현재 상태:

- 실제 GPT Image 타일 PNG는 아직 만들지 않았다.
- 지금 화면에 보이는 타일은 새 규칙 검증용 절차적 placeholder다.
- 다음 리소스 단계에서는 방 전체 이미지가 아니라 `assets/tiles`와 `assets/props` 아래의 개별 floor/edge/wall/door/prop 이미지를 만들어야 한다.
- `assets/sprites/dungeon_quarter/modules/*_visual.png` 파일은 저장소에 남아 있지만, 메인 쿼터뷰 렌더 경로에서는 더 이상 사용하지 않는다.

검증:

```powershell
godot --headless --path . --import
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --path . --run res://tools/ManualVerificationCapture.tscn
```

결과:

- Godot import 종료 코드 0
- `QuarterModuleSmokeTest.tscn` 종료 코드 0, `QUARTER_MODULE_SMOKE_TEST: PASS`
- `DemoSmokeTest.tscn` 종료 코드 0, `DEMO_SMOKE_TEST: PASS`
- `BalanceSimulation.tscn`은 120초 제한에서는 종료 전 timeout, 240초 제한에서는 정상 완료
- 밸런스 흐름은 DAY1/DAY2 자동 승리, DAY3 자동 패배, DAY3 보조 승리 유지
- 수동 검증 캡처 생성 성공

다음 세션 첫 작업:

1. GPT Image로 `floor_cave_f_mask_00~15`의 실제 PNG 또는 중심 타일+edge/코너 오버레이 원본을 제작한다.
2. `assets/tiles/cave_f/*`와 `assets/props/*`에 실제 리소스를 넣고 `tile_variant_manifest.json`, `asset_manifest.json`을 연결한다.
3. 현재 절차적 타일 렌더를 실제 타일 PNG 렌더로 교체한다.
4. 큰 소품은 back/front 분리 이미지로 제작해 유닛 앞뒤 정렬을 개선한다.

## 추가 Cave F 바닥 타일 리소스 제작

2026-07-02 추가 작업:

- GPT 이미지 생성으로 `cave_f` 쿼터뷰 동굴 석재 바닥 타일 시트를 만들었다.
- 원본은 `assets/tiles/cave_f/floor/gpt2_floor_cave_f_source_atlas.png`에 보관했다.
- `tile_variant_manifest.json`의 `floor_mask` 항목에 맞춰 `floor_cave_f_mask_00.png`부터 `floor_cave_f_mask_15.png`까지 16개 실제 PNG를 추가했다.
- 각 타일은 `128x64` 크기이며, `AutoTileMask.gd`의 `NW=1`, `NE=2`, `SE=4`, `SW=8` 연결 규칙을 따른다.
- 아직 `QuarterDungeonRenderer.gd`가 이 PNG들을 화면에 직접 그리지는 않는다. 이번 작업은 실제 리소스 준비 단계다.
- 출처와 후처리 규칙은 `assets/tiles/cave_f/floor/SOURCE.md`에 정리했다.
- 작업 로그는 `docs/WORK_LOG_2026-07-02_CAVE_FLOOR_TILE_ASSETS.md`에 정리했다.

검증:

```powershell
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --headless --path . --import
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --headless --path . --run res://tools/DemoSmokeTest.tscn
```

결과:

- Godot import 종료 코드 0
- `QuarterModuleSmokeTest.tscn` 종료 코드 0, `QUARTER_MODULE_SMOKE_TEST: PASS`
- `DemoSmokeTest.tscn` 종료 코드 0

다음 세션 첫 작업:

1. `QuarterDungeonRenderer.gd`에서 `tile_variant_manifest.json`을 통해 `floor_cave_f_mask_00~15.png`를 로드한다.
2. `_draw_floor_layer()`의 임시 다각형 바닥을 실제 바닥 PNG 렌더링으로 교체한다.
3. F4 마스크 디버그를 켜고, 화면의 실제 타일 연결 상태와 마스크 숫자가 맞는지 확인한다.
4. 이후 같은 방식으로 벽, 문, 가장자리, 장식품 리소스를 만든다.

## 추가 Cave F 바닥 타일 렌더러 연결

2026-07-02 추가 작업:

- `QuarterDungeonRenderer.gd`가 `tile_variant_manifest.json`의 `floor_mask` 항목을 읽어 실제 바닥 PNG를 로드하게 했다.
- `floor_cave_f_mask_00.png`부터 `floor_cave_f_mask_15.png`까지 16개 텍스처를 캐시한다.
- `_draw_floor_layer()`의 임시 다각형 바닥을 실제 PNG 렌더링으로 교체했다.
- 텍스처가 없을 때는 기존 placeholder 바닥으로 fallback한다.
- 기존 모듈 통짜 PNG 경로는 계속 사용하지 않는다.
- `QuarterModuleSmokeTest.gd`에 바닥 타일 16개 로딩과 누락 마스크 없음 검증을 추가했다.
- 작업 로그는 `docs/WORK_LOG_2026-07-02_CAVE_FLOOR_TILE_RENDERER.md`에 정리했다.

검증:

```powershell
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --headless --path . --run res://tools/DemoSmokeTest.tscn
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --path . --run res://tools/ManualVerificationCapture.tscn
```

결과:

- `QuarterModuleSmokeTest.tscn` 종료 코드 0, `QUARTER_MODULE_SMOKE_TEST: PASS`
- `DemoSmokeTest.tscn` 종료 코드 0
- 수동 검증 캡처 생성 성공
- `tmp/manual_verification/01_management.png`에서 실제 바닥 타일 PNG 표시 확인

다음 세션 첫 작업:

1. GPT 이미지 생성으로 `edge`, `wall`, `door`, `overlay`용 실제 PNG를 제작한다.
2. 앞벽/뒤벽을 분리해 유닛 앞뒤 정렬을 개선한다.
3. `asset_manifest.json` 기준으로 함정/장식 prop 리소스를 제작한다.
4. 이후 필요하면 현재 legacy room rect 기반 투영을 실제 8×8 쿼터뷰 그리드 좌표로 더 정교하게 옮긴다.
