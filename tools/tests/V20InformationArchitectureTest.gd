extends Node

const HUDScene = preload("res://scenes/v20/ui/V20InformationHUD.tscn")
const HUDScript = preload("res://scripts/v20/ui/V20InformationHUD.gd")

var failed := false
var assertion_count := 0
var received_actions: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	for viewport_size in [Vector2(1280, 720), Vector2(1366, 768), Vector2(1920, 1080)]:
		await _test_management_layout(viewport_size)
		await _test_combat_layout(viewport_size)
	await _test_action_signals()
	if OS.get_cmdline_user_args().has("--capture-v20-ui") and DisplayServer.get_name() != "headless":
		await _capture_ui("management", Vector2i(1280, 720), true)
		await _capture_ui("combat", Vector2i(1280, 720), false)
	if failed:
		print("V20_INFORMATION_ARCHITECTURE_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V20_INFORMATION_ARCHITECTURE_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_management_layout(viewport_size: Vector2) -> void:
	var host := _host(viewport_size)
	var hud = HUDScene.instantiate()
	host.add_child(hud)
	await get_tree().process_frame
	hud.setup("management", _management_state(true))
	await get_tree().process_frame
	var rects: Dictionary = hud.layout_rects_for_viewport(viewport_size, "management", true)
	_expect(_rects_inside(rects, viewport_size), "%dx%d 관리 HUD 화면 내부" % [int(viewport_size.x), int(viewport_size.y)])
	_expect(_non_overlapping(rects, [["intrusion", "resources"], ["resources", "day"], ["workspace", "drawer"], ["workspace", "actions"], ["drawer", "actions"]]), "%dx%d 관리 HUD 핵심 영역 비겹침" % [int(viewport_size.x), int(viewport_size.y)])
	_expect(_count_group(hud, HUDScript.PRIMARY_ACTION_GROUP) == 4, "%dx%d 관리 상시 주 행동 4개" % [int(viewport_size.x), int(viewport_size.y)])
	_expect(hud.get_node_or_null("StrategyBoardWorkspace") != null and hud.get_node_or_null("ContextDrawer") != null, "%dx%d 중앙 전략 보드·선택 드로어 분리" % [int(viewport_size.x), int(viewport_size.y)])
	_expect(_forbidden_panels_absent(hud), "%dx%d 방 목록·로그·대형 상세 상시 패널 없음" % [int(viewport_size.x), int(viewport_size.y)])
	host.queue_free()
	await get_tree().process_frame


func _test_combat_layout(viewport_size: Vector2) -> void:
	var host := _host(viewport_size)
	var hud = HUDScene.instantiate()
	host.add_child(hud)
	await get_tree().process_frame
	var state := _combat_state(viewport_size.x <= 1366.0)
	hud.setup("combat", state)
	await get_tree().process_frame
	var rects: Dictionary = hud.layout_rects_for_viewport(viewport_size, "combat", bool(state.get("drawer_open", false)))
	var overlap_pairs := [["objective", "pattern"], ["commands", "speed"], ["workspace", "commands"], ["workspace", "speed"]]
	if bool(state.get("drawer_open", false)):
		overlap_pairs.append(["workspace", "drawer"])
		overlap_pairs.append(["drawer", "commands"])
		overlap_pairs.append(["drawer", "speed"])
	_expect(_rects_inside(rects, viewport_size), "%dx%d 전투 HUD 화면 내부" % [int(viewport_size.x), int(viewport_size.y)])
	_expect(_non_overlapping(rects, overlap_pairs), "%dx%d 전투 HUD 핵심 영역 비겹침" % [int(viewport_size.x), int(viewport_size.y)])
	var command_count := _count_group(hud, HUDScript.TACTICAL_COMMAND_GROUP)
	_expect(command_count >= 3 and command_count <= 4, "%dx%d 전술 명령 %d개 상한 준수" % [int(viewport_size.x), int(viewport_size.y), command_count])
	_expect(hud.get_node_or_null("CoreObjective") != null and hud.get_node_or_null("NextPattern") != null and hud.get_node_or_null("SpeedDock") != null, "%dx%d 목표·다음 패턴·속도 상시 노출" % [int(viewport_size.x), int(viewport_size.y)])
	_expect(_forbidden_panels_absent(hud), "%dx%d 전투 로그·유닛 목록·대형 상세 상시 패널 없음" % [int(viewport_size.x), int(viewport_size.y)])
	host.queue_free()
	await get_tree().process_frame


func _test_action_signals() -> void:
	var host := _host(Vector2(1280, 720))
	var hud = HUDScene.instantiate()
	host.add_child(hud)
	await get_tree().process_frame
	hud.setup("management", _management_state(false))
	hud.action_requested.connect(_record_action)
	await get_tree().process_frame
	var start_button := _find_button(hud, "방어 시작")
	_expect(start_button != null and start_button.focus_mode == Control.FOCUS_ALL, "주 행동 키보드 포커스 가능")
	if start_button != null:
		start_button.pressed.emit()
	_expect(received_actions.has("start_defense"), "주 행동 signal 전달")
	hud.set_context_drawer(true, _management_state(true).get("context", {}))
	await get_tree().process_frame
	var close_button: Button = hud.get_node_or_null("ContextDrawer/ContextDrawerClose")
	if close_button != null:
		close_button.pressed.emit()
	_expect(received_actions.has("close_context"), "컨텍스트 드로어 닫기 signal 전달")
	host.queue_free()
	await get_tree().process_frame


func _capture_ui(mode_value: String, viewport_size: Vector2i, drawer_value: bool) -> void:
	var capture_viewport := SubViewport.new()
	capture_viewport.size = viewport_size
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(capture_viewport)
	var hud = HUDScene.instantiate()
	capture_viewport.add_child(hud)
	await get_tree().process_frame
	hud.setup(mode_value, _management_state(drawer_value) if mode_value == "management" else _combat_state(drawer_value))
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := capture_viewport.get_texture().get_image()
	var path := "user://v20_phase2_%s_%dx%d.png" % [mode_value, viewport_size.x, viewport_size.y]
	var error := image.save_png(path) if image != null and not image.is_empty() else ERR_CANT_CREATE
	_expect(error == OK, "%s %dx%d 실제 렌더 캡처" % [mode_value, viewport_size.x, viewport_size.y])
	if error == OK:
		print("V20_PHASE2_CAPTURE: %s" % ProjectSettings.globalize_path(path))
	capture_viewport.queue_free()
	await get_tree().process_frame


func _management_state(drawer_value: bool) -> Dictionary:
	return {
		"day": 3,
		"intrusion_title": "공병이 북문 시설을 노립니다",
		"intrusion_hint": "예상 경로 북문 → 병영 · 예고 5초",
		"resources": {"build": 7, "command": 3, "command_max": 3},
		"board_hint": "방·문·경로를 지도에서 직접 선택",
		"drawer_open": drawer_value,
		"context": {
			"eyebrow": "선택한 방",
			"title": "북문 길목",
			"subtitle": "첫 방어선 · 문 슬롯",
			"facts": [
				{"label": "예상 적", "value": "공병 1"},
				{"label": "시설", "value": "바리케이드"},
				{"label": "배치", "value": "슬라임 1 / 2"},
				{"label": "우회 비용", "value": "+12"}
			],
			"summary": "차단하면 남문으로 우회합니다. 교체 시 자원 손실을 확인합니다."
		}
	}


func _combat_state(drawer_value: bool) -> Dictionary:
	return {
		"objective_label": "왕좌 방어",
		"objective_hp": 82,
		"objective_hp_max": 100,
		"phase_label": "2단계 · 공병 진입",
		"pattern_title": "시설 무력화",
		"pattern_eta": "4.2초",
		"pattern_response": "집중 또는 예비 방어선으로 대응",
		"drawer_open": drawer_value,
		"context": {
			"eyebrow": "선택 유닛",
			"title": "성문 파수 슬라임",
			"subtitle": "북문 길목 · 차단 역할",
			"facts": [
				{"label": "체력", "value": "74 / 100"},
				{"label": "상태", "value": "문 고정"},
				{"label": "시설", "value": "바리케이드"}
			],
			"summary": "세부 기술과 전체 기록은 일시정지 상태에서 확인합니다."
		},
		"emergency_command": {"id": "release_lock", "label": "봉쇄 해제"}
	}


func _host(host_size: Vector2) -> Control:
	var host := Control.new()
	host.size = host_size
	add_child(host)
	return host


func _rects_inside(rects: Dictionary, viewport_size: Vector2) -> bool:
	var bounds := Rect2(Vector2.ZERO, viewport_size)
	for rect_value in rects.values():
		if not bounds.encloses(rect_value):
			return false
	return true


func _non_overlapping(rects: Dictionary, pairs: Array) -> bool:
	for pair_value in pairs:
		var pair: Array = pair_value
		if rects.has(pair[0]) and rects.has(pair[1]) and rects[pair[0]].intersects(rects[pair[1]]):
			return false
	return true


func _count_group(node: Node, group_name: String) -> int:
	var count := 1 if node.is_in_group(group_name) else 0
	for child in node.get_children():
		count += _count_group(child, group_name)
	return count


func _forbidden_panels_absent(node: Node) -> bool:
	for forbidden_name in ["RoomList", "BattleLog", "UnitStatus", "SelectedUnitPanel"]:
		if node.find_child(forbidden_name, true, false) != null:
			return false
	return true


func _find_button(node: Node, text_value: String) -> Button:
	if node is Button and node.text == text_value:
		return node
	for child in node.get_children():
		var found := _find_button(child, text_value)
		if found != null:
			return found
	return null


func _record_action(action_id: String) -> void:
	received_actions.append(action_id)


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[V20InformationArchitecture] FAIL: %s" % message)
