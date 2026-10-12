extends "res://tools/tests/SkillActionAutomaticFrameTest.gd"
const MOLTEN := "link_molten_carapace"
const MOON := "link_moon_scent_hunt"
var raw_shots: Array[Dictionary] = []

func run() -> void:
	expect(ProjectSettings.globalize_path("user://").contains("skill_action_review"), "isolated duo userdata")
	if not failures.is_empty(): get_tree().quit(1); return
	DataRegistry.load_all()
	UISettings.reset_skill_cutscene_history(false)
	var off: Dictionary = await _duo_case("off", false)
	var first: Dictionary = await _duo_case("once", true, true)
	var seen: Dictionary = await _duo_case("once", false)
	var always: Dictionary = await _duo_case("always", true)
	expect(off == first and first == seen and seen == always, "duo damage armor cooldown gauge and use identical across policies")
	await _duo_invalid("target")
	await _duo_invalid("member")
	await _duo_interruptions()
	var counter_off: Dictionary = await _automatic_counter("off")
	var counter_full: Dictionary = await _automatic_counter("always")
	expect(counter_off == counter_full, "automatic duo before Leon counter preserves complete original calculation order")
	await _nested_specialist()
	await _ram_prepared_targets()
	await _settings_history()
	var dir := "res://tmp/skill_action_duo"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var metadata: Array = []
	for shot in raw_shots:
		expect(shot.image.save_png(dir.path_join(shot.name + ".png")) == OK, "real duo frame saved")
		metadata.append({"name": shot.name, "age": shot.age, "hp": shot.hp, "frames": shot.frames})
	var file := FileAccess.open(dir.path_join("duo-frames.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(metadata, "\t"))
	print("SKILL_ACTION_DUO_TEST: %s (%d checks; %d failures)" % ["PASS" if failures.is_empty() else "FAIL", checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func _setup_duo(policy: String, link: String = MOLTEN) -> void:
	await _setup(policy)
	for actor in actors + [enemy]: actor.queue_free()
	game.monster_units.clear()
	game.enemy_units.clear()
	actors.clear()
	var species_list := ["imp", "armored_beetle"] if link == MOLTEN else ["goblin", "graveyard_hound"]
	for species in species_list:
		var actor = game._create_unit(species, DataRegistry.monster(species), Constants.FACTION_MONSTER, "entrance")
		actor.global_position = Vector2(600 + 25 * actors.size(), 430)
		actor.set_physics_process(false)
		actor.attack_cooldown = 100.0
		actors.append(actor)
		game.monster_units.append(actor)
	enemy = game._create_unit("official_hero_leon", DataRegistry.enemy("official_hero_leon"), Constants.FACTION_ENEMY, "entrance")
	enemy.global_position = Vector2(655, 430)
	enemy.hp = 10000
	enemy.max_hp = 10000
	enemy.set_physics_process(false)
	enemy.apply_duo_mark(6.0, "fixture")
	game.enemy_units = [enemy]
	game.selected_unit = actors[0]
	game.update3_active_run["equipped_duo_links"] = [link]
	game.update3_active_run["duo_link_states"] = {link: {"charge": 100, "active": true, "ready": true, "used_this_battle": false}}
	game.update3_active_run["duo_link_auto_use"] = false
	game.combat_scene.contact_feedback_events.clear()

func _dispose() -> void:
	game.queue_free()
	await settle()

func _duo_case(policy: String, show_scene: bool, capture_live: bool = false) -> Dictionary:
	await _setup_duo(policy)
	var action = game.combat_scene.skill_actions
	game._activate_update3_duo_link(MOLTEN)
	expect(action.is_active() == show_scene, policy + " expected duo scene")
	if show_scene:
		expect(action.actors.size() == 2, "both real members appear")
		for index in range(2):
			expect(str(action.actors[index].get_meta("action_sprite_path")) == actors[index].sprite_path, "current live member art used")
		expect(enemy.hp == 10000 and not game.update3_active_run.duo_link_states[MOLTEN].used_this_battle, "duo preparation consumes neither damage nor use")
		game._activate_update3_duo_link(MOLTEN)
		expect(action.pending.is_empty() and action.commits == 0, "duplicate duo request cannot enqueue or commit")
		if capture_live:
			await get_tree().create_timer(0.04).timeout
			await _duo_shot("01_prepare")
			await get_tree().create_timer(0.22).timeout
			await _duo_shot("02_two_member_attack")
			await get_tree().create_timer(0.28).timeout
			await _duo_shot("03_real_impact")
			await get_tree().create_timer(0.48).timeout
		else: action.skip()
		for actor in actors + [enemy]: actor.set_physics_process(false)
		expect(not action.is_active() and not game.combat_paused, "duo finishes and restores hold")
		expect(UISettings.skill_cutscene_seen.has("duo:" + MOLTEN), "history keyed by duo ID")
	var state: Dictionary = game.update3_active_run.duo_link_states[MOLTEN]
	expect(state.used_this_battle and state.charge == 0, "duo consumes original single use")
	expect(enemy.hp < 10000 and game.combat_scene.contact_feedback_events.size() == 1, "one actual impact event")
	var hp: int = enemy.hp
	game._activate_update3_duo_link(MOLTEN)
	expect(enemy.hp == hp and not action.is_active(), "used duo cannot replay its reward or damage")
	var result := {"hp": enemy.hp, "armor": enemy.armor_break_amount, "armor_timer": enemy.armor_break_timer, "repair_cd": actors[1].skill_cooldowns.get("patch_plates", 0.0), "charge": state.charge, "used": state.used_this_battle, "mana": GameState.mana}
	print("DUO_RESULT ", policy, " ", JSON.stringify(result))
	await _dispose()
	return result

func _duo_shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var frames: Array = []
	for actor in game.combat_scene.skill_actions.actors: frames.append([actor.animation, actor.frame])
	raw_shots.append({"name": name, "age": game.combat_scene.skill_actions.age, "hp": enemy.hp, "frames": frames, "image": get_viewport().get_texture().get_image()})

func _duo_invalid(kind: String) -> void:
	await _setup_duo("always")
	game._activate_update3_duo_link(MOLTEN)
	if kind == "target": enemy.queue_free()
	else: actors[1].queue_free()
	game.combat_scene.skill_actions.skip()
	expect(not game.update3_active_run.duo_link_states[MOLTEN].used_this_battle, kind + " invalidation cancels without consuming use")
	expect(not game.combat_scene.skill_actions.last_result and not game.combat_scene.skill_actions.is_active(), kind + " cancellation restores director")
	await _dispose()

func _duo_interruptions() -> void:
	for owner in ["menu", "load", "title"]:
		UISettings.reset_skill_cutscene_history(false)
		await _setup_duo("always")
		game._activate_update3_duo_link(MOLTEN)
		if owner == "menu": game._open_pause_menu()
		elif owner == "load": game._restore_campaign_payload({})
		else: game._set_screen(Constants.SCREEN_TITLE, false)
		expect(not game.combat_scene.skill_actions.is_active() and game.combat_scene.skill_actions.commits == 1, owner + " interrupts accepted action exactly once")
		expect(not UISettings.skill_cutscene_seen.has("duo:" + MOLTEN), owner + " interrupted scene not recorded as viewed")
		if owner == "menu":
			expect(game.combat_paused, "menu retains pause ownership")
			game._close_pause_menu()
			expect(not game.combat_paused, "cancel menu restores input and pause")
		await _dispose()

func _automatic_counter(policy: String) -> Dictionary:
	await _setup_duo(policy, MOON)
	var combat = game.combat_scene
	combat.leon_stance_id = "leon_stance_duelist"
	actors[1].atk = 100
	actors[1].attack_cooldown = 0.0
	enemy.scent_mark_timer = 6.0
	game.update3_active_run.duo_link_states[MOON].charge = 96
	game.update3_active_run.duo_link_states[MOON].ready = false
	game.update3_active_run.duo_link_auto_use = true
	combat.try_attack(actors[1], [enemy])
	if policy == "always":
		expect(combat.skill_actions.is_active() and combat.pending_atomic_tail.is_valid(), "automatic basic attack suspends its original counter tail")
		expect(combat.leon_counter_damage == 0, "counter waits for duo vulnerability")
		combat.skill_actions.skip()
	for actor in actors + [enemy]: actor.set_physics_process(false)
	expect(combat.leon_counter_damage > 0 and not combat.pending_atomic_tail.is_valid(), "original counter resumes once")
	var result := {"hp": enemy.hp, "caster_hp": actors[1].hp, "counter": combat.leon_counter_damage, "counter_count": combat.leon_stance_activations, "vulnerability": actors[1].duo_damage_taken_multiplier, "attack_cd": actors[1].attack_cooldown, "used": game.update3_active_run.duo_link_states[MOON].used_this_battle}
	print("AUTO_DUO_COUNTER ", policy, " ", JSON.stringify(result))
	await _dispose()
	return result

func _nested_specialist() -> void:
	await _setup_duo("always")
	var center: Vector2 = game.graph.center("entrance")
	actors[1].global_position = game._clamp_to_combat_walkable(center - Vector2(20, 0))
	enemy.global_position = game._clamp_to_combat_walkable(center + Vector2(20, 0))
	game.update3_active_run.duo_link_states[MOLTEN].charge = 94
	game.update3_active_run.duo_link_states[MOLTEN].ready = false
	game.update3_active_run.duo_link_auto_use = true
	var combat = game.combat_scene
	expect(combat._try_toktok_auto_skill(actors[1], "carapace_ram", enemy), "specialist automatic action prepared")
	expect(enemy.hp == 10000 and GameState.mana == 500, "specialist preparation has no early cost or impact")
	combat.skill_actions.tick(0.55)
	print("NESTED_SPECIALIST_RESULT ", combat.skill_actions.debug_snapshot(), " state=", game.update3_active_run.duo_link_states[MOLTEN])
	expect(combat.skill_actions.pending.size() == 1 and not game.update3_active_run.duo_link_states[MOLTEN].used_this_battle, "automatic duo accepted once during parent commit")
	combat.skill_actions.tick(0.46)
	expect(combat.skill_actions.is_active() and combat.skill_actions.current.key == "duo:" + MOLTEN, "nested duo reuses continuous simulation hold")
	combat.skill_actions.skip()
	for actor in actors + [enemy]: actor.set_physics_process(false)
	expect(combat.skill_actions.commits == 2 and game.update3_active_run.duo_link_states[MOLTEN].used_this_battle, "parent and child commit exactly once")
	expect(not game.combat_paused and UISettings.skill_cutscene_seen.has("skill:carapace_ram"), "specialist and nested duo restore and record independent IDs")
	await _dispose()

func _settings_history() -> void:
	var snapshot: Dictionary = UISettings.snapshot()
	UISettings.reset_skill_cutscene_history(false)
	expect(UISettings.skill_cutscene_seen.is_empty(), "history reset preview")
	UISettings.apply_snapshot(snapshot, false)
	expect(UISettings.skill_cutscene_seen == snapshot.skill_cutscene_seen, "cancel restores prior viewed history")
	UISettings.reset_skill_cutscene_history(true)
	UISettings._load_settings()
	expect(UISettings.skill_cutscene_seen.is_empty(), "applied reset survives config reload")
	UISettings.set_skill_cutscene_policy("once", true)
	UISettings._load_settings()
	expect(UISettings.skill_cutscene_policy == "once", "policy persists in existing config")

func _ram_prepared_targets() -> void:
	for invalidated in ["requested", "collision"]:
		await _setup_duo("always")
		var center: Vector2 = game.graph.center("entrance")
		actors[1].global_position = game._clamp_to_combat_walkable(center - Vector2(35, 0))
		enemy.global_position = game._clamp_to_combat_walkable(center + Vector2(35, 0))
		var blocker = game._create_unit("explorer", DataRegistry.enemy("explorer"), Constants.FACTION_ENEMY, "entrance")
		blocker.global_position = center
		blocker.set_physics_process(false)
		game.enemy_units.append(blocker)
		var combat = game.combat_scene
		expect(combat._try_toktok_auto_skill(actors[1], "carapace_ram", enemy), "ram first collision prepared independently of requested rear enemy")
		expect(combat.skill_actions.current.target == blocker, "ram scene depicts actual first collision")
		if invalidated == "requested": enemy.queue_free()
		else: blocker.queue_free()
		await settle()
		combat.skill_actions.skip()
		expect(not combat.skill_actions.last_result and GameState.mana == 500 and actors[1].skill_cooldowns.is_empty(), invalidated + " freed ram target cancels without costs or typed callback errors")
		expect(combat.contact_feedback_events.is_empty() and not game.combat_paused, invalidated + " invalidation produces no contact and restores hold")
		await _dispose()
