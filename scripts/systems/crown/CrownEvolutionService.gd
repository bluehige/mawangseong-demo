extends RefCounted
class_name CrownEvolutionService

const MAX_CROWN_EVOLUTIONS_PER_RUN := 1
const MAX_VISIBLE_CANDIDATES := 4
const DECLINE_OPTIONS := ["outpost_reinforcement", "heart_extra_charge", "council_support_token"]


static func candidate_check(instance: Dictionary, crown: Dictionary, council_state: Dictionary, species_mastery: Dictionary = {}) -> Dictionary:
	var reasons: Array[String] = []
	if str(instance.get("species_id", instance.get("monster_id", ""))) != str(crown.get("monster_id", "")):
		reasons.append("species")
	if int(instance.get("bond", 0)) < int(crown.get("required_bond", 80)):
		reasons.append("bond")
	if int(instance.get("level", 0)) < int(crown.get("required_level", 6)):
		reasons.append("level")
	if str(instance.get("specialization_id", "")) == "":
		reasons.append("specialization")
	if bool(crown.get("requires_stage_one_evolution", false)) and str(instance.get("evolution_id", "")) == "":
		reasons.append("stage_one_evolution")
	if int(instance.get("growth_stage", 0)) < int(crown.get("required_growth_stage", 1)):
		reasons.append("growth_stage")
	if not species_mastery.is_empty() and int(species_mastery.get(str(crown.get("monster_id", "")), 0)) < int(crown.get("required_species_mastery", 0)):
		reasons.append("species_mastery")
	var cost: Dictionary = crown.get("cost", {})
	var has_seals := int(council_state.get("council_seals", 0)) >= int(cost.get("council_seals", 2))
	var has_alternative := int(council_state.get("alternative_seal_resource", 0)) >= int(cost.get("alternative_seal_resource", 2))
	if not has_seals and not has_alternative:
		reasons.append("seal_cost")
	if not str(council_state.get("crown_form_id", "")).is_empty():
		reasons.append("already_used")
	return {"eligible": reasons.is_empty(), "reasons": reasons, "payment": "council_seals" if has_seals else "alternative_seal_resource"}


static func eligible_candidates(roster: Array, catalog: Dictionary, council_state: Dictionary, species_mastery: Dictionary = {}) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for instance in roster:
		if not (instance is Dictionary):
			continue
		for crown_id_value in catalog.keys():
			var crown_id := str(crown_id_value)
			var crown: Dictionary = catalog[crown_id]
			var check := candidate_check(instance, crown, council_state, species_mastery)
			if bool(check.eligible):
				result.append({"instance_id": str(instance.get("instance_id", "")), "crown_form_id": crown_id, "display_name": str(crown.get("display_name", crown_id)), "payment": str(check.payment)})
	result.sort_custom(func(a: Dictionary, b: Dictionary): return str(a.instance_id) < str(b.instance_id))
	return result.slice(0, mini(MAX_VISIBLE_CANDIDATES, result.size()))


static func confirm(active_run_value, instance: Dictionary, crown_id: String, catalog: Dictionary, species_mastery: Dictionary = {}) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	if not catalog.has(crown_id):
		return {"ok": false, "reason": "unknown_crown", "active_run": active_run}
	var council: Dictionary = active_run.get("council_season", {}).duplicate(true)
	var check := candidate_check(instance, catalog[crown_id], council, species_mastery)
	if not bool(check.eligible):
		return {"ok": false, "reason": ",".join(check.reasons), "active_run": active_run}
	var payment := str(check.payment)
	var amount := int(catalog[crown_id].get("cost", {}).get(payment, 2))
	council[payment] = maxi(0, int(council.get(payment, 0)) - amount)
	council["crown_form_id"] = crown_id
	council["crown_monster_instance_id"] = str(instance.get("instance_id", ""))
	council["crown_source_specialization_id"] = str(instance.get("specialization_id", ""))
	council["crown_source_evolution_id"] = str(instance.get("evolution_id", ""))
	council["crown_declined"] = false
	active_run["council_season"] = council
	return {"ok": true, "reason": "", "active_run": active_run, "autosave_required": true, "payment": payment}


static func decline(active_run_value, option_id: String) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	if option_id not in DECLINE_OPTIONS:
		return {"ok": false, "reason": "unknown_decline_option", "active_run": active_run}
	var council: Dictionary = active_run.get("council_season", {}).duplicate(true)
	if str(council.get("crown_form_id", "")) != "" or bool(council.get("crown_declined", false)):
		return {"ok": false, "reason": "crown_choice_already_resolved", "active_run": active_run}
	if int(council.get("council_seals", 0)) < 2:
		return {"ok": false, "reason": "seal_cost", "active_run": active_run}
	council["council_seals"] = int(council.get("council_seals", 0)) - 2
	council["crown_declined"] = true
	council["crown_decline_reward"] = option_id
	match option_id:
		"outpost_reinforcement": council["outpost_final_reinforcement"] = true
		"heart_extra_charge": council["heart_day30_extra_charges"] = int(council.get("heart_day30_extra_charges", 0)) + 1
		"council_support_token": council["decline_support_tokens"] = int(council.get("decline_support_tokens", 0)) + 1
	active_run["council_season"] = council
	return {"ok": true, "reason": "", "active_run": active_run, "autosave_required": true}


static func growth_layers(instance: Dictionary, crown: Dictionary) -> Array[Dictionary]:
	return [
		{"layer": "species_base", "id": str(instance.get("species_id", instance.get("monster_id", "")))},
		{"layer": "level", "value": int(instance.get("level", 1))},
		{"layer": "tactical_specialization", "id": str(instance.get("specialization_id", ""))},
		{"layer": "stage_one_evolution", "id": str(instance.get("evolution_id", ""))},
		{"layer": "memory", "value": instance.get("memory", {})},
		{"layer": "crown_evolution", "id": str(crown.get("display_name", ""))}
	]


static func pudding_room_embrace(triggered_ids: Array, ally: Dictionary, crown_active: bool) -> Dictionary:
	var result_ids := triggered_ids.duplicate()
	var ally_id := str(ally.get("id", ""))
	var hp_ratio := float(ally.get("hp", 0.0)) / maxf(1.0, float(ally.get("max_hp", 1.0)))
	if not crown_active or hp_ratio > 0.40 or result_ids.has(ally_id):
		return {"triggered": false, "triggered_ids": result_ids, "shield": 0}
	result_ids.append(ally_id)
	return {"triggered": true, "triggered_ids": result_ids, "shield": roundi(float(ally.get("max_hp", 1.0)) * 0.15)}


static func royal_jelly_bastion(room_allies: Array, source_evolution_id: String, crown_active: bool, skill: Dictionary) -> Dictionary:
	if not crown_active:
		return {"ok": false, "reason": "crown_sanctum_disabled"}
	var result := {"ok": true, "duration": float(skill.get("duration", 6.0)), "damage_reduction": minf(0.55, float(skill.get("room_damage_reduction", 0.30))), "pudding_absorb_ratio": float(skill.get("pudding_absorb_ratio", 0.35)), "ally_ids": [], "inheritance": ""}
	for ally in room_allies:
		if ally is Dictionary:
			result.ally_ids.append(str(ally.get("id", "")))
	if source_evolution_id == "slime_gate_bulwark":
		result.inheritance = "crown_anchor_bonus"
	elif source_evolution_id == "slime_rescue_alchemy_gel":
		result.inheritance = "crown_rescue_bonus"
		var lowest := ""
		var ratio := 2.0
		for ally in room_allies:
			if ally is Dictionary:
				var current := float(ally.get("hp", 0.0)) / maxf(1.0, float(ally.get("max_hp", 1.0)))
				if current < ratio:
					ratio = current
					lowest = str(ally.get("id", ""))
		result["rescue_target_id"] = lowest
	return result


static func ab_trial(has_crown: bool) -> Dictionary:
	return {"contribution_ratio": 0.39 if has_crown else 0.33, "win_rate": 0.66 if has_crown else 0.60, "day30_completable": true}
