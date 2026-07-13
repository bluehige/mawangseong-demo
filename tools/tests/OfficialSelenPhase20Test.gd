extends Node

const MainScene = preload("res://scenes/main/Main.tscn")
const FrontServiceScript = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const HeartServiceScript = preload("res://scripts/systems/hearts/CastleHeartService.gd")
const WaveManagerScript = preload("res://scripts/combat/WaveManager.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_data_and_day30_wave()
	_test_charge_floor_multiplier()
	await _test_three_stage_boss()
	print("OFFICIAL_SELEN_PHASE20_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS", assertion_count])
	get_tree().quit(1 if failed else 0)


func _holy_run() -> Dictionary:
	var profile := FrontServiceScript.default_update3_profile()
	profile["rival_relations"]["selen"] = 45
	var selected := FrontServiceScript.select_front(profile, FrontServiceScript.new_cycle_active_run(2), FrontServiceScript.HOLY_FRONT_ID, DataRegistry.update3_fronts)
	return HeartServiceScript.select_heart(selected.get("profile", {}), selected.get("active_run", {}), "heart_stonebone", DataRegistry.update3_castle_hearts).get("active_run", {}).duplicate(true)


func _test_data_and_day30_wave() -> void:
	var enemy: Dictionary = DataRegistry.enemy("official_paladin_selen")
	_expect(str(enemy.get("character_id", "")) == "CHR_SELEN_OFFICIAL" and str(enemy.get("behavior_handler", "")) == "official_paladin_selen", "정식 셀렌 캐릭터·행동 처리기 연결")
	_expect(is_equal_approx(float(enemy.get("threat", 0.0)), 6.30), "위협도 6.30")
	_expect(int(enemy.get("max_hp", 0)) == 520 and int(enemy.get("atk", 0)) == 26 and int(enemy.get("def", 0)) == 12, "HP 520·ATK 26·DEF 12")
	_expect(int(enemy.get("move_speed", 0)) == 104 and int(enemy.get("attack_range", 0)) == 58 and is_equal_approx(float(enemy.get("attack_interval", 0.0)), 1.0), "이동 104·사거리 58·공격 간격 1.00")
	_expect(int(enemy.get("morale", 0)) == 135 and enemy.get("skills", []).size() == 4, "사기 135·보스 스킬 4종")
	var frame_count := 0
	var patterns := ["enemy_selen_paladin_idle_down_*.png", "enemy_selen_paladin_move_down_*.png", "enemy_selen_paladin_attack_down_*.png", "enemy_selen_paladin_skill_down_*.png", "enemy_selen_paladin_down_*.png"]
	for file_name in DirAccess.get_files_at("res://assets/sprites/enemies"):
		for pattern in patterns:
			if file_name.match(pattern):
				frame_count += 1
				break
	_expect(not bool(enemy.get("placeholder_art", true)) and frame_count == 16 and FileAccess.file_exists(str(DataRegistry.character("CHR_SELEN_OFFICIAL").get("portrait", {}).get("base", ""))), "승인된 이미지 생성 원본 기반 16프레임·정식 초상화 연결")
	_expect(float(DataRegistry.skill("inspection_seal").get("telegraph_seconds", 0.0)) >= 0.8 and int(DataRegistry.skill("inspection_seal").get("cancel_damage", 0)) == 55, "검수 예고 0.8초 이상·피해 55 대응")
	_expect(is_equal_approx(float(DataRegistry.skill("consecrated_advance").get("status_duration_multiplier", 0.0)), 0.8) and is_equal_approx(float(DataRegistry.skill("consecrated_advance").get("heart_charge_multiplier", 0.0)), 0.75), "축성 바닥 상태 -20%·심장 충전 -25%")
	_expect(int(DataRegistry.skill("mercy_barrier").get("shield", 0)) == 55 and is_equal_approx(float(DataRegistry.skill("mercy_barrier").get("damage_reduction", 0.0)), 0.22), "자비의 방벽 55·피해 감소 22%")
	var modifier := FrontServiceScript.day_defense_modifier(_holy_run(), 30, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays)
	var manager = WaveManagerScript.new()
	manager.setup(30, DataRegistry.waves, {"holy": modifier})
	_expect(manager.total_to_spawn == 9, "성정화 DAY30 총 9명 전투 예산")
	_expect(_enemy_count(manager.schedule, "official_paladin_selen") == 1 and _enemy_count(manager.schedule, "selen_trainee_paladin") == 0 and _enemy_count(manager.schedule, "official_hero_leon") == 0, "기존 최종 보스를 제거하고 정식 셀렌 1명 배치")
	var operation_a: Dictionary = DataRegistry.update3_front_operations.get("d28_holy_relic_registry_swap", {}).get("defense_modifier", {})
	var manager_a = WaveManagerScript.new()
	manager_a.setup(30, DataRegistry.waves, {"holy": modifier, "operation": operation_a})
	_expect(_enemy_count(manager_a.schedule, "reliquary_guard") == 0 and _enemy_count(manager_a.schedule, "seal_chainbearer") == 1 and is_equal_approx(float(operation_a.get("selen_first_inspection_delay", 0.0)), 3.0), "작전 A: 수호기사 -1·사슬병 +1·첫 검수 +3초")
	var operation_b: Dictionary = DataRegistry.update3_front_operations.get("d28_holy_pilgrim_detour", {}).get("defense_modifier", {})
	_expect(is_equal_approx(float(operation_b.get("spawn_delay_bonus", 0.0)), 4.0) and int(operation_b.get("count_delta_by_enemy", {}).get("choir_exorcist", 0)) == -1 and int(operation_b.get("selen_mercy_barrier_bonus", 0)) == 12, "작전 B: 도착 +4초·퇴마사 -1·방벽 +12")


func _test_charge_floor_multiplier() -> void:
	var run := _holy_run()
	run["heart"]["awakened"] = true
	run["heart"]["disabled_this_battle"] = false
	run["heart"]["charge_gain_multiplier"] = 0.75
	var reduced := HeartServiceScript.record_charge(run, "facility_damage_taken", 60, "phase20_floor", 1.0)
	var normal_run := _holy_run()
	normal_run["heart"]["awakened"] = true
	normal_run["heart"]["disabled_this_battle"] = false
	var normal := HeartServiceScript.record_charge(normal_run, "facility_damage_taken", 60, "phase20_normal", 1.0)
	_expect(int(reduced.get("gain", 0)) < int(normal.get("gain", 0)), "축성 바닥에서 실제 심장 충전 획득량 25% 감소")


func _test_three_stage_boss() -> void:
	var host = MainScene.instantiate()
	add_child(host)
	await get_tree().process_frame
	var game = host.get_node("GameRoot")
	game._set_campaign_save_path_for_tests("")
	game.current_screen = Constants.SCREEN_COMBAT
	game.combat_paused = true
	game.monster_units.clear()
	game.enemy_units.clear()
	game.combat_scene.spawn_enemy("official_paladin_selen")
	var selen = game.enemy_units[0]
	var state: Dictionary = game.combat_scene.official_selen_states[selen.get_instance_id()]
	_expect(int(state.get("phase", 0)) == 1 and str(state.get("inspection_mode", "")) == "idle", "1단계 검수 절차 초기화")
	state["inspection_cooldown"] = 0.0
	game.combat_scene._update_selen_inspection(selen, state, 0.01, false)
	_expect(str(state.get("inspection_mode", "")) == "telegraph" and float(state.get("inspection_timer", 0.0)) >= 0.8, "검수 봉인 월드 예고 시작")
	game.combat_scene._update_selen_inspection(selen, state, 1.01, false)
	selen.receive_damage(55)
	var cancelled: String = str(game.combat_scene._update_selen_inspection(selen, state, 0.01, false))
	_expect(cancelled == "cancelled" and selen.armor_break_amount == 2 and selen.armor_break_timer > 0.0, "피해 55로 검수 취소·절차 흔들림 DEF -2")
	selen.hp = int(floor(float(selen.max_hp) * 0.64))
	game.combat_scene._update_official_paladin_selen(0.01)
	state = game.combat_scene.official_selen_states[selen.get_instance_id()]
	_expect(int(state.get("phase", 0)) == 2 and is_equal_approx(float(selen.boss_move_multiplier), 0.92), "HP 65% 이하 2단계·이동 속도 -8%")
	_expect(game.combat_scene.selen_consecrated_floors.size() == 1, "축성 진군 경로 바닥 생성")
	selen.action_interrupt_timer = 3.0
	selen.seal_move_lock_timer = 3.0
	game.combat_scene._update_official_paladin_selen(0.01)
	_expect(is_zero_approx(float(selen.action_interrupt_timer)) and is_zero_approx(float(selen.seal_move_lock_timer)), "보스 완전 기절·강제 이동 봉쇄 면역")
	selen.hp = int(floor(float(selen.max_hp) * 0.34))
	game.combat_scene._update_official_paladin_selen(0.01)
	state = game.combat_scene.official_selen_states[selen.get_instance_id()]
	_expect(int(state.get("phase", 0)) == 3 and bool(state.get("final_active", false)), "HP 35% 이하 마지막 검수표 시작")
	# 첫 두 검수는 피해 집중으로 취소하고, 세 번째는 허용한다.
	for attempt in range(3):
		state["inspection_mode"] = "idle"
		state["inspection_cooldown"] = 0.0
		game.combat_scene._update_selen_final_checklist(selen, state, 0.01)
		game.combat_scene._update_selen_final_checklist(selen, state, 1.01)
		if attempt < 2:
			selen.hp -= 55
			game.combat_scene._update_selen_final_checklist(selen, state, 0.01)
		else:
			game.combat_scene._update_selen_final_checklist(selen, state, 5.01)
		state["final_wait"] = 0.0
	_expect(int(state.get("final_attempt", 0)) == 3 and int(state.get("final_cancelled", 0)) == 2, "마지막 검수 3회·취소 2회 기록")
	game.combat_scene._update_selen_final_checklist(selen, state, 0.01)
	_expect(bool(state.get("barrier_activated", false)) and int(selen.duo_barrier) == 30, "취소 2회로 최종 방벽 55에서 25 감소")
	for enemy in game.enemy_units:
		enemy.duo_barrier = 0
	game.combat_scene._update_selen_barrier(selen, state, 0.01)
	_expect(is_equal_approx(float(selen.boss_damage_taken_multiplier), 1.18) and is_equal_approx(float(state.get("vulnerable_timer", 0.0)), 2.5), "4초 내 방벽 파괴 시 2.5초간 받는 피해 +18%")
	_expect(is_equal_approx(float(selen.boss_attack_interval_multiplier), 1.2), "자비의 방벽 동안 공격 간격 +20%")
	_expect(game.combat_scene.selen_inspections_started >= 4 and game.combat_scene.selen_barrier_breaks_in_window == 1, "검수·방벽 대응 전투 지표 집계")
	host.queue_free()
	await get_tree().process_frame


func _enemy_count(schedule: Array, enemy_id: String) -> int:
	var result := 0
	for entry in schedule:
		if str(entry.get("enemy_id", "")) == enemy_id:
			result += 1
	return result


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[OfficialSelenPhase20] FAIL: %s" % message)
