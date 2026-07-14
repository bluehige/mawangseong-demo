extends RefCounted
class_name DuskCourierCounterService


static func can_spawn(active_count: int, enemy_definition: Dictionary) -> bool:
	return active_count >= 0 and active_count < maxi(1, int(enemy_definition.get("max_simultaneous", 2)))


static func air_shortcut_path(from_floor: String, target_id: String, outpost_battle: bool = false) -> Array[Dictionary]:
	var to_floor := "1F" if outpost_battle else "2F"
	var path: Array[Dictionary] = [{"floor_id": from_floor, "node": "vent_entry"}, {"floor_id": to_floor, "node": "vent_exit"}]
	path.append({"floor_id": to_floor, "node": "outpost_cache" if outpost_battle else target_id})
	return path


static func new_theft_state(courier_id: String, skill: Dictionary) -> Dictionary:
	return {"courier_id": courier_id, "phase": "idle", "channel_remaining": float(skill.get("channel_seconds", 4.0)), "retry_remaining": 0.0, "completed": false, "blocked": false, "damage_interrupts": 0}


static func start_theft(state_value, skill: Dictionary, alarm_delay_seconds: float = 0.0) -> Dictionary:
	var state: Dictionary = state_value.duplicate(true) if state_value is Dictionary else new_theft_state("", skill)
	if bool(state.get("completed", false)):
		return state
	state["phase"] = "warning" if alarm_delay_seconds > 0.0 else "channel"
	state["retry_remaining"] = maxf(0.0, alarm_delay_seconds)
	state["channel_remaining"] = float(skill.get("channel_seconds", 4.0))
	return state


static func receive_damage(state_value, skill: Dictionary) -> Dictionary:
	var state: Dictionary = state_value.duplicate(true)
	if str(state.get("phase", "")) == "channel":
		state["phase"] = "retry_wait"
		state["retry_remaining"] = float(skill.get("retry_delay_after_hit", 1.0))
		state["channel_remaining"] = float(skill.get("channel_seconds", 4.0))
		state["damage_interrupts"] = int(state.get("damage_interrupts", 0)) + 1
		state["blocked"] = true
	return state


static func tick_theft(state_value, delta: float) -> Dictionary:
	var state: Dictionary = state_value.duplicate(true)
	if delta <= 0.0 or bool(state.get("completed", false)):
		return state
	var phase := str(state.get("phase", "idle"))
	if phase in ["warning", "retry_wait"]:
		state["retry_remaining"] = maxf(0.0, float(state.get("retry_remaining", 0.0)) - delta)
		if float(state.get("retry_remaining", 0.0)) <= 0.0:
			state["phase"] = "channel"
	elif phase == "channel":
		state["channel_remaining"] = maxf(0.0, float(state.get("channel_remaining", 0.0)) - delta)
		if float(state.get("channel_remaining", 0.0)) <= 0.0001:
			state["channel_remaining"] = 0.0
			state["phase"] = "complete"
			state["completed"] = true
	return state


static func popo_efficiency_trial(courier_count: int, popo_specialization_id: String) -> Dictionary:
	var baseline_recovery_chance := 0.88 if popo_specialization_id == "popo_seal_guard" else 0.80
	var congestion_penalty := maxf(0.0, float(maxi(0, courier_count - 1)) * 0.24)
	var countered := maxf(0.0, baseline_recovery_chance * (1.0 - congestion_penalty))
	return {"baseline": baseline_recovery_chance, "countered": countered, "efficiency_reduction_ratio": 0.0 if baseline_recovery_chance <= 0.0 else 1.0 - countered / baseline_recovery_chance}


static func alternative_response(courier_count: int, interceptors: int, watch_delay_seconds: float, split_guard: bool) -> Dictionary:
	var stopped := mini(courier_count, maxi(0, interceptors))
	if watch_delay_seconds >= 2.0:
		stopped = mini(courier_count, stopped + 1)
	if split_guard and stopped < courier_count:
		stopped += 1
	return {"viable": stopped >= courier_count, "stopped": stopped, "requires_popo": false}
