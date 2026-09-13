extends Node
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const UnitScript = preload("res://scripts/units/Unit.gd")
const WaveManagerScript = preload("res://scripts/combat/WaveManager.gd")
const CORE = ["slime", "goblin", "imp"]
const OUT = "res://tmp/uiux_economy_20260913"
var checks := 0
var failed := false
var evidence := {"kind": "CONDITIONAL_ECONOMY_API_LEDGER_NOT_PLAYTHROUGH", "days": [], "actions": []}

func _ready() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error("ECONOMY_FAIL: " + label)

func resources() -> Dictionary:
	return {"gold": GameState.gold, "mana": GameState.mana, "food": GameState.food, "infamy": GameState.infamy}

func difference(before: Dictionary, after: Dictionary) -> Dictionary:
	var result := {}
	for key in before:
		result[key] = int(after[key]) - int(before[key])
	return result

func action(label: String, before: Dictionary, cost: Dictionary) -> void:
	var after := resources()
	for key in before:
		check(int(after[key]) == int(before[key]) - int(cost.get(key, 0)), label + " exact charge " + key)
	evidence.actions.append({"day": GameState.day, "action": label, "cost": cost.duplicate(true), "before": before, "after": after})

func game_instance():
	var g = GameRootScene.instantiate()
	g.campaign_save_enabled = false
	g.campaign_auxiliary_save_enabled = false
	g.campaign_save_v4_enabled = false
	g.campaign_save_v5_enabled = false
	add_child(g)
	g._debug_skip_onboarding()
	g.set_process(false)
	g.set_physics_process(false)
	return g

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var g = game_instance()
	await get_tree().process_frame
	_budget_recovery(g)
	g.queue_free()
	await get_tree().process_frame
	GameState.reset()
	g = game_instance()
	await get_tree().process_frame
	evidence["initial_resources"] = resources()
	for day in range(1, 16):
		check(GameState.day == day, "actual daily progression")
		var opening := resources()
		if day == 1:
			for id in CORE:
				var before := resources()
				g.selected_monster_id = id
				g._train_selected_monster()
				action("train_" + id, before, g.MONSTER_TRAINING_COST)
		if day == 3:
			var connector: Dictionary = g._v122_defender_connector()
			var before := resources()
			check(g._build_v122_defender_connector(), "unlocked optional defender door built")
			action("defender_door", before, connector.get("cost", {}))
			var paid := resources()
			check(not g._build_v122_defender_connector() and resources() == paid, "duplicate door no charge")
		if day == 7:
			for id in g.rooms:
				if str(g.rooms[id].get("facility_role", "")) == "barracks":
					g.selected_room = id
					break
			var cost: Dictionary = g._facility_upgrade_cost()
			var before := resources()
			check(g._upgrade_selected_facility(), "barracks upgrade with earned resources")
			action("barracks_upgrade", before, cost)
		if day == 8:
			var slot := ""
			for id in g.rooms:
				if str(g.rooms[id].get("facility_role", "")) == "build_slot":
					slot = str(id)
					break
			check(slot != "", "existing empty construction slot")
			var before := resources()
			var cost: Dictionary = g._facility_definition("watch_post").get("cost", {})
			check(g._change_room_facility(slot, "watch_post"), "watch post rebuilt in real slot")
			action("watch_post_relocation", before, cost)
		if day == 12:
			var rule: Dictionary = g._evolution_rule_choice("slime")
			var before := resources()
			check(g._promotion_block_reason("slime") == "", "promotion meets earned level/bond and result unlock flags")
			g._promote_monster("slime")
			check(str(g.monster_roster.slime.promotion_id) != "", "promotion applied")
			action("first_promotion", before, rule.get("cost", {}))
		var pre_battle := resources()
		if day == 15:
			check(g._stage_two_upgrade_budget_ready(), "earned budget meets stage review")
			check(g._first_promotion_ready(), "first promotion gate met")
		var waves = WaveManagerScript.new()
		waves.setup(day, g._active_wave_catalog(day), {})
		g.rewards_pending = {"gold": 0, "mana": 0, "food": 0, "infamy": 0}
		if not waves.schedule.is_empty():
			g._capture_battle_growth_start()
			for entry in waves.schedule:
				var stats: Dictionary = g.combat_scene._scaled_enemy_stats(str(entry.enemy_id), entry)
				var unit = UnitScript.new()
				unit.faction = Constants.FACTION_ENEMY
				unit.unit_id = str(entry.enemy_id)
				unit.display_name = str(stats.get("display_name", unit.unit_id))
				unit.exp_reward = int(stats.get("exp", 0))
				unit.infamy_reward = int(stats.get("infamy", 0))
				g.combat_scene.on_unit_downed(unit)
				unit.free()
			var growth: Array = g._commit_or_rollback_battle_progress(true)
			g.result_summary = {"win": true, "growth": growth}
			g.current_screen = Constants.SCREEN_RESULT
			check(g._choose_result_growth(CORE[(day - 1) % 3]), "one real growth choice")
			g._apply_campaign_result_flags(true)
		var closing := resources()
		check(difference(pre_battle, closing) == g.rewards_pending, "only actual kill rewards credited")
		evidence.days.append({"day": day, "opening": opening, "before_battle": pre_battle, "kill_rewards": g.rewards_pending.duplicate(true), "closing": closing, "enemies": waves.schedule.size(), "stage": g.castle_art_stage})
		if day < 15:
			GameState.advance_day()
			var expected_income := {"gold": GameState.gold_income, "mana": GameState.mana_income, "food": GameState.food_income, "infamy": GameState.infamy_income}
			check(difference(closing, resources()) == expected_income, "actual next-day income once")
	check(g.campaign_stage_two_upgrade_funded and g.campaign_stage_two_unlock_ready and g.castle_art_stage == "stage_02_castle", "conditional ledger reaches Stage02 through result API")
	evidence["checks"] = checks
	evidence["result"] = "FAIL" if failed else "PASS"
	var file = FileAccess.open(OUT + "/economy.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(evidence, "	"))
	file.close()
	g.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	print("UIUX_ECONOMY_FLOW_TEST: %s (%d checks)" % [evidence.result, checks])
	get_tree().quit(1 if failed else 0)

func _budget_recovery(g: Node) -> void:
	g.campaign_chapter_two_started = true
	g.campaign_stage_two_upgrade_funded = false
	g.campaign_stage_two_unlock_ready = false
	GameState.day = 14
	var cost: Dictionary = g._stage_two_upgrade_cost()
	GameState.gold = int(cost.gold) - 1
	GameState.infamy = int(cost.infamy) - 1
	g._apply_campaign_result_flags(true)
	check(not g.campaign_stage_two_upgrade_funded, "DAY14 insufficient budget remains unfunded")
	GameState.advance_day()
	var before := resources()
	var after_income := before.duplicate(true)
	for i in range(3):
		check(g._stage_two_upgrade_budget_ready(), "DAY15 income repairs stale funding flag")
	check(resources() == before and not g.campaign_stage_two_upgrade_funded and not g.campaign_stage_two_unlock_ready, "budget queries do not spend or unlock")
	g._apply_campaign_result_flags(false)
	check(not g.campaign_stage_two_unlock_ready, "loss does not unlock stage")
	GameState.gold = int(cost.gold) - 1
	check(not g._stage_two_upgrade_budget_ready(), "one gold short still blocked")
	GameState.gold = int(cost.gold)
	GameState.infamy = int(cost.infamy) - 1
	check(not g._stage_two_upgrade_budget_ready(), "one infamy short still blocked")
	GameState.infamy = int(cost.infamy)
	g.campaign_chapter_two_started = false
	check(not g._stage_two_upgrade_budget_ready(), "funds alone do not bypass chapter")
	g.campaign_chapter_two_started = true
	GameState.day = 13
	check(not g._stage_two_upgrade_budget_ready(), "early day cannot pass new review")
	GameState.day = 15
	before = resources()
	g._apply_campaign_result_flags(true)
	check(g.campaign_stage_two_upgrade_funded and g.campaign_stage_two_unlock_ready, "victory persists recovered funding and unlock")
	check(resources() == before, "stage review is existing holding condition, no invented fee")
	evidence["recovery"] = {"day14_gold": int(cost.gold) - 1, "day14_infamy": int(cost.infamy) - 1, "day15_after_income": after_income, "exact_threshold_victory": before, "cost": cost}
