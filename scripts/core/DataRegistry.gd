extends Node

var rooms: Dictionary = {}
var monsters: Dictionary = {}
var enemies: Dictionary = {}
var skills: Dictionary = {}
var waves: Dictionary = {}
var quarter_modules: Dictionary = {}
var quarter_starting_layout: Dictionary = {}
var quarter_layout_catalog: Dictionary = {}
var quarter_layouts: Dictionary = {}
var quarter_default_layout_id: String = ""
var quarter_tile_variant_manifest: Dictionary = {}
var quarter_castle_grade_rules: Dictionary = {}
var quarter_asset_manifest: Dictionary = {}

const QUARTER_CUSTOM_LAYOUTS_PATH = "res://data/dungeon_quarter/custom_layouts.json"

func _ready() -> void:
	load_all()

func load_all() -> void:
	rooms = _load_json("res://data/rooms.json")
	monsters = _load_json("res://data/monsters.json")
	enemies = _load_json("res://data/enemies.json")
	skills = _load_json("res://data/skills.json")
	waves = _load_json("res://data/waves.json")
	var quarter_blueprints = _load_json("res://data/dungeon_quarter/room_blueprints.json")
	quarter_modules = quarter_blueprints if not quarter_blueprints.is_empty() else _load_json("res://data/dungeon_quarter/modules.json")
	quarter_starting_layout = _load_json("res://data/dungeon_quarter/starting_layout.json")
	quarter_layout_catalog = _load_json(QUARTER_CUSTOM_LAYOUTS_PATH)
	_rebuild_quarter_layouts()
	quarter_tile_variant_manifest = _load_json("res://data/dungeon_quarter/tile_variant_manifest.json")
	quarter_castle_grade_rules = _load_json("res://data/dungeon_quarter/castle_grade_rules.json")
	quarter_asset_manifest = _load_json("res://data/dungeon_quarter/asset_manifest.json")

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

func _save_json(path: String, data: Dictionary) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Cannot write JSON data: %s" % path)
		return false
	file.store_string(JSON.stringify(data, "  ", true))
	file.store_string("\n")
	file.close()
	return true

func room(room_id: String) -> Dictionary:
	return rooms.get(room_id, {})

func monster(monster_id: String) -> Dictionary:
	return monsters.get(monster_id, {})

func enemy(enemy_id: String) -> Dictionary:
	return enemies.get(enemy_id, {})

func skill(skill_id: String) -> Dictionary:
	return skills.get(skill_id, {})

func quarter_module(module_id: String) -> Dictionary:
	return quarter_modules.get(module_id, {})

func quarter_layout_ids() -> Array:
	var ids = quarter_layouts.keys()
	ids.sort()
	return ids

func quarter_layout(layout_id: String = "") -> Dictionary:
	var selected_id = layout_id if layout_id != "" else quarter_default_layout_id
	return quarter_layouts.get(selected_id, {}).duplicate(true)

func register_quarter_layout(layout_id: String, layout_data: Dictionary, persist: bool = false) -> bool:
	if layout_id == "" or layout_data.is_empty():
		return false
	var copied_layout = layout_data.duplicate(true)
	copied_layout["template_id"] = layout_id
	quarter_layouts[layout_id] = copied_layout
	if not persist:
		return true
	if not quarter_layout_catalog.has("layouts") or typeof(quarter_layout_catalog["layouts"]) != TYPE_DICTIONARY:
		quarter_layout_catalog["layouts"] = {}
	quarter_layout_catalog["layouts"][layout_id] = copied_layout
	return _save_json(QUARTER_CUSTOM_LAYOUTS_PATH, quarter_layout_catalog)

func next_quarter_custom_layout_id(prefix: String = "edited_layout") -> String:
	var index = 1
	while true:
		var candidate = "%s_%02d" % [prefix, index]
		if not quarter_layouts.has(candidate):
			return candidate
		index += 1
	return "%s_%02d" % [prefix, index]

func _rebuild_quarter_layouts() -> void:
	quarter_layouts.clear()
	quarter_default_layout_id = str(quarter_starting_layout.get("template_id", ""))
	if not quarter_starting_layout.is_empty() and quarter_default_layout_id != "":
		quarter_layouts[quarter_default_layout_id] = quarter_starting_layout.duplicate(true)

	var layouts = quarter_layout_catalog.get("layouts", {})
	if typeof(layouts) == TYPE_DICTIONARY:
		for layout_id in layouts.keys():
			var layout = layouts[layout_id]
			if typeof(layout) != TYPE_DICTIONARY:
				continue
			var copied_layout: Dictionary = layout.duplicate(true)
			if not copied_layout.has("template_id"):
				copied_layout["template_id"] = str(layout_id)
			quarter_layouts[str(layout_id)] = copied_layout

	var catalog_default_id = str(quarter_layout_catalog.get("default_layout_id", ""))
	if catalog_default_id != "" and quarter_layouts.has(catalog_default_id):
		quarter_default_layout_id = catalog_default_id
	elif quarter_default_layout_id == "" and not quarter_layouts.is_empty():
		quarter_default_layout_id = str(quarter_layouts.keys()[0])

	quarter_starting_layout = quarter_layout(quarter_default_layout_id)

