extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const CombatResultViewModel = preload("res://scripts/v122/ui/V122CombatResultViewModel.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const CORE_METRIC_IDS := [
	"throne_damage",
	"monster_survival",
	"final_breach_segment"
]
const DEFEAT_ACTION_IDS := [
	"edit_placement",
	"retry_same_placement"
]

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_check_result_view_model_contract()

	var game := GameRootScene.instantiate()
	add_child(game)
	await _settle(4)
	game.campaign_save_enabled = false
	game._debug_skip_onboarding()

	await _check_defeat_edit_placement_flow(game)
	await _check_same_placement_retry_flow(game)
	await _check_victory_flow_is_preserved(game)

	game.queue_free()
	await _settle(2)
	if failed:
		print("V122_RESULT_UI_SIMPLIFICATION_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V122_RESULT_UI_SIMPLIFICATION_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _check_result_view_model_contract() -> void:
	var defeat_model := CombatResultViewModel.build_result(
		_result_summary(false, 40, 2),
		_ledger_summary(125, 40),
		_preserved_progression()
	)
	var core_metrics: Array = defeat_model.get("core_metrics", [])
	_expect(
		_ids(core_metrics) == CORE_METRIC_IDS,
		"result exposes exactly the three fixed metrics in the agreed order"
	)
	_expect(
		str(_entry(core_metrics, "throne_damage").get("label", "")) == "왕좌 피해",
		"throne damage uses the player-facing fixed label"
	)
	_expect(
		str(_entry(core_metrics, "monster_survival").get("label", "")) == "몬스터 생존",
		"monster survival uses the player-facing fixed label"
	)
	_expect(
		str(_entry(core_metrics, "final_breach_segment").get("label", "")) == "최종 돌파 구간",
		"final breach segment uses the player-facing fixed label"
	)
	_expect(
		str(_entry(core_metrics, "throne_damage").get("value", "")).find("125") >= 0,
		"throne damage value comes from the battle ledger"
	)
	_expect(
		str(_entry(core_metrics, "monster_survival").get("value", "")).replace(" ", "") == "1/3",
		"monster survival value comes from the actual alive and total counts"
	)
	var breach_value := str(_entry(core_metrics, "final_breach_segment").get("value", ""))
	_expect(
		breach_value.find("병영") >= 0 and breach_value.find("왕좌") >= 0,
		"final breach segment preserves the actual final segment"
	)

	var conditional_alerts: Array = defeat_model.get("conditional_alerts", [])
	_expect(
		_ids(conditional_alerts) == ["treasure_theft", "facility_damage"],
		"theft and facility damage are the only contextual loss alerts"
	)
	_expect(
		str(_entry(conditional_alerts, "treasure_theft").get("value", "")).find("40") >= 0,
		"theft alert reports the actual stolen amount"
	)
	_expect(
		str(_entry(conditional_alerts, "facility_damage").get("value", "")).find("2") >= 0,
		"facility alert reports the actual affected facility count"
	)

	var clean_model := CombatResultViewModel.build_result(
		_result_summary(true, 0, 0),
		_ledger_summary(0, 0),
		_preserved_progression()
	)
	_expect(
		clean_model.get("conditional_alerts", []).is_empty(),
		"theft and facility alerts are absent when neither event occurred"
	)

	var defeat_actions: Array = defeat_model.get("actions", [])
	_expect(
		_ids(defeat_actions) == DEFEAT_ACTION_IDS,
		"defeat exposes placement editing first and same-placement retry second"
	)
	_expect(
		str(_entry(defeat_actions, "edit_placement").get("label", "")) == "배치 수정"
		and str(_entry(defeat_actions, "edit_placement").get("priority", "")) == "primary",
		"placement editing is the defeat primary action"
	)
	_expect(
		str(_entry(defeat_actions, "retry_same_placement").get("label", "")) == "동일 배치 재도전"
		and str(_entry(defeat_actions, "retry_same_placement").get("priority", "")) == "secondary",
		"same-placement retry is the defeat secondary action"
	)
	_expect(
		is_equal_approx(
			float(_entry(defeat_actions, "retry_same_placement").get("countdown_seconds", 0.0)),
			3.0
		),
		"same-placement retry declares a three-second countdown"
	)
	_expect(
		not _ids(clean_model.get("actions", [])).has("edit_placement")
		and not _ids(clean_model.get("actions", [])).has("retry_same_placement"),
		"victory does not expose defeat-only actions"
	)


func _check_defeat_edit_placement_flow(game: Node) -> void:
	_configure_day_one(game)
	var confirmed_plan: Dictionary = game._v122_current_battle_plan()
	game._capture_v122_battle_confirmation(confirmed_plan)
	game.result_summary = _result_summary(false, 40, 2)
	game.result_summary["v122_ledger"] = _ledger_summary(125, 40)
	GameState.defeat = true
	game._set_screen(Constants.SCREEN_RESULT)
	await _settle(2)

	for label_text in ["왕좌 피해", "몬스터 생존", "최종 돌파 구간", "탈취", "시설 피해"]:
		_expect(
			_has_text_fragment(game.ui_layer, label_text),
			"defeat result renders '%s'" % label_text
		)
	_expect(
		_has_text_fragment(game.ui_layer, "내 선택의 결과")
		and _has_text_fragment(game.ui_layer, "곱 → 전열")
		and _has_text_fragment(game.ui_layer, "공격 47"),
		"result renders the actual DAY 1 placement-to-combat causality line"
	)

	var edit_button := _find_button(game.ui_layer, "배치 수정")
	_expect(edit_button != null, "defeat result renders the placement-edit primary button")
	if edit_button == null:
		return
	edit_button.pressed.emit()
	await _settle(3)
	_expect(
		game.current_screen == Constants.SCREEN_MANAGEMENT,
		"placement editing returns directly to management"
	)
	_expect(
		game.pending_precombat_snapshot.is_empty()
		and is_zero_approx(float(game.defense_start_remaining)),
		"placement editing does not start the retry countdown"
	)
	_expect(
		str(game._v122_current_battle_plan().get("layout_fingerprint", ""))
		== str(confirmed_plan.get("layout_fingerprint", "")),
		"placement editing restores the last confirmed placement as its starting point"
	)


func _check_same_placement_retry_flow(game: Node) -> void:
	_configure_day_one(game)
	var confirmed_plan: Dictionary = game._v122_current_battle_plan()
	game._capture_v122_battle_confirmation(confirmed_plan)
	game.result_summary = _result_summary(false, 0, 0)
	game.result_summary["v122_ledger"] = _ledger_summary(80, 0)
	GameState.defeat = true
	game._set_screen(Constants.SCREEN_RESULT)
	await _settle(2)

	var retry_button := _find_button(game.ui_layer, "동일 배치 재도전")
	_expect(retry_button != null, "defeat result renders the same-placement retry secondary button")
	if retry_button == null:
		return
	retry_button.pressed.emit()
	await _settle(3)
	_expect(
		game.current_screen == Constants.SCREEN_DEFENSE_START,
		"same-placement retry goes directly to the defense-start countdown"
	)
	_expect(
		is_equal_approx(float(game.defense_start_remaining), 3.0),
		"same-placement retry starts at exactly three seconds"
	)
	_expect(
		not game.pending_precombat_snapshot.is_empty(),
		"same-placement retry freezes a precombat snapshot immediately"
	)
	_expect(
		str(game.pending_precombat_snapshot.get("layout_fingerprint", ""))
		== str(confirmed_plan.get("layout_fingerprint", "")),
		"same-placement retry uses the last confirmed placement"
	)

	game._tick_defense_start_countdown(2.9)
	_expect(
		game.current_screen == Constants.SCREEN_DEFENSE_START
		and float(game.defense_start_remaining) > 0.0,
		"same-placement retry does not commit before the three-second boundary"
	)
	game._tick_defense_start_countdown(0.2)
	_expect(
		game.current_screen == Constants.SCREEN_COMBAT,
		"same-placement retry commits combat when the three seconds finish"
	)


func _check_victory_flow_is_preserved(game: Node) -> void:
	_configure_day_one(game)
	game.result_summary = _result_summary(true, 0, 0)
	game.result_summary["v122_ledger"] = _ledger_summary(0, 0)
	GameState.victory = false
	GameState.defeat = false
	game._set_screen(Constants.SCREEN_RESULT)
	await _settle(2)

	_expect(
		_find_button(game.ui_layer, "배치 수정") == null
		and _find_button(game.ui_layer, "동일 배치 재도전") == null,
		"victory result does not render defeat-only actions"
	)
	var continue_button := _find_button_containing(game.ui_layer, "다음")
	_expect(continue_button != null, "victory retains its next-day continuation action")
	if continue_button == null:
		return
	continue_button.pressed.emit()
	await _settle(3)
	_expect(GameState.day == 2, "victory continuation still advances to the next day")
	_expect(game.current_screen != Constants.SCREEN_RESULT, "victory continuation still leaves the result screen")


func _configure_day_one(game: Node) -> void:
	game._clear_units()
	game._clear_effects()
	GameState.day = 1
	GameState.max_day = 30
	GameState.player_name = "result-ui-contract"
	GameState.victory = false
	GameState.defeat = false
	GameState.demon_lord_hp = GameState.demon_lord_max_hp
	GameState.onboarding_complete = true
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game.tutorial_manager.active = false
	game.campaign_postgame_active = false
	game.result_summary.clear()
	game.rewards_pending.clear()
	game.last_growth_summary.clear()
	game.result_growth_reviewed = true
	game.result_growth_choice_monster_id = ""
	game.result_growth_choice_applied = false
	game.last_growth_choice_summary.clear()
	game.pending_precombat_snapshot.clear()
	game.intrusion_brief_snapshot.clear()
	game.defense_start_remaining = 0.0
	game.defense_start_last_second = -1
	game._setup_dungeon_graph()
	game._init_room_directives()
	game._set_screen(Constants.SCREEN_MANAGEMENT)


func _result_summary(win: bool, stolen_gold: int, facility_disables: int) -> Dictionary:
	return {
		"win": win,
		"lines": [],
		"growth": [],
		"metrics": {
			"alive_monsters": 1,
			"total_monsters": 3,
			"treasure_gold_stolen": stolen_gold,
			"facility_disables": facility_disables,
			"final_breach_segment": "병영 → 왕좌",
			"monster_contributions": {
				"goblin": {"damage_absorbed": 32, "damage_dealt": 47}
			},
			"decision_context": {
				"day": 1,
				"directive_id": "defense",
				"directive_name": "사수",
				"monster_placements": [{
					"monster_id": "goblin",
					"monster_name": "곱",
					"room_id": "spike_corridor",
					"room_name": "전열 통로",
					"defense_zone_id": "zone_a_front"
				}]
			}
		}
	}


func _ledger_summary(throne_damage: int, stolen_gold: int) -> Dictionary:
	return {
		"throne_damage": throne_damage,
		"gold_stolen": stolen_gold,
		"breach_progress": 0.75,
		"final_breach_segment": "병영 → 왕좌",
		"facility_contribution": {},
		"command_contribution": {},
		"events": [
			{
				"type": "breach_progress",
				"from_room_id": "barracks",
				"room_id": "throne",
				"progress": 0.75
			}
		]
	}


func _preserved_progression() -> Dictionary:
	return {
		"rewards": {"gold": 15},
		"story_preserved": true,
		"meta_progress_preserved": true,
		"ending_preserved": true,
		"next_day_preserved": true
	}


func _ids(values: Array) -> Array:
	var result: Array = []
	for value in values:
		if value is Dictionary:
			result.append(str(value.get("id", "")))
	return result


func _entry(values: Array, entry_id: String) -> Dictionary:
	for value in values:
		if value is Dictionary and str(value.get("id", "")) == entry_id:
			return value
	return {}


func _find_button(parent: Node, expected_text: String) -> Button:
	if parent is Button and parent.text == expected_text:
		return parent
	for child in parent.get_children():
		var found := _find_button(child, expected_text)
		if found != null:
			return found
	return null


func _find_button_containing(parent: Node, fragment: String) -> Button:
	if parent is Button and parent.text.find(fragment) >= 0:
		return parent
	for child in parent.get_children():
		var found := _find_button_containing(child, fragment)
		if found != null:
			return found
	return null


func _has_text_fragment(parent: Node, fragment: String) -> bool:
	if (parent is Label or parent is RichTextLabel or parent is Button) and str(parent.text).find(fragment) >= 0:
		return true
	for child in parent.get_children():
		if _has_text_fragment(child, fragment):
			return true
	return false


func _settle(frame_count: int) -> void:
	for _index in range(frame_count):
		await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		return
	failed = true
	push_error(message)
