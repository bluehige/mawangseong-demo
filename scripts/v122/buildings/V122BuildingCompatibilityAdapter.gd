class_name V122BuildingCompatibilityAdapter
extends RefCounted

const ROLE_OBJECTS := {
	"entry": "entrance_gate_f",
	"core": "throne_f",
	"barracks": "weapon_rack",
	"recovery": "recovery_nest_f",
	"treasure": "treasure_pile_large",
	"build_slot": "foundation_marks",
	"watch_post": "watch_post",
	"heart_chamber": "selected_castle_heart",
	"ward_core": "foundation_marks"
}

const DEDICATED_RENDERERS := {
	"heart_chamber": {
		"sprite_path": "assets/sprites/hearts/heart_props_sheet.png",
		"facing": "SW",
		"renderer_mode": "heart_sheet"
	},
	"ward_core": {
		"facing": "NW",
		"renderer_mode": "quarter_prop"
	}
}

const ROLE_METRICS := {
	"entry": "breach_progress",
	"core": "throne_damage",
	"barracks": "barracks_engagements",
	"recovery": "facility_healing",
	"treasure": "treasure_stolen",
	"build_slot": "build_slot_state",
	"watch_post": "rearline_reveals",
	"heart_chamber": "heart_pressure",
	"ward_core": "prevented_damage"
}

const PRODUCT_ALIASES := {
	"v20_barracks": "barracks",
	"v20_recovery_nest": "recovery",
	"v20_decoy_treasure": "treasure",
	"v20_watch_post": "watch_post",
	"v20_barricade": "entrance"
}


static func build_descriptors(
	rooms: Dictionary,
	layout: Dictionary,
	modules: Dictionary,
	asset_manifest: Dictionary,
	castle_stage: String = "stage_01_cave"
) -> Dictionary:
	var cells := _layout_cells(layout)
	var placed := _placed_modules(layout)
	var props: Dictionary = asset_manifest.get("props", {})
	var result := {}
	for room_id_value in rooms.keys():
		var room_id := str(room_id_value)
		var room: Dictionary = rooms.get(room_id, {})
		if str(room.get("type", "")) == "legacy":
			continue
		var role := _product_role(room_id, room)
		if role == "":
			continue
		var cell: Dictionary = cells.get(room_id, {})
		var module_id := str(placed.get(room_id, ""))
		var module: Dictionary = modules.get(module_id, {})
		var object_slot := _first_object_slot(module)
		var object_id := str(cell.get("object_id", object_slot.get("id", ROLE_OBJECTS.get(role, ""))))
		var renderer: Dictionary = DEDICATED_RENDERERS.get(role, {})
		if role in DEDICATED_RENDERERS:
			object_id = str(ROLE_OBJECTS.get(role, object_id))
		elif object_id == "" and role in ROLE_OBJECTS:
			object_id = str(ROLE_OBJECTS[role])
		var prop: Dictionary = props.get(object_id, {})
		var facing := str(renderer.get(
			"facing",
			cell.get("object_facing", object_slot.get("facing", prop.get("default_facing", "")))
		))
		var layer := str(cell.get("layer", "object_%s" % str(object_slot.get("layer", "front"))))
		var sprite_path := str(renderer.get(
			"sprite_path",
			_sprite_path(prop, castle_stage, facing, "back" if layer.ends_with("back") else "front")
		))
		var facility := role not in ["entry", "core", "build_slot"]
		result[room_id] = {
			"product_room_id": room_id,
			"facility_role": role,
			"unlock_condition": "castle_stage:%d" % int(room.get("castle_stage_level", 1)),
			"upgrade_state": int(room.get("facility_level", 1)),
			"room_blueprint": module_id,
			"object_id": object_id,
			"sprite_path": sprite_path,
			"renderer_mode": str(renderer.get("renderer_mode", "quarter_prop")),
			"stage_override": castle_stage,
			"facing": facing,
			"slot_anchor": cell.get("anchor_cell", object_slot.get("cell", [])),
			"management_visible": true,
			"combat_visible": object_id != "" and sprite_path != "",
			"clickable": true,
			"command_targetable": facility,
			"engineer_targetable": facility,
			"saved": true,
			"result_metric": str(ROLE_METRICS.get(role, "room_state")),
			"status": "COMPLETE" if object_id != "" and sprite_path != "" else "MISSING_OBJECT"
		}
	return result


static func validate_descriptors(descriptors: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var required_roles := [
		"entry",
		"core",
		"barracks",
		"recovery",
		"treasure",
		"build_slot",
		"watch_post",
		"heart_chamber",
		"ward_core"
	]
	var found_roles := {}
	for room_id_value in descriptors.keys():
		var room_id := str(room_id_value)
		var descriptor: Dictionary = descriptors.get(room_id, {})
		var role := str(descriptor.get("facility_role", ""))
		found_roles[role] = true
		if room_id.begins_with("v20_"):
			errors.append("%s uses a test-only product ID" % room_id)
		if str(descriptor.get("object_id", "")).begins_with("v20_"):
			errors.append("%s uses a duplicated v20 object" % room_id)
		if str(descriptor.get("object_id", "")) == "":
			errors.append("%s has no runtime object" % room_id)
		if str(descriptor.get("sprite_path", "")) == "":
			errors.append("%s has no runtime sprite" % room_id)
		if str(descriptor.get("facing", "")) not in ["NW", "NE", "SE", "SW"]:
			errors.append("%s has an invalid facing" % room_id)
		if bool(descriptor.get("command_targetable", false)) and not bool(descriptor.get("combat_visible", false)):
			errors.append("%s command target is not visible" % room_id)
		if bool(descriptor.get("engineer_targetable", false)) and not bool(descriptor.get("combat_visible", false)):
			errors.append("%s engineer target is not visible" % room_id)
	for role in required_roles:
		if not found_roles.has(role):
			errors.append("required product role is missing: %s" % role)
	return errors


static func facility_visual_state(room: Dictionary, selected: bool = false, cooldown: float = 0.0, engineer_target: bool = false) -> String:
	if int(room.get("hp", 1)) <= 0:
		return "destroyed"
	if bool(room.get("disabled", false)) or float(room.get("disabled_time", room.get("disabled_remaining", 0.0))) > 0.0:
		return "disabled"
	if engineer_target:
		return "engineer_target"
	if cooldown > 0.0:
		return "cooldown"
	if bool(room.get("active_effect", false)):
		return "active"
	if selected:
		return "selected"
	if int(room.get("hp", 1)) < int(room.get("max_hp", room.get("hp", 1))):
		return "damaged"
	return "default"


static func product_id_for_alias(value: String) -> String:
	return str(PRODUCT_ALIASES.get(value, value))


static func _product_role(room_id: String, room: Dictionary) -> String:
	var explicit := str(room.get("facility_role", ""))
	if explicit != "":
		return explicit
	match str(room.get("type", "")):
		"entry":
			return "entry"
		"core":
			return "core"
		"support":
			return "barracks" if room_id == "barracks" else ""
		"recovery":
			return "recovery"
		"bait":
			return "treasure"
		"build_slot":
			return "build_slot"
	return ""


static func _layout_cells(layout: Dictionary) -> Dictionary:
	var result := {}
	for value in layout.get("room_grid", {}).get("cells", []):
		if value is Dictionary and str(value.get("instance_id", "")) != "":
			result[str(value.get("instance_id"))] = value
	return result


static func _placed_modules(layout: Dictionary) -> Dictionary:
	var result := {}
	for value in layout.get("placed_modules", []):
		if value is Dictionary:
			result[str(value.get("instance_id", ""))] = str(value.get("module_id", ""))
	return result


static func _first_object_slot(module: Dictionary) -> Dictionary:
	var slots = module.get("object_slots", [])
	return slots[0] if slots is Array and not slots.is_empty() and slots[0] is Dictionary else {}


static func _sprite_path(prop: Dictionary, castle_stage: String, facing: String, layer: String) -> String:
	var stages: Dictionary = prop.get("stage_facing_sprites", {})
	var stage: Dictionary = stages.get(castle_stage, {})
	var stage_facing: Dictionary = stage.get(facing, {})
	if stage_facing.has(layer):
		return str(stage_facing.get(layer))
	var facings: Dictionary = prop.get("facing_sprites", {})
	var facing_data: Dictionary = facings.get(facing, {})
	if facing_data.has(layer):
		return str(facing_data.get(layer))
	var sprites: Dictionary = prop.get("sprites", {})
	if sprites.has(layer):
		return str(sprites.get(layer))
	for candidate in ["front", "back"]:
		if sprites.has(candidate):
			return str(sprites.get(candidate))
	return ""
