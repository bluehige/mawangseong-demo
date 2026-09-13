extends Control
class_name OutpostBattleRoot

signal battle_settled(result: Dictionary)

const EncounterServiceScript = preload("res://scripts/systems/outpost/OutpostEncounterService.gd")
const UXTheme = preload("res://scripts/ui/UIUXTheme.gd")
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
var defender_visuals: Array = []
var enemy_markers: Dictionary = {}
var settlement_sent := false
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


func setup(outpost_value: Dictionary, encounter_value: Dictionary, type_value: Dictionary, defender_names_value: Array, current_day: int, visuals: Array = []) -> void:
	outpost = outpost_value.duplicate(true)
	encounter = encounter_value.duplicate(true)
	type_definition = type_value.duplicate(true)
	defender_visuals=visuals.duplicate()
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
	if is_instance_valid(content_root):
		remove_child(content_root)
		content_root.queue_free()
	enemy_markers.clear()
	content_root=Control.new()
	content_root.name="DesignCanvas"
	content_root.size=DESIGN_SIZE
	content_root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(content_root)
	var background:=ColorRect.new()
	background.size=DESIGN_SIZE
	background.color=Color("#09070d")
	background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content_root.add_child(background)
	var art_state:="level2" if int(outpost.get("level",0))>=2 else ("damaged" if bool(outpost.get("damaged",false)) else "base")
	var art:=TextureRect.new()
	art.name="OutpostBattleArt_"+art_state
	art.position=Vector2(300,172)
	art.size=Vector2(1300,600)
	var path:=str(type_definition.get("art_states",{}).get(art_state,""))
	if path!="": art.texture=load(path)
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content_root.add_child(art)
	_add_label(content_root,"전초기지 방어전",Rect2(64,38,1010,66),42,UXTheme.PAPER,HORIZONTAL_ALIGNMENT_LEFT,UIFontScript.ROLE_EMPHASIS)
	_add_label(content_root,"DAY %02d · %s · 자동 방어" % [day,str(type_definition.get("display_name","전초기지"))],Rect2(64,112,1240,46),25,UXTheme.GOLD,HORIZONTAL_ALIGNMENT_LEFT,UIFontScript.ROLE_BODY)
	timer_label=_add_label(content_root,"",Rect2(1366,46,480,54),30,UXTheme.PAPER,HORIZONTAL_ALIGNMENT_RIGHT,UIFontScript.ROLE_EMPHASIS)
	status_label=_add_label(content_root,"",Rect2(736,162,1110,52),23,UXTheme.MUTED,HORIZONTAL_ALIGNMENT_RIGHT,UIFontScript.ROLE_BODY)
	var banner:=Panel.new()
	banner.name="OutpostBanner"
	banner.position=Vector2(1430,244)
	banner.size=Vector2(414,180)
	banner.add_theme_stylebox_override("panel",UXTheme.panel(UXTheme.INK,UXTheme.GOLD,2))
	banner.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content_root.add_child(banner)
	banner_label=_add_label(banner,"",Rect2(26,20,362,46),26,UXTheme.PAPER,HORIZONTAL_ALIGNMENT_LEFT,UIFontScript.ROLE_EMPHASIS)
	banner_bar=_health_bar(banner,Rect2(26,88,362,28),Color("#dbae68"))
	_add_label(banner,"깃발을 지키면 방어 성공",Rect2(26,128,362,38),22,UXTheme.MUTED,HORIZONTAL_ALIGNMENT_LEFT,UIFontScript.ROLE_BODY)
	var route:=Line2D.new()
	route.name="OutpostEntryRoute"
	route.points=PackedVector2Array([Vector2(170,670),Vector2(1710,670)])
	route.width=4
	route.default_color=Color("#9b7850")
	content_root.add_child(route)
	for index in MODULES.size():
		var label:=_add_label(content_root,str(MODULES[index][1]),Rect2(100+index*410,730,390,50),22,UXTheme.MUTED,HORIZONTAL_ALIGNMENT_CENTER,UIFontScript.ROLE_BODY)
		label.name=str(MODULES[index][0])
	_add_label(content_root,"진입 →",Rect2(80,590,180,52),24,Color("#f3aca5"),HORIZONTAL_ALIGNMENT_LEFT,UIFontScript.ROLE_EMPHASIS)
	_add_label(content_root,"→ 깃발",Rect2(1680,590,170,52),24,UXTheme.GOLD,HORIZONTAL_ALIGNMENT_RIGHT,UIFontScript.ROLE_EMPHASIS)
	enemy_layer=Control.new()
	enemy_layer.name="EnemyLayer"
	enemy_layer.size=DESIGN_SIZE
	enemy_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content_root.add_child(enemy_layer)
	var defenders:=Panel.new()
	defenders.name="DefenderRoster"
	defenders.position=Vector2(64,824)
	defenders.size=Vector2(1780,180)
	defenders.add_theme_stylebox_override("panel",UXTheme.panel(UXTheme.INK,UXTheme.LINE))
	content_root.add_child(defenders)
	_add_label(defenders,"파견 수비대",Rect2(30,18,240,48),26,UXTheme.GOLD,HORIZONTAL_ALIGNMENT_LEFT,UIFontScript.ROLE_EMPHASIS)
	_add_label(defenders,str(type_definition.get("battle_text","")),Rect2(30,82,340,76),22,UXTheme.MUTED,HORIZONTAL_ALIGNMENT_LEFT,UIFontScript.ROLE_BODY)
	for index in range(3):
		var at:=Vector2(410+index*450,16)
		var slot:=Control.new()
		slot.name="DefenderSlot%d"%(index+1)
		slot.position=at
		slot.size=Vector2(430,148)
		slot.mouse_filter=Control.MOUSE_FILTER_IGNORE
		defenders.add_child(slot)
		var name:=defender_names[index] if index<defender_names.size() else "빈 배치 칸"
		var portrait:=TextureRect.new()
		portrait.name="DefenderPortrait%d"%index
		portrait.position=Vector2.ZERO
		portrait.size=Vector2(142,146)
		portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
		if index<defender_visuals.size() and str(defender_visuals[index])!="": portrait.texture=load(str(defender_visuals[index]))
		slot.add_child(portrait)
		_add_label(slot,name,Rect2(150,30,265,52),28,UXTheme.PAPER if index<defender_names.size() else UXTheme.MUTED,HORIZONTAL_ALIGNMENT_LEFT,UIFontScript.ROLE_EMPHASIS)
		_add_label(slot,"파견 중" if index<defender_names.size() else "파견 인원 없음",Rect2(150,91,265,42),22,UXTheme.MUTED,HORIZONTAL_ALIGNMENT_LEFT,UIFontScript.ROLE_BODY)
	_add_label(content_root,"전초기지에서 패배해도 본성은 계속됩니다. 결과에서 재도전하거나 다음 DAY로 진행할 수 있습니다.",Rect2(64,1024,1780,36),22,UXTheme.MUTED,HORIZONTAL_ALIGNMENT_CENTER,UIFontScript.ROLE_BODY)
	result_overlay=null
	_fit_design_canvas()
func _health_bar(parent: Control,rect: Rect2,color: Color) -> ProgressBar:
	var bar:=ProgressBar.new()
	bar.position=rect.position
	bar.size=rect.size
	bar.show_percentage=false
	bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var bg:=StyleBoxFlat.new()
	bg.bg_color=Color("#2b2331")
	var fill:=StyleBoxFlat.new()
	fill.bg_color=color
	bar.add_theme_stylebox_override("background",bg)
	bar.add_theme_stylebox_override("fill",fill)
	parent.add_child(bar)
	bar.size=rect.size
	return bar

func _reset_battle(retry_count: int) -> void:
	settlement_sent=false
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
	banner_label.text = "깃발  %d / %d" % [int(battle_state.get("banner_hp", 0)), int(battle_state.get("banner_max_hp", 0))]
	var alive: Dictionary={}
	for enemy_value in battle_state.get("enemies",[]):
		var enemy: Dictionary=enemy_value
		var id:=int(enemy.get("id",0))
		alive[id]=true
		if not enemy_markers.has(id):
			var marker:=Control.new()
			marker.name="Enemy%d"%id
			marker.size=Vector2(130,162)
			marker.mouse_filter=Control.MOUSE_FILTER_IGNORE
			enemy_layer.add_child(marker)
			var actor:=AnimatedSprite2D.new()
			actor.name="IntruderArt"
			# The encounter models generic intruders. This is their shared appearance,
			# not an explorer unit or a change to encounter statistics.
			actor.sprite_frames=preload("res://scripts/units/Unit.gd").warm_animation_frames(str(DataRegistry.enemy("explorer").get("sprite","")))
			actor.position=Vector2(65,50)
			actor.scale=Vector2.ONE*(190.0/384.0)
			actor.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			actor.play("move_down")
			marker.add_child(actor)
			var bar:=_health_bar(marker,Rect2(22,134,86,7),Color("#dc7777"))
			bar.name="IntruderHP"
			var name:=_add_label(marker,"침입자",Rect2(0,145,130,34),20,UXTheme.PAPER,HORIZONTAL_ALIGNMENT_CENTER,UIFontScript.ROLE_BODY)
			name.add_theme_constant_override("outline_size",4)
			name.add_theme_color_override("font_outline_color",Color("#09070d"))
			enemy_markers[id]=marker
		var marker: Control=enemy_markers[id]
		marker.position=Vector2(120+1540*float(enemy.get("progress",0)),530+float(id%3)*14)
		var hp:=marker.get_node("IntruderHP") as ProgressBar
		hp.max_value=float(enemy.get("max_hp",1))
		hp.value=float(enemy.get("hp",0))
	for id in enemy_markers.keys():
		if not alive.has(id):
			enemy_markers[id].queue_free()
			enemy_markers.erase(id)


func _show_result() -> void:
	if is_instance_valid(result_overlay): return
	set_process(false)
	var battle_result := EncounterServiceScript.result(battle_state)
	result_overlay = Panel.new()
	result_overlay.name = "BattleResultOverlay"
	result_overlay.position = Vector2(500, 260)
	result_overlay.size = Vector2(920, 560)
	result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	result_overlay.z_index = 100
	result_overlay.add_theme_stylebox_override("panel", _style(Color("#100b16fc"), Color("#ffd36a") if bool(battle_result.get("win", false)) else Color("#e06f74"), 4, 16))
	content_root.add_child(result_overlay)
	_add_label(result_overlay, "깃발 방어 성공" if bool(battle_result.get("win", false)) else "깃발 방어 실패", Rect2(60, 52, 800, 72), 42, Color("#fff1d0"), HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_EMPHASIS)
	_add_label(result_overlay, "전투 시간  %.1f초   ·   깃발 HP  %d / %d" % [float(battle_result.get("duration_seconds", 0.0)), int(battle_result.get("ending_hp", 0)), int(battle_result.get("max_hp", 0))], Rect2(80, 150, 760, 44), 21, Color("#d8ccd9"), HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_BODY)
	_add_label(result_overlay, "전초기지에서 패배해도 본성의 방어는 계속됩니다.", Rect2(80, 222, 760, 42), 18, Color("#bcaec1"), HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_BODY)
	if not bool(battle_result.get("win", false)):
		var retry_button := _add_button(result_overlay, "재도전", Rect2(120, 390, 300, 76), Callable(self, "_retry"), false)
		retry_button.name = "RetryButton"
		var settle_loss_button := _add_button(result_overlay, "패배 수용", Rect2(500, 390, 300, 76), Callable(self, "_settle"), false)
		settle_loss_button.name = "SettleLossButton"
	else:
		var settle_win_button := _add_button(result_overlay, "결산으로", Rect2(310, 390, 300, 76), Callable(self, "_settle"), false)
		settle_win_button.name = "SettleWinButton"


func _retry() -> void:
	if settlement_sent or not bool(battle_state.get("completed",false)): return
	_reset_battle(int(battle_state.get("retry_count", 0)) + 1)


func _settle() -> void:
	if settlement_sent or not bool(battle_state.get("completed",false)): return
	settlement_sent=true
	if is_instance_valid(result_overlay):
		for child in result_overlay.get_children():
			if child is Button: child.disabled=true
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
	UXTheme.apply_tree(content_root)


func _add_label(parent: Control, text_value: String, rect: Rect2, font_size: int, color: Color, alignment: HorizontalAlignment, role: String) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.text = text_value
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", UIFontScript.font_for_role(role))
	label.add_theme_font_size_override("font_size", UISettings.scaled_font_size(maxi(20, font_size)))
	label.add_theme_color_override("font_color", color)
	label.tooltip_text = text_value
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
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color("#fff2cf"))
	button.add_theme_stylebox_override("normal", _style(Color("#251730f4"), Color("#9b6a27"), 2, 8))
	button.add_theme_stylebox_override("hover", _style(Color("#3a2348f8"), Color("#ffd36a"), 2, 8))
	button.add_theme_stylebox_override("pressed", _style(Color("#150d1df8"), Color("#fff0b0"), 2, 8))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _style(fill: Color, border: Color, width: int, radius: int) -> StyleBox:
	return UXTheme.panel(fill, border, width, radius)
