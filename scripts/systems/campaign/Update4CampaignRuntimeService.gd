extends RefCounted
class_name Update4CampaignRuntimeService

const RegionContentScript = preload("res://scripts/systems/regions/RegionContentService.gd")
const RivalLordScript = preload("res://scripts/systems/council/RivalLordService.gd")
const BrassaBossScript = preload("res://scripts/systems/bosses/BrassaBossBattleService.gd")
const VesperBossScript = preload("res://scripts/systems/bosses/VesperBossBattleService.gd")
const MirellaBossScript = preload("res://scripts/systems/bosses/MirellaBossBattleService.gd")

const VOTE_DAYS := [13, 22, 26]
const RIVAL_BATTLE_DAYS := [25, 30]
const REGION_SETTLEMENT_DAYS := {10: 1, 20: 2, 28: 3}


static func required_choice_id(active_run_value, day: int) -> String:
	if not (active_run_value is Dictionary):
		return ""
	var council: Dictionary = active_run_value.get("council_season", {})
	if day in VOTE_DAYS:
		for record_value in council.get("vote_records", []):
			if record_value is Dictionary and int(record_value.get("day", 0)) == day:
				return ""
		return "council_vote"
	if day == 23 and str(council.get("crown_form_id", "")) == "" and not bool(council.get("crown_declined", false)):
		return "crown_choice"
	if day == 29 and str(council.get("day29_decision_id", "")) == "":
		return "council_final_declaration"
	if day >= 16:
		var upper: Dictionary = active_run_value.get("upper_floor", {})
		if bool(upper.get("unlocked", false)) and str(upper.get("layout_id", "")) == "":
			return "upper_layout"
	if day >= 24 and str(council.get("final_representative_id", "")) == "":
		return "representative_lock"
	return ""


static func wave_catalog_for_day(active_run_value, day: int, templates: Dictionary, rival_catalog: Dictionary, legacy_waves: Dictionary) -> Dictionary:
	var key := "day_%d" % day
	var entries: Array = []
	var route := _selected_regions(active_run_value)
	if route.is_empty():
		entries = legacy_waves.get(key, []).duplicate(true)
	else:
		var slot := clampi(int(active_run_value.get("council_season", {}).get("current_region_index", route.size() - 1)) + 1, 1, 3)
		var region_id := route[clampi(slot - 1, 0, route.size() - 1)]
		var template := RegionContentScript.wave_for_chapter(region_id, slot, templates)
		entries = _wave_entries(template, day)
	if day in RIVAL_BATTLE_DAYS:
		var boss_id := rival_boss_enemy_id(active_run_value, rival_catalog)
		if boss_id != "":
			entries.append({
				"enemy_id": boss_id,
				"count": 1,
				"spawn_delay": 8.0 if day == 25 else 6.0,
				"spawn_interval": 1.0,
				"hp_scale": 0.75 if day == 25 else 1.0,
				"atk_scale": 0.90 if day == 25 else 1.0,
				"reward_scale": 1.0
			})
	return {key: entries}


static func rival_boss_enemy_id(active_run_value, rival_catalog: Dictionary) -> String:
	if not (active_run_value is Dictionary):
		return ""
	var rival_id := str(active_run_value.get("council_season", {}).get("final_representative_id", ""))
	return str(rival_catalog.get(rival_id, {}).get("boss_enemy_id", ""))


static func record_battle_metrics(active_run_value, day: int, battle_metrics: Dictionary) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var council: Dictionary = active_run.get("council_season", {}).duplicate(true)
	var chapter_metrics: Dictionary = council.get("region_chapter_metrics", {}).duplicate(true)
	var slot := clampi(int(council.get("current_region_index", 0)) + 1, 1, 3)
	var metrics: Dictionary = chapter_metrics.get(str(slot), {}).duplicate(true)
	metrics["facility_disables"] = int(metrics.get("facility_disables", 0)) + maxi(0, int(battle_metrics.get("facility_disables", 0)))
	metrics["treasure_loss"] = int(metrics.get("treasure_loss", 0)) + maxi(0, int(battle_metrics.get("treasure_loss", 0)))
	metrics["seal_thefts"] = int(metrics.get("seal_thefts", 0)) + maxi(0, int(battle_metrics.get("seal_thefts", 0)))
	metrics["down_count"] = int(metrics.get("down_count", 0)) + maxi(0, int(battle_metrics.get("down_count", 0)))
	metrics["distinct_duo_links"] = maxi(int(metrics.get("distinct_duo_links", 0)), int(battle_metrics.get("distinct_duo_links", 0)))
	metrics["security_grade"] = str(battle_metrics.get("security_grade", metrics.get("security_grade", "")))
	metrics["last_battle_day"] = day
	chapter_metrics[str(slot)] = metrics
	council["region_chapter_metrics"] = chapter_metrics
	active_run["council_season"] = council
	return active_run


static func settle_region_chapter(profile_value, active_run_value, slot: int, region_catalog: Dictionary) -> Dictionary:
	var profile: Dictionary = profile_value.duplicate(true) if profile_value is Dictionary else {}
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var council: Dictionary = active_run.get("council_season", {}).duplicate(true)
	var settled: Array = council.get("settled_region_slots", []).duplicate()
	if slot < 1 or slot > 3 or settled.has(slot):
		return {"ok": false, "error": "이미 정산했거나 유효하지 않은 지역 순서입니다.", "profile": profile, "active_run": active_run}
	var route := _selected_regions(active_run)
	if route.size() < slot:
		return {"ok": false, "error": "정산할 지역이 선택되지 않았습니다.", "profile": profile, "active_run": active_run}
	var region_id := route[slot - 1]
	var region: Dictionary = region_catalog.get(region_id, {})
	var metrics: Dictionary = council.get("region_chapter_metrics", {}).get(str(slot), {})
	var charter_completed := RegionContentScript.charter_completed(region, metrics)
	var regions: Dictionary = profile.get("regions", {}).duplicate(true)
	var charter_ids: Array = regions.get("charters_completed", []).duplicate()
	if charter_completed and not charter_ids.has(region_id):
		charter_ids.append(region_id)
	regions["charters_completed"] = charter_ids
	profile["regions"] = regions
	if charter_completed:
		council["council_seals"] = mini(3, int(council.get("council_seals", 0)) + 1)
	else:
		# 실패한 헌장도 DAY 23을 막지 않도록 전투력이 아닌 대체 인장을 준다.
		council["alternative_seal_resource"] = int(council.get("alternative_seal_resource", 0)) + 2
	var flags: Dictionary = council.get("region_flags", {}).duplicate(true)
	var region_flags: Dictionary = flags.get(region_id, {}).duplicate(true)
	region_flags["charter_completed"] = charter_completed
	region_flags["settled_slot"] = slot
	flags[region_id] = region_flags
	council["region_flags"] = flags
	settled.append(slot)
	council["settled_region_slots"] = settled
	active_run["council_season"] = council
	return {"ok": true, "error": "", "profile": profile, "active_run": active_run, "region_id": region_id, "charter_completed": charter_completed}


static func lock_representative(active_run_value, rival_catalog: Dictionary, region_catalog: Dictionary, cycle_seed: int) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var rival_metrics := {}
	for rival_id_value in rival_catalog.keys():
		rival_metrics[str(rival_id_value)] = {"region_wins": 0, "agenda_alignments": 0, "objective_pressure": 0, "preview_duel_wins": 0}
	for region_id in _selected_regions(active_run):
		var rival_id := str(region_catalog.get(region_id, {}).get("rival_id", ""))
		if rival_metrics.has(rival_id):
			rival_metrics[rival_id]["region_wins"] = int(rival_metrics[rival_id].get("region_wins", 0)) + 1
	active_run = RivalLordScript.recompute_competitive_scores(active_run, rival_catalog, rival_metrics)
	return RivalLordScript.lock_representative(active_run, rival_catalog, cycle_seed)


static func resolve_rival_battle(active_run_value, day: int, won: bool, rival_catalog: Dictionary, battle_stats: Dictionary = {}) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var rival_id := str(active_run.get("council_season", {}).get("final_representative_id", ""))
	match rival_id:
		"rival_brassa": return BrassaBossScript.resolve_battle(active_run, day, won, battle_stats)
		"rival_vesper": return VesperBossScript.resolve_battle(active_run, day, won, battle_stats)
		"rival_mirella": return MirellaBossScript.resolve_battle(active_run, day, won, battle_stats)
	return {"active_run": active_run, "won": won, "retry_day": 0 if won else day, "return_screen": "settlement" if won else "management"}


static func settlement_slot_for_day(day: int) -> int:
	return int(REGION_SETTLEMENT_DAYS.get(day, 0))


static func _wave_entries(template: Dictionary, day: int) -> Array:
	var result: Array = []
	var enemy_ids: Array = template.get("enemy_counts", {}).keys()
	enemy_ids.sort()
	for index in enemy_ids.size():
		var enemy_id := str(enemy_ids[index])
		result.append({
			"enemy_id": enemy_id,
			"count": int(template.get("enemy_counts", {}).get(enemy_id, 0)),
			"spawn_delay": 4.0 + float(index) * 3.0,
			"spawn_interval": 2.0,
			"hp_scale": 1.0,
			"atk_scale": 1.0,
			"reward_scale": 1.0,
			"update4_region_id": str(template.get("region_id", "")),
			"update4_chapter_slot": int(template.get("chapter_slot", 0)),
			"update4_floor_pattern": str(template.get("floor_pattern", "")),
			"update4_day": day
		})
	return result


static func _selected_regions(active_run_value) -> Array[String]:
	var result: Array[String] = []
	if not (active_run_value is Dictionary):
		return result
	for value in active_run_value.get("council_season", {}).get("selected_regions", []):
		var region_id := str(value)
		if region_id != "":
			result.append(region_id)
	return result
