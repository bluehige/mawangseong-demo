extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const FrontServiceScript = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const UnitActorScript = preload("res://scripts/units/Unit.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var game: Node
var output_dir := ""
var failed := false
var showcase: CanvasLayer = null


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = ProjectSettings.globalize_path("res://tmp/update3_phase29")
	DirAccess.make_dir_recursive_absolute(output_dir)
	game = GameRootScene.instantiate()
	add_child(game)
	await _settle(4)
	game._debug_skip_onboarding()
	_prepare_profile()
	game._set_screen(Constants.SCREEN_HEART_SELECTION)
	await _capture(Vector2i(1920, 1080), "heart_selection_1920x1080.png")
	game._set_screen(Constants.SCREEN_FRONT_SELECTION)
	await _capture(Vector2i(1366, 768), "front_selection_1366x768.png")
	game._set_screen(Constants.SCREEN_CHRONICLE)
	await _capture(Vector2i(1920, 1080), "chronicle_map_1920x1080.png")
	_build_enemy_showcase()
	await _capture(Vector2i(1920, 1080), "enemy_atlases_1920x1080.png")
	_build_heart_duo_showcase()
	await _capture(Vector2i(1920, 1080), "heart_duo_assets_1920x1080.png")
	print("PRESENTATION_PHASE29_VISUAL_REVIEW: %s" % ("FAIL" if failed else "PASS"))
	get_tree().quit(1 if failed else 0)


func _prepare_profile() -> void:
	game.campaign_cycle_index = 3
	game.update3_profile = FrontServiceScript.default_update3_profile()
	game.update3_profile["hearts"]["unlocked"] = ["heart_stonebone", "heart_hungry_maw", "heart_dream_lantern"]
	game.update3_profile["fronts"]["unlocked"] = DataRegistry.update3_fronts.keys()
	game.update3_active_run = FrontServiceScript.default_legacy_active_run(3)
	game.update3_active_run["front_selection_completed"] = true
	game.update3_active_run["front_id"] = "front_hero_oath"


func _clear_showcase() -> void:
	if showcase != null and is_instance_valid(showcase):
		showcase.queue_free()
		showcase = null
	game.visible = false


func _showcase_base(title: String) -> Control:
	_clear_showcase()
	showcase = CanvasLayer.new()
	showcase.layer = 500
	add_child(showcase)
	var root := Control.new()
	root.size = Vector2(1920, 1080)
	showcase.add_child(root)
	var background := ColorRect.new()
	background.size = root.size
	background.color = Color("#08060d")
	root.add_child(background)
	var heading := Label.new()
	heading.position = Vector2(70, 34)
	heading.size = Vector2(1780, 60)
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", preload("res://assets/fonts/NotoSansCJKkr-Regular.otf"))
	heading.add_theme_font_size_override("font_size", 34)
	heading.add_theme_color_override("font_color", Color("#ffe4a0"))
	root.add_child(heading)
	return root


func _build_enemy_showcase() -> void:
	var root := _showcase_base("UPDATE 3 · 신규 적 6종 / 16프레임 런타임 아틀라스")
	var ids := ["seal_chainbearer", "reliquary_guard", "choir_exorcist", "bounty_tracker", "combat_alchemist", "ledger_binder"]
	for index in range(ids.size()):
		var enemy_id: String = ids[index]
		var unit := UnitActorScript.new()
		unit.position = Vector2(330 + (index % 3) * 630, 340 + (index / 3) * 450)
		root.add_child(unit)
		unit.setup(enemy_id, DataRegistry.enemies[enemy_id], Constants.FACTION_ENEMY, "entrance")
		unit.sprite.scale *= 1.55
		unit.name_label.position += Vector2(0, -38)
		unit.name_label.add_theme_font_size_override("font_size", 18)
		unit._play_animation("skill_down" if index % 2 == 0 else "attack_down")


func _build_heart_duo_showcase() -> void:
	var root := _showcase_base("UPDATE 3 · 심장 9단계 · 비활성 표식 · 듀오 6종")
	var heart_sheet := load("res://assets/sprites/hearts/heart_props_sheet.png") as Texture2D
	for row in range(3):
		for column in range(4):
			var icon := TextureRect.new()
			icon.position = Vector2(80 + column * 285, 128 + row * 275)
			icon.size = Vector2(250, 245)
			icon.texture = _atlas(heart_sheet, Vector2i(column, row), Vector2i(4, 3))
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.material = _chroma_material()
			root.add_child(icon)
	var duo_sheet := load("res://assets/ui/duo/duo_badges_vfx_sheet.png") as Texture2D
	for index in range(6):
		var duo := TextureRect.new()
		duo.position = Vector2(1280 + (index % 2) * 290, 145 + (index / 2) * 285)
		duo.size = Vector2(260, 260)
		duo.texture = _atlas(duo_sheet, Vector2i(index % 3, index / 3), Vector2i(3, 2))
		duo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		duo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		duo.material = _chroma_material()
		root.add_child(duo)


func _atlas(sheet: Texture2D, cell: Vector2i, grid: Vector2i) -> AtlasTexture:
	var size := Vector2(sheet.get_width() / float(grid.x), sheet.get_height() / float(grid.y))
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(cell) * size, size)
	return atlas


func _chroma_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); float m=min(c.r,c.b)-c.g; float balance=1.0-smoothstep(0.10,0.32,abs(c.r-c.b)); float k=smoothstep(0.10,0.34,m)*balance; c.a*=1.0-k; COLOR=c; }"
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _capture(size: Vector2i, file_name: String) -> void:
	DisplayServer.window_set_size(size)
	await _settle(10)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image == null or absi(image.get_width() - size.x) > 1 or absi(image.get_height() - size.y) > 1:
		failed = true
		push_error("Capture size mismatch: %s" % size)
		return
	image.convert(Image.FORMAT_RGB8)
	if image.save_png(output_dir.path_join(file_name)) != OK:
		failed = true
		push_error("Capture failed: %s" % file_name)


func _settle(frames: int) -> void:
	for _index in range(frames):
		await get_tree().process_frame
		await get_tree().physics_frame
