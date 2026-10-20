extends Node
## Uses real dialogue layout, without loading or writing player saves.
var game: Node
var checks := 0
var failures: Array = []
var samples: Array = []

func _ready() -> void:
	run.call_deferred()

func frames() -> void:
	for i in 4: await get_tree().process_frame

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func run() -> void:
	game = load("res://scenes/game/GameRoot.tscn").instantiate()
	game.campaign_save_enabled = false; game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v5_enabled = false; game.campaign_save_v6_enabled = false
	add_child(game)
	await frames()
	game.set_process(false); game.set_physics_process(false); game.start_flow.set_process(false)
	game.story_feature_enabled = false; game.tutorial_gate_enabled = false; game.tutorial_manager.active = false
	var audit: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tmp/portrait_alpha_20261020/audit.json"))
	var saved: Dictionary = DataRegistry.characters["CHR_GOLDIN"].duplicate(true)
	for resolution in [Vector2i(1280,720), Vector2i(1920,1080)]:
		get_window().size = resolution
		await frames()
		for row in audit.rows:
			var path := str(row.path)
			if not (path.contains("_alpha_v131") or path.contains("uiux_crowns/") or path.contains("uiux_evolution/") or path.contains("/portraits/update3/")): continue
			DataRegistry.characters["CHR_GOLDIN"]["portrait"] = {"base":path}
			var screen := Control.new()
			game.ui_layer.add_child(screen)
			screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			game.story_presenter._standing(screen,"CHR_BATI",0,true,false)
			game.story_presenter._standing(screen,"CHR_GOLDIN",1,true,false)
			await frames()
			var left: TextureRect = screen.get_node("DialogueStandingLeft")
			var right: TextureRect = screen.get_node("DialogueStandingRight")
			var bounds: Rect2i = game.story_presenter.standing_visible_bounds(left.texture)
			var fit := minf(left.size.x/left.texture.get_width(),left.size.y/left.texture.get_height())
			var origin := left.position+(left.size-left.texture.get_size()*fit)*0.5
			var height := bounds.size.y*fit
			var baseline := origin.y+bounds.end.y*fit
			expect(absf(right.size.y-height)<1.1,"height "+path)
			expect(absf(right.position.y+right.size.y-baseline)<1.1,"baseline "+path)
			expect(right.texture.get_image().get_format() == Image.FORMAT_RGBA8,"RGBA "+path)
			samples.append({"path":path,"resolution":str(resolution),"height":right.size.y,"reference_height":height,"baseline":right.position.y+right.size.y,"reference_baseline":baseline})
			screen.free()
	DataRegistry.characters["CHR_GOLDIN"] = saved
	var result := {"checks":checks,"failures":failures,"samples":samples}
	var file := FileAccess.open("res://tmp/portrait_alpha_20261020/layout_checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t")); file.close()
	print("PORTRAIT_ALPHA_LAYOUT checks=",checks," failures=",failures.size())
	if not failures.is_empty(): print(failures.slice(0,5))
	game._shutdown_audio_for_exit(); game.campaign_autosave_pending = false
	game.queue_free(); await frames()
	get_tree().quit(0 if failures.is_empty() else 1)
