extends Node2D

const Constants = preload("res://scripts/core/Constants.gd")
const CampaignSaveStoreScript = preload("res://scripts/core/CampaignSaveStore.gd")
const CampaignSaveMigratorV1ToV2Script = preload("res://scripts/core/CampaignSaveMigratorV1ToV2.gd")
const CampaignSaveV2StoreScript = preload("res://scripts/core/CampaignSaveV2Store.gd")
const RoomGraphScript = preload("res://scripts/map/RoomGraph.gd")
const ModuleGraphScript = preload("res://scripts/dungeon_quarter/ModuleGraph.gd")
const WaveManagerScript = preload("res://scripts/combat/WaveManager.gd")
const TargetingService = preload("res://scripts/combat/TargetingService.gd")
const DamageService = preload("res://scripts/combat/DamageService.gd")
const DirectiveManager = preload("res://scripts/combat/DirectiveManager.gd")
const UnitActorScript = preload("res://scripts/units/Unit.gd")
const HUDControllerScript = preload("res://scripts/ui/HUDController.gd")
const ManagementSceneControllerScript = preload("res://scripts/game/ManagementSceneController.gd")
const CombatSceneControllerScript = preload("res://scripts/game/CombatSceneController.gd")
const OnboardingFlowScript = preload("res://scripts/systems/tutorial/OnboardingFlow.gd")
const TutorialManagerScript = preload("res://scripts/systems/tutorial/TutorialManager.gd")
const FirstPlayObservationRecorderScript = preload("res://scripts/systems/tutorial/FirstPlayObservationRecorder.gd")
const RunMetricsTrackerScript = preload("res://scripts/systems/endings/RunMetricsTracker.gd")
const EndingConditionEvaluatorScript = preload("res://scripts/systems/endings/EndingConditionEvaluator.gd")
const NewCycleServiceScript = preload("res://scripts/systems/legacy/NewCycleService.gd")
const DungeonRendererScript = preload("res://scripts/map/DungeonRenderer.gd")
const QuarterDungeonRendererScript = preload("res://scripts/dungeon_quarter/QuarterDungeonRenderer.gd")
const AutoTileMaskScript = preload("res://scripts/dungeon_quarter/AutoTileMask.gd")
const IsoMathScript = preload("res://scripts/dungeon_quarter/IsoMath.gd")
const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const COMBAT_MUSIC = preload("res://assets/audio/bgm/combat_dungeon_pressure.wav")
const UI_FONT = UIFontScript.BODY_FONT

const FACILITY_CHOICES = ["barracks", "treasure", "recovery", "watch_post", "ward_core", "build_slot"]
const UNIQUE_FACILITIES = ["treasure", "recovery", "ward_core"]
const LOCKED_FACILITY_ROOMS = ["entrance", "spike_corridor", "throne", "center"]
const COMBAT_ZOOM_MIN = 0.78
const COMBAT_ZOOM_MAX = 1.85
const COMBAT_ZOOM_STEP = 1.12
const COMBAT_CAMERA_HOME = Vector2(960, 540)
const COMBAT_MUSIC_TARGET_DB = -7.5
const COMBAT_MUSIC_FADE_IN_SECONDS = 0.65
const COMBAT_MUSIC_FADE_OUT_SECONDS = 0.45
const FACILITY_FEEDBACK_REDRAW_INTERVAL_SECONDS = 0.1
const ACTIVITY_EXP_DAMAGE_STEP = 110.0
const ACTIVITY_EXP_DAMAGE_MAX = 3
const ACTIVITY_EXP_ABSORB_STEP = 40.0
const ACTIVITY_EXP_ABSORB_MAX = 2
const ACTIVITY_EXP_FINISH_PER_BLOW = 1
const ACTIVITY_EXP_FINISH_MAX = 1
const ACTIVITY_EXP_FACILITY_STEP = 8.0
const ACTIVITY_EXP_FACILITY_MAX = 1
const RESULT_GROWTH_CHOICE_EXP_BONUS = 8
const RESULT_GROWTH_PREPARATION_RULES = {
	"slime": {
		"id": "reinforced_body",
		"combat_name": "철벽 준비",
		"preview": "HP+24 · 방어+1",
		"summary": "다음 방어 최대 HP +24 · 방어력 +1",
		"stat_bonuses": {"max_hp": 24, "def": 1}
	},
	"goblin": {
		"id": "pursuit_drill",
		"combat_name": "추격 훈련",
		"preview": "이동+15% · 공격+2",
		"summary": "다음 방어 이동 속도 +15% · 공격력 +2",
		"stat_multipliers": {"move_speed": 1.15},
		"stat_bonuses": {"atk": 2}
	},
	"imp": {
		"id": "flame_focus",
		"combat_name": "화염 집중",
		"preview": "사거리+24 · 공격+2",
		"summary": "다음 방어 공격 사거리 +24 · 공격력 +2",
		"stat_bonuses": {"attack_range": 24.0, "atk": 2}
	}
}
const REQUIRED_MAIN_ROUTE_FROM = "entrance"
const REQUIRED_MAIN_ROUTE_TO = "throne"
const REQUIRED_ROUTE_REPAIR_MAX_STEPS = 16
const SYSTEM_REQUIRED_PATH_PREFIX = "system_required_path"
const SYSTEM_REQUIRED_PATH_GRID_ID = "SYSTEM_REQUIRED_ROUTE"
const USER_AUTHORED_PATH_PREFIX = "user_path"
const USER_AUTHORED_PATH_GRID_ID = "USER_AUTHORED_PATH"
const ONBOARDING_OPENING_TRIGGERS = [
	"opening_start",
	"after_narration",
	"after_player",
	"after_bati",
	"goldin_intro",
	"throne_reveal",
	"opening_end"
]
const ONBOARDING_ESSENTIAL_OPENING_LINE_IDS = [
	"D_OP_PLAYER_001",
	"D_OP_BATI_001",
	"D_OP_BATI_002",
	"D_OP_BATI_003"
]
const ONBOARDING_NONBLOCKING_TRIGGER_IDS = [
	"select_slime",
	"select_goblin",
	"select_imp",
	"global_directive_defend",
	"room_directive_block"
]
const ONBOARDING_ACTION_NONE = ""
const ONBOARDING_ACTION_DAY1_MANAGEMENT = "day1_management"
const KOBOLD_SCOUT_ID = "kobold_scout"
const KOBOLD_SCOUT_CHARACTER_ID = "CHR_ROLO"
const FIRST_RAID_MISSION_ID = "d04_signpost_flip"
const SECOND_PROMOTION_UNLOCK_DAY = 23
const REGULAR_CAMPAIGN_FINAL_DAY = 30
const CASTLE_STAGE_ONE_ID = "stage_01_cave"
const CASTLE_STAGE_TWO_ID = "stage_02_castle"
const CASTLE_STAGE_THREE_ID = "stage_03_keep"
const CASTLE_STAGE_FOUR_ID = "stage_04_citadel"
const ONBOARDING_SCENE_BASE = "res://assets/ui/onboarding/scenes/"
const ONBOARDING_START_SCENE = ONBOARDING_SCENE_BASE + "scene_rookie_cave_start.png"
const ONBOARDING_SCENE_ILLUSTRATIONS = {
	"default": ONBOARDING_SCENE_BASE + "scene_demon_castle_dialogue.png",
	"LV02_OPENING_CUTSCENE": ONBOARDING_SCENE_BASE + "scene_demon_castle_dialogue.png"
}

var graph = null
var use_quarter_module_map := true
var quarter_layout_id: String = ""
var castle_art_stage: String = CASTLE_STAGE_ONE_ID
var castle_evolution_history: Array[String] = [CASTLE_STAGE_ONE_ID]
var last_castle_evolution_day := 0
var last_castle_evolution_from_stage: String = ""
var map_editor_active := false
var map_editor_layout: Dictionary = {}
var map_editor_status: String = ""
var map_editor_errors: Array = []
var map_editor_path_candidate_index := 0
var map_editor_path_drag_active := false
var map_editor_path_drag_source: String = ""
var map_editor_path_drag_target: String = ""
var map_editor_path_drag_position := Vector2.ZERO
var map_editor_path_drag_start_position := Vector2.ZERO
var wave_manager = WaveManagerScript.new()
var hud
var management_scene
var combat_scene
var onboarding_flow = OnboardingFlowScript.new()
var tutorial_manager = TutorialManagerScript.new()
var first_play_observation = FirstPlayObservationRecorderScript.new()
var run_metrics_tracker = RunMetricsTrackerScript.new()
var resolved_campaign_ending_id := "true_demon_castle"
var campaign_profile: Dictionary = NewCycleServiceScript.default_profile()
var campaign_cycle_index := 1
var inherited_legacy_monster: Dictionary = {}
var onboarding_enabled := false
var onboarding_stage_id: String = "LV00_TITLE_BOOT"
var onboarding_dialogue_queue: Array = []
var onboarding_dialogue_index := 0
var onboarding_dialogue_return_screen: String = Constants.SCREEN_MANAGEMENT
var onboarding_dialogue_complete_action: String = ONBOARDING_ACTION_NONE
var onboarding_seen_dialogue_ids: Dictionary = {}
var onboarding_name_input: LineEdit = null
var onboarding_bati_comment_label: Label = null
var onboarding_name_entry_tip_dismissed := false
var onboarding_boss_hp_thresholds: Dictionary = {}
var onboarding_treasure_stolen_this_day := false
var tutorial_gate_enabled := true
var tutorial_targets: Dictionary = {}
var dungeon_renderer
var quarter_renderer

var rooms: Dictionary = {}
var current_screen: String = Constants.SCREEN_MANAGEMENT
var selected_room: String = "entrance"
var selected_monster_id: String = "slime"
var selected_unit: Node = null
var facility_change_panel_open := false
var build_pick_mode := false
var build_pick_facility_id: String = ""
var build_palette_target_room: String = ""
var build_preview_room_id: String = ""
var build_blocked_room_id: String = ""
var deploy_pick_monster_id: String = ""
var facility_effect_stats: Dictionary = {}
var facility_disabled_timers: Dictionary = {}
var facility_feedback_redraw_accumulator := 0.0
var directive_effect_stats: Dictionary = {}
var raid_selected_mission_id: String = FIRST_RAID_MISSION_ID
var raid_selected_monster_ids: Array[String] = []
var completed_raids: Dictionary = {}
var last_raid_result: Dictionary = {}
var next_defense_modifiers: Dictionary = {}
var campaign_seen_day_intros: Dictionary = {}
var campaign_seen_combat_intros: Dictionary = {}
var campaign_combat_timed_lines_fired: Dictionary = {}
var campaign_chapter_one_clear := false
var campaign_stage_two_prepared := false
var campaign_chapter_two_started := false
var campaign_stage_two_upgrade_funded := false
var campaign_stage_two_unlock_ready := false
var campaign_chapter_three_clear := false
var campaign_chapter_four_clear := false
var campaign_final_chapter_unlocked := false
var campaign_final_upgrade_ready := false
var campaign_final_preparation_confirmed := false
var campaign_completed := false
var campaign_final_battle_outcome := ""
var campaign_finale_defeat_seen := false
var campaign_postgame_active := false
var first_promotion_completed := false
var facility_upgrade_unlocked := false

var global_directive: String = Constants.DIRECTIVE_DEFENSE
var room_directives: Dictionary = {}
var monster_roster: Dictionary = {}
var logs: Array[String] = []

var unit_root: Node2D
var effect_root: Node2D
var ui_layer: CanvasLayer
var combat_camera: Camera2D
var combat_music_player: AudioStreamPlayer
var combat_music_tween: Tween = null
var combat_music_active := false
var combat_time: float = 0.0
var combat_speed: float = 1.0
var combat_paused: bool = false
var combat_view_zoom: float = 1.0
var trap_cooldown: float = 0.0
var spawned_count: int = 0
var result_summary: Dictionary = {}
var rewards_pending: Dictionary = {}
var thief_steal_timers: Dictionary = {}
var treasure_gold_stolen_this_battle := 0
var thieves_spawned_this_battle := 0
var thieves_reached_treasure_this_battle := 0
var thieves_completed_theft_this_battle := 0
var thieves_escaped_this_battle := 0
var engineers_spawned_this_battle := 0
var engineers_reached_facility_this_battle := 0
var facility_disables_this_battle := 0
var engineer_target_rooms: Dictionary = {}
var engineer_completed_units: Dictionary = {}
var engineer_targeted_facility_rooms: Dictionary = {}
var engineer_disabled_facility_rooms: Dictionary = {}
var last_security_grade := ""
var battle_growth_start: Dictionary = {}
var last_growth_summary: Array = []
var result_growth_reviewed := false
var result_growth_choice_monster_id := ""
var result_growth_choice_applied := false
var last_growth_choice_summary: Dictionary = {}
var battle_contribution_stats: Dictionary = {}
var battle_activity_exp_applied := false

var monster_units: Array = []
var enemy_units: Array = []

var dragging_monster_id: String = ""
var drag_monster_position := Vector2.ZERO
var drag_start_position := Vector2.ZERO
var drag_hover_room: String = ""
var monster_drag_texture_cache: Dictionary = {}

var floor_texture: Texture2D
var wall_texture: Texture2D
var spike_texture: Texture2D
var dungeon_art: Dictionary = {}
var props: Dictionary = {}
var effect_textures: Dictionary = {}
var effect_frame_sets: Dictionary = {}

var debug_show_quarter_module_overlay := false
var debug_show_active_overlay := false
var debug_show_socket_overlay := false
var debug_show_walkable_overlay := false
var debug_show_floor_mask_overlay := false
var debug_show_room_id_overlay := false
var debug_show_blocked_overlay := false
var debug_show_cursor_cell := false
var debug_show_path_overlay := false

var campaign_save_enabled := true
var campaign_save_path: String = CampaignSaveStoreScript.SAVE_PATH
var campaign_save_status: String = CampaignSaveStoreScript.STATUS_MISSING
var campaign_save_summary: Dictionary = {}
var campaign_save_error: String = ""
var campaign_save_notice: String = ""
var campaign_save_restore_active := false
var campaign_autosave_pending := false
var campaign_autosave_checkpoint: String = ""

func _ready() -> void:
	randomize()
	RenderingServer.set_default_clear_color(Color("#07050b"))
	DataRegistry.load_all()
	_reset_run_metrics()
	GameState.reset()
	rooms = DataRegistry.rooms.duplicate(true)
	_init_room_facilities()
	_sync_castle_stage_content()
	_setup_dungeon_graph()
	_init_roster()
	_init_room_directives()
	_load_textures()
	_create_layers()
	_create_controllers()
	_configure_campaign_save_context()
	SignalBus.log_added.connect(_on_log_added)
	SignalBus.tutorial_action.connect(_on_tutorial_action)
	onboarding_enabled = onboarding_flow.load()
	if onboarding_enabled:
		tutorial_manager.setup(onboarding_flow.data.get("tutorial_steps", []))
		_onboarding_set_stage("LV00_TITLE_BOOT")
		_refresh_campaign_save_status()
		_set_screen(Constants.SCREEN_TITLE)
	else:
		_set_screen(Constants.SCREEN_MANAGEMENT)
	set_process_input(true)

func _configure_campaign_save_context() -> void:
	var current_scene_node := get_tree().current_scene
	var current_scene_path := ""
	if current_scene_node != null:
		current_scene_path = str(current_scene_node.scene_file_path)
	if current_scene_path.begins_with("res://tools/") and campaign_save_path == CampaignSaveStoreScript.SAVE_PATH:
		campaign_save_enabled = false

func _set_campaign_save_path_for_tests(path: String) -> void:
	campaign_save_path = path
	campaign_save_enabled = path != ""
	campaign_save_notice = ""
	_refresh_campaign_save_status()

func _refresh_campaign_save_status() -> Dictionary:
	if not campaign_save_enabled:
		campaign_save_status = CampaignSaveStoreScript.STATUS_MISSING
		campaign_save_summary.clear()
		campaign_save_error = ""
		return {
			"status": campaign_save_status,
			"summary": campaign_save_summary,
			"error": campaign_save_error
		}
	var inspection: Dictionary = CampaignSaveStoreScript.inspect(campaign_save_path)
	campaign_save_status = str(inspection.get("status", CampaignSaveStoreScript.STATUS_CORRUPT))
	campaign_save_summary = inspection.get("summary", {}).duplicate(true)
	campaign_save_error = str(inspection.get("error", ""))
	return inspection

func _campaign_safe_save_screen(screen_name: String) -> bool:
	return screen_name in [
		Constants.SCREEN_MANAGEMENT,
		Constants.SCREEN_MONSTER,
		Constants.SCREEN_RESULT,
		Constants.SCREEN_ENDING,
		Constants.SCREEN_CYCLE_DOCTRINE,
		Constants.SCREEN_DIALOGUE,
		Constants.SCREEN_RAID_PREVIEW,
		Constants.SCREEN_RAID
	]

func _schedule_campaign_autosave(checkpoint: String) -> void:
	if not campaign_save_enabled or campaign_save_restore_active or map_editor_active:
		return
	if not _campaign_safe_save_screen(checkpoint):
		return
	campaign_autosave_checkpoint = checkpoint
	if campaign_autosave_pending:
		return
	campaign_autosave_pending = true
	call_deferred("_flush_campaign_autosave")

func _flush_campaign_autosave() -> bool:
	if not campaign_autosave_pending:
		return false
	campaign_autosave_pending = false
	if not campaign_save_enabled or campaign_save_restore_active or map_editor_active:
		return false
	if not _campaign_safe_save_screen(current_screen) or current_screen != campaign_autosave_checkpoint:
		return false
	var payload := _campaign_save_payload(current_screen)
	var summary := _campaign_save_summary(current_screen)
	var write_result: Dictionary = CampaignSaveStoreScript.write(payload, summary, campaign_save_path)
	if not bool(write_result.get("ok", false)):
		campaign_save_status = CampaignSaveStoreScript.STATUS_CORRUPT
		campaign_save_error = str(write_result.get("error", "저장에 실패했습니다."))
		campaign_save_notice = "자동 저장에 실패했습니다. 이전 저장은 유지됩니다.\n%s" % campaign_save_error
		_log("자동 저장 실패: %s" % campaign_save_error)
		push_warning("Campaign autosave failed: %s" % campaign_save_error)
		_show_campaign_save_notice_overlay()
		return false
	campaign_save_status = CampaignSaveStoreScript.STATUS_VALID
	campaign_save_summary = summary.duplicate(true)
	campaign_save_error = ""
	campaign_save_notice = ""
	_clear_campaign_save_notice_overlay()
	return true

func _show_campaign_save_notice_overlay() -> void:
	if ui_layer == null or hud == null or campaign_save_notice == "" or current_screen == Constants.SCREEN_TITLE:
		return
	_clear_campaign_save_notice_overlay()
	var notice = hud.panel(Rect2(500, 18, 920, 88), Color("#2a0d12f5"), Color("#ff756d"), "", "flat")
	notice.name = "CampaignSaveNoticeOverlay"
	notice.z_index = 500
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var notice_label = hud.label(notice, campaign_save_notice, Vector2(24, 10), Vector2(872, 68), 18, Color("#ffe4df"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 3)
	notice_label.name = "CampaignSaveNoticeText"

func _clear_campaign_save_notice_overlay() -> void:
	if ui_layer == null:
		return
	var existing := ui_layer.get_node_or_null("CampaignSaveNoticeOverlay")
	if existing == null:
		return
	ui_layer.remove_child(existing)
	existing.queue_free()

func _campaign_save_summary(checkpoint: String) -> Dictionary:
	var stage_info := _castle_stage_info()
	return {
		"day": GameState.day,
		"campaign_final_day": REGULAR_CAMPAIGN_FINAL_DAY,
		"player_name": _onboarding_player_name(),
		"castle_stage": castle_art_stage,
		"castle_stage_index": int(stage_info.get("index", 1)),
		"castle_name": str(stage_info.get("display_name", "마왕성")),
		"checkpoint": checkpoint,
		"checkpoint_label": _campaign_checkpoint_label(checkpoint),
		"campaign_completed": campaign_completed,
		"campaign_postgame_active": campaign_postgame_active,
		"final_battle_outcome": campaign_final_battle_outcome,
		"cycle_index": campaign_cycle_index,
		"ending_archive_count": _known_ending_count()
	}


func _known_ending_count() -> int:
	var archive: Dictionary = campaign_profile.get("ending_archive", {})
	var ending_ids: Dictionary = {}
	for ending_id_value in archive.keys():
		ending_ids[str(ending_id_value)] = true
	if campaign_completed and campaign_final_battle_outcome == "victory" and resolved_campaign_ending_id != "":
		ending_ids[resolved_campaign_ending_id] = true
	return ending_ids.size()

func _campaign_checkpoint_label(checkpoint: String) -> String:
	match checkpoint:
		Constants.SCREEN_RESULT:
			return "결산 확인"
		Constants.SCREEN_ENDING:
			return "최종 엔딩"
		Constants.SCREEN_RAID, Constants.SCREEN_RAID_PREVIEW:
			return "원정 준비"
		Constants.SCREEN_DIALOGUE:
			return "이야기 진행"
		Constants.SCREEN_MONSTER:
			return "몬스터 관리"
		_:
			return "후일담 관리" if campaign_postgame_active else "성 관리"

func _campaign_save_payload(checkpoint: String) -> Dictionary:
	return {
		"checkpoint": checkpoint,
		"screen": current_screen,
		"game_state": GameState.campaign_snapshot(),
		"world": {
			"quarter_layout_id": quarter_layout_id,
			"quarter_layout": DataRegistry.quarter_layout(quarter_layout_id),
			"castle_art_stage": castle_art_stage,
			"castle_evolution_history": castle_evolution_history.duplicate(),
			"last_castle_evolution_day": last_castle_evolution_day,
			"last_castle_evolution_from_stage": last_castle_evolution_from_stage,
			"rooms": rooms.duplicate(true),
			"selected_room": selected_room,
			"selected_monster_id": selected_monster_id,
			"global_directive": global_directive,
			"room_directives": room_directives.duplicate(true),
			"monster_roster": monster_roster.duplicate(true),
			"logs": logs.duplicate()
		},
		"raid": {
			"selected_mission_id": raid_selected_mission_id,
			"selected_monster_ids": raid_selected_monster_ids.duplicate(),
			"completed_raids": completed_raids.duplicate(true),
			"last_raid_result": last_raid_result.duplicate(true),
			"next_defense_modifiers": next_defense_modifiers.duplicate(true)
		},
		"campaign": {
			"seen_day_intros": _integer_dictionary_keys(campaign_seen_day_intros),
			"seen_combat_intros": _integer_dictionary_keys(campaign_seen_combat_intros),
			"chapter_one_clear": campaign_chapter_one_clear,
			"stage_two_prepared": campaign_stage_two_prepared,
			"chapter_two_started": campaign_chapter_two_started,
			"stage_two_upgrade_funded": campaign_stage_two_upgrade_funded,
			"stage_two_unlock_ready": campaign_stage_two_unlock_ready,
			"chapter_three_clear": campaign_chapter_three_clear,
			"chapter_four_clear": campaign_chapter_four_clear,
			"final_chapter_unlocked": campaign_final_chapter_unlocked,
			"final_upgrade_ready": campaign_final_upgrade_ready,
			"final_preparation_confirmed": campaign_final_preparation_confirmed,
			"completed": campaign_completed,
			"final_battle_outcome": campaign_final_battle_outcome,
			"finale_defeat_seen": campaign_finale_defeat_seen,
			"postgame_active": campaign_postgame_active,
			"first_promotion_completed": first_promotion_completed,
			"facility_upgrade_unlocked": facility_upgrade_unlocked,
			"last_security_grade": last_security_grade
		},
		"result": {
			"summary": result_summary.duplicate(true),
			"rewards_pending": rewards_pending.duplicate(true),
			"last_growth_summary": last_growth_summary.duplicate(true),
			"growth_reviewed": result_growth_reviewed,
			"growth_choice_monster_id": result_growth_choice_monster_id,
			"growth_choice_applied": result_growth_choice_applied,
			"last_growth_choice_summary": last_growth_choice_summary.duplicate(true)
		},
		"onboarding": {
			"stage_id": onboarding_stage_id,
			"seen_dialogue_ids": onboarding_seen_dialogue_ids.duplicate(true),
			"dialogue_queue": onboarding_dialogue_queue.duplicate(true),
			"dialogue_index": onboarding_dialogue_index,
			"dialogue_return_screen": onboarding_dialogue_return_screen,
			"dialogue_complete_action": onboarding_dialogue_complete_action,
			"name_entry_tip_dismissed": onboarding_name_entry_tip_dismissed,
			"tutorial_gate_enabled": tutorial_gate_enabled,
			"tutorial_manager": tutorial_manager.export_state()
		},
		"legacy_expansion": {
			"run_metrics": run_metrics_tracker.snapshot(),
			"resolved_ending_id": resolved_campaign_ending_id,
			"profile": campaign_profile.duplicate(true),
			"cycle_index": campaign_cycle_index,
			"legacy_monster": inherited_legacy_monster.duplicate(true)
		}
	}

func _integer_dictionary_keys(source: Dictionary) -> Array[int]:
	var values: Array[int] = []
	for key_value in source.keys():
		var key := int(key_value)
		if not values.has(key):
			values.append(key)
	values.sort()
	return values

func _integer_key_set(values) -> Dictionary:
	var result := {}
	if not (values is Array):
		return result
	for value in values:
		result[int(value)] = true
	return result

func _string_array(values) -> Array[String]:
	var result: Array[String] = []
	if not (values is Array):
		return result
	for value in values:
		result.append(str(value))
	return result

func _campaign_payload_is_restorable(payload: Dictionary) -> bool:
	var game_state_value = payload.get("game_state", null)
	var world_value = payload.get("world", null)
	var campaign_value = payload.get("campaign", null)
	if not (game_state_value is Dictionary) or not (world_value is Dictionary) or not (campaign_value is Dictionary):
		return false
	var game_state: Dictionary = game_state_value
	var world: Dictionary = world_value
	var campaign: Dictionary = campaign_value
	var stage_id: String = world.get("castle_art_stage") if world.get("castle_art_stage") is String else ""
	var validation_summary := {
		"day": game_state.get("day"),
		"campaign_final_day": REGULAR_CAMPAIGN_FINAL_DAY,
		"player_name": game_state.get("player_name"),
		"castle_stage": stage_id,
		"castle_stage_index": int(CampaignSaveStoreScript.CASTLE_STAGE_INDEX.get(stage_id, 0)),
		"castle_name": "복원 검사",
		"checkpoint": payload.get("screen") if payload.get("screen") is String else "",
		"checkpoint_label": "복원 검사",
		"campaign_completed": campaign.get("completed"),
		"campaign_postgame_active": campaign.get("postgame_active"),
		"final_battle_outcome": campaign.get("final_battle_outcome")
	}
	if CampaignSaveStoreScript.validate_payload(payload, validation_summary) != "":
		return false
	var onboarding: Dictionary = payload.get("onboarding", {})
	if not tutorial_manager.can_import_state(onboarding.get("tutorial_manager", {})):
		return false
	var candidate_layout: Dictionary = world.get("quarter_layout", {}).duplicate(true)
	var target_stage_index := int(CampaignSaveStoreScript.CASTLE_STAGE_INDEX.get(stage_id, 0))
	for stage_id_value in DataRegistry.castle_evolution_stage_ids():
		var expansion_stage_id := str(stage_id_value)
		if _castle_stage_index(expansion_stage_id) > target_stage_index:
			continue
		var addition: Dictionary = DataRegistry.castle_stage_expansion(expansion_stage_id)
		_merge_unique_layout_entries(candidate_layout, "placed_modules", addition.get("placed_modules", []), "instance_id")
		_merge_unique_layout_entries(candidate_layout, "connections", addition.get("connections", []), "from", "to")
		_merge_unique_layout_entries(candidate_layout, "required_paths", addition.get("required_paths", []), "from", "to")
	var candidate_graph = ModuleGraphScript.new()
	candidate_graph.setup_quarter(DataRegistry.quarter_modules, candidate_layout, world.get("rooms", {}))
	var graph_validation: Dictionary = candidate_graph.validation_summary()
	if not bool(graph_validation.get("ok", false)):
		return false
	return not candidate_graph.path_between(REQUIRED_MAIN_ROUTE_FROM, REQUIRED_MAIN_ROUTE_TO).is_empty()

func _restore_campaign_payload(payload: Dictionary) -> bool:
	if not _campaign_payload_is_restorable(payload):
		return false
	campaign_save_restore_active = true
	campaign_autosave_pending = false
	_clear_units()
	_clear_effects()
	_reset_engineer_combat_state()
	map_editor_active = false
	map_editor_layout.clear()
	map_editor_errors.clear()
	_clear_map_editor_path_drag()
	if not GameState.restore_campaign_snapshot(payload.get("game_state", {})):
		campaign_save_restore_active = false
		return false

	var world: Dictionary = payload.get("world", {})
	castle_art_stage = str(world.get("castle_art_stage", CASTLE_STAGE_ONE_ID))
	castle_evolution_history = _string_array(world.get("castle_evolution_history", [CASTLE_STAGE_ONE_ID]))
	if castle_evolution_history.is_empty():
		castle_evolution_history.append(CASTLE_STAGE_ONE_ID)
	last_castle_evolution_day = int(world.get("last_castle_evolution_day", 0))
	last_castle_evolution_from_stage = str(world.get("last_castle_evolution_from_stage", ""))
	rooms = world.get("rooms", {}).duplicate(true)
	_init_room_facilities()
	_sync_castle_stage_content()
	quarter_layout_id = str(world.get("quarter_layout_id", DataRegistry.quarter_default_layout_id))
	var saved_layout = world.get("quarter_layout", {})
	if quarter_layout_id != "" and saved_layout is Dictionary and not saved_layout.is_empty():
		DataRegistry.register_quarter_layout(quarter_layout_id, saved_layout, false)
	_setup_dungeon_graph()
	selected_room = str(world.get("selected_room", "entrance"))
	if not rooms.has(selected_room):
		selected_room = "entrance"
	selected_monster_id = str(world.get("selected_monster_id", "slime"))
	global_directive = str(world.get("global_directive", Constants.DIRECTIVE_DEFENSE))
	room_directives = world.get("room_directives", {}).duplicate(true)
	for room_id_value in rooms.keys():
		if not room_directives.has(room_id_value):
			room_directives[room_id_value] = Constants.ROOM_DIRECTIVE_NONE
	monster_roster = world.get("monster_roster", {}).duplicate(true)
	_normalize_monster_roster_legacy_fields()
	logs = _string_array(world.get("logs", []))

	var raid: Dictionary = payload.get("raid", {})
	raid_selected_mission_id = str(raid.get("selected_mission_id", FIRST_RAID_MISSION_ID))
	raid_selected_monster_ids = _string_array(raid.get("selected_monster_ids", []))
	completed_raids = raid.get("completed_raids", {}).duplicate(true)
	last_raid_result = raid.get("last_raid_result", {}).duplicate(true)
	next_defense_modifiers = raid.get("next_defense_modifiers", {}).duplicate(true)

	var campaign: Dictionary = payload.get("campaign", {})
	campaign_seen_day_intros = _integer_key_set(campaign.get("seen_day_intros", []))
	campaign_seen_combat_intros = _integer_key_set(campaign.get("seen_combat_intros", []))
	campaign_chapter_one_clear = bool(campaign.get("chapter_one_clear", false))
	campaign_stage_two_prepared = bool(campaign.get("stage_two_prepared", false))
	campaign_chapter_two_started = bool(campaign.get("chapter_two_started", false))
	campaign_stage_two_upgrade_funded = bool(campaign.get("stage_two_upgrade_funded", false))
	campaign_stage_two_unlock_ready = bool(campaign.get("stage_two_unlock_ready", false))
	campaign_chapter_three_clear = bool(campaign.get("chapter_three_clear", false))
	campaign_chapter_four_clear = bool(campaign.get("chapter_four_clear", false))
	campaign_final_chapter_unlocked = bool(campaign.get("final_chapter_unlocked", false))
	campaign_final_upgrade_ready = bool(campaign.get("final_upgrade_ready", false))
	campaign_final_preparation_confirmed = bool(campaign.get("final_preparation_confirmed", false))
	campaign_completed = bool(campaign.get("completed", false))
	campaign_final_battle_outcome = str(campaign.get("final_battle_outcome", ""))
	campaign_finale_defeat_seen = bool(campaign.get("finale_defeat_seen", false))
	campaign_postgame_active = bool(campaign.get("postgame_active", false))
	first_promotion_completed = bool(campaign.get("first_promotion_completed", false))
	facility_upgrade_unlocked = bool(campaign.get("facility_upgrade_unlocked", false))
	last_security_grade = str(campaign.get("last_security_grade", ""))

	var result: Dictionary = payload.get("result", {})
	result_summary = result.get("summary", {}).duplicate(true)
	rewards_pending = result.get("rewards_pending", {}).duplicate(true)
	last_growth_summary = result.get("last_growth_summary", []).duplicate(true)
	result_growth_reviewed = bool(result.get("growth_reviewed", false))
	result_growth_choice_monster_id = str(result.get("growth_choice_monster_id", ""))
	result_growth_choice_applied = bool(result.get("growth_choice_applied", false))
	last_growth_choice_summary = result.get("last_growth_choice_summary", {}).duplicate(true)

	_reset_run_metrics()
	var legacy_expansion: Dictionary = payload.get("legacy_expansion", {})
	campaign_profile = NewCycleServiceScript.normalize_profile(legacy_expansion.get("profile", {}))
	campaign_cycle_index = maxi(1, int(legacy_expansion.get("cycle_index", int(campaign_profile.get("completed_cycles", 0)) + 1)))
	inherited_legacy_monster = legacy_expansion.get("legacy_monster", {}).duplicate(true) if legacy_expansion.get("legacy_monster") is Dictionary else {}
	var metric_restore_errors := run_metrics_tracker.restore(legacy_expansion.get("run_metrics", {}))
	if not metric_restore_errors.is_empty():
		campaign_save_restore_active = false
		return false
	resolved_campaign_ending_id = str(legacy_expansion.get("resolved_ending_id", "true_demon_castle"))

	var onboarding: Dictionary = payload.get("onboarding", {})
	onboarding_stage_id = str(onboarding.get("stage_id", GameState.onboarding_stage))
	GameState.onboarding_stage = onboarding_stage_id
	onboarding_seen_dialogue_ids = onboarding.get("seen_dialogue_ids", {}).duplicate(true)
	onboarding_dialogue_queue = onboarding.get("dialogue_queue", []).duplicate(true)
	onboarding_dialogue_index = int(onboarding.get("dialogue_index", 0))
	onboarding_dialogue_return_screen = str(onboarding.get("dialogue_return_screen", Constants.SCREEN_MANAGEMENT))
	onboarding_dialogue_complete_action = str(onboarding.get("dialogue_complete_action", ONBOARDING_ACTION_NONE))
	onboarding_name_entry_tip_dismissed = bool(onboarding.get("name_entry_tip_dismissed", false))
	tutorial_gate_enabled = bool(onboarding.get("tutorial_gate_enabled", false))
	if not tutorial_manager.import_state(onboarding.get("tutorial_manager", {})):
		campaign_save_restore_active = false
		return false
	onboarding_enabled = onboarding_flow.loaded

	_ensure_selected_monster_available_for_defense()
	if quarter_renderer != null and quarter_renderer.has_method("refresh_layout"):
		quarter_renderer.refresh_layout()
	SignalBus.resources_changed.emit()
	var restored_screen := str(payload.get("screen", Constants.SCREEN_MANAGEMENT))
	if restored_screen == Constants.SCREEN_DIALOGUE and (onboarding_dialogue_queue.is_empty() or onboarding_dialogue_index >= onboarding_dialogue_queue.size()):
		restored_screen = Constants.SCREEN_MANAGEMENT
	if restored_screen == Constants.SCREEN_RESULT and result_summary.is_empty():
		restored_screen = Constants.SCREEN_MANAGEMENT
	if restored_screen == Constants.SCREEN_ENDING and (not campaign_completed or campaign_final_battle_outcome != "victory"):
		restored_screen = Constants.SCREEN_MANAGEMENT
	if campaign_cycle_index >= 2 and str(campaign_profile.get("active_doctrine_id", "")) == "":
		restored_screen = Constants.SCREEN_CYCLE_DOCTRINE
	logs.append("저장 기록을 불러왔습니다. DAY %d." % GameState.day)
	_set_screen(restored_screen)
	campaign_save_restore_active = false
	return true

func _continue_campaign_save() -> void:
	var inspection := _refresh_campaign_save_status()
	if campaign_save_status != CampaignSaveStoreScript.STATUS_VALID:
		_set_screen(Constants.SCREEN_TITLE)
		return
	if not _restore_campaign_payload(inspection.get("payload", {})):
		var restore_error := "저장 내용을 안전하게 복원할 수 없습니다."
		var invalidated := CampaignSaveStoreScript.mark_invalid(campaign_save_path, restore_error)
		campaign_save_status = CampaignSaveStoreScript.STATUS_CORRUPT
		campaign_save_summary.clear()
		campaign_save_error = restore_error
		campaign_save_notice = "저장 내용을 복원하지 못해 이어하기를 차단했습니다." if invalidated else "저장 복원과 손상 기록 격리에 모두 실패했습니다. 파일 사용 권한을 확인하세요."
		_onboarding_reset_game()
		_onboarding_set_stage("LV00_TITLE_BOOT")
		_set_screen(Constants.SCREEN_TITLE)

func _delete_campaign_save() -> bool:
	campaign_autosave_pending = false
	if not campaign_save_enabled:
		campaign_save_notice = ""
		return true
	var removed := CampaignSaveStoreScript.delete(campaign_save_path)
	if removed and campaign_save_path == CampaignSaveStoreScript.SAVE_PATH:
		removed = CampaignSaveV2StoreScript.delete(CampaignSaveV2StoreScript.SAVE_PATH)
	if not removed:
		campaign_save_notice = "저장 기록을 지우지 못해 새 게임을 시작하지 않았습니다.\n파일 사용 권한을 확인한 뒤 다시 시도하세요."
		campaign_save_error = campaign_save_notice
		push_warning("Campaign save deletion failed: %s" % campaign_save_path)
		return false
	campaign_save_notice = ""
	_refresh_campaign_save_status()
	return removed

func _physics_process(delta: float) -> void:
	combat_scene.physics_process(delta)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and current_screen == Constants.SCREEN_DIALOGUE:
		if _is_dialogue_advance_key(event.keycode):
			_onboarding_advance_dialogue()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseMotion and map_editor_path_drag_active:
		_update_map_editor_path_drag(get_global_mouse_position())
		return
	if event is InputEventMouseMotion and dragging_monster_id != "":
		_update_management_monster_drag(get_global_mouse_position())
		return
	if _onboarding_screen_blocks_map_input():
		if event is InputEventKey and event.pressed and not event.echo:
			_handle_key(event.keycode)
		return
	if event is InputEventMouseButton:
		var screen_point = event.position
		var point = _combat_screen_to_world(screen_point) if current_screen == Constants.SCREEN_COMBAT else get_global_mouse_position()
		if event.pressed and current_screen == Constants.SCREEN_COMBAT:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_adjust_combat_zoom(1, screen_point)
				return
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_adjust_combat_zoom(-1, screen_point)
				return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if current_screen == Constants.SCREEN_MANAGEMENT:
				if event.pressed:
					if screen_point.x > -90000 and _management_ui_at(screen_point):
						return
					if map_editor_active and _start_map_editor_path_drag(point):
						return
					if _start_management_monster_drag(point):
						return
					_handle_left_click(point, screen_point)
				elif map_editor_path_drag_active:
					_finish_map_editor_path_drag(point)
				elif dragging_monster_id != "":
					_finish_management_monster_drag(point)
				return
			if event.pressed:
				_handle_left_click(point, screen_point)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_handle_right_click(point, screen_point)
	elif event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event.keycode)

func _draw() -> void:
	if use_quarter_module_map and quarter_renderer != null:
		quarter_renderer.draw()
		if current_screen != Constants.SCREEN_COMBAT:
			dungeon_renderer.draw_roster_preview()
	else:
		dungeon_renderer.draw()
	_draw_combat_facility_feedback()
	_draw_management_drag_feedback()

func _init_roster() -> void:
	monster_roster = {
		"slime": {"level": 1, "exp": 0, "bond": 0, "bond_rank": 0, "unlocked_memory_ids": [], "room": "entrance"},
		"goblin": {"level": 1, "exp": 0, "bond": 0, "bond_rank": 0, "unlocked_memory_ids": [], "room": "barracks"},
		"imp": {"level": 1, "exp": 0, "bond": 0, "bond_rank": 0, "unlocked_memory_ids": [], "room": "recovery"}
	}


func _normalize_monster_roster_legacy_fields() -> void:
	for monster_id_value in monster_roster.keys():
		var monster_id := str(monster_id_value)
		if not (monster_roster.get(monster_id) is Dictionary):
			continue
		var roster: Dictionary = monster_roster.get(monster_id)
		if not roster.has("bond"):
			roster["bond"] = clampi((int(roster.get("level", 1)) - 1) * 12, 0, 70)
		roster["bond"] = clampi(int(roster.get("bond", 0)), 0, 100)
		roster["bond_rank"] = _monster_bond_rank(int(roster.get("bond", 0)))
		if not (roster.get("unlocked_memory_ids", []) is Array):
			roster["unlocked_memory_ids"] = []
		monster_roster[monster_id] = roster


func _monster_bond_rank(bond: int) -> int:
	return clampi(int(bond / 25), 0, 4)


func _monster_bond_rank_name(bond: int) -> String:
	return ["낯섦", "신뢰", "동료", "식구", "운명 공동체"][_monster_bond_rank(bond)]


func _grant_monster_bond(monster_id: String, amount: int) -> Dictionary:
	if not monster_roster.has(monster_id) or not (monster_roster.get(monster_id) is Dictionary):
		return {}
	var before := clampi(int(monster_roster[monster_id].get("bond", 0)), 0, 100)
	var after := clampi(before + maxi(0, amount), 0, 100)
	var rank_before := _monster_bond_rank(before)
	var rank_after := _monster_bond_rank(after)
	monster_roster[monster_id]["bond"] = after
	monster_roster[monster_id]["bond_rank"] = rank_after
	var unlocked_memory_id := ""
	if rank_after > rank_before:
		unlocked_memory_id = "bond_%s_rank_%d" % [monster_id, rank_after]
		var memory_ids: Array = monster_roster[monster_id].get("unlocked_memory_ids", [])
		if not memory_ids.has(unlocked_memory_id):
			memory_ids.append(unlocked_memory_id)
		monster_roster[monster_id]["unlocked_memory_ids"] = memory_ids
	return {
		"before": before,
		"after": after,
		"gain": after - before,
		"rank": rank_after,
		"unlocked_memory_id": unlocked_memory_id
	}

func _init_room_directives() -> void:
	room_directives.clear()
	for room_id in rooms.keys():
		room_directives[room_id] = Constants.ROOM_DIRECTIVE_NONE

func _init_room_facilities() -> void:
	for room_id in rooms.keys():
		if rooms[room_id].has("facility_role"):
			continue
		rooms[room_id]["facility_role"] = _default_facility_role(room_id, rooms[room_id])

func _setup_dungeon_graph() -> void:
	var layout_data = _quarter_layout_for_graph()
	var can_use_quarter_map = use_quarter_module_map and not DataRegistry.quarter_modules.is_empty() and not layout_data.is_empty()
	if can_use_quarter_map:
		if quarter_layout_id == "" and not map_editor_active:
			quarter_layout_id = str(layout_data.get("template_id", DataRegistry.quarter_default_layout_id))
		graph = ModuleGraphScript.new()
		graph.setup_quarter(DataRegistry.quarter_modules, layout_data, rooms)
		var validation = graph.validation_summary()
		if not bool(validation.get("ok", false)) and not map_editor_active:
			push_warning("Quarter module map validation errors: %s" % str(validation.get("errors", [])))
	else:
		graph = RoomGraphScript.new()
		graph.setup(rooms)
	if quarter_renderer != null and quarter_renderer.has_method("invalidate_layout_cache"):
		quarter_renderer.invalidate_layout_cache()

func _quarter_layout_for_graph() -> Dictionary:
	if map_editor_active and not map_editor_layout.is_empty():
		return map_editor_layout.duplicate(true)
	var layout := DataRegistry.quarter_layout(quarter_layout_id)
	return _layout_with_castle_stage_expansions(layout)

func _layout_with_castle_stage_expansions(source_layout: Dictionary) -> Dictionary:
	var expanded := source_layout.duplicate(true)
	if expanded.is_empty() or not DataRegistry.has_method("castle_stage_expansion"):
		return expanded
	for stage_id_value in DataRegistry.castle_evolution_stage_ids():
		var stage_id := str(stage_id_value)
		if _castle_stage_index(stage_id) > _castle_stage_index():
			continue
		var addition: Dictionary = DataRegistry.castle_stage_expansion(stage_id)
		_merge_unique_layout_entries(expanded, "placed_modules", addition.get("placed_modules", []), "instance_id")
		_merge_unique_layout_entries(expanded, "connections", addition.get("connections", []), "from", "to")
		_merge_unique_layout_entries(expanded, "required_paths", addition.get("required_paths", []), "from", "to")
	return expanded

func _merge_unique_layout_entries(target: Dictionary, key: String, additions: Array, first_key: String, second_key: String = "") -> void:
	var entries: Array = target.get(key, []).duplicate(true)
	for addition_value in additions:
		if not (addition_value is Dictionary):
			continue
		var addition: Dictionary = addition_value
		var exists := false
		for entry_value in entries:
			if not (entry_value is Dictionary):
				continue
			var entry: Dictionary = entry_value
			if str(entry.get(first_key, "")) != str(addition.get(first_key, "")):
				continue
			if second_key == "" or str(entry.get(second_key, "")) == str(addition.get(second_key, "")):
				exists = true
				break
		if not exists:
			entries.append(addition.duplicate(true))
	target[key] = entries

func set_quarter_layout(layout_id: String) -> bool:
	if not DataRegistry.quarter_layouts.has(layout_id):
		push_warning("Unknown quarter layout: %s" % layout_id)
		return false
	map_editor_active = false
	_clear_map_editor_path_drag()
	facility_change_panel_open = false
	map_editor_layout.clear()
	map_editor_errors.clear()
	quarter_layout_id = layout_id
	_setup_dungeon_graph()
	if quarter_renderer != null and quarter_renderer.has_method("refresh_layout"):
		quarter_renderer.refresh_layout()
	queue_redraw()
	return true

func quarter_layout_display_name(layout_id: String) -> String:
	var layout = DataRegistry.quarter_layout(layout_id)
	return str(layout.get("display_name", layout_id))

func _select_quarter_layout(layout_id: String) -> void:
	if layout_id == quarter_layout_id:
		return
	if set_quarter_layout(layout_id):
		facility_change_panel_open = false
		_log("맵 레이아웃을 %s로 전환했습니다." % quarter_layout_display_name(layout_id))
		_set_screen(Constants.SCREEN_MANAGEMENT)

func _open_map_editor() -> void:
	if not use_quarter_module_map:
		_log("쿼터뷰 맵에서만 편집할 수 있습니다.")
		return
	var source_layout = _quarter_layout_for_graph()
	if source_layout.is_empty():
		_log("편집할 맵 레이아웃이 없습니다.")
		return
	map_editor_active = true
	_clear_map_editor_path_drag()
	facility_change_panel_open = false
	_clear_management_action_mode(false)
	map_editor_layout = source_layout.duplicate(true)
	map_editor_layout["template_id"] = "%s_draft" % quarter_layout_id
	map_editor_status = "편집 중"
	map_editor_path_candidate_index = 0
	map_editor_errors.clear()
	_rebuild_map_editor_preview("편집 시작")
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _cancel_map_editor() -> void:
	if not map_editor_active:
		return
	map_editor_active = false
	_clear_map_editor_path_drag()
	map_editor_layout.clear()
	map_editor_status = ""
	map_editor_path_candidate_index = 0
	map_editor_errors.clear()
	_setup_dungeon_graph()
	if quarter_renderer != null and quarter_renderer.has_method("refresh_layout"):
		quarter_renderer.refresh_layout()
	_log("맵 편집을 취소했습니다.")
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _move_map_editor_room(delta: Vector2i) -> void:
	if not map_editor_active:
		_open_map_editor()
		return
	var room_id = selected_room
	if _map_editor_selected_locked():
		map_editor_status = "고정 방은 이동할 수 없습니다."
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	map_editor_path_candidate_index = 0
	var candidate = map_editor_layout.duplicate(true)
	var moved = false
	var placed_modules: Array = candidate.get("placed_modules", [])
	for index in range(placed_modules.size()):
		var placed: Dictionary = placed_modules[index]
		if str(placed.get("instance_id", "")) != room_id:
			continue
		var origin_value: Array = placed.get("grid_origin", [0, 0])
		var origin = Vector2i(int(origin_value[0]), int(origin_value[1])) if origin_value.size() >= 2 else Vector2i.ZERO
		placed["grid_origin"] = [origin.x + delta.x, origin.y + delta.y]
		placed_modules[index] = placed
		moved = true
		break
	if not moved:
		map_editor_status = "선택 방을 레이아웃에서 찾을 수 없습니다."
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	candidate["placed_modules"] = placed_modules
	map_editor_layout = candidate
	_rebuild_map_editor_preview("이동")
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _map_editor_disconnect_selected_room() -> void:
	if not map_editor_active:
		_open_map_editor()
		return
	map_editor_path_candidate_index = 0
	var connections: Array = map_editor_layout.get("connections", [])
	var kept_connections: Array = []
	var socket_states: Dictionary = map_editor_layout.get("socket_states", {}).duplicate(true)
	var removed_count = 0
	for connection in connections:
		var from_ref = str(connection.get("from", ""))
		var to_ref = str(connection.get("to", ""))
		if _map_editor_ref_instance(from_ref) == selected_room or _map_editor_ref_instance(to_ref) == selected_room:
			socket_states[from_ref] = "open_placeholder"
			socket_states[to_ref] = "open_placeholder"
			removed_count += 1
		else:
			kept_connections.append(connection)
	map_editor_layout["connections"] = kept_connections
	map_editor_layout["socket_states"] = socket_states
	_rebuild_map_editor_preview("연결 해제")
	if removed_count == 0:
		map_editor_status = "끊을 연결이 없습니다."
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _map_editor_connect_adjacent_socket() -> void:
	if not map_editor_active:
		_open_map_editor()
		return
	map_editor_path_candidate_index = 0
	var candidate = _map_editor_first_adjacent_socket_pair()
	if candidate.is_empty():
		map_editor_status = "인접한 연결 후보가 없습니다."
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	var connections: Array = map_editor_layout.get("connections", []).duplicate(true)
	connections.append({"from": candidate["from"], "to": candidate["to"]})
	var socket_states: Dictionary = map_editor_layout.get("socket_states", {}).duplicate(true)
	socket_states[str(candidate["from"])] = "connected"
	socket_states[str(candidate["to"])] = "connected"
	map_editor_layout["connections"] = connections
	map_editor_layout["socket_states"] = socket_states
	_rebuild_map_editor_preview("인접 연결")
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _map_editor_connect_selected_path_ends() -> void:
	if not map_editor_active:
		_open_map_editor()
		return
	var placed = _map_editor_placed_entry(selected_room)
	if placed.is_empty() or not _map_editor_entry_is_path(placed):
		map_editor_status = "선택한 항목은 양끝 연결 가능한 통로가 아닙니다."
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	map_editor_path_candidate_index = 0
	var added := 0
	for other_id in _layout_instance_ids(map_editor_layout):
		if str(other_id) == selected_room:
			continue
		added += _layout_connect_adjacent_sockets_between_instances(map_editor_layout, selected_room, str(other_id), false)
	_rebuild_map_editor_preview("통로 양끝 연결")
	if added == 0:
		map_editor_status = "통로 양끝에 새로 연결할 인접 소켓이 없습니다."
	else:
		map_editor_status = "통로 양끝 연결 %d개. 저장 전 경로를 확인하세요." % added
		_log("통로 %s 양끝 연결 %d개." % [selected_room, added])
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _map_editor_next_gap_path_candidate() -> void:
	if not map_editor_active:
		_open_map_editor()
		return
	var candidates = _map_editor_gap_path_candidates_for_selected()
	if candidates.is_empty():
		map_editor_path_candidate_index = 0
		map_editor_status = "배치 가능한 2칸 통로 후보가 없습니다."
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	map_editor_path_candidate_index = (map_editor_path_candidate_index + 1) % candidates.size()
	map_editor_status = _map_editor_path_candidate_line()
	queue_redraw()
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _map_editor_select_gap_path_candidate_to(target_instance_id: String) -> bool:
	if not map_editor_active:
		return false
	if target_instance_id == "" or target_instance_id == selected_room:
		return false
	var candidates = _map_editor_gap_path_candidates_for_selected()
	var matching_indices: Array = []
	for index in range(candidates.size()):
		var candidate: Dictionary = candidates[index]
		if str(candidate.get("other_instance", "")) == target_instance_id:
			matching_indices.append(index)
	if matching_indices.is_empty():
		return false

	var current_index = _map_editor_clamped_path_candidate_index(candidates.size())
	var next_index = int(matching_indices[0])
	if str(candidates[current_index].get("other_instance", "")) == target_instance_id:
		for local_index in range(matching_indices.size()):
			if int(matching_indices[local_index]) != current_index:
				continue
			next_index = int(matching_indices[(local_index + 1) % matching_indices.size()])
			break
	map_editor_path_candidate_index = next_index
	var local_position = matching_indices.find(next_index) + 1
	map_editor_status = "목표 후보 %d/%d 선택: %s -> %s. 통로 배치로 확정하세요." % [
		local_position,
		matching_indices.size(),
		display_name_for_instance(selected_room),
		display_name_for_instance(target_instance_id)
	]
	queue_redraw()
	_set_screen(Constants.SCREEN_MANAGEMENT)
	return true
	return false

func _map_editor_auto_connect_current_candidate() -> void:
	if not map_editor_active:
		_open_map_editor()
		return
	var candidate = _map_editor_gap_path_candidate_for_selected()
	if not candidate.is_empty():
		if _map_editor_connect_selected_to(str(candidate.get("other_instance", ""))):
			return
	var direct_pairs = _map_editor_direct_socket_pairs_for_selected()
	if not direct_pairs.is_empty():
		var target_id = _map_editor_ref_instance(str(direct_pairs[0].get("to", "")))
		if _map_editor_connect_selected_to(target_id):
			return
	map_editor_status = "자동 연결할 후보가 없습니다. 맵에서 다른 방을 클릭하세요."
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _start_map_editor_path_drag(point: Vector2) -> bool:
	if not map_editor_active:
		return false
	var source_id = _room_at(point)
	if source_id == "":
		return false
	facility_change_panel_open = false
	map_editor_path_drag_active = true
	map_editor_path_drag_source = source_id
	map_editor_path_drag_target = source_id
	map_editor_path_drag_position = point
	map_editor_path_drag_start_position = point
	selected_room = source_id
	map_editor_path_candidate_index = 0
	map_editor_status = "시작: %s. 다른 방까지 드래그하세요." % display_name_for_instance(source_id)
	SignalBus.room_selected.emit(source_id)
	_tutorial_emit_action("room_selected", {"room_id": source_id})
	queue_redraw()
	return true

func _update_map_editor_path_drag(point: Vector2) -> void:
	if not map_editor_path_drag_active:
		return
	map_editor_path_drag_position = point
	map_editor_path_drag_target = _room_at(point)
	queue_redraw()

func _finish_map_editor_path_drag(point: Vector2) -> void:
	if not map_editor_path_drag_active:
		return
	var source_id = map_editor_path_drag_source
	var target_id = _room_at(point)
	var drag_distance = point.distance_to(map_editor_path_drag_start_position)
	_clear_map_editor_path_drag()
	if source_id == "":
		return
	selected_room = source_id
	if drag_distance < 10.0:
		map_editor_status = "시작 방: %s. 다른 방까지 드래그하면 연결하거나 끊습니다." % display_name_for_instance(source_id)
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	if target_id == "":
		map_editor_status = "방 위에서 놓아야 길을 연결할 수 있습니다."
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	if target_id == source_id:
		map_editor_status = "다른 방까지 드래그해야 길을 연결합니다."
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	if _map_editor_can_disconnect_instances(source_id, target_id):
		_map_editor_disconnect_between_instances(source_id, target_id)
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	if _map_editor_ref_instances_connected(source_id, target_id):
		map_editor_status = "%s와 %s는 이미 다른 길로 이어져 있습니다." % [
			display_name_for_instance(source_id),
			display_name_for_instance(target_id)
		]
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	if not _map_editor_connect_selected_to(target_id):
		selected_room = source_id
		_set_screen(Constants.SCREEN_MANAGEMENT)

func _map_editor_drag_state(source_id: String, target_id: String) -> String:
	if not map_editor_active or source_id == "":
		return "idle"
	if target_id == "":
		return "aim"
	if target_id == source_id:
		return "same"
	if _map_editor_can_disconnect_instances(source_id, target_id):
		return "disconnect"
	if _map_editor_ref_instances_connected(source_id, target_id):
		return "indirect"
	if _map_editor_can_connect_instances(source_id, target_id):
		return "connect"
	return "blocked"

func _map_editor_drag_state_label(source_id: String, target_id: String) -> String:
	var state = _map_editor_drag_state(source_id, target_id)
	match state:
		"connect":
			return "놓으면 연결"
		"disconnect":
			return "놓으면 끊기"
		"blocked":
			return "연결 불가"
		"indirect":
			return "이미 연결됨"
		"same":
			return "다른 방으로"
		_:
			return "방에 놓기"

func _map_editor_drag_state_color(source_id: String, target_id: String) -> Color:
	var state = _map_editor_drag_state(source_id, target_id)
	match state:
		"connect":
			return Color("#7bdcfff2")
		"disconnect":
			return Color("#ffb15df2")
		"blocked":
			return Color("#ff5d6cf2")
		"indirect":
			return Color("#bfb7ccf2")
		"same":
			return Color("#ffd36af2")
		_:
			return Color("#f7efe1d8")

func _map_editor_can_connect_instances(source_id: String, target_id: String) -> bool:
	if source_id == "" or target_id == "" or source_id == target_id:
		return false
	if _layout_count_adjacent_sockets_between_instances(map_editor_layout, source_id, target_id) > 0:
		return true
	return not _map_editor_best_gap_path_candidate_between(source_id, target_id).is_empty()

func _map_editor_can_disconnect_instances(source_id: String, target_id: String) -> bool:
	if source_id == "" or target_id == "" or source_id == target_id:
		return false
	if _layout_count_connections_between_instances(map_editor_layout, source_id, target_id) > 0:
		return true
	return _map_editor_dedicated_path_between_instances(source_id, target_id) != ""

func _map_editor_best_gap_path_candidate_between(source_id: String, target_id: String) -> Dictionary:
	var source_sockets = _map_editor_socket_records(source_id)
	var target_sockets = _map_editor_socket_records(target_id)
	var best: Dictionary = {}
	var best_score := INF
	for source_socket in source_sockets:
		if _map_editor_ref_has_connection(str(source_socket.get("ref", ""))):
			continue
		for target_socket in target_sockets:
			if _map_editor_ref_has_connection(str(target_socket.get("ref", ""))):
				continue
			for candidate in _gap_corridor_candidates_from_socket_pair(map_editor_layout, source_socket, target_socket):
				var score = _cell_distance_sq(source_socket.get("cell", Vector2i.ZERO), target_socket.get("cell", Vector2i.ZERO))
				if best.is_empty() or score < best_score:
					best = candidate
					best_score = score
	return best

func _map_editor_disconnect_between_instances(source_id: String, target_id: String) -> bool:
	if source_id == "" or target_id == "" or source_id == target_id:
		return false
	var candidate_layout = map_editor_layout.duplicate(true)
	var removed_direct = _layout_remove_connections_between_instances(candidate_layout, source_id, target_id)
	if removed_direct > 0:
		map_editor_layout = candidate_layout
		selected_room = source_id
		map_editor_path_candidate_index = 0
		_rebuild_map_editor_preview("드래그 연결 해제")
		map_editor_status = "%s - %s 연결을 끊었습니다." % [
			display_name_for_instance(source_id),
			display_name_for_instance(target_id)
		]
		_log("%s - %s 연결 해제." % [display_name_for_instance(source_id), display_name_for_instance(target_id)])
		return true

	var path_id = _map_editor_dedicated_path_between_instances(source_id, target_id)
	if path_id == "":
		map_editor_status = "%s와 %s 사이에 끊을 직접 연결이 없습니다." % [
			display_name_for_instance(source_id),
			display_name_for_instance(target_id)
		]
		return false
	var placed = _map_editor_placed_entry(path_id)
	if placed.is_empty() or not _map_editor_entry_is_path(placed):
		map_editor_status = "선택한 연결은 통로 모듈로 끊을 수 없습니다."
		return false
	candidate_layout = map_editor_layout.duplicate(true)
	_layout_remove_path_instance(candidate_layout, path_id)
	if bool(placed.get("system_required", false)) and not _layout_has_instance_path(candidate_layout, REQUIRED_MAIN_ROUTE_FROM, REQUIRED_MAIN_ROUTE_TO):
		map_editor_status = "필수 통로는 대체 경로가 있을 때만 끊을 수 있습니다."
		return false
	map_editor_layout = candidate_layout
	selected_room = source_id
	map_editor_path_candidate_index = 0
	_rebuild_map_editor_preview("드래그 통로 삭제")
	map_editor_status = "%s - %s 사이 통로를 삭제했습니다." % [
		display_name_for_instance(source_id),
		display_name_for_instance(target_id)
	]
	_log("%s - %s 통로 삭제." % [display_name_for_instance(source_id), display_name_for_instance(target_id)])
	return true

func _map_editor_single_path_between_instances(source_id: String, target_id: String) -> String:
	var route_graph = ModuleGraphScript.new()
	route_graph.setup_quarter(DataRegistry.quarter_modules, map_editor_layout, rooms)
	var route: Array = route_graph.path_between(source_id, target_id)
	if route.size() != 3:
		return ""
	var path_id = str(route[1])
	var placed = _map_editor_placed_entry(path_id)
	if placed.is_empty() or not _map_editor_entry_is_path(placed):
		return ""
	return path_id

func _map_editor_dedicated_path_between_instances(source_id: String, target_id: String) -> String:
	var path_id = _map_editor_single_path_between_instances(source_id, target_id)
	if path_id == "":
		return ""
	var placed = _map_editor_placed_entry(path_id)
	if placed.is_empty():
		return ""
	var instance_id = str(placed.get("instance_id", ""))
	var grid_id = str(placed.get("grid_id", ""))
	if bool(placed.get("user_authored", false)) or bool(placed.get("system_required", false)):
		return path_id
	if instance_id.begins_with(USER_AUTHORED_PATH_PREFIX) or instance_id.begins_with(SYSTEM_REQUIRED_PATH_PREFIX):
		return path_id
	if grid_id == USER_AUTHORED_PATH_GRID_ID or grid_id == SYSTEM_REQUIRED_PATH_GRID_ID:
		return path_id
	if bool(placed.get("locked", false)):
		return ""
	return path_id

func _map_editor_connect_selected_to(target_instance_id: String) -> bool:
	if not map_editor_active:
		return false
	if target_instance_id == "" or target_instance_id == selected_room:
		return false
	var source_id = selected_room
	if source_id == "":
		map_editor_status = "먼저 시작 방을 선택하세요."
		return false
	if _map_editor_ref_instances_connected(source_id, target_instance_id):
		map_editor_status = "%s와 %s는 이미 이어져 있습니다." % [
			display_name_for_instance(source_id),
			display_name_for_instance(target_instance_id)
		]
		return false

	map_editor_path_candidate_index = 0
	var direct_added = _layout_connect_adjacent_sockets_between_instances(map_editor_layout, source_id, target_instance_id, false)
	if direct_added > 0:
		_finish_map_editor_auto_connection(source_id, target_instance_id, "직접 연결", direct_added)
		return true

	var candidate = _map_editor_best_gap_path_candidate_to(target_instance_id)
	if candidate.is_empty():
		map_editor_status = "%s에서 %s까지 바로 이을 수 없습니다. 더 가까운 방을 선택하세요." % [
			display_name_for_instance(source_id),
			display_name_for_instance(target_instance_id)
		]
		return false

	var path_id = _layout_next_user_path_id(map_editor_layout)
	var origin: Vector2i = candidate.get("origin", Vector2i.ZERO)
	var placed_modules: Array = map_editor_layout.get("placed_modules", []).duplicate(true)
	placed_modules.append({
		"instance_id": path_id,
		"module_id": str(candidate.get("module_id", "")),
		"grid_id": USER_AUTHORED_PATH_GRID_ID,
		"grid_origin": [origin.x, origin.y],
		"locked": false,
		"legacy_room_id": path_id,
		"user_authored": true
	})
	map_editor_layout["placed_modules"] = placed_modules
	var added := 0
	added += _layout_connect_adjacent_sockets_between_instances(map_editor_layout, source_id, path_id, false)
	added += _layout_connect_adjacent_sockets_between_instances(map_editor_layout, path_id, target_instance_id, false)
	_finish_map_editor_auto_connection(source_id, target_instance_id, "통로 자동 생성", added)
	return true

func _map_editor_best_gap_path_candidate_to(target_instance_id: String) -> Dictionary:
	var candidates = _map_editor_gap_path_candidates_for_selected()
	var best: Dictionary = {}
	var best_score := INF
	for candidate in candidates:
		if str(candidate.get("other_instance", "")) != target_instance_id:
			continue
		var score := float(candidate.get("score", 0.0))
		if best.is_empty() or score < best_score:
			best = candidate
			best_score = score
	return best

func _finish_map_editor_auto_connection(source_id: String, target_instance_id: String, action_label: String, added_connections: int) -> void:
	selected_room = target_instance_id
	map_editor_path_candidate_index = 0
	_rebuild_map_editor_preview(action_label)
	if added_connections <= 0:
		map_editor_status = "%s와 %s 사이에 통로 후보를 만들었지만 연결을 확인해야 합니다." % [
			display_name_for_instance(source_id),
			display_name_for_instance(target_instance_id)
		]
	elif map_editor_errors.is_empty():
		map_editor_status = "%s -> %s 연결 완료. 이어서 다음 방을 클릭하거나 저장하세요." % [
			display_name_for_instance(source_id),
			display_name_for_instance(target_instance_id)
		]
	else:
		map_editor_status = "%s -> %s 연결됨. 저장 전 표시된 오류를 확인하세요." % [
			display_name_for_instance(source_id),
			display_name_for_instance(target_instance_id)
		]
	SignalBus.room_selected.emit(target_instance_id)
	_tutorial_emit_action("room_selected", {"room_id": target_instance_id})
	_log("%s -> %s %s." % [display_name_for_instance(source_id), display_name_for_instance(target_instance_id), action_label])
	_set_screen(Constants.SCREEN_MANAGEMENT)
	queue_redraw()

func _map_editor_ref_instances_connected(first_id: String, second_id: String) -> bool:
	if _layout_count_connections_between_instances(map_editor_layout, first_id, second_id) > 0:
		return true
	return _map_editor_dedicated_path_between_instances(first_id, second_id) != ""

func _map_editor_place_gap_path() -> void:
	if not map_editor_active:
		_open_map_editor()
		return
	var candidate = _map_editor_gap_path_candidate_for_selected()
	if candidate.is_empty():
		map_editor_status = "배치 가능한 2칸 통로 후보가 없습니다."
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	var path_id = _layout_next_user_path_id(map_editor_layout)
	var origin: Vector2i = candidate.get("origin", Vector2i.ZERO)
	var placed_modules: Array = map_editor_layout.get("placed_modules", []).duplicate(true)
	placed_modules.append({
		"instance_id": path_id,
		"module_id": str(candidate.get("module_id", "")),
		"grid_id": USER_AUTHORED_PATH_GRID_ID,
		"grid_origin": [origin.x, origin.y],
		"locked": false,
		"legacy_room_id": path_id,
		"user_authored": true
	})
	map_editor_layout["placed_modules"] = placed_modules
	selected_room = path_id
	map_editor_path_candidate_index = 0
	_rebuild_map_editor_preview("통로 배치")
	if map_editor_errors.is_empty():
		map_editor_status = "통로를 배치했습니다. 인접 연결로 방과 이어주세요."
	_log("수동 통로 %s 배치: %s -> %s." % [path_id, str(candidate.get("source_instance", "")), str(candidate.get("other_instance", ""))])
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _map_editor_delete_selected_path() -> void:
	if not map_editor_active:
		_open_map_editor()
		return
	var placed = _map_editor_placed_entry(selected_room)
	if placed.is_empty() or not _map_editor_entry_is_path(placed):
		map_editor_status = "선택한 항목은 삭제 가능한 통로가 아닙니다."
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	var candidate_layout = map_editor_layout.duplicate(true)
	_layout_remove_path_instance(candidate_layout, selected_room)
	if bool(placed.get("system_required", false)) and not _layout_has_instance_path(candidate_layout, REQUIRED_MAIN_ROUTE_FROM, REQUIRED_MAIN_ROUTE_TO):
		map_editor_status = "필수 통로는 대체 경로가 있을 때만 삭제할 수 있습니다."
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	var deleted_id = selected_room
	map_editor_layout = candidate_layout
	selected_room = REQUIRED_MAIN_ROUTE_FROM if _layout_has_instance(map_editor_layout, REQUIRED_MAIN_ROUTE_FROM) else ""
	map_editor_path_candidate_index = 0
	_rebuild_map_editor_preview("통로 삭제")
	_log("통로 %s 삭제." % deleted_id)
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _save_map_editor_layout(persist: bool = true) -> bool:
	if not map_editor_active:
		return false
	var repair_result = _repair_required_main_route(map_editor_layout)
	if not bool(repair_result.get("ok", false)):
		map_editor_status = "필수 경로 복구 실패: %s" % str(repair_result.get("error", "unknown"))
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return false
	if bool(repair_result.get("changed", false)):
		map_editor_layout = repair_result.get("layout", map_editor_layout).duplicate(true)
		var created_count = int(repair_result.get("created_paths", 0))
		var connected_count = int(repair_result.get("connections_added", 0))
		_log("입구-왕좌 필수 경로를 복구했습니다. 길 %d개, 연결 %d개." % [created_count, connected_count])
	_rebuild_map_editor_preview("필수 경로 복구" if bool(repair_result.get("changed", false)) else "저장 검증")
	if not map_editor_errors.is_empty():
		map_editor_status = "오류가 있어 저장할 수 없습니다."
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return false
	var layout_id = DataRegistry.next_quarter_custom_layout_id("map_custom")
	var saved_layout = map_editor_layout.duplicate(true)
	saved_layout["template_id"] = layout_id
	saved_layout["display_name"] = "사용자 편집 맵 %s" % layout_id.get_slice("_", 2)
	if not DataRegistry.register_quarter_layout(layout_id, saved_layout, persist):
		map_editor_status = "맵 저장에 실패했습니다."
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return false
	map_editor_active = false
	_clear_map_editor_path_drag()
	map_editor_layout.clear()
	map_editor_errors.clear()
	quarter_layout_id = layout_id
	_setup_dungeon_graph()
	if quarter_renderer != null and quarter_renderer.has_method("refresh_layout"):
		quarter_renderer.refresh_layout()
	_log("맵 레이아웃을 %s로 저장했습니다." % quarter_layout_display_name(layout_id))
	_set_screen(Constants.SCREEN_MANAGEMENT)
	return true

func _map_editor_selected_origin_label() -> String:
	var origin = _map_editor_selected_origin()
	if origin == Vector2i(-9999, -9999):
		return "-"
	return "%d,%d" % [origin.x, origin.y]

func _map_editor_selected_locked() -> bool:
	var placed = _map_editor_placed_entry(selected_room)
	return bool(placed.get("locked", false)) if not placed.is_empty() else true

func _map_editor_status_line() -> String:
	if not map_editor_active:
		return "대기"
	if map_editor_errors.is_empty():
		return map_editor_status if map_editor_status != "" else "유효"
	return _player_map_error(str(map_editor_errors[0]))

func _player_map_error(error: String) -> String:
	var text = error.strip_edges()
	var required_prefix = "required path missing "
	if text.begins_with(required_prefix):
		return "필수 경로가 끊겼습니다: %s" % _player_error_route(text.substr(required_prefix.length()))
	var required_walk_prefix = "required walk path missing "
	if text.begins_with(required_walk_prefix):
		return "이동 가능한 길이 끊겼습니다: %s" % _player_error_route(text.substr(required_walk_prefix.length()))
	if text.begins_with("connected sockets are not adjacent"):
		return "연결된 문이 서로 맞닿아 있지 않습니다."
	if text.begins_with("socket side does not face target"):
		return "문 방향이 연결 대상과 맞지 않습니다."
	if text.begins_with("socket side mismatch"):
		return "마주 보는 문끼리만 연결할 수 있습니다."
	if text.begins_with("socket width mismatch"):
		return "문 크기가 맞는 곳끼리만 연결할 수 있습니다."
	if text.begins_with("socket type/tag mismatch"):
		return "방과 통로에 맞는 문끼리만 연결할 수 있습니다."
	if text.begins_with("invalid socket connection reference") or text.begins_with("connection references missing"):
		return "없는 방이나 문을 가리키는 연결이 있습니다."
	return "맵 연결 오류: %s" % text

func _player_error_route(route_text: String) -> String:
	var parts = route_text.split(" -> ")
	if parts.size() != 2:
		return route_text
	return "%s -> %s" % [
		display_name_for_instance(str(parts[0])),
		display_name_for_instance(str(parts[1]))
	]

func _map_editor_path_candidate_line() -> String:
	if not map_editor_active:
		return ""
	var candidates = _map_editor_gap_path_candidates_for_selected()
	if candidates.is_empty():
		return "통로 후보 없음"
	var index = _map_editor_clamped_path_candidate_index(candidates.size())
	var candidate: Dictionary = candidates[index]
	var origin: Vector2i = candidate.get("origin", Vector2i.ZERO)
	return "%d/%d: %s -> %s, 위치 %d,%d" % [
		index + 1,
		candidates.size(),
		display_name_for_instance(str(candidate.get("source_instance", ""))),
		display_name_for_instance(str(candidate.get("other_instance", ""))),
		origin.x,
		origin.y
	]

func _rebuild_map_editor_preview(action_label: String) -> void:
	_setup_dungeon_graph()
	var validation = graph.validation_summary() if graph != null and graph.has_method("validation_summary") else {"ok": false, "errors": ["graph unavailable"]}
	map_editor_errors = validation.get("errors", []).duplicate(true)
	map_editor_status = "%s: 유효" % action_label if map_editor_errors.is_empty() else "%s: 오류 %d개" % [action_label, map_editor_errors.size()]
	if quarter_renderer != null and quarter_renderer.has_method("refresh_layout"):
		quarter_renderer.refresh_layout()
	queue_redraw()

func _map_editor_selected_origin() -> Vector2i:
	var placed = _map_editor_placed_entry(selected_room)
	var origin_value: Array = placed.get("grid_origin", []) if not placed.is_empty() else []
	if origin_value.size() < 2:
		return Vector2i(-9999, -9999)
	return Vector2i(int(origin_value[0]), int(origin_value[1]))

func _map_editor_placed_entry(instance_id: String) -> Dictionary:
	var source_layout = map_editor_layout if map_editor_active and not map_editor_layout.is_empty() else _quarter_layout_for_graph()
	for placed in source_layout.get("placed_modules", []):
		if placed is Dictionary and str(placed.get("instance_id", "")) == instance_id:
			return placed
	return {}

func _map_editor_first_adjacent_socket_pair() -> Dictionary:
	var pairs = _map_editor_direct_socket_pairs_for_selected()
	if pairs.is_empty():
		return {}
	return pairs[0]

func _map_editor_direct_socket_pairs_for_selected() -> Array:
	var selected_sockets = _map_editor_socket_records(selected_room)
	var all_sockets = _map_editor_socket_records("")
	var pairs: Array = []
	for selected_socket in selected_sockets:
		var from_ref = str(selected_socket.get("ref", ""))
		if _map_editor_ref_has_connection(from_ref):
			continue
		for other_socket in all_sockets:
			if str(other_socket.get("instance_id", "")) == selected_room:
				continue
			var to_ref = str(other_socket.get("ref", ""))
			if _map_editor_ref_has_connection(to_ref):
				continue
			var side = AutoTileMaskScript.side_between(selected_socket.get("cell", Vector2i.ZERO), other_socket.get("cell", Vector2i.ZERO))
			if side == "":
				continue
			if side != str(selected_socket.get("side", "")):
				continue
			if AutoTileMaskScript.opposite_side(side) != str(other_socket.get("side", "")):
				continue
			pairs.append({"from": from_ref, "to": to_ref})
	return pairs

func _map_editor_gap_path_candidate_for_selected() -> Dictionary:
	var candidates = _map_editor_gap_path_candidates_for_selected()
	if candidates.is_empty():
		map_editor_path_candidate_index = 0
		return {}
	return candidates[_map_editor_clamped_path_candidate_index(candidates.size())]

func _map_editor_gap_path_candidates_for_selected() -> Array:
	var selected_sockets = _map_editor_socket_records(selected_room)
	var all_sockets = _map_editor_socket_records("")
	var candidates: Array = []
	var seen_candidates: Dictionary = {}
	for selected_socket in selected_sockets:
		if _map_editor_ref_has_connection(str(selected_socket.get("ref", ""))):
			continue
		for other_socket in all_sockets:
			var other_id = str(other_socket.get("instance_id", ""))
			if other_id == selected_room:
				continue
			if other_id.begins_with(USER_AUTHORED_PATH_PREFIX) or other_id.begins_with(SYSTEM_REQUIRED_PATH_PREFIX):
				continue
			if _map_editor_ref_has_connection(str(other_socket.get("ref", ""))):
				continue
			for candidate in _gap_corridor_candidates_from_socket_pair(map_editor_layout, selected_socket, other_socket):
				var score = _cell_distance_sq(selected_socket.get("cell", Vector2i.ZERO), other_socket.get("cell", Vector2i.ZERO)) \
					+ _cell_distance_sq(_layout_instance_center_cell(map_editor_layout, other_id), _layout_instance_center_cell(map_editor_layout, selected_room))
				var origin: Vector2i = candidate.get("origin", Vector2i.ZERO)
				var candidate_key = "%s|%s|%d,%d" % [other_id, str(candidate.get("module_id", "")), origin.x, origin.y]
				if seen_candidates.has(candidate_key):
					continue
				seen_candidates[candidate_key] = true
				candidate["score"] = score
				candidate["source_socket"] = str(selected_socket.get("ref", ""))
				candidate["other_socket"] = str(other_socket.get("ref", ""))
				candidates.append(candidate)
	candidates.sort_custom(Callable(self, "_map_editor_gap_path_candidate_less"))
	if candidates.is_empty():
		map_editor_path_candidate_index = 0
	elif map_editor_path_candidate_index >= candidates.size():
		map_editor_path_candidate_index = 0
	return candidates

func _map_editor_gap_path_candidate_less(first: Dictionary, second: Dictionary) -> bool:
	var first_score := float(first.get("score", 0.0))
	var second_score := float(second.get("score", 0.0))
	if not is_equal_approx(first_score, second_score):
		return first_score < second_score
	var first_target = str(first.get("other_instance", ""))
	var second_target = str(second.get("other_instance", ""))
	if first_target != second_target:
		return first_target < second_target
	var first_origin: Vector2i = first.get("origin", Vector2i.ZERO)
	var second_origin: Vector2i = second.get("origin", Vector2i.ZERO)
	if first_origin.y != second_origin.y:
		return first_origin.y < second_origin.y
	return first_origin.x < second_origin.x

func _map_editor_clamped_path_candidate_index(candidate_count: int) -> int:
	if candidate_count <= 0:
		map_editor_path_candidate_index = 0
		return 0
	if map_editor_path_candidate_index < 0 or map_editor_path_candidate_index >= candidate_count:
		map_editor_path_candidate_index = 0
	return map_editor_path_candidate_index

func _map_editor_preview_gap_path_candidate() -> Dictionary:
	if not map_editor_active:
		return {}
	return _map_editor_gap_path_candidate_for_selected()

func _map_editor_preview_gap_path_socket_markers() -> Array:
	if not map_editor_active:
		return []
	var candidate = _map_editor_preview_gap_path_candidate()
	if candidate.is_empty():
		return []
	var markers: Array = []
	var refs = [
		{"key": "source_socket", "role": "source"},
		{"key": "other_socket", "role": "target"}
	]
	for entry in refs:
		var socket = _map_editor_socket_record_for_ref(str(candidate.get(str(entry["key"]), "")))
		if socket.is_empty():
			continue
		var marker = socket.duplicate(true)
		marker["role"] = str(entry["role"])
		markers.append(marker)
	return markers

func _map_editor_socket_visibility_markers() -> Array:
	if not map_editor_active:
		return []
	var connectable_refs: Dictionary = {}
	for direct_pair in _map_editor_direct_socket_pairs_for_selected():
		connectable_refs[str(direct_pair.get("from", ""))] = true
		connectable_refs[str(direct_pair.get("to", ""))] = true
	for candidate in _map_editor_gap_path_candidates_for_selected():
		connectable_refs[str(candidate.get("source_socket", ""))] = true
		connectable_refs[str(candidate.get("other_socket", ""))] = true

	var markers: Array = []
	for socket in _map_editor_socket_records(""):
		var ref = str(socket.get("ref", ""))
		var instance_id = str(socket.get("instance_id", ""))
		var state := ""
		if _map_editor_ref_has_connection(ref):
			if instance_id != selected_room:
				continue
			state = "connected"
		elif connectable_refs.has(ref):
			state = "connectable"
		elif instance_id == selected_room:
			state = "blocked"
		else:
			continue
		var marker = socket.duplicate(true)
		marker["state"] = state
		markers.append(marker)
	return markers

func _map_editor_socket_records(instance_filter: String) -> Array:
	var source_layout = map_editor_layout if map_editor_active and not map_editor_layout.is_empty() else _quarter_layout_for_graph()
	return _layout_socket_records(source_layout, instance_filter)

func _map_editor_socket_record_for_ref(reference: String) -> Dictionary:
	if reference == "":
		return {}
	for socket in _map_editor_socket_records(""):
		if str(socket.get("ref", "")) == reference:
			return socket
	return {}

func _layout_socket_records(source_layout: Dictionary, instance_filter: String = "") -> Array:
	var records: Array = []
	for placed in source_layout.get("placed_modules", []):
		if not (placed is Dictionary):
			continue
		var instance_id = str(placed.get("instance_id", ""))
		if instance_filter != "" and instance_id != instance_filter:
			continue
		var module_id = str(placed.get("module_id", ""))
		var module: Dictionary = DataRegistry.quarter_module(module_id)
		var origin = IsoMathScript.array_to_cell(placed.get("grid_origin", []))
		for socket in module.get("sockets", []):
			var socket_id = str(socket.get("id", ""))
			var local_cell = IsoMathScript.array_to_cell(socket.get("cell", socket.get("local_cell", [0, 0])))
			var ref = "%s:%s" % [instance_id, socket_id]
			records.append({
				"ref": ref,
				"instance_id": instance_id,
				"socket_id": socket_id,
				"side": str(socket.get("side", "")),
				"cell": origin + local_cell
			})
	return records

func _map_editor_ref_has_connection(reference: String) -> bool:
	return _layout_ref_has_connection(map_editor_layout, reference)

func _layout_ref_has_connection(source_layout: Dictionary, reference: String) -> bool:
	for connection in source_layout.get("connections", []):
		if str(connection.get("from", "")) == reference or str(connection.get("to", "")) == reference:
			return true
	return false

func _map_editor_ref_instance(reference: String) -> String:
	var parts = reference.split(":")
	if parts.size() < 2:
		return ""
	return str(parts[0])

func _map_editor_socket_id_from_ref(reference: String) -> String:
	var parts = reference.split(":")
	if parts.size() < 2:
		return "-"
	return str(parts[1])

func _ensure_required_main_route_for_current_layout(action_label: String) -> bool:
	if not use_quarter_module_map:
		return true
	var source_layout = DataRegistry.quarter_layout(quarter_layout_id)
	if source_layout.is_empty():
		return true
	var repair_result = _repair_required_main_route(source_layout)
	if not bool(repair_result.get("ok", false)):
		_log("%s 실패: 입구-왕좌 필수 경로를 복구할 수 없습니다. %s" % [action_label, str(repair_result.get("error", ""))])
		return false
	if not bool(repair_result.get("changed", false)):
		return true
	var repaired_layout: Dictionary = repair_result.get("layout", source_layout).duplicate(true)
	DataRegistry.register_quarter_layout(quarter_layout_id, repaired_layout, false)
	_setup_dungeon_graph()
	if quarter_renderer != null and quarter_renderer.has_method("refresh_layout"):
		quarter_renderer.refresh_layout()
	queue_redraw()
	_log("%s 전 입구-왕좌 필수 경로를 복구했습니다. 길 %d개, 연결 %d개." % [
		action_label,
		int(repair_result.get("created_paths", 0)),
		int(repair_result.get("connections_added", 0))
	])
	return true

func _repair_required_main_route(source_layout: Dictionary) -> Dictionary:
	var work: Dictionary = source_layout.duplicate(true)
	if _layout_has_instance_path(work, REQUIRED_MAIN_ROUTE_FROM, REQUIRED_MAIN_ROUTE_TO):
		return {"ok": true, "changed": false, "layout": work, "created_paths": 0, "connections_added": 0}
	if not _layout_has_instance(work, REQUIRED_MAIN_ROUTE_FROM):
		return {"ok": false, "changed": false, "layout": work, "error": "missing %s" % REQUIRED_MAIN_ROUTE_FROM}
	if not _layout_has_instance(work, REQUIRED_MAIN_ROUTE_TO):
		return {"ok": false, "changed": false, "layout": work, "error": "missing %s" % REQUIRED_MAIN_ROUTE_TO}

	var changed := false
	var created_paths := 0
	var connections_added := 0
	for _step in range(REQUIRED_ROUTE_REPAIR_MAX_STEPS):
		if _layout_has_instance_path(work, REQUIRED_MAIN_ROUTE_FROM, REQUIRED_MAIN_ROUTE_TO):
			return {
				"ok": true,
				"changed": changed,
				"layout": work,
				"created_paths": created_paths,
				"connections_added": connections_added
			}
		var source_component = _layout_component(work, REQUIRED_MAIN_ROUTE_FROM)
		if source_component.has(REQUIRED_MAIN_ROUTE_TO):
			return {
				"ok": true,
				"changed": changed,
				"layout": work,
				"created_paths": created_paths,
				"connections_added": connections_added
			}

		var bridge = _layout_closest_adjacent_instance_bridge(work, source_component, REQUIRED_MAIN_ROUTE_TO)
		if not bridge.is_empty():
			var bridge_added = _layout_connect_adjacent_sockets_between_instances(work, str(bridge.get("source_instance", "")), str(bridge.get("other_instance", "")), true)
			if bridge_added > 0:
				changed = true
				connections_added += bridge_added
				continue

		var inserted = _layout_insert_closest_gap_corridor(work, source_component, REQUIRED_MAIN_ROUTE_TO)
		if not inserted.is_empty():
			changed = true
			created_paths += 1
			connections_added += int(inserted.get("connections_added", 0))
			continue

		return {"ok": false, "changed": changed, "layout": work, "error": "no connectable socket or 2x2 gap candidate"}

	return {"ok": false, "changed": changed, "layout": work, "error": "repair step limit exceeded"}

func _layout_has_instance_path(source_layout: Dictionary, from_id: String, to_id: String) -> bool:
	var route_graph = ModuleGraphScript.new()
	route_graph.setup_quarter(DataRegistry.quarter_modules, source_layout, rooms)
	return not route_graph.path_between(from_id, to_id).is_empty()

func _layout_has_instance(source_layout: Dictionary, instance_id: String) -> bool:
	return not _layout_placed_entry(source_layout, instance_id).is_empty()

func _layout_placed_entry(source_layout: Dictionary, instance_id: String) -> Dictionary:
	for placed in source_layout.get("placed_modules", []):
		if placed is Dictionary and str(placed.get("instance_id", "")) == instance_id:
			return placed
	return {}

func _map_editor_entry_is_path(placed: Dictionary) -> bool:
	var instance_id = str(placed.get("instance_id", ""))
	var grid_id = str(placed.get("grid_id", ""))
	var module_id = str(placed.get("module_id", ""))
	return instance_id.begins_with(USER_AUTHORED_PATH_PREFIX) \
		or instance_id.begins_with(SYSTEM_REQUIRED_PATH_PREFIX) \
		or grid_id == USER_AUTHORED_PATH_GRID_ID \
		or grid_id == SYSTEM_REQUIRED_PATH_GRID_ID \
		or module_id.begins_with("corridor_gap_")

func _layout_remove_path_instance(source_layout: Dictionary, instance_id: String) -> void:
	var placed_modules: Array = []
	for placed in source_layout.get("placed_modules", []):
		if not (placed is Dictionary):
			continue
		if str(placed.get("instance_id", "")) != instance_id:
			placed_modules.append(placed)
	source_layout["placed_modules"] = placed_modules

	var socket_states: Dictionary = source_layout.get("socket_states", {}).duplicate(true)
	var kept_connections: Array = []
	for connection in source_layout.get("connections", []):
		var from_ref = str(connection.get("from", ""))
		var to_ref = str(connection.get("to", ""))
		if _map_editor_ref_instance(from_ref) == instance_id or _map_editor_ref_instance(to_ref) == instance_id:
			if _map_editor_ref_instance(from_ref) != instance_id:
				socket_states[from_ref] = "open_placeholder"
			else:
				socket_states.erase(from_ref)
			if _map_editor_ref_instance(to_ref) != instance_id:
				socket_states[to_ref] = "open_placeholder"
			else:
				socket_states.erase(to_ref)
		else:
			kept_connections.append(connection)
	source_layout["connections"] = kept_connections
	source_layout["socket_states"] = socket_states

func _layout_instance_ids(source_layout: Dictionary) -> Array:
	var ids: Array = []
	for placed in source_layout.get("placed_modules", []):
		if placed is Dictionary:
			var instance_id = str(placed.get("instance_id", ""))
			if instance_id != "":
				ids.append(instance_id)
	return ids

func _layout_component(source_layout: Dictionary, start_id: String) -> Dictionary:
	var adjacency: Dictionary = {}
	for instance_id in _layout_instance_ids(source_layout):
		adjacency[instance_id] = []
	if not adjacency.has(start_id):
		return {}
	for connection in source_layout.get("connections", []):
		var from_ref = _split_layout_ref(str(connection.get("from", "")))
		var to_ref = _split_layout_ref(str(connection.get("to", "")))
		if from_ref.is_empty() or to_ref.is_empty():
			continue
		var from_id = str(from_ref.get("instance_id", ""))
		var to_id = str(to_ref.get("instance_id", ""))
		if not adjacency.has(from_id) or not adjacency.has(to_id):
			continue
		if not adjacency[from_id].has(to_id):
			adjacency[from_id].append(to_id)
		if not adjacency[to_id].has(from_id):
			adjacency[to_id].append(from_id)
	var visited: Dictionary = {start_id: true}
	var frontier: Array = [start_id]
	while not frontier.is_empty():
		var current = str(frontier.pop_front())
		for next_id in adjacency.get(current, []):
			if visited.has(next_id):
				continue
			visited[next_id] = true
			frontier.append(next_id)
	return visited

func _split_layout_ref(reference: String) -> Dictionary:
	var parts = reference.split(":")
	if parts.size() != 2 or str(parts[0]) == "" or str(parts[1]) == "":
		return {}
	return {"instance_id": str(parts[0]), "socket_id": str(parts[1])}

func _layout_closest_adjacent_instance_bridge(source_layout: Dictionary, source_component: Dictionary, goal_id: String) -> Dictionary:
	var sockets = _layout_socket_records(source_layout)
	var best: Dictionary = {}
	var best_score := INF
	for source_socket in sockets:
		var source_id = str(source_socket.get("instance_id", ""))
		if not source_component.has(source_id):
			continue
		if _layout_ref_has_connection(source_layout, str(source_socket.get("ref", ""))):
			continue
		for other_socket in sockets:
			var other_id = str(other_socket.get("instance_id", ""))
			if other_id == source_id or source_component.has(other_id):
				continue
			if _layout_ref_has_connection(source_layout, str(other_socket.get("ref", ""))):
				continue
			if not _socket_records_can_connect(source_socket, other_socket):
				continue
			var score = _layout_bridge_score(source_layout, source_socket, other_socket, goal_id)
			if score < best_score:
				best_score = score
				best = {
					"source_instance": source_id,
					"other_instance": other_id,
					"score": score
				}
	return best

func _layout_bridge_score(source_layout: Dictionary, source_socket: Dictionary, other_socket: Dictionary, goal_id: String) -> float:
	var other_id = str(other_socket.get("instance_id", ""))
	var goal_component = _layout_component(source_layout, goal_id)
	var goal_component_penalty := 0.0 if goal_component.has(other_id) else 10000.0
	return goal_component_penalty \
		+ _cell_distance_sq(source_socket.get("cell", Vector2i.ZERO), other_socket.get("cell", Vector2i.ZERO)) \
		+ _cell_distance_sq(_layout_instance_center_cell(source_layout, other_id), _layout_instance_center_cell(source_layout, goal_id))

func _layout_connect_adjacent_sockets_between_instances(source_layout: Dictionary, first_id: String, second_id: String, system_required: bool = false) -> int:
	var added := 0
	var first_sockets = _layout_socket_records(source_layout, first_id)
	var second_sockets = _layout_socket_records(source_layout, second_id)
	for first_socket in first_sockets:
		var first_ref = str(first_socket.get("ref", ""))
		if _layout_ref_has_connection(source_layout, first_ref):
			continue
		for second_socket in second_sockets:
			var second_ref = str(second_socket.get("ref", ""))
			if _layout_ref_has_connection(source_layout, second_ref):
				continue
			if not _socket_records_can_connect(first_socket, second_socket):
				continue
			if _layout_add_connection(source_layout, first_ref, second_ref, system_required):
				added += 1
				break
	return added

func _layout_count_adjacent_sockets_between_instances(source_layout: Dictionary, first_id: String, second_id: String) -> int:
	var count := 0
	var first_sockets = _layout_socket_records(source_layout, first_id)
	var second_sockets = _layout_socket_records(source_layout, second_id)
	for first_socket in first_sockets:
		var first_ref = str(first_socket.get("ref", ""))
		if _layout_ref_has_connection(source_layout, first_ref):
			continue
		for second_socket in second_sockets:
			var second_ref = str(second_socket.get("ref", ""))
			if _layout_ref_has_connection(source_layout, second_ref):
				continue
			if _socket_records_can_connect(first_socket, second_socket):
				count += 1
				break
	return count

func _layout_add_connection(source_layout: Dictionary, from_ref: String, to_ref: String, system_required: bool = false) -> bool:
	if from_ref == "" or to_ref == "" or _layout_connection_exists(source_layout, from_ref, to_ref):
		return false
	var connections: Array = source_layout.get("connections", []).duplicate(true)
	var entry = {"from": from_ref, "to": to_ref}
	if system_required:
		entry["system_required"] = true
	connections.append(entry)
	source_layout["connections"] = connections
	var socket_states: Dictionary = source_layout.get("socket_states", {}).duplicate(true)
	socket_states[from_ref] = "connected"
	socket_states[to_ref] = "connected"
	source_layout["socket_states"] = socket_states
	return true

func _layout_remove_connections_between_instances(source_layout: Dictionary, first_id: String, second_id: String) -> int:
	var kept_connections: Array = []
	var socket_states: Dictionary = source_layout.get("socket_states", {}).duplicate(true)
	var removed := 0
	for connection in source_layout.get("connections", []):
		var from_ref = str(connection.get("from", ""))
		var to_ref = str(connection.get("to", ""))
		var from_id = _map_editor_ref_instance(from_ref)
		var to_id = _map_editor_ref_instance(to_ref)
		var matches = (from_id == first_id and to_id == second_id) or (from_id == second_id and to_id == first_id)
		if matches:
			socket_states[from_ref] = "open_placeholder"
			socket_states[to_ref] = "open_placeholder"
			removed += 1
		else:
			kept_connections.append(connection)
	source_layout["connections"] = kept_connections
	source_layout["socket_states"] = socket_states
	return removed

func _layout_count_connections_between_instances(source_layout: Dictionary, first_id: String, second_id: String) -> int:
	var count := 0
	for connection in source_layout.get("connections", []):
		var from_id = _map_editor_ref_instance(str(connection.get("from", "")))
		var to_id = _map_editor_ref_instance(str(connection.get("to", "")))
		if (from_id == first_id and to_id == second_id) or (from_id == second_id and to_id == first_id):
			count += 1
	return count

func _layout_connection_exists(source_layout: Dictionary, from_ref: String, to_ref: String) -> bool:
	for connection in source_layout.get("connections", []):
		var existing_from = str(connection.get("from", ""))
		var existing_to = str(connection.get("to", ""))
		if existing_from == from_ref and existing_to == to_ref:
			return true
		if existing_from == to_ref and existing_to == from_ref:
			return true
	return false

func _socket_records_can_connect(first_socket: Dictionary, second_socket: Dictionary) -> bool:
	var first_cell: Vector2i = first_socket.get("cell", Vector2i.ZERO)
	var second_cell: Vector2i = second_socket.get("cell", Vector2i.ZERO)
	var side = AutoTileMaskScript.side_between(first_cell, second_cell)
	if side == "":
		return false
	if side != str(first_socket.get("side", "")):
		return false
	return AutoTileMaskScript.opposite_side(side) == str(second_socket.get("side", ""))

func _layout_insert_closest_gap_corridor(source_layout: Dictionary, source_component: Dictionary, goal_id: String) -> Dictionary:
	var candidate = _layout_closest_gap_corridor_candidate(source_layout, source_component, goal_id)
	if candidate.is_empty():
		return {}
	var path_id = _layout_next_system_path_id(source_layout)
	var placed_modules: Array = source_layout.get("placed_modules", []).duplicate(true)
	var origin: Vector2i = candidate.get("origin", Vector2i.ZERO)
	placed_modules.append({
		"instance_id": path_id,
		"module_id": str(candidate.get("module_id", "")),
		"grid_id": SYSTEM_REQUIRED_PATH_GRID_ID,
		"grid_origin": [origin.x, origin.y],
		"locked": false,
		"legacy_room_id": path_id,
		"system_required": true
	})
	source_layout["placed_modules"] = placed_modules
	var added := 0
	added += _layout_connect_adjacent_sockets_between_instances(source_layout, str(candidate.get("source_instance", "")), path_id, true)
	added += _layout_connect_adjacent_sockets_between_instances(source_layout, path_id, str(candidate.get("other_instance", "")), true)
	return {
		"instance_id": path_id,
		"connections_added": added
	}

func _layout_closest_gap_corridor_candidate(source_layout: Dictionary, source_component: Dictionary, goal_id: String) -> Dictionary:
	var sockets = _layout_socket_records(source_layout)
	var best: Dictionary = {}
	var best_score := INF
	for source_socket in sockets:
		var source_id = str(source_socket.get("instance_id", ""))
		if not source_component.has(source_id):
			continue
		if _layout_ref_has_connection(source_layout, str(source_socket.get("ref", ""))):
			continue
		for other_socket in sockets:
			var other_id = str(other_socket.get("instance_id", ""))
			if other_id == source_id or source_component.has(other_id):
				continue
			if _layout_ref_has_connection(source_layout, str(other_socket.get("ref", ""))):
				continue
			var candidates = _gap_corridor_candidates_from_socket_pair(source_layout, source_socket, other_socket)
			for candidate in candidates:
				var score = _layout_gap_candidate_score(source_layout, source_socket, other_socket, goal_id)
				if score < best_score:
					best_score = score
					best = candidate
	return best

func _gap_corridor_candidates_from_socket_pair(source_layout: Dictionary, source_socket: Dictionary, other_socket: Dictionary) -> Array:
	var results: Array = []
	var source_cell: Vector2i = source_socket.get("cell", Vector2i.ZERO)
	var other_cell: Vector2i = other_socket.get("cell", Vector2i.ZERO)
	var source_side = str(source_socket.get("side", ""))
	if AutoTileMaskScript.opposite_side(source_side) != str(other_socket.get("side", "")):
		return results
	var delta = other_cell - source_cell
	var module_id := ""
	var origins: Array = []
	match source_side:
		"E":
			if delta != Vector2i(3, 0):
				return results
			module_id = "corridor_gap_ew_2x2_01"
			origins = [Vector2i(source_cell.x + 1, source_cell.y), Vector2i(source_cell.x + 1, source_cell.y - 1)]
		"W":
			if delta != Vector2i(-3, 0):
				return results
			module_id = "corridor_gap_ew_2x2_01"
			origins = [Vector2i(source_cell.x - 2, source_cell.y), Vector2i(source_cell.x - 2, source_cell.y - 1)]
		"S":
			if delta != Vector2i(0, 3):
				return results
			module_id = "corridor_gap_ns_2x2_01"
			origins = [Vector2i(source_cell.x, source_cell.y + 1), Vector2i(source_cell.x - 1, source_cell.y + 1)]
		"N":
			if delta != Vector2i(0, -3):
				return results
			module_id = "corridor_gap_ns_2x2_01"
			origins = [Vector2i(source_cell.x, source_cell.y - 2), Vector2i(source_cell.x - 1, source_cell.y - 2)]
		_:
			return results
	for origin in origins:
		var candidate = {
			"source_instance": str(source_socket.get("instance_id", "")),
			"other_instance": str(other_socket.get("instance_id", "")),
			"module_id": module_id,
			"origin": origin
		}
		if _layout_gap_corridor_candidate_is_valid(source_layout, candidate):
			results.append(candidate)
	return results

func _layout_gap_corridor_candidate_is_valid(source_layout: Dictionary, candidate: Dictionary) -> bool:
	var module_id = str(candidate.get("module_id", ""))
	var origin: Vector2i = candidate.get("origin", Vector2i.ZERO)
	if not _layout_cells_available_for_module(source_layout, module_id, origin):
		return false
	var probe_id = "__required_route_probe_path"
	var probe_layout: Dictionary = source_layout.duplicate(true)
	var placed_modules: Array = probe_layout.get("placed_modules", []).duplicate(true)
	placed_modules.append({
		"instance_id": probe_id,
		"module_id": module_id,
		"grid_origin": [origin.x, origin.y],
		"locked": false,
		"legacy_room_id": probe_id
	})
	probe_layout["placed_modules"] = placed_modules
	var source_count = _layout_count_adjacent_sockets_between_instances(probe_layout, str(candidate.get("source_instance", "")), probe_id)
	var other_count = _layout_count_adjacent_sockets_between_instances(probe_layout, probe_id, str(candidate.get("other_instance", "")))
	return source_count >= 2 and other_count >= 2

func _layout_cells_available_for_module(source_layout: Dictionary, module_id: String, origin: Vector2i) -> bool:
	var module: Dictionary = DataRegistry.quarter_module(module_id)
	if module.is_empty():
		return false
	var occupied = _layout_floor_cell_set(source_layout)
	var active_rect = _layout_active_rect(source_layout)
	var max_grid = _layout_max_grid_size()
	for value in module.get("floor_cells", []):
		if not value is Array:
			continue
		var cell = origin + IsoMathScript.array_to_cell(value)
		if occupied.has(cell):
			return false
		if cell.x < 0 or cell.y < 0 or cell.x >= max_grid.x or cell.y >= max_grid.y:
			return false
		if not active_rect.has_point(cell):
			return false
	return true

func _layout_floor_cell_set(source_layout: Dictionary) -> Dictionary:
	var occupied: Dictionary = {}
	for placed in source_layout.get("placed_modules", []):
		if not placed is Dictionary:
			continue
		var module: Dictionary = DataRegistry.quarter_module(str(placed.get("module_id", "")))
		var origin = IsoMathScript.array_to_cell(placed.get("grid_origin", []))
		for value in module.get("floor_cells", []):
			if value is Array:
				occupied[origin + IsoMathScript.array_to_cell(value)] = true
	return occupied

func _layout_active_rect(source_layout: Dictionary) -> Rect2i:
	var grade = str(source_layout.get("castle_grade", "F"))
	var grades: Dictionary = DataRegistry.quarter_castle_grade_rules.get("grades", {})
	var grade_rule: Dictionary = grades.get(grade, grades.get("F", {}))
	var rect_value: Array = grade_rule.get("active_rect", [0, 0, _layout_max_grid_size().x, _layout_max_grid_size().y])
	if rect_value.size() < 4:
		return Rect2i(Vector2i.ZERO, _layout_max_grid_size())
	return Rect2i(int(rect_value[0]), int(rect_value[1]), int(rect_value[2]), int(rect_value[3]))

func _layout_max_grid_size() -> Vector2i:
	var max_value: Array = DataRegistry.quarter_castle_grade_rules.get("max_grid_size", [28, 26])
	if max_value.size() < 2:
		return Vector2i(28, 26)
	return Vector2i(int(max_value[0]), int(max_value[1]))

func _layout_gap_candidate_score(source_layout: Dictionary, source_socket: Dictionary, other_socket: Dictionary, goal_id: String) -> float:
	var other_id = str(other_socket.get("instance_id", ""))
	var goal_component = _layout_component(source_layout, goal_id)
	var goal_component_penalty := 0.0 if goal_component.has(other_id) else 10000.0
	return goal_component_penalty \
		+ _cell_distance_sq(source_socket.get("cell", Vector2i.ZERO), other_socket.get("cell", Vector2i.ZERO)) \
		+ _cell_distance_sq(_layout_instance_center_cell(source_layout, other_id), _layout_instance_center_cell(source_layout, goal_id))

func _layout_instance_center_cell(source_layout: Dictionary, instance_id: String) -> Vector2:
	var placed = _layout_placed_entry(source_layout, instance_id)
	if placed.is_empty():
		return Vector2.ZERO
	var module: Dictionary = DataRegistry.quarter_module(str(placed.get("module_id", "")))
	var origin = IsoMathScript.array_to_cell(placed.get("grid_origin", []))
	var total := Vector2.ZERO
	var count := 0
	for value in module.get("floor_cells", []):
		if value is Array:
			var cell = origin + IsoMathScript.array_to_cell(value)
			total += Vector2(cell.x, cell.y)
			count += 1
	if count == 0:
		return Vector2(origin.x, origin.y)
	return total / float(count)

func _cell_distance_sq(first, second) -> float:
	var first_point = Vector2(float(first.x), float(first.y))
	var second_point = Vector2(float(second.x), float(second.y))
	return first_point.distance_squared_to(second_point)

func _layout_next_system_path_id(source_layout: Dictionary) -> String:
	var index := 1
	while true:
		var candidate = "%s_%02d" % [SYSTEM_REQUIRED_PATH_PREFIX, index]
		if not _layout_has_instance(source_layout, candidate):
			return candidate
		index += 1
	return "%s_%02d" % [SYSTEM_REQUIRED_PATH_PREFIX, index]

func _layout_next_user_path_id(source_layout: Dictionary) -> String:
	var index := 1
	while true:
		var candidate = "%s_%02d" % [USER_AUTHORED_PATH_PREFIX, index]
		if not _layout_has_instance(source_layout, candidate):
			return candidate
		index += 1
	return "%s_%02d" % [USER_AUTHORED_PATH_PREFIX, index]

func _default_facility_role(room_id: String, room: Dictionary) -> String:
	match room_id:
		"barracks":
			return "barracks"
		"treasure":
			return "treasure"
		"recovery":
			return "recovery"
		"slot_01":
			return "build_slot"
	var room_type = str(room.get("type", ""))
	match room_type:
		"entry":
			return "entry"
		"trap":
			return "trap"
		"corridor":
			return "corridor"
		"core":
			return "core"
	return room_type

func _load_textures() -> void:
	var dungeon_path = "res://assets/sprites/dungeon_gpt2/"
	floor_texture = _load_png(dungeon_path + "gpt2_floor_stone.png")
	wall_texture = _load_png(dungeon_path + "gpt2_floor_rough.png")
	spike_texture = _load_png("res://assets/sprites/tiles/tile_spike_floor_01.png")
	dungeon_art = {
		"asset_sheet": _load_png(dungeon_path + "gpt2_dungeon_asset_sheet.png"),
		"connected_map": _load_png(dungeon_path + "gpt2_dungeon_connected_map.png"),
		"floor_stone": floor_texture,
		"floor_rough": wall_texture,
		"wall_cap": _load_png(dungeon_path + "gpt2_wall_cap_long.png"),
		"wall_face": _load_png(dungeon_path + "gpt2_wall_face_banner.png"),
		"wall_panel": _load_png(dungeon_path + "gpt2_wall_panel_torch.png"),
		"door_arch": _load_png(dungeon_path + "gpt2_door_arch.png"),
		"pillar": _load_png(dungeon_path + "gpt2_pillar.png"),
		"purple_torch": _load_png(dungeon_path + "gpt2_purple_torch.png"),
		"brazier": _load_png(dungeon_path + "gpt2_brazier.png"),
		"rock_border": _load_png(dungeon_path + "gpt2_rock_border_front.png"),
		"rock_columns": _load_png(dungeon_path + "gpt2_rock_columns.png"),
		"fortress_wall": _load_png(dungeon_path + "gpt2_fortress_wall.png")
	}
	props = {
		"res://assets/ui/room_v2/room_v2_entrance.png": _load_png("res://assets/ui/room_v2/room_v2_entrance.png"),
		"res://assets/ui/room_v2/room_v2_spike_corridor.png": _load_png("res://assets/ui/room_v2/room_v2_spike_corridor.png"),
		"res://assets/ui/room_v2/room_v2_center.png": _load_png("res://assets/ui/room_v2/room_v2_center.png"),
		"res://assets/ui/room_v2/room_v2_throne.png": _load_png("res://assets/ui/room_v2/room_v2_throne.png"),
		"res://assets/ui/room_v2/room_v2_barracks.png": _load_png("res://assets/ui/room_v2/room_v2_barracks.png"),
		"res://assets/ui/room_v2/room_v2_treasure.png": _load_png("res://assets/ui/room_v2/room_v2_treasure.png"),
		"res://assets/ui/room_v2/room_v2_recovery.png": _load_png("res://assets/ui/room_v2/room_v2_recovery.png"),
		"res://assets/ui/room_v2/room_v2_build_slot.png": _load_png("res://assets/ui/room_v2/room_v2_build_slot.png"),
		"res://assets/ui/room_v2/room_v2_watch_post.png": _load_png("res://assets/ui/room_v2/room_v2_watch_post.png")
	}
	effect_textures = {
		"fireball": _load_png("res://assets/sprites/effects/fx_fireball_00.png"),
		"slash": _load_png("res://assets/sprites/effects/fx_hit_slash_00.png"),
		"impact": _load_png("res://assets/sprites/effects/fx_fire_impact_00.png"),
		"shield": _load_png("res://assets/sprites/effects/fx_shield_pulse_00.png"),
		"slime_gate_bulwark": _load_png("res://assets/sprites/effects/fx_slime_gate_bulwark_00.png"),
		"slime_rescue_alchemy": _load_png("res://assets/sprites/effects/fx_slime_rescue_alchemy_00.png"),
		"goblin_ambush_captain": _load_png("res://assets/sprites/effects/fx_goblin_ambush_captain_00.png"),
		"goblin_vault_keeper": _load_png("res://assets/sprites/effects/fx_goblin_vault_keeper_00.png"),
		"imp_flame_adept": _load_png("res://assets/sprites/effects/fx_imp_flame_adept_00.png"),
		"imp_ember_shaman": _load_png("res://assets/sprites/effects/fx_imp_ember_shaman_00.png"),
		"guard": _load_png("res://assets/sprites/effects/fx_guard_pulse_00.png"),
		"loot": _load_png("res://assets/sprites/effects/fx_loot_spark_00.png")
	}
	effect_frame_sets = {
		"fireball": _load_effect_frames("fx_fireball"),
		"slash": _load_effect_frames("fx_hit_slash"),
		"impact": _load_effect_frames("fx_fire_impact"),
		"shield": _load_effect_frames("fx_shield_pulse"),
		"slime_gate_bulwark": _load_effect_frames("fx_slime_gate_bulwark"),
		"slime_rescue_alchemy": _load_effect_frames("fx_slime_rescue_alchemy"),
		"goblin_ambush_captain": _load_effect_frames("fx_goblin_ambush_captain"),
		"goblin_vault_keeper": _load_effect_frames("fx_goblin_vault_keeper"),
		"imp_flame_adept": _load_effect_frames("fx_imp_flame_adept"),
		"imp_ember_shaman": _load_effect_frames("fx_imp_ember_shaman"),
		"guard": _load_effect_frames("fx_guard_pulse"),
		"loot": _load_effect_frames("fx_loot_spark")
	}

func _load_png(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var loaded = ResourceLoader.load(path)
		if loaded is Texture2D:
			return loaded
	var image = Image.new()
	var err = image.load(path)
	if err != OK and path.begins_with("res://"):
		err = image.load(ProjectSettings.globalize_path(path))
	if err == OK:
		return ImageTexture.create_from_image(image)
	push_warning("Could not load texture: %s" % path)
	return null

func _load_effect_frames(base_name: String) -> Array:
	var frames: Array = []
	for index in range(8):
		var frame_path = "res://assets/sprites/effects/%s_%02d.png" % [base_name, index]
		if ResourceLoader.exists(frame_path):
			var texture = _load_png(frame_path)
			if texture != null:
				frames.append(texture)
	return frames

func room_icon_path(icon_name: String) -> String:
	if icon_name == "":
		return ""
	if icon_name.begins_with("res://"):
		return icon_name
	if icon_name.begins_with("marker_"):
		return "res://assets/sprites/room_markers/%s" % icon_name
	return "res://assets/sprites/rooms/%s" % icon_name

func _create_layers() -> void:
	combat_music_player = AudioStreamPlayer.new()
	combat_music_player.name = "CombatMusicPlayer"
	combat_music_player.bus = AudioSettings.MUSIC_BUS
	combat_music_player.volume_db = -45.0
	combat_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	combat_music_player.stream = COMBAT_MUSIC
	add_child(combat_music_player)
	combat_camera = Camera2D.new()
	combat_camera.name = "CombatCamera"
	combat_camera.enabled = false
	combat_camera.position = COMBAT_CAMERA_HOME
	add_child(combat_camera)
	unit_root = Node2D.new()
	unit_root.name = "UnitYSortLayer"
	unit_root.y_sort_enabled = true
	unit_root.z_index = 0
	add_child(unit_root)
	effect_root = Node2D.new()
	effect_root.name = "FxLayer"
	effect_root.z_index = 70
	add_child(effect_root)
	ui_layer = CanvasLayer.new()
	ui_layer.name = "HUD"
	add_child(ui_layer)

func _create_controllers() -> void:
	dungeon_renderer = DungeonRendererScript.new()
	dungeon_renderer.setup(self)
	quarter_renderer = QuarterDungeonRendererScript.new()
	quarter_renderer.setup(self)
	hud = HUDControllerScript.new()
	hud.setup(self)
	management_scene = ManagementSceneControllerScript.new()
	management_scene.setup(self, hud)
	combat_scene = CombatSceneControllerScript.new()
	combat_scene.setup(self, hud)

func _set_screen(screen_name: String) -> void:
	var previous_screen = current_screen
	if screen_name != Constants.SCREEN_MANAGEMENT:
		facility_change_panel_open = false
		_clear_management_action_mode(false)
	current_screen = screen_name
	first_play_observation.record_screen(screen_name, GameState.day)
	_update_combat_music(previous_screen, current_screen)
	_update_combat_camera_enabled()
	SignalBus.screen_changed.emit(screen_name)
	hud.clear()
	tutorial_targets.clear()
	match current_screen:
		Constants.SCREEN_TITLE:
			_build_onboarding_title_ui()
		Constants.SCREEN_NAME_ENTRY:
			_build_onboarding_name_entry_ui()
		Constants.SCREEN_DIALOGUE:
			_build_onboarding_dialogue_ui()
		Constants.SCREEN_MANAGEMENT:
			management_scene.build_management_ui()
		Constants.SCREEN_MONSTER:
			management_scene.build_monster_ui()
		Constants.SCREEN_COMBAT:
			combat_scene.build_combat_ui()
		Constants.SCREEN_RESULT:
			management_scene.build_result_ui()
		Constants.SCREEN_ENDING:
			_build_campaign_ending_ui()
		Constants.SCREEN_ENDING_ARCHIVE:
			_build_ending_archive_ui()
		Constants.SCREEN_MEMORY_ARCHIVE:
			management_scene.build_memory_archive_ui()
		Constants.SCREEN_CYCLE_DOCTRINE:
			_build_cycle_doctrine_ui()
		Constants.SCREEN_RAID_PREVIEW:
			_build_onboarding_raid_preview_ui()
		Constants.SCREEN_RAID:
			_build_raid_ui()
		Constants.SCREEN_SETTINGS:
			_build_settings_ui()
	_tutorial_build_overlay()
	if campaign_save_notice != "" and current_screen != Constants.SCREEN_TITLE:
		_show_campaign_save_notice_overlay()
	_schedule_campaign_autosave(current_screen)
	queue_redraw()

func _update_combat_music(previous_screen: String, next_screen: String) -> void:
	if combat_music_player == null:
		return
	if previous_screen != Constants.SCREEN_COMBAT and next_screen == Constants.SCREEN_COMBAT:
		_start_combat_music()
	elif previous_screen == Constants.SCREEN_COMBAT and next_screen != Constants.SCREEN_COMBAT:
		_stop_combat_music()

func _start_combat_music() -> void:
	_kill_combat_music_tween()
	combat_music_active = true
	if not combat_music_player.playing:
		combat_music_player.volume_db = -45.0
		combat_music_player.play()
	combat_music_tween = create_tween()
	combat_music_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	combat_music_tween.tween_property(combat_music_player, "volume_db", COMBAT_MUSIC_TARGET_DB, COMBAT_MUSIC_FADE_IN_SECONDS)

func _stop_combat_music() -> void:
	_kill_combat_music_tween()
	combat_music_active = false
	if not combat_music_player.playing:
		return
	combat_music_tween = create_tween()
	combat_music_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	combat_music_tween.tween_property(combat_music_player, "volume_db", -45.0, COMBAT_MUSIC_FADE_OUT_SECONDS)
	combat_music_tween.tween_callback(_finish_combat_music_stop)

func _finish_combat_music_stop() -> void:
	if current_screen != Constants.SCREEN_COMBAT and combat_music_player != null:
		combat_music_active = false
		combat_music_player.stop()

func _kill_combat_music_tween() -> void:
	if combat_music_tween != null and combat_music_tween.is_valid():
		combat_music_tween.kill()
	combat_music_tween = null

func _onboarding_screen_blocks_map_input() -> bool:
	return current_screen in [
		Constants.SCREEN_TITLE,
		Constants.SCREEN_NAME_ENTRY,
		Constants.SCREEN_DIALOGUE,
		Constants.SCREEN_RAID_PREVIEW,
		Constants.SCREEN_RAID,
		Constants.SCREEN_SETTINGS,
		Constants.SCREEN_ENDING,
		Constants.SCREEN_ENDING_ARCHIVE,
		Constants.SCREEN_MEMORY_ARCHIVE,
		Constants.SCREEN_CYCLE_DOCTRINE
	]

func _build_onboarding_title_ui() -> void:
	_refresh_campaign_save_status()
	var screen = _onboarding_screen_panel(Color("#050407ff"))
	_onboarding_add_scene_illustration(screen, Rect2(0, 0, 1920, 1080), ONBOARDING_START_SCENE)
	hud.label(screen, "마왕님, 마왕성은 누가 지켜요?", _onboarding_rect("S00_TITLE", "Logo", Rect2(360, 120, 1200, 220)).position, _onboarding_rect("S00_TITLE", "Logo", Rect2(360, 120, 1200, 220)).size, 54, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.label(screen, "F급 신입 마왕성 방어 튜토리얼", Vector2(560, 330), Vector2(800, 44), 24, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.button(screen, "새 게임", _onboarding_rect("S00_TITLE", "Menu_NewGame", Rect2(760, 460, 400, 72)), Callable(self, "_onboarding_start_new_game"), 22, "CampaignNewGameButton")
	var continue_button = hud.button(screen, "이어하기", _onboarding_rect("S00_TITLE", "Menu_Continue", Rect2(760, 548, 400, 72)), Callable(self, "_continue_campaign_save"), 22, "CampaignContinueButton")
	continue_button.disabled = campaign_save_status != CampaignSaveStoreScript.STATUS_VALID or campaign_save_notice != ""
	hud.button(screen, "빠른 시작", Rect2(760, 636, 400, 64), Callable(self, "_onboarding_start_quick_game"), 21, "CampaignQuickStartButton")
	hud.button(screen, "설정", Rect2(760, 712, 190, 64), Callable(self, "_open_settings_screen"), 21)
	hud.button(screen, "엔딩 도감", Rect2(970, 712, 190, 64), Callable(self, "_open_ending_archive"), 19, "EndingArchiveButton")
	hud.button(screen, "종료", Rect2(760, 788, 400, 64), Callable(self, "_onboarding_quit_requested"), 21)
	var save_status_text := _campaign_title_save_status_text()
	var save_status_color := Color("#c9bdd2")
	if campaign_save_notice != "":
		save_status_color = Color("#ff9b8f")
	elif campaign_save_status == CampaignSaveStoreScript.STATUS_VALID:
		save_status_color = Color("#ffd36a")
	elif campaign_save_status in [CampaignSaveStoreScript.STATUS_CORRUPT, CampaignSaveStoreScript.STATUS_UNSUPPORTED]:
		save_status_color = Color("#ff9b8f")
	hud.label(screen, save_status_text, Vector2(560, 870), Vector2(800, 112), 17, save_status_color, HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 3)
	hud.label(screen, "onboarding_flow_dialogue_v0.4 / Godot 4.5", _onboarding_rect("S00_TITLE", "VersionLabel", Rect2(32, 1020, 400, 32)).position, _onboarding_rect("S00_TITLE", "VersionLabel", Rect2(32, 1020, 400, 32)).size, 15, Color("#8d8398"))

func _campaign_title_save_status_text() -> String:
	if campaign_save_notice != "":
		return campaign_save_notice
	match campaign_save_status:
		CampaignSaveStoreScript.STATUS_VALID:
			return "DAY %02d / %02d · 마왕성 %d/4 %s · %s\n%d회차 · 발견 엔딩 %d/5 · %s · 자동 저장" % [
				int(campaign_save_summary.get("day", 1)),
				REGULAR_CAMPAIGN_FINAL_DAY,
				int(campaign_save_summary.get("castle_stage_index", 1)),
				str(campaign_save_summary.get("castle_name", "마왕성")),
				str(campaign_save_summary.get("player_name", "신입 마왕")),
				int(campaign_save_summary.get("cycle_index", 1)),
				int(campaign_save_summary.get("ending_archive_count", 0)),
				str(campaign_save_summary.get("checkpoint_label", "성 관리"))
			]
		CampaignSaveStoreScript.STATUS_CORRUPT:
			return "저장 파일이 손상되어 이어할 수 없습니다.\n새 게임을 시작하면 손상 기록을 안전하게 지웁니다."
		CampaignSaveStoreScript.STATUS_UNSUPPORTED:
			return "현재 버전에서 읽을 수 없는 저장 기록입니다.\n새 게임을 시작하면 새 형식으로 교체합니다."
		_:
			return "저장 기록 없음 · 새 게임 또는 빠른 시작으로 시작하세요."

func _open_settings_screen() -> void:
	_set_screen(Constants.SCREEN_SETTINGS)

func _open_ending_archive() -> void:
	_set_screen(Constants.SCREEN_ENDING_ARCHIVE)

func _open_selected_monster_memories() -> void:
	if selected_monster_id == "" or not monster_roster.has(selected_monster_id):
		return
	_set_screen(Constants.SCREEN_MEMORY_ARCHIVE)

func _ending_archive_snapshot() -> Dictionary:
	var archive: Dictionary = campaign_profile.get("ending_archive", {}).duplicate(true)
	var inspection: Dictionary = CampaignSaveStoreScript.inspect(campaign_save_path)
	if str(inspection.get("status", "")) == CampaignSaveStoreScript.STATUS_VALID:
		var payload: Dictionary = inspection.get("payload", {})
		var legacy_expansion: Dictionary = payload.get("legacy_expansion", {})
		var saved_profile: Dictionary = legacy_expansion.get("profile", {})
		var saved_archive = saved_profile.get("ending_archive", {})
		if saved_archive is Dictionary and saved_archive.size() >= archive.size():
			archive = saved_archive.duplicate(true)
	if campaign_completed and campaign_final_battle_outcome == "victory" and resolved_campaign_ending_id != "":
		if not archive.has(resolved_campaign_ending_id):
			archive[resolved_campaign_ending_id] = {"first_seen_cycle": campaign_cycle_index, "seen_count": 1, "last_seen_cycle": campaign_cycle_index}
	return archive

func _build_ending_archive_ui() -> void:
	var screen := _onboarding_screen_panel(Color("#050407ff"))
	_onboarding_add_scene_illustration(screen, Rect2(0, 0, 1920, 1080), ONBOARDING_START_SCENE)
	var shade := _onboarding_child_panel(screen, Rect2(90, 56, 1740, 944), Color("#08060cdf"), Color("#9b6a27"))
	var archive := _ending_archive_snapshot()
	hud.label(shade, "엔딩 도감", Vector2(0, 26), Vector2(1740, 54), 38, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(shade, "발견 %d/5 · 한 번 확인한 결말은 다음 회차에도 남습니다." % archive.size(), Vector2(0, 80), Vector2(1740, 34), 17, Color("#c6a968"), HORIZONTAL_ALIGNMENT_CENTER)
	var ending_ids := ["true_demon_castle", "monster_family_castle", "impregnable_demon_citadel", "dread_overlord_rises", "demon_hero_rival_pact"]
	var positions := [Vector2(130, 142), Vector2(610, 142), Vector2(1090, 142), Vector2(370, 508), Vector2(850, 508)]
	for index in range(ending_ids.size()):
		var ending_id: String = ending_ids[index]
		var rule := DataRegistry.ending_rule(ending_id)
		var discovered := archive.has(ending_id)
		var card: Panel = hud.child_panel(shade, Rect2(positions[index], Vector2(390, 320)), Color("#100d14f2"), Color("#9b6a27") if discovered else Color("#403846"), 2 if discovered else 1)
		if discovered:
			var thumbnail: TextureRect = hud.texture(card, str(rule.get("thumbnail", "")), Rect2(18, 18, 354, 199))
			thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			var emblem: TextureRect = hud.texture(card, str(rule.get("emblem", "")), Rect2(20, 224, 70, 70))
			emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hud.label(card, str(rule.get("display_name", ending_id)), Vector2(92, 226), Vector2(278, 34), 20, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
			var entry: Dictionary = archive.get(ending_id, {})
			hud.label(card, "발견 %d회 · 최초 %d회차" % [int(entry.get("seen_count", 1)), int(entry.get("first_seen_cycle", 1))], Vector2(92, 264), Vector2(278, 24), 14, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_LEFT)
		else:
			hud.label(card, "?", Vector2(0, 58), Vector2(390, 120), 72, Color("#574f60"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
			hud.label(card, "아직 발견하지 못한 결말", Vector2(24, 226), Vector2(342, 46), 18, Color("#7d7586"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.button(shade, "타이틀로 돌아가기", Rect2(690, 862, 360, 58), Callable(self, "_set_screen").bind(Constants.SCREEN_TITLE), 19)

func _build_settings_ui() -> void:
	var screen = _onboarding_screen_panel(Color("#050407ff"))
	_onboarding_add_scene_illustration(screen, Rect2(0, 0, 1920, 1080), ONBOARDING_START_SCENE)
	var panel_rect = Rect2(570, 180, 780, 700)
	var panel = _onboarding_child_panel(screen, panel_rect, Color("#100d14f4"), Color("#9b6a27"))
	hud.label(panel, "환경 설정", Vector2(0, 30), Vector2(panel_rect.size.x, 52), 34, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	_build_audio_setting_row(panel, 100.0, "마스터 음량", AudioSettings.master_volume, "master")
	_build_audio_setting_row(panel, 220.0, "전투 음악", AudioSettings.music_volume, "music")
	_build_audio_setting_row(panel, 340.0, "전투 효과음", AudioSettings.sfx_volume, "sfx")
	_build_ui_setting_row(panel, 460.0)
	hud.button(panel, "기본값 복원", Rect2(78, 610, 280, 62), Callable(self, "_reset_audio_settings"), 20)
	hud.button(panel, "돌아가기", Rect2(422, 610, 280, 62), Callable(self, "_close_settings_screen"), 20)

func _build_audio_setting_row(parent: Control, y: float, title: String, current_value: float, setting_id: String) -> void:
	hud.label(parent, title, Vector2(78, y), Vector2(430, 34), 22, Color("#eee5f4"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var value_label = hud.label(parent, "%d%%" % int(round(current_value * 100.0)), Vector2(590, y), Vector2(112, 34), 20, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_RIGHT, "", UIFontScript.ROLE_EMPHASIS)
	hud.slider(parent, Rect2(78, y + 50, 624, 36), current_value * 100.0, Callable(self, "_on_audio_slider_changed").bind(setting_id, value_label))

func _on_audio_slider_changed(value: float, setting_id: String, value_label: Label) -> void:
	var linear_value = value / 100.0
	match setting_id:
		"master":
			AudioSettings.set_master_volume(linear_value)
		"music":
			AudioSettings.set_music_volume(linear_value)
		_:
			AudioSettings.set_sfx_volume(linear_value)
	if value_label != null and is_instance_valid(value_label):
		value_label.text = "%d%%" % int(round(value))

func _build_ui_setting_row(parent: Control, y: float) -> void:
	hud.label(parent, "글자 크기", Vector2(78, y), Vector2(430, 34), 22, Color("#eee5f4"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var value_label = hud.label(parent, "%d%%" % int(round(UISettings.text_scale * 100.0)), Vector2(590, y), Vector2(112, 34), 20, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_RIGHT, "", UIFontScript.ROLE_EMPHASIS)
	hud.slider(parent, Rect2(78, y + 50, 624, 36), UISettings.text_scale * 100.0, Callable(self, "_on_ui_scale_changed").bind(value_label), UISettings.MIN_TEXT_SCALE * 100.0, UISettings.MAX_TEXT_SCALE * 100.0, 5.0)

func _on_ui_scale_changed(value: float, value_label: Label) -> void:
	UISettings.set_text_scale(value / 100.0)
	if value_label != null and is_instance_valid(value_label):
		value_label.text = "%d%%" % int(round(value))

func _reset_audio_settings() -> void:
	AudioSettings.reset_defaults()
	UISettings.reset_defaults()
	_set_screen(Constants.SCREEN_SETTINGS)

func _close_settings_screen() -> void:
	_set_screen(Constants.SCREEN_TITLE)

func _build_onboarding_name_entry_ui() -> void:
	onboarding_name_input = null
	onboarding_bati_comment_label = null
	var screen = _onboarding_screen_panel(Color("#050407ff"))
	_onboarding_add_scene_illustration(screen, Rect2(0, 0, 1920, 1080), ONBOARDING_START_SCENE)
	var panel_rect = _onboarding_rect("S01_NAME_ENTRY", "Panel_NameForm", Rect2(560, 210, 800, 610))
	var panel = _onboarding_child_panel(screen, panel_rect, Color("#100d14f2"), Color("#9b6a27"))
	var title_rect = _onboarding_rect("S01_NAME_ENTRY", "Title", Rect2(620, 260, 680, 60))
	var title_back = Panel.new()
	title_back.position = title_rect.position - panel_rect.position + Vector2(78, 4)
	title_back.size = Vector2(title_rect.size.x - 156, title_rect.size.y - 6)
	title_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_back.add_theme_stylebox_override("panel", hud.style(Color("#050407d8"), Color("#ffd36a88"), 1))
	panel.add_child(title_back)
	var title_label = hud.label(panel, "F급 신입 마왕 등록", title_rect.position - panel_rect.position, title_rect.size, 34, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	title_label.add_theme_constant_override("outline_size", 5)
	title_label.add_theme_color_override("font_outline_color", Color("#050407"))
	hud.label(panel, "당신의 이름은 무엇입니까?", Vector2(80, 130), Vector2(640, 34), 20, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)

	var input_rect = _onboarding_rect("S01_NAME_ENTRY", "NameInput", Rect2(700, 420, 520, 64))
	onboarding_name_input = LineEdit.new()
	onboarding_name_input.position = input_rect.position - panel_rect.position
	onboarding_name_input.size = input_rect.size
	onboarding_name_input.placeholder_text = "마왕명을 입력하세요"
	onboarding_name_input.max_length = 12
	onboarding_name_input.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_EMPHASIS))
	onboarding_name_input.add_theme_font_size_override("font_size", 24)
	onboarding_name_input.add_theme_color_override("font_color", Color("#f7efe1"))
	onboarding_name_input.add_theme_color_override("font_placeholder_color", Color("#a79dad"))
	onboarding_name_input.add_theme_stylebox_override("normal", hud.style(Color("#0c0910f2"), Color("#ffd36a"), 2))
	onboarding_name_input.add_theme_stylebox_override("focus", hud.style(Color("#120d18f8"), Color("#ffe38a"), 2))
	onboarding_name_input.text_submitted.connect(_onboarding_name_submitted)
	panel.add_child(onboarding_name_input)
	register_tutorial_target("NameInput", input_rect)
	onboarding_name_input.visible = onboarding_name_entry_tip_dismissed
	onboarding_name_input.editable = onboarding_name_entry_tip_dismissed
	if onboarding_name_entry_tip_dismissed:
		onboarding_name_input.call_deferred("grab_focus")

	var random_button = hud.button(panel, "무작위 이름", _onboarding_relative_rect(_onboarding_rect("S01_NAME_ENTRY", "RandomNameButton", Rect2(700, 500, 250, 56)), panel_rect), Callable(self, "_onboarding_random_name"), 19)
	var confirm_button = hud.button(panel, "확정", _onboarding_relative_rect(_onboarding_rect("S01_NAME_ENTRY", "ConfirmButton", Rect2(970, 500, 250, 56)), panel_rect), Callable(self, "_onboarding_confirm_name"), 19)
	random_button.visible = onboarding_name_entry_tip_dismissed
	confirm_button.visible = onboarding_name_entry_tip_dismissed
	random_button.disabled = not onboarding_name_entry_tip_dismissed
	confirm_button.disabled = not onboarding_name_entry_tip_dismissed

	var note_panel = Panel.new()
	note_panel.position = Vector2(56, 386)
	note_panel.size = Vector2(688, 116)
	note_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note_panel.add_theme_stylebox_override("panel", hud.style(Color("#07050dd8"), Color("#6e5630"), 1))
	panel.add_child(note_panel)
	var portrait_frame = Panel.new()
	portrait_frame.position = Vector2(14, 12)
	portrait_frame.size = Vector2(92, 92)
	portrait_frame.clip_contents = true
	portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_frame.add_theme_stylebox_override("panel", hud.style(Color("#100b14f4"), _onboarding_speaker_accent("CHR_BATI"), 1))
	note_panel.add_child(portrait_frame)
	var portrait_image = hud.texture(portrait_frame, _onboarding_speaker_portrait_path("CHR_BATI", "dry"), Rect2(-6, -6, 104, 104))
	portrait_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hud.label(note_panel, "바티", Vector2(122, 14), Vector2(520, 22), 15, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	onboarding_bati_comment_label = hud.label(note_panel, _onboarding_name_screen_comment(), Vector2(122, 42), Vector2(528, 58), 17, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_ARBITRARY, 3)
	if not onboarding_name_entry_tip_dismissed:
		_onboarding_add_name_entry_tip(panel, panel_rect, input_rect)

func _onboarding_add_name_entry_tip(parent: Control, panel_rect: Rect2, input_rect: Rect2) -> void:
	var card_rect = Rect2(input_rect.position - panel_rect.position - Vector2(12, 20), input_rect.size + Vector2(24, 142))
	var shadow = Panel.new()
	shadow.position = card_rect.position + Vector2(8, 10)
	shadow.size = card_rect.size
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.add_theme_stylebox_override("panel", hud.style(Color("#00000099"), Color("#00000000"), 0))
	parent.add_child(shadow)
	var card = Panel.new()
	card.position = card_rect.position
	card.size = card_rect.size
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", hud.style(Color("#100d14fb"), Color("#ffd36a"), 3))
	card.gui_input.connect(_onboarding_name_tip_gui_input)
	parent.add_child(card)
	hud.label(card, "먼저 안내를 확인하세요", Vector2(24, 18), Vector2(card_rect.size.x - 48, 26), 19, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(card, "마왕명은 이후 모든 대사와 결과 화면에 표시됩니다.\n확인하면 입력창이 열립니다.", Vector2(24, 56), Vector2(card_rect.size.x - 48, 58), 20, Color("#fff7e6"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_ARBITRARY, 2)
	hud.button(card, "확인하고 입력하기", Rect2(card_rect.size.x * 0.5 - 150, card_rect.size.y - 64, 300, 46), Callable(self, "_onboarding_dismiss_name_entry_tip"), 18)

func _onboarding_name_tip_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_onboarding_dismiss_name_entry_tip()

func _onboarding_dismiss_name_entry_tip() -> void:
	if onboarding_name_entry_tip_dismissed:
		return
	onboarding_name_entry_tip_dismissed = true
	_set_screen(Constants.SCREEN_NAME_ENTRY)

func _build_onboarding_dialogue_ui() -> void:
	var screen = _onboarding_screen_panel(Color("#050407d8"))
	if onboarding_dialogue_queue.is_empty():
		_onboarding_add_scene_illustration(screen, _onboarding_rect("S02_DIALOGUE", "SceneIllustration", Rect2(0, 0, 1920, 1080)), _onboarding_dialogue_scene_path({}))
		hud.label(screen, "튜토리얼", Vector2(72, 50), Vector2(360, 42), 24, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
		hud.rich_label(screen, "표시할 대사가 없습니다.", Vector2(560, 766), Vector2(1040, 150), 24, Color("#f7efe1"), UIFontScript.ROLE_DIALOGUE, TextServer.AUTOWRAP_ARBITRARY, VERTICAL_ALIGNMENT_CENTER)
		hud.button(screen, "닫기", Rect2(1600, 920, 190, 48), Callable(self, "_onboarding_advance_dialogue"), 18)
		return
	var line: Dictionary = onboarding_dialogue_queue[clampi(onboarding_dialogue_index, 0, onboarding_dialogue_queue.size() - 1)]
	_onboarding_add_scene_illustration(screen, _onboarding_rect("S02_DIALOGUE", "SceneIllustration", Rect2(0, 0, 1920, 1080)), _onboarding_dialogue_scene_path(line))
	var dialogue_header := str(line.get("dialogue_header", "튜토리얼"))
	hud.label(screen, dialogue_header, Vector2(72, 50), Vector2(720, 42), 24, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var speaker_id = str(line.get("speaker", ""))
	var speaker_name = str(line.get("speaker_name", _onboarding_speaker_name(speaker_id)))
	var portrait_rect = Rect2(72, 612, 292, 396)
	_onboarding_add_portrait(screen, portrait_rect, speaker_id, speaker_name, str(line.get("emotion", "")), false)
	var box_rect = Rect2(336, 660, 1510, 326)
	_onboarding_child_panel(screen, box_rect, Color("#100d14f4"), Color("#9b6a27"))
	var speaker_rect = Rect2(392, 696, 760, 46)
	hud.label(screen, speaker_name, speaker_rect.position, speaker_rect.size, 29, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var text_rect = Rect2(392, 756, 1220, 134)
	var dialogue_label = hud.rich_label(screen, _onboarding_line_text(line), text_rect.position, text_rect.size, 24, Color("#f7efe1"), UIFontScript.ROLE_DIALOGUE, TextServer.AUTOWRAP_WORD_SMART, VERTICAL_ALIGNMENT_CENTER, "", 16)
	dialogue_label.add_theme_constant_override("line_separation", 4)
	var next_button_rect = Rect2(1542, 908, 246, 56)
	hud.label(screen, "%d / %d" % [onboarding_dialogue_index + 1, onboarding_dialogue_queue.size()], Vector2(1402, 920), Vector2(116, 28), 16, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_RIGHT, "", UIFontScript.ROLE_BODY)
	var next_label := str(line.get("next_label", "다음"))
	hud.button(screen, next_label, next_button_rect, Callable(self, "_onboarding_advance_dialogue"), 21)
	if campaign_cycle_index >= 2 and onboarding_dialogue_queue.size() > 1:
		hud.button(screen, "본 대화 건너뛰기", Rect2(1184, 908, 200, 56), Callable(self, "_onboarding_skip_dialogue"), 16)

func _build_cycle_doctrine_ui() -> void:
	var screen := _onboarding_screen_panel(Color("#050407ff"))
	_onboarding_add_scene_illustration(screen, Rect2(0, 0, 1920, 1080), ONBOARDING_START_SCENE)
	var shade := _onboarding_child_panel(screen, Rect2(150, 90, 1620, 900), Color("#08060cef"), Color("#9b6a27"))
	hud.label(shade, "%d회차 · 왕국 교리 대응" % campaign_cycle_index, Vector2(0, 38), Vector2(1620, 56), 38, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(shade, "정찰대가 확인한 왕국의 다음 공세 중 하나를 골라 대응책을 확정하세요. 선택 효과는 이번 회차에 즉시 적용됩니다.", Vector2(180, 108), Vector2(1260, 52), 19, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
	var doctrine_ids := DataRegistry.cycle_doctrine_ids()
	for index in range(doctrine_ids.size()):
		var doctrine_id := str(doctrine_ids[index])
		var doctrine: Dictionary = DataRegistry.cycle_doctrine(doctrine_id)
		var card := _onboarding_child_panel(shade, Rect2(88 + index * 492, 208, 456, 520), Color("#130f19f4"), Color("#6e5630"))
		hud.label(card, str(doctrine.get("kingdom_title", "왕국 교리")), Vector2(22, 28), Vector2(412, 38), 21, Color("#f0c46f"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
		hud.label(card, str(doctrine.get("counter_title", "대응책")), Vector2(22, 92), Vector2(412, 46), 29, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
		hud.rich_label(card, str(doctrine.get("description", "")), Vector2(42, 166), Vector2(372, 142), 18, Color("#d8d1df"), UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_WORD_SMART, VERTICAL_ALIGNMENT_CENTER, "", 8)
		var effect_panel := _onboarding_child_panel(card, Rect2(30, 334, 396, 72), Color("#24172eee"), Color("#8f66b5"))
		hud.label(effect_panel, str(doctrine.get("effect_label", "")), Vector2(14, 12), Vector2(368, 48), 17, Color("#fff2c9"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
		hud.button(card, "이 대응으로 시작", Rect2(80, 438, 296, 58), Callable(self, "_select_cycle_doctrine").bind(doctrine_id), 19)
	hud.label(shade, "교리는 한 회차에 한 번만 선택할 수 있습니다.", Vector2(0, 788), Vector2(1620, 34), 16, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)

func _build_onboarding_raid_preview_ui() -> void:
	_unlock_kobold_scout_commander()
	var screen = _onboarding_screen_panel(Color("#06050bee"))
	_onboarding_set_stage("LV12_DAY04_RAID_PREVIEW")
	var world_rect = _onboarding_rect("S06_RAID_PREVIEW", "WorldMapPanel", Rect2(120, 100, 1080, 780))
	var world = _onboarding_child_panel(screen, world_rect, Color("#101017e8"), Color("#6e5630"))
	register_tutorial_target("WorldMapPanel", world_rect)
	hud.label(world, "DAY 04 악명 원정", Vector2(0, 42), Vector2(world_rect.size.x, 52), 34, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.label(world, "마왕성 방어 이후에는 밖으로 나가 악명을 얻는 원정 루프가 열립니다.", Vector2(120, 132), Vector2(840, 56), 22, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_CENTER)
	_onboarding_add_portrait(world, Rect2(82, 238, 250, 310), KOBOLD_SCOUT_CHARACTER_ID, "로로", "mischief", true)
	hud.label(world, "첫 목표: 마을 외곽 표지판", Vector2(390, 285), Vector2(560, 46), 30, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.label(world, "로로가 원정대장으로 합류했습니다.\n장난은 많지만 길 찾기와 소문 부풀리기는 확실합니다.", Vector2(390, 352), Vector2(560, 112), 22, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 3)
	hud.label(world, "정규 캠페인 연결 지점: CAMPAIGN_DAY_04", Vector2(240, 615), Vector2(600, 40), 20, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
	var info_rect = _onboarding_rect("S06_RAID_PREVIEW", "RaidInfoPanel", Rect2(1240, 100, 560, 780))
	var info = _onboarding_child_panel(screen, info_rect, Color("#100d14f2"), Color("#9b6a27"))
	hud.label(info, "원정 브리핑", Vector2(0, 34), Vector2(info_rect.size.x, 46), 31, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.label(info, "방어만으로 악명을 올리는 초반 루프는 DAY 03에서 검증되었습니다.\n\nDAY 04부터는 원정 선택, 목표 보상, 귀환 후 다음 방어 영향으로 확장합니다.\n\n첫 원정은 작지만, 세계가 마왕성을 기억하기 시작하는 장면입니다.", Vector2(44, 120), Vector2(472, 390), 22, Color("#d8d1df"))
	hud.button(info, "첫 원정 시작", Rect2(86, 560, 388, 64), Callable(self, "_open_raid_screen"), 21, "StartRaidButton")
	hud.button(screen, "관리 화면", _onboarding_rect("S06_RAID_PREVIEW", "BackButton", Rect2(1520, 920, 280, 64)), Callable(self, "_onboarding_finish_raid_preview"), 20, "BackButton")
	call_deferred("_onboarding_emit_raid_preview_dialogue")

func _onboarding_screen_panel(color: Color) -> Panel:
	var screen = hud.panel(Rect2(0, 0, 1920, 1080), color, color, "", "flat")
	screen.mouse_filter = Control.MOUSE_FILTER_STOP
	return screen

func _onboarding_child_panel(parent: Control, rect: Rect2, color: Color, border: Color) -> Panel:
	var result = Panel.new()
	result.position = rect.position
	result.size = rect.size
	result.mouse_filter = Control.MOUSE_FILTER_STOP
	result.clip_contents = true
	result.add_theme_stylebox_override("panel", hud.panel_style("flat", color, Color(border.r, border.g, border.b, 0.62), 1))
	parent.add_child(result)
	return result

func _onboarding_add_scene_illustration(parent: Control, rect: Rect2, path: String) -> void:
	if path != "":
		var image = hud.texture(parent, path, rect)
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var shade = ColorRect.new()
	shade.position = rect.position
	shade.size = rect.size
	shade.color = Color("#0302078c")
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(shade)

func _onboarding_add_portrait(parent: Control, rect: Rect2, speaker_id: String, speaker_name: String, emotion: String = "", show_name: bool = true) -> Panel:
	var portrait = _onboarding_child_panel(parent, rect, Color("#050407fa"), _onboarding_speaker_accent(speaker_id))
	var portrait_path := _onboarding_speaker_portrait_path(speaker_id, emotion)
	if portrait_path == "":
		hud.label(portrait, speaker_name, Vector2.ZERO, rect.size, 24, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER)
		return portrait
	var padding := 6.0
	var label_height := 54.0 if show_name else 0.0
	var image_rect = Rect2(Vector2(padding, padding), Vector2(rect.size.x - padding * 2.0, rect.size.y - padding * 2.0 - label_height))
	var image_back = ColorRect.new()
	image_back.position = image_rect.position
	image_back.size = image_rect.size
	image_back.color = Color("#020203")
	image_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.add_child(image_back)
	var portrait_image = hud.texture(portrait, portrait_path, image_rect)
	portrait_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if show_name:
		var plate = ColorRect.new()
		plate.position = Vector2(padding, rect.size.y - label_height - padding)
		plate.size = Vector2(rect.size.x - padding * 2.0, label_height)
		plate.color = Color("#050407c8")
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.add_child(plate)
		hud.label(portrait, speaker_name, plate.position, plate.size, 24, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	return portrait

func _onboarding_rect(screen_id: String, node_name: String, fallback: Rect2) -> Rect2:
	if onboarding_flow.loaded:
		return onboarding_flow.screen_rect(screen_id, node_name, fallback)
	return fallback

func _onboarding_relative_rect(rect: Rect2, parent_rect: Rect2) -> Rect2:
	return Rect2(rect.position - parent_rect.position, rect.size)

func _onboarding_name_screen_comment() -> String:
	var entries = onboarding_flow.dialogue_for_trigger("screen_open", "LV01_NAME_ENTRY") if onboarding_flow.loaded else []
	if entries.is_empty():
		return "마왕명을 입력하고 확정하십시오."
	return _onboarding_line_text(entries[0])

func _onboarding_start_new_game() -> void:
	if not _delete_campaign_save():
		_set_screen(Constants.SCREEN_TITLE)
		return
	_onboarding_reset_game()
	_start_first_play_observation("new")
	_onboarding_set_stage("LV01_NAME_ENTRY")
	_set_screen(Constants.SCREEN_NAME_ENTRY)

func _onboarding_start_quick_game() -> void:
	if not _delete_campaign_save():
		_set_screen(Constants.SCREEN_TITLE)
		return
	_onboarding_reset_game()
	_start_first_play_observation("quick")
	GameState.player_name = "신입 마왕"
	_onboarding_set_stage("LV01_NAME_ENTRY")
	_tutorial_emit_action("name_valid", {"player_name": GameState.player_name})
	_onboarding_set_stage("LV02_OPENING_CUTSCENE")
	_tutorial_emit_action("dialogue_closed", {"stage": onboarding_stage_id})
	_onboarding_enter_management_day(1, false)

func _onboarding_reset_game() -> void:
	GameState.reset()
	_reset_run_metrics()
	campaign_profile = NewCycleServiceScript.default_profile()
	campaign_cycle_index = 1
	inherited_legacy_monster.clear()
	logs.clear()
	_clear_units()
	_reset_raid_state()
	quarter_layout_id = DataRegistry.quarter_default_layout_id
	map_editor_active = false
	map_editor_layout.clear()
	map_editor_status = ""
	map_editor_errors.clear()
	_clear_map_editor_path_drag()
	result_summary.clear()
	rewards_pending.clear()
	last_growth_summary.clear()
	result_growth_reviewed = false
	result_growth_choice_monster_id = ""
	result_growth_choice_applied = false
	last_growth_choice_summary.clear()
	last_security_grade = ""
	facility_change_panel_open = false
	build_pick_mode = false
	build_pick_facility_id = ""
	build_palette_target_room = ""
	build_preview_room_id = ""
	build_blocked_room_id = ""
	deploy_pick_monster_id = ""
	facility_effect_stats.clear()
	facility_disabled_timers.clear()
	directive_effect_stats.clear()
	rooms = DataRegistry.rooms.duplicate(true)
	_init_room_facilities()
	_sync_castle_stage_content()
	_setup_dungeon_graph()
	_init_roster()
	_init_room_directives()
	global_directive = Constants.DIRECTIVE_ALL_OUT
	selected_room = "entrance"
	selected_monster_id = "slime"
	onboarding_stage_id = "LV00_TITLE_BOOT"
	onboarding_dialogue_queue.clear()
	onboarding_dialogue_index = 0
	onboarding_dialogue_return_screen = Constants.SCREEN_MANAGEMENT
	onboarding_dialogue_complete_action = ONBOARDING_ACTION_NONE
	onboarding_seen_dialogue_ids.clear()
	onboarding_name_entry_tip_dismissed = false
	onboarding_boss_hp_thresholds.clear()
	onboarding_treasure_stolen_this_day = false
	onboarding_enabled = onboarding_flow.loaded
	tutorial_gate_enabled = true
	tutorial_manager.reset()

func _start_first_play_observation(mode: String) -> void:
	first_play_observation.start_session(mode, tutorial_manager.current_step_id(), GameState.day)

func _reset_raid_state() -> void:
	raid_selected_mission_id = FIRST_RAID_MISSION_ID
	raid_selected_monster_ids.clear()
	completed_raids.clear()
	last_raid_result.clear()
	next_defense_modifiers.clear()
	campaign_seen_day_intros.clear()
	campaign_seen_combat_intros.clear()
	campaign_combat_timed_lines_fired.clear()
	campaign_chapter_one_clear = false
	campaign_stage_two_prepared = false
	campaign_chapter_two_started = false
	campaign_stage_two_upgrade_funded = false
	campaign_stage_two_unlock_ready = false
	campaign_chapter_three_clear = false
	campaign_chapter_four_clear = false
	campaign_final_chapter_unlocked = false
	campaign_final_upgrade_ready = false
	campaign_final_preparation_confirmed = false
	campaign_completed = false
	campaign_final_battle_outcome = ""
	campaign_finale_defeat_seen = false
	campaign_postgame_active = false
	castle_art_stage = CASTLE_STAGE_ONE_ID
	castle_evolution_history = [CASTLE_STAGE_ONE_ID]
	last_castle_evolution_day = 0
	last_castle_evolution_from_stage = ""
	first_promotion_completed = false
	facility_upgrade_unlocked = false
	last_security_grade = ""

func _onboarding_random_name() -> void:
	if onboarding_name_input == null:
		return
	var names = ["그림송곳", "밤안개", "불씨왕", "동굴남작", "작은파멸"]
	onboarding_name_input.text = names[randi() % names.size()]

func _onboarding_name_submitted(_text: String) -> void:
	_onboarding_confirm_name()

func _onboarding_confirm_name() -> void:
	if onboarding_name_input == null:
		return
	var player_name = onboarding_name_input.text.strip_edges()
	if player_name == "":
		_onboarding_show_name_comment("invalid_empty")
		return
	if player_name.length() > 12:
		_onboarding_show_name_comment("invalid_too_long")
		return
	GameState.player_name = player_name
	_tutorial_emit_action("name_valid", {"player_name": player_name})
	_onboarding_set_stage("LV02_OPENING_CUTSCENE")
	_onboarding_begin_dialogue(_onboarding_essential_opening_entries(), Constants.SCREEN_MANAGEMENT, ONBOARDING_ACTION_DAY1_MANAGEMENT)

func _onboarding_essential_opening_entries() -> Array:
	var allowed_ids: Dictionary = {}
	for line_id in ONBOARDING_ESSENTIAL_OPENING_LINE_IDS:
		allowed_ids[str(line_id)] = true
	var result: Array = []
	for entry in onboarding_flow.dialogue_for_stage_triggers("LV02_OPENING_CUTSCENE", ONBOARDING_OPENING_TRIGGERS):
		if entry is Dictionary and allowed_ids.has(str(entry.get("id", ""))):
			result.append(entry)
	return result

func _onboarding_show_name_comment(trigger_id: String) -> void:
	var entries = onboarding_flow.dialogue_for_trigger(trigger_id, "LV01_NAME_ENTRY")
	if entries.is_empty() or onboarding_bati_comment_label == null:
		return
	onboarding_bati_comment_label.text = _onboarding_line_text(entries[0])

func _onboarding_begin_dialogue(entries: Array, return_screen: String, complete_action: String = ONBOARDING_ACTION_NONE) -> void:
	if entries.is_empty():
		_onboarding_complete_dialogue_action(complete_action, return_screen)
		return
	onboarding_dialogue_queue = entries
	onboarding_dialogue_index = 0
	onboarding_dialogue_return_screen = return_screen
	onboarding_dialogue_complete_action = complete_action
	_set_screen(Constants.SCREEN_DIALOGUE)

func _onboarding_advance_dialogue() -> void:
	if onboarding_dialogue_index + 1 < onboarding_dialogue_queue.size():
		onboarding_dialogue_index += 1
		_set_screen(Constants.SCREEN_DIALOGUE)
		return
	var return_screen = onboarding_dialogue_return_screen
	var complete_action = onboarding_dialogue_complete_action
	onboarding_dialogue_queue.clear()
	onboarding_dialogue_index = 0
	onboarding_dialogue_complete_action = ONBOARDING_ACTION_NONE
	_tutorial_emit_action("dialogue_closed", {"stage": onboarding_stage_id})
	_onboarding_complete_dialogue_action(complete_action, return_screen)

func _onboarding_skip_dialogue() -> void:
	if campaign_cycle_index < 2:
		return
	var return_screen := onboarding_dialogue_return_screen
	var complete_action := onboarding_dialogue_complete_action
	onboarding_dialogue_queue.clear()
	onboarding_dialogue_index = 0
	onboarding_dialogue_complete_action = ONBOARDING_ACTION_NONE
	_tutorial_emit_action("dialogue_closed", {"stage": onboarding_stage_id, "skipped": true})
	_onboarding_complete_dialogue_action(complete_action, return_screen)

func _select_cycle_doctrine(doctrine_id: String) -> void:
	if campaign_cycle_index < 2 or str(campaign_profile.get("active_doctrine_id", "")) != "":
		return
	var doctrine: Dictionary = DataRegistry.cycle_doctrine(doctrine_id)
	if doctrine.is_empty():
		return
	GameState.add_rewards(doctrine.get("rewards", {}))
	var income: Dictionary = doctrine.get("income", {})
	GameState.gold_income += int(income.get("gold", 0))
	GameState.mana_income += int(income.get("mana", 0))
	GameState.food_income += int(income.get("food", 0))
	GameState.infamy_income += int(income.get("infamy", 0))
	var bond_gain := int(doctrine.get("bond_all", 0))
	if bond_gain > 0:
		for monster_id_value in monster_roster.keys():
			_grant_monster_bond(str(monster_id_value), bond_gain)
	campaign_profile["active_doctrine_id"] = doctrine_id
	var history: Array = campaign_profile.get("doctrine_history", [])
	history.append({"cycle": campaign_cycle_index, "doctrine_id": doctrine_id})
	campaign_profile["doctrine_history"] = history
	SignalBus.resources_changed.emit()
	_log("%d회차 대응 교리 확정: %s · %s" % [campaign_cycle_index, str(doctrine.get("counter_title", doctrine_id)), str(doctrine.get("effect_label", ""))])
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _onboarding_complete_dialogue_action(action: String, return_screen: String) -> void:
	match action:
		ONBOARDING_ACTION_DAY1_MANAGEMENT:
			_onboarding_enter_management_day(1, true)
		_:
			_set_screen(return_screen)

func _onboarding_enter_management_day(day: int, show_dialogue: bool) -> void:
	GameState.day = day
	_onboarding_set_stage(_onboarding_management_stage_for_day(day))
	_set_screen(Constants.SCREEN_MANAGEMENT)
	if show_dialogue:
		call_deferred("_onboarding_emit_management_intro", day)

func _onboarding_emit_management_intro(day: int) -> void:
	if not onboarding_enabled:
		return
	var triggers: Array = ["management_open"]
	if day == 2:
		triggers.append("enemy_preview")
	if day == 3:
		triggers.append("recovery_nest_unlock")
	_onboarding_open_stage_dialogue(triggers, Constants.SCREEN_MANAGEMENT)

func _onboarding_emit_raid_preview_dialogue() -> void:
	if not onboarding_enabled or current_screen != Constants.SCREEN_RAID_PREVIEW:
		return
	_onboarding_open_stage_dialogue(["raid_preview_open"], Constants.SCREEN_RAID_PREVIEW)

func _onboarding_open_stage_dialogue(triggers: Array, return_screen: String) -> bool:
	if not onboarding_enabled or not onboarding_flow.loaded:
		return false
	var entries = _onboarding_collect_unseen_entries(onboarding_flow.dialogue_for_stage_triggers(onboarding_stage_id, triggers))
	if entries.is_empty():
		return false
	_onboarding_begin_dialogue(entries, return_screen)
	return true

func _onboarding_emit_trigger(trigger_id: String, stage_id: String = "") -> bool:
	if not onboarding_enabled or not onboarding_flow.loaded:
		return false
	var active_stage = stage_id if stage_id != "" else onboarding_stage_id
	var entries = _onboarding_collect_unseen_entries(onboarding_flow.dialogue_for_trigger(trigger_id, active_stage))
	if entries.is_empty():
		return false
	if current_screen == Constants.SCREEN_COMBAT or trigger_id in ONBOARDING_NONBLOCKING_TRIGGER_IDS:
		for entry in entries:
			_log(_onboarding_log_line(entry))
	else:
		_onboarding_begin_dialogue(entries, current_screen)
	return true

func _onboarding_collect_unseen_entries(entries: Array) -> Array:
	var result: Array = []
	for entry in entries:
		if not (entry is Dictionary):
			continue
		var line_id = str(entry.get("id", ""))
		if line_id != "" and onboarding_seen_dialogue_ids.has(line_id):
			continue
		if line_id != "":
			onboarding_seen_dialogue_ids[line_id] = true
		result.append(entry)
	return result

func _onboarding_line_text(line: Dictionary) -> String:
	match str(line.get("id", "")):
		"TUT_030_SELECT_SLIME":
			return "침입자는 노란 경로를 따라 왕좌로 향합니다.\n슬라임으로 입구에서 시간을 벌어야 합니다."
		"TUT_040_DEPLOY_SLIME":
			return "오른쪽 [몬스터 배치]에서 슬라임을 누른 뒤, 입구 방을 클릭하세요.\n또는 맵 위 슬라임을 입구로 드래그하세요."
		"TUT_050_GLOBAL_DEFEND":
			return "오른쪽 [운영 지침]에서 전체를 [사수]로 바꾸세요.\n몬스터가 배치된 방과 방어선을 지킵니다."
		"TUT_060_ROOM_BLOCK":
			return "오른쪽 [운영 지침]에서 선택 방을 [입구 봉쇄]로 바꾸세요.\n입구 주변에서 적을 먼저 막습니다."
		"TUT_070_DIRECT_CONTROL":
			return "슬라임을 선택한 상태에서 [직접 조종]을 누르세요.\n이후 적을 우클릭하면 직접 공격을 지정합니다."
		"TUT_075_DIRECT_ATTACK":
			return "탐험가를 우클릭해 직접 공격을 지정하세요.\n스킬 1을 눌러도 직접 조종 액션으로 인정됩니다."
	return str(line.get("text", "")).replace("{{player_name}}", _onboarding_player_name())

func _onboarding_log_line(line: Dictionary) -> String:
	var speaker = _onboarding_speaker_name(str(line.get("speaker", "")))
	if speaker == "" or speaker == "나레이션":
		return _onboarding_line_text(line)
	return "%s: %s" % [speaker, _onboarding_line_text(line)]

func _onboarding_speaker_name(speaker_id: String) -> String:
	if speaker_id == "NARRATOR":
		return "나레이션"
	if speaker_id == "CHR_DARKLORD_PLAYER":
		return _onboarding_player_name()
	var character = DataRegistry.character(speaker_id)
	if not character.is_empty():
		return str(character.get("display_name", speaker_id))
	return speaker_id

func _onboarding_speaker_portrait_path(speaker_id: String, emotion: String = "") -> String:
	var portrait = _onboarding_speaker_portrait_data(speaker_id)
	if portrait.is_empty():
		return ""
	var selected_emotion = _onboarding_portrait_emotion_key(portrait, emotion)
	var variants: Dictionary = portrait.get("variants", {})
	if selected_emotion != "" and variants.has(selected_emotion):
		return str(variants[selected_emotion])
	return str(portrait.get("base", ""))

func _onboarding_speaker_accent(speaker_id: String) -> Color:
	var portrait = _onboarding_speaker_portrait_data(speaker_id)
	if portrait.is_empty():
		return Color("#57485e")
	return Color(str(portrait.get("accent", "#57485e")))

func _onboarding_speaker_portrait_data(speaker_id: String) -> Dictionary:
	var character = DataRegistry.character(speaker_id)
	if character.is_empty():
		return {}
	var portrait = character.get("portrait", {})
	if portrait is Dictionary:
		return portrait
	return {}

func _onboarding_portrait_emotion_key(portrait: Dictionary, emotion: String) -> String:
	if emotion == "":
		return ""
	var aliases: Dictionary = portrait.get("emotion_aliases", {})
	return str(aliases.get(emotion, emotion))

func _onboarding_dialogue_scene_path(line: Dictionary) -> String:
	var stage_id = str(line.get("stage", onboarding_stage_id))
	return str(ONBOARDING_SCENE_ILLUSTRATIONS.get(stage_id, ONBOARDING_SCENE_ILLUSTRATIONS["default"]))

func _onboarding_player_name() -> String:
	if GameState.player_name.strip_edges() == "":
		return "신입 마왕"
	return GameState.player_name

func _onboarding_set_stage(stage_id: String) -> void:
	onboarding_stage_id = stage_id
	GameState.onboarding_stage = stage_id

func _onboarding_management_stage_for_day(day: int) -> String:
	match day:
		1:
			return "LV03_DAY01_MANAGEMENT_TUTORIAL"
		2:
			return "LV06_DAY02_MANAGEMENT_TREASURE"
		3:
			return "LV09_DAY03_MANAGEMENT_HERO"
		_:
			return "LV12_DAY04_RAID_PREVIEW"

func _onboarding_battle_stage_for_day(day: int) -> String:
	match day:
		1:
			return "LV04_DAY01_BATTLE_EXPLORER"
		2:
			return "LV07_DAY02_BATTLE_THIEF"
		3:
			return "LV10_DAY03_BATTLE_HERO"
		_:
			return ""

func _onboarding_result_stage_for_day(day: int) -> String:
	match day:
		1:
			return "LV05_DAY01_RESULT"
		2:
			return "LV08_DAY02_RESULT"
		3:
			return "LV11_DAY03_RESULT_DEMO_CLEAR"
		_:
			return ""

func _raid_unlocked() -> bool:
	return GameState.day >= 4 or GameState.onboarding_complete or not completed_raids.is_empty()

func _campaign_day_info(day: int = 0) -> Dictionary:
	var target_day = GameState.day if day <= 0 else day
	if DataRegistry.has_method("campaign_day"):
		return DataRegistry.campaign_day(target_day)
	return {}

func _is_regular_campaign_final_battle(day: int = 0) -> bool:
	var target_day := GameState.day if day <= 0 else day
	return target_day == REGULAR_CAMPAIGN_FINAL_DAY and bool(_campaign_day_info(target_day).get("final_battle", false))

func _campaign_final_preparation_flag_enabled(flag: String) -> bool:
	if flag == "":
		return true
	if flag == "day29_final_preparation_confirmed":
		return campaign_final_preparation_confirmed
	return false

func _castle_stage_info(stage_id: String = "") -> Dictionary:
	var target_id := castle_art_stage if stage_id == "" else stage_id
	if DataRegistry.has_method("castle_evolution_stage"):
		return DataRegistry.castle_evolution_stage(target_id)
	return {}

func _castle_stage_index(stage_id: String = "") -> int:
	return int(_castle_stage_info(stage_id).get("index", 1))

func _castle_stage_display_line(stage_id: String = "") -> String:
	var info := _castle_stage_info(stage_id)
	if info.is_empty():
		return "마왕성 단계 정보 없음"
	return "마왕성 %d/4 · %s" % [int(info.get("index", 1)), str(info.get("display_name", "마왕성"))]

func _castle_stage_subtitle(stage_id: String = "") -> String:
	return str(_castle_stage_info(stage_id).get("subtitle", ""))

func _castle_evolution_completed_today() -> bool:
	return last_castle_evolution_day == GameState.day and last_castle_evolution_day > 0

func _castle_evolution_target_for_day(day: int) -> String:
	if not DataRegistry.has_method("castle_evolution_stage_ids"):
		return ""
	for stage_id_value in DataRegistry.castle_evolution_stage_ids():
		var stage_id := str(stage_id_value)
		var info: Dictionary = DataRegistry.castle_evolution_stage(stage_id)
		if int(info.get("unlock_after_victory_day", -1)) == day:
			return stage_id
	return ""

func _castle_flag_enabled(flag: String) -> bool:
	match flag:
		"":
			return true
		"campaign_stage_two_unlock_ready":
			return campaign_stage_two_unlock_ready
		"campaign_chapter_three_clear":
			return campaign_chapter_three_clear
		"campaign_final_upgrade_ready":
			return campaign_final_upgrade_ready
	return false

func _castle_evolution_will_complete_for_day(day: int) -> bool:
	var stage_id := _castle_evolution_target_for_day(day)
	if stage_id == "" or _castle_stage_index(stage_id) <= _castle_stage_index():
		return false
	var required_flag := str(_castle_stage_info(stage_id).get("required_flag", ""))
	if _castle_flag_enabled(required_flag):
		return true
	var day_info := _campaign_day_info(day)
	match required_flag:
		"campaign_stage_two_unlock_ready":
			return bool(day_info.get("stage_two_unlock_review", false)) and _stage_two_upgrade_budget_ready()
		"campaign_chapter_three_clear":
			return bool(day_info.get("chapter_three_clear", false))
		"campaign_final_upgrade_ready":
			return bool(day_info.get("final_upgrade_ready", false))
	return false

func _castle_evolution_result_line(day: int) -> String:
	if not _castle_evolution_will_complete_for_day(day):
		return ""
	var stage_id := _castle_evolution_target_for_day(day)
	var info := _castle_stage_info(stage_id)
	var buildings: Array = info.get("new_buildings", [])
	return "마왕성 진화: %d단계 %s · 구역 %d · 시설 Lv.%d · 신규 %d곳 (castle_evolution_stage_%02d)" % [
		int(info.get("index", 1)),
		str(info.get("display_name", "마왕성")),
		int(info.get("area_room_count", 0)),
		int(info.get("facility_level_cap", 2)),
		buildings.size(),
		int(info.get("index", 1))
	]

func _sync_castle_stage_content() -> void:
	if not DataRegistry.has_method("castle_stage_expansion"):
		return
	for stage_id_value in DataRegistry.castle_evolution_stage_ids():
		var stage_id := str(stage_id_value)
		if _castle_stage_index(stage_id) > _castle_stage_index():
			continue
		var addition: Dictionary = DataRegistry.castle_stage_expansion(stage_id)
		var added_rooms: Dictionary = addition.get("rooms", {})
		for room_id_value in added_rooms.keys():
			var room_id := str(room_id_value)
			if not rooms.has(room_id):
				rooms[room_id] = added_rooms[room_id].duplicate(true)
	_apply_castle_stage_room_upgrades()

func _apply_castle_stage_room_upgrades() -> void:
	var info := _castle_stage_info()
	var desired_hp_bonus := int(info.get("facility_hp_bonus", 0))
	var desired_capacity_bonus := int(info.get("facility_capacity_bonus", 0))
	for room_id_value in rooms.keys():
		var room_id := str(room_id_value)
		var room: Dictionary = rooms[room_id]
		var facility_id := str(room.get("facility_role", ""))
		if facility_id in ["", "entry", "trap", "corridor", "core", "build_slot"]:
			room["castle_stage_level"] = _castle_stage_index()
			continue
		var applied_hp_bonus := int(room.get("castle_stage_hp_bonus", 0))
		var applied_capacity_bonus := int(room.get("castle_stage_capacity_bonus", 0))
		room["hp"] = max(1, int(room.get("hp", 1)) + desired_hp_bonus - applied_hp_bonus)
		room["max_monsters"] = max(1, int(room.get("max_monsters", 1)) + desired_capacity_bonus - applied_capacity_bonus)
		room["castle_stage_hp_bonus"] = desired_hp_bonus
		room["castle_stage_capacity_bonus"] = desired_capacity_bonus
		room["castle_stage_level"] = _castle_stage_index()
	var desired_throne_hp := int(info.get("throne_max_hp", GameState.demon_lord_max_hp))
	if desired_throne_hp != GameState.demon_lord_max_hp:
		var hp_delta := desired_throne_hp - GameState.demon_lord_max_hp
		GameState.demon_lord_max_hp = desired_throne_hp
		GameState.demon_lord_hp = clampi(GameState.demon_lord_hp + max(0, hp_delta), 0, desired_throne_hp)
	# 왕좌는 일반 시설 강화 대상에서 제외되므로 방 정보의 체력도 별도로 맞춘다.
	# 이 값이 어긋나면 상단 성 체력과 왕좌 방 상세 정보가 서로 다르게 표시된다.
	for room_id_value in rooms.keys():
		var core_room_id := str(room_id_value)
		var core_room: Dictionary = rooms[core_room_id]
		if str(core_room.get("facility_role", "")) == "core":
			core_room["hp"] = desired_throne_hp
			core_room["castle_stage_level"] = _castle_stage_index()

func _castle_facility_scale(key: String, fallback: float = 1.0) -> float:
	return float(_castle_stage_info().get(key, fallback))

func _castle_area_summary() -> String:
	var info := _castle_stage_info()
	return "구역 %d · 시설 Lv.%d" % [int(info.get("area_room_count", 0)), int(info.get("facility_level_cap", 2))]

func _apply_castle_evolution_for_day(day: int) -> bool:
	var stage_id := _castle_evolution_target_for_day(day)
	if stage_id == "" or _castle_stage_index(stage_id) <= _castle_stage_index():
		return false
	var required_flag := str(_castle_stage_info(stage_id).get("required_flag", ""))
	if not _castle_flag_enabled(required_flag):
		return false
	last_castle_evolution_from_stage = castle_art_stage
	castle_art_stage = stage_id
	last_castle_evolution_day = day
	if not castle_evolution_history.has(stage_id):
		castle_evolution_history.append(stage_id)
	_sync_castle_stage_content()
	_setup_dungeon_graph()
	_relocate_invalid_monsters()
	if quarter_renderer != null and quarter_renderer.has_method("refresh_layout"):
		quarter_renderer.refresh_layout()
	_log("%s으로 진화했습니다." % _castle_stage_display_line())
	queue_redraw()
	return true

func _campaign_required_raid_choice_group(day: int = 0) -> String:
	return str(_campaign_day_info(day).get("required_raid_choice_group", ""))

func _campaign_required_raid_choice_label(day: int = 0) -> String:
	return str(_campaign_day_info(day).get("required_raid_choice_label", "원정 선택"))

func _campaign_required_raid_choice_start_label(day: int = 0) -> String:
	return str(_campaign_day_info(day).get("required_raid_choice_start_label", "원정 선택 후 전투"))

func _campaign_required_raid_choice_prompt(day: int = 0) -> String:
	return str(_campaign_day_info(day).get("required_raid_choice_prompt", "[원정 선택]에서 오늘 계획 하나를 먼저 확정하세요."))

func _campaign_required_raid_choice_log(day: int = 0) -> String:
	return str(_campaign_day_info(day).get("required_raid_choice_log", "DAY %d 전투 전에 원정 계획 하나를 확정하세요." % (GameState.day if day <= 0 else day)))

func _completed_raid_choice_id(choice_group: String) -> String:
	if choice_group == "":
		return ""
	for raid_id_value in DataRegistry.raid_missions.keys():
		var raid_id := str(raid_id_value)
		var mission: Dictionary = DataRegistry.raid_mission(raid_id)
		if str(mission.get("choice_group", "")) == choice_group and completed_raids.has(raid_id):
			return raid_id
	return ""

func _campaign_raid_choice_pending(day: int = 0) -> bool:
	var choice_group := _campaign_required_raid_choice_group(day)
	return choice_group != "" and _completed_raid_choice_id(choice_group) == ""

func _raid_choice_locked(mission_id: String) -> bool:
	var mission: Dictionary = DataRegistry.raid_mission(mission_id)
	var choice_group := str(mission.get("choice_group", ""))
	var completed_choice := _completed_raid_choice_id(choice_group)
	return completed_choice != "" and completed_choice != mission_id

func _campaign_notice_cast_line(day: int = 0) -> String:
	var info = _campaign_day_info(day)
	var override_line := str(info.get("cast_notice_line", ""))
	if override_line != "":
		return override_line
	var cast: Array = info.get("cast", [])
	var names: Array[String] = []
	for entry_value in cast:
		if not (entry_value is Dictionary):
			continue
		var entry: Dictionary = entry_value
		var character_id = str(entry.get("character_id", ""))
		var character: Dictionary = DataRegistry.character(character_id)
		names.append(str(entry.get("display_name", character.get("display_name", character_id))))
	if names.is_empty():
		return ""
	return "등장: %s" % ", ".join(names)

func _campaign_notice_summary(day: int = 0) -> String:
	var info = _campaign_day_info(day)
	var compact_summary := str(info.get("compact_management_summary", ""))
	var lines: Array[String] = [compact_summary if compact_summary != "" else str(info.get("summary", ""))]
	var completed_raid_summaries = info.get("completed_raid_summary_lines", {})
	if completed_raid_summaries is Dictionary:
		for raid_id_value in completed_raid_summaries.keys():
			var raid_id = str(raid_id_value)
			if completed_raids.has(raid_id):
				lines.append(str(completed_raid_summaries[raid_id]))
				break
	var security_summaries = info.get("security_grade_summary_lines", {})
	if security_summaries is Dictionary and last_security_grade != "" and security_summaries.has(last_security_grade):
		lines.append(str(security_summaries[last_security_grade]))
	return "\n".join(lines)

func _campaign_notice_enemy_line(day: int = 0) -> String:
	var info = _campaign_day_info(day)
	var compact_line := str(info.get("compact_enemy_notice_line", ""))
	if compact_line != "":
		return compact_line
	var completed_raid_lines = info.get("completed_raid_enemy_notice_lines", {})
	if completed_raid_lines is Dictionary:
		for raid_id_value in completed_raid_lines.keys():
			var raid_id := str(raid_id_value)
			if completed_raids.has(raid_id):
				return str(completed_raid_lines[raid_id])
	var override_line := str(info.get("enemy_notice_line", ""))
	if override_line != "":
		return override_line
	var enemy_plan: Array = info.get("enemy_plan", [])
	var parts: Array[String] = []
	for entry_value in enemy_plan:
		if not (entry_value is Dictionary):
			continue
		var entry: Dictionary = entry_value
		var enemy_id = str(entry.get("enemy_id", ""))
		var enemy: Dictionary = DataRegistry.enemy(enemy_id)
		parts.append("%s x%d" % [str(enemy.get("display_name", enemy_id)), int(entry.get("count", 0))])
	if parts.is_empty():
		return ""
	return "출현: %s" % " / ".join(parts)

func _campaign_notice_monster_line(day: int = 0) -> String:
	var info = _campaign_day_info(day)
	var monster_plan: Array = info.get("monster_plan", [])
	var names: Array[String] = []
	for entry_value in monster_plan:
		if not (entry_value is Dictionary):
			continue
		var entry: Dictionary = entry_value
		var monster_id = str(entry.get("monster_id", ""))
		var monster: Dictionary = DataRegistry.monster(monster_id)
		names.append(str(monster.get("display_name", monster_id)))
	if names.is_empty():
		return ""
	return "몬스터: %s" % ", ".join(names)

func _campaign_speaker_portrait_path(character_id: String, emotion: String = "") -> String:
	return _onboarding_speaker_portrait_path(character_id, emotion)

func _campaign_speaker_accent(character_id: String) -> Color:
	return _onboarding_speaker_accent(character_id)

func _apply_campaign_day_entry(day: int) -> void:
	var info = _campaign_day_info(day)
	if info.is_empty():
		return
	if bool(info.get("facility_upgrade_unlocked", false)):
		facility_upgrade_unlocked = true
	if campaign_seen_day_intros.has(day):
		return
	campaign_seen_day_intros[day] = true
	var completed_raid_lines = info.get("completed_raid_management_lines", {})
	if completed_raid_lines is Dictionary:
		for raid_id_value in completed_raid_lines.keys():
			var raid_id = str(raid_id_value)
			if completed_raids.has(raid_id):
				_log(str(completed_raid_lines[raid_id]))
				break
	var security_lines = info.get("security_grade_management_lines", {})
	if security_lines is Dictionary and last_security_grade != "" and security_lines.has(last_security_grade):
		_log(str(security_lines[last_security_grade]))
	for line_value in info.get("management_lines", []):
		_log(str(line_value))

func _current_security_grade() -> String:
	if thieves_spawned_this_battle <= 0:
		return ""
	if thieves_escaped_this_battle > 0:
		return "D"
	if thieves_completed_theft_this_battle > 0:
		return "C"
	if thieves_reached_treasure_this_battle > 0:
		return "A"
	return "S"

func _current_security_result_line() -> String:
	match _current_security_grade():
		"D":
			return "보안 평가 D: 도둑 %d명 침입 / %d명 약탈 후 탈출" % [thieves_reached_treasure_this_battle, thieves_escaped_this_battle]
		"C":
			return "보안 평가 C: 도둑 %d명 침입 / 보물 회수 전 격퇴" % thieves_reached_treasure_this_battle
		"A":
			return "보안 평가 A: 도둑 %d명 침입 / 약탈 전에 저지" % thieves_reached_treasure_this_battle
		"S":
			return "보안 평가 S: 도둑 %d명 모두 보물 방 진입 전 격퇴" % thieves_spawned_this_battle
	return ""

func _apply_campaign_combat_entry(day: int) -> void:
	var info = _campaign_day_info(day)
	if info.is_empty() or campaign_seen_combat_intros.has(day):
		return
	campaign_seen_combat_intros[day] = true
	var completed_raid_lines = info.get("completed_raid_combat_start_lines", {})
	if completed_raid_lines is Dictionary:
		for raid_id_value in completed_raid_lines.keys():
			var raid_id := str(raid_id_value)
			if completed_raids.has(raid_id):
				_log(str(completed_raid_lines[raid_id]))
				break
	for line_value in info.get("combat_start_lines", []):
		_log(str(line_value))

func _reset_campaign_combat_timed_lines() -> void:
	campaign_combat_timed_lines_fired.clear()

func _update_campaign_combat_timed_lines() -> void:
	var info := _campaign_day_info()
	var timed_lines: Array = info.get("combat_timed_lines", [])
	for index in range(timed_lines.size()):
		if campaign_combat_timed_lines_fired.has(index):
			continue
		var entry = timed_lines[index]
		if not (entry is Dictionary) or combat_time < float(entry.get("time", 0.0)):
			continue
		campaign_combat_timed_lines_fired[index] = true
		var line := str(entry.get("text", ""))
		if line != "":
			_log(line)

func _campaign_result_lines(win: bool) -> Array:
	var lines := []
	if not win:
		var defeat_info: Dictionary = _campaign_day_info().get("defeat_ending", {})
		if _is_regular_campaign_final_battle() and not defeat_info.is_empty():
			for line_value in defeat_info.get("lines", []):
				lines.append(str(line_value))
		return lines
	var info = _campaign_day_info()
	if bool(info.get("security_review", false)):
		if _current_security_grade() == "D":
			lines.append("니아: 금화도 챙겼고 퇴로도 열렸네. 보안 평가는 D야. (nia_security_review_d)")
		elif _current_security_grade() == "C":
			lines.append("니아: 보물은 만졌지만 나가지는 못했네. 보안 평가는 C. (nia_security_review_c)")
		elif _current_security_grade() == "A":
			lines.append("니아: 보물 방까지는 갔지만 손은 못 댔어. 보안 평가는 A. (nia_security_review_a)")
		elif _current_security_grade() == "S":
			lines.append("니아: 이번엔 보물 방 문도 못 봤네. 보안 평가 S, 인정할게. (nia_security_review_s)")
	if bool(info.get("stage_two_upgrade_review", false)):
		var cost = _stage_two_upgrade_cost()
		if GameState.can_pay(cost):
			lines.append("성 업그레이드 심사: Stage 02 비용 마련 완료. (stage_two_upgrade_funded)")
		else:
			lines.append("성 업그레이드 심사: 비용 부족. 필요: %s. (stage_two_upgrade_unfunded)" % _cost_label(cost))
	if bool(info.get("stage_two_unlock_review", false)):
		var cost = _stage_two_upgrade_cost()
		if _stage_two_upgrade_budget_ready():
			lines.append("Stage 02 해금: 비용 심사와 셀렌 점검을 통과해 다음 성 단계 적용 준비가 끝났다. (stage_two_unlock_ready)")
		else:
			lines.append("Stage 02 해금 보류: 심사 비용을 다시 확보해야 한다. 필요: %s. (stage_two_unlock_blocked)" % _cost_label(cost))
	var castle_evolution_line := _castle_evolution_result_line(GameState.day)
	if castle_evolution_line != "":
		lines.append(castle_evolution_line)
	var raid_choice_id := _completed_raid_choice_id(str(info.get("required_raid_choice_group", "")))
	if raid_choice_id != "":
		var raid_choice: Dictionary = DataRegistry.raid_mission(raid_choice_id)
		var defense_result_line := str(raid_choice.get("defense_result_line", ""))
		if defense_result_line != "":
			lines.append(defense_result_line)
	var completed_raid_result_lines = info.get("completed_raid_result_lines", {})
	if completed_raid_result_lines is Dictionary:
		for raid_id_value in completed_raid_result_lines.keys():
			var completed_raid_id := str(raid_id_value)
			if completed_raids.has(completed_raid_id):
				lines.append(str(completed_raid_result_lines[completed_raid_id]))
				break
	for line_value in info.get("result_lines", []):
		lines.append(str(line_value))
	return lines

func _apply_campaign_result_flags(win: bool) -> void:
	var info = _campaign_day_info()
	if not win:
		if _is_regular_campaign_final_battle():
			campaign_final_battle_outcome = "defeat"
			campaign_finale_defeat_seen = true
		return
	if info.is_empty():
		return
	var security_grade := _current_security_grade()
	if security_grade != "":
		last_security_grade = security_grade
	if bool(info.get("chapter_one_clear", false)):
		campaign_chapter_one_clear = true
	if bool(info.get("stage_two_prepared", false)):
		campaign_stage_two_prepared = true
	if bool(info.get("chapter_two_started", false)):
		campaign_chapter_two_started = true
	if bool(info.get("stage_two_upgrade_review", false)) and GameState.can_pay(_stage_two_upgrade_cost()):
		campaign_stage_two_upgrade_funded = true
	if bool(info.get("stage_two_unlock_review", false)) and _stage_two_upgrade_budget_ready():
		campaign_stage_two_unlock_ready = true
	if bool(info.get("chapter_three_clear", false)):
		campaign_chapter_three_clear = true
	if bool(info.get("chapter_four_clear", false)):
		campaign_chapter_four_clear = true
	if bool(info.get("final_chapter_unlocked", false)):
		campaign_final_chapter_unlocked = true
	if bool(info.get("final_upgrade_ready", false)):
		campaign_final_upgrade_ready = true
	if str(info.get("final_preparation_flag", "")) == "day29_final_preparation_confirmed":
		campaign_final_preparation_confirmed = true
	if _is_regular_campaign_final_battle():
		campaign_completed = true
		campaign_final_battle_outcome = "victory"
		_record_final_run_metrics()
		_resolve_campaign_ending()
	_apply_castle_evolution_for_day(GameState.day)

func _stage_two_upgrade_cost() -> Dictionary:
	var info = _campaign_day_info()
	var cost = info.get("stage_two_upgrade_cost", {})
	if cost is Dictionary and not cost.is_empty():
		return cost
	return {"gold": 720, "infamy": 720}

func _stage_two_upgrade_cost_label() -> String:
	return _cost_label(_stage_two_upgrade_cost())

func _stage_two_upgrade_budget_ready() -> bool:
	return campaign_stage_two_upgrade_funded and GameState.can_pay(_stage_two_upgrade_cost())

func _stage_two_upgrade_required_for_current_day() -> bool:
	var info = _campaign_day_info()
	return bool(info.get("requires_stage_two_upgrade_funded", false))

func _has_defense_wave_for_day(day: int) -> bool:
	var key = "day_%d" % day
	if not DataRegistry.waves.has(key):
		return false
	var entries = DataRegistry.waves.get(key, [])
	return entries is Array and not entries.is_empty()

func _enter_campaign_management_day(show_intro: bool = true) -> void:
	var info := _campaign_day_info()
	var first_intro := show_intro and not campaign_seen_day_intros.has(GameState.day)
	var management_dialogue: Array = info.get("management_dialogue", [])
	if show_intro:
		_apply_campaign_day_entry(GameState.day)
	_set_screen(Constants.SCREEN_MANAGEMENT)
	if first_intro and not management_dialogue.is_empty():
		var dialogue_entries: Array = management_dialogue.duplicate(true)
		var dialogue_header := str(info.get("management_dialogue_header", "정규 캠페인"))
		for index in range(dialogue_entries.size()):
			if not (dialogue_entries[index] is Dictionary):
				continue
			dialogue_entries[index]["dialogue_header"] = dialogue_header
			if index == dialogue_entries.size() - 1:
				dialogue_entries[index]["next_label"] = "관리 화면"
		_onboarding_begin_dialogue(dialogue_entries, Constants.SCREEN_MANAGEMENT)

func _confirm_management_only_day() -> void:
	var info := _campaign_day_info()
	if not bool(info.get("management_only", false)):
		_log("오늘은 관리 전용 일정이 아닙니다.")
		return
	if _campaign_final_declaration_pending():
		_log("DAY 29 최종 준비 전에 '재전 약속' 또는 '성 수호' 선언을 하나 선택하세요.")
		return
	if map_editor_active:
		_log("맵 편집을 저장하거나 취소한 뒤 최종 준비를 확정하세요.")
		return
	if bool(info.get("requires_final_upgrade", false)) and not campaign_final_upgrade_ready:
		_log("최종 준비는 Stage 04 대마왕성 강화를 완료한 뒤 확정할 수 있습니다.")
		return
	if not _ensure_required_main_route_for_current_layout("최종 준비 확정"):
		return
	_clear_management_action_mode(false)
	last_growth_summary.clear()
	result_growth_reviewed = true
	result_growth_choice_monster_id = ""
	result_growth_choice_applied = false
	last_growth_choice_summary.clear()
	var lines := _campaign_result_lines(true)
	_apply_campaign_result_flags(true)
	result_summary = {
		"win": true,
		"management_only": true,
		"lines": lines,
		"growth": [],
		"metrics": {"management_only": true}
	}
	_log("DAY %d 최종 준비를 확정했습니다. 전투 없이 결산으로 이동합니다." % GameState.day)
	_set_screen(Constants.SCREEN_RESULT)


func _campaign_final_declaration_required() -> bool:
	return GameState.day == 29 and bool(_campaign_day_info().get("management_only", false))


func _campaign_final_declaration_pending() -> bool:
	return _campaign_final_declaration_required() and str(run_metrics_tracker.metrics.get("decision.day29", "")) == ""


func _campaign_final_declaration_id() -> String:
	return str(run_metrics_tracker.metrics.get("decision.day29", ""))


func _set_campaign_final_declaration(declaration_id: String) -> void:
	if not _campaign_final_declaration_required() or declaration_id not in ["rival_pact", "castle_oath"]:
		return
	run_metrics_tracker.set_value("decision.day29", declaration_id)
	if declaration_id == "rival_pact":
		run_metrics_tracker.set_value("relation.leon", 70.0)
		run_metrics_tracker.set_value("style.honor", 65.0)
		_log("최후 선언: 레온과 이번 결전 뒤에도 다시 겨룰 것을 약속했습니다.")
	else:
		_log("최후 선언: 어떤 도전자보다 마왕성과 식구들을 먼저 지키겠다고 맹세했습니다.")
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _campaign_ending_data() -> Dictionary:
	var info := _campaign_day_info(REGULAR_CAMPAIGN_FINAL_DAY)
	if campaign_final_battle_outcome == "defeat":
		var defeat_ending = info.get("defeat_ending", {})
		return defeat_ending if defeat_ending is Dictionary else {}
	_record_final_run_metrics()
	_resolve_campaign_ending()
	var original = info.get("victory_ending", {})
	if resolved_campaign_ending_id == "true_demon_castle":
		var original_ending: Dictionary = original.duplicate(true) if original is Dictionary else {}
		var fallback_rule := DataRegistry.ending_rule("true_demon_castle")
		original_ending["id"] = "true_demon_castle"
		original_ending["illustration"] = str(fallback_rule.get("illustration", ""))
		original_ending["emblem"] = str(fallback_rule.get("emblem", ""))
		original_ending["thumbnail"] = str(fallback_rule.get("thumbnail", ""))
		return original_ending
	var rule := DataRegistry.ending_rule(resolved_campaign_ending_id)
	if rule.is_empty():
		return original if original is Dictionary else {}
	return {
		"id": resolved_campaign_ending_id,
		"title": "엔딩 · %s" % str(rule.get("display_name", resolved_campaign_ending_id)),
		"illustration": str(rule.get("illustration", "")),
		"emblem": str(rule.get("emblem", "")),
		"thumbnail": str(rule.get("thumbnail", "")),
		"lines": rule.get("lines", []).duplicate(),
		"sign_text": str(rule.get("sign_text", "여기서부터 진짜 마왕성.")),
		"post_campaign_mode": "continue_stage04"
	}

func _reset_run_metrics() -> void:
	var errors := run_metrics_tracker.setup(DataRegistry.run_metric_definitions)
	if not errors.is_empty():
		push_error("Run metric definitions are invalid: %s" % [errors])
	resolved_campaign_ending_id = "true_demon_castle"

func _record_final_run_metrics() -> void:
	run_metrics_tracker.set_value("infamy.final", GameState.infamy)
	var max_hp: float = maxf(1.0, float(GameState.demon_lord_max_hp))
	var throne_hp_ratio: float = float(GameState.demon_lord_hp) / max_hp
	run_metrics_tracker.set_value("castle.throne_hp_ratio", throne_hp_ratio)
	run_metrics_tracker.set_value("castle.treasure_lost", treasure_gold_stolen_this_battle)
	run_metrics_tracker.set_value("castle.facility_disables", facility_disables_this_battle)
	var security_scores := {"S": 100.0, "A": 80.0, "C": 45.0, "D": 15.0}
	if security_scores.has(last_security_grade):
		run_metrics_tracker.set_value("castle.security_score", security_scores[last_security_grade])
	var bond_total := 0.0
	var bond_count := 0
	var high_bond_count := 0
	for roster_value in monster_roster.values():
		if not (roster_value is Dictionary):
			continue
		var roster: Dictionary = roster_value
		var actual_bond := float(roster.get("bond", 0))
		bond_total += actual_bond
		bond_count += 1
		if actual_bond >= 65.0:
			high_bond_count += 1
	var average_bond := bond_total / float(max(1, bond_count))
	run_metrics_tracker.set_value("bond.core_average", average_bond)
	run_metrics_tracker.set_value("bond.high_rank_count", high_bond_count)
	run_metrics_tracker.set_value("style.family", average_bond)
	var facility_level_total := 0.0
	var facility_count := 0
	for room_value in rooms.values():
		if not (room_value is Dictionary):
			continue
		var room: Dictionary = room_value
		if str(room.get("facility_id", room.get("facility", ""))) == "":
			continue
		facility_level_total += float(room.get("facility_level", 1))
		facility_count += 1
	var average_facility_level := facility_level_total / float(max(1, facility_count))
	var security_score := float(run_metrics_tracker.metrics.get("castle.security_score", 0.0))
	var fortress_style: float = clampf(throne_hp_ratio * 45.0 + security_score * 0.35 + average_facility_level * 5.0, 0.0, 100.0)
	run_metrics_tracker.set_value("style.fortress", fortress_style)
	var high_risk_raid_ids := ["d16_supply_ambush", "d18_seal_smuggling_tunnel", "d28_engineer_supply_disruption"]
	var high_risk_successes := 0
	for raid_id in high_risk_raid_ids:
		if completed_raids.has(raid_id):
			high_risk_successes += 1
	run_metrics_tracker.set_value("raid.high_risk_successes", high_risk_successes)
	run_metrics_tracker.set_value("style.dread", clamp(float(GameState.infamy) / 20.0 + float(high_risk_successes) * 8.0, 0.0, 100.0))
	var directive_ids: Dictionary = {global_directive: true}
	for directive_id in room_directives.values():
		if str(directive_id) != "":
			directive_ids[str(directive_id)] = true
	run_metrics_tracker.set_value("directive.variety_ratio", clamp(float(directive_ids.size()) / 5.0, 0.0, 1.0))
	run_metrics_tracker.set_value("relation.rolo", clamp(float(completed_raids.size()) * 12.0, 0.0, 100.0))

func _resolve_campaign_ending() -> String:
	var result := EndingConditionEvaluatorScript.resolve(DataRegistry.ending_rules, run_metrics_tracker.snapshot())
	if not bool(result.get("ok", false)):
		push_error("Ending resolution failed: %s" % str(result.get("error", "unknown error")))
		resolved_campaign_ending_id = "true_demon_castle"
	else:
		resolved_campaign_ending_id = str(result.get("ending_id", "true_demon_castle"))
	return resolved_campaign_ending_id

func _show_campaign_ending() -> void:
	if not campaign_completed or campaign_final_battle_outcome != "victory":
		_log("최종 공성전 승리 후 엔딩을 확인할 수 있습니다.")
		return
	_set_screen(Constants.SCREEN_ENDING)

func _build_campaign_ending_ui() -> void:
	var info := _campaign_day_info(REGULAR_CAMPAIGN_FINAL_DAY)
	var ending := _campaign_ending_data()
	var screen := _onboarding_screen_panel(Color("#050407ff"))
	_onboarding_add_scene_illustration(screen, Rect2(0, 0, 1920, 1080), str(ending.get("illustration", "")))
	_onboarding_child_panel(screen, Rect2(1030, 70, 820, 880), Color("#0b0711dc"), Color("#9b6a27"))
	var ending_emblem_path := str(ending.get("emblem", ""))
	if ending_emblem_path != "":
		var ending_emblem: TextureRect = hud.texture(screen, ending_emblem_path, Rect2(1062, 104, 86, 86))
		ending_emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hud.label(screen, str(ending.get("title", "엔딩 · 진짜 마왕성")), Vector2(1150, 112), Vector2(630, 78), 38, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(screen, "DAY %d 최종 공성전 완료" % REGULAR_CAMPAIGN_FINAL_DAY, Vector2(1140, 194), Vector2(600, 34), 19, Color("#c6a968"), HORIZONTAL_ALIGNMENT_CENTER)
	var style_icon: TextureRect = hud.texture(screen, "res://assets/sprites/ui/legacy/ui_icon_style.png", Rect2(1110, 224, 32, 32))
	style_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hud.label(screen, "%d회차 · 엔딩 도감 %d/5" % [campaign_cycle_index, _known_ending_count()], Vector2(1140, 226), Vector2(600, 28), 16, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
	var story_panel := _onboarding_child_panel(screen, Rect2(1090, 270, 700, 380), Color("#100d14c9"), Color("#57485e"))
	var sign_text := str(ending.get("sign_text", info.get("ending_sign_text", "여기서부터 진짜 마왕성.")))
	var story_lines: Array[String] = []
	for line_value in ending.get("lines", []):
		var line := str(line_value)
		if sign_text != "" and line.ends_with(sign_text):
			continue
		story_lines.append(line)
	hud.label(story_panel, "\n\n".join(story_lines), Vector2(42, 32), Vector2(616, 316), 20, Color("#e9e0ed"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 8, 18)
	hud.label(screen, sign_text, Vector2(1090, 670), Vector2(700, 64), 30, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	var legacy_candidate := _campaign_legacy_candidate()
	var legacy_name := str(legacy_candidate.get("display_name", "몬스터"))
	hud.label(screen, "계승 몬스터는 레벨·진화 대신 이번 승리의 기억 1개를 다음 회차에 가져갑니다.", Vector2(1090, 748), Vector2(700, 48), 16, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART)
	hud.button(screen, "후일담 계속", Rect2(1070, 842, 220, 64), Callable(self, "_continue_campaign_postgame"), 18, "PostgameContinueButton")
	hud.button(screen, "계승: %s 변경" % legacy_name, Rect2(1310, 842, 260, 64), Callable(self, "_cycle_campaign_legacy_candidate"), 18, "LegacyCandidateButton")
	hud.button(screen, "다음 회차 시작", Rect2(1590, 842, 220, 64), Callable(self, "_campaign_next_cycle_from_ending"), 18, "EndingNextCycleButton")

func _continue_campaign_postgame() -> void:
	campaign_postgame_active = true
	GameState.victory = false
	GameState.defeat = false
	_clear_units()
	_clear_effects()
	result_summary.clear()
	_log("후일담 관리 모드로 돌아왔습니다. Stage 04와 열한 구역은 그대로 유지됩니다.")
	_enter_campaign_management_day(false)

func _campaign_new_game_from_ending() -> void:
	if not _delete_campaign_save():
		_set_screen(Constants.SCREEN_TITLE)
		return
	_onboarding_reset_game()
	_onboarding_set_stage("LV00_TITLE_BOOT")
	_set_screen(Constants.SCREEN_TITLE)


func _campaign_legacy_candidate() -> Dictionary:
	var species_id := selected_monster_id
	if not monster_roster.has(species_id):
		var available_ids := _campaign_legacy_candidate_ids()
		if available_ids.is_empty():
			return {}
		species_id = available_ids[0]
	var candidate: Dictionary = monster_roster.get(species_id, {}).duplicate(true)
	candidate["species_id"] = species_id
	candidate["instance_id"] = NewCycleServiceScript.instance_id_for_species(species_id)
	candidate["display_name"] = str(DataRegistry.monster(species_id).get("display_name", species_id))
	return candidate


func _campaign_legacy_candidate_ids() -> Array[String]:
	var preferred_order: Array[String] = ["slime", "goblin", "imp", KOBOLD_SCOUT_ID]
	var result: Array[String] = []
	for species_id in preferred_order:
		if monster_roster.has(species_id):
			result.append(species_id)
	return result


func _cycle_campaign_legacy_candidate() -> void:
	var available_ids := _campaign_legacy_candidate_ids()
	if available_ids.is_empty():
		return
	var current_index := available_ids.find(selected_monster_id)
	selected_monster_id = available_ids[(current_index + 1) % available_ids.size()]
	_set_screen(Constants.SCREEN_ENDING)


func _campaign_next_cycle_from_ending() -> void:
	if not campaign_completed or campaign_final_battle_outcome != "victory":
		return
	_record_final_run_metrics()
	_resolve_campaign_ending()
	var legacy_candidate := _campaign_legacy_candidate()
	if legacy_candidate.is_empty():
		campaign_save_notice = "계승할 몬스터를 찾지 못해 다음 회차를 시작하지 않았습니다."
		_show_campaign_save_notice_overlay()
		return
	var next_profile := NewCycleServiceScript.complete_cycle(campaign_profile, resolved_campaign_ending_id, run_metrics_tracker.snapshot(), legacy_candidate)
	var next_legacy: Dictionary = next_profile.get("legacy_monster", {}).duplicate(true)
	var preserved_player_name := GameState.player_name
	_onboarding_reset_game()
	campaign_profile = next_profile
	campaign_cycle_index = int(campaign_profile.get("completed_cycles", 0)) + 1
	inherited_legacy_monster = next_legacy
	GameState.player_name = preserved_player_name
	GameState.day = 4
	GameState.onboarding_complete = true
	onboarding_enabled = false
	tutorial_gate_enabled = false
	tutorial_manager.active = false
	_unlock_kobold_scout_commander()
	NewCycleServiceScript.apply_legacy_memory(monster_roster, inherited_legacy_monster)
	_onboarding_set_stage("CAMPAIGN_CYCLE_%d_DAY_04" % campaign_cycle_index)
	_apply_campaign_day_entry(4)
	_log("%d회차를 DAY 04부터 시작합니다. %s의 승리 기억 1개를 계승했습니다." % [campaign_cycle_index, str(next_legacy.get("display_name", "몬스터"))])
	_set_screen(Constants.SCREEN_CYCLE_DOCTRINE)
	if not _write_campaign_v2_snapshot():
		campaign_save_notice = "다음 회차는 시작했지만 프로필 보조 저장에 실패했습니다. 현재 회차 자동 저장은 계속 유지됩니다."
		push_warning(campaign_save_notice)
		_show_campaign_save_notice_overlay()


func _write_campaign_v2_snapshot() -> bool:
	if not campaign_save_enabled or campaign_save_path != CampaignSaveStoreScript.SAVE_PATH:
		return true
	var checkpoint := current_screen
	var migration := CampaignSaveMigratorV1ToV2Script.migrate_inspection({
		"status": CampaignSaveStoreScript.STATUS_VALID,
		"payload": _campaign_save_payload(checkpoint),
		"summary": _campaign_save_summary(checkpoint),
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"saved_at_text": Time.get_datetime_string_from_system(false, true)
	}, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	if not bool(migration.get("ok", false)):
		return false
	var envelope: Dictionary = migration.get("envelope", {}).duplicate(true)
	envelope["profile"] = campaign_profile.duplicate(true)
	var active_run: Dictionary = envelope.get("active_run", {})
	active_run["cycle_index"] = campaign_cycle_index
	active_run["run_metrics"] = run_metrics_tracker.snapshot()
	envelope["active_run"] = active_run
	var write_result := CampaignSaveV2StoreScript.write(envelope, CampaignSaveV2StoreScript.SAVE_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	return bool(write_result.get("ok", false))

func _prepare_finale_retry() -> void:
	GameState.victory = false
	GameState.defeat = false
	GameState.demon_lord_hp = GameState.demon_lord_max_hp
	SignalBus.resources_changed.emit()
	campaign_postgame_active = false
	_clear_units()
	_clear_effects()
	_reset_engineer_combat_state()
	result_summary.clear()
	last_growth_summary.clear()
	result_growth_reviewed = false
	result_growth_choice_monster_id = ""
	result_growth_choice_applied = false
	last_growth_choice_summary.clear()
	_restore_final_expedition_modifier_for_retry()
	_log("DAY %d 최종 공성전을 다시 준비합니다. 왕좌 체력을 완전히 복구했습니다." % REGULAR_CAMPAIGN_FINAL_DAY)
	_enter_campaign_management_day(false)

func _restore_final_expedition_modifier_for_retry() -> bool:
	var mission_id := _completed_raid_choice_id("day28_final_expedition")
	if mission_id == "":
		return false
	var mission: Dictionary = DataRegistry.raid_mission(mission_id)
	var modifier: Dictionary = mission.get("next_defense_modifier", {})
	if modifier.is_empty():
		return false
	var modifier_id := str(modifier.get("id", mission_id))
	next_defense_modifiers[modifier_id] = modifier.duplicate(true)
	_log("DAY 30 재도전 원정 효과 복원: %s." % str(modifier.get("display_name", mission_id)))
	return true

func _active_defense_modifiers() -> Dictionary:
	var active: Dictionary = {}
	for key in next_defense_modifiers.keys():
		var modifier: Dictionary = next_defense_modifiers[key]
		var apply_on_day = int(modifier.get("apply_on_day", 0))
		if apply_on_day <= 0 or GameState.day >= apply_on_day:
			active[key] = modifier.duplicate(true)
	var campaign_modifiers = _campaign_day_info().get("completed_raid_defense_modifiers", {})
	if campaign_modifiers is Dictionary:
		for raid_id_value in campaign_modifiers.keys():
			var raid_id := str(raid_id_value)
			if not completed_raids.has(raid_id):
				continue
			var campaign_modifier = campaign_modifiers[raid_id]
			if campaign_modifier is Dictionary and not campaign_modifier.is_empty():
				active[str(campaign_modifier.get("id", "campaign_%s" % raid_id))] = campaign_modifier.duplicate(true)
			break
	return active

func _consume_defense_modifiers() -> void:
	var active_ids: Array = []
	for key in next_defense_modifiers.keys():
		var modifier: Dictionary = next_defense_modifiers[key]
		var apply_on_day = int(modifier.get("apply_on_day", 0))
		if apply_on_day <= 0 or GameState.day >= apply_on_day:
			active_ids.append(key)
	for key in active_ids:
		next_defense_modifiers.erase(key)

func _unlock_kobold_scout_commander() -> void:
	if monster_roster.has(KOBOLD_SCOUT_ID):
		monster_roster[KOBOLD_SCOUT_ID]["defense_enabled"] = false
		monster_roster[KOBOLD_SCOUT_ID]["raid_support"] = true
		if not monster_roster[KOBOLD_SCOUT_ID].has("bond"):
			monster_roster[KOBOLD_SCOUT_ID]["bond"] = 0
		if not (monster_roster[KOBOLD_SCOUT_ID].get("unlocked_memory_ids", []) is Array):
			monster_roster[KOBOLD_SCOUT_ID]["unlocked_memory_ids"] = []
		monster_roster[KOBOLD_SCOUT_ID]["bond_rank"] = _monster_bond_rank(int(monster_roster[KOBOLD_SCOUT_ID].get("bond", 0)))
		return
	monster_roster[KOBOLD_SCOUT_ID] = {
		"level": 1,
		"exp": 0,
		"bond": 0,
		"bond_rank": 0,
		"unlocked_memory_ids": [],
		"room": "barracks",
		"defense_enabled": false,
		"raid_support": true
	}
	_log("코볼트 척후대장 로로가 합류했습니다. 원정 보상 악명을 조금 더 올립니다.")

func _monster_available_for_defense(monster_id: String) -> bool:
	if not monster_roster.has(monster_id):
		return false
	var roster: Dictionary = monster_roster[monster_id]
	return bool(roster.get("defense_enabled", true))

func _defense_monster_ids() -> Array[String]:
	var monster_ids: Array[String] = []
	for monster_id in monster_roster.keys():
		if _monster_available_for_defense(str(monster_id)):
			monster_ids.append(str(monster_id))
	return monster_ids

func _support_only_monster_line() -> String:
	var names: Array[String] = []
	for monster_id in monster_roster.keys():
		if _monster_available_for_defense(str(monster_id)):
			continue
		if not bool(monster_roster[monster_id].get("raid_support", false)):
			continue
		names.append(str(DataRegistry.monster(str(monster_id)).get("display_name", monster_id)))
	if names.is_empty():
		return ""
	var joined_names := ""
	for name in names:
		if joined_names != "":
			joined_names += ", "
		joined_names += name
	return "원정/정찰 지원 전용: %s" % joined_names

func _ensure_selected_monster_available_for_defense() -> bool:
	if _monster_available_for_defense(selected_monster_id):
		return true
	var defense_ids = _defense_monster_ids()
	if defense_ids.is_empty():
		selected_monster_id = ""
		return false
	selected_monster_id = defense_ids[0]
	return true

func _open_raid_screen() -> void:
	if not _raid_unlocked():
		_log("악명 원정은 DAY 04부터 열립니다.")
		return
	_unlock_kobold_scout_commander()
	_ensure_raid_selection()
	_set_screen(Constants.SCREEN_RAID)

func _ensure_raid_selection() -> void:
	var required_group := _campaign_required_raid_choice_group()
	var selected_mission: Dictionary = DataRegistry.raid_mission(raid_selected_mission_id)
	if required_group != "" and _completed_raid_choice_id(required_group) == "" and str(selected_mission.get("choice_group", "")) != required_group:
		for raid_id_value in _available_raid_ids():
			var required_raid_id := str(raid_id_value)
			if str(DataRegistry.raid_mission(required_raid_id).get("choice_group", "")) == required_group:
				raid_selected_mission_id = required_raid_id
				break
	if raid_selected_mission_id == "" or DataRegistry.raid_mission(raid_selected_mission_id).is_empty():
		var ids = _available_raid_ids()
		raid_selected_mission_id = str(ids[0]) if not ids.is_empty() else ""
	raid_selected_monster_ids = _clean_raid_selection(raid_selected_monster_ids)
	if raid_selected_monster_ids.is_empty() and monster_roster.has(KOBOLD_SCOUT_ID):
		raid_selected_monster_ids.append(KOBOLD_SCOUT_ID)

func _available_raid_ids() -> Array:
	var ids: Array = []
	var max_day_available = max(4, GameState.day)
	var required_group := _campaign_required_raid_choice_group()
	var required_choice_pending := required_group != "" and _completed_raid_choice_id(required_group) == ""
	for raid_id_value in DataRegistry.raid_missions.keys():
		var raid_id = str(raid_id_value)
		var mission: Dictionary = DataRegistry.raid_mission(raid_id)
		if required_choice_pending and str(mission.get("choice_group", "")) != required_group:
			continue
		if int(mission.get("day", 999)) <= max_day_available:
			ids.append(raid_id)
	ids.sort_custom(func(a, b):
		var left: Dictionary = DataRegistry.raid_mission(str(a))
		var right: Dictionary = DataRegistry.raid_mission(str(b))
		return int(left.get("day", 999)) < int(right.get("day", 999))
	)
	return ids

func _clean_raid_selection(selection: Array) -> Array[String]:
	var result: Array[String] = []
	for monster_id_value in selection:
		var monster_id = str(monster_id_value)
		if monster_roster.has(monster_id) and not result.has(monster_id):
			result.append(monster_id)
	return result

func _build_raid_ui() -> void:
	_unlock_kobold_scout_commander()
	_ensure_raid_selection()
	var screen = hud.panel(Rect2(0, 0, 1920, 1080), Color("#06050bee"), Color("#06050bee"), "", "flat")
	screen.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.build_top_bar()
	var map_panel = hud.panel(Rect2(72, 112, 720, 812), Color("#0d0c12ee"), Color("#6e5630"), "", "flat")
	hud.label(map_panel, "악명 원정 지도", Vector2(0, 24), Vector2(720, 36), 27, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(map_panel, "방어로 얻은 악명을 밖으로 퍼뜨리는 소규모 임무입니다.", Vector2(78, 74), Vector2(564, 42), 16, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
	_build_raid_mission_list(map_panel)

	var detail_panel = hud.panel(Rect2(830, 112, 560, 812), Color("#100d14f2"), Color("#9b6a27"), "", "flat")
	_build_raid_detail_panel(detail_panel)

	var roster_panel = hud.panel(Rect2(1430, 112, 420, 812), Color("#0f0e13ee"), Color("#57485e"), "", "flat")
	_build_raid_roster_panel(roster_panel)

	hud.button(screen, "관리 화면", Rect2(72, 946, 220, 56), Callable(self, "_onboarding_finish_raid_preview"), 18)
	hud.button(screen, "원정 지도 갱신", Rect2(316, 946, 220, 56), Callable(self, "_set_screen").bind(Constants.SCREEN_RAID), 18)

func _build_raid_mission_list(parent: Control) -> void:
	var mission_ids = _available_raid_ids()
	var y := 148
	for mission_id_value in mission_ids:
		var mission_id = str(mission_id_value)
		var mission: Dictionary = DataRegistry.raid_mission(mission_id)
		var selected = mission_id == raid_selected_mission_id
		var completed = completed_raids.has(mission_id)
		var choice_locked = _raid_choice_locked(mission_id)
		var row = hud.child_panel(parent, Rect2(42, y, 636, 124), Color("#15121af0"), Color("#403448"), 1)
		var title = str(mission.get("title", mission_id))
		var status = "완료" if completed else ("다른 계획 확정" if choice_locked else str(mission.get("difficulty", "")))
		var mission_button = hud.button(row, title, Rect2(20, 18, 360, 38), Callable(self, "_select_raid_mission").bind(mission_id), 16)
		mission_button.disabled = choice_locked
		if selected:
			mission_button.add_theme_stylebox_override("normal", hud.style(Color("#2b2340ee"), Color("#ffd36a"), 2))
			mission_button.add_theme_color_override("font_color", Color("#fff2c9"))
		hud.label(row, status, Vector2(412, 24), Vector2(176, 26), 16, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_RIGHT, "", UIFontScript.ROLE_EMPHASIS)
		hud.label(row, str(mission.get("location", "")), Vector2(24, 64), Vector2(564, 22), 14, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT)
		hud.label(row, _raid_reward_label(mission), Vector2(24, 92), Vector2(564, 20), 13, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_LEFT)
		y += 144
	if mission_ids.is_empty():
		hud.label(parent, "표시할 원정 목표가 없습니다.", Vector2(80, 280), Vector2(560, 40), 22, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_CENTER)

func _build_raid_detail_panel(parent: Control) -> void:
	var mission: Dictionary = DataRegistry.raid_mission(raid_selected_mission_id)
	if mission.is_empty():
		hud.label(parent, "원정 목표를 선택하세요.", Vector2(42, 120), Vector2(476, 40), 24, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_CENTER)
		return
	var completed = completed_raids.has(raid_selected_mission_id)
	var choice_locked = _raid_choice_locked(raid_selected_mission_id)
	hud.label(parent, str(mission.get("subtitle", "원정")), Vector2(42, 34), Vector2(476, 24), 16, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(parent, str(mission.get("title", raid_selected_mission_id)), Vector2(42, 70), Vector2(476, 54), 31, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
	hud.rich_label(parent, str(mission.get("summary", "")), Vector2(54, 146), Vector2(452, 84), 18, Color("#d8d1df"), UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_WORD_SMART, VERTICAL_ALIGNMENT_CENTER)
	_build_raid_stat_row(parent, "비용", _raid_cost_label(mission), 258)
	_build_raid_stat_row(parent, "보상", _raid_expected_reward_label(mission), 310)
	_build_raid_stat_row(parent, "위험", "%s / %s" % [mission.get("difficulty", ""), mission.get("risk", "")], 362)
	var modifier: Dictionary = mission.get("next_defense_modifier", {})
	hud.label(parent, "다음 방어 영향", Vector2(54, 430), Vector2(452, 24), 17, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	hud.rich_label(parent, str(modifier.get("description", "영향 없음")), Vector2(54, 462), Vector2(452, 66), 16, Color("#cfc7d9"), UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_WORD_SMART, VERTICAL_ALIGNMENT_TOP)
	if last_raid_result.is_empty():
		hud.label(parent, "브리핑", Vector2(54, 548), Vector2(452, 24), 17, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
		var briefing_lines: Array = mission.get("briefing_lines", [])
		hud.rich_label(parent, "- %s" % "\n- ".join(briefing_lines), Vector2(54, 578), Vector2(452, 104), 15, Color("#d8d1df"), UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_WORD_SMART, VERTICAL_ALIGNMENT_TOP)
	var start_button = hud.button(parent, "원정 출발", Rect2(116, 710, 328, 58), Callable(self, "_start_selected_raid"), 20, "RaidStartButton")
	if completed:
		start_button.disabled = true
		start_button.text = "완료된 원정"
	elif choice_locked:
		start_button.disabled = true
		start_button.text = "다른 계획 확정"
	if not _can_start_selected_raid():
		start_button.disabled = true
	hud.label(parent, _raid_start_hint(), Vector2(54, 778), Vector2(452, 24), 13, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
	if not last_raid_result.is_empty():
		_build_raid_result_panel(parent)

func _build_raid_result_panel(parent: Control) -> void:
	var result_panel = hud.child_panel(parent, Rect2(34, 542, 492, 148), Color("#18121dff"), Color("#ffd36a"), 2)
	hud.label(result_panel, "최근 원정 보고", Vector2(0, 10), Vector2(492, 24), 17, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	var lines: Array = last_raid_result.get("lines", [])
	var y := 40
	for index in range(mini(lines.size(), 4)):
		hud.label(result_panel, str(lines[index]), Vector2(28, y), Vector2(436, 20), 12, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_WORD_SMART, 1)
		y += 24

func _build_raid_stat_row(parent: Control, label_text: String, value_text: String, y: int) -> void:
	var row = hud.child_panel(parent, Rect2(54, y, 452, 38), Color("#0b0910d8"), Color("#403448"), 1)
	hud.label(row, label_text, Vector2(16, 9), Vector2(96, 20), 14, Color("#aaa1b5"), HORIZONTAL_ALIGNMENT_LEFT)
	hud.label(row, value_text, Vector2(118, 9), Vector2(316, 20), 14, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_RIGHT)

func _build_raid_roster_panel(parent: Control) -> void:
	hud.label(parent, "원정대", Vector2(0, 26), Vector2(420, 34), 27, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	_onboarding_add_portrait(parent, Rect2(78, 82, 264, 308), KOBOLD_SCOUT_CHARACTER_ID, "로로", "briefing", true)
	hud.label(parent, "대장 효과", Vector2(42, 414), Vector2(336, 22), 16, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(parent, "로로 포함 시 원정 악명 보상 +10%", Vector2(42, 444), Vector2(336, 42), 15, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_WORD_SMART, 2)
	hud.label(parent, "편성", Vector2(42, 508), Vector2(336, 22), 16, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var keys = monster_roster.keys()
	var y := 544
	for monster_id_value in keys:
		var monster_id = str(monster_id_value)
		var data: Dictionary = DataRegistry.monster(monster_id)
		var selected = raid_selected_monster_ids.has(monster_id)
		var button_text = "%s  %s" % ["선택" if selected else "대기", data.get("display_name", monster_id)]
		var select_button = hud.button(parent, button_text, Rect2(42, y, 336, 34), Callable(self, "_toggle_raid_monster").bind(monster_id), 13)
		if selected:
			select_button.add_theme_stylebox_override("normal", hud.style(Color("#2b2340ee"), Color("#ffd36a"), 2))
			select_button.add_theme_color_override("font_color", Color("#fff2c9"))
		y += 42
	hud.label(parent, _raid_roster_hint(), Vector2(42, 736), Vector2(336, 42), 13, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)

func _select_raid_mission(mission_id: String) -> void:
	if DataRegistry.raid_mission(mission_id).is_empty() or _raid_choice_locked(mission_id):
		return
	raid_selected_mission_id = mission_id
	_ensure_raid_selection()
	_set_screen(Constants.SCREEN_RAID)

func _toggle_raid_monster(monster_id: String) -> void:
	if not monster_roster.has(monster_id):
		return
	var mission: Dictionary = DataRegistry.raid_mission(raid_selected_mission_id)
	var max_monsters = int(mission.get("max_monsters", 2))
	if raid_selected_monster_ids.has(monster_id):
		raid_selected_monster_ids.erase(monster_id)
	elif raid_selected_monster_ids.size() < max_monsters:
		raid_selected_monster_ids.append(monster_id)
	else:
		_log("이 원정은 최대 %d명까지 보낼 수 있습니다." % max_monsters)
	_set_screen(Constants.SCREEN_RAID)

func _can_start_selected_raid() -> bool:
	var mission: Dictionary = DataRegistry.raid_mission(raid_selected_mission_id)
	if mission.is_empty() or completed_raids.has(raid_selected_mission_id) or _raid_choice_locked(raid_selected_mission_id):
		return false
	if raid_selected_monster_ids.size() < int(mission.get("required_monsters", 1)):
		return false
	return GameState.can_pay(mission.get("cost", {}))

func _start_selected_raid() -> void:
	_ensure_raid_selection()
	var mission: Dictionary = DataRegistry.raid_mission(raid_selected_mission_id)
	if mission.is_empty():
		_log("원정 목표를 선택하세요.")
		return
	if completed_raids.has(raid_selected_mission_id):
		_log("이미 완료한 원정입니다.")
		return
	if _raid_choice_locked(raid_selected_mission_id):
		_log("이 보급로의 다른 계획을 이미 확정했습니다.")
		_set_screen(Constants.SCREEN_RAID)
		return
	if raid_selected_monster_ids.size() < int(mission.get("required_monsters", 1)):
		_log("원정에 보낼 몬스터를 더 선택하세요.")
		_set_screen(Constants.SCREEN_RAID)
		return
	var cost: Dictionary = mission.get("cost", {})
	if not GameState.pay(cost):
		_log("원정 비용이 부족합니다.")
		_set_screen(Constants.SCREEN_RAID)
		return
	var reward = _raid_reward_with_bonus(mission)
	GameState.add_rewards(reward)
	completed_raids[raid_selected_mission_id] = true
	for monster_id_value in raid_selected_monster_ids:
		var monster_id := str(monster_id_value)
		var bond_result := _grant_monster_bond(monster_id, 8 if monster_id == KOBOLD_SCOUT_ID else 4)
		if int(bond_result.get("gain", 0)) > 0:
			_log("%s와의 원정 유대 +%d." % [_monster_display_name(monster_id), int(bond_result.get("gain", 0))])
		if str(bond_result.get("unlocked_memory_id", "")) != "":
			_log("%s와의 새 원정 기억이 해금되었습니다." % _monster_display_name(monster_id))
	var modifier: Dictionary = mission.get("next_defense_modifier", {})
	if not modifier.is_empty():
		next_defense_modifiers[str(modifier.get("id", raid_selected_mission_id))] = modifier.duplicate(true)
	var flag = str(mission.get("story_flags", {}).get("on_complete", ""))
	if flag != "":
		completed_raids[flag] = true
	var success_lines: Array = mission.get("success_lines", [])
	last_raid_result = {
		"mission_id": raid_selected_mission_id,
		"reward": reward,
		"lines": [
			str(success_lines[0]) if success_lines.size() > 0 else "원정 성공.",
			"획득 금화 %d / 악명 %d" % [int(reward.get("gold", 0)), int(reward.get("infamy", 0))],
			str(modifier.get("description", "다음 방어 영향 없음")),
			"원정대: %s" % _raid_selected_names()
		]
	}
	GameState.onboarding_complete = true
	tutorial_gate_enabled = false
	_onboarding_set_stage("CAMPAIGN_DAY_04_RAID_COMPLETE")
	_log("%s 성공. %s" % [mission.get("title", raid_selected_mission_id), _raid_reward_label({"reward": reward})])
	_set_screen(Constants.SCREEN_RAID)

func _raid_reward_with_bonus(mission: Dictionary) -> Dictionary:
	var reward: Dictionary = mission.get("reward", {}).duplicate(true)
	var base_infamy = int(reward.get("infamy", 0))
	if raid_selected_monster_ids.has(KOBOLD_SCOUT_ID) and base_infamy > 0:
		var bonus = int(ceil(float(base_infamy) * 0.10))
		reward["infamy"] = base_infamy + bonus
	return reward

func _raid_selected_names() -> String:
	var names: Array[String] = []
	for monster_id in raid_selected_monster_ids:
		names.append(str(DataRegistry.monster(monster_id).get("display_name", monster_id)))
	if names.is_empty():
		return "없음"
	return ", ".join(names)

func _raid_cost_label(mission: Dictionary) -> String:
	return _resource_label(mission.get("cost", {}), "없음")

func _raid_reward_label(mission: Dictionary) -> String:
	return _resource_label(mission.get("reward", {}), "보상 없음")

func _raid_expected_reward_label(mission: Dictionary) -> String:
	var base_reward: Dictionary = mission.get("reward", {})
	var expected_reward = _raid_reward_with_bonus(mission)
	var label = _resource_label(expected_reward, "보상 없음")
	var base_infamy = int(base_reward.get("infamy", 0))
	var expected_infamy = int(expected_reward.get("infamy", 0))
	if expected_infamy > base_infamy:
		label += " (로로 +%d)" % (expected_infamy - base_infamy)
	return label

func _resource_label(values: Dictionary, empty_label: String) -> String:
	var parts: Array[String] = []
	for key in ["gold", "mana", "food", "infamy"]:
		var amount = int(values.get(key, 0))
		if amount <= 0:
			continue
		match key:
			"gold":
				parts.append("금화 %d" % amount)
			"mana":
				parts.append("마력 %d" % amount)
			"food":
				parts.append("식량 %d" % amount)
			"infamy":
				parts.append("악명 %d" % amount)
	return empty_label if parts.is_empty() else " / ".join(parts)

func _raid_start_hint() -> String:
	var mission: Dictionary = DataRegistry.raid_mission(raid_selected_mission_id)
	if mission.is_empty():
		return ""
	if completed_raids.has(raid_selected_mission_id):
		return "완료된 원정입니다."
	if _raid_choice_locked(raid_selected_mission_id):
		return "이 보급로의 다른 계획을 이미 확정했습니다."
	if raid_selected_monster_ids.size() < int(mission.get("required_monsters", 1)):
		return "원정대원을 선택하세요."
	if not GameState.can_pay(mission.get("cost", {})):
		return "비용이 부족합니다."
	return "출발하면 보상과 다음 방어 영향이 즉시 적용됩니다."

func _raid_roster_hint() -> String:
	var mission: Dictionary = DataRegistry.raid_mission(raid_selected_mission_id)
	if mission.is_empty():
		return ""
	return "필요 %d명 / 최대 %d명 / 현재 %d명" % [
		int(mission.get("required_monsters", 1)),
		int(mission.get("max_monsters", 2)),
		raid_selected_monster_ids.size()
	]

func _onboarding_quit_requested() -> void:
	get_tree().quit()

func _onboarding_finish_raid_preview() -> void:
	_unlock_kobold_scout_commander()
	GameState.onboarding_complete = true
	tutorial_gate_enabled = false
	tutorial_manager.active = false
	GameState.victory = false
	first_play_observation.save_snapshot(GameState.day, true)
	_enter_campaign_management_day(true)

func _debug_skip_onboarding() -> void:
	first_play_observation.stop()
	onboarding_enabled = false
	onboarding_dialogue_queue.clear()
	onboarding_seen_dialogue_ids.clear()
	tutorial_gate_enabled = false
	tutorial_manager.reset()
	tutorial_manager.active = false
	GameState.onboarding_complete = true
	_onboarding_set_stage("")
	if _onboarding_screen_blocks_map_input():
		_set_screen(Constants.SCREEN_MANAGEMENT)

func _tutorial_build_overlay() -> void:
	_tutorial_clear_overlay()
	if not onboarding_enabled or not tutorial_manager.is_active_for_stage(onboarding_stage_id):
		return
	if current_screen == Constants.SCREEN_NAME_ENTRY:
		return
	if current_screen == Constants.SCREEN_DIALOGUE:
		return
	var step = tutorial_manager.current_step()
	if step.is_empty():
		return
	var overlay = Panel.new()
	overlay.name = "TutorialOverlay"
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(1920, 1080)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_theme_stylebox_override("panel", hud.style(Color("#00000000"), Color("#00000000"), 0))
	ui_layer.add_child(overlay)
	var focus_rect = _tutorial_focus_rect(str(step.get("focus", "")))
	var suppress_focus_highlight = current_screen == Constants.SCREEN_MANAGEMENT and _management_action_mode_active()
	if not suppress_focus_highlight and focus_rect.size.x > 0.0 and focus_rect.size.y > 0.0:
		var focus_glow = Panel.new()
		focus_glow.position = focus_rect.position - Vector2(3, 3)
		focus_glow.size = focus_rect.size + Vector2(6, 6)
		focus_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		focus_glow.add_theme_stylebox_override("panel", hud.style(Color("#ffd36a0d"), Color("#d8b86788"), 1))
		overlay.add_child(focus_glow)
		var highlight = Panel.new()
		highlight.position = focus_rect.position
		highlight.size = focus_rect.size
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		highlight.add_theme_stylebox_override("panel", hud.style(Color("#ffd36a12"), Color("#cfb05aaa"), 2))
		overlay.add_child(highlight)
	var message_rect = _tutorial_message_rect(focus_rect)
	var shadow_panel = Panel.new()
	shadow_panel.position = message_rect.position + Vector2(8, 10)
	shadow_panel.size = message_rect.size
	shadow_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow_panel.add_theme_stylebox_override("panel", hud.style(Color("#00000088"), Color("#00000000"), 0))
	overlay.add_child(shadow_panel)
	var message_panel = Panel.new()
	message_panel.position = message_rect.position
	message_panel.size = message_rect.size
	message_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_panel.add_theme_stylebox_override("panel", hud.style(Color("#0b0910f5"), Color("#9b7b38cc"), 1))
	overlay.add_child(message_panel)
	hud.label(message_panel, "지금 할 일", Vector2(20, 10), Vector2(message_rect.size.x - 40, 28), 18, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	hud.rich_label(message_panel, _onboarding_line_text(step), Vector2(20, 42), Vector2(message_rect.size.x - 40, message_rect.size.y - 54), 19, Color("#fff7e6"), UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_WORD_SMART, VERTICAL_ALIGNMENT_CENTER, "", 14)

func _tutorial_clear_overlay() -> void:
	if ui_layer == null:
		return
	for child in ui_layer.get_children():
		if child.name == "TutorialOverlay":
			child.queue_free()

func _tutorial_message_rect(focus_rect: Rect2) -> Rect2:
	var step_text = _onboarding_line_text(tutorial_manager.current_step())
	var estimated_lines = maxi(1, int(ceil(float(step_text.length()) / 34.0)))
	var size := Vector2(680, clampf(92.0 + float(estimated_lines) * 20.0, 118.0, 158.0))
	if current_screen == Constants.SCREEN_NAME_ENTRY:
		return Rect2(620, 842, size.x, size.y)
	if current_screen == Constants.SCREEN_MONSTER:
		return Rect2(620, 920, size.x, minf(size.y, 132.0))
	if current_screen == Constants.SCREEN_COMBAT:
		return Rect2(826, 86, size.x, minf(size.y, 138.0))
	if focus_rect.size.x <= 0.0:
		return Rect2(620, 150, size.x, size.y)
	var margin := 28.0
	var top_limit := 86.0
	var bottom_limit := 852.0
	var candidate := Vector2.ZERO
	if focus_rect.position.y > 700.0:
		candidate = Vector2(focus_rect.get_center().x - size.x * 0.5, focus_rect.position.y - size.y - 26.0)
	elif focus_rect.position.y < 230.0:
		candidate = Vector2(focus_rect.get_center().x - size.x * 0.5, focus_rect.end.y + 26.0)
	elif focus_rect.get_center().x < 960.0:
		candidate = Vector2(focus_rect.end.x + 28.0, focus_rect.get_center().y - size.y * 0.5)
	else:
		candidate = Vector2(focus_rect.position.x - size.x - 28.0, focus_rect.get_center().y - size.y * 0.5)
	candidate.x = clampf(candidate.x, margin, 1920.0 - size.x - margin)
	candidate.y = clampf(candidate.y, top_limit, bottom_limit - size.y)
	return Rect2(candidate, size)

func _tutorial_focus_rect(focus_id: String) -> Rect2:
	var registered_rect = _tutorial_registered_target_rect(focus_id)
	if registered_rect.size.x > 0.0 and registered_rect.size.y > 0.0:
		return registered_rect.grow(8)
	match focus_id:
		"NameInput":
			return _onboarding_rect("S01_NAME_ENTRY", "NameInput", Rect2(700, 420, 520, 64)).grow(10)
		"ROOM_THRONE":
			return _tutorial_room_rect("throne")
		"ROOM_ENTRANCE":
			return _tutorial_room_rect("entrance")
		"ROOM_TREASURE":
			return _tutorial_room_rect("treasure")
		"ROOM_RECOVERY_NEST":
			return _tutorial_room_rect("recovery")
		"CHR_PUDDING":
			return _tutorial_monster_rect("slime")
		"CHR_GOB":
			return _tutorial_monster_rect("goblin")
		"CHR_PYNN":
			return _tutorial_monster_rect("imp")
		"GLOBAL_DIRECTIVE_DEFEND":
			return Rect2(596, 932, 120, 66).grow(8)
		"ROOM_DIRECTIVE_BLOCK_ENTRANCE":
			return Rect2(1546, 766, 145, 34).grow(8) if current_screen == Constants.SCREEN_MANAGEMENT else Rect2(1056, 932, 136, 66).grow(8)
		"ROOM_DIRECTIVE_TRAP_LURE":
			return Rect2(1708, 766, 145, 34).grow(8) if current_screen == Constants.SCREEN_MANAGEMENT else Rect2(1056, 932, 136, 66).grow(8)
		"ROOM_DIRECTIVE_RETREAT_LINE":
			return Rect2(1546, 808, 145, 34).grow(8) if current_screen == Constants.SCREEN_MANAGEMENT else Rect2(1056, 932, 136, 66).grow(8)
		"DirectControlButton":
			return Rect2(1554, 746, 136, 52).grow(8)
		"FirstEnemy":
			return _tutorial_enemy_rect()
		"BattleLogPanel":
			return Rect2(20, 710, 360, 288).grow(8)
		"BossHpBar":
			return Rect2(1460, 22, 360, 42).grow(8)
		"GrowthReviewButton":
			return _onboarding_rect("S05_RESULT", "GrowthReviewButton", Rect2(988, 486, 220, 56)).grow(8)
		"WorldMapPanel":
			return _onboarding_rect("S06_RAID_PREVIEW", "WorldMapPanel", Rect2(120, 100, 1080, 780)).grow(8)
		_:
			return Rect2()

func register_tutorial_target(target_id: String, rect: Rect2) -> void:
	if target_id == "":
		return
	tutorial_targets[target_id] = rect

func register_tutorial_target_control(target_id: String, control: Control, grow_amount: float = 0.0) -> void:
	if target_id == "" or control == null:
		return
	var rect = Rect2(control.global_position, control.size)
	if grow_amount != 0.0:
		rect = rect.grow(grow_amount)
	register_tutorial_target(target_id, rect)

func _tutorial_registered_target_rect(target_id: String) -> Rect2:
	if tutorial_targets.has(target_id):
		return tutorial_targets[target_id]
	return Rect2()

func _tutorial_room_rect(room_id: String) -> Rect2:
	if graph == null or not rooms.has(room_id):
		return Rect2()
	if current_screen == Constants.SCREEN_COMBAT:
		var center = _combat_world_to_screen(graph.center(room_id))
		return Rect2(center - Vector2(70, 50), Vector2(140, 100))
	return graph.rect(room_id).grow(12)

func _tutorial_monster_rect(monster_id: String) -> Rect2:
	if current_screen == Constants.SCREEN_MONSTER:
		var order = ["slime", "goblin", "imp"]
		var index = order.find(monster_id)
		if index >= 0:
			return Rect2(48, 196 + index * 90, 460, 76).grow(8)
	if current_screen == Constants.SCREEN_COMBAT:
		for unit in monster_units:
			if unit.unit_id == monster_id and is_instance_valid(unit):
				var screen_pos = _combat_world_to_screen(unit.global_position)
				return Rect2(screen_pos - Vector2(48, 64), Vector2(96, 110))
	var point = _management_monster_preview_position(monster_id)
	if point == Vector2.INF:
		return Rect2()
	return Rect2(point - Vector2(54, 64), Vector2(108, 128))

func _tutorial_enemy_rect() -> Rect2:
	if current_screen != Constants.SCREEN_COMBAT:
		return Rect2()
	for unit in enemy_units:
		if unit != null and is_instance_valid(unit) and unit.is_alive():
			var screen_pos = _combat_world_to_screen(unit.global_position)
			return Rect2(screen_pos - Vector2(52, 70), Vector2(104, 118))
	return Rect2(20, 710, 360, 288).grow(8)

func _tutorial_allows(action_id: String, payload: Dictionary = {}) -> bool:
	if not onboarding_enabled or not tutorial_gate_enabled:
		return true
	if not tutorial_manager.is_active_for_stage(onboarding_stage_id):
		return true
	if tutorial_manager.allows_action(action_id, payload):
		return true
	var step = tutorial_manager.current_step()
	first_play_observation.record_blocked(
		action_id,
		tutorial_manager.expected_action(),
		tutorial_manager.current_step_id(),
		GameState.day,
		current_screen
	)
	first_play_observation.save_snapshot(GameState.day, false)
	_log("튜토리얼 진행 중입니다: %s" % _onboarding_line_text(step))
	_tutorial_build_overlay()
	return false

func _tutorial_emit_action(action_id: String, payload: Dictionary = {}) -> void:
	SignalBus.emit_tutorial_action(action_id, payload)

func _on_tutorial_action(action_id: String, payload: Dictionary) -> void:
	if not onboarding_enabled:
		return
	var step_before := tutorial_manager.current_step_id()
	var advanced = tutorial_manager.handle_action(action_id, payload)
	var step_after := tutorial_manager.current_step_id()
	first_play_observation.record_tutorial_action(action_id, payload, step_before, step_after, advanced, GameState.day, current_screen)
	if advanced and step_after == "TUT_040_DEPLOY_SLIME" and str(monster_roster.get("slime", {}).get("room", "")) == "entrance":
		var deploy_payload := {"monster_id": "slime", "unit_id": "slime", "room_id": "entrance", "already_deployed": true}
		var deploy_step_before := step_after
		var deploy_advanced := tutorial_manager.handle_action("unit_deployed", deploy_payload)
		step_after = tutorial_manager.current_step_id()
		first_play_observation.record_tutorial_action("unit_deployed", deploy_payload, deploy_step_before, step_after, deploy_advanced, GameState.day, current_screen)
		advanced = advanced or deploy_advanced
	var observation_complete: bool = not tutorial_manager.active and GameState.day >= 4
	if advanced or action_id in ["battle_finished", "day_advanced", "global_directive_set", "room_directive_set"] or observation_complete:
		first_play_observation.save_snapshot(GameState.day, observation_complete)
	if observation_complete:
		first_play_observation.stop()
	if advanced:
		_tutorial_build_overlay()

func _clear_ui() -> void:
	hud.clear()

func _build_management_ui() -> void:
	management_scene.build_management_ui()

func _build_monster_ui() -> void:
	management_scene.build_monster_ui()

func _build_combat_ui() -> void:
	combat_scene.build_combat_ui()

func _build_result_ui() -> void:
	management_scene.build_result_ui()

func _build_top_bar() -> void:
	hud.build_top_bar()

func _build_room_list(x: int, y: int, w: int, h: int) -> void:
	hud.build_room_list(x, y, w, h)

func _build_selected_room_info(parent: Control) -> void:
	hud.build_selected_room_info(parent)

func _build_stat_lines(parent: Control, monster: Dictionary, roster: Dictionary) -> void:
	hud.build_stat_lines(parent, monster, roster)

func _build_log_panel() -> void:
	hud.build_log_panel()

func _build_selected_unit_panel() -> void:
	hud.build_selected_unit_panel()

func _build_command_panel() -> void:
	hud.build_command_panel()

func _build_speed_panel() -> void:
	hud.build_speed_panel()

func _rebuild_combat_ui_light() -> void:
	if int(combat_time * 4.0) % 4 != 0:
		return

func _reset_combat_view() -> void:
	combat_view_zoom = 1.0
	if combat_camera == null:
		return
	combat_camera.position = COMBAT_CAMERA_HOME
	combat_camera.zoom = Vector2.ONE
	combat_camera.offset = Vector2.ZERO

func _update_combat_camera_enabled() -> void:
	if combat_camera == null:
		return
	var enabled = current_screen == Constants.SCREEN_COMBAT
	combat_camera.enabled = enabled
	if enabled:
		combat_camera.make_current()

func _adjust_combat_zoom(direction: int, screen_point: Vector2) -> void:
	if current_screen != Constants.SCREEN_COMBAT or combat_camera == null:
		return
	if _combat_ui_at(screen_point):
		return
	var focus_world = _combat_screen_to_world(screen_point)
	var next_zoom = combat_view_zoom * (COMBAT_ZOOM_STEP if direction > 0 else 1.0 / COMBAT_ZOOM_STEP)
	combat_view_zoom = clamp(next_zoom, COMBAT_ZOOM_MIN, COMBAT_ZOOM_MAX)
	combat_camera.zoom = Vector2(combat_view_zoom, combat_view_zoom)
	var viewport_size = get_viewport().get_visible_rect().size
	combat_camera.position = focus_world - (screen_point - viewport_size * 0.5) / combat_view_zoom
	queue_redraw()

func _combat_screen_to_world(screen_point: Vector2) -> Vector2:
	if current_screen != Constants.SCREEN_COMBAT or combat_camera == null or not combat_camera.enabled:
		return screen_point
	var viewport_size = get_viewport().get_visible_rect().size
	return combat_camera.position + (screen_point - viewport_size * 0.5) / combat_view_zoom

func _combat_world_to_screen(world_point: Vector2) -> Vector2:
	if combat_camera == null:
		return world_point
	var viewport_size = get_viewport().get_visible_rect().size
	return (world_point - combat_camera.position) * combat_view_zoom + viewport_size * 0.5

func _clamp_to_combat_walkable(point: Vector2) -> Vector2:
	if graph == null or not graph.has_method("clamp_to_walkable"):
		return point
	return graph.clamp_to_walkable(point)

func _handle_left_click(point: Vector2, screen_point: Vector2 = Vector2(-99999, -99999)) -> void:
	if current_screen == Constants.SCREEN_COMBAT:
		if screen_point.x > -90000 and _combat_ui_at(screen_point):
			return
		var unit = _unit_at(point)
		if unit != null:
			_select_unit(unit)
		return
	if current_screen != Constants.SCREEN_MANAGEMENT:
		return
	if screen_point.x > -90000 and _management_ui_at(screen_point):
		return
	var room_id = _room_at(point)
	if room_id != "":
		if map_editor_active and _map_editor_connect_selected_to(room_id):
			return
		if build_pick_mode:
			_select_build_target_room(room_id)
			return
		if deploy_pick_monster_id != "":
			if _assign_monster_to_room(deploy_pick_monster_id, room_id):
				deploy_pick_monster_id = ""
			_set_screen(Constants.SCREEN_MANAGEMENT)
			return
		_select_room(room_id)
		if _can_change_room_facility(room_id):
			_open_build_palette_for_room(room_id)

func _handle_right_click(point: Vector2, screen_point: Vector2 = Vector2(-99999, -99999)) -> void:
	if current_screen != Constants.SCREEN_COMBAT:
		return
	if screen_point.x > -90000 and _combat_ui_at(screen_point):
		return
	if selected_unit == null or selected_unit.faction != Constants.FACTION_MONSTER:
		return
	var enemy_target = _enemy_at(point)
	if enemy_target != null:
		var direct_attack_payload = {"unit_id": selected_unit.unit_id, "target_id": enemy_target.unit_id}
		var tutorial_needs_direct_attack = onboarding_enabled and tutorial_gate_enabled and tutorial_manager.expected_action() == "direct_attack_once"
		if tutorial_needs_direct_attack and not _tutorial_allows("direct_attack_once", direct_attack_payload):
			return
		selected_unit.command_attack(enemy_target)
		if graph != null and graph.has_method("path_to_point"):
			var target_point = _clamp_to_combat_walkable(enemy_target.global_position)
			selected_unit.set_path(graph.path_to_point(selected_unit.global_position, target_point))
		_tutorial_emit_action("direct_attack_once", direct_attack_payload)
		_log("%s 직접 공격 지정: %s." % [selected_unit.display_name, enemy_target.display_name])
		return
	selected_unit.command_move(_clamp_to_combat_walkable(point))
	_log("%s 직접 이동 명령." % selected_unit.display_name)

func _handle_key(keycode: int) -> void:
	if current_screen == Constants.SCREEN_DIALOGUE:
		if _is_dialogue_advance_key(keycode):
			_onboarding_advance_dialogue()
		return
	match keycode:
		KEY_SPACE:
			if current_screen == Constants.SCREEN_COMBAT:
				_toggle_pause()
		KEY_TAB:
			_select_next_monster_unit()
		KEY_ESCAPE:
			if current_screen == Constants.SCREEN_SETTINGS:
				_close_settings_screen()
			elif current_screen == Constants.SCREEN_MANAGEMENT:
				if map_editor_path_drag_active:
					_clear_map_editor_path_drag()
					map_editor_status = "드래그를 취소했습니다."
					_set_screen(Constants.SCREEN_MANAGEMENT)
				else:
					_cancel_management_action_mode()
		KEY_1:
			_use_selected_skill(0)
		KEY_2:
			_use_selected_skill(1)
		KEY_3:
			_use_selected_skill(2)
		KEY_F3:
			_toggle_quarter_debug_overlay("active")
		KEY_F4:
			_toggle_quarter_debug_overlay("walkable")
		KEY_F5:
			_toggle_quarter_debug_overlay("floor_mask")
		KEY_F6:
			_toggle_quarter_debug_overlay("sockets")
		KEY_F7:
			_toggle_quarter_debug_overlay("room_id")
		KEY_F8:
			_toggle_quarter_debug_overlay("cursor")
		KEY_F9:
			_toggle_quarter_debug_overlay("path")
		KEY_ESCAPE:
			if current_screen == Constants.SCREEN_MONSTER:
				_set_screen(Constants.SCREEN_MANAGEMENT)

func _is_dialogue_advance_key(keycode: int) -> bool:
	return keycode == KEY_SPACE or keycode == KEY_ENTER or keycode == KEY_KP_ENTER

func _toggle_quarter_debug_overlay(overlay_id: String) -> void:
	match overlay_id:
		"active":
			debug_show_active_overlay = not debug_show_active_overlay
			_log("활성 셀 표시 %s." % ("ON" if debug_show_active_overlay else "OFF"))
		"sockets":
			debug_show_socket_overlay = not debug_show_socket_overlay
			_log("소켓 디버그 표시 %s." % ("ON" if debug_show_socket_overlay else "OFF"))
		"modules":
			debug_show_quarter_module_overlay = not debug_show_quarter_module_overlay
			_log("모듈 외곽선 표시 %s." % ("ON" if debug_show_quarter_module_overlay else "OFF"))
		"walkable":
			debug_show_walkable_overlay = not debug_show_walkable_overlay
			_log("보행 가능 셀 표시 %s." % ("ON" if debug_show_walkable_overlay else "OFF"))
		"floor_mask":
			debug_show_floor_mask_overlay = not debug_show_floor_mask_overlay
			_log("바닥 마스크 표시 %s." % ("ON" if debug_show_floor_mask_overlay else "OFF"))
		"room_id":
			debug_show_room_id_overlay = not debug_show_room_id_overlay
			_log("방 ID 표시 %s." % ("ON" if debug_show_room_id_overlay else "OFF"))
		"blocked":
			debug_show_blocked_overlay = not debug_show_blocked_overlay
			_log("차단 셀 표시 %s." % ("ON" if debug_show_blocked_overlay else "OFF"))
		"cursor":
			debug_show_cursor_cell = not debug_show_cursor_cell
			_log("선택 유닛/커서 셀 표시 %s." % ("ON" if debug_show_cursor_cell else "OFF"))
		"path":
			debug_show_path_overlay = not debug_show_path_overlay
			_log("경로 라인 표시 %s." % ("ON" if debug_show_path_overlay else "OFF"))
	queue_redraw()

func _start_combat() -> void:
	if map_editor_active:
		_log("맵 편집을 저장하거나 취소한 뒤 전투를 시작하세요.")
		return
	_clear_management_action_mode(false)
	if campaign_postgame_active:
		_show_campaign_ending()
		return
	var campaign_info := _campaign_day_info()
	if bool(campaign_info.get("management_only", false)):
		_log(str(campaign_info.get("management_only_prompt", "오늘은 전투 없이 관리 준비를 확정하는 날입니다.")))
		return
	if bool(campaign_info.get("requires_final_upgrade", false)) and not campaign_final_upgrade_ready:
		_log("DAY %d 일정은 Stage 04 대마왕성 강화를 완료한 뒤 진행할 수 있습니다." % GameState.day)
		return
	var preparation_flag := str(campaign_info.get("requires_final_preparation_flag", ""))
	if not _campaign_final_preparation_flag_enabled(preparation_flag):
		_log("DAY %d 최종 공성전은 DAY 29의 배치·시설·지침 점검을 확정한 뒤 시작할 수 있습니다." % GameState.day)
		return
	if not _tutorial_allows("combat_started", {"day": GameState.day}):
		return
	if (not onboarding_enabled or GameState.onboarding_complete) and not _has_defense_wave_for_day(GameState.day):
		_log("DAY %d 방어 데이터가 아직 준비되지 않았습니다. 다음 장 준비 중입니다." % GameState.day)
		return
	if (not onboarding_enabled or GameState.onboarding_complete) and _campaign_raid_choice_pending():
		_log(_campaign_required_raid_choice_log())
		_open_raid_screen()
		return
	if _early_specialization_required_for_current_day():
		_log("DAY %d 전투 전에 몬스터 한 명의 전술 특화를 선택하세요." % GameState.day)
		_open_monster_screen()
		return
	if (not onboarding_enabled or GameState.onboarding_complete) and _first_promotion_required_for_current_day() and not _first_promotion_ready():
		_log("DAY %d 전투는 첫 승급을 완료한 뒤 시작할 수 있습니다." % GameState.day)
		_open_monster_screen()
		return
	if (not onboarding_enabled or GameState.onboarding_complete) and _stage_two_upgrade_required_for_current_day() and not _stage_two_upgrade_budget_ready():
		_log("DAY %d 전투는 Stage 02 심사 비용을 마련한 뒤 시작할 수 있습니다." % GameState.day)
		return
	if not _ensure_required_main_route_for_current_layout("전투 시작"):
		return
	if onboarding_enabled and not GameState.onboarding_complete:
		_onboarding_set_stage(_onboarding_battle_stage_for_day(GameState.day))
		onboarding_boss_hp_thresholds.clear()
		onboarding_treasure_stolen_this_day = false
	else:
		_apply_campaign_combat_entry(GameState.day)
	combat_scene.start_combat()
	_tutorial_emit_action("combat_started", {"day": GameState.day})
	if onboarding_enabled and GameState.day == 1:
		_onboarding_emit_trigger("direct_control_prompt")

func _spawn_monsters() -> void:
	combat_scene.spawn_monsters()

func _spawn_ready_enemies(delta: float) -> void:
	combat_scene.spawn_ready_enemies(delta)

func _spawn_enemy(enemy_id: String) -> void:
	combat_scene.spawn_enemy(enemy_id)

func _create_unit(source_id: String, stats: Dictionary, faction: String, room_id: String) -> Node:
	var unit = UnitActorScript.new()
	unit_root.add_child(unit)
	unit.setup(source_id, stats, faction, room_id)
	unit.downed.connect(_on_unit_downed)
	return unit

func _scaled_monster_stats(monster_id: String) -> Dictionary:
	var stats = DataRegistry.monster(monster_id).duplicate(true)
	var roster: Dictionary = monster_roster[monster_id]
	var level = int(roster["level"])
	stats["max_hp"] = int(stats.get("max_hp", 100)) + (level - 1) * 20
	stats["atk"] = int(stats.get("atk", 10)) + (level - 1) * 3
	stats["def"] = int(stats.get("def", 0)) + (level - 1)
	_apply_specialization_stats(monster_id, stats)
	_apply_promotion_stats(monster_id, stats)
	_apply_growth_preparation_stats(monster_id, stats)
	return stats

func _result_growth_preparation_rule(monster_id: String) -> Dictionary:
	return Dictionary(RESULT_GROWTH_PREPARATION_RULES.get(monster_id, {})).duplicate(true)

func _result_growth_preparation_preview(monster_id: String) -> String:
	return str(RESULT_GROWTH_PREPARATION_RULES.get(monster_id, {}).get("preview", ""))

func _growth_preparation_combat_name(monster_id: String) -> String:
	return str(RESULT_GROWTH_PREPARATION_RULES.get(monster_id, {}).get("combat_name", "집중 준비"))

func _result_growth_preparation_summary(monster_id: String) -> String:
	return str(RESULT_GROWTH_PREPARATION_RULES.get(monster_id, {}).get("summary", ""))

func _growth_preparation_active(monster_id: String) -> bool:
	if not monster_roster.has(monster_id) or not RESULT_GROWTH_PREPARATION_RULES.has(monster_id):
		return false
	var roster: Dictionary = monster_roster[monster_id]
	var rule: Dictionary = RESULT_GROWTH_PREPARATION_RULES[monster_id]
	return (
		int(roster.get("growth_preparation_day", -1)) == GameState.day
		and str(roster.get("growth_preparation_id", "")) == str(rule.get("id", ""))
	)

func _active_growth_preparation_line(monster_id: String) -> String:
	if not _growth_preparation_active(monster_id):
		return ""
	return "집중 준비 발동 · %s" % _result_growth_preparation_summary(monster_id)

func _apply_growth_preparation_stats(monster_id: String, stats: Dictionary) -> void:
	if not _growth_preparation_active(monster_id):
		return
	var rule: Dictionary = RESULT_GROWTH_PREPARATION_RULES[monster_id]
	for stat_name in rule.get("stat_multipliers", {}).keys():
		var key = str(stat_name)
		stats[key] = float(stats.get(key, 0.0)) * float(rule["stat_multipliers"][stat_name])
	for stat_name in rule.get("stat_bonuses", {}).keys():
		var key = str(stat_name)
		stats[key] = float(stats.get(key, 0.0)) + float(rule["stat_bonuses"][stat_name])
		if key not in ["move_speed", "attack_range", "attack_interval"]:
			stats[key] = int(round(float(stats[key])))

func _apply_specialization_stats(monster_id: String, stats: Dictionary) -> void:
	var rule = _monster_specialization(monster_id)
	if rule.is_empty():
		return
	for stat_name in rule.get("stat_multipliers", {}).keys():
		var key = str(stat_name)
		var scaled_value = float(stats.get(key, 0)) * float(rule["stat_multipliers"][stat_name])
		if key in ["move_speed", "attack_range", "attack_interval"]:
			stats[key] = scaled_value
		else:
			stats[key] = int(round(scaled_value))
	for stat_name in rule.get("stat_bonuses", {}).keys():
		var key = str(stat_name)
		stats[key] = float(stats.get(key, 0)) + float(rule["stat_bonuses"][stat_name])
		if key not in ["move_speed", "attack_range", "attack_interval"]:
			stats[key] = int(round(float(stats[key])))
	var role_tag = str(rule.get("role_tag", stats.get("role", "")))
	stats["role_tag"] = role_tag
	stats["role"] = role_tag

func _monster_specialization(monster_id: String) -> Dictionary:
	if not monster_roster.has(monster_id):
		return {}
	var specialization_id = str(monster_roster[monster_id].get("specialization_id", ""))
	if specialization_id == "" or not DataRegistry.has_method("specialization"):
		return {}
	return DataRegistry.specialization(specialization_id)

func _specializations_for_monster(monster_id: String) -> Array:
	var result: Array = []
	for specialization_id in DataRegistry.specializations.keys():
		var rule: Dictionary = DataRegistry.specialization(str(specialization_id))
		if str(rule.get("monster_id", "")) != monster_id:
			continue
		var copied_rule = rule.duplicate(true)
		copied_rule["id"] = str(specialization_id)
		result.append(copied_rule)
	result.sort_custom(func(a, b): return str(a.get("id", "")) < str(b.get("id", "")))
	return result

func _early_specialization_unlocked() -> bool:
	return GameState.day >= 2 and not DataRegistry.specializations.is_empty()

func _early_specialization_count() -> int:
	var count := 0
	for monster_id in _defense_monster_ids():
		if str(monster_roster[monster_id].get("specialization_id", "")) != "":
			count += 1
	return count

func _early_specialization_limit() -> int:
	if not _early_specialization_unlocked():
		return 0
	if GameState.day <= 3:
		return 1
	return _defense_monster_ids().size()

func _early_specialization_required_for_current_day() -> bool:
	return GameState.day in [2, 3] and _early_specialization_unlocked() and _early_specialization_count() == 0

func _specialization_block_reason(monster_id: String, specialization_id: String = "") -> String:
	if not _monster_available_for_defense(monster_id):
		return "지원 전용"
	if not _early_specialization_unlocked():
		return "DAY 2 해금"
	if str(monster_roster[monster_id].get("specialization_id", "")) != "":
		return "특화 완료"
	var options = _specializations_for_monster(monster_id)
	if options.is_empty():
		return "특화 없음"
	if specialization_id != "":
		var valid_option := false
		for option in options:
			if str(option.get("id", "")) == specialization_id:
				valid_option = true
				break
		if not valid_option:
			return "선택 불가"
	var limit = _early_specialization_limit()
	if limit > 0 and _early_specialization_count() >= limit:
		return "DAY 2~3에는 팀에서 1명만"
	return ""

func _can_choose_early_specialization(monster_id: String, specialization_id: String) -> bool:
	return monster_roster.has(monster_id) and _specialization_block_reason(monster_id, specialization_id) == ""

func _choose_early_specialization(monster_id: String, specialization_id: String) -> bool:
	var reason = _specialization_block_reason(monster_id, specialization_id)
	if reason != "":
		_log("전술 특화를 선택할 수 없습니다: %s." % reason)
		_set_screen(Constants.SCREEN_MONSTER)
		return false
	var rule = DataRegistry.specialization(specialization_id)
	monster_roster[monster_id]["specialization_id"] = specialization_id
	monster_roster[monster_id]["role_tag"] = str(rule.get("role_tag", ""))
	selected_monster_id = monster_id
	first_play_observation.record_choice("specialization", specialization_id, GameState.day, {"monster_id": monster_id, "specialization_id": specialization_id})
	first_play_observation.save_snapshot(GameState.day, false)
	_log("%s 전술 특화 확정: %s." % [_monster_display_name(monster_id), str(rule.get("display_name", specialization_id))])
	_set_screen(Constants.SCREEN_MONSTER)
	return true

func _monster_ai_behavior(monster_id: String) -> String:
	return str(_monster_specialization(monster_id).get("ai_behavior", ""))

func _apply_promotion_stats(monster_id: String, stats: Dictionary) -> void:
	var rule = _monster_promotion_rule(monster_id)
	if rule.is_empty():
		return
	for stat_name in rule.get("stat_multipliers", {}).keys():
		var current_value = float(stats.get(str(stat_name), 0))
		stats[str(stat_name)] = int(round(current_value * float(rule["stat_multipliers"][stat_name])))
	for stat_name in rule.get("stat_bonuses", {}).keys():
		stats[str(stat_name)] = int(stats.get(str(stat_name), 0)) + int(rule["stat_bonuses"][stat_name])
	stats["display_name"] = str(rule.get("display_name", stats.get("display_name", monster_id)))
	var combat_sprite := str(rule.get("combat_sprite", ""))
	if combat_sprite != "":
		stats["sprite"] = combat_sprite
	var role_tag = str(rule.get("role_tag", stats.get("role", "")))
	stats["role_tag"] = role_tag
	stats["role"] = role_tag

func _monster_promotion_rule(monster_id: String) -> Dictionary:
	if not monster_roster.has(monster_id):
		return {}
	var promotion_id = str(monster_roster[monster_id].get("promotion_id", ""))
	if promotion_id == "":
		return {}
	if not DataRegistry.has_method("evolution_rule"):
		return {}
	return DataRegistry.evolution_rule(promotion_id)

func _monster_display_name(monster_id: String) -> String:
	var rule = _monster_promotion_rule(monster_id)
	if not rule.is_empty():
		return str(rule.get("display_name", monster_id))
	var monster = DataRegistry.monster(monster_id)
	return str(monster.get("display_name", monster_id))

func _evolution_rules_for_monster(monster_id: String) -> Array:
	var result: Array = []
	for rule_id in DataRegistry.evolution_rules.keys():
		var rule: Dictionary = DataRegistry.evolution_rule(str(rule_id))
		if str(rule.get("monster_id", "")) == monster_id:
			var copied_rule = rule.duplicate(true)
			copied_rule["id"] = str(rule_id)
			result.append(copied_rule)
	result.sort_custom(func(a, b): return str(a.get("id", "")) < str(b.get("id", "")))
	return result

func _first_evolution_rule_for_monster(monster_id: String) -> Dictionary:
	var rules = _evolution_rules_for_monster(monster_id)
	if rules.is_empty():
		return {}
	return rules[0]


func _evolution_rule_choice(monster_id: String, rule_id: String = "") -> Dictionary:
	if rule_id == "":
		return _first_evolution_rule_for_monster(monster_id)
	var rule: Dictionary = DataRegistry.evolution_rule(rule_id)
	if rule.is_empty() or str(rule.get("monster_id", "")) != monster_id:
		return {}
	var choice := rule.duplicate(true)
	choice["id"] = rule_id
	return choice

func _promotion_unlocked() -> bool:
	if DataRegistry.evolution_rules.is_empty():
		return false
	var info = _campaign_day_info()
	return bool(info.get("promotion_unlocked", false)) or GameState.day >= 12

func _first_promotion_ready() -> bool:
	if first_promotion_completed:
		return true
	for monster_id in monster_roster.keys():
		if str(monster_roster[monster_id].get("promotion_id", "")) != "":
			return true
	return false

func _first_promotion_required_for_current_day() -> bool:
	var info = _campaign_day_info()
	return bool(info.get("requires_first_promotion", false))

func _first_promotion_limit_active() -> bool:
	var info = _campaign_day_info()
	return bool(info.get("first_promotion_limit", false))

func _promotion_limit_for_current_day() -> int:
	var info = _campaign_day_info()
	if info.has("promotion_limit"):
		return max(0, int(info.get("promotion_limit", 0)))
	if bool(info.get("first_promotion_limit", false)):
		return 1
	if _promotion_unlocked() and GameState.day < SECOND_PROMOTION_UNLOCK_DAY:
		return 1
	return 0

func _promotion_count() -> int:
	var count = 0
	for monster_id in monster_roster.keys():
		if str(monster_roster[monster_id].get("promotion_id", "")) != "":
			count += 1
	if count == 0 and first_promotion_completed:
		return 1
	return count

func _promotion_flags_met(rule: Dictionary) -> bool:
	for flag_value in rule.get("required_flags", []):
		var flag = str(flag_value)
		match flag:
			"campaign_chapter_two_started":
				if not campaign_chapter_two_started:
					return false
			"campaign_chapter_one_clear":
				if not campaign_chapter_one_clear:
					return false
			"campaign_stage_two_prepared":
				if not campaign_stage_two_prepared:
					return false
			"campaign_stage_two_unlock_ready":
				if not campaign_stage_two_unlock_ready:
					return false
			_:
				return false
	return true

func _promotion_block_reason(monster_id: String, rule_id: String = "") -> String:
	if not _monster_available_for_defense(monster_id):
		return "지원 전용"
	var rule = _evolution_rule_choice(monster_id, rule_id)
	if rule.is_empty():
		return "승급 없음"
	if not _promotion_unlocked() or GameState.day < int(rule.get("unlock_day", 1)):
		return "DAY %d 해금" % int(rule.get("unlock_day", 12))
	if not _promotion_flags_met(rule):
		return "2장 시작 필요"
	if str(monster_roster[monster_id].get("promotion_id", "")) != "":
		return "승급 완료"
	var promotion_limit = _promotion_limit_for_current_day()
	if promotion_limit > 0 and _promotion_count() >= promotion_limit:
		return "오늘은 %d명만" % promotion_limit
	if int(monster_roster[monster_id].get("level", 1)) < int(rule.get("required_level", 1)):
		return "Lv.%d 필요" % int(rule.get("required_level", 1))
	if int(monster_roster[monster_id].get("bond", 0)) < int(rule.get("required_bond", 0)):
		return "유대 %d 필요" % int(rule.get("required_bond", 0))
	if not GameState.can_pay(rule.get("cost", {})):
		return "비용 부족"
	return ""

func _can_promote_monster(monster_id: String, rule_id: String = "") -> bool:
	return monster_roster.has(monster_id) and _promotion_block_reason(monster_id, rule_id) == ""

func _can_promote_selected_monster() -> bool:
	return _can_promote_monster(selected_monster_id)

func _selected_promotion_rule() -> Dictionary:
	if selected_monster_id == "" or not monster_roster.has(selected_monster_id):
		return {}
	var active_rule = _monster_promotion_rule(selected_monster_id)
	if not active_rule.is_empty():
		var active_copy = active_rule.duplicate(true)
		active_copy["id"] = str(monster_roster[selected_monster_id].get("promotion_id", ""))
		return active_copy
	return _first_evolution_rule_for_monster(selected_monster_id)

func _selected_promotion_summary() -> String:
	var rule = _selected_promotion_rule()
	if rule.is_empty():
		return "이 몬스터는 아직 승급 규칙이 없습니다."
	var role_tag = str(rule.get("role_tag", "role"))
	if str(monster_roster[selected_monster_id].get("promotion_id", "")) != "":
		return "%s / %s / %s" % [str(rule.get("display_name", "")), role_tag, str(rule.get("role_summary", ""))]
	return "%s 후보 / %s / %s" % [str(rule.get("display_name", "")), role_tag, str(rule.get("balance_note", ""))]

func _selected_promotion_button_text() -> String:
	var rule = _selected_promotion_rule()
	if rule.is_empty():
		return "승급 없음"
	var reason = _promotion_block_reason(selected_monster_id)
	if reason == "":
		return "승급  %s" % _cost_label(rule.get("cost", {}))
	if reason == "승급 완료":
		return "승급 완료"
	return "승급 조건: %s" % reason

func _selected_promotion_icon() -> String:
	var rule = _selected_promotion_rule()
	if rule.is_empty():
		return ""
	return str(rule.get("icon", ""))

func _promotion_skill_upgrade(monster_id: String, skill_id: String) -> Dictionary:
	var rule = _monster_promotion_rule(monster_id)
	if rule.is_empty():
		return {}
	var upgrade = rule.get("skill_upgrade", {})
	if not (upgrade is Dictionary):
		return {}
	if str(upgrade.get("skill_id", "")) != skill_id:
		return {}
	return upgrade

func _promotion_skill_float(monster_id: String, skill_id: String, key: String, fallback: float = 0.0) -> float:
	var upgrade = _promotion_skill_upgrade(monster_id, skill_id)
	if upgrade.is_empty():
		return fallback
	return float(upgrade.get(key, fallback))

func _specialization_skill_upgrade(monster_id: String, skill_id: String) -> Dictionary:
	var rule = _monster_specialization(monster_id)
	if rule.is_empty():
		return {}
	var upgrade = rule.get("skill_upgrade", {})
	if not (upgrade is Dictionary) or str(upgrade.get("skill_id", "")) != skill_id:
		return {}
	return upgrade

func _combat_skill_float(monster_id: String, skill_id: String, key: String, fallback: float = 0.0) -> float:
	var value = fallback
	var specialization_upgrade = _specialization_skill_upgrade(monster_id, skill_id)
	if not specialization_upgrade.is_empty():
		value += float(specialization_upgrade.get(key, 0.0))
	var promotion_upgrade = _promotion_skill_upgrade(monster_id, skill_id)
	if not promotion_upgrade.is_empty():
		value += float(promotion_upgrade.get(key, 0.0))
	return value

func _monster_exp_to_next(level: int) -> int:
	return 50 + max(0, level - 1) * 30

func _reset_battle_contribution_stats() -> void:
	battle_contribution_stats.clear()
	battle_activity_exp_applied = false
	for monster_id in monster_roster.keys():
		if not _monster_available_for_defense(str(monster_id)):
			continue
		battle_contribution_stats[monster_id] = {
			"damage_dealt": 0,
			"damage_absorbed": 0,
			"finishing_blows": 0,
			"facility_value": 0,
			"shared_exp": 0,
			"activity_exp": 0,
			"activity_breakdown": {
				"attack": 0,
				"defense": 0,
				"finisher": 0,
				"facility": 0
			}
		}

func _record_monster_contribution(monster_id: String, key: String, amount: int) -> void:
	if amount <= 0 or not monster_roster.has(monster_id) or not _monster_available_for_defense(monster_id):
		return
	if not battle_contribution_stats.has(monster_id):
		battle_contribution_stats[monster_id] = {
			"damage_dealt": 0,
			"damage_absorbed": 0,
			"finishing_blows": 0,
			"facility_value": 0,
			"shared_exp": 0,
			"activity_exp": 0,
			"activity_breakdown": {}
		}
	var stats: Dictionary = battle_contribution_stats[monster_id]
	stats[key] = int(stats.get(key, 0)) + amount
	battle_contribution_stats[monster_id] = stats

func _activity_exp_breakdown(stats: Dictionary) -> Dictionary:
	return {
		"attack": mini(ACTIVITY_EXP_DAMAGE_MAX, int(floor(float(stats.get("damage_dealt", 0)) / ACTIVITY_EXP_DAMAGE_STEP))),
		"defense": mini(ACTIVITY_EXP_ABSORB_MAX, int(floor(float(stats.get("damage_absorbed", 0)) / ACTIVITY_EXP_ABSORB_STEP))),
		"finisher": mini(ACTIVITY_EXP_FINISH_MAX, int(stats.get("finishing_blows", 0)) * ACTIVITY_EXP_FINISH_PER_BLOW),
		"facility": mini(ACTIVITY_EXP_FACILITY_MAX, int(floor(float(stats.get("facility_value", 0)) / ACTIVITY_EXP_FACILITY_STEP)))
	}

func _apply_battle_activity_exp() -> void:
	if battle_activity_exp_applied:
		return
	battle_activity_exp_applied = true
	for monster_id_value in battle_contribution_stats.keys():
		var monster_id = str(monster_id_value)
		if not monster_roster.has(monster_id) or not _monster_available_for_defense(monster_id):
			continue
		var stats: Dictionary = battle_contribution_stats[monster_id]
		var breakdown := _activity_exp_breakdown(stats)
		var activity_exp = mini(Constants.ACTIVITY_EXP_CAP, (
			int(breakdown.get("attack", 0))
			+ int(breakdown.get("defense", 0))
			+ int(breakdown.get("finisher", 0))
			+ int(breakdown.get("facility", 0))
		))
		stats["activity_breakdown"] = breakdown
		stats["activity_exp"] = activity_exp
		battle_contribution_stats[monster_id] = stats
		monster_roster[monster_id]["exp"] = int(monster_roster[monster_id].get("exp", 0)) + activity_exp

func _capture_battle_growth_start() -> void:
	battle_growth_start.clear()
	last_growth_summary.clear()
	result_growth_reviewed = false
	result_growth_choice_monster_id = ""
	result_growth_choice_applied = false
	last_growth_choice_summary.clear()
	_reset_battle_contribution_stats()
	for monster_id in monster_roster.keys():
		if not _monster_available_for_defense(str(monster_id)):
			continue
		var roster: Dictionary = monster_roster[monster_id]
		battle_growth_start[monster_id] = {
			"level": int(roster.get("level", 1)),
			"exp": int(roster.get("exp", 0)),
			"bond": int(roster.get("bond", 0))
		}

func _apply_monster_levelups(monster_id: String) -> int:
	if not monster_roster.has(monster_id):
		return 0
	var roster: Dictionary = monster_roster[monster_id]
	var level := int(roster.get("level", 1))
	var exp := int(roster.get("exp", 0))
	var gained := 0
	var guard := 0
	while exp >= _monster_exp_to_next(level) and guard < 50:
		exp -= _monster_exp_to_next(level)
		level += 1
		gained += 1
		guard += 1
	monster_roster[monster_id]["level"] = level
	monster_roster[monster_id]["exp"] = exp
	return gained

func _finalize_battle_growth(win: bool = false) -> Array:
	_apply_battle_activity_exp()
	var summary := []
	for monster_id in monster_roster.keys():
		if not _monster_available_for_defense(str(monster_id)):
			continue
		var roster: Dictionary = monster_roster[monster_id]
		var start: Dictionary = battle_growth_start.get(monster_id, {})
		var level_before := int(start.get("level", roster.get("level", 1)))
		var exp_before := int(start.get("exp", 0))
		var exp_before_levelup := int(roster.get("exp", 0))
		var exp_gain = max(0, exp_before_levelup - exp_before)
		_apply_monster_levelups(monster_id)
		var level_after := int(monster_roster[monster_id].get("level", 1))
		var exp_after := int(monster_roster[monster_id].get("exp", 0))
		var contribution: Dictionary = battle_contribution_stats.get(monster_id, {})
		var bond_before := int(start.get("bond", roster.get("bond", 0)))
		var bond_gain: int = (3 if win else 1) + mini(3, int(int(contribution.get("activity_exp", 0)) / 2))
		if int(contribution.get("finishing_blows", 0)) > 0:
			bond_gain += 1
		var bond_result := _grant_monster_bond(str(monster_id), bond_gain)
		var bond_after := int(bond_result.get("after", bond_before))
		var rank_after := int(bond_result.get("rank", _monster_bond_rank(bond_after)))
		var unlocked_memory_id := str(bond_result.get("unlocked_memory_id", ""))
		summary.append({
			"monster_id": monster_id,
			"display_name": _monster_display_name(monster_id),
			"level_before": level_before,
			"level_after": level_after,
			"levels_gained": max(0, level_after - level_before),
			"exp_before": exp_before,
			"exp_after": exp_after,
			"exp_gain": exp_gain,
			"next_exp": _monster_exp_to_next(level_after),
			"shared_exp": int(contribution.get("shared_exp", 0)),
			"activity_exp": int(contribution.get("activity_exp", 0)),
			"activity_breakdown": contribution.get("activity_breakdown", {}).duplicate(true),
			"damage_dealt": int(contribution.get("damage_dealt", 0)),
			"damage_absorbed": int(contribution.get("damage_absorbed", 0)),
			"finishing_blows": int(contribution.get("finishing_blows", 0)),
			"facility_value": int(contribution.get("facility_value", 0)),
			"bond_before": bond_before,
			"bond_after": bond_after,
			"bond_gain": bond_after - bond_before,
			"bond_rank": rank_after,
			"unlocked_memory_id": unlocked_memory_id
		})
	last_growth_summary = summary
	return summary

func _result_growth_lines() -> Array:
	var lines := []
	for row in last_growth_summary:
		var name := str(row.get("display_name", row.get("monster_id", "")))
		var level_after := int(row.get("level_after", 1))
		var gained_levels := int(row.get("levels_gained", 0))
		var exp_gain := int(row.get("exp_gain", 0))
		var exp_after := int(row.get("exp_after", 0))
		var next_exp := int(row.get("next_exp", _monster_exp_to_next(level_after)))
		if gained_levels > 0:
			lines.append("%s: EXP +%d / Lv.%d -> Lv.%d" % [name, exp_gain, int(row.get("level_before", level_after)), level_after])
		else:
			lines.append("%s: EXP +%d / Lv.%d (%d/%d)" % [name, exp_gain, level_after, exp_after, next_exp])
		if int(row.get("choice_bonus_exp", 0)) > 0:
			var last_index = lines.size() - 1
			lines[last_index] = "%s / 집중 +%d" % [str(lines[last_index]), int(row.get("choice_bonus_exp", 0))]
		var bond_gain := int(row.get("bond_gain", 0))
		if bond_gain > 0:
			lines.append("%s: 유대 +%d · %d/100 (%s)" % [name, bond_gain, int(row.get("bond_after", 0)), _monster_bond_rank_name(int(row.get("bond_after", 0)))])
		if str(row.get("unlocked_memory_id", "")) != "":
			lines.append("%s와의 새 기억이 해금되었습니다." % name)
	if lines.is_empty():
		lines.append("이번 전투 성장 기록이 없습니다.")
	return lines

func _result_growth_choice_bonus() -> int:
	return RESULT_GROWTH_CHOICE_EXP_BONUS

func _result_growth_choice_required() -> bool:
	if _is_regular_campaign_final_battle():
		return false
	return bool(result_summary.get("win", false)) and not last_growth_summary.is_empty()

func _can_choose_result_growth(monster_id: String) -> bool:
	return (
		current_screen == Constants.SCREEN_RESULT
		and _result_growth_choice_required()
		and not result_growth_choice_applied
		and monster_roster.has(monster_id)
		and _growth_row_index(monster_id) >= 0
	)

func _choose_result_growth(monster_id: String) -> bool:
	if not _can_choose_result_growth(monster_id):
		return false
	var bonus := _result_growth_choice_bonus()
	var preparation := _result_growth_preparation_rule(monster_id)
	var preparation_day := GameState.day + 1
	var before_level = int(monster_roster[monster_id].get("level", 1))
	var before_exp = int(monster_roster[monster_id].get("exp", 0))
	monster_roster[monster_id]["exp"] = before_exp + bonus
	monster_roster[monster_id]["growth_preparation_id"] = str(preparation.get("id", ""))
	monster_roster[monster_id]["growth_preparation_day"] = preparation_day
	_apply_monster_levelups(monster_id)
	var row_index := _growth_row_index(monster_id)
	if row_index >= 0:
		var row: Dictionary = last_growth_summary[row_index]
		var level_after := int(monster_roster[monster_id].get("level", before_level))
		var exp_after := int(monster_roster[monster_id].get("exp", before_exp))
		row["choice_bonus_exp"] = int(row.get("choice_bonus_exp", 0)) + bonus
		row["exp_gain"] = int(row.get("exp_gain", 0)) + bonus
		row["level_after"] = level_after
		row["levels_gained"] = max(0, level_after - int(row.get("level_before", before_level)))
		row["exp_after"] = exp_after
		row["next_exp"] = _monster_exp_to_next(level_after)
		last_growth_summary[row_index] = row
	result_growth_choice_monster_id = monster_id
	result_growth_choice_applied = true
	selected_monster_id = monster_id
	first_play_observation.record_choice("growth_focus", monster_id, GameState.day, {
		"monster_id": monster_id,
		"preparation_id": str(preparation.get("id", "")),
		"preparation_day": preparation_day
	})
	first_play_observation.save_snapshot(GameState.day, false)
	last_growth_choice_summary = {
		"monster_id": monster_id,
		"display_name": _monster_display_name(monster_id),
		"bonus_exp": bonus,
		"preparation_id": str(preparation.get("id", "")),
		"preparation_day": preparation_day,
		"preparation_preview": str(preparation.get("preview", "")),
		"preparation_summary": str(preparation.get("summary", "")),
		"level_before": before_level,
		"level_after": int(monster_roster[monster_id].get("level", before_level)),
		"exp_before": before_exp,
		"exp_after": int(monster_roster[monster_id].get("exp", before_exp))
	}
	result_summary["growth"] = last_growth_summary.duplicate(true)
	_log("%s 집중 성장: EXP +%d, %s." % [_monster_display_name(monster_id), bonus, str(preparation.get("summary", "다음 방어 준비"))])
	_set_screen(Constants.SCREEN_RESULT)
	return true

func _growth_row_index(monster_id: String) -> int:
	for index in range(last_growth_summary.size()):
		var row: Dictionary = last_growth_summary[index]
		if str(row.get("monster_id", "")) == monster_id:
			return index
	return -1

func _review_growth_from_result() -> void:
	if not _tutorial_allows("growth_reviewed", {"day": GameState.day}):
		return
	if _result_growth_choice_required() and not result_growth_choice_applied:
		_log("성장 확인 전에 집중 성장 대상을 먼저 선택하세요.")
		_set_screen(Constants.SCREEN_RESULT)
		return
	result_growth_reviewed = true
	_tutorial_emit_action("growth_reviewed", {"day": GameState.day})
	_log("전투 성장 내용을 확인했습니다.")
	_set_screen(Constants.SCREEN_RESULT)

func _clear_units() -> void:
	for unit in monster_units + enemy_units:
		if is_instance_valid(unit):
			unit.queue_free()
	monster_units.clear()
	enemy_units.clear()
	selected_unit = null

func _clear_effects() -> void:
	combat_scene.clear_effects()

func _refresh_unit_rooms() -> void:
	combat_scene.refresh_unit_rooms()

func _update_ai_paths() -> void:
	combat_scene.update_ai_paths()

func _update_monster_path(unit: Node) -> void:
	combat_scene.update_monster_path(unit)

func _update_enemy_path(unit: Node) -> void:
	combat_scene.update_enemy_path(unit)

func _nearest_enemy_in_rooms(unit: Node, room_ids: Array) -> Node:
	return combat_scene.nearest_enemy_in_rooms(unit, room_ids)

func _nearest_monster_in_rooms(unit: Node, room_ids: Array) -> Node:
	return combat_scene.nearest_monster_in_rooms(unit, room_ids)

func _move_unit_to_room(unit: Node, room_id: String) -> void:
	combat_scene.move_unit_to_room(unit, room_id)

func _move_unit_to_point(unit: Node, point: Vector2) -> void:
	combat_scene.move_unit_to_point(unit, point)

func _update_room_effects(delta: float) -> void:
	combat_scene.update_room_effects(delta)

func _update_attacks(delta: float) -> void:
	combat_scene.update_attacks(delta)

func _try_attack(attacker: Node, opponents: Array) -> void:
	combat_scene.try_attack(attacker, opponents)

func _on_unit_downed(unit: Node) -> void:
	combat_scene.on_unit_downed(unit)

func _check_combat_end() -> void:
	combat_scene.check_combat_end()

func _finish_combat(win: bool, reason: String) -> void:
	combat_scene.finish_combat(win, reason)

func _count_downed_enemies() -> int:
	return combat_scene.count_downed_enemies()

func _advance_after_result() -> void:
	if _is_regular_campaign_final_battle():
		if bool(result_summary.get("win", false)):
			_show_campaign_ending()
		else:
			_prepare_finale_retry()
		return
	GameState.advance_day()
	_tutorial_emit_action("day_advanced", {"day": GameState.day})
	if onboarding_enabled and not GameState.onboarding_complete and GameState.day <= GameState.max_day:
		_onboarding_enter_management_day(GameState.day, true)
	else:
		_enter_campaign_management_day(true)

func _continue_from_result() -> void:
	if onboarding_enabled and tutorial_gate_enabled and tutorial_manager.is_active_for_stage(onboarding_stage_id) and tutorial_manager.expected_action() == "growth_reviewed":
		_log("몬스터 성장 내용을 먼저 확인하세요.")
		_tutorial_build_overlay()
		return
	if onboarding_enabled and not GameState.onboarding_complete:
		if GameState.victory and GameState.day >= GameState.max_day:
			GameState.victory = false
			GameState.day = 4
			_onboarding_set_stage("LV12_DAY04_RAID_PREVIEW")
			_set_screen(Constants.SCREEN_RAID_PREVIEW)
			return
		if not GameState.defeat and GameState.day < GameState.max_day:
			_advance_after_result()
			return
	if _is_regular_campaign_final_battle():
		if bool(result_summary.get("win", false)):
			_show_campaign_ending()
		else:
			_prepare_finale_retry()
		return
	if bool(result_summary.get("win", false)) and not GameState.victory:
		_advance_after_result()
		return
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _advance_day_from_management() -> void:
	if map_editor_active:
		_log("맵 편집을 저장하거나 취소한 뒤 날짜를 진행하세요.")
		return
	if GameState.day >= REGULAR_CAMPAIGN_FINAL_DAY:
		if campaign_completed:
			_show_campaign_ending()
		else:
			_log("DAY %d가 정규 캠페인의 마지막 날입니다. 최종 공성전을 완료하세요." % REGULAR_CAMPAIGN_FINAL_DAY)
		return
	_clear_management_action_mode(false)
	if not _tutorial_allows("day_advanced", {"day": GameState.day + 1}):
		return
	if not _ensure_required_main_route_for_current_layout("날짜 진행"):
		return
	GameState.advance_day()
	_tutorial_emit_action("day_advanced", {"day": GameState.day})
	_log("하루를 넘겼습니다. DAY %d." % GameState.day)
	if onboarding_enabled and not GameState.onboarding_complete and GameState.day <= GameState.max_day:
		_onboarding_enter_management_day(GameState.day, true)
	else:
		_enter_campaign_management_day(true)

func _open_monster_screen() -> void:
	if map_editor_active:
		_log("맵 편집을 저장하거나 취소한 뒤 몬스터 관리를 여세요.")
		return
	_clear_management_action_mode(false)
	_ensure_selected_monster_available_for_defense()
	_set_screen(Constants.SCREEN_MONSTER)

func _select_monster(monster_id: String) -> void:
	if not _monster_available_for_defense(monster_id):
		_log("%s는 현재 원정/정찰 지원 전용입니다." % str(DataRegistry.monster(monster_id).get("display_name", monster_id)))
		_ensure_selected_monster_available_for_defense()
		_set_screen(Constants.SCREEN_MONSTER)
		return
	selected_monster_id = monster_id
	_tutorial_emit_action("unit_selected", {"monster_id": monster_id, "unit_id": monster_id})
	_set_screen(Constants.SCREEN_MONSTER)
	if onboarding_enabled:
		match monster_id:
			"slime":
				_onboarding_emit_trigger("select_slime")
			"goblin":
				_onboarding_emit_trigger("select_goblin")
			"imp":
				_onboarding_emit_trigger("select_imp")

func _train_selected_monster() -> void:
	if not _monster_available_for_defense(selected_monster_id):
		_log("%s는 현재 원정/정찰 지원 전용이라 훈련할 수 없습니다." % str(DataRegistry.monster(selected_monster_id).get("display_name", selected_monster_id)))
		_ensure_selected_monster_available_for_defense()
		_set_screen(Constants.SCREEN_MONSTER)
		return
	if not GameState.pay({"gold": 30}):
		_log("훈련 비용이 부족합니다.")
		return
	var roster: Dictionary = monster_roster[selected_monster_id]
	roster["exp"] = int(roster["exp"]) + 20
	var gained_levels = _apply_monster_levelups(selected_monster_id)
	if gained_levels > 0:
		_log("%s 레벨 업." % DataRegistry.monster(selected_monster_id).get("display_name", selected_monster_id))
	else:
		_log("%s 훈련 완료." % DataRegistry.monster(selected_monster_id).get("display_name", selected_monster_id))
	_set_screen(Constants.SCREEN_MONSTER)

func _promote_selected_monster() -> void:
	_promote_monster(selected_monster_id)

func _promote_monster(monster_id: String, rule_id: String = "") -> bool:
	if not monster_roster.has(monster_id):
		return false
	var rule = _evolution_rule_choice(monster_id, rule_id)
	if rule.is_empty():
		_log("아직 승급 규칙이 없습니다.")
		return false
	var reason = _promotion_block_reason(monster_id, str(rule.get("id", rule_id)))
	if reason != "":
		_log("승급할 수 없습니다: %s." % reason)
		_set_screen(Constants.SCREEN_MONSTER)
		return false
	if not GameState.pay(rule.get("cost", {})):
		_log("승급 비용이 부족합니다.")
		_set_screen(Constants.SCREEN_MONSTER)
		return false
	var selected_rule_id := str(rule.get("id", ""))
	monster_roster[monster_id]["promotion_id"] = selected_rule_id
	monster_roster[monster_id]["promotion_stage"] = int(rule.get("stage", 1))
	monster_roster[monster_id]["role_tag"] = str(rule.get("role_tag", ""))
	first_promotion_completed = true
	_log("%s 진화 완료: %s." % [DataRegistry.monster(monster_id).get("display_name", monster_id), str(rule.get("display_name", selected_rule_id))])
	_set_screen(Constants.SCREEN_MONSTER)
	return true

func _place_selected_monster() -> void:
	if _assign_monster_to_room(selected_monster_id, selected_room):
		_set_screen(current_screen)

func _start_monster_placement(monster_id: String) -> void:
	if not monster_roster.has(monster_id):
		return
	if not _monster_available_for_defense(monster_id):
		_log("%s는 현재 원정/정찰 지원 전용입니다." % str(DataRegistry.monster(monster_id).get("display_name", monster_id)))
		return
	if map_editor_active:
		_log("맵 편집을 저장하거나 취소한 뒤 몬스터를 배치하세요.")
		return
	selected_monster_id = monster_id
	deploy_pick_monster_id = monster_id
	build_pick_mode = false
	facility_change_panel_open = false
	var current_room = str(monster_roster[monster_id].get("room", ""))
	if rooms.has(current_room):
		selected_room = current_room
	var monster_name = str(DataRegistry.monster(monster_id).get("display_name", monster_id))
	_log("%s 배치 중: 맵에서 보낼 방을 클릭하세요." % monster_name)
	_tutorial_emit_action("unit_selected", {"monster_id": monster_id, "unit_id": monster_id, "room_id": current_room})
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _clear_map_editor_path_drag() -> void:
	map_editor_path_drag_active = false
	map_editor_path_drag_source = ""
	map_editor_path_drag_target = ""
	map_editor_path_drag_position = Vector2.ZERO
	map_editor_path_drag_start_position = Vector2.ZERO

func _assign_monster_to_selected_room(monster_id: String) -> void:
	if _assign_monster_to_room(monster_id, selected_room):
		_set_screen(Constants.SCREEN_MANAGEMENT)

func _placement_count(room_id: String, ignore_monster_id: String = "") -> int:
	var count = 0
	for monster_id in monster_roster.keys():
		if monster_id == ignore_monster_id:
			continue
		if not _monster_available_for_defense(str(monster_id)):
			continue
		if monster_roster[monster_id].get("room", "") == room_id:
			count += 1
	return count

func _assign_monster_to_room(monster_id: String, room_id: String) -> bool:
	if not monster_roster.has(monster_id) or not rooms.has(room_id):
		return false
	if not _monster_available_for_defense(monster_id):
		_log("%s는 현재 원정/정찰 지원 전용입니다." % str(DataRegistry.monster(monster_id).get("display_name", monster_id)))
		return false
	if not _tutorial_allows("unit_deployed", {"monster_id": monster_id, "unit_id": monster_id, "room_id": room_id}):
		return false
	if str(monster_roster[monster_id].get("room", "")) == room_id:
		selected_monster_id = monster_id
		selected_room = room_id
		_tutorial_emit_action("unit_deployed", {"monster_id": monster_id, "unit_id": monster_id, "room_id": room_id})
		return true
	if rooms[room_id].get("type", "") == "build_slot":
		_log("비어 있는 건설 슬롯에는 배치할 수 없습니다.")
		return false
	if _placement_count(room_id, monster_id) >= int(rooms[room_id].get("max_monsters", 1)):
		_log("%s의 배치 한도가 찼습니다. 현재 %d/%d." % [
			rooms[room_id].get("display_name", room_id),
			_placement_count(room_id, monster_id),
			int(rooms[room_id].get("max_monsters", 1))
		])
		return false
	monster_roster[monster_id]["room"] = room_id
	selected_monster_id = monster_id
	selected_room = room_id
	var max_count = int(rooms[room_id].get("max_monsters", 1))
	var placed_count = _placement_count(room_id)
	_log("%s을(를) %s에 배치했습니다. 현재 %d/%d, 남은 자리 %d." % [
		DataRegistry.monster(monster_id).get("display_name", monster_id),
		rooms[room_id].get("display_name", room_id),
		placed_count,
		max_count,
		max(0, max_count - placed_count)
	])
	_tutorial_emit_action("unit_deployed", {"monster_id": monster_id, "unit_id": monster_id, "room_id": room_id})
	if onboarding_enabled:
		_onboarding_emit_trigger("unit_deployed")
	return true

func _build_selected_slot() -> void:
	if map_editor_active:
		_log("맵 편집을 저장하거나 취소한 뒤 건설하세요.")
		return
	if build_pick_mode:
		_cancel_management_action_mode()
		return
	if _first_changeable_room() == "":
		_log("건설 가능한 방이 없습니다.")
		return
	build_pick_mode = true
	build_pick_facility_id = _default_build_facility_choice()
	build_palette_target_room = ""
	build_preview_room_id = ""
	build_blocked_room_id = ""
	deploy_pick_monster_id = ""
	facility_change_panel_open = false
	_log("건설할 시설을 고른 뒤 맵에서 후보 방을 클릭하세요. 확정 전에는 비용을 쓰지 않습니다.")
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _open_build_palette_for_room(room_id: String) -> void:
	if map_editor_active:
		return
	if not _can_change_room_facility(room_id):
		return
	selected_room = room_id
	build_pick_mode = true
	build_pick_facility_id = ""
	build_palette_target_room = room_id
	build_preview_room_id = ""
	build_blocked_room_id = ""
	deploy_pick_monster_id = ""
	facility_change_panel_open = false
	_log("%s 선택. 왼쪽 팔레트에서 시설을 고르면 미리보기가 표시됩니다." % display_name_for_instance(room_id))
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _select_build_target_room(room_id: String) -> void:
	if not build_pick_mode:
		return
	if not _can_change_room_facility(room_id):
		selected_room = room_id
		build_palette_target_room = ""
		build_preview_room_id = ""
		build_blocked_room_id = room_id
		_log("%s은(는) 고정 시설이라 변경할 수 없습니다. 이전 건설 후보를 해제했습니다." % display_name_for_instance(room_id))
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	if build_pick_facility_id == "":
		selected_room = room_id
		build_palette_target_room = room_id
		build_preview_room_id = ""
		build_blocked_room_id = ""
		_log("%s 선택. 왼쪽 팔레트에서 시설을 고르세요." % display_name_for_instance(room_id))
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	_set_build_preview_target(room_id)
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _facility_choices() -> Array:
	return _unlocked_facility_choices(FACILITY_CHOICES)

func _build_facility_choices() -> Array:
	return _unlocked_facility_choices(["watch_post", "ward_core", "barracks", "treasure", "recovery", "build_slot"])

func _unlocked_facility_choices(candidates: Array) -> Array:
	var unlocked: Array = _castle_stage_info().get("unlocked_facilities", [])
	var result: Array = []
	for facility_id_value in candidates:
		var facility_id := str(facility_id_value)
		if unlocked.has(facility_id):
			result.append(facility_id)
	return result

func _facility_unlocked(facility_id: String) -> bool:
	return _unlocked_facility_choices([facility_id]).has(facility_id)

func _default_build_facility_choice() -> String:
	var choices := _build_facility_choices()
	if choices.is_empty():
		return ""
	return str(choices[0])

func _set_build_facility(facility_id: String) -> void:
	if not _build_facility_choices().has(facility_id):
		return
	first_play_observation.record_choice("facility", facility_id, GameState.day, {"facility_id": facility_id})
	first_play_observation.save_snapshot(GameState.day, false)
	build_pick_facility_id = facility_id
	if not build_pick_mode:
		build_pick_mode = true
		deploy_pick_monster_id = ""
		facility_change_panel_open = false
	if build_palette_target_room != "" and _can_change_room_facility(build_palette_target_room):
		var target_room = build_palette_target_room
		build_palette_target_room = ""
		_set_build_preview_target(target_room)
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	if build_preview_room_id != "":
		_set_build_preview_target(build_preview_room_id)
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	_log("%s 선택. 맵에서 후보 방을 클릭한 뒤 건설 확정을 누르세요." % _facility_definition(facility_id).get("display_name", facility_id))
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _set_build_preview_target(room_id: String) -> void:
	if not build_pick_mode:
		return
	if not _can_change_room_facility(room_id):
		return
	selected_room = room_id
	build_preview_room_id = room_id
	build_blocked_room_id = ""
	var facility_name = str(_facility_definition(build_pick_facility_id).get("display_name", "시설"))
	_log("%s에 %s 미리보기. 경로 영향을 확인한 뒤 건설 확정을 누르세요." % [display_name_for_instance(room_id), facility_name])

func _confirm_build_preview() -> bool:
	if not build_pick_mode:
		return false
	if build_pick_facility_id == "":
		_log("먼저 왼쪽 팔레트에서 시설을 고르세요.")
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return false
	if build_preview_room_id == "":
		_log("먼저 맵에서 건설 후보 방을 클릭하세요.")
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return false
	var target_room = build_preview_room_id
	var target_facility = build_pick_facility_id
	if _change_room_facility(target_room, target_facility):
		_clear_management_action_mode(false)
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return true
	build_pick_mode = true
	build_pick_facility_id = target_facility
	build_preview_room_id = target_room if _can_change_room_facility(target_room) else ""
	_set_screen(Constants.SCREEN_MANAGEMENT)
	return false

func _facility_short_label(facility_id: String) -> String:
	return _facility_definition(facility_id).get("short_label", facility_id)

func _facility_cost_label(facility_id: String) -> String:
	return _cost_label(_facility_definition(facility_id).get("cost", {}))

func _can_change_room_facility(room_id: String) -> bool:
	if not rooms.has(room_id):
		return false
	if str(rooms[room_id].get("type", "")) == "legacy":
		return false
	return not LOCKED_FACILITY_ROOMS.has(room_id)

func _first_changeable_room() -> String:
	for room_id in rooms.keys():
		if _can_change_room_facility(str(room_id)):
			return str(room_id)
	return ""

func _toggle_facility_change_panel() -> void:
	if map_editor_active:
		_log("맵 편집을 저장하거나 취소한 뒤 시설을 변경하세요.")
		return
	if not _can_change_room_facility(selected_room):
		_log("이 방은 고정 시설이라 변경할 수 없습니다.")
		return
	facility_change_panel_open = not facility_change_panel_open
	if facility_change_panel_open:
		_clear_management_action_mode(false)
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _close_facility_change_panel() -> void:
	facility_change_panel_open = false
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _cancel_management_action_mode() -> void:
	if not _management_action_mode_active() and not facility_change_panel_open:
		return
	facility_change_panel_open = false
	_clear_management_action_mode(false)
	_log("현재 배치 작업을 취소했습니다.")
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _clear_management_action_mode(redraw: bool = true) -> void:
	build_pick_mode = false
	build_pick_facility_id = ""
	build_palette_target_room = ""
	build_preview_room_id = ""
	build_blocked_room_id = ""
	deploy_pick_monster_id = ""
	if redraw:
		queue_redraw()

func _management_action_mode_active() -> bool:
	return build_pick_mode or deploy_pick_monster_id != ""

func _management_action_mode_title() -> String:
	if build_pick_mode:
		if build_palette_target_room != "" and build_pick_facility_id == "":
			return "시설 선택"
		if build_pick_facility_id != "":
			return "%s 건설" % _facility_short_label(build_pick_facility_id)
		return "건설 위치 선택"
	if deploy_pick_monster_id != "":
		var monster_name = str(DataRegistry.monster(deploy_pick_monster_id).get("display_name", deploy_pick_monster_id))
		return "%s 배치" % monster_name
	return ""

func _management_action_mode_help() -> String:
	if build_pick_mode:
		if build_palette_target_room != "" and build_pick_facility_id == "":
			return "%s을(를) 바꾸는 중입니다.\n왼쪽 팔레트에서 시설을 고르면 미리보기만 표시됩니다.\nESC로 취소할 수 있습니다." % display_name_for_instance(build_palette_target_room)
		var facility_name = _facility_definition(build_pick_facility_id).get("display_name", "시설")
		var cost_label = _facility_cost_label(build_pick_facility_id) if build_pick_facility_id != "" else "-"
		return "%s 선택 중입니다.\n보라색 방/슬롯 클릭은 미리보기입니다.\n비용: %s" % [facility_name, cost_label]
	if deploy_pick_monster_id != "":
		return "노란색 방을 클릭하면 몬스터가 이동합니다.\n빨간 표시는 배치 불가 또는 정원 초과입니다."
	return ""

func _build_preview_ready() -> bool:
	return (
		build_pick_mode
		and build_pick_facility_id != ""
		and build_preview_room_id != ""
		and _can_change_room_facility(build_preview_room_id)
	)

func _build_preview_summary() -> String:
	if not build_pick_mode:
		return ""
	if build_pick_facility_id == "":
		return "시설을 먼저 고르세요."
	if build_preview_room_id == "":
		if build_blocked_room_id != "":
			return "%s: 건설 불가" % display_name_for_instance(build_blocked_room_id)
		return "맵에서 후보 방을 클릭하세요."
	var facility_name = str(_facility_definition(build_pick_facility_id).get("display_name", build_pick_facility_id))
	return "%s -> %s" % [display_name_for_instance(build_preview_room_id), facility_name]

func _build_preview_route_line(room_id: String = "") -> String:
	var target_room = room_id if room_id != "" else build_preview_room_id
	if target_room == "":
		if build_blocked_room_id != "":
			return "경로: 고정 시설은 후보로 쓸 수 없습니다."
		return "경로: 후보 방을 고르면 표시됩니다."
	var route = _main_route_instance_ids()
	if route.is_empty():
		return "경로: 입구-왕좌 길이 끊겨 있습니다."
	var route_index = route.find(target_room)
	if route_index >= 0:
		return "경로: 주요 침입로 위, 입구에서 %d번째 지점" % route_index
	if graph != null and graph.has_method("exits"):
		for neighbor_id in graph.exits(target_room):
			if route.has(neighbor_id):
				return "경로: 주요 침입로 바로 옆, %s와 연결" % display_name_for_instance(str(neighbor_id))
	return "경로: 주요 침입로 밖, 보조/보관 역할에 적합"

func _build_preview_effect_line() -> String:
	if build_pick_facility_id == "":
		return "효과: 시설을 고르면 표시됩니다."
	match build_pick_facility_id:
		"watch_post":
			return "효과: 이 방과 이웃 방의 적을 느리게 하고 받는 피해를 늘립니다."
		"barracks":
			return "효과: 이 방의 아군이 더 세게 때리고 피해를 덜 받습니다."
		"recovery":
			return "효과: 이 방의 아군을 전투 중 조금씩 회복합니다."
		"treasure":
			return "효과: 도둑이 노리는 보물 위치가 됩니다."
		"ward_core":
			return "효과: 성 전체의 방어 몬스터가 받는 피해를 줄입니다."
		"build_slot":
			return "효과: 이 방을 빈 건설 슬롯으로 되돌립니다."
		_:
			return "효과: 선택한 시설 효과를 적용합니다."

func _room_by_facility(facility_id: String, fallback: String = "") -> String:
	var facility_rooms := _rooms_by_facility(facility_id)
	if not facility_rooms.is_empty():
		return facility_rooms[0]
	return fallback

func _rooms_by_facility(facility_id: String) -> Array[String]:
	var result: Array[String] = []
	for room_id_value in rooms.keys():
		var room_id := str(room_id_value)
		if str(rooms[room_id].get("facility_role", "")) == facility_id:
			result.append(room_id)
	result.sort()
	return result

func _room_by_type(room_type: String, fallback: String = "") -> String:
	for room_id in rooms.keys():
		if str(rooms[room_id].get("type", "")) == room_type:
			return room_id
	return fallback

func _change_selected_room_facility(facility_id: String) -> bool:
	return _change_room_facility(selected_room, facility_id)

func _change_room_facility(room_id: String, facility_id: String) -> bool:
	if map_editor_active:
		_log("맵 편집을 저장하거나 취소한 뒤 시설을 변경하세요.")
		return false
	if not _can_change_room_facility(room_id):
		selected_room = room_id
		_log("입구, 가시 복도, 중앙 통로, 왕좌의 방은 변경할 수 없습니다.")
		return false
	if not _facility_unlocked(facility_id):
		_log("%s은(는) 다음 마왕성 진화 단계에서 해금됩니다." % _facility_short_label(facility_id))
		return false
	var definition = _facility_definition(facility_id)
	if definition.is_empty():
		return false
	selected_room = room_id
	if str(rooms[room_id].get("facility_role", "")) == facility_id:
		_log("이미 %s입니다." % definition.get("display_name", facility_id))
		return false
	var old_name = str(rooms[room_id].get("display_name", room_id))
	var cost: Dictionary = definition.get("cost", {})
	if not GameState.pay(cost):
		_log("시설 변경 비용이 부족합니다. 필요: %s." % _cost_label(cost))
		return false
	var replaced_rooms: Array[String] = []
	if UNIQUE_FACILITIES.has(facility_id):
		for other_room_id in rooms.keys():
			if other_room_id == room_id:
				continue
			if str(rooms[other_room_id].get("facility_role", "")) == facility_id and _can_change_room_facility(other_room_id):
				_apply_facility_to_room(other_room_id, "build_slot")
				replaced_rooms.append(other_room_id)
	_apply_facility_to_room(room_id, facility_id)
	_relocate_invalid_monsters()
	var moved_text = ""
	if not replaced_rooms.is_empty():
		moved_text = " 기존 %s 위치는 빈 슬롯으로 바뀌었습니다." % definition.get("display_name", facility_id)
	_refresh_quarter_map_from_rooms()
	facility_change_panel_open = false
	_log("%s을(를) %s로 변경했습니다.%s" % [old_name, definition.get("display_name", facility_id), moved_text])
	_set_screen(Constants.SCREEN_MANAGEMENT)
	return true

func _facility_upgrade_cost() -> Dictionary:
	var info = _campaign_day_info(7)
	var cost = info.get("facility_upgrade_cost", {})
	var base: Dictionary = cost if cost is Dictionary and not cost.is_empty() else {"gold": 90, "mana": 30}
	var multiplier: int = maxi(1, _facility_upgrade_level(selected_room))
	var scaled: Dictionary = {}
	for resource_id in base.keys():
		scaled[resource_id] = int(base[resource_id]) * multiplier
	return scaled

func _facility_upgrade_cost_label() -> String:
	return _cost_label(_facility_upgrade_cost())

func _facility_upgrade_unlocked() -> bool:
	return facility_upgrade_unlocked or GameState.day >= 7

func _facility_upgrade_level(room_id: String) -> int:
	if not rooms.has(room_id):
		return 0
	return max(1, int(rooms[room_id].get("facility_level", 1)))

func _facility_upgrade_level_cap() -> int:
	return max(2, int(_castle_stage_info().get("facility_level_cap", 2)))

func _can_upgrade_selected_facility() -> bool:
	return _can_upgrade_room_facility(selected_room)

func _can_upgrade_room_facility(room_id: String) -> bool:
	if not _facility_upgrade_unlocked() or not rooms.has(room_id):
		return false
	if not _can_change_room_facility(room_id):
		return false
	if str(rooms[room_id].get("type", "")) == "build_slot":
		return false
	return _facility_upgrade_level(room_id) < _facility_upgrade_level_cap()

func _upgrade_selected_facility() -> bool:
	if map_editor_active:
		_log("맵 편집을 저장하거나 취소한 뒤 시설을 강화하세요.")
		return false
	if not _facility_upgrade_unlocked():
		_log("시설 강화는 DAY 07부터 가능합니다.")
		return false
	if not rooms.has(selected_room):
		return false
	if not _can_upgrade_room_facility(selected_room):
		_log("선택한 시설은 더 강화할 수 없습니다.")
		return false
	var cost = _facility_upgrade_cost()
	if not GameState.pay(cost):
		_log("시설 강화 비용이 부족합니다. 필요: %s." % _cost_label(cost))
		return false
	var room: Dictionary = rooms[selected_room]
	var next_level = _facility_upgrade_level(selected_room) + 1
	room["facility_level"] = next_level
	room["hp"] = int(room.get("hp", 0)) + 80
	room["max_monsters"] = min(8, int(room.get("max_monsters", 1)) + 1)
	_relocate_invalid_monsters()
	_refresh_quarter_map_from_rooms()
	_log("%s을(를) Lv.%d로 강화했습니다. 체력 +80, 배치 한도 +1." % [display_name_for_instance(selected_room), next_level])
	_set_screen(Constants.SCREEN_MANAGEMENT)
	return true

func _refresh_quarter_map_from_rooms() -> void:
	if not use_quarter_module_map:
		return
	_setup_dungeon_graph()
	if quarter_renderer != null and quarter_renderer.has_method("refresh_layout"):
		quarter_renderer.refresh_layout()
	queue_redraw()

func _facility_stage_preview_hp(base_hp: int) -> int:
	return base_hp + int(_castle_stage_info().get("facility_hp_bonus", 0))

func _facility_stage_preview_capacity(base_capacity: int) -> int:
	return base_capacity + int(_castle_stage_info().get("facility_capacity_bonus", 0))

func _barracks_stage_attack_bonus_percent() -> int:
	return int(round(25.0 * _castle_facility_scale("barracks_power_scale")))

func _barracks_stage_damage_reduction_percent() -> int:
	return int(round(22.0 * _castle_facility_scale("barracks_power_scale")))

func _watch_stage_damage_bonus_percent() -> int:
	return int(round(18.0 * _castle_facility_scale("watch_power_scale")))

func _watch_stage_slow_percent() -> int:
	return int(round(minf(55.0, 28.0 * _castle_facility_scale("watch_power_scale"))))

func _ward_stage_damage_reduction_percent() -> int:
	return int(round((1.0 - _castle_facility_scale("ward_damage_taken_scale")) * 100.0))

func _facility_definition(facility_id: String) -> Dictionary:
	match facility_id:
		"barracks":
			return {
				"display_name": "병영",
				"short_label": "병영",
				"role_title": "주력 방어선",
				"role_summary": "몬스터를 가장 많이 세워 한 방에서 버티는 전투 거점입니다.",
				"effect_summary": "체력 %d / 몬스터 %d명 배치. 이 방에 배치된 아군은 인접 방 방어 중에도 공격 +%d%%, 받는 피해 -%d%%." % [_facility_stage_preview_hp(450), _facility_stage_preview_capacity(4), _barracks_stage_attack_bonus_percent(), _barracks_stage_damage_reduction_percent()],
				"recommend_summary": "입구와 왕좌 사이의 필수 길목, 또는 여러 길이 합쳐지는 방에 적합합니다.",
				"caution_summary": "식량을 쓰기 때문에 초반에 많이 늘리면 몬스터 운용 여유가 줄어듭니다.",
				"type": "support",
				"hp": 450,
				"max_monsters": 4,
				"icon": "res://assets/ui/room_v2/room_v2_barracks.png",
				"icon_offset": [0, -8],
				"icon_size": 54,
				"cost": {"gold": 100, "food": 2}
			}
		"treasure":
			return {
				"display_name": "보물 보관실",
				"short_label": "보물고",
				"role_title": "도둑 유인 목표",
				"role_summary": "도둑이 노리는 금화 보관 방입니다. 일부러 지킬 위치를 만드는 시설입니다.",
				"effect_summary": "체력 %d / 몬스터 %d명 배치. 도둑은 이 방을 목표로 이동합니다. 5초 방치되면 금화 100을 잃습니다." % [_facility_stage_preview_hp(250), _facility_stage_preview_capacity(2)],
				"recommend_summary": "왕좌 직전보다 한 칸 바깥에 두고, 병영이나 감시 초소가 바로 덮을 수 있게 두세요.",
				"caution_summary": "방어 병력이 없으면 보상이 아니라 손실 지점이 됩니다.",
				"type": "bait",
				"hp": 250,
				"max_monsters": 2,
				"bait_priority": 80,
				"icon": "res://assets/ui/room_v2/room_v2_treasure.png",
				"icon_offset": [0, -8],
				"icon_size": 58,
				"cost": {"gold": 120}
			}
		"recovery":
			return {
				"display_name": "회복 둥지",
				"short_label": "회복",
				"role_title": "후퇴 거점",
				"role_summary": "다친 몬스터를 다시 전선으로 돌려보내는 유지력 시설입니다.",
				"effect_summary": "체력 %d / 몬스터 %d명 배치. 내부 초당 %.1f, 배치 아군이 인접 방에서 싸울 때 초당 %.1f 회복합니다." % [_facility_stage_preview_hp(350), _facility_stage_preview_capacity(2), 8.0 * _castle_facility_scale("recovery_power_scale"), 3.0 * _castle_facility_scale("recovery_power_scale")],
				"recommend_summary": "주력 교전 방 뒤쪽이나 왕좌 근처에 두면 후퇴 동선이 짧아집니다.",
				"caution_summary": "직접 화력은 없으니 앞쪽 방이 버텨줘야 가치가 생깁니다.",
				"type": "recovery",
				"hp": 350,
				"max_monsters": 2,
				"icon": "res://assets/ui/room_v2/room_v2_recovery.png",
				"icon_offset": [0, -8],
				"icon_size": 58,
				"cost": {"mana": 80}
			}
		"watch_post":
			return {
				"display_name": "감시 초소",
				"short_label": "감시",
				"role_title": "전방 차단",
				"role_summary": "침입자를 초반에 붙잡아 왕좌까지 도달하는 시간을 늦추는 방입니다.",
				"effect_summary": "체력 %d / 몬스터 %d명 배치. 이 방과 영향 범위의 적 이동 -%d%%, 해당 적에게 아군 피해 +%d%%." % [_facility_stage_preview_hp(380), _facility_stage_preview_capacity(3), _watch_stage_slow_percent(), _watch_stage_damage_bonus_percent()],
				"recommend_summary": "입구 가까운 긴 경로, 보물 방으로 가는 우회로, 새로 만든 분기 앞에 적합합니다.",
				"caution_summary": "몬스터를 배치하지 않으면 감시 이름만 있는 빈 방이 됩니다.",
				"type": "support",
				"hp": 380,
				"max_monsters": 3,
				"icon": "res://assets/ui/room_v2/room_v2_watch_post.png",
				"icon_offset": [0, -8],
				"icon_size": 54,
				"cost": {"gold": 100, "mana": 50}
			}
		"ward_core":
			return {
				"display_name": "마력 수호핵",
				"short_label": "수호핵",
				"role_title": "성역 방호망",
				"role_summary": "3단계부터 성 전체에 방호막을 펼쳐 모든 방어 몬스터가 받는 피해를 줄입니다.",
				"effect_summary": "체력 %d / 몬스터 %d명 배치. 현재 성 단계에서 모든 아군이 받는 피해 -%d%%." % [_facility_stage_preview_hp(420), _facility_stage_preview_capacity(1), _ward_stage_damage_reduction_percent()],
				"recommend_summary": "후방 분기에 두고 병영과 회복 둥지를 함께 보호하면 오래 버틸 수 있습니다.",
				"caution_summary": "공격 시설이 아니며 3단계 마왕성 진화 전에는 건설할 수 없습니다.",
				"type": "support",
				"hp": 420,
				"max_monsters": 1,
				"icon": "res://assets/ui/room_v2/room_v2_build_slot.png",
				"icon_offset": [0, -4],
				"icon_size": 50,
				"cost": {"gold": 180, "mana": 140}
			}
		"build_slot":
			return {
				"display_name": "건설 슬롯",
				"short_label": "빈 슬롯",
				"role_title": "철거 / 예비지",
				"role_summary": "현재 시설을 비우고 다음 배치를 위한 공간으로 남깁니다.",
				"effect_summary": "비용 없이 시설을 제거합니다. 완성 방이 아니므로 몬스터 배치는 막힙니다.",
				"recommend_summary": "보물고나 회복 둥지처럼 하나만 유지되는 시설을 옮길 때 임시 공간으로 쓰세요.",
				"caution_summary": "전투 직전에 비워두면 방어력이 줄어듭니다.",
				"type": "build_slot",
				"hp": 200,
				"max_monsters": 1,
				"icon": "res://assets/ui/room_v2/room_v2_build_slot.png",
				"icon_offset": [0, -4],
				"icon_size": 50,
				"cost": {}
			}
	return {}

func _apply_facility_to_room(room_id: String, facility_id: String) -> void:
	var definition = _facility_definition(facility_id)
	if definition.is_empty() or not rooms.has(room_id):
		return
	var room: Dictionary = rooms[room_id]
	room["facility_role"] = facility_id
	room["display_name"] = definition.get("display_name", room.get("display_name", room_id))
	room["type"] = definition.get("type", room.get("type", "support"))
	room["hp"] = int(definition.get("hp", room.get("hp", 200)))
	room["max_monsters"] = int(definition.get("max_monsters", room.get("max_monsters", 1)))
	room["icon"] = definition.get("icon", room.get("icon", ""))
	room["icon_offset"] = definition.get("icon_offset", room.get("icon_offset", [0, -8]))
	room["icon_size"] = int(definition.get("icon_size", room.get("icon_size", 54)))
	room["facility_level"] = 1
	room["castle_stage_hp_bonus"] = 0
	room["castle_stage_capacity_bonus"] = 0
	room.erase("bait_priority")
	room.erase("build_slot_id")
	if definition.has("bait_priority"):
		room["bait_priority"] = definition["bait_priority"]
	if facility_id == "build_slot":
		room["build_slot_id"] = room_id
	_apply_castle_stage_room_upgrades()

func _relocate_invalid_monsters() -> void:
	var room_counts: Dictionary = {}
	for monster_id in monster_roster.keys():
		if not _monster_available_for_defense(str(monster_id)):
			continue
		var room_id = str(monster_roster[monster_id].get("room", ""))
		if not _room_accepts_monsters(room_id):
			var fallback = _first_available_monster_room(monster_id, room_counts)
			monster_roster[monster_id]["room"] = fallback
			room_counts[fallback] = int(room_counts.get(fallback, 0)) + 1
			continue
		var count = int(room_counts.get(room_id, 0))
		if count >= int(rooms[room_id].get("max_monsters", 1)):
			var overflow_target = _first_available_monster_room(monster_id, room_counts)
			monster_roster[monster_id]["room"] = overflow_target
			room_counts[overflow_target] = int(room_counts.get(overflow_target, 0)) + 1
		else:
			room_counts[room_id] = count + 1

func _room_accepts_monsters(room_id: String) -> bool:
	if not rooms.has(room_id):
		return false
	var room_type = str(rooms[room_id].get("type", ""))
	return room_type != "build_slot" and room_type != "legacy" and int(rooms[room_id].get("max_monsters", 0)) > 0

func _first_available_monster_room(monster_id: String, room_counts: Dictionary = {}) -> String:
	var preferred = [str(monster_roster.get(monster_id, {}).get("room", "")), "entrance", "barracks", "recovery", "treasure", "throne", "slot_01"]
	for room_id in preferred:
		if not _room_accepts_monsters(room_id):
			continue
		var used = int(room_counts.get(room_id, _placement_count(room_id, monster_id)))
		if used < int(rooms[room_id].get("max_monsters", 1)):
			return room_id
	return "entrance"

func _cost_label(cost: Dictionary) -> String:
	var parts: Array[String] = []
	if int(cost.get("gold", 0)) > 0:
		parts.append("금화 %d" % int(cost.get("gold", 0)))
	if int(cost.get("mana", 0)) > 0:
		parts.append("마력 %d" % int(cost.get("mana", 0)))
	if int(cost.get("food", 0)) > 0:
		parts.append("식량 %d" % int(cost.get("food", 0)))
	if int(cost.get("infamy", 0)) > 0:
		parts.append("악명 %d" % int(cost.get("infamy", 0)))
	if parts.is_empty():
		return "무료"
	return " / ".join(parts)

func _select_room(room_id: String) -> void:
	if current_screen == Constants.SCREEN_MANAGEMENT:
		if build_pick_mode:
			_select_build_target_room(room_id)
			return
		if deploy_pick_monster_id != "":
			if _assign_monster_to_room(deploy_pick_monster_id, room_id):
				deploy_pick_monster_id = ""
			_set_screen(Constants.SCREEN_MANAGEMENT)
			return
	if selected_room != room_id:
		facility_change_panel_open = false
	selected_room = room_id
	if map_editor_active:
		map_editor_path_candidate_index = 0
	SignalBus.room_selected.emit(room_id)
	_tutorial_emit_action("room_selected", {"room_id": room_id})
	if current_screen == Constants.SCREEN_COMBAT:
		_set_screen(Constants.SCREEN_COMBAT)
	else:
		_set_screen(current_screen)
	queue_redraw()

func display_name_for_instance(instance_id: String) -> String:
	if rooms.has(instance_id):
		return str(rooms[instance_id].get("display_name", instance_id))
	if instance_id.begins_with(USER_AUTHORED_PATH_PREFIX):
		return "수동 통로"
	if instance_id.begins_with(SYSTEM_REQUIRED_PATH_PREFIX):
		return "필수 통로"
	var placed = _map_editor_placed_entry(instance_id)
	if placed.is_empty() and graph != null and graph.has_method("placed_module_data"):
		placed = graph.placed_module_data(instance_id)
	var module_id = str(placed.get("module_id", ""))
	var module: Dictionary = DataRegistry.quarter_module(module_id)
	var module_type = str(module.get("module_type", ""))
	if module_type == "corridor" or module_id.begins_with("corridor_gap_"):
		return "통로"
	var display_name = str(module.get("display_name", ""))
	if display_name != "":
		return display_name
	return "배치물"

func _main_route_instance_ids() -> Array:
	if graph == null or not graph.has_method("path_between"):
		return []
	return graph.path_between(REQUIRED_MAIN_ROUTE_FROM, REQUIRED_MAIN_ROUTE_TO)

func _main_route_status_line() -> String:
	var route = _main_route_instance_ids()
	if route.is_empty():
		return "입구-왕좌 경로: 끊김"
	return "입구-왕좌 경로: 연결됨 %d단계" % max(0, route.size() - 1)

func _select_unit(unit: Node) -> void:
	if selected_unit != null and is_instance_valid(selected_unit):
		selected_unit.set_selected(false)
	selected_unit = unit
	selected_unit.set_selected(true)
	SignalBus.unit_selected.emit(unit)
	_tutorial_emit_action("unit_selected", {"unit_id": unit.unit_id, "room_id": unit.current_room, "faction": unit.faction})
	if current_screen == Constants.SCREEN_COMBAT:
		_set_screen(Constants.SCREEN_COMBAT)

func _select_next_monster_unit() -> void:
	if monster_units.is_empty():
		return
	var alive: Array = []
	for unit in monster_units:
		if unit.is_alive():
			alive.append(unit)
	if alive.is_empty():
		return
	var index = alive.find(selected_unit)
	index = (index + 1) % alive.size()
	_select_unit(alive[index])

func _set_global_directive(directive: String) -> void:
	if not _tutorial_allows("global_directive_set", {"directive": directive}):
		return
	var screen_before = current_screen
	combat_scene.set_global_directive(directive)
	if onboarding_enabled:
		match directive:
			Constants.DIRECTIVE_DEFENSE:
				_onboarding_emit_trigger("global_directive_defend")
			Constants.DIRECTIVE_SURVIVAL:
				_onboarding_emit_trigger("survival_priority")
	if screen_before == Constants.SCREEN_MANAGEMENT:
		_set_screen(Constants.SCREEN_MANAGEMENT)
	_tutorial_emit_action("global_directive_set", {"directive": directive})

func _set_room_directive(directive: String) -> void:
	if not _tutorial_allows("room_directive_set", {"directive": directive, "room_id": selected_room}):
		return
	var screen_before = current_screen
	combat_scene.set_room_directive(directive)
	if onboarding_enabled:
		match directive:
			Constants.ROOM_DIRECTIVE_ENTRY_BLOCK:
				_onboarding_emit_trigger("room_directive_block")
			Constants.ROOM_DIRECTIVE_TRAP_LURE:
				_onboarding_emit_trigger("trap_lure")
			Constants.ROOM_DIRECTIVE_RETREAT:
				_onboarding_emit_trigger("retreat_line")
	if screen_before == Constants.SCREEN_MANAGEMENT:
		_set_screen(Constants.SCREEN_MANAGEMENT)
	_tutorial_emit_action("room_directive_set", {"directive": directive, "room_id": selected_room})

func _enable_direct_control() -> void:
	if not _tutorial_allows("direct_control_once", {"unit_id": selected_unit.unit_id if selected_unit != null else ""}):
		return
	if not combat_scene.enable_direct_control():
		return
	_tutorial_emit_action("direct_control_once", {"unit_id": selected_unit.unit_id if selected_unit != null else ""})
	if onboarding_enabled:
		_onboarding_emit_trigger("direct_control_start")

func _release_direct_control() -> void:
	combat_scene.release_direct_control()

func _preview_selected_skill(slot: int) -> void:
	combat_scene.preview_selected_skill(slot)

func _clear_selected_skill_preview() -> void:
	combat_scene.clear_skill_preview()

func _use_selected_skill(slot: int) -> bool:
	var used_skill_id = ""
	if selected_unit != null and selected_unit.faction == Constants.FACTION_MONSTER:
		var skills: Array = DataRegistry.monster(selected_unit.unit_id).get("skill_slots", [])
		if slot >= 0 and slot < skills.size() and skills[slot] != null:
			used_skill_id = str(skills[slot])
	var direct_attack_step = onboarding_enabled and tutorial_manager.expected_action() == "direct_attack_once" and selected_unit != null and selected_unit.direct_control
	var tutorial_action_id = "direct_attack_once" if direct_attack_step else ("imp_casts_fireball" if used_skill_id == "fireball" else "skill_used")
	if not _tutorial_allows(tutorial_action_id, {"skill_id": used_skill_id, "unit_id": selected_unit.unit_id if selected_unit != null else ""}):
		return false
	if not combat_scene.use_selected_skill(slot):
		return false
	if direct_attack_step:
		_tutorial_emit_action("direct_attack_once", {"skill_id": used_skill_id, "unit_id": selected_unit.unit_id if selected_unit != null else ""})
	if onboarding_enabled and used_skill_id == "fireball":
		_tutorial_emit_action("imp_casts_fireball", {"skill_id": used_skill_id, "unit_id": selected_unit.unit_id if selected_unit != null else ""})
		_onboarding_emit_trigger("imp_fireball")
	return true

func _onboarding_enemy_spawned(enemy_id: String) -> void:
	if not onboarding_enabled:
		return
	if enemy_id == "trainee_hero":
		_onboarding_emit_trigger("boss_spawn")
	elif GameState.day == 1 and enemy_id == "explorer":
		_onboarding_emit_trigger("enemy_spawn")
	elif GameState.day == 2 and enemy_id == "thief":
		_log("경고: 도둑이 보물 방으로 향합니다. 보물 방 지침과 함정 유도로 시간을 버세요.")
		_onboarding_emit_trigger("enemy_spawn")

func _onboarding_trap_triggered() -> void:
	_onboarding_emit_trigger("trap_triggered")

func _onboarding_treasure_stolen() -> void:
	onboarding_treasure_stolen_this_day = true
	_onboarding_emit_trigger("treasure_stolen")

func _onboarding_unit_retreat(unit: Node) -> void:
	if not onboarding_enabled or unit == null:
		return
	if unit.unit_id == "slime":
		_onboarding_emit_trigger("slime_low_hp_retreat")
	_onboarding_emit_trigger("unit_retreat")

func _onboarding_unit_damaged(unit: Node) -> void:
	if not onboarding_enabled or unit == null or not is_instance_valid(unit):
		return
	if unit.max_hp <= 0:
		return
	var hp_ratio = float(unit.hp) / float(unit.max_hp)
	if unit.faction == Constants.FACTION_ENEMY and unit.unit_id == "trainee_hero":
		_onboarding_emit_boss_hp_threshold(hp_ratio)
	elif unit.faction == Constants.FACTION_ENEMY and hp_ratio <= 0.35:
		_onboarding_emit_trigger("low_hp")

func _onboarding_emit_boss_hp_threshold(hp_ratio: float) -> void:
	var thresholds = [
		{"key": "75", "ratio": 0.75, "trigger": "boss_hp_75"},
		{"key": "50", "ratio": 0.50, "trigger": "boss_hp_50"},
		{"key": "25", "ratio": 0.25, "trigger": "boss_hp_25"}
	]
	for threshold in thresholds:
		var key = str(threshold["key"])
		if onboarding_boss_hp_thresholds.has(key):
			continue
		if hp_ratio <= float(threshold["ratio"]):
			onboarding_boss_hp_thresholds[key] = true
			if key == "50":
				_log("보스 체력 50%: 임프 화염구와 후퇴선을 활용해 남은 전투를 버티세요.")
				_tutorial_emit_action("boss_hp_50", {"hp_ratio": hp_ratio})
			_onboarding_emit_trigger(str(threshold["trigger"]))

func _onboarding_battle_finished(win: bool) -> void:
	if not onboarding_enabled or GameState.onboarding_complete or GameState.day > GameState.TUTORIAL_FINAL_DAY:
		return
	_tutorial_emit_action("battle_finished", {"win": win, "day": GameState.day})
	if win:
		_onboarding_set_stage(_onboarding_result_stage_for_day(GameState.day))
		var triggers: Array = []
		if GameState.day == 2 and not onboarding_treasure_stolen_this_day:
			triggers.append("win_no_treasure_loss")
		triggers.append("win")
		_onboarding_open_stage_dialogue(triggers, Constants.SCREEN_RESULT)
	else:
		_onboarding_set_stage(_onboarding_battle_stage_for_day(GameState.day))
		_onboarding_open_stage_dialogue(["lose"], Constants.SCREEN_RESULT)

func _set_speed(speed: float) -> void:
	combat_scene.set_speed(speed)

func _toggle_pause() -> void:
	combat_scene.toggle_pause()

func _unit_at(point: Vector2) -> Node:
	var best: Node = null
	var best_distance = 36.0
	for unit in monster_units + enemy_units:
		if not unit.is_alive():
			continue
		var distance = unit.global_position.distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best = unit
	return best

func _enemy_at(point: Vector2) -> Node:
	var best: Node = null
	var best_distance = 36.0
	for unit in enemy_units:
		if not unit.is_alive():
			continue
		var distance = unit.global_position.distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best = unit
	return best

func _combat_ui_at(point: Vector2) -> bool:
	if current_screen != Constants.SCREEN_COMBAT:
		return false
	var rects = [
		Rect2(16, 10, 1870, 70),
		Rect2(390, 92, 430, 116),
		Rect2(20, 105, 300, 385),
		Rect2(20, 500, 360, 200),
		Rect2(20, 710, 360, 288),
		Rect2(1518, 142, 370, 710),
		Rect2(560, 884, 860, 142),
		Rect2(1438, 884, 74, 142)
	]
	for rect in rects:
		if rect.has_point(point):
			return true
	return false

func _management_ui_at(point: Vector2) -> bool:
	if current_screen != Constants.SCREEN_MANAGEMENT:
		return false
	var rects = [
		Rect2(16, 10, 1870, 70),
		Rect2(16, 92, 300, 780 if build_pick_mode else 420),
		Rect2(16, 530, 300, 342),
		Rect2(98, 880, 1725, 142),
		Rect2(1518, 92, 370, 760)
	]
	if facility_change_panel_open:
		rects.append(Rect2(650, 218, 620, 548))
	for rect in rects:
		if rect.has_point(point):
			return true
	return false

func _room_at(point: Vector2) -> String:
	if graph != null and graph.has_method("room_at_world"):
		var room_id = str(graph.room_at_world(point))
		if room_id != "":
			return room_id
	var best_room = ""
	var best_area = INF
	for room_id in rooms.keys():
		var rect = graph.rect(room_id)
		if not rect.has_point(point):
			continue
		var area = rect.size.x * rect.size.y
		if area < best_area:
			best_area = area
			best_room = room_id
	return best_room

func _start_management_monster_drag(point: Vector2) -> bool:
	var monster_id = _management_monster_at(point)
	if monster_id == "":
		return false
	_clear_management_action_mode(false)
	facility_change_panel_open = false
	dragging_monster_id = monster_id
	drag_monster_position = point
	drag_start_position = point
	drag_hover_room = _room_at(point)
	selected_monster_id = monster_id
	var current_room = str(monster_roster[monster_id].get("room", ""))
	if rooms.has(current_room):
		selected_room = current_room
	_tutorial_emit_action("unit_selected", {"monster_id": monster_id, "unit_id": monster_id, "room_id": current_room})
	queue_redraw()
	return true

func _update_management_monster_drag(point: Vector2) -> void:
	drag_monster_position = point
	drag_hover_room = _room_at(point)
	queue_redraw()

func _finish_management_monster_drag(point: Vector2) -> void:
	var monster_id = dragging_monster_id
	var room_id = _room_at(point)
	dragging_monster_id = ""
	drag_hover_room = ""
	drag_monster_position = Vector2.ZERO
	var current_room = str(monster_roster.get(monster_id, {}).get("room", ""))
	if point.distance_to(drag_start_position) < 8.0:
		if rooms.has(current_room):
			selected_room = current_room
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	drag_start_position = Vector2.ZERO
	if room_id != "":
		_assign_monster_to_room(monster_id, room_id)
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _management_monster_at(point: Vector2) -> String:
	var best_monster = ""
	var best_distance = 48.0
	for monster_id in monster_roster.keys():
		if not _monster_available_for_defense(str(monster_id)):
			continue
		var preview_pos = _management_monster_preview_position(monster_id)
		if preview_pos == Vector2.INF:
			continue
		var distance = preview_pos.distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best_monster = monster_id
	return best_monster

func _management_monster_preview_position(monster_id: String) -> Vector2:
	if not _monster_available_for_defense(monster_id):
		return Vector2.INF
	var room_counts: Dictionary = {}
	for current_monster_id in monster_roster.keys():
		if not _monster_available_for_defense(str(current_monster_id)):
			continue
		var roster: Dictionary = monster_roster[current_monster_id]
		var room_id: String = roster.get("room", "")
		if not rooms.has(room_id):
			continue
		var count = int(room_counts.get(room_id, 0))
		if current_monster_id == monster_id:
			return _room_actor_point(room_id, count)
		room_counts[room_id] = count + 1
	return Vector2.INF

func _management_preview_offset(index: int) -> Vector2:
	var offsets = [
		Vector2(-30, 10),
		Vector2(0, -2),
		Vector2(30, 10),
		Vector2(-16, -24),
		Vector2(20, -24)
	]
	return offsets[index % offsets.size()]

func _room_actor_point(room_id: String, index: int, combat: bool = false) -> Vector2:
	if graph == null or not rooms.has(room_id):
		return Vector2.ZERO
	var center = graph.center(room_id)
	var rect = graph.rect(room_id)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return center + (_spawn_offset(index) if combat else _management_preview_offset(index))
	var normalized = _room_actor_offset(room_id, index)
	var spread = 0.92 if combat else 0.78
	return center + Vector2(rect.size.x * normalized.x * spread, rect.size.y * normalized.y * spread)

func _room_actor_offset(room_id: String, index: int) -> Vector2:
	var offsets = {
		"entrance": [Vector2(-0.30, 0.22), Vector2(-0.14, 0.30), Vector2(0.08, 0.18), Vector2(-0.24, -0.02), Vector2(0.18, 0.02)],
		"spike_corridor": [Vector2(-0.26, 0.16), Vector2(0.00, 0.24), Vector2(0.24, 0.12), Vector2(-0.12, -0.06), Vector2(0.14, -0.06)],
		"barracks": [Vector2(0.26, 0.18), Vector2(0.08, 0.28), Vector2(-0.14, 0.14), Vector2(0.18, -0.04)],
		"recovery": [Vector2(0.20, -0.02), Vector2(0.30, 0.14), Vector2(0.04, 0.18), Vector2(-0.12, 0.04)],
		"treasure": [Vector2(-0.14, 0.20), Vector2(0.08, 0.16), Vector2(-0.28, 0.04)],
		"throne": [Vector2(-0.10, 0.18), Vector2(0.12, 0.16), Vector2(0.00, -0.04)],
		"slot_01": [Vector2(-0.12, 0.18), Vector2(0.14, 0.16), Vector2(0.00, -0.06)],
		"watch_post": [Vector2(0.18, 0.14), Vector2(-0.08, 0.18), Vector2(0.26, -0.02)]
	}
	var room_offsets: Array = offsets.get(room_id, [])
	if room_offsets.is_empty():
		room_offsets = [Vector2(-0.22, 0.18), Vector2(0.00, 0.26), Vector2(0.22, 0.18), Vector2(-0.10, -0.06), Vector2(0.12, -0.06)]
	return room_offsets[index % room_offsets.size()]

func _draw_management_drag_feedback() -> void:
	if current_screen != Constants.SCREEN_MANAGEMENT:
		return
	_draw_map_editor_path_drag_feedback()
	_draw_management_action_mode_feedback()
	if dragging_monster_id == "":
		return
	if drag_hover_room != "":
		var can_drop = _can_drop_monster_in_room(dragging_monster_id, drag_hover_room)
		var color = Color("#ffd36a") if can_drop else Color("#ff5d6c")
		_draw_management_target_overlay(drag_hover_room, color, can_drop)
	var texture = _monster_drag_texture(dragging_monster_id)
	draw_circle(drag_monster_position + Vector2(0, 18), 30.0, Color("#050506aa"))
	if texture != null:
		draw_texture_rect(texture, Rect2(drag_monster_position - Vector2(42, 58), Vector2(84, 84)), false, Color(1, 1, 1, 0.86))
	draw_arc(drag_monster_position + Vector2(0, 2), 44.0, 0.0, TAU, 40, Color("#ffd36acc"), 3.0)
	var monster = DataRegistry.monster(dragging_monster_id)
	draw_string(UI_FONT, drag_monster_position + Vector2(-52, 62), monster.get("display_name", dragging_monster_id), HORIZONTAL_ALIGNMENT_CENTER, 104.0, 16, Color("#fff3cd"))

func _draw_map_editor_path_drag_feedback() -> void:
	if graph == null or not map_editor_path_drag_active or map_editor_path_drag_source == "":
		return
	var source_id = map_editor_path_drag_source
	var target_id = map_editor_path_drag_target
	var source_center = graph.center(source_id)
	var line_end = map_editor_path_drag_position
	var color = _map_editor_drag_state_color(source_id, target_id)
	var line_color = Color(color.r, color.g, color.b, 0.90)
	draw_line(source_center, line_end, Color("#080508cc"), 11.0, true)
	draw_line(source_center, line_end, line_color, 5.0, true)
	draw_circle(source_center, 10.0, Color("#080508dd"))
	draw_circle(source_center, 7.0, Color("#ffd36af2"))
	draw_circle(line_end, 13.0, Color("#080508cc"))
	draw_circle(line_end, 9.0, line_color)

	_draw_management_target_overlay(source_id, Color("#ffd36a"), true)

	if target_id != "" and target_id != source_id:
		var state = _map_editor_drag_state(source_id, target_id)
		_draw_management_target_overlay(target_id, color, state != "blocked")

	var label_text = _map_editor_drag_state_label(source_id, target_id)
	var label_rect = Rect2(line_end + Vector2(18.0, -38.0), Vector2(126.0, 28.0))
	draw_rect(label_rect, Color("#09070de8"), true)
	draw_rect(label_rect, line_color, false, 1.6)
	draw_string(UI_FONT, label_rect.position + Vector2(0, 20), label_text, HORIZONTAL_ALIGNMENT_CENTER, label_rect.size.x, 14, Color("#fff6d6"))

func _draw_management_action_mode_feedback() -> void:
	if graph == null or not _management_action_mode_active() or dragging_monster_id != "":
		return
	for room_id_value in rooms.keys():
		var room_id = str(room_id_value)
		if str(rooms[room_id].get("type", "")) == "legacy":
			continue
		var rect = graph.rect(room_id)
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		if build_pick_mode:
			var can_build = _can_change_room_facility(room_id)
			var build_color = Color("#8f72a8") if can_build else Color("#a95f68")
			_draw_management_target_overlay(room_id, build_color, can_build)
			if can_build:
				var build_label = _facility_short_label(build_pick_facility_id) if build_pick_facility_id != "" else "건설"
				_draw_management_target_label(rect, build_label, build_color)
		elif deploy_pick_monster_id != "":
			var can_drop = _can_drop_monster_in_room(deploy_pick_monster_id, room_id)
			var deploy_color = Color("#ffd36a") if can_drop else Color("#ff5d6c")
			_draw_management_target_overlay(room_id, deploy_color, can_drop)
			var label_text = _placement_capacity_label(room_id, deploy_pick_monster_id)
			_draw_management_target_label(rect, label_text, deploy_color)
	if build_pick_mode:
		_draw_build_preview_feedback()

func _draw_build_preview_feedback() -> void:
	if graph == null or build_preview_room_id == "" or not rooms.has(build_preview_room_id):
		return
	_draw_build_preview_main_route()
	var target_color = Color("#ffd36a")
	_draw_management_target_overlay(build_preview_room_id, target_color, true)
	var rect = graph.rect(build_preview_room_id)
	_draw_management_target_label(rect, "확정 대기", target_color)
	var route_line = _build_preview_route_line()
	var label_width = clampf(UI_FONT.get_string_size(route_line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 26.0, 180.0, 330.0)
	var label_rect = Rect2(Vector2(rect.get_center().x - label_width * 0.5, rect.position.y - 36.0), Vector2(label_width, 24.0))
	draw_rect(label_rect, Color("#09070df0"), true)
	draw_rect(label_rect, Color("#ffd36ab8"), false, 1.2)
	draw_string(UI_FONT, label_rect.position + Vector2(0, 17), route_line, HORIZONTAL_ALIGNMENT_CENTER, label_rect.size.x, 12, Color("#fff6d6"))

func _draw_build_preview_main_route() -> void:
	var route = _main_route_instance_ids()
	if route.size() < 2 or graph == null or not graph.has_method("center"):
		return
	for index in range(route.size() - 1):
		var from_point = graph.center(str(route[index]))
		var to_point = graph.center(str(route[index + 1]))
		draw_line(from_point, to_point, Color("#09070dd8"), 9.0, true)
		draw_line(from_point, to_point, Color("#67b7ff78"), 3.0, true)
		draw_circle(to_point, 4.5, Color("#d6fbffbb"))
	draw_circle(graph.center(str(route[0])), 4.5, Color("#d6fbffbb"))
	if route.has(build_preview_room_id):
		return
	if graph.has_method("exits"):
		for neighbor_id in graph.exits(build_preview_room_id):
			if route.has(neighbor_id):
				var target_point = graph.center(build_preview_room_id)
				var route_point = graph.center(str(neighbor_id))
				draw_line(target_point, route_point, Color("#09070dd8"), 8.0, true)
				draw_line(target_point, route_point, Color("#ffd36ab0"), 3.0, true)
				return

func _draw_management_target_overlay(room_id: String, color: Color, enabled: bool) -> void:
	var alpha = 0.055 if enabled else 0.022
	var line_alpha = 0.56 if enabled else 0.24
	var cells = _management_room_tile_cells(room_id)
	if cells.is_empty():
		var fallback_rect = graph.rect(room_id).grow(-8.0)
		if fallback_rect.size.x <= 0.0 or fallback_rect.size.y <= 0.0:
			return
		var fallback_diamond = _management_diamond(fallback_rect)
		var fallback_fill = Color(color.r, color.g, color.b, alpha)
		draw_polygon(fallback_diamond, PackedColorArray([fallback_fill, fallback_fill, fallback_fill, fallback_fill]))
		draw_polyline(PackedVector2Array([fallback_diamond[0], fallback_diamond[1], fallback_diamond[2], fallback_diamond[3], fallback_diamond[0]]), Color(color.r, color.g, color.b, line_alpha), 1.6 if enabled else 1.0, true)
		return
	var cell_lookup: Dictionary = {}
	for cell in cells:
		cell_lookup[cell] = true
	for cell in cells:
		var cell_rect = graph.tile_cell_rect(cell).grow(-2.0)
		var diamond = _management_diamond(cell_rect)
		var fill = Color(color.r, color.g, color.b, alpha)
		draw_polygon(diamond, PackedColorArray([fill, fill, fill, fill]))
	var edge_color = Color(color.r, color.g, color.b, line_alpha)
	var edge_width = 1.6 if enabled else 1.0
	for cell in cells:
		var cell_rect = graph.tile_cell_rect(cell).grow(-2.0)
		var diamond = _management_diamond(cell_rect)
		_draw_management_outer_edge(cell, cell_lookup, Vector2i(0, -1), diamond[0], diamond[1], edge_color, edge_width)
		_draw_management_outer_edge(cell, cell_lookup, Vector2i(1, 0), diamond[1], diamond[2], edge_color, edge_width)
		_draw_management_outer_edge(cell, cell_lookup, Vector2i(0, 1), diamond[2], diamond[3], edge_color, edge_width)
		_draw_management_outer_edge(cell, cell_lookup, Vector2i(-1, 0), diamond[3], diamond[0], edge_color, edge_width)

func _draw_management_outer_edge(cell: Vector2i, cell_lookup: Dictionary, neighbor_offset: Vector2i, from_point: Vector2, to_point: Vector2, color: Color, width: float) -> void:
	if cell_lookup.has(cell + neighbor_offset):
		return
	draw_line(from_point, to_point, color, width, true)

func _management_room_tile_cells(room_id: String) -> Array:
	var result: Array = []
	if graph == null or not graph.has_method("debug_floor_cells") or not graph.has_method("debug_room_id_for_tile_cell"):
		return result
	for cell in graph.debug_floor_cells().keys():
		if str(graph.debug_room_id_for_tile_cell(cell)) == room_id:
			result.append(cell)
	return result

func _management_diamond(rect: Rect2) -> PackedVector2Array:
	var center = rect.get_center()
	return PackedVector2Array([
		Vector2(center.x, rect.position.y),
		Vector2(rect.end.x, center.y),
		Vector2(center.x, rect.end.y),
		Vector2(rect.position.x, center.y)
	])

func _draw_management_target_label(rect: Rect2, text: String, color: Color) -> void:
	if text == "":
		return
	var label_width = clampf(UI_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 24.0, 76.0, 148.0)
	var label_rect = Rect2(Vector2(rect.get_center().x - label_width * 0.5, rect.end.y + 4.0), Vector2(label_width, 22.0))
	draw_rect(label_rect, Color("#09070ddd"), true)
	draw_rect(label_rect, Color(color.r, color.g, color.b, 0.76), false, 1.2)
	draw_string(UI_FONT, label_rect.position + Vector2(0, 16), text, HORIZONTAL_ALIGNMENT_CENTER, label_rect.size.x, 12, Color("#fff6d6"))

func _draw_combat_facility_feedback() -> void:
	if current_screen != Constants.SCREEN_COMBAT or graph == null:
		return
	var entries = [
		{"facility": "barracks", "text": _facility_combat_overlay_text("barracks"), "color": Color("#ffd36a")},
		{"facility": "watch_post", "text": _facility_combat_overlay_text("watch_post"), "color": Color("#67b7ff")},
		{"facility": "recovery", "text": _facility_combat_overlay_text("recovery"), "color": Color("#8dffb1")}
	]
	var watch_rooms: Array[String] = _active_watch_post_pressure_rooms()
	for pressure_room in watch_rooms:
		if not rooms.has(pressure_room):
			continue
		var pressure_rect = graph.rect(pressure_room)
		if pressure_rect.size.x > 0.0 and pressure_rect.size.y > 0.0:
			draw_rect(pressure_rect.grow(8.0), Color("#67b7ff18"), true)
			draw_rect(pressure_rect.grow(8.0), Color("#67b7ff72"), false, 2.0)
	for entry in entries:
		for room_id in _rooms_by_facility(str(entry["facility"])):
			if not rooms.has(room_id):
				continue
			var rect = graph.rect(room_id)
			if rect.size.x <= 0.0 or rect.size.y <= 0.0:
				continue
			var disabled_seconds := _facility_room_disabled_remaining(room_id)
			var targeted := _engineer_room_is_targeted(room_id)
			var color: Color = Color("#ff6f61") if disabled_seconds > 0.0 else entry["color"]
			var text := str(entry["text"])
			if disabled_seconds > 0.0:
				text = "무력화 %.1f초" % disabled_seconds
			elif targeted:
				color = Color("#ffb347")
				text = "공병 목표 · %s" % text
			if disabled_seconds > 0.0 or targeted:
				draw_rect(rect.grow(10.0), Color(color.r, color.g, color.b, 0.12), true)
				draw_rect(rect.grow(10.0), Color(color.r, color.g, color.b, 0.88), false, 3.0)
			var label_width := 150.0 if disabled_seconds > 0.0 or targeted else 116.0
			var label_rect = Rect2(Vector2(rect.get_center().x - label_width * 0.5, rect.position.y - 30.0), Vector2(label_width, 24.0))
			draw_rect(label_rect, Color("#08070de8"), true)
			draw_rect(label_rect, Color(color.r, color.g, color.b, 0.86), false, 1.4)
			draw_string(UI_FONT, label_rect.position + Vector2(0, 17), text, HORIZONTAL_ALIGNMENT_CENTER, label_rect.size.x, 12, Color("#fff6d6"))

func _facility_combat_overlay_text(facility_id: String) -> String:
	match facility_id:
		"barracks":
			return "병영 +공/방"
		"watch_post":
			return "감시 둔화"
		"recovery":
			return "회복 +%.1f/s" % (8.0 * _castle_facility_scale("recovery_power_scale"))
	return facility_id

func _placement_capacity_label(room_id: String, ignore_monster_id: String = "") -> String:
	if not rooms.has(room_id):
		return ""
	if rooms[room_id].get("type", "") == "build_slot":
		return "건설 필요"
	var max_count = int(rooms[room_id].get("max_monsters", 1))
	var placed_count = _placement_count(room_id, ignore_monster_id)
	if placed_count >= max_count:
		return "%d/%d 가득" % [placed_count, max_count]
	return "%d/%d 여유 %d" % [placed_count, max_count, max_count - placed_count]

func _can_drop_monster_in_room(monster_id: String, room_id: String) -> bool:
	if not _room_accepts_monsters(room_id):
		return false
	return _placement_count(room_id, monster_id) < int(rooms[room_id].get("max_monsters", 1))

func _reset_facility_effect_stats() -> void:
	facility_effect_stats = {
		"barracks_bonus_damage": 0,
		"barracks_damage_reduced": 0,
		"barracks_attack_applications": 0,
		"barracks_assigned_incoming_attacks": 0,
		"barracks_no_reduction_hits": 0,
		"barracks_damage_reduction_applications": 0,
		"barracks_assigned_unit_seconds": 0.0,
		"barracks_covered_unit_seconds": 0.0,
		"barracks_contested_unit_seconds": 0.0,
		"barracks_in_range_unit_seconds": 0.0,
		"watch_post_bonus_damage": 0,
		"watch_post_slow_applications": 0,
		"recovery_healing": 0,
		"ward_damage_reduced": 0
	}

func _reset_engineer_combat_state() -> void:
	facility_disabled_timers.clear()
	facility_feedback_redraw_accumulator = 0.0
	engineer_target_rooms.clear()
	engineer_completed_units.clear()
	engineer_targeted_facility_rooms.clear()
	engineer_disabled_facility_rooms.clear()
	engineers_spawned_this_battle = 0
	engineers_reached_facility_this_battle = 0
	facility_disables_this_battle = 0

func _facility_room_is_active(room_id: String) -> bool:
	return rooms.has(room_id) and float(facility_disabled_timers.get(room_id, 0.0)) <= 0.0

func _active_watch_post_pressure_rooms() -> Array[String]:
	var result: Array[String] = []
	if graph == null or not graph.has_method("exits"):
		return result
	for watch_room in _rooms_by_facility("watch_post"):
		if not _facility_room_is_active(watch_room):
			continue
		if not result.has(watch_room):
			result.append(watch_room)
		for room_id_value in graph.exits(watch_room):
			var room_id := str(room_id_value)
			if not result.has(room_id):
				result.append(room_id)
	if _castle_facility_scale("watch_power_scale") > 1.0:
		var first_ring := result.duplicate()
		for first_room in first_ring:
			for room_id_value in graph.exits(first_room):
				var room_id := str(room_id_value)
				if not result.has(room_id):
					result.append(room_id)
	result.sort()
	return result

func _facility_is_active(facility_id: String) -> bool:
	for room_id in _rooms_by_facility(facility_id):
		if _facility_room_is_active(room_id):
			return true
	return false

func _facility_room_disabled_remaining(room_id: String) -> float:
	return maxf(0.0, float(facility_disabled_timers.get(room_id, 0.0)))

func _facility_disabled_remaining(facility_id: String) -> float:
	var result := 0.0
	for room_id in _rooms_by_facility(facility_id):
		var remaining := _facility_room_disabled_remaining(room_id)
		if remaining <= 0.0:
			return 0.0
		if result <= 0.0 or remaining < result:
			result = remaining
	return result

func _engineer_target_facility_rooms() -> Array[String]:
	var result: Array[String] = []
	for facility_id in ["barracks", "watch_post", "recovery"]:
		for room_id in _rooms_by_facility(facility_id):
			if _facility_room_is_active(room_id):
				result.append(room_id)
	return result

func _disable_facility_room(room_id: String, seconds: float) -> bool:
	if not rooms.has(room_id) or str(rooms[room_id].get("facility_role", "")) not in ["barracks", "watch_post", "recovery"]:
		return false
	var was_active := _facility_room_is_active(room_id)
	facility_disabled_timers[room_id] = maxf(_facility_room_disabled_remaining(room_id), seconds)
	facility_feedback_redraw_accumulator = 0.0
	engineer_disabled_facility_rooms[room_id] = true
	if was_active:
		facility_disables_this_battle += 1
		_log("왕국 공병이 %s 기능을 %.0f초간 무력화했습니다." % [display_name_for_instance(room_id), seconds])
	queue_redraw()
	return was_active

func _update_facility_disables(delta: float, feedback_delta: float = -1.0) -> void:
	if facility_disabled_timers.is_empty():
		facility_feedback_redraw_accumulator = 0.0
		return
	var should_redraw := false
	for room_id_value in facility_disabled_timers.keys():
		var room_id := str(room_id_value)
		var remaining := _facility_room_disabled_remaining(room_id) - maxf(0.0, delta)
		if remaining <= 0.0:
			facility_disabled_timers.erase(room_id)
			_log("%s 기능이 복구됐습니다." % display_name_for_instance(room_id))
			should_redraw = true
		else:
			facility_disabled_timers[room_id] = remaining
	var feedback_step := delta if feedback_delta < 0.0 else feedback_delta
	facility_feedback_redraw_accumulator += maxf(0.0, feedback_step)
	if facility_feedback_redraw_accumulator >= FACILITY_FEEDBACK_REDRAW_INTERVAL_SECONDS:
		facility_feedback_redraw_accumulator = fmod(facility_feedback_redraw_accumulator, FACILITY_FEEDBACK_REDRAW_INTERVAL_SECONDS)
		should_redraw = true
	if facility_disabled_timers.is_empty():
		facility_feedback_redraw_accumulator = 0.0
	if should_redraw:
		queue_redraw()

func _engineer_room_is_targeted(room_id: String) -> bool:
	for enemy in enemy_units:
		if enemy != null and is_instance_valid(enemy) and enemy.is_alive() and enemy.unit_id == "engineer":
			if str(engineer_target_rooms.get(enemy.get_instance_id(), "")) == room_id:
				return true
	return false

func _engineer_facilities_saved_count() -> int:
	var count := 0
	for room_id in engineer_targeted_facility_rooms.keys():
		if not engineer_disabled_facility_rooms.has(room_id):
			count += 1
	return count

func _engineer_result_lines() -> Array[String]:
	if engineers_spawned_this_battle <= 0:
		return []
	return ["공병 대응: 시설 도달 %d/%d명 · 무력화 %d회 · 지켜낸 시설 %d곳" % [
		engineers_reached_facility_this_battle,
		engineers_spawned_this_battle,
		facility_disables_this_battle,
		_engineer_facilities_saved_count()
	]]

func _reset_directive_effect_stats() -> void:
	directive_effect_stats = {
		"all_out_bonus_damage": 0,
		"all_out_extra_damage_taken": 0,
		"defense_damage_reduced": 0,
		"survival_damage_reduced": 0
	}

func _record_directive_effect_stat(key: String, amount: int = 1) -> void:
	if not directive_effect_stats.has(key):
		directive_effect_stats[key] = 0
	directive_effect_stats[key] = int(directive_effect_stats.get(key, 0)) + amount

func _directive_effect_result_lines() -> Array[String]:
	var parts: Array[String] = []
	var defense_reduced = int(directive_effect_stats.get("defense_damage_reduced", 0))
	var all_out_bonus = int(directive_effect_stats.get("all_out_bonus_damage", 0))
	var all_out_extra_taken = int(directive_effect_stats.get("all_out_extra_damage_taken", 0))
	var survival_reduced = int(directive_effect_stats.get("survival_damage_reduced", 0))
	if defense_reduced > 0:
		parts.append("사수 피해 감소 %d" % defense_reduced)
	if all_out_bonus > 0 or all_out_extra_taken > 0:
		parts.append("총공격 추가 피해 +%d·추가 피격 %d" % [all_out_bonus, all_out_extra_taken])
	if survival_reduced > 0:
		parts.append("생존 피해 감소 %d" % survival_reduced)
	if parts.is_empty():
		parts.append("발동 기록 없음")
	return ["지침 효과: %s" % " / ".join(parts)]

func _record_facility_effect_stat(key: String, amount: int = 1) -> void:
	if not facility_effect_stats.has(key):
		facility_effect_stats[key] = 0
	facility_effect_stats[key] = int(facility_effect_stats.get(key, 0)) + amount

func _record_facility_effect_time(key: String, delta: float) -> void:
	if not facility_effect_stats.has(key):
		facility_effect_stats[key] = 0.0
	facility_effect_stats[key] = float(facility_effect_stats.get(key, 0.0)) + max(0.0, delta)

func _facility_status_label(facility_id: String, display_name: String) -> String:
	var facility_rooms := _rooms_by_facility(facility_id)
	if facility_rooms.size() <= 1:
		return display_name
	var active_count := 0
	for room_id in facility_rooms:
		if _facility_room_is_active(room_id):
			active_count += 1
	return "%s(작동 %d/%d)" % [display_name, active_count, facility_rooms.size()]

func _facility_effect_status_lines() -> Array[String]:
	var lines: Array[String] = []
	var barracks_room = _room_by_facility("barracks", "")
	if barracks_room != "":
		var barracks_label := _facility_status_label("barracks", "병영")
		lines.append("%s: 무력화 %.1f초" % [barracks_label, _facility_disabled_remaining("barracks")] if not _facility_is_active("barracks") else "%s: 배치 아군이 인접 방까지 공격 +%d%%, 받는 피해 -%d%%" % [barracks_label, _barracks_stage_attack_bonus_percent(), _barracks_stage_damage_reduction_percent()])
	var watch_room = _room_by_facility("watch_post", "")
	if watch_room != "":
		var watch_label := _facility_status_label("watch_post", "감시초소")
		lines.append("%s: 무력화 %.1f초" % [watch_label, _facility_disabled_remaining("watch_post")] if not _facility_is_active("watch_post") else "%s: 영향 범위 적 이동 -%d%%, 받는 피해 +%d%%" % [watch_label, _watch_stage_slow_percent(), _watch_stage_damage_bonus_percent()])
	var recovery_room = _room_by_facility("recovery", "")
	if recovery_room != "":
		var recovery_scale := _castle_facility_scale("recovery_power_scale")
		var recovery_label := _facility_status_label("recovery", "회복 둥지")
		lines.append("%s: 무력화 %.1f초" % [recovery_label, _facility_disabled_remaining("recovery")] if not _facility_is_active("recovery") else "%s: 내부 초당 %.1f·인접 방 초당 %.1f 회복" % [recovery_label, 8.0 * recovery_scale, 3.0 * recovery_scale])
	var ward_room = _room_by_facility("ward_core", "")
	if ward_room != "":
		var ward_label := _facility_status_label("ward_core", "마력 수호핵")
		lines.append("%s: 무력화 %.1f초" % [ward_label, _facility_disabled_remaining("ward_core")] if not _facility_is_active("ward_core") else "%s: 전 성역 아군 받는 피해 -%d%%" % [ward_label, _ward_stage_damage_reduction_percent()])
	return lines

func _facility_effect_result_lines() -> Array[String]:
	var parts: Array[String] = []
	var barracks_bonus = int(facility_effect_stats.get("barracks_bonus_damage", 0))
	var barracks_reduced = int(facility_effect_stats.get("barracks_damage_reduced", 0))
	var barracks_attacks = int(facility_effect_stats.get("barracks_attack_applications", 0))
	var barracks_blocks = int(facility_effect_stats.get("barracks_damage_reduction_applications", 0))
	var watch_bonus = int(facility_effect_stats.get("watch_post_bonus_damage", 0))
	var watch_slow = int(facility_effect_stats.get("watch_post_slow_applications", 0))
	var recovery_healing = int(facility_effect_stats.get("recovery_healing", 0))
	var ward_reduced = int(facility_effect_stats.get("ward_damage_reduced", 0))
	if barracks_bonus > 0:
		parts.append("병영 추가 피해 +%d" % barracks_bonus)
	if barracks_reduced > 0:
		parts.append("병영 피해 감소 %d" % barracks_reduced)
	if barracks_attacks > 0 or barracks_blocks > 0:
		parts.append("병영 발동 공격 %d회·방어 %d회" % [barracks_attacks, barracks_blocks])
	if watch_bonus > 0:
		parts.append("감시초소 추가 피해 +%d" % watch_bonus)
	if watch_slow > 0:
		parts.append("감시초소 둔화 %d회" % watch_slow)
	if recovery_healing > 0:
		parts.append("회복 둥지 회복 %d" % recovery_healing)
	if ward_reduced > 0:
		parts.append("수호핵 피해 방어 %d" % ward_reduced)
	if parts.is_empty():
		return ["시설 기여: 발동 없음 (적 동선과 몬스터 배치를 확인하세요)"]
	return ["시설 기여: %s" % " / ".join(parts)]

func _monster_drag_texture(monster_id: String) -> Texture2D:
	if monster_drag_texture_cache.has(monster_id):
		return monster_drag_texture_cache[monster_id]
	var monster = DataRegistry.monster(monster_id)
	var texture: Texture2D = null
	var path = str(monster.get("sprite", ""))
	if path != "":
		texture = _load_png(path)
	monster_drag_texture_cache[monster_id] = texture
	return texture

func _spawn_offset(index: int) -> Vector2:
	var offsets = [
		Vector2(-30, 12),
		Vector2(0, 0),
		Vector2(30, 12),
		Vector2(-18, -24),
		Vector2(22, -24)
	]
	return offsets[index % offsets.size()]

func _spawn_projectile(from_position: Vector2, to_position: Vector2) -> void:
	combat_scene.spawn_projectile(from_position, to_position)

func _spawn_slash(position: Vector2) -> void:
	combat_scene.spawn_slash(position)

func _spawn_impact(position: Vector2) -> void:
	combat_scene.spawn_impact(position)

func _log(message: String) -> void:
	var time_text = "[%05.1f] " % combat_time if current_screen == Constants.SCREEN_COMBAT else ""
	SignalBus.emit_log("%s%s" % [time_text, message])

func _on_log_added(message: String) -> void:
	logs.append(message)
	while logs.size() > 8:
		logs.pop_front()
	if current_screen == Constants.SCREEN_COMBAT:
		_tutorial_emit_action("log_event_seen", {"message": message})
		if hud != null:
			hud.update_log_panel()

func _draw_background() -> void:
	dungeon_renderer.draw_background()

func _draw_connections() -> void:
	dungeon_renderer.draw_connections()

func _draw_rooms() -> void:
	dungeon_renderer.draw_rooms()

func _draw_room_tiles(rect: Rect2, room_type: String) -> void:
	dungeon_renderer.draw_room_tiles(rect, room_type)

func _panel(rect: Rect2, color: Color, border: Color = Color("#3b3143")) -> Panel:
	return hud.panel(rect, color, border)

func _label(parent: Control, text: String, position: Vector2, size: Vector2, font_size: int = 20, color: Color = Color.WHITE, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	return hud.label(parent, text, position, size, font_size, color, align)

func _button(parent: Control, text: String, rect: Rect2, callback: Callable) -> Button:
	return hud.button(parent, text, rect, callback)

func _texture(parent: Control, path: String, rect: Rect2) -> TextureRect:
	return hud.texture(parent, path, rect)

func _style(color: Color, border: Color, width: int) -> StyleBoxFlat:
	return hud.style(color, border, width)

