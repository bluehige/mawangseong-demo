extends RefCounted
class_name SaveV4ToV5Migrator

const SaveV4MigratorScript = preload("res://scripts/systems/save/SaveV3ToV4Migrator.gd")
const CouncilSeasonServiceScript = preload("res://scripts/systems/campaign/CouncilSeasonService.gd")
const RegionRouteServiceScript = preload("res://scripts/systems/regions/RegionRouteService.gd")
const CouncilVoteLedgerScript = preload("res://scripts/systems/council/CouncilVoteLedger.gd")
const OutpostServiceScript = preload("res://scripts/systems/outpost/OutpostService.gd")

const SOURCE_VERSION := 4
const TARGET_VERSION := 5
const PROFILE_VERSION := 4
const CAMPAIGN_FINAL_DAY := 30
const MODE_NONE := ""
const MODE_FRONT_CHRONICLE := "front_chronicle"
const MODE_COUNCIL_SEASON := "council_season"
const MODE_LEGACY_V4 := "front_chronicle_legacy_v4"
const VALID_MODE_IDS := [MODE_NONE, MODE_FRONT_CHRONICLE, MODE_COUNCIL_SEASON, MODE_LEGACY_V4]
const UPDATE4_ENDING_IDS := ["E17", "E18", "E19", "E20", "E21", "E22"]
const RIVAL_IDS := ["rival_brassa", "rival_vesper", "rival_mirella"]


static func migrate_envelope(v4_envelope: Dictionary, instance_templates: Dictionary, metric_definitions: Dictionary, update3_catalogs: Dictionary = {}, update4_catalogs: Dictionary = {}) -> Dictionary:
	var v4_error := SaveV4MigratorScript.validate_v4(v4_envelope, instance_templates, metric_definitions, update3_catalogs)
	if v4_error != "":
		return {"ok": false, "error": "유효한 저장 v4가 아닙니다: %s" % v4_error, "envelope": {}}
	var envelope := v4_envelope.duplicate(true)
	envelope["version"] = TARGET_VERSION
	envelope["migrated_from_version"] = SOURCE_VERSION
	envelope["profile"] = _migrate_profile(v4_envelope.get("profile", {}))
	envelope["active_run"] = _migrate_active_run(v4_envelope.get("active_run", {}))
	var validation_error := validate_v5(envelope, instance_templates, metric_definitions, update3_catalogs, update4_catalogs)
	if validation_error != "":
		return {"ok": false, "error": validation_error, "envelope": {}}
	return {"ok": true, "error": "", "envelope": envelope}


static func validate_v5(envelope: Dictionary, instance_templates: Dictionary, metric_definitions: Dictionary, update3_catalogs: Dictionary = {}, update4_catalogs: Dictionary = {}) -> String:
	if int(envelope.get("version", 0)) != TARGET_VERSION:
		return "저장 v5 버전이 올바르지 않습니다."
	if int(envelope.get("campaign_final_day", 0)) != CAMPAIGN_FINAL_DAY:
		return "저장 v5의 캠페인 마지막 날이 DAY 30이 아닙니다."
	for key in ["summary", "profile", "active_run"]:
		if not (envelope.get(key) is Dictionary):
			return "저장 v5의 필수 영역이 없습니다: %s" % key
	var active_run: Dictionary = envelope.get("active_run", {})
	var mode_id := str(active_run.get("campaign_mode_id", ""))
	if not mode_id in VALID_MODE_IDS:
		return "등록되지 않은 캠페인 모드입니다: %s" % mode_id
	var v4_error := SaveV4MigratorScript.validate_v4(_v4_compat_envelope(envelope, mode_id), instance_templates, metric_definitions, update3_catalogs)
	if v4_error != "":
		return "저장 v4 호환 자료가 손상되었습니다: %s" % v4_error
	var profile: Dictionary = envelope.get("profile", {})
	if int(profile.get("profile_version", 0)) != PROFILE_VERSION:
		return "저장 v5 프로필 버전이 올바르지 않습니다."
	var profile_error := _validate_profile(profile)
	if profile_error != "":
		return profile_error
	return _validate_active_run(active_run, profile, instance_templates, update4_catalogs)


static func fresh_update4_active_run(mode_id: String, cycle_index: int, cycle_seed: int, v4_active_run: Dictionary = {}) -> Dictionary:
	var result := v4_active_run.duplicate(true)
	result["campaign_mode_id"] = mode_id
	result["cycle_index"] = maxi(1, cycle_index)
	result["cycle_seed"] = maxi(1, cycle_seed)
	result["update3_enabled"] = false
	result["new_cycle_selection_pending"] = mode_id == MODE_NONE
	result["front_selection_completed"] = false
	result["front_id"] = ""
	result["heart"] = _empty_legacy_heart()
	result["heart_event_candidate_id"] = ""
	result["equipped_duo_links"] = []
	result["duo_link_loadout_confirmed"] = false
	result["duo_link_states"] = {}
	result["duo_link_auto_use"] = false
	result["duo_link_active_effects"] = []
	result["duo_link_inactive_count"] = 0
	result["front_flags"] = {}
	result["day28_front_operation"] = ""
	result["rival_finale"] = {"rival_id": "", "phase_state": {}, "retry_seed": 0}
	result["run_metrics_update3"] = {}
	var council := default_council_season()
	var legacy_day := int(result.get("legacy_payload", {}).get("game_state", {}).get("day", 1))
	council["day_state"] = CouncilSeasonServiceScript.new_day_state(legacy_day)
	result["council_season"] = council
	result["outpost"] = default_outpost()
	result["upper_floor"] = default_upper_floor()
	result["crown"] = default_crown()
	result["run_metrics_update4"] = {}
	return result


static func default_council_season() -> Dictionary:
	var relations := {}
	var states := {}
	for rival_id in RIVAL_IDS:
		relations[rival_id] = 0
		states[rival_id] = {}
	return {
		"selected_regions": [], "current_region_index": -1, "region_flags": {},
		"council_votes": 0, "council_seals": 0, "independence": 0,
		"agenda_history": [], "vote_records": [], "promise_violations": [],
		"rival_relations": relations, "rival_states": states,
		"final_representative_id": "", "rival_support_id": "",
		"day_state": CouncilSeasonServiceScript.new_day_state()
	}


static func default_outpost() -> Dictionary:
	return {"type_id": "", "level": 0, "current_hp": 0, "max_hp": 0, "assigned_monster_ids": [], "battle_results": [], "damaged": false, "recovery_used": false, "upgrade_cost_multiplier": 1.0, "support_token_lost": false, "passive_applied": false, "passive_income_bonus": {"gold": 0, "food": 0}, "home_threat_reduction_used": false, "final_vanguard_delay_used": false, "stats": OutpostServiceScript.default_stats()}


static func default_upper_floor() -> Dictionary:
	return {"unlocked": false, "layout_id": "", "objective_hp": {}, "facility_role": "", "seal_theft_count": 0, "graph_runtime": {}, "crown_suppressed": false, "repair_cost_gold": 0}


static func default_crown() -> Dictionary:
	return {"selected_instance_id": "", "crown_form_id": "", "declined": false, "replacement_reward_id": ""}


static func _migrate_profile(value) -> Dictionary:
	var profile: Dictionary = value.duplicate(true) if value is Dictionary else {}
	var any_front_cleared := _any_front_cleared(profile)
	profile["profile_version"] = PROFILE_VERSION
	profile["campaign_modes"] = {
		"update3_any_front_cleared": any_front_cleared,
		"council_season_unlocked": any_front_cleared,
		"council_season_clears": 0,
		"open_council_rule": _has_update3_ending(profile, "E16")
	}
	profile["regions"] = {"discovered_ids": [], "mastery_by_region": {}, "charters_completed": []}
	profile["rivals"] = {"rival_brassa": {}, "rival_vesper": {}, "rival_mirella": {}, "letters_seen": [], "champion_wins": 0}
	profile["crown_evolution"] = {"forms_unlocked": [], "forms_seen": [], "memories_unlocked": []}
	profile["outpost"] = {"types_seen": [], "perfect_defenses": 0}
	profile["update4_endings_seen"] = []
	return profile


static func _migrate_active_run(value) -> Dictionary:
	var active_run: Dictionary = value.duplicate(true) if value is Dictionary else {}
	active_run["campaign_mode_id"] = MODE_LEGACY_V4
	active_run["council_season"] = default_council_season()
	active_run["outpost"] = default_outpost()
	active_run["upper_floor"] = default_upper_floor()
	active_run["crown"] = default_crown()
	active_run["run_metrics_update4"] = {}
	return active_run


static func _validate_profile(profile: Dictionary) -> String:
	for key in ["campaign_modes", "regions", "rivals", "crown_evolution", "outpost"]:
		if not (profile.get(key) is Dictionary):
			return "저장 v5 프로필 영역 형식이 올바르지 않습니다: %s" % key
	var modes: Dictionary = profile.get("campaign_modes", {})
	for key in ["update3_any_front_cleared", "council_season_unlocked", "open_council_rule"]:
		if not (modes.get(key) is bool):
			return "캠페인 모드 해금 상태 형식이 올바르지 않습니다: %s" % key
	if int(modes.get("council_season_clears", -1)) < 0:
		return "의회 회차 완료 횟수는 0 이상이어야 합니다."
	var regions: Dictionary = profile.get("regions", {})
	for key in ["discovered_ids", "charters_completed"]:
		if not _unique_string_array(regions.get(key)):
			return "지역 프로필 목록 형식이 올바르지 않습니다: %s" % key
	if not (regions.get("mastery_by_region") is Dictionary):
		return "지역 숙련 기록 형식이 올바르지 않습니다."
	for value in regions.get("mastery_by_region", {}).values():
		if not _is_number(value) or float(value) < 0.0 or float(value) > 100.0:
			return "지역 숙련도는 0~100이어야 합니다."
	var rivals: Dictionary = profile.get("rivals", {})
	for rival_id in RIVAL_IDS:
		if not (rivals.get(rival_id) is Dictionary):
			return "경쟁 마왕 프로필이 없습니다: %s" % rival_id
	if not _unique_string_array(rivals.get("letters_seen")) or int(rivals.get("champion_wins", -1)) < 0:
		return "경쟁 마왕 서신·승리 기록 형식이 올바르지 않습니다."
	var crown: Dictionary = profile.get("crown_evolution", {})
	for key in ["forms_unlocked", "forms_seen", "memories_unlocked"]:
		if not _unique_string_array(crown.get(key)):
			return "왕관 프로필 목록 형식이 올바르지 않습니다: %s" % key
	var outpost: Dictionary = profile.get("outpost", {})
	if not _unique_string_array(outpost.get("types_seen")) or int(outpost.get("perfect_defenses", -1)) < 0:
		return "전초기지 프로필 기록 형식이 올바르지 않습니다."
	if not _unique_string_array(profile.get("update4_endings_seen")):
		return "Update 4 엔딩 목록 형식이 올바르지 않습니다."
	for ending_id in profile.get("update4_endings_seen", []):
		if not ending_id in UPDATE4_ENDING_IDS:
			return "등록되지 않은 Update 4 엔딩입니다: %s" % ending_id
	return ""


static func _validate_active_run(active_run: Dictionary, profile: Dictionary, instance_templates: Dictionary, catalogs: Dictionary) -> String:
	for key in ["council_season", "outpost", "upper_floor", "crown", "run_metrics_update4"]:
		if not (active_run.get(key) is Dictionary):
			return "저장 v5 현재 회차 영역 형식이 올바르지 않습니다: %s" % key
	var mode_id := str(active_run.get("campaign_mode_id", ""))
	var council: Dictionary = active_run.get("council_season", {})
	if not (council.get("day_state") is Dictionary):
		return "의회 DAY 상태 형식이 올바르지 않습니다."
	var day_state: Dictionary = CouncilSeasonServiceScript.normalize_day_state(council.get("day_state", {}))
	var regions = council.get("selected_regions")
	if not _unique_string_array(regions) or regions.size() > 3:
		return "선택 지역은 중복 없는 최대 3개여야 합니다."
	var region_index := int(council.get("current_region_index", -2))
	if region_index < -1 or (not regions.is_empty() and region_index >= regions.size()):
		return "현재 지역 순서가 선택 지역 범위를 벗어났습니다."
	if mode_id == MODE_COUNCIL_SEASON:
		var region_error := RegionRouteServiceScript.validate_selection_state(active_run, int(active_run.get("legacy_payload", {}).get("game_state", {}).get("day", 1)), catalogs.get("regions", {}))
		if region_error != "":
			return region_error
	for key in ["region_flags", "rival_relations", "rival_states"]:
		if not (council.get(key) is Dictionary):
			return "의회 회차 영역 형식이 올바르지 않습니다: %s" % key
	for key in ["agenda_history", "promise_violations"]:
		if not _unique_string_array(council.get(key)):
			return "의회 회차 목록 형식이 올바르지 않습니다: %s" % key
	if not (council.get("vote_records") is Array) or council.get("vote_records", []).size() != council.get("agenda_history", []).size():
		return "의회 표결 원장 수가 안건 이력과 일치하지 않습니다."
	if mode_id == MODE_COUNCIL_SEASON:
		var vote_error := CouncilVoteLedgerScript.validate_ledger(active_run, catalogs.get("council_agendas", {}))
		if vote_error != "":
			return vote_error
	for key in ["final_representative_id", "rival_support_id"]:
		if not (council.get(key) is String):
			return "의회 대표·지원 ID 형식이 올바르지 않습니다: %s" % key
	for rival_id in RIVAL_IDS:
		if not council.get("rival_relations", {}).has(rival_id) or not council.get("rival_states", {}).has(rival_id):
			return "의회 경쟁 마왕 상태가 없습니다: %s" % rival_id
		var relation = council.get("rival_relations", {}).get(rival_id)
		if not _is_number(relation) or float(relation) < -100.0 or float(relation) > 100.0:
			return "경쟁 마왕 관계는 -100~100이어야 합니다."
	if int(council.get("council_votes", -1)) < 0 or int(council.get("council_votes", 101)) > 100:
		return "의회 표는 0~100이어야 합니다."
	if int(council.get("independence", -1)) < 0 or int(council.get("independence", 101)) > 100:
		return "독립도는 0~100이어야 합니다."
	if int(council.get("council_seals", -1)) < 0 or int(council.get("council_seals", 4)) > 3:
		return "의회 인장은 0~3이어야 합니다."
	var outpost: Dictionary = active_run.get("outpost", {})
	if not (outpost.get("type_id") is String) or int(outpost.get("level", -1)) < 0:
		return "전초기지 유형·레벨 형식이 올바르지 않습니다."
	var current_hp := int(outpost.get("current_hp", -1))
	var max_hp := int(outpost.get("max_hp", -1))
	if current_hp < 0 or max_hp < 0 or current_hp > max_hp:
		return "전초기지 HP가 0~최대 HP 범위를 벗어났습니다."
	if not _unique_string_array(outpost.get("assigned_monster_ids")) or not (outpost.get("battle_results") is Array) or not (outpost.get("damaged") is bool):
		return "전초기지 배치·전투 결과 형식이 올바르지 않습니다."
	for instance_id in outpost.get("assigned_monster_ids", []):
		if not instance_templates.has(instance_id):
			return "등록되지 않은 전초기지 배치 monster instance입니다: %s" % instance_id
	if mode_id == MODE_COUNCIL_SEASON:
		var outpost_error := OutpostServiceScript.validate_state(active_run, int(active_run.get("legacy_payload", {}).get("game_state", {}).get("day", 1)), catalogs.get("outpost_types", {}), instance_templates)
		if outpost_error != "":
			return outpost_error
	var upper: Dictionary = active_run.get("upper_floor", {})
	if not (upper.get("unlocked") is bool) or not (upper.get("layout_id") is String) or not (upper.get("objective_hp") is Dictionary) or not (upper.get("facility_role") is String) or int(upper.get("seal_theft_count", -1)) < 0:
		return "상층 상태 형식이 올바르지 않습니다."
	var day := int(active_run.get("legacy_payload", {}).get("game_state", {}).get("day", 1))
	if mode_id == MODE_COUNCIL_SEASON and int(day_state.get("current_day", 0)) != day:
		return "의회 DAY 상태와 공통 게임 날짜가 일치하지 않습니다."
	if str(day_state.get("phase", "")) == CouncilSeasonServiceScript.PHASE_COMBAT:
		return "진행 중인 의회 전투는 저장할 수 없습니다."
	if bool(upper.get("unlocked", false)) and day < 16:
		return "DAY 16 이전에는 상층을 해금할 수 없습니다."
	for hp_value in upper.get("objective_hp", {}).values():
		if not _is_number(hp_value) or float(hp_value) < 0.0:
			return "상층 목표 HP는 0 이상이어야 합니다."
	var crown: Dictionary = active_run.get("crown", {})
	for key in ["selected_instance_id", "crown_form_id", "replacement_reward_id"]:
		if not (crown.get(key) is String):
			return "왕관 상태 ID 형식이 올바르지 않습니다: %s" % key
	if not (crown.get("declined") is bool):
		return "왕관 거절 상태 형식이 올바르지 않습니다."
	var selected_instance_id := str(crown.get("selected_instance_id", ""))
	var crown_form_id := str(crown.get("crown_form_id", ""))
	if selected_instance_id != "" and not instance_templates.has(selected_instance_id):
		return "등록되지 않은 왕관 대상 monster instance입니다: %s" % selected_instance_id
	if (selected_instance_id == "") != (crown_form_id == ""):
		return "왕관 형태와 monster instance 선택이 일치하지 않습니다."
	if bool(crown.get("declined", false)) and selected_instance_id != "":
		return "왕관을 거절한 회차에는 진화 대상을 저장할 수 없습니다."
	if mode_id == MODE_COUNCIL_SEASON and not bool(profile.get("campaign_modes", {}).get("council_season_unlocked", false)):
		return "해금되지 않은 의회 회차를 시작할 수 없습니다."
	if mode_id == MODE_LEGACY_V4 and (not regions.is_empty() or str(outpost.get("type_id", "")) != "" or bool(upper.get("unlocked", false)) or selected_instance_id != "" or not active_run.get("run_metrics_update4", {}).is_empty()):
		return "진행 중 v4 레거시 회차에는 Update 4 상태를 삽입할 수 없습니다."
	return _validate_catalog_references(active_run, catalogs)


static func _validate_catalog_references(active_run: Dictionary, catalogs: Dictionary) -> String:
	var checks := [
		["regions", active_run.get("council_season", {}).get("selected_regions", [])],
		["council_agendas", active_run.get("council_season", {}).get("agenda_history", [])],
		["outpost_types", [active_run.get("outpost", {}).get("type_id", "")]],
		["upper_floor_layouts", [active_run.get("upper_floor", {}).get("layout_id", "")]],
		["crown_evolutions", [active_run.get("crown", {}).get("crown_form_id", "")]]
	]
	for check in checks:
		var catalog = catalogs.get(check[0], {})
		if not (catalog is Dictionary) or catalog.is_empty():
			continue
		for value in check[1]:
			var id := str(value)
			if id != "" and not catalog.has(id):
				return "등록되지 않은 Update 4 참조입니다: %s/%s" % [check[0], id]
	return ""


static func _v4_compat_envelope(envelope: Dictionary, mode_id: String) -> Dictionary:
	var compat := envelope.duplicate(true)
	compat["version"] = SOURCE_VERSION
	var profile: Dictionary = compat.get("profile", {}).duplicate(true)
	profile["profile_version"] = SaveV4MigratorScript.PROFILE_VERSION
	compat["profile"] = profile
	if mode_id in [MODE_NONE, MODE_COUNCIL_SEASON]:
		var active: Dictionary = compat.get("active_run", {}).duplicate(true)
		active["update3_enabled"] = false
		active["new_cycle_selection_pending"] = true
		active["front_selection_completed"] = false
		active["front_id"] = ""
		active["heart"] = _empty_legacy_heart()
		active["equipped_duo_links"] = []
		compat["active_run"] = active
	return compat


static func _empty_legacy_heart() -> Dictionary:
	return {
		"heart_id": "", "awakened": false, "awakened_day": 0,
		"chamber_spawned": false, "chamber_hp": 0, "chamber_max_hp": 0, "disabled_this_battle": false,
		"charge": 0, "active_used_this_battle": false, "active_remaining": 0.0,
		"room_shields": {}, "battle_charge_dedupe": {}, "battle_id": "",
		"hunger": 0, "hunger_waves": 0, "hunger_finish_ids": {}, "hungry_damage_tokens": {},
		"hungry_infamy_earned": 0, "active_room_id": "", "active_tick_accumulator": 0.0,
		"last_upkeep_day": 0, "dream_charge_dedupe": {}, "false_corridor_targets": {},
		"dream_base_throne_max_hp": 0, "dream_adjusted_throne_max_hp": 0
	}


static func _any_front_cleared(profile: Dictionary) -> bool:
	for value in profile.get("fronts", {}).get("clear_counts", {}).values():
		if int(value) > 0:
			return true
	return not profile.get("update3_endings_seen", []).is_empty()


static func _has_update3_ending(profile: Dictionary, ending_id: String) -> bool:
	return ending_id in profile.get("update3_endings_seen", []) or profile.get("ending_catalog_codes", {}).values().has(ending_id)


static func _unique_string_array(value) -> bool:
	if not (value is Array):
		return false
	var seen := {}
	for item in value:
		if not (item is String) or seen.has(item):
			return false
		seen[item] = true
	return true


static func _is_number(value) -> bool:
	return value is int or value is float
