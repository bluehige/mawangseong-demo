class_name V20RoutePreview
extends Control

const UIFontScript = preload("res://scripts/ui/UIFont.gd")

var board: Dictionary = {}
var route: Dictionary = {}


func setup(board_value: Dictionary, route_value: Dictionary) -> void:
	board = board_value.duplicate(true)
	route = route_value.duplicate(true)
	_rebuild_labels()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and not board.is_empty():
		_rebuild_labels()
		queue_redraw()


func _draw() -> void:
	if board.is_empty():
		return
	var active_edges: Array = route.get("edges", [])
	for edge_value in board.get("edges", []):
		var edge: Dictionary = edge_value
		var start := _node_position(str(edge.get("from", "")))
		var finish := _node_position(str(edge.get("to", "")))
		var active: bool = active_edges.has(str(edge.get("id", "")))
		draw_line(start, finish, Color("#e8bb58") if active else Color("#554b60"), 7.0 if active else 3.0, true)
	for node_id_value in board.get("nodes", []):
		var node_id := str(node_id_value)
		var active: bool = route.get("nodes", []).has(node_id)
		draw_circle(_node_position(node_id), 13.0 if active else 9.0, Color("#ffe4a0") if active else Color("#8b799b"))
		draw_circle(_node_position(node_id), 6.0, Color("#17131f"))


func _rebuild_labels() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for node_id_value in board.get("nodes", []):
		var node_id := str(node_id_value)
		var label := Label.new()
		label.name = "NodeLabel_%s" % node_id
		label.text = _display_name(node_id)
		label.position = _node_position(node_id) + Vector2(-68, 15)
		label.size = Vector2(136, 24)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_EMPHASIS))
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", Color("#ffe4a0") if route.get("nodes", []).has(node_id) else Color("#bdb3c6"))
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
	var summary := Label.new()
	summary.name = "RouteSummary"
	summary.text = "예상 경로 · %s · 비용 %.1f" % [str(route.get("goal_key", "목표")), float(route.get("total_cost", 0.0))]
	summary.position = Vector2(18, 12)
	summary.size = Vector2(maxf(200.0, size.x - 36), 28)
	summary.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_EMPHASIS))
	summary.add_theme_font_size_override("font_size", 14)
	summary.add_theme_color_override("font_color", Color("#e8bb58"))
	summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(summary)


func _node_position(node_id: String) -> Vector2:
	var value: Array = board.get("node_positions", {}).get(node_id, [0.5, 0.5])
	var x := float(value[0]) if value.size() > 0 else 0.5
	var y := float(value[1]) if value.size() > 1 else 0.5
	return Vector2(28.0 + x * maxf(1.0, size.x - 56.0), 38.0 + y * maxf(1.0, size.y - 78.0))


func _display_name(node_id: String) -> String:
	var names := {
		"entrance": "침입구", "north_gate": "북문", "north_cross": "북부 교차로",
		"south_gate": "남문", "south_cross": "남부 교차로", "treasure": "미끼 보물",
		"fallback": "후퇴선", "throne": "왕좌"
	}
	return str(names.get(node_id, node_id))
