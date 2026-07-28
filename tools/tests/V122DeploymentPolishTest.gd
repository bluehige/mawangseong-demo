extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = GameRootScene.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame
	game._debug_skip_onboarding()
	GameState.day = 2
	game._choose_early_specialization("goblin", "goblin_treasure_hunter")
	game._set_global_directive(Constants.DIRECTIVE_DEFENSE)
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await get_tree().process_frame

	_expect(game.ui_layer.find_child("MapEditButton", true, false) == null, "management UI removes the castle structure edit button")
	var management_model: Dictionary = game.get_meta("v122_management_view_model", {})
	_expect(not _action_ids(management_model).has("map_edit"), "management view model no longer exposes map editing")

	var patrol_path: Array = game.graph.room_patrol_path("spike_corridor")
	_expect(game.graph.is_corridor_room("spike_corridor"), "spike corridor is recognized from actual walk-cell data")
	_expect(patrol_path.size() >= 12, "corridor patrol uses a long route instead of a tiny local loop")
	if patrol_path.size() >= 2:
		_expect(patrol_path[0].distance_to(patrol_path[-1]) >= 120.0, "corridor patrol endpoints are meaningfully separated")
	_expect(_all_walkable(game, patrol_path), "corridor patrol path stays inside walkable corridor cells")

	var first = game._create_unit("slime", DataRegistry.monster("slime"), Constants.FACTION_MONSTER, "spike_corridor")
	var second = game._create_unit("goblin", DataRegistry.monster("goblin"), Constants.FACTION_MONSTER, "spike_corridor")
	game.monster_units.append(first)
	game.monster_units.append(second)
	first.global_position = game.graph.center("spike_corridor")
	second.global_position = game.graph.center("spike_corridor")
	first.set_physics_process(false)
	second.set_physics_process(false)

	game.current_screen = Constants.SCREEN_COMBAT
	game._update_world_render_visibility()
	game.combat_scene.update_monster_path(first)
	game.combat_scene.update_monster_path(second)
	_expect(first.intent_text == "복도 순찰" and second.intent_text == "복도 순찰", "idle corridor defenders enter deliberate patrol state")
	_expect(int(first.get_meta("corridor_patrol_target_index", -1)) != int(second.get_meta("corridor_patrol_target_index", -1)), "two corridor defenders start toward opposite patrol ends")
	_expect(not first.path_points.is_empty() and not second.path_points.is_empty(), "both corridor defenders receive stable navigation paths")
	if not first.path_points.is_empty() and not second.path_points.is_empty():
		_expect(first.path_points[-1].distance_to(second.path_points[-1]) >= 120.0, "two defenders do not crowd the same short target point")
	_expect(_all_walkable(game, first.path_points) and _all_walkable(game, second.path_points), "lane offsets remain inside the combat walk map")
	_expect(
		first.collision_layer == 0
		and first.collision_mask == 0
		and first.find_child("CollisionShape2D", true, false) == null,
		"corridor movement uses collision-free point agents instead of a blocking body collider"
	)

	var first_start: Vector2 = first.global_position
	var second_start: Vector2 = second.global_position
	var max_first_displacement := 0.0
	var max_second_displacement := 0.0
	var first_reversals := 0
	var second_reversals := 0
	var previous_first_direction := Vector2.ZERO
	var previous_second_direction := Vector2.ZERO
	for _frame in range(240):
		game.combat_scene.update_monster_path(first)
		game.combat_scene.update_monster_path(second)
		first._physics_process(1.0 / 60.0)
		second._physics_process(1.0 / 60.0)
		game.combat_scene.refresh_unit_rooms()
		max_first_displacement = maxf(max_first_displacement, first.global_position.distance_to(first_start))
		max_second_displacement = maxf(max_second_displacement, second.global_position.distance_to(second_start))
		var first_direction: Vector2 = first.velocity.normalized()
		var second_direction: Vector2 = second.velocity.normalized()
		if first_direction != Vector2.ZERO and previous_first_direction != Vector2.ZERO and first_direction.dot(previous_first_direction) < -0.5:
			first_reversals += 1
		if second_direction != Vector2.ZERO and previous_second_direction != Vector2.ZERO and second_direction.dot(previous_second_direction) < -0.5:
			second_reversals += 1
		if first_direction != Vector2.ZERO:
			previous_first_direction = first_direction
		if second_direction != Vector2.ZERO:
			previous_second_direction = second_direction
	_expect(max_first_displacement >= 90.0 and max_second_displacement >= 90.0, "corridor defenders travel across the corridor instead of pacing in place")
	_expect(first_reversals <= 2 and second_reversals <= 2, "corridor patrol avoids rapid back-and-forth direction changes")

	game.current_screen = Constants.SCREEN_MANAGEMENT
	game._update_world_render_visibility()
	_expect(not game.unit_root.visible, "placement view hides surviving combat actor sprites")
	_expect(not game.effect_root.visible, "placement view hides leftover combat effects")
	_expect(game.unit_root.get_child_count() >= 2, "visibility rule hides combat actors even while runtime instances still exist")
	game.current_screen = Constants.SCREEN_COMBAT
	game._update_world_render_visibility()
	_expect(game.unit_root.visible, "combat actor sprites return only on the combat screen")

	game.queue_free()
	await get_tree().process_frame
	print("V122_DEPLOYMENT_POLISH_TEST: %s" % ("FAIL" if failed else "PASS"))
	get_tree().quit(1 if failed else 0)


func _action_ids(model: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for value in model.get("actions", []):
		if value is Dictionary:
			result.append(str(value.get("id", "")))
	return result


func _all_walkable(game: Node, points: Array) -> bool:
	if points.is_empty():
		return false
	for point_value in points:
		if not (point_value is Vector2) or not game.graph.is_walkable(point_value):
			return false
	return true


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	failed = true
	push_error("FAIL: %s" % message)
