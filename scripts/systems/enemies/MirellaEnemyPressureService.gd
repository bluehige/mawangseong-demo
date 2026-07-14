extends RefCounted
class_name MirellaEnemyPressureService

const MAX_ACTIVE_ZONES := 2


static func place_wet_spore(active_zones: Array, zone_id: String, room_id: String, skill: Dictionary) -> Dictionary:
	for value in active_zones:
		if value is Dictionary and str(value.get("room_id", "")) == room_id:
			return {"ok": false, "reason": "same_zone_non_stacking", "zones": active_zones.duplicate(true)}
	if active_zones.size() >= MAX_ACTIVE_ZONES:
		return {"ok": false, "reason": "zone_cap", "zones": active_zones.duplicate(true)}
	var zones := active_zones.duplicate(true)
	zones.append({
		"id": zone_id,
		"room_id": room_id,
		"duration": float(skill.get("duration", 5.0)),
		"enemy_heal_multiplier": float(skill.get("enemy_heal_multiplier", 1.10)),
		"player_move_multiplier": float(skill.get("player_move_multiplier", 0.85))
	})
	return {"ok": true, "reason": "", "zones": zones}


static func cleanse_zone(active_zones: Array, zone_id: String) -> Array:
	var result := []
	for value in active_zones:
		if not (value is Dictionary) or str(value.get("id", "")) != zone_id:
			result.append(value)
	return result


static func fire_reduce_zone(zone: Dictionary, fire_power: float) -> Dictionary:
	var result := zone.duplicate(true)
	result["duration"] = maxf(0.0, float(result.get("duration", 0.0)) - maxf(0.0, fire_power) * 0.25)
	return result


static func place_root_barrier(active_barriers: Array, barrier_id: String, location_type: String, skill: Dictionary) -> Dictionary:
	if location_type not in ["threshold", "stair"]:
		return {"ok": false, "reason": "invalid_location", "barriers": active_barriers.duplicate(true)}
	if active_barriers.size() >= maxi(1, int(skill.get("max_simultaneous", 1))):
		return {"ok": false, "reason": "barrier_cap", "barriers": active_barriers.duplicate(true)}
	var barriers := active_barriers.duplicate(true)
	barriers.append({"id": barrier_id, "location_type": location_type, "duration": float(skill.get("duration", 6.0)), "hp": int(skill.get("barrier_hp", 45)), "player_move_multiplier": float(skill.get("player_move_multiplier", 0.55)), "enemy_move_multiplier": float(skill.get("enemy_move_multiplier", 1.0)), "cleansable": bool(skill.get("cleansable", true))})
	return {"ok": true, "reason": "", "barriers": barriers}


static func damage_barrier(barrier: Dictionary, damage: int) -> Dictionary:
	var result := barrier.duplicate(true)
	result["hp"] = maxi(0, int(result.get("hp", 0)) - maxi(0, damage))
	result["active"] = int(result.hp) > 0
	return result


static func has_deadlock(barrier: Dictionary, alternate_route_available: bool) -> bool:
	if alternate_route_available:
		return false
	return int(barrier.get("hp", 0)) <= 0 and not bool(barrier.get("cleansable", false))


static func region_wave(region_id: String, enemies: Dictionary) -> Dictionary:
	var counts := {"spore_doll": 2, "root_tender": 1} if region_id == "region_mistcap_marsh" else {"spore_doll": 2, "shadow_duelist": 1}
	var threat := 0.0
	for enemy_id in counts:
		threat += float(enemies.get(enemy_id, {}).get("threat", 0.0)) * int(counts[enemy_id])
	return {"counts": counts, "threat": threat, "target_threat": 3.575, "within_budget": absf(threat - 3.575) <= 3.575 * 0.05}


static func healing_build_trial(spore_count: int, has_cleanse: bool, has_fire: bool) -> Dictionary:
	var baseline_survival := 100.0
	var loss := minf(25.0, maxi(0, spore_count) * 11.0)
	if has_cleanse:
		loss *= 0.55
	if has_fire:
		loss *= 0.75
	return {"baseline_survival": baseline_survival, "effective_survival": baseline_survival - loss, "efficiency_reduction_ratio": loss / baseline_survival, "completable": baseline_survival - loss >= 70.0}
