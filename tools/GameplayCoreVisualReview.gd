extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

func _ready() -> void:
	call_deferred("_open_review_screen")

func _open_review_screen() -> void:
	var game = GameRootScene.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame
	game._debug_skip_onboarding()
	GameState.day = 2
	game._set_screen(Constants.SCREEN_MANAGEMENT)
