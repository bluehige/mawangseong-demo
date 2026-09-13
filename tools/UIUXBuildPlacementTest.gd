extends Node
const Game = preload("res://scenes/game/GameRoot.tscn")
const Constants = preload("res://scripts/core/Constants.gd")
var game
var failed := false
var output := "res://tmp/uiux_evidence"
var checks := 0

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence-dir=res://tmp/"):
			output = argument.trim_prefix("--evidence-dir=")
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	game = Game.instantiate()
	add_child(game)
	await settle()
	game._debug_skip_onboarding()
	GameState.day = 2
	game._choose_early_specialization("goblin", "goblin_treasure_hunter")
	game.management_context_drawer_open = false
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await settle()
	await capture("01_management_roster")
	game._set_management_tool_tab("build")
	await settle()
	await capture("02_building_cards")
	var before := state()
	var card := game.ui_layer.find_child("FacilityCard_watch_post", true, false) as Button
	check(card != null, "B01 live building card exists")
	if card == null:
		finish()
		return
	var start := card.get_global_rect().get_center()
	mouse(start, true)
	await settle()
	check(game.build_placement.pointer_active, "B01 GUI press owns building pointer")
	var target: Vector2 = world(game.graph.center("slot_01"))
	motion(target)
	await settle()
	check(game.build_placement.hover_room == "slot_01", "B01 pointer snaps to exact existing slot")
	check(state() == before, "B02 drag preview does not mutate economy, buildings, units or tutorial")

	var ghost = game.build_placement.ghost
	var expected_ghost: Dictionary = game.quarter_renderer.facility_visual("slot_01", "watch_post")
	check(ghost.is_visible_in_tree() and ghost.visual.get("objects", []) == expected_ghost.objects and ghost.visual.get("texture_keys", []) == expected_ghost.texture_keys, "B01 rendered ghost uses the actual candidate composition")
	check(ghost.z_index + game.world_overlay_layer.z_index > 50, "B01 ghost is in front of foreground walls")
	await check_ghost_pixels("drag")
	await capture("03_drag_valid")
	mouse(target, false)
	await settle()
	check(game.build_preview_room_id == "slot_01", "B01 release selects candidate")
	check(state() == before, "B02 drop remains read-only")
	await capture("04_review")
	var preview: Dictionary = game.quarter_renderer.facility_visual("slot_01", "watch_post")
	var confirm := game.ui_layer.find_child("ConfirmFacilityReplacementButton", true, false) as Button
	check(confirm != null and not confirm.disabled, "B03 confirmation is reachable in bottom bar")
	if confirm == null:
		finish()
		return
	var confirm_point := confirm.get_global_rect().get_center()
	mouse(confirm_point, true)
	mouse(confirm_point, false)
	await settle()
	check(str(game.rooms["slot_01"].get("facility_role")) == "watch_post", "B03 real confirmation builds facility")
	var cost: Dictionary = game._facility_definition("watch_post").get("cost", {})
	check(int(GameState.gold) == int(before.gold) - int(cost.get("gold", 0)), "B03 gold charged exactly once")
	check(int(GameState.mana) == int(before.mana) - int(cost.get("mana", 0)), "B03 mana charged exactly once")
	check(not game._confirm_build_preview(), "B03 duplicate confirmation is rejected")
	var installed: Dictionary = game.quarter_renderer.facility_visual("slot_01", "watch_post")
	check(preview.texture_keys == installed.texture_keys and preview.objects == installed.objects, "B11 card, ghost and installation share exact stage, facing and composition")
	await capture("05_built")
	check(game._undo_last_management_placement(), "B08 existing Undo executes")
	await settle()
	check(state() == before, "B08 Undo restores facilities, resources, units and connectors")
	await capture("06_undo")
	await safety_cases()
	await monster_cases()
	await final_input_cases()
	await layout_cases()
	await late_stage_cases()
	finish()

func state() -> Dictionary:
	return {"rooms": game.rooms.duplicate(true), "roster": game.monster_roster.duplicate(true), "gold": GameState.gold, "mana": GameState.mana, "food": GameState.food, "infamy": GameState.infamy, "connectors": game.v122_connector_state.duplicate(true), "tutorial": game.tutorial_manager.current_index}

func world(point: Vector2) -> Vector2:
	return game.get_global_transform_with_canvas() * point

func mouse(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = point
	event.global_position = point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	get_viewport().push_input(event, true)

func motion(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(event, true)

func settle(frames: int = 5) -> void:
	for i in range(frames):
		await get_tree().process_frame
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw

func capture(id: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await settle(2)
	var result := get_viewport().get_texture().get_image().save_png(output.path_join(id + ".png"))
	check(result == OK, "capture " + id)

func check(ok: bool, message: String) -> void:
	checks += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failed = true

func finish() -> void:
	print("UIUX_BUILD_PLACEMENT_TEST: %s (%d checks)" % ["FAIL" if failed else "PASS", checks])
	get_tree().quit(1 if failed else 0)

func drag_card(facility: String, target: Vector2) -> void:
	game._set_management_tool_tab("build")
	await settle(2)
	var card := game.ui_layer.find_child("FacilityCard_" + facility, true, false) as Button
	check(card != null and not card.disabled, "available card " + facility)
	if card == null or card.disabled:
		return
	mouse(card.get_global_rect().get_center(), true)
	motion(target)
	await settle(2)

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	get_viewport().push_input(event, true)
	event = InputEventKey.new()
	event.keycode = code
	event.pressed = false
	get_viewport().push_input(event, true)

func safety_cases() -> void:
	var before := state()
	for entry in [["start_button", Vector2(1700, 1030)], ["outside", Vector2(-200, 200)], ["ui", Vector2(250, 1030)], ["fixed", world(game.graph.center("throne"))], ["empty_space", Vector2(60, 260)]]:
		var point: Vector2 = entry[1]
		await drag_card("watch_post", point)
		await capture("invalid_" + str(entry[0]))
		mouse(point, false)
		await settle(2)
		check(game.build_preview_room_id == "" and state() == before, "B05 invalid drop is free and clears candidate: " + str(entry[0]))
		check(not game.build_placement.pointer_active, "B05 no dangling pointer: " + str(entry[0]))
		key(KEY_ESCAPE)
		await settle(2)
		check(not game._management_action_mode_active(), "B06 ESC clears selection after invalid drop")
	# ESC, tab changes and focus loss while dragging must leave all economic state intact.
	await drag_card("watch_post", world(game.graph.center("slot_01")))
	var start := game.ui_layer.find_child("StartCombatButton", true, false) as Button
	check(start == null or start.disabled, "B12 defense start is disabled during drag")
	game._request_combat_start()
	check(game.current_screen == Constants.SCREEN_MANAGEMENT, "B12 pending placement blocks defense request")
	key(KEY_ESCAPE)
	await settle(2)
	check(state() == before and not game.build_placement.pointer_active, "B06 ESC cancels active drag without cost")
	await drag_card("watch_post", world(game.graph.center("slot_01")))
	game.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await settle(2)
	check(state() == before and not game._management_action_mode_active(), "B06 focus loss cancels active placement")
	await drag_card("watch_post", world(game.graph.center("slot_01")))
	mouse(world(game.graph.center("slot_01")), false)
	await settle(2)
	game._set_management_tool_tab("tactics")
	await settle(2)
	check(state() == before and not game.build_pick_mode, "B06 tab change cancels review without cost")
	await drag_card("watch_post", world(game.graph.center("slot_01")))
	mouse(world(game.graph.center("slot_01")), false)
	await settle(2)
	game._open_settings_screen()
	await settle(2)
	check(not game.build_pick_mode and state() == before, "B06 screen transition clears preview without cost")
	game._close_settings_screen()
	await settle(2)
	# Revalidation uses current resources, not the earlier affordability displayed on the card.
	await drag_card("watch_post", world(game.graph.center("slot_01")))
	mouse(world(game.graph.center("slot_01")), false)
	await settle(2)
	GameState.gold = 0
	var poor := state()
	check(not game._confirm_build_preview() and state() == poor, "B04 resources changing before confirmation cannot partially charge or build")
	GameState.gold = int(before.gold)
	game._cancel_management_action_mode()
	await settle(2)
	check(not bool(game._evaluate_facility_placement("slot_01", "ward_core").ok), "B04 locked facilities are rejected")
	check(not bool(game._evaluate_facility_placement("throne", "watch_post").ok), "B10 fixed rooms are rejected")
	check(not bool(game._evaluate_facility_placement("barracks", "barracks").ok), "B10 replacing with the same facility cannot charge")
	# Unique facilities move under the existing rule; disclose it before moving.
	game._open_build_palette_for_room("slot_01")
	game._set_build_facility("treasure")
	await settle(2)
	check(not game._evaluate_facility_placement("slot_01", "treasure").warnings.is_empty(), "B10 unique facility relocation is disclosed")
	await capture("unique_facility_review")
	check(game._confirm_build_preview(), "B10 unique relocation uses existing construction execution")
	check(game.rooms["treasure"].facility_role == "build_slot", "B10 old unique facility location becomes a build slot")
	game._undo_last_management_placement()
	await settle(2)
	check(state() == before, "B08 unique relocation Undo restores original state")
	# Click alternative: actual GUI click, then actual map click, same review.
	game._set_management_tool_tab("build")
	await settle(2)
	var card := game.ui_layer.find_child("FacilityCard_watch_post", true, false) as Button
	var point := card.get_global_rect().get_center()
	mouse(point, true)
	mouse(point, false)
	await settle(2)
	check(game.build_pick_mode and game.build_preview_room_id == "", "B07 card click arms position selection")
	mouse(world(game.graph.center("slot_01")), true)
	mouse(world(game.graph.center("slot_01")), false)
	await settle(2)
	check(game.build_preview_room_id == "slot_01" and state() == before, "B07 map click uses the same free review")
	game._cancel_management_action_mode()
	await settle(2)
	# Keyboard-only card -> target -> confirmation.
	game._set_management_tool_tab("build")
	await settle(2)
	card = game.ui_layer.find_child("FacilityCard_watch_post", true, false) as Button
	card.grab_focus()
	key(KEY_ENTER)
	await settle(2)
	check(game.build_pick_facility_id == "watch_post", "B07 keyboard activates focused building card")
	key(KEY_RIGHT)
	await settle(2)
	var keyboard_target: String = game.build_placement.hover_room
	key(KEY_ENTER)
	await settle(3)
	check(game.build_preview_room_id == keyboard_target and keyboard_target != "", "B07 keyboard selects an existing target")
	var confirm := game.ui_layer.find_child("ConfirmFacilityReplacementButton", true, false) as Button
	check(confirm != null and confirm.has_focus(), "B07 focus transfers to review confirmation")
	key(KEY_ENTER)
	await settle(2)
	check(game.rooms[keyboard_target].facility_role == "watch_post", "B07 keyboard confirmation builds the same facility")
	game._undo_last_management_placement()
	await settle(2)
	check(state() == before, "B07 keyboard result is reversible with existing Undo")
	# Camera/canvas conversion: test a translated, scaled world while UI remains fixed.
	var original_transform := get_viewport().canvas_transform
	game._set_management_tool_tab("build")
	await settle(2)
	get_viewport().canvas_transform = Transform2D(0.0, Vector2(1.17, 1.17), 0.0, Vector2(82, -105))
	var target: Vector2 = world(game.graph.center("slot_01"))
	card = game.ui_layer.find_child("FacilityCard_watch_post", true, false) as Button
	mouse(card.get_global_rect().get_center(), true)
	motion(target)
	await settle(2)
	check(game.build_placement.hover_room == "slot_01", "B09 zoom and pan use inverse canvas conversion")
	await check_ghost_pixels("zoom_pan")
	await capture("zoom_pan_drag")
	mouse(target, false)
	await settle(2)
	check(game.build_preview_room_id == "slot_01", "B09 transformed drop selects correct slot")
	get_viewport().canvas_transform = original_transform
	game._cancel_management_action_mode()
	await settle(2)
	# No campaign or observation save may be scheduled by preview, even when saving is enabled.
	game.campaign_save_enabled = true
	game.campaign_save_path = "user://uiux_save_contract.json"
	game.campaign_autosave_pending = false
	game._set_build_facility("watch_post")
	game._set_build_preview_target("slot_01")
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	check(not game.campaign_autosave_pending, "B02 preview cannot schedule a campaign save")
	game._cancel_management_action_mode()
	check(not game.campaign_autosave_pending, "B06 cancel cannot schedule a campaign save")
	game.campaign_save_enabled = false
	check(state() == before, "B02 all preview and cancel routes preserve game state")

func layout_cases() -> void:
	for resolution in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		DisplayServer.window_set_size(resolution)
		for scale_value in [0.9, 1.0, 1.15]:
			UISettings.set_text_scale(scale_value, false)
			game._set_management_tool_tab("build")
			await settle(4)
			var prefix := "%dx%d_%d" % [resolution.x, resolution.y, roundi(scale_value * 100)]
			await capture(prefix + "_cards")
			game._open_build_palette_for_room("slot_01")
			game._set_build_facility("treasure")
			await settle(4)
			await check_ghost_pixels(prefix)
			await capture(prefix + "_review")
			for id in ["BuildReviewSummary", "BuildReviewCost", "BuildReviewEffects", "BuildReviewWarning"]:
				var label := game.ui_layer.find_child(id, true, false) as Label
				if label != null and label.get_line_count() * label.get_line_height() > label.size.y + 2:
					print("TEXT_BOUNDS: %s lines=%d height=%f font=%d box=%s" % [id, label.get_line_count(), label.get_line_height(), label.get_theme_font_size("font_size"), label.size])
				check(label != null and label.get_line_count() * label.get_line_height() <= label.size.y + 2, "screen text fits " + prefix + " " + id)
			game._cancel_management_action_mode()
			game._set_management_tool_tab("tactics")
			game._select_room("recovery")
			await settle(4)
			await capture(prefix + "_inspector")
			var inspector := game.ui_layer.find_child("ManagementContextDrawer", true, false) as Control
			if inspector != null:
				for label in inspector.find_children("*", "Label", true, false):
					if label.get_meta("uiux_keep_font_size", false):
						check(label.get_line_count() * label.get_line_height() <= label.size.y + 2 and Rect2(Vector2.ZERO, inspector.size).encloses(label.get_rect()), "inspector text fits " + prefix + " " + label.text.left(12))
			var tabs := game.ui_layer.find_child("ManagementToolTabs", true, false) as Control
			var dock := game.ui_layer.find_child("TacticsToolbox", true, false) as Control
			var footer := game.ui_layer.find_child("ManagementPrimaryBar", true, false) as Control
			check(tabs != null and dock != null and footer != null and not tabs.get_global_rect().intersects(dock.get_global_rect()) and not dock.get_global_rect().intersects(footer.get_global_rect()), "screen regions do not overlap " + prefix)
	UISettings.set_text_scale(1.0, false)
	DisplayServer.window_set_size(Vector2i(1920, 1080))

func late_stage_cases() -> void:
	GameState.gold = 100000
	GameState.mana = 100000
	GameState.food = 100000
	for stage in ["stage_01_cave", "stage_02_castle", "stage_03_keep", "stage_04_citadel"]:
		game.castle_art_stage = stage
		game._sync_castle_stage_content()
		game._refresh_quarter_map_from_rooms()
		game._set_management_tool_tab("build")
		await settle(2)
		var baseline := state()
		var target := "slot_03" if game.rooms.has("slot_03") else ("slot_02" if game.rooms.has("slot_02") else "slot_01")
		for id in game._build_facility_choices():
			if id == "build_slot":
				continue
			game._open_build_palette_for_room(target)
			game._set_build_facility(str(id))
			await settle(2)
			var preview: Dictionary = game.quarter_renderer.facility_visual(target, str(id))
			var shown: Rect2 = game.get_global_transform_with_canvas() * preview.bounds
			check(shown.end.y <= 738.0, "B09 review building is above the bottom toolbox " + stage + " " + str(id))
			await check_ghost_pixels(stage + "_" + str(id))
			check(not preview.texture_keys.is_empty(), "B11 real sprites available " + stage + " " + str(id))
			check(game._confirm_build_preview(), "B11 existing facility builds in late slot " + stage + " " + str(id))
			var live: Array = []
			for slot in game.graph.debug_object_slots():
				if str(slot.get("instance_id", "")) == target:
					live.append(slot)
			check(live == preview.objects, "B11 preview composition matches actual installed room " + stage + " " + str(id))
			var installed: Dictionary = game.quarter_renderer.facility_visual(target, str(id))
			check(installed.texture_keys == preview.texture_keys, "B11 actual stage and facing match preview " + stage + " " + str(id))
			game._undo_last_management_placement()
			await settle(2)
			check(state() == baseline, "B08 late-stage Undo restores complete supported state")
		# Demolition uses the same card and reports original zero refund contract.
		game._open_build_palette_for_room("barracks")
		game._set_build_facility("build_slot")
		await settle(2)
		check(game._confirm_build_preview(), "B10 demolition reuses existing removal rule " + stage)
		game._undo_last_management_placement()
		await settle(2)
		check(state() == baseline, "B08 demolition Undo restores units and building " + stage)
		game._open_build_palette_for_room(target)
		game._set_build_facility("watch_post")
		await settle(2)
		await capture(stage + "_review")
		game._cancel_management_action_mode()
		await settle(2)

func monster_cases() -> void:
	var before := state()
	game._set_management_tool_tab("roster")
	await settle(2)
	var card := game.ui_layer.find_child("MonsterCard_slime", true, false) as Button
	check(card != null and card.icon != null, "M01 roster still uses real monster image")
	mouse(card.get_global_rect().get_center(), true)
	motion(world(game.graph.center("recovery")))
	mouse(world(game.graph.center("recovery")), false)
	await settle(2)
	check(str(game.monster_roster.slime.room) == "recovery", "M01 actual roster drag deploys monster")
	check(game._undo_last_management_placement(), "M01 monster drag retains existing Undo")
	await settle(2)
	check(state() == before, "M01 monster Undo restores all supported state")
	game._set_management_tool_tab("roster")
	await settle(2)
	card = game.ui_layer.find_child("MonsterCard_slime", true, false) as Button
	card.grab_focus()
	key(KEY_ENTER)
	await settle(2)
	check(game.deploy_pick_monster_id == "slime" and game.dragging_monster_id == "", "M01 keyboard roster selection offers click placement without a dangling drag")
	mouse(world(game.graph.center("recovery")), true)
	mouse(world(game.graph.center("recovery")), false)
	await settle(2)
	check(str(game.monster_roster.slime.room) == "recovery", "M01 click alternative deploys monster")
	game._undo_last_management_placement()
	await settle(2)
	check(state() == before, "M01 click alternative preserves reversible placement contract")

func final_input_cases() -> void:
	var before := state()
	await drag_card("watch_post", world(game.graph.center("slot_01")))
	mouse(world(game.graph.center("slot_01")), false)
	await settle(2)
	var cancel := game.ui_layer.find_child("CancelBuildingButton", true, false) as Button
	check(cancel != null and cancel.is_visible_in_tree(), "B06 nearby review exposes actual Cancel button")
	mouse(cancel.get_global_rect().get_center(), true)
	mouse(cancel.get_global_rect().get_center(), false)
	await settle(2)
	check(not game.build_pick_mode and state() == before, "B06 Cancel button is free and clears review")
	await capture("07_cancel")
	await drag_card("watch_post", world(game.graph.center("slot_01")))
	DisplayServer.window_set_size(Vector2i(1280, 720))
	await settle(4)
	var target: Vector2 = world(game.graph.center("slot_01"))
	motion(target)
	mouse(target, false)
	await settle(2)
	check(game.build_preview_room_id == "slot_01" and state() == before, "B09 window resize during drag preserves candidate and cost")
	var confirm := game.ui_layer.find_child("ConfirmFacilityReplacementButton", true, false) as Button
	var point := confirm.get_global_rect().get_center()
	mouse(point, true)
	mouse(point, false)
	mouse(point, true)
	mouse(point, false)
	key(KEY_ENTER)
	await settle(2)
	var cost: Dictionary = game._facility_definition("watch_post").get("cost", {})
	check(GameState.gold == before.gold - int(cost.get("gold", 0)) and GameState.mana == before.mana - int(cost.get("mana", 0)), "B03 repeated GUI release and Enter charge once")
	check(game.current_screen == Constants.SCREEN_MANAGEMENT, "B03 confirmation release never starts defense")
	game._undo_last_management_placement()
	await settle(2)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	game._set_management_tool_tab("tactics")
	await settle(2)
	game._select_room("spike_corridor")
	await settle(2)
	check(game.management_context_drawer_open, "T01 selecting a room opens its directive inspector")
	for id in ["GLOBAL_DIRECTIVE_DEFEND", "ROOM_DIRECTIVE_TRAP_LURE", "ROOM_DIRECTIVE_RETREAT_LINE"]:
		var registered: Dictionary = game.tutorial_targets.get(id, {})
		check(is_instance_valid(registered.get("control")), "T01 existing tutorial target resolves live toolbox/detail Control: " + id)

	game._set_management_tool_tab("roster")
	await settle(2)
	game._begin_management_roster_drag("slime")
	key(KEY_ESCAPE)
	check(not game.roster_monster_drag_active and game.dragging_monster_id == "", "M01 roster cancel clears origin flag and pointer")
	var run_before := [game.update2_cycle_seed, game.wave_variant_ids.duplicate(), game.event_deck_order.duplicate()]
	game.combat_scene.build_precombat_snapshot(false)
	check([game.update2_cycle_seed, game.wave_variant_ids, game.event_deck_order] == run_before and state() == before, "B02 intrusion summary does not initialize campaign state")
	game.onboarding_enabled = true
	game.tutorial_gate_enabled = true
	GameState.onboarding_complete = false
	GameState.day = 1
	game._set_management_tool_tab("roster")
	await settle(2)
	for id in ["slime", "imp"]:
		var card := game.ui_layer.find_child("MonsterCard_" + id, true, false) as Button
		check(card != null and card.disabled, "M01 DAY 1 fixed monster remains disabled: " + id)
		var room_before := str(game.monster_roster[id].room)
		game._begin_management_roster_drag(id)
		check(game.dragging_monster_id == "" and str(game.monster_roster[id].room) == room_before, "M01 fixed tutorial monster cannot start drag")
		check(not game._assign_monster_to_room(id, "recovery"), "M01 fixed tutorial monster cannot bypass placement guard")
	GameState.day = 2
	GameState.onboarding_complete = true
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game._set_management_tool_tab("roster")
	await settle(2)
	check(state() == before, "M01 fixed tutorial checks preserve placement and economy")

# Compare the rendered candidate with the same frame with just the ghost hidden.
# Visibility flags and matching texture IDs missed the zero-sized Control bug.
func check_ghost_pixels(id: String) -> void:
	var ghost: Control = game.build_placement.ghost
	var was_processing := ghost.is_processing()
	ghost.set_process(false)
	await settle(2)
	var shown := get_viewport().get_texture().get_image()
	var rect: Rect2 = ghost.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, ghost.size)
	var ratio := Vector2(shown.get_size()) / get_viewport().get_visible_rect().size
	var sample := Rect2i(rect.position * ratio, rect.size * ratio).intersection(Rect2i(Vector2i.ZERO, shown.get_size()))
	ghost.visible = false
	await settle(2)
	var hidden := get_viewport().get_texture().get_image()
	var changed := 0
	for y in range(sample.position.y, sample.end.y, 2):
		for x in range(sample.position.x, sample.end.x, 2):
			var a := shown.get_pixel(x,y)
			var b := hidden.get_pixel(x,y)
			if absf(a.r-b.r) + absf(a.g-b.g) + absf(a.b-b.b) > 0.16:
				changed += 1
	ghost.visible = true
	ghost.set_process(was_processing)
	await settle(2)
	print("GHOST_PIXEL_EVIDENCE %s changed=%d bounds=%s" % [id,changed,sample])
	check(changed > 100, "B01 real ghost changes visible building pixels " + id)
