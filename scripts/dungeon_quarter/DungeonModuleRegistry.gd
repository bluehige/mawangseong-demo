extends RefCounted
class_name DungeonModuleRegistry

var modules: Dictionary = {}

func setup(module_data: Dictionary) -> void:
	modules = module_data.duplicate(true)

func has_module(module_id: String) -> bool:
	return modules.has(module_id)

func module_data(module_id: String) -> Dictionary:
	return modules.get(module_id, {})

func socket_data(module_id: String, socket_id: String) -> Dictionary:
	for socket in module_data(module_id).get("sockets", []):
		if str(socket.get("id", "")) == socket_id:
			return socket
	return {}

func required_field_errors() -> Array:
	var errors: Array = []
	var required_fields = ["id", "display_name", "theme", "module_type", "room_function", "floor_cells", "walk_cells", "blocked_cells", "sockets", "object_slots"]
	for module_id in modules.keys():
		var module: Dictionary = modules[module_id]
		for field in required_fields:
			if not module.has(field):
				errors.append("module %s missing field %s" % [module_id, field])
		if not module.has("size") and not module.has("footprint"):
			errors.append("module %s missing field size or footprint" % module_id)
		if str(module.get("id", module_id)) != str(module_id):
			errors.append("module %s id mismatch" % module_id)
	return errors
