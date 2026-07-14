extends RefCounted
class_name MirellaBossBattleService


static func battle_profile(day: int, enemy: Dictionary) -> Dictionary:
	var final_battle := day == 30
	return {"day": day, "max_hp": int(enemy.get("max_hp", 590)) if final_battle else roundi(int(enemy.get("max_hp", 590)) * 0.75), "skills": enemy.get("skills", []).duplicate() if final_battle else enemy.get("skills", []).slice(0, 3), "stage_count": 3, "max_duration_seconds": 240.0 if final_battle else 180.0, "retry_day": day}


static func create_sleeping_garden(active_gardens: Array, room_id: String, skill: Dictionary) -> Dictionary:
	if active_gardens.size() >= maxi(1, int(skill.get("max_active_rooms", 1))):
		return {"ok": false, "gardens": active_gardens.duplicate(true), "reason": "garden_cap"}
	var gardens := active_gardens.duplicate(true)
	gardens.append({"room_id": room_id, "remaining": float(skill.get("duration", 7.0)), "telegraph_seconds": float(skill.get("telegraph_seconds", 2.0)), "telegraph_color": str(skill.get("telegraph_color", "#8BD77B")), "edge_ring": bool(skill.get("edge_ring", true)), "remaining_time_label": bool(skill.get("remaining_time_label", true))})
	return {"ok": true, "gardens": gardens, "reason": ""}


static func apply_garden_weakness(garden: Dictionary, cleanse: bool, fire_power: float, skill: Dictionary) -> Dictionary:
	var result := garden.duplicate(true)
	var reduction := float(skill.get("cleanse_reduction_seconds", 3.0)) if cleanse else 0.0
	reduction += maxf(0.0, fire_power) * float(skill.get("fire_reduction_per_power", 0.30))
	result["remaining"] = maxf(0.0, float(result.get("remaining", 0.0)) - reduction)
	result["active"] = float(result.remaining) > 0.0
	return result


static func pruning_choice(buffs: Array, current_hp: int, max_hp: int, skill: Dictionary) -> Dictionary:
	var best_index := -1
	var best_power := -INF
	for index in buffs.size():
		var value = buffs[index]
		if not (value is Dictionary) or not bool(value.get("temporary", false)):
			continue
		var power := float(value.get("power", 0.0))
		if power > best_power:
			best_power = power
			best_index = index
	var remaining := buffs.duplicate(true)
	var removed_id := ""
	if best_index >= 0:
		removed_id = str(remaining[best_index].get("id", ""))
		remaining.remove_at(best_index)
	var healed_hp := mini(maxi(1, max_hp), maxi(0, current_hp) + roundi(maxi(1, max_hp) * float(skill.get("target_heal_ratio", 0.15)))) if best_index >= 0 else maxi(0, current_hp)
	return {"removed_buff_id": removed_id, "remaining_buffs": remaining, "hp": healed_hp}


static func regrowth_vote(defeated_enemies: Array, skill: Dictionary) -> Dictionary:
	for value in defeated_enemies:
		if value is Dictionary and str(value.get("enemy_id", "")) == "spore_doll":
			var max_hp := maxi(1, int(value.get("max_hp", 120)))
			return {"ok": true, "enemy_id": "spore_doll", "hp": roundi(max_hp * float(skill.get("revive_hp_ratio", 0.30))), "max_hp": max_hp}
	return {"ok": false, "reason": "no_spore_doll"}


static func create_crown_roots(skill: Dictionary) -> Array:
	var roots := []
	for index in maxi(0, int(skill.get("root_count", 3))):
		roots.append({"id": "crown_root_%d" % (index + 1), "hp": int(skill.get("root_hp", 55)), "active": true})
	return roots


static func damage_crown_root(roots: Array, root_id: String, damage: int, skill: Dictionary) -> Dictionary:
	var result := roots.duplicate(true)
	for index in result.size():
		if str(result[index].get("id", "")) != root_id:
			continue
		var root: Dictionary = result[index].duplicate(true)
		root["hp"] = maxi(0, int(root.get("hp", 0)) - maxi(0, damage))
		root["active"] = int(root.hp) > 0
		result[index] = root
	var all_cleared := true
	for root in result:
		if bool(root.get("active", false)):
			all_cleared = false
			break
	return {"roots": result, "all_cleared": all_cleared, "boss_def_multiplier": float(skill.get("boss_def_multiplier_on_clear", 0.70)) if all_cleared else 1.0, "vulnerability_seconds": float(skill.get("vulnerability_seconds", 8.0)) if all_cleared else 0.0}


static func time_cap_state(elapsed_seconds: float, profile: Dictionary) -> Dictionary:
	var capped := elapsed_seconds >= float(profile.get("max_duration_seconds", 240.0))
	return {"capped": capped, "regrowth_enabled": not capped, "boss_incoming_damage_multiplier": 1.50 if capped else 1.0, "clear_active_gardens": capped}


static func resolve_battle(active_run_value, day: int, won: bool, battle_stats: Dictionary) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var metrics: Dictionary = active_run.get("run_metrics_update4", {}).duplicate(true)
	var bosses: Dictionary = metrics.get("rival_bosses", {}).duplicate(true)
	var mirella: Dictionary = bosses.get("rival_mirella", {}).duplicate(true)
	mirella["attempts"] = int(mirella.get("attempts", 0)) + 1
	mirella["wins"] = int(mirella.get("wins", 0)) + (1 if won else 0)
	mirella["losses"] = int(mirella.get("losses", 0)) + (0 if won else 1)
	mirella["gardens_cleansed"] = int(mirella.get("gardens_cleansed", 0)) + int(battle_stats.get("gardens_cleansed", 0))
	mirella["roots_destroyed"] = int(mirella.get("roots_destroyed", 0)) + int(battle_stats.get("roots_destroyed", 0))
	bosses["rival_mirella"] = mirella
	metrics["rival_bosses"] = bosses
	active_run["run_metrics_update4"] = metrics
	return {"active_run": active_run, "won": won, "retry_day": 0 if won else day, "return_screen": "settlement" if won else "management"}
