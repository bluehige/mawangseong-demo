extends Node

const HUDControllerScript = preload("res://scripts/ui/HUDController.gd")
const GameRootScript = preload("res://scripts/game/GameRoot.gd")
const CombatSceneControllerScript = preload("res://scripts/game/CombatSceneController.gd")
const UnitActorScript = preload("res://scripts/units/Unit.gd")

class HUDRootStub extends Node:
	var ui_layer: CanvasLayer

	func _init() -> void:
		ui_layer = CanvasLayer.new()
		add_child(ui_layer)

class CombatRootStub extends Node2D:
	var effect_root: Node2D

	func _init() -> void:
		effect_root = Node2D.new()
		add_child(effect_root)

var failed := false
var assertion_count := 0
var probe_pressed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_shared_hud_contract()
	_test_onboarding_contract()
	await _test_runtime_feedback_contract()
	if assertion_count < 10:
		failed = true
		push_error("[UIInputLayer] FAIL: test dependencies did not complete")
	if failed:
		print("UI_INPUT_LAYER_SMOKE_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("UI_INPUT_LAYER_SMOKE_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_shared_hud_contract() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(400, 300)
	add_child(viewport)
	var stub := HUDRootStub.new()
	viewport.add_child(stub)
	var hud = HUDControllerScript.new()
	hud.setup(stub)

	var interactive_host := Control.new()
	interactive_host.size = Vector2(400, 300)
	stub.ui_layer.add_child(interactive_host)
	var helper_button: Button = hud.button(interactive_host, "확인", Rect2(8, 8, 100, 36), Callable(self, "_on_probe_pressed"))
	var helper_slider: HSlider = hud.slider(interactive_host, Rect2(116, 8, 120, 36), 50.0, Callable(self, "_on_slider_changed"))
	var helper_option: OptionButton = hud.option_button(interactive_host, Rect2(244, 8, 120, 36), [{"value": "one", "label": "하나"}], "one", Callable(self, "_on_option_selected"))
	_expect(helper_button.mouse_filter == Control.MOUSE_FILTER_STOP, "shared HUD buttons explicitly own mouse input")
	_expect(helper_slider.mouse_filter == Control.MOUSE_FILTER_STOP, "shared HUD sliders explicitly own mouse input")
	_expect(helper_option.mouse_filter == Control.MOUSE_FILTER_STOP, "shared HUD options explicitly own mouse input")

	var button := Button.new()
	button.name = "InputLayerProbeButton"
	button.position = Vector2(70, 100)
	button.size = Vector2(260, 100)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.z_index = 1
	button.pressed.connect(_on_probe_pressed)
	stub.ui_layer.add_child(button)
	var cover: Panel = hud.panel(Rect2(button.position, button.size), Color("#ffffff22"), Color("#ffffff55"), "", "flat")
	cover.name = "LateDecorativeCover"
	cover.z_index = 2
	_expect(cover.mouse_filter == Control.MOUSE_FILTER_IGNORE, "shared HUD panels are passive by default")
	await get_tree().process_frame
	await _click(viewport, button.get_global_rect().get_center())
	_expect(probe_pressed, "a button remains clickable below a later, higher decorative panel")
	viewport.queue_free()
	await get_tree().process_frame


func _test_onboarding_contract() -> void:
	var game = GameRootScript.new()
	game.ui_layer = CanvasLayer.new()
	game.add_child(game.ui_layer)
	game.hud = HUDControllerScript.new()
	game.hud.setup(game)
	var screen: Panel = game._onboarding_screen_panel(Color.BLACK)
	var child: Panel = game._onboarding_child_panel(screen, Rect2(0, 0, 100, 100), Color.BLACK, Color.WHITE)
	_expect(screen.mouse_filter == Control.MOUSE_FILTER_STOP, "full-screen onboarding explicitly blocks underlying input")
	_expect(child.mouse_filter == Control.MOUSE_FILTER_IGNORE, "decorative onboarding child panels are passive")
	game.free()


func _test_runtime_feedback_contract() -> void:
	var unit = UnitActorScript.new()
	add_child(unit)
	await get_tree().process_frame
	_expect(unit.name_label != null and unit.name_label.mouse_filter == Control.MOUSE_FILTER_IGNORE, "unit name labels do not intercept input")
	unit.queue_free()

	var combat_root := CombatRootStub.new()
	add_child(combat_root)
	var combat = CombatSceneControllerScript.new()
	combat.setup(combat_root, null)
	combat.spawn_damage_number(Vector2(100, 100), 12, "monster")
	combat.spawn_growth_preparation_feedback(Vector2(180, 160), "철벽 준비")
	await get_tree().process_frame
	var passive_feedback := true
	var feedback_count := 0
	for child in combat_root.effect_root.get_children():
		if child is Label:
			feedback_count += 1
			passive_feedback = passive_feedback and child.mouse_filter == Control.MOUSE_FILTER_IGNORE
	_expect(feedback_count == 2, "combat feedback labels are created")
	_expect(passive_feedback, "combat feedback labels do not intercept input")
	combat_root.queue_free()
	await get_tree().process_frame


func _click(viewport: Viewport, position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	viewport.push_input(motion, true)
	await get_tree().process_frame
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.position = position
	press.global_position = position
	viewport.push_input(press, true)
	await get_tree().process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = position
	release.global_position = position
	viewport.push_input(release, true)
	await get_tree().process_frame


func _on_probe_pressed() -> void:
	probe_pressed = true


func _on_slider_changed(_value: float) -> void:
	pass


func _on_option_selected(_value: String) -> void:
	pass


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[UIInputLayer] FAIL: %s" % message)
