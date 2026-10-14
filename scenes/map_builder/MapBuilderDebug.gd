extends Node2D

const Plot = preload("res://scripts/map_builder/PlotMask.gd")
const Roads = preload("res://scripts/map_builder/AutoRoadBuilder.gd")
var plot := Plot.build()
var buildings: Array = [
	{"id": "entrance", "rect": Rect2i(16, 35, 5, 5)},
	{"id": "throne", "rect": Rect2i(30, 19, 5, 5)},
	{"id": "barracks", "rect": Rect2i(24, 29, 3, 5)}
]
var result: Dictionary

func _ready() -> void:
	var doors: Array = []
	for building in buildings:
		var rect: Rect2i = building["rect"]
		doors.append({"id": building["id"], "building_id": building["id"], "anchor": Vector2i(rect.end.x, rect.position.y + 1)})
	result = Roads.build(plot, buildings, doors)
	queue_redraw()

func _draw() -> void:
	for cell: Vector2i in plot["cells"]:
		var point := Vector2(960, 420) + Vector2(cell.x - cell.y, cell.x + cell.y - 60) * Vector2(20, 10)
		var color := Color("393b45")
		if result.get("road_cells", {}).has(cell):
			color = Color("e5bb6b")
		for building in buildings:
			if building["rect"].has_point(cell):
				color = Color("7864ad")
		draw_colored_polygon(PackedVector2Array([point + Vector2(0,-9), point + Vector2(18,0), point + Vector2(0,9), point + Vector2(-18,0)]), color)
