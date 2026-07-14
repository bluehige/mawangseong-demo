extends Control
class_name OutpostBattleRoot

signal battle_settled(result: Dictionary)

const EncounterServiceScript = preload("res://scripts/systems/outpost/OutpostEncounterService.gd")
const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const DESIGN_SIZE := Vector2(1920, 1080)
const MODULES := [
	["OutpostGate", "전초기지 성문", Rect2(120, 424, 300, 230), "#39506b"],
	["OutpostCenter", "중앙 마당", Rect2(470, 364, 300, 350), "#465a43"],
	["OutpostCache", "보급 창고", Rect2(820, 424, 300, 230), "#665038"],
	["OutpostRetreat", "퇴각 통로", Rect2(1170, 424, 300, 230), "#55405e"]
]

var outpost: Dictionary = {}
var encounter: Dictionary = {}
var type_definition: Dictionary = {}
var defender_names: Array[String] = []
var day := 10
var battle_state: Dictionary = {}
var content_root: Control
var enemy_layer: Control
var banner_bar: ProgressBar
var banner_label: Label
var timer_label: Label
var status_label: Label
var result_overlay: Panel


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_fit_design_canvas)
	_build()
	_reset_battle(0)
	call_deferred("_fit_design_canvas")


func setup(outpost_value: Dictionary, encounter_value: Dictionary, type_value: Dictionary, defender_names_value: Array, current_day: int) -> void:
	outpost = outpost_value.duplicate(true)
	encounter = encounter_value.duplicate(true)
	type_definition = type_value.duplicate(true)
	defender_names.clear()
	for value in defender_names_value:
		defender_names.append(str(value))
	day = current_day
	if is_node_ready():
		_build()
		_reset_battle(0)


func _process(delta: float) -> void:
	if battle_state.is_empty() or bool(battle_state.get("completed", false)):
		return
	battle_state = EncounterServiceScript.step(battle_state, delta)
	_refresh_battle_view()
	if bool(battle_state.get("completed", false)):
		_show_result()


func _build() -> void:
	if content_root != null and is_instance_valid(content_root):
		content_root.queue_free()
	content_root = Control.new()
	content_root.name = "DesignCanvas"
	content_root.size = DESIGN_SIZE
	add_child(content_root)
	var background := ColorRect.new()
	background.size = DESIGN_SIZE
	background.color = Color("#09070d")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -2
	content_root.add_child(background)
	var art_state := "level2" if int(outpost.get("level", 0)) >= 2 else ("damaged" if bool(outpost.get("damaged", false)) else "base")
	var outpost_art := TextureRect.new()
	outpost_art.name = "OutpostBattleArt_%s" % art_state
	outpost_art.position = Vector2(160, 218)
	outpost_art.size = Vector2(1390, 570)
	var outpost_art_path := str(type_definition.get("art_states", {}).get(art_state, ""))
	if not outpost_art_path.is_empty():
		outpost_art.texture = load(outpost_art_path)
	outpost_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	outpost_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	outpost_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outpost_art.modulate = Color(1, 1, 1, 0.34)
	outpost_art.z_index = 0
	content_root.add_child(outpost_art)
	var header := Panel.new()
	header.position = Vector2(70, 46)
	header.size = Vector2(1780, 160)
	header.add_theme_stylebox_override("panel", _style(Color("#120d18f5"), Color("#785d39"), 2, 12))
	header.z_index = 10
	content_root.add_child(header)
	_add_label(header, "전초기지 방어전", Rect2(34, 20, 700, 54), 38, Color("#fff1d0"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(header, "DAY %02d · %s" % [day, str(type_definition.get("display_name", outpost.get("type_id", "")))], Rect2(36, 70, 700, 30), 19, Color("#d7b46b"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(header, str(type_definition.get("battle_text", "")), Rect2(36, 104, 950, 28), 15, Color("#bdb0c4"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_BODY)
	timer_label = _add_label(header, "00.0 / 55.0초", Rect2(1270, 20, 470, 42), 25, Color("#d9cce0"), HORIZONTAL_ALIGNMENT_RIGHT, UIFontScript.ROLE_EMPHASIS)
	status_label = _add_label(header, "배치 0명", Rect2(1130, 76, 610, 32), 17, Color("#b9aebe"), HORIZONTAL_ALIGNMENT_RIGHT, UIFontScript.ROLE_BODY)

	for module_data in MODULES:
		var panel := Panel.new()
		panel.name = str(module_data[0])
		var rect: Rect2 = module_data[2]
		panel.position = rect.position
		panel.size = rect.size
		panel.add_theme_stylebox_override("panel", _style(Color(str(module_data[3]) + "aa"), Color(str(module_data[3])).lightened(0.25), 2, 10))
		panel.z_index = 3
		content_root.add_child(panel)
		_add_label(panel, str(module_data[1]), Rect2(18, 16, rect.size.x - 36, 34), 20, Color("#f4e9d7"), HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_EMPHASIS)
		_add_label(panel, "고정 모듈", Rect2(18, rect.size.y - 44, rect.size.x - 36, 24), 14, Color("#aaa0ae"), HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_BODY)
	var route := ColorRect.new()
	route.position = Vector2(220, 530)
	route.size = Vector2(1400, 18)
	route.color = Color("#8e7043")
	route.mouse_filter = Control.MOUSE_FILTER_IGNORE
	route.z_index = 5
	content_root.add_child(route)

	var banner := Panel.new()
	banner.name = "OutpostBanner"
	banner.position = Vector2(1530, 354)
	banner.size = Vector2(260, 420)
	banner.add_theme_stylebox_override("panel", _style(Color("#27162ef5"), Color("#d9a94e"), 4, 14))
	banner.z_index = 10
	content_root.add_child(banner)
	_add_label(banner, "깃발", Rect2(20, 26, 220, 48), 31, Color("#ffe4a0"), HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_EMPHASIS)
	banner_bar = ProgressBar.new()
	banner_bar.position = Vector2(36, 104)
	banner_bar.size = Vector2(188, 250)
	banner_bar.fill_mode = ProgressBar.FILL_BOTTOM_TO_TOP
	banner_bar.show_percentage = false
	banner.add_child(banner_bar)
	banner_label = _add_label(banner, "0 / 0", Rect2(20, 360, 220, 34), 20, Color("#fff1d0"), HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_EMPHASIS)

	var defender_panel := Panel.new()
	defender_panel.name = "DefenderRoster"
	defender_panel.position = Vector2(120, 786)
	defender_panel.size = Vector2(1350, 170)
	defender_panel.add_theme_stylebox_override("panel", _style(Color("#120e18ef"), Color("#4d4056"), 2, 10))
	defender_panel.z_index = 10
	content_root.add_child(defender_panel)
	_add_label(defender_panel, "파견 수비대", Rect2(26, 18, 260, 34), 22, Color("#fff0ce"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	for slot in 3:
		var name := defender_names[slot] if slot < defender_names.size() else "빈 배치 칸"
		var slot_panel := Panel.new()
		slot_panel.name = "DefenderSlot%d" % (slot + 1)
		slot_panel.position = Vector2(28 + slot * 430, 72)
		slot_panel.size = Vector2(398, 72)
		slot_panel.add_theme_stylebox_override("panel", _style(Color("#211729"), Color("#705d78"), 1, 8))
		defender_panel.add_child(slot_panel)
		_add_label(slot_panel, "%d · %s" % [slot + 1, name], Rect2(16, 10, 366, 52), 18, Color("#f1e5f3") if slot < defender_names.size() else Color("#817785"), HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_EMPHASIS)

	enemy_layer = Control.new()
	enemy_layer.name = "EnemyLayer"
	enemy_layer.size = DESIGN_SIZE
	enemy_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_layer.z_index = 20
	content_root.add_child(enemy_layer)
	_add_label(content_root, "전초기지 패배는 왕좌 패배가 아닙니다. 재도전하거나 결과를 수용해 다음 DAY로 진행할 수 있습니다.", Rect2(260, 984, 1400, 34), 16, Color("#b4a8b8"), HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_BODY)
	result_overlay = null
	_fit_design_canvas()


func _reset_battle(retry_count: int) -> void:
	battle_state = EncounterServiceScript.new_battle_state(outpost, encounter, day, retry_count, type_definition)
	if result_overlay != null and is_instance_valid(result_overlay):
		content_root.remove_child(result_overlay)
		result_overlay.queue_free()
	result_overlay = null
	set_process(true)
	_refresh_battle_view()


func _refresh_battle_view() -> void:
	if timer_label == null:
		return
	var elapsed := float(battle_state.get("elapsed", 0.0))
	var target := float(encounter.get("target_duration_seconds", 55.0))
	timer_label.text = "%04.1f / %04.1f초" % [elapsed, target]
	var effect_status := ""
	if bool(battle_state.get("supply_chest_used", false)):
		effect_status = " · 회복 상자 +%d" % int(battle_state.get("supply_chest_healing", 0))
	elif int(battle_state.get("detoured_count", 0)) > 0:
		effect_status = " · 우회 %d" % int(battle_state.get("detoured_count", 0))
	status_label.text = "배치 %d명 · 적 %d명 · 재도전 %d회%s" % [int(battle_state.get("defender_count", 0)), battle_state.get("enemies", []).size(), int(battle_state.get("retry_count", 0)), effect_status]
	banner_bar.max_value = float(battle_state.get("banner_max_hp", 1))
	banner_bar.value = float(battle_state.get("banner_hp", 0))
	banner_label.text = "%d / %d" % [int(battle_state.get("banner_hp", 0)), int(battle_state.get("banner_max_hp", 0))]
	for child in enemy_layer.get_children():
		child.queue_free()
	for enemy_value in battle_state.get("enemies", []):
		var enemy: Dictionary = enemy_value
		var marker := Panel.new()
		marker.name = "Enemy%d" % int(enemy.get("id", 0))
		marker.position = Vector2(230.0 + 1360.0 * float(enemy.get("progress", 0.0)), 496.0 + float(int(enemy.get("id", 0)) % 3) * 36.0)
		marker.size = Vector2(74, 32)
		marker.add_theme_stylebox_override("panel", _style(Color("#6a2830"), Color("#ff8c80"), 2, 8))
		enemy_layer.add_child(marker)
		_add_label(marker, "침입자", Rect2(4, 2, 66, 28), 12, Color("#ffe4df"), HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_EMPHASIS)


func _show_result() -> void:
	set_process(false)
	var battle_result := EncounterServiceScript.result(battle_state)
	result_overlay = Panel.new()
	result_overlay.name = "BattleResultOverlay"
	result_overlay.position = Vector2(500, 260)
	result_overlay.size = Vector2(920, 560)
	result_overlay.z_index = 100
	result_overlay.add_theme_stylebox_override("panel", _style(Color("#100b16fc"), Color("#ffd36a") if bool(battle_result.get("win", false)) else Color("#e06f74"), 4, 16))
	content_root.add_child(result_overlay)
	_add_label(result_overlay, "깃발 방어 성공" if bool(battle_result.get("win", false)) else "깃발 방어 실패", Rect2(60, 52, 800, 72), 42, Color("#fff1d0"), HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_EMPHASIS)
	_add_label(result_overlay, "전투 시간  %.1f초   ·   깃발 HP  %d / %d" % [float(battle_result.get("duration_seconds", 0.0)), int(battle_result.get("ending_hp", 0)), int(battle_result.get("max_hp", 0))], Rect2(80, 150, 760, 44), 21, Color("#d8ccd9"), HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_BODY)
	_add_label(result_overlay, "본성 왕좌와 캠페인 패배 플래그에는 영향을 주지 않습니다.", Rect2(80, 222, 760, 42), 18, Color("#bcaec1"), HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_BODY)
	if not bool(battle_result.get("win", false)):
		var retry_button := _add_button(result_overlay, "재도전", Rect2(120, 390, 300, 76), Callable(self, "_retry"), false)
		retry_button.name = "RetryButton"
		var settle_loss_button := _add_button(result_overlay, "패배 수용", Rect2(500, 390, 300, 76), Callable(self, "_settle"), false)
		settle_loss_button.name = "SettleLossButton"
	else:
		var settle_win_button := _add_button(result_overlay, "결산으로", Rect2(310, 390, 300, 76), Callable(self, "_settle"), false)
		settle_win_button.name = "SettleWinButton"


func _retry() -> void:
	_reset_battle(int(battle_state.get("retry_count", 0)) + 1)


func _settle() -> void:
	battle_settled.emit(EncounterServiceScript.result(battle_state))


func debug_complete(win: bool) -> void:
	battle_state["elapsed"] = float(encounter.get("minimum_result_seconds", 45.0))
	battle_state["banner_hp"] = int(battle_state.get("banner_max_hp", 1)) if win else 0
	battle_state["completed"] = true
	battle_state["win"] = win
	_show_result()


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
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color("#fff2cf"))
	button.add_theme_stylebox_override("normal", _style(Color("#251730f4"), Color("#9b6a27"), 2, 8))
	button.add_theme_stylebox_override("hover", _style(Color("#3a2348f8"), Color("#ffd36a"), 2, 8))
	button.add_theme_stylebox_override("pressed", _style(Color("#150d1df8"), Color("#fff0b0"), 2, 8))
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
