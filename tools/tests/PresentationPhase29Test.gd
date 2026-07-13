extends Node

const UnitActorScript = preload("res://scripts/units/Unit.gd")
const HeartScreenScene = preload("res://scenes/ui/screens/HeartSelectionScreen.tscn")
const FrontScreenScene = preload("res://scenes/ui/screens/FrontSelectionScreen.tscn")
const ChronicleScreenScene = preload("res://scenes/ui/screens/ChronicleScreen.tscn")

const ENEMY_IDS := ["seal_chainbearer", "reliquary_guard", "choir_exorcist", "bounty_tracker", "combat_alchemist", "ledger_binder"]
const HEART_IDS := ["heart_stonebone", "heart_hungry_maw", "heart_dream_lantern"]

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_enemy_atlases()
	_test_heart_art()
	_test_duo_front_and_status_art()
	_test_audio()
	_test_source_records_and_runtime_policies()
	await _test_ui_mounts()
	if failed:
		print("PRESENTATION_PHASE29_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("PRESENTATION_PHASE29_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_enemy_atlases() -> void:
	for enemy_id in ENEMY_IDS:
		var definition: Dictionary = DataRegistry.update3_enemy_extensions.get(enemy_id, {})
		var path := str(definition.get("sprite", ""))
		_expect(path.ends_with("_sheet.png") and ResourceLoader.exists(path), "%s 4x4 atlas exists" % enemy_id)
		_expect(not bool(definition.get("placeholder_art", true)), "%s placeholder flag removed" % enemy_id)
		var texture := load(path) as Texture2D
		_expect(texture != null and texture.get_width() % 4 == 2 and texture.get_height() % 4 == 2, "%s equal fractional 4x4 regions remain in bounds" % enemy_id)
		var frames := UnitActorScript.warm_animation_frames(path)
		var count := 0
		for animation in ["idle_down", "down", "move_down", "attack_down", "skill_down"]:
			count += frames.get_frame_count(animation)
		_expect(count == 16, "%s exposes exactly 16 runtime frames" % enemy_id)
		_expect(_hot_magenta_corners(texture), "%s keeps chroma safety margin at all outer corners" % enemy_id)


func _test_heart_art() -> void:
	var prop_sheet := load("res://assets/sprites/hearts/heart_props_sheet.png") as Texture2D
	var icon_sheet := load("res://assets/ui/hearts/heart_icons_vfx_sheet.png") as Texture2D
	_expect(prop_sheet != null and prop_sheet.get_width() > 1200 and prop_sheet.get_height() > 900, "heart prop sheet imported")
	_expect(icon_sheet != null and icon_sheet.get_width() % 3 == 0 and icon_sheet.get_height() % 2 == 0, "heart icon/VFX 3x2 sheet imported")
	var prop_count := 0
	for heart_id in HEART_IDS:
		var art: Dictionary = DataRegistry.update3_castle_hearts.get(heart_id, {}).get("art", {})
		_expect(not bool(art.get("placeholder", true)), "%s production art record" % heart_id)
		_expect(art.get("stage_columns", {}).size() == 3 and int(art.get("inactive_column", -1)) == 3, "%s stage 2/3/4 plus inactive mapping" % heart_id)
		prop_count += art.get("stage_columns", {}).size()
	_expect(prop_count == 9, "all nine heart-stage props mapped")
	_expect(_hot_magenta_corners(prop_sheet) and _hot_magenta_corners(icon_sheet), "heart sheets have uncropped chroma margins")


func _test_duo_front_and_status_art() -> void:
	var duo_sheet := load("res://assets/ui/duo/duo_badges_vfx_sheet.png") as Texture2D
	_expect(duo_sheet != null and duo_sheet.get_width() % 3 == 0 and duo_sheet.get_height() % 2 == 0, "six-cell duo sheet imported")
	var duo_cells: Dictionary = {}
	for link_id in DataRegistry.update3_duo_links.keys():
		var vfx: Dictionary = DataRegistry.update3_duo_links[link_id].get("vfx", {})
		_expect(not bool(vfx.get("placeholder", true)) and ResourceLoader.exists(str(vfx.get("sheet", ""))), "%s production VFX record" % link_id)
		duo_cells[str(vfx.get("cell", []))] = true
	_expect(duo_cells.size() == 6, "six duo emblem/VFX cells are unique")
	var front_sheet := load("res://assets/ui/fronts/front_chronicle_sheet.png") as Texture2D
	_expect(front_sheet != null and _hot_magenta_corners(front_sheet), "front and Chronicle sheet imported with safe margin")
	for front_id in DataRegistry.update3_fronts.keys():
		var art: Dictionary = DataRegistry.update3_fronts[front_id].get("art", {})
		_expect(not bool(art.get("placeholder", true)) and art.get("emblem_cell", []).size() == 2 and art.get("rival_cell", []).size() == 2, "%s emblem and rival crest mapped" % front_id)
	var status_sheet := load("res://assets/ui/status/update3_status_icons_sheet.png") as Texture2D
	_expect(status_sheet != null and status_sheet.get_width() == status_sheet.get_height(), "16-state icon square sheet imported")
	_expect(_hot_magenta_corners(status_sheet), "status icon sheet keeps transparent-edge safety margin")


func _test_audio() -> void:
	var directory := DirAccess.open("res://assets/audio/update3")
	var wav_count := 0
	if directory != null:
		directory.list_dir_begin()
		var file_name := directory.get_next()
		while file_name != "":
			if not directory.current_is_dir() and file_name.ends_with(".wav"):
				wav_count += 1
				_expect(load("res://assets/audio/update3/%s" % file_name) is AudioStreamWAV, "%s imports as WAV" % file_name)
			file_name = directory.get_next()
	_expect(wav_count == 31, "31 Update 3 audio cues generated")
	for required in ["heart_stonebone_loop", "heart_hungry_loop", "heart_dream_loop", "heart_ready", "heart_disabled", "boss_selen_motif", "boss_roman_motif"]:
		_expect(ResourceLoader.exists("res://assets/audio/update3/%s.wav" % required), "%s required cue exists" % required)


func _test_source_records_and_runtime_policies() -> void:
	for path in ["res://assets/source/imagegen/update3_enemy_atlases/SOURCE.md", "res://assets/source/imagegen/update3_presentation/SOURCE.md", "res://assets/audio/update3/SOURCE.md", "res://assets/source/imagegen/update3_endings/SOURCE.md"]:
		_expect(FileAccess.file_exists(path), "%s source record exists" % path.get_file())
	var root_source := FileAccess.get_file_as_string("res://scripts/game/GameRoot.gd")
	var unit_source := FileAccess.get_file_as_string("res://scripts/units/Unit.gd")
	_expect(root_source.contains("active_total >= 4") and root_source.contains("Update3HeartLoop"), "audio overlap cap and single heart loop are enforced")
	_expect(root_source.contains("DuoLinkVfx_") and root_source.contains("HeartActiveVfx"), "heart and duo runtime VFX are connected")
	_expect(unit_source.contains("_sheet_chroma_shader") and unit_source.contains("_build_sheet_animation_frames"), "enemy chroma edges and atlas frames are connected")


func _test_ui_mounts() -> void:
	var host := Control.new()
	host.size = Vector2(1920, 1080)
	add_child(host)
	var profile: Dictionary = preload("res://scripts/systems/fronts/FrontCampaignService.gd").default_update3_profile()
	profile["hearts"]["unlocked"] = HEART_IDS.duplicate()
	profile["fronts"]["unlocked"] = DataRegistry.update3_fronts.keys()
	var heart = HeartScreenScene.instantiate()
	heart.setup(profile, DataRegistry.update3_castle_hearts, "test front", true)
	host.add_child(heart)
	await get_tree().process_frame
	for heart_id in HEART_IDS:
		var icon := heart.get_node_or_null("DesignCanvas/HeartCardButton_%s/HeartIcon_%s" % [heart_id, heart_id]) as TextureRect
		_expect(icon != null and icon.texture is AtlasTexture and icon.material is ShaderMaterial, "%s selection icon mounted without card overflow" % heart_id)
	heart.queue_free()
	await get_tree().process_frame
	var front = FrontScreenScene.instantiate()
	front.setup(profile, DataRegistry.update3_fronts, 2, true)
	host.add_child(front)
	await get_tree().process_frame
	for front_id in DataRegistry.update3_fronts.keys():
		_expect(front.get_node_or_null("DesignCanvas/FrontCardButton_%s/FrontEmblem_%s" % [front_id, front_id]) != null, "%s emblem mounted" % front_id)
		_expect(front.get_node_or_null("DesignCanvas/FrontCardButton_%s/RivalCrest_%s" % [front_id, front_id]) != null, "%s rival crest mounted" % front_id)
	front.queue_free()
	await get_tree().process_frame
	var chronicle = ChronicleScreenScene.instantiate()
	chronicle.setup(profile, {"fronts": DataRegistry.update3_fronts, "castle_hearts": DataRegistry.update3_castle_hearts, "duo_links": DataRegistry.update3_duo_links}, DataRegistry.update3_chronicle_goals)
	host.add_child(chronicle)
	await get_tree().process_frame
	_expect(chronicle.get_node_or_null("ChronicleCanvas/ChronicleThreeFrontMap") != null, "Chronicle three-front map mounted")
	host.queue_free()


func _hot_magenta_corners(texture: Texture2D) -> bool:
	if texture == null:
		return false
	var image := texture.get_image()
	for point in [Vector2i(0, 0), Vector2i(image.get_width() - 1, 0), Vector2i(0, image.get_height() - 1), Vector2i(image.get_width() - 1, image.get_height() - 1)]:
		var color := image.get_pixelv(point)
		# Imported sRGB textures are sampled in linear color space, so vivid magenta
		# corners read near 0.75 rather than the source file's 0.9+ byte values.
		if color.r < 0.60 or color.b < 0.60 or color.g > 0.22:
			return false
	return true


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  PASS - %s" % label)
	else:
		failed = true
		push_error("  FAIL - %s" % label)
