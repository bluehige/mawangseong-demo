# 작업 로그: 가시 함정 발동 애니메이션 연결

일시: 2026-07-02

## 목표

- 가시 복도의 함정 피해가 실제 전투 이벤트로 발생할 때, 맵에 배치된 `spike_floor` 오브젝트가 idle 이미지에서 trigger 프레임 애니메이션으로 전환되게 한다.
- 테스트에서 “피해 수치만 적용됨”이 아니라 “화면 리소스의 발동 상태도 시작됨”까지 검증한다.

## 변경 사항

- `QuarterDungeonRenderer.gd`
  - `asset_manifest.json`의 trap frame 정보를 읽어 trap animation frame count를 보관한다.
  - `trigger_trap_animation(instance_id, trap_id)` API를 추가했다.
  - 발동 중인 trap은 `Time.get_ticks_msec()` 기준으로 `trap:spike_floor:trigger:00..03` 프레임을 순서대로 그린다.
  - 발동 시간이 끝난 trap은 자동으로 active 목록에서 제거되고 idle frame으로 돌아간다.
  - 테스트용 debug API를 추가했다.

- `CombatSceneController.gd`
  - 전투 시작 시 이전 trap animation 상태를 초기화한다.
  - 적이 `spike_corridor`에 들어와 실제 함정 피해와 둔화를 받을 때 `trigger_quarter_trap("spike_corridor", "spike_floor")`를 호출한다.

- `QuarterModuleSmokeTest.gd`
  - renderer가 가시 함정 발동 상태를 추적하고 trigger frame key를 선택하는지 검증한다.

- `DemoSmokeTest.gd`
  - 실제 전투 room effect 처리 후 가시 함정 발동 애니메이션이 active 상태가 되는지 검증한다.

- `ManualVerificationCapture.gd`
  - 자동 캡처에 `04_combat_trap_trigger.png`를 추가했다.
  - 캡처 흐름은 `01_management`, `02_monster`, `03_combat_start`, `04_combat_trap_trigger`, `05_combat_controls`, `06_result` 순서다.

## 검증

```powershell
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --headless --path . --run res://tools/DemoSmokeTest.tscn
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --path . --run res://tools/ManualVerificationCapture.tscn
```

결과:

- `QuarterModuleSmokeTest.tscn` PASS
- `DemoSmokeTest.tscn` 종료 코드 0
- `ManualVerificationCapture.tscn` 종료 코드 0
- `tmp/manual_verification/04_combat_trap_trigger.png`에서 가시 복도 피해 로그와 trigger 캡처 확인

## 다음 우선순위

1. prop front/back 정렬과 유닛 YSort를 더 정교하게 맞춘다.
2. 실제 플레이 캡처에서 유닛과 prop 겹침을 확인하고 prop별 offset 값을 데이터화한다.
3. 전투 핵심 재미를 더 보여주기 위해 방/통로 특성별 상호작용 이벤트를 추가한다.
