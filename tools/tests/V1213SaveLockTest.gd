extends Node

const GameScene = preload("res://scenes/game/GameRoot.tscn")
const OUTPUT = "res://tmp/v1213_s1"
var checks := 0
var failures: Array[String] = []

func _ready() -> void:
	get_tree().create_timer(45).timeout.connect(func(): get_tree().quit(1))
	call_deferred("run")

func expect(ok: bool, text: String) -> void:
	checks += 1
	print("%s: %s" % ["PASS" if ok else "FAIL",text])
	if not ok: failures.append(text)

func settle() -> void:
	for i in range(8): await get_tree().process_frame

func marker(name: String, value: String = "ready") -> void:
	var file := FileAccess.open(OUTPUT.path_join(name),FileAccess.WRITE)
	file.store_string(value)
	file.close()

func wait_marker(name: String) -> void:
	while not FileAccess.file_exists(OUTPUT.path_join(name)):
		await get_tree().create_timer(0.05).timeout

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await settle()
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	expect(image.get_size() == Vector2i(1920,1080), "S1-02 1920x1080 " + name)
	image.save_png(OUTPUT.path_join(name + ".png"))

func run() -> void:
	expect(ProjectSettings.globalize_path("user://").replace("\\","/").contains("/tmp/v1213_s1/"), "S1-02 isolated APPDATA")
	if not failures.is_empty():
		get_tree().quit(1)
		return
	GameState.reset()
	var game = GameScene.instantiate()
	game._set_campaign_save_path_for_tests("user://lock_campaign.json", "user://lock_v2.json", "user://lock_v3.json", "user://lock_v4.json", "user://lock_v5.json")
	add_child(game)
	await settle()
	game._onboarding_reset_game()
	game._debug_skip_onboarding()
	GameState.player_name = "S1 isolated save test"
	game.set_process(false)
	game.set_physics_process(false)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(Vector2i(1920,1080))
		await settle()
	game._set_screen("management",false)
	game._open_pause_menu()
	expect(game.continuity.save_now(), "S1-02 create normal five-format checkpoint")
	if not failures.is_empty():
		get_tree().quit(1)
		return
	var paths := [game.campaign_save_path,game.campaign_save_v2_path,game.campaign_save_v3_path,game.campaign_save_v4_path,game.campaign_save_v5_path]
	var before := preload("res://scripts/core/CampaignSaveBundleGuard.gd").snapshot(paths)
	expect(before.ok, "S1-02 normal save bundle readable before lock")
	marker("lock-ready.txt",ProjectSettings.globalize_path(game.campaign_save_path))
	await wait_marker("lock-held.txt")
	expect(not game.continuity.save_now(), "S1-02 locked existing checkpoint rejects new write")
	expect(game.campaign_save_error != "" and game.campaign_save_notice != "", "S1-02 read failure retains error and notice")
	expect(game.ui_layer.find_child("CampaignSaveNoticeOverlay",true,false) != null, "S1-02 read failure displays warning")
	await capture("save_locked_warning")
	game.continuity.confirm("quit")
	game.continuity.leave(true)
	await settle()
	expect(game.continuity.confirmation_action == "quit" and game.tutorial_targets.get("LeaveSaveFailure", {}).get("control") != null, "S1-02 failed save-and-quit preserves retry/error dialog")
	await capture("save_locked_quit_retry")
	marker("unlock-request.txt")
	await wait_marker("lock-released.txt")
	var after := preload("res://scripts/core/CampaignSaveBundleGuard.gd").snapshot(paths)
	expect(after.ok and after.files == before.files, "S1-02 all five prior checkpoint bytes preserved")
	game.continuity.cancel_confirmation()
	expect(game.continuity.save_now() and game.campaign_save_error == "" and game.campaign_save_notice == "", "S1-02 save retry succeeds after lock released")
	game.campaign_save_enabled = false
	game.campaign_autosave_pending = false
	game.queue_free()
	await settle()
	print("V1213_SAVE_LOCK_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)
