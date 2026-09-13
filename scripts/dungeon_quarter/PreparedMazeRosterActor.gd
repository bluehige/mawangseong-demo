extends Node2D
const Art = preload("res://scripts/ui/UIUXActorArt.gd")
var texture: Texture2D
func _draw() -> void:
	draw_circle(Vector2(0, 12), 18.0, Color("#05050699"))
	if texture != null:
		draw_texture_rect(texture, Art.preview_rect(texture, Vector2(0, 12), 54.0), false)
	draw_arc(Vector2(0, 1), 25.0, 0.0, TAU, 36, Color("#f0d375aa"), 1.6)
