class_name V20PlacementRoomButton
extends Button

signal monster_dropped(monster_id: String, room_id: String)

var room_id := ""


func setup(room_id_value: String, display_name: String) -> void:
	room_id = room_id_value
	text = display_name


func _can_drop_data(_at_position: Vector2, data) -> bool:
	return data is Dictionary and str(data.get("kind", "")) == "v20_monster" and str(data.get("monster_id", "")) != ""


func _drop_data(_at_position: Vector2, data) -> void:
	if _can_drop_data(Vector2.ZERO, data):
		monster_dropped.emit(str(data.get("monster_id", "")), room_id)
