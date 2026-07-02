# 작업 로그: 쿼터뷰 모듈 디버그 렌더러

작성일: 2026-07-02

## 요청

- 수정된 모듈형 맵 구성 계획의 다음 단계 진행.
- 그래픽 리소스 제작은 그 이후 단계인지 확인.

## 판단

- 그래픽 리소스 제작은 이번 단계 이후가 맞다.
- 먼저 소켓, 모듈 footprint, walk/block 셀, 커서 셀을 화면에서 확인할 수 있어야 실제 리소스 제작 시 이미지와 데이터가 어긋나는 문제를 줄일 수 있다.
- 따라서 이번 단계는 실제 아트 제작이 아니라 placeholder/디버그 렌더링과 검증 토글을 붙이는 작업으로 진행했다.

## 구현

- `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` 추가.
  - 기존 `DungeonRenderer`와 분리된 overlay 전용 렌더러.
  - 모듈 외곽선, 소켓 연결, walkable cell, blocked cell, 커서 cell 표시 지원.

- `GameRoot.gd`에 쿼터뷰 디버그 렌더러 연결.
  - 기본 화면을 덮지 않도록 모든 디버그 overlay는 기본 OFF.
  - F1: 소켓 연결 표시.
  - F2: 모듈 placeholder 외곽선 표시.
  - F3: 보행 가능 셀 표시.
  - F7: 차단 셀 표시.
  - F8: 현재 커서 셀 표시.

- `DungeonWalkMap.gd` 디버그 API 추가.
  - walkable/blocked cell rect 목록.
  - world position -> cell 변환.
  - cell walkable 여부.

- `ModuleGraph.gd` 디버그/렌더러 API 추가.
  - 모듈 인스턴스 목록.
  - 인스턴스별 모듈 데이터.
  - 소켓 연결 pair.
  - walk/block/cursor cell 디버그 위임.

- `QuarterModuleSmokeTest.gd` 확장.
  - 렌더러 연결 여부 확인.
  - F1/F2/F3/F7/F8 토글 검증.
  - overlay가 켜진 상태에서 redraw 프레임을 한 번 넘겨 draw 호출까지 검증.

## 검증

통과:

```powershell
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --path . --run res://tools/ManualVerificationCapture.tscn
```

결과:

- 쿼터뷰 모듈/소켓/보행 디버그 토글 테스트 PASS.
- 기존 데모 스모크 테스트 PASS.
- 일반 렌더러 캡처 생성 성공.
- 기본 화면에서는 디버그 overlay가 꺼져 있어 플레이 화면을 덮지 않는다.

## 다음 작업

1. `DungeonWalkMap`을 기존 room rect 기반에서 실제 `walk_cells/block_cells/prop_block_cells` 전역 셀 병합 기반으로 전환.
2. F3/F7 overlay와 실제 모듈 셀 데이터가 맞는지 확인.
3. 그 다음 쿼터뷰 그래픽 리소스 제작 시작.
4. 제작 순서는 테스트방/직선복도/입구/왕좌/보물방/가시복도/병영/회복실 순서가 적절하다.
