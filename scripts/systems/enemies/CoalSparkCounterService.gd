extends RefCounted
class_name CoalSparkCounterService


static func choose_objective(upper_floor: Dictionary, heart_active: bool) -> String:
	var crown_hp := int(upper_floor.get("objective_hp", {}).get("crown_sanctum", 0))
	if crown_hp > 0:
		return "crown_sanctum"
	return "heart_chamber" if heart_active else "throne_route"


static func contact_thread(thread_state: Dictionary, enemy_definition: Dictionary) -> Dictionary:
	var thread := thread_state.duplicate(true)
	if not bool(thread.get("active", false)):
		return {"thread": thread, "durability_damage": 0, "removed": false}
	var damage := maxi(0, int(enemy_definition.get("thread_durability_damage", 2)))
	thread["fire_durability"] = maxi(0, int(thread.get("fire_durability", 0)) - damage)
	if int(thread.get("fire_durability", 0)) <= 0:
		thread["active"] = false
	return {"thread": thread, "durability_damage": damage, "removed": not bool(thread.get("active", false))}


static func enter_objective(enemy_id: String, objective_id: String, residual_skill: Dictionary) -> Dictionary:
	return {
		"enemy_id": enemy_id,
		"objective_id": objective_id,
		"heat_zone": {"active": true, "duration": float(residual_skill.get("duration", 4.0)), "radius": float(residual_skill.get("radius", 72.0)), "damage_per_second": int(residual_skill.get("damage_per_second", 3)), "non_stacking": bool(residual_skill.get("non_stacking", true))},
		"death_explosion": bool(residual_skill.get("death_explosion", false))
	}


static func silky_efficiency_trial(specialization_id: String, coal_sparks: int) -> Dictionary:
	var baseline_control_seconds := 16.0 if specialization_id != "silky_field_tailor" else 12.0
	var reduction_per_spark := 4.5 if specialization_id == "silky_stair_warden" else 4.0
	var reduced := minf(baseline_control_seconds * 0.35, maxi(0, coal_sparks) * reduction_per_spark)
	var remaining := baseline_control_seconds - reduced
	return {"baseline_control_seconds": baseline_control_seconds, "countered_control_seconds": remaining, "efficiency_reduction_ratio": reduced / baseline_control_seconds}


static func alternative_response(enemy_definition: Dictionary, fast_interceptor_dps: float, control_seconds: float) -> Dictionary:
	var time_to_defeat := float(enemy_definition.get("max_hp", 75)) / maxf(1.0, fast_interceptor_dps)
	var controlled_long_enough := control_seconds >= minf(2.0, time_to_defeat)
	return {"viable": time_to_defeat <= 6.0 or controlled_long_enough, "time_to_defeat": time_to_defeat, "requires_silky": false}
