extends Node
const Game = preload("res://scenes/game/GameRoot.tscn")
const C = preload("res://scripts/core/Constants.gd")
const Model = preload("res://scripts/v122/ui/V122CombatResultViewModel.gd")
var game
var count := 0
var failed := false
var captures: Array[String] = []
func _ready() -> void:
	call_deferred("_run")
func settle(n: int = 4) -> void:
	for i in range(n):
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
func expect(ok: bool, label: String) -> void:
	count += 1
	if not ok:
		failed = true
		push_error("UIUX_U4_ASSERT_FAIL: " + label)
func node(id: String) -> Node:
	return game.ui_layer.find_child(id, true, false)
func click(control: Control) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.position = control.get_global_rect().get_center()
	event.global_position = event.position
	get_viewport().push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	event.button_mask = 0
	get_viewport().push_input(event, true)
	await settle()
func key(code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	get_viewport().push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	get_viewport().push_input(event, true)
	await settle()
func capture(id: String) -> void:
	await settle()
	var path := "res://tmp/uiux_u4_u5/interaction/" + id + ".png"
	expect(get_viewport().get_texture().get_image().save_png(path) == OK, id + " capture saved")
	captures.append(path)
func check_copy(parent: Node) -> void:
	if parent is Label and parent.has_meta("uiux_keep_font_size"):
		var font: Font = parent.get_theme_font("font")
		var height := font.get_height(parent.get_theme_font_size("font_size"))
		expect(parent.get_line_count() * height <= parent.size.y + 2, "%s fits %d lines in %.0f" % [str(parent.name), parent.get_line_count(), parent.size.y])
	for child in parent.get_children():
		check_copy(child)
func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://tmp/uiux_u4_u5/interaction")
	game = Game.instantiate()
	add_child(game)
	await settle()
	game.campaign_save_enabled = false
	game._debug_skip_onboarding()
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	GameState.day = 2
	game._choose_early_specialization("goblin", "goblin_treasure_hunter")
	var blank := Model.build_result({"win":false},{})
	expect(blank.primary_cause_id == "record_unavailable", "missing defeat record never invents a cause")
	var management := Model.build_result({"management_only":true,"win":true},{},{"rewards":{"gold":999}})
	expect(management.rewards.is_empty(), "management settlement excludes prior battle rewards")
	var outpost := Model.build_result({"outpost_battle":true,"win":true,"rewards":{"gold":17}},{},{"rewards":{"gold":999}})
	expect(outpost.rewards == {"gold":17}, "outpost settlement uses that encounter's actual rewards")
	var disabled := Model.build_result({"win":false,"metrics":{"facility_disables":2}}, {})
	expect(disabled.conditional_alerts[0].value == "2회", "facility disables report events rather than invented distinct rooms")
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		for text_scale in [0.9,1.0,1.15]:
			UISettings.text_scale = text_scale
			var tag := "%dx%d_%d" % [resolution.x,resolution.y,roundi(text_scale*100)]
			game.selected_monster_id = "goblin"
			game.monster_roster["goblin"]["level"] = 1
			game.monster_roster["goblin"]["exp"] = 40
			game.monster_roster["goblin"]["training_count_today"] = 0
			game.monster_roster["goblin"]["training_day"] = 2
			GameState.gold = 300
			game._set_screen(C.SCREEN_MONSTER)
			await settle()
			check_copy(game.ui_layer)
			var before_roster: Dictionary = game.monster_roster.duplicate(true)
			game._set_screen(C.SCREEN_MONSTER)
			await settle()
			expect(game.monster_roster == before_roster and GameState.gold == 300, tag + " training preview is read-only")
			var preview: Dictionary = game._scaled_monster_stats("goblin", 2)
			await capture(tag + "_monster")
			await click(node("MonsterTrainingButton"))
			expect(GameState.gold == 270 and game.monster_roster.goblin.level == 2 and game.monster_roster.goblin.exp == 10, tag + " training click pays once and applies actual exp")
			expect(game._scaled_monster_stats("goblin") == preview, tag + " training result equals preview stats")
			# Include an existing fourth owned monster after the previously truncated third row.
			if not game.monster_roster.has("kobold_scout"):
				game.monster_roster["kobold_scout"] = {"level":1,"exp":0,"bond":0,"room":"barracks"}
			game.result_summary = {"win":true,"metrics":{"alive_monsters":4,"total_monsters":4},"v122_ledger":{"throne_damage":0,"events":[]}}
			game.rewards_pending = {"gold":60}
			game.result_growth_choice_applied = false
			game.result_growth_reviewed = false
			game.result_growth_choice_monster_id = ""
			game.last_growth_summary.clear()
			for id in ["slime","goblin","imp","kobold_scout"]:
				var r: Dictionary = game.monster_roster[id]
				game.last_growth_summary.append({"monster_id":id,"display_name":game._monster_display_name(id),"level_before":r.level,"level_after":r.level,"exp_gain":10,"exp_after":r.exp,"next_exp":game._monster_exp_to_next(r.level)})
			game._set_screen(C.SCREEN_RESULT)
			await settle()
			check_copy(game.ui_layer)
			var fourth := node("GrowthChoice_kobold_scout") as Button
			expect(fourth != null, tag + " fourth growth candidate exists")
			var exp_before: int = game.monster_roster.kobold_scout.exp
			fourth.grab_focus()
			await settle()
			var scroll := node("ResultGrowthScroll") as ScrollContainer
			expect(scroll.get_global_rect().encloses(fourth.get_global_rect()), tag + " keyboard focus scrolls fourth candidate into view")
			await capture(tag + "_fourth_growth")
			await key(KEY_ENTER)
			expect(game.result_growth_choice_monster_id == "kobold_scout" and game.monster_roster.kobold_scout.exp == exp_before + game._result_growth_choice_bonus(), tag + " keyboard growth choice applies once")
			var paid_exp: int = game.monster_roster.kobold_scout.exp
			game._choose_result_growth("kobold_scout")
			expect(game.monster_roster.kobold_scout.exp == paid_exp and GameState.gold == 270, tag + " repeated choice / UI rebuild gives no extra exp or rewards")
			expect("선택 후" not in str(node("GrowthChoicePreview_kobold_scout").text), tag + " completed choice shows actual exp")
			await capture(tag + "_growth_chosen")
			# Clicking an old result button after a screen change is ignored.
			game._set_screen(C.SCREEN_MANAGEMENT)
			var old_day: int = GameState.day
			game._continue_from_result()
			game._edit_placement_from_result()
			game._retry_same_placement_from_result()
			expect(GameState.day == old_day and game.current_screen == C.SCREEN_MANAGEMENT, tag + " stale result callbacks cannot advance or retry")
			game._set_screen(C.SCREEN_MONSTER)
			game._open_settings_screen()
			UISettings.text_scale = 0.9 if text_scale != 0.9 else 1.0
			game._cancel_settings_changes()
			expect(is_equal_approx(UISettings.text_scale, text_scale) and game.current_screen == C.SCREEN_MONSTER, tag + " settings cancel restores text scale and source screen")
	game.queue_free()
	await settle(3)
	var file := FileAccess.open("res://tmp/uiux_u4_u5/interaction/results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"assertions":count,"failed":failed,"captures":captures},"\t"))
	file.close()
	print("UIUX_U4_INTERACTION_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS",count])
	get_tree().quit(1 if failed else 0)
