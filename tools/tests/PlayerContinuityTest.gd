extends "res://tools/tests/PlayerFeedbackHotfixTest.gd"
const Bundle = preload("res://scripts/core/CampaignSaveBundleGuard.gd")

func run() -> void:
	output_dir = "res://tmp/continuity_review"
	expect(ProjectSettings.globalize_path("user://").contains("continuity_review"), "isolated synthetic user data")
	if not failures.is_empty(): get_tree().quit(1); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	var prior_config := ConfigFile.new()
	prior_config.set_value("updates", "acknowledged", "1.2.10-continuity-20261011")
	prior_config.set_value("review", "prior_setting", "preserve")
	prior_config.save("user://settings.cfg")
	game = GameRootScene.instantiate()
	add_child(game)
	await settle()
	expect(game.continuity.update_open, "1.2.10 acknowledgement does not suppress first 1.3.0 notes")
	expect(modal_has_focus("UpdateNotesOverlay"), "startup update owns focus without manual focus injection")
	game._set_screen(Constants.SCREEN_MANAGEMENT, false)
	expect(not game.continuity.update_open and game.ui_layer.find_child("UpdateNotesOverlay", true, false) == null, "leaving title clears discarded update modal input state")
	game._set_screen(Constants.SCREEN_TITLE, false)
	await settle()
	expect(game.continuity.update_open, "unacknowledged update returns when title is revisited")
	expect(game.continuity.UPDATE_ID == "1.3.0", "acknowledgement key matches installed patch version")
	game.continuity.acknowledge_update()
	expect(game.continuity.update_acknowledged(), "update acknowledgement persisted offline")
	prior_config.load("user://settings.cfg")
	expect(prior_config.get_value("review", "prior_setting", "") == "preserve", "version acknowledgement preserves unrelated prior settings")
	game._set_screen(Constants.SCREEN_TITLE)
	await settle()
	expect(not game.continuity.update_open, "acknowledged build does not pop up again")
	expect(game.ui_layer.find_child("InstalledVersionLabel", true, false).text.contains("1.3.0"), "title actual installed version")
	await click(game.ui_layer.find_child("TitleUpdateNotesButton", true, false))
	expect(game.continuity.update_open, "title reopens update notes")
	await capture("update_notes")
	await keyboard_accept(game.ui_layer.find_child("UpdateNotesConfirm", true, false))
	expect(not game.continuity.update_open, "focused update button accepts keyboard input")
	if game.continuity.update_open: game.continuity.acknowledge_update()
	await test_acknowledgement_failure()
	game._onboarding_reset_game()
	game._onboarding_enter_management_day(1, true)
	game.onboarding_dialogue_queue.clear()
	game.story_director.cancel_active_scene()
	expect(game.story_director.start_scene("STORY_D01_MANAGEMENT_ENTRY", game._story_context(), Constants.SCREEN_MANAGEMENT), "explicit multi-line catalogue dialogue fixture")
	game._story_show_active_scene()
	game.story_director.set_auto(false)
	game._story_refresh_dialogue_ui()
	for i in range(2): game._story_advance_dialogue(true)
	expect(game.continuity.history.size() >= 3, "rapid advancement retains previously displayed lines")
	game.story_director.set_auto(true)
	game._story_refresh_dialogue_ui()
	await settle()
	var cursor: int = game.story_director.cursor
	var state: Dictionary = game.story_director.export_state()
	var gold: int = GameState.gold
	var size: int = game.continuity.history.size()
	await click(game.ui_layer.find_child("DialogueBacklogButton", true, false))
	game._story_tick_auto(100.0)
	game._story_advance_dialogue(true)
	expect(game.story_director.cursor == cursor, "backlog freezes auto and manual advancement")
	expect(game.story_director.export_state() == state and GameState.gold == gold, "reading history never changes story flags or rewards")
	await capture("dialogue_backlog")
	await keyboard_accept(game.ui_layer.find_child("BacklogCloseButton", true, false))
	expect(not game.continuity.backlog_open, "focused backlog close accepts keyboard input")
	if game.continuity.backlog_open: game.continuity.close_backlog()
	expect(game.story_director.auto_enabled and game.continuity.history.size() == size, "close resumes auto without appending duplicate current cue")
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	game._input(esc)
	expect(game.pause_menu_open, "ESC opens shared menu during story")
	await settle()
	for i in range(8):
		await keyboard_key(KEY_TAB)
		expect(modal_has_focus("PauseMenuOverlay"), "menu tab focus remains inside modal " + str(i))
	game.ui_layer.find_child("DialogueMenuButton", true, false).grab_focus()
	await keyboard_key(KEY_ENTER)
	expect(not game.pause_menu_open and game.story_director.cursor == cursor, "menu accept repairs outside focus and resumes without advancing story")
	game._open_pause_menu()
	game._story_tick_auto(100.0)
	expect(game.story_director.cursor == cursor, "menu freezes story auto")
	for name in ["PauseResumeButton", "PauseSaveButton", "PauseLoadButton", "PauseSettingsButton", "PauseTitleButton", "PauseQuitButton"]:
		expect(game.ui_layer.find_child(name, true, false) != null, "menu action present " + name)
	await click(game.ui_layer.find_child("PauseSettingsButton", true, false))
	expect(game.ui_layer.find_child("SettingsInstalledVersionLabel", true, false).text == "v1.3.0", "settings shows actual installed version")
	await capture("settings_version")
	game._story_tick_auto(100.0)
	expect(game.story_director.cursor == cursor, "settings freezes hidden dialogue")
	await click(game.ui_layer.find_child("SettingsGameMenuButton", true, false))
	expect(game.pause_menu_open and game.current_screen == Constants.SCREEN_DIALOGUE, "settings menu returns to exact story and common controls")
	game._close_pause_menu()
	game.story_director.set_auto(false)
	while game.story_director.is_active(): game._story_advance_dialogue(true)
	GameState.player_name = "Continuity QA"
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game._set_campaign_save_path_for_tests("user://campaign_save_v1.json", "user://campaign_save_v2.json", "user://campaign_save_v3.json", "user://campaign_save_v4.json", "user://campaign_save_v5.json")
	game._set_screen(Constants.SCREEN_MANAGEMENT, false)
	game._open_pause_menu()
	expect(game.continuity.save_now(), "manual checkpoint save succeeds for all formats")
	var saved_gold: int = GameState.gold
	var paths: Array = [game.campaign_save_path, game.campaign_save_v2_path, game.campaign_save_v3_path, game.campaign_save_v4_path, game.campaign_save_v5_path]
	var before: Dictionary = Bundle.snapshot(paths)
	expect(game.continuity.checkpoint_text().contains("DAY 01") and game.continuity.checkpoint_text().contains("2026"), "menu shows checkpoint day and timestamp")
	await capture("management_menu")
	var good_v5: String = game.campaign_save_v5_path
	game.campaign_save_v5_path = "user://nonexistent-folder/campaign_save_v5.json"
	GameState.gold += 37
	expect(not game.continuity.save_now(), "injected v5 write failure rejects save")
	expect(Bundle.snapshot(paths).files == before.files, "failed save restores complete v1-v5 bytes")
	expect(game.campaign_save_status == game.CampaignSaveStoreScript.STATUS_VALID, "recovered checkpoint remains available after failed new write")
	game.continuity.confirm("title")
	game.continuity.leave(true)
	expect(game.current_screen == Constants.SCREEN_MANAGEMENT and game.pause_menu_open, "save failure blocks save-and-title; game stays playable")
	game.continuity.confirm("quit")
	game.continuity.leave(true)
	expect(game.current_screen == Constants.SCREEN_MANAGEMENT and game.pause_menu_open, "save failure also blocks save-and-quit")
	game.campaign_save_v5_path = good_v5
	game.campaign_save_notice = ""
	for i in range(3):
		game.continuity.confirm("title")
		game.continuity.leave(false)
		game._continue_campaign_save()
		await settle()
		expect(GameState.gold == saved_gold and game.current_screen == Constants.SCREEN_MANAGEMENT, "title continue repetition restores checkpoint without reward duplication " + str(i))
		expect(not game.pause_menu_open and not game.campaign_save_restore_active, "restore clears menu and input state " + str(i))
	await test_countdown_menu()
	game.combat_scene.start_combat()
	game.story_director.cancel_active_scene()
	game.story_combat_overlay_open = false
	game.combat_scene.set_pause_state(false, false)
	game._open_pause_menu()
	var combat_time: float = game.combat_time
	before = Bundle.snapshot(paths)
	expect(not game.continuity.save_now(), "combat save explicitly unavailable")
	expect(Bundle.snapshot(paths).files == before.files, "combat menu never writes false mid-battle checkpoint")
	game.continuity.confirm("title")
	game.continuity.cancel_confirmation()
	expect(game.pause_menu_open and game.combat_paused, "cancel confirmation retains pause")
	game._close_pause_menu()
	expect(not game.combat_paused and game.combat_time >= combat_time, "resume restores original unpaused state")
	game.combat_scene.set_pause_state(true, false)
	game._open_pause_menu()
	game._close_pause_menu()
	expect(game.combat_paused, "already paused battle remains paused after menu")
	game._open_pause_menu()
	await capture("combat_menu")
	game._close_pause_menu()
	await test_feed()
	await test_promotion()
	await test_locales()
	game.queue_free()
	await settle()
	print("PlayerContinuityTest: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func keyboard_accept(control: Control) -> void:
	control.grab_focus()
	await keyboard_key(KEY_ENTER)

func modal_has_focus(name: String) -> bool:
	var overlay: Node = game.ui_layer.find_child(name, true, false)
	var focused: Control = game.get_viewport().gui_get_focus_owner()
	return overlay != null and focused != null and overlay.is_ancestor_of(focused)

func keyboard_key(key: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = key
		event.physical_keycode = key
		event.pressed = pressed
		get_viewport().push_input(event, true)
		await settle()

func test_acknowledgement_failure() -> void:
	var path: String = ProjectSettings.globalize_path("user://settings.cfg")
	var backup: String = path + ".ack-test-backup"
	var staged: bool = DirAccess.rename_absolute(path, backup) == OK
	expect(staged, "acknowledgement failure fixture preserves synthetic settings")
	if not staged: return
	expect(DirAccess.make_dir_absolute(path) == OK, "acknowledgement failure fixture blocks config write")
	game.continuity.show_update()
	game.continuity.acknowledge_update()
	expect(not game.continuity.update_open, "failed acknowledgement write never traps player behind update modal")
	game._set_screen(Constants.SCREEN_TITLE, false)
	expect(not game.continuity.update_open, "failed acknowledgement remains dismissed for this session")
	DirAccess.remove_absolute(path)
	expect(DirAccess.rename_absolute(backup, path) == OK, "acknowledgement failure fixture restores synthetic settings")
	if game.continuity.update_open: game.continuity.acknowledge_update()

func test_countdown_menu() -> void:
	var story_enabled: bool = game.story_feature_enabled
	game.story_feature_enabled = false
	game._request_combat_start()
	expect(game.current_screen == Constants.SCREEN_DEFENSE_START, "countdown menu fixture enters real precombat snapshot")
	if game.current_screen != Constants.SCREEN_DEFENSE_START:
		game.story_feature_enabled = story_enabled
		return
	var remaining: float = game.defense_start_remaining
	await click(game.ui_layer.find_child("CommonGameMenuButton", true, false))
	game._tick_defense_start_countdown(4.0)
	expect(game.current_screen == Constants.SCREEN_DEFENSE_START and game.pause_menu_open, "countdown cannot start battle behind the menu")
	expect(game.defense_start_remaining == remaining, "countdown menu preserves remaining time")
	if game.current_screen != Constants.SCREEN_DEFENSE_START:
		game._close_pause_menu()
		game.story_feature_enabled = story_enabled
		return
	await click(game.ui_layer.find_child("PauseSettingsButton", true, false))
	await click(game.ui_layer.find_child("SettingsGameMenuButton", true, false))
	expect(game.current_screen == Constants.SCREEN_DEFENSE_START and game.pause_menu_open, "countdown settings return keeps menu and source")
	game._tick_defense_start_countdown(4.0)
	expect(game.defense_start_remaining == remaining, "countdown settings return remains held")
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	game._input(esc)
	expect(not game.pause_menu_open, "countdown ESC resumes menu")
	game._input(esc)
	expect(game.pause_menu_open, "countdown ESC reopens common menu")
	game._input(esc)
	game._tick_defense_start_countdown(4.0)
	expect(game.current_screen == Constants.SCREEN_COMBAT and not game.pause_menu_open, "resumed countdown starts input-enabled battle")
	game._set_screen(Constants.SCREEN_MANAGEMENT, false)
	game.story_feature_enabled = story_enabled

func test_feed() -> void:
	game.combat_story_feed.clear()
	game.combat_time = 0.0
	game.combat_paused = false
	var candidate: Dictionary = {}
	for id in game.story_catalog.all_scene_ids():
		var scene: Dictionary = game.story_catalog.scene(id)
		if scene.get("metadata", {}).get("nonblocking", false) and scene.get("metadata", {}).get("required_event", "") == "":
			candidate = scene
			break
	expect(not candidate.is_empty(), "nonblocking scene available for reproduction")
	if candidate.is_empty(): return
	var facts: Dictionary = game._story_context({"battle_scope_id": "continuity-test"})
	game.combat_story_feed.enqueue(game, candidate, facts)
	game.combat_story_feed.tick(game, 0.01)
	expect(game.combat_story_feed.reader != null, "feed starts actual catalogue scene")
	var reader = game.combat_story_feed.reader
	var remaining: float = game.combat_story_feed.remaining
	game._open_pause_menu()
	game._open_settings_screen(true)
	game.combat_story_feed.tick(game, 30.0)
	expect(game.combat_story_feed.reader == reader and game.combat_story_feed.remaining == remaining, "settings does not clear queue or consume reading time")
	game._cancel_settings_changes()
	game._close_pause_menu()
	game.combat_time = 36.0
	game.combat_story_feed.tick(game, 0.01)
	expect(game.combat_story_feed.reader == reader, "x3 simulation age does not discard visible sentence")
	await capture("combat_feed")
	game.combat_story_feed.clear()
	# Ordinary pending feed: priority replacement, four-entry cap and expiry remain.
	for i in range(7):
		var other := candidate.duplicate(true)
		other["id"] = "ordinary-%d" % i
		other["metadata"]["feed_priority"] = i
		game.combat_story_feed.enqueue(game, other, facts)
	expect(game.combat_story_feed.pending.size() == 4, "ordinary feed remains capped at four")
	expect(int(game.combat_story_feed.pending[0].scene.metadata.feed_priority) == 6, "ordinary feed sorted by priority")
	game.combat_time = 100.0
	expect(not game.combat_story_feed._still_relevant(game, game.combat_story_feed.pending[0]), "queued ordinary reaction expires after twelve combat seconds")
	game.combat_story_feed.clear()
	GameState.day = 12
	game.story_director.cancel_active_scene()
	game.story_pending_combat_scenes.clear()
	game.story_combat_overlay_open = false
	game.story_director.set_auto(false)
	game._story_queue_combat_trigger("combat_time", {"combat_time": 0.0})
	print("important fixture reader: ", game.story_director.current_scene_id)
	expect(game.story_combat_overlay_open and game.story_director.current_scene_id == "STORY_D12_COMBAT_01", "important promotion story uses retained blocking reader")
	game.story_director.cancel_active_scene()
	game._story_close_combat_overlay()

func test_promotion() -> void:
	game._clear_units()
	var room := "entrance"
	game.monster_roster["goblin"]["promotion_id"] = ""
	var goblin: Node = game._create_unit("goblin", DataRegistry.monster("goblin"), Constants.FACTION_MONSTER, room)
	var explorer: Node = game._create_unit("explorer", DataRegistry.enemy("explorer"), Constants.FACTION_ENEMY, room)
	var support: Node = game._create_unit("engineer", DataRegistry.enemy("engineer"), Constants.FACTION_ENEMY, room)
	var thief: Node = game._create_unit("thief", DataRegistry.enemy("thief"), Constants.FACTION_ENEMY, room)
	for unit in [goblin, explorer, support, thief]: unit.set_physics_process(false)
	game.monster_units = [goblin]
	game.enemy_units = [explorer, support, thief]
	goblin.global_position = game.graph.center(room)
	explorer.global_position = goblin.global_position + Vector2(12, 0)
	support.global_position = goblin.global_position + Vector2(18, 0)
	thief.global_position = goblin.global_position + Vector2(25, 0)
	var base: Node = game.combat_scene._specialization_priority_target(goblin, explorer)
	game.monster_roster["goblin"]["promotion_id"] = "goblin_ambush_captain"
	var promoted: Node = game.combat_scene._specialization_priority_target(goblin, explorer)
	expect(base == thief and promoted == thief, "measured overlap: base and captain choose identical thief")
	thief.hp = 0
	game.continuity.prototype_ambush_enabled = false
	expect(game.combat_scene._specialization_priority_target(goblin, explorer) == explorer, "default captain targeting unchanged")
	game.continuity.prototype_ambush_enabled = true
	expect(game.combat_scene._specialization_priority_target(goblin, explorer) == support, "opt-in captain prototype prioritizes rear support after thieves")
	game.monster_roster["goblin"]["promotion_id"] = ""
	expect(game.combat_scene._specialization_priority_target(goblin, explorer) == explorer, "prototype leaves base goblin fallback unchanged")
	game.monster_roster["goblin"]["promotion_id"] = "goblin_ambush_captain"
	game.continuity.prototype_ambush_enabled = false
	game.selected_unit = goblin
	game.combat_scene.set_pause_state(true, false)
	GameState.mana = 500
	game.continuity.reset_combat()
	var hp: int = explorer.hp
	expect(game.combat_scene._execute_selected_unit_skill(0), "real promoted slash executes")
	expect(game.continuity.promotion_damage > 0 and explorer.hp < hp, "contribution records actual damage rather than theoretical attack")
	expect(game.ui_layer.find_child("PromotionFirstUseText", true, false) != null, "first upgraded slash visible in battle")
	await capture("promotion_first_use")
	var rule: Dictionary = DataRegistry.evolution_rules.get("goblin_ambush_captain", {}).duplicate(true)
	rule["id"] = "goblin_ambush_captain"
	expect(game.continuity.promotion_explanation(rule).contains("1.90"), "before and after skill change explained")
	game.selected_monster_id = "goblin"
	game._set_screen(Constants.SCREEN_MONSTER, false)
	await settle()
	game.ui_layer.find_child("MonsterGrowthScroll", true, false).scroll_vertical = 100000
	await capture("promotion_growth")

func test_locales() -> void:
	for locale in ["en", "zh_CN"]:
		LanguageSettings.set_locale(locale, false)
		game._set_screen(Constants.SCREEN_MANAGEMENT, false)
		game._open_pause_menu()
		await capture("menu_" + locale)
		expect(game.ui_layer.find_child("PauseSaveButton", true, false).text == ("Save" if locale == "en" else "保存"), "localized menu " + locale)
		game._close_pause_menu()
		game._set_screen(Constants.SCREEN_TITLE, false)
		game.continuity.show_update()
		await capture("update_" + locale)
		expect(game.continuity.update_open, "offline localized update notes " + locale)
		game.continuity.acknowledge_update()
	LanguageSettings.set_locale("ko", false)
