extends RefCounted
class_name CampaignModeService

const SaveV5MigratorScript = preload("res://scripts/systems/save/SaveV4ToV5Migrator.gd")

const FRONT_MODE_ID := SaveV5MigratorScript.MODE_FRONT_CHRONICLE
const COUNCIL_MODE_ID := SaveV5MigratorScript.MODE_COUNCIL_SEASON
const LEGACY_MODE_ID := SaveV5MigratorScript.MODE_LEGACY_V4
const MODE_IDS := [FRONT_MODE_ID, COUNCIL_MODE_ID]


static func default_profile() -> Dictionary:
	return {
		"campaign_modes": {"update3_any_front_cleared": false, "council_season_unlocked": false, "council_season_clears": 0, "open_council_rule": false},
		"regions": {"discovered_ids": [], "mastery_by_region": {}, "charters_completed": []},
		"rivals": {"rival_brassa": {}, "rival_vesper": {}, "rival_mirella": {}, "letters_seen": [], "champion_wins": 0},
		"crown_evolution": {"forms_unlocked": [], "forms_seen": [], "memories_unlocked": []},
		"outpost": {"types_seen": [], "perfect_defenses": 0},
		"update4_endings_seen": []
	}


static func default_active_run() -> Dictionary:
	return {
		"campaign_mode_id": LEGACY_MODE_ID,
		"council_season": SaveV5MigratorScript.default_council_season(),
		"outpost": SaveV5MigratorScript.default_outpost(),
		"upper_floor": SaveV5MigratorScript.default_upper_floor(),
		"crown": SaveV5MigratorScript.default_crown(),
		"run_metrics_update4": {}
	}


static func new_cycle_active_run() -> Dictionary:
	var result := default_active_run()
	result["campaign_mode_id"] = SaveV5MigratorScript.MODE_NONE
	return result


static func normalize_profile(value, update3_profile: Dictionary = {}) -> Dictionary:
	var result := default_profile()
	if value is Dictionary:
		for key in result.keys():
			if value.has(key) and typeof(value.get(key)) == typeof(result[key]):
				result[key] = value.get(key).duplicate(true) if value.get(key) is Dictionary or value.get(key) is Array else value.get(key)
	var any_front_cleared := _any_front_cleared(update3_profile)
	var modes: Dictionary = result["campaign_modes"].duplicate(true)
	modes["update3_any_front_cleared"] = bool(modes.get("update3_any_front_cleared", false)) or any_front_cleared
	modes["council_season_unlocked"] = bool(modes.get("council_season_unlocked", false)) or any_front_cleared
	modes["open_council_rule"] = bool(modes.get("open_council_rule", false)) or _has_ending_code(update3_profile, "E16")
	result["campaign_modes"] = modes
	return result


static func normalize_active_run(value) -> Dictionary:
	var result := default_active_run()
	if not (value is Dictionary):
		return result
	for key in result.keys():
		if value.has(key) and typeof(value.get(key)) == typeof(result[key]):
			result[key] = value.get(key).duplicate(true) if value.get(key) is Dictionary or value.get(key) is Array else value.get(key)
	var mode_id := str(value.get("campaign_mode_id", LEGACY_MODE_ID))
	result["campaign_mode_id"] = mode_id if mode_id in ["", FRONT_MODE_ID, COUNCIL_MODE_ID, LEGACY_MODE_ID] else LEGACY_MODE_ID
	return result


static func lock_reason(profile_value, mode_id: String, catalog: Dictionary) -> String:
	if not catalog.has(mode_id):
		return "등록되지 않은 회차입니다."
	if mode_id == COUNCIL_MODE_ID:
		var profile := normalize_profile(profile_value)
		if not bool(profile.get("campaign_modes", {}).get("council_season_unlocked", false)):
			return "전선 연대기 중 하나를 DAY 30 승리로 완료하면 해금됩니다."
	return ""


static func select_mode(profile_value, active_run_value, mode_id: String, catalog: Dictionary) -> Dictionary:
	var profile := normalize_profile(profile_value)
	var reason := lock_reason(profile, mode_id, catalog)
	if reason != "":
		return {"ok": false, "error": reason, "profile": profile, "active_run": normalize_active_run(active_run_value)}
	var active_run := normalize_active_run(active_run_value)
	active_run["campaign_mode_id"] = mode_id
	active_run["council_season"] = SaveV5MigratorScript.default_council_season()
	active_run["outpost"] = SaveV5MigratorScript.default_outpost()
	active_run["upper_floor"] = SaveV5MigratorScript.default_upper_floor()
	active_run["crown"] = SaveV5MigratorScript.default_crown()
	active_run["run_metrics_update4"] = {}
	return {"ok": true, "error": "", "profile": profile, "active_run": active_run}


static func start_day(mode_id: String, catalog: Dictionary) -> int:
	return maxi(1, int(catalog.get(mode_id, {}).get("start_day", 1)))


static func _any_front_cleared(profile: Dictionary) -> bool:
	for value in profile.get("fronts", {}).get("clear_counts", {}).values():
		if int(value) > 0:
			return true
	return not profile.get("update3_endings_seen", []).is_empty()


static func _has_ending_code(profile: Dictionary, code: String) -> bool:
	return code in profile.get("update3_endings_seen", []) or profile.get("ending_catalog_codes", {}).values().has(code)
