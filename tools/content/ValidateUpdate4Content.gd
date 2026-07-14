class_name ValidateUpdate4Content
extends RefCounted

const LoaderScript = preload("res://scripts/data/update4/Update4CatalogLoader.gd")

const REQUIRED_FIELDS := {
	"campaign_modes": ["display_name", "start_day", "max_day", "day_schedule_id", "supported_systems", "data_root", "start_screen_id"],
	"regions": ["display_name", "rival_id", "environment_rule_id", "enemy_pool", "event_ids", "charter_condition_id", "reward_table_id"],
	"council_agendas": ["display_name", "vote_day", "choices", "preferred_rival_ids", "disliked_rival_ids", "modifier_handler_id"],
	"rival_lords": ["character_id", "display_name", "region_affinities", "preferred_agendas", "disliked_agendas", "enemy_pool", "boss_enemy_id", "support_handler_id"],
	"outpost_types": ["display_name", "battle_layout_id", "passive_handler_id", "upgrade_handler_id", "max_deployed"],
	"upper_floor_layouts": ["display_name", "floor_id", "placed_modules", "connections"],
	"crown_evolutions": ["monster_id", "display_name", "required_bond", "required_level", "required_growth_stage", "cost", "stat_multipliers", "passive_handler_id", "royal_skill_id", "branch_inheritance", "animation_set_id"],
	"council_endings": ["catalog_code", "priority", "condition", "reward_ids", "illustration"]
}

const FINAL_REQUIRED_COUNTS := {
	"campaign_modes": 2,
	"council_campaign_days": 30,
	"regions": 5,
	"region_events": 15,
	"council_agendas": 12,
	"rival_lords": 3,
	"rival_events": 9,
	"outpost_types": 3,
	"outpost_events": 6,
	"upper_floor_modules": 4,
	"upper_floor_layouts": 3,
	"monsters": 2,
	"enemies": 6,
	"crown_evolutions": 6,
	"crown_events": 6,
	"rival_letters": 15,
	"council_wave_templates": 15,
	"council_endings": 6
}


static func load_catalogs(root_path: String = LoaderScript.ROOT) -> Dictionary:
	return LoaderScript.load_all(root_path)


static func validate_catalogs(catalogs: Dictionary, context: Dictionary = {}, required_counts: Dictionary = {}) -> Array[String]:
	var errors: Array[String] = []
	_validate_catalog_shapes(catalogs, errors)
	_validate_duplicate_ids(catalogs, errors)
	_validate_required_fields(catalogs, errors)
	_validate_campaign_modes(catalogs, context, errors)
	_validate_regions(catalogs, context, errors)
	_validate_agendas(catalogs, context, errors)
	_validate_rivals(catalogs, context, errors)
	_validate_outposts(catalogs, context, errors)
	_validate_upper_floors(catalogs, errors)
	_validate_crowns(catalogs, context, errors)
	_validate_endings(catalogs, context, errors)
	_validate_counts(catalogs, required_counts, errors)
	return errors


static func _validate_catalog_shapes(catalogs: Dictionary, errors: Array[String]) -> void:
	for catalog_name_value in LoaderScript.CATALOG_FILES.keys():
		var catalog_name := str(catalog_name_value)
		if not catalogs.has(catalog_name):
			errors.append("필수 카탈로그 누락: %s" % catalog_name)
		elif not (catalogs[catalog_name] is Dictionary):
			errors.append("카탈로그 %s는 Dictionary여야 합니다." % catalog_name)


static func _validate_duplicate_ids(catalogs: Dictionary, errors: Array[String]) -> void:
	var owners := {}
	for catalog_name_value in LoaderScript.CATALOG_FILES.keys():
		var catalog_name := str(catalog_name_value)
		var catalog = catalogs.get(catalog_name, {})
		if not (catalog is Dictionary):
			continue
		for entry_id_value in catalog.keys():
			var entry_id := str(entry_id_value)
			if owners.has(entry_id):
				errors.append("Update 4 ID 중복: %s (%s, %s)" % [entry_id, owners[entry_id], catalog_name])
			else:
				owners[entry_id] = catalog_name


static func _validate_required_fields(catalogs: Dictionary, errors: Array[String]) -> void:
	for catalog_name_value in REQUIRED_FIELDS.keys():
		var catalog_name := str(catalog_name_value)
		var catalog = catalogs.get(catalog_name, {})
		if not (catalog is Dictionary):
			continue
		for entry_id_value in catalog.keys():
			var entry_id := str(entry_id_value)
			var entry = catalog[entry_id_value]
			if not (entry is Dictionary):
				errors.append("%s 항목 %s는 Dictionary여야 합니다." % [catalog_name, entry_id])
				continue
			for field_value in REQUIRED_FIELDS[catalog_name]:
				var field := str(field_value)
				if not entry.has(field):
					errors.append("%s %s 필수 필드 누락: %s" % [catalog_name, entry_id, field])


static func _validate_campaign_modes(catalogs: Dictionary, context: Dictionary, errors: Array[String]) -> void:
	var schedules: Dictionary = catalogs.get("council_campaign_days", {}).duplicate(true)
	for schedule_id in context.get("day_schedules", {}).keys():
		schedules[schedule_id] = context.get("day_schedules", {})[schedule_id]
	var screens: Dictionary = context.get("screens", {})
	for mode_id_value in _keys(catalogs, "campaign_modes"):
		var mode_id := str(mode_id_value)
		var mode: Dictionary = catalogs["campaign_modes"][mode_id_value]
		var start_day := int(mode.get("start_day", 0))
		var max_day := int(mode.get("max_day", 0))
		var expected_start_day := 4 if mode_id == "front_chronicle" else 1
		if start_day != expected_start_day or max_day != 30:
			errors.append("campaign mode %s는 DAY %d~30 계약이어야 합니다." % [mode_id, expected_start_day])
		_require_ref("campaign mode %s day schedule" % mode_id, str(mode.get("day_schedule_id", "")), schedules, errors)
		_require_ref("campaign mode %s start screen" % mode_id, str(mode.get("start_screen_id", "")), screens, errors)
		if not (mode.get("supported_systems", []) is Array):
			errors.append("campaign mode %s supported_systems는 Array여야 합니다." % mode_id)


static func _validate_regions(catalogs: Dictionary, context: Dictionary, errors: Array[String]) -> void:
	var rivals := _combined(catalogs.get("rival_lords", {}), context.get("rivals", {}))
	var events := _combined(catalogs.get("region_events", {}), context.get("region_events", {}))
	var enemies := _combined(catalogs.get("enemies", {}), context.get("enemies", {}))
	var handlers: Dictionary = context.get("handlers", {})
	for region_id_value in _keys(catalogs, "regions"):
		var region_id := str(region_id_value)
		var region: Dictionary = catalogs["regions"][region_id_value]
		_require_ref("region %s rival" % region_id, str(region.get("rival_id", "")), rivals, errors)
		_require_refs("region %s enemy" % region_id, region.get("enemy_pool", []), enemies, errors)
		_require_refs("region %s event" % region_id, region.get("event_ids", []), events, errors)
		_require_ref("region %s environment handler" % region_id, str(region.get("environment_rule_id", "")), handlers, errors)
		_require_ref("region %s charter handler" % region_id, str(region.get("charter_condition_id", "")), handlers, errors)
		_require_ref("region %s reward handler" % region_id, str(region.get("reward_table_id", "")), handlers, errors)


static func _validate_agendas(catalogs: Dictionary, context: Dictionary, errors: Array[String]) -> void:
	var rivals: Dictionary = catalogs.get("rival_lords", {})
	var handlers: Dictionary = context.get("handlers", {})
	for agenda_id_value in _keys(catalogs, "council_agendas"):
		var agenda_id := str(agenda_id_value)
		var agenda: Dictionary = catalogs["council_agendas"][agenda_id_value]
		if int(agenda.get("vote_day", 0)) not in [13, 22, 26]:
			errors.append("agenda %s vote_day는 13, 22, 26 중 하나여야 합니다." % agenda_id)
		if not (agenda.get("choices", []) is Array) or agenda.get("choices", []).size() != 3:
			errors.append("agenda %s choices는 정확히 3개여야 합니다." % agenda_id)
		_require_refs("agenda %s preferred rival" % agenda_id, agenda.get("preferred_rival_ids", []), rivals, errors)
		_require_refs("agenda %s disliked rival" % agenda_id, agenda.get("disliked_rival_ids", []), rivals, errors)
		_require_ref("agenda %s modifier handler" % agenda_id, str(agenda.get("modifier_handler_id", "")), handlers, errors)


static func _validate_rivals(catalogs: Dictionary, context: Dictionary, errors: Array[String]) -> void:
	var regions: Dictionary = catalogs.get("regions", {})
	var agendas: Dictionary = catalogs.get("council_agendas", {})
	var enemies := _combined(catalogs.get("enemies", {}), context.get("enemies", {}))
	var characters := _combined(catalogs.get("characters", {}), context.get("characters", {}))
	var handlers: Dictionary = context.get("handlers", {})
	for rival_id_value in _keys(catalogs, "rival_lords"):
		var rival_id := str(rival_id_value)
		var rival: Dictionary = catalogs["rival_lords"][rival_id_value]
		_require_ref("rival %s character" % rival_id, str(rival.get("character_id", "")), characters, errors)
		_require_refs("rival %s region" % rival_id, rival.get("region_affinities", []), regions, errors)
		_require_refs("rival %s preferred agenda" % rival_id, rival.get("preferred_agendas", []), agendas, errors)
		_require_refs("rival %s disliked agenda" % rival_id, rival.get("disliked_agendas", []), agendas, errors)
		_require_refs("rival %s enemy" % rival_id, rival.get("enemy_pool", []), enemies, errors)
		_require_ref("rival %s boss" % rival_id, str(rival.get("boss_enemy_id", "")), enemies, errors)
		_require_ref("rival %s support handler" % rival_id, str(rival.get("support_handler_id", "")), handlers, errors)


static func _validate_outposts(catalogs: Dictionary, context: Dictionary, errors: Array[String]) -> void:
	var encounters: Dictionary = catalogs.get("outpost_encounters", {})
	var handlers: Dictionary = context.get("handlers", {})
	for outpost_id_value in _keys(catalogs, "outpost_types"):
		var outpost_id := str(outpost_id_value)
		var outpost: Dictionary = catalogs["outpost_types"][outpost_id_value]
		_require_ref("outpost %s battle layout" % outpost_id, str(outpost.get("battle_layout_id", "")), encounters, errors)
		_require_ref("outpost %s passive handler" % outpost_id, str(outpost.get("passive_handler_id", "")), handlers, errors)
		_require_ref("outpost %s upgrade handler" % outpost_id, str(outpost.get("upgrade_handler_id", "")), handlers, errors)
		if int(outpost.get("max_deployed", 0)) != 3:
			errors.append("outpost %s max_deployed는 3이어야 합니다." % outpost_id)


static func _validate_upper_floors(catalogs: Dictionary, errors: Array[String]) -> void:
	var modules: Dictionary = catalogs.get("upper_floor_modules", {})
	for layout_id_value in _keys(catalogs, "upper_floor_layouts"):
		var layout_id := str(layout_id_value)
		var layout: Dictionary = catalogs["upper_floor_layouts"][layout_id_value]
		var instances := {}
		var placed = layout.get("placed_modules", [])
		if not (placed is Array):
			errors.append("upper floor %s placed_modules는 Array여야 합니다." % layout_id)
			continue
		for placement_value in placed:
			if not (placement_value is Dictionary):
				errors.append("upper floor %s placement는 Dictionary여야 합니다." % layout_id)
				continue
			var placement: Dictionary = placement_value
			var instance_id := str(placement.get("instance_id", ""))
			if instance_id == "" or instances.has(instance_id):
				errors.append("upper floor %s instance_id 누락 또는 중복: %s" % [layout_id, instance_id])
			instances[instance_id] = true
			_require_ref("upper floor %s module" % layout_id, str(placement.get("module_id", "")), modules, errors)


static func _validate_crowns(catalogs: Dictionary, context: Dictionary, errors: Array[String]) -> void:
	var monsters := _combined(catalogs.get("monsters", {}), context.get("monsters", {}))
	var skills := _combined(catalogs.get("skills", {}), context.get("skills", {}))
	var evolutions: Dictionary = context.get("evolutions", {})
	var handlers: Dictionary = context.get("handlers", {})
	var animation_sets: Dictionary = context.get("animation_sets", {})
	for crown_id_value in _keys(catalogs, "crown_evolutions"):
		var crown_id := str(crown_id_value)
		var crown: Dictionary = catalogs["crown_evolutions"][crown_id_value]
		_require_ref("crown %s monster" % crown_id, str(crown.get("monster_id", "")), monsters, errors)
		_require_ref("crown %s passive handler" % crown_id, str(crown.get("passive_handler_id", "")), handlers, errors)
		_require_ref("crown %s royal skill" % crown_id, str(crown.get("royal_skill_id", "")), skills, errors)
		_require_ref("crown %s animation set" % crown_id, str(crown.get("animation_set_id", "")), animation_sets, errors)
		var inheritance = crown.get("branch_inheritance", {})
		if not (inheritance is Dictionary):
			errors.append("crown %s branch_inheritance는 Dictionary여야 합니다." % crown_id)
			continue
		for evolution_id_value in inheritance.keys():
			_require_ref("crown %s evolution branch" % crown_id, str(evolution_id_value), evolutions, errors)
			_require_ref("crown %s inheritance handler" % crown_id, str(inheritance[evolution_id_value]), handlers, errors)


static func _validate_endings(catalogs: Dictionary, context: Dictionary, errors: Array[String]) -> void:
	var metrics := _combined(catalogs.get("run_metric_definitions", {}), context.get("metrics", {}))
	for ending_id_value in _keys(catalogs, "council_endings"):
		var ending_id := str(ending_id_value)
		var ending: Dictionary = catalogs["council_endings"][ending_id_value]
		var code := str(ending.get("catalog_code", ""))
		if not code.begins_with("E") or not code.substr(1).is_valid_int():
			errors.append("ending %s catalog_code 형식 오류: %s" % [ending_id, code])
		var condition = ending.get("condition", {})
		if condition is Dictionary and condition.has("metric"):
			_require_ref("ending %s metric" % ending_id, str(condition.get("metric", "")), metrics, errors)
		var illustration := str(ending.get("illustration", ""))
		if illustration != "" and not ResourceLoader.exists(illustration):
			errors.append("ending %s illustration 리소스가 없습니다: %s" % [ending_id, illustration])


static func _validate_counts(catalogs: Dictionary, required_counts: Dictionary, errors: Array[String]) -> void:
	for catalog_name_value in required_counts.keys():
		var catalog_name := str(catalog_name_value)
		var catalog = catalogs.get(catalog_name, {})
		var actual: int = catalog.size() if catalog is Dictionary else -1
		var expected := int(required_counts[catalog_name_value])
		if actual != expected:
			errors.append("카탈로그 %s 수량 오류: expected=%d actual=%d" % [catalog_name, expected, actual])


static func _keys(catalogs: Dictionary, catalog_name: String) -> Array:
	var catalog = catalogs.get(catalog_name, {})
	return catalog.keys() if catalog is Dictionary else []


static func _combined(first_value, second_value) -> Dictionary:
	var result := {}
	if first_value is Dictionary:
		result.merge(first_value, true)
	if second_value is Dictionary:
		result.merge(second_value, true)
	return result


static func _require_ref(label: String, reference_id: String, catalog: Dictionary, errors: Array[String]) -> void:
	if reference_id == "" or not catalog.has(reference_id):
		errors.append("%s 참조가 없습니다: %s" % [label, reference_id])


static func _require_refs(label: String, values, catalog: Dictionary, errors: Array[String]) -> void:
	if not (values is Array):
		errors.append("%s 목록은 Array여야 합니다." % label)
		return
	for value in values:
		_require_ref(label, str(value), catalog, errors)
