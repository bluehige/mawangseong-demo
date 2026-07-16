extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var failed := false

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var quick_game = GameRootScene.instantiate()
	add_child(quick_game)
	await get_tree().process_frame
	await get_tree().physics_frame
	var quick_start_button = _find_button_by_text(quick_game.ui_layer, "빠른 시작")
	_expect(quick_start_button != null, "title exposes quick start")
	if quick_start_button != null:
		quick_start_button.pressed.emit()
	await get_tree().process_frame
	_expect(quick_game.current_screen == Constants.SCREEN_MANAGEMENT, "quick start enters DAY 01 management immediately")
	_expect(GameState.player_name == "신입 마왕", "quick start assigns a default player name")
	_expect(quick_game.tutorial_manager.current_step_id() == "TUT_030_SELECT_SLIME", "quick start preserves the required gameplay tutorial")
	_expect(quick_game.onboarding_dialogue_queue.is_empty(), "quick start does not queue opening dialogue")
	_expect(quick_game.first_play_observation.active and quick_game.first_play_observation.session_mode == "quick", "quick start begins a first-play observation session")
	_expect(quick_game.update2_cycle_seed > 0, "quick start initializes a valid campaign seed before autosave")
	_expect(quick_game.campaign_save_notice == "", "quick start completes the initial autosave without a warning overlay")
	await get_tree().process_frame
	_expect_tutorial_click_guidance(quick_game, "quick-start slime selection")
	quick_game.queue_free()
	await get_tree().process_frame

	var game = GameRootScene.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame

	game._onboarding_start_new_game()
	await get_tree().process_frame
	_expect(game.first_play_observation.active and game.first_play_observation.session_mode == "new", "new game begins a first-play observation session")
	_expect(game.global_directive == Constants.DIRECTIVE_ALL_OUT, "new onboarding starts with a directive that must change to defense")
	game.onboarding_name_input.text = "튜토리얼마왕"
	game._onboarding_confirm_name()
	_expect(game.onboarding_dialogue_queue.size() == 4, "new game keeps only four essential opening lines")
	var opening_line_ids: Array = []
	for entry in game.onboarding_dialogue_queue:
		opening_line_ids.append(str(entry.get("id", "")))
	_expect(opening_line_ids == ["D_OP_PLAYER_001", "D_OP_BATI_001", "D_OP_BATI_002", "D_OP_BATI_003"], "essential opening lines keep their intended order")
	await _drain_dialogue(game)
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "opening reaches management with tutorial gate on")
	_expect(game.tutorial_manager.current_step_id() == "TUT_030_SELECT_SLIME", "first management step asks for slime selection")
	_expect(game.onboarding_seen_dialogue_ids.has("D01_PRE_BATI_001"), "DAY 01 keeps one immediate management intro")
	_expect(not game.onboarding_seen_dialogue_ids.has("D01_PRE_PLAYER_001") and not game.onboarding_seen_dialogue_ids.has("D01_PRE_BATI_002"), "DAY 01 defers optional management banter")
	_expect_tutorial_click_guidance(game, "new-game slime selection")

	game._start_combat()
	await get_tree().process_frame
	_expect(game.current_screen != Constants.SCREEN_COMBAT, "combat start is blocked before required management tutorial steps")
	_expect(game.first_play_observation.total_blocked_attempts() == 1, "first-play observation records an early blocked combat attempt")
	_expect(not game.first_play_observation.last_written_paths.is_empty(), "a blocked attempt creates an immediate observation checkpoint")

	game._select_monster("slime")
	await _drain_dialogue(game)
	_expect(game.current_screen == Constants.SCREEN_MONSTER, "slime introduction stays nonblocking")
	_expect(game.tutorial_manager.current_step_id() == "TUT_050_GLOBAL_DEFEND", "already deployed slime skips the redundant deployment step")
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await get_tree().process_frame
	_expect_tutorial_click_guidance(game, "global defense button")

	game.first_play_observation.current_step_started_msec -= 21000
	game._set_global_directive(Constants.DIRECTIVE_ALL_OUT)
	await get_tree().process_frame
	_expect(game.tutorial_manager.current_step_id() == "TUT_050_GLOBAL_DEFEND", "an exploratory wrong directive does not advance the required step")
	game._set_global_directive(Constants.DIRECTIVE_DEFENSE)
	await _drain_dialogue(game)
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "global directive feedback stays nonblocking")
	_expect(game.tutorial_manager.current_step_id() == "TUT_090_RESULT_GROWTH", "defense directive completes the simplified DAY 01 controls tutorial")
	var directive_choice: Dictionary = game.first_play_observation.choice_for(1, "global_directive")
	_expect(str(directive_choice.get("first_value", "")) == Constants.DIRECTIVE_ALL_OUT and str(directive_choice.get("latest_value", "")) == Constants.DIRECTIVE_DEFENSE, "first-play observation keeps the first and corrected directive choices")
	_expect(int(directive_choice.get("attempts", 0)) == 2 and int(directive_choice.get("changes", 0)) == 1, "first-play observation counts directive retries")
	_expect(game.first_play_observation.long_wait_count() >= 1, "first-play observation marks a tutorial step that took at least 20 seconds")
	game._start_combat()
	await get_tree().physics_frame
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "combat starts after the three essential DAY 01 management actions")
	_expect(game.ui_layer.find_child("DirectControlButton", true, false) == null, "combat exposes directives without single-unit direct controls")
	var tutorial_speed_button := _find_button_by_text(game.ui_layer, "x3")
	_expect(tutorial_speed_button != null and tutorial_speed_button.disabled and not game._combat_speed_unlocked(), "combat acceleration stays locked until the tutorial is complete")
	game._set_speed(3.0)
	_expect(is_equal_approx(game.combat_speed, 1.0), "tutorial speed request cannot bypass the x1 lock")
	await _finish_current_battle(game)
	var locked_next_button = _find_button_by_text(game.ui_layer, "성장 확인 필요")
	_expect(locked_next_button != null and locked_next_button.disabled, "DAY 01 result disables next-day button until growth review")
	_expect(game._tutorial_effective_focus_id(game.tutorial_manager.current_step()) == "GrowthChoice_slime", "growth tutorial first points at an enabled focus-growth choice")
	_expect_tutorial_click_guidance(game, "focus-growth choice")
	game._continue_from_result()
	await get_tree().process_frame
	_expect(GameState.day == 1 and game.current_screen == Constants.SCREEN_RESULT, "DAY 01 result is blocked until growth review")
	var locked_growth_button = _find_button_by_text(game.ui_layer, "성장 선택 필요")
	_expect(locked_growth_button != null and locked_growth_button.disabled, "DAY 01 result requires a focused growth choice before review")
	var focus_button = _find_button_by_text(game.ui_layer, "집중 +8")
	_expect(focus_button != null and not focus_button.disabled, "DAY 01 result exposes focused growth choice")
	_expect(game._choose_result_growth("slime"), "DAY 01 focused growth choice applies")
	_expect(str(game.first_play_observation.choice_for(1, "growth_focus").get("first_value", "")) == "slime", "first-play observation records the focused growth target")
	await get_tree().process_frame
	_expect(game._tutorial_effective_focus_id(game.tutorial_manager.current_step()) == "GrowthReviewButton", "growth tutorial points at growth review after choosing a focus")
	_expect_tutorial_click_guidance(game, "growth review button")
	game._review_growth_from_result()
	await get_tree().process_frame
	_expect(game.tutorial_manager.current_step_id() == "TUT_110_TRAP_CORRIDOR", "growth review advances to the DAY 02 trap-corridor step")
	game._continue_from_result()
	await _drain_dialogue(game)
	_expect(GameState.day == 2 and game.current_screen == Constants.SCREEN_MANAGEMENT, "DAY 01 result advances to DAY 02 management")

	game._start_combat()
	await get_tree().process_frame
	_expect(game.current_screen != Constants.SCREEN_COMBAT, "DAY 02 combat is blocked before treasure tutorial")
	game._set_build_facility("watch_post")
	_expect(str(game.first_play_observation.choice_for(2, "facility").get("first_value", "")) == "watch_post", "first-play observation records the first facility choice")
	game._clear_management_action_mode(false)
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	game._select_room("spike_corridor")
	await get_tree().process_frame
	_expect(game.tutorial_manager.current_step_id() == "TUT_120_TRAP_LURE", "spike corridor selection completes DAY 02 room step")
	_expect_registered_tutorial_target(game, "ROOM_DIRECTIVE_TRAP_LURE", "trap lure directive")
	game._select_room("treasure")
	await get_tree().process_frame
	_expect(game.selected_room == "spike_corridor", "trap lure tutorial keeps the required room selected after exploratory room clicks")
	_expect_registered_tutorial_target(game, "ROOM_DIRECTIVE_TRAP_LURE", "trap lure directive after exploratory room click")
	_expect_no_stale_target_fallback(game, "ROOM_DIRECTIVE_TRAP_LURE", "trap lure directive")
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await get_tree().process_frame
	_expect_registered_tutorial_target(game, "ROOM_DIRECTIVE_TRAP_LURE", "restored trap lure directive")
	game._set_room_directive(Constants.ROOM_DIRECTIVE_TRAP_LURE)
	await _drain_dialogue(game)
	_expect(game.tutorial_manager.current_step_id() == "TUT_130_GOBLIN_CONTROL", "trap lure directive unlocks DAY 02 combat step")
	game._start_combat()
	await get_tree().process_frame
	_expect(game.current_screen == Constants.SCREEN_MONSTER, "DAY 02 combat requests the first tactical specialization")
	_expect(game._choose_early_specialization("goblin", "goblin_treasure_hunter"), "DAY 02 tutorial chooses goblin tactical specialization")
	_expect(str(game.first_play_observation.choice_for(2, "specialization").get("first_value", "")) == "goblin_treasure_hunter", "first-play observation records the first tactical specialization")
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	game._start_combat()
	await get_tree().physics_frame
	var goblin = _unit_by_id(game.monster_units, "goblin")
	game._spawn_enemy("thief")
	var thief = _unit_by_id(game.enemy_units, "thief")
	_expect(goblin != null and thief != null, "DAY 02 creates goblin and thief for the chase tutorial")
	if goblin != null and thief != null:
		goblin.global_position = game.graph.center("barracks")
		goblin.current_room = "barracks"
		goblin.stop_navigation()
		thief.global_position = game.graph.center("entrance")
		thief.current_room = "entrance"
		thief.stop_navigation()
		game.combat_scene.update_ai_paths()
		_expect(not goblin.has_method("command_attack") and game.global_directive == Constants.DIRECTIVE_DEFENSE, "goblin follows the current defense directive without a direct attack command")
		thief.global_position = goblin.global_position + Vector2(20, 0)
		thief.current_room = "barracks"
		goblin.attack_cooldown = 0.0
		game.combat_scene.update_attacks(0.0)
	await get_tree().process_frame
	_expect(game.tutorial_manager.current_step_id() == "TUT_210_RECOVERY_NEST", "a real goblin attack completes the DAY 02 combat step")
	await _finish_current_battle(game)
	game._continue_from_result()
	await _drain_dialogue(game)
	_expect(GameState.day == 3 and game.current_screen == Constants.SCREEN_MANAGEMENT, "DAY 02 result advances to DAY 03 management")

	game._select_room("recovery")
	await get_tree().process_frame
	_expect(game.tutorial_manager.current_step_id() == "TUT_220_RETREAT_LINE", "recovery nest selection completes DAY 03 room step")
	game._set_room_directive(Constants.ROOM_DIRECTIVE_RETREAT)
	await _drain_dialogue(game)
	_expect(game.tutorial_manager.current_step_id() == "TUT_230_IMP_FIREBALL", "retreat directive unlocks imp fireball step")
	game._start_combat()
	await get_tree().physics_frame
	var imp = _unit_by_id(game.monster_units, "imp")
	if imp != null:
		game._select_unit(imp)
	game._spawn_enemy("trainee_hero")
	if imp != null and not game.enemy_units.is_empty():
		var fireball_target = game.enemy_units[game.enemy_units.size() - 1]
		fireball_target.global_position = imp.global_position + Vector2(24, 0)
		fireball_target.current_room = imp.current_room
		fireball_target.set_physics_process(false)
		imp.skill_cooldowns["fireball"] = 0.0
		GameState.mana = maxi(GameState.mana, 100)
		_expect(game.combat_scene.try_auto_monster_skill(imp), "imp AI automatically casts an available fireball")
	await _drain_dialogue(game)
	_expect(game.tutorial_manager.current_step_id() == "TUT_240_BOSS_HP", "automatic imp fireball completes the DAY 03 observation step")
	game._tutorial_emit_action("boss_hp_50", {"hp_ratio": 0.5})
	await get_tree().process_frame
	_expect(game.tutorial_manager.current_step_id() == "TUT_310_RAID_PREVIEW", "boss HP threshold advances to raid preview step")
	await _finish_current_battle(game)
	game._continue_from_result()
	await _drain_dialogue(game)
	_expect(GameState.day == 4 and game.current_screen == Constants.SCREEN_RAID_PREVIEW, "DAY 03 result advances to DAY 04 preview")
	_expect(not game.tutorial_manager.active, "raid preview dialogue closes final tutorial step")
	_expect(not game.first_play_observation.active, "first-play observation stops after the DAY 1~3 route")
	_verify_observation_report(game)

	game.queue_free()
	await get_tree().process_frame
	if failed:
		print("TUTORIAL_FLOW_SMOKE_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("TUTORIAL_FLOW_SMOKE_TEST: PASS")
		get_tree().quit(0)

func _drain_dialogue(game: Node, max_steps: int = 160) -> void:
	var quiet_frames := 0
	for _i in range(max_steps):
		await get_tree().process_frame
		if game.current_screen == Constants.SCREEN_DIALOGUE:
			quiet_frames = 0
			game._onboarding_advance_dialogue()
		else:
			quiet_frames += 1
			if quiet_frames >= 3:
				return
	push_error("Timed out while draining dialogue")
	failed = true

func _finish_current_battle(game: Node) -> void:
	game.wave_manager.next_index = game.wave_manager.schedule.size()
	for entry in game.wave_manager.schedule:
		game._spawn_enemy(str(entry.get("enemy_id", "explorer")))
	for enemy in game.enemy_units:
		if enemy.is_alive():
			enemy.receive_damage(9999)
	game._check_combat_end()
	await _drain_dialogue(game)
	_expect(game.current_screen == Constants.SCREEN_RESULT, "battle result screen reached")

func _unit_by_id(units: Array, unit_id: String) -> Node:
	for unit in units:
		if unit.unit_id == unit_id:
			return unit
	return null

func _first_alive_enemy(game: Node) -> Node:
	for unit in game.enemy_units:
		if unit.is_alive():
			return unit
	return null

func _find_button_by_text(node: Node, text: String) -> Button:
	if node is Button and node.text == text:
		return node
	for child in node.get_children():
		var result = _find_button_by_text(child, text)
		if result != null:
			return result
	return null

func _expect_tutorial_click_guidance(game: Node, label: String) -> void:
	var overlay = game.ui_layer.find_child("TutorialOverlay", true, false)
	_expect(overlay != null, "%s creates a tutorial overlay" % label)
	if overlay == null:
		return
	var outer = overlay.find_child("TutorialFocusOuter", true, false) as Panel
	var ring = overlay.find_child("TutorialFocusRing", true, false) as Panel
	var badge = overlay.find_child("TutorialClickBadge", true, false) as Panel
	var click_label = overlay.find_child("TutorialClickLabel", true, false) as Label
	var message = overlay.find_child("TutorialMessagePanel", true, false) as Panel
	_expect(outer != null and ring != null, "%s uses a double high-contrast target ring" % label)
	_expect(badge != null and badge.size.x >= 300.0 and badge.size.y >= 64.0, "%s uses a large click badge" % label)
	_expect(click_label != null and click_label.text.contains("클릭") and click_label.get_theme_font_size("font_size") >= 21, "%s names the click action in large text" % label)
	_expect(message != null and badge != null and not badge.get_global_rect().intersects(message.get_global_rect()), "%s keeps the click badge clear of the task card" % label)
	var shade_count := 0
	for child in overlay.get_children():
		if child.name.begins_with("TutorialSpotlightShade"):
			shade_count += 1
	_expect(shade_count >= 3, "%s darkens the non-target area" % label)
	if outer != null:
		var outer_style = outer.get_theme_stylebox("panel") as StyleBoxFlat
		_expect(outer_style != null and outer_style.border_width_top >= 6, "%s target ring is at least six pixels thick" % label)

func _expect_registered_tutorial_target(game: Node, target_id: String, label: String) -> void:
	_expect(game.tutorial_targets.has(target_id), "%s registers its live control as the tutorial target" % label)
	if not game.tutorial_targets.has(target_id):
		return
	var live_control = game.ui_layer.find_child("SelectedRoomDirectiveOption", true, false) as OptionButton
	_expect(live_control != null, "%s live directive control exists" % label)
	if live_control == null:
		return
	var has_target_value := false
	for index in range(live_control.item_count):
		if str(live_control.get_item_metadata(index)) == Constants.ROOM_DIRECTIVE_TRAP_LURE:
			has_target_value = true
			break
	_expect(has_target_value, "%s live control exposes the trap lure action" % label)
	var overlay = game.ui_layer.find_child("TutorialOverlay", true, false)
	var outer = overlay.find_child("TutorialFocusOuter", true, false) as Panel if overlay != null else null
	var badge = overlay.find_child("TutorialClickBadge", true, false) as Panel if overlay != null else null
	var target_rect: Rect2 = game.tutorial_targets[target_id]
	var live_rect := live_control.get_global_rect()
	_expect(target_rect.is_equal_approx(live_rect), "%s registered rect exactly matches the live control" % label)
	_expect(game._tutorial_focus_rect(target_id).is_equal_approx(live_rect.grow(8.0)), "%s focus rect derives from the live control" % label)
	_expect(outer != null and outer.get_global_rect().encloses(target_rect), "%s ring encloses the live control" % label)
	_expect(badge != null and not badge.get_global_rect().intersects(target_rect), "%s badge stays clear of the live control" % label)

func _expect_no_stale_target_fallback(game: Node, target_id: String, label: String) -> void:
	game.tutorial_targets.erase(target_id)
	_expect(not game._tutorial_focus_rect(target_id).has_area(), "%s has no stale coordinate fallback" % label)

func _verify_observation_report(game: Node) -> void:
	var paths: Dictionary = game.first_play_observation.last_written_paths
	var json_path := str(paths.get("dev_json", paths.get("json", "")))
	var markdown_path := str(paths.get("dev_markdown", paths.get("markdown", "")))
	var session_json_path := str(paths.get("dev_session_json", paths.get("session_json", "")))
	_expect(json_path != "" and FileAccess.file_exists(json_path), "first-play observation writes a JSON report")
	_expect(markdown_path != "" and FileAccess.file_exists(markdown_path), "first-play observation writes a Korean Markdown report")
	_expect(session_json_path != "" and FileAccess.file_exists(session_json_path) and session_json_path != json_path, "first-play observation preserves a separate file for each session")
	if json_path == "" or not FileAccess.file_exists(json_path):
		return
	var json_text := FileAccess.get_file_as_string(json_path)
	var parsed = JSON.parse_string(json_text)
	_expect(parsed is Dictionary, "first-play observation JSON can be parsed")
	if not parsed is Dictionary:
		return
	var report: Dictionary = parsed
	var summary: Dictionary = report.get("summary", {})
	_expect(str(report.get("session_id", "")).begins_with("session_"), "first-play report includes a reusable session identifier")
	_expect(bool(report.get("completed", false)), "first-play observation marks the DAY 1~3 route complete")
	_expect(int(summary.get("blocked_attempt_count", 0)) >= 2, "first-play report preserves blocked attempts from multiple days")
	_expect(int(summary.get("long_wait_count", 0)) >= 1, "first-play report preserves long-wait observations")
	_expect(str(report.get("privacy", "")).contains("플레이어 이름"), "first-play report states its privacy boundary")
	_expect(not json_text.contains("튜토리얼마왕"), "first-play JSON excludes the entered player name")
	if markdown_path != "" and FileAccess.file_exists(markdown_path):
		var markdown_text := FileAccess.get_file_as_string(markdown_path)
		_expect(markdown_text.contains("# 첫 플레이 관찰 기록") and markdown_text.contains("처음 고른 선택과 재시도"), "first-play Markdown includes Korean observation sections")
		_expect(not markdown_text.contains("튜토리얼마왕"), "first-play Markdown excludes the entered player name")

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		push_error("FAIL: %s" % message)
		failed = true
