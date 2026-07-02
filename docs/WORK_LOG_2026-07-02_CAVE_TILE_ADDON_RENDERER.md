이 파일이 왜 필요한지: `cave_f` 던전 타일의 가장자리, 벽, 문, 코너 장식 리소스 제작과 렌더러 연결 내용을 다음 작업자가 바로 이어받을 수 있게 기록한다.

# Cave F Tile Add-On Renderer

작성일: 2026-07-02

## 작업 요약

- GPT 이미지 생성 결과를 사용해 `edge`, `overlay`, `wall`, `door`용 실제 PNG 16개를 제작했다.
- 초록 배경은 투명 alpha로 제거했다.
- 생성 원본 atlas를 `assets/tiles/cave_f/gpt2_cave_f_addon_source_atlas.png`에 보존했다.
- `data/dungeon_quarter/tile_variant_manifest.json`에 `edges` 항목을 추가하고, 기존 `corner_overlays`, `walls`, `doors` 항목과 함께 실제 파일을 연결했다.
- `QuarterDungeonRenderer.gd`가 add-on 텍스처 16개를 로드하고 화면에 그리도록 연결했다.
- 기존 선/단색 placeholder보다 던전 내부처럼 보이도록 가장자리, 벽, 문 아치, 코너 석재를 실제 PNG로 렌더링한다.

## 추가된 리소스

```text
assets/tiles/cave_f/edge/edge_cave_f_nw_lip.png
assets/tiles/cave_f/edge/edge_cave_f_ne_lip.png
assets/tiles/cave_f/edge/edge_cave_f_se_lip.png
assets/tiles/cave_f/edge/edge_cave_f_sw_lip.png
assets/tiles/cave_f/overlay/floor_cave_f_corner_inner_nw.png
assets/tiles/cave_f/overlay/floor_cave_f_corner_inner_ne.png
assets/tiles/cave_f/overlay/floor_cave_f_corner_inner_se.png
assets/tiles/cave_f/overlay/floor_cave_f_corner_inner_sw.png
assets/tiles/cave_f/overlay/floor_cave_f_corner_outer_nw.png
assets/tiles/cave_f/overlay/floor_cave_f_corner_outer_ne.png
assets/tiles/cave_f/overlay/floor_cave_f_corner_outer_se.png
assets/tiles/cave_f/overlay/floor_cave_f_corner_outer_sw.png
assets/tiles/cave_f/wall/wall_cave_f_ne_straight_00.png
assets/tiles/cave_f/wall/wall_cave_f_nw_straight_00.png
assets/tiles/cave_f/door/door_cave_f_ne_open.png
assets/tiles/cave_f/door/door_cave_f_nw_open.png
```

## 코드 변경

- `QuarterDungeonRenderer.gd`
  - `edge_tile_textures`, `corner_overlay_textures`, `wall_tile_textures`, `door_tile_textures` 캐시 추가.
  - `tile_variant_manifest.json`에서 add-on 파일을 로드.
  - 노출된 바닥 가장자리에는 `edge` PNG를 그림.
  - 볼록/오목 코너에는 `overlay` PNG를 그림.
  - 뒤쪽 벽에는 `wall` PNG를 그림.
  - NE/NW 연결 소켓에는 `door` PNG를 그림.
- `QuarterModuleSmokeTest.gd`
  - add-on 텍스처 16개 로딩과 누락 파일 없음 검증 추가.

## 검증

```powershell
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --headless --path . --import
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --headless --path . --run res://tools/DemoSmokeTest.tscn
& 'C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe' --path . --run res://tools/ManualVerificationCapture.tscn
```

결과:

- Godot import 종료 코드 0
- `QuarterModuleSmokeTest.tscn` PASS
- `DemoSmokeTest.tscn` 종료 코드 0
- `ManualVerificationCapture.tscn` 종료 코드 0
- `tmp/manual_verification/01_management.png`, `03_combat_start.png`에서 실제 벽/문/가장자리 PNG 표시 확인

## 남은 조정

1. 문 아치 위치가 일부 연결부에서 과하게 커 보일 수 있어 실제 플레이 창에서 크기와 위치를 미세조정한다.
2. 벽 밀도가 다소 높게 보이는 구간이 있어 앞/뒤 벽 분리 규칙을 다듬는다.
3. 이후 prop 리소스가 들어오면 `object_slots`도 placeholder 원형이 아니라 실제 PNG로 교체한다.
