extends Node
## GPT raster command controls; no text-only buttons or procedural decoration.
const ART := "res://assets/maps/v130r_step4/"
const TACTICS := ["rally","focus_attack","emergency_retreat","hold_ground","lure_retreat"]
const TITLES := ["집결 · 길 칸 선택","집중 공격 · 적 선택","비상 후퇴 · 회복 둥지","사수 · 수비 칸 복귀","후퇴 유도 · 길 칸 선택"]
var view: Control
var battle
var bar: Control
var skills: Control
var skill_buttons: Array[TextureButton] = []
var command_buttons := {}
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
		command_buttons[id] = button(bar,ART+"tactic_"+id+".png",Vector2(18+i*84,10),76,func(): choose_command(id),TITLES[i])
	for i in range(4):
		var id: String = ["pause","1","2","3"][i]
		speed_buttons[id] = button(bar,ART+"speed_"+id+".png",Vector2(460+i*66,19),58,func(): choose_speed(id),"일시정지" if i==0 else "속도 ×"+id)
	battle_status = view.label_at(view.chrome,"",Vector2(24,105),20,true)
	health_status = view.label_at(view.chrome,"",Vector2(24,140),18)
	skills = Control.new(); skills.name = "SelectedMonsterSkills"; skills.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.chrome.add_child(skills)
	for i in range(3):
		view.monster_ui.tabs.get_child(i*3).modulate = Color(1.25,1.12,.75) if i==2 else Color(.45,.45,.5)
	view.ui_rects.build = Rect2(Vector2(590,956)*view.ui_unit,Vector2(740,100)*view.ui_unit)
	view.ui_rects["battle_status"] = Rect2(Vector2(20,100)*view.ui_unit,Vector2(490,85)*view.ui_unit)

func button(parent: Control, path: String, point: Vector2, width: float, action: Callable, hint: String) -> TextureButton:
	var control := TextureButton.new(); control.texture_normal = view.texture(path)
	control.ignore_texture_size = true; control.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	control.position = point; control.size = Vector2.ONE*width; control.tooltip_text = hint
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
	var panel: Control = view.panel_image(skills,Rect2(0,0,252,98)); panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.label_at(panel,unit.display_name+" · HP %d/%d" % [unit.hp,unit.max_hp],Vector2(12,5),15,true).name = "SelectedVitals"
	var count := 0
	for slot in range(slots.size()):
		if slots[slot]==null: continue
		var definition: Dictionary = DataRegistry.skill(str(slots[slot]))
		var b := button(panel,str(definition.get("icon",ART+"skill_block.png")),Vector2(10+count*60,30),56,
			func(): battle.request_unit_skill(unit,slot),str(definition.get("display_name",slots[slot])))
		b.set_meta("slot",slot); b.set_meta("skill_id",str(slots[slot])); skill_buttons.append(b); count += 1
	direct_button = button(panel,ART+"skill_direct_control_v2.png",Vector2(10+count*60,30),56,func():
		battle.direct_unit = null if battle.direct_unit==unit else unit
		unit.stop_navigation(),
		"직접 조종 · 우클릭으로 길 이동, 다시 누르면 자동 수비")
	position_skills()

func position_skills() -> void:
	if not is_instance_valid(selected) or not selected.is_alive(): skills.hide(); return
	var point: Vector2 = view.world.to_global(selected.position)/view.ui_unit
	var screen: Vector2 = view.size/view.ui_unit
	# Follow the monster, and choose the side away from the nearest screen edge.
	var x: float = point.x+42 if point.x+300<screen.x else point.x-294
	var y: float = clampf(point.y-116,190,screen.y-232)
	skills.position = Vector2(x,y)
	var label: Label = skills.find_child("SelectedVitals",true,false)
	if label!=null: label.text = selected.display_name+" · HP %d/%d" % [selected.hp,selected.max_hp]
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
		var d: float = (candidate.position-Vector2(0,40)).distance_to(point)
		if candidate.is_alive() and d<distance: distance = d; unit = candidate
	if unit!=null: select_unit(unit); return true
	return false

func refresh() -> void:
	if not battle.running: return
	var alive := 0
	for enemy in battle.root.enemy_units:
		if enemy.is_alive(): alive += 1
	battle_status.text = "DAY %d · 웨이브 %d/%d · 남은 적 %d" % [GameState.day,battle.root.spawned_count,battle.root.wave_manager.total_to_spawn,alive]
	health_status.text = "옥좌 %d/%d  ·  금고 손실 %d  ·  %s" % [GameState.demon_lord_hp,GameState.demon_lord_max_hp,battle.root.treasure_gold_stolen_this_battle,
		"일시정지" if battle.root.combat_paused else "×%d  %.1f초" % [battle.root.combat_speed,battle.root.combat_time]]
	if pending_command!="": battle_status.text += " · "+TITLES[TACTICS.find(pending_command)]
	for id in command_buttons: command_buttons[id].modulate = Color(1.25,1.15,.7) if id==battle.command or id==pending_command else Color.WHITE
	for id in speed_buttons:
		var active: bool = battle.root.combat_paused if id=="pause" else not battle.root.combat_paused and int(id)==int(battle.root.combat_speed)
		speed_buttons[id].modulate = Color(1.25,1.15,.7) if active else Color.WHITE
	view.placement.resources.mana = GameState.mana; view.placement.resources.gold = GameState.gold
	view.update_wallet()

func _process(delta: float) -> void:
	position_skills(); refresh_clock += delta
	if refresh_clock>=.1: refresh_clock = 0; refresh(); layout_vitals()

func layout_vitals() -> void:
	var units: Array = battle.root.monster_units+battle.root.enemy_units
	units.sort_custom(func(a,b):
		if a.selected!=b.selected: return a.selected
		return a.position.y<b.position.y if a.position.y!=b.position.y else a.get_instance_id()<b.get_instance_id())
	var occupied: Array[Rect2] = []
	if skills.visible:
		occupied.append(Rect2(view.world.to_local(skills.global_position),Vector2(252,98)*view.ui_unit/view.camera_scale).grow(8))
	for unit in units:
		unit.vitals.visible = unit.is_alive()
		if not unit.is_alive(): continue
		var desired: Vector2 = unit.position+unit.combat_anchor_local("head")-Vector2(0,10)
		var chosen := desired
		for row in range(units.size()+1):
			var found := false
			for column in [0,-1,1]:
				var point: Vector2 = desired+Vector2(column*120,-row*40)
				var rect := Rect2(point+Vector2(-58,-26),Vector2(116,38)).grow(2)
				var blocked := false
				for other in occupied:
					if rect.intersects(other): blocked = true; break
				if not blocked: chosen = point; found = true; occupied.append(rect); break
			if found: break
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
		node.tooltip_text = node.text; node.text = ""
		if node.has_method("set_label"): node.set_label("")
		if "selected_marker" in node: node.selected_marker = false
		if "jewel" in node: node.jewel = false
		node.icon = preload("res://assets/maps/v130r_step2/ui/menu_info.png")
		if "다음" in node.tooltip_text or "계속" in node.tooltip_text: node.icon = preload("res://assets/maps/v130r_step4/speed_1.png")
		elif "타이틀" in node.tooltip_text: node.icon = preload("res://assets/ui/kit/icons/icon_close_128.png")
		node.expand_icon = true
	for child in node.get_children(): prepare_result_controls(child)
