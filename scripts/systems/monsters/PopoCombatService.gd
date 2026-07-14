extends RefCounted
class_name PopoCombatService

const SPEC_EXPRESS := "popo_royal_express"
const SPEC_SEAL_GUARD := "popo_seal_guard"


static func choose_relay_target(popo_state: Dictionary, allies: Array, danger_rooms: Array) -> Dictionary:
	var popo_floor := str(popo_state.get("floor_id", "1F"))
	var best: Dictionary = {}
	var best_score := -INF
	for ally_value in allies:
		if not (ally_value is Dictionary):
			continue
		var ally: Dictionary = ally_value
		if not bool(ally.get("alive", true)) or str(ally.get("id", "")) == str(popo_state.get("id", "MON_POPO")):
			continue
		var score := float(ally.get("danger", 0.0)) + (1000.0 if str(ally.get("floor_id", popo_floor)) != popo_floor else 0.0) + float(ally.get("distance", 0.0))
		if score > best_score:
			best_score = score
			best = {"kind": "ally", "target_id": str(ally.get("id", "")), "floor_id": str(ally.get("floor_id", popo_floor)), "room_id": str(ally.get("room_id", ""))}
	if not best.is_empty():
		return best
	for danger_value in danger_rooms:
		if danger_value is Dictionary and float(danger_value.get("distance", 0.0)) > best_score:
			best_score = float(danger_value.get("distance", 0.0))
			best = {"kind": "danger_room", "target_id": "", "floor_id": str(danger_value.get("floor_id", popo_floor)), "room_id": str(danger_value.get("room_id", ""))}
	return best


static func apply_night_relay(target: Dictionary, specialization_id: String, skill: Dictionary) -> Dictionary:
	var move_multiplier := float(skill.get("move_multiplier", 1.15))
	var attack_multiplier := float(skill.get("attack_interval_multiplier", 0.90))
	if specialization_id == SPEC_EXPRESS:
		move_multiplier = 1.20
		attack_multiplier = 0.86
	elif specialization_id == SPEC_SEAL_GUARD:
		move_multiplier = 1.10
	return {"target": target.duplicate(true), "duration": float(skill.get("duration", 5.0)), "popo_buff": {"move_multiplier": move_multiplier, "attack_interval_multiplier": attack_multiplier}, "target_buff": {"move_multiplier": move_multiplier, "attack_interval_multiplier": attack_multiplier}}


static func echo_alarm(enemies: Array, skill: Dictionary) -> Dictionary:
	var revealed: Array[String] = []
	var delays := {}
	var revealed_tags: Array = skill.get("revealed_role_tags", [])
	for enemy_value in enemies:
		if not (enemy_value is Dictionary):
			continue
		var enemy: Dictionary = enemy_value
		var tags: Array = enemy.get("role_tags", [])
		var matched := false
		for tag in revealed_tags:
			if tag in tags:
				matched = true
				break
		if not matched:
			continue
		var enemy_id := str(enemy.get("id", ""))
		revealed.append(enemy_id)
		delays[enemy_id] = float(skill.get("boss_interaction_delay", 0.7)) if bool(enemy.get("boss", false)) else float(skill.get("normal_interaction_delay", 2.0))
	return {"duration": float(skill.get("duration", 8.0)), "revealed_ids": revealed, "interaction_delay_by_enemy": delays}


static func new_bag_state() -> Dictionary:
	return {"holds_used": 0, "pending": {}, "recovered": 0, "finalized_losses": 0}


static func hold_first_theft(state_value, thief_id: String, specialization_id: String, skill: Dictionary) -> Dictionary:
	var state: Dictionary = state_value.duplicate(true) if state_value is Dictionary else new_bag_state()
	if int(state.get("holds_used", 0)) >= int(skill.get("max_holds_per_battle", 1)) or not state.get("pending", {}).is_empty():
		return {"held": false, "state": state}
	var hold_seconds := float(skill.get("hold_seconds", 5.0))
	if specialization_id == SPEC_EXPRESS:
		hold_seconds = maxf(1.0, hold_seconds - 1.0)
	elif specialization_id == SPEC_SEAL_GUARD:
		hold_seconds += 2.0
	state["holds_used"] = int(state.get("holds_used", 0)) + 1
	state["pending"] = {"thief_id": thief_id, "remaining": hold_seconds}
	return {"held": true, "state": state}


static func tick_bag(state_value, delta: float) -> Dictionary:
	var state: Dictionary = state_value.duplicate(true) if state_value is Dictionary else new_bag_state()
	var pending: Dictionary = state.get("pending", {}).duplicate(true)
	if pending.is_empty() or delta <= 0.0:
		return {"state": state, "loss_finalized": false}
	pending["remaining"] = maxf(0.0, float(pending.get("remaining", 0.0)) - delta)
	if float(pending.get("remaining", 0.0)) <= 0.0:
		state["pending"] = {}
		state["finalized_losses"] = int(state.get("finalized_losses", 0)) + 1
		return {"state": state, "loss_finalized": true}
	state["pending"] = pending
	return {"state": state, "loss_finalized": false}


static func arrive_at_thief(state_value, thief_id: String) -> Dictionary:
	var state: Dictionary = state_value.duplicate(true) if state_value is Dictionary else new_bag_state()
	var pending: Dictionary = state.get("pending", {})
	if pending.is_empty() or str(pending.get("thief_id", "")) != thief_id:
		return {"recovered": false, "state": state}
	state["pending"] = {}
	state["recovered"] = int(state.get("recovered", 0)) + 1
	return {"recovered": true, "state": state}


static func choose_floor_transition(current_floor: String, enemy_counts_by_floor: Dictionary, objective_attack_floor: String = "") -> String:
	if objective_attack_floor in ["1F", "2F"] and objective_attack_floor != current_floor:
		return objective_attack_floor
	var other := "2F" if current_floor == "1F" else "1F"
	return other if int(enemy_counts_by_floor.get(other, 0)) > int(enemy_counts_by_floor.get(current_floor, 0)) else current_floor
