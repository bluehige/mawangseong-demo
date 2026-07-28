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
