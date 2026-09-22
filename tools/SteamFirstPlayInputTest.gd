extends Node

const Game = preload("res://scenes/game/GameRoot.tscn")
const C = preload("res://scripts/core/Constants.gd")
var game
var failed := false
var checks := 0
var use_monster_drag := false
var evidence := "res://tmp/steam_review_fix"

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var locale := args[0] if not args.is_empty() else "en"
	if args.size() > 1:
		evidence = args[1]
	use_monster_drag = args.size() > 2 and args[2] == "drag"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(evidence))
	LanguageSettings.set_locale(locale, false)
	UISettings.set_tutorial_guidance_level(UISettings.TUTORIAL_GUIDANCE_FULL, false)
	TutorialGuidanceHistory.reset(false)
	game = Game.instantiate()
	game.campaign_save_enabled = false
	add_child(game)
	await settle()
	game.pending_title_reset_mode = "new"
	game._onboarding_start_new_game()
	await settle()
	game.onboarding_name_input.text = "Review"
	game._onboarding_confirm_name()
	await drain_dialogue()
	check(game.current_screen == C.SCREEN_INTRUSION_BRIEF, "new game reaches intrusion brief")
	await click_control("EnterPlacementButton")
	check(game.current_screen == C.SCREEN_MANAGEMENT, "real placement button opens management")
	check(game.tutorial_gate_enabled and game.tutorial_manager.current_step_id() == "TUT_030_SELECT_SLIME", "required first-play tutorial is active")
	await capture("01_first_placement")
	await check_passive_parent_controls()
	var map_point := world(game.graph.center("recovery"))
	check(not game._management_ui_at(map_point), "passive tutorial overlay leaves the map interactive")
	var footer := game.ui_layer.find_child("StartCombatButton", true, false) as Button
	check(footer != null and game._management_ui_at(control_center(footer)), "real HUD controls still block map actions")

	# Exercise building before tutorial completion, as in the rejected Steam build.
	await click_control("ManagementTab_build")
	var card := game.ui_layer.find_child("FacilityCard_watch_post", true, false) as Button
	check(card != null and not card.disabled, "new game offers an affordable facility card")
	if card != null and not card.disabled:
		var before_gold: int = GameState.gold
		var before_mana: int = GameState.mana
		await drag(control_center(card), world(game.graph.center("slot_01")))
		check(game.build_preview_room_id == "slot_01", "real facility drag reaches the selected map slot with tutorial on")
		check(GameState.gold == before_gold and GameState.mana == before_mana, "drag and review do not spend resources")
		await capture("02_facility_review")
		if game.build_preview_room_id == "slot_01":
			await click_control("ConfirmFacilityReplacementButton")
			check(str(game.rooms["slot_01"].get("facility_role", "")) == "watch_post", "real confirmation installs facility")
			var cost: Dictionary = game._facility_definition("watch_post").get("cost", {})
			check(GameState.gold == before_gold - int(cost.get("gold", 0)) and GameState.mana == before_mana - int(cost.get("mana", 0)), "facility confirmation charges exactly once")
		else:
			await press_key(KEY_ESCAPE)

	await click_control("ManagementTab_roster")
	var gob := game.ui_layer.find_child("MonsterCard_goblin", true, false) as Button
	check(gob != null and not gob.disabled, "required Gob card is available")
	if gob != null:
		var target: Vector2 = world(game.graph.center("recovery"))
		if use_monster_drag:
			await drag(control_center(gob), target)
		else:
			await click(control_center(gob))
			check(game.tutorial_manager.current_step_id() == "TUT_040_DEPLOY_SLIME", "real Gob click advances to formation choice")
			var ring := game.ui_layer.find_child("TutorialFocusRing", true, false) as Control
			check(ring != null and ring.get_global_rect().has_point(game.ui_layer.transform.affine_inverse() * target), "formation highlight covers the displayed room after map fitting")
			await capture("03_formation_choice")
			await click(target)
		check(str(game.monster_roster["goblin"].get("room", "")) == "recovery", "real mouse %s places Gob in rear formation" % ("drag" if use_monster_drag else "click"))
		await drain_dialogue()
		check(not game._management_action_mode_active(), "completed placement clears pending mode")
		check(game.ui_layer.find_child("TutorialOverlay", true, false) == null, "completed placement removes grey tutorial overlay")
		footer = game.ui_layer.find_child("StartCombatButton", true, false) as Button
		check(footer != null and not footer.disabled, "Defense becomes enabled after the required placement")
		await capture("04_ready_to_defend")
		if footer != null and not footer.disabled:
			await click(control_center(footer))
			await drain_dialogue()
			await get_tree().create_timer(3.5).timeout
			await drain_dialogue()
			check(game.current_screen == C.SCREEN_COMBAT, "real Defense click and countdown enter combat")
			await get_tree().create_timer(5.0).timeout
			check(not game.enemy_units.is_empty() and not game.monster_units.is_empty(), "combat spawns the enemy and defenders")
			await capture("05_live_combat")

	game._shutdown_audio_for_exit()
	game.queue_free()
	await settle(2)
	print("STEAM_FIRST_PLAY_INPUT_TEST: %s (%d checks, %s)" % ["FAIL" if failed else "PASS", checks, locale])
	get_tree().quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	checks += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", label])
	failed = failed or not ok

func settle(count: int = 5) -> void:
	for index in range(count):
		await get_tree().process_frame
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw

func world(point: Vector2) -> Vector2:
	return game.get_global_transform_with_canvas() * point

func control_center(control: Control) -> Vector2:
	return control.get_global_transform_with_canvas() * (control.size * 0.5)

func mouse(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.global_position = point
	event.pressed = pressed
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	get_viewport().push_input(event, true)

func motion(point: Vector2, held: bool = false) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	get_viewport().push_input(event, true)

func click(point: Vector2) -> void:
	motion(point)
	mouse(point, true)
	mouse(point, false)
	await settle()

func click_control(id: String) -> void:
	var control := game.ui_layer.find_child(id, true, false) as Control
	check(control != null, "control exists: " + id)
	if control != null:
		await click(control_center(control))

func drag(from: Vector2, to: Vector2) -> void:
	motion(from)
	mouse(from, true)
	await settle(2)
	for index in range(1, 5):
		motion(from.lerp(to, index / 4.0), true)
		await settle(2)
	mouse(to, false)
	await settle()

func press_key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	get_viewport().push_input(event, true)
	event = InputEventKey.new()
	event.keycode = code
	get_viewport().push_input(event, true)
	await settle()

func drain_dialogue() -> void:
	var quiet := 0
	for index in range(160):
		await get_tree().process_frame
		if game.story_director.is_active():
			quiet = 0
			game._story_advance_dialogue(true)
		elif game.current_screen == C.SCREEN_DIALOGUE:
			quiet = 0
			game._onboarding_advance_dialogue()
		else:
			quiet += 1
			if quiet >= 3:
				await settle()
				return
	check(false, "dialogue finishes")

func capture(id: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await settle(2)
	check(get_viewport().get_texture().get_image().save_png(evidence.path_join(id + ".png")) == OK, "capture " + id)

func check_passive_parent_controls() -> void:
	var panel := Panel.new()
	panel.position = Vector2(800, 300)
	panel.size = Vector2(300, 200)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.ui_layer.add_child(panel)
	var button := Button.new()
	button.position = Vector2(20, 20)
	button.size = Vector2(100, 40)
	panel.add_child(button)
	check(game._management_ui_at(control_center(button)), "interactive child of a passive panel still blocks map input")
	panel.hide()
	check(not game._management_control_blocks_pointer(panel, control_center(button)), "hidden descendants do not block map input")
	panel.show()
	button.position = Vector2(320, 20)
	panel.clip_contents = true
	check(not game._management_control_blocks_pointer(panel, control_center(button)), "clipped descendants do not block map input")
	panel.queue_free()
	await settle()
