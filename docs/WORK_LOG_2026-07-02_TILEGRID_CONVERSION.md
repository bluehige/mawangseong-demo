이 파일이 왜 필요한지: 새 쿼터뷰 타일그리드 규칙 문서에 맞춰 던전 구조를 수정한 내용을 백업한다.

# 쿼터뷰 타일그리드 전환 작업 로그

작성일: 2026-07-02

## 요청

`mawang_quarterview_tilegrid_docs/mawang_quarterview_tilegrid_docs/docs`에 있는 문서 규칙을 모두 확인하고, 지금까지 만든 쿼터뷰 던전 방식을 그 규칙에 맞게 수정한다.

## 확인한 문서

- `00_QUICK_COPYPASTE_TILEGRID_RULES.txt`
- `01_QUARTERVIEW_TILE_GRID_MODULE_RULES.md`
- `02_ASSET_COUNT_AND_VARIANT_CALCULATION.md`
- `03_CASTLE_UPGRADE_AND_GRID_SCALING_RULES.md`
- `04_GODOT_IMPLEMENTATION_GUIDE_TILE_GRID.md`
- `05_CODEX_COMMANDS_TILE_GRID_CONVERSION.md`
- `06_GPT_IMAGE_ASSET_PROMPT_RULES.md`
- `07_REFERENCE_SUMMARY.md`
- 패키지 루트의 `QUARTERVIEW_TILE_GRID_MODULE_SPEC_FULL.md`
- `templates/asset_manifest_example.json`
- `templates/castle_grade_rules_example.json`
- `templates/room_blueprint_example.json`
- `templates/tile_variant_manifest_example.json`

## 핵심 결정

- 기존 "구역당 통짜 모듈 PNG 1장" 방식은 메인 렌더 경로에서 사용하지 않는다.
- 방/복도는 `RoomBlueprint`의 `floor_cells`, `walk_cells`, `blocked_cells`, `sockets`, `object_slots`로 정의한다.
- 바닥 연결은 NW=1, NE=2, SE=4, SW=8 기준의 4방향 16마스크로 계산한다.
- 소켓은 연결 가능 여부만 판단하고, 실제 이동은 `DungeonWalkMap`의 walkable cell을 따른다.
- 현재 단계에서는 실제 PNG 타일셋이 없으므로, 렌더러가 Blueprint 셀을 절차적으로 다이아몬드 타일로 그린다. 다음 리소스 제작 단계에서 `assets/tiles`의 실제 타일 PNG로 교체한다.

## 변경한 데이터

- `data/dungeon_quarter/room_blueprints.json` 추가.
  - 현재 데모 8개 방/복도를 Blueprint 구조로 정의.
  - 각 항목에 `floor_cells`, `walk_cells`, `blocked_cells`, `object_slots`, `theme`, `size` 포함.
- `data/dungeon_quarter/starting_layout.json` 수정.
  - `coordinate_mode`를 `tile_grid`로 변경.
  - F급 8×8 기준 `grid_size`, `tile_size`, `castle_grade` 추가.
  - 연결은 현재 데모 핵심 경로 7개로 정리.
- `data/dungeon_quarter/tile_variant_manifest.json` 추가.
  - `floor_mask` 0~15 전체 정의.
- `data/dungeon_quarter/castle_grade_rules.json` 추가.
  - F 8×8부터 A 18×18까지 규칙 정의.
- `data/dungeon_quarter/asset_manifest.json` 추가.
  - 소품/함정 footprint와 block cell 구조 정의.

## 변경한 코드

- `scripts/dungeon_quarter/AutoTileMask.gd` 추가.
  - 4방향 16마스크 계산.
- `scripts/core/DataRegistry.gd`
  - `room_blueprints.json`을 우선 로드하고 기존 `modules.json`은 fallback으로 유지.
  - tile manifest, castle grade rules, asset manifest 로드 추가.
- `scripts/dungeon_quarter/DungeonWalkMap.gd`
  - `blocked_cells`를 우선 사용.
  - 빌드 출처를 `tile_grid_blueprints`로 변경.
- `scripts/dungeon_quarter/ModuleGraph.gd`
  - tile floor/walk/blocked/socket debug 데이터 제공.
  - floor mask 값 조회 기능 추가.
- `scripts/dungeon_quarter/QuarterDungeonRenderer.gd`
  - 모듈 PNG 로딩/그리기 제거.
  - Blueprint 셀 기반 floor/edge/back wall/door/object/front wall/debug 순서로 렌더.
  - `has_module_visuals()`는 false를 반환해 통짜 이미지 경로가 꺼졌음을 테스트 가능하게 함.
- `scripts/game/GameRoot.gd`
  - 쿼터뷰 모드에서 기존 `DungeonRenderer` 배경을 그리지 않음.
  - F4 floor mask, F5 socket, F6 room id, F9 path debug 추가.
  - 유닛 레이어 이름을 `UnitYSortLayer`로 변경하고 y-sort 활성화.
- `tools/QuarterModuleSmokeTest.gd`
  - 새 Blueprint/manifest/16마스크/디버그 키/렌더러 규칙 검증으로 갱신.

## 리소스 구조

- `assets/tiles/`
  - `cave_f/floor`, `edge`, `wall`, `door`, `overlay`
  - `lair_e/floor`, `fortress_d/floor`
- `assets/props/`
  - `throne`, `treasure`, `barracks`, `recovery`, `traps`

실제 GPT Image 타일/소품 PNG는 아직 생성하지 않았다. 이번 작업은 코드와 데이터 구조를 먼저 새 규칙으로 맞춘 것이다.

## 검증

```powershell
godot --headless --path . --import
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --headless --path . --run res://tools/BalanceSimulation.tscn
godot --path . --run res://tools/ManualVerificationCapture.tscn
```

결과:

- Godot import 종료 코드 0
- `QuarterModuleSmokeTest.tscn` 종료 코드 0, `QUARTER_MODULE_SMOKE_TEST: PASS`
- `DemoSmokeTest.tscn` 종료 코드 0, `DEMO_SMOKE_TEST: PASS`
- `BalanceSimulation.tscn`은 120초 제한에서는 종료 전 timeout이 났고, 240초 제한에서는 정상 완료
- 밸런스 결과는 DAY1/DAY2 자동 승리, DAY3 자동 패배, DAY3 보조 승리 유지
- 수동 검증 캡처 생성 성공: `tmp/manual_verification/01_management.png`, `03_combat_start.png`

## 다음 작업

1. GPT Image로 방 전체가 아니라 개별 `floor/edge/wall/door/prop` PNG를 제작한다.
2. `tile_variant_manifest.json`의 `file_hint`와 실제 파일을 연결한다.
3. 현재 절차적 다이아몬드 렌더를 실제 타일 이미지 렌더로 교체한다.
4. 왕좌/보물더미/회복 둥지 등 큰 소품은 back/front 분리 이미지로 제작한다.
5. 장기적으로 `_draw()` 기반 placeholder를 실제 `TileMapLayer`/Scene Tile 구조로 옮긴다.
