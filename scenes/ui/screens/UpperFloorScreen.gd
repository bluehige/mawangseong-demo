extends Control
class_name UpperFloorScreen

signal layout_selected(layout_id: String)
signal closed

const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const DESIGN_SIZE := Vector2(1920, 1080)
const ORDER := ["upper_compact_guard", "upper_split_vault", "upper_long_gallery"]
const CARD_RECTS := [Rect2(120, 246, 520, 560), Rect2(700, 246, 520, 560), Rect2(1280, 246, 520, 560)]

var upper_floor: Dictionary = {}
var layouts: Dictionary = {}
var modules: Dictionary = {}
var content_root: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_fit)
	_build()
	call_deferred("_fit")


func setup(upper_value: Dictionary, layouts_value: Dictionary, modules_value: Dictionary) -> void:
	upper_floor = upper_value.duplicate(true)
	layouts = layouts_value.duplicate(true)
	modules = modules_value.duplicate(true)
	if is_node_ready():
		_build()


func layout_rects_for_viewport(viewport_size: Vector2) -> Array[Rect2]:
	var factor := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	var offset := (viewport_size - DESIGN_SIZE * factor) * 0.5
	var result: Array[Rect2] = []
	for rect in CARD_RECTS:
		result.append(Rect2(offset + rect.position * factor, rect.size * factor))
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
	backdrop.size = DESIGN_SIZE
	backdrop.texture = load("res://assets/ui/onboarding/scenes/scene_demon_castle_dialogue.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_root.add_child(backdrop)
	var shade := ColorRect.new()
	shade.size = DESIGN_SIZE
	shade.color = Color("#07050bea")
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_root.add_child(shade)
	_add_label(content_root, "제한적 2층 왕성", Rect2(120, 48, 1100, 66), 43, Color("#fff1ce"), HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(content_root, "상층은 기존 1층 전력을 나누는 선택입니다. 총 출전 수는 늘어나지 않습니다.", Rect2(122, 120, 1500, 38), 19, Color("#cdbfd2"), HORIZONTAL_ALIGNMENT_LEFT)
	var locked := bool(upper_floor.get("layout_locked", false))
	_add_label(content_root, "LAYOUT  ·  %s" % ("확정됨" if locked else "세 레이아웃 중 하나 선택"), Rect2(1180, 68, 620, 40), 18, Color("#d7b469"), HORIZONTAL_ALIGNMENT_RIGHT)
	for index in ORDER.size():
		_build_card(index, ORDER[index], locked)
	var close := _button(content_root, "관리 화면으로", Rect2(760, 916, 400, 72), Callable(self, "_close"), false)
	close.name = "UpperFloorCloseButton"
	_fit()


func _build_card(index: int, layout_id: String, locked: bool) -> void:
	var definition: Dictionary = layouts.get(layout_id, {})
	var selected := str(upper_floor.get("layout_id", "")) == layout_id
	var card := Button.new()
	card.name = "UpperLayout_%s" % layout_id
	card.position = CARD_RECTS[index].position
	card.size = CARD_RECTS[index].size
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.text = ""
	card.disabled = locked
	var accent: Color = [Color("#8bb6dc"), Color("#b58bdd"), Color("#d1a96c")][index]
	card.add_theme_stylebox_override("normal", _style(Color("#15101df5"), accent.darkened(0.25), 2))
	card.add_theme_stylebox_override("hover", _style(Color("#24182ffa"), accent.lightened(0.18), 4))
	card.add_theme_stylebox_override("disabled", _style(Color("#100c17f0"), accent if selected else Color("#4c4352"), 4 if selected else 2))
	card.pressed.connect(func(): layout_selected.emit(layout_id))
	content_root.add_child(card)
	_add_label(card, "현재 레이아웃" if selected else ("선택 가능" if not locked else "다른 레이아웃"), Rect2(30, 26, 460, 26), 15, accent, HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(card, str(definition.get("display_name", layout_id)), Rect2(30, 66, 460, 52), 31, Color("#fff1d7"), HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(card, str(definition.get("advantage", "")), Rect2(30, 128, 460, 62), 16, Color("#b7d6c0"), HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(card, "약점 · %s" % str(definition.get("weakness", "")), Rect2(30, 194, 460, 62), 16, Color("#d7a0a7"), HORIZONTAL_ALIGNMENT_LEFT)
	var mini_map := Panel.new()
	mini_map.position = Vector2(30, 278)
	mini_map.size = Vector2(460, 224)
	mini_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mini_map.add_theme_stylebox_override("panel", _style(Color("#0d0a12e8"), Color("#55465e"), 1))
	card.add_child(mini_map)
	mini_map.clip_contents = true
	var preview := TextureRect.new()
	preview.name = "LayoutPreview_%s" % layout_id
	preview.size = mini_map.size
	var preview_path := str(definition.get("preview", ""))
	if not preview_path.is_empty():
		preview.texture = load(preview_path)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.modulate = Color(1, 1, 1, 0.72)
	preview.z_index = 0
	mini_map.add_child(preview)
	for placement in definition.get("placed_modules", []):
		var origin: Array = placement.get("grid_origin", [0, 0])
		var module_id := str(placement.get("module_id", ""))
		var room := Panel.new()
		room.position = Vector2(34 + int(origin[0]) * 96, 28 + int(origin[1]) * 56)
		room.size = Vector2(86, 46)
		room.mouse_filter = Control.MOUSE_FILTER_IGNORE
		room.add_theme_stylebox_override("panel", _style(accent.darkened(0.55), accent, 1))
		room.z_index = 2
		mini_map.add_child(room)
		_add_label(room, str(modules.get(module_id, {}).get("display_name", module_id)), Rect2(4, 2, 78, 42), 10, Color("#f5edf7"), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(card, "고정 4모듈 · 단일 계단 연결", Rect2(30, 518, 460, 28), 14, Color("#aaa0b0"), HORIZONTAL_ALIGNMENT_CENTER)


func _close() -> void:
	closed.emit()


func _fit() -> void:
	if content_root == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var factor := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	content_root.scale = Vector2.ONE * factor
	content_root.position = (size - DESIGN_SIZE * factor) * 0.5


func _add_label(parent: Control, value: String, rect: Rect2, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.text = value
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_EMPHASIS))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 3
	parent.add_child(label)
	return label


func _button(parent: Control, value: String, rect: Rect2, callback: Callable, disabled: bool) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.text = value
	button.disabled = disabled
	button.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_EMPHASIS))
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(12)
	return style
