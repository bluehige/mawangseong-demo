extends "res://tools/tests/PlayerFeedbackHotfixTest.gd"
const PresentationScript = preload("res://scripts/ui/CombatDamagePresentation.gd")
const UIFontScript = preload("res://scripts/ui/UIFont.gd")
var units := {}
var enemy: Node

func run() -> void:
	output_dir = "res://tmp/combat_presentation"
	expect(ProjectSettings.globalize_path("user://").contains("combat_presentation_review"), "synthetic userdata is isolated")
	if not failures.is_empty(): get_tree().quit(1); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	DataRegistry.load_all()
	game = GameRootScene.instantiate()
	add_child(game)
	await settle()
	expect(game.get("combat_scene") != null and game.get("graph") != null, "game runtime initialized without script failures")
	if not failures.is_empty():
		get_tree().quit(1)
		return
	game._set_campaign_save_path_for_tests("")
	game._onboarding_reset_game()
	game._onboarding_enter_management_day(1, true)
	game._debug_skip_onboarding()
	game.story_feature_enabled = false
	game.set_process(false)
	game.set_physics_process(false)
	game._set_screen(Constants.SCREEN_COMBAT, false)
	game.combat_paused = false
	game.monster_units.clear()
	game.enemy_units.clear()
	for species in ["slime", "goblin", "imp", "ghost_housemaid", "graveyard_hound", "armored_beetle", "stone_sentinel", "war_drummer"]:
		if not game.monster_roster.has(species):
			game.monster_roster[species] = {"level": 1, "exp": 0, "room": "entrance", "promotion_id": "", "specialization_id": ""}
		var unit = game._create_unit(species, DataRegistry.monster(species), Constants.FACTION_MONSTER, "entrance")
		unit.global_position = Vector2(600, 430)
		unit.max_hp = 5000
		unit.hp = 5000
		unit.set_physics_process(false)
		units[species] = unit
		game.monster_units.append(unit)
	enemy = game._create_unit("official_hero_leon", DataRegistry.enemy("official_hero_leon"), Constants.FACTION_ENEMY, "entrance")
	enemy.global_position = Vector2(630, 430)
	enemy.max_hp = 10000
	enemy.hp = 10000
	enemy.set_physics_process(false)
	game.enemy_units = [enemy]
	_test_missing_routes()
	_test_number_contract()
	await _capture_numbers()
	game.queue_free()
	await settle()
	print("COMBAT_PRESENTATION_PROTOTYPE_TEST: %s (%d checks; %d failures)" % ["PASS" if failures.is_empty() else "FAIL", checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func reset_feedback() -> void:
	game.combat_scene.clear_effects()
	game.combat_scene.contact_feedback_events.clear()
	game.combat_scene.contact_feedback_tokens.clear()
	game.combat_paused = false
	enemy.hp = enemy.max_hp
	enemy.down = false
	enemy.damage_reduction = 0.0
	enemy.duo_damage_taken_multiplier = 1.0
	enemy.soft_counter_damage_taken_multiplier = 1.0
	enemy.boss_damage_taken_multiplier = 1.0
	enemy.relic_aura_magic_multiplier = 1.0
	enemy.patch_plate_barrier = 0
	enemy.duo_barrier = 0

func contact_sum() -> int:
	var result := 0
	for event in game.combat_scene.contact_feedback_events: result += int(event.damage)
	return result

func _test_missing_routes() -> void:
	var combat = game.combat_scene
	reset_feedback()
	combat.leon_stance_id = "leon_stance_duelist"
	var before: int = units.goblin.hp
	combat._apply_leon_duelist_counter(units.goblin, enemy, 100)
	expect(units.goblin.hp == before - 18 and contact_sum() == 18, "real Leon counter preserves capped damage and gains feedback")
	expect(combat.contact_feedback_events.size() == 1, "counter produces exactly one contact")
	combat.leon_stance_id = ""
	reset_feedback()
	before = enemy.hp
	var broom: Dictionary = combat.perform_bebe_broom(units.ghost_housemaid)
	expect(int(broom.targets) == 1 and enemy.hp < before, "real broom hits the boss")
	expect(contact_sum() == before - enemy.hp and combat.contact_feedback_events.size() == 1, "boss broom now shares real damage feedback without knockback")
	reset_feedback()
	units.goblin.apply_duo_damage_redirect(units.slime, 4.0, 0.25)
	var protector_before: int = units.slime.hp
	before = units.goblin.hp
	var dealt: int = units.goblin.receive_damage(20)
	combat._apply_combat_hit_feedback(enemy, units.goblin, dealt, false, "melee")
	expect(units.goblin.hp == before - 15 and units.slime.hp == protector_before - 5, "redirect preserves original 15/5 HP split")
	expect(contact_sum() == 20 and combat.contact_feedback_events.size() == 2, "both actual recipients get one number each")
	units.goblin.duo_redirect_timer = 0.0
	reset_feedback()
	before = enemy.hp
	game._emit_update3_hunger_wave()
	expect(contact_sum() == before - enemy.hp and combat.contact_feedback_events.size() == 1, "hunger wave actual hit gains feedback")
	reset_feedback()
	before = enemy.hp
	game._apply_update3_devouring_pulse("entrance")
	expect(contact_sum() == before - enemy.hp and combat.contact_feedback_events.size() == 1, "devouring pulse actual hit gains feedback")
	reset_feedback()
	enemy.duo_mark_timer = 6.0
	before = enemy.hp
	game._apply_moon_scent_hunt("link_moon_scent_hunt")
	expect(combat.contact_feedback_events.size() == 2 and contact_sum() == before - enemy.hp and contact_sum() <= 80, "moon hunt preserves two capped hits and their two sources")
	reset_feedback()
	before = enemy.hp
	game._apply_molten_carapace("link_molten_carapace")
	expect(combat.contact_feedback_events.size() == 1 and contact_sum() == before - enemy.hp, "molten impact gains feedback without new damage")
	reset_feedback()
	var state := {"remaining": 5.0, "targets": [{"node_id": enemy.get_instance_id(), "tick_accumulator": 0.0, "damage_done": 26}]}
	var updated: Dictionary = game._update_molten_carapace_burn(state, 1.0, {"direct_damage_cap": 41, "burn_damage_per_second": 3})
	expect(contact_sum() == 3 and int(updated.targets[0].damage_done) == 29, "molten burn preserves its cap accumulator and gains one tick feedback")
	reset_feedback()
	before = enemy.hp
	game._apply_stone_march("link_stone_march")
	expect(combat.contact_feedback_events.size() == 1 and contact_sum() == before - enemy.hp, "stone march gains real hit feedback")

func _test_number_contract() -> void:
	var combat = game.combat_scene
	reset_feedback()
	game.combat_time = 50.0
	combat.spawn_damage_number(enemy.global_position, 11, enemy.faction, enemy)
	combat.spawn_damage_number(enemy.global_position, 7, enemy.faction, enemy)
	expect(combat.damage_presentation.active.size() == 1 and combat.damage_presentation.active[0].label.text == "-18", "legacy anchored visual API retains exact short-hit sum")
	game.combat_time += 0.2
	combat.spawn_damage_number(enemy.global_position, 5, enemy.faction, enemy)
	expect(combat.damage_presentation.active.size() == 2, "legacy later-hit API remains separate")
	reset_feedback()
	var mana_before: int = GameState.mana
	var rewards_before: Dictionary = game.rewards_pending.duplicate(true)
	var cooldown_before: Dictionary = units.goblin.skill_cooldowns.duplicate(true)
	var dealt: int = enemy.receive_damage(17)
	combat._apply_combat_hit_feedback(units.goblin, enemy, dealt, false, "melee", "same_contact")
	combat._apply_combat_hit_feedback(units.goblin, enemy, dealt, false, "melee", "same_contact")
	expect(combat.contact_feedback_events.size() == 1 and combat.damage_presentation.submitted == 1, "duplicate contact token cannot duplicate number or other feedback")
	expect(GameState.mana == mana_before and game.rewards_pending == rewards_before and units.goblin.skill_cooldowns == cooldown_before, "presentation never changes resources rewards or cooldowns")
	reset_feedback()
	combat._apply_combat_hit_feedback(units.goblin, enemy, 11, false, "melee")
	combat._apply_combat_hit_feedback(units.goblin, enemy, 7, false, "melee")
	expect(combat.damage_presentation.active.size() == 1 and int(combat.damage_presentation.active[0].total) == 18, "same recipient source and kind sum exactly")
	combat._apply_combat_hit_feedback(units.imp, enemy, 9, false, "melee")
	combat._apply_combat_hit_feedback(units.goblin, enemy, 20, false, "skill_melee")
	expect(combat.damage_presentation.active.size() == 3, "other attackers and skills cannot merge into a basic hit")
	game.combat_speed = 3.0
	combat.damage_presentation.tick(0.11)
	combat._apply_combat_hit_feedback(units.goblin, enemy, 4, false, "melee")
	expect(combat.damage_presentation.active.size() == 4, "x3 uses presentation-time merge window")
	var clock_before: float = combat.damage_presentation.clock
	combat.set_pause_state(true, false)
	combat.damage_presentation.tick(5.0)
	expect(combat.damage_presentation.clock == clock_before, "pause freezes number lifetime and pulse")
	combat.set_pause_state(false, false)
	combat.damage_presentation.tick(0.73)
	expect(combat.damage_presentation.active.is_empty() and combat.damage_presentation.pool.size() == 4, "expired labels are recycled")
	reset_feedback()
	combat._show_combat_hit_feedback(enemy.global_position, "important", enemy, 70, false, "skill_melee")
	for i in range(200): combat._show_combat_hit_feedback(enemy.global_position, "burst_%d" % i, enemy, 1, false, "melee")
	expect(combat.damage_presentation.active.size() == 32 and combat.damage_presentation.suppressed > 0, "concurrent burst has bounded display allocation")
	var strong_kept := false
	for row in combat.damage_presentation.active:
		strong_kept = strong_kept or int(row.peak) == 70
		combat.damage_presentation.tick(0.0)
		expect(float(row.label.get_meta("damage_impact_scale")) <= 1.25, "impact scale has a hard upper bound")
	expect(strong_kept, "weak overflow does not evict a stronger skill number")
	var locale := TranslationServer.get_locale()
	for language in ["ko", "en", "zh_CN"]:
		TranslationServer.set_locale(language)
		var font: Font = UIFontScript.font_for_role(UIFontScript.ROLE_DAMAGE)
		expect(font.resource_path.ends_with("NEXON_Maplestory_Bold.otf"), language + " numeric font stays Maple Bold")
		for index in range(11): expect(font.has_char("0123456789-".unicode_at(index)), language + " required numeric glyph")
	TranslationServer.set_locale(locale)
	for zoom in [0.78, 1.0, 1.85]:
		var factor := PresentationScript.screen_compensation(zoom, Vector2(1280, 720), Vector2(1920, 1080))
		expect(is_equal_approx(24.0 * factor * zoom * (1280.0 / 1920.0), 24.0), "numeric pixel size stays constant at zoom %.2f" % zoom)
	if DisplayServer.get_name() != "headless":
		var started := Time.get_ticks_usec()
		var maximum := 0
		for iteration in range(64):
			var frame_started := Time.get_ticks_usec()
			combat.damage_presentation._layout()
			maximum = maxi(maximum, Time.get_ticks_usec() - frame_started)
		var visible_numbers := 0
		for row in combat.damage_presentation.active: visible_numbers += int(row.label.visible)
		var report := {"fixture": "32 concurrent numbers / synthetic 200-hit burst", "iterations": 64, "mean_layout_us": (Time.get_ticks_usec() - started) / 64.0, "maximum_layout_us": maximum, "visible_numbers": visible_numbers, "snapshot": combat.damage_presentation.debug_snapshot(), "low_end_pc": "NOT_RUN"}
		var file := FileAccess.open(output_dir.path_join("number_layout_measure.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "\t"))

func _capture_numbers() -> void:
	if DisplayServer.get_name() == "headless": return
	for size in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		DisplayServer.window_set_size(size)
		await settle()
		for zoom in [0.78, 1.85]:
			reset_feedback()
			game.combat_view_zoom = zoom
			game.combat_camera.zoom = Vector2.ONE * zoom
			var values := [7, 28, 66, 1234]
			for i in range(values.size()):
				var position := Vector2(500 + i * 120, 400)
				game.combat_scene.spawn_damage_number(position, values[i], Constants.FACTION_ENEMY)
			game.combat_scene.damage_presentation.tick(0.09)
			for row in game.combat_scene.damage_presentation.active:
				expect(row.label.mouse_filter == Control.MOUSE_FILTER_IGNORE, "damage number never intercepts input")
				expect(row.label.get_theme_constant("shadow_offset_y") > 0, "number shadow is configured")
				expect(row.label.visible and row.has("screen_rect"), "numeric label has a visible safe screen rectangle")
				for other in game.combat_scene.damage_presentation.active:
					if other.label != row.label: expect(not Rect2(row.screen_rect).intersects(other.screen_rect), "long adjacent numbers do not overlap at either zoom")
			await capture("damage_%dx%d_zoom_%02d" % [size.x, size.y, int(zoom * 100)])
