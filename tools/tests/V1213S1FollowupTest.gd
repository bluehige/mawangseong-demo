extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const OUTPUT = "res://tmp/v1213_s1fu"
var game: Node
var checks := 0
var failures: Array[String] = []
var measurements: Array = []

func _ready() -> void:
	get_tree().create_timer(300).timeout.connect(func(): get_tree().quit(2))
	call_deferred("run")

func expect(ok: bool, message: String) -> void:
	checks += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", message])
	if not ok: failures.append(message)

func settle() -> void:
	for i in range(8): await get_tree().process_frame

func control(name: String) -> Control:
	return game.ui_layer.find_child(name, true, false) as Control

func click_point(point: Vector2, mode: String = "mouse") -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	get_viewport().push_input(motion, true)
	for pressed in [true, false]:
		var event: InputEvent
		if mode == "touch":
			event = InputEventScreenTouch.new()
			event.index = 0
		else:
			event = InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT
			event.global_position = get_viewport().get_final_transform() * point
		event.position = get_viewport().get_final_transform() * point
		event.pressed = pressed
		# parse_input_event also exercises Godot's touch-to-mouse emulation.
		Input.parse_input_event(event)
		await get_tree().process_frame
	await settle()

func click(name: String, mode: String = "mouse") -> void:
	var button := control(name) as Button
	if button == null or not button.is_visible_in_tree() or button.disabled:
		expect(false, "clickable " + name)
		return
	if mode == "keyboard":
		button.grab_focus()
		for pressed in [true, false]:
			var event := InputEventKey.new()
			event.keycode = KEY_ENTER
			event.pressed = pressed
			Input.parse_input_event(event)
			await get_tree().process_frame
		await settle()
	else:
		await click_point(button.get_global_rect().get_center(), mode)

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	expect(image.get_size() == Vector2i(1920, 1080), "capture 1920x1080 " + name)
	image.save_png(OUTPUT.path_join(name + ".png"))

func tutorial(step_id: String) -> void:
	for i in range(game.tutorial_manager.steps.size()):
		var step: Dictionary = game.tutorial_manager.steps[i]
		if str(step.id) == step_id:
			game.tutorial_manager.completed.erase(step_id)
			game.tutorial_manager.current_index = i
			game.tutorial_manager.active = true
			game._onboarding_set_stage(str(step.stage))
			return
	expect(false, "tutorial fixture " + step_id)

func run() -> void:
	expect(ProjectSettings.globalize_path("user://").replace("\\", "/").contains("/tmp/v1213_s1fu/"), "isolated APPDATA")
	if not failures.is_empty(): get_tree().quit(1); return
	GameState.reset()
	game = load("res://scenes/game/GameRoot.tscn").instantiate()
	game.campaign_save_enabled = false
	game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v4_enabled = false
	game.campaign_save_v5_enabled = false
	add_child(game)
	await settle()
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(Vector2i(1920, 1080))
		await settle()
	game.story_feature_enabled = false
	game.set_process(false)
	game.set_physics_process(false)
	if OS.get_cmdline_user_args().has("--touch-only"):
		await room_touch_guards()
	else:
		if not OS.get_cmdline_user_args().has("--geometry-only"): await growth()
		if not OS.get_cmdline_user_args().has("--growth-only"): await geometry()
	if not measurements.is_empty():
		var file := FileAccess.open(OUTPUT.path_join("geometry.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify(measurements, "\t"))
		file.close()
	game.queue_free()
	await settle()
	print("V1213_S1_FOLLOWUP: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func growth() -> void:
	for mode in ["mouse", "keyboard", "touch"]:
		GameState.day = 1
		GameState.onboarding_complete = false
		GameState.gold = 500
		game.onboarding_enabled = true
		game.tutorial_gate_enabled = true
		tutorial("TUT_090_RESULT_GROWTH")
		game.selected_monster_id = "slime"
		game.monster_roster.slime.level = 1
		game.monster_roster.slime.exp = 0
		game.monster_roster.slime.training_count_today = 0
		game.monster_roster.slime.training_day = 1
		# Public synthetic post-victory state; no personal save is loaded.
		game.result_summary = {"win": true, "lines": ["DAY1 fixture"]}
		game.last_growth_summary = [{"monster_id": "slime", "display_name": "푸딩", "level_before": 1, "level_after": 1, "exp_gain": 10, "exp_after": 0, "next_exp": 30}]
		game.result_growth_choice_applied = false
		game.result_growth_reviewed = false
		game._set_screen(Constants.SCREEN_MONSTER, false)
		await settle()
		await click("MonsterTrainingButton", mode)
		expect(int(game.monster_roster.slime.training_count_today) == 1, "DAY1 train " + mode)
		game._set_screen(Constants.SCREEN_RESULT, false)
		await settle()
		await click("GrowthChoice_slime", mode)
		expect(game.result_growth_choice_applied and game.result_growth_choice_monster_id == "slime", "DAY1 focus growth " + mode)
		expect(int(game.monster_roster.slime.exp) == 28 and GameState.gold == 470, "train+focus applied exactly once " + mode)
		expect((control("GrowthChoice_slime") as Button).disabled and not game.pause_menu_open, "focus disables daily choice without modal " + mode)
		game._set_screen(Constants.SCREEN_MONSTER, false)
		await settle()
		await click("CHR_GOB", mode)
		expect(game.selected_monster_id == "goblin", "after train+focus select goblin " + mode)
		await click("CHR_PYNN", mode)
		expect(game.selected_monster_id == "imp", "after train+focus select imp " + mode)
		expect((control("MonsterSelectedDetail").get_child(0) as Label).text == game._monster_companion_name("imp"), "selected imp detail rebuilt " + mode)
		if mode == "mouse": await capture("growth_selected_imp")
		await click("CHR_PUDDING", mode)
		expect(game.selected_monster_id == "slime", "after train+focus select slime " + mode)
		if mode == "mouse": await capture("growth_train_focus_selection")
		game._set_screen(Constants.SCREEN_RESULT, false)
		await settle()
		await click("GrowthReviewButton", mode)
		expect(game.result_growth_reviewed, "growth review confirmation " + mode)
		game._open_monster_screen()
		await settle()
		await click("CHR_PYNN", mode)
		expect(game.selected_monster_id == "imp", "selection after growth confirmation " + mode)
		game._set_screen(Constants.SCREEN_MANAGEMENT, false)
		await settle()
		var original_room: String = game.monster_roster.slime.room
		expect(not game._assign_monster_to_room("slime", "recovery") and game.monster_roster.slime.room == original_room, "DAY1 placement restriction preserved " + mode)

func geometry() -> void:
	GameState.day = 2
	game.onboarding_enabled = true
	game.tutorial_gate_enabled = true
	game.management_context_drawer_open = false
	game.management_tool_tab = "roster"
	game.selected_room = "entrance"
	for resolution in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(2560, 1080)]:
		if DisplayServer.get_name() != "headless": DisplayServer.window_set_size(resolution)
		await settle()
		for view_mode in ["fit", "zoom", "pan"]:
			tutorial("TUT_110_TRAP_CORRIDOR")
			game.management_context_drawer_open = false
			game._set_screen(Constants.SCREEN_MANAGEMENT, false)
			await settle()
			game.build_placement.fit_workspace()
			game._tutorial_build_overlay()
			await settle()
			if view_mode != "fit":
				game.build_placement.zoom_workspace(1)
				if view_mode == "pan":
					var point := Vector2(1100, 620)
					var middle := InputEventMouseButton.new()
					middle.position = point
					middle.button_index = MOUSE_BUTTON_MIDDLE
					middle.pressed = true
					get_viewport().push_input(middle, true)
					var motion := InputEventMouseMotion.new()
					motion.position = point + Vector2(50, 20)
					get_viewport().push_input(motion, true)
					middle.position = motion.position
					middle.pressed = false
					get_viewport().push_input(middle, true)
				await settle()
			var ring := control("TutorialFocusRing")
			var rect := ring.get_global_rect().grow(-3)
			var live: Rect2 = game._tutorial_room_rect("spike_corridor")
			var drift := rect.get_center().distance_to(live.get_center())
			expect(DisplayServer.get_name() == "headless" or DisplayServer.window_get_size() == resolution, "actual window resolution " + str(resolution))
			expect(drift < 0.01, "S1-03 overlay follows " + view_mode + " " + str(resolution))
			print("GEOMETRY %s %s viewport=%s ring=%s live=%s drift=%.2f" % [resolution, view_mode, get_viewport().get_visible_rect().size, rect, live, drift])
			var samples := {
				"center": rect.get_center(),
				"left": Vector2(rect.position.x + 1, rect.get_center().y),
				"right": Vector2(rect.end.x - 1, rect.get_center().y),
				"top": Vector2(rect.get_center().x, rect.position.y + 1),
				"bottom": Vector2(rect.get_center().x, rect.end.y - 1),
				"corner": rect.position + Vector2.ONE,
				"badge": control("TutorialClickBadge").get_global_rect().get_center()
			}
			if resolution == Vector2i(1920, 1080) and view_mode == "pan": await capture("tutorial_zoom_pan")
			for sample in samples:
				# Each input starts at the same tutorial step and camera transform.
				# Rebuild the overlay only after recording its navigation drift.
				tutorial("TUT_110_TRAP_CORRIDOR")
				game.management_context_drawer_open = false
				game._set_screen(Constants.SCREEN_MANAGEMENT, false)
				await settle()
				var point: Vector2 = samples[sample]
				var world: Vector2 = game.build_placement.viewport_to_world(point)
				var exact: String = game.build_placement.exact_room(world)
				var blocked: bool = game._management_ui_at(point)
				await click_point(point)
				var advanced: bool = game.tutorial_manager.current_step_id() == "TUT_120_TRAP_LURE"
				measurements.append({"resolution": str(resolution), "view": view_mode, "sample": sample, "point": str(point), "exact": exact, "ui_blocked": blocked, "drift": drift, "success": advanced})
				expect(advanced, "S1-03 %s %s %s exact=%s blocked=%s" % [resolution, view_mode, sample, exact, blocked])
	await room_touch_guards()

func room_touch_guards() -> void:
	game.onboarding_enabled = true
	game.tutorial_gate_enabled = true
	if DisplayServer.get_name() != "headless": DisplayServer.window_set_size(Vector2i(1920, 1080))
	await settle()
	for step_id in ["TUT_110_TRAP_CORRIDOR", "TUT_210_RECOVERY_NEST"]:
		GameState.day = 2 if step_id == "TUT_110_TRAP_CORRIDOR" else 3
		for sample in ["center", "corner", "outer_corner", "badge", "outside", "pause", "build", "hidden"]:
			tutorial(step_id)
			game.management_context_drawer_open = false
			game._set_screen(Constants.SCREEN_MANAGEMENT, false)
			await settle()
			var rect := control("TutorialFocusRing").get_global_rect().grow(-3)
			var point: Vector2 = rect.get_center()
			if sample == "corner": point = rect.position + Vector2.ONE
			if sample == "outer_corner": point = control("TutorialFocusOuter").get_global_rect().position + Vector2.ONE
			if sample == "badge": point = control("TutorialClickBadge").get_global_rect().get_center()
			if sample in ["outside", "pause", "build", "hidden"]:
				if sample == "outside": point = Vector2(-10000, -10000)
				if sample == "pause": game.pause_menu_open = true
				if sample == "build": game.build_pick_mode = true
				if sample == "hidden": game._tutorial_clear_overlay()
				expect(game._tutorial_room_focus_at(point) == "", "S1-03 guard " + step_id + " " + sample)
				game.pause_menu_open = false
				game.build_pick_mode = false
			else:
				# Real screen-touch events through the viewport, no mouse fallback.
				print("TOUCH_TARGET %s %s point=%s hit=%s ui=%s" % [step_id, sample, point, game._tutorial_room_focus_at(point), game._management_ui_at(point)])
				if step_id == "TUT_210_RECOVERY_NEST" and sample == "badge": await capture("recovery_badge")
				for pressed in [true, false]:
					var event := InputEventScreenTouch.new()
					event.position = point
					event.pressed = pressed
					get_viewport().push_input(event, true)
					await get_tree().process_frame
				await settle()
				expect(game.tutorial_manager.completed.has(step_id), "S1-03 direct touch " + step_id + " " + sample)
