extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const PRODUCT_LAYOUT_ID := "stage01_dual_front_candidate_01"
const LEGACY_LAYOUT_ID := "current_demo_v2_master_grid_01"
const LEGACY_LAYOUT_PATH := "res://data/dungeon_quarter/starting_layout.json"

var failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	var product_layout := DataRegistry.quarter_layout(PRODUCT_LAYOUT_ID)
	var legacy_layout := _load_layout(LEGACY_LAYOUT_PATH)
	_expect(DataRegistry.quarter_default_layout_id == PRODUCT_LAYOUT_ID, "dual-front layout is the product default")
	_expect(not product_layout.is_empty(), "product dual-front layout is registered")
	_expect(
		str(product_layout.get("combat_topology", {}).get("activation_state", "")) == "product_default",
		"product layout activation marker is explicit"
	)
	_expect(not legacy_layout.is_empty(), "legacy product layout fixture loads")
	if product_layout.is_empty() or legacy_layout.is_empty():
		_finish()
		return

	var game := GameRootScene.instantiate()
	add_child(game)
	await _settle(4)
	game.campaign_save_enabled = false
	game._onboarding_reset_game()
	game._debug_skip_onboarding()
	game.current_screen = Constants.SCREEN_MANAGEMENT
	_expect(game.quarter_layout_id == PRODUCT_LAYOUT_ID, "new games start on the dual-front product layout")
	_expect(
		bool(game.graph.validation_summary().get("ok", false)),
		"new-game product graph validates"
	)

	var base_payload: Dictionary = game._campaign_save_payload(Constants.SCREEN_MANAGEMENT)
	var legacy_payload := base_payload.duplicate(true)
	legacy_payload["world"]["quarter_layout_id"] = LEGACY_LAYOUT_ID
	legacy_payload["world"]["quarter_layout"] = legacy_layout.duplicate(true)
	legacy_payload.erase("v122_battle_plan")
	var migrated_payload: Dictionary = game._campaign_restore_payload(legacy_payload)
	_expect(
		str(migrated_payload.get("world", {}).get("quarter_layout_id", "")) == PRODUCT_LAYOUT_ID,
		"legacy product saves migrate at a safe checkpoint"
	)
	_expect(
		str(legacy_payload.get("world", {}).get("quarter_layout_id", "")) == LEGACY_LAYOUT_ID,
		"migration does not mutate the inspected save payload"
	)
	_expect(game._restore_campaign_payload(legacy_payload), "legacy product save restores after migration")
	_expect(game.quarter_layout_id == PRODUCT_LAYOUT_ID, "restored legacy save uses the dual-front layout")
	_expect(
		bool(game.graph.validation_summary().get("ok", false)),
		"migrated legacy save rebuilds a valid graph"
	)
	_expect(
		game.logs.has("기존 마왕성 배치를 이중 전선 구조로 안전하게 전환했습니다."),
		"migration is recorded in the campaign log"
	)
	_expect(
		str(game.get_meta("v122_battle_plan", {}).get("layout_id", "")) == PRODUCT_LAYOUT_ID,
		"legacy saves derive their battle plan from the migrated layout"
	)

	var custom_layout := product_layout.duplicate(true)
	custom_layout["template_id"] = "user_fixture_layout"
	var custom_payload := base_payload.duplicate(true)
	custom_payload["world"]["quarter_layout_id"] = "user_fixture_layout"
	custom_payload["world"]["quarter_layout"] = custom_layout
	var custom_restore: Dictionary = game._campaign_restore_payload(custom_payload)
	_expect(
		str(custom_restore.get("world", {}).get("quarter_layout_id", "")) == "user_fixture_layout",
		"user-authored layouts are never auto-migrated"
	)
	_expect(game._restore_campaign_payload(custom_payload), "user-authored layout save remains restorable")
	_expect(game.quarter_layout_id == "user_fixture_layout", "user-authored layout ID is preserved")

	var invalid_product := product_layout.duplicate(true)
	invalid_product["connections"] = []
	DataRegistry.register_quarter_layout(PRODUCT_LAYOUT_ID, invalid_product, false)
	var fallback_payload: Dictionary = game._campaign_restore_payload(legacy_payload)
	DataRegistry.register_quarter_layout(PRODUCT_LAYOUT_ID, product_layout, false)
	_expect(
		str(fallback_payload.get("world", {}).get("quarter_layout_id", "")) == LEGACY_LAYOUT_ID,
		"failed product migration falls back to the valid legacy layout"
	)
	_expect(
		game._campaign_payload_is_restorable(legacy_payload),
		"legacy save remains restorable when the migration candidate fails"
	)

	game.queue_free()
	await _settle(2)
	_finish()


func _load_layout(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _settle(frames: int) -> void:
	for _index in range(frames):
		await get_tree().process_frame


func _finish() -> void:
	if failed:
		print("V122_DUAL_FRONT_DEFAULT_ACTIVATION_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("V122_DUAL_FRONT_DEFAULT_ACTIVATION_TEST: PASS")
		get_tree().quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
