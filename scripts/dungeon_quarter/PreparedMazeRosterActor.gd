extends Node2D
const Art = preload("res://scripts/ui/UIUXActorArt.gd")
var texture: Texture2D
var body: Sprite2D

func update_body() -> void:
	if not is_instance_valid(body):
		body = Sprite2D.new()
		body.name = "Body"
		body.centered = false
		add_child(body)
	body.texture = texture
	if texture != null:
		var rect: Rect2 = Art.preview_rect(texture, Vector2(0, 12), 54.0)
		body.position = rect.position
		body.scale = rect.size / texture.get_size()

func _draw() -> void:
	draw_circle(Vector2(0, 12), 18.0, Color("#05050699"))
	draw_arc(Vector2(0, 1), 25.0, 0.0, TAU, 36, Color("#f0d375aa"), 1.6)
