extends Node

const CouncilChronicleScript = preload("res://scripts/systems/chronicle/CouncilChronicleService.gd")
const CampaignModeScript = preload("res://scripts/systems/campaign/CampaignModeService.gd")
const ChronicleScreenScene = preload("res://scenes/ui/screens/ChronicleScreen.tscn")
const RegionScreenScene = preload("res://scenes/ui/screens/RegionSelectionScreen.tscn")
const FloorHudScene = preload("res://scenes/ui/hud/MultiFloorHUD.tscn")

var failed := false
var assertion_count := 0
var completed_profile: Dictionary = {}


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_horizontal_unlocks_and_recent_runs()
	_test_relation_letter_gates()
	_test_accessibility_normalization_and_profile_round_trip()
	await _test_ui_and_hud()
	if DisplayServer.get_name() != "headless":
		await _capture_chronicle(Vector2i(1920, 1080))
		await _capture_chronicle(Vector2i(1366, 768))
	if failed:
		print("UPDATE4_CHRONICLE_ACCESSIBILITY_PHASE35_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("UPDATE4_CHRONICLE_ACCESSIBILITY_PHASE35_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_horizontal_unlocks_and_recent_runs() -> void:
	var profile := CampaignModeScript.default_profile()
	var region_ids := CouncilChronicleScript.REGION_ORDER
	var crown_ids := CouncilChronicleScript.CROWN_ORDER
	var ending_ids := DataRegistry.update4_council_endings.keys()
	ending_ids.sort()
	for cycle_index in range(1, 8):
		var active := _active_run(cycle_index)
		active.council_season.selected_regions = [region_ids[(cycle_index - 1) % 5], region_ids[cycle_index % 5], region_ids[(cycle_index + 1) % 5]]
		active.council_season.rival_relations = {"rival_brassa": 70, "rival_vesper": 65, "rival_mirella": 62}
		active.council_season.final_representative_id = CouncilChronicleScript.RIVAL_ORDER[(cycle_index - 1) % 3]
		active.council_season.rival_support_id = CouncilChronicleScript.RIVAL_ORDER[cycle_index % 3]
		active.crown.crown_form_id = crown_ids[(cycle_index - 1) % crown_ids.size()]
		var ending_id := str(ending_ids[(cycle_index - 1) % ending_ids.size()])
		profile = CouncilChronicleScript.record_completed_run(profile, active, cycle_index, ending_id, _context(cycle_index), _catalogs())
	completed_profile = profile.duplicate(true)
	var state: Dictionary = profile.chronicle_update4
	_expect(state.recent_runs.size() == 5 and state.recent_runs.map(func(entry): return int(entry.cycle_index)) == [3, 4, 5, 6, 7], "최근 의회 회차 정확히 5개·오래된 기록 제거")
	_expect(state.recorded_cycle_ids.size() == 7, "수평 해금 회차 7개 멱등 기록")
	_expect(profile.regions.mastery_by_region.values().all(func(value): return int(value) == 3), "지역 5종 숙련 최대 3등급")
	_expect(profile.crown_evolution.forms_seen.size() == 6 and profile.crown_evolution.forms_unlocked.size() == 6 and profile.crown_evolution.memories_unlocked.size() == 6, "왕관 6종 도감·기억 수평 해금")
	_expect(profile.rivals.letters_seen.size() == 15, "관계·결말 누적으로 경쟁 마왕 서신 15개 해금")
	var summary: Dictionary = state.recent_runs.back()
	var expected_fields := ["region_order", "outpost_type_id", "outpost_survived", "upper_layout_id", "representative_id", "rival_relations", "crown_form_id", "council_seals", "council_votes", "independence", "ending_id", "day30"]
	_expect(expected_fields.all(func(key): return summary.has(key)) and summary.day30.has("time_seconds") and summary.day30.has("damage_by_floor"), "최근 회차 비교 필수 12항목·DAY30 세부 기록")
	var mastery_before: Dictionary = profile.regions.mastery_by_region.duplicate(true)
	profile = CouncilChronicleScript.record_completed_run(profile, _active_run(7), 7, str(ending_ids[0]), _context(7), _catalogs())
	_expect(profile.regions.mastery_by_region == mastery_before and profile.chronicle_update4.recorded_cycle_ids.size() == 7, "동일 회차 재기록 시 숙련 중복 증가 금지")
	var model := CouncilChronicleScript.build_view_model(completed_profile, _catalogs())
	_expect(model.regions.size() == 5 and model.rival_letters.size() == 15 and model.crowns.size() == 6 and model.recent_runs.size() == 5, "연대기 지역·서신·왕관·최근 회차 수량")
	_expect(model.regions.all(func(entry): return int(entry.mastery_level) == 3 and bool(entry.alternate_amendment_unlocked)), "지역 숙련 3등급 대체 수정안·후일담 표시")
	var serialized := JSON.stringify({"regions": model.regions, "letters": model.rival_letters, "crowns": model.crowns})
	_expect(not serialized.contains("stat_bonus") and not serialized.contains("combat_bonus") and not serialized.contains("attack_bonus"), "연대기 수평 해금에 영구 전투 수치 없음")


func _test_relation_letter_gates() -> void:
	var profile := CampaignModeScript.default_profile()
	var active := _active_run(1)
	active.council_season.selected_regions = CouncilChronicleScript.REGION_ORDER.slice(0, 3)
	active.council_season.rival_relations = {"rival_brassa": 65, "rival_vesper": 35, "rival_mirella": -20}
	active.council_season.final_representative_id = "rival_brassa"
	active.council_season.rival_support_id = "rival_vesper"
	profile = CouncilChronicleScript.record_completed_run(profile, active, 1, "ending_council_seat", _context(1), _catalogs())
	var letters: Array = profile.rivals.letters_seen
	_expect(letters.filter(func(id): return str(id).contains("brassa")).size() == 5, "대표·관계 65 브라사 서신 5개")
	_expect(letters.filter(func(id): return str(id).contains("vesper")).size() == 4, "지원·관계 35 베스퍼 서신 4개")
	_expect(letters.filter(func(id): return str(id).contains("mirella")).size() == 1, "관계 -20 미렐라 첫 서신만 해금")


func _test_accessibility_normalization_and_profile_round_trip() -> void:
	var invalid := CouncilChronicleScript.normalize_accessibility({"floor_alert_volume": 4.0, "floor_one_key": "X", "floor_two_key": "Y", "quick_dialogue": true})
	_expect(is_equal_approx(float(invalid.floor_alert_volume), 1.0) and invalid.floor_one_key == "Q" and invalid.floor_two_key == "E" and bool(invalid.quick_dialogue), "접근성 범위·층 키 정규화")
	var profile := CouncilChronicleScript.update_accessibility(completed_profile, "floor_alert_volume", 0.25)
	profile = CouncilChronicleScript.update_accessibility(profile, "floor_one_key", "A")
	profile = CouncilChronicleScript.update_accessibility(profile, "floor_two_key", "D")
	var restored: Dictionary = JSON.parse_string(JSON.stringify(profile))
	var normalized := CampaignModeScript.normalize_profile(restored)
	var settings: Dictionary = normalized.chronicle_update4.accessibility
	_expect(is_equal_approx(float(settings.floor_alert_volume), 0.25) and settings.floor_one_key == "A" and settings.floor_two_key == "D", "v5 프로필 JSON 왕복 후 접근성 설정 보존")
	_expect(normalized.chronicle_update4.recent_runs.size() == 5 and normalized.chronicle_update4.recorded_cycle_ids.size() == 7, "v5 프로필 JSON 왕복 후 의회 연대기 보존")


func _test_ui_and_hud() -> void:
	var host := Control.new()
	host.size = Vector2(1920, 1080)
	add_child(host)
	var chronicle = ChronicleScreenScene.instantiate()
	chronicle.set_physical_width_override_for_tests(1920)
	chronicle.setup({}, {}, {}, completed_profile, _catalogs())
	host.add_child(chronicle)
	await get_tree().process_frame
	await get_tree().process_frame
	var region_text: Label = chronicle.get_node("ChronicleCanvas/ChroniclePage0/ChronicleScroll0/ChroniclePageText0")
	var letter_text: Label = chronicle.get_node("ChronicleCanvas/ChroniclePage1/ChronicleScroll1/ChroniclePageText1")
	var run_text: Label = chronicle.get_node("ChronicleCanvas/ChroniclePage2/ChronicleScroll2/ChroniclePageText2")
	_expect(region_text.text.contains("의회 지역 숙련") and letter_text.text.contains("경쟁 마왕 서신") and run_text.text.contains("최근 5회 의회 회차 비교") and run_text.text.contains("왕관 진화 도감"), "기존 연대기에 Update 4 네 기록군 통합")
	var controls = chronicle.get_node_or_null("ChronicleCanvas/ChroniclePage2/Update4AccessibilityControls")
	_expect(controls != null and controls.get_node_or_null("QuickDialogueToggle") != null and controls.get_node_or_null("FloorAlertVolume") != null and controls.get_node_or_null("FloorOneKey") != null, "연대기 접근성 토글·경보 볼륨·층 키")
	for viewport_size in [Vector2(1920, 1080), Vector2(1366, 768)]:
		var rects: Dictionary = chronicle.layout_contract(viewport_size)
		_expect(_rects_non_overlapping(rects, viewport_size), "%dx%d 연대기 UI 경계·비겹침" % [int(viewport_size.x), int(viewport_size.y)])
	chronicle.queue_free()
	await get_tree().process_frame

	var active := _active_run(1)
	var region_screen = RegionScreenScene.instantiate()
	region_screen.setup(active, DataRegistry.update4_regions, 4, false, {"reduce_region_motion": true, "show_region_details": true}, {"region_ironbell_ravine": 2})
	host.add_child(region_screen)
	await get_tree().process_frame
	var region_button: Button = region_screen.get_node("DesignCanvas/RegionCardButton_region_ironbell_ravine")
	var mastery_label: Label = region_button.get_node("RegionMastery_region_ironbell_ravine")
	_expect(is_equal_approx(region_screen.modulate.a, 1.0) and mastery_label.text.contains("숙련 Lv.2") and region_button.tooltip_text.contains("숙련 Lv.2 추가 정보"), "지역 움직임 감소·숙련 2 추가 정보")
	region_screen.queue_free()
	await get_tree().process_frame

	var upper: Dictionary = active.upper_floor
	upper.layout_id = "upper_compact_guard"
	upper.layout_locked = true
	upper.objective_hp = {"crown_sanctum": 600}
	upper.graph_runtime = {"visible_floor": "1F", "entities": {}}
	var hud = FloorHudScene.instantiate()
	hud.setup(upper, DataRegistry.update4_upper_floor_layouts, DataRegistry.update4_upper_floor_modules, {"floor_alert_volume": 0.0, "hidden_floor_summary": false, "high_contrast_icons": true, "floor_one_key": "A", "floor_two_key": "D"})
	host.add_child(hud)
	await get_tree().process_frame
	hud.push_hidden_floor_alert("2F", 4, true)
	var event := InputEventKey.new()
	event.keycode = KEY_D
	event.pressed = true
	hud._unhandled_input(event)
	_expect(hud.floor_1_button.text.contains("A") and hud.floor_2_button.text.contains("D") and hud.visible_floor == "2F", "재설정한 A/D 층 전환 키 적용")
	_expect(hud.alert_label.text == "⚠ 2F 위험" and (hud.alert_sound == null or is_equal_approx(hud.alert_sound.volume_db, -80.0)), "숨은 층 요약 OFF·전용 경보 음량 0")
	var alert_style: StyleBoxFlat = hud.alert_panel.get_theme_stylebox("panel")
	_expect(alert_style.border_color == Color("#fff05a") and alert_style.get_border_width(SIDE_LEFT) == 4, "고대비 위험 아이콘·경보 테두리")
	host.queue_free()
	await get_tree().process_frame


func _capture_chronicle(viewport_size: Vector2i) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var screen = ChronicleScreenScene.instantiate()
	screen.set_physical_width_override_for_tests(float(viewport_size.x))
	if viewport_size.x < 1600:
		screen.active_tab = 2
	screen.setup({}, {}, {}, completed_profile, _catalogs())
	viewport.add_child(screen)
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var path := "res://tmp/phase35_chronicle_%dx%d.png" % [viewport_size.x, viewport_size.y]
	_expect(image.save_png(path) == OK and image.get_size() == viewport_size, "%dx%d 연대기 실제 캡처" % [viewport_size.x, viewport_size.y])
	viewport.queue_free()
	await get_tree().process_frame


func _active_run(cycle_index: int) -> Dictionary:
	var active := CampaignModeScript.default_active_run()
	active.campaign_mode_id = CampaignModeScript.COUNCIL_MODE_ID
	active.cycle_index = cycle_index
	active.council_season.council_seals = cycle_index % 4
	active.council_season.council_votes = 40 + cycle_index
	active.council_season.independence = 20 + cycle_index
	active.outpost.type_id = "outpost_watch_nest"
	active.outpost.stats.day20_win = cycle_index % 2 == 1
	active.upper_floor.layout_id = "upper_compact_guard"
	return active


func _context(cycle_index: int) -> Dictionary:
	return {
		"final_battle_won": true,
		"cycle_index": cycle_index,
		"outpost_day20_survived": cycle_index % 2 == 1,
		"day30_time_seconds": 120.0 + cycle_index,
		"day30_lower_survivor_count": 2,
		"day30_upper_survivor_count": 1,
		"day30_damage_by_floor": {"1F": 100 + cycle_index, "2F": 50 + cycle_index}
	}


func _catalogs() -> Dictionary:
	return {
		"regions": DataRegistry.update4_regions,
		"rival_lords": DataRegistry.update4_rival_lords,
		"rival_letters": DataRegistry.update4_rival_letters,
		"crown_evolutions": DataRegistry.update4_crown_evolutions,
		"council_endings": DataRegistry.update4_council_endings
	}


func _rects_non_overlapping(rects: Dictionary, viewport_size: Vector2) -> bool:
	var values: Array = rects.values()
	for index in values.size():
		var rect: Rect2 = values[index]
		if rect.position.x < 0.0 or rect.position.y < 0.0 or rect.end.x > viewport_size.x or rect.end.y > viewport_size.y:
			return false
		for other_index in range(index + 1, values.size()):
			if rect.intersects(values[other_index]):
				return false
	return true


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[Update4ChronicleAccessibilityPhase35] FAIL: %s" % label)
