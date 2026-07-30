extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const UnitScript = preload("res://scripts/units/Unit.gd")
const UNIT_SOURCE := "res://scripts/units/Unit.gd"

var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_unit_information_budget()
	_test_warning_visibility()
	_test_draw_order_contract()
	if failures.is_empty():
		print("V122_COMBAT_VISUAL_HIERARCHY_TEST: PASS")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("V122_COMBAT_VISUAL_HIERARCHY_TEST: FAIL")
	get_tree().quit(1)


func _test_unit_information_budget() -> void:
	var unit = UnitScript.new()
	add_child(unit)
	unit.setup(
		"goblin",
		{"display_name": "고블린", "max_hp": 100},
		Constants.FACTION_MONSTER,
		"corridor_a"
	)
	_expect(not unit.name_label.visible, "정상 상태의 비선택 유닛 이름은 상시 노출하지 않는다")
	_expect(not unit._should_show_hp_bar(), "정상 상태의 비선택 유닛 체력은 상시 노출하지 않는다")
	unit.set_selected(true)
	_expect(unit.name_label.visible, "선택 유닛 이름은 즉시 표시한다")
	_expect(unit._should_show_hp_bar(), "선택 유닛 체력은 즉시 표시한다")
	unit.set_selected(false)
	unit.hp = 49
	unit._sync_combat_label_visibility()
	_expect(unit.name_label.visible, "체력 50% 이하 유닛 이름은 위험 정보로 표시한다")
	_expect(unit._should_show_hp_bar(), "피해를 받은 유닛 체력은 표시한다")
	unit.hp = 75
	unit._sync_combat_label_visibility()
	_expect(not unit.name_label.visible, "경상 비선택 유닛은 이름보다 전장을 우선한다")
	_expect(unit._should_show_hp_bar(), "경상이라도 손실 체력은 얇은 bar로 남긴다")
	unit.queue_free()


func _test_warning_visibility() -> void:
	var thief = UnitScript.new()
	add_child(thief)
	thief.setup(
		"thief",
		{"display_name": "도둑", "max_hp": 80, "role": "treasure"},
		Constants.FACTION_ENEMY,
		"treasure"
	)
	_expect(thief.threat_warning_text() == "보물방 침투", "목표형 적은 전술 경고를 만든다")
	_expect(thief.name_label.visible, "목표형 적 이름은 선택하지 않아도 경고와 함께 표시한다")
	thief.queue_free()


func _test_draw_order_contract() -> void:
	var source := FileAccess.get_file_as_string(UNIT_SOURCE)
	var draw_body := _function_body(source, "_draw")
	var contact_index := draw_body.find("_draw_contact_shadow()")
	var selection_index := draw_body.find("_draw_selection_ground_marker()")
	var effect_index := draw_body.find("ledger_mark_cast_timer")
	var hp_index := draw_body.find("_draw_hp_bar()")
	var warning_index := draw_body.find("_draw_threat_warning()")
	_expect(contact_index >= 0, "모든 유닛은 접지 그림자를 그린다")
	_expect(selection_index > contact_index and selection_index < effect_index, "선택 표시는 접지 뒤·상태 VFX 전에 그린다")
	_expect(hp_index > effect_index and warning_index > hp_index, "체력 뒤에 최우선 전술 경고를 그린다")
	_expect(source.contains("Vector2(1.0, 0.31)"), "접지 그림자는 아이소메트릭 타원 비율을 사용한다")
	_expect(source.contains("MOUSE_FILTER_IGNORE"), "이름 표시는 전투 입력을 가로채지 않는다")


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
