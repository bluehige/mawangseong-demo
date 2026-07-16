extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const CampaignSaveStoreScript = preload("res://scripts/core/CampaignSaveStore.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const TEST_SAVE_PATH := "user://onboarding_day4_to_day5_save.json"

var failed := false

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	CampaignSaveStoreScript.delete(TEST_SAVE_PATH)
	var game = GameRootScene.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame
	game._set_campaign_save_path_for_tests(TEST_SAVE_PATH)
	game.tutorial_gate_enabled = false

	_expect(game.current_screen == Constants.SCREEN_TITLE, "game boots into onboarding title")
	_expect(game.onboarding_flow.loaded, "onboarding JSON loads")

	game._onboarding_start_new_game()
	game.tutorial_gate_enabled = false
	await get_tree().process_frame
	_expect(game.current_screen == Constants.SCREEN_NAME_ENTRY, "new game opens name entry")
	_expect(game.onboarding_name_input != null, "name entry creates LineEdit")
	_expect(not game.onboarding_name_entry_tip_dismissed, "name entry starts with dismissible tip")
	_expect(not game.onboarding_name_input.visible, "name input is hidden behind the tip")
	var original_name_input: LineEdit = game.onboarding_name_input
	game._onboarding_dismiss_name_entry_tip()
	await get_tree().process_frame
	_expect(game.onboarding_name_entry_tip_dismissed, "name tip dismisses on click")
	_expect(game.onboarding_name_input.visible and game.onboarding_name_input.editable, "name input appears after tip")
	_expect(game.onboarding_name_input == original_name_input, "name tip dismissal preserves the LineEdit for IME composition")
	_expect(game.onboarding_name_input.max_length == 0, "name length is validated after IME text is committed")
	_expect(game._text_input_owns_keyboard(), "focused name input owns keyboard events")

	game.onboarding_name_input.text = "가나다라마바사아자차카타파"
	game._onboarding_confirm_name()
	await get_tree().process_frame
	_expect(game.current_screen == Constants.SCREEN_NAME_ENTRY, "overlong committed Korean name remains on name entry")

	game.onboarding_name_input.text = "검은성123"
	game._onboarding_confirm_name()
	await get_tree().process_frame
	_expect(GameState.player_name == "검은성123", "mixed Korean player name stored")
	_expect(game.current_screen == Constants.SCREEN_DIALOGUE, "confirm name starts opening dialogue")
	await _advance_dialogue_until(game, Constants.SCREEN_MANAGEMENT, 100)
	_expect(GameState.day == 1, "opening ends at DAY 01")
	_expect(GameState.onboarding_stage == "LV03_DAY01_MANAGEMENT_TUTORIAL", "DAY 01 management stage set")

	for day in range(1, GameState.max_day + 1):
		_expect(GameState.day == day, "DAY %d tutorial loop starts" % day)
		game._start_combat()
		if game.current_screen == Constants.SCREEN_MONSTER:
			_expect(game._choose_early_specialization("goblin", "goblin_treasure_hunter"), "DAY %d tactical specialization is selected" % day)
			game._set_screen(Constants.SCREEN_MANAGEMENT)
			game._start_combat()
		await get_tree().physics_frame
		_expect(game.current_screen == Constants.SCREEN_COMBAT, "DAY %d combat screen opens" % day)
		if day == 1:
			var tutorial_speed_button := _find_button_by_text(game.ui_layer, "x3")
			_expect(not game._combat_speed_unlocked(), "combat acceleration stays locked during the tutorial")
			_expect(tutorial_speed_button != null and tutorial_speed_button.disabled, "tutorial combat shows x3 as locked")
			game._set_speed(3.0)
			_expect(is_equal_approx(game.combat_speed, 1.0), "tutorial combat remains fixed at x1")
		game.wave_manager.next_index = game.wave_manager.schedule.size()
		for entry in game.wave_manager.schedule:
			game._spawn_enemy(str(entry.get("enemy_id", "explorer")))
		for enemy in game.enemy_units:
			if enemy.is_alive():
				enemy.receive_damage(9999)
		game._check_combat_end()
		await _advance_dialogue_until(game, Constants.SCREEN_RESULT, 120)
		_expect(game.current_screen == Constants.SCREEN_RESULT, "DAY %d result screen reached" % day)
		if day < GameState.max_day:
			game._continue_from_result()
			await _advance_dialogue_until(game, Constants.SCREEN_MANAGEMENT, 120)
			_expect(GameState.day == day + 1, "result advances to DAY %d management" % (day + 1))
		else:
			_expect(GameState.victory, "DAY 03 win marks demo victory")
			game._continue_from_result()
			await _advance_dialogue_until(game, Constants.SCREEN_RAID_PREVIEW, 120)
			_expect(GameState.day == 4, "demo victory advances to DAY 04 preview")
			_expect(GameState.onboarding_stage == "LV12_DAY04_RAID_PREVIEW", "DAY 04 preview stage set")

	game.tutorial_gate_enabled = true
	game._onboarding_finish_raid_preview()
	await _advance_dialogue_until(game, Constants.SCREEN_MANAGEMENT, 120)
	_expect(GameState.onboarding_complete, "DAY 04 preview completion marks onboarding complete")
	_expect(not game.tutorial_gate_enabled, "DAY 04 preview completion releases the tutorial gate")
	_expect(game._combat_speed_unlocked() and not game.combat_speed_intro_seen, "tutorial completion unlocks acceleration and queues its introduction")
	var day_four_save: Dictionary = CampaignSaveStoreScript.inspect(TEST_SAVE_PATH)
	_expect(str(day_four_save.get("status", "")) == CampaignSaveStoreScript.STATUS_VALID, "DAY 04 management checkpoint is saveable")

	game._start_combat()
	await get_tree().physics_frame
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "DAY 04 regular campaign combat opens")
	_expect(game.ui_layer.get_node_or_null("CombatSpeedFeatureIntro") != null and game.combat_speed_intro_open and game.combat_paused, "first regular combat introduces acceleration while paused")
	var unlocked_speed_button := _find_button_by_text(game.ui_layer, "x3")
	_expect(unlocked_speed_button != null and not unlocked_speed_button.disabled, "x3 becomes usable when its introduction appears")
	game._dismiss_combat_speed_intro()
	_expect(game.combat_speed_intro_seen and not game.combat_speed_intro_open and not game.combat_paused, "confirming the introduction resumes combat and records it")
	game._set_speed(3.0)
	_expect(is_equal_approx(game.combat_speed, 3.0), "x3 works immediately after the introduction")
	game.wave_manager.next_index = game.wave_manager.schedule.size()
	for entry in game.wave_manager.schedule:
		game._spawn_enemy(str(entry.get("enemy_id", "explorer")))
	for enemy in game.enemy_units:
		if enemy.is_alive():
			enemy.receive_damage(9999)
	game._check_combat_end()
	await _advance_dialogue_until(game, Constants.SCREEN_RESULT, 120)
	_expect(game.current_screen == Constants.SCREEN_RESULT, "DAY 04 result screen reached")
	game._continue_from_result()
	await _advance_dialogue_until(game, Constants.SCREEN_MANAGEMENT, 120)
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(GameState.day == 5, "DAY 04 victory advances to DAY 05 management")
	var day_five_save: Dictionary = CampaignSaveStoreScript.inspect(TEST_SAVE_PATH)
	var day_five_payload: Dictionary = day_five_save.get("payload", {})
	_expect(str(day_five_save.get("status", "")) == CampaignSaveStoreScript.STATUS_VALID, "DAY 05 management checkpoint remains saveable")
	_expect(int(day_five_payload.get("game_state", {}).get("day", 0)) == 5 and not bool(day_five_payload.get("onboarding", {}).get("tutorial_gate_enabled", true)), "DAY 05 save records the released tutorial gate")
	_expect(bool(day_five_payload.get("onboarding", {}).get("combat_speed_intro_seen", false)), "DAY 05 save records the completed acceleration introduction")
	_expect(str(day_five_payload.get("game_state", {}).get("player_name", "")) == "검은성123", "mixed Korean player name survives the save round trip")
	var legacy_payload := day_five_payload.duplicate(true)
	legacy_payload["onboarding"].erase("combat_speed_intro_seen")
	_expect(CampaignSaveStoreScript.validate_payload(legacy_payload, day_five_save.get("summary", {})) == "", "legacy saves without the acceleration introduction flag remain valid")
	var invalid_intro_payload := day_five_payload.duplicate(true)
	invalid_intro_payload["onboarding"]["combat_speed_intro_seen"] = "invalid"
	_expect(CampaignSaveStoreScript.validate_payload(invalid_intro_payload, day_five_save.get("summary", {})).contains("전투 속도 안내"), "invalid acceleration introduction state is rejected")

	CampaignSaveStoreScript.delete(TEST_SAVE_PATH)
	game.queue_free()
	await get_tree().process_frame
	if failed:
		print("ONBOARDING_FLOW_SMOKE_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("ONBOARDING_FLOW_SMOKE_TEST: PASS")
		get_tree().quit(0)

func _advance_dialogue_until(game: Node, expected_screen: String, max_steps: int) -> void:
	for _i in range(max_steps):
		await get_tree().process_frame
		if game.current_screen == Constants.SCREEN_DIALOGUE:
			game._onboarding_advance_dialogue()
			continue
		if game.current_screen == expected_screen:
			return
		push_error("Expected %s but reached %s" % [expected_screen, game.current_screen])
		failed = true
		return
	push_error("Timed out waiting for %s" % expected_screen)
	failed = true

func _find_button_by_text(node: Node, text: String) -> Button:
	if node is Button and node.text == text:
		return node
	for child in node.get_children():
		var result := _find_button_by_text(child, text)
		if result != null:
			return result
	return null

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		push_error("FAIL: %s" % message)
		failed = true
