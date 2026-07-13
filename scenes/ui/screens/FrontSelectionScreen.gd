extends Control
class_name FrontSelectionScreen

signal front_selected(front_id: String)
signal invitation_selected(front_id: String)
signal front_rotation_changed(enabled: bool)
signal canceled

const FrontCampaignServiceScript = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const FRONT_ART_SHEET := preload("res://assets/ui/fronts/front_chronicle_sheet.png")
const DESIGN_SIZE := Vector2(1920, 1080)
const CARD_ORDER := [
	FrontCampaignServiceScript.HERO_FRONT_ID,
	FrontCampaignServiceScript.HOLY_FRONT_ID,
	FrontCampaignServiceScript.GUILD_FRONT_ID
]
const CARD_RECTS := {
	"front_hero_oath": Rect2(132, 310, 520, 540),
	"front_holy_purification": Rect2(700, 310, 520, 540),
	"front_guild_repossession": Rect2(1268, 310, 520, 540)
}
const RIVAL_NAMES := {"leon": "레온", "selen": "셀렌", "roman": "로만"}

var profile: Dictionary = {}
var catalog: Dictionary = {}
var cycle_index := 1
var allow_cancel := true
var content_root: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_fit_design_canvas)
	if content_root == null:
		_build()
	call_deferred("_fit_design_canvas")


func setup(profile_value: Dictionary, catalog_value: Dictionary, current_cycle: int, cancel_enabled: bool = true) -> void:
	profile = FrontCampaignServiceScript.reconcile_unlocks(profile_value, catalog_value)
	catalog = catalog_value.duplicate(true)
	cycle_index = maxi(1, current_cycle)
	allow_cancel = cancel_enabled
	if is_node_ready():
		_build()


func layout_rects_for_viewport(viewport_size: Vector2) -> Dictionary:
	var factor := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	var offset := (viewport_size - DESIGN_SIZE * factor) * 0.5
	var result: Dictionary = {}
	for front_id in CARD_RECTS.keys():
		var source: Rect2 = CARD_RECTS[front_id]
		result[front_id] = Rect2(offset + source.position * factor, source.size * factor)
	return result


func _build() -> void:
	if content_root != null and is_instance_valid(content_root):
		content_root.queue_free()
	content_root = Control.new()
	content_root.name = "DesignCanvas"
	content_root.position = Vector2.ZERO
	content_root.size = DESIGN_SIZE
	add_child(content_root)

	var backdrop := TextureRect.new()
	backdrop.name = "FrontSelectionBackdrop"
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
	shade.color = Color("#07040cdd")
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_root.add_child(shade)

	_add_label(content_root, "새 회차 작전 전선", Rect2(132, 54, 1200, 66), 42, Color("#fff3d2"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(content_root, "%d회차 · 한 전선을 선택하면 이번 30일 캠페인에 유지됩니다." % cycle_index, Rect2(134, 124, 1260, 34), 19, Color("#c9bfd2"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_BODY)
	_add_label(content_root, "작전 지도  /  FINAL RIVAL ROUTE", Rect2(1390, 70, 398, 36), 17, Color("#d7a9ff"), HORIZONTAL_ALIGNMENT_RIGHT, UIFontScript.ROLE_EMPHASIS)
	var rotation_unlocked := bool(profile.get("front_rotation_unlocked", false))
	var rotation_enabled := rotation_unlocked and bool(profile.get("front_rotation_enabled", false))
	var rotation_text := "전선 순환 · 잠김"
	if rotation_unlocked:
		rotation_text = "전선 순환 · 켜짐" if rotation_enabled else "전선 순환 · 꺼짐 (기본)"
	var rotation_button := _add_button(content_root, rotation_text, Rect2(1470, 116, 318, 48), Callable(self, "_toggle_front_rotation"), not rotation_unlocked)
	rotation_button.name = "FrontRotationButton"
	rotation_button.tooltip_text = "E16 대휴전 엔딩 보상입니다. 해금되어도 기본값은 꺼짐이며, 직접 켠 뒤에만 다음 회차의 전선 순환 변형이 적용됩니다." if rotation_unlocked else "E16 대휴전 엔딩을 보면 해금됩니다."

	_build_invitation_strip()
	for front_id in CARD_ORDER:
		_build_front_card(front_id)

	_add_label(content_root, "전선 선택은 저장됩니다. 각 전선은 고유 적·작전·최종 라이벌과 후일담으로 이어집니다.", Rect2(420, 888, 1080, 34), 17, Color("#bcb2c5"), HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_BODY)
	var cancel_button := _add_button(content_root, "나중에 선택하기", Rect2(760, 946, 400, 64), Callable(self, "_cancel"), false)
	cancel_button.name = "FrontSelectionCancelButton"
	cancel_button.visible = allow_cancel

	modulate.a = 0.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.18)
	_fit_design_canvas()


func _build_invitation_strip() -> void:
	var required := FrontCampaignServiceScript.invitation_required(profile, catalog)
	var strip := Panel.new()
	strip.name = "InvitationStrip"
	strip.position = Vector2(132, 180)
	strip.size = Vector2(1656, 98)
	strip.add_theme_stylebox_override("panel", _style(Color("#1d1328ee"), Color("#9b6a27"), 2, 10))
	content_root.add_child(strip)
	var text := "첫 진입 초대장  ·  대체 전선 하나를 즉시 해금하세요." if required else "프로필 해금 상태가 적용되었습니다. 금색 표시의 전선만 선택할 수 있습니다."
	_add_label(strip, text, Rect2(28, 16, 910, 62), 18, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	if required:
		var holy := _add_button(strip, "성광 초대장", Rect2(1010, 20, 280, 58), Callable(self, "_choose_invitation").bind(FrontCampaignServiceScript.HOLY_FRONT_ID), false)
		holy.name = "HolyInvitationButton"
		var guild := _add_button(strip, "길드 소환장", Rect2(1310, 20, 280, 58), Callable(self, "_choose_invitation").bind(FrontCampaignServiceScript.GUILD_FRONT_ID), false)
		guild.name = "GuildInvitationButton"


func _build_front_card(front_id: String) -> void:
	var definition: Dictionary = catalog.get(front_id, {})
	var locked := FrontCampaignServiceScript.lock_reason(profile, front_id, catalog) != ""
	var card := Button.new()
	card.name = "FrontCardButton_%s" % front_id
	var rect: Rect2 = CARD_RECTS[front_id]
	card.position = rect.position
	card.size = rect.size
	card.text = ""
	card.disabled = locked
	card.focus_mode = Control.FOCUS_ALL
	var accent := Color("#8f64ad") if locked else Color("#d3a84b")
	var normal_color := Color("#15101ddf") if locked else Color("#1a1124f2")
	card.add_theme_stylebox_override("normal", _style(normal_color, accent, 2, 12))
	card.add_theme_stylebox_override("hover", _style(Color("#2b1b39f5"), Color("#ffd36a"), 3, 12))
	card.add_theme_stylebox_override("pressed", _style(Color("#100a16f8"), Color("#fff0b0"), 3, 12))
	card.add_theme_stylebox_override("disabled", _style(Color("#100d16e8"), Color("#55465e"), 2, 12))
	card.pressed.connect(_choose_front.bind(front_id))
	content_root.add_child(card)
	var art_index := CARD_ORDER.find(front_id)
	var emblem := TextureRect.new()
	emblem.name = "FrontEmblem_%s" % front_id
	emblem.position = Vector2(354, 14)
	emblem.size = Vector2(136, 136)
	emblem.texture = _sheet_cell(FRONT_ART_SHEET, Vector2i(art_index, 0), Vector2i(4, 3))
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.material = _chroma_material()
	emblem.modulate.a = 0.72 if not locked else 0.28
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(emblem)
	var rival_art := TextureRect.new()
	rival_art.name = "RivalCrest_%s" % front_id
	rival_art.position = Vector2(374, 198)
	rival_art.size = Vector2(116, 116)
	rival_art.texture = _sheet_cell(FRONT_ART_SHEET, Vector2i(art_index, 1), Vector2i(4, 3))
	rival_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rival_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rival_art.material = _chroma_material()
	rival_art.modulate.a = 0.78 if not locked else 0.28
	rival_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(rival_art)

	var state_text := "LOCKED  /  잠김" if locked else "AVAILABLE  /  선택 가능"
	var state_color := Color("#81768a") if locked else Color("#ffd36a")
	_add_label(card, state_text, Rect2(30, 24, 460, 28), 15, state_color, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(card, str(definition.get("display_name", front_id)), Rect2(30, 72, 460, 54), 31, Color("#938b99") if locked else Color("#fff6df"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(card, str(definition.get("summary", "")), Rect2(30, 132, 460, 72), 17, Color("#918996") if locked else Color("#d8d0df"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_BODY)
	var rival_id := str(definition.get("final_rival_id", ""))
	_add_label(card, "최종 라이벌", Rect2(30, 228, 150, 24), 14, Color("#a899b2"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_BODY)
	_add_label(card, str(RIVAL_NAMES.get(rival_id, rival_id)), Rect2(190, 218, 158, 38), 23, Color("#b2aab7") if locked else Color("#f2d38b"), HORIZONTAL_ALIGNMENT_RIGHT, UIFontScript.ROLE_EMPHASIS)
	_add_divider(card, 274)
	_add_label(card, "주요 위험", Rect2(30, 298, 130, 24), 14, Color("#a899b2"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(card, _join_labels(definition.get("danger_goals", [])), Rect2(30, 330, 460, 52), 16, Color("#aaa1ae") if locked else Color("#e5dce8"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_BODY)
	_add_label(card, "추천 역할", Rect2(30, 398, 130, 24), 14, Color("#a899b2"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(card, _join_labels(definition.get("recommended_role_tags", [])), Rect2(30, 430, 460, 46), 16, Color("#aaa1ae") if locked else Color("#d7b3f0"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_BODY)
	var footer := FrontCampaignServiceScript.lock_reason(profile, front_id, catalog) if locked else "이 전선으로 새 회차 시작"
	_add_label(card, footer, Rect2(30, 492, 460, 30), 14, Color("#786f80") if locked else Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_EMPHASIS)


func _choose_front(front_id: String) -> void:
	front_selected.emit(front_id)


func _choose_invitation(front_id: String) -> void:
	invitation_selected.emit(front_id)


func _toggle_front_rotation() -> void:
	if not bool(profile.get("front_rotation_unlocked", false)):
		return
	front_rotation_changed.emit(not bool(profile.get("front_rotation_enabled", false)))


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
	button.add_theme_color_override("font_color", Color("#fff2cf"))
	button.add_theme_stylebox_override("normal", _style(Color("#251730f4"), Color("#9b6a27"), 2, 8))
	button.add_theme_stylebox_override("hover", _style(Color("#3a2348f8"), Color("#ffd36a"), 2, 8))
	button.add_theme_stylebox_override("pressed", _style(Color("#150d1df8"), Color("#fff0b0"), 2, 8))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _add_divider(parent: Control, y: float) -> void:
	var divider := ColorRect.new()
	divider.position = Vector2(30, y)
	divider.size = Vector2(460, 1)
	divider.color = Color("#5d4c67")
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
