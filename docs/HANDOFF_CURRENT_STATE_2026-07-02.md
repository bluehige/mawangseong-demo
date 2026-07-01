이 파일이 왜 필요한지: 2026-07-02 현재까지 구현한 데모 상태, 최신 수정 내용, 검증 방법, 다음 작업 우선순위를 다음 작업자가 바로 이어받을 수 있게 정리한다.

# 마왕성 데모 현재 상태 핸드오프

작성일: 2026-07-02

## 결론

현재 프로젝트는 Godot 4.5.2에서 실행 가능한 탑뷰 마왕성 방어 데모 상태다.

관리 화면에서 방과 몬스터를 확인하고, 방어 준비로 전투에 들어가며, 전투 후 결과 화면까지 이어지는 기본 플레이 루프는 연결되어 있다. 최근 작업으로 던전 배경, 방 클릭 좌표, 방 용도 표시, 전투 상태 UI, 간단한 전술 전투, 캐릭터 애니메이션 구조까지 들어갔다.

다만 상용 완성판은 아니다. 지금 기준은 "검수 가능한 데모"이며, 다음 단계는 사람이 직접 플레이하면서 재미, 템포, 가독성, 방 배치 변경 가능성을 다듬는 것이다.

## 실행 환경

- 엔진: Godot 4.5.2
- 확인한 버전 출력: `4.5.2.stable.official.6ce3de25a`
- 현재 사용 중인 실행 파일:
  `C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe`
- 프로젝트 루트:
  `C:\Users\blueh\Desktop\진행중인프로젝트\codex\마왕성`
- 원격 저장소:
  `https://github.com/bluehige/mawangseong-demo.git`

## 현재 주요 흐름

1. 실행하면 관리 화면이 열린다.
2. 던전 맵에서 방을 클릭해 선택한다.
3. 왼쪽 시설 배치 목록과 오른쪽 선택 방 정보가 갱신된다.
4. 몬스터 화면에서 슬라임, 고블린, 임프를 확인하고 배치할 수 있다.
5. `방어 준비`를 누르면 전투가 시작된다.
6. 침입자는 입구에서 등장해 왕좌 또는 보물 보관실을 목표로 이동한다.
7. 몬스터는 전체 지침과 방 지침에 따라 방어, 추격, 후퇴, 함정 유도 등을 수행한다.
8. 전투 중 유닛 상태 UI에서 아군과 침입자의 체력, 행동 상태, 목표를 확인할 수 있다.
9. 유닛 선택 후 직접 조종, 스킬 입력, AI 복귀를 사용할 수 있다.
10. 전투가 끝나면 결과 화면으로 넘어간다.

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

현재는 1프레임 중심이라 움직임은 제한적이다. 하지만 구조는 프레임을 늘릴 수 있게 준비되어 있다.

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

## 검증 방법

Godot import:

```powershell
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --headless --path . --import
```

자동 스모크 테스트:

```powershell
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --headless --path . --scene res://tools/DemoSmokeTest.tscn
```

수동 검증 캡처:

```powershell
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --path . --scene res://tools/ManualVerificationCapture.tscn
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

## 이어서 볼 주요 파일

- `data/rooms.json`: 방 위치, 방 연결, 방 용도, 아이콘 설정
- `scripts/map/DungeonRenderer.gd`: 던전 배경, 방 영역, 방 아이콘, 라벨 렌더링
- `scripts/ui/HUDController.gd`: 관리/전투 UI 패널과 버튼
- `scripts/game/GameRoot.gd`: 전체 상태, 입력, 씬 전환
- `scripts/game/CombatSceneController.gd`: 전투 흐름, AI, 스킬, 보상
- `scripts/units/Unit.gd`: 유닛 상태, 이동, 애니메이션

## 다음 작업 우선순위

1. 실제 플레이로 관리 화면 클릭감과 전투 HUD 조작감을 검수
2. 방 용도 변경 시스템 설계
   - 예: 보물 보관실을 다른 방으로 옮기기
   - 예: 건설 슬롯에 다른 시설을 짓기
3. 방 아이콘을 더 작고 상징적인 게임 UI 마커로 추가 개선할지 판단
4. 전투에서 방 지침과 몬스터 행동의 체감 차이를 더 크게 만들기
5. 캐릭터 애니메이션을 2프레임 이상으로 늘려 이동/공격/스킬 동작을 더 분명하게 만들기
6. UI 검수
   - 텍스트 넘침
   - 버튼 클릭 범위
   - 전투 중 유닛과 패널 겹침
7. 밸런스 검수
   - 1일차 쉬움
   - 2일차 압박
   - 3일차 데모 보스 느낌

## 주의할 점

- 현재 던전 배경은 이미지 한 장이지만, 방 용도 표시는 분리했다. 배경 자체의 방 구조를 바꾸면 `rooms.json` 좌표도 같이 바꿔야 한다.
- `rect`는 클릭 영역이고, `center`는 유닛 배치와 이동 목표 기준이다.
- 작은 방과 큰 방 영역이 겹칠 수 있어서 `_room_at()`은 작은 영역을 우선 선택한다.
- `tmp/manual_verification`은 검수용 캡처 결과이며, 일반적으로 커밋 대상이 아니다.
- `.import` 파일은 Godot가 PNG를 읽기 위해 만든 설정 파일이므로 새 PNG와 함께 커밋해야 한다.

