extends Node

const ObjectiveScript = preload("res://scripts/systems/multifloor/UpperFloorObjectiveService.gd")
const MultiFloorScript = preload("res://scripts/systems/multifloor/MultiFloorGraphService.gd")
const UpperScreenScene = preload("res://scenes/ui/screens/UpperFloorScreen.tscn")
const FloorHudScene = preload("res://scenes/ui/hud/MultiFloorHUD.tscn")
const GameRootScript = preload("res://scripts/game/GameRoot.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_layouts_and_selection()
	_test_auto_camera()
	await _test_ui_and_alerts()
	if failed:
		print("MULTI_FLOOR_HUD_PHASE12_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("MULTI_FLOOR_HUD_PHASE12_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_layouts_and_selection() -> void:
	_expect(GameRootScript != null, "GameRoot 상층 화면·전투 HUD parse")
	_expect(DataRegistry.update4_upper_floor_layouts.size() == 3, "상층 레이아웃 3종")
	for layout_id_value in DataRegistry.update4_upper_floor_layouts.keys():
		var layout_id := str(layout_id_value)
		var layout: Dictionary = DataRegistry.update4_upper_floor_layouts[layout_id_value]
		var rooms := ObjectiveScript.upper_rooms_from_layout(layout, DataRegistry.update4_upper_floor_modules)
		var graph := MultiFloorScript.build_graph(DataRegistry.rooms, rooms, str(layout.get("base_stair_room", "spike_corridor")), "upper_stair")
		_expect(rooms.size() == 4 and not MultiFloorScript.path_between(graph, "1F", "entrance", "2F", "upper_crown").is_empty() and not MultiFloorScript.path_between(graph, "1F", "entrance", "2F", "upper_vault").is_empty(), "%s 4모듈·왕관실·금고 path PASS" % layout_id)
	var active := _active_run()
	active = ObjectiveScript.initialize_if_unlocked(active, DataRegistry.update4_upper_floor_layouts, DataRegistry.update4_upper_floor_modules, 3)
	var selected := ObjectiveScript.select_layout(active, "upper_split_vault", DataRegistry.update4_upper_floor_layouts, DataRegistry.update4_upper_floor_modules, 3)
	var repeated := ObjectiveScript.select_layout(selected.active_run, "upper_long_gallery", DataRegistry.update4_upper_floor_layouts, DataRegistry.update4_upper_floor_modules, 3)
	_expect(bool(selected.ok) and str(selected.active_run.upper_floor.layout_id) == "upper_split_vault", "3종 중 상층 레이아웃 선택·확정")
	_expect(not bool(repeated.ok), "회차 중 상층 레이아웃 재선택 금지")


func _test_auto_camera() -> void:
	var runtime := MultiFloorScript.new_runtime()
	runtime = MultiFloorScript.register_entity(runtime, "controlled", "monster", "2F", "upper_stair_landing")
	_expect(MultiFloorScript.auto_camera_floor(runtime, "controlled", "1F", true) == "2F", "직접 조종 몬스터 계단 이동 자동 카메라 전환")
	_expect(MultiFloorScript.auto_camera_floor(runtime, "controlled", "1F", false) == "1F", "자동 카메라 옵션 OFF 보존")


func _test_ui_and_alerts() -> void:
	var upper := _upper_state("upper_split_vault")
	upper.graph_runtime.entities = {
		"enemy_hidden_1": {"faction": "enemy", "floor_id": "2F", "alive": true},
		"enemy_hidden_2": {"faction": "enemy", "floor_id": "2F", "alive": true},
		"monster_hidden": {"faction": "monster", "floor_id": "2F", "alive": true}
	}
	var hud = FloorHudScene.instantiate()
	add_child(hud)
	hud.setup(upper, DataRegistry.update4_upper_floor_layouts, DataRegistry.update4_upper_floor_modules)
	await get_tree().process_frame
	_expect(hud.floor_1_button != null and hud.floor_2_button != null and hud.upper_overlay != null, "1F/2F 탭·상층 모듈 schematic")
	_expect(hud.hidden_enemy_count() == 2 and hud.find_child("HiddenFloorAlert", true, false).visible, "숨은 층 적 수·위험 경보")
	_expect(is_equal_approx(float(hud.alert_remaining), 6.0), "숨은 층 경보 6초 대응 창")
	_expect(hud.select_floor("2F") and not hud.select_floor("1F"), "층 전환 입력 버퍼 0.2초")
	hud._process(0.21)
	_expect(hud.select_floor("1F"), "입력 버퍼 종료 후 층 재전환")
	hud.push_hidden_floor_alert("2F", 2, true)
	hud._process(5.8)
	_expect(hud.find_child("HiddenFloorAlert", true, false).visible, "경보 6초 전 유지")
	hud._process(0.3)
	_expect(not hud.find_child("HiddenFloorAlert", true, false).visible, "경보 6초 후 자동 해제")
	for viewport_size in [Vector2(1920, 1080), Vector2(1366, 768)]:
		var rects: Dictionary = hud.hud_rects_for_viewport(viewport_size)
		_expect(_inside(rects.floor_tabs, viewport_size) and _inside(rects.hidden_alert, viewport_size) and _inside(rects.auto_camera, viewport_size) and not rects.floor_tabs.intersects(rects.hidden_alert), "%dx%d HUD 경계·비겹침" % [int(viewport_size.x), int(viewport_size.y)])
	hud.queue_free()
	var screen = UpperScreenScene.instantiate()
	add_child(screen)
	screen.setup(upper, DataRegistry.update4_upper_floor_layouts, DataRegistry.update4_upper_floor_modules)
	await get_tree().process_frame
	_expect(_button_count(screen, "UpperLayout_") == 3, "상층 레이아웃 선택 카드 3개")
	for viewport_size in [Vector2(1920, 1080), Vector2(1366, 768)]:
		var rects: Array[Rect2] = screen.layout_rects_for_viewport(viewport_size)
		_expect(rects.size() == 3 and _inside(rects[0], viewport_size) and _inside(rects[2], viewport_size) and not rects[0].intersects(rects[1]) and not rects[1].intersects(rects[2]), "%dx%d 레이아웃 카드 경계·비겹침" % [int(viewport_size.x), int(viewport_size.y)])
	get_viewport().set_embedding_subwindows(false)
	get_viewport().size = Vector2i(1366, 768)
	await get_tree().process_frame
	var texture: ViewportTexture = get_viewport().get_texture()
	if DisplayServer.get_name() != "headless" and texture != null:
		var image := texture.get_image()
		if image != null:
			image.save_png("user://upper_floor_phase12_1366.png")
	screen.queue_free()


func _active_run() -> Dictionary:
	return {"campaign_mode_id": "council_season", "upper_floor": {"unlocked": true, "layout_id": "", "objective_hp": {}, "facility_role": "", "seal_theft_count": 0, "graph_runtime": {}, "crown_suppressed": false, "repair_cost_gold": 0, "layout_locked": false, "auto_camera_switch": true}}


func _upper_state(layout_id: String) -> Dictionary:
	return {"unlocked": true, "layout_id": layout_id, "objective_hp": {"crown_sanctum": 600}, "facility_role": "recovery", "seal_theft_count": 0, "graph_runtime": {"visible_floor": "1F", "entities": {}, "transition_queues": {"1F>2F": [], "2F>1F": []}}, "crown_suppressed": false, "repair_cost_gold": 0, "layout_locked": true, "auto_camera_switch": true}


func _inside(rect: Rect2, viewport_size: Vector2) -> bool:
	return rect.position.x >= -0.1 and rect.position.y >= -0.1 and rect.end.x <= viewport_size.x + 0.1 and rect.end.y <= viewport_size.y + 0.1


func _button_count(root: Node, prefix: String) -> int:
	var count := 1 if root is Button and root.name.begins_with(prefix) else 0
	for child in root.get_children():
		count += _button_count(child, prefix)
	return count


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[MultiFloorHudPhase12] FAIL: %s" % label)
