extends Node

const Validator = preload("res://scripts/v20/contracts/V20ContractValidator.gd")
const CommandService = preload("res://scripts/v20/commands/V20CommandService.gd")
const FacilityService = preload("res://scripts/v20/facilities/V20FacilityService.gd")
const HUDScene = preload("res://scenes/v20/ui/V20InformationHUD.tscn")
const HUDScript = preload("res://scripts/v20/ui/V20InformationHUD.gd")

var failed := false
var assertion_count := 0
var received_actions: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_catalog_and_resources()
	_test_focus_cooldown_and_expiry()
	_test_facility_activation()
	_test_command_changes_pattern_outcome()
	await _test_hud_connection()
	if OS.get_cmdline_user_args().has("--capture-v20-commands") and DisplayServer.get_name() != "headless":
		await _capture_commands()
	if failed:
		print("V20_TACTICAL_COMMANDS_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V20_TACTICAL_COMMANDS_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_catalog_and_resources() -> void:
	var validation := Validator.validate_catalog("command", DataRegistry.v20_commands)
	_expect(bool(validation.get("ok", false)), "전술 명령 catalog validator 승인: %s" % [validation.get("errors", [])])
	_expect(DataRegistry.v20_commands.size() == 4, "집결·집중·시설 발동·비상 후퇴 네 명령")
	var state := CommandService.new_state(DataRegistry.v20_commands)
	_expect(int(state.get("points", 0)) == 3 and int(state.get("max_points", 0)) == 3, "초기 명령력 3 / 3")
	var emergency := CommandService.issue(state, "v20_emergency_fallback", {"type": "room", "id": "fallback"}, DataRegistry.v20_commands)
	state = emergency.get("state", {})
	_expect(bool(emergency.get("ok", false)) and int(state.get("points", -1)) == 1, "비상 후퇴 명령력 2 소비")
	var insufficient := CommandService.issue(state, "v20_emergency_fallback", {"type": "room", "id": "fallback"}, DataRegistry.v20_commands)
	_expect(not bool(insufficient.get("ok", true)), "동일 명령 연속 spam 거부")
	state = CommandService.advance(state, 12.0)
	_expect(int(state.get("points", 0)) == 2, "12초마다 명령력 1 회복")


func _test_focus_cooldown_and_expiry() -> void:
	var state := CommandService.new_state(DataRegistry.v20_commands)
	var invalid := CommandService.issue(state, "v20_focus", {"type": "room", "id": "north_gate"}, DataRegistry.v20_commands)
	_expect(not bool(invalid.get("ok", true)) and str(invalid.get("status", "")) == "invalid_target", "집중 명령은 적 선택 필수")
	var issued := CommandService.issue(state, "v20_focus", {"type": "enemy", "id": "engineer", "room_id": "north_gate"}, DataRegistry.v20_commands)
	state = issued.get("state", {})
	_expect(bool(issued.get("ok", false)) and int(state.get("points", -1)) == 2, "집중 명령 발동·명령력 1 소비")
	_expect(float(state.get("cooldowns", {}).get("v20_focus", 0.0)) == 8.0 and float(CommandService.active_effect(state, "v20_focus").get("remaining_seconds", 0.0)) == 5.0, "집중 cooldown 8초·지속 5초")
	var effect := CommandService.effect_for_target(state, "engineer", "north_gate")
	_expect(is_equal_approx(float(effect.get("damage_multiplier", 0.0)), 1.18) and int(effect.get("target_priority_bonus", 0)) == 100, "집중 대상 우선도·피해 효과")
	_expect(CommandService.effect_for_target(state, "thief", "treasure").get("source_commands", []).is_empty(), "집중 효과가 다른 적에게 누출되지 않음")
	var spam := CommandService.issue(state, "v20_focus", {"type": "enemy", "id": "engineer"}, DataRegistry.v20_commands)
	_expect(not bool(spam.get("ok", true)) and str(spam.get("status", "")) == "cooldown", "집중 연속 spam cooldown 거부")
	state = CommandService.advance(state, 5.0)
	_expect(CommandService.active_effect(state, "v20_focus").is_empty() and float(state.get("cooldowns", {}).get("v20_focus", 0.0)) == 3.0, "효과 종료 뒤 cooldown 3초 잔여")
	state = CommandService.advance(state, 3.0)
	_expect(is_zero_approx(float(state.get("cooldowns", {}).get("v20_focus", -1.0))), "8초 뒤 집중 재사용 가능")


func _test_facility_activation() -> void:
	var facility_state := FacilityService.new_battle_state({
		"north_wall": {"facility_id": "v20_barricade", "slot_id": "door_north", "edge_id": "entry_north", "room_id": "north_gate"}
	}, DataRegistry.v20_facilities)
	var state := CommandService.new_state(DataRegistry.v20_commands)
	var issued := CommandService.issue(state, "v20_activate_facility", {"type": "facility", "id": "north_wall", "room_id": "north_gate"}, DataRegistry.v20_commands, facility_state, DataRegistry.v20_facilities)
	state = issued.get("state", {})
	facility_state = issued.get("facility_state", {})
	_expect(bool(issued.get("ok", false)) and int(state.get("points", -1)) == 2, "시설 발동 명령력 1 소비")
	_expect(float(facility_state.get("facilities", {}).get("north_wall", {}).get("active_seconds", 0.0)) == 6.0 and int(facility_state.get("facilities", {}).get("north_wall", {}).get("charges", -1)) == 0, "선택 바리케이드 6초 발동·charge 소비")
	_expect(float(state.get("metrics", {}).get("v20_activate_facility", {}).get("facility_activations", 0.0)) == 1.0, "시설 발동 결산 지표")
	var unknown := CommandService.issue(CommandService.new_state(DataRegistry.v20_commands), "v20_activate_facility", {"type": "facility", "id": "missing"}, DataRegistry.v20_commands, facility_state, DataRegistry.v20_facilities)
	_expect(not bool(unknown.get("ok", true)) and str(unknown.get("status", "")) == "unknown_placement", "없는 시설 발동 시 명령력 미소비")


func _test_command_changes_pattern_outcome() -> void:
	var pattern := {"id": "engineer_disable", "response_tags": ["focus_target", "backup_line"], "responses_required": 1, "base_pressure": 100.0, "response_per_tag": 45.0}
	var unused_state := CommandService.new_state(DataRegistry.v20_commands)
	var unused := CommandService.evaluate_pattern(unused_state, pattern)
	var focused_state: Dictionary = CommandService.issue(unused_state, "v20_focus", {"type": "enemy", "id": "engineer"}, DataRegistry.v20_commands).get("state", {})
	var used := CommandService.evaluate_pattern(focused_state, pattern)
	_expect(not bool(unused.get("success", true)) and bool(used.get("success", false)), "명령 미사용 실패·집중 사용 성공 결과 차이")
	_expect(float(unused.get("remaining_pressure", 0.0)) == 100.0 and float(used.get("remaining_pressure", 0.0)) == 55.0, "집중 대응이 패턴 압력 45 감소")
	_expect(str(unused.get("outcome_signature", "")) != str(used.get("outcome_signature", "")), "명령 사용 여부 결과 signature 분리")
	var repeat := CommandService.evaluate_pattern(focused_state, pattern)
	_expect(used == repeat, "동일 command state 패턴 결과 deterministic")


func _test_hud_connection() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_child(host)
	var hud = HUDScene.instantiate()
	host.add_child(hud)
	await get_tree().process_frame
	var state := CommandService.new_state(DataRegistry.v20_commands)
	hud.setup("combat", _combat_state(CommandService.command_rows(state, DataRegistry.v20_commands), 3))
	hud.action_requested.connect(_record_action)
	await get_tree().process_frame
	_expect(_count_group(hud, HUDScript.TACTICAL_COMMAND_GROUP) == 4, "전투 HUD 상시 명령 4개 상한")
	var focus_button := _find_button_prefix(hud, "집중")
	_expect(focus_button != null and not focus_button.disabled and focus_button.tooltip_text != "", "집중 버튼 비용·설명·활성 상태")
	if focus_button != null:
		focus_button.pressed.emit()
	_expect(received_actions.has("command:v20_focus"), "전투 HUD 명령 action signal 연결")
	state = CommandService.issue(state, "v20_focus", {"type": "enemy", "id": "engineer"}, DataRegistry.v20_commands).get("state", {})
	hud.set_command_state(CommandService.command_rows(state, DataRegistry.v20_commands), int(state.get("points", 0)), 3)
	await get_tree().process_frame
	focus_button = _find_button_prefix(hud, "집중")
	_expect(focus_button != null and focus_button.disabled and "8.0초" in focus_button.text, "발동 직후 HUD cooldown·disabled 반영")
	host.queue_free()
	await get_tree().process_frame


func _capture_commands() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var hud = HUDScene.instantiate()
	viewport.add_child(hud)
	await get_tree().process_frame
	var state := CommandService.new_state(DataRegistry.v20_commands)
	state = CommandService.issue(state, "v20_focus", {"type": "enemy", "id": "engineer"}, DataRegistry.v20_commands).get("state", {})
	hud.setup("combat", _combat_state(CommandService.command_rows(state, DataRegistry.v20_commands), int(state.get("points", 0))))
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var path := "user://v20_phase7_commands_1280x720.png"
	var error := image.save_png(path) if image != null and not image.is_empty() else ERR_CANT_CREATE
	_expect(error == OK, "Phase 7 전술 명령 1280x720 실제 렌더")
	if error == OK:
		print("V20_PHASE7_CAPTURE: %s" % ProjectSettings.globalize_path(path))
	viewport.queue_free()
	await get_tree().process_frame


func _combat_state(rows: Array, points: int) -> Dictionary:
	return {
		"objective_label": "왕좌 방어",
		"objective_hp": 76,
		"objective_hp_max": 100,
		"phase_label": "3단계 · 공병 시설 접근",
		"pattern_title": "시설 무력화",
		"pattern_eta": "3.4초",
		"pattern_response": "공병 집중 또는 비상 후퇴로 대응",
		"commands": rows,
		"command_points": points,
		"command_max": 3,
		"drawer_open": false
	}


func _count_group(node: Node, group_name: String) -> int:
	var count := 1 if node.is_in_group(group_name) else 0
	for child in node.get_children():
		count += _count_group(child, group_name)
	return count


func _find_button_prefix(node: Node, prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix):
		return node
	for child in node.get_children():
		var found := _find_button_prefix(child, prefix)
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
	push_error("[V20TacticalCommands] FAIL: %s" % message)
