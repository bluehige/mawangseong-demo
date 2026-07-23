extends Node

const SpatialModel = preload("res://scripts/v20/spatial/V20SpatialModel.gd")
const ModuleGraphScript = preload("res://scripts/dungeon_quarter/ModuleGraph.gd")
const PlacementService = preload("res://scripts/v20/placement/V20PlacementService.gd")
const SessionService = preload("res://scripts/v20/session/V20SessionService.gd")
const SaveStore = preload("res://scripts/v20/save/V20SaveStore.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const DEFENSE_ZONE_IDS := ["gate_outpost", "spike_corridor", "central_battle_room", "throne_anteroom"]
const LEGACY_ZONE_IDS := ["entrance", "north_gate", "north_cross", "south_gate", "south_cross", "treasure", "barracks", "fallback"]
const EXPECTED_GEOMETRY := {
	"gate_outpost": {"origin": [2, 14], "footprint": [5, 5]},
	"spike_corridor": {"origin": [9, 14], "footprint": [5, 5]},
	"central_battle_room": {"origin": [9, 7], "footprint": [12, 5]},
	"throne_anteroom": {"origin": [23, 7], "footprint": [5, 5]},
	"throne": {"origin": [23, 0], "footprint": [5, 5]}
}

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_exact_spatial_contract()
	_test_module_graph_lookup()
	_test_all_twelve_slots_save_restore()
	_test_one_time_v2_migration()
	await _test_product_autosave_isolation()
	await _test_preparation_to_combat_positions()
	if failed:
		print("V20_UNIFIED_SPATIAL_MODEL_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V20_UNIFIED_SPATIAL_MODEL_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_exact_spatial_contract() -> void:
	var board := _board()
	_expect(int(board.get("schema_version", 0)) == 3 and _vector2i(board.get("spatial_header", {}).get("active_grid_size", [])) == Vector2i(28, 26), "공간 schema 3 및 active grid 28×26")
	_expect(_vector2i(board.get("spatial_header", {}).get("tile_size", [])) == Vector2i(128, 64) and _vector2i(board.get("spatial_header", {}).get("room_cell_size", [])) == Vector2i(5, 5) and _vector2i(board.get("spatial_header", {}).get("gap_size", [])) == Vector2i(2, 2) and _vector2i(board.get("spatial_header", {}).get("stride", [])) == Vector2i(7, 7), "tile 128×64·room 5×5·gap 2·stride 7")
	_expect(SpatialModel.zone_ids(board) == ["gate_outpost", "spike_corridor", "central_battle_room", "throne_anteroom", "throne"], "canonical 구역 5개 순서 고정")
	_expect(board.get("fixed_route", {}).get("nodes", []) == SpatialModel.zone_ids(board), "침입 경로가 canonical 구역 순서와 동일")
	for zone_id in SpatialModel.zone_ids(board):
		var zone := SpatialModel.zone(board, zone_id)
		var expected: Dictionary = EXPECTED_GEOMETRY.get(zone_id, {})
		_expect(_vector2i(zone.get("logical_origin", [])) == _vector2i(expected.get("origin", [])) and _vector2i(zone.get("module_footprint", [])) == _vector2i(expected.get("footprint", [])), "%s origin·footprint 계약 일치" % zone_id)
		var logical: Array = zone.get("logical_anchor", [])
		var world: Array = zone.get("world_anchor", [])
		var projected := SpatialModel.logical_to_world(board, Vector2(float(logical[0]), float(logical[1])))
		var declared := Vector2(float(world[0]), float(world[1]))
		_expect(projected.distance_to(declared) <= 0.01, "%s logical→world 오차 0.01px 이하" % zone_id)
		var round_trip := SpatialModel.world_to_logical(board, declared)
		_expect(round_trip.distance_to(Vector2(float(logical[0]), float(logical[1]))) <= 0.01, "%s world→logical 왕복 오차 0.01 cell 이하" % zone_id)
	var slots := SpatialModel.all_slots(board)
	var slot_ids: Dictionary = {}
	for slot_value in slots:
		var slot: Dictionary = slot_value
		slot_ids[str(slot.get("slot_id", ""))] = true
		_expect(DEFENSE_ZONE_IDS.has(str(slot.get("slot_zone", ""))), "%s는 방어 구역 소유 슬롯" % str(slot.get("slot_id", "")))
	_expect(slots.size() == 12 and slot_ids.size() == 12, "시설 4·몬스터 8, 중복 없는 슬롯 12개")
	_expect(SpatialModel.zone(board, "throne").get("facility_slot", {}).is_empty() and SpatialModel.zone(board, "throne").get("monster_slots", []).is_empty(), "throne에는 배치 슬롯 0개")


func _test_module_graph_lookup() -> void:
	var graph = ModuleGraphScript.new()
	graph.setup_quarter(DataRegistry.quarter_modules, DataRegistry.quarter_layout(DataRegistry.V20_RUNTIME_LAYOUT_ID), DataRegistry.rooms)
	_expect(bool(graph.validation_summary().get("ok", false)), "canonical ModuleGraph 물리 연결 검증 통과")
	_expect(graph.canonical_zone_ids() == SpatialModel.zone_ids(_board()), "ModuleGraph와 준비 보드의 zone ID 순서 일치")
	for slot_value in SpatialModel.all_slots(_board()):
		var slot: Dictionary = slot_value
		var slot_id := str(slot.get("slot_id", ""))
		var world: Array = slot.get("world_anchor", [])
		var expected := Vector2(float(world[0]), float(world[1]))
		_expect(graph.canonical_zone_for_slot(slot_id) == str(slot.get("slot_zone", "")) and graph.canonical_slot_world_position(slot_id).distance_to(expected) <= 0.01, "%s 준비 소유 구역·전투 좌표 일치" % slot_id)


func _test_all_twelve_slots_save_restore() -> void:
	for zone_id in DEFENSE_ZONE_IDS:
		var session := SessionService.new_session("v20_tactician", DataRegistry.v20_economy, DataRegistry.v20_onboarding)
		var source_rooms: Dictionary = session.get("placement_state", {}).get("rooms", {}).duplicate(true)
		for room_id in source_rooms.keys():
			source_rooms[room_id]["facility_id"] = ""
			source_rooms[room_id]["monster_ids"] = []
		var placement := PlacementService.new_state(20, source_rooms, {
			"slot_probe_a": {"display_name": "slot probe A", "room_id": "", "monster_slot_id": ""},
			"slot_probe_b": {"display_name": "slot probe B", "room_id": "", "monster_slot_id": ""}
		})
		placement = PlacementService.place_facility_drag(placement, "v20_barricade", zone_id, DataRegistry.v20_facilities).get("state", {})
		placement = PlacementService.place_monster_drag(placement, "slot_probe_a", zone_id).get("state", {})
		placement = PlacementService.place_monster_drag(placement, "slot_probe_b", zone_id).get("state", {})
		session["placement_state"] = placement
		var path := "user://tests/v20_spatial_slots_%s.json" % zone_id
		SaveStore.delete(path)
		var summary := {"day": 1, "difficulty_id": "v20_tactician", "difficulty_name": "test", "checkpoint": zone_id, "completed": false}
		var written := SaveStore.write(SessionService.save_payload(session), summary, path)
		var inspected := SaveStore.inspect(path)
		var restored := SessionService.restore(inspected.get("payload", {}), DataRegistry.v20_economy)
		var restored_placement: Dictionary = restored.get("state", {}).get("placement_state", {})
		var zone := SpatialModel.zone(_board(), zone_id)
		var monster_slots: Array = zone.get("monster_slots", [])
		_expect(bool(written.get("ok", false)) and bool(restored.get("ok", false)), "%s 시설 1·몬스터 2 배치 저장·복원" % zone_id)
		_expect(str(restored_placement.get("rooms", {}).get(zone_id, {}).get("facility_slot_id", "")) == str(zone.get("facility_slot", {}).get("slot_id", "")), "%s facility slot 복원" % zone_id)
		_expect(str(restored_placement.get("roster", {}).get("slot_probe_a", {}).get("monster_slot_id", "")) == str(monster_slots[0].get("slot_id", "")) and str(restored_placement.get("roster", {}).get("slot_probe_b", {}).get("monster_slot_id", "")) == str(monster_slots[1].get("slot_id", "")), "%s monster slot 2개 복원" % zone_id)
		SaveStore.delete(path)


func _test_one_time_v2_migration() -> void:
	var path := "user://tests/v20_spatial_migration_v2.json"
	SaveStore.delete(path)
	var session := SessionService.new_session("v20_tactician", DataRegistry.v20_economy, DataRegistry.v20_onboarding)
	var payload := SessionService.save_payload(session)
	payload["schema_version"] = 2
	var canonical_rooms: Dictionary = payload.get("placement", {}).get("rooms", {})
	payload["placement"]["rooms"] = {
		"north_gate": canonical_rooms.get("gate_outpost", {}).duplicate(true),
		"south_gate": canonical_rooms.get("spike_corridor", {}).duplicate(true),
		"treasure": canonical_rooms.get("central_battle_room", {}).duplicate(true),
		"fallback": canonical_rooms.get("throne_anteroom", {}).duplicate(true)
	}
	payload["placement"]["roster"]["slime"]["room_id"] = "north_gate"
	payload["placement"]["roster"]["goblin"]["room_id"] = "treasure"
	payload["placement"]["roster"]["imp"]["room_id"] = "fallback"
	payload["last_result"] = {"zone_id": "treasure", "route_nodes": ["entrance", "north_gate", "south_gate", "treasure", "fallback", "throne"]}
	var summary := {"day": 1, "difficulty_id": "v20_tactician", "difficulty_name": "test", "checkpoint": "legacy", "completed": false}
	_write_raw_json(path, {"version": 2, "saved_at_unix": 1, "saved_at_text": "legacy", "summary": summary, "payload": payload})
	var first := SaveStore.inspect(path)
	var second := SaveStore.inspect(path)
	_expect(str(first.get("status", "")) == SaveStore.STATUS_VALID and int(first.get("migration_count", 0)) == 1, "schema 2 저장 첫 로드에서 migration_count 1")
	var normalized_first = JSON.parse_string(JSON.stringify(first.get("payload", {})))
	_expect(int(second.get("migration_count", -1)) == 0 and second.get("payload", {}) == normalized_first, "두 번째 로드는 재마이그레이션 없이 동일 payload")
	_expect(not _has_legacy_zone_field(first.get("payload", {})), "마이그레이션 뒤 방·경로·결과 zone field에 구 ID 0개")
	_expect(str(first.get("payload", {}).get("placement", {}).get("roster", {}).get("slime", {}).get("monster_slot_id", "")) == "gate_outpost_monster_1", "schema 2 slime에 gate_outpost_monster_1 배정")
	SaveStore.delete(path)


func _test_product_autosave_isolation() -> void:
	var paths := ["user://tests/v20_product_save_v1.json", "user://tests/v20_product_save_v2.json", "user://tests/v20_product_save_v3.json", "user://tests/v20_product_save_v4.json", "user://tests/v20_product_save_v5.json"]
	for path in paths:
		_delete_path(path)
	var game_root = GameRootScene.instantiate()
	add_child(game_root)
	await get_tree().process_frame
	game_root._set_campaign_save_path_for_tests(paths[0], paths[1], paths[2], paths[3], paths[4])
	for index in range(paths.size()):
		_write_raw_text(paths[index], "{\"sentinel\":%d}" % (index + 1))
	game_root._v20_set_save_path_for_tests("user://tests/v20_autosave_isolation.json")
	SaveStore.delete("user://tests/v20_autosave_isolation.json")
	game_root._v20_start_new_session("v20_tactician")
	game_root._schedule_campaign_autosave(game_root.current_screen)
	var flush_while_v20: bool = game_root._flush_campaign_autosave()
	var changed_paths: Array[String] = []
	for index in range(paths.size()):
		if FileAccess.get_file_as_string(paths[index]) != "{\"sentinel\":%d}" % (index + 1):
			changed_paths.append(paths[index])
	_expect(not flush_while_v20, "v2.0 활성 중 제품 자동저장 flush가 false 반환")
	_expect(changed_paths.is_empty(), "v2.0 활성 중 제품 v1~v5 자동저장 파일 byte 변경 0: %s" % [changed_paths])
	game_root.v20_session["active"] = false
	game_root._set_campaign_save_path_for_tests(paths[0])
	game_root.current_screen = Constants.SCREEN_MANAGEMENT
	game_root._schedule_campaign_autosave(Constants.SCREEN_MANAGEMENT)
	var resumed: bool = game_root._flush_campaign_autosave()
	_expect(resumed and FileAccess.get_file_as_string(paths[0]) != "{\"sentinel\":1}", "v2.0 종료 뒤 제품 자동저장이 v1 경로에 실제 기록")
	game_root.queue_free()
	await get_tree().process_frame
	for path in paths:
		_delete_path(path)
	SaveStore.delete("user://tests/v20_autosave_isolation.json")


func _test_preparation_to_combat_positions() -> void:
	var save_path := "user://tests/v20_preparation_to_combat.json"
	SaveStore.delete(save_path)
	var game_root = GameRootScene.instantiate()
	game_root._v20_set_save_path_for_tests(save_path)
	add_child(game_root)
	await get_tree().process_frame
	game_root._v20_start_new_session("v20_tactician")
	game_root._v20_start_placement()
	var placement: Dictionary = game_root._v20_placement_state()
	var result := PlacementService.place_monster_drag(placement, "slime", "spike_corridor")
	game_root._v20_update_placement_state(result.get("state", {}), result)
	placement = game_root._v20_placement_state()
	result = PlacementService.place_monster_drag(placement, "goblin", "central_battle_room")
	game_root._v20_update_placement_state(result.get("state", {}), result)
	placement = game_root._v20_placement_state()
	result = PlacementService.place_monster_drag(placement, "imp", "throne_anteroom")
	game_root._v20_update_placement_state(result.get("state", {}), result)
	if OS.get_cmdline_user_args().has("--capture-v20-spatial") and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(Vector2i(1280, 720))
		game_root._set_screen(Constants.SCREEN_MANAGEMENT)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		_capture_window("user://v20_spatial_preparation_1280x720.png", "V20_SPATIAL_PREPARATION_CAPTURE")
	game_root._v20_request_defense_start()
	game_root._v20_advance_defense_countdown(3.0)
	game_root.combat_paused = true
	if OS.get_cmdline_user_args().has("--capture-v20-spatial") and DisplayServer.get_name() != "headless":
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		_capture_window("user://v20_spatial_combat_1280x720.png", "V20_SPATIAL_COMBAT_CAPTURE")
	var matched := 0
	for unit in game_root.monster_units:
		var monster_id := str(unit.unit_id)
		if not ["slime", "goblin", "imp"].has(monster_id):
			continue
		var roster: Dictionary = game_root.monster_roster.get(monster_id, {})
		var slot_id := str(roster.get("monster_slot_id", ""))
		var expected: Vector2 = game_root._clamp_to_combat_walkable(game_root.graph.canonical_slot_world_position(slot_id))
		var zone_id := str(roster.get("room", ""))
		if unit.global_position.distance_to(expected) <= 0.01 and str(unit.current_room) == zone_id and game_root.graph.canonical_zone_for_slot(slot_id) == zone_id:
			matched += 1
	_expect(matched == 3, "준비에서 배치한 slime·goblin·imp 방·slot 좌표가 전투 spawn과 0.01px 이내 일치")
	_expect(str(game_root.monster_roster.get("slime", {}).get("monster_slot_id", "")) == "spike_corridor_monster_1" and str(game_root.monster_roster.get("goblin", {}).get("monster_slot_id", "")) == "central_battle_room_monster_1" and str(game_root.monster_roster.get("imp", {}).get("monster_slot_id", "")) == "throne_anteroom_monster_1", "실전투 roster가 준비 단계의 세 monster slot ID 유지")
	game_root.queue_free()
	await get_tree().process_frame
	SaveStore.delete(save_path)


func _board() -> Dictionary:
	return DataRegistry.v20_dungeon_layouts.get(SpatialModel.BOARD_ID, {}).duplicate(true)


func _vector2i(value) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1])) if value is Array and value.size() >= 2 else Vector2i.ZERO


func _write_raw_json(path: String, value: Dictionary) -> void:
	_write_raw_text(path, JSON.stringify(value, "\t"))


func _capture_window(path: String, marker: String) -> void:
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path) if image != null and not image.is_empty() else ERR_CANT_CREATE
	_expect(error == OK and DisplayServer.window_get_size() == Vector2i(1280, 720), "%s 실제 창 1280×720 PNG 저장" % marker)
	if error == OK:
		print("%s: %s" % [marker, ProjectSettings.globalize_path(path)])


func _write_raw_text(path: String, value: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(value)
		file.close()


func _delete_path(path: String) -> void:
	for candidate in [path, "%s.tmp" % path, "%s.bak" % path]:
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))


func _has_legacy_zone_field(value) -> bool:
	if value is Array:
		for item in value:
			if _has_legacy_zone_field(item):
				return true
		return false
	if not (value is Dictionary):
		return false
	for key_value in value.keys():
		var key := str(key_value)
		var item = value.get(key_value)
		if SaveStore.ZONE_VALUE_KEYS.has(key) and item is String and LEGACY_ZONE_IDS.has(str(item)):
			return true
		if SaveStore.ZONE_ARRAY_KEYS.has(key) and item is Array:
			for zone_value in item:
				if LEGACY_ZONE_IDS.has(str(zone_value)):
					return true
		if _has_legacy_zone_field(item):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[V20UnifiedSpatialModel] FAIL: %s" % message)
