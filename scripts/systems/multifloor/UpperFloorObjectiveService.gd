extends RefCounted
class_name UpperFloorObjectiveService

const DEFAULT_LAYOUT_ID := "upper_compact_guard"
const CROWN_MODULE_ID := "crown_sanctum"
const VAULT_MODULE_ID := "seal_vault"
const FACILITY_MODULE_ID := "upper_facility_slot"


static func initialize_if_unlocked(active_run_value, layouts: Dictionary, modules: Dictionary, castle_stage_index: int) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var upper: Dictionary = active_run.get("upper_floor", {}).duplicate(true)
	if not bool(upper.get("unlocked", false)) or str(upper.get("layout_id", "")) != "" or not layouts.has(DEFAULT_LAYOUT_ID):
		return active_run
	upper["layout_id"] = DEFAULT_LAYOUT_ID
	upper["objective_hp"] = {CROWN_MODULE_ID: crown_max_hp(modules, castle_stage_index)}
	upper["facility_role"] = ""
	upper["seal_theft_count"] = maxi(0, int(upper.get("seal_theft_count", 0)))
	upper["crown_suppressed"] = false
	upper["repair_cost_gold"] = 0
	upper["layout_locked"] = false
	upper["auto_camera_switch"] = bool(upper.get("auto_camera_switch", true))
	active_run["upper_floor"] = upper
	return active_run


static func select_layout(active_run_value, layout_id: String, layouts: Dictionary, modules: Dictionary, castle_stage_index: int) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var upper: Dictionary = active_run.get("upper_floor", {}).duplicate(true)
	if not bool(upper.get("unlocked", false)):
		return {"ok": false, "error": "상층이 아직 해금되지 않았습니다.", "active_run": active_run}
	if bool(upper.get("layout_locked", false)):
		return {"ok": false, "error": "이번 회차의 상층 레이아웃은 이미 확정되었습니다.", "active_run": active_run}
	if not layouts.has(layout_id):
		return {"ok": false, "error": "등록되지 않은 상층 레이아웃입니다.", "active_run": active_run}
	upper["layout_id"] = layout_id
	upper["layout_locked"] = true
	upper["objective_hp"] = {CROWN_MODULE_ID: crown_max_hp(modules, castle_stage_index)}
	upper["graph_runtime"] = {"visible_floor": "1F", "entities": {}, "transition_queues": {"1F>2F": [], "2F>1F": []}}
	active_run["upper_floor"] = upper
	return {"ok": true, "error": "", "active_run": active_run}


static func crown_max_hp(modules: Dictionary, castle_stage_index: int) -> int:
	var base_hp := maxi(1, int(modules.get(CROWN_MODULE_ID, {}).get("base_hp", 600)))
	var stage_multiplier := 1.0 + maxf(0.0, float(castle_stage_index - 3) * 0.10)
	return maxi(1, int(round(base_hp * stage_multiplier)))


static func damage_crown_sanctum(active_run_value, damage: int) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var upper: Dictionary = active_run.get("upper_floor", {}).duplicate(true)
	var hp: Dictionary = upper.get("objective_hp", {}).duplicate(true)
	var current := maxi(0, int(hp.get(CROWN_MODULE_ID, 0)) - maxi(0, damage))
	hp[CROWN_MODULE_ID] = current
	upper["objective_hp"] = hp
	upper["crown_suppressed"] = current <= 0
	active_run["upper_floor"] = upper
	return {"active_run": active_run, "destroyed": current <= 0, "crown_passive_enabled": current > 0, "crown_skill_enabled": current > 0, "castle_defeat": false}


static func repair_next_day(active_run_value, modules: Dictionary, castle_stage_index: int) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var upper: Dictionary = active_run.get("upper_floor", {}).duplicate(true)
	if not bool(upper.get("crown_suppressed", false)):
		return active_run
	var hp: Dictionary = upper.get("objective_hp", {}).duplicate(true)
	hp[CROWN_MODULE_ID] = crown_max_hp(modules, castle_stage_index)
	upper["objective_hp"] = hp
	upper["crown_suppressed"] = false
	upper["repair_cost_gold"] = maxi(0, int(modules.get(CROWN_MODULE_ID, {}).get("repair_cost_gold", 0)))
	active_run["upper_floor"] = upper
	return active_run


static func new_battle_objectives(active_run_value, modules: Dictionary) -> Dictionary:
	var active_run: Dictionary = active_run_value if active_run_value is Dictionary else {}
	var upper: Dictionary = active_run.get("upper_floor", {})
	return {
		"crown_hp": int(upper.get("objective_hp", {}).get(CROWN_MODULE_ID, 0)),
		"crown_suppressed": false,
		"seal_theft": {"active": false, "warning_remaining": float(modules.get(VAULT_MODULE_ID, {}).get("warning_seconds", 3.0)), "channel_remaining": float(modules.get(VAULT_MODULE_ID, {}).get("channel_seconds", 4.0)), "ready_to_settle": false, "loss_applied": false},
		"secondary_failure": false
	}


static func start_seal_theft(battle_state_value, modules: Dictionary) -> Dictionary:
	var battle: Dictionary = battle_state_value.duplicate(true) if battle_state_value is Dictionary else {}
	var theft: Dictionary = battle.get("seal_theft", {}).duplicate(true)
	if bool(theft.get("active", false)) or bool(theft.get("ready_to_settle", false)) or bool(theft.get("loss_applied", false)):
		return battle
	theft["active"] = true
	theft["warning_remaining"] = float(modules.get(VAULT_MODULE_ID, {}).get("warning_seconds", 3.0))
	theft["channel_remaining"] = float(modules.get(VAULT_MODULE_ID, {}).get("channel_seconds", 4.0))
	battle["seal_theft"] = theft
	return battle


static func tick_seal_theft(battle_state_value, delta: float) -> Dictionary:
	var battle: Dictionary = battle_state_value.duplicate(true) if battle_state_value is Dictionary else {}
	var theft: Dictionary = battle.get("seal_theft", {}).duplicate(true)
	if not bool(theft.get("active", false)) or delta <= 0.0:
		return battle
	var remaining_delta := delta
	var warning := maxf(0.0, float(theft.get("warning_remaining", 0.0)))
	if warning > 0.0:
		var used := minf(warning, remaining_delta)
		warning -= used
		remaining_delta -= used
		theft["warning_remaining"] = warning
	if remaining_delta > 0.0 and warning <= 0.0:
		var channel := maxf(0.0, float(theft.get("channel_remaining", 0.0)) - remaining_delta)
		theft["channel_remaining"] = channel
		if channel <= 0.0001:
			theft["channel_remaining"] = 0.0
			theft["active"] = false
			theft["ready_to_settle"] = true
	battle["seal_theft"] = theft
	return battle


static func interrupt_seal_theft(battle_state_value) -> Dictionary:
	var battle: Dictionary = battle_state_value.duplicate(true) if battle_state_value is Dictionary else {}
	var theft: Dictionary = battle.get("seal_theft", {}).duplicate(true)
	theft["active"] = false
	theft["ready_to_settle"] = false
	battle["seal_theft"] = theft
	return battle


static func settle_seal_theft(active_run_value, battle_state_value, modules: Dictionary) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var battle: Dictionary = battle_state_value.duplicate(true) if battle_state_value is Dictionary else {}
	var theft: Dictionary = battle.get("seal_theft", {}).duplicate(true)
	if not bool(theft.get("ready_to_settle", false)) or bool(theft.get("loss_applied", false)):
		return {"active_run": active_run, "battle_state": battle, "loss": {}, "castle_defeat": false}
	var council: Dictionary = active_run.get("council_season", {}).duplicate(true)
	var loss := {}
	var vote_loss := maxi(0, int(modules.get(VAULT_MODULE_ID, {}).get("vote_loss", 5)))
	var seal_loss := maxi(0, int(modules.get(VAULT_MODULE_ID, {}).get("seal_loss", 1)))
	if int(council.get("council_votes", 0)) >= vote_loss:
		council["council_votes"] = int(council.get("council_votes", 0)) - vote_loss
		loss = {"council_votes": vote_loss}
	else:
		var applied_seal_loss := mini(seal_loss, maxi(0, int(council.get("council_seals", 0))))
		council["council_seals"] = maxi(0, int(council.get("council_seals", 0)) - applied_seal_loss)
		loss = {"council_seals": applied_seal_loss}
	active_run["council_season"] = council
	var upper: Dictionary = active_run.get("upper_floor", {}).duplicate(true)
	upper["seal_theft_count"] = int(upper.get("seal_theft_count", 0)) + 1
	active_run["upper_floor"] = upper
	theft["loss_applied"] = true
	theft["ready_to_settle"] = false
	battle["seal_theft"] = theft
	return {"active_run": active_run, "battle_state": battle, "loss": loss, "castle_defeat": false}


static func install_facility(active_run_value, facility_role: String, modules: Dictionary) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var allowed: Array = modules.get(FACILITY_MODULE_ID, {}).get("allowed_facility_roles", [])
	if facility_role not in allowed:
		return {"ok": false, "error": "상층에는 병영·감시초소·회복 시설만 설치할 수 있습니다.", "active_run": active_run}
	var upper: Dictionary = active_run.get("upper_floor", {}).duplicate(true)
	upper["facility_role"] = facility_role
	active_run["upper_floor"] = upper
	return {"ok": true, "error": "", "active_run": active_run}


static func same_floor_targets(entity_states: Dictionary, source_floor: String) -> Array[String]:
	var result: Array[String] = []
	for entity_id_value in entity_states.keys():
		var entity_id := str(entity_id_value)
		if bool(entity_states[entity_id_value].get("alive", false)) and str(entity_states[entity_id_value].get("floor_id", "")) == source_floor:
			result.append(entity_id)
	return result


static func upper_rooms_from_layout(layout: Dictionary, modules: Dictionary) -> Dictionary:
	var rooms := {}
	for placement_value in layout.get("placed_modules", []):
		var placement: Dictionary = placement_value
		var instance_id := str(placement.get("instance_id", ""))
		var module_id := str(placement.get("module_id", ""))
		var origin: Array = placement.get("grid_origin", [0, 0])
		rooms[instance_id] = {"display_name": str(modules.get(module_id, {}).get("display_name", module_id)), "module_id": module_id, "center": [540 + int(origin[0]) * 360, 260 + int(origin[1]) * 250], "rect": [420 + int(origin[0]) * 360, 160 + int(origin[1]) * 250, 240, 200], "exits": [], "is_objective": module_id in [CROWN_MODULE_ID, VAULT_MODULE_ID]}
	for connection_value in layout.get("connections", []):
		if connection_value is Array and connection_value.size() == 2:
			var first := str(connection_value[0])
			var second := str(connection_value[1])
			if rooms.has(first) and rooms.has(second):
				rooms[first]["exits"].append(second)
				rooms[second]["exits"].append(first)
	return rooms
