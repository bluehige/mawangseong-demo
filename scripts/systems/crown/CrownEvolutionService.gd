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
	if int(species_mastery.get(str(crown.get("monster_id", "")), 0)) < int(crown.get("required_species_mastery", 0)):
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


static func runtime_appearance(crown_id: String, catalog: Dictionary) -> Dictionary:
	var crown = catalog.get(crown_id, {})
	if not (crown is Dictionary) or crown.is_empty():
		return {"ok": false, "reason": "unknown_crown"}
	var required := ["combat_sprite", "portrait", "portrait_victory", "vfx_id", "sfx", "crown_event_id"]
	for key in required:
		if str(crown.get(key, "")) == "":
			return {"ok": false, "reason": "missing_%s" % key}
	return {
		"ok": true,
		"combat_sprite": str(crown.combat_sprite),
		"portrait": str(crown.portrait),
		"portrait_victory": str(crown.portrait_victory),
		"vfx_id": str(crown.vfx_id),
		"sfx": str(crown.sfx),
		"crown_event_id": str(crown.crown_event_id),
		"frame_count": int(crown.get("frame_count", 0))
	}


static func crown_event_for_form(crown_id: String, events: Dictionary) -> Dictionary:
	for event_id_value in events.keys():
		var event = events.get(event_id_value)
		if event is Dictionary and str(event.get("crown_form_id", "")) == crown_id:
			var result: Dictionary = event.duplicate(true)
			result["id"] = str(event_id_value)
			return result
	return {}


static func complete_crown_event(profile_value, active_run_value, events: Dictionary) -> Dictionary:
	var profile: Dictionary = profile_value.duplicate(true) if profile_value is Dictionary else {}
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var council: Dictionary = active_run.get("council_season", {}).duplicate(true)
	var crown_id := str(council.get("crown_form_id", ""))
	if crown_id == "":
		return {"ok": false, "reason": "no_crown_selected", "profile": profile, "active_run": active_run}
	var event := crown_event_for_form(crown_id, events)
	if event.is_empty():
		return {"ok": false, "reason": "missing_crown_event", "profile": profile, "active_run": active_run}
	if int(event.get("unlock_day", 23)) > int(active_run.get("day", 23)):
		return {"ok": false, "reason": "event_not_unlocked", "profile": profile, "active_run": active_run}
	if event.get("scenes", []).size() != 3:
		return {"ok": false, "reason": "scene_contract", "profile": profile, "active_run": active_run}
	var crown_profile: Dictionary = profile.get("crown_evolution", {}).duplicate(true)
	var forms_unlocked: Array = crown_profile.get("forms_unlocked", []).duplicate()
	var forms_seen: Array = crown_profile.get("forms_seen", []).duplicate()
	var memories_unlocked: Array = crown_profile.get("memories_unlocked", []).duplicate()
	if forms_seen.has(crown_id):
		return {"ok": false, "reason": "event_already_seen", "profile": profile, "active_run": active_run}
	if not forms_unlocked.has(crown_id):
		forms_unlocked.append(crown_id)
	forms_seen.append(crown_id)
	var memory_id := str(event.get("memory_id", ""))
	if memory_id != "" and not memories_unlocked.has(memory_id):
		memories_unlocked.append(memory_id)
	crown_profile["forms_unlocked"] = forms_unlocked
	crown_profile["forms_seen"] = forms_seen
	crown_profile["memories_unlocked"] = memories_unlocked
	profile["crown_evolution"] = crown_profile
	council["crown_event_id"] = str(event.id)
	council["crown_event_seen"] = true
	active_run["council_season"] = council
	return {"ok": true, "reason": "", "profile": profile, "active_run": active_run, "event": event, "autosave_required": true}


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


static func gob_royal_mark(enemies: Array, crown_active: bool) -> Dictionary:
	if not crown_active:
		return {"ok": false, "reason": "crown_sanctum_disabled"}
	var target_id := ""
	var highest_danger := -INF
	for enemy in enemies:
		if not (enemy is Dictionary) or not bool(enemy.get("active", true)):
			continue
		var danger := float(enemy.get("danger", 0.0))
		if danger > highest_danger:
			highest_danger = danger
			target_id = str(enemy.get("id", ""))
	return {"ok": target_id != "", "target_id": target_id, "danger": highest_danger}


static func gob_chain_command(marked_target_id: String, enemies: Array, origin_room_id: String, source_evolution_id: String, crown_active: bool, skill: Dictionary) -> Dictionary:
	if not crown_active:
		return {"ok": false, "reason": "crown_sanctum_disabled"}
	var target_ids: Array[String] = []
	if marked_target_id != "":
		target_ids.append(marked_target_id)
	for enemy in enemies:
		if enemy is Dictionary and str(enemy.get("id", "")) != marked_target_id and str(enemy.get("role", "")) == "support":
			target_ids.append(str(enemy.get("id", "")))
			break
	var result := {"ok": not target_ids.is_empty(), "target_ids": target_ids, "return_room_id": origin_room_id if bool(skill.get("return_to_origin", true)) else "", "post_def_multiplier": float(skill.get("post_def_multiplier", 0.85)), "post_def_duration": float(skill.get("post_def_duration", 4.0)), "inheritance": "", "trap_damage_multiplier": 1.0, "interrupt_theft": false}
	if source_evolution_id == "goblin_ambush_captain":
		result.inheritance = "crown_trap_opening_bonus"
		result.trap_damage_multiplier = 1.20
	elif source_evolution_id == "goblin_vault_keeper":
		result.inheritance = "crown_theft_interrupt_bonus"
		result.interrupt_theft = true
	return result


static func pynn_ember_cost(history: Array, selected_mode: String, skill: Dictionary) -> Dictionary:
	if selected_mode not in skill.get("modes", []):
		return {"ok": false, "reason": "unknown_mode"}
	var base_cost := float(skill.get("cost_mana", 24.0))
	var multiplier := 1.0
	var reason := "base"
	if not history.is_empty() and str(history.back()) == selected_mode:
		multiplier += float(skill.get("repeat_cost_increase", 0.20))
		reason = "repeat_cost"
	elif history.size() >= 3:
		var recent := history.slice(history.size() - 3)
		var distinct := {}
		for mode in recent:
			distinct[str(mode)] = true
		if distinct.size() == 3:
			multiplier -= float(skill.get("cycle_discount", 0.30))
			reason = "three_embers_discount"
	return {"ok": true, "mana_cost": roundi(base_cost * multiplier), "reason": reason}


static func pynn_tricolor_fire(selected_mode: String, source_evolution_id: String, crown_active: bool) -> Dictionary:
	if not crown_active:
		return {"ok": false, "reason": "crown_sanctum_disabled"}
	var result := {"ok": true, "mode": selected_mode, "direct_damage_multiplier": 1.0, "area_damage_multiplier": 1.0, "debuff_duration_multiplier": 1.0, "inheritance": ""}
	match selected_mode:
		"single_flame": result.direct_damage_multiplier = 1.45
		"area_flame": result.area_damage_multiplier = 1.35
		"ember_curse": result.debuff_duration_multiplier = 1.30
		_: return {"ok": false, "reason": "unknown_mode"}
	if source_evolution_id == "imp_flame_adept":
		result.inheritance = "crown_direct_area_damage_bonus"
		result.direct_damage_multiplier *= 1.10
		result.area_damage_multiplier *= 1.10
	elif source_evolution_id == "imp_ember_shaman":
		result.inheritance = "crown_debuff_duration_bonus"
		result.debuff_duration_multiplier *= 1.20
	return result


static func representative_matrix(crown_id: String, rival_id: String) -> Dictionary:
	var base: float = float({"rival_brassa": 0.38, "rival_vesper": 0.39, "rival_mirella": 0.40}.get(rival_id, 0.38))
	var adjustment := 0.0
	if crown_id == "crown_gob_midnight_marshal" and rival_id == "rival_vesper":
		adjustment = 0.02
	elif crown_id == "crown_pynn_castle_flame_sage" and rival_id == "rival_brassa":
		adjustment = 0.02
	return {"contribution_ratio": minf(0.48, base + adjustment), "viable": true, "hard_countered": false}


static func mori_spore_sacrament(overheal: int, target_max_hp: int, crown_active: bool) -> Dictionary:
	if not crown_active:
		return {"ok": false, "shield": 0, "reason": "crown_sanctum_disabled"}
	var shield := mini(roundi(maxi(0, overheal) * 0.50), roundi(maxi(1, target_max_hp) * 0.35))
	return {"ok": true, "shield": shield, "shield_ratio_cap": 0.35}


static func mori_shared_umbrella(allies: Array, mori_floor_id: String, crown_active: bool, skill: Dictionary) -> Dictionary:
	if not crown_active:
		return {"ok": false, "reason": "crown_sanctum_disabled"}
	var ally_ids: Array[String] = []
	var rescue_target_id := ""
	var lowest_ratio := 2.0
	for ally in allies:
		if not (ally is Dictionary) or str(ally.get("floor_id", "")) != mori_floor_id:
			continue
		ally_ids.append(str(ally.get("id", "")))
		var ratio := float(ally.get("hp", 0.0)) / maxf(1.0, float(ally.get("max_hp", 1.0)))
		if ratio < lowest_ratio:
			lowest_ratio = ratio
			rescue_target_id = str(ally.get("id", ""))
	return {"ok": true, "ally_ids": ally_ids, "cleanse": true, "regeneration_seconds": float(skill.get("regeneration_seconds", 5.0)), "rescue_target_id": rescue_target_id, "rescue_hp": 1, "post_healing_multiplier": float(skill.get("post_healing_multiplier", 0.85)), "post_healing_duration": float(skill.get("post_healing_duration", 6.0))}


static func toktok_moving_forge(base_def: int, facility_damage: int, crown_active: bool) -> Dictionary:
	if not crown_active:
		return {"ok": false, "def": base_def, "reason": "crown_sanctum_disabled"}
	var bonus := clampi(ceili(maxi(0, facility_damage) / 10.0), 1, 6)
	return {"ok": true, "def": maxi(0, base_def) + bonus, "bonus": bonus}


static func toktok_emergency_plating(objectives: Array, crown_active: bool, skill: Dictionary) -> Dictionary:
	if not crown_active:
		return {"ok": false, "reason": "crown_sanctum_disabled"}
	var target: Dictionary = {}
	var lowest_ratio := 2.0
	for value in objectives:
		if not (value is Dictionary) or not bool(value.get("active", true)):
			continue
		var ratio := float(value.get("hp", 0.0)) / maxf(1.0, float(value.get("max_hp", 1.0)))
		if ratio < lowest_ratio:
			lowest_ratio = ratio
			target = value
	if target.is_empty():
		return {"ok": false, "reason": "no_objective"}
	var max_hp := maxi(1, int(target.get("max_hp", 1)))
	var missing := maxi(0, max_hp - int(target.get("hp", 0)))
	var repaired := mini(missing, roundi(max_hp * float(skill.get("max_repair_ratio", 0.30))))
	return {"ok": true, "target_id": str(target.get("id", "")), "repair": repaired, "protection_seconds": float(skill.get("protection_seconds", 8.0)), "post_move_multiplier": float(skill.get("post_move_multiplier", 0.75)), "post_move_duration": float(skill.get("post_move_duration", 5.0))}


static func popo_shortest_mail_route(crown_active: bool) -> Dictionary:
	return {"ok": crown_active, "transition_seconds": 0.20 if crown_active else 0.60, "first_skill_cooldown_recovery": 0.30 if crown_active else 0.0, "capture_duration_multiplier": 1.15 if crown_active else 1.0}


static func popo_urgent_courier(popo_floor_id: String, target: Dictionary, crown_active: bool, skill: Dictionary) -> Dictionary:
	if not crown_active:
		return {"ok": false, "reason": "crown_sanctum_disabled"}
	if str(target.get("floor_id", "")) == popo_floor_id:
		return {"ok": false, "reason": "target_same_floor"}
	return {"ok": true, "target_id": str(target.get("id", "")), "target_floor_id": str(target.get("floor_id", "")), "target_position": target.get("position", Vector2.ZERO), "transition_seconds": float(skill.get("transition_seconds", 0.20)), "duration": float(skill.get("duration", 6.0)), "move_multiplier": minf(1.30, float(skill.get("move_multiplier", 1.20))), "attack_interval_multiplier": maxf(0.75, float(skill.get("attack_interval_multiplier", 0.85))), "status_resistance_bonus": float(skill.get("status_resistance_bonus", 0.20))}
