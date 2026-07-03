이 파일이 왜 필요한지: 이번 세션의 범위를 "맵 커스텀 완성"으로 고정하고, 세션 압축/인계 후에도 같은 참고자료와 같은 구현 규칙에서 이어가기 위해 필요하다.

# 맵 커스텀 전용 전면 재구현 계획

작성일: 2026-07-03

## 2026-07-03 구현 완료 상태

- v2 기준으로 기존 맵 커스텀 데이터/코드를 덮어썼다.
- `20x20` master grid, 등급별 `active_rect`, v2 `CellData`, canonical mask bit, socket 3상태, edge-constrained walk map을 구현했다.
- 관리 화면에 catalog 기반 `맵 커스텀` 레이아웃 선택 UI를 추가했다.
- 시설 변경은 방 geometry를 흔들지 않고 `facility_role`에 맞는 object slot 재빌드로 반영한다.
- `tools/generate_quarter_v2_assets.py` 산출물은 규칙 확인용 임시 도형 에셋이다. 최종 아트는 GPT 이미지 생성 결과를 사용한다.
- 이 프로젝트에서 `GPT Image 2`는 Codex 내장 `image_gen` 이미지 생성 도구를 뜻한다. 맵 에셋 제작에서 API/CLI fallback이나 `OPENAI_API_KEY` 확인으로 우회하지 않는다.
- GPT 이미지 생성 기준 시트: `output/imagegen/quarter_v2_gpt_image2_asset_sheet.png`
- 화면에 표시되는 방 목록/선택 패널은 `assets/ui/room_v2/room_v2_*.png`를 사용하며, 기존 `marker_*_gpt2.png` 마커로 되돌리지 않는다.
- 최종 작업 로그와 검증 결과는 `docs/WORK_LOG_2026-07-03_QUARTERVIEW_CUSTOM_LAYOUTS.md`를 기준으로 본다.

## 전제

기존 쿼터뷰 맵 커스텀 구현은 참고자료 v2 기준과 다르게 만든 임시/오답 구조로 본다.
따라서 맵 커스텀 관련 기존 코드와 데이터는 호환 유지하지 않아도 되며, 새 규칙에 맞게 덮어씌운다.

단, 전투 밸런스, 적 AI, 스킬, 경제, 몬스터 성장, 일반 UI처럼 맵 커스텀과 직접 관련 없는 영역은 불필요하게 건드리지 않는다.

## 반드시 다시 읽을 참고자료

기준 자료 경로:

`C:\Users\LDK-6248\Desktop\AI개발\어시스트프로젝트\마왕성\참고자료\mawang_quarterview_tilegrid_v2_docs\mawang_quarterview_tilegrid_v2`

압축되거나 세션이 넘어간 뒤에는 아래 순서로 다시 읽고 시작한다.

1. `docs/08_COPYPASTE_FOR_CODEX.txt`
2. `docs/00_README.md`
3. `docs/01_CORE_SYSTEM_RULES.md`
4. `docs/02_GRID_GROWTH_AND_UNLOCK_RULES.md`
5. `docs/03_16_TILE_MASK_RULES.md`
6. `docs/04_BACKGROUND_VOID_UNCONNECTED_RULES.md`
7. `docs/06_CODEX_IMPLEMENTATION_SPEC.md`
8. `templates/castle_grade_unlocks.json`
9. `templates/room_blueprint_v2.json`
10. `templates/tile_mask_mapping.json`

## 현재 프로젝트 파악

재사용 가능한 것:

- `assets/tiles/cave_f/floor/floor_cave_f_mask_00.png`부터 `15.png`: F급 floor 16마스크 에셋.
- `assets/tiles/cave_f/edge`, `overlay`, `wall`, `door`: edge/skirt, corner, wall, doorway 보조 에셋.
- `assets/props`: 왕좌, 보물, 회복, 병영, 입구, 함정 등 일부 오브젝트 에셋.
- 기존 전투/이동 호출부: 최종적으로 새 walkable grid API에 연결만 맞추면 된다.

덮어쓸 대상:

- `data/dungeon_quarter/castle_grade_rules.json`: v2의 `max_grid_size: [20,20]`, grade별 `active_rect` 구조로 교체.
- `data/dungeon_quarter/room_blueprints.json`: v2 `RoomBlueprint` 기준으로 정리하고 `default_socket_states`를 추가.
- `data/dungeon_quarter/starting_layout.json`, `custom_layouts.json`: 새 마스터 그리드/소켓 상태/placed room 구조로 교체.
- `scripts/dungeon_quarter/AutoTileMask.gd`: v2 canonical 방향 `N=1,E=2,S=4,W=8`로 교체.
- `scripts/dungeon_quarter/ModuleGraph.gd`: 기존 모듈 그래프 중심에서 마스터 grid cell state 중심으로 재작성 가능.
- `scripts/dungeon_quarter/DungeonWalkMap.gd`: 새 `CellData.walkable` 기준으로 재작성 가능.
- `scripts/dungeon_quarter/QuarterDungeonRenderer.gd`: v2 레이어와 새 cell state 렌더러로 재작성 가능.
- `tools/QuarterModuleSmokeTest.gd`: 기존 구현 검증이 아니라 v2 규칙 검증으로 교체.

## 작업 순서

| 순서 | 작업 | 대상 | 완료 기준 |
|---:|---|---|---|
| 0 | 기준 고정 | 이 문서, 참고자료 | 기존 맵 커스텀 호환을 버리고 v2 규칙을 정답으로 삼는다. |
| 1 | 기존 맵 커스텀 파일 인벤토리 | `data/dungeon_quarter`, `scripts/dungeon_quarter`, 관련 테스트 | 무엇을 교체할지 확인한다. 보존 목적이 아니라 누락 방지 목적이다. |
| 2 | v2 데이터 스키마 교체 | `castle_grade_rules.json`, 새 `master_grid`/layout 데이터 | `max_grid_size=[20,20]`, grade별 `active_rect`, theme가 데이터로 정의된다. |
| 3 | CellData 모델 작성 | 새 grid model 또는 `ModuleGraph.gd` 재작성 | 모든 셀이 `gx`, `gy`, `active`, `cell_type`, `theme`, `walkable`, `room_id`, `is_corridor`, `socket_state`, `object_id`, `trap_id`를 가진다. |
| 4 | 방/통로 blueprint 재정의 | `room_blueprints.json` | 방/통로는 통짜 이미지가 아니라 `floor_cells`, `walk_cells`, `blocked_cells`, `socket_entries`, `default_socket_states`, `object_slots`의 cell 집합이다. |
| 5 | 레이아웃 구조 교체 | `starting_layout.json`, `custom_layouts.json` | placed room/corridor, socket state, grade, required paths가 새 스키마로 표현된다. |
| 6 | 16마스크 canonical 교체 | `AutoTileMask.gd`, `tile_variant_manifest.json`, 테스트 | 방향은 v2 그대로 `N=1,E=2,S=4,W=8`이며 파일명은 `floor_<theme>_mask_00~15`다. 기존 `NW/NE/SE/SW`는 제거하거나 명확한 렌더 alias로만 둔다. |
| 7 | 소켓 3상태 구현 | grid model, renderer | `closed`, `open_placeholder`, `connected`가 데이터와 렌더에 반영된다. connected만 floor 연결로 인정한다. |
| 8 | WalkMap 재작성 | `DungeonWalkMap.gd` | 모든 이동/AI/직접 조종은 `CellData.walkable` 기반 AStar 경로만 사용한다. 배경/이미지 기반 판정은 없다. |
| 9 | 렌더러 전면 정렬 | `QuarterDungeonRenderer.gd` | `BackgroundVoidLayer`, `FloorLayer`, `EdgeSkirtLayer`, `BackWallLayer`, `ObjectBackLayer`, `UnitYSortLayer`, `ObjectFrontLayer`, `FrontWallLayer`, `FxLayer`, `UiDebugLayer` 순서로 그린다. |
| 10 | active/void/rock 시각화 | renderer, asset manifest | 바닥 없는 곳은 floor를 그리지 않고 배경/void가 보인다. active rock과 open placeholder는 서로 다른 시각 상태다. |
| 11 | 커스텀 선택/교체 UI | 관리 화면 | 레이아웃 선택, 방 모듈 교체, 소켓 연결/해제가 실제 grid와 renderer에 반영된다. |
| 12 | 디버그 키 재정렬 | `GameRoot.gd`, renderer | `F3 active`, `F4 walkable`, `F5 mask`, `F6 socket`, `F7 room id`가 새 규칙대로 표시된다. |
| 13 | 테스트 전면 교체 | `QuarterModuleSmokeTest.gd`, `DemoSmokeTest.gd` | v2 스키마, 20x20 grid, active rect, 16마스크, 소켓 3상태, walkable 경로, 레이어명, 디버그 키를 검증한다. |
| 14 | 수동 캡처 검증 | `ManualVerificationCapture.tscn` | 관리/전투 화면에서 배경, 바닥, edge, 소켓 연결 전후, 방 교체가 어색하지 않다. |
| 15 | 작업 로그 갱신 | `docs/WORK_LOG_...` | 교체한 파일, 검증 명령, 남은 리스크를 남긴다. |

## 우선순위 결정

이번 세션에서 먼저 끝내야 하는 것은 기존 구현을 살리는 일이 아니다.

우선순위는 다음이다.

1. v2 스키마와 `20x20` 마스터 그리드를 먼저 만든다.
2. `active/void/rock/floor/socket_state/walkable`이 하나의 셀 데이터에서 나온다.
3. floor 연결은 v2 16마스크 규칙으로만 계산한다.
4. 소켓 연결 전후가 데이터와 화면에서 다르게 보인다.
5. 관리 화면에서 커스텀 선택/방 교체가 실제 맵 구조를 바꾼다.
6. 자동 테스트와 수동 캡처가 새 규칙을 검증한다.

## 압축/인계 시 필수 규칙

1. 이 세션의 범위는 맵 커스텀뿐이다. 전투 밸런스, 적 AI, 스킬, 경제, 일반 UI 리디자인은 맵 커스텀을 위해 꼭 필요한 경우가 아니면 건드리지 않는다.
2. 기존 맵 커스텀 구현은 보존 대상이 아니다. v2 규칙과 충돌하면 기존 것을 덮어쓴다.
3. 참고자료 v2의 핵심 결론을 우선한다. 구역당 통짜 방/맵 PNG 배치 방식으로 돌아가지 않는다.
4. 논리 그리드가 원천 데이터다. 쿼터뷰 렌더 좌표는 항상 `grid_to_world`/`IsoMath` 변환 결과다.
5. 최대 그리드는 `20x20`으로 고정하고, 등급 상승은 배열 재생성이 아니라 `active` 셀 증가로 처리한다.
6. 배경 이미지는 분위기와 빈 공간 채우기만 담당한다. walkable, 연결, exposed edge 판정에 절대 쓰지 않는다.
7. 방과 통로는 항상 cell 집합이다. `floor_cells`, `walk_cells`, `blocked_cells`, `sockets`, `object_slots`를 기준으로 처리한다.
8. 소켓은 반드시 `closed`, `open_placeholder`, `connected` 세 상태로 다룬다. 연결 전후 같은 이미지를 재사용하지 않는다.
9. 이동은 항상 `walkable` cell 기반이다. 예쁜 바닥처럼 보여도 `walkable=false`면 이동 금지다.
10. 큰 오브젝트는 가능하면 back/front로 나눈다. 오브젝트는 floor mask를 바꾸지 않고, 필요할 때만 block cell로 이동을 막는다.
11. 16마스크 비트 규칙은 하나만 canonical로 둔다. v2는 `N=1, E=2, S=4, W=8`이다. 현재 코드의 `NW/NE/SE/SW`는 제거하거나 렌더 좌표 별칭으로만 둔다.
12. 레이어는 v2 명세 순서를 따른다: `BackgroundVoidLayer`, `FloorLayer`, `EdgeSkirtLayer`, `BackWallLayer`, `ObjectBackLayer`, `UnitYSortLayer`, `ObjectFrontLayer`, `FrontWallLayer`, `FxLayer`, `UiDebugLayer`.
13. 디버그 키는 v2 명세를 따른다: `F3 active`, `F4 walkable`, `F5 floor mask`, `F6 socket`, `F7 room id`.
14. 모든 커스텀 레이아웃은 socket validation, 필수 경로, walkable path 검증을 통과해야 한다.
15. 맵 에셋 제작에서 `GPT Image 2`는 Codex 내장 `image_gen` 도구를 의미한다. API/CLI fallback, `OPENAI_API_KEY` 확인, 별도 이미지 생성 스크립트 실행으로 우회하지 않는다.
16. 바닥/통로/벽/오브젝트/방 썸네일 같은 시각 에셋은 내장 이미지 생성 결과를 사용한다. 코드로 그린 임시 도형 에셋을 최종 아트로 취급하지 않는다.
17. 코드 생성은 이미지 후처리, 크롭, 알파 제거, 리사이즈, Godot import, manifest 연결에만 사용한다.
18. 기존 `gpt2` 통짜 방 이미지나 `marker_*_gpt2.png` UI 마커를 새 맵 커스텀 화면에 다시 연결하지 않는다.
19. 세션 시작/재개 시 `git status --short`를 먼저 확인한다. 단, 맵 커스텀 관련 기존 구현은 덮어써도 된다.
20. 완료 전 최소 검증 명령은 다음이다.

```powershell
godot --headless --path . --import
godot --headless --path . --run res://tools/QuarterModuleSmokeTest.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --path . --run res://tools/ManualVerificationCapture.tscn
```

21. 최종 응답에는 변경 파일, 실행한 검증, 실패/미실행 검증, 남은 리스크만 짧게 보고한다.
