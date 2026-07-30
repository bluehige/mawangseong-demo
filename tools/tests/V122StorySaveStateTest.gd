extends Node

const CampaignSaveStore = preload("res://scripts/core/CampaignSaveStore.gd")
const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const StorySaveState = preload("res://scripts/story/StorySaveState.gd")

var failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_story_state_contract()
	await _check_campaign_save_integration()
	if failed:
		print("V122_STORY_SAVE_STATE_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("V122_STORY_SAVE_STATE_TEST: PASS")
		get_tree().quit(0)


func _check_story_state_contract() -> void:
	var active := StorySaveState.build({
		"current_scene_id": "story.day01.management.core",
		"current_cue_id": "story.day01.management.core.003",
		"cursor": 2,
		"seen_scene_ids": ["story.day00.prologue"],
		"seen_scene_scope_ids": ["once_battle::cycle1-day1-attempt1::story.day01.combat.001"],
		"seen_cue_ids": ["story.day00.prologue.001", "story.day01.management.core.001"],
		"pending_return_screen": Constants.SCREEN_MANAGEMENT,
		"auto_enabled": true,
		"legacy_cutover_day": 1,
		"current_facts": {"selected_vanguard_id": "goblin", "victory": false},
		"pending_action": "open_intrusion_brief"
	})
	_expect(StorySaveState.validate_state(active, CampaignSaveStore.SAFE_SCREENS) == "", "active story state validates")
	_expect(StorySaveState.is_active(active), "active story state is recognized")
	_expect(
		str(active.get("current_cue_id", "")) == "story.day01.management.core.003"
			and active.get("current_facts", {}).get("selected_vanguard_id") == "goblin"
			and active.get("seen_scene_scope_ids", []).size() == 1
			and str(active.get("pending_action", "")) == "open_intrusion_brief",
		"exact cue, resolved facts, and completion action are retained"
	)

	var json_round_trip = JSON.parse_string(JSON.stringify(active))
	_expect(json_round_trip is Dictionary, "story state survives JSON encoding")
	_expect(
		StorySaveState.validate_state(json_round_trip, CampaignSaveStore.SAFE_SCREENS) == "",
		"JSON story state validates"
	)
	var normalized := StorySaveState.normalize(json_round_trip, 1)
	_expect(
		str(normalized.get("current_scene_id", "")) == str(active.get("current_scene_id", ""))
			and str(normalized.get("current_cue_id", "")) == str(active.get("current_cue_id", ""))
			and int(normalized.get("cursor", -1)) == 2
			and bool(normalized.get("auto_enabled", false)),
		"normalize preserves exact cue and Auto state"
	)

	var legacy_story := active.duplicate(true)
	legacy_story.erase("current_facts")
	legacy_story.erase("pending_action")
	legacy_story.erase("seen_scene_scope_ids")
	legacy_story["future_extension"] = {"supported_later": true}
	_expect(
		StorySaveState.validate_state(legacy_story, CampaignSaveStore.SAFE_SCREENS) == "",
		"optional additions may be absent and unknown extension keys remain compatible"
	)
	normalized = StorySaveState.normalize(legacy_story, 1)
	_expect(
		normalized.get("current_facts", {}).is_empty()
			and str(normalized.get("pending_action", "")) == ""
			and normalized.get("seen_scene_scope_ids", []).is_empty(),
		"missing optional branch facts, completion action, and repeat scopes receive safe defaults"
	)

	var inactive := StorySaveState.default_state(12)
	_expect(StorySaveState.validate_state(inactive, CampaignSaveStore.SAFE_SCREENS) == "", "inactive migrated state validates")
	_expect(not StorySaveState.is_active(inactive), "inactive migrated state is not a dialogue checkpoint")
	_expect(int(inactive.get("legacy_cutover_day", 0)) == 12, "legacy cutover DAY is retained")

	var invalid_schema := active.duplicate(true)
	invalid_schema["schema_version"] = 99
	_expect(StorySaveState.validate_state(invalid_schema, CampaignSaveStore.SAFE_SCREENS) != "", "unsupported story schema is rejected")
	var invalid_cursor := active.duplicate(true)
	invalid_cursor["cursor"] = -1
	_expect(StorySaveState.validate_state(invalid_cursor, CampaignSaveStore.SAFE_SCREENS) != "", "negative story cursor is rejected")
	var invalid_seen := active.duplicate(true)
	invalid_seen["seen_cue_ids"] = ["cue.001", "cue.001"]
	_expect(StorySaveState.validate_state(invalid_seen, CampaignSaveStore.SAFE_SCREENS) != "", "duplicate read cue IDs are rejected")
	var unsafe_return := active.duplicate(true)
	unsafe_return["pending_return_screen"] = Constants.SCREEN_COMBAT
	_expect(StorySaveState.validate_state(unsafe_return, CampaignSaveStore.SAFE_SCREENS) != "", "live combat is rejected as a disk restore screen")
	var embedded_text := active.duplicate(true)
	embedded_text["dialogue_queue"] = [{"text": "must not be saved"}]
	_expect(StorySaveState.validate_state(embedded_text, CampaignSaveStore.SAFE_SCREENS) != "", "dialogue text queues are rejected from story state")
	var invalid_facts := active.duplicate(true)
	invalid_facts["current_facts"] = {"callable": Callable()}
	_expect(StorySaveState.validate_state(invalid_facts, CampaignSaveStore.SAFE_SCREENS) != "", "non-JSON branch facts are rejected")


func _check_campaign_save_integration() -> void:
	var game := GameRootScene.instantiate()
	add_child(game)
	await _settle(4)
	game.campaign_save_enabled = false
	game._debug_skip_onboarding()
	GameState.player_name = "스토리 저장 테스트"

	game.current_screen = Constants.SCREEN_MANAGEMENT
	var legacy_payload: Dictionary = game._campaign_save_payload(Constants.SCREEN_MANAGEMENT)
	var management_summary: Dictionary = game._campaign_save_summary(Constants.SCREEN_MANAGEMENT)
	legacy_payload.erase("story")
	var legacy_error := CampaignSaveStore.validate_payload(legacy_payload, management_summary)
	_expect(
		legacy_error == "",
		"save without optional story state remains valid (%s)" % legacy_error
	)
	_expect(CampaignSaveStore.SAVE_VERSION == 1, "optional story state does not bump CampaignSaveStore version")

	game.current_screen = Constants.SCREEN_DIALOGUE
	var dialogue_payload: Dictionary = game._campaign_save_payload(Constants.SCREEN_DIALOGUE)
	var dialogue_summary: Dictionary = game._campaign_save_summary(Constants.SCREEN_DIALOGUE)
	dialogue_payload["onboarding"]["dialogue_queue"] = []
	dialogue_payload["onboarding"]["dialogue_index"] = 0
	dialogue_payload["story"] = StorySaveState.build({
		"current_scene_id": "story.day01.management.core",
		"current_cue_id": "story.day01.management.core.003",
		"cursor": 2,
		"seen_scene_ids": [],
		"seen_cue_ids": ["story.day01.management.core.001"],
		"pending_return_screen": Constants.SCREEN_MANAGEMENT,
		"auto_enabled": false,
		"legacy_cutover_day": 1,
		"current_facts": {"selected_vanguard_id": "goblin"},
		"pending_action": "open_intrusion_brief"
	})
	var story_dialogue_error := CampaignSaveStore.validate_payload(dialogue_payload, dialogue_summary)
	_expect(story_dialogue_error == "", "active story permits a dialogue checkpoint without duplicating the onboarding queue (%s)" % story_dialogue_error)

	var missing_dialogue_state := dialogue_payload.duplicate(true)
	missing_dialogue_state.erase("story")
	_expect(
		CampaignSaveStore.validate_payload(missing_dialogue_state, dialogue_summary) != "",
		"dialogue checkpoint without legacy queue or active story is rejected"
	)

	var legacy_dialogue := missing_dialogue_state.duplicate(true)
	legacy_dialogue["onboarding"]["dialogue_queue"] = [{"id": "LEGACY_QUEUE_001"}]
	legacy_dialogue["onboarding"]["dialogue_index"] = 0
	var legacy_dialogue_error := CampaignSaveStore.validate_payload(legacy_dialogue, dialogue_summary)
	_expect(legacy_dialogue_error == "", "existing onboarding dialogue queue remains a valid legacy checkpoint (%s)" % legacy_dialogue_error)

	game.queue_free()
	await _settle(2)


func _settle(frame_count: int) -> void:
	for _index in range(frame_count):
		await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
