class_name V122CombatRuleAdapter
extends RefCounted


static func monster_action(actor: Dictionary, context: Dictionary) -> Dictionary:
	if int(actor.get("hp", 1)) <= 0 or bool(actor.get("forced_exit", false)):
		return _action(1, "inactive")
	if not context.get("active_command", {}).is_empty():
		return _action(2, "limited_command", context.get("active_command", {}))
	if not context.get("story_forced_action", {}).is_empty():
		return _action(3, "story_forced", context.get("story_forced_action", {}))
	if bool(context.get("emergency_defense", false)):
		return _action(4, "emergency_defense", {"room_id": str(context.get("emergency_room_id", ""))})
	if not context.get("existing_special_action", {}).is_empty():
		return _action(5, "existing_special", context.get("existing_special_action", {}))
	if not context.get("placement_role_action", {}).is_empty():
		return _action(6, "placement_role", context.get("placement_role_action", {}))
	if str(context.get("engaged_target_id", "")) != "":
		return _action(7, "current_engagement", {"target_id": str(context.get("engaged_target_id", ""))})
	if str(actor.get("current_room", "")) != str(actor.get("assigned_room", "")):
		return _action(8, "return_home", {"room_id": str(actor.get("assigned_room", ""))})
	return _action(9, "stuck_recovery" if bool(context.get("stuck", false)) else "hold_home")


static func enemy_action(actor: Dictionary, context: Dictionary) -> Dictionary:
	if int(actor.get("hp", 1)) <= 0 or bool(actor.get("casting", false)) or bool(actor.get("forced_state", false)):
		return _action(1, "forced_state")
	if not context.get("existing_boss_or_special_action", {}).is_empty():
		return _action(2, "existing_boss_or_special", context.get("existing_boss_or_special_action", {}))
	if not context.get("operation_action", {}).is_empty():
		return _action(3, "operation_goal", context.get("operation_action", {}))
	if not context.get("role_action", {}).is_empty():
		return _action(4, "enemy_role", context.get("role_action", {}))
	if str(context.get("next_segment_room_id", "")) != "":
		return _action(5, "advance_segment", {"room_id": str(context.get("next_segment_room_id", ""))})
	if str(context.get("engaged_target_id", "")) != "":
		return _action(6, "current_engagement", {"target_id": str(context.get("engaged_target_id", ""))})
	if not context.get("breach_action", {}).is_empty():
		return _action(7, "breach", context.get("breach_action", {}))
	if str(context.get("final_goal_room_id", "")) != "":
		return _action(8, "final_goal", {"room_id": str(context.get("final_goal_room_id", ""))})
	return _action(9, "stuck_recovery")


static func _action(priority: int, action: String, payload: Dictionary = {}) -> Dictionary:
	return {"priority": priority, "action": action, "payload": payload.duplicate(true)}
