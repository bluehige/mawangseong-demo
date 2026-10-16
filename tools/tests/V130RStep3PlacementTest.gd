extends Node
const Model = preload("res://scripts/map_builder/ApprovedMonsterPlacement.gd")
const Buildings = preload("res://scripts/map_builder/ApprovedPlacement.gd")
const OUT := "res://tmp/v130r_step3/"
var failures: Array[String] = []
var checks := 0
var preview: Node
var view: Control
var ui: Node
var metrics := {}
func expect(ok: bool, what: String) -> void:
	checks += 1
	if not ok: failures.append(what); print("FAIL ",what)
func _ready() -> void: call_deferred("run")
func settle() -> void:
	await get_tree().create_timer(.25).timeout
	for i in range(3): await get_tree().process_frame
func boot() -> void:
	preview = load("res://scenes/map_builder/ApprovedPlacementPreview.tscn").instantiate()
	add_child(preview); await settle()
	get_window().size = Vector2i(1920,1080); await settle()
	view = preview.game.ui_layer.get_node("ApprovedMapManagement"); ui = view.monster_ui
func stop_preview() -> void:
	preview.game.campaign_autosave_pending = false; preview.game._shutdown_audio_for_exit()
	preview.queue_free(); await get_tree().process_frame
func direct() -> void:
	var members: Dictionary = ui.members; var ids: Array = members.keys()
	var layout: Dictionary = view.baseline; var targets := []
	for b in layout.defense_points:
		for slot in range(layout.defense_points[b].size()): targets.append({"building":b,"slot":slot})
	expect(members.size()==14,"14 unique individual members")
	var expected_cost := {"푸딩":1,"곱":1,"핀":1,"로로":1,"모리":2,"두둠":2,"베베":2,"포포":2,"실키":2,"돌콩":3,"미미":3,"루미":3,"코코":3,"톡톡":3}
	for id in members:
		expect(members[id].upkeep==expected_cost[members[id].display_name],"design upkeep "+id)
		expect(ResourceLoader.exists(ui.portrait(id)),"GPT portrait "+id)
		expect(members[id].equipped_skill_ids.size()>=2,"skills "+id)
	ui.unlock_all = false
	expect(ui.unlocked().size()==4,"unjoined monsters locked")
	expect(not Model.available(members["mon_contract_mori"],30,false,[]),"existing contract is not day auto recruitment")
	var locked := Model.put(layout,{},"mon_contract_mori",targets[0],members,ui.unlocked())
	expect(not locked.ok,"locked member cannot deploy")
	ui.unlock_all = true
	var a: Dictionary = Model.put(layout,{},ids[0],targets[0],members,ids).assignments
	a = Model.put(layout,a,ids[1],targets[1],members,ids).assignments
	var swap := Model.put(layout,a,ids[0],targets[1],members,ids)
	expect(swap.assignments[ids[1]]==targets[0] and swap.assignments[ids[0]]==targets[1],"occupied slots swap")
	var invalid := {"building":targets[0].building,"slot":layout.defense_points[targets[0].building].size()}
	expect(not Model.put(layout,a,ids[2],invalid,members,ids).ok,"over capacity rejected")
	expect(not Model.put(layout,a,ids[2],{"building":"missing","slot":0},members,ids).ok,"unknown building rejected")
	var removed: Dictionary = Model.put(layout,a,ids[0],{},members,ids).assignments
	expect(not removed.has(ids[0]) and removed.has(ids[1]),"outside removes only dragged member")
	var from_roster: Dictionary = Model.put(layout,a,ids[2],targets[0],members,ids).assignments
	expect(from_roster.size()==2 and not from_roster.has(ids[0]),"roster replacement returns displaced member")
	for limit in [0,1,15,23,30]:
		var auto := Model.auto_place(layout,members,ids,limit)
		expect(Model.upkeep(auto,members)<=limit,"auto respects income "+str(limit))
		if limit==23:
			expect(auto.has("mon_contract_mimi") and auto["mon_contract_mimi"].building=="bait_treasure","auto covers decoy role within income")
			expect(auto.has("mon_contract_mori") and auto["mon_contract_mori"].building=="recovery_nest","auto covers healer role")
		var used := {}
		for id in auto:
			var c := Model.cell(layout,auto[id]); expect(not used.has(c),"one member per cell"); used[c] = true
			var b := Buildings.building(layout,auto[id].building)
			expect(b.kind in Model.preferences(members[id].species_id),"role recommendation "+id)
		for b in layout.buildings:
			var count := 0
			for target in auto.values():
				if target.building==b.id: count += 1
			expect(count<=b.capacity,"capacity "+b.id)
	view.placement = layout.duplicate(true); ui.assignments = Model.auto_place(layout,members,ids,23)
	var saved: Dictionary = ui.assignments.duplicate(true)
	expect(ui.persist()==OK,"test copy saved")
	var loaded := Model.load_copy(layout,members)
	expect(loaded.defenders==saved,"JSON save round trip")
	expect(Buildings.snapshot(loaded.layout)==Buildings.snapshot(layout),"layout round trip")
	await stop_preview(); await boot()
	expect(ui.assignments==saved,"actual preview reopening retains assignments")
	ui.unlock_all = true; ui.set_mode("place"); ui.clear_all()
	expect(ui.assignments.is_empty() and Model.upkeep(ui.assignments,members)==0,"clear all removes upkeep")
	ui.auto_place()

func mouse(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new(); event.position = point; event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
	get_viewport().push_input(event,true); await get_tree().process_frame
func move_mouse(point: Vector2) -> void:
	var event := InputEventMouseMotion.new(); event.position = point; event.global_position = point
	get_viewport().push_input(event,true); await get_tree().process_frame
func shot(name: String) -> void:
	await settle(); await RenderingServer.frame_post_draw
	var im := get_viewport().get_texture().get_image()
	expect(im.get_size()==Vector2i(1920,1080),"real 1920x1080 "+name)
	expect(im.save_png(OUT+name+".png")==OK,"saved "+name)
func capture() -> void:
	view.placement = view.baseline.duplicate(true); ui.assignments.clear(); view.render_map()
	ui.unlock_all = true; ui.set_mode("build"); await settle()
	await mouse(Vector2(960,55),true)
	await mouse(Vector2(960,55),false); await settle()
	expect(ui.mode=="place","actual placement tab click")
	await mouse(view.screen_cell(Vector2(12.5,3.5)),true)
	await mouse(view.screen_cell(Vector2(12.5,3.5)),false); await settle()
	expect(view.selected_id=="","placement mode does not open construction radial")
	await shot("place_01_roster")
	var id := "mon_core_pudding"
	var target := {"building":"barracks","slot":0}
	var point: Vector2 = view.screen_cell(Vector2(Model.cell(view.placement,target))+Vector2(.5,.5))
	await mouse(ui.cards[id].get_global_rect().get_center(),true)
	await move_mouse(point-Vector2(15,15))
	expect(ui.drag_started and ui.ghost.visible,"actual card drag begins")
	await shot("place_02_drag")
	await move_mouse(point); await mouse(point,false); await settle()
	expect(ui.assignments.get(id,{})==target,"actual card drop deploys individual")
	await shot("place_03_placed")
	var click_point: Vector2 = ui.unit_rect(id).get_center()*view.ui_unit
	await mouse(click_point,true); await mouse(click_point,false); await settle()
	expect(ui.selected==id and ui.detail.get_child_count()>0,"actual placed monster click opens info")
	var near: Rect2 = ui.unit_rect(id)
	var panel := Rect2(ui.detail.position,Vector2(400,324))
	expect(near.get_center().distance_to(near.get_center().clamp(panel.position,panel.end))<180,"info adjacent to monster")
	metrics.info = {"monster":[near.position.x,near.position.y,near.size.x,near.size.y],"panel":[panel.position.x,panel.position.y,panel.size.x,panel.size.y]}
	await shot("place_04_info")
	await mouse(ui.roster_panel.get_node("place_auto").get_global_rect().get_center(),true)
	await mouse(ui.roster_panel.get_node("place_auto").get_global_rect().get_center(),false); await settle()
	expect(Model.upkeep(ui.assignments,ui.members)<=23,"actual auto button income")
	await shot("place_05_auto")
	ui.clear_all()
	# Manual placements intentionally exceed the daily income, but remain allowed.
	for member in ui.members:
		var done := false
		for b in view.placement.defense_points:
			for slot in range(view.placement.defense_points[b].size()):
				var t := {"building":b,"slot":slot}
				if Model.occupant(ui.assignments,t)!="": continue
				ui.apply_drop(member,t); done = true; break
			if done: break
	expect(ui.assignments.size()==14,"all fourteen individually placeable")
	expect(ui.warning.visible and Model.upkeep(ui.assignments,ui.members)>23,"manual over income shows hunger warning")
	await shot("place_06_food_warn")
	for member in ui.assignments:
		ui.show_info(member)
		expect(ui.detail.get_child_count()>=13,"all individual info contents "+member)
		var height := 386 if ui.members[member].equipped_skill_ids.size()>2 else 324
		expect(ui.detail.position.y+height<866,"info avoids roster "+member)
	ui.close_info()
	# Actual map-to-map drag swaps; actual outside drag removes the selected unit.
	var first := "mon_core_pudding"; var second := "mon_core_gob"
	var old: Dictionary = ui.assignments[first].duplicate()
	var destination: Dictionary = ui.assignments[second].duplicate()
	await mouse(ui.unit_rect(first).get_center()*view.ui_unit,true)
	var dest: Vector2 = view.screen_cell(Vector2(Model.cell(view.placement,destination))+Vector2(.5,.5))
	await move_mouse(dest); await mouse(dest,false); await settle()
	expect(ui.assignments.get(first,{})==destination and ui.assignments.get(second,{})==old,"actual map drag swaps")
	await mouse(ui.unit_rect(first).get_center()*view.ui_unit,true)
	await move_mouse(Vector2(80,140)); await mouse(Vector2(80,140),false); await settle()
	expect(not ui.assignments.has(first),"actual outside drag removes unit")
	await mouse(ui.roster_panel.get_node("place_clear_all").get_global_rect().get_center(),true)
	await mouse(ui.roster_panel.get_node("place_clear_all").get_global_rect().get_center(),false); await settle()
	expect(ui.assignments.is_empty(),"actual clear all icon")
	await mouse(Vector2(770,55),true); await mouse(Vector2(770,55),false); await settle()
	expect(ui.mode=="build" and ui.build_bar.visible and not ui.roster_panel.visible,"actual switch back to construction")
	await mouse(Vector2(1150,55),true); await mouse(Vector2(1150,55),false); await settle()
	expect(ui.mode=="build","combat tab remains inactive")
	view.select_building("barracks"); await settle()
	expect(view.radial.get_child_count()==5,"construction actions retained after tab round trip")
	ui.set_mode("place")
	ui.auto_place(); ui.persist()
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var prior := FileAccess.get_file_as_bytes(Buildings.SAVE_PATH) if FileAccess.file_exists(Buildings.SAVE_PATH) else PackedByteArray()
	await boot()
	if OS.get_cmdline_user_args().has("--capture"): await capture()
	else: await direct()
	expect(prior==(FileAccess.get_file_as_bytes(Buildings.SAVE_PATH) if FileAccess.file_exists(Buildings.SAVE_PATH) else PackedByteArray()),"preceding test save unchanged")
	await stop_preview()
	var mode := "capture" if OS.get_cmdline_user_args().has("--capture") else "direct"
	var result := {"result":"TARGETED_PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures,"metrics":metrics}
	var file := FileAccess.open(OUT+mode+"_result.json",FileAccess.WRITE); file.store_string(JSON.stringify(result,"\t")); file.close()
	print("V130RStep3PlacementTest ",result)
	get_tree().quit(0 if failures.is_empty() else 1)
