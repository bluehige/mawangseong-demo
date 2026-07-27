extends Node

const ResultScene = preload("res://scenes/v20/ui/V20ResultScreen.tscn")

var failed := false
var assertion_count := 0
var received_actions: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	for viewport_size in [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1920, 1080)]:
		await _test_loss_layout(viewport_size)
	await _test_victory_and_actions()
	if OS.get_cmdline_user_args().has("--capture-v20-results") and DisplayServer.get_name() != "headless":
		await _capture_results()
	if failed:
		print("V20_RESULT_SCREEN_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V20_RESULT_SCREEN_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_loss_layout(viewport_size: Vector2i) -> void:
	var host := Control.new()
	host.size = viewport_size
	add_child(host)
	var screen = ResultScene.instantiate()
	host.add_child(screen)
	await get_tree().process_frame
	screen.setup(_loss_result(), 3)
	await get_tree().process_frame
	var title: Label = screen.get_node_or_null("ResultBackdrop/ResultHeader/ResultTitleValue")
	var cause: Label = screen.get_node_or_null("ResultBackdrop/OutcomeSummary/PrimaryCauseValue")
	_expect(title != null and title.text == "방어 실패", "%dx%d 패배 제목 즉시 표시" % [viewport_size.x, viewport_size.y])
	_expect(cause != null and "100" in cause.text and "보물 방어 목표" in cause.text, "%dx%d 실제 도난 수치와 필수 실패 원인을 1순위 표시" % [viewport_size.x, viewport_size.y])
	_expect(screen.get_node_or_null("ResultBackdrop/OutcomeSummary/HighlightSummary/PrimaryHighlightValue") != null and screen.get_node_or_null("ResultBackdrop/OutcomeSummary/GuidanceSummary/PrimaryGuidanceValue") != null, "%dx%d 잘한 점·다음에 바꿀 점 각 1개" % [viewport_size.x, viewport_size.y])
	_expect(_primary_metric_count(screen) == 3, "%dx%d 1차 지표를 왕좌 피해·첫 교전·정산 3개로 제한" % [viewport_size.x, viewport_size.y])
	_expect(_metric_value(screen, 0) == "220" and _metric_value(screen, 1) == "가시 회랑" and _metric_value(screen, 2) == "+80", "%dx%d 1차 지표가 실제 evidence·정산과 일치" % [viewport_size.x, viewport_size.y])
	var edit: Button = screen.get_node_or_null("ResultBackdrop/ResultActionDock/V20RetryEditButton")
	var same: Button = screen.get_node_or_null("ResultBackdrop/ResultActionDock/V20RetrySameButton")
	_expect(edit != null and same != null and edit.size.x > same.size.x and "배치 수정" in edit.text, "%dx%d 패배 주 행동은 더 큰 배치 수정" % [viewport_size.x, viewport_size.y])
	_expect(screen.get_node_or_null("ResultBackdrop/ResultDetails") == null, "%dx%d 상세 기록 기본 접힘" % [viewport_size.x, viewport_size.y])
	_expect(screen.find_child("ContributionLedger", true, false) == null and screen.find_child("RunSummary", true, false) == null and screen.find_child("StoryCard_*", true, false) == null, "%dx%d 상시 장부·수비 방식·3대형 카드 제거" % [viewport_size.x, viewport_size.y])
	_expect(not _node_contains_text(screen, "결산 원인을 확인하세요"), "%dx%d 원인 없는 일반 문구 미노출" % [viewport_size.x, viewport_size.y])
	_expect(_all_controls_inside(screen, Rect2(Vector2.ZERO, viewport_size)), "%dx%d 결과 UI 화면 내부" % [viewport_size.x, viewport_size.y])
	var toggle: Button = screen.get_node_or_null("ResultBackdrop/ResultActionDock/V20ResultDetailsToggle")
	if toggle != null:
		toggle.pressed.emit()
	await get_tree().process_frame
	var details: Panel = screen.get_node_or_null("ResultBackdrop/ResultDetails")
	_expect(details != null and _node_contains_text(details, "63.2초") and _node_contains_text(details, "효과 8회") and _node_contains_text(details, "1340"), "%dx%d 상세 펼침에 전투 시간·시설 기여·몬스터 피해 실제 수치" % [viewport_size.x, viewport_size.y])
	_expect(details != null and _node_contains_text(details, "2회 · 2점") and _node_contains_text(details, "도난 100") and _node_contains_text(details, "120 · -40 · +80"), "%dx%d 상세 펼침에 명령·실패 지표·보상/수리/정산" % [viewport_size.x, viewport_size.y])
	host.queue_free()
	await get_tree().process_frame


func _test_victory_and_actions() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_child(host)
	var screen = ResultScene.instantiate()
	host.add_child(screen)
	await get_tree().process_frame
	screen.setup(_win_result(), 2)
	screen.action_requested.connect(_record_action)
	await get_tree().process_frame
	var cause: Label = screen.get_node_or_null("ResultBackdrop/OutcomeSummary/PrimaryCauseValue")
	_expect(cause != null and "성문 전초" in cause.text and "12.3초" in cause.text, "승리 원인은 실제 첫 교전 구역·전선 유지 시간과 일치")
	_expect(screen.get_node_or_null("ResultBackdrop/ResultActionDock/V20RetryEditButton") == null and screen.get_node_or_null("ResultBackdrop/ResultActionDock/V20RetrySameButton") == null, "승리 결과에 재도전 행동 미노출")
	var next_button: Button = screen.get_node_or_null("ResultBackdrop/ResultActionDock/V20ResultActionButton")
	_expect(next_button != null and "다음 침입 확인" in next_button.text, "승리 주 행동은 다음 침입 확인 하나")
	if next_button != null:
		next_button.pressed.emit()
	_expect(received_actions == ["next_day"], "승리 다음 침입 signal 전달")
	screen.setup(_loss_result(), 3)
	await get_tree().process_frame
	var edit: Button = screen.get_node_or_null("ResultBackdrop/ResultActionDock/V20RetryEditButton")
	var same: Button = screen.get_node_or_null("ResultBackdrop/ResultActionDock/V20RetrySameButton")
	if edit != null:
		edit.pressed.emit()
	if same != null:
		same.pressed.emit()
	_expect(received_actions.slice(1) == ["retry_edit", "retry_same"], "패배 배치 수정·같은 배치 재도전 signal 전달")
	host.queue_free()
	await get_tree().process_frame


func _capture_results() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var screen = ResultScene.instantiate()
	viewport.add_child(screen)
	await get_tree().process_frame
	screen.setup(_loss_result(), 3)
	await get_tree().process_frame
	await _save_capture(viewport, "user://v20_u4_result_loss_1280x720.png", "U4 패배 결과 1280×720 실제 렌더", "V20_U4_LOSS_CAPTURE")
	var toggle: Button = screen.get_node_or_null("ResultBackdrop/ResultActionDock/V20ResultDetailsToggle")
	if toggle != null:
		toggle.pressed.emit()
	await get_tree().process_frame
	await _save_capture(viewport, "user://v20_u4_result_loss_details_1280x720.png", "U4 패배 상세 1280×720 실제 렌더", "V20_U4_LOSS_DETAILS_CAPTURE")
	screen.setup(_win_result(), 2)
	await get_tree().process_frame
	await _save_capture(viewport, "user://v20_u4_result_win_1280x720.png", "U4 승리 결과 1280×720 실제 렌더", "V20_U4_WIN_CAPTURE")
	viewport.queue_free()
	await get_tree().process_frame


func _save_capture(viewport: SubViewport, path: String, message: String, marker: String) -> void:
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var error := image.save_png(path) if image != null and not image.is_empty() else ERR_CANT_CREATE
	_expect(error == OK, message)
	if error == OK:
		print("%s: %s" % [marker, ProjectSettings.globalize_path(path)])


func _loss_result() -> Dictionary:
	return {
		"win": false,
		"v20_required_objective_failure": "protect_treasure",
		"v20": {
			"cause": "일반 원인",
			"highlight": "일반 잘한 점",
			"guidance": "일반 다음 행동",
			"gross_income": 120,
			"repair_cost": 40,
			"net_income": 80
		},
		"metrics": {
			"combat_time": 63.2,
			"alive_monsters": 1,
			"total_monsters": 3,
			"remaining_monster_hp": 82,
			"total_monster_hp": 440,
			"demon_lord_hp": 1280,
			"demon_lord_hp_max": 1500,
			"treasure_gold_stolen": 100,
			"facility_disables": 1,
			"v20_command_points_spent": 2,
			"v20_evidence": {
				"first_engagement_zone": "spike_corridor",
				"frontline_hold_seconds": 7.4,
				"throne_damage": 220,
				"throne_max_hp": 1500,
				"gold_stolen": 100,
				"max_contiguous_facility_disabled_seconds": 7.0,
				"fallback_breaches": 1,
				"second_phase_leaks": 0,
				"facility_effect_events": 8,
				"monster_damage_total": 1340,
				"monster_end_hp": 82,
				"monster_start_max_hp": 440,
				"command_events": [{"command_id": "v20_rally"}, {"command_id": "v20_focus"}]
			}
		}
	}


func _win_result() -> Dictionary:
	return {
		"win": true,
		"v20": {
			"cause": "목표를 지켰습니다.",
			"highlight": "몬스터가 버텼습니다.",
			"guidance": "현재 배치를 유지하고 다음 날 목표에 맞춰 한 곳만 조정하세요.",
			"gross_income": 110,
			"repair_cost": 10,
			"net_income": 100
		},
		"metrics": {
			"combat_time": 52.0,
			"alive_monsters": 3,
			"total_monsters": 3,
			"demon_lord_hp": 1500,
			"demon_lord_hp_max": 1500,
			"v20_command_points_spent": 1,
			"v20_evidence": {
				"first_engagement_zone": "gate_outpost",
				"frontline_hold_seconds": 12.3,
				"throne_damage": 0,
				"facility_effect_events": 6,
				"monster_damage_total": 1540,
				"monster_end_hp": 380,
				"monster_start_max_hp": 440,
				"command_events": [{"command_id": "v20_focus"}]
			}
		}
	}


func _primary_metric_count(screen: Node) -> int:
	var count := 0
	for index in range(6):
		if screen.get_node_or_null("ResultBackdrop/OutcomeSummary/PrimaryMetric_%d" % index) != null:
			count += 1
	return count


func _metric_value(screen: Node, index: int) -> String:
	var value: Label = screen.get_node_or_null("ResultBackdrop/OutcomeSummary/PrimaryMetric_%d/MetricValue" % index)
	return str(value.text) if value != null else ""


func _node_contains_text(node: Node, text_value: String) -> bool:
	if node is Label and text_value in str(node.text):
		return true
	if node is Button and text_value in str(node.text):
		return true
	for child in node.get_children():
		if _node_contains_text(child, text_value):
			return true
	return false


func _all_controls_inside(node: Node, bounds: Rect2) -> bool:
	if node is Control and node.visible:
		var rect: Rect2 = node.get_global_rect()
		if rect.size.x > 0.0 and rect.size.y > 0.0 and not bounds.encloses(rect):
			return false
	for child in node.get_children():
		if not _all_controls_inside(child, bounds):
			return false
	return true


func _record_action(action_id: String) -> void:
	received_actions.append(action_id)


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[V20ResultScreen] FAIL: %s" % message)
