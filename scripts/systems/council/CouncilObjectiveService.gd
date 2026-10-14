extends RefCounted
class_name CouncilObjectiveService

const CROWN_MODULE_ID := "crown_sanctum"
const VAULT_MODULE_ID := "seal_vault"
const FACILITY_MODULE_ID := "upper_facility_slot"


static func crown_max_hp(modules: Dictionary, castle_stage_index: int) -> int:
	var base_hp := maxi(1, int(modules.get(CROWN_MODULE_ID, {}).get("base_hp", 600)))
	var stage_multiplier := 1.0 + maxf(0.0, float(castle_stage_index - 3) * 0.10)
	return maxi(1, int(round(base_hp * stage_multiplier)))


static func damage_crown_sanctum(active_run_value, damage: int) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var upper: Dictionary = active_run.get("expansion", {}).duplicate(true)
	var hp: Dictionary = upper.get("objective_hp", {}).duplicate(true)
	var current := maxi(0, int(hp.get(CROWN_MODULE_ID, 0)) - maxi(0, damage))
	hp[CROWN_MODULE_ID] = current
	upper["objective_hp"] = hp
	if current <= 0 and not bool(upper.get("crown_suppressed", false)):
		upper["disable_count_since_day16"] = int(upper.get("disable_count_since_day16", 0)) + 1
	upper["crown_suppressed"] = current <= 0
	active_run["expansion"] = upper
	return {"active_run": active_run, "destroyed": current <= 0, "crown_passive_enabled": current > 0, "crown_skill_enabled": current > 0, "castle_defeat": false}


static func repair_next_day(active_run_value, modules: Dictionary, castle_stage_index: int) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var upper: Dictionary = active_run.get("expansion", {}).duplicate(true)
	if not bool(upper.get("crown_suppressed", false)):
		return active_run
	var hp: Dictionary = upper.get("objective_hp", {}).duplicate(true)
	hp[CROWN_MODULE_ID] = crown_max_hp(modules, castle_stage_index)
	upper["objective_hp"] = hp
	upper["crown_suppressed"] = false
	upper["repair_cost_gold"] = maxi(0, int(modules.get(CROWN_MODULE_ID, {}).get("repair_cost_gold", 0)))
	active_run["expansion"] = upper
	return active_run


static func new_battle_objectives(active_run_value, modules: Dictionary) -> Dictionary:
	var active_run: Dictionary = active_run_value if active_run_value is Dictionary else {}
	var upper: Dictionary = active_run.get("expansion", {})
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
	var upper: Dictionary = active_run.get("expansion", {}).duplicate(true)
	upper["seal_theft_count"] = int(upper.get("seal_theft_count", 0)) + 1
	active_run["expansion"] = upper
	theft["loss_applied"] = true
	theft["ready_to_settle"] = false
	battle["seal_theft"] = theft
	return {"active_run": active_run, "battle_state": battle, "loss": loss, "castle_defeat": false}


static func install_facility(active_run_value, facility_role: String, modules: Dictionary) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var allowed: Array = modules.get(FACILITY_MODULE_ID, {}).get("allowed_facility_roles", [])
	if facility_role not in allowed:
		return {"ok": false, "error": "보조 시설에는 병영·감시초소·회복 시설만 설치할 수 있습니다.", "active_run": active_run}
	var upper: Dictionary = active_run.get("expansion", {}).duplicate(true)
	upper["facility_role"] = facility_role
	active_run["expansion"] = upper
	return {"ok": true, "error": "", "active_run": active_run}
