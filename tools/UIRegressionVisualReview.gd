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

	await _capture_finale_days_review()

func _capture_finale_days_review() -> void:
	game.facility_change_panel_open = false
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	game._open_raid_screen()
	await _settle(5)
	_expect(game.current_screen == Constants.SCREEN_RAID, "DAY 28 마지막 원정 선택 화면 진입")
	var modifier_copy := _find_text_control(game.ui_layer, "DAY 30 조사관")
	var recent_report_title := _find_text_control(game.ui_layer, "최근 원정 보고")
	if modifier_copy != null and recent_report_title != null and recent_report_title.get_parent() is Control:
		_expect(not modifier_copy.get_global_rect().intersects((recent_report_title.get_parent() as Control).get_global_rect()), "DAY 28 다음 방어 영향 설명과 최근 원정 보고 패널 비겹침")
	else:
		_expect(false, "DAY 28 다음 방어 영향과 최근 원정 보고 검사 대상 생성")
	_expect_top_level_layout_within_design_bounds("DAY 28 마지막 원정 선택")
	_expect_capture_size(Vector2i(1366, 768), "DAY 28 마지막 원정 선택")
	await _save("16_day28_final_expedition_choice_1366.png")

	_apply_finale_raid_choice_for_review("d28_siege_route_recon")
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	game._start_combat()
	await _settle(4)
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "DAY 28 원정 확정 후 방어 전투 진입")
	game._finish_combat(true, "DAY 28 최종 공성로 정찰 방어 성공.")
	await _settle(6)
	game._continue_from_result()
	await _settle(6)

	_expect(GameState.day == 29, "DAY 28 결산 후 DAY 29 진행")
	_expect(game.current_screen == Constants.SCREEN_DIALOGUE, "DAY 29 결전 전야 대화 화면 진입")
	_expect(game.onboarding_dialogue_queue.size() == 10, "DAY 29 결전 전야 대사 10개 로드")
	_expect(_find_text_control(game.ui_layer, "DAY 29 · 결전 전야") != null, "DAY 29 전용 대화 제목 표시")
	for _index in range(5):
		game._onboarding_advance_dialogue()
		await _settle(2)
	_expect(_find_text_control(game.ui_layer, "로만의 보급 전언") != null, "DAY 29 로만 보급 전언 대화 표시")
	_expect(_has_texture_path(game.ui_layer, "CHR_ROMAN_portrait_command.png"), "DAY 29 로만 전용 imagegen 초상 실제 렌더링")
	_expect_top_level_layout_within_design_bounds("DAY 29 로만 보급 전언")
	_expect_capture_size(Vector2i(1366, 768), "DAY 29 로만 보급 전언")
	await _save("17_day29_roman_notice_1366.png")
	for _index in range(2):
		game._onboarding_advance_dialogue()
		await _settle(2)
	_expect(_find_text_control(game.ui_layer, "정식 용사 레온") != null, "DAY 29 정식 레온 호칭 표시")
	_expect(_has_texture_path(game.ui_layer, "CHR_HERO_LEON_OFFICIAL_portrait_final.png"), "DAY 29 정식 레온 imagegen 승급 초상 실제 렌더링")
	_expect_top_level_layout_within_design_bounds("DAY 29 정식 레온 예고")
	_expect_capture_size(Vector2i(1366, 768), "DAY 29 정식 레온 예고")
	await _save("17b_day29_official_leon_notice_1366.png")
	while game.current_screen == Constants.SCREEN_DIALOGUE:
		game._onboarding_advance_dialogue()
		await _settle(2)
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "DAY 29 결전 전야 대사를 모두 본 뒤 관리 화면 진입")
	_expect(not game.campaign_final_preparation_confirmed, "DAY 29 확정 전 최종 준비 플래그 비활성화")
	_expect(_find_text_control(game.ui_layer, "전원 집결 · 결전 전야") != null and _find_text_control(game.ui_layer, "오늘 침입 없음 · DAY 30 예고") != null, "DAY 29 상단 공지의 짧은 문구로 겹침 방지")
	var day29_notice_summary = game.ui_layer.find_child("CampaignNoticeSummary", true, false) as RichTextLabel
	_expect(day29_notice_summary != null and day29_notice_summary.text.begins_with("침입 없는 결전 전야."), "DAY 29 상단 공지에 잘리지 않는 전용 요약 표시")
	var day29_guide = game.ui_layer.find_child("ManagementGuideText", true, false) as RichTextLabel
	_expect(_rich_text_fits(day29_guide), "DAY 29 하단 준비 순서 안내 전체 표시")
	_expect_campaign_notice_regions_do_not_overlap("DAY 29 관리")
	_expect_target_within_design_bounds("StartCombatButton", "DAY 29 관리")
	_expect_top_level_layout_within_design_bounds("DAY 29 관리")
	_expect_capture_size(Vector2i(1366, 768), "DAY 29 관리")
	await _save("17c_day29_management_only_1366.png")

	game._set_campaign_final_declaration("rival_pact")
	await _settle(3)
	_expect(game._campaign_final_declaration_id() == "rival_pact", "DAY 29 재전 약속 최종 선언 저장")
	game._confirm_management_only_day()
	await _settle(6)
	_expect(game.current_screen == Constants.SCREEN_RESULT, "DAY 29 최종 준비 확정 결과 화면")
	_expect(bool(game.result_summary.get("management_only", false)), "DAY 29 결과의 비전투 계약")
	_expect(game.campaign_final_preparation_confirmed, "DAY 29 최종 준비 플래그 활성화")
	_expect_target_within_design_bounds("NextDayButton", "DAY 29 결과")
	_expect_top_level_layout_within_design_bounds("DAY 29 결과")
	_expect_capture_size(Vector2i(1366, 768), "DAY 29 결과")
	await _save("18_day29_preparation_result_1366.png")

	game._continue_from_result()
	await _settle(6)
	_expect(GameState.day == 30, "DAY 29 결산 후 DAY 30 진행")
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "DAY 30 최종 관리 화면 진입")
	_expect(game.castle_art_stage == "stage_04_citadel", "DAY 30 Stage 04 유지")
	_expect(int(game._castle_stage_info().get("area_room_count", 0)) == 11, "DAY 30 열한 구역 유지")
	_expect(_find_text_control(game.ui_layer, "등장 4명 · 정식 용사 레온 포함") != null and _find_text_control(game.ui_layer, "3단계 공성 · 최종 레온 1") != null, "DAY 30 상단 공지의 정식 레온 호칭과 짧은 문구 표시")
	var day30_notice_summary = game.ui_layer.find_child("CampaignNoticeSummary", true, false) as RichTextLabel
	_expect(day30_notice_summary != null and day30_notice_summary.text.begins_with("선발대·셀렌 공병대·정식 레온"), "DAY 30 상단 공지에 3단계 결전 요약을 잘림 없이 표시")
	var day30_guide = game.ui_layer.find_child("ManagementGuideText", true, false) as RichTextLabel
	_expect(_rich_text_fits(day30_guide) and day30_guide.text.contains("마지막 레온"), "DAY 30 하단 준비 순서 안내 전체 표시")
	_expect_campaign_notice_regions_do_not_overlap("DAY 30 관리")
	_expect_target_within_design_bounds("StartCombatButton", "DAY 30 관리")
	_expect_top_level_layout_within_design_bounds("DAY 30 관리")
	_expect_capture_size(Vector2i(1366, 768), "DAY 30 관리")
	await _save("19_day30_final_management_1366.png")

	game._start_combat()
	await _settle(4)
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "DAY 30 최종 공성전 진입")
	game._spawn_enemy("selen_trainee_paladin")
	game._spawn_enemy("engineer")
	game._spawn_enemy("official_hero_leon")
	var leon = game.enemy_units[-1] if not game.enemy_units.is_empty() else null
	if leon != null:
		game.combat_scene._try_brave_shout(leon)
	game.combat_scene._update_royal_rally(0.1)
	await _settle(5)
	_expect(game.enemy_units.any(func(unit): return unit.unit_id == "official_hero_leon"), "DAY 30 정식 용사 레온 스프라이트 배치")
	_expect_top_level_layout_within_design_bounds("DAY 30 최종 공성전")
	_expect_capture_size(Vector2i(1366, 768), "DAY 30 최종 공성전")
	await _save("20_day30_final_combat_1366.png")

	game._finish_combat(true, "DAY 30 최종 공성 방어 성공.")
	await _settle(8)
	_expect(game.current_screen == Constants.SCREEN_RESULT, "DAY 30 승리 결과 화면")
	_expect(game.campaign_completed, "DAY 30 승리로 정규 캠페인 완료")
	_expect(game.campaign_final_battle_outcome == "victory", "DAY 30 최종 결말 승리 기록")
	_expect_target_within_design_bounds("NextDayButton", "DAY 30 결과")
	_expect_top_level_layout_within_design_bounds("DAY 30 결과")
	_expect_capture_size(Vector2i(1366, 768), "DAY 30 결과")
	await _save("21_day30_final_result_1366.png")

	var actual_final_result_lines: Array = game.result_summary.get("lines", []).duplicate()
	game.result_summary["lines"] = [
		"※ 최대 23줄 배치 검사용 결산 예시",
		"격퇴한 적: 9 / 스폰: 9",
		"전투 시간: 72.1초 / 생존 몬스터: 2/3",
		"잔여 전력: HP 367 / 854",
		"획득 금화: 640",
		"획득 마력: 240",
		"증가 악명: 95",
		"마왕성 체력: 2500 / 2500",
		"지침 효과: 사수 피해 감소 142 / 총공격 추가 피해 +318",
		"시설 기여: 병영 공격 강화 311 · 피해 감소 244 · 감시초소 진입 지연 9.4초",
		"시설 기여: 회복실 몬스터 회복 186 · 왕좌 회복 42",
		"시설 기여: 수호핵 피해 감소 277",
		"공병 대응: 시설 도달 1회 · 무력화 1회",
		"셀렌 기술: 진군 지휘 1회 · 유지 34.2초",
		"레온 기술: 용기의 외침 1회 · 강화 대상 4명",
		"레온 기술: 용사의 돌진 1회 · 피해 58",
		"레온 기술: 최후의 맹세 1회 · 회복 81 · 방어막 6.0초",
		"마지막 원정: 안전한 공성로 정찰 효과 적용",
		"Stage 04 대마왕성 열한 구역 최종 방어 검증 완료",
		"정식 용사 레온과 왕국 최종 공성대를 격퇴했습니다.",
		"메인 스토리 클리어: DAY 30 이후 DAY 31로 넘어가지 않습니다.",
		"결전의 기록은 엔딩과 후일담 관리 화면에 그대로 이어집니다.",
		"여기서부터 진짜 마왕성. 네 단계 진화와 모든 시설의 성장이 완성되었습니다."
	]
	game._set_screen(Constants.SCREEN_RESULT)
	await _settle(8)
	var result_scroll = game.ui_layer.find_child("ResultLinesScroll", true, false) as ScrollContainer
	var result_list = game.ui_layer.find_child("ResultLinesList", true, false) as VBoxContainer
	_expect(result_scroll != null and result_list != null, "DAY 30 최대 23줄 결산 스크롤 구조 생성")
	if result_scroll != null and result_list != null:
		_expect(result_list.get_child_count() == 23, "DAY 30 최대 결산 23줄을 생략 없이 모두 생성")
		_expect(_control_children_do_not_overlap(result_list), "DAY 30 최대 결산의 모든 줄이 서로 겹치지 않음")
		var vertical_bar: VScrollBar = result_scroll.get_v_scroll_bar()
		_expect(result_list.size.y > result_scroll.size.y and vertical_bar.max_value > vertical_bar.page, "DAY 30 최대 결산에서 세로 스크롤 자동 활성화")
	_expect_capture_size(Vector2i(1366, 768), "DAY 30 최대 결산 상단")
	await _save("21b_day30_final_result_max_density_top_1366.png")
	if result_scroll != null:
		result_scroll.scroll_vertical = 100000
		await _settle(5)
		var bottom_bar: VScrollBar = result_scroll.get_v_scroll_bar()
		var expected_bottom := maxf(0.0, bottom_bar.max_value - bottom_bar.page)
		_expect(absf(float(result_scroll.scroll_vertical) - expected_bottom) <= 1.0, "DAY 30 최대 결산의 실제 맨 아래까지 스크롤 도달")
		if result_list != null and result_list.get_child_count() == 23:
			var last_result_label := result_list.get_child(22) as Control
			_expect(last_result_label != null and result_scroll.get_global_rect().intersects(last_result_label.get_global_rect()), "DAY 30 최대 결산의 23번째 줄이 하단 화면에 실제 표시")
		await _save("21c_day30_final_result_max_density_bottom_1366.png")
	game.result_summary["lines"] = actual_final_result_lines
	game._set_screen(Constants.SCREEN_RESULT)
	await _settle(5)

	game._continue_from_result()
	await _settle(8)
	_expect(game.current_screen == Constants.SCREEN_ENDING, "DAY 30 엔딩 화면 진입")
	_expect_target_within_design_bounds("PostgameContinueButton", "DAY 30 엔딩")
	_expect_target_within_design_bounds("EndingNextCycleButton", "DAY 30 엔딩")
	_expect_top_level_layout_within_design_bounds("DAY 30 엔딩")
	_expect_capture_size(Vector2i(1366, 768), "DAY 30 엔딩")
	await _save("22_day30_ending_1366.png")

func _apply_finale_raid_choice_for_review(mission_id: String) -> void:
	var mission: Dictionary = DataRegistry.raid_mission(mission_id)
	_expect(not mission.is_empty(), "DAY 28 마지막 원정 데이터 존재")
	if mission.is_empty():
		return
	game.raid_selected_mission_id = mission_id
	game.completed_raids[mission_id] = true
	var modifier: Dictionary = mission.get("next_defense_modifier", {})
	if not modifier.is_empty():
		game.next_defense_modifiers[str(modifier.get("id", mission_id))] = modifier.duplicate(true)

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

func _find_text_control(node: Node, needle: String) -> Control:
	if node is Label and str(node.text).find(needle) >= 0:
		return node
	if node is RichTextLabel and str(node.text).find(needle) >= 0:
		return node
	for child in node.get_children():
		var found := _find_text_control(child, needle)
		if found != null:
			return found
	return null

func _has_texture_path(node: Node, path_suffix: String) -> bool:
	if node is TextureRect and node.texture != null and str(node.texture.resource_path).ends_with(path_suffix):
		return true
	for child in node.get_children():
		if _has_texture_path(child, path_suffix):
			return true
	return false

func _control_children_do_not_overlap(parent: Control) -> bool:
	var previous_control: Control = null
	for child in parent.get_children():
		if not child is Control or not (child as Control).visible:
			continue
		var current_control := child as Control
		if current_control.size.y <= 0.0:
			return false
		if previous_control != null and previous_control.get_rect().intersects(current_control.get_rect()):
			return false
		if previous_control != null and current_control.position.y < previous_control.position.y + previous_control.size.y:
			return false
		previous_control = current_control
	return true

func _rich_text_fits(label: RichTextLabel) -> bool:
	if label == null:
		return false
	return label.get_content_height() <= label.size.y + 1.0

func _expect_campaign_notice_regions_do_not_overlap(screen_label: String) -> void:
	var region_names := [
		"CampaignNoticeTitle",
		"CampaignNoticeStage",
		"CampaignNoticeSummary",
		"CampaignNoticePortrait0",
		"CampaignNoticePortrait1",
		"CampaignNoticePortrait2",
		"CampaignNoticeCast",
		"CampaignNoticeEnemy",
		"CampaignNoticeMonster"
	]
	var regions: Array[Control] = []
	var all_regions_exist := true
	for region_name in region_names:
		var region = game.ui_layer.find_child(str(region_name), true, false) as Control
		if region == null:
			all_regions_exist = false
			continue
		regions.append(region)
	_expect(all_regions_exist and regions.size() == region_names.size(), "%s 상단 공지의 제목·요약·인물·편성 영역 생성" % screen_label)
	var no_overlaps := true
	for first_index in range(regions.size()):
		for second_index in range(first_index + 1, regions.size()):
			if regions[first_index].get_global_rect().intersects(regions[second_index].get_global_rect()):
				no_overlaps = false
				push_error("%s 상단 공지 겹침: %s %s / %s %s" % [screen_label, regions[first_index].name, regions[first_index].get_global_rect(), regions[second_index].name, regions[second_index].get_global_rect()])
	_expect(no_overlaps, "%s 상단 공지의 제목·요약·인물·편성 영역 비겹침" % screen_label)

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
	var window_size := DisplayServer.window_get_size()
	var capture_matches := absi(actual_size.x - expected_size.x) <= 1 and absi(actual_size.y - expected_size.y) <= 1
	_expect(window_size == expected_size, "%s 실행 창 크기 %dx%d (실제 %dx%d)" % [screen_label, expected_size.x, expected_size.y, window_size.x, window_size.y])
	_expect(capture_matches, "%s 캡처 크기 %dx%d 호환 (실제 %dx%d)" % [screen_label, expected_size.x, expected_size.y, actual_size.x, actual_size.y])

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
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	for _attempt in range(6):
		DisplayServer.window_set_size(window_size)
		get_window().size = window_size
		await _settle(2)
		if DisplayServer.window_get_size() == window_size:
			break
	UISettings.set_text_scale(text_scale, false)
	await _settle(4)

func _settle(frames: int) -> void:
	for _index in range(frames):
		await get_tree().process_frame
		await get_tree().physics_frame

func _running_without_viewport_capture() -> bool:
	return DisplayServer.get_name() == "headless"

func _save(file_name: String) -> void:
	var image: Image
	var requires_top_bar := game.ui_layer.find_child("BossHpBar", true, false) != null
	for _attempt in range(8):
		await get_tree().process_frame
		await _wait_for_capture_frame()
		var texture = get_viewport().get_texture()
		if texture != null:
			image = texture.get_image()
			if image != null and not image.is_empty() and (not requires_top_bar or _capture_has_complete_top_bar(image)):
				break
	if image == null:
		push_error("화면 캡처 텍스처를 만들지 못했습니다.")
		failed = true
		return
	if image == null or image.is_empty():
		push_error("화면 캡처 이미지가 비어 있습니다.")
		failed = true
		return
	if requires_top_bar and not _capture_has_complete_top_bar(image):
		push_error("상단 HUD가 완전히 렌더링된 프레임을 얻지 못했습니다.")
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

func _capture_has_complete_top_bar(image: Image) -> bool:
	var width := image.get_width()
	var height := image.get_height()
	var sample_y := clampi(roundi(float(height) * 0.04), 0, height - 1)
	var visible_samples := 0
	for x_ratio in [0.025, 0.073, 0.18, 0.34, 0.65, 0.81]:
		var color := image.get_pixelv(Vector2i(roundi(float(width) * x_ratio), sample_y))
		if color.a > 0.80 and maxf(color.r, maxf(color.g, color.b)) > 0.025:
			visible_samples += 1
	return visible_samples >= 5
