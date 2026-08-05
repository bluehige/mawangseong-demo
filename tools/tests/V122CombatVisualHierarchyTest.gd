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
	_test_grounding_structure()
	_test_profile_specific_anchors()
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
	_expect(source.contains("var visual_body: Node2D"), "유닛은 바닥 root와 분리된 visual body를 가진다")
	_expect(source.contains("visual_body.add_child(sprite)"), "스프라이트는 visual body 아래에 둔다")
	_expect(source.contains("visual_body.position = pose_position"), "포즈 이동은 visual body에만 적용한다")
	_expect(source.contains("down_foot_anchor"), "쓰러짐은 별도 바닥 앵커를 사용한다")


func _test_grounding_structure() -> void:
	var unit = UnitScript.new()
	add_child(unit)
	var root_position := Vector2(420.0, 260.0)
	unit.global_position = root_position
	unit.setup(
		"thief",
		{
			"display_name": "도둑",
			"max_hp": 80,
			"sprite": "res://assets/sprites/enemies/enemy_thief_idle_down_00.png"
		},
		Constants.FACTION_ENEMY,
		"treasure"
	)
	_expect(unit.visual_body != null, "유닛 visual body가 생성된다")
	_expect(unit.visual_body.get_parent() == unit, "visual body는 유닛 바닥 root의 자식이다")
	_expect(unit.sprite.get_parent() == unit.visual_body, "스프라이트는 visual body의 자식이다")
	_expect(unit.sprite.position == Vector2.ZERO, "스프라이트 자체에는 월드 기준 오프셋을 넣지 않는다")
	var profile_motion: Dictionary = unit.combat_visual_profile.get("motion_entry", {})
	_expect(profile_motion.get("down_foot_anchor", []) is Array, "프로필에 쓰러짐 발 앵커가 있다")
	_expect(profile_motion.get("shadow_offset_px", []) is Array, "프로필에 그림자 오프셋이 있다")
	unit.visual_phase = 0.0
	unit.velocity = Vector2.ZERO
	unit._apply_visual_pose()
	var idle_foot := _foot_world_position(unit, profile_motion.get("foot_anchor", []))
	unit.visual_phase = 0.2
	unit.velocity = Vector2.RIGHT * 100.0
	unit._apply_visual_pose()
	var move_foot := _foot_world_position(unit, profile_motion.get("foot_anchor", []))
	_expect(unit.global_position == root_position, "이동 포즈가 유닛 월드 바닥 root를 움직이지 않는다")
	_expect(idle_foot.distance_to(move_foot) <= 2.0, "지상 이동 포즈의 발 흔들림은 2픽셀 이내다")
	unit.velocity = Vector2.ZERO
	unit.attack_anim_timer = 0.2
	unit.action_direction = Vector2(0.0, -1.0)
	unit._apply_visual_pose()
	var attack_foot := _foot_world_position(unit, profile_motion.get("foot_anchor", []))
	_expect(idle_foot.distance_to(attack_foot) <= 2.0, "지상 공격 포즈의 발 흔들림은 2픽셀 이내다")
	unit.attack_anim_timer = 0.0
	unit.down = true
	unit._apply_visual_pose()
	var down_anchor: Array = profile_motion.get("down_foot_anchor", [])
	var down_foot := _foot_world_position(unit, down_anchor)
	_expect(down_foot.distance_to(root_position) <= 2.0, "쓰러짐 포즈도 별도 발 앵커로 바닥에 남는다")
	unit.queue_free()

	var flying = UnitScript.new()
	add_child(flying)
	flying.setup(
		"imp",
		{
			"display_name": "임프",
			"max_hp": 60,
			"sprite": "res://assets/sprites/monsters/monster_imp_idle_down_00.png"
		},
		Constants.FACTION_MONSTER,
		"corridor_a"
	)
	_expect(flying._is_flying_unit(), "비행 유닛은 데이터 프로필에서 flying을 읽는다")
	flying.queue_free()


func _foot_world_position(unit, anchor_value) -> Vector2:
	if not anchor_value is Array or anchor_value.size() != 2:
		return unit.global_position
	var frame: Array = unit.combat_visual_profile.get("source_frame_px", [])
	if frame.size() != 2:
		return unit.global_position
	return unit.global_position + unit.visual_body.position + unit.sprite.position + Vector2(
		(float(anchor_value[0]) - 0.5) * float(frame[0]) * unit.sprite.scale.x,
		(float(anchor_value[1]) - 0.5) * float(frame[1]) * unit.sprite.scale.y
	)


func _test_profile_specific_anchors() -> void:
	DataRegistry.load_all()
	var expected := {
		"slime": {
			"idle": [29, 71, 169, 181],
			"down": [76, 25, 181, 185],
			"idle_anchor_y": 0.942708,
			"down_anchor_y": 0.963542
		},
		"thief": {
			"idle": [35, 24, 155, 173],
			"down": [24, 51, 172, 138],
			"idle_anchor_y": 0.901042,
			"down_anchor_y": 0.71875
		}
	}
	var overrides: Dictionary = DataRegistry.combat_visual_profiles.get("unit_overrides", {})
	for unit_id_value in expected.keys():
		var unit_id := str(unit_id_value)
		var override: Dictionary = overrides.get(unit_id, {})
		var grounding: Dictionary = override.get("grounding_anchors", {})
		var case_data: Dictionary = expected[unit_id]
		_expect(not grounding.is_empty(), "%s 개별 접지 앵커가 프로필에 있다" % unit_id)
		_expect(str(grounding.get("runtime_consumption_state", "")) == "PENDING_V3_PROFILE_CONNECT", "%s 개별 앵커의 연결 대기 상태가 명시된다" % unit_id)
		_expect(_arrays_equal(grounding.get("idle_alpha_bbox_px", []), case_data["idle"]), "%s idle alpha bbox가 원본 측정과 일치한다" % unit_id)
		_expect(_arrays_equal(grounding.get("down_alpha_bbox_px", []), case_data["down"]), "%s down alpha bbox가 원본 측정과 일치한다" % unit_id)
		var idle_anchor: Array = grounding.get("idle_foot_anchor", [])
		var down_anchor: Array = grounding.get("down_foot_anchor", [])
		_expect(idle_anchor.size() == 2 and is_equal_approx(float(idle_anchor[1]), float(case_data["idle_anchor_y"])), "%s idle 발 앵커가 측정값과 일치한다" % unit_id)
		_expect(down_anchor.size() == 2 and is_equal_approx(float(down_anchor[1]), float(case_data["down_anchor_y"])), "%s down 발 앵커가 측정값과 일치한다" % unit_id)
		var runtime_path := str(override.get("runtime_path", ""))
		var down_path := runtime_path.replace("_idle_down_00.png", "_down_00.png")
		var idle_bbox := _alpha_bbox(runtime_path)
		var down_bbox := _alpha_bbox(down_path)
		_expect(_arrays_equal(idle_bbox, case_data["idle"]), "%s runtime idle bbox 재측정이 일치한다" % unit_id)
		_expect(_arrays_equal(down_bbox, case_data["down"]), "%s runtime down bbox 재측정이 일치한다" % unit_id)


func _alpha_bbox(path: String) -> Array:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		return []
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.0:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return []
	return [min_x, min_y, max_x + 1, max_y + 1]


func _arrays_equal(left_value, right_value) -> bool:
	if not left_value is Array or not right_value is Array or left_value.size() != right_value.size():
		return false
	for index in range(left_value.size()):
		if left_value[index] != right_value[index]:
			return false
	return true


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
