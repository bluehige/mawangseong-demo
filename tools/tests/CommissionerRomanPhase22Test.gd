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
	_test_data_wave_and_operations()
	await _test_budget_and_three_phases()
	print("COMMISSIONER_ROMAN_PHASE22_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS", assertion_count])
	get_tree().quit(1 if failed else 0)


func _guild_run() -> Dictionary:
	var profile := FrontServiceScript.default_update3_profile()
	profile["rival_relations"]["roman"] = 45
	var selected := FrontServiceScript.select_front(profile, FrontServiceScript.new_cycle_active_run(2), FrontServiceScript.GUILD_FRONT_ID, DataRegistry.update3_fronts)
	return HeartServiceScript.select_heart(selected.get("profile", {}), selected.get("active_run", {}), "heart_stonebone", DataRegistry.update3_castle_hearts).get("active_run", {}).duplicate(true)


func _test_data_wave_and_operations() -> void:
	var enemy: Dictionary = DataRegistry.enemy("guild_commissioner_roman")
	_expect(str(enemy.get("character_id", "")) == "CHR_ROMAN_COMMISSIONER" and str(enemy.get("behavior_handler", "")) == "guild_commissioner_roman", "총감사관 로만 캐릭터·행동 처리기 연결")
	_expect(is_equal_approx(float(enemy.get("threat", 0.0)), 6.10), "위협도 6.10")
	_expect(int(enemy.get("max_hp", 0)) == 500 and int(enemy.get("atk", 0)) == 22 and int(enemy.get("def", 0)) == 10, "HP 500·ATK 22·DEF 10")
	_expect(int(enemy.get("move_speed", 0)) == 96 and int(enemy.get("attack_range", 0)) == 62 and is_equal_approx(float(enemy.get("attack_interval", 0.0)), 1.05), "이동 96·사거리 62·공격 간격 1.05")
	_expect(int(enemy.get("morale", 0)) == 130 and enemy.get("skills", []).size() == 4, "사기 130·스킬 4종")
	var frame_count := 0
	for file_name in DirAccess.get_files_at("res://assets/sprites/enemies"):
		for pattern in ["enemy_roman_idle_down_*.png", "enemy_roman_move_down_*.png", "enemy_roman_attack_down_*.png", "enemy_roman_skill_down_*.png", "enemy_roman_down_*.png"]:
			if file_name.match(pattern):
				frame_count += 1
				break
	_expect(not bool(enemy.get("placeholder_art", true)) and frame_count == 16 and FileAccess.file_exists(str(DataRegistry.character("CHR_ROMAN_COMMISSIONER").get("portrait", {}).get("base", ""))), "승인된 로만 16프레임·초상화 연결")
	_expect(is_equal_approx(float(DataRegistry.skill("asset_freeze").get("telegraph_seconds", 0.0)), 1.0) and int(DataRegistry.skill("asset_freeze").get("cancel_damage", 0)) == 50, "자산 동결 1초 예고·피해 50 취소")
	_expect(int(DataRegistry.skill("mercenary_invoice").get("budget_cost", 0)) == 2 and int(DataRegistry.skill("mercenary_invoice").get("max_calls", 0)) == 2 and is_equal_approx(float(DataRegistry.skill("mercenary_invoice").get("cast_seconds", 0.0)), 1.3), "용병 예산 2·최대 2명·호출 1.3초")
	var modifier := FrontServiceScript.day_defense_modifier(_guild_run(), 30, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays)
	var manager = WaveManagerScript.new()
	manager.setup(30, DataRegistry.waves, {"guild": modifier})
	_expect(manager.total_to_spawn == 9 and _count(manager.schedule, "guild_commissioner_roman") == 1 and _count(manager.schedule, "official_hero_leon") == 0, "길드 DAY30 9명·총감사관 1명으로 교체")
	var op_a: Dictionary = DataRegistry.update3_front_operations["d28_guild_ledger_forgery"]["defense_modifier"]
	var manager_a = WaveManagerScript.new()
	manager_a.setup(30, DataRegistry.waves, {"guild": modifier, "operation": op_a})
	_expect(manager_a.total_to_spawn == 8 and _count(manager_a.schedule, "ledger_binder") == 0 and int(op_a.get("roman_start_budget_delta", 0)) == -1, "작전 A 장부술사 제거·시작 예산 -1")
	var op_b: Dictionary = DataRegistry.update3_front_operations["d28_guild_payroll_cut"]["defense_modifier"]
	var manager_b = WaveManagerScript.new()
	manager_b.setup(30, DataRegistry.waves, {"guild": modifier, "operation": op_b})
	_expect(manager_b.total_to_spawn == 10 and _count(manager_b.schedule, "bounty_tracker") == 2 and int(op_b.get("roman_mercenary_call_max", 0)) == 1, "작전 B 추적자 +1·용병 호출 상한 1")


func _test_budget_and_three_phases() -> void:
	var host = MainScene.instantiate()
	add_child(host)
	await get_tree().process_frame
	var game = host.get_node("GameRoot")
	game._set_campaign_save_path_for_tests("")
	game.current_screen = Constants.SCREEN_COMBAT
	game.combat_paused = true
	game.monster_units.clear()
	game.enemy_units.clear()
	var supports: Array = []
	for support_id in ["bounty_tracker", "combat_alchemist", "ledger_binder"]:
		var support = game._create_unit(support_id, DataRegistry.enemy(support_id).duplicate(true), Constants.FACTION_ENEMY, "entrance")
		game.enemy_units.append(support)
		supports.append(support)
	game.combat_scene.spawn_enemy("guild_commissioner_roman")
	var roman = game.enemy_units.back()
	var state: Dictionary = game.combat_scene.commissioner_roman_states[roman.get_instance_id()]
	_expect(int(state.get("budget", -1)) == 3 and state.get("budget_contributors", {}).size() == 3, "생존 길드 지원 적 3명으로 시작 예산 3")
	supports[0].hp = 0
	supports[0].down = true
	game.combat_scene._update_roman_budget_contributors(state)
	_expect(int(state.get("budget", -1)) == 2, "지원 적 처치 시 미사용 예산 1 제거")
	game.combat_scene._roman_support_facility_completed(supports[1])
	state = game.combat_scene.commissioner_roman_states[roman.get_instance_id()]
	_expect(int(state.get("budget", -1)) == 3, "지원 적 시설 공격 완료 시 예산 +1")
	state["freeze_cooldown"] = 0.0
	var freeze_started: String = str(game.combat_scene._update_roman_asset_freeze(roman, state, 0.01))
	_expect(freeze_started == "started" and str(state.get("freeze_mode", "")) == "telegraph" and int(state.get("budget", -1)) == 2, "1단계 자산 동결 예고·예산 1 소비")
	roman.receive_damage(50)
	var freeze_cancelled: String = str(game.combat_scene._update_roman_asset_freeze(roman, state, 0.01))
	_expect(freeze_cancelled == "cancelled" and int(state.get("stress", 0)) == 1 and game.combat_scene.roman_asset_freezes_cancelled == 1, "피해 50으로 동결 취소·감사 스트레스 +1")
	_expect(is_equal_approx(float(state.get("freeze_cooldown", 0.0)), 10.0), "첫 취소 시 기존 스트레스 반영 전 10초 재사용 대기")
	roman.hp = int(floor(float(roman.max_hp) * 0.69))
	state["budget"] = 4
	state["freeze_mode"] = "idle"
	state["freeze_cooldown"] = 20.0
	game.combat_scene._update_guild_commissioner_roman(0.01)
	state = game.combat_scene.commissioner_roman_states[roman.get_instance_id()]
	_expect(int(state.get("phase", 0)) == 2 and str(state.get("mercenary_mode", "")) == "casting" and int(state.get("budget", -1)) == 2, "HP 70% 이하 용병 호출·예산 2 소비")
	_expect(is_zero_approx(float(roman.boss_move_multiplier)) and is_equal_approx(float(state.get("mercenary_timer", 0.0)), 1.3), "호출 중 1.3초 이동 불가")
	game.combat_scene._update_roman_mercenary_invoice(roman, state, 1.31)
	_expect(int(state.get("mercenary_calls", 0)) == 1 and game.combat_scene.roman_mercenaries_summoned == 1, "첫 용병 한 명 호출 완료")
	var summoned_ids: Array = state.get("summoned_mercenaries", {}).keys()
	var mercenary = instance_from_id(int(summoned_ids[0]))
	mercenary.hp = 0
	mercenary.down = true
	game.combat_scene._update_roman_summoned_mercenaries(state, 1.0)
	_expect(game.combat_scene.roman_fast_mercenary_kills == 1 and int(state.get("stress", 0)) == 2, "호출 용병 6초 내 처치 시 스트레스 +1")
	state["budget"] = 5
	roman.hp = int(floor(float(roman.max_hp) * 0.34))
	game.combat_scene._update_guild_commissioner_roman(0.01)
	state = game.combat_scene.commissioner_roman_states[roman.get_instance_id()]
	_expect(int(state.get("phase", 0)) == 3 and bool(state.get("emergency_used", false)), "HP 35% 이하 긴급 예산 1회 발동")
	_expect(int(roman.duo_barrier) == 72 and int(state.get("budget", -1)) == 1, "예산 4를 보호막 72로 전환·상한 적용")
	_expect(int(state.get("stress", 0)) == 4 and is_equal_approx(float(roman.boss_move_multiplier), 0.94), "긴급 예산 후 스트레스 +2·3중첩 이상 이동 -6%")
	game.combat_scene._roman_add_stress(roman, state, 1, "test")
	_expect(int(state.get("stress", 0)) == 5 and bool(state.get("paperwork_triggered", false)) and float(roman.action_interrupt_timer) >= 2.0, "스트레스 5에서 서류 정리 2초 경직 1회")
	game.combat_scene._roman_add_stress(roman, state, 1, "repeat")
	_expect(int(state.get("stress", 0)) == 5, "감사 스트레스 상한 5·경직 반복 없음")
	state["emergency_used"] = false
	state["budget"] = 0
	roman.duo_barrier = 0
	game.combat_scene._activate_roman_emergency_budget(roman, state)
	_expect(int(roman.duo_barrier) == 18 and int(state.get("budget", -1)) == 0, "예산 0이어도 최소 보호막 18·보스 진행 가능")
	state["mercenary_calls"] = int(state.get("mercenary_call_max", 2))
	state["mercenary_mode"] = "idle"
	state["mercenary_cooldown"] = 0.0
	state["budget"] = 5
	game.combat_scene._update_roman_mercenary_invoice(roman, state, 20.0)
	_expect(str(state.get("mercenary_mode", "")) == "idle" and int(state.get("mercenary_calls", 0)) <= 2, "용병 최대 2명·무한 소환 차단")
	host.queue_free()
	await get_tree().process_frame


func _count(schedule: Array, enemy_id: String) -> int:
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
	push_error("[CommissionerRomanPhase22] FAIL: %s" % message)
