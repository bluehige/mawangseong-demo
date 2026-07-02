extends RefCounted
class_name IsoMath

const DEFAULT_TILE_WIDTH = 128.0
const DEFAULT_TILE_HEIGHT = 64.0

static func array_to_cell(value: Array, fallback: Vector2i = Vector2i.ZERO) -> Vector2i:
	if value.size() < 2:
		return fallback
	return Vector2i(int(value[0]), int(value[1]))

static func array_to_world(value: Array, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	if value.size() < 2:
		return fallback
	return Vector2(float(value[0]), float(value[1]))

static func cell_to_iso_world(cell: Vector2i, origin: Vector2 = Vector2.ZERO, tile_width: float = DEFAULT_TILE_WIDTH, tile_height: float = DEFAULT_TILE_HEIGHT) -> Vector2:
	var half_width = tile_width * 0.5
	var half_height = tile_height * 0.5
	return origin + Vector2(
		float(cell.x - cell.y) * half_width,
		float(cell.x + cell.y) * half_height
	)

static func iso_world_to_cell(world_position: Vector2, origin: Vector2 = Vector2.ZERO, tile_width: float = DEFAULT_TILE_WIDTH, tile_height: float = DEFAULT_TILE_HEIGHT) -> Vector2i:
	var local_position = world_position - origin
	var half_width = tile_width * 0.5
	var half_height = tile_height * 0.5
	if half_width <= 0.0 or half_height <= 0.0:
		return Vector2i.ZERO
	var x = (local_position.x / half_width + local_position.y / half_height) * 0.5
	var y = (local_position.y / half_height - local_position.x / half_width) * 0.5
	return Vector2i(int(round(x)), int(round(y)))
