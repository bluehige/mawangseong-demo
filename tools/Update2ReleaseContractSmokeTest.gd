extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const CampaignSaveStoreScript = preload("res://scripts/core/CampaignSaveStore.gd")
const CampaignSaveV2StoreScript = preload("res://scripts/core/CampaignSaveV2Store.gd")
const CampaignSaveV3StoreScript = preload("res://scripts/core/CampaignSaveV3Store.gd")
const CampaignSaveV4StoreScript = preload("res://scripts/systems/save/CampaignSaveV4Store.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const TEST_SAVE_V1 := "user://update2_release_contract_v1.json"
const TEST_SAVE_V2 := "user://update2_release_contract_v2.json"
const TEST_SAVE_V3 := "user://update2_release_contract_v3.json"
const TEST_SAVE_V4 := "user://update2_release_contract_v4.json"
const SOURCE_ROOT := "res://assets/source/imagegen/update2_counterforce"
const COUNTERFORCE_IDS := [
	"royal_scout",
	"monster_binder",
	"ward_breaker",
	"supply_raider",
	"anti_magic_archer",
	"royal_field_medic",
	"royal_strategist_evelyn"
]
const FRAME_COUNTS := {
	"idle_down": 2,
	"move_down": 4,
	"attack_down": 4,
	"skill_down": 4,
	"down": 2
}

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_graphics_source_and_frames()
	await _test_next_cycle_save_and_continue()
	_cleanup_saves()
	if failed:
		print("UPDATE2_RELEASE_CONTRACT_SMOKE_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("UPDATE2_RELEASE_CONTRACT_SMOKE_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_graphics_source_and_frames() -> void:
	var source_document_path := "%s/SOURCE.md" % SOURCE_ROOT
	_expect(FileAccess.file_exists(source_document_path), "2차 신규 대응군 SOURCE 문서 존재")
	var source_document := FileAccess.get_file_as_string(source_document_path)
	_expect(source_document.contains("built-in") and source_document.contains("imagegen"), "SOURCE 문서에 기본 이미지 생성 경로 기록")
	_expect(source_document.contains("idle 2 / move 4 / attack 4 / skill 4 / down 2"), "SOURCE 문서에 프레임 계약 기록")
	for enemy_id in COUNTERFORCE_IDS:
		_expect(source_document.contains(enemy_id), "%s SOURCE 식별자 기록" % enemy_id)
	for source_name in ["design", "move", "attack", "skill", "down"]:
		var chroma_path := "%s/counterforce_%s_sheet_4x2_chroma.png" % [SOURCE_ROOT, source_name]
		_expect(FileAccess.file_exists(chroma_path), "%s chroma 생성 원본 보존" % source_name)
	for source_name in ["idle", "move", "attack", "skill", "down"]:
		var alpha_path := "%s/counterforce_%s_sheet_4x2_alpha.png" % [SOURCE_ROOT, source_name]
		_expect(FileAccess.file_exists(alpha_path), "%s alpha 생성 원본 보존" % source_name)

	for enemy_id in COUNTERFORCE_IDS:
		var unique_frame_hashes: Dictionary = {}
		var total_frames := 0
		for animation_name in FRAME_COUNTS:
			var expected_count: int = int(FRAME_COUNTS[animation_name])
			for frame_index in range(expected_count):
				var frame_path := "res://assets/sprites/enemies/enemy_%s_%s_%02d.png" % [enemy_id, animation_name, frame_index]
				var texture: Texture2D = ResourceLoader.load(frame_path)
				var image: Image = texture.get_image() if texture != null else null
				_expect(image != null, "%s %s %02d 프레임 로드" % [enemy_id, animation_name, frame_index])
				if image == null:
					continue
				_expect(image.get_width() == 192 and image.get_height() == 192, "%s %s %02d 프레임 192×192" % [enemy_id, animation_name, frame_index])
				_expect(image.detect_alpha() != Image.ALPHA_NONE, "%s %s %02d 투명 배경" % [enemy_id, animation_name, frame_index])
				unique_frame_hashes[hash(image.get_data())] = true
				total_frames += 1
		_expect(total_frames == 16, "%s 프레임 계약 합계 16장" % enemy_id)
		_expect(unique_frame_hashes.size() == 16, "%s 런타임 프레임 16장 픽셀 중복 없음" % enemy_id)


func _test_next_cycle_save_and_continue() -> void:
	_cleanup_saves()
	GameState.reset()
	var game = GameRootScene.instantiate()
	game._set_campaign_save_path_for_tests(TEST_SAVE_V1, TEST_SAVE_V2, TEST_SAVE_V3, TEST_SAVE_V4)
	add_child(game)
	await _settle(4)
	game._debug_skip_onboarding()
	GameState.day = 30
	GameState.player_name = "2차 릴리스 검증"
	game.campaign_completed = true
	game.campaign_final_battle_outcome = "victory"
	game.campaign_final_preparation_confirmed = true
	game._campaign_next_cycle_from_ending()
	await _settle(8)

	_expect(game.current_screen == Constants.SCREEN_FRONT_SELECTION, "DAY 30 승리 뒤 다음 회차 전선 선택 진입")
	_expect(bool(game.update3_active_run.get("new_cycle_selection_pending", false)), "새 회차 전선 선택 대기 저장")
	game._select_update3_front("front_hero_oath")
	await _settle(6)
	var heart_selection_reached: bool = game.current_screen == Constants.SCREEN_HEART_SELECTION
	game._select_update3_heart("heart_stonebone")
	await _settle(6)
	_expect(heart_selection_reached and game.current_screen == Constants.SCREEN_CONTRACT_BOARD, "레온 전선→석골 심장→계약 게시판 순차 진입")
	_expect(GameState.day == 4, "다음 회차도 DAY 31 없이 DAY 04 관리 준비로 시작")
	_expect(int(game.campaign_profile.get("completed_cycles", 0)) == 1 and game.campaign_cycle_index == 2, "완료 회차와 현재 2회차 기록")
	_expect(game.contract_board_offer_ids.size() >= 2, "다음 회차 계약 후보 2종 이상 제시")
	_expect(str(CampaignSaveStoreScript.inspect(TEST_SAVE_V1).get("status", "")) == CampaignSaveStoreScript.STATUS_VALID, "다음 회차 자동 저장 v1 체크포인트 생성")
	var v2_inspection := CampaignSaveV2StoreScript.inspect(TEST_SAVE_V2, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	_expect(str(v2_inspection.get("status", "")) == CampaignSaveV2StoreScript.STATUS_VALID, "다음 회차 보조 저장 v2 생성")
	var v3_inspection := CampaignSaveV3StoreScript.inspect(TEST_SAVE_V3, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	_expect(str(v3_inspection.get("status", "")) == CampaignSaveV3StoreScript.STATUS_VALID, "다음 회차 저장 v3 생성·재검증")
	var v3_envelope: Dictionary = v3_inspection.get("envelope", {})
	_expect(int(v3_envelope.get("version", 0)) == 3 and int(v3_envelope.get("campaign_final_day", 0)) == 30, "저장 v3와 DAY 30 최종일 계약")
	_expect(int(v3_envelope.get("profile", {}).get("completed_cycles", 0)) == 1, "저장 v3 프로필에 완료 회차 보존")
	_expect(int(v3_envelope.get("active_run", {}).get("cycle_index", 0)) == 2, "저장 v3 active_run에 새 회차 번호 보존")
	var v4_inspection := CampaignSaveV4StoreScript.inspect(TEST_SAVE_V4, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, game._update3_save_catalogs())
	_expect(str(v4_inspection.get("status", "")) == CampaignSaveV4StoreScript.STATUS_VALID, "전선·심장 선택 다음 회차 저장 v4 생성·재검증")
	_expect(str(v4_inspection.get("envelope", {}).get("active_run", {}).get("front_id", "")) == "front_hero_oath" and bool(v4_inspection.get("envelope", {}).get("active_run", {}).get("front_selection_completed", false)) and str(v4_inspection.get("envelope", {}).get("active_run", {}).get("heart", {}).get("heart_id", "")) == "heart_stonebone", "저장 v4에 레온 전선·석골 심장 선택 보존")
	game.queue_free()
	await _settle(3)

	var restored = GameRootScene.instantiate()
	restored._set_campaign_save_path_for_tests(TEST_SAVE_V1, TEST_SAVE_V2, TEST_SAVE_V3)
	add_child(restored)
	await _settle(4)
	_expect(restored.campaign_save_status == CampaignSaveStoreScript.STATUS_VALID, "제목 화면에서 다음 회차 저장을 이어하기 가능 상태로 판정")
	restored._continue_campaign_save()
	await _settle(6)
	_expect(restored.current_screen == Constants.SCREEN_CONTRACT_BOARD and GameState.day == 4, "다음 회차 계약 게시판 체크포인트 복원")
	_expect(restored.campaign_cycle_index == 2 and int(restored.campaign_profile.get("completed_cycles", 0)) == 1, "이어하기에서 회차 프로필 무손실 복원(cycle=%d, completed=%d)" % [restored.campaign_cycle_index, int(restored.campaign_profile.get("completed_cycles", 0))])
	restored.queue_free()
	await _settle(3)


func _cleanup_saves() -> void:
	CampaignSaveStoreScript.delete(TEST_SAVE_V1)
	CampaignSaveV2StoreScript.delete(TEST_SAVE_V2)
	CampaignSaveV3StoreScript.delete(TEST_SAVE_V3)
	CampaignSaveV4StoreScript.delete(TEST_SAVE_V4)


func _settle(frame_count: int) -> void:
	for _index in range(frame_count):
		await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[Update2ReleaseContract] FAIL: %s" % message)
