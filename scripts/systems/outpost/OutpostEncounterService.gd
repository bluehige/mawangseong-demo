extends RefCounted
class_name OutpostEncounterService

const BATTLE_DAYS := [10, 20]


static func is_battle_day(day: int) -> bool:
	return day in BATTLE_DAYS


static func new_battle_state(outpost: Dictionary, encounter: Dictionary, day: int, retry_count: int = 0) -> Dictionary:
	return {
		"day": day,
		"elapsed": 0.0,
		"banner_hp": maxi(1, int(outpost.get("current_hp", outpost.get("max_hp", 1)))),
		"banner_max_hp": maxi(1, int(outpost.get("max_hp", 1))),
		"defender_count": mini(3, outpost.get("assigned_monster_ids", []).size()),
		"next_spawn_index": 0,
		"enemies": [],
		"completed": false,
		"win": false,
		"retry_count": maxi(0, retry_count),
		"encounter": encounter.duplicate(true)
	}


static func step(state_value, delta: float) -> Dictionary:
	var state: Dictionary = state_value.duplicate(true) if state_value is Dictionary else {}
	if bool(state.get("completed", false)) or delta <= 0.0:
		return state
	var encounter: Dictionary = state.get("encounter", {})
	var wave: Array = encounter.get("placeholder_wave", [])
	var elapsed := float(state.get("elapsed", 0.0)) + delta
	state["elapsed"] = elapsed
	var next_spawn := int(state.get("next_spawn_index", 0))
	var enemies: Array = state.get("enemies", []).duplicate(true)
	while next_spawn < wave.size() and float(wave[next_spawn].get("spawn_second", 0.0)) <= elapsed:
		var entry: Dictionary = wave[next_spawn]
		enemies.append({"id": next_spawn, "hp": float(entry.get("hp", 1.0)), "max_hp": float(entry.get("hp", 1.0)), "damage": int(entry.get("banner_damage", 0)), "progress": 0.0})
		next_spawn += 1
	state["next_spawn_index"] = next_spawn
	var defender_dps := float(encounter.get("defender_dps_per_monster", 0.0)) * int(state.get("defender_count", 0))
	if defender_dps > 0.0 and not enemies.is_empty():
		var target_index := 0
		for index in range(1, enemies.size()):
			if float(enemies[index].get("progress", 0.0)) > float(enemies[target_index].get("progress", 0.0)):
				target_index = index
		enemies[target_index]["hp"] = float(enemies[target_index].get("hp", 0.0)) - defender_dps * delta
	var travel_seconds := maxf(0.1, float(encounter.get("enemy_travel_seconds", 12.0)))
	var banner_hp := int(state.get("banner_hp", 0))
	for index in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[index]
		if float(enemy.get("hp", 0.0)) <= 0.0:
			enemies.remove_at(index)
			continue
		enemy["progress"] = float(enemy.get("progress", 0.0)) + delta / travel_seconds
		enemies[index] = enemy
		if float(enemy.get("progress", 0.0)) >= 1.0:
			banner_hp = maxi(0, banner_hp - int(enemy.get("damage", 0)))
			enemies.remove_at(index)
	state["banner_hp"] = banner_hp
	state["enemies"] = enemies
	var minimum_seconds := float(encounter.get("minimum_result_seconds", 45.0))
	var target_seconds := float(encounter.get("target_duration_seconds", 55.0))
	var wave_finished := next_spawn >= wave.size() and enemies.is_empty()
	if elapsed >= minimum_seconds and (banner_hp <= 0 or wave_finished or elapsed >= target_seconds):
		state["completed"] = true
		state["win"] = banner_hp > 0
	return state


static func result(state: Dictionary) -> Dictionary:
	return {
		"day": int(state.get("day", 0)),
		"win": bool(state.get("win", false)),
		"duration_seconds": snappedf(float(state.get("elapsed", 0.0)), 0.1),
		"ending_hp": int(state.get("banner_hp", 0)),
		"max_hp": int(state.get("banner_max_hp", 0)),
		"retry_count": int(state.get("retry_count", 0))
	}


static func run_placeholder_trial(outpost: Dictionary, encounter: Dictionary, day: int, retry_count: int = 0) -> Dictionary:
	var state := new_battle_state(outpost, encounter, day, retry_count)
	var safety_steps := 0
	while not bool(state.get("completed", false)) and safety_steps < 1000:
		state = step(state, 0.1)
		safety_steps += 1
	return result(state)


static func settle_result(active_run_value, battle_result: Dictionary) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var day := int(battle_result.get("day", 0))
	if day not in BATTLE_DAYS:
		return {"ok": false, "error": "전초기지 방어전 DAY가 아닙니다.", "active_run": active_run}
	var outpost: Dictionary = active_run.get("outpost", {}).duplicate(true)
	if str(outpost.get("type_id", "")) == "":
		return {"ok": false, "error": "건설된 전초기지가 없습니다.", "active_run": active_run}
	var results: Array = outpost.get("battle_results", []).duplicate(true)
	for value in results:
		if value is Dictionary and int(value.get("day", 0)) == day:
			return {"ok": false, "error": "해당 DAY 전초기지 결산이 이미 기록되었습니다.", "active_run": active_run}
	var stored := battle_result.duplicate(true)
	stored["settled"] = true
	results.append(stored)
	outpost["battle_results"] = results
	outpost["current_hp"] = clampi(int(stored.get("ending_hp", 0)), 0, int(outpost.get("max_hp", 0)))
	outpost["damaged"] = int(outpost.get("current_hp", 0)) < int(outpost.get("max_hp", 0))
	if day == 20 and not bool(stored.get("win", false)):
		outpost["support_token_lost"] = true
		var council: Dictionary = active_run.get("council_season", {}).duplicate(true)
		council["rival_support_id"] = ""
		active_run["council_season"] = council
	active_run["outpost"] = outpost
	return {"ok": true, "error": "", "active_run": active_run}


static func apply_day_start_recovery(active_run_value, day: int) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	if day != 11:
		return active_run
	var outpost: Dictionary = active_run.get("outpost", {}).duplicate(true)
	if bool(outpost.get("recovery_used", false)):
		return active_run
	var day10_result: Dictionary = {}
	for value in outpost.get("battle_results", []):
		if value is Dictionary and int(value.get("day", 0)) == 10:
			day10_result = value
			break
	if day10_result.is_empty() or bool(day10_result.get("win", false)):
		return active_run
	var max_hp := maxi(1, int(outpost.get("max_hp", 1)))
	outpost["current_hp"] = maxi(1, int(round(max_hp * 0.5)))
	outpost["damaged"] = true
	outpost["recovery_used"] = true
	outpost["upgrade_cost_multiplier"] = 1.25
	active_run["outpost"] = outpost
	return active_run
