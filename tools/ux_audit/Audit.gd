extends Node
## Read-only product audit: synthetic state and engine input only; no product patches.
const OUT := "res://tmp/v1213_uiux_audit"
var game: Node
var busy := false
var last_command := ""
var captures: Array = []
var actions: Array = []

func _ready() -> void:
	call_deferred("start")

func start() -> void:
	var user_path := ProjectSettings.globalize_path("user://").replace("\\", "/")
	if not user_path.contains("/tmp/v1213_uiux_audit/") or DisplayServer.get_name() == "headless":
		push_error("UX audit requires isolated APPDATA and graphical rendering")
		get_tree().quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DisplayServer.window_set_size(Vector2i(1920,1080))
	DisplayServer.window_set_title("Mawangseong UX Audit - isolated")
	GameState.reset()
	LanguageSettings.set_locale("ko", false)
	if FileAccess.file_exists(OUT.path_join("actions.json")):
		actions = JSON.parse_string(FileAccess.get_file_as_string(OUT.path_join("actions.json")))
	if FileAccess.file_exists(OUT.path_join("command.json")):
		last_command = str(JSON.parse_string(FileAccess.get_file_as_string(OUT.path_join("command.json"))).get("id", ""))
	game = load("res://scenes/game/GameRoot.tscn").instantiate()
	game._set_campaign_save_path_for_tests("user://audit_campaign.json", "user://audit_campaign_v2.json", "user://audit_campaign_v3.json", "user://audit_campaign_v4.json", "user://audit_campaign_v5.json")
	add_child(game)
	await settle()
	game.set_process(false)
	game.set_physics_process(false)
	if not OS.get_cmdline_user_args().has("--resume-audit"):
		await capture("01_title_fresh", "Choose new game or continue", "fresh isolated boot")
	write_json("ready.json", {"user_dir":user_path,"renderer":DisplayServer.get_name(),"size":str(get_viewport().get_visible_rect())})

func _process(_delta: float) -> void:
	if busy or game == null: return
	var path := OUT.path_join("command.json")
	if not FileAccess.file_exists(path): return
	var command = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not command is Dictionary or str(command.get("id", "")) == last_command: return
	busy = true
	last_command = str(command.id)
	call_deferred("execute", command)

func settle(frames: int = 10) -> void:
	for i in range(frames): await get_tree().process_frame

func write_json(name: String, value: Variant) -> void:
	var file := FileAccess.open(OUT.path_join(name), FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "\t"))
	file.close()

func target(path: String) -> Variant:
	var obj: Variant = game
	if path == "GameState": return GameState
	if path == "UISettings": return UISettings
	if path == "LanguageSettings": return LanguageSettings
	for part in path.split(".", false):
		if part == "game": continue
		obj = obj.get(part)
	return obj

func execute(command: Dictionary) -> void:
	var results: Array = []
	for action in command.get("actions", []):
		var before: String = game.current_screen
		var result: Variant = null
		match str(action.op):
			"eval":
				var expression := Expression.new()
				var error := expression.parse(str(action.expr), PackedStringArray(["game"]))
				if error == OK:
					result = expression.execute([game], game, false)
					if expression.has_execute_failed(): result = {"error":expression.get_error_text()}
					elif result is Object: result = str(result)
				else: result = {"error":expression.get_error_text()}
			"call":
				var obj: Variant = target(str(action.get("target", "game")))
				result = obj.callv(str(action.method), action.get("args", []))
			"set":
				var obj: Variant = target(str(action.get("target", "game")))
				obj.set(str(action.property), action.value)
			"patch":
				var obj: Variant = target(str(action.get("target", "game")))
				for key in action.value: obj[key] = action.value[key]
			"click":
				var c: Control = game.ui_layer.find_child(str(action.name), true, false)
				if c == null or not c.is_visible_in_tree() or (c is BaseButton and c.disabled):
					result = {"error":"control missing, hidden or disabled", "name":action.name}
				else:
					var visible := effective_rect(c)
					if visible.has_area():
						await click_point(visible.get_center())
						result = {"name":action.name}
					else: result = {"error":"control clipped completely"}
			"click_text":
				var found: Control = null
				for c in game.ui_layer.find_children("*", "Button", true, false):
					if c.is_visible_in_tree() and c.text == str(action.text): found = c; break
				if found != null: await click_point(found.get_global_rect().get_center())
				else: result = {"error":"text button not found", "text":action.text}
			"point":
				await click_point(Vector2(action.x, action.y))
			"room":
				await click_point(game.get_global_transform_with_canvas() * game.graph.center(str(action.room)))
			"scroll":
				var c := game.ui_layer.find_child(str(action.name), true, false) as ScrollContainer
				if c != null: c.scroll_vertical = int(action.value)
				else: result = {"error":"scroll not found"}
			"capture":
				await capture(str(action.name), str(action.get("decision", "")), str(action.get("provenance", "synthetic UI state")))
			"wait": await settle(int(action.get("frames", 10)))
			"tick":
				for i in range(int(action.get("steps", 1))):
					game._physics_process(float(action.get("delta", 0.1)))
					game._process(float(action.get("delta", 0.1)))
					await get_tree().process_frame
			"freeze":
				game.set_process(false)
				game.set_physics_process(false)
			"unit":
				for unit in game.unit_root.get_children():
					if unit.get("unit_id") == str(action.id): game.selected_unit = unit; break
				game._set_screen(game.current_screen, false)
			"dump": result = dump_state()
			"quit":
				write_json("actions.json", actions)
				write_json("response.json", {"id":command.id,"results":results,"state":dump_state()})
				get_tree().quit()
				return
		await settle()
		var entry := {"op":action,"before":before,"after":game.current_screen,"tutorial":game.tutorial_manager.current_step_id(),"result":result}
		actions.append(entry)
		results.append(entry)
	write_json("actions.json", actions)
	write_json("response.json", {"id":command.id,"results":results,"state":dump_state()})
	busy = false

func click_point(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	get_viewport().push_input(motion, true)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = point
		event.global_position = point
		get_viewport().push_input(event,true)
		await get_tree().process_frame
	await settle()

func dump_state() -> Dictionary:
	var buttons: Array = []
	for c in game.ui_layer.find_children("*", "BaseButton", true, false):
		if c.is_visible_in_tree(): buttons.append({"name":str(c.name),"text":c.get("text"),"disabled":c.disabled,"rect":str(c.get_global_rect())})
	return {"screen":game.current_screen,"day":GameState.day,"tutorial":game.tutorial_manager.current_step_id(),"stage":game.onboarding_stage_id,"dialogue_index":game.onboarding_dialogue_index,"dialogue_count":game.onboarding_dialogue_queue.size(),"story_scene":game.story_director.current_scene_id,"story_cursor":game.story_director.cursor,"story_active":game.story_director.is_active(),"buttons":buttons}

func capture(name: String, decision: String, provenance: String) -> void:
	await settle()
	game.queue_redraw()
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image.get_size() != Vector2i(1920,1080):
		push_error("Capture size mismatch: " + str(image.get_size()))
		return
	image.save_png(OUT.path_join(name + ".png"))
	var controls: Array = []
	collect(game.ui_layer, controls)
	collect(game.effect_root, controls)
	var world: Array = []
	if game.current_screen == "combat":
		for info in game.combat_map_label_layouts:
			world.append({"text":info.text,"font_px":info.font_size,"rect":[info.rect.position.x,info.rect.position.y,info.rect.size.x,info.rect.size.y]})
	var entry := {"id":name,"decision":decision,"provenance":provenance,"screen":game.current_screen,"day":GameState.day,"controls":controls,"world_text":world,"state":dump_state(),"world_text_note":"Combat badge layouts are recorded; other custom draw strings and art-embedded text require source/visual supplement."}
	write_json(name + ".json",entry)
	captures.append(entry)
	write_json("captures.json", captures)
	print("UX_CAPTURE " + name + " controls=" + str(controls.size()))

func collect(node: Node, result: Array) -> void:
	if node is Control:
		var c := node as Control
		if not c.is_visible_in_tree(): return
		var rect: Rect2 = c.get_global_transform_with_canvas() * Rect2(Vector2.ZERO,c.size)
		var visible := effective_rect(c)
		var parent := c.get_parent()
		var clip_parent := ""
		while parent != null:
			if parent is Control and parent.clip_contents:
				visible = visible.intersection(parent.get_global_rect())
				clip_parent = str(parent.name)
			parent = parent.get_parent()
		if visible.has_area():
			var text := ""
			if c is Label or c is Button or c is LineEdit: text = c.text
			elif c is RichTextLabel: text = c.get_parsed_text()
			var fs := c.get_theme_font_size("normal_font_size" if c is RichTextLabel else "font_size")
			var record := {"path":str(c.get_path()),"name":str(c.name),"type":c.get_class(),"text":text,"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"visible_rect":[visible.position.x,visible.position.y,visible.size.x,visible.size.y],"font_px":fs,"tooltip":c.tooltip_text,"button":c is BaseButton,"disabled":c.disabled if c is BaseButton else false,"clipped":visible.size.distance_to(rect.size)>1,"clip_parent":clip_parent,"min_size":[c.get_minimum_size().x,c.get_minimum_size().y],"z":c.z_index}
			if c is Label:
				record["line_count"] = c.get_line_count()
				record["visible_lines"] = c.get_visible_line_count()
				record["autowrap"] = c.autowrap_mode
				var font := c.get_theme_font("font")
				record["line_height"] = font.get_height(fs)
			result.append(record)
	for child in node.get_children(): collect(child,result)

func effective_rect(c: Control) -> Rect2:
	var visible: Rect2 = (c.get_global_transform_with_canvas() * Rect2(Vector2.ZERO,c.size)).intersection(Rect2(0,0,1920,1080))
	var parent := c.get_parent()
	while parent != null:
		if parent is Control and parent.clip_contents: visible = visible.intersection(parent.get_global_transform_with_canvas() * Rect2(Vector2.ZERO,parent.size))
		parent = parent.get_parent()
	return visible
