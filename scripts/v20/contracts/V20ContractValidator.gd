class_name V20ContractValidator
extends RefCounted

const CATALOG_KINDS := ["encounter", "facility", "command", "path"]
const PATH_WEIGHT_TERMS := [
	"base_edge_cost",
	"door_state_cost",
	"facility_route_cost",
	"temporary_hazard_cost",
	"enemy_role_preference",
	"goal_preference"
]
const COMMAND_TARGET_TYPES := ["room", "enemy", "facility", "encounter"]


static func validate_bundle(bundle) -> Dictionary:
	var errors: Array[String] = []
	if not (bundle is Dictionary):
		return {"ok": false, "errors": ["bundle must be a Dictionary"]}
	for kind in CATALOG_KINDS:
		if not bundle.has(kind):
			errors.append("bundle.%s is required" % kind)
			continue
		var result := validate_catalog(kind, bundle.get(kind))
		for error_value in result.get("errors", []):
			errors.append(str(error_value))
	return {"ok": errors.is_empty(), "errors": errors}


static func validate_catalog(kind: String, catalog) -> Dictionary:
	var errors: Array[String] = []
	if not CATALOG_KINDS.has(kind):
		return {"ok": false, "errors": ["unsupported catalog kind: %s" % kind]}
	if not (catalog is Dictionary):
		return {"ok": false, "errors": ["%s catalog must be a Dictionary" % kind]}
	if catalog.is_empty():
		errors.append("%s catalog must not be empty" % kind)
	var ids: Array = catalog.keys()
	ids.sort()
	for id_value in ids:
		var entry_id := str(id_value)
		var path := "%s.%s" % [kind, entry_id]
		if entry_id == "" or not entry_id.begins_with("v20_"):
			errors.append("%s id must start with v20_" % path)
		var entry = catalog.get(id_value)
		if not (entry is Dictionary):
			errors.append("%s must be a Dictionary" % path)
			continue
		match kind:
			"encounter":
				_validate_encounter(entry, path, errors)
			"facility":
				_validate_facility(entry, path, errors)
			"command":
				_validate_command(entry, path, errors)
			"path":
				_validate_path(entry, path, errors)
	return {"ok": errors.is_empty(), "errors": errors}


static func _validate_encounter(entry: Dictionary, path: String, errors: Array[String]) -> void:
	var day := int(entry.get("day", 0))
	if day < 1 or day > 30:
		errors.append("%s.day must be between 1 and 30" % path)
	_require_string_array(entry.get("objectives"), "%s.objectives" % path, errors, 1)
	var preview := _require_dictionary(entry.get("preview"), "%s.preview" % path, errors)
	_require_string_array(preview.get("targets"), "%s.preview.targets" % path, errors, 1)
	_require_string_array(preview.get("route_ids"), "%s.preview.route_ids" % path, errors, 1)
	_require_string(preview.get("special_pattern"), "%s.preview.special_pattern" % path, errors)
	var phases := _require_array(entry.get("phases"), "%s.phases" % path, errors)
	if phases.is_empty():
		errors.append("%s.phases must contain at least one phase" % path)
	for index in range(phases.size()):
		var phase_path := "%s.phases[%d]" % [path, index]
		var phase := _require_dictionary(phases[index], phase_path, errors)
		_require_string(phase.get("id"), "%s.id" % phase_path, errors)
		if float(phase.get("telegraph_seconds", -1.0)) < 0.5:
			errors.append("%s.telegraph_seconds must be at least 0.5" % phase_path)
		var spawns := _require_array(phase.get("spawns"), "%s.spawns" % phase_path, errors)
		if spawns.is_empty():
			errors.append("%s.spawns must contain at least one spawn" % phase_path)
		for spawn_index in range(spawns.size()):
			var spawn_path := "%s.spawns[%d]" % [phase_path, spawn_index]
			var spawn := _require_dictionary(spawns[spawn_index], spawn_path, errors)
			_require_string(spawn.get("enemy_id"), "%s.enemy_id" % spawn_path, errors)
			_require_string(spawn.get("route_policy"), "%s.route_policy" % spawn_path, errors)
			if int(spawn.get("count", 0)) < 1:
				errors.append("%s.count must be at least 1" % spawn_path)
		_require_string_array(phase.get("response_tags"), "%s.response_tags" % phase_path, errors, 2)
		_require_string(phase.get("failure_metric"), "%s.failure_metric" % phase_path, errors)
	_require_string_array(entry.get("result_metrics"), "%s.result_metrics" % path, errors, 2)
	var limits := _require_dictionary(entry.get("limits"), "%s.limits" % path, errors)
	var hp_scale_max := float(limits.get("hp_scale_max", 0.0))
	if hp_scale_max < 1.0 or hp_scale_max > 1.35:
		errors.append("%s.limits.hp_scale_max must be between 1.0 and 1.35" % path)
	if float(limits.get("target_duration_seconds", 0.0)) <= 0.0:
		errors.append("%s.limits.target_duration_seconds must be positive" % path)


static func _validate_facility(entry: Dictionary, path: String, errors: Array[String]) -> void:
	_require_string(entry.get("role"), "%s.role" % path, errors)
	_require_string_array(entry.get("placement_tags"), "%s.placement_tags" % path, errors, 1)
	var route_effect := _require_dictionary(entry.get("route_effect"), "%s.route_effect" % path, errors)
	if route_effect.is_empty() or not (route_effect.has("cost_delta") or route_effect.has("closed_cost") or route_effect.has("goal_bias")):
		errors.append("%s.route_effect must declare cost_delta, closed_cost, or goal_bias" % path)
	if entry.has("activation"):
		var activation := _require_dictionary(entry.get("activation"), "%s.activation" % path, errors)
		_require_string(activation.get("command_id"), "%s.activation.command_id" % path, errors)
		if float(activation.get("duration", 0.0)) <= 0.0:
			errors.append("%s.activation.duration must be positive" % path)
		if int(activation.get("charges", 0)) < 1:
			errors.append("%s.activation.charges must be at least 1" % path)
	_require_string_array(entry.get("counter_tags"), "%s.counter_tags" % path, errors, 1)
	_require_string_array(entry.get("synergy_tags"), "%s.synergy_tags" % path, errors, 1)
	_require_string_array(entry.get("result_metrics"), "%s.result_metrics" % path, errors, 3)


static func _validate_command(entry: Dictionary, path: String, errors: Array[String]) -> void:
	var target_type := str(entry.get("target_type", ""))
	if not COMMAND_TARGET_TYPES.has(target_type):
		errors.append("%s.target_type must be one of %s" % [path, COMMAND_TARGET_TYPES])
	if int(entry.get("command_point_cost", 0)) < 1:
		errors.append("%s.command_point_cost must be at least 1" % path)
	if float(entry.get("cooldown_seconds", 0.0)) < 1.0:
		errors.append("%s.cooldown_seconds must prevent command spam" % path)
	if float(entry.get("duration_seconds", -1.0)) < 0.0:
		errors.append("%s.duration_seconds must not be negative" % path)
	var effect := _require_dictionary(entry.get("effect"), "%s.effect" % path, errors)
	if effect.is_empty():
		errors.append("%s.effect must not be empty" % path)
	_require_string_array(entry.get("result_metrics"), "%s.result_metrics" % path, errors, 1)


static func _validate_path(entry: Dictionary, path: String, errors: Array[String]) -> void:
	var weight_terms := _require_string_array(entry.get("weight_terms"), "%s.weight_terms" % path, errors, PATH_WEIGHT_TERMS.size())
	if weight_terms != PATH_WEIGHT_TERMS:
		errors.append("%s.weight_terms must match the approved weighted path formula" % path)
	var nodes := _require_string_array(entry.get("nodes"), "%s.nodes" % path, errors, 4)
	var node_set: Dictionary = {}
	for node_id in nodes:
		node_set[node_id] = true
	var edges := _require_array(entry.get("edges"), "%s.edges" % path, errors)
	if edges.size() < 2:
		errors.append("%s.edges must contain at least two edges" % path)
	var edge_ids: Dictionary = {}
	var entrance_outgoing := 0
	for index in range(edges.size()):
		var edge_path := "%s.edges[%d]" % [path, index]
		var edge := _require_dictionary(edges[index], edge_path, errors)
		var edge_id := str(edge.get("id", ""))
		_require_string(edge_id, "%s.id" % edge_path, errors)
		if edge_ids.has(edge_id):
			errors.append("%s.id must be unique" % edge_path)
		edge_ids[edge_id] = true
		var from_id := str(edge.get("from", ""))
		var to_id := str(edge.get("to", ""))
		if not node_set.has(from_id):
			errors.append("%s.from must reference a declared node" % edge_path)
		if not node_set.has(to_id):
			errors.append("%s.to must reference a declared node" % edge_path)
		if float(edge.get("base_cost", 0.0)) <= 0.0:
			errors.append("%s.base_cost must be positive" % edge_path)
		if from_id == "entrance":
			entrance_outgoing += 1
	if entrance_outgoing < 2:
		errors.append("%s must expose at least two routes from entrance" % path)
	var goal_nodes := _require_dictionary(entry.get("goal_nodes"), "%s.goal_nodes" % path, errors)
	if goal_nodes.size() < 2 or not goal_nodes.has("throne"):
		errors.append("%s.goal_nodes must include throne and at least one alternate goal" % path)
	for goal_name in goal_nodes.keys():
		if not node_set.has(str(goal_nodes.get(goal_name, ""))):
			errors.append("%s.goal_nodes.%s must reference a declared node" % [path, str(goal_name)])


static func _require_dictionary(value, path: String, errors: Array[String]) -> Dictionary:
	if value is Dictionary:
		return value
	errors.append("%s must be a Dictionary" % path)
	return {}


static func _require_array(value, path: String, errors: Array[String]) -> Array:
	if value is Array:
		return value
	errors.append("%s must be an Array" % path)
	return []


static func _require_string(value, path: String, errors: Array[String]) -> String:
	var result := str(value) if value != null else ""
	if result.strip_edges() == "":
		errors.append("%s must be a non-empty String" % path)
	return result


static func _require_string_array(value, path: String, errors: Array[String], minimum_size: int) -> Array[String]:
	var result: Array[String] = []
	if not (value is Array):
		errors.append("%s must be an Array" % path)
		return result
	var seen: Dictionary = {}
	for index in range(value.size()):
		var item := str(value[index])
		if item.strip_edges() == "":
			errors.append("%s[%d] must be a non-empty String" % [path, index])
		elif seen.has(item):
			errors.append("%s must not contain duplicate value %s" % [path, item])
		else:
			seen[item] = true
			result.append(item)
	if result.size() < minimum_size:
		errors.append("%s must contain at least %d unique values" % [path, minimum_size])
	return result
