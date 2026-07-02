extends RefCounted
class_name PlacedModule

const IsoMathScript = preload("res://scripts/dungeon_quarter/IsoMath.gd")

var instance_id: String = ""
var module_id: String = ""
var grid_origin: Vector2i = Vector2i.ZERO
var locked: bool = false
var legacy_room_id: String = ""
var replaceable_with: Array = []

static func from_dict(source: Dictionary) -> PlacedModule:
	var placed = PlacedModule.new()
	placed.instance_id = str(source.get("instance_id", ""))
	placed.module_id = str(source.get("module_id", ""))
	placed.grid_origin = IsoMathScript.array_to_cell(source.get("grid_origin", []))
	placed.locked = bool(source.get("locked", false))
	placed.legacy_room_id = str(source.get("legacy_room_id", placed.instance_id))
	placed.replaceable_with = source.get("replaceable_with", []).duplicate(true)
	return placed

func local_to_global_cell(local_cell: Vector2i) -> Vector2i:
	return grid_origin + local_cell

func cell_array_to_global(local_cell_value: Array) -> Vector2i:
	return local_to_global_cell(IsoMathScript.array_to_cell(local_cell_value))

func is_replaceable_with(next_module_id: String) -> bool:
	return not locked and replaceable_with.has(next_module_id)
