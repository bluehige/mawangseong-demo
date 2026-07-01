extends Node

var rooms: Dictionary = {}
var monsters: Dictionary = {}
var enemies: Dictionary = {}
var skills: Dictionary = {}
var waves: Dictionary = {}

func _ready() -> void:
	load_all()

func load_all() -> void:
	rooms = _load_json("res://data/rooms.json")
	monsters = _load_json("res://data/monsters.json")
	enemies = _load_json("res://data/enemies.json")
	skills = _load_json("res://data/skills.json")
	waves = _load_json("res://data/waves.json")

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Missing data file: %s" % path)
		return {}
	var text = FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	push_warning("Invalid JSON data: %s" % path)
	return {}

func room(room_id: String) -> Dictionary:
	return rooms.get(room_id, {})

func monster(monster_id: String) -> Dictionary:
	return monsters.get(monster_id, {})

func enemy(enemy_id: String) -> Dictionary:
	return enemies.get(enemy_id, {})

func skill(skill_id: String) -> Dictionary:
	return skills.get(skill_id, {})

