extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const CampaignSaveStore = preload("res://scripts/core/CampaignSaveStore.gd")
const CampaignModeService = preload("res://scripts/systems/campaign/CampaignModeService.gd")
const CouncilSeasonService = preload("res://scripts/systems/campaign/CouncilSeasonService.gd")
const FrontCampaignService = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const SaveProgressionAdapter = preload("res://scripts/v122/save/V122SaveProgressionAdapter.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const TEST_SAVE_PATH := "user://v122_save_progression.json"
const TEST_V2_PATH := "user://v122_save_progression_v2.json"
const TEST_V3_PATH := "user://v122_save_progression_v3.json"
const TEST_V4_PATH := "user://v122_save_progression_v4.json"
const TEST_V5_PATH := "user://v122_save_progression_v5.json"

var failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup()
	var game := GameRootScene.instantiate()
	add_child(game)
	await _settle(4)
	game._set_campaign_save_path_for_tests(TEST_SAVE_PATH)
	game._debug_skip_onboarding()
	game.campaign_save_enabled = false

	_check_legacy_and_day_fixtures(game)
	await _check_day_transitions(game)
	_check_v122_round_trip_and_retry(game)
	_check_finale_retry_snapshot(game)
	_check_atomic_recovery(game)
	_check_update4_auxiliary_coexistence(game)

	game.queue_free()
	await _settle(2)
	_cleanup()
	if failed:
		print("V122_SAVE_PROGRESSION_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("V122_SAVE_PROGRESSION_TEST: PASS")
		get_tree().quit(0)


func _check_legacy_and_day_fixtures(game: Node) -> void:
	var fixture_specs := [
		{"name": "v1.2.0 새 게임", "day": 1, "legacy": true},
		{"name": "v1.2.1 DAY 1", "day": 1, "legacy": true},
		{"name": "DAY 3 성장 전", "day": 3},
		{"name": "DAY 3 성장 후", "day": 3, "growth": true},
		{"name": "DAY 5", "day": 5},
		{"name": "DAY 12 진화", "day": 12, "promotion": true},
		{"name": "DAY 20 전선", "day": 20, "front": true},
		{"name": "DAY 25 보스", "day": 25},
		{"name": "DAY 29", "day": 29},
		{"name": "DAY 30", "day": 30},
		{"name": "엔딩 완료", "day": 30, "ending": true},
		{"name": "Update 4 캠페인", "day": 30, "update4": true}
	]
	for spec_value in fixture_specs:
		var spec: Dictionary = spec_value
		_configure_day(game, int(spec.get("day", 1)), bool(spec.get("ending", false)))
		if bool(spec.get("growth", false)):
			game.last_growth_summary = [_growth_row()]
		else:
			game.last_growth_summary.clear()
		if bool(spec.get("promotion", false)):
			game.monster_roster["slime"]["promotion_id"] = "slime_gate_bulwark"
			game.monster_roster["slime"]["promotion_stage"] = 1
		if bool(spec.get("front", false)):
			game.update3_active_run["front_id"] = "front_hero_oath"
		if bool(spec.get("update4", false)):
			game.update4_active_run["campaign_mode_id"] = "council_season"
		var checkpoint := Constants.SCREEN_ENDING if bool(spec.get("ending", false)) else Constants.SCREEN_MANAGEMENT
		game.current_screen = checkpoint
		var payload: Dictionary = game._campaign_save_payload(checkpoint)
		var summary: Dictionary = game._campaign_save_summary(checkpoint)
		if bool(spec.get("legacy", false)):
			payload.erase("v122_battle_plan")
			_expect(SaveProgressionAdapter.validate_optional_payload(payload) == "", "%s accepts missing optional v1.2.2 state" % spec.get("name"))
		else:
			var v122: Dictionary = payload.get("v122_battle_plan", {})
			_expect(not v122.is_empty(), "%s contains v1.2.2 state" % spec.get("name"))
			_expect(str(v122.get("battle_plan", {}).get("layout_fingerprint", "")).length() == 64, "%s has a stable battle plan fingerprint" % spec.get("name"))
			_expect(not v122.get("facility_placements", []).is_empty(), "%s retains product facility placements" % spec.get("name"))
			_expect(not v122.get("monster_placements", []).is_empty(), "%s retains monster placements" % spec.get("name"))
		_expect(CampaignSaveStore.validate_payload(payload, summary) == "", "%s passes CampaignSaveStore validation" % spec.get("name"))
		var json_round_trip = JSON.parse_string(JSON.stringify(payload))
		_expect(json_round_trip is Dictionary and CampaignSaveStore.validate_payload(json_round_trip, summary) == "", "%s survives JSON round trip" % spec.get("name"))


func _check_day_transitions(game: Node) -> void:
	_configure_day(game, 5, false)
	game.current_screen = Constants.SCREEN_RESULT
	game.result_summary = {"win": true, "lines": ["DAY 5 방어 성공."]}
	game._continue_from_result()
	await _settle(4)
	_expect(
		GameState.day == 6 and game.current_screen == Constants.SCREEN_INTRUSION_BRIEF,
		"DAY 5 result advances to product DAY 6 (day=%d, screen=%s, victory=%s)" % [
			GameState.day,
			game.current_screen,
			str(GameState.victory)
		]
	)

	_configure_day(game, 30, true)
	game.current_screen = Constants.SCREEN_RESULT
	game.result_summary = {"win": true, "lines": ["DAY 30 최종 공성 방어 성공."]}
	game._continue_from_result()
	await _settle(4)
	_expect(GameState.day == 30 and game.current_screen == Constants.SCREEN_ENDING, "DAY 30 victory opens the ending without DAY 31")


func _check_v122_round_trip_and_retry(game: Node) -> void:
	_configure_day(game, 12, false)
	game.v122_command_settings = {
		"max_points": 4,
		"initial_points": 2,
		"recharge_seconds": 9.0,
		"preferred_commands": ["focus", "rally", "activate_facility", "emergency_fallback"]
	}
	game.v122_ui_state = {
		"management_context_collapsed": true,
		"result_details_collapsed": false
	}
	var plan: Dictionary = game._v122_current_battle_plan()
	game._capture_v122_battle_confirmation(plan)
	var payload: Dictionary = game._campaign_save_payload(Constants.SCREEN_MANAGEMENT)
	var summary: Dictionary = game._campaign_save_summary(Constants.SCREEN_MANAGEMENT)
	_expect(CampaignSaveStore.validate_payload(payload, summary) == "", "extended payload validates before write")
	var v122_state: Dictionary = payload.get("v122_battle_plan", {})
	for transient_key in ["current_hp", "cooldown", "cooldown_left", "command_points", "combat_elapsed", "recharge_elapsed"]:
		_expect(
			not _contains_key_recursive(v122_state, transient_key),
			"extended payload excludes transient combat key: %s" % transient_key
		)
	var write_result := CampaignSaveStore.write(payload, summary, TEST_SAVE_PATH)
	_expect(bool(write_result.get("ok", false)), "extended payload writes through CampaignSaveStore (%s)" % write_result.get("error", ""))
	var inspection := CampaignSaveStore.inspect(TEST_SAVE_PATH)
	_expect(str(inspection.get("status", "")) == CampaignSaveStore.STATUS_VALID, "extended payload inspects as valid")

	game.v122_command_settings.clear()
	game.v122_ui_state.clear()
	game.v122_last_confirmed_placements.clear()
	game.v122_retry_snapshot.clear()
	_expect(game._restore_campaign_payload(inspection.get("payload", {})), "extended payload restores through product runtime")
	_expect(int(game.v122_command_settings.get("max_points", 0)) == 4, "command settings round trip")
	_expect(bool(game.v122_ui_state.get("management_context_collapsed", false)), "minimal UI fold state round trips")
	_expect(str(game.v122_last_confirmed_placements.get("layout_fingerprint", "")) == str(plan.get("layout_fingerprint", "")), "last confirmed placement fingerprint round trips")
	_expect(int(game.v122_retry_snapshot.get("day", 0)) == 12, "pre-battle retry snapshot round trips")

	var expected_room := _retry_monster_room(game.v122_retry_snapshot, "slime")
	_expect(expected_room != "", "retry snapshot records the confirmed monster defense position")
	var changed_room := "treasure" if expected_room != "treasure" else "barracks"
	game.monster_roster["slime"]["room"] = changed_room
	game.global_directive = Constants.DIRECTIVE_ALL_OUT
	game._apply_v122_retry_snapshot()
	_expect(str(game.monster_roster.get("slime", {}).get("room", "")) == expected_room, "retry restores last confirmed monster placement")
	_expect(game.global_directive == str(game.v122_retry_snapshot.get("global_directive", "")), "retry restores confirmed command directive")

	var legacy_payload := payload.duplicate(true)
	legacy_payload.erase("v122_battle_plan")
	game._reset_v122_save_progression()
	_expect(game._restore_campaign_payload(legacy_payload), "legacy save restores without v1.2.2 state")
	_expect(str(game.get_meta("v122_battle_plan", {}).get("layout_fingerprint", "")).length() == 64, "legacy save derives v1.2.2 plan from current ModuleGraph")
	_expect(not game.v122_last_confirmed_placements.is_empty(), "legacy save receives safe placement defaults")


func _check_finale_retry_snapshot(game: Node) -> void:
	_configure_day(game, 30, false)
	var plan: Dictionary = game._v122_current_battle_plan()
	game._capture_v122_battle_confirmation(plan)
	var expected_room := _retry_monster_room(game.v122_retry_snapshot, "slime")
	_expect(expected_room != "", "finale retry snapshot records the confirmed monster defense position")
	game.monster_roster["slime"]["room"] = "treasure" if expected_room != "treasure" else "barracks"
	game._prepare_finale_retry()
	_expect(
		str(game.monster_roster.get("slime", {}).get("room", "")) == expected_room,
		"DAY 30 retry restores the last confirmed monster placement"
	)
	_expect(
		GameState.day == 30 and game.current_screen == Constants.SCREEN_MANAGEMENT,
		"DAY 30 retry stays on the final campaign day"
	)


func _check_atomic_recovery(game: Node) -> void:
	_configure_day(game, 29, false)
	var payload: Dictionary = game._campaign_save_payload(Constants.SCREEN_MANAGEMENT)
	var summary: Dictionary = game._campaign_save_summary(Constants.SCREEN_MANAGEMENT)
	_expect(bool(CampaignSaveStore.write(payload, summary, TEST_SAVE_PATH).get("ok", false)), "atomic recovery fixture write")
	var valid_raw := _read_raw(TEST_SAVE_PATH)

	var invalid_payload := payload.duplicate(true)
	invalid_payload["v122_battle_plan"]["schema_version"] = 99
	var rejected := CampaignSaveStore.write(invalid_payload, summary, TEST_SAVE_PATH)
	_expect(not bool(rejected.get("ok", false)), "invalid migration payload is rejected")
	_expect(_read_raw(TEST_SAVE_PATH) == valid_raw, "rejected migration leaves the previous save unchanged")

	var backup_path := "%s.bak" % TEST_SAVE_PATH
	_expect(_rename(TEST_SAVE_PATH, backup_path), "construct valid .bak interruption fixture")
	var recovered := CampaignSaveStore.inspect(TEST_SAVE_PATH)
	_expect(str(recovered.get("status", "")) == CampaignSaveStore.STATUS_VALID and FileAccess.file_exists(TEST_SAVE_PATH), "valid .bak restores the primary save")
	_expect(not FileAccess.file_exists(backup_path), ".bak residue is removed after recovery")

	var temp_path := "%s.tmp" % TEST_SAVE_PATH
	_expect(_rename(TEST_SAVE_PATH, temp_path), "construct valid .tmp interruption fixture")
	recovered = CampaignSaveStore.inspect(TEST_SAVE_PATH)
	_expect(str(recovered.get("status", "")) == CampaignSaveStore.STATUS_VALID and FileAccess.file_exists(TEST_SAVE_PATH), "valid .tmp restores the primary save")
	_expect(not FileAccess.file_exists(temp_path), ".tmp residue is removed after recovery")

	_expect(_write_raw(TEST_SAVE_PATH, "{broken"), "construct corrupt fixture")
	var corrupt := CampaignSaveStore.inspect(TEST_SAVE_PATH)
	_expect(str(corrupt.get("status", "")) == CampaignSaveStore.STATUS_CORRUPT, "corrupt save is blocked")
	_expect(bool(CampaignSaveStore.mark_invalid(TEST_SAVE_PATH, "fixture corruption")), "corrupt original receives an invalid marker")
	_expect(str(CampaignSaveStore.inspect(TEST_SAVE_PATH).get("status", "")) == CampaignSaveStore.STATUS_CORRUPT, "invalid marker keeps continue blocked")


func _check_update4_auxiliary_coexistence(game: Node) -> void:
	_cleanup()
	_configure_day(game, 30, true)
	var modes: Dictionary = game.update4_profile.get("campaign_modes", {}).duplicate(true)
	modes["council_season_unlocked"] = true
	game.update4_profile["campaign_modes"] = modes
	game.update4_active_run["campaign_mode_id"] = CampaignModeService.COUNCIL_MODE_ID
	var council: Dictionary = game.update4_active_run.get("council_season", {}).duplicate(true)
	council["day_state"] = CouncilSeasonService.new_day_state(30)
	game.update4_active_run["council_season"] = council
	game._set_campaign_save_path_for_tests(TEST_SAVE_PATH, TEST_V2_PATH, TEST_V3_PATH, TEST_V4_PATH, TEST_V5_PATH)
	game.current_screen = Constants.SCREEN_ENDING
	var payload: Dictionary = game._campaign_save_payload(Constants.SCREEN_ENDING)
	var summary: Dictionary = game._campaign_save_summary(Constants.SCREEN_ENDING)
	_expect(bool(CampaignSaveStore.write(payload, summary, TEST_SAVE_PATH).get("ok", false)), "Update 4 primary CampaignSaveStore write")
	_expect(game._write_campaign_v2_snapshot(), "existing v1→v5 auxiliary migration chain accepts v1.2.2 payload")
	var legacy_payload: Dictionary = game.campaign_save_v5_envelope.get("active_run", {}).get("legacy_payload", {})
	_expect(legacy_payload.has("v122_battle_plan"), "Update 4 v5 envelope retains the v1.2.2 legacy payload extension")
	_expect(str(legacy_payload.get("v122_battle_plan", {}).get("battle_plan", {}).get("layout_fingerprint", "")).length() == 64, "Update 4 v5 envelope retains the battle plan fingerprint")


func _configure_day(game: Node, day: int, ending: bool) -> void:
	GameState.day = day
	GameState.max_day = 30
	GameState.player_name = "v1.2.2 저장 검증"
	GameState.victory = false
	GameState.defeat = false
	GameState.onboarding_complete = true
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game.tutorial_manager.active = false
	game.result_summary.clear()
	game.rewards_pending.clear()
	game.last_growth_summary.clear()
	game.result_growth_reviewed = false
	game.result_growth_choice_monster_id = ""
	game.result_growth_choice_applied = false
	game.last_growth_choice_summary.clear()

	var stage_ids := ["stage_01_cave"]
	if day >= 16:
		stage_ids.append("stage_02_castle")
	if day >= 21:
		stage_ids.append("stage_03_keep")
	if day >= 28:
		stage_ids.append("stage_04_citadel")
	game.castle_art_stage = stage_ids.back()
	game.castle_evolution_history.assign(stage_ids)
	game.campaign_chapter_one_clear = day >= 11
	game.campaign_stage_two_prepared = day >= 11
	game.campaign_chapter_two_started = day >= 11
	game.campaign_stage_two_upgrade_funded = day >= 15
	game.campaign_stage_two_unlock_ready = day >= 16
	game.campaign_chapter_three_clear = day >= 21
	game.campaign_chapter_four_clear = day >= 26
	game.campaign_final_chapter_unlocked = day >= 26
	game.campaign_final_upgrade_ready = day >= 28
	game.campaign_final_preparation_confirmed = day >= 30
	game.campaign_completed = ending
	game.campaign_final_battle_outcome = "victory" if ending else ""
	game.campaign_finale_defeat_seen = false
	game.campaign_postgame_active = ending
	game.first_promotion_completed = day >= 12
	game.facility_upgrade_unlocked = day >= 7
	game.update2_cycle_seed = 122001
	game.update3_active_run = FrontCampaignService.default_legacy_active_run(game.campaign_cycle_index)
	game.update4_active_run = CampaignModeService.default_active_run()
	game._sync_castle_stage_content()
	game._setup_dungeon_graph()
	game._init_room_directives()
	game.current_screen = Constants.SCREEN_ENDING if ending else Constants.SCREEN_MANAGEMENT


func _growth_row() -> Dictionary:
	return {
		"monster_id": "slime",
		"display_name": "푸딩",
		"level_before": 1,
		"level_after": 2,
		"levels_gained": 1,
		"exp_before": 40,
		"exp_after": 5,
		"exp_gain": 15,
		"next_exp": 75,
		"shared_exp": 10,
		"activity_exp": 5,
		"activity_breakdown": {"attack": 3, "defense": 2}
	}


func _rename(from_path: String, to_path: String) -> bool:
	_remove_path(to_path)
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(from_path), ProjectSettings.globalize_path(to_path)) == OK


func _read_raw(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var result := file.get_as_text()
	file.close()
	return result


func _write_raw(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.close()
	return true


func _cleanup() -> void:
	for path in [TEST_SAVE_PATH, TEST_V2_PATH, TEST_V3_PATH, TEST_V4_PATH, TEST_V5_PATH]:
		for suffix in ["", ".tmp", ".bak", ".invalid", ".unrestorable", ".delete_pending"]:
			_remove_path("%s%s" % [path, suffix])


func _remove_path(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _settle(frame_count: int) -> void:
	for _index in range(frame_count):
		await get_tree().process_frame


func _contains_key_recursive(value, target_key: String) -> bool:
	if value is Dictionary:
		if value.has(target_key):
			return true
		for child_value in value.values():
			if _contains_key_recursive(child_value, target_key):
				return true
	elif value is Array:
		for child_value in value:
			if _contains_key_recursive(child_value, target_key):
				return true
	return false


func _retry_monster_room(retry_snapshot: Dictionary, monster_instance_id: String) -> String:
	for value in retry_snapshot.get("monster_placements", []):
		if value is Dictionary and str(value.get("monster_instance_id", "")) == monster_instance_id:
			return str(value.get("room_id", ""))
	return ""


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
