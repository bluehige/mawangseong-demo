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
const CANONICAL_ZONE_IDS := ["gate_outpost", "spike_corridor", "central_battle_room", "throne_anteroom", "throne"]


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
	var combat_effect := _require_dictionary(entry.get("combat_effect"), "%s.combat_effect" % path, errors)
	if combat_effect.is_empty():
		errors.append("%s.combat_effect must not be empty" % path)
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
	var edge_by_id: Dictionary = {}
	var entrance_outgoing := 0
	for index in range(edges.size()):
		var edge_path := "%s.edges[%d]" % [path, index]
		var edge := _require_dictionary(edges[index], edge_path, errors)
		var edge_id := str(edge.get("id", ""))
		_require_string(edge_id, "%s.id" % edge_path, errors)
		if edge_ids.has(edge_id):
			errors.append("%s.id must be unique" % edge_path)
		edge_ids[edge_id] = true
		edge_by_id[edge_id] = edge
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
	var route_mode := str(entry.get("route_mode", ""))
	if route_mode == "":
		if entrance_outgoing < 2:
			errors.append("%s must expose at least two routes from entrance" % path)
	elif route_mode != "fixed":
		errors.append("%s.route_mode must be fixed when declared" % path)
	var goal_nodes := _require_dictionary(entry.get("goal_nodes"), "%s.goal_nodes" % path, errors)
	if goal_nodes.size() < 2 or not goal_nodes.has("throne"):
		errors.append("%s.goal_nodes must include throne and at least one alternate goal" % path)
	for goal_name in goal_nodes.keys():
		if not node_set.has(str(goal_nodes.get(goal_name, ""))):
			errors.append("%s.goal_nodes.%s must reference a declared node" % [path, str(goal_name)])
	if route_mode == "fixed":
		_validate_fixed_path(entry, path, node_set, edge_by_id, goal_nodes, errors)
		_validate_canonical_zones(entry, path, errors)


static func _validate_fixed_path(entry: Dictionary, path: String, node_set: Dictionary, edge_by_id: Dictionary, goal_nodes: Dictionary, errors: Array[String]) -> void:
	var background_path := _require_string(entry.get("background_path"), "%s.background_path" % path, errors)
	if background_path != "" and not background_path.begins_with("res://"):
		errors.append("%s.background_path must be a res:// path" % path)
	var declaration := _require_dictionary(entry.get("fixed_route"), "%s.fixed_route" % path, errors)
	_require_string(declaration.get("id"), "%s.fixed_route.id" % path, errors)
	var start_node := _require_string(declaration.get("start_node"), "%s.fixed_route.start_node" % path, errors)
	var goal_node := _require_string(declaration.get("goal_node"), "%s.fixed_route.goal_node" % path, errors)
	var route_nodes := _require_string_array(declaration.get("nodes"), "%s.fixed_route.nodes" % path, errors, 4)
	var route_edges := _require_string_array(declaration.get("edges"), "%s.fixed_route.edges" % path, errors, 3)
	if not route_nodes.is_empty():
		if route_nodes[0] != start_node or route_nodes[-1] != goal_node:
			errors.append("%s.fixed_route nodes must start and end at the declared nodes" % path)
		for node_id in route_nodes:
			if not node_set.has(node_id):
				errors.append("%s.fixed_route.nodes must reference declared board nodes" % path)
	if start_node != "gate_outpost":
		errors.append("%s.fixed_route.start_node must be gate_outpost" % path)
	if goal_node != str(goal_nodes.get("throne", "")):
		errors.append("%s.fixed_route.goal_node must match goal_nodes.throne" % path)
	if route_edges.size() != maxi(0, route_nodes.size() - 1):
		errors.append("%s.fixed_route must declare exactly one edge between each node" % path)
	else:
		for index in range(route_edges.size()):
			var edge_id := route_edges[index]
			var edge: Dictionary = edge_by_id.get(edge_id, {})
			if edge.is_empty():
				errors.append("%s.fixed_route.edges[%d] must reference a declared edge" % [path, index])
			elif str(edge.get("from", "")) != route_nodes[index] or str(edge.get("to", "")) != route_nodes[index + 1]:
				errors.append("%s.fixed_route.edges[%d] must connect its adjacent declared nodes" % [path, index])
	var route_waypoints := _require_array(entry.get("route_waypoints"), "%s.route_waypoints" % path, errors)
	if route_waypoints.size() < 4:
		errors.append("%s.route_waypoints must trace the fixed route with at least four points" % path)
	for index in range(route_waypoints.size()):
		var waypoint := _require_array(route_waypoints[index], "%s.route_waypoints[%d]" % [path, index], errors)
		if waypoint.size() != 2 or float(waypoint[0]) < 0.0 or float(waypoint[0]) > 1.0 or float(waypoint[1]) < 0.0 or float(waypoint[1]) > 1.0:
			errors.append("%s.route_waypoints[%d] must contain two normalized coordinates" % [path, index])

	var sections := _require_array(entry.get("ordered_sections"), "%s.ordered_sections" % path, errors)
	if sections.is_empty():
		errors.append("%s.ordered_sections must contain at least one section" % path)
	var placement_ids: Dictionary = {}
	for index in range(sections.size()):
		var section_path := "%s.ordered_sections[%d]" % [path, index]
		var section := _require_dictionary(sections[index], section_path, errors)
		if int(section.get("index", 0)) != index + 1:
			errors.append("%s.index must match its route order" % section_path)
		var placement_id := _require_string(section.get("placement_id"), "%s.placement_id" % section_path, errors)
		if placement_ids.has(placement_id):
			errors.append("%s.placement_id must be unique" % section_path)
		placement_ids[placement_id] = true
		var node_id := _require_string(section.get("node_id"), "%s.node_id" % section_path, errors)
		if not route_nodes.has(node_id):
			errors.append("%s.node_id must be on the fixed route" % section_path)
		_require_string(section.get("display_name"), "%s.display_name" % section_path, errors)
		var anchor := _require_array(section.get("anchor"), "%s.anchor" % section_path, errors)
		if anchor.size() != 2 or float(anchor[0]) < 0.0 or float(anchor[0]) > 1.0 or float(anchor[1]) < 0.0 or float(anchor[1]) > 1.0:
			errors.append("%s.anchor must contain two normalized coordinates" % section_path)


static func _validate_canonical_zones(entry: Dictionary, path: String, errors: Array[String]) -> void:
	var nodes: Array = entry.get("nodes", [])
	if nodes != CANONICAL_ZONE_IDS:
		errors.append("%s.nodes must match the five canonical zones in route order" % path)
	var zones := _require_dictionary(entry.get("zones"), "%s.zones" % path, errors)
	if zones.keys().size() != CANONICAL_ZONE_IDS.size():
		errors.append("%s.zones must contain exactly five canonical zones" % path)
	var slot_ids: Dictionary = {}
	for zone_id in CANONICAL_ZONE_IDS:
		var zone_path := "%s.zones.%s" % [path, zone_id]
		var definition := _require_dictionary(zones.get(zone_id), zone_path, errors)
		if str(definition.get("zone_id", "")) != zone_id:
			errors.append("%s.zone_id must match its dictionary key" % zone_path)
		var facility: Dictionary = definition.get("facility_slot", {})
		var monsters: Array = definition.get("monster_slots", [])
		if zone_id == "throne":
			if not facility.is_empty() or not monsters.is_empty():
				errors.append("%s must not declare placement slots" % zone_path)
			continue
		if facility.is_empty() or monsters.size() != 2:
			errors.append("%s must declare one facility slot and two monster slots" % zone_path)
		for slot_value in [facility] + monsters:
			if not (slot_value is Dictionary):
				continue
			var slot_id := str(slot_value.get("slot_id", ""))
			if slot_id == "" or slot_ids.has(slot_id):
				errors.append("%s slot ids must be non-empty and unique" % zone_path)
			slot_ids[slot_id] = true


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
