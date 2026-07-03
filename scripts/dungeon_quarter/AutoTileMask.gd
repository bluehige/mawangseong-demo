extends RefCounted
class_name AutoTileMask

const DIRS = {
	"N": Vector2i(0, -1),
	"E": Vector2i(1, 0),
	"S": Vector2i(0, 1),
	"W": Vector2i(-1, 0)
}

const BITS = {
	"N": 1,
	"E": 2,
	"S": 4,
	"W": 8
}

const OPPOSITE = {
	"N": "S",
	"E": "W",
	"S": "N",
	"W": "E"
}

static func get_4bit_mask(cell: Vector2i, floor_cells: Dictionary, open_edges: Dictionary = {}) -> int:
	var mask := 0
	for side in ["N", "E", "S", "W"]:
		var neighbor: Vector2i = cell + DIRS[side]
		var connected := false
		if not open_edges.is_empty():
			connected = open_edges.has(edge_key(cell, side))
		else:
			connected = floor_cells.has(neighbor)
		if connected:
			mask |= int(BITS[side])
	return mask

static func mask_to_sides(mask: int) -> Array:
	var sides: Array = []
	for side in ["N", "E", "S", "W"]:
		if (mask & int(BITS[side])) != 0:
			sides.append(side)
	return sides

static func edge_key(cell: Vector2i, side: String) -> String:
	return "%d,%d:%s" % [cell.x, cell.y, side]

static func opposite_side(side: String) -> String:
	return str(OPPOSITE.get(side, ""))

static func side_between(from_cell: Vector2i, to_cell: Vector2i) -> String:
	var delta := to_cell - from_cell
	for side in DIRS.keys():
		if DIRS[side] == delta:
			return side
	return ""
