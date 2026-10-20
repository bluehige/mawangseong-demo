extends Control
# Presentation-only: composed from the live map renderer, never a game facility instance.
var game: Node
var facility_id := ""
var world_preview := false
var last_key := ""
var visual: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func _process(_delta: float) -> void:
	if game == null or game.quarter_renderer == null or game.graph == null:
		return
	var placement = game.build_placement
	var room_id: String = placement.visual_room()
	var active_id := facility_id
	if world_preview:
		active_id = str(game.build_pick_facility_id)
		visible = game.current_screen == "management" and game.build_pick_mode and active_id != "" and (placement.pointer_active or placement.hover_room != "" or game.build_preview_room_id != "" or not placement.plot.preview.is_empty())
		if not visible:
			return
		modulate.a = 0.88
	var next_visual: Dictionary = game.quarter_renderer.facility_visual(room_id, active_id)
	if world_preview:
		var plot = placement.plot
		if plot.active() and not plot.preview.is_empty() and plot.preview.id != "":
			room_id = plot.preview.id
			next_visual = game.quarter_renderer.facility_visual(room_id,active_id,plot.ghost_graph)
			modulate = Color("#6bec9a") if plot.preview.ok else Color("#ff6878")
			modulate.a = 0.78
		var bounds: Rect2 = next_visual.get("bounds", Rect2())
		var offset := Vector2.ZERO
		if plot.active() and not plot.preview.is_empty() and plot.ghost_graph == null:
			var original: Dictionary = game.graph.placed_module_data(room_id)
			if not original.is_empty(): offset = plot.world(plot.preview.origin)-plot.world(preload("res://scripts/dungeon_quarter/IsoMath.gd").array_to_cell(original.grid_origin))
		if not plot.active() and not game._can_change_room_facility(placement.hover_room) and game.build_preview_room_id == "" and placement.pointer_active:
			offset = placement.pointer_world - game.graph.center(room_id)
		# Give the world Control real local bounds so viewport culling includes its art.
		position = bounds.position + offset
		size = bounds.size
	var key := "%s:%s:%s:%s:%s" % [next_visual.get("key", ""), size, placement.pointer_world if world_preview else Vector2.ZERO, game.build_preview_room_id,placement.plot.preview_key if world_preview else ""]
	if key != last_key:
		visual = next_visual
		last_key = key
		queue_redraw()

func _draw() -> void:
	if game == null or visual.is_empty():
		return
	var bounds: Rect2 = visual.get("bounds", Rect2())
	if bounds.size.x <= 0.0:
		return
	if world_preview:
		draw_set_transform(-bounds.position)
	else:
		var factor := minf(size.x / bounds.size.x, size.y / bounds.size.y)
		draw_set_transform((size - bounds.size * factor) * 0.5 - bounds.position * factor, 0.0, Vector2.ONE * factor)
	game.quarter_renderer.draw_facility_visual(self, visual)
	draw_set_transform(Vector2.ZERO)
