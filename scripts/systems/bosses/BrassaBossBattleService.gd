extends RefCounted
class_name BrassaBossBattleService


static func battle_profile(day: int, enemy: Dictionary) -> Dictionary:
	var final_battle := day == 30
	return {
		"day": day,
		"max_hp": int(enemy.get("max_hp", 620)) if final_battle else roundi(int(enemy.get("max_hp", 620)) * 0.75),
		"skills": enemy.get("skills", []).duplicate() if final_battle else enemy.get("skills", []).slice(0, 3),
		"stage_count": 3,
		"retry_day": day
	}


static func place_iron_wall(active_walls: Array, room_id: String, available_paths: int, skill: Dictionary) -> Dictionary:
	if active_walls.size() >= maxi(1, int(skill.get("max_active_walls", 1))):
		return {"ok": false, "walls": active_walls.duplicate(true), "reason": "wall_cap"}
	var walls := active_walls.duplicate(true)
	walls.append({
		"id": "brassa_wall_%s" % room_id,
		"room_id": room_id,
		"hp": int(skill.get("wall_hp", 90)),
		"blocks_players": true,
		"blocks_enemies": true,
		"decay_seconds": float(skill.get("single_path_decay_seconds", 8.0)) if available_paths <= 1 else 0.0,
		"destructible": true
	})
	return {"ok": true, "walls": walls, "reason": ""}


static func damage_wall(wall: Dictionary, damage: int) -> Dictionary:
	var result := wall.duplicate(true)
	result["hp"] = maxi(0, int(result.get("hp", 0)) - maxi(0, damage))
	result["active"] = int(result.hp) > 0
	return result


static func wall_can_deadlock(wall: Dictionary, available_paths: int) -> bool:
	return available_paths <= 1 and not bool(wall.get("destructible", false)) and float(wall.get("decay_seconds", 0.0)) <= 0.0


static func apply_overheat(units: Array, skill: Dictionary) -> Array:
	var result := []
	for value in units:
		if not (value is Dictionary):
			continue
		var unit: Dictionary = value.duplicate(true)
		if str(unit.get("enemy_id", "")) == "bronze_automaton":
			unit["move_speed"] = float(unit.get("move_speed", 0.0)) * float(skill.get("move_multiplier", 1.20))
			unit["atk"] = float(unit.get("atk", 0.0)) * float(skill.get("atk_multiplier", 1.15))
			unit["incoming_damage_multiplier"] = float(skill.get("incoming_damage_multiplier", 1.15))
			unit["overheat_seconds"] = float(skill.get("duration", 6.0))
		result.append(unit)
	return result


static func weight_test(room_id: String, facility_present: bool, skill: Dictionary) -> Dictionary:
	return {"room_id": room_id, "warning_seconds": float(skill.get("warning_seconds", 2.0)), "room_damage": int(skill.get("room_damage", 38)), "facility_damage": int(skill.get("facility_extra_damage", 12)) if facility_present else 0}


static func verdict_targets(crown_active: bool, facilities: Array) -> Array[String]:
	var result: Array[String] = []
	if crown_active:
		result.append("crown_sanctum")
	var best_id := ""
	var best_level := -1
	for value in facilities:
		if not (value is Dictionary) or not bool(value.get("active", true)):
			continue
		var level := int(value.get("level", 0))
		if level > best_level:
			best_level = level
			best_id = str(value.get("id", ""))
	if best_id != "":
		result.append(best_id)
	return result


static func stage_action(stage: int, day: int) -> String:
	if stage <= 1:
		return "bell_foundry"
	if stage == 2:
		return "overheat_order"
	return "weight_test" if day == 25 else "weight_test_then_castle_load_verdict"


static func resolve_battle(active_run_value, day: int, won: bool, battle_stats: Dictionary) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var metrics: Dictionary = active_run.get("run_metrics_update4", {}).duplicate(true)
	var bosses: Dictionary = metrics.get("rival_bosses", {}).duplicate(true)
	var brassa: Dictionary = bosses.get("rival_brassa", {}).duplicate(true)
	brassa["attempts"] = int(brassa.get("attempts", 0)) + 1
	brassa["wins"] = int(brassa.get("wins", 0)) + (1 if won else 0)
	brassa["losses"] = int(brassa.get("losses", 0)) + (0 if won else 1)
	brassa["facility_damage"] = int(brassa.get("facility_damage", 0)) + int(battle_stats.get("facility_damage", 0))
	brassa["walls_destroyed"] = int(brassa.get("walls_destroyed", 0)) + int(battle_stats.get("walls_destroyed", 0))
	bosses["rival_brassa"] = brassa
	metrics["rival_bosses"] = bosses
	active_run["run_metrics_update4"] = metrics
	return {"active_run": active_run, "won": won, "retry_day": 0 if won else day, "return_screen": "settlement" if won else "management"}
