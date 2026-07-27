extends Node

const HUDScene = preload("res://scenes/v20/ui/V20InformationHUD.tscn")
const HUDScript = preload("res://scripts/v20/ui/V20InformationHUD.gd")
const TitleScene = preload("res://scenes/v20/ui/V20TitleEntryPanel.tscn")
const TitleScript = preload("res://scripts/v20/ui/V20TitleEntryPanel.gd")
const UITheme = preload("res://scripts/v20/ui/V20UITheme.gd")
const CommandService = preload("res://scripts/v20/commands/V20CommandService.gd")
const EncounterService = preload("res://scripts/v20/encounters/V20EncounterService.gd")

var failed := false
var assertion_count := 0
var received_actions: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_theme_contract()
	await _test_title_entry()
	for viewport_size in [Vector2(1280, 720), Vector2(1366, 768), Vector2(1920, 1080)]:
		await _test_intrusion_brief_layout(viewport_size)
		await _test_management_layout(viewport_size)
		await _test_combat_layout(viewport_size)
	await _test_action_signals()
	_test_actionable_encounter_prompts()
	if OS.get_cmdline_user_args().has("--capture-v20-ui") and DisplayServer.get_name() != "headless":
		await _capture_ui("management", Vector2i(1280, 720), false)
		await _capture_ui("combat", Vector2i(1280, 720), false)
	if OS.get_cmdline_user_args().has("--capture-v20-ui-foundation") and DisplayServer.get_name() != "headless":
		for viewport_size in [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1920, 1080)]:
			await _capture_foundation_ui(viewport_size)
	if failed:
		print("V20_INFORMATION_ARCHITECTURE_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V20_INFORMATION_ARCHITECTURE_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_theme_contract() -> void:
	_expect(UITheme.FONT_TITLE >= 20 and UITheme.FONT_VALUE >= 18 and UITheme.FONT_BUTTON >= 15 and UITheme.FONT_BODY >= 13 and UITheme.FONT_SUPPORT >= 11, "공통 UI theme 최소 글꼴 규격")
	_expect(UITheme.BUTTON_MIN_HEIGHT >= 40.0 and UITheme.SCREEN_MARGIN >= 15.0 and UITheme.PANEL_GAP >= 8.0, "공통 UI theme 클릭 영역·여백 규격")
	_expect(is_equal_approx(UITheme.responsive_scale(Vector2(1280, 720)), 1.0) and UITheme.responsive_scale(Vector2(1920, 1080)) > 1.0, "1280×720 기준 responsive scale")


func _test_title_entry() -> void:
	var host := _host(Vector2(420, 300))
	var title = TitleScene.instantiate()
	title.size = host.size
	host.add_child(title)
	await get_tree().process_frame
	title.setup("v20_overlord", {"status": "absent"})
	await get_tree().process_frame
	_expect(title.get_node_or_null("Panel/GameTitle") != null and title.get_node("Panel/GameTitle").text == "마왕성", "타이틀 게임명 최상위 표시")
	_expect(title.get_node_or_null("Panel/V20TestSubtitle") != null and title.get_node("Panel/V20TestSubtitle").text == "DAY 1~5 전술 방어 테스트", "타이틀 짧은 테스트 설명")
	_expect(title.find_child("DifficultyHeading", true, false) == null and title.find_child("Difficulty_v20_tactician", true, false) == null, "선택지 하나인 가짜 난이도 UI 제거")
	_expect(_count_group(title, TitleScript.PRIMARY_ACTION_GROUP) == 1 and _button_count(title) == 1, "저장 없음 타이틀 주 행동 하나")
	var start_button: Button = title.get_node_or_null("Panel/V20NewSessionButton")
	_expect(start_button != null and start_button.text == "새 테스트 시작" and start_button.size.y >= UITheme.BUTTON_MIN_HEIGHT and start_button.focus_mode == Control.FOCUS_ALL, "새 테스트 시작 가독성·키보드 포커스")
	_expect(title.get_node_or_null("Panel/V20ContinueButton") == null and title.get_node_or_null("Panel/ContinueUnavailableHint") != null, "저장 없음 이어하기 숨김과 사유 표시")
	title.setup("v20_story", {"status": "valid", "summary": {"day": 3}})
	await get_tree().process_frame
	var continue_button: Button = title.get_node_or_null("Panel/V20ContinueButton")
	_expect(continue_button != null and continue_button.text == "이어하기 · DAY 3" and not continue_button.disabled, "유효 저장에만 이어하기 표시")
	_expect(_count_group(title, TitleScript.PRIMARY_ACTION_GROUP) == 1 and _button_count(title) == 2, "유효 저장 타이틀 주 행동 하나·보조 행동 하나")
	host.queue_free()
	await get_tree().process_frame


func _test_intrusion_brief_layout(viewport_size: Vector2) -> void:
	var host := _host(viewport_size)
	var hud = HUDScene.instantiate()
	host.add_child(hud)
	await get_tree().process_frame
	hud.setup("management", _intrusion_state())
	await get_tree().process_frame
	_expect(hud.get_node_or_null("BuildResources") == null and hud.get_node_or_null("IntrusionBrief") != null and hud.get_node_or_null("DayBadge") != null, "%dx%d 침입 화면 DAY·브리핑만 상단 표시" % [int(viewport_size.x), int(viewport_size.y)])
	_expect(hud.get_node_or_null("StrategyBoardWorkspace/IntrusionEnemyPortrait") != null and hud.get_node_or_null("StrategyBoardWorkspace/IntrusionEnemyName") != null, "%dx%d 적 대표 이미지·이름 표시" % [int(viewport_size.x), int(viewport_size.y)])
	_expect(hud.get_node_or_null("StrategyBoardWorkspace/IntrusionGoal") != null and hud.get_node_or_null("StrategyBoardWorkspace/IntrusionRouteOrder") != null and hud.get_node_or_null("StrategyBoardWorkspace/IntrusionWarning") != null, "%dx%d 적 목표·고정 침입 순서·주의 행동 표시" % [int(viewport_size.x), int(viewport_size.y)])
	_expect(_count_group(hud, HUDScript.PRIMARY_ACTION_GROUP) == 1 and _button_count(hud) == 1, "%dx%d 침입 화면 경쟁 행동 없이 배치 시작 하나" % [int(viewport_size.x), int(viewport_size.y)])
	var begin_button: Button = hud.get_node_or_null("ManagementActionDock/V20PrimaryActionButton")
	_expect(begin_button != null and begin_button.text.begins_with("배치 시작") and begin_button.size.y >= UITheme.BUTTON_MIN_HEIGHT and begin_button.get_theme_font_size("font_size") >= UITheme.FONT_BUTTON, "%dx%d 배치 시작 최소 클릭·글꼴 크기" % [int(viewport_size.x), int(viewport_size.y)])
	host.queue_free()
	await get_tree().process_frame


func _test_management_layout(viewport_size: Vector2) -> void:
	var host := _host(viewport_size)
	var hud = HUDScene.instantiate()
	host.add_child(hud)
	await get_tree().process_frame
	hud.setup("management", _management_state(false))
	await get_tree().process_frame
	var board = hud.show_placement_board(_sample_placement_state(), DataRegistry.v20_facilities)
	await get_tree().process_frame
	var rects: Dictionary = hud.layout_rects_for_viewport(viewport_size, "management", false)
	_expect(_rects_inside(rects, viewport_size), "%dx%d 관리 HUD 화면 내부" % [int(viewport_size.x), int(viewport_size.y)])
	_expect(_non_overlapping(rects, [["intrusion", "resources"], ["resources", "day"], ["workspace", "actions"]]), "%dx%d 관리 HUD 핵심 영역 비겹침" % [int(viewport_size.x), int(viewport_size.y)])
	_expect(_count_group(hud, HUDScript.PRIMARY_ACTION_GROUP) == 1, "%dx%d 관리 상시 주 행동을 방어 시작 하나로 제한" % [int(viewport_size.x), int(viewport_size.y)])
	var undo_button: Button = hud.get_node_or_null("ManagementActionDock/UndoPlacement")
	var placement_status: Label = hud.get_node_or_null("ManagementActionDock/PlacementStatus")
	_expect(undo_button != null and undo_button.size.y >= UITheme.BUTTON_MIN_HEIGHT and placement_status != null, "%dx%d 하단에 보조 되돌리기·배치 상태 표시" % [int(viewport_size.x), int(viewport_size.y)])
	hud.update_placement_status(false, ["imp.required_placement_missing"], true, 7)
	var start_button: Button = hud.get_node_or_null("ManagementActionDock/V20PrimaryActionButton")
	_expect(start_button != null and start_button.disabled and undo_button.disabled == false and placement_status.text == "임프를 몬스터 슬롯에 배치하세요.", "%dx%d 방어 시작 차단 이유·되돌리기 가능 상태 실시간 반영" % [int(viewport_size.x), int(viewport_size.y)])
	_expect(hud.get_node_or_null("StrategyBoardWorkspace") != null and hud.get_node_or_null("ContextDrawer") == null, "%dx%d 전략 보드 전체 폭·건물 설정 드로어 미노출" % [int(viewport_size.x), int(viewport_size.y)])
	_expect(board != null and str(board.board_data.get("route_mode", "")) == "fixed" and board.get_node_or_null("RouteMap/FixedRouteHeader") != null, "%dx%d 마왕성 배경 위 확정 침입로" % [int(viewport_size.x), int(viewport_size.y)])
	_expect(board.get_node_or_null("ThreatRail") == null and board.get_node_or_null("PlacementSteps") == null and board.get_node_or_null("RoomInspector") == null, "%dx%d 중복 위협 패널·단계 리본·상시 설정창 제거" % [int(viewport_size.x), int(viewport_size.y)])
	var map_before: Rect2 = board._map_rect
	board.selected_room_id = "spike_corridor"
	board._rebuild()
	_expect(board._map_rect == map_before and board.get_node_or_null("PlacementToolTray/SectionSummary") != null, "%dx%d 위치 선택 시 지도 고정·오른쪽 요약만 갱신" % [int(viewport_size.x), int(viewport_size.y)])
	_expect(_forbidden_panels_absent(hud), "%dx%d 방 목록·로그·대형 상세 상시 패널 없음" % [int(viewport_size.x), int(viewport_size.y)])
	host.queue_free()
	await get_tree().process_frame


func _test_combat_layout(viewport_size: Vector2) -> void:
	var host := _host(viewport_size)
	var hud = HUDScene.instantiate()
	host.add_child(hud)
	await get_tree().process_frame
	var state := _combat_state(viewport_size.x <= 1366.0)
	hud.setup("combat", state)
	await get_tree().process_frame
	var rects: Dictionary = hud.layout_rects_for_viewport(viewport_size, "combat", bool(state.get("drawer_open", false)))
	var overlap_pairs := [["commands", "speed"], ["workspace", "commands"], ["workspace", "speed"]]
	if bool(state.get("drawer_open", false)):
		overlap_pairs.append(["workspace", "drawer"])
		overlap_pairs.append(["drawer", "commands"])
		overlap_pairs.append(["drawer", "speed"])
	_expect(_rects_inside(rects, viewport_size), "%dx%d 전투 HUD 화면 내부" % [int(viewport_size.x), int(viewport_size.y)])
	_expect(_non_overlapping(rects, overlap_pairs), "%dx%d 전투 HUD 핵심 영역 비겹침" % [int(viewport_size.x), int(viewport_size.y)])
	var command_count := _count_group(hud, HUDScript.TACTICAL_COMMAND_GROUP)
	_expect(command_count == 4, "%dx%d 압축 전술 명령 4개 접근 가능" % [int(viewport_size.x), int(viewport_size.y)])
	_expect(hud.get_node_or_null("CombatHeader/ObjectiveLabelValue") != null and hud.get_node_or_null("CombatHeader/ObjectiveHpValue") != null and hud.get_node_or_null("NextPattern") != null and hud.get_node_or_null("SpeedDock") != null and hud.get_node_or_null("CoreObjective") == null, "%dx%d 상단 목표·조건부 위협·작은 속도 컨트롤과 좌측 대형 패널 제거" % [int(viewport_size.x), int(viewport_size.y)])
	var workspace: Panel = hud.get_node_or_null("CombatWorkspace")
	var workspace_style := workspace.get_theme_stylebox("panel") as StyleBoxFlat if workspace != null else null
	_expect(workspace_style != null and workspace_style.bg_color.a <= 0.02, "%dx%d 전장 검정 덮개 제거" % [int(viewport_size.x), int(viewport_size.y)])
	var active_stage: Panel = hud.get_node_or_null("DefenseStageStrip/DefenseStage_0")
	_expect(_count_group(hud, HUDScript.DEFENSE_STAGE_GROUP) == 4 and active_stage != null and bool(active_stage.get_meta("active", false)) and "교전" in str(active_stage.get_node("StageStatus").text), "%dx%d 한 줄 4단계 strip·현재 구역 강조" % [int(viewport_size.x), int(viewport_size.y)])
	var rally_button: Button = hud.get_node_or_null("TacticalCommandDock/Command_v20_rally")
	var focus_button: Button = hud.get_node_or_null("TacticalCommandDock/Command_v20_focus")
	var facility_button: Button = hud.get_node_or_null("TacticalCommandDock/Command_v20_activate_facility")
	var fallback_button: Button = hud.get_node_or_null("TacticalCommandDock/Command_v20_emergency_fallback")
	_expect(rally_button != null and rally_button.size.y >= UITheme.BUTTON_MIN_HEIGHT and "집결" in rally_button.text and "사용 가능" not in rally_button.text and "방 클릭" not in rally_button.text and focus_button != null and "집중" in focus_button.text and "피해" not in focus_button.text, "%dx%d 기본 명령 버튼은 표식·이름·비용만 표시하고 정상 상태 문구 생략" % [int(viewport_size.x), int(viewport_size.y)])
	_expect(facility_button != null and fallback_button != null and hud.get_node_or_null("SelectedTarget") == null and hud.get_node_or_null("CoreObjective/SelectedTarget") == null, "%dx%d 네 기능 유지·빈 선택 대상 정보 미노출" % [int(viewport_size.x), int(viewport_size.y)])
	_expect(rects["speed"].size.x <= 208.0 and rects["commands"].size.x <= 980.0 and rects["commands"].size.y <= 72.0 and rects["stages"].size.x <= 900.0, "%dx%d 배속·명령·단계 UI 최대 폭과 높이 제한" % [int(viewport_size.x), int(viewport_size.y)])
	_expect(rects["speed"].size.x < rects["header"].size.x and rects["commands"].size.y < rects["workspace"].size.y * 0.16, "%dx%d 속도·명령 UI가 전장보다 낮은 시각 비중" % [int(viewport_size.x), int(viewport_size.y)])
	var command_dock := hud.get_node_or_null("TacticalCommandDock")
	var command_dock_id := command_dock.get_instance_id() if command_dock != null else 0
	var command_state := CommandService.new_state(DataRegistry.v20_commands)
	hud.set_command_state(CommandService.command_rows(command_state, DataRegistry.v20_commands), 3, 3)
	_expect(hud.get_node_or_null("TacticalCommandDock") != null and hud.get_node("TacticalCommandDock").get_instance_id() == command_dock_id, "%dx%d 전투 수치 갱신 시 HUD 트리 유지" % [int(viewport_size.x), int(viewport_size.y)])
	var stage_strip_id := hud.get_node("DefenseStageStrip").get_instance_id()
	hud.set_defense_stage_state({
		"active_stage_label": "2차 · 가시 회랑",
		"defense_stages": [
			{"id": "gate_outpost", "label": "1차 · 성문 전초", "status": "돌파"},
			{"id": "spike_corridor", "label": "2차 · 가시 회랑", "status": "교전", "active": true},
			{"id": "central_battle_room", "label": "3차 · 중앙 전투실", "status": "대기"},
			{"id": "throne_anteroom", "label": "4차 · 왕좌 전실", "status": "대기"}
		]
	})
	var updated_stage: Panel = hud.get_node("DefenseStageStrip/DefenseStage_1")
	_expect(hud.get_node("DefenseStageStrip").get_instance_id() == stage_strip_id and bool(updated_stage.get_meta("active", false)) and "가시 회랑" in str(updated_stage.get_node("StageLabel").text), "%dx%d 방어 구간 상태 갱신 시 compact strip 유지" % [int(viewport_size.x), int(viewport_size.y)])
	hud.set_encounter_status({"threat_active": false}, false)
	_expect(hud.get_node_or_null("NextPattern") == null, "%dx%d 실제 위협이 없으면 예고 패널 제거" % [int(viewport_size.x), int(viewport_size.y)])
	hud.set_encounter_status({"threat_active": true, "pattern_title": "시설 무력화", "pattern_eta": "3.2초", "recommended_command_label": "집중", "recommended_target_label": "공병"}, false)
	var recommendation: Label = hud.get_node_or_null("NextPattern/PatternRecommendationValue")
	_expect(recommendation != null and "집중" in recommendation.text and "공병" in recommendation.text, "%dx%d 위협 발생 시 행동·시간·권장 명령·대상만 표시" % [int(viewport_size.x), int(viewport_size.y)])
	hud.set_targeting_state("v20_focus", "집중", "enemy")
	var target_prompt: Panel = hud.get_node_or_null("CombatWorkspace/TargetingPrompt")
	_expect(target_prompt != null and _node_contains_text(target_prompt, "적 클릭") and _node_contains_text(target_prompt, "집중 피해") and _node_contains_text(target_prompt, "ESC 취소"), "%dx%d 명령 선택 후 대상·예상 효과·취소 안내 표시" % [int(viewport_size.x), int(viewport_size.y)])
	hud.clear_targeting_state()
	_expect(hud.get_node_or_null("CombatWorkspace/TargetingPrompt") == null, "%dx%d 명령 완료 즉시 대상 안내 제거" % [int(viewport_size.x), int(viewport_size.y)])
	hud.set_objective_state("왕좌 방어", 71, 100)
	hud.set_combat_speed_state(2.0, true)
	_expect("71 / 100" in str(hud.get_node("CombatHeader/ObjectiveHpValue").text) and str(hud.get_node("SpeedDock/CombatSpeed_3").text) == "재개", "%dx%d 왕좌 HP·속도·일시정지 실시간 상태 반영" % [int(viewport_size.x), int(viewport_size.y)])
	_expect(_forbidden_panels_absent(hud), "%dx%d 전투 로그·유닛 목록·대형 상세 상시 패널 없음" % [int(viewport_size.x), int(viewport_size.y)])
	host.queue_free()
	await get_tree().process_frame


func _test_action_signals() -> void:
	var host := _host(Vector2(1280, 720))
	var hud = HUDScene.instantiate()
	host.add_child(hud)
	await get_tree().process_frame
	hud.setup("management", _management_state(false))
	hud.action_requested.connect(_record_action)
	await get_tree().process_frame
	var start_button := _find_button(hud, "방어 시작")
	_expect(start_button != null and start_button.focus_mode == Control.FOCUS_ALL, "주 행동 키보드 포커스 가능")
	if start_button != null:
		start_button.pressed.emit()
	_expect(received_actions.has("start_defense"), "주 행동 signal 전달")
	hud.setup("combat", _combat_state(true))
	await get_tree().process_frame
	var close_button: Button = hud.get_node_or_null("ContextDrawer/ContextDrawerClose")
	if close_button != null:
		close_button.pressed.emit()
	_expect(received_actions.has("close_context"), "전투 중 일시 컨텍스트 드로어 닫기 signal 전달")
	host.queue_free()
	await get_tree().process_frame


func _test_actionable_encounter_prompts() -> void:
	var board: Dictionary = DataRegistry.v20_dungeon_layouts.get("v20_day_01_05_board", {})
	var engineer_encounter: Dictionary = DataRegistry.v20_encounters.get("v20_day_03_engineer_disable", {})
	var engineer_state := EncounterService.new_state(engineer_encounter, board)
	var engineer_status := EncounterService.hud_status(engineer_state, engineer_encounter)
	_expect(str(engineer_status.get("pattern_response", "")) == "지금 할 일: 집중 → 공병 클릭" and str(engineer_status.get("recommended_command_id", "")) == "v20_focus", "공병 예고를 실제 집중 버튼·공병 대상으로 안내")
	var breach_encounter: Dictionary = DataRegistry.v20_encounters.get("v20_day_05_breach_shift", {})
	var breach_state := EncounterService.new_state(breach_encounter, board)
	var breach_status := EncounterService.hud_status(breach_state, breach_encounter)
	_expect(str(breach_status.get("pattern_response", "")) == "지금 할 일: 비상 후퇴 → 왕좌 전실 클릭" and str(breach_status.get("recommended_command_id", "")) == "v20_emergency_fallback", "돌파 예고를 실제 비상 후퇴 버튼·왕좌 전실 대상으로 안내")
	var preview_encounter := {
		"display_name": "예고 수명주기",
		"phases": [{
			"id": "warning",
			"start_seconds": 5.0,
			"telegraph_seconds": 2.0,
			"response_tags": ["focus_target"],
			"special_action": {"id": "disable_first_activated_facility"}
		}]
	}
	var preview_state := EncounterService.new_state(preview_encounter, board)
	_expect(not bool(EncounterService.hud_status(preview_state, preview_encounter).get("threat_active", true)), "실제 예고 전 위협 패널 숨김")
	preview_state = EncounterService.advance(preview_state, 3.1, preview_encounter)
	var preview_status := EncounterService.hud_status(preview_state, preview_encounter)
	_expect(bool(preview_status.get("threat_active", false)) and str(preview_status.get("recommended_command_label", "")) == "집중", "실제 예고 중 위협 패널과 권장 명령 노출")
	preview_state = EncounterService.advance(preview_state, 2.0, preview_encounter)
	_expect(not bool(EncounterService.hud_status(preview_state, preview_encounter).get("threat_active", true)), "패턴 시작 뒤 위협 패널 자동 숨김")


func _capture_ui(mode_value: String, viewport_size: Vector2i, drawer_value: bool) -> void:
	var capture_viewport := SubViewport.new()
	capture_viewport.size = viewport_size
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(capture_viewport)
	var hud = HUDScene.instantiate()
	capture_viewport.add_child(hud)
	await get_tree().process_frame
	hud.setup(mode_value, _management_state(drawer_value) if mode_value == "management" else _combat_state(drawer_value))
	if mode_value == "management":
		hud.show_placement_board(_sample_placement_state(), DataRegistry.v20_facilities)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := capture_viewport.get_texture().get_image()
	var path := "user://v20_phase11s_%s_%dx%d.png" % [mode_value, viewport_size.x, viewport_size.y]
	var error := image.save_png(path) if image != null and not image.is_empty() else ERR_CANT_CREATE
	_expect(error == OK, "%s %dx%d 실제 렌더 캡처" % [mode_value, viewport_size.x, viewport_size.y])
	if error == OK:
		print("V20_PHASE11S_CAPTURE: %s" % ProjectSettings.globalize_path(path))
	if mode_value == "management" and hud.placement_board != null:
		hud.placement_board.selected_room_id = "spike_corridor"
		hud.placement_board._rebuild()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var selected_path := "user://v20_p11s_management_selected_%dx%d.png" % [viewport_size.x, viewport_size.y]
		var selected_error := capture_viewport.get_texture().get_image().save_png(selected_path)
		_expect(selected_error == OK, "management 선택형 상세 %dx%d 실제 렌더" % [viewport_size.x, viewport_size.y])
		if selected_error == OK:
			print("V20_P11S_SELECTED_CAPTURE: %s" % ProjectSettings.globalize_path(selected_path))
	capture_viewport.queue_free()
	await get_tree().process_frame


func _capture_foundation_ui(viewport_size: Vector2i) -> void:
	var capture_viewport := SubViewport.new()
	capture_viewport.size = viewport_size
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(capture_viewport)
	var background := ColorRect.new()
	background.size = viewport_size
	background.color = Color("#07060b")
	capture_viewport.add_child(background)
	var title = TitleScene.instantiate()
	title.size = Vector2(420, 300)
	title.position = (Vector2(viewport_size) - title.size) * 0.5
	capture_viewport.add_child(title)
	title.setup("v20_tactician", {"status": "valid", "summary": {"day": 3}})
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var title_path := "user://v20_u1_title_%dx%d.png" % [viewport_size.x, viewport_size.y]
	var title_error := capture_viewport.get_texture().get_image().save_png(title_path)
	_expect(title_error == OK, "U1 타이틀 %dx%d 실제 렌더" % [viewport_size.x, viewport_size.y])
	if title_error == OK:
		print("V20_U1_TITLE_CAPTURE: %s" % ProjectSettings.globalize_path(title_path))
	title.queue_free()
	await get_tree().process_frame
	var hud = HUDScene.instantiate()
	capture_viewport.add_child(hud)
	await get_tree().process_frame
	hud.setup("management", _intrusion_state())
	await get_tree().create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	var intrusion_path := "user://v20_u1_intrusion_%dx%d.png" % [viewport_size.x, viewport_size.y]
	var intrusion_error := capture_viewport.get_texture().get_image().save_png(intrusion_path)
	_expect(intrusion_error == OK, "U1 침입 확인 %dx%d 실제 렌더" % [viewport_size.x, viewport_size.y])
	if intrusion_error == OK:
		print("V20_U1_INTRUSION_CAPTURE: %s" % ProjectSettings.globalize_path(intrusion_path))
	capture_viewport.queue_free()
	await get_tree().process_frame


func _intrusion_state() -> Dictionary:
	return {
		"day": 3,
		"flow_state": "INTRUSION_BRIEF",
		"intrusion_title": "핵심 시설 무력화",
		"intrusion_enemy_name": "공병 1 · 탐험가 4",
		"intrusion_enemy_portrait": "res://assets/sprites/enemies/enemy_engineer_idle_down_00.png",
		"intrusion_goal": "왕좌를 지킨다 · 시설 한 곳 이상을 가동 상태로 지킨다",
		"intrusion_route_order": "성문 전초 → 가시 회랑 → 중앙 전투실 → 왕좌 전실",
		"intrusion_warning": "공병이 먼저 활성화된 시설을 무력화합니다.",
		"resources": {"build": 10, "command": 3, "command_max": 3}
	}


func _management_state(drawer_value: bool) -> Dictionary:
	return {
		"day": 3,
		"intrusion_title": "공병이 고정 침입로를 따라 진입합니다",
		"intrusion_hint": "확정 경로 성문 → 가시 회랑 → 중앙 전투실 → 왕좌 · 예고 5초",
		"resources": {"build": 7, "command": 3, "command_max": 3},
		"board_hint": "방·문·경로를 지도에서 직접 선택",
		"flow_state": "PLACEMENT",
		"placement_valid": true,
		"drawer_open": drawer_value,
		"context": {
			"eyebrow": "선택한 방",
			"title": "성문 전초",
			"subtitle": "1구간 · 첫 교전 위치",
			"facts": [
				{"label": "예상 적", "value": "공병 1"},
				{"label": "시설", "value": "바리케이드"},
				{"label": "배치", "value": "슬라임 1 / 2"},
				{"label": "구간 효과", "value": "이동 지연"}
			],
			"summary": "길은 그대로이며 이 구간의 교전 시간이 늘어납니다."
		}
	}


func _combat_state(drawer_value: bool) -> Dictionary:
	return {
		"day": 3,
		"objective_label": "왕좌 방어",
		"objective_hp": 82,
		"objective_hp_max": 100,
		"phase_label": "2단계 · 공병 진입",
		"threat_active": true,
		"pattern_title": "시설 무력화",
		"pattern_eta": "4.2초",
		"pattern_response": "지금 할 일: 집중 → 공병 클릭",
		"recommended_command_id": "v20_focus",
		"recommended_command_label": "집중",
		"recommended_target_label": "공병",
		"commands": CommandService.command_rows(CommandService.new_state(DataRegistry.v20_commands), DataRegistry.v20_commands),
		"command_points": 3,
		"command_max": 3,
		"combat_speed": 1.0,
		"combat_paused": false,
		"active_stage_label": "1차 · 성문 전초",
		"defense_stages": [
			{"id": "gate_outpost", "label": "1차 · 성문 전초", "status": "교전", "active": true},
			{"id": "spike_corridor", "label": "2차 · 가시 회랑", "status": "대기"},
			{"id": "central_battle_room", "label": "3차 · 중앙 전투실", "status": "대기"},
			{"id": "throne_anteroom", "label": "4차 · 왕좌 전실", "status": "대기"}
		],
		"drawer_open": drawer_value,
		"context": {
			"eyebrow": "선택 유닛",
			"title": "성문 파수 슬라임",
			"subtitle": "북문 길목 · 차단 역할",
			"facts": [
				{"label": "체력", "value": "74 / 100"},
				{"label": "상태", "value": "문 고정"},
				{"label": "시설", "value": "바리케이드"}
			],
			"summary": "세부 기술과 전체 기록은 일시정지 상태에서 확인합니다."
		},
		"emergency_command": {"id": "release_lock", "label": "봉쇄 해제"}
	}


func _sample_placement_state() -> Dictionary:
	return {
		"schema_version": 1,
		"build_points": 7,
		"rooms": {
			"gate_outpost": {"display_name": "1 · 성문 전초", "section_index": 1, "strategy_hint": "첫 교전", "placement_tags": ["door", "corridor", "room", "bait", "recovery", "overlook"], "facility_slot_id": "gate_outpost_facility", "monster_slot_ids": ["gate_outpost_monster_1", "gate_outpost_monster_2"], "facility_id": "v20_barricade", "capacity": 2, "monster_ids": ["slime_01"]},
			"spike_corridor": {"display_name": "2 · 가시 회랑", "section_index": 2, "strategy_hint": "함정 집중", "placement_tags": ["door", "corridor", "room", "bait", "recovery", "overlook"], "facility_slot_id": "spike_corridor_facility", "monster_slot_ids": ["spike_corridor_monster_1", "spike_corridor_monster_2"], "facility_id": "", "capacity": 2, "monster_ids": []},
			"central_battle_room": {"display_name": "3 · 중앙 전투실", "section_index": 3, "strategy_hint": "중앙 교전", "placement_tags": ["door", "corridor", "room", "bait", "recovery", "overlook"], "facility_slot_id": "central_battle_room_facility", "monster_slot_ids": ["central_battle_room_monster_1", "central_battle_room_monster_2"], "facility_id": "", "capacity": 2, "monster_ids": []},
			"throne_anteroom": {"display_name": "4 · 왕좌 전실", "section_index": 4, "strategy_hint": "최종 방어", "placement_tags": ["door", "corridor", "room", "bait", "recovery", "overlook"], "facility_slot_id": "throne_anteroom_facility", "monster_slot_ids": ["throne_anteroom_monster_1", "throne_anteroom_monster_2"], "facility_id": "", "capacity": 2, "monster_ids": ["imp_01"]}
		},
		"roster": {
			"slime_01": {"display_name": "슬라임", "room_id": "gate_outpost", "monster_slot_id": "gate_outpost_monster_1"},
			"goblin_01": {"display_name": "고블린", "room_id": ""},
			"imp_01": {"display_name": "임프", "room_id": "throne_anteroom", "monster_slot_id": "throne_anteroom_monster_1"}
		},
		"placement_session": {},
		"pending_replacement": {},
		"undo": {},
		"last_action": {"kind": "facility", "target_id": "gate_outpost"}
	}


func _host(host_size: Vector2) -> Control:
	var host := Control.new()
	host.size = host_size
	add_child(host)
	return host


func _rects_inside(rects: Dictionary, viewport_size: Vector2) -> bool:
	var bounds := Rect2(Vector2.ZERO, viewport_size)
	for rect_value in rects.values():
		if not bounds.encloses(rect_value):
			return false
	return true


func _non_overlapping(rects: Dictionary, pairs: Array) -> bool:
	for pair_value in pairs:
		var pair: Array = pair_value
		if rects.has(pair[0]) and rects.has(pair[1]) and rects[pair[0]].intersects(rects[pair[1]]):
			return false
	return true


func _count_group(node: Node, group_name: String) -> int:
	var count := 1 if node.is_in_group(group_name) else 0
	for child in node.get_children():
		count += _count_group(child, group_name)
	return count


func _button_count(node: Node) -> int:
	var count := 1 if node is Button else 0
	for child in node.get_children():
		count += _button_count(child)
	return count


func _node_contains_text(node: Node, text_value: String) -> bool:
	if node is Label and text_value in str(node.text):
		return true
	if node is Button and text_value in str(node.text):
		return true
	for child in node.get_children():
		if _node_contains_text(child, text_value):
			return true
	return false


func _forbidden_panels_absent(node: Node) -> bool:
	for forbidden_name in ["RoomList", "BattleLog", "UnitStatus", "SelectedUnitPanel"]:
		if node.find_child(forbidden_name, true, false) != null:
			return false
	return true


func _find_button(node: Node, text_value: String) -> Button:
	if node is Button and node.text.begins_with(text_value):
		return node
	for child in node.get_children():
		var found := _find_button(child, text_value)
		if found != null:
			return found
	return null


func _record_action(action_id: String) -> void:
	received_actions.append(action_id)


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[V20InformationArchitecture] FAIL: %s" % message)
