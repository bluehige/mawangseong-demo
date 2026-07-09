extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var failed := false

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = GameRootScene.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame

	game._onboarding_start_new_game()
	await get_tree().process_frame
	game.onboarding_name_input.text = "튜토리얼마왕"
	game._onboarding_confirm_name()
	await _drain_dialogue(game)
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "opening reaches management with tutorial gate on")
	_expect(game.tutorial_manager.current_step_id() == "TUT_030_SELECT_SLIME", "first management step asks for slime selection")

	game._start_combat()
	await get_tree().process_frame
	_expect(game.current_screen != Constants.SCREEN_COMBAT, "combat start is blocked before required management tutorial steps")

	game._select_monster("slime")
	await _drain_dialogue(game)
	_expect(game.tutorial_manager.current_step_id() == "TUT_040_DEPLOY_SLIME", "selecting slime completes unit_selected step")
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	game._assign_monster_to_room("slime", "entrance")
	await get_tree().process_frame
	_expect(game.tutorial_manager.current_step_id() == "TUT_050_GLOBAL_DEFEND", "deploying slime to entrance completes deployment step")

	game._set_global_directive(Constants.DIRECTIVE_DEFENSE)
	await _drain_dialogue(game)
	_expect(game.tutorial_manager.current_step_id() == "TUT_060_ROOM_BLOCK", "defense directive completes global directive step")
	game.selected_room = "entrance"
	game._set_room_directive(Constants.ROOM_DIRECTIVE_ENTRY_BLOCK)
	await _drain_dialogue(game)
	_expect(game.tutorial_manager.current_step_id() == "TUT_070_DIRECT_CONTROL", "entry block directive unlocks combat tutorial step")

	game._start_combat()
	await get_tree().physics_frame
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "combat starts after management tutorial steps")
	game._enable_direct_control()
	await _drain_dialogue(game)
	_expect(game.tutorial_manager.current_step_id() == "TUT_075_DIRECT_ATTACK", "direct control now asks for an actual attack command")
	var first_enemy = _first_alive_enemy(game)
	if first_enemy == null:
		game._spawn_enemy("explorer")
		await get_tree().physics_frame
		first_enemy = _first_alive_enemy(game)
	if first_enemy != null:
		game._handle_right_click(first_enemy.global_position)
	await _drain_dialogue(game)
	_expect(game.tutorial_manager.current_step_id() == "TUT_090_RESULT_GROWTH", "direct control and battle log steps unlock DAY 01 result growth review")
	await _finish_current_battle(game)
	var locked_next_button = _find_button_by_text(game.ui_layer, "성장 확인 필요")
	_expect(locked_next_button != null and locked_next_button.disabled, "DAY 01 result disables next-day button until growth review")
	game._continue_from_result()
	await get_tree().process_frame
	_expect(GameState.day == 1 and game.current_screen == Constants.SCREEN_RESULT, "DAY 01 result is blocked until growth review")
	game._review_growth_from_result()
	await get_tree().process_frame
	_expect(game.tutorial_manager.current_step_id() == "TUT_110_TREASURE", "growth review completes DAY 01 result tutorial step")
	game._continue_from_result()
	await _drain_dialogue(game)
	_expect(GameState.day == 2 and game.current_screen == Constants.SCREEN_MANAGEMENT, "DAY 01 result advances to DAY 02 management")

	game._start_combat()
	await get_tree().process_frame
	_expect(game.current_screen != Constants.SCREEN_COMBAT, "DAY 02 combat is blocked before treasure tutorial")
	game._select_room("treasure")
	await get_tree().process_frame
	_expect(game.tutorial_manager.current_step_id() == "TUT_120_TRAP_LURE", "treasure room selection completes DAY 02 room step")
	game._set_room_directive(Constants.ROOM_DIRECTIVE_TRAP_LURE)
	await _drain_dialogue(game)
	_expect(game.tutorial_manager.current_step_id() == "TUT_130_GOBLIN_CONTROL", "trap lure directive unlocks DAY 02 combat step")
	game._start_combat()
	await get_tree().physics_frame
	game._tutorial_emit_action("goblin_attacks_once", {"unit_id": "goblin"})
	await get_tree().process_frame
	_expect(game.tutorial_manager.current_step_id() == "TUT_210_RECOVERY_NEST", "goblin attack event completes DAY 02 combat step")
	await _finish_current_battle(game)
	game._continue_from_result()
	await _drain_dialogue(game)
	_expect(GameState.day == 3 and game.current_screen == Constants.SCREEN_MANAGEMENT, "DAY 02 result advances to DAY 03 management")

	game._select_room("recovery")
	await get_tree().process_frame
	_expect(game.tutorial_manager.current_step_id() == "TUT_220_RETREAT_LINE", "recovery nest selection completes DAY 03 room step")
	game._set_room_directive(Constants.ROOM_DIRECTIVE_RETREAT)
	await _drain_dialogue(game)
	_expect(game.tutorial_manager.current_step_id() == "TUT_230_IMP_FIREBALL", "retreat directive unlocks imp fireball step")
	game._start_combat()
	await get_tree().physics_frame
	var imp = _unit_by_id(game.monster_units, "imp")
	if imp != null:
		game._select_unit(imp)
	game._spawn_enemy("trainee_hero")
	game._use_selected_skill(0)
	await _drain_dialogue(game)
	_expect(game.tutorial_manager.current_step_id() == "TUT_240_BOSS_HP", "imp fireball completes DAY 03 skill step")
	game._tutorial_emit_action("boss_hp_50", {"hp_ratio": 0.5})
	await get_tree().process_frame
	_expect(game.tutorial_manager.current_step_id() == "TUT_310_RAID_PREVIEW", "boss HP threshold advances to raid preview step")
	await _finish_current_battle(game)
	game._continue_from_result()
	await _drain_dialogue(game)
	_expect(GameState.day == 4 and game.current_screen == Constants.SCREEN_RAID_PREVIEW, "DAY 03 result advances to DAY 04 preview")
	_expect(not game.tutorial_manager.active, "raid preview dialogue closes final tutorial step")

	game.queue_free()
	await get_tree().process_frame
	if failed:
		print("TUTORIAL_FLOW_SMOKE_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("TUTORIAL_FLOW_SMOKE_TEST: PASS")
		get_tree().quit(0)

func _drain_dialogue(game: Node, max_steps: int = 160) -> void:
	var quiet_frames := 0
	for _i in range(max_steps):
		await get_tree().process_frame
		if game.current_screen == Constants.SCREEN_DIALOGUE:
			quiet_frames = 0
			game._onboarding_advance_dialogue()
		else:
			quiet_frames += 1
			if quiet_frames >= 3:
				return
	push_error("Timed out while draining dialogue")
	failed = true

func _finish_current_battle(game: Node) -> void:
	game.wave_manager.next_index = game.wave_manager.schedule.size()
	for entry in game.wave_manager.schedule:
		game._spawn_enemy(str(entry.get("enemy_id", "explorer")))
	for enemy in game.enemy_units:
		if enemy.is_alive():
			enemy.receive_damage(9999)
	game._check_combat_end()
	await _drain_dialogue(game)
	_expect(game.current_screen == Constants.SCREEN_RESULT, "battle result screen reached")

func _unit_by_id(units: Array, unit_id: String) -> Node:
	for unit in units:
		if unit.unit_id == unit_id:
			return unit
	return null

func _first_alive_enemy(game: Node) -> Node:
	for unit in game.enemy_units:
		if unit.is_alive():
			return unit
	return null

func _find_button_by_text(node: Node, text: String) -> Button:
	if node is Button and node.text == text:
		return node
	for child in node.get_children():
		var result = _find_button_by_text(child, text)
		if result != null:
			return result
	return null

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		push_error("FAIL: %s" % message)
		failed = true
