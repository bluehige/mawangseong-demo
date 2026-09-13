extends Node

const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const WaveManagerScript = preload("res://scripts/combat/WaveManager.gd")
const UnitScript = preload("res://scripts/units/Unit.gd")
const CORE = ["slime", "goblin", "imp"]
const EVIDENCE = "res://tmp/uiux_growth_20260913"
var checks := 0
var failed := false
var report := {"kind": "CONDITIONAL_REWARD_LEDGER_NOT_CAMPAIGN_PLAYTHROUGH", "profiles": {}}

func _ready() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error("GROWTH_EVIDENCE_FAIL: " + label)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE))
	var g = GameRootScene.instantiate()
	g.campaign_save_enabled = false
	g.campaign_auxiliary_save_enabled = false
	g.campaign_save_v4_enabled = false
	g.campaign_save_v5_enabled = false
	add_child(g)
	await get_tree().process_frame
	g._debug_skip_onboarding()
	g.onboarding_enabled = false
	g.tutorial_gate_enabled = false
	g.story_feature_enabled = false
	g.set_process(false)
	g.set_physics_process(false)
	var original: Dictionary = g.monster_roster.duplicate(true)
	report["layout_id"] = g.quarter_layout_id
	_damage_boundaries(g)
	_training_boundaries(g, original)
	for focus in [false, true]:
		g.monster_roster = original.duplicate(true)
		for id in CORE:
			g.monster_roster[id]["level"] = 1
			g.monster_roster[id]["exp"] = 0
		var days: Array = []
		var milestones := {}
		var battle_index := 0
		var total_shared := 0
		var total_kill_gold := 0
		for day in range(1, 31):
			GameState.day = day
			if day in [6, 12, 22, 30]:
				milestones[str(day)] = _power(g)
			if day == 30:
				break # DAY30 readiness; do not claim the final battle was won.
			var waves = WaveManagerScript.new()
			waves.setup(day, g._active_wave_catalog(day), {})
			if waves.schedule.is_empty():
				days.append({"day": day, "enemies": 0, "shared_exp": 0, "growth_choice": "none"})
				continue
			g._capture_battle_growth_start()
			g.rewards_pending = {"gold": 0, "mana": 0, "food": 0, "infamy": 0}
			var shared := 0
			for entry in waves.schedule:
				var stats: Dictionary = g.combat_scene._scaled_enemy_stats(str(entry.enemy_id), entry)
				check(not stats.is_empty(), "known enemy DAY%d %s" % [day, entry.enemy_id])
				var unit = UnitScript.new()
				unit.faction = Constants.FACTION_ENEMY
				unit.unit_id = str(entry.enemy_id)
				unit.display_name = str(stats.get("display_name", unit.unit_id))
				unit.exp_reward = int(stats.get("exp", 0))
				unit.infamy_reward = int(stats.get("infamy", 0))
				shared += maxi(5, int(unit.exp_reward / 3))
				g.combat_scene.on_unit_downed(unit)
				unit.free()
			var growth: Array = g._commit_or_rollback_battle_progress(true)
			for row in growth:
				if str(row.monster_id) in CORE:
					check(int(row.shared_exp) == shared and int(row.activity_exp) == 0, "actual reward accounting DAY%d" % day)
			var chosen := "none"
			if focus:
				chosen = CORE[battle_index % CORE.size()]
				g.current_screen = Constants.SCREEN_RESULT
				g.result_summary = {"win": true, "growth": growth}
				check(g._choose_result_growth(chosen), "real focus choice DAY%d" % day)
				var roster_after: Dictionary = g.monster_roster.duplicate(true)
				check(not g._choose_result_growth(chosen) and g.monster_roster == roster_after, "focus single application DAY%d" % day)
			battle_index += 1
			total_shared += shared
			total_kill_gold += int(g.rewards_pending.gold)
			days.append({"day": day, "enemies": waves.schedule.size(), "shared_exp": shared, "kill_gold": g.rewards_pending.gold, "growth_choice": chosen})
		report.profiles["rotating_focus" if focus else "shared_only_lower_bound"] = {"days": days, "before_day": milestones, "shared_exp_per_monster": total_shared, "gross_kill_gold": total_kill_gold, "training_spend": 0}
	var simulation = preload("res://tools/BalanceSimulation.gd").new()
	GameState.day = 12
	var resources := [GameState.gold, GameState.mana, GameState.food, GameState.infamy]
	var basis: Dictionary = simulation.apply_growth_evidence(g, report, "rotating_focus")
	check(not basis.has("error") and int(g.monster_roster.slime.level) == int(report.profiles.rotating_focus.before_day["12"].slime.level), "simulation uses ledger level/EXP")
	check([GameState.gold, GameState.mana, GameState.food, GameState.infamy] == resources, "ledger import does not fabricate money")
	var before_import: Dictionary = g.monster_roster.duplicate(true)
	GameState.day = 13
	check(simulation.apply_growth_evidence(g, report, "rotating_focus").has("error") and g.monster_roster == before_import, "missing milestone rejects without partial mutation")
	var invalid: Dictionary = report.duplicate(true)
	invalid.profiles.rotating_focus.before_day["12"].imp.exp = -1
	GameState.day = 12
	check(simulation.apply_growth_evidence(g, invalid, "rotating_focus").has("error") and g.monster_roster == before_import, "invalid last monster rejects atomically")
	simulation.free()
	_rollback(g)
	report["checks"] = checks
	report["result"] = "FAIL" if failed else "PASS"
	var output = FileAccess.open(EVIDENCE + "/growth_evidence.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "	"))
	output.close()
	g.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	print("UIUX_GROWTH_EVIDENCE_TEST: %s (%d checks)" % [report.result, checks])
	get_tree().quit(1 if failed else 0)

func _power(g: Node) -> Dictionary:
	var result := {}
	for id in CORE:
		var stats: Dictionary = g._scaled_monster_stats(id)
		result[id] = {"level": g.monster_roster[id].level, "exp": g.monster_roster[id].exp, "hp": stats.max_hp, "atk": stats.atk, "def": stats.def, "promotion_id": g.monster_roster[id].get("promotion_id", ""), "preparation_active": g._growth_preparation_active(id)}
	return result

func _damage_boundaries(g: Node) -> void:
	var unit = g._create_unit("explorer", DataRegistry.enemy("explorer"), Constants.FACTION_ENEMY, "entrance")
	unit.set_physics_process(false)
	unit.hp = 1
	unit.duo_barrier = 7
	unit.patch_plate_barrier = 5
	unit.patch_plate_barrier_timer = 2.0
	var rewards_before: Dictionary = g.rewards_pending.duplicate(true)
	var roster_before: Dictionary = g.monster_roster.duplicate(true)
	for amount in [0, -1, -100]:
		check(unit.receive_damage(amount) == 0, "non-positive physical hit returns zero")
		check(unit.receive_magic_damage(amount) == 0, "non-positive magic hit returns zero")
		check(unit.hp == 1 and not unit.down and unit.duo_barrier == 7 and unit.patch_plate_barrier == 5, "no HP/barrier consumption")
	unit.relic_aura_magic_multiplier = 0.1
	check(unit.receive_magic_damage(1) == 0 and unit.patch_plate_barrier == 5, "magic rounded to zero stays zero")
	check(g.rewards_pending == rewards_before and g.monster_roster == roster_before, "zero hit grants no kill rewards or growth")
	unit.patch_plate_barrier = 0
	unit.duo_barrier = 0
	unit.relic_aura_magic_multiplier = 1.0
	unit.receive_damage(1)
	check(unit.down and unit.hp == 0, "positive minimum hit still kills")
	var after: Dictionary = g.rewards_pending.duplicate(true)
	unit.receive_damage(100)
	check(g.rewards_pending == after and int(after.gold) == int(rewards_before.get("gold", 0)) + 60, "downed signal grants reward only once")
	unit.queue_free()

func _training_boundaries(g: Node, original: Dictionary) -> void:
	g.monster_roster = original.duplicate(true)
	g.selected_monster_id = "slime"
	var r: Dictionary = g.monster_roster.slime
	GameState.day = 1
	r.level = 1
	r.exp = 40
	r.training_day = 0
	r.training_count_today = 0
	GameState.gold = 29
	g._train_selected_monster()
	check(r.exp == 40 and r.level == 1 and GameState.gold == 29, "insufficient funds no growth or charge")
	GameState.gold = 90
	g._train_selected_monster()
	check(r.level == 2 and r.exp == 10 and GameState.gold == 60, "training preserves threshold overflow and exact cost")
	g._train_selected_monster()
	g._train_selected_monster()
	check(r.exp == 30 and r.training_count_today == 2 and GameState.gold == 30, "two daily trainings; third costs nothing")
	GameState.day = 2
	g._train_selected_monster()
	check(r.exp == 50 and r.training_count_today == 1 and GameState.gold == 0, "daily limit resets")
	for day in [10, 20, 30]:
		GameState.day = day
		r.level = g._training_level_cap()
		r.exp = 0
		GameState.gold = 100
		g._train_selected_monster()
		check(r.exp == 0 and GameState.gold == 100, "chapter training cap no charge DAY%d" % day)
	report["training"] = {"exp_per_action": g.MONSTER_TRAINING_EXP, "gold_per_action": g.MONSTER_TRAINING_COST.gold, "actions_per_monster_day": 2, "level_caps": [3, 5, 8], "from_level1_zero_exp_to_level3": {"exp": 130, "actions": 7, "gold": 210, "minimum_days": 4}}

func _rollback(g: Node) -> void:
	g._capture_battle_growth_start()
	var before: Dictionary = g.monster_roster.duplicate(true)
	var resources := [GameState.gold, GameState.mana, GameState.food, GameState.infamy]
	g.monster_roster.slime.exp += 55
	g.rewards_pending = {"gold": 120, "mana": 40, "food": 0, "infamy": 10}
	GameState.gold -= 20
	g._commit_or_rollback_battle_progress(false)
	check(g.monster_roster == before and [GameState.gold, GameState.mana, GameState.food, GameState.infamy] == resources, "failed battle no growth or resource farming")
