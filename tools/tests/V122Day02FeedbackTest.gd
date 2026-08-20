extends Node

const CommandService = preload("res://scripts/v122/combat/V122CommandService.gd")
const BattleLedger = preload("res://scripts/v122/combat/V122BattleLedger.gd")

const MANAGEMENT_SOURCE := "res://scripts/game/ManagementSceneController.gd"
const ROOT_SOURCE := "res://scripts/game/GameRoot.gd"
const COMBAT_SOURCE := "res://scripts/game/CombatSceneController.gd"
const RENDERER_SOURCE := "res://scripts/dungeon_quarter/QuarterDungeonRenderer.gd"
const TUTORIAL_PATH := "res://data/onboarding_flow_dialogue_v0.4.json"

var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_contextual_management_ui()
	_test_command_ai_contract()
	_test_directive_and_tutorial_contract()
	_test_connected_map_editor_contract()
	if failures.is_empty():
		print("V122_DAY02_FEEDBACK_TEST: PASS")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("V122_DAY02_FEEDBACK_TEST: FAIL")
	get_tree().quit(1)


func _test_contextual_management_ui() -> void:
	var source := FileAccess.get_file_as_string(MANAGEMENT_SOURCE)
	var root_source := FileAccess.get_file_as_string(ROOT_SOURCE)
	var build_body := _function_body(source, "build_management_ui")
	_expect(build_body.contains("_build_monster_roster_dock"), "관리 화면은 확장 가능한 몬스터 로스터 도크를 조립한다")
	_expect(not build_body.contains("_build_placement_card_rail"), "시설과 몬스터를 한 고정 버튼 열에 모두 펼치지 않는다")
	_expect(source.contains("HorizontalScrollBar") or source.contains("ScrollContainer"), "몬스터 수가 늘어나도 로스터를 스크롤할 수 있다")
	_expect(source.contains("_build_contextual_facility_palette"), "시설 교체 목록은 선택 방 문맥에서 열린다")
	_expect(source.contains("건설 슬롯 · 시설 선택"), "빈 슬롯은 시설 교체가 아니라 건설 진입점으로 표시한다")
	_expect(source.contains("_contextual_facility_location_hint"), "시설 목록은 보물실과 같은 전선 추천을 설명한다")
	_expect(source.contains("effect_summary") and source.contains("recommend_summary"), "시설 목록 tooltip은 실제 효과와 추천 위치를 사용한다")
	_expect(source.contains("_monster_drag_texture"), "몬스터 로스터 카드는 실제 몬스터 이미지를 사용한다")
	_expect(source.contains("_begin_management_roster_drag"), "몬스터 로스터 카드가 실제 드래그 배치를 시작한다")
	_expect(root_source.contains("roster_monster_drag_active"), "UI 로스터 드래그는 맵 위 몬스터 드래그와 구분해 추적한다")
	var click_body := _function_body(root_source, "_handle_left_click")
	_expect(click_body.contains("_select_build_target_room(room_id)"), "지도 건설 클릭은 즉시 결제하지 않고 미리보기 대상으로 전환한다")
	_expect(not click_body.contains("_commit_selected_facility_to_room(room_id)"), "지도 건설 클릭은 명시적 확정 전 비용을 쓰지 않는다")
	_expect(root_source.contains("+ 건설 가능"), "빈 슬롯은 선택 전에도 건설 가능 표식을 노출한다")
	var facility_label_body := _function_body(root_source, "_facility_short_label")
	_expect(facility_label_body.contains("\"trap\": \"함정 구역\""), "함정 구조 역할은 내부 ID 대신 사용자용 이름으로 표시한다")
	_expect(not facility_label_body.contains("get(\"short_label\", facility_id)"), "알 수 없는 시설 역할도 내부 ID를 플레이어 화면에 그대로 노출하지 않는다")


func _test_command_ai_contract() -> void:
	var plan := {
		"layout_fingerprint": "day02_feedback",
		"world_anchors": {
			"entrance": [420.0, 320.0],
			"barracks": [760.0, 480.0],
			"recovery": [1040.0, 620.0],
		},
		"defense_segments": [
			{
				"segment_id": "defense_entrance",
				"entry_room_id": "entrance",
				"room_ids": ["entrance", "barracks"],
			},
			{
				"segment_id": "defense_recovery",
				"entry_room_id": "recovery",
				"room_ids": ["recovery"],
			},
		],
		"facility_slots": [],
	}
	var state := CommandService.new_state(8, 8, 12.0)
	var ledger := BattleLedger.new_state(2, 2202, "day02_feedback")
	var rally := CommandService.issue(state, "rally", {"type": "defense_zone", "id": "defense_entrance"}, plan, ledger)
	_expect(bool(rally.get("ok", false)), "집결 명령이 유효한 방어 구역 대상으로 발동된다")
	_expect(not rally.has("directive_patch"), "집결 명령이 전체 지침을 몰래 바꾸지 않는다")
	var rally_state: Dictionary = rally.get("state", {})
	var rally_target: Dictionary = rally_state.get("active_commands", {}).get("rally", {}).get("target", {})
	_expect(str(rally_target.get("type", "")) == "defense_zone", "집결 명령은 방이 아닌 방어 구역 타입을 기록한다")
	_expect(str(rally_target.get("id", "")) == "defense_entrance", "집결 명령은 선택한 구역 ID를 보존한다")
	var rally_order := CommandService.movement_order_for_actor(rally_state, "goblin", "barracks", "monster")
	_expect(str(rally_order.get("command_id", "")) == "rally", "집결 명령이 몬스터 AI 이동 명령으로 노출된다")
	_expect(str(rally_order.get("target_room_id", "")) == "entrance", "집결 명령이 선택 구역의 앵커 방을 실제 이동 목표로 유지한다")
	var monster_effect := CommandService.effect_for_actor(rally_state, "goblin", "barracks", "monster")
	var enemy_effect := CommandService.effect_for_actor(rally_state, "thief", "barracks", "enemy")
	_expect(float(monster_effect.get("move_speed_multiplier", 1.0)) > 1.0, "집결 효과가 이동 중인 아군 몬스터에게 적용된다")
	_expect(not enemy_effect.has("move_speed_multiplier"), "집결 효과가 같은 방의 적에게 잘못 적용되지 않는다")

	state = CommandService.new_state(8, 8, 12.0)
	var fallback := CommandService.issue(state, "emergency_fallback", {"type": "defense_zone", "id": "defense_recovery"}, plan, ledger)
	var fallback_order := CommandService.movement_order_for_actor(fallback.get("state", {}), "slime", "entrance", "monster")
	_expect(str(fallback_order.get("command_id", "")) == "emergency_fallback", "비상 후퇴가 실제 몬스터 AI 이동 명령으로 연결된다")
	_expect(str(fallback_order.get("target_room_id", "")) == "recovery", "비상 후퇴가 선택한 구역의 앵커 방으로 이동시킨다")

	var combat_source := FileAccess.get_file_as_string(COMBAT_SOURCE)
	var issue_body := _function_body(combat_source, "issue_v122_command")
	_expect(not issue_body.contains("_set_global_directive"), "전술 명령 실행은 지속형 전체 지침과 분리된다")
	_expect(not issue_body.contains("_set_room_directive"), "전술 명령 실행은 지속형 방 지침과 분리된다")
	_expect(_function_body(combat_source, "update_monster_path").contains("_apply_v122_movement_order"), "몬스터 경로 AI가 활성 명령 이동을 최우선으로 처리한다")
	var path_body := _function_body(combat_source, "update_monster_path")
	var focus_index := path_body.find("command_focus_target != null")
	var directive_index := path_body.find("_apply_room_directive")
	var role_index := path_body.find("thief_hunter")
	_expect(focus_index >= 0 and directive_index > focus_index, "집중 명령은 방 지침보다 먼저 처리한다")
	_expect(directive_index >= 0 and role_index > directive_index, "방 지침은 자율 역할 AI보다 먼저 처리한다")
	_expect(combat_source.contains("_room_directive_active_for_unit"), "입구·함정 지침은 관련 방어구역 몬스터에만 적용한다")
	var defense_body := _function_body(combat_source, "_defense_target")
	_expect(not defense_body.contains("_v122_defender_connector_path"), "사수 전술은 연결로만 있다는 이유로 반대 전선을 추격하지 않는다")


func _test_directive_and_tutorial_contract() -> void:
	var root_source := FileAccess.get_file_as_string(ROOT_SOURCE)
	_expect(root_source.contains("_global_directive_description"), "전체 전술은 이름뿐 아니라 실제 AI 효과 설명을 제공한다")
	_expect(root_source.contains("_room_directive_description"), "선택 방 예외는 전체 전술과 다른 효과 설명을 제공한다")
	_expect(root_source.contains("_show_room_directive_feedback"), "방 지침 선택 직후 수락과 실제 효과를 표시한다")
	var setter_body := _function_body(FileAccess.get_file_as_string(COMBAT_SOURCE), "set_room_directive")
	var rebuild_index := setter_body.find("_set_screen")
	var deferred_feedback_index := setter_body.find("call_deferred")
	_expect(rebuild_index >= 0 and deferred_feedback_index > rebuild_index, "방 지침 수락 토스트는 HUD 재구성 뒤 표시한다")
	_expect(root_source.contains("_draw_room_selection_and_directive_feedback"), "방 지침과 건설 가능 슬롯은 맵 위 지속 배지로 표시한다")
	_expect(root_source.contains("_day_one_global_directive_locked"), "DAY 01 사수 기본값은 다시 고르게 하지 않고 잠근다")
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(TUTORIAL_PATH))
	_expect(parsed is Dictionary, "튜토리얼 데이터를 읽을 수 있다")
	if not parsed is Dictionary:
		return
	var step_ids: Array[String] = []
	var goblin_step: Dictionary = {}
	for value in parsed.get("tutorial_steps", []):
		if not value is Dictionary:
			continue
		step_ids.append(str(value.get("id", "")))
		if str(value.get("id", "")) == "TUT_130_GOBLIN_CONTROL":
			goblin_step = value
	_expect(not step_ids.has("TUT_050_GLOBAL_DEFEND"), "이미 기본인 사수를 다시 고르게 하는 DAY 01 단계를 제거한다")
	var goblin_text := str(goblin_step.get("text", ""))
	_expect(goblin_text.contains("기준") and goblin_text.contains("집중"), "고블린 관찰 단계가 자동 AI의 이유와 명령으로 바뀌는 점을 설명한다")
	_expect(FileAccess.get_file_as_string(TUTORIAL_PATH).contains("+ 건설 가능"), "DAY 2 대사가 보물실 전선의 건설 슬롯을 안내한다")
	_expect(root_source.contains("_tutorial_step_is_observation"), "전투 관찰 단계는 조작 UI를 가리는 스포트라이트와 분리된다")


func _test_connected_map_editor_contract() -> void:
	var root_source := FileAccess.get_file_as_string(ROOT_SOURCE)
	var open_body := _function_body(root_source, "_open_map_editor")
	_expect(open_body.contains("_repair_required_main_route"), "맵 편집 진입 시 입구-왕좌 기본 경로를 먼저 연결한다")
	_expect(open_body.contains("주 경로 고정"), "맵 편집 상태가 보호된 기본 경로를 명확히 안내한다")
	var renderer_source := FileAccess.get_file_as_string(RENDERER_SOURCE)
	var selection_body := _function_body(renderer_source, "_draw_selected_module_highlight")
	_expect(not selection_body.contains("draw_string"), "선택 방 이름표는 전면 소품 아래 정적 맵에 그리지 않는다")
	var draw_body := _function_body(renderer_source, "draw")
	var grid_index := draw_body.find("_draw_map_editor_planning_grid")
	var object_index := draw_body.find("_draw_object_layer")
	_expect(grid_index >= 0 and object_index >= 0 and grid_index < object_index, "확장형 편집 그리드와 연결 길을 건물 오브젝트보다 먼저 그린다")
	_expect(renderer_source.contains("_draw_map_editor_route_overlay"), "편집 중 실제 입구-왕좌 연결을 강한 경로로 표시한다")


func _function_body(source: String, function_name: String) -> String:
	var marker := "func %s(" % function_name
	var start := source.find(marker)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + marker.length())
	return source.substr(start, source.length() - start) if next < 0 else source.substr(start, next - start)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
