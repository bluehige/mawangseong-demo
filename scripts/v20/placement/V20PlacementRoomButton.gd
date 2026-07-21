class_name V20PlacementRoomButton
extends Button

signal monster_dropped(monster_id: String, room_id: String)
signal facility_dropped(facility_id: String, room_id: String)

var room_id := ""


func setup(room_id_value: String, display_name: String) -> void:
	room_id = room_id_value
	text = display_name


func _can_drop_data(_at_position: Vector2, data) -> bool:
	if not (data is Dictionary):
		return false
	var kind := str(data.get("kind", ""))
	return (kind == "v20_monster" and str(data.get("monster_id", "")) != "") or (kind == "v20_facility" and str(data.get("facility_id", "")) != "")


func _drop_data(_at_position: Vector2, data) -> void:
	if not _can_drop_data(Vector2.ZERO, data):
		return
	if str(data.get("kind", "")) == "v20_facility":
		facility_dropped.emit(str(data.get("facility_id", "")), room_id)
	else:
		monster_dropped.emit(str(data.get("monster_id", "")), room_id)
