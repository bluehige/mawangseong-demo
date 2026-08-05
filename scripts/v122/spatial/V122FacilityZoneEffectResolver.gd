class_name V122FacilityZoneEffectResolver
extends RefCounted

const CATALOG_PATH := "res://data/v122/facility_zone_effects.json"
const VALID_SCOPES := ["local", "adjacent", "lane", "global"]
const VALID_TARGETS := ["allies", "enemies", "facilities", "path"]


static func load_catalog(path: String = CATALOG_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func resolve_by_zone(
	topology: Dictionary,
	facility_states: Array,
	catalog: Dictionary = {}
) -> Dictionary:
	var active_catalog: Dictionary = catalog if not catalog.is_empty() else load_catalog()
	var facility_rules: Dictionary = active_catalog.get("facilities", {})
	var zone_index := _index_by_id(topology.get("defense_zones", []), "zone_id")
	var slot_index := _index_by_id(topology.get("facility_slots", []), "slot_id")
	var selected_by_zone: Dictionary = {}
	for zone_id_value in zone_index.keys():
		selected_by_zone[str(zone_id_value)] = {}

	for state_value in facility_states:
		if not state_value is Dictionary:
			continue
		var state: Dictionary = state_value
		if not _facility_is_active(state):
			continue
		var role := str(state.get("facility_role", ""))
		var facility_rule: Dictionary = facility_rules.get(role, {})
		if facility_rule.is_empty():
			continue
		var slot_id := str(state.get("slot_id", ""))
		var slot: Dictionary = slot_index.get(slot_id, {})
		var linked_zone_ids := _linked_zone_ids(slot, state, zone_index)
		if linked_zone_ids.is_empty():
			continue
		var lane_id := str(slot.get("lane_id", state.get("lane_id", "")))
		var power_multiplier := maxf(
			0.0,
			float(state.get("power_multiplier", state.get("facility_power_multiplier", 1.0)))
		)
		if is_zero_approx(power_multiplier):
			continue

		for effect_value in facility_rule.get("effects", []):
			if not effect_value is Dictionary:
				continue
			var effect: Dictionary = effect_value
			var scope := str(effect.get("scope", ""))
			var target := str(effect.get("target", ""))
			var category := str(effect.get("category", ""))
			if not VALID_SCOPES.has(scope) or not VALID_TARGETS.has(target) or category == "":
				continue
			var affected_zone_ids := _zones_for_scope(
				scope,
				linked_zone_ids,
				lane_id,
				zone_index
			)
			for zone_id_value in affected_zone_ids:
				var zone_id := str(zone_id_value)
				var candidate := _resolved_effect(
					effect,
					role,
					slot_id,
					lane_id,
					linked_zone_ids,
					zone_id,
					power_multiplier
				)
				var stack_group := str(effect.get("stack_group", category))
				var stack_key := "%s|%s" % [target, stack_group]
				var zone_effects: Dictionary = selected_by_zone.get(zone_id, {})
				var current: Dictionary = zone_effects.get(stack_key, {})
				if current.is_empty() or _prefer_candidate(candidate, current):
					zone_effects[stack_key] = candidate
					selected_by_zone[zone_id] = zone_effects

	var resolved_by_zone: Dictionary = {}
	var zone_ids: Array = selected_by_zone.keys()
	zone_ids.sort()
	for zone_id_value in zone_ids:
		var zone_id := str(zone_id_value)
		var selected: Dictionary = selected_by_zone.get(zone_id, {})
		var stack_keys: Array = selected.keys()
		stack_keys.sort()
		var effects: Array = []
		for stack_key_value in stack_keys:
			effects.append(selected.get(stack_key_value, {}).duplicate(true))
		resolved_by_zone[zone_id] = effects
	return resolved_by_zone


static func _index_by_id(values: Array, id_field: String) -> Dictionary:
	var result: Dictionary = {}
	for value in values:
		if not value is Dictionary:
			continue
		var record: Dictionary = value
		var record_id := str(record.get(id_field, ""))
		if record_id != "":
			result[record_id] = record
	return result


static func _facility_is_active(state: Dictionary) -> bool:
	if not bool(state.get("enabled", true)):
		return false
	if bool(state.get("disabled", false)):
		return false
	if float(state.get("disabled_remaining", 0.0)) > 0.0:
		return false
	return not str(state.get("state", "active")) in ["disabled", "destroyed", "empty"]


static func _linked_zone_ids(
	slot: Dictionary,
	state: Dictionary,
	zone_index: Dictionary
) -> Array:
	var raw_zone_ids = slot.get("linked_zone_ids", state.get("linked_zone_ids", []))
	var result: Array = []
	if not raw_zone_ids is Array:
		return result
	for zone_id_value in raw_zone_ids:
		var zone_id := str(zone_id_value)
		if zone_index.has(zone_id) and not result.has(zone_id):
			result.append(zone_id)
	result.sort()
	return result


static func _zones_for_scope(
	scope: String,
	linked_zone_ids: Array,
	lane_id: String,
	zone_index: Dictionary
) -> Array:
	var result: Array = []
	match scope:
		"local":
			result.append_array(linked_zone_ids)
		"adjacent":
			result.append_array(linked_zone_ids)
			for zone_id_value in linked_zone_ids:
				var zone: Dictionary = zone_index.get(str(zone_id_value), {})
				for adjacent_id_value in zone.get("adjacent_zone_ids", []):
					var adjacent_id := str(adjacent_id_value)
					if zone_index.has(adjacent_id):
						result.append(adjacent_id)
		"lane":
			for zone_id_value in zone_index.keys():
				var zone_id := str(zone_id_value)
				if str(zone_index[zone_id].get("lane_id", "")) == lane_id:
					result.append(zone_id)
		"global":
			result.append_array(zone_index.keys())
	var unique: Array = []
	for zone_id_value in result:
		var zone_id := str(zone_id_value)
		if zone_index.has(zone_id) and not unique.has(zone_id):
			unique.append(zone_id)
	unique.sort()
	return unique


static func _resolved_effect(
	effect: Dictionary,
	role: String,
	slot_id: String,
	lane_id: String,
	linked_zone_ids: Array,
	affected_zone_id: String,
	power_multiplier: float
) -> Dictionary:
	var result := effect.duplicate(true)
	var base_value = effect.get("value")
	result["base_value"] = base_value
	result["value"] = _scaled_value(
		base_value,
		str(effect.get("operation", "set")),
		power_multiplier
	)
	result["strength"] = float(effect.get("strength", 0.0)) * power_multiplier
	result["stacking"] = "strongest"
	result["facility_role"] = role
	result["source_slot_id"] = slot_id
	result["source_lane_id"] = lane_id
	result["source_zone_ids"] = linked_zone_ids.duplicate()
	result["affected_zone_id"] = affected_zone_id
	return result


static func _scaled_value(base_value, operation: String, power_multiplier: float):
	if not (base_value is int or base_value is float):
		return base_value
	var numeric_value := float(base_value)
	match operation:
		"add":
			return numeric_value * power_multiplier
		"multiply":
			return 1.0 + (numeric_value - 1.0) * power_multiplier
		_:
			return base_value


static func _prefer_candidate(candidate: Dictionary, current: Dictionary) -> bool:
	var candidate_strength := float(candidate.get("strength", 0.0))
	var current_strength := float(current.get("strength", 0.0))
	if not is_equal_approx(candidate_strength, current_strength):
		return candidate_strength > current_strength
	return _deterministic_key(candidate).naturalnocasecmp_to(_deterministic_key(current)) < 0


static func _deterministic_key(effect: Dictionary) -> String:
	return "%s|%s|%s" % [
		str(effect.get("source_slot_id", "")),
		str(effect.get("effect_id", "")),
		str(effect.get("facility_role", ""))
	]
