extends Node
const Geometry = preload("res://scripts/map_builder/ApprovedPlacementLayout.gd")
const Glow = preload("res://scripts/ui/TutorialButtonGlow.gd")
const Tooltip = preload("res://scripts/ui/kit/KitTooltip.gd")
var game: Node
var checks := 0
var failures: Array[String] = []
var metrics := []
const OUT := "res://tmp/v131_ui/"

func _ready() -> void: run.call_deferred()
func frames(n: int = 5) -> void:
	for i in n: await get_tree().process_frame
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); print("FAIL ",message)
func view() -> Node: return game.ui_layer.get_node_or_null("ApprovedMapManagement")
func click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		get_viewport().push_input(event,true)
		await frames(2)

func run() -> void:
	get_window().content_scale_size = Vector2i.ZERO
	for flag in ["1","2","5","6","7","10"]: ProjectSettings.set_setting("debug/approved_map_step"+flag,true)
	ProjectSettings.set_setting("debug/start_flow14",true)
	LanguageSettings.set_locale("ko",false)
	game = load("res://scenes/game/GameRoot.tscn").instantiate()
	add_child(game); await frames(10)
	game._onboarding_reset_game()
	game.start_flow.fresh = true; game.start_flow.intro_complete = true
	game.start_flow.command_seen = true
	game._set_screen("management",false); await frames(8)
	var initial := view()
	game.start_flow.guide_step = 1; game.start_flow.guide_key = ""; await frames(5)
	var next: Control = game.ui_layer.find_child("StartGuideNext",true,false)
	expect(next != null and next.has_node("TutorialButtonGlow"),"landmark acknowledgement glows")
	await click(next)
	expect(game.start_flow.guide_step >= 2,"acknowledgement advances")
	var original: Array = initial.placement.buildings.duplicate(true)
	initial.placement.buildings = original.filter(func(b): return b.fixed)
	game.start_flow.guide_step = 2; game.start_flow.guide_key = ""; await frames(5)
	expect(initial.chrome.find_child("BuildTab",true,false).has_node("TutorialButtonGlow"),"build tab glows")
	expect(initial.palette_buttons.barracks.has_node("TutorialButtonGlow"),"build palette action glows")
	await click(initial.palette_buttons.barracks)
	expect(not initial.palette_buttons.barracks.get_node("TutorialButtonGlow").visible,"build selection switches glow off")
	initial.cancel_build(); initial.placement.buildings = original
	game.start_flow.set_process(false)
	game.start_flow.show_guide(initial,"command",game.start_flow.text("commands"),Rect2(600,580,900,330),game.start_flow.ack_commands)
	await frames(3)
	next = game.ui_layer.find_child("StartGuideNext",true,false)
	expect(next.has_node("TutorialButtonGlow"),"command acknowledgement glows")
	await click(next)
	expect(game.start_flow.command_seen and not is_instance_valid(game.start_flow.guide),"command acknowledgement switches guidance off")
	game.start_flow.set_process(true)
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440)]:
		get_window().size = resolution
		await frames(12)
		var v := view()
		var layout: Dictionary = v.ui_rects
		expect(v.size == Vector2(resolution),"actual viewport "+str(resolution))
		for a in ["hud","tabs","tools"]:
			for b in ["hud","tabs","tools"]:
				if a != b: expect(not layout[a].intersects(layout[b]),"top separation "+a+"/"+b)
		var place: Control = v.chrome.find_child("PlaceTab",true,false)
		expect(place.size == Vector2(240,96),"enlarged visible/click rect")
		game.start_flow.guide_step = 3; game.start_flow.guide_key = ""; await frames(5)
		expect(place.has_node("TutorialButtonGlow"),"placement guidance lights actual tab")
		var glow: Control = place.get_node("TutorialButtonGlow")
		var alpha: float = glow.modulate.a
		await get_tree().create_timer(0.22).timeout
		expect(not is_equal_approx(alpha,glow.modulate.a),"visible pulse changes opacity")
		await click(place)
		expect(v.monster_ui.mode == "place","visible tab accepts actual mouse input")
		expect(not is_instance_valid(glow) or not glow.visible,"glow dismisses after click")
		v.monster_ui.auto_place(); await frames(6)
		expect(game.start_flow.guide_step == 4,"real three companions advance guidance")
		expect(v.chrome.find_child("ApprovedDayAction",true,false).has_node("TutorialButtonGlow"),"battle step lights battle")
		v.select_building("barracks"); v.show_info("menu_info"); await frames(5)
		expect(v.info.get_meta("content_height") == 162.0,"short building info fits content")
		v.clear_context()
		metrics.append({"resolution":str(resolution),"tabs":str(layout.tabs),"viewport":str(v.size)})
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var image := get_viewport().get_texture().get_image()
			expect(image.get_size() == resolution,"render dimensions")
			image.resize(960,540,Image.INTERPOLATE_LANCZOS)
			image.save_png(OUT+"layout-%dx%d.png" % [resolution.x,resolution.y])
		v.monster_ui.clear_all()
	# Every currently available information card, including three locales, stays bounded.
	game.start_flow.clear_guide(); game.start_flow.fresh = false
	var v := view()
	v.monster_ui.set_mode("place")
	for locale in ["ko","en","zh_CN"]:
		LanguageSettings.set_locale(locale,false)
		for id in v.monster_ui.members:
			v.monster_ui.show_info(id)
			await frames(2)
			expect(v.monster_ui.info_height >= 324 and v.monster_ui.info_height <= 740,"bounded monster information "+str(id))
			for child in v.monster_ui.detail.get_children():
				if child is Control: expect(child.position.y+child.size.y <= v.monster_ui.info_height+1,"content contained "+str(id)+"/"+str(child.name))
	v.monster_ui.close_info()
	LanguageSettings.set_locale("ko",false)
	var tip := Tooltip.new().configure("선택 후 27/50","첫 줄\n둘째 줄\n셋째 줄\n넷째 줄\n다섯째 줄\n마지막 줄")
	add_child(tip); await frames(5)
	expect(tip.size.y < 300,"seven line tooltip has content height")
	var short_height := tip.size.y
	tip.queue_free(); await frames(2)
	tip = Tooltip.new().configure("Long information",("Long localized description with wrapping. ").repeat(200))
	add_child(tip); await frames(5)
	expect(tip.size.y <= 448,"long tooltip maximum height")
	expect(tip.copy.scroll_active,"complete long tooltip scrolls")
	tip.queue_free()
	var button := Button.new(); add_child(button)
	Glow.attach(button); await frames(3)
	button.pressed.emit()
	expect(not button.get_node("TutorialButtonGlow").visible,"keyboard/controller activation dismisses glow")
	button.queue_free()
	for day in [2,3]:
		GameState.day = day
		game.management_scene.monster_ui.active_tab = "skills"
		game._set_screen("monster",false); await frames(6)
		var choices: Array = game.ui_layer.find_children("MonsterSpecialization_*","BaseButton",true,false)
		expect(not choices.is_empty(),"DAY2–3 actual specialization actions exist")
		for choice in choices:
			if not choice.disabled: expect(choice.has_node("TutorialButtonGlow"),"DAY2–3 actual choice glows")
	expect(DataRegistry.waves.get("day_29",[]).is_empty(),"DAY29 stays noncombat")
	game.campaign_autosave_pending = false; game._shutdown_audio_for_exit()
	var file := FileAccess.open(OUT+"feedback-checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"resolutions":metrics,"seven_line_tooltip_height":short_height},"\t"))
	print("V131_UI ",checks," checks; failures=",failures.size())
	game.queue_free(); await frames(8)
	get_tree().quit(0 if failures.is_empty() else 1)
