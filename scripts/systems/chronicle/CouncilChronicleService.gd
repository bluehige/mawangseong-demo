extends RefCounted
class_name CouncilChronicleService

const MAX_RECENT_RUNS := 5
const REGION_ORDER := [
	"region_ironbell_ravine",
	"region_moonbat_aerie",
	"region_mistcap_marsh",
	"region_bone_lantern_fields",
	"region_blackwater_exchange"
]
const RIVAL_ORDER := ["rival_brassa", "rival_vesper", "rival_mirella"]
const CROWN_ORDER := [
	"crown_pudding_royal_bastion",
	"crown_gob_midnight_marshal",
	"crown_pynn_castle_flame_sage",
	"crown_mori_grand_mycelial_priest",
	"crown_toktok_royal_armorer",
	"crown_popo_grand_night_courier"
]
const FLOOR_ONE_KEYS := ["Q", "A", "1"]
const FLOOR_TWO_KEYS := ["E", "D", "2"]


static func default_accessibility() -> Dictionary:
	return {
		"floor_alert_volume": 0.8,
		"hidden_floor_summary": true,
		"high_contrast_icons": false,
		"reduce_region_motion": false,
		"quick_dialogue": false,
		"show_region_details": true,
		"floor_one_key": "Q",
		"floor_two_key": "E"
	}


static func default_state() -> Dictionary:
	return {"recent_runs": [], "recorded_cycle_ids": [], "accessibility": default_accessibility()}


static func normalize_accessibility(value) -> Dictionary:
	var result := default_accessibility()
	if value is Dictionary:
		for key in ["hidden_floor_summary", "high_contrast_icons", "reduce_region_motion", "quick_dialogue", "show_region_details"]:
			if value.get(key) is bool:
				result[key] = value.get(key)
		var volume = value.get("floor_alert_volume", result.floor_alert_volume)
		if volume is float or volume is int:
			result["floor_alert_volume"] = clampf(float(volume), 0.0, 1.0)
		var floor_one := str(value.get("floor_one_key", "Q")).to_upper()
		var floor_two := str(value.get("floor_two_key", "E")).to_upper()
		result["floor_one_key"] = floor_one if floor_one in FLOOR_ONE_KEYS else "Q"
		result["floor_two_key"] = floor_two if floor_two in FLOOR_TWO_KEYS else "E"
	if result.floor_one_key == result.floor_two_key:
		result["floor_one_key"] = "Q"
		result["floor_two_key"] = "E"
	return result


static func normalize_recent_runs(value) -> Array:
	var result: Array = []
	if value is Array:
		for entry_value in value:
			if entry_value is Dictionary and int(entry_value.get("cycle_index", 0)) > 0:
				result.append(entry_value.duplicate(true))
	result.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.get("cycle_index", 0)) < int(b.get("cycle_index", 0)))
	while result.size() > MAX_RECENT_RUNS:
		result.pop_front()
	return result


static func normalize_state(value) -> Dictionary:
	var result := default_state()
	if value is Dictionary:
		result["recent_runs"] = normalize_recent_runs(value.get("recent_runs", []))
		var recorded: Array = []
		if value.get("recorded_cycle_ids") is Array:
			for cycle_value in value.get("recorded_cycle_ids", []):
				var cycle_id := int(cycle_value)
				if cycle_id > 0 and not recorded.has(cycle_id):
					recorded.append(cycle_id)
		recorded.sort()
		result["recorded_cycle_ids"] = recorded
		result["accessibility"] = normalize_accessibility(value.get("accessibility", {}))
	return result


static func record_completed_run(profile_value, active_run_value, cycle_index: int, ending_id: String, context_value = {}, catalogs: Dictionary = {}) -> Dictionary:
	var profile: Dictionary = profile_value.duplicate(true) if profile_value is Dictionary else {}
	var active_run: Dictionary = active_run_value if active_run_value is Dictionary else {}
	var context: Dictionary = context_value if context_value is Dictionary else {}
	if cycle_index < 1 or ending_id.is_empty():
		return profile
	var state := normalize_state(profile.get("chronicle_update4", {}))
	var recorded: Array = state.get("recorded_cycle_ids", [])
	var first_record := not recorded.has(cycle_index)
	if first_record:
		recorded.append(cycle_index)
		recorded.sort()
		state["recorded_cycle_ids"] = recorded
		profile = _record_horizontal_unlocks(profile, active_run, ending_id, catalogs)
	var recent := normalize_recent_runs(state.get("recent_runs", []))
	for index in range(recent.size() - 1, -1, -1):
		if int(recent[index].get("cycle_index", 0)) == cycle_index:
			recent.remove_at(index)
	var ending_catalog: Dictionary = catalogs.get("council_endings", {}) if catalogs.get("council_endings") is Dictionary else {}
	var ending: Dictionary = ending_catalog.get(ending_id, {})
	recent.append(_run_summary(active_run, cycle_index, ending_id, ending, context))
	state["recent_runs"] = normalize_recent_runs(recent)
	profile["chronicle_update4"] = state
	return profile


static func build_view_model(profile_value, catalogs: Dictionary) -> Dictionary:
	var profile: Dictionary = profile_value if profile_value is Dictionary else {}
	var state := normalize_state(profile.get("chronicle_update4", {}))
	var region_catalog: Dictionary = catalogs.get("regions", {}) if catalogs.get("regions") is Dictionary else {}
	var rival_catalog: Dictionary = catalogs.get("rival_lords", {}) if catalogs.get("rival_lords") is Dictionary else {}
	var letter_catalog: Dictionary = catalogs.get("rival_letters", {}) if catalogs.get("rival_letters") is Dictionary else {}
	var crown_catalog: Dictionary = catalogs.get("crown_evolutions", {}) if catalogs.get("crown_evolutions") is Dictionary else {}
	var region_profile: Dictionary = profile.get("regions", {})
	var rival_profile: Dictionary = profile.get("rivals", {})
	var crown_profile: Dictionary = profile.get("crown_evolution", {})
	var result := {
		"regions": [], "rival_letters": [], "crowns": [],
		"recent_runs": normalize_recent_runs(state.get("recent_runs", [])),
		"accessibility": normalize_accessibility(state.get("accessibility", {})),
		"horizontal_only": true
	}
	for region_id in REGION_ORDER:
		var definition: Dictionary = region_catalog.get(region_id, {})
		var mastery := clampi(int(region_profile.get("mastery_by_region", {}).get(region_id, 0)), 0, 3)
		result.regions.append({
			"id": region_id,
			"name": str(definition.get("display_name", region_id)),
			"mastery_level": mastery,
			"discovered": region_profile.get("discovered_ids", []).has(region_id),
			"event_codex_unlocked": mastery >= 1,
			"extra_region_info_unlocked": mastery >= 2,
			"alternate_amendment_unlocked": mastery >= 3,
			"benefit_text": _region_benefit_text(mastery)
		})
	var seen_letters: Array = rival_profile.get("letters_seen", [])
	for rival_id in RIVAL_ORDER:
		var rival: Dictionary = rival_catalog.get(rival_id, {})
		var best_relation := int(rival_profile.get(rival_id, {}).get("best_relation", -100))
		var ids: Array[String] = []
		for letter_id_value in letter_catalog.keys():
			if str(letter_catalog.get(letter_id_value, {}).get("rival_id", "")) == rival_id:
				ids.append(str(letter_id_value))
		ids.sort_custom(func(a: String, b: String): return int(letter_catalog[a].get("unlock_day", 0)) < int(letter_catalog[b].get("unlock_day", 0)))
		for letter_id in ids:
			var letter: Dictionary = letter_catalog.get(letter_id, {})
			result.rival_letters.append({
				"id": letter_id,
				"rival_id": rival_id,
				"rival_name": str(rival.get("display_name", rival_id)),
				"best_relation": best_relation,
				"subject": str(letter.get("subject", "")),
				"body": str(letter.get("body", "")) if seen_letters.has(letter_id) else "",
				"unlocked": seen_letters.has(letter_id),
				"lock_hint": "관계 단계와 의회 결말 기록 필요" if not seen_letters.has(letter_id) else ""
			})
	for crown_id in CROWN_ORDER:
		var definition: Dictionary = crown_catalog.get(crown_id, {})
		var unlocked: bool = crown_profile.get("forms_unlocked", []).has(crown_id)
		var seen: bool = crown_profile.get("forms_seen", []).has(crown_id)
		result.crowns.append({
			"id": crown_id,
			"name": str(definition.get("display_name", crown_id)),
			"role": str(definition.get("role", "")) if seen else "",
			"weakness": str(definition.get("weakness_text", "")) if seen else "",
			"portrait": str(definition.get("portrait", "")) if seen else "",
			"unlocked": unlocked,
			"seen": seen,
			"memory_unlocked": crown_profile.get("memories_unlocked", []).has(crown_id),
			"lock_hint": "왕관 진화를 실제로 선택하면 기록" if not seen else ""
		})
	return result


static func update_accessibility(profile_value, key: String, value) -> Dictionary:
	var profile: Dictionary = profile_value.duplicate(true) if profile_value is Dictionary else {}
	var state := normalize_state(profile.get("chronicle_update4", {}))
	var settings: Dictionary = state.get("accessibility", {}).duplicate(true)
	if settings.has(key):
		settings[key] = value
	state["accessibility"] = normalize_accessibility(settings)
	profile["chronicle_update4"] = state
	return profile


static func _record_horizontal_unlocks(profile: Dictionary, active_run: Dictionary, ending_id: String, catalogs: Dictionary) -> Dictionary:
	var council: Dictionary = active_run.get("council_season", {})
	var regions: Dictionary = profile.get("regions", {}).duplicate(true)
	var discovered: Array = regions.get("discovered_ids", []).duplicate()
	var mastery: Dictionary = regions.get("mastery_by_region", {}).duplicate(true)
	for region_id_value in council.get("selected_regions", []):
		var region_id := str(region_id_value)
		_append_unique(discovered, region_id)
		mastery[region_id] = mini(3, int(mastery.get(region_id, 0)) + 1)
	regions["discovered_ids"] = discovered
	regions["mastery_by_region"] = mastery
	profile["regions"] = regions
	var crown: Dictionary = profile.get("crown_evolution", {}).duplicate(true)
	var crown_form_id := str(active_run.get("crown", {}).get("crown_form_id", ""))
	if not crown_form_id.is_empty():
		for key in ["forms_unlocked", "forms_seen", "memories_unlocked"]:
			var values: Array = crown.get(key, []).duplicate()
			_append_unique(values, crown_form_id)
			crown[key] = values
	profile["crown_evolution"] = crown
	var rivals: Dictionary = profile.get("rivals", {}).duplicate(true)
	var letters_seen: Array = rivals.get("letters_seen", []).duplicate()
	var letter_catalog: Dictionary = catalogs.get("rival_letters", {}) if catalogs.get("rival_letters") is Dictionary else {}
	var representative_id := str(council.get("final_representative_id", ""))
	var support_id := str(council.get("rival_support_id", ""))
	for rival_id in RIVAL_ORDER:
		var rival: Dictionary = rivals.get(rival_id, {}).duplicate(true)
		var relation := int(council.get("rival_relations", {}).get(rival_id, -100))
		rival["best_relation"] = maxi(int(rival.get("best_relation", -100)), relation)
		rivals[rival_id] = rival
		for letter_id_value in letter_catalog.keys():
			var letter: Dictionary = letter_catalog.get(letter_id_value, {})
			if str(letter.get("rival_id", "")) == rival_id and _letter_unlocked(letter, relation, rival_id == representative_id, rival_id == support_id, ending_id):
				_append_unique(letters_seen, str(letter_id_value))
	rivals["letters_seen"] = letters_seen
	profile["rivals"] = rivals
	return profile


static func _letter_unlocked(letter: Dictionary, relation: int, representative: bool, support: bool, ending_id: String) -> bool:
	match str(letter.get("stage", "")):
		"first_measurement": return true
		"first_agenda": return relation >= 0
		"second_agenda": return relation >= 30
		"preview_duel": return relation >= 60 or representative
		"day29_finale": return representative or support or ending_id in ["ending_three_rivals_cosign", "ending_council_dissolved"]
	return false


static func _run_summary(active_run: Dictionary, cycle_index: int, ending_id: String, ending: Dictionary, context: Dictionary) -> Dictionary:
	var council: Dictionary = active_run.get("council_season", {})
	var outpost: Dictionary = active_run.get("outpost", {})
	var upper: Dictionary = active_run.get("upper_floor", {})
	var ending_metrics: Dictionary = active_run.get("run_metrics_update4", {}).get("ending", {})
	return {
		"cycle_index": cycle_index,
		"region_order": council.get("selected_regions", []).duplicate(),
		"outpost_type_id": str(outpost.get("type_id", "")),
		"outpost_survived": bool(context.get("outpost_day20_survived", ending_metrics.get("outpost_day20_survived", outpost.get("stats", {}).get("day20_win", false)))),
		"upper_layout_id": str(upper.get("layout_id", "")),
		"representative_id": str(council.get("final_representative_id", "")),
		"rival_relations": council.get("rival_relations", {}).duplicate(true),
		"crown_form_id": str(active_run.get("crown", {}).get("crown_form_id", "")),
		"council_seals": int(council.get("council_seals", 0)),
		"council_votes": int(council.get("council_votes", 0)),
		"independence": int(council.get("independence", 0)),
		"ending_id": ending_id,
		"ending_code": str(ending.get("catalog_code", context.get("ending_code", ""))),
		"ending_title": str(ending.get("display_name", ending.get("title", ending_id))),
		"day30": {
			"time_seconds": float(context.get("day30_time_seconds", ending_metrics.get("day30_time_seconds", 0.0))),
			"lower_survivors": int(context.get("day30_lower_survivor_count", ending_metrics.get("day30_lower_survivor_count", 0))),
			"upper_survivors": int(context.get("day30_upper_survivor_count", ending_metrics.get("day30_upper_survivor_count", 0))),
			"damage_by_floor": context.get("day30_damage_by_floor", ending_metrics.get("day30_damage_by_floor", {})).duplicate(true)
		}
	}


static func _region_benefit_text(mastery: int) -> String:
	match mastery:
		1: return "사건 도감·지역 장식"
		2: return "사건 도감·지역 장식 · 선택 전 추가 정보"
		3: return "전체 기록 · 대체 의회 수정안·후일담"
		_: return "해당 지역 회차 완료 시 1등급"


static func _append_unique(values: Array, value: String) -> void:
	if not value.is_empty() and not values.has(value):
		values.append(value)
