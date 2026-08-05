extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const VIEWPORT_SIZE := Vector2i(1280, 720)
const OUTPUT_DIR := "res://tmp/v122_release_polish/luna_audit"

var game: Node
var failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_size(VIEWPORT_SIZE)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	await _new_game()
	game.selected_contract_ids.clear()
	game.contract_board_pending_ids.clear()
	game.contract_board_offer_ids.clear()
	game._set_screen(Constants.SCREEN_CONTRACT_BOARD)
	await _settle(8)
	_expect(game.contract_board_offer_ids.size() == 4, "신규 계약 화면은 전투 외형이 준비된 4종만 표시한다")
	_expect(not game.contract_board_offer_ids.has("moon_tracker"), "신규 계약 화면에서 루미를 숨긴다")
	await _save("moon_tracker_new_offer_gate_1280x720.png")

	game.selected_contract_ids.assign(["moon_tracker", "spore_healer"])
	game.contract_board_pending_ids.assign(game.selected_contract_ids)
	game.monster_roster = {
		"moon_tracker": {"level": 1, "defense_enabled": true},
		"spore_healer": {"level": 1, "defense_enabled": true}
	}
	game.deployed_instance_ids.assign(["mon_contract_lumi", "mon_contract_mori"])
	game._sanitize_unready_contract_combat_assets()
	game._set_screen(Constants.SCREEN_CONTRACT_BOARD)
	await _settle(8)
	_expect(game.selected_contract_ids.has("moon_tracker"), "기존 저장의 루미 계약 소유 기록은 유지한다")
	_expect(not game.deployed_instance_ids.has("mon_contract_lumi"), "기존 저장의 루미 방어 출전은 해제한다")
	_expect(_visible_text_exists("예비 · 전투 외형 준비 중"), "편성 화면에 전투 외형 대기 사유를 표시한다")
	await _save("moon_tracker_owned_reserve_gate_1280x720.png")

	await _dispose_game()
	print("V122_MOON_TRACKER_GATE_CAPTURE: %s" % ("FAIL" if failed else "PASS"))
	get_tree().quit(1 if failed else 0)


func _new_game() -> void:
	game = GameRootScene.instantiate()
	add_child(game)
	await _settle(8)
	game.campaign_save_enabled = false
	game._debug_skip_onboarding()
	GameState.day = 4
	GameState.max_day = 30
	GameState.player_name = "luna-audit"
	GameState.onboarding_complete = true
	game.campaign_cycle_index = 2
	game.update2_cycle_seed = 20260802


func _dispose_game() -> void:
	if game == null or not is_instance_valid(game):
		return
	remove_child(game)
	game.queue_free()
	game = null
	await _settle(4)


func _visible_text_exists(expected: String) -> bool:
	for node in game.ui_layer.find_children("*", "Label", true, false):
		if node is Label and node.visible and str(node.text) == expected:
			return true
	return false


func _save(file_name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	_expect(image != null and not image.is_empty(), "%s 화면을 읽는다" % file_name)
	if image == null or image.is_empty():
		return
	_expect(image.get_size() == VIEWPORT_SIZE, "%s 화면은 1280×720이다" % file_name)
	var path := ProjectSettings.globalize_path(OUTPUT_DIR).path_join(file_name)
	_expect(image.save_png(path) == OK, "%s 캡처를 저장한다" % file_name)


func _settle(frame_count: int) -> void:
	for _index in range(frame_count):
		await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	failed = true
	push_error("FAIL: %s" % message)
