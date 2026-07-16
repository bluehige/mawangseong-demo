extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const CampaignSaveStoreScript = preload("res://scripts/core/CampaignSaveStore.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const TEST_SAVE_PATH := "user://campaign_save_load_smoke.json"
const MUTATION_SAVE_PATH := "user://campaign_save_load_mutation.json"
const STAGE_ONE_ID := "stage_01_cave"
const STAGE_FOUR_ID := "stage_04_citadel"
const FINAL_RAID_ID := "d28_siege_route_recon"

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	CampaignSaveStoreScript.delete(TEST_SAVE_PATH)
	CampaignSaveStoreScript.delete(MUTATION_SAVE_PATH)
	GameState.reset()

	await _check_title_save_states()
	await _check_cycle_doctrine_round_trip()
	await _check_day_28_round_trip()
	await _check_day_30_retry_postgame_and_new_game()

	CampaignSaveStoreScript.delete(TEST_SAVE_PATH)
	CampaignSaveStoreScript.delete(MUTATION_SAVE_PATH)
	if failed:
		print("CAMPAIGN_SAVE_LOAD_SMOKE_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("CAMPAIGN_SAVE_LOAD_SMOKE_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _check_title_save_states() -> void:
	print("[CampaignSaveLoad] 제목 화면 저장 상태")
	CampaignSaveStoreScript.delete(TEST_SAVE_PATH)
	GameState.reset()

	var game := await _new_game()
	_expect(game.current_screen == Constants.SCREEN_TITLE, "저장 기록이 없으면 제목 화면으로 시작")
	_expect(game.campaign_save_status == CampaignSaveStoreScript.STATUS_MISSING, "저장 파일 없음 상태 판정")
	var continue_button := _find_button_by_text(game.ui_layer, "이어하기")
	_expect(continue_button != null and continue_button.disabled, "저장 기록이 없으면 이어하기 비활성화")
	_expect(_find_button_by_text(game.ui_layer, "빠른 시작") != null, "이어하기와 별개로 빠른 시작 유지")
	_expect(_tree_has_text(game.ui_layer, "저장 기록 없음"), "제목 화면에 저장 기록 없음 안내 노출")
	_check_title_layout(game, "저장 기록 없음")
	_expect(_write_raw_text("{}"), "자동 저장 실패 재현용 파일 작성")
	GameState.player_name = "자동저장 경고 검증"
	game._set_campaign_save_path_for_tests("%s/nested.json" % TEST_SAVE_PATH)
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle(4)
	_expect(game.campaign_save_notice.find("자동 저장에 실패") >= 0 and game.campaign_save_error.find("임시 저장 파일") >= 0, "파일 쓰기 실패 원인을 현재 실행 상태에 기록")
	var save_notice_overlay: Node = game.ui_layer.get_node_or_null("CampaignSaveNoticeOverlay")
	_expect(save_notice_overlay != null and _tree_has_text(save_notice_overlay, "자동 저장에 실패"), "자동 저장 실패를 현재 화면 경고로 표시")
	CampaignSaveStoreScript.delete(TEST_SAVE_PATH)
	game._set_campaign_save_path_for_tests(TEST_SAVE_PATH)
	game._set_screen(Constants.SCREEN_TITLE)
	await _settle(2)
	await _dispose_game(game)

	_expect(_write_raw_text("[]"), "손상 구조 저장 파일 작성")
	game = await _new_game()
	continue_button = _find_button_by_text(game.ui_layer, "이어하기")
	_expect(game.campaign_save_status == CampaignSaveStoreScript.STATUS_CORRUPT, "깨진 JSON을 손상 저장으로 판정")
	_expect(continue_button != null and continue_button.disabled, "손상 저장이면 이어하기 비활성화")
	_expect(_tree_has_text(game.ui_layer, "손상"), "손상 저장 안내 문구 노출")
	var new_game_button := _find_button_by_text(game.ui_layer, "새 게임")
	_expect(new_game_button != null, "손상 저장 상태에서도 새 게임 제공")
	if new_game_button != null:
		new_game_button.pressed.emit()
		await _settle(3)
	_expect(game.current_screen == Constants.SCREEN_NAME_ENTRY, "제목의 새 게임은 이름 입력으로 이동")
	_expect(str(CampaignSaveStoreScript.inspect(TEST_SAVE_PATH).get("status", "")) == CampaignSaveStoreScript.STATUS_MISSING, "새 게임이 손상 저장 파일을 삭제")
	await _dispose_game(game)

	var unsupported_envelope := {
		"version": 999,
		"campaign_final_day": 30,
		"summary": {},
		"payload": {}
	}
	_expect(_write_raw_text(JSON.stringify(unsupported_envelope)), "미지원 버전 저장 파일 작성")
	game = await _new_game()
	continue_button = _find_button_by_text(game.ui_layer, "이어하기")
	_expect(game.campaign_save_status == CampaignSaveStoreScript.STATUS_UNSUPPORTED, "다른 저장 버전을 미지원 상태로 판정")
	_expect(continue_button != null and continue_button.disabled, "미지원 저장이면 이어하기 비활성화")
	_expect(_tree_has_text(game.ui_layer, "읽을 수 없는"), "미지원 저장 안내 문구 노출")
	await _dispose_game(game)
	CampaignSaveStoreScript.delete(TEST_SAVE_PATH)

	var restore_rejected_payload := {
		"screen": Constants.SCREEN_COMBAT,
		"checkpoint": Constants.SCREEN_COMBAT,
		"game_state": {"day": 1},
		"world": {"castle_art_stage": STAGE_ONE_ID},
		"raid": {},
		"campaign": {},
		"result": {},
		"onboarding": {}
	}
	var restore_rejected_summary := {"day": 1, "player_name": "복원 거부 검증"}
	var write_result: Dictionary = CampaignSaveStoreScript.write(restore_rejected_payload, restore_rejected_summary, TEST_SAVE_PATH)
	_expect(not bool(write_result.get("ok", false)), "안전하지 않은 전투 화면 저장 작성을 원천 거부")
	_expect(str(write_result.get("error", "")).find("안전하지 않은 화면") >= 0, "복원 불가능 저장의 거부 원인 제공")
	_expect(str(CampaignSaveStoreScript.inspect(TEST_SAVE_PATH).get("status", "")) == CampaignSaveStoreScript.STATUS_MISSING, "거부된 저장은 디스크에 남기지 않음")


func _check_cycle_doctrine_round_trip() -> void:
	print("[CampaignSaveLoad] 2회차 교리 선택 전 저장 복원")
	CampaignSaveStoreScript.delete(TEST_SAVE_PATH)
	GameState.reset()
	var game := await _new_game()
	game._debug_skip_onboarding()
	game.campaign_cycle_index = 2
	game.campaign_profile["completed_cycles"] = 1
	game.campaign_profile["active_doctrine_id"] = ""
	game.selected_contract_ids.assign(["spore_healer", "stone_sentinel"])
	game._add_contract_monster_to_roster("spore_healer")
	game._add_contract_monster_to_roster("stone_sentinel")
	game.deployed_instance_ids.assign(["mon_core_pudding", "mon_contract_mori", "mon_contract_dolkong"])
	game._sync_contract_reserves()
	game.inherited_legacy_monster = {
		"instance_id": "mon_core_pudding",
		"species_id": "slime",
		"display_name": "푸딩",
		"inherited_memory_id": "legacy_mon_core_pudding_cycle_1",
		"source_cycle": 1
	}
	GameState.player_name = "교리 저장 검증"
	GameState.day = 4
	GameState.onboarding_complete = true
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game._set_screen(Constants.SCREEN_CYCLE_DOCTRINE)
	await _settle(5)
	var inspection := CampaignSaveStoreScript.inspect(TEST_SAVE_PATH)
	_expect(str(inspection.get("status", "")) == CampaignSaveStoreScript.STATUS_VALID, "교리 미선택 2회차 화면 자동 저장 허용")
	_expect(str(inspection.get("payload", {}).get("screen", "")) == Constants.SCREEN_CYCLE_DOCTRINE, "교리 화면 체크포인트 기록")
	var valid_envelope := _read_json_dictionary(TEST_SAVE_PATH)
	await _dispose_game(game)

	game = await _new_game()
	game._continue_campaign_save()
	await _settle(5)
	_expect(game.current_screen == Constants.SCREEN_CYCLE_DOCTRINE and game.campaign_cycle_index == 2, "교리 미선택 2회차 화면 복원")
	_expect(str(game.inherited_legacy_monster.get("species_id", "")) == "slime", "교리 선택 전 계승 몬스터 복원")
	await _dispose_game(game)

	var mutated := valid_envelope.duplicate(true)
	mutated["payload"]["legacy_expansion"] = "broken"
	_expect(_write_raw_text_at(MUTATION_SAVE_PATH, JSON.stringify(mutated)), "잘못된 회차 계승 정보 저장 작성")
	_expect(str(CampaignSaveStoreScript.inspect(MUTATION_SAVE_PATH).get("status", "")) == CampaignSaveStoreScript.STATUS_CORRUPT, "사전 검증에서 잘못된 회차 계승 정보 차단")
	CampaignSaveStoreScript.delete(MUTATION_SAVE_PATH)
	mutated = valid_envelope.duplicate(true)
	mutated["payload"]["legacy_expansion"]["run_metrics"]["style.family"] = []
	_expect(_write_raw_text_at(MUTATION_SAVE_PATH, JSON.stringify(mutated)), "잘못된 회차 지표 저장 작성")
	_expect(str(CampaignSaveStoreScript.inspect(MUTATION_SAVE_PATH).get("status", "")) == CampaignSaveStoreScript.STATUS_CORRUPT, "사전 검증에서 잘못된 회차 지표 차단")
	CampaignSaveStoreScript.delete(TEST_SAVE_PATH)
	CampaignSaveStoreScript.delete(MUTATION_SAVE_PATH)


func _check_day_28_round_trip() -> void:
	print("[CampaignSaveLoad] DAY 28 Stage 04 왕복 복원")
	CampaignSaveStoreScript.delete(TEST_SAVE_PATH)
	GameState.reset()

	var game := await _new_game()
	game._debug_skip_onboarding()
	_prepare_stage_four(game)
	GameState.day = 28
	GameState.player_name = "저장검증 마왕"
	GameState.gold = 4321
	GameState.mana = 876
	GameState.food = 45
	GameState.infamy = 987
	GameState.gold_income = 57
	GameState.mana_income = 31
	GameState.demon_lord_hp = 2317
	GameState.victory = false
	GameState.defeat = false
	GameState.onboarding_complete = true

	var barracks: Dictionary = game.rooms.get("barracks", {})
	barracks["facility_level"] = 4
	barracks["hp"] = int(barracks.get("hp", 0)) + 17
	var expected_barracks_hp := int(barracks.get("hp", 0))
	var expected_barracks_capacity := int(barracks.get("max_monsters", 0))

	var slime: Dictionary = game.monster_roster.get("slime", {})
	slime["level"] = 7
	slime["exp"] = 23
	slime["room"] = "barracks"
	slime["specialization_id"] = "slime_gate_keeper"
	slime["promotion_id"] = "slime_gate_bulwark"
	slime["promotion_stage"] = 1
	slime["role_tag"] = "blocker"
	game.selected_room = "barracks"
	game.selected_monster_id = "slime"
	game.global_directive = Constants.DIRECTIVE_SURVIVAL
	game.room_directives["barracks"] = Constants.ROOM_DIRECTIVE_ENTRY_BLOCK
	game.completed_raids.erase(FINAL_RAID_ID)
	game.completed_raids.erase("d28_engineer_supply_disruption")
	game.next_defense_modifiers.clear()
	game._enter_campaign_management_day(false)
	await _settle(4)

	var inspection: Dictionary = CampaignSaveStoreScript.inspect(TEST_SAVE_PATH)
	_expect(str(inspection.get("status", "")) == CampaignSaveStoreScript.STATUS_VALID, "DAY 28 관리 화면 자동 저장 생성")
	var envelope := _read_json_dictionary(TEST_SAVE_PATH)
	_expect(int(envelope.get("version", 0)) == 1, "저장 봉투 버전 1 기록")
	_expect(int(envelope.get("campaign_final_day", 0)) == 30, "저장 봉투에 정규 최종일 DAY 30 기록")
	_expect(str(envelope.get("payload", {}).get("world", {}).get("castle_art_stage", "")) == STAGE_FOUR_ID, "저장 파일에 Stage 04 기록")
	await _check_day_28_mutation_guards(envelope)
	var backup_path := "%s.bak" % TEST_SAVE_PATH
	var temp_path := "%s.tmp" % TEST_SAVE_PATH
	var rename_error := DirAccess.rename_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH), ProjectSettings.globalize_path(backup_path))
	_expect(rename_error == OK, "중단된 저장의 백업 파일 상황 구성")
	inspection = CampaignSaveStoreScript.inspect(TEST_SAVE_PATH)
	_expect(str(inspection.get("status", "")) == CampaignSaveStoreScript.STATUS_VALID and FileAccess.file_exists(TEST_SAVE_PATH), "본 파일 유실 시 유효한 .bak 자동 복구")
	_expect(not FileAccess.file_exists(backup_path), ".bak 복구 뒤 임시 잔여물 정리")
	rename_error = DirAccess.rename_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH), ProjectSettings.globalize_path(temp_path))
	_expect(rename_error == OK, "중단된 저장의 임시 파일 상황 구성")
	inspection = CampaignSaveStoreScript.inspect(TEST_SAVE_PATH)
	_expect(str(inspection.get("status", "")) == CampaignSaveStoreScript.STATUS_VALID and FileAccess.file_exists(TEST_SAVE_PATH), "본 파일 유실 시 유효한 .tmp 자동 복구")
	_expect(not FileAccess.file_exists(temp_path), ".tmp 복구 뒤 임시 잔여물 정리")
	await _dispose_game(game)

	game = await _new_game()
	var continue_button := _find_button_by_text(game.ui_layer, "이어하기")
	_expect(game.campaign_save_status == CampaignSaveStoreScript.STATUS_VALID, "DAY 28 저장을 제목에서 유효 판정")
	_expect(continue_button != null and not continue_button.disabled, "DAY 28 저장이면 이어하기 활성화")
	_expect(_tree_has_text(game.ui_layer, "DAY 28 / 30"), "저장 요약에 DAY 28 / 30 노출")
	_expect(_tree_has_text(game.ui_layer, "마왕성 4/4 대마왕성"), "저장 요약에 대마왕성 4단계 이름 노출")
	_check_title_layout(game, "DAY 28 / 30")
	var new_game_button := _find_button_by_text(game.ui_layer, "새 게임")
	if new_game_button != null:
		new_game_button.pressed.emit()
		await _settle(3)
	_expect(game.current_screen == Constants.SCREEN_TITLE and _tree_has_text(game.ui_layer, "저장 기록을 삭제할까요?"), "유효 저장의 새 게임은 삭제 확인 표시")
	_expect(str(CampaignSaveStoreScript.inspect(TEST_SAVE_PATH).get("status", "")) == CampaignSaveStoreScript.STATUS_VALID, "새 게임 확인 전에는 기존 저장 보존")
	var cancel_reset_button := _find_button_by_text(game.ui_layer, "취소")
	if cancel_reset_button != null:
		cancel_reset_button.pressed.emit()
		await _settle(3)
	continue_button = _find_button_by_text(game.ui_layer, "이어하기")
	_expect(continue_button != null and not continue_button.disabled and str(CampaignSaveStoreScript.inspect(TEST_SAVE_PATH).get("status", "")) == CampaignSaveStoreScript.STATUS_VALID, "삭제 취소 뒤 이어하기와 저장 유지")
	if continue_button != null:
		continue_button.pressed.emit()
		await _settle(4)
	_assert_day_28_persistent_state(game, expected_barracks_hp, expected_barracks_capacity, "1차 복원")

	# 복원된 상태를 다시 저장한 뒤 두 번째로 불러와야 시설 단계 보너스의 누적 여부를 잡을 수 있다.
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle(4)
	await _dispose_game(game)

	game = await _new_game()
	continue_button = _find_button_by_text(game.ui_layer, "이어하기")
	if continue_button != null:
		continue_button.pressed.emit()
		await _settle(4)
	_assert_day_28_persistent_state(game, expected_barracks_hp, expected_barracks_capacity, "2차 복원")
	_expect(game._campaign_raid_choice_pending(), "DAY 28 마지막 원정 선택 대기 상태 복원")
	game._start_combat()
	await _settle(3)
	_expect(game.current_screen == Constants.SCREEN_RAID, "DAY 28 선택 없이 방어 시작 시 마지막 원정 화면으로 이동")
	await _dispose_game(game)


func _check_day_30_retry_postgame_and_new_game() -> void:
	print("[CampaignSaveLoad] DAY 30 재도전·엔딩·후일담")
	CampaignSaveStoreScript.delete(TEST_SAVE_PATH)
	GameState.reset()

	var game := await _new_game()
	game._debug_skip_onboarding()
	_prepare_stage_four(game)
	GameState.day = 30
	GameState.player_name = "최종장 저장검증"
	GameState.gold = 7654
	GameState.mana = 543
	GameState.food = 32
	GameState.infamy = 1400
	GameState.demon_lord_hp = GameState.demon_lord_max_hp
	GameState.victory = false
	GameState.defeat = false
	game.campaign_final_preparation_confirmed = true
	game.campaign_completed = false
	game.campaign_final_battle_outcome = ""
	game.campaign_finale_defeat_seen = false
	game.campaign_postgame_active = false

	var raid_choice: Dictionary = DataRegistry.raid_mission(FINAL_RAID_ID)
	var final_modifier: Dictionary = raid_choice.get("next_defense_modifier", {}).duplicate(true)
	var final_modifier_id := str(final_modifier.get("id", FINAL_RAID_ID))
	game.completed_raids[FINAL_RAID_ID] = true
	game.next_defense_modifiers[final_modifier_id] = final_modifier
	game._enter_campaign_management_day(false)
	await _settle(4)
	_expect(str(CampaignSaveStoreScript.inspect(TEST_SAVE_PATH).get("status", "")) == CampaignSaveStoreScript.STATUS_VALID, "DAY 30 최종전 직전 자동 저장")
	_check_day_30_mutation_guards(_read_json_dictionary(TEST_SAVE_PATH))

	game._start_combat()
	await _settle(2)
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "DAY 30 최종 공성전 시작")
	GameState.damage_throne(GameState.demon_lord_max_hp)
	game._check_combat_end()
	await _settle(4)
	_expect(game.current_screen == Constants.SCREEN_RESULT and not bool(game.result_summary.get("win", true)), "DAY 30 왕좌 파괴를 패배 결산으로 저장")
	_expect(game.campaign_final_battle_outcome == "defeat" and game.campaign_finale_defeat_seen, "DAY 30 패배 결과와 재도전 서사 플래그 기록")
	_expect(not game.campaign_completed, "DAY 30 패배는 캠페인 완료로 처리하지 않음")
	var defeat_mutation := _read_json_dictionary(TEST_SAVE_PATH)
	defeat_mutation["payload"]["result"]["summary"]["win"] = true
	_expect(_write_raw_text_at(MUTATION_SAVE_PATH, JSON.stringify(defeat_mutation)), "변조 검증용 DAY 30 패배·승리 결산 불일치 저장 작성")
	_expect(str(CampaignSaveStoreScript.inspect(MUTATION_SAVE_PATH).get("status", "")) == CampaignSaveStoreScript.STATUS_CORRUPT, "DAY 30 최종전 결과와 결산 승패 불일치 차단")
	CampaignSaveStoreScript.delete(MUTATION_SAVE_PATH)

	game._continue_from_result()
	await _settle(4)
	_expect(GameState.day == 30 and game.current_screen == Constants.SCREEN_MANAGEMENT, "패배 뒤 DAY 31이 아닌 DAY 30 관리 화면으로 복귀")
	_expect(not GameState.defeat and not GameState.victory, "재도전에서 승패 상태 초기화")
	_expect(GameState.demon_lord_hp == GameState.demon_lord_max_hp, "재도전에서 왕좌 체력 완전 복구")
	_expect(game.next_defense_modifiers.has(final_modifier_id), "재도전에서 DAY 28 원정 보정 복원")
	var gold_after_retry := GameState.gold
	await _dispose_game(game)

	game = await _new_game()
	var continue_button := _find_button_by_text(game.ui_layer, "이어하기")
	_expect(continue_button != null and not continue_button.disabled, "DAY 30 재도전 저장의 이어하기 활성화")
	_expect(_tree_has_text(game.ui_layer, "DAY 30 / 30"), "제목 저장 요약에 최종일 DAY 30 / 30 노출")
	if continue_button != null:
		continue_button.pressed.emit()
		await _settle(4)
	_expect(GameState.day == 30 and game.current_screen == Constants.SCREEN_MANAGEMENT, "DAY 30 재도전 관리 상태 복원")
	_expect(game.campaign_final_battle_outcome == "defeat" and game.campaign_finale_defeat_seen and not game.campaign_completed, "재도전 결과 플래그 왕복 보존")
	_expect(GameState.gold == gold_after_retry, "재도전 로드에서 자원 중복 지급 없음")
	_expect(GameState.demon_lord_hp == 2500 and GameState.demon_lord_max_hp == 2500, "재도전 로드에서 Stage 04 왕좌 완전 체력 보존")
	_expect(game.next_defense_modifiers.has(final_modifier_id), "재도전 로드에서 원정 보정 보존")

	game._start_combat()
	await _settle(2)
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "불러온 DAY 30 재도전 시작")
	_expect(game.wave_manager.total_to_spawn == 8, "안전한 공성로 정찰로 최종 웨이브 8명")
	_expect(_scheduled_enemy_count(game, "investigator") == 0, "DAY 30 조사관 1명 제거 보정 유지")
	var scheduled_leon := _scheduled_enemy_entry(game, "official_hero_leon")
	_expect(float(scheduled_leon.get("time", 0.0)) >= 59.0, "DAY 30 레온 도착이 5초 지연된 상태 유지")
	game._finish_combat(true, "DAY 30 저장·이어하기 최종 공성전 승리 검증")
	await _settle(4)
	_expect(game.current_screen == Constants.SCREEN_RESULT and bool(game.result_summary.get("win", false)), "DAY 30 승리 결산 자동 저장")
	_expect(game.campaign_completed and game.campaign_final_battle_outcome == "victory", "DAY 30 승리로 정규 캠페인 완료")
	var gold_after_victory := GameState.gold

	game._continue_from_result()
	await _settle(4)
	_expect(GameState.day == 30 and game.current_screen == Constants.SCREEN_ENDING, "승리 뒤 DAY 31 없이 최종 엔딩 표시")
	game._continue_campaign_postgame()
	await _settle(4)
	_expect(game.campaign_postgame_active and GameState.day == 30 and game.current_screen == Constants.SCREEN_MANAGEMENT, "후일담은 DAY 30 Stage 04 관리 상태로 진입")
	_assert_stage_four_state(game, "후일담 진입")
	_expect(GameState.gold == gold_after_victory, "엔딩·후일담 전환에서 자원 중복 지급 없음")
	var postgame_inspection: Dictionary = CampaignSaveStoreScript.inspect(TEST_SAVE_PATH)
	_expect(str(postgame_inspection.get("summary", {}).get("checkpoint_label", "")) == "후일담 관리", "후일담 관리 체크포인트 요약 저장")
	await _dispose_game(game)

	game = await _new_game()
	continue_button = _find_button_by_text(game.ui_layer, "이어하기")
	_expect(_tree_has_text(game.ui_layer, "후일담 관리"), "제목 화면에 후일담 체크포인트 노출")
	if continue_button != null:
		continue_button.pressed.emit()
		await _settle(4)
	_expect(game.campaign_postgame_active and game.campaign_completed and game.campaign_final_battle_outcome == "victory", "후일담·승리 완료 상태 복원")
	_expect(GameState.day == 30 and game.current_screen == Constants.SCREEN_MANAGEMENT, "후일담 로드도 DAY 30 유지")
	_expect(GameState.gold == gold_after_victory, "후일담 로드에서 승리 보상 중복 지급 없음")
	_assert_stage_four_state(game, "후일담 복원")
	game._advance_day_from_management()
	await _settle(4)
	_expect(GameState.day == 30 and game.current_screen == Constants.SCREEN_ENDING, "후일담에서 날짜 진행 시 DAY 31 대신 엔딩 재표시")

	# 같은 인스턴스에서 엔딩 새 게임을 눌러야 이전 캠페인 상태 오염을 검출할 수 있다.
	game.quarter_layout_id = "campaign_save_smoke_stale_layout"
	game.result_summary = {"stale": true}
	game.rewards_pending = {"gold": 999}
	game.last_growth_summary = [{"monster_id": "slime", "stale": true}]
	game.result_growth_reviewed = false
	game.result_growth_choice_monster_id = "slime"
	game.result_growth_choice_applied = true
	game.last_growth_choice_summary = {"stale": true}
	game.last_security_grade = "S"
	game._campaign_new_game_from_ending()
	await _settle(3)
	_expect(game.current_screen == Constants.SCREEN_TITLE, "엔딩의 새 게임은 초기화된 제목 화면으로 이동")
	_expect(GameState.day == 1 and GameState.max_day == 3, "새 게임은 DAY 1과 튜토리얼 DAY 3 기준으로 초기화")
	_expect(GameState.gold == 1245 and GameState.mana == 320 and GameState.food == 18 and GameState.infamy == 620, "새 게임 기본 자원 초기화")
	_expect(GameState.demon_lord_hp == 1500 and GameState.demon_lord_max_hp == 1500, "새 게임 Stage 01 왕좌 체력 초기화")
	_expect(GameState.player_name == "" and not GameState.onboarding_complete, "새 게임 이름과 온보딩 상태 초기화")
	_expect(game.castle_art_stage == STAGE_ONE_ID and game.castle_evolution_history == [STAGE_ONE_ID], "새 게임 마왕성 Stage 01 초기화")
	_expect(not game.rooms.has("elite_garrison_01") and not game.rooms.has("slot_03"), "새 게임에서 Stage 04 추가 구역 제거")
	_expect(game.completed_raids.is_empty() and game.next_defense_modifiers.is_empty(), "새 게임 원정 완료와 예약 보정 초기화")
	_expect(not game.campaign_completed and not game.campaign_final_preparation_confirmed and game.campaign_final_battle_outcome == "", "새 게임 최종장 플래그 초기화")
	_expect(int(game.monster_roster.get("slime", {}).get("level", 0)) == 1 and int(game.monster_roster.get("slime", {}).get("exp", -1)) == 0, "새 게임 몬스터 성장 초기화")
	_expect(game.quarter_layout_id == str(DataRegistry.quarter_default_layout_id), "새 게임 던전 배치 ID 초기화")
	_expect(game.result_summary.is_empty() and game.rewards_pending.is_empty() and game.last_growth_summary.is_empty(), "새 게임 결산·보상·성장 임시 상태 초기화")
	_expect(game.result_growth_choice_monster_id == "" and not game.result_growth_choice_applied and game.last_growth_choice_summary.is_empty(), "새 게임 성장 선택 임시 상태 초기화")
	_expect(game.last_security_grade == "", "새 게임 보안 평가 상태 초기화")
	_expect(str(CampaignSaveStoreScript.inspect(TEST_SAVE_PATH).get("status", "")) == CampaignSaveStoreScript.STATUS_MISSING, "엔딩 새 게임이 디스크 저장을 삭제")

	var title_new_game_button := _find_button_by_text(game.ui_layer, "새 게임")
	if title_new_game_button != null:
		title_new_game_button.pressed.emit()
		await _settle(3)
	_expect(game.current_screen == Constants.SCREEN_NAME_ENTRY, "초기화된 제목에서 새 게임을 누르면 이름 입력 표시")
	await _dispose_game(game)

	game = await _new_game()
	continue_button = _find_button_by_text(game.ui_layer, "이어하기")
	_expect(game.campaign_save_status == CampaignSaveStoreScript.STATUS_MISSING, "새 게임 삭제 뒤 다음 실행에서도 저장 없음")
	_expect(continue_button != null and continue_button.disabled, "삭제 뒤 이어하기 비활성화 유지")
	await _dispose_game(game)


func _prepare_stage_four(game: Node) -> void:
	game.castle_art_stage = STAGE_FOUR_ID
	game.castle_evolution_history.clear()
	game.castle_evolution_history.append_array([
		"stage_01_cave",
		"stage_02_castle",
		"stage_03_keep",
		"stage_04_citadel"
	])
	game.campaign_chapter_one_clear = true
	game.campaign_stage_two_prepared = true
	game.campaign_chapter_two_started = true
	game.campaign_stage_two_upgrade_funded = true
	game.campaign_stage_two_unlock_ready = true
	game.campaign_chapter_three_clear = true
	game.campaign_chapter_four_clear = true
	game.campaign_final_chapter_unlocked = true
	game.campaign_final_upgrade_ready = true
	game.first_promotion_completed = true
	game.facility_upgrade_unlocked = true
	game._sync_castle_stage_content()
	game._setup_dungeon_graph()
	game._init_room_directives()
	if game.quarter_renderer != null and game.quarter_renderer.has_method("refresh_layout"):
		game.quarter_renderer.refresh_layout()


func _check_day_28_mutation_guards(valid_envelope: Dictionary) -> void:
	var mutated := valid_envelope.duplicate(true)
	mutated["payload"]["result"]["last_growth_summary"] = [123]
	_expect(_write_raw_text_at(MUTATION_SAVE_PATH, JSON.stringify(mutated)), "변조 검증용 성장 결과 저장 작성")
	_expect(str(CampaignSaveStoreScript.inspect(MUTATION_SAVE_PATH).get("status", "")) == CampaignSaveStoreScript.STATUS_CORRUPT, "성장 결과 배열의 비사전 항목 차단")
	CampaignSaveStoreScript.delete(MUTATION_SAVE_PATH)

	mutated = valid_envelope.duplicate(true)
	mutated["payload"]["raid"]["next_defense_modifiers"] = {"bad_modifier": 123}
	_expect(_write_raw_text_at(MUTATION_SAVE_PATH, JSON.stringify(mutated)), "변조 검증용 중첩 방어 보정 저장 작성")
	_expect(str(CampaignSaveStoreScript.inspect(MUTATION_SAVE_PATH).get("status", "")) == CampaignSaveStoreScript.STATUS_CORRUPT, "중첩 방어 보정의 비사전 항목 차단")
	CampaignSaveStoreScript.delete(MUTATION_SAVE_PATH)

	mutated = valid_envelope.duplicate(true)
	mutated["payload"]["result"]["last_growth_summary"] = [{"activity_breakdown": {"attack": {}}}]
	_expect(_write_raw_text_at(MUTATION_SAVE_PATH, JSON.stringify(mutated)), "변조 검증용 몬스터 활약 내역 저장 작성")
	_expect(str(CampaignSaveStoreScript.inspect(MUTATION_SAVE_PATH).get("status", "")) == CampaignSaveStoreScript.STATUS_CORRUPT, "몬스터 활약 내역의 비수치 값 차단")
	CampaignSaveStoreScript.delete(MUTATION_SAVE_PATH)

	mutated = valid_envelope.duplicate(true)
	mutated["payload"]["result"]["growth_choice_applied"] = true
	mutated["payload"]["result"]["growth_choice_monster_id"] = "slime"
	mutated["payload"]["result"]["last_growth_choice_summary"] = {"bonus_exp": {}}
	_expect(_write_raw_text_at(MUTATION_SAVE_PATH, JSON.stringify(mutated)), "변조 검증용 집중 성장 요약 저장 작성")
	_expect(str(CampaignSaveStoreScript.inspect(MUTATION_SAVE_PATH).get("status", "")) == CampaignSaveStoreScript.STATUS_CORRUPT, "집중 성장 요약의 누락·비수치 값 차단")
	CampaignSaveStoreScript.delete(MUTATION_SAVE_PATH)

	for mutation_case in [
		{"key": "tile_size", "value": "bad", "label": "타일 크기"},
		{"key": "socket_states", "value": "bad", "label": "소켓 상태"}
	]:
		mutated = valid_envelope.duplicate(true)
		mutated["payload"]["world"]["quarter_layout"][mutation_case["key"]] = mutation_case["value"]
		_expect(_write_raw_text_at(MUTATION_SAVE_PATH, JSON.stringify(mutated)), "변조 검증용 맵 %s 저장 작성" % mutation_case["label"])
		_expect(str(CampaignSaveStoreScript.inspect(MUTATION_SAVE_PATH).get("status", "")) == CampaignSaveStoreScript.STATUS_CORRUPT, "맵 %s 자료형 변조 차단" % mutation_case["label"])
		CampaignSaveStoreScript.delete(MUTATION_SAVE_PATH)

	mutated = valid_envelope.duplicate(true)
	mutated["payload"]["world"]["quarter_layout"]["room_grid"]["grid_size"] = "bad"
	_expect(_write_raw_text_at(MUTATION_SAVE_PATH, JSON.stringify(mutated)), "변조 검증용 맵 격자 크기 저장 작성")
	_expect(str(CampaignSaveStoreScript.inspect(MUTATION_SAVE_PATH).get("status", "")) == CampaignSaveStoreScript.STATUS_CORRUPT, "맵 격자 크기 자료형 변조 차단")
	CampaignSaveStoreScript.delete(MUTATION_SAVE_PATH)

	mutated = valid_envelope.duplicate(true)
	mutated["payload"]["game_state"]["onboarding_complete"] = false
	_expect(_write_raw_text_at(MUTATION_SAVE_PATH, JSON.stringify(mutated)), "변조 검증용 정규 캠페인 온보딩 미완료 저장 작성")
	_expect(str(CampaignSaveStoreScript.inspect(MUTATION_SAVE_PATH).get("status", "")) == CampaignSaveStoreScript.STATUS_CORRUPT, "DAY 28 온보딩 미완료 상태 차단")
	CampaignSaveStoreScript.delete(MUTATION_SAVE_PATH)

	mutated = valid_envelope.duplicate(true)
	mutated["payload"]["onboarding"]["tutorial_gate_enabled"] = true
	_expect(_write_raw_text_at(MUTATION_SAVE_PATH, JSON.stringify(mutated)), "변조 검증용 정규 캠페인 튜토리얼 제한 저장 작성")
	_expect(str(CampaignSaveStoreScript.inspect(MUTATION_SAVE_PATH).get("status", "")) == CampaignSaveStoreScript.STATUS_CORRUPT, "DAY 28 튜토리얼 제한 잔존 상태 차단")
	CampaignSaveStoreScript.delete(MUTATION_SAVE_PATH)

	mutated = valid_envelope.duplicate(true)
	mutated["payload"]["onboarding"]["tutorial_manager"]["current_index"] = 999
	_expect(_write_raw_text_at(MUTATION_SAVE_PATH, JSON.stringify(mutated)), "변조 검증용 범위 밖 튜토리얼 위치 저장 작성")
	_expect(str(CampaignSaveStoreScript.inspect(MUTATION_SAVE_PATH).get("status", "")) == CampaignSaveStoreScript.STATUS_VALID, "저장소가 모르는 튜토리얼 단계 수는 복원 단계에서 확인")
	var mutation_game := await _new_game(MUTATION_SAVE_PATH)
	var continue_button := _find_button_by_text(mutation_game.ui_layer, "이어하기")
	_expect(continue_button != null and not continue_button.disabled, "범위 밖 튜토리얼 위치 저장의 최초 이어하기 시도 허용")
	if continue_button != null:
		continue_button.pressed.emit()
		await _settle(4)
	_expect(mutation_game.current_screen == Constants.SCREEN_MANAGEMENT and mutation_game.campaign_save_status == CampaignSaveStoreScript.STATUS_VALID, "삭제된 구형 튜토리얼 위치를 정상 관리 상태로 복원")
	_expect(mutation_game.tutorial_manager.current_index == mutation_game.tutorial_manager.steps.size() and not mutation_game.tutorial_manager.active, "범위 밖 구형 튜토리얼 위치를 현재 단계 끝으로 보정")
	_expect(not FileAccess.file_exists("%s.invalid" % MUTATION_SAVE_PATH), "정상 보정 저장에 .invalid 표식을 만들지 않음")
	await _dispose_game(mutation_game)

	mutation_game = await _new_game(MUTATION_SAVE_PATH)
	continue_button = _find_button_by_text(mutation_game.ui_layer, "이어하기")
	_expect(mutation_game.campaign_save_status == CampaignSaveStoreScript.STATUS_VALID and continue_button != null and not continue_button.disabled, "보정된 구형 튜토리얼 저장을 다음 실행에서도 이어가기 허용")
	await _dispose_game(mutation_game)
	CampaignSaveStoreScript.delete(MUTATION_SAVE_PATH)

	mutated = valid_envelope.duplicate(true)
	mutated["payload"]["onboarding"]["tutorial_manager"]["active"] = true
	_expect(_write_raw_text_at(MUTATION_SAVE_PATH, JSON.stringify(mutated)), "변조 검증용 정규 캠페인 튜토리얼 활성 저장 작성")
	_expect(str(CampaignSaveStoreScript.inspect(MUTATION_SAVE_PATH).get("status", "")) == CampaignSaveStoreScript.STATUS_CORRUPT, "DAY 28 활성 튜토리얼 상태 차단")
	CampaignSaveStoreScript.delete(MUTATION_SAVE_PATH)

	_expect(_write_raw_text_at("%s.tmp" % MUTATION_SAVE_PATH, JSON.stringify(valid_envelope)), "복원 실패 표식과 유효 임시 저장 동시 상황 구성")
	_expect(_write_raw_text_at("%s.invalid" % MUTATION_SAVE_PATH, "이전 복원 실패"), "본 파일 없는 복원 실패 표식 작성")
	var invalid_first := CampaignSaveStoreScript.inspect(MUTATION_SAVE_PATH)
	var invalid_second := CampaignSaveStoreScript.inspect(MUTATION_SAVE_PATH)
	_expect(str(invalid_first.get("status", "")) == CampaignSaveStoreScript.STATUS_CORRUPT and str(invalid_second.get("status", "")) == CampaignSaveStoreScript.STATUS_CORRUPT, "복원 실패 표식이 유효 임시 저장보다 항상 우선")
	_expect(not FileAccess.file_exists(MUTATION_SAVE_PATH) and FileAccess.file_exists("%s.tmp" % MUTATION_SAVE_PATH), "복원 실패 표식 상태에서 임시 저장을 본 파일로 승격하지 않음")
	CampaignSaveStoreScript.delete(MUTATION_SAVE_PATH)

	var unsupported_candidate := valid_envelope.duplicate(true)
	unsupported_candidate["version"] = 999
	_expect(_write_raw_text_at("%s.tmp" % MUTATION_SAVE_PATH, JSON.stringify(unsupported_candidate)), "본 파일 없는 미지원 임시 저장 상황 구성")
	var unsupported_first := CampaignSaveStoreScript.inspect(MUTATION_SAVE_PATH)
	var unsupported_second := CampaignSaveStoreScript.inspect(MUTATION_SAVE_PATH)
	_expect(str(unsupported_first.get("status", "")) == CampaignSaveStoreScript.STATUS_UNSUPPORTED and str(unsupported_second.get("status", "")) == CampaignSaveStoreScript.STATUS_UNSUPPORTED, "미지원 임시 저장 상태를 두 번 검사해도 그대로 유지")
	_expect(not FileAccess.file_exists(MUTATION_SAVE_PATH) and FileAccess.file_exists("%s.tmp" % MUTATION_SAVE_PATH), "미지원 임시 저장을 손상 처리하거나 본 파일로 승격하지 않음")
	CampaignSaveStoreScript.delete(MUTATION_SAVE_PATH)


func _check_day_30_mutation_guards(valid_envelope: Dictionary) -> void:
	var mutated := valid_envelope.duplicate(true)
	mutated["payload"]["campaign"]["final_preparation_confirmed"] = false
	_expect(_write_raw_text_at(MUTATION_SAVE_PATH, JSON.stringify(mutated)), "변조 검증용 DAY 30 준비 누락 저장 작성")
	_expect(str(CampaignSaveStoreScript.inspect(MUTATION_SAVE_PATH).get("status", "")) == CampaignSaveStoreScript.STATUS_CORRUPT, "DAY 30 최종 준비=false 저장 차단")
	CampaignSaveStoreScript.delete(MUTATION_SAVE_PATH)

	mutated = valid_envelope.duplicate(true)
	mutated["payload"]["campaign"]["postgame_active"] = true
	mutated["summary"]["campaign_postgame_active"] = true
	_expect(_write_raw_text_at(MUTATION_SAVE_PATH, JSON.stringify(mutated)), "변조 검증용 미완료 후일담 저장 작성")
	_expect(str(CampaignSaveStoreScript.inspect(MUTATION_SAVE_PATH).get("status", "")) == CampaignSaveStoreScript.STATUS_CORRUPT, "캠페인 미완료 후일담 상태 차단")
	CampaignSaveStoreScript.delete(MUTATION_SAVE_PATH)


func _assert_day_28_persistent_state(game: Node, expected_hp: int, expected_capacity: int, prefix: String) -> void:
	_expect(GameState.day == 28 and game.current_screen == Constants.SCREEN_MANAGEMENT, "%s: DAY 28 관리 체크포인트" % prefix)
	_expect(GameState.player_name == "저장검증 마왕", "%s: 마왕명 보존" % prefix)
	_expect(GameState.gold == 4321 and GameState.mana == 876 and GameState.food == 45 and GameState.infamy == 987, "%s: 네 자원 보존" % prefix)
	_expect(GameState.gold_income == 57 and GameState.mana_income == 31, "%s: 자원 수입 보존" % prefix)
	_expect(GameState.demon_lord_hp == 2317 and GameState.demon_lord_max_hp == 2500, "%s: 왕좌 현재/최대 체력 보존" % prefix)
	_assert_stage_four_state(game, prefix)
	var barracks: Dictionary = game.rooms.get("barracks", {})
	_expect(int(barracks.get("facility_level", 0)) == 4, "%s: 시설 강화 Lv.4 보존" % prefix)
	_expect(int(barracks.get("hp", 0)) == expected_hp, "%s: 시설 HP Stage 보너스 중복 가산 없음" % prefix)
	_expect(int(barracks.get("max_monsters", 0)) == expected_capacity, "%s: 시설 정원 Stage 보너스 중복 가산 없음" % prefix)
	_expect(int(barracks.get("castle_stage_hp_bonus", 0)) == 320 and int(barracks.get("castle_stage_capacity_bonus", 0)) == 3, "%s: 시설 단계 보너스 추적값 보존" % prefix)
	var slime: Dictionary = game.monster_roster.get("slime", {})
	_expect(int(slime.get("level", 0)) == 7 and int(slime.get("exp", 0)) == 23 and str(slime.get("room", "")) == "barracks", "%s: 몬스터 성장·배치 보존" % prefix)
	_expect(str(slime.get("specialization_id", "")) == "slime_gate_keeper" and str(slime.get("promotion_id", "")) == "slime_gate_bulwark" and int(slime.get("promotion_stage", 0)) == 1, "%s: 특화·승급 보존" % prefix)
	_expect(game.global_directive == Constants.DIRECTIVE_SURVIVAL and str(game.room_directives.get("barracks", "")) == Constants.ROOM_DIRECTIVE_ENTRY_BLOCK, "%s: 전체·방 지침 보존" % prefix)
	_expect(game.selected_room == "barracks" and game.selected_monster_id == "slime", "%s: 관리 선택 상태 보존" % prefix)
	_expect(GameState.onboarding_complete and not game.tutorial_gate_enabled, "%s: 정규 캠페인 온보딩 완료 상태 보존" % prefix)


func _assert_stage_four_state(game: Node, prefix: String) -> void:
	_expect(game.castle_art_stage == STAGE_FOUR_ID, "%s: Stage 04 대마왕성 보존" % prefix)
	_expect(game.castle_evolution_history == ["stage_01_cave", "stage_02_castle", "stage_03_keep", "stage_04_citadel"], "%s: 마왕성 4단계 진화 이력 보존" % prefix)
	_expect(int(game._castle_stage_info().get("area_room_count", 0)) == 11, "%s: Stage 04 구역 계약 11개" % prefix)
	_expect(game.rooms.has("elite_garrison_01") and game.rooms.has("slot_03"), "%s: Stage 04 신규 건물 보존" % prefix)
	_expect(game.quarter_renderer != null and game.quarter_renderer.debug_full_grid_room_projection_count() == 11, "%s: 실제 쿼터뷰 구역 11개 투영" % prefix)
	_expect(GameState.demon_lord_max_hp == 2500 and int(game.rooms.get("throne", {}).get("hp", 0)) == 2500, "%s: Stage 04 왕좌 최대 체력 2500" % prefix)


func _check_title_layout(game: Node, status_needle: String) -> void:
	var controls: Array[Control] = []
	for button_text in ["새 게임", "이어하기", "빠른 시작", "설정", "종료"]:
		var button := _find_button_by_text(game.ui_layer, button_text)
		_expect(button != null, "제목 메뉴 버튼 존재: %s" % button_text)
		if button != null:
			controls.append(button)
	var status_control := _find_text_control(game.ui_layer, status_needle)
	_expect(status_control != null, "제목 저장 요약 라벨 존재")
	if status_control != null:
		controls.append(status_control)

	var screen_bounds := Rect2(Vector2.ZERO, Vector2(1920, 1080))
	for control in controls:
		_expect(screen_bounds.encloses(control.get_global_rect()), "제목 UI가 1920x1080 화면 안에 배치: %s" % control.name)
	for left_index in range(controls.size()):
		for right_index in range(left_index + 1, controls.size()):
			_expect(not controls[left_index].get_global_rect().intersects(controls[right_index].get_global_rect()), "제목 UI 비겹침: %s / %s" % [controls[left_index].name, controls[right_index].name])


func _new_game(save_path: String = TEST_SAVE_PATH) -> Node:
	var game = GameRootScene.instantiate()
	game._set_campaign_save_path_for_tests(save_path)
	add_child(game)
	await _settle(3)
	return game


func _dispose_game(game: Node) -> void:
	if not is_instance_valid(game):
		return
	game.campaign_save_enabled = false
	game.campaign_autosave_pending = false
	game.queue_free()
	await _settle(2)


func _settle(frame_count: int = 2) -> void:
	for _index in range(frame_count):
		await get_tree().process_frame
	await get_tree().physics_frame


func _scheduled_enemy_count(game: Node, enemy_id: String) -> int:
	var count := 0
	for entry in game.wave_manager.schedule:
		if str(entry.get("enemy_id", "")) == enemy_id:
			count += 1
	return count


func _scheduled_enemy_entry(game: Node, enemy_id: String) -> Dictionary:
	for entry in game.wave_manager.schedule:
		if str(entry.get("enemy_id", "")) == enemy_id:
			return entry
	return {}


func _find_button_by_text(node: Node, needle: String) -> Button:
	if node is Button and str(node.text).find(needle) >= 0:
		return node
	for child in node.get_children():
		var found := _find_button_by_text(child, needle)
		if found != null:
			return found
	return null


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


func _tree_has_text(node: Node, needle: String) -> bool:
	if node is Label and str(node.text).find(needle) >= 0:
		return true
	if node is RichTextLabel and str(node.text).find(needle) >= 0:
		return true
	if node is Button and str(node.text).find(needle) >= 0:
		return true
	for child in node.get_children():
		if _tree_has_text(child, needle):
			return true
	return false


func _write_raw_text(text: String) -> bool:
	return _write_raw_text_at(TEST_SAVE_PATH, text)


func _write_raw_text_at(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.flush()
	file.close()
	return true


func _read_json_dictionary(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[CampaignSaveLoad] FAIL: %s" % message)
