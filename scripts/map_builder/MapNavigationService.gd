extends RefCounted

static func build(graph) -> Dictionary:
	var routes := {
		"main":graph.path_points("outside_approach","throne"),
		"thief":graph.path_points("outside_approach","treasure"),
		"patrol":{}
	}
	for id in graph.module_instance_ids():
		var path: Array = graph.room_patrol_path(id)
		if not path.is_empty(): routes["patrol"][id] = path
	return routes

static func center_cell(cells: Array) -> Vector2i:
	var center := Vector2.ZERO
	for cell in cells: center += Vector2(cell)
	center /= float(cells.size())
	var best: Vector2i = cells[0]
	for cell: Vector2i in cells:
		if Vector2(cell).distance_squared_to(center) < Vector2(best).distance_squared_to(center): best = cell
	return best
