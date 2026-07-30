extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const UnitActor = preload("res://scripts/units/Unit.gd")
const LAYOUT_ID := "stage01_dual_front_candidate_01"
const LAYOUT_PATH := "res://data/dungeon_quarter/layouts/stage01_dual_front_01.json"

var failed := false


class FactionUnit:
	extends Node

	var faction := ""


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	var layout = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT_PATH))
	_expect(layout is Dictionary, "candidate layout fixture loads")
	if not layout is Dictionary:
		_finish()
		return
	var game := GameRootScene.instantiate()
	add_child(game)
	await _settle(4)
	game.campaign_save_enabled = false
	game._debug_skip_onboarding()
	DataRegistry.register_quarter_layout(LAYOUT_ID, layout, false)
	game.quarter_layout_id = LAYOUT_ID
	game._setup_dungeon_graph()
	game.current_screen = Constants.SCREEN_MANAGEMENT

	GameState.day = 2
	GameState.gold = 1200
	GameState.mana = 150
	_expect(not game._v122_can_build_defender_connector(), "connector cannot be built before DAY 3")
	_expect(not game._build_v122_defender_connector(), "locked connector rejects construction")
	_expect(GameState.gold == 1200 and GameState.mana == 150, "locked construction spends no resources")

	GameState.day = 3
	_expect(game._v122_can_build_defender_connector(), "connector becomes purchasable on DAY 3")
	_expect(game._build_v122_defender_connector(), "DAY 3 connector construction succeeds")
	_expect(GameState.gold == 200 and GameState.mana == 50, "construction spends exactly 1000 gold and 100 mana")
	_expect(
		bool(game.v122_connector_state.get("built", false))
			and int(game.v122_connector_state.get("built_day", 0)) == 3,
		"runtime records permanent construction state"
	)
	_expect(
		bool(game._v122_current_battle_plan().get("defender_connector", {}).get("built", false)),
		"current battle plan consumes the built state"
	)
	var connector: Dictionary = game._v122_current_battle_plan().get("defender_connector", {})
	var anchor_value: Array = connector.get("world_anchor", [])
	var connector_anchor := Vector2(float(anchor_value[0]), float(anchor_value[1]))
	var defender := FactionUnit.new()
	defender.faction = Constants.FACTION_MONSTER
	game.add_child(defender)
	var enemy := FactionUnit.new()
	enemy.faction = Constants.FACTION_ENEMY
	game.add_child(enemy)
	_expect(not game.graph.is_walkable(connector_anchor), "connector center remains outside the shared enemy walk map")
	_expect(
		game._clamp_unit_to_combat_walkable(connector_anchor, defender) == connector_anchor,
		"built connector grants its crossing width to defenders"
	)
	_expect(
		game._clamp_unit_to_combat_walkable(connector_anchor, enemy) != connector_anchor,
		"enemy floor clamping still rejects the connector"
	)
	var runtime_defender = UnitActor.new()
	runtime_defender.faction = Constants.FACTION_MONSTER
	runtime_defender.set_physics_process(false)
	game.add_child(runtime_defender)
	runtime_defender.set_path([connector_anchor])
	_expect(
		runtime_defender.path_points.has(connector_anchor),
		"the real unit path setter preserves the defender crossing anchor"
	)
	var runtime_enemy = UnitActor.new()
	runtime_enemy.faction = Constants.FACTION_ENEMY
	runtime_enemy.set_physics_process(false)
	game.add_child(runtime_enemy)
	runtime_enemy.set_path([connector_anchor])
	_expect(
		not runtime_enemy.path_points.has(connector_anchor),
		"the real unit path setter clamps the same anchor away for enemies"
	)
	_expect(
		bool(game._v122_save_progression_payload().get("connector_state", {}).get("built", false)),
		"campaign save payload contains the built state"
	)
	_expect(not game._build_v122_defender_connector(), "permanent connector cannot be purchased twice")
	_expect(GameState.gold == 200 and GameState.mana == 50, "duplicate construction spends no resources")

	_expect(game._undo_last_management_placement(), "normal management undo can revert the latest construction")
	_expect(not bool(game.v122_connector_state.get("built", false)), "undo returns the connector to unbuilt")
	_expect(GameState.gold == 1200 and GameState.mana == 150, "undo refunds both construction resources")

	_expect(game._build_v122_defender_connector(), "connector can be rebuilt after undo")
	var confirmed_plan: Dictionary = game._v122_current_battle_plan()
	game._capture_v122_battle_confirmation(confirmed_plan)
	game.v122_connector_state = {
		"connector_id": "rear_cross_lane_connector",
		"built": false,
		"built_day": 0
	}
	game._apply_v122_retry_snapshot()
	_expect(
		bool(game.v122_connector_state.get("built", false)),
		"retry restores the last confirmed connector state"
	)

	game.queue_free()
	await _settle(2)
	_finish()


func _settle(frames: int) -> void:
	for _index in range(frames):
		await get_tree().process_frame


func _finish() -> void:
	if failed:
		print("V122_DEFENDER_CONNECTOR_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("V122_DEFENDER_CONNECTOR_TEST: PASS")
		get_tree().quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
