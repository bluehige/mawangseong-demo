extends Node

const RegionScreenScene = preload("res://scenes/ui/screens/RegionSelectionScreen.tscn")
const OutpostScreenScene = preload("res://scenes/ui/screens/OutpostManagementScreen.tscn")
const UpperScreenScene = preload("res://scenes/ui/screens/UpperFloorScreen.tscn")
const FloorHudScene = preload("res://scenes/ui/hud/MultiFloorHUD.tscn")
const CampaignModeScript = preload("res://scripts/systems/campaign/CampaignModeService.gd")

const SIZES := [Vector2i(1920, 1080), Vector2i(1366, 768)]

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_region_assets()
	_test_outpost_assets()
	_test_upper_assets()
	_test_source_records()
	await _test_screen_layers_and_captures()
	if failed:
		print("UPDATE4_WORLD_ART_PHASE34_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("UPDATE4_WORLD_ART_PHASE34_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_region_assets() -> void:
	_expect(DataRegistry.update4_regions.size() == 5, "지역 카드 데이터 5종")
	var backgrounds := {}
	var emblems := {}
	for region_id in DataRegistry.update4_regions.keys():
		var definition: Dictionary = DataRegistry.update4_regions[region_id]
		var background := _image(str(definition.get("card_background", "")))
		var emblem := _image(str(definition.get("emblem", "")))
		_expect(background != null and background.get_size() == Vector2i(1024, 576), "%s 카드 배경 1024×576" % region_id)
		_expect(emblem != null and emblem.get_size() == Vector2i(256, 256) and emblem.get_used_rect().size != Vector2i.ZERO, "%s 문양 256×256" % region_id)
		backgrounds[_digest(background)] = true
		emblems[_digest(emblem)] = true
	_expect(backgrounds.size() == 5 and emblems.size() == 5, "지역 배경·문양 5종 시각 고유")


func _test_outpost_assets() -> void:
	_expect(DataRegistry.update4_outpost_types.size() == 3, "전초기지 유형 3종")
	var state_hashes := {}
	for type_id in DataRegistry.update4_outpost_types.keys():
		var states: Dictionary = DataRegistry.update4_outpost_types[type_id].get("art_states", {})
		_expect(states.keys().size() == 3 and states.has("base") and states.has("damaged") and states.has("level2"), "%s 기본·손상·Lv.2 상태" % type_id)
		for state in ["base", "damaged", "level2"]:
			var image := _image(str(states.get(state, "")))
			_expect(image != null and image.get_size() == Vector2i(512, 320) and image.get_pixel(0, 0).a < 0.05 and image.get_used_rect().size != Vector2i.ZERO, "%s %s 투명 512×320" % [type_id, state])
			state_hashes[_digest(image)] = true
	_expect(state_hashes.size() == 9, "전초기지 9개 상태 이미지 고유")
	_expect(int(DataRegistry.update4_outpost_types.outpost_watch_nest.base_hp) == 360 and int(DataRegistry.update4_outpost_types.outpost_supply_burrow.base_hp) == 400 and int(DataRegistry.update4_outpost_types.outpost_false_gate.base_hp) == 440, "Phase 34에서 전초기지 전투 수치 불변")


func _test_upper_assets() -> void:
	var manifest: Dictionary = DataRegistry.update4_asset_manifest.get("asset_update4_world_upper_floor", {})
	_expect(manifest.get("tiles", []).size() == 4 and manifest.get("props", []).size() == 7 and manifest.get("layout_previews", []).size() == 3, "상층 타일 4·소품 7·레이아웃 3")
	for path_value in manifest.get("tiles", []) + manifest.get("props", []) + manifest.get("layout_previews", []) + [manifest.get("floor_icon", "")]:
		var image := _image(str(path_value))
		_expect(image != null and image.get_width() > 0 and image.get_height() > 0, "상층 런타임 자산 로드: %s" % path_value)
	var normal := _image("res://assets/props/update4/upper/seal_vault_normal.png")
	var alarm := _image("res://assets/props/update4/upper/seal_vault_alarm.png")
	var stolen := _image("res://assets/props/update4/upper/seal_vault_stolen.png")
	_expect(_digest(normal) != _digest(alarm) and _digest(alarm) != _digest(stolen), "인장 금고 기본·경보·절도 상태 구분")
	_expect(_red_energy(alarm) > _red_energy(normal) * 1.15, "인장 금고 경보 상태 적색 신호 강화")
	_expect(DataRegistry.update4_upper_floor_modules.seal_vault.art_states.alarm.ends_with("seal_vault_alarm.png"), "인장 금고 경보 데이터 연결")


func _test_source_records() -> void:
	var region_source := FileAccess.get_file_as_string("res://assets/source/imagegen/update4_world_phase34/regions/SOURCE.md")
	var outpost_source := FileAccess.get_file_as_string("res://assets/source/imagegen/update4_world_phase34/outposts/SOURCE.md")
	var upper_source := FileAccess.get_file_as_string("res://assets/source/imagegen/update4_world_phase34/upper_floor/SOURCE.md")
	for source_text in [region_source, outpost_source, upper_source]:
		_expect(source_text.contains("Generation model: GPT internal image generation") and source_text.contains("Generated date: 2026-07-14") and source_text.contains("Target version: v0.4"), "Phase 34 SOURCE 고정 필드")
	_expect(region_source.count("Source image path:") == 5 and region_source.count("Runtime image path:") == 10, "지역 원본 5·런타임 10 기록")
	_expect(outpost_source.count("Source image path:") == 3 and outpost_source.count("Runtime image path:") == 9, "전초기지 원본 3·런타임 9 기록")
	_expect(upper_source.count("Source image path:") == 1 and upper_source.count("Runtime image path:") == 15, "상층 원본 1·런타임 15 기록")


func _test_screen_layers_and_captures() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
	var active := CampaignModeScript.default_active_run()
	active.campaign_mode_id = CampaignModeScript.COUNCIL_MODE_ID
	var region_screen = RegionScreenScene.instantiate()
	region_screen.setup(active, DataRegistry.update4_regions, 4, false)
	await _capture_at_sizes(region_screen, "phase34_regions")
	var region_art = region_screen.get_node_or_null("DesignCanvas/RegionCardButton_region_ironbell_ravine/RegionArt_region_ironbell_ravine")
	_expect(region_art is TextureRect and region_art.z_index == 0, "지역 카드 배경 z-index")
	region_screen.queue_free()
	await get_tree().process_frame

	var outpost_screen = OutpostScreenScene.instantiate()
	outpost_screen.setup(active, DataRegistry.update4_outpost_types, [], {}, 4)
	await _capture_at_sizes(outpost_screen, "phase34_outposts")
	var outpost_art = outpost_screen.get_node_or_null("DesignCanvas/OutpostTypeButton_outpost_watch_nest/OutpostArt_outpost_watch_nest_base")
	_expect(outpost_art is TextureRect and outpost_art.z_index == 0, "전초기지 카드 아트 z-index")
	outpost_screen.queue_free()
	await get_tree().process_frame

	var upper: Dictionary = active.upper_floor.duplicate(true)
	upper.layout_id = "upper_compact_guard"
	upper.layout_locked = true
	upper.objective_hp = {"crown_sanctum": 600}
	upper.graph_runtime = {"visible_floor": "2F", "seal_alert_active": true, "entities": {}}
	var upper_screen = UpperScreenScene.instantiate()
	upper_screen.setup(upper, DataRegistry.update4_upper_floor_layouts, DataRegistry.update4_upper_floor_modules)
	add_child(upper_screen)
	await get_tree().process_frame
	var layout_preview = upper_screen.find_child("LayoutPreview_upper_compact_guard", true, false)
	_expect(layout_preview is TextureRect and layout_preview.z_index == 0, "상층 선택 카드 미리보기 z-index")
	upper_screen.queue_free()
	await get_tree().process_frame

	var hud = FloorHudScene.instantiate()
	hud.setup(upper, DataRegistry.update4_upper_floor_layouts, DataRegistry.update4_upper_floor_modules)
	await _capture_at_sizes(hud, "phase34_upper_hud")
	var backdrop = hud.get_node_or_null("DesignCanvas/UpperFloorSchematic/UpperFloorBackdrop")
	var alert = hud.get_node_or_null("DesignCanvas/HiddenFloorAlert")
	var vault_art = hud.get_node_or_null("DesignCanvas/UpperFloorSchematic/upper_vault/ModuleArt_seal_vault")
	_expect(backdrop is TextureRect and backdrop.z_index == -1, "상층 HUD 배경 z-index")
	_expect(alert is Panel and alert.z_index == 50, "숨은 층 경보 최상위 z-index")
	_expect(vault_art is TextureRect and str(vault_art.texture.resource_path).ends_with("seal_vault_alarm.png"), "상층 HUD 인장 금고 경보 아트")
	hud.queue_free()
	await get_tree().process_frame


func _capture_at_sizes(screen: Control, prefix: String) -> void:
	if DisplayServer.get_name() == "headless":
		add_child(screen)
		screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
		for viewport_size in SIZES:
			screen.size = Vector2(viewport_size)
			await get_tree().process_frame
			await get_tree().process_frame
			_expect(Vector2i(screen.size) == viewport_size, "%s %d×%d 뷰포트 배치" % [prefix, viewport_size.x, viewport_size.y])
		remove_child(screen)
		return
	for viewport_size in SIZES:
		var capture_viewport := SubViewport.new()
		capture_viewport.size = viewport_size
		capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(capture_viewport)
		capture_viewport.add_child(screen)
		await get_tree().process_frame
		await get_tree().create_timer(0.25).timeout
		await RenderingServer.frame_post_draw
		var capture := capture_viewport.get_texture().get_image()
		var path := "res://tmp/%s_%dx%d.png" % [prefix, viewport_size.x, viewport_size.y]
		var error := capture.save_png(path)
		_expect(error == OK and capture.get_size() == viewport_size, "%s %d×%d 실제 캡처" % [prefix, viewport_size.x, viewport_size.y])
		capture_viewport.remove_child(screen)
		capture_viewport.queue_free()
		await get_tree().process_frame


func _image(path: String) -> Image:
	var texture = ResourceLoader.load(path)
	return texture.get_image() if texture is Texture2D else null


func _digest(image: Image) -> String:
	if image == null:
		return ""
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(image.get_data())
	return context.finish().hex_encode()


func _red_energy(image: Image) -> float:
	if image == null:
		return 0.0
	var total := 0.0
	var samples := 0
	for y in range(0, image.get_height(), 8):
		for x in range(0, image.get_width(), 8):
			var color := image.get_pixel(x, y)
			if color.a > 0.2:
				total += maxf(0.0, color.r - color.b * 0.35)
				samples += 1
	return total / maxf(1.0, float(samples))


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[Update4WorldArtPhase34] FAIL: %s" % label)
