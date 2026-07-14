extends RefCounted
class_name OutpostService

const MODE_COUNCIL_SEASON := "council_season"
const BUILD_DAY := 4
const UPGRADE_DAY := 12
const RAID_DAYS := [10, 20]
const MAX_ASSIGNED := 3


static func setup_pending(active_run_value, day: int) -> bool:
	return active_run_value is Dictionary and str(active_run_value.get("campaign_mode_id", "")) == MODE_COUNCIL_SEASON and day >= BUILD_DAY and str(active_run_value.get("outpost", {}).get("type_id", "")) == ""


static func build(profile_value, active_run_value, type_id: String, day: int, catalog: Dictionary) -> Dictionary:
	var profile: Dictionary = profile_value.duplicate(true) if profile_value is Dictionary else {}
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	if str(active_run.get("campaign_mode_id", "")) != MODE_COUNCIL_SEASON:
		return _result(false, "마왕 의회 회차에서만 전초기지를 건설할 수 있습니다.", profile, active_run)
	if day < BUILD_DAY:
		return _result(false, "전초기지는 DAY 4부터 건설할 수 있습니다.", profile, active_run)
	if str(active_run.get("outpost", {}).get("type_id", "")) != "":
		return _result(false, "이번 회차에는 이미 전초기지를 건설했습니다.", profile, active_run)
	if not catalog.has(type_id):
		return _result(false, "등록되지 않은 전초기지 유형입니다: %s" % type_id, profile, active_run)
	var definition: Dictionary = catalog.get(type_id, {})
	var max_hp := maxi(1, int(definition.get("base_hp", 1)))
	active_run["outpost"] = {
		"type_id": type_id,
		"level": 1,
		"current_hp": max_hp,
		"max_hp": max_hp,
		"assigned_monster_ids": [],
		"battle_results": [],
		"damaged": false,
		"recovery_used": false,
		"upgrade_cost_multiplier": 1.0,
		"support_token_lost": false
	}
	var outpost_profile: Dictionary = profile.get("outpost", {}).duplicate(true)
	var seen: Array = outpost_profile.get("types_seen", []).duplicate()
	if not seen.has(type_id):
		seen.append(type_id)
	outpost_profile["types_seen"] = seen
	outpost_profile["perfect_defenses"] = maxi(0, int(outpost_profile.get("perfect_defenses", 0)))
	profile["outpost"] = outpost_profile
	return _result(true, "", profile, active_run)


static func assign_monsters(active_run_value, instance_ids_value, owned_instance_ids: Array, instance_catalog: Dictionary) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	if str(active_run.get("outpost", {}).get("type_id", "")) == "":
		return {"ok": false, "error": "전초기지를 먼저 건설해야 합니다.", "active_run": active_run}
	if not (instance_ids_value is Array):
		return {"ok": false, "error": "배치 목록은 Array여야 합니다.", "active_run": active_run}
	var assigned: Array[String] = []
	for value in instance_ids_value:
		var instance_id := str(value)
		if instance_id == "" or assigned.has(instance_id):
			return {"ok": false, "error": "배치 몬스터는 중복 없는 instance ID여야 합니다.", "active_run": active_run}
		if not owned_instance_ids.has(instance_id) or not instance_catalog.has(instance_id):
			return {"ok": false, "error": "보유하지 않은 몬스터는 배치할 수 없습니다: %s" % instance_id, "active_run": active_run}
		assigned.append(instance_id)
	if assigned.size() > MAX_ASSIGNED:
		return {"ok": false, "error": "전초기지에는 몬스터를 최대 3명 배치할 수 있습니다.", "active_run": active_run}
	var outpost: Dictionary = active_run.get("outpost", {}).duplicate(true)
	outpost["assigned_monster_ids"] = assigned
	active_run["outpost"] = outpost
	return {"ok": true, "error": "", "active_run": active_run}


static func upgrade(active_run_value, day: int, catalog: Dictionary) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var outpost: Dictionary = active_run.get("outpost", {}).duplicate(true)
	var type_id := str(outpost.get("type_id", ""))
	if type_id == "" or not catalog.has(type_id):
		return {"ok": false, "error": "건설된 전초기지가 없습니다.", "active_run": active_run}
	if day < UPGRADE_DAY:
		return {"ok": false, "error": "전초기지 Lv.2 강화는 DAY 12부터 가능합니다.", "active_run": active_run}
	if int(outpost.get("level", 0)) >= 2:
		return {"ok": false, "error": "전초기지는 이미 Lv.2입니다.", "active_run": active_run}
	var definition: Dictionary = catalog.get(type_id, {})
	var old_max := maxi(1, int(outpost.get("max_hp", 1)))
	var old_current := clampi(int(outpost.get("current_hp", 0)), 0, old_max)
	var new_max := maxi(old_max, int(definition.get("level_2_hp", old_max)))
	outpost["level"] = 2
	outpost["max_hp"] = new_max
	outpost["current_hp"] = clampi(old_current + (new_max - old_max), 0, new_max)
	active_run["outpost"] = outpost
	return {"ok": true, "error": "", "active_run": active_run}


static func next_raid_day(day: int) -> int:
	for raid_day in RAID_DAYS:
		if day < int(raid_day):
			return int(raid_day)
	return 0


static func validate_state(active_run_value, day: int, catalog: Dictionary, instance_catalog: Dictionary) -> String:
	if not (active_run_value is Dictionary):
		return "전초기지 회차 상태가 Dictionary가 아닙니다."
	var outpost = active_run_value.get("outpost", {})
	if not (outpost is Dictionary):
		return "전초기지 상태가 없습니다."
	var type_id := str(outpost.get("type_id", ""))
	var level := int(outpost.get("level", -1))
	if type_id == "":
		return "" if level == 0 and int(outpost.get("current_hp", -1)) == 0 and int(outpost.get("max_hp", -1)) == 0 else "미건설 전초기지 상태가 초기값이 아닙니다."
	if not catalog.is_empty() and not catalog.has(type_id):
		return "등록되지 않은 전초기지 유형입니다: %s" % type_id
	if level < 1 or level > 2 or (level == 2 and day < UPGRADE_DAY):
		return "전초기지 레벨이 DAY 강화 계약과 맞지 않습니다."
	var max_hp := int(outpost.get("max_hp", -1))
	var current_hp := int(outpost.get("current_hp", -1))
	if max_hp <= 0 or current_hp < 0 or current_hp > max_hp:
		return "전초기지 HP가 0~최대 HP 범위를 벗어났습니다."
	if not (outpost.get("recovery_used", false) is bool) or not (outpost.get("support_token_lost", false) is bool) or float(outpost.get("upgrade_cost_multiplier", 0.0)) < 1.0:
		return "전초기지 복구·강화 상태가 올바르지 않습니다."
	var assigned = outpost.get("assigned_monster_ids", [])
	if not (assigned is Array) or assigned.size() > MAX_ASSIGNED:
		return "전초기지 배치는 최대 3칸이어야 합니다."
	var seen := {}
	for value in assigned:
		var instance_id := str(value)
		if instance_id == "" or seen.has(instance_id) or not instance_catalog.has(instance_id):
			return "전초기지 배치 monster instance가 올바르지 않습니다: %s" % instance_id
		seen[instance_id] = true
	return ""


static func _result(ok: bool, error: String, profile: Dictionary, active_run: Dictionary) -> Dictionary:
	return {"ok": ok, "error": error, "profile": profile, "active_run": active_run}
