extends RefCounted
class_name SilkyCombatService

const SPEC_WARDEN := "silky_stair_warden"
const SPEC_TAILOR := "silky_field_tailor"


static func new_state() -> Dictionary:
	return {"thread": {}, "rescues": 0, "transition_uses": 0, "ai_repaths": 0}


static func place_thread(state_value, requested_anchor: String, available_anchors: Array, specialization_id: String, skill: Dictionary) -> Dictionary:
	var state: Dictionary = state_value.duplicate(true) if state_value is Dictionary else new_state()
	var anchor := requested_anchor
	if anchor == "" or anchor not in available_anchors:
		for fallback in ["stair", "threshold", "outpost_retreat"]:
			if fallback in available_anchors:
				anchor = fallback
				break
	if anchor == "" or anchor not in available_anchors:
		return {"ok": false, "error": "거미실을 설치할 계단·문턱·퇴각 통로가 없습니다.", "state": state}
	var target_count := maxi(1, int(skill.get("max_slow_targets", 4)))
	var slow_multiplier := float(skill.get("slow_multiplier", 0.65))
	var fire_durability := maxi(1, int(skill.get("fire_hits_to_remove", 2)))
	if specialization_id == SPEC_WARDEN:
		slow_multiplier = 0.60
		fire_durability += 1
	elif specialization_id == SPEC_TAILOR:
		target_count = maxi(1, target_count - 1)
	state["thread"] = {"anchor": anchor, "remaining_targets": target_count, "slow_multiplier": slow_multiplier, "slow_seconds": float(skill.get("slow_seconds", 4.0)), "fire_durability": fire_durability, "active": true}
	return {"ok": true, "error": "", "state": state}


static func trigger_thread(state_value, enemy_id: String) -> Dictionary:
	var state: Dictionary = state_value.duplicate(true) if state_value is Dictionary else new_state()
	var thread: Dictionary = state.get("thread", {}).duplicate(true)
	if enemy_id == "" or not bool(thread.get("active", false)) or int(thread.get("remaining_targets", 0)) <= 0:
		return {"state": state, "applied": false, "effect": {}}
	thread["remaining_targets"] = int(thread.get("remaining_targets", 0)) - 1
	if int(thread.get("remaining_targets", 0)) <= 0:
		thread["active"] = false
	state["thread"] = thread
	return {"state": state, "applied": true, "effect": {"enemy_id": enemy_id, "move_multiplier": float(thread.get("slow_multiplier", 0.65)), "duration": float(thread.get("slow_seconds", 4.0))}}


static func apply_fire_hit(state_value, hits: int = 1) -> Dictionary:
	var state: Dictionary = state_value.duplicate(true) if state_value is Dictionary else new_state()
	var thread: Dictionary = state.get("thread", {}).duplicate(true)
	if not bool(thread.get("active", false)):
		return state
	thread["fire_durability"] = maxi(0, int(thread.get("fire_durability", 0)) - maxi(0, hits))
	if int(thread.get("fire_durability", 0)) <= 0:
		thread["active"] = false
	state["thread"] = thread
	return state


static func emergency_pull(state_value, ally: Dictionary, safe_direction: Vector2, specialization_id: String, skill: Dictionary) -> Dictionary:
	var state: Dictionary = state_value.duplicate(true) if state_value is Dictionary else new_state()
	var max_hp := maxi(1, int(ally.get("max_hp", 1)))
	var hp_ratio := float(ally.get("hp", max_hp)) / max_hp
	if hp_ratio > float(skill.get("hp_ratio_threshold", 0.35)) or not bool(ally.get("alive", true)):
		return {"ok": false, "state": state, "shield": 0, "pull_offset": Vector2.ZERO, "facility_repair": 0}
	var shield_ratio := float(skill.get("shield_max_hp_ratio", 0.10))
	var facility_repair := 0
	if specialization_id == SPEC_WARDEN:
		shield_ratio = maxf(0.0, shield_ratio - 0.03)
	elif specialization_id == SPEC_TAILOR:
		shield_ratio += 0.05
		facility_repair = 12
	var movable := not bool(ally.get("boss", false)) and not bool(ally.get("fixed", false))
	var direction := safe_direction.normalized() if safe_direction.length_squared() > 0.001 else Vector2.LEFT
	var offset := direction * float(skill.get("pull_distance", 120.0)) if movable else Vector2.ZERO
	state["rescues"] = int(state.get("rescues", 0)) + 1
	return {"ok": true, "state": state, "shield": maxi(1, int(round(max_hp * shield_ratio))), "pull_offset": offset, "facility_repair": facility_repair, "moved": movable}


static func ceiling_path_transition(base_transition_seconds: float, hidden_floor_alert: bool, passive: Dictionary) -> Dictionary:
	return {
		"transition_seconds": maxf(0.0, base_transition_seconds * float(passive.get("transition_time_multiplier", 0.60))),
		"ignore_ally_queue_collision": bool(passive.get("ignore_ally_queue_collision", true)),
		"first_move_multiplier": float(passive.get("hidden_floor_alert_move_multiplier", 1.20)) if hidden_floor_alert else 1.0
	}


static func choose_ai_action(state: Dictionary, allies: Array, available_anchors: Array, in_outpost: bool) -> Dictionary:
	for ally_value in allies:
		if ally_value is Dictionary:
			var ally: Dictionary = ally_value
			if bool(ally.get("alive", true)) and float(ally.get("hp", 1)) / maxi(1.0, float(ally.get("max_hp", 1))) <= 0.35:
				return {"action": "emergency_thread_pull", "target_id": str(ally.get("id", "")), "anchor": ""}
	if state.get("thread", {}).is_empty() or not bool(state.get("thread", {}).get("active", false)):
		var preferred := "outpost_retreat" if in_outpost else ("stair" if "stair" in available_anchors else "threshold")
		if preferred in available_anchors:
			return {"action": "stitch_stairway", "target_id": "", "anchor": preferred}
	return {"action": "basic_attack", "target_id": "", "anchor": ""}
