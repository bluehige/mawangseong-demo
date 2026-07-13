extends Control
class_name DuoLinkLoadoutScreen

signal link_toggled(link_id: String)
signal auto_use_changed(enabled: bool)
signal preset_saved(slot_index: int)
signal preset_loaded(slot_index: int)
signal auto_recommend_requested
signal confirmed
signal canceled

const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const DESIGN_SIZE := Vector2(1920, 1080)
const LINK_CARD_RECTS := [Rect2(150, 330, 510, 460), Rect2(690, 330, 510, 460), Rect2(1230, 330, 510, 460)]

var profile: Dictionary = {}
var active_run: Dictionary = {}
var catalog: Dictionary = {}
var deployed_instance_ids: Array = []
var content_root: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_fit_design_canvas)
	_build()
	call_deferred("_fit_design_canvas")


func setup(profile_value: Dictionary, active_run_value: Dictionary, catalog_value: Dictionary, deployed_value: Array) -> void:
	profile = profile_value.duplicate(true)
	active_run = active_run_value.duplicate(true)
	catalog = catalog_value.duplicate(true)
	deployed_instance_ids = deployed_value.duplicate()
	if is_node_ready():
		_build()


func slot_contract() -> Dictionary:
	var equipped: Array = active_run.get("equipped_duo_links", [])
	return {
		"slot_1": str(equipped[0]) if equipped.size() > 0 else "",
		"slot_2": str(equipped[1]) if equipped.size() > 1 else "",
		"max_slots": 2
	}


func _build() -> void:
	if content_root != null and is_instance_valid(content_root):
		content_root.queue_free()
	content_root = Control.new()
	content_root.name = "DuoLinkLoadoutDesignCanvas"
	content_root.size = DESIGN_SIZE
	add_child(content_root)
	var backdrop := ColorRect.new()
	backdrop.size = DESIGN_SIZE
	backdrop.color = Color("#08060dea")
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_root.add_child(backdrop)
	_add_label(content_root, "합동기 편성", Rect2(150, 66, 920, 64), 42, Color("#fff1c9"), UIFontScript.ROLE_EMPHASIS)
	_add_label(content_root, "새 회차에 사용할 합동기를 최대 2개까지 고릅니다. 같은 몬스터는 두 합동기에 중복 편성할 수 없습니다.", Rect2(152, 132, 1460, 42), 19, Color("#d7cddd"), UIFontScript.ROLE_BODY)
	_build_slots()
	if bool(profile.get("duo_link_auto_recommendation_unlocked", false)):
		var recommend_button := _add_button(content_root, "자동 추천", Rect2(870, 220, 190, 64), Callable(self, "_request_auto_recommend"), false)
		recommend_button.name = "DuoLinkAutoRecommendButton"
		recommend_button.tooltip_text = "현재 출전 멤버가 모두 갖춰진 해금 합동기를 우선해 최대 2개를 추천합니다."
	var auto_toggle := CheckButton.new()
	auto_toggle.name = "DuoLinkAutoUseToggle"
	auto_toggle.position = Vector2(1080, 220)
	auto_toggle.size = Vector2(690, 64)
	auto_toggle.text = "게이지 100에서 자동 사용"
	auto_toggle.button_pressed = bool(active_run.get("duo_link_auto_use", false))
	auto_toggle.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_BODY))
	auto_toggle.add_theme_font_size_override("font_size", 18)
	auto_toggle.toggled.connect(_on_auto_use_toggled)
	content_root.add_child(auto_toggle)
	if catalog.is_empty():
		_add_label(content_root, "등록된 합동기가 없습니다.", Rect2(150, 330, 1620, 80), 24, Color("#9b91a2"), UIFontScript.ROLE_BODY)
	else:
		var order := ["link_spore_jelly_shelter", "link_stone_march", "link_false_beacon_vault"]
		for link_id_value in catalog.keys():
			if not order.has(str(link_id_value)):
				order.append(str(link_id_value))
		var visible_index := 0
		for link_id in order:
			if not catalog.has(link_id):
				continue
			if visible_index >= LINK_CARD_RECTS.size():
				break
			_build_link_card(link_id, LINK_CARD_RECTS[visible_index])
			visible_index += 1
	var warnings := _deployment_warnings()
	_add_label(content_root, "\n".join(warnings) if not warnings.is_empty() else "출전 멤버가 모두 갖춰진 합동기는 전투에서 충전할 수 있습니다.", Rect2(150, 820, 1620, 64), 17, Color("#f1c982") if not warnings.is_empty() else Color("#a9c7b3"), UIFontScript.ROLE_BODY)
	_build_preset_controls()
	_add_button(content_root, "이전", Rect2(150, 930, 250, 62), Callable(self, "_cancel"), false)
	_add_button(content_root, "편성 확정", Rect2(1470, 930, 300, 62), Callable(self, "_confirm"), false)
	_fit_design_canvas()


func _build_slots() -> void:
	var slots := slot_contract()
	for index in range(2):
		var link_id := str(slots.get("slot_%d" % (index + 1), ""))
		var rect := Rect2(150 + index * 430, 210, 400, 86)
		var panel := Panel.new()
		panel.position = rect.position
		panel.size = rect.size
		panel.add_theme_stylebox_override("panel", _style(Color("#15101ded"), Color("#8d6c9f"), 2, 8))
		content_root.add_child(panel)
		_add_label(panel, "슬롯 %d" % (index + 1), Rect2(18, 10, 110, 26), 14, Color("#bca8c7"), UIFontScript.ROLE_EMPHASIS)
		_add_label(panel, str(catalog.get(link_id, {}).get("display_name", "비어 있음")), Rect2(18, 38, 364, 34), 20, Color("#fff0d1") if link_id != "" else Color("#7f7485"), UIFontScript.ROLE_BODY)


func _build_link_card(link_id: String, rect: Rect2) -> void:
	var definition: Dictionary = catalog.get(link_id, {})
	var unlocked: bool = profile.get("duo_links", {}).get("unlocked", []).has(link_id)
	var equipped: bool = active_run.get("equipped_duo_links", []).has(link_id)
	var card := Panel.new()
	card.position = rect.position
	card.size = rect.size
	card.add_theme_stylebox_override("panel", _style(Color("#17101ff2"), Color("#b88c52") if unlocked else Color("#554c5c"), 2, 10))
	content_root.add_child(card)
	_add_label(card, str(definition.get("display_name", link_id)) if unlocked else "잠긴 합동기", Rect2(28, 24, 454, 44), 27, Color("#fff0c8") if unlocked else Color("#827989"), UIFontScript.ROLE_EMPHASIS)
	var members: Array = definition.get("member_names", definition.get("member_instance_ids", []))
	_add_label(card, " + ".join(members), Rect2(30, 76, 450, 32), 19, Color("#cfb7da") if unlocked else Color("#706878"), UIFontScript.ROLE_BODY)
	if unlocked:
		_add_label(card, "충전\n%s" % _gauge_summary(definition), Rect2(30, 124, 450, 82), 15, Color("#d8d0dc"), UIFontScript.ROLE_BODY)
		_add_label(card, "발동\n%s" % _effect_summary(link_id, definition), Rect2(30, 216, 450, 104), 15, Color("#c7e2ce"), UIFontScript.ROLE_BODY)
		_add_label(card, str(definition.get("tradeoff", "")), Rect2(30, 326, 450, 62), 14, Color("#e4bdb8"), UIFontScript.ROLE_BODY)
	else:
		var condition: Dictionary = definition.get("unlock_condition", {})
		_add_label(card, "해금 힌트\n유대 %d · 개인 기억 각 %d개\n함께 출전 %d일 · 역할 조합 %d회" % [int(condition.get("bond_each", 45)), int(condition.get("personal_memory_each", 1)), int(condition.get("deployed_together_days", 3)), int(condition.get("role_combo_count", 5))], Rect2(30, 142, 450, 130), 16, Color("#918796"), UIFontScript.ROLE_BODY)
	var button_text := "장착 해제" if equipped else "장착"
	_add_button(card, button_text, Rect2(30, 398, 450, 48), _toggle.bind(link_id), not unlocked)


func _gauge_summary(definition: Dictionary) -> String:
	var parts: Array[String] = []
	for source_value in definition.get("gauge_sources", []):
		if not (source_value is Dictionary):
			continue
		var source: Dictionary = source_value
		parts.append("%s %d마다 +%d" % [_source_name(str(source.get("source_id", ""))), int(source.get("threshold", 1)), int(source.get("gain", 0))])
	return " / ".join(parts)


func _source_name(source_id: String) -> String:
	match source_id:
		"damage_absorbed": return "피해 흡수"
		"effective_heal": return "실제 회복"
		"fixed_attack": return "고정 상태 공격"
		"buffed_ally": return "버프 아군"
		"mark_success": return "표식 성공"
		"false_treasure_contact": return "가짜 보물 접촉"
		_: return source_id


func _effect_summary(link_id: String, _definition: Dictionary) -> String:
	match link_id:
		"link_stone_march": return "반경 180 피해 12·사기 -30 / 아군 방어+1·이동+6%"
		"link_false_beacon_vault": return "6초 등대 / 일반 적 최대 2명 유인 / 확인한 적 표식"
		_: return "반경 190 보호막 40 / 5초간 초당 회복 3 / 정화 1개"


func _deployment_warnings() -> Array[String]:
	var warnings: Array[String] = []
	for link_id_value in active_run.get("equipped_duo_links", []):
		var link_id := str(link_id_value)
		var missing: Array[String] = []
		for member in catalog.get(link_id, {}).get("member_instance_ids", []):
			if not deployed_instance_ids.has(member):
				missing.append(str(member))
		if not missing.is_empty():
			warnings.append("주의 · %s은(는) 멤버 미출전으로 비활성 예정입니다: %s" % [str(catalog.get(link_id, {}).get("display_name", link_id)), ", ".join(missing)])
	return warnings


func _toggle(link_id: String) -> void:
	link_toggled.emit(link_id)


func _on_auto_use_toggled(enabled: bool) -> void:
	auto_use_changed.emit(enabled)


func _build_preset_controls() -> void:
	var preset_slots := clampi(int(profile.get("duo_link_preset_slots", 0)), 0, 2)
	if preset_slots <= 0:
		return
	_add_label(content_root, "E15 편성 프리셋", Rect2(500, 888, 190, 34), 15, Color("#e4c47e"), UIFontScript.ROLE_EMPHASIS)
	for index in range(preset_slots):
		var x := 700.0 + index * 390.0
		var load_button := _add_button(content_root, "프리셋 %d 불러오기" % (index + 1), Rect2(x, 886, 190, 38), Callable(self, "_load_preset").bind(index), false)
		load_button.name = "DuoPresetLoad%d" % (index + 1)
		var save_button := _add_button(content_root, "현재 편성 저장", Rect2(x + 198, 886, 180, 38), Callable(self, "_save_preset").bind(index), false)
		save_button.name = "DuoPresetSave%d" % (index + 1)


func _save_preset(slot_index: int) -> void:
	preset_saved.emit(slot_index)


func _load_preset(slot_index: int) -> void:
	preset_loaded.emit(slot_index)


func _request_auto_recommend() -> void:
	auto_recommend_requested.emit()


func _confirm() -> void:
	confirmed.emit()


func _cancel() -> void:
	canceled.emit()


func _add_label(parent: Control, text_value: String, rect: Rect2, font_size: int, color: Color, role: String) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", UIFontScript.font_for_role(role))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _add_button(parent: Control, text_value: String, rect: Rect2, callback: Callable, disabled: bool) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = text_value
	button.disabled = disabled
	button.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_EMPHASIS))
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_stylebox_override("normal", _style(Color("#25172ff3"), Color("#a77b43"), 2, 8))
	button.add_theme_stylebox_override("hover", _style(Color("#3a2548fa"), Color("#ffd47b"), 2, 8))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style


func _fit_design_canvas() -> void:
	if content_root == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var factor := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	content_root.scale = Vector2.ONE * factor
	content_root.position = (size - DESIGN_SIZE * factor) * 0.5


func link_card_rects_for_viewport(viewport_size: Vector2) -> Array[Rect2]:
	var factor := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	var offset := (viewport_size - DESIGN_SIZE * factor) * 0.5
	var result: Array[Rect2] = []
	for rect in LINK_CARD_RECTS:
		result.append(Rect2(offset + rect.position * factor, rect.size * factor))
	return result
