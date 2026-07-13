extends RefCounted
class_name ValidateUpdate3Content

const DATA_PATHS := {
	"fronts": "res://data/regular_version/update3/fronts.json",
	"front_day_overlays": "res://data/regular_version/update3/front_day_overlays.json",
	"front_operations": "res://data/regular_version/update3/front_operations.json",
	"events": "res://data/regular_version/update3/events.json",
	"castle_hearts": "res://data/regular_version/update3/castle_hearts.json",
	"duo_links": "res://data/regular_version/update3/duo_links.json",
	"monsters": "res://data/regular_version/update3/monsters.json",
	"enemies": "res://data/regular_version/update3/enemies.json",
	"rival_finales": "res://data/regular_version/update3/rival_finales.json",
	"endings": "res://data/regular_version/update3/endings.json",
	"chronicle_goals": "res://data/regular_version/update3/chronicle_goals.json"
}

const REQUIRED_FIELDS := {
	"fronts": ["display_name", "final_rival_id", "final_enemy_id", "enemy_pool_tags", "danger_goals", "recommended_role_tags", "day_overlay_id", "day28_choice_group"],
	"front_day_overlays": ["front_id", "days"],
	"front_operations": ["display_name", "front_id", "choice_group", "day", "description", "reward", "defense_modifier"],
	"events": ["display_name", "day", "kind", "text"],
	"castle_hearts": ["display_name", "passives", "tradeoffs", "charge_sources", "active_skill_id", "max_uses_per_battle", "room_hp_by_stage"],
	"duo_links": ["display_name", "member_instance_ids", "unlock_condition", "gauge_sources", "effect_handler", "max_uses_per_battle"],
	"monsters": ["display_name", "instance_id", "character_id", "skills", "role_tags"],
	"enemies": ["display_name", "character_id", "front_tags", "skills", "behavior_handler"],
	"rival_finales": ["display_name", "front_id", "enemy_id", "character_id", "phases"],
	"endings": ["catalog_code", "priority", "front_required", "condition", "reward_ids", "illustration"],
	"chronicle_goals": ["goal_type", "target_id", "threshold", "reward_ids"]
}


static func load_catalogs() -> Dictionary:
	var catalogs: Dictionary = {}
	var errors: Array[String] = []
	for catalog_name_value in DATA_PATHS.keys():
		var catalog_name := str(catalog_name_value)
		var path := str(DATA_PATHS[catalog_name])
		if not FileAccess.file_exists(path):
			errors.append("3차 데이터 파일이 없습니다: %s" % path)
			catalogs[catalog_name] = {}
			continue
		var parser := JSON.new()
		var parse_error := parser.parse(FileAccess.get_file_as_string(path))
		if parse_error != OK:
			errors.append("3차 JSON 해석 실패: %s line %d (%s)" % [path, parser.get_error_line(), parser.get_error_message()])
			catalogs[catalog_name] = {}
			continue
		if not (parser.data is Dictionary):
			errors.append("3차 JSON 최상위 값은 사전이어야 합니다: %s" % path)
			catalogs[catalog_name] = {}
			continue
		catalogs[catalog_name] = parser.data.duplicate(true)
	return {"ok": errors.is_empty(), "catalogs": catalogs, "errors": errors}


static func validate_catalogs(catalogs: Dictionary, context: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for catalog_name in DATA_PATHS.keys():
		if not (catalogs.get(catalog_name) is Dictionary):
			errors.append("3차 카탈로그 형식이 올바르지 않습니다: %s" % catalog_name)
	_validate_global_ids(catalogs, errors)
	_validate_fronts(catalogs, context, errors)
	_validate_overlays(catalogs, context, errors)
	_validate_front_operations(catalogs, errors)
	_validate_events(catalogs, errors)
	_validate_hearts(catalogs, context, errors)
	_validate_duo_links(catalogs, context, errors)
	_validate_unit_extensions(catalogs, context, errors)
	_validate_rivals(catalogs, context, errors)
	_validate_endings(catalogs, context, errors)
	_validate_chronicle(catalogs, errors)
	return errors


static func _validate_global_ids(catalogs: Dictionary, errors: Array[String]) -> void:
	var owners: Dictionary = {}
	for catalog_name_value in DATA_PATHS.keys():
		var catalog_name := str(catalog_name_value)
		var catalog: Dictionary = catalogs.get(catalog_name, {}) if catalogs.get(catalog_name) is Dictionary else {}
		for entry_id_value in catalog.keys():
			var entry_id := str(entry_id_value)
			if entry_id == "":
				errors.append("%s에 빈 ID가 있습니다." % catalog_name)
			elif owners.has(entry_id):
				errors.append("3차 ID 중복: %s (%s, %s)" % [entry_id, owners[entry_id], catalog_name])
			else:
				owners[entry_id] = catalog_name


static func _validate_fronts(catalogs: Dictionary, context: Dictionary, errors: Array[String]) -> void:
	var fronts: Dictionary = catalogs.get("fronts", {})
	var rivals: Dictionary = catalogs.get("rival_finales", {})
	var overlays: Dictionary = catalogs.get("front_day_overlays", {})
	var enemies := _combined_ids(context.get("enemies", {}), catalogs.get("enemies", {}))
	for front_id in fronts.keys():
		var front = fronts[front_id]
		if not (front is Dictionary):
			errors.append("front 항목 형식 오류: %s" % front_id)
			continue
		_require_fields("front", str(front_id), front, REQUIRED_FIELDS["fronts"], errors)
		for field in ["enemy_pool_tags", "danger_goals", "recommended_role_tags"]:
			if front.has(field) and not _is_string_array(front[field]):
				errors.append("front %s의 %s는 문자열 배열이어야 합니다." % [front_id, field])
		var boss_id := str(front.get("final_enemy_id", ""))
		if boss_id == "":
			errors.append("front DAY 30 보스 누락: %s" % front_id)
		elif not enemies.has(boss_id):
			errors.append("front %s의 DAY 30 적 참조가 없습니다: %s" % [front_id, boss_id])
		var rival_id := str(front.get("final_rival_id", ""))
		if rival_id != "" and not rivals.has(rival_id):
			errors.append("front %s의 라이벌 참조가 없습니다: %s" % [front_id, rival_id])
		var overlay_id := str(front.get("day_overlay_id", ""))
		if overlay_id != "" and not overlays.has(overlay_id):
			errors.append("front %s의 DAY overlay 참조가 없습니다: %s" % [front_id, overlay_id])


static func _validate_overlays(catalogs: Dictionary, context: Dictionary, errors: Array[String]) -> void:
	var overlays: Dictionary = catalogs.get("front_day_overlays", {})
	var fronts: Dictionary = catalogs.get("fronts", {})
	var enemies := _combined_ids(context.get("enemies", {}), catalogs.get("enemies", {}))
	for overlay_id in overlays.keys():
		var overlay = overlays[overlay_id]
		if not (overlay is Dictionary):
			errors.append("front overlay 항목 형식 오류: %s" % overlay_id)
			continue
		_require_fields("front overlay", str(overlay_id), overlay, REQUIRED_FIELDS["front_day_overlays"], errors)
		var front_id := str(overlay.get("front_id", ""))
		if front_id != "" and not fronts.has(front_id):
			errors.append("overlay %s의 front 참조가 없습니다: %s" % [overlay_id, front_id])
		var days = overlay.get("days", {})
		if not (days is Dictionary):
			errors.append("overlay %s의 days는 사전이어야 합니다." % overlay_id)
			continue
		var day30 = days.get("30", {})
		if not (day30 is Dictionary) or str(day30.get("boss_enemy_id", "")) == "":
			errors.append("overlay DAY 30 보스 누락: %s" % overlay_id)
		elif not enemies.has(str(day30.get("boss_enemy_id"))):
			errors.append("overlay %s의 DAY 30 적 참조가 없습니다: %s" % [overlay_id, day30.get("boss_enemy_id")])


static func _validate_hearts(catalogs: Dictionary, context: Dictionary, errors: Array[String]) -> void:
	var hearts: Dictionary = catalogs.get("castle_hearts", {})
	var skills: Dictionary = context.get("skills", {})
	for heart_id in hearts.keys():
		var heart = hearts[heart_id]
		if not (heart is Dictionary):
			errors.append("heart 항목 형식 오류: %s" % heart_id)
			continue
		_require_fields("heart", str(heart_id), heart, REQUIRED_FIELDS["castle_hearts"], errors)
		for field in ["passives", "tradeoffs", "charge_sources"]:
			if heart.has(field) and not (heart[field] is Array):
				errors.append("heart %s의 %s는 배열이어야 합니다." % [heart_id, field])
		var skill_id := str(heart.get("active_skill_id", ""))
		if skill_id != "" and not skills.has(skill_id):
			errors.append("heart %s의 스킬 참조가 없습니다: %s" % [heart_id, skill_id])
		var room_hp = heart.get("room_hp_by_stage", {})
		if room_hp is Dictionary:
			for stage in ["2", "3", "4"]:
				if not room_hp.has(stage) or not _is_number(room_hp[stage]):
					errors.append("heart %s의 Stage %s 심장방 HP가 없습니다." % [heart_id, stage])
		else:
			errors.append("heart %s의 room_hp_by_stage는 사전이어야 합니다." % heart_id)


static func _validate_front_operations(catalogs: Dictionary, errors: Array[String]) -> void:
	var operations: Dictionary = catalogs.get("front_operations", {})
	var fronts: Dictionary = catalogs.get("fronts", {})
	for operation_id in operations.keys():
		var operation = operations[operation_id]
		if not (operation is Dictionary):
			errors.append("front operation 항목 형식 오류: %s" % operation_id)
			continue
		_require_fields("front operation", str(operation_id), operation, REQUIRED_FIELDS["front_operations"], errors)
		if not fronts.has(str(operation.get("front_id", ""))):
			errors.append("front operation %s의 front 참조가 없습니다: %s" % [operation_id, operation.get("front_id")])
		if int(operation.get("day", 0)) != 28:
			errors.append("front operation %s은 DAY 28 작전이어야 합니다." % operation_id)
		var modifier = operation.get("defense_modifier", {})
		if not (modifier is Dictionary) or int(modifier.get("apply_on_day", 0)) != 30:
			errors.append("front operation %s의 효과는 DAY 30에 예약되어야 합니다." % operation_id)


static func _validate_events(catalogs: Dictionary, errors: Array[String]) -> void:
	var events: Dictionary = catalogs.get("events", {})
	var fronts: Dictionary = catalogs.get("fronts", {})
	for event_id in events.keys():
		var event = events[event_id]
		if not (event is Dictionary):
			errors.append("event 항목 형식 오류: %s" % event_id)
			continue
		_require_fields("event", str(event_id), event, REQUIRED_FIELDS["events"], errors)
		var kind := str(event.get("kind", ""))
		if kind != "duo_memory" and not fronts.has(str(event.get("front_id", ""))):
			errors.append("event %s의 front 참조가 없습니다: %s" % [event_id, event.get("front_id")])
		if kind not in ["front_event", "heart_event", "eve_placeholder", "duo_memory"]:
			errors.append("event %s의 kind값이 올바르지 않습니다." % event_id)
		if kind != "eve_placeholder" and not (event.get("choices", []) is Array):
			errors.append("event %s의 choices는 배열이어야 합니다." % event_id)


static func _validate_duo_links(catalogs: Dictionary, context: Dictionary, errors: Array[String]) -> void:
	var links: Dictionary = catalogs.get("duo_links", {})
	var known_members := _combined_ids(context.get("monster_instances", {}), _extension_instances(catalogs.get("monsters", {})))
	var handlers: Array = context.get("duo_effect_handlers", [])
	for link_id in links.keys():
		var link = links[link_id]
		if not (link is Dictionary):
			errors.append("duo link 항목 형식 오류: %s" % link_id)
			continue
		_require_fields("duo link", str(link_id), link, REQUIRED_FIELDS["duo_links"], errors)
		var members = link.get("member_instance_ids", [])
		if not _is_string_array(members) or members.size() != 2 or members[0] == members[1]:
			errors.append("duo link %s는 서로 다른 멤버 2명이 필요합니다." % link_id)
		elif not known_members.has(str(members[0])) or not known_members.has(str(members[1])):
			errors.append("duo member 누락: %s -> %s" % [link_id, members])
		var handler := str(link.get("effect_handler", ""))
		if handler != "" and not handlers.has(handler):
			errors.append("duo link %s의 effect handler가 등록되지 않았습니다: %s" % [link_id, handler])


static func _validate_unit_extensions(catalogs: Dictionary, context: Dictionary, errors: Array[String]) -> void:
	var characters: Dictionary = context.get("characters", {})
	var skills: Dictionary = context.get("skills", {})
	for catalog_name in ["monsters", "enemies"]:
		var catalog: Dictionary = catalogs.get(catalog_name, {})
		for unit_id in catalog.keys():
			var unit = catalog[unit_id]
			if not (unit is Dictionary):
				errors.append("%s 확장 항목 형식 오류: %s" % [catalog_name, unit_id])
				continue
			_require_fields(catalog_name, str(unit_id), unit, REQUIRED_FIELDS[catalog_name], errors)
			var character_id := str(unit.get("character_id", ""))
			if character_id != "" and not characters.has(character_id):
				errors.append("%s %s의 캐릭터 참조가 없습니다: %s" % [catalog_name, unit_id, character_id])
			var skill_ids = unit.get("skills", [])
			if not _is_string_array(skill_ids):
				errors.append("%s %s의 skills는 문자열 배열이어야 합니다." % [catalog_name, unit_id])
			else:
				for skill_id in skill_ids:
					if not skills.has(str(skill_id)):
						errors.append("%s %s의 스킬 참조가 없습니다: %s" % [catalog_name, unit_id, skill_id])
			if catalog_name == "enemies":
				var handler := str(unit.get("behavior_handler", ""))
				var handlers: Array = context.get("enemy_behavior_handlers", [])
				if handler != "" and not handlers.has(handler):
					errors.append("enemy %s의 behavior handler가 등록되지 않았습니다: %s" % [unit_id, handler])


static func _validate_rivals(catalogs: Dictionary, context: Dictionary, errors: Array[String]) -> void:
	var rivals: Dictionary = catalogs.get("rival_finales", {})
	var fronts: Dictionary = catalogs.get("fronts", {})
	var enemies := _combined_ids(context.get("enemies", {}), catalogs.get("enemies", {}))
	var characters: Dictionary = context.get("characters", {})
	for rival_id in rivals.keys():
		var rival = rivals[rival_id]
		if not (rival is Dictionary):
			errors.append("rival finale 항목 형식 오류: %s" % rival_id)
			continue
		_require_fields("rival finale", str(rival_id), rival, REQUIRED_FIELDS["rival_finales"], errors)
		if not fronts.has(str(rival.get("front_id", ""))):
			errors.append("rival %s의 front 참조가 없습니다: %s" % [rival_id, rival.get("front_id")])
		if not enemies.has(str(rival.get("enemy_id", ""))):
			errors.append("rival %s의 적 참조가 없습니다: %s" % [rival_id, rival.get("enemy_id")])
		if not characters.has(str(rival.get("character_id", ""))):
			errors.append("rival %s의 캐릭터 참조가 없습니다: %s" % [rival_id, rival.get("character_id")])
		var phases = rival.get("phases", [])
		if not (phases is Array) or phases.size() != 3:
			errors.append("rival finale %s는 정확히 3단계여야 합니다." % rival_id)


static func _validate_endings(catalogs: Dictionary, context: Dictionary, errors: Array[String]) -> void:
	var endings: Dictionary = catalogs.get("endings", {})
	var fronts: Dictionary = catalogs.get("fronts", {})
	var metrics: Dictionary = context.get("metric_definitions", {})
	var codes: Dictionary = {}
	for ending_id in endings.keys():
		var ending = endings[ending_id]
		if not (ending is Dictionary):
			errors.append("ending 항목 형식 오류: %s" % ending_id)
			continue
		_require_fields("ending", str(ending_id), ending, REQUIRED_FIELDS["endings"], errors)
		var code := str(ending.get("catalog_code", ""))
		if not code in ["E12", "E13", "E14", "E15", "E16"]:
			errors.append("3차 ending code 범위 오류: %s -> %s" % [ending_id, code])
		elif codes.has(code):
			errors.append("3차 ending code 중복: %s" % code)
		else:
			codes[code] = true
		var front_id := str(ending.get("front_required", ""))
		if front_id != "" and not fronts.has(front_id):
			errors.append("ending %s의 front 참조가 없습니다: %s" % [ending_id, front_id])
		_validate_condition_metrics(ending.get("condition", {}), metrics, "ending %s" % ending_id, errors)
		var illustration := str(ending.get("illustration", ""))
		if illustration != "" and not ResourceLoader.exists(illustration) and not FileAccess.file_exists(illustration):
			errors.append("ending %s의 리소스 참조가 없습니다: %s" % [ending_id, illustration])


static func _validate_chronicle(catalogs: Dictionary, errors: Array[String]) -> void:
	var goals: Dictionary = catalogs.get("chronicle_goals", {})
	for goal_id in goals.keys():
		var goal = goals[goal_id]
		if not (goal is Dictionary):
			errors.append("chronicle goal 항목 형식 오류: %s" % goal_id)
			continue
		_require_fields("chronicle goal", str(goal_id), goal, REQUIRED_FIELDS["chronicle_goals"], errors)
		if goal.has("reward_ids") and not _is_string_array(goal.get("reward_ids")):
			errors.append("chronicle goal %s의 reward_ids는 문자열 배열이어야 합니다." % goal_id)


static func _validate_condition_metrics(condition, metrics: Dictionary, label: String, errors: Array[String]) -> void:
	if not (condition is Dictionary):
		errors.append("%s 조건은 사전이어야 합니다." % label)
		return
	for group_key in ["all", "any"]:
		if condition.has(group_key):
			if not (condition[group_key] is Array):
				errors.append("%s의 %s 조건은 배열이어야 합니다." % [label, group_key])
				continue
			for child in condition[group_key]:
				_validate_condition_metrics(child, metrics, label, errors)
	if condition.has("not"):
		_validate_condition_metrics(condition["not"], metrics, label, errors)
	if condition.has("metric"):
		var metric_id := str(condition.get("metric", ""))
		if metric_id == "" or not metrics.has(metric_id):
			errors.append("%s의 ending metric이 없습니다: %s" % [label, metric_id])


static func _require_fields(kind: String, entry_id: String, entry: Dictionary, fields: Array, errors: Array[String]) -> void:
	for field_value in fields:
		var field := str(field_value)
		if not entry.has(field):
			errors.append("%s %s 필수 필드 누락: %s" % [kind, entry_id, field])


static func _combined_ids(base_value, extension_value) -> Dictionary:
	var result: Dictionary = {}
	if base_value is Dictionary:
		for entry_id in base_value.keys():
			result[str(entry_id)] = true
	if extension_value is Dictionary:
		for entry_id in extension_value.keys():
			result[str(entry_id)] = true
	return result


static func _extension_instances(monsters_value) -> Dictionary:
	var result: Dictionary = {}
	if not (monsters_value is Dictionary):
		return result
	for monster in monsters_value.values():
		if monster is Dictionary and str(monster.get("instance_id", "")) != "":
			result[str(monster.get("instance_id"))] = true
	return result


static func _is_string_array(value) -> bool:
	if not (value is Array):
		return false
	for item in value:
		if not (item is String):
			return false
	return true


static func _is_number(value) -> bool:
	return value is int or value is float
