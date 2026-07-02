이 파일이 왜 필요한지: 2026-07-02 전투 중 맵 바닥 클릭이 방 선택으로 처리되던 문제를 수정한 과정, 판단 근거, 검증 결과를 핸드오프와 별도로 백업한다.

# 작업 로그: 전투 맵 방 선택 비활성화

작성일: 2026-07-02

## 요청

- 전투 중 바닥을 클릭하려고 할 때 방이 선택되는 현상이 발생.
- 전투 중에는 맵 클릭으로 방을 선택하는 의미가 낮음.
- 방별 전투 지침은 옆 방 목록에서 충분히 선택 가능하므로, 전투 시 맵 위 방 선택 UI는 숨기고 선택되지 않게 수정.

## 확인한 문제

- `scripts/game/GameRoot.gd`의 `_handle_left_click()`이 전투 화면에서도 유닛을 찾지 못하면 `_room_at(point)`으로 방을 선택했다.
- 방 클릭 영역은 `data/rooms.json`의 `rect` 기준이라 실제 바닥 이동/유닛 선택 의도와 겹칠 수 있었다.
- `scripts/map/DungeonRenderer.gd`는 전투 화면에서도 방 선택 테두리, 방 용도 마커, 방 라벨을 낮은 투명도로 계속 그리고 있었다.

## 구현 내용

- `scripts/game/GameRoot.gd`
  - 전투 화면 좌클릭은 유닛 선택만 처리하고 즉시 반환하도록 변경.
  - 유닛이 없는 바닥을 클릭해도 `_room_at()`을 호출하지 않으므로 `selected_room`이 바뀌지 않는다.
  - 관리 화면에서는 기존처럼 맵 방 클릭 선택을 유지한다.

- `scripts/map/DungeonRenderer.gd`
  - 연결형 던전 맵을 사용하는 전투 화면에서는 방 인터랙션 오버레이, 방 용도 마커, 방 라벨을 그리지 않도록 변경.
  - 전투 화면에서 `_draw_room_selection()`, `_draw_room_props()`, `_draw_room_labels()`, `_draw_room_interaction_overlays()`가 조기 반환하도록 방어 로직을 추가.
  - 왼쪽 방 목록 UI는 그대로 유지해 방별 지침 변경 경로는 보존했다.

- `tools/DemoSmokeTest.gd`
  - 전투 시작 후 빈 방 바닥을 좌클릭해도 `selected_room`이 바뀌지 않는 검증을 추가.

## 검증 결과

명령:

```powershell
godot --headless --path . --scene res://tools/DemoSmokeTest.tscn
```

결과:

- 종료 코드 0
- `DEMO_SMOKE_TEST: PASS`
- 추가 검증 통과:
  - 전투 중 맵 바닥 클릭은 방 선택하지 않음

명령:

```powershell
godot --headless --path . --import
```

결과:

- 종료 코드 0

명령:

```powershell
godot --path . --scene res://tools/ManualVerificationCapture.tscn
```

결과:

- 종료 코드 0
- `tmp/manual_verification/03_combat_start.png`, `04_combat_controls.png` 기준 전투 맵 위 방 마커/방 라벨/방 선택 테두리가 사라진 것을 확인.
- 왼쪽 방 목록은 남아 있어 방 지침 선택 경로는 유지됨.

참고:

- `godot --headless --path . --scene res://tools/ManualVerificationCapture.tscn`는 dummy 렌더러에서 뷰포트 텍스처가 null로 떨어져 캡처 저장이 실패했다. 캡처 검증은 일반 렌더러로 실행해야 한다.

## 남은 판단 사항

- 실제 플레이에서 왼쪽 방 목록과 하단 `방 지침` 버튼의 관계가 충분히 명확한지 확인.
- 필요하면 왼쪽 방 목록 제목을 `시설 배치`에서 전투 화면 전용 `방 지침 선택`으로 바꿔 전투 중 목적을 더 분명하게 만들 수 있다.
- 전투 중 맵에서 방 시각 정보를 모두 숨겼으므로, 플레이어가 현재 방 이름을 알아야 하는 순간은 유닛 상태 패널과 왼쪽 방 목록으로 보완한다.
