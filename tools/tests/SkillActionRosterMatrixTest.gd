extends "res://tools/tests/PlayerFeedbackHotfixTest.gd"
const Modes = preload("res://scripts/systems/campaign/CampaignModeService.gd")
var forms: Array[Dictionary] = []
var rows: Array[Dictionary] = []
var form_rows: Array[Dictionary] = []
var duo_rows: Array[Dictionary] = []
var actor
var ally
var enemies: Array = []
var screenshots := 0
var unsupported_hud_screenshots := 0
var serial := 0
var stop_at := 0

func _ready() -> void: call_deferred("run") # Matrix has an explicit longer watchdog.

func run() -> void:
	get_tree().create_timer(480.0).timeout.connect(func(): push_error("Roster matrix timeout"); get_tree().quit(1))
	expect(ProjectSettings.globalize_path("user://").contains("skill_action_review"), "isolated roster matrix")
	if not failures.is_empty(): get_tree().quit(1); return
	DataRegistry.load_all()
	game = GameRootScene.instantiate()
	add_child(game)
	await settle()
	game.continuity.acknowledge_update()
	game._set_campaign_save_path_for_tests("")
	game._onboarding_reset_game()
	game._onboarding_enter_management_day(1, true)
	game._debug_skip_onboarding()
	game.story_feature_enabled = false
	game.campaign_save_enabled = false
	game.campaign_autosave_pending = false
	game.set_process(false)
	game.set_physics_process(false)
	game._set_screen(Constants.SCREEN_COMBAT, false)
	output_dir = "res://tmp/skill_action_roster_matrix"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	_build_forms()
	for form in forms:
		await _prepare(form)
		var frames: SpriteFrames = actor.sprite.sprite_frames
		var good := frames != null
		var frame_counts := {}
		for animation in ["idle_down", "attack_down", "skill_down", "down"]:
			frame_counts[animation] = frames.get_frame_count(animation) if frames.has_animation(animation) else 0
			good = good and int(frame_counts[animation]) >= (4 if animation in ["attack_down", "skill_down"] else 1)
		form_rows.append({"species": form.species, "form": form.id, "kind": form.kind, "expected_sprite": form.sprite, "runtime_sprite": actor.sprite_path, "animations": good, "frame_counts": frame_counts, "path_normalized": actor.sprite_path != form.sprite})
		expect(good and not actor.sprite_path.is_empty(), form.id + " real art and four poses resolve")
		var slots: Array = game.combat_scene.skill_slots_for(actor)
		for slot in range(slots.size()):
			if slots[slot] == null: continue
			for route in ["manual", "automatic"]: await _skill_case(form, slot, str(slots[slot]), route)
	for link_id in DataRegistry.update3_duo_links:
		var definition: Dictionary = DataRegistry.update3_duo_links[link_id]
		var members: Array = definition.member_instance_ids
		var a_species: String = DataRegistry.monster_instances[members[0]].species_id
		var b_species: String = DataRegistry.monster_instances[members[1]].species_id
		for a in forms:
			if a.species != a_species: continue
			for b in forms:
				if b.species != b_species: continue
				for route in ["manual", "automatic"]: await _duo_case(str(link_id), a, b, route)
	var blocked: Array = rows.filter(func(r): return r.status == "UNSUPPORTED_BASELINE")
	var report := {"product_scope": "controlled real GUI matrix; manual means controller request, not manual HUD casting", "roster_species": DataRegistry.monsters.keys(), "forms": form_rows, "skill_cases": rows, "duo_cases": duo_rows, "checks": checks, "failures": failures, "screenshots": screenshots, "action_screenshots": screenshots - unsupported_hud_screenshots, "unsupported_hud_screenshots": unsupported_hud_screenshots, "unsupported_cases": blocked.size(), "royal_skills": [], "passives": [], "human_mouse": "NOT_RUN", "full_campaign": "NOT_RUN"}
	for crown_id in DataRegistry.update4_crown_evolutions:
		var crown: Dictionary = DataRegistry.update4_crown_evolutions[crown_id]
		report.royal_skills.append({"crown": crown_id, "species": crown.monster_id, "skill_id": crown.royal_skill_id, "status": "BASE_GUARD_CONNECTED_BRANCH_INHERITANCE_UNSUPPORTED" if crown.royal_skill_id == "royal_jelly_bastion" else "DATA_SERVICE_ONLY_NO_RUNTIME_SLOT", "action": "MATRIX" if crown.royal_skill_id == "royal_jelly_bastion" else "NOT_RUN"})
	for species in DataRegistry.monsters:
		var passive: String = DataRegistry.monster(species).get("passive_skill_id", "")
		if passive != "": report.passives.append({"species": species, "skill_id": passive, "separate_action_scene": "NOT_APPLICABLE_PASSIVE"})
	var file := FileAccess.open(output_dir.path_join("matrix.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("ROSTER_MATRIX_COUNTS forms=", forms.size(), " skill_cases=", rows.size(), " unsupported=", blocked.size(), " duo_cases=", duo_rows.size(), " screenshots=", screenshots)
	print("SKILL_ACTION_ROSTER_MATRIX_TEST: %s (%d checks; %d failures)" % ["PASS" if failures.is_empty() else "FAIL", checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func _build_forms() -> void:
	var species_ids: Array = []
	for instance in DataRegistry.monster_instances.values():
		var species: String = instance.get("species_id", "")
		if species != "" and not species_ids.has(species): species_ids.append(species)
	species_ids.sort()
	expect(species_ids.size() == DataRegistry.monsters.size(), "runtime species catalog equals playable roster instances")
	for species in species_ids:
		forms.append({"id": species + ":base", "kind": "base", "species": species, "sprite": str(DataRegistry.monster(species).get("sprite", ""))})
		for promotion_id in DataRegistry.evolution_rules:
			var rule: Dictionary = DataRegistry.evolution_rules[promotion_id]
			if str(rule.monster_id) == species: forms.append({"id": promotion_id, "kind": "promotion", "species": species, "sprite": str(rule.combat_sprite)})
		for crown_id in DataRegistry.update4_crown_evolutions:
			var crown: Dictionary = DataRegistry.update4_crown_evolutions[crown_id]
			if str(crown.monster_id) == species: forms.append({"id": crown_id, "kind": "crown", "species": species, "sprite": str(crown.combat_sprite)})

func _prepare(form: Dictionary) -> void:
	game.combat_scene.clear_effects()
	game.continuity.reset_combat()
	var prior_inspector = game.ui_layer.find_child("CombatUnitInspector", true, false)
	if is_instance_valid(prior_inspector): prior_inspector.get_parent().remove_child(prior_inspector); prior_inspector.queue_free()
	for old in game.monster_units + game.enemy_units:
		if is_instance_valid(old): old.get_parent().remove_child(old); old.queue_free()
	game.monster_units.clear()
	game.enemy_units.clear()
	game.combat_scene.contact_feedback_events.clear()
	game.combat_scene.contact_feedback_tokens.clear()
	game.combat_scene.requested_pause = false
	game.combat_paused = false
	game.combat_time = 0.0
	game.combat_scene.leon_stance_id = ""
	game.update3_active_run.equipped_duo_links = []
	game.update3_active_run.duo_link_auto_use = false
	game.update3_active_run.duo_link_active_effects = []
	game.update4_active_run["campaign_mode_id"] = "legacy"
	game.monster_roster[form.species] = {"level": 3, "exp": 0, "room": "entrance", "promotion_id": form.id if form.kind == "promotion" else "", "specialization_id": ""}
	if form.kind == "crown":
		game.update4_active_run.campaign_mode_id = Modes.COUNCIL_MODE_ID
		var instance_id := ""
		for id in DataRegistry.monster_instances:
			if str(DataRegistry.monster_instances[id].species_id) == form.species: instance_id = id; break
		game.update4_active_run["crown"] = {"crown_form_id": form.id, "selected_instance_id": instance_id}
		game.update4_active_run["upper_floor"] = {"crown_suppressed": false}
	var stats: Dictionary = game._scaled_monster_stats(form.species)
	expect(str(stats.get("sprite", "")) == form.sprite, form.id + " actual stat builder chooses expected current form")
	actor = _create(form.species, stats, true, 0)
	ally = _create("spore_healer", DataRegistry.monster("spore_healer"), true, 1)
	actor.hp = maxi(1, int(actor.max_hp * 0.2))
	ally.hp = maxi(1, int(ally.max_hp * 0.1))
	enemies = [_create("explorer", DataRegistry.enemy("explorer"), false, 2), _create("explorer", DataRegistry.enemy("explorer"), false, 3)]
	for enemy in enemies:
		enemy.hp = 10000
		enemy.max_hp = 10000
		enemy.apply_duo_mark(8.0, "matrix")
	game.selected_unit = actor
	game.global_directive = Constants.DIRECTIVE_DEFENSE
	GameState.mana = 10000
	UISettings.set_skill_cutscene_policy("always", false)
	UISettings.reset_skill_cutscene_history(false)
	await get_tree().process_frame

func _create(species: String, stats: Dictionary, monster: bool, index: int):
	var unit = game._create_unit(species, stats, Constants.FACTION_MONSTER if monster else Constants.FACTION_ENEMY, "entrance")
	unit.global_position = game._clamp_to_combat_walkable(game.graph.center("entrance") + Vector2(index * 14 - 21, 0))
	unit.set_physics_process(false)
	unit.attack_cooldown = 100.0
	if monster: game.monster_units.append(unit)
	else: game.enemy_units.append(unit)
	return unit

func _skill_case(form: Dictionary, slot: int, skill_id: String, route: String) -> void:
	var failures_before := failures.size()
	await _prepare(form)
	var combat = game.combat_scene
	if skill_id == "flame_zone":
		for enemy in enemies: enemy.current_room = "spike_corridor"
	for other in DataRegistry.monster(form.species).get("skill_slots", []):
		if other != null and str(other) != skill_id: actor.set_skill_cooldown(str(other), 1000.0)
	var supported: bool = skill_id in combat.IMPLEMENTED_ACTION_SKILLS
	var accepted := false
	var automatic_path := "try_auto_monster_skill"
	if route == "manual": accepted = combat.request_selected_skill(slot)
	elif skill_id == "spectral_transfer": accepted = combat.try_bebe_auto_rescue(actor); automatic_path = "try_bebe_auto_rescue"
	elif skill_id in ["scent_lock", "home_guard_bark"]: accepted = combat._try_koko_auto_skill(actor, skill_id, enemies[0] if skill_id == "scent_lock" else null); automatic_path = "specialist_koko"
	elif skill_id in ["carapace_ram", "patch_plates"]: accepted = combat._try_toktok_auto_skill(actor, skill_id, enemies[0] if skill_id == "carapace_ram" else null); automatic_path = "specialist_toktok"
	else: accepted = combat.try_auto_monster_skill(actor)
	var row := {"species": form.species, "form": form.id, "skill_id": skill_id, "route": route, "automatic_path": automatic_path if route == "automatic" else "request_selected_skill", "accepted": accepted, "scene": combat.skill_actions.is_active(), "current_sprite": actor.sprite_path, "status": "PASS" if supported else "UNSUPPORTED_BASELINE", "screenshot": "", "committed_success": false}
	if not supported:
		expect(not accepted and not combat.skill_actions.is_active() and GameState.mana == 10000, form.id + skill_id + " unsupported data-only skill cannot claim cast/cost/history")
		expect(combat.hud._selected_unit_skill_summary(actor).contains("현재 전투 미지원"), "unsupported HUD does not claim ready automatic skill")
		if route == "manual" and slot == 0:
			combat.build_combat_ui()
			expect(combat.hud.selected_unit_dynamic_labels["status"].text.contains("전투 미지원"), "actual native inspector names unavailable active skills")
			row.screenshot = await _shot(form.id + "__unsupported_HUD")
			unsupported_hud_screenshots += 1
	else:
		expect(accepted and combat.skill_actions.is_active(), form.id + skill_id + route + " actual action path accepts")
		if combat.skill_actions.is_active():
			expect(combat.skill_actions.current.key == "skill:" + skill_id and combat.skill_actions.actors[0].sprite_frames == actor.sprite.sprite_frames, "correct ID/current art mapping")
			var baseline: float = game.combat_time
			combat.skill_actions.tick(0.55)
			row.committed_success = combat.skill_actions.last_result
			expect(row.committed_success and combat.skill_actions.commits > 0 and game.combat_time == baseline, "real effect succeeds once under logical hold")
			row.screenshot = await _shot(form.id + "__" + skill_id + "__" + route)
			combat.skill_actions.skip()
			for unit in game.monster_units + game.enemy_units: unit.set_physics_process(false)
			expect(not combat.skill_actions.is_active() and not game.combat_paused, "action and original pause restore")
		else: row.status = "FAIL"
	if failures.size() > failures_before: row.status = "FAIL"
	rows.append(row)
	print("MATRIX_SKILL ", form.id, " ", skill_id, " ", route, " ", row.status)

func _duo_case(link_id: String, a: Dictionary, b: Dictionary, route: String) -> void:
	var failures_before := failures.size()
	await _prepare(a)
	# A deployment has a unique instance per species. The generic heal fixture
	# must not impersonate the second duo member before its chosen form is added.
	game.monster_units.erase(ally)
	ally.get_parent().remove_child(ally)
	ally.queue_free()
	# Both members use the same actual promotion/crown stat builder used above.
	game.monster_roster[b.species] = {"level": 3, "exp": 0, "room": "entrance", "promotion_id": b.id if b.kind == "promotion" else "", "specialization_id": ""}
	if b.kind == "crown":
		game.update4_active_run.campaign_mode_id = Modes.COUNCIL_MODE_ID
		var second_instance := ""
		for id in DataRegistry.monster_instances:
			if str(DataRegistry.monster_instances[id].species_id) == b.species: second_instance = id; break
		game.update4_active_run.crown = {"crown_form_id": b.id, "selected_instance_id": second_instance}
	var b_stats: Dictionary = game._scaled_monster_stats(b.species)
	expect(str(b_stats.get("sprite", "")) == b.sprite, "second member actual stat builder chooses expected form")
	var second = _create(b.species, b_stats, true, 1)
	game.update3_active_run.equipped_duo_links = [link_id]
	game.update3_active_run.duo_link_states = {link_id: {"charge": 100 if route == "manual" else 99, "active": true, "ready": route == "manual", "used_this_battle": false}}
	var combat = game.combat_scene
	game.update3_active_run.duo_link_auto_use = route == "automatic"
	if route == "manual": game._activate_update3_duo_link(link_id)
	else:
		var source: Dictionary = DataRegistry.update3_duo_links[link_id].gauge_sources[0]
		game._record_update3_duo_link_action(str(source.member_instance_id), str(source.source_id), int(source.threshold), "matrix:" + str(serial))
	var row := {"link_id": link_id, "members": DataRegistry.update3_duo_links[link_id].member_instance_ids, "forms": [a.id, b.id], "route": route, "scene": combat.skill_actions.is_active(), "status": "PASS", "screenshot": "", "both_crowns_fixture_only": a.kind == "crown" and b.kind == "crown"}
	expect(row.scene, link_id + a.id + b.id + route + " duo accepted")
	if row.scene:
		expect(combat.skill_actions.actors.size() == 2 and combat.skill_actions.actors[0].sprite_frames == actor.sprite.sprite_frames and combat.skill_actions.actors[1].sprite_frames == second.sprite.sprite_frames, "both exact current member arts")
		combat.skill_actions.tick(0.55)
		expect(combat.skill_actions.last_result and game.update3_active_run.duo_link_states[link_id].used_this_battle, "real original duo activates once")
		row.screenshot = await _shot(link_id + "__" + a.id + "__" + b.id + "__" + route)
		combat.skill_actions.skip()
		for unit in game.monster_units + game.enemy_units: unit.set_physics_process(false)
		expect(not game.combat_paused, "duo hold resumes")
	else: row.status = "FAIL"
	if failures.size() > failures_before: row.status = "FAIL"
	duo_rows.append(row)
	print("MATRIX_DUO ", link_id, " ", a.id, " ", b.id, " ", route, " ", row.status)

func _shot(key: String) -> String:
	if DisplayServer.get_name() == "headless": return "NOT_RUN_HEADLESS"
	await RenderingServer.frame_post_draw
	var raw := get_viewport().get_texture().get_image()
	var path := output_dir.path_join("%03d_%s.png" % [serial, key.replace(":", "_")])
	serial += 1
	# Freeze the stage while PNG encoding; logical gameplay remains held already.
	var stage = game.combat_scene.skill_actions.stage
	if is_instance_valid(stage): stage.set_process(false)
	expect(raw.save_png(path) == OK, "real viewport image written")
	screenshots += 1
	return path
