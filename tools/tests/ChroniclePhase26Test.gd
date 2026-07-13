extends Node

const ChronicleServiceScript = preload("res://scripts/systems/chronicle/ChronicleService.gd")
const FrontServiceScript = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const ChronicleScreenScene = preload("res://scenes/ui/screens/ChronicleScreen.tscn")
const MainScene = preload("res://scenes/main/Main.tscn")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_goal_contract()
	_test_mastery_and_recent_runs()
	_test_view_model_and_hints()
	await _test_responsive_screen()
	await _test_game_root_flow()
	if failed:
		print("CHRONICLE_PHASE26_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("CHRONICLE_PHASE26_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_goal_contract() -> void:
	_expect(DataRegistry.update3_chronicle_goals.size() == 12, "연대기 장기 목표 12종 로드")
	_expect(not ChronicleServiceScript.has_numeric_rewards(DataRegistry.update3_chronicle_goals), "연대기 보상에 능력치·자원·전투 수치 보상 없음")
	for goal_value in DataRegistry.update3_chronicle_goals.values():
		var goal: Dictionary = goal_value
		_expect(not goal.get("reward_ids", []).is_empty() and str(goal.get("lock_hint", "")) != "", "%s 꾸미기·기록 보상과 잠금 힌트" % str(goal.get("title", "목표")))


func _test_mastery_and_recent_runs() -> void:
	var profile := FrontServiceScript.default_update3_profile()
	var active := FrontServiceScript.new_cycle_active_run(1)
	active["front_id"] = FrontServiceScript.HERO_FRONT_ID
	for expected in [34, 68, 100]:
		profile = FrontServiceScript.record_front_clear(profile, active, DataRegistry.update3_fronts)
		_expect(int(profile.get("fronts", {}).get("mastery", {}).get(FrontServiceScript.HERO_FRONT_ID, 0)) == expected, "전선 클리어 누적 숙련 %d%%" % expected)
	for cycle in range(1, 8):
		active["heart"]["heart_id"] = "heart_stonebone"
		profile = ChronicleServiceScript.record_run_summary(profile, active, cycle, "true_demon_castle", DataRegistry.ending_rules, DataRegistry.update3_fronts)
	var recent: Array = profile.get("recent_run_summaries", [])
	_expect(recent.size() == 5 and int(recent.front().get("cycle_index", 0)) == 3 and int(recent.back().get("cycle_index", 0)) == 7, "5개 초과 회차 요약은 오래된 항목부터 제거")
	profile = ChronicleServiceScript.record_run_summary(profile, active, 7, "true_demon_castle", DataRegistry.ending_rules, DataRegistry.update3_fronts)
	_expect(profile.get("recent_run_summaries", []).size() == 5, "같은 회차 재기록 시 중복 없이 교체")
	var restored = JSON.parse_string(JSON.stringify(profile))
	var normalized := FrontServiceScript.normalize_update3_profile(restored)
	_expect(normalized.get("recent_run_summaries", []).size() == 5 and int(normalized.get("fronts", {}).get("mastery", {}).get(FrontServiceScript.HERO_FRONT_ID, 0)) == 100, "profile JSON 저장·복원 뒤 연대기 기록 보존")


func _test_view_model_and_hints() -> void:
	var profile := FrontServiceScript.default_update3_profile()
	var model := ChronicleServiceScript.build_view_model(profile, _catalogs(), DataRegistry.update3_chronicle_goals)
	_expect(model.get("fronts", []).size() == 3 and model.get("hearts", []).size() == 3 and model.get("rivals", []).size() == 3, "전선·심장·라이벌 전체 항목 구성")
	_expect(model.get("links", []).size() == 6 and model.get("epilogues", []).size() == 3, "합동 기억 6종·후일담 카드 3종 구성")
	var holy: Dictionary = model.get("fronts", [])[1]
	var guild: Dictionary = model.get("fronts", [])[2]
	_expect(str(holy.get("lock_hint", "")).contains("셀렌 관계 45") and str(guild.get("lock_hint", "")).contains("로만 관계 45"), "대체 전선 잠금 힌트가 실제 해금 관계 수치와 일치")
	for entry_value in model.get("links", []):
		var hint := str(entry_value.get("lock_hint", ""))
		_expect(hint.contains("유대 각 45") and hint.contains("3일 동시 출전") and hint.contains("역할 합동 5회"), "%s 합동 기억 잠금 조건 정확" % str(entry_value.get("name", "")))


func _test_responsive_screen() -> void:
	for viewport_size in [Vector2(1920, 1080), Vector2(1366, 768)]:
		var host := Control.new()
		host.size = viewport_size
		add_child(host)
		var screen = ChronicleScreenScene.instantiate()
		screen.set_physical_width_override_for_tests(viewport_size.x)
		screen.setup(FrontServiceScript.default_update3_profile(), _catalogs(), DataRegistry.update3_chronicle_goals)
		host.add_child(screen)
		await get_tree().process_frame
		await get_tree().process_frame
		var contract: Dictionary = screen.layout_contract(viewport_size)
		_expect(_rects_inside(contract, viewport_size) and _no_overlaps(contract), "%dx%d 연대기 배치 화면 내부·비겹침" % [int(viewport_size.x), int(viewport_size.y)])
		if viewport_size.x >= 1600:
			_expect(screen.layout_mode_for_viewport(viewport_size) == "three_columns" and screen.get_node_or_null("ChronicleCanvas/ChroniclePage2") != null, "1920 해상도 3열 연대기 UI")
			_expect(screen.get_node_or_null("ChronicleCanvas/ChronicleTab0") == null, "1920 해상도에는 불필요한 탭 숨김")
		else:
			_expect(screen.layout_mode_for_viewport(viewport_size) == "tabs" and screen.get_node_or_null("ChronicleCanvas/ChronicleTab2") != null, "1366 해상도 3탭 연대기 UI")
			_expect(screen.get_node_or_null("ChronicleCanvas/ChroniclePage0") != null and screen.get_node_or_null("ChronicleCanvas/ChroniclePage1") == null, "1366 해상도는 선택 탭 한 페이지만 표시")
		host.queue_free()
		await get_tree().process_frame


func _test_game_root_flow() -> void:
	var host = MainScene.instantiate()
	add_child(host)
	await get_tree().process_frame
	var game = host.get_node("GameRoot")
	game._set_campaign_save_path_for_tests("")
	game._debug_skip_onboarding()
	game._open_chronicle()
	await get_tree().process_frame
	_expect(game.current_screen == Constants.SCREEN_CHRONICLE and game.ui_layer.get_node_or_null("ChronicleScreen") != null, "실제 관리 흐름에서 전선 연대기 화면 진입")
	var close_button: Button = game.ui_layer.get_node("ChronicleScreen/ChronicleCanvas/ChronicleCloseButton")
	close_button.pressed.emit()
	await get_tree().process_frame
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "연대기 돌아가기 후 관리 화면 복귀")
	host.queue_free()


func _catalogs() -> Dictionary:
	return {"fronts": DataRegistry.update3_fronts, "castle_hearts": DataRegistry.update3_castle_hearts, "duo_links": DataRegistry.update3_duo_links}


func _rects_inside(rects: Dictionary, viewport_size: Vector2) -> bool:
	var bounds := Rect2(Vector2.ZERO, viewport_size)
	for rect_value in rects.values():
		if not bounds.encloses(rect_value):
			return false
	return true


func _no_overlaps(rects: Dictionary) -> bool:
	var values := rects.values()
	for first in range(values.size()):
		for second in range(first + 1, values.size()):
			if values[first].intersects(values[second]):
				return false
	return true


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[ChroniclePhase26] FAIL: %s" % message)
