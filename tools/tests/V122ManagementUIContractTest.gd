extends Node

const ManagementViewModel = preload("res://scripts/v122/ui/V122ManagementViewModel.gd")

var failed := false


class ProductRootFixture:
	extends Node

	var selected_room := "throne"
	var update4_active_run := {
		"outpost": {"type_id": "watch_nest"},
		"upper_floor": {"unlocked": true}
	}

	func _build_selected_slot() -> void:
		pass

	func _open_monster_screen() -> void:
		pass

	func _start_combat() -> void:
		pass

	func _open_chronicle() -> void:
		pass

	func _open_update3_duo_link_loadout() -> void:
		pass

	func _open_raid_screen() -> void:
		pass

	func _open_update4_outpost_management() -> void:
		pass

	func _open_update4_upper_floor() -> void:
		pass

	func display_name_for_instance(_room_id: String) -> String:
		return "왕좌"

	func _update3_duo_loadout_edit_available() -> bool:
		return true

	func _raid_unlocked() -> bool:
		return true

	func _campaign_raid_choice_pending() -> bool:
		return false

	func _update4_council_mode_active() -> bool:
		return true

	func _update4_required_choice_pending() -> bool:
		return false

	func _early_specialization_required_for_current_day() -> bool:
		return false

	func _campaign_final_declaration_pending() -> bool:
		return false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var root := ProductRootFixture.new()
	add_child(root)
	var model: Dictionary = ManagementViewModel.build(root)
	_expect(str(model.get("source", "")) == "product_runtime", "management UI reads product runtime")
	_expect(bool(model.get("workspace", {}).get("map_is_primary", false)), "castle map remains the primary workspace")
	_expect(str(model.get("workspace", {}).get("selected_room_name", "")) == "왕좌", "actual selected room feeds the inspector")
	_expect(ManagementViewModel.validate_entrypoints(root, model).is_empty(), "all visible actions have live product callbacks")
	var ids: Array[String] = []
	for value in model.get("actions", []):
		ids.append(str(value.get("id", "")))
	for expected_id in ["build", "monsters", "start_combat", "chronicle", "duo_loadout", "raid", "outpost", "upper_floor"]:
		_expect(ids.has(expected_id), "%s remains reachable from management UI" % expected_id)
	_expect(ids.size() == _unique(ids).size(), "management action IDs are unique")
	_expect(model.get("developer_copy", []).is_empty(), "management UI has no test or developer copy")

	for viewport_size in [Vector2(1920, 1080), Vector2(1366, 768), Vector2(1280, 720), Vector2(844, 390)]:
		var contract: Dictionary = ManagementViewModel.layout_contract(viewport_size)
		_expect(str(contract.get("mode", "")) != "orientation_notice", "%dx%d uses landscape management workspace" % [int(viewport_size.x), int(viewport_size.y)])
		_expect(_inside_and_non_overlapping(contract, viewport_size), "%dx%d management regions fit without overlap" % [int(viewport_size.x), int(viewport_size.y)])
	var portrait: Dictionary = ManagementViewModel.layout_contract(Vector2(390, 844))
	_expect(str(portrait.get("mode", "")) == "orientation_notice", "portrait mobile receives a rotation notice")

	root.queue_free()
	if failed:
		print("V122_MANAGEMENT_UI_CONTRACT_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("V122_MANAGEMENT_UI_CONTRACT_TEST: PASS")
		get_tree().quit(0)


func _inside_and_non_overlapping(contract: Dictionary, viewport_size: Vector2) -> bool:
	var bounds := Rect2(Vector2.ZERO, viewport_size)
	var rects: Array[Rect2] = []
	for key in ["map", "room_list", "context_drawer", "primary_actions"]:
		var rect: Rect2 = contract.get(key, Rect2())
		if rect.size.x <= 0.0 or rect.size.y <= 0.0 or not bounds.encloses(rect):
			return false
		rects.append(rect)
	for left_index in range(rects.size()):
		for right_index in range(left_index + 1, rects.size()):
			if rects[left_index].intersects(rects[right_index]):
				return false
	return true


func _unique(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		if not result.has(value):
			result.append(value)
	return result


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
