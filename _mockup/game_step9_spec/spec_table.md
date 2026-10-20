# 전문화 효과·검증 표

기준: 0106 `9d1e9bf7` 위, 목표 1.3.0. 기존12 + update4 4 + 신규·보충32 = 24종×2, 중복 ID0. 설명문은 보존했다.

선택: 기존 몬스터 관리 → 스킬의 DAY2 해금/팀1명(DAY2~3)/DAY4 추가 선택·변경 불가를 재사용한다. 배치 카드나 배치 몬스터를 클릭하면 옆 정보창에서도 GPT 배지2개로 고른다. Lv3 대체 규칙은 적용하지 않았다. 로로도 전문화 가능하며 실제 합류 명단에서만 정보창을 연다.

공통 처리: stat_multipliers/stat_bonuses는 본체에 한 번, skill_mods[skill_id][field]는 기본값에 더하는 차이값, flags는 시간·위치·명중·정산 사건에 적용한다. 구 skill_upgrade는 호환 대체 경로이며 같은 항목을 이중 합산하지 않는다. 기존 실키·포포 서비스의 전문화 ID별 수치 분기도 데이터 조회로 교체했다.

직접 검사 331개, 실패0. 전문화48/48에 효과1개 이상과 수치 화살표 표시를 검사했다. 신규32개는 실제 시전·상태·정산 결과를 확인했다. 추가로 선택 잠금/영구 선택/종 불일치 거부/복사본 저장·복원/구 형식·잘못된 ID 호환/DAY29 전투 차단을 검사했다.

| 몬스터 / 전문화 ID | 이름·원문 효과 | 실제 데이터(배율·가산·스킬 차이·조건) | 개별 검사 |
|---|---|---|---|
| armored_beetle / `toktok_castle_mason` | 마왕성 석공 — 시설 수리 +18 / 보호막 +10 / 돌진 거리 -25px | `{"skill_mods":{"carapace_ram":{"distance_penalty":25.0},"patch_plates":{"facility_repair_bonus":18,"ally_shield_bonus":10}},"ai_behavior":"armor_support"}` | PASS 5 |
| armored_beetle / `toktok_shell_breaker` | 갑각 파쇄자 — 돌진 방어력 감소 -1 추가 / 돌진 피해 +20% / 수리 -12 | `{"skill_mods":{"carapace_ram":{"def_reduction_bonus":1,"damage_multiplier_bonus":0.2},"patch_plates":{"facility_repair_bonus":-12}},"ai_behavior":"armor_support"}` | PASS 4 |
| bat_courier / `popo_royal_express` | 왕성 특급 — 중계 이동 +20%·공격 간격 -14% / 회수 보류 -1초 | `{"skill_mods":{"night_relay":{"move_multiplier":0.05,"attack_interval_multiplier":-0.04},"messenger_bag":{"hold_seconds":-1}},"ai_behavior":"popo_floor_courier"}` | PASS 5 |
| bat_courier / `popo_seal_guard` | 인장 회수반 — 인장 보류 +2초·표식 피해 +10% / 중계 이동 +10% | `{"skill_mods":{"night_relay":{"move_multiplier":-0.05},"messenger_bag":{"hold_seconds":2}},"flags":{"held_thief_damage_multiplier":1.1},"ai_behavior":"popo_floor_courier"}` | PASS 5 |
| bridge_troll / `troll_gatekeeper` | 관문지기 — 통행금지 범위 2칸, 도발 4초. | `{"skill_mods":{"no_passage":{"radius_cells":0.5,"duration":1}}}` | PASS 4 |
| bridge_troll / `troll_tax_collector` | 세금 징수원 — 통행세로 떨어진 금화를 전투 후 100% 회수. | `{"flags":{"toll_recovery_ratio":1}}` | PASS 4 |
| candle_wisp / `wisp_beacon` | 등대지기 — 촛불 비추기 범위 4칸, 주변 아군 명중 시 피해 +5%. | `{"flags":{"reveal_radius_cells":4,"aura_damage_multiplier":1.05}}` | PASS 3 |
| candle_wisp / `wisp_bonfire` | 모닥불 — 촛농 뚝뚝이 주변 1칸에 화상 2초. | `{"skill_mods":{"wax_drip":{"burn_radius_cells":1,"burn_seconds":2,"burn_dps":3}}}` | PASS 4 |
| crumpled_map / `map_guide` | 진짜 길잡이 — 지도 펼치기 +25%, 범위 3칸. | `{"skill_mods":{"map_spread":{"move_multiplier":0.1,"radius_cells":1}}}` | PASS 4 |
| crumpled_map / `map_labyrinth` | 미궁 지도 — 엉터리 길안내 대상에 조사관 추가, 6초. | `{"skill_mods":{"wrong_way":{"duration":2}},"flags":{"wrong_way_investigator":true}}` | PASS 4 |
| curse_doll / `doll_guardian` | 수호 인형 — 대신 아파 줄게 40%, 대상 2명. | `{"skill_mods":{"proxy_pain":{"redirect_ratio":0.1,"max_targets":1}}}` | PASS 4 |
| curse_doll / `doll_hex_mistress` | 저주 장인 — 바느질 저주 +30% / -20%, 8초. | `{"skill_mods":{"stitch_curse":{"duration":2,"damage_taken_multiplier":0.1,"attack_multiplier":-0.05}}}` | PASS 4 |
| ghost_housemaid / `bebe_night_steward` | 야간 당번장 — 구조 보호막 +12 / 재사용 -2초 / 기본 공격 -10% | `{"stat_multipliers":{"atk":0.9},"skill_mods":{"spectral_transfer":{"shield_bonus":12,"cooldown_reduction":2.0}},"ai_behavior":"rescue_support"}` | PASS 4 |
| ghost_housemaid / `bebe_poltergeist_cleaner` | 소동 청소부 — 빗자루 피해 +30% / 밀침 +14 / 구조 보호막 -10 | `{"skill_mods":{"haunted_broom_whirl":{"damage_multiplier_bonus":0.3,"knockback_bonus":14,"rescue_shield_penalty":10},"spectral_transfer":{"shield_bonus":-10}},"ai_behavior":"rescue_support"}` | PASS 5 |
| glue_snail / `snail_fortress` | 이동식 요새 — 최대 체력 +20%, 집으로 쏙 감소율 70%. | `{"stat_multipliers":{"max_hp":1.2},"skill_mods":{"shell_retreat":{"reduction":0.1}}}` | PASS 4 |
| glue_snail / `snail_trail_layer` | 길 칠장이 — 점액 자국 2칸, 쿨다운 -2초. | `{"skill_mods":{"slime_trail":{"trap_count":1,"cooldown":-2}}}` | PASS 4 |
| goblin / `goblin_finisher` | 마무리 칼날 — 약한 적 우선 / 공격 강화 | `{"stat_multipliers":{"atk":1.18,"def":0.85},"skill_mods":{"quick_slash":{"damage_multiplier_bonus":0.3}},"ai_behavior":"wounded_hunter"}` | PASS 4 |
| goblin / `goblin_treasure_hunter` | 도둑 사냥꾼 — 도둑 우선 추격 / 이동 강화 | `{"stat_multipliers":{"max_hp":1.08,"move_speed":1.18},"skill_mods":{"quick_slash":{"damage_multiplier_bonus":0.15}},"ai_behavior":"thief_hunter"}` | PASS 4 |
| graveyard_hound / `koko_bounty_sniffer` | 현상금 냄새꾼 — 표식 피해 +12% / 지속 +1초 / 보호막 -8 | `{"skill_mods":{"scent_lock":{"marked_basic_attack_multiplier_bonus":0.12,"duration_bonus":1.0,"bark_shield_penalty":8},"home_guard_bark":{"shield_bonus":-8}},"ai_behavior":"danger_tracker"}` | PASS 5 |
| graveyard_hound / `koko_throne_shepherd` | 왕좌 양치개 — 도발 최대 3명 / 도발 중 피해 -12% / 표식 피해 추가 제거 | `{"skill_mods":{"home_guard_bark":{"max_targets_bonus":1}},"ai_behavior":"danger_tracker","legacy_flags":{"remove_marked_damage_bonus":true,"bark_damage_reduction":0.12}}` | PASS 4 |
| hollow_armor / `armor_throne_guard` | 옥좌 근위대 — 옥좌 5칸 이내 방어력 +5. | `{"flags":{"position_defense":{"room":"throne","radius_cells":5,"bonus":5}}}` | PASS 4 |
| hollow_armor / `armor_wandering_knight` | 떠돌이 기사 — 용사의 자세 쿨다운 -3초, 도발 대상 4명. | `{"skill_mods":{"hero_pose":{"cooldown":-3,"max_targets":1}}}` | PASS 4 |
| imp / `imp_artillery` | 장거리 화염술 — 화염구 사거리 / 단일 피해 강화 | `{"stat_multipliers":{"atk":1.12,"attack_range":1.18},"skill_mods":{"fireball":{"damage_bonus":12,"range_bonus":48.0}},"ai_behavior":"artillery"}` | PASS 4 |
| imp / `imp_trap_weaver` | 함정 화염술 — 가시 복도 지원 / 광역 둔화 | `{"stat_multipliers":{"max_hp":1.12,"atk":0.95},"skill_mods":{"flame_zone":{"damage_bonus":10,"slow_seconds_bonus":1.0,"slow_factor_bonus":0.12}},"ai_behavior":"trap_support"}` | PASS 4 |
| kobold_scout / `rolo_raid_captain` | 원정대장 — 원정 악명 보상 +10%, 원정 위험 -1. | `{"flags":{"raid_infamy_bonus":0.1,"raid_risk_reduction":1}}` | PASS 4 |
| kobold_scout / `rolo_trail_master` | 흔적 장인 — 가짜 발자국 감속 +10%, 범위 +1칸. | `{"skill_mods":{"false_footprints":{"radius":71.554175,"slow_factor":-0.1}}}` | PASS 4 |
| mimic_porter / `mimi_bait_master` | 미끼 장인 — 가짜 보물 유인 시간 +3초. | `{"skill_mods":{"false_treasure":{"duration_bonus":3}}}` | PASS 4 |
| mimic_porter / `mimi_vault_jaws` | 금고 이빨 — 유인된 적 첫 공격 피해 +50%. | `{"flags":{"lured_first_hit_multiplier":1.5}}` | PASS 4 |
| mole_digger / `mole_foreman` | 현장 반장 — 굴 파기 후 2초 동안 주변 아군 방어력 +3. | `{"skill_mods":{"tunnel_hop":{"ally_guard_seconds":2,"ally_guard_bonus":3,"ally_guard_radius_cells":2}}}` | PASS 4 |
| mole_digger / `mole_saboteur` | 부실 공사 감별사 — 공사 방해 행동 방해 3.5초. | `{"skill_mods":{"undermine":{"interrupt_seconds":1}}}` | PASS 4 |
| moon_tracker / `lumi_hunter` | 사냥꾼 — 표식 대상 피해 +15%. | `{"flags":{"marked_damage_multiplier":1.15}}` | PASS 4 |
| moon_tracker / `lumi_moon_guide` | 달빛 길잡이 — 표식 대상 위치를 아군 전체가 추적, 이동 +10%. | `{"flags":{"team_mark_tracking":true,"team_mark_move_multiplier":1.1}}` | PASS 4 |
| rat_union / `rats_night_shift` | 야간조 — 우르르 5연타, 쿨다운 +2초. | `{"skill_mods":{"swarm":{"hits":2,"cooldown":2}}}` | PASS 4 |
| rat_union / `rats_vault_union` | 금고 지부 — 치즈값 회수 범위 4칸, 회수한 금화 +20%. | `{"flags":{"recovery_radius_cells":4,"recovery_gold_multiplier":1.2}}` | PASS 3 |
| river_frog / `frog_bridge_watch` | 다리 망꾼 — 혀 낚시 사거리 +40, 묶기 +0.5초. | `{"skill_mods":{"tongue_snag":{"range":40,"root_seconds":0.5}}}` | PASS 4 |
| river_frog / `frog_choir` | 웅덩이 합창단 — 웅덩이 노래 범위 3칸, 방어력 +4. | `{"skill_mods":{"puddle_song":{"radius_cells":1,"def_bonus":1}}}` | PASS 4 |
| slime / `slime_gate_keeper` | 성문 파수 — 입구 고정 / 생존 강화 | `{"stat_multipliers":{"max_hp":1.15},"stat_bonuses":{"def":2},"skill_mods":{"slime_shield":{"duration_bonus":1.0,"reduction_bonus":0.05}},"ai_behavior":"entry_anchor"}` | PASS 4 |
| slime / `slime_rescue_guard` | 구조 점액 — 부상 아군 호위 / 기동 강화 | `{"stat_multipliers":{"max_hp":1.08,"move_speed":1.2},"skill_mods":{"slime_shield":{"duration_bonus":0.5,"reduction_bonus":0.03}},"ai_behavior":"ally_guard"}` | PASS 7 |
| spider_tailor / `silky_field_tailor` | 전장 수선사 — 응급 실밥 보호막 +5%p·시설 수리 12 / 거미실 대상 -1 | `{"skill_mods":{"stitch_stairway":{"max_slow_targets":-1},"emergency_thread_pull":{"shield_max_hp_ratio":0.05,"facility_repair":12}},"ai_behavior":"silky_threshold_rescue"}` | PASS 4 |
| spider_tailor / `silky_stair_warden` | 통로 파수 재봉 — 거미실 둔화 40%·내구 +1 / 구조 보호막 -3%p | `{"skill_mods":{"stitch_stairway":{"slow_multiplier":-0.05,"fire_hits_to_remove":1},"emergency_thread_pull":{"shield_max_hp_ratio":-0.03}},"ai_behavior":"silky_threshold_rescue"}` | PASS 4 |
| spore_healer / `mori_field_medic` | 야전 의무병 — 회복량 +20%, 회복 대상 2명. | `{"skill_mods":{"spore_mend":{"heal_multiplier":0.2,"max_targets":1},"cleansing_bloom":{"heal_multiplier":0.2}}}` | PASS 4 |
| spore_healer / `mori_purifier` | 정화사 — 정화 시 3초 상태이상 면역. | `{"skill_mods":{"cleansing_bloom":{"immunity_seconds":3}}}` | PASS 5 |
| stone_sentinel / `dolkong_gate_stone` | 성문석 — 입구 방어선 방어력 +5. | `{"flags":{"position_defense":{"tag":"defense_line","value":"1","bonus":5}}}` | PASS 3 |
| stone_sentinel / `dolkong_quake` | 땅울림 — 석상 파동 범위 +1칸, 1초 기절. | `{"skill_mods":{"stone_pulse":{"radius":71.554175,"stun_seconds":1}}}` | PASS 4 |
| under_bed_shadow / `shadow_lullaby` | 자장가 그림자 — 은신 중 주변 아군 회복 +2/초. | `{"flags":{"stealth_heal_per_second":2,"stealth_heal_radius_cells":2}}` | PASS 3 |
| under_bed_shadow / `shadow_nightmare` | 악몽 담당 — 까꿍 공포 3.5초, 대상 주변 1칸 적도 겁먹음. | `{"skill_mods":{"peekaboo":{"duration":1,"fear_radius_cells":1}}}` | PASS 4 |
| war_drummer / `dudum_lullaby` | 자장 북 — 리듬 대신 주변 적 공격 속도 -15%. | `{"skill_mods":{"war_rhythm":{"enemy_attack_interval_multiplier":0.17647058823529416}},"flags":{"rhythm_debuff_instead":true}}` | PASS 4 |
| war_drummer / `dudum_war_band` | 전투 악단 — 리듬 버프 범위 +1칸. | `{"skill_mods":{"war_rhythm":{"radius":71.554175}}}` | PASS 4 |

## 가정·기획과의 차이

- 1칸은 기존 전투의71.554175월드px. 범위 미지정인 은신 회복·굴 도착 보호는2칸, 은신 회복은 자신을 포함한 범위 내 생존 아군에 적용한다. 화상은 설명에 피해량이 없어 초당3,2초로 정했다. 재적용은 남은 시간을 갱신한다.
- 웅덩이 합창단은 최종 방어+4, 지도 펼치기는 최종 이동+25%, 바느질 저주는 받는 피해+30%/공격−20%, 회복+20%는 포자 재생과 정화 개화 모두에 적용한다. 포자 재생은2명, 기존 개화는 같은 방 전체다.
- 전투 악단은 기존 같은 방 아군을 유지하면서180px+1칸 반경의 다른 방 아군도 포함한다. 기존 리듬은 숫자 반경이 아닌 같은 방 판정이어서180px를 확장 반경의 기준으로 가정했다. 자장 북은180px의 적 공격 간격을1/0.85배로 바꾸고 아군 방어 버프를 주지 않는다.
- 달빛 길잡이는 표식 위치를 전원 공유하되 기존 수비 칸3칸 이동 한도·사용자 명령·강제 도발을 유지한다. 이동+10%는 표식이 살아 있는6초 동안 공유하며 전장 전체를 무제한 추격하지 않는다. 사냥꾼은 루미 자신의 표식 대상 피해에 적용한다.
- 금고 이빨은 자신이 유인한 대상마다 유인 중 첫 명중1회에 적용한다. 세금 징수원은 기존 통행세로 소지금50%가 떨어지는 규칙을 유지하고 그 금화100%를 전투 종료 때 회수한다. 회수할 금화를 즉시 도둑 소지금에서 빼서 재회수·중복 정산을 막는다.
- 금고 지부는 회수 원금100%와 추가20%를 분리한다. 추가 보상을 도난 손실에서 이중 차감하지 않는다. 실키/포포의 기존 교환 비용도 보존한다.
- 구 전문화의 +12% 표식은 기존 계수1.10→1.22(+12%p), 베베 빗자루+30%는 기존 skill_upgrade 의미인 공격 계수0.9→1.2를 유지한다. 고정 피해8은 유지하므로 전체 최종 피해×1.30과는 다르다.
- **로로 원정 위험−1은 위험 단계 표시·결과 기록에서만1 낮춘다. 기존 원정은 확률 실패/피해 판정이 없고 risk는 설명 문자열이므로 실제 실패 확률이나 피해 감소를 새로 만들지 않았다. 명시 risk_level이 없으면 기존 위험 문구 낮음=1,그 외=2로 표시 단계를 가정했다.** 악명은 기존 지휘+10%에 추가10%를 합산한다. 질문을 남겼으며 답변 없으면 이 해석으로 사용자 확인 대기다.
- 시설 수리는 기존 시설HP 훼손에 적용하며0106 공병의 일시 무력화 시간을 줄이는 효과로 바꾸지 않았다. 기존6개 고유 배지 보존, 배지가 없던42개는 GPT 공통 배지2개를 재사용한다. 종별48개 고유 그림을 생성한 것은 아니다. 실제 알파0..255 검증, NEXON Maplestory 사용. 선택 확정 후 상시·스킬·조건 수치의 전후 화살표를 보여주며 긴 내용은 툴팁으로 제공한다.

증거: `spec_results.json`, `direct_checks.json`, `capture_checks.json`, `spec_choose.png`, `spec_info.png`, `spec_battle.png`. PNG·JSON은 로컬 검수 산출물이며 소스 커밋에 넣지 않는다. 전체 회귀·전체 캠페인·export·별도 검수 에이전트는 미요청/미실행. **사용자 확인 대기.**
