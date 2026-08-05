class_name V122BreachService
extends RefCounted


static func new_state(room_id: String, object_id: String, required_damage: float, next_route: Array) -> Dictionary:
	return {
		"breach_target": {"room_id": room_id, "object_id": object_id},
		"breach_animation": "attack_object",
		"breach_progress": 0.0,
		"required_damage": maxf(1.0, required_damage),
		"interrupt_condition": "attacker_displaced_or_defeated",
		"complete_event": "breach_completed",
		"next_route": next_route.duplicate(),
		"visual_feedback": "object_damage_and_progress",
		"audio_feedback": "combat_hit",
		"completed": false
	}


static func apply_damage(state: Dictionary, amount: float, interrupted: bool = false) -> Dictionary:
	var next := state.duplicate(true)
	if bool(next.get("completed", false)) or interrupted or amount <= 0.0:
		return next
	next["breach_progress"] = minf(float(next.get("required_damage", 1.0)), float(next.get("breach_progress", 0.0)) + amount)
	next["completed"] = float(next.get("breach_progress", 0.0)) >= float(next.get("required_damage", 1.0))
	return next
