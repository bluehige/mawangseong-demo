extends "res://scripts/map_builder/ApprovedBattleMap.gd"
## Memoize immutable geometry only. Mutable traps/rooms and A* stay in super.
var road_lookup := {}
var center_lookup := {}
var room_lookup := {}

func setup(source: Dictionary) -> void:
	road_lookup.clear(); center_lookup.clear(); room_lookup.clear()
	for c in source.road_cells: road_lookup[c]=true
	super.setup(source)

func is_road(c: Vector2i) -> bool: return road_lookup.has(c)

func world(c: Vector2i) -> Vector2:
	if not center_lookup.has(c): center_lookup[c]=super.world(c)
	return center_lookup[c]

func room_at_world(point: Vector2) -> String:
	var c := cell(point)
	if not room_lookup.has(c): room_lookup[c]=super.room_at_world(point)
	return room_lookup[c]
