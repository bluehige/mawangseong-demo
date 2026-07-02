# 작업 로그: 쿼터뷰 보행맵 모듈 셀 전환

작성일: 2026-07-02

## 요청

- `DungeonWalkMap`을 기존 room rect/corridor 기반에서 `walk_cells/block_cells/prop_block_cells` 기반 전역 셀 병합으로 전환.

## 구현

- `DungeonWalkMap.gd`
  - `rebuild_from_modules()` 추가.
  - 배치된 모듈의 `walk_cells`를 전역 보행 셀로 병합.
  - `block_cells`, `prop_block_cells`를 전역 차단 셀로 병합.
  - `socket_entry_cells`와 레이아웃 `connections`를 이용해 모듈 사이 통행 연결부를 생성.
  - 현재 `starting_layout.coordinate_mode`가 `legacy_world_grid`이므로, 모듈 local cell은 기존 `rooms.json`의 room rect 안으로 투영한다.
  - AStarGrid2D는 병합된 모듈 셀을 기준으로 재생성한다.

- `ModuleGraph.gd`
  - `DungeonWalkMap.rebuild_from_modules()`를 사용하도록 연결.
  - `debug_source_mode()` 추가.

- `QuarterModuleSmokeTest.gd`
  - 보행맵이 `module_cells` 기반으로 빌드되는지 확인.
  - walk/block 셀 등록 여부 확인.
  - block 셀 중심이 실제로 비보행 처리되는지 확인.
  - 기존 필수 경로와 게임 루트 통합 검증 유지.

## 검증

통과:

```powershell
godot --headless --path . --import
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
```

결과:

- `QuarterModuleSmokeTest.tscn` PASS
- `DemoSmokeTest.tscn` PASS
- 기존 직접 조종, 충돌 회피, 전투 루프 유지
- F3/F7 디버그 overlay는 이제 모듈 셀 병합 결과를 표시한다.

## 다음 작업

1. 쿼터뷰 그래픽 리소스 제작 시작.
2. 제작된 module bg/fg 이미지와 현재 `walk_cells/block_cells` 투영이 맞는지 F3/F7 overlay로 검증.
3. 리소스 제작 순서는 테스트방, 직선 복도, 입구, 왕좌, 보물방, 가시복도, 병영, 회복실 순서가 적절하다.
4. 그래픽 리소스가 들어온 뒤에는 `legacy_world_grid` 투영을 실제 쿼터뷰 모듈 월드 좌표로 전환한다.
