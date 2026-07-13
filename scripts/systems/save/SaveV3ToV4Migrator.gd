extends RefCounted
class_name SaveV3ToV4Migrator

const SaveV3MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV2ToV3.gd")

const SOURCE_VERSION := 3
const TARGET_VERSION := 4
const PROFILE_VERSION := 3
const CAMPAIGN_FINAL_DAY := 30
const LEGACY_FRONT_ID := "front_hero_oath_legacy"
const DEFAULT_FRONT_ID := "front_hero_oath"
const DEFAULT_HEART_IDS := ["heart_stonebone", "heart_hungry_maw", "heart_dream_lantern"]


static func migrate_envelope(v3_envelope: Dictionary, instance_templates: Dictionary, metric_definitions: Dictionary, update3_catalogs: Dictionary = {}) -> Dictionary:
	var v3_error := SaveV3MigratorScript.validate_v3(v3_envelope, instance_templates, metric_definitions)
	if v3_error != "":
		return {"ok": false, "error": "유효한 저장 v3가 아닙니다: %s" % v3_error, "envelope": {}}
	var envelope := v3_envelope.duplicate(true)
	envelope["version"] = TARGET_VERSION
	envelope["migrated_from_version"] = SOURCE_VERSION
	envelope["profile"] = _migrate_profile(v3_envelope.get("profile", {}))
	envelope["active_run"] = _legacy_active_run(v3_envelope.get("active_run", {}))
	var validation_error := validate_v4(envelope, instance_templates, metric_definitions, update3_catalogs)
	if validation_error != "":
		return {"ok": false, "error": validation_error, "envelope": {}}
	return {"ok": true, "error": "", "envelope": envelope}


static func validate_v4(envelope: Dictionary, instance_templates: Dictionary, metric_definitions: Dictionary, update3_catalogs: Dictionary = {}) -> String:
	if int(envelope.get("version", 0)) != TARGET_VERSION:
		return "저장 v4 버전이 올바르지 않습니다."
	if int(envelope.get("campaign_final_day", 0)) != CAMPAIGN_FINAL_DAY:
		return "저장 v4의 캠페인 마지막 날이 DAY 30이 아닙니다."
	for key in ["summary", "profile", "active_run"]:
		if not (envelope.get(key) is Dictionary):
			return "저장 v4의 필수 영역이 없습니다: %s" % key

	var v3_compat := envelope.duplicate(true)
	v3_compat["version"] = SOURCE_VERSION
	var v3_profile: Dictionary = v3_compat.get("profile", {}).duplicate(true)
	v3_profile["profile_version"] = 2
	v3_compat["profile"] = v3_profile
	var legacy_error := SaveV3MigratorScript.validate_v3(v3_compat, instance_templates, metric_definitions)
	if legacy_error != "":
		return "저장 v3 호환 자료가 손상되었습니다: %s" % legacy_error

	var profile: Dictionary = envelope.get("profile", {})
	if int(profile.get("profile_version", 0)) != PROFILE_VERSION:
		return "저장 v4 프로필 버전이 올바르지 않습니다."
	for key in ["fronts", "hearts", "duo_links", "rival_relations"]:
		if not (profile.get(key) is Dictionary):
			return "저장 v4 프로필 영역 형식이 올바르지 않습니다: %s" % key
	for key in ["update3_endings_seen", "recent_run_summaries"]:
		if not _string_or_dictionary_array(profile.get(key), key == "recent_run_summaries"):
			return "저장 v4 프로필 목록 형식이 올바르지 않습니다: %s" % key
	if profile.get("recent_run_summaries", []).size() > 5:
		return "최근 회차 요약은 최대 5개입니다."
	var profile_error := _validate_profile_progress(profile)
	if profile_error != "":
		return profile_error

	var active_run: Dictionary = envelope.get("active_run", {})
	for key in ["update3_enabled", "new_cycle_selection_pending", "front_selection_completed"]:
		if not (active_run.get(key) is bool):
			return "저장 v4 현재 회차 상태 형식이 올바르지 않습니다: %s" % key
	for key in ["front_id", "day28_front_operation"]:
		if not (active_run.get(key) is String):
			return "저장 v4 현재 회차 ID 형식이 올바르지 않습니다: %s" % key
	if active_run.has("heart_event_candidate_id") and not (active_run.get("heart_event_candidate_id") is String):
		return "심장 사건 후보 ID 형식이 올바르지 않습니다."
	for key in ["heart", "front_flags", "rival_finale", "run_metrics_update3"]:
		if not (active_run.get(key) is Dictionary):
			return "저장 v4 현재 회차 영역 형식이 올바르지 않습니다: %s" % key
	if not _string_array(active_run.get("equipped_duo_links")):
		return "장착 합동기 목록 형식이 올바르지 않습니다."
	if active_run.get("equipped_duo_links", []).size() > 2 or _has_duplicates(active_run.get("equipped_duo_links", [])):
		return "장착 합동기는 서로 다른 최대 2개입니다."
	if active_run.has("duo_link_loadout_confirmed") and not (active_run.get("duo_link_loadout_confirmed") is bool):
		return "합동기 편성 확정 상태 형식이 올바르지 않습니다."
	if active_run.has("duo_link_states") and not (active_run.get("duo_link_states") is Dictionary):
		return "합동기 전투 상태 형식이 올바르지 않습니다."
	if active_run.has("duo_link_auto_use") and not (active_run.get("duo_link_auto_use") is bool):
		return "합동기 자동 사용 상태 형식이 올바르지 않습니다."
	var heart: Dictionary = active_run.get("heart", {})
	for key in ["awakened", "chamber_spawned", "disabled_this_battle"]:
		if not (heart.get(key) is bool):
			return "심장 상태 형식이 올바르지 않습니다: %s" % key
	if not (heart.get("heart_id") is String):
		return "심장 ID 형식이 올바르지 않습니다."
	for hp_key in ["chamber_hp", "chamber_max_hp"]:
		if not _is_number(heart.get(hp_key)):
			return "심장실 체력 형식이 올바르지 않습니다: %s" % hp_key
	var chamber_hp := int(heart.get("chamber_hp", 0))
	var chamber_max_hp := int(heart.get("chamber_max_hp", 0))
	if chamber_hp < 0 or chamber_max_hp < 0 or chamber_hp > chamber_max_hp:
		return "심장실 체력이 0~최대 체력 범위를 벗어났습니다."
	if bool(heart.get("chamber_spawned", false)) and chamber_max_hp <= 0:
		return "배치된 심장실은 최대 체력이 1 이상이어야 합니다."
	if not bool(heart.get("chamber_spawned", false)) and (chamber_hp != 0 or chamber_max_hp != 0):
		return "배치되지 않은 심장실의 체력은 0이어야 합니다."
	for numeric_key in ["awakened_day", "charge", "active_remaining"]:
		if not _is_number(heart.get(numeric_key)):
			return "심장 수치 형식이 올바르지 않습니다: %s" % numeric_key
	if int(heart.get("charge", 0)) < 0 or int(heart.get("charge", 0)) > 100 or float(heart.get("active_remaining", 0.0)) < 0.0:
		return "심장 충전도는 0~100, 액티브 남은 시간은 0 이상이어야 합니다."
	if not (heart.get("active_used_this_battle") is bool) or not (heart.get("room_shields") is Dictionary) or not (heart.get("battle_charge_dedupe") is Dictionary) or not (heart.get("battle_id") is String):
		return "심장 전투 상태 형식이 올바르지 않습니다."
	for numeric_key in ["hunger", "hunger_waves", "hungry_infamy_earned", "active_tick_accumulator", "last_upkeep_day"]:
		if heart.has(numeric_key) and not _is_number(heart.get(numeric_key)):
			return "포식 심장 상태 수치 형식이 올바르지 않습니다: %s" % numeric_key
	if int(heart.get("hunger", 0)) < 0 or int(heart.get("hunger", 0)) > 4:
		return "포식 심장 hunger는 0~4여야 합니다."
	if int(heart.get("hunger_waves", 0)) < 0 or int(heart.get("hunger_waves", 0)) > 3 or int(heart.get("hungry_infamy_earned", 0)) < 0 or int(heart.get("hungry_infamy_earned", 0)) > 9:
		return "포식 파동은 최대 3회, 보너스 악명은 최대 9입니다."
	if float(heart.get("active_tick_accumulator", 0.0)) < 0.0 or float(heart.get("active_tick_accumulator", 0.0)) >= 1.0 or int(heart.get("last_upkeep_day", 0)) < 0:
		return "포식 심장 시간·일일 유지비 상태가 범위를 벗어났습니다."
	if (heart.has("hunger_finish_ids") and not (heart.get("hunger_finish_ids") is Dictionary)) or (heart.has("hungry_damage_tokens") and not (heart.get("hungry_damage_tokens") is Dictionary)) or (heart.has("active_room_id") and not (heart.get("active_room_id") is String)):
		return "포식 심장 중복 방지·대상 방 상태 형식이 올바르지 않습니다."
	for numeric_key in ["dream_base_throne_max_hp", "dream_adjusted_throne_max_hp"]:
		if heart.has(numeric_key) and (not _is_number(heart.get(numeric_key)) or int(heart.get(numeric_key)) < 0):
			return "몽등 심장 최대 HP 상태가 올바르지 않습니다: %s" % numeric_key
	if (heart.has("dream_charge_dedupe") and not (heart.get("dream_charge_dedupe") is Dictionary)) or (heart.has("false_corridor_targets") and not (heart.get("false_corridor_targets") is Dictionary)):
		return "몽등 심장 중복 방지·가짜 복도 상태 형식이 올바르지 않습니다."
	var rival: Dictionary = active_run.get("rival_finale", {})
	if not (rival.get("rival_id") is String) or not (rival.get("phase_state") is Dictionary) or not _is_number(rival.get("retry_seed")):
		return "라이벌 최종전 상태 형식이 올바르지 않습니다."

	var enabled := bool(active_run.get("update3_enabled", false))
	var selection_pending := bool(active_run.get("new_cycle_selection_pending", false))
	var front_selected := bool(active_run.get("front_selection_completed", false))
	if not enabled:
		if selection_pending:
			if front_selected or str(active_run.get("front_id", "")) != "" or str(heart.get("heart_id", "")) != "":
				return "새 회차 선택 대기 상태에는 전선·심장을 미리 넣을 수 없습니다."
		elif front_selected:
			var front_only_error := _validate_front_only_run(profile, active_run, update3_catalogs)
			if front_only_error != "":
				return front_only_error
		elif str(active_run.get("front_id", "")) != LEGACY_FRONT_ID or str(heart.get("heart_id", "")) != "":
			return "진행 중 v3 변환 회차는 레거시 레온 전선이며 심장이 없어야 합니다."
		if (not front_selected and bool(heart.get("chamber_spawned", false))) or not active_run.get("equipped_duo_links", []).is_empty():
			return "3차 비활성 회차에 심장방 또는 합동기를 넣을 수 없습니다."
	else:
		if selection_pending:
			return "3차 활성 회차는 선택 대기 상태일 수 없습니다."
		var enabled_error := _validate_enabled_run(profile, active_run, update3_catalogs)
		if enabled_error != "":
			return enabled_error
	return ""


static func reset_active_run_for_new_cycle(v4_envelope: Dictionary, cycle_index: int, cycle_seed: int) -> Dictionary:
	var result := v4_envelope.duplicate(true)
	var old_run: Dictionary = result.get("active_run", {})
	var new_run: Dictionary = old_run.duplicate(true)
	new_run["cycle_index"] = maxi(1, cycle_index)
	new_run["cycle_seed"] = maxi(1, cycle_seed)
	new_run["update3_enabled"] = false
	new_run["new_cycle_selection_pending"] = true
	new_run["front_selection_completed"] = false
	new_run["front_id"] = ""
	new_run["heart"] = _empty_heart()
	new_run["heart_event_candidate_id"] = ""
	new_run["equipped_duo_links"] = []
	new_run["duo_link_loadout_confirmed"] = false
	new_run["duo_link_states"] = {}
	new_run["duo_link_auto_use"] = false
	new_run["duo_link_active_effects"] = []
	new_run["duo_link_inactive_count"] = 0
	new_run["front_flags"] = {}
	new_run["day28_front_operation"] = ""
	new_run["rival_finale"] = _empty_rival()
	new_run["run_metrics_update3"] = {}
	result["active_run"] = new_run
	return result


static func _migrate_profile(value) -> Dictionary:
	var profile: Dictionary = value.duplicate(true) if value is Dictionary else {}
	profile["profile_version"] = PROFILE_VERSION
	profile["fronts"] = {
		"unlocked": [DEFAULT_FRONT_ID],
		"clear_counts": {},
		"mastery": {},
		"epilogues_seen": [],
		"invitation_pending": true
	}
	profile["hearts"] = {"unlocked": DEFAULT_HEART_IDS.duplicate(), "mastery": {}, "records": {}, "cosmetics": []}
	profile["duo_links"] = {"unlocked": [], "usage_counts": {}, "first_use_cycle": {}}
	profile["rival_relations"] = {"leon": _migrated_leon_relation(profile), "selen": 0, "roman": 0}
	profile["update3_endings_seen"] = []
	profile["duo_link_preset_slots"] = 0
	profile["duo_link_presets"] = []
	profile["duo_link_auto_recommendation_unlocked"] = false
	profile["front_rotation_unlocked"] = false
	profile["front_rotation_enabled"] = false
	profile["chronicle_final_nameplate"] = false
	profile["recent_run_summaries"] = []
	return profile


static func _legacy_active_run(value) -> Dictionary:
	var active_run: Dictionary = value.duplicate(true) if value is Dictionary else {}
	active_run["update3_enabled"] = false
	active_run["new_cycle_selection_pending"] = false
	active_run["front_selection_completed"] = false
	active_run["front_id"] = LEGACY_FRONT_ID
	active_run["heart"] = _empty_heart()
	active_run["heart_event_candidate_id"] = ""
	active_run["equipped_duo_links"] = []
	active_run["duo_link_loadout_confirmed"] = false
	active_run["duo_link_states"] = {}
	active_run["duo_link_auto_use"] = false
	active_run["duo_link_active_effects"] = []
	active_run["duo_link_inactive_count"] = 0
	active_run["front_flags"] = {}
	active_run["day28_front_operation"] = ""
	active_run["rival_finale"] = {"rival_id": "leon", "phase_state": {}, "retry_seed": 0}
	active_run["run_metrics_update3"] = {}
	return active_run


static func _empty_heart() -> Dictionary:
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


static func _empty_rival() -> Dictionary:
	return {"rival_id": "", "phase_state": {}, "retry_seed": 0}


static func _migrated_leon_relation(profile: Dictionary) -> int:
	var archive: Dictionary = profile.get("ending_archive", {})
	return 45 if archive.has("demon_hero_rival_pact") else 0


static func _validate_profile_progress(profile: Dictionary) -> String:
	var fronts: Dictionary = profile.get("fronts", {})
	var hearts: Dictionary = profile.get("hearts", {})
	var links: Dictionary = profile.get("duo_links", {})
	for pair in [[fronts, ["unlocked", "epilogues_seen"], ["clear_counts", "mastery"]], [hearts, ["unlocked", "cosmetics"], ["mastery"]], [links, ["unlocked"], ["usage_counts", "first_use_cycle"]]]:
		for key in pair[1]:
			if not _string_array(pair[0].get(key)):
				return "3차 프로필 목록 형식이 올바르지 않습니다: %s" % key
		for key in pair[2]:
			if not (pair[0].get(key) is Dictionary):
				return "3차 프로필 누적값 형식이 올바르지 않습니다: %s" % key
	for value in fronts.get("clear_counts", {}).values():
		if not _is_number(value) or float(value) < 0:
			return "전선 클리어 횟수가 올바르지 않습니다."
	for mastery in [fronts.get("mastery", {}), hearts.get("mastery", {})]:
		for value in mastery.values():
			if not _is_number(value) or float(value) < 0 or float(value) > 100:
				return "전선·심장 숙련도는 0~100이어야 합니다."
	if hearts.has("records"):
		if not (hearts.get("records") is Dictionary):
			return "심장 숙련 기록 형식이 올바르지 않습니다."
		for record_value in hearts.get("records", {}).values():
			if not (record_value is Dictionary):
				return "심장 숙련 세부 기록 형식이 올바르지 않습니다."
			if int(record_value.get("selected_count", 0)) < 0 or int(record_value.get("active_uses", 0)) < 0:
				return "심장 선택·액티브 사용 횟수는 0 이상이어야 합니다."
			if not (record_value.get("first_clear", false) is bool) or not (record_value.get("day30_no_chamber_disable", false) is bool):
				return "심장 숙련 달성 기록 형식이 올바르지 않습니다."
	for value in profile.get("rival_relations", {}).values():
		if not _is_number(value) or float(value) < 0 or float(value) > 100:
			return "라이벌 관계는 0~100이어야 합니다."
	return ""


static func _validate_enabled_run(profile: Dictionary, active_run: Dictionary, catalogs: Dictionary) -> String:
	var front_id := str(active_run.get("front_id", ""))
	var heart_id := str(active_run.get("heart", {}).get("heart_id", ""))
	var fronts: Dictionary = catalogs.get("fronts", {}) if catalogs.get("fronts") is Dictionary else {}
	var hearts: Dictionary = catalogs.get("castle_hearts", {}) if catalogs.get("castle_hearts") is Dictionary else {}
	var links: Dictionary = catalogs.get("duo_links", {}) if catalogs.get("duo_links") is Dictionary else {}
	if front_id == "" or not fronts.has(front_id) or not profile.get("fronts", {}).get("unlocked", []).has(front_id):
		return "잠겼거나 존재하지 않는 전선입니다: %s" % front_id
	if heart_id == "" or not hearts.has(heart_id) or not profile.get("hearts", {}).get("unlocked", []).has(heart_id):
		return "잠겼거나 존재하지 않는 심장입니다: %s" % heart_id
	var stage_id := str(active_run.get("legacy_payload", {}).get("world", {}).get("castle_art_stage", "stage_01_cave"))
	if stage_id in ["stage_02_castle", "stage_03_keep", "stage_04_citadel"] and not bool(active_run.get("heart", {}).get("chamber_spawned", false)):
		return "Stage 02 이상 3차 회차에는 heart_chamber 배치가 필요합니다."
	var used_members: Dictionary = {}
	for link_id_value in active_run.get("equipped_duo_links", []):
		var link_id := str(link_id_value)
		if not links.has(link_id) or not profile.get("duo_links", {}).get("unlocked", []).has(link_id):
			return "잠겼거나 존재하지 않는 합동기입니다: %s" % link_id
		var members = links.get(link_id, {}).get("member_instance_ids", [])
		if not (members is Array) or members.size() != 2:
			return "합동기 멤버 계약이 올바르지 않습니다: %s" % link_id
		for member in members:
			if used_members.has(member):
				return "동일 monster instance가 두 합동기에 중복됩니다: %s" % member
			used_members[member] = true
	var expected_rival := str(fronts.get(front_id, {}).get("final_rival_id", ""))
	if expected_rival != "" and str(active_run.get("rival_finale", {}).get("rival_id", "")) != expected_rival:
		return "DAY 30 라이벌과 front_id가 일치하지 않습니다."
	return ""


static func _validate_front_only_run(profile: Dictionary, active_run: Dictionary, catalogs: Dictionary) -> String:
	var front_id := str(active_run.get("front_id", ""))
	var fronts: Dictionary = catalogs.get("fronts", {}) if catalogs.get("fronts") is Dictionary else {}
	if front_id == "" or not fronts.has(front_id) or not profile.get("fronts", {}).get("unlocked", []).has(front_id):
		return "잠겼거나 존재하지 않는 전선입니다: %s" % front_id
	var heart: Dictionary = active_run.get("heart", {})
	if str(heart.get("heart_id", "")) != "":
		return "전선만 선택한 Phase 3 회차에는 심장·심장방을 넣을 수 없습니다."
	var stage_id := str(active_run.get("legacy_payload", {}).get("world", {}).get("castle_art_stage", "stage_01_cave"))
	var chamber_required := stage_id in ["stage_02_castle", "stage_03_keep", "stage_04_citadel"]
	if chamber_required != bool(heart.get("chamber_spawned", false)):
		return "Stage 02 이상에서만 심장실이 배치되어야 합니다."
	if not active_run.get("equipped_duo_links", []).is_empty():
		return "전선만 선택한 Phase 3 회차에는 합동기를 넣을 수 없습니다."
	var expected_rival := str(fronts.get(front_id, {}).get("final_rival_id", ""))
	if expected_rival == "" or str(active_run.get("rival_finale", {}).get("rival_id", "")) != expected_rival:
		return "선택한 전선과 최종 라이벌이 일치하지 않습니다."
	return ""


static func _string_array(value) -> bool:
	if not (value is Array):
		return false
	for item in value:
		if not (item is String):
			return false
	return true


static func _string_or_dictionary_array(value, dictionaries: bool) -> bool:
	if not (value is Array):
		return false
	for item in value:
		if dictionaries and not (item is Dictionary):
			return false
		if not dictionaries and not (item is String):
			return false
	return true


static func _has_duplicates(values: Array) -> bool:
	var seen: Dictionary = {}
	for value in values:
		if seen.has(value):
			return true
		seen[value] = true
	return false


static func _is_number(value) -> bool:
	return value is int or value is float
