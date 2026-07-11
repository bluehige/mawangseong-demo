extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const MAX_SIM_SECONDS = 120.0
const PHYSICS_STEP = 1.0 / 60.0
const SIM_TIME_SCALE = 4.0
const TUTORIAL_BALANCE_RANGES = {
	"DAY1_AUTO": {"min": 38.0, "max": 50.0, "monster_down_max": 1},
	"DAY2_TRAP_DIRECTIVE": {"min": 30.0, "max": 45.0, "monster_down_max": 2},
	"DAY3_ASSISTED": {"min": 32.0, "max": 50.0, "monster_down_max": 1, "skill_uses_min": 8}
}
const TUTORIAL_BALANCE_SCENARIOS = ["DAY1_AUTO", "DAY2_TRAP_DIRECTIVE", "DAY3_ASSISTED"]
const CORE_CHOICE_SCENARIOS = ["DAY2_DIRECTIVE_DEFENSE", "DAY2_DIRECTIVE_ALL_OUT"]
const FACILITY_CHOICE_SCENARIOS = ["DAY2_FACILITY_NEUTRAL", "DAY2_FACILITY_WATCH", "DAY2_FACILITY_BARRACKS", "DAY2_FACILITY_RECOVERY"]
const FACILITY_FRONTLINE_SCENARIOS = ["DAY2_FRONTLINE_NEUTRAL", "DAY2_FRONTLINE_BARRACKS"]
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
const COMBINATION_TREASURE_DEFENSE_SCENARIOS = [
	"DAY2_COMBO_THIEF_LOCK",
	"DAY2_COMBO_FAST_BARRACKS",
	"DAY2_COMBO_TRAP_BURST"
]
const GROWTH_CHOICE_SCENARIOS = [
	"DAY1_GROWTH_FOCUS_SLIME",
	"DAY1_GROWTH_FOCUS_GOBLIN",
	"DAY1_GROWTH_FOCUS_IMP"
]
const GROWTH_CHOICE_TARGETS = {
	"DAY1_GROWTH_FOCUS_SLIME": "slime",
	"DAY1_GROWTH_FOCUS_GOBLIN": "goblin",
	"DAY1_GROWTH_FOCUS_IMP": "imp"
}
const COMBINATION_CHOICE_LABELS = {
	"DAY2_COMBO_THIEF_LOCK": "도둑 봉쇄",
	"DAY2_COMBO_FAST_BARRACKS": "병영 속공",
	"DAY2_COMBO_SAFE_RECOVERY": "회복 생존",
	"DAY2_COMBO_TRAP_BURST": "함정 집중"
}
const FACILITY_CHOICE_LABELS = {
	"DAY2_FACILITY_NEUTRAL": "중립 방",
	"DAY2_FACILITY_WATCH": "감시 초소",
	"DAY2_FACILITY_BARRACKS": "병영",
	"DAY2_FACILITY_RECOVERY": "회복 둥지",
	"DAY2_FRONTLINE_NEUTRAL": "전선 중립 방",
	"DAY2_FRONTLINE_BARRACKS": "전선 병영"
}

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
	var assert_growth_choices = _has_user_arg("--assert-growth-choices")
	var scenarios = [
		{"name": "DAY1_AUTO", "day": 1, "setup": "auto", "assist": "none"},
		{"name": "DAY1_GROWTH_FOCUS_SLIME", "day": 1, "setup": "auto", "assist": "none", "growth_focus": "slime"},
		{"name": "DAY1_GROWTH_FOCUS_GOBLIN", "day": 1, "setup": "auto", "assist": "none", "growth_focus": "goblin"},
		{"name": "DAY1_GROWTH_FOCUS_IMP", "day": 1, "setup": "auto", "assist": "none", "growth_focus": "imp"},
		{"name": "DAY2_AUTO", "day": 2, "setup": "auto", "assist": "none"},
		{"name": "DAY2_TRAP_DIRECTIVE", "day": 2, "setup": "trap_lure", "assist": "none"},
		{"name": "DAY2_DIRECTIVE_DEFENSE", "day": 2, "setup": "directive_defense", "assist": "none"},
		{"name": "DAY2_DIRECTIVE_ALL_OUT", "day": 2, "setup": "directive_all_out", "assist": "none"},
		{"name": "DAY2_FACILITY_NEUTRAL", "day": 2, "setup": "facility_neutral", "assist": "none"},
		{"name": "DAY2_FACILITY_WATCH", "day": 2, "setup": "facility_watch", "assist": "none"},
		{"name": "DAY2_FACILITY_BARRACKS", "day": 2, "setup": "facility_barracks", "assist": "none"},
		{"name": "DAY2_FACILITY_RECOVERY", "day": 2, "setup": "facility_recovery", "assist": "none"},
		{"name": "DAY2_FRONTLINE_NEUTRAL", "day": 2, "setup": "facility_frontline_neutral", "assist": "none", "wave_override": "frontline_explorers"},
		{"name": "DAY2_FRONTLINE_BARRACKS", "day": 2, "setup": "facility_frontline_barracks", "assist": "none", "wave_override": "frontline_explorers"},
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
		{"name": "DAY15_SELEN_BOSS_IMP", "day": 15, "setup": "first_promotion_imp", "assist": "active_skills"},
		{"name": "DAY17_NIA_SECURITY_GOBLIN", "day": 17, "setup": "first_promotion_goblin", "assist": "active_skills"},
		{"name": "DAY18_MANIFEST_GOBLIN", "day": 18, "setup": "first_promotion_goblin", "assist": "active_skills", "raid_choice": "d18_forged_manifest"},
		{"name": "DAY18_TUNNEL_SLIME", "day": 18, "setup": "first_promotion_slime", "assist": "active_skills", "raid_choice": "d18_seal_smuggling_tunnel"},
		{"name": "DAY19_MANIFEST_GOBLIN", "day": 19, "setup": "first_promotion_goblin", "assist": "active_skills", "completed_raid": "d18_forged_manifest"},
		{"name": "DAY19_TUNNEL_SLIME", "day": 19, "setup": "first_promotion_slime", "assist": "active_skills", "completed_raid": "d18_seal_smuggling_tunnel"},
		{"name": "DAY20_ENGINEER_GOBLIN", "day": 20, "setup": "first_promotion_goblin", "assist": "active_skills"},
		{"name": "DAY20_ENGINEER_SLIME", "day": 20, "setup": "first_promotion_slime", "assist": "active_skills"},
		{"name": "DAY21_SELEN_RALLY_GOBLIN", "day": 21, "setup": "first_promotion_goblin", "assist": "active_skills"},
		{"name": "DAY21_SELEN_RALLY_SLIME", "day": 21, "setup": "first_promotion_slime", "assist": "active_skills"}
	]
	var assert_scenario_names = _assert_scenario_names({
		"tutorial_balance": assert_tutorial_balance,
		"core_choices": assert_core_choices,
		"facility_choices": assert_facility_choices,
		"activity_growth": assert_activity_growth,
		"specialization_choices": assert_specialization_choices,
		"choice_value": assert_choice_value,
		"growth_choices": assert_growth_choices
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
		var facility_choices_passed = _assert_facility_choices(results)
		failed = not facility_choices_passed or failed
		_write_facility_choice_report(results, facility_choices_passed)
	if assert_activity_growth:
		failed = not _assert_activity_growth(results) or failed
	if assert_specialization_choices:
		failed = not _assert_specialization_choices(results) or failed
	if assert_choice_value:
		var choice_value_passed = _assert_choice_value(results)
		failed = not choice_value_passed or failed
		_write_choice_value_report(results, choice_value_passed)
	if assert_growth_choices:
		var growth_choices_passed = _assert_growth_choices(results)
		failed = not growth_choices_passed or failed
		_write_growth_choice_report(results, growth_choices_passed)
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
		_add_assert_names(result, FACILITY_FRONTLINE_SCENARIOS)
	if bool(flags.get("activity_growth", false)):
		_add_assert_names(result, ACTIVITY_GROWTH_SCENARIOS)
	if bool(flags.get("specialization_choices", false)):
		_add_assert_names(result, SPECIALIZATION_CHOICE_SCENARIOS)
	if bool(flags.get("choice_value", false)):
		_add_assert_names(result, COMBINATION_CHOICE_SCENARIOS)
	if bool(flags.get("growth_choices", false)):
		_add_assert_names(result, GROWTH_CHOICE_SCENARIOS)
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
	_apply_completed_raid(game, str(scenario.get("completed_raid", "")))
	_apply_raid_choice(game, str(scenario.get("raid_choice", "")))
	game._start_combat()
	_apply_wave_override(game, str(scenario.get("wave_override", "")))
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
	var growth_choice_value: Dictionary = {}
	var growth_focus = str(scenario.get("growth_focus", ""))
	if game.current_screen == Constants.SCREEN_RESULT and growth_focus != "":
		growth_choice_value = _apply_growth_choice_for_audit(game, growth_focus)
	var result = _collect_result(game, scenario, elapsed, skill_uses, thief_reached_treasure)
	if not growth_choice_value.is_empty():
		game._review_growth_from_result()
		game._advance_after_result()
		await get_tree().process_frame
		growth_choice_value["day_two"] = GameState.day
		growth_choice_value["day_two_roster"] = _growth_roster_snapshot(game)
		GameState.day = 3
		growth_choice_value["day_three_without_reselection_roster"] = _growth_roster_snapshot(game)
		result["growth_choice_value"] = growth_choice_value
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	return result

func _apply_completed_raid(game: Node, mission_id: String) -> void:
	if mission_id != "" and not DataRegistry.raid_mission(mission_id).is_empty():
		game.completed_raids[mission_id] = true

func _apply_raid_choice(game: Node, mission_id: String) -> void:
	if mission_id == "":
		return
	var mission: Dictionary = DataRegistry.raid_mission(mission_id)
	if mission.is_empty():
		return
	game.completed_raids[mission_id] = true
	var modifier: Dictionary = mission.get("next_defense_modifier", {})
	if not modifier.is_empty():
		game.next_defense_modifiers[str(modifier.get("id", mission_id))] = modifier.duplicate(true)

func _apply_wave_override(game: Node, override_id: String) -> void:
	if override_id != "frontline_explorers":
		return
	game.wave_manager.setup(2, {
		"day_2": [{
			"enemy_id": "explorer",
			"count": 3,
			"spawn_delay": 0.0,
			"spawn_interval": 4.0,
			"hp_scale": 4.0,
			"atk_scale": 1.1
		}]
	})

func _apply_growth_choice_for_audit(game: Node, monster_id: String) -> Dictionary:
	var before_roster = _growth_roster_snapshot(game)
	var applied = game._choose_result_growth(monster_id)
	var after_roster = _growth_roster_snapshot(game)
	return {
		"target_id": monster_id,
		"applied": applied,
		"bonus_exp": game._result_growth_choice_bonus(),
		"preparation_rule": game._result_growth_preparation_rule(monster_id),
		"before": before_roster.get(monster_id, {}).duplicate(true),
		"after_selection": after_roster.get(monster_id, {}).duplicate(true),
		"before_roster": before_roster,
		"after_roster": after_roster
	}

func _growth_roster_snapshot(game: Node) -> Dictionary:
	var result: Dictionary = {}
	for monster_id in ["slime", "goblin", "imp"]:
		result[monster_id] = _growth_monster_snapshot(game, monster_id)
	return result

func _growth_monster_snapshot(game: Node, monster_id: String) -> Dictionary:
	if not game.monster_roster.has(monster_id):
		return {}
	var roster: Dictionary = game.monster_roster[monster_id]
	var level = int(roster.get("level", 1))
	var exp = int(roster.get("exp", 0))
	var next_exp = int(game._monster_exp_to_next(level))
	var stats: Dictionary = game._scaled_monster_stats(monster_id)
	return {
		"level": level,
		"exp": exp,
		"next_exp": next_exp,
		"remaining_exp": max(0, next_exp - exp),
		"max_hp": int(stats.get("max_hp", 0)),
		"atk": int(stats.get("atk", 0)),
		"def": int(stats.get("def", 0)),
		"move_speed": float(stats.get("move_speed", 0.0)),
		"attack_range": float(stats.get("attack_range", 0.0)),
		"attack_interval": float(stats.get("attack_interval", 0.0)),
		"preparation_active": game._growth_preparation_active(monster_id),
		"preparation_day": int(roster.get("growth_preparation_day", -1)),
		"preparation_summary": game._result_growth_preparation_summary(monster_id)
	}

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
			_apply_choice_value_setup(game, "watch_post", Constants.DIRECTIVE_DEFENSE, Constants.ROOM_DIRECTIVE_ENTRY_BLOCK)
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
		"facility_frontline_neutral":
			_apply_facility_frontline_setup(game, "build_slot")
		"facility_frontline_barracks":
			_apply_facility_frontline_setup(game, "barracks")
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

func _apply_facility_frontline_setup(game: Node, facility_id: String) -> void:
	_apply_facility_comparison_setup(game, facility_id)
	game.selected_room = "spike_corridor"
	game._set_room_directive(Constants.ROOM_DIRECTIVE_TRAP_LURE)
	game._set_global_directive(Constants.DIRECTIVE_ALL_OUT)

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
		"engineers_spawned": int(metrics.get("engineers_spawned", game.engineers_spawned_this_battle)),
		"engineers_reached_facility": int(metrics.get("engineers_reached_facility", game.engineers_reached_facility_this_battle)),
		"facility_disables": int(metrics.get("facility_disables", game.facility_disables_this_battle)),
		"facilities_saved": int(metrics.get("facilities_saved", game._engineer_facilities_saved_count())),
		"royal_rally_seconds": float(metrics.get("royal_rally_seconds", 0.0)),
		"royal_rally_activations": int(metrics.get("royal_rally_activations", 0)),
		"royal_rally_stopped": bool(metrics.get("royal_rally_stopped", false)),
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
		var skill_uses = int(result.get("skill_uses", 0))
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
		if skill_uses < int(limits.get("skill_uses_min", 0)):
			push_error("BALANCE_ASSERT FAIL %s: skill uses %d < %d" % [
				name,
				skill_uses,
				int(limits.get("skill_uses_min", 0))
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
	for scenario_name in FACILITY_FRONTLINE_SCENARIOS:
		if not by_name.has(scenario_name):
			push_error("FACILITY_CHOICE_ASSERT FAIL: %s scenario was not run" % scenario_name)
			passed = false
	if not passed:
		print("FACILITY_CHOICE_ASSERT: FAIL")
		return false
	var frontline_neutral: Dictionary = by_name["DAY2_FRONTLINE_NEUTRAL"]
	var frontline_barracks: Dictionary = by_name["DAY2_FRONTLINE_BARRACKS"]
	var frontline_effects: Dictionary = frontline_barracks.get("facility_effects", {})
	if int(watch.get("watch_post_bonus_damage", 0)) <= 0 or int(watch.get("watch_post_slow_applications", 0)) <= 0:
		push_error("FACILITY_CHOICE_ASSERT FAIL: watch post did not affect the battle")
		passed = false
	if bool(watch_result.get("thief_stole", false)) or not bool(neutral_result.get("thief_stole", false)):
		push_error("FACILITY_CHOICE_ASSERT FAIL: watch post did not prevent the neutral room's theft")
		passed = false
	if int(barracks.get("barracks_bonus_damage", 0)) < 40:
		push_error("FACILITY_CHOICE_ASSERT FAIL: barracks offense contribution was too small")
		passed = false
	if float(barracks.get("barracks_covered_unit_seconds", 0.0)) <= 0.0 or int(barracks.get("barracks_attack_applications", 0)) <= 0:
		push_error("FACILITY_CHOICE_ASSERT FAIL: barracks combat coverage was not recorded")
		passed = false
	if float(barracks_result.get("time", 0.0)) > float(neutral_result.get("time", 0.0)) + 3.0 or int(barracks_result.get("monster_hp", 0)) < int(neutral_result.get("monster_hp", 0)):
		push_error("FACILITY_CHOICE_ASSERT FAIL: barracks contribution did not hold the neutral outcome")
		passed = false
	if int(recovery.get("recovery_healing", 0)) <= 0:
		push_error("FACILITY_CHOICE_ASSERT FAIL: recovery nest did not heal any monster")
		passed = false
	if int(recovery_result.get("monster_hp", 0)) < int(neutral_result.get("monster_hp", 0)) + 40:
		push_error("FACILITY_CHOICE_ASSERT FAIL: recovery nest did not preserve a meaningful amount of monster HP")
		passed = false
	if bool(frontline_neutral.get("timed_out", false)) or not bool(frontline_neutral.get("win", false)) or bool(frontline_barracks.get("timed_out", false)) or not bool(frontline_barracks.get("win", false)):
		push_error("FACILITY_CHOICE_ASSERT FAIL: frontline comparison did not finish with wins")
		passed = false
	if int(frontline_effects.get("barracks_attack_applications", 0)) < 10 or int(frontline_effects.get("barracks_damage_reduction_applications", 0)) <= 0:
		push_error("FACILITY_CHOICE_ASSERT FAIL: frontline barracks did not apply both offense and defense")
		passed = false
	if float(frontline_barracks.get("time", 0.0)) >= float(frontline_neutral.get("time", 0.0)) or int(frontline_barracks.get("monster_hp", 0)) < int(frontline_neutral.get("monster_hp", 0)):
		push_error("FACILITY_CHOICE_ASSERT FAIL: frontline barracks did not improve speed and survival")
		passed = false
	print("FACILITY_CHOICE_ASSERT: %s" % ("PASS" if passed else "FAIL"))
	return passed

func _write_facility_choice_report(results: Array[Dictionary], passed: bool) -> void:
	var by_name = _results_by_name(results)
	var records: Array[Dictionary] = []
	for scenario_name in FACILITY_CHOICE_SCENARIOS + FACILITY_FRONTLINE_SCENARIOS:
		if by_name.has(scenario_name):
			records.append(Dictionary(by_name[scenario_name]).duplicate(true))
	var output_dir = ProjectSettings.globalize_path("res://tmp/facility_choice_value")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var generated_at = Time.get_datetime_string_from_system(false, true)
	var report = {
		"version": 1,
		"generated_at": generated_at,
		"passed": passed,
		"criteria": {
			"watch_prevents_neutral_theft": true,
			"barracks_minimum_bonus_damage": 40,
			"barracks_maximum_delay_from_neutral": 3.0,
			"recovery_minimum_hp_gain_from_neutral": 40,
			"frontline_barracks_must_improve_speed_and_hp": true
		},
		"scenarios": records
	}
	var json_path = output_dir.path_join("latest.json")
	var json_file = FileAccess.open(json_path, FileAccess.WRITE)
	if json_file == null:
		push_error("FACILITY_CHOICE_REPORT FAIL: could not open %s" % json_path)
		return
	json_file.store_string(JSON.stringify(report, "\t"))
	json_file.close()
	var markdown_path = output_dir.path_join("latest.md")
	var markdown_file = FileAccess.open(markdown_path, FileAccess.WRITE)
	if markdown_file == null:
		push_error("FACILITY_CHOICE_REPORT FAIL: could not open %s" % markdown_path)
		return
	markdown_file.store_string(_facility_choice_markdown(records, passed, generated_at))
	markdown_file.close()
	print("FACILITY_CHOICE_REPORT_JSON: %s" % json_path)
	print("FACILITY_CHOICE_REPORT_MARKDOWN: %s" % markdown_path)

func _facility_choice_markdown(records: Array[Dictionary], passed: bool, generated_at: String) -> String:
	var lines: Array[String] = [
		"# DAY 2 시설 선택 가치 기록",
		"",
		"- 생성 시각: `%s`" % generated_at,
		"- 판정: **%s**" % ("PASS" if passed else "FAIL"),
		"",
		"| 시설 | 시간 | 몬스터 체력 | 도난 | 추가 피해 | 피해 감소 | 효과 범위 | 같은 방 교전 | 사거리 교전 | 공격/방어 발동 | 감소 없는 피격 | 회복 |",
		"|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|"
	]
	for result in records:
		var effects: Dictionary = result.get("facility_effects", {})
		lines.append("| %s | %.1f초 | %d/%d | %s | %d | %d | %.1f초 | %.1f초 | %.1f초 | %d/%d회 | %d/%d회 | %d |" % [
			str(FACILITY_CHOICE_LABELS.get(str(result.get("name", "")), result.get("name", ""))),
			float(result.get("time", 0.0)),
			int(result.get("monster_hp", 0)),
			int(result.get("monster_max_hp", 0)),
			"예" if bool(result.get("thief_stole", false)) else "아니요",
			int(effects.get("barracks_bonus_damage", 0)) + int(effects.get("watch_post_bonus_damage", 0)),
			int(effects.get("barracks_damage_reduced", 0)),
			float(effects.get("barracks_covered_unit_seconds", 0.0)),
			float(effects.get("barracks_contested_unit_seconds", 0.0)),
			float(effects.get("barracks_in_range_unit_seconds", 0.0)),
			int(effects.get("barracks_attack_applications", 0)),
			int(effects.get("barracks_damage_reduction_applications", 0)),
			int(effects.get("barracks_no_reduction_hits", 0)),
			int(effects.get("barracks_assigned_incoming_attacks", 0)),
			int(effects.get("recovery_healing", 0))
		])
	lines.append("")
	lines.append("- 효과 범위·교전 시간은 병영 배치 몬스터들의 시간을 합한 값입니다. 두 마리가 5초 동안 함께 있으면 10초로 기록됩니다.")
	lines.append("- 병영의 공격 수치뿐 아니라 실제 전선 유지와 방어 발동 여부를 함께 비교합니다.")
	return "\n".join(lines) + "\n"

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
			if activity_exp < 0 or activity_exp > Constants.ACTIVITY_EXP_CAP:
				push_error("ACTIVITY_GROWTH_ASSERT FAIL: %s %s activity EXP %d outside 0-%d" % [scenario_name, str(row.get("monster_id", "")), activity_exp, Constants.ACTIVITY_EXP_CAP])
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
		if scenario_name in COMBINATION_TREASURE_DEFENSE_SCENARIOS and bool(result.get("thief_stole", false)):
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
	var fastest_defense_name := ""
	var max_hp_name := ""
	var fastest_defense_time := INF
	var max_hp := -INF
	for scenario_name in COMBINATION_CHOICE_SCENARIOS:
		var result: Dictionary = by_name[scenario_name]
		var time = float(result.get("time", 0.0))
		var hp = float(result.get("monster_hp", 0))
		if not bool(result.get("thief_stole", false)) and time < fastest_defense_time:
			fastest_defense_time = time
			fastest_defense_name = scenario_name
		if hp > max_hp:
			max_hp = hp
			max_hp_name = scenario_name
	if fastest_defense_name == max_hp_name:
		push_error("CHOICE_VALUE_ASSERT FAIL: fastest treasure-defense combo and safest combo are the same")
		passed = false
	if float(safe_recovery.get("monster_hp", 0)) < float(fast_barracks.get("monster_hp", 0)) + 30.0:
		push_error("CHOICE_VALUE_ASSERT FAIL: safe recovery does not preserve enough HP over fast barracks")
		passed = false
	if float(fast_barracks.get("time", 0.0)) >= float(thief_lock.get("time", 0.0)):
		push_error("CHOICE_VALUE_ASSERT FAIL: fast barracks is not faster than thief lock")
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

func _write_choice_value_report(results: Array[Dictionary], passed: bool) -> void:
	var by_name = _results_by_name(results)
	var records: Array[Dictionary] = []
	for scenario_name in COMBINATION_CHOICE_SCENARIOS:
		if by_name.has(scenario_name):
			records.append(Dictionary(by_name[scenario_name]).duplicate(true))
	var output_dir = ProjectSettings.globalize_path("res://tmp/balance_choice_value")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var generated_at = Time.get_datetime_string_from_system(false, true)
	var report = {
		"version": 1,
		"generated_at": generated_at,
		"passed": passed,
		"criteria": {
			"all_win": true,
			"treasure_defense_scenarios_must_prevent_theft": COMBINATION_TREASURE_DEFENSE_SCENARIOS,
			"safe_recovery_may_trade_treasure_for_monster_hp": true,
			"fastest_treasure_defense_and_safest_must_differ": true,
			"minimum_time_spread": 8.0,
			"minimum_monster_hp_spread": 60.0
		},
		"scenarios": records
	}
	var json_path = output_dir.path_join("latest.json")
	var json_file = FileAccess.open(json_path, FileAccess.WRITE)
	if json_file == null:
		push_error("CHOICE_VALUE_REPORT FAIL: could not open %s" % json_path)
		return
	json_file.store_string(JSON.stringify(report, "\t"))
	json_file.close()
	var markdown_path = output_dir.path_join("latest.md")
	var markdown_file = FileAccess.open(markdown_path, FileAccess.WRITE)
	if markdown_file == null:
		push_error("CHOICE_VALUE_REPORT FAIL: could not open %s" % markdown_path)
		return
	markdown_file.store_string(_choice_value_markdown(records, passed, generated_at))
	markdown_file.close()
	print("CHOICE_VALUE_REPORT_JSON: %s" % json_path)
	print("CHOICE_VALUE_REPORT_MARKDOWN: %s" % markdown_path)

func _choice_value_markdown(records: Array[Dictionary], passed: bool, generated_at: String) -> String:
	var lines: Array[String] = [
		"# DAY 2 조합 선택 가치 기록",
		"",
		"- 생성 시각: `%s`" % generated_at,
		"- 판정: **%s**" % ("PASS" if passed else "FAIL"),
		"",
		"| 조합 | 결과 | 시간 | 몬스터 체력 | 전투 불능 | 도둑 도달 | 도난 | 스킬 |",
		"|---|---:|---:|---:|---:|---:|---:|---:|"
	]
	var fastest_defense_name := ""
	var safest_name := ""
	var fastest_defense_time := INF
	var safest_hp := -INF
	for result in records:
		var scenario_name = str(result.get("name", ""))
		var elapsed = float(result.get("time", 0.0))
		var monster_hp = int(result.get("monster_hp", 0))
		if not bool(result.get("thief_stole", false)) and elapsed < fastest_defense_time:
			fastest_defense_time = elapsed
			fastest_defense_name = scenario_name
		if monster_hp > safest_hp:
			safest_hp = monster_hp
			safest_name = scenario_name
		lines.append("| %s | %s | %.1f초 | %d/%d | %d | %s | %s | %d |" % [
			str(COMBINATION_CHOICE_LABELS.get(scenario_name, scenario_name)),
			"승리" if bool(result.get("win", false)) else "실패",
			elapsed,
			monster_hp,
			int(result.get("monster_max_hp", 0)),
			int(result.get("monster_down", 0)),
			"예" if bool(result.get("thief_reached_treasure", false)) else "아니요",
			"예" if bool(result.get("thief_stole", false)) else "아니요",
			int(result.get("skill_uses", 0))
		])
	lines.append("")
	lines.append("- 도난 없이 가장 빠른 조합: **%s** (%.1f초)" % [str(COMBINATION_CHOICE_LABELS.get(fastest_defense_name, fastest_defense_name)), fastest_defense_time])
	lines.append("- 가장 안전한 조합: **%s** (남은 체력 %d)" % [str(COMBINATION_CHOICE_LABELS.get(safest_name, safest_name)), int(safest_hp)])
	lines.append("- 판정 기준: 전 조합 승리, 도둑 대응·속공·함정 조합은 도난 방지, 회복 생존은 체력 보존 우위, 도난 없는 속공과 안전형 분리, 시간 차이 8초 이상, 체력 차이 60 이상.")
	return "\n".join(lines) + "\n"

func _assert_growth_choices(results: Array[Dictionary]) -> bool:
	var by_name = _results_by_name(results)
	var passed := true
	for scenario_name in GROWTH_CHOICE_SCENARIOS:
		if not by_name.has(scenario_name):
			push_error("GROWTH_CHOICE_ASSERT FAIL: %s scenario was not run" % scenario_name)
			passed = false
			continue
		var result: Dictionary = by_name[scenario_name]
		var target_id = str(GROWTH_CHOICE_TARGETS[scenario_name])
		var choice: Dictionary = result.get("growth_choice_value", {})
		if bool(result.get("timed_out", false)) or not bool(result.get("win", false)):
			push_error("GROWTH_CHOICE_ASSERT FAIL: %s did not finish with a win" % scenario_name)
			passed = false
		if not bool(choice.get("applied", false)) or str(choice.get("target_id", "")) != target_id:
			push_error("GROWTH_CHOICE_ASSERT FAIL: %s did not apply its target choice" % scenario_name)
			passed = false
			continue
		var bonus = int(choice.get("bonus_exp", 0))
		var before: Dictionary = choice.get("before", {})
		var after: Dictionary = choice.get("after_selection", {})
		var expected = _expected_growth_state(before, bonus)
		if bonus <= 0 or not _same_growth_progress(after, expected):
			push_error("GROWTH_CHOICE_ASSERT FAIL: %s target progress does not match +%d EXP" % [scenario_name, bonus])
			passed = false
		var before_roster: Dictionary = choice.get("before_roster", {})
		var after_roster: Dictionary = choice.get("after_roster", {})
		var day_two_roster: Dictionary = choice.get("day_two_roster", {})
		var day_three_roster: Dictionary = choice.get("day_three_without_reselection_roster", {})
		for monster_id in ["slime", "goblin", "imp"]:
			var row = _growth_row_from_result(result, monster_id)
			var row_bonus = int(row.get("choice_bonus_exp", 0))
			if monster_id == target_id:
				if row_bonus != bonus:
					push_error("GROWTH_CHOICE_ASSERT FAIL: %s target row bonus is %d, expected %d" % [scenario_name, row_bonus, bonus])
					passed = false
			elif (
				row_bonus != 0
				or not _same_growth_progress(before_roster.get(monster_id, {}), after_roster.get(monster_id, {}))
				or not _same_growth_snapshot(after_roster.get(monster_id, {}), day_two_roster.get(monster_id, {}))
				or bool(day_two_roster.get(monster_id, {}).get("preparation_active", false))
			):
				push_error("GROWTH_CHOICE_ASSERT FAIL: %s changed non-target %s" % [scenario_name, monster_id])
				passed = false
		var day_two_target: Dictionary = day_two_roster.get(target_id, {})
		var preparation_rule: Dictionary = choice.get("preparation_rule", {})
		if (
			int(choice.get("day_two", 0)) != 2
			or not bool(day_two_target.get("preparation_active", false))
			or int(day_two_target.get("preparation_day", -1)) != 2
			or not _prepared_growth_snapshot_matches(after, day_two_target, preparation_rule)
		):
			push_error("GROWTH_CHOICE_ASSERT FAIL: %s preparation was not applied on DAY 2" % scenario_name)
			passed = false
		var day_three_target: Dictionary = day_three_roster.get(target_id, {})
		if bool(day_three_target.get("preparation_active", false)) or not _same_growth_snapshot(after, day_three_target):
			push_error("GROWTH_CHOICE_ASSERT FAIL: %s preparation did not expire before DAY 3" % scenario_name)
			passed = false
	print("GROWTH_CHOICE_ASSERT: %s" % ("PASS" if passed else "FAIL"))
	return passed

func _expected_growth_state(before: Dictionary, bonus: int) -> Dictionary:
	var level = int(before.get("level", 1))
	var exp = int(before.get("exp", 0)) + bonus
	var next_exp = 50 + max(0, level - 1) * 30
	var guard := 0
	while exp >= next_exp and guard < 20:
		exp -= next_exp
		level += 1
		next_exp = 50 + max(0, level - 1) * 30
		guard += 1
	return {"level": level, "exp": exp, "next_exp": next_exp}

func _same_growth_progress(left: Dictionary, right: Dictionary) -> bool:
	return (
		int(left.get("level", -1)) == int(right.get("level", -2))
		and int(left.get("exp", -1)) == int(right.get("exp", -2))
		and int(left.get("next_exp", -1)) == int(right.get("next_exp", -2))
	)

func _same_growth_snapshot(left: Dictionary, right: Dictionary) -> bool:
	return (
		_same_growth_progress(left, right)
		and int(left.get("max_hp", -1)) == int(right.get("max_hp", -2))
		and int(left.get("atk", -1)) == int(right.get("atk", -2))
		and int(left.get("def", -1)) == int(right.get("def", -2))
		and is_equal_approx(float(left.get("move_speed", -1.0)), float(right.get("move_speed", -2.0)))
		and is_equal_approx(float(left.get("attack_range", -1.0)), float(right.get("attack_range", -2.0)))
		and is_equal_approx(float(left.get("attack_interval", -1.0)), float(right.get("attack_interval", -2.0)))
	)

func _prepared_growth_snapshot_matches(base: Dictionary, prepared: Dictionary, rule: Dictionary) -> bool:
	if rule.is_empty() or not _same_growth_progress(base, prepared):
		return false
	var multipliers: Dictionary = rule.get("stat_multipliers", {})
	var bonuses: Dictionary = rule.get("stat_bonuses", {})
	for key in ["max_hp", "atk", "def", "move_speed", "attack_range", "attack_interval"]:
		var expected = float(base.get(key, 0.0))
		if multipliers.has(key):
			expected *= float(multipliers[key])
		if bonuses.has(key):
			expected += float(bonuses[key])
		if key in ["max_hp", "atk", "def"]:
			if int(prepared.get(key, -1)) != int(round(expected)):
				return false
		elif not is_equal_approx(float(prepared.get(key, -1.0)), expected):
			return false
	return true

func _growth_row_from_result(result: Dictionary, monster_id: String) -> Dictionary:
	for row_value in result.get("growth", []):
		var row: Dictionary = row_value
		if str(row.get("monster_id", "")) == monster_id:
			return row
	return {}

func _write_growth_choice_report(results: Array[Dictionary], passed: bool) -> void:
	var by_name = _results_by_name(results)
	var records: Array[Dictionary] = []
	for scenario_name in GROWTH_CHOICE_SCENARIOS:
		if by_name.has(scenario_name):
			records.append(Dictionary(by_name[scenario_name]).duplicate(true))
	var output_dir = ProjectSettings.globalize_path("res://tmp/growth_choice_value")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var generated_at = Time.get_datetime_string_from_system(false, true)
	var report = {
		"version": 1,
		"generated_at": generated_at,
		"passed": passed,
		"criteria": {
			"all_day_one_battles_win": true,
			"only_selected_monster_receives_bonus": true,
			"choice_progress_is_preserved_on_day_two": true,
			"selected_monster_gets_role_preparation_on_day_two": true,
			"preparation_expires_without_reselection_on_day_three": true
		},
		"scenarios": records
	}
	var json_path = output_dir.path_join("latest.json")
	var json_file = FileAccess.open(json_path, FileAccess.WRITE)
	if json_file == null:
		push_error("GROWTH_CHOICE_REPORT FAIL: could not open %s" % json_path)
		return
	json_file.store_string(JSON.stringify(report, "\t"))
	json_file.close()
	var markdown_path = output_dir.path_join("latest.md")
	var markdown_file = FileAccess.open(markdown_path, FileAccess.WRITE)
	if markdown_file == null:
		push_error("GROWTH_CHOICE_REPORT FAIL: could not open %s" % markdown_path)
		return
	markdown_file.store_string(_growth_choice_markdown(records, passed, generated_at))
	markdown_file.close()
	print("GROWTH_CHOICE_REPORT_JSON: %s" % json_path)
	print("GROWTH_CHOICE_REPORT_MARKDOWN: %s" % markdown_path)

func _growth_choice_markdown(records: Array[Dictionary], passed: bool, generated_at: String) -> String:
	var labels = {"slime": "슬라임", "goblin": "고블린", "imp": "임프"}
	var lines: Array[String] = [
		"# DAY 1 집중 성장 선택 가치 기록",
		"",
		"- 생성 시각: `%s`" % generated_at,
		"- 판정: **%s**" % ("PASS" if passed else "FAIL"),
		"",
		"| 집중 대상 | 전투 | 선택 전 | 선택 후 | DAY 2 시작 | 다음 방어 준비 효과 |",
		"|---|---:|---:|---:|---:|---:|"
	]
	for result in records:
		var choice: Dictionary = result.get("growth_choice_value", {})
		var target_id = str(choice.get("target_id", ""))
		var before: Dictionary = choice.get("before", {})
		var after: Dictionary = choice.get("after_selection", {})
		var day_two: Dictionary = Dictionary(choice.get("day_two_roster", {})).get(target_id, {})
		var preparation_summary = str(day_two.get("preparation_summary", ""))
		lines.append("| %s | %s | Lv.%d %d/%d | Lv.%d %d/%d | Lv.%d %d/%d | %s |" % [
			str(labels.get(target_id, target_id)),
			"승리" if bool(result.get("win", false)) else "실패",
			int(before.get("level", 0)), int(before.get("exp", 0)), int(before.get("next_exp", 0)),
			int(after.get("level", 0)), int(after.get("exp", 0)), int(after.get("next_exp", 0)),
			int(day_two.get("level", 0)), int(day_two.get("exp", 0)), int(day_two.get("next_exp", 0)),
			preparation_summary if bool(day_two.get("preparation_active", false)) else "발동 안 됨"
		])
	lines.append("")
	lines.append("- 세 선택 모두 대상 한 명에게만 +8 EXP와 몬스터 역할에 맞는 DAY 2 준비 효과가 적용되어야 통과합니다.")
	lines.append("- 준비 효과는 다음 방어전 날짜에만 적용되며, 다시 선택하지 않은 DAY 3에는 자동으로 사라집니다.")
	return "\n".join(lines) + "\n"

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
