extends Node

const StoryCatalogScript = preload("res://scripts/story/StoryCatalog.gd")
const StoryDirectorScript = preload("res://scripts/story/StoryDirector.gd")
const GameRootScript = preload("res://scripts/game/GameRoot.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog = StoryCatalogScript.new()
	_expect(catalog.load_default(), "product story catalog loads: %s" % " | ".join(catalog.load_errors))
	_expect(catalog.scene_count() == 205, "DAY 1-30 catalog exposes 205 stable scenes")
	_check_read_skip_and_resume(catalog)
	_check_day_one_placement(catalog)
	_check_day_two_replacement(catalog)
	_check_day_three_threshold_metadata(catalog)
	_check_day_four_additive_roster(catalog)
	_check_day30_ending_flow(catalog)
	_check_dynamic_promotion_portraits()
	_check_battle_repeat_scope(catalog)
	_check_legacy_cutover(catalog)
	_check_runtime_hooks()
	if failed:
		print("V122_STORY_RUNTIME_INTEGRATION_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V122_STORY_RUNTIME_INTEGRATION_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _check_read_skip_and_resume(catalog) -> void:
	var director = StoryDirectorScript.new()
	director.setup(catalog, 1)
	_expect(director.try_start(1, "management_entered", {"cycle_index": 1}, "management", "open_intrusion_brief"), "DAY 1 management scene starts")
	_expect(director.cue_count() == 8, "DAY 1 management scene has eight cues")
	_expect(not director.skip_allowed(), "first-seen scene cannot be skipped")
	var first_cue_id := str(director.current_cue_id)
	director.set_auto(true)
	var auto_advance: Dictionary = director.advance(false)
	_expect(bool(director.auto_enabled), "automatic advance keeps opt-in Auto enabled")
	_expect(not bool(auto_advance.get("completed", true)), "first automatic advance stays inside the scene")
	_expect(director.seen_cue_ids.has(first_cue_id), "only the consumed cue becomes read")
	var saved: Dictionary = director.export_state()
	var expected_cue_id := str(director.current_cue_id)

	var restored = StoryDirectorScript.new()
	restored.setup(catalog, 1)
	_expect(restored.import_state(saved, 1, true), "story state imports")
	_expect(str(restored.current_cue_id) == expected_cue_id, "save resumes at the exact stable cue ID")
	restored.advance(true)
	_expect(not bool(restored.auto_enabled), "manual advance stops Auto")
	while restored.is_active():
		restored.advance()
	_expect(restored.seen_scene_ids.has("STORY_D01_MANAGEMENT_ENTRY"), "scene is seen only after its final cue")
	_expect(not restored.try_start(1, "management_entered", {"cycle_index": 1}), "once scene does not reopen automatically")
	_expect(restored.start_scene("STORY_D01_MANAGEMENT_ENTRY", {"cycle_index": 1}, "management", "", true), "archive replay can force a seen scene")
	_expect(restored.skip_allowed(), "fully read replay can be skipped")
	_expect(bool(restored.skip().get("completed", false)), "read-scene skip completes the replay")


func _check_day_one_placement(catalog) -> void:
	var front = StoryDirectorScript.new()
	front.setup(catalog, 1)
	_expect(front.try_start(1, "placement_confirmed", {"gob_formation": "front"}, "management"), "front formation branch starts")
	_expect(str(front.current_scene_id) == "STORY_D01_PLACEMENT_FRONT" and front.cue_count() == 2, "front branch selects only its two cues")
	var rear = StoryDirectorScript.new()
	rear.setup(catalog, 1)
	_expect(rear.try_start(1, "placement_confirmed", {"gob_formation": "rear"}, "management"), "rear formation branch starts")
	_expect(str(rear.current_scene_id) == "STORY_D01_PLACEMENT_REAR" and rear.cue_count() == 2, "rear branch selects only its two cues")


func _check_day_two_replacement(catalog) -> void:
	var secure = StoryDirectorScript.new()
	secure.setup(catalog, 1)
	_expect(secure.try_start(2, "result_win", {"treasure_gold_stolen_this_battle": 0}, "result"), "DAY 2 no-loss result starts")
	var secure_count := secure.cue_count()
	var secure_text := _active_text(secure)
	_expect(secure_count == 8 and secure_text.contains("보안은 7점") and not secure_text.contains("오늘은 8점"), "no-loss path contains exactly the 7-point variant")
	var damaged = StoryDirectorScript.new()
	damaged.setup(catalog, 1)
	_expect(damaged.try_start(2, "result_win", {"treasure_gold_stolen_this_battle": 12}, "result"), "DAY 2 damaged-vault result starts")
	var damaged_count := damaged.cue_count()
	var damaged_text := _active_text(damaged)
	_expect(damaged_count == 8 and damaged_text.contains("오늘은 8점") and not damaged_text.contains("보안은 7점"), "damage path replaces both conflicting common cues")


func _check_day_three_threshold_metadata(catalog) -> void:
	var scenes: Array[Dictionary] = catalog.scenes_for(3, "combat_boss_hp", {})
	_expect(scenes.size() == 3, "DAY 3 exposes three ordered boss threshold scenes")
	_expect(
		float(scenes[0].get("metadata", {}).get("threshold", 0.0)) == 0.75
			and float(scenes[1].get("metadata", {}).get("threshold", 0.0)) == 0.50
			and float(scenes[2].get("metadata", {}).get("threshold", 0.0)) == 0.25,
		"boss thresholds preserve 75/50/25 order"
	)


func _check_day_four_additive_roster(catalog) -> void:
	var roster = StoryDirectorScript.new()
	roster.setup(catalog, 1)
	var facts := {
		"raid_mission_id": "d04_signpost_flip",
		"selected_raid_monster_ids": ["mon_core_gob", "mon_core_pynn"]
	}
	_expect(roster.try_start(4, "raid_roster_confirmed", facts, "raid"), "DAY 4 fixed-operator raid roster starts")
	var roster_count := roster.cue_count()
	var text := _active_text(roster)
	_expect(roster_count == 11, "two selected escorts add both two-cue reactions to seven common cues")
	_expect(text.contains("곱이 때리면 돌아가?") and text.contains("못을 살짝 데우면"), "additive roster keeps both selected escort reactions")
	_expect(not text.contains("밀어서 돌리는 건 자신"), "unselected Pudding reaction is excluded")


	_expect(
		catalog.scenes_for(4, "combat_started", {"day4_raid_completed": false}).is_empty(),
		"DAY 4 defense arrival dialogue stays locked before the signpost raid"
	)
	var unlocked_arrival: Array[Dictionary] = catalog.scenes_for(4, "combat_started", {"day4_raid_completed": true})
	_expect(
		unlocked_arrival.size() == 1 and str(unlocked_arrival[0].get("id", "")) == "STORY_D04_DEFENSE_ARRIVAL",
		"DAY 4 defense arrival dialogue unlocks exactly once after the signpost raid"
	)


func _check_day30_ending_flow(catalog) -> void:
	var ending_scenes: Array[Dictionary] = catalog.scenes_for(30, "ending_entered", {"resolved_ending_id": "demon_hero_rival_pact"})
	_expect(ending_scenes.size() == 1 and str(ending_scenes[0].get("id", "")) == "STORY_D30_ENDING", "DAY 30 기본 엔딩 후일담 scene 연결")
	var ending_director = StoryDirectorScript.new()
	ending_director.setup(catalog, 1)
	_expect(ending_director.try_start(30, "ending_entered", {"resolved_ending_id": "demon_hero_rival_pact", "cycle_index": 1}, "ending"), "선택된 E04 후일담 시작")
	_expect(ending_director.cue_count() == 10, "E04 후일담은 선택된 10줄만 표시")
	var day30_combat: Array[Dictionary] = catalog.scenes_for(30, "combat_time", {})
	_expect(day30_combat.size() <= 8, "DAY 30 전투 대화 정지 지점은 최대 8개")


func _check_dynamic_promotion_portraits() -> void:
	var root = GameRootScript.new()
	root.monster_roster = {
		"goblin": {"promotion_id": "ambush_captain"},
		"imp": {"promotion_id": "flame_adept"}
	}
	root.story_promotion_order.append("goblin")
	root.story_promotion_order.append("imp")
	var first: Dictionary = root._story_resolve_cue_speaker({
		"speaker_id": "NARRATOR",
		"speaker_label": "첫 승급자",
		"speaker_role": "first_promoted",
		"emotion_direction": "집중"
	})
	var second: Dictionary = root._story_resolve_cue_speaker({
		"speaker_id": "NARRATOR",
		"speaker_label": "두번째승급자",
		"speaker_role": "second_promoted",
		"emotion_direction": "집중"
	})
	_expect(str(first.get("speaker_id", "")) == "CHR_GOB" and str(first.get("portrait_emotion", "")) == "eager", "첫 승급자 곱 초상화로 실제 치환")
	_expect(str(second.get("speaker_id", "")) == "CHR_PYNN" and str(second.get("portrait_emotion", "")) == "cast", "두 번째 승급자 핀 초상화로 실제 치환")
	root.free()


func _check_legacy_cutover(catalog) -> void:
	var migrated = StoryDirectorScript.new()
	migrated.setup(catalog, 1)
	_expect(migrated.import_state({}, 4, false), "story-less legacy save bootstraps safely")
	_expect(int(migrated.legacy_cutover_day) == 4, "legacy save cutover starts at its current DAY")
	_expect(not migrated.try_start(1, "management_entered", {"cycle_index": 1}), "legacy save never forces past DAY 1 dialogue")
	_expect(migrated.try_start(4, "management_entered", {"cycle_index": 1}, "raid_preview"), "legacy save may continue from its current DAY")


func _check_battle_repeat_scope(catalog) -> void:
	var director = StoryDirectorScript.new()
	director.setup(catalog, 1)
	var first_attempt := {"battle_scope_id": "cycle1-day5-attempt1"}
	_expect(director.try_start(5, "precombat_confirmed", first_attempt, "management"), "once-battle scene starts in the first battle attempt")
	while director.is_active():
		director.advance()
	_expect(not director.try_start(5, "precombat_confirmed", first_attempt, "management"), "once-battle scene does not repeat inside one attempt")
	var retry_attempt := {"battle_scope_id": "cycle1-day5-attempt2"}
	_expect(director.try_start(5, "precombat_confirmed", retry_attempt, "management"), "once-battle scene reopens for a same-DAY retry")
	_expect(director.skip_allowed(), "fully read retry dialogue is immediately skippable")
	director.cancel_active_scene()
	var interrupted_attempt := {"battle_scope_id": "cycle1-day5-attempt3"}
	_expect(director.try_start(5, "combat_time", interrupted_attempt, "combat"), "combat dialogue starts for interruption cleanup")
	var interrupted_scene_id := str(director.current_scene_id)
	_expect(director.cancel_active_scene() == interrupted_scene_id and not director.is_active(), "battle end can cancel an unfinished combat dialogue without leaving unsafe save state")
	_expect(not director.seen_scene_ids.has(interrupted_scene_id), "canceled combat dialogue is not falsely marked as fully read")


func _check_runtime_hooks() -> void:
	var root_source := FileAccess.get_file_as_string("res://scripts/game/GameRoot.gd")
	var combat_source := FileAccess.get_file_as_string("res://scripts/game/CombatSceneController.gd")
	_expect(root_source.contains("\"story\": story_director.export_state()"), "campaign payload exports optional story state")
	_expect(root_source.contains("대화 알람") or FileAccess.get_file_as_string("res://scripts/game/ManagementSceneController.gd").contains("대화 알람"), "management UI uses the approved 대화 알람 wording")
	_expect(not root_source.contains("\"경고: 도둑이 보물 방"), "legacy combat copy no longer labels dialogue notification as 경고")
	_expect(combat_source.contains("func set_pause_state") and combat_source.contains("active_combat_tweens"), "combat story pause covers units and gameplay tweens")
	_expect(combat_source.contains("paused_combat_animation_speeds") and combat_source.contains("_pause_animated_sprites_in"), "combat story pause freezes and restores visible battle animation")
	_expect(combat_source.count("root.create_tween()") == 1, "all combat tweens flow through the tracked pause wrapper")
	_expect(combat_source.contains("story_started = bool(root._story_battle_finished(win))"), "result dialogue starts only after the computed result contract")
	_expect(root_source.contains("story_promotion_order") and root_source.contains("_story_resolve_cue_speaker"), "승급 순서 기반 동적 초상화 해석 연결")
	_expect(root_source.contains("_story_begin_trigger(\"ending_entered\"") and root_source.contains("\"show_campaign_ending\""), "결과 UI 뒤 엔딩 후일담 트리거 연결")


func _active_text(director) -> String:
	var lines: Array[String] = []
	while director.is_active():
		lines.append(str(director.current_cue().get("text_ko", "")))
		director.advance()
	return "\n".join(lines)


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		return
	failed = true
	push_error(message)
