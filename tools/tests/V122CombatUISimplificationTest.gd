extends Node

const CombatViewModel = preload("res://scripts/v122/ui/V122CombatResultViewModel.gd")
const CommandService = preload("res://scripts/v122/combat/V122CommandService.gd")
const BattleLedger = preload("res://scripts/v122/combat/V122BattleLedger.gd")

const COMBAT_CONTROLLER_PATH := "res://scripts/game/CombatSceneController.gd"
const GAME_ROOT_PATH := "res://scripts/game/GameRoot.gd"
const HUD_CONTROLLER_PATH := "res://scripts/ui/HUDController.gd"
const COMMAND_IDS := ["rally", "focus", "activate_facility", "emergency_fallback"]
const LANDSCAPE_SIZES := [
	Vector2(1920, 1080),
	Vector2(1366, 768),
	Vector2(1280, 720),
]

var failures: Array[String] = []
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_default_hud_model()
	_test_layout_contract()
	_test_explicit_command_target_contract()
	_test_runtime_composition_contract()

	print(
		"V122_COMBAT_UI_SIMPLIFICATION_COVERAGE: %s"
		% JSON.stringify({
			"assertions": assertion_count,
			"commands": COMMAND_IDS.size(),
			"landscape_sizes": LANDSCAPE_SIZES.size(),
			"failure_count": failures.size(),
		})
	)
	if not failures.is_empty():
		print("V122_COMBAT_UI_SIMPLIFICATION_FAILURES: %s" % JSON.stringify(failures))
		print("V122_COMBAT_UI_SIMPLIFICATION_TEST: FAIL")
		get_tree().quit(1)
		return
	print("V122_COMBAT_UI_SIMPLIFICATION_TEST: PASS")
	get_tree().quit(0)


func _test_default_hud_model() -> void:
	var plan := _battle_plan()
	var command_state := CommandService.new_state(4, 3, 12.0)
	var runtime_state := {
		"throne_hp": 375,
		"throne_hp_max": 500,
		"defense_progress": 0.42,
		"context_drawer_open": false,
		"speed": 1.5,
		"paused": false,
	}
	var telegraphs := [{
		"enemy_id": "thief",
		"target_room_id": "treasure",
		"counter_hint": "보물실 접근 전에 차단",
	}]
	var model: Dictionary = CombatViewModel.build_combat(
		plan,
		telegraphs,
		CommandService.load_catalog(),
		command_state,
		runtime_state
	)

	_expect(str(model.get("source", "")) == "product_runtime", "전투 HUD가 실제 런타임 모델을 사용한다")
	_expect(_command_ids(model) == COMMAND_IDS, "기본 HUD에는 합의한 네 명령만 고정 순서로 노출된다")
	_expect(int(model.get("command_points", -1)) == 3, "현재 명령 포인트가 기본 HUD에 노출된다")
	_expect(int(model.get("command_points_max", -1)) == 4, "최대 명령 포인트가 기본 HUD에 노출된다")
	_expect(_model_number(model, "throne_hp", "throne", "hp") == 375.0, "왕좌 현재 HP가 런타임 값으로 노출된다")
	_expect(_model_number(model, "throne_hp_max", "throne", "max_hp") == 500.0, "왕좌 최대 HP가 런타임 값으로 노출된다")
	_expect(is_equal_approx(_model_number(model, "defense_progress", "defense", "progress"), 0.42), "방어 진행도가 런타임 값으로 노출된다")
	_expect(bool(model.get("threat_panel_visible", false)), "실제 위협이 있을 때만 위협 표시가 열린다")
	_expect(model.get("threats", []).size() == 1, "위협 표시가 실제 텔레그래프만 사용한다")
	_expect(is_equal_approx(float(model.get("speed", 0.0)), 1.5), "작은 속도 컨트롤이 실제 속도 상태를 읽는다")

	var quiet_model: Dictionary = CombatViewModel.build_combat(
		plan,
		[],
		CommandService.load_catalog(),
		command_state,
		runtime_state
	)
	_expect(not bool(quiet_model.get("threat_panel_visible", true)), "위협이 없으면 위협 영역을 숨긴다")
	_expect(quiet_model.get("threats", []).is_empty(), "위협이 없을 때 빈 위협 목록을 유지한다")

	var targeting_runtime := runtime_state.duplicate(true)
	targeting_runtime["pending_command_id"] = "rally"
	var targeting_model: Dictionary = CombatViewModel.build_combat(
		plan,
		telegraphs,
		CommandService.load_catalog(),
		command_state,
		targeting_runtime
	)
	_expect(not _drawer_open(model), "기본 전투 HUD에는 context drawer가 열리지 않는다")
	_expect(not _drawer_open(targeting_model), "명령 대상 선택 중에도 context drawer가 열리지 않는다")
	_expect(str(targeting_model.get("pending_command_id", "")) == "rally", "명령 대상 선택 상태는 전장 오버레이용 pending ID로 노출된다")


func _test_layout_contract() -> void:
	for viewport_size in LANDSCAPE_SIZES:
		var contract: Dictionary = CombatViewModel.layout_contract(viewport_size)
		var size_label := "%dx%d" % [int(viewport_size.x), int(viewport_size.y)]
		_expect(str(contract.get("mode", "")) != "orientation_notice", "%s는 전투 가능한 landscape HUD다" % size_label)
		_expect(_required_regions_inside(contract, viewport_size), "%s 기본 HUD 필수 영역이 화면 안에 있다" % size_label)
		_expect(_default_regions_do_not_overlap(contract), "%s 기본 HUD 영역이 서로 겹치지 않는다" % size_label)
		var commands: Rect2 = contract.get("commands", Rect2())
		var speed: Rect2 = contract.get("speed_pause", Rect2())
		_expect(speed.size.x <= commands.size.x * 0.2, "%s 속도 컨트롤은 명령 영역보다 작게 유지된다" % size_label)
		var inspector: Rect2 = contract.get("unit_inspector", Rect2())
		var battlefield: Rect2 = contract.get("battlefield", Rect2())
		_expect(inspector.size.x <= battlefield.size.x * 0.25 and inspector.size.y <= battlefield.size.y * 0.5, "%s 유닛 정보창은 전장을 가리지 않는 소형 패널이다" % size_label)


func _test_explicit_command_target_contract() -> void:
	var plan := _battle_plan()
	var catalog := CommandService.load_catalog()
	for command_id in COMMAND_IDS:
		var definition: Dictionary = catalog.get(command_id, {})
		var target_type := str(definition.get("target_type", ""))
		var state := CommandService.new_state(8, 8, 12.0)
		var ledger := BattleLedger.new_state(5, 5005, str(plan.get("layout_fingerprint", "")))
		var before_points := int(state.get("points", -1))
		var missing_target: Dictionary = CommandService.issue(state, command_id, {}, plan, ledger)
		_expect(not bool(missing_target.get("ok", true)), "%s는 대상 없이 발동되지 않는다" % command_id)
		_expect(str(missing_target.get("status", "")) == "invalid_target", "%s는 대상 미확정을 명시적으로 거부한다" % command_id)
		_expect(int(missing_target.get("state", {}).get("points", -1)) == before_points, "%s 대상 미확정 시 포인트가 소모되지 않는다" % command_id)

		var explicit_target := _explicit_target(target_type)
		var confirmed: Dictionary = CommandService.issue(state, command_id, explicit_target, plan, ledger)
		_expect(bool(confirmed.get("ok", false)), "%s는 사용자가 고른 유효 대상 확정 후에만 발동된다" % command_id)
		_expect(
			str(confirmed.get("state", {}).get("history", []).back().get("target", {}).get("id", "")) == str(explicit_target.get("id", "")),
			"%s 이력에는 자동 추론값이 아니라 확정 대상이 기록된다" % command_id
		)


func _test_runtime_composition_contract() -> void:
	var combat_source := FileAccess.get_file_as_string(COMBAT_CONTROLLER_PATH)
	var root_source := FileAccess.get_file_as_string(GAME_ROOT_PATH)
	var hud_source := FileAccess.get_file_as_string(HUD_CONTROLLER_PATH)
	var build_body := _function_body(combat_source, "build_combat_ui")
	_expect(build_body != "", "전투 HUD 조립 함수가 존재한다")
	for legacy_call in [
		"build_top_bar",
		"build_facility_effect_panel",
		"build_room_list",
		"build_unit_status_panel",
		"build_log_panel",
		"build_selected_unit_panel",
		"build_mobile_combat_bar",
		"build_combat_context_drawer",
	]:
		_expect(not build_body.contains(legacy_call), "기본 전투 HUD가 상시 패널 %s를 조립하지 않는다" % legacy_call)

	var command_body := _function_body(hud_source, "build_command_panel")
	if build_body.contains("build_command_panel"):
		_expect(not command_body.contains("_set_room_directive"), "기본 명령 바에 별도 방 지침 버튼을 섞지 않는다")
		_expect(not command_body.contains("ROOM_DIRECTIVE_"), "기본 명령 바는 네 전술 명령에 집중한다")
	_expect(build_body.contains("build_combat_unit_inspector"), "전투 개체 클릭은 소형 아군·적 정보창으로 연결된다")
	_expect(not build_body.contains("command_targeting_state()"), "명령 대상 목록은 UI 드로어로 조립하지 않는다")
	var threat_body := _function_body(combat_source, "_v122_active_threats")
	var refresh_body := _function_body(combat_source, "_refresh_v122_combat_view_model")
	_expect(
		threat_body.contains("root.enemy_units")
		and threat_body.contains("root.wave_manager.next_index")
		and refresh_body.contains("_v122_active_threats()"),
		"침입 위협은 최초 예고에 고정되지 않고 현재 생존 적 또는 다음 스폰을 추적한다"
	)

	var issue_body := _function_body(combat_source, "issue_v122_command")
	_expect(issue_body != "", "전술 명령 실행 진입점이 존재한다")
	_expect(not issue_body.contains("_v122_command_target("), "명령 실행 진입점이 대상을 자동 추론하지 않는다")
	var target_body := _function_body(combat_source, "_v122_command_target")
	if target_body != "":
		for fallback_token in [
			"for enemy in root.enemy_units",
			"telegraphs.front()",
			"for slot_value in battle_plan",
			"for room_id_value in battle_plan",
		]:
			_expect(not target_body.contains(fallback_token), "대상 선택기가 자동 fallback을 사용하지 않는다: %s" % fallback_token)

	var root_issue_body := _function_body(root_source, "_issue_v122_command")
	_expect(
		not root_issue_body.contains("combat_scene.issue_v122_command(command_id)"),
		"명령 버튼 한 번으로 자동 대상 발동하지 않고 대상 선택 단계로 들어간다"
	)
	var combat_click_body := _function_body(root_source, "_handle_left_click")
	_expect(
		combat_click_body.contains("combat_scene.select_v122_command_target")
		and combat_click_body.find("command_targeting_state") < combat_click_body.find("_select_unit"),
		"명령 중 전장 대상 클릭이 일반 개체 선택보다 먼저 처리된다"
	)
	var target_select_body := _function_body(combat_source, "select_v122_command_target")
	_expect(target_select_body.contains("issue_v122_command"), "유효한 전장 대상 클릭은 별도 확정 없이 즉시 명령을 실행한다")
	_expect(not target_select_body.contains("pending_v122_command_target = candidate"), "대상 클릭 뒤 중간 확정 상태를 저장하지 않는다")
	var candidate_body := _function_body(combat_source, "_v122_command_target_candidates")
	_expect(candidate_body.contains("enemy.get_instance_id()"), "동종 적도 실제 개체별 대상 ID를 사용한다")
	var marker_body := _function_body(root_source, "_draw_v122_command_target_feedback")
	_expect(marker_body.contains("_draw_management_target_overlay") and marker_body.contains("_draw_v122_target_brackets"), "방·시설·적의 실제 클릭 영역에 노란 월드 표시를 그린다")


func _battle_plan() -> Dictionary:
	return {
		"layout_fingerprint": "combat-ui-simplification-fixture",
		"active_route": ["entrance", "barracks", "throne"],
		"enemy_goals": ["throne"],
		"defense_segments": [
			{"room_id": "entrance", "progress_start": 0.0, "progress_end": 0.3},
			{"room_id": "barracks", "progress_start": 0.3, "progress_end": 0.8},
			{"room_id": "throne", "progress_start": 0.8, "progress_end": 1.0},
		],
		"world_anchors": {
			"entrance": [100.0, 200.0],
			"barracks": [420.0, 200.0],
			"throne": [760.0, 200.0],
		},
		"facility_slots": [{
			"room_id": "barracks",
			"facility_role": "barracks",
			"object_id": "facility_barracks",
			"world_anchor": [420.0, 200.0],
		}],
	}


func _explicit_target(target_type: String) -> Dictionary:
	match target_type:
		"enemy":
			return {"type": "enemy", "id": "enemy_user_selected", "world_anchor": [510.0, 200.0]}
		"facility":
			return {"type": "facility", "id": "barracks"}
		"room":
			return {"type": "room", "id": "entrance"}
	return {}


func _command_ids(model: Dictionary) -> Array:
	var result: Array = []
	for value in model.get("commands", []):
		if value is Dictionary:
			result.append(str(value.get("id", "")))
	return result


func _model_number(model: Dictionary, direct_key: String, group_key: String, nested_key: String) -> float:
	if model.has(direct_key):
		return float(model.get(direct_key, -1.0))
	var group: Dictionary = model.get(group_key, {})
	return float(group.get(nested_key, -1.0))


func _drawer_open(model: Dictionary) -> bool:
	if model.has("context_drawer_open"):
		return bool(model.get("context_drawer_open", false))
	var drawer: Dictionary = model.get("context_drawer", {})
	return bool(drawer.get("open", false))


func _required_regions_inside(contract: Dictionary, viewport_size: Vector2) -> bool:
	var bounds := Rect2(Vector2.ZERO, viewport_size)
	for key in ["battlefield", "throne_status", "threat", "tactics", "commands", "speed_pause", "special_actions", "unit_inspector"]:
		var rect: Rect2 = contract.get(key, Rect2())
		if rect.size.x <= 0.0 or rect.size.y <= 0.0 or not bounds.encloses(rect):
			return false
	return true


func _default_regions_do_not_overlap(contract: Dictionary) -> bool:
	var rects: Array[Rect2] = []
	for key in ["battlefield", "throne_status", "threat", "tactics", "commands", "speed_pause", "special_actions"]:
		var rect: Rect2 = contract.get(key, Rect2())
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			return false
		rects.append(rect)
	for left_index in range(rects.size()):
		for right_index in range(left_index + 1, rects.size()):
			if rects[left_index].intersects(rects[right_index]):
				return false
	return true


func _function_body(source: String, function_name: String) -> String:
	var marker := "func %s(" % function_name
	var start := source.find(marker)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + marker.length())
	return source.substr(start) if next < 0 else source.substr(start, next - start)


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		return
	failures.append(message)
	push_error(message)
