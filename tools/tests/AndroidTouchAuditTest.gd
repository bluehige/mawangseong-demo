extends Node
## Measurement only. Synthetic navigation fixtures never change product UI or saves.
const Game = preload("res://scenes/game/GameRoot.tscn")
const OUT := "res://tmp/android_audit/"
const TARGET := 128.0
const GAP := 20.0
const CAPTURE_IDS := ["title", "settings_general", "dialogue", "management_build", "placement_preview", "decoration", "monster", "combat_selected", "result", "defeat", "chronicle_0", "council_management"]
var game
var screens: Array = []
var failures: Array[String] = []
var checks := 0
var captures: Array[String] = []

func _ready() -> void: call_deferred("run")

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func settle(count: int = 8) -> void:
	for i in range(count): await get_tree().process_frame

func write_json(path: String, value: Variant) -> void:
	var file := FileAccess.open(OUT + path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "\t")); file.close()

func rect_array(rect: Rect2) -> Array:
	return [snappedf(rect.position.x,0.01),snappedf(rect.position.y,0.01),snappedf(rect.size.x,0.01),snappedf(rect.size.y,0.01)]

func physical_transform(item: CanvasItem) -> Transform2D:
	return get_viewport().get_stretch_transform() * item.get_global_transform_with_canvas()

func clipped_rect(c: Control) -> Rect2:
	var rect := physical_transform(c) * Rect2(Vector2.ZERO,c.size)
	rect = rect.intersection(Rect2(Vector2.ZERO,Vector2(get_window().size)))
	var parent := c.get_parent()
	while parent != null:
		if parent is Control and parent.clip_contents:
			rect = rect.intersection(physical_transform(parent) * Rect2(Vector2.ZERO,parent.size))
		parent = parent.get_parent()
	return rect

func input_kind(c: Control) -> String:
	if c is BaseButton: return "button"
	if c is Slider: return "slider"
	if c is ScrollBar: return "scrollbar"
	if c is ScrollContainer: return "scroll_container"
	if c is TabBar: return "tab_bar"
	if c is LineEdit: return "line_edit"
	if c is TextEdit: return "text_edit"
	if c is RichTextLabel and not c.get_signal_connection_list("meta_clicked").is_empty(): return "richtext_link"
	if c.mouse_filter == Control.MOUSE_FILTER_STOP:
		if not c.get_signal_connection_list("gui_input").is_empty(): return "stop_gui_input"
		var script = c.get_script()
		while script != null:
			for method in script.get_script_method_list():
				if method.name == "_gui_input": return "stop_gui_input"
			script = script.get_base_script()
		return "stop_candidate"
	return ""

func text_sizes(c: Control) -> Array:
	var sizes: Array = []
	if c is RichTextLabel:
		# Theme resolution already includes text_scale, touch overrides and inheritance.
		var keys := ["normal_font_size"]
		if c.bbcode_enabled:
			for pair in [["[b]","bold_font_size"],["[i]","italics_font_size"],["[code]","mono_font_size"]]:
				if pair[0] in c.text: keys.append(pair[1])
		for key in keys:
			var value := c.get_theme_font_size(key)
			if not sizes.has(value): sizes.append(value)
		if c.bbcode_enabled:
			var regex := RegEx.new(); regex.compile("\\[font_size=(\\d+)\\]")
			for match_value in regex.search_all(c.text):
				var value := int(match_value.get_string(1))
				if not sizes.has(value): sizes.append(value)
	else: sizes.append(c.get_theme_font_size("font_size"))
	return sizes

func collect(node: Node, controls: Array, labels: Array, tooltips: Array, stops: Array) -> void:
	if node is CanvasItem and (not node.is_visible_in_tree() or node.get_modulate().a <= 0): return
	if node is Control:
		var c := node as Control
		var visible := clipped_rect(c)
		if visible.has_area() and c.self_modulate.a > 0:
			var full := physical_transform(c) * Rect2(Vector2.ZERO,c.size)
			var value := ""
			if c is Label or c is BaseButton or c is LineEdit: value = str(c.get("text"))
			if c is RichTextLabel: value = c.get_parsed_text()
			var record := {"path":str(game.get_path_to(c)),"name":str(c.name),"type":c.get_class(),"text":value,"rect_px":rect_array(full),"visible_rect_px":rect_array(visible),"clipped":not full.is_equal_approx(visible),"tooltip":c.tooltip_text,"mouse_filter":c.mouse_filter}
			if c.get_script() != null: record["script"] = c.get_script().resource_path
			var kind := input_kind(c)
			if kind != "":
				var row := record.duplicate(true)
				row["kind"] = kind
				row["disabled"] = (c is BaseButton and c.disabled) or (c is Slider and not c.editable) or (c is LineEdit and not c.editable)
				row["below_target"] = visible.size.x < TARGET or visible.size.y < TARGET
				row["size_mm"] = [snappedf(visible.size.x*0.063,0.01),snappedf(visible.size.y*0.063,0.01)]
				if kind == "stop_candidate": stops.append(row)
				else: controls.append(row)
			if not value.strip_edges().is_empty() and (c is Label or c is RichTextLabel or c is BaseButton or c is LineEdit):
				var row := record.duplicate(true)
				var sizes := text_sizes(c)
				var transform := physical_transform(c)
				var scale_y := transform.y.length()
				var rendered: Array = []
				for size_value in sizes: rendered.append(snappedf(float(size_value)*scale_y,0.01))
				row["theme_font_sizes"] = sizes
				row["font_px"] = rendered
				row["font_scale_y"] = scale_y
				row["below_minimum_30"] = rendered.min() < 30
				row["below_body_36"] = rendered.min() < 36
				row["label_required"] = c is Label or c is RichTextLabel
				labels.append(row)
			if c.tooltip_text != "": tooltips.append(record)
	for child in node.get_children(): collect(child,controls,labels,tooltips,stops)

func gap_between(a: Rect2, b: Rect2) -> float:
	var delta := Vector2(maxf(0,maxf(a.position.x-b.end.x,b.position.x-a.end.x)),maxf(0,maxf(a.position.y-b.end.y,b.position.y-a.end.y)))
	return delta.length()

func from_array(a: Array) -> Rect2: return Rect2(a[0],a[1],a[2],a[3])

func measure_gaps(controls: Array) -> Array:
	var pairs: Array = []
	for i in range(controls.size()):
		var nearest := INF
		var neighbor := ""
		for j in range(controls.size()):
			if i == j: continue
			var a: Dictionary = controls[i]; var b: Dictionary = controls[j]
			# A scrollbar inside a scroll container is not a neighboring action.
			if str(a.path).begins_with(str(b.path)+"/") or str(b.path).begins_with(str(a.path)+"/"): continue
			var distance := gap_between(from_array(a.visible_rect_px),from_array(b.visible_rect_px))
			if distance < nearest: nearest = distance; neighbor = b.path
			if j > i and distance < GAP: pairs.append({"a":a.path,"b":b.path,"gap_px":snappedf(distance,0.01),"overlap":from_array(a.visible_rect_px).intersects(from_array(b.visible_rect_px))})
		controls[i]["nearest_gap_px"] = snappedf(nearest,0.01) if nearest != INF else null
		controls[i]["nearest_neighbor"] = neighbor
	return pairs

func world_targets() -> Array:
	var targets: Array = []
	if game.current_screen not in ["management","combat"]: return targets
	var transform := physical_transform(game)
	var view := Rect2(Vector2.ZERO,Vector2(get_window().size))
	if game.current_screen == "management":
		for id in game._defense_monster_ids():
			var point: Vector2 = game._management_monster_preview_position(id)
			if point == Vector2.INF: continue
			var radius := 104.0 if UISettings.is_touch_ui() else 48.0
			var rect := transform * Rect2(point-Vector2.ONE*radius,Vector2.ONE*radius*2)
			if not rect.intersects(view): continue
			targets.append({"id":"unit:"+id,"shape":"circle","radius_world":radius,"radius_px":radius*transform.x.length(),"rect_px":rect_array(rect),"visible_rect_px":rect_array(rect.intersection(view)),"source":"GameRoot._management_monster_at"})
	else:
		for unit in game.monster_units+game.enemy_units:
			if not is_instance_valid(unit) or not unit.is_alive() or not unit.is_targetable_by(): continue
			var radius := 96.0 if UISettings.is_touch_ui() else 36.0
			var rect := transform*Rect2(unit.global_position-Vector2.ONE*radius,Vector2.ONE*radius*2)
			if not rect.intersects(view): continue
			targets.append({"id":unit_key(unit),"unit_type":str(unit.unit_id),"shape":"circle","radius_world":radius,"radius_px":radius*transform.x.length(),"rect_px":rect_array(rect),"visible_rect_px":rect_array(rect.intersection(view)),"source":"GameRoot._unit_at"})
			if unit.faction == "enemy":
				var half := Vector2(96,110) if UISettings.is_touch_ui() else Vector2(52,70)
				var command_rect := transform*Rect2(unit.global_position-half,half*2)
				targets.append({"id":"enemy_command:"+unit_key(unit).trim_prefix("unit:"),"shape":"rect","rect_px":rect_array(command_rect),"visible_rect_px":rect_array(command_rect.intersection(view)),"source":"GameRoot._enemy_at"})
	# The room picker is nearest-cell fallback, not a fixed circle. Record actual
	# room floor bounds AND sample the live picker with UI/unit priority applied.
	for id in game.rooms:
		var rect: Rect2 = transform*game.graph.rect(id)
		if rect.intersects(view): targets.append({"id":"room:"+id,"shape":"room_floor_bounds_with_nearest_cell_fallback","rect_px":rect_array(rect),"visible_rect_px":rect_array(rect.intersection(view)),"source":"GameRoot._room_at / ModuleGraph.room_at_world","radius_px":null})
	for target in targets:
		var size_value := from_array(target.visible_rect_px).size
		target["below_target"] = size_value.x < TARGET or size_value.y < TARGET
	var unit_targets: Array = targets.filter(func(row): return row.shape == "circle")
	for target in unit_targets:
		var nearest := INF; var neighbor := ""
		var center := from_array(target.rect_px).get_center()
		for other in unit_targets:
			if other.id == target.id: continue
			var distance := maxf(0,center.distance_to(from_array(other.rect_px).get_center())-float(target.radius_px)-float(other.radius_px))
			if distance < nearest: nearest = distance; neighbor = other.id
		target["nearest_gap_px"] = nearest if nearest != INF else null
		target["nearest_neighbor"] = neighbor
	return targets

func unit_key(unit: Node) -> String:
	# unit_id identifies a species, so two explorers must retain separate pick regions.
	return "unit:"+str(unit.unit_id)+":"+str((game.monster_units+game.enemy_units).find(unit))

func sample_map_targets(targets: Array) -> Dictionary:
	const STEP := 8
	var rows: Dictionary = {}
	var previous: Array = []
	var transform := physical_transform(game).affine_inverse()
	var stretch_inverse := get_viewport().get_stretch_transform().affine_inverse()
	for y in range(STEP/2,get_window().size.y,STEP):
		var current: Array = []
		for x in range(STEP/2,get_window().size.x,STEP):
			var pixel := Vector2(x,y)
			var viewport_point := stretch_inverse*pixel
			var blocked: bool = game._management_ui_at(viewport_point) if game.current_screen=="management" else game._combat_ui_at(viewport_point)
			var id := ""
			if not blocked:
				var world := transform*pixel
				if game.current_screen=="management":
					var unit_id: String = game._management_monster_at(world)
					id = "unit:"+unit_id if unit_id!="" else "room:"+game._room_at(world)
				else:
					var unit = game._unit_at(world)
					id = unit_key(unit) if unit!=null else "room:"+game._room_at(world)
			var square := 1
			var column := current.size()
			if column>0 and not previous.is_empty() and id!="" and current[column-1][0]==id and previous[column][0]==id and previous[column-1][0]==id:
				square += mini(current[column-1][1],mini(previous[column][1],previous[column-1][1]))
			current.append([id,square])
			if id == "": continue
			if not rows.has(id): rows[id] = {"samples":0,"bounds":Rect2(pixel-Vector2.ONE*STEP/2,Vector2.ONE*STEP),"largest_square_px":0}
			rows[id].samples += 1
			rows[id].bounds = rows[id].bounds.merge(Rect2(pixel-Vector2.ONE*STEP/2,Vector2.ONE*STEP))
			rows[id].largest_square_px = maxi(rows[id].largest_square_px,square*STEP)
		previous = current
	for target in targets:
		if target.id.begins_with("enemy_command:"): continue
		var value: Dictionary = rows.get(target.id,{})
		target["reachable_samples"] = value.get("samples",0)
		target["reachable_bounds_px"] = rect_array(value.bounds) if value.has("bounds") else []
		target["reachable_square_px"] = value.get("largest_square_px",0)
	for id in rows: rows[id].bounds = rect_array(rows[id].bounds)
	return {"step_px":STEP,"rows":rows,"note":"8px center-sampled largest axis-aligned square; approximate, not a continuous inscribed-square proof. UI and nearest unit precedence applied. Room fallback can extend outside floor."}

func audit(id: String, provenance: String, sample_map: bool = false) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	var controls: Array = []; var labels: Array = []; var tooltips: Array = []; var stops: Array = []
	collect(game,controls,labels,tooltips,stops)
	var targets := world_targets()
	var sample := sample_map_targets(targets) if sample_map else {}
	var entry := {"id":id,"screen":game.current_screen,"day":GameState.day,"provenance":provenance,"window_px":[get_window().size.x,get_window().size.y],"viewport_rect":str(get_viewport().get_visible_rect()),"stretch":str(get_viewport().get_stretch_transform()),"touch_ui":UISettings.is_touch_ui(),"controls":controls,"labels":labels,"tooltips":tooltips,"passive_stop_candidates":stops,"gap_pairs_below_20":measure_gaps(controls),"world_targets":targets,"map_sample":sample,"capture":""}
	if OS.get_cmdline_user_args().has("--capture") and id in CAPTURE_IDS:
		expect(captures.size()<20,"capture budget <=20")
		var path := OUT+id+".png"
		var image := get_viewport().get_texture().get_image()
		expect(image.get_size()==Vector2i(1920,1080),"capture pixel dimensions "+id)
		expect(image.save_png(path)==OK,"capture saved "+id)
		captures.append(path); entry.capture=path.trim_prefix("res://")
	elif FileAccess.file_exists(OUT+id+".png"):
		# Retain representative screenshots from the earlier capture run. Their
		# exact frame/state JSON remains archived; no extra GUI capture is created.
		entry.capture=(OUT+id+".png").trim_prefix("res://")
		entry["capture_reused"] = true
		captures.append(OUT+id+".png")
	expect(not controls.is_empty(),"screen contains input controls "+id)
	expect(not labels.is_empty(),"screen contains rendered text "+id)
	screens.append(entry)
	write_json(id+".json",entry)
	print("ANDROID_AUDIT ",id," controls=",controls.size()," text=",labels.size()," maps=",targets.size())

func show(screen: String) -> void:
	game._set_screen(screen,false); await settle()
	expect(game.current_screen==screen,"requested screen "+screen)

func require_control(id: String) -> void:
	var c := game.ui_layer.find_child(id,true,false) as Control
	expect(c!=null and c.is_visible_in_tree() and clipped_rect(c).has_area(),"required visible control "+id)

func open_result_details() -> void:
	var button = game.ui_layer.find_child("ResultDetailsButton",true,false)
	if button!=null: button.pressed.emit(); await settle()
	require_control("ResultDetailsClose")

func freeze_game() -> void:
	game.set_process(false); game.set_physics_process(false)
	game.onboarding_enabled=false; game.tutorial_gate_enabled=false; game.tutorial_manager.active=false
	game.story_feature_enabled=false; game.story_director.cancel_active_scene(); game.onboarding_dialogue_queue.clear()

func spawn() -> void:
	GameState.reset()
	game=Game.instantiate()
	for property in ["campaign_save_enabled","campaign_auxiliary_save_enabled","campaign_save_v4_enabled","campaign_save_v5_enabled","campaign_save_v6_enabled"]: game.set(property,false)
	add_child(game); await settle(); freeze_game()

func destroy() -> void:
	game.campaign_autosave_pending=false; game._shutdown_audio_for_exit()
	game.queue_free(); await settle()

func run() -> void:
	var user_path := ProjectSettings.globalize_path("user://").replace("\\","/")
	var out_path := ProjectSettings.globalize_path(OUT).replace("\\","/")
	if not user_path.begins_with(out_path) or DisplayServer.get_name()=="headless" or not UISettings.is_touch_ui():
		push_error("Requires graphical renderer, --mobile-touch-ui and isolated APPDATA under tmp/android_audit")
		get_tree().quit(2); return
	DirAccess.make_dir_recursive_absolute(out_path)
	get_window().size=Vector2i(1920,1080)
	Engine.max_fps=30
	LanguageSettings.set_locale("ko",false)
	UISettings.set_text_scale(1.0,false); UISettings.set_layout_mode("auto",false)
	expect(is_equal_approx(gap_between(Rect2(0,0,128,128),Rect2(148,0,128,128)),20),"measurement calibration: 20px edge gap")
	expect(is_equal_approx(gap_between(Rect2(0,0,128,128),Rect2(100,100,128,128)),0),"measurement calibration: overlap is zero gap")
	expect(is_equal_approx(gap_between(Rect2(0,0,128,128),Rect2(131,132,128,128)),5),"measurement calibration: diagonal 3-4-5 edge gap")
	await spawn()
	await show("title"); await audit("title","Fresh isolated title")
	await show("name_entry"); await audit("name_entry","Name entry navigation fixture; includes LineEdit")
	game._open_settings_screen(); await settle()
	for category in ["general","display","audio","accessibility","combat"]:
		game.settings_category=category; await show("settings")
		await audit("settings_"+category,"Settings category, initial scroll")
		var scroll := game.ui_layer.find_child("SettingsFieldsScroll",true,false) as ScrollContainer
		expect(scroll!=null,"settings scroll exists "+category)
		if scroll!=null:
			scroll.scroll_vertical=10000; await settle()
			await audit("settings_"+category+"_bottom","Same category, bottom scroll; repeated elements are intentional")
	game._cancel_settings_changes(); freeze_game()
	game.onboarding_dialogue_queue=[{"speaker":"CHR_GOLDIN","emotion":"accounting","text":"보상 정산 완료. 악명 +1, 골드 소량. 위엄은 장부상 무형자산입니다. 다음 방어 준비까지 확인하겠습니다."}]
	game.onboarding_dialogue_index=0
	await show("dialogue"); await audit("dialogue","Existing onboarding dialogue presenter with representative line")
	game.onboarding_dialogue_queue.clear()
	game.management_scene.workspace_ui.tools_expanded=true; game.management_tool_tab="build"
	await show("management"); await audit("management_build","DAY1 initial build palette",true)
	var cards := game.ui_layer.find_child("BuildingCardScroll",true,false) as ScrollContainer
	if cards!=null:
		cards.scroll_horizontal=10000; await settle()
		await audit("management_build_right","DAY1 build palette right edge")
	game._set_build_facility("watch_post"); await settle()
	game.build_placement.plot.update(game.graph.center("slot_01"),false)
	await audit("placement_preview","DAY1 placement ghost on existing build slot; no commit")
	game._cancel_management_action_mode()
	game.management_tool_tab="decor"; game.management_scene.workspace_ui.tools_expanded=true
	await show("management"); await audit("decoration","DAY1 decoration palette; no placement")
	game.management_tool_tab="roster"; await show("management")
	await audit("garrison","DAY1 garrison dock")
	game.management_tool_tab="tactics"; await show("management")
	await audit("management_tactics","DAY1 tactics and room directive")
	await show("monster"); await audit("monster","DAY1 monster management")
	game._open_chronicle(); await settle()
	for index in range(3):
		var chronicle = game.ui_layer.find_child("ChronicleScreen",true,false)
		if chronicle == null:
			for child in game.ui_layer.get_children():
				if child.get_script()!=null and child.get_script().resource_path.ends_with("ChronicleScreen.gd"): chronicle=child; break
		expect(chronicle!=null,"chronicle screen found")
		if chronicle!=null: chronicle._select_tab(index); await settle()
		await audit("chronicle_"+str(index),"Chronicle tab "+str(index)+", current profile")
	await show("ending_archive"); await audit("ending_archive","Ending record archive, current profile")
	await show("memory_archive"); await audit("memory_archive","Companion memory record, current profile")
	await destroy()
	await spawn()
	seed(1310)
	game.set_process(true); game.set_physics_process(true)
	game.combat_scene.start_combat()
	var deadline := Time.get_ticks_msec()+20000
	while game.combat_time<3.5 and Time.get_ticks_msec()<deadline:
		if game.combat_scene.skill_actions.is_active(): game.combat_scene.skill_actions.skip()
		await get_tree().physics_frame
	game.combat_scene.set_pause_state(true,false)
	game.set_process(false); game.set_physics_process(false)
	expect(game.enemy_units.size()>0,"real DAY1 combat spawns enemies")
	game.spectator_camera.set_process(false)
	game.combat_camera.position=game.monster_units[0].global_position+Vector2(20,-15)
	game._clear_combat_unit_selection(true); await settle()
	require_control("CombatMinimap"); require_control("V122_COMMAND_FOCUS"); require_control("CombatSpeed3x")
	await audit("combat_hud","Real DAY1 combat 3.5s, paused, initial HUD",true)
	game._select_unit(game.monster_units[0]); await settle()
	require_control("CombatUnitInspectorClose"); require_control("CombatRepresentativeSkill")
	await audit("combat_selected","Real first allied unit selected, actual inspector")
	game.hud.combat_workspace.inspector_details=true
	game.hud.combat_workspace.tactics_open=true
	await show("combat"); await audit("combat_tactics_details","Tactics and selected unit details expanded")
	var inspector_scroll := game.ui_layer.find_child("CombatUnitInspectorScroll",true,false) as ScrollContainer
	if inspector_scroll!=null:
		inspector_scroll.scroll_vertical=10000; await settle()
		await audit("combat_details_bottom","Selected unit details bottom scroll")
	game.result_summary={"win":true,"rewards":{"gold":20,"mana":10,"food":0,"infamy":1},"metrics":{"alive_monsters":3,"total_monsters":3},"v122_ledger":{"throne_damage":0,"breach_progress":0.0}}
	await show("result"); await audit("result","Synthetic victory summary, actual result builder")
	await open_result_details(); await audit("result_details","Victory detailed record overlay")
	game.result_summary={"win":false,"rewards":{"gold":0,"mana":0,"food":0,"infamy":0},"metrics":{"alive_monsters":1,"total_monsters":3},"v122_ledger":{"throne_damage":125,"breach_progress":0.8}}
	GameState.defeat=true
	await show("result"); await audit("defeat","Synthetic defeat summary, actual result builder")
	await open_result_details(); await audit("defeat_details","Defeat detailed record overlay")
	await destroy()
	await spawn()
	game.update4_active_run.campaign_mode_id="council_season"
	game.update4_active_run.council_season.selected_regions=["region_ironbell_ravine","region_moonbat_aerie","region_mistcap_marsh"]
	game.update4_active_run.council_season.current_region_index=0
	var outpost: Dictionary = preload("res://scripts/systems/outpost/OutpostService.gd").build(game.update4_profile,game.update4_active_run,"outpost_watch_nest",4,DataRegistry.update4_outpost_types)
	expect(outpost.ok,"council fixture satisfies earlier outpost prerequisite")
	game.update4_active_run=outpost.active_run
	GameState.day=16
	game.update4_active_run.council_season.day_state=preload("res://scripts/systems/campaign/CouncilSeasonService.gd").new_day_state(16)
	game.update4_active_run=preload("res://scripts/systems/council/CouncilExpansionService.gd").unlock_if_due(game.update4_active_run,16,DataRegistry.update4_expansion_modules,game._castle_stage_index())
	game._setup_dungeon_graph()
	game.management_tool_tab="build"; game.management_scene.workspace_ui.tools_expanded=true
	await show("management"); await audit("council_management","Council season DAY16 management, temporary 1F expansion fixture",true)
	await destroy()
	write_json("audit.json",{"schema_version":1,"base_sha":"9befdd2afc32bbf1f0a231bae5bd840b09d33cfe","engine":Engine.get_version_info(),"renderer":DisplayServer.get_name(),"user_dir":user_path,"criteria":{"touch_px":128,"gap_px":20,"body_font_px":36,"minimum_font_px":30,"mm_per_px":0.063},"settings":UISettings.snapshot(),"screens":screens,"captures":captures,"checks":checks,"failures":failures})
	print("AndroidTouchAuditTest ","PASS" if failures.is_empty() else "FAIL"," checks=",checks," screens=",screens.size()," captures=",captures.size()," failures=",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
