extends Node
const Scene = preload("res://scenes/game/GameRoot.tscn")
const Heart = preload("res://scripts/systems/hearts/CastleHeartService.gd")
const Front = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const Wave = preload("res://scripts/combat/WaveManager.gd")
const OUT = "res://tmp/uiux_raid_choice_20260914"
const MISSIONS = ["d04_signpost_flip", "d05_supply_tag", "d16_route_recon", "d16_supply_ambush", "d18_forged_manifest", "d18_seal_smuggling_tunnel", "d28_siege_route_recon", "d28_engineer_supply_disruption", "d28_holy_relic_registry_swap", "d28_holy_pilgrim_detour", "d28_guild_ledger_forgery", "d28_guild_payroll_cut"]
var checks := 0
var failed := false
var records: Array = []

func _ready() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error("RAID_CHOICE_FAIL: " + message)

func settle() -> void:
	for i in range(3):
		await get_tree().process_frame
		await RenderingServer.frame_post_draw

func resources() -> Dictionary:
	return {"gold": GameState.gold, "mana": GameState.mana, "food": GameState.food, "infamy": GameState.infamy}

func prepare(g, id: String) -> void:
	g._debug_skip_onboarding()
	g.completed_raids.clear()
	g.next_defense_modifiers.clear()
	g.last_raid_result.clear()
	g.update3_active_run.clear()
	if id in ["d28_holy_relic_registry_swap", "d28_holy_pilgrim_detour", "d28_guild_ledger_forgery", "d28_guild_payroll_cut"]:
		var profile := Front.default_update3_profile()
		profile.rival_relations = {"selen": 100, "roman": 100, "leon": 100}
		var selected := Front.select_front(profile, Front.new_cycle_active_run(2), str(DataRegistry.update3_front_operations[id].front_id), DataRegistry.update3_fronts)
		g.update3_active_run = Heart.select_heart(selected.get("profile", {}), selected.get("active_run", {}), "heart_stonebone", DataRegistry.update3_castle_hearts).get("active_run", {}).duplicate(true)
	GameState.day = int(DataRegistry.raid_mission(id).day)
	# Deliberate sufficient-funds fixture, not a campaign economy claim.
	GameState.gold = 1000
	GameState.mana = 1000
	GameState.food = 1000
	GameState.infamy = 1000
	g._unlock_kobold_scout_commander()
	g.raid_selected_mission_id = id
	g.raid_selected_monster_ids.assign(["slime"])

func immutable_state(g) -> Dictionary:
	return {"resources": resources(), "completed": g.completed_raids.duplicate(true), "modifiers": g.next_defense_modifiers.duplicate(true), "roster": g.monster_roster.duplicate(true), "result": g.last_raid_result.duplicate(true)}

func reject(g, tag: String) -> void:
	check(not g._can_start_selected_raid(), tag + " disabled")
	var before := immutable_state(g)
	g._commit_selected_raid()
	check(immutable_state(g) == before, tag + " no charge, reward, bond or effect")

func counts(schedule: Array) -> Dictionary:
	var result := {}
	for entry in schedule:
		result[entry.enemy_id] = int(result.get(entry.enemy_id, 0)) + 1
	return result

func capture(name: String) -> void:
	await settle()
	check(get_viewport().get_texture().get_image().save_png(OUT + "/" + name + ".png") == OK, "capture " + name)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var g = Scene.instantiate()
	g.campaign_save_enabled = false
	g.campaign_auxiliary_save_enabled = false
	g.campaign_save_v4_enabled = false
	g.campaign_save_v5_enabled = false
	add_child(g)
	await settle()
	g.set_process(false)
	g.set_physics_process(false)
	for id in MISSIONS:
		prepare(g, id)
		var mission: Dictionary = DataRegistry.raid_mission(id)
		var before := resources()
		var reward: Dictionary = mission.get("reward", {}).duplicate(true)
		if mission.get("recommended_captain", "") == "kobold_scout" and int(reward.get("infamy", 0)) > 0:
			reward.infamy += int(ceil(float(reward.infamy) * 0.1))
		var stable := immutable_state(g)
		var preview: Dictionary = g._raid_defense_preview(mission)
		check(immutable_state(g) == stable and GameState.day == int(mission.day), id + " preview read-only")
		check(g._can_start_selected_raid(), id + " allowed on mission day")
		g._commit_selected_raid()
		check(g.completed_raids.has(id), id + " completed by real commit")
		var actual: Dictionary = g.last_raid_result.get("resource_balance", {})
		check(actual.get("before") == before and actual.get("after") == resources(), id + " ledger actual balances")
		for key in before:
			var net := int(reward.get(key, 0)) - int(mission.get("cost", {}).get(key, 0))
			check(int(resources()[key]) - int(before[key]) == net, id + " exact cost/reward " + key)
			check(int(actual.get("delta", {}).get(key, -999)) == net, id + " ledger " + key)
		check(g.last_raid_result.get("cost") == mission.cost, id + " cost recorded")
		check(str(g.last_raid_result.lines[2]).begins_with(str(preview.timing)), id + " report preserves effect timing")
		reject(g, id + " duplicate")
		var modifier: Dictionary = mission.get("next_defense_modifier", {})
		var target_day := int(preview.get("day", GameState.day))
		if int(mission.day) == 28:
			for day in [28, 29]:
				GameState.day = day
				check(not g._active_defense_modifiers().has(modifier.id), id + " not active day " + str(day))
				g._consume_defense_modifiers()
				check(g.next_defense_modifiers.has(modifier.id), id + " future modifier preserved")
			check(target_day == 30, id + " preview day30")
		GameState.day = target_day
		check(g._active_defense_modifiers().has(modifier.id), id + " actual effect on target day")
		var wave = Wave.new()
		wave.setup(target_day, g._active_wave_catalog(target_day), g._active_defense_modifiers())
		check(counts(wave.schedule) == preview.after_counts, id + " preview matches real active schedule")
		g._consume_defense_modifiers()
		check(not g.next_defense_modifiers.has(modifier.id), id + " consumed once")
		if int(mission.day) == 28:
			var paid := resources()
			check(g._restore_final_expedition_modifier_for_retry(), id + " retry restores effect")
			check(g.next_defense_modifiers.has(modifier.id) and resources() == paid, id + " retry no payment/reward")
		records.append({"mission": id, "balance": actual, "preview": preview, "schedule": wave.schedule})
		g.current_screen = Constants.SCREEN_MANAGEMENT
		await settle()
	prepare(g, "d28_siege_route_recon")
	GameState.day = 27
	reject(g, "future mission")
	prepare(g, "d16_route_recon")
	g.raid_selected_monster_ids.assign(["slime", "goblin", "imp"])
	reject(g, "over capacity")
	prepare(g, "d16_route_recon")
	g.raid_selected_monster_ids.assign(["slime", "unknown"])
	reject(g, "unknown member")
	prepare(g, "d16_route_recon")
	g.raid_selected_monster_ids.assign(["slime", "slime"])
	reject(g, "duplicate member")
	prepare(g, "d16_route_recon")
	g.raid_selected_monster_ids.clear()
	reject(g, "empty roster")
	prepare(g, "d16_route_recon")
	check(g._can_start_selected_raid(), "before briefing affordable")
	GameState.food = 0
	reject(g, "resources changed after briefing")
	prepare(g, "d16_route_recon")
	g.completed_raids["d16_supply_ambush"] = true
	reject(g, "exclusive alternative")
	prepare(g, "d16_route_recon")
	g.raid_selected_mission_id = "d05_supply_tag"
	reject(g, "required group first")
	for resolution in [Vector2i(1920,1080), Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		UISettings.text_scale = 1.0 if resolution.x == 1920 else 1.15
		for id in ["d16_supply_ambush", "d28_engineer_supply_disruption", "d28_holy_relic_registry_swap", "d28_guild_payroll_cut"]:
			prepare(g, id)
			g._set_screen(Constants.SCREEN_RAID)
			await settle()
			var timing = g.find_child("RaidEffectTiming", true, false)
			var changes = g.find_child("RaidWaveChanges", true, false)
			var scroller = g.find_child("RaidDetailScroll", true, false)
			check(timing != null and changes != null, "effect UI exists")
			check(timing.text.contains("30" if GameState.day == 28 else "16"), "UI actual target day")
			check(changes.get_global_rect().end.y <= scroller.get_global_rect().end.y, "effect visible without scrolling")
			var tag: String = str(resolution.x) + "_" + id
			await capture(tag)
			if resolution.x == 1920 and id == "d28_engineer_supply_disruption" and FileAccess.file_exists(OUT + "/BeforeWorkspace.gd"):
				g.hud.clear()
				var previous = load(OUT + "/BeforeWorkspace.gd").new()
				previous.setup(g, g.hud)
				previous.build_raid()
				await capture("before_1920_day28")
	g.queue_free()
	await get_tree().create_timer(0.3).timeout
	await settle()
	var file := FileAccess.open(OUT + "/results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"kind": "REAL_RAID_COMMIT_WITH_SUFFICIENT_FUNDS_FIXTURE_NOT_PLAYTHROUGH", "checks": checks, "passed": not failed, "missions": records}, "  "))
	file.close()
	print("UIUX_RAID_CHOICE_TEST: %s (%d checks)" % ["FAIL" if failed else "PASS", checks])
	get_tree().quit(1 if failed else 0)
