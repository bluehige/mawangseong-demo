extends RefCounted
class_name VesperBossBattleService


static func battle_profile(day: int, enemy: Dictionary) -> Dictionary:
	var final_battle := day == 30
	return {"day": day, "max_hp": int(enemy.get("max_hp", 540)) if final_battle else roundi(int(enemy.get("max_hp", 540)) * 0.75), "skills": enemy.get("skills", []).duplicate() if final_battle else enemy.get("skills", []).slice(0, 3), "stage_count": 3, "retry_day": day}


static func deadline_dive(from_room: String, to_room: String, transition_endpoints: Dictionary, skill: Dictionary) -> Dictionary:
	var path_id := "%s:%s" % [from_room, to_room]
	var endpoints = transition_endpoints.get(path_id, [])
	if not (endpoints is Array) or endpoints.size() < 2 or from_room == to_room:
		return {"ok": false, "reason": "invalid_passage_path"}
	return {
		"ok": true,
		"path_id": path_id,
		"endpoints": endpoints.duplicate(),
		"warning_seconds": float(skill.get("warning_seconds", 1.5)),
		"travel_seconds": float(skill.get("travel_seconds", 0.7)),
		"silence_seconds": float(skill.get("arrival_silence_seconds", 1.5)),
		"arrival_lock_seconds": float(skill.get("arrival_lock_seconds", 1.0)),
		"target_room": to_room,
		"objective_alert": true
	}


static func start_seal_snatch(skill: Dictionary) -> Dictionary:
	return {"active": true, "remaining": float(skill.get("channel_seconds", 5.0)), "incoming_damage_multiplier": float(skill.get("incoming_damage_multiplier", 1.25)), "completed": false}


static func tick_seal_snatch(state: Dictionary, delta: float) -> Dictionary:
	var result := state.duplicate(true)
	if not bool(result.get("active", false)):
		return result
	result["remaining"] = maxf(0.0, float(result.get("remaining", 0.0)) - maxf(0.0, delta))
	if is_zero_approx(float(result.remaining)):
		result["active"] = false
		result["completed"] = true
	return result


static func airmail_exchange(boss: Dictionary, couriers: Array, valid_room_ids: Array, skill: Dictionary) -> Dictionary:
	for value in couriers:
		if not (value is Dictionary) or not bool(value.get("active", true)):
			continue
		var courier: Dictionary = value.duplicate(true)
		if str(boss.get("room_id", "")) not in valid_room_ids or str(courier.get("room_id", "")) not in valid_room_ids:
			continue
		var moved_boss := boss.duplicate(true)
		var boss_room = moved_boss.get("room_id")
		var boss_position = moved_boss.get("position")
		moved_boss["room_id"] = courier.get("room_id")
		moved_boss["position"] = courier.get("position")
		courier["room_id"] = boss_room
		courier["position"] = boss_position
		return {"ok": true, "boss": moved_boss, "courier": courier, "arrival_lock_seconds": float(skill.get("arrival_lock_seconds", 1.0))}
	return {"ok": false, "reason": "no_valid_courier"}


static func return_to_sender(skill_history: Array, skill: Dictionary) -> Dictionary:
	for index in range(skill_history.size() - 1, -1, -1):
		var value = skill_history[index]
		if value is Dictionary and bool(value.get("position_skill", false)):
			return {"ok": true, "skill_id": str(value.get("skill_id", "")), "cooldown_increase_seconds": float(skill.get("cooldown_increase_seconds", 4.0))}
	return {"ok": false, "reason": "no_position_skill"}


static func resolve_battle(active_run_value, day: int, won: bool, battle_stats: Dictionary) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var metrics: Dictionary = active_run.get("run_metrics_update4", {}).duplicate(true)
	var bosses: Dictionary = metrics.get("rival_bosses", {}).duplicate(true)
	var vesper: Dictionary = bosses.get("rival_vesper", {}).duplicate(true)
	vesper["attempts"] = int(vesper.get("attempts", 0)) + 1
	vesper["wins"] = int(vesper.get("wins", 0)) + (1 if won else 0)
	vesper["losses"] = int(vesper.get("losses", 0)) + (0 if won else 1)
	vesper["seal_channels_completed"] = int(vesper.get("seal_channels_completed", 0)) + int(battle_stats.get("seal_channels_completed", 0))
	vesper["passage_transitions"] = int(vesper.get("passage_transitions", 0)) + int(battle_stats.get("passage_transitions", 0))
	bosses["rival_vesper"] = vesper
	metrics["rival_bosses"] = bosses
	active_run["run_metrics_update4"] = metrics
	return {"active_run": active_run, "won": won, "retry_day": 0 if won else day, "return_screen": "settlement" if won else "management"}
