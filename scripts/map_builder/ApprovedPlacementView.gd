extends "res://scripts/map_builder/ApprovedMapView.gd"
## Branch management UI: generated raster controls, model-only placement edits.
const Grade = preload("res://scripts/map_builder/ApprovedGradeProgression.gd")
const Placement = preload("res://scripts/map_builder/ApprovedPlacement.gd")
const Assembly = preload("res://scripts/map_builder/ApprovedTileAssembler.gd")
const ScreenLayout = preload("res://scripts/map_builder/ApprovedPlacementLayout.gd")
const Monsters = preload("res://scripts/map_builder/ApprovedMonsterPlacement.gd")
const MonsterUI = preload("res://scripts/map_builder/ApprovedMonsterPlacementUI.gd")
const KIT := "res://assets/ui/kit/icons/icon_"
var MINIMAP_BOUNDS := Rect2(-144,135,4000,2319)
const UI_ART := "res://assets/maps/v130r_step2/ui/"
const TITLE_FONT = preload("res://assets/fonts/NEXON_Maplestory_Bold.otf")
const BODY_FONT = preload("res://assets/fonts/NEXON_Maplestory_Light.otf")
const START_CENTER := Vector2(1930,1390)
const START_ZOOM := .75
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
var wallet: Control
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
var ui_unit := 1.0
var ui_rects := {}
var costs := {}
var mini_viewport: SubViewport
var mini_picture: TextureRect
var mini_outline: NinePatchRect
var mini_clip: Control
var start_solution := {}
var context_rects: Array[Rect2] = []
var resource_rows: Array[Control] = []
var selection_layer: Node2D
var radial_backdrop: Polygon2D
var context_layout := {}
var context_tween: Tween
var monster_ui: Node
var battle
var battle_ui: Node
var finish_pending := false

func setup(game: Node) -> void:
	root = game; name = "ApprovedMapManagement"
	size = game.get_viewport().get_visible_rect().size; clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	state = Layout.read()
	terrain_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/v130r_step2/terrain.json"))
	door_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/v130r_step2/door_directions.json"))
	baseline = Placement.initial(game,"F" if Grade.enabled() else "E")
	placement = baseline if Grade.enabled() else Placement.load_copy(baseline)
	if not placement.get("ok",false): placement = baseline
	monster_ui = MonsterUI.new(); monster_ui.view = self; add_child(monster_ui)
	monster_ui.members = Monsters.roster()
	var copy := Grade.load_session(game) if Grade.enabled() else Monsters.load_copy(placement,monster_ui.members)
	placement = copy.layout; monster_ui.assignments = copy.defenders
	for species in placement.get("specializations",{}):
		if not root.monster_roster.has(species): root.monster_roster[species] = {"level":1,"exp":0}
		root.monster_roster[species]["specialization_id"] = placement.specializations[species]
	state = Layout.read(str(placement.get("grade","E")))
	monster_ui.food_income = 15 if placement.get("grade","E")=="F" else 23
	if food_enabled():
		placement.food_state = GameState.Food.migrate(placement.get("food_state",{}),int(placement.day))
		GameState.food_state = placement.food_state.duplicate(true)
		GameState.food_income = GameState.Food.income(int(placement.day))
		monster_ui.food_income = GameState.food_income
		monster_ui.joined = placement.food_state.owned.duplicate()
		# Restore the same two contracts; restarting cannot grant a new pair.
		if not placement.food_state.contracts.is_empty(): root.selected_contract_ids.assign(placement.food_state.contracts)
		elif root.selected_contract_ids.is_empty():
			for id in monster_ui.joined:
				if not monster_ui.members.has(id): continue
				var species: String = monster_ui.members[id].species_id
				if DataRegistry.update2_contracts.has(species) and root.selected_contract_ids.size()<2: root.selected_contract_ids.append(species)
		if not monster_ui.unlock_all:
			var owned: Array = monster_ui.unlocked()
			for id in monster_ui.assignments.keys():
				if id not in owned: monster_ui.assignments.erase(id)
	world = Node2D.new(); world.name = "DynamicApprovedPieces"; add_child(world)
	var story_owned: Array = ["slime","goblin","imp","kobold_scout"]
	for id in monster_ui.joined:
		if monster_ui.members.has(id): story_owned.append(monster_ui.members[id].species_id)
	root.set_meta("v130r_owned_species",story_owned)
	render_map()
	build_chrome()
	show_default()
	game.get_viewport().size_changed.connect(resize_workspace)
	# Existing menu uses drawn controls. This branch's image controls own input.
	call_deferred("hide_legacy_menu")
	if food_enabled(): call_deferred("check_recruits")

func hide_legacy_menu() -> void:
	var menu: Node = root.ui_layer.find_child("CommonGameMenuButton",true,false)
	if menu!=null: menu.hide()

func texture(path: String) -> Texture2D:
	if not textures.has(path): textures[path] = load(path)
	return textures[path]

func render_map() -> void:
	if placement.get("grade","") in ["D","C"]:
		terrain_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/v130r_step10/terrain_"+str(placement.grade).to_lower()+".json"))
		var extent := Placement.dimensions(placement)
		var a := project(Vector2(0,0)); var b := project(Vector2(extent))
		MINIMAP_BOUNDS = Rect2(Vector2(a.x-220,project(Vector2(extent.x,0)).y-260),Vector2(b.x-a.x+440,(extent.x+extent.y)*32+600))
	else:
		terrain_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/v130r_step2/terrain.json"))
		MINIMAP_BOUNDS = Rect2(-144,135,4000,2319)
	Assembly.populate(self,placement)
	if placement.get("grade","") in ["D","C"]:
		var first := true
		for child in world.get_children():
			if not child is Sprite2D or child.name=="DynamicCaveBackground": continue
			var r: Rect2 = child.transform*child.get_rect()
			MINIMAP_BOUNDS = r if first else MINIMAP_BOUNDS.merge(r); first = false
		MINIMAP_BOUNDS = MINIMAP_BOUNDS.grow(45)
	sites_layer = Node2D.new(); sites_layer.name = "ValidPlacementCells"; world.add_child(sites_layer)
	preview_layer = Node2D.new(); preview_layer.name = "PlacementGhost"; world.add_child(preview_layer)
	selection_layer = Node2D.new(); selection_layer.name = "SelectedBuildingOutline"; world.add_child(selection_layer)
	root.graph.layout["approved_map_step2"] = placement
	if is_instance_valid(monster_ui): monster_ui.render_units(); monster_ui.refresh_cards()
	if is_instance_valid(mini_viewport): call_deferred("rebuild_minimap")

func cell_highlight(parent: Node, cell: Vector2i, tint: Color) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture(UI_ART+"cell_highlight.png")
	sprite.position = project(Vector2(cell)+Vector2(.5,.5))
	sprite.scale = Vector2(.94,.94); sprite.modulate = tint
	parent.add_child(sprite)
	return sprite

func label_at(parent: Node, text: String, point: Vector2, font_size: int = 18, heading: bool = false) -> Label:
	var label := Label.new(); label.text = text; label.position = point
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font",TITLE_FONT if heading else BODY_FONT); label.add_theme_font_size_override("font_size",font_size)
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
	button.mouse_entered.connect(func():
		if not button.disabled: button.modulate = Color(1.18,1.18,1.1))
	button.mouse_exited.connect(func():
		if not button.disabled: button.modulate = Color.WHITE)
	parent.add_child(button); return button

func panel_image(parent: Node, rect: Rect2) -> TextureRect:
	var panel := TextureRect.new()
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.texture = texture("res://assets/ui/uiux/obsidian_panel.png")
	panel.position = rect.position; panel.size = rect.size
	panel.stretch_mode = TextureRect.STRETCH_SCALE
	panel.mouse_filter = Control.MOUSE_FILTER_STOP; parent.add_child(panel); return panel

func art_at(parent: Node, path: String, rect: Rect2) -> TextureRect:
	var image := TextureRect.new(); image.texture = texture(path)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.position = rect.position; image.size = rect.size
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(image)
	return image

func resource_line(parent: Node, values: Dictionary, point: Vector2, step: float, affordable: bool = true) -> Control:
	var row := Control.new(); row.position = point; row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(row); row.set_meta("values",values.duplicate()); row.set_meta("affordable",affordable)
	var i := 0
	for key in ["gold","mana","food"]:
		if not values.has(key): continue
		var icon := art_at(row,KIT+key+"_64.png",Rect2(i*step,0,24,24)); icon.name = key+"Icon"
		var number := label_at(row,str(values[key]),Vector2(i*step+25,1),16); number.name = key+"Number"
		i += 1
	resource_rows.append(row)
	return row

func resize_workspace() -> void:
	if not is_inside_tree(): return
	size = get_viewport_rect().size
	clear_context()
	chrome.free(); palette_buttons.clear(); costs.clear(); resource_rows.clear()
	mini_viewport = null; mini_picture = null
	build_chrome(); show_default()

func build_chrome() -> void:
	ui_unit = ScreenLayout.unit(size); ui_rects = ScreenLayout.panels(size)
	chrome = Control.new(); chrome.name = "MapControls"; chrome.scale = Vector2.ONE*ui_unit
	chrome.z_as_relative = false; chrome.z_index = 4090
	chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(chrome)
	radial_backdrop = Polygon2D.new(); radial_backdrop.name = "RadialObsidianDisc"
	radial_backdrop.texture = texture("res://assets/ui/uiux/obsidian_panel.png")
	radial_backdrop.modulate = Color(.32,.34,.42,.46); radial_backdrop.hide(); chrome.add_child(radial_backdrop)
	var tooltip_theme := Theme.new()
	var tooltip_panel := StyleBoxTexture.new(); tooltip_panel.texture = texture("res://assets/ui/uiux/obsidian_panel.png")
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		tooltip_panel.set_texture_margin(side,40); tooltip_panel.set_content_margin(side,12)
	tooltip_theme.set_stylebox("panel","TooltipPanel",tooltip_panel)
	tooltip_theme.default_font = BODY_FONT
	tooltip_theme.set_font("font","TooltipLabel",BODY_FONT); tooltip_theme.set_font_size("font_size","TooltipLabel",16)
	chrome.theme = tooltip_theme
	var hud := panel_image(chrome,local_ui("hud"))
	var day_label := label_at(hud,"DAY %d  ·  %s등급" % [placement.day,placement.get("grade","E")],Vector2(18,21),18)
	day_label.name = "GradeDayLabel"
	wallet = resource_line(hud,placement.resources,Vector2(175,21),98,false)
	var tabs := Control.new(); tabs.position = local_ui("tabs").position; chrome.add_child(tabs)
	for i in range(3):
		var tab := art_at(tabs,"res://assets/ui/uiux/obsidian_button.png",Rect2(i*190,0,184,74))
		tab.stretch_mode = TextureRect.STRETCH_SCALE
		tab.name = ["BuildTab","PlaceTab","CombatTab"][i]
		tab.modulate = Color(1.25,1.12,.75) if i==0 else Color(.5,.5,.58)
		var preparation := preparation_only()
		var icon: String = ["build","monster","check" if preparation else "battle_start"][i]
		var tab_icon := art_at(tabs,KIT+icon+"_64.png",Rect2(i*190+17,17,36,36))
		var title := label_at(tabs,["건설","몬스터 배치","준비 확정" if preparation else "전투"][i],Vector2(i*190+57,24),18,true)
		if i==2:
			tab.name = "ApprovedDayAction"
			tab_icon.modulate = Color(.45,.45,.5); title.modulate = Color(.5,.5,.56)
			tab_icon.modulate = Color.WHITE; title.modulate = Color.WHITE
			tab.tooltip_text = "전투 없이 다음 날로 넘어갑니다" if preparation else "현재 배치로 DAY %d 전투 시작" % int(placement.day)
			tab.mouse_filter = Control.MOUSE_FILTER_STOP
			tab.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			tab.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
					if preparation_only(): confirm_preparation_day.call_deferred()
					else: start_battle.call_deferred()
					tab.accept_event())
		else:
			tab.mouse_filter = Control.MOUSE_FILTER_STOP
			tab.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			var mode := "build" if i==0 else "place"
			tab.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
						if battle==null: monster_ui.set_mode(mode)
						tab.accept_event())
	var tools := panel_image(chrome,local_ui("tools"))
	image_button(tools,"place_auto",Vector2(8,5),56,show_full,"전체 보기 · F")
	image_button(tools,"frame_selected",Vector2(72,5),56,show_default,"시작 화면 · 2")
	image_button(tools,"place_clear_all",Vector2(140,11),44,func(): get_tree().quit(),"테스트 창 닫기")
	var bar := panel_image(chrome,local_ui("build")); bar.name = "BuildBar"
	var index := 0
	for kind in ICONS:
		var x: float = 20+index*120
		var button := image_button(bar,ICONS[kind],Vector2(x+11,60),82,func(): pass,Placement.NAMES[kind])
		button.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
				begin_build(kind)
				pointer_down = true; press_position = button.get_global_rect().get_center(); click_armed = false
				button.accept_event())
		palette_buttons[kind] = button
		var title := label_at(bar,Placement.NAMES[kind],Vector2(x-2,139),15,true)
		title.size.x = 112; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var price: Dictionary = placement.catalog[kind].cost
		costs[kind] = resource_line(bar,price,Vector2(x+(110-price.size()*56)/2,37),56)
		index += 1
	status_text = label_at(bar,"",Vector2(22,10),16)
	status_text.size.x = 832; status_text.clip_text = true
	scale_label = label_at(chrome,"",Vector2(28,size.y/ui_unit-32),14)
	scale_label.hide()
	radial = Control.new(); radial.name = "BuildingRadial"; radial.mouse_filter = Control.MOUSE_FILTER_IGNORE; chrome.add_child(radial)
	info = Control.new(); info.name = "BuildingInfo"; info.mouse_filter = Control.MOUSE_FILTER_IGNORE; chrome.add_child(info)
	build_minimap()
	monster_ui.build_controls(hud,tabs,bar)
	update_wallet()

func local_ui(key: String) -> Rect2:
	var r: Rect2 = ui_rects[key]
	return Rect2(r.position/ui_unit,r.size/ui_unit)

func update_wallet() -> void:
	if wallet==null: return
	for key in placement.resources:
		var number := wallet.get_node_or_null(key+"Number")
		if number!=null: number.text = str(placement.resources[key])
	for row in resource_rows:
		if not is_instance_valid(row) or not row.get_meta("affordable",false): continue
		var values: Dictionary = row.get_meta("values")
		for key in values:
			var enough: bool = placement.resources.get(key,0)>=values[key]
			row.get_node(key+"Number").modulate = Color.WHITE if enough else Color(1,.27,.25)
			row.get_node(key+"Icon").modulate = Color.WHITE if enough else Color(.32,.32,.38)
	for kind in palette_buttons:
		var rule: Dictionary = placement.catalog[kind]
		palette_buttons[kind].modulate = Color.WHITE if Placement.can_pay(placement,rule.cost) and placement.stage>=rule.stage else Color(.5,.5,.5)
	if is_instance_valid(monster_ui): monster_ui.update_food()

func cost_text(cost: Dictionary) -> String:
	var parts: PackedStringArray = []
	for key in cost:
		parts.append(str({"gold":"금","mana":"마","food":"식"}.get(key,key))+str(cost[key]))
	return " · ".join(parts) if not parts.is_empty() else "0"

func build_minimap() -> void:
	var panel := panel_image(chrome,local_ui("minimap")); panel.name = "Minimap"
	label_at(panel,"미니맵",Vector2(18,10),16,true)
	mini_clip = Control.new(); mini_clip.position = Vector2(16,40); mini_clip.size = Vector2(248,164)
	mini_clip.clip_contents = true; panel.add_child(mini_clip)
	mini_viewport = SubViewport.new(); mini_viewport.name = "AssembledMapOverview"
	mini_viewport.size = Vector2i(1000,580); mini_viewport.world_2d = World2D.new()
	mini_viewport.disable_3d = true; mini_viewport.gui_disable_input = true
	mini_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE; panel.add_child(mini_viewport)
	mini_picture = TextureRect.new(); mini_picture.position = Vector2(0,10); mini_picture.size = Vector2(248,143.778)
	mini_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; mini_picture.texture = mini_viewport.get_texture()
	mini_picture.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mini_picture.gui_input.connect(minimap_input); mini_clip.add_child(mini_picture)
	mini_outline = NinePatchRect.new()
	# Scale the existing GPT frame before nine-slice assembly, so its painted
	# brass rim remains within each 8px slice even at the smallest viewport box.
	var frame := texture("res://assets/ui/uiux/obsidian_panel.png").get_image()
	frame.resize(256,256,Image.INTERPOLATE_LANCZOS)
	mini_outline.texture = ImageTexture.create_from_image(frame)
	mini_outline.draw_center = false
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: mini_outline.set_patch_margin(side,8)
	mini_outline.modulate = Color(2.5,2.4,1.7); mini_outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mini_picture.add_child(mini_outline)
	rebuild_minimap()

func rebuild_minimap() -> void:
	if not is_instance_valid(mini_viewport): return
	for child in mini_viewport.get_children(): child.free()
	var miniature := world.duplicate() as Node2D
	for layer in ["ValidPlacementCells","PlacementGhost","SelectedBuildingOutline"]:
		var child := miniature.get_node_or_null(layer)
		if child!=null: child.free()
	var ratio := Vector2(mini_viewport.size)/MINIMAP_BOUNDS.size
	miniature.scale = ratio; miniature.position = -MINIMAP_BOUNDS.position*ratio
	# The overview owns a fixed, full-size background, independent of panning.
	var cave: Sprite2D = miniature.get_node_or_null("DynamicCaveBackground")
	if cave!=null:
		cave.position = MINIMAP_BOUNDS.position; cave.scale = MINIMAP_BOUNDS.size/cave.texture.get_size()
	mini_viewport.add_child(miniature)
	mini_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	update_minimap_outline()

func update_minimap_outline() -> void:
	if not is_instance_valid(mini_picture): return
	var visible := Rect2(camera_center-size/2/camera_scale,size/camera_scale)
	var clipped := visible.intersection(MINIMAP_BOUNDS)
	mini_outline.position = (clipped.position-MINIMAP_BOUNDS.position)/MINIMAP_BOUNDS.size*mini_picture.size
	mini_outline.size = clipped.size/MINIMAP_BOUNDS.size*mini_picture.size

func minimap_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		clear_context(); cancel_build()
		set_camera(MINIMAP_BOUNDS.position+event.position/mini_picture.size*MINIMAP_BOUNDS.size,camera_scale)
		mini_picture.accept_event()

func show_default() -> void:
	# Match Step2B gui(): set_camera(Vector2(1930,1390),.75) before radial_edge.
	# Scale with the shorter viewport ratio; wider aspects reveal extra cells.
	var center := START_CENTER
	if placement.get("grade","E") in ["F","D","C"]: center = project(Vector2(Placement.dimensions(placement))/2)
	start_solution = {"center":center,"zoom":START_ZOOM*ScreenLayout.unit(size)}
	set_camera(start_solution.center,start_solution.zoom)

func start_targets() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for asset in ["interiors/throne.png","interiors/entrance.png"]:
		var sprite: Sprite2D = world.get_node(asset.replace("/","_").trim_suffix(".png"))
		var used := sprite.texture.get_image().get_used_rect()
		result.append(Rect2(sprite.position+Vector2(used.position),Vector2(used.size)))
	return result

func show_full() -> void:
	if placement.get("grade","") in ["D","C"]:
		var bounds := MINIMAP_BOUNDS
		var safe := Rect2(Vector2(24,100)*ui_unit,size-Vector2(48,300)*ui_unit)
		var zoom := minf(safe.size.x/bounds.size.x,safe.size.y/bounds.size.y)
		set_camera(bounds.get_center()+(size/2-safe.get_center())/zoom,zoom)
		return
	var center := MINIMAP_BOUNDS.get_center()
	if placement.get("grade","E")=="F": center += Vector2(120,-90)
	set_camera(center,minf(size.x/MINIMAP_BOUNDS.size.x,size.y/MINIMAP_BOUNDS.size.y))

func set_camera(center: Vector2, factor: float) -> void:
	camera_scale = clampf(factor,.05*ui_unit,1.5*ui_unit)
	camera_center = center
	var half := size/2/camera_scale
	var bounds := MINIMAP_BOUNDS if placement.get("grade","") in ["D","C"] else CAMERA_BOUNDS
	camera_center = camera_center.clamp(bounds.position,bounds.end)
	world.scale = Vector2.ONE*camera_scale
	world.position = size/2-camera_center*camera_scale
	var cave: Sprite2D = world.get_node_or_null("DynamicCaveBackground")
	if cave!=null:
		var extent := Vector2(4000,2250).max(size/camera_scale)*1.02
		cave.scale = extent/cave.texture.get_size()
		var bg_center := Vector2(1856,1260)
		for axis in range(2):
			bg_center[axis] = clampf(bg_center[axis],camera_center[axis]+half[axis]-extent[axis]/2,camera_center[axis]-half[axis]+extent[axis]/2)
		cave.position = bg_center-extent/2
	if scale_label!=null: scale_label.text = "휠 확대 · 드래그 이동 · F 전체 · 2 시작 · Esc 취소"
	if is_instance_valid(radial): update_context_position()
	update_minimap_outline()

func screen_cell(cell: Vector2) -> Vector2:
	return world.position+project(cell)*camera_scale

func zoom_at(point: Vector2, factor: float) -> void:
	var before := camera_center+(point-size/2)/camera_scale
	var next := clampf(camera_scale*factor,.05*ui_unit,1.5*ui_unit)
	set_camera(before-(point-size/2)/next,next)

func cell_at(point: Vector2) -> Vector2i:
	return Vector2i(Layout.unproject((point-world.position)/camera_scale,Placement.dimensions(placement).x).floor())

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
	for y in range(Placement.dimensions(placement).y):
		for x in range(Placement.dimensions(placement).x):
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
		var anchor := project(Vector2(cell)+Vector2(.5,.5)) if side==Vector2i.ONE else project(Vector2(cell.x,cell.y+side.y))
		var ghost := Assembly.piece(self,asset,anchor,preview_layer); ghost.modulate = Color(1,1,1,.42) if valid else Color(1,.5,.5,.42)
	if valid: status_text.text = Placement.NAMES[build_kind]+" · 배치 가능"

func commit_preview() -> void:
	if not preview.get("ok",false): return
	placement = preview; cancel_build(); render_map(); update_wallet()
	last_save_error = monster_ui.persist()
	status_text.text = "저장됨" if last_save_error==OK else "테스트 저장 실패: "+str(last_save_error)

func cancel_build() -> void:
	sites_generation += 1; sites_pending = false
	build_kind = ""; moving_id = ""; preview = {}; pointer_down = false; click_armed = false
	if is_instance_valid(status_text): status_text.text = ""
	for parent in [sites_layer,preview_layer]:
		if is_instance_valid(parent):
			for child in parent.get_children(): child.free()

func clear_context() -> void:
	if context_tween!=null: context_tween.kill(); context_tween = null
	selected_id = ""; panel_mode = ""
	context_rects.clear(); context_layout.clear()
	if is_instance_valid(radial_backdrop): radial_backdrop.hide()
	if is_instance_valid(selection_layer):
		for child in selection_layer.get_children(): child.free()
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
		var icon: String = names[i]
		var callback := context_action.bind(icon)
		var button := image_button(radial,icon,Vector2.ZERO,64,callback,["정보","강화","이동","해체·환불","수비 지점"][i])
		var title := label_at(button,["정보","강화","이동","해체","수비"][i],Vector2(-8,63),14,true)
		title.size.x = 80; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.set_meta("action_index",i)
		if b.fixed and i in [1,2,3]: button.disabled = true; button.modulate = Color(.4,.4,.4)
	show_selection(b)
	fit_context()

func show_selection(b: Dictionary) -> void:
	for child in selection_layer.get_children(): child.free()
	var r: Rect2i = b.rect
	for y in range(r.position.y,r.end.y):
		for x in range(r.position.x,r.end.x):
			if x in [r.position.x,r.end.x-1] or y in [r.position.y,r.end.y-1]:
				cell_highlight(selection_layer,Vector2i(x,y),Color(1.5,1.2,.48,.95))

func context_action(icon: String) -> void:
	var b := Placement.building(placement,selected_id)
	if b.is_empty(): return
	if icon=="menu_move":
		var id := selected_id; begin_build(b.kind,id); return
	if icon=="menu_assign_defenders":
		monster_ui.set_mode("place")
		return
	show_info(icon)

func show_info(mode: String) -> void:
	panel_mode = mode
	for child in info.get_children(): child.free()
	var b := Placement.building(placement,selected_id)
	panel_image(info,Rect2(0,0,360,268))
	var next := Placement.upgrade(placement,b.id) if mode=="menu_upgrade" else {}
	var after := Placement.building(next,b.id) if next.get("ok",false) else {}
	var level := "Lv%d → Lv%d" % [b.level,after.level] if not after.is_empty() else "Lv%d" % b.level
	var title := label_at(info,Placement.NAMES[b.kind]+"  "+level,Vector2(22,18),20,true)
	while title.get_minimum_size().x>270 and title.get_theme_font_size("font_size")>12:
		title.add_theme_font_size_override("font_size",title.get_theme_font_size("font_size")-1)
	var capacity := "%d → %d명" % [b.capacity,after.capacity] if not after.is_empty() and after.capacity!=b.capacity else "%d명" % b.capacity
	label_at(info,"수비 정원  "+capacity,Vector2(22,58),18)
	var effect := effect_lines(b)
	label_at(info,effect[0],Vector2(22,91),16)
	label_at(info,effect[1],Vector2(22,119),16)
	if mode=="menu_dismantle_refund":
		label_at(info,"해체 환불",Vector2(22,159),16)
		resource_line(info,Placement.refund(b,placement),Vector2(22,190),88,false)
		image_button(info,"menu_dismantle_refund",Vector2(280,183),58,confirm_dismantle,"해체 확인")
	elif mode=="menu_upgrade":
		label_at(info,"강화 비용" if not after.is_empty() else " · ".join(next.get("errors",["강화 제한"])),Vector2(22,159),16)
		resource_line(info,Placement.upgrade_cost(placement,b),Vector2(22,190),88)
		var confirm := image_button(info,"menu_upgrade",Vector2(280,183),58,confirm_upgrade,"강화 확인")
		confirm.disabled = after.is_empty()
		if confirm.disabled: confirm.modulate = Color(.4,.4,.4)
	else:
		for c in placement.influence.get(b.id,[]): cell_highlight(preview_layer,c,Color(.6,.45,1,.12))
	var close := image_button(info,"place_clear_all",Vector2(304,18),30,func():
		for child in info.get_children(): child.free()
		panel_mode = ""; fit_context(), "닫기")
	close.name = "CloseInfo"
	label_at(info,"닫기",Vector2(304,51),12)
	if mode in ["menu_upgrade","menu_dismantle_refund"]:
		label_at(info,"강화 확인" if mode=="menu_upgrade" else "해체 확인",Vector2(276,242),12)
	update_wallet()
	fit_context()

func effect_lines(b: Dictionary) -> Array[String]:
	# Explain the existing facility role, while keeping visual influence distinct
	# from the later combat connection. This preview does not apply combat buffs.
	var scope := "영향 범위  반경 %s칸" % str(b.aura) if b.aura>0 else "영향 범위  시설 내부"
	var effect: String = {"barracks":"주둔 아군 공격·방어 지원","recovery_nest":"주둔·인접 아군 체력 회복",
		"ward_core":"모든 아군 받는 피해 감소","watchtower":"범위 내 적 둔화·아군 피해 증가",
		"bait_treasure":"도둑을 유인하는 방어 거점","throne":"마왕을 지키는 최종 방어선",
		"entrance":"침입자가 들어오는 성문","vault":"금화를 지키는 방어 거점"}.get(b.kind,"")
	if b.kind=="ward_core": scope = "영향 범위  성 전체"
	return [scope,effect]

func building_screen_rect(b: Dictionary) -> Rect2:
	var r: Rect2i = b.rect
	var points := [Vector2(r.position),Vector2(r.end),Vector2(r.position.x,r.end.y),Vector2(r.end.x,r.position.y)]
	var bounds := Rect2(screen_cell(points[0])/ui_unit,Vector2.ZERO)
	for point in points: bounds = bounds.expand(screen_cell(point)/ui_unit)
	# Full walls rise 100 world pixels above the footprint. Include the interior
	# alpha rectangle as well (chair, steps, entrance arch, props).
	bounds.position.y -= 100*camera_scale/ui_unit; bounds.size.y += 100*camera_scale/ui_unit
	var asset := "interiors/"+str(b.kind)+".png"
	var details: Dictionary = state.assets[asset]
	var anchor := project(Vector2(.25,9)) if b.kind=="entrance" else project(Vector2(r.position.x,r.end.y))
	var pivot := Vector2(details.pivot[0],details.pivot[1])
	var used := texture(Layout.ART+asset).get_image().get_used_rect()
	bounds = bounds.merge(Rect2((world.position+(anchor-pivot+Vector2(used.position))*camera_scale)/ui_unit,Vector2(used.size)*camera_scale/ui_unit))
	return bounds.grow(8)

func facility_screen_rect() -> Rect2:
	# Use the actual facility silhouette, not its surrounding room floor/walls.
	var b := Placement.building(placement,selected_id)
	var r: Rect2i = b.rect
	var asset := "interiors/"+str(b.kind)+".png"
	var details: Dictionary = state.assets[asset]
	var anchor := project(Vector2(.25,9)) if b.kind=="entrance" else project(Vector2(r.position.x,r.end.y))
	var pivot := Vector2(details.pivot[0],details.pivot[1])
	var used := texture(Layout.ART+asset).get_image().get_used_rect()
	return Rect2((world.position+(anchor-pivot+Vector2(used.position))*camera_scale)/ui_unit,Vector2(used.size)*camera_scale/ui_unit)

func context_center() -> Vector2:
	return facility_screen_rect().get_center()

func context_radius() -> float:
	var bounds := facility_screen_rect()
	var exterior := maxf(bounds.size.x,bounds.size.y)/2
	# Eight pixels of breathing room; only the five labels impose a minimum.
	return maxf(exterior+8,100/(2*sin(PI/5)))

func solve_context(center: Vector2, radius: float) -> Dictionary:
	var blocked: Array[Rect2] = []
	for key in ui_rects: blocked.append(local_ui(key).grow(8))
	var building := building_screen_rect(Placement.building(placement,selected_id))
	building.position += center-context_center()
	if not ScreenLayout.free_rect(building,Rect2(Vector2(12,12),size/ui_unit-Vector2(24,24)),blocked): return {}
	return ScreenLayout.radial_group(center,radius,size/ui_unit,blocked,info.get_child_count()>0)

func fit_context() -> void:
	if selected_id=="": return
	if context_tween!=null: context_tween.kill(); context_tween = null
	var center := context_center()
	var radius := context_radius()
	if not solve_context(center,radius).is_empty(): update_context_position(); return
	# Move the building and its complete menu together into the nearest usable
	# workspace. Map art is intentionally not an obstacle.
	var chosen := Vector2.ZERO; var best := INF
	for y in range(180,int(size.y/ui_unit)-160,60):
		for x in range(180,int(size.x/ui_unit)-160,60):
			var point := Vector2(x,y)
			var distance := point.distance_squared_to(center)
			if distance>=best: continue
			if not solve_context(point,radius).is_empty(): chosen = point; best = distance
	if best==INF:
		# A very close zoom can exceed the viewport even as a semicircle.
		if camera_scale>.2*ui_unit:
			set_camera(camera_center,camera_scale*.85); fit_context()
		return
	var destination := camera_center+(center-chosen)*ui_unit/camera_scale
	context_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	context_tween.tween_method(func(point: Vector2): set_camera(point,camera_scale),camera_center,destination,.28)
	context_tween.finished.connect(update_context_position)
	update_context_position()

func update_context_position() -> void:
	if selected_id=="": return
	var center := context_center()
	var radius := context_radius()
	context_layout = solve_context(center,radius)
	context_rects.clear()
	radial.visible = not context_layout.is_empty()
	radial_backdrop.visible = radial.visible
	info.visible = radial.visible and info.get_child_count()>0
	if context_layout.is_empty(): return
	context_rects.assign(context_layout.rects)
	for button in radial.get_children():
		var index: int = button.get_meta("action_index")
		button.position = context_rects[index].position+Vector2(8,8)
	if info.visible: info.position = context_layout.panel.position
	# The existing GPT obsidian painting is clipped to one round backing.
	var points := PackedVector2Array(); var uv := PackedVector2Array()
	var disc_radius := radius
	var source_size := radial_backdrop.texture.get_size()
	for i in range(72):
		var direction := Vector2.from_angle(i*TAU/72)
		points.append(direction*disc_radius)
		uv.append((direction+Vector2.ONE)*source_size/2)
	radial_backdrop.position = center; radial_backdrop.polygon = points; radial_backdrop.uv = uv

func confirm_dismantle() -> void:
	apply_action(Placement.dismantle(placement,selected_id))

func confirm_upgrade() -> void:
	var id := selected_id
	if apply_action(Placement.upgrade(placement,id)): select_building(id); show_info("menu_info")

func apply_action(next: Dictionary) -> bool:
	if not next.get("ok",false): status_text.text = " · ".join(next.get("errors",[])); return false
	placement = next; clear_context(); cancel_build(); render_map(); update_wallet()
	last_save_error = monster_ui.persist()
	status_text.text = "저장됨" if last_save_error==OK else "테스트 저장 실패"
	return true

func _input(event: InputEvent) -> void:
	if battle!=null:
		if handle_key(event): get_viewport().set_input_as_handled(); return
		# Direct movement also works when the adjacent skill popup covers a road.
		if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT and event.pressed:
			if battle_ui.map_input(event): get_viewport().set_input_as_handled()
		return
	if is_instance_valid(monster_ui) and monster_ui.input_event(event): return
	if build_kind=="": return
	if event is InputEventMouseMotion:
		update_preview(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_RIGHT and event.pressed:
			cancel_build(); get_viewport().set_input_as_handled(); return
		if event.button_index!=MOUSE_BUTTON_LEFT: return
		var over_ui := false
		for rect in ui_rects.values():
			if rect.has_point(event.position): over_ui = true
		if over_ui: return
		if event.pressed:
			pointer_down = true; click_armed = true; press_position = event.position; update_preview(event.position)
		elif not event.pressed:
			if click_armed or event.position.distance_to(press_position)>8:
				update_preview(event.position); commit_preview()
			pointer_down = false; click_armed = false
		get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if battle!=null:
		if battle_ui.map_input(event): accept_event()
		else: super._gui_input(event)
		return
	if monster_ui.mode=="place":
		if monster_ui.map_input(event): accept_event()
		else: super._gui_input(event)
		return
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
	if battle!=null and event is InputEventKey and event.pressed:
		if event.keycode==KEY_J: root._activate_update3_duo_link(); return true
		if event.keycode==KEY_K:
			var links: Array = root.update3_active_run.get("equipped_duo_links",[])
			if links.size()>1: root._activate_update3_duo_link(str(links[1]))
			return true
		if event.keycode==KEY_SPACE: battle.set_pause_state(not root.combat_paused); return true
	if event is InputEventKey and event.pressed:
		if event.keycode==KEY_ESCAPE and monster_ui.mode=="place": monster_ui.cancel_drag(); monster_ui.close_info(); return true
		if event.keycode==KEY_ESCAPE: cancel_build(); clear_context(); return true
	return super.handle_key(event)

func preparation_only() -> bool:
	return int(placement.day)==29 and not root._has_defense_wave_for_day(29)

func confirm_preparation_day() -> bool:
	if not preparation_only() or not Grade.enabled() or battle!=null or finish_pending: return false
	finish_pending = true
	# Management purchases live in placement, not in a battle settlement.
	GameState.gold = int(placement.resources.gold); GameState.mana = int(placement.resources.mana); GameState.food = int(placement.resources.food)
	if monster_ui.persist()!=OK: finish_pending = false; return false
	Grade.stash(root,placement,monster_ui.assignments)
	Grade.continue_after_result(root)
	return true

func start_battle() -> bool:
	if battle!=null: return false
	if not root._has_defense_wave_for_day(int(placement.day)):
		status_text.text = "오늘은 전투 없는 준비일입니다. 준비를 확정해 다음 날로 넘어가세요"; return false
	if monster_ui.assignments.is_empty():
		status_text.text = "몬스터 배치 탭에서 수비대를 배치하세요"; return false
	var species: Array = []
	for id in monster_ui.assignments: species.append(monster_ui.members[id].species_id)
	Grade.stash(root,placement,monster_ui.assignments)
	if not monster_ui.unlock_all and root.v130r_story.first_battle(root,species): return false
	monster_ui.set_mode("battle"); monster_ui.unit_layer.hide()
	battle = load("res://scripts/game/ApprovedBattleController.gd").new()
	battle.begin(self)
	battle_ui = load("res://scripts/ui/ApprovedBattleUI.gd").new(); add_child(battle_ui); battle_ui.setup(self,battle)
	return true

func _physics_process(delta: float) -> void:
	if battle!=null and not finish_pending: battle.physics_process(delta)

func show_battle_result(win: bool, reason: String) -> void:
	var controller = battle
	if Grade.enabled(): Grade.stash(root,placement,monster_ui.assignments)
	controller.settle_result(win,reason)
	if food_enabled():
		var session := Grade.load_session(root)
		session.layout.food_state = GameState.food_state.duplicate(true)
		session.layout.resources.food = GameState.food
		Grade.stash(root,session.layout,session.defenders)
		Monsters.save_copy(session.layout,session.defenders,Grade.save_path())
	preload("res://scripts/ui/ApprovedBattleUI.gd").prepare_result_controls(root.ui_layer)
	if food_enabled(): preload("res://scripts/ui/ApprovedBattleUI.gd").food_result_panel(root)
	if win: root.v130r_story.show_victory(root)

func project(cell: Vector2) -> Vector2:
	return Layout.project(cell,Placement.dimensions(placement).x)

func save_path() -> String:
	return Grade.save_path() if Grade.enabled() else Monsters.SAVE_PATH

func set_preview_day(day: int) -> Dictionary:
	if battle!=null: return {"ok":false,"errors":["battle active"]}
	var result := Grade.advance(root,placement,monster_ui.assignments,day)
	if not result.ok: return result
	clear_context(); cancel_build()
	placement = result.layout; monster_ui.assignments = result.defenders
	state = Layout.read(str(placement.grade))
	monster_ui.food_income = GameState.Food.income(day) if food_enabled() else 15 if placement.grade=="F" else 23
	GameState.day = day
	render_map(); update_wallet(); monster_ui.update_food(); show_default()
	var title := chrome.find_child("GradeDayLabel",true,false) as Label
	if title!=null: title.text = "DAY %d  ·  %s등급" % [placement.day,placement.grade]
	if Grade.enabled(): Grade.stash(root,placement,monster_ui.assignments)
	return result

func food_enabled() -> bool:
	return bool(ProjectSettings.get_setting("debug/approved_map_step6",false))

func request_join(id: String) -> void:
	if not food_enabled(): return
	var recruits = load("res://scripts/map_builder/ApprovedRecruitment.gd")
	var eligible: Array = recruits.eligible(root,monster_ui.members,int(placement.day))
	if id in eligible:
		Grade.stash(root,placement,monster_ui.assignments)
		recruits.begin(root,[id]); return
	var species: String = monster_ui.members[id].species_id
	if DataRegistry.update2_contracts.has(species):
		Grade.stash(root,placement,monster_ui.assignments)
		root._set_screen(Constants.SCREEN_CONTRACT_BOARD)
		preload("res://scripts/ui/ApprovedBattleUI.gd").prepare_result_controls(root.ui_layer)
	else:
		status_text.text = "기존 합류 조건: "+recruits.condition(species)

func check_recruits() -> void:
	if not is_instance_valid(monster_ui) or monster_ui.unlock_all or battle!=null: return
	var recruits = load("res://scripts/map_builder/ApprovedRecruitment.gd")
	var pending: Array = []
	for id in recruits.eligible(root,monster_ui.members,int(placement.day)):
		if monster_ui.members[id].species_id not in recruits.CORE and id not in monster_ui.joined: pending.append(id)
	if pending.is_empty():
		root.v130r_story.management(root)
		return
	Grade.stash(root,placement,monster_ui.assignments)
	recruits.begin(root,pending)
