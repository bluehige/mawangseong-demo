extends "res://scripts/map_builder/ApprovedBattleMap.gd"
## Memoize immutable geometry only. Mutable traps/rooms and A* stay in super.
var road_lookup := {}
var center_lookup := {}
var room_lookup := {}
var tag_lookup := {}
var nearest_lookup := {}

func setup(source: Dictionary) -> void:
	road_lookup.clear(); center_lookup.clear(); room_lookup.clear(); tag_lookup.clear(); nearest_lookup.clear()
	for c in source.road_cells: road_lookup[c]=true
	super.setup(source)

func is_road(c: Vector2i) -> bool: return road_lookup.has(c)

func nearest_cell(point: Vector2) -> Vector2i:
	var c := cell(point)
	if is_road(c): return c
	if not nearest_lookup.has(point): nearest_lookup[point]=super.nearest_cell(point)
	return nearest_lookup[point]

func world(c: Vector2i) -> Vector2:
	if not center_lookup.has(c): center_lookup[c]=super.world(c)
	return center_lookup[c]

func room_at_world(point: Vector2) -> String:
	var c := cell(point)
	if not room_lookup.has(c): room_lookup[c]=super.room_at_world(point)
	return room_lookup[c]

func tags_at(c: Vector2i) -> Dictionary:
	if not tag_lookup.has(c): tag_lookup[c]={}
	var variants: Dictionary=tag_lookup[c]
	var trap: String=str(trap_cells.get(c,""))
	if not variants.has(trap):
		var tags: Dictionary=super.tags_at(c)
		tags.aura.make_read_only()
		tags.make_read_only()
		variants[trap]=tags
	return variants[trap]
