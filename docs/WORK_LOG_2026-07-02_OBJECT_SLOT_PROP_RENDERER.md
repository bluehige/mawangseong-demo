이 파일이 왜 필요한지: 쿼터뷰 던전의 object slot placeholder를 실제 prop/trap PNG로 교체한 변경을 다음 작업자가 이어받기 쉽게 기록한다.

# Object Slot Prop Renderer

작성일: 2026-07-02

## 작업 요약

- GPT 이미지 생성으로 쿼터뷰 던전 prop/trap atlas를 제작했다.
- atlas를 잘라 실제 prop PNG 13개를 추가했다.
- `asset_manifest.json`에 입구문, 화로, 건설 룬 prop 정의를 추가했다.
- `QuarterDungeonRenderer.gd`가 `asset_manifest.json`의 prop/trap 이미지를 로드하고 `object_slots`에 그리도록 연결했다.
- 기존 원형 placeholder는 리소스가 없을 때만 fallback으로 남겼다.
- 벽/문 렌더링도 소켓 위치에서는 겹치지 않게 조정하고, 문과 벽 크기/투명도를 줄여 시야를 개선했다.

## 추가된 리소스

```text
assets/props/gpt2_dungeon_props_source_atlas.png
assets/props/gate/prop_entrance_gate_f_back.png
assets/props/decor/prop_small_brazier_back.png
assets/props/throne/prop_throne_f_back.png
assets/props/throne/prop_throne_f_front.png
assets/props/treasure/prop_treasure_pile_large_front.png
assets/props/barracks/prop_weapon_rack_cave_f_back.png
assets/props/recovery/prop_recovery_nest_f_front.png
assets/props/build/prop_foundation_marks_back.png
assets/props/traps/trap_spike_idle_00.png
assets/props/traps/trap_spike_trigger_00.png
assets/props/traps/trap_spike_trigger_01.png
assets/props/traps/trap_spike_trigger_02.png
assets/props/traps/trap_spike_trigger_03.png
```

## 코드 변경

- `QuarterDungeonRenderer.gd`
  - object sprite 캐시와 누락 파일 목록 추가.
  - prop/trap manifest 로딩 추가.
  - object slot의 footprint를 반영해 2칸짜리 prop이 한 칸으로 줄어들지 않게 처리.
  - prop별 렌더링 크기와 바닥 정렬 보정 추가.
  - 소켓 위치에서는 edge/wall 장식이 겹치지 않게 처리.
- `QuarterModuleSmokeTest.gd`
  - prop/trap 텍스처 로딩 검증 추가.
- `asset_manifest.json`
  - `entrance_gate_f`, `small_brazier`, `foundation_marks` 추가.

## 검증

```powershell
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --headless --path . --import
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --headless --path . --run res://tools/DemoSmokeTest.tscn
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --path . --run res://tools/ManualVerificationCapture.tscn
```

결과:

- Godot import 성공
- `QuarterModuleSmokeTest.tscn` PASS
- `DemoSmokeTest.tscn` 종료 코드 0
- `ManualVerificationCapture.tscn` 종료 코드 0
- 관리 화면과 전투 시작 화면에서 입구문, 왕좌, 보물, 무기거치대, 회복둥지, 화로, 함정 표시 확인

## 남은 작업

1. trap trigger 애니메이션을 전투 이벤트와 연결한다.
2. front/back prop 분리 정렬을 더 세밀하게 다듬는다.
3. 소품이 유닛과 겹치는 지점을 실제 플레이로 확인하고 필요하면 prop별 offset을 추가한다.
