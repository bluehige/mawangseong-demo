extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const FrontServiceScript = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var game: Node
var output_dir := ""
var failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = ProjectSettings.globalize_path("res://tmp/update3_phase27")
	DirAccess.make_dir_recursive_absolute(output_dir)
	game = GameRootScene.instantiate()
	add_child(game)
	await _settle(4)
	game._debug_skip_onboarding()
	_prepare_common()
	_prepare_e12()
	game._set_screen(Constants.SCREEN_ENDING)
	await _capture(Vector2i(1920, 1080), "ending_e12_1920x1080.png", "ending_holy_open_gate")
	_prepare_e13()
	game._set_screen(Constants.SCREEN_ENDING)
	await _capture(Vector2i(1366, 768), "ending_e13_1366x768.png", "ending_off_ledger_independence")
	_prepare_e14()
	game._set_screen(Constants.SCREEN_ENDING)
	await _capture(Vector2i(1920, 1080), "ending_e14_1920x1080.png", "ending_living_castle_voice")
	print("ENDING_PHASE27_VISUAL_REVIEW: %s" % ("FAIL" if failed else "PASS"))
	get_tree().quit(1 if failed else 0)


func _prepare_common() -> void:
	GameState.day = 30
	GameState.gold = 500
	GameState.infamy = 0
	GameState.demon_lord_max_hp = 1000
	GameState.demon_lord_hp = 900
	game.campaign_completed = true
	game.campaign_final_battle_outcome = "victory"
	game.update3_profile = FrontServiceScript.default_update3_profile()
	game.update3_active_run = FrontServiceScript.default_legacy_active_run(3)
	game.update3_active_run["update3_enabled"] = true
	game.update3_active_run["heart"]["heart_id"] = "heart_stonebone"


func _prepare_e12() -> void:
	game.update3_profile["rival_relations"]["selen"] = 76
	game.update3_active_run["front_id"] = "front_holy_purification"
	game.update3_active_run["run_metrics_update3"] = {
		"e12_living_castle_testimony": 1,
		"e12_responsible_heart": 1,
		"holy_seals_interrupted": 3,
		"heart_chamber_disable_count": 0
	}


func _prepare_e13() -> void:
	game.update3_profile["rival_relations"]["selen"] = 0
	game.update3_profile["rival_relations"]["roman"] = 74
	game.update3_active_run["front_id"] = "front_guild_repossession"
	game.update3_active_run["run_metrics_update3"] = {
		"security_grade_total": 12,
		"security_grade_count": 4,
		"campaign_treasure_losses": 1,
		"facility_disable_count": 3,
		"debt_marks_cleansed": 5,
		"heart_chamber_disable_count": 0
	}


func _prepare_e14() -> void:
	game.update3_profile["rival_relations"] = {"leon": 0, "selen": 0, "roman": 0}
	game.update3_active_run["front_id"] = "front_hero_oath"
	game.update3_active_run["heart"]["heart_id"] = "heart_stonebone"
	game.update3_active_run["run_metrics_update3"] = {
		"heart_active_uses": 8,
		"heart_chamber_disable_count": 0,
		"heart_metric_contribution": 300,
		"campaign_monster_contribution": 1000,
		"selected_heart_mastery_before_run": 1,
		"stonebone_facility_damage_reduced": 300
	}


func _capture(size: Vector2i, file_name: String, expected_ending_id: String) -> void:
	DisplayServer.window_set_size(size)
	await _settle(10)
	if game.resolved_campaign_ending_id != expected_ending_id:
		failed = true
		push_error("예상 엔딩 %s 대신 %s가 표시됐습니다." % [expected_ending_id, game.resolved_campaign_ending_id])
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image == null or absi(image.get_width() - size.x) > 1 or absi(image.get_height() - size.y) > 1:
		failed = true
		push_error("예상 해상도 %s 캡처 실패" % size)
		return
	image.convert(Image.FORMAT_RGB8)
	if image.save_png(output_dir.path_join(file_name)) != OK:
		failed = true
		push_error("엔딩 캡처 저장 실패: %s" % file_name)


func _settle(frames: int) -> void:
	for _index in range(frames):
		await get_tree().process_frame
		await get_tree().physics_frame
