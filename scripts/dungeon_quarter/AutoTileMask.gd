extends RefCounted
class_name AutoTileMask

const DIRS = {
	"NW": Vector2i(-1, 0),
	"NE": Vector2i(0, -1),
	"SE": Vector2i(1, 0),
	"SW": Vector2i(0, 1)
}

const BITS = {
	"NW": 1,
	"NE": 2,
	"SE": 4,
	"SW": 8
}

static func get_4bit_mask(cell: Vector2i, floor_cells: Dictionary) -> int:
	var mask := 0
	for direction_name in DIRS.keys():
		if floor_cells.has(cell + DIRS[direction_name]):
			mask |= int(BITS[direction_name])
	return mask

static func mask_to_sides(mask: int) -> Array:
	var sides: Array = []
	for direction_name in ["NW", "NE", "SE", "SW"]:
		if (mask & int(BITS[direction_name])) != 0:
			sides.append(direction_name)
	return sides
