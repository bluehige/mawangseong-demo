# v1.2.2 건물 호환 감사표

공통 근거는 `data/dungeon_quarter/room_blueprints.json`, `asset_manifest.json`, `modules.json`, `castle_evolution_stages.json`, `ModuleGraph.debug_object_slots`, `QuarterDungeonRenderer.debug_object_texture_key/debug_object_facing`이다.

| product_room_id / role | blueprint·object | runtime sprite·stage | facing·anchor | 관리/전투 | 입력·대상 | 저장·metric | P2 상태 |
|---|---|---|---|---|---|---|---|
| `entrance` / entry | `room_entrance_01` · `entrance_gate_f` | `assets/props/v2/prop_entrance_gate_v2_back.png`, stage 01/03/04 override | blueprint SE, object cell | visible / renderer 연결 | 경로·돌파 target | layout 저장·breach metric 예정 | `COMPLETE` |
| `throne` / core | throne blueprint · throne object | `asset_manifest` throne stage override | blueprint anchor/facing | visible / renderer 연결 | 최종 목표 | 왕좌 HP·피해 metric | `COMPLETE` |
| `barracks` / barracks | barracks blueprint · weapon rack/armory | v2/v3 및 stage armory override | ModuleGraph 산출 | visible / renderer 연결 | 클릭·명령·공병 | room state·시설 기여 | `COMPLETE` |
| `recovery` / recovery | recovery blueprint · `recovery_nest_f` | v2 recovery, stage sanctuary override | blueprint NW 계열 | visible / renderer 연결 | 클릭·시설 발동·공병 | room state·healing metric | `COMPLETE` |
| `treasure` / treasure | treasure blueprint · `treasure_pile_large` | v2 treasure, stage vault override | blueprint NW 계열 | visible / renderer 연결 | 클릭·도둑 target | room state·theft metric | `COMPLETE` |
| 건설 슬롯 / build | build-slot blueprint · foundation marks | stage foundation/platform override | slot cell | visible / renderer 연결 | 건설 클릭 | layout·건설 상태 | `COMPLETE` |
| `watch_post` facility role | 해금된 room의 `watch_post` object | v2/v3 watch post·stage 04 watch tower | ModuleGraph room object slot | 관리 visible / 전투 pressure range 연결 | 클릭·시설 발동·공병 target | room state·slow/bonus damage 결산 | `COMPLETE` |
| `heart_chamber` | Update 3 heart chamber module/prop | `data/regular_version/update3`, stage heart asset | module anchor | 관리·전투 기존 전용 렌더 | heart active target | v4/v5 save·heart metric | `COMPLETE` |
| upper facility slots | Update 4 upper floor module/prop | `assets/props/update4/upper/*` | upper layout slot | 별도 안전 화면·전투 상태 | 기존 upper action | v5 save·upper objective | `COMPLETE` |
| v20 barricade alias | 제품 중복 ID 없음 | 신규 그림 사용 금지 | 입구 문/건설 슬롯 중 P2 확정 | 별도 label 금지 | 실제 breach target에 연결 | 제품 room ID로만 저장 | `INTENTIONALLY_NONVISUAL` |

## P2 폐쇄 결과

- `watch_post`는 제품 room ID와 기존 prop을 유지한 채 전투 pressure range, slow, bonus damage, 공병 목표, 무력화 타이머, 결과 metric에 연결돼 있다.
- barricade는 별도 건물로 등록하지 않고 실제 입구 문의 전투 역할 alias로만 해석한다.
- `V122BuildingCompatibilityAdapter`가 제품 room·module·manifest에서 object, stage sprite, facing, anchor, 대상 가능 여부와 결산 metric을 한 번에 산출한다.
- 심장실은 기존 전용 heart sheet renderer를, ward core는 기존 foundation prop의 stage별 NW override를 사용한다.
- 기본·선택·발동·cooldown·공병 목표·무력화·복구·손상·파괴 상태를 동일 제품 room 상태에서 판정한다.
- `V122BuildingCompatibilityTest`와 기존 `QuarterModuleSmokeTest`, `EngineerPerformanceSmokeTest`를 포함한 Quick 73/73이 통과했다.
- `MISSING_OBJECT`, `LABEL_ONLY`, `WRONG_OBJECT`, `WRONG_ANCHOR`, `WRONG_FACING`, `HIDDEN_BY_ZSORT`, `NOT_CLICKABLE`, `STATE_NOT_SYNCED`, `SAVE_MISMATCH`, `PLACEHOLDER_ONLY`는 0이다.
