extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var game: Node
var output_dir := ""
var failed := false
var review_result_summary: Dictionary = {}
var review_growth_summary: Array = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	output_dir = ProjectSettings.globalize_path("res://tmp/ui_regression_review")
	DirAccess.make_dir_recursive_absolute(output_dir)
	if _running_without_viewport_capture():
		print("UI_REGRESSION_VISUAL_REVIEW_HEADLESS_SKIP: viewport capture requires a rendering display")
		print("UI_REGRESSION_VISUAL_REVIEW: %s" % output_dir)
		get_tree().quit(0)
		return
	var original_text_scale = UISettings.text_scale
	UISettings.set_text_scale(UISettings.DEFAULT_TEXT_SCALE, false)
	game = GameRootScene.instantiate()
	add_child(game)
	await _settle(4)
	game._debug_skip_onboarding()
	GameState.day = 2
	game.monster_roster["goblin"]["growth_preparation_id"] = "pursuit_drill"
	game.monster_roster["goblin"]["growth_preparation_day"] = 2
	game.selected_monster_id = "goblin"
	game._choose_early_specialization("goblin", "goblin_treasure_hunter")
	game._set_screen(Constants.SCREEN_MONSTER)
	await _settle(4)
	await _save("01_monster_screen.png")

	game._set_screen(Constants.SCREEN_MANAGEMENT)
	game._build_selected_slot()
	game._select_build_target_room("slot_01")
	await _settle(4)
	await _save("02_management_build.png")
	game._select_build_target_room("throne")
	await _settle(4)
	await _save("02b_management_build_blocked.png")
	game._select_build_target_room("slot_01")
	await _settle(4)

	game.result_summary = {
		"win": true,
		"lines": [
			"DAY 2 방어 성공.",
			"격퇴한 적: 3 / 스폰: 3",
			"전투 시간: 20.4초 / 생존 몬스터: 3/3",
			"잔여 전력: HP 324 / 440",
			"획득 금화: 198",
			"획득 마력: 60",
			"증가 악명: 15",
			"마왕성 체력: 1500 / 1500",
			"지침 효과: 사수 피해 감소 5 / 총공격 추가 피해 +17",
			"시설 기여: 발동 없음 (방 동선과 몬스터 배치를 확인하세요)"
		]
	}
	game.result_growth_reviewed = false
	game.result_growth_choice_monster_id = ""
	game.result_growth_choice_applied = false
	game.last_growth_choice_summary.clear()
	game.last_growth_summary = [
		{
			"monster_id": "slime",
			"display_name": "슬라임",
			"level_before": 1,
			"level_after": 1,
			"levels_gained": 0,
			"exp_after": 33,
			"exp_gain": 25,
			"next_exp": 50,
			"shared_exp": 22,
			"activity_exp": 3,
			"activity_breakdown": {"attack": 1, "defense": 2}
		},
		{
			"monster_id": "goblin",
			"display_name": "고블린",
			"level_before": 1,
			"level_after": 1,
			"levels_gained": 0,
			"exp_after": 45,
			"exp_gain": 27,
			"next_exp": 50,
			"shared_exp": 22,
			"activity_exp": 5,
			"activity_breakdown": {"attack": 2, "defense": 1, "finisher": 1, "facility": 1}
		},
		{
			"monster_id": "imp",
			"display_name": "임프",
			"level_before": 1,
			"level_after": 1,
			"levels_gained": 0,
			"exp_after": 34,
			"exp_gain": 27,
			"next_exp": 50,
			"shared_exp": 22,
			"activity_exp": 5,
			"activity_breakdown": {"attack": 1, "defense": 2, "finisher": 1, "facility": 1}
		}
	]
	game.result_summary["growth"] = game.last_growth_summary.duplicate(true)
	review_result_summary = game.result_summary.duplicate(true)
	review_growth_summary = game.last_growth_summary.duplicate(true)
	game._set_screen(Constants.SCREEN_RESULT)
	await _settle(5)
	await _save("03_result_screen.png")
	game._choose_result_growth("goblin")
	await _settle(4)
	await _save("03b_result_focus_selected.png")

	game.onboarding_enabled = true
	game.onboarding_dialogue_queue = [{
		"speaker": "CHR_GOLDIN",
		"emotion": "accounting",
		"text": "보상 정산 완료. 악명 +1, 골드 소량. 위엄은 장부상 무형자산입니다. 다음 방어 준비까지 확인하겠습니다."
	}]
	game.onboarding_dialogue_index = 0
	game._set_screen(Constants.SCREEN_DIALOGUE)
	await _settle(5)
	await _save("04_dialogue_screen.png")

	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	GameState.day = 16
	game.raid_selected_mission_id = "d16_route_recon"
	game.completed_raids.erase("d16_route_recon")
	game.completed_raids.erase("d16_supply_ambush")
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle(4)
	await _save("05a_day16_management_choice.png")
	game._open_raid_screen()
	await _settle(4)
	await _save("05b_day16_raid_choice.png")
	game._select_raid_mission("d16_supply_ambush")
	await _settle(4)
	await _save("05c_day16_raid_ambush.png")

	GameState.day = 17
	game.first_promotion_completed = true
	game.completed_raids["d16_route_recon"] = true
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle(4)
	await _save("05d_day17_management.png")
	game._start_combat()
	await _settle(4)
	game._spawn_enemy("thief")
	var day17_thief = game.enemy_units[-1]
	var treasure_room = game._room_by_facility("treasure", "")
	if day17_thief != null and treasure_room != "":
		day17_thief.global_position = game.graph.center(treasure_room) + Vector2(-110, 0)
		day17_thief.current_room = "spike_corridor"
	await _settle(4)
	await _save("05e_day17_combat.png")
	if day17_thief != null and treasure_room != "":
		day17_thief.global_position = game.graph.center(treasure_room)
		day17_thief.current_room = treasure_room
		game.combat_scene.update_room_effects(0.1)
		day17_thief.receive_damage(day17_thief.max_hp + 100)
	game._finish_combat(true, "DAY 17 니아의 두 번째 침투 방어 성공.")
	await _settle(5)
	await _save("05f_day17_security_result.png")

	GameState.day = 18
	GameState.food = 100
	game.last_security_grade = "S"
	game.completed_raids.erase("d18_forged_manifest")
	game.completed_raids.erase("d18_seal_smuggling_tunnel")
	game.next_defense_modifiers.clear()
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle(4)
	await _save("05g_day18_management_choice.png")
	game._open_raid_screen()
	await _settle(4)
	await _save("05h_day18_blockade_choices.png")
	game._select_raid_mission("d18_seal_smuggling_tunnel")
	await _settle(4)
	await _save("05i_day18_tunnel_choice.png")
	game.raid_selected_monster_ids.clear()
	game.raid_selected_monster_ids.append("kobold_scout")
	game._start_selected_raid()
	await _settle(3)
	game._onboarding_finish_raid_preview()
	await _settle(3)
	game._start_combat()
	await _settle(5)
	await _save("05j_day18_tunnel_combat.png")
	game._finish_combat(true, "DAY 18 왕국 봉쇄선 방어 성공.")
	await _settle(3)
	game._continue_from_result()
	await _settle(5)
	await _save("05k_day19_management_tunnel.png")
	game._start_combat()
	await _settle(4)
	game._spawn_enemy("shieldbearer")
	game._spawn_enemy("thief")
	var day19_thief = game.enemy_units[-1]
	if day19_thief != null and treasure_room != "":
		day19_thief.global_position = game.graph.center(treasure_room) + Vector2(-130, 0)
		day19_thief.current_room = "spike_corridor"
	game.combat_time = 30.1
	game._update_campaign_combat_timed_lines()
	await _settle(5)
	await _save("05l_day19_recovery_combat.png")
	if day19_thief != null:
		day19_thief.receive_damage(day19_thief.max_hp + 100)
	game._finish_combat(true, "DAY 19 봉쇄 명령서 수호 성공.")
	await _settle(5)
	await _save("05m_day19_recovery_result.png")
	game._continue_from_result()
	await _settle(5)
	await _save("05n_day20_management_engineer.png")
	game._start_combat()
	await _settle(4)
	game._spawn_enemy("engineer")
	var day20_engineer = game.enemy_units[-1]
	await _settle(4)
	await _save("05o_day20_engineer_target.png")
	if day20_engineer != null:
		var engineer_target_room := str(game.engineer_target_rooms.get(day20_engineer.get_instance_id(), ""))
		if engineer_target_room != "":
			day20_engineer.current_room = engineer_target_room
			day20_engineer.global_position = game.graph.center(engineer_target_room)
			game._update_enemy_path(day20_engineer)
	await _settle(4)
	await _save("05p_day20_facility_disabled.png")
	game._finish_combat(true, "DAY 20 왕국 공병 격퇴 성공.")
	await _settle(5)
	await _save("05q_day20_engineer_result.png")
	game._continue_from_result()
	await _settle(5)
	await _save("05r_day21_management_rally.png")
	game._start_combat()
	await _settle(4)
	game._spawn_enemy("explorer")
	game._spawn_enemy("selen_trainee_paladin")
	game.combat_scene._update_royal_rally(0.1)
	await _settle(3)
	await _save("05s_day21_selen_rally.png")
	var day21_commander = game.enemy_units[-1]
	if day21_commander != null:
		day21_commander.receive_damage(day21_commander.max_hp + 100)
	await _settle(4)
	await _save("05t_day21_rally_stopped.png")
	game._finish_combat(true, "DAY 21 셀렌 진군 지휘 저지 성공.")
	await _settle(5)
	await _save("05u_day21_rally_result.png")

	GameState.day = 2
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	game._start_combat()
	await _settle(5)
	game.onboarding_enabled = true
	game.tutorial_gate_enabled = true
	game._onboarding_set_stage("LV07_DAY02_BATTLE_THIEF")
	for index in range(game.tutorial_manager.steps.size()):
		if str(game.tutorial_manager.steps[index].get("id", "")) == "TUT_130_GOBLIN_CONTROL":
			game.tutorial_manager.current_index = index
			game.tutorial_manager.active = true
			break
	game._tutorial_build_overlay()
	await _settle(5)
	await _save("05_combat_tutorial.png")

	await _capture_scale_review()
	UISettings.set_text_scale(original_text_scale, false)
	DisplayServer.window_set_size(Vector2i(1920, 1080))

	print("UI_REGRESSION_VISUAL_REVIEW: %s" % output_dir)
	get_tree().quit(1 if failed else 0)

func _capture_scale_review() -> void:
	await _set_review_view(Vector2i(1920, 1080), UISettings.MIN_TEXT_SCALE)
	_disable_tutorial_overlay()
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	game._build_selected_slot()
	game._select_build_target_room("slot_01")
	await _settle(4)
	await _save("06_management_scale_90.png")

	await _set_review_view(Vector2i(1920, 1080), UISettings.MAX_TEXT_SCALE)
	_disable_tutorial_overlay()
	game._set_screen(Constants.SCREEN_MONSTER)
	await _settle(4)
	await _save("07_monster_scale_115.png")
	_restore_result_review_state()
	game._set_screen(Constants.SCREEN_RESULT)
	await _settle(4)
	await _save("08_result_scale_115.png")
	game._set_screen(Constants.SCREEN_DIALOGUE)
	await _settle(4)
	await _save("09_dialogue_scale_115.png")
	game._set_screen(Constants.SCREEN_COMBAT)
	game._tutorial_build_overlay()
	await _settle(4)
	await _save("10_combat_scale_115.png")

	await _set_review_view(Vector2i(1366, 768), UISettings.MAX_TEXT_SCALE)
	_disable_tutorial_overlay()
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	game._build_selected_slot()
	game._select_build_target_room("slot_01")
	await _settle(4)
	await _save("11_management_1366_scale_115.png")
	game._select_build_target_room("throne")
	await _settle(4)
	await _save("11b_management_blocked_1366_scale_115.png")
	_restore_result_review_state()
	game._set_screen(Constants.SCREEN_RESULT)
	await _settle(4)
	await _save("12_result_1366_scale_115.png")
	game._choose_result_growth("imp")
	await _settle(4)
	await _save("12b_result_focus_selected_1366_scale_115.png")

	await _capture_final_castle_review()

func _capture_final_castle_review() -> void:
	await _set_review_view(Vector2i(1366, 768), UISettings.MAX_TEXT_SCALE)
	_disable_tutorial_overlay()
	GameState.victory = false
	GameState.defeat = false
	GameState.day = 27
	game.campaign_final_upgrade_ready = false
	game.castle_art_stage = "stage_03_keep"
	game.castle_evolution_history.clear()
	game.castle_evolution_history.append_array(["stage_01_cave", "stage_02_castle", "stage_03_keep"])
	game.last_castle_evolution_day = 20
	game.last_castle_evolution_from_stage = "stage_02_castle"
	game._sync_castle_stage_content()
	game._setup_dungeon_graph()
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle(4)

	_expect(game.castle_art_stage == "stage_03_keep", "DAY 27 전투 전 Stage 03 상태")
	game._start_combat()
	await _settle(4)
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "DAY 27 방어 전투 진입")
	game._finish_combat(true, "DAY 27 성채 심장 방어 성공.")
	await _settle(8)

	_expect(game.current_screen == Constants.SCREEN_RESULT, "DAY 27 승리 직후 결과 화면")
	_expect(game.campaign_final_upgrade_ready, "DAY 27 승리로 최종 강화 조건 활성화")
	_expect(game.castle_art_stage == "stage_04_citadel", "DAY 27 승리 즉시 Stage 04 대마왕성 적용")
	_expect(game.last_castle_evolution_day == 27, "DAY 27 최종 진화 이력 기록")
	_expect(int(game._castle_stage_info().get("area_room_count", 0)) == 11, "Stage 04 전체 11개 구역 확장")
	_expect(game.quarter_renderer.debug_full_grid_room_projection_count() == 11, "Stage 04 11개 구역 렌더 투영")
	_expect(_has_top_level_control_rect(Rect2(560, 174, 800, 46), 8.0), "최종 진화 전용 배너 배치")
	_expect(_has_top_level_control_rect(Rect2(300, 220, 600, 520)), "DAY 27 결산 패널 배치")
	_expect(_has_top_level_control_rect(Rect2(940, 220, 680, 520)), "DAY 27 다음 진행 패널 배치")
	_expect_target_within_design_bounds("NextDayButton", "DAY 27 결과")
	_expect_target_within_design_bounds("GrowthReviewButton", "DAY 27 결과")
	for monster_id in ["slime", "goblin", "imp"]:
		_expect_growth_choice_layout(monster_id, "DAY 27 결과")
	_expect_top_level_layout_within_design_bounds("DAY 27 결과")
	_expect_capture_size(Vector2i(1366, 768), "DAY 27 결과")
	await _save("13_day27_final_evolution_result_1366.png")

	game._continue_from_result()
	await _settle(6)
	_expect(GameState.day == 28, "DAY 27 결산 후 DAY 28 진행")
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "DAY 28 관리 화면 진입")
	_expect(game.castle_art_stage == "stage_04_citadel", "DAY 28 Stage 04 대마왕성 유지")
	_expect(int(game._castle_stage_info().get("area_room_count", 0)) == 11, "DAY 28 확장 구역 11개 유지")
	_expect(game.quarter_renderer.debug_full_grid_room_projection_count() == 11, "DAY 28 관리 화면 11개 구역 렌더 투영")
	_expect_target_within_design_bounds("BuildButton", "DAY 28 관리")
	_expect_target_within_design_bounds("MonsterManagementButton", "DAY 28 관리")
	_expect_target_within_design_bounds("StartCombatButton", "DAY 28 관리")
	_expect_top_level_layout_within_design_bounds("DAY 28 관리")
	_expect_capture_size(Vector2i(1366, 768), "DAY 28 관리")
	await _save("14_day28_stage04_management_1366.png")

	game.selected_room = "slot_03"
	game.facility_change_panel_open = true
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle(4)
	var expected_facility_stats := {
		"barracks": "체력 770 / 배치 7",
		"treasure": "체력 570 / 배치 5",
		"recovery": "체력 670 / 배치 5",
		"watch_post": "체력 700 / 배치 6",
		"ward_core": "체력 740 / 배치 4",
		"build_slot": "체력 200 / 배치 불가"
	}
	for facility_id in expected_facility_stats.keys():
		var stat_label = game.ui_layer.find_child("FacilityChoiceStats_%s" % facility_id, true, false) as Label
		_expect(stat_label != null and stat_label.text == str(expected_facility_stats[facility_id]), "DAY 28 시설 변경 창 %s Stage 04 실제 수치" % facility_id)
	_expect_top_level_layout_within_design_bounds("DAY 28 시설 변경 창")
	_expect_capture_size(Vector2i(1366, 768), "DAY 28 시설 변경 창")
	await _save("15_day28_stage04_facility_modal_1366.png")

func _expect_target_within_design_bounds(target_id: String, screen_label: String) -> void:
	var target = game.tutorial_targets.get(target_id)
	var exists: bool = false
	if target is Rect2:
		var target_rect: Rect2 = target
		exists = target_rect.has_area()
	_expect(exists, "%s %s 컨트롤 존재" % [screen_label, target_id])
	if not exists:
		return
	var rect: Rect2 = target
	_expect(_rect_within_design_bounds(rect), "%s %s 화면 안 배치" % [screen_label, target_id])

func _expect_growth_choice_layout(monster_id: String, screen_label: String) -> void:
	var preview = game.ui_layer.find_child("GrowthChoicePreview_%s" % monster_id, true, false) as Control
	var preparation = game.ui_layer.find_child("GrowthChoicePreparation_%s" % monster_id, true, false) as Control
	var button = game.ui_layer.find_child("GrowthChoice_%s" % monster_id, true, false) as Control
	var controls_exist: bool = preview != null and preparation != null and button != null
	_expect(controls_exist, "%s %s 성장 상태·준비 효과와 집중 버튼 생성" % [screen_label, monster_id])
	if not controls_exist:
		return
	var same_card: bool = preview.get_parent() == button.get_parent() and preparation.get_parent() == button.get_parent()
	_expect(same_card, "%s %s 성장 상태·준비 효과와 집중 버튼이 같은 카드에 배치" % [screen_label, monster_id])
	if not same_card:
		return
	var preview_rect := Rect2(preview.position, preview.size)
	var preparation_rect := Rect2(preparation.position, preparation.size)
	var button_rect := Rect2(button.position, button.size)
	_expect(not preview_rect.intersects(button_rect), "%s %s 성장 상태와 집중 버튼 비겹침" % [screen_label, monster_id])
	_expect(not preparation_rect.intersects(button_rect), "%s %s 준비 효과와 집중 버튼 비겹침" % [screen_label, monster_id])

func _expect_top_level_layout_within_design_bounds(screen_label: String) -> void:
	var checked_count := 0
	var all_within_bounds := true
	for child in game.ui_layer.get_children():
		if not child is Control or not (child as Control).visible:
			continue
		var control := child as Control
		if control.size.x <= 0.0 or control.size.y <= 0.0:
			continue
		checked_count += 1
		if not _rect_within_design_bounds(control.get_global_rect()):
			all_within_bounds = false
			push_error("%s 최상위 UI가 화면 밖입니다: %s %s" % [screen_label, control.name, control.get_global_rect()])
	_expect(checked_count > 0, "%s 최상위 UI 생성" % screen_label)
	_expect(all_within_bounds, "%s 최상위 UI 1920x1080 기준 경계 안 배치" % screen_label)

func _rect_within_design_bounds(rect: Rect2) -> bool:
	const DESIGN_SIZE := Vector2(1920, 1080)
	return (
		rect.position.x >= -1.0
		and rect.position.y >= -1.0
		and rect.end.x <= DESIGN_SIZE.x + 1.0
		and rect.end.y <= DESIGN_SIZE.y + 1.0
	)

func _has_top_level_control_rect(expected: Rect2, tolerance: float = 1.0) -> bool:
	for child in game.ui_layer.get_children():
		if not child is Control or not (child as Control).visible:
			continue
		var actual := (child as Control).get_global_rect()
		if actual.position.distance_to(expected.position) <= tolerance and actual.size.distance_to(expected.size) <= tolerance:
			return true
	return false

func _expect_capture_size(expected_size: Vector2i, screen_label: String) -> void:
	var texture = get_viewport().get_texture()
	var actual_size := Vector2i.ZERO
	if texture != null:
		var image = texture.get_image()
		if image != null and not image.is_empty():
			actual_size = image.get_size()
	var capture_matches := absi(actual_size.x - expected_size.x) <= 1 and absi(actual_size.y - expected_size.y) <= 1
	_expect(DisplayServer.window_get_size() == expected_size, "%s 실행 창 크기 %dx%d" % [screen_label, expected_size.x, expected_size.y])
	_expect(capture_matches, "%s 캡처 크기 %dx%d 호환" % [screen_label, expected_size.x, expected_size.y])

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	push_error("FAIL: %s" % message)
	failed = true

func _disable_tutorial_overlay() -> void:
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game.tutorial_manager.active = false
	game._tutorial_clear_overlay()

func _restore_result_review_state() -> void:
	_disable_tutorial_overlay()
	GameState.victory = false
	GameState.defeat = false
	game.result_summary = review_result_summary.duplicate(true)
	game.last_growth_summary = review_growth_summary.duplicate(true)
	game.result_summary["growth"] = game.last_growth_summary.duplicate(true)
	game.result_growth_reviewed = false
	game.result_growth_choice_monster_id = ""
	game.result_growth_choice_applied = false
	game.last_growth_choice_summary.clear()

func _set_review_view(window_size: Vector2i, text_scale: float) -> void:
	DisplayServer.window_set_size(window_size)
	UISettings.set_text_scale(text_scale, false)
	await _settle(4)

func _settle(frames: int) -> void:
	for _index in range(frames):
		await get_tree().process_frame
		await get_tree().physics_frame

func _running_without_viewport_capture() -> bool:
	return DisplayServer.get_name() == "headless"

func _save(file_name: String) -> void:
	await get_tree().process_frame
	await _wait_for_capture_frame()
	var texture = get_viewport().get_texture()
	if texture == null:
		push_error("화면 캡처 텍스처를 만들지 못했습니다.")
		failed = true
		return
	var image = texture.get_image()
	if image == null or image.is_empty():
		push_error("화면 캡처 이미지가 비어 있습니다.")
		failed = true
		return
	image.convert(Image.FORMAT_RGB8)
	var error = image.save_png(output_dir.path_join(file_name))
	if error != OK:
		push_error("%s 저장 실패: %d" % [file_name, error])
		failed = true

func _wait_for_capture_frame() -> void:
	var draw_completed: bool = false
	var mark_drawn: Callable = func() -> void:
		draw_completed = true
	RenderingServer.frame_post_draw.connect(mark_drawn, CONNECT_ONE_SHOT)
	for _index in range(30):
		await get_tree().process_frame
		if draw_completed:
			break
	if RenderingServer.frame_post_draw.is_connected(mark_drawn):
		RenderingServer.frame_post_draw.disconnect(mark_drawn)
