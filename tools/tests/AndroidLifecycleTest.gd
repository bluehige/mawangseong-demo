extends Node

const Game = preload("res://scenes/game/GameRoot.tscn")
const Lifecycle = preload("res://scripts/core/AndroidLifecycle.gd")
const Bundle = preload("res://scripts/core/CampaignSaveBundleGuard.gd")
var checks := 0
var failures: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("run")

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func settle() -> void:
	for i in range(6): await get_tree().process_frame

func run() -> void:
	expect(ProjectSettings.globalize_path("user://").contains("android_build"), "isolated test user directory")
	if not failures.is_empty(): get_tree().quit(1); return
	var game: Node = Game.instantiate()
	game.campaign_save_enabled = false
	add_child(game)
	await settle()
	expect(Engine.max_fps == 120, "desktop FPS remains 120")
	expect(game.quarter_renderer.debug_render_profile() == "full" if game.get("quarter_renderer") != null else not OS.has_feature("android"), "desktop platform is unchanged")
	for child in game.get_children():
		expect(child.get_script() != Lifecycle, "Android lifecycle is absent on desktop")
	game.continuity.acknowledge_update()
	game._onboarding_reset_game()
	GameState.player_name = "Android Tester"
	game.onboarding_enabled = false
	game.story_feature_enabled = false
	game.story_director.cancel_active_scene()
	game.tutorial_manager.active = false
	game._onboarding_enter_management_day(1, true)
	game._set_campaign_save_path_for_tests("user://v1.json", "user://v2.json", "user://v3.json", "user://v4.json", "user://v5.json", "user://v6.json")
	game.campaign_save_enabled = true
	game._set_screen("management", false)
	var lifecycle = Lifecycle.new()
	add_child(lifecycle)
	lifecycle.setup(game)
	var paths: Array = [game.campaign_save_path, game.campaign_save_v2_path, game.campaign_save_v3_path, game.campaign_save_v4_path, game.campaign_save_v5_path, game.campaign_save_v6_path]
	GameState.gold += 17
	var saved_gold: int = GameState.gold
	lifecycle.notification(NOTIFICATION_APPLICATION_PAUSED)
	expect(get_tree().paused and lifecycle.backgrounded, "background pauses the complete tree")
	expect(game.pause_menu_open, "background leaves existing pause menu open")
	expect(FileAccess.file_exists(game.campaign_save_v6_path), "background synchronously saves v6")
	expect(not lifecycle.keep_screen_on, "background releases screen wake request")
	var before: Dictionary = Bundle.snapshot(paths)
	lifecycle.notification(NOTIFICATION_APPLICATION_PAUSED)
	expect(Bundle.snapshot(paths).files == before.files, "duplicate pause is idempotent")
	lifecycle.notification(NOTIFICATION_APPLICATION_RESUMED)
	expect(not get_tree().paused and game.pause_menu_open, "resume restores tree but retains player menu")
	lifecycle.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	await settle()
	expect(not game.pause_menu_open, "back closes the existing menu")
	game._open_settings_screen()
	lifecycle.cancel_or_menu()
	await settle()
	expect(game.current_screen == "management", "back leaves settings through existing cancel path")
	GameState.gold += 9
	game._continue_campaign_save()
	await settle()
	expect(GameState.gold == saved_gold, "background save restores committed progress")
	game.combat_scene.start_combat()
	game.story_director.cancel_active_scene()
	game.story_combat_overlay_open = false
	game.combat_scene.set_pause_state(false, false)
	lifecycle._update_screen_awake()
	expect(lifecycle.keep_screen_on, "combat requests screen awake")
	before = Bundle.snapshot(paths)
	lifecycle.pause_application()
	var elapsed: float = game.combat_time
	await settle()
	expect(game.combat_time == elapsed and game.combat_paused, "background stops combat time")
	expect(Bundle.snapshot(paths).files == before.files, "combat preserves safe checkpoint bytes")
	lifecycle.resume_application()
	expect(game.combat_paused and game.pause_menu_open, "combat stays paused until explicit resume")
	lifecycle.cancel_or_menu()
	await settle()
	expect(not game.combat_scene.requested_pause and game.combat_paused == game.combat_scene.presentation_hold, "resume restores user pause state while preserving active skill presentation")
	game.combat_scene.set_pause_state(true, false)
	lifecycle.pause_application()
	lifecycle.resume_application()
	game._close_pause_menu()
	expect(game.combat_paused, "already paused combat remains paused")
	game._set_screen("title", false)
	lifecycle._update_screen_awake()
	expect(not lifecycle.keep_screen_on, "leaving combat releases screen wake request")
	lifecycle.queue_free()
	game.queue_free()
	await settle()
	var result := {"checks": checks, "failures": failures}
	var file := FileAccess.open("res://tmp/android_build/lifecycle_result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	print("AndroidLifecycleTest: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
