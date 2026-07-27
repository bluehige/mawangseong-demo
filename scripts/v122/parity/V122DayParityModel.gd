class_name V122DayParityModel
extends RefCounted

const ROOM_UPTIME := {
	"entrance": 1.20,
	"spike_corridor": 1.00,
	"barracks": 1.00,
	"recovery": 0.96,
	"treasure": 0.96,
	"slot_01": 0.82,
	"throne": 0.35
}

const ROLE_ROOMS := {
	"slime": ["entrance", "spike_corridor"],
	"goblin": ["barracks", "treasure"],
	"imp": ["recovery", "spike_corridor"]
}


static func evaluate(
	day: int,
	scenario: Dictionary,
	graph,
	monster_catalog: Dictionary,
	enemy_catalog: Dictionary,
	waves: Dictionary,
	monster_state: Dictionary,
	duration_range: Array
) -> Dictionary:
	var placements: Dictionary = scenario.get("placements", {})
	var effective_dps := 0.0
	var total_route_steps := 0
	var first_room := ""
	var first_rank := 999
	var room_ids: Array = placements.keys()
	room_ids.sort()
	for monster_id_value in room_ids:
		var monster_id := str(monster_id_value)
		var room_id := str(placements.get(monster_id, ""))
		var monster: Dictionary = monster_catalog.get(monster_id, {})
		var state: Dictionary = monster_state.get(monster_id, {})
		var base_dps := float(monster.get("atk", 0.0)) / maxf(0.1, float(monster.get("attack_interval", 1.0)))
		var level_multiplier := 1.0 + 0.08 * maxf(0.0, float(int(state.get("level", 1)) - 1))
		var room_multiplier := float(ROOM_UPTIME.get(room_id, 0.35))
		if ROLE_ROOMS.get(monster_id, []).has(room_id):
			room_multiplier += 0.12
		effective_dps += base_dps * level_multiplier * room_multiplier
		var route_steps: int = int(graph.path_between("outside_approach", room_id).size())
		total_route_steps += route_steps
		var rank: int = _room_rank(room_id)
		if rank < first_rank:
			first_rank = rank
			first_room = room_id

	var command_multiplier := 1.0
	for command_value in scenario.get("commands", []):
		if not command_value is Dictionary:
			continue
		match str(command_value.get("id", "")):
			"focus":
				command_multiplier *= 1.12
			"rally":
				command_multiplier *= 1.08
			"activate_facility":
				command_multiplier *= 1.10
			"emergency_fallback":
				command_multiplier *= 1.05
	effective_dps *= command_multiplier

	var wave_hp_budget := 0.0
	var thief_count := 0
	for wave_value in waves.get("day_%d" % day, []):
		if not wave_value is Dictionary:
			continue
		var wave: Dictionary = wave_value
		var enemy_id := str(wave.get("enemy_id", ""))
		var count := int(wave.get("count", 0))
		var enemy: Dictionary = enemy_catalog.get(enemy_id, {})
		wave_hp_budget += float(enemy.get("max_hp", 0.0)) * float(wave.get("hp_scale", 1.0)) * count
		if enemy_id == "thief":
			thief_count += count

	var midpoint := (float(duration_range[0]) + float(duration_range[1])) * 0.5
	var effective_damage := effective_dps * midpoint * 0.62
	var damage_ratio := wave_hp_budget / maxf(1.0, effective_damage)
	var estimated_duration := midpoint * clampf(damage_ratio + 0.45, 0.80, 1.35)
	var treasure_covered := str(placements.get("goblin", "")) in ["treasure", "barracks"]
	var gold_stolen := thief_count * 30 if thief_count > 0 and not treasure_covered else 0
	var throne_damage := maxi(0, int(round((wave_hp_budget - effective_damage) * 0.20)))
	var success := effective_damage >= wave_hp_budget * 0.90 and gold_stolen == 0
	return {
		"day": day,
		"success": success,
		"wave_hp_budget": snappedf(wave_hp_budget, 0.001),
		"effective_dps": snappedf(effective_dps, 0.001),
		"effective_damage": snappedf(effective_damage, 0.001),
		"estimated_duration_seconds": snappedf(estimated_duration, 0.001),
		"first_engagement_room": first_room,
		"total_route_steps": total_route_steps,
		"gold_stolen": gold_stolen,
		"throne_damage": throne_damage,
		"penalty_reason": "" if success else ("gold_stolen" if gold_stolen > 0 else "late_first_engagement")
	}


static func _room_rank(room_id: String) -> int:
	return int({
		"outside_approach": 0,
		"entrance": 1,
		"spike_corridor": 2,
		"barracks": 2,
		"recovery": 2,
		"treasure": 2,
		"slot_01": 3,
		"throne": 4
	}.get(room_id, 9))
