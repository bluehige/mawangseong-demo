extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const CAPTURE_SIZE := Vector2i(1280, 720)
const MIN_SEGMENT_SECONDS := 372.0

var game: Node
var segment := "early"
var ending_limit := 0
var overlay_layer: CanvasLayer
var overlay_label: Label


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	segment = _segment_argument()
	ending_limit = _ending_limit_argument()
	DisplayServer.window_set_size(CAPTURE_SIZE)
	game = GameRootScene.instantiate()
	add_child(game)
	await _settle(12)
	game.campaign_save_enabled = false
	game._debug_skip_onboarding()
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	_build_overlay()
	await _settle(6)

	match segment:
		"early":
			await _capture_early()
		"mid":
			await _capture_mid()
		"late":
			await _capture_late()
		"endings":
			await _capture_endings()
		_:
			push_error("Unknown STOVE rating capture segment: %s" % segment)
			get_tree().quit(2)
			return

	print("STOVE_RATING_VIDEO_CAPTURE: PASS (%s)" % segment)
	get_tree().quit(0)


func _segment_argument() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--segment="):
			return argument.trim_prefix("--segment=").strip_edges().to_lower()
	return "early"


func _ending_limit_argument() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--ending-limit="):
			return maxi(0, int(argument.trim_prefix("--ending-limit=").strip_edges()))
	return 0


func _capture_early() -> void:
	_prepare_campaign_day(1, "stage_01_cave")
	_set_overlay("초반부 | DAY 1-3 | 관리와 첫 방어전")
	await _hold(12.0)

	game._select_room("barracks")
	_set_overlay("초반부 | 마왕성 관리와 방 선택")
	await _hold(35.0)
	game._build_selected_slot()
	await _hold(16.0)
	game._cancel_management_action_mode()
	game._change_selected_room_facility("watch_post")
	await _hold(18.0)

	game._open_monster_screen()
	_set_overlay("초반부 | 몬스터 성장 화면")
	await _hold(35.0)
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	game._open_raid_screen()
	_set_overlay("초반부 | 원정 선택 화면")
	await _hold(30.0)
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _hold(8.0)

	_set_overlay("초반부 | DAY 1 방어전 | 만화적 판타지 전투")
	await _start_combat_for_review()
	await _exercise_combat(165.0)
	await _finish_combat_for_review("초반부 심의 영상 방어 성공")
	_set_overlay("초반부 | 전투 결과와 성장")
	await _hold(35.0)

	if game.current_screen == Constants.SCREEN_RESULT:
		if game.has_method("_review_growth_from_result"):
			game._review_growth_from_result()
		await _hold(10.0)
		if game.current_screen == Constants.SCREEN_RESULT:
			game._continue_from_result()
	_set_overlay("초반부 | 다음 DAY 관리 화면")
	await _hold(18.0)
	await _pad_to_minimum(MIN_SEGMENT_SECONDS)


func _capture_mid() -> void:
	_prepare_campaign_day(15, "stage_03_keep")
	_prepare_grown_roster()
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	_set_overlay("중반부 | DAY 15 | 확장된 마왕성")
	await _hold(12.0)

	game._select_room("spike_corridor")
	game._set_global_directive(Constants.DIRECTIVE_DEFENSE)
	_set_overlay("중반부 | 시설 운영과 방어 지침")
	await _hold(45.0)

	game._open_monster_screen()
	_set_overlay("중반부 | 성장·승급·특화 몬스터")
	await _hold(45.0)
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	game._open_raid_screen()
	_set_overlay("중반부 | 원정과 다음 방어 효과")
	await _hold(30.0)
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _hold(7.0)

	_set_overlay("중반부 | 무기·마법·함정 전투")
	await _start_combat_for_review()
	await _exercise_combat(165.0)
	await _finish_combat_for_review("중반부 심의 영상 방어 성공")
	_set_overlay("중반부 | 전투 결산")
	await _hold(30.0)

	game._set_screen(Constants.SCREEN_CHRONICLE)
	_set_overlay("중반부 | 전선 연대기")
	await _hold(38.0)
	await _pad_to_minimum(MIN_SEGMENT_SECONDS)


func _capture_late() -> void:
	_prepare_campaign_day(25, "stage_04_citadel")
	_prepare_grown_roster()
	game.campaign_final_preparation_confirmed = true
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	_set_overlay("후반부 | DAY 25 | 최종 단계 마왕성")
	await _hold(12.0)

	game._select_room("throne")
	_set_overlay("후반부 | 상층·왕좌·최종 방어 준비")
	await _hold(50.0)
	game._open_monster_screen()
	_set_overlay("후반부 | 승급 몬스터와 최종 편성")
	await _hold(40.0)
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _hold(8.0)

	_set_overlay("후반부 | 보스전 | 가장 강한 판타지 폭력·공포 표현")
	await _start_combat_for_review()
	await _spawn_late_review_opponents()
	await _exercise_combat(205.0)
	await _finish_combat_for_review("후반부 보스 방어 성공")
	_set_overlay("후반부 | 보스전 결산")
	await _hold(35.0)

	game.campaign_completed = true
	game.campaign_final_battle_outcome = "victory"
	game.resolved_campaign_ending_id = "true_demon_castle"
	game._set_screen(Constants.SCREEN_ENDING)
	_set_overlay("후반부 | 엔딩 진입 예시 | 전체 엔딩은 별도 영상")
	await _hold(28.0)
	await _pad_to_minimum(MIN_SEGMENT_SECONDS)


func _capture_endings() -> void:
	_prepare_campaign_day(30, "stage_04_citadel")
	game.campaign_completed = true
	game.campaign_final_battle_outcome = "victory"
	var ending_ids: Array[String] = game._ending_catalog_ids()
	if ending_limit > 0:
		ending_ids = ending_ids.slice(0, mini(ending_limit, ending_ids.size()))
	_set_overlay("전체 엔딩 모음 | %d개 | 각 엔딩 ID 표시" % ending_ids.size())
	await _hold(8.0)
	var index := 0
	for ending_id in ending_ids:
		index += 1
		game.resolved_campaign_ending_id = ending_id
		# The original E00 ending gets its story from the campaign-day record. The
		# remaining catalog entries use the direct council data path, which avoids
		# resolving and overwriting the requested ID from the current run metrics.
		game.update4_active_run["campaign_mode_id"] = (
			"front_chronicle_legacy_v4" if ending_id == "true_demon_castle" else "council_season"
		)
		var catalog_data: Dictionary = DataRegistry.ending_rule(ending_id)
		var screen_data: Dictionary = game._campaign_ending_data()
		if str(screen_data.get("id", "")) != ending_id:
			push_error("Ending capture mismatch: requested %s, rendered %s" % [ending_id, str(screen_data.get("id", ""))])
			get_tree().quit(3)
			return
		game._set_screen(Constants.SCREEN_ENDING)
		var display_name := str(catalog_data.get("display_name", ending_id))
		var catalog_code := str(catalog_data.get("catalog_code", ""))
		_set_overlay("전체 엔딩 %02d/%02d | %s | %s | %s" % [index, ending_ids.size(), catalog_code, ending_id, display_name])
		print("STOVE_RATING_ENDING: %02d/%02d %s %s %s" % [index, ending_ids.size(), catalog_code, ending_id, str(screen_data.get("illustration", ""))])
		await _hold(10.0)
	_set_overlay("전체 엔딩 모음 종료 | %d개 확인" % ending_ids.size())
	await _hold(8.0)


func _prepare_campaign_day(day: int, stage_id: String) -> void:
	GameState.day = day
	GameState.max_day = 30
	GameState.gold = 999
	GameState.mana = 999
	GameState.infamy = 999
	GameState.victory = false
	GameState.defeat = false
	game.campaign_chapter_one_clear = day >= 10
	game.campaign_stage_two_prepared = day >= 10
	game.campaign_chapter_two_started = day >= 11
	game.campaign_stage_two_upgrade_funded = day >= 18
	game.campaign_stage_two_unlock_ready = day >= 18
	game.campaign_chapter_three_clear = day >= 23
	game.first_promotion_completed = day >= 12
	game.castle_art_stage = stage_id
	game.castle_evolution_history.clear()
	game.castle_evolution_history.append("stage_01_cave")
	if stage_id in ["stage_02_castle", "stage_03_keep", "stage_04_citadel"]:
		game.castle_evolution_history.append("stage_02_castle")
	if stage_id in ["stage_03_keep", "stage_04_citadel"]:
		game.castle_evolution_history.append("stage_03_keep")
	if stage_id == "stage_04_citadel":
		game.castle_evolution_history.append("stage_04_citadel")
	game._sync_castle_stage_content()
	game._setup_dungeon_graph()
	game._init_room_directives()
	if game.quarter_renderer != null:
		game.quarter_renderer.refresh_layout()
	game._enter_campaign_management_day(true)


func _prepare_grown_roster() -> void:
	for monster_id in ["slime", "goblin", "imp"]:
		if not game.monster_roster.has(monster_id):
			continue
		game.monster_roster[monster_id]["level"] = 8
		game.monster_roster[monster_id]["exp"] = 600
		game.monster_roster[monster_id]["loyalty"] = 90
	if game.monster_roster.has("slime"):
		game.monster_roster["slime"]["promotion_id"] = "slime_gate_bulwark"
		game.monster_roster["slime"]["promotion_stage"] = 1
	if game.monster_roster.has("goblin"):
		game.monster_roster["goblin"]["promotion_id"] = "goblin_ambush_captain"
		game.monster_roster["goblin"]["promotion_stage"] = 1
	if game.monster_roster.has("imp"):
		game.monster_roster["imp"]["promotion_id"] = "imp_flame_sage"
		game.monster_roster["imp"]["promotion_stage"] = 1


func _start_combat_for_review() -> void:
	if game.current_screen != Constants.SCREEN_MANAGEMENT:
		game._set_screen(Constants.SCREEN_MANAGEMENT)
	game._start_combat()
	await _settle(8)
	if game.current_screen != Constants.SCREEN_COMBAT:
		# Some campaign days gate combat behind a choice. Day 10 is a stable fallback
		# that still uses the real runtime wave, combat, effects, and UI.
		GameState.day = 10
		game._enter_campaign_management_day(true)
		await _settle(4)
		game._start_combat()
		await _settle(8)
	if game.current_screen == Constants.SCREEN_COMBAT:
		game.combat_speed = 0.85


func _exercise_combat(seconds: float) -> void:
	var remaining := seconds
	while remaining > 0.0:
		var slice := minf(30.0, remaining)
		if game.current_screen == Constants.SCREEN_COMBAT:
			var imp := _unit_by_id(game.monster_units, "imp")
			if imp != null and imp.is_alive():
				game._select_unit(imp)
				game._enable_direct_control()
				game._handle_key(KEY_1)
		await _hold(slice)
		remaining -= slice


func _spawn_late_review_opponents() -> void:
	if game.current_screen != Constants.SCREEN_COMBAT:
		return
	game.combat_paused = true
	for enemy_id in ["trainee_hero", "selen_trainee_paladin", "investigator"]:
		if not DataRegistry.enemy(enemy_id).is_empty():
			game._spawn_enemy(enemy_id)
	game.combat_paused = false
	await _settle(6)


func _finish_combat_for_review(reason: String) -> void:
	if game.current_screen == Constants.SCREEN_COMBAT:
		game._finish_combat(true, reason)
	await _settle(8)


func _unit_by_id(units: Array, unit_id: String) -> Node:
	for unit in units:
		if is_instance_valid(unit) and str(unit.unit_id) == unit_id:
			return unit
	return null


func _build_overlay() -> void:
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 1000
	add_child(overlay_layer)
	var panel := ColorRect.new()
	panel.position = Vector2(12, 12)
	panel.size = Vector2(980, 42)
	panel.color = Color("#160d23dc")
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.add_child(panel)
	overlay_label = Label.new()
	overlay_label.position = Vector2(18, 6)
	overlay_label.size = Vector2(950, 30)
	overlay_label.add_theme_font_override("font", preload("res://assets/fonts/NotoSansCJKkr-Regular.otf"))
	overlay_label.add_theme_font_size_override("font_size", 20)
	overlay_label.add_theme_color_override("font_color", Color("#fff1c4"))
	overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(overlay_label)


func _set_overlay(text: String) -> void:
	if overlay_label != null:
		overlay_label.text = "STOVE 자체등급 심의자료 · v2.0.1 · %s" % text


func _hold(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _pad_to_minimum(target_seconds: float) -> void:
	# Segment timelines are deliberately longer than six minutes. Keep this hook so
	# future timeline edits can preserve the submission minimum explicitly.
	if target_seconds > 0.0:
		await _hold(4.0)


func _settle(frames: int) -> void:
	for _index in range(frames):
		await get_tree().process_frame
		await get_tree().physics_frame
