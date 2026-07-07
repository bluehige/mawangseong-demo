extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const MAX_SIM_SECONDS = 120.0
const PHYSICS_STEP = 1.0 / 60.0
const SIM_TIME_SCALE = 1.0
const TUTORIAL_BALANCE_RANGES = {
	"DAY1_AUTO": {"min": 45.0, "max": 95.0, "monster_down_max": 1},
	"DAY2_TRAP_DIRECTIVE": {"min": 45.0, "max": 95.0, "monster_down_max": 2},
	"DAY3_ASSISTED": {"min": 60.0, "max": 115.0, "monster_down_max": 3}
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
	var scenarios = [
		{"name": "DAY1_AUTO", "day": 1, "setup": "auto", "assist": "none"},
		{"name": "DAY2_AUTO", "day": 2, "setup": "auto", "assist": "none"},
		{"name": "DAY2_TRAP_DIRECTIVE", "day": 2, "setup": "trap_lure", "assist": "none"},
		{"name": "DAY3_AUTO", "day": 3, "setup": "auto", "assist": "none"},
		{"name": "DAY3_ASSISTED", "day": 3, "setup": "trap_lure", "assist": "imp_skills"}
	]
	var results: Array[Dictionary] = []
	print("BALANCE_SIMULATION: START")
	_print_header()
	for scenario in scenarios:
		if scenario_filter != "" and str(scenario["name"]) != scenario_filter:
			continue
		if assert_tutorial_balance and not TUTORIAL_BALANCE_RANGES.has(str(scenario["name"])):
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
	print("BALANCE_SIMULATION: END")
	get_tree().quit(1 if failed else 0)

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
	return result

func _apply_setup(game: Node, setup: String) -> void:
	match setup:
		"trap_lure":
			game.selected_room = "spike_corridor"
			game._set_room_directive(Constants.ROOM_DIRECTIVE_TRAP_LURE)
			game._set_global_directive(Constants.DIRECTIVE_ALL_OUT)
		_:
			game._set_global_directive(Constants.DIRECTIVE_DEFENSE)

func _apply_assist(game: Node, assist: String, _elapsed: float) -> int:
	if assist != "imp_skills":
		return 0
	var imp = _unit_by_id(game.monster_units, "imp")
	if imp == null or not imp.is_alive():
		return 0
	var used = 0
	if _alive_enemy_count(game) >= 2 and imp.skill_ready("flame_zone") and GameState.mana >= 40:
		game._select_unit(imp)
		game._handle_key(KEY_2)
		used += 1
	elif _alive_enemy_count(game) >= 1 and imp.skill_ready("fireball") and GameState.mana >= 20:
		game._select_unit(imp)
		game._handle_key(KEY_1)
		used += 1
	return used

func _collect_result(game: Node, scenario: Dictionary, elapsed: float, skill_uses: int, thief_reached_treasure: bool) -> Dictionary:
	var win = bool(game.result_summary.get("win", false))
	var timed_out = game.current_screen != Constants.SCREEN_RESULT
	var monster_down = 0
	for unit in game.monster_units:
		if not unit.is_alive():
			monster_down += 1
	var thief_stole = _logs_contain("도둑이 보물을 훔쳤습니다")
	var result = {
		"name": str(scenario["name"]),
		"day": int(scenario["day"]),
		"win": win,
		"timed_out": timed_out,
		"time": elapsed,
		"throne_hp": GameState.demon_lord_hp,
		"throne_damage": GameState.demon_lord_max_hp - GameState.demon_lord_hp,
		"monster_down": monster_down,
		"enemy_down": game._count_downed_enemies(),
		"spawned": game.spawned_count,
		"thief_reached_treasure": thief_reached_treasure,
		"thief_stole": thief_stole,
		"skill_uses": skill_uses,
		"gold": GameState.gold,
		"mana": GameState.mana
	}
	if timed_out or not win or thief_stole:
		result["units"] = _unit_snapshot(game)
		result["recent_logs"] = current_logs.slice(max(0, current_logs.size() - 6), current_logs.size())
	return result

func _unit_snapshot(game: Node) -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for unit in game.monster_units + game.enemy_units:
		snapshot.append({
			"id": unit.unit_id,
			"faction": unit.faction,
			"alive": unit.is_alive(),
			"room": unit.current_room,
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
	print("| scenario | result | time | throne hp | monster down | enemies | thief reached | thief stole | skill uses | gold | mana |")
	print("|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|")

func _print_result(result: Dictionary) -> void:
	var result_text = "TIMEOUT"
	if not bool(result["timed_out"]):
		result_text = "WIN" if bool(result["win"]) else "LOSS"
	print("| %s | %s | %.1f | %d | %d | %d/%d | %s | %s | %d | %d | %d |" % [
		str(result["name"]),
		result_text,
		float(result["time"]),
		int(result["throne_hp"]),
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
