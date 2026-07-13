extends Node

const MainScene = preload("res://scenes/main/Main.tscn")
const FrontServiceScript = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const HeartServiceScript = preload("res://scripts/systems/hearts/HeartChamberService.gd")
const SaveV1ToV2MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV1ToV2.gd")
const SaveV2ToV3MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV2ToV3.gd")
const SaveV4MigratorScript = preload("res://scripts/systems/save/SaveV3ToV4Migrator.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_service_contract()
	await _test_game_integration()
	_test_v4_round_trip()
	if failed:
		print("HEART_CHAMBER_PHASE4_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("HEART_CHAMBER_PHASE4_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _selected_run() -> Dictionary:
	var selection := FrontServiceScript.select_front(
		FrontServiceScript.default_update3_profile(),
		FrontServiceScript.new_cycle_active_run(2),
		FrontServiceScript.HERO_FRONT_ID,
		DataRegistry.update3_fronts
	)
	return selection.get("active_run", {}).duplicate(true)


func _test_service_contract() -> void:
	var selected := _selected_run()
	var legacy := FrontServiceScript.default_legacy_active_run()
	_expect(DataRegistry.quarter_modules.has(HeartServiceScript.MODULE_ID), "심장실 5x5 모듈 로드")
	_expect(not HeartServiceScript.should_spawn(legacy, 4), "기존 v3 레온 회차에는 심장실 없음")
	_expect(not HeartServiceScript.should_spawn(selected, 1), "Stage 01에는 심장실 없음")
	_expect(HeartServiceScript.should_spawn(selected, 2), "전선 선택 Stage 02에 심장실 배치")
	for pair in [[2, 420], [3, 600], [4, 820]]:
		var synced := HeartServiceScript.sync_active_run(selected, pair[0])
		_expect(int(synced.get("heart", {}).get("chamber_hp", 0)) == pair[1], "Stage %02d 심장실 HP %d" % [pair[0], pair[1]])
	var stage2 := HeartServiceScript.sync_active_run(selected, 2)
	_expect(HeartServiceScript.enemy_goal(stage2) == HeartServiceScript.ROOM_ID, "임시 적 목표가 살아 있는 심장실")
	var damaged := HeartServiceScript.damage(stage2, 9999)
	_expect(bool(damaged.get("disabled", false)) and not bool(damaged.get("castle_defeat", true)), "심장실 HP 0은 마왕성 패배가 아님")
	_expect(HeartServiceScript.enemy_goal(damaged.get("active_run", {})) == "throne", "심장실 비활성 후 원래 왕좌 목표 복귀")


func _test_game_integration() -> void:
	var host = MainScene.instantiate()
	add_child(host)
	await get_tree().process_frame
	var game = host.get_node("GameRoot")
	game._set_campaign_save_path_for_tests("")
	var selected := _selected_run()
	var stage_ids := ["stage_02_castle", "stage_03_keep", "stage_04_citadel"]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp/update3_phase4"))
	for index in range(stage_ids.size()):
		game.castle_art_stage = stage_ids[index]
		game.rooms = DataRegistry.rooms.duplicate(true)
		game._init_room_facilities()
		game.update3_active_run = selected.duplicate(true)
		game._sync_castle_stage_content()
		game._setup_dungeon_graph()
		var stage_number := index + 2
		var expected_hp := HeartServiceScript.hp_for_stage(stage_number)
		_expect(game.rooms.has(HeartServiceScript.ROOM_ID), "Stage %02d 심장실 방 생성" % stage_number)
		_expect(int(game.rooms.get(HeartServiceScript.ROOM_ID, {}).get("hp", 0)) == expected_hp, "Stage %02d 방 HP 동기화" % stage_number)
		_expect(int(game.rooms.get(HeartServiceScript.ROOM_ID, {}).get("max_monsters", 0)) == 1, "심장실 배치 한도 1")
		_expect(bool(game.graph.validation_summary().get("ok", false)), "Stage %02d 모듈 그래프 유효" % stage_number)
		_expect(not game.graph.path_between("entrance", "throne").is_empty(), "Stage %02d 입구→왕좌 필수 경로 유지" % stage_number)
		_expect(not game.graph.path_between("entrance", HeartServiceScript.ROOM_ID).is_empty(), "Stage %02d 입구→심장실 경로" % stage_number)
		var heart_count := 0
		for placed in game._quarter_layout_for_graph().get("placed_modules", []):
			if str(placed.get("instance_id", "")) == HeartServiceScript.ROOM_ID:
				heart_count += 1
		_expect(heart_count == 1, "Stage %02d 심장실 중복 배치 없음" % stage_number)
		game._set_screen(Constants.SCREEN_MANAGEMENT)
		await get_tree().process_frame
		var capture_path := "res://tmp/update3_phase4/heart_stage_%02d.png" % stage_number
		_expect(_save_stage_capture(game, capture_path) == OK, "Stage %02d 레이아웃 측정 캡처" % stage_number)

	game.castle_art_stage = "stage_02_castle"
	game.rooms = DataRegistry.rooms.duplicate(true)
	game._init_room_facilities()
	game.update3_active_run = selected.duplicate(true)
	game._sync_castle_stage_content()
	game._setup_dungeon_graph()
	game._open_map_editor()
	game.selected_room = HeartServiceScript.ROOM_ID
	var before_layout := JSON.stringify(game.map_editor_layout)
	game._move_map_editor_room(Vector2i.RIGHT)
	_expect(JSON.stringify(game.map_editor_layout) == before_layout, "고정 심장실 이동 거부")
	game._map_editor_disconnect_selected_room()
	_expect(JSON.stringify(game.map_editor_layout) == before_layout, "고정 심장실 연결 해제 거부")
	game.selected_room = HeartServiceScript.PATH_ID
	game._map_editor_delete_selected_path()
	_expect(JSON.stringify(game.map_editor_layout) == before_layout, "고정 심장실 통로 삭제 거부")
	_expect(not game._can_change_room_facility(HeartServiceScript.ROOM_ID), "심장실 시설 교체 금지")

	var throne_hp_before := GameState.demon_lord_hp
	var damage_result: Dictionary = game._damage_update3_heart_chamber(9999)
	_expect(not bool(damage_result.get("castle_defeat", true)) and GameState.demon_lord_hp == throne_hp_before, "심장실 파괴가 왕좌 HP를 깎지 않음")
	_expect(int(game.update3_active_run.get("run_metrics_update3", {}).get("heart_room_disabled_count", 0)) == 1, "심장실 비활성 결과 지표 기록")
	_expect(not game.graph.path_between("entrance", game._update3_enemy_goal()).is_empty(), "비활성 후 원래 적 경로가 멈추지 않음")

	game.map_editor_active = false
	game.castle_art_stage = "stage_04_citadel"
	game.rooms = DataRegistry.rooms.duplicate(true)
	game.update3_active_run = FrontServiceScript.default_legacy_active_run()
	game._sync_castle_stage_content()
	game._setup_dungeon_graph()
	_expect(not game.rooms.has(HeartServiceScript.ROOM_ID), "기존 v3 스테이지 4에도 심장실 없음")
	_expect(game.graph.path_between("entrance", "throne").size() > 0, "기존 v3 입구→왕좌 경로 유지")
	host.queue_free()


func _save_stage_capture(game, path: String) -> Error:
	var image := Image.create(640, 400, false, Image.FORMAT_RGBA8)
	image.fill(Color("#17131d"))
	for cell_value in game.graph.debug_floor_cells().keys():
		var cell: Vector2i = cell_value
		image.fill_rect(Rect2i(18 + cell.x * 18, 18 + cell.y * 12, 16, 10), Color("#6e6672"))
	for slot in game.graph.debug_object_slots():
		if str(slot.get("id", "")) != "heart_core_placeholder":
			continue
		var cell: Vector2i = slot.get("cell", Vector2i.ZERO)
		image.fill_rect(Rect2i(14 + cell.x * 18, 14 + cell.y * 12, 24, 18), Color("#c43f83"))
	return image.save_png(ProjectSettings.globalize_path(path))


func _test_v4_round_trip() -> void:
	var migration := SaveV4MigratorScript.migrate_envelope(_base_v3_fixture(), DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _save_catalogs())
	_expect(bool(migration.get("ok", false)), "Phase 4 검증용 v4 기본 저장")
	var envelope: Dictionary = migration.get("envelope", {}).duplicate(true)
	var selected := _selected_run()
	for key in selected.keys():
		envelope["active_run"][key] = selected[key].duplicate(true) if selected[key] is Dictionary or selected[key] is Array else selected[key]
	envelope["active_run"]["legacy_payload"]["world"]["castle_art_stage"] = "stage_02_castle"
	envelope["active_run"] = HeartServiceScript.sync_active_run(envelope["active_run"], 2)
	_expect(SaveV4MigratorScript.validate_v4(envelope, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _save_catalogs()) == "", "Stage 02 심장실 v4 저장 유효")
	var restored = JSON.parse_string(JSON.stringify(envelope))
	_expect(int(restored.get("active_run", {}).get("heart", {}).get("chamber_hp", 0)) == 420, "심장실 HP 저장·불러오기 보존")
	var corrupt := envelope.duplicate(true)
	corrupt["active_run"]["heart"]["chamber_hp"] = 421
	_expect(SaveV4MigratorScript.validate_v4(corrupt, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _save_catalogs()) != "", "최대보다 큰 심장실 HP 저장 거부")


func _base_v3_fixture() -> Dictionary:
	var payload := {
		"checkpoint": "management", "screen": "management",
		"world": {"selected_monster_id": "slime", "castle_art_stage": "stage_01_cave", "monster_roster": {"slime": {"level": 1}, "goblin": {"level": 1}, "imp": {"level": 1}}},
		"raid": {"selected_monster_ids": []},
		"campaign": {"completed": false, "final_battle_outcome": "", "postgame_active": false},
		"result": {}, "game_state": {"day": 4}, "onboarding": {}, "update2": {}
	}
	var v2 := SaveV1ToV2MigratorScript.migrate_inspection({"status": "valid", "payload": payload, "summary": {"day": 4}, "saved_at_unix": 1783872000}, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	var v3 := SaveV2ToV3MigratorScript.migrate_envelope(v2.get("envelope", {}), DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	return v3.get("envelope", {})


func _save_catalogs() -> Dictionary:
	return {"fronts": DataRegistry.update3_fronts, "castle_hearts": DataRegistry.update3_castle_hearts, "duo_links": DataRegistry.update3_duo_links, "rival_finales": DataRegistry.update3_rival_finales}


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[HeartChamberPhase4] FAIL: %s" % message)
