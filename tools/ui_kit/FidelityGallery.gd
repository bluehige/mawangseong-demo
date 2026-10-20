extends Node
## Direct 1920x1080 framebuffer evidence. No source-image UI crops or composites.
const Kit = preload("res://scripts/ui/kit/UIKit.gd")
const PanelScript = preload("res://scripts/ui/kit/KitPanel.gd")
const ButtonScript = preload("res://scripts/ui/kit/KitButton.gd")
const IconButton = preload("res://scripts/ui/kit/KitIconButton.gd")
const Tabs = preload("res://scripts/ui/kit/KitTabs.gd")
const Resources = preload("res://scripts/ui/kit/KitResourceBar.gd")
const Stat = preload("res://scripts/ui/kit/KitStatBar.gd")
const Card = preload("res://scripts/ui/kit/KitCard.gd")
const Chip = preload("res://scripts/ui/kit/KitChip.gd")
const Tooltip = preload("res://scripts/ui/kit/KitTooltip.gd")
const Modal = preload("res://scripts/ui/kit/KitModal.gd")
const Toast = preload("res://scripts/ui/kit/KitToast.gd")
const Dock = preload("res://scripts/ui/kit/KitDock.gd")
var out := "res://tmp/v1213_u4/fidelity"
var ui: Control
var measured: Dictionary = {}
var performance: Array = []
var view_name := ""

func _ready() -> void:
	call_deferred("run")

func place(control: Control, rect: Rect2, id: String = "") -> Control:
	ui.add_child(control)
	control.position = rect.position
	control.size = rect.size
	if not id.is_empty(): measured[view_name + "/" + id] = {"control":control, "target":[rect.size.x,rect.size.y]}
	return control

func caption(text: String, rect: Rect2, pixels: int = 26, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Kit.label(text)
	label.add_theme_font_size_override("font_size", pixels)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	place(label, rect)
	return label

func picture(path: String, rect: Rect2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = load(path) if ResourceLoader.exists(path) else ImageTexture.create_from_image(Image.load_from_file(path))
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(image, rect)
	return image

func build_base() -> void:
	if ui != null:
		remove_child(ui)
		ui.queue_free()
	ui = Control.new()
	ui.theme = Kit.base_theme()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ui)
	var background := picture("res://docs/design/v1213_screens/dialogue_bg_throne_report.png", Rect2(0,0,1920,1080))
	background.stretch_mode = TextureRect.STRETCH_SCALE

func entries() -> Array:
	return [{"id":"build","label":"건설","icon":"build"},{"id":"guard","label":"수비대","icon":"garrison"},{"id":"tactics","label":"전술","icon":"tactics"},{"id":"monster","label":"몬스터","icon":"monster"}]

func kit_screen() -> void:
	view_name = "kit"
	build_base()
	caption("B · 귀여운 다크 판타지", Rect2(260,65,760,100), 60).add_theme_color_override("font_color",Kit.Tokens.HIGHLIGHT)
	caption("작지만, 위대한 어둠이 깃든 세계",Rect2(360,174,590,42),26)
	picture("res://assets/sprites/portraits/uiux3d/pudding_base.png",Rect2(825,85,195,145))
	var resources := Resources.new()
	resources.set_resources({"gold":"1,250","mana":80,"food":24,"infamy":12})
	place(resources,Rect2(1052,110,795,86),"resources")
	# The three-state panel and four tabs follow the reference coordinates.
	place(PanelScript.new(),Rect2(86,242,796,159),"button_panel")
	for i in range(3):
		caption(["기본","강조","비활성"][i],Rect2(123+i*252,259,216,42),24,HORIZONTAL_ALIGNMENT_CENTER)
		var button := ButtonScript.new().configure("확인",[ButtonScript.VariantStyle.BASIC,ButtonScript.VariantStyle.PRIMARY,ButtonScript.VariantStyle.DISABLED][i])
		place(button,Rect2(123+i*252,305,216,70),"button_"+str(i))
	place(PanelScript.new(),Rect2(86,429,796,103),"tab_panel")
	var tabs := Tabs.new()
	tabs.set_tabs(entries(),"build")
	place(tabs,Rect2(98,439,768,78),"tabs")
	for button in tabs._buttons.values(): button.custom_minimum_size.x = 183
	for i in range(4): measured["kit/tab_"+str(i)] = {"control":tabs.get_child(i),"target":[183,78]}
	var ids := ["settings","log","save","encyclopedia","speed","pause","build","monster"]
	var names := ["설정","로그","저장","도감","배속","일시정지","건설","몬스터"]
	for i in range(8):
		place(IconButton.new().configure_icon(ids[i],names[i]),Rect2(80+i*102,568,84,84),"icon_"+str(i))
		caption(names[i],Rect2(68+i*102,657,108,40),24,HORIZONTAL_ALIGNMENT_CENTER)
	var card := Card.new().configure("방패 슬라임",5,Kit.Icons.get_icon("portrait"),800,1000,65,100)
	card.experience.caption.text = "경험치"
	card.set_emphasis(true)
	place(card,Rect2(914,247,519,332),"card")
	var enemy := Chip.new().configure("explorer_enemy",3,-1,"탐험가")
	enemy.symbol.custom_minimum_size = Vector2(116,86)
	enemy.symbol.texture = Kit.Icons.get_icon("explorer_enemy",128)
	enemy.row.add_child(Kit.label("탐험가","number"))
	enemy.row.move_child(enemy.row.get_child(2),1)
	place(enemy,Rect2(1475,312,372,118),"enemy")
	for i in range(2):
		var panel := PanelScript.new()
		var row := HBoxContainer.new()
		panel.set_meta("kit_surface_radius",Kit.Tokens.RADIUS_COMPACT)
		row.add_child(Kit.image("throne" if i==0 else "treasury",64))
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(Kit.label("왕좌" if i==0 else "보물실","number"))
		var stat := Stat.new().configure("HP",1500 if i==0 else 800,1500 if i==0 else 1000)
		stat.caption.hide()
		info.add_child(stat)
		row.add_child(info)
		panel.content.add_child(row)
		# Compact health strip keeps its measured 95px frame.
		var empty := StyleBoxEmpty.new()
		for side in range(4): empty.set_content_margin(side,12)
		panel.add_theme_stylebox_override("panel",empty)
		place(panel,Rect2(914,614+i*107,513,95),"health_"+str(i))
	var tooltip := Tooltip.new().configure("성문 방벽","입구의 아군을 보호합니다.",{"gold":120,"mana":10},0)
	tooltip.set_illustration(load("res://assets/sprites/rooms/prop_gate_01.png"))
	place(tooltip,Rect2(167,740,612,205),"tooltip")
	var modal := Modal.new().configure("전투를 시작할까요?","배치를 마치고 방어를 시작합니다.","시작","취소")
	modal.title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal.description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal.content.add_theme_constant_override("separation",24)
	modal.cancel_button.custom_minimum_size.x = 158
	modal.confirm_button.custom_minimum_size.x = 158
	modal.confirm_button.jewel = false
	place(modal,Rect2(1465,515,401,274),"modal")
	place(Toast.new().configure("저장했습니다","닫기"),Rect2(1073,862,488,94),"toast")

func management_screen() -> void:
	view_name = "management"
	build_base()
	# Only the requested strip is reproduced; no generated map UI is used as evidence.
	var resources := Resources.new()
	resources.set_resources({"gold":"1,245","mana":320,"food":"18 / 30","infamy":620})
	place(resources,Rect2(14,3,1892,58),"resources")
	resources.custom_minimum_size.y = 58
	resources.set_meta("kit_surface_radius",22)
	for item in resources.row.get_children(): item.get_child(0).custom_minimum_size = Vector2(48,48)
	var empty := StyleBoxEmpty.new()
	empty.content_margin_left = 24; empty.content_margin_right = 24
	empty.content_margin_top = 5; empty.content_margin_bottom = 5
	resources.add_theme_stylebox_override("panel",empty)
	for i in range(3):
		var icon := Kit.image(["settings","save","encyclopedia"][i],40)
		place(icon,Rect2(1680+i*80,12,40,40))
	caption("DAY 1",Rect2(42,82,200,48),28)
	var names := ["감시 초소","병영","보물 보관실","회복 둥지"]
	var paths := ["res://assets/sprites/rooms/prop_watch_post_01.png","res://assets/sprites/rooms/prop_barracks_01.png","res://assets/sprites/rooms/prop_treasure_pile_01.png","res://assets/sprites/rooms/prop_recovery_nest_01.png"]
	var icons := ["watch_post_range","garrison","treasury","hp"]
	for i in range(4):
		var panel := PanelScript.new()
		panel.set_meta("kit_surface_radius",16)
		if i==0: panel.set_emphasis(true)
		var row := HBoxContainer.new()
		var image := Kit.image(icons[i],104)
		if ResourceLoader.exists(paths[i]): image.texture=load(paths[i])
		row.add_child(image)
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.add_theme_constant_override("separation",4)
		var title := Kit.label(names[i],"number")
		title.add_theme_font_size_override("font_size",26)
		copy.add_child(title)
		var costs := HBoxContainer.new()
		costs.add_child(Kit.image("gold",32))
		costs.add_child(Kit.label("120" if i==2 else "100","support"))
		copy.add_child(costs)
		if i!=2:
			var second := HBoxContainer.new()
			second.add_child(Kit.image("food" if i==1 else "mana",32))
			second.add_child(Kit.label("2" if i==1 else ("80" if i==3 else "50"),"support"))
			copy.add_child(second)
		row.add_child(copy)
		panel.content.add_child(row)
		var inset := StyleBoxEmpty.new()
		for side in range(4): inset.set_content_margin(side,12)
		panel.add_theme_stylebox_override("panel",inset)
		place(panel,Rect2(426+i*270,806,260,128),"card_"+str(i))
	var dock := Dock.new().configure(entries(),"build")
	var inset := StyleBoxEmpty.new()
	for side in range(4): inset.set_content_margin(side,0)
	dock.add_theme_stylebox_override("panel",inset)
	place(dock,Rect2(394,960,838,96),"dock")
	var dock_widths := [224,198,178,198]
	for i in range(4):
		var button: Button = dock.tabs.get_child(i)
		button.custom_minimum_size.x = dock_widths[i]
		measured["management/dock_button_"+str(i)] = {"control":button,"target":[dock_widths[i],96]}
	var battle := ButtonScript.new().configure("전투 시작",ButtonScript.VariantStyle.BASIC,"play")
	battle.set_meta("kit_button_height",Kit.Tokens.BATTLE_HEIGHT)
	place(battle,Rect2(1246,960,278,96),"battle")
	var undo := ButtonScript.new().configure("되돌리기",ButtonScript.VariantStyle.BASIC,"undo")
	undo.add_theme_constant_override("icon_max_width",44)
	place(undo,Rect2(32,902,205,70),"undo")

func capture(name: String) -> void:
	for i in range(12): await get_tree().process_frame
	# Autowrap minimum heights settle after their width. Reapply the measured
	# viewport fixture extent, allowing Containers to grow only for real content.
	for i in range(3):
		for key in measured:
			if key.begins_with(view_name+"/"):
				var control: Control = measured[key].control
				control.size = Vector2(measured[key].target[0],measured[key].target[1])
		for frame in range(4): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name+".png"))
	for key in measured:
		if key.begins_with(view_name+"/"):
			var c: Control = measured[key].control
			measured[key].actual = [c.size.x,c.size.y]
			measured[key].position = [c.position.x,c.position.y]
	# Short capped sample after warmup; no process loop in product components.
	var start := Time.get_ticks_usec()
	var start_drawn := Engine.get_frames_drawn()
	for i in range(120): await get_tree().process_frame
	var seconds := (Time.get_ticks_usec()-start)/1000000.0
	var drawn := Engine.get_frames_drawn()-start_drawn
	performance.append({"screen":view_name,"process_frame_resumes":120,"drawn_frames":drawn,"seconds":seconds,"fps":drawn/seconds,"engine_fps":Engine.get_frames_per_second(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"objects":Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)})

func states_screen() -> void:
	view_name = "states"
	build_base()
	caption("UI 상태",Rect2(96,64,900,80),40)
	var names := ["기본", "호버", "눌림", "초점", "비활성"]
	var states := ["normal", "hover", "pressed", "focus", "disabled"]
	for row in range(3):
		caption(["기본 버튼","강조 버튼","위험 버튼"][row],Rect2(96,200+row*220,300,50),32)
		for col in range(5):
			var button := ButtonScript.new().configure(names[col],row)
			button.disabled = col==4
			button.surface.preview_state = states[col]
			if col==3: button.add_theme_stylebox_override("normal",Kit.base_theme().get_stylebox("focus","Button"))
			place(button,Rect2(96+col*340,270+row*220,300,90))
	var selected := ButtonScript.new().configure("선택",ButtonScript.VariantStyle.PRIMARY,"monster")
	selected.selected_marker = true
	selected.set_meta("kit_selected",true)
	place(selected,Rect2(96,960,300,90))

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fidelity-out=tmp/v1213_u4/"): out="res://"+arg.trim_prefix("--fidelity-out=")
	if not ProjectSettings.globalize_path("user://").replace("\\","/").begins_with(ProjectSettings.globalize_path(out).replace("\\","/")+"/") or DisplayServer.get_name()=="headless":
		push_error("Fidelity renderer requires isolated APPDATA and graphical rendering")
		get_tree().quit(2); return
	Engine.max_fps = 60
	get_window().content_scale_size = Vector2i(1920,1080)
	get_window().size = Vector2i(1920,1080)
	LanguageSettings.set_locale("ko",false)
	kit_screen()
	await capture("kit_render")
	management_screen()
	await capture("management_render")
	states_screen()
	await capture("states_render")
	for value in measured.values(): value.erase("control")
	var file := FileAccess.open(out.path_join("render_metrics.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"dimensions":[1920,1080],"geometry":measured,"performance":performance},"\t"))
	file.close()
	print("FIDELITY_RENDER complete ",out)
	get_tree().quit()
