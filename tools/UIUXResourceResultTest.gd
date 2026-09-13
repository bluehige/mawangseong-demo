extends Node
const Scene = preload("res://scenes/game/GameRoot.tscn")
const OUT = "res://tmp/uiux_resource_result_20260914"
var checks := 0
var failed := false
var records: Array = []

func _ready() -> void:
	call_deferred("_run")

func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error("RESOURCE_RESULT_FAIL: " + text)

func settle() -> void:
	for i in range(3):
		await get_tree().process_frame
		await RenderingServer.frame_post_draw

func shot(name: String) -> void:
	await settle()
	check(get_viewport().get_texture().get_image().save_png(OUT + "/" + name + ".png") == OK, "capture " + name)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		UISettings.text_scale = 1.0 if resolution.x == 1920 else 1.15
		for win in [true, false]:
			var g = Scene.instantiate()
			g.campaign_save_enabled = false
			g.campaign_auxiliary_save_enabled = false
			g.campaign_save_v4_enabled = false
			g.campaign_save_v5_enabled = false
			add_child(g)
			await settle()
			g._debug_skip_onboarding()
			g.set_process(false)
			g.set_physics_process(false)
			g._clear_units()
			GameState.day = 6
			GameState.gold = 500
			GameState.mana = 100
			g.current_screen = Constants.SCREEN_COMBAT
			g.rewards_pending = {"gold": 0, "mana": 0, "food": 0, "infamy": 0}
			g._capture_battle_growth_start()
			var actor = g._create_unit("imp", g._scaled_monster_stats("imp"), Constants.FACTION_MONSTER, "entrance")
			actor.global_position = g.graph.center("entrance")
			actor.set_physics_process(false)
			g.monster_units.append(actor)
			g.selected_unit = actor
			var treasure: String = g.combat_scene._treasure_room()
			var thief = g._create_unit("thief", DataRegistry.enemy("thief"), Constants.FACTION_ENEMY, treasure)
			thief.global_position = g.graph.center(treasure)
			thief.set_physics_process(false)
			g.enemy_units.append(thief)
			g.spawned_count = 1
			g.combat_scene.update_room_effects(5.1)
			check(GameState.gold == 400 and g.treasure_gold_stolen_this_battle == 100, "real theft tick")
			thief.current_room = "spike_corridor"
			thief.global_position = g.graph.center("spike_corridor")
			actor.global_position = thief.global_position + Vector2(50,0)
			var mana_cost: int = g._current_skill_mana_cost(DataRegistry.skill("flame_zone"))
			check(mana_cost > 0 and g.combat_scene._execute_selected_unit_skill(1), "real paid skill")
			check(GameState.mana == 100 - mana_cost, "real skill payment")
			thief.receive_damage(10000)
			check(int(g.rewards_pending.gold) == 60 and int(g.rewards_pending.mana) == 20, "real kill reward")
			g.combat_scene.finish_combat(win, "자원 결산 재현 · 실제 스킬·약탈·격퇴 처리")
			await settle()
			var balance: Dictionary = g.result_summary.get("resource_balance", {})
			check(balance.get("battle_delta", {}).get("gold") == -100 and balance.get("battle_delta", {}).get("mana") == -mana_cost, "pre-settlement delta")
			check(balance.get("delta", {}).get("gold") == (-40 if win else 0), "reward does not hide theft; loss restored")
			check(balance.get("delta", {}).get("mana") == (20 - mana_cost if win else 0), "mana settlement reconciles")
			var stable: Dictionary = balance.duplicate(true)
			g.combat_scene.finish_combat(win, "duplicate")
			check(g.result_summary.resource_balance == stable, "settlement exactly once")
			var model: Dictionary = g.get_meta("v122_result_view_model")
			check(model.get("resource_balance", {}) == balance, "view model keeps actual balance")
			var label = g.find_child("ResultResourceBalance", true, false)
			var reward = g.find_child("ResultRewards", true, false)
			check(label != null and reward != null, "both reward and net shown")
			check(label.text.contains("-40" if win else "복구"), "win/loss copy distinct")
			check(label.get_global_rect().position.y >= reward.get_global_rect().end.y, "reward and net do not overlap")
			check(label.get_global_rect().end.y <= g.find_child("ResultRetryAction", true, false).get_global_rect().position.y, "next action stays clear")
			check(label.get_line_count() == 1, "net line fits at text scale")
			var tag := "%d_%s" % [resolution.x, "win" if win else "loss"]
			records.append({"case": tag, "resource_balance": balance, "skill_cost": mana_cost})
			await shot(tag)
			if resolution.x == 1920 and win and FileAccess.file_exists(OUT + "/BeforeWorkspace.gd"):
				g.find_child("V122ResultScreen", true, false).queue_free()
				await settle()
				var previous = load(OUT + "/BeforeWorkspace.gd").new()
				previous.setup(g, g.management_scene.hud)
				previous.build_result(model, "방어 성공", false)
				await shot("before_1920_win")
			g.result_summary.erase("resource_balance")
			g._set_screen(Constants.SCREEN_RESULT)
			await settle()
			check(g.find_child("ResultResourceBalance", true, false) == null, "old result with no ledger shows no fabricated zero")
			g.queue_free()
			await settle()
	var f = FileAccess.open(OUT + "/results.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"result": "FAIL" if failed else "PASS", "checks": checks, "cases": records}, "	"))
	f.close()
	print("UIUX_RESOURCE_RESULT_TEST: %s (%d checks)" % ["FAIL" if failed else "PASS", checks])
	get_tree().quit(1 if failed else 0)
