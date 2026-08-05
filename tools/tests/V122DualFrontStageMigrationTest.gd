extends Node

const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const SaveProgressionAdapter = preload("res://scripts/v122/save/V122SaveProgressionAdapter.gd")
const LAYOUT_ID := "stage01_dual_front_candidate_01"
const LAYOUT_PATH := "res://data/dungeon_quarter/layouts/stage01_dual_front_01.json"

var failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	var layout = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT_PATH))
	_expect(layout is Dictionary, "candidate stage migration layout loads")
	if not layout is Dictionary:
		_finish()
		return

	var game := GameRootScene.instantiate()
	add_child(game)
	await _settle(4)
	game.campaign_save_enabled = false
	game._debug_skip_onboarding()
	DataRegistry.register_quarter_layout(LAYOUT_ID, layout, false)
	game.quarter_layout_id = LAYOUT_ID
	game.update3_active_run["update3_enabled"] = true
	game.update3_active_run["front_selection_completed"] = true
	game.update3_active_run["front_id"] = "front_stage_migration_test"

	var stages := [
		{
			"id": "stage_01_cave",
			"day": 1,
			"rooms": [],
			"facility_count": 4,
			"grid_size": Vector2i(28, 26)
		},
		{
			"id": "stage_02_castle",
			"day": 16,
			"rooms": ["heart_chamber", "watch_post_01"],
			"facility_count": 5,
			"grid_size": Vector2i(28, 26)
		},
		{
			"id": "stage_03_keep",
			"day": 21,
			"rooms": ["heart_chamber", "watch_post_01", "ward_core_01", "slot_02"],
			"facility_count": 7,
			"grid_size": Vector2i(28, 33)
		},
		{
			"id": "stage_04_citadel",
			"day": 30,
			"rooms": [
				"heart_chamber",
				"watch_post_01",
				"ward_core_01",
				"slot_02",
				"elite_garrison_01",
				"slot_03"
			],
			"facility_count": 9,
			"grid_size": Vector2i(28, 33)
		}
	]
	var baseline_lane_routes: Dictionary = {}
	var final_plan: Dictionary = {}
	for stage_value in stages:
		var stage: Dictionary = stage_value
		game.castle_art_stage = str(stage.get("id", ""))
		GameState.day = int(stage.get("day", 1))
		game.rooms = DataRegistry.rooms.duplicate(true)
		game._sync_castle_stage_content()
		game._setup_dungeon_graph()
		var validation: Dictionary = game.graph.validation_summary()
		_expect(
			bool(validation.get("ok", false)),
			"%s candidate graph has no overlap or socket error: %s" % [stage.get("id", ""), validation]
		)
		_expect(
			game.graph.debug_tile_grid_size() == stage.get("grid_size"),
			"%s uses its declared candidate grid bounds" % stage.get("id", "")
		)
		for room_id_value in stage.get("rooms", []):
			var room_id := str(room_id_value)
			_expect(
				game.graph.module_instance_ids().has(room_id),
				"%s preserves legacy room %s on candidate geometry" % [stage.get("id", ""), room_id]
			)
		var plan: Dictionary = game._v122_current_battle_plan()
		_expect(
			plan.get("facility_slot_contracts", []).size() == int(stage.get("facility_count", 0)),
			"%s exposes every unlocked facility as a replaceable slot" % stage.get("id", "")
		)
		if baseline_lane_routes.is_empty():
			baseline_lane_routes = plan.get("lane_routes", {}).duplicate(true)
		else:
			_expect(
				plan.get("lane_routes", {}) == baseline_lane_routes,
				"%s keeps both fixed main lanes unchanged" % stage.get("id", "")
			)
		if str(stage.get("id", "")) != "stage_01_cave":
			_expect(
				not game.graph.module_instance_ids().has("stage_path_east_01")
					and not game.graph.module_instance_ids().has("stage_path_east_02"),
				"%s does not import overlapping legacy stage paths" % stage.get("id", "")
			)
		if str(stage.get("id", "")) == "stage_04_citadel":
			final_plan = plan.duplicate(true)

	_check_legacy_placement_migration(final_plan, game.rooms)
	game.queue_free()
	await _settle(2)
	_finish()


func _check_legacy_placement_migration(candidate_plan: Dictionary, rooms: Dictionary) -> void:
	var expected_slots := {
		"watch_post_01": "facility_b_watch",
		"ward_core_01": "facility_b_ward",
		"slot_02": "facility_b_stage3",
		"elite_garrison_01": "facility_b_elite",
		"slot_03": "facility_b_stage4"
	}
	var expected_zones := {
		"watch_post_01": "zone_b_rear",
		"ward_core_01": "zone_b_front",
		"slot_02": "zone_b_rear",
		"elite_garrison_01": "zone_b_front",
		"slot_03": "zone_b_front"
	}
	var legacy_facilities: Array = []
	var legacy_monsters: Array = []
	var roster := {}
	var index := 0
	for room_id_value in expected_slots.keys():
		var room_id := str(room_id_value)
		legacy_facilities.append({
			"slot_id": "facility:%s" % room_id,
			"room_id": room_id,
			"facility_role": str(rooms.get(room_id, {}).get("facility_role", "build_slot"))
		})
		var monster_id := "legacy_monster_%d" % index
		legacy_monsters.append({
			"monster_instance_id": monster_id,
			"room_id": room_id,
			"slot_id": "monster:%s:0" % room_id
		})
		roster[monster_id] = {"room": "entrance"}
		index += 1
	var legacy_plan := candidate_plan.duplicate(true)
	legacy_plan["facility_slot_contracts"] = []
	legacy_plan["facility_slots"] = []
	legacy_plan["defense_zones"] = []
	legacy_plan["lane_routes"] = {}
	var legacy_state := {
		"schema_version": 1,
		"battle_plan": legacy_plan,
		"facility_placements": legacy_facilities.duplicate(true),
		"monster_placements": legacy_monsters.duplicate(true),
		"last_confirmed_placements": {
			"layout_id": "legacy_stage04",
			"layout_fingerprint": "b".repeat(64),
			"facility_placements": legacy_facilities.duplicate(true),
			"monster_placements": legacy_monsters.duplicate(true)
		},
		"retry_snapshot": {
			"day": 30,
			"layout_id": "legacy_stage04",
			"layout_fingerprint": "b".repeat(64),
			"facility_placements": legacy_facilities.duplicate(true),
			"monster_placements": legacy_monsters.duplicate(true),
			"global_directive": "guard",
			"room_directives": {}
		}
	}
	var normalized := SaveProgressionAdapter.normalize(legacy_state, candidate_plan)
	for room_id_value in expected_slots.keys():
		var room_id := str(room_id_value)
		var facility := _facility_placement_for_room(
			normalized.get("facility_placements", []),
			room_id
		)
		_expect(
			str(facility.get("facility_slot_id", "")) == str(expected_slots.get(room_id, "")),
			"legacy facility %s maps to its stable candidate slot" % room_id
		)
		var monster := _monster_placement_for_room(
			normalized.get("monster_placements", []),
			room_id
		)
		_expect(
			str(monster.get("defense_zone_id", "")) == str(expected_zones.get(room_id, "")),
			"legacy monster in %s maps to the linked candidate defense zone" % room_id
		)
		_expect(
			str(monster.get("slot_id", "")).begins_with(
				"monster:%s:" % str(expected_zones.get(room_id, ""))
			),
			"legacy monster slot in %s becomes a candidate zone slot" % room_id
		)
	var restored := SaveProgressionAdapter.apply_retry_snapshot(
		normalized.get("retry_snapshot", {}),
		rooms,
		roster,
		"defense",
		{},
		candidate_plan
	)
	for monster_value in normalized.get("monster_placements", []):
		var monster: Dictionary = monster_value
		var monster_id := str(monster.get("monster_instance_id", ""))
		var restored_member: Dictionary = restored.get("monster_roster", {}).get(monster_id, {})
		_expect(
			str(restored_member.get("room", "")) == str(monster.get("room_id", ""))
				and str(restored_member.get("defense_zone_id", ""))
					== str(monster.get("defense_zone_id", "")),
			"retry restores %s to the migrated room and defense zone" % monster_id
		)
	_expect(
		SaveProgressionAdapter.validate_optional_payload({"v122_battle_plan": normalized}) == "",
		"migrated Stage 4 candidate save remains schema-valid"
	)


func _facility_placement_for_room(values: Array, room_id: String) -> Dictionary:
	for value in values:
		if value is Dictionary and str(value.get("room_id", "")) == room_id:
			return value
	return {}


func _monster_placement_for_room(values: Array, room_id: String) -> Dictionary:
	for value in values:
		if value is Dictionary and str(value.get("room_id", "")) == room_id:
			return value
	return {}


func _settle(frames: int) -> void:
	for _index in range(frames):
		await get_tree().process_frame


func _finish() -> void:
	if failed:
		print("V122_DUAL_FRONT_STAGE_MIGRATION_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("V122_DUAL_FRONT_STAGE_MIGRATION_TEST: PASS")
		get_tree().quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
