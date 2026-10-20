extends RefCounted
# Output-only cleanup. Raw story/catalog/save identifiers remain authoritative.
const TAGS := ["campaign_main_story_cleared", "chapter_four_clear", "chapter_one_clear", "chapter_three_clear", "chapter_three_supply_route", "chapter_two_started", "day17_security_review_complete", "day18_blockade_broken", "day19_manifest_aftermath", "day19_recovery_team_defeated", "day19_tunnel_aftermath", "day20_castle_upheaval", "day20_engineers_repulsed", "day20_roman_supply_broken", "day21_selen_rally_stopped", "day22_watchtower_intel_secured", "day23_growth_pair_proven", "day23_second_promotion_preview", "day23_second_promotion_unlocked", "day24_leon_route_countered", "day25_leon_rematch_ready", "day25_leon_rematch_won", "day26_official_response_repulsed", "day27_castle_upheaval", "day27_citadel_heart_secured", "day28_citadel_facilities_proven", "day28_final_expedition_locked", "day29_final_preparation_confirmed", "day29_finale_eve_complete", "day30_final_siege_won", "final_chapter_unlocked", "final_upgrade_ready", "first_promotion", "growth_preview", "investigator_class", "leon_mutual_recognition", "nia_security_review_a", "nia_security_review_c", "nia_security_review_d", "nia_security_review_s", "second_promotion_deferred", "selen_boss_clear", "shieldbearer_class", "stage_two_review_day", "stage_two_transition_armed", "stage_two_unlock_blocked", "stage_two_unlock_ready", "stage_two_upgrade_funded", "stage_two_upgrade_unfunded", "stage_two_visual_active", "stage_two_visual_enabled"]
static var stage_pattern: RegEx
static var tag_pattern: RegEx
static func clean(source: String, locale: String, protected_name: String = "") -> String:
	if stage_pattern==null:
		stage_pattern = RegEx.new()
		stage_pattern.compile("(?<![A-Za-z0-9_/:.])(?:Stage[ _]+0?([1-4])|stage_0([1-4])_(?:cave|castle|keep|citadel)|第0?([1-4])阶段)(?![A-Za-z0-9_/.])")
		tag_pattern = RegEx.new()
		tag_pattern.compile("[（(]([a-z][a-z0-9]*(?:_[a-z0-9]+)+)[）)]")
	var pieces := source.split(protected_name) if protected_name!="" else PackedStringArray([source])
	var names := ["신생 마굴","소마왕성","요새 마왕성","대마왕성"]
	if locale=="en": names = ["New Demon Den","Lesser Demon Castle","Fortified Demon Castle","Grand Demon Castle"]
	if locale=="zh_CN": names = ["新生魔窟","小魔王城","要塞魔王城","大魔王城"]
	for i in range(pieces.size()):
		var value: String = pieces[i]
		var matches := stage_pattern.search_all(value)
		matches.reverse()
		for found in matches:
			var index := 0
			for group in range(1,4):
				if found.get_string(group)!="": index = int(found.get_string(group))-1
			value = value.substr(0,found.get_start())+names[index]+value.substr(found.get_end())
		for name in names:
			value = value.replace(name+" "+name,name).replace(name+name,name)
		var flags := tag_pattern.search_all(value)
		flags.reverse()
		for flag in flags:
			if flag.get_string(1) in TAGS: value = value.substr(0,flag.get_start())+value.substr(flag.get_end())
		pieces[i] = value.strip_edges() if value!=pieces[i] else value
	return protected_name.join(pieces) if protected_name!="" else pieces[0]
