extends Node

const CombatViewModel = preload("res://scripts/v122/ui/V122CombatResultViewModel.gd")
const CouncilOverlay = preload("res://scripts/ui/Update4CouncilDecisionOverlay.gd")

var assertions := 0
var failures: Array[String] = []
var confirmed_instance_id := ""
var confirmed_crown_id := ""


func _ready() -> void:
	_test_combat_room_labels()
	_test_unknown_room_fallback()
	_test_crown_candidate_hides_internal_id()
	if failures.is_empty():
		print("V122_PLAYER_FACING_LABEL_TEST: PASS (%d assertions)" % assertions)
		get_tree().quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("V122_PLAYER_FACING_LABEL_TEST: FAIL (%d assertions, %d failures)" % [assertions, failures.size()])
	get_tree().quit(1)


func _test_combat_room_labels() -> void:
	var model := CombatViewModel.build_combat(
		{
			"enemy_goals": ["throne"],
			"active_route": ["entrance", "service_entrance", "path_b_entry_front", "throne"]
		},
		[],
		{},
		{"points": 0, "max_points": 0}
	)
	_expect(str(model.get("objective_label", "")) == "방어 목표 · 왕좌", "전투 목표가 내부 room ID 대신 사용자 용어를 쓴다")
	_expect(str(model.get("active_route_label", "")) == "활성 경로 · 정문 입구 → 서비스 침입 균열 → 연결 통로 → 왕좌", "활성 경로가 알려진 구역과 통로를 사용자 용어로 표시한다")
	_expect(not str(model.get("active_route_label", "")).contains("_"), "활성 경로에 내부 ID 구분자가 노출되지 않는다")


func _test_unknown_room_fallback() -> void:
	var model := CombatViewModel.build_combat(
		{"enemy_goals": ["future_room"], "active_route": ["future_room"]},
		[],
		{},
		{"points": 0, "max_points": 0}
	)
	_expect(str(model.get("objective_label", "")) == "방어 목표 · 미확인 구역", "미등록 목표가 내부 ID 대신 안전한 안내 문구를 쓴다")
	_expect(str(model.get("active_route_label", "")) == "활성 경로 · 미확인 구역", "미등록 경로가 내부 ID 대신 안전한 안내 문구를 쓴다")
	_expect(not str(model.get("objective_label", "")).contains("future_room") and not str(model.get("active_route_label", "")).contains("future_room"), "사용자 표시 문구에 미등록 내부 room ID가 남지 않는다")


func _test_crown_candidate_hides_internal_id() -> void:
	var overlay := CouncilOverlay.new()
	var parent := VBoxContainer.new()
	overlay.crown_confirmed.connect(_on_crown_confirmed)
	overlay._build_crown(
		parent,
		{"council_season": {"council_seals": 1, "alternative_seal_resource": 0}},
		{
			"crown_evolutions": {
				"crown_gob_midnight_marshal": {
					"weakness_text": "빛 속성에 약함"
				}
			}
		},
		[{
			"display_name": "곱",
			"instance_id": "MON_GOBLIN",
			"crown_form_id": "crown_gob_midnight_marshal"
		}]
	)
	var candidate_button: Button = null
	for button_value in parent.find_children("*", "Button", true, false):
		var button := button_value as Button
		if button != null and button.text.begins_with("곱"):
			candidate_button = button
			break
	_expect(candidate_button != null, "왕관 후보 버튼이 생성된다")
	if candidate_button != null:
		_expect(not candidate_button.text.contains("MON_GOBLIN"), "왕관 후보 문구에서 내부 instance ID를 숨긴다")
		_expect(candidate_button.text.contains("빛 속성에 약함"), "왕관 선택에 필요한 약점 정보는 유지한다")
		candidate_button.pressed.emit()
	_expect(confirmed_instance_id == "MON_GOBLIN", "내부 instance ID는 화면에 숨겨도 선택 신호에는 보존된다")
	_expect(confirmed_crown_id == "crown_gob_midnight_marshal", "왕관 ID는 선택 신호에 보존된다")
	overlay.free()
	parent.free()


func _on_crown_confirmed(instance_id: String, crown_id: String) -> void:
	confirmed_instance_id = instance_id
	confirmed_crown_id = crown_id


func _expect(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)
