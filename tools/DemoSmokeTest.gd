extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const DamageService = preload("res://scripts/combat/DamageService.gd")
const WaveManagerScript = preload("res://scripts/combat/WaveManager.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var failed := false

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	_check_combat_action_assets()
	var game = await _new_game()
	await _check_audio_settings_ui(game)
	await _check_combat_music_lifecycle(game)
	game.queue_free()
	await get_tree().process_frame

	game = await _new_game()
	await _check_map_click_build_palette(game)
	game.queue_free()
	await get_tree().process_frame

	game = await _new_game()
	await _check_raid_loop(game)
	game.queue_free()
	await get_tree().process_frame

	game = await _new_game()
	await _check_campaign_day_5_to_7(game)
	game.queue_free()
	await get_tree().process_frame

	game = await _new_game()
	await _check_campaign_day_8_to_21(game)
	game.queue_free()
	await get_tree().process_frame

	game = await _new_game()
	await _check_promotion_choice_matrix(game)
	game.queue_free()
	await get_tree().process_frame

	game = await _new_game()
	await _check_invalid_combat_actions(game)
	game.queue_free()
	await get_tree().process_frame

	game = await _new_game()
	await _check_early_specialization(game)
	game.queue_free()
	await get_tree().process_frame

	game = await _new_game()
	await _check_ai_reengagement(game)
	game.queue_free()
	await get_tree().process_frame

	game = await _new_game()
	await _check_core_loop(game)
	game.queue_free()
	await get_tree().process_frame

	game = await _new_game()
	await _check_facility_combat_effects(game)
	game.queue_free()
	await get_tree().process_frame

	game = await _new_game()
	await _check_defeat_branch(game)
	game.queue_free()
	await get_tree().process_frame

	game = await _new_game()
	await _check_three_day_victory(game)
	game.queue_free()
	await get_tree().process_frame

	if failed:
		print("DEMO_SMOKE_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("DEMO_SMOKE_TEST: PASS")
		get_tree().quit(0)

func _new_game() -> Node:
	var game = GameRootScene.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame
	if game.has_method("_debug_skip_onboarding"):
		game._debug_skip_onboarding()
		await get_tree().process_frame
	return game

func _check_combat_action_assets() -> void:
	for monster_id in ["slime", "goblin", "imp"]:
		for frame_index in range(4):
			var frame_path = "res://assets/sprites/monsters/monster_%s_attack_down_%02d.png" % [monster_id, frame_index]
			_expect(ResourceLoader.exists(frame_path), "%s 공격 원본 프레임 %02d 존재" % [monster_id, frame_index])
	for sound_name in ["slash", "shield_bash", "fire_burst", "hit", "down"]:
		var sound_path = "res://assets/audio/sfx/combat_%s.wav" % sound_name
		_expect(ResourceLoader.exists(sound_path), "전투 효과음 %s 존재" % sound_name)
		_expect(ResourceLoader.load(sound_path) is AudioStream, "전투 효과음 %s 로드" % sound_name)
	var music_path = "res://assets/audio/bgm/combat_dungeon_pressure.wav"
	_expect(ResourceLoader.exists(music_path), "전투 음악 존재")
	_expect(ResourceLoader.load(music_path) is AudioStreamWAV, "전투 음악 WAV 로드")
	_expect(AudioServer.get_bus_index(AudioSettings.MUSIC_BUS) >= 0, "전투 음악 전용 음량 통로 생성")
	_expect(AudioServer.get_bus_index(AudioSettings.SFX_BUS) >= 0, "전투 효과음 전용 음량 통로 생성")

func _check_audio_settings_ui(game: Node) -> void:
	var master_before = AudioSettings.master_volume
	var music_before = AudioSettings.music_volume
	var sfx_before = AudioSettings.sfx_volume
	var text_scale_before = UISettings.text_scale
	game._set_screen(Constants.SCREEN_TITLE)
	await get_tree().process_frame
	var settings_button = _find_button_by_text(game.ui_layer, "설정")
	_expect(settings_button != null, "제목 화면 설정 버튼 연결")
	if settings_button == null:
		return
	settings_button.pressed.emit()
	await get_tree().process_frame
	_expect(game.current_screen == Constants.SCREEN_SETTINGS, "환경 설정 화면 열림")
	var sliders = _find_sliders(game.ui_layer)
	_expect(sliders.size() == 4, "음량 3종과 글자 크기 슬라이더 표시")
	if sliders.size() == 4:
		sliders[0].value = 37.0
		sliders[1].value = 52.0
		sliders[2].value = 64.0
		sliders[3].value = 110.0
		await get_tree().process_frame
		_expect(is_equal_approx(AudioSettings.master_volume, 0.37), "마스터 음량 즉시 적용")
		_expect(is_equal_approx(AudioSettings.music_volume, 0.52), "전투 음악 음량 즉시 적용")
		_expect(is_equal_approx(AudioSettings.sfx_volume, 0.64), "전투 효과음 음량 즉시 적용")
		_expect(is_equal_approx(UISettings.text_scale, 1.10), "글자 크기 배율 즉시 저장")
	AudioSettings.set_master_volume(master_before)
	AudioSettings.set_music_volume(music_before)
	AudioSettings.set_sfx_volume(sfx_before)
	UISettings.set_text_scale(text_scale_before)
	game._set_screen(Constants.SCREEN_MANAGEMENT)

func _check_combat_music_lifecycle(game: Node) -> void:
	GameState.day = 1
	game._start_combat()
	await get_tree().process_frame
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "전투 음악 검증용 전투 시작")
	_expect(game.combat_music_player != null and game.combat_music_active, "전투 진입 시 음악 재생 요청")
	if DisplayServer.get_name() != "headless":
		await get_tree().create_timer(0.30).timeout
		_expect(game.combat_music_player.playing, "오디오 장치 환경에서 전투 음악 재생")
	_expect(game.combat_music_player.bus == AudioSettings.MUSIC_BUS, "전투 음악이 음악 전용 통로 사용")
	var music_stream = game.combat_music_player.stream
	_expect(music_stream is AudioStreamWAV and music_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "전투 음악 반복 재생 설정")
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await get_tree().create_timer(0.55).timeout
	_expect(not game.combat_music_player.playing, "전투 이탈 후 음악 페이드아웃 정지")

func _check_map_click_build_palette(game: Node) -> void:
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "맵 클릭 시설 팔레트 검증 시작")
	game._handle_left_click(game.graph.center("slot_01"))
	await get_tree().process_frame
	_expect(game.build_pick_mode and game.build_palette_target_room == "slot_01" and game.build_pick_facility_id == "", "빈 슬롯 맵 클릭으로 시설 팔레트 열림")
	game._set_build_facility("watch_post")
	await get_tree().process_frame
	_expect(game.build_pick_mode and game.build_preview_room_id == "slot_01", "시설 팔레트 선택 후 건설 미리보기 생성")
	_expect(game.rooms["slot_01"].get("facility_role", "") == "build_slot", "건설 미리보기 전에는 시설 미적용")
	_expect(game._build_preview_ready(), "건설 미리보기 확정 가능")
	_expect(game._build_preview_route_line().find("경로") >= 0, "건설 미리보기 경로 안내 표시")
	_expect(game._confirm_build_preview(), "건설 미리보기 확정 적용")
	await get_tree().process_frame
	_expect(not game.build_pick_mode and game.build_palette_target_room == "" and game.build_preview_room_id == "", "건설 확정 후 건설 모드 해제")
	_expect(game.rooms["slot_01"].get("facility_role", "") == "watch_post", "건설 확정이 클릭한 슬롯에 적용")

func _check_raid_loop(game: Node) -> void:
	GameState.day = 4
	game._open_raid_screen()
	await get_tree().process_frame
	_expect(game.current_screen == Constants.SCREEN_RAID, "DAY 04 원정 화면 열림")
	_expect(game.monster_roster.has("kobold_scout"), "원정 화면에서 코볼트 척후대장 로로 합류")
	_expect(not DataRegistry.raid_mission("d04_signpost_flip").is_empty(), "DAY 04 표지판 원정 데이터 로드")
	var gold_before = GameState.gold
	var food_before = GameState.food
	var infamy_before = GameState.infamy
	game.raid_selected_mission_id = "d04_signpost_flip"
	game.raid_selected_monster_ids.clear()
	game.raid_selected_monster_ids.append("kobold_scout")
	game._start_selected_raid()
	await get_tree().process_frame
	_expect(game.completed_raids.has("d04_signpost_flip"), "표지판 원정 완료 플래그 저장")
	_expect(GameState.food == food_before - 5, "원정 식량 비용 차감")
	_expect(GameState.gold == gold_before + 30, "원정 금화 보상 지급")
	_expect(GameState.infamy == infamy_before + 22, "로로 대장 보너스 포함 악명 보상 지급")
	_expect(game.next_defense_modifiers.has("lost_adventurers"), "원정 결과가 다음 방어 영향으로 저장")
	_expect(not game.last_raid_result.is_empty(), "원정 결과 보고 생성")
	game._start_combat()
	await get_tree().process_frame
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "원정 이후 DAY 04 방어전 시작")
	_expect(game.wave_manager.total_to_spawn == 5, "길 잃은 탐험가 효과로 DAY 04 적 수 조정")
	_expect(float(game.wave_manager.schedule[0].get("time", 0.0)) >= 4.0, "길 잃은 탐험가 효과로 첫 침입 지연")
	_expect(game.next_defense_modifiers.is_empty(), "방어전 시작 후 원정 효과 소모")
	game.wave_manager.next_index = game.wave_manager.schedule.size()
	game._check_combat_end()
	await get_tree().process_frame
	_expect(game.current_screen == Constants.SCREEN_RESULT, "DAY 04 방어전 결과 화면 표시")
	_expect(not GameState.victory, "DAY 04 방어전은 3일차 데모 클리어로 처리하지 않음")

func _check_campaign_day_5_to_7(game: Node) -> void:
	_expect(not DataRegistry.campaign_day(5).is_empty(), "DAY 05 캠페인 데이터 로드")
	_expect(not DataRegistry.campaign_day(6).is_empty(), "DAY 06 캠페인 데이터 로드")
	_expect(not DataRegistry.campaign_day(7).is_empty(), "DAY 07 캠페인 데이터 로드")
	_expect(DataRegistry.character("CHR_EXPLORER_MILO").get("portrait", {}).get("variants", {}).has("panic"), "밀로 panic 초상 변형 등록")
	_expect(DataRegistry.character("CHR_THIEF_NIA").get("portrait", {}).get("variants", {}).has("teasing"), "니아 teasing 초상 변형 등록")
	_expect(DataRegistry.character("CHR_GOLDIN").get("portrait", {}).get("variants", {}).has("accounting"), "골딘 accounting 초상 변형 등록")

	GameState.day = 4
	GameState.victory = false
	game._unlock_kobold_scout_commander()
	game.raid_selected_mission_id = "d04_signpost_flip"
	game.raid_selected_monster_ids.clear()
	game.raid_selected_monster_ids.append("kobold_scout")
	game._start_selected_raid()
	await get_tree().process_frame
	game._start_combat()
	await get_tree().process_frame
	_expect(game.wave_manager.total_to_spawn == 5, "DAY 04 원정 효과 적용 후 방어 웨이브 유지")
	game.wave_manager.next_index = game.wave_manager.schedule.size()
	game._check_combat_end()
	await get_tree().process_frame
	_expect(game.current_screen == Constants.SCREEN_RESULT, "DAY 04 정규 캠페인 결과 화면")
	game._continue_from_result()
	await get_tree().process_frame
	_expect(GameState.day == 5 and game.current_screen == Constants.SCREEN_MANAGEMENT, "DAY 04 결과 후 DAY 05 관리 화면으로 진행")
	_expect(game.campaign_seen_day_intros.has(5), "DAY 05 관리 인트로 기록")

	game._open_raid_screen()
	await get_tree().process_frame
	_expect(game._available_raid_ids().has("d05_supply_tag"), "DAY 05 보급 표식 원정 표시")
	game.raid_selected_mission_id = "d05_supply_tag"
	game.raid_selected_monster_ids.clear()
	game.raid_selected_monster_ids.append("kobold_scout")
	game._start_selected_raid()
	await get_tree().process_frame
	_expect(game.next_defense_modifiers.has("supply_suspicion"), "DAY 05 원정 효과가 다음 방어에 저장")
	game._start_combat()
	await get_tree().process_frame
	var day5_thief_count := 0
	for entry in game.wave_manager.schedule:
		if str(entry.get("enemy_id", "")) == "thief":
			day5_thief_count += 1
	_expect(day5_thief_count == 0, "DAY 05 보급 원정 효과는 당일 방어에 도둑을 추가하지 않음")
	_expect(game.next_defense_modifiers.has("supply_suspicion"), "DAY 05에 미룬 원정 효과는 방어 시작 후에도 보존")
	game._finish_combat(true, "DAY 05 보급 원정 지연 검증")
	await get_tree().process_frame

	GameState.day = 6
	game.next_defense_modifiers.clear()
	game._enter_campaign_management_day(true)
	await get_tree().process_frame
	game._start_combat()
	await get_tree().process_frame
	var day6_thief_count := 0
	for entry in game.wave_manager.schedule:
		if str(entry.get("enemy_id", "")) == "thief":
			day6_thief_count += 1
	_expect(day6_thief_count == 2, "DAY 06 니아 재등장 웨이브는 도둑 2명")
	GameState.gold = 60
	var treasure_room = game._room_by_facility("treasure", "")
	game._spawn_enemy("thief")
	var thief = _unit_by_id(game.enemy_units, "thief")
	_expect(thief != null and treasure_room != "", "DAY 06 보물 손실 검증용 도둑과 보물 방 준비")
	if thief != null and treasure_room != "":
		thief.global_position = game.graph.center(treasure_room)
		thief.current_room = treasure_room
		thief.set_physics_process(false)
		game.combat_scene.update_room_effects(5.1)
		_expect(GameState.gold == 0, "보유 금화보다 큰 약탈은 0으로 제한")
		_expect(game.treasure_gold_stolen_this_battle == 60, "보물 손실 집계는 실제 손실액 사용")
		_expect(game.thieves_reached_treasure_this_battle == 1, "보물 방에 들어온 도둑 수 기록")
		_expect(game.thieves_completed_theft_this_battle == 1, "약탈을 끝낸 도둑 수 기록")
	game._finish_combat(true, "DAY 06 보물 손실 검증")
	await get_tree().process_frame
	var saw_treasure_loss_line := false
	for line in game.result_summary.get("lines", []):
		if str(line).find("60") >= 0:
			saw_treasure_loss_line = true
	_expect(saw_treasure_loss_line, "DAY 06 결과 화면에 보물 손실 라인 표시")
	_expect(_result_has_line(game, "보안 평가 C"), "DAY 06 약탈 후 격퇴를 보안 평가로 표시")

	GameState.day = 7
	GameState.gold = 500
	GameState.mana = 300
	game._enter_campaign_management_day(true)
	await get_tree().process_frame
	_expect(game._facility_upgrade_unlocked(), "DAY 07 시설 강화 해금")
	game.selected_room = "barracks"
	var hp_before = int(game.rooms["barracks"].get("hp", 0))
	var capacity_before = int(game.rooms["barracks"].get("max_monsters", 0))
	var gold_before = GameState.gold
	var mana_before = GameState.mana
	_expect(game._can_upgrade_selected_facility(), "DAY 07 선택 시설 강화 가능")
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await get_tree().process_frame
	var upgrade_button = _find_button_by_text(game.ui_layer, "시설 강화")
	_expect(upgrade_button != null and not upgrade_button.disabled, "DAY 07 시설 강화 버튼 활성")
	game._upgrade_selected_facility()
	await get_tree().process_frame
	_expect(int(game.rooms["barracks"].get("facility_level", 1)) == 2, "시설 강화 레벨 저장")
	_expect(int(game.rooms["barracks"].get("hp", 0)) == hp_before + 80, "시설 강화 체력 증가")
	_expect(int(game.rooms["barracks"].get("max_monsters", 0)) == capacity_before + 1, "시설 강화 배치 한도 증가")
	_expect(GameState.gold == gold_before - 90 and GameState.mana == mana_before - 30, "시설 강화 비용 차감")
	_expect(not game._can_upgrade_selected_facility(), "Lv.2 시설 재강화 방지")
	var done_button = _find_button_by_text(game.ui_layer, "강화 완료")
	_expect(done_button != null and done_button.disabled, "Lv.2 시설은 UI에서 강화 완료로 비활성화")

func _check_campaign_day_8_to_21(game: Node) -> void:
	_expect(not DataRegistry.campaign_day(8).is_empty(), "DAY 08 캠페인 데이터 로드")
	_expect(not DataRegistry.campaign_day(9).is_empty(), "DAY 09 캠페인 데이터 로드")
	_expect(not DataRegistry.campaign_day(10).is_empty(), "DAY 10 캠페인 데이터 로드")
	_expect(not DataRegistry.campaign_day(11).is_empty(), "DAY 11 캠페인 데이터 로드")
	_expect(not DataRegistry.campaign_day(12).is_empty(), "DAY 12 캠페인 데이터 로드")
	_expect(not DataRegistry.campaign_day(13).is_empty(), "DAY 13 캠페인 데이터 로드")
	_expect(not DataRegistry.campaign_day(14).is_empty(), "DAY 14 캠페인 데이터 로드")
	_expect(not DataRegistry.campaign_day(15).is_empty(), "DAY 15 캠페인 데이터 로드")
	_expect(not DataRegistry.campaign_day(16).is_empty(), "DAY 16 캠페인 데이터 로드")
	_expect(not DataRegistry.campaign_day(17).is_empty(), "DAY 17 캠페인 데이터 로드")
	_expect(not DataRegistry.campaign_day(18).is_empty(), "DAY 18 캠페인 데이터 로드")
	_expect(not DataRegistry.campaign_day(19).is_empty(), "DAY 19 캠페인 데이터 로드")
	_expect(not DataRegistry.campaign_day(20).is_empty(), "DAY 20 캠페인 데이터 로드")
	_expect(not DataRegistry.campaign_day(21).is_empty(), "DAY 21 캠페인 데이터 로드")
	_expect(not DataRegistry.evolution_rule("slime_gate_bulwark").is_empty(), "푸딩 1차 승급 규칙 로드")
	_expect(not DataRegistry.evolution_rule("goblin_ambush_captain").is_empty(), "고브 1차 승급 규칙 로드")
	_expect(not DataRegistry.evolution_rule("imp_flame_adept").is_empty(), "핀 1차 승급 규칙 로드")
	_expect(not DataRegistry.enemy("investigator").is_empty(), "신규 적 클래스 investigator 등록")
	_expect(not DataRegistry.enemy("shieldbearer").is_empty(), "신규 적 클래스 shieldbearer 등록")
	_expect(not DataRegistry.enemy("selen_trainee_paladin").is_empty(), "신규 보스 클래스 selen_trainee_paladin 등록")
	_expect(not DataRegistry.enemy("engineer").is_empty(), "신규 적 클래스 engineer 등록")
	_expect(DataRegistry.character("CHR_INVESTIGATOR_IRIS").get("portrait", {}).get("variants", {}).has("inquisitive"), "조사관 아이리스 초상 등록")
	_expect(DataRegistry.character("CHR_SELEN").get("portrait", {}).get("variants", {}).has("checklist"), "셀렌 checklist 초상 등록")
	_expect(ResourceLoader.exists("res://assets/sprites/enemies/enemy_investigator_idle_down_00.png"), "조사관 전투 idle 스프라이트 존재")
	_expect(ResourceLoader.exists("res://assets/sprites/enemies/enemy_shieldbearer_idle_down_00.png"), "방패병 전투 idle 스프라이트 존재")
	_expect(ResourceLoader.exists("res://assets/sprites/enemies/enemy_shieldbearer_down_00.png"), "방패병 down 스프라이트 존재")
	_expect(ResourceLoader.exists("res://assets/sprites/enemies/enemy_selen_paladin_idle_down_00.png"), "셀렌 전투 idle 스프라이트 존재")
	_expect(ResourceLoader.exists("res://assets/sprites/enemies/enemy_selen_paladin_down_00.png"), "셀렌 down 스프라이트 존재")
	_expect(ResourceLoader.exists("res://assets/sprites/enemies/enemy_engineer_idle_down_00.png"), "공병 imagegen 전투 스프라이트 존재")
	_expect(ResourceLoader.exists("res://assets/sprites/enemies/enemy_engineer_down_00.png"), "공병 down 스프라이트 존재")
	for animation_source in ["idle", "move", "attack", "skill", "down"]:
		_expect(ResourceLoader.exists("res://assets/source/imagegen/engineer/CHR_ENGINEER_%s_sheet_imagegen.png" % animation_source), "공병 %s imagegen 원본 시트 존재" % animation_source)
	var engineer_texture := ResourceLoader.load("res://assets/sprites/enemies/enemy_engineer_idle_down_00.png") as Texture2D
	var engineer_image := engineer_texture.get_image() if engineer_texture != null else Image.new()
	_expect(not engineer_image.is_empty() and engineer_image.get_pixel(0, 0).a < 0.01, "공병 스프라이트 투명 모서리")
	var engineer_attack_texture := ResourceLoader.load("res://assets/sprites/enemies/enemy_engineer_attack_down_02.png") as Texture2D
	var engineer_skill_texture := ResourceLoader.load("res://assets/sprites/enemies/enemy_engineer_skill_down_02.png") as Texture2D
	_expect(engineer_attack_texture != null and engineer_attack_texture.get_image().get_data() != engineer_image.get_data(), "공병 공격 전용 imagegen 포즈 적용")
	_expect(engineer_skill_texture != null and engineer_skill_texture.get_image().get_data() != engineer_image.get_data(), "공병 시설 교란 전용 imagegen 포즈 적용")
	_expect(ResourceLoader.exists("res://assets/sprites/portraits/onboarding/CHR_SELEN_portrait_checklist.png"), "셀렌 초상 파일 존재")
	_expect(ResourceLoader.exists("res://assets/sprites/ui/evolution/badge_slime_gate_bulwark.png"), "푸딩 승급 배지 아이콘 존재")

	var day8_info: Dictionary = DataRegistry.campaign_day(8)
	var rolo_decision_recorded = str(day8_info.get("asset_decision", "")) == "rolo_raid_scout_support"
	_expect(rolo_decision_recorded, "DAY 08에서 로로 방어전 보류/정찰 지원 결정 기록")
	game._unlock_kobold_scout_commander()
	_expect(game.monster_roster.has("kobold_scout") and not game._monster_available_for_defense("kobold_scout"), "로로는 roster에는 있지만 방어 배치 비활성")
	_expect(game._management_monster_preview_position("kobold_scout") == Vector2.INF, "로로는 관리 맵 방어 프리뷰에서 제외")
	_expect(not game.dungeon_renderer._roster_preview_monster_ids().has("kobold_scout"), "로스터 렌더러 프리뷰도 로로 제외")
	game.selected_monster_id = "slime"
	game._select_monster("kobold_scout")
	await get_tree().process_frame
	_expect(game.selected_monster_id != "kobold_scout", "지원 전용 로로는 일반 몬스터 선택 차단")
	game.selected_monster_id = "kobold_scout"
	var rolo_train_gold_before = GameState.gold
	var rolo_train_exp_before = int(game.monster_roster["kobold_scout"].get("exp", 0))
	game._train_selected_monster()
	await get_tree().process_frame
	_expect(GameState.gold == rolo_train_gold_before and int(game.monster_roster["kobold_scout"].get("exp", 0)) == rolo_train_exp_before, "지원 전용 로로 훈련 비용/EXP 변경 없음")
	game._open_monster_screen()
	await get_tree().process_frame
	_expect(_find_button_by_text(game.ui_layer, "로로") == null, "로로는 일반 몬스터 관리 버튼에서 제외")
	_expect(_find_label_by_text(game.ui_layer, "원정/정찰 지원 전용") != null, "로로는 지원 전용 안내로만 표시")
	GameState.day = 8
	game._enter_campaign_management_day(true)
	await get_tree().process_frame
	_expect(game._campaign_notice_monster_line().find("로로") >= 0, "DAY 08 캠페인 공지에 추가 몬스터 운용 노출")
	game._start_combat()
	await get_tree().process_frame
	_expect(game.wave_manager.total_to_spawn == 5, "DAY 08 성장 예고 웨이브는 총 5명")
	_expect(_scheduled_enemy_count(game, "thief") == 1, "DAY 08 도둑은 1명으로 제한")
	_expect(_unit_by_id(game.monster_units, "kobold_scout") == null, "로로는 DAY 08 방어전에 스폰되지 않음")
	game._finish_combat(true, "DAY 08 성장 예고 검증")
	await get_tree().process_frame
	_expect(_result_has_line(game, "growth_preview"), "DAY 08 결과에 성장 예고 라인 표시")

	GameState.day = 9
	game._enter_campaign_management_day(true)
	await get_tree().process_frame
	game._start_combat()
	await get_tree().process_frame
	_expect(_scheduled_enemy_count(game, "investigator") == 1, "DAY 09 조사관 1명 스케줄")
	game._spawn_enemy("investigator")
	var investigator = _unit_by_id(game.enemy_units, "investigator")
	_expect(investigator != null and investigator.goal_room != "", "조사관 스폰 및 목표 방 설정")
	if investigator != null:
		_expect(investigator.sprite.sprite_frames.get_frame_count("idle_down") >= 2, "조사관 idle 애니메이션 프레임")
		_expect(investigator.sprite.sprite_frames.get_frame_count("move_down") >= 4, "조사관 move 애니메이션 프레임")
		_expect(investigator.sprite.sprite_frames.get_frame_count("attack_down") >= 4, "조사관 attack 애니메이션 프레임")
		_expect(investigator.sprite.sprite_frames.get_frame_count("skill_down") >= 4, "조사관 skill 애니메이션 프레임")
	game._finish_combat(true, "DAY 09 조사관 검증")
	await get_tree().process_frame
	_expect(_result_has_line(game, "investigator_class"), "DAY 09 결과에 신규 적 확인 라인 표시")

	GameState.day = 10
	GameState.victory = false
	game.campaign_chapter_one_clear = false
	game.campaign_stage_two_prepared = false
	game.campaign_chapter_two_started = false
	game._enter_campaign_management_day(true)
	await get_tree().process_frame
	game._start_combat()
	await get_tree().process_frame
	_expect(_scheduled_enemy_count(game, "investigator") == 1, "DAY 10 조사관 후속 등장")
	_expect(_scheduled_enemy_count(game, "trainee_hero") == 1, "DAY 10 수련생 용사 클라이맥스 등장")
	game._finish_combat(true, "DAY 10 챕터 마감 검증")
	await get_tree().process_frame
	_expect(game.campaign_chapter_one_clear, "DAY 10 승리 시 1장 클리어 플래그")
	_expect(game.campaign_stage_two_prepared, "DAY 10 승리 시 다음 장 준비 플래그")
	_expect(not GameState.victory, "DAY 10은 전체 게임 승리 상태로 처리하지 않음")
	_expect(_result_has_line(game, "chapter_one_clear"), "DAY 10 결과에 1장 클리어 라인 표시")
	game._continue_from_result()
	await get_tree().process_frame
	_expect(GameState.day == 11 and game.current_screen == Constants.SCREEN_MANAGEMENT, "DAY 10 결과 후 DAY 11 관리 화면으로 계속 진행")
	game._start_combat()
	await get_tree().process_frame
	_expect(GameState.day == 11 and game.current_screen == Constants.SCREEN_COMBAT, "DAY 11 웨이브가 있으면 전투 시작")
	_expect(game.wave_manager.total_to_spawn == 7, "DAY 11 왕국 경고문 웨이브는 총 7명")
	_expect(_scheduled_enemy_count(game, "investigator") == 1, "DAY 11 조사관 1명 유지")
	_expect(_scheduled_enemy_count(game, "thief") == 2, "DAY 11 도둑 2명 보물 압박")
	_expect(_unit_by_id(game.monster_units, "kobold_scout") == null, "로로는 DAY 11 방어전에도 스폰되지 않음")
	game._finish_combat(true, "DAY 11 왕국 경고문 검증")
	await get_tree().process_frame
	_expect(game.campaign_chapter_two_started, "DAY 11 승리 시 2장 시작 플래그")
	_expect(_result_has_line(game, "chapter_two_started"), "DAY 11 결과에 2장 시작 라인 표시")
	game._continue_from_result()
	await get_tree().process_frame
	_expect(GameState.day == 12 and game.current_screen == Constants.SCREEN_MANAGEMENT, "DAY 11 결과 후 DAY 12 관리 화면으로 계속 진행")
	_expect(game._promotion_unlocked(), "DAY 12 첫 승급 해금")
	game._start_combat()
	await get_tree().process_frame
	_expect(GameState.day == 12 and game.current_screen == Constants.SCREEN_MONSTER, "첫 승급 전 DAY 12 전투 시작 차단")
	GameState.gold = 500
	GameState.mana = 300
	GameState.infamy = 700
	game.selected_monster_id = "slime"
	game.monster_roster["slime"]["level"] = 2
	game.monster_roster["slime"]["exp"] = 75
	game._open_monster_screen()
	await get_tree().process_frame
	var locked_promotion_button = _find_button_by_text(game.ui_layer, "승급 조건")
	_expect(locked_promotion_button != null and locked_promotion_button.disabled, "Lv.3 전 첫 승급 버튼은 조건 안내로 비활성")
	game._train_selected_monster()
	await get_tree().process_frame
	_expect(int(game.monster_roster["slime"].get("level", 1)) == 3, "DAY 12 훈련 1회로 푸딩 Lv.3 도달")
	var promotion_button = _find_button_by_text(game.ui_layer, "승급")
	_expect(promotion_button != null and not promotion_button.disabled, "Lv.3 푸딩 첫 승급 버튼 활성")
	var stats_before_promotion: Dictionary = game._scaled_monster_stats("slime")
	var gold_before_promotion = GameState.gold
	var mana_before_promotion = GameState.mana
	var infamy_before_promotion = GameState.infamy
	var promotion_cost: Dictionary = DataRegistry.evolution_rule("slime_gate_bulwark").get("cost", {})
	game._promote_selected_monster()
	await get_tree().process_frame
	_expect(str(game.monster_roster["slime"].get("promotion_id", "")) == "slime_gate_bulwark", "푸딩 첫 승급 ID 저장")
	_expect(int(game.monster_roster["slime"].get("promotion_stage", 0)) == 1, "푸딩 첫 승급 단계 저장")
	_expect(str(game.monster_roster["slime"].get("role_tag", "")) == "blocker", "푸딩 승급 역할 태그 저장")
	_expect(game.first_promotion_completed, "첫 승급 완료 플래그 저장")
	_expect(GameState.gold == gold_before_promotion - int(promotion_cost.get("gold", 0)), "첫 승급 금화 비용 차감")
	_expect(GameState.mana == mana_before_promotion - int(promotion_cost.get("mana", 0)), "첫 승급 마력 비용 차감")
	_expect(GameState.infamy == infamy_before_promotion - int(promotion_cost.get("infamy", 0)), "첫 승급 악명 비용 차감")
	var stats_after_promotion: Dictionary = game._scaled_monster_stats("slime")
	_expect(int(stats_after_promotion.get("max_hp", 0)) > int(stats_before_promotion.get("max_hp", 0)), "푸딩 승급 HP 상승")
	_expect(int(stats_after_promotion.get("def", 0)) > int(stats_before_promotion.get("def", 0)), "푸딩 승급 방어 상승")
	_expect(int(stats_after_promotion.get("atk", 0)) > int(stats_before_promotion.get("atk", 0)), "푸딩 승급 공격 소폭 상승")
	_expect(not game._can_promote_selected_monster(), "동일 몬스터 중복 승급 방지")
	_expect(_find_label_by_text(game.ui_layer, "성문 방벽 푸딩") != null, "승급 후 몬스터 관리 UI에 승급명 표시")
	game._start_combat()
	await get_tree().process_frame
	_expect(GameState.day == 12 and game.current_screen == Constants.SCREEN_COMBAT, "DAY 12 첫 승급 웨이브 전투 시작")
	_expect(game.wave_manager.total_to_spawn == 8, "DAY 12 첫 승급 웨이브는 총 8명")
	_expect(_scheduled_enemy_count(game, "investigator") == 1, "DAY 12 조사관 1명 유지")
	_expect(_scheduled_enemy_count(game, "thief") == 2, "DAY 12 도둑 2명 유지")
	_expect(_scheduled_enemy_count(game, "trainee_hero") == 1, "DAY 12 약한 수련생 용사 1명 등장")
	_expect(_unit_by_id(game.monster_units, "kobold_scout") == null, "로로는 DAY 12 방어전에도 스폰되지 않음")
	game._finish_combat(true, "DAY 12 첫 승급 검증")
	await get_tree().process_frame
	_expect(_result_has_line(game, "first_promotion"), "DAY 12 결과에 첫 승급 해금 라인 표시")
	game._continue_from_result()
	await get_tree().process_frame
	_expect(GameState.day == 13 and game.current_screen == Constants.SCREEN_MANAGEMENT, "DAY 12 결과 후 DAY 13 관리 화면으로 계속 진행")
	_expect(game._promotion_limit_for_current_day() == 1, "DAY 13도 첫 승급 1명 제한 유지")
	GameState.gold = 800
	GameState.mana = 500
	GameState.infamy = 900
	game.selected_monster_id = "goblin"
	game.monster_roster["goblin"]["level"] = 3
	_expect(not game._can_promote_selected_monster(), "DAY 13 두 번째 승급은 아직 차단")
	_expect(game._promotion_block_reason("goblin") == "오늘은 1명만", "DAY 13 두 번째 승급 차단 사유 표시")
	game._start_combat()
	await get_tree().process_frame
	_expect(GameState.day == 13 and game.current_screen == Constants.SCREEN_COMBAT, "DAY 13 방패병 웨이브 전투 시작")
	_expect(game.wave_manager.total_to_spawn == 7, "DAY 13 방패병 웨이브는 총 7명")
	_expect(_scheduled_enemy_count(game, "shieldbearer") == 1, "DAY 13 방패병 1명 스케줄")
	_expect(_scheduled_enemy_count(game, "investigator") == 1, "DAY 13 조사관 1명 유지")
	_expect(_scheduled_enemy_count(game, "thief") == 2, "DAY 13 도둑 2명 유지")
	_expect(_unit_by_id(game.monster_units, "kobold_scout") == null, "로로는 DAY 13 방어전에도 스폰되지 않음")
	game._spawn_enemy("shieldbearer")
	var shieldbearer = _unit_by_id(game.enemy_units, "shieldbearer")
	_expect(shieldbearer != null and shieldbearer.goal_room != "", "방패병 스폰 및 목표 방 설정")
	if shieldbearer != null:
		_expect(shieldbearer.sprite.sprite_frames.get_frame_count("idle_down") >= 2, "방패병 idle 애니메이션 프레임")
		_expect(shieldbearer.sprite.sprite_frames.get_frame_count("move_down") >= 4, "방패병 move 애니메이션 프레임")
		_expect(shieldbearer.sprite.sprite_frames.get_frame_count("attack_down") >= 4, "방패병 attack 애니메이션 프레임")
		_expect(shieldbearer.sprite.sprite_frames.get_frame_count("skill_down") >= 4, "방패병 skill 애니메이션 프레임")
		_expect(shieldbearer.sprite.sprite_frames.get_frame_count("down") >= 2, "방패병 down 애니메이션 프레임")
		_expect(shieldbearer.move_speed < float(DataRegistry.enemy("explorer").get("move_speed", 0)), "방패병은 탐험가보다 느림")
		_expect(shieldbearer.def > int(DataRegistry.enemy("investigator").get("def", 0)), "방패병은 조사관보다 높은 방어")
	game._finish_combat(true, "DAY 13 방패병 카운터 검증")
	await get_tree().process_frame
	_expect(_result_has_line(game, "shieldbearer_class"), "DAY 13 결과에 신규 방패병 확인 라인 표시")
	_expect(_result_has_line(game, "second_promotion_deferred"), "DAY 13 결과에 두 번째 승급 보류 라인 표시")
	game._continue_from_result()
	await get_tree().process_frame
	_expect(GameState.day == 14 and game.current_screen == Constants.SCREEN_MANAGEMENT, "DAY 13 결과 후 DAY 14 관리 화면으로 계속 진행")
	GameState.gold = 800
	GameState.mana = 500
	GameState.infamy = 900
	game.selected_monster_id = "goblin"
	game.monster_roster["goblin"]["level"] = 3
	_expect(game._promotion_limit_for_current_day() == 1, "DAY 14도 DAY23 전 승급 1명 제한 유지")
	_expect(not game._can_promote_selected_monster(), "DAY 14 두 번째 승급도 차단")
	_expect(game._promotion_block_reason("goblin") == "오늘은 1명만", "DAY 14 두 번째 승급 차단 사유 표시")
	_expect(not game.campaign_stage_two_upgrade_funded, "DAY 14 전투 전 Stage 02 심사 비용 플래그는 미완료")
	var stage_two_cost: Dictionary = game._stage_two_upgrade_cost()
	_expect(int(stage_two_cost.get("gold", 0)) == 720 and int(stage_two_cost.get("infamy", 0)) == 720, "DAY 14 Stage 02 심사 비용 로드")
	game._start_combat()
	await get_tree().process_frame
	_expect(GameState.day == 14 and game.current_screen == Constants.SCREEN_COMBAT, "DAY 14 성 업그레이드 심사 웨이브 전투 시작")
	_expect(game.wave_manager.total_to_spawn == 7, "DAY 14 성 업그레이드 심사 웨이브는 총 7명")
	_expect(_scheduled_enemy_count(game, "explorer") == 3, "DAY 14 탐험가 3명 스케줄")
	_expect(_scheduled_enemy_count(game, "investigator") == 1, "DAY 14 조사관 1명 스케줄")
	_expect(_scheduled_enemy_count(game, "shieldbearer") == 1, "DAY 14 방패병 1명 재등장")
	_expect(_scheduled_enemy_count(game, "thief") == 2, "DAY 14 도둑 2명 비용 압박")
	game._finish_combat(true, "DAY 14 성 업그레이드 심사 검증")
	await get_tree().process_frame
	_expect(game.campaign_stage_two_upgrade_funded, "DAY 14 승리 후 Stage 02 심사 비용 마련 플래그")
	_expect(_result_has_line(game, "stage_two_upgrade_funded"), "DAY 14 결과에 Stage 02 비용 마련 라인 표시")
	_expect(_result_has_line(game, "stage_two_visual_deferred"), "DAY 14 결과에 Stage 02 비주얼 보류 라인 표시")
	game._continue_from_result()
	await get_tree().process_frame
	_expect(GameState.day == 15 and game.current_screen == Constants.SCREEN_MANAGEMENT, "DAY 14 결과 후 DAY 15 관리 화면으로 계속 진행")
	_expect(game._promotion_limit_for_current_day() == 1, "DAY 15도 DAY23 전 승급 1명 제한 유지")
	_expect(game.campaign_stage_two_upgrade_funded, "DAY 15에서도 Stage 02 심사 비용 플래그 유지")
	_expect(not game.campaign_stage_two_unlock_ready, "DAY 15 전투 전 Stage 02 해금 준비 플래그는 미완료")
	game.campaign_stage_two_upgrade_funded = false
	game._start_combat()
	await get_tree().process_frame
	_expect(GameState.day == 15 and game.current_screen == Constants.SCREEN_MANAGEMENT, "DAY 15는 Stage 02 비용 플래그 없으면 전투 시작 차단")
	game.campaign_stage_two_upgrade_funded = true
	var ready_gold_before_day15 = GameState.gold
	var ready_infamy_before_day15 = GameState.infamy
	var day15_stage_two_cost: Dictionary = game._stage_two_upgrade_cost()
	GameState.gold = int(day15_stage_two_cost.get("gold", 0)) - 1
	GameState.infamy = int(day15_stage_two_cost.get("infamy", 0))
	game._start_combat()
	await get_tree().process_frame
	_expect(GameState.day == 15 and game.current_screen == Constants.SCREEN_MANAGEMENT, "DAY 15는 현재 Stage 02 비용이 부족하면 전투 시작 차단")
	GameState.gold = ready_gold_before_day15
	GameState.infamy = ready_infamy_before_day15
	game.campaign_stage_two_upgrade_funded = true
	game._start_combat()
	await get_tree().process_frame
	_expect(GameState.day == 15 and game.current_screen == Constants.SCREEN_COMBAT, "DAY 15 셀렌 보스 웨이브 전투 시작")
	_expect(game.wave_manager.total_to_spawn == 6, "DAY 15 셀렌 보스 웨이브는 총 6명")
	_expect(_scheduled_enemy_count(game, "explorer") == 2, "DAY 15 탐험가 2명 스케줄")
	_expect(_scheduled_enemy_count(game, "investigator") == 1, "DAY 15 조사관 1명 스케줄")
	_expect(_scheduled_enemy_count(game, "shieldbearer") == 1, "DAY 15 방패병 1명 스케줄")
	_expect(_scheduled_enemy_count(game, "thief") == 1, "DAY 15 도둑 1명 점검 압박")
	_expect(_scheduled_enemy_count(game, "selen_trainee_paladin") == 1, "DAY 15 셀렌 보스 1명 스케줄")
	var day15_explorer_hp = _scaled_wave_stat("explorer", _scheduled_enemy_entry(game, "explorer"), "max_hp", "hp_scale", 1.0)
	var day15_selen_hp = _scaled_wave_stat("selen_trainee_paladin", _scheduled_enemy_entry(game, "selen_trainee_paladin"), "max_hp", "hp_scale", 1.0)
	_expect(day15_selen_hp > day15_explorer_hp, "DAY 15 셀렌 실전 HP는 탐험가보다 높음")
	game._spawn_enemy("selen_trainee_paladin")
	var selen = _unit_by_id(game.enemy_units, "selen_trainee_paladin")
	_expect(selen != null and selen.goal_room != "", "셀렌 스폰 및 목표 방 설정")
	if selen != null:
		_expect(selen.sprite.sprite_frames.get_frame_count("idle_down") >= 2, "셀렌 idle 애니메이션 프레임")
		_expect(selen.sprite.sprite_frames.get_frame_count("move_down") >= 4, "셀렌 move 애니메이션 프레임")
		_expect(selen.sprite.sprite_frames.get_frame_count("attack_down") >= 4, "셀렌 attack 애니메이션 프레임")
		_expect(selen.sprite.sprite_frames.get_frame_count("skill_down") >= 4, "셀렌 skill 애니메이션 프레임")
		_expect(selen.sprite.sprite_frames.get_frame_count("down") >= 2, "셀렌 down 애니메이션 프레임")
		_expect(selen.max_hp > int(DataRegistry.enemy("shieldbearer").get("max_hp", 0)), "셀렌은 방패병보다 높은 기본 체력")
		_expect(selen.def >= int(DataRegistry.enemy("trainee_hero").get("def", 0)), "셀렌은 수련생 용사급 이상 방어")
	game._finish_combat(true, "DAY 15 셀렌 보스 검증")
	await get_tree().process_frame
	_expect(game.campaign_stage_two_unlock_ready, "DAY 15 승리 후 Stage 02 해금 준비 플래그")
	_expect(_result_has_line(game, "selen_boss_clear"), "DAY 15 결과에 셀렌 보스 격퇴 라인 표시")
	_expect(_result_has_line(game, "stage_two_unlock_ready"), "DAY 15 결과에 Stage 02 해금 준비 라인 표시")
	_expect(_result_has_line(game, "stage_two_visual_deferred"), "DAY 15 결과에 Stage 02 비주얼 보류 라인 표시")
	game._continue_from_result()
	await get_tree().process_frame
	_expect(GameState.day == 16 and game.current_screen == Constants.SCREEN_MANAGEMENT, "DAY 15 결과 후 DAY 16 관리 화면으로 계속 진행")
	var day16_info: Dictionary = DataRegistry.campaign_day(16)
	var recon_mission: Dictionary = DataRegistry.raid_mission("d16_route_recon")
	var ambush_mission: Dictionary = DataRegistry.raid_mission("d16_supply_ambush")
	_expect(not day16_info.is_empty(), "DAY 16 보급로 캠페인 데이터 로드")
	_expect(str(day16_info.get("required_raid_choice_group", "")) == "day16_supply_route", "DAY 16 전투 전 보급로 선택 필수")
	_expect(str(recon_mission.get("choice_group", "")) == "day16_supply_route" and str(ambush_mission.get("choice_group", "")) == "day16_supply_route", "DAY 16 두 원정이 하나의 선택 묶음")
	_expect(int(ambush_mission.get("reward", {}).get("gold", 0)) > int(recon_mission.get("reward", {}).get("gold", 0)), "DAY 16 급습은 정찰보다 큰 금화 보상")
	var ambush_preview = WaveManagerScript.new()
	ambush_preview.setup(16, DataRegistry.waves, {"ambush": ambush_mission.get("next_defense_modifier", {})})
	var ambush_thief_count := 0
	for scheduled_entry_value in ambush_preview.schedule:
		var scheduled_entry: Dictionary = scheduled_entry_value
		if str(scheduled_entry.get("enemy_id", "")) == "thief":
			ambush_thief_count += 1
	_expect(ambush_preview.total_to_spawn == 7 and ambush_thief_count == 2, "DAY 16 급습은 기본 방어에 추격 도둑 1명 추가")
	_expect(_find_button_by_text(game.ui_layer, "보급로 선택") != null, "DAY 16 관리 화면에서 필수 원정 버튼 강조")
	game._start_combat()
	await get_tree().process_frame
	_expect(GameState.day == 16 and game.current_screen == Constants.SCREEN_RAID, "DAY 16 선택 전 전투 시작 시 보급로 원정 화면으로 안내")
	_expect(str(DataRegistry.raid_mission(game.raid_selected_mission_id).get("choice_group", "")) == "day16_supply_route", "DAY 16 원정 화면은 보급로 선택을 먼저 표시")
	GameState.food = 100
	var recon_gold_before := GameState.gold
	game.raid_selected_mission_id = "d16_route_recon"
	game.raid_selected_monster_ids.clear()
	game.raid_selected_monster_ids.append("kobold_scout")
	game._start_selected_raid()
	await get_tree().process_frame
	_expect(game.completed_raids.has("d16_route_recon"), "DAY 16 정찰 원정 완료 저장")
	_expect(GameState.gold == recon_gold_before + 80 and GameState.food == 92, "DAY 16 정찰 비용과 보상 즉시 적용")
	_expect(game._completed_raid_choice_id("day16_supply_route") == "d16_route_recon", "DAY 16 정찰을 보급로 최종 선택으로 저장")
	_expect(game._raid_choice_locked("d16_supply_ambush"), "DAY 16 정찰 선택 후 급습 중복 선택 잠금")
	game.raid_selected_mission_id = "d16_supply_ambush"
	game._start_selected_raid()
	await get_tree().process_frame
	_expect(not game.completed_raids.has("d16_supply_ambush"), "DAY 16 다른 보급로 계획 중복 보상 차단")
	game._onboarding_finish_raid_preview()
	await get_tree().process_frame
	game._start_combat()
	await get_tree().process_frame
	_expect(GameState.day == 16 and game.current_screen == Constants.SCREEN_COMBAT, "DAY 16 보급로 선택 후 방어 시작")
	_expect(game.wave_manager.total_to_spawn == 5, "DAY 16 정찰로 조사관 1명 우회")
	_expect(_scheduled_enemy_count(game, "investigator") == 0, "DAY 16 정찰 방어에 조사관 없음")
	_expect(not game.wave_manager.schedule.is_empty() and float(game.wave_manager.schedule[0].get("time", 0.0)) >= 4.0, "DAY 16 정찰로 첫 적 도착 4초 지연")
	game._finish_combat(true, "DAY 16 보급로 정찰 검증")
	await get_tree().process_frame
	_expect(_result_has_line(game, "day16_recon_result"), "DAY 16 결산에 선택한 정찰 결과 표시")
	_expect(_result_has_line(game, "chapter_three_supply_route"), "DAY 16 결산에 3장 보급로 시작 표시")
	game._continue_from_result()
	await get_tree().process_frame
	_expect(GameState.day == 17 and game.current_screen == Constants.SCREEN_MANAGEMENT, "DAY 16 결과 후 DAY 17 관리 화면으로 계속 진행")
	_expect(bool(DataRegistry.campaign_day(17).get("security_review", false)), "DAY 17 니아 보안 평가 활성")
	_expect(game._campaign_notice_summary().find("능선 정찰 흔적") >= 0, "DAY 16 정찰 선택을 DAY 17 화면 요약에 표시")
	var saw_day16_recon_continuity := false
	for log_line in game.logs:
		if str(log_line).find("능선에서 발자국을 숨겼더라") >= 0:
			saw_day16_recon_continuity = true
			break
	_expect(saw_day16_recon_continuity, "DAY 16 정찰 선택을 DAY 17 니아 관리 대사로 이어 받음")
	game._start_combat()
	await get_tree().process_frame
	_expect(GameState.day == 17 and game.current_screen == Constants.SCREEN_COMBAT, "DAY 17 니아 두 번째 침투 시작")
	_expect(game.wave_manager.total_to_spawn == 5, "DAY 17 방어는 총 5명으로 체력 숫자만 올리지 않음")
	_expect(_scheduled_enemy_count(game, "thief") == 2, "DAY 17 도둑이 두 차례 침투")
	game._spawn_enemy("thief")
	var day17_thief = _unit_by_id(game.enemy_units, "thief")
	if day17_thief != null:
		day17_thief.receive_damage(day17_thief.max_hp + 100)
	game._finish_combat(true, "DAY 17 보안 평가 검증")
	await get_tree().process_frame
	_expect(_result_has_line(game, "보안 평가 S"), "DAY 17 보물 방 진입 전 격퇴 시 보안 평가 S")
	_expect(_result_has_line(game, "nia_security_review_s"), "DAY 17 결산에 니아의 보안 평가 반응 표시")
	_expect(_result_has_line(game, "day17_security_review_complete"), "DAY 17 보안 재평가 완료 기록")
	_expect(game.last_security_grade == "S", "DAY 17 보안 평가 S를 다음 날 선택 정보로 저장")
	game._continue_from_result()
	await get_tree().process_frame
	_expect(GameState.day == 18 and game.current_screen == Constants.SCREEN_MANAGEMENT, "DAY 17 결과 후 DAY 18 관리 화면으로 계속 진행")
	_expect(game._campaign_notice_summary().find("지난 보안 평가 S") >= 0, "DAY 18 관리 요약에 DAY 17 보안 등급 계승")
	_expect(_find_button_by_text(game.ui_layer, "봉쇄 대응") != null, "DAY 18 관리 화면에서 봉쇄 대응 선택 강조")
	var manifest_mission: Dictionary = DataRegistry.raid_mission("d18_forged_manifest")
	var tunnel_mission: Dictionary = DataRegistry.raid_mission("d18_seal_smuggling_tunnel")
	_expect(str(manifest_mission.get("choice_group", "")) == "day18_blockade_response" and str(tunnel_mission.get("choice_group", "")) == "day18_blockade_response", "DAY 18 두 대응 작전이 하나의 선택 묶음")
	var manifest_preview = WaveManagerScript.new()
	manifest_preview.setup(18, DataRegistry.waves, {"manifest": manifest_mission.get("next_defense_modifier", {})})
	_expect(manifest_preview.total_to_spawn == 6, "DAY 18 가짜 장부 작전은 적 6명 유지")
	_expect(_enemy_count_in_schedule(manifest_preview.schedule, "explorer") == 3 and _enemy_count_in_schedule(manifest_preview.schedule, "investigator") == 0, "DAY 18 가짜 장부는 조사관을 탐험가로 교체")
	_expect(_enemy_count_in_schedule(manifest_preview.schedule, "thief") == 2 and _enemy_count_in_schedule(manifest_preview.schedule, "shieldbearer") == 1, "DAY 18 가짜 장부는 도둑 둘을 남김")
	var tunnel_preview = WaveManagerScript.new()
	tunnel_preview.setup(18, DataRegistry.waves, {"tunnel": tunnel_mission.get("next_defense_modifier", {})})
	_expect(tunnel_preview.total_to_spawn == 6, "DAY 18 갱도 봉쇄 작전은 적 6명 유지")
	_expect(_enemy_count_in_schedule(tunnel_preview.schedule, "thief") == 1 and _enemy_count_in_schedule(tunnel_preview.schedule, "shieldbearer") == 2, "DAY 18 갱도 봉쇄는 도둑을 방패병으로 교체")
	game._start_combat()
	await get_tree().process_frame
	_expect(game.current_screen == Constants.SCREEN_RAID, "DAY 18 선택 전 전투 시작 시 봉쇄 대응 화면으로 안내")
	GameState.food = 100
	game.raid_selected_mission_id = "d18_seal_smuggling_tunnel"
	game.raid_selected_monster_ids.clear()
	game.raid_selected_monster_ids.append("kobold_scout")
	game._start_selected_raid()
	await get_tree().process_frame
	_expect(game.completed_raids.has("d18_seal_smuggling_tunnel"), "DAY 18 밀수 갱도 봉쇄 작전 완료 저장")
	_expect(game._raid_choice_locked("d18_forged_manifest"), "DAY 18 선택 후 다른 대응 작전 중복 실행 잠금")
	game._onboarding_finish_raid_preview()
	await get_tree().process_frame
	game._start_combat()
	await get_tree().process_frame
	_expect(GameState.day == 18 and game.current_screen == Constants.SCREEN_COMBAT, "DAY 18 대응 선택 후 방어 시작")
	_expect(game.wave_manager.total_to_spawn == 6, "DAY 18 실제 방어도 적 6명")
	_expect(_scheduled_enemy_count(game, "thief") == 1 and _scheduled_enemy_count(game, "shieldbearer") == 2, "DAY 18 실제 방어에 갱도 봉쇄 조합 적용")
	game._finish_combat(true, "DAY 18 왕국 봉쇄선 검증")
	await get_tree().process_frame
	_expect(_result_has_line(game, "day18_tunnel_result"), "DAY 18 결산에 선택한 갱도 봉쇄 결과 표시")
	_expect(_result_has_line(game, "day18_blockade_broken"), "DAY 18 봉쇄선 돌파 기록")
	game._continue_from_result()
	await get_tree().process_frame
	_expect(GameState.day == 19 and game.current_screen == Constants.SCREEN_MANAGEMENT, "DAY 18 결과 후 DAY 19 관리 화면으로 계속 진행")
	_expect(not game._campaign_raid_choice_pending(), "DAY 19는 필수 원정 선택을 반복하지 않음")
	_expect(game._campaign_notice_summary().find("막힌 갱도를 포기한 방패병 둘") >= 0, "DAY 18 갱도 봉쇄를 DAY 19 관리 요약에 계승")
	_expect(game._campaign_notice_enemy_line().find("방패병 2") >= 0, "DAY 19 출현 예고에 전날 선택으로 바뀐 선발대 표시")
	var day19_info: Dictionary = DataRegistry.campaign_day(19)
	var day19_manifest_modifier: Dictionary = day19_info.get("completed_raid_defense_modifiers", {}).get("d18_forged_manifest", {})
	var day19_manifest_preview = WaveManagerScript.new()
	day19_manifest_preview.setup(19, DataRegistry.waves, {"manifest": day19_manifest_modifier})
	_expect(day19_manifest_preview.total_to_spawn == 6, "DAY 19 가짜 장부 후속전도 적 6명")
	_expect(_enemy_count_in_schedule(day19_manifest_preview.schedule, "investigator") == 2 and _enemy_count_in_schedule(day19_manifest_preview.schedule, "shieldbearer") == 0, "DAY 19 가짜 장부 후속전은 조사관 둘")
	_expect(_enemy_count_in_schedule(day19_manifest_preview.schedule, "thief") == 1 and _enemy_count_in_schedule(day19_manifest_preview.schedule, "trainee_hero") == 1, "DAY 19 두 경로 모두 회수 도둑과 회수대장 유지")
	game._start_combat()
	await get_tree().process_frame
	_expect(GameState.day == 19 and game.current_screen == Constants.SCREEN_COMBAT, "DAY 19은 새 선택 화면 없이 바로 방어 시작")
	_expect(game.wave_manager.total_to_spawn == 6, "DAY 19 실제 방어는 적 6명")
	_expect(_scheduled_enemy_count(game, "investigator") == 0 and _scheduled_enemy_count(game, "shieldbearer") == 2, "DAY 19 실제 방어에 갱도 봉쇄 후속 방패대 적용")
	_expect(_scheduled_enemy_count(game, "thief") == 1 and _scheduled_enemy_count(game, "trainee_hero") == 1, "DAY 19 실제 방어에 회수 도둑과 회수대장 적용")
	game.combat_time = 30.1
	game._update_campaign_combat_timed_lines()
	_expect(_logs_have_line(game, "6초 뒤"), "DAY 19 회수 도둑 도착 전 경고")
	game.combat_time = 42.1
	game._update_campaign_combat_timed_lines()
	_expect(_logs_have_line(game, "회수대장 접근"), "DAY 19 회수대장 도착 전 경고")
	_expect(game.campaign_combat_timed_lines_fired.size() == 2, "DAY 19 시간 경고는 각각 한 번만 기록")
	game._spawn_enemy("thief")
	var day19_thief = _unit_by_id(game.enemy_units, "thief")
	if day19_thief != null:
		day19_thief.receive_damage(day19_thief.max_hp + 100)
	game._finish_combat(true, "DAY 19 봉쇄 명령서 회수대 검증")
	await get_tree().process_frame
	_expect(_result_has_line(game, "보안 평가 S"), "DAY 19 회수 도둑 진입 전 격퇴를 공통 보안 평가로 표시")
	_expect(_result_has_line(game, "day19_tunnel_aftermath"), "DAY 19 결산에 갱도 봉쇄 후속 결과 표시")
	_expect(_result_has_line(game, "day19_recovery_team_defeated"), "DAY 19 봉쇄 명령서 수호 기록")
	game._continue_from_result()
	await get_tree().process_frame
	_expect(GameState.day == 20 and game.current_screen == Constants.SCREEN_MANAGEMENT, "DAY 19 결과 후 DAY 20 관리 화면으로 계속 진행")
	_expect(game._campaign_notice_enemy_line().find("왕국 공병 2") >= 0, "DAY 20 출현 예고에 공병 둘 표시")
	game._start_combat()
	await get_tree().process_frame
	_expect(GameState.day == 20 and game.current_screen == Constants.SCREEN_COMBAT, "DAY 20은 새 선택 없이 바로 방어 시작")
	_expect(game.wave_manager.total_to_spawn == 6, "DAY 20 실제 방어는 적 6명")
	_expect(_scheduled_enemy_count(game, "engineer") == 2, "DAY 20 공병 2명 스케줄")
	game._spawn_enemy("engineer")
	var engineer = _unit_by_id(game.enemy_units, "engineer")
	_expect(engineer != null, "왕국 공병 스폰")
	if engineer != null:
		var engineer_frames: SpriteFrames = engineer.sprite.sprite_frames
		var expected_engineer_frames := {"idle_down": 2, "move_down": 4, "attack_down": 4, "skill_down": 4, "down": 2}
		for animation_name in expected_engineer_frames:
			var expected_count: int = expected_engineer_frames[animation_name]
			_expect(engineer_frames.get_frame_count(animation_name) == expected_count, "공병 %s 규칙 프레임 수 %d" % [animation_name, expected_count])
			_expect(_animation_frames_are_unique(engineer_frames, animation_name), "공병 %s 전체 프레임이 서로 다른 원화" % animation_name)
		_expect(is_equal_approx(engineer_frames.get_animation_speed("idle_down"), 5.0), "공병 대기 5 FPS 규칙")
		_expect(is_equal_approx(engineer_frames.get_animation_speed("move_down"), 10.0), "공병 이동 10 FPS 규칙")
		_expect(is_equal_approx(engineer_frames.get_animation_speed("attack_down"), 10.0), "공병 공격 10 FPS 규칙")
		_expect(is_equal_approx(engineer_frames.get_animation_speed("skill_down"), 8.0), "공병 기술 8 FPS 규칙")
		_expect(is_equal_approx(engineer_frames.get_animation_speed("down"), 7.0), "공병 쓰러짐 7 FPS 규칙")
		var engineer_attack_frame_time := float(engineer_frames.get_frame_count("attack_down")) / engineer_frames.get_animation_speed("attack_down")
		engineer.play_attack(engineer.global_position + Vector2(100, 0))
		_expect(engineer.attack_anim_timer >= engineer_attack_frame_time, "공병 공격 전체 프레임 재생 시간 확보")
		var target_room := str(game.engineer_target_rooms.get(engineer.get_instance_id(), ""))
		_expect(target_room != "" and game._facility_room_is_active(target_room), "공병이 가장 가까운 작동 중 시설을 목표로 선택")
		_expect(engineer.threat_warning_text() == "시설 교란", "공병 시설 교란 위협 표시")
		if target_room != "":
			engineer.current_room = target_room
			engineer.global_position = game.graph.center(target_room)
			game._update_enemy_path(engineer)
			_expect(not game._facility_room_is_active(target_room), "공병 도착 시 시설 실제 무력화")
			_expect(engineer.skill_anim_timer > 0.0 and engineer.sprite.animation == &"skill_down", "공병 도착 순간 시설 교란 모션 재생")
			_expect(game.engineers_reached_facility_this_battle == 1 and game.facility_disables_this_battle == 1, "공병 도달과 무력화 횟수 기록")
			game.hud.update_facility_effect_panel()
			_expect(_find_label_by_text(game.ui_layer, "무력화") != null, "시설 효과 패널에 무력화 남은 시간 표시")
			game._update_facility_disables(10.1)
			_expect(game._facility_room_is_active(target_room), "10초 뒤 시설 기능 자동 복구")
	game._finish_combat(true, "DAY 20 왕국 공병 격퇴 검증")
	await get_tree().process_frame
	_expect(_result_has_line(game, "공병 대응: 시설 도달"), "DAY 20 결산에 공병 도달·무력화·시설 방어 통계 표시")
	_expect(_result_has_line(game, "day20_engineers_repulsed"), "DAY 20 왕국 공병 격퇴 기록")
	game._continue_from_result()
	await get_tree().process_frame
	_expect(GameState.day == 21 and game.current_screen == Constants.SCREEN_MANAGEMENT, "DAY 20 결과 후 DAY 21 관리 화면으로 계속 진행")
	_expect(game._campaign_notice_enemy_line().find("지휘관 셀렌 1") >= 0, "DAY 21 출현 예고에 지휘관 셀렌 표시")
	game._start_combat()
	await get_tree().process_frame
	_expect(GameState.day == 21 and game.current_screen == Constants.SCREEN_COMBAT, "DAY 21 셀렌 지휘 방어 시작")
	_expect(game.wave_manager.total_to_spawn == 6, "DAY 21 실제 방어는 적 6명")
	_expect(_scheduled_enemy_count(game, "selen_trainee_paladin") == 1, "DAY 21 지휘관 셀렌 1명 스케줄")
	game._spawn_enemy("explorer")
	var rallied_explorer = _unit_by_id(game.enemy_units, "explorer")
	game._spawn_enemy("selen_trainee_paladin")
	var commander = _unit_by_id(game.enemy_units, "selen_trainee_paladin")
	game.combat_scene._update_royal_rally(0.1)
	_expect(commander != null and commander.role == "commander", "DAY 21 셀렌 현장 지휘관 역할 적용")
	if commander != null:
		_expect(commander.threat_warning_text() == "진군 지휘", "셀렌 진군 지휘 위협 표시")
		_expect(commander.skill_anim_timer > 0.0 and commander.sprite.animation == &"skill_down", "셀렌 지휘 스킬 모션 재생")
	if rallied_explorer != null:
		_expect(is_equal_approx(rallied_explorer.royal_rally_move_multiplier, 1.18), "셀렌 생존 중 왕국군 이동 속도 강화")
		_expect(rallied_explorer.effective_attack_interval() < rallied_explorer.attack_interval, "셀렌 생존 중 왕국군 공격 속도 강화")
	if commander != null:
		commander.receive_damage(commander.max_hp + 100)
	_expect(game.combat_scene.royal_rally_stopped, "셀렌 격퇴 시 진군 지휘 중단 기록")
	if rallied_explorer != null:
		_expect(is_equal_approx(rallied_explorer.royal_rally_move_multiplier, 1.0), "셀렌 격퇴 시 이동 강화 즉시 해제")
		_expect(is_equal_approx(rallied_explorer.royal_rally_attack_interval_multiplier, 1.0), "셀렌 격퇴 시 공격 강화 즉시 해제")
	game._finish_combat(true, "DAY 21 셀렌 진군 지휘 저지 검증")
	await get_tree().process_frame
	_expect(_result_has_line(game, "셀렌 지휘: 진군 강화"), "DAY 21 결산에 지휘 시간·횟수·중단 결과 표시")
	_expect(_result_has_line(game, "day21_selen_rally_stopped"), "DAY 21 셀렌 현장 지휘 저지 기록")

func _check_promotion_choice_matrix(game: Node) -> void:
	var cases = [
		{
			"monster_id": "slime",
			"rule_id": "slime_gate_bulwark",
			"skill_id": "slime_shield",
			"upgrade_key": "duration_bonus",
			"increased_stats": ["max_hp", "def", "atk"]
		},
		{
			"monster_id": "goblin",
			"rule_id": "goblin_ambush_captain",
			"skill_id": "quick_slash",
			"upgrade_key": "damage_multiplier_bonus",
			"increased_stats": ["atk", "move_speed", "def"]
		},
		{
			"monster_id": "imp",
			"rule_id": "imp_flame_adept",
			"skill_id": "fireball",
			"upgrade_key": "damage_bonus",
			"increased_stats": ["atk", "attack_range", "max_hp"]
		}
	]
	for entry in cases:
		var monster_id = str(entry.get("monster_id", ""))
		var rule_id = str(entry.get("rule_id", ""))
		game._init_roster()
		GameState.day = 12
		GameState.gold = 800
		GameState.mana = 500
		GameState.infamy = 900
		game.campaign_chapter_two_started = true
		game.first_promotion_completed = false
		game.monster_roster[monster_id]["level"] = 3
		game.selected_monster_id = monster_id
		var rule: Dictionary = DataRegistry.evolution_rule(rule_id)
		var icon_path = str(rule.get("icon", ""))
		_expect(ResourceLoader.exists(icon_path), "%s 승급 배지 아이콘 존재" % rule_id)
		var stats_before: Dictionary = game._scaled_monster_stats(monster_id)
		_expect(game._can_promote_selected_monster(), "%s 승급 조건 충족" % rule_id)
		var gold_before = GameState.gold
		var mana_before = GameState.mana
		var infamy_before = GameState.infamy
		var promoted = game._promote_monster(monster_id)
		await get_tree().process_frame
		_expect(promoted, "%s 승급 실행 성공" % rule_id)
		_expect(str(game.monster_roster[monster_id].get("promotion_id", "")) == rule_id, "%s 승급 ID 저장" % rule_id)
		var cost: Dictionary = rule.get("cost", {})
		_expect(GameState.gold == gold_before - int(cost.get("gold", 0)), "%s 금화 비용 차감" % rule_id)
		_expect(GameState.mana == mana_before - int(cost.get("mana", 0)), "%s 마력 비용 차감" % rule_id)
		_expect(GameState.infamy == infamy_before - int(cost.get("infamy", 0)), "%s 악명 비용 차감" % rule_id)
		var stats_after: Dictionary = game._scaled_monster_stats(monster_id)
		for stat_name_value in entry.get("increased_stats", []):
			var stat_name = str(stat_name_value)
			_expect(float(stats_after.get(stat_name, 0.0)) > float(stats_before.get(stat_name, 0.0)), "%s 승급으로 %s 상승" % [rule_id, stat_name])
		var upgrade = game._promotion_skill_upgrade(monster_id, str(entry.get("skill_id", "")))
		_expect(not upgrade.is_empty(), "%s 스킬 업그레이드 데이터 연결" % rule_id)
		_expect(float(upgrade.get(str(entry.get("upgrade_key", "")), 0.0)) > 0.0, "%s 스킬 업그레이드 수치 연결" % rule_id)
		_expect(not game._can_promote_selected_monster(), "%s 중복 승급 방지" % rule_id)
		await _check_promoted_skill_effect(game, monster_id, str(entry.get("skill_id", "")), rule_id)

func _check_promoted_skill_effect(game: Node, monster_id: String, skill_id: String, rule_id: String) -> void:
	game._start_combat()
	await get_tree().process_frame
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "%s 승급 스킬 검증용 전투 시작" % rule_id)
	var unit = _unit_by_id(game.monster_units, monster_id)
	_expect(unit != null and unit.role == str(DataRegistry.evolution_rule(rule_id).get("role_tag", "")), "%s 전투 유닛 역할 태그 표시" % rule_id)
	if unit == null:
		return
	game._select_unit(unit)
	match skill_id:
		"slime_shield":
			game.combat_scene.use_selected_skill(0)
			_expect(unit.shield_timer > 5.0, "%s 점액 방패 지속시간 업그레이드 적용" % rule_id)
			_expect(unit.damage_reduction > 0.4, "%s 점액 방패 피해 감소 업그레이드 적용" % rule_id)
		"quick_slash":
			game._spawn_enemy("explorer")
			var slash_target = game.enemy_units[game.enemy_units.size() - 1]
			slash_target.global_position = unit.global_position + Vector2(24, 0)
			slash_target.current_room = unit.current_room
			slash_target.set_physics_process(false)
			var base_damage = DamageService.compute(unit, slash_target, 1.9)
			var hp_before = slash_target.hp
			game.combat_scene.use_selected_skill(0)
			var actual_damage = hp_before - slash_target.hp
			_expect(actual_damage > base_damage, "%s 날붙이 베기 피해 업그레이드 적용" % rule_id)
		"fireball":
			game._spawn_enemy("explorer")
			var fire_target = game.enemy_units[game.enemy_units.size() - 1]
			fire_target.global_position = unit.global_position + Vector2(340, 0)
			fire_target.current_room = unit.current_room
			fire_target.set_physics_process(false)
			var hp_before = fire_target.hp
			game.combat_scene.use_selected_skill(0)
			_expect(fire_target.hp == hp_before, "%s 화염구 도착 전에는 피해 없음" % rule_id)
			await get_tree().create_timer(0.45).timeout
			var actual_damage = hp_before - fire_target.hp
			_expect(actual_damage > 52, "%s 화염구 피해/사거리 업그레이드 적용" % rule_id)
	game._clear_units()
	game._set_screen(Constants.SCREEN_MANAGEMENT)

func _check_monster_screen_buttons(game: Node) -> void:
	game._open_monster_screen()
	await get_tree().process_frame
	_expect(game.current_screen == Constants.SCREEN_MONSTER, "몬스터 관리 화면 열림")
	var train_button = _find_button_by_text(game.ui_layer, "훈련")
	_expect(train_button != null and not train_button.disabled, "몬스터 훈련 버튼 활성")
	var gold_before = GameState.gold
	var exp_before = int(game.monster_roster[game.selected_monster_id].get("exp", 0))
	if train_button != null:
		train_button.pressed.emit()
		await get_tree().process_frame
	_expect(GameState.gold == gold_before - 30, "몬스터 화면 훈련 버튼 작동")
	_expect(int(game.monster_roster[game.selected_monster_id].get("exp", 0)) > exp_before, "훈련 EXP 증가")
	var back_button = _find_button_by_text(game.ui_layer, "돌아가기")
	_expect(back_button != null and not back_button.disabled, "몬스터 돌아가기 버튼 활성")
	if back_button != null:
		back_button.pressed.emit()
		await get_tree().process_frame
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "몬스터 화면 돌아가기 버튼 작동")

func _check_invalid_combat_actions(game: Node) -> void:
	game._start_combat()
	await get_tree().physics_frame
	var imp = _unit_by_id(game.monster_units, "imp")
	_expect(imp != null, "잘못된 전투 입력 검증용 임프 생성")
	if imp == null:
		return
	for enemy in game.enemy_units:
		enemy.down = true
		enemy.hp = 0
	game._select_unit(imp)
	var mana_before = GameState.mana
	var used_without_target = game.combat_scene.use_selected_skill(0)
	_expect(not used_without_target, "대상 없는 화염구 사용 거부")
	_expect(GameState.mana == mana_before, "대상 없는 화염구가 마력을 소모하지 않음")
	_expect(not imp.skill_cooldowns.has("fireball"), "대상 없는 화염구가 재사용 대기시간을 만들지 않음")

	imp.down = true
	imp.hp = 0
	var direct_control_started = game.combat_scene.enable_direct_control()
	_expect(not direct_control_started and not imp.direct_control, "전투 불능 몬스터 직접 조종 거부")
	var downed_mana_before = GameState.mana
	var downed_skill_used = game.combat_scene.use_selected_skill(0)
	_expect(not downed_skill_used and GameState.mana == downed_mana_before, "전투 불능 몬스터 스킬 사용 거부")
	game._set_screen(Constants.SCREEN_COMBAT)
	await get_tree().process_frame
	var direct_button = _find_button_by_text(game.ui_layer, "직접 조종")
	var skill_button = _find_button_by_text(game.ui_layer, "화염구")
	_expect(direct_button != null and direct_button.disabled, "전투 불능 몬스터 직접 조종 버튼 비활성")
	_expect(skill_button != null and skill_button.text.contains("화염구") and skill_button.text.contains("전투 불능"), "기술 버튼에 실제 기술명과 전투 불능 상태 표시")
	_expect(skill_button != null and skill_button.disabled, "전투 불능 몬스터 기술 버튼 비활성")

func _check_core_loop(game: Node) -> void:
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "프로젝트 시작 시 관리 화면")

	await _check_monster_screen_buttons(game)

	game.selected_room = "spike_corridor"
	game._set_room_directive(Constants.ROOM_DIRECTIVE_TRAP_LURE)
	_expect(game.room_directives["spike_corridor"] == Constants.ROOM_DIRECTIVE_TRAP_LURE, "방 지침 변경 반영")

	game._set_global_directive(Constants.DIRECTIVE_ALL_OUT)
	_expect(game.global_directive == Constants.DIRECTIVE_ALL_OUT, "전체 지침 변경 반영")

	game.selected_room = "entrance"
	game._build_selected_slot()
	await get_tree().process_frame
	_expect(game.build_pick_mode, "건설 버튼이 위치 선택 모드로 전환")
	_expect(game.build_pick_facility_id == "watch_post", "건설 모드 기본 시설은 감시 초소")
	var preview_gold_before = GameState.gold
	var preview_mana_before = GameState.mana
	var slot_facility_before = str(game.rooms["slot_01"].get("facility_role", ""))
	var recovery_facility_before = str(game.rooms["recovery"].get("facility_role", ""))
	game._handle_left_click(game.graph.center("slot_01"))
	await get_tree().process_frame
	_expect(game.selected_room == "slot_01" and game.build_pick_mode and game.build_preview_room_id == "slot_01", "건설 모드에서 맵 클릭으로 후보 미리보기")
	_expect(game.rooms["slot_01"].get("facility_role", "") == "build_slot", "건설 미리보기 단계에서는 방 상태 유지")
	_expect(game._build_preview_route_line().find("경로") >= 0, "건설 미리보기에 경로 피드백 제공")
	game._select_build_target_room("throne")
	await get_tree().process_frame
	_expect(game.build_pick_mode and game.build_preview_room_id == "" and not game._build_preview_ready(), "고정 시설 클릭 시 이전 건설 후보와 확정 상태 해제")
	_expect(game.build_blocked_room_id == "throne" and game._build_preview_summary().find("건설 불가") >= 0, "고정 시설의 건설 불가 이유 표시")
	_expect(game._build_preview_route_line().find("고정 시설") >= 0, "고정 시설 클릭 뒤 경로 안내를 차단 이유로 갱신")
	game._select_build_target_room("recovery")
	await get_tree().process_frame
	_expect(game.build_preview_room_id == "recovery" and game.build_blocked_room_id == "" and game._build_preview_ready(), "차단 뒤 새 건설 후보 재선택")
	_expect(game._build_preview_route_line("recovery").find("경로") >= 0, "재선택한 후보 기준 경로 피드백 갱신")
	game._cancel_management_action_mode()
	await get_tree().process_frame
	_expect(not game.build_pick_mode and game.build_preview_room_id == "" and game.build_blocked_room_id == "", "건설 미리보기 취소는 후보 상태를 모두 해제")
	_expect(str(game.rooms["slot_01"].get("facility_role", "")) == slot_facility_before and str(game.rooms["recovery"].get("facility_role", "")) == recovery_facility_before, "건설 미리보기 재선택과 취소는 시설을 바꾸지 않음")
	_expect(GameState.gold == preview_gold_before and GameState.mana == preview_mana_before, "건설 미리보기 재선택과 취소는 자원을 쓰지 않음")
	game._build_selected_slot()
	game._handle_left_click(game.graph.center("slot_01"))
	await get_tree().process_frame
	_expect(game._confirm_build_preview(), "건설 미리보기 확정")
	await get_tree().process_frame
	_expect(game.selected_room == "slot_01" and not game.facility_change_panel_open and not game.build_pick_mode, "건설 확정 후 건설 모드 종료")
	_expect(game.rooms["slot_01"].get("facility_role", "") == "watch_post", "확정 대상에 감시 초소 건설")

	game._start_monster_placement("imp")
	await get_tree().process_frame
	_expect(game.deploy_pick_monster_id == "imp", "몬스터 버튼이 방 선택 배치 모드로 전환")
	game._handle_left_click(game.graph.center("barracks"))
	await get_tree().process_frame
	_expect(game.monster_roster["imp"]["room"] == "barracks" and game.deploy_pick_monster_id == "", "배치 모드에서 맵 클릭으로 몬스터 방 이동")

	var goblin_start = game._management_monster_preview_position("goblin")
	var recovery_target = game.graph.center("recovery")
	_expect(game._start_management_monster_drag(goblin_start), "관리 화면 몬스터 드래그 시작")
	game._update_management_monster_drag(recovery_target)
	game._finish_management_monster_drag(recovery_target)
	_expect(game.monster_roster["goblin"]["room"] == "recovery", "드래그로 몬스터 방 배치")

	var gold_before_purpose = GameState.gold
	game.selected_room = "barracks"
	game._change_selected_room_facility("treasure")
	_expect(game.rooms["barracks"].get("facility_role", "") == "treasure", "방 용도 변경으로 보물 보관실 이동")
	_expect(game.rooms["treasure"].get("facility_role", "") == "build_slot", "기존 보물 보관실 빈 슬롯 전환")
	_expect(GameState.gold == gold_before_purpose - 120, "방 용도 변경 비용 차감")
	game._spawn_enemy("thief")
	var thief_probe = _unit_by_id(game.enemy_units, "thief")
	_expect(thief_probe != null and thief_probe.goal_room == "barracks", "도둑 목표가 현재 보물 보관실을 추적")
	if thief_probe != null:
		_expect(thief_probe.threat_warning_text() == "보물방 침투", "도둑 이동 중 보물방 침투 경고 표시")
		thief_probe.set_tactical_state(Constants.UNIT_STATE_LOOTING, "보물 약탈", "금화")
		_expect(thief_probe.threat_warning_text() == "약탈 중", "도둑 약탈 중 긴급 경고 표시")
		thief_probe.global_position = game.graph.center("barracks")
		thief_probe.current_room = "barracks"
		thief_probe.goal_room = "barracks"
		thief_probe.stop_navigation()
		game.thief_steal_timers[thief_probe] = -999.0
		game.combat_scene.update_enemy_path(thief_probe)
		_expect(thief_probe.goal_room == "entrance" and not thief_probe.path_points.is_empty(), "도둑이 도주 중 교전으로 경로를 잃어도 입구 탈출 경로 복구")
		_expect(thief_probe.threat_warning_text() == "", "도둑 탈출 중 위협 경고 해제")
	game._clear_units()

	game._start_combat()
	await get_tree().physics_frame
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "전투 시작 후 전투 화면")
	_expect(game.monster_units.size() == 3, "슬라임, 고블린, 임프 배치")
	var selected_room_before_floor_click = game.selected_room
	game._handle_left_click(game.graph.center("recovery"))
	_expect(game.selected_room == selected_room_before_floor_click, "전투 중 맵 바닥 클릭은 방 선택하지 않음")

	var slime = _unit_by_id(game.monster_units, "slime")
	var goblin = _unit_by_id(game.monster_units, "goblin")
	var imp = _unit_by_id(game.monster_units, "imp")
	var slime_position_before_room_probe = slime.global_position
	slime.global_position = game._clamp_to_combat_walkable(game.graph.center("slot_01"))
	game.combat_scene.refresh_unit_rooms()
	_expect(slime.current_room == "slot_01", "쿼터뷰 건설칸 중심을 가시 복도가 아닌 실제 방으로 판정")
	slime.global_position = slime_position_before_room_probe
	game.combat_scene.refresh_unit_rooms()
	_expect(slime.sprite.scale.x <= 0.5 and imp.sprite.scale.x <= 0.5, "전투 캐릭터 스프라이트 축소")
	_expect(slime.sprite.position.y <= -34.0 and imp.sprite.position.y <= -40.0, "캐릭터 발 위치 기준 정렬")
	var zoom_before = game.combat_view_zoom
	game._adjust_combat_zoom(1, Vector2(960, 540))
	_expect(game.combat_view_zoom > zoom_before, "전투 휠 확대")
	game._adjust_combat_zoom(-1, Vector2(960, 540))
	_expect(game.combat_view_zoom <= zoom_before + 0.01, "전투 휠 축소")
	var outside_point = Vector2(40, 40)
	var clamped_point = game._clamp_to_combat_walkable(outside_point)
	_expect(game.graph.is_walkable(clamped_point), "던전 밖 이동 좌표 보행 영역 보정")
	_expect(slime.state_label() != "" and slime.status_line() != "", "아군 상태 UI용 상태값 초기화")
	_expect(slime.sprite.sprite_frames.has_animation("move_down"), "이동 애니메이션 슬롯")
	_expect(slime.sprite.sprite_frames.has_animation("attack_down"), "공격 애니메이션 슬롯")
	_expect(slime.sprite.sprite_frames.has_animation("skill_down"), "스킬 애니메이션 슬롯")
	_expect(slime.sprite.sprite_frames.get_frame_count("move_down") >= 4, "몬스터 이동 애니메이션 다중 프레임")
	_expect(slime.sprite.sprite_frames.get_frame_count("attack_down") >= 4, "몬스터 공격 애니메이션 다중 프레임")
	_expect(goblin.sprite.sprite_frames.get_frame_count("attack_down") >= 4, "고블린 공격 원본 4프레임 로드")
	_expect(imp.sprite.sprite_frames.get_frame_count("attack_down") >= 4, "임프 공격 원본 4프레임 로드")
	_expect(slime.sprite.sprite_frames.get_frame_count("skill_down") >= 4, "몬스터 스킬 애니메이션 다중 프레임")
	var attack_frame_time = float(slime.sprite.sprite_frames.get_frame_count("attack_down")) / slime.sprite.sprite_frames.get_animation_speed("attack_down")
	slime.play_attack(slime.global_position + Vector2(100, 0))
	_expect(slime.attack_anim_timer >= attack_frame_time, "공격 애니메이션이 전체 프레임을 보여줄 시간 확보")
	_expect(slime.action_direction.x > 0.9, "공격 대상 방향 반영")
	slime.play_hit(slime.global_position - Vector2(100, 0))
	_expect(slime.hit_anim_timer > 0.0 and slime.hit_direction.x > 0.9, "피격 반동 방향과 지속시간 적용")
	_expect(game.effect_frame_sets.get("fireball", []).size() >= 4, "화염구 이펙트 다중 프레임")
	_expect(game.effect_frame_sets.get("shield", []).size() >= 4, "방어 스킬 이펙트 다중 프레임")
	await _check_unit_collision_avoidance(game, slime)
	game._select_unit(slime)
	game._enable_direct_control()
	_expect(slime.direct_control and slime.path_points.is_empty(), "직접 조종 시작 시 AI 이동 경로 정지")
	var command_point = game.graph.center("barracks")
	game._handle_right_click(command_point)
	_expect(slime.direct_control and slime.command_point == command_point, "몬스터 직접 조종 이동 명령")
	game._handle_right_click(outside_point)
	_expect(game.graph.is_walkable(slime.command_point), "직접 이동 명령 던전 내부 보정")
	_expect(slime.tactical_state == Constants.UNIT_STATE_DIRECT_CONTROL, "직접 조종 상태 표시")
	game._release_direct_control()
	game._select_unit(slime)
	var shield_effects_before = game.effect_root.get_child_count()
	game._handle_key(KEY_1)
	_expect(slime.shield_timer > 0.0, "키보드 1번 스킬 입력")
	_expect(slime.tactical_state == Constants.UNIT_STATE_CAST_SKILL, "스킬 사용 상태 표시")
	_expect(game.effect_root.get_child_count() > shield_effects_before, "방어 스킬 이펙트 생성")
	game._handle_key(KEY_2)
	_expect(slime.skill_cooldowns.has("hold_corridor"), "키보드 2번 스킬 입력")
	_expect(slime.guard_bonus > 0, "통로 막기 방어 보너스")

	game._spawn_ready_enemies(0.2)
	_expect(game.enemy_units.size() > 0, "적이 입구에서 등장")
	var enemy = game.enemy_units[0]
	_expect(enemy.goal_room != "" or not enemy.path_points.is_empty(), "적 이동/교전 목표 설정")
	_expect(enemy.sprite.sprite_frames.get_frame_count("move_down") >= 4, "적 이동 뛰기 애니메이션 다중 프레임")
	enemy.global_position = imp.global_position + Vector2(80, 0)
	game._select_unit(imp)
	game.combat_scene.preview_selected_skill(0)
	_expect(imp.skill_preview_active and imp.skill_preview_range >= 320.0, "기술 버튼 화염구 사거리 미리보기")
	_expect(imp.skill_preview_targets.has(enemy), "기술 버튼 화염구 예상 대상 미리보기")
	game.combat_scene.clear_skill_preview()
	_expect(not imp.skill_preview_active, "기술 버튼 미리보기 종료")

	enemy.global_position = game.graph.center("barracks")
	enemy.current_room = "barracks"
	enemy.set_physics_process(false)
	_expect(game.graph.is_walkable(enemy.global_position), "직접 공격 검증 대상이 보행 셀 위에 있음")
	game._select_unit(slime)
	game._enable_direct_control()
	game._handle_right_click(enemy.global_position)
	_expect(slime.command_target == enemy and slime.command_point == Vector2.ZERO, "우클릭 적 직접 공격 대상 지정")
	var path_count_before_manual_attack = slime.path_points.size()
	var position_before_manual_attack = slime.global_position
	for i in range(45):
		await get_tree().physics_frame
	var moved_for_manual_attack = slime.global_position.distance_to(position_before_manual_attack) > 8.0
	var path_progressed_for_manual_attack = slime.path_points.size() < path_count_before_manual_attack
	_expect(moved_for_manual_attack or path_progressed_for_manual_attack, "직접 공격 대상 경로 추적 이동")
	enemy.set_physics_process(true)
	game._release_direct_control()

	enemy.global_position = slime.global_position + Vector2(30, 0)
	enemy.current_room = slime.current_room
	slime.set_path([slime.global_position + Vector2(96, 0)])
	slime.velocity = Vector2(30, 0)
	game.combat_scene.update_monster_path(slime)
	_expect(slime.path_points.is_empty() and slime.velocity.length() <= 0.01 and slime.tactical_state == Constants.UNIT_STATE_ATTACK, "근접 교전 사거리 안에서 이동 정지")

	enemy.global_position = slime.global_position + Vector2(30, 0)
	enemy.current_room = slime.current_room
	slime.attack_cooldown = 0.0
	var hp_before_attack = enemy.hp
	game._try_attack(slime, [enemy])
	_expect(enemy.hp < hp_before_attack, "몬스터 자동 공격 피해")
	_expect(slime.target == enemy and slime.target_focus_timer > 0.0, "기본 공격 대상 표시 활성")
	await get_tree().create_timer(0.22).timeout
	_expect(enemy.hit_focus_timer > 0.0, "피격 강조 고리 활성")
	game.combat_scene.clear_effects()
	await get_tree().process_frame
	for damage_probe in [7, 12, 18]:
		game.combat_scene.spawn_damage_number(enemy.global_position, damage_probe, enemy.faction)
	var damage_labels: Array = []
	for effect in game.effect_root.get_children():
		if effect is Label and str(effect.get_meta("combat_feedback_kind", "")) == "damage":
			damage_labels.append(effect)
	_expect(damage_labels.size() == 3, "연속 피해 숫자 3개 생성")
	if damage_labels.size() == 3:
		_expect(str(damage_labels[0].text).begins_with("-") and str(damage_labels[1].text).begins_with("-") and str(damage_labels[2].text).begins_with("-"), "피해 숫자를 회복과 구분하는 음수 표기")
		_expect(damage_labels[0].position != damage_labels[1].position and damage_labels[1].position != damage_labels[2].position and damage_labels[0].position != damage_labels[2].position, "같은 위치의 연속 피해 숫자 분산")
		_expect(int(damage_labels[0].get_meta("damage_number_lane", -1)) == 0 and int(damage_labels[1].get_meta("damage_number_lane", -1)) == 1 and int(damage_labels[2].get_meta("damage_number_lane", -1)) == 2, "연속 피해 숫자 표시 순서 유지")
	_expect(int(game.battle_contribution_stats.get("slime", {}).get("damage_dealt", 0)) > 0, "기본 공격 피해를 슬라임 활약으로 기록")

	enemy.hp = enemy.max_hp
	enemy.down = false
	enemy.visible = true
	enemy.global_position = imp.global_position + Vector2(90, 0)
	enemy.current_room = imp.current_room
	game._select_unit(imp)
	var effect_count = game.effect_root.get_child_count()
	game._handle_key(KEY_1)
	_expect(enemy.hp == enemy.max_hp and game.effect_root.get_child_count() > effect_count, "임프 화염구 투사체 발사 시 피해 지연")
	_expect(imp.target == enemy and imp.target_focus_timer > 0.0, "화염구 대상 표시 활성")
	await get_tree().create_timer(0.16).timeout
	_expect(enemy.hp < enemy.max_hp, "임프 화염구 투사체 도착 시 피해 적용")

	enemy.hp = enemy.max_hp
	enemy.down = false
	enemy.current_room = "spike_corridor"
	enemy.global_position = game.graph.center("spike_corridor")
	game.trap_cooldown = 0.0
	var hp_before_trap = enemy.hp
	game._update_room_effects(2.0)
	_expect(game.quarter_renderer.debug_active_trap_animation_count() == 1, "spike trap trigger animation starts")
	_expect(enemy.hp < hp_before_trap, "가시 복도 함정 피해")

	slime.shield_timer = 0.0
	slime.damage_reduction = 0.0
	slime.guard_timer = 0.0
	slime.guard_bonus = 0
	slime.hp = slime.max_hp
	slime.down = false
	slime.attack_cooldown = 999.0
	enemy.hp = enemy.max_hp
	enemy.down = false
	enemy.atk = 90
	enemy.global_position = slime.global_position + Vector2(30, 0)
	enemy.current_room = slime.current_room
	enemy.attack_cooldown = 0.0
	game._try_attack(enemy, [slime])
	_expect(int(game.battle_contribution_stats.get("slime", {}).get("damage_absorbed", 0)) >= 40, "실제 피격 압박을 슬라임 방어 활약으로 기록")

	enemy.hp = 1
	enemy.down = false
	enemy.visible = true
	enemy.attack_cooldown = 999.0
	slime.attack_cooldown = 0.0
	game._try_attack(slime, [enemy])
	_expect(not enemy.is_alive(), "슬라임이 빈사 적을 마무리")
	_expect(int(game.battle_contribution_stats.get("slime", {}).get("finishing_blows", 0)) >= 1, "마무리 일격을 슬라임 활약으로 기록")

	for alive_enemy in game.enemy_units:
		if alive_enemy.is_alive():
			alive_enemy.receive_damage(9999)
	game.wave_manager.next_index = game.wave_manager.schedule.size()
	game._check_combat_end()
	_expect(game.current_screen == Constants.SCREEN_RESULT, "결산 화면 표시")
	_expect(_result_has_line(game, "전투 시간"), "결산에 전투 시간과 생존 몬스터 표시")
	_expect(_result_has_line(game, "잔여 전력"), "결산에 몬스터 잔여 체력 표시")
	_expect(_result_has_line(game, "지침 효과"), "결산에 전투 지침 효과 표시")
	_expect(game.result_summary.get("metrics", {}).has("directive_effects"), "결산에 비교 가능한 전투 지표 저장")
	_expect(game.result_summary.get("metrics", {}).has("remaining_monster_hp"), "결산에 몬스터 잔여 체력 지표 저장")
	_expect(game.result_summary.get("metrics", {}).has("monster_contributions"), "결산에 몬스터별 활약 원본 지표 저장")
	var slime_growth = _growth_row(game, "slime")
	var imp_growth = _growth_row(game, "imp")
	_expect(not slime_growth.is_empty() and not imp_growth.is_empty(), "결산에 몬스터별 성장 행 생성")
	var slime_activity = int(slime_growth.get("activity_exp", 0))
	var slime_breakdown: Dictionary = slime_growth.get("activity_breakdown", {})
	_expect(slime_activity > 0 and slime_activity <= Constants.ACTIVITY_EXP_CAP, "슬라임 활약 EXP를 1~%d 범위로 제한" % Constants.ACTIVITY_EXP_CAP)
	_expect(int(slime_growth.get("exp_gain", -1)) == int(slime_growth.get("shared_exp", 0)) + slime_activity, "총 EXP가 공유 EXP와 활약 EXP의 합")
	_expect(int(slime_growth.get("shared_exp", -1)) == int(imp_growth.get("shared_exp", -2)), "공유 EXP는 모든 수비 몬스터에게 동일 지급")
	_expect(int(slime_breakdown.get("defense", 0)) > 0, "결산 활약 근거에 피해 흡수 포함")
	_expect(int(slime_breakdown.get("finisher", 0)) > 0, "결산 활약 근거에 마무리 포함")
	_expect(_find_label_by_text(game.ui_layer, "공유 +") != null, "결산 카드에 공유 EXP 표시")
	_expect(_find_label_by_text(game.ui_layer, "활약 +") != null, "결산 카드에 활약 EXP 표시")
	var growth_preview_label = _find_label_by_text(game.ui_layer, "선택 후")
	if growth_preview_label == null:
		growth_preview_label = _find_label_by_text(game.ui_layer, "선택 시 Lv.")
	_expect(growth_preview_label != null, "결산에서 집중 성장 결과 미리보기 표시")
	var focus_button = _find_button_by_text(game.ui_layer, "집중 +")
	_expect(focus_button != null and not focus_button.disabled, "결산에서 집중 성장 선택 버튼 표시")
	var slime_exp_before_focus = int(game.monster_roster["slime"].get("exp", 0))
	var focus_choice_day = GameState.day
	var slime_stats_before_preparation: Dictionary = game._scaled_monster_stats("slime")
	_expect(game._choose_result_growth("slime"), "결산 집중 성장 선택 적용")
	await get_tree().process_frame
	slime_growth = _growth_row(game, "slime")
	_expect(game.result_growth_choice_applied and game.result_growth_choice_monster_id == "slime", "결산 집중 성장 선택 상태 저장")
	_expect(int(slime_growth.get("choice_bonus_exp", 0)) == game._result_growth_choice_bonus(), "결산 집중 성장 보너스 EXP 기록")
	_expect(int(slime_growth.get("exp_gain", 0)) == int(slime_growth.get("shared_exp", 0)) + int(slime_growth.get("activity_exp", 0)) + int(slime_growth.get("choice_bonus_exp", 0)), "집중 성장 포함 총 EXP 계산")
	_expect(int(game.monster_roster["slime"].get("exp", 0)) >= slime_exp_before_focus, "집중 성장 EXP가 로스터에 반영")
	_expect(int(game.monster_roster["slime"].get("growth_preparation_day", -1)) == focus_choice_day + 1, "집중 성장 다음 방어 준비 날짜 저장")
	_expect(str(game.last_growth_choice_summary.get("preparation_summary", "")).find("최대 HP") >= 0, "집중 성장 준비 효과를 결산 요약에 기록")
	_expect(_find_button_by_text(game.ui_layer, "선택됨") != null, "선택된 성장 버튼 표시")
	_expect(_find_label_by_text(game.ui_layer, "다음 방어 준비") != null, "선택 뒤 다음 방어 준비 효과 표시")
	GameState.day = focus_choice_day + 1
	var slime_stats_with_preparation: Dictionary = game._scaled_monster_stats("slime")
	_expect(game._growth_preparation_active("slime"), "다음 날 선택 몬스터 준비 효과 활성화")
	_expect(int(slime_stats_with_preparation.get("max_hp", 0)) == int(slime_stats_before_preparation.get("max_hp", 0)) + 24, "슬라임 집중 준비 최대 HP +24 적용")
	_expect(int(slime_stats_with_preparation.get("def", 0)) == int(slime_stats_before_preparation.get("def", 0)) + 1, "슬라임 집중 준비 방어력 +1 적용")
	GameState.day = focus_choice_day + 2
	var slime_stats_after_preparation: Dictionary = game._scaled_monster_stats("slime")
	_expect(not game._growth_preparation_active("slime"), "재선택하지 않은 다음 날짜에 준비 효과 만료")
	_expect(int(slime_stats_after_preparation.get("max_hp", 0)) == int(slime_stats_before_preparation.get("max_hp", 0)), "준비 효과 만료 뒤 기본 최대 HP 복원")
	GameState.day = focus_choice_day
	game._review_growth_from_result()
	await get_tree().process_frame
	_expect(game.result_growth_reviewed, "결산 성장 확인 상태 저장")
	_expect(_find_label_by_text(game.ui_layer, "다음 날 진행할 수 있습니다") != null, "성장 확인 뒤 다음 진행 안내로 전환")

func _check_early_specialization(game: Node) -> void:
	GameState.day = 2
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	_expect(not DataRegistry.specialization("goblin_treasure_hunter").is_empty(), "초기 전술 특화 데이터 로드")
	_expect(game._early_specialization_required_for_current_day(), "DAY 02 전투 전에 첫 전술 특화 필요")
	game._start_combat()
	await get_tree().process_frame
	_expect(game.current_screen == Constants.SCREEN_MONSTER, "특화 없이 DAY 02 전투 시작 시 몬스터 화면으로 안내")
	var base_stats = game._scaled_monster_stats("goblin")
	var chosen = game._choose_early_specialization("goblin", "goblin_treasure_hunter")
	var specialized_stats = game._scaled_monster_stats("goblin")
	_expect(chosen, "고블린 도둑 사냥꾼 특화 선택")
	_expect(float(specialized_stats.get("move_speed", 0.0)) > float(base_stats.get("move_speed", 0.0)), "전술 특화 이동 속도 반영")
	_expect(str(game.monster_roster["goblin"].get("role_tag", "")).find("보물") >= 0, "전술 특화 역할 태그 반영")
	_expect(not game._choose_early_specialization("imp", "imp_artillery"), "DAY 02~03 팀 내 두 번째 특화 제한")
	_expect(not game._early_specialization_required_for_current_day(), "첫 특화 선택 후 전투 조건 충족")
	game.monster_roster["goblin"]["growth_preparation_id"] = "pursuit_drill"
	game.monster_roster["goblin"]["growth_preparation_day"] = 2
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	game._start_combat()
	await get_tree().physics_frame
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "특화 선택 후 DAY 02 전투 시작")
	var goblin = _unit_by_id(game.monster_units, "goblin")
	_expect(goblin != null and str(goblin.role).find("보물") >= 0, "전투 유닛에 특화 역할 적용")
	_expect(goblin != null and goblin.has_growth_preparation() and goblin.growth_preparation_name == "추격 훈련", "전투 유닛에 집중 준비 상태 적용")
	var preparation_feedback_found := false
	for effect in game.effect_root.get_children():
		if str(effect.get_meta("combat_feedback_kind", "")) == "growth_preparation":
			preparation_feedback_found = true
			break
	_expect(preparation_feedback_found, "전투 시작 집중 준비 발동 문구 생성")
	if goblin != null:
		game._select_unit(goblin)
		game._set_screen(Constants.SCREEN_COMBAT)
		await get_tree().process_frame
		_expect(_find_label_by_text(game.ui_layer, "집중 준비 · 추격 훈련") != null, "선택 유닛 정보창에 집중 준비 표시")

func _check_ai_reengagement(game: Node) -> void:
	GameState.day = 2
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	_expect(game._choose_early_specialization("goblin", "goblin_treasure_hunter"), "AI 재교전 검증용 도둑 사냥꾼 선택")
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	game._start_combat()
	await get_tree().physics_frame
	game.combat_paused = true
	var goblin = _unit_by_id(game.monster_units, "goblin")
	var imp = _unit_by_id(game.monster_units, "imp")
	game._spawn_enemy("thief")
	var thief = game.enemy_units[-1]
	thief.down = true
	thief.visible = false
	game._spawn_enemy("explorer")
	var explorer = game.enemy_units[-1]
	for enemy in game.enemy_units:
		if enemy != explorer:
			enemy.down = true
			enemy.visible = false
	_expect(goblin != null and imp != null and explorer != null, "AI 재교전 검증 유닛 준비")
	if goblin == null or imp == null or explorer == null:
		return
	goblin.global_position = game.graph.center("spike_corridor")
	goblin.current_room = "spike_corridor"
	goblin.stop_navigation()
	explorer.global_position = goblin.global_position + Vector2(28, 0)
	explorer.current_room = "spike_corridor"
	explorer.goal_room = "throne"
	game.global_directive = Constants.DIRECTIVE_DEFENSE
	game.combat_scene.update_monster_path(goblin)
	_expect(goblin.tactical_state == Constants.UNIT_STATE_ATTACK and goblin.target_text == explorer.display_name, "도둑 처리 뒤 사냥꾼이 일반 적과 재교전")

	imp.global_position = game.graph.center("recovery")
	imp.current_room = "recovery"
	imp.goal_room = "recovery"
	imp.stop_navigation()
	var staging_point = game.graph.center("entrance")
	game.combat_scene.move_unit_to_point(imp, staging_point)
	var first_route_size = imp.path_points.size()
	if first_route_size > 1:
		imp.path_points.pop_front()
	var progressed_route_size = imp.path_points.size()
	game.combat_scene.move_unit_to_point(imp, staging_point)
	_expect(first_route_size > 1 and imp.path_points.size() == progressed_route_size, "같은 목적지 이동 경로를 매 순간 초기화하지 않음")

	explorer.global_position = game.graph.center("throne")
	explorer.current_room = "throne"
	explorer.goal_room = "throne"
	imp.global_position = game.graph.center("recovery")
	imp.current_room = "recovery"
	imp.goal_room = "recovery"
	imp.hp = imp.max_hp
	imp.stop_navigation()
	game.room_directives["recovery"] = Constants.ROOM_DIRECTIVE_RETREAT
	game.global_directive = Constants.DIRECTIVE_SURVIVAL
	game.combat_scene.update_monster_path(imp)
	_expect(imp.goal_room == "throne" and imp.intent_text == "왕좌 긴급 방어" and not imp.path_points.is_empty(), "회복 완료 뒤 후퇴 지시보다 왕좌 긴급 방어 우선")

	for monster in game.monster_units:
		monster.hp = 0
		monster.down = true
	explorer.attack_cooldown = 0.0
	var throne_hp_before := GameState.demon_lord_hp
	game.combat_scene.update_room_effects(0.0)
	var expected_unopposed_damage: int = maxi(8, int(explorer.atk)) * 3
	_expect(throne_hp_before - GameState.demon_lord_hp == expected_unopposed_damage, "몬스터 전멸 뒤 무방비 왕좌 공격 3배 적용")

func _check_facility_combat_effects(game: Node) -> void:
	_expect(game._change_room_facility("slot_01", "watch_post"), "감시 초소 건설 효과 준비")
	_expect(game.rooms["slot_01"].get("facility_role", "") == "watch_post", "감시 초소 시설 역할 적용")
	game.monster_roster["slime"]["room"] = "barracks"
	game._start_combat()
	await get_tree().physics_frame

	var slime = _unit_by_id(game.monster_units, "slime")
	_expect(slime != null, "시설 효과 검증용 슬라임 생성")
	if slime == null:
		return
	var barracks_room = game._room_by_facility("barracks", "")
	var watch_room = game._room_by_facility("watch_post", "")
	var recovery_room = game._room_by_facility("recovery", "")
	_expect(barracks_room != "" and watch_room != "" and recovery_room != "", "시설 효과 대상 방 확인")
	if barracks_room == "" or watch_room == "" or recovery_room == "":
		return

	slime.global_position = game.graph.center(barracks_room)
	slime.current_room = barracks_room
	slime.assigned_room = barracks_room
	slime.attack_cooldown = 0.0
	slime.set_physics_process(false)
	game._spawn_enemy("explorer")
	var enemy = game.enemy_units[game.enemy_units.size() - 1]
	enemy.global_position = slime.global_position + Vector2(8, 0)
	enemy.current_room = barracks_room
	enemy.attack_cooldown = 999.0
	enemy.set_physics_process(false)
	var base_barracks_damage = DamageService.compute(slime, enemy)
	var enemy_hp_before = enemy.hp
	game.combat_scene.try_attack(slime, [enemy])
	_expect(enemy_hp_before - enemy.hp > base_barracks_damage, "병영 안 아군 공격 보너스 적용")
	_expect(int(game.facility_effect_stats.get("barracks_bonus_damage", 0)) > 0, "병영 추가 피해 통계 기록")

	enemy.hp = enemy.max_hp
	enemy.attack_cooldown = 0.0
	slime.hp = slime.max_hp
	slime.attack_cooldown = 999.0
	var base_taken_damage = DamageService.compute(enemy, slime)
	var slime_hp_before = slime.hp
	game.combat_scene.try_attack(enemy, [slime])
	_expect(slime_hp_before - slime.hp < base_taken_damage, "병영 안 아군 피해 감소 적용")
	_expect(int(game.facility_effect_stats.get("barracks_damage_reduced", 0)) > 0, "병영 피해 감소 통계 기록")
	_expect(int(game.battle_contribution_stats.get("slime", {}).get("facility_value", 0)) > 0, "병영 효과를 슬라임 시설 활약으로 기록")

	game._spawn_enemy("explorer")
	var watched_enemy = game.enemy_units[game.enemy_units.size() - 1]
	watched_enemy.global_position = game.graph.center(watch_room)
	watched_enemy.current_room = watch_room
	watched_enemy.slow_factor = 1.0
	watched_enemy.slow_timer = 0.0
	watched_enemy.set_physics_process(false)
	game.combat_scene.update_room_effects(0.2)
	_expect(watched_enemy.slow_timer > 0.0 and watched_enemy.slow_factor <= 0.78, "감시 초소 구역 적 둔화 적용")
	_expect(int(game.facility_effect_stats.get("watch_post_slow_applications", 0)) > 0, "감시 초소 둔화 통계 기록")

	slime.global_position = watched_enemy.global_position + Vector2(8, 0)
	slime.current_room = "entrance"
	slime.attack_cooldown = 0.0
	watched_enemy.hp = watched_enemy.max_hp
	var base_watch_damage = DamageService.compute(slime, watched_enemy)
	var watched_hp_before = watched_enemy.hp
	game.combat_scene.try_attack(slime, [watched_enemy])
	_expect(watched_hp_before - watched_enemy.hp > base_watch_damage, "감시 초소 구역 적 피해 증가 적용")
	_expect(int(game.facility_effect_stats.get("watch_post_bonus_damage", 0)) > 0, "감시 초소 추가 피해 통계 기록")

	slime.current_room = recovery_room
	slime.hp = slime.max_hp - 20
	var wounded_hp = slime.hp
	game.combat_scene.update_room_effects(1.0)
	_expect(slime.hp > wounded_hp, "회복 둥지 전투 중 회복 적용")
	_expect(int(game.facility_effect_stats.get("recovery_healing", 0)) > 0, "회복 둥지 회복 통계 기록")
	_expect(int(game.battle_contribution_stats.get("slime", {}).get("facility_value", 0)) > 0, "회복량을 슬라임 시설 활약으로 기록")
	var facility_result_lines: Array = game._facility_effect_result_lines()
	_expect(not facility_result_lines.is_empty() and str(facility_result_lines[0]).find("시설 기여") >= 0, "전투 결과 시설 기여 문구 생성")

func _check_defeat_branch(game: Node) -> void:
	game._start_combat()
	await get_tree().physics_frame
	GameState.damage_throne(GameState.demon_lord_max_hp)
	game._check_combat_end()
	_expect(GameState.defeat and game.current_screen == Constants.SCREEN_RESULT, "왕좌의 방 HP 0 패배")

func _check_three_day_victory(game: Node) -> void:
	for day in range(1, GameState.max_day + 1):
		_expect(GameState.day == day, "DAY %d 시작" % day)
		if game._early_specialization_required_for_current_day():
			_expect(game._choose_early_specialization("goblin", "goblin_treasure_hunter"), "DAY %d 첫 전술 특화 선택" % day)
			game._set_screen(Constants.SCREEN_MANAGEMENT)
		game._start_combat()
		await get_tree().physics_frame
		game.wave_manager.next_index = game.wave_manager.schedule.size()
		var saw_trainee_hero := false
		for entry in game.wave_manager.schedule:
			game._spawn_enemy(str(entry.get("enemy_id", "explorer")))
		for enemy in game.enemy_units:
			if enemy.unit_id == "trainee_hero":
				saw_trainee_hero = true
			if enemy.is_alive():
				enemy.receive_damage(9999)
		game._check_combat_end()
		_expect(game.current_screen == Constants.SCREEN_RESULT, "DAY %d 결과 화면" % day)
		if day < GameState.max_day:
			game._advance_after_result()
			await get_tree().process_frame
		else:
			_expect(saw_trainee_hero, "3일차 수련생 용사 등장")
			_expect(GameState.victory, "3일차 수련생 용사 격퇴 후 데모 클리어")

func _check_unit_collision_avoidance(game: Node, blocker: Node) -> void:
	var original_position = blocker.global_position
	var original_physics = blocker.is_physics_processing()
	blocker.global_position = game.graph.center("barracks")
	blocker.current_room = "barracks"
	blocker.set_physics_process(false)
	game.combat_paused = true
	game._spawn_enemy("thief")
	var thief = _unit_by_id(game.enemy_units, "thief")
	_expect(thief != null, "충돌 검증용 도둑 생성")
	if thief == null:
		blocker.set_physics_process(original_physics)
		blocker.global_position = original_position
		game.combat_paused = false
		return
	thief.global_position = blocker.global_position + Vector2(-120, 0)
	thief.current_room = "barracks"
	thief.goal_room = "barracks"
	thief.set_path([blocker.global_position + Vector2(120, 0)])
	var collision_shape = _collision_shape(thief)
	var circle = collision_shape.shape as CircleShape2D if collision_shape != null else null
	_expect(circle != null and circle.radius <= 18.0, "유닛 충돌체가 근접 전투용 소형 반경")
	var min_distance = INF
	var moved_past_blocker = false
	for i in range(90):
		await get_tree().physics_frame
		min_distance = min(min_distance, thief.global_position.distance_to(blocker.global_position))
		if thief.global_position.x > blocker.global_position.x + 34.0:
			moved_past_blocker = true
	_expect(min_distance >= 22.0, "도둑이 유닛 충돌체를 관통하지 않음")
	_expect(moved_past_blocker, "도둑이 충돌 유닛을 돌아서 이동")
	game.enemy_units.erase(thief)
	thief.queue_free()
	blocker.global_position = original_position
	blocker.set_physics_process(original_physics)
	game.combat_paused = false

func _collision_shape(unit: Node) -> CollisionShape2D:
	for child in unit.get_children():
		if child is CollisionShape2D:
			return child
	return null

func _scheduled_enemy_count(game: Node, enemy_id: String) -> int:
	var count := 0
	for entry in game.wave_manager.schedule:
		if str(entry.get("enemy_id", "")) == enemy_id:
			count += 1
	return count

func _enemy_count_in_schedule(schedule: Array, enemy_id: String) -> int:
	var count := 0
	for entry in schedule:
		if str(entry.get("enemy_id", "")) == enemy_id:
			count += 1
	return count

func _scheduled_enemy_entry(game: Node, enemy_id: String) -> Dictionary:
	for entry in game.wave_manager.schedule:
		if str(entry.get("enemy_id", "")) == enemy_id:
			return entry
	return {}

func _scaled_wave_stat(enemy_id: String, wave_entry: Dictionary, stat_key: String, scale_key: String, minimum: float) -> int:
	var enemy: Dictionary = DataRegistry.enemy(enemy_id)
	var base_value = float(enemy.get(stat_key, 0))
	var flat_bonus = float(wave_entry.get("%s_bonus" % stat_key, 0.0))
	var scale = float(wave_entry.get(scale_key, 1.0))
	return int(round(max(minimum, base_value * scale + flat_bonus)))

func _result_has_line(game: Node, needle: String) -> bool:
	for line in game.result_summary.get("lines", []):
		if str(line).find(needle) >= 0:
			return true
	return false

func _logs_have_line(game: Node, needle: String) -> bool:
	for line in game.logs:
		if str(line).find(needle) >= 0:
			return true
	return false

func _growth_row(game: Node, monster_id: String) -> Dictionary:
	for row_value in game.last_growth_summary:
		var row: Dictionary = row_value
		if str(row.get("monster_id", "")) == monster_id:
			return row
	return {}

func _unit_by_id(units: Array, unit_id: String) -> Node:
	for unit in units:
		if unit.unit_id == unit_id:
			return unit
	return null

func _find_button_by_text(node: Node, needle: String) -> Button:
	if node is Button and String(node.text).find(needle) >= 0:
		return node
	for child in node.get_children():
		var found = _find_button_by_text(child, needle)
		if found != null:
			return found
	return null

func _find_label_by_text(node: Node, needle: String) -> Label:
	if node is Label and String(node.text).find(needle) >= 0:
		return node
	for child in node.get_children():
		var found = _find_label_by_text(child, needle)
		if found != null:
			return found
	return null

func _find_sliders(node: Node) -> Array[HSlider]:
	var result: Array[HSlider] = []
	if node is HSlider:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_sliders(child))
	return result

func _animation_frames_are_unique(frames: SpriteFrames, animation_name: StringName) -> bool:
	var seen_data: Array[PackedByteArray] = []
	for index in range(frames.get_frame_count(animation_name)):
		var texture := frames.get_frame_texture(animation_name, index)
		if texture == null:
			return false
		var image := texture.get_image()
		if image == null or image.is_empty():
			return false
		var data := image.get_data()
		for previous_data in seen_data:
			if data == previous_data:
				return false
		seen_data.append(data)
	return true

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		push_error("FAIL: %s" % message)
		failed = true
