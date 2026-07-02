# 작업 로그: 전투 캐릭터 축소, 휠 줌, 보행 영역 보정

작성일: 2026-07-02

## 요청

- 데모 체험 결과 맵 공간 대비 캐릭터가 너무 크게 보이는 문제를 수정.
- 캐릭터를 줄인 뒤 전투 중 마우스 휠로 전투 지역을 확대/축소 가능하게 수정.
- 임프처럼 날아다니는 캐릭터를 제외하고, 이동 중 캐릭터가 던전 바닥을 밟고 뛰는 느낌이 나도록 보강.
- 캐릭터가 던전 영역 밖으로 나가는 경우를 줄이고, 전투 기본 화면은 작게 보되 필요하면 줌으로 자세히 볼 수 있게 수정.

## 작업 전 판단

- 스프라이트 배율만 줄이면 이동 목표가 방 외곽이나 통로 밖으로 잡힐 때 여전히 벽/외부를 밟아 보일 수 있다.
- 전투 중 카메라 줌을 넣으면 입력 좌표도 카메라 줌 기준으로 월드 좌표 변환을 해야 직접 조종이 어긋나지 않는다.
- 적 캐릭터는 기존에 `_00` 단일 프레임 중심이라 몬스터보다 이동 애니메이션이 부족했다. 같은 생성 스크립트로 적 프레임도 확장하는 쪽이 안정적이다.

## 구현 내용

- `scripts/units/Unit.gd`
  - 기본 지상 유닛 시각 배율을 `0.42`, 임프 같은 비행 유닛 배율을 `0.44`로 축소.
  - 지상 유닛은 이동 중 전체 스프라이트 bobbing을 제거하고 발 위치 기준으로 고정.
  - 비행 유닛(`imp`)만 이동 중 작은 hover bobbing을 유지.
  - 선택 링, 보호막 링, HP바, 이름 라벨을 축소된 캐릭터 기준으로 조정.
  - 유닛 충돌 우회 detour 좌표와 실제 위치를 던전 보행 영역 안으로 보정.

- `scripts/game/GameRoot.gd`
  - 전투 전용 `Camera2D`를 추가.
  - 전투 중 휠 업/다운으로 `0.78~1.85` 범위 줌 가능.
  - 줌 시 마우스 포인터 아래 월드 좌표가 유지되도록 카메라 위치를 보정.
  - 전투 화면 입력은 화면 좌표를 전투 카메라 월드 좌표로 변환해 처리.
  - 축소된 캐릭터에 맞춰 유닛/적 클릭 판정 반경을 `58`에서 `36`으로 축소.

- `scripts/map/RoomGraph.gd`
  - `is_walkable()`과 `clamp_to_walkable()` 추가.
  - 방 내부는 벽/가장자리에 붙지 않도록 안전 마진을 두고, 방 중심 연결 통로는 일정 폭 안에서 보행 가능하게 처리.
  - `Rect2.get_closest_point()` 의존 대신 직접 클램프 함수를 사용해 Godot API 차이 리스크를 제거.

- `scripts/game/CombatSceneController.gd`
  - 전투 시작 시 줌 상태를 초기화.
  - 몬스터/적 스폰 좌표, 방 이동 경로, 직접 포인트 이동, 함정 유도 위치, 용사 돌진 도착 지점을 보행 영역 안으로 보정.
  - 도둑이 보물 훔친 뒤 입구로 복귀하는 경로도 보행 영역 안으로 보정.

- `tools/generate_animation_variants.py`
  - 기존 몬스터 프레임 생성 로직을 actor 공통 함수로 정리.
  - `assets/sprites/enemies`의 탐험가/도둑/수련생 용사에도 `idle`, `move`, `attack`, `skill`, `down` 다중 프레임 생성.
  - 적 애니메이션 미리보기 시트 생성 추가.

- `tools/DemoSmokeTest.gd`
  - 캐릭터 축소 배율, 발 위치 정렬, 휠 줌 확대/축소, 던전 밖 좌표 보정, 직접 이동 명령 보정, 적 이동 다중 프레임 검증 추가.

## 생성 에셋

- `assets/sprites/enemies/enemy_explorer_*_01~03.png`
- `assets/sprites/enemies/enemy_thief_*_01~03.png`
- `assets/sprites/enemies/enemy_trainee_hero_*_01~03.png`
- 각 신규 PNG에 대한 Godot `.import` 파일
- `tmp/asset_previews/enemy_animation_variants.png`는 검증용 미리보기이며 커밋 대상은 아니다.

## 검증 결과

명령:

```powershell
python tools/generate_animation_variants.py
```

결과:

- 종료 코드 0
- 적/몬스터 애니메이션 프레임과 미리보기 시트 생성 성공

명령:

```powershell
godot --headless --import
```

결과:

- 종료 코드 0
- 신규 적 PNG `.import` 생성 성공

명령:

```powershell
godot --headless --path . --scene res://tools/DemoSmokeTest.tscn
```

결과:

- 종료 코드 0
- `DEMO_SMOKE_TEST: PASS`
- 추가 검증 통과:
  - 전투 캐릭터 스프라이트 축소
  - 캐릭터 발 위치 기준 정렬
  - 전투 휠 확대/축소
  - 던전 밖 이동 좌표 보행 영역 보정
  - 직접 이동 명령 던전 내부 보정
  - 적 이동 뛰기 애니메이션 다중 프레임

명령:

```powershell
godot --headless --path . --scene res://tools/BalanceSimulation.tscn
```

결과:

- 종료 코드 0
- DAY1_AUTO WIN, DAY2_AUTO WIN, DAY2_TRAP_DIRECTIVE WIN, DAY3_AUTO LOSS, DAY3_ASSISTED WIN
- 기존 밸런스 체크 의도 유지

명령:

```powershell
godot --path . --scene res://tools/ManualVerificationCapture.tscn
```

결과:

- 종료 코드 0
- `tmp/manual_verification/03_combat_start.png`, `04_combat_controls.png`에서 캐릭터 축소와 바닥 배치 확인

## 주의

- `godot --headless --path . --script tools/DemoSmokeTest.gd`는 오토로드가 초기화되지 않아 `DataRegistry`, `GameState` 미정의 오류가 난다. 테스트는 README 기준인 `--scene res://tools/DemoSmokeTest.tscn`으로 실행해야 한다.
- 현재 줌은 휠 줌만 지원하고, 카메라 드래그/팬은 아직 없다.
- 보행 가능 통로 폭과 방 안전 마진은 체감값이다. 플레이 테스트에서 통로가 너무 좁거나 넓으면 `RoomGraph.gd`의 `WALKABLE_ROOM_MARGIN`, `WALKABLE_CORRIDOR_HALF_WIDTH`를 조정한다.

## 남은 판단 사항

- 실제 플레이 중 줌 감도(`COMBAT_ZOOM_STEP = 1.12`)와 최대 줌(`1.85`)이 충분한지 확인.
- 캐릭터가 더 작아진 만큼 선택이 어렵다면 클릭 반경 `36`을 화면 줌에 따라 보정할지 판단.
- 임프 비행 연출은 유지했지만, 장기적으로는 비행 유닛 전용 move frame을 별도로 만들면 더 자연스럽다.
