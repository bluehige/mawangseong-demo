extends Node
## Safe branch-only entry: no campaign save is opened or written.
var game: Node

func _ready() -> void:
	ProjectSettings.set_setting("debug/approved_map_step1",true)
	LanguageSettings.set_locale("ko",false)
	game = load("res://scenes/game/GameRoot.tscn").instantiate()
	game.campaign_save_enabled = false
	game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v5_enabled = false
	game.campaign_save_v6_enabled = false
	add_child(game)
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game.tutorial_manager.active = false
	game.story_feature_enabled = false
	game.story_director.cancel_active_scene()
	game.onboarding_dialogue_queue.clear()
	game._set_screen("management",false)
	# Stage one is an inspection workspace, with no campaign time progression.
	game.set_process(false)
	game._shutdown_audio_for_exit()

func _exit_tree() -> void:
	if is_instance_valid(game):
		game.campaign_autosave_pending = false
