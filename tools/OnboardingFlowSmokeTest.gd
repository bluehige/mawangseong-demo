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
	game._onboarding_dismiss_name_entry_tip()
	await get_tree().process_frame
	_expect(game.onboarding_name_entry_tip_dismissed, "name tip dismisses on click")
	_expect(game.onboarding_name_input.visible and game.onboarding_name_input.editable, "name input appears after tip")

	game.onboarding_name_input.text = "테스트마왕"
	game._onboarding_confirm_name()
	await get_tree().process_frame
	_expect(GameState.player_name == "테스트마왕", "player name stored")
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
	var day_four_save: Dictionary = CampaignSaveStoreScript.inspect(TEST_SAVE_PATH)
	_expect(str(day_four_save.get("status", "")) == CampaignSaveStoreScript.STATUS_VALID, "DAY 04 management checkpoint is saveable")

	game._start_combat()
	await get_tree().physics_frame
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "DAY 04 regular campaign combat opens")
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

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		push_error("FAIL: %s" % message)
		failed = true
