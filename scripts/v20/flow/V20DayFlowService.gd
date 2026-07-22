class_name V20DayFlowService
extends RefCounted

const INTRUSION_BRIEF := "INTRUSION_BRIEF"
const PLACEMENT := "PLACEMENT"
const DEFENSE_START := "DEFENSE_START"
const COMBAT := "COMBAT"
const RESULT := "RESULT"
const STATES := [INTRUSION_BRIEF, PLACEMENT, DEFENSE_START, COMBAT, RESULT]
const REQUIRED_MONSTERS := ["slime", "goblin", "imp"]
const ACCEPTANCE_SCENARIOS := ["A", "B", "C", "D", "FREE"]
const BUILD_CAP := 10
const FINAL_DAY := 5
const COUNTDOWN_SECONDS := 3.0
const VALIDATION_DEMON_LORD_MAX_HP := 1500
const VALIDATION_MANA := 320
const PROTOCOL_SEEDS := {
	1: [2001, 3001, 4001],
	2: [2002, 3002, 4002],
	3: [2003, 3003, 4003],
	4: [2004, 3004, 4004],
	5: [2005, 3005, 4005]
}


static func can_transition(from_state: String, to_state: String, context: Dictionary = {}) -> Dictionary:
	if not STATES.has(from_state) or not STATES.has(to_state) or from_state == to_state:
		return _transition_result(false, "forbidden_edge")
	var allowed := false
	match "%s>%s" % [from_state, to_state]:
		"INTRUSION_BRIEF>PLACEMENT":
			allowed = str(context.get("action", "")) == "placement_start"
		"PLACEMENT>DEFENSE_START":
			allowed = bool(context.get("placement_valid", false))
		"DEFENSE_START>COMBAT":
			allowed = bool(context.get("snapshot_saved", false)) and bool(context.get("spatial_resolved", false)) and bool(context.get("countdown_complete", false))
		"DEFENSE_START>PLACEMENT":
			allowed = bool(context.get("cancel_or_error", false))
		"COMBAT>RESULT":
			allowed = bool(context.get("battle_finished", false))
		"RESULT>INTRUSION_BRIEF":
			allowed = bool(context.get("win", false)) and int(context.get("day", FINAL_DAY)) < FINAL_DAY
		"RESULT>PLACEMENT":
			allowed = not bool(context.get("win", true)) and str(context.get("retry_mode", "")) == "edit"
		"RESULT>DEFENSE_START":
			allowed = not bool(context.get("win", true)) and str(context.get("retry_mode", "")) == "same"
	return _transition_result(allowed, "" if allowed else "forbidden_edge")


static func transition(state: Dictionary, to_state: String, context: Dictionary = {}) -> Dictionary:
	var from_state := str(state.get("flow_state", ""))
	var checked := can_transition(from_state, to_state, context)
	if not bool(checked.get("ok", false)):
		return {"ok": false, "error": str(checked.get("error", "forbidden_edge")), "state": state.duplicate(true)}
	var next := state.duplicate(true)
	next["flow_state"] = to_state
	next["status"] = _legacy_status(to_state)
	return {"ok": true, "error": "", "state": next}


static func validate_defense_placement(placement_state: Dictionary, facility_catalog: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var rooms = placement_state.get("rooms")
	var roster = placement_state.get("roster")
	if not (rooms is Dictionary) or not (roster is Dictionary):
		return {"ok": false, "errors": ["rooms_and_roster_required"], "installed_cost": 0, "available_build_points": BUILD_CAP}
	var installed_cost := 0
	for room_id_value in rooms.keys():
		var room_id := str(room_id_value)
		var room: Dictionary = rooms.get(room_id_value, {})
		var monster_ids = room.get("monster_ids", [])
		if not (monster_ids is Array):
			errors.append("%s.monster_ids_not_array" % room_id)
			continue
		if monster_ids.size() > 2:
			errors.append("%s.monster_capacity_exceeded" % room_id)
		var facility_id := str(room.get("facility_id", ""))
		if facility_id == "":
			continue
		if not facility_catalog.has(facility_id):
			errors.append("%s.unknown_facility" % room_id)
			continue
		installed_cost += int(facility_catalog.get(facility_id, {}).get("cost", {}).get("build", 0))
	if installed_cost > BUILD_CAP:
		errors.append("facility_cost_exceeds_%d" % BUILD_CAP)
	var occupied_slots: Dictionary = {}
	var placed_monsters: Dictionary = {}
	for room_id_value in rooms.keys():
		var room_id := str(room_id_value)
		var room: Dictionary = rooms.get(room_id_value, {})
		var declared_slots: Array = room.get("monster_slot_ids", [])
		for monster_id_value in room.get("monster_ids", []):
			var monster_id := str(monster_id_value)
			if placed_monsters.has(monster_id):
				errors.append("%s.placed_more_than_once" % monster_id)
			placed_monsters[monster_id] = room_id
			var roster_row: Dictionary = roster.get(monster_id, {})
			var slot_id := str(roster_row.get("monster_slot_id", ""))
			if str(roster_row.get("room_id", "")) != room_id:
				errors.append("%s.room_mismatch" % monster_id)
			if slot_id == "" or not declared_slots.has(slot_id):
				errors.append("%s.invalid_monster_slot" % monster_id)
			elif occupied_slots.has(slot_id):
				errors.append("%s.duplicate_monster_slot" % slot_id)
			else:
				occupied_slots[slot_id] = monster_id
	for monster_id in REQUIRED_MONSTERS:
		if not placed_monsters.has(monster_id):
			errors.append("%s.required_placement_missing" % monster_id)
		continue
		var row: Dictionary = roster.get(monster_id, {})
		if str(row.get("monster_slot_id", "")) == "":
			errors.append("%s.required_slot_missing" % monster_id)
	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"installed_cost": installed_cost,
		"available_build_points": maxi(0, BUILD_CAP - installed_cost)
	}


static func recalculate_placement_budget(placement_state: Dictionary, facility_catalog: Dictionary) -> Dictionary:
	var next := placement_state.duplicate(true)
	var validation := validate_defense_placement(next, facility_catalog)
	next["build_points"] = int(validation.get("available_build_points", BUILD_CAP))
	return next


static func new_day_runtime(placement_state: Dictionary, monster_catalog: Dictionary, command_catalog: Dictionary, facility_catalog: Dictionary) -> Dictionary:
	var monsters: Dictionary = {}
	for monster_id in REQUIRED_MONSTERS:
		var definition: Dictionary = monster_catalog.get(monster_id, {})
		var max_hp := maxi(1, int(definition.get("max_hp", 1)))
		var max_mana := maxi(0, int(definition.get("max_mana", definition.get("mana", 0))))
		var skill_cooldowns: Dictionary = {}
		for skill_value in definition.get("skill_slots", []):
			var skill_id := str(skill_value) if skill_value != null else ""
			if skill_id != "":
				skill_cooldowns[skill_id] = 0.0
		monsters[monster_id] = {
			"level": 1,
			"exp": 0,
			"hp": max_hp,
			"max_hp": max_hp,
			"mana": max_mana,
			"max_mana": max_mana,
			"skill_cooldowns": skill_cooldowns,
			"status_seconds": 0.0
		}
	var command_cooldowns: Dictionary = {}
	for command_id_value in command_catalog.keys():
		command_cooldowns[str(command_id_value)] = 0.0
	var facilities: Dictionary = {}
	for room_id_value in placement_state.get("rooms", {}).keys():
		var room_id := str(room_id_value)
		var facility_id := str(placement_state.get("rooms", {}).get(room_id_value, {}).get("facility_id", ""))
		if facility_id == "" or not facility_catalog.has(facility_id):
			continue
		facilities[room_id] = {
			"facility_id": facility_id,
			"charges": int(facility_catalog.get(facility_id, {}).get("activation", {}).get("charges", 0)),
			"active_seconds": 0.0,
			"disabled_seconds": 0.0
		}
	return {
		"monsters": monsters,
		"command": {"points": 3, "max_points": 3, "recharge_progress": 0.0, "cooldowns": command_cooldowns},
		"facilities": facilities,
		"resources": {"demon_lord_hp": VALIDATION_DEMON_LORD_MAX_HP, "demon_lord_max_hp": VALIDATION_DEMON_LORD_MAX_HP, "mana": VALIDATION_MANA}
	}


static func make_precombat_snapshot(state: Dictionary, runtime_state: Dictionary, encounter_seed: int, rng_state: int) -> Dictionary:
	return {
		"day": int(state.get("day", 1)),
		"placement_state": state.get("placement_state", {}).duplicate(true),
		"runtime_state": runtime_state.duplicate(true),
		"encounter_seed": encounter_seed,
		"rng_state": rng_state,
		"difficulty_id": str(state.get("difficulty_id", "v20_tactician"))
	}


static func snapshot_fingerprint(snapshot: Dictionary) -> String:
	if snapshot.is_empty():
		return ""
	return JSON.stringify(_canonical_value(snapshot)).sha256_text()


static func parse_acceptance_sources(user_args: Array, web_query: String, debug_build: bool) -> Dictionary:
	var windows := _parse_windows_args(user_args)
	var web := _parse_web_query(web_query)
	var windows_enabled := bool(windows.get("enabled", false))
	var web_enabled := bool(web.get("enabled", false))
	if not windows_enabled and not web_enabled:
		return {"ok": false, "error": "acceptance_source_missing", "source": "", "seed_map": {}, "scenario_id": ""}
	if not debug_build:
		return {"ok": false, "error": "release_export_refused", "source": "", "seed_map": {}, "scenario_id": ""}
	if windows_enabled == web_enabled:
		return {"ok": false, "error": "exactly_one_acceptance_source_required", "source": "", "seed_map": {}, "scenario_id": ""}
	var selected: Dictionary = windows if windows_enabled else web
	if str(selected.get("error", "")) != "":
		return {"ok": false, "error": str(selected.get("error", "")), "source": "", "seed_map": {}, "scenario_id": ""}
	var campaign := begin_acceptance_campaign(selected.get("seed_map", {}), str(selected.get("scenario_id", "")), debug_build, false)
	if not bool(campaign.get("ok", false)):
		return {"ok": false, "error": str(campaign.get("error", "invalid_campaign")), "source": "", "seed_map": {}, "scenario_id": ""}
	return {
		"ok": true,
		"error": "",
		"source": "windows" if windows_enabled else "web",
		"seed_map": campaign.get("seed_map", {}).duplicate(true),
		"scenario_id": "FREE",
		"placement_fingerprint": ""
	}


static func begin_acceptance_case(current_session: Dictionary, day: int, seed: int, scenario_id: String, debug_build: bool, product_mode: bool) -> Dictionary:
	if not debug_build:
		return {"ok": false, "error": "release_export_refused"}
	if product_mode:
		return {"ok": false, "error": "product_mode_refused"}
	if not current_session.is_empty():
		return {"ok": false, "error": "acceptance_must_begin_before_intrusion_brief"}
	if day < 1 or day > FINAL_DAY or not PROTOCOL_SEEDS.get(day, []).has(seed):
		return {"ok": false, "error": "invalid_day_seed"}
	if not ACCEPTANCE_SCENARIOS.has(scenario_id):
		return {"ok": false, "error": "unknown_scenario"}
	return {
		"ok": true,
		"error": "",
		"day": day,
		"seed": seed,
		"scenario_id": scenario_id,
		"placement_fingerprint": ""
	}


static func begin_acceptance_campaign(seed_map_value: Dictionary, scenario_id: String, debug_build: bool, product_mode: bool) -> Dictionary:
	if not debug_build:
		return {"ok": false, "error": "release_export_refused"}
	if product_mode:
		return {"ok": false, "error": "product_mode_refused"}
	if scenario_id != "FREE":
		return {"ok": false, "error": "campaign_requires_free"}
	var seed_map: Dictionary = {}
	var used_seeds: Dictionary = {}
	for day in range(1, FINAL_DAY + 1):
		var raw_seed = seed_map_value.get(day, seed_map_value.get(str(day), null))
		if raw_seed == null:
			return {"ok": false, "error": "seed_map_day_missing"}
		var seed := int(raw_seed)
		if not PROTOCOL_SEEDS.get(day, []).has(seed):
			return {"ok": false, "error": "invalid_day_seed"}
		if used_seeds.has(seed):
			return {"ok": false, "error": "duplicate_seed"}
		used_seeds[seed] = true
		seed_map[day] = seed
	if seed_map_value.size() != FINAL_DAY:
		return {"ok": false, "error": "seed_map_must_have_five_days"}
	return {"ok": true, "error": "", "seed_map": seed_map, "scenario_id": "FREE", "placement_fingerprint": ""}


static func _parse_windows_args(user_args: Array) -> Dictionary:
	var enabled := false
	var seed_map_text := ""
	var scenario_id := ""
	for arg_value in user_args:
		var arg := str(arg_value)
		if arg == "--v20-acceptance":
			enabled = true
		elif arg.begins_with("--v20-seed-map="):
			seed_map_text = arg.trim_prefix("--v20-seed-map=")
		elif arg.begins_with("--v20-scenario="):
			scenario_id = arg.trim_prefix("--v20-scenario=")
	if not enabled:
		return {"enabled": false, "error": "", "seed_map": {}, "scenario_id": ""}
	var parsed := _parse_seed_map(seed_map_text)
	return {"enabled": true, "error": str(parsed.get("error", "")), "seed_map": parsed.get("seed_map", {}), "scenario_id": scenario_id}


static func _parse_web_query(web_query: String) -> Dictionary:
	var values: Dictionary = {}
	var query := web_query.trim_prefix("?")
	for pair in query.split("&", false):
		var equals := pair.find("=")
		if equals < 0:
			continue
		values[pair.left(equals).uri_decode()] = pair.substr(equals + 1).uri_decode()
	var enabled := str(values.get("v20_acceptance", "")) == "1"
	if not enabled:
		return {"enabled": false, "error": "", "seed_map": {}, "scenario_id": ""}
	var parsed := _parse_seed_map(str(values.get("v20_seed_map", "")))
	return {"enabled": true, "error": str(parsed.get("error", "")), "seed_map": parsed.get("seed_map", {}), "scenario_id": str(values.get("v20_scenario", ""))}


static func _parse_seed_map(value: String) -> Dictionary:
	var result: Dictionary = {}
	for pair in value.split(",", false):
		var parts := pair.split(":", false)
		if parts.size() != 2 or not str(parts[0]).is_valid_int() or not str(parts[1]).is_valid_int():
			return {"error": "invalid_seed_map_syntax", "seed_map": {}}
		var day := int(parts[0])
		if result.has(day):
			return {"error": "duplicate_seed_map_day", "seed_map": {}}
		result[day] = int(parts[1])
	return {"error": "", "seed_map": result}


static func _canonical_value(value):
	if value is Dictionary:
		var keys: Array = value.keys()
		keys.sort_custom(func(a, b): return str(a) < str(b))
		var result: Dictionary = {}
		for key in keys:
			result[str(key)] = _canonical_value(value.get(key))
		return result
	if value is Array:
		var result_array: Array = []
		for item in value:
			result_array.append(_canonical_value(item))
		return result_array
	return value


static func _legacy_status(flow_state: String) -> String:
	match flow_state:
		COMBAT:
			return "combat"
		RESULT:
			return "result"
		_:
			return "management"


static func _transition_result(ok: bool, error: String) -> Dictionary:
	return {"ok": ok, "error": error}
