extends Node
const Constants = preload("res://scripts/core/Constants.gd")
var game: Node
var checks := 0
var failures: Array[String] = []

func _ready() -> void:
	call_deferred("run")

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); print("FAIL: " + message)

func settle() -> void:
	for i in range(12): await get_tree().process_frame

func tutorial(id: String) -> void:
	for i in range(game.tutorial_manager.steps.size()):
		var step: Dictionary = game.tutorial_manager.steps[i]
		if str(step.id) == id:
			game.tutorial_manager.current_index = i
			game.tutorial_manager.active = true
			game.onboarding_enabled = true
			game._onboarding_set_stage(str(step.stage))
			return
	expect(false,"tutorial step exists " + id)

func overlay() -> Node:
	return game.ui_layer.get_node_or_null("TutorialOverlay")

func run() -> void:
	expect(ProjectSettings.globalize_path("user://").replace("\\", "/").contains("/tmp/v1213_perf/"), "isolated APPDATA")
	if not failures.is_empty(): get_tree().quit(2); return
	LanguageSettings.set_locale("ko",false)
	game = load("res://scenes/game/GameRoot.tscn").instantiate()
	game.campaign_save_enabled = false
	game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v4_enabled = false
	game.campaign_save_v5_enabled = false
	add_child(game)
	await settle()
	tutorial("TUT_030_SELECT_SLIME")
	game._set_screen(Constants.SCREEN_MANAGEMENT,false)
	await settle()
	var first := overlay()
	expect(first != null,"DAY1 overlay exists")
	if first == null: get_tree().quit(1); return
	for i in range(120): game._tutorial_build_overlay()
	await settle()
	expect(overlay() == first,"unchanged overlay and pulse nodes reused across 120 inputs")
	var view := get_viewport().canvas_transform
	view.origin += Vector2(12,8)
	get_viewport().canvas_transform = view
	game._tutorial_build_overlay()
	await settle()
	expect(overlay() == first,"world pan does not recreate stationary HUD focus")
	LanguageSettings.set_locale("en",false)
	game._tutorial_build_overlay()
	await settle()
	expect(overlay() != first,"locale change invalidates presentation")
	GameState.day = 2
	tutorial("TUT_110_TRAP_CORRIDOR")
	game._set_screen(Constants.SCREEN_MANAGEMENT,false)
	await settle()
	var room_overlay := overlay()
	var focus_before: Rect2 = game._tutorial_focus_rect("ROOM_SPIKE_CORRIDOR")
	expect(focus_before.has_area(),"converted room focus has visible area before movement")
	view = get_viewport().canvas_transform
	view.origin += Vector2(26,16)
	get_viewport().canvas_transform = view
	game._tutorial_build_overlay()
	await settle()
	expect(overlay() != room_overlay,"moving room focus still rebuilds overlay")
	expect(game._tutorial_focus_rect("ROOM_SPIKE_CORRIDOR") != focus_before,"room focus follows canvas")
	game.onboarding_enabled = false
	game._tutorial_build_overlay()
	await settle()
	expect(overlay() == null,"disabled tutorial clears reused overlay")
	game.queue_free()
	await settle()
	print("V1213_PERF_FREEZE: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)
