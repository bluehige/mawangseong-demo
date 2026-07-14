extends Control
class_name RegionSelectionScreen

signal region_selected(region_id: String)
signal canceled

const RegionRouteServiceScript = preload("res://scripts/systems/regions/RegionRouteService.gd")
const CouncilChronicleScript = preload("res://scripts/systems/chronicle/CouncilChronicleService.gd")
const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const DESIGN_SIZE := Vector2(1920, 1080)
const CARD_ORDER := [
	"region_ironbell_ravine",
	"region_moonbat_aerie",
	"region_mistcap_marsh",
	"region_bone_lantern_fields",
	"region_blackwater_exchange"
]
const CARD_RECTS := {
	"region_ironbell_ravine": Rect2(132, 238, 520, 318),
	"region_moonbat_aerie": Rect2(700, 238, 520, 318),
	"region_mistcap_marsh": Rect2(1268, 238, 520, 318),
	"region_bone_lantern_fields": Rect2(416, 594, 520, 318),
	"region_blackwater_exchange": Rect2(984, 594, 520, 318)
}

var active_run: Dictionary = {}
var catalog: Dictionary = {}
var day := 4
var allow_cancel := true
var accessibility: Dictionary = CouncilChronicleScript.default_accessibility()
var mastery_by_region: Dictionary = {}
var content_root: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_fit_design_canvas)
	if content_root == null:
		_build()
	call_deferred("_fit_design_canvas")


func setup(active_run_value: Dictionary, catalog_value: Dictionary, current_day: int, cancel_enabled: bool = true, accessibility_value: Dictionary = {}, mastery_value: Dictionary = {}) -> void:
	active_run = active_run_value.duplicate(true)
	catalog = catalog_value.duplicate(true)
	day = current_day
	allow_cancel = cancel_enabled
	accessibility = CouncilChronicleScript.normalize_accessibility(accessibility_value)
	mastery_by_region = mastery_value.duplicate(true)
	if is_node_ready():
		_build()


func layout_rects_for_viewport(viewport_size: Vector2) -> Dictionary:
	var factor := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	var offset := (viewport_size - DESIGN_SIZE * factor) * 0.5
	var result := {}
	for region_id in CARD_RECTS:
		var source: Rect2 = CARD_RECTS[region_id]
		result[region_id] = Rect2(offset + source.position * factor, source.size * factor)
	return result


func _build() -> void:
	if content_root != null and is_instance_valid(content_root):
		content_root.queue_free()
	content_root = Control.new()
	content_root.name = "DesignCanvas"
	content_root.size = DESIGN_SIZE
	content_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content_root)

	var backdrop := TextureRect.new()
	backdrop.name = "RegionSelectionBackdrop"
	backdrop.size = DESIGN_SIZE
	backdrop.texture = load("res://assets/ui/onboarding/scenes/scene_demon_castle_dialogue.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_root.add_child(backdrop)
	var shade := ColorRect.new()
	shade.size = DESIGN_SIZE
	shade.color = Color("#07040cef")
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_root.add_child(shade)

	var selected := RegionRouteServiceScript.selected_region_ids(active_run)
	var slot := RegionRouteServiceScript.pending_selection_slot(active_run, day)
	_add_label(content_root, "마계 의회 지역 경로", Rect2(132, 48, 1100, 60), 42, Color("#fff3d2"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(content_root, "DAY %02d · %d번째 지역을 선택하세요" % [day, slot + 1], Rect2(134, 112, 1000, 38), 21, Color("#d9b86c"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(content_root, "선택 순서가 챕터 순서입니다. 같은 회차에는 같은 지역을 다시 고를 수 없습니다.", Rect2(134, 156, 1280, 32), 18, Color("#c9bfd2"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_BODY)
	_add_label(content_root, "REGION ROUTE  %d / 3" % selected.size(), Rect2(1400, 70, 388, 36), 17, Color("#cfa9ee"), HORIZONTAL_ALIGNMENT_RIGHT, UIFontScript.ROLE_EMPHASIS)
	var route_text := RegionRouteServiceScript.selection_summary(active_run, catalog)
	_add_label(content_root, "현재 경로  ·  %s" % (route_text if route_text != "" else "아직 선택하지 않음"), Rect2(1100, 124, 688, 34), 17, Color("#c4b6cf"), HORIZONTAL_ALIGNMENT_RIGHT, UIFontScript.ROLE_BODY)

	for region_id in CARD_ORDER:
		_build_region_card(region_id, selected)

	_add_label(content_root, "지역 문양과 환경 그림은 전투 규칙·적 풀·보상을 구분합니다. 모든 수치는 선택 전에 확인할 수 있습니다.", Rect2(280, 934, 1360, 32), 16, Color("#aaa0b1"), HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_BODY)
	var cancel_button := _add_button(content_root, "제목으로 돌아가기", Rect2(760, 982, 400, 58), Callable(self, "_cancel"), false)
	cancel_button.name = "RegionSelectionCancelButton"
	cancel_button.visible = allow_cancel

	if bool(accessibility.get("reduce_region_motion", false)):
		modulate.a = 1.0
	else:
		modulate.a = 0.0
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "modulate:a", 1.0, 0.18)
	_fit_design_canvas()


func _build_region_card(region_id: String, selected: Array[String]) -> void:
	var definition: Dictionary = catalog.get(region_id, {})
	var order_index := selected.find(region_id)
	var already_selected := order_index >= 0
	var available := not already_selected and RegionRouteServiceScript.selection_pending(active_run, day)
	var mastery := clampi(int(mastery_by_region.get(region_id, 0)), 0, 3)
	var rect: Rect2 = CARD_RECTS[region_id]
	var accent := Color(str(definition.get("accent", "#c89f53")))
	var card := Button.new()
	card.name = "RegionCardButton_%s" % region_id
	card.position = rect.position
	card.size = rect.size
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.text = ""
	card.disabled = not available
	card.clip_contents = true
	card.focus_mode = Control.FOCUS_ALL
	card.add_theme_stylebox_override("normal", _style(Color("#17101ff5"), accent.darkened(0.18), 2, 12))
	card.add_theme_stylebox_override("hover", _style(Color("#2b1b39fa"), accent.lightened(0.2), 4, 12))
	card.add_theme_stylebox_override("pressed", _style(Color("#100a16fa"), Color("#fff0b0"), 4, 12))
	card.add_theme_stylebox_override("disabled", _style(Color("#100d16ef"), accent.darkened(0.48), 2, 12))
	card.pressed.connect(_choose_region.bind(region_id))
	card.tooltip_text = "이미 %d번째 지역으로 선택했습니다." % (order_index + 1) if already_selected else str(definition.get("environment_rule_text", ""))
	if mastery >= 2 and bool(accessibility.get("show_region_details", true)):
		card.tooltip_text += "\n숙련 Lv.%d 추가 정보 · %s · %s" % [mastery, str(definition.get("reward_summary", "")), str(definition.get("charter_text", ""))]
	content_root.add_child(card)
	var art := TextureRect.new()
	art.name = "RegionArt_%s" % region_id
	art.position = Vector2(2, 2)
	art.size = Vector2(516, 126)
	var art_path := str(definition.get("card_background", ""))
	if not art_path.is_empty():
		art.texture = load(art_path)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.modulate = Color(1, 1, 1, 0.72 if available else 0.38)
	art.z_index = 0
	card.add_child(art)
	var art_shade := ColorRect.new()
	art_shade.position = art.position
	art_shade.size = art.size
	art_shade.color = Color(0.035, 0.018, 0.05, 0.52)
	art_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_shade.z_index = 1
	card.add_child(art_shade)
	var emblem := TextureRect.new()
	emblem.name = "RegionEmblem_%s" % region_id
	emblem.position = Vector2(430, 52)
	emblem.size = Vector2(64, 64)
	var emblem_path := str(definition.get("emblem", ""))
	if not emblem_path.is_empty():
		emblem.texture = load(emblem_path)
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	emblem.z_index = 2
	card.add_child(emblem)

	var state_text := "%d번째 선택 완료" % (order_index + 1) if already_selected else "선택 가능"
	_add_label(card, state_text, Rect2(26, 18, 220, 24), 14, accent if available else Color("#887b8f"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(card, str(definition.get("rival_name", "")), Rect2(248, 18, 246, 24), 13, Color("#a99bb2"), HORIZONTAL_ALIGNMENT_RIGHT, UIFontScript.ROLE_BODY)
	_add_label(card, str(definition.get("display_name", region_id)), Rect2(26, 48, 468, 44), 29, Color("#fff4d8") if available else Color("#aaa2ad"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(card, str(definition.get("pressure_summary", "")), Rect2(26, 94, 468, 34), 15, Color("#d3c8d8"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_BODY)
	_add_divider(card, 136)
	_add_label(card, "환경", Rect2(26, 145, 54, 24), 14, accent, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(card, str(definition.get("environment_rule_text", "")), Rect2(86, 142, 408, 34), 15, Color("#e7deea"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_BODY)
	_add_label(card, "주요 적", Rect2(26, 185, 66, 24), 14, accent, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(card, " · ".join(PackedStringArray(definition.get("enemy_names", []))), Rect2(100, 182, 394, 34), 15, Color("#e7deea"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_BODY)
	_add_label(card, "보상", Rect2(26, 225, 54, 24), 14, accent, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(card, str(definition.get("reward_summary", "")), Rect2(86, 222, 408, 34), 15, Color("#e7deea"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_BODY)
	var mastery_label := _add_label(card, "숙련 Lv.%d  ·  인장  ·  %s" % [mastery, str(definition.get("charter_text", ""))], Rect2(26, 270, 468, 28), 14, Color("#cbb9d3"), HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_EMPHASIS)
	mastery_label.name = "RegionMastery_%s" % region_id


func _choose_region(region_id: String) -> void:
	region_selected.emit(region_id)


func _cancel() -> void:
	canceled.emit()


func _fit_design_canvas() -> void:
	if content_root == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var factor := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	content_root.scale = Vector2.ONE * factor
	content_root.position = (size - DESIGN_SIZE * factor) * 0.5


func _add_label(parent: Control, text_value: String, rect: Rect2, font_size: int, color: Color, alignment: HorizontalAlignment, role: String) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.text = text_value
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", UIFontScript.font_for_role(role))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 3
	parent.add_child(label)
	return label


func _add_button(parent: Control, text_value: String, rect: Rect2, callback: Callable, disabled: bool) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.text = text_value
	button.disabled = disabled
	button.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_EMPHASIS))
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("#fff2cf"))
	button.add_theme_stylebox_override("normal", _style(Color("#251730f4"), Color("#9b6a27"), 2, 8))
	button.add_theme_stylebox_override("hover", _style(Color("#3a2348f8"), Color("#ffd36a"), 2, 8))
	button.add_theme_stylebox_override("pressed", _style(Color("#150d1df8"), Color("#fff0b0"), 2, 8))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _add_divider(parent: Control, y: float) -> void:
	var divider := ColorRect.new()
	divider.position = Vector2(26, y)
	divider.size = Vector2(468, 1)
	divider.color = Color("#5d4c67")
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	divider.z_index = 3
	parent.add_child(divider)


func _style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
