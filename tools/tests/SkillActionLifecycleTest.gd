extends "res://tools/tests/SkillActionAutomaticFrameTest.gd"

func run() -> void:
	expect(ProjectSettings.globalize_path("user://").contains("skill_action_review"), "isolated lifecycle userdata")
	if not failures.is_empty(): get_tree().quit(1); return
	DataRegistry.load_all()
	for owner in ["menu", "story", "backlog"]: await _suspended_owner(owner)
	await _invalid_target()
	await _invalid_specialist()
	await _rapid_input()
	await _legacy_config()
	_save_failure()
	print("SKILL_ACTION_LIFECYCLE_TEST: %s (%d checks; %d failures)" % ["PASS" if failures.is_empty() else "FAIL", checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func _suspended_owner(owner: String) -> void:
	await _setup("always")
	var combat = game.combat_scene
	game._physics_process(0.125)
	expect(combat.skill_actions.is_active() and combat.has_suspended_frame(), owner + " begins during real automatic frame")
	if owner == "menu": game._open_pause_menu()
	else:
		if owner == "story": game.story_combat_overlay_open = true
		else: game.continuity.backlog_open = true
		combat.set_pause_state(true, false)
	var mana: int = GameState.mana
	var cursor: int = combat.suspended_frame.index
	var hp: int = enemy.hp
	game._physics_process(0.999)
	expect(combat.requested_pause and game.combat_paused, owner + " owns explicit pause after interrupt")
	expect(GameState.mana == mana and enemy.hp == hp and combat.suspended_frame.index == cursor and not actors[1].skill_cooldowns.has("fireball"), owner + " prevents hidden remaining actor and time advancement")
	if owner == "menu": game._close_pause_menu()
	else:
		game.story_combat_overlay_open = false
		game.continuity.backlog_open = false
		combat.set_pause_state(false, false)
	var guard := 0
	while combat.has_suspended_frame() or combat.skill_actions.is_active():
		guard += 1
		if guard > 6: expect(false, owner + " bounded resume"); break
		if combat.skill_actions.is_active(): combat.skill_actions.skip()
		if combat.has_suspended_frame(): game._physics_process(0.999)
	for actor in actors + [enemy]: actor.set_physics_process(false)
	expect(not game.combat_paused and is_equal_approx(game.combat_time, 0.125), owner + " returns with original time once")
	expect(actors[1].skill_cooldowns.has("fireball") and GameState.mana == 480, owner + " continues remaining actor exactly once")
	game.queue_free()
	await settle()

func _invalid_target() -> void:
	await _setup("always")
	for actor in actors + [enemy]: actor.set_physics_process(false)
	var combat = game.combat_scene
	expect(combat.request_selected_skill(0), "invalid target case accepted initially")
	enemy.queue_free()
	await settle()
	combat.skill_actions.skip()
	expect(not combat.skill_actions.last_result and GameState.mana == 500 and actors[0].skill_cooldowns.is_empty(), "freed target consumes no damage mana cooldown")
	expect(not combat.skill_actions.is_active() and not game.combat_paused, "freed target releases hold")
	game.queue_free()
	await settle()

func _rapid_input() -> void:
	await _setup("always")
	for actor in actors + [enemy]: actor.set_physics_process(false)
	var combat = game.combat_scene
	combat.request_selected_skill(0)
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_2
	game._input(event)
	expect(GameState.mana == 500 and not actors[1].skill_cooldowns.has("fireball"), "world skill shortcut cannot pass through scene")
	event.keycode = KEY_SPACE
	game._input(event)
	game._input(event)
	expect(combat.skill_actions.commits == 1 and combat.contact_feedback_events.size() == 1, "rapid skip input cannot duplicate accepted hit")
	for actor in actors + [enemy]: actor.set_physics_process(false)
	game.queue_free()
	await settle()

func _invalid_specialist() -> void:
	await _setup("always")
	for actor in actors + [enemy]: actor.set_physics_process(false)
	var koko = game._create_unit("graveyard_hound", DataRegistry.monster("graveyard_hound"), Constants.FACTION_MONSTER, "entrance")
	koko.global_position = Vector2(600, 430)
	koko.set_physics_process(false)
	game.monster_units.append(koko)
	expect(game.combat_scene._try_koko_auto_skill(koko, "scent_lock", enemy), "specialist target initially valid")
	enemy.queue_free()
	await settle()
	game.combat_scene.skill_actions.skip()
	expect(not game.combat_scene.skill_actions.last_result and GameState.mana == 500 and koko.skill_cooldowns.is_empty(), "freed specialist target cancels without cost or typed-call errors")
	expect(not game.combat_paused, "invalid specialist releases hold")
	game.queue_free()
	await settle()

func _legacy_config() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "sentinel", 0.37)
	cfg.set_value("interface", "combat_cutin_mode", "full")
	cfg.save(UISettings.SETTINGS_PATH)
	UISettings._load_settings()
	expect(UISettings.skill_cutscene_policy == "once", "legacy full migrates to default once")
	UISettings.mark_skill_cutscene_seen("skill:quick_slash")
	cfg.load(UISettings.SETTINGS_PATH)
	expect(is_equal_approx(float(cfg.get_value("audio", "sentinel", 0)), 0.37), "history save preserves unrelated legacy config sections")
	UISettings.skill_cutscene_seen.clear()
	UISettings._load_settings()
	expect(UISettings.skill_cutscene_seen.has("skill:quick_slash"), "real file reload preserves skill ID")
	cfg = ConfigFile.new()
	cfg.set_value("interface", "combat_cutin_mode", "off")
	cfg.save(UISettings.SETTINGS_PATH)
	UISettings._load_settings()
	expect(UISettings.skill_cutscene_policy == "off", "legacy explicit off preserved")

func _save_failure() -> void:
	var path := ProjectSettings.globalize_path(UISettings.SETTINGS_PATH)
	expect(path.contains("skill_action_review"), "failure injection confined to synthetic settings")
	if not path.contains("skill_action_review"): return
	var backup := path + ".failure-test-backup"
	expect(DirAccess.rename_absolute(path, backup) == OK, "preserve synthetic config before injection")
	expect(DirAccess.make_dir_absolute(path) == OK, "simulate settings write failure with directory at file path")
	expect(not UISettings.mark_skill_cutscene_seen("skill:failure_probe"), "settings failure returned honestly")
	UISettings.skill_cutscene_seen.clear()
	UISettings._load_settings()
	expect(not UISettings.skill_cutscene_seen.has("skill:failure_probe"), "failed write cannot claim persisted history")
	expect(DirAccess.remove_absolute(path) == OK and DirAccess.rename_absolute(backup, path) == OK, "restore synthetic config after failure injection")
