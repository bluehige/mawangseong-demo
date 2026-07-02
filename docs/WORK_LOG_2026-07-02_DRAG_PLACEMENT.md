# 작업 로그 백업 - 몬스터 드래그 배치

작성일: 2026-07-02

## 요청

기존 흐름은 원하는 방을 클릭한 뒤 몬스터 탭으로 들어가 `배치` 버튼을 눌러야 했다. 이를 관리 화면에서 보이는 몬스터를 직접 드래그해 원하는 방으로 옮기면 배치되도록 바꾸고, 몬스터 탭은 별도 관리 페이지로 남겨 달라는 요청이었다.

## 구현 방향

- 관리 화면의 방 위에 이미 표시되는 몬스터 프리뷰를 드래그 시작점으로 사용했다.
- 드래그 중인 몬스터는 원래 위치 프리뷰를 숨기고, 마우스 위치에 반투명 고스트를 그린다.
- 드롭 가능한 방은 노란색, 드롭 불가 방은 붉은색으로 하이라이트한다.
- 드롭 시 기존 배치 규칙을 재사용한다.
  - 비어 있는 건설 슬롯에는 배치 불가
  - 방의 최대 배치 수를 초과하면 배치 불가
  - 같은 방에 다시 놓으면 불필요한 로그 없이 선택만 갱신
- 몬스터 관리 화면은 훈련/정보 중심으로 분리하고 기존 배치 버튼을 제거했다.

## 변경 파일

- `scripts/game/GameRoot.gd`
  - 관리 화면 전용 드래그 상태 추가
  - 마우스 press/motion/release 기반 드래그 배치 처리 추가
  - `_assign_monster_to_room()` 추가로 기존 배치 규칙 재사용
  - 드래그 고스트와 드롭 대상 하이라이트 렌더링 추가
- `scripts/map/DungeonRenderer.gd`
  - 드래그 중인 몬스터의 원래 위치 프리뷰 숨김
- `scripts/game/ManagementSceneController.gd`
  - 관리 화면 버튼 이름을 `몬스터 관리`로 변경
  - 관리 화면 하단 안내 문구를 드래그 배치 기준으로 변경
  - 몬스터 관리 화면의 `배치`, `선택 방 배치` 버튼 제거
- `tools/DemoSmokeTest.gd`
  - 관리 화면 몬스터 드래그 시작 검증 추가
  - 드래그로 몬스터 방 배치 검증 추가
- `docs/HANDOFF_CURRENT_STATE_2026-07-02.md`
  - 최신 변경 내용, 검증 결과, 다음 작업 우선순위 업데이트

## 검증 로그

```powershell
godot --headless --path . --import
```

결과:

```text
성공
```

```powershell
godot --headless --path . --scene res://tools/DemoSmokeTest.tscn
```

결과:

```text
PASS: 관리 화면 몬스터 드래그 시작
PASS: 드래그로 몬스터 방 배치
DEMO_SMOKE_TEST: PASS
```

```powershell
godot --path . --scene res://tools/ManualVerificationCapture.tscn
```

결과:

```text
tmp/manual_verification/01_management.png
tmp/manual_verification/02_monster.png
tmp/manual_verification/03_combat_start.png
tmp/manual_verification/04_combat_controls.png
tmp/manual_verification/05_result.png
```

## 시각 검수 메모

- 관리 화면 하단에 `몬스터 관리` 버튼과 드래그 배치 안내가 보인다.
- 몬스터 관리 화면에는 배치 버튼이 남아 있지 않고, 훈련 버튼과 배치 방식 안내만 보인다.
- 자동 캡처는 드래그 중 순간을 찍지는 않지만, 스모크 테스트에서 드래그 상태 시작과 드롭 배치를 검증한다.

## 남은 리스크

- 실제 마우스로 오래 플레이했을 때 드래그 시작 판정 반경이 적당한지는 추가 체감 검수가 필요하다.
- 배치 실패 로그는 현재 전투 로그 패널처럼 항상 화면에 노출되는 구조가 아니다. 드래그 중 붉은색 하이라이트가 1차 피드백이다.
- 이후 몬스터 수가 늘어나면 방 위 프리뷰가 겹칠 수 있으므로 별도 대기열 UI나 접힘 표현이 필요할 수 있다.

## 다음 권장 작업

1. 실제 플레이로 드래그 시작, 드롭, 실패 피드백을 확인한다.
2. 건설 슬롯을 시설로 바꾼 뒤 그 방에 드롭 배치가 자연스럽게 되는지 확인한다.
3. 배치 실패 메시지를 관리 화면에도 짧게 보여줄지 결정한다.
