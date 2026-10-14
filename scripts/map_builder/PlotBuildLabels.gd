extends RefCounted

const StatusLabel = preload("res://scripts/ui/MapStatusLabel.gd")

# Geometry changed, but visible labels remain selectors until M3. Drawing and
# hit-testing share one layout, including collision avoidance between labels.
static func layouts(root: Node) -> Dictionary:
	var result: Dictionary = {}
	var previous: Array[Rect2] = []
	var transform: Transform2D = root.get_global_transform_with_canvas()
	for id in root.rooms:
		var allowed: bool = root._can_change_room_facility(id) if root.build_pick_facility_id == "" else bool(root._evaluate_facility_placement(id,root.build_pick_facility_id).get("ok",false))
		if not allowed: continue
		var bounds: Rect2 = root.graph.rect(id)
		if not bounds.has_area(): continue
		var anchor := transform * Vector2(bounds.get_center().x,bounds.end.y)
		var layout: Dictionary = root._management_label_layout(anchor,root._building_area_label())
		if root.graph.layout.has("plot_grid"):
			var obstacles: Array[Rect2] = previous.duplicate()
			for child in root.ui_layer.get_children():
				if child is Control and child.is_visible_in_tree() and child.get_meta("u5b_occluder",false): obstacles.append(child.get_global_rect())
			layout.rect = StatusLabel.place(layout.rect,root.get_viewport_rect().grow(-12),obstacles)
		previous.append(layout.rect)
		layout["anchor"] = anchor
		result[id] = layout
	return result
