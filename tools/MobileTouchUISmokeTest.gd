extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const CampaignSaveStoreScript = preload("res://scripts/core/CampaignSaveStore.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const TEST_SAVE_PATH := "user://mobile_touch_ui_smoke_save.json"
const COMMAND_BUTTON_COUNT := 4

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	CampaignSaveStoreScript.delete(TEST_SAVE_PATH)
	_expect(UISettings.is_touch_ui(), "mobile argument enables the touch layout")
	var game = GameRootScene.instantiate()
	add_child(game)
	await _settle(2)
	game._set_campaign_save_path_for_tests(TEST_SAVE_PATH)

	var new_game_button := _find_button_by_text(game.ui_layer, "새 게임")
	_expect(new_game_button != null and new_game_button.size.y >= 120.0, "title exposes one large new-game touch target")
	_expect(new_game_button != null and new_game_button.get_theme_font_size("font_size") >= 40, "title button uses a readable mobile font")
	var title_subtitle := _find_label_by_text(game.ui_layer, "F급 신입 마왕성 방어 튜토리얼")
	_expect(title_subtitle != null and title_subtitle.get_theme_font_size("font_size") >= 40, "mobile title copy receives the larger readability scale")

	game._onboarding_start_new_game()
	await get_tree().process_frame
	_expect(game.global_directive == Constants.DIRECTIVE_DEFENSE, "touch onboarding keeps the global directive on defense")
	var name_tip_button := _find_button_by_text(game.ui_layer, "확인하고 이름 선택")
	_expect(name_tip_button != null and name_tip_button.size.y >= 120.0, "name guidance uses a large confirmation target")
	game._onboarding_dismiss_name_entry_tip()
	await get_tree().process_frame
	_expect(game.onboarding_name_input != null and game.onboarding_name_input.size.y >= 120.0, "name input is large enough for touch")
	_expect(not game.onboarding_name_input.has_focus(), "name screen does not reopen the mobile keyboard automatically")
	var random_name_button := _find_button_by_text(game.ui_layer, "무작위 이름")
	_expect(random_name_button != null and random_name_button.size.y >= 120.0, "name screen provides a keyboard-free random-name choice")
	game.onboarding_name_input.grab_focus()
	game.onboarding_name_input.text = "모바일마왕"
	game._onboarding_confirm_name()
	_expect(not game.onboarding_name_input.has_focus(), "confirming a name releases keyboard focus")
	await get_tree().process_frame
	await _drain_dialogue(game)

	_expect(game.current_screen == Constants.SCREEN_INTRUSION_BRIEF, "opening reaches the intrusion brief before placement")
	var intrusion_brief := game.ui_layer.find_child("IntrusionBriefScreen", true, false) as Control
	_expect(intrusion_brief != null, "intrusion brief is a named touch screen")
	var enter_placement_button := _find_button_by_text(intrusion_brief, "배치 시작") if intrusion_brief != null else null
	_expect(enter_placement_button != null and enter_placement_button.size.y >= 120.0, "intrusion brief exposes a large placement action")
	if enter_placement_button != null:
		enter_placement_button.pressed.emit()
	await get_tree().process_frame

	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "intrusion brief proceeds to placement management")
	var monster_roster_scroll := game.ui_layer.find_child("MonsterRosterScroll", true, false) as ScrollContainer
	var primary_bar := game.ui_layer.find_child("ManagementPrimaryBar", true, false) as Control
	_expect(monster_roster_scroll != null, "management exposes a scrollable image monster roster")
	_expect(primary_bar != null, "management keeps one primary action bar")
	_expect(game.ui_layer.find_child("MobileManagementDirectiveBar", true, false) == null, "obsolete mobile directive bar is not composed")
	var monster_card := game.ui_layer.find_child("MonsterCard_slime", true, false) as Button
	var facility_card := game.ui_layer.find_child("FacilityCard_barracks", true, false) as Button
	_expect(monster_card != null and monster_card.size.y >= 120.0, "monster placement card has a full touch target")
	_expect(facility_card == null, "facility choices are not duplicated in the global monster roster")
	var context_button := _find_button_by_text(primary_bar, "전술 · 상세") if primary_bar != null else null
	var start_button := _find_button_by_text(primary_bar, "방어 시작") if primary_bar != null else null
	_expect(context_button != null and context_button.size.y >= 120.0, "management context drawer has one large entry action")
	_expect(start_button != null and start_button.size.y >= 120.0, "defense start remains a large primary action")

	if context_button != null:
		context_button.pressed.emit()
	await get_tree().process_frame
	_expect(_count_named(game.ui_layer, "ManagementContextDrawer") == 1, "management opens exactly one context drawer")
	_expect(game._management_ui_at(Vector2(900, 140)), "management touch hit-test blocks the live drawer area")
	_expect(game._management_ui_at(Vector2(120, 600)), "management touch hit-test blocks the live monster roster")
	var management_drawer := game.ui_layer.find_child("ManagementContextDrawer", true, false) as Control
	var tutorial_overlay := game.ui_layer.find_child("TutorialOverlay", true, false) as Control
	var tutorial_message := tutorial_overlay.find_child("TutorialMessagePanel", true, false) as Control if tutorial_overlay != null else null
	_expect(tutorial_overlay != null and management_drawer != null and tutorial_overlay.z_index > management_drawer.z_index, "touch tutorial renders above the management drawer")
	_expect(tutorial_message != null and management_drawer != null and not tutorial_message.get_global_rect().intersects(management_drawer.get_global_rect()), "touch tutorial task card stays clear of the management drawer")
	var global_directive_button := _find_global_directive_button(management_drawer)
	_expect(global_directive_button != null, "touch management drawer exposes the global directive control")
	if global_directive_button != null:
		_expect(
			str(global_directive_button.get_item_metadata(global_directive_button.selected)) == Constants.DIRECTIVE_DEFENSE,
			"touch management keeps defense selected"
		)
		_expect(
			global_directive_button.get_item_text(global_directive_button.selected).begins_with("사수"),
			"touch management displays the selected defense directive as a descriptive 사수 option"
		)
	var management_room_directive := game.ui_layer.find_child("SelectedRoomDirectiveOption", true, false) as OptionButton
	var management_drawer_close := _find_button_by_text(management_drawer, "닫기")
	_expect(management_room_directive != null and management_room_directive.size.y >= 96.0, "management drawer controls are touch-sized")
	_expect(management_drawer_close != null and management_drawer_close.size.y >= 100.0, "management drawer has a large close action")
	_expect(game.ui_layer.find_child("ContextualFacilityScroll", true, false) == null, "facility choices stay hidden until a room is selected")
	game._close_management_context_drawer()
	await get_tree().process_frame
	var first_touch_instruction: String = game._onboarding_line_text(game.tutorial_manager.current_step())
	_expect(first_touch_instruction.contains("탭") and not first_touch_instruction.contains("클릭"), "mobile tutorial consistently uses touch wording")

	# The opening path above verifies touch onboarding. Disable only the tutorial
	# action gate so the remaining smoke can exercise unrestricted production UI.
	game.tutorial_gate_enabled = false
	game.tutorial_manager.active = false
	game._clear_management_action_mode(false)
	var changeable_room := str(game._first_changeable_room())
	_expect(changeable_room != "" and game._can_change_room_facility(changeable_room), "touch fixture has a replaceable room")
	_expect(
		game.current_screen == Constants.SCREEN_MANAGEMENT
		and not game.map_editor_active
		and not game.build_pick_mode
		and game.deploy_pick_monster_id == "",
		"touch fixture is clear of other management action modes"
	)
	game._select_room(changeable_room)
	_expect(game.selected_room == changeable_room, "selecting a replaceable room updates the selected room")
	_expect(game.facility_change_panel_open, "selecting a replaceable room opens its contextual facility state")
	game._open_management_context_drawer()
	await get_tree().process_frame
	var contextual_facility_scroll := game.ui_layer.find_child("ContextualFacilityScroll", true, false) as ScrollContainer
	_expect(contextual_facility_scroll != null, "facility replacement appears inside the selected-room context")
	game._close_management_context_drawer()
	await get_tree().process_frame

	game._open_map_editor()
	await get_tree().process_frame
	var map_editor_workspace := game.ui_layer.find_child("MapEditorWorkspace", true, false) as Control
	var map_save_button := _find_button_by_text(map_editor_workspace, "저장") if map_editor_workspace != null else null
	var map_cancel_button := _find_button_by_text(map_editor_workspace, "취소") if map_editor_workspace != null else null
	_expect(map_editor_workspace != null, "map editing remains a separate named workspace")
	_expect(map_save_button != null and map_save_button.size.y >= 120.0, "map editor save is touch-sized")
	_expect(map_cancel_button != null and map_cancel_button.size.y >= 120.0, "map editor cancel is touch-sized")
	_expect(game._management_ui_at(Vector2(100, 900)), "map editor touch hit-test blocks its live workspace")
	if map_cancel_button != null:
		map_cancel_button.pressed.emit()
	await get_tree().process_frame
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "map editor cancel returns to placement without applying changes")

	game._request_combat_start()
	_expect(game.current_screen == Constants.SCREEN_DEFENSE_START, "defense request opens the three-second start screen")
	_expect(not game.pending_precombat_snapshot.is_empty(), "start screen freezes the real precombat snapshot")
	var frozen_snapshot: Dictionary = game.pending_precombat_snapshot.duplicate(true)
	var countdown_label := game.ui_layer.find_child("DefenseStartCountdownLabel", true, false) as Label
	var cancel_button := _find_button_by_text(game.ui_layer, "취소")
	_expect(countdown_label != null and countdown_label.text == "3", "touch countdown starts at three seconds")
	_expect(cancel_button != null and cancel_button.size.y >= 120.0, "countdown cancel is a large touch target")
	game._tick_defense_start_countdown(2.9)
	_expect(game.current_screen == Constants.SCREEN_DEFENSE_START, "countdown does not commit before three seconds")
	_expect(game.pending_precombat_snapshot == frozen_snapshot, "countdown keeps the frozen placement and intrusion snapshot")
	game._tick_defense_start_countdown(0.1)
	if game.current_screen != Constants.SCREEN_COMBAT:
		game._tick_defense_start_countdown(0.01)
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "three-second countdown commits into combat")

	var command_bar := game.ui_layer.find_child("CombatCommandBar", true, false) as Control
	var speed_panel := game.ui_layer.find_child("CombatSpeedPanel", true, false) as Control
	_expect(command_bar != null, "touch combat uses the stripped CombatCommandBar")
	_expect(game.ui_layer.find_child("MobileCombatBar", true, false) == null, "obsolete MobileCombatBar is not composed")
	var command_buttons := _direct_buttons(command_bar)
	_expect(command_buttons.size() == COMMAND_BUTTON_COUNT, "touch combat exposes exactly four command actions")
	_expect(command_buttons.all(func(control): return control.size.y >= 120.0), "all four combat commands have full touch targets")
	_expect(game.ui_layer.find_child("DirectControlButton", true, false) == null and _find_button_by_text(game.ui_layer, "직접 조종") == null, "touch combat has no direct unit controls")
	_expect(game.ui_layer.find_child("CombatThroneStatus", true, false) != null, "touch combat keeps throne status")
	_expect(game.ui_layer.find_child("CombatThreat", true, false) != null, "touch combat keeps the active threat")
	_expect(speed_panel != null and speed_panel.size.x <= command_bar.size.x * 0.2, "speed and pause stay compact beside commands")
	var speed_button := _find_button_by_text(speed_panel, "x3") if speed_panel != null else null
	var pause_button := _find_button_by_text(speed_panel, "일시정지") if speed_panel != null else null
	_expect(speed_button != null and speed_button.size.y >= 120.0 and speed_button.disabled, "tutorial combat exposes a large locked x3 control")
	_expect(pause_button != null and pause_button.size.y >= 120.0, "pause remains a large touch control")

	var command_button := _first_enabled_button(command_buttons)
	_expect(command_button != null, "at least one touch command is currently actionable")
	if command_button != null:
		command_button.pressed.emit()
	await get_tree().process_frame
	var combat_drawer := game.ui_layer.find_child("CombatContextDrawer", true, false) as Control
	_expect(_count_named(game.ui_layer, "CombatContextDrawer") == 1, "command targeting opens exactly one combat context drawer")
	_expect(game._combat_ui_at(Vector2(900, 140)), "combat touch hit-test blocks the live drawer area")
	_expect(game._combat_ui_at(Vector2(120, 840)), "combat touch hit-test blocks the live command bar")
	_expect(game.combat_scene.pending_v122_command_id != "", "command tap enters explicit target selection")
	_expect(game.combat_scene.pending_v122_command_target.is_empty(), "command tap does not infer a target")
	var confirm_button := _find_button_by_text(combat_drawer, "대상 확정") if combat_drawer != null else null
	_expect(confirm_button != null and confirm_button.disabled, "target confirmation stays disabled before an explicit selection")
	var candidates: Array = game.combat_scene.command_targeting_state().get("candidates", [])
	if not candidates.is_empty():
		var candidate: Dictionary = candidates.front()
		var candidate_button := _find_button_by_text(combat_drawer, str(candidate.get("label", "")))
		_expect(candidate_button != null and candidate_button.size.y >= 96.0, "target candidates are touch-sized in the shared drawer")
		if candidate_button != null:
			candidate_button.pressed.emit()
		await get_tree().process_frame
		confirm_button = _find_button_by_text(game.ui_layer, "대상 확정")
		_expect(not game.combat_scene.pending_v122_command_target.is_empty(), "candidate tap records the explicit target")
		_expect(confirm_button != null and not confirm_button.disabled, "explicit target enables confirmation")
	else:
		_expect(false, "an actionable command provides at least one explicit target")
	game._cancel_v122_command_targeting()
	await get_tree().process_frame

	var enemy := _first_alive_enemy(game)
	if enemy == null:
		game._spawn_enemy("explorer")
		await get_tree().physics_frame
		enemy = _first_alive_enemy(game)
	if enemy != null:
		game._handle_touch_combat_tap(enemy.global_position, Vector2(-99999, -99999))
		_expect(game.selected_unit == enemy, "tapping an enemy selects information without issuing a unit command")
		_expect(not enemy.has_method("command_attack") and not enemy.has_method("command_move"), "units expose no direct attack or movement commands")
		var combat_room_directive := game.ui_layer.find_child("CombatSelectedRoomDirective", true, false) as OptionButton
		var combat_drawer_close := _find_button_by_text(game.ui_layer.find_child("CombatContextDrawer", true, false), "닫기")
		_expect(combat_room_directive != null and combat_room_directive.size.y >= 96.0, "combat detail drawer controls are touch-sized")
		_expect(combat_drawer_close != null and combat_drawer_close.size.y >= 100.0, "combat detail drawer has a large close action")
	else:
		_expect(false, "combat creates an enemy for touch targeting")

	GameState.onboarding_complete = true
	game.combat_speed_intro_seen = false
	game._set_screen(Constants.SCREEN_COMBAT)
	await get_tree().process_frame
	var speed_intro: Node = game.ui_layer.get_node_or_null("CombatSpeedFeatureIntro")
	_expect(speed_intro != null and game.combat_speed_intro_open and game.combat_paused, "first regular touch combat introduces acceleration while paused")
	speed_panel = game.ui_layer.find_child("CombatSpeedPanel", true, false) as Control
	speed_button = _find_button_by_text(speed_panel, "x3") if speed_panel != null else null
	_expect(speed_button != null and not speed_button.disabled, "x3 unlocks in the compact speed panel")
	game._dismiss_combat_speed_intro()
	if speed_button != null:
		speed_button.pressed.emit()
	_expect(game.combat_speed_intro_seen and is_equal_approx(game.combat_speed, 3.0), "touch x3 works after the introduction")

	game.result_summary = {
		"win": false,
		"reason": "mobile_touch_fixture",
		"metrics": {
			"final_breach_segment": "입구 → 병영",
			"alive_monsters": 1,
			"total_monsters": 1
		},
		"v122_ledger": {
			"final_breach_segment": "입구 → 병영",
			"facility_damage_count": 0,
			"throne_damage": 10
		}
	}
	game._set_screen(Constants.SCREEN_RESULT)
	await get_tree().process_frame
	var edit_placement_button := _find_button_by_text(game.ui_layer, "배치 수정")
	var retry_button := _find_button_by_text(game.ui_layer, "동일 배치 재도전")
	_expect(edit_placement_button != null and edit_placement_button.size.y >= 120.0, "defeat result keeps placement editing touch-sized")
	_expect(retry_button != null and retry_button.size.y >= 120.0, "defeat result keeps same-placement retry touch-sized")

	game._refresh_touch_orientation_notice(Vector2(390, 844))
	var orientation_notice := game.ui_layer.get_node_or_null("TouchPortraitOrientationNotice") as Control
	_expect(orientation_notice != null and orientation_notice.size == Vector2(1920, 1080), "portrait renders a named full-screen rotation notice")
	_expect(_find_label_by_text(orientation_notice, "화면을 가로로 돌려 주세요") != null, "portrait notice gives a clear rotation instruction")
	var blocked_portrait_touch := InputEventScreenTouch.new()
	_expect(game._touch_orientation_notice_blocks_pointer(blocked_portrait_touch), "portrait notice blocks pointer input from reaching the hidden game screen")
	game._refresh_touch_orientation_notice(Vector2(844, 390))
	_expect(game.ui_layer.get_node_or_null("TouchPortraitOrientationNotice") == null, "rotation notice clears in official landscape")
	_expect(not game._touch_orientation_notice_blocks_pointer(blocked_portrait_touch), "landscape restores normal pointer input")

	CampaignSaveStoreScript.delete(TEST_SAVE_PATH)
	game.queue_free()
	await _settle(2)
	if failed:
		print("MOBILE_TOUCH_UI_SMOKE_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("MOBILE_TOUCH_UI_SMOKE_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _drain_dialogue(game: Node, max_steps: int = 120) -> void:
	var quiet_frames := 0
	for _index in range(max_steps):
		await get_tree().process_frame
		if game.current_screen == Constants.SCREEN_DIALOGUE:
			quiet_frames = 0
			game._onboarding_advance_dialogue()
		else:
			quiet_frames += 1
			if quiet_frames >= 3:
				return
	failed = true
	push_error("Timed out while draining dialogue")


func _settle(frame_count: int) -> void:
	for _index in range(frame_count):
		await get_tree().process_frame


func _find_button_by_text(node: Node, text: String) -> Button:
	if node == null:
		return null
	if node is Button and node.text == text:
		return node
	for child in node.get_children():
		var result := _find_button_by_text(child, text)
		if result != null:
			return result
	return null


func _find_label_by_text(node: Node, text: String) -> Label:
	if node == null:
		return null
	if node is Label and node.text == text:
		return node
	for child in node.get_children():
		var result := _find_label_by_text(child, text)
		if result != null:
			return result
	return null


func _direct_buttons(node: Node) -> Array[Button]:
	var result: Array[Button] = []
	if node == null:
		return result
	for child in node.get_children():
		if child is Button:
			result.append(child)
	return result


func _first_enabled_button(buttons: Array[Button]) -> Button:
	for button in buttons:
		if not button.disabled:
			return button
	return null


func _count_named(node: Node, node_name: String) -> int:
	var result := 1 if node.name == node_name else 0
	for child in node.get_children():
		result += _count_named(child, node_name)
	return result


func _find_global_directive_button(node: Node) -> OptionButton:
	for candidate in node.find_children("*", "OptionButton", true, false):
		var option := candidate as OptionButton
		if option == null:
			continue
		var values: Array[String] = []
		for index in range(option.item_count):
			values.append(str(option.get_item_metadata(index)))
		if (
			values.has(Constants.DIRECTIVE_DEFENSE)
			and values.has(Constants.DIRECTIVE_ALL_OUT)
			and values.has(Constants.DIRECTIVE_SURVIVAL)
		):
			return option
	return null


func _first_alive_enemy(game: Node) -> Node:
	for enemy in game.enemy_units:
		if enemy.is_alive():
			return enemy
	return null


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("PASS: %s" % message)
	else:
		push_error("FAIL: %s" % message)
		failed = true
