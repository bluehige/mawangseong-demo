extends RefCounted
class_name BronzeAutomatonPressureService


static func choose_goal(facilities: Array, stair_queue_size: int) -> String:
	var best_id := ""
	var best_ratio := 2.0
	for value in facilities:
		if not (value is Dictionary) or not bool(value.get("active", true)):
			continue
		var max_hp := maxf(1.0, float(value.get("max_hp", 1.0)))
		var ratio := float(value.get("hp", max_hp)) / max_hp
		if ratio < best_ratio:
			best_ratio = ratio
			best_id = str(value.get("id", ""))
	if best_id != "":
		return best_id
	return "upper_stair" if stair_queue_size == 0 else "facility_route"


static func apply_heavy_body(knockback_distance: float, skill: Dictionary) -> float:
	return maxf(0.0, knockback_distance) * clampf(float(skill.get("knockback_multiplier", 0.5)), 0.0, 1.0)


static func brace_state(base_def: int, skill: Dictionary) -> Dictionary:
	return {
		"duration": float(skill.get("duration", 4.0)),
		"def": ceili(maxi(0, base_def) * float(skill.get("def_multiplier", 1.25))),
		"move_multiplier": float(skill.get("move_multiplier", 0.0))
	}


static func can_enter_stair(current_automaton_transitions: int, enemy_definition: Dictionary) -> bool:
	return current_automaton_transitions < maxi(1, int(enemy_definition.get("max_stair_transitioning", 1)))


static func facility_pressure(base_damage: int, base_repair: int, overlay: Dictionary) -> Dictionary:
	return {
		"damage": roundi(maxi(0, base_damage) * float(overlay.get("facility_damage_multiplier", 1.0))),
		"repair": roundi(maxi(0, base_repair) * float(overlay.get("facility_repair_multiplier", 1.0)))
	}


static func outpost_wave_variant(enemies: Dictionary) -> Dictionary:
	var counts := {"bronze_automaton": 1, "coal_spark": 3}
	var threat := 0.0
	for enemy_id in counts:
		threat += float(enemies.get(enemy_id, {}).get("threat", 0.0)) * int(counts[enemy_id])
	return {
		"id": "ironbell_reinforced_frontline",
		"counts": counts,
		"threat": threat,
		"target_threat": 4.0,
		"within_budget": absf(threat - 4.0) <= 0.2
	}


static func fixed_defense_efficiency_trial(automaton_count: int) -> Dictionary:
	var baseline_uptime := 20.0
	var lost_uptime := minf(baseline_uptime * 0.30, maxi(0, automaton_count) * 5.0)
	return {
		"baseline_uptime": baseline_uptime,
		"countered_uptime": baseline_uptime - lost_uptime,
		"efficiency_reduction_ratio": lost_uptime / baseline_uptime
	}


static func alternative_response(armor_break: float, magic_damage: float, bypass_available: bool) -> Dictionary:
	return {
		"viable": armor_break >= 0.20 or magic_damage >= 18.0 or bypass_available,
		"requires_fixed_defense": false
	}
