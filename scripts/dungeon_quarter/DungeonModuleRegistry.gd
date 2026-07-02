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
	var required_fields = ["id", "module_type", "room_function", "footprint", "walk_cells", "sockets"]
	for module_id in modules.keys():
		var module: Dictionary = modules[module_id]
		for field in required_fields:
			if not module.has(field):
				errors.append("module %s missing field %s" % [module_id, field])
		if str(module.get("id", module_id)) != str(module_id):
			errors.append("module %s id mismatch" % module_id)
	return errors
