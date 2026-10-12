extends "res://tools/tests/PlayerFeedbackHotfixTest.gd"
const Modes = preload("res://scripts/systems/campaign/CampaignModeService.gd")
var caster
var ally
var outsider
var enemy
var evidence: Array = []

func run() -> void:
	expect(ProjectSettings.globalize_path("user://").contains("skill_action_review"), "isolated connection userdata")
	if not failures.is_empty(): get_tree().quit(1); return
	DataRegistry.load_all()
	UISettings.reset_skill_cutscene_history(false)
	for species in ["spider_tailor", "slime"]:
		var baseline: Dictionary = await effect_case(species, "off", false)
		var first: Dictionary = await effect_case(species, "once", false)
		var seen: Dictionary = await effect_case(species, "once", false)
		var full: Dictionary = await effect_case(species, "always", false)
		var automatic: Dictionary = await effect_case(species, "always", true)
		expect(baseline == first and first == seen and seen == full and full == automatic, species + " exact costs/shields/routes/uses equivalent across policies and actual AI")
	await guards()
	await specialization()
	await lifecycle()
	await geometry()
	var file := FileAccess.open("res://tmp/skill_runtime_connection/results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(evidence, "\t"))
	print("SKILL_RUNTIME_CONNECTION_TEST: %s (%d checks; %d failures)" % ["PASS" if failures.is_empty() else "FAIL", checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func setup_case(species: String, policy: String) -> void:
	output_dir = "res://tmp/skill_runtime_connection"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	UISettings.set_skill_cutscene_policy(policy, false)
	game = GameRootScene.instantiate(); add_child(game); await settle()
	game.continuity.acknowledge_update(); game._set_campaign_save_path_for_tests("")
	game._onboarding_reset_game(); game._onboarding_enter_management_day(1, true); game._debug_skip_onboarding()
	game.campaign_save_enabled = false; game.campaign_autosave_pending = false
	game.set_process(false); game.set_physics_process(false)
	for old in game.monster_units + game.enemy_units: old.queue_free()
	game.monster_units.clear(); game.enemy_units.clear()
	game.monster_roster[species] = {"level": 1, "exp": 0, "bond": 0, "bond_rank": 0, "room": "entrance", "specialization_id": ""}
	if species == "slime":
		game.update4_active_run.campaign_mode_id = Modes.COUNCIL_MODE_ID
		game.update4_active_run.crown = {"crown_form_id": "crown_pudding_royal_bastion", "selected_instance_id": "mon_core_pudding"}
		game.update4_active_run.upper_floor = {"crown_suppressed": false}
	var position: Vector2 = game.graph.center("entrance")
	caster = game._create_unit(species, game._scaled_monster_stats(species), Constants.FACTION_MONSTER, "entrance")
	caster.global_position = position
	ally = game._create_unit("goblin", DataRegistry.monster("goblin"), Constants.FACTION_MONSTER, "entrance")
	ally.global_position = position + Vector2(100, 0); ally.hp = maxi(1, int(ally.max_hp * 0.2))
	outsider = game._create_unit("imp", DataRegistry.monster("imp"), Constants.FACTION_MONSTER, "recovery")
	outsider.global_position = game.graph.center("recovery")
	enemy = game._create_unit("explorer", DataRegistry.enemy("explorer"), Constants.FACTION_ENEMY, "entrance")
	enemy.global_position = position + Vector2(30, 0); enemy.hp = 10000; enemy.max_hp = 10000
	game.monster_units = [caster, ally, outsider]; game.enemy_units = [enemy]
	for actor in game.monster_units + game.enemy_units: actor.set_physics_process(false)
	game.selected_unit = caster; game.combat_time = 0; GameState.mana = 500
	game._set_screen(Constants.SCREEN_COMBAT, false)
	game.combat_scene.requested_pause = false
	await settle()

func effect_case(species: String, policy: String, automatic: bool) -> Dictionary:
	await setup_case(species, policy)
	var combat = game.combat_scene
	var action = combat.skill_actions
	var slot := 1 if species == "spider_tailor" else 2
	var id := "emergency_thread_pull" if species == "spider_tailor" else "royal_jelly_bastion"
	var was_seen: bool = UISettings.skill_cutscene_seen.has("skill:" + id)
	var before_position: Vector2 = ally.global_position
	for base in combat.skill_slots_for(caster):
		if base != null and str(base) != id: caster.set_skill_cooldown(str(base), 100)
	var accepted: bool = combat.try_auto_monster_skill(caster) if automatic else combat.request_selected_skill(slot)
	expect(accepted, species + " actual request accepted " + policy)
	var should_show := policy == "always" or (policy == "once" and not was_seen)
	expect(action.is_active() == should_show, id + " viewed policy respected")
	if action.is_active():
		expect(GameState.mana == 500 and ally.duo_barrier == 0 and ally.royal_jelly_timer == 0, id + " preparation has no cost/effect")
		expect(action.actors[0].sprite_frames == caster.sprite.sprite_frames, id + " actual current appearance frames")
		action.tick(0.4)
		expect(action.caption.text == "시전", "support preparation accurately says cast")
		await capture(species + "_" + policy + ("_auto" if automatic else "_manual"))
		action.tick(0.16)
		await capture(species + "_" + policy + ("_auto" if automatic else "_manual") + "_impact")
		action.skip(); action.skip()
	for actor in game.monster_units + game.enemy_units: actor.set_physics_process(false)
	expect(enemy.hp == 10000 and combat.contact_feedback_events.is_empty(), id + " support never creates fake enemy damage")
	if species == "spider_tailor":
		expect(GameState.mana == 486 and caster.skill_cooldowns[id] == 10.0, "rescue mana14/cooldown10 once")
		expect(ally.duo_barrier == roundi(ally.max_hp * 0.10), "real ten-percent shield")
		expect(ally.global_position != before_position and ally.global_position.distance_to(before_position) <= 120.01 and ally.path_points.is_empty(), "actual safe displacement up to120, no stale route")
		expect(caster.get_meta("silky_state").rescues == 1, "one actual rescue")
		var moved_position: Vector2 = ally.global_position
		combat.update_monster_path(ally)
		expect(ally.global_position == moved_position, "next actual AI starts from completed displacement")
		expect(combat.hud._combat_unit_status_text(caster, false).contains("계단 꿰매기") and not combat.hud._combat_unit_status_text(caster, false).contains("응급 실밥 · 전투 미지원"), "partial HUD names only unavailable skill")
	else:
		expect(GameState.mana == 500 and ally.royal_jelly_timer == 6.0 and ally.royal_jelly_redirect_timer == 6.0, "actual royal six-second guard/redirect")
		expect(outsider.royal_jelly_timer == 0.0, "other room receives no royal guard")
		expect(caster.get_meta("royal_jelly_uses") == 1 and not combat.request_selected_skill(slot), "one royal use per battle despite cooldownzero")
		ally.hp = 1000; ally.max_hp = 1000; caster.hp = 2000; caster.max_hp = 2000
		var before_ally: int = ally.hp; var before_caster: int = caster.hp
		ally.receive_damage(100)
		expect(before_ally - ally.hp == 46 and before_caster - caster.hp == 25, "actual incoming100 redirects35 and reduces both shares30percent")
	var outcome := {"mana": GameState.mana, "shield": ally.duo_barrier, "position": str(ally.global_position), "guard": ally.royal_jelly_timer, "redirect": ally.royal_jelly_redirect_timer, "uses": caster.get_meta("royal_jelly_uses", 0), "rescues": caster.get_meta("silky_state", {}).get("rescues", 0), "enemy_hp": enemy.hp}
	evidence.append({"species": species, "policy": policy, "automatic": automatic, "outcome": outcome})
	await dispose_case()
	return outcome

func guards() -> void:
	await setup_case("spider_tailor", "always")
	var combat = game.combat_scene
	ally.hp = ally.max_hp
	expect(not combat.request_selected_skill(1) and GameState.mana == 500 and not combat.skill_actions.is_active(), "healthy target rejected before cost/scene")
	ally.hp = 1
	GameState.mana = 0
	expect(not combat.request_selected_skill(1) and ally.duo_barrier == 0, "insufficient mana no effect")
	GameState.mana = 500
	combat.request_selected_skill(1); ally.hp = ally.max_hp; combat.skill_actions.skip()
	expect(GameState.mana == 500 and ally.duo_barrier == 0, "healed fixed target at commit rejected without cost")
	ally.hp = 1; ally.set_meta("fixed", true)
	combat.request_selected_skill(1); combat.skill_actions.skip()
	expect(ally.path_points.is_empty() and ally.duo_barrier > 0, "fixed target shieldonly")
	await dispose_case()
	await setup_case("slime", "always")
	game.update4_active_run.upper_floor.crown_suppressed = true
	expect(not game.combat_scene.request_selected_skill(2) and not game.combat_scene.skill_actions.is_active(), "suppressed crown has no usable royal slot")
	game.update4_active_run.upper_floor.crown_suppressed = false
	game.combat_scene.request_selected_skill(2); game.update4_active_run.upper_floor.crown_suppressed = true; game.combat_scene.skill_actions.skip()
	expect(ally.royal_jelly_timer == 0 and caster.get_meta("royal_jelly_uses", 0) == 0, "suppression during preparation cancels effect/use")
	await dispose_case()

func specialization() -> void:
	for spec in ["silky_stair_warden", "silky_field_tailor"]:
		await setup_case("spider_tailor", "off")
		game.monster_roster["spider_tailor"] = {"specialization_id": spec}
		caster.global_position = game.graph.center("barracks")
		game._damage_update3_facility("barracks", 30, "fixture:" + spec)
		var before: int = game.rooms.barracks.hp
		game.combat_scene.request_selected_skill(1)
		expect(ally.duo_barrier == maxi(1, roundi(ally.max_hp * (0.07 if spec == "silky_stair_warden" else 0.15))), "existing specialization shield contract " + spec)
		expect(int(game.rooms.barracks.hp) - before == (12 if spec == "silky_field_tailor" else 0), "existing specialization effective facility repair " + spec)
		await dispose_case()

func lifecycle() -> void:
	for species in ["spider_tailor", "slime"]:
		await setup_case(species, "always")
		UISettings.reset_skill_cutscene_history(false)
		var slot := 1 if species == "spider_tailor" else 2
		var id := "emergency_thread_pull" if species == "spider_tailor" else "royal_jelly_bastion"
		game.combat_scene.set_speed(3.0)
		game.combat_scene.request_selected_skill(slot)
		game._open_pause_menu()
		expect(game.combat_paused and game.combat_scene.requested_pause, id + " interrupted menu retains pause")
		expect(not UISettings.skill_cutscene_seen.has("skill:" + id), id + " menu interruption not falsely viewed")
		expect(caster.get_meta("silky_state", {}).get("rescues", 0) == (1 if species == "spider_tailor" else 0) and caster.get_meta("royal_jelly_uses", 0) == (1 if species == "slime" else 0), id + " interruption commits exactly once")
		game._close_pause_menu()
		expect(not game.combat_paused and game.combat_speed == 3.0, id + " menu resume restores input and x3")
		await dispose_case()
	await setup_case("slime", "off")
	game.combat_scene.request_selected_skill(2)
	ally.activate_shield(2.0, 0.4)
	ally.simulation_speed = 1.0
	ally._physics_process(2.1)
	expect(ally.shield_timer <= 0.0 and ally.damage_reduction == 0.0 and ally.royal_jelly_timer > 3.8, "independent original shield expires without royal extension")
	ally._physics_process(4.0)
	expect(ally.royal_jelly_timer == 0.0, "royal guard expires at six combat seconds")
	ally.apply_duo_damage_redirect(caster, 10, 0.25)
	ally.apply_royal_jelly_redirect(caster, 6, 0.35)
	ally._physics_process(6.0)
	expect(ally.royal_jelly_redirect_timer == 0.0 and ally.duo_redirect_timer == 4.0 and ally.duo_redirect_fraction == 0.25, "royal six seconds cannot extend existing10second redirect or upgrade its residual fraction")
	ally.hp = 1000; caster.hp = 2000; ally.max_hp = 1000; caster.max_hp = 2000
	ally.apply_duo_damage_redirect(caster, 6, 0.35)
	caster.apply_duo_damage_redirect(ally, 6, 0.35)
	ally.receive_damage(100)
	expect(ally.hp > 0 and caster.hp > 0 and not ally.damage_redirect_in_progress and not caster.damage_redirect_in_progress, "redirect cycle terminates and flags reset")
	await dispose_case()

func dispose_case() -> void:
	game.queue_free(); await settle()

func geometry() -> void:
	await setup_case("spider_tailor", "off")
	var route: Array = game.combat_scene._bebe_safe_route(caster, ally, 120.0)
	var length := 0.0
	var last: Vector2 = ally.global_position
	for point in route:
		length += last.distance_to(point); last = point
	expect(not route.is_empty() and length <= 120.01, "entire verified pull route at most120")
	expect(game._clamp_to_combat_walkable(last).distance_to(last) < 0.1, "real endpoint walkable")
	game.monster_roster["spider_tailor"]["specialization_id"] = "silky_field_tailor"
	game._damage_update3_facility("recovery", 50, "fixture:remote")
	game.selected_room = "recovery"
	var before: int = game.rooms.recovery.hp
	game.combat_scene.request_selected_skill(1)
	expect(game.rooms.recovery.hp == before, "selected remote facility cannot receive free repair")
	await dispose_case()
