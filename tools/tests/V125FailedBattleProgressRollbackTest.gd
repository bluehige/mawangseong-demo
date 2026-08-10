extends Node

const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameRootScene.instantiate()
	add_child(game)
	await _settle(4)
	game.campaign_save_enabled = false
	game.campaign_auxiliary_save_enabled = false
	game._debug_skip_onboarding()

	_check_defeat_rollback(game)
	_check_victory_commit(game)

	game.queue_free()
	await _settle(2)
	print("V125_FAILED_BATTLE_PROGRESS_ROLLBACK_TEST: %s" % ("FAIL" if failed else "PASS"))
	get_tree().quit(1 if failed else 0)


func _check_defeat_rollback(game: Node) -> void:
	GameState.gold = 900
	GameState.mana = 240
	GameState.food = 17
	GameState.infamy = 510
	game.monster_roster["slime"]["level"] = 3
	game.monster_roster["slime"]["exp"] = 41
	game.monster_roster["slime"]["bond"] = 24
	game.monster_roster["slime"]["bond_rank"] = 0
	game.monster_roster["slime"]["unlocked_memory_ids"] = ["memory_before_battle"]
	game._capture_battle_growth_start()

	GameState.gold -= 120
	GameState.mana -= 70
	GameState.food -= 3
	GameState.infamy += 80
	game.rewards_pending = {"gold": 180, "mana": 60, "food": 2, "infamy": 90}
	game.monster_roster["slime"]["level"] = 5
	game.monster_roster["slime"]["exp"] = 88
	game.monster_roster["slime"]["bond"] = 55
	game.monster_roster["slime"]["bond_rank"] = 2
	game.monster_roster["slime"]["unlocked_memory_ids"].append("memory_from_failed_attempt")
	game._record_monster_contribution("slime", "damage_dealt", 275)
	var contribution_before: Dictionary = game.battle_contribution_stats.duplicate(true)

	var summary: Array = game._commit_or_rollback_battle_progress(false)
	_expect(summary.is_empty() and game.last_growth_summary.is_empty(), "패배 시 성장 결산을 만들지 않음")
	_expect(
		[GameState.gold, GameState.mana, GameState.food, GameState.infamy] == [900, 240, 17, 510],
		"패배 시 전투 전 금화·마력·식량·악명으로 복구"
	)
	var slime: Dictionary = game.monster_roster["slime"]
	_expect(
		int(slime.get("level", 0)) == 3
		and int(slime.get("exp", 0)) == 41
		and int(slime.get("bond", 0)) == 24
		and int(slime.get("bond_rank", -1)) == 0
		and slime.get("unlocked_memory_ids", []) == ["memory_before_battle"],
		"패배 시 레벨·EXP·유대·기억을 전투 전 상태로 복구"
	)
	_expect(
		game.rewards_pending == {"gold": 0, "mana": 0, "food": 0, "infamy": 0},
		"패배 결산 보상을 0으로 고정"
	)
	_expect(game.battle_contribution_stats == contribution_before, "재도전 조언용 전투 기여 기록은 보존")


func _check_victory_commit(game: Node) -> void:
	GameState.gold = 500
	GameState.mana = 100
	GameState.food = 12
	GameState.infamy = 300
	game.monster_roster["slime"]["level"] = 1
	game.monster_roster["slime"]["exp"] = 0
	game.monster_roster["slime"]["bond"] = 0
	game.monster_roster["slime"]["bond_rank"] = 0
	game.monster_roster["slime"]["unlocked_memory_ids"] = []
	game._capture_battle_growth_start()
	game.rewards_pending = {"gold": 75, "mana": 25, "food": 1, "infamy": 40}
	game.monster_roster["slime"]["exp"] = 20
	game._record_monster_contribution("slime", "shared_exp", 20)
	game._record_monster_contribution("slime", "damage_dealt", 300)

	var summary: Array = game._commit_or_rollback_battle_progress(true)
	_expect(not summary.is_empty(), "승리 시 성장 결산 생성")
	_expect(
		[GameState.gold, GameState.mana, GameState.food, GameState.infamy] == [575, 125, 13, 340],
		"승리 시 전투 보상 확정"
	)
	_expect(
		int(game.monster_roster["slime"].get("exp", 0)) > 20
		and int(game.monster_roster["slime"].get("bond", 0)) >= 3,
		"승리 시 공유·활약 EXP와 유대 확정"
	)


func _settle(frames: int) -> void:
	for _index in range(frames):
		await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
