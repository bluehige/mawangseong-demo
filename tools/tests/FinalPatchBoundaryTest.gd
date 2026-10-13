extends SceneTree
# One final packaged-runtime pass for the new boundaries only. No combat/save
# suite is rerun. All writes are confined to the fresh final-review profile.
var game
var state
var registry
var language
var out := ""
var args: PackedStringArray
var failures: Array[String] = []
var checks := 0
var evidence := {}
var repair_only := false
var last_input_feedback := ""

func _initialize() -> void:
	args = OS.get_cmdline_user_args()
	out = args[1]
	repair_only = args.size() > 4
	if not ProjectSettings.load_resource_pack(args[0], true):
		printerr("FINAL_PATCH_MOUNT_FAILED"); quit(2); return
	call_deferred("run")

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); printerr("FINAL_BOUNDARY_FAIL: " + label)

func settle(frames: int = 8) -> void:
	for i in range(frames): await process_frame

func click(name: String) -> bool:
	var button = game.find_child(name, true, false)
	if not button is BaseButton or not button.is_visible_in_tree() or button.disabled: return false
	await click_point(button.get_global_rect().get_center())
	return true

func click_point(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new(); motion.position = point; root.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new(); event.position = point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		root.push_input(event, true)
		if pressed: last_input_feedback = str(game._management_feedback_line())
		await process_frame
	await settle()

func read_dialogue() -> void:
	for i in range(150):
		if not game.story_director.is_active() and game.onboarding_dialogue_queue.is_empty(): return
		if game.story_director.is_active():
			if not game.story_director.current_cue().get("choices", []).is_empty(): return
			game._story_advance_dialogue(true)
		else: game._onboarding_advance_dialogue()
		await settle(2)

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))

func run() -> void:
	create_timer(120.0).timeout.connect(func(): expect(false, "unfinished harness timeout"); finish())
	expect(ProjectSettings.globalize_path("user://").contains("final-review"), "isolated profile before game/save operations")
	if not failures.is_empty(): finish(); return
	DirAccess.make_dir_recursive_absolute(out)
	state = root.get_node("GameState"); registry = root.get_node("DataRegistry"); language = root.get_node("LanguageSettings")
	var main = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(main); current_scene = main; game = main.get_node("GameRoot")
	await settle(20)
	if not repair_only: expect(game.combat_scene != null and game.current_screen == "title", "actual final Main title/controllers boot")
	evidence["version"] = ProjectSettings.get_setting("application/config/version")
	if not repair_only: expect(language.catalog_error == "" and language.ui_catalog_error == "", "mounted final localization initializes without errors")
	await click("UpdateNotesConfirm")
	game.campaign_save_enabled = false
	language.set_locale("ko", false)
	if not repair_only: await capture("final-title")
	await placement_ui()
	if not repair_only or args[4] != "remaining": await facility_ui()
	await day30_save_and_quit()

func placement_ui() -> void:
	var outcomes := []
	for room_id in ["barracks", "recovery"]:
		game._set_screen("title", false); await settle()
		expect(await click("CampaignNewGameButton"), "normal New Game initializes tutorial flow " + room_id)
		game.campaign_save_enabled = false
		game.onboarding_name_input.text = "최종경계검토"
		game.onboarding_name_input.text_changed.emit("최종경계검토")
		game._onboarding_confirm_name(); await settle(); await read_dialogue(); await settle()
		expect(await click("EnterPlacementButton"), "normal placement entry " + room_id)
		expect(await click("MonsterCard_goblin"), "DAY1 actual Gob selection control " + room_id)
		expect(game._day1_goblin_choice_active(), "normal tutorial reaches formation choice " + room_id)
		var point: Vector2 = game.get_global_transform_with_canvas() * game.graph.center(room_id)
		expect(not game._management_ui_at(point), "formation map target unobstructed " + room_id)
		await click_point(point); await read_dialogue(); await settle()
		var desired_zone := "zone_a_front" if room_id == "barracks" else "zone_a_rear"
		expect(str(game.monster_roster.goblin.room) == room_id and str(game.monster_roster.goblin.get("defense_zone_id", "")) == desired_zone, "actual chosen formation/zone " + room_id)
		var feedback := last_input_feedback
		expect(feedback.contains("선택 완료") and not feedback.contains("이미"), "same/new room confirms chosen formation " + room_id)
		var card = game.find_child("MonsterCard_goblin", true, false)
		expect(card != null and card.text.contains("푸딩 합류" if room_id == "barracks" else "핀 합류"), "visible card matches selected formation " + room_id)
		outcomes.append({"room": room_id, "zone": desired_zone, "feedback": feedback, "card": card.text if card != null else ""})
		await capture("placement-" + room_id)
	evidence["placement"] = outcomes
	game.onboarding_enabled = false; game.tutorial_gate_enabled = false; game.tutorial_manager.active = false
	game.story_director.cancel_active_scene(); game.onboarding_dialogue_queue.clear()

func facility_ui() -> void:
	var vm = load("res://scripts/v122/ui/V122CombatResultViewModel.gd")
	var recorded: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[3])).evidence.result
	var metrics: Dictionary = recorded.metrics
	var missing: Dictionary = metrics.duplicate(true); missing.erase("facility_effects")
	if not repair_only: expect(vm._facility_feedback(missing) == "", "missing facility metrics never invent zero contribution")
	var partial: Dictionary = metrics.duplicate(true); partial.facility_effects = {"watch_post_bonus_damage": 7}; partial.decision_context.built_facilities = ["watch_post"]
	if not repair_only: expect(vm._facility_feedback(partial) == "", "partial old metrics do not invent missing slow count")
	var summary: String = vm._facility_feedback(metrics)
	if not repair_only: expect(summary.contains("추가 피해 +17") and summary.contains("실제 회복 0 HP"), "existing recorded facility values, including measured zero, presented unchanged")
	# Synthetic visibility stress only: retain recorded facility measurements and
	# add an alert plus built watch-post zero counters. This is not combat evidence.
	var display: Dictionary = recorded.duplicate(true)
	display.metrics.decision_context.built_facilities.append("watch_post")
	display.metrics.treasure_gold_stolen = 11
	display.v122_ledger.gold_stolen = 11
	game.result_summary = display; game.last_growth_summary = display.get("growth", [])
	state.day = 1
	var views := []
	for locale in (["en", "zh_CN"] if repair_only else ["ko", "en", "zh_CN"]):
		language.set_locale(locale, false)
		game._set_screen("result", false); await settle(12)
		var label = game.find_child("ResultFacilityFeedback", true, false)
		if not repair_only: expect(label != null and label.is_visible_in_tree(), "facility contribution visible alongside theft alert " + locale)
		if label != null:
			if not repair_only: expect(label.text.contains("17") and label.text.contains("11") and label.get_line_count() <= 4, "facility/alert values fit final result panel " + locale)
			var rendered: String = language.ui_text(label.text)
			if locale == "en": expect(rendered.contains("Barracks") and rendered.contains("Recovery Room") and not rendered.contains("병영"), "final mounted English facility templates active")
			if locale == "zh_CN": expect(rendered.contains("兵营") and rendered.contains("恢复室") and not rendered.contains("회복실"), "final mounted Chinese facility templates active")
			views.append({"locale": locale, "source_text": label.text, "rendered_text": rendered, "lines": label.get_line_count(), "height": label.size.y})
		await capture("result-facility-" + locale)
	evidence["facility_display_fixture"] = views
	language.set_locale("ko", false)

func checkpoint_bytes() -> Dictionary:
	var result := {}
	for path in [game.campaign_save_path, game.campaign_save_v2_path, game.campaign_save_v3_path, game.campaign_save_v4_path, game.campaign_save_v5_path]:
		result[path] = FileAccess.get_file_as_string(path)
	return result

func day30_save_and_quit() -> void:
	var copied: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[2]))
	expect(game._restore_campaign_payload(copied.payload), "read isolated byte-copy of actual local DAY2 checkpoint")
	game.onboarding_enabled = false; game.tutorial_gate_enabled = false; game.tutorial_manager.active = false
	game.story_director.cancel_active_scene(); game.onboarding_dialogue_queue.clear()
	state.day = 30; state.onboarding_complete = true
	game.campaign_stage_two_unlock_ready = true
	game._apply_castle_evolution_for_day(15)
	game.campaign_chapter_three_clear = true
	game._apply_castle_evolution_for_day(20)
	game.campaign_final_upgrade_ready = true
	game._apply_castle_evolution_for_day(27)
	game.campaign_final_preparation_confirmed = true
	expect(game.castle_art_stage == "stage_04_citadel", "controlled DAY30 fixture has required real castle evolution")
	game.build_pick_mode = false; game.deploy_pick_monster_id = ""
	game.result_summary.clear(); game.last_growth_summary.clear()
	var expected_roster := {}
	for instance_id in registry.monster_instances:
		var template: Dictionary = registry.monster_instances[instance_id]
		var species: String = str(template.species_id)
		var row: Dictionary = game.monster_roster.get(species, {}).duplicate(true)
		row.merge({"level": 5, "exp": 13, "bond": 44, "bond_rank": 1, "room": "barracks", "promotion_id": "", "specialization_id": "", "review_nested": {"mastery": 2, "values": [3, 5]}}, true)
		game.monster_roster[species] = row
		expected_roster[species] = row.duplicate(true)
	game.selected_monster_id = "graveyard_hound"
	game.raid_selected_monster_ids.assign(["graveyard_hound", "spider_tailor", "bat_courier"])
	game._set_campaign_save_path_for_tests("user://campaign_save_v1.json", "user://campaign_save_v2.json", "user://campaign_save_v3.json", "user://campaign_save_v4.json", "user://campaign_save_v5.json")
	game._set_screen("management", false); await settle()
	game._open_pause_menu()
	var saved: bool = game.continuity.save_now()
	expect(saved, "DAY30 controlled extended roster writes v1-v5 normally")
	if not saved: finish(); return
	var v5: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.campaign_save_v5_path))
	var persisted: Dictionary = v5.get("active_run", {}).get("monsters", {})
	expect(persisted.size() == expected_roster.size() and persisted.size() == 14, "all fourteen registered species preserved, no deletion")
	for instance_id in registry.monster_instances:
		var species: String = str(registry.monster_instances[instance_id].species_id)
		var row: Dictionary = persisted.get(instance_id, {})
		expect(not row.is_empty() and row.get("species_id") == species and row.get("instance_id") == instance_id, "canonical migration " + species)
		var fields_equal := true
		for key in expected_roster[species]:
			if JSON.stringify(row.get(key)) != JSON.stringify(expected_roster[species][key]): fields_equal = false
		expect(fields_equal, "all original runtime fields retained " + species)
	var legacy: Dictionary = v5.active_run.legacy_payload
	expect(legacy.world.selected_monster_id == "monster_koko" and legacy.raid.selected_monster_ids == ["monster_koko", "MON_SILKY", "MON_POPO"], "selected/raid references use same canonical mappings")
	var saved_resources: Dictionary = state.campaign_snapshot().duplicate(true)
	game._close_pause_menu(); game._continue_campaign_save(); await settle(12)
	expect(state.day == 30 and game.monster_roster.size() == 14 and game.monster_roster.has("graveyard_hound"), "v5 Continue restores controlled DAY30 Koko roster")
	expect(state.campaign_snapshot() == saved_resources, "controlled DAY30 load preserves resources")
	expect(game.monster_roster.graveyard_hound.level == 5 and game.monster_roster.graveyard_hound.exp == 13 and game.monster_roster.graveyard_hound.bond == 44 and game.monster_roster.graveyard_hound.review_nested.mastery == 2, "Koko progression and nested fields survive roundtrip")
	game._open_pause_menu(); await settle(); await capture("day30-save-success")
	var before := checkpoint_bytes()
	game.monster_roster["unknown_review_species"] = game.monster_roster.graveyard_hound.duplicate(true)
	var roster_before: Dictionary = game.monster_roster.duplicate(true)
	expect(await click("PauseQuitButton") and await click("LeaveSaveButton"), "real Save-and-Quit controls attempt unknown-species failure")
	expect(game.current_screen == "management" and game.pause_menu_open and game.continuity.confirmation_action == "quit", "failed save keeps playable game and Quit intent")
	expect(game.campaign_save_error.contains("unknown_review_species"), "truly unknown species still rejected")
	expect(checkpoint_bytes() == before and game.monster_roster == roster_before, "failed conversion preserves all five primary checkpoint bytes and roster")
	var quit_views := []
	for locale in ["ko", "en", "zh_CN"]:
		language.set_locale(locale, false)
		game.continuity.cancel_confirmation(); game.continuity.confirm("quit"); await settle()
		var error_label = game.find_child("LeaveSaveFailure", true, false)
		var quit_button = game.find_child("LeaveCheckpointButton", true, false)
		expect(error_label != null and quit_button != null and quit_button.is_visible_in_tree() and not quit_button.disabled, "actual error plus explicit no-save Quit choice " + locale)
		var loss = game.find_child("LeaveLossText", true, false)
		expect(loss != null and loss.is_visible_in_tree(), "checkpoint/loss guidance retained " + locale)
		quit_views.append({"locale": locale, "quit_label": quit_button.text, "error": error_label.text if error_label != null else ""})
		await capture("quit-save-failure-" + locale)
	language.set_locale("ko", false)
	expect(await click("LeaveCancelButton") and game.pause_menu_open and game.continuity.confirmation_action == "", "cancel returns to continued playable menu")
	game.continuity.confirm("quit"); await settle()
	evidence["day30"] = {"kind": "controlled reproduction from copied DAY2 data, not user's unseen DAY30 save", "species": expected_roster.keys(), "quit_views": quit_views, "checkpoint_bytes_preserved": checkpoint_bytes() == before}
	if not failures.is_empty(): finish(); return
	# Write evidence after the explicit control invokes production Quit; the
	# launcher verifies this process actually exits 0. No forced termination.
	var button = game.find_child("LeaveCheckpointButton", true, false)
	button.pressed.emit()
	expect(not game.pause_menu_open and not game.campaign_autosave_pending and checkpoint_bytes() == before, "explicit no-save Quit performs no checkpoint write")
	evidence["explicit_quit_invoked"] = true
	write_report()
	print("FINAL_PATCH_BOUNDARY: " + ("PASS" if failures.is_empty() else "FAIL") + " (%d/%d)" % [checks - failures.size(), failures.size()])

func write_report() -> void:
	var file := FileAccess.open(out.path_join("final-boundary-results.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "evidence": evidence}, "\t")); file.close()

func finish() -> void:
	write_report(); print("FINAL_PATCH_BOUNDARY: FAIL (%d/%d)" % [checks - failures.size(), failures.size()]); quit(1)
