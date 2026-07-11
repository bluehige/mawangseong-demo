extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var failed := false

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var quick_game = GameRootScene.instantiate()
	add_child(quick_game)
	await get_tree().process_frame
	await get_tree().physics_frame
	var quick_start_button = _find_button_by_text(quick_game.ui_layer, "빠른 시작")
	_expect(quick_start_button != null, "title exposes quick start")
	if quick_start_button != null:
		quick_start_button.pressed.emit()
	await get_tree().process_frame
	_expect(quick_game.current_screen == Constants.SCREEN_MANAGEMENT, "quick start enters DAY 01 management immediately")
	_expect(GameState.player_name == "신입 마왕", "quick start assigns a default player name")
	_expect(quick_game.tutorial_manager.current_step_id() == "TUT_030_SELECT_SLIME", "quick start preserves the required gameplay tutorial")
	_expect(quick_game.onboarding_dialogue_queue.is_empty(), "quick start does not queue opening dialogue")
	quick_game.queue_free()
	await get_tree().process_frame

	var game = GameRootScene.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame

	game._onboarding_start_new_game()
	await get_tree().process_frame
	_expect(game.global_directive == Constants.DIRECTIVE_ALL_OUT, "new onboarding starts with a directive that must change to defense")
	game.onboarding_name_input.text = "튜토리얼마왕"
	game._onboarding_confirm_name()
	_expect(game.onboarding_dialogue_queue.size() == 4, "new game keeps only four essential opening lines")
	var opening_line_ids: Array = []
	for entry in game.onboarding_dialogue_queue:
		opening_line_ids.append(str(entry.get("id", "")))
	_expect(opening_line_ids == ["D_OP_PLAYER_001", "D_OP_BATI_001", "D_OP_BATI_002", "D_OP_BATI_003"], "essential opening lines keep their intended order")
	await _drain_dialogue(game)
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "opening reaches management with tutorial gate on")
	_expect(game.tutorial_manager.current_step_id() == "TUT_030_SELECT_SLIME", "first management step asks for slime selection")
	_expect(game.onboarding_seen_dialogue_ids.has("D01_PRE_BATI_001"), "DAY 01 keeps one immediate management intro")
	_expect(not game.onboarding_seen_dialogue_ids.has("D01_PRE_PLAYER_001") and not game.onboarding_seen_dialogue_ids.has("D01_PRE_BATI_002"), "DAY 01 defers optional management banter")

	game._start_combat()
	await get_tree().process_frame
	_expect(game.current_screen != Constants.SCREEN_COMBAT, "combat start is blocked before required management tutorial steps")

	game._select_monster("slime")
	await _drain_dialogue(game)
	_expect(game.current_screen == Constants.SCREEN_MONSTER, "slime introduction stays nonblocking")
	_expect(game.tutorial_manager.current_step_id() == "TUT_040_DEPLOY_SLIME", "selecting slime completes unit_selected step")
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	game._assign_monster_to_room("slime", "entrance")
	await get_tree().process_frame
	_expect(game.tutorial_manager.current_step_id() == "TUT_050_GLOBAL_DEFEND", "deploying slime to entrance completes deployment step")

	game._set_global_directive(Constants.DIRECTIVE_DEFENSE)
	await _drain_dialogue(game)
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "global directive feedback stays nonblocking")
	_expect(game.tutorial_manager.current_step_id() == "TUT_060_ROOM_BLOCK", "defense directive completes global directive step")
	game.selected_room = "entrance"
	game._set_room_directive(Constants.ROOM_DIRECTIVE_ENTRY_BLOCK)
	await _drain_dialogue(game)
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "room directive feedback stays nonblocking")
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
	var locked_growth_button = _find_button_by_text(game.ui_layer, "성장 선택 필요")
	_expect(locked_growth_button != null and locked_growth_button.disabled, "DAY 01 result requires a focused growth choice before review")
	var focus_button = _find_button_by_text(game.ui_layer, "집중 +8")
	_expect(focus_button != null and not focus_button.disabled, "DAY 01 result exposes focused growth choice")
	_expect(game._choose_result_growth("slime"), "DAY 01 focused growth choice applies")
	await get_tree().process_frame
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
	await get_tree().process_frame
	_expect(game.current_screen == Constants.SCREEN_MONSTER, "DAY 02 combat requests the first tactical specialization")
	_expect(game._choose_early_specialization("goblin", "goblin_treasure_hunter"), "DAY 02 tutorial chooses goblin tactical specialization")
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	game._start_combat()
	await get_tree().physics_frame
	var goblin = _unit_by_id(game.monster_units, "goblin")
	game._spawn_enemy("thief")
	var thief = _unit_by_id(game.enemy_units, "thief")
	_expect(goblin != null and thief != null, "DAY 02 creates goblin and thief for the chase tutorial")
	if goblin != null and thief != null:
		goblin.global_position = game.graph.center("barracks")
		goblin.current_room = "barracks"
		goblin.stop_navigation()
		thief.global_position = game.graph.center("entrance")
		thief.current_room = "entrance"
		thief.stop_navigation()
		game.combat_scene.update_ai_paths()
		_expect(goblin.goal_room == "entrance" and not goblin.path_points.is_empty(), "goblin thief-hunter specialization creates a real chase path")
		thief.global_position = goblin.global_position + Vector2(20, 0)
		thief.current_room = "barracks"
		goblin.attack_cooldown = 0.0
		game.combat_scene.update_attacks(0.0)
	await get_tree().process_frame
	_expect(game.tutorial_manager.current_step_id() == "TUT_210_RECOVERY_NEST", "a real goblin attack completes the DAY 02 combat step")
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
	if imp != null and not game.enemy_units.is_empty():
		var fireball_target = game.enemy_units[game.enemy_units.size() - 1]
		fireball_target.global_position = imp.global_position + Vector2(24, 0)
		fireball_target.current_room = imp.current_room
		fireball_target.set_physics_process(false)
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
