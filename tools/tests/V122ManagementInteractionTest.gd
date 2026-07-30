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
	game._debug_skip_onboarding()
	GameState.day = 2
	game._choose_early_specialization("goblin", "goblin_treasure_hunter")
	game.management_context_drawer_open = false
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await get_tree().process_frame
	var resource_rail := game.ui_layer.find_child("ResourceStatusRail", true, false) as Control
	var start_combat_button := game.ui_layer.find_child("StartCombatButton", true, false) as Button
	var context_button := game.ui_layer.find_child("OpenManagementContextButton", true, false) as Button
	var undo_button := game.ui_layer.find_child("PlacementUndoButton", true, false) as Button
	_expect(resource_rail != null, "desktop resources render as one shared status rail")
	_expect(start_combat_button != null and str(start_combat_button.get_meta("ui_button_grade", "")) == "primary", "defense start is the management primary action")
	_expect(context_button != null and str(context_button.get_meta("ui_button_grade", "")) == "tactical", "management context uses the tactical grade")
	_expect(undo_button != null and str(undo_button.get_meta("ui_button_grade", "")) == "utility", "undo uses the utility grade")
	_expect(_count_button_grade(game.ui_layer, "primary") == 1, "management exposes one visual primary action")
	var slime_card := game.ui_layer.find_child("MonsterCard_slime", true, false) as Button
	_expect(slime_card != null and slime_card.icon != null, "live roster renders the slime as an image card")
	_expect(game.ui_layer.find_child("MonsterRosterScroll", true, false) is ScrollContainer, "live roster is horizontally scrollable")
	_expect(game.ui_layer.find_child("FacilityCard_watch_post", true, false) == null, "management does not expose every facility as a global rail button")
	if slime_card != null:
		slime_card.button_down.emit()
	_expect(game.roster_monster_drag_active and game.dragging_monster_id == "slime", "roster image button starts the real drag state")
	var target_room := "recovery"
	game._update_management_monster_drag(game.graph.center(target_room))
	game._finish_management_monster_drag(game.graph.center(target_room))
	await get_tree().process_frame
	_expect(str(game.monster_roster.get("slime", {}).get("room", "")) == target_room, "dropping the roster image on a room changes the actual deployment")

	var facility_room := "slot_01" if game.rooms.has("slot_01") else str(game._first_changeable_room())
	game.management_context_drawer_open = true
	game._select_room(facility_room)
	await _settle_ui()
	var facility_scroll := game.ui_layer.find_child("ContextualFacilityScroll", true, false) as ScrollContainer
	var watch_button := game.ui_layer.find_child("ContextFacility_watch_post", true, false) as Button
	_expect(facility_scroll != null and watch_button != null, "selecting a room immediately opens its scrollable facility replacement list")
	if watch_button != null:
		watch_button.pressed.emit()
	await _settle_ui()
	var confirm := game.ui_layer.find_child("ConfirmFacilityReplacementButton", true, false) as Button
	_expect(confirm != null and game.build_preview_room_id == facility_room, "facility choice creates a preview on the selected room")
	if confirm != null:
		confirm.pressed.emit()
	await _settle_ui()
	_expect(str(game.rooms.get(facility_room, {}).get("facility_role", "")) == "watch_post", "contextual facility confirmation changes the actual room facility")

	game._open_settings_screen()
	await _settle_ui()
	var apply_settings := game.ui_layer.find_child("ApplySettingsButton", true, false) as Button
	var cancel_settings := game.ui_layer.find_child("CancelSettingsButton", true, false) as Button
	var display_category := game.ui_layer.find_child("SettingsCategory_display", true, false) as Button
	var layout_option := game.ui_layer.find_child("LayoutModeOption", true, false) as OptionButton
	_expect(apply_settings != null and str(apply_settings.get_meta("ui_button_grade", "")) == "primary", "settings Apply is the primary action")
	_expect(cancel_settings != null and str(cancel_settings.get_meta("ui_button_grade", "")) == "utility", "settings Cancel uses the utility grade")
	_expect(display_category != null and str(display_category.get_meta("ui_semantic_state", "")) == "selected", "active settings category uses the selected state")
	_expect(layout_option != null and str(layout_option.get_meta("ui_button_grade", "")) == "tactical", "layout selector uses the tactical grade")
	_expect(_count_button_grade(game.ui_layer, "primary") == 1, "settings exposes one visual primary action")
	game.queue_free()
	await get_tree().process_frame
	print("V122_MANAGEMENT_INTERACTION_TEST: %s" % ("FAIL" if failed else "PASS"))
	get_tree().quit(1 if failed else 0)


func _settle_ui() -> void:
	for _index in range(3):
		await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	failed = true
	push_error("FAIL: %s" % message)


func _count_button_grade(parent: Node, grade: String) -> int:
	var count := 0
	for child in parent.find_children("*", "BaseButton", true, false):
		if child is BaseButton and str(child.get_meta("ui_button_grade", "")) == grade:
			count += 1
	return count
