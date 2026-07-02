extends RefCounted
class_name SocketValidator

const DungeonModuleRegistryScript = preload("res://scripts/dungeon_quarter/DungeonModuleRegistry.gd")

const OPPOSITE_SIDE = {
	"NE": "SW",
	"SW": "NE",
	"NW": "SE",
	"SE": "NW",
	"N": "S",
	"S": "N",
	"E": "W",
	"W": "E"
}

func validate_layout(module_data: Dictionary, layout_data: Dictionary) -> Dictionary:
	var errors: Array = []
	var registry = DungeonModuleRegistryScript.new()
	registry.setup(module_data)
	errors.append_array(registry.required_field_errors())

	var placed_by_id: Dictionary = {}
	for placed in layout_data.get("placed_modules", []):
		var instance_id = str(placed.get("instance_id", ""))
		var module_id = str(placed.get("module_id", ""))
		if instance_id == "":
			errors.append("placed module has empty instance_id")
			continue
		if placed_by_id.has(instance_id):
			errors.append("duplicate placed module instance %s" % instance_id)
		placed_by_id[instance_id] = placed
		if not registry.has_module(module_id):
			errors.append("placed module %s references missing module %s" % [instance_id, module_id])

	var adjacency: Dictionary = {}
	for instance_id in placed_by_id.keys():
		adjacency[instance_id] = []

	for connection in layout_data.get("connections", []):
		var from_ref = _split_ref(str(connection.get("from", "")))
		var to_ref = _split_ref(str(connection.get("to", "")))
		if from_ref.is_empty() or to_ref.is_empty():
			errors.append("invalid socket connection reference %s -> %s" % [connection.get("from", ""), connection.get("to", "")])
			continue
		if not placed_by_id.has(from_ref["instance_id"]) or not placed_by_id.has(to_ref["instance_id"]):
			errors.append("connection references missing instance %s -> %s" % [from_ref["instance_id"], to_ref["instance_id"]])
			continue

		var from_module_id = str(placed_by_id[from_ref["instance_id"]].get("module_id", ""))
		var to_module_id = str(placed_by_id[to_ref["instance_id"]].get("module_id", ""))
		var from_socket = registry.socket_data(from_module_id, from_ref["socket_id"])
		var to_socket = registry.socket_data(to_module_id, to_ref["socket_id"])
		if from_socket.is_empty() or to_socket.is_empty():
			errors.append("connection references missing socket %s -> %s" % [connection.get("from", ""), connection.get("to", "")])
			continue
		_validate_socket_pair(from_module_id, from_socket, to_module_id, to_socket, errors)
		adjacency[from_ref["instance_id"]].append(to_ref["instance_id"])
		adjacency[to_ref["instance_id"]].append(from_ref["instance_id"])

	for requirement in layout_data.get("required_paths", []):
		var from_id = str(requirement.get("from", ""))
		var to_id = str(requirement.get("to", ""))
		if not _has_path(adjacency, from_id, to_id):
			errors.append("required path missing %s -> %s" % [from_id, to_id])

	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"placed_count": placed_by_id.size(),
		"connection_count": layout_data.get("connections", []).size()
	}

func _validate_socket_pair(from_module_id: String, from_socket: Dictionary, to_module_id: String, to_socket: Dictionary, errors: Array) -> void:
	var from_side = str(from_socket.get("side", ""))
	var to_side = str(to_socket.get("side", ""))
	if OPPOSITE_SIDE.get(from_side, "") != to_side:
		errors.append("socket side mismatch %s:%s -> %s:%s" % [from_module_id, from_socket.get("id", ""), to_module_id, to_socket.get("id", "")])
	if int(from_socket.get("width", 1)) != int(to_socket.get("width", 1)):
		errors.append("socket width mismatch %s:%s -> %s:%s" % [from_module_id, from_socket.get("id", ""), to_module_id, to_socket.get("id", "")])
	if not _connects_to_module(from_socket, to_module_id) or not _connects_to_module(to_socket, from_module_id):
		errors.append("socket type/tag mismatch %s:%s -> %s:%s" % [from_module_id, from_socket.get("id", ""), to_module_id, to_socket.get("id", "")])

func _connects_to_module(socket: Dictionary, other_module_id: String) -> bool:
	var connects_to: Array = socket.get("connects_to", [])
	if connects_to.is_empty():
		return true
	for accepted in connects_to:
		if other_module_id.find(str(accepted)) >= 0:
			return true
	return false

func _split_ref(reference: String) -> Dictionary:
	var parts = reference.split(":")
	if parts.size() != 2 or str(parts[0]) == "" or str(parts[1]) == "":
		return {}
	return {"instance_id": str(parts[0]), "socket_id": str(parts[1])}

func _has_path(adjacency: Dictionary, start_id: String, goal_id: String) -> bool:
	if start_id == goal_id and adjacency.has(start_id):
		return true
	if not adjacency.has(start_id) or not adjacency.has(goal_id):
		return false
	var frontier: Array = [start_id]
	var visited: Dictionary = {start_id: true}
	while not frontier.is_empty():
		var current = frontier.pop_front()
		for next_id in adjacency.get(current, []):
			if visited.has(next_id):
				continue
			if next_id == goal_id:
				return true
			visited[next_id] = true
			frontier.append(next_id)
	return false
