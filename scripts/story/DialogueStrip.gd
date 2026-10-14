extends "res://scripts/ui/kit/KitPanel.gd"
## Dialogue-only corner jewels; the shared kit keeps its existing decoration.

func _draw() -> void:
	super()
	for x in [12.0, size.x - 12.0]:
		var center := Vector2(x, 0)
		var diamond := PackedVector2Array([center + Vector2(0, -12), center + Vector2(8, 0), center + Vector2(0, 12), center + Vector2(-8, 0)])
		draw_colored_polygon(diamond, Kit.Tokens.ACCENT)
		diamond.append(diamond[0])
		draw_polyline(diamond, Kit.Tokens.HIGHLIGHT, 2, true)
		for direction in [-1, 1]:
			draw_polyline(PackedVector2Array([center + Vector2(direction * 12, 0), center + Vector2(direction * 22, 8), center + Vector2(direction * 22, 22)]), Kit.Tokens.BORDER, 2, true)
