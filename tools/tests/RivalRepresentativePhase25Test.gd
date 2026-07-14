extends Node

const RivalScript = preload("res://scripts/systems/council/RivalLordService.gd")
const ModeScript = preload("res://scripts/systems/campaign/CampaignModeService.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_three_representatives()
	_test_competitive_and_lock_notice()
	_test_support_tokens()
	_test_day29_letters()
	if failed:
		print("RIVAL_REPRESENTATIVE_PHASE25_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("RIVAL_REPRESENTATIVE_PHASE25_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _base_run() -> Dictionary:
	var profile := ModeScript.normalize_profile(ModeScript.default_profile(), {"fronts": {"clear_counts": {"front_hero_oath": 1}}})
	return ModeScript.select_mode(profile, ModeScript.new_cycle_active_run(), ModeScript.COUNCIL_MODE_ID, DataRegistry.update4_campaign_modes).active_run


func _test_three_representatives() -> void:
	for rival_id in DataRegistry.update4_rival_lords.keys():
		var active := _base_run()
		for other_id in DataRegistry.update4_rival_lords.keys():
			active = RivalScript.set_relation(active, str(other_id), -70 if str(other_id) == str(rival_id) else 10, DataRegistry.update4_rival_lords).active_run
		var preview := RivalScript.representative_preview(active, DataRegistry.update4_rival_lords, 25)
		_expect(str(preview.rival_id) == str(rival_id) and str(preview.reason) == "lowest_relation", "%s 적대 대표 fixture" % rival_id)


func _test_competitive_and_lock_notice() -> void:
	var active := _base_run()
	active = RivalScript.recompute_competitive_scores(active, DataRegistry.update4_rival_lords, {"rival_brassa": {"region_wins": 1}, "rival_vesper": {"region_wins": 3, "agenda_alignments": 2}, "rival_mirella": {"region_wins": 2}})
	var preview := RivalScript.representative_preview(active, DataRegistry.update4_rival_lords, 25)
	_expect(str(preview.rival_id) == "rival_vesper" and str(preview.reason) == "competitive_score", "우호 결투 competitive score fixture")
	active = RivalScript.set_relation(active, "rival_brassa", 70, DataRegistry.update4_rival_lords).active_run
	var locked := RivalScript.lock_representative(active, DataRegistry.update4_rival_lords, 25)
	var notice := RivalScript.day24_notice(locked.active_run, DataRegistry.update4_rival_lords)
	_expect(bool(locked.ok) and int(notice.day) == 24 and bool(notice.locked) and str(notice.rival_id) == str(locked.preview.rival_id), "DAY 24 대표·지원 공지")
	var changed: Dictionary = RivalScript.set_relation(locked.active_run, str(locked.preview.rival_id), -100, DataRegistry.update4_rival_lords).active_run
	_expect(str(RivalScript.representative_preview(changed, DataRegistry.update4_rival_lords, 999).rival_id) == str(locked.preview.rival_id), "DAY 24 공지 후 대표 변경 방지")


func _support_run(support_id: String) -> Dictionary:
	var active := _base_run()
	active.council_season.final_representative_id = "rival_vesper" if support_id != "rival_vesper" else "rival_brassa"
	active.council_season.rival_support_id = support_id
	active.council_season.rival_support_used = false
	return active


func _test_support_tokens() -> void:
	var brassa := RivalScript.activate_support(_support_run("rival_brassa"), "facility_danger", {"facility_id": "barracks"}, DataRegistry.update4_rival_lords)
	_expect(bool(brassa.ok) and str(brassa.effect.type) == "facility_shield" and float(brassa.effect.duration) == 8.0, "브라사 시설 8초 방호 지원")
	_expect(not bool(RivalScript.activate_support(brassa.active_run, "facility_danger", {"facility_id": "trap"}, DataRegistry.update4_rival_lords).ok), "지원 토큰 전투당 1회 상한")
	var vesper := RivalScript.activate_support(_support_run("rival_vesper"), "objective_channel", {"enemy_id": "dusk_1"}, DataRegistry.update4_rival_lords)
	_expect(bool(vesper.ok) and bool(vesper.effect.cancelled), "베스퍼 목표 채널 1회 취소 지원")
	var mirella := RivalScript.activate_support(_support_run("rival_mirella"), "ally_near_down", {"monster_id": "slime", "hp": 1, "max_hp": 100}, DataRegistry.update4_rival_lords)
	_expect(bool(mirella.ok) and int(mirella.effect.hp) == 20, "미렐라 전투 불능 직전 HP 20% 구조")
	var lost := _support_run("rival_brassa")
	lost.outpost = {"support_token_lost": true}
	_expect(str(RivalScript.activate_support(lost, "facility_danger", {"facility_id": "trap"}, DataRegistry.update4_rival_lords).reason) == "support_token_lost", "DAY 20 전초기지 패배 시 지원 상실")


func _test_day29_letters() -> void:
	var letters := RivalScript.day29_letters(DataRegistry.update4_rival_letters, DataRegistry.update4_rival_lords)
	_expect(letters.size() == 3 and letters.all(func(letter): return int(letter.unlock_day) == 29), "DAY 29 경쟁 마왕 최종 서신 3개")
	_expect(letters.all(func(letter): return bool(letter.codex_only) and not bool(letter.combat_bonus)), "서신은 도감·대사 전용·전투 보너스 없음")


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[RivalRepresentativePhase25] FAIL: %s" % label)
