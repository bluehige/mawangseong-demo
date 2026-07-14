extends Control
class_name HeartSelectionScreen

signal heart_selected(heart_id: String)
signal canceled

const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const DESIGN_SIZE := Vector2(1920, 1080)
const HEART_ICON_SHEET := preload("res://assets/ui/hearts/heart_icons_vfx_sheet.png")
const CARD_ORDER := ["heart_stonebone", "heart_hungry_maw", "heart_dream_lantern"]
const CARD_RECTS := {
	"heart_stonebone": Rect2(132, 250, 520, 650),
	"heart_hungry_maw": Rect2(700, 250, 520, 650),
	"heart_dream_lantern": Rect2(1268, 250, 520, 650)
}
const ACCENTS := {
	"heart_stonebone": Color("#c5a46a"),
	"heart_hungry_maw": Color("#d86b63"),
	"heart_dream_lantern": Color("#a887e8")
}
const SIGILS := {"heart_stonebone": "◆", "heart_hungry_maw": "◉", "heart_dream_lantern": "✦"}

var profile: Dictionary = {}
var catalog: Dictionary = {}
var front_name := ""
var allow_cancel := true
var content_root: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_fit_design_canvas)
	if content_root == null:
		_build()
	call_deferred("_fit_design_canvas")


func setup(profile_value: Dictionary, catalog_value: Dictionary, selected_front_name: String, cancel_enabled: bool = true) -> void:
	profile = profile_value.duplicate(true)
	catalog = catalog_value.duplicate(true)
	front_name = selected_front_name
	allow_cancel = cancel_enabled
	if is_node_ready():
		_build()


func layout_rects_for_viewport(viewport_size: Vector2) -> Dictionary:
	var factor := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	var offset := (viewport_size - DESIGN_SIZE * factor) * 0.5
	var result: Dictionary = {}
	for heart_id in CARD_RECTS.keys():
		var source: Rect2 = CARD_RECTS[heart_id]
		result[heart_id] = Rect2(offset + source.position * factor, source.size * factor)
	return result


func comparison_contract(heart_id: String) -> Dictionary:
	var definition: Dictionary = catalog.get(heart_id, {})
	return {
		"strengths": definition.get("passives", []).duplicate(),
		"tradeoffs": definition.get("tradeoffs", []).duplicate(),
		"recommended_monsters": definition.get("recommended_monsters", []).duplicate(),
		"danger_enemies": definition.get("danger_enemies", []).duplicate(),
		"event_candidate_id": str(definition.get("event_candidate_id", ""))
	}


func _build() -> void:
	if content_root != null and is_instance_valid(content_root):
		content_root.queue_free()
	content_root = Control.new()
	content_root.name = "DesignCanvas"
	content_root.position = Vector2.ZERO
	content_root.size = DESIGN_SIZE
	content_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content_root)

	var backdrop := TextureRect.new()
	backdrop.name = "HeartSelectionBackdrop"
	backdrop.position = Vector2.ZERO
	backdrop.size = DESIGN_SIZE
	backdrop.texture = load("res://assets/ui/onboarding/scenes/scene_demon_castle_dialogue.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_root.add_child(backdrop)
	var shade := ColorRect.new()
	shade.position = Vector2.ZERO
	shade.size = DESIGN_SIZE
	shade.color = Color("#05030ae8")
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_root.add_child(shade)

	_add_label(content_root, "마왕성의 심장을 깨워라", Rect2(132, 54, 1100, 64), 42, Color("#fff3d2"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(content_root, "%s · 이 회차에서 단 하나의 심장만 선택할 수 있습니다." % (front_name if front_name != "" else "선택한 전선"), Rect2(134, 122, 1280, 38), 19, Color("#d2c8d8"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_BODY)
	_add_label(content_root, "강점과 대가는 같은 비중으로 표시되며 별도의 난이도 등급은 없습니다.", Rect2(134, 170, 1280, 34), 17, Color("#b9a9c4"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_BODY)
	_add_label(content_root, "LIVING CASTLE / HEART COVENANT", Rect2(1370, 78, 418, 34), 16, Color("#d7a9ff"), HORIZONTAL_ALIGNMENT_RIGHT, UIFontScript.ROLE_EMPHASIS)

	for heart_id in CARD_ORDER:
		_build_heart_card(heart_id)
	var cancel_button := _add_button(content_root, "나중에 선택하기", Rect2(760, 946, 400, 64), Callable(self, "_cancel"), false)
	cancel_button.name = "HeartSelectionCancelButton"
	cancel_button.visible = allow_cancel
	_fit_design_canvas()


func _build_heart_card(heart_id: String) -> void:
	var definition: Dictionary = catalog.get(heart_id, {})
	var unlocked: bool = profile.get("hearts", {}).get("unlocked", []).has(heart_id)
	var rect: Rect2 = CARD_RECTS[heart_id]
	var accent: Color = ACCENTS.get(heart_id, Color("#d3a84b"))
	var card := Button.new()
	card.name = "HeartCardButton_%s" % heart_id
	card.position = rect.position
	card.size = rect.size
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.text = ""
	card.disabled = not unlocked
	card.focus_mode = Control.FOCUS_ALL
	card.add_theme_stylebox_override("normal", _style(Color("#17101ff4"), accent, 2, 12))
	card.add_theme_stylebox_override("hover", _style(Color("#2a1b38fa"), accent.lightened(0.18), 3, 12))
	card.add_theme_stylebox_override("pressed", _style(Color("#0d0913fa"), Color("#fff0bd"), 3, 12))
	card.add_theme_stylebox_override("disabled", _style(Color("#100d16e8"), Color("#55465e"), 2, 12))
	card.pressed.connect(_choose_heart.bind(heart_id))
	content_root.add_child(card)

	var icon_index := CARD_ORDER.find(heart_id)
	var icon := TextureRect.new()
	icon.name = "HeartIcon_%s" % heart_id
	icon.position = Vector2(22, 14)
	icon.size = Vector2(66, 66)
	icon.texture = _sheet_cell(HEART_ICON_SHEET, Vector2i(icon_index, 0), Vector2i(3, 2))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.material = _chroma_material()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon)
	_add_label(card, str(definition.get("display_name", heart_id)), Rect2(92, 22, 394, 48), 29, Color("#fff6df"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(card, "선택 가능" if unlocked else "잠김", Rect2(310, 70, 176, 26), 14, accent if unlocked else Color("#81768a"), HORIZONTAL_ALIGNMENT_RIGHT, UIFontScript.ROLE_EMPHASIS)
	_add_divider(card, 112, accent.darkened(0.35))
	_add_section(card, "강점", definition.get("passives", []), 134, Color("#d9f2cf"))
	_add_section(card, "대가", definition.get("tradeoffs", []), 312, Color("#ffd2cc"))
	_add_divider(card, 466, Color("#5d4c67"))
	_add_label(card, "추천 몬스터", Rect2(28, 486, 174, 26), 14, Color("#bea5ce"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(card, _join_labels(definition.get("recommended_monsters", [])), Rect2(28, 516, 464, 42), 16, Color("#eee5f1"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_BODY)
	_add_label(card, "주의할 적", Rect2(28, 562, 174, 26), 14, Color("#d9a39e"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(card, _join_labels(definition.get("danger_enemies", [])), Rect2(28, 592, 464, 34), 15, Color("#f0d5d1"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_BODY)


func _add_section(parent: Control, title: String, values, y: float, color: Color) -> void:
	_add_label(parent, title, Rect2(28, y, 120, 28), 15, color, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	var lines: Array[String] = []
	if values is Array:
		for value in values:
			lines.append("• %s" % str(value))
	_add_label(parent, "\n".join(lines) if not lines.is_empty() else "-", Rect2(28, y + 34, 464, 132), 15, Color("#e6dfe9"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_BODY)


func _choose_heart(heart_id: String) -> void:
	heart_selected.emit(heart_id)


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
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
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


func _add_divider(parent: Control, y: float, color: Color) -> void:
	var divider := ColorRect.new()
	divider.position = Vector2(28, y)
	divider.size = Vector2(464, 1)
	divider.color = color
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(divider)


func _style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _sheet_cell(sheet: Texture2D, cell: Vector2i, grid: Vector2i) -> AtlasTexture:
	var cell_size := Vector2(sheet.get_width() / float(grid.x), sheet.get_height() / float(grid.y))
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(cell) * cell_size, cell_size)
	return atlas


func _chroma_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); float m=min(c.r,c.b)-c.g; float balance=1.0-smoothstep(0.10,0.32,abs(c.r-c.b)); float k=smoothstep(0.10,0.34,m)*balance; c.a*=1.0-k; COLOR=c; }"
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _join_labels(values) -> String:
	if not (values is Array):
		return "-"
	var labels: Array[String] = []
	for value in values:
		labels.append(str(value))
	return "  ·  ".join(labels) if not labels.is_empty() else "-"
