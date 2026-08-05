extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = GameRootScene.instantiate()
	add_child(game)
	await _settle(5)
	game.campaign_save_enabled = false
	game._onboarding_reset_game()
	GameState.player_name = "제품 흐름 테스트"
	_expect(game.story_feature_enabled, "approved story catalog is enabled in the product root")

	game._onboarding_enter_management_day(1, true)
	await _settle(3)
	_expect(game.current_screen == Constants.SCREEN_DIALOGUE, "DAY 1 management entry opens blocking story dialogue")
	_expect(str(game.story_director.current_scene_id) == "STORY_D01_MANAGEMENT_ENTRY", "DAY 1 product hook selects the approved management scene")
	_expect(game.ui_layer.get_node_or_null("StoryDialogueScreen") != null, "product HUD renders the story dialogue screen")
	_expect(game.ui_layer.find_child("StoryNextButton", true, false) != null, "manual Next control is present")
	_expect(game.ui_layer.find_child("StoryAutoButton", true, false) != null, "opt-in Auto control is present")
	_expect(game.ui_layer.find_child("StorySkipButton", true, false) == null, "first-seen scene exposes no skip control")

	var active_cue_id := str(game.story_director.current_cue_id)
	var payload: Dictionary = game._campaign_save_payload(Constants.SCREEN_DIALOGUE)
	_expect(str(payload.get("story", {}).get("current_cue_id", "")) == active_cue_id, "product save payload stores the exact active cue ID")
	_expect(not payload.get("story", {}).has("cues") and not payload.get("story", {}).has("dialogue_queue"), "story save contains IDs and facts, never dialogue text")

	while game.story_director.is_active():
		game._story_advance_dialogue(true)
	await _settle(2)
	_expect(game.current_screen == Constants.SCREEN_INTRUSION_BRIEF, "management story completion resumes at intrusion information")

	game.set_physics_process(false)
	game._set_screen(Constants.SCREEN_COMBAT)
	game.combat_speed = 2.0
	game.combat_scene.set_pause_state(false, false)
	var marker := Node2D.new()
	marker.position = Vector2.ZERO
	game.effect_root.add_child(marker)
	var combat_tween: Tween = game.combat_scene._create_combat_tween()
	combat_tween.tween_property(marker, "position:x", 100.0, 5.0)
	var combat_animation := AnimatedSprite2D.new()
	combat_animation.speed_scale = 1.75
	game.effect_root.add_child(combat_animation)
	_expect(combat_tween.is_running(), "tracked gameplay tween begins running before dialogue")
	_expect(
		game.story_director.start_scene(
			"STORY_D01_COMBAT_TIME_01",
			game._story_context({"combat_time": 0.0}),
			Constants.SCREEN_COMBAT
		),
		"combat story scene starts through the product director"
	)
	game._story_show_active_scene()
	await _settle(1)
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "combat dialogue remains on SCREEN_COMBAT")
	_expect(game.story_combat_overlay_open and game.combat_paused, "combat dialogue opens a full simulation pause overlay")
	_expect(game.ui_layer.get_node_or_null("StoryCombatDialogueOverlay") != null, "combat overlay is rendered above the live battlefield")
	game.combat_scene.physics_process(0.016)
	_expect(not combat_tween.is_running(), "projectile/delay tween class is paused with the battle")
	_expect(is_zero_approx(combat_animation.speed_scale), "visible combat animation freezes with the battle")
	_expect(is_equal_approx(game.combat_speed, 2.0), "combat speed is preserved while dialogue is open")

	while game.story_director.is_active():
		game._story_advance_dialogue(true)
	await _settle(1)
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "combat dialogue returns to the same combat screen")
	_expect(not game.story_combat_overlay_open and not game.combat_paused, "battle resumes after the final cue")
	_expect(combat_tween.is_running(), "tracked gameplay tween resumes after dialogue")
	_expect(is_equal_approx(combat_animation.speed_scale, 1.75), "visible combat animation restores its prior speed after dialogue")
	_expect(is_equal_approx(game.combat_speed, 2.0), "battle resumes at the previous x2 speed")

	game.combat_scene._clear_active_combat_tweens()
	GameState.day = 4
	game._unlock_kobold_scout_commander()
	_expect(game._campaign_raid_choice_pending(), "DAY 4 defense remains blocked until the mandatory signpost raid is complete")
	game._onboarding_finish_raid_preview()
	await _settle(1)
	_expect(game.current_screen == Constants.SCREEN_RAID, "leaving the DAY 4 preview opens the mandatory raid instead of bypassing it")
	game.raid_selected_mission_id = "d04_signpost_flip"
	game.raid_selected_monster_ids.clear()
	game.raid_selected_monster_ids.append("kobold_scout")
	game.raid_selected_monster_ids.append("goblin")
	game._ensure_raid_selection()
	_expect(game.raid_selected_monster_ids == ["goblin"], "Rolo is removed from escort slots and kept as the fixed raid commander")
	_expect(game._raid_fixed_captain_id(DataRegistry.raid_mission("d04_signpost_flip")) == "kobold_scout", "DAY 4 raid resolves Rolo as its fixed commander")
	var infamy_before := GameState.infamy
	game._start_selected_raid()
	_expect(str(game.story_director.current_scene_id) == "STORY_D04_RAID_ROSTER", "DAY 4 escort confirmation opens the approved roster dialogue before settlement")
	while game.story_director.is_active():
		game._story_advance_dialogue(true)
	await _settle(2)
	_expect(game.completed_raids.has("d04_signpost_flip"), "raid settlement runs only after the roster dialogue closes")
	_expect(not game._campaign_raid_choice_pending(), "completing the signpost raid releases the DAY 4 defense gate")
	_expect(GameState.infamy - infamy_before == 22, "Rolo's fixed command applies the automatic ten-percent infamy bonus")
	_expect(str(game.last_raid_result.get("lines", [])[3]).contains("로로(지휘)") and str(game.last_raid_result.get("lines", [])[3]).contains("곱"), "raid result names both fixed commander and selected escort")
	_expect(str(game.story_director.current_scene_id) == "STORY_D04_RAID_RESOLUTION", "completed raid opens the approved resolution dialogue")
	while game.story_director.is_active():
		game._story_advance_dialogue(true)
	game.queue_free()
	await _settle(3)
	if failed:
		print("V122_STORY_PRODUCT_FLOW_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V122_STORY_PRODUCT_FLOW_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _settle(frame_count: int) -> void:
	for _index in range(frame_count):
		await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		return
	failed = true
	push_error(message)
