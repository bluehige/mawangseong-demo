extends "res://tools/tests/SkillActionDuoTest.gd"
const GHOST := "link_ghostly_evacuate"
const SPORE := "link_spore_jelly_shelter"

func run() -> void:
	expect(ProjectSettings.globalize_path("user://").contains("skill_action_review"), "isolated support userdata")
	if not failures.is_empty(): get_tree().quit(1); return
	DataRegistry.load_all()
	for link in [GHOST, SPORE]:
		var off: Dictionary = await _support_duo("off", link)
		var full: Dictionary = await _support_duo("always", link)
		expect(off == full, link + " support gameplay equivalent with scene disabled/enabled")
	await _specialist_equivalence("graveyard_hound", "scent_lock")
	await _specialist_equivalence("ghost_housemaid", "spectral_transfer")
	await _fixed_heal()
	print("SKILL_ACTION_SUPPORT_TEST: %s (%d checks; %d failures)" % ["PASS" if failures.is_empty() else "FAIL", checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func _support_setup(policy: String, species_list: Array) -> void:
	await _setup_duo(policy)
	for actor in actors: actor.queue_free()
	game.monster_units.clear()
	actors.clear()
	for species in species_list:
		var actor = game._create_unit(species, DataRegistry.monster(species), Constants.FACTION_MONSTER, "entrance")
		actor.global_position = Vector2(600 + actors.size() * 20, 430)
		actor.set_physics_process(false)
		actors.append(actor)
		game.monster_units.append(actor)
	actors[-1].hp = 20
	game.update3_active_run.duo_link_auto_use = false

func _support_duo(policy: String, link: String) -> Dictionary:
	await _support_setup(policy, ["slime", "ghost_housemaid" if link == GHOST else "spore_healer", "goblin"])
	game.update3_active_run.equipped_duo_links = [link]
	game.update3_active_run.duo_link_states = {link: {"charge": 100, "active": true, "ready": true, "used_this_battle": false}}
	var action = game.combat_scene.skill_actions
	var before: Vector2 = actors[2].global_position
	game._activate_update3_duo_link(link)
	if policy == "always":
		expect(action.current.target == (actors[2] if link == GHOST else null), link + " visual target is actual supported ally or area, never enemy")
		expect(action.current.animation == "skill_down", "support uses existing support frames")
		action.tick(0.38)
		expect(is_equal_approx(action.actors[0].position.x, 460.0), "support caster does not charge enemy")
		expect(enemy.hp == 10000 and actors[2].global_position == before, "support preparation makes no gameplay changes")
		action.skip()
	for actor in actors + [enemy]: actor.set_physics_process(false)
	expect(enemy.hp == 10000 and game.combat_scene.contact_feedback_events.is_empty(), "support scene never fabricates damage")
	if link == GHOST: expect(actors[2].global_position != before, "prepared actual ally rescued")
	else: expect(actors[2].duo_barrier > 0 and actors[2].hp > 20, "original support shield and heal applied")
	var result := {"hp": actors[2].hp, "barrier": actors[2].duo_barrier, "position": actors[2].global_position, "enemy_hp": enemy.hp, "used": game.update3_active_run.duo_link_states[link].used_this_battle}
	print("SUPPORT_DUO ", policy, " ", link, " ", result)
	await _dispose()
	return result

func _specialist_equivalence(species: String, skill: String) -> void:
	var outcomes: Array = []
	for policy in ["off", "always"]:
		await _support_setup(policy, [species, "goblin"])
		var combat = game.combat_scene
		var accepted: bool = combat._try_koko_auto_skill(actors[0], skill, enemy) if species == "graveyard_hound" else combat.try_bebe_auto_rescue(actors[0])
		expect(accepted, skill + " real specialist route accepted")
		if policy == "always":
			expect(combat.skill_actions.is_active() and GameState.mana == 500, skill + " valid prepared scene delays cost")
			combat.skill_actions.skip()
		for actor in actors + [enemy]: actor.set_physics_process(false)
		outcomes.append({"mana": GameState.mana, "cd": actors[0].skill_cooldowns.duplicate(), "ally_barrier": actors[1].duo_barrier, "enemy_hp": enemy.hp, "mark": enemy.scent_mark_timer, "rescue": actors[1].rescue_phase_timer})
		await _dispose()
	expect(outcomes[0] == outcomes[1], skill + " existing costs cooldown and effects preserved")

func _fixed_heal() -> void:
	await _support_setup("always", ["spore_healer", "goblin", "imp"])
	actors[1].hp = 10
	actors[2].hp = 40
	game.selected_unit = actors[0]
	var combat = game.combat_scene
	expect(combat.request_selected_skill(0), "healing action accepted")
	var intended = combat.skill_actions.current.target
	expect(intended == actors[1], "healing target fixed during preparation")
	actors[2].hp = 1 # Controlled external change must not silently retarget accepted action.
	game.selected_unit = actors[2]
	combat.skill_actions.skip()
	for actor in actors + [enemy]: actor.set_physics_process(false)
	expect(actors[1].hp > 10 and actors[2].hp == 1, "heal commits to prepared ally despite selection and health changes")
	await _dispose()
