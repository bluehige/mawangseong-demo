extends "res://tools/tests/SkillActionAutomaticFrameTest.gd"
var observing := false
var observations: Dictionary = {}

func run() -> void:
	expect(ProjectSettings.globalize_path("user://").contains("skill_action_review"), "isolated live automatic userdata")
	if not failures.is_empty(): get_tree().quit(1); return
	DataRegistry.load_all()
	UISettings.reset_skill_cutscene_history(false)
	await _setup("always")
	observing = true
	game.set_physics_process(true) # Real production root/actor frames and stage clock.
	await get_tree().create_timer(2.7).timeout
	observing = false
	game.set_physics_process(false)
	for actor in actors + [enemy]: actor.set_physics_process(false)
	expect(observations.size() == 2 and game.combat_scene.skill_actions.completed == 2, "real physics initiates and completes both automatic scenes")
	for key in observations:
		var row: Dictionary = observations[key]
		expect(is_equal_approx(row.min_time, row.max_time), key + " real production combat clock frozen throughout scene")
		expect(float(row.max_age) > 0.90 and float(row.max_age) <= 1.05, key + " independent live presentation clock spans about one second")
		expect(row.prepared_hp == row.last_prepare_hp, key + " no damage during preparation")
	expect(game.combat_scene.contact_feedback_events.size() == 2, "one melee contact and original projectile arrival in real automatic run")
	expect(not game.combat_paused and not game.combat_scene.has_suspended_frame(), "actual automatic continuation restores simulation ownership")
	expect(UISettings.skill_cutscene_seen.has("skill:quick_slash") and UISettings.skill_cutscene_seen.has("skill:fireball"), "actual live skills persist individual IDs")
	print("LIVE_AUTO_OBSERVATIONS ", JSON.stringify(observations))
	game.queue_free()
	await settle()
	print("SKILL_ACTION_LIVE_AUTOMATIC_TEST: %s (%d checks; %d failures)" % ["PASS" if failures.is_empty() else "FAIL", checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func _process(_delta: float) -> void:
	if not observing or not is_instance_valid(game): return
	var action = game.combat_scene.skill_actions
	if action.completed >= 2:
		game.set_physics_process(false)
		for actor in actors + [enemy]: actor.set_physics_process(false)
		return
	if not action.is_active(): return
	var key: String = action.current.key
	if not observations.has(key): observations[key] = {"min_time": game.combat_time, "max_time": game.combat_time, "max_age": 0.0, "prepared_hp": enemy.hp, "last_prepare_hp": enemy.hp}
	var row: Dictionary = observations[key]
	row.min_time = minf(row.min_time, game.combat_time)
	row.max_time = maxf(row.max_time, game.combat_time)
	row.max_age = maxf(row.max_age, action.age)
	if action.age < action.CONTACT_AT: row.last_prepare_hp = enemy.hp
