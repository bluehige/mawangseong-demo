extends Node
const Game = preload("res://scenes/game/GameRoot.tscn")
const C = preload("res://scripts/core/Constants.gd")
var game
var dir: String
func _ready() -> void:
	call_deferred("_run")
func frames(count: int = 4) -> void:
	for i in range(count):
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
func shot(id: String) -> void:
	await frames()
	var err := get_viewport().get_texture().get_image().save_png(dir.path_join(id + ".png"))
	print("UIUX_LATE_CAPTURE %s requested=%s actual=%s err=%d" % [id,id,game.current_screen,err])
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	dir = ProjectSettings.globalize_path("res://tmp/uiux_u4_u5/" + (args[0] if args.size() > 0 else "after"))
	DirAccess.make_dir_recursive_absolute(dir)
	DisplayServer.window_set_size(Vector2i(1920,1080))
	game = Game.instantiate()
	add_child(game)
	await frames()
	game.campaign_save_enabled = false
	game._debug_skip_onboarding()
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	GameState.day = 16
	for mode in [{"size":Vector2i(1920,1080),"scale":1.0,"suffix":""},{"size":Vector2i(1280,720),"scale":1.15,"suffix":"_720_115"},{"size":Vector2i(1920,1080),"scale":0.9,"suffix":"_1080_90"},{"size":Vector2i(1920,1080),"scale":1.15,"suffix":"_1080_115"},{"size":Vector2i(1280,720),"scale":0.9,"suffix":"_720_90"},{"size":Vector2i(1280,720),"scale":1.0,"suffix":"_720_100"}]:
		DisplayServer.window_set_size(mode.size)
		UISettings.text_scale = float(mode.scale)
		var suffix: String = mode.suffix
		if args.has("utility"):
			await utility_screens(suffix)
			continue
		for target in [C.SCREEN_CAMPAIGN_MODE,C.SCREEN_FRONT_SELECTION,C.SCREEN_HEART_SELECTION,C.SCREEN_DUO_LINK_LOADOUT,C.SCREEN_REGION_SELECTION,C.SCREEN_OUTPOST_MANAGEMENT,C.SCREEN_UPPER_FLOOR,C.SCREEN_CHRONICLE,C.SCREEN_CYCLE_DOCTRINE,C.SCREEN_CYCLE_DECREE,C.SCREEN_CHALLENGE_SEAL,C.SCREEN_CONTRACT_BOARD,C.SCREEN_RAID,C.SCREEN_ENDING_ARCHIVE,C.SCREEN_NAME_ENTRY]:
			game._set_screen(target)
			await shot(str(target) + suffix)
		game.onboarding_dialogue_queue = [{"speaker":"CHR_GOLDIN","emotion":"accounting","text":"보상 정산 완료. 악명 +1, 골드 소량. 위엄은 장부상 무형자산입니다. 다음 방어 준비까지 확인하겠습니다."}]
		game.onboarding_dialogue_index = 0
		game._set_screen(C.SCREEN_DIALOGUE)
		await shot("dialogue" + suffix)
		game._open_settings_screen()
		for category in ["general","display","audio"]:
			game.settings_category = category
			game._set_screen(C.SCREEN_SETTINGS)
			await shot("settings_" + category + suffix)
	game.queue_free()
	await frames(2)
	get_tree().quit()

func utility_screens(suffix: String) -> void:
	GameState.day = 2
	game.pending_precombat_snapshot = game.combat_scene.build_precombat_snapshot(false)
	for target in [C.SCREEN_INTRUSION_BRIEF,C.SCREEN_DEFENSE_START,C.SCREEN_RAID_PREVIEW,C.SCREEN_ENDING,C.SCREEN_OUTPOST_BATTLE]:
		if target == C.SCREEN_DEFENSE_START:
			game.defense_start_remaining = 3.0
			game.set_physics_process(false)
		if target == C.SCREEN_OUTPOST_BATTLE:
			GameState.day = 10
			var type_id := "outpost_supply_burrow"
			var hp := int(DataRegistry.update4_outpost_types[type_id].base_hp)
			game.update4_active_run["outpost"] = {"type_id":type_id,"level":1,"max_hp":hp,"current_hp":hp,"assigned_monster_ids":DataRegistry.monster_instances.keys().slice(0,3)}
		game._set_screen(target)
		await shot(str(target) + suffix)
	game._start_tutorial_practice()
	await shot("tutorial_practice" + suffix)
	game.set_physics_process(true)
	GameState.day = 16
