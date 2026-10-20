extends Node
## GPT raster command controls; no text-only buttons or procedural decoration.
const ART := "res://assets/maps/v130r_step4/"
const Presentation = preload("res://scripts/map_builder/ApprovedActorPresentation.gd")
const TACTICS := ["rally","focus_attack","emergency_retreat","hold_ground","lure_retreat"]
const TITLES := ["map.rally_choose_a_road_tile","map.focus_fire_choose_an_enemy","map.emergency_retreat_recovery_nest","map.hold_ground_return_to_post","map.lure_retreat_choose_a_road_tile"]
var view: Control
var battle
var bar: Control
var skills: Control
var skill_buttons: Array[TextureButton] = []
var command_buttons := {}
var command_timers := {}
var speed_buttons := {}
var battle_status: Label
var health_status: Label
var selected: Node
var direct_button: TextureButton
var pending_command := ""
var refresh_clock := 0.0

func setup(owner_view: Control, controller) -> void:
	view = owner_view; battle = controller
	bar = view.panel_image(view.chrome,Rect2(590,956,740,100)); bar.name = "BattleCommandBar"
	for i in range(TACTICS.size()):
		var id: String = TACTICS[i]
		command_buttons[id] = button(bar,ART+"tactic_"+id+".png",Vector2(18+i*84,10),76,func(): choose_command(id),LanguageSettings.text(TITLES[i]))
		var timer: Label = view.label_at(command_buttons[id],"",Vector2(0,52),18,true)
		timer.name = "CommandRemaining"; timer.size = Vector2(76,24)
		timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		timer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		command_timers[id] = timer
	for i in range(4):
		var id: String = ["pause","1","2","3"][i]
		speed_buttons[id] = button(bar,ART+"speed_"+id+".png",Vector2(460+i*66,19),58,func(): choose_speed(id),LanguageSettings.text("map.paused") if i==0 else LanguageSettings.text("map.speed")+id)
	battle_status = view.label_at(view.chrome,"",Vector2(24,130 if view.food_enabled() else 105),20,true)
	health_status = view.label_at(view.chrome,"",Vector2(24,165 if view.food_enabled() else 140),18)
	skills = Control.new(); skills.name = "SelectedMonsterSkills"; skills.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.chrome.add_child(skills)
	for i in range(3):
		view.monster_ui.tabs.get_child(i*3).modulate = Color(1.25,1.12,.75) if i==2 else Color(.45,.45,.5)
	view.ui_rects.build = Rect2(Vector2(590,956)*view.ui_unit,Vector2(740,100)*view.ui_unit)
	view.ui_rects["battle_status"] = Rect2(Vector2(20,125 if view.food_enabled() else 100)*view.ui_unit,Vector2(490,85)*view.ui_unit)
	battle.root._build_update3_duo_link_combat_hud()

func button(parent: Control, path: String, point: Vector2, width: float, action: Callable, hint: String) -> TextureButton:
	var control := preload("res://scripts/ui/ReadableTooltipTextureButton.gd").new(); control.texture_normal = view.texture(path)
	control.ignore_texture_size = true; control.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	control.position = point; control.size = Vector2.ONE*width; control.tooltip_text = LanguageSettings.ui_text(hint)
	control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	control.pressed.connect(action); parent.add_child(control); return control

func choose_speed(id: String) -> void:
	if id=="pause": battle.set_pause_state(not battle.root.combat_paused)
	else: battle.set_speed(float(id))
	refresh()

func choose_command(id: String) -> void:
	if id in ["emergency_retreat","hold_ground"]:
		battle.issue_command(id); pending_command = ""
	else: pending_command = id
	refresh()

func select_unit(unit: Node) -> void:
	if is_instance_valid(selected): selected.set_selected(false)
	selected = unit; battle.root.selected_unit = unit
	for c in skills.get_children(): c.free()
	skill_buttons.clear()
	if not is_instance_valid(unit) or not unit.is_alive(): skills.hide(); return
	unit.set_selected(true); skills.show()
	var slots: Array = battle.skill_slots_for(unit)
	var panel: Control = view.panel_image(skills,Rect2(0,0,252,148 if bool(unit.get_meta("food_hungry",false)) else 98)); panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.label_at(panel,LanguageSettings.ui_text(unit.display_name)+" · HP %d/%d" % [unit.hp,unit.max_hp],Vector2(12,5),15,true).name = "SelectedVitals"
	if bool(unit.get_meta("food_hungry",false)):
		var hungry_text: Label = view.label_at(panel,LanguageSettings.text("map.hungry_atk_20_ncannot_heal_at_recovery_nests"),Vector2(12,99),16)
		hungry_text.name = "HungryStatus"; hungry_text.modulate = Color(1,.65,.4)
	var count := 0
	for slot in range(slots.size()):
		if slots[slot]==null: continue
		var definition: Dictionary = DataRegistry.skill(str(slots[slot]))
		if bool(definition.get("passive",false)): continue
		var b := button(panel,str(definition.get("icon",ART+"skill_block.png")),Vector2(10+count*60,30),56,
			func(): battle.request_unit_skill(unit,slot),str(definition.get("display_name",slots[slot])))
		b.set_meta("slot",slot); b.set_meta("skill_id",str(slots[slot])); skill_buttons.append(b); count += 1
	direct_button = button(panel,ART+"skill_direct_control_v2.png",Vector2(10+count*60,30),56,func():
		battle.direct_unit = null if battle.direct_unit==unit else unit
		unit.stop_navigation(),
		LanguageSettings.text("map.direct_control_right_click_a_road_to_move_click_again_for_auto_defense"))
	position_skills()

func position_skills() -> void:
	if not is_instance_valid(selected) or not selected.is_alive(): skills.hide(); return
	var point: Vector2 = view.world.to_global(selected.position)/view.ui_unit
	var screen: Vector2 = view.size/view.ui_unit
	var factor: float = view.camera_scale/view.ui_unit*Presentation.ui_scale(selected.unit_id)
	skills.scale = Vector2.ONE*factor
	# Follow the monster, and choose the side away from the nearest screen edge.
	var x: float = point.x+42*factor if point.x+300*factor<screen.x else point.x-294*factor
	x = clampf(x,8,maxf(8,screen.x-252*factor-8))
	var y: float = clampf(point.y-116*factor,190,maxf(190,screen.y-220-148*factor))
	skills.position = Vector2(x,y)
	var label: Label = skills.find_child("SelectedVitals",true,false)
	if label!=null: label.text = LanguageSettings.ui_text(selected.display_name)+" · HP %d/%d" % [selected.hp,selected.max_hp]
	for b in skill_buttons:
		var available: bool = selected.skill_ready(b.get_meta("skill_id")) and not battle.root.combat_paused
		b.modulate = Color.WHITE if available else Color(.4,.4,.5)

func map_input(event: InputEvent) -> bool:
	if not event is InputEventMouseButton or not event.pressed: return false
	var point: Vector2 = view.world.to_local(event.position)
	if event.button_index==MOUSE_BUTTON_RIGHT and is_instance_valid(battle.direct_unit):
		if battle.map.is_walkable(point): battle.move_unit_to_point(battle.direct_unit,point,true)
		return true
	if event.button_index!=MOUSE_BUTTON_LEFT: return false
	if pending_command!="":
		var target: Node
		if pending_command=="focus_attack":
			var distance := 80.0
			for enemy in battle.root.enemy_units:
				var d: float = enemy.position.distance_to(point)
				if enemy.is_alive() and d<distance: distance = d; target = enemy
			if target==null: return true
		elif not battle.map.is_walkable(point): return true
		battle.issue_command(pending_command,point,target); pending_command = ""; return true
	var unit: Node; var distance := 80.0
	for candidate in battle.root.monster_units:
		var d: float = candidate.visible_body_rect().get_center().distance_to(point)
		if candidate.is_alive() and d<distance: distance = d; unit = candidate
	if unit!=null: select_unit(unit); return true
	return false

func refresh() -> void:
	if not battle.running: return
	var alive := 0
	for enemy in battle.root.enemy_units:
		if enemy.is_alive(): alive += 1
	battle_status.text = LanguageSettings.text("map.day_d_wave_d_d_enemies_d") % [GameState.day,battle.root.spawned_count,battle.root.wave_manager.total_to_spawn,alive]
	health_status.text = LanguageSettings.text("map.throne_d_d_gold_stolen_d_s") % [GameState.demon_lord_hp,GameState.demon_lord_max_hp,battle.root.treasure_gold_stolen_this_battle,
		LanguageSettings.text("map.paused") if battle.root.combat_paused else LanguageSettings.text("map.d_1fs") % [battle.root.combat_speed,battle.root.combat_time]]
	if pending_command!="": battle_status.text += " · "+LanguageSettings.text(TITLES[TACTICS.find(pending_command)])
	var remaining: float = battle.command_remaining()
	for id in command_buttons:
		var active: bool = id==battle.command and remaining>0
		command_buttons[id].modulate = Color(1.25,1.15,.7) if active or id==pending_command else Color.WHITE
		command_timers[id].text = "%.1fs"%remaining if active else ""
		command_timers[id].visible = active
	for id in speed_buttons:
		var active: bool = battle.root.combat_paused if id=="pause" else not battle.root.combat_paused and int(id)==int(battle.root.combat_speed)
		speed_buttons[id].modulate = Color(1.25,1.15,.7) if active else Color.WHITE
	view.placement.resources.mana = GameState.mana; view.placement.resources.gold = GameState.gold
	view.update_wallet()

func _process(delta: float) -> void:
	# Approved combat disables GameRoot's physics loop. Keep nonblocking story
	# expiry and dialogue auto timing alive under the same modal input owner.
	if battle.root.current_screen==Constants.SCREEN_COMBAT:
		battle.root._suspended_interface_tick(delta)
	# Settings keep this battle view alive while hiding it. Resume the visual
	# layout on the first visible frame, before it is drawn again.
	if not view.is_visible_in_tree(): return
	position_skills(); layout_vitals(); refresh_clock += delta
	if refresh_clock>=.1: refresh_clock = 0; refresh()

func layout_vitals() -> void:
	var units: Array = battle.root.monster_units+battle.root.enemy_units
	var alive_count := 0
	for actor in units:
		if actor.is_alive(): alive_count += 1
	units.sort_custom(func(a,b):
		if a.selected!=b.selected: return a.selected
		return a.position.y<b.position.y if a.position.y!=b.position.y else a.get_instance_id()<b.get_instance_id())
	var occupied: Array[Rect2] = []
	if skills.visible and is_instance_valid(selected):
		occupied.append(Rect2(view.world.to_local(skills.global_position),Vector2(252,148 if bool(selected.get_meta("food_hungry",false)) else 98)*skills.scale*view.ui_unit/view.camera_scale).grow(8))
	for unit in units:
		unit.health.set_crowded(alive_count>=10)
		unit.vitals.visible = unit.health.should_show()
		unit.update_silhouette()
		if not unit.vitals.visible: unit.vitals_link.hide(); continue
		var desired: Vector2 = unit.desired_vitals_position(view.camera_scale)
		var chosen := desired
		var extent: Vector2 = unit.vitals_rect().size+Vector2(8,8)
		for row in range(units.size()*2+1):
			# Alternate above/below while keeping the label on its own body's X.
			var level := ceili(row/2.0)*(1 if row%2==0 else -1)
			var point: Vector2 = desired+Vector2(0,level*extent.y)
			var rect: Rect2 = unit.vitals_rect_at(point).grow(3)
			var blocked := false
			for other in occupied:
				if rect.intersects(other): blocked = true; break
			if not blocked: chosen = point; occupied.append(rect); break
		unit.set_vitals_position(chosen)

static func prepare_result_controls(node: Node) -> void:
	# Keep existing result actions/signals and layout, using the existing GPT kit art.
	if node.get_script()!=null and node.get_script().resource_path=="res://scripts/ui/kit/KitSurface.gd":
		node.hide(); return
	if node is Panel or node is PanelContainer or node is Button:
		var panel := StyleBoxTexture.new()
		panel.texture = preload("res://assets/ui/uiux/obsidian_button.png") if node is Button else preload("res://assets/ui/uiux/obsidian_panel.png")
		for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
			panel.set_texture_margin(side,24); panel.set_content_margin(side,12)
		if node is Button:
			for key in ["normal","hover","pressed","disabled","focus"]: node.add_theme_stylebox_override(key,panel)
		else: node.add_theme_stylebox_override("panel",panel)
	if node is Label or node is RichTextLabel:
		node.add_theme_font_override("font",preload("res://assets/fonts/NEXON_Maplestory_Light.otf"))
		if node is RichTextLabel:
			for key in ["normal_font","italics_font","mono_font"]: node.add_theme_font_override(key,preload("res://assets/fonts/NEXON_Maplestory_Light.otf"))
			node.add_theme_font_override("bold_font",preload("res://assets/fonts/NEXON_Maplestory_Bold.otf"))
	if node is Button:
		if node.text!="": node.tooltip_text = node.text
		node.text = ""
		if node.has_method("set_label"): node.set_label("")
		if "selected_marker" in node: node.selected_marker = false
		if "jewel" in node: node.jewel = false
		if node.icon==null: node.icon = preload("res://assets/maps/v130r_step2/ui/menu_info.png")
		if LanguageSettings.text("map.next") in node.tooltip_text or LanguageSettings.text("map.continue") in node.tooltip_text or node.name=="LegacyNextButton": node.icon = preload("res://assets/maps/v130r_step4/speed_1.png")
		elif LanguageSettings.text("map.title") in node.tooltip_text: node.icon = preload("res://assets/ui/kit/icons/icon_close_128.png")
		node.expand_icon = true
	for child in node.get_children(): prepare_result_controls(child)

static func food_result_panel(root: Node) -> void:
	var ledger: Dictionary = root.result_summary.get("food_ledger",{})
	if ledger.is_empty(): return
	var panel := TextureRect.new(); panel.name = "FoodSettlementPanel"
	panel.texture = preload("res://assets/ui/uiux/obsidian_panel.png")
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.position = Vector2(1120,190); panel.size = Vector2(730,340)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP; root.ui_layer.add_child(panel)
	var title := Label.new(); title.text = LanguageSettings.text("map.food_daily_settlement"); title.position = Vector2(28,22)
	title.add_theme_font_override("font",preload("res://assets/fonts/NEXON_Maplestory_Bold.otf")); title.add_theme_font_size_override("font_size",28); panel.add_child(title)
	var body := RichTextLabel.new(); body.name = "FoodSettlementDetails"
	body.position = Vector2(28,72); body.size = Vector2(670,245); body.bbcode_enabled = false
	body.add_theme_font_override("normal_font",preload("res://assets/fonts/NEXON_Maplestory_Light.otf")); body.add_theme_font_size_override("normal_font_size",23)
	body.text = "\n\n".join(preload("res://scripts/systems/MonsterFoodService.gd").lines(ledger)); panel.add_child(body)
	preload("res://scripts/ui/DialogueLayout.gd").scrolling_text(body)
	body.add_theme_font_size_override("normal_font_size",UISettings.scaled_font_size(23))
