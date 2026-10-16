extends "res://scripts/map_builder/ApprovedMapView.gd"
## Branch management UI: generated raster controls, model-only placement edits.
const Placement = preload("res://scripts/map_builder/ApprovedPlacement.gd")
const Assembly = preload("res://scripts/map_builder/ApprovedTileAssembler.gd")
const UI_ART := "res://assets/maps/v130r_step2/ui/"
const ICONS := {"barracks":"build_barracks","recovery_nest":"build_recovery_nest","ward_core":"build_ward_core","watchtower":"build_watchtower","bait_treasure":"build_decoy_treasure","spikes":"build_spike_trap","sticky":"build_sticky_trap"}
var placement: Dictionary
var baseline: Dictionary
var terrain_data: Dictionary
var door_data: Dictionary
var build_kind := ""
var moving_id := ""
var selected_id := ""
var preview: Dictionary = {}
var hover_cell := Vector2i(-999,-999)
var preview_layer: Node2D
var sites_layer: Node2D
var radial: Control
var info: Control
var wallet: Label
var status_text: Label
var palette_buttons := {}
var pointer_down := false
var click_armed := false
var press_position := Vector2.ZERO
var grab_offset := Vector2i.ZERO
var panel_mode := ""
var last_save_error: Error = OK
var sites_generation := 0
var sites_pending := false

func setup(game: Node) -> void:
	root = game; name = "ApprovedMapManagement"
	size = Vector2(1920,1080); clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	state = Layout.read()
	terrain_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/v130r_step2/terrain.json"))
	door_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/v130r_step2/door_directions.json"))
	baseline = Placement.initial(game)
	placement = Placement.load_copy(baseline)
	if not placement.get("ok",false): placement = baseline
	world = Node2D.new(); world.name = "DynamicApprovedPieces"; add_child(world)
	render_map()
	build_chrome()
	show_default()
	# Existing menu uses drawn controls. This branch's image controls own input.
	call_deferred("hide_legacy_menu")

func hide_legacy_menu() -> void:
	var menu: Node = root.ui_layer.find_child("CommonGameMenuButton",true,false)
	if menu!=null: menu.hide()

func texture(path: String) -> Texture2D:
	if not textures.has(path): textures[path] = load(path)
	return textures[path]

func render_map() -> void:
	Assembly.populate(self,placement)
	sites_layer = Node2D.new(); sites_layer.name = "ValidPlacementCells"; world.add_child(sites_layer)
	preview_layer = Node2D.new(); preview_layer.name = "PlacementGhost"; world.add_child(preview_layer)
	root.graph.layout["approved_map_step2"] = placement

func cell_highlight(parent: Node, cell: Vector2i, tint: Color) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture(UI_ART+"cell_highlight.png")
	sprite.position = Layout.project(Vector2(cell)+Vector2(.5,.5))
	sprite.scale = Vector2(.94,.94); sprite.modulate = tint
	parent.add_child(sprite)
	return sprite

func label_at(parent: Node, text: String, point: Vector2, font_size: int = 18) -> Label:
	var label := Label.new(); label.text = text; label.position = point
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font",FONT); label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("eee9d9"))
	label.add_theme_color_override("font_shadow_color",Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x",1); label.add_theme_constant_override("shadow_offset_y",2)
	parent.add_child(label); return label

func image_button(parent: Node, icon: String, point: Vector2, width: float, callback: Callable, tooltip: String) -> TextureButton:
	var button := TextureButton.new(); button.name = icon
	button.texture_normal = texture(UI_ART+icon+".png")
	button.ignore_texture_size = true; button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.position = point; button.size = Vector2.ONE*width; button.tooltip_text = tooltip
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(func(): callback.call_deferred())
	button.mouse_entered.connect(func(): button.modulate = Color(1.18,1.18,1.1))
	button.mouse_exited.connect(func(): button.modulate = Color.WHITE)
	parent.add_child(button); return button

func panel_image(parent: Node, rect: Rect2) -> TextureRect:
	var panel := TextureRect.new()
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.texture = texture("res://assets/ui/uiux/obsidian_panel.png")
	panel.position = rect.position; panel.size = rect.size
	panel.stretch_mode = TextureRect.STRETCH_SCALE
	panel.mouse_filter = Control.MOUSE_FILTER_STOP; parent.add_child(panel); return panel

func build_chrome() -> void:
	chrome = Control.new(); chrome.name = "MapControls"; chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(chrome)
	label_at(chrome,"성 관리  ·  E 32×18",Vector2(30,22),22)
	wallet = label_at(chrome,"",Vector2(30,55),18)
	image_button(chrome,"place_auto",Vector2(1720,18),56,show_full,"전체 보기 · F")
	image_button(chrome,"frame_selected",Vector2(1790,18),56,show_default,"기본 2배 · 2 · 안전 맞춤")
	image_button(chrome,"place_clear_all",Vector2(1860,18),44,func(): get_tree().quit(),"테스트 창 닫기")
	var bar := Control.new(); bar.name = "BuildBar"; bar.mouse_filter = Control.MOUSE_FILTER_IGNORE; chrome.add_child(bar)
	var index := 0
	for kind in ICONS:
		var x: float = 592+index*106
		var button := image_button(bar,ICONS[kind],Vector2(x,966),82,func(): pass,Placement.NAMES[kind])
		button.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
				begin_build(kind)
				pointer_down = true; press_position = button.get_global_rect().get_center(); click_armed = false
				button.accept_event())
		palette_buttons[kind] = button
		var title := label_at(bar,Placement.NAMES[kind],Vector2(x-8,1044),15)
		title.size.x = 98; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var multi_cost: bool = placement.catalog[kind].cost.size()>1
		var price_text := cost_text(placement.catalog[kind].cost).replace(" · ","\n")
		var price := label_at(bar,price_text,Vector2(x-9,924 if multi_cost else 945),14)
		price.size.x = 100; price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		index += 1
	status_text = label_at(chrome,"",Vector2(30,902),18)
	scale_label = label_at(chrome,"",Vector2(30,1050),14)
	radial = Control.new(); radial.name = "BuildingRadial"; radial.mouse_filter = Control.MOUSE_FILTER_IGNORE; chrome.add_child(radial)
	info = Control.new(); info.name = "BuildingInfo"; info.mouse_filter = Control.MOUSE_FILTER_IGNORE; chrome.add_child(info)
	update_wallet()

func update_wallet() -> void:
	if wallet==null: return
	wallet.text = "금화 %d  ·  마나 %d  ·  식량 %d" % [placement.resources.gold,placement.resources.mana,placement.resources.food]
	for kind in palette_buttons:
		var rule: Dictionary = placement.catalog[kind]
		palette_buttons[kind].modulate = Color.WHITE if Placement.can_pay(placement,rule.cost) and placement.stage>=rule.stage else Color(.5,.5,.5)

func cost_text(cost: Dictionary) -> String:
	var parts: PackedStringArray = []
	for key in cost:
		parts.append(str({"gold":"금","mana":"마","food":"식"}.get(key,key))+str(cost[key]))
	return " · ".join(parts) if not parts.is_empty() else "0"

func show_default() -> void:
	# Both approved ends exceed 1920x1080 at raw .75. Fit their artwork and
	# reserve the lower icon strip; retain .75 as the requested 2x zoom target.
	set_camera(Vector2(1856,1260),.43)
	scale_label.text = "2배 · 안전 맞춤  |  휠 확대  ·  빈 바닥 드래그 이동  ·  F 전체  ·  Esc 취소"

func set_camera(center: Vector2, factor: float) -> void:
	camera_scale = clampf(factor,.4,1.5)
	camera_center = center
	var half := size/2/camera_scale
	for axis in range(2):
		var low: float = CAMERA_BOUNDS.position[axis]+half[axis]
		var high: float = CAMERA_BOUNDS.end[axis]-half[axis]
		camera_center[axis] = clampf(camera_center[axis],low,high) if low<=high else CAMERA_BOUNDS.get_center()[axis]
	world.scale = Vector2.ONE*camera_scale
	world.position = size/2-camera_center*camera_scale
	var cave: Sprite2D = world.get_node_or_null("DynamicCaveBackground")
	if cave!=null:
		var cover := maxf(1.0,.48/camera_scale)
		var extent := Vector2(4000,2250)*cover
		cave.scale = extent/cave.texture.get_size()
		var bg_center := Vector2(1856,1260)
		for axis in range(2):
			bg_center[axis] = clampf(bg_center[axis],camera_center[axis]+half[axis]-extent[axis]/2,camera_center[axis]-half[axis]+extent[axis]/2)
		cave.position = bg_center-extent/2
	if scale_label!=null: scale_label.text = "휠 확대 · 빈 바닥 드래그 이동 · F 전체 · 2 안전 맞춤 · Esc 취소"
	if is_instance_valid(radial): update_context_position()

func screen_cell(cell: Vector2) -> Vector2:
	return world.position+Layout.project(cell)*camera_scale

func zoom_at(point: Vector2, factor: float) -> void:
	var before := camera_center+(point-size/2)/camera_scale
	var next := clampf(camera_scale*factor,.4,1.5)
	set_camera(before-(point-size/2)/next,next)

func cell_at(point: Vector2) -> Vector2i:
	return Vector2i(Layout.unproject((point-world.position)/camera_scale).floor())

func begin_build(kind: String, moving: String = "") -> void:
	clear_context(); build_kind = kind; moving_id = moving; hover_cell = Vector2i(-999,-999)
	grab_offset = Vector2i.ZERO
	sites_generation += 1
	var generation := sites_generation
	status_text.text = Placement.NAMES[kind]+" · 놓을 위치 선택"
	show_sites(kind,moving,generation)

func show_sites(kind: String, moving: String, generation: int) -> void:
	for child in sites_layer.get_children(): child.free()
	sites_pending = true
	var count := 0
	for y in range(18):
		for x in range(32):
			if generation!=sites_generation or not is_inside_tree(): return
			var c := Vector2i(x,y)
			var attempt := Placement.preview(placement,kind,c,moving)
			cell_highlight(sites_layer,c,Color(.3,1,.68,.18) if attempt.get("ok",false) else Color(1,.15,.16,.035))
			count += 1
			if count%12==0: await get_tree().process_frame
	sites_pending = false

func update_preview(point: Vector2) -> void:
	var cell := cell_at(point)-grab_offset
	if cell==hover_cell: return
	hover_cell = cell
	preview = Placement.preview(placement,build_kind,cell,moving_id)
	for child in preview_layer.get_children(): child.free()
	var valid: bool = preview.get("ok",false)
	var tint := Color(.3,1,.65,.68) if valid else Color(1,.15,.16,.8)
	var side: Vector2i = placement.catalog[build_kind].size
	for y in range(side.y):
		for x in range(side.x): cell_highlight(preview_layer,cell+Vector2i(x,y),tint)
	if valid:
		for c in preview.road_cells:
			if not placement.road_cells.has(c): cell_highlight(preview_layer,c,Color(.25,.8,1,.65))
		if build_kind not in ["spikes","sticky"]:
			var id := moving_id if moving_id!="" else build_kind+"_"+str(preview.serial)
			for c in preview.influence.get(id,[]): cell_highlight(preview_layer,c,Color(.55,.45,1,.13))
			var b := Placement.building(preview,id)
			var objects: Array = []
			Assembly.building(self,preview,b,objects,preview_layer)
			for r in objects:
				var sprite := Assembly.piece(self,r.asset,r.anchor,preview_layer); sprite.modulate.a = .48
			for c in preview.doors[id].front: cell_highlight(preview_layer,c,Color(1,.8,.25,.9))
	else:
		status_text.text = Placement.NAMES[build_kind]+" · "+str(preview.get("errors",["배치 불가"])[0])
	# Keep the ghost visible even over an invalid surface.
	var asset := "traps/"+build_kind+".png" if build_kind in ["spikes","sticky"] else "interiors/"+build_kind+".png"
	if not valid or build_kind in ["spikes","sticky"]:
		var anchor := Layout.project(Vector2(cell)+Vector2(.5,.5)) if side==Vector2i.ONE else Layout.project(Vector2(cell.x,cell.y+side.y))
		var ghost := Assembly.piece(self,asset,anchor,preview_layer); ghost.modulate = Color(1,1,1,.42) if valid else Color(1,.5,.5,.42)
	if valid: status_text.text = Placement.NAMES[build_kind]+" · 배치 가능"

func commit_preview() -> void:
	if not preview.get("ok",false): return
	placement = preview; cancel_build(); render_map(); update_wallet()
	last_save_error = Placement.save_copy(placement)
	status_text.text = "저장됨" if last_save_error==OK else "테스트 저장 실패: "+str(last_save_error)

func cancel_build() -> void:
	sites_generation += 1; sites_pending = false
	build_kind = ""; moving_id = ""; preview = {}; pointer_down = false; click_armed = false
	for parent in [sites_layer,preview_layer]:
		if is_instance_valid(parent):
			for child in parent.get_children(): child.free()

func clear_context() -> void:
	selected_id = ""; panel_mode = ""
	for parent in [radial,info]:
		if is_instance_valid(parent):
			for child in parent.get_children(): child.free()
	if is_instance_valid(preview_layer):
		for child in preview_layer.get_children(): child.free()

func select_building(id: String) -> void:
	clear_context(); selected_id = id
	var b := Placement.building(placement,id)
	if b.is_empty(): return
	var names := ["menu_info","menu_upgrade","menu_move","menu_dismantle_refund","menu_assign_defenders"]
	for i in range(names.size()):
		var angle := -PI/2+i*TAU/5
		var pos := Vector2(cos(angle)*116,sin(angle)*76)-Vector2.ONE*32
		var icon: String = names[i]
		var callback := context_action.bind(icon)
		var button := image_button(radial,icon,pos,64,callback,["정보","강화","이동","해체·환불","수비 지점"][i])
		if b.fixed and i in [1,2,3]: button.disabled = true; button.modulate = Color(.4,.4,.4)
	update_context_position()

func context_action(icon: String) -> void:
	var b := Placement.building(placement,selected_id)
	if b.is_empty(): return
	if icon=="menu_move":
		var id := selected_id; begin_build(b.kind,id); return
	if icon=="menu_assign_defenders":
		for child in preview_layer.get_children(): child.free()
		for c in placement.defense_points[b.id]: cell_highlight(preview_layer,c,Color(1,.8,.25,.85))
		status_text.text = "수비 지점 %d · 몬스터 배치는 다음 단계" % b.capacity
		return
	show_info(icon)

func show_info(mode: String) -> void:
	panel_mode = mode
	for child in info.get_children(): child.free()
	var b := Placement.building(placement,selected_id)
	panel_image(info,Rect2(0,0,292,184))
	label_at(info,Placement.NAMES[b.kind]+"  ·  Lv"+str(b.level),Vector2(18,14),20)
	label_at(info,"수비 %d  ·  범위 %.1f칸" % [b.capacity,b.aura],Vector2(18,49),17)
	if mode=="menu_dismantle_refund":
		label_at(info,"환불 "+cost_text(Placement.refund(b,placement)),Vector2(18,81),17)
		image_button(info,"menu_dismantle_refund",Vector2(214,106),58,confirm_dismantle,"해체 확인")
	elif mode=="menu_upgrade":
		label_at(info,"Lv%d → %d  ·  %s" % [b.level,b.level+1,cost_text(Placement.upgrade_cost(placement,b))],Vector2(18,81),17)
		image_button(info,"menu_upgrade",Vector2(214,106),58,confirm_upgrade,"강화 확인")
	else:
		label_at(info,"문 "+placement.doors[b.id].side+"  ·  %d×%d" % [b.rect.size.x,b.rect.size.y],Vector2(18,81),17)
		for c in placement.influence.get(b.id,[]): cell_highlight(preview_layer,c,Color(.6,.45,1,.12))
	image_button(info,"place_clear_all",Vector2(18,118),42,func():
		for child in info.get_children(): child.free()
		panel_mode = "", "닫기")
	update_context_position()

func update_context_position() -> void:
	if selected_id=="": return
	var b := Placement.building(placement,selected_id)
	if b.is_empty(): return
	var center := screen_cell(Vector2(b.rect.position)+Vector2(b.rect.size)/2)
	radial.position = Vector2(clampf(center.x,154,1766),clampf(center.y,145,840))
	# Follow the building; switch to its other side only to remain onscreen.
	var px := center.x-440 if center.x>960 else center.x+150
	info.position = Vector2(clampf(px,12,1616),clampf(center.y-175,90,748))

func confirm_dismantle() -> void:
	apply_action(Placement.dismantle(placement,selected_id))

func confirm_upgrade() -> void:
	var id := selected_id
	if apply_action(Placement.upgrade(placement,id)): select_building(id); show_info("menu_info")

func apply_action(next: Dictionary) -> bool:
	if not next.get("ok",false): status_text.text = " · ".join(next.get("errors",[])); return false
	placement = next; clear_context(); cancel_build(); render_map(); update_wallet()
	last_save_error = Placement.save_copy(placement)
	status_text.text = "저장됨" if last_save_error==OK else "테스트 저장 실패"
	return true

func _input(event: InputEvent) -> void:
	if build_kind=="": return
	if event is InputEventMouseMotion:
		update_preview(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_RIGHT and event.pressed:
			cancel_build(); get_viewport().set_input_as_handled(); return
		if event.button_index!=MOUSE_BUTTON_LEFT: return
		if event.pressed and (event.position.y>=935 or (event.position.x>1700 and event.position.y<85)): return
		if event.pressed and event.position.y<935:
			pointer_down = true; click_armed = true; press_position = event.position; update_preview(event.position)
		elif not event.pressed:
			if event.position.y<935 and (click_armed or event.position.distance_to(press_position)>8):
				update_preview(event.position); commit_preview()
			pointer_down = false; click_armed = false
		get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if build_kind!="": return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			var c := cell_at(event.position)
			for b in placement.buildings:
				if b.rect.has_point(c): select_building(b.id); accept_event(); return
			clear_context()
		super._gui_input(event)
	elif event is InputEventMouseMotion:
		super._gui_input(event)
	else: super._gui_input(event)

func handle_key(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed:
		if event.keycode==KEY_ESCAPE: cancel_build(); clear_context(); return true
	return super.handle_key(event)
