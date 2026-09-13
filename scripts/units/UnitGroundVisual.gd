extends Node2D
var unit: Node2D
func _draw() -> void:
	if not is_instance_valid(unit): return
	unit._draw_contact_shadow(self)
	if unit.selected and not unit.down:
		unit._draw_selection_ground_marker(self)
