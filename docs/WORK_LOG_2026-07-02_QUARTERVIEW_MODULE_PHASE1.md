# 작업 로그: 쿼터뷰 소켓 모듈 맵 Phase 1 구현

작성일: 2026-07-02

## 요청

- 수정된 모듈형 맵 구성 개발 계획대로 진행.
- 기존 전투/관리 기능은 유지하면서, 쿼터뷰 전용 소켓 연결식 모듈 맵 기반을 실제 코드에 연결.
- 작업 로그는 별도 백업 문서로 남김.

## 구현 범위

- `data/dungeon_quarter/modules.json`
  - 현재 데모 맵을 8개 모듈로 분해한 초안 데이터 추가.
  - 입구, 가시 복도, 중앙 분기, 왕좌, 병영, 회복실, 건설 슬롯, 보물방 포함.
  - 각 모듈에 `sockets`, `walk_cells`, `block_cells`, `prop_block_cells`, 목적별 셀 메타데이터 추가.

- `data/dungeon_quarter/starting_layout.json`
  - 현재 데모 방 ID와 동일한 `module_instance_id`를 사용하는 시작 레이아웃 추가.
  - `entrance -> throne`, `entrance -> treasure` 필수 경로 명시.
  - 기존 UI/AI 호환을 위해 `room_id == module_instance_id` 전략 유지.

- `scripts/dungeon_quarter/`
  - `IsoMath.gd`: 향후 쿼터뷰 좌표 변환용 유틸.
  - `PlacedModule.gd`: 배치된 모듈 인스턴스 데이터 모델.
  - `DungeonModuleRegistry.gd`: 모듈 데이터 조회/필수 필드 검증.
  - `SocketValidator.gd`: 소켓 방향, 폭, 연결 타입, 필수 경로 검증.
  - `DungeonWalkMap.gd`: 현재 런타임용 보행 셀/AStarGrid2D 경로 생성.
  - `ModuleGraph.gd`: 기존 `RoomGraph` API와 호환되는 모듈 그래프.

- 기존 코드 연결
  - `DataRegistry.gd`: 쿼터뷰 모듈/레이아웃 JSON 로딩 추가.
  - `GameRoot.gd`: `use_quarter_module_map` 플래그 추가, 모듈 데이터가 있으면 `ModuleGraph` 사용.
  - `CombatSceneController.gd`: 점 이동도 `path_to_point()` 기반 경로를 사용.
  - `Unit.gd`: 직접 공격 명령 시 보행맵 경로가 있으면 경로를 우선 따라가도록 조정.

- 테스트
  - `tools/QuarterModuleSmokeTest.gd/.tscn` 추가.
  - 소켓 검증, 필수 경로, 보행 가능 경로 확장, 게임 루트 통합 확인.
  - `DemoSmokeTest.gd`는 직접 공격 테스트가 이전 공격 쿨다운 타이밍에 의존하지 않도록 보정.

## 검증 결과

통과:

```text
godot --headless --path . --import
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
```

핵심 확인:

- 모듈 JSON과 시작 레이아웃 로딩 성공.
- 소켓 연결 검증 성공.
- 입구에서 왕좌/보물방까지 필수 경로 존재.
- `RoomGraph` 호환 API를 통해 기존 관리/전투 UI 유지.
- 전투 이동 경로가 `DungeonWalkMap` 경로로 확장됨.
- 기존 데모 스모크 테스트 전체 통과.

## 보류/다음 작업

- 아직 실제 화면 렌더러는 기존 `DungeonRenderer`를 사용한다.
- 다음 단계에서 `QuarterDungeonRenderer` 또는 placeholder 쿼터뷰 모듈 렌더러를 추가해야 한다.
- 소켓 교체/건설 UI는 아직 붙이지 않았다.
- `DungeonWalkMap`은 현재 화면 호환을 위해 기존 방 rect/corridor 기반으로 생성한다. 실제 쿼터뷰 아트 배치 단계에서 `walk_cells/block_cells/prop_block_cells` 기반 전역 셀 병합으로 전환해야 한다.
- 디버그 오버레이(F3/F7 등)는 다음 렌더러 단계에서 추가하는 것이 적절하다.
