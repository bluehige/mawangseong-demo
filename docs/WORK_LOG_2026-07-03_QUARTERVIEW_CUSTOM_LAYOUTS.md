이 파일이 왜 필요한지: 이번 세션의 범위는 "맵 커스텀 완성"으로 고정되었다. 세션 압축/이관 뒤에도 기존 잘못된 맵 커스텀 구현으로 되돌아가지 않도록 v2 기준, 구현 결과, 검증 명령을 남긴다.

# 쿼터뷰 v2 맵 커스텀 작업 로그

작성일: 2026-07-03

## 결론

- 기존 맵 커스텀 데이터/구현은 보존 대상이 아니며, 참고자료 `mawang_quarterview_tilegrid_v2` 규칙을 기준으로 덮어썼다.
- 맵은 고정 `20x20` 논리 그리드를 사용한다. 성 등급 확장은 배열 크기 변경이 아니라 `active_rect` 확장이다.
- 방/통로/오브젝트/함정/소켓/보행은 모두 `CellData` 기반으로 계산한다.
- 배경 이미지는 분위기/void 표현일 뿐이며, 연결/이동/마스크 판정에 관여하지 않는다.
- 관리 화면에서 등록된 커스텀 레이아웃을 선택할 수 있고, 선택 즉시 `ModuleGraph`와 `QuarterDungeonRenderer`가 갱신된다.

## 주요 구현

- 데이터
  - `data/dungeon_quarter/castle_grade_rules.json`
    - `max_grid_size: [20, 20]`
    - F~S 등급별 `active_rect`
  - `data/dungeon_quarter/room_blueprints.json`
    - v2 방 blueprint로 교체
    - `floor_cells`, `walk_cells`, `blocked_cells`, `socket_entries`, `default_socket_states`, `object_slots` 사용
  - `data/dungeon_quarter/starting_layout.json`
    - `coordinate_mode: logical_grid_v2`
    - 현재 데모 맵을 20x20 논리 좌표에 배치
  - `data/dungeon_quarter/custom_layouts.json`
    - 기본 맵과 `expanded_right_branch_layout_01` 커스텀 맵 catalog 구성
  - `data/dungeon_quarter/asset_manifest.json`
    - v2 타일/오브젝트 렌더링에 필요한 manifest 보강

- 그래프/보행
  - `scripts/dungeon_quarter/AutoTileMask.gd`
    - canonical bit: `N=1`, `E=2`, `S=4`, `W=8`
    - 열린 edge set 기준으로 16 floor mask 계산
  - `scripts/dungeon_quarter/ModuleGraph.gd`
    - 전체 `20x20` master cell grid 생성
    - 각 cell에 `active`, `cell_type`, `theme`, `walkable`, `room_id`, `is_corridor`, `socket_state`, `object_id`, `trap_id` 기록
    - `closed`, `open_placeholder`, `connected` 소켓 상태 반영
    - 시설 변경 뒤 같은 방 geometry는 유지하되, `facility_role`에 맞춰 object slot을 재빌드
    - `room_at_world()`를 추가해 드래그/클릭 판정을 사각 bounds가 아니라 논리 셀 기준으로 처리
  - `scripts/dungeon_quarter/DungeonWalkMap.gd`
    - `CellData.walkable`과 열린 edge set 기반 pathfinding
    - 인접 floor라도 edge가 닫혀 있으면 통과하지 않음

- 렌더러/UI
  - `scripts/dungeon_quarter/QuarterDungeonRenderer.gd`
    - v2 layer 순서로 tile grid 렌더링
    - module PNG 합성 경로 대신 cell floor/edge/wall/socket/object/trap 렌더링 사용
  - `scripts/game/GameRoot.gd`
    - `set_quarter_layout()`, `_select_quarter_layout()`, `quarter_layout_display_name()` 추가
    - 시설 변경 뒤 quarter map 재빌드
    - debug key를 v2 규칙으로 정렬: `F3 active`, `F4 walkable`, `F5 floor mask`, `F6 socket`, `F7 room id`
  - `scripts/game/ManagementSceneController.gd`
    - 관리 화면 좌측에 `맵 커스텀` 레이아웃 선택 패널 추가

- 테스트
  - `tools/QuarterModuleSmokeTest.gd`
    - v2 schema, 20x20 grid, active rect, socket state, mask bit, walk path, renderer layer, debug key, layout 선택 UI callback 검증
  - `tools/DemoSmokeTest.gd`
    - v2 walk map 기준으로 기존 데모 루프 통과 확인

## 이어받기 규칙

1. 이 세션 범위는 맵 커스텀이다. 전투 밸런스, AI, 경제, 일반 UI 리디자인은 맵 커스텀 검증에 꼭 필요할 때만 건드린다.
2. 기존 map custom 구현과 데이터는 v2와 충돌하면 기존 것을 버린다.
3. `20x20` master grid는 고정이다. grade 확장은 `active_rect` 변경이다.
4. 방과 통로는 이미지가 아니라 cell 집합이다.
5. 이동/경로/드롭 판정은 `CellData.walkable`과 열린 edge set 기준이다.
6. 소켓 상태는 `closed`, `open_placeholder`, `connected` 세 가지다. `open_placeholder`는 시각 표시만 하고 연결 floor로 계산하지 않는다.
7. floor mask bit는 하나만 canonical로 둔다: `N=1`, `E=2`, `S=4`, `W=8`.
8. v2 layer 이름은 유지한다: `BackgroundVoidLayer`, `FloorLayer`, `EdgeSkirtLayer`, `BackWallLayer`, `ObjectBackLayer`, `UnitYSortLayer`, `ObjectFrontLayer`, `FrontWallLayer`, `FxLayer`, `UiDebugLayer`.
9. 완료 전 최소 검증은 아래 네 명령이다.

```powershell
godot --headless --path . --import
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --path . --run res://tools/ManualVerificationCapture.tscn
```

## 검증 결과

- `godot --headless --path . --import`: PASS
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`
- `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS
  - 출력: `C:/Users/LDK-6248/Desktop/AI개발/어시스트프로젝트/마왕성/tmp/manual_verification`
  - 확인 이미지: `01_management.png`, `03_combat_start.png`, `04_combat_trap_trigger.png`

## 남은 리스크

- 현재 커스텀은 catalog 기반 레이아웃 선택과 시설 역할 변경 반영까지다. 별도 맵 저작 에디터(셀을 직접 찍고 소켓을 연결하는 도구)는 아직 만들지 않았다.
- v2 로직은 고정했지만, 일부 에셋 이름은 과거 `NW/NE/SE/SW` 명명 관성이 남아 있어 렌더러 alias로만 사용한다. 논리 규칙은 반드시 `N/E/S/W`를 기준으로 유지한다.

## 2026-07-03 추가 진행: 맵 에디터 1차

- 관리 화면 `맵 커스텀` 패널에 `편집` 진입을 추가했다.
- 편집 중 선택 방의 `grid_origin`을 상/하/좌/우로 이동할 수 있다.
- 이동 결과는 즉시 `ModuleGraph`와 `QuarterDungeonRenderer`에 반영된다.
- 편집 중 무효 상태는 허용하지만, 저장은 `ModuleGraph.validation_summary().ok == true`일 때만 허용한다.
- 검증은 다음 항목까지 포함한다.
  - 20x20 max grid 밖 배치
  - active rect 밖 배치
  - floor cell overlap
  - connected socket 인접/방향 오류
  - required path / walk path 단절
- 저장 시 `DataRegistry.register_quarter_layout()`로 runtime catalog에 등록하고, 실제 UI 저장은 `data/dungeon_quarter/custom_layouts.json`에 persistence를 시도한다.
- 테스트에서는 `persist=false`로 저장하여 디스크 catalog를 오염시키지 않는다.
- 편집 중 선택 방은 `QuarterDungeonRenderer`가 노란 외곽선으로 표시하고, 오류가 있으면 붉은 외곽선으로 표시한다.
- 편집 중에는 전투 시작, 날짜 진행, 몬스터 관리, 건설, 시설 변경을 막는다.

### 추가 검증

- `godot --headless --path . --import`: PASS
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`
- `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS

### 다음 작업 후보

- 셀/소켓 직접 클릭 편집.
- 연결 후보 자동 탐색과 socket connect/disconnect UI.
- 방 하나 이동 시 연결된 branch를 함께 이동하는 valid transform.
- 저장한 custom layout 이름 변경/삭제.

## 2026-07-03 추가 진행: 소켓 편집 1차

- 편집 패널에 `연결 해제`, `인접 연결` 버튼을 추가했다.
- `연결 해제`
  - 선택 방이 포함된 모든 `connections` 항목을 제거한다.
  - 제거된 양쪽 소켓은 `socket_states`에서 `open_placeholder`로 바꾼다.
  - 필수 경로와 관계없는 선택 방은 연결 해제 후 이동/저장이 가능하다.
- `인접 연결`
  - 선택 방의 미연결 소켓과 다른 방의 미연결 소켓 중 논리 셀이 인접하고 방향이 서로 마주 보는 첫 후보를 연결한다.
  - 연결된 양쪽 소켓은 `socket_states`에서 `connected`로 바꾼다.
- 편집 중 무효 배치 경고는 콘솔 경고로 뿌리지 않고, 편집 패널 상태와 맵 외곽선 색으로만 표시한다.
- `ManualVerificationCapture.gd`에 편집 화면 캡처 `01_map_editor.png`를 추가했다.

### 추가 검증

- `godot --headless --path . --import`: PASS
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`
- `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS
  - 확인 이미지: `01_management.png`, `01_map_editor.png`, `03_combat_start.png`, `04_combat_trap_trigger.png`

### 다음 작업 후보

- 소켓 후보를 하나씩 순환 선택하는 UI.
- 소켓 직접 클릭 편집.
- 연결된 branch를 함께 이동하되 locked room은 기준점으로 남기는 transform.
- 저장한 custom layout 이름 변경/삭제.

## 2026-07-03 추가 진행: v2 규칙 기반 에셋 교체

- 정정: 아래 `tools/generate_quarter_v2_assets.py` 산출물은 규칙 검증용 임시 도형 에셋으로만 본다. 최종 아트 방향으로 승인하지 않는다.
- 추가 정정: 이 프로젝트에서 `GPT Image 2`는 Codex 내장 `image_gen` 이미지 생성 도구를 뜻한다. API/CLI fallback이나 `OPENAI_API_KEY` 확인으로 우회하지 않는다.
- 사용자가 요청한 시각 에셋은 내장 이미지 생성 경로로 다시 만든다.
- GPT 이미지 생성 시트: `output/imagegen/quarter_v2_gpt_image2_asset_sheet.png`
- 이 시트를 기준으로 이후 바닥/통로/벽/오브젝트를 크롭/알파 처리해서 프로젝트 에셋에 연결한다.
- 기존 `gpt2` 방 마커/룸 미리보기 이미지를 화면에서 쓰지 않도록 v2 규칙 기반 에셋 연결은 진행했지만, 현재 연결된 도형 스타일 이미지는 GPT 생성 에셋으로 교체 대상이다.
- 생성 스크립트: `tools/generate_quarter_v2_assets.py`
- 새 타일 경로:
  - `assets/tiles/cave_v2/floor/floor_cave_v2_mask_00.png` ~ `15`
  - `assets/tiles/cave_v2/edge/edge_cave_v2_*_lip.png`
  - `assets/tiles/cave_v2/wall/wall_cave_v2_*`
  - `assets/tiles/cave_v2/door/door_cave_v2_*_open.png`
- 새 오브젝트/함정 경로:
  - `assets/props/v2/prop_*.png`
  - `assets/props/v2/trap_spike_v2_*.png`
- 새 UI 방 썸네일 경로:
  - `assets/ui/room_v2/room_v2_*.png`
- `data/dungeon_quarter/tile_variant_manifest.json`의 `theme_id`를 `cave_v2`로 교체했다.
- `data/dungeon_quarter/asset_manifest.json`의 prop/trap sprite 경로를 `assets/props/v2`로 교체했다.
- `data/rooms.json`과 `GameRoot._facility_definition()`의 방 아이콘을 `assets/ui/room_v2`로 교체했다.
- `GameRoot._load_textures()`의 표시용 `props` 로더도 v2 썸네일만 읽도록 정리했다.
- 확인용 에셋 시트: `output/quarter_v2_asset_preview.png`

### 이미지 생성 규칙

- `GPT Image 2` 요청은 내장 `image_gen` 도구 호출로 처리한다.
- 여러 에셋이 필요하면 내장 생성 호출을 여러 번 쓰거나, 내장 생성으로 asset sheet를 만든 뒤 프로젝트에서 잘라 쓴다.
- CLI/API batch, `OPENAI_API_KEY`, 별도 이미지 생성 스크립트는 이 맵 에셋 작업의 기본 경로가 아니다.
- 코드로 직접 그린 PNG는 최종 아트가 아니라 임시 검증물로만 취급한다.
- 코드 사용 범위는 생성 이미지의 복사, 크롭, 알파 제거, 리사이즈, import, manifest 연결이다.

### 추가 검증

- `godot --headless --path . --import`: PASS
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`
- `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS
  - 확인 이미지: `01_management.png`, `01_map_editor.png`, `03_combat_start.png`

## 2026-07-03 추가 진행: 내장 GPT Image 2 시트 맵 적용

- 내장 이미지 생성 결과를 프로젝트 소스로 복사했다.
  - `output/imagegen/quarter_v2_gpt_image2_asset_sheet.png`
  - `output/imagegen/spike_floor_v2_gpt_image2_sheet.png`
- 후처리 스크립트를 추가했다.
  - `tools/slice_quarter_v2_gpt_sheet.py`
- 후처리 범위:
  - GPT 생성 asset sheet에서 바닥, wall/door/edge, prop, UI room icon을 크롭/알파 처리했다.
  - 바닥 16마스크는 생성 시트의 석재 플랫폼 텍스처를 2:1 다이아몬드 셀에 맞춰 만든다.
  - 별도 내장 생성한 spike sheet에서 `idle`, `trigger_00~03` 함정 프레임을 추출했다.
  - 기존 `assets/tiles/cave_v2`, `assets/props/v2`, `assets/ui/room_v2` 경로를 유지하고 내용만 GPT 생성 기반으로 교체했다.
- 실제 화면 확인:
  - `01_management.png`: 좌측 방 목록, 우측 방 미리보기, 중앙 맵 모두 GPT 생성 기반 v2 에셋으로 표시됨.
  - `01_map_editor.png`: 편집 선택 박스가 새 바닥/소품 위에 정상 표시됨.
  - `03_combat_start.png`: 전투 중 유닛 발밑 기준과 맵 바닥 정렬 정상.
  - `04_combat_trap_trigger.png`: 함정 발동 프레임이 표시되고 데모 피해 이벤트와 연결됨.

### 추가 검증

- `godot --headless --path . --import`: PASS
- `godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn`: `QUARTER_MODULE_SMOKE_TEST: PASS`
- `godot --headless --path . --run res://tools/DemoSmokeTest.tscn`: `DEMO_SMOKE_TEST: PASS`
- `godot --path . --run res://tools/ManualVerificationCapture.tscn`: PASS
  - 확인 이미지: `01_management.png`, `01_map_editor.png`, `03_combat_start.png`, `04_combat_trap_trigger.png`

### 남은 시각 리스크

- 현재 16 floor mask는 같은 GPT 석재 플랫폼 계열의 변형이며, 모든 연결 방향이 독립적으로 그려진 완전한 16방향 전용 atlas는 아니다.
- 렌더 정합은 정상이나, 더 높은 품질을 원하면 다음 단계에서 내장 이미지 생성으로 `floor mask 0~15` 전용 atlas를 따로 생성해 교체한다.
