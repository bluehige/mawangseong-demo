extends Node

const Update4CatalogLoaderScript = preload("res://scripts/data/update4/Update4CatalogLoader.gd")

var rooms: Dictionary = {}
var monsters: Dictionary = {}
var enemies: Dictionary = {}
var characters: Dictionary = {}
var skills: Dictionary = {}
var waves: Dictionary = {}
var campaign_days: Dictionary = {}
var castle_evolution_stages: Dictionary = {}
var castle_stage_expansions: Dictionary = {}
var evolution_rules: Dictionary = {}
var specializations: Dictionary = {}
var raid_missions: Dictionary = {}
var monster_instances: Dictionary = {}
var run_metric_definitions: Dictionary = {}
var ending_rules: Dictionary = {}
var memory_entries: Dictionary = {}
var cycle_doctrines: Dictionary = {}
var cycle_decrees: Dictionary = {}
var challenge_seals: Dictionary = {}
var update2_contracts: Dictionary = {}
var update2_counterforce: Dictionary = {}
var update2_seeded_campaign: Dictionary = {}
var leon_adaptive_stances: Dictionary = {}
var update3_fronts: Dictionary = {}
var update3_front_day_overlays: Dictionary = {}
var update3_front_operations: Dictionary = {}
var update3_events: Dictionary = {}
var update3_castle_hearts: Dictionary = {}
var update3_heart_auto_profiles: Dictionary = {}
var update3_duo_links: Dictionary = {}
var update3_monster_extensions: Dictionary = {}
var update3_enemy_extensions: Dictionary = {}
var update3_rival_finales: Dictionary = {}
var update3_endings: Dictionary = {}
var update3_chronicle_goals: Dictionary = {}
var update4_catalogs: Dictionary = {}
var update4_campaign_modes: Dictionary = {}
var update4_council_campaign_days: Dictionary = {}
var update4_regions: Dictionary = {}
var update4_region_day_overlays: Dictionary = {}
var update4_region_events: Dictionary = {}
var update4_council_wave_templates: Dictionary = {}
var update4_council_agendas: Dictionary = {}
var update4_council_balance: Dictionary = {}
var update4_rival_lords: Dictionary = {}
var update4_rival_letters: Dictionary = {}
var update4_characters: Dictionary = {}
var update4_monsters: Dictionary = {}
var update4_skills: Dictionary = {}
var update4_enemies: Dictionary = {}
var update4_rival_bosses: Dictionary = {}
var update4_specializations: Dictionary = {}
var update4_monster_instances: Dictionary = {}
var update4_outpost_types: Dictionary = {}
var update4_outpost_encounters: Dictionary = {}
var update4_upper_floor_modules: Dictionary = {}
var update4_upper_floor_layouts: Dictionary = {}
var update4_crown_evolutions: Dictionary = {}
var update4_crown_events: Dictionary = {}
var update4_asset_manifest: Dictionary = {}
var update4_bond_events: Dictionary = {}
var update4_monster_codex: Dictionary = {}
var update4_run_metric_definitions: Dictionary = {}
var update4_council_endings: Dictionary = {}
var quarter_modules: Dictionary = {}
var quarter_starting_layout: Dictionary = {}
var quarter_layout_catalog: Dictionary = {}
var quarter_user_layout_catalog: Dictionary = {}
var quarter_layouts: Dictionary = {}
var quarter_default_layout_id: String = ""
var quarter_tile_variant_manifest: Dictionary = {}
var quarter_castle_grade_rules: Dictionary = {}
var quarter_asset_manifest: Dictionary = {}
var runtime_layout_persistence_disabled := false

const QUARTER_CUSTOM_LAYOUTS_PATH = "res://data/dungeon_quarter/custom_layouts.json"
const QUARTER_USER_LAYOUTS_PATH = "user://quarter_custom_layouts.json"

func _ready() -> void:
	load_all()

func load_all() -> void:
	rooms = _load_json("res://data/rooms.json")
	monsters = _load_json("res://data/monsters.json")
	enemies = _load_json("res://data/enemies.json")
	characters = _load_json("res://data/characters.json")
	skills = _load_json("res://data/skills.json")
	waves = _load_json("res://data/waves.json")
	campaign_days = _load_json("res://data/campaign_days.json")
	castle_evolution_stages = _load_json("res://data/castle_evolution_stages.json")
	castle_stage_expansions = _load_json("res://data/castle_stage_expansions.json")
	evolution_rules = _load_json("res://data/evolution_rules.json")
	specializations = _load_json("res://data/specializations.json")
	raid_missions = _load_json("res://data/raid_missions.json")
	monster_instances = _load_json("res://data/monster_instances.json")
	run_metric_definitions = _load_json("res://data/run_metric_definitions.json")
	ending_rules = _load_json("res://data/ending_rules.json")
	memory_entries = _load_json("res://data/memory_entries.json")
	cycle_doctrines = _load_json("res://data/cycle_doctrines.json")
	cycle_decrees = _load_json("res://data/cycle_decrees.json")
	challenge_seals = _load_json("res://data/challenge_seals.json")
	update2_contracts = _load_json("res://data/update2_contracts.json")
	update2_counterforce = _load_json("res://data/update2_counterforce.json")
	update2_seeded_campaign = _load_json("res://data/update2_seeded_campaign.json")
	leon_adaptive_stances = _load_json("res://data/leon_adaptive_stances.json")
	update3_fronts = _load_json("res://data/regular_version/update3/fronts.json")
	update3_front_day_overlays = _load_json("res://data/regular_version/update3/front_day_overlays.json")
	update3_front_operations = _load_json("res://data/regular_version/update3/front_operations.json")
	_resolve_update3_front_operation_sources()
	update3_events = _load_json("res://data/regular_version/update3/events.json")
	_register_update3_front_operations_as_raids()
	update3_castle_hearts = _load_json("res://data/regular_version/update3/castle_hearts.json")
	update3_heart_auto_profiles = _load_json("res://data/regular_version/update3/heart_auto_profiles.json")
	update3_duo_links = _load_json("res://data/regular_version/update3/duo_links.json")
	update3_monster_extensions = _load_json("res://data/regular_version/update3/monsters.json")
	for monster_id in update3_monster_extensions.keys():
		monsters[str(monster_id)] = update3_monster_extensions[monster_id].duplicate(true)
	update3_enemy_extensions = _load_json("res://data/regular_version/update3/enemies.json")
	for enemy_id in update3_enemy_extensions.keys():
		enemies[str(enemy_id)] = update3_enemy_extensions[enemy_id].duplicate(true)
	update3_rival_finales = _load_json("res://data/regular_version/update3/rival_finales.json")
	update3_endings = _load_json("res://data/regular_version/update3/endings.json")
	_merge_update3_endings_into_catalog()
	update3_chronicle_goals = _load_json("res://data/regular_version/update3/chronicle_goals.json")
	var update4_load := Update4CatalogLoaderScript.load_all()
	update4_catalogs = update4_load.get("catalogs", {}).duplicate(true) if bool(update4_load.get("ok", false)) else {}
	update4_campaign_modes = update4_catalogs.get("campaign_modes", {}).duplicate(true)
	update4_council_campaign_days = update4_catalogs.get("council_campaign_days", {}).duplicate(true)
	update4_regions = update4_catalogs.get("regions", {}).duplicate(true)
	update4_region_day_overlays = update4_catalogs.get("region_day_overlays", {}).duplicate(true)
	update4_region_events = update4_catalogs.get("region_events", {}).duplicate(true)
	update4_council_wave_templates = update4_catalogs.get("council_wave_templates", {}).duplicate(true)
	update4_council_agendas = update4_catalogs.get("council_agendas", {}).duplicate(true)
	update4_council_balance = update4_catalogs.get("council_balance", {}).duplicate(true)
	update4_rival_lords = update4_catalogs.get("rival_lords", {}).duplicate(true)
	update4_rival_letters = update4_catalogs.get("rival_letters", {}).duplicate(true)
	update4_characters = update4_catalogs.get("characters", {}).duplicate(true)
	update4_monsters = update4_catalogs.get("monsters", {}).duplicate(true)
	update4_skills = update4_catalogs.get("skills", {}).duplicate(true)
	update4_enemies = update4_catalogs.get("enemies", {}).duplicate(true)
	update4_rival_bosses = _load_json("res://data/regular_version/update4/rival_bosses.json")
	update4_specializations = _load_json("res://data/regular_version/update4/specializations.json")
	update4_monster_instances = _load_json("res://data/regular_version/update4/monster_instances.json")
	for character_id in update4_characters.keys():
		characters[str(character_id)] = update4_characters[character_id].duplicate(true)
	for monster_id in update4_monsters.keys():
		monsters[str(monster_id)] = update4_monsters[monster_id].duplicate(true)
	for skill_id in update4_skills.keys():
		skills[str(skill_id)] = update4_skills[skill_id].duplicate(true)
	for enemy_id in update4_enemies.keys():
		enemies[str(enemy_id)] = update4_enemies[enemy_id].duplicate(true)
	for boss_id in update4_rival_bosses.keys():
		enemies[str(boss_id)] = update4_rival_bosses[boss_id].duplicate(true)
	for specialization_id in update4_specializations.keys():
		specializations[str(specialization_id)] = update4_specializations[specialization_id].duplicate(true)
	for instance_id in update4_monster_instances.keys():
		monster_instances[str(instance_id)] = update4_monster_instances[instance_id].duplicate(true)
	update4_outpost_types = update4_catalogs.get("outpost_types", {}).duplicate(true)
	update4_outpost_encounters = update4_catalogs.get("outpost_encounters", {}).duplicate(true)
	update4_upper_floor_modules = update4_catalogs.get("upper_floor_modules", {}).duplicate(true)
	update4_upper_floor_layouts = update4_catalogs.get("upper_floor_layouts", {}).duplicate(true)
	update4_crown_evolutions = update4_catalogs.get("crown_evolutions", {}).duplicate(true)
	update4_crown_events = update4_catalogs.get("crown_events", {}).duplicate(true)
	update4_asset_manifest = update4_catalogs.get("asset_manifest", {}).duplicate(true)
	update4_bond_events = update4_catalogs.get("bond_events", {}).duplicate(true)
	update4_monster_codex = update4_catalogs.get("monster_codex", {}).duplicate(true)
	update4_run_metric_definitions = update4_catalogs.get("run_metric_definitions", {}).duplicate(true)
	update4_council_endings = update4_catalogs.get("council_endings", {}).duplicate(true)
	_merge_update4_metrics_and_endings()
	var quarter_blueprints = _load_json("res://data/dungeon_quarter/room_blueprints.json")
	quarter_modules = quarter_blueprints if not quarter_blueprints.is_empty() else _load_json("res://data/dungeon_quarter/modules.json")
	var update3_heart_modules := _load_json("res://data/regular_version/update3/heart_chamber_modules.json")
	for module_id in update3_heart_modules.keys():
		quarter_modules[module_id] = update3_heart_modules[module_id].duplicate(true)
	quarter_starting_layout = _load_json("res://data/dungeon_quarter/starting_layout.json")
	quarter_layout_catalog = _load_json(QUARTER_CUSTOM_LAYOUTS_PATH)
	quarter_user_layout_catalog = _load_json(QUARTER_USER_LAYOUTS_PATH) if FileAccess.file_exists(QUARTER_USER_LAYOUTS_PATH) else {"version": 1, "layouts": {}}
	_merge_user_quarter_layouts()
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

func character(character_id: String) -> Dictionary:
	return characters.get(character_id, {})

func skill(skill_id: String) -> Dictionary:
	return skills.get(skill_id, {})

func raid_mission(raid_id: String) -> Dictionary:
	return raid_missions.get(raid_id, {})

func campaign_day(day: int) -> Dictionary:
	return campaign_days.get("day_%d" % day, {})

func castle_evolution_stage(stage_id: String) -> Dictionary:
	return castle_evolution_stages.get(stage_id, {})

func castle_evolution_stage_ids() -> Array:
	var ids := castle_evolution_stages.keys()
	ids.sort_custom(func(a, b): return int(castle_evolution_stages[a].get("index", 0)) < int(castle_evolution_stages[b].get("index", 0)))
	return ids

func castle_stage_expansion(stage_id: String) -> Dictionary:
	return castle_stage_expansions.get(stage_id, {}).duplicate(true)

func evolution_rule(rule_id: String) -> Dictionary:
	return evolution_rules.get(rule_id, {})

func specialization(specialization_id: String) -> Dictionary:
	return specializations.get(specialization_id, {})

func monster_instance(instance_id: String) -> Dictionary:
	return monster_instances.get(instance_id, {}).duplicate(true)

func ending_rule(ending_id: String) -> Dictionary:
	return ending_rules.get(ending_id, {}).duplicate(true)

func memory_entry(memory_id: String) -> Dictionary:
	if memory_entries.has(memory_id):
		return memory_entries.get(memory_id, {}).duplicate(true)
	for entry_value in memory_entries.values():
		if not (entry_value is Dictionary):
			continue
		var prefix := str(entry_value.get("id_prefix", ""))
		if prefix != "" and memory_id.begins_with(prefix):
			var entry: Dictionary = entry_value.duplicate(true)
			entry["source_cycle"] = int(memory_id.trim_prefix(prefix))
			return entry
	return {}


func _merge_update3_endings_into_catalog() -> void:
	for ending_id_value in update3_endings.keys():
		var ending_id := str(ending_id_value)
		var source = update3_endings.get(ending_id_value)
		if ending_id == "" or not (source is Dictionary):
			continue
		var runtime_rule: Dictionary = source.duplicate(true)
		runtime_rule["id"] = ending_id
		runtime_rule["fallback"] = false
		runtime_rule["requirements"] = runtime_rule.get("condition", {}).duplicate(true)
		runtime_rule.erase("condition")
		ending_rules[ending_id] = runtime_rule


func _merge_update4_metrics_and_endings() -> void:
	for metric_id_value in update4_run_metric_definitions.keys():
		var metric_id := str(metric_id_value)
		var definition = update4_run_metric_definitions.get(metric_id_value)
		if metric_id != "" and definition is Dictionary:
			run_metric_definitions[metric_id] = definition.duplicate(true)
	for ending_id_value in update4_council_endings.keys():
		var ending_id := str(ending_id_value)
		var source = update4_council_endings.get(ending_id_value)
		if ending_id == "" or not (source is Dictionary):
			continue
		var runtime_rule: Dictionary = source.duplicate(true)
		runtime_rule["id"] = ending_id
		runtime_rule["fallback"] = false
		runtime_rule["requirements"] = runtime_rule.get("condition", {}).duplicate(true)
		runtime_rule.erase("condition")
		ending_rules[ending_id] = runtime_rule


func _register_update3_front_operations_as_raids() -> void:
	for operation_id_value in update3_front_operations.keys():
		var operation_id := str(operation_id_value)
		var operation: Dictionary = update3_front_operations.get(operation_id, {}).duplicate(true)
		if str(operation.get("raid_source_id", "")) != "":
			continue
		operation["id"] = operation_id
		operation["title"] = str(operation.get("display_name", operation_id))
		operation["subtitle"] = "DAY 28 전선 최종 작전"
		operation["location"] = "성광 정화대 진군로"
		operation["difficulty"] = "전선 작전"
		operation["risk"] = str(operation.get("tradeoff", "선택에 따른 대가"))
		operation["required_monsters"] = 1
		operation["max_monsters"] = 2
		operation["cost"] = operation.get("cost", {"food": 10})
		operation["summary"] = str(operation.get("description", ""))
		operation["briefing_lines"] = [str(operation.get("description", "")), str(operation.get("tradeoff", ""))]
		operation["success_lines"] = ["%s 작전을 확정했습니다." % str(operation.get("display_name", operation_id))]
		operation["next_defense_modifier"] = operation.get("defense_modifier", {}).duplicate(true)
		operation["defense_result_line"] = "%s 효과가 DAY 30에 적용됐다." % str(operation.get("display_name", operation_id))
		raid_missions[operation_id] = operation


func _resolve_update3_front_operation_sources() -> void:
	for operation_id_value in update3_front_operations.keys():
		var operation_id := str(operation_id_value)
		var operation: Dictionary = update3_front_operations.get(operation_id, {}).duplicate(true)
		var source_id := str(operation.get("raid_source_id", ""))
		if source_id == "":
			continue
		var source: Dictionary = raid_missions.get(source_id, {})
		if source.is_empty():
			continue
		operation["id"] = operation_id
		operation["display_name"] = str(operation.get("display_name", source.get("title", operation_id)))
		operation["description"] = str(operation.get("description", source.get("summary", "")))
		operation["reward"] = source.get("reward", {}).duplicate(true)
		operation["defense_modifier"] = source.get("next_defense_modifier", {}).duplicate(true)
		operation["tradeoff"] = str(operation.get("tradeoff", source.get("risk", "")))
		update3_front_operations[operation_id] = operation

func cycle_doctrine(doctrine_id: String) -> Dictionary:
	return cycle_doctrines.get(doctrine_id, {}).duplicate(true)

func cycle_doctrine_ids() -> Array:
	var ids := cycle_doctrines.keys()
	ids.sort_custom(func(a, b): return int(cycle_doctrines[a].get("order", 0)) < int(cycle_doctrines[b].get("order", 0)))
	return ids

func cycle_decree(decree_id: String) -> Dictionary:
	return cycle_decrees.get(decree_id, {}).duplicate(true)

func cycle_decree_ids() -> Array:
	var ids := cycle_decrees.keys()
	ids.sort_custom(func(a, b): return int(cycle_decrees[a].get("order", 0)) < int(cycle_decrees[b].get("order", 0)))
	return ids

func challenge_seal(seal_id: String) -> Dictionary:
	return challenge_seals.get(seal_id, {}).duplicate(true)

func challenge_seal_ids() -> Array:
	var ids := challenge_seals.keys()
	ids.sort_custom(func(a, b): return int(challenge_seals[a].get("order", 0)) < int(challenge_seals[b].get("order", 0)))
	return ids

func update2_contract(contract_id: String) -> Dictionary:
	return update2_contracts.get(contract_id, {}).duplicate(true)

func update2_contract_ids() -> Array:
	var ids := update2_contracts.keys()
	ids.sort_custom(func(a, b): return int(update2_contracts[a].get("order", 0)) < int(update2_contracts[b].get("order", 0)))
	return ids

func update2_counterforce_profile(enemy_id: String) -> Dictionary:
	return update2_counterforce.get(enemy_id, {}).duplicate(true)

func update2_counterforce_ids() -> Array:
	var ids := update2_counterforce.keys()
	ids.sort_custom(func(a, b): return int(update2_counterforce[a].get("order", 0)) < int(update2_counterforce[b].get("order", 0)))
	return ids

func leon_adaptive_stance(stance_id: String) -> Dictionary:
	return leon_adaptive_stances.get(stance_id, {}).duplicate(true)

func leon_adaptive_stance_ids() -> Array:
	var ids := leon_adaptive_stances.keys()
	ids.sort_custom(func(a, b): return int(leon_adaptive_stances[a].get("order", 0)) < int(leon_adaptive_stances[b].get("order", 0)))
	return ids

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
	if _runtime_layout_persistence_disabled():
		return true
	if not quarter_user_layout_catalog.has("layouts") or typeof(quarter_user_layout_catalog["layouts"]) != TYPE_DICTIONARY:
		quarter_user_layout_catalog["layouts"] = {}
	quarter_user_layout_catalog["layouts"][layout_id] = copied_layout
	return _save_json(QUARTER_USER_LAYOUTS_PATH, quarter_user_layout_catalog)

func _runtime_layout_persistence_disabled() -> bool:
	return runtime_layout_persistence_disabled or OS.get_name() == "Web" or OS.has_feature("web")

func _merge_user_quarter_layouts() -> void:
	var user_layouts = quarter_user_layout_catalog.get("layouts", {})
	if not (user_layouts is Dictionary):
		return
	if not quarter_layout_catalog.has("layouts") or not (quarter_layout_catalog.get("layouts") is Dictionary):
		quarter_layout_catalog["layouts"] = {}
	for layout_id in user_layouts.keys():
		var layout = user_layouts.get(layout_id)
		if layout is Dictionary and not layout.is_empty():
			quarter_layout_catalog["layouts"][str(layout_id)] = layout.duplicate(true)

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

