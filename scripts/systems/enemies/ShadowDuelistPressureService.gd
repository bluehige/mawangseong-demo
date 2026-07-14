extends RefCounted
class_name ShadowDuelistPressureService


static func select_target(candidates: Array, recent_contribution: Dictionary) -> String:
	var selected_id := ""
	var selected_score := -INF
	for value in candidates:
		if not (value is Dictionary) or not bool(value.get("active", true)):
			continue
		var candidate_id := str(value.get("id", ""))
		var score := float(recent_contribution.get(candidate_id, 0.0))
		if score > selected_score or (is_equal_approx(score, selected_score) and candidate_id < selected_id):
			selected_id = candidate_id
			selected_score = score
	return selected_id


static func shadow_promise(target: Dictionary, skill: Dictionary, already_used: bool, duelist_floor: String) -> Dictionary:
	if already_used or str(target.get("floor_id", "")) != duelist_floor:
		return {"ok": false, "used": already_used}
	var target_position := float(target.get("position_x", 0.0))
	var facing := signf(float(target.get("facing_x", 1.0)))
	if is_zero_approx(facing):
		facing = 1.0
	return {
		"ok": true,
		"used": true,
		"position_x": target_position - facing * float(skill.get("behind_distance", 90.0)),
		"duration": float(skill.get("duration", 2.0)),
		"atk_multiplier": float(skill.get("atk_multiplier", 1.20)),
		"def_multiplier": float(skill.get("def_multiplier", 0.75))
	}


static func cross_floor_wave(region_id: String, enemies: Dictionary) -> Dictionary:
	var counts := {}
	var floors := []
	var target_threat := 3.4
	if region_id == "region_moonbat_aerie":
		counts = {"dusk_courier": 2, "shadow_duelist": 1}
		floors = [{"floor_id": "lower_01", "enemy_ids": ["shadow_duelist"]}, {"floor_id": "upper_02", "enemy_ids": ["dusk_courier", "dusk_courier"], "delay_seconds": 3.0}]
	elif region_id == "region_blackwater_exchange":
		counts = {"bronze_automaton": 1, "dusk_courier": 2}
		floors = [{"floor_id": "lower_01", "enemy_ids": ["bronze_automaton"]}, {"floor_id": "upper_02", "enemy_ids": ["dusk_courier", "dusk_courier"], "delay_seconds": 2.5}]
	var threat := 0.0
	for enemy_id in counts:
		threat += float(enemies.get(enemy_id, {}).get("threat", 0.0)) * int(counts[enemy_id])
	return {"counts": counts, "floors": floors, "threat": threat, "target_threat": target_threat, "within_budget": absf(threat - target_threat) <= target_threat * 0.05}


static func focus_efficiency_trial(duelist_count: int) -> Dictionary:
	var baseline_seconds := 20.0
	var lost_seconds := minf(baseline_seconds * 0.30, maxi(0, duelist_count) * 5.0)
	return {"baseline_seconds": baseline_seconds, "effective_seconds": baseline_seconds - lost_seconds, "efficiency_reduction_ratio": lost_seconds / baseline_seconds}


static func protection_response(guard_redirect: bool, rescue_ready: bool, emergency_stitch_ready: bool, floor_transfer_ready: bool) -> Dictionary:
	var options: Array[String] = []
	if guard_redirect:
		options.append("protect")
	if rescue_ready or emergency_stitch_ready:
		options.append("rescue")
	if floor_transfer_ready:
		options.append("floor_transfer")
	return {"viable": not options.is_empty(), "options": options, "requires_crown": false}
