extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const CampaignSaveStoreScript = preload("res://scripts/core/CampaignSaveStore.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const TEST_SAVE_PATH := "user://mobile_touch_ui_smoke_save.json"

var failed := false

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	CampaignSaveStoreScript.delete(TEST_SAVE_PATH)
	_expect(UISettings.is_touch_ui(), "mobile argument enables the touch layout")
	var game = GameRootScene.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame
	game._set_campaign_save_path_for_tests(TEST_SAVE_PATH)

	var new_game_button = _find_button_by_text(game.ui_layer, "새 게임")
	_expect(new_game_button != null and new_game_button.size.y >= 120.0, "title exposes a large new-game touch target")
	_expect(new_game_button != null and new_game_button.get_theme_font_size("font_size") >= 40, "title button uses a readable mobile font")
	var title_subtitle = _find_label_by_text(game.ui_layer, "F급 신입 마왕성 방어 튜토리얼")
	_expect(title_subtitle != null and title_subtitle.get_theme_font_size("font_size") >= 40, "mobile body text receives the larger readability scale")
	game._onboarding_start_new_game()
	await get_tree().process_frame
	var name_tip_button = _find_button_by_text(game.ui_layer, "확인하고 이름 선택")
	_expect(name_tip_button != null and name_tip_button.size.y >= 120.0, "name guidance uses a large confirmation target")
	game._onboarding_dismiss_name_entry_tip()
	await get_tree().process_frame
	_expect(game.onboarding_name_input != null and game.onboarding_name_input.size.y >= 120.0, "name input is large enough for touch")
	_expect(not game.onboarding_name_input.has_focus(), "name screen does not reopen the mobile keyboard automatically")
	var random_name_button = _find_button_by_text(game.ui_layer, "무작위 이름")
	_expect(random_name_button != null and random_name_button.size.y >= 120.0, "name screen provides a keyboard-free random-name choice")
	game.onboarding_name_input.grab_focus()
	game.onboarding_name_input.text = "모바일마왕"
	game._onboarding_confirm_name()
	_expect(not game.onboarding_name_input.has_focus(), "confirming a name releases keyboard focus")
	await get_tree().process_frame
	await _drain_dialogue(game)
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "opening reaches the management screen")
	_expect(game.selected_monster_id == "slime", "tutorial preselects the required monster instead of keeping a stale choice")
	var first_touch_instruction: String = game._onboarding_line_text(game.tutorial_manager.current_step())
	_expect(first_touch_instruction.contains("탭") and not first_touch_instruction.contains("클릭"), "mobile tutorial consistently uses touch wording")
	var directive_bar = game.ui_layer.find_child("MobileManagementDirectiveBar", true, false) as Panel
	_expect(directive_bar != null, "management uses the mobile quick-directive bar")
	var defense_button = _find_button_by_text(directive_bar, "사수") if directive_bar != null else null
	_expect(defense_button != null and defense_button.size.y >= 120.0, "management directives are large one-tap buttons")

	var slime_step: Dictionary = game.tutorial_manager.current_step()
	var slime_focus: Rect2 = game._tutorial_focus_rect(game._tutorial_effective_focus_id(slime_step))
	var slime_badge: Dictionary = game._tutorial_click_badge_placement(slime_focus, game._tutorial_message_rect(slime_focus))
	var slime_badge_rect: Rect2 = slime_badge.get("rect", Rect2())
	_expect(game._handle_mobile_tutorial_focus_tap(slime_badge_rect.get_center()), "tutorial tap badge activates its highlighted target")
	_expect(game.selected_monster_id == "slime", "tutorial badge selects the intended slime")
	await _drain_dialogue(game)
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "tutorial touch returns to the next required controls automatically")
	game._set_global_directive(Constants.DIRECTIVE_DEFENSE)
	await _drain_dialogue(game)
	game._start_combat()
	await get_tree().physics_frame
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "tutorial reaches combat with touch controls")
	var combat_bar = game.ui_layer.find_child("MobileCombatBar", true, false) as Panel
	_expect(combat_bar != null, "combat uses the dedicated mobile action bar")
	var direct_button = _find_button_by_text(combat_bar, "직접 조종") if combat_bar != null else null
	_expect(direct_button == null, "mobile combat removes single-unit direct controls")
	var focus_button = _find_button_by_text(combat_bar, "입구 봉쇄") if combat_bar != null else null
	var speed_button = _find_button_by_text(combat_bar, "x3") if combat_bar != null else null
	_expect(focus_button != null and focus_button.size.y >= 110.0, "room directives remain large one-tap controls")
	_expect(speed_button != null and speed_button.size.y >= 120.0 and speed_button.disabled, "mobile tutorial exposes x3 as a large locked control")
	if speed_button != null:
		speed_button.pressed.emit()
	_expect(is_equal_approx(game.combat_speed, 1.0), "mobile tutorial cannot accelerate before completion")
	var enemy = _first_alive_enemy(game)
	if enemy == null:
		game._spawn_enemy("explorer")
		await get_tree().physics_frame
		enemy = _first_alive_enemy(game)
	if enemy != null:
		game._handle_touch_combat_tap(enemy.global_position, Vector2(-99999, -99999))
		_expect(game.selected_unit == enemy, "tapping an enemy selects information without issuing a unit command")
		_expect(not enemy.has_method("command_attack") and not enemy.has_method("command_move"), "units no longer expose direct attack or movement commands")
	else:
		_expect(false, "combat creates an enemy for touch targeting")
	GameState.onboarding_complete = true
	game.tutorial_gate_enabled = false
	game.combat_speed_intro_seen = false
	game._set_screen(Constants.SCREEN_COMBAT)
	await get_tree().process_frame
	var speed_intro = game.ui_layer.get_node_or_null("CombatSpeedFeatureIntro")
	_expect(speed_intro != null and game.combat_speed_intro_open and game.combat_paused, "mobile first regular combat introduces acceleration while paused")
	combat_bar = game.ui_layer.find_child("MobileCombatBar", true, false) as Panel
	speed_button = _find_button_by_text(combat_bar, "x3") if combat_bar != null else null
	_expect(speed_button != null and not speed_button.disabled, "mobile x3 unlocks with the introduction")
	game._dismiss_combat_speed_intro()
	if speed_button != null:
		speed_button.pressed.emit()
	_expect(game.combat_speed_intro_seen and is_equal_approx(game.combat_speed, 3.0), "mobile introduction confirmation enables x3")

	CampaignSaveStoreScript.delete(TEST_SAVE_PATH)
	game.queue_free()
	await get_tree().process_frame
	if failed:
		print("MOBILE_TOUCH_UI_SMOKE_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("MOBILE_TOUCH_UI_SMOKE_TEST: PASS")
		get_tree().quit(0)

func _drain_dialogue(max_steps_game: Node, max_steps: int = 120) -> void:
	var quiet_frames := 0
	for _index in range(max_steps):
		await get_tree().process_frame
		if max_steps_game.current_screen == Constants.SCREEN_DIALOGUE:
			quiet_frames = 0
			max_steps_game._onboarding_advance_dialogue()
		else:
			quiet_frames += 1
			if quiet_frames >= 3:
				return
	failed = true
	push_error("Timed out while draining dialogue")

func _find_button_by_text(node: Node, text: String) -> Button:
	if node is Button and node.text == text:
		return node
	for child in node.get_children():
		var result = _find_button_by_text(child, text)
		if result != null:
			return result
	return null

func _find_label_by_text(node: Node, text: String) -> Label:
	if node is Label and node.text == text:
		return node
	for child in node.get_children():
		var result = _find_label_by_text(child, text)
		if result != null:
			return result
	return null

func _first_alive_enemy(game: Node) -> Node:
	for enemy in game.enemy_units:
		if enemy.is_alive():
			return enemy
	return null

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		push_error("FAIL: %s" % message)
		failed = true
