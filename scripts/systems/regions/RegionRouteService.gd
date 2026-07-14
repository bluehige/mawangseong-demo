extends RefCounted
class_name RegionRouteService

const MODE_COUNCIL_SEASON := "council_season"
const SELECTION_DAYS := [4, 11, 21]
const MAX_SELECTED_REGIONS := 3


static func selected_region_ids(active_run_value) -> Array[String]:
	var result: Array[String] = []
	if not (active_run_value is Dictionary):
		return result
	var council = active_run_value.get("council_season", {})
	if not (council is Dictionary):
		return result
	for value in council.get("selected_regions", []):
		var region_id := str(value)
		if region_id != "" and not result.has(region_id):
			result.append(region_id)
	return result


static func selection_slot_for_day(day: int) -> int:
	return SELECTION_DAYS.find(day)


static func selection_day_for_slot(slot: int) -> int:
	return int(SELECTION_DAYS[slot]) if slot >= 0 and slot < SELECTION_DAYS.size() else 0


static func allowed_selection_count(day: int) -> int:
	var count := 0
	for selection_day in SELECTION_DAYS:
		if day >= int(selection_day):
			count += 1
	return count


static func pending_selection_slot(active_run_value, day: int) -> int:
	if not (active_run_value is Dictionary) or str(active_run_value.get("campaign_mode_id", "")) != MODE_COUNCIL_SEASON:
		return -1
	var selected := selected_region_ids(active_run_value)
	if selected.size() >= MAX_SELECTED_REGIONS:
		return -1
	var slot := selected.size()
	return slot if day >= selection_day_for_slot(slot) else -1


static func selection_pending(active_run_value, day: int) -> bool:
	return pending_selection_slot(active_run_value, day) >= 0


static func available_region_ids(active_run_value, catalog: Dictionary) -> Array[String]:
	var selected := selected_region_ids(active_run_value)
	var result: Array[String] = []
	for region_id_value in catalog.keys():
		var region_id := str(region_id_value)
		if not selected.has(region_id):
			result.append(region_id)
	result.sort()
	return result


static func select_region(profile_value, active_run_value, region_id: String, day: int, catalog: Dictionary) -> Dictionary:
	var profile: Dictionary = profile_value.duplicate(true) if profile_value is Dictionary else {}
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	if str(active_run.get("campaign_mode_id", "")) != MODE_COUNCIL_SEASON:
		return _result(false, "마왕 의회 회차에서만 지역을 선택할 수 있습니다.", profile, active_run)
	if not catalog.has(region_id):
		return _result(false, "등록되지 않은 지역입니다: %s" % region_id, profile, active_run)
	var selected := selected_region_ids(active_run)
	if selected.has(region_id):
		return _result(false, "이번 회차에 이미 선택한 지역입니다.", profile, active_run)
	var slot := pending_selection_slot(active_run, day)
	if slot < 0:
		return _result(false, "DAY %d에는 새 지역 선택 슬롯이 없습니다." % day, profile, active_run)
	selected.append(region_id)
	var council: Dictionary = active_run.get("council_season", {}).duplicate(true)
	council["selected_regions"] = selected
	council["current_region_index"] = slot
	active_run["council_season"] = council
	var region_profile: Dictionary = profile.get("regions", {}).duplicate(true)
	var discovered: Array = region_profile.get("discovered_ids", []).duplicate()
	if not discovered.has(region_id):
		discovered.append(region_id)
	region_profile["discovered_ids"] = discovered
	if not (region_profile.get("mastery_by_region") is Dictionary):
		region_profile["mastery_by_region"] = {}
	if not (region_profile.get("charters_completed") is Array):
		region_profile["charters_completed"] = []
	profile["regions"] = region_profile
	return _result(true, "", profile, active_run)


static func current_region_id(active_run_value) -> String:
	var selected := selected_region_ids(active_run_value)
	if selected.is_empty():
		return ""
	var council: Dictionary = active_run_value.get("council_season", {})
	var index := clampi(int(council.get("current_region_index", selected.size() - 1)), 0, selected.size() - 1)
	return selected[index]


static func validate_selection_state(active_run_value, day: int, catalog: Dictionary) -> String:
	if not (active_run_value is Dictionary):
		return "지역 경로 회차 상태가 Dictionary가 아닙니다."
	var selected := selected_region_ids(active_run_value)
	var raw_selected = active_run_value.get("council_season", {}).get("selected_regions", [])
	if not (raw_selected is Array) or selected.size() != raw_selected.size():
		return "선택 지역은 중복 없는 문자열 목록이어야 합니다."
	if selected.size() > allowed_selection_count(day):
		return "DAY %d에 허용된 지역 선택 수를 초과했습니다." % day
	for region_id in selected:
		if not catalog.is_empty() and not catalog.has(region_id):
			return "등록되지 않은 지역이 선택 기록에 있습니다: %s" % region_id
	var index := int(active_run_value.get("council_season", {}).get("current_region_index", -1))
	if selected.is_empty() and index != -1:
		return "지역을 선택하지 않은 회차의 현재 지역 순서는 -1이어야 합니다."
	if not selected.is_empty() and index != selected.size() - 1:
		return "현재 지역 순서는 마지막 선택 슬롯과 일치해야 합니다."
	return ""


static func ordered_route_count(catalog: Dictionary) -> int:
	var count := catalog.size()
	return count * (count - 1) * (count - 2) if count >= MAX_SELECTED_REGIONS else 0


static func selection_summary(active_run_value, catalog: Dictionary) -> String:
	var labels: Array[String] = []
	for region_id in selected_region_ids(active_run_value):
		labels.append(str(catalog.get(region_id, {}).get("display_name", region_id)))
	return " → ".join(labels)


static func _result(ok: bool, error: String, profile: Dictionary, active_run: Dictionary) -> Dictionary:
	return {"ok": ok, "error": error, "profile": profile, "active_run": active_run}
