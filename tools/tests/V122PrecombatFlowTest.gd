extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameRootScene.instantiate()
	add_child(game)
	await _settle(4)
	game.campaign_save_enabled = false
	game._debug_skip_onboarding()
	_configure_day_one(game)

	var preview: Dictionary = game.combat_scene.build_precombat_snapshot()
	_expect(not preview.is_empty(), "precombat snapshot is created from the product runtime")
	_expect(not preview.get("schedule", []).is_empty(), "precombat snapshot contains the actual wave schedule")
	_expect(not preview.get("telegraphs", []).is_empty(), "precombat snapshot contains actual encounter telegraphs")
	_expect(str(preview.get("layout_fingerprint", "")).length() == 64, "precombat snapshot has the product layout fingerprint")

	game._open_intrusion_brief()
	_expect(game.current_screen == Constants.SCREEN_INTRUSION_BRIEF, "intrusion brief opens as its own product screen")
	_expect(not game.intrusion_brief_snapshot.get("schedule", []).is_empty(), "intrusion brief receives the actual wave schedule")
	_expect(not game.intrusion_brief_snapshot.get("telegraphs", []).is_empty(), "intrusion brief receives actual encounter telegraphs")
	game._enter_placement_from_brief()
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "intrusion brief proceeds to placement management")

	var unchanged_state := _gameplay_state(game)
	game._request_combat_start()
	_expect(game.current_screen == Constants.SCREEN_DEFENSE_START, "combat request opens the defense-start countdown")
	_expect(not game.pending_precombat_snapshot.is_empty(), "defense-start countdown freezes a precombat snapshot")
	var cancel_snapshot: Dictionary = game.pending_precombat_snapshot.duplicate(true)

	game._tick_defense_start_countdown(2.9)
	_expect(game.current_screen == Constants.SCREEN_DEFENSE_START, "2.9 seconds does not commit combat")
	_expect(game.defense_start_remaining > 0.0, "countdown retains time before the three-second boundary")
	_expect(game.pending_precombat_snapshot == cancel_snapshot, "countdown does not replace the frozen snapshot")
	_expect_gameplay_state(game, unchanged_state, "2.9-second countdown")

	game._cancel_defense_start()
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "countdown cancel returns to management")
	_expect(game.pending_precombat_snapshot.is_empty(), "countdown cancel clears only the pending snapshot")
	_expect_gameplay_state(game, unchanged_state, "countdown cancel")

	game._request_combat_start()
	_expect(game.current_screen == Constants.SCREEN_DEFENSE_START, "combat can be requested again after cancel")
	var committed_snapshot: Dictionary = game.pending_precombat_snapshot.duplicate(true)
	_expect(not committed_snapshot.get("schedule", []).is_empty(), "committed snapshot retains its frozen schedule")
	_expect(not committed_snapshot.get("telegraphs", []).is_empty(), "committed snapshot retains its frozen telegraphs")

	game._tick_defense_start_countdown(3.0)
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "three-second countdown commits combat")
	_expect(game.wave_manager.schedule == committed_snapshot.get("schedule", []), "combat uses the frozen precombat schedule")
	var runtime_plan: Dictionary = game.get_meta("v122_battle_plan", {})
	var committed_fingerprint := str(committed_snapshot.get("layout_fingerprint", ""))
	_expect(str(runtime_plan.get("layout_fingerprint", "")) == committed_fingerprint, "combat uses the frozen battle-plan fingerprint")
	_expect(int(game.v122_retry_snapshot.get("day", 0)) == GameState.day, "commit captures a retry snapshot for the current day")
	_expect(str(game.v122_retry_snapshot.get("layout_fingerprint", "")) == committed_fingerprint, "retry snapshot uses the frozen battle-plan fingerprint")
	_expect(game.pending_precombat_snapshot.is_empty(), "commit clears the transient pending snapshot")

	game.queue_free()
	await _settle(2)
	if failed:
		print("V122_PRECOMBAT_FLOW_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V122_PRECOMBAT_FLOW_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _configure_day_one(game: Node) -> void:
	GameState.day = 1
	GameState.max_day = 30
	GameState.player_name = "precombat-flow-test"
	GameState.victory = false
	GameState.defeat = false
	GameState.onboarding_complete = true
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game.tutorial_manager.active = false
	game.campaign_postgame_active = false
	game.result_summary.clear()
	game.rewards_pending.clear()
	game.pending_precombat_snapshot.clear()
	game.intrusion_brief_snapshot.clear()
	game.defense_start_remaining = 0.0
	game.defense_start_last_second = -1
	game._setup_dungeon_graph()
	game._init_room_directives()
	game._set_screen(Constants.SCREEN_MANAGEMENT)


func _gameplay_state(game: Node) -> Dictionary:
	return {
		"rooms": game.rooms.duplicate(true),
		"monster_roster": game.monster_roster.duplicate(true),
		"resources": {
			"gold": GameState.gold,
			"mana": GameState.mana,
			"food": GameState.food,
			"infamy": GameState.infamy,
			"demon_lord_hp": GameState.demon_lord_hp,
			"demon_lord_max_hp": GameState.demon_lord_max_hp
		},
		"global_directive": game.global_directive,
		"room_directives": game.room_directives.duplicate(true),
		"next_defense_modifiers": game.next_defense_modifiers.duplicate(true),
		"active_defense_modifiers": game._active_defense_modifiers().duplicate(true),
		"retry_snapshot": game.v122_retry_snapshot.duplicate(true)
	}


func _expect_gameplay_state(game: Node, expected: Dictionary, prefix: String) -> void:
	var actual := _gameplay_state(game)
	_expect(actual.get("rooms", {}) == expected.get("rooms", {}), "%s preserves rooms and facilities" % prefix)
	_expect(actual.get("monster_roster", {}) == expected.get("monster_roster", {}), "%s preserves the monster roster and placements" % prefix)
	_expect(actual.get("resources", {}) == expected.get("resources", {}), "%s preserves resources and throne health" % prefix)
	_expect(actual.get("global_directive", "") == expected.get("global_directive", ""), "%s preserves the global directive" % prefix)
	_expect(actual.get("room_directives", {}) == expected.get("room_directives", {}), "%s preserves room directives" % prefix)
	_expect(actual.get("next_defense_modifiers", {}) == expected.get("next_defense_modifiers", {}), "%s preserves pending defense modifiers" % prefix)
	_expect(actual.get("active_defense_modifiers", {}) == expected.get("active_defense_modifiers", {}), "%s preserves active defense modifiers" % prefix)
	_expect(actual.get("retry_snapshot", {}) == expected.get("retry_snapshot", {}), "%s preserves the retry snapshot" % prefix)


func _settle(frame_count: int) -> void:
	for _index in range(frame_count):
		await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		return
	failed = true
	push_error(message)
