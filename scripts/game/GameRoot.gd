extends Node2D

const Constants = preload("res://scripts/core/Constants.gd")
const CampaignSaveStoreScript = preload("res://scripts/core/CampaignSaveStore.gd")
const CampaignSaveMigratorV1ToV2Script = preload("res://scripts/core/CampaignSaveMigratorV1ToV2.gd")
const CampaignSaveV2StoreScript = preload("res://scripts/core/CampaignSaveV2Store.gd")
const CampaignSaveMigratorV2ToV3Script = preload("res://scripts/core/CampaignSaveMigratorV2ToV3.gd")
const CampaignSaveV3StoreScript = preload("res://scripts/core/CampaignSaveV3Store.gd")
const SaveV3ToV4MigratorScript = preload("res://scripts/systems/save/SaveV3ToV4Migrator.gd")
const CampaignSaveV4StoreScript = preload("res://scripts/systems/save/CampaignSaveV4Store.gd")
const SaveV4ToV5MigratorScript = preload("res://scripts/systems/save/SaveV4ToV5Migrator.gd")
const CampaignSaveV5StoreScript = preload("res://scripts/systems/save/CampaignSaveV5Store.gd")
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
const ContractRosterServiceScript = preload("res://scripts/systems/contracts/ContractRosterService.gd")
const Update2SeededCampaignServiceScript = preload("res://scripts/systems/campaign/Update2SeededCampaignService.gd")
const LeonAdaptationServiceScript = preload("res://scripts/systems/campaign/LeonAdaptationService.gd")
const FrontCampaignServiceScript = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const CampaignModeServiceScript = preload("res://scripts/systems/campaign/CampaignModeService.gd")
const CouncilSeasonServiceScript = preload("res://scripts/systems/campaign/CouncilSeasonService.gd")
const Update4CampaignRuntimeScript = preload("res://scripts/systems/campaign/Update4CampaignRuntimeService.gd")
const RegionRouteServiceScript = preload("res://scripts/systems/regions/RegionRouteService.gd")
const RegionContentServiceScript = preload("res://scripts/systems/regions/RegionContentService.gd")
const CouncilVoteLedgerScript = preload("res://scripts/systems/council/CouncilVoteLedger.gd")
const RivalLordServiceScript = preload("res://scripts/systems/council/RivalLordService.gd")
const CrownEvolutionServiceScript = preload("res://scripts/systems/crown/CrownEvolutionService.gd")
const CouncilEndingServiceScript = preload("res://scripts/systems/endings/CouncilEndingService.gd")
const OutpostServiceScript = preload("res://scripts/systems/outpost/OutpostService.gd")
const OutpostEncounterServiceScript = preload("res://scripts/systems/outpost/OutpostEncounterService.gd")
const MultiFloorGraphServiceScript = preload("res://scripts/systems/multifloor/MultiFloorGraphService.gd")
const UpperFloorObjectiveServiceScript = preload("res://scripts/systems/multifloor/UpperFloorObjectiveService.gd")
const HeartChamberServiceScript = preload("res://scripts/systems/hearts/HeartChamberService.gd")
const CastleHeartServiceScript = preload("res://scripts/systems/hearts/CastleHeartService.gd")
const DuoLinkServiceScript = preload("res://scripts/systems/duo_links/DuoLinkService.gd")
const ChronicleServiceScript = preload("res://scripts/systems/chronicle/ChronicleService.gd")
const CouncilChronicleScript = preload("res://scripts/systems/chronicle/CouncilChronicleService.gd")
const FrontSelectionScreenScene = preload("res://scenes/ui/screens/FrontSelectionScreen.tscn")
const CampaignModeSelectionScreenScene = preload("res://scenes/ui/screens/CampaignModeSelectionScreen.tscn")
const RegionSelectionScreenScene = preload("res://scenes/ui/screens/RegionSelectionScreen.tscn")
const OutpostManagementScreenScene = preload("res://scenes/ui/screens/OutpostManagementScreen.tscn")
const OutpostBattleRootScene = preload("res://scenes/outpost/OutpostBattleRoot.tscn")
const UpperFloorScreenScene = preload("res://scenes/ui/screens/UpperFloorScreen.tscn")
const HeartSelectionScreenScene = preload("res://scenes/ui/screens/HeartSelectionScreen.tscn")
const DuoLinkLoadoutScreenScene = preload("res://scenes/ui/screens/DuoLinkLoadoutScreen.tscn")
const ChronicleScreenScene = preload("res://scenes/ui/screens/ChronicleScreen.tscn")
const HeartCombatHUDScene = preload("res://scenes/ui/hud/HeartCombatHUD.tscn")
const DuoLinkCombatHUDScene = preload("res://scenes/ui/hud/DuoLinkCombatHUD.tscn")
const MultiFloorHUDScene = preload("res://scenes/ui/hud/MultiFloorHUD.tscn")
const Update4CouncilDecisionOverlayScript = preload("res://scripts/ui/Update4CouncilDecisionOverlay.gd")
const DungeonRendererScript = preload("res://scripts/map/DungeonRenderer.gd")
const QuarterDungeonRendererScript = preload("res://scripts/dungeon_quarter/QuarterDungeonRenderer.gd")
const AutoTileMaskScript = preload("res://scripts/dungeon_quarter/AutoTileMask.gd")
const IsoMathScript = preload("res://scripts/dungeon_quarter/IsoMath.gd")
const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const COMBAT_MUSIC = preload("res://assets/audio/bgm/combat_dungeon_pressure.wav")
const COMBAT_BOSS_MUSIC = preload("res://assets/audio/bgm/combat_boss_council.wav")
const MANAGEMENT_MUSIC = preload("res://assets/audio/bgm/management_castle_bustle.wav")
const MANAGEMENT_MUSIC_SCREENS := [
	Constants.SCREEN_MANAGEMENT,
	Constants.SCREEN_MONSTER,
	Constants.SCREEN_RESULT,
	Constants.SCREEN_CONTRACT_BOARD,
	Constants.SCREEN_FRONT_SELECTION,
	Constants.SCREEN_CAMPAIGN_MODE,
	Constants.SCREEN_REGION_SELECTION,
	Constants.SCREEN_OUTPOST_MANAGEMENT,
	Constants.SCREEN_UPPER_FLOOR,
	Constants.SCREEN_HEART_SELECTION,
	Constants.SCREEN_DUO_LINK_LOADOUT,
	Constants.SCREEN_CHRONICLE
]
const WORLD_RENDER_SCREENS := [
	Constants.SCREEN_MANAGEMENT,
	Constants.SCREEN_MONSTER,
	Constants.SCREEN_COMBAT,
	Constants.SCREEN_RESULT
]
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
var update2_cycle_seed := 0
var contract_board_offer_ids: Array[String] = []
var selected_contract_ids: Array[String] = []
var contract_board_pending_ids: Array[String] = []
var deployed_instance_ids: Array[String] = []
var reserve_instance_ids: Array[String] = []
var event_deck_order: Array[String] = []
var wave_variant_ids: Array[String] = []
var update2_triggered_event_ids: Array[String] = []
var leon_adaptation: Dictionary = LeonAdaptationServiceScript.default_adaptation()
var update3_profile: Dictionary = FrontCampaignServiceScript.default_update3_profile()
var update3_active_run: Dictionary = FrontCampaignServiceScript.default_legacy_active_run()
var update4_profile: Dictionary = CampaignModeServiceScript.default_profile()
var update4_active_run: Dictionary = CampaignModeServiceScript.default_active_run()
var onboarding_enabled := false
var onboarding_stage_id: String = "LV00_TITLE_BOOT"
var onboarding_dialogue_queue: Array = []
var onboarding_dialogue_index := 0
var onboarding_dialogue_return_screen: String = Constants.SCREEN_MANAGEMENT
var onboarding_dialogue_complete_action: String = ONBOARDING_ACTION_NONE
var onboarding_seen_dialogue_ids: Dictionary = {}
var onboarding_name_input: LineEdit = null
var onboarding_name_random_button: Button = null
var onboarding_name_confirm_button: Button = null
var onboarding_name_tip_overlay: Control = null
var onboarding_bati_comment_label: Label = null
var onboarding_name_entry_tip_dismissed := false
var onboarding_boss_hp_thresholds: Dictionary = {}
var onboarding_treasure_stolen_this_day := false
var tutorial_gate_enabled := true
var combat_speed_intro_seen := false
var combat_speed_intro_open := false
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
var update3_heart_loop_player: AudioStreamPlayer = null
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
var battle_contribution_events: Array[Dictionary] = []
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
var campaign_auxiliary_save_enabled := true
var campaign_save_v2_path: String = CampaignSaveV2StoreScript.SAVE_PATH
var campaign_save_v3_path: String = CampaignSaveV3StoreScript.SAVE_PATH
var campaign_save_v4_path: String = CampaignSaveV4StoreScript.SAVE_PATH
var campaign_save_v4_enabled := true
var campaign_save_v5_path: String = CampaignSaveV5StoreScript.SAVE_PATH
var campaign_save_v5_enabled := true
var campaign_save_v5_envelope: Dictionary = {}
var campaign_save_status: String = CampaignSaveStoreScript.STATUS_MISSING
var campaign_save_summary: Dictionary = {}
var campaign_save_error: String = ""
var campaign_save_notice: String = ""
var campaign_save_restore_active := false
var campaign_autosave_pending := false
var campaign_autosave_checkpoint: String = ""
var pending_title_reset_mode: String = ""

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


func _exit_tree() -> void:
	_shutdown_audio_for_exit()


func _shutdown_audio_for_exit() -> void:
	_kill_combat_music_tween()
	if combat_music_player != null:
		combat_music_player.stop()
		combat_music_player.stream = null
	if update3_heart_loop_player != null:
		update3_heart_loop_player.stop()
		update3_heart_loop_player.stream = null


func _configure_campaign_save_context() -> void:
	var current_scene_node := get_tree().current_scene
	var current_scene_path := ""
	if current_scene_node != null:
		current_scene_path = str(current_scene_node.scene_file_path)
	if current_scene_path.begins_with("res://tools/") and campaign_save_path == CampaignSaveStoreScript.SAVE_PATH:
		campaign_save_enabled = false
		campaign_auxiliary_save_enabled = false
		campaign_save_v5_enabled = false

func _set_campaign_save_path_for_tests(path: String, v2_path: String = "", v3_path: String = "", v4_path: String = "", v5_path: String = "") -> void:
	campaign_save_path = path
	campaign_save_enabled = path != ""
	campaign_auxiliary_save_enabled = v2_path != "" and v3_path != ""
	if campaign_auxiliary_save_enabled:
		campaign_save_v2_path = v2_path
		campaign_save_v3_path = v3_path
	campaign_save_v4_enabled = v4_path != ""
	if campaign_save_v4_enabled:
		campaign_save_v4_path = v4_path
	campaign_save_v5_enabled = v5_path != ""
	if campaign_save_v5_enabled:
		campaign_save_v5_path = v5_path
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
	var inspection: Dictionary = {}
	if campaign_save_v5_enabled:
		var v5_inspection := CampaignSaveV5StoreScript.inspect(campaign_save_v5_path, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_save_catalogs(), DataRegistry.update4_catalogs)
		if str(v5_inspection.get("status", "")) == CampaignSaveV5StoreScript.STATUS_MISSING and campaign_save_v4_enabled:
			var migration := CampaignSaveV5StoreScript.migrate_v4_file(campaign_save_v4_path, campaign_save_v5_path, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_save_catalogs(), DataRegistry.update4_catalogs)
			if bool(migration.get("ok", false)):
				v5_inspection = CampaignSaveV5StoreScript.inspect(campaign_save_v5_path, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_save_catalogs(), DataRegistry.update4_catalogs)
		if str(v5_inspection.get("status", "")) != CampaignSaveV5StoreScript.STATUS_MISSING:
			inspection = _campaign_v5_primary_inspection(v5_inspection)
	if inspection.is_empty():
		inspection = CampaignSaveStoreScript.inspect(campaign_save_path)
	campaign_save_status = str(inspection.get("status", CampaignSaveStoreScript.STATUS_CORRUPT))
	campaign_save_summary = inspection.get("summary", {}).duplicate(true)
	campaign_save_error = str(inspection.get("error", ""))
	return inspection


func _campaign_v5_primary_inspection(inspection: Dictionary) -> Dictionary:
	if str(inspection.get("status", "")) != CampaignSaveV5StoreScript.STATUS_VALID:
		campaign_save_v5_envelope.clear()
		return {"status": inspection.get("status", CampaignSaveV5StoreScript.STATUS_CORRUPT), "summary": {}, "payload": {}, "envelope": {}, "error": inspection.get("error", "")}
	var envelope: Dictionary = inspection.get("envelope", {}).duplicate(true)
	campaign_save_v5_envelope = envelope.duplicate(true)
	var profile: Dictionary = envelope.get("profile", {})
	update4_profile = CampaignModeServiceScript.normalize_profile(profile, profile)
	return {
		"status": CampaignSaveV5StoreScript.STATUS_VALID,
		"summary": envelope.get("summary", {}).duplicate(true),
		"payload": envelope.get("active_run", {}).get("legacy_payload", {}).duplicate(true),
		"envelope": envelope,
		"error": ""
	}

func _campaign_safe_save_screen(screen_name: String) -> bool:
	return screen_name in [
		Constants.SCREEN_MANAGEMENT,
		Constants.SCREEN_MONSTER,
		Constants.SCREEN_RESULT,
		Constants.SCREEN_ENDING,
		Constants.SCREEN_CONTRACT_BOARD,
		Constants.SCREEN_CAMPAIGN_MODE,
		Constants.SCREEN_REGION_SELECTION,
		Constants.SCREEN_OUTPOST_MANAGEMENT,
		Constants.SCREEN_FRONT_SELECTION,
		Constants.SCREEN_HEART_SELECTION,
		Constants.SCREEN_DUO_LINK_LOADOUT,
		Constants.SCREEN_CHRONICLE,
		Constants.SCREEN_CYCLE_DOCTRINE,
		Constants.SCREEN_CYCLE_DECREE,
		Constants.SCREEN_CHALLENGE_SEAL,
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
	if not _write_campaign_v2_snapshot():
		campaign_save_status = CampaignSaveStoreScript.STATUS_CORRUPT
		campaign_save_notice = "자동 저장 본문은 기록했지만 v5 저장을 완성하지 못했습니다.\n%s" % campaign_save_error
		push_warning("Campaign v5 autosave failed: %s" % campaign_save_error)
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
		"ending_archive_count": _known_ending_count(),
		"front_id": str(update3_active_run.get("front_id", "")),
		"front_name": str(DataRegistry.update3_fronts.get(str(update3_active_run.get("front_id", "")), {}).get("display_name", "")),
		"front_selection_pending": bool(update3_active_run.get("new_cycle_selection_pending", false)),
		"campaign_mode_id": str(update4_active_run.get("campaign_mode_id", ""))
	}


func _known_ending_count() -> int:
	var archive: Dictionary = campaign_profile.get("ending_archive", {})
	var ending_ids: Dictionary = {}
	for ending_id_value in archive.keys():
		ending_ids[str(ending_id_value)] = true
	if campaign_completed and campaign_final_battle_outcome == "victory" and resolved_campaign_ending_id != "" and resolved_campaign_ending_id != CouncilEndingServiceScript.LOCAL_FALLBACK_ID:
		ending_ids[resolved_campaign_ending_id] = true
	return ending_ids.size()

func _ending_catalog_ids() -> Array[String]:
	var ending_ids: Array[String] = []
	for ending_id_value in DataRegistry.ending_rules.keys():
		ending_ids.append(str(ending_id_value))
	ending_ids.sort_custom(func(a: String, b: String): return str(DataRegistry.ending_rule(a).get("catalog_code", "ZZZ")) < str(DataRegistry.ending_rule(b).get("catalog_code", "ZZZ")))
	return ending_ids

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
		Constants.SCREEN_CAMPAIGN_MODE:
			return "새 회차 모드 선택"
		Constants.SCREEN_REGION_SELECTION:
			return "의회 지역 선택"
		Constants.SCREEN_OUTPOST_MANAGEMENT:
			return "전초기지 관리"
		Constants.SCREEN_FRONT_SELECTION:
			return "새 회차 전선 선택"
		Constants.SCREEN_HEART_SELECTION:
			return "새 회차 심장 선택"
		Constants.SCREEN_CHRONICLE:
			return "전선 연대기"
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
			"combat_speed_intro_seen": combat_speed_intro_seen,
			"tutorial_manager": tutorial_manager.export_state()
		},
		"legacy_expansion": {
			"run_metrics": run_metrics_tracker.snapshot(),
			"resolved_ending_id": resolved_campaign_ending_id,
			"profile": campaign_profile.duplicate(true),
			"cycle_index": campaign_cycle_index,
			"legacy_monster": inherited_legacy_monster.duplicate(true)
		},
		"update2": {
			"cycle_seed": update2_cycle_seed,
			"contract_board_offer_ids": contract_board_offer_ids.duplicate(),
			"selected_contract_ids": selected_contract_ids.duplicate(),
			"deployed_instance_ids": deployed_instance_ids.duplicate(),
			"reserve_instance_ids": reserve_instance_ids.duplicate(),
			"stage_deployment_limit": _current_stage_deployment_limit(),
			"event_deck_order": event_deck_order.duplicate(),
			"wave_variant_ids": wave_variant_ids.duplicate(),
			"triggered_event_ids": update2_triggered_event_ids.duplicate(),
			"leon_adaptation": leon_adaptation.duplicate(true)
		},
		"update3": {
			"profile": update3_profile.duplicate(true),
			"active_run": update3_active_run.duplicate(true)
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
	var saved_update3: Dictionary = payload.get("update3", {}) if payload.get("update3") is Dictionary else {}
	var saved_update3_run: Dictionary = saved_update3.get("active_run", {}) if saved_update3.get("active_run") is Dictionary else {}
	var include_heart_chamber := HeartChamberServiceScript.should_spawn(saved_update3_run, target_stage_index)
	for stage_id_value in DataRegistry.castle_evolution_stage_ids():
		var expansion_stage_id := str(stage_id_value)
		if _castle_stage_index(expansion_stage_id) > target_stage_index:
			continue
		var addition: Dictionary = DataRegistry.castle_stage_expansion(expansion_stage_id)
		var placed_additions: Array = []
		var connection_additions: Array = []
		var required_additions: Array = []
		for entry in addition.get("placed_modules", []):
			if not bool(entry.get("update3_only", false)) or include_heart_chamber:
				placed_additions.append(entry)
		for entry in addition.get("connections", []):
			if not bool(entry.get("update3_only", false)) or include_heart_chamber:
				connection_additions.append(entry)
		for entry in addition.get("required_paths", []):
			if not bool(entry.get("update3_only", false)) or include_heart_chamber:
				required_additions.append(entry)
		_merge_unique_layout_entries(candidate_layout, "placed_modules", placed_additions, "instance_id")
		_merge_unique_layout_entries(candidate_layout, "connections", connection_additions, "from", "to")
		_merge_unique_layout_entries(candidate_layout, "required_paths", required_additions, "from", "to")
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
	var saved_cycle_index := maxi(1, int(payload.get("legacy_expansion", {}).get("cycle_index", 1)))
	var update3: Dictionary = payload.get("update3", {}) if payload.get("update3") is Dictionary else {}
	if update3.is_empty():
		update3_profile = FrontCampaignServiceScript.default_update3_profile()
		update3_active_run = FrontCampaignServiceScript.default_legacy_active_run(saved_cycle_index)
	else:
		update3_profile = FrontCampaignServiceScript.normalize_update3_profile(update3.get("profile", {}))
		update3_active_run = FrontCampaignServiceScript.normalize_active_run(update3.get("active_run", {}), saved_cycle_index)

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
	_sanitize_update3_legacy_rival_pact_metrics()
	resolved_campaign_ending_id = str(legacy_expansion.get("resolved_ending_id", "true_demon_castle"))
	var update2: Dictionary = payload.get("update2", {})
	update2_cycle_seed = int(update2.get("cycle_seed", 0))
	contract_board_offer_ids = _string_array(update2.get("contract_board_offer_ids", []))
	selected_contract_ids = _string_array(update2.get("selected_contract_ids", []))
	contract_board_pending_ids = selected_contract_ids.duplicate()
	deployed_instance_ids = _string_array(update2.get("deployed_instance_ids", []))
	reserve_instance_ids = _string_array(update2.get("reserve_instance_ids", []))
	event_deck_order = _string_array(update2.get("event_deck_order", []))
	wave_variant_ids = _string_array(update2.get("wave_variant_ids", []))
	update2_triggered_event_ids = _string_array(update2.get("triggered_event_ids", []))
	leon_adaptation = LeonAdaptationServiceScript.normalize(update2.get("leon_adaptation", {}), DataRegistry.leon_adaptive_stances)
	_ensure_update2_seeded_campaign()
	_sync_update3_reward_monsters()
	_sync_contract_reserves()

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
	combat_speed_intro_seen = bool(onboarding.get("combat_speed_intro_seen", false))
	combat_speed_intro_open = false
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
	var legacy_update2_run := not bool(update3_active_run.get("update3_enabled", false)) \
		and not bool(update3_active_run.get("new_cycle_selection_pending", false)) \
		and not bool(update3_active_run.get("front_selection_completed", false))
	var council_run := str(update4_active_run.get("campaign_mode_id", "")) == CampaignModeServiceScript.COUNCIL_MODE_ID
	if council_run:
		restored_screen = Constants.SCREEN_MANAGEMENT
	elif campaign_cycle_index >= 2 and not legacy_update2_run:
		var setup_screen := _next_update2_cycle_setup_screen()
		if setup_screen != Constants.SCREEN_MANAGEMENT:
			restored_screen = setup_screen
	logs.append("저장 기록을 불러왔습니다. DAY %d." % GameState.day)
	_set_screen(restored_screen)
	campaign_save_restore_active = false
	return true

func _continue_campaign_save() -> void:
	var inspection := _refresh_campaign_save_status()
	if campaign_save_status != CampaignSaveStoreScript.STATUS_VALID:
		_set_screen(Constants.SCREEN_TITLE)
		return
	var v5_envelope: Dictionary = inspection.get("envelope", {})
	if not v5_envelope.is_empty():
		_load_update4_context_from_v5(v5_envelope, false)
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
	elif not v5_envelope.is_empty():
		_load_update4_context_from_v5(v5_envelope, true)


func _load_update4_context_from_v5(envelope: Dictionary, include_update3: bool) -> void:
	var profile: Dictionary = envelope.get("profile", {})
	var active_run: Dictionary = envelope.get("active_run", {})
	update4_profile = CampaignModeServiceScript.normalize_profile(profile, profile)
	update4_active_run = CampaignModeServiceScript.normalize_active_run(active_run)
	if include_update3:
		update3_profile = FrontCampaignServiceScript.normalize_update3_profile(profile)
		update3_active_run = FrontCampaignServiceScript.normalize_active_run(active_run, campaign_cycle_index)

func _delete_campaign_save() -> bool:
	campaign_autosave_pending = false
	if not campaign_save_enabled:
		campaign_save_notice = ""
		return true
	var removed := CampaignSaveStoreScript.delete(campaign_save_path)
	if removed and campaign_save_path == CampaignSaveStoreScript.SAVE_PATH:
		removed = CampaignSaveV2StoreScript.delete(CampaignSaveV2StoreScript.SAVE_PATH)
		removed = CampaignSaveV3StoreScript.delete(CampaignSaveV3StoreScript.SAVE_PATH) and removed
		removed = CampaignSaveV4StoreScript.delete(CampaignSaveV4StoreScript.SAVE_PATH) and removed
		removed = CampaignSaveV5StoreScript.delete(CampaignSaveV5StoreScript.SAVE_PATH) and removed
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
	_update3_duo_link_effects(delta)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and _text_input_owns_keyboard():
		return
	if combat_speed_intro_open:
		if event is InputEventKey and event.pressed and not event.echo and _is_dialogue_advance_key(event.keycode):
			_dismiss_combat_speed_intro()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and current_screen == Constants.SCREEN_COMBAT and event.keycode == KEY_H:
		_activate_update3_heart()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and current_screen == Constants.SCREEN_COMBAT and event.keycode == KEY_J:
		var equipped_links: Array = update3_active_run.get("equipped_duo_links", [])
		_activate_update3_duo_link(str(equipped_links[0]) if not equipped_links.is_empty() else "")
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and current_screen == Constants.SCREEN_COMBAT and event.keycode == KEY_K:
		var equipped_links: Array = update3_active_run.get("equipped_duo_links", [])
		_activate_update3_duo_link(str(equipped_links[1]) if equipped_links.size() > 1 else "")
		get_viewport().set_input_as_handled()
		return
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
	if UISettings.is_touch_ui():
		var tutorial_touch_pressed: bool = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
		if tutorial_touch_pressed and _handle_mobile_tutorial_focus_tap(event.position):
			get_viewport().set_input_as_handled()
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
				if current_screen == Constants.SCREEN_COMBAT and UISettings.is_touch_ui():
					_handle_touch_combat_tap(point, screen_point)
				else:
					_handle_left_click(point, screen_point)
	elif event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event.keycode)

func _text_input_owns_keyboard() -> bool:
	var focus_owner := get_viewport().gui_get_focus_owner()
	return focus_owner is LineEdit or focus_owner is TextEdit

func _draw() -> void:
	if not _screen_uses_world_render(current_screen):
		return
	if use_quarter_module_map and quarter_renderer != null:
		quarter_renderer.draw()
		if current_screen != Constants.SCREEN_COMBAT:
			dungeon_renderer.draw_roster_preview()
	else:
		dungeon_renderer.draw()
	_draw_combat_facility_feedback()
	_draw_management_drag_feedback()

func _screen_uses_world_render(screen_name: String) -> bool:
	return screen_name in WORLD_RENDER_SCREENS

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
		var custom_memory_ids: Dictionary = DataRegistry.monster(monster_id).get("bond_memory_ids", {})
		unlocked_memory_id = str(custom_memory_ids.get(str(rank_after), "")) if not custom_memory_ids.is_empty() else "bond_%s_rank_%d" % [monster_id, rank_after]
		if unlocked_memory_id != "":
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
	var stage_info := _castle_stage_info()
	expanded["castle_stage_id"] = castle_art_stage
	expanded["unlocked_room_grid_ids"] = stage_info.get("unlocked_room_grid_ids", []).duplicate()
	for stage_id_value in DataRegistry.castle_evolution_stage_ids():
		var stage_id := str(stage_id_value)
		if _castle_stage_index(stage_id) > _castle_stage_index():
			continue
		var addition: Dictionary = DataRegistry.castle_stage_expansion(stage_id)
		_merge_unique_layout_entries(expanded, "placed_modules", _update3_stage_entries(addition.get("placed_modules", [])), "instance_id")
		_merge_unique_layout_entries(expanded, "connections", _update3_stage_entries(addition.get("connections", [])), "from", "to")
		_merge_unique_layout_entries(expanded, "required_paths", _update3_stage_entries(addition.get("required_paths", [])), "from", "to")
	return expanded

func _update3_heart_chamber_should_spawn(stage_index: int = -1) -> bool:
	var target_stage := _castle_stage_index() if stage_index < 0 else stage_index
	return HeartChamberServiceScript.should_spawn(update3_active_run, target_stage)

func _update3_stage_entries(values) -> Array:
	var filtered: Array = []
	if not (values is Array):
		return filtered
	for value in values:
		if not (value is Dictionary):
			continue
		if bool(value.get("update3_only", false)) and not _update3_heart_chamber_should_spawn():
			continue
		filtered.append(value.duplicate(true))
	return filtered

func _update3_enemy_goal(original_goal: String = "throne", prefers_heart: bool = true) -> String:
	return HeartChamberServiceScript.enemy_goal(update3_active_run, original_goal, prefers_heart)

func _sync_update3_heart_awaken() -> bool:
	var result := CastleHeartServiceScript.awaken(update3_active_run, GameState.day)
	update3_active_run = result.get("active_run", update3_active_run).duplicate(true)
	_apply_update3_dream_max_hp()
	if bool(result.get("awakened_now", false)):
		var heart_id := str(update3_active_run.get("heart", {}).get("heart_id", ""))
		var heart_name := str(DataRegistry.update3_castle_hearts.get(heart_id, {}).get("display_name", heart_id))
		_log("DAY %d: %s이(가) 각성했습니다. Stage 02 전까지는 왕좌 패시브로 작동합니다." % [GameState.day, heart_name])
		return true
	return false

func _apply_update3_dream_max_hp() -> void:
	var chamber_base := HeartChamberServiceScript.hp_for_stage(_castle_stage_index()) if _castle_stage_index() >= 2 else 0
	var result := CastleHeartServiceScript.apply_dream_max_hp(update3_active_run, GameState.demon_lord_hp, GameState.demon_lord_max_hp, chamber_base)
	update3_active_run = result.get("active_run", update3_active_run).duplicate(true)
	GameState.demon_lord_max_hp = int(result.get("throne_max_hp", GameState.demon_lord_max_hp))
	GameState.demon_lord_hp = int(result.get("throne_hp", GameState.demon_lord_hp))

func _apply_update3_daily_heart_upkeep() -> int:
	var result := CastleHeartServiceScript.apply_daily_upkeep(update3_active_run, GameState.day, GameState.food)
	update3_active_run = result.get("active_run", update3_active_run).duplicate(true)
	var paid := int(result.get("paid", 0))
	if paid > 0:
		GameState.food = int(result.get("food", GameState.food))
		SignalBus.resources_changed.emit()
		_log("포식 심장 일일 유지비로 식량 %d을 사용했습니다." % paid)
	return paid

func _prepare_update3_heart_battle() -> void:
	_sync_update3_heart_awaken()
	update3_active_run = CastleHeartServiceScript.start_battle(update3_active_run, "cycle_%d_day_%d" % [campaign_cycle_index, GameState.day], _castle_stage_index())
	if rooms.has(HeartChamberServiceScript.ROOM_ID):
		var heart: Dictionary = update3_active_run.get("heart", {})
		rooms[HeartChamberServiceScript.ROOM_ID]["hp"] = int(heart.get("chamber_hp", 0))
		rooms[HeartChamberServiceScript.ROOM_ID]["disabled"] = false
	_start_update3_heart_loop()

func _update3_active_facility_room_ids() -> Array:
	var result: Array = []
	for room_id_value in rooms.keys():
		var room_id := str(room_id_value)
		var role := str(rooms[room_id].get("facility_role", ""))
		if role in ["", "entry", "trap", "corridor", "core", "build_slot"]:
			continue
		if role == "heart_chamber":
			if int(update3_active_run.get("heart", {}).get("chamber_hp", 0)) > 0:
				result.append(room_id)
		elif _facility_room_is_active(room_id):
			result.append(room_id)
	return result

func _activate_update3_heart(target_room_id: String = "") -> Dictionary:
	var resolved_room := target_room_id
	var heart_id := str(update3_active_run.get("heart", {}).get("heart_id", ""))
	if resolved_room == "" and heart_id in [CastleHeartServiceScript.HUNGRY_MAW_ID, CastleHeartServiceScript.DREAM_LANTERN_ID]:
		resolved_room = _update3_devouring_target_room()
	var dream_targets := _update3_dream_target_entries(resolved_room) if heart_id == CastleHeartServiceScript.DREAM_LANTERN_ID else []
	var result := CastleHeartServiceScript.activate(update3_active_run, _update3_active_facility_room_ids(), resolved_room, GameState.demon_lord_hp, dream_targets)
	update3_active_run = result.get("active_run", update3_active_run).duplicate(true)
	if bool(result.get("ok", false)):
		var mastery_result := CastleHeartServiceScript.record_active_use(update3_profile, update3_active_run)
		update3_profile = mastery_result.get("profile", update3_profile).duplicate(true)
		update3_active_run = mastery_result.get("active_run", update3_active_run).duplicate(true)
		if str(result.get("skill_id", "")) == CastleHeartServiceScript.HUNGRY_ACTIVE_SKILL_ID:
			GameState.demon_lord_hp = int(result.get("throne_hp", GameState.demon_lord_hp))
			SignalBus.resources_changed.emit()
			_log("포식 심장 액티브: %s 방을 5초 동안 삼킵니다. 왕좌 HP -35." % display_name_for_instance(resolved_room))
		elif str(result.get("skill_id", "")) == CastleHeartServiceScript.DREAM_ACTIVE_SKILL_ID:
			_apply_update3_false_corridor_targets(dream_targets, resolved_room)
			_log("몽등 심장 액티브: %s을(를) 미끼 방으로 삼아 적 %d명을 교란합니다." % [display_name_for_instance(resolved_room), int(result.get("target_count", 0))])
		else:
			_log("석골 심장 액티브: 성 전체 버티기 6초, 활성 시설 보호막 45.")
		_spawn_update3_heart_art(heart_id, false)
		var active_cue: String = str({"heart_stonebone": "heart_stonebone_active", "heart_hungry_maw": "heart_hungry_active", "heart_dream_lantern": "heart_dream_active"}.get(heart_id, ""))
		_play_update3_sfx(active_cue, -7.0)
		if combat_scene != null and combat_scene.has_method("trigger_leon_heart_response"):
			combat_scene.trigger_leon_heart_response(heart_id)
	else:
		_log(str(result.get("error", "심장 액티브를 사용할 수 없습니다.")))
	queue_redraw()
	return result

func _update3_dream_target_entries(bait_room_id: String) -> Array:
	var result: Array = []
	if bait_room_id == "" or not rooms.has(bait_room_id) or str(rooms[bait_room_id].get("type", "")) == "build_slot" or graph == null:
		return result
	for enemy in enemy_units:
		if result.size() >= 2:
			break
		if not is_instance_valid(enemy) or not enemy.is_alive():
			continue
		if enemy.unit_id == "thief" and float(thief_steal_timers.get(enemy, 0.0)) < -100.0:
			continue
		if enemy.unit_id == "engineer" and engineer_completed_units.has(enemy.get_instance_id()):
			continue
		var boss := _update3_enemy_is_boss(enemy)
		if not boss and str(enemy.current_room) == bait_room_id:
			continue
		if not boss and graph.path_between(str(enemy.current_room), bait_room_id).is_empty():
			continue
		result.append({"token": str(enemy.get_instance_id()), "unit_id": str(enemy.unit_id), "original_goal": str(enemy.goal_room), "boss": boss})
	return result

func _apply_update3_false_corridor_targets(target_entries: Array, bait_room_id: String) -> void:
	for entry_value in target_entries:
		if not (entry_value is Dictionary):
			continue
		var entry: Dictionary = entry_value
		var enemy = instance_from_id(int(entry.get("token", "0")))
		if enemy == null or not is_instance_valid(enemy) or not enemy.is_alive():
			continue
		if bool(entry.get("boss", false)):
			enemy.apply_slow(CastleHeartServiceScript.DREAM_BOSS_SLOW_SECONDS, CastleHeartServiceScript.DREAM_BOSS_SLOW_SCALE)
		else:
			combat_scene.move_unit_to_room(enemy, bait_room_id)
			var metrics: Dictionary = update3_active_run.get("run_metrics_update3", {}).duplicate(true)
			metrics["dream_path_rebuilds"] = int(metrics.get("dream_path_rebuilds", 0)) + 1
			update3_active_run["run_metrics_update3"] = metrics

func _update3_false_corridor_holds(unit: Node) -> bool:
	if unit == null or not is_instance_valid(unit):
		return false
	var entry: Dictionary = update3_active_run.get("heart", {}).get("false_corridor_targets", {}).get(str(unit.get_instance_id()), {})
	if entry.is_empty() or bool(entry.get("boss", false)):
		return false
	if str(unit.current_room) == str(entry.get("bait_room", "")):
		unit.stop_navigation()
		unit.set_tactical_state(Constants.UNIT_STATE_IDLE, "가짜 복도에 현혹", display_name_for_instance(str(entry.get("bait_room", ""))))
	return true

func _update3_devouring_target_room() -> String:
	if selected_unit != null and is_instance_valid(selected_unit) and rooms.has(str(selected_unit.current_room)):
		return str(selected_unit.current_room)
	var counts: Dictionary = {}
	for enemy in enemy_units:
		if is_instance_valid(enemy) and enemy.is_alive() and rooms.has(str(enemy.current_room)):
			var room_id := str(enemy.current_room)
			counts[room_id] = int(counts.get(room_id, 0)) + 1
	var best_room := ""
	var best_count := 0
	for room_id_value in counts.keys():
		var room_id := str(room_id_value)
		if int(counts[room_id]) > best_count:
			best_room = room_id
			best_count = int(counts[room_id])
	return best_room

func _record_update3_heart_charge(source_id: String, amount: int, event_token: String) -> int:
	var result := CastleHeartServiceScript.record_charge(update3_active_run, source_id, amount, event_token, combat_time)
	update3_active_run = result.get("active_run", update3_active_run).duplicate(true)
	return int(result.get("gain", 0))


func _suppress_update3_heart_charge(seconds: float) -> void:
	update3_active_run = CastleHeartServiceScript.suppress_charge(update3_active_run, seconds)
	queue_redraw()


func _update3_heart_charge_suppression_remaining() -> float:
	return float(update3_active_run.get("heart", {}).get("charge_suppressed_remaining", 0.0))

func _record_update3_hungry_damage(actual_damage: int, attack_token: String) -> int:
	var result := CastleHeartServiceScript.record_hungry_damage(update3_active_run, actual_damage, attack_token)
	update3_active_run = result.get("active_run", update3_active_run).duplicate(true)
	return int(result.get("gain", 0))

func _record_update3_dream_charge(source_id: String, event_token: String) -> int:
	var result := CastleHeartServiceScript.record_dream_charge(update3_active_run, source_id, event_token)
	update3_active_run = result.get("active_run", update3_active_run).duplicate(true)
	return int(result.get("gain", 0))

func _on_update3_unit_effective_healed(unit: Node, amount: int, event_token: String) -> void:
	if unit != null and is_instance_valid(unit) and unit.faction == Constants.FACTION_MONSTER and amount > 0:
		var token := event_token if event_token != "" else "%s:%d" % [str(unit.get_instance_id()), Time.get_ticks_usec()]
		_record_update3_dream_charge("effective_heal", token)

func _on_update3_first_control_applied(unit: Node) -> void:
	if unit != null and is_instance_valid(unit) and unit.faction == Constants.FACTION_ENEMY:
		_record_update3_dream_charge("first_status", str(unit.get_instance_id()))

func _record_update3_hungry_finish(target: Node) -> Dictionary:
	if target == null or not is_instance_valid(target):
		return {"counted": false, "wave": false}
	var result := CastleHeartServiceScript.record_hungry_finish(update3_active_run, str(target.get_instance_id()))
	update3_active_run = result.get("active_run", update3_active_run).duplicate(true)
	if bool(result.get("wave", false)):
		rewards_pending["infamy"] = int(rewards_pending.get("infamy", 0)) + int(result.get("infamy", 0))
		_emit_update3_hunger_wave()
	return result

func _emit_update3_hunger_wave() -> Dictionary:
	var engaged_rooms: Dictionary = {}
	for monster in monster_units:
		if is_instance_valid(monster) and monster.is_alive():
			engaged_rooms[str(monster.current_room)] = true
	var hit_count := 0
	var damage_total := 0
	var morale_total := 0
	for enemy in enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive() or not engaged_rooms.has(str(enemy.current_room)):
			continue
		var boss := _update3_enemy_is_boss(enemy)
		var damage := CastleHeartServiceScript.HUNGER_WAVE_BOSS_DAMAGE if boss else CastleHeartServiceScript.HUNGER_WAVE_DAMAGE
		var dealt := int(enemy.receive_magic_damage(damage))
		enemy.morale = maxi(0, int(enemy.morale) - CastleHeartServiceScript.HUNGER_WAVE_MORALE_DAMAGE)
		hit_count += 1
		damage_total += dealt
		morale_total += CastleHeartServiceScript.HUNGER_WAVE_MORALE_DAMAGE
	var metrics: Dictionary = update3_active_run.get("run_metrics_update3", {}).duplicate(true)
	metrics["hungry_wave_damage"] = int(metrics.get("hungry_wave_damage", 0)) + damage_total
	metrics["hungry_wave_morale_damage"] = int(metrics.get("hungry_wave_morale_damage", 0)) + morale_total
	update3_active_run["run_metrics_update3"] = metrics
	_log("포식 파동: 교전 중인 적 %d명에게 체력 피해 %d, 사기 피해 %d." % [hit_count, damage_total, morale_total])
	return {"hit_count": hit_count, "damage": damage_total, "morale_damage": morale_total}


func _record_update3_metric_count(metric_id: String, amount: int = 1) -> void:
	if metric_id == "" or amount == 0:
		return
	var metrics: Dictionary = update3_active_run.get("run_metrics_update3", {}).duplicate(true)
	metrics[metric_id] = int(metrics.get(metric_id, 0)) + amount
	update3_active_run["run_metrics_update3"] = metrics


func _record_update3_throne_damage(amount: int) -> void:
	_record_update3_metric_count("campaign_throne_damage", maxi(0, amount))

func _update3_enemy_is_boss(enemy: Node) -> bool:
	return enemy != null and str(enemy.unit_id) in ["trainee_hero", "selen_trainee_paladin", "roman", "official_hero_leon", "official_paladin_selen", "guild_commissioner_roman", "royal_strategist_evelyn"]

func _damage_update3_facility(room_id: String, amount: int, event_token: String = "") -> Dictionary:
	if not rooms.has(room_id) or str(rooms[room_id].get("facility_role", "")) in ["", "entry", "trap", "corridor", "core", "build_slot"]:
		return {"ok": false, "damage": 0, "error": "피해를 받을 활성 시설이 아닙니다."}
	var token := event_token if event_token != "" else "%s:%d" % [room_id, Time.get_ticks_msec()]
	var result := CastleHeartServiceScript.apply_room_damage(update3_active_run, room_id, amount, token, combat_time)
	update3_active_run = result.get("active_run", update3_active_run).duplicate(true)
	if not rooms[room_id].has("max_hp"):
		rooms[room_id]["max_hp"] = int(rooms[room_id].get("hp", 0))
	rooms[room_id]["hp"] = maxi(0, int(rooms[room_id].get("hp", 0)) - int(result.get("damage", 0)))
	if combat_scene != null and combat_scene.has_method("notify_toktok_facility_hit"):
		combat_scene.notify_toktok_facility_hit(room_id, int(result.get("damage", 0)))
	result["ok"] = true
	result["room_hp"] = int(rooms[room_id]["hp"])
	return result

func _repair_update3_facility(room_id: String, amount: int, event_token: String = "") -> Dictionary:
	if not rooms.has(room_id):
		return {"ok": false, "repair": 0, "error": "수리할 방이 없습니다."}
	var token := event_token if event_token != "" else "%s:%d" % [room_id, Time.get_ticks_msec()]
	var result := CastleHeartServiceScript.apply_repair(update3_active_run, amount, token, combat_time)
	update3_active_run = result.get("active_run", update3_active_run).duplicate(true)
	var maximum := int(rooms[room_id].get("max_hp", rooms[room_id].get("hp", 0)))
	var before := int(rooms[room_id].get("hp", 0))
	rooms[room_id]["hp"] = mini(maximum, before + int(result.get("repair", 0)))
	if room_id == HeartChamberServiceScript.ROOM_ID:
		update3_active_run["heart"]["chamber_hp"] = int(rooms[room_id]["hp"])
	result["ok"] = true
	result["effective_repair"] = maxi(0, int(rooms[room_id]["hp"]) - before)
	result["room_hp"] = int(rooms[room_id]["hp"])
	return result

func _damage_update3_heart_chamber(amount: int) -> Dictionary:
	var mitigation := CastleHeartServiceScript.apply_room_damage(update3_active_run, HeartChamberServiceScript.ROOM_ID, amount, "heart:%d" % Time.get_ticks_msec(), combat_time)
	update3_active_run = mitigation.get("active_run", update3_active_run).duplicate(true)
	var result: Dictionary = HeartChamberServiceScript.damage(update3_active_run, int(mitigation.get("damage", amount)))
	update3_active_run = result.get("active_run", update3_active_run).duplicate(true)
	if bool(result.get("disabled", false)):
		update3_active_run = CastleHeartServiceScript.record_chamber_disabled(update3_active_run)
		result["active_run"] = update3_active_run.duplicate(true)
		_spawn_update3_heart_art(str(update3_active_run.get("heart", {}).get("heart_id", "")), true)
		_play_update3_sfx("heart_disabled", -6.0)
	result["passive_reduced"] = int(mitigation.get("reduced", 0))
	result["shield_absorbed"] = int(mitigation.get("shield_absorbed", 0))
	if combat_scene != null and combat_scene.has_method("notify_toktok_facility_hit"):
		combat_scene.notify_toktok_facility_hit(HeartChamberServiceScript.ROOM_ID, int(result.get("damage", mitigation.get("damage", amount))))
	if rooms.has(HeartChamberServiceScript.ROOM_ID):
		var heart: Dictionary = update3_active_run.get("heart", {})
		rooms[HeartChamberServiceScript.ROOM_ID]["hp"] = int(heart.get("chamber_hp", 0))
		rooms[HeartChamberServiceScript.ROOM_ID]["disabled"] = bool(heart.get("disabled_this_battle", false))
	return result


func _spawn_update3_heart_art(heart_id: String, inactive: bool) -> void:
	if effect_root == null:
		return
	var ids := ["heart_stonebone", "heart_hungry_maw", "heart_dream_lantern"]
	var index := ids.find(heart_id)
	if index < 0:
		return
	var sheet_path := "res://assets/sprites/hearts/heart_props_sheet.png" if inactive else "res://assets/ui/hearts/heart_icons_vfx_sheet.png"
	var sheet := load(sheet_path) as Texture2D
	if sheet == null:
		return
	var grid := Vector2i(4, 3) if inactive else Vector2i(3, 2)
	var cell := Vector2i(3, index) if inactive else Vector2i(index, 1)
	var cell_size := Vector2(sheet.get_width() / float(grid.x), sheet.get_height() / float(grid.y))
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(cell) * cell_size, cell_size)
	var sprite := Sprite2D.new()
	sprite.name = "HeartInactiveArt" if inactive else "HeartActiveVfx"
	sprite.texture = atlas
	sprite.position = graph.rect(HeartChamberServiceScript.ROOM_ID).get_center() if graph != null and rooms.has(HeartChamberServiceScript.ROOM_ID) else Vector2(960, 540)
	sprite.scale = Vector2.ONE * (0.22 if inactive else 0.20)
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); float m=min(c.r,c.b)-c.g; float balance=1.0-smoothstep(0.10,0.32,abs(c.r-c.b)); float k=smoothstep(0.10,0.34,m)*balance; c.a*=1.0-k; COLOR=c; }"
	var material := ShaderMaterial.new()
	material.shader = shader
	sprite.material = material
	effect_root.add_child(sprite)
	var tween := sprite.create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2.ONE * (0.38 if inactive else 0.52), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.9).set_delay(0.48)
	tween.chain().tween_callback(sprite.queue_free)


func _start_update3_heart_loop() -> void:
	var heart_id := str(update3_active_run.get("heart", {}).get("heart_id", ""))
	var cue := str({"heart_stonebone": "heart_stonebone_loop", "heart_hungry_maw": "heart_hungry_loop", "heart_dream_lantern": "heart_dream_loop"}.get(heart_id, ""))
	if cue == "" or effect_root == null:
		return
	if update3_heart_loop_player == null:
		update3_heart_loop_player = AudioStreamPlayer.new()
		update3_heart_loop_player.name = "Update3HeartLoop"
		update3_heart_loop_player.bus = AudioSettings.SFX_BUS
		effect_root.add_child(update3_heart_loop_player)
	var source := load("res://assets/audio/update3/%s.wav" % cue)
	if source == null:
		return
	var loop_stream := source.duplicate(true)
	if loop_stream is AudioStreamWAV:
		loop_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	update3_heart_loop_player.stream = loop_stream
	update3_heart_loop_player.volume_db = -22.0
	update3_heart_loop_player.play()


func _play_update3_sfx(cue: String, volume_db: float = -8.0) -> void:
	if effect_root == null or cue == "":
		return
	var prefix := "Update3Sfx_"
	var active_total := 0
	for child in effect_root.get_children():
		if str(child.name).begins_with(prefix):
			active_total += 1
			if str(child.name) == "%s%s" % [prefix, cue]:
				return
	if active_total >= 4:
		return
	var stream := load("res://assets/audio/update3/%s.wav" % cue)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.name = "%s%s" % [prefix, cue]
	player.stream = stream
	player.bus = AudioSettings.SFX_BUS
	player.volume_db = volume_db
	effect_root.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _play_update3_enemy_warning(enemy_id: String) -> void:
	if enemy_id in ["seal_chainbearer", "reliquary_guard", "choir_exorcist", "bounty_tracker", "combat_alchemist", "ledger_binder"]:
		_play_update3_sfx("enemy_%s" % enemy_id, -10.0)
	elif enemy_id == "official_paladin_selen":
		_play_update3_sfx("boss_selen_motif", -12.0)
	elif enemy_id == "guild_commissioner_roman":
		_play_update3_sfx("boss_roman_motif", -12.0)


func _damage_update3_room(room_id: String, amount: int, event_token: String = "") -> Dictionary:
	if room_id == HeartChamberServiceScript.ROOM_ID:
		return _damage_update3_heart_chamber(amount)
	if not rooms.has(room_id):
		return {"ok": false, "damage": 0, "error": "방을 찾을 수 없습니다."}
	var token := event_token if event_token != "" else "room:%s:%d" % [room_id, Time.get_ticks_usec()]
	var mitigation := CastleHeartServiceScript.apply_room_damage(update3_active_run, room_id, amount, token, combat_time)
	update3_active_run = mitigation.get("active_run", update3_active_run).duplicate(true)
	var damage := maxi(0, int(mitigation.get("damage", amount)))
	var before := int(rooms[room_id].get("hp", 0))
	rooms[room_id]["hp"] = maxi(0, before - damage)
	if combat_scene != null and combat_scene.has_method("notify_toktok_facility_hit"):
		combat_scene.notify_toktok_facility_hit(room_id, damage)
	return {"ok": damage > 0, "damage": mini(before, damage), "room_hp": int(rooms[room_id]["hp"]), "passive_reduced": int(mitigation.get("reduced", 0)), "shield_absorbed": int(mitigation.get("shield_absorbed", 0))}


func _apply_update3_heart_debt_lock(disable_seconds: float, lock_seconds: float) -> void:
	update3_active_run = CastleHeartServiceScript.apply_debt_disable_and_lock(update3_active_run, disable_seconds, lock_seconds)
	queue_redraw()

func _update3_modify_monster_damage(target: Node, amount: int) -> int:
	if target == null or not is_instance_valid(target) or target.faction != Constants.FACTION_MONSTER:
		return amount
	var result := CastleHeartServiceScript.monster_damage(update3_active_run, amount, rooms.has(str(target.current_room)))
	var reduced := int(result.get("reduced", 0))
	if reduced > 0:
		var metrics: Dictionary = update3_active_run.get("run_metrics_update3", {}).duplicate(true)
		metrics["stonebone_monster_damage_reduced"] = int(metrics.get("stonebone_monster_damage_reduced", 0)) + reduced
		metrics["heart_metric_contribution"] = int(metrics.get("heart_metric_contribution", 0)) + reduced
		update3_active_run["run_metrics_update3"] = metrics
	return int(result.get("damage", amount))

func _update3_refresh_monster_heart_position(unit: Node) -> void:
	if unit == null or not is_instance_valid(unit) or unit.faction != Constants.FACTION_MONSTER:
		return
	unit.heart_def_bonus = 0
	unit.heart_move_multiplier = 1.0
	unit.heart_healing_multiplier = CastleHeartServiceScript.healing_multiplier(update3_active_run)
	unit.heart_skill_recovery_multiplier = CastleHeartServiceScript.skill_recovery_multiplier(update3_active_run)
	if not CastleHeartServiceScript.passive_active(update3_active_run) or not monster_roster.has(str(unit.unit_id)):
		return
	var assigned_room := str(monster_roster[str(unit.unit_id)].get("room", ""))
	var current_room := str(unit.current_room)
	if assigned_room == "" or current_room == "" or graph == null:
		return
	var route: Array = graph.path_between(assigned_room, current_room)
	var distance := maxi(0, route.size() - 1)
	if distance <= 1:
		unit.heart_def_bonus = 1
	elif distance > 2:
		unit.heart_move_multiplier = 0.94

func _update3_refresh_enemy_heart_control(unit: Node) -> void:
	if unit == null or not is_instance_valid(unit) or unit.faction != Constants.FACTION_ENEMY:
		return
	var is_boss := _update3_enemy_is_boss(unit)
	unit.heart_first_control_multiplier = CastleHeartServiceScript.first_control_multiplier(update3_active_run) if not is_boss else 1.0
	if unit.heart_first_control_multiplier > 1.0 and not bool(unit.get_meta("dream_control_initialized", false)):
		unit.heart_first_control_available = true
		unit.set_meta("dream_control_initialized", true)

func _tick_update3_heart(delta: float) -> void:
	var result := CastleHeartServiceScript.tick_events(update3_active_run, delta)
	update3_active_run = result.get("active_run", update3_active_run).duplicate(true)
	for _pulse_index in range(int(result.get("hungry_pulses", 0))):
		_apply_update3_devouring_pulse(str(result.get("target_room_id", "")))
	for restore_value in result.get("dream_restore_entries", []):
		if not (restore_value is Dictionary) or bool(restore_value.get("boss", false)):
			continue
		var unit = instance_from_id(int(restore_value.get("token", "0")))
		if unit == null or not is_instance_valid(unit) or not unit.is_alive():
			continue
		var original_goal := str(restore_value.get("original_goal", ""))
		if original_goal != "" and rooms.has(original_goal):
			combat_scene.move_unit_to_room(unit, original_goal)
			var metrics: Dictionary = update3_active_run.get("run_metrics_update3", {}).duplicate(true)
			metrics["dream_path_rebuilds"] = int(metrics.get("dream_path_rebuilds", 0)) + 1
			metrics["dream_goal_restores"] = int(metrics.get("dream_goal_restores", 0)) + 1
			update3_active_run["run_metrics_update3"] = metrics

func _apply_update3_devouring_pulse(room_id: String) -> Dictionary:
	var hit_count := 0
	var damage_total := 0
	for enemy in enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive() or str(enemy.current_room) != room_id:
			continue
		var dealt := int(enemy.receive_magic_damage(CastleHeartServiceScript.HUNGRY_ACTIVE_DAMAGE_PER_SECOND))
		enemy.apply_slow(1.1, CastleHeartServiceScript.HUNGRY_ACTIVE_BOSS_SLOW_SCALE if _update3_enemy_is_boss(enemy) else CastleHeartServiceScript.HUNGRY_ACTIVE_SLOW_SCALE)
		hit_count += 1
		damage_total += dealt
	var metrics: Dictionary = update3_active_run.get("run_metrics_update3", {}).duplicate(true)
	metrics["hungry_active_damage"] = int(metrics.get("hungry_active_damage", 0)) + damage_total
	update3_active_run["run_metrics_update3"] = metrics
	return {"hit_count": hit_count, "damage": damage_total}

func _update3_heart_result_lines() -> Array[String]:
	var heart: Dictionary = update3_active_run.get("heart", {})
	if str(heart.get("heart_id", "")) == "":
		return []
	var metrics: Dictionary = update3_active_run.get("run_metrics_update3", {})
	if str(heart.get("heart_id", "")) == CastleHeartServiceScript.HUNGRY_MAW_ID:
		return ["포식 심장: 충전 %d/100 · 파동 %d/3 · 보너스 악명 %d/9 · 파동 피해 %d · 왕좌 소모 %d" % [
			int(heart.get("charge", 0)), int(heart.get("hunger_waves", 0)), int(heart.get("hungry_infamy_earned", 0)),
			int(metrics.get("hungry_wave_damage", 0)), int(metrics.get("hungry_throne_hp_spent", 0))
		]]
	if str(heart.get("heart_id", "")) == CastleHeartServiceScript.DREAM_LANTERN_ID:
		return ["몽등 심장: 충전 %d/100 · 목표 변경 %d · 원래 목표 복귀 %d · 경로 재생성 %d" % [
			int(heart.get("charge", 0)), int(metrics.get("dream_goal_changes", 0)),
			int(metrics.get("dream_goal_restores", 0)), int(metrics.get("dream_path_rebuilds", 0))
		]]
	return ["석골 심장: 충전 %d/100 · 액티브 %s · 피해 감소 %d · 수리 추가 %d" % [
		int(heart.get("charge", 0)),
		"사용" if bool(heart.get("active_used_this_battle", false)) else "미사용",
		int(metrics.get("stonebone_facility_damage_reduced", 0)) + int(metrics.get("stonebone_monster_damage_reduced", 0)),
		int(metrics.get("stonebone_repair_bonus", 0))
	]]

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
	if _map_editor_selected_locked():
		map_editor_status = "고정 방의 연결은 해제할 수 없습니다."
		_set_screen(Constants.SCREEN_MANAGEMENT)
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
	if bool(placed.get("locked", false)):
		map_editor_status = "고정 통로는 삭제할 수 없습니다."
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
		"bebe_rescue": _load_png("res://assets/sprites/effects/fx_ghost_housemaid_rescue_ring_00.png"),
		"bebe_broom": _load_png("res://assets/sprites/effects/fx_ghost_housemaid_broom_interrupt_00.png"),
		"bebe_glide": _load_png("res://assets/sprites/effects/fx_ghost_housemaid_ghost_glide_00.png"),
		"koko_scent": _load_png("res://assets/sprites/effects/fx_graveyard_hound_scent_lock_00.png"),
		"koko_bark": _load_png("res://assets/sprites/effects/fx_graveyard_hound_grave_bark_00.png"),
		"koko_return": _load_png("res://assets/sprites/effects/fx_graveyard_hound_return_trail_00.png"),
		"toktok_impact": _load_png("res://assets/sprites/effects/fx_armored_beetle_carapace_impact_00.png"),
		"toktok_patch": _load_png("res://assets/sprites/effects/fx_armored_beetle_patch_shield_00.png"),
		"toktok_scrap": _load_png("res://assets/sprites/effects/fx_armored_beetle_scrap_rivets_00.png"),
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
		"bebe_rescue": _load_effect_frames("fx_ghost_housemaid_rescue_ring"),
		"bebe_broom": _load_effect_frames("fx_ghost_housemaid_broom_interrupt"),
		"bebe_glide": _load_effect_frames("fx_ghost_housemaid_ghost_glide"),
		"koko_scent": _load_effect_frames("fx_graveyard_hound_scent_lock"),
		"koko_bark": _load_effect_frames("fx_graveyard_hound_grave_bark"),
		"koko_return": _load_effect_frames("fx_graveyard_hound_return_trail"),
		"toktok_impact": _load_effect_frames("fx_armored_beetle_carapace_impact"),
		"toktok_patch": _load_effect_frames("fx_armored_beetle_patch_shield"),
		"toktok_scrap": _load_effect_frames("fx_armored_beetle_scrap_rivets"),
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
	if OS.has_feature("web"):
		combat_music_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
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
	if screen_name == Constants.SCREEN_MANAGEMENT and _update4_region_selection_pending():
		screen_name = Constants.SCREEN_REGION_SELECTION
	if screen_name == Constants.SCREEN_MANAGEMENT and _update4_outpost_setup_pending():
		screen_name = Constants.SCREEN_OUTPOST_MANAGEMENT
	if screen_name == Constants.SCREEN_MANAGEMENT and _update4_upper_layout_pending():
		screen_name = Constants.SCREEN_UPPER_FLOOR
	var previous_screen = current_screen
	if previous_screen == Constants.SCREEN_COMBAT and screen_name != Constants.SCREEN_COMBAT and _update4_council_mode_active():
		var completed := CouncilSeasonServiceScript.complete_combat(_update4_council_day_state())
		if bool(completed.get("ok", false)):
			_set_update4_council_day_state(completed.get("state", {}))
	if screen_name != Constants.SCREEN_MANAGEMENT:
		facility_change_panel_open = false
		_clear_management_action_mode(false)
	current_screen = screen_name
	_update_world_render_visibility()
	if UISettings.is_touch_ui():
		_tutorial_prepare_touch_selection()
	if current_screen == Constants.SCREEN_MANAGEMENT:
		_tutorial_sync_required_selected_room()
	if current_screen != Constants.SCREEN_COMBAT and update3_heart_loop_player != null:
		update3_heart_loop_player.stop()
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
			_build_update3_heart_combat_hud()
			_build_update3_duo_link_combat_hud()
			_build_update4_multifloor_hud()
		Constants.SCREEN_RESULT:
			management_scene.build_result_ui()
		Constants.SCREEN_ENDING:
			_build_campaign_ending_ui()
		Constants.SCREEN_ENDING_ARCHIVE:
			_build_ending_archive_ui()
		Constants.SCREEN_MEMORY_ARCHIVE:
			management_scene.build_memory_archive_ui()
		Constants.SCREEN_CONTRACT_BOARD:
			_build_contract_board_ui()
		Constants.SCREEN_CAMPAIGN_MODE:
			_build_campaign_mode_selection_ui()
		Constants.SCREEN_REGION_SELECTION:
			_build_region_selection_ui()
		Constants.SCREEN_OUTPOST_MANAGEMENT:
			_build_outpost_management_ui()
		Constants.SCREEN_OUTPOST_BATTLE:
			_build_outpost_battle_ui()
		Constants.SCREEN_UPPER_FLOOR:
			_build_upper_floor_ui()
		Constants.SCREEN_FRONT_SELECTION:
			_build_front_selection_ui()
		Constants.SCREEN_HEART_SELECTION:
			_build_heart_selection_ui()
		Constants.SCREEN_DUO_LINK_LOADOUT:
			_build_duo_link_loadout_ui()
		Constants.SCREEN_CHRONICLE:
			_build_chronicle_ui()
		Constants.SCREEN_CYCLE_DOCTRINE:
			_build_cycle_doctrine_ui()
		Constants.SCREEN_CYCLE_DECREE:
			_build_cycle_decree_ui()
		Constants.SCREEN_CHALLENGE_SEAL:
			_build_challenge_seal_ui()
		Constants.SCREEN_RAID_PREVIEW:
			_build_onboarding_raid_preview_ui()
		Constants.SCREEN_RAID:
			_build_raid_ui()
		Constants.SCREEN_SETTINGS:
			_build_settings_ui()
	if current_screen == Constants.SCREEN_MANAGEMENT:
		_build_update4_required_choice_overlay()
		_show_update3_event_choice_overlay()
	_tutorial_build_overlay()
	_maybe_show_combat_speed_intro()
	if campaign_save_notice != "" and current_screen != Constants.SCREEN_TITLE:
		_show_campaign_save_notice_overlay()
	_schedule_campaign_autosave(current_screen)
	queue_redraw()

func _update_world_render_visibility() -> void:
	var is_visible := _screen_uses_world_render(current_screen)
	if unit_root != null:
		unit_root.visible = is_visible
	if effect_root != null:
		effect_root.visible = is_visible
	if quarter_renderer != null and quarter_renderer.has_method("set_world_layers_visible"):
		quarter_renderer.set_world_layers_visible(is_visible)

func _update_combat_music(_previous_screen: String, next_screen: String) -> void:
	if combat_music_player == null:
		return
	var next_music := _music_for_screen(next_screen)
	if next_music == null:
		_stop_combat_music()
		return
	_start_combat_music(next_music)

func _music_for_screen(screen_name: String) -> AudioStream:
	if screen_name in [Constants.SCREEN_COMBAT, Constants.SCREEN_OUTPOST_BATTLE, Constants.SCREEN_RAID]:
		return COMBAT_BOSS_MUSIC if _combat_music_has_boss() else COMBAT_MUSIC
	if screen_name in MANAGEMENT_MUSIC_SCREENS:
		return MANAGEMENT_MUSIC
	return null

func _combat_music_has_boss() -> bool:
	for enemy in enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive():
			continue
		if _update3_enemy_is_boss(enemy):
			return true
		var definition: Dictionary = DataRegistry.enemy(str(enemy.unit_id))
		if bool(definition.get("boss", false)) or definition.get("role_tags", []).has("boss"):
			return true
	return false

func _refresh_combat_music_variant() -> void:
	if current_screen not in [Constants.SCREEN_COMBAT, Constants.SCREEN_OUTPOST_BATTLE, Constants.SCREEN_RAID]:
		return
	var desired := _music_for_screen(current_screen)
	if desired != null and combat_music_player != null and combat_music_player.stream != desired:
		_start_combat_music(desired)

func _start_combat_music(stream: AudioStream = null) -> void:
	_kill_combat_music_tween()
	combat_music_active = true
	if stream != null and combat_music_player.stream != stream:
		combat_music_player.stop()
		combat_music_player.stream = stream
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
		Constants.SCREEN_CONTRACT_BOARD,
		Constants.SCREEN_CAMPAIGN_MODE,
		Constants.SCREEN_FRONT_SELECTION,
		Constants.SCREEN_HEART_SELECTION,
		Constants.SCREEN_DUO_LINK_LOADOUT,
		Constants.SCREEN_CHRONICLE,
		Constants.SCREEN_CYCLE_DOCTRINE,
		Constants.SCREEN_CYCLE_DECREE,
		Constants.SCREEN_CHALLENGE_SEAL
	]

func _build_onboarding_title_ui() -> void:
	_refresh_campaign_save_status()
	var touch_ui := UISettings.is_touch_ui()
	var screen = _onboarding_screen_panel(Color("#050407ff"))
	_onboarding_add_scene_illustration(screen, Rect2(0, 0, 1920, 1080), ONBOARDING_START_SCENE)
	var logo_rect := Rect2(280, 50, 1360, 190) if touch_ui else _onboarding_rect("S00_TITLE", "Logo", Rect2(360, 120, 1200, 220))
	hud.label(screen, "마왕님, 마왕성은 누가 지켜요?", logo_rect.position, logo_rect.size, 60 if touch_ui else 54, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.label(screen, "F급 신입 마왕성 방어 튜토리얼", Vector2(460, 245) if touch_ui else Vector2(560, 330), Vector2(1000, 52) if touch_ui else Vector2(800, 44), 30 if touch_ui else 24, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
	var new_game_label := "새 회차" if _title_campaign_mode_available() else "새 게임"
	var new_game_callback := Callable(self, "_open_campaign_mode_from_title") if _title_campaign_mode_available() else Callable(self, "_onboarding_start_new_game")
	var new_game_rect := Rect2(680, 320, 560, 128) if touch_ui else _onboarding_rect("S00_TITLE", "Menu_NewGame", Rect2(760, 460, 400, 72))
	var continue_rect := Rect2(680, 468, 560, 128) if touch_ui else _onboarding_rect("S00_TITLE", "Menu_Continue", Rect2(760, 548, 400, 72))
	hud.button(screen, new_game_label, new_game_rect, new_game_callback, 30 if touch_ui else 22, "CampaignNewGameButton")
	var continue_button = hud.button(screen, "이어하기", continue_rect, Callable(self, "_continue_campaign_save"), 30 if touch_ui else 22, "CampaignContinueButton")
	continue_button.disabled = campaign_save_status != CampaignSaveStoreScript.STATUS_VALID or campaign_save_notice != ""
	hud.button(screen, "빠른 시작", Rect2(680, 616, 560, 128) if touch_ui else Rect2(760, 636, 400, 64), Callable(self, "_onboarding_start_quick_game"), 29 if touch_ui else 21, "CampaignQuickStartButton")
	hud.button(screen, "설정", Rect2(680, 764, 270, 112) if touch_ui else Rect2(760, 712, 190, 64), Callable(self, "_open_settings_screen"), 27 if touch_ui else 21)
	hud.button(screen, "엔딩 도감", Rect2(970, 764, 270, 112) if touch_ui else Rect2(970, 712, 190, 64), Callable(self, "_open_ending_archive"), 25 if touch_ui else 19, "EndingArchiveButton")
	if not touch_ui:
		hud.button(screen, "종료", Rect2(760, 788, 400, 64), Callable(self, "_onboarding_quit_requested"), 21)
	var save_status_text := _campaign_title_save_status_text()
	var save_status_color := Color("#c9bdd2")
	if campaign_save_notice != "":
		save_status_color = Color("#ff9b8f")
	elif campaign_save_status == CampaignSaveStoreScript.STATUS_VALID:
		save_status_color = Color("#ffd36a")
	elif campaign_save_status in [CampaignSaveStoreScript.STATUS_CORRUPT, CampaignSaveStoreScript.STATUS_UNSUPPORTED]:
		save_status_color = Color("#ff9b8f")
	hud.label(screen, save_status_text, Vector2(480, 895) if touch_ui else Vector2(560, 870), Vector2(960, 100) if touch_ui else Vector2(800, 112), 21 if touch_ui else 17, save_status_color, HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 3)
	hud.label(screen, "버전 1.2", _onboarding_rect("S00_TITLE", "VersionLabel", Rect2(32, 1020, 400, 32)).position, _onboarding_rect("S00_TITLE", "VersionLabel", Rect2(32, 1020, 400, 32)).size, 15, Color("#8d8398"))
	if pending_title_reset_mode != "":
		_build_title_reset_confirmation()


func _title_campaign_mode_available() -> bool:
	if campaign_save_status != CampaignSaveStoreScript.STATUS_VALID or campaign_save_v5_envelope.is_empty():
		return false
	var active_run: Dictionary = campaign_save_v5_envelope.get("active_run", {})
	if str(active_run.get("campaign_mode_id", "")) == SaveV4ToV5MigratorScript.MODE_NONE:
		return true
	var campaign: Dictionary = active_run.get("legacy_payload", {}).get("campaign", {})
	return bool(campaign.get("completed", false)) and str(campaign.get("final_battle_outcome", "")) == "victory"


func _open_campaign_mode_from_title() -> void:
	var mode_id := str(campaign_save_v5_envelope.get("active_run", {}).get("campaign_mode_id", ""))
	_continue_campaign_save()
	if mode_id == SaveV4ToV5MigratorScript.MODE_NONE:
		_set_screen(Constants.SCREEN_CAMPAIGN_MODE)
	elif campaign_completed and campaign_final_battle_outcome == "victory":
		_campaign_next_cycle_from_ending()

func _build_title_reset_confirmation() -> void:
	var is_quick := pending_title_reset_mode == "quick"
	var backdrop = hud.panel(Rect2(0, 0, 1920, 1080), Color("#000000b8"), Color("#00000000"), "TitleResetConfirmation", "flat")
	backdrop.name = "TitleResetConfirmation"
	backdrop.z_index = 500
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	var modal = hud.child_panel(backdrop, Rect2(590, 340, 740, 400), Color("#0b0910fa"), Color("#d8b867"), 2)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.label(modal, "저장 기록을 삭제할까요?", Vector2(36, 34), Vector2(668, 48), 30, Color("#fff4dc"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	var summary_text := "DAY %02d · %s\n%s의 진행 기록은 삭제 후 복구할 수 없습니다." % [
		int(campaign_save_summary.get("day", 1)),
		str(campaign_save_summary.get("castle_name", "마왕성")),
		str(campaign_save_summary.get("player_name", "신입 마왕"))
	]
	hud.label(modal, summary_text, Vector2(54, 112), Vector2(632, 104), 20, Color("#d8cfdf"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 3)
	var confirm_text := "삭제하고 빠른 시작" if is_quick else "삭제하고 새 게임"
	var confirm_callback := Callable(self, "_onboarding_start_quick_game") if is_quick else Callable(self, "_onboarding_start_new_game")
	hud.button(modal, confirm_text, Rect2(54, 258, 300, 72), confirm_callback, 20, "TitleResetConfirmButton")
	hud.button(modal, "취소", Rect2(386, 258, 300, 72), Callable(self, "_cancel_title_reset_confirmation"), 20, "TitleResetCancelButton")

func _title_reset_confirmation_required(mode: String) -> bool:
	if pending_title_reset_mode == mode:
		pending_title_reset_mode = ""
		return false
	if campaign_save_status != CampaignSaveStoreScript.STATUS_VALID:
		return false
	pending_title_reset_mode = mode
	_set_screen(Constants.SCREEN_TITLE)
	return true

func _cancel_title_reset_confirmation() -> void:
	pending_title_reset_mode = ""
	_set_screen(Constants.SCREEN_TITLE)

func _campaign_title_save_status_text() -> String:
	if campaign_save_notice != "":
		return campaign_save_notice
	match campaign_save_status:
		CampaignSaveStoreScript.STATUS_VALID:
			return "DAY %02d / %02d · 마왕성 %d/4 %s · %s\n%d회차 · 발견 엔딩 %d/%d · %s · 자동 저장" % [
				int(campaign_save_summary.get("day", 1)),
				REGULAR_CAMPAIGN_FINAL_DAY,
				int(campaign_save_summary.get("castle_stage_index", 1)),
				str(campaign_save_summary.get("castle_name", "마왕성")),
				str(campaign_save_summary.get("player_name", "신입 마왕")),
				int(campaign_save_summary.get("cycle_index", 1)),
				int(campaign_save_summary.get("ending_archive_count", 0)),
				_ending_catalog_ids().size(),
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

func _open_chronicle() -> void:
	_set_screen(Constants.SCREEN_CHRONICLE)

func _build_chronicle_ui() -> void:
	var screen = ChronicleScreenScene.instantiate()
	screen.name = "ChronicleScreen"
	screen.setup(update3_profile, {
		"fronts": DataRegistry.update3_fronts,
		"castle_hearts": DataRegistry.update3_castle_hearts,
		"duo_links": DataRegistry.update3_duo_links
	}, DataRegistry.update3_chronicle_goals, update4_profile, {
		"regions": DataRegistry.update4_regions,
		"rival_lords": DataRegistry.update4_rival_lords,
		"rival_letters": DataRegistry.update4_rival_letters,
		"crown_evolutions": DataRegistry.update4_crown_evolutions,
		"council_endings": DataRegistry.update4_council_endings
	})
	screen.accessibility_changed.connect(_set_update4_accessibility)
	screen.canceled.connect(_set_screen.bind(Constants.SCREEN_MANAGEMENT))
	ui_layer.add_child(screen)


func _set_update4_accessibility(settings: Dictionary) -> void:
	var state := CouncilChronicleScript.normalize_state(update4_profile.get("chronicle_update4", {}))
	state["accessibility"] = CouncilChronicleScript.normalize_accessibility(settings)
	update4_profile["chronicle_update4"] = state
	_write_campaign_v2_snapshot()

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
	if campaign_completed and campaign_final_battle_outcome == "victory" and resolved_campaign_ending_id != "" and resolved_campaign_ending_id != CouncilEndingServiceScript.LOCAL_FALLBACK_ID:
		if not archive.has(resolved_campaign_ending_id):
			archive[resolved_campaign_ending_id] = {"first_seen_cycle": campaign_cycle_index, "seen_count": 1, "last_seen_cycle": campaign_cycle_index}
	return archive

func _build_ending_archive_ui() -> void:
	var screen := _onboarding_screen_panel(Color("#050407ff"))
	_onboarding_add_scene_illustration(screen, Rect2(0, 0, 1920, 1080), ONBOARDING_START_SCENE)
	var shade := _onboarding_child_panel(screen, Rect2(90, 56, 1740, 944), Color("#08060cdf"), Color("#9b6a27"))
	var archive := _ending_archive_snapshot()
	hud.label(shade, "엔딩 도감", Vector2(0, 26), Vector2(1740, 54), 38, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	var ending_ids := _ending_catalog_ids()
	hud.label(shade, "발견 %d/%d · 한 번 확인한 결말은 다음 회차에도 남습니다." % [archive.size(), ending_ids.size()], Vector2(0, 80), Vector2(1740, 34), 17, Color("#c6a968"), HORIZONTAL_ALIGNMENT_CENTER)
	for index in range(ending_ids.size()):
		var ending_id: String = ending_ids[index]
		var rule := DataRegistry.ending_rule(ending_id)
		var discovered := archive.has(ending_id)
		var card_position := Vector2(52 + float(index % 4) * 415.0, 132 + float(floori(float(index) / 4.0)) * 232.0)
		var card: Panel = hud.child_panel(shade, Rect2(card_position, Vector2(390, 214)), Color("#100d14f2"), Color("#9b6a27") if discovered else Color("#403846"), 2 if discovered else 1)
		if discovered:
			var thumbnail: TextureRect = hud.texture(card, str(rule.get("thumbnail", "")), Rect2(14, 14, 162, 92))
			thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			var emblem: TextureRect = hud.texture(card, str(rule.get("emblem", "")), Rect2(18, 124, 54, 54))
			emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hud.label(card, "%s · %s" % [str(rule.get("catalog_code", "")), str(rule.get("display_name", ending_id))], Vector2(188, 20), Vector2(184, 72), 17, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART)
			var entry: Dictionary = archive.get(ending_id, {})
			hud.label(card, "발견 %d회\n최초 %d회차" % [int(entry.get("seen_count", 1)), int(entry.get("first_seen_cycle", 1))], Vector2(88, 126), Vector2(284, 56), 14, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_LEFT)
		else:
			hud.label(card, str(rule.get("catalog_code", "?")), Vector2(0, 36), Vector2(390, 70), 40, Color("#574f60"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
			hud.label(card, "아직 발견하지 못한 결말", Vector2(24, 128), Vector2(342, 42), 16, Color("#7d7586"), HORIZONTAL_ALIGNMENT_CENTER)
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
	onboarding_name_random_button = null
	onboarding_name_confirm_button = null
	onboarding_name_tip_overlay = null
	onboarding_bati_comment_label = null
	var touch_ui := UISettings.is_touch_ui()
	var screen = _onboarding_screen_panel(Color("#050407ff"))
	_onboarding_add_scene_illustration(screen, Rect2(0, 0, 1920, 1080), ONBOARDING_START_SCENE)
	var panel_fallback := Rect2(330, 90, 1260, 900) if touch_ui else Rect2(560, 210, 800, 610)
	var panel_rect = panel_fallback if touch_ui else _onboarding_rect("S01_NAME_ENTRY", "Panel_NameForm", panel_fallback)
	var panel = _onboarding_child_panel(screen, panel_rect, Color("#100d14f2"), Color("#9b6a27"))
	var title_fallback := Rect2(430, 130, 1060, 80) if touch_ui else Rect2(620, 260, 680, 60)
	var title_rect = title_fallback if touch_ui else _onboarding_rect("S01_NAME_ENTRY", "Title", title_fallback)
	var title_back = Panel.new()
	title_back.position = title_rect.position - panel_rect.position + Vector2(78, 4)
	title_back.size = Vector2(title_rect.size.x - 156, title_rect.size.y - 6)
	title_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_back.add_theme_stylebox_override("panel", hud.style(Color("#050407d8"), Color("#ffd36a88"), 1))
	panel.add_child(title_back)
	var title_label = hud.label(panel, "F급 신입 마왕 등록", title_rect.position - panel_rect.position, title_rect.size, 40 if touch_ui else 34, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	title_label.add_theme_constant_override("outline_size", 5)
	title_label.add_theme_color_override("font_outline_color", Color("#050407"))
	var name_prompt := "입력창을 누를 때만 키보드가 열립니다" if touch_ui else "당신의 이름은 무엇입니까?"
	hud.label(panel, name_prompt, Vector2(120, 150) if touch_ui else Vector2(80, 130), Vector2(1020, 44) if touch_ui else Vector2(640, 34), 25 if touch_ui else 20, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)

	var input_fallback := Rect2(520, 360, 880, 128) if touch_ui else Rect2(700, 420, 520, 64)
	var input_rect = input_fallback if touch_ui else _onboarding_rect("S01_NAME_ENTRY", "NameInput", input_fallback)
	onboarding_name_input = LineEdit.new()
	onboarding_name_input.position = input_rect.position - panel_rect.position
	onboarding_name_input.size = input_rect.size
	onboarding_name_input.placeholder_text = "마왕명을 입력하세요"
	onboarding_name_input.max_length = 0
	onboarding_name_input.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_EMPHASIS))
	onboarding_name_input.add_theme_font_size_override("font_size", 34 if touch_ui else 24)
	onboarding_name_input.add_theme_color_override("font_color", Color("#f7efe1"))
	onboarding_name_input.add_theme_color_override("font_placeholder_color", Color("#a79dad"))
	onboarding_name_input.add_theme_stylebox_override("normal", hud.style(Color("#0c0910f2"), Color("#ffd36a"), 2))
	onboarding_name_input.add_theme_stylebox_override("focus", hud.style(Color("#120d18f8"), Color("#ffe38a"), 2))
	onboarding_name_input.text_submitted.connect(_onboarding_name_submitted)
	panel.add_child(onboarding_name_input)
	register_tutorial_target("NameInput", input_rect)
	onboarding_name_input.visible = onboarding_name_entry_tip_dismissed
	onboarding_name_input.editable = onboarding_name_entry_tip_dismissed
	if onboarding_name_entry_tip_dismissed and not touch_ui:
		onboarding_name_input.call_deferred("grab_focus")

	var random_fallback := Rect2(520, 520, 420, 128) if touch_ui else Rect2(700, 500, 250, 56)
	var confirm_fallback := Rect2(980, 520, 420, 128) if touch_ui else Rect2(970, 500, 250, 56)
	var random_rect = random_fallback if touch_ui else _onboarding_rect("S01_NAME_ENTRY", "RandomNameButton", random_fallback)
	var confirm_rect = confirm_fallback if touch_ui else _onboarding_rect("S01_NAME_ENTRY", "ConfirmButton", confirm_fallback)
	onboarding_name_random_button = hud.button(panel, "무작위 이름", _onboarding_relative_rect(random_rect, panel_rect), Callable(self, "_onboarding_random_name"), 27 if touch_ui else 19)
	onboarding_name_confirm_button = hud.button(panel, "이 이름으로 시작", _onboarding_relative_rect(confirm_rect, panel_rect), Callable(self, "_onboarding_confirm_name"), 27 if touch_ui else 19)
	onboarding_name_random_button.visible = onboarding_name_entry_tip_dismissed
	onboarding_name_confirm_button.visible = onboarding_name_entry_tip_dismissed
	onboarding_name_random_button.disabled = not onboarding_name_entry_tip_dismissed
	onboarding_name_confirm_button.disabled = not onboarding_name_entry_tip_dismissed

	var note_panel = Panel.new()
	note_panel.position = Vector2(120, 650) if touch_ui else Vector2(56, 386)
	note_panel.size = Vector2(1020, 150) if touch_ui else Vector2(688, 116)
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
	hud.label(note_panel, "바티", Vector2(122, 14), Vector2(850, 28) if touch_ui else Vector2(520, 22), 20 if touch_ui else 15, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	onboarding_bati_comment_label = hud.label(note_panel, _onboarding_name_screen_comment(), Vector2(122, 48) if touch_ui else Vector2(122, 42), Vector2(850, 82) if touch_ui else Vector2(528, 58), 22 if touch_ui else 17, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_ARBITRARY, 3)
	if not onboarding_name_entry_tip_dismissed:
		_onboarding_add_name_entry_tip(panel, panel_rect, input_rect)

func _onboarding_add_name_entry_tip(parent: Control, panel_rect: Rect2, input_rect: Rect2) -> void:
	var touch_ui := UISettings.is_touch_ui()
	var card_rect = Rect2(input_rect.position - panel_rect.position - Vector2(12, 20), input_rect.size + (Vector2(24, 250) if touch_ui else Vector2(24, 142)))
	onboarding_name_tip_overlay = Control.new()
	onboarding_name_tip_overlay.position = Vector2.ZERO
	onboarding_name_tip_overlay.size = parent.size
	onboarding_name_tip_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(onboarding_name_tip_overlay)
	var shadow = Panel.new()
	shadow.position = card_rect.position + Vector2(8, 10)
	shadow.size = card_rect.size
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.add_theme_stylebox_override("panel", hud.style(Color("#00000099"), Color("#00000000"), 0))
	onboarding_name_tip_overlay.add_child(shadow)
	var card = Panel.new()
	card.position = card_rect.position
	card.size = card_rect.size
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", hud.style(Color("#100d14fb"), Color("#ffd36a"), 3))
	card.gui_input.connect(_onboarding_name_tip_gui_input)
	onboarding_name_tip_overlay.add_child(card)
	hud.label(card, "먼저 안내를 확인하세요", Vector2(32, 24) if touch_ui else Vector2(24, 18), Vector2(card_rect.size.x - 64, 38) if touch_ui else Vector2(card_rect.size.x - 48, 26), 27 if touch_ui else 19, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var guide_text := "키보드는 자동으로 열리지 않습니다.\n입력창을 직접 누르거나 [무작위 이름]을 선택하세요." if touch_ui else "마왕명은 이후 모든 대사와 결과 화면에 표시됩니다.\n확인하면 입력창이 열립니다."
	hud.label(card, guide_text, Vector2(32, 78) if touch_ui else Vector2(24, 56), Vector2(card_rect.size.x - 64, 90) if touch_ui else Vector2(card_rect.size.x - 48, 58), 25 if touch_ui else 20, Color("#fff7e6"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_ARBITRARY, 3)
	var tip_button_rect := Rect2(card_rect.size.x * 0.5 - 230, card_rect.size.y - 150, 460, 128) if touch_ui else Rect2(card_rect.size.x * 0.5 - 150, card_rect.size.y - 64, 300, 46)
	hud.button(card, "확인하고 이름 선택", tip_button_rect, Callable(self, "_onboarding_dismiss_name_entry_tip"), 25 if touch_ui else 18)

func _onboarding_name_tip_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_onboarding_dismiss_name_entry_tip()

func _onboarding_dismiss_name_entry_tip() -> void:
	if onboarding_name_entry_tip_dismissed:
		return
	onboarding_name_entry_tip_dismissed = true
	if onboarding_name_tip_overlay != null and is_instance_valid(onboarding_name_tip_overlay):
		onboarding_name_tip_overlay.visible = false
		onboarding_name_tip_overlay.queue_free()
	onboarding_name_tip_overlay = null
	if onboarding_name_input != null and is_instance_valid(onboarding_name_input):
		onboarding_name_input.visible = true
		onboarding_name_input.editable = true
	if onboarding_name_random_button != null and is_instance_valid(onboarding_name_random_button):
		onboarding_name_random_button.visible = true
		onboarding_name_random_button.disabled = false
	if onboarding_name_confirm_button != null and is_instance_valid(onboarding_name_confirm_button):
		onboarding_name_confirm_button.visible = true
		onboarding_name_confirm_button.disabled = false
	if not UISettings.is_touch_ui():
		call_deferred("_focus_onboarding_name_input")

func _focus_onboarding_name_input() -> void:
	if current_screen != Constants.SCREEN_NAME_ENTRY:
		return
	if onboarding_name_input != null and is_instance_valid(onboarding_name_input) and onboarding_name_input.visible and onboarding_name_input.editable:
		onboarding_name_input.grab_focus()

func _build_onboarding_dialogue_ui() -> void:
	var touch_ui := UISettings.is_touch_ui()
	var screen = _onboarding_screen_panel(Color("#050407d8"))
	if onboarding_dialogue_queue.is_empty():
		_onboarding_add_scene_illustration(screen, _onboarding_rect("S02_DIALOGUE", "SceneIllustration", Rect2(0, 0, 1920, 1080)), _onboarding_dialogue_scene_path({}))
		hud.label(screen, "튜토리얼", Vector2(72, 50), Vector2(360, 42), 24, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
		hud.rich_label(screen, "표시할 대사가 없습니다.", Vector2(560, 766), Vector2(1040, 150), 24, Color("#f7efe1"), UIFontScript.ROLE_DIALOGUE, TextServer.AUTOWRAP_ARBITRARY, VERTICAL_ALIGNMENT_CENTER)
		hud.button(screen, "닫기", Rect2(1430, 850, 360, 128) if touch_ui else Rect2(1600, 920, 190, 48), Callable(self, "_onboarding_advance_dialogue"), 28 if touch_ui else 18)
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
	var text_rect = Rect2(392, 756, 1040, 180) if touch_ui else Rect2(392, 756, 1220, 134)
	var dialogue_label = hud.rich_label(screen, _onboarding_line_text(line), text_rect.position, text_rect.size, 24, Color("#f7efe1"), UIFontScript.ROLE_DIALOGUE, TextServer.AUTOWRAP_WORD_SMART, VERTICAL_ALIGNMENT_CENTER, "", 16)
	dialogue_label.add_theme_constant_override("line_separation", 4)
	var next_button_rect = Rect2(1460, 820, 328, 144) if touch_ui else Rect2(1542, 908, 246, 56)
	hud.label(screen, "%d / %d" % [onboarding_dialogue_index + 1, onboarding_dialogue_queue.size()], Vector2(1300, 934) if touch_ui else Vector2(1402, 920), Vector2(136, 28) if touch_ui else Vector2(116, 28), 20 if touch_ui else 16, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_RIGHT, "", UIFontScript.ROLE_BODY)
	var next_label := str(line.get("next_label", "다음"))
	hud.button(screen, next_label, next_button_rect, Callable(self, "_onboarding_advance_dialogue"), 30 if touch_ui else 21)
	if (campaign_cycle_index >= 2 or bool(update4_profile.get("chronicle_update4", {}).get("accessibility", {}).get("quick_dialogue", false))) and onboarding_dialogue_queue.size() > 1:
		hud.button(screen, "빠른 대사 건너뛰기", Rect2(1110, 820, 320, 144) if touch_ui else Rect2(1184, 908, 200, 56), Callable(self, "_onboarding_skip_dialogue"), 22 if touch_ui else 16)

func _update3_front_profile_context() -> Dictionary:
	var result := update3_profile.duplicate(true)
	result["ending_catalog_codes"] = campaign_profile.get("ending_catalog_codes", {}).duplicate(true)
	result["doctrine_history"] = campaign_profile.get("doctrine_history", []).duplicate(true)
	result["defeated_doctrine_ids"] = campaign_profile.get("defeated_doctrine_ids", []).duplicate(true)
	return result


func _build_campaign_mode_selection_ui() -> void:
	update4_profile = CampaignModeServiceScript.normalize_profile(update4_profile, _update3_front_profile_context())
	var screen = CampaignModeSelectionScreenScene.instantiate()
	screen.name = "CampaignModeSelectionScreen"
	ui_layer.add_child(screen)
	screen.setup(update4_profile, DataRegistry.update4_campaign_modes, campaign_cycle_index, true)
	screen.mode_selected.connect(_select_campaign_mode)
	screen.canceled.connect(_cancel_campaign_mode_selection)


func _select_campaign_mode(mode_id: String) -> void:
	var result := CampaignModeServiceScript.select_mode(update4_profile, update4_active_run, mode_id, DataRegistry.update4_campaign_modes)
	if not bool(result.get("ok", false)):
		campaign_save_notice = str(result.get("error", "회차 모드를 선택하지 못했습니다."))
		_show_campaign_save_notice_overlay()
		return
	update4_profile = result.get("profile", update4_profile).duplicate(true)
	update4_active_run = result.get("active_run", update4_active_run).duplicate(true)
	GameState.day = CampaignModeServiceScript.start_day(mode_id, DataRegistry.update4_campaign_modes)
	if mode_id == CampaignModeServiceScript.FRONT_MODE_ID:
		_log("%d회차 모드 확정: 전선 연대기. 기존 전선 선택 흐름을 이어갑니다." % campaign_cycle_index)
		_set_screen(Constants.SCREEN_FRONT_SELECTION)
	else:
		_ensure_update4_council_roster()
		_onboarding_set_stage("COUNCIL_CYCLE_%d_DAY_01" % campaign_cycle_index)
		_log("%d회차 모드 확정: 마왕 의회. 실키·포포를 포함한 5인 의회 편성으로 DAY 1을 시작합니다." % campaign_cycle_index)
		_set_screen(Constants.SCREEN_MANAGEMENT)
	if not _write_campaign_v2_snapshot():
		campaign_save_notice = "회차 모드는 선택했지만 v5 저장에 실패했습니다."
		_show_campaign_save_notice_overlay()


func _cancel_campaign_mode_selection() -> void:
	_set_screen(Constants.SCREEN_TITLE)


func _build_region_selection_ui() -> void:
	var screen = RegionSelectionScreenScene.instantiate()
	screen.name = "RegionSelectionScreen"
	ui_layer.add_child(screen)
	screen.setup(update4_active_run, DataRegistry.update4_regions, GameState.day, true, update4_profile.get("chronicle_update4", {}).get("accessibility", {}), update4_profile.get("regions", {}).get("mastery_by_region", {}))
	screen.region_selected.connect(_select_update4_region)
	screen.canceled.connect(_cancel_update4_region_selection)


func _select_update4_region(region_id: String) -> void:
	var result := RegionRouteServiceScript.select_region(update4_profile, update4_active_run, region_id, GameState.day, DataRegistry.update4_regions)
	if not bool(result.get("ok", false)):
		campaign_save_notice = str(result.get("error", "지역을 선택하지 못했습니다."))
		_show_campaign_save_notice_overlay()
		return
	update4_profile = result.get("profile", update4_profile).duplicate(true)
	update4_active_run = result.get("active_run", update4_active_run).duplicate(true)
	var selected := RegionRouteServiceScript.selected_region_ids(update4_active_run)
	var region: Dictionary = DataRegistry.update4_regions.get(region_id, {})
	var rival_id := str(region.get("rival_id", ""))
	if rival_id != "":
		var relation_result := RivalLordServiceScript.change_relation(update4_active_run, rival_id, 10, DataRegistry.update4_rival_lords)
		update4_active_run = relation_result.get("active_run", update4_active_run).duplicate(true)
	for secondary_id_value in region.get("secondary_rival_ids", []):
		var secondary_result := RivalLordServiceScript.change_relation(update4_active_run, str(secondary_id_value), 5, DataRegistry.update4_rival_lords)
		update4_active_run = secondary_result.get("active_run", update4_active_run).duplicate(true)
	_apply_update4_region_event(region_id, selected.size())
	_log("의회 지역 %d번째 선택: %s" % [selected.size(), str(DataRegistry.update4_regions.get(region_id, {}).get("display_name", region_id))])
	_set_screen(Constants.SCREEN_MANAGEMENT)
	if not _write_campaign_v2_snapshot():
		campaign_save_notice = "지역 선택은 반영했지만 v5 저장에 실패했습니다."
		_show_campaign_save_notice_overlay()


func _cancel_update4_region_selection() -> void:
	_set_screen(Constants.SCREEN_TITLE)


func _ensure_update4_council_roster() -> void:
	for instance_id in ["MON_SILKY", "MON_POPO"]:
		var instance: Dictionary = DataRegistry.monster_instances.get(instance_id, {})
		var species_id := str(instance.get("species_id", ""))
		if species_id == "" or monster_roster.has(species_id):
			continue
		var definition: Dictionary = DataRegistry.monster(species_id)
		var room_id := str(definition.get("recommended_room", "barracks"))
		if not rooms.has(room_id):
			room_id = "barracks" if rooms.has("barracks") else "entrance"
		monster_roster[species_id] = {
			"level": int(instance.get("level", 1)),
			"exp": int(instance.get("exp", 0)),
			"bond": int(instance.get("bond", 0)),
			"bond_rank": int(instance.get("bond_rank", 0)),
			"unlocked_memory_ids": instance.get("unlocked_memory_ids", []).duplicate(),
			"specialization_id": str(instance.get("specialization_id", "")),
			"evolution_id": str(instance.get("evolution_id", "")),
			"room": room_id
		}
	deployed_instance_ids.clear()
	for species_id in ["slime", "goblin", "imp", "spider_tailor", "bat_courier"]:
		if not monster_roster.has(species_id):
			continue
		var instance_id := ContractRosterServiceScript.instance_id_for_species(species_id, DataRegistry.monster_instances)
		if instance_id != "":
			deployed_instance_ids.append(instance_id)
	_sync_contract_reserves()


func _apply_update4_region_event(region_id: String, chapter_slot: int) -> void:
	var event := RegionContentServiceScript.event_for_chapter(DataRegistry.update4_regions.get(region_id, {}), DataRegistry.update4_region_events, chapter_slot)
	if event.is_empty():
		return
	var council: Dictionary = update4_active_run.get("council_season", {}).duplicate(true)
	var resolved_ids: Array = council.get("resolved_region_event_ids", []).duplicate()
	var event_id := str(event.get("id", ""))
	if event_id == "" or resolved_ids.has(event_id):
		return
	var result: Dictionary = event.get("result", {})
	if result.has("gold"):
		GameState.gold = maxi(0, GameState.gold + int(result.get("gold", 0)))
	if result.has("council_votes"):
		council["council_votes"] = clampi(int(council.get("council_votes", 0)) + int(result.get("council_votes", 0)), 0, 100)
	if result.has("outpost_hp"):
		council["pending_outpost_hp_bonus"] = int(council.get("pending_outpost_hp_bonus", 0)) + int(result.get("outpost_hp", 0))
	update4_active_run["council_season"] = council
	for rival_id_value in result.get("rival_relation", {}).keys():
		var relation_result := RivalLordServiceScript.change_relation(update4_active_run, str(rival_id_value), int(result.get("rival_relation", {}).get(rival_id_value, 0)), DataRegistry.update4_rival_lords)
		update4_active_run = relation_result.get("active_run", update4_active_run).duplicate(true)
	for bond_id_value in result.get("bond", {}).keys():
		var species_id := str({"popo": "bat_courier", "silky": "spider_tailor", "dodoom": "war_drummer"}.get(str(bond_id_value), str(bond_id_value)))
		if monster_roster.has(species_id):
			_grant_monster_bond(species_id, int(result.get("bond", {}).get(bond_id_value, 0)))
	council = update4_active_run.get("council_season", council).duplicate(true)
	resolved_ids.append(event_id)
	council["resolved_region_event_ids"] = resolved_ids
	update4_active_run["council_season"] = council
	SignalBus.resources_changed.emit()
	_log("지역 사건 · %s: %s → %s" % [str(event.get("display_name", event_id)), str(event.get("prompt", "")), str(event.get("choice", {}).get("label", "처리"))])


func _build_outpost_management_ui() -> void:
	var screen = OutpostManagementScreenScene.instantiate()
	screen.name = "OutpostManagementScreen"
	ui_layer.add_child(screen)
	var owned_ids := ContractRosterServiceScript.owned_instance_ids(monster_roster, DataRegistry.monster_instances)
	var wave_preview := OutpostServiceScript.preview_next_home_wave(update4_active_run, DataRegistry.waves, GameState.day)
	screen.setup(update4_active_run, DataRegistry.update4_outpost_types, owned_ids, DataRegistry.monster_instances, GameState.day, wave_preview)
	screen.outpost_selected.connect(_select_update4_outpost)
	screen.assignment_changed.connect(_set_update4_outpost_assignment)
	screen.upgrade_requested.connect(_upgrade_update4_outpost)
	screen.closed.connect(_close_update4_outpost_management)


func _select_update4_outpost(type_id: String) -> void:
	var result := OutpostServiceScript.build(update4_profile, update4_active_run, type_id, GameState.day, DataRegistry.update4_outpost_types)
	if not bool(result.get("ok", false)):
		campaign_save_notice = str(result.get("error", "전초기지를 건설하지 못했습니다."))
		_show_campaign_save_notice_overlay()
		return
	update4_profile = result.get("profile", update4_profile).duplicate(true)
	update4_active_run = result.get("active_run", update4_active_run).duplicate(true)
	var council: Dictionary = update4_active_run.get("council_season", {}).duplicate(true)
	var pending_hp_bonus := int(council.get("pending_outpost_hp_bonus", 0))
	if pending_hp_bonus > 0:
		var outpost: Dictionary = update4_active_run.get("outpost", {}).duplicate(true)
		outpost["max_hp"] = int(outpost.get("max_hp", 0)) + pending_hp_bonus
		outpost["current_hp"] = int(outpost.get("current_hp", 0)) + pending_hp_bonus
		update4_active_run["outpost"] = outpost
		council["pending_outpost_hp_bonus"] = 0
		update4_active_run["council_season"] = council
	var passive := OutpostServiceScript.activate_income_passive(update4_active_run, GameState.gold_income, GameState.food_income, DataRegistry.update4_outpost_types)
	update4_active_run = passive.get("active_run", update4_active_run).duplicate(true)
	GameState.gold_income = int(passive.get("gold_income", GameState.gold_income))
	GameState.food_income = int(passive.get("food_income", GameState.food_income))
	_log("전초기지 건설: %s" % str(DataRegistry.update4_outpost_types.get(type_id, {}).get("display_name", type_id)))
	_set_screen(Constants.SCREEN_OUTPOST_MANAGEMENT)
	_write_campaign_v2_snapshot()


func _set_update4_outpost_assignment(instance_ids: Array[String]) -> void:
	var owned_ids := ContractRosterServiceScript.owned_instance_ids(monster_roster, DataRegistry.monster_instances)
	var result := OutpostServiceScript.assign_monsters(update4_active_run, instance_ids, owned_ids, DataRegistry.monster_instances)
	if not bool(result.get("ok", false)):
		campaign_save_notice = str(result.get("error", "전초기지 배치를 변경하지 못했습니다."))
		_show_campaign_save_notice_overlay()
		return
	update4_active_run = result.get("active_run", update4_active_run).duplicate(true)
	_set_screen(Constants.SCREEN_OUTPOST_MANAGEMENT)
	_write_campaign_v2_snapshot()


func _upgrade_update4_outpost() -> void:
	var result := OutpostServiceScript.upgrade(update4_active_run, GameState.day, DataRegistry.update4_outpost_types)
	if not bool(result.get("ok", false)):
		campaign_save_notice = str(result.get("error", "전초기지를 강화하지 못했습니다."))
		_show_campaign_save_notice_overlay()
		return
	update4_active_run = result.get("active_run", update4_active_run).duplicate(true)
	_log("전초기지 Lv.2 강화를 완료했습니다.")
	_set_screen(Constants.SCREEN_OUTPOST_MANAGEMENT)
	_write_campaign_v2_snapshot()


func _open_update4_outpost_management() -> void:
	if _update4_council_mode_active() and str(update4_active_run.get("outpost", {}).get("type_id", "")) != "":
		_set_screen(Constants.SCREEN_OUTPOST_MANAGEMENT)


func _close_update4_outpost_management() -> void:
	_set_screen(Constants.SCREEN_MANAGEMENT)


func _open_update4_upper_floor() -> void:
	if _update4_council_mode_active() and bool(update4_active_run.get("upper_floor", {}).get("unlocked", false)):
		_set_screen(Constants.SCREEN_UPPER_FLOOR)


func _build_upper_floor_ui() -> void:
	var screen = UpperFloorScreenScene.instantiate()
	screen.name = "UpperFloorScreen"
	ui_layer.add_child(screen)
	screen.setup(update4_active_run.get("upper_floor", {}), DataRegistry.update4_upper_floor_layouts, DataRegistry.update4_upper_floor_modules)
	screen.layout_selected.connect(_select_update4_upper_layout)
	screen.closed.connect(func(): _set_screen(Constants.SCREEN_MANAGEMENT))


func _select_update4_upper_layout(layout_id: String) -> void:
	var selected := UpperFloorObjectiveServiceScript.select_layout(update4_active_run, layout_id, DataRegistry.update4_upper_floor_layouts, DataRegistry.update4_upper_floor_modules, _castle_stage_index())
	if not bool(selected.get("ok", false)):
		campaign_save_notice = str(selected.get("error", "상층 레이아웃을 확정하지 못했습니다."))
		_show_campaign_save_notice_overlay()
		return
	update4_active_run = selected.get("active_run", update4_active_run).duplicate(true)
	_log("상층 레이아웃 확정: %s" % str(DataRegistry.update4_upper_floor_layouts.get(layout_id, {}).get("display_name", layout_id)))
	_set_screen(Constants.SCREEN_UPPER_FLOOR)
	_write_campaign_v2_snapshot()


func _build_update4_multifloor_hud() -> void:
	if not _update4_council_mode_active() or not bool(update4_active_run.get("upper_floor", {}).get("unlocked", false)):
		return
	var floor_hud = MultiFloorHUDScene.instantiate()
	floor_hud.name = "MultiFloorHUD"
	ui_layer.add_child(floor_hud)
	floor_hud.setup(update4_active_run.get("upper_floor", {}), DataRegistry.update4_upper_floor_layouts, DataRegistry.update4_upper_floor_modules, update4_profile.get("chronicle_update4", {}).get("accessibility", {}))
	floor_hud.floor_selected.connect(_select_update4_visible_floor)
	floor_hud.auto_camera_changed.connect(_set_update4_auto_camera)


func _prepare_update4_multifloor_battle() -> void:
	if not _update4_council_mode_active() or not bool(update4_active_run.get("upper_floor", {}).get("unlocked", false)):
		return
	var upper: Dictionary = update4_active_run.get("upper_floor", {}).duplicate(true)
	var runtime: Dictionary = upper.get("graph_runtime", MultiFloorGraphServiceScript.new_runtime()).duplicate(true)
	var layout: Dictionary = DataRegistry.update4_upper_floor_layouts.get(str(upper.get("layout_id", "")), {})
	var upper_room_id := "crown_sanctum"
	for placement_value in layout.get("placed_modules", []):
		if placement_value is Dictionary:
			upper_room_id = str(placement_value.get("instance_id", upper_room_id))
			break
	var upper_species := ["spider_tailor", "bat_courier"]
	for monster in monster_units:
		if not is_instance_valid(monster):
			continue
		var species_id := str(monster.unit_id)
		var floor_id := MultiFloorGraphServiceScript.FLOOR_2 if species_id in upper_species else MultiFloorGraphServiceScript.FLOOR_1
		var room_id := upper_room_id if floor_id == MultiFloorGraphServiceScript.FLOOR_2 else str(monster.current_room)
		runtime = MultiFloorGraphServiceScript.register_entity(runtime, species_id, "monster", floor_id, room_id)
	upper["graph_runtime"] = runtime
	update4_active_run["upper_floor"] = upper


func _select_update4_visible_floor(floor_id: String) -> void:
	var upper: Dictionary = update4_active_run.get("upper_floor", {}).duplicate(true)
	var runtime: Dictionary = upper.get("graph_runtime", {}).duplicate(true)
	runtime["visible_floor"] = floor_id
	upper["graph_runtime"] = runtime
	update4_active_run["upper_floor"] = upper


func _set_update4_auto_camera(enabled: bool) -> void:
	var upper: Dictionary = update4_active_run.get("upper_floor", {}).duplicate(true)
	upper["auto_camera_switch"] = enabled
	update4_active_run["upper_floor"] = upper
	_write_campaign_v2_snapshot()


func _start_update4_outpost_battle() -> void:
	if not _update4_council_mode_active() or not OutpostEncounterServiceScript.is_battle_day(GameState.day):
		return
	if str(update4_active_run.get("outpost", {}).get("type_id", "")) == "":
		_log("전초기지를 먼저 건설하세요.")
		_set_screen(Constants.SCREEN_OUTPOST_MANAGEMENT)
		return
	if not _begin_update4_council_combat():
		return
	_clear_units()
	_clear_effects()
	_reset_engineer_combat_state()
	GameState.victory = false
	GameState.defeat = false
	_set_screen(Constants.SCREEN_OUTPOST_BATTLE)


func _build_outpost_battle_ui() -> void:
	var screen = OutpostBattleRootScene.instantiate()
	screen.name = "OutpostBattleRoot"
	ui_layer.add_child(screen)
	var outpost: Dictionary = update4_active_run.get("outpost", {})
	var type_id := str(outpost.get("type_id", ""))
	var defender_names: Array[String] = []
	for instance_id_value in outpost.get("assigned_monster_ids", []):
		var instance_id := str(instance_id_value)
		defender_names.append(str(DataRegistry.monster_instances.get(instance_id, {}).get("display_name", instance_id)))
	screen.setup(outpost, DataRegistry.update4_outpost_encounters.get("outpost_fixed_four_modules", {}), DataRegistry.update4_outpost_types.get(type_id, {}), defender_names, GameState.day)
	screen.battle_settled.connect(_settle_update4_outpost_battle)


func _settle_update4_outpost_battle(battle_result: Dictionary) -> void:
	var settled := OutpostEncounterServiceScript.settle_result(update4_active_run, battle_result, update4_profile)
	if not bool(settled.get("ok", false)):
		campaign_save_notice = str(settled.get("error", "전초기지 결산을 기록하지 못했습니다."))
		_show_campaign_save_notice_overlay()
		return
	update4_active_run = settled.get("active_run", update4_active_run).duplicate(true)
	update4_profile = settled.get("profile", update4_profile).duplicate(true)
	update4_active_run = Update4CampaignRuntimeScript.record_battle_metrics(update4_active_run, GameState.day, {})
	_settle_update4_region_chapter(Update4CampaignRuntimeScript.settlement_slot_for_day(GameState.day))
	var reward: Dictionary = battle_result.get("reward", {})
	GameState.add_rewards(reward)
	var completed := CouncilSeasonServiceScript.complete_combat(_update4_council_day_state())
	if bool(completed.get("ok", false)):
		_set_update4_council_day_state(completed.get("state", {}))
	var win := bool(battle_result.get("win", false))
	result_growth_reviewed = true
	last_growth_summary.clear()
	result_summary = {
		"win": win,
		"outpost_battle": true,
		"lines": [
			"전초기지 깃발 방어 %s" % ("성공" if win else "실패"),
			"전투 시간 %.1f초" % float(battle_result.get("duration_seconds", 0.0)),
			"깃발 HP %d / %d" % [int(battle_result.get("ending_hp", 0)), int(battle_result.get("max_hp", 0))],
			"재도전 %d회" % int(battle_result.get("retry_count", 0)),
			"방어 보상  금화 %d · 식량 %d" % [int(reward.get("gold", 0)), int(reward.get("food", 0))],
			"본성 왕좌와 캠페인 패배 상태는 변하지 않았습니다."
		],
		"growth": [],
		"metrics": {"outpost_battle": true, "day": GameState.day}
	}
	_clear_units()
	_clear_effects()
	_log("DAY %d 전초기지 방어전 결산: %s" % [GameState.day, "승리" if win else "패배 수용"])
	_set_screen(Constants.SCREEN_RESULT)


func _build_front_selection_ui() -> void:
	update3_profile = FrontCampaignServiceScript.reconcile_unlocks(_update3_front_profile_context(), DataRegistry.update3_fronts)
	var screen = FrontSelectionScreenScene.instantiate()
	screen.name = "FrontSelectionScreen"
	ui_layer.add_child(screen)
	screen.setup(update3_profile, DataRegistry.update3_fronts, campaign_cycle_index, true)
	screen.front_selected.connect(_select_update3_front)
	screen.invitation_selected.connect(_select_update3_invitation)
	screen.front_rotation_changed.connect(_set_update3_front_rotation)
	screen.canceled.connect(_cancel_update3_front_selection)


func _set_update3_front_rotation(enabled: bool) -> void:
	if not bool(update3_profile.get("front_rotation_unlocked", false)):
		return
	update3_profile["front_rotation_enabled"] = enabled
	_log("전선 순환 옵션: %s" % ("켜짐" if enabled else "꺼짐"))
	_set_screen(Constants.SCREEN_FRONT_SELECTION)


func _select_update3_invitation(front_id: String) -> void:
	var result := FrontCampaignServiceScript.apply_invitation(_update3_front_profile_context(), front_id, DataRegistry.update3_fronts)
	if not bool(result.get("ok", false)):
		campaign_save_notice = str(result.get("error", "초대장을 선택하지 못했습니다."))
		_show_campaign_save_notice_overlay()
		return
	update3_profile = result.get("profile", {}).duplicate(true)
	_log("3차 첫 진입 초대장으로 %s 전선을 해금했습니다." % str(DataRegistry.update3_fronts.get(front_id, {}).get("display_name", front_id)))
	_set_screen(Constants.SCREEN_FRONT_SELECTION)
	_write_campaign_v2_snapshot()


func _select_update3_front(front_id: String) -> void:
	var result := FrontCampaignServiceScript.select_front(_update3_front_profile_context(), update3_active_run, front_id, DataRegistry.update3_fronts)
	if not bool(result.get("ok", false)):
		campaign_save_notice = str(result.get("error", "전선을 선택하지 못했습니다."))
		_show_campaign_save_notice_overlay()
		return
	update3_profile = result.get("profile", {}).duplicate(true)
	update3_active_run = result.get("active_run", {}).duplicate(true)
	var display_name := str(DataRegistry.update3_fronts.get(front_id, {}).get("display_name", front_id))
	_log("%d회차 작전 전선 확정: %s. 이제 마왕성 심장을 선택합니다." % [campaign_cycle_index, display_name])
	_set_screen(Constants.SCREEN_HEART_SELECTION)
	if not _write_campaign_v2_snapshot():
		campaign_save_notice = "전선은 선택했지만 심장 선택 대기 상태 저장에 실패했습니다."
		_show_campaign_save_notice_overlay()


func _cancel_update3_front_selection() -> void:
	_set_screen(Constants.SCREEN_TITLE)


func _build_heart_selection_ui() -> void:
	var screen = HeartSelectionScreenScene.instantiate()
	screen.name = "HeartSelectionScreen"
	ui_layer.add_child(screen)
	var front_id := str(update3_active_run.get("front_id", ""))
	var front_name := str(DataRegistry.update3_fronts.get(front_id, {}).get("display_name", front_id))
	screen.setup(update3_profile, DataRegistry.update3_castle_hearts, front_name, true)
	screen.heart_selected.connect(_select_update3_heart)
	screen.canceled.connect(_cancel_update3_heart_selection)


func _select_update3_heart(heart_id: String) -> void:
	var result := CastleHeartServiceScript.select_heart(update3_profile, update3_active_run, heart_id, DataRegistry.update3_castle_hearts)
	if not bool(result.get("ok", false)):
		campaign_save_notice = str(result.get("error", "심장을 선택하지 못했습니다."))
		_show_campaign_save_notice_overlay()
		return
	update3_profile = result.get("profile", update3_profile).duplicate(true)
	update3_active_run = result.get("active_run", update3_active_run).duplicate(true)
	_sync_update3_heart_awaken()
	var definition: Dictionary = DataRegistry.update3_castle_hearts.get(heart_id, {})
	_log("%d회차 마왕성 심장 확정: %s. 후보 사건 %s을(를) 연결했습니다." % [campaign_cycle_index, str(definition.get("display_name", heart_id)), str(update3_active_run.get("heart_event_candidate_id", "없음"))])
	_set_screen(Constants.SCREEN_CONTRACT_BOARD)
	if not _write_campaign_v2_snapshot():
		campaign_save_notice = "심장은 선택했지만 v4 보조 저장에 실패했습니다."
		_show_campaign_save_notice_overlay()


func _cancel_update3_heart_selection() -> void:
	_set_screen(Constants.SCREEN_TITLE)


func _update3_heart_hud_state() -> Dictionary:
	return {"heart": update3_active_run.get("heart", {}).duplicate(true)}


func _build_update3_heart_combat_hud() -> void:
	var component = HeartCombatHUDScene.instantiate()
	component.name = "HeartCombatHUD"
	ui_layer.add_child(component)
	component.setup(Callable(self, "_update3_heart_hud_state"))


func _build_duo_link_loadout_ui() -> void:
	var screen = DuoLinkLoadoutScreenScene.instantiate()
	screen.name = "DuoLinkLoadoutScreen"
	ui_layer.add_child(screen)
	screen.setup(update3_profile, update3_active_run, DataRegistry.update3_duo_links, deployed_instance_ids)
	screen.link_toggled.connect(_toggle_update3_duo_link)
	screen.auto_use_changed.connect(_set_update3_duo_link_auto_use)
	screen.preset_saved.connect(_save_update3_duo_link_preset)
	screen.preset_loaded.connect(_load_update3_duo_link_preset)
	screen.auto_recommend_requested.connect(_auto_recommend_update3_duo_links)
	screen.confirmed.connect(_confirm_update3_duo_link_loadout)
	screen.canceled.connect(_cancel_update3_duo_link_loadout)


func _toggle_update3_duo_link(link_id: String) -> void:
	if update3_active_run.get("equipped_duo_links", []).has(link_id):
		update3_active_run = DuoLinkServiceScript.unequip(update3_active_run, link_id)
	else:
		var result := DuoLinkServiceScript.equip(update3_profile, update3_active_run, link_id, DataRegistry.update3_duo_links)
		if not bool(result.get("ok", false)):
			_log(str(result.get("error", "합동기를 장착하지 못했습니다.")))
			return
		update3_active_run = result.get("active_run", update3_active_run).duplicate(true)
	_set_screen(Constants.SCREEN_DUO_LINK_LOADOUT)


func _confirm_update3_duo_link_loadout() -> void:
	update3_active_run["duo_link_loadout_confirmed"] = true
	var warnings := DuoLinkServiceScript.deployment_warnings(update3_active_run, deployed_instance_ids, DataRegistry.update3_duo_links)
	for warning in warnings:
		_log(str(warning))
	_log("합동기 편성을 확정했습니다: %d/2 슬롯." % update3_active_run.get("equipped_duo_links", []).size())
	_set_screen(_next_update2_cycle_setup_screen())


func _set_update3_duo_link_auto_use(enabled: bool) -> void:
	update3_active_run["duo_link_auto_use"] = enabled
	_set_screen(Constants.SCREEN_DUO_LINK_LOADOUT)


func _save_update3_duo_link_preset(slot_index: int) -> void:
	var slot_count := clampi(int(update3_profile.get("duo_link_preset_slots", 0)), 0, 2)
	if slot_index < 0 or slot_index >= slot_count:
		return
	var presets: Array = update3_profile.get("duo_link_presets", []).duplicate(true)
	while presets.size() < slot_count:
		presets.append([])
	presets[slot_index] = update3_active_run.get("equipped_duo_links", []).duplicate()
	update3_profile["duo_link_presets"] = presets
	_log("합동기 프리셋 %d에 현재 편성을 저장했습니다." % (slot_index + 1))
	_set_screen(Constants.SCREEN_DUO_LINK_LOADOUT)


func _load_update3_duo_link_preset(slot_index: int) -> void:
	var presets: Array = update3_profile.get("duo_link_presets", [])
	if slot_index < 0 or slot_index >= presets.size() or not (presets[slot_index] is Array):
		return
	_update3_equip_link_candidates(presets[slot_index])
	_log("합동기 프리셋 %d을 불러왔습니다." % (slot_index + 1))
	_set_screen(Constants.SCREEN_DUO_LINK_LOADOUT)


func _auto_recommend_update3_duo_links() -> void:
	if not bool(update3_profile.get("duo_link_auto_recommendation_unlocked", false)):
		return
	var candidates: Array[Dictionary] = []
	for link_id_value in update3_profile.get("duo_links", {}).get("unlocked", []):
		var link_id := str(link_id_value)
		if not DataRegistry.update3_duo_links.has(link_id):
			continue
		var members: Array = DataRegistry.update3_duo_links.get(link_id, {}).get("member_instance_ids", [])
		var ready_count := 0
		for member_id_value in members:
			if deployed_instance_ids.has(str(member_id_value)):
				ready_count += 1
		candidates.append({"id": link_id, "ready": ready_count == members.size() and members.size() == 2})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if bool(a.get("ready", false)) != bool(b.get("ready", false)):
			return bool(a.get("ready", false))
		return str(a.get("id", "")) < str(b.get("id", ""))
	)
	var candidate_ids: Array = []
	for candidate in candidates:
		candidate_ids.append(str(candidate.get("id", "")))
	_update3_equip_link_candidates(candidate_ids)
	_log("현재 출전 멤버를 기준으로 합동기 편성을 추천했습니다.")
	_set_screen(Constants.SCREEN_DUO_LINK_LOADOUT)


func _update3_equip_link_candidates(candidate_ids: Array) -> void:
	update3_active_run["equipped_duo_links"] = []
	for link_id_value in candidate_ids:
		if update3_active_run.get("equipped_duo_links", []).size() >= DuoLinkServiceScript.MAX_EQUIPPED:
			break
		var result := DuoLinkServiceScript.equip(update3_profile, update3_active_run, str(link_id_value), DataRegistry.update3_duo_links)
		if bool(result.get("ok", false)):
			update3_active_run = result.get("active_run", update3_active_run).duplicate(true)


func _cancel_update3_duo_link_loadout() -> void:
	if bool(update3_active_run.get("duo_link_loadout_confirmed", false)):
		_set_screen(Constants.SCREEN_MANAGEMENT)
	else:
		_set_screen(Constants.SCREEN_CONTRACT_BOARD)


func _update3_duo_loadout_edit_available() -> bool:
	return campaign_cycle_index >= 2 and bool(update3_active_run.get("update3_enabled", false)) and bool(update3_active_run.get("duo_link_loadout_confirmed", false)) and not campaign_postgame_active


func _open_update3_duo_link_loadout() -> void:
	if not _update3_duo_loadout_edit_available():
		return
	_set_screen(Constants.SCREEN_DUO_LINK_LOADOUT)


func _update3_duo_link_hud_state() -> Dictionary:
	var names: Dictionary = {}
	for link_id_value in update3_active_run.get("equipped_duo_links", []):
		var link_id := str(link_id_value)
		names[link_id] = str(DataRegistry.update3_duo_links.get(link_id, {}).get("display_name", link_id))
	return {"equipped": update3_active_run.get("equipped_duo_links", []).duplicate(), "states": update3_active_run.get("duo_link_states", {}).duplicate(true), "names": names}


func _build_update3_duo_link_combat_hud() -> void:
	var component = DuoLinkCombatHUDScene.instantiate()
	component.name = "DuoLinkCombatHUD"
	ui_layer.add_child(component)
	component.setup(Callable(self, "_update3_duo_link_hud_state"), Callable(self, "_activate_update3_duo_link"))


func _build_contract_board_ui() -> void:
	_ensure_contract_board_offer()
	var selection_open := selected_contract_ids.size() != ContractRosterServiceScript.REQUIRED_CONTRACT_COUNT
	if selection_open and contract_board_pending_ids.is_empty():
		contract_board_pending_ids = selected_contract_ids.duplicate()
	var screen := _onboarding_screen_panel(Color("#050407ff"))
	_onboarding_add_scene_illustration(screen, Rect2(0, 0, 1920, 1080), ONBOARDING_START_SCENE)
	var shade := _onboarding_child_panel(screen, Rect2(90, 58, 1740, 964), Color("#08060cf2"), Color("#9b6a27"))
	if selection_open:
		_build_contract_selection_panel(shade)
	else:
		_build_contract_roster_panel(shade)

func _build_contract_selection_panel(shade: Control) -> void:
	hud.label(shade, "%d회차 · 계약 게시판" % campaign_cycle_index, Vector2(0, 28), Vector2(1740, 52), 38, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(shade, "다섯 동료 중 이번 회차에 함께할 정확히 2명을 선택하세요. 계약한 동료는 회차가 끝날 때까지 보유 명단에 남습니다.", Vector2(190, 88), Vector2(1360, 52), 18, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
	for index in range(contract_board_offer_ids.size()):
		var contract_id := str(contract_board_offer_ids[index])
		var contract: Dictionary = DataRegistry.update2_contract(contract_id)
		var selected := contract_board_pending_ids.has(contract_id)
		var card_x := 46 + index * 334
		var border := Color("#e1b85f") if selected else Color("#5c4b35")
		var card := _onboarding_child_panel(shade, Rect2(card_x, 176, 308, 548), Color("#15111bf4"), border)
		hud.label(card, str(contract.get("display_name", contract_id)), Vector2(18, 24), Vector2(272, 40), 28, Color("#fff2c9") if selected else Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
		hud.label(card, str(contract.get("species_name", "계약 몬스터")), Vector2(18, 72), Vector2(272, 30), 17, Color("#c6a968"), HORIZONTAL_ALIGNMENT_CENTER)
		var role_panel := _onboarding_child_panel(card, Rect2(28, 126, 252, 52), Color("#24172eee"), Color("#8f66b5"))
		hud.label(role_panel, str(contract.get("role", "전투 지원")), Vector2(8, 10), Vector2(236, 32), 17, Color("#f0d8ff"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
		hud.label(card, str(contract.get("description", "")), Vector2(28, 210), Vector2(252, 166), 17, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 5)
		var label := "선택됨 · 해제" if selected else "계약 후보 선택"
		hud.button(card, label, Rect2(44, 450, 220, 58), Callable(self, "_toggle_contract_candidate").bind(contract_id), 17)
	var count := contract_board_pending_ids.size()
	hud.label(shade, "현재 선택 %d / %d" % [count, ContractRosterServiceScript.REQUIRED_CONTRACT_COUNT], Vector2(540, 780), Vector2(320, 42), 22, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	var confirm = hud.button(shade, "두 계약 확정", Rect2(880, 770, 320, 60), Callable(self, "_confirm_contract_selection"), 20)
	confirm.disabled = count != ContractRosterServiceScript.REQUIRED_CONTRACT_COUNT
	hud.label(shade, "확정 뒤에는 이번 회차에서 계약 상대를 바꿀 수 없습니다.", Vector2(0, 856), Vector2(1740, 34), 15, Color("#a99fba"), HORIZONTAL_ALIGNMENT_CENTER)


func _build_contract_roster_panel(shade: Control) -> void:
	_sync_contract_reserves()
	var limit := _current_stage_deployment_limit()
	hud.label(shade, "출전·예비 편성", Vector2(0, 28), Vector2(1740, 52), 38, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(shade, "%s · 출전 %d / 최대 %d명" % [str(DataRegistry.castle_evolution_stage(castle_art_stage).get("display_name", castle_art_stage)), deployed_instance_ids.size(), limit], Vector2(0, 88), Vector2(1740, 40), 20, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.label(shade, "출전은 실제 방어전에 등장하고, 예비는 성장 정보와 계약을 유지한 채 대기합니다.", Vector2(230, 132), Vector2(1280, 38), 17, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_CENTER)
	var owned_ids := _contract_owned_instance_ids(true)
	for index in range(owned_ids.size()):
		var instance_id := str(owned_ids[index])
		var instance: Dictionary = DataRegistry.monster_instance(instance_id)
		var species_id := str(instance.get("species_id", ""))
		var monster: Dictionary = DataRegistry.monster(species_id)
		var deployed := deployed_instance_ids.has(instance_id)
		var column := index % 4
		var row := index / 4
		var card := _onboarding_child_panel(shade, Rect2(68 + column * 408, 210 + row * 244, 372, 208), Color("#15111bf4"), Color("#d0a94f") if deployed else Color("#4c4354"))
		hud.label(card, str(instance.get("display_name", monster.get("display_name", species_id))), Vector2(18, 18), Vector2(336, 34), 23, Color("#fff2c9") if deployed else Color("#d8d1df"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
		hud.label(card, str(monster.get("role", "")), Vector2(18, 58), Vector2(336, 26), 15, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
		hud.label(card, "출전" if deployed else "예비", Vector2(18, 96), Vector2(336, 26), 18, Color("#7ee0a3") if deployed else Color("#aaa1b5"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
		hud.button(card, "예비로 전환" if deployed else "출전으로 전환", Rect2(76, 140, 220, 46), Callable(self, "_toggle_contract_deployment").bind(instance_id), 15)
	var confirm = hud.button(shade, "편성 저장", Rect2(710, 804, 320, 60), Callable(self, "_confirm_contract_roster"), 20)
	confirm.disabled = not ContractRosterServiceScript.validate_deployment(deployed_instance_ids, owned_ids, castle_art_stage, _current_stage_deployment_limit() - ContractRosterServiceScript.stage_deployment_limit(castle_art_stage)).is_empty()
	hud.label(shade, "성 단계가 오르면 출전 상한이 늘어납니다. 새 칸은 이 화면에서 직접 출전시켜 사용합니다.", Vector2(0, 882), Vector2(1740, 34), 15, Color("#a99fba"), HORIZONTAL_ALIGNMENT_CENTER)


func _ensure_contract_board_offer() -> void:
	if update2_cycle_seed <= 0:
		update2_cycle_seed = maxi(1, campaign_cycle_index * 1009 + int(Time.get_unix_time_from_system()) % 1000003)
	if contract_board_offer_ids.size() != DataRegistry.update2_contracts.size():
		contract_board_offer_ids = ContractRosterServiceScript.offer_ids(DataRegistry.update2_contracts, update2_cycle_seed)
	_ensure_update2_seeded_campaign()

func _ensure_update2_seeded_campaign() -> void:
	if campaign_cycle_index < 2 or update2_cycle_seed <= 0:
		return
	var event_count := int(DataRegistry.update2_seeded_campaign.get("events", {}).size())
	if event_deck_order.size() != event_count:
		event_deck_order = Update2SeededCampaignServiceScript.event_deck(DataRegistry.update2_seeded_campaign, update2_cycle_seed)
	if wave_variant_ids.size() != 5:
		wave_variant_ids = Update2SeededCampaignServiceScript.wave_variant_ids(DataRegistry.update2_seeded_campaign, update2_cycle_seed)

func _update2_seeded_wave_variant(day: int) -> Dictionary:
	_ensure_update2_seeded_campaign()
	return Update2SeededCampaignServiceScript.wave_variant_for_day(DataRegistry.update2_seeded_campaign, wave_variant_ids, day)

func _apply_update2_seeded_event(day: int) -> void:
	if campaign_cycle_index < 2:
		return
	_ensure_update2_seeded_campaign()
	var event: Dictionary = Update2SeededCampaignServiceScript.event_for_day(DataRegistry.update2_seeded_campaign, event_deck_order, day)
	var event_id := str(event.get("id", ""))
	if event_id == "" or update2_triggered_event_ids.has(event_id):
		return
	_apply_update2_cycle_choice_rewards(event)
	var contract_bond := int(event.get("contract_bond", 0))
	if contract_bond > 0:
		for contract_id_value in selected_contract_ids:
			if monster_roster.has(str(contract_id_value)):
				_grant_monster_bond(str(contract_id_value), contract_bond)
	update2_triggered_event_ids.append(event_id)
	var seen_events: Array = campaign_profile.get("seen_event_ids", [])
	var archive_id := "cycle_%d:%s" % [campaign_cycle_index, event_id]
	if not seen_events.has(archive_id):
		seen_events.append(archive_id)
	campaign_profile["seen_event_ids"] = seen_events
	SignalBus.resources_changed.emit()
	_log("회차 사건 · %s: %s" % [str(event.get("title", event_id)), str(event.get("text", ""))])

func _update2_leon_analysis() -> Dictionary:
	var scores := {"facility": 0.0, "backline": 0.0, "sustain": 0.0, "direct": 0.0}
	var observed_monsters: Array[String] = []
	for monster_id_value in _defense_monster_ids():
		var monster_id := str(monster_id_value)
		if not _monster_deployed_for_defense(monster_id):
			continue
		var stats := _scaled_monster_stats(monster_id)
		var roster: Dictionary = monster_roster.get(monster_id, {})
		var role_text := (str(stats.get("role", "")) + " " + str(stats.get("role_tag", ""))).to_lower()
		var attack_range := float(stats.get("attack_range", 0.0))
		var attack_power := float(stats.get("atk", 0.0))
		if attack_range >= 100.0:
			scores["backline"] += 20.0 + attack_range * 0.10
		else:
			scores["direct"] += 20.0 + attack_power
		if role_text.contains("heal") or role_text.contains("support") or role_text.contains("guard") or role_text.contains("tank"):
			scores["sustain"] += 32.0
		var room_id := str(roster.get("room", ""))
		if rooms.has(room_id):
			var room: Dictionary = rooms.get(room_id, {})
			var facility_role := str(room.get("facility_role", room.get("type", "")))
			if facility_role not in ["", "entrance", "throne", "build_slot"]:
				scores["facility"] += 12.0 + float(room.get("facility_level", 0)) * 6.0
			if facility_role in ["recovery", "ward_core"]:
				scores["sustain"] += 25.0
		observed_monsters.append(monster_id)
	for room_value in rooms.values():
		if not (room_value is Dictionary):
			continue
		var room: Dictionary = room_value
		var facility_role := str(room.get("facility_role", room.get("type", "")))
		if facility_role not in ["", "entrance", "throne", "build_slot"]:
			scores["facility"] += float(room.get("facility_level", 0)) * 3.0
	scores["observed_monsters"] = observed_monsters
	scores["heart_id"] = str(update3_active_run.get("heart", {}).get("heart_id", ""))
	scores["heart_active_uses"] = int(update3_active_run.get("run_metrics_update3", {}).get("heart_active_uses", 0))
	scores["equipped_duo_links"] = update3_active_run.get("equipped_duo_links", []).size()
	return scores


func _ensure_update2_leon_adaptation(day: int = 0) -> Dictionary:
	var target_day := GameState.day if day <= 0 else day
	leon_adaptation = LeonAdaptationServiceScript.normalize(leon_adaptation, DataRegistry.leon_adaptive_stances)
	if campaign_cycle_index < 2 or target_day < 24:
		return leon_adaptation
	if bool(leon_adaptation.get("locked", false)):
		return leon_adaptation
	var retry_seed := maxi(1, update2_cycle_seed if update2_cycle_seed > 0 else campaign_cycle_index * 1009)
	leon_adaptation = LeonAdaptationServiceScript.choose_stance(DataRegistry.leon_adaptive_stances, _update2_leon_analysis(), retry_seed)
	var stance_id := str(leon_adaptation.get("stance_id", ""))
	var stance := DataRegistry.leon_adaptive_stance(stance_id)
	if stance.is_empty():
		return leon_adaptation
	var history: Array = campaign_profile.get("leon_stance_history", [])
	var history_exists := history.any(func(entry): return entry is Dictionary and int(entry.get("cycle_index", 0)) == campaign_cycle_index)
	if not history_exists:
		history.append({"cycle_index": campaign_cycle_index, "stance_id": stance_id, "announced_day": 24, "retry_seed": retry_seed})
		campaign_profile["leon_stance_history"] = history
	_log("DAY 24 레온 분석 · DAY 30 최종 공성 재등장 대비 · %s: %s" % [str(stance.get("display_name", stance_id)), str(stance.get("analysis_notice", ""))])
	_log("DAY 30 최종 공성 대응 약점 예고: %s" % str(stance.get("weakness_notice", "")))
	return leon_adaptation
func _update2_leon_stance() -> Dictionary:
	var adaptation := _ensure_update2_leon_adaptation(GameState.day)
	if not bool(adaptation.get("locked", false)):
		return {}
	return DataRegistry.leon_adaptive_stance(str(adaptation.get("stance_id", "")))

func _apply_update2_leon_enemy_stats(enemy_id: String, stats: Dictionary) -> void:
	if enemy_id != "official_hero_leon" or GameState.day != 30:
		return
	var stance := _update2_leon_stance()
	if stance.is_empty():
		return
	var effects: Dictionary = stance.get("effects", {})
	stats["max_hp"] = maxi(1, int(round(float(stats.get("max_hp", 1)) * float(effects.get("max_hp_multiplier", 1.0)))))
	stats["atk"] = maxi(1, int(round(float(stats.get("atk", 1)) * float(effects.get("atk_multiplier", 1.0)))))
	stats["move_speed"] = float(stats.get("move_speed", 100.0)) * float(effects.get("move_speed_multiplier", 1.0))
	stats["attack_interval"] = maxf(0.1, float(stats.get("attack_interval", 1.0)) * float(effects.get("attack_interval_multiplier", 1.0)))
	if effects.has("attack_range"):
		stats["attack_range"] = float(effects.get("attack_range"))
	if str(effects.get("goal_type", "")) != "":
		stats["goal_type"] = str(effects.get("goal_type"))

func _prepare_update2_leon_combat() -> Dictionary:
	if GameState.day != 30:
		return {}
	var stance := _update2_leon_stance()
	if stance.is_empty():
		return {}
	leon_adaptation["applied_count"] = int(leon_adaptation.get("applied_count", 0)) + 1
	_log("레온 적응 자세 · %s: %s" % [str(stance.get("display_name", "")), str(stance.get("combat_notice", ""))])
	return stance

func _toggle_contract_candidate(contract_id: String) -> void:
	if selected_contract_ids.size() == ContractRosterServiceScript.REQUIRED_CONTRACT_COUNT or DataRegistry.update2_contract(contract_id).is_empty():
		return
	if contract_board_pending_ids.has(contract_id):
		contract_board_pending_ids.erase(contract_id)
	elif contract_board_pending_ids.size() < ContractRosterServiceScript.REQUIRED_CONTRACT_COUNT:
		contract_board_pending_ids.append(contract_id)
	else:
		_log("계약 몬스터는 정확히 2명만 선택할 수 있습니다.")
	_set_screen(Constants.SCREEN_CONTRACT_BOARD)


func _confirm_contract_selection() -> void:
	var errors := ContractRosterServiceScript.validate_contract_selection(contract_board_pending_ids, DataRegistry.update2_contracts)
	if not errors.is_empty() or selected_contract_ids.size() == ContractRosterServiceScript.REQUIRED_CONTRACT_COUNT:
		return
	selected_contract_ids = contract_board_pending_ids.duplicate()
	for contract_id in selected_contract_ids:
		_add_contract_monster_to_roster(contract_id)
	var unlocked: Array = campaign_profile.get("unlocked_contract_ids", [])
	for contract_id in selected_contract_ids:
		if not unlocked.has(contract_id):
			unlocked.append(contract_id)
	campaign_profile["unlocked_contract_ids"] = unlocked
	var history: Array = campaign_profile.get("contract_history", [])
	history.append({"cycle": campaign_cycle_index, "contract_ids": selected_contract_ids.duplicate()})
	campaign_profile["contract_history"] = history
	deployed_instance_ids.clear()
	for contract_id in selected_contract_ids:
		var instance_id := str(DataRegistry.update2_contract(contract_id).get("instance_id", ""))
		if instance_id != "":
			deployed_instance_ids.append(instance_id)
	if DataRegistry.monster_instances.has("mon_core_pudding"):
		deployed_instance_ids.append("mon_core_pudding")
	_sync_contract_reserves()
	_log("%d회차 계약 확정: %s" % [campaign_cycle_index, _contract_name_list(selected_contract_ids)])
	update3_active_run["duo_link_loadout_confirmed"] = false
	_set_screen(Constants.SCREEN_DUO_LINK_LOADOUT)


func _add_contract_monster_to_roster(contract_id: String) -> void:
	var contract: Dictionary = DataRegistry.update2_contract(contract_id)
	var instance: Dictionary = DataRegistry.monster_instance(str(contract.get("instance_id", "")))
	var species_id := str(instance.get("species_id", contract_id))
	if species_id == "" or monster_roster.has(species_id):
		return
	var recommended_room := str(DataRegistry.monster(species_id).get("recommended_room", "barracks"))
	if not rooms.has(recommended_room):
		recommended_room = "barracks" if rooms.has("barracks") else "entrance"
	monster_roster[species_id] = {
		"level": int(instance.get("level", 1)),
		"exp": int(instance.get("exp", 0)),
		"bond": int(instance.get("bond", 0)),
		"bond_rank": int(instance.get("bond_rank", 0)),
		"unlocked_memory_ids": instance.get("unlocked_memory_ids", []).duplicate(),
		"room": recommended_room,
		"contract_cycle": campaign_cycle_index
	}


func _sync_update3_reward_monsters() -> Array[String]:
	var guaranteed_ids: Array = update3_profile.get("guaranteed_contract_instance_ids", [])
	var front_clears: Dictionary = update3_profile.get("fronts", {}).get("clear_counts", {})
	var ending_codes: Dictionary = {}
	for code_value in campaign_profile.get("ending_catalog_codes", {}).values():
		ending_codes[str(code_value)] = true
	for ending_id_value in update3_profile.get("update3_endings_seen", []):
		var ending_id := str(ending_id_value)
		var ending_code := str(DataRegistry.update3_endings.get(ending_id, {}).get("catalog_code", ""))
		if ending_code != "":
			ending_codes[ending_code] = true
	var added_names: Array[String] = []
	for species_id_value in DataRegistry.update3_monster_extensions.keys():
		var species_id := str(species_id_value)
		var definition: Dictionary = DataRegistry.update3_monster_extensions.get(species_id, {})
		var instance_id := str(definition.get("instance_id", ""))
		var unlock_condition: Dictionary = definition.get("unlock_condition", {})
		var required_front_id := str(unlock_condition.get("front_id", ""))
		var required_code := str(unlock_condition.get("alternate_ending_id", ""))
		var front_unlocked := required_front_id != "" and int(front_clears.get(required_front_id, 0)) >= 1
		var ending_unlocked := required_code != "" and ending_codes.has(required_code)
		if not guaranteed_ids.has(instance_id) and not front_unlocked and not ending_unlocked:
			continue
		if _add_update3_monster_to_roster(species_id, instance_id):
			added_names.append(str(definition.get("display_name", species_id)))
	if not added_names.is_empty():
		_sync_contract_reserves()
		_log("엔딩 보상 동료 합류: %s." % ", ".join(added_names))
	return added_names


func _add_update3_monster_to_roster(species_id: String, instance_id: String) -> bool:
	if species_id == "" or instance_id == "" or monster_roster.has(species_id):
		return false
	var definition: Dictionary = DataRegistry.monster(species_id)
	var instance: Dictionary = DataRegistry.monster_instance(instance_id)
	if definition.is_empty() or instance.is_empty():
		return false
	var recommended_room := str(definition.get("recommended_room", ""))
	var recommended_rooms = definition.get("recommended_rooms", [])
	if recommended_room == "" and recommended_rooms is Array and not recommended_rooms.is_empty():
		recommended_room = str(recommended_rooms[0])
	if not rooms.has(recommended_room):
		recommended_room = "barracks" if rooms.has("barracks") else "entrance"
	monster_roster[species_id] = {
		"level": int(instance.get("level", 1)),
		"exp": int(instance.get("exp", 0)),
		"bond": int(instance.get("bond", 0)),
		"bond_rank": int(instance.get("bond_rank", 0)),
		"unlocked_memory_ids": instance.get("unlocked_memory_ids", []).duplicate(),
		"room": recommended_room,
		"contract_cycle": campaign_cycle_index
	}
	return true


func _contract_owned_instance_ids(defense_only: bool = false) -> Array[String]:
	var result: Array[String] = []
	for species_id_value in monster_roster.keys():
		var species_id := str(species_id_value)
		if defense_only and not _monster_available_for_defense(species_id):
			continue
		var instance_id := ContractRosterServiceScript.instance_id_for_species(species_id, DataRegistry.monster_instances)
		if instance_id != "" and not result.has(instance_id):
			result.append(instance_id)
	return result


func _sync_contract_reserves() -> void:
	if selected_contract_ids.size() != ContractRosterServiceScript.REQUIRED_CONTRACT_COUNT:
		return
	var owned_ids := _contract_owned_instance_ids(false)
	var valid_deployed: Array[String] = []
	var defense_owned := _contract_owned_instance_ids(true)
	var limit := _current_stage_deployment_limit()
	for instance_id in deployed_instance_ids:
		if defense_owned.has(instance_id) and not valid_deployed.has(instance_id) and valid_deployed.size() < limit:
			valid_deployed.append(instance_id)
	deployed_instance_ids = valid_deployed
	reserve_instance_ids = ContractRosterServiceScript.reserve_instance_ids(owned_ids, deployed_instance_ids)


func _toggle_contract_deployment(instance_id: String) -> void:
	var owned_ids := _contract_owned_instance_ids(true)
	if not owned_ids.has(instance_id):
		return
	if deployed_instance_ids.has(instance_id):
		deployed_instance_ids.erase(instance_id)
	elif deployed_instance_ids.size() < _current_stage_deployment_limit():
		deployed_instance_ids.append(instance_id)
	else:
		_log("현재 성 단계의 출전 상한에 도달했습니다.")
	_sync_contract_reserves()
	_set_screen(Constants.SCREEN_CONTRACT_BOARD)


func _confirm_contract_roster() -> void:
	var errors := ContractRosterServiceScript.validate_deployment(deployed_instance_ids, _contract_owned_instance_ids(true), castle_art_stage, _current_stage_deployment_limit() - ContractRosterServiceScript.stage_deployment_limit(castle_art_stage))
	if not errors.is_empty():
		_log(str(errors[0]))
		return
	_sync_contract_reserves()
	_log("출전 편성을 저장했습니다: %d명 출전 · %d명 예비." % [deployed_instance_ids.size(), reserve_instance_ids.size()])
	_set_screen(_next_update2_cycle_setup_screen())


func _contract_roster_available() -> bool:
	return campaign_cycle_index >= 2 and selected_contract_ids.size() == ContractRosterServiceScript.REQUIRED_CONTRACT_COUNT


func _open_contract_roster() -> void:
	if _contract_roster_available():
		_set_screen(Constants.SCREEN_CONTRACT_BOARD)


func _monster_deployed_for_defense(monster_id: String) -> bool:
	if deployed_instance_ids.is_empty():
		return true
	var instance_id := ContractRosterServiceScript.instance_id_for_species(monster_id, DataRegistry.monster_instances)
	return instance_id != "" and deployed_instance_ids.has(instance_id)


func _contract_name_list(contract_ids: Array) -> String:
	var names: Array[String] = []
	for contract_id_value in contract_ids:
		var contract_id := str(contract_id_value)
		names.append(str(DataRegistry.update2_contract(contract_id).get("display_name", contract_id)))
	return ", ".join(names)


func _build_cycle_doctrine_ui() -> void:
	_build_update2_cycle_choice_ui("doctrine", DataRegistry.cycle_doctrine_ids(), "왕국 교리 대응", "정찰대가 확인한 왕국 공세 하나를 골라 이번 회차의 대응 방향을 확정하세요.")


func _build_cycle_decree_ui() -> void:
	_build_update2_cycle_choice_ui("decree", DataRegistry.cycle_decree_ids(), "마왕 칙령", "이번 회차에 성 전체가 따를 운영 원칙 하나를 선포하세요.")


func _build_challenge_seal_ui() -> void:
	_build_update2_cycle_choice_ui("seal", DataRegistry.challenge_seal_ids(), "도전 인장", "DAY 30에 완수할 도전 하나를 선택하세요. 성공하면 추가 악명을 얻습니다.")


func _build_update2_cycle_choice_ui(kind: String, choice_ids: Array, heading: String, intro: String) -> void:
	var screen := _onboarding_screen_panel(Color("#050407ff"))
	_onboarding_add_scene_illustration(screen, Rect2(0, 0, 1920, 1080), ONBOARDING_START_SCENE)
	var shade := _onboarding_child_panel(screen, Rect2(150, 90, 1620, 900), Color("#08060cef"), Color("#9b6a27"))
	hud.label(shade, "%d회차 · %s" % [campaign_cycle_index, heading], Vector2(0, 26), Vector2(1620, 54), 36, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(shade, intro, Vector2(180, 88), Vector2(1260, 44), 18, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
	for index in range(choice_ids.size()):
		var choice_id := str(choice_ids[index])
		var choice := _update2_cycle_choice_data(kind, choice_id)
		var column := index % 3
		var row := index / 3
		var card := _onboarding_child_panel(shade, Rect2(64 + column * 510, 158 + row * 344, 472, 310), Color("#130f19f4"), Color("#6e5630"))
		var title := str(choice.get("kingdom_title", choice.get("title", heading)))
		var subtitle := str(choice.get("counter_title", ""))
		hud.label(card, title, Vector2(20, 18), Vector2(432, 34), 20, Color("#f0c46f"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
		if subtitle != "":
			hud.label(card, subtitle, Vector2(20, 56), Vector2(432, 36), 23, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
		hud.rich_label(card, str(choice.get("description", "")), Vector2(34, 100), Vector2(404, 78), 16, Color("#d8d1df"), UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_WORD_SMART, VERTICAL_ALIGNMENT_CENTER, "", 5)
		var effect_text := str(choice.get("effect_label", _challenge_seal_reward_label(choice)))
		var effect_panel := _onboarding_child_panel(card, Rect2(30, 188, 412, 52), Color("#24172eee"), Color("#8f66b5"))
		hud.label(effect_panel, effect_text, Vector2(10, 6), Vector2(392, 40), 15, Color("#fff2c9"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
		var select_method := "_select_cycle_doctrine" if kind == "doctrine" else ("_select_cycle_decree" if kind == "decree" else "_select_challenge_seal")
		hud.button(card, "선택 확정", Rect2(126, 252, 220, 44), Callable(self, select_method).bind(choice_id), 16)
	hud.label(shade, "%s은(는) 한 회차에 하나만 선택하며 확정 후 바꿀 수 없습니다." % heading, Vector2(0, 846), Vector2(1620, 30), 15, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)

func _update2_cycle_choice_data(kind: String, choice_id: String) -> Dictionary:
	match kind:
		"doctrine":
			return DataRegistry.cycle_doctrine(choice_id)
		"decree":
			return DataRegistry.cycle_decree(choice_id)
		"seal":
			return DataRegistry.challenge_seal(choice_id)
	return {}

func _challenge_seal_reward_label(seal: Dictionary) -> String:
	var reward: Dictionary = seal.get("reward", {})
	return "DAY 30 달성 보상 · 악명 +%d" % int(reward.get("infamy", 0))

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
	hud.label(world, "정규 캠페인 시작: DAY 04", Vector2(240, 615), Vector2(600, 40), 20, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
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
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	if _title_reset_confirmation_required("new"):
		return
	if not _delete_campaign_save():
		_set_screen(Constants.SCREEN_TITLE)
		return
	_onboarding_reset_game()
	_start_first_play_observation("new")
	_onboarding_set_stage("LV01_NAME_ENTRY")
	_set_screen(Constants.SCREEN_NAME_ENTRY)

func _onboarding_start_quick_game() -> void:
	if _title_reset_confirmation_required("quick"):
		return
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
	update2_cycle_seed = maxi(1, campaign_cycle_index * 1009 + int(Time.get_unix_time_from_system()) % 1000003)
	contract_board_offer_ids.clear()
	selected_contract_ids.clear()
	contract_board_pending_ids.clear()
	deployed_instance_ids.clear()
	reserve_instance_ids.clear()
	event_deck_order.clear()
	wave_variant_ids.clear()
	update2_triggered_event_ids.clear()
	leon_adaptation = LeonAdaptationServiceScript.default_adaptation()
	update3_profile = FrontCampaignServiceScript.default_update3_profile()
	update3_active_run = FrontCampaignServiceScript.default_legacy_active_run()
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
	combat_speed_intro_seen = false
	combat_speed_intro_open = false
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
	if UISettings.is_touch_ui():
		_close_onboarding_name_keyboard()

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
	_close_onboarding_name_keyboard()
	GameState.player_name = player_name
	_tutorial_emit_action("name_valid", {"player_name": player_name})
	_onboarding_set_stage("LV02_OPENING_CUTSCENE")
	_onboarding_begin_dialogue(_onboarding_essential_opening_entries(), Constants.SCREEN_MANAGEMENT, ONBOARDING_ACTION_DAY1_MANAGEMENT)

func _close_onboarding_name_keyboard() -> void:
	if onboarding_name_input != null and is_instance_valid(onboarding_name_input):
		onboarding_name_input.release_focus()
	DisplayServer.virtual_keyboard_hide()

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
	_apply_update2_cycle_choice_rewards(doctrine)
	var contract_bond := int(doctrine.get("contract_bond", 0))
	if contract_bond > 0:
		for contract_id_value in selected_contract_ids:
			if monster_roster.has(str(contract_id_value)):
				_grant_monster_bond(str(contract_id_value), contract_bond)
	var throne_hp_bonus := int(doctrine.get("throne_hp_bonus", 0))
	if throne_hp_bonus > 0:
		GameState.demon_lord_max_hp += throne_hp_bonus
		GameState.demon_lord_hp += throne_hp_bonus
	campaign_profile["active_doctrine_id"] = doctrine_id
	var history: Array = campaign_profile.get("doctrine_history", [])
	history.append({"cycle": campaign_cycle_index, "doctrine_id": doctrine_id})
	campaign_profile["doctrine_history"] = history
	SignalBus.resources_changed.emit()
	_log("%d회차 대응 교리 확정: %s · %s" % [campaign_cycle_index, str(doctrine.get("counter_title", doctrine_id)), str(doctrine.get("effect_label", ""))])
	_set_screen(Constants.SCREEN_CYCLE_DECREE)

func _select_cycle_decree(decree_id: String) -> void:
	if campaign_cycle_index < 2 or str(campaign_profile.get("active_doctrine_id", "")) == "" or str(campaign_profile.get("active_decree_id", "")) != "":
		return
	var decree: Dictionary = DataRegistry.cycle_decree(decree_id)
	if decree.is_empty():
		return
	_apply_update2_cycle_choice_rewards(decree)
	campaign_profile["active_decree_id"] = decree_id
	var history: Array = campaign_profile.get("decree_history", [])
	history.append({"cycle": campaign_cycle_index, "decree_id": decree_id})
	campaign_profile["decree_history"] = history
	_sync_contract_reserves()
	SignalBus.resources_changed.emit()
	_log("%d회차 마왕 칙령 확정: %s · %s" % [campaign_cycle_index, str(decree.get("title", decree_id)), str(decree.get("effect_label", ""))])
	_set_screen(Constants.SCREEN_CHALLENGE_SEAL)

func _select_challenge_seal(seal_id: String) -> void:
	if campaign_cycle_index < 2 or str(campaign_profile.get("active_decree_id", "")) == "" or str(campaign_profile.get("active_challenge_seal_id", "")) != "":
		return
	var seal: Dictionary = DataRegistry.challenge_seal(seal_id)
	if seal.is_empty():
		return
	campaign_profile["active_challenge_seal_id"] = seal_id
	var history: Array = campaign_profile.get("challenge_seal_history", [])
	history.append({"cycle": campaign_cycle_index, "seal_id": seal_id, "completed": false})
	campaign_profile["challenge_seal_history"] = history
	_log("%d회차 도전 인장 확정: %s" % [campaign_cycle_index, str(seal.get("title", seal_id))])
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _apply_update2_cycle_choice_rewards(choice: Dictionary) -> void:
	GameState.add_rewards(choice.get("rewards", {}))
	var income: Dictionary = choice.get("income", {})
	GameState.gold_income += int(income.get("gold", 0))
	GameState.mana_income += int(income.get("mana", 0))
	GameState.food_income += int(income.get("food", 0))
	GameState.infamy_income += int(income.get("infamy", 0))
	var bond_gain := int(choice.get("bond_all", 0))
	if bond_gain > 0:
		for monster_id_value in monster_roster.keys():
			_grant_monster_bond(str(monster_id_value), bond_gain)
func _next_update2_cycle_setup_screen() -> String:
	if campaign_cycle_index < 2:
		return Constants.SCREEN_MANAGEMENT
	var mode_id := str(update4_active_run.get("campaign_mode_id", ""))
	if mode_id == SaveV4ToV5MigratorScript.MODE_NONE:
		return Constants.SCREEN_CAMPAIGN_MODE
	if mode_id == CampaignModeServiceScript.COUNCIL_MODE_ID:
		return Constants.SCREEN_MANAGEMENT
	if bool(update3_active_run.get("new_cycle_selection_pending", false)):
		return Constants.SCREEN_FRONT_SELECTION
	if bool(update3_active_run.get("front_selection_completed", false)) and str(update3_active_run.get("heart", {}).get("heart_id", "")) == "":
		return Constants.SCREEN_HEART_SELECTION
	if selected_contract_ids.size() != ContractRosterServiceScript.REQUIRED_CONTRACT_COUNT:
		return Constants.SCREEN_CONTRACT_BOARD
	if not bool(update3_active_run.get("duo_link_loadout_confirmed", false)):
		return Constants.SCREEN_DUO_LINK_LOADOUT
	if str(campaign_profile.get("active_doctrine_id", "")) == "":
		return Constants.SCREEN_CYCLE_DOCTRINE
	if str(campaign_profile.get("active_decree_id", "")) == "":
		return Constants.SCREEN_CYCLE_DECREE
	if str(campaign_profile.get("active_challenge_seal_id", "")) == "":
		return Constants.SCREEN_CHALLENGE_SEAL
	return Constants.SCREEN_MANAGEMENT

func _update2_cycle_effects() -> Dictionary:
	var result: Dictionary = {}
	for choice in [DataRegistry.cycle_doctrine(str(campaign_profile.get("active_doctrine_id", ""))), DataRegistry.cycle_decree(str(campaign_profile.get("active_decree_id", "")))]:
		var effects: Dictionary = choice.get("effects", {})
		for key_value in effects.keys():
			var key := str(key_value)
			var value = effects.get(key)
			if key.ends_with("_multiplier"):
				result[key] = float(result.get(key, 1.0)) * float(value)
			else:
				result[key] = float(result.get(key, 0.0)) + float(value)
	return result

func _update2_cycle_effect_value(key: String, fallback: float) -> float:
	return float(_update2_cycle_effects().get(key, fallback))

func _current_stage_deployment_limit() -> int:
	return ContractRosterServiceScript.stage_deployment_limit(castle_art_stage) + int(round(_update2_cycle_effect_value("deployment_limit_bonus", 0.0)))

func _current_skill_mana_cost(skill: Dictionary) -> int:
	return maxi(0, int(ceil(float(skill.get("cost_mana", 0)) * _update2_cycle_effect_value("skill_mana_cost_multiplier", 1.0))))
func _update2_soft_counter_strength(base_strength: float) -> float:
	var resistance := clampf(_update2_cycle_effect_value("soft_counter_resistance", 0.0), 0.0, 0.50)
	return minf(0.35, maxf(0.0, base_strength * (1.0 - resistance)))

func _resolve_update2_challenge_seal(win: bool) -> String:
	var seal_id := str(campaign_profile.get("active_challenge_seal_id", ""))
	if seal_id == "" or not win or not _is_regular_campaign_final_battle():
		return ""
	var seal: Dictionary = DataRegistry.challenge_seal(seal_id)
	if seal.is_empty():
		return ""
	var completed := _update2_challenge_seal_condition_met(seal)
	var history: Array = campaign_profile.get("challenge_seal_history", [])
	var already_completed := false
	for entry_value in history:
		if entry_value is Dictionary and int(entry_value.get("cycle", 0)) == campaign_cycle_index and str(entry_value.get("seal_id", "")) == seal_id:
			already_completed = already_completed or bool(entry_value.get("completed", false))
	if completed and not already_completed:
		for index in range(history.size() - 1, -1, -1):
			if history[index] is Dictionary and int(history[index].get("cycle", 0)) == campaign_cycle_index and str(history[index].get("seal_id", "")) == seal_id:
				history[index]["completed"] = true
				break
		campaign_profile["challenge_seal_history"] = history
		var reward: Dictionary = seal.get("reward", {})
		for key_value in reward.keys():
			var key := str(key_value)
			rewards_pending[key] = int(rewards_pending.get(key, 0)) + int(reward.get(key, 0))
		return "도전 인장 달성: %s · 악명 +%d" % [str(seal.get("title", seal_id)), int(reward.get("infamy", 0))]
	if already_completed:
		return "도전 인장: 이번 회차에서 이미 달성했습니다."
	return "도전 인장 미달: %s" % str(seal.get("title", seal_id))

func _update2_challenge_seal_condition_met(seal: Dictionary) -> bool:
	match str(seal.get("condition_id", "")):
		"no_throne_damage":
			return GameState.demon_lord_hp >= GameState.demon_lord_max_hp
		"no_monster_down":
			for monster in monster_units:
				if not is_instance_valid(monster) or not monster.is_alive():
					return false
			return not monster_units.is_empty()
		"low_mana":
			return GameState.mana <= int(seal.get("threshold", 80))
		"no_facility_disable":
			return facility_disables_this_battle <= 0
		"contract_vanguard":
			if selected_contract_ids.size() != ContractRosterServiceScript.REQUIRED_CONTRACT_COUNT:
				return false
			for contract_id_value in selected_contract_ids:
				var contract_id := str(contract_id_value)
				if not _monster_deployed_for_defense(contract_id):
					return false
				var survived := false
				for monster in monster_units:
					if is_instance_valid(monster) and str(monster.unit_id) == contract_id and monster.is_alive():
						survived = true
						break
				if not survived:
					return false
			return true
		"adaptive_rival":
			return int(combat_scene.update2_counter_activations.get("royal_strategist_evelyn", 0)) > 0
	return false

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
			return _mobile_instruction_text("노란 테두리 안의 [슬라임]을 클릭하세요.")
		"TUT_040_DEPLOY_SLIME":
			return _mobile_instruction_text("슬라임을 고른 다음, 노란 [입구 방]을 클릭하세요.")
		"TUT_050_GLOBAL_DEFEND":
			return _mobile_instruction_text("노란 테두리의 [사수] 버튼을 클릭하세요.")
		"TUT_090_RESULT_GROWTH":
			if _result_growth_choice_required() and not result_growth_choice_applied:
				return _mobile_instruction_text("노란 [집중 +8] 버튼을 먼저 클릭하세요.")
			return _mobile_instruction_text("노란 [성장 확인] 버튼을 클릭하세요.")
		"TUT_110_TRAP_CORRIDOR":
			return _mobile_instruction_text("노란 테두리의 [가시 복도]를 클릭하세요.")
		"TUT_120_TRAP_LURE":
			return _mobile_instruction_text("노란 테두리의 [함정 유도] 버튼을 클릭하세요.")
		"TUT_130_GOBLIN_CONTROL":
			return "고블린이 지시에 따라 도둑을 자동으로 추격·공격하는지 확인하세요."
		"TUT_210_RECOVERY_NEST":
			return _mobile_instruction_text("노란 테두리의 [회복 둥지]를 클릭하세요.")
		"TUT_220_RETREAT_LINE":
			return _mobile_instruction_text("노란 테두리의 [후퇴 지점] 버튼을 클릭하세요.")
		"TUT_230_IMP_FIREBALL":
			return "임프가 마력과 지시에 따라 화염구를 자동으로 사용하는지 확인하세요."
		"TUT_240_BOSS_HP":
			return "보스 체력이 절반이 될 때까지 공격하세요."
	return _mobile_instruction_text(str(line.get("text", "")).replace("{{player_name}}", _onboarding_player_name()))

func _mobile_instruction_text(text: String) -> String:
	if not UISettings.is_touch_ui():
		return text
	return text.replace("마우스 오른쪽 버튼으로 클릭", "한 번 탭").replace("우클릭", "탭").replace("클릭", "탭")

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
	if _update4_council_mode_active():
		var council_info := CouncilSeasonServiceScript.definition_for_day(DataRegistry.update4_council_campaign_days, target_day)
		if council_info.is_empty():
			return {}
		council_info["summary"] = str(council_info.get("story_beat", ""))
		council_info["management_hint"] = "%s · %s" % [str(council_info.get("title", "의회 일정")), str(council_info.get("story_beat", ""))]
		council_info["management_only_start_label"] = "일정 확정"
		council_info["management_only_prompt"] = "오늘은 전투 없이 의회 준비를 확정합니다."
		council_info["final_battle"] = target_day == CouncilSeasonServiceScript.FINAL_DAY
		return council_info
	if DataRegistry.has_method("campaign_day"):
		var base_info: Dictionary = DataRegistry.campaign_day(target_day).duplicate(true)
		if target_day == 29:
			return _update3_finale_eve_day_info(base_info)
		return base_info
	return {}


func _update4_council_mode_active() -> bool:
	return str(update4_active_run.get("campaign_mode_id", "")) == CampaignModeServiceScript.COUNCIL_MODE_ID


func _update4_region_selection_pending() -> bool:
	return _update4_council_mode_active() and RegionRouteServiceScript.selection_pending(update4_active_run, GameState.day)


func _update4_outpost_setup_pending() -> bool:
	return _update4_council_mode_active() and OutpostServiceScript.setup_pending(update4_active_run, GameState.day)


func _update4_upper_layout_pending() -> bool:
	if not _update4_council_mode_active() or GameState.day < 16:
		return false
	var upper: Dictionary = update4_active_run.get("upper_floor", {})
	return bool(upper.get("unlocked", false)) and str(upper.get("layout_id", "")) == ""


func _update4_required_choice_id() -> String:
	if not _update4_council_mode_active():
		return ""
	return Update4CampaignRuntimeScript.required_choice_id(update4_active_run, GameState.day)


func _update4_required_choice_pending() -> bool:
	return _update4_required_choice_id() != ""


func _update4_management_only_setup_screen() -> String:
	if not _update4_council_mode_active():
		return ""
	if _update4_region_selection_pending():
		return Constants.SCREEN_REGION_SELECTION
	if _update4_outpost_setup_pending():
		return Constants.SCREEN_OUTPOST_MANAGEMENT
	return ""


func _build_update4_required_choice_overlay() -> void:
	var action_id := _update4_required_choice_id()
	if action_id not in ["council_vote", "crown_choice", "council_final_declaration"]:
		return
	var overlay = Update4CouncilDecisionOverlayScript.new()
	overlay.name = "Update4CouncilDecisionOverlay"
	ui_layer.add_child(overlay)
	overlay.setup(action_id, GameState.day, update4_active_run, {
		"council_agendas": DataRegistry.update4_council_agendas,
		"rival_lords": DataRegistry.update4_rival_lords,
		"crown_evolutions": DataRegistry.update4_crown_evolutions
	}, _update4_crown_candidates(), update2_cycle_seed if update2_cycle_seed > 0 else campaign_cycle_index * 1009)
	overlay.vote_confirmed.connect(_commit_update4_council_vote)
	overlay.crown_confirmed.connect(_confirm_update4_crown)
	overlay.crown_declined.connect(_decline_update4_crown)
	overlay.final_declaration_confirmed.connect(_commit_update4_final_declaration)


func _update4_crown_candidates() -> Array:
	var roster_instances: Array = []
	for species_id_value in monster_roster.keys():
		var species_id := str(species_id_value)
		var instance_id := ContractRosterServiceScript.instance_id_for_species(species_id, DataRegistry.monster_instances)
		if instance_id == "":
			continue
		var instance: Dictionary = DataRegistry.monster_instances.get(instance_id, {}).duplicate(true)
		var roster: Dictionary = monster_roster.get(species_id, {})
		instance["instance_id"] = instance_id
		instance["species_id"] = species_id
		instance["level"] = int(roster.get("level", instance.get("level", 1)))
		instance["bond"] = int(roster.get("bond", instance.get("bond", 0)))
		instance["specialization_id"] = str(roster.get("specialization_id", instance.get("specialization_id", "")))
		instance["evolution_id"] = str(roster.get("promotion_id", roster.get("evolution_id", instance.get("evolution_id", ""))))
		instance["growth_stage"] = int(roster.get("growth_stage", 1 if str(instance.get("evolution_id", "")) != "" else instance.get("growth_stage", 0)))
		roster_instances.append(instance)
	var mastery: Dictionary = update4_profile.get("crown_evolution", {}).get("species_mastery", {})
	return CrownEvolutionServiceScript.eligible_candidates(roster_instances, DataRegistry.update4_crown_evolutions, update4_active_run.get("council_season", {}), mastery)


func _update4_crown_instance(instance_id: String) -> Dictionary:
	var instance: Dictionary = DataRegistry.monster_instances.get(instance_id, {}).duplicate(true)
	var species_id := str(instance.get("species_id", ""))
	if species_id == "" or not monster_roster.has(species_id):
		return {}
	var roster: Dictionary = monster_roster.get(species_id, {})
	instance["instance_id"] = instance_id
	instance["species_id"] = species_id
	instance["level"] = int(roster.get("level", instance.get("level", 1)))
	instance["bond"] = int(roster.get("bond", instance.get("bond", 0)))
	instance["specialization_id"] = str(roster.get("specialization_id", instance.get("specialization_id", "")))
	instance["evolution_id"] = str(roster.get("promotion_id", roster.get("evolution_id", instance.get("evolution_id", ""))))
	instance["growth_stage"] = int(roster.get("growth_stage", 1 if str(instance.get("evolution_id", "")) != "" else instance.get("growth_stage", 0)))
	return instance


func _commit_update4_council_vote(agenda_id: String, choice_id: String) -> void:
	if _update4_required_choice_id() != "council_vote":
		return
	var result := CouncilVoteLedgerScript.record_empty_vote(update4_active_run, agenda_id, choice_id, GameState.day, DataRegistry.update4_council_agendas, DataRegistry.update4_rival_lords)
	if not bool(result.get("ok", false)):
		_log(str(result.get("error", "의회 표결을 기록하지 못했습니다.")))
		return
	update4_active_run = result.get("active_run", update4_active_run).duplicate(true)
	var record: Dictionary = result.get("record", {})
	update4_active_run = CouncilVoteLedgerScript.apply_vote_outcome(update4_active_run, record, DataRegistry.update4_council_balance)
	var agenda: Dictionary = DataRegistry.update4_council_agendas.get(agenda_id, {})
	for rival_id_value in DataRegistry.update4_rival_lords.keys():
		var rival_id := str(rival_id_value)
		var delta := 0
		if rival_id in agenda.get("preferred_rival_ids", []):
			delta = 8 if choice_id == "approve" else (4 if choice_id == "amend" else -6)
		elif rival_id in agenda.get("disliked_rival_ids", []):
			delta = -4 if choice_id == "approve" else (0 if choice_id == "amend" else 4)
		if delta != 0:
			var relation_result := RivalLordServiceScript.change_relation(update4_active_run, rival_id, delta, DataRegistry.update4_rival_lords)
			update4_active_run = relation_result.get("active_run", update4_active_run).duplicate(true)
	_log("의회 표결 확정 · %s · %s · %s" % [str(agenda.get("display_name", agenda_id)), {"approve": "찬성", "amend": "수정안", "reject": "반대"}.get(choice_id, choice_id), "통과" if bool(record.get("passed", false)) else "부결"])
	_write_campaign_v2_snapshot()
	_set_screen(Constants.SCREEN_MANAGEMENT)


func _confirm_update4_crown(instance_id: String, crown_id: String) -> void:
	if _update4_required_choice_id() != "crown_choice":
		return
	var instance := _update4_crown_instance(instance_id)
	var mastery: Dictionary = update4_profile.get("crown_evolution", {}).get("species_mastery", {})
	var result := CrownEvolutionServiceScript.confirm(update4_active_run, instance, crown_id, DataRegistry.update4_crown_evolutions, mastery)
	if not bool(result.get("ok", false)):
		_log("왕관 진화 조건을 충족하지 못했습니다: %s" % str(result.get("reason", "unknown")))
		return
	update4_active_run = result.get("active_run", update4_active_run).duplicate(true)
	update4_active_run["crown"] = {"selected_instance_id": instance_id, "crown_form_id": crown_id, "declined": false, "replacement_reward_id": ""}
	var event_result := CrownEvolutionServiceScript.complete_crown_event(update4_profile, update4_active_run, DataRegistry.update4_crown_events)
	if bool(event_result.get("ok", false)):
		update4_profile = event_result.get("profile", update4_profile).duplicate(true)
		update4_active_run = event_result.get("active_run", update4_active_run).duplicate(true)
	_log("왕관 진화 확정: %s" % str(DataRegistry.update4_crown_evolutions.get(crown_id, {}).get("display_name", crown_id)))
	_write_campaign_v2_snapshot()
	_set_screen(Constants.SCREEN_MANAGEMENT)


func _decline_update4_crown(option_id: String) -> void:
	if _update4_required_choice_id() != "crown_choice":
		return
	var result := CrownEvolutionServiceScript.decline(update4_active_run, option_id)
	if not bool(result.get("ok", false)):
		_log("왕관 대체 보상을 선택하지 못했습니다: %s" % str(result.get("reason", "unknown")))
		return
	update4_active_run = result.get("active_run", update4_active_run).duplicate(true)
	update4_active_run["crown"] = {"selected_instance_id": "", "crown_form_id": "", "declined": true, "replacement_reward_id": option_id}
	_log("왕관을 쓰지 않고 대체 보상을 확정했습니다: %s" % option_id)
	_write_campaign_v2_snapshot()
	_set_screen(Constants.SCREEN_MANAGEMENT)


func _commit_update4_final_declaration(choice_id: String) -> void:
	if _update4_required_choice_id() != "council_final_declaration":
		return
	if choice_id not in ["council_commitment", "delegate_the_crown", "keep_outpost_after_council", "reject_council_authority"]:
		return
	var council: Dictionary = update4_active_run.get("council_season", {}).duplicate(true)
	council["day29_decision_id"] = choice_id
	if choice_id == "reject_council_authority":
		council["independence"] = clampi(int(council.get("independence", 0)) + 25, 0, 100)
	update4_active_run["council_season"] = council
	_log("의회 전야 최종 선언: %s" % choice_id)
	_write_campaign_v2_snapshot()
	_set_screen(Constants.SCREEN_MANAGEMENT)


func _ensure_update4_representative_locked() -> bool:
	if not _update4_council_mode_active() or GameState.day < 24:
		return true
	var council: Dictionary = update4_active_run.get("council_season", {})
	if str(council.get("final_representative_id", "")) != "":
		return true
	var seed := update2_cycle_seed if update2_cycle_seed > 0 else campaign_cycle_index * 1009
	var result := Update4CampaignRuntimeScript.lock_representative(update4_active_run, DataRegistry.update4_rival_lords, DataRegistry.update4_regions, seed)
	if not bool(result.get("ok", false)):
		_log(str(result.get("error", "DAY 30 대표를 확정하지 못했습니다.")))
		return false
	update4_active_run = result.get("active_run", update4_active_run).duplicate(true)
	var notice := RivalLordServiceScript.day24_notice(update4_active_run, DataRegistry.update4_rival_lords)
	_log("DAY 30 의회 대표 확정: %s%s" % [str(notice.get("display_name", notice.get("rival_id", ""))), " · 지원 " + str(notice.get("support_name", "")) if str(notice.get("support_name", "")) != "" else ""])
	return true


func _update4_council_day_state() -> Dictionary:
	return update4_active_run.get("council_season", {}).get("day_state", CouncilSeasonServiceScript.new_day_state(GameState.day)).duplicate(true)


func _set_update4_council_day_state(state: Dictionary) -> void:
	var council: Dictionary = update4_active_run.get("council_season", {}).duplicate(true)
	council["day_state"] = CouncilSeasonServiceScript.normalize_day_state(state, GameState.day)
	update4_active_run["council_season"] = council


func _sync_update4_council_day_state() -> void:
	if not _update4_council_mode_active():
		return
	var state := CouncilSeasonServiceScript.normalize_day_state(_update4_council_day_state(), GameState.day)
	if int(state.get("current_day", 0)) != GameState.day:
		var started := CouncilSeasonServiceScript.start_day(state, GameState.day, DataRegistry.update4_council_campaign_days)
		if bool(started.get("ok", false)):
			state = started.get("state", {})
	_set_update4_council_day_state(state)


func _begin_update4_council_combat() -> bool:
	if not _update4_council_mode_active():
		return true
	if _update4_region_selection_pending():
		_log("DAY %d 전투 전에 의회 지역을 선택하세요." % GameState.day)
		_set_screen(Constants.SCREEN_REGION_SELECTION)
		return false
	if _update4_outpost_setup_pending():
		_log("전투 전에 DAY 4 전초기지를 건설하세요.")
		_set_screen(Constants.SCREEN_OUTPOST_MANAGEMENT)
		return false
	if _update4_upper_layout_pending():
		_log("DAY %d 전투 전에 상층 레이아웃을 확정하세요." % GameState.day)
		_set_screen(Constants.SCREEN_UPPER_FLOOR)
		return false
	if not _ensure_update4_representative_locked():
		return false
	var required_choice := _update4_required_choice_id()
	if required_choice in ["council_vote", "crown_choice"]:
		_log("DAY %d 전투 전에 의회 필수 결정을 확정하세요." % GameState.day)
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return false
	_sync_update4_council_day_state()
	var state := _update4_council_day_state()
	if str(state.get("phase", "")) == CouncilSeasonServiceScript.PHASE_MANAGEMENT:
		var ready := CouncilSeasonServiceScript.finish_management(state, DataRegistry.update4_council_campaign_days)
		if not bool(ready.get("ok", false)):
			_log(str(ready.get("error", "의회 관리 준비를 확정하지 못했습니다.")))
			return false
		state = ready.get("state", {})
	var started := CouncilSeasonServiceScript.begin_combat(state, DataRegistry.update4_council_campaign_days)
	if not bool(started.get("ok", false)):
		_log(str(started.get("error", "의회 전투에 진입할 수 없습니다.")))
		return false
	_set_update4_council_day_state(started.get("state", {}))
	return true


func _update3_finale_eve_day_info(base_info: Dictionary) -> Dictionary:
	var info := base_info.duplicate(true)
	var resolved := _update3_finale_eve_resolution()
	if resolved.is_empty():
		return info
	for key_value in resolved.get("day_info_overrides", {}).keys():
		info[str(key_value)] = resolved.get("day_info_overrides", {}).get(key_value)
	info["management_dialogue"] = resolved.get("dialogue", []).duplicate(true)
	var management_lines: Array[String] = []
	for line_value in resolved.get("dialogue", []):
		if line_value is Dictionary:
			var speaker_id := str(line_value.get("speaker", ""))
			var speaker_name := str(line_value.get("speaker_name", DataRegistry.character(speaker_id).get("display_name", speaker_id)))
			var text := str(line_value.get("text", ""))
			management_lines.append("%s: %s" % [speaker_name, text] if speaker_name != "" else text)
	info["management_lines"] = management_lines
	info["cast"] = resolved.get("cast", []).duplicate(true)
	info["final_rival_name"] = str(resolved.get("final_rival_name", ""))
	info["ending_hint"] = str(resolved.get("ending_hint", ""))
	return info


func _update3_finale_eve_resolution(eve_id: String = "") -> Dictionary:
	if not bool(update3_active_run.get("update3_enabled", false)):
		return {}
	var event_id := eve_id
	if event_id == "":
		var overlay := FrontCampaignServiceScript.overlay_day_entry(update3_active_run, 29, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays)
		event_id = str(overlay.get("eve_id", ""))
	var event := FrontCampaignServiceScript.event_definition(event_id, DataRegistry.update3_events)
	if event.is_empty():
		return {}
	var operation_id := str(update3_active_run.get("day28_front_operation", ""))
	if operation_id == "":
		var front_id := str(update3_active_run.get("front_id", ""))
		var choice_group := str(DataRegistry.update3_fronts.get(front_id, {}).get("day28_choice_group", ""))
		operation_id = _completed_raid_choice_id(choice_group)
	var operation: Dictionary = DataRegistry.update3_front_operations.get(operation_id, {}).duplicate(true)
	if operation.is_empty():
		operation = DataRegistry.raid_mission(operation_id).duplicate(true)
	if operation_id != "":
		operation["id"] = operation_id
	return FrontCampaignServiceScript.resolve_finale_eve(update3_active_run, update3_profile, event, DataRegistry.update3_castle_hearts, DataRegistry.update3_duo_links, operation)

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
	update3_active_run = HeartChamberServiceScript.sync_active_run(update3_active_run, _castle_stage_index())
	if not _update3_heart_chamber_should_spawn():
		rooms.erase(HeartChamberServiceScript.ROOM_ID)
	for stage_id_value in DataRegistry.castle_evolution_stage_ids():
		var stage_id := str(stage_id_value)
		if _castle_stage_index(stage_id) > _castle_stage_index():
			continue
		var addition: Dictionary = DataRegistry.castle_stage_expansion(stage_id)
		var added_rooms: Dictionary = addition.get("rooms", {})
		for room_id_value in added_rooms.keys():
			var room_id := str(room_id_value)
			if bool(added_rooms[room_id].get("update3_only", false)) and not _update3_heart_chamber_should_spawn():
				continue
			if not rooms.has(room_id):
				rooms[room_id] = added_rooms[room_id].duplicate(true)
	_apply_castle_stage_room_upgrades()
	_apply_update3_dream_max_hp()
	if _update3_heart_chamber_should_spawn():
		rooms[HeartChamberServiceScript.ROOM_ID] = HeartChamberServiceScript.room_definition(update3_active_run, _castle_stage_index())

func _apply_castle_stage_room_upgrades() -> void:
	var info := _castle_stage_info()
	var desired_hp_bonus := int(info.get("facility_hp_bonus", 0))
	var desired_capacity_bonus := int(info.get("facility_capacity_bonus", 0))
	for room_id_value in rooms.keys():
		var room_id := str(room_id_value)
		var room: Dictionary = rooms[room_id]
		var facility_id := str(room.get("facility_role", ""))
		if facility_id in ["", "entry", "trap", "corridor", "core", "build_slot", "heart_chamber"]:
			room["castle_stage_level"] = _castle_stage_index()
			continue
		var applied_hp_bonus := int(room.get("castle_stage_hp_bonus", 0))
		var applied_capacity_bonus := int(room.get("castle_stage_capacity_bonus", 0))
		room["hp"] = max(1, int(room.get("hp", 1)) + desired_hp_bonus - applied_hp_bonus)
		room["max_monsters"] = max(1, int(room.get("max_monsters", 1)) + desired_capacity_bonus - applied_capacity_bonus)
		room["castle_stage_hp_bonus"] = desired_hp_bonus
		room["castle_stage_capacity_bonus"] = desired_capacity_bonus
		room["castle_stage_level"] = _castle_stage_index()
	var base_desired_throne_hp := int(info.get("throne_max_hp", GameState.demon_lord_max_hp))
	var desired_throne_hp := base_desired_throne_hp
	var heart: Dictionary = update3_active_run.get("heart", {})
	if str(heart.get("heart_id", "")) == CastleHeartServiceScript.DREAM_LANTERN_ID and bool(heart.get("awakened", false)):
		if int(heart.get("dream_base_throne_max_hp", 0)) == base_desired_throne_hp and int(heart.get("dream_adjusted_throne_max_hp", 0)) > 0:
			desired_throne_hp = int(heart.get("dream_adjusted_throne_max_hp", base_desired_throne_hp))
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
	var target_day := GameState.day if day <= 0 else day
	var overlay := FrontCampaignServiceScript.overlay_day_entry(update3_active_run, target_day, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays)
	var operation_group := str(overlay.get("operation_group", ""))
	if operation_group != "":
		return operation_group
	return str(_campaign_day_info(day).get("required_raid_choice_group", ""))

func _campaign_required_raid_choice_label(day: int = 0) -> String:
	if _campaign_required_raid_choice_group(day) == "day28_holy_purification":
		return "성광 최종 작전"
	if _campaign_required_raid_choice_group(day) == "day28_guild_repossession":
		return "길드 장부 대응 작전"
	return str(_campaign_day_info(day).get("required_raid_choice_label", "원정 선택"))

func _campaign_required_raid_choice_start_label(day: int = 0) -> String:
	if _campaign_required_raid_choice_group(day) == "day28_holy_purification":
		return "작전 확정 후 방어"
	if _campaign_required_raid_choice_group(day) == "day28_guild_repossession":
		return "장부 대응 확정 후 방어"
	return str(_campaign_day_info(day).get("required_raid_choice_start_label", "원정 선택 후 전투"))

func _campaign_required_raid_choice_prompt(day: int = 0) -> String:
	if _campaign_required_raid_choice_group(day) == "day28_holy_purification":
		return "[성광 최종 작전]에서 DAY 30에 적용할 대응 하나를 확정하세요."
	if _campaign_required_raid_choice_group(day) == "day28_guild_repossession":
		return "[길드 장부 대응 작전]에서 DAY 30에 적용할 계획 하나를 확정하세요."
	return str(_campaign_day_info(day).get("required_raid_choice_prompt", "[원정 선택]에서 오늘 계획 하나를 먼저 확정하세요."))

func _campaign_required_raid_choice_log(day: int = 0) -> String:
	if _campaign_required_raid_choice_group(day) == "day28_holy_purification":
		return "DAY 28 방어 전에 성물 목록 바꿔치기와 순례길 열어두기 중 하나를 확정하세요."
	if _campaign_required_raid_choice_group(day) == "day28_guild_repossession":
		return "DAY 28 방어 전에 자산 장부 위조와 용병 급여 차단 중 하나를 확정하세요."
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
	_apply_update3_front_day_entry(day)
	var info = _campaign_day_info(day)
	if info.is_empty():
		return
	if bool(info.get("facility_upgrade_unlocked", false)):
		facility_upgrade_unlocked = true
	_ensure_update2_leon_adaptation(day)
	if campaign_seen_day_intros.has(day):
		return
	campaign_seen_day_intros[day] = true
	_apply_update2_seeded_event(day)
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
	_apply_update3_front_combat_entry(day)
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


func _apply_update3_front_day_entry(day: int) -> void:
	if FrontCampaignServiceScript.day_content_seen(update3_active_run, day):
		return
	var entry := FrontCampaignServiceScript.overlay_day_entry(update3_active_run, day, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays)
	if entry.is_empty():
		return
	for line_value in entry.get("management_lines", []):
		_log(str(line_value))
	var seen_event_ids: Array = []
	for event_id_value in entry.get("event_ids", []):
		var event_id := str(event_id_value)
		var event := FrontCampaignServiceScript.event_definition(event_id, DataRegistry.update3_events)
		if event.is_empty():
			continue
		_log("전선 사건 예고 · %s: %s" % [str(event.get("display_name", event_id)), str(event.get("text", ""))])
		seen_event_ids.append(event_id)
	var heart_event := FrontCampaignServiceScript.selected_heart_event(update3_active_run, entry, DataRegistry.update3_events)
	if not heart_event.is_empty():
		var heart_event_id := str(update3_active_run.get("heart_event_candidate_id", ""))
		_log("이번 회차의 심장 사건 · %s: %s" % [str(heart_event.get("display_name", heart_event_id)), str(heart_event.get("text", ""))])
		seen_event_ids.append(heart_event_id)
	var eve_id := str(entry.get("eve_id", ""))
	if eve_id != "":
		var eve_line := _update3_finale_eve_summary_line(eve_id)
		if eve_line != "":
			_log(eve_line)
		seen_event_ids.append(eve_id)
	update3_active_run = FrontCampaignServiceScript.mark_day_content_seen(update3_active_run, day, seen_event_ids)


func _apply_update3_front_combat_entry(day: int) -> void:
	var combat_flag := "day_%d_combat_seen" % day
	var flags: Dictionary = update3_active_run.get("front_flags", {})
	if bool(flags.get(combat_flag, false)):
		return
	var entry := FrontCampaignServiceScript.overlay_day_entry(update3_active_run, day, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays)
	var combat_lines: Array = entry.get("combat_start_lines", [])
	if combat_lines.is_empty():
		return
	for line_value in combat_lines:
		_log(str(line_value))
	flags = flags.duplicate(true)
	flags[combat_flag] = true
	update3_active_run["front_flags"] = flags


func _update3_finale_eve_summary_line(eve_id: String) -> String:
	var resolved := _update3_finale_eve_resolution(eve_id)
	if resolved.is_empty():
		return ""
	return "결전 전야 · 심장 %s · 합동기 %s · 작전 %s · %s 관계 %d. %s" % [
		str(resolved.get("heart_name", "심장 미선택")),
		str(resolved.get("duo_name", "합동기 미장착")),
		str(resolved.get("operation_name", "DAY 28 작전 미확정")),
		str(resolved.get("final_rival_name", "")),
		int(resolved.get("relation", 0)),
		str(resolved.get("summary_line", ""))
	]


func _pending_update3_event_ids() -> Array[String]:
	var result: Array[String] = []
	var entry := FrontCampaignServiceScript.overlay_day_entry(update3_active_run, GameState.day, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays)
	for event_id_value in entry.get("event_ids", []):
		result.append(str(event_id_value))
	var heart_event := FrontCampaignServiceScript.selected_heart_event(update3_active_run, entry, DataRegistry.update3_events)
	if not heart_event.is_empty():
		result.append(str(update3_active_run.get("heart_event_candidate_id", "")))
	for event_id in DuoLinkServiceScript.eligible_memory_event_ids(update3_profile, update3_active_run, _update3_duo_member_progress(), DataRegistry.update3_duo_links):
		result.append(event_id)
	var flags: Dictionary = update3_active_run.get("front_flags", {})
	var pending: Array[String] = []
	for event_id in result:
		if event_id != "" and str(flags.get("event_%s_choice" % event_id, "")) == "":
			pending.append(event_id)
	return pending


func _show_update3_event_choice_overlay() -> void:
	if ui_layer == null or hud == null or current_screen != Constants.SCREEN_MANAGEMENT:
		return
	var existing := ui_layer.get_node_or_null("Update3EventChoiceOverlay")
	if existing != null:
		existing.queue_free()
	var pending := _pending_update3_event_ids()
	if pending.is_empty():
		return
	var event_id := pending[0]
	var event := FrontCampaignServiceScript.event_definition(event_id, DataRegistry.update3_events)
	if event.is_empty():
		return
	var overlay = hud.panel(Rect2(0, 0, 1920, 1080), Color("#07060bd9"), Color("#00000000"), "", "flat")
	overlay.name = "Update3EventChoiceOverlay"
	overlay.z_index = 700
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var card = hud.child_panel(overlay, Rect2(460, 170, 1000, 740), Color("#17131ff8"), Color("#d7b45a"), 2)
	hud.label(card, "성광 전선 사건 · DAY %02d" % GameState.day, Vector2(70, 48), Vector2(860, 36), 20, Color("#d7b45a"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(card, str(event.get("display_name", event_id)), Vector2(70, 104), Vector2(860, 64), 34, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
	hud.rich_label(card, str(event.get("text", "")), Vector2(100, 190), Vector2(800, 128), 21, Color("#ddd5e5"), UIFontScript.ROLE_DIALOGUE, TextServer.AUTOWRAP_WORD_SMART, VERTICAL_ALIGNMENT_CENTER)
	var choices: Array = event.get("choices", [])
	for index in range(mini(choices.size(), 3)):
		var choice: Dictionary = choices[index]
		var choice_id := str(choice.get("id", ""))
		var button = hud.button(card, str(choice.get("label", choice_id)), Rect2(130, 350 + index * 96, 740, 68), Callable(self, "_choose_update3_event").bind(event_id, choice_id), 20, "Update3EventChoiceButton_%d" % index)
		button.tooltip_text = _update3_event_effect_label(choice.get("effects", {}))
	hud.label(card, "선택은 이번 회차에 저장되며 다시 고를 수 없습니다.", Vector2(100, 660), Vector2(800, 34), 16, Color("#aaa2b6"), HORIZONTAL_ALIGNMENT_CENTER)


func _update3_event_effect_label(effects_value) -> String:
	if not (effects_value is Dictionary):
		return ""
	var effects: Dictionary = effects_value
	var parts: Array[String] = []
	for rival_id in ["leon", "selen", "roman"]:
		var relation_key := "relation_%s" % rival_id
		if effects.has(relation_key):
			var rival_name := str({"leon": "레온", "selen": "셀렌", "roman": "로만"}.get(rival_id, rival_id))
			parts.append("%s 관계 %+d" % [rival_name, int(effects.get(relation_key, 0))])
	for key in ["gold", "mana", "food", "infamy"]:
		if int(effects.get(key, 0)) != 0:
			parts.append("%s %+d" % [key, int(effects.get(key, 0))])
	return " / ".join(parts)


func _choose_update3_event(event_id: String, choice_id: String) -> void:
	var result := FrontCampaignServiceScript.apply_event_choice(update3_profile, update3_active_run, event_id, choice_id, GameState.day, DataRegistry.update3_events)
	if not bool(result.get("ok", false)):
		_log(str(result.get("error", "사건 선택을 적용하지 못했습니다.")))
		return
	update3_profile = result.get("profile", update3_profile).duplicate(true)
	update3_active_run = result.get("active_run", update3_active_run).duplicate(true)
	if str(DataRegistry.update3_events.get(event_id, {}).get("kind", "")) == "duo_memory":
		var memory_result := DuoLinkServiceScript.complete_memory_event(update3_profile, event_id, DataRegistry.update3_duo_links)
		if not bool(memory_result.get("ok", false)):
			_log(str(memory_result.get("error", "합동 기억을 해금하지 못했습니다.")))
			return
		update3_profile = memory_result.get("profile", update3_profile).duplicate(true)
		_record_update3_metric_count("new_duo_memories_this_run", 1)
		_log("합동 기억 해금 · %s" % str(DataRegistry.update3_duo_links.get(str(memory_result.get("link_id", "")), {}).get("display_name", "")))
	_apply_update3_event_resource_effects(result.get("effects", {}))
	var choice: Dictionary = result.get("choice", {})
	_log("전선 사건 선택 · %s" % str(choice.get("label", choice_id)))
	_set_screen(Constants.SCREEN_MANAGEMENT)


func _apply_update3_event_resource_effects(effects_value) -> void:
	if not (effects_value is Dictionary):
		return
	var effects: Dictionary = effects_value
	GameState.gold = maxi(0, GameState.gold + int(effects.get("gold", 0)))
	GameState.mana = maxi(0, GameState.mana + int(effects.get("mana", 0)))
	GameState.food = maxi(0, GameState.food + int(effects.get("food", 0)))
	GameState.infamy = maxi(0, GameState.infamy + int(effects.get("infamy", 0)))
	SignalBus.resources_changed.emit()

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
	if _update4_council_mode_active():
		_apply_update4_campaign_result_flags(win)
		return
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
	_accumulate_update3_campaign_metrics(security_grade)
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
		update3_profile = CastleHeartServiceScript.record_campaign_clear(update3_profile, update3_active_run)
		update3_profile = FrontCampaignServiceScript.record_front_clear(update3_profile, update3_active_run, DataRegistry.update3_fronts)
		_record_final_run_metrics()
		_sync_update3_leon_relation()
		_resolve_campaign_ending()
		update3_profile = FrontCampaignServiceScript.apply_ending_rewards(update3_profile, update3_active_run, resolved_campaign_ending_id, DataRegistry.update3_endings)
		_sync_update3_reward_monsters()
		update3_profile = ChronicleServiceScript.record_run_summary(update3_profile, update3_active_run, campaign_cycle_index, resolved_campaign_ending_id, DataRegistry.ending_rules, DataRegistry.update3_fronts)
	_apply_castle_evolution_for_day(GameState.day)


func _apply_update4_campaign_result_flags(win: bool) -> void:
	_record_update4_battle_metrics()
	if GameState.day in Update4CampaignRuntimeScript.RIVAL_BATTLE_DAYS:
		var boss_result := Update4CampaignRuntimeScript.resolve_rival_battle(update4_active_run, GameState.day, win, DataRegistry.update4_rival_lords, {
			"facility_damage": facility_disables_this_battle,
			"walls_destroyed": 0,
			"seal_channels_completed": int(update4_active_run.get("upper_floor", {}).get("seal_theft_count", 0)),
			"floor_transitions": 0,
			"gardens_cleansed": 0,
			"roots_destroyed": 0
		})
		update4_active_run = boss_result.get("active_run", update4_active_run).duplicate(true)
	if not win:
		if _is_regular_campaign_final_battle():
			campaign_final_battle_outcome = "defeat"
			campaign_finale_defeat_seen = true
		return
	var settlement_slot := Update4CampaignRuntimeScript.settlement_slot_for_day(GameState.day)
	if settlement_slot > 0:
		_settle_update4_region_chapter(settlement_slot)
	if not _is_regular_campaign_final_battle():
		return
	campaign_completed = true
	campaign_final_battle_outcome = "victory"
	_finalize_update4_council_ending()


func _finalize_update4_council_ending() -> void:
	var upper: Dictionary = update4_active_run.get("upper_floor", {})
	var crown: Dictionary = update4_active_run.get("crown", {})
	var crown_instance_id := str(crown.get("selected_instance_id", ""))
	var crown_species_id := str(DataRegistry.monster_instances.get(crown_instance_id, {}).get("species_id", ""))
	var total_contribution := 0.0
	for contribution_value in battle_contribution_stats.values():
		if contribution_value is Dictionary:
			total_contribution += float(contribution_value.get("damage_dealt", 0)) + float(contribution_value.get("damage_absorbed", 0)) + float(contribution_value.get("facility_value", 0))
	var crown_contribution := 0.0
	if battle_contribution_stats.get(crown_species_id) is Dictionary:
		var crown_stats: Dictionary = battle_contribution_stats.get(crown_species_id, {})
		crown_contribution = float(crown_stats.get("damage_dealt", 0)) + float(crown_stats.get("damage_absorbed", 0)) + float(crown_stats.get("facility_value", 0))
	var other_contributors := 0
	if total_contribution > 0.0:
		for species_id_value in battle_contribution_stats.keys():
			if str(species_id_value) == crown_species_id or not (battle_contribution_stats.get(species_id_value) is Dictionary):
				continue
			var stats: Dictionary = battle_contribution_stats.get(species_id_value, {})
			var value := float(stats.get("damage_dealt", 0)) + float(stats.get("damage_absorbed", 0)) + float(stats.get("facility_value", 0))
			if value / total_contribution >= 0.08:
				other_contributors += 1
	var lower_survivors := 0
	var upper_survivors := 0
	var entities: Dictionary = upper.get("graph_runtime", {}).get("entities", {})
	var alive_by_species := {}
	for monster in monster_units:
		if is_instance_valid(monster):
			alive_by_species[str(monster.unit_id)] = monster.is_alive()
	for entity_id_value in entities.keys():
		var entity_value = entities.get(entity_id_value)
		if not (entity_value is Dictionary) or str(entity_value.get("faction", "")) != "monster" or not bool(alive_by_species.get(str(entity_id_value), false)):
			continue
		if str(entity_value.get("floor_id", "1F")) == "2F":
			upper_survivors += 1
		else:
			lower_survivors += 1
	if entities.is_empty():
		for monster in monster_units:
			if is_instance_valid(monster) and monster.is_alive():
				lower_survivors += 1
	var crown_max_hp := UpperFloorObjectiveServiceScript.crown_max_hp(DataRegistry.update4_upper_floor_modules, _castle_stage_index())
	var upper_integrity := 100.0 * float(upper.get("objective_hp", {}).get("crown_sanctum", 0)) / float(maxi(1, crown_max_hp))
	var crown_survived := false
	for monster in monster_units:
		if is_instance_valid(monster) and str(monster.unit_id) == crown_species_id and monster.is_alive():
			crown_survived = true
			break
	var context := {
		"final_battle_won": true,
		"cycle_index": campaign_cycle_index,
		"completed_region_ids": RegionRouteServiceScript.selected_region_ids(update4_active_run),
		"upper_floor_integrity": upper_integrity,
		"day30_upper_floor_contribution_ratio": float(upper_survivors) / float(maxi(1, lower_survivors + upper_survivors)),
		"day30_lower_survivor_count": lower_survivors,
		"day30_upper_survivor_count": upper_survivors,
		"crown_evolution_used": str(crown.get("crown_form_id", "")) != "",
		"crown_monster_bond": float(monster_roster.get(crown_species_id, {}).get("bond", 0)),
		"day30_crown_monster_survived": crown_survived,
		"day30_crown_contribution_ratio": crown_contribution / maxf(1.0, total_contribution),
		"day30_other_contributors_eight_percent": other_contributors,
		"crown_or_seal_replacement_used": str(crown.get("crown_form_id", "")) != "" or str(crown.get("replacement_reward_id", "")) != ""
	}
	var finalized := CouncilEndingServiceScript.finalize_day30(update4_profile, update4_active_run, context, DataRegistry.update4_council_endings, {
		"regions": DataRegistry.update4_regions,
		"rival_lords": DataRegistry.update4_rival_lords,
		"rival_letters": DataRegistry.update4_rival_letters,
		"crown_evolutions": DataRegistry.update4_crown_evolutions
	})
	update4_profile = finalized.get("profile", update4_profile).duplicate(true)
	update4_active_run = finalized.get("active_run", update4_active_run).duplicate(true)
	resolved_campaign_ending_id = str(finalized.get("ending_id", CouncilEndingServiceScript.LOCAL_FALLBACK_ID))
	_record_update4_ending_archive(resolved_campaign_ending_id)


func _record_update4_ending_archive(ending_id: String) -> void:
	if ending_id == "" or ending_id == CouncilEndingServiceScript.LOCAL_FALLBACK_ID:
		return
	var archive: Dictionary = campaign_profile.get("ending_archive", {}).duplicate(true)
	var entry: Dictionary = archive.get(ending_id, {}).duplicate(true)
	if entry.is_empty():
		entry = {"first_seen_cycle": campaign_cycle_index, "seen_count": 0}
	entry["seen_count"] = int(entry.get("seen_count", 0)) + 1
	entry["last_seen_cycle"] = campaign_cycle_index
	archive[ending_id] = entry
	campaign_profile["ending_archive"] = archive


func _accumulate_update3_campaign_metrics(security_grade: String) -> void:
	if not bool(update3_active_run.get("update3_enabled", false)):
		return
	var metrics: Dictionary = update3_active_run.get("run_metrics_update3", {}).duplicate(true)
	var recorded_days: Array = metrics.get("campaign_metric_days_recorded", []).duplicate()
	if recorded_days.has(GameState.day):
		return
	recorded_days.append(GameState.day)
	metrics["campaign_metric_days_recorded"] = recorded_days
	if treasure_gold_stolen_this_battle > 0:
		metrics["campaign_treasure_losses"] = int(metrics.get("campaign_treasure_losses", 0)) + 1
	metrics["facility_disable_count"] = int(metrics.get("facility_disable_count", 0)) + maxi(0, facility_disables_this_battle)
	metrics["holy_seals_interrupted"] = int(metrics.get("holy_seals_interrupted", 0)) + maxi(0, int(combat_scene.seal_chain_interruptions))
	metrics["debt_marks_cleansed"] = int(metrics.get("debt_marks_cleansed", 0)) + maxi(0, int(combat_scene.ledger_marks_cleansed))
	metrics["selen_mercy_vulnerable_successes"] = int(metrics.get("selen_mercy_vulnerable_successes", 0)) + maxi(0, int(combat_scene.selen_barrier_breaks_in_window))
	var security_values := {"S": 4, "A": 3, "C": 2, "D": 1}
	if security_values.has(security_grade):
		metrics["security_grade_total"] = int(metrics.get("security_grade_total", 0)) + int(security_values[security_grade])
		metrics["security_grade_count"] = int(metrics.get("security_grade_count", 0)) + 1
	var battle_total := 0
	var contribution_by_species: Dictionary = metrics.get("campaign_monster_contribution_by_species", {}).duplicate(true)
	for species_id_value in battle_contribution_stats.keys():
		var contribution_value = battle_contribution_stats.get(species_id_value)
		if not (contribution_value is Dictionary):
			continue
		var contribution: Dictionary = contribution_value
		var species_total := 0
		species_total += maxi(0, int(contribution.get("damage_dealt", 0)))
		species_total += maxi(0, int(contribution.get("damage_absorbed", 0)))
		species_total += maxi(0, int(contribution.get("facility_value", 0)))
		species_total += maxi(0, int(contribution.get("finishing_blows", 0))) * 50
		battle_total += species_total
		var species_id := str(species_id_value)
		contribution_by_species[species_id] = int(contribution_by_species.get(species_id, 0)) + species_total
	metrics["campaign_monster_contribution"] = int(metrics.get("campaign_monster_contribution", 0)) + battle_total
	metrics["campaign_monster_contribution_by_species"] = contribution_by_species
	if GameState.day == REGULAR_CAMPAIGN_FINAL_DAY:
		var down_count := 0
		for monster in monster_units:
			if is_instance_valid(monster) and not monster.is_alive():
				down_count += 1
		metrics["day30_down_count"] = down_count
		metrics["roman_final_phase_entry_budget"] = int(combat_scene.roman_final_phase_entry_budget)
	update3_active_run["run_metrics_update3"] = metrics

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
	var catalog := _active_wave_catalog(day)
	if not catalog.has(key):
		return false
	var entries = catalog.get(key, [])
	return entries is Array and not entries.is_empty()


func _active_wave_catalog(day: int = 0) -> Dictionary:
	var target_day := GameState.day if day <= 0 else day
	if not _update4_council_mode_active():
		return DataRegistry.waves
	return Update4CampaignRuntimeScript.wave_catalog_for_day(update4_active_run, target_day, DataRegistry.update4_council_wave_templates, DataRegistry.update4_rival_lords, DataRegistry.waves)


func _record_update4_battle_metrics() -> void:
	if not _update4_council_mode_active():
		return
	var down_count := 0
	for monster in monster_units:
		if is_instance_valid(monster) and not monster.is_alive():
			down_count += 1
	update4_active_run = Update4CampaignRuntimeScript.record_battle_metrics(update4_active_run, GameState.day, {
		"facility_disables": facility_disables_this_battle,
		"treasure_loss": treasure_gold_stolen_this_battle,
		"seal_thefts": int(update4_active_run.get("upper_floor", {}).get("seal_theft_count", 0)),
		"down_count": down_count,
		"distinct_duo_links": update3_active_run.get("run_metrics_update3", {}).get("link_skills_used_campaign", []).size(),
		"security_grade": _current_security_grade()
	})


func _settle_update4_region_chapter(slot: int) -> void:
	if not _update4_council_mode_active() or slot <= 0:
		return
	var result := Update4CampaignRuntimeScript.settle_region_chapter(update4_profile, update4_active_run, slot, DataRegistry.update4_regions)
	if not bool(result.get("ok", false)):
		return
	update4_profile = result.get("profile", update4_profile).duplicate(true)
	update4_active_run = result.get("active_run", update4_active_run).duplicate(true)
	var region_id := str(result.get("region_id", ""))
	_log("지역 헌장 정산 · %s · %s" % [str(DataRegistry.update4_regions.get(region_id, {}).get("display_name", region_id)), "의회 인장 획득" if bool(result.get("charter_completed", false)) else "헌장 미달 · 대체 인장 획득"])

func _enter_campaign_management_day(show_intro: bool = true) -> void:
	if _update4_council_mode_active():
		update4_active_run = OutpostEncounterServiceScript.apply_day_start_recovery(update4_active_run, GameState.day)
		update4_active_run = MultiFloorGraphServiceScript.unlock_if_due(update4_active_run, GameState.day)
		update4_active_run = UpperFloorObjectiveServiceScript.repair_next_day(update4_active_run, DataRegistry.update4_upper_floor_modules, _castle_stage_index())
		_ensure_update4_representative_locked()
	_sync_update3_heart_awaken()
	_apply_update3_daily_heart_upkeep()
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
	var update4_setup_screen := _update4_management_only_setup_screen()
	if update4_setup_screen == Constants.SCREEN_REGION_SELECTION:
		_log("DAY %d 결산 전에 의회 지역을 선택하세요." % GameState.day)
		_set_screen(update4_setup_screen)
		return
	if update4_setup_screen == Constants.SCREEN_OUTPOST_MANAGEMENT:
		_log("DAY 4 결산 전에 전초기지를 건설하세요.")
		_set_screen(update4_setup_screen)
		return
	if _campaign_final_declaration_pending():
		_log("DAY 29 최종 준비 전에 선언을 하나 선택하세요. 자격을 갖췄다면 '휴전문 제안'도 선택할 수 있습니다.")
		return
	if _update4_council_mode_active() and _update4_required_choice_pending():
		_log("DAY %d 의회 필수 결정을 먼저 확정하세요." % GameState.day)
		_set_screen(Constants.SCREEN_MANAGEMENT)
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
	if _update4_council_mode_active():
		_sync_update4_council_day_state()
		var completed := CouncilSeasonServiceScript.finish_management(_update4_council_day_state(), DataRegistry.update4_council_campaign_days)
		if not bool(completed.get("ok", false)):
			_log(str(completed.get("error", "의회 관리 일정을 완료하지 못했습니다.")))
			return
		_set_update4_council_day_state(completed.get("state", {}))
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
	if _update4_council_mode_active():
		return false
	return GameState.day == 29 and bool(_campaign_day_info().get("management_only", false))


func _campaign_final_declaration_pending() -> bool:
	return _campaign_final_declaration_required() and str(run_metrics_tracker.metrics.get("decision.day29", "")) == ""


func _campaign_final_declaration_id() -> String:
	return str(run_metrics_tracker.metrics.get("decision.day29", ""))


func _campaign_armistice_request_available() -> bool:
	return _campaign_final_declaration_required() and FrontCampaignServiceScript.armistice_profile_eligible(update3_profile)


func _set_campaign_final_declaration(declaration_id: String) -> void:
	var allowed := ["rival_pact", "castle_oath"]
	if _campaign_armistice_request_available():
		allowed.append("grand_armistice_request")
	if not _campaign_final_declaration_required() or declaration_id not in allowed:
		return
	run_metrics_tracker.set_value("decision.day29", declaration_id)
	if declaration_id == "rival_pact":
		var front_id := str(update3_active_run.get("front_id", ""))
		if front_id in [FrontCampaignServiceScript.HERO_FRONT_ID, FrontCampaignServiceScript.LEGACY_HERO_FRONT_ID]:
			run_metrics_tracker.set_value("relation.leon", 70.0)
			run_metrics_tracker.set_value("style.honor", 65.0)
		var rival_name := str(_campaign_day_info().get("final_rival_name", "레온"))
		_log("최후 선언: 라이벌 %s에게 이번 결전 뒤 다시 겨루자고 약속했습니다." % rival_name)
	elif declaration_id == "castle_oath":
		_log("최후 선언: 어떤 도전자보다 마왕성과 식구들을 먼저 지키겠다고 맹세했습니다.")
	else:
		_log("최후 선언: 레온·셀렌·로만에게 한 장의 마왕성 휴전문을 제안했습니다.")
	_set_screen(Constants.SCREEN_MANAGEMENT)


func _sanitize_update3_legacy_rival_pact_metrics() -> void:
	if not bool(update3_active_run.get("update3_enabled", false)):
		return
	var front_id := str(update3_active_run.get("front_id", ""))
	if front_id in [FrontCampaignServiceScript.HERO_FRONT_ID, FrontCampaignServiceScript.LEGACY_HERO_FRONT_ID]:
		return
	if str(run_metrics_tracker.metrics.get("decision.day29", "")) != "rival_pact":
		return
	# Earlier Update 3 builds wrote the legacy Leon bonus for every front. The
	# exact pair identifies that write without erasing unrelated player metrics.
	if int(run_metrics_tracker.metrics.get("relation.leon", 0)) != 70 or int(run_metrics_tracker.metrics.get("style.honor", 0)) != 65:
		return
	var preserved_leon_relation := int(update3_profile.get("rival_relations", {}).get("leon", 0))
	run_metrics_tracker.set_value("relation.leon", preserved_leon_relation)
	run_metrics_tracker.set_value("style.honor", 0.0)


func _campaign_ending_data() -> Dictionary:
	var info := _campaign_day_info(REGULAR_CAMPAIGN_FINAL_DAY)
	if campaign_final_battle_outcome == "defeat":
		var defeat_ending = info.get("defeat_ending", {})
		return defeat_ending if defeat_ending is Dictionary else {}
	if _update4_council_mode_active():
		var council_rule := DataRegistry.ending_rule(resolved_campaign_ending_id)
		if council_rule.is_empty():
			var fallback_rule := DataRegistry.ending_rule("true_demon_castle")
			return {
				"id": resolved_campaign_ending_id,
				"title": "엔딩 · 의회 회기 완주",
				"illustration": str(fallback_rule.get("illustration", "")),
				"emblem": str(fallback_rule.get("emblem", "")),
				"thumbnail": str(fallback_rule.get("thumbnail", "")),
				"lines": ["마왕성은 첫 마계 의회 회기를 끝까지 버텼다.", "다음 회기에는 다른 지역·대표·왕관 선택이 새 결말로 이어진다."],
				"sign_text": "첫 회기는 끝났고, 다음 안건은 이미 도착했다.",
				"post_campaign_mode": "continue_stage04"
			}
		return {
			"id": resolved_campaign_ending_id,
			"title": "엔딩 · %s" % str(council_rule.get("display_name", resolved_campaign_ending_id)),
			"illustration": str(council_rule.get("illustration", "")),
			"emblem": str(council_rule.get("emblem", "")),
			"thumbnail": str(council_rule.get("thumbnail", "")),
			"lines": council_rule.get("lines", []).duplicate(),
			"sign_text": str(council_rule.get("sign_text", "다음 회기가 시작된다.")),
			"post_campaign_mode": "continue_stage04"
		}
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
	var ending_data := {
		"id": resolved_campaign_ending_id,
		"title": "엔딩 · %s" % str(rule.get("display_name", resolved_campaign_ending_id)),
		"illustration": str(rule.get("illustration", "")),
		"emblem": str(rule.get("emblem", "")),
		"thumbnail": str(rule.get("thumbnail", "")),
		"lines": rule.get("lines", []).duplicate(),
		"sign_text": str(rule.get("sign_text", "여기서부터 진짜 마왕성.")),
		"post_campaign_mode": "continue_stage04"
	}
	if resolved_campaign_ending_id == "ending_living_castle_voice":
		var heart_id := str(update3_active_run.get("heart", {}).get("heart_id", ""))
		var variant_line := str(rule.get("heart_variant_lines", {}).get(heart_id, ""))
		if variant_line != "":
			var variant_lines: Array = ending_data.get("lines", []).duplicate()
			variant_lines.append(variant_line)
			ending_data["lines"] = variant_lines
	return ending_data

func _reset_run_metrics() -> void:
	var errors := run_metrics_tracker.setup(DataRegistry.run_metric_definitions)
	if not errors.is_empty():
		push_error("Run metric definitions are invalid: %s" % [errors])
	run_metrics_tracker.set_value("directive.used_ids", [Constants.DIRECTIVE_DEFENSE])
	resolved_campaign_ending_id = "true_demon_castle"

func _record_battle_run_metrics() -> void:
	run_metrics_tracker.add("castle.treasure_lost", float(treasure_gold_stolen_this_battle))
	run_metrics_tracker.add("castle.facility_disables", float(facility_disables_this_battle))

func _record_directive_use(directive_id: String) -> void:
	if directive_id == "" or directive_id == Constants.ROOM_DIRECTIVE_NONE:
		return
	var used_ids: Array = run_metrics_tracker.metrics.get("directive.used_ids", []).duplicate()
	if not used_ids.has(directive_id):
		used_ids.append(directive_id)
		run_metrics_tracker.set_value("directive.used_ids", used_ids)

func _record_final_run_metrics() -> void:
	run_metrics_tracker.set_value("infamy.final", GameState.infamy)
	var max_hp: float = maxf(1.0, float(GameState.demon_lord_max_hp))
	var throne_hp_ratio: float = float(GameState.demon_lord_hp) / max_hp
	run_metrics_tracker.set_value("castle.throne_hp_ratio", throne_hp_ratio)
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
		if str(room.get("facility_role", "")) not in ["barracks", "treasure", "recovery", "watch_post", "ward_core"]:
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
	var directive_ids: Dictionary = {}
	for directive_id in run_metrics_tracker.metrics.get("directive.used_ids", []):
		directive_ids[str(directive_id)] = true
	directive_ids[global_directive] = true
	for directive_id in room_directives.values():
		if str(directive_id) != "":
			directive_ids[str(directive_id)] = true
	run_metrics_tracker.set_value("directive.variety_ratio", clamp(float(directive_ids.size()) / 5.0, 0.0, 1.0))
	run_metrics_tracker.set_value("relation.rolo", clamp(float(completed_raids.size()) * 12.0, 0.0, 100.0))
	var doctrine_selected := str(campaign_profile.get("active_doctrine_id", "")) != ""
	var decree_selected := str(campaign_profile.get("active_decree_id", "")) != ""
	var intrigue_score := clampf(float(run_metrics_tracker.metrics.get("directive.variety_ratio", 0.0)) * 65.0 + (10.0 if doctrine_selected else 0.0) + (10.0 if decree_selected else 0.0), 0.0, 100.0)
	run_metrics_tracker.set_value("style.intrigue", intrigue_score)
	run_metrics_tracker.set_value("update2.cycle_index", campaign_cycle_index)
	run_metrics_tracker.set_value("update2.contract_selected_count", selected_contract_ids.size())
	var contract_bond_total := 0.0
	var contract_bond_count := 0
	for contract_id_value in selected_contract_ids:
		var contract_id := str(contract_id_value)
		if monster_roster.has(contract_id):
			contract_bond_total += float(monster_roster.get(contract_id, {}).get("bond", 0))
			contract_bond_count += 1
	run_metrics_tracker.set_value("update2.contract_bond_average", contract_bond_total / float(maxi(1, contract_bond_count)))
	run_metrics_tracker.set_value("update2.doctrine_selected", doctrine_selected)
	run_metrics_tracker.set_value("update2.decree_selected", decree_selected)
	var active_seal_id := str(campaign_profile.get("active_challenge_seal_id", ""))
	run_metrics_tracker.set_value("update2.active_seal_id", active_seal_id)
	var seal_completed := false
	for seal_entry_value in campaign_profile.get("challenge_seal_history", []):
		if seal_entry_value is Dictionary and int(seal_entry_value.get("cycle", 0)) == campaign_cycle_index and str(seal_entry_value.get("seal_id", "")) == active_seal_id:
			seal_completed = seal_completed or bool(seal_entry_value.get("completed", false))
	run_metrics_tracker.set_value("update2.challenge_seal_completed", seal_completed)
	var counterforce_activations := 0
	for activation_value in combat_scene.update2_counter_activations.values():
		counterforce_activations += int(activation_value)
	run_metrics_tracker.set_value("update2.evelyn_counter_activations", int(combat_scene.update2_counter_activations.get("royal_strategist_evelyn", 0)))
	run_metrics_tracker.set_value("update2.counterforce_activations", counterforce_activations)
	run_metrics_tracker.set_value("update2.leon_stance_applied", int(leon_adaptation.get("applied_count", 0)))
	run_metrics_tracker.set_value("update2.reserve_count", reserve_instance_ids.size())
	var known_catalog_ids: Dictionary = {}
	for ending_id_value in DataRegistry.ending_rules.keys():
		var catalog_code := str(DataRegistry.ending_rule(str(ending_id_value)).get("catalog_code", ""))
		var catalog_number := int(catalog_code.trim_prefix("E")) if catalog_code.begins_with("E") and catalog_code.trim_prefix("E").is_valid_int() else -1
		if catalog_number >= 0 and catalog_number <= 10:
			known_catalog_ids[str(ending_id_value)] = true
	var catalog_count := 0
	for ending_id_value in campaign_profile.get("ending_archive", {}).keys():
		if known_catalog_ids.has(str(ending_id_value)):
			catalog_count += 1
	run_metrics_tracker.set_value("profile.catalog_count", catalog_count)
	run_metrics_tracker.set_value("update3.heart_active_uses", int(update3_active_run.get("run_metrics_update3", {}).get("heart_active_uses", 0)))
	run_metrics_tracker.set_value("update3.heart_chamber_disable_count", int(update3_active_run.get("run_metrics_update3", {}).get("heart_chamber_disable_count", 0)))
	run_metrics_tracker.set_value("update3.heart_day30_no_disable", int(update3_active_run.get("run_metrics_update3", {}).get("heart_chamber_disable_count", 0)) == 0 and str(update3_active_run.get("heart", {}).get("heart_id", "")) != "")
	var update3_metrics: Dictionary = update3_active_run.get("run_metrics_update3", {})
	var relations: Dictionary = update3_profile.get("rival_relations", {})
	var positive_mercy_choices := 0
	for metric_id in ["e12_living_castle_testimony", "e12_responsible_heart", "e12_family_ethos", "e12_honor"]:
		positive_mercy_choices += int(update3_metrics.get(metric_id, 0))
	var selen_relation := int(relations.get("selen", 0))
	var honor_tone := clampf(float(positive_mercy_choices) * 18.0 + float(selen_relation) * 0.45, 0.0, 100.0)
	var fear_tone := clampf(float(run_metrics_tracker.metrics.get("style.dread", 0.0)) + float(update3_metrics.get("e12_intimidation", 0)) * 25.0, 0.0, 100.0)
	var security_count := int(update3_metrics.get("security_grade_count", 0))
	var security_average := float(update3_metrics.get("security_grade_total", 0)) / float(maxi(1, security_count))
	var heart_contribution := float(update3_metrics.get("heart_metric_contribution", 0))
	var monster_contribution := float(update3_metrics.get("campaign_monster_contribution", 0))
	var contribution_ratio := heart_contribution / maxf(1.0, heart_contribution + monster_contribution)
	var heart_id := str(update3_active_run.get("heart", {}).get("heart_id", ""))
	var role_progress: Dictionary = update3_metrics.get("duo_role_progress", {})
	var bebe_rescues := int(role_progress.get("link_ghostly_evacuate", {}).get("member_counts", {}).get("monster_bebe", 0))
	run_metrics_tracker.set_value("update3.front_id", str(update3_active_run.get("front_id", "")))
	run_metrics_tracker.set_value("update3.final_battle_won", campaign_final_battle_outcome == "victory")
	run_metrics_tracker.set_value("update3.relation_selen", selen_relation)
	run_metrics_tracker.set_value("update3.relation_roman", int(relations.get("roman", 0)))
	run_metrics_tracker.set_value("update3.honor_tone", honor_tone)
	run_metrics_tracker.set_value("update3.fear_tone", fear_tone)
	run_metrics_tracker.set_value("update3.holy_seals_interrupted", int(update3_metrics.get("holy_seals_interrupted", 0)))
	run_metrics_tracker.set_value("update3.mercy_choice_count", positive_mercy_choices)
	run_metrics_tracker.set_value("update3.average_security_grade", security_average)
	run_metrics_tracker.set_value("update3.campaign_treasure_losses", int(update3_metrics.get("campaign_treasure_losses", 0)))
	run_metrics_tracker.set_value("update3.facility_disable_count", int(update3_metrics.get("facility_disable_count", 0)))
	run_metrics_tracker.set_value("update3.debt_marks_cleansed", int(update3_metrics.get("debt_marks_cleansed", 0)))
	run_metrics_tracker.set_value("update3.gold_at_final", GameState.gold)
	run_metrics_tracker.set_value("update3.heart_metric_contribution_ratio", contribution_ratio)
	run_metrics_tracker.set_value("update3.selected_heart_id", heart_id)
	run_metrics_tracker.set_value("update3.selected_heart_mastery_before_run", int(update3_metrics.get("selected_heart_mastery_before_run", 0)))
	run_metrics_tracker.set_value("update3.stonebone_damage_reduced", int(update3_metrics.get("stonebone_facility_damage_reduced", 0)) + int(update3_metrics.get("stonebone_monster_damage_reduced", 0)))
	run_metrics_tracker.set_value("update3.hungry_waves", int(update3_metrics.get("hungry_waves", 0)))
	run_metrics_tracker.set_value("update3.hungry_safe_clear", heart_id == CastleHeartServiceScript.HUNGRY_MAW_ID and campaign_final_battle_outcome == "victory" and throne_hp_ratio >= 0.70)
	run_metrics_tracker.set_value("update3.dream_goal_changes", int(update3_metrics.get("dream_goal_changes", 0)))
	run_metrics_tracker.set_value("update3.dream_throne_damage", int(update3_metrics.get("campaign_throne_damage", 0)))
	run_metrics_tracker.set_value("update3.day30_no_down", 1 if int(update3_metrics.get("day30_down_count", 0)) == 0 else 0)
	run_metrics_tracker.set_value("update3.bebe_rescues_five", 1 if bebe_rescues >= 5 else 0)
	run_metrics_tracker.set_value("update3.selen_mercy_vulnerable_success", 1 if int(update3_metrics.get("selen_mercy_vulnerable_successes", 0)) >= 1 else 0)
	run_metrics_tracker.set_value("update3.day28_no_ledger_forgery", 1 if str(update3_active_run.get("day28_front_operation", "")) != "d28_guild_ledger_forgery" else 0)
	var roman_budget := int(update3_metrics.get("roman_final_phase_entry_budget", -1))
	run_metrics_tracker.set_value("update3.roman_final_budget_two_or_less", 1 if roman_budget >= 0 and roman_budget <= 2 else 0)
	run_metrics_tracker.set_value("update3.toktok_repairs_five", 1 if int(update3_metrics.get("toktok_facility_repairs", 0)) >= 5 else 0)
	var used_link_ids: Array = update3_metrics.get("link_skills_used_campaign", [])
	var day30_link_ids: Array = update3_metrics.get("link_skills_used_day30", [])
	var used_member_ids: Dictionary = {}
	for link_id_value in used_link_ids:
		for member_id_value in DataRegistry.update3_duo_links.get(str(link_id_value), {}).get("member_instance_ids", []):
			used_member_ids[str(member_id_value)] = true
	var pair_bond_total := 0.0
	for member_id_value in used_member_ids.keys():
		var member_id := str(member_id_value)
		var instance: Dictionary = DataRegistry.monster_instances.get(member_id, {})
		var species_id := str(instance.get("species_id", ""))
		pair_bond_total += float(monster_roster.get(species_id, {}).get("bond", instance.get("bond", 0)))
	var average_pair_bond := pair_bond_total / float(maxi(1, used_member_ids.size()))
	var contribution_by_species: Dictionary = update3_metrics.get("campaign_monster_contribution_by_species", {})
	var maximum_contribution_ratio := 1.0
	var eight_percent_count := 0
	if monster_contribution > 0.0:
		maximum_contribution_ratio = 0.0
		for contribution_value in contribution_by_species.values():
			var ratio := float(contribution_value) / monster_contribution
			maximum_contribution_ratio = maxf(maximum_contribution_ratio, ratio)
			if ratio >= 0.08:
				eight_percent_count += 1
	var day30_downed_members: Dictionary = {}
	for state_value in update3_active_run.get("duo_link_states", {}).values():
		if state_value is Dictionary:
			for member_id_value in state_value.get("downed_members", []):
				day30_downed_members[str(member_id_value)] = true
	var both_equipped_used: bool = update3_active_run.get("equipped_duo_links", []).size() == 2
	for link_id_value in update3_active_run.get("equipped_duo_links", []):
		both_equipped_used = both_equipped_used and day30_link_ids.has(link_id_value)
	var seen_endings: Array = update3_profile.get("update3_endings_seen", [])
	var day29_choice := str(run_metrics_tracker.metrics.get("decision.day29", ""))
	run_metrics_tracker.set_value("update3.distinct_link_skills_used_campaign", used_link_ids.size())
	run_metrics_tracker.set_value("update3.link_skill_used_day30", not day30_link_ids.is_empty())
	run_metrics_tracker.set_value("update3.average_active_pair_bond", average_pair_bond)
	run_metrics_tracker.set_value("update3.max_monster_contribution_ratio", maximum_contribution_ratio)
	run_metrics_tracker.set_value("update3.day30_pair_member_down_count", day30_downed_members.size())
	var new_duo_memories := int(update3_metrics.get("new_duo_memories_this_run", 0))
	run_metrics_tracker.set_value("update3.new_duo_memories_this_run", new_duo_memories)
	run_metrics_tracker.set_value("update3.new_duo_memories_two", 1 if new_duo_memories >= 2 else 0)
	run_metrics_tracker.set_value("update3.both_equipped_links_used_day30", 1 if both_equipped_used else 0)
	run_metrics_tracker.set_value("update3.five_deployed_all_contributed_eight_percent", 1 if contribution_by_species.size() >= 5 and eight_percent_count >= 5 else 0)
	run_metrics_tracker.set_value("update3.day29_heart_preference", 1 if day29_choice == "castle_oath" else 0)
	run_metrics_tracker.set_value("update3.day29_link_preference", 1 if day29_choice == "rival_pact" else 0)
	run_metrics_tracker.set_value("update3.ending_e14_unseen", 0 if seen_endings.has("ending_living_castle_voice") else 1)
	run_metrics_tracker.set_value("update3.ending_e15_unseen", 0 if seen_endings.has("ending_linked_corridors") else 1)
	var front_clears: Dictionary = update3_profile.get("fronts", {}).get("clear_counts", {})
	run_metrics_tracker.set_value("update3.front_clear_hero_oath", int(front_clears.get(FrontCampaignServiceScript.HERO_FRONT_ID, 0)))
	run_metrics_tracker.set_value("update3.front_clear_holy_purification", int(front_clears.get(FrontCampaignServiceScript.HOLY_FRONT_ID, 0)))
	run_metrics_tracker.set_value("update3.front_clear_guild_repossession", int(front_clears.get(FrontCampaignServiceScript.GUILD_FRONT_ID, 0)))
	run_metrics_tracker.set_value("update3.relation_leon", int(relations.get("leon", 0)))
	run_metrics_tracker.set_value("update3.ending_holy_open_gate_seen", seen_endings.has("ending_holy_open_gate"))
	run_metrics_tracker.set_value("update3.ending_off_ledger_independence_seen", seen_endings.has("ending_off_ledger_independence"))
	run_metrics_tracker.set_value("update3.campaign_abandonment_count", int(update3_metrics.get("campaign_abandonment_count", 0)))


func _sync_update3_leon_relation() -> void:
	var relations: Dictionary = update3_profile.get("rival_relations", {}).duplicate(true)
	var candidate := int(relations.get("leon", 0))
	var front_id := str(update3_active_run.get("front_id", ""))
	if front_id in [FrontCampaignServiceScript.HERO_FRONT_ID, FrontCampaignServiceScript.LEGACY_HERO_FRONT_ID]:
		candidate = maxi(candidate, int(run_metrics_tracker.metrics.get("relation.leon", 0)))
	if front_id == FrontCampaignServiceScript.HERO_FRONT_ID:
		var metrics: Dictionary = update3_active_run.get("run_metrics_update3", {})
		candidate = maxi(candidate, 35 + int(metrics.get("leon_heart_guidance", 0)) * 15 + int(metrics.get("leon_link_respect", 0)) * 15)
	relations["leon"] = clampi(maxi(int(relations.get("leon", 0)), candidate), 0, 100)
	update3_profile["rival_relations"] = relations
	run_metrics_tracker.set_value("update3.relation_leon", int(relations.get("leon", 0)))

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
	hud.label(screen, "%d회차 · 엔딩 도감 %d/%d" % [campaign_cycle_index, _known_ending_count(), _ending_catalog_ids().size()], Vector2(1140, 226), Vector2(600, 28), 16, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
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
	var available_ids := _campaign_legacy_candidate_ids()
	if not available_ids.has(species_id):
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
	var next_update3_profile := FrontCampaignServiceScript.reconcile_unlocks(_update3_front_profile_context(), DataRegistry.update3_fronts)
	var next_legacy: Dictionary = next_profile.get("legacy_monster", {}).duplicate(true)
	var preserved_player_name := GameState.player_name
	_onboarding_reset_game()
	campaign_profile = next_profile
	update3_profile = next_update3_profile
	campaign_cycle_index = int(campaign_profile.get("completed_cycles", 0)) + 1
	update3_active_run = FrontCampaignServiceScript.new_cycle_active_run(campaign_cycle_index)
	update4_profile = CampaignModeServiceScript.normalize_profile(update4_profile, update3_profile)
	update4_active_run = CampaignModeServiceScript.new_cycle_active_run()
	inherited_legacy_monster = next_legacy
	GameState.player_name = preserved_player_name
	GameState.day = 4
	GameState.onboarding_complete = true
	onboarding_enabled = false
	tutorial_gate_enabled = false
	combat_speed_intro_seen = true
	tutorial_manager.active = false
	_unlock_kobold_scout_commander()
	NewCycleServiceScript.apply_legacy_memory(monster_roster, inherited_legacy_monster)
	_sync_update3_reward_monsters()
	_onboarding_set_stage("CAMPAIGN_CYCLE_%d_DAY_04" % campaign_cycle_index)
	_apply_campaign_day_entry(4)
	_log("%d회차를 DAY 04부터 시작합니다. %s의 승리 기억 1개를 계승했습니다." % [campaign_cycle_index, str(next_legacy.get("display_name", "몬스터"))])
	update2_cycle_seed = maxi(1, campaign_cycle_index * 1009 + int(Time.get_unix_time_from_system()) % 1000003)
	leon_adaptation = LeonAdaptationServiceScript.default_adaptation()
	contract_board_offer_ids = ContractRosterServiceScript.offer_ids(DataRegistry.update2_contracts, update2_cycle_seed)
	contract_board_pending_ids.clear()
	selected_contract_ids.clear()
	deployed_instance_ids.clear()
	reserve_instance_ids.clear()
	event_deck_order.clear()
	wave_variant_ids.clear()
	update2_triggered_event_ids.clear()
	_ensure_update2_seeded_campaign()
	_set_screen(Constants.SCREEN_CAMPAIGN_MODE)
	if not _write_campaign_v2_snapshot():
		campaign_save_notice = "다음 회차는 시작했지만 프로필 보조 저장에 실패했습니다. 현재 회차 자동 저장은 계속 유지됩니다."
		push_warning(campaign_save_notice)
		_show_campaign_save_notice_overlay()


func _write_campaign_v2_snapshot() -> bool:
	if not campaign_save_enabled or not campaign_auxiliary_save_enabled:
		return true
	_sync_update4_council_day_state()
	var checkpoint := current_screen
	var migration := CampaignSaveMigratorV1ToV2Script.migrate_inspection({
		"status": CampaignSaveStoreScript.STATUS_VALID,
		"payload": _campaign_save_payload(checkpoint),
		"summary": _campaign_save_summary(checkpoint),
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"saved_at_text": Time.get_datetime_string_from_system(false, true)
	}, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	if not bool(migration.get("ok", false)):
		campaign_save_error = str(migration.get("error", "저장 v1을 v2로 변환하지 못했습니다."))
		push_warning("Campaign auxiliary v2 migration failed: %s" % campaign_save_error)
		return false
	var envelope: Dictionary = migration.get("envelope", {}).duplicate(true)
	var compatible_v2_profile := campaign_profile.duplicate(true)
	compatible_v2_profile["profile_version"] = 1
	envelope["profile"] = compatible_v2_profile
	var active_run: Dictionary = envelope.get("active_run", {})
	active_run["cycle_index"] = campaign_cycle_index
	active_run["run_metrics"] = run_metrics_tracker.snapshot()
	envelope["active_run"] = active_run
	var write_result := CampaignSaveV2StoreScript.write(envelope, campaign_save_v2_path, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	if not bool(write_result.get("ok", false)):
		campaign_save_error = str(write_result.get("error", "저장 v2를 기록하지 못했습니다."))
		push_warning("Campaign auxiliary v2 write failed: %s" % campaign_save_error)
		return false
	var v3_migration := CampaignSaveMigratorV2ToV3Script.migrate_envelope(envelope, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	if not bool(v3_migration.get("ok", false)):
		campaign_save_error = str(v3_migration.get("error", "저장 v2를 v3로 변환하지 못했습니다."))
		push_warning("Campaign auxiliary v3 migration failed: %s" % campaign_save_error)
		return false
	var v3_envelope: Dictionary = v3_migration.get("envelope", {}).duplicate(true)
	v3_envelope["profile"] = campaign_profile.duplicate(true)
	var v3_write_result := CampaignSaveV3StoreScript.write(v3_envelope, campaign_save_v3_path, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	if not bool(v3_write_result.get("ok", false)):
		campaign_save_error = str(v3_write_result.get("error", "저장 v3를 기록하지 못했습니다."))
		push_warning("Campaign auxiliary v3 write failed: %s" % campaign_save_error)
		return false
	if not campaign_save_v4_enabled:
		return true
	var v4_migration := SaveV3ToV4MigratorScript.migrate_envelope(v3_envelope, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_save_catalogs())
	if not bool(v4_migration.get("ok", false)):
		campaign_save_error = str(v4_migration.get("error", "저장 v3를 v4로 변환하지 못했습니다."))
		push_warning("Campaign auxiliary v4 migration failed: %s" % campaign_save_error)
		return false
	var v4_envelope: Dictionary = v4_migration.get("envelope", {}).duplicate(true)
	var v4_profile: Dictionary = v4_envelope.get("profile", {}).duplicate(true)
	for key in ["fronts", "hearts", "duo_links", "rival_relations", "update3_endings_seen", "unlocked_reward_ids", "guaranteed_contract_instance_ids", "joint_boundary_event_ids", "contract_board_free_refreshes", "heart_voice_records", "heart_selection_flair_ids", "recent_run_summaries", "duo_link_preset_slots", "duo_link_presets", "duo_link_auto_recommendation_unlocked", "front_rotation_unlocked", "front_rotation_enabled", "chronicle_final_nameplate"]:
		if update3_profile.has(key):
			v4_profile[key] = update3_profile.get(key).duplicate(true) if update3_profile.get(key) is Dictionary or update3_profile.get(key) is Array else update3_profile.get(key)
	v4_envelope["profile"] = v4_profile
	var v4_active_run: Dictionary = v4_envelope.get("active_run", {}).duplicate(true)
	for key in ["update3_enabled", "new_cycle_selection_pending", "front_selection_completed", "front_id", "heart", "heart_event_candidate_id", "equipped_duo_links", "duo_link_loadout_confirmed", "duo_link_states", "duo_link_auto_use", "duo_link_active_effects", "duo_link_inactive_count", "front_flags", "day28_front_operation", "rival_finale", "run_metrics_update3"]:
		if update3_active_run.has(key):
			v4_active_run[key] = update3_active_run.get(key).duplicate(true) if update3_active_run.get(key) is Dictionary or update3_active_run.get(key) is Array else update3_active_run.get(key)
	v4_active_run["cycle_index"] = campaign_cycle_index
	v4_envelope["active_run"] = v4_active_run
	var v4_write_result := CampaignSaveV4StoreScript.write(v4_envelope, campaign_save_v4_path, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_save_catalogs())
	if not bool(v4_write_result.get("ok", false)):
		campaign_save_error = str(v4_write_result.get("error", "저장 v4를 기록하지 못했습니다."))
		push_warning("Campaign auxiliary v4 write failed: %s" % campaign_save_error)
		return false
	if not campaign_save_v5_enabled:
		return true
	var v5_migration := SaveV4ToV5MigratorScript.migrate_envelope(v4_envelope, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_save_catalogs(), DataRegistry.update4_catalogs)
	if not bool(v5_migration.get("ok", false)):
		campaign_save_error = str(v5_migration.get("error", "저장 v4를 v5로 변환하지 못했습니다."))
		push_warning("Campaign v5 migration failed: %s" % campaign_save_error)
		return false
	var v5_envelope: Dictionary = v5_migration.get("envelope", {}).duplicate(true)
	update4_profile = CampaignModeServiceScript.normalize_profile(update4_profile, _update3_front_profile_context())
	var v5_profile: Dictionary = v5_envelope.get("profile", {}).duplicate(true)
	for key in CampaignModeServiceScript.default_profile().keys():
		if update4_profile.has(key):
			v5_profile[key] = update4_profile.get(key).duplicate(true) if update4_profile.get(key) is Dictionary or update4_profile.get(key) is Array else update4_profile.get(key)
	v5_envelope["profile"] = v5_profile
	var v5_active_run: Dictionary = v5_envelope.get("active_run", {}).duplicate(true)
	for key in CampaignModeServiceScript.default_active_run().keys():
		if update4_active_run.has(key):
			v5_active_run[key] = update4_active_run.get(key).duplicate(true) if update4_active_run.get(key) is Dictionary or update4_active_run.get(key) is Array else update4_active_run.get(key)
	v5_envelope["active_run"] = v5_active_run
	var v5_write_result := CampaignSaveV5StoreScript.write(v5_envelope, campaign_save_v5_path, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_save_catalogs(), DataRegistry.update4_catalogs)
	if not bool(v5_write_result.get("ok", false)):
		campaign_save_error = str(v5_write_result.get("error", "저장 v5를 기록하지 못했습니다."))
		push_warning("Campaign v5 write failed: %s" % campaign_save_error)
		return false
	campaign_save_v5_envelope = v5_envelope.duplicate(true)
	return true


func _update3_save_catalogs() -> Dictionary:
	return {
		"fronts": DataRegistry.update3_fronts,
		"castle_hearts": DataRegistry.update3_castle_hearts,
		"duo_links": DataRegistry.update3_duo_links,
		"rival_finales": DataRegistry.update3_rival_finales
	}

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
	var mission_id := str(update3_active_run.get("day28_front_operation", ""))
	var choice_group := _campaign_required_raid_choice_group()
	if choice_group == "":
		choice_group = "day28_final_expedition"
	if mission_id == "" or not completed_raids.has(mission_id):
		mission_id = _completed_raid_choice_id(choice_group)
	if mission_id == "" and choice_group != "day28_final_expedition":
		mission_id = _completed_raid_choice_id("day28_final_expedition")
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
	var front_modifier := FrontCampaignServiceScript.day_defense_modifier(update3_active_run, GameState.day, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays)
	if not front_modifier.is_empty():
		active[str(front_modifier.get("id", "update3_front_day_%d" % GameState.day))] = front_modifier
	var operation_modifier := FrontCampaignServiceScript.selected_operation_modifier(update3_active_run, GameState.day, DataRegistry.update3_front_operations)
	if not operation_modifier.is_empty():
		var operation_modifier_id := str(operation_modifier.get("id", "update3_front_operation"))
		if not active.has(operation_modifier_id):
			active[operation_modifier_id] = operation_modifier
	if _update4_council_mode_active():
		var outpost_modifier := OutpostServiceScript.home_defense_modifier(update4_active_run, GameState.day, DataRegistry.update4_outpost_types)
		if not outpost_modifier.is_empty():
			active[str(outpost_modifier.get("id", "update4_outpost"))] = outpost_modifier
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
	if _update4_council_mode_active():
		update4_active_run = OutpostServiceScript.consume_home_defense_modifier(update4_active_run, GameState.day)

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
		if _monster_available_for_defense(str(monster_id)) and _monster_deployed_for_defense(str(monster_id)):
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
	if DataRegistry.update3_front_operations.has(raid_selected_mission_id):
		var operation_result := FrontCampaignServiceScript.select_operation(update3_active_run, raid_selected_mission_id, GameState.day, DataRegistry.update3_front_operations)
		if bool(operation_result.get("ok", false)):
			update3_active_run = operation_result.get("active_run", update3_active_run).duplicate(true)
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

func _combat_speed_unlocked() -> bool:
	return not onboarding_enabled or GameState.onboarding_complete

func _maybe_show_combat_speed_intro() -> void:
	if current_screen != Constants.SCREEN_COMBAT or not onboarding_enabled or not GameState.onboarding_complete or combat_speed_intro_seen:
		return
	if ui_layer == null or hud == null or ui_layer.get_node_or_null("CombatSpeedFeatureIntro") != null:
		return
	combat_speed_intro_open = true
	combat_paused = true
	for unit in monster_units + enemy_units:
		if is_instance_valid(unit):
			unit.set_physics_process(false)
	var touch_ui := UISettings.is_touch_ui()
	var overlay = hud.panel(Rect2(0, 0, 1920, 1080), Color("#000000b8"), Color("#00000000"), "CombatSpeedFeatureIntro", "flat")
	overlay.name = "CombatSpeedFeatureIntro"
	overlay.z_index = 600
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var modal_rect := Rect2(300, 220, 1320, 640) if touch_ui else Rect2(560, 300, 800, 460)
	var modal = hud.child_panel(overlay, modal_rect, Color("#0b0910fa"), Color("#ffd36a"), 3)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.label(modal, "전투 속도 해금", Vector2(50, 32), Vector2(modal_rect.size.x - 100, 90 if touch_ui else 70), 32 if touch_ui else 30, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_OFF, 1)
	var location_text := "화면 아래 두 번째 줄" if touch_ui else "화면 오른쪽 아래"
	var description := "튜토리얼을 마쳤습니다. 이제 %s의 속도 버튼에서\nx1 · x1.5 · x2 · x3를 선택할 수 있습니다.\n전투 판정과 자동 스킬도 함께 빨라집니다.\n필요할 때 언제든 x1로 돌아오세요." % location_text
	hud.label(modal, description, Vector2(70, 150 if touch_ui else 112), Vector2(modal_rect.size.x - 140, 260 if touch_ui else 188), 28 if touch_ui else 21, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 6)
	hud.button(modal, "확인하고 전투 재개", Rect2(modal_rect.size.x * 0.5 - (300 if touch_ui else 180), modal_rect.size.y - (170 if touch_ui else 112), 600 if touch_ui else 360, 120 if touch_ui else 68), Callable(self, "_dismiss_combat_speed_intro"), 27 if touch_ui else 20, "CombatSpeedIntroConfirm")

func _dismiss_combat_speed_intro() -> void:
	combat_speed_intro_seen = true
	combat_speed_intro_open = false
	if ui_layer != null:
		var overlay := ui_layer.get_node_or_null("CombatSpeedFeatureIntro")
		if overlay != null:
			ui_layer.remove_child(overlay)
			overlay.queue_free()
	if current_screen == Constants.SCREEN_COMBAT:
		combat_paused = false
		for unit in monster_units + enemy_units:
			if is_instance_valid(unit):
				unit.set_physics_process(true)
	_log("전투 속도 x1~x3가 해금되었습니다.")

func _debug_skip_onboarding() -> void:
	first_play_observation.stop()
	onboarding_enabled = false
	onboarding_dialogue_queue.clear()
	onboarding_seen_dialogue_ids.clear()
	tutorial_gate_enabled = false
	tutorial_manager.reset()
	tutorial_manager.active = false
	GameState.onboarding_complete = true
	combat_speed_intro_seen = true
	combat_speed_intro_open = false
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
	if UISettings.is_touch_ui():
		_tutorial_prepare_touch_selection(step)
	var focus_id := _tutorial_effective_focus_id(step)
	var focus_rect := _tutorial_focus_rect(focus_id)
	if _tutorial_requires_live_control(focus_id) and not focus_rect.has_area():
		return
	var overlay = Panel.new()
	overlay.name = "TutorialOverlay"
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(1920, 1080)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_theme_stylebox_override("panel", hud.style(Color("#00000000"), Color("#00000000"), 0))
	ui_layer.add_child(overlay)
	var suppress_focus_highlight = current_screen == Constants.SCREEN_MANAGEMENT and _management_action_mode_active()
	if not suppress_focus_highlight and focus_rect.size.x > 0.0 and focus_rect.size.y > 0.0:
		_tutorial_add_spotlight(overlay, focus_rect)
		var focus_glow = Panel.new()
		focus_glow.name = "TutorialFocusOuter"
		focus_glow.position = focus_rect.position - Vector2(14, 14)
		focus_glow.size = focus_rect.size + Vector2(28, 28)
		focus_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		focus_glow.add_theme_stylebox_override("panel", hud.style(Color("#ffd43a18"), Color("#ffcf3a"), 6))
		overlay.add_child(focus_glow)
		var highlight = Panel.new()
		highlight.name = "TutorialFocusRing"
		highlight.position = focus_rect.position - Vector2(3, 3)
		highlight.size = focus_rect.size + Vector2(6, 6)
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		highlight.add_theme_stylebox_override("panel", hud.style(Color("#fff2a62e"), Color("#fff7c2"), 4))
		overlay.add_child(highlight)
		var pulse = focus_glow.create_tween().set_loops()
		pulse.set_trans(Tween.TRANS_SINE)
		pulse.tween_property(focus_glow, "modulate:a", 0.45, 0.55)
		pulse.tween_property(focus_glow, "modulate:a", 1.0, 0.55)
	var message_rect = _tutorial_message_rect(focus_rect)
	var shadow_panel = Panel.new()
	shadow_panel.position = message_rect.position + Vector2(8, 10)
	shadow_panel.size = message_rect.size
	shadow_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow_panel.add_theme_stylebox_override("panel", hud.style(Color("#00000088"), Color("#00000000"), 0))
	overlay.add_child(shadow_panel)
	var message_panel = Panel.new()
	message_panel.name = "TutorialMessagePanel"
	message_panel.position = message_rect.position
	message_panel.size = message_rect.size
	message_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_panel.add_theme_stylebox_override("panel", hud.style(Color("#0b0910fa"), Color("#ffd36a"), 3))
	overlay.add_child(message_panel)
	hud.label(message_panel, _tutorial_action_heading(step), Vector2(24, 12), Vector2(message_rect.size.x - 48, 34), 26, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	hud.rich_label(message_panel, _onboarding_line_text(step), Vector2(24, 52), Vector2(message_rect.size.x - 48, message_rect.size.y - 64), 22, Color("#fffdf4"), UIFontScript.ROLE_EMPHASIS, TextServer.AUTOWRAP_WORD_SMART, VERTICAL_ALIGNMENT_CENTER, "", 17)
	if not suppress_focus_highlight and _tutorial_step_uses_click_badge(step) and focus_rect.size.x > 0.0 and focus_rect.size.y > 0.0:
		_tutorial_add_click_badge(overlay, step, focus_rect, message_rect)

func _tutorial_effective_focus_id(step: Dictionary) -> String:
	if str(step.get("id", "")) == "TUT_090_RESULT_GROWTH" and _result_growth_choice_required() and not result_growth_choice_applied:
		return "GrowthChoice_slime"
	return str(step.get("focus", ""))

func _tutorial_requires_live_control(focus_id: String) -> bool:
	return focus_id in [
		"GLOBAL_DIRECTIVE_DEFEND",
		"ROOM_DIRECTIVE_TRAP_LURE",
		"ROOM_DIRECTIVE_RETREAT_LINE",
		"BossHpBar",
		"GrowthReviewButton"
	] or focus_id.begins_with("GrowthChoice_")

func _tutorial_sync_required_selected_room() -> void:
	if not onboarding_enabled or not tutorial_manager.is_active_for_stage(onboarding_stage_id):
		return
	var required_room_id := ""
	match _tutorial_effective_focus_id(tutorial_manager.current_step()):
		"ROOM_DIRECTIVE_TRAP_LURE":
			required_room_id = "spike_corridor"
		"ROOM_DIRECTIVE_RETREAT_LINE":
			required_room_id = "recovery"
	if required_room_id != "" and rooms.has(required_room_id):
		selected_room = required_room_id

func _tutorial_action_heading(step: Dictionary) -> String:
	match str(step.get("id", "")):
		"TUT_130_GOBLIN_CONTROL", "TUT_230_IMP_FIREBALL":
			return "AI 자동 전투를 확인하세요"
		"TUT_240_BOSS_HP":
			return "화면을 잠깐 확인하세요"
	return ("노란 표시를 탭하세요!" if UISettings.is_touch_ui() else "노란 표시를 클릭하세요!") if _tutorial_step_uses_click_badge(step) else "지금 할 일"

func _tutorial_step_uses_click_badge(step: Dictionary) -> bool:
	return str(step.get("id", "")) in [
		"TUT_030_SELECT_SLIME",
		"TUT_040_DEPLOY_SLIME",
		"TUT_050_GLOBAL_DEFEND",
		"TUT_090_RESULT_GROWTH",
		"TUT_110_TRAP_CORRIDOR",
		"TUT_120_TRAP_LURE",
		"TUT_210_RECOVERY_NEST",
		"TUT_220_RETREAT_LINE"
	]

func _tutorial_prepare_touch_selection(step: Dictionary = {}) -> void:
	if not UISettings.is_touch_ui() or not onboarding_enabled or not tutorial_gate_enabled:
		return
	if not tutorial_manager.is_active_for_stage(onboarding_stage_id):
		return
	if step.is_empty():
		step = tutorial_manager.current_step()
	match str(step.get("id", "")):
		"TUT_030_SELECT_SLIME":
			selected_monster_id = "slime"
		"TUT_040_DEPLOY_SLIME":
			selected_monster_id = "slime"
			selected_room = "entrance"
			deploy_pick_monster_id = "slime"
		"TUT_110_TRAP_CORRIDOR":
			selected_room = "spike_corridor"
		"TUT_120_TRAP_LURE":
			selected_room = "spike_corridor"
		"TUT_210_RECOVERY_NEST", "TUT_220_RETREAT_LINE":
			selected_room = "recovery"

func _handle_mobile_tutorial_focus_tap(screen_point: Vector2) -> bool:
	if not UISettings.is_touch_ui() or not onboarding_enabled or not tutorial_gate_enabled:
		return false
	if not tutorial_manager.is_active_for_stage(onboarding_stage_id):
		return false
	var step := tutorial_manager.current_step()
	if step.is_empty() or not _tutorial_step_uses_click_badge(step):
		return false
	var focus_rect := _tutorial_focus_rect(_tutorial_effective_focus_id(step))
	if not focus_rect.has_area():
		return false
	var message_rect := _tutorial_message_rect(focus_rect)
	var badge_placement := _tutorial_click_badge_placement(focus_rect, message_rect)
	var badge_rect: Rect2 = badge_placement.get("rect", Rect2())
	var focus_hit := focus_rect.grow(24.0).has_point(screen_point)
	var badge_hit := badge_rect.has_area() and badge_rect.grow(12.0).has_point(screen_point)
	if not focus_hit and not badge_hit:
		return false
	match str(step.get("id", "")):
		"TUT_030_SELECT_SLIME":
			_select_monster("slime")
			_set_screen(Constants.SCREEN_MANAGEMENT)
		"TUT_040_DEPLOY_SLIME":
			if _assign_monster_to_room("slime", "entrance"):
				deploy_pick_monster_id = ""
				_set_screen(Constants.SCREEN_MANAGEMENT)
		"TUT_050_GLOBAL_DEFEND":
			_set_global_directive(Constants.DIRECTIVE_DEFENSE)
		"TUT_090_RESULT_GROWTH":
			if _result_growth_choice_required() and not result_growth_choice_applied:
				_choose_result_growth("slime")
			else:
				_review_growth_from_result()
		"TUT_110_TRAP_CORRIDOR":
			_select_room("spike_corridor")
		"TUT_120_TRAP_LURE":
			selected_room = "spike_corridor"
			_set_room_directive(Constants.ROOM_DIRECTIVE_TRAP_LURE)
		"TUT_210_RECOVERY_NEST":
			_select_room("recovery")
		"TUT_220_RETREAT_LINE":
			selected_room = "recovery"
			_set_room_directive(Constants.ROOM_DIRECTIVE_RETREAT)
		_:
			return false
	return true

func _tutorial_add_spotlight(overlay: Control, focus_rect: Rect2) -> void:
	var clipped := focus_rect.grow(18.0).intersection(Rect2(0, 0, 1920, 1080))
	var shade_rects: Array[Rect2] = [
		Rect2(0, 0, 1920, maxf(0.0, clipped.position.y)),
		Rect2(0, clipped.end.y, 1920, maxf(0.0, 1080.0 - clipped.end.y)),
		Rect2(0, clipped.position.y, maxf(0.0, clipped.position.x), clipped.size.y),
		Rect2(clipped.end.x, clipped.position.y, maxf(0.0, 1920.0 - clipped.end.x), clipped.size.y)
	]
	for index in range(shade_rects.size()):
		var rect := shade_rects[index]
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		var shade = Panel.new()
		shade.name = "TutorialSpotlightShade%d" % index
		shade.position = rect.position
		shade.size = rect.size
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shade.add_theme_stylebox_override("panel", hud.style(Color("#000000a8"), Color("#00000000"), 0))
		overlay.add_child(shade)

func _tutorial_add_click_badge(overlay: Control, step: Dictionary, focus_rect: Rect2, message_rect: Rect2) -> void:
	var placement := _tutorial_click_badge_placement(focus_rect, message_rect)
	var badge_rect: Rect2 = placement.get("rect", Rect2())
	if badge_rect.size.x <= 0.0:
		return
	var badge = Panel.new()
	badge.name = "TutorialClickBadge"
	badge.position = badge_rect.position
	badge.size = badge_rect.size
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override("panel", hud.style(Color("#ffd447"), Color("#fff7c2"), 4))
	badge.pivot_offset = badge.size * 0.5
	overlay.add_child(badge)
	var text := str(placement.get("text", "여기를 클릭!"))
	if UISettings.is_touch_ui():
		text = text.replace("클릭", "탭")
	var click_label = hud.label(badge, text, Vector2(10, 6), badge.size - Vector2(20, 12), 36 if UISettings.is_touch_ui() else 27, Color("#171008"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BUTTON, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_OFF, 1, 26 if UISettings.is_touch_ui() else 21)
	click_label.name = "TutorialClickLabel"
	var pulse = badge.create_tween().set_loops()
	pulse.set_trans(Tween.TRANS_SINE)
	pulse.tween_property(badge, "scale", Vector2(1.045, 1.045), 0.55)
	pulse.tween_property(badge, "scale", Vector2.ONE, 0.55)

func _tutorial_click_badge_placement(focus_rect: Rect2, message_rect: Rect2) -> Dictionary:
	var badge_size := Vector2(420, 112) if UISettings.is_touch_ui() else Vector2(300, 64)
	var screen_bounds := Rect2(16, 78, 1888, 986)
	var edge_x := screen_bounds.end.x - badge_size.x if focus_rect.get_center().x >= 960.0 else screen_bounds.position.x
	var candidates := [
		{"rect": Rect2(Vector2(focus_rect.get_center().x - badge_size.x * 0.5, focus_rect.position.y - badge_size.y - 18.0), badge_size), "text": "여기를 클릭!  ▼"},
		{"rect": Rect2(Vector2(edge_x, focus_rect.position.y - badge_size.y - 18.0), badge_size), "text": "여기를 클릭!  ▼"},
		{"rect": Rect2(Vector2(focus_rect.get_center().x - badge_size.x * 0.5, focus_rect.end.y + 18.0), badge_size), "text": "여기를 클릭!  ▲"},
		{"rect": Rect2(Vector2(edge_x, focus_rect.end.y + 18.0), badge_size), "text": "여기를 클릭!  ▲"},
		{"rect": Rect2(Vector2(focus_rect.position.x - badge_size.x - 18.0, focus_rect.get_center().y - badge_size.y * 0.5), badge_size), "text": "여기를 클릭!  →"},
		{"rect": Rect2(Vector2(focus_rect.end.x + 18.0, focus_rect.get_center().y - badge_size.y * 0.5), badge_size), "text": "←  여기를 클릭!"}
	]
	for candidate in candidates:
		var rect: Rect2 = candidate["rect"]
		rect.position.x = clampf(rect.position.x, screen_bounds.position.x, screen_bounds.end.x - rect.size.x)
		rect.position.y = clampf(rect.position.y, screen_bounds.position.y, screen_bounds.end.y - rect.size.y)
		candidate["rect"] = rect
		if not rect.intersects(message_rect.grow(10.0)) and not rect.intersects(focus_rect.grow(8.0)):
			return candidate
	var fallback: Dictionary = candidates[0]
	var fallback_rect: Rect2 = fallback["rect"]
	fallback_rect.position.x = clampf(fallback_rect.position.x, screen_bounds.position.x, screen_bounds.end.x - fallback_rect.size.x)
	fallback_rect.position.y = clampf(fallback_rect.position.y, screen_bounds.position.y, screen_bounds.end.y - fallback_rect.size.y)
	fallback["rect"] = fallback_rect
	return fallback

func _tutorial_clear_overlay() -> void:
	if ui_layer == null:
		return
	for child in ui_layer.get_children():
		if child.name == "TutorialOverlay":
			ui_layer.remove_child(child)
			child.queue_free()

func _tutorial_message_rect(focus_rect: Rect2) -> Rect2:
	var step_text = _onboarding_line_text(tutorial_manager.current_step())
	var estimated_lines = maxi(1, int(ceil(float(step_text.length()) / 30.0)))
	var size := Vector2(760, clampf(112.0 + float(estimated_lines) * 24.0, 144.0, 190.0))
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
		"ROOM_SPIKE_CORRIDOR":
			return _tutorial_room_rect("spike_corridor")
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
		"FirstEnemy":
			return _tutorial_enemy_rect()
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
			if UISettings.is_touch_ui():
				return Rect2(screen_pos - Vector2(92, 98), Vector2(184, 196))
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
	if advanced and step_after == "TUT_120_TRAP_LURE" and rooms.has("spike_corridor"):
		selected_room = "spike_corridor"
		if current_screen == Constants.SCREEN_MANAGEMENT:
			_set_screen(Constants.SCREEN_MANAGEMENT)
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

func _handle_touch_combat_tap(point: Vector2, screen_point: Vector2) -> void:
	if current_screen != Constants.SCREEN_COMBAT or _combat_ui_at(screen_point):
		return
	_handle_left_click(point, screen_point)

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
			elif current_screen == Constants.SCREEN_MONSTER:
				_set_screen(Constants.SCREEN_MANAGEMENT)
			elif current_screen == Constants.SCREEN_MANAGEMENT:
				if map_editor_path_drag_active:
					_clear_map_editor_path_drag()
					map_editor_status = "드래그를 취소했습니다."
					_set_screen(Constants.SCREEN_MANAGEMENT)
				else:
					_cancel_management_action_mode()
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
	if _update4_council_mode_active() and OutpostEncounterServiceScript.is_battle_day(GameState.day):
		_start_update4_outpost_battle()
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
	if not _begin_update4_council_combat():
		return
	if onboarding_enabled and not GameState.onboarding_complete:
		_onboarding_set_stage(_onboarding_battle_stage_for_day(GameState.day))
		onboarding_boss_hp_thresholds.clear()
		onboarding_treasure_stolen_this_day = false
	else:
		_apply_campaign_combat_entry(GameState.day)
	combat_scene.start_combat()
	_tutorial_emit_action("combat_started", {"day": GameState.day})

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
	unit.effective_healed.connect(_on_update3_unit_effective_healed)
	unit.first_heart_control_applied.connect(_on_update3_first_control_applied)
	return unit


func _update3_unit_instance_id(unit: Node) -> String:
	if unit == null or not is_instance_valid(unit) or unit.faction != Constants.FACTION_MONSTER:
		return ""
	return ContractRosterServiceScript.instance_id_for_species(str(unit.unit_id), DataRegistry.monster_instances)


func _update3_duo_member_progress() -> Dictionary:
	var result: Dictionary = {}
	for instance_id_value in DataRegistry.monster_instances.keys():
		var instance_id := str(instance_id_value)
		var definition: Dictionary = DataRegistry.monster_instances.get(instance_id, {})
		var species_id := str(definition.get("species_id", ""))
		var roster: Dictionary = monster_roster.get(species_id, {})
		result[instance_id] = {
			"bond": int(roster.get("bond", definition.get("bond", 0))),
			"unlocked_memory_ids": roster.get("unlocked_memory_ids", definition.get("unlocked_memory_ids", [])).duplicate()
		}
	return result


func _prepare_update3_duo_link_battle() -> void:
	var deployed: Array = []
	for unit in monster_units:
		var instance_id := _update3_unit_instance_id(unit)
		if instance_id != "" and not deployed.has(instance_id):
			deployed.append(instance_id)
	update3_active_run = DuoLinkServiceScript.record_deployed_day(update3_active_run, deployed, GameState.day, DataRegistry.update3_duo_links)
	update3_active_run = DuoLinkServiceScript.begin_battle(update3_active_run, deployed, DataRegistry.update3_duo_links)
	var inactive_count := int(update3_active_run.get("duo_link_inactive_count", 0))
	if inactive_count > 0:
		_log("전투 시작 · 합동기 %d개 비활성(멤버 미출전)." % inactive_count)


func _record_update3_duo_link_action(member_instance_id: String, source_id: String, amount: int, event_token: String) -> int:
	var total_gain := 0
	update3_active_run = DuoLinkServiceScript.record_unlock_action(update3_active_run, member_instance_id, source_id, amount, event_token, DataRegistry.update3_duo_links)
	for link_id_value in update3_active_run.get("equipped_duo_links", []):
		var link_id := str(link_id_value)
		if not DataRegistry.update3_duo_links.get(link_id, {}).get("member_instance_ids", []).has(member_instance_id):
			continue
		var result := DuoLinkServiceScript.record_action(update3_active_run, link_id, member_instance_id, source_id, amount, event_token, DataRegistry.update3_duo_links)
		update3_active_run = result.get("active_run", update3_active_run).duplicate(true)
		total_gain += int(result.get("gain", 0))
		if bool(update3_active_run.get("duo_link_auto_use", false)) and bool(update3_active_run.get("duo_link_states", {}).get(link_id, {}).get("ready", false)):
			_activate_update3_duo_link(link_id)
	return total_gain


func _activate_update3_duo_link(requested_link_id: String = "") -> void:
	var activation_order: Array = update3_active_run.get("equipped_duo_links", []).duplicate()
	if requested_link_id != "" and activation_order.has(requested_link_id):
		activation_order.erase(requested_link_id)
		activation_order.push_front(requested_link_id)
	for link_id_value in activation_order:
		var link_id := str(link_id_value)
		if requested_link_id != "" and link_id != requested_link_id:
			continue
		var state: Dictionary = update3_active_run.get("duo_link_states", {}).get(link_id, {})
		if int(state.get("charge", 0)) < 100 or not bool(state.get("active", false)) or bool(state.get("used_this_battle", false)):
			continue
		var result := DuoLinkServiceScript.activate(update3_active_run, link_id, DataRegistry.update3_duo_links)
		if not bool(result.get("ok", false)):
			_log(str(result.get("error", "합동기를 발동하지 못했습니다.")))
			return
		update3_active_run = result.get("active_run", update3_active_run).duplicate(true)
		_record_update3_duo_link_use(link_id)
		match str(result.get("effect_handler", "")):
			"ghostly_evacuate": _apply_ghostly_evacuate(link_id)
			"moon_scent_hunt": _apply_moon_scent_hunt(link_id)
			"molten_carapace": _apply_molten_carapace(link_id)
			"stone_march": _apply_stone_march(link_id)
			"false_beacon_vault": _apply_false_beacon_vault(link_id)
			_: _apply_spore_jelly_shelter(link_id)
		_spawn_update3_duo_link_art(link_id)
		if combat_scene != null and combat_scene.has_method("trigger_leon_duo_response"):
			combat_scene.trigger_leon_duo_response(link_id)
		return
	_log("지금 발동할 수 있는 합동기가 없습니다.")


func _spawn_update3_duo_link_art(link_id: String) -> void:
	if effect_root == null:
		return
	var order := ["link_spore_jelly_shelter", "link_ghostly_evacuate", "link_moon_scent_hunt", "link_molten_carapace", "link_stone_march", "link_false_beacon_vault"]
	var index := order.find(link_id)
	if index < 0:
		return
	_play_update3_sfx(["duo_spore", "duo_ghost", "duo_moon", "duo_molten", "duo_stone", "duo_beacon"][index], -7.5)
	var members: Array[Node] = []
	var member_ids: Array = DataRegistry.update3_duo_links.get(link_id, {}).get("member_instance_ids", [])
	for unit in monster_units:
		if is_instance_valid(unit) and unit.is_alive() and _update3_unit_instance_id(unit) in member_ids:
			members.append(unit)
	var center := Vector2(960, 540)
	if not members.is_empty():
		center = Vector2.ZERO
		for member in members:
			center += member.global_position
		center /= float(members.size())
	var sheet := load("res://assets/ui/duo/duo_badges_vfx_sheet.png") as Texture2D
	if sheet == null:
		return
	var cell_size := Vector2(sheet.get_width() / 3.0, sheet.get_height() / 2.0)
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(index % 3, index / 3) * cell_size, cell_size)
	var sprite := Sprite2D.new()
	sprite.name = "DuoLinkVfx_%s" % link_id
	sprite.texture = atlas
	sprite.position = center
	sprite.scale = Vector2.ONE * 0.28
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); float m=min(c.r,c.b)-c.g; float balance=1.0-smoothstep(0.10,0.32,abs(c.r-c.b)); float k=smoothstep(0.10,0.34,m)*balance; c.a*=1.0-k; COLOR=c; }"
	var material := ShaderMaterial.new()
	material.shader = shader
	sprite.material = material
	effect_root.add_child(sprite)
	var tween := sprite.create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2.ONE * 0.58, 0.62).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.72).set_delay(0.34)
	tween.chain().tween_callback(sprite.queue_free)


func _record_update3_duo_link_use(link_id: String) -> void:
	if link_id == "":
		return
	var metrics: Dictionary = update3_active_run.get("run_metrics_update3", {}).duplicate(true)
	var campaign_used: Array = metrics.get("link_skills_used_campaign", []).duplicate()
	if not campaign_used.has(link_id):
		campaign_used.append(link_id)
	metrics["link_skills_used_campaign"] = campaign_used
	if GameState.day == REGULAR_CAMPAIGN_FINAL_DAY:
		var day30_used: Array = metrics.get("link_skills_used_day30", []).duplicate()
		if not day30_used.has(link_id):
			day30_used.append(link_id)
		metrics["link_skills_used_day30"] = day30_used
	update3_active_run["run_metrics_update3"] = metrics


func _apply_spore_jelly_shelter(link_id: String) -> void:
	var definition: Dictionary = DataRegistry.update3_duo_links.get(link_id, {})
	if str(definition.get("effect_handler", "")) != "spore_jelly_shelter":
		return
	var effect: Dictionary = definition.get("effect", {})
	var members: Array[Node] = []
	for unit in monster_units:
		if _update3_unit_instance_id(unit) in definition.get("member_instance_ids", []) and unit.is_alive():
			members.append(unit)
	if members.size() != 2:
		return
	var center: Vector2 = (members[0].global_position + members[1].global_position) * 0.5
	for member in members:
		member.apply_duo_action_lock(float(effect.get("action_lock_seconds", 0.6)))
	var affected := _apply_spore_jelly_shelter_tick(center, effect, true)
	var active_effects: Array = update3_active_run.get("duo_link_active_effects", []).duplicate(true)
	active_effects.append({"link_id": link_id, "center_x": center.x, "center_y": center.y, "remaining": maxf(0.0, float(effect.get("duration", 5.0)) - 1.0), "tick_accumulator": 0.0})
	update3_active_run["duo_link_active_effects"] = active_effects
	_log("포자 젤리 피난처 발동 · 아군 %d명에게 보호막·회복·정화를 적용했습니다." % affected)


func _apply_spore_jelly_shelter_tick(center: Vector2, effect: Dictionary, first_tick: bool) -> int:
	var affected := 0
	for ally in monster_units:
		if not is_instance_valid(ally) or not ally.is_alive() or ally.global_position.distance_to(center) > float(effect.get("radius", 190.0)):
			continue
		if first_tick:
			ally.grant_duo_barrier(int(effect.get("shield", 40)))
			ally.cleanse_one_negative_status()
		ally.heal(int(effect.get("heal_per_second", 3)), "duo_spore_jelly", first_tick and bool(effect.get("first_heal_ignores_fatigue", true)))
		affected += 1
	return affected


func _update3_duo_member_unit(instance_id: String) -> Node:
	for unit in monster_units:
		if is_instance_valid(unit) and _update3_unit_instance_id(unit) == instance_id:
			return unit
	return null


func _apply_ghostly_evacuate(link_id: String) -> void:
	var effect: Dictionary = DataRegistry.update3_duo_links.get(link_id, {}).get("effect", {})
	var pudding = _update3_duo_member_unit("mon_core_pudding")
	var bebe = _update3_duo_member_unit("monster_bebe")
	if pudding == null or bebe == null or not pudding.is_alive() or not bebe.is_alive():
		return
	var target: Node = null
	var lowest_ratio := INF
	for ally in monster_units:
		if not is_instance_valid(ally) or not ally.is_alive() or ally == pudding or ally == bebe:
			continue
		var ratio := float(ally.hp) / float(maxi(1, ally.max_hp))
		if ratio < lowest_ratio:
			lowest_ratio = ratio
			target = ally
	if target == null:
		target = bebe
	var direction: Vector2 = (pudding.global_position - bebe.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.LEFT
	target.global_position = pudding.global_position + direction * float(effect.get("safe_offset", 44.0))
	target.current_room = pudding.current_room
	target.apply_duo_damage_redirect(pudding, float(effect.get("duration", 4.0)), float(effect.get("redirect_fraction", 0.25)))
	pudding.apply_duo_penalty(float(effect.get("duration", 4.0)), float(effect.get("pudding_move_multiplier", 0.85)), 1.0)
	combat_scene.spawn_effect_burst("shield", target.global_position, Vector2(0, -14), Vector2(1.25, 1.25), 12.0)
	_log("유령 이사 대작전 발동 · %s을 푸딩 뒤로 옮기고 4초 동안 피해를 나눠 받습니다." % target.display_name)


func _apply_moon_scent_hunt(link_id: String) -> void:
	var effect: Dictionary = DataRegistry.update3_duo_links.get(link_id, {}).get("effect", {})
	var gob = _update3_duo_member_unit("mon_core_gob")
	var koko = _update3_duo_member_unit("monster_koko")
	if gob == null or koko == null or not gob.is_alive() or not koko.is_alive():
		return
	var candidates: Array[Node] = []
	for enemy in enemy_units:
		if is_instance_valid(enemy) and enemy.is_alive() and (float(enemy.duo_mark_timer) > 0.0 or float(enemy.scent_mark_timer) > 0.0):
			candidates.append(enemy)
	if candidates.is_empty():
		return
	candidates.sort_custom(func(a: Node, b: Node): return int(a.atk) > int(b.atk))
	var target: Node = candidates[0]
	for member in [gob, koko]:
		var offset: Vector2 = target.global_position - member.global_position
		var travel := minf(float(effect.get("approach_distance", 140.0)), maxf(0.0, offset.length() - 34.0))
		if offset.length() > 0.01:
			member.global_position += offset.normalized() * travel
		member.play_attack(target.global_position)
	var total_cap := int(effect.get("direct_damage_cap", 80))
	var per_hit_cap := maxi(1, total_cap / 2)
	var first := mini(per_hit_cap, DamageService.compute(gob, target, 1.0))
	var dealt_first: int = target.receive_damage(first)
	var second := mini(maxi(0, total_cap - dealt_first), DamageService.compute(koko, target, 1.0))
	var dealt_second: int = target.receive_damage(second) if second > 0 and target.is_alive() else 0
	target.apply_armor_break(int(effect.get("boss_def_reduction", 1)) if _update3_enemy_is_boss(target) else int(effect.get("normal_def_reduction", 2)), float(effect.get("def_reduction_seconds", 5.0)), link_id)
	for member in [gob, koko]:
		member.apply_duo_penalty(float(effect.get("member_vulnerable_seconds", 3.0)), 1.0, float(effect.get("member_damage_taken_multiplier", 1.10)))
	combat_scene.spawn_effect_burst("slash", target.global_position, Vector2(0, -12), Vector2(1.4, 1.4), 16.0)
	_log("달빛 냄새 추격 발동 · 표식 대상에게 합계 %d 피해를 주고 방어를 낮췄습니다." % [dealt_first + dealt_second])


func _apply_molten_carapace(link_id: String) -> void:
	var effect: Dictionary = DataRegistry.update3_duo_links.get(link_id, {}).get("effect", {})
	var pynn = _update3_duo_member_unit("mon_core_pynn")
	var toktok = _update3_duo_member_unit("monster_toktok")
	if pynn == null or toktok == null or not pynn.is_alive() or not toktok.is_alive() or enemy_units.is_empty():
		return
	var target: Node = null
	var nearest := INF
	for enemy in enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive():
			continue
		var distance: float = toktok.global_position.distance_to(enemy.global_position)
		if distance < nearest:
			nearest = distance
			target = enemy
	if target == null:
		return
	var offset: Vector2 = target.global_position - toktok.global_position
	if offset.length() > 0.01:
		toktok.global_position += offset.normalized() * minf(float(effect.get("dash_distance", 140.0)), maxf(0.0, offset.length() - 28.0))
	var targets: Array = []
	for enemy in enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive() or enemy.global_position.distance_to(toktok.global_position) > float(effect.get("radius", 90.0)):
			continue
		var dealt: int = enemy.receive_damage(int(effect.get("impact_damage", 26)))
		enemy.apply_armor_break(int(effect.get("def_reduction", 1)), float(effect.get("def_reduction_seconds", 5.0)), link_id)
		targets.append({"node_id": enemy.get_instance_id(), "remaining": float(effect.get("burn_seconds", 5.0)), "tick_accumulator": 0.0, "damage_done": dealt})
	toktok.skill_cooldowns["patch_plates"] = float(toktok.skill_cooldowns.get("patch_plates", 0.0)) + float(effect.get("repair_cooldown_penalty", 3.0))
	var active_effects: Array = update3_active_run.get("duo_link_active_effects", []).duplicate(true)
	active_effects.append({"kind": "molten_carapace_burn", "link_id": link_id, "remaining": float(effect.get("burn_seconds", 5.0)), "targets": targets})
	update3_active_run["duo_link_active_effects"] = active_effects
	combat_scene.spawn_effect_burst("impact", toktok.global_position, Vector2(0, -10), Vector2(1.7, 1.7), 16.0)
	_log("용융 갑각포 발동 · 반경 내 적 %d명에게 충격과 화상을 남겼습니다." % targets.size())


func _apply_stone_march(link_id: String) -> void:
	var effect: Dictionary = DataRegistry.update3_duo_links.get(link_id, {}).get("effect", {})
	var dolkong = _update3_duo_member_unit("mon_contract_dolkong")
	if dolkong == null or not dolkong.is_alive():
		return
	var radius := float(effect.get("radius", 180.0))
	var hit_count := 0
	var morale_total := 0
	for enemy in enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive() or enemy.global_position.distance_to(dolkong.global_position) > radius:
			continue
		var hp_before := int(enemy.hp)
		var dealt: int = enemy.receive_damage(int(effect.get("damage", 12)))
		combat_scene._record_damage_contribution(dolkong, enemy, int(effect.get("damage", 12)), dealt, hp_before, "", "stone_march:%d:%d" % [dolkong.get_instance_id(), enemy.get_instance_id()])
		morale_total += enemy.receive_morale_damage(int(effect.get("morale_damage", 30)))
		hit_count += 1
	for ally in monster_units:
		if is_instance_valid(ally) and ally.is_alive() and ally.global_position.distance_to(dolkong.global_position) <= radius:
			ally.apply_duo_march_buff(float(effect.get("ally_buff_seconds", 5.0)), int(effect.get("ally_def_bonus", 1)), float(effect.get("ally_move_multiplier", 1.06)))
	dolkong.apply_duo_move_lock(float(effect.get("dolkong_move_lock_seconds", 2.0)))
	combat_scene.spawn_effect_burst("guard", dolkong.global_position, Vector2(0, -12), Vector2(1.6, 1.2), 14.0)
	_log("석상 행진곡 발동 · 적 %d명에게 피해와 사기 피해 %d를 주었습니다." % [hit_count, morale_total])


func _apply_false_beacon_vault(link_id: String) -> void:
	var effect: Dictionary = DataRegistry.update3_duo_links.get(link_id, {}).get("effect", {})
	var lumi = _update3_duo_member_unit("mon_contract_lumi")
	var mimi = _update3_duo_member_unit("mon_contract_mimi")
	if lumi == null or mimi == null or not lumi.is_alive() or not mimi.is_alive():
		return
	var beacon_position: Vector2 = mimi.global_position
	var candidates: Array[Node] = []
	var excluded_ids: Array = effect.get("excluded_unit_ids", [])
	for enemy in enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive():
			continue
		if str(enemy.role) == str(effect.get("appraiser_role", "appraiser")):
			enemy.apply_duo_mark(float(effect.get("mark_seconds", 6.0)), "mon_contract_lumi")
			continue
		if excluded_ids.has(str(enemy.unit_id)):
			continue
		candidates.append(enemy)
	candidates.sort_custom(func(a: Node, b: Node): return a.global_position.distance_squared_to(beacon_position) < b.global_position.distance_squared_to(beacon_position))
	var targets: Array = []
	var max_targets := mini(int(effect.get("max_lured_normal_enemies", 2)), candidates.size())
	for index in range(max_targets):
		var target: Node = candidates[index]
		targets.append({"node_id": target.get_instance_id(), "original_goal": str(target.goal_room)})
		combat_scene.move_unit_to_point(target, beacon_position)
	var active_effects: Array = update3_active_run.get("duo_link_active_effects", []).duplicate(true)
	active_effects.append({"kind": "false_beacon_vault", "link_id": link_id, "center_x": beacon_position.x, "center_y": beacon_position.y, "remaining": float(effect.get("duration", 6.0)), "lure_remaining": float(effect.get("lure_seconds", 3.0)), "targets": targets, "checked": false, "penalty_applied": false})
	update3_active_run["duo_link_active_effects"] = active_effects
	combat_scene.spawn_effect_burst("loot", beacon_position, Vector2(0, -20), Vector2(1.4, 1.2), 13.0)
	_log("가짜 등대 금고 발동 · 일반 적 %d명을 등대로 유인했습니다." % targets.size())


func _update_false_beacon_effect(effect_state: Dictionary, delta_scaled: float, effect: Dictionary) -> Dictionary:
	var result := effect_state.duplicate(true)
	var previous_lure := float(result.get("lure_remaining", 0.0))
	result["remaining"] = maxf(0.0, float(result.get("remaining", 0.0)) - delta_scaled)
	result["lure_remaining"] = maxf(0.0, previous_lure - delta_scaled)
	if previous_lure > 0.0 and float(result.get("lure_remaining", 0.0)) <= 0.0 and not bool(result.get("checked", false)):
		for target_value in result.get("targets", []):
			if not (target_value is Dictionary):
				continue
			var target = instance_from_id(int(target_value.get("node_id", 0)))
			if target != null and is_instance_valid(target) and target.is_alive():
				target.apply_duo_mark(float(effect.get("mark_seconds", 6.0)), "mon_contract_lumi")
				var original_goal := str(target_value.get("original_goal", ""))
				if original_goal != "":
					combat_scene.move_unit_to_room(target, original_goal)
		result["checked"] = true
	if float(result.get("remaining", 0.0)) <= 0.0 and not bool(result.get("penalty_applied", false)):
		var mimi = _update3_duo_member_unit("mon_contract_mimi")
		if mimi != null and is_instance_valid(mimi):
			mimi.skill_cooldowns["false_treasure"] = float(mimi.skill_cooldowns.get("false_treasure", 0.0)) + float(effect.get("mimi_cooldown_penalty", 4.0))
		result["penalty_applied"] = true
	return result


func _update_molten_carapace_burn(effect_state: Dictionary, delta_scaled: float, effect: Dictionary) -> Dictionary:
	var result := effect_state.duplicate(true)
	result["remaining"] = maxf(0.0, float(result.get("remaining", 0.0)) - delta_scaled)
	var targets: Array = []
	for target_value in result.get("targets", []):
		if not (target_value is Dictionary):
			continue
		var target_state: Dictionary = target_value.duplicate(true)
		var target = instance_from_id(int(target_state.get("node_id", 0)))
		var accumulator := float(target_state.get("tick_accumulator", 0.0)) + delta_scaled
		var damage_done := int(target_state.get("damage_done", 0))
		while accumulator >= 1.0 and damage_done < int(effect.get("direct_damage_cap", 41)):
			accumulator -= 1.0
			if target != null and is_instance_valid(target) and target.is_alive():
				var tick_damage := mini(int(effect.get("burn_damage_per_second", 3)), int(effect.get("direct_damage_cap", 41)) - damage_done)
				damage_done += int(target.receive_magic_damage(tick_damage))
		target_state["tick_accumulator"] = accumulator
		target_state["damage_done"] = damage_done
		targets.append(target_state)
	result["targets"] = targets
	return result


func _update3_duo_link_effects(delta: float) -> void:
	if current_screen != Constants.SCREEN_COMBAT or combat_paused:
		return
	var active_effects: Array = update3_active_run.get("duo_link_active_effects", []).duplicate(true)
	if active_effects.is_empty():
		return
	var next_effects: Array = []
	for value in active_effects:
		if not (value is Dictionary):
			continue
		var effect_state: Dictionary = value.duplicate(true)
		var link_id := str(effect_state.get("link_id", ""))
		var effect: Dictionary = DataRegistry.update3_duo_links.get(link_id, {}).get("effect", {})
		if str(effect_state.get("kind", "")) == "false_beacon_vault":
			effect_state = _update_false_beacon_effect(effect_state, delta * combat_speed, effect)
			if float(effect_state.get("remaining", 0.0)) > 0.0:
				next_effects.append(effect_state)
			continue
		if str(effect_state.get("kind", "")) == "molten_carapace_burn":
			effect_state = _update_molten_carapace_burn(effect_state, delta * combat_speed, effect)
			if float(effect_state.get("remaining", 0.0)) > 0.0:
				next_effects.append(effect_state)
			continue
		var remaining := maxf(0.0, float(effect_state.get("remaining", 0.0)) - delta * combat_speed)
		var accumulator := float(effect_state.get("tick_accumulator", 0.0)) + delta * combat_speed
		while accumulator >= 1.0:
			accumulator -= 1.0
			_apply_spore_jelly_shelter_tick(Vector2(float(effect_state.get("center_x", 0.0)), float(effect_state.get("center_y", 0.0))), effect, false)
		effect_state["remaining"] = remaining
		effect_state["tick_accumulator"] = accumulator
		if remaining > 0.0:
			next_effects.append(effect_state)
	update3_active_run["duo_link_active_effects"] = next_effects


func _update3_duo_link_result_lines() -> Array[String]:
	var used_names: Array[String] = []
	for link_id_value in update3_active_run.get("duo_link_states", {}).keys():
		var link_id := str(link_id_value)
		if bool(update3_active_run.get("duo_link_states", {}).get(link_id, {}).get("used_this_battle", false)):
			used_names.append(str(DataRegistry.update3_duo_links.get(link_id, {}).get("display_name", link_id)))
	update3_profile = DuoLinkServiceScript.settle_profile(update3_profile, update3_active_run, campaign_cycle_index)
	if used_names.is_empty():
		return []
	return ["합동기 사용: %s" % ", ".join(used_names)]

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
	stats["max_hp"] = maxi(1, int(round(float(stats.get("max_hp", 1)) * _update2_cycle_effect_value("monster_hp_multiplier", 1.0))))
	stats["atk"] = maxi(1, int(round(float(stats.get("atk", 1)) * _update2_cycle_effect_value("monster_atk_multiplier", 1.0))))
	if selected_contract_ids.has(monster_id):
		stats["atk"] = maxi(1, int(round(float(stats.get("atk", 1)) * _update2_cycle_effect_value("contract_atk_multiplier", 1.0))))
	_apply_update4_crown_stats(monster_id, stats)
	return stats


func _apply_update4_crown_stats(monster_id: String, stats: Dictionary) -> void:
	if not _update4_council_mode_active():
		return
	var crown_state: Dictionary = update4_active_run.get("crown", {})
	var crown_id := str(crown_state.get("crown_form_id", ""))
	var instance_id := str(crown_state.get("selected_instance_id", ""))
	if crown_id == "" or str(DataRegistry.monster_instances.get(instance_id, {}).get("species_id", "")) != monster_id:
		return
	var crown: Dictionary = DataRegistry.update4_crown_evolutions.get(crown_id, {})
	if bool(update4_active_run.get("upper_floor", {}).get("crown_suppressed", false)):
		return
	for stat_id_value in crown.get("stat_multipliers", {}).keys():
		var stat_id := str(stat_id_value)
		stats[stat_id] = float(stats.get(stat_id, 0.0)) * float(crown.get("stat_multipliers", {}).get(stat_id_value, 1.0))
		if stat_id not in ["move_speed", "attack_range", "attack_interval"]:
			stats[stat_id] = int(round(float(stats[stat_id])))
	stats["sprite"] = str(crown.get("combat_sprite", stats.get("sprite", "")))
	stats["crown_form_id"] = crown_id

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
	var promotion_behavior := str(_monster_promotion_rule(monster_id).get("ai_behavior", ""))
	if promotion_behavior != "":
		return promotion_behavior
	if monster_id == "ghost_housemaid":
		return "rescue_support"
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
	var role_tag = _promotion_role_display_name(str(rule.get("role_tag", "role")))
	if str(monster_roster[selected_monster_id].get("promotion_id", "")) != "":
		return "%s / %s / %s" % [str(rule.get("display_name", "")), role_tag, str(rule.get("role_summary", ""))]
	return "%s 후보 / %s / %s" % [str(rule.get("display_name", "")), role_tag, str(rule.get("balance_note", ""))]

func _promotion_role_display_name(role_tag: String) -> String:
	return str({
		"blocker": "전열 방벽",
		"support_blocker": "구조 지원",
		"chaser": "기동 추격",
		"vault_guard": "금고 수호",
		"caster": "원거리 화력",
		"zone_support": "구역 지원"
	}.get(role_tag, role_tag))

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
	battle_contribution_events.clear()
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
	if key in ["damage_dealt", "damage_absorbed", "finishing_blows", "facility_value"]:
		battle_contribution_events.append({"time": combat_time, "monster_id": monster_id, "key": key, "amount": amount})


func _recent_monster_contribution_scores(window_seconds: float = 20.0) -> Dictionary:
	var scores: Dictionary = {}
	var weights: Dictionary = DataRegistry.skill("bounty_target").get("contribution_weights", {})
	var cutoff := combat_time - maxf(0.0, window_seconds)
	for event in battle_contribution_events:
		if float(event.get("time", -INF)) < cutoff:
			continue
		var monster_id := str(event.get("monster_id", ""))
		if monster_id == "":
			continue
		var key := str(event.get("key", ""))
		var weight := float(weights.get(key, 1.0))
		scores[monster_id] = float(scores.get(monster_id, 0.0)) + float(event.get("amount", 0)) * weight
	return scores


func _legacy_monster_species_id() -> String:
	return str(inherited_legacy_monster.get("species_id", inherited_legacy_monster.get("monster_id", "")))

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
	var duo_instance_id := _update3_unit_instance_id(unit)
	if duo_instance_id != "":
		update3_active_run = DuoLinkServiceScript.member_downed(update3_active_run, duo_instance_id, DataRegistry.update3_duo_links)
	combat_scene.on_unit_downed(unit)
	if unit.faction == Constants.FACTION_ENEMY:
		_refresh_combat_music_variant()

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
	if bool(result_summary.get("outpost_battle", false)):
		_advance_after_result()
		return
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
	if not bool(result_summary.get("win", false)):
		_prepare_regular_defense_retry()
		return
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _prepare_regular_defense_retry() -> void:
	GameState.victory = false
	GameState.defeat = false
	GameState.demon_lord_hp = GameState.demon_lord_max_hp
	SignalBus.resources_changed.emit()
	_clear_units()
	_clear_effects()
	_reset_engineer_combat_state()
	result_summary.clear()
	last_growth_summary.clear()
	result_growth_reviewed = false
	result_growth_choice_monster_id = ""
	result_growth_choice_applied = false
	last_growth_choice_summary.clear()
	_log("DAY %d 방어전을 다시 준비합니다. 왕좌 체력을 완전히 복구했습니다." % GameState.day)
	_enter_campaign_management_day(false)

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
	var training_block_reason := _training_block_reason(selected_monster_id)
	if training_block_reason != "":
		_log("훈련할 수 없습니다: %s." % training_block_reason)
		_set_screen(Constants.SCREEN_MONSTER)
		return
	if not GameState.pay({"gold": 30}):
		_log("훈련 비용이 부족합니다.")
		return
	var roster: Dictionary = monster_roster[selected_monster_id]
	if int(roster.get("training_day", 0)) != GameState.day:
		roster["training_day"] = GameState.day
		roster["training_count_today"] = 0
	roster["exp"] = int(roster["exp"]) + 20
	roster["training_count_today"] = int(roster.get("training_count_today", 0)) + 1
	var gained_levels = _apply_monster_levelups(selected_monster_id)
	if gained_levels > 0:
		_log("%s 레벨 업." % DataRegistry.monster(selected_monster_id).get("display_name", selected_monster_id))
	else:
		_log("%s 훈련 완료." % DataRegistry.monster(selected_monster_id).get("display_name", selected_monster_id))
	_set_screen(Constants.SCREEN_MONSTER)

func _training_level_cap() -> int:
	if GameState.day <= 10:
		return 3
	if GameState.day <= 20:
		return 5
	return 8

func _training_block_reason(monster_id: String) -> String:
	if not monster_roster.has(monster_id):
		return "대상을 찾을 수 없음"
	var roster: Dictionary = monster_roster[monster_id]
	if int(roster.get("level", 1)) >= _training_level_cap():
		return "현재 장의 훈련 상한 Lv.%d" % _training_level_cap()
	var count_today := int(roster.get("training_count_today", 0)) if int(roster.get("training_day", 0)) == GameState.day else 0
	if count_today >= 2:
		return "오늘 훈련 2회 완료"
	return ""

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
	if bool(rooms[room_id].get("fixed", false)):
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
	_record_directive_use(directive)
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
	var allowed_values: Array = _room_directive_options(selected_room).map(func(option): return str(option.get("value", "")))
	if not allowed_values.has(directive):
		_log("이 방에는 %s 지침을 적용할 수 없습니다." % DirectiveManager.directive_label(directive))
		return
	if not _tutorial_allows("room_directive_set", {"directive": directive, "room_id": selected_room}):
		return
	var screen_before = current_screen
	combat_scene.set_room_directive(directive)
	_record_directive_use(directive)
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

func _room_directive_options(room_id: String) -> Array:
	var options: Array = [{"label": "기본", "value": Constants.ROOM_DIRECTIVE_NONE}]
	if room_id in ["entrance", "spike_corridor"]:
		options.append({"label": "집중 방어", "value": Constants.ROOM_DIRECTIVE_ENTRY_BLOCK})
	if room_id == "spike_corridor":
		options.append({"label": "함정 유도", "value": Constants.ROOM_DIRECTIVE_TRAP_LURE})
	if rooms.has(room_id) and str(rooms[room_id].get("type", "")) not in ["core", "build_slot"]:
		options.append({"label": "후퇴 지점", "value": Constants.ROOM_DIRECTIVE_RETREAT})
	return options

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
	if speed > 1.0 and not _combat_speed_unlocked():
		combat_scene.set_speed(1.0)
		_log("전투 가속은 튜토리얼 완료 후 사용할 수 있습니다.")
		return
	combat_scene.set_speed(speed)

func _toggle_pause() -> void:
	combat_scene.toggle_pause()

func _unit_at(point: Vector2) -> Node:
	var best: Node = null
	var best_distance = 96.0 if UISettings.is_touch_ui() else 36.0
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
	var best_distance = INF
	for unit in enemy_units:
		if not unit.is_alive():
			continue
		var pick_half_size := Vector2(96, 110) if UISettings.is_touch_ui() else Vector2(52, 70)
		var pick_rect := Rect2(unit.global_position - pick_half_size, pick_half_size * 2.0)
		if not pick_rect.has_point(point):
			continue
		var distance = unit.global_position.distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best = unit
	return best

func _combat_ui_at(point: Vector2) -> bool:
	if current_screen != Constants.SCREEN_COMBAT:
		return false
	if UISettings.is_touch_ui():
		return Rect2(16, 10, 1870, 70).has_point(point) or Rect2(390, 92, 430, 116).has_point(point) or Rect2(220, 730, 1480, 338).has_point(point)
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
	if UISettings.is_touch_ui() and (Rect2(330, 640, 1260, 190).has_point(point) or Rect2(98, 842, 1725, 210).has_point(point)):
		return true
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
	var best_distance = 104.0 if UISettings.is_touch_ui() else 48.0
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
	if combat_scene == null:
		return
	for telegraph_value in combat_scene.acid_telegraphs:
		var telegraph: Dictionary = telegraph_value
		var telegraph_center := Vector2(telegraph.get("position", Vector2.ZERO))
		var telegraph_radius := float(telegraph.get("radius", 85.0))
		var total := maxf(0.01, float(telegraph.get("total", 0.8)))
		var remaining := float(telegraph.get("remaining", 0.0))
		var ratio := clampf(remaining / total, 0.0, 1.0)
		draw_circle(telegraph_center, telegraph_radius, Color("#d7ef3a18"))
		draw_arc(telegraph_center, telegraph_radius, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - ratio), 72, Color("#e8ff58"), 4.0)
		for spoke in range(8):
			var direction := Vector2.RIGHT.rotated(TAU * float(spoke) / 8.0)
			draw_line(telegraph_center + direction * (telegraph_radius - 16.0), telegraph_center + direction * telegraph_radius, Color("#f0ff86cc"), 2.0)
		var warning_rect := Rect2(telegraph_center + Vector2(-66, -telegraph_radius - 30), Vector2(132, 22))
		draw_rect(warning_rect, Color("#151906e8"), true)
		draw_rect(warning_rect, Color("#dff35c"), false, 1.5)
		draw_string(UI_FONT, warning_rect.position + Vector2(0, 16), "산성 예고 %.1f초" % remaining, HORIZONTAL_ALIGNMENT_CENTER, warning_rect.size.x, 12, Color("#f6ffc4"))
	for zone_value in combat_scene.acid_zones:
		var zone: Dictionary = zone_value
		var zone_center := Vector2(zone.get("position", Vector2.ZERO))
		var zone_radius := float(zone.get("radius", 85.0))
		draw_circle(zone_center, zone_radius, Color("#6d991f28"))
		draw_arc(zone_center, zone_radius, 0.0, TAU, 72, Color("#a9d63fdd"), 3.0)
		for offset in range(-60, 61, 24):
			var half := sqrt(maxf(0.0, zone_radius * zone_radius - float(offset * offset)))
			draw_line(zone_center + Vector2(-half, float(offset)), zone_center + Vector2(half, float(offset) + 18.0), Color("#bce85a45"), 1.5)
		var zone_rect := Rect2(zone_center + Vector2(-72, -zone_radius - 30), Vector2(144, 22))
		draw_rect(zone_rect, Color("#101506e8"), true)
		draw_rect(zone_rect, Color("#91bd35"), false, 1.5)
		draw_string(UI_FONT, zone_rect.position + Vector2(0, 16), "산성 구역 %.1f초" % float(zone.get("remaining", 0.0)), HORIZONTAL_ALIGNMENT_CENTER, zone_rect.size.x, 12, Color("#e9ffc0"))
	for floor_value in combat_scene.selen_consecrated_floors:
		var holy_floor: Dictionary = floor_value
		var floor_center := Vector2(holy_floor.get("position", Vector2.ZERO))
		var floor_radius := float(holy_floor.get("radius", 92.0))
		draw_circle(floor_center, floor_radius, Color("#f7df7824"))
		draw_arc(floor_center, floor_radius, 0.0, TAU, 72, Color("#fff1a8dd"), 3.0)
		for ray_index in range(8):
			var ray := Vector2.RIGHT.rotated(TAU * float(ray_index) / 8.0)
			draw_line(floor_center + ray * 20.0, floor_center + ray * (floor_radius - 8.0), Color("#ffe99155"), 2.0)
		var floor_label := Rect2(floor_center + Vector2(-76, -floor_radius - 28), Vector2(152, 22))
		draw_rect(floor_label, Color("#17130ae8"), true)
		draw_rect(floor_label, Color("#f4d877"), false, 1.5)
		draw_string(UI_FONT, floor_label.position + Vector2(0, 16), "축성 바닥 %.1f초" % float(holy_floor.get("remaining", 0.0)), HORIZONTAL_ALIGNMENT_CENTER, floor_label.size.x, 12, Color("#fff5cb"))
	for state_value in combat_scene.official_selen_states.values():
		var selen_state: Dictionary = state_value
		var inspection_mode := str(selen_state.get("inspection_mode", "idle"))
		var target_room := str(selen_state.get("inspection_target", ""))
		if inspection_mode not in ["telegraph", "mark"] or not rooms.has(target_room):
			continue
		var inspection_rect: Rect2 = graph.rect(target_room).grow(10.0)
		var inspection_color := Color("#fff0a5") if inspection_mode == "telegraph" else Color("#f4c95f")
		draw_rect(inspection_rect, Color(inspection_color.r, inspection_color.g, inspection_color.b, 0.15), true)
		draw_rect(inspection_rect, inspection_color, false, 4.0)
		var inspection_label := Rect2(Vector2(inspection_rect.get_center().x - 86.0, inspection_rect.position.y - 30.0), Vector2(172, 24))
		draw_rect(inspection_label, Color("#17120aeb"), true)
		draw_rect(inspection_label, inspection_color, false, 1.5)
		var inspection_text := "검수 예고" if inspection_mode == "telegraph" else "검수 중 · 피해 55"
		draw_string(UI_FONT, inspection_label.position + Vector2(0, 17), "%s %.1f초" % [inspection_text, float(selen_state.get("inspection_timer", 0.0))], HORIZONTAL_ALIGNMENT_CENTER, inspection_label.size.x, 12, Color("#fff5ca"))
	for state_value in combat_scene.commissioner_roman_states.values():
		var roman_state: Dictionary = state_value
		var roman_unit = instance_from_id(int(roman_state.get("unit_id", 0)))
		if roman_unit != null and is_instance_valid(roman_unit):
			var budget_label := Rect2(roman_unit.global_position + Vector2(-82, -134), Vector2(164, 24))
			draw_rect(budget_label, Color("#170e09e8"), true)
			draw_rect(budget_label, Color("#c88a55"), false, 1.5)
			draw_string(UI_FONT, budget_label.position + Vector2(0, 17), "예산 %d/5 · 스트레스 %d/5" % [int(roman_state.get("budget", 0)), int(roman_state.get("stress", 0))], HORIZONTAL_ALIGNMENT_CENTER, budget_label.size.x, 12, Color("#ffe0bd"))
		var freeze_mode := str(roman_state.get("freeze_mode", "idle"))
		var freeze_room := str(roman_state.get("freeze_target", ""))
		if freeze_mode == "telegraph" and rooms.has(freeze_room):
			var freeze_rect: Rect2 = graph.rect(freeze_room).grow(10.0)
			draw_rect(freeze_rect, Color("#bd704022"), true)
			draw_rect(freeze_rect, Color("#e39a62"), false, 4.0)
			var freeze_label := Rect2(Vector2(freeze_rect.get_center().x - 88.0, freeze_rect.position.y - 30.0), Vector2(176, 24))
			draw_rect(freeze_label, Color("#170e09eb"), true)
			draw_rect(freeze_label, Color("#e39a62"), false, 1.5)
			draw_string(UI_FONT, freeze_label.position + Vector2(0, 17), "자산 동결 · 피해 50 · %.1f초" % float(roman_state.get("freeze_timer", 0.0)), HORIZONTAL_ALIGNMENT_CENTER, freeze_label.size.x, 12, Color("#ffe1c5"))
	for cast_value in combat_scene.purifying_hymn_casts:
		var cast: Dictionary = cast_value
		var cast_center := Vector2(cast.get("position", Vector2.ZERO))
		var cast_radius := float(cast.get("radius", 180.0))
		var total := maxf(0.01, float(cast.get("total", 1.2)))
		var remaining := float(cast.get("remaining", 0.0))
		var ratio := clampf(remaining / total, 0.0, 1.0)
		draw_circle(cast_center, cast_radius, Color("#fff0a512"))
		draw_arc(cast_center, cast_radius, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - ratio), 96, Color("#ffe58a"), 3.5)
		var cast_rect := Rect2(cast_center + Vector2(-78, -cast_radius - 30), Vector2(156, 22))
		draw_rect(cast_rect, Color("#19150ae8"), true)
		draw_rect(cast_rect, Color("#ffe58a"), false, 1.5)
		draw_string(UI_FONT, cast_rect.position + Vector2(0, 16), "정화 성가 %.1f초" % remaining, HORIZONTAL_ALIGNMENT_CENTER, cast_rect.size.x, 12, Color("#fff7cf"))
	for cast_value in combat_scene.ledger_mark_casts:
		var cast: Dictionary = cast_value
		var cast_center := Vector2(cast.get("position", Vector2.ZERO))
		var total := maxf(0.01, float(cast.get("total", 1.0)))
		var remaining := float(cast.get("remaining", 0.0))
		var ratio := clampf(remaining / total, 0.0, 1.0)
		draw_circle(cast_center, 52.0, Color("#d983381c"))
		draw_arc(cast_center, 52.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - ratio), 56, Color("#f0ad67"), 4.0)
		var cast_rect := Rect2(cast_center + Vector2(-72, -82), Vector2(144, 22))
		draw_rect(cast_rect, Color("#1d1008e8"), true)
		draw_rect(cast_rect, Color("#e59c55"), false, 1.5)
		draw_string(UI_FONT, cast_rect.position + Vector2(0, 16), "부채 표식 예고 %.1f초" % remaining, HORIZONTAL_ALIGNMENT_CENTER, cast_rect.size.x, 12, Color("#ffe0b5"))
	for room_id_value in combat_scene.ledger_room_marks.keys():
		var room_id := str(room_id_value)
		if not rooms.has(room_id):
			continue
		var mark: Dictionary = combat_scene.ledger_room_marks.get(room_id, {})
		var room_rect: Rect2 = graph.rect(room_id)
		var debt := int(mark.get("debt", 0))
		draw_rect(room_rect.grow(12.0), Color("#9b4f2524"), true)
		draw_rect(room_rect.grow(12.0), Color("#e99a55dd"), false, 3.0)
		var mark_rect := Rect2(Vector2(room_rect.get_center().x - 82.0, room_rect.end.y + 6.0), Vector2(164, 24))
		draw_rect(mark_rect, Color("#160c08eb"), true)
		draw_rect(mark_rect, Color("#e99a55"), false, 1.5)
		draw_string(UI_FONT, mark_rect.position + Vector2(0, 17), "부채 %d/3 · %.1f초" % [debt, float(mark.get("remaining", 0.0))], HORIZONTAL_ALIGNMENT_CENTER, mark_rect.size.x, 12, Color("#ffe2bd"))

func _draw_update3_heart_hud() -> void:
	if current_screen != Constants.SCREEN_COMBAT:
		return
	var heart: Dictionary = update3_active_run.get("heart", {})
	if str(heart.get("heart_id", "")) == "" or not bool(heart.get("awakened", false)):
		return
	var rect := Rect2(760, 82, 400, 42)
	var charge := int(heart.get("charge", 0))
	var active_remaining := float(heart.get("active_remaining", 0.0))
	var disabled := bool(heart.get("disabled_this_battle", false))
	var charge_suppressed := float(heart.get("charge_suppressed_remaining", 0.0))
	var debt_disabled := float(heart.get("debt_disabled_remaining", 0.0))
	var active_locked := float(heart.get("active_locked_remaining", 0.0))
	var color := Color("#77717d") if disabled else Color("#c68aa8")
	draw_rect(rect, Color("#0b0810e8"), true)
	draw_rect(rect, color, false, 2.0)
	draw_rect(Rect2(rect.position + Vector2(10, 27), Vector2(250.0 * float(charge) / 100.0, 6)), Color("#b94f84"), true)
	var hungry := str(heart.get("heart_id", "")) == CastleHeartServiceScript.HUNGRY_MAW_ID
	var dream := str(heart.get("heart_id", "")) == CastleHeartServiceScript.DREAM_LANTERN_ID
	var active_label := "가짜 복도 %.1f초" % active_remaining if dream else ("포식 %.1f초" % active_remaining if hungry else "버티기 %.1f초" % active_remaining)
	var state := "비활성" if disabled else ("부채 무력화 %.1f초" % debt_disabled if debt_disabled > 0.0 else ("액티브 잠금 %.1f초" % active_locked if active_locked > 0.0 else ("충전 봉쇄 %.1f초" % charge_suppressed if charge_suppressed > 0.0 else (active_label if active_remaining > 0.0 else ("H키 사용 가능" if charge >= 100 and not bool(heart.get("active_used_this_battle", false)) else "충전 중")))))
	var name := "몽등 심장" if dream else ("포식 심장 %d/5" % int(heart.get("hunger", 0)) if hungry else "석골 심장")
	draw_string(UI_FONT, rect.position + Vector2(12, 21), "%s  %d/100  ·  %s" % [name, charge, state], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24, 14, Color("#fff0f5"))

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


func _disable_facility_room_by_debt(room_id: String, seconds: float) -> bool:
	if not rooms.has(room_id):
		return false
	var role := str(rooms[room_id].get("facility_role", ""))
	if role in ["", "entry", "trap", "corridor", "core", "build_slot", "heart_chamber"]:
		return false
	var was_active := _facility_room_is_active(room_id)
	facility_disabled_timers[room_id] = maxf(_facility_room_disabled_remaining(room_id), maxf(0.0, seconds))
	facility_feedback_redraw_accumulator = 0.0
	queue_redraw()
	return was_active

func _update_facility_disables(delta: float, feedback_delta: float = -1.0) -> void:
	if facility_disabled_timers.is_empty():
		facility_feedback_redraw_accumulator = 0.0
		return
	var should_redraw := false
	for room_id_value in facility_disabled_timers.keys():
		var room_id := str(room_id_value)
		var remaining := _facility_room_disabled_remaining(room_id) - maxf(0.0, delta) * _bebe_facility_recovery_rate(room_id)
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


func _bebe_facility_recovery_rate(room_id: String) -> float:
	if graph == null or not rooms.has(room_id):
		return 1.0
	for unit in monster_units:
		if not is_instance_valid(unit) or not unit.is_alive() or str(unit.unit_id) != "ghost_housemaid":
			continue
		if str(unit.current_room) == room_id or graph.exits(room_id).has(str(unit.current_room)):
			return 1.0 / 0.88
	return 1.0

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

