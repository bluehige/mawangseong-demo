# 작업 로그: 쿼터뷰 소켓 연결식 모듈 맵 전환 계획

작성일: 2026-07-02

## 요청

- 지금까지 작업한 내용을 오늘자로 백업.
- `mawang_quarterview_walkarea_update_docs` 문서 묶음을 확인.
- 쿼터뷰 맵을 소켓 연결식 모델 조립형으로 구성하는 개발 계획 수립.

## 백업

백업 위치:

`C:\Users\LDK-6248\Desktop\AI개발\어시스트프로젝트\마왕성_backups\2026-07-02_1f7fc62_walkarea_plan`

생성 파일:

- `mawang_git_all_2026-07-02_1f7fc62.bundle`
- `mawang_source_2026-07-02_1f7fc62.zip`
- `BACKUP_MANIFEST.txt`

기준 커밋:

- `1f7fc62 Adjust combat scale and zoom`

## 확인한 문서

- `QUARTERVIEW_DUNGEON_MODULE_SPEC_FULL.md`
- `docs/00_QUICK_COPYPASTE_RULES.txt`
- `docs/01_QUARTERVIEW_DUNGEON_MODULE_RULES.md`
- `docs/02_QUARTERVIEW_GRAPHIC_ASSET_RULES.md`
- `docs/03_GODOT_IMPLEMENTATION_GUIDE.md`
- `docs/04_CODEX_COMMANDS.md`
- `docs/05_WALKABLE_FLOOR_NAVIGATION_RULES.md`
- `templates/module_data_example.json`
- `templates/module_data_walkable_example.json`
- `templates/layout_template_example.json`
- `templates/dungeon_walkmap_gd_snippet.gd`

## 판단

- 기존 `rooms.json + RoomGraph + DungeonRenderer` 구조를 바로 삭제하면 전투/관리/지침/배치 기능이 크게 흔들린다.
- 새 시스템은 `ModuleGraph + DungeonWalkMap + QuarterDungeonRenderer`를 병렬 구축한 뒤, 현재 `RoomGraph` API와 호환되는 방식으로 단계 전환하는 편이 안전하다.
- 문서의 핵심은 “소켓은 연결 검사용, 실제 이동은 `walk_cells` 기반 `DungeonWalkMap`이 단일 진실”이다.
- 현재 막 구현한 전투 줌/캐릭터 축소/보행 보정은 임시 `RoomGraph.clamp_to_walkable()`에서 최종 `DungeonWalkMap.get_path_world()` 구조로 자연스럽게 넘어갈 수 있다.

## 작성한 계획 문서

- `docs/PLAN_2026-07-02_QUARTERVIEW_SOCKET_MODULE_MAP.md`

## 계획 요약

1. 백업과 기능 플래그를 먼저 둔다.
2. `IsoMath`, `DungeonModuleData`, `PlacedModule`, `ModuleGraph`, `SocketValidator`, `DungeonWalkMap`부터 만든다.
3. 실제 아트 전에 placeholder 쿼터뷰 모듈 렌더러와 F1~F8 디버그 오버레이를 만든다.
4. 기존 전투 이동을 `DungeonWalkMap.get_path_world()`로 연결한다.
5. `room_id`를 `module_instance_id` 의미로 점진 전환한다.
6. 소켓 건설/교체 UI를 붙인다.
7. 마지막에 실제 쿼터뷰 bg/fg/walk_debug 아트로 교체한다.

## 남은 작업

- 다음 구현 턴에서는 `data/dungeon_quarter/modules.json`, `starting_layout.json` 초안과 `scripts/dungeon_quarter/IsoMath.gd`, `DungeonWalkMap.gd`부터 만들면 된다.
- 새 문서 묶음 `mawang_quarterview_walkarea_update_docs/`는 현재 untracked 상태다. 기준 문서로 계속 둘지, repo에 포함할지는 별도 판단이 필요하다.
