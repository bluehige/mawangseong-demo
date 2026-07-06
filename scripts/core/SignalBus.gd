extends Node

signal log_added(message: String)
signal room_selected(room_id: String)
signal unit_selected(unit: Node)
signal resources_changed
signal screen_changed(screen_name: String)
signal battle_finished(summary: Dictionary)
signal tutorial_action(action_id: String, payload: Dictionary)

func emit_log(message: String) -> void:
	log_added.emit(message)

func emit_tutorial_action(action_id: String, payload: Dictionary = {}) -> void:
	tutorial_action.emit(action_id, payload)

