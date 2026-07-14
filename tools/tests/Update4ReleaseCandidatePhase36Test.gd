extends Node

const CampaignModeScript = preload("res://scripts/systems/campaign/CampaignModeService.gd")
const CouncilSeasonScript = preload("res://scripts/systems/campaign/CouncilSeasonService.gd")
const RuntimeScript = preload("res://scripts/systems/campaign/Update4CampaignRuntimeService.gd")
const RegionRouteScript = preload("res://scripts/systems/regions/RegionRouteService.gd")
const OutpostScript = preload("res://scripts/systems/outpost/OutpostService.gd")
const MultiFloorScript = preload("res://scripts/systems/multifloor/MultiFloorGraphService.gd")
const UpperFloorScript = preload("res://scripts/systems/multifloor/UpperFloorObjectiveService.gd")
const CouncilVoteScript = preload("res://scripts/systems/council/CouncilVoteLedger.gd")
const CrownScript = preload("res://scripts/systems/crown/CrownEvolutionService.gd")
const CouncilEndingScript = preload("res://scripts/systems/endings/CouncilEndingService.gd")
const DecisionOverlayScript = preload("res://scripts/ui/Update4CouncilDecisionOverlay.gd")
const GameRootScript = preload("res://scripts/game/GameRoot.gd")

const ROUTE := [
	"region_ironbell_ravine",
	"region_moonbat_aerie",
	"region_mistcap_marsh"
]
const VOTE_DAYS := [13, 22, 26]

var failed := false
var assertion_count := 0
var profile: Dictionary = {}
var active_run: Dictionary = {}
var day_state: Dictionary = {}


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_day4_management_gate()
	_test_full_thirty_day_runtime()
	_test_all_rival_boss_routes()
	await _test_decision_overlays()
	if failed:
		print("UPDATE4_RELEASE_CANDIDATE_PHASE36_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("UPDATE4_RELEASE_CANDIDATE_PHASE36_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_day4_management_gate() -> void:
	var fixture := _fresh_council_run()
	var gate_profile: Dictionary = fixture.get("profile", {})
	var gate_active: Dictionary = fixture.get("active_run", {})
	var root = GameRootScript.new()
	var previous_day := GameState.day
	GameState.day = 4
	root.update4_active_run = gate_active
	_expect(root._update4_management_only_setup_screen() == Constants.SCREEN_REGION_SELECTION, "DAY 4 blocks settlement until a region is selected")
	var selected := RegionRouteScript.select_region(gate_profile, gate_active, ROUTE[0], 4, DataRegistry.update4_regions)
	gate_profile = selected.get("profile", {})
	gate_active = selected.get("active_run", {})
	root.update4_active_run = gate_active
	_expect(root._update4_management_only_setup_screen() == Constants.SCREEN_OUTPOST_MANAGEMENT, "DAY 4 blocks settlement until an outpost is built")
	var outpost_ids := DataRegistry.update4_outpost_types.keys()
	outpost_ids.sort()
	var built := OutpostScript.build(gate_profile, gate_active, str(outpost_ids[0]), 4, DataRegistry.update4_outpost_types)
	root.update4_active_run = built.get("active_run", {})
	_expect(bool(built.get("ok", false)) and root._update4_management_only_setup_screen() == "", "DAY 4 setup gate clears after region and outpost choices")
	GameState.day = previous_day
	root.free()


func _test_full_thirty_day_runtime() -> void:
	var fixture := _fresh_council_run()
	profile = fixture.get("profile", {})
	active_run = fixture.get("active_run", {})
	active_run["cycle_index"] = 4
	day_state = CouncilSeasonScript.new_day_state(1)
	var root = GameRootScript.new()
	var battle_days := 0
	for day in range(1, 31):
		_expect(int(day_state.get("current_day", 0)) == day, "DAY %02d enters the expected state" % day)
		_resolve_required_day_action(day)
		_expect(RuntimeScript.required_choice_id(active_run, day) == "", "DAY %02d has no unresolved mandatory council choice" % day)
		var ready := CouncilSeasonScript.finish_management(day_state, DataRegistry.update4_council_campaign_days)
		_expect(bool(ready.get("ok", false)), "DAY %02d management completes" % day)
		day_state = ready.get("state", {})
		if CouncilSeasonScript.is_management_only(DataRegistry.update4_council_campaign_days, day):
			_expect(str(day_state.get("phase", "")) == CouncilSeasonScript.PHASE_DAY_COMPLETE, "DAY %02d remains combat-free" % day)
		else:
			battle_days += 1
			var wave_catalog := RuntimeScript.wave_catalog_for_day(active_run, day, DataRegistry.update4_council_wave_templates, DataRegistry.update4_rival_lords, DataRegistry.waves)
			var entries: Array = wave_catalog.get("day_%d" % day, [])
			_expect(not entries.is_empty(), "DAY %02d resolves a playable wave" % day)
			root.update4_active_run = active_run
			var root_entries: Array = root._active_wave_catalog(day).get("day_%d" % day, [])
			_expect(root_entries == entries, "DAY %02d GameRoot uses the Update 4 wave catalog" % day)
			if day in RuntimeScript.RIVAL_BATTLE_DAYS:
				var boss_id := RuntimeScript.rival_boss_enemy_id(active_run, DataRegistry.update4_rival_lords)
				_expect(entries.any(func(entry): return entry is Dictionary and str(entry.get("enemy_id", "")) == boss_id), "DAY %02d includes the locked rival boss" % day)
			var started := CouncilSeasonScript.begin_combat(day_state, DataRegistry.update4_council_campaign_days)
			_expect(bool(started.get("ok", false)), "DAY %02d combat starts" % day)
			var completed := CouncilSeasonScript.complete_combat(started.get("state", {}))
			_expect(bool(completed.get("ok", false)), "DAY %02d combat completes" % day)
			day_state = completed.get("state", {})
		_settle_region_if_due(day)
		_sync_day_state()
		if day < 30:
			var advanced := CouncilSeasonScript.advance_day(day_state, DataRegistry.update4_council_campaign_days)
			_expect(bool(advanced.get("ok", false)), "DAY %02d advances" % day)
			day_state = advanced.get("state", {})
			_sync_day_state()
	_expect(battle_days == 28, "the council season contains 28 playable battle days")
	_expect(active_run.get("council_season", {}).get("settled_region_slots", []) == [1, 2, 3], "all three region chapters settle in order")
	var final_context := {
		"final_battle_won": true,
		"completed_region_ids": ROUTE.duplicate(),
		"cycle_index": 4,
		"outpost_day20_survived": true,
		"day30_lower_survivor_count": 3,
		"day30_upper_survivor_count": 2,
		"day30_time_seconds": 300.0,
		"day30_damage_by_floor": {"1F": 100.0, "2F": 50.0}
	}
	var representative_id := str(active_run.get("council_season", {}).get("final_representative_id", ""))
	var finalized := CouncilEndingScript.finalize_day30(profile, active_run, final_context, DataRegistry.update4_council_endings, DataRegistry.update4_catalogs)
	profile = finalized.get("profile", {})
	active_run = finalized.get("active_run", {})
	_expect(bool(finalized.get("ok", false)) and str(finalized.get("ending_id", "")) != "", "DAY 30 resolves a council ending or the local fallback")
	_expect(int(profile.get("campaign_modes", {}).get("council_season_clears", 0)) == 1, "DAY 30 records one council-season clear")
	_expect(int(profile.get("rivals", {}).get(representative_id, {}).get("day30_representative_defeats", 0)) == 1, "DAY 30 records the representative defeat")
	_expect(profile.get("chronicle_update4", {}).get("recent_runs", []).size() == 1, "DAY 30 records one chronicle run")
	root.free()


func _resolve_required_day_action(day: int) -> void:
	match day:
		4:
			_select_region(ROUTE[0], day)
			var outpost_ids := DataRegistry.update4_outpost_types.keys()
			outpost_ids.sort()
			var built := OutpostScript.build(profile, active_run, str(outpost_ids[0]), day, DataRegistry.update4_outpost_types)
			_expect(bool(built.get("ok", false)), "DAY 04 builds an outpost")
			profile = built.get("profile", profile)
			active_run = built.get("active_run", active_run)
		11:
			_select_region(ROUTE[1], day)
		13, 22, 26:
			_expect(RuntimeScript.required_choice_id(active_run, day) == "council_vote", "DAY %02d exposes the council vote gate" % day)
			var agendas := CouncilVoteScript.seeded_agendas_for_day(DataRegistry.update4_council_agendas, day, active_run, 40404, 3)
			_expect(not agendas.is_empty(), "DAY %02d offers a seeded agenda" % day)
			if not agendas.is_empty():
				var recorded := CouncilVoteScript.record_empty_vote(active_run, str(agendas[0]), CouncilVoteScript.CHOICE_APPROVE, day, DataRegistry.update4_council_agendas, DataRegistry.update4_rival_lords)
				_expect(bool(recorded.get("ok", false)), "DAY %02d records the vote" % day)
				active_run = CouncilVoteScript.apply_vote_outcome(recorded.get("active_run", active_run), recorded.get("record", {}), DataRegistry.update4_council_balance)
		16:
			active_run = MultiFloorScript.unlock_if_due(active_run, day)
			_expect(RuntimeScript.required_choice_id(active_run, day) == "upper_layout", "DAY 16 exposes the upper-floor layout gate")
			var layout_ids := DataRegistry.update4_upper_floor_layouts.keys()
			layout_ids.sort()
			var selected := UpperFloorScript.select_layout(active_run, str(layout_ids[0]), DataRegistry.update4_upper_floor_layouts, DataRegistry.update4_upper_floor_modules, 4)
			_expect(bool(selected.get("ok", false)), "DAY 16 selects an upper-floor layout")
			active_run = selected.get("active_run", active_run)
		21:
			_select_region(ROUTE[2], day)
		23:
			_expect(RuntimeScript.required_choice_id(active_run, day) == "crown_choice", "DAY 23 exposes the crown gate")
			var council: Dictionary = active_run.get("council_season", {}).duplicate(true)
			council["council_seals"] = 0
			council["alternative_seal_resource"] = maxi(2, int(council.get("alternative_seal_resource", 0)))
			active_run["council_season"] = council
			var declined := CrownScript.decline(active_run, "council_support_token")
			_expect(bool(declined.get("ok", false)) and str(declined.get("payment", "")) == "alternative_seal_resource", "DAY 23 supports the alternative-seal decline path")
			active_run = declined.get("active_run", active_run)
			active_run["crown"] = {"selected_instance_id": "", "crown_form_id": "", "declined": true, "replacement_reward_id": "council_support_token"}
		24:
			_expect(RuntimeScript.required_choice_id(active_run, day) == "representative_lock", "DAY 24 exposes the representative lock gate")
			var locked := RuntimeScript.lock_representative(active_run, DataRegistry.update4_rival_lords, DataRegistry.update4_regions, 40404)
			_expect(bool(locked.get("ok", false)), "DAY 24 locks a rival representative")
			active_run = locked.get("active_run", active_run)
		29:
			_expect(RuntimeScript.required_choice_id(active_run, day) == "council_final_declaration", "DAY 29 exposes the final declaration gate")
			var council: Dictionary = active_run.get("council_season", {}).duplicate(true)
			council["day29_decision_id"] = "council_commitment"
			active_run["council_season"] = council


func _select_region(region_id: String, day: int) -> void:
	var selected := RegionRouteScript.select_region(profile, active_run, region_id, day, DataRegistry.update4_regions)
	_expect(bool(selected.get("ok", false)), "DAY %02d selects %s" % [day, region_id])
	profile = selected.get("profile", profile)
	active_run = selected.get("active_run", active_run)


func _settle_region_if_due(day: int) -> void:
	var slot := RuntimeScript.settlement_slot_for_day(day)
	if slot <= 0:
		return
	var settled := RuntimeScript.settle_region_chapter(profile, active_run, slot, DataRegistry.update4_regions)
	_expect(bool(settled.get("ok", false)), "DAY %02d settles region chapter %d" % [day, slot])
	profile = settled.get("profile", profile)
	active_run = settled.get("active_run", active_run)


func _sync_day_state() -> void:
	var council: Dictionary = active_run.get("council_season", {}).duplicate(true)
	council["day_state"] = day_state.duplicate(true)
	active_run["council_season"] = council


func _test_all_rival_boss_routes() -> void:
	for rival_id_value in DataRegistry.update4_rival_lords.keys():
		var rival_id := str(rival_id_value)
		var fixture := _fresh_council_run()
		var rival_run: Dictionary = fixture.get("active_run", {})
		var council: Dictionary = rival_run.get("council_season", {}).duplicate(true)
		council["selected_regions"] = [ROUTE[0]]
		council["current_region_index"] = 0
		council["final_representative_id"] = rival_id
		rival_run["council_season"] = council
		var entries: Array = RuntimeScript.wave_catalog_for_day(rival_run, 30, DataRegistry.update4_council_wave_templates, DataRegistry.update4_rival_lords, DataRegistry.waves).get("day_30", [])
		var boss_id := str(DataRegistry.update4_rival_lords.get(rival_id, {}).get("boss_enemy_id", ""))
		_expect(boss_id != "" and entries.any(func(entry): return entry is Dictionary and str(entry.get("enemy_id", "")) == boss_id), "%s routes to its DAY 30 boss" % rival_id)


func _test_decision_overlays() -> void:
	var fixture := _fresh_council_run()
	var overlay_active: Dictionary = fixture.get("active_run", {})
	var catalogs := {
		"council_agendas": DataRegistry.update4_council_agendas,
		"rival_lords": DataRegistry.update4_rival_lords,
		"crown_evolutions": DataRegistry.update4_crown_evolutions
	}
	var cases := [
		{"action": "council_vote", "day": 13, "candidates": [], "buttons": 9},
		{"action": "crown_choice", "day": 23, "candidates": [
			{"instance_id": "MON_SLIME", "crown_form_id": "crown_pudding_royal_bastion", "display_name": "Pudding"},
			{"instance_id": "MON_GOB", "crown_form_id": "crown_gob_midnight_marshal", "display_name": "Gob"}
		], "buttons": 5},
		{"action": "council_final_declaration", "day": 29, "candidates": [], "buttons": 4}
	]
	for case_value in cases:
		var host := Control.new()
		host.size = Vector2(1920, 1080)
		add_child(host)
		var overlay = DecisionOverlayScript.new()
		overlay.setup(str(case_value.action), int(case_value.day), overlay_active, catalogs, case_value.candidates, 40404)
		host.add_child(overlay)
		await get_tree().process_frame
		var panel: Control = overlay.get_node("DecisionPanel")
		var buttons := _buttons_below(overlay)
		_expect(buttons.size() == int(case_value.buttons), "%s exposes the expected decision buttons" % str(case_value.action))
		_expect(Rect2(Vector2.ZERO, host.size).encloses(panel.get_rect()), "%s stays inside the 1920x1080 logical viewport" % str(case_value.action))
		_expect(panel.get_combined_minimum_size().y <= panel.size.y, "%s content fits its decision panel" % str(case_value.action))
		if OS.get_environment("UPDATE4_CAPTURE_UI") == "1":
			await get_tree().process_frame
			var image := get_viewport().get_texture().get_image()
			if image != null:
				var label := OS.get_environment("UPDATE4_CAPTURE_LABEL")
				var capture_path := OS.get_user_data_dir().path_join("update4_phase36_%s_%s.png" % [str(case_value.action), label])
				image.save_png(capture_path)
				print("UPDATE4_PHASE36_CAPTURE: %s" % capture_path)
		host.queue_free()
		await get_tree().process_frame


func _buttons_below(node: Node) -> Array:
	var result: Array = []
	if node is Button:
		result.append(node)
	for child in node.get_children():
		result.append_array(_buttons_below(child))
	return result


func _fresh_council_run() -> Dictionary:
	var fresh_profile := CampaignModeScript.default_profile()
	var modes: Dictionary = fresh_profile.get("campaign_modes", {}).duplicate(true)
	modes["council_season_unlocked"] = true
	fresh_profile["campaign_modes"] = modes
	var selected := CampaignModeScript.select_mode(fresh_profile, CampaignModeScript.new_cycle_active_run(), CampaignModeScript.COUNCIL_MODE_ID, DataRegistry.update4_campaign_modes)
	_expect(bool(selected.get("ok", false)), "fresh council-season fixture is available")
	return selected


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[Update4ReleaseCandidatePhase36] FAIL: %s" % label)
