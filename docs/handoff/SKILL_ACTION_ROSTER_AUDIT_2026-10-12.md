# 마왕성 전체 캐릭터 액션 적용 대조 — 2026-10-12

전체14캐릭터를 확인했으며 모든 기술의 적용 완료라는 결론은 아닙니다. 24개 기존 연결 액티브는 실행/외형 매핑 PASS. 실키·포포4액티브와 왕관6전용 기술은 기존 게임의 실행 경로 미연결입니다. 새 효과·스킬·밸런스는 추가하지 않았습니다.

## 검증 범위

- 26외모: 기본14/승급6/왕관6. 자원/공격·스킬4프레임/현재 sprite 경로 검사 PASS, 외모 fallback0.
- 104액티브 경로: 46형태×기술×수동컨트롤러 요청=46 + 자동=46 성공, 기존 미연결12경로 별도. 수동은 게임의 수동 캐스팅 UI를 새로 만들었다는 뜻이 아닙니다.
- 6합동기26외모쌍×수동/게이지자동=52경로 PASS. 왕관2명동시인2외모쌍×2=4경로는 실제 회차에서 불가능한 자원스트레스 fixture. 도달 가능한 합동기외모쌍24/경로48.
- 실제 Godot GUI147PNG: 액션144 + 미지원정보카드3. 대표23발동가능외모+6합동기=29액션 이미지와 미지원카드3을 직접 열어 확인. 나머지 액션115이미지는 자동렌더/매핑검사이며 개별 육안검토 미실행.
- 미연결 액티브6형태×기술은 액션이 없어 화면발동 검증12경로 미지원. 왕관전용6개의 게임 실행/액션은 NOT_RUN. 왕관 포포 포함3외모는 자원·카드만 검사했으며 활성 스킬 발동은 미지원.
- 최종1012checks/0failures. 수동127/자동56/생명주기34/편의89 회귀 PASS. 자연 캠페인 전체, 사용자 마우스/체감,저사양, Cloud NOT_RUN.

## 플레이 가능 roster와 액티브 IDs

|species|액티브 slots|왕관 전용 ID(기존 미연결)|적용|
|---|---|---|---|
|slime|slime_shield, hold_corridor|royal_jelly_bastion|연결된 기존기술 PASS|
|goblin|quick_slash, loot_instinct|royal_no_second_cut|연결된 기존기술 PASS|
|imp|fireball, flame_zone|tricolor_demonfire|연결된 기존기술 PASS|
|kobold_scout|false_footprints, rumor_boost||연결된 기존기술 PASS|
|spore_healer|spore_mend, cleansing_bloom|royal_shared_umbrella|연결된 기존기술 PASS|
|stone_sentinel|rooted_guard, stone_pulse||연결된 기존기술 PASS|
|war_drummer|war_rhythm, steady_beat||연결된 기존기술 PASS|
|moon_tracker|moon_mark, scent_pursuit||연결된 기존기술 PASS|
|mimic_porter|false_treasure, vault_swap||연결된 기존기술 PASS|
|ghost_housemaid|spectral_transfer, haunted_broom_whirl||연결된 기존기술 PASS|
|graveyard_hound|scent_lock, home_guard_bark||연결된 기존기술 PASS|
|armored_beetle|carapace_ram, patch_plates|royal_emergency_plating|연결된 기존기술 PASS|
|spider_tailor|stitch_stairway, emergency_thread_pull||액티브 기존 미지원|
|bat_courier|night_relay, echo_alarm|royal_urgent_courier|액티브 기존 미지원|

## 전체 외모와 실제 자원

|외모ID|종류|실제현재sprite|idle/attack/skill/down|
|---|---|---|
|armored_beetle:base|base|res://assets/sprites/uiux3d/armored_beetle_sheet.png|2/4/4/2|
|crown_toktok_royal_armorer|crown|res://assets/sprites/uiux3d/crown_toktok_royal_armorer_sheet.png|2/4/4/2|
|bat_courier:base|base|res://assets/sprites/uiux3d/bat_courier_sheet.png|2/4/4/2|
|crown_popo_grand_night_courier|crown|res://assets/sprites/uiux3d/crown_popo_grand_night_courier_sheet.png|2/4/4/2|
|ghost_housemaid:base|base|res://assets/sprites/uiux3d/ghost_housemaid_sheet.png|2/4/4/2|
|goblin:base|base|res://assets/sprites/uiux3d/goblin_sheet.png|2/4/4/2|
|goblin_ambush_captain|promotion|res://assets/sprites/uiux3d/goblin_ambush_captain_sheet.png|2/4/4/2|
|goblin_vault_keeper|promotion|res://assets/sprites/uiux3d/goblin_vault_keeper_sheet.png|2/4/4/2|
|crown_gob_midnight_marshal|crown|res://assets/sprites/uiux3d/crown_gob_midnight_marshal_sheet.png|2/4/4/2|
|graveyard_hound:base|base|res://assets/sprites/uiux3d/graveyard_hound_sheet.png|2/4/4/2|
|imp:base|base|res://assets/sprites/uiux3d/imp_sheet.png|2/4/4/2|
|imp_flame_adept|promotion|res://assets/sprites/uiux3d/imp_flame_adept_sheet.png|2/4/4/2|
|imp_ember_shaman|promotion|res://assets/sprites/uiux3d/imp_ember_shaman_sheet.png|2/4/4/2|
|crown_pynn_castle_flame_sage|crown|res://assets/sprites/uiux3d/crown_pynn_castle_flame_sage_sheet.png|2/4/4/2|
|kobold_scout:base|base|res://assets/sprites/uiux3d/kobold_scout_sheet.png|2/4/4/2|
|mimic_porter:base|base|res://assets/sprites/uiux3d/mimic_porter_sheet.png|2/4/4/2|
|moon_tracker:base|base|res://assets/sprites/uiux3d/moon_tracker_sheet.png|2/4/4/2|
|slime:base|base|res://assets/sprites/uiux3d/slime_sheet.png|2/4/4/2|
|slime_gate_bulwark|promotion|res://assets/sprites/uiux3d/slime_gate_bulwark_sheet.png|2/4/4/2|
|slime_rescue_alchemy_gel|promotion|res://assets/sprites/uiux3d/slime_rescue_alchemy_gel_sheet.png|2/4/4/2|
|crown_pudding_royal_bastion|crown|res://assets/sprites/uiux3d/crown_pudding_royal_bastion_sheet.png|2/4/4/2|
|spider_tailor:base|base|res://assets/sprites/uiux3d/spider_tailor_sheet.png|2/4/4/2|
|spore_healer:base|base|res://assets/sprites/uiux3d/spore_healer_sheet.png|2/4/4/2|
|crown_mori_grand_mycelial_priest|crown|res://assets/sprites/uiux3d/crown_mori_grand_mycelial_priest_sheet.png|2/4/4/2|
|stone_sentinel:base|base|res://assets/sprites/uiux3d/stone_sentinel_sheet.png|2/4/4/2|
|war_drummer:base|base|res://assets/sprites/uiux3d/war_drummer_sheet.png|2/4/4/2|

## 합동기별 외모쌍

|ID|멤버instance pair|외모쌍 수|manual/auto 경로|
|---|---|---|---|
|link_false_beacon_vault|mon_contract_lumi + mon_contract_mimi|1|2|
|link_ghostly_evacuate|mon_core_pudding + monster_bebe|4|8|
|link_molten_carapace|mon_core_pynn + monster_toktok|8|16|
|link_moon_scent_hunt|mon_core_gob + monster_koko|4|8|
|link_spore_jelly_shelter|mon_core_pudding + mon_contract_mori|8|16|
|link_stone_march|mon_contract_dolkong + mon_contract_dudum|1|2|

## 누락과 최소 수정

실키 stitch_stairway/emergency_thread_pull, 포포 night_relay/echo_alarm은 기존 CombatSceneController의 구체 effect match/auto조건에 없고 별도 서비스도 실제 게임에서 호출되지 않았습니다. 로그만 남기고 자원을 차감하는 legacy fallback을 새 컷씬이 성공으로 기록하지 못하도록 공용 action request에서 거부합니다. native 정보카드와 legacy 요약에 미지원 상태를 표시했습니다. 직접 low-level legacy test kernel은 유지하며 runtime UI가 그 경로를 호출하지 않음을 대조했습니다.

왕관 royal_jelly_bastion/royal_no_second_cut/tricolor_demonfire/royal_shared_umbrella/royal_emergency_plating/royal_urgent_courier는 데이터/서비스 계약은 있지만 runtime slot/caller가 없습니다. 왕관 외모에서 기존 기본 액티브 사용과 왕관 전용 기술의 구현은 구분합니다. 신규 효과 설계 없이 임의 연결하지 않았습니다. 패시브5개는 별도 능동 컷씬 대상이 아닙니다.

중간 실패: initial942/76은 잘못된 모드ID·idle/down4프레임 fixture였고 final942/8은 모리중복 fixture. 모두 원인·이전로그 보존. 실제 단일 instance/캠페인 상수로 보정, assertion 실패가 row PASS로 남지 않게 수정. 최종 native 카드 연결/상태분리를 포함1012/0.

## 직접 테스트 시작

바탕화면 기존 마왕성_스킬액션_검토_748001f의 저장격리 실행 바로가기를 사용합니다(이름은 이전 버전 식별자로 유지하고 대상만 최신 별도 검토본으로 갱신). 새 게임으로 시작, ESC/메뉴→설정→전투 연출에서 계속 보기 선택 후 적용. 한번만 보기는 같은 skill/duo ID를 외모와 별개로 기억하므로 반복/승급 외모 확인에는 계속 보기가 편합니다. Space/스킵, 메뉴복귀, x1/x3전환도 확인해 주세요.

전투는 지시 기반 자동 스킬입니다. 합동기는 장착/게이지100 조건을 충족한 뒤 J(첫 합동기), K(둘째 합동기) 또는 HUD의 해당 제어로 시험합니다. 해금일/유대조건은 그대로이므로 새 게임에서 모든 승급·합동기를 즉시 사용할 수 없습니다. 현재 save를 인위적으로 해금/변경하지 않았습니다. 우선 기본 곱·핀·푸딩, 이후 곱 매복대장/금고지기, 핀 두승급, 핀+톡톡 용융갑각포, 곱+코코 달빛추격, 푸딩+모리 보호/푸딩+베베 구조를 비교하세요.

숫자1회/발사와도착피해구분/두멤버외모/배속유지/메뉴후입력복귀/지원기에서적피해없음을 봐주세요. 왕관 전용 기술과 실키·포포 액티브 미지원은 이번 테스트에서 숨기지 않습니다.


## 패시브 및 정의 전용 왕관 핸들러

- ghost_housemaid: house_spirit — 별도 능동 컷씬 대상 아님.
- graveyard_hound: return_scent — 별도 능동 컷씬 대상 아님.
- armored_beetle: scrap_shell — 별도 능동 컷씬 대상 아님.
- spider_tailor: ceiling_path — 별도 능동 컷씬 대상 아님.
- bat_courier: messenger_bag — 별도 능동 컷씬 대상 아님.
- crown_pudding_royal_bastion: passive_handler_id=crown_room_embrace; royal_skill_id=royal_jelly_bastion (왕관전용 runtime 미연결).
- crown_gob_midnight_marshal: passive_handler_id=royal_command_mark; royal_skill_id=royal_no_second_cut (왕관전용 runtime 미연결).
- crown_pynn_castle_flame_sage: passive_handler_id=three_embers_cycle; royal_skill_id=tricolor_demonfire (왕관전용 runtime 미연결).
- crown_mori_grand_mycelial_priest: passive_handler_id=spore_sacrament; royal_skill_id=royal_shared_umbrella (왕관전용 runtime 미연결).
- crown_toktok_royal_armorer: passive_handler_id=moving_forge; royal_skill_id=royal_emergency_plating (왕관전용 runtime 미연결).
- crown_popo_grand_night_courier: passive_handler_id=royal_shortest_mail_route; royal_skill_id=royal_urgent_courier (왕관전용 runtime 미연결).

현재 검토 빌드 제품6618c0998451f2eda30bc0a40ce64de0105b6f80. 첫10–20분 선택/결과 전달 검수는 이 작업 종료 후 부모가 시작하며 이번 전수 검증 도중 진행하지 않았습니다. 후속 원문의미는 evidence/MAWANGSEONG_NEXT_FIRST_DEFENSE_REVIEW.md와 기존 Hub세션 next에 기록합니다.
