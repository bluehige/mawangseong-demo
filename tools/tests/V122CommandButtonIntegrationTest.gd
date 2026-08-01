extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const CommandService = preload("res://scripts/v122/combat/V122CommandService.gd")
const DamageService = preload("res://scripts/combat/DamageService.gd")

var failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = GameRootScene.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame
	game._debug_skip_onboarding()
	GameState.day = 2
	game._choose_early_specialization("goblin", "goblin_treasure_hunter")
	game._set_global_directive(Constants.DIRECTIVE_ALL_OUT)
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	game._start_combat()
	await get_tree().physics_frame
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "integration fixture enters combat")
	var directive_before: String = str(game.global_directive)
	var points_before := int(game.get_meta("v122_command_state", {}).get("points", -1))
	var rally_button := _find_button_prefix(game.ui_layer, "집결")
	_expect(rally_button != null and not rally_button.disabled, "live command bar exposes an enabled rally button")
	if rally_button != null:
		rally_button.pressed.emit()
	await get_tree().process_frame
	_expect(game.combat_scene.pending_v122_command_id == "rally", "rally button arms direct battlefield targeting")
	_expect(game.ui_layer.find_child("CombatContextDrawer", true, false) == null, "direct targeting does not open a context drawer")
	_expect(_find_button_exact(game.ui_layer, "대상 확정") == null, "direct targeting does not expose a redundant confirmation button")
	var rally_candidates: Array = game.combat_scene.command_targeting_state().get("candidates", [])
	var runtime_plan: Dictionary = game.get_meta("v122_battle_plan", {})
	_expect(
		not runtime_plan.get("defense_zones", []).is_empty()
		or not runtime_plan.get("defense_segments", []).is_empty(),
		"integration fixture exposes typed defense zones"
	)
	_expect(not _candidate_type_exists(rally_candidates, "room"), "rally no longer exposes raw rooms as command targets")
	var rally_target := _candidate_with_runtime_anchor(rally_candidates, game.rooms)
	_expect(not rally_target.is_empty(), "current battle plan exposes a typed rally zone with a valid world anchor")
	var rally_target_id := str(rally_target.get("id", ""))
	var rally_room_id := str(rally_target.get("anchor_room_id", ""))
	if not rally_target.is_empty():
		game._handle_left_click(game.graph.center(rally_room_id))
	await get_tree().process_frame
	var command_state: Dictionary = game.get_meta("v122_command_state", {})
	_expect(command_state.get("active_commands", {}).has("rally"), "clicking the highlighted room activates rally immediately")
	var active_rally_target: Dictionary = command_state.get("active_commands", {}).get("rally", {}).get("target", {})
	_expect(str(active_rally_target.get("type", "")) == "defense_zone", "rally records a typed defense-zone target")
	_expect(str(active_rally_target.get("id", "")) == rally_target_id, "rally preserves the clicked defense-zone ID")
	_expect(int(command_state.get("points", -1)) == points_before - 1, "the direct room click consumes exactly the rally command point cost")
	_expect(game.combat_scene.pending_v122_command_id == "", "successful direct click exits targeting mode")
	_expect(game.global_directive == directive_before, "rally does not overwrite the persistent global directive")
	var goblin := _unit_by_id(game.monster_units, "goblin")
	_expect(goblin != null, "combat creates the goblin fixture")
	if goblin != null:
		goblin.current_room = "barracks"
		goblin.global_position = game.graph.center("barracks")
		goblin.stop_navigation()
		game.combat_scene.update_monster_path(goblin)
		_expect(goblin.goal_room == rally_room_id, "direct rally changes the goblin's actual navigation goal")
		_expect(goblin.intent_text == "집결 명령", "direct rally exposes its actual AI state on the unit")

	game.combat_scene.spawn_enemy("explorer")
	await get_tree().process_frame
	var explorers := _alive_units_by_id(game.enemy_units, "explorer")
	_expect(explorers.size() >= 2, "focus fixture contains duplicate enemies of the same type")
	var focus_button := _find_button_prefix(game.ui_layer, "집중")
	_expect(focus_button != null and not focus_button.disabled, "focus command remains available after rally")
	if focus_button != null:
		focus_button.pressed.emit()
	await get_tree().process_frame
	var focus_candidates: Array = game.combat_scene.command_targeting_state().get("candidates", [])
	_expect(_candidate_ids_are_unique(focus_candidates, "enemy"), "focus candidates preserve each live enemy instance instead of merging by species")
	var points_before_invalid := int(game.get_meta("v122_command_state", {}).get("points", -1))
	game._handle_left_click(Vector2(-1000, -1000))
	_expect(game.combat_scene.pending_v122_command_id == "focus", "an invalid battlefield click keeps focus targeting armed")
	_expect(int(game.get_meta("v122_command_state", {}).get("points", -1)) == points_before_invalid, "an invalid battlefield click does not consume command points")
	if explorers.size() >= 2:
		var chosen_enemy = explorers[1]
		game._handle_left_click(chosen_enemy.global_position)
		await get_tree().process_frame
		command_state = game.get_meta("v122_command_state", {})
		var focus_target_id := str(command_state.get("active_commands", {}).get("focus", {}).get("target", {}).get("id", ""))
		_expect(focus_target_id == str(chosen_enemy.get_instance_id()), "focus records the exact clicked enemy instance")
		_expect(game.combat_scene._v122_focus_target() == chosen_enemy, "monster AI resolves focus to the exact clicked enemy instance")
		if goblin != null:
			command_state["active_commands"].erase("rally")
			game.set_meta("v122_command_state", command_state)
			var nearby_enemy = explorers[0]
			var combat_center: Vector2 = game.graph.center("barracks")
			for unit in [goblin, nearby_enemy, chosen_enemy]:
				unit.set_physics_process(false)
				unit.current_room = "barracks"
			goblin.global_position = combat_center
			nearby_enemy.global_position = combat_center + Vector2(14.0, 0.0)
			chosen_enemy.global_position = combat_center + Vector2(minf(38.0, float(goblin.attack_range) - 4.0), 0.0)
			goblin.attack_cooldown = 0.0
			goblin.skill_cooldowns = {"quick_slash": 99.0, "loot_instinct": 99.0}
			var nearby_hp_before := int(nearby_enemy.hp)
			var focus_hp_before := int(chosen_enemy.hp)
			game.combat_scene.try_attack(goblin, [nearby_enemy, chosen_enemy])
			_expect(chosen_enemy.hp < focus_hp_before and nearby_enemy.hp == nearby_hp_before, "focus redirects the live basic attack away from a closer enemy")

			nearby_enemy.hp = nearby_enemy.max_hp
			chosen_enemy.hp = chosen_enemy.max_hp
			goblin.skill_cooldowns["quick_slash"] = 0.0
			GameState.mana = 100
			nearby_hp_before = int(nearby_enemy.hp)
			focus_hp_before = int(chosen_enemy.hp)
			var slash_multiplier: float = 1.9 + game.combat_scene._combat_skill_float(str(goblin.unit_id), "quick_slash", "damage_multiplier_bonus", 0.0)
			var slash_damage_without_focus: int = DamageService.compute(goblin, chosen_enemy, slash_multiplier)
			_expect(game.combat_scene.use_unit_skill_for_ai(goblin, 0), "focused goblin can use quick slash when the selected enemy is in range")
			_expect(chosen_enemy.hp < focus_hp_before and nearby_enemy.hp == nearby_hp_before, "focus redirects quick slash away from a closer enemy")
			_expect(focus_hp_before - int(chosen_enemy.hp) > slash_damage_without_focus, "focus damage amplification also applies to quick slash")

			nearby_enemy.hp = nearby_enemy.max_hp
			chosen_enemy.hp = chosen_enemy.max_hp
			nearby_enemy.global_position = combat_center + Vector2(14.0, 0.0)
			chosen_enemy.global_position = combat_center + Vector2(float(goblin.attack_range) + 70.0, 0.0)
			goblin.attack_cooldown = 0.0
			goblin.skill_cooldowns = {"quick_slash": 99.0, "loot_instinct": 99.0}
			goblin.stop_navigation()
			game.combat_scene.update_monster_path(goblin)
			var focus_path_before: Array = goblin.path_points.duplicate()
			nearby_hp_before = int(nearby_enemy.hp)
			focus_hp_before = int(chosen_enemy.hp)
			game.combat_scene.try_attack(goblin, [nearby_enemy, chosen_enemy])
			_expect(goblin.intent_text == "집중 공격" and not focus_path_before.is_empty(), "focus makes the defender move toward an out-of-range selected enemy")
			_expect(nearby_enemy.hp == nearby_hp_before and chosen_enemy.hp == focus_hp_before, "focus pursuit does not fire at an unrelated closer enemy")
			_expect(goblin.path_points == focus_path_before, "an unrelated nearby enemy does not cancel the focus pursuit path")

	_refill_commands(game)
	var facility_button := _find_button_prefix(game.ui_layer, "시설 발동")
	_expect(facility_button != null and not facility_button.disabled, "facility command is available in the direct command bar")
	if facility_button != null:
		facility_button.pressed.emit()
	await get_tree().process_frame
	var facility_candidates: Array = game.combat_scene.command_targeting_state().get("candidates", [])
	_expect(not facility_candidates.is_empty(), "facility command exposes active facilities as world targets")
	if not facility_candidates.is_empty():
		var facility_target: Dictionary = facility_candidates.front()
		var facility_slot_id := str(facility_target.get("id", ""))
		var facility_room_id := str(facility_target.get("room_id", ""))
		_expect(facility_slot_id != "" and facility_slot_id == str(facility_target.get("facility_slot_id", "")), "facility target ID is the stable slot ID")
		_expect(facility_room_id != "" and facility_room_id != facility_slot_id, "facility target keeps its room ID as separate spatial data")
		game._handle_left_click(game.graph.center(facility_room_id))
		await get_tree().process_frame
		command_state = game.get_meta("v122_command_state", {})
		var active_facility_target: Dictionary = command_state.get("active_commands", {}).get("activate_facility", {}).get("target", {})
		_expect(
			str(active_facility_target.get("id", "")) == facility_slot_id
			and str(active_facility_target.get("room_id", "")) == facility_room_id,
			"clicking a highlighted facility activates the command immediately"
		)

	_refill_commands(game)
	var fallback_button := _find_button_prefix(game.ui_layer, "비상 후퇴")
	_expect(fallback_button != null and not fallback_button.disabled, "fallback command is available in the direct command bar")
	if fallback_button != null:
		fallback_button.pressed.emit()
	await get_tree().process_frame
	var fallback_candidates: Array = game.combat_scene.command_targeting_state().get("candidates", [])
	_expect(not fallback_candidates.is_empty(), "fallback command exposes defense zones")
	_expect(not _candidate_type_exists(fallback_candidates, "room"), "fallback no longer exposes raw rooms as command targets")
	var fallback_target := _candidate_with_runtime_anchor(fallback_candidates, game.rooms)
	_expect(not fallback_target.is_empty(), "fallback exposes at least one defense zone with a valid runtime anchor")
	if not fallback_target.is_empty():
		var fallback_target_id := str(fallback_target.get("id", ""))
		var fallback_room_id := str(fallback_target.get("anchor_room_id", ""))
		game._handle_left_click(game.graph.center(fallback_room_id))
		await get_tree().process_frame
		command_state = game.get_meta("v122_command_state", {})
		var active_fallback_target: Dictionary = command_state.get("active_commands", {}).get("emergency_fallback", {}).get("target", {})
		_expect(
			str(active_fallback_target.get("type", "")) == "defense_zone"
			and str(active_fallback_target.get("id", "")) == fallback_target_id,
			"clicking a highlighted defense zone activates fallback immediately"
		)

	_refill_commands(game)
	var points_before_cancel := int(game.get_meta("v122_command_state", {}).get("points", -1))
	game._issue_v122_command("rally")
	var cancel_event := InputEventMouseButton.new()
	cancel_event.button_index = MOUSE_BUTTON_RIGHT
	cancel_event.pressed = true
	cancel_event.position = Vector2(960, 540)
	game._input(cancel_event)
	_expect(game.combat_scene.pending_v122_command_id == "", "right click cancels an armed command")
	_expect(int(game.get_meta("v122_command_state", {}).get("points", -1)) == points_before_cancel, "cancelling an armed command does not consume points")

	if goblin != null:
		game._handle_left_click(goblin.global_position)
		await get_tree().process_frame
		var ally_inspector: Node = game.ui_layer.find_child("CombatUnitInspector", true, false)
		_expect(ally_inspector != null and _tree_text(ally_inspector).contains("아군 정보"), "clicking a monster opens the compact ally inspector")
		_expect(not _tree_text(ally_inspector).contains("시설"), "the unit inspector does not mix building information into combat detail")
	if not explorers.is_empty() and is_instance_valid(explorers[0]):
		game._handle_left_click(explorers[0].global_position)
		await get_tree().process_frame
		var enemy_inspector: Node = game.ui_layer.find_child("CombatUnitInspector", true, false)
		_expect(enemy_inspector != null and _tree_text(enemy_inspector).contains("적 정보"), "clicking an enemy opens the compact enemy inspector")
	game.queue_free()
	await get_tree().process_frame
	print("V122_COMMAND_BUTTON_INTEGRATION_TEST: %s" % ("FAIL" if failed else "PASS"))
	get_tree().quit(1 if failed else 0)


func _find_button_prefix(node: Node, prefix: String) -> Button:
	if node is Button and str(node.text).begins_with(prefix):
		return node
	for child in node.get_children():
		var result := _find_button_prefix(child, prefix)
		if result != null:
			return result
	return null


func _find_button_exact(node: Node, text: String) -> Button:
	if node is Button and str(node.text) == text:
		return node
	for child in node.get_children():
		var result := _find_button_exact(child, text)
		if result != null:
			return result
	return null


func _unit_by_id(units: Array, unit_id: String) -> Node:
	for unit in units:
		if str(unit.unit_id) == unit_id:
			return unit
	return null


func _alive_units_by_id(units: Array, unit_id: String) -> Array:
	var result: Array = []
	for unit in units:
		if is_instance_valid(unit) and unit.is_alive() and str(unit.unit_id) == unit_id:
			result.append(unit)
	return result


func _refill_commands(game: Node) -> void:
	game.set_meta("v122_command_state", CommandService.new_state(8, 8, 12.0))
	game.combat_scene.cancel_v122_command_targeting()


func _candidate_type_exists(candidates: Array, target_type: String) -> bool:
	for candidate_value in candidates:
		if candidate_value is Dictionary and str(candidate_value.get("type", "")) == target_type:
			return true
	return false


func _candidate_for_room(candidates: Array, target_type: String, room_id: String) -> Dictionary:
	for candidate_value in candidates:
		if not candidate_value is Dictionary or str(candidate_value.get("type", "")) != target_type:
			continue
		var candidate: Dictionary = candidate_value
		if str(candidate.get("anchor_room_id", "")) == room_id or candidate.get("room_ids", []).has(room_id):
			return candidate
	return {}


func _candidate_with_runtime_anchor(candidates: Array, rooms: Dictionary) -> Dictionary:
	for candidate_value in candidates:
		if not candidate_value is Dictionary or str(candidate_value.get("type", "")) != "defense_zone":
			continue
		var candidate: Dictionary = candidate_value
		if rooms.has(str(candidate.get("anchor_room_id", ""))):
			return candidate
	return {}


func _candidate_ids_are_unique(candidates: Array, target_type: String) -> bool:
	var seen: Dictionary = {}
	var count := 0
	for candidate_value in candidates:
		if not candidate_value is Dictionary or str(candidate_value.get("type", "")) != target_type:
			continue
		count += 1
		var target_id := str(candidate_value.get("id", ""))
		if target_id == "" or seen.has(target_id):
			return false
		seen[target_id] = true
	return count >= 2


func _tree_text(node: Node) -> String:
	if node == null:
		return ""
	var parts: Array[String] = []
	if node is Label or node is Button:
		parts.append(str(node.text))
	elif node is RichTextLabel:
		parts.append(str(node.text))
	for child in node.get_children():
		parts.append(_tree_text(child))
	return "\n".join(parts)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	failed = true
	push_error("FAIL: %s" % message)
