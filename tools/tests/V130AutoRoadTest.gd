extends Node

const Plot = preload("res://scripts/map_builder/PlotMask.gd")
const Roads = preload("res://scripts/map_builder/AutoRoadBuilder.gd")
var checks := 0
var failures: Array[String] = []

func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)

func _ready() -> void:
	var plot := Plot.build()
	expect(plot["size"] == Vector2i(30,20), "starting plot 30x20")
	expect(Plot.build(3)["size"] == Vector2i(48,20), "grade expands width by 6")
	var rng := RandomNumberGenerator.new()
	rng.seed = 13020261015
	for trial in range(200):
		var buildings: Array = []
		var doors: Array = []
		# Random sizes, offsets, number and order on separated screen-aligned
		# sites. This samples valid layouts without discarding routing failures.
		var sites := [Vector2i(16,35), Vector2i(30,19), Vector2i(23,28), Vector2i(35,30)]
		for index in range(rng.randi_range(3,4)):
			var origin: Vector2i = sites[index] + Vector2i(rng.randi_range(0,1), rng.randi_range(0,1))
			var size := Vector2i(3, rng.randi_range(3,5))
			var id := "room_%d" % index
			buildings.append({"id": id, "rect": Rect2i(origin,size)})
			doors.append({"id": id, "building_id": id, "anchor": origin + Vector2i(size.x,1)})
		var before := buildings.duplicate(true)
		var result := Roads.build(plot, buildings, doors)
		expect(result["ok"], "trial %d connects: %s" % [trial,result["errors"]])
		expect(before == buildings, "pure input: %d" % trial)
		if not result["ok"]:
			continue
		var cells: Dictionary = result["road_cells"]
		var reached: Dictionary = {doors[0]["anchor"]:true}
		var frontier: Array = [doors[0]["anchor"]]
		while not frontier.is_empty():
			var current: Vector2i = frontier.pop_front()
			for direction in Roads.DIRS:
				var next: Vector2i = current + direction
				if cells.has(next) and not reached.has(next):
					reached[next] = true
					frontier.append(next)
		for door in doors:
			expect(reached.has(door["anchor"]), "all doors connected %d/%s" % [trial,door["id"]])
		for path in result["paths"]:
			var previous: Vector2i = path["anchors"][0]
			for anchor: Vector2i in path["anchors"]:
				expect(absi(anchor.x-previous.x)+absi(anchor.y-previous.y) <= 1, "continuous width-2 anchors")
				previous = anchor
				for offset in Roads.footprint_offsets():
					expect(cells.has(anchor+offset) and plot["cells"].has(anchor+offset), "complete 2x2 footprint in plot")
		for cell: Vector2i in cells:
			for building in buildings:
				expect(not building["rect"].has_point(cell), "no road inside building")
	var blocked_plot := {"cells": {}, "size": Vector2i(8,8)}
	for x in range(8):
		for y in range(8):
			if x != 4:
				blocked_plot["cells"][Vector2i(x,y)] = true
	var blocked := Roads.build(blocked_plot, [], [{"id":"entry","anchor":Vector2i(0,2)},{"id":"throne","anchor":Vector2i(6,2)}])
	expect(not blocked["ok"] and not blocked["errors"].is_empty(), "barrier returns explicit error")
	blocked = Roads.build(blocked_plot, [], [{"id":"entry","anchor":Vector2i(3,2)},{"id":"throne","anchor":Vector2i(6,2)}])
	expect(not blocked["ok"], "one-cell bottleneck rejected")
	print("V130AutoRoadTest %s checks=%d trials=200 failures=%s" % ["PASS" if failures.is_empty() else "FAIL",checks,failures])
	get_tree().quit(0 if failures.is_empty() else 1)
