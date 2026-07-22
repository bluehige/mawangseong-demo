class_name V20SpatialModel
extends RefCounted

const BOARD_ID := "v20_day_01_05_board"
const RUNTIME_LAYOUT_ID := "v20_day_01_05_spatial"
const DEFAULT_CATALOG_PATH := "res://data/v20/dungeon_layouts.json"
const CANONICAL_ZONE_IDS := [
	"gate_outpost",
	"spike_corridor",
	"central_battle_room",
	"throne_anteroom",
	"throne"
]


static func load_default_board() -> Dictionary:
	if not FileAccess.file_exists(DEFAULT_CATALOG_PATH):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(DEFAULT_CATALOG_PATH))
	return board_from_catalog(parsed if parsed is Dictionary else {})


static func board_from_catalog(catalog: Dictionary) -> Dictionary:
	return catalog.get(BOARD_ID, {}).duplicate(true)


static func zone(board: Dictionary, zone_id: String) -> Dictionary:
	return board.get("zones", {}).get(zone_id, {}).duplicate(true)


static func zone_ids(board: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for zone_id in CANONICAL_ZONE_IDS:
		if board.get("zones", {}).has(zone_id):
			result.append(zone_id)
	return result


static func defense_zones(board: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for zone_id in zone_ids(board):
		var definition := zone(board, zone_id)
		if str(definition.get("kind", "")) == "defense_zone":
			result.append(definition)
	result.sort_custom(func(a, b): return int(a.get("order", 0)) < int(b.get("order", 0)))
	return result


static func all_slots(board: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition in defense_zones(board):
		var facility = definition.get("facility_slot", {})
		if facility is Dictionary and not facility.is_empty():
			result.append(facility.duplicate(true))
		for slot_value in definition.get("monster_slots", []):
			if slot_value is Dictionary:
				result.append(slot_value.duplicate(true))
	return result


static func slot(board: Dictionary, slot_id: String) -> Dictionary:
	for slot_value in all_slots(board):
		if str(slot_value.get("slot_id", "")) == slot_id:
			return slot_value
	return {}


static func zone_for_slot(board: Dictionary, slot_id: String) -> String:
	return str(slot(board, slot_id).get("slot_zone", ""))


static func monster_slot_for_index(board: Dictionary, zone_id: String, index: int) -> Dictionary:
	var slots: Array = zone(board, zone_id).get("monster_slots", [])
	return slots[index].duplicate(true) if index >= 0 and index < slots.size() and slots[index] is Dictionary else {}


static func logical_to_world(board: Dictionary, logical_cell: Vector2) -> Vector2:
	var projection: Dictionary = board.get("spatial_header", {}).get("world_projection", {})
	var origin := _array_to_vector2(projection.get("origin", []))
	var basis_x := _array_to_vector2(projection.get("basis_x", []))
	var basis_y := _array_to_vector2(projection.get("basis_y", []))
	return origin + basis_x * logical_cell.x + basis_y * logical_cell.y


static func world_to_logical(board: Dictionary, world_position: Vector2) -> Vector2:
	var projection: Dictionary = board.get("spatial_header", {}).get("world_projection", {})
	var origin := _array_to_vector2(projection.get("origin", []))
	var basis_x := _array_to_vector2(projection.get("basis_x", []))
	var basis_y := _array_to_vector2(projection.get("basis_y", []))
	var determinant := basis_x.x * basis_y.y - basis_x.y * basis_y.x
	if absf(determinant) <= 0.0001:
		return Vector2.ZERO
	var local := world_position - origin
	return Vector2(
		(local.x * basis_y.y - local.y * basis_y.x) / determinant,
		(basis_x.x * local.y - basis_x.y * local.x) / determinant
	)


static func world_to_board_anchor(board: Dictionary, world_position: Vector2) -> Vector2:
	var rect_value: Array = board.get("spatial_header", {}).get("board_world_rect", [])
	if rect_value.size() < 4 or float(rect_value[2]) <= 0.0 or float(rect_value[3]) <= 0.0:
		return Vector2.ZERO
	return Vector2(
		(world_position.x - float(rect_value[0])) / float(rect_value[2]),
		(world_position.y - float(rect_value[1])) / float(rect_value[3])
	)


static func board_anchor_to_world(board: Dictionary, anchor: Vector2) -> Vector2:
	var rect_value: Array = board.get("spatial_header", {}).get("board_world_rect", [])
	if rect_value.size() < 4:
		return Vector2.ZERO
	return Vector2(
		float(rect_value[0]) + anchor.x * float(rect_value[2]),
		float(rect_value[1]) + anchor.y * float(rect_value[3])
	)


static func to_module_graph_layout(board: Dictionary) -> Dictionary:
	var layout: Dictionary = board.get("module_graph", {}).duplicate(true)
	if layout.is_empty():
		return {}
	layout["template_id"] = RUNTIME_LAYOUT_ID
	layout["coordinate_mode"] = str(board.get("coordinate_mode", "logical_grid_v2"))
	layout["tile_size"] = board.get("spatial_header", {}).get("tile_size", [128, 64]).duplicate()
	layout["canonical_zones"] = board.get("zones", {}).duplicate(true)
	layout["canonical_route"] = board.get("fixed_route", {}).duplicate(true)
	return layout


static func _array_to_vector2(value) -> Vector2:
	if not (value is Array) or value.size() < 2:
		return Vector2.ZERO
	return Vector2(float(value[0]), float(value[1]))
