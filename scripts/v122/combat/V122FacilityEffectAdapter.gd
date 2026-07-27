class_name V122FacilityEffectAdapter
extends RefCounted

const ROLE_RULES := {
	"barracks": {"radius": 280.0, "faction": "monster", "damage_multiplier": 1.10, "damage_taken_multiplier": 0.92},
	"recovery": {"radius": 260.0, "faction": "monster", "heal_per_second": 8.0},
	"watch_post": {"radius": 360.0, "faction": "enemy", "move_speed_multiplier": 0.82, "damage_taken_multiplier": 1.12, "revealed": true},
	"ward_core": {"radius": -1.0, "faction": "monster", "damage_taken_multiplier": 0.90}
}


static func effect_for_actor(
	facility_slot: Dictionary,
	actor: Dictionary,
	disabled_remaining: float = 0.0,
	power_multiplier: float = 1.0
) -> Dictionary:
	if disabled_remaining > 0.0:
		return {}
	var role := str(facility_slot.get("facility_role", ""))
	var rule: Dictionary = ROLE_RULES.get(role, {})
	if rule.is_empty() or str(rule.get("faction", "")) != str(actor.get("faction", "")):
		return {}
	var facility_position := _array_vector(facility_slot.get("world_anchor", []))
	var actor_position := _array_vector(actor.get("world_anchor", []))
	var radius := float(rule.get("radius", 0.0))
	if radius >= 0.0 and facility_position.distance_to(actor_position) > radius:
		return {}
	var result := {
		"source_room_id": str(facility_slot.get("room_id", "")),
		"facility_role": role,
		"distance": snappedf(facility_position.distance_to(actor_position), 0.001)
	}
	for key_value in rule.keys():
		var key := str(key_value)
		if key in ["radius", "faction"]:
			continue
		var value = rule.get(key)
		if value is int or value is float:
			result[key] = 1.0 + (float(value) - 1.0) * power_multiplier if key.ends_with("_multiplier") else float(value) * power_multiplier
		else:
			result[key] = value
	return result


static func _array_vector(value) -> Vector2:
	return Vector2(float(value[0]), float(value[1])) if value is Array and value.size() >= 2 else Vector2.ZERO
