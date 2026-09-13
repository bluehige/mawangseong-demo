extends Node
const Game = preload("res://scenes/game/GameRoot.tscn")
const C = preload("res://scripts/core/Constants.gd")
var game
var dir: String
func _ready() -> void:
	call_deferred("_run")
func frames(count: int = 5) -> void:
	for i in range(count):
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
func shot(id: String) -> void:
	await frames()
	var err := get_viewport().get_texture().get_image().save_png(dir.path_join(id + ".png"))
	print("UIUX_SCREEN_CAPTURE %s %s" % [id, err])
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var phase := args[0] if args.size() > 0 else "after"
	dir = ProjectSettings.globalize_path("res://tmp/uiux_u4_u5/" + phase)
	DirAccess.make_dir_recursive_absolute(dir)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	game = Game.instantiate()
	add_child(game)
	await frames()
	game.campaign_save_enabled = false
	await shot("title")
	game._debug_skip_onboarding()
	GameState.day = 2
	game._choose_early_specialization("goblin", "goblin_treasure_hunter")
	game._set_screen(C.SCREEN_MONSTER)
	await shot("monster")
	game._open_settings_screen()
	await shot("settings")
	game._set_screen(C.SCREEN_MANAGEMENT)
	game._start_combat()
	await frames()
	game._set_screen(C.SCREEN_COMBAT)
	game.combat_paused = true
	await shot("combat")
	game._set_screen(C.SCREEN_MANAGEMENT)
	game.result_summary = {"win": false, "metrics": {"alive_monsters": 1, "total_monsters": 3, "treasure_gold_stolen": 40, "facility_disables": 2}, "v122_ledger": {"throne_damage": 125, "gold_stolen": 40, "breach_progress": 0.8, "final_breach_segment": "병영 → 왕좌 전실"}}
	game._set_screen(C.SCREEN_RESULT)
	await shot("result_defeat")
	game.result_summary = {"win": true, "metrics": {"alive_monsters": 3, "total_monsters": 3}}
	game.rewards_pending = {"gold": 60, "mana": 20, "food": 10, "infamy": 5}
	game.last_growth_summary = [{"monster_id":"slime", "display_name":"푸딩", "level_before":1,"level_after":2,"exp_gain":60,"exp_after":10,"next_exp":80},{"monster_id":"imp","display_name":"핀","level_before":1,"level_after":1,"exp_gain":30,"exp_after":30,"next_exp":50},{"monster_id":"goblin","display_name":"곱","level_before":1,"level_after":1,"exp_gain":30,"exp_after":30,"next_exp":50}]
	game._set_screen(C.SCREEN_RESULT)
	await shot("result_win")
	game._set_screen(C.SCREEN_MEMORY_ARCHIVE)
	await shot("memory")
	for resolution in [Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		UISettings.text_scale = 1.15
		game._set_screen(C.SCREEN_MONSTER)
		await shot("monster_720_115")
		game._set_screen(C.SCREEN_RESULT)
		await shot("result_720_115")
	if phase == "after":
		game.onboarding_enabled = false
		game.tutorial_gate_enabled = false
		GameState.day = 23
		GameState.gold = 100000
		GameState.mana = 100000
		GameState.food = 100000
		DisplayServer.window_set_size(Vector2i(1920,1080))
		UISettings.text_scale = 1.0
		for stage in ["stage_03_keep","stage_04_citadel"]:
			game.castle_art_stage = stage
			game._sync_castle_stage_content()
			game._refresh_quarter_map_from_rooms()
			game._set_screen(C.SCREEN_MANAGEMENT)
			game._set_management_tool_tab("build")
			await shot(stage + "_ward_cards")
			game._open_build_palette_for_room("slot_02")
			game._set_build_facility("ward_core")
			await shot(stage + "_ward_review")
			var built: bool = game._confirm_build_preview()
			print("UIUX_WARD_CONFIRM %s %s" % [stage,built])
			await shot(stage + "_ward_installed")
			game._undo_last_management_placement()
		game.selected_monster_id = "goblin"
		game.monster_roster.goblin.level = 6
		game.monster_roster.goblin.bond = 85
		game._set_screen(C.SCREEN_MONSTER)
		await shot("monster_evolution")
		var memory_ids: Array = DataRegistry.memory_entries.keys().filter(func(id): return str(DataRegistry.memory_entry(str(id)).get("monster_id","")) == "goblin")
		if not memory_ids.is_empty():
			game.monster_roster.goblin["unlocked_memory_ids"] = memory_ids
			game._set_screen(C.SCREEN_MEMORY_ARCHIVE)
			await shot("memory_long")
	game.queue_free()
	await frames(3)
	get_tree().quit()
