extends RefCounted
class_name OutpostEncounterService

const BATTLE_DAYS := [10, 20]
const TYPE_WATCH := "outpost_watch_nest"
const TYPE_SUPPLY := "outpost_supply_burrow"
const TYPE_FALSE_GATE := "outpost_false_gate"


static func is_battle_day(day: int) -> bool:
	return day in BATTLE_DAYS


static func new_battle_state(outpost: Dictionary, encounter: Dictionary, day: int, retry_count: int = 0, type_definition: Dictionary = {}) -> Dictionary:
	var type_id := str(outpost.get("type_id", ""))
	var wave_key := "day20_wave" if day == 20 else "placeholder_wave"
	var wave: Array = encounter.get(wave_key, encounter.get("placeholder_wave", [])).duplicate(true)
	if type_id == TYPE_FALSE_GATE and not wave.is_empty():
		var extra_count := maxi(0, int(type_definition.get("extra_banner_enemies", 0)))
		for extra_index in extra_count:
			var extra: Dictionary = wave[mini(extra_index, wave.size() - 1)].duplicate(true)
			extra["spawn_second"] = float(extra.get("spawn_second", 0.0)) + 3.0 + extra_index
			extra["false_gate_extra"] = true
			wave.append(extra)
		wave.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("spawn_second", 0.0)) < float(b.get("spawn_second", 0.0)))
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
		"encounter": encounter.duplicate(true),
		"wave": wave,
		"type_id": type_id,
		"type_definition": type_definition.duplicate(true),
		"supply_chest_used": false,
		"supply_chest_healing": 0,
		"detoured_count": 0
	}


static func step(state_value, delta: float) -> Dictionary:
	var state: Dictionary = state_value.duplicate(true) if state_value is Dictionary else {}
	if bool(state.get("completed", false)) or delta <= 0.0:
		return state
	var encounter: Dictionary = state.get("encounter", {})
	var wave: Array = state.get("wave", [])
	var type_id := str(state.get("type_id", ""))
	var type_definition: Dictionary = state.get("type_definition", {})
	var elapsed := float(state.get("elapsed", 0.0)) + delta
	state["elapsed"] = elapsed
	var next_spawn := int(state.get("next_spawn_index", 0))
	var enemies: Array = state.get("enemies", []).duplicate(true)
	while next_spawn < wave.size() and float(wave[next_spawn].get("spawn_second", 0.0)) <= elapsed:
		var entry: Dictionary = wave[next_spawn]
		var hp := float(entry.get("hp", 1.0))
		var damage := int(entry.get("banner_damage", 0))
		if type_id == TYPE_SUPPLY:
			var threat_multiplier := maxf(1.0, float(type_definition.get("raid_threat_multiplier", 1.0)))
			hp *= threat_multiplier
			damage = int(round(damage * threat_multiplier))
		var travel_seconds := float(encounter.get("enemy_travel_seconds", 12.0))
		if type_id == TYPE_WATCH and next_spawn == 0:
			travel_seconds += maxf(0.0, float(type_definition.get("first_entry_delay_seconds", 0.0)))
		var detoured := false
		if type_id == TYPE_FALSE_GATE:
			var stride := maxi(1, int(type_definition.get("detour_stride", 3)))
			detoured = (next_spawn + 1) % stride == 0
			if detoured:
				travel_seconds *= 1.5
				state["detoured_count"] = int(state.get("detoured_count", 0)) + 1
		enemies.append({"id": next_spawn, "hp": hp, "max_hp": hp, "damage": damage, "progress": 0.0, "travel_seconds": travel_seconds, "detoured": detoured})
		next_spawn += 1
	state["next_spawn_index"] = next_spawn
	var defender_dps := float(encounter.get("defender_dps_per_monster", 0.0)) * int(state.get("defender_count", 0))
	if defender_dps > 0.0 and not enemies.is_empty():
		var target_index := 0
		for index in range(1, enemies.size()):
			if float(enemies[index].get("progress", 0.0)) > float(enemies[target_index].get("progress", 0.0)):
				target_index = index
		enemies[target_index]["hp"] = float(enemies[target_index].get("hp", 0.0)) - defender_dps * delta
	var banner_hp := int(state.get("banner_hp", 0))
	for index in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[index]
		if float(enemy.get("hp", 0.0)) <= 0.0:
			enemies.remove_at(index)
			continue
		var travel_seconds := maxf(0.1, float(enemy.get("travel_seconds", encounter.get("enemy_travel_seconds", 12.0))))
		enemy["progress"] = float(enemy.get("progress", 0.0)) + delta / travel_seconds
		enemies[index] = enemy
		if float(enemy.get("progress", 0.0)) >= 1.0:
			banner_hp = maxi(0, banner_hp - int(enemy.get("damage", 0)))
			enemies.remove_at(index)
	if type_id == TYPE_SUPPLY and not bool(state.get("supply_chest_used", false)) and elapsed >= 22.0 and banner_hp < int(state.get("banner_max_hp", 0)):
		var healing := maxi(1, int(round(int(state.get("banner_max_hp", 1)) * maxf(0.0, float(type_definition.get("recovery_chest_ratio", 0.0))))))
		var healed := mini(healing, int(state.get("banner_max_hp", 1)) - banner_hp)
		banner_hp += healed
		state["supply_chest_used"] = true
		state["supply_chest_healing"] = healed
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
		"retry_count": int(state.get("retry_count", 0)),
		"type_id": str(state.get("type_id", "")),
		"reward": _battle_reward(state),
		"effect_metrics": {
			"supply_chest_used": bool(state.get("supply_chest_used", false)),
			"supply_chest_healing": int(state.get("supply_chest_healing", 0)),
			"detoured_count": int(state.get("detoured_count", 0))
		}
	}


static func run_placeholder_trial(outpost: Dictionary, encounter: Dictionary, day: int, retry_count: int = 0, type_definition: Dictionary = {}) -> Dictionary:
	var state := new_battle_state(outpost, encounter, day, retry_count, type_definition)
	var safety_steps := 0
	while not bool(state.get("completed", false)) and safety_steps < 1000:
		state = step(state, 0.1)
		safety_steps += 1
	return result(state)


static func settle_result(active_run_value, battle_result: Dictionary, profile_value = {}) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var profile: Dictionary = profile_value.duplicate(true) if profile_value is Dictionary else {}
	var day := int(battle_result.get("day", 0))
	if day not in BATTLE_DAYS:
		return {"ok": false, "error": "전초기지 방어전 DAY가 아닙니다.", "active_run": active_run, "profile": profile}
	var outpost: Dictionary = active_run.get("outpost", {}).duplicate(true)
	if str(outpost.get("type_id", "")) == "":
		return {"ok": false, "error": "건설된 전초기지가 없습니다.", "active_run": active_run, "profile": profile}
	var results: Array = outpost.get("battle_results", []).duplicate(true)
	for value in results:
		if value is Dictionary and int(value.get("day", 0)) == day:
			return {"ok": false, "error": "해당 DAY 전초기지 결산이 이미 기록되었습니다.", "active_run": active_run, "profile": profile}
	var stored := battle_result.duplicate(true)
	stored["settled"] = true
	results.append(stored)
	outpost["battle_results"] = results
	outpost["current_hp"] = clampi(int(stored.get("ending_hp", 0)), 0, int(outpost.get("max_hp", 0)))
	outpost["damaged"] = int(outpost.get("current_hp", 0)) < int(outpost.get("max_hp", 0))
	var stats: Dictionary = outpost.get("stats", _default_stats()).duplicate(true)
	stats["battles"] = int(stats.get("battles", 0)) + 1
	if bool(stored.get("win", false)):
		stats["wins"] = int(stats.get("wins", 0)) + 1
	else:
		stats["losses"] = int(stats.get("losses", 0)) + 1
	var hp_ratio := clampf(float(stored.get("ending_hp", 0)) / maxf(1.0, float(stored.get("max_hp", 1))), 0.0, 1.0)
	stats["total_ending_hp_ratio"] = float(stats.get("total_ending_hp_ratio", 0.0)) + hp_ratio
	stats["average_ending_hp_ratio"] = float(stats.get("total_ending_hp_ratio", 0.0)) / maxi(1, int(stats.get("battles", 1)))
	stats["day%d_win" % day] = bool(stored.get("win", false))
	if str(outpost.get("type_id", "")) == TYPE_SUPPLY and int(outpost.get("level", 0)) >= 2:
		stored["fatigue_cleared_monster_ids"] = outpost.get("assigned_monster_ids", []).duplicate()
		stats["fatigue_clear_count"] = int(stats.get("fatigue_clear_count", 0)) + stored["fatigue_cleared_monster_ids"].size()
		results[results.size() - 1] = stored
	if day == 20 and not bool(stored.get("win", false)):
		outpost["support_token_lost"] = true
		var council: Dictionary = active_run.get("council_season", {}).duplicate(true)
		council["rival_support_id"] = ""
		active_run["council_season"] = council
	var perfect := day == 20 and bool(stats.get("day10_win", false)) and bool(stats.get("day20_win", false)) and int(outpost.get("level", 0)) >= 2 and float(stats.get("average_ending_hp_ratio", 0.0)) >= 0.5
	if perfect and not bool(stats.get("perfect_run_recorded", false)):
		stats["perfect_run_recorded"] = true
		var profile_outpost: Dictionary = profile.get("outpost", {}).duplicate(true)
		profile_outpost["perfect_defenses"] = int(profile_outpost.get("perfect_defenses", 0)) + 1
		profile["outpost"] = profile_outpost
	outpost["stats"] = stats
	active_run["outpost"] = outpost
	var metrics: Dictionary = active_run.get("run_metrics_update4", {}).duplicate(true)
	metrics["outpost"] = {
		"type_id": str(outpost.get("type_id", "")), "level": int(outpost.get("level", 0)),
		"battles": int(stats.get("battles", 0)), "wins": int(stats.get("wins", 0)), "losses": int(stats.get("losses", 0)),
		"day10_win": bool(stats.get("day10_win", false)), "day20_win": bool(stats.get("day20_win", false)),
		"both_battles_won": bool(stats.get("day10_win", false)) and bool(stats.get("day20_win", false)),
		"banner_hp_average_ratio": float(stats.get("average_ending_hp_ratio", 0.0)),
		"support_token_lost": bool(outpost.get("support_token_lost", false)),
		"perfect_defense": bool(stats.get("perfect_run_recorded", false))
	}
	active_run["run_metrics_update4"] = metrics
	return {"ok": true, "error": "", "active_run": active_run, "profile": profile}


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


static func _battle_reward(state: Dictionary) -> Dictionary:
	if not bool(state.get("win", false)):
		return {"gold": 0, "food": 0}
	var definition: Dictionary = state.get("type_definition", {})
	var base: Dictionary = definition.get("win_reward", {})
	var multiplier := 1.5 if int(state.get("day", 0)) == 20 else 1.0
	return {"gold": int(round(int(base.get("gold", 0)) * multiplier)), "food": int(round(int(base.get("food", 0)) * multiplier))}


static func _default_stats() -> Dictionary:
	return {
		"battles": 0, "wins": 0, "losses": 0,
		"total_ending_hp_ratio": 0.0, "average_ending_hp_ratio": 0.0,
		"day10_win": false, "day20_win": false,
		"perfect_run_recorded": false, "fatigue_clear_count": 0
	}
