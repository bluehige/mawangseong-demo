extends RefCounted
class_name PlotMask

const START_SIZE := Vector2i(30, 20)
const GRADE_WIDTH := 6

# Orthogonal cells for the defense-layout graybox; no isometric island mask.
static func defense_plot(size: Vector2i = Vector2i(18,16)) -> Dictionary:
	var cells: Dictionary = {}
	for x in range(size.x):
		for y in range(size.y): cells[Vector2i(x,y)] = true
	return {"size":size, "cells":cells, "grade_index":0}

# Screen-aligned rectangle in half-tile projection coordinates (x-y, x+y).
# Width uses a full 128px tile; height uses a full 64px row. The integer
# isometric grid remains unchanged; only the buildable mask is rectangular.
static func build(grade_index: int = 0) -> Dictionary:
	var size := START_SIZE + Vector2i(maxi(0, grade_index) * GRADE_WIDTH, 0)
	var center := Vector2i(size.x, size.x)
	var cells: Dictionary = {}
	for x in range(size.x * 2 + size.y):
		for y in range(size.x * 2 + size.y):
			var delta := Vector2i(x, y) - center
			if absi(delta.x - delta.y) < size.x and absi(delta.x + delta.y) < size.y:
				cells[Vector2i(x, y)] = true
	return {"size": size, "cells": cells, "center": center, "grade_index": maxi(0, grade_index)}

static func contains_rect(plot: Dictionary, rect: Rect2i) -> bool:
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			if not plot.get("cells", {}).has(Vector2i(x, y)):
				return false
	return true
