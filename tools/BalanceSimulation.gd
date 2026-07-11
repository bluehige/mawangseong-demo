extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const MAX_SIM_SECONDS = 120.0
const PHYSICS_STEP = 1.0 / 60.0
const SIM_TIME_SCALE = 4.0
const TUTORIAL_BALANCE_RANGES = {
	"DAY1_AUTO": {"min": 38.0, "max": 50.0, "monster_down_max": 1},
	"DAY2_TRAP_DIRECTIVE": {"min": 30.0, "max": 45.0, "monster_down_max": 2},
	"DAY3_ASSISTED": {"min": 50.0, "max": 65.0, "monster_down_max": 1}
}
const TUTORIAL_BALANCE_SCENARIOS = ["DAY1_AUTO", "DAY2_TRAP_DIRECTIVE", "DAY3_ASSISTED"]
const CORE_CHOICE_SCENARIOS = ["DAY2_DIRECTIVE_DEFENSE", "DAY2_DIRECTIVE_ALL_OUT"]
const FACILITY_CHOICE_SCENARIOS = ["DAY2_FACILITY_NEUTRAL", "DAY2_FACILITY_WATCH", "DAY2_FACILITY_BARRACKS", "DAY2_FACILITY_RECOVERY"]
const ACTIVITY_GROWTH_SCENARIOS = ["DAY1_AUTO", "DAY2_FACILITY_NEUTRAL", "DAY2_FACILITY_WATCH", "DAY2_FACILITY_BARRACKS", "DAY2_FACILITY_RECOVERY"]
const SPECIALIZATION_CHOICE_SCENARIOS = [
	"DAY2_SPEC_SLIME_GATE",
	"DAY2_SPEC_SLIME_RESCUE",
	"DAY2_SPEC_GOBLIN_THIEF",
	"DAY2_SPEC_GOBLIN_FINISHER",
	"DAY2_SPEC_IMP_ARTILLERY",
	"DAY2_SPEC_IMP_TRAP"
]
const COMBINATION_CHOICE_SCENARIOS = [
	"DAY2_COMBO_THIEF_LOCK",
	"DAY2_COMBO_FAST_BARRACKS",
	"DAY2_COMBO_SAFE_RECOVERY",
	"DAY2_COMBO_TRAP_BURST"
]

var current_logs: Array[String] = []

func _ready() -> void:
	var log_collector = Callable(self, "_collect_log")
	if not SignalBus.log_added.is_connected(log_collector):
		SignalBus.log_added.connect(log_collector)
	call_deferred("_run")

func _run() -> void:
	Engine.time_scale = SIM_TIME_SCALE
	var scenario_filter = _scenario_filter()
	var assert_tutorial_balance = _has_user_arg("--assert-tutorial-balance")
	var assert_core_choices = _has_user_arg("--assert-core-choices")
	var assert_facility_choices = _has_user_arg("--assert-facility-choices")
	var assert_activity_growth = _has_user_arg("--assert-activity-growth")
	var assert_specialization_choices = _has_user_arg("--assert-specialization-choices")
	var assert_choice_value = _has_user_arg("--assert-choice-value")
	var scenarios = [
		{"name": "DAY1_AUTO", "day": 1, "setup": "auto", "assist": "none"},
		{"name": "DAY2_AUTO", "day": 2, "setup": "auto", "assist": "none"},
		{"name": "DAY2_TRAP_DIRECTIVE", "day": 2, "setup": "trap_lure", "assist": "none"},
		{"name": "DAY2_DIRECTIVE_DEFENSE", "day": 2, "setup": "directive_defense", "assist": "none"},
		{"name": "DAY2_DIRECTIVE_ALL_OUT", "day": 2, "setup": "directive_all_out", "assist": "none"},
		{"name": "DAY2_FACILITY_NEUTRAL", "day": 2, "setup": "facility_neutral", "assist": "none"},
		{"name": "DAY2_FACILITY_WATCH", "day": 2, "setup": "facility_watch", "assist": "none"},
		{"name": "DAY2_FACILITY_BARRACKS", "day": 2, "setup": "facility_barracks", "assist": "none"},
		{"name": "DAY2_FACILITY_RECOVERY", "day": 2, "setup": "facility_recovery", "assist": "none"},
		{"name": "DAY3_AUTO", "day": 3, "setup": "auto", "assist": "none"},
		{"name": "DAY3_ASSISTED", "day": 3, "setup": "trap_lure_defense", "assist": "active_skills"},
		{"name": "DAY2_SPEC_SLIME_GATE", "day": 2, "setup": "specialization_slime_gate_keeper", "assist": "active_skills"},
		{"name": "DAY2_SPEC_SLIME_RESCUE", "day": 2, "setup": "specialization_slime_rescue_guard", "assist": "active_skills"},
		{"name": "DAY2_SPEC_GOBLIN_THIEF", "day": 2, "setup": "specialization_goblin_treasure_hunter", "assist": "active_skills"},
		{"name": "DAY2_SPEC_GOBLIN_FINISHER", "day": 2, "setup": "specialization_goblin_finisher", "assist": "active_skills"},
		{"name": "DAY2_SPEC_IMP_ARTILLERY", "day": 2, "setup": "specialization_imp_artillery", "assist": "active_skills"},
		{"name": "DAY2_SPEC_IMP_TRAP", "day": 2, "setup": "specialization_imp_trap_weaver", "assist": "active_skills"},
		{"name": "DAY2_COMBO_THIEF_LOCK", "day": 2, "setup": "combo_thief_lock", "assist": "active_skills"},
		{"name": "DAY2_COMBO_FAST_BARRACKS", "day": 2, "setup": "combo_fast_barracks", "assist": "active_skills"},
		{"name": "DAY2_COMBO_SAFE_RECOVERY", "day": 2, "setup": "combo_safe_recovery", "assist": "none"},
		{"name": "DAY2_COMBO_TRAP_BURST", "day": 2, "setup": "combo_trap_burst", "assist": "active_skills"},
		{"name": "DAY8_GROWTH_PREVIEW", "day": 8, "setup": "regular_campaign", "assist": "active_skills"},
		{"name": "DAY9_INVESTIGATOR", "day": 9, "setup": "regular_campaign", "assist": "active_skills"},
		{"name": "DAY10_CHAPTER_CLOSE", "day": 10, "setup": "regular_campaign", "assist": "active_skills"},
		{"name": "DAY11_KINGDOM_NOTICE", "day": 11, "setup": "regular_campaign", "assist": "active_skills"},
		{"name": "DAY12_FIRST_PROMOTION", "day": 12, "setup": "first_promotion_slime", "assist": "active_skills"},
		{"name": "DAY12_FIRST_PROMOTION_SLIME", "day": 12, "setup": "first_promotion_slime", "assist": "active_skills"},
		{"name": "DAY12_FIRST_PROMOTION_GOBLIN", "day": 12, "setup": "first_promotion_goblin", "assist": "active_skills"},
		{"name": "DAY12_FIRST_PROMOTION_IMP", "day": 12, "setup": "first_promotion_imp", "assist": "active_skills"},
		{"name": "DAY13_SHIELDBEARER_SLIME", "day": 13, "setup": "first_promotion_slime", "assist": "active_skills"},
		{"name": "DAY13_SHIELDBEARER_GOBLIN", "day": 13, "setup": "first_promotion_goblin", "assist": "active_skills"},
		{"name": "DAY13_SHIELDBEARER_IMP", "day": 13, "setup": "first_promotion_imp", "assist": "active_skills"},
		{"name": "DAY14_STAGE_TWO_REVIEW_SLIME", "day": 14, "setup": "first_promotion_slime", "assist": "active_skills"},
		{"name": "DAY14_STAGE_TWO_REVIEW_GOBLIN", "day": 14, "setup": "first_promotion_goblin", "assist": "active_skills"},
		{"name": "DAY14_STAGE_TWO_REVIEW_IMP", "day": 14, "setup": "first_promotion_imp", "assist": "active_skills"},
		{"name": "DAY15_SELEN_BOSS_SLIME", "day": 15, "setup": "first_promotion_slime", "assist": "active_skills"},
		{"name": "DAY15_SELEN_BOSS_GOBLIN", "day": 15, "setup": "first_promotion_goblin", "assist": "active_skills"},
		{"name": "DAY15_SELEN_BOSS_IMP", "day": 15, "setup": "first_promotion_imp", "assist": "active_skills"}
	]
	var assert_scenario_names = _assert_scenario_names({
		"tutorial_balance": assert_tutorial_balance,
		"core_choices": assert_core_choices,
		"facility_choices": assert_facility_choices,
		"activity_growth": assert_activity_growth,
		"specialization_choices": assert_specialization_choices,
		"choice_value": assert_choice_value
	})
	var results: Array[Dictionary] = []
	print("BALANCE_SIMULATION: START")
	_print_header()
	for scenario in scenarios:
		if scenario_filter != "" and str(scenario["name"]) != scenario_filter:
			continue
		if scenario_filter == "" and not assert_scenario_names.is_empty() and not assert_scenario_names.has(str(scenario["name"])):
			continue
		var result = await _run_scenario(scenario)
		results.append(result)
		_print_result(result)
		await get_tree().process_frame
	Engine.time_scale = 1.0
	for result in results:
		print("BALANCE_RESULT %s" % JSON.stringify(result))
	var failed = false
	if assert_tutorial_balance:
		failed = not _assert_tutorial_balance(results)
	if assert_core_choices:
		failed = not _assert_core_choices(results) or failed
	if assert_facility_choices:
		failed = not _assert_facility_choices(results) or failed
	if assert_activity_growth:
		failed = not _assert_activity_growth(results) or failed
	if assert_specialization_choices:
		failed = not _assert_specialization_choices(results) or failed
	if assert_choice_value:
		failed = not _assert_choice_value(results) or failed
	print("BALANCE_SIMULATION: END")
	get_tree().quit(1 if failed else 0)

func _assert_scenario_names(flags: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	if bool(flags.get("tutorial_balance", false)):
		_add_assert_names(result, TUTORIAL_BALANCE_SCENARIOS)
	if bool(flags.get("core_choices", false)):
		_add_assert_names(result, CORE_CHOICE_SCENARIOS)
	if bool(flags.get("facility_choices", false)):
		_add_assert_names(result, FACILITY_CHOICE_SCENARIOS)
	if bool(flags.get("activity_growth", false)):
		_add_assert_names(result, ACTIVITY_GROWTH_SCENARIOS)
	if bool(flags.get("specialization_choices", false)):
		_add_assert_names(result, SPECIALIZATION_CHOICE_SCENARIOS)
	if bool(flags.get("choice_value", false)):
		_add_assert_names(result, COMBINATION_CHOICE_SCENARIOS)
	return result

func _add_assert_names(target: Dictionary, names: Array) -> void:
	for scenario_name in names:
		target[str(scenario_name)] = true

func _scenario_filter() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--scenario="):
			return argument.trim_prefix("--scenario=")
	return ""

func _has_user_arg(expected: String) -> bool:
	for argument in OS.get_cmdline_user_args():
		if argument == expected:
			return true
	return false

func _run_scenario(scenario: Dictionary) -> Dictionary:
	current_logs.clear()
	var game = GameRootScene.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame
	if game.has_method("_debug_skip_onboarding"):
		game._debug_skip_onboarding()
		await get_tree().process_frame
	GameState.day = int(scenario["day"])
	_apply_setup(game, str(scenario.get("setup", "auto")))
	game._start_combat()
	await get_tree().physics_frame
	var elapsed = 0.0
	var skill_uses = 0
	var thief_reached_treasure = false
	while game.current_screen != Constants.SCREEN_RESULT and elapsed < MAX_SIM_SECONDS:
		skill_uses += _apply_assist(game, str(scenario.get("assist", "none")), elapsed)
		if _any_thief_in_treasure(game):
			thief_reached_treasure = true
		await get_tree().physics_frame
		elapsed += PHYSICS_STEP * SIM_TIME_SCALE
	var result = _collect_result(game, scenario, elapsed, skill_uses, thief_reached_treasure)
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	return result

func _apply_setup(game: Node, setup: String) -> void:
	var specialization_id = _specialization_for_setup(setup)
	if specialization_id != "":
		_choose_specialization(game, specialization_id)
	elif GameState.day in [2, 3] and game._early_specialization_required_for_current_day():
		game._choose_early_specialization("goblin", "goblin_treasure_hunter")
		game._set_screen(Constants.SCREEN_MANAGEMENT)
	match setup:
		"directive_defense":
			game._set_global_directive(Constants.DIRECTIVE_DEFENSE)
		"directive_all_out":
			game._set_global_directive(Constants.DIRECTIVE_ALL_OUT)
		"trap_lure":
			if game.rooms.has("slot_01"):
				game._change_room_facility("slot_01", "watch_post")
			game.selected_room = "spike_corridor"
			game._set_room_directive(Constants.ROOM_DIRECTIVE_TRAP_LURE)
			game._set_global_directive(Constants.DIRECTIVE_ALL_OUT)
		"trap_lure_defense":
			if game.rooms.has("slot_01"):
				game._change_room_facility("slot_01", "watch_post")
			game.selected_room = "spike_corridor"
			game._set_room_directive(Constants.ROOM_DIRECTIVE_TRAP_LURE)
			game._set_global_directive(Constants.DIRECTIVE_DEFENSE)
		"specialization_slime_gate_keeper", "specialization_slime_rescue_guard", "specialization_goblin_treasure_hunter", "specialization_goblin_finisher", "specialization_imp_artillery", "specialization_imp_trap_weaver":
			_apply_choice_value_setup(game, "watch_post", Constants.DIRECTIVE_DEFENSE, Constants.ROOM_DIRECTIVE_TRAP_LURE)
		"combo_thief_lock":
			_apply_choice_value_setup(game, "watch_post", Constants.DIRECTIVE_DEFENSE, Constants.ROOM_DIRECTIVE_TRAP_LURE)
		"combo_fast_barracks":
			_apply_choice_value_setup(game, "barracks", Constants.DIRECTIVE_ALL_OUT, Constants.ROOM_DIRECTIVE_TRAP_LURE)
		"combo_safe_recovery":
			_apply_choice_value_setup(game, "recovery", Constants.DIRECTIVE_SURVIVAL, Constants.ROOM_DIRECTIVE_RETREAT)
		"combo_trap_burst":
			_apply_choice_value_setup(game, "watch_post", Constants.DIRECTIVE_ALL_OUT, Constants.ROOM_DIRECTIVE_TRAP_LURE)
		"facility_neutral":
			_apply_facility_comparison_setup(game, "build_slot")
		"facility_watch":
			_apply_facility_comparison_setup(game, "watch_post")
		"facility_barracks":
			_apply_facility_comparison_setup(game, "barracks")
		"facility_recovery":
			_apply_facility_comparison_setup(game, "recovery")
		"regular_campaign":
			_apply_regular_campaign_setup(game)
			if game.rooms.has("slot_01"):
				game._change_room_facility("slot_01", "watch_post")
			game.selected_room = "spike_corridor"
			game._set_room_directive(Constants.ROOM_DIRECTIVE_TRAP_LURE)
			game._set_global_directive(Constants.DIRECTIVE_ALL_OUT)
		"first_promotion_slime":
			_apply_first_promotion_setup(game, "slime")
			if game.rooms.has("slot_01"):
				game._change_room_facility("slot_01", "watch_post")
			game.selected_room = "spike_corridor"
			game._set_room_directive(Constants.ROOM_DIRECTIVE_TRAP_LURE)
			game._set_global_directive(Constants.DIRECTIVE_ALL_OUT)
		"first_promotion_goblin":
			_apply_first_promotion_setup(game, "goblin")
			if game.rooms.has("slot_01"):
				game._change_room_facility("slot_01", "watch_post")
			game.selected_room = "spike_corridor"
			game._set_room_directive(Constants.ROOM_DIRECTIVE_TRAP_LURE)
			game._set_global_directive(Constants.DIRECTIVE_ALL_OUT)
		"first_promotion_imp":
			_apply_first_promotion_setup(game, "imp")
			if game.rooms.has("slot_01"):
				game._change_room_facility("slot_01", "watch_post")
			game.selected_room = "spike_corridor"
			game._set_room_directive(Constants.ROOM_DIRECTIVE_TRAP_LURE)
			game._set_global_directive(Constants.DIRECTIVE_ALL_OUT)
		_:
			game._set_global_directive(Constants.DIRECTIVE_DEFENSE)

func _specialization_for_setup(setup: String) -> String:
	match setup:
		"specialization_slime_gate_keeper", "combo_safe_recovery":
			return "slime_gate_keeper"
		"specialization_slime_rescue_guard":
			return "slime_rescue_guard"
		"specialization_goblin_treasure_hunter", "combo_thief_lock":
			return "goblin_treasure_hunter"
		"specialization_goblin_finisher", "combo_fast_barracks":
			return "goblin_finisher"
		"specialization_imp_artillery":
			return "imp_artillery"
		"specialization_imp_trap_weaver", "combo_trap_burst":
			return "imp_trap_weaver"
	return ""

func _choose_specialization(game: Node, specialization_id: String) -> void:
	var rule: Dictionary = DataRegistry.specialization(specialization_id)
	var monster_id = str(rule.get("monster_id", ""))
	if monster_id == "":
		return
	game._choose_early_specialization(monster_id, specialization_id)
	game._set_screen(Constants.SCREEN_MANAGEMENT)

func _apply_choice_value_setup(game: Node, facility_id: String, global_directive: String, room_directive: String) -> void:
	match facility_id:
		"watch_post":
			game._apply_facility_to_room("slot_01", "watch_post")
		"recovery":
			_move_unique_facility_to_slot(game, "recovery")
			if game.monster_roster.has("slime"):
				game.monster_roster["slime"]["room"] = "slot_01"
			if game.monster_roster.has("imp"):
				game.monster_roster["imp"]["room"] = "slot_01"
		_:
			game._apply_facility_to_room("slot_01", "build_slot")
	if game.has_method("_relocate_invalid_monsters"):
		game._relocate_invalid_monsters()
	game.selected_room = "spike_corridor"
	game._set_room_directive(room_directive)
	game._set_global_directive(global_directive)

func _move_unique_facility_to_slot(game: Node, facility_id: String) -> void:
	for room_id in game.rooms.keys():
		if str(room_id) == "slot_01":
			continue
		if str(game.rooms[room_id].get("facility_role", "")) == facility_id and game.has_method("_can_change_room_facility") and game._can_change_room_facility(str(room_id)):
			game._apply_facility_to_room(str(room_id), "build_slot")
	game._apply_facility_to_room("slot_01", facility_id)

func _apply_facility_comparison_setup(game: Node, facility_id: String) -> void:
	game._apply_facility_to_room("barracks", "build_slot")
	game._apply_facility_to_room("recovery", "build_slot")
	game._apply_facility_to_room("slot_01", facility_id)
	game.monster_roster["slime"]["room"] = "slot_01"
	game.monster_roster["goblin"]["room"] = "slot_01"
	game.monster_roster["imp"]["room"] = "center"
	game._set_global_directive(Constants.DIRECTIVE_SURVIVAL)

func _apply_regular_campaign_setup(game: Node) -> void:
	GameState.gold = 420
	GameState.mana = 260
	GameState.demon_lord_hp = GameState.demon_lord_max_hp
	game.facility_upgrade_unlocked = true
	for monster_id in ["slime", "goblin", "imp"]:
		if game.monster_roster.has(monster_id):
			game.monster_roster[monster_id]["level"] = 2
			game.monster_roster[monster_id]["exp"] = 20
	if game.rooms.has("barracks"):
		var barracks: Dictionary = game.rooms["barracks"]
		if int(barracks.get("facility_level", 1)) < 2:
			barracks["facility_level"] = 2
			barracks["hp"] = int(barracks.get("hp", 0)) + 80
			barracks["max_monsters"] = min(5, int(barracks.get("max_monsters", 1)) + 1)
	if game.has_method("_relocate_invalid_monsters"):
		game._relocate_invalid_monsters()

func _apply_first_promotion_setup(game: Node, monster_id: String = "slime") -> void:
	_apply_regular_campaign_setup(game)
	GameState.gold = 560
	GameState.mana = 320
	GameState.infamy = 700
	if GameState.day >= 15:
		GameState.gold = 1050
		GameState.infamy = 900
	game.campaign_chapter_one_clear = true
	game.campaign_stage_two_prepared = true
	game.campaign_chapter_two_started = true
	if game.monster_roster.has(monster_id):
		game.monster_roster[monster_id]["level"] = 3
		game.monster_roster[monster_id]["exp"] = 0
		game.selected_monster_id = monster_id
		game._promote_monster(monster_id)
	game.campaign_stage_two_upgrade_funded = GameState.day >= 15 and GameState.can_pay(game._stage_two_upgrade_cost())

func _apply_assist(game: Node, assist: String, _elapsed: float) -> int:
	if assist == "none":
		return 0
	var used = 0
	if assist == "active_skills":
		used += _try_goblin_quick_slash(game)
	used += _try_imp_skills(game)
	return used

func _try_imp_skills(game: Node) -> int:
	var imp = _unit_by_id(game.monster_units, "imp")
	if imp == null or not imp.is_alive():
		return 0
	var flame_rooms = ["spike_corridor", game._room_by_facility("barracks", "")]
	if _alive_enemy_count_in_rooms(game, flame_rooms) >= 2 and imp.skill_ready("flame_zone") and GameState.mana >= 40:
		game._select_unit(imp)
		return 1 if game._use_selected_skill(1) else 0
	elif _alive_enemy_count(game) >= 1 and imp.skill_ready("fireball") and GameState.mana >= 20:
		game._select_unit(imp)
		return 1 if game._use_selected_skill(0) else 0
	return 0

func _try_goblin_quick_slash(game: Node) -> int:
	var goblin = _unit_by_id(game.monster_units, "goblin")
	if goblin == null or not goblin.is_alive() or not goblin.skill_ready("quick_slash"):
		return 0
	if _nearest_enemy_in_range(game, goblin, goblin.attack_range + 38.0) == null:
		return 0
	game._select_unit(goblin)
	return 1 if game._use_selected_skill(0) else 0

func _collect_result(game: Node, scenario: Dictionary, elapsed: float, skill_uses: int, thief_reached_treasure: bool) -> Dictionary:
	var win = bool(game.result_summary.get("win", false))
	var timed_out = game.current_screen != Constants.SCREEN_RESULT
	var monster_down = 0
	for unit in game.monster_units:
		if not unit.is_alive():
			monster_down += 1
	var thief_stole = _logs_contain("도둑이 보물을 훔쳤습니다")
	var metrics: Dictionary = game.result_summary.get("metrics", {})
	var directive_effects: Dictionary = metrics.get("directive_effects", game.directive_effect_stats)
	var facility_effects: Dictionary = metrics.get("facility_effects", game.facility_effect_stats)
	var result = {
		"name": str(scenario["name"]),
		"day": int(scenario["day"]),
		"win": win,
		"timed_out": timed_out,
		"time": elapsed,
		"throne_hp": GameState.demon_lord_hp,
		"throne_damage": GameState.demon_lord_max_hp - GameState.demon_lord_hp,
		"monster_down": monster_down,
		"monster_hp": int(metrics.get("remaining_monster_hp", 0)),
		"monster_max_hp": int(metrics.get("total_monster_hp", 0)),
		"enemy_down": game._count_downed_enemies(),
		"spawned": game.spawned_count,
		"thief_reached_treasure": thief_reached_treasure,
		"thief_stole": thief_stole,
		"stage_two_upgrade_funded": bool(game.get("campaign_stage_two_upgrade_funded")),
		"stage_two_unlock_ready": bool(game.get("campaign_stage_two_unlock_ready")),
		"skill_uses": skill_uses,
		"gold": GameState.gold,
		"mana": GameState.mana,
		"directive": str(metrics.get("directive", game.global_directive)),
		"setup": str(scenario.get("setup", "")),
		"specializations": _specialization_snapshot(game),
		"directive_effects": directive_effects.duplicate(true),
		"facility_effects": facility_effects.duplicate(true),
		"growth": game.last_growth_summary.duplicate(true),
		"monster_contributions": metrics.get("monster_contributions", {}).duplicate(true)
	}
	if timed_out or not win or thief_stole or str(scenario["name"]).begins_with("DAY2_DIRECTIVE_"):
		result["units"] = _unit_snapshot(game)
		result["recent_logs"] = current_logs.slice(max(0, current_logs.size() - 6), current_logs.size())
	return result

func _specialization_snapshot(game: Node) -> Dictionary:
	var result: Dictionary = {}
	for monster_id in ["slime", "goblin", "imp"]:
		if game.monster_roster.has(monster_id):
			var specialization_id = str(game.monster_roster[monster_id].get("specialization_id", ""))
			if specialization_id != "":
				result[monster_id] = specialization_id
	return result

func _unit_snapshot(game: Node) -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for unit in game.monster_units + game.enemy_units:
		snapshot.append({
			"id": unit.unit_id,
			"faction": unit.faction,
			"alive": unit.is_alive(),
			"room": unit.current_room,
			"assigned": unit.assigned_room,
			"goal": unit.goal_room,
			"state": unit.tactical_state,
			"hp": unit.hp,
			"x": int(round(unit.global_position.x)),
			"y": int(round(unit.global_position.y)),
			"path": unit.path_points.size()
		})
	return snapshot

func _print_results(results: Array[Dictionary]) -> void:
	print("BALANCE_SIMULATION: START")
	_print_header()
	for result in results:
		_print_result(result)
		print("BALANCE_RESULT %s" % JSON.stringify(result))
	print("BALANCE_SIMULATION: END")

func _print_header() -> void:
	print("| scenario | result | time | throne hp | monster hp | monster down | enemies | thief reached | thief stole | skill uses | gold | mana |")
	print("|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|")

func _print_result(result: Dictionary) -> void:
	var result_text = "TIMEOUT"
	if not bool(result["timed_out"]):
		result_text = "WIN" if bool(result["win"]) else "LOSS"
	print("| %s | %s | %.1f | %d | %d/%d | %d | %d/%d | %s | %s | %d | %d | %d |" % [
		str(result["name"]),
		result_text,
		float(result["time"]),
		int(result["throne_hp"]),
		int(result["monster_hp"]),
		int(result["monster_max_hp"]),
		int(result["monster_down"]),
		int(result["enemy_down"]),
		int(result["spawned"]),
		"Y" if bool(result["thief_reached_treasure"]) else "N",
		"Y" if bool(result["thief_stole"]) else "N",
		int(result["skill_uses"]),
		int(result["gold"]),
		int(result["mana"])
	])

func _assert_tutorial_balance(results: Array[Dictionary]) -> bool:
	var passed = true
	var seen: Dictionary = {}
	for result in results:
		var name = str(result.get("name", ""))
		if not TUTORIAL_BALANCE_RANGES.has(name):
			continue
		seen[name] = true
		var limits: Dictionary = TUTORIAL_BALANCE_RANGES[name]
		var time = float(result.get("time", 0.0))
		var monster_down = int(result.get("monster_down", 0))
		if bool(result.get("timed_out", false)):
			push_error("BALANCE_ASSERT FAIL %s: timed out at %.1fs" % [name, time])
			passed = false
		if not bool(result.get("win", false)):
			push_error("BALANCE_ASSERT FAIL %s: did not win" % name)
			passed = false
		if time < float(limits["min"]) or time > float(limits["max"]):
			push_error("BALANCE_ASSERT FAIL %s: time %.1fs outside %.1f-%.1fs" % [
				name,
				time,
				float(limits["min"]),
				float(limits["max"])
			])
			passed = false
		if monster_down > int(limits["monster_down_max"]):
			push_error("BALANCE_ASSERT FAIL %s: monster_down %d > %d" % [
				name,
				monster_down,
				int(limits["monster_down_max"])
			])
			passed = false
	for scenario_name in TUTORIAL_BALANCE_RANGES.keys():
		if not seen.has(scenario_name):
			push_error("BALANCE_ASSERT FAIL %s: scenario was not run" % scenario_name)
			passed = false
	if passed:
		print("BALANCE_ASSERT: PASS")
	else:
		print("BALANCE_ASSERT: FAIL")
	return passed

func _assert_core_choices(results: Array[Dictionary]) -> bool:
	var by_name: Dictionary = {}
	for result in results:
		by_name[str(result.get("name", ""))] = result
	for required_name in ["DAY2_DIRECTIVE_DEFENSE", "DAY2_DIRECTIVE_ALL_OUT"]:
		if not by_name.has(required_name):
			push_error("CORE_CHOICE_ASSERT FAIL: %s scenario was not run" % required_name)
			return false
	var defense: Dictionary = by_name["DAY2_DIRECTIVE_DEFENSE"]
	var all_out: Dictionary = by_name["DAY2_DIRECTIVE_ALL_OUT"]
	var passed := true
	if bool(defense.get("timed_out", false)) or bool(all_out.get("timed_out", false)):
		push_error("CORE_CHOICE_ASSERT FAIL: a directive comparison timed out")
		passed = false
	if int(defense.get("directive_effects", {}).get("defense_damage_reduced", 0)) <= 0:
		push_error("CORE_CHOICE_ASSERT FAIL: defense did not reduce incoming damage")
		passed = false
	if int(all_out.get("directive_effects", {}).get("all_out_bonus_damage", 0)) <= 0:
		push_error("CORE_CHOICE_ASSERT FAIL: all-out did not add outgoing damage")
		passed = false
	var minimum_hp_gap = int(ceil(float(defense.get("monster_max_hp", 0)) * 0.10))
	if int(defense.get("monster_hp", 0)) < int(all_out.get("monster_hp", 0)) + minimum_hp_gap:
		push_error("CORE_CHOICE_ASSERT FAIL: defense did not preserve at least 10 percent more monster HP than all-out")
		passed = false
	if float(defense.get("time", 0.0)) <= float(all_out.get("time", 0.0)):
		push_error("CORE_CHOICE_ASSERT FAIL: all-out was not faster than defense")
		passed = false
	var time_gap = abs(float(defense.get("time", 0.0)) - float(all_out.get("time", 0.0)))
	var result_differs = time_gap >= 0.5 or int(defense.get("monster_down", 0)) != int(all_out.get("monster_down", 0)) or int(defense.get("throne_damage", 0)) != int(all_out.get("throne_damage", 0))
	if not result_differs:
		push_error("CORE_CHOICE_ASSERT FAIL: changing only the directive did not change the result")
		passed = false
	print("CORE_CHOICE_ASSERT: %s" % ("PASS" if passed else "FAIL"))
	return passed

func _assert_facility_choices(results: Array[Dictionary]) -> bool:
	var by_name: Dictionary = {}
	for result in results:
		by_name[str(result.get("name", ""))] = result
	var required = ["DAY2_FACILITY_NEUTRAL", "DAY2_FACILITY_WATCH", "DAY2_FACILITY_BARRACKS", "DAY2_FACILITY_RECOVERY"]
	for scenario_name in required:
		if not by_name.has(scenario_name):
			push_error("FACILITY_CHOICE_ASSERT FAIL: %s scenario was not run" % scenario_name)
			return false
	var passed := true
	for scenario_name in required:
		var result: Dictionary = by_name[scenario_name]
		if bool(result.get("timed_out", false)) or not bool(result.get("win", false)):
			push_error("FACILITY_CHOICE_ASSERT FAIL: %s did not finish with a win" % scenario_name)
			passed = false
	var watch: Dictionary = by_name["DAY2_FACILITY_WATCH"].get("facility_effects", {})
	var barracks: Dictionary = by_name["DAY2_FACILITY_BARRACKS"].get("facility_effects", {})
	var recovery: Dictionary = by_name["DAY2_FACILITY_RECOVERY"].get("facility_effects", {})
	var neutral_result: Dictionary = by_name["DAY2_FACILITY_NEUTRAL"]
	var watch_result: Dictionary = by_name["DAY2_FACILITY_WATCH"]
	var barracks_result: Dictionary = by_name["DAY2_FACILITY_BARRACKS"]
	var recovery_result: Dictionary = by_name["DAY2_FACILITY_RECOVERY"]
	if int(watch.get("watch_post_bonus_damage", 0)) <= 0 or int(watch.get("watch_post_slow_applications", 0)) <= 0:
		push_error("FACILITY_CHOICE_ASSERT FAIL: watch post did not affect the battle")
		passed = false
	if float(watch_result.get("time", 0.0)) >= float(neutral_result.get("time", 0.0)):
		push_error("FACILITY_CHOICE_ASSERT FAIL: watch post did not clear faster than the neutral room")
		passed = false
	if int(barracks.get("barracks_bonus_damage", 0)) <= 0:
		push_error("FACILITY_CHOICE_ASSERT FAIL: barracks did not add offense")
		passed = false
	if int(barracks_result.get("monster_hp", 0)) < int(neutral_result.get("monster_hp", 0)) + 20:
		push_error("FACILITY_CHOICE_ASSERT FAIL: barracks did not preserve a meaningful amount of monster HP")
		passed = false
	if int(recovery.get("recovery_healing", 0)) <= 0:
		push_error("FACILITY_CHOICE_ASSERT FAIL: recovery nest did not heal any monster")
		passed = false
	if int(recovery_result.get("monster_hp", 0)) < int(neutral_result.get("monster_hp", 0)) + 40:
		push_error("FACILITY_CHOICE_ASSERT FAIL: recovery nest did not preserve a meaningful amount of monster HP")
		passed = false
	print("FACILITY_CHOICE_ASSERT: %s" % ("PASS" if passed else "FAIL"))
	return passed

func _assert_activity_growth(results: Array[Dictionary]) -> bool:
	var required = ["DAY1_AUTO", "DAY2_FACILITY_NEUTRAL", "DAY2_FACILITY_WATCH", "DAY2_FACILITY_BARRACKS", "DAY2_FACILITY_RECOVERY"]
	var by_name: Dictionary = {}
	for result in results:
		by_name[str(result.get("name", ""))] = result
	var passed := true
	var saw_individual_difference := false
	var saw_facility_exp := false
	for scenario_name in required:
		if not by_name.has(scenario_name):
			push_error("ACTIVITY_GROWTH_ASSERT FAIL: %s scenario was not run" % scenario_name)
			passed = false
			continue
		var result: Dictionary = by_name[scenario_name]
		if bool(result.get("timed_out", false)) or not bool(result.get("win", false)):
			push_error("ACTIVITY_GROWTH_ASSERT FAIL: %s did not finish with a win" % scenario_name)
			passed = false
		var rows: Array = result.get("growth", [])
		if rows.size() != 3:
			push_error("ACTIVITY_GROWTH_ASSERT FAIL: %s expected 3 growth rows, got %d" % [scenario_name, rows.size()])
			passed = false
			continue
		var shared_values: Dictionary = {}
		var activity_values: Dictionary = {}
		for row_value in rows:
			var row: Dictionary = row_value
			var shared_exp = int(row.get("shared_exp", -1))
			var activity_exp = int(row.get("activity_exp", -1))
			var breakdown: Dictionary = row.get("activity_breakdown", {})
			var breakdown_total = int(breakdown.get("attack", 0)) + int(breakdown.get("defense", 0)) + int(breakdown.get("finisher", 0)) + int(breakdown.get("facility", 0))
			shared_values[shared_exp] = true
			activity_values[activity_exp] = true
			if activity_exp < 0 or activity_exp > 8:
				push_error("ACTIVITY_GROWTH_ASSERT FAIL: %s %s activity EXP %d outside 0-8" % [scenario_name, str(row.get("monster_id", "")), activity_exp])
				passed = false
			if breakdown_total != activity_exp:
				push_error("ACTIVITY_GROWTH_ASSERT FAIL: %s %s breakdown %d != activity %d" % [scenario_name, str(row.get("monster_id", "")), breakdown_total, activity_exp])
				passed = false
			if int(row.get("exp_gain", -1)) != shared_exp + activity_exp:
				push_error("ACTIVITY_GROWTH_ASSERT FAIL: %s %s total EXP does not match shared + activity" % [scenario_name, str(row.get("monster_id", ""))])
				passed = false
			if int(breakdown.get("facility", 0)) > 0:
				saw_facility_exp = true
		if shared_values.size() != 1:
			push_error("ACTIVITY_GROWTH_ASSERT FAIL: %s shared EXP differs between defenders" % scenario_name)
			passed = false
		if activity_values.size() > 1:
			saw_individual_difference = true
	if not saw_individual_difference:
		push_error("ACTIVITY_GROWTH_ASSERT FAIL: no scenario produced individual activity differences")
		passed = false
	if not saw_facility_exp:
		push_error("ACTIVITY_GROWTH_ASSERT FAIL: no facility scenario produced facility EXP")
		passed = false
	print("ACTIVITY_GROWTH_ASSERT: %s" % ("PASS" if passed else "FAIL"))
	return passed

func _assert_specialization_choices(results: Array[Dictionary]) -> bool:
	var by_name = _results_by_name(results)
	var passed := true
	for scenario_name in SPECIALIZATION_CHOICE_SCENARIOS:
		if not by_name.has(scenario_name):
			push_error("SPECIALIZATION_CHOICE_ASSERT FAIL: %s scenario was not run" % scenario_name)
			passed = false
			continue
		var result: Dictionary = by_name[scenario_name]
		if bool(result.get("timed_out", false)) or not bool(result.get("win", false)):
			push_error("SPECIALIZATION_CHOICE_ASSERT FAIL: %s did not finish with a win" % scenario_name)
			passed = false
		if bool(result.get("thief_stole", false)):
			push_error("SPECIALIZATION_CHOICE_ASSERT FAIL: %s allowed treasure theft" % scenario_name)
			passed = false
	var expected_specializations = {
		"DAY2_SPEC_SLIME_GATE": {"slime": "slime_gate_keeper"},
		"DAY2_SPEC_SLIME_RESCUE": {"slime": "slime_rescue_guard"},
		"DAY2_SPEC_GOBLIN_THIEF": {"goblin": "goblin_treasure_hunter"},
		"DAY2_SPEC_GOBLIN_FINISHER": {"goblin": "goblin_finisher"},
		"DAY2_SPEC_IMP_ARTILLERY": {"imp": "imp_artillery"},
		"DAY2_SPEC_IMP_TRAP": {"imp": "imp_trap_weaver"}
	}
	var seen_by_monster := {"slime": {}, "goblin": {}, "imp": {}}
	var signatures := {}
	var min_time := INF
	var max_time := 0.0
	var min_hp := INF
	var max_hp := 0.0
	for scenario_name in expected_specializations.keys():
		if not by_name.has(scenario_name):
			continue
		var result: Dictionary = by_name[scenario_name]
		var expected: Dictionary = expected_specializations[scenario_name]
		var specializations: Dictionary = result.get("specializations", {})
		for monster_id in expected.keys():
			var specialization_id = str(expected[monster_id])
			if str(specializations.get(monster_id, "")) != specialization_id:
				push_error("SPECIALIZATION_CHOICE_ASSERT FAIL: %s did not apply %s to %s" % [scenario_name, specialization_id, monster_id])
				passed = false
			seen_by_monster[monster_id][specialization_id] = true
		var time = float(result.get("time", 0.0))
		var hp = float(result.get("monster_hp", 0))
		min_time = min(min_time, time)
		max_time = max(max_time, time)
		min_hp = min(min_hp, hp)
		max_hp = max(max_hp, hp)
		signatures["%d/%d/%d" % [int(round(time)), int(round(hp)), int(result.get("skill_uses", 0))]] = true
	for monster_id in ["slime", "goblin", "imp"]:
		if Dictionary(seen_by_monster[monster_id]).size() < 2:
			push_error("SPECIALIZATION_CHOICE_ASSERT FAIL: %s does not have two compared specializations" % monster_id)
			passed = false
	if signatures.size() < 4:
		push_error("SPECIALIZATION_CHOICE_ASSERT FAIL: specialization scenarios are too similar")
		passed = false
	if max_time - min_time < 3.0:
		push_error("SPECIALIZATION_CHOICE_ASSERT FAIL: specialization time spread is too small")
		passed = false
	if max_hp - min_hp < 25.0:
		push_error("SPECIALIZATION_CHOICE_ASSERT FAIL: specialization HP spread is too small")
		passed = false
	print("SPECIALIZATION_CHOICE_ASSERT: %s" % ("PASS" if passed else "FAIL"))
	return passed

func _assert_choice_value(results: Array[Dictionary]) -> bool:
	var by_name = _results_by_name(results)
	var passed := true
	for scenario_name in COMBINATION_CHOICE_SCENARIOS:
		if not by_name.has(scenario_name):
			push_error("CHOICE_VALUE_ASSERT FAIL: %s scenario was not run" % scenario_name)
			passed = false
			continue
		var result: Dictionary = by_name[scenario_name]
		if bool(result.get("timed_out", false)) or not bool(result.get("win", false)):
			push_error("CHOICE_VALUE_ASSERT FAIL: %s did not finish with a win" % scenario_name)
			passed = false
		if bool(result.get("thief_stole", false)):
			push_error("CHOICE_VALUE_ASSERT FAIL: %s allowed treasure theft" % scenario_name)
			passed = false
	if not passed:
		print("CHOICE_VALUE_ASSERT: FAIL")
		return false
	var thief_lock: Dictionary = by_name["DAY2_COMBO_THIEF_LOCK"]
	var fast_barracks: Dictionary = by_name["DAY2_COMBO_FAST_BARRACKS"]
	var safe_recovery: Dictionary = by_name["DAY2_COMBO_SAFE_RECOVERY"]
	var trap_burst: Dictionary = by_name["DAY2_COMBO_TRAP_BURST"]
	var directives_seen := {}
	for scenario_name in COMBINATION_CHOICE_SCENARIOS:
		var result: Dictionary = by_name[scenario_name]
		directives_seen[str(result.get("directive", ""))] = true
	if not directives_seen.has(Constants.DIRECTIVE_DEFENSE) or not directives_seen.has(Constants.DIRECTIVE_ALL_OUT) or not directives_seen.has(Constants.DIRECTIVE_SURVIVAL):
		push_error("CHOICE_VALUE_ASSERT FAIL: combination set does not cover defense/all-out/survival directives")
		passed = false
	var thief_watch: Dictionary = thief_lock.get("facility_effects", {})
	var fast_facility: Dictionary = fast_barracks.get("facility_effects", {})
	var safe_facility: Dictionary = safe_recovery.get("facility_effects", {})
	var trap_watch: Dictionary = trap_burst.get("facility_effects", {})
	if int(thief_watch.get("watch_post_bonus_damage", 0)) <= 0 or int(thief_watch.get("watch_post_slow_applications", 0)) <= 0:
		push_error("CHOICE_VALUE_ASSERT FAIL: thief-lock combo did not use watch-post value")
		passed = false
	if int(fast_facility.get("barracks_bonus_damage", 0)) <= 0:
		push_error("CHOICE_VALUE_ASSERT FAIL: fast-barracks combo did not use barracks value")
		passed = false
	if int(safe_facility.get("recovery_healing", 0)) <= 0:
		push_error("CHOICE_VALUE_ASSERT FAIL: safe-recovery combo did not use recovery value")
		passed = false
	if int(trap_watch.get("watch_post_bonus_damage", 0)) <= 0 or int(trap_burst.get("skill_uses", 0)) <= 0:
		push_error("CHOICE_VALUE_ASSERT FAIL: trap-burst combo did not combine watch pressure and skills")
		passed = false
	if bool(thief_lock.get("thief_reached_treasure", false)):
		push_error("CHOICE_VALUE_ASSERT FAIL: thief-lock combo still let a thief reach treasure")
		passed = false
	var min_time_name := ""
	var max_hp_name := ""
	var min_time := INF
	var max_hp := -INF
	for scenario_name in COMBINATION_CHOICE_SCENARIOS:
		var result: Dictionary = by_name[scenario_name]
		var time = float(result.get("time", 0.0))
		var hp = float(result.get("monster_hp", 0))
		if time < min_time:
			min_time = time
			min_time_name = scenario_name
		if hp > max_hp:
			max_hp = hp
			max_hp_name = scenario_name
	if min_time_name == max_hp_name:
		push_error("CHOICE_VALUE_ASSERT FAIL: fastest combo and safest combo are the same")
		passed = false
	if float(safe_recovery.get("monster_hp", 0)) < float(fast_barracks.get("monster_hp", 0)) + 30.0:
		push_error("CHOICE_VALUE_ASSERT FAIL: safe recovery does not preserve enough HP over fast barracks")
		passed = false
	if float(fast_barracks.get("time", 0.0)) >= float(safe_recovery.get("time", 0.0)):
		push_error("CHOICE_VALUE_ASSERT FAIL: fast barracks is not faster than safe recovery")
		passed = false
	var time_spread = _result_float_spread(results, COMBINATION_CHOICE_SCENARIOS, "time")
	var hp_spread = _result_float_spread(results, COMBINATION_CHOICE_SCENARIOS, "monster_hp")
	if time_spread < 8.0:
		push_error("CHOICE_VALUE_ASSERT FAIL: combination time spread %.1f is too small" % time_spread)
		passed = false
	if hp_spread < 60.0:
		push_error("CHOICE_VALUE_ASSERT FAIL: combination HP spread %.1f is too small" % hp_spread)
		passed = false
	print("CHOICE_VALUE_ASSERT: %s" % ("PASS" if passed else "FAIL"))
	return passed

func _results_by_name(results: Array[Dictionary]) -> Dictionary:
	var by_name: Dictionary = {}
	for result in results:
		by_name[str(result.get("name", ""))] = result
	return by_name

func _result_float_spread(results: Array[Dictionary], names: Array, key: String) -> float:
	var by_name = _results_by_name(results)
	var min_value := INF
	var max_value := -INF
	for scenario_name in names:
		if not by_name.has(str(scenario_name)):
			continue
		var value = float(Dictionary(by_name[str(scenario_name)]).get(key, 0.0))
		min_value = min(min_value, value)
		max_value = max(max_value, value)
	if min_value == INF or max_value == -INF:
		return 0.0
	return max_value - min_value

func _any_thief_in_treasure(game: Node) -> bool:
	var treasure_room = game._room_by_facility("treasure", "")
	for enemy in game.enemy_units:
		if enemy.is_alive() and enemy.unit_id == "thief" and enemy.current_room == treasure_room:
			return true
	return false

func _alive_enemy_count(game: Node) -> int:
	var count = 0
	for enemy in game.enemy_units:
		if enemy.is_alive():
			count += 1
	return count

func _alive_enemy_count_in_rooms(game: Node, room_ids: Array) -> int:
	var count = 0
	for enemy in game.enemy_units:
		if enemy.is_alive() and room_ids.has(enemy.current_room):
			count += 1
	return count

func _nearest_enemy_in_range(game: Node, unit: Node, range: float) -> Node:
	var nearest = null
	var best_distance := INF
	for enemy in game.enemy_units:
		if not enemy.is_alive():
			continue
		var distance = unit.global_position.distance_to(enemy.global_position)
		if distance <= range and distance < best_distance:
			nearest = enemy
			best_distance = distance
	return nearest

func _unit_by_id(units: Array, unit_id: String) -> Node:
	for unit in units:
		if unit.unit_id == unit_id:
			return unit
	return null

func _logs_contain(fragment: String) -> bool:
	for message in current_logs:
		if message.find(fragment) >= 0:
			return true
	return false

func _collect_log(message: String) -> void:
	current_logs.append(message)
