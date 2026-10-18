extends Node
## Raster-only assembly for the branch preview's individual defenders.
const Model = preload("res://scripts/map_builder/ApprovedMonsterPlacement.gd")
const Layout = preload("res://scripts/map_builder/ApprovedMapLayout.gd")
const ActorArt = preload("res://scripts/ui/UIUXActorArt.gd")
const Presentation = preload("res://scripts/map_builder/ApprovedActorPresentation.gd")
const PORTRAITS := {"slime":"uiux3d/pudding_base","goblin":"uiux3d/gob_base","imp":"uiux3d/pynn_base","kobold_scout":"uiux3d/rolo_base","spore_healer":"uiux3d/mori_base","stone_sentinel":"uiux3d/dolkong_base","war_drummer":"uiux3d/dudum_base","moon_tracker":"uiux3d/moon_base","mimic_porter":"uiux3d/mimi_base","ghost_housemaid":"update3/portrait_ghost_housemaid_base","graveyard_hound":"update3/portrait_graveyard_hound_base","armored_beetle":"update3/portrait_armored_beetle_base","spider_tailor":"update4/portrait_spider_tailor_base","bat_courier":"update4/portrait_bat_courier_base"}
var view: Control
var members := {}
var assignments := {}
var mode := "build"
var unlock_all := false
var joined: Array = []
var food_income := 23
var roster_panel: Control
var build_bar: Control
var tabs: Control
var cards := {}
var food_detail: Label
var food_label: Label
var warning: Control
var count_label: Label
var detail: Control
var selected := ""
var unit_layer: Node2D
var units := {}
var overflow_cells := {}
var drag_id := ""
var drag_started := false
var drag_origin := Vector2.ZERO
var ghost: TextureRect
const Spec = preload("res://scripts/systems/SpecializationEffects.gd")
var info_height := 324.0
var skills: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/skills.json"))

func _ready() -> void:
	skills = DataRegistry.skills.duplicate(true)
	unlock_all = OS.get_cmdline_user_args().has("--unlock-all")

func unlocked() -> Array:
	var ids := []
	for id in members:
		if bool(ProjectSettings.get_setting("debug/start_flow14",false)) and not unlock_all and not view.root._monster_available_for_defense(str(members[id].species_id)): continue
		if bool(ProjectSettings.get_setting("debug/start_flow14",false)) and view.root.start_flow.fresh and int(view.placement.day)==1 and not unlock_all and id not in joined and members[id].species_id not in ["slime","goblin","imp"]: continue
		if Model.available(members[id],view.placement.day,unlock_all,joined): ids.append(id)
	return ids

func portrait(id: String) -> String:
	var species: String = members[id].species_id
	var path := "res://assets/sprites/v130r/%s/portrait_%s_card.png" % [species,species]
	if FileAccess.file_exists(path): return path
	return "res://assets/sprites/portraits/"+PORTRAITS[members[id].species_id]+".png"

func role_icon(row: Dictionary) -> String:
	if row.species_id in Model.TANKS: return "garrison"
	if row.species_id in Model.RANGED: return "watch_post_range"
	if row.species_id in Model.SUPPORT: return "hp"
	if row.species_id=="mimic_porter": return "treasury"
	return "tactics"

func build_controls(hud: Control, tab_parent: Control, bar: Control) -> void:
	tabs = tab_parent; build_bar = bar; cards.clear()
	# Expand the existing food row without overlapping tabs.
	hud.size.x = 580
	view.ui_rects.hud.size.x = 580*view.ui_unit
	food_label = hud.get_node("foodNumber") if hud.has_node("foodNumber") else view.wallet.get_node("foodNumber")
	food_label.position.x -= 5; food_label.add_theme_font_size_override("font_size",15)
	food_label.size = Vector2(160,28)
	warning = view.art_at(view.chrome,view.KIT+"warning_64.png",Rect2(27,89,28,28))
	warning.name = "FoodWarning"
	if view.food_enabled(): food_detail = view.label_at(view.chrome,"",Vector2(200,91),16)
	var warning_text: Label = view.label_at(warning,LanguageSettings.text("map.hunger_risk"),Vector2(32,3),17,true)
	warning_text.modulate = Color(1,.55,.4)
	roster_panel = view.panel_image(view.chrome,Rect2(24,866,1560,204)); roster_panel.name = "MonsterRoster"
	count_label = view.label_at(roster_panel,"",Vector2(22,12),17,true)
	view.label_at(roster_panel,LanguageSettings.text("map.drag_cards_to_glowing_posts_drop_to_swap_drag_out_to_remove"),Vector2(290,14),16)
	var index := 0
	for id in members:
		var row: Dictionary = members[id]
		var card: Control = view.panel_image(roster_panel,Rect2(18+(index%12)*115,44+(index/12)*73,111,69)); card.name = id
		view.art_at(card,portrait(id),Rect2(4,4,45,59))
		view.art_at(card,view.KIT+role_icon(row)+"_64.png",Rect2(50,46,17,17))
		view.fit_label(view.label_at(card,row.display_name,Vector2(50,3),14,true),57,9)
		view.art_at(card,view.KIT+"food_64.png",Rect2(50,25,18,18))
		view.label_at(card,str(row.upkeep),Vector2(70,25),15)
		view.label_at(card,"Lv"+str(int(row.level)),Vector2(70,46),11)
		card.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
				begin_drag(id,event.global_position); card.accept_event())
		cards[id] = card; index += 1
	view.image_button(roster_panel,"place_auto",Vector2(1422,43),64,auto_place,LanguageSettings.text("map.auto_deploy_suggested_roles_within_food_income"))
	view.label_at(roster_panel,LanguageSettings.text("map.auto"),Vector2(1438,109),15)
	view.image_button(roster_panel,"place_clear_all",Vector2(1490,43),56,clear_all,LanguageSettings.text("map.clear_all"))
	view.label_at(roster_panel,LanguageSettings.text("map.clear_all"),Vector2(1488,109),14)
	detail = Control.new(); detail.name = "MonsterAdjacentInfo"; detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.chrome.add_child(detail)
	ghost = view.art_at(view.chrome,portrait(members.keys()[0]),Rect2(0,0,80,88)); ghost.name = "MonsterDragGhost"; ghost.modulate.a = .8; ghost.hide()
	set_mode(mode)

func set_mode(next: String) -> void:
	cancel_drag(); close_info(); view.clear_context(); view.cancel_build(); mode = next
	if not is_instance_valid(roster_panel): return
	roster_panel.visible = mode=="place"; build_bar.visible = mode=="build"
	view.ui_rects.build = Rect2(Vector2(24,866)*view.ui_unit,Vector2(1560,204)*view.ui_unit) if mode=="place" else Rect2(Vector2(522,900)*view.ui_unit,Vector2(876,170)*view.ui_unit)
	for i in range(2): tabs.get_child(i*3).modulate = Color(1.25,1.12,.75) if i==int(mode=="place") else Color(.65,.65,.72)
	refresh_cards(); render_sites()

func refresh_cards() -> void:
	var active := unlocked()
	for id in cards:
		var card: Control = cards[id]
		var locked: bool = id not in active
		card.modulate = Color(.4,.4,.48) if locked else Color(.68,.85,.75) if assignments.has(id) else Color.WHITE
		var lock := card.get_node_or_null("RecruitLock")
		if locked and lock==null:
			lock = view.art_at(card,view.KIT+"lock_64.png",Rect2(9,17,32,32)); lock.name = "RecruitLock"
		elif not locked and lock!=null: lock.free()
		if view.food_enabled() and GameState.is_hungry(str(members[id].species_id)): card.modulate = Color(1,.55,.35)
		card.tooltip_text = (LanguageSettings.text("map.not_recruited") if locked else LanguageSettings.text("map.deployed") if assignments.has(id) else LanguageSettings.text("map.reserve"))+LanguageSettings.ui_text(members[id].stats.role)
	if is_instance_valid(count_label): count_label.text = LanguageSettings.text("map.deployed_d_d_recruited_d") % [assignments.size(),total_slots(),active.size()]
	update_food()

func total_slots() -> int:
	var count := 0
	for points in view.placement.defense_points.values(): count += points.size()
	return count

func update_food() -> void:
	if not is_instance_valid(food_label): return
	var cost := Model.upkeep(assignments,members)
	food_label.text = LanguageSettings.text("map.food_d_d_day") % [view.placement.resources.food,cost]
	if view.food_enabled(): food_label.text = LanguageSettings.text("map.d_d_d_day") % [view.placement.resources.food,GameState.Food.capacity(int(view.placement.day)),cost]
	food_label.modulate = Color(1,.5,.35) if cost>food_income else Color.WHITE
	food_label.tooltip_text = LanguageSettings.text("map.food_income_d_day_reserves_cost_0_income_upkeep_storage") % food_income
	warning.visible = cost>food_income
	if is_instance_valid(food_detail): food_detail.text = LanguageSettings.text("map.income_d_day_reserves_0_storage_d") % [food_income,GameState.Food.capacity(int(view.placement.day))]

func render_units() -> void:
	assignments = Model.sanitize(view.placement,assignments,members)
	unit_layer = Node2D.new(); unit_layer.name = "IndividualDefenders"; unit_layer.z_index = 20; view.world.add_child(unit_layer); units.clear()
	for id in assignments:
		var row: Dictionary = members[id]
		var sprite := Sprite2D.new(); sprite.name = id
		var c := Model.cell(view.placement,assignments[id])
		var foot: Vector2 = view.project(Vector2(c)+Vector2(.5,.5))
		var entrance_cell: Vector2i = view.placement.doors.entrance.front[0]
		var direction: Vector2 = view.project(Vector2(entrance_cell)+Vector2(.5,.5))-foot
		var path: String = row.stats.sprite_ne if direction.y<0 else row.stats.sprite
		var sheet: Texture2D = view.texture(path)
		var atlas := ActorArt.frame(sheet,0)
		sprite.texture = atlas
		var used := Presentation.visible_bounds(atlas)
		var factor := Presentation.body_scale(used,row.species_id)
		sprite.scale = Vector2.ONE*factor
		sprite.centered = true
		sprite.flip_h = direction.x>0 if direction.y>=0 else direction.x<0
		var anchor := Vector2(used.get_center().x,used.end.y)-atlas.get_size()/2
		if sprite.flip_h: anchor.x *= -1
		sprite.offset = -anchor
		sprite.position = foot
		sprite.z_index = Presentation.depth(foot)
		unit_layer.add_child(sprite); units[id] = sprite
	render_sites()

func render_sites() -> void:
	overflow_cells.clear()
	if not is_instance_valid(view.sites_layer): return
	for child in view.sites_layer.get_children(): child.free()
	if mode!="place": return
	for b in view.placement.buildings:
		for slot in range(view.placement.defense_points[b.id].size()):
			var target := {"building":b.id,"slot":slot}
			var empty := Model.occupant(assignments,target)==""
			view.cell_highlight(view.sites_layer,Model.cell(view.placement,target),Color(.3,1,.75,.85 if drag_started and empty else .25))
		if drag_started and b.capacity>0:
			var front: Vector2i = view.placement.doors[b.id].front[0]
			var extra := 0
			for delta in [Vector2i(-1,0),Vector2i(0,-1),Vector2i(2,0),Vector2i(0,2),Vector2i(-2,0)]:
				var c: Vector2i = front+delta
				if view.placement.road_cells.has(c) and target_at(c).is_empty() and not view.placement.water.has(c):
					view.cell_highlight(view.sites_layer,c,Color(1,.18,.16,.75)); overflow_cells[c] = true; extra += 1
				if extra==2: break

func target_at(c: Vector2i) -> Dictionary:
	for b in view.placement.defense_points:
		var slot: int = view.placement.defense_points[b].find(c)
		if slot>=0: return {"building":b,"slot":slot}
	return {}

func begin_drag(id: String, point: Vector2) -> void:
	if id not in unlocked():
		view.request_join(id); return
	close_info(); view.dragging = false; drag_id = id; drag_origin = point; drag_started = false

func cancel_drag() -> void:
	drag_id = ""; drag_started = false
	if is_instance_valid(ghost): ghost.hide()
	render_sites()

func input_event(event: InputEvent) -> bool:
	if mode!="place" or drag_id=="": return false
	if event is InputEventMouseMotion:
		if event.position.distance_to(drag_origin)>7:
			if not drag_started: drag_started = true; render_sites()
			ghost.texture = view.texture(portrait(drag_id)); ghost.position = event.position/view.ui_unit-Vector2(40,75); ghost.show()
		view.get_viewport().set_input_as_handled(); return true
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_RIGHT and event.pressed: cancel_drag(); return true
		if event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
			var id := drag_id
			if drag_started:
				var drop_cell: Vector2i = view.cell_at(event.position)
				if overflow_cells.has(drop_cell):
					cancel_drag(); view.get_viewport().set_input_as_handled(); return true
				var target := target_at(drop_cell)
				var over_ui := false
				for r in view.ui_rects.values():
					if r.has_point(event.position): over_ui = true
				if over_ui: target = {}
				# An invalid map cell releases an existing unit; roster drops do nothing.
				apply_drop(id,target)
			else: show_info(id)
			cancel_drag(); view.get_viewport().set_input_as_handled(); return true
	return false

func map_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		var point: Vector2 = event.position/view.ui_unit
		for id in units:
			if unit_rect(id).grow(10).has_point(point): begin_drag(id,event.position); return true
		close_info()
	return false

func apply_drop(id: String, target: Dictionary) -> bool:
	var result := Model.put(view.placement,assignments,id,target,members,unlocked())
	if not result.ok: return false
	assignments = result.assignments; refresh(); return true

func refresh() -> void:
	if is_instance_valid(unit_layer): unit_layer.free()
	render_units(); refresh_cards(); persist(); view.rebuild_minimap()

func persist() -> Error:
	var chosen := {}
	for species in view.root.monster_roster:
		var spec := str(view.root.monster_roster[species].get("specialization_id",""))
		if spec!="": chosen[species] = spec
	view.placement["specializations"] = preload("res://scripts/systems/SpecializationEffects.gd").valid_choices(chosen)
	assignments = Model.sanitize(view.placement,assignments,members)
	if view.food_enabled():
		view.placement.food_state = GameState.food_state.duplicate(true)
		view.placement.food_state.owned = joined.duplicate()
		preload("res://scripts/map_builder/ApprovedGradeProgression.gd").stash(view.root,view.placement,assignments)
	var error := Model.save_copy(view.placement,assignments,view.save_path())
	view.last_save_error = error
	if error!=OK and is_instance_valid(count_label): count_label.text = LanguageSettings.text("map.test_save_failed")+str(error)
	return error

func auto_place() -> void:
	close_info(); assignments = Model.auto_place(view.placement,members,unlocked(),food_income); refresh()

func clear_all() -> void:
	close_info(); assignments.clear(); refresh()

func unit_rect(id: String) -> Rect2:
	var point: Vector2 = view.screen_cell(Vector2(Model.cell(view.placement,assignments[id]))+Vector2(.5,.5))/view.ui_unit
	return Rect2(point-Vector2(42,90)*view.camera_scale/view.ui_unit,Vector2(84,90)*view.camera_scale/view.ui_unit)

func close_info() -> void:
	selected = ""
	if is_instance_valid(detail):
		for child in detail.get_children(): child.free()

func show_info(id: String) -> void:
	close_info(); selected = id
	var row: Dictionary = members[id]
	var height := (386 if row.equipped_skill_ids.size()>2 else 324)+250
	info_height = height
	var footer := height-46
	var panel: TextureRect = view.art_at(detail,"res://assets/maps/v130r_step3/monster_info_panel.png",Rect2(0,0,400,height))
	panel.stretch_mode = TextureRect.STRETCH_SCALE
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	view.art_at(detail,portrait(id),Rect2(18,18,66,66))
	view.label_at(detail,LanguageSettings.ui_text(row.display_name)+"  Lv"+str(int(view.root.monster_roster.get(row.species_id,{}).get("level",row.level))),Vector2(96,24),22,true)
	var role: Label = view.label_at(detail,row.stats.role,Vector2(96,56),15)
	role.size.x = 250; role.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var actual: Dictionary = view.root._monster_combat_stats(row.species_id) if view.root.monster_roster.has(row.species_id) else row.stats.duplicate(true)
	view.label_at(detail,LanguageSettings.text("map.hp_d_atk_d_def_d") % [actual.max_hp,actual.atk,actual.def],Vector2(24,99),18,true)
	var y := 139
	for skill_id in row.equipped_skill_ids.slice(0,3):
		var skill: Dictionary = skills.get(skill_id,{})
		if skill.is_empty(): continue
		view.art_at(detail,skill.icon,Rect2(23,y,38,38))
		view.label_at(detail,skill.display_name,Vector2(70,y-1),17,true)
		var description: String = LanguageSettings.ui_text(skill.description)
		var text: Label = view.label_at(detail,description,Vector2(70,y+22),14)
		text.size.x = 302; text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		text.tooltip_text = description; text.mouse_filter = Control.MOUSE_FILTER_PASS
		y += 62
	build_specialization(id,y)
	var memory_button := Button.new(); detail.add_child(memory_button)
	memory_button.name = "V130RBondMemoryButton"
	memory_button.position = Vector2(24,footer-56); memory_button.size = Vector2(164,40)
	memory_button.text = LanguageSettings.text("map.bond_memories")
	memory_button.pressed.connect(func():
		persist(); view.root.selected_monster_id = row.species_id
		view.root.management_scene.monster_ui.inspected_id = row.species_id
		view.root.management_scene.monster_ui.active_tab = "memory"
		view.root._set_screen(Constants.SCREEN_MONSTER))
	var duo_button := Button.new(); detail.add_child(duo_button)
	duo_button.name = "V130RDuoLoadoutButton"
	duo_button.position = Vector2(204,footer-56); duo_button.size = Vector2(164,40)
	duo_button.text = view.root.continuity.localized("합동기 편성","Duo loadout","合击编组")
	duo_button.pressed.connect(func():
		persist(); view.root.set_meta("v130r_duo_loadout",true)
		view.root.deployed_instance_ids.assign(assignments.keys())
		view.root._set_screen(Constants.SCREEN_DUO_LINK_LOADOUT))
	view.art_at(detail,view.KIT+"food_64.png",Rect2(24,footer,28,28))
	view.label_at(detail,LanguageSettings.text("map.upkeep_d_day") % row.upkeep,Vector2(57,footer+4),17)
	view.image_button(detail,"place_clear_all",Vector2(314,footer-12),42,func(): close_info(); apply_drop(id,{}),LanguageSettings.text("map.remove_this_defender"))
	view.label_at(detail,LanguageSettings.text("map.remove"),Vector2(358,footer+2),15)
	var close: TextureButton = view.image_button(detail,"place_clear_all",Vector2(352,22),25,close_info,LanguageSettings.text("map.close")); close.name = "CloseMonsterInfo"
	position_info()

func position_info() -> void:
	if selected=="": return
	var r := unit_rect(selected) if assignments.has(selected) else Rect2(Vector2(1160,530),Vector2(80,90))
	var bounds: Vector2 = view.size/view.ui_unit
	var height := info_height
	var x := r.end.x+12
	if x+400>bounds.x-12 or (x<1584 and r.position.y+324>866): x = r.position.x-412
	detail.position = Vector2(clampf(x,12,bounds.x-412),clampf(r.position.y-60,106,866-height-12))

func _process(_delta: float) -> void:
	position_info()

func build_specialization(id: String, y: float) -> void:
	var species: String = members[id].species_id
	if not view.root.monster_roster.has(species): view.root.monster_roster[species] = {"level":members[id].level,"exp":0}
	var active: Dictionary = view.root._monster_specialization(species)
	var title: Label = view.label_at(detail,LanguageSettings.text("map.specialization_unlocks_day_2_permanent_choice"),Vector2(24,y),15,true)
	title.name = "SpecializationHeading"
	if not active.is_empty():
		view.art_at(detail,str(active.badge),Rect2(24,y+30,58,58))
		view.label_at(detail,str(active.display_name),Vector2(92,y+32),18,true).name = "SelectedSpecializationName"
		var words := Spec.preview(active,members[id].stats)
		words.append(str(active.get("short_effect",active.get("description",""))))
		var text: Label = view.label_at(detail,"\n".join(words.slice(0,4)),Vector2(92,y+62),14)
		text.tooltip_text = "\n".join(words); text.mouse_filter = Control.MOUSE_FILTER_PASS
		text.name = "SpecializationStatArrows"; text.size = Vector2(282,100); text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		return
	var options: Array = view.root._specializations_for_monster(species)
	for index in range(options.size()):
		var option: Dictionary = options[index]
		var x := 24+index*186
		var button := TextureButton.new(); button.name = "SpecChoose_"+str(option.id)
		button.texture_normal = view.texture(str(option.badge)); button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.position = Vector2(x,y+28); button.size = Vector2(58,58)
		button.disabled = not view.root._can_choose_early_specialization(species,str(option.id))
		button.modulate = Color(.5,.5,.5) if button.disabled else Color.WHITE
		button.tooltip_text = str(option.display_name)+"\n"+str(option.get("short_effect",""))+"\n"+view.root._specialization_block_reason(species,str(option.id))
		button.pressed.connect(func(): choose_specialization.call_deferred(id,str(option.id)))
		detail.add_child(button)
		view.label_at(detail,str(option.display_name),Vector2(x,y+92),15,true)
		var text: Label = view.label_at(detail,str(option.get("short_effect","")),Vector2(x,y+115),13)
		text.size = Vector2(172,54); text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func choose_specialization(id: String, spec_id: String) -> bool:
	var species: String = members[id].species_id
	if not view.root._choose_early_specialization(species,spec_id,false): return false
	persist(); show_info(id)
	return true
