extends Node
const GameScene = preload("res://scenes/game/GameRoot.tscn")
const Audit = preload("res://tools/ux_audit/Audit.gd")
var game: Node
var checks := 0
var failures: Array[String] = []
var screens: Array = []
var out := "res://tmp/v1213_u5c/contract"
var capture := false
var selected: Node
var capture_paths: Array[String]=[]
var capture_filter: PackedStringArray=[]

func _ready() -> void:
	get_tree().create_timer(140).timeout.connect(func(): get_tree().quit(2))
	call_deferred("run")

func expect(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message); print("FAIL: "+message)

func settle(count: int=6) -> void:
	for i in range(count): await get_tree().process_frame

func control(id: String) -> Control:
	return game.ui_layer.find_child(id,true,false) as Control

func click(id: String) -> void:
	var target:=control(id)
	expect(target!=null and target.is_visible_in_tree(),"visible click "+id)
	if target==null: return
	var point:=target.get_global_transform_with_canvas()*(target.size/2)
	var motion:=InputEventMouseMotion.new(); motion.position=point; motion.global_position=point
	get_viewport().push_input(motion,true)
	await settle(2)
	for pressed in [true,false]:
		var e:=InputEventMouseButton.new(); e.position=point; e.global_position=point; e.button_index=MOUSE_BUTTON_LEFT; e.pressed=pressed
		get_viewport().push_input(e,true)
		await get_tree().process_frame
	await settle()

func rebuild() -> void:
	game._set_screen("combat",false)
	await settle()
	game.hud.update_combat_status()
	await settle()

func inspect(id: String, save: bool=false) -> void:
	await settle()
	var items: Array=[]
	var audit:=Audit.new(); audit.game=game; audit.collect(game.ui_layer,items); audit.free()
	for item in items:
		if str(item.text).is_empty(): continue
		if item.type=="Label": expect(int(item.line_count)<=int(item.visible_lines),id+" visible lines "+str(item.name))
		if bool(item.button):
			expect(not str(item.tooltip).is_empty(),id+" tooltip "+str(item.name))
			if not str(item.clip_parent).contains("Scroll"):
				var rect:=Rect2(item.rect[0],item.rect[1],item.rect[2],item.rect[3])
				expect(get_viewport().get_visible_rect().grow(2).encloses(rect),id+" viewport "+str(item.name))
	for pair in [["CombatSpeedPanel","CombatUnitInspector"],["CombatCommandBar","CombatUnitInspector"],["CombatSpeedPanel","CombatContextDrawer"],["CombatCommandBar","CombatTacticsPanel"],["CombatThroneStatus","CombatFloorControls"]]:
		var a:=control(pair[0]);var b:=control(pair[1])
		if a!=null and b!=null and a.is_visible_in_tree() and b.is_visible_in_tree(): expect(not a.get_global_rect().intersects(b.get_global_rect()),id+" no overlap "+str(pair))
	expect(control("CommonMenuHolder")==null,"combat owns one menu without a duplicate overlay")
	for panel_id in ["CombatThroneStatus","CombatSpeedPanel","CombatCommandBar","CombatUnitInspector","CombatContextDrawer","CombatTacticsPanel","CombatFloorControls"]:
		var panel:=control(panel_id)
		if panel==null or not panel.is_visible_in_tree(): continue
		for b in panel.find_children("*","BaseButton",true,false):
			if b.get_parent() == panel or panel_id in ["CombatThroneStatus","CombatSpeedPanel","CombatFloorControls"]:
				expect(panel.get_global_rect().grow(1).encloses(b.get_global_rect()),id+" panel owns "+str(b.name))
		var close=control("CombatUnitInspectorClose" if panel_id=="CombatUnitInspector" else "CombatTacticsClose")
		var scroll=control(panel_id+"Scroll")
		if close!=null and scroll!=null and panel.is_ancestor_of(close): expect(close.get_global_rect().end.y<=scroll.get_global_rect().position.y,"fixed close stays above scrolling detail")
	screens.append({"id":id,"items":items,"save":save})
	if control("CombatCommandBar")!=null and control("CombatCommandBar").is_visible_in_tree():
		expect(control("CombatSpecialActions")==null,"instant actions occupy a single strip")
		for b in control("CombatCommandBar").find_children("*","Button",true,false):
			if b.has_method("set_action_caption"):
				expect(b.get_global_rect().grow(1).encloses(b.caption.get_global_rect()),id+" caption inside action "+str(b.name))
		if game._update3_duo_link_hud_state().get("equipped",[]).is_empty():
			expect(control("CombatDuoLocked")!=null and control("CombatDuoLocked").disabled,"unequipped duo shows a locked action without spending")
		for button_id in ["GLOBAL_DIRECTIVE_DEFEND","V122_COMMAND_FOCUS","V122_COMMAND_FALLBACK"]:
			var b=control(button_id)
			expect(is_equal_approx(b.size.x,b.size.y),"square action "+button_id)
			expect(control("CombatCommandBar").get_global_rect().encloses(b.get_global_rect()),"fixed order remains visible "+button_id)
		for button_id in ["CombatMenu","CombatSave","CombatDetails"]:
			var b: Button=control(button_id)
			expect(b.icon!=null and b.get_theme_constant("icon_max_width")>=40,"readable top icon "+button_id)
		if control("CombatUnitInspector")!=null:
			expect(control("CombatSelectedHPBar")!=null,"selected summary has a live HP bar")
			expect(control("CombatRepresentativeSkill")!=null,"representative skill is fixed above detail")
			expect(control("CombatUnitInspector").get_global_rect().encloses(control("CombatRepresentativeSkill").get_global_rect()),"representative skill stays in inspector")
	if capture and save and (capture_filter.is_empty() or capture_filter.has(id)):
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join(id+".png"))
		capture_paths.append(id+".png")

func interactions() -> void:
	game.combat_scene.set_pause_state(false,false)
	await rebuild()
	expect(control("CombatTacticsPanel")==null,"standing policy initially folded")
	await click("CombatTacticsToggle")
	expect(control("CombatTacticsPanel")!=null,"policy opens using real mouse input")
	expect(not control("CombatTacticsPanel").is_ancestor_of(control("GLOBAL_DIRECTIVE_DEFEND")),"spending action separate from policy")
	await click("CombatTacticsClose")
	for value in [1.0,1.5,2.0,3.0]:
		await click({1.0:"CombatSpeed1x",1.5:"CombatSpeed15x",2.0:"CombatSpeed2x",3.0:"CombatSpeed3x"}[value])
		expect(is_equal_approx(game.combat_speed,value),"speed changes through existing handler %s"%value)
	await click("CombatPause")
	expect(game.combat_scene.requested_pause,"fixed pause requests pause")
	await click("CombatMenu")
	expect(game.pause_menu_open,"menu opens")
	game._close_pause_menu(); await settle()
	expect(game.combat_scene.requested_pause,"menu restores already paused")
	await click("CombatPause")
	expect(not game.combat_scene.requested_pause,"fixed resume restores running")
	await click("CombatSave")
	expect(game.pause_menu_open and not game.continuity.menu_feedback.is_empty(),"save icon preserves existing mid-battle refusal")
	game._close_pause_menu(); await settle()
	await click("CombatDetails")
	expect(game.combat_scene.requested_pause and control("CombatContextDrawer")!=null,"battle log pauses")
	await click("CombatContextClose")
	expect(not game.combat_scene.requested_pause,"battle log restores running")
	game.combat_scene.set_pause_state(true,false)
	await click("CombatDetails");await click("CombatContextClose")
	expect(game.combat_scene.requested_pause,"battle log restores already paused")
	game.combat_scene.set_pause_state(false,false)
	# Existing targeting service owns cost, candidates and single commitment.
	await click("GLOBAL_DIRECTIVE_DEFEND")
	expect(game.combat_scene.pending_v122_command_id=="rally","order opens target selection")
	var targeting: Dictionary=game.combat_scene.command_targeting_state()
	var candidates: Array=targeting.get("candidates",[])
	expect(not candidates.is_empty(),"existing candidates available")
	if not candidates.is_empty():
		var before: Dictionary=game.get_meta("v122_command_state",{}).duplicate(true)
		var candidate: Dictionary=candidates[0]
		game._select_v122_command_target(str(candidate.type),str(candidate.id));await settle()
		var after: Dictionary=game.get_meta("v122_command_state",{})
		expect(int(after.get("points",0))==int(before.get("points",0))-1,"exact existing rally cost once")
		expect(game.combat_scene.pending_v122_command_id=="","target consumed once")
	game.selected_unit=null; await rebuild()
	var point: Vector2=game._combat_world_to_screen(selected.global_position)
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
		get_viewport().push_input(event,true);await get_tree().process_frame
	await settle()
	expect(game.selected_unit==selected,"actual battlefield click selects the ally")
	var skill_id:="slime_shield"
	expect(control("ManualCast_"+skill_id)!=null,"selected ally exposes existing skill")
	if control("ManualCast_"+skill_id)!=null:
		UISettings.skill_cutscene_policy="off"
		var mana:=GameState.mana
		var cost: int=game._current_skill_mana_cost(DataRegistry.skill(skill_id),selected)
		await click("ManualCast_"+skill_id)
		expect(GameState.mana==mana-cost and not selected.skill_ready(skill_id),"manual skill pays existing cost and starts cooldown")
		var paid:=GameState.mana
		await click("ManualCast_"+skill_id)
		expect(GameState.mana==paid,"cooldown prevents duplicate skill spending")
	await click("CombatUnitDetailsToggle")
	expect(control("CombatUnitInspectorScroll")!=null,"stats expand below fixed summary")
	await click("CombatUnitDetailsToggle")
	expect(control("CombatUnitInspectorScroll")==null,"stats fold without hiding representative skill")
	# Cosmetic stage tests use an isolated effect counter, never change combat rules.
	var presentation=game.combat_scene.skill_actions
	var tally: Array=[0]
	UISettings.skill_cutscene_policy="always"
	game.combat_scene.set_pause_state(false,false)
	var effect:=func():
		tally[0]+=1
		game.combat_scene._spawn_contact_damage_number(selected,12,null,"u5c","skill")
		return true
	expect(presentation.request({"key":"u5c_stage","name":"U5-C","actors":[selected],"kind":"skill"},effect),"cutscene accepted")
	presentation.stage.set_process(false)
	expect(presentation.stage_layer.layer==40,"cutscene owns separate canvas above HUD")
	var stripe= presentation.stage.find_child("SkillActionStyleBStrip",true,false)
	expect(stripe!=null and stripe.size.x>stripe.size.y*3,"Style B cutscene uses a wide strip over the live battlefield")
	for button_id in ["SkillActionSkipButton","CutsceneCombatMenu"]:
		var b= presentation.stage.find_child(button_id,true,false)
		expect(b!=null and b.has_method("set_variant") and b.icon!=null,"Style B cutscene button "+button_id)
	var notice:=Panel.new();notice.name="PromotionSupportNotice";game.ui_layer.add_child(notice)
	presentation._hide_inspectors()
	for id in ["CombatSpeedPanel","CombatCommandBar","CombatUnitInspector","PromotionSupportNotice"]:
		expect(not control(id).is_visible_in_tree(),"cutscene hides "+id)
	presentation._commit()
	var number: Label=game.combat_scene.damage_presentation.active.back().label
	expect(number.get_parent()==presentation.stage_layer,"real contact number shares the cutscene canvas")
	presentation.skip();presentation.skip();await settle()
	expect(number.get_parent()==game.effect_root,"pooled number restored before canvas cleanup")
	expect(tally[0]==1,"double skip commits effect once")
	expect(control("CombatSpeedPanel").visible and notice.visible,"cutscene restores original HUD and pending notice")
	notice.queue_free()
	presentation.request({"key":"u5c_menu","name":"U5-C","actors":[selected],"kind":"skill"},effect)
	presentation.stage.set_process(false)
	game._open_pause_menu();await settle()
	expect(tally[0]==2 and not presentation.is_active() and game.pause_menu_open,"menu interrupt commits once and takes ownership")
	game._close_pause_menu();await settle()
	expect(not game.combat_scene.requested_pause,"menu interruption restores prior running state")
	# Floor runtime is a synthetic unlocked UI fixture; rules remain untouched.
	game.update4_active_run["campaign_mode_id"]="council_season"
	game.update4_active_run["upper_floor"]={"unlocked":true,"graph_runtime":{"entities":{str(selected.unit_id):{"floor_id":"1F"}},"visible_floor":"1F"}}
	game.selected_unit=selected
	await rebuild()
	await click("CombatFloor2")
	expect(game.selected_unit==null and control("CombatUnitInspector")==null,"floor switch clears selection from another floor")
	game.update4_active_run.clear()

func run() -> void:
	expect(ProjectSettings.globalize_path("user://").replace("\\","/").contains("/tmp/v1213_u5c/"),"isolated profile")
	capture=OS.get_cmdline_user_args().has("--capture-only")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output-dir="): out=arg.trim_prefix("--output-dir=")
		if arg.begins_with("--capture-filter="): capture_filter=arg.trim_prefix("--capture-filter=").split(",")
	GameState.reset();LanguageSettings.set_locale("ko",false)
	game=GameScene.instantiate()
	game.campaign_save_enabled=false;game.campaign_auxiliary_save_enabled=false;game.campaign_save_v4_enabled=false;game.campaign_save_v5_enabled=false
	add_child(game);await settle(12)
	game.set_process(false);game.set_physics_process(false)
	game.onboarding_enabled=false;game.tutorial_gate_enabled=false;game.tutorial_manager.active=false;game.story_feature_enabled=false
	game.story_director.cancel_active_scene();game.onboarding_dialogue_queue.clear()
	GameState.day=7;GameState.mana=5000
	game.combat_scene.start_combat();await settle()
	game.combat_scene.set_pause_state(true,false)
	for unit in game.monster_units+game.enemy_units: unit.set_physics_process(false)
	for unit in game.monster_units:
		if str(unit.unit_id)=="slime": selected=unit;break
	expect(selected!=null,"actual selected slime exists")
	if not capture: await interactions()
	game.combat_scene.set_pause_state(true,false)
	var serial:=0
	for size in [Vector2i(1920,1080),Vector2i(1280,720)]:
		get_window().size=size;await settle()
		for locale in ["ko","en","zh_CN"]:
			LanguageSettings.set_locale(locale,false)
			for touch in [UISettings.is_touch_ui()]:
				if locale=="ko" and size.x==1920 and not touch:
					game.selected_unit=null; game.hud.combat_workspace.tactics_open=false
					await rebuild(); await inspect("ko_1920_mouse_default",capture)
				game.selected_unit=selected;game.hud.combat_workspace.tactics_open=false
				await rebuild()
				var id:="%s_%d_%s_selected"%[locale,size.x,"touch" if touch else "mouse"]
				await inspect(id,capture and ((size.x==1920 and locale=="ko" and not touch) or (size.x==1280 and locale in ["ko","zh_CN"] and touch)))
				game.hud.combat_workspace.tactics_open=true;await rebuild()
				await inspect(id+"_policy",capture and size.x==1920 and locale=="en" and not touch)
				serial+=1
	# Highest-pressure instant-action strip and floor notifications use existing data.
	game.hud.combat_workspace.tactics_open=false
	game.update3_active_run["heart"]={"heart_id":"stonebone","awakened":true,"charge":100}
	var links: Array=DataRegistry.update3_duo_links.keys()
	game.update3_active_run["equipped_duo_links"]=links.slice(0,2)
	game.update3_active_run["duo_link_states"]={}
	for id in links.slice(0,2): game.update3_active_run.duo_link_states[id]={"active":true,"charge":100}
	await rebuild(); await inspect("special_actions")
	expect(control("CombatHeartActivate")!=null and control("CombatDuoActivate_0")!=null,"heart and duo remain immediate actions")
	game.update3_active_run.clear()
	if UISettings.is_touch_ui():
		game.update4_active_run={"campaign_mode_id":"council_season","upper_floor":{"unlocked":true,"layout_id":"upper_compact_guard","graph_runtime":{"visible_floor":"1F","entities":{"test_enemy":{"alive":true,"faction":"enemy","floor_id":"2F"}}}}}
		await rebuild()
		var floor_hud=control("MultiFloorHUD")
		expect(floor_hud!=null and floor_hud.alert_panel.visible,"hidden-floor alert visible with production HUD")
		await inspect("zh_CN_1280_touch_floor")
		expect(not floor_hud.alert_panel.get_global_rect().intersects(control("CombatUnitInspector").get_global_rect()),"floor alert avoids selected detail")
	else:
		get_window().size=Vector2i(1920,1080);LanguageSettings.set_locale("ko",false)
		await rebuild();game.combat_scene.set_pause_state(false,false);UISettings.skill_cutscene_policy="always"
		var presentation=game.combat_scene.skill_actions
		presentation.request({"key":"u5c_capture","name":LanguageSettings.ui_text("점액 방패"),"actors":[selected],"kind":"skill"},func(): return true)
		presentation.stage.set_process(false);presentation.tick(0.3)
		await inspect("ko_1920_mouse_cutscene",capture)
		presentation.skip()
	var result:={"checks":checks,"failures":failures,"screens":screens,"captures":capture_paths}
	var file:=FileAccess.open(out.path_join("result.json"),FileAccess.WRITE);file.store_string(JSON.stringify(result,"\t"));file.close()
	game.queue_free();await settle()
	print("U5-C checks=%d failures=%d captures=%d"%[checks,failures.size(),capture_paths.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
