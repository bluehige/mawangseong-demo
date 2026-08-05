extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const LAYOUT_PATH := "res://data/dungeon_quarter/test_layouts/role_driven_combat_layout_test_01.json"

var game: Node
var output_dir := ""
var failed := false

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	output_dir = ProjectSettings.globalize_path("res://tmp/role_combat_verification")
	DirAccess.make_dir_recursive_absolute(output_dir)

	var layout := _load_json(LAYOUT_PATH)
	_expect(not layout.is_empty(), "role combat layout file loads")

	game = GameRootScene.instantiate()
	add_child(game)
	await _settle()
	if game.has_method("_debug_skip_onboarding"):
		game._debug_skip_onboarding()
		await _settle()

	var layout_id := str(layout.get("template_id", "role_driven_combat_layout_test_01"))
	_expect(DataRegistry.register_quarter_layout(layout_id, layout, false), "test layout registers without writing custom layouts")
	_expect(game.set_quarter_layout(layout_id), "test layout applied to GameRoot")
	_expect(game.graph.path_between("outside_approach", "throne") == [
		"outside_approach",
		"entrance",
		"path_entrance_trap",
		"spike_corridor",
		"path_trap_barracks",
		"barracks",
		"path_barracks_throne",
		"throne"
	], "main route stays forced in capture scene")

	game._select_room("barracks")
	await _settle()
	await _save("01_management_role_layout.png")

	game.debug_show_room_id_overlay = true
	game.debug_show_socket_overlay = true
	game.debug_show_walkable_overlay = true
	game.queue_redraw()
	await _settle()
	await _save("02_management_role_debug_overlay.png")

	game._start_combat()
	await _settle()
	game._spawn_enemy("explorer")
	game._spawn_enemy("thief")
	await _settle()

	var explorer = _unit_by_id(game.enemy_units, "explorer")
	var thief = _unit_by_id(game.enemy_units, "thief")
	_expect(explorer != null and explorer.goal_room == "throne", "explorer targets throne")
	_expect(thief != null and thief.goal_room == "treasure", "thief targets treasure lure branch")

	game.debug_show_path_overlay = true
	if explorer != null:
		game._select_unit(explorer)
	await _settle()
	await _save("03_combat_explorer_throne_path.png")

	if thief != null:
		game._select_unit(thief)
	await _settle()
	await _save("04_combat_thief_treasure_path.png")

	if explorer != null:
		explorer.current_room = "spike_corridor"
		explorer.global_position = game.graph.center("spike_corridor")
		game.trap_cooldown = 0.0
		var hp_before_trap = explorer.hp
		game._update_room_effects(2.0)
		_expect(explorer.hp < hp_before_trap, "trap room damages enemy during capture")
	await _settle()
	await _save("05_combat_trap_trigger.png")

	if explorer != null:
		var front_wall := _front_wall_near_viewport_center()
		_expect(not front_wall.is_empty(), "front wall overlap capture finds an actually drawn camera-facing wall")
		if not front_wall.is_empty():
			var wall_sample: Dictionary = front_wall.get("debug_overlap_sample", {})
			var unit_sample := _unit_overlap_sample(explorer)
			_expect(not wall_sample.is_empty(), "front wall overlap uses an opaque pixel from the wall PNG")
			_expect(not unit_sample.is_empty(), "front wall overlap uses an opaque pixel from the explorer sprite")
			explorer.set_physics_process(false)
			explorer.set_process(false)
			if explorer.sprite != null:
				explorer.sprite.pause()
			if not wall_sample.is_empty() and not unit_sample.is_empty():
				var wall_point: Vector2 = wall_sample.get("world_point", Vector2.ZERO)
				var unit_local_point: Vector2 = unit_sample.get("local_point", Vector2.ZERO)
				var current_unit_point: Vector2 = explorer.sprite.to_global(unit_local_point)
				explorer.global_position += wall_point - current_unit_point
			explorer.refresh_depth_slot()
			game.debug_show_path_overlay = false
			game.debug_show_room_id_overlay = false
			game.debug_show_socket_overlay = false
			game.debug_show_walkable_overlay = false
			game.queue_redraw()
			await _settle()
			if not wall_sample.is_empty() and not unit_sample.is_empty():
				var actual_unit_point: Vector2 = explorer.sprite.to_global(unit_sample.get("local_point", Vector2.ZERO))
				var actual_draw_rect: Rect2 = game.quarter_renderer.debug_structural_wall_draw_rect(front_wall)
				var wall_source_alpha: float = float(game.quarter_renderer.debug_structural_wall_source_alpha_at(front_wall, actual_unit_point))
				_expect(actual_draw_rect.has_point(actual_unit_point), "explorer opaque pixel lies inside the actual wall PNG draw rect")
				_expect(actual_unit_point.distance_to(wall_sample.get("world_point", Vector2.ZERO)) <= 1.0, "explorer and wall opaque pixels share the same screen coordinate")
				_expect(float(unit_sample.get("source_alpha", 0.0)) >= 0.75, "explorer overlap pixel remains opaque after chroma-key filtering")
				_expect(wall_source_alpha >= 0.75, "wall overlap pixel is opaque before the configured translucency is applied")
				_expect(explorer.debug_depth_slot() < game.quarter_renderer.front_wall_depth(), "explorer stays behind the translucent front-wall layer")
			await _save("06_combat_front_wall_transparency.png")

		var top_floor_point := _walkable_vertical_extreme(true)
		_expect(top_floor_point != Vector2.ZERO, "top-floor capture finds a visible walkable cell")
		if top_floor_point != Vector2.ZERO:
			explorer.global_position = top_floor_point
			explorer.refresh_depth_slot()
			_expect(explorer.debug_depth_slot() >= 1, "top-floor unit remains above static floor depth")
			await _settle()
			await _save("07_combat_top_floor_depth.png")

		var bottom_floor_point := _walkable_vertical_extreme(false)
		_expect(bottom_floor_point != Vector2.ZERO, "bottom-floor capture finds a visible walkable cell")
		if bottom_floor_point != Vector2.ZERO:
			explorer.global_position = bottom_floor_point
			explorer.refresh_depth_slot()
			_expect(explorer.debug_depth_slot() <= 44, "bottom-floor unit remains below front-wall depth")
			await _settle()
			await _save("08_combat_bottom_floor_depth.png")

	print("ROLE_COMBAT_LAYOUT_CAPTURE: %s" % output_dir)
	if failed:
		print("ROLE_COMBAT_LAYOUT_CAPTURE: FAIL")
		get_tree().quit(1)
	else:
		print("ROLE_COMBAT_LAYOUT_CAPTURE: PASS")
		get_tree().quit(0)

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing layout: %s" % path)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	push_error("Invalid JSON layout: %s" % path)
	return {}

func _settle() -> void:
	for i in range(10):
		await get_tree().process_frame
		await get_tree().physics_frame

func _save(file_name: String) -> void:
	await get_tree().process_frame
	var texture = get_viewport().get_texture()
	if texture == null:
		push_error("Viewport texture is null. Run this capture without --headless.")
		failed = true
		return
	var image = texture.get_image()
	if image == null:
		push_error("Viewport image is null. Run this capture without --headless.")
		failed = true
		return
	var path = "%s/%s" % [output_dir, file_name]
	var err = image.save_png(path)
	if err != OK:
		push_error("Failed to save screenshot: %s" % path)
		failed = true

func _unit_by_id(units: Array, unit_id: String) -> Node:
	for unit in units:
		if unit.unit_id == unit_id:
			return unit
	return null


func _front_wall_near_viewport_center() -> Dictionary:
	var best: Dictionary = {}
	var best_distance := INF
	var target := Vector2(960.0, 540.0)
	for value in game.quarter_renderer.debug_wall_edge_records():
		if not value is Dictionary:
			continue
		var record: Dictionary = value
		if str(record.get("side", "")) not in ["E", "S"]:
			continue
		if str(record.get("state", "closed")) != "closed":
			continue
		var overlap_sample: Dictionary = game.quarter_renderer.debug_structural_wall_overlap_sample(record)
		if overlap_sample.is_empty():
			continue
		var draw_rect: Rect2 = overlap_sample.get("draw_rect", Rect2())
		var center := draw_rect.get_center()
		if center.x < 520.0 or center.x > 1400.0 or center.y < 260.0 or center.y > 760.0:
			continue
		var distance := center.distance_squared_to(target)
		if distance < best_distance:
			best = record.duplicate(true)
			best["debug_overlap_sample"] = overlap_sample
			best_distance = distance
	return best


func _unit_overlap_sample(unit: Node) -> Dictionary:
	var animated := unit.get("sprite") as AnimatedSprite2D
	if animated == null or animated.sprite_frames == null:
		return {}
	var texture := animated.sprite_frames.get_frame_texture(animated.animation, animated.frame) as Texture2D
	if texture == null:
		return {}
	var image := texture.get_image()
	if image == null or image.is_empty():
		return {}
	var size := Vector2(image.get_width(), image.get_height())
	var target := size * Vector2(0.5, 0.55)
	var step := maxi(1, int(minf(size.x, size.y) / 64.0))
	var best_pixel := Vector2i(-1, -1)
	var best_alpha := 0.0
	var best_distance := INF
	for y in range(0, image.get_height(), step):
		for x in range(0, image.get_width(), step):
			var effective_alpha := _effective_sprite_alpha(image.get_pixel(x, y))
			if effective_alpha < 0.75:
				continue
			var distance := Vector2(x + 0.5, y + 0.5).distance_squared_to(target)
			if distance < best_distance:
				best_pixel = Vector2i(x, y)
				best_alpha = effective_alpha
				best_distance = distance
	if best_pixel.x < 0:
		return {}
	var displayed_source_point := Vector2(best_pixel) + Vector2(0.5, 0.5)
	if animated.flip_h:
		displayed_source_point.x = size.x - displayed_source_point.x
	if animated.flip_v:
		displayed_source_point.y = size.y - displayed_source_point.y
	return {
		"local_point": displayed_source_point - size * 0.5 + animated.offset,
		"source_alpha": best_alpha,
		"source_pixel": best_pixel
	}


func _effective_sprite_alpha(color: Color) -> float:
	var magenta_excess := minf(color.r, color.b) - color.g
	var magenta_balance := 1.0 - smoothstep(0.10, 0.32, absf(color.r - color.b))
	var chroma_strength := smoothstep(0.10, 0.34, magenta_excess) * magenta_balance
	return color.a * (1.0 - chroma_strength)

func _walkable_vertical_extreme(top: bool) -> Vector2:
	var best := Vector2.ZERO
	var found := false
	for value in game.graph.debug_walkable_rects():
		if not value is Rect2:
			continue
		var center: Vector2 = value.get_center()
		if center.x < 520.0 or center.x > 1400.0 or center.y < 220.0 or center.y > 800.0:
			continue
		if not found or (top and center.y < best.y) or (not top and center.y > best.y):
			best = center
			found = true
	return best if found else Vector2.ZERO

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		push_error("FAIL: %s" % message)
		failed = true
