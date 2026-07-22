extends RefCounted
class_name CombatSceneController

const V20InformationHUDScene = preload("res://scenes/v20/ui/V20InformationHUD.tscn")
const V20MonsterRoleService = preload("res://scripts/v20/monsters/V20MonsterRoleService.gd")
const V20CommandService = preload("res://scripts/v20/commands/V20CommandService.gd")
const V20FacilityService = preload("res://scripts/v20/facilities/V20FacilityService.gd")
const V20EncounterService = preload("res://scripts/v20/encounters/V20EncounterService.gd")
const V20EconomyService = preload("res://scripts/v20/economy/V20EconomyService.gd")

const Constants = preload("res://scripts/core/Constants.gd")
const TargetingService = preload("res://scripts/combat/TargetingService.gd")
const DamageService = preload("res://scripts/combat/DamageService.gd")
const DirectiveManager = preload("res://scripts/combat/DirectiveManager.gd")
const UnitActorScript = preload("res://scripts/units/Unit.gd")
const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const UI_FONT = UIFontScript.BODY_FONT
const SFX_SLASH = preload("res://assets/audio/sfx/combat_slash.wav")
const SFX_SHIELD_BASH = preload("res://assets/audio/sfx/combat_shield_bash.wav")
const SFX_FIRE_BURST = preload("res://assets/audio/sfx/combat_fire_burst.wav")
const SFX_HIT = preload("res://assets/audio/sfx/combat_hit.wav")
const SFX_DOWN = preload("res://assets/audio/sfx/combat_down.wav")
const SKILL_SFX := {
	"slime_shield": preload("res://assets/audio/sfx/skills/slime_shield.wav"),
	"hold_corridor": preload("res://assets/audio/sfx/skills/hold_corridor.wav"),
	"quick_slash": preload("res://assets/audio/sfx/skills/quick_slash.wav"),
	"loot_instinct": preload("res://assets/audio/sfx/skills/loot_instinct.wav"),
	"fireball": preload("res://assets/audio/sfx/skills/fireball.wav"),
	"flame_zone": preload("res://assets/audio/sfx/skills/flame_zone.wav"),
	"false_footprints": preload("res://assets/audio/sfx/skills/false_footprints.wav"),
	"rumor_boost": preload("res://assets/audio/sfx/skills/rumor_boost.wav"),
	"spore_mend": preload("res://assets/audio/sfx/skills/spore_mend.wav"),
	"cleansing_bloom": preload("res://assets/audio/sfx/skills/cleansing_bloom.wav"),
	"rooted_guard": preload("res://assets/audio/sfx/skills/rooted_guard.wav"),
	"stone_pulse": preload("res://assets/audio/sfx/skills/stone_pulse.wav"),
	"war_rhythm": preload("res://assets/audio/sfx/skills/war_rhythm.wav"),
	"steady_beat": preload("res://assets/audio/sfx/skills/steady_beat.wav"),
	"moon_mark": preload("res://assets/audio/sfx/skills/moon_mark.wav"),
	"scent_pursuit": preload("res://assets/audio/sfx/skills/scent_pursuit.wav"),
	"false_treasure": preload("res://assets/audio/sfx/skills/false_treasure.wav"),
	"vault_swap": preload("res://assets/audio/sfx/skills/vault_swap.wav"),
	"spectral_transfer": preload("res://assets/audio/sfx/skills/spectral_transfer.wav"),
	"haunted_broom_whirl": preload("res://assets/audio/sfx/skills/haunted_broom_whirl.wav"),
	"scent_lock": preload("res://assets/audio/sfx/skills/scent_lock.wav"),
	"home_guard_bark": preload("res://assets/audio/sfx/skills/home_guard_bark.wav"),
	"carapace_ram": preload("res://assets/audio/sfx/skills/carapace_ram.wav"),
	"patch_plates": preload("res://assets/audio/sfx/skills/patch_plates.wav")
}

const SEAL_CHAIN_HINT := "대응: 곱·코코 선제 공격 / 푸딩 도발 / 베베 빗자루 중단 / 모리 정화"
const COUNTER_ENEMY_TYPE_LIMIT := 2
const HOLY_COUNTER_COMBO_THREAT_CAP := 3.80
const UPDATE3_COUNTER_ENEMY_IDS := ["seal_chainbearer", "reliquary_guard", "choir_exorcist", "bounty_tracker", "combat_alchemist", "ledger_binder"]
const ROMAN_GUILD_SUPPORT_IDS := ["bounty_tracker", "combat_alchemist", "ledger_binder", "engineer", "thief", "investigator"]
const COUNTER_COMBO_THREAT_BONUSES := {
	"choir_exorcist|seal_chainbearer": 0.35,
	"choir_exorcist|reliquary_guard": 0.45
}

const BARRACKS_ATTACK_MULTIPLIER = 1.25
const BARRACKS_DAMAGE_TAKEN_MULTIPLIER = 0.78
const WATCH_POST_DAMAGE_MULTIPLIER = 1.18
const WATCH_POST_SLOW_SECONDS = 0.45
const WATCH_POST_SLOW_FACTOR = 0.72
const ENGINEER_DISABLE_SECONDS = 10.0
const HUD_REFRESH_INTERVAL_SECONDS = 0.1
const V20_CHECKPOINT_BREACH_SECONDS := 1.25
const ROYAL_RALLY_DAYS = [21, 26, 30]
const HERO_SKILL_DAYS = [25, 30]
const HERO_UNIT_IDS = ["trainee_hero", "official_hero_leon"]
const ROYAL_RALLY_MOVE_MULTIPLIER = 1.18
const ROYAL_RALLY_ATTACK_INTERVAL_MULTIPLIER = 0.85
const ROYAL_RALLY_PULSE_SECONDS = 8.0
const BRAVE_SHOUT_DURATION = 5.0
const BRAVE_SHOUT_COOLDOWN = 10.0
const BRAVE_SHOUT_RADIUS = 360.0
const BRAVE_SHOUT_MOVE_MULTIPLIER = 1.12
const BRAVE_SHOUT_ATTACK_INTERVAL_MULTIPLIER = 0.82
const HERO_DASH_DISTANCE = 120.0
const HERO_DASH_DURATION = 0.32
const HERO_DASH_IMPACT_RADIUS = 72.0
const HERO_DASH_DAMAGE = 20
const FINAL_OATH_HP_RATIO = 0.60
const FINAL_OATH_HEAL_RATIO = 0.15
const FINAL_OATH_SHIELD_SECONDS = 6.0
const FINAL_OATH_DAMAGE_REDUCTION = 0.30
const ROMAN_SUPPLY_RADIUS = 280.0
const ROMAN_SUPPLY_COOLDOWN = 8.0
const ROMAN_SUPPLY_HEAL_RATIO = 0.16
const ROMAN_SUPPLY_SHIELD_SECONDS = 5.0
const ROMAN_SUPPLY_DAMAGE_REDUCTION = 0.25
const ALL_OUT_ATTACK_MULTIPLIER = 1.15
const ALL_OUT_DAMAGE_TAKEN_MULTIPLIER = 1.15
const DEFENSE_DAMAGE_TAKEN_MULTIPLIER = 0.50
const SURVIVAL_ATTACK_MULTIPLIER = 0.90
const SURVIVAL_DAMAGE_TAKEN_MULTIPLIER = 0.45
const UNOPPOSED_THRONE_DAMAGE_MULTIPLIER = 3.0
const MELEE_CONTACT_DELAY = 0.18
const PROJECTILE_TRAVEL_SECONDS = 0.12
const AUTO_SKILL_DECISION_INTERVAL = 0.35
const AUTO_SKILL_DEFENSIVE = ["slime_shield", "hold_corridor", "spore_mend", "cleansing_bloom", "rooted_guard", "war_rhythm", "steady_beat", "vault_swap"]
const AUTO_SKILL_CONTROL = ["flame_zone", "false_footprints", "stone_pulse", "false_treasure", "haunted_broom_whirl"]
const AUTO_SKILL_OFFENSIVE = ["quick_slash", "fireball", "moon_mark", "scent_pursuit"]
const AUTO_SKILL_REWARD = ["loot_instinct", "rumor_boost"]
const SPECIALIZED_AUTO_SKILLS = ["spectral_transfer", "scent_lock", "home_guard_bark", "carapace_ram", "patch_plates"]
const DAMAGE_NUMBER_LANE_WINDOW_MSEC = 700
const COMBAT_OVERLAY_REDRAW_INTERVAL_SECONDS := 0.1
const DAMAGE_NUMBER_LANE_OFFSETS = [
	Vector2(0, 0),
	Vector2(-26, -12),
	Vector2(26, -20),
	Vector2(-42, -30),
	Vector2(42, -38)
]

var root: Node
var hud
var v20_hud
var v20_role_result_state: Dictionary = {}
var v20_command_state: Dictionary = {}
var v20_facility_state: Dictionary = {}
var v20_command_ui_second := -1
var v20_encounter_definition: Dictionary = {}
var v20_encounter_state: Dictionary = {}
var v20_difficulty_profile: Dictionary = {}
var pending_v20_command_id := ""
var recovery_heal_accumulator: Dictionary = {}
var camera_kick_cooldown := 0.0
var sfx_cooldowns: Dictionary = {}
var damage_number_lanes: Dictionary = {}
var royal_rally_pulse_timer := 0.0
var royal_rally_active_seconds := 0.0
var royal_rally_activations := 0
var royal_rally_was_active := false
var royal_rally_stopped := false
var brave_shout_remaining := 0.0
var brave_shout_active_seconds := 0.0
var brave_shout_activations := 0
var brave_shout_recipient_total := 0
var brave_shout_buffed_ids: Dictionary = {}
var brave_shout_was_active := false
var hero_dash_states: Dictionary = {}
var hero_dash_activations := 0
var hero_dash_damage := 0
var final_oath_activated_ids: Dictionary = {}
var final_oath_activations := 0
var final_oath_healing := 0
var roman_supply_activations := 0
var roman_supply_healing := 0
var roman_supply_shields := 0
var update2_counter_cooldowns: Dictionary = {}
var update2_counter_activations: Dictionary = {}
var update2_counter_targets := 0
var update2_counter_healing := 0
var leon_stance_id := ""
var leon_purification_cooldown := 0.0
var leon_stance_activations := 0
var leon_counter_damage := 0
var leon_heart_response_used := false
var leon_duo_response_used := false
var leon_heart_response_count := 0
var leon_duo_response_count := 0
var hud_refresh_accumulator := 0.0
var seal_chain_telegraphs_started := 0
var seal_chain_activations := 0
var seal_chain_interruptions := 0
var seal_chain_hint_shown := false
var bounty_evaluations := 0
var bounty_marks_applied := 0
var acid_telegraphs: Array[Dictionary] = []
var acid_zones: Array[Dictionary] = []
var acid_damage_accumulator := 0.0
var acid_throws_started := 0
var acid_zones_created := 0
var relic_aura_refreshes := 0
var relic_aura_peak_protected := 0
var purifying_hymn_casts: Array[Dictionary] = []
var purifying_hymn_started := 0
var purifying_hymn_completed := 0
var purifying_hymn_interrupted := 0
var purifying_hymn_cleansed := 0
var ledger_mark_casts: Array[Dictionary] = []
var ledger_room_marks: Dictionary = {}
var ledger_casts_started := 0
var ledger_marks_applied := 0
var ledger_debt_recorded := 0
var ledger_overloads := 0
var ledger_marks_cleansed := 0
var ledger_marks_cleared_on_source_down := 0
var official_selen_states: Dictionary = {}
var selen_consecrated_floors: Array[Dictionary] = []
var selen_first_inspection_delay_bonus := 0.0
var selen_mercy_barrier_bonus := 0
var selen_inspections_started := 0
var selen_inspections_cancelled := 0
var selen_inspections_completed := 0
var selen_barrier_breaks_in_window := 0
var commissioner_roman_states: Dictionary = {}
var roman_start_budget_delta := 0
var roman_mercenary_call_max := 2
var roman_asset_freezes_cancelled := 0
var roman_mercenaries_summoned := 0
var roman_fast_mercenary_kills := 0
var roman_final_phase_entry_budget := -1
var active_flame_zones: Array = []
var combat_overlay_redraw_accumulator := 0.0
var combat_overlay_was_dynamic := false

func setup(game_root: Node, hud_controller) -> void:
	root = game_root
	hud = hud_controller

func physics_process(delta: float) -> void:
	_update_sfx_cooldowns(delta)
	if root.current_screen != Constants.SCREEN_COMBAT:
		return
	_sync_unit_simulation_speed()
	hud_refresh_accumulator += delta
	if hud_refresh_accumulator >= HUD_REFRESH_INTERVAL_SECONDS:
		hud_refresh_accumulator = fmod(hud_refresh_accumulator, HUD_REFRESH_INTERVAL_SECONDS)
		hud.update_facility_effect_panel()
		hud.update_combat_status()
	if root.combat_paused:
		return
	var sim_delta = delta * root.combat_speed
	if _v20_roles_active():
		v20_command_state = V20CommandService.advance(v20_command_state, sim_delta)
		v20_facility_state = V20FacilityService.advance(v20_facility_state, sim_delta)
		v20_encounter_state = V20EncounterService.advance(v20_encounter_state, sim_delta, v20_encounter_definition)
		_sync_v20_command_runtime()
		_refresh_v20_command_hud_if_needed()
	camera_kick_cooldown = max(0.0, camera_kick_cooldown - delta)
	root.combat_time += sim_delta
	if root.has_method("_update_campaign_combat_timed_lines"):
		root._update_campaign_combat_timed_lines()
	if root.has_method("_update_facility_disables"):
		root._update_facility_disables(sim_delta, delta)
	if root.has_method("_tick_update3_heart"):
		root._tick_update3_heart(sim_delta)
	root.trap_cooldown = max(0.0, root.trap_cooldown - sim_delta)
	spawn_ready_enemies(sim_delta)
	_update_royal_rally(sim_delta)
	_update_brave_shout(sim_delta)
	_update_update2_counterforce(sim_delta)
	_update_seal_chainbearers(sim_delta)
	_update_bounty_trackers(sim_delta)
	_update_combat_alchemists(sim_delta)
	_update_reliquary_auras(sim_delta)
	_update_choir_exorcists(sim_delta)
	_update_ledger_binders(sim_delta)
	_update_leon_adaptation(sim_delta)
	_update_official_paladin_selen(sim_delta)
	_update_guild_commissioner_roman(sim_delta)
	_update_combat_overlay_redraw(delta)
	_update_hero_dashes(sim_delta)
	refresh_unit_rooms()
	_refresh_heart_target_limit()
	if root.has_method("_update3_refresh_monster_heart_position"):
		for monster in root.monster_units:
			root._update3_refresh_monster_heart_position(monster)
	if root.has_method("_update3_refresh_enemy_heart_control"):
		for enemy in root.enemy_units:
			root._update3_refresh_enemy_heart_control(enemy)
	_advance_v20_checkpoint_waits(sim_delta)
	update_ai_paths()
	update_room_effects(sim_delta)
	_update_active_flame_zones(sim_delta)
	update_attacks(sim_delta)
	check_combat_end()

func build_combat_ui() -> void:
	if root.has_method("_v20_vertical_slice_active") and root._v20_vertical_slice_active():
		_build_v20_combat_ui()
		return
	hud.build_top_bar()
	hud.build_facility_effect_panel()
	if UISettings.is_touch_ui():
		hud.build_mobile_combat_bar()
		return
	hud.build_room_list(20, 105, 300, 385)
	hud.build_unit_status_panel()
	hud.build_log_panel()
	hud.build_selected_unit_panel()
	hud.build_command_panel()
	hud.build_speed_panel()


func _build_v20_combat_ui() -> void:
	v20_hud = V20InformationHUDScene.instantiate()
	root.ui_layer.add_child(v20_hud)
	var selected_context := {
		"eyebrow": "전장 선택",
		"title": "지도에서 대상을 선택",
		"subtitle": "방·유닛·시설 상세",
		"summary": "상세 능력치와 전투 기록은 전장을 가리지 않는 컨텍스트 드로어에서 확인합니다."
	}
	if root.selected_unit != null and is_instance_valid(root.selected_unit):
		selected_context = {
			"eyebrow": "선택 유닛",
			"title": root.selected_unit.display_name,
			"subtitle": root.selected_unit.role,
			"facts": [
				{"label": "체력", "value": "%d / %d" % [root.selected_unit.hp, root.selected_unit.max_hp]},
				{"label": "현재 방", "value": str(root.rooms.get(root.selected_unit.current_room, {}).get("display_name", root.selected_unit.current_room))},
				{"label": "상태", "value": root.selected_unit.state_label()}
			],
			"summary": root.selected_unit.status_line()
		}
	var state := {
		"day": GameState.day,
		"encounter_title": str(v20_encounter_definition.get("display_name", "침입대 방어")),
		"objective_label": "왕좌 방어",
		"objective_hp": GameState.demon_lord_hp,
		"objective_hp_max": GameState.demon_lord_max_hp,
		"phase_label": "현재 단계 · %d / %d 출현" % [root.spawned_count, root.wave_manager.schedule.size()],
		"pattern_title": "정찰 정보 갱신 중",
		"pattern_eta": "—",
		"pattern_response": "특수 패턴은 예고와 대응을 함께 표시합니다.",
		"drawer_open": root.selected_unit != null and is_instance_valid(root.selected_unit),
		"selected_target_label": str(root.selected_unit.display_name) if root.selected_unit != null and is_instance_valid(root.selected_unit) else "전장에서 선택",
		"context": selected_context,
		"commands": V20CommandService.command_rows(v20_command_state, DataRegistry.v20_commands),
		"command_points": int(v20_command_state.get("points", 0)),
		"command_max": int(v20_command_state.get("max_points", 3))
	}
	var encounter_status := V20EncounterService.hud_status(v20_encounter_state, v20_encounter_definition)
	for key_value in encounter_status.keys():
		state[str(key_value)] = encounter_status.get(key_value)
	var defense_status := v20_defense_stage_hud_state()
	for key_value in defense_status.keys():
		state[str(key_value)] = defense_status.get(key_value)
	v20_hud.setup("combat", state)
	v20_hud.action_requested.connect(_on_v20_combat_action)
	if pending_v20_command_id != "":
		var pending_definition: Dictionary = DataRegistry.v20_commands.get(pending_v20_command_id, {})
		v20_hud.set_targeting_state(pending_v20_command_id, str(pending_definition.get("display_name", pending_v20_command_id)), str(pending_definition.get("target_type", "")))


func _on_v20_combat_action(action_id: String) -> void:
	match action_id:
		"speed:1":
			root._set_speed(1.0)
		"speed:2":
			root._set_speed(2.0)
		"speed:3":
			root._set_speed(3.0)
		"pause":
			root._toggle_pause()
		"close_context":
			if v20_hud != null:
				v20_hud.set_context_drawer(false)
		_:
			if action_id.begins_with("command:"):
				_begin_v20_command_targeting(action_id.trim_prefix("command:"))


func _begin_v20_command_targeting(command_id: String) -> void:
	if not _v20_roles_active():
		return
	var definition: Dictionary = DataRegistry.v20_commands.get(command_id, {})
	if definition.is_empty():
		return
	var cooldown := float(v20_command_state.get("cooldowns", {}).get(command_id, 0.0))
	var cost := int(definition.get("command_point_cost", 1))
	if cooldown > 0.0:
		_show_v20_command_feedback("%s · %.1f초 뒤 사용 가능" % [str(definition.get("display_name", command_id)), cooldown], false)
		return
	if int(v20_command_state.get("points", 0)) < cost:
		_show_v20_command_feedback("명령력이 부족합니다", false)
		return
	pending_v20_command_id = command_id
	if v20_hud != null and is_instance_valid(v20_hud):
		v20_hud.set_targeting_state(command_id, str(definition.get("display_name", command_id)), str(definition.get("target_type", "")))


func handle_v20_world_click(world_point: Vector2) -> bool:
	if pending_v20_command_id == "" or not _v20_roles_active():
		return false
	var command_id := pending_v20_command_id
	var definition: Dictionary = DataRegistry.v20_commands.get(command_id, {})
	var target_type := str(definition.get("target_type", ""))
	var target: Dictionary = {}
	match target_type:
		"enemy":
			var unit = root._unit_at(world_point)
			if unit != null and root.enemy_units.has(unit) and unit.is_alive():
				target = {"type": "enemy", "id": str(unit.get_instance_id()), "room_id": str(unit.current_room), "label": str(unit.display_name)}
				if root.selected_unit != null and is_instance_valid(root.selected_unit):
					root.selected_unit.set_selected(false)
				root.selected_unit = unit
				unit.set_selected(true)
		"room":
			var room_id := str(root._room_at(world_point))
			if room_id != "":
				target = {"type": "room", "id": room_id, "label": _room_name(room_id)}
		"facility":
			var runtime_room_id := str(root._room_at(world_point))
			target = _v20_facility_target_for_runtime_room(runtime_room_id)
	if target.is_empty():
		_show_v20_command_feedback(_v20_target_prompt_error(target_type), false)
		return true
	pending_v20_command_id = ""
	if v20_hud != null and is_instance_valid(v20_hud):
		v20_hud.clear_targeting_state()
	_issue_v20_command_with_target(command_id, target)
	return true


func cancel_v20_targeting() -> bool:
	if pending_v20_command_id == "":
		return false
	pending_v20_command_id = ""
	if v20_hud != null and is_instance_valid(v20_hud):
		v20_hud.clear_targeting_state()
		v20_hud.show_feedback("명령 선택을 취소했습니다", true)
	return true


func _v20_facility_target_for_runtime_room(runtime_room_id: String) -> Dictionary:
	if runtime_room_id == "":
		return {}
	for facility_id_value in v20_facility_state.get("facilities", {}).keys():
		var facility_id := str(facility_id_value)
		var facility: Dictionary = v20_facility_state.get("facilities", {}).get(facility_id, {})
		var node_id := str(facility.get("room_id", facility_id))
		if _v20_runtime_room(node_id) != runtime_room_id:
			continue
		return {
			"type": "facility",
			"id": facility_id,
			"room_id": node_id,
			"label": str(DataRegistry.v20_facilities.get(str(facility.get("facility_id", "")), {}).get("display_name", _room_name(runtime_room_id)))
		}
	return {}


func _v20_target_prompt_error(target_type: String) -> String:
	match target_type:
		"enemy":
			return "살아 있는 적을 클릭하세요"
		"room":
			return "전장의 방을 클릭하세요"
		"facility":
			return "설치된 시설이 있는 방을 클릭하세요"
	return "유효한 대상을 클릭하세요"


func _show_v20_command_feedback(message: String, success: bool) -> void:
	if v20_hud != null and is_instance_valid(v20_hud):
		v20_hud.show_feedback(message, success)

func start_combat() -> void:
	root._clear_units()
	clear_effects()
	clear_quarter_trap_animations()
	root._reset_combat_view()
	root.combat_time = 0.0
	root.combat_paused = false
	root.combat_speed = 1.0
	v20_role_result_state = _new_v20_role_result_state()
	v20_difficulty_profile = V20EconomyService.profile(DataRegistry.v20_economy, str(root.get_meta("v20_difficulty_id", V20EconomyService.DEFAULT_PROFILE_ID))) if _v20_roles_active() else {}
	var command_settings := V20EconomyService.command_settings(v20_difficulty_profile) if not v20_difficulty_profile.is_empty() else {"max_points": 3, "initial_points": 3, "recharge_seconds": 12.0}
	v20_command_state = V20CommandService.new_state(DataRegistry.v20_commands, int(command_settings.get("max_points", 3)), int(command_settings.get("initial_points", 3)), float(command_settings.get("recharge_seconds", 12.0)))
	v20_facility_state = _new_v20_facility_state()
	v20_encounter_definition = V20EncounterService.encounter_for_day(GameState.day, DataRegistry.v20_encounters) if _v20_roles_active() else {}
	if not v20_encounter_definition.is_empty():
		v20_encounter_definition = V20EconomyService.configured_encounter(v20_encounter_definition, v20_difficulty_profile)
	v20_encounter_state = V20EncounterService.new_state(v20_encounter_definition, _v20_board(), _v20_encounter_context()) if not v20_encounter_definition.is_empty() else {}
	v20_command_ui_second = -1
	active_flame_zones.clear()
	combat_overlay_redraw_accumulator = 0.0
	combat_overlay_was_dynamic = false
	hud_refresh_accumulator = 0.0
	root.trap_cooldown = 0.0
	camera_kick_cooldown = 0.0
	sfx_cooldowns.clear()
	root.spawned_count = 0
	root.thief_steal_timers.clear()
	root.treasure_gold_stolen_this_battle = 0
	root.thieves_spawned_this_battle = 0
	root.thieves_reached_treasure_this_battle = 0
	root.thieves_completed_theft_this_battle = 0
	root.thieves_escaped_this_battle = 0
	royal_rally_pulse_timer = 0.0
	royal_rally_active_seconds = 0.0
	royal_rally_activations = 0
	royal_rally_was_active = false
	royal_rally_stopped = false
	brave_shout_remaining = 0.0
	brave_shout_active_seconds = 0.0
	brave_shout_activations = 0
	brave_shout_recipient_total = 0
	brave_shout_buffed_ids.clear()
	brave_shout_was_active = false
	hero_dash_states.clear()
	hero_dash_activations = 0
	hero_dash_damage = 0
	final_oath_activated_ids.clear()
	final_oath_activations = 0
	final_oath_healing = 0
	roman_supply_activations = 0
	roman_supply_healing = 0
	roman_supply_shields = 0
	update2_counter_cooldowns.clear()
	update2_counter_activations.clear()
	update2_counter_targets = 0
	update2_counter_healing = 0
	leon_stance_id = ""
	leon_purification_cooldown = 0.0
	leon_stance_activations = 0
	leon_counter_damage = 0
	leon_heart_response_used = false
	leon_duo_response_used = false
	leon_heart_response_count = 0
	leon_duo_response_count = 0
	seal_chain_telegraphs_started = 0
	seal_chain_activations = 0
	seal_chain_interruptions = 0
	seal_chain_hint_shown = false
	bounty_evaluations = 0
	bounty_marks_applied = 0
	acid_throws_started = 0
	acid_zones_created = 0
	relic_aura_refreshes = 0
	relic_aura_peak_protected = 0
	purifying_hymn_casts.clear()
	purifying_hymn_started = 0
	purifying_hymn_completed = 0
	purifying_hymn_interrupted = 0
	purifying_hymn_cleansed = 0
	ledger_mark_casts.clear()
	ledger_room_marks.clear()
	ledger_casts_started = 0
	ledger_marks_applied = 0
	ledger_debt_recorded = 0
	ledger_overloads = 0
	ledger_marks_cleansed = 0
	ledger_marks_cleared_on_source_down = 0
	official_selen_states.clear()
	selen_consecrated_floors.clear()
	selen_first_inspection_delay_bonus = 0.0
	selen_mercy_barrier_bonus = 0
	selen_inspections_started = 0
	selen_inspections_cancelled = 0
	selen_inspections_completed = 0
	selen_barrier_breaks_in_window = 0
	commissioner_roman_states.clear()
	roman_start_budget_delta = 0
	roman_mercenary_call_max = int(DataRegistry.skill("mercenary_invoice").get("max_calls", 2))
	roman_asset_freezes_cancelled = 0
	roman_mercenaries_summoned = 0
	roman_fast_mercenary_kills = 0
	roman_final_phase_entry_budget = -1
	if root.has_method("_reset_engineer_combat_state"):
		root._reset_engineer_combat_state()
	if root.has_method("_reset_campaign_combat_timed_lines"):
		root._reset_campaign_combat_timed_lines()
	recovery_heal_accumulator.clear()
	if root.has_method("_reset_facility_effect_stats"):
		root._reset_facility_effect_stats()
	if root.has_method("_reset_directive_effect_stats"):
		root._reset_directive_effect_stats()
	if root.has_method("_prepare_update3_heart_battle"):
		root._prepare_update3_heart_battle()
	root.rewards_pending = {"gold": 0, "mana": 0, "food": 0, "infamy": 0}
	root.result_summary = {"win": false, "lines": []}
	if root.has_method("_prepare_update2_leon_combat"):
		var leon_stance: Dictionary = root._prepare_update2_leon_combat()
		leon_stance_id = str(leon_stance.get("id", root.leon_adaptation.get("stance_id", ""))) if not leon_stance.is_empty() else ""
	if root.has_method("_capture_battle_growth_start"):
		root._capture_battle_growth_start()
	var defense_modifiers: Dictionary = {}
	if root.has_method("_active_defense_modifiers"):
		defense_modifiers = root._active_defense_modifiers()
	for modifier_value in defense_modifiers.values():
		var phase20_modifier: Dictionary = modifier_value
		selen_first_inspection_delay_bonus += float(phase20_modifier.get("selen_first_inspection_delay", 0.0))
		selen_mercy_barrier_bonus += int(phase20_modifier.get("selen_mercy_barrier_bonus", 0))
		roman_start_budget_delta += int(phase20_modifier.get("roman_start_budget_delta", 0))
		roman_mercenary_call_max = mini(roman_mercenary_call_max, int(phase20_modifier.get("roman_mercenary_call_max", roman_mercenary_call_max)))
	if root.has_method("_update2_seeded_wave_variant"):
		var seeded_variant: Dictionary = root._update2_seeded_wave_variant(GameState.day)
		if not seeded_variant.is_empty():
			seeded_variant["source_label"] = "회차 웨이브 변형"
			seeded_variant["display_name"] = str(seeded_variant.get("title", seeded_variant.get("id", "왕국 대응 편성")))
			seeded_variant["combat_start_line"] = "회차 seed에 고정된 왕국 대응 부대가 합류합니다."
			defense_modifiers["update2_seeded_variant"] = seeded_variant
	var wave_catalog: Dictionary = root._active_wave_catalog(GameState.day) if root.has_method("_active_wave_catalog") else DataRegistry.waves
	var applied_defense_modifiers := defense_modifiers
	if _v20_roles_active() and GameState.day in [1, 2, 3, 4, 5]:
		var v20_wave_catalog := V20EncounterService.wave_catalog_for_encounter(v20_encounter_definition, _v20_board(), _v20_encounter_context())
		if not v20_wave_catalog.is_empty():
			wave_catalog = v20_wave_catalog
			applied_defense_modifiers = {}
	root.wave_manager.setup(GameState.day, wave_catalog, applied_defense_modifiers)
	_warm_scheduled_enemy_animations()
	if not applied_defense_modifiers.is_empty():
		for modifier in applied_defense_modifiers.values():
			var source_label := str(modifier.get("source_label", "원정 효과 적용"))
			root._log("%s: %s" % [source_label, str(modifier.get("display_name", "다음 방어 변화"))])
			var combat_start_line := str(modifier.get("combat_start_line", ""))
			if combat_start_line != "":
				root._log(combat_start_line)
		if root.has_method("_consume_defense_modifiers"):
			root._consume_defense_modifiers()
	spawn_monsters()
	if root.has_method("_prepare_update4_multifloor_battle"):
		root._prepare_update4_multifloor_battle()
	if root.has_method("_prepare_update3_duo_link_battle"):
		root._prepare_update3_duo_link_battle()
	for unit in root.monster_units:
		unit.set_physics_process(true)
	root._log("DAY %d 침입이 시작되었습니다." % GameState.day)
	root._set_screen(Constants.SCREEN_COMBAT)

func _warm_scheduled_enemy_animations() -> void:
	var warmed_paths: Dictionary = {}
	for entry_value in root.wave_manager.schedule:
		if not (entry_value is Dictionary):
			continue
		var enemy_id := str(entry_value.get("enemy_id", ""))
		var sprite_path := str(DataRegistry.enemy(enemy_id).get("sprite", ""))
		if sprite_path == "" or warmed_paths.has(sprite_path):
			continue
		warmed_paths[sprite_path] = true
		UnitActorScript.warm_animation_frames(sprite_path)

func spawn_monsters() -> void:
	var spawn_counts: Dictionary = {}
	for monster_id in root.monster_roster.keys():
		if root.has_method("_monster_available_for_defense") and not root._monster_available_for_defense(str(monster_id)):
			continue
		if root.has_method("_monster_deployed_for_defense") and not root._monster_deployed_for_defense(str(monster_id)):
			continue
		var roster: Dictionary = root.monster_roster[monster_id]
		var room_id: String = roster.get("room", DataRegistry.monster(monster_id).get("recommended_room", "entrance"))
		var stats = root._scaled_monster_stats(monster_id)
		var unit = root._create_unit(monster_id, stats, Constants.FACTION_MONSTER, room_id)
		var count = int(spawn_counts.get(room_id, 0))
		unit.global_position = root._clamp_to_combat_walkable(root._room_actor_point(room_id, count, true))
		spawn_counts[room_id] = count + 1
		root.monster_units.append(unit)
		if root.has_method("_growth_preparation_active") and root._growth_preparation_active(str(monster_id)):
			var preparation_name = root._growth_preparation_combat_name(str(monster_id)) if root.has_method("_growth_preparation_combat_name") else "집중 준비"
			var preparation_preview = root._result_growth_preparation_preview(str(monster_id)) if root.has_method("_result_growth_preparation_preview") else ""
			unit.activate_growth_preparation(preparation_name, preparation_preview)
			spawn_growth_preparation_feedback(unit.global_position, preparation_name)
			root._log("%s의 %s 발동: %s." % [unit.display_name, preparation_name, preparation_preview])
		if root.selected_unit == null:
			root._select_unit(unit)

func spawn_ready_enemies(delta: float) -> void:
	for entry in root.wave_manager.tick(delta):
		spawn_enemy(entry.get("enemy_id", "explorer"), entry)

func spawn_enemy(enemy_id: String, wave_entry: Dictionary = {}) -> void:
	if UPDATE3_COUNTER_ENEMY_IDS.has(enemy_id) and not bool(wave_entry.get("ignore_counter_cap", false)):
		var composition_ids: Array[String] = []
		for existing in root.enemy_units:
			if is_instance_valid(existing) and existing.is_alive() and UPDATE3_COUNTER_ENEMY_IDS.has(str(existing.unit_id)):
				composition_ids.append(str(existing.unit_id))
		composition_ids.append(enemy_id)
		var composition := evaluate_update3_counter_combo(composition_ids)
		if not bool(composition.get("allowed", false)):
			root._log("카운터 조합 상한으로 %s 증원을 보류했습니다: %s" % [enemy_id, str(composition.get("reason", "위협도 초과"))])
			return
	var stats = _scaled_enemy_stats(enemy_id, wave_entry)
	var unit = root._create_unit(enemy_id, stats, Constants.FACTION_ENEMY, "entrance")
	if wave_entry.has("v20_phase_id"):
		unit.set_meta("v20_phase_id", str(wave_entry.get("v20_phase_id", "")))
		unit.set_meta("v20_route_policy", str(wave_entry.get("v20_route_policy", "")))
		unit.set_meta("v20_response_tags", wave_entry.get("v20_response_tags", []).duplicate())
		unit.set_meta("v20_special_action", wave_entry.get("v20_special_action", {}).duplicate(true))
	if enemy_id == "official_hero_leon" and leon_stance_id != "":
		unit.set_meta("leon_stance_id", leon_stance_id)
	if ROYAL_RALLY_DAYS.has(GameState.day) and enemy_id == "selen_trainee_paladin":
		unit.role = "commander"
	unit.global_position = root._clamp_to_combat_walkable(root._room_actor_point("entrance", root.spawned_count + 3, true))
	if stats.get("goal_type", "") == "facility" and enemy_id != "combat_alchemist":
		root.engineers_spawned_this_battle += 1
		_assign_engineer_target(unit)
	elif stats.get("goal_type", "") == "facility":
		var facility_goal := _nearest_active_facility_room("entrance", 0, true)
		unit.goal_room = facility_goal if facility_goal != "" else _core_room()
		unit.set_path(_path_from_world_to_room(unit.global_position, unit.goal_room))
	elif stats.get("goal_type", "") == "heart":
		unit.set_meta("prefers_heart_goal", true)
		var heart_goal: String = str(root._update3_enemy_goal(_core_room(), true)) if root.has_method("_update3_enemy_goal") else _core_room()
		unit.goal_room = heart_goal if heart_goal == "heart_chamber" and active_heart_target_count() == 0 else _core_room()
		unit.set_path(_path_from_world_to_room(unit.global_position, unit.goal_room))
	else:
		var treasure_room = _treasure_room()
		unit.goal_room = treasure_room if stats.get("goal_type", "") == "treasure" and treasure_room != "" else _core_room()
		unit.set_path(_path_from_world_to_room(unit.global_position, unit.goal_room))
	var v20_route_nodes: Array = wave_entry.get("v20_route_nodes", [])
	if not v20_route_nodes.is_empty():
		unit.set_meta("v20_route_nodes", v20_route_nodes.duplicate())
	if not v20_route_nodes.is_empty() and str(stats.get("goal_type", "")) != "facility":
		_initialize_v20_defense_checkpoints(unit, v20_route_nodes)
	root.enemy_units.append(unit)
	root.spawned_count += 1
	if root.has_method("_refresh_combat_music_variant"):
		root._refresh_combat_music_variant()
	if root.has_method("_play_update3_enemy_warning"):
		root._play_update3_enemy_warning(enemy_id)
	if enemy_id == "thief":
		root.thieves_spawned_this_battle += 1
	if enemy_id == "seal_chainbearer" and not seal_chain_hint_shown:
		seal_chain_hint_shown = true
		root._log("봉인 사슬병은 0.9초 예고 후 이동과 스킬을 봉인합니다.")
		root._log(SEAL_CHAIN_HINT)
	var behavior_handler := str(stats.get("behavior_handler", ""))
	if behavior_handler == "official_paladin_selen":
		_initialize_official_paladin_selen(unit)
		root._log("정식 성기사 셀렌이 마지막 검수표를 펼칩니다. 검수 중 피해 55를 집중하면 절차를 중단할 수 있습니다.")
	elif behavior_handler == "guild_commissioner_roman":
		_initialize_guild_commissioner_roman(unit)
		root._log("길드 총감사관 로만이 생존 지원 인원을 세어 시작 예산을 확정합니다. 지원 적을 먼저 제거하세요.")
	if behavior_handler == "bounty_tracker":
		unit.bounty_evaluation_timer = float(DataRegistry.skill("bounty_target").get("first_evaluation_seconds", 5.0))
		root._log("현상금 추적자는 5초 뒤 최근 20초 기여 1위를 표적화합니다. 푸딩·코코 도발로 공격 대상을 바꿀 수 있습니다.")
	elif behavior_handler == "combat_alchemist":
		root._log("전투 연금술사는 0.8초 예고 뒤 방어력과 수리 효율을 낮추는 산성 장판을 던집니다.")
	elif behavior_handler == "choir_exorcist":
		root._log("성가 퇴마사는 심장실을 노리고 1.2초 정화 성가로 아군 약화를 지우며 심장 충전을 4초 막습니다.")
	elif behavior_handler == "ledger_binder":
		root._log("장부 구속술사는 1초 예고 뒤 방을 7초 표식합니다. 그 방에서 액티브 스킬 3회 사용 시 방이 3초 무력화됩니다.")
	if root.has_method("_onboarding_enemy_spawned"):
		root._onboarding_enemy_spawned(enemy_id)
	root._log("%s가 입구에 도착했습니다." % unit.display_name)


func _initialize_official_paladin_selen(selen: Node) -> void:
	var inspection: Dictionary = DataRegistry.skill("inspection_seal")
	official_selen_states[selen.get_instance_id()] = {
		"unit_id": selen.get_instance_id(),
		"phase": 1,
		"inspection_mode": "idle",
		"inspection_timer": 0.0,
		"inspection_cooldown": float(inspection.get("first_delay", 6.0)) + selen_first_inspection_delay_bonus,
		"inspection_target": "",
		"inspection_hp_start": int(selen.hp),
		"final_active": false,
		"final_attempt": 0,
		"final_cancelled": 0,
		"final_completed": 0,
		"final_wait": 0.0,
		"barrier_activated": false,
		"barrier_window": 0.0,
		"barrier_members": [],
		"vulnerable_timer": 0.0,
		"floor_cooldown": 0.0
	}
	selen.set_meta("boss_control_immunity", true)
	selen.set_tactical_state(Constants.UNIT_STATE_SEEK_TARGET, "마지막 검수 준비")


func official_selen_state(selen: Node) -> Dictionary:
	if selen == null or not is_instance_valid(selen):
		return {}
	return official_selen_states.get(selen.get_instance_id(), {}).duplicate(true)


func _update_official_paladin_selen(delta: float) -> void:
	_update_selen_consecrated_floors(delta)
	for state_key in official_selen_states.keys():
		var state: Dictionary = official_selen_states[state_key]
		var selen = instance_from_id(int(state.get("unit_id", 0)))
		if selen == null or not is_instance_valid(selen) or not selen.is_alive():
			official_selen_states.erase(state_key)
			continue
		# Final bosses cannot be fully stunned or forcibly moved. Slows remain valid.
		selen.action_interrupt_timer = 0.0
		selen.seal_move_lock_timer = 0.0
		selen.duo_move_lock_timer = 0.0
		var hp_ratio := float(selen.hp) / float(maxi(1, selen.max_hp))
		if hp_ratio <= float(DataRegistry.skill("consecrated_advance").get("trigger_hp_ratio", 0.65)) and int(state.get("phase", 1)) < 2:
			state["phase"] = 2
			selen.boss_move_multiplier = float(DataRegistry.skill("consecrated_advance").get("move_multiplier", 0.92))
			root._log("셀렌 2단계: 축성 진군이 시작됩니다. 빛나는 바닥 밖으로 몬스터를 이동시키세요.")
		if hp_ratio <= float(DataRegistry.skill("mercy_barrier").get("trigger_hp_ratio", 0.35)) and int(state.get("phase", 1)) < 3:
			state["phase"] = 3
			state["final_active"] = true
			state["inspection_mode"] = "idle"
			state["inspection_cooldown"] = 0.0
			root._log("셀렌 3단계: 마지막 검수표 3회가 시작됩니다.")
		if int(state.get("phase", 1)) >= 2:
			_update_selen_advance(selen, state, delta)
		if bool(state.get("final_active", false)):
			_update_selen_final_checklist(selen, state, delta)
		elif int(state.get("phase", 1)) < 3:
			_update_selen_inspection(selen, state, delta, false)
		_update_selen_barrier(selen, state, delta)
		official_selen_states[state_key] = state


func _selen_inspection_targets() -> Array[String]:
	var targets: Array[String] = []
	for room_id_value in root.rooms.keys():
		var room_id := str(room_id_value)
		var role := str(root.rooms[room_id].get("facility_role", ""))
		if role in ["", "entry", "trap", "corridor", "core", "build_slot", "heart_chamber"]:
			continue
		if root._facility_room_is_active(room_id):
			targets.append(room_id)
	if root.rooms.has("heart_chamber"):
		targets.append("heart_chamber")
	targets.sort()
	return targets


func _start_selen_inspection(selen: Node, state: Dictionary, final_attempt: bool) -> void:
	var targets := _selen_inspection_targets()
	if targets.is_empty():
		state["inspection_cooldown"] = 1.0
		return
	var offset := int(state.get("final_attempt", selen_inspections_started))
	state["inspection_target"] = targets[offset % targets.size()]
	state["inspection_mode"] = "telegraph"
	state["inspection_timer"] = float(DataRegistry.skill("inspection_seal").get("telegraph_seconds", 1.0))
	state["inspection_hp_start"] = int(selen.hp)
	state["inspection_is_final"] = final_attempt
	selen_inspections_started += 1
	selen.play_skill(root._room_actor_point(str(state["inspection_target"]), 0, true))
	_play_sfx(SFX_SHIELD_BASH, "selen_inspection", -10.0, 0.3, 1.12, 1.18)
	selen.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "검수 봉인 예고", root.display_name_for_instance(str(state["inspection_target"])))
	root._log("검수 예고: %s. 1초 뒤 검수가 시작됩니다." % root.display_name_for_instance(str(state["inspection_target"])))


func _update_selen_inspection(selen: Node, state: Dictionary, delta: float, final_attempt: bool) -> String:
	var skill: Dictionary = DataRegistry.skill("inspection_seal")
	var mode := str(state.get("inspection_mode", "idle"))
	if mode == "idle":
		state["inspection_cooldown"] = maxf(0.0, float(state.get("inspection_cooldown", 0.0)) - delta)
		if float(state["inspection_cooldown"]) <= 0.0:
			_start_selen_inspection(selen, state, final_attempt)
		return "running"
	state["inspection_timer"] = maxf(0.0, float(state.get("inspection_timer", 0.0)) - delta)
	if mode == "telegraph":
		if float(state["inspection_timer"]) <= 0.0:
			state["inspection_mode"] = "mark"
			state["inspection_timer"] = float(skill.get("mark_seconds", 5.0))
			state["inspection_hp_start"] = int(selen.hp)
			selen.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "검수 진행", root.display_name_for_instance(str(state["inspection_target"])))
		return "running"
	var damage_during_mark := int(state.get("inspection_hp_start", selen.hp)) - int(selen.hp)
	if damage_during_mark >= int(skill.get("cancel_damage", 55)):
		state["inspection_mode"] = "idle"
		state["inspection_cooldown"] = float(skill.get("cooldown", 10.0))
		selen.apply_armor_break(int(skill.get("stagger_def_penalty", 2)), float(skill.get("stagger_seconds", 2.0)), "procedure_stagger")
		selen_inspections_cancelled += 1
		root._log("검수 취소 성공: 셀렌의 절차가 흔들려 방어력 -2가 2초간 적용됩니다.")
		return "cancelled"
	if float(state["inspection_timer"]) > 0.0:
		return "running"
	state["inspection_mode"] = "idle"
	state["inspection_cooldown"] = float(skill.get("cooldown", 10.0))
	selen_inspections_completed += 1
	if not final_attempt:
		_apply_selen_inspection_lock(str(state.get("inspection_target", "")), float(skill.get("disable_seconds", 5.0)))
		root._log("검수 완료: %s 기능이 5초간 멈춥니다." % root.display_name_for_instance(str(state.get("inspection_target", ""))))
	return "completed"


func _apply_selen_inspection_lock(room_id: String, seconds: float) -> void:
	if room_id == "heart_chamber":
		root._apply_update3_heart_debt_lock(seconds, seconds)
	else:
		root._disable_facility_room_by_debt(room_id, seconds)


func _update_selen_advance(selen: Node, state: Dictionary, delta: float) -> void:
	var skill: Dictionary = DataRegistry.skill("consecrated_advance")
	state["floor_cooldown"] = maxf(0.0, float(state.get("floor_cooldown", 0.0)) - delta)
	if float(state["floor_cooldown"]) > 0.0:
		return
	state["floor_cooldown"] = float(skill.get("floor_interval", 2.5))
	while selen_consecrated_floors.size() >= int(skill.get("max_floors", 2)):
		selen_consecrated_floors.pop_front()
	selen_consecrated_floors.append({"position": selen.global_position, "remaining": float(skill.get("floor_seconds", 4.0)), "radius": float(skill.get("floor_radius", 92.0))})
	spawn_effect_burst("holy", selen.global_position, Vector2.ZERO, Vector2(1.3, 1.3), 10.0)


func _update_selen_consecrated_floors(delta: float) -> void:
	for monster in root.monster_units:
		if is_instance_valid(monster):
			monster.consecrated_status_multiplier = 1.0
	for index in range(selen_consecrated_floors.size() - 1, -1, -1):
		var floor: Dictionary = selen_consecrated_floors[index]
		floor["remaining"] = maxf(0.0, float(floor.get("remaining", 0.0)) - delta)
		if float(floor["remaining"]) <= 0.0:
			selen_consecrated_floors.remove_at(index)
		else:
			selen_consecrated_floors[index] = floor
	var occupied := false
	for monster in root.monster_units:
		if not is_instance_valid(monster) or not monster.is_alive():
			continue
		for floor in selen_consecrated_floors:
			if monster.global_position.distance_to(Vector2(floor.get("position", Vector2.ZERO))) <= float(floor.get("radius", 92.0)):
				monster.consecrated_status_multiplier = float(DataRegistry.skill("consecrated_advance").get("status_duration_multiplier", 0.8))
				occupied = true
				break
	var heart: Dictionary = root.update3_active_run.get("heart", {}).duplicate(true)
	heart["charge_gain_multiplier"] = float(DataRegistry.skill("consecrated_advance").get("heart_charge_multiplier", 0.75)) if occupied else 1.0
	root.update3_active_run["heart"] = heart


func _update_selen_final_checklist(selen: Node, state: Dictionary, delta: float) -> void:
	state["final_wait"] = maxf(0.0, float(state.get("final_wait", 0.0)) - delta)
	if float(state["final_wait"]) > 0.0:
		return
	if int(state.get("final_attempt", 0)) >= int(DataRegistry.skill("last_inspection_checklist").get("attempts", 3)):
		state["final_active"] = false
		if int(state.get("final_completed", 0)) >= 3:
			var targets := _selen_inspection_targets()
			var facility := ""
			for target in targets:
				if target != "heart_chamber":
					facility = target
					break
			root._apply_update3_heart_debt_lock(4.0, 4.0)
			if facility != "":
				root._disable_facility_room_by_debt(facility, 4.0)
			root._log("마지막 검수를 모두 허용해 심장실과 시설 하나가 동시에 4초간 잠깁니다.")
		_activate_selen_mercy_barrier(selen, state)
		return
	var result := _update_selen_inspection(selen, state, delta, true)
	if result == "cancelled" or result == "completed":
		state["final_attempt"] = int(state.get("final_attempt", 0)) + 1
		state["final_cancelled"] = int(state.get("final_cancelled", 0)) + (1 if result == "cancelled" else 0)
		state["final_completed"] = int(state.get("final_completed", 0)) + (1 if result == "completed" else 0)
		state["final_wait"] = float(DataRegistry.skill("last_inspection_checklist").get("inter_attempt_seconds", 0.8))


func _activate_selen_mercy_barrier(selen: Node, state: Dictionary) -> void:
	if bool(state.get("barrier_activated", false)):
		return
	var skill: Dictionary = DataRegistry.skill("mercy_barrier")
	var shield := int(skill.get("shield", 55)) + selen_mercy_barrier_bonus
	if int(state.get("final_cancelled", 0)) >= 2:
		shield = maxi(0, shield - int(DataRegistry.skill("last_inspection_checklist").get("cancelled_barrier_reduction", 25)))
	var member_ids: Array = []
	for ally in root.enemy_units:
		if not is_instance_valid(ally) or not ally.is_alive():
			continue
		var ally_data: Dictionary = DataRegistry.enemy(str(ally.unit_id))
		if not ally_data.get("front_tags", []).has("holy_purification"):
			continue
		ally.grant_duo_barrier(shield)
		member_ids.append(ally.get_instance_id())
	selen.activate_shield(float(skill.get("duration", 6.0)), float(skill.get("damage_reduction", 0.22)), "자비의 방벽")
	_play_sfx(SFX_SHIELD_BASH, "selen_mercy_barrier", -5.0, 0.5, 0.82, 0.9)
	selen.boss_attack_interval_multiplier = float(skill.get("attack_interval_multiplier", 1.2))
	state["barrier_activated"] = true
	state["barrier_window"] = float(skill.get("break_window", 4.0))
	state["barrier_members"] = member_ids
	root._log("자비의 방벽: 4초 안에 모든 성정화 보호막을 파괴하면 셀렌이 취약해집니다.")


func _update_selen_barrier(selen: Node, state: Dictionary, delta: float) -> void:
	state["vulnerable_timer"] = maxf(0.0, float(state.get("vulnerable_timer", 0.0)) - delta)
	if float(state["vulnerable_timer"]) <= 0.0:
		selen.boss_damage_taken_multiplier = 1.0
	if not bool(state.get("barrier_activated", false)) or float(state.get("barrier_window", 0.0)) <= 0.0:
		return
	state["barrier_window"] = maxf(0.0, float(state["barrier_window"]) - delta)
	var all_broken := true
	for member_id_value in state.get("barrier_members", []):
		var member = instance_from_id(int(member_id_value))
		if member != null and is_instance_valid(member) and member.is_alive() and int(member.duo_barrier) > 0:
			all_broken = false
			break
	if all_broken:
		state["barrier_window"] = 0.0
		state["vulnerable_timer"] = float(DataRegistry.skill("mercy_barrier").get("vulnerable_seconds", 2.5))
		selen.boss_damage_taken_multiplier = float(DataRegistry.skill("mercy_barrier").get("vulnerable_damage_multiplier", 1.18))
		selen_barrier_breaks_in_window += 1
		root._log("방벽 파괴 성공: 셀렌이 2.5초간 받는 피해가 18% 증가합니다.")


func _initialize_guild_commissioner_roman(roman: Node) -> void:
	var contributors: Dictionary = {}
	var starting_budget := 0
	for support in root.enemy_units:
		if support == roman or not is_instance_valid(support) or not support.is_alive() or not ROMAN_GUILD_SUPPORT_IDS.has(str(support.unit_id)):
			continue
		contributors[support.get_instance_id()] = true
		starting_budget += 1
	starting_budget = clampi(starting_budget + roman_start_budget_delta, 0, 5)
	commissioner_roman_states[roman.get_instance_id()] = {
		"unit_id": roman.get_instance_id(),
		"phase": 1,
		"budget": starting_budget,
		"budget_contributors": contributors,
		"stress": 0,
		"paperwork_triggered": false,
		"freeze_mode": "idle",
		"freeze_timer": 0.0,
		"freeze_cooldown": float(DataRegistry.skill("asset_freeze").get("first_delay", 5.0)),
		"freeze_target": "",
		"freeze_hp_start": int(roman.hp),
		"mercenary_mode": "idle",
		"mercenary_timer": 0.0,
		"mercenary_cooldown": 0.0,
		"mercenary_calls": 0,
		"mercenary_call_max": roman_mercenary_call_max,
		"summoned_mercenaries": {},
		"emergency_used": false
	}
	roman.set_tactical_state(Constants.UNIT_STATE_SEEK_TARGET, "감사 예산 %d/5" % starting_budget)


func commissioner_roman_state(roman: Node) -> Dictionary:
	if roman == null or not is_instance_valid(roman):
		return {}
	return commissioner_roman_states.get(roman.get_instance_id(), {}).duplicate(true)


func _update_guild_commissioner_roman(delta: float) -> void:
	for state_key in commissioner_roman_states.keys():
		var state: Dictionary = commissioner_roman_states[state_key]
		var roman = instance_from_id(int(state.get("unit_id", 0)))
		if roman == null or not is_instance_valid(roman) or not roman.is_alive():
			commissioner_roman_states.erase(state_key)
			continue
		_update_roman_budget_contributors(state)
		_update_roman_summoned_mercenaries(state, delta)
		var hp_ratio := float(roman.hp) / float(maxi(1, roman.max_hp))
		if hp_ratio <= float(DataRegistry.skill("mercenary_invoice").get("trigger_hp_ratio", 0.70)) and int(state.get("phase", 1)) < 2:
			state["phase"] = 2
			root._log("로만 2단계: 용병 청구서를 발행합니다. 호출 중 1.3초 동안 이동하지 못합니다.")
		if hp_ratio <= float(DataRegistry.skill("emergency_budget").get("trigger_hp_ratio", 0.35)) and int(state.get("phase", 1)) < 3:
			state["phase"] = 3
			_activate_roman_emergency_budget(roman, state)
		_update_roman_mercenary_invoice(roman, state, delta)
		if str(state.get("mercenary_mode", "idle")) == "idle":
			_update_roman_asset_freeze(roman, state, delta)
		commissioner_roman_states[state_key] = state


func _update_roman_budget_contributors(state: Dictionary) -> void:
	var contributors: Dictionary = state.get("budget_contributors", {}).duplicate(true)
	for contributor_id_value in contributors.keys():
		if not bool(contributors[contributor_id_value]):
			continue
		var support = instance_from_id(int(contributor_id_value))
		if support != null and is_instance_valid(support) and support.is_alive():
			continue
		contributors[contributor_id_value] = false
		if int(state.get("budget", 0)) > 0:
			state["budget"] = int(state.get("budget", 0)) - 1
	state["budget_contributors"] = contributors


func _roman_support_facility_completed(support: Node) -> void:
	if support == null or not is_instance_valid(support) or not ROMAN_GUILD_SUPPORT_IDS.has(str(support.unit_id)):
		return
	for state_key in commissioner_roman_states.keys():
		var state: Dictionary = commissioner_roman_states[state_key]
		state["budget"] = mini(5, int(state.get("budget", 0)) + 1)
		commissioner_roman_states[state_key] = state
		root._log("지원 적 시설 공격 완료: 로만 감사 예산 +1 (%d/5)." % int(state["budget"]))


func _roman_asset_target() -> String:
	var result := ""
	var best_score := -INF
	for room_id_value in root.rooms.keys():
		var room_id := str(room_id_value)
		var role := str(root.rooms[room_id].get("facility_role", ""))
		if role in ["", "entry", "trap", "corridor", "core", "build_slot"]:
			continue
		if room_id != "heart_chamber" and not root._facility_room_is_active(room_id):
			continue
		var occupants := 0
		for monster in root.monster_units:
			if is_instance_valid(monster) and monster.is_alive() and str(monster.current_room) == room_id:
				occupants += 1
		var score := float(occupants * 100 + (30 if room_id == "heart_chamber" else 0))
		if score > best_score:
			best_score = score
			result = room_id
	return result


func _roman_cooldown_multiplier(state: Dictionary) -> float:
	return 1.0 + float(state.get("stress", 0)) * float(DataRegistry.skill("audit_stress").get("cooldown_penalty_per_stack", 0.06))


func _update_roman_asset_freeze(roman: Node, state: Dictionary, delta: float) -> String:
	var skill: Dictionary = DataRegistry.skill("asset_freeze")
	var mode := str(state.get("freeze_mode", "idle"))
	if mode == "idle":
		state["freeze_cooldown"] = maxf(0.0, float(state.get("freeze_cooldown", 0.0)) - delta)
		if float(state["freeze_cooldown"]) > 0.0 or int(state.get("budget", 0)) < int(skill.get("budget_cost", 1)):
			return "idle"
		var target := _roman_asset_target()
		if target == "":
			state["freeze_cooldown"] = 1.0
			return "idle"
		state["budget"] = int(state.get("budget", 0)) - int(skill.get("budget_cost", 1))
		state["freeze_mode"] = "telegraph"
		state["freeze_timer"] = float(skill.get("telegraph_seconds", 1.0))
		state["freeze_target"] = target
		state["freeze_hp_start"] = int(roman.hp)
		roman.play_skill(root.graph.center(target))
		roman.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "자산 동결 예고", root.display_name_for_instance(target))
		_play_sfx(SFX_SHIELD_BASH, "roman_asset_freeze", -10.0, 0.3, 0.9, 0.96)
		root._log("자산 동결 예고: %s · 1초 안에 로만에게 피해 50을 주세요." % root.display_name_for_instance(target))
		return "started"
	state["freeze_timer"] = maxf(0.0, float(state.get("freeze_timer", 0.0)) - delta)
	if int(state.get("freeze_hp_start", roman.hp)) - int(roman.hp) >= int(skill.get("cancel_damage", 50)):
		state["freeze_mode"] = "idle"
		state["freeze_cooldown"] = float(skill.get("cooldown", 10.0)) * _roman_cooldown_multiplier(state)
		_roman_add_stress(roman, state, 1, "자산 동결 취소")
		roman_asset_freezes_cancelled += 1
		return "cancelled"
	if float(state["freeze_timer"]) > 0.0:
		return "running"
	var room_id := str(state.get("freeze_target", ""))
	if room_id == "heart_chamber":
		root._apply_update3_heart_debt_lock(float(skill.get("disable_seconds", 5.0)), float(skill.get("disable_seconds", 5.0)))
	else:
		root._disable_facility_room_by_debt(room_id, float(skill.get("disable_seconds", 5.0)))
	state["freeze_mode"] = "idle"
	state["freeze_cooldown"] = float(skill.get("cooldown", 10.0)) * _roman_cooldown_multiplier(state)
	root._log("자산 동결 완료: %s 기능이 5초간 멈춥니다." % root.display_name_for_instance(room_id))
	return "completed"


func _update_roman_mercenary_invoice(roman: Node, state: Dictionary, delta: float) -> void:
	var skill: Dictionary = DataRegistry.skill("mercenary_invoice")
	state["mercenary_cooldown"] = maxf(0.0, float(state.get("mercenary_cooldown", 0.0)) - delta)
	if str(state.get("mercenary_mode", "idle")) == "casting":
		state["mercenary_timer"] = maxf(0.0, float(state.get("mercenary_timer", 0.0)) - delta)
		if float(state["mercenary_timer"]) > 0.0:
			return
		roman.boss_move_multiplier = 1.0 if int(state.get("stress", 0)) < 3 else float(DataRegistry.skill("audit_stress").get("move_multiplier", 0.94))
		state["mercenary_mode"] = "idle"
		var summon_ids: Array = skill.get("summon_ids", ["bounty_tracker", "combat_alchemist"])
		var summon_id := str(summon_ids[int(state.get("mercenary_calls", 0)) % summon_ids.size()])
		var before: int = root.enemy_units.size()
		spawn_enemy(summon_id, {"ignore_counter_cap": true, "hp_scale": 1.0, "atk_scale": 0.85})
		if root.enemy_units.size() > before:
			var mercenary = root.enemy_units.back()
			var summoned: Dictionary = state.get("summoned_mercenaries", {}).duplicate(true)
			summoned[mercenary.get_instance_id()] = {"age": 0.0, "counted": false}
			state["summoned_mercenaries"] = summoned
		state["mercenary_calls"] = int(state.get("mercenary_calls", 0)) + 1
		roman_mercenaries_summoned += 1
		state["mercenary_cooldown"] = float(skill.get("cooldown", 12.0)) * _roman_cooldown_multiplier(state)
		return
	if int(state.get("phase", 1)) < 2 or int(state.get("mercenary_calls", 0)) >= int(state.get("mercenary_call_max", 2)) or int(state.get("budget", 0)) < int(skill.get("budget_cost", 2)) or float(state["mercenary_cooldown"]) > 0.0 or str(state.get("freeze_mode", "idle")) != "idle":
		return
	state["budget"] = int(state.get("budget", 0)) - int(skill.get("budget_cost", 2))
	state["mercenary_mode"] = "casting"
	state["mercenary_timer"] = float(skill.get("cast_seconds", 1.3))
	roman.boss_move_multiplier = 0.0
	roman.play_skill()
	roman.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "용병 청구서 발행")
	root._log("용병 청구서: 로만이 1.3초 동안 이동하지 못합니다.")


func _update_roman_summoned_mercenaries(state: Dictionary, delta: float) -> void:
	var summoned: Dictionary = state.get("summoned_mercenaries", {}).duplicate(true)
	for mercenary_id_value in summoned.keys():
		var record: Dictionary = summoned[mercenary_id_value]
		if bool(record.get("counted", false)):
			continue
		record["age"] = float(record.get("age", 0.0)) + delta
		var mercenary = instance_from_id(int(mercenary_id_value))
		if mercenary == null or not is_instance_valid(mercenary) or not mercenary.is_alive():
			record["counted"] = true
			if float(record["age"]) <= float(DataRegistry.skill("mercenary_invoice").get("fast_kill_seconds", 6.0)):
				var roman = instance_from_id(int(state.get("unit_id", 0)))
				if roman != null and is_instance_valid(roman):
					_roman_add_stress(roman, state, 1, "용병 빠른 처치")
				roman_fast_mercenary_kills += 1
		summoned[mercenary_id_value] = record
	state["summoned_mercenaries"] = summoned


func _activate_roman_emergency_budget(roman: Node, state: Dictionary) -> void:
	if bool(state.get("emergency_used", false)):
		return
	var skill: Dictionary = DataRegistry.skill("emergency_budget")
	roman_final_phase_entry_budget = int(state.get("budget", 0))
	var spend := mini(4, int(state.get("budget", 0)))
	var shield := int(skill.get("minimum_shield", 18)) if spend <= 0 else mini(int(skill.get("shield_max", 72)), spend * int(skill.get("shield_per_budget", 18)))
	state["budget"] = int(state.get("budget", 0)) - spend
	roman.grant_duo_barrier(shield)
	for ally in root.enemy_units:
		if is_instance_valid(ally) and ally.is_alive() and ally != roman and ally.global_position.distance_to(roman.global_position) <= 300.0:
			ally.heal(int(skill.get("ally_heal", 12)))
	state["emergency_used"] = true
	_roman_add_stress(roman, state, int(skill.get("stress_gain", 2)), "긴급 예산")
	root._log("긴급 예산: 보호막 %d · 주변 길드 병력 HP 12 회복." % shield)


func _roman_add_stress(roman: Node, state: Dictionary, amount: int, reason: String) -> int:
	var skill: Dictionary = DataRegistry.skill("audit_stress")
	var before := int(state.get("stress", 0))
	state["stress"] = mini(int(skill.get("max_stacks", 5)), before + maxi(0, amount))
	if int(state["stress"]) >= int(skill.get("slow_threshold", 3)):
		roman.boss_move_multiplier = float(skill.get("move_multiplier", 0.94))
	if int(state["stress"]) >= int(skill.get("paperwork_threshold", 5)) and not bool(state.get("paperwork_triggered", false)):
		state["paperwork_triggered"] = true
		roman.action_interrupt_timer = maxf(float(roman.action_interrupt_timer), float(skill.get("paperwork_stagger_seconds", 2.0)))
		roman.set_tactical_state(Constants.UNIT_STATE_STUNNED, "서류 정리 경직")
		root._log("감사 스트레스 5: 로만이 2초간 서류를 정리합니다.")
	if int(state["stress"]) > before:
		root._log("감사 스트레스 +%d (%d/5): %s." % [int(state["stress"]) - before, int(state["stress"]), reason])
	return int(state["stress"])


func _roman_add_stress_all(amount: int, reason: String) -> void:
	for state_key in commissioner_roman_states.keys():
		var state: Dictionary = commissioner_roman_states[state_key]
		var roman = instance_from_id(int(state.get("unit_id", 0)))
		if roman != null and is_instance_valid(roman) and roman.is_alive():
			_roman_add_stress(roman, state, amount, reason)
			commissioner_roman_states[state_key] = state


func evaluate_update3_counter_combo(enemy_ids: Array) -> Dictionary:
	var unique_ids: Array[String] = []
	for enemy_id_value in enemy_ids:
		var enemy_id := str(enemy_id_value)
		if not UPDATE3_COUNTER_ENEMY_IDS.has(enemy_id) or unique_ids.has(enemy_id):
			continue
		unique_ids.append(enemy_id)
	unique_ids.sort()
	var base_threat := 0.0
	for enemy_id in unique_ids:
		base_threat += float(DataRegistry.enemy(enemy_id).get("threat", 0.0))
	var combo_bonus := 0.0
	for first_index in range(unique_ids.size()):
		for second_index in range(first_index + 1, unique_ids.size()):
			var key := "%s|%s" % [unique_ids[first_index], unique_ids[second_index]]
			combo_bonus += float(COUNTER_COMBO_THREAT_BONUSES.get(key, 0.0))
	var total := base_threat + combo_bonus
	var type_limit_ok := unique_ids.size() <= COUNTER_ENEMY_TYPE_LIMIT
	var threat_ok := total <= HOLY_COUNTER_COMBO_THREAT_CAP + 0.0001
	var reason := ""
	if not type_limit_ok:
		reason = "카운터 적은 한 웨이브에 최대 %d종" % COUNTER_ENEMY_TYPE_LIMIT
	elif not threat_ok:
		reason = "조합 threat %.2f가 상한 %.2f 초과" % [total, HOLY_COUNTER_COMBO_THREAT_CAP]
	return {"allowed": type_limit_ok and threat_ok, "enemy_ids": unique_ids, "base_threat": base_threat, "combo_bonus": combo_bonus, "total_threat": total, "reason": reason}


func active_heart_target_count() -> int:
	var count := 0
	for enemy in root.enemy_units:
		if is_instance_valid(enemy) and enemy.is_alive() and str(enemy.goal_room) == "heart_chamber":
			count += 1
	return count


func _refresh_heart_target_limit() -> void:
	var heart_goal: String = str(root._update3_enemy_goal(_core_room(), true)) if root.has_method("_update3_enemy_goal") else _core_room()
	var active: Array = []
	var waiting: Array = []
	for enemy in root.enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive() or not bool(enemy.get_meta("prefers_heart_goal", false)):
			continue
		if str(enemy.goal_room) == "heart_chamber":
			active.append(enemy)
		else:
			waiting.append(enemy)
	if heart_goal != "heart_chamber":
		for enemy in active:
			enemy.goal_room = _core_room()
			enemy.set_path(_path_from_world_to_room(enemy.global_position, enemy.goal_room))
		return
	while active.size() > 1:
		var extra = active.pop_back()
		extra.goal_room = _core_room()
		extra.set_path(_path_from_world_to_room(extra.global_position, extra.goal_room))
		waiting.append(extra)
	if active.is_empty() and not waiting.is_empty():
		var promoted = waiting[0]
		promoted.goal_room = "heart_chamber"
		promoted.set_path(_path_from_world_to_room(promoted.global_position, promoted.goal_room))

func _royal_rally_commander() -> Node:
	if not ROYAL_RALLY_DAYS.has(GameState.day):
		return null
	for enemy in root.enemy_units:
		if enemy.is_alive() and enemy.unit_id == "selen_trainee_paladin" and enemy.role == "commander":
			return enemy
	return null

func _update_royal_rally(delta: float) -> void:
	if not ROYAL_RALLY_DAYS.has(GameState.day):
		return
	var commander = _royal_rally_commander()
	var active := commander != null
	if active:
		royal_rally_active_seconds += delta
		royal_rally_pulse_timer -= delta
		if royal_rally_pulse_timer <= 0.0:
			royal_rally_pulse_timer = ROYAL_RALLY_PULSE_SECONDS
			royal_rally_activations += 1
			commander.play_skill(commander.global_position + Vector2(1, 0))
			commander.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "왕국군 진군 지휘", "%d명 강화" % _royal_rally_recipient_count(commander))
			root._log("셀렌의 진군 지휘: 주변 왕국군의 이동과 공격 속도가 상승합니다.")
	elif royal_rally_was_active:
		royal_rally_stopped = true
		root._log("셀렌이 쓰러져 왕국군의 진군 강화가 해제되었습니다.")
	royal_rally_was_active = active
	_apply_enemy_command_buffs()

func _royal_rally_recipient_count(commander: Node) -> int:
	var count := 0
	for enemy in root.enemy_units:
		if enemy != commander and enemy.is_alive():
			count += 1
	return count

func _royal_rally_result_line() -> String:
	if not ROYAL_RALLY_DAYS.has(GameState.day):
		return ""
	var stopped_text := "지휘관 격퇴" if royal_rally_stopped else "전투 종료까지 유지"
	return "셀렌 지휘: 진군 강화 %.1f초 · 지휘 %d회 · %s" % [royal_rally_active_seconds, royal_rally_activations, stopped_text]

func _update_brave_shout(delta: float) -> void:
	if not HERO_SKILL_DAYS.has(GameState.day):
		return
	if brave_shout_remaining > 0.0:
		var active_delta := minf(delta, brave_shout_remaining)
		brave_shout_active_seconds += active_delta
		brave_shout_remaining = maxf(0.0, brave_shout_remaining - delta)
	var active := brave_shout_remaining > 0.0
	if brave_shout_was_active and not active:
		brave_shout_buffed_ids.clear()
		root._log("레온의 용기의 외침 강화가 끝났습니다.")
	brave_shout_was_active = active
	_apply_enemy_command_buffs()

func _apply_enemy_command_buffs() -> void:
	var rally_commander = _royal_rally_commander()
	var shout_active := HERO_SKILL_DAYS.has(GameState.day) and brave_shout_remaining > 0.0
	for enemy in root.enemy_units:
		if not is_instance_valid(enemy):
			continue
		var move_multiplier := 1.0
		var attack_interval_multiplier := 1.0
		if rally_commander != null and enemy.is_alive() and enemy != rally_commander:
			move_multiplier *= ROYAL_RALLY_MOVE_MULTIPLIER
			attack_interval_multiplier *= ROYAL_RALLY_ATTACK_INTERVAL_MULTIPLIER
		if shout_active and enemy.is_alive() and brave_shout_buffed_ids.has(enemy.get_instance_id()):
			move_multiplier *= BRAVE_SHOUT_MOVE_MULTIPLIER
			attack_interval_multiplier *= BRAVE_SHOUT_ATTACK_INTERVAL_MULTIPLIER
		enemy.royal_rally_move_multiplier = move_multiplier
		enemy.royal_rally_attack_interval_multiplier = attack_interval_multiplier

func _try_brave_shout(unit: Node) -> bool:
	if not HERO_SKILL_DAYS.has(GameState.day) or not _is_hero_unit(unit) or not unit.skill_ready("brave_shout"):
		return false
	var recipients: Array[Node] = []
	for enemy in root.enemy_units:
		if not enemy.is_alive():
			continue
		if unit.global_position.distance_to(enemy.global_position) <= BRAVE_SHOUT_RADIUS:
			recipients.append(enemy)
	if recipients.is_empty():
		return false
	brave_shout_buffed_ids.clear()
	for recipient in recipients:
		brave_shout_buffed_ids[recipient.get_instance_id()] = true
	brave_shout_remaining = BRAVE_SHOUT_DURATION
	brave_shout_activations += 1
	brave_shout_recipient_total += recipients.size()
	unit.set_skill_cooldown("brave_shout", BRAVE_SHOUT_COOLDOWN)
	unit.play_skill(unit.global_position + Vector2(1, 0))
	unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "용기의 외침", "%d명 강화" % recipients.size())
	spawn_effect_burst("guard", unit.global_position, Vector2(0, -20), Vector2(1.24, 1.08), 13.0)
	root._log("%s의 용기의 외침: 주변 왕국군 %d명의 이동과 공격 속도가 상승합니다." % [unit.display_name, recipients.size()])
	return true

func _brave_shout_result_line() -> String:
	if not HERO_SKILL_DAYS.has(GameState.day) or brave_shout_activations <= 0:
		return ""
	return "레온 기술: 용기의 외침 %d회 · 누적 %d명 강화 · %.1f초 유지" % [brave_shout_activations, brave_shout_recipient_total, brave_shout_active_seconds]

func _update_update2_counterforce(delta: float) -> void:
	for enemy in root.enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive():
			continue
		var profile: Dictionary = DataRegistry.update2_counterforce_profile(str(enemy.unit_id))
		if profile.is_empty():
			continue
		var instance_id: int = enemy.get_instance_id()
		var remaining := maxf(0.0, float(update2_counter_cooldowns.get(instance_id, 0.0)) - delta)
		update2_counter_cooldowns[instance_id] = remaining
		if remaining > 0.0:
			continue
		if _try_update2_counter_action(enemy, profile):
			update2_counter_cooldowns[instance_id] = maxf(0.1, float(profile.get("cooldown", 8.0)))
		else:
			# 대상이 없을 때는 매 프레임 재탐색하지 않고 짧게 기다린다.
			update2_counter_cooldowns[instance_id] = 0.5


func _update_seal_chainbearers(delta: float) -> void:
	var skill: Dictionary = DataRegistry.skill("seal_chain")
	if skill.is_empty():
		return
	for enemy in root.enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive() or str(enemy.unit_id) != "seal_chainbearer":
			continue
		if enemy.seal_chain_cast_timer > 0.0:
			_tick_seal_chain_cast(enemy, delta, skill)
			continue
		enemy.seal_chain_cooldown_timer = maxf(0.0, enemy.seal_chain_cooldown_timer - delta)
		if enemy.seal_chain_cooldown_timer > 0.0 or enemy.action_interrupt_timer > 0.0:
			continue
		var target := _seal_chain_target(enemy, float(skill.get("range", 150.0)), skill.get("priority_monster_ids", []))
		if target != null:
			_begin_seal_chain_cast(enemy, target, skill)


func _begin_seal_chain_cast(enemy: Node, target: Node, skill: Dictionary = {}) -> bool:
	if enemy == null or target == null or not is_instance_valid(enemy) or not is_instance_valid(target):
		return false
	var resolved_skill: Dictionary = skill if not skill.is_empty() else DataRegistry.skill("seal_chain")
	var telegraph_seconds := maxf(0.1, float(resolved_skill.get("telegraph_seconds", 0.9)))
	enemy.seal_chain_target = target
	enemy.seal_chain_cast_timer = telegraph_seconds
	enemy.skill_anim_timer = maxf(enemy.skill_anim_timer, telegraph_seconds)
	enemy.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "봉인 사슬 예고", target.display_name)
	enemy.mark_action_target(target, telegraph_seconds)
	target.begin_seal_chain_telegraph(enemy, telegraph_seconds)
	seal_chain_telegraphs_started += 1
	root._log("%s이 %s에게 봉인 사슬을 예고합니다. %.1f초 안에 끊으세요!" % [enemy.display_name, target.display_name, telegraph_seconds])
	return true


func _tick_seal_chain_cast(enemy: Node, delta: float, skill: Dictionary) -> void:
	var target = enemy.seal_chain_target
	if enemy.action_interrupt_timer > 0.0 or target == null or not is_instance_valid(target) or not target.is_alive():
		_cancel_seal_chain_cast(enemy, true)
		return
	var cast_range := float(skill.get("range", 150.0))
	if enemy.global_position.distance_to(target.global_position) > cast_range:
		_cancel_seal_chain_cast(enemy, false)
		return
	enemy.seal_chain_cast_timer = maxf(0.0, enemy.seal_chain_cast_timer - delta)
	if enemy.seal_chain_cast_timer > 0.0:
		return
	target.apply_seal_chain(
		float(skill.get("move_lock_seconds", 2.2)),
		float(skill.get("skill_lock_seconds", 1.5)),
		float(skill.get("same_target_immunity_seconds", 5.0))
	)
	enemy.seal_chain_target = null
	enemy.seal_chain_cooldown_timer = maxf(0.1, float(skill.get("cooldown", 9.0)))
	enemy.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "봉인 사슬", target.display_name)
	spawn_effect_burst("guard", target.global_position, Vector2(0, -18), Vector2(1.18, 1.04), 13.0)
	seal_chain_activations += 1
	root._log("%s의 봉인 사슬: %s의 이동 2.2초·액티브 스킬 1.5초 봉인." % [enemy.display_name, target.display_name])


func _cancel_seal_chain_cast(enemy: Node, interrupted: bool) -> void:
	var target = enemy.seal_chain_target
	if target != null and is_instance_valid(target):
		target.cancel_seal_chain_telegraph(enemy)
	enemy.seal_chain_target = null
	enemy.seal_chain_cast_timer = 0.0
	enemy.skill_anim_timer = 0.0
	enemy.seal_chain_cooldown_timer = 1.0 if interrupted else 0.5
	if interrupted:
		seal_chain_interruptions += 1
		root._log("봉인 사슬 시전이 끊겼습니다.")


func _seal_chain_target(enemy: Node, cast_range: float, priority_ids: Array = []) -> Node:
	var threatened = enemy.threat_unit
	if _seal_chain_target_eligible(enemy, threatened, cast_range):
		return threatened
	var selected: Node = null
	var selected_score := -INF
	for monster in root.monster_units:
		if not _seal_chain_target_eligible(enemy, monster, cast_range):
			continue
		var priority_index := priority_ids.find(str(monster.unit_id))
		var priority_score := 1000.0 - float(priority_index * 10) if priority_index >= 0 else 0.0
		var distance_score: float = -enemy.global_position.distance_to(monster.global_position) / 1000.0
		var score: float = priority_score + distance_score
		if score > selected_score:
			selected_score = score
			selected = monster
	return selected


func _seal_chain_target_eligible(enemy: Node, target: Node, cast_range: float) -> bool:
	return target != null \
		and is_instance_valid(target) \
		and target.is_alive() \
		and target.faction == Constants.FACTION_MONSTER \
		and float(target.seal_target_immunity_timer) <= 0.0 \
		and enemy.global_position.distance_to(target.global_position) <= cast_range


func seal_chain_fairness_reduction() -> float:
	var skill: Dictionary = DataRegistry.skill("seal_chain")
	if skill.is_empty():
		return 0.0
	return clampf(float(skill.get("move_lock_seconds", 0.0)) / maxf(0.1, float(skill.get("cooldown", 9.0))), 0.0, 1.0)


func _update_bounty_trackers(delta: float) -> void:
	var skill: Dictionary = DataRegistry.skill("bounty_target")
	if skill.is_empty():
		return
	for enemy in root.enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive():
			continue
		if str(DataRegistry.enemy(str(enemy.unit_id)).get("behavior_handler", "")) != "bounty_tracker":
			continue
		enemy.bounty_evaluation_timer = maxf(0.0, enemy.bounty_evaluation_timer - delta)
		if enemy.bounty_evaluation_timer > 0.0:
			continue
		bounty_evaluations += 1
		var target := _bounty_select_target(enemy, float(skill.get("contribution_window_seconds", 20.0)))
		if target == null:
			enemy.bounty_evaluation_timer = 1.0
			continue
		var duration := float(skill.get("duration", 6.0))
		enemy.apply_bounty_target(target, duration, float(skill.get("damage_taken_multiplier", 1.15)))
		enemy.bounty_evaluation_timer = float(skill.get("cooldown", 12.0))
		enemy.play_skill(target.global_position)
		enemy.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "현상금 표적", target.display_name)
		spawn_effect_burst("guard", target.global_position, Vector2(0, -24), Vector2(1.0, 0.9), 12.0)
		bounty_marks_applied += 1
		root._log("%s가 최근 20초 기여 1위 %s에게 6초 현상금을 걸었습니다." % [enemy.display_name, target.display_name])


func _bounty_select_target(_tracker: Node, window_seconds: float = 20.0) -> Node:
	if not root.has_method("_recent_monster_contribution_scores"):
		return null
	var scores: Dictionary = root._recent_monster_contribution_scores(window_seconds)
	if scores.is_empty():
		return null
	var legacy_id := str(root._legacy_monster_species_id()) if root.has_method("_legacy_monster_species_id") else ""
	var selected: Node = null
	var selected_score := 0.0
	for monster in root.monster_units:
		if not is_instance_valid(monster) or not monster.is_alive():
			continue
		var score := float(scores.get(str(monster.unit_id), 0.0))
		if score <= 0.0:
			continue
		if selected == null or score > selected_score or (is_equal_approx(score, selected_score) and str(monster.unit_id) == legacy_id and str(selected.unit_id) != legacy_id):
			selected = monster
			selected_score = score
	return selected


func _bounty_combat_target(tracker: Node) -> Node:
	if tracker.threat_unit != null and is_instance_valid(tracker.threat_unit) and tracker.threat_unit.is_alive():
		return tracker.threat_unit
	if tracker.bounty_target_timer > 0.0 and tracker.bounty_target != null and is_instance_valid(tracker.bounty_target) and tracker.bounty_target.is_alive():
		return tracker.bounty_target
	return null


func _update_combat_alchemists(delta: float) -> void:
	var skill: Dictionary = DataRegistry.skill("acid_solution")
	if skill.is_empty():
		return
	for enemy in root.enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive() or str(DataRegistry.enemy(str(enemy.unit_id)).get("behavior_handler", "")) != "combat_alchemist":
			continue
		if enemy.skill_ready("acid_solution"):
			var target := _acid_throw_target(enemy, float(skill.get("range", 180.0)))
			if target != null:
				begin_alchemist_acid_throw(enemy, target)
	_update_acid_telegraphs(delta)
	_update_acid_zones(delta)


func _acid_throw_target(alchemist: Node, cast_range: float) -> Node:
	var selected: Node = null
	var selected_score := -INF
	for monster in root.monster_units:
		if not is_instance_valid(monster) or not monster.is_alive():
			continue
		var distance: float = alchemist.global_position.distance_to(monster.global_position)
		if distance > cast_range:
			continue
		var toktok_bonus := 1000.0 if str(monster.unit_id) == "armored_beetle" else 0.0
		var facility_bonus := 300.0 if str(monster.current_room) in root._update3_active_facility_room_ids() else 0.0
		var score: float = toktok_bonus + facility_bonus - distance
		if score > selected_score:
			selected_score = score
			selected = monster
	return selected


func begin_alchemist_acid_throw(alchemist: Node, target: Node) -> Dictionary:
	if alchemist == null or target == null or not is_instance_valid(alchemist) or not is_instance_valid(target) or not alchemist.is_alive() or not target.is_alive():
		return {"ok": false, "reason": "invalid_cast"}
	var skill: Dictionary = DataRegistry.skill("acid_solution")
	if alchemist.global_position.distance_to(target.global_position) > float(skill.get("range", 180.0)):
		return {"ok": false, "reason": "out_of_range"}
	var telegraph := {
		"position": Vector2(target.global_position),
		"remaining": float(skill.get("telegraph_seconds", 0.8)),
		"total": float(skill.get("telegraph_seconds", 0.8)),
		"radius": float(skill.get("radius", 85.0)),
		"source": alchemist,
		"source_id": int(alchemist.get_instance_id())
	}
	acid_telegraphs.append(telegraph)
	alchemist.set_skill_cooldown("acid_solution", float(skill.get("cooldown", 10.0)))
	alchemist.play_skill(target.global_position)
	alchemist.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "산성 용액 예고", target.display_name)
	acid_throws_started += 1
	root._log("전투 연금술사가 %s 위치에 0.8초 산성 용액 예고를 표시했습니다." % target.display_name)
	return {"ok": true, "position": telegraph["position"], "telegraph_seconds": telegraph["remaining"]}


func _update_acid_telegraphs(delta: float) -> void:
	var skill: Dictionary = DataRegistry.skill("acid_solution")
	for index in range(acid_telegraphs.size() - 1, -1, -1):
		var telegraph: Dictionary = acid_telegraphs[index]
		var source = telegraph.get("source")
		if source == null or not is_instance_valid(source) or not source.is_alive():
			acid_telegraphs.remove_at(index)
			continue
		telegraph["remaining"] = maxf(0.0, float(telegraph.get("remaining", 0.0)) - delta)
		acid_telegraphs[index] = telegraph
		if float(telegraph["remaining"]) > 0.0:
			continue
		_deploy_acid_zone(Vector2(telegraph.get("position", Vector2.ZERO)), int(telegraph.get("source_id", 0)), float(skill.get("duration", 5.0)), float(skill.get("radius", 85.0)))
		acid_telegraphs.remove_at(index)


func _deploy_acid_zone(position: Vector2, source_id: int, duration: float = 5.0, radius: float = 85.0) -> Dictionary:
	for index in range(acid_zones.size()):
		var existing: Dictionary = acid_zones[index]
		if Vector2(existing.get("position", Vector2.ZERO)).distance_to(position) <= radius * 0.5:
			existing["remaining"] = maxf(float(existing.get("remaining", 0.0)), duration)
			acid_zones[index] = existing
			return {"refreshed": true, "zone": existing}
	var zone := {"position": position, "remaining": duration, "duration": duration, "radius": radius, "source_id": source_id}
	acid_zones.append(zone)
	acid_zones_created += 1
	root._log("산성 장판이 5초 동안 생성되었습니다. 내부 몬스터 DEF -2·수리 -40%·초당 피해 2.")
	return {"refreshed": false, "zone": zone}


func _update_acid_zones(delta: float) -> void:
	for index in range(acid_zones.size() - 1, -1, -1):
		var zone: Dictionary = acid_zones[index]
		zone["remaining"] = maxf(0.0, float(zone.get("remaining", 0.0)) - delta)
		if float(zone["remaining"]) <= 0.0:
			acid_zones.remove_at(index)
		else:
			acid_zones[index] = zone
	var affected: Dictionary = {}
	for zone in acid_zones:
		var center := Vector2(zone.get("position", Vector2.ZERO))
		var radius := float(zone.get("radius", 85.0))
		for monster in root.monster_units:
			if is_instance_valid(monster) and monster.is_alive() and center.distance_to(monster.global_position) <= radius:
				affected[int(monster.get_instance_id())] = monster
	var skill: Dictionary = DataRegistry.skill("acid_solution")
	for monster in affected.values():
		monster.apply_acid_zone(0.25, int(skill.get("def_penalty", 2)), float(skill.get("repair_multiplier", 0.6)))
	acid_damage_accumulator += delta
	var ticks := int(floor(acid_damage_accumulator))
	if ticks <= 0:
		return
	acid_damage_accumulator -= float(ticks)
	var tick_damage := int(skill.get("damage_per_second", 2)) * ticks
	for monster in affected.values():
		monster.receive_damage(tick_damage)
		spawn_impact(monster.global_position)


func acid_zone_contains(point: Vector2) -> bool:
	for zone in acid_zones:
		if Vector2(zone.get("position", Vector2.ZERO)).distance_to(point) <= float(zone.get("radius", 85.0)):
			return true
	return false


func active_acid_warning_count() -> int:
	return acid_telegraphs.size() + acid_zones.size()


func estimate_toktok_acid_core_reduction(toktok_stats: Dictionary, pressure_atk: int = 9) -> float:
	var base_def := int(toktok_stats.get("def", 0))
	var defense_penalty := int(DataRegistry.skill("acid_solution").get("def_penalty", 2))
	var base_damage := maxi(1, int(round(float(pressure_atk) - float(base_def) * 0.5)))
	var acid_damage := maxi(1, int(round(float(pressure_atk) - float(maxi(0, base_def - defense_penalty)) * 0.5)))
	var survival_ratio := clampf(float(base_damage) / float(acid_damage), 0.0, 1.0)
	var repair_ratio := float(DataRegistry.skill("acid_solution").get("repair_multiplier", 0.6))
	var combined_ratio := repair_ratio * 0.6 + survival_ratio * 0.4
	return 1.0 - combined_ratio


func _update_reliquary_auras(delta: float) -> void:
	var skill: Dictionary = DataRegistry.skill("relic_aura")
	if skill.is_empty():
		return
	var guards: Array = []
	for enemy in root.enemy_units:
		if is_instance_valid(enemy) and enemy.is_alive() and str(DataRegistry.enemy(str(enemy.unit_id)).get("behavior_handler", "")) == "reliquary_guard":
			guards.append(enemy)
	if guards.is_empty():
		return
	var radius := float(skill.get("radius", 155.0))
	var refresh_seconds := maxf(0.25, delta * 2.0)
	var protected_count := 0
	for ally in root.enemy_units:
		if not is_instance_valid(ally) or not ally.is_alive():
			continue
		var covered := false
		for guard in guards:
			if guard.global_position.distance_to(ally.global_position) <= radius:
				covered = true
				break
		if not covered:
			continue
		ally.apply_relic_aura(refresh_seconds, float(skill.get("magic_damage_multiplier", 0.85)), float(skill.get("status_duration_multiplier", 0.75)), float(skill.get("morale_damage_multiplier", 0.75)))
		protected_count += 1
	relic_aura_refreshes += protected_count
	relic_aura_peak_protected = maxi(relic_aura_peak_protected, protected_count)


func active_relic_aura_sources() -> int:
	var count := 0
	for enemy in root.enemy_units:
		if is_instance_valid(enemy) and enemy.is_alive() and str(enemy.unit_id) == "reliquary_guard":
			count += 1
	return count


func _update_choir_exorcists(delta: float) -> void:
	var skill: Dictionary = DataRegistry.skill("purifying_hymn")
	if skill.is_empty():
		return
	for enemy in root.enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive() or str(DataRegistry.enemy(str(enemy.unit_id)).get("behavior_handler", "")) != "choir_exorcist":
			continue
		if enemy.skill_ready("purifying_hymn") and not _choir_is_casting(enemy) and (str(enemy.current_room) == "heart_chamber" or not _choir_cleanse_targets(enemy, float(skill.get("radius", 180.0)), 1).is_empty()):
			begin_purifying_hymn(enemy)
	for index in range(purifying_hymn_casts.size() - 1, -1, -1):
		var cast: Dictionary = purifying_hymn_casts[index]
		var source = instance_from_id(int(cast.get("source_id", 0)))
		if source == null or not is_instance_valid(source) or not source.is_alive() or float(source.action_interrupt_timer) > 0.0:
			if source != null and is_instance_valid(source):
				source.cancel_purifying_hymn()
			purifying_hymn_casts.remove_at(index)
			purifying_hymn_interrupted += 1
			continue
		cast["remaining"] = maxf(0.0, float(cast.get("remaining", 0.0)) - delta)
		purifying_hymn_casts[index] = cast
		source.purifying_hymn_cast_timer = float(cast["remaining"])
		if float(cast["remaining"]) > 0.0:
			continue
		_resolve_purifying_hymn(source)
		purifying_hymn_casts.remove_at(index)


func _choir_is_casting(exorcist: Node) -> bool:
	if exorcist == null or not is_instance_valid(exorcist):
		return false
	var source_id := exorcist.get_instance_id()
	for cast in purifying_hymn_casts:
		if int(cast.get("source_id", 0)) == source_id:
			return true
	return false


func begin_purifying_hymn(exorcist: Node) -> Dictionary:
	if exorcist == null or not is_instance_valid(exorcist) or not exorcist.is_alive() or str(exorcist.unit_id) != "choir_exorcist":
		return {"ok": false, "reason": "invalid_exorcist"}
	if _choir_is_casting(exorcist):
		return {"ok": false, "reason": "already_casting"}
	var skill: Dictionary = DataRegistry.skill("purifying_hymn")
	var cast_seconds := float(skill.get("cast_seconds", 1.2))
	exorcist.stop_navigation()
	exorcist.begin_purifying_hymn(cast_seconds)
	exorcist.set_skill_cooldown("purifying_hymn", float(skill.get("cooldown", 11.0)))
	purifying_hymn_casts.append({"source_id": exorcist.get_instance_id(), "position": exorcist.global_position, "remaining": cast_seconds, "total": cast_seconds, "radius": float(skill.get("radius", 180.0))})
	purifying_hymn_started += 1
	root._log("%s가 1.2초 정화 성가를 시작했습니다. 베베의 빗자루로 중단할 수 있습니다." % exorcist.display_name)
	return {"ok": true, "cast_seconds": cast_seconds, "position": exorcist.global_position}


func _choir_cleanse_targets(exorcist: Node, radius: float, maximum: int) -> Array:
	var candidates: Array = []
	for ally in root.enemy_units:
		if not is_instance_valid(ally) or not ally.is_alive() or ally.global_position.distance_to(exorcist.global_position) > radius or int(ally.negative_status_count()) <= 0:
			continue
		candidates.append(ally)
	candidates.sort_custom(func(a, b):
		var a_count := int(a.negative_status_count())
		var b_count := int(b.negative_status_count())
		if a_count != b_count:
			return a_count > b_count
		return exorcist.global_position.distance_squared_to(a.global_position) < exorcist.global_position.distance_squared_to(b.global_position)
	)
	var result: Array = []
	for candidate in candidates:
		if result.size() >= maximum:
			break
		result.append(candidate)
	return result


func _resolve_purifying_hymn(exorcist: Node) -> Dictionary:
	var skill: Dictionary = DataRegistry.skill("purifying_hymn")
	var targets := _choir_cleanse_targets(exorcist, float(skill.get("radius", 180.0)), int(skill.get("max_targets", 3)))
	var cleansed := 0
	for target in targets:
		if target.cleanse_one_negative_status():
			cleansed += 1
			spawn_effect_burst("shield", target.global_position, Vector2(0, -22), Vector2(0.72, 0.72), 9.0)
	var suppressed := false
	if str(exorcist.current_room) == "heart_chamber" and root.has_method("_suppress_update3_heart_charge"):
		root._suppress_update3_heart_charge(float(skill.get("heart_charge_suppression_seconds", 4.0)))
		suppressed = true
	exorcist.cancel_purifying_hymn()
	purifying_hymn_completed += 1
	purifying_hymn_cleansed += cleansed
	root._log("정화 성가 완료: 아군 %d명 약화 제거%s." % [cleansed, " · 심장 충전 4초 봉쇄" if suppressed else ""])
	return {"ok": true, "cleansed": cleansed, "heart_suppressed": suppressed}


func _update_ledger_binders(delta: float) -> void:
	var skill: Dictionary = DataRegistry.skill("debt_mark")
	if skill.is_empty():
		return
	for room_id_value in ledger_room_marks.keys():
		var room_id := str(room_id_value)
		var mark: Dictionary = ledger_room_marks.get(room_id, {}).duplicate(true)
		var source = instance_from_id(int(mark.get("source_id", 0)))
		if source == null or not is_instance_valid(source) or not source.is_alive():
			ledger_room_marks.erase(room_id)
			ledger_marks_cleared_on_source_down += 1
			root._log("%s 부채 표식이 시전자 격퇴로 해제됐습니다." % _room_name(room_id))
			continue
		mark["remaining"] = maxf(0.0, float(mark.get("remaining", 0.0)) - maxf(0.0, delta))
		if float(mark["remaining"]) <= 0.0:
			ledger_room_marks.erase(room_id)
			root._log("%s 부채 표식이 만료됐습니다." % _room_name(room_id))
		else:
			ledger_room_marks[room_id] = mark
	for index in range(ledger_mark_casts.size() - 1, -1, -1):
		var cast: Dictionary = ledger_mark_casts[index]
		var source = instance_from_id(int(cast.get("source_id", 0)))
		if source == null or not is_instance_valid(source) or not source.is_alive():
			if source != null and is_instance_valid(source):
				source.cancel_ledger_mark_cast()
			ledger_mark_casts.remove_at(index)
			continue
		cast["remaining"] = maxf(0.0, float(cast.get("remaining", 0.0)) - maxf(0.0, delta))
		ledger_mark_casts[index] = cast
		source.ledger_mark_cast_timer = float(cast["remaining"])
		if float(cast["remaining"]) > 0.0:
			continue
		_resolve_ledger_mark(source, str(cast.get("room_id", "")), skill)
		ledger_mark_casts.remove_at(index)
	for enemy in root.enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive() or str(DataRegistry.enemy(str(enemy.unit_id)).get("behavior_handler", "")) != "ledger_binder":
			continue
		if enemy.skill_ready("debt_mark") and not _ledger_is_casting(enemy):
			var target_room := _ledger_target_room(enemy)
			if target_room != "":
				begin_ledger_mark_cast(enemy, target_room)

func _update_combat_overlay_redraw(delta: float) -> void:
	var is_dynamic := _combat_overlay_is_dynamic()
	if is_dynamic and not combat_overlay_was_dynamic:
		combat_overlay_redraw_accumulator = 0.0
		root.queue_redraw()
	elif is_dynamic:
		combat_overlay_redraw_accumulator += maxf(0.0, delta)
		if combat_overlay_redraw_accumulator >= COMBAT_OVERLAY_REDRAW_INTERVAL_SECONDS:
			combat_overlay_redraw_accumulator = fmod(combat_overlay_redraw_accumulator, COMBAT_OVERLAY_REDRAW_INTERVAL_SECONDS)
			root.queue_redraw()
	elif combat_overlay_was_dynamic:
		combat_overlay_redraw_accumulator = 0.0
		root.queue_redraw()
	else:
		combat_overlay_redraw_accumulator = 0.0
	combat_overlay_was_dynamic = is_dynamic


func _combat_overlay_is_dynamic() -> bool:
	if _v20_roles_active():
		return true
	if not acid_telegraphs.is_empty() or not acid_zones.is_empty():
		return true
	if not purifying_hymn_casts.is_empty() or not ledger_mark_casts.is_empty() or not ledger_room_marks.is_empty():
		return true
	if not selen_consecrated_floors.is_empty() or not commissioner_roman_states.is_empty():
		return true
	for state_value in official_selen_states.values():
		if str(state_value.get("inspection_mode", "idle")) in ["telegraph", "mark"]:
			return true
	return false


func _ledger_is_casting(binder: Node) -> bool:
	if binder == null or not is_instance_valid(binder):
		return false
	var source_id := binder.get_instance_id()
	for cast in ledger_mark_casts:
		if int(cast.get("source_id", 0)) == source_id:
			return true
	return false


func _ledger_target_room(binder: Node) -> String:
	if binder == null or not is_instance_valid(binder) or not root.has_method("_update3_active_facility_room_ids"):
		return ""
	var selected := ""
	var selected_score := -INF
	for room_id_value in root._update3_active_facility_room_ids():
		var room_id := str(room_id_value)
		if room_id == "" or ledger_room_marks.has(room_id):
			continue
		var occupants := 0
		for monster in root.monster_units:
			if is_instance_valid(monster) and monster.is_alive() and str(monster.current_room) == room_id:
				occupants += 1
		var score: float = float(occupants * 100) + (25.0 if room_id == "heart_chamber" else 0.0) - binder.global_position.distance_to(root.graph.center(room_id)) / 1000.0
		if score > selected_score:
			selected_score = score
			selected = room_id
	return selected


func begin_ledger_mark_cast(binder: Node, room_id: String = "") -> Dictionary:
	if binder == null or not is_instance_valid(binder) or not binder.is_alive() or str(binder.unit_id) != "ledger_binder":
		return {"ok": false, "reason": "invalid_binder"}
	if _ledger_is_casting(binder):
		return {"ok": false, "reason": "already_casting"}
	var target_room := room_id if room_id != "" else _ledger_target_room(binder)
	if target_room == "" or not root.rooms.has(target_room):
		return {"ok": false, "reason": "no_target_room"}
	var skill: Dictionary = DataRegistry.skill("debt_mark")
	var telegraph := float(skill.get("telegraph_seconds", 1.0))
	binder.stop_navigation()
	binder.begin_ledger_mark_cast(telegraph, _room_name(target_room))
	binder.set_skill_cooldown("debt_mark", float(skill.get("cooldown", 12.0)))
	ledger_mark_casts.append({"source_id": binder.get_instance_id(), "room_id": target_room, "position": root.graph.center(target_room), "remaining": telegraph, "total": telegraph})
	ledger_casts_started += 1
	root._log("%s가 %s에 1초 장부 문양을 예고합니다. 시전자를 먼저 쓰러뜨리세요." % [binder.display_name, _room_name(target_room)])
	return {"ok": true, "room_id": target_room, "telegraph_seconds": telegraph}


func _resolve_ledger_mark(binder: Node, room_id: String, skill: Dictionary = {}) -> Dictionary:
	if binder == null or not is_instance_valid(binder) or not binder.is_alive() or room_id == "":
		return {"ok": false}
	var resolved_skill := skill if not skill.is_empty() else DataRegistry.skill("debt_mark")
	ledger_room_marks[room_id] = {"source_id": binder.get_instance_id(), "remaining": float(resolved_skill.get("duration", 7.0)), "duration": float(resolved_skill.get("duration", 7.0)), "debt": 0}
	binder.cancel_ledger_mark_cast()
	binder.play_skill(root.graph.center(room_id))
	ledger_marks_applied += 1
	root._log("%s에 부채 표식이 생겼습니다. 7초 동안 액티브 스킬 3회를 쓰면 방이 무력화됩니다." % _room_name(room_id))
	return {"ok": true, "room_id": room_id, "duration": float(resolved_skill.get("duration", 7.0))}


func record_ledger_skill_use(monster: Node, skill_id: String) -> Dictionary:
	if monster == null or not is_instance_valid(monster) or not monster.is_alive() or monster.faction != Constants.FACTION_MONSTER:
		return {"counted": false}
	var room_id := str(monster.current_room)
	if not ledger_room_marks.has(room_id):
		return {"counted": false, "room_id": room_id}
	var mark: Dictionary = ledger_room_marks[room_id].duplicate(true)
	mark["debt"] = int(mark.get("debt", 0)) + 1
	ledger_debt_recorded += 1
	var threshold := int(DataRegistry.skill("debt_mark").get("debt_threshold", 3))
	if int(mark["debt"]) >= threshold:
		ledger_room_marks.erase(room_id)
		return _trigger_ledger_overload(room_id, monster, skill_id)
	ledger_room_marks[room_id] = mark
	root._log("%s 부채 %d/%d · %s 사용." % [_room_name(room_id), int(mark["debt"]), threshold, DataRegistry.skill(skill_id).get("display_name", skill_id)])
	root.queue_redraw()
	return {"counted": true, "room_id": room_id, "debt": int(mark["debt"]), "overloaded": false}


func _trigger_ledger_overload(room_id: String, monster: Node, skill_id: String) -> Dictionary:
	var skill: Dictionary = DataRegistry.skill("debt_mark")
	var damage := int(skill.get("room_damage", 20))
	var disable_seconds := float(skill.get("room_disable_seconds", 3.0))
	var damage_result: Dictionary = root._damage_update3_room(room_id, damage, "debt:%d:%d" % [monster.get_instance_id(), Time.get_ticks_usec()]) if root.has_method("_damage_update3_room") else {}
	if room_id == "heart_chamber" and root.has_method("_apply_update3_heart_debt_lock"):
		root._apply_update3_heart_debt_lock(disable_seconds, float(skill.get("heart_active_lock_seconds", 3.0)))
	elif root.has_method("_disable_facility_room_by_debt"):
		root._disable_facility_room_by_debt(room_id, disable_seconds)
	ledger_overloads += 1
	root._log("%s 부채 3중첩 폭주: 방 피해 %d · %.1f초 무력화%s." % [_room_name(room_id), int(damage_result.get("damage", damage)), disable_seconds, " · 심장 액티브 잠금" if room_id == "heart_chamber" else ""])
	root.queue_redraw()
	return {"counted": true, "room_id": room_id, "debt": 3, "overloaded": true, "damage": int(damage_result.get("damage", damage)), "disable_seconds": disable_seconds, "skill_id": skill_id}


func cleanse_ledger_room(room_id: String, cleanser_id: String = "") -> bool:
	if room_id == "" or not ledger_room_marks.has(room_id):
		return false
	ledger_room_marks.erase(room_id)
	ledger_marks_cleansed += 1
	_roman_add_stress_all(1, "부채 표식 정화")
	root._log("%s의 부채 표식이 %s 정화로 해제됐습니다." % [_room_name(room_id), cleanser_id])
	root.queue_redraw()
	return true


func _clear_ledger_marks_from_source(source: Node) -> int:
	if source == null or not is_instance_valid(source):
		return 0
	var cleared := 0
	var source_id := source.get_instance_id()
	for room_id_value in ledger_room_marks.keys():
		var room_id := str(room_id_value)
		if int(ledger_room_marks.get(room_id, {}).get("source_id", 0)) == source_id:
			ledger_room_marks.erase(room_id)
			cleared += 1
	ledger_marks_cleared_on_source_down += cleared
	return cleared


func ledger_mark_state(room_id: String) -> Dictionary:
	return ledger_room_marks.get(room_id, {}).duplicate(true)


func ledger_skill_efficiency_reduction() -> float:
	var skill: Dictionary = DataRegistry.skill("debt_mark")
	return clampf(float(skill.get("room_disable_seconds", 3.0)) / maxf(0.1, float(skill.get("cooldown", 12.0))), 0.0, 1.0)


func ledger_max_skill_hold_seconds() -> float:
	return float(DataRegistry.skill("debt_mark").get("duration", 7.0))

func _try_update2_counter_action(enemy: Node, profile: Dictionary = {}) -> bool:
	if not is_instance_valid(enemy) or not enemy.is_alive():
		return false
	var resolved_profile := profile
	if resolved_profile.is_empty():
		resolved_profile = DataRegistry.update2_counterforce_profile(str(enemy.unit_id))
	if resolved_profile.is_empty():
		return false
	var behavior_id := str(resolved_profile.get("behavior_id", ""))
	if behavior_id == "field_triage":
		return _try_update2_field_triage(enemy, resolved_profile)
	if behavior_id == "adaptive_counterledger":
		return _try_update2_evelyn_counter(enemy, resolved_profile)
	var target := _update2_counter_target(enemy, str(resolved_profile.get("target_rule", "")))
	if target == null:
		return false
	return _apply_update2_counter_modes(enemy, [target], resolved_profile, "")

func _alive_update2_monsters() -> Array:
	var result: Array = []
	for monster in root.monster_units:
		if is_instance_valid(monster) and monster.is_alive():
			result.append(monster)
	return result

func _update2_counter_target(enemy: Node, target_rule: String) -> Node:
	var candidates := _alive_update2_monsters()
	if candidates.is_empty():
		return null
	var result: Node = candidates[0]
	match target_rule:
		"nearest_monster":
			var best_distance := INF
			for candidate in candidates:
				var distance: float = enemy.global_position.distance_squared_to(candidate.global_position)
				if distance < best_distance:
					best_distance = distance
					result = candidate
		"longest_range_monster":
			for candidate in candidates:
				if float(candidate.attack_range) > float(result.attack_range):
					result = candidate
		"protector_or_wounded":
			var protectors := ["slime", "stone_sentinel", "spore_healer"]
			var best_score := -INF
			for candidate in candidates:
				var hp_ratio := float(candidate.hp) / float(maxi(1, int(candidate.max_hp)))
				var score := (2.0 if protectors.has(str(candidate.unit_id)) else 0.0) + (1.0 - hp_ratio)
				if score > best_score:
					best_score = score
					result = candidate
		"facility_defender":
			var best_score := -INF
			for candidate in candidates:
				var room: Dictionary = root.rooms.get(str(candidate.current_room), {})
				var facility_role := str(room.get("facility_role", ""))
				var facility_score := 2.0 if facility_role in ["barracks", "recovery", "treasure"] else 0.0
				var distance_score: float = -enemy.global_position.distance_to(candidate.global_position) / 10000.0
				var score: float = facility_score + distance_score
				if score > best_score:
					best_score = score
					result = candidate
		"caster_or_longest_range":
			var casters := ["imp", "spore_healer", "moon_tracker"]
			var best_score := -INF
			for candidate in candidates:
				var score := (1000.0 if casters.has(str(candidate.unit_id)) else 0.0) + float(candidate.attack_range)
				if score > best_score:
					best_score = score
					result = candidate
	return result

func _apply_update2_counter_modes(enemy: Node, targets: Array, profile: Dictionary, forced_mode: String) -> bool:
	var modes: Array = [forced_mode] if forced_mode != "" else profile.get("counter_modes", [])
	var strength: float = root._update2_soft_counter_strength(float(profile.get("counter_strength", 0.0)))
	var duration := maxf(0.0, float(profile.get("duration", 0.0)))
	if modes.is_empty() or strength <= 0.0 or duration <= 0.0:
		return false
	var affected := 0
	var first_target: Node = null
	for target in targets:
		if not is_instance_valid(target) or not target.is_alive():
			continue
		if first_target == null:
			first_target = target
		for mode_value in modes:
			if target.apply_soft_counter(str(mode_value), duration, strength, str(enemy.unit_id)) > 0.0:
				affected += 1
	if affected <= 0 or first_target == null:
		return false
	enemy.play_skill(first_target.global_position)
	enemy.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, _update2_counter_skill_name(str(enemy.unit_id)), first_target.display_name)
	spawn_effect_burst("guard", first_target.global_position, Vector2(0, -20), Vector2(1.08, 0.94), 12.0)
	_update2_record_counter_activation(str(enemy.unit_id), targets.size())
	root._log("%s의 %s: %d명에게 최대 %.0f%%의 대응 효과를 적용했습니다." % [enemy.display_name, _update2_counter_skill_name(str(enemy.unit_id)), targets.size(), strength * 100.0])
	return true

func _try_update2_field_triage(enemy: Node, profile: Dictionary) -> bool:
	var recipient: Node = null
	var lowest_ratio := 0.95
	for ally in root.enemy_units:
		if not is_instance_valid(ally) or not ally.is_alive():
			continue
		var hp_ratio := float(ally.hp) / float(maxi(1, int(ally.max_hp)))
		if hp_ratio < lowest_ratio:
			lowest_ratio = hp_ratio
			recipient = ally
	if recipient == null:
		return false
	var hp_before := int(recipient.hp)
	var heal_amount := maxi(1, int(round(float(recipient.max_hp) * float(profile.get("heal_ratio", 0.22)))))
	recipient.heal(heal_amount)
	recipient.slow_timer = 0.0
	recipient.slow_factor = 1.0
	var healed := maxi(0, int(recipient.hp) - hp_before)
	enemy.play_skill(recipient.global_position)
	enemy.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, _update2_counter_skill_name(str(enemy.unit_id)), recipient.display_name)
	spawn_effect_burst("heal", recipient.global_position, Vector2(0, -18), Vector2(1.12, 1.02), 12.0)
	update2_counter_healing += healed
	_update2_record_counter_activation(str(enemy.unit_id), 1)
	root._log("%s의 야전 응급처치: %s의 체력을 %d 회복했습니다." % [enemy.display_name, recipient.display_name, healed])
	return true

func _try_update2_evelyn_counter(enemy: Node, profile: Dictionary) -> bool:
	var targets := _alive_update2_monsters()
	if targets.is_empty():
		return false
	var roster_ids: Dictionary = {}
	for target in targets:
		roster_ids[str(target.unit_id)] = true
	var selected_mode := "movement"
	if roster_ids.has("spore_healer"):
		selected_mode = "healing"
	elif roster_ids.has("slime") or roster_ids.has("stone_sentinel"):
		selected_mode = "shield"
	elif roster_ids.has("imp") or roster_ids.has("moon_tracker"):
		selected_mode = "skill_recovery"
	elif roster_ids.has("war_drummer") or roster_ids.has("mimic_porter"):
		selected_mode = "attack_speed"
	return _apply_update2_counter_modes(enemy, targets, profile, selected_mode)

func _update2_record_counter_activation(enemy_id: String, target_count: int) -> void:
	update2_counter_activations[enemy_id] = int(update2_counter_activations.get(enemy_id, 0)) + 1
	update2_counter_targets += maxi(0, target_count)

func _update2_counter_skill_name(enemy_id: String) -> String:
	return {
		"royal_scout": "약점 노출",
		"monster_binder": "룬 구속",
		"ward_breaker": "수호 파쇄",
		"supply_raider": "보급선 절단",
		"anti_magic_archer": "파마 화살",
		"royal_field_medic": "야전 응급처치",
		"royal_strategist_evelyn": "적응형 대응 장부"
	}.get(enemy_id, "왕국 대응 전술")

func _update2_counterforce_result_line() -> String:
	var total_activations := 0
	for value in update2_counter_activations.values():
		total_activations += int(value)
	if total_activations <= 0:
		return ""
	return "왕국 대응군: 전술 %d회 · 영향 %d명 · 야전 회복 %d" % [total_activations, update2_counter_targets, update2_counter_healing]

func clear_effects() -> void:
	damage_number_lanes.clear()
	acid_telegraphs.clear()
	acid_zones.clear()
	acid_damage_accumulator = 0.0
	for cast in purifying_hymn_casts:
		var source = instance_from_id(int(cast.get("source_id", 0)))
		if source != null and is_instance_valid(source):
			source.cancel_purifying_hymn()
	purifying_hymn_casts.clear()
	for cast in ledger_mark_casts:
		var source = instance_from_id(int(cast.get("source_id", 0)))
		if source != null and is_instance_valid(source):
			source.cancel_ledger_mark_cast()
	ledger_mark_casts.clear()
	ledger_room_marks.clear()
	for child in root.effect_root.get_children():
		root.effect_root.remove_child(child)
		child.queue_free()

func clear_quarter_trap_animations() -> void:
	if root.quarter_renderer != null and root.quarter_renderer.has_method("clear_trap_animations"):
		root.quarter_renderer.clear_trap_animations()

func trigger_quarter_trap(instance_id: String, trap_id: String) -> void:
	if root.quarter_renderer != null and root.quarter_renderer.has_method("trigger_trap_animation"):
		root.quarter_renderer.trigger_trap_animation(instance_id, trap_id)

func refresh_unit_rooms() -> void:
	for unit in root.monster_units + root.enemy_units:
		if unit.is_alive():
			var room_id := _point_room(unit.global_position)
			if room_id != "":
				unit.current_room = room_id

func update_ai_paths() -> void:
	for unit in root.monster_units:
		if not unit.is_alive():
			continue
		update_monster_path(unit)
	for unit in root.enemy_units:
		if not unit.is_alive() or _hero_dash_active(unit):
			continue
		update_enemy_path(unit)

func update_monster_path(unit: Node) -> void:
	var hp_ratio = float(unit.hp) / float(unit.max_hp)
	if root.global_directive == Constants.DIRECTIVE_SURVIVAL:
		var has_recovery_nest = root._facility_is_active("recovery")
		var retreat_threshold = 0.85 if has_recovery_nest else 0.70
		var return_threshold = 0.95 if has_recovery_nest else 0.85
		var survival_recovering = unit.tactical_state == Constants.UNIT_STATE_RETREAT and hp_ratio < return_threshold
		if hp_ratio <= retreat_threshold or survival_recovering:
			_retreat_unit(unit, "생존 우선")
			return
	if root.global_directive == Constants.DIRECTIVE_DEFENSE and hp_ratio <= 0.55:
		unit.activate_shield(0.6, 0.70)
	var priority_target = TargetingService.monster_priority(unit, root.enemy_units, root.graph, _core_room(), _treasure_room())
	priority_target = _specialization_priority_target(unit, priority_target)
	if priority_target != null and priority_target.current_room == _core_room():
		if _hold_attack_position(unit, priority_target):
			return
		move_unit_to_room(unit, _core_room())
		unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET, "왕좌 긴급 방어", priority_target.display_name)
		return
	if _run_monster_behavior(unit):
		return
	if try_auto_monster_skill(unit):
		return
	if root.room_directives.get(unit.current_room, Constants.ROOM_DIRECTIVE_NONE) == Constants.ROOM_DIRECTIVE_RETREAT:
		_retreat_unit(unit, "후퇴선 유지")
		return

	if _apply_v20_role_movement(unit, priority_target):
		return
	if priority_target != null and _hold_attack_position(unit, priority_target):
		return
	var ai_behavior = _monster_ai_behavior(unit)
	if ai_behavior == "thief_hunter":
		if priority_target != null and priority_target.unit_id == "thief":
			if priority_target.current_room == unit.current_room:
				move_unit_to_point(unit, priority_target.global_position)
			else:
				move_unit_to_room(unit, priority_target.current_room)
			unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET, "도둑 추격", priority_target.display_name)
			if root.has_method("_onboarding_emit_trigger"):
				root._onboarding_emit_trigger("goblin_chase")
			return
		var thief_has_spawned := false
		for enemy in root.enemy_units:
			if enemy.unit_id == "thief":
				thief_has_spawned = true
				break
		if not thief_has_spawned:
			var staging_room = "spike_corridor" if root.rooms.has("spike_corridor") else str(unit.assigned_room)
			move_unit_to_room(unit, staging_room)
			unit.set_tactical_state(Constants.UNIT_STATE_SEEK_TARGET, "도둑 대비", _room_name(staging_room))
			return
	if ai_behavior == "ally_guard":
		var wounded_ally = _most_wounded_ally(unit)
		if wounded_ally != null and wounded_ally.current_room != unit.current_room:
			move_unit_to_room(unit, wounded_ally.current_room)
			unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "부상 아군 호위", wounded_ally.display_name)
			return
	if ai_behavior == "vault_guard" and unit.unit_id == "goblin":
		var vault_room := _treasure_room()
		if priority_target != null and (priority_target.current_room == vault_room or str(priority_target.goal_room) == vault_room):
			move_unit_to_room(unit, priority_target.current_room)
			unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET, "금고 침입 차단", priority_target.display_name)
		else:
			move_unit_to_room(unit, vault_room)
			unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "금고 수호", _room_name(vault_room))
		return
	if ai_behavior == "entry_anchor" and unit.unit_id == "slime":
		var anchor_point = root.graph.center("entrance").lerp(root.graph.center("spike_corridor"), 0.55)
		move_unit_to_point(unit, anchor_point)
		unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "성문 파수", "입구 방어선")
		return
	if ai_behavior == "trap_support" and unit.unit_id == "imp":
		var support_point = root.graph.center("spike_corridor").lerp(root.graph.center(_barracks_room()), 0.58)
		move_unit_to_point(unit, support_point)
		unit.set_tactical_state(Constants.UNIT_STATE_SEEK_TARGET, "함정 화력 지원", "가시 복도")
		return
	if _entry_block_active() and unit.unit_id == "slime":
		var block_point = root.graph.center("entrance").lerp(root.graph.center("spike_corridor"), 0.55)
		move_unit_to_point(unit, block_point)
		unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "입구 봉쇄", "초크포인트")
		return

	if root.room_directives.get("spike_corridor", Constants.ROOM_DIRECTIVE_NONE) == Constants.ROOM_DIRECTIVE_TRAP_LURE:
		if priority_target != null and priority_target.current_room == unit.current_room:
			move_unit_to_point(unit, priority_target.global_position)
			unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET, "함정 유도 교전", priority_target.display_name)
			return
		if unit.unit_id == "imp":
			var rear_point = root.graph.center("spike_corridor").lerp(root.graph.center(_barracks_room()), 0.58)
			move_unit_to_point(unit, rear_point)
			unit.set_tactical_state(Constants.UNIT_STATE_SEEK_TARGET, "함정 뒤 화력 지원", "가시 복도")
			return
		if priority_target != null and priority_target.current_room in ["entrance", "spike_corridor", _barracks_room()]:
			move_unit_to_point(unit, _trap_lure_point(unit))
			unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "함정 유도", "가시 복도")
			return
	if root.global_directive == Constants.DIRECTIVE_ALL_OUT:
		var target = priority_target
		if target != null:
			if target.current_room == unit.current_room:
				move_unit_to_point(unit, target.global_position)
			else:
				move_unit_to_room(unit, target.current_room)
			unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET, "총공격", target.display_name)
			return
	var nearby = _defense_target(unit, priority_target)
	if nearby != null:
		if nearby.current_room == unit.current_room:
			move_unit_to_point(unit, nearby.global_position)
		else:
			move_unit_to_room(unit, nearby.current_room)
		unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET, "방어 교전", nearby.display_name)
	elif unit.current_room != unit.assigned_room:
		move_unit_to_room(unit, unit.assigned_room)
		unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "배치 방 복귀", _room_name(unit.assigned_room))
	else:
		unit.set_tactical_state(Constants.UNIT_STATE_IDLE, "배치 방 사수", _room_name(unit.assigned_room))


func _run_monster_behavior(unit: Node) -> bool:
	var behavior_id := str(DataRegistry.monster(str(unit.unit_id)).get("behavior_handler", ""))
	match behavior_id:
		"rescue_support":
			return try_bebe_auto_rescue(unit)
		"danger_tracker":
			return _update_danger_tracker(unit)
		"armor_support":
			return _update_armor_support(unit)
	return false


func try_auto_monster_skill(unit: Node) -> bool:
	if unit == null or not is_instance_valid(unit) or not unit.is_alive():
		return false
	if unit.has_method("active_skills_locked") and unit.active_skills_locked():
		return false
	if unit.has_method("duo_action_locked") and unit.duo_action_locked():
		return false
	var next_decision := float(unit.get_meta("auto_skill_next_time", 0.0))
	if root.combat_time < next_decision:
		return false
	unit.set_meta("auto_skill_next_time", root.combat_time + AUTO_SKILL_DECISION_INTERVAL)
	var skill_slots: Array = DataRegistry.monster(str(unit.unit_id)).get("skill_slots", [])
	var ordered_slots: Array[int] = []
	for slot in range(skill_slots.size()):
		if skill_slots[slot] != null:
			ordered_slots.append(slot)
	ordered_slots.sort_custom(func(a: int, b: int) -> bool:
		var a_priority := _auto_skill_priority(str(skill_slots[a]))
		var b_priority := _auto_skill_priority(str(skill_slots[b]))
		return a_priority < b_priority if a_priority != b_priority else a < b
	)
	for slot in ordered_slots:
		var skill_id := str(skill_slots[slot])
		if skill_id in SPECIALIZED_AUTO_SKILLS or not unit.skill_ready(skill_id):
			continue
		if not _auto_skill_condition(unit, skill_id) or not _auto_skill_mana_allowed(unit, skill_id):
			continue
		if use_unit_skill_for_ai(unit, slot):
			if skill_id in AUTO_SKILL_REWARD:
				unit.set_meta("auto_skill_once_%s" % skill_id, true)
			return true
	return false


func _auto_skill_priority(skill_id: String) -> int:
	var category := 3
	if skill_id in AUTO_SKILL_DEFENSIVE:
		category = 0
	elif skill_id in AUTO_SKILL_CONTROL:
		category = 1
	elif skill_id in AUTO_SKILL_OFFENSIVE:
		category = 2
	elif skill_id in AUTO_SKILL_REWARD:
		category = 3
	match root.global_directive:
		Constants.DIRECTIVE_ALL_OUT:
			return {2: 0, 1: 1, 0: 2, 3: 3}.get(category, 4)
		Constants.DIRECTIVE_SURVIVAL:
			return {0: 0, 1: 1, 2: 2, 3: 3}.get(category, 4)
		_:
			return {0: 0, 1: 1, 2: 2, 3: 3}.get(category, 4)


func _auto_skill_condition(unit: Node, skill_id: String) -> bool:
	var nearby_enemies := _auto_enemy_count_in_range(unit, 280.0)
	var lowest_ally_ratio := _auto_lowest_ally_hp_ratio(unit, false)
	var lowest_room_ally_ratio := _auto_lowest_ally_hp_ratio(unit, true)
	match skill_id:
		"slime_shield":
			return nearby_enemies > 0 and (root.global_directive != Constants.DIRECTIVE_ALL_OUT or float(unit.hp) / maxf(1.0, float(unit.max_hp)) <= 0.82 or lowest_ally_ratio <= 0.70)
		"hold_corridor":
			return root.global_directive == Constants.DIRECTIVE_DEFENSE and nearby_enemies > 0 and float(unit.guard_timer) <= 1.0
		"quick_slash":
			return TargetingService.nearest(unit, root.enemy_units, unit.attack_range + 38.0) != null
		"loot_instinct":
			return nearby_enemies > 0 and not bool(unit.loot_bonus_active)
		"fireball":
			var fire_range := 320.0 + _combat_skill_float(str(unit.unit_id), skill_id, "range_bonus", 0.0)
			return TargetingService.nearest(unit, root.enemy_units, fire_range) != null
		"flame_zone":
			return _flame_zone_targets().size() >= (1 if root.global_directive == Constants.DIRECTIVE_ALL_OUT else 2)
		"false_footprints":
			return _auto_enemy_count_in_range(unit, 260.0) >= (1 if root.global_directive == Constants.DIRECTIVE_SURVIVAL else 2)
		"rumor_boost":
			return nearby_enemies > 0 and not unit.has_meta("auto_skill_once_rumor_boost")
		"spore_mend":
			return lowest_ally_ratio <= 0.70
		"cleansing_bloom":
			return lowest_room_ally_ratio <= 0.82 or _auto_room_has_negative_status(unit)
		"rooted_guard":
			return nearby_enemies > 0 and float(unit.guard_timer) <= 1.0 and (root.global_directive == Constants.DIRECTIVE_DEFENSE or float(unit.hp) / maxf(1.0, float(unit.max_hp)) <= 0.78)
		"stone_pulse":
			return _auto_enemy_count_in_range(unit, 180.0) >= (1 if root.global_directive == Constants.DIRECTIVE_ALL_OUT else 2)
		"war_rhythm":
			return _auto_same_room_ally_count(unit) >= 2 and nearby_enemies > 0
		"steady_beat":
			return lowest_room_ally_ratio <= 0.78
		"moon_mark":
			return TargetingService.nearest(unit, root.enemy_units, 360.0) != null
		"scent_pursuit":
			return TargetingService.nearest(unit, root.enemy_units, 280.0) != null
		"false_treasure":
			return _auto_enemy_count_in_range(unit, 250.0) >= (1 if root.global_directive == Constants.DIRECTIVE_DEFENSE else 2)
		"vault_swap":
			return lowest_ally_ratio <= 0.50
		"haunted_broom_whirl":
			return _bebe_broom_targets(unit, 85.0).size() >= (1 if root.global_directive != Constants.DIRECTIVE_DEFENSE else 2)
	return false


func _auto_skill_mana_allowed(unit: Node, skill_id: String) -> bool:
	var skill: Dictionary = DataRegistry.skill(skill_id)
	var cost := int(root._current_skill_mana_cost(skill))
	if GameState.mana < cost:
		return false
	if cost <= 0:
		return true
	var emergency_support := skill_id in ["spore_mend", "cleansing_bloom", "steady_beat", "vault_swap"] and _auto_lowest_ally_hp_ratio(unit, false) <= 0.35
	if emergency_support:
		return true
	var reserve := 0
	if root.global_directive == Constants.DIRECTIVE_DEFENSE:
		reserve = 12
	elif root.global_directive == Constants.DIRECTIVE_SURVIVAL:
		reserve = 24
	return GameState.mana - cost >= reserve


func _auto_enemy_count_in_range(unit: Node, radius: float) -> int:
	var count := 0
	for enemy in root.enemy_units:
		if is_instance_valid(enemy) and enemy.is_alive() and unit.global_position.distance_to(enemy.global_position) <= radius:
			count += 1
	return count


func _auto_lowest_ally_hp_ratio(unit: Node, same_room_only: bool) -> float:
	var result := 1.0
	for ally in root.monster_units:
		if not is_instance_valid(ally) or not ally.is_alive():
			continue
		if same_room_only and str(ally.current_room) != str(unit.current_room):
			continue
		result = minf(result, float(ally.hp) / maxf(1.0, float(ally.max_hp)))
	return result


func _auto_same_room_ally_count(unit: Node) -> int:
	var count := 0
	for ally in root.monster_units:
		if is_instance_valid(ally) and ally.is_alive() and str(ally.current_room) == str(unit.current_room):
			count += 1
	return count


func _auto_room_has_negative_status(unit: Node) -> bool:
	for ally in root.monster_units:
		if not is_instance_valid(ally) or not ally.is_alive() or str(ally.current_room) != str(unit.current_room):
			continue
		if float(ally.slow_timer) > 0.0 or float(ally.seal_move_lock_timer) > 0.0 or float(ally.seal_skill_lock_timer) > 0.0:
			return true
	return false


func _update_armor_support(unit: Node) -> bool:
	var repair_room := _toktok_facility_repair_target(unit, true)
	if repair_room != "":
		if unit.skill_ready("patch_plates") and _toktok_facility_in_range(unit, repair_room):
			return _try_toktok_auto_skill(unit, "patch_plates", null, repair_room)
		move_unit_to_room(unit, repair_room)
		unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "긴급 시설 수리", _room_name(repair_room))
		return true
	var ram_target := _toktok_ram_target(unit)
	if ram_target == null:
		return false
	if unit.skill_ready("carapace_ram") and unit.global_position.distance_to(ram_target.global_position) <= _toktok_ram_distance(unit):
		if _try_toktok_auto_skill(unit, "carapace_ram", ram_target):
			return true
	if str(ram_target.current_room) == str(unit.current_room):
		move_unit_to_point(unit, ram_target.global_position)
	else:
		move_unit_to_room(unit, str(ram_target.current_room))
	unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET, "단단한 적 파쇄", ram_target.display_name)
	return true


func _try_toktok_auto_skill(unit: Node, skill_id: String, target: Node = null, room_id: String = "") -> bool:
	var skill: Dictionary = DataRegistry.skill(skill_id)
	var cost := int(skill.get("cost_mana", 0))
	if GameState.mana < cost or unit.active_skills_locked():
		return false
	var result: Dictionary
	if skill_id == "carapace_ram":
		result = perform_toktok_carapace_ram(unit, target)
	else:
		result = perform_toktok_patch_plates(unit, null, room_id)
	if not bool(result.get("ok", false)):
		return false
	GameState.mana -= cost
	SignalBus.resources_changed.emit()
	_play_skill_sfx(skill_id)
	unit.set_skill_cooldown(skill_id, float(skill.get("cooldown", 0.0)))
	record_ledger_skill_use(unit, skill_id)
	return true


func _toktok_ram_target(unit: Node) -> Node:
	var priority_ids: Array = DataRegistry.monster(str(unit.unit_id)).get("priority_enemy_ids", [])
	var selected: Node = null
	var selected_score := -INF
	for enemy in root.enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive():
			continue
		var index := priority_ids.find(str(enemy.unit_id))
		var priority_bonus := 1000.0 - float(index * 20) if index >= 0 else 0.0
		var score: float = priority_bonus - unit.global_position.distance_to(enemy.global_position)
		if score > selected_score:
			selected_score = score
			selected = enemy
	return selected


func _toktok_ram_distance(unit: Node) -> float:
	var base := float(DataRegistry.skill("carapace_ram").get("max_distance", 110.0))
	return maxf(25.0, base - _combat_skill_float(str(unit.unit_id), "carapace_ram", "distance_penalty", 0.0))


func _toktok_facility_repair_target(unit: Node, critical_only: bool = false) -> String:
	if not critical_only and unit.has_meta("patch_facility_target"):
		var commanded_room := str(unit.get_meta("patch_facility_target", ""))
		if commanded_room != "" and root.rooms.has(commanded_room):
			var commanded: Dictionary = root.rooms[commanded_room]
			var commanded_max := int(commanded.get("max_hp", commanded.get("hp", 0)))
			if int(commanded.get("hp", commanded_max)) < commanded_max:
				return commanded_room
		unit.remove_meta("patch_facility_target")
	var selected_room := str(root.selected_room) if not critical_only else ""
	var best_room := ""
	var best_score := -INF
	for room_id_value in root.rooms.keys():
		var room_id := str(room_id_value)
		var room: Dictionary = root.rooms[room_id]
		var role := str(room.get("facility_role", ""))
		if role in ["", "entry", "trap", "corridor", "core", "build_slot"]:
			continue
		var maximum := int(room.get("max_hp", room.get("hp", 0)))
		var current := int(room.get("hp", maximum))
		if maximum <= 0 or current >= maximum:
			continue
		var ratio := float(current) / float(maximum)
		var threshold := 0.35 if role == "heart_chamber" else 0.45
		if critical_only and ratio > threshold:
			continue
		var selected_bonus := 5000.0 if room_id == selected_room else 0.0
		var heart_bonus := 3000.0 if role == "heart_chamber" and ratio <= 0.35 else 0.0
		var critical_bonus := 1500.0 if ratio <= threshold else 0.0
		var distance: float = unit.global_position.distance_to(root.graph.center(room_id)) if root.graph != null else 0.0
		var score: float = selected_bonus + heart_bonus + critical_bonus + (1.0 - ratio) * 1000.0 - distance * 0.01
		if score > best_score:
			best_score = score
			best_room = room_id
	return best_room


func _toktok_facility_in_range(unit: Node, room_id: String) -> bool:
	if room_id == "" or not root.rooms.has(room_id):
		return false
	if str(unit.current_room) == room_id:
		return true
	if root.graph == null:
		return false
	return unit.global_position.distance_to(root.graph.center(room_id)) <= float(DataRegistry.skill("patch_plates").get("range", 120.0))


func _update_danger_tracker(unit: Node) -> bool:
	if unit.return_scent_timer > 0.0:
		if str(unit.current_room) == str(unit.assigned_room):
			unit.end_return_scent()
			unit.stop_navigation()
			unit.set_tactical_state(Constants.UNIT_STATE_IDLE, "복귀 완료", _room_name(unit.assigned_room))
			return true
		move_unit_to_room(unit, str(unit.assigned_room))
		unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "돌아가는 냄새", _room_name(unit.assigned_room))
		return true
	if unit.scent_mark_target != null and not unit.has_active_scent_mark():
		_begin_tracker_return(unit)
		return true
	var target := _danger_tracker_target(unit)
	if target == null:
		return false
	if unit.skill_ready("home_guard_bark") and _tracker_bark_candidate_count(unit) >= 2:
		_try_koko_auto_skill(unit, "home_guard_bark", target)
	if target != unit.scent_mark_target and unit.skill_ready("scent_lock"):
		_try_koko_auto_skill(unit, "scent_lock", target)
	unit.scent_tracking_active = unit.has_active_scent_mark() and unit.scent_mark_target == target
	if str(target.current_room) == str(unit.current_room):
		move_unit_to_point(unit, target.global_position)
	else:
		move_unit_to_room(unit, str(target.current_room))
	unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET, _danger_tracker_intent(unit, target), target.display_name)
	return true


func _danger_tracker_target(unit: Node) -> Node:
	var stolen_thief: Node = null
	for enemy in root.enemy_units:
		if is_instance_valid(enemy) and enemy.is_alive() and str(enemy.unit_id) == "thief" and float(root.thief_steal_timers.get(enemy, 0.0)) < -100.0:
			stolen_thief = enemy
			break
	if stolen_thief != null:
		return stolen_thief
	var home_intruders := _living_enemies_in_room(str(unit.assigned_room))
	if not home_intruders.is_empty():
		return TargetingService.nearest(unit, home_intruders)
	var throne_intruders := _living_enemies_in_room(_core_room())
	if not throne_intruders.is_empty() and (not unit.has_active_scent_mark() or not _bebe_broom_boss(unit.scent_mark_target)):
		return TargetingService.nearest(unit, throne_intruders)
	if unit.has_active_scent_mark():
		return unit.scent_mark_target
	var monster_data: Dictionary = DataRegistry.monster(str(unit.unit_id))
	var priority_ids: Array = monster_data.get("priority_enemy_ids", [])
	var selected: Node = null
	var selected_score := -INF
	for enemy in root.enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive():
			continue
		var index := priority_ids.find(str(enemy.unit_id))
		var role_bonus := 500.0 if str(enemy.role) in ["facility", "caster", "bounty"] else 0.0
		var id_bonus := 1000.0 - float(index * 10) if index >= 0 else 0.0
		var score: float = id_bonus + role_bonus - unit.global_position.distance_to(enemy.global_position) / 1000.0
		if score > selected_score:
			selected_score = score
			selected = enemy
	return selected


func _living_enemies_in_room(room_id: String) -> Array:
	var result: Array = []
	for enemy in root.enemy_units:
		if is_instance_valid(enemy) and enemy.is_alive() and str(enemy.current_room) == room_id:
			result.append(enemy)
	return result


func _danger_tracker_intent(unit: Node, target: Node) -> String:
	if str(target.unit_id) == "thief" and float(root.thief_steal_timers.get(target, 0.0)) < -100.0:
		return "도둑 탈출 추격"
	if str(target.current_room) == _core_room():
		return "왕좌 긴급 방어"
	if str(target.current_room) == str(unit.assigned_room) and target != unit.scent_mark_target:
		return "배치 방 긴급 방어"
	return "위험 냄새 추적"


func _tracker_bark_candidate_count(unit: Node) -> int:
	var radius := float(DataRegistry.skill("home_guard_bark").get("radius", 145.0))
	var count := 0
	for enemy in root.enemy_units:
		if is_instance_valid(enemy) and enemy.is_alive() and unit.global_position.distance_to(enemy.global_position) <= radius:
			count += 1
	return count


func _try_koko_auto_skill(unit: Node, skill_id: String, target: Node = null) -> bool:
	var skill: Dictionary = DataRegistry.skill(skill_id)
	var cost := int(skill.get("cost_mana", 0))
	if GameState.mana < cost or unit.active_skills_locked():
		return false
	GameState.mana -= cost
	SignalBus.resources_changed.emit()
	var result: Dictionary = perform_koko_scent_lock(unit, target) if skill_id == "scent_lock" else perform_koko_home_guard_bark(unit)
	if not bool(result.get("ok", false)):
		GameState.mana += cost
		SignalBus.resources_changed.emit()
		return false
	_play_skill_sfx(skill_id)
	unit.set_skill_cooldown(skill_id, float(skill.get("cooldown", 0.0)))
	record_ledger_skill_use(unit, skill_id)
	return true


func _begin_tracker_return(unit: Node) -> void:
	var passive: Dictionary = DataRegistry.skill("return_scent")
	unit.begin_return_scent(float(passive.get("duration", 4.0)), float(passive.get("return_move_multiplier", 1.35)), float(passive.get("damage_reduction", 0.08)))
	move_unit_to_room(unit, str(unit.assigned_room))
	unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "돌아가는 냄새", _room_name(unit.assigned_room))
	spawn_effect_burst("koko_return", unit.global_position, Vector2(0, -16), Vector2(1.0, 0.8), 12.0)
	root._log("%s가 표식 추적을 마치고 배치 방으로 복귀합니다." % unit.display_name)

func update_enemy_path(unit: Node) -> void:
	var treasure_room = _treasure_room()
	var core_room = _core_room()
	if float(unit.purifying_hymn_cast_timer) > 0.0:
		unit.stop_navigation()
		unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "정화 성가", "시전 중")
		return
	if float(unit.ledger_mark_cast_timer) > 0.0:
		unit.stop_navigation()
		unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "부채 표식", "예고 중")
		return
	if root.has_method("_update3_false_corridor_holds") and root._update3_false_corridor_holds(unit):
		return
	if _run_enemy_behavior(unit):
		return
	if _hero_skills_enabled() and _is_hero_unit(unit) and _run_hero_skill(unit):
		return
	if unit.unit_id == "roman" and _try_roman_supply_command(unit):
		return
	if unit.unit_id == "engineer" and _update_engineer_path(unit):
		return
	if _update_v20_defense_checkpoint(unit):
		return
	if unit.unit_id == "thief" and float(root.thief_steal_timers.get(unit, 0.0)) < -100.0:
		if unit.current_room != "entrance":
			move_unit_to_room(unit, "entrance")
			unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "보물 탈출", _room_name("entrance"))
		return
	if unit.unit_id == "thief" and treasure_room != "" and unit.current_room == treasure_room:
		unit.set_tactical_state(Constants.UNIT_STATE_LOOTING, "보물 약탈", "금화")
		return
	if unit.unit_id == "thief" and treasure_room != "" and unit.threat_unit != null and unit.current_room != treasure_room:
		move_unit_to_room(unit, treasure_room)
		unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "피격 후 침투", _room_name(treasure_room))
		return
	var monster_target = nearest_monster_in_rooms(unit, [unit.current_room])
	if monster_target != null:
		if _hold_attack_position(unit, monster_target):
			return
		move_unit_to_point(unit, monster_target.global_position, true)
		unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET, "교전", monster_target.display_name)
		return
	if unit.current_room == unit.goal_room:
		if unit.goal_room == core_room:
			unit.set_tactical_state(Constants.UNIT_STATE_ATTACK, "왕좌 압박", _room_name(core_room))
		elif unit.goal_room == "heart_chamber":
			unit.set_tactical_state(Constants.UNIT_STATE_ATTACK, "심장 압박", _room_name("heart_chamber"))
		return
	move_unit_to_room(unit, unit.goal_room)
	unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "목표 방 이동", _room_name(unit.goal_room))


func _initialize_v20_defense_checkpoints(unit: Node, route_nodes: Array) -> void:
	var checkpoints := _v20_runtime_checkpoints(route_nodes)
	if checkpoints.is_empty():
		return
	unit.set_meta("v20_runtime_checkpoints", checkpoints)
	unit.set_meta("v20_checkpoint_index", 0)
	unit.set_meta("v20_checkpoint_wait_remaining", -1.0)
	unit.set_meta("v20_checkpoint_final_goal", str(unit.goal_room))
	unit.set_meta("v20_checkpoint_complete", false)
	unit.goal_room = str(checkpoints[0])
	unit.set_path(_path_from_world_to_room(unit.global_position, unit.goal_room))


func _v20_runtime_checkpoints(route_nodes: Array) -> Array[String]:
	var checkpoints: Array[String] = []
	for route_node_value in route_nodes:
		var runtime_room := _v20_runtime_room(str(route_node_value))
		if runtime_room == "" or not root.rooms.has(runtime_room) or checkpoints.has(runtime_room):
			continue
		checkpoints.append(runtime_room)
	return checkpoints


func _advance_v20_checkpoint_waits(delta: float) -> void:
	if delta <= 0.0:
		return
	for unit in root.enemy_units:
		if not is_instance_valid(unit) or not unit.is_alive() or bool(unit.get_meta("v20_checkpoint_complete", false)):
			continue
		var remaining := float(unit.get_meta("v20_checkpoint_wait_remaining", -1.0))
		if remaining > 0.0:
			unit.set_meta("v20_checkpoint_wait_remaining", maxf(0.0, remaining - delta))


func _update_v20_defense_checkpoint(unit: Node) -> bool:
	if bool(unit.get_meta("v20_checkpoint_complete", false)):
		return false
	var checkpoints: Array = unit.get_meta("v20_runtime_checkpoints", [])
	if checkpoints.is_empty():
		return false
	var checkpoint_index := clampi(int(unit.get_meta("v20_checkpoint_index", 0)), 0, checkpoints.size() - 1)
	var checkpoint_room := str(checkpoints[checkpoint_index])
	var stage_label := "방어선 %d/%d" % [checkpoint_index + 1, checkpoints.size()]
	if str(unit.current_room) != checkpoint_room:
		move_unit_to_room(unit, checkpoint_room)
		unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "%s 진입" % stage_label, _room_name(checkpoint_room))
		return true
	var defender := nearest_monster_in_rooms(unit, [checkpoint_room])
	if defender != null:
		unit.set_meta("v20_checkpoint_wait_remaining", -1.0)
		if not _hold_attack_position(unit, defender):
			move_unit_to_point(unit, defender.global_position, true)
			unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET, "%s 교전" % stage_label, defender.display_name)
		return true
	if checkpoint_index >= checkpoints.size() - 1:
		_complete_v20_defense_checkpoints(unit)
		return false
	var wait_remaining := float(unit.get_meta("v20_checkpoint_wait_remaining", -1.0))
	if wait_remaining < 0.0:
		wait_remaining = V20_CHECKPOINT_BREACH_SECONDS
		unit.set_meta("v20_checkpoint_wait_remaining", wait_remaining)
	if wait_remaining > 0.0:
		unit.stop_navigation()
		unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "%s 관문 돌파 %.1f초" % [stage_label, wait_remaining], _room_name(checkpoint_room))
		return true
	checkpoint_index += 1
	unit.set_meta("v20_checkpoint_index", checkpoint_index)
	unit.set_meta("v20_checkpoint_wait_remaining", -1.0)
	var next_checkpoint := str(checkpoints[checkpoint_index])
	move_unit_to_room(unit, next_checkpoint)
	unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "방어선 %d/%d 진입" % [checkpoint_index + 1, checkpoints.size()], _room_name(next_checkpoint))
	return true


func _complete_v20_defense_checkpoints(unit: Node) -> void:
	unit.set_meta("v20_checkpoint_complete", true)
	unit.set_meta("v20_checkpoint_wait_remaining", 0.0)
	var final_goal := str(unit.get_meta("v20_checkpoint_final_goal", unit.goal_room))
	if final_goal == "" or not root.rooms.has(final_goal):
		var checkpoints: Array = unit.get_meta("v20_runtime_checkpoints", [])
		final_goal = str(checkpoints[-1]) if not checkpoints.is_empty() else str(unit.current_room)
	unit.goal_room = final_goal
	if str(unit.current_room) == final_goal:
		unit.stop_navigation()
	else:
		unit.set_path(_path_from_world_to_room(unit.global_position, final_goal))


func v20_defense_stage_snapshot() -> Dictionary:
	var enemies: Array[Dictionary] = []
	for unit in root.enemy_units:
		if not is_instance_valid(unit) or not unit.is_alive() or not unit.has_meta("v20_runtime_checkpoints"):
			continue
		var checkpoints: Array = unit.get_meta("v20_runtime_checkpoints", [])
		var checkpoint_index := clampi(int(unit.get_meta("v20_checkpoint_index", 0)), 0, maxi(0, checkpoints.size() - 1))
		enemies.append({
			"unit_id": str(unit.unit_id),
			"instance_id": unit.get_instance_id(),
			"checkpoints": checkpoints.duplicate(),
			"checkpoint_index": checkpoint_index,
			"checkpoint_room": str(checkpoints[checkpoint_index]) if not checkpoints.is_empty() else "",
			"current_room": str(unit.current_room),
			"wait_remaining": maxf(0.0, float(unit.get_meta("v20_checkpoint_wait_remaining", 0.0))),
			"final_goal": str(unit.get_meta("v20_checkpoint_final_goal", unit.goal_room)),
			"complete": bool(unit.get_meta("v20_checkpoint_complete", false))
		})
	return {
		"breach_seconds": V20_CHECKPOINT_BREACH_SECONDS,
		"enemies": enemies
	}


func v20_defense_stage_hud_state() -> Dictionary:
	var definitions: Array[Dictionary] = [
		{"id": "north_gate", "room_id": "entrance", "label": "1차 · 성문 전초"},
		{"id": "south_gate", "room_id": "spike_corridor", "label": "2차 · 가시 회랑"},
		{"id": "treasure", "room_id": "barracks", "label": "3차 · 중앙 전투실"},
		{"id": "fallback", "room_id": "fallback", "label": "4차 · 왕좌 전실"}
	]
	var snapshot := v20_defense_stage_snapshot()
	var enemy_rows: Array = snapshot.get("enemies", [])
	var deepest_stage := -1
	for enemy_value in enemy_rows:
		var enemy: Dictionary = enemy_value
		var enemy_stage := int(enemy.get("checkpoint_index", 0))
		if bool(enemy.get("complete", false)):
			enemy_stage = definitions.size()
		deepest_stage = maxi(deepest_stage, enemy_stage)
	var stages: Array[Dictionary] = []
	for index in range(definitions.size()):
		var definition := definitions[index]
		var room_id := str(definition.get("room_id", ""))
		var enemy_count := 0
		var defender_count := 0
		var progressed := false
		var breaching := false
		for enemy_value in enemy_rows:
			var enemy: Dictionary = enemy_value
			var enemy_stage := int(enemy.get("checkpoint_index", 0))
			if bool(enemy.get("complete", false)) or enemy_stage > index:
				progressed = true
			elif enemy_stage == index:
				enemy_count += 1
				breaching = breaching or float(enemy.get("wait_remaining", 0.0)) > 0.0
		for monster in root.monster_units:
			if is_instance_valid(monster) and monster.is_alive() and str(monster.current_room) == room_id:
				defender_count += 1
		var is_active := enemy_count > 0 or (enemy_rows.is_empty() and index == 0)
		var status := "대기"
		if enemy_count > 0:
			if breaching:
				status = "돌파중"
			elif defender_count > 0:
				status = "교전 %d" % enemy_count
			else:
				status = "진입 %d" % enemy_count
		elif progressed:
			status = "돌파"
		elif enemy_rows.is_empty() and index == 0:
			status = "준비"
		var stage := definition.duplicate(true)
		stage["status"] = status
		stage["active"] = is_active
		stage["enemy_count"] = enemy_count
		stage["defender_count"] = defender_count
		stage["facility_label"] = _v20_stage_facility_label(room_id)
		stages.append(stage)
	var active_stage_label := "1차 · 성문 전초"
	if deepest_stage >= definitions.size():
		active_stage_label = "왕좌 진입 위험"
	elif deepest_stage >= 0:
		active_stage_label = str(definitions[deepest_stage].get("label", active_stage_label))
	return {
		"active_stage_label": active_stage_label,
		"defense_stages": stages
	}


func _v20_stage_facility_label(room_id: String) -> String:
	var facility_role := str(root.rooms.get(room_id, {}).get("facility_role", "v20_empty"))
	return str({
		"v20_barricade": "바리케이드",
		"barracks": "병영",
		"treasure": "미끼 보물",
		"watch_post": "감시 초소",
		"recovery": "회복 둥지",
		"v20_empty": "시설 없음"
	}.get(facility_role, "시설 없음"))


func _run_enemy_behavior(unit: Node) -> bool:
	var behavior_handler := str(DataRegistry.enemy(str(unit.unit_id)).get("behavior_handler", ""))
	if behavior_handler != "bounty_tracker":
		return false
	var target := _bounty_combat_target(unit)
	if target == null:
		return false
	if str(target.current_room) == str(unit.current_room):
		if _hold_attack_position(unit, target):
			return true
		move_unit_to_point(unit, target.global_position, true)
	else:
		move_unit_to_room(unit, str(target.current_room))
	var intent := "도발 대상 교전" if target == unit.threat_unit else "현상금 추적"
	unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET, intent, target.display_name)
	return true

func nearest_enemy_in_rooms(unit: Node, room_ids: Array) -> Node:
	var candidates: Array = []
	for enemy in root.enemy_units:
		if enemy.is_alive() and room_ids.has(enemy.current_room):
			candidates.append(enemy)
	return TargetingService.nearest(unit, candidates)

func nearest_monster_in_rooms(unit: Node, room_ids: Array) -> Node:
	var candidates: Array = []
	for monster in root.monster_units:
		if monster.is_alive() and room_ids.has(monster.current_room):
			candidates.append(monster)
	return TargetingService.nearest(unit, candidates)

func _defense_target(unit: Node, priority_target: Node) -> Node:
	if priority_target == null:
		return null
	var anchor_room = str(unit.assigned_room)
	if anchor_room == "" or not root.rooms.has(anchor_room):
		anchor_room = str(unit.current_room)
	var allowed_rooms = [anchor_room, unit.current_room]
	for room_id in root.graph.exits(anchor_room):
		if not allowed_rooms.has(room_id):
			allowed_rooms.append(room_id)
	if root.global_directive == Constants.DIRECTIVE_DEFENSE and not allowed_rooms.has(priority_target.current_room):
		var pressured_ally = _most_wounded_ally(unit)
		if pressured_ally != null and pressured_ally.current_room == priority_target.current_room:
			return priority_target
		return null
	return priority_target

func _monster_ai_behavior(unit: Node) -> String:
	if root.has_method("_monster_ai_behavior"):
		return root._monster_ai_behavior(str(unit.unit_id))
	return ""

func _sync_unit_simulation_speed() -> void:
	for unit in root.monster_units + root.enemy_units:
		if is_instance_valid(unit) and unit.has_method("set_simulation_speed"):
			unit.set_simulation_speed(root.combat_speed)

func _specialization_priority_target(unit: Node, fallback: Node) -> Node:
	if _v20_roles_active():
		var focused_id := str(root.get_meta("v20_focused_target_id", ""))
		if focused_id != "":
			for enemy in root.enemy_units:
				if is_instance_valid(enemy) and enemy.is_alive() and str(enemy.get_instance_id()) == focused_id:
					return enemy
	var v20_target := _v20_role_priority_target(unit)
	if v20_target != null:
		return v20_target
	match _monster_ai_behavior(unit):
		"thief_hunter":
			var thieves: Array = []
			for enemy in root.enemy_units:
				if enemy.is_alive() and enemy.unit_id == "thief":
					thieves.append(enemy)
			var thief_target = TargetingService.nearest(unit, thieves)
			if thief_target != null:
				return thief_target
		"wounded_hunter":
			var wounded_enemy: Node = null
			var lowest_ratio := 2.0
			for enemy in root.enemy_units:
				if not enemy.is_alive():
					continue
				var hp_ratio = float(enemy.hp) / float(max(1, enemy.max_hp))
				if hp_ratio < lowest_ratio:
					lowest_ratio = hp_ratio
					wounded_enemy = enemy
			if wounded_enemy != null:
				return wounded_enemy
		"vault_guard":
			var vault_room := _treasure_room()
			var vault_targets: Array = []
			for enemy in root.enemy_units:
				if enemy.is_alive() and (enemy.current_room == vault_room or str(enemy.goal_room) == vault_room):
					vault_targets.append(enemy)
			var vault_target = TargetingService.nearest(unit, vault_targets)
			if vault_target != null:
				return vault_target
	return fallback


func _v20_roles_active() -> bool:
	return root != null and root.has_method("_v20_vertical_slice_active") and root._v20_vertical_slice_active()


func _v20_specialization_id(unit: Node) -> String:
	if unit == null or root == null or not root.monster_roster.has(str(unit.unit_id)):
		return ""
	return str(root.monster_roster.get(str(unit.unit_id), {}).get("specialization_id", ""))


func _v20_role_priority_target(unit: Node) -> Node:
	if not _v20_roles_active():
		return null
	var specialization_id := _v20_specialization_id(unit)
	if specialization_id == "":
		return null
	var plan := V20MonsterRoleService.plan_turn(specialization_id, _v20_role_context(unit), DataRegistry.specializations)
	var target_id := str(plan.get("target", {}).get("id", ""))
	for enemy in root.enemy_units:
		if is_instance_valid(enemy) and str(enemy.get_instance_id()) == target_id:
			return enemy
	return null


func _apply_v20_role_movement(unit: Node, priority_target: Node) -> bool:
	if not _v20_roles_active():
		return false
	var specialization_id := _v20_specialization_id(unit)
	if specialization_id == "":
		return false
	var context := _v20_role_context(unit)
	var movement_command := _v20_movement_command_for_unit(unit)
	if priority_target != null and is_instance_valid(priority_target):
		context["focused_target_id"] = str(priority_target.get_instance_id()) if str(root.get_meta("v20_focused_target_id", "")) != "" else ""
	var plan := V20MonsterRoleService.plan_turn(specialization_id, context, DataRegistry.specializations)
	var anchor_node := str(movement_command.get("target", {}).get("id", "")) if not movement_command.is_empty() else str(plan.get("movement", {}).get("anchor_node", ""))
	anchor_node = _v20_runtime_room(anchor_node)
	if movement_command.is_empty() and priority_target != null and is_instance_valid(priority_target) and str(priority_target.current_room) == str(unit.current_room):
		return false
	if anchor_node == "" or anchor_node == str(unit.current_room) or not root.rooms.has(anchor_node):
		return false
	move_unit_to_room(unit, anchor_node)
	var movement_reason := str(DataRegistry.v20_commands.get(str(movement_command.get("command_id", "")), {}).get("display_name", "")) if not movement_command.is_empty() else str(plan.get("movement", {}).get("reason", "역할 이동"))
	unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, movement_reason, _room_name(anchor_node))
	v20_role_result_state = V20MonsterRoleService.record_decision(v20_role_result_state, specialization_id)
	if not movement_command.is_empty():
		var metric_id := "units_retreated" if str(movement_command.get("command_id", "")) == "v20_emergency_fallback" else "units_repositioned"
		var command_token := "%s:%d" % [str(movement_command.get("command_id", "")), v20_command_state.get("history", []).size()]
		if str(unit.get_meta("v20_command_move_recorded", "")) != command_token:
			unit.set_meta("v20_command_move_recorded", command_token)
			_record_v20_command_metric(str(movement_command.get("command_id", "")), metric_id, 1.0)
	if int(plan.get("facility_synergy", {}).get("score", 0)) > 0:
		var metric_result := V20MonsterRoleService.record_metric(v20_role_result_state, specialization_id, "facility_synergy_events", 1.0)
		if bool(metric_result.get("ok", false)):
			v20_role_result_state = metric_result.get("state", v20_role_result_state)
	return true


func _v20_role_context(unit: Node) -> Dictionary:
	var allies: Array[Dictionary] = []
	for ally in root.monster_units:
		if is_instance_valid(ally) and ally.is_alive():
			allies.append({"id": str(ally.get_instance_id()), "node_id": str(ally.current_room), "hp": int(ally.hp), "max_hp": int(ally.max_hp)})
	var enemies: Array[Dictionary] = []
	for enemy in root.enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive():
			continue
		var definition: Dictionary = DataRegistry.enemy(str(enemy.unit_id))
		var tags: Array = definition.get("tags", []).duplicate()
		if not tags.has(str(enemy.unit_id)):
			tags.append(str(enemy.unit_id))
		if str(enemy.unit_id) == "thief" and not tags.has("thief"):
			tags.append("thief")
		enemies.append({
			"id": str(enemy.get_instance_id()),
			"node_id": str(enemy.current_room),
			"hp": int(enemy.hp),
			"max_hp": int(enemy.max_hp),
			"distance": unit.global_position.distance_to(enemy.global_position),
			"threat": float(definition.get("threat", 1.0)),
			"cluster_size": _living_enemies_in_room(str(enemy.current_room)).size(),
			"tags": tags
		})
	return {
		"current_node": str(unit.current_room),
		"manual_anchor_node": str(unit.assigned_room),
		"seed": int(root.get_meta("v20_seed", 0)),
		"allies": allies,
		"enemies": enemies,
		"facilities": _v20_runtime_facilities(),
		"hazards": [{"node_id": "spike_corridor", "active": root.rooms.has("spike_corridor")}],
		"focused_target_id": str(root.get_meta("v20_focused_target_id", "")),
		"command_id": _v20_active_command_id_for_unit(unit)
	}


func _v20_runtime_facilities() -> Array[Dictionary]:
	if root != null and root.has_method("_v20_runtime_facilities"):
		var session_facilities: Array[Dictionary] = root._v20_runtime_facilities()
		if not session_facilities.is_empty():
			return session_facilities
	var role_map := {
		"barracks": "v20_barracks",
		"treasure": "v20_decoy_treasure",
		"watch_post": "v20_watch_post",
		"recovery": "v20_recovery_nest",
		"trap": "v20_barricade"
	}
	var result: Array[Dictionary] = []
	for room_id_value in root.rooms.keys():
		var room_id := str(room_id_value)
		var facility_role := str(root.rooms.get(room_id, {}).get("facility_role", root.rooms.get(room_id, {}).get("type", "")))
		if not role_map.has(facility_role):
			continue
		var active := true
		if root.has_method("_facility_room_is_active"):
			active = root._facility_room_is_active(room_id)
		result.append({"id": room_id, "facility_id": str(role_map.get(facility_role, "")), "node_id": room_id, "active": active})
	return result


func _new_v20_role_result_state() -> Dictionary:
	if not _v20_roles_active():
		return {}
	var specialization_ids: Array[String] = []
	for monster_id_value in root.monster_roster.keys():
		var specialization_id := str(root.monster_roster.get(str(monster_id_value), {}).get("specialization_id", ""))
		if specialization_id != "":
			specialization_ids.append(specialization_id)
	return V20MonsterRoleService.new_result_state(specialization_ids, DataRegistry.specializations)


func _new_v20_facility_state() -> Dictionary:
	var placements: Dictionary = {}
	for facility_value in _v20_runtime_facilities():
		var facility: Dictionary = facility_value
		placements[str(facility.get("id", ""))] = {
			"facility_id": str(facility.get("facility_id", "")),
			"room_id": str(facility.get("node_id", "")),
			"slot_id": str(facility.get("slot_id", facility.get("id", ""))),
			"edge_id": str(facility.get("edge_id", ""))
		}
	return V20FacilityService.new_battle_state(placements, DataRegistry.v20_facilities)


func _issue_v20_command(command_id: String) -> void:
	if not _v20_roles_active():
		return
	var definition: Dictionary = DataRegistry.v20_commands.get(command_id, {})
	var target := _v20_command_target(str(definition.get("target_type", "")))
	_issue_v20_command_with_target(command_id, target)


func _issue_v20_command_with_target(command_id: String, target: Dictionary) -> void:
	if not _v20_roles_active():
		return
	var definition: Dictionary = DataRegistry.v20_commands.get(command_id, {})
	var issued := V20CommandService.issue(v20_command_state, command_id, target, DataRegistry.v20_commands, v20_facility_state, DataRegistry.v20_facilities)
	if not bool(issued.get("ok", false)):
		root._log("전술 명령 실패: %s" % str(issued.get("error", "사용할 수 없습니다.")))
		_show_v20_command_feedback(str(issued.get("error", "사용할 수 없습니다.")), false)
		_refresh_v20_command_hud(true)
		return
	v20_command_state = issued.get("state", v20_command_state)
	v20_facility_state = issued.get("facility_state", v20_facility_state)
	_record_v20_encounter_response(command_id)
	_sync_v20_command_runtime()
	root._log("전술 명령 · %s: %s" % [str(definition.get("display_name", command_id)), str(target.get("label", target.get("id", "")))])
	_show_v20_command_feedback("%s · %s · 실행" % [str(definition.get("display_name", command_id)), str(target.get("label", target.get("id", "")))], true)
	_refresh_v20_command_hud(true)


func _v20_command_target(target_type: String) -> Dictionary:
	match target_type:
		"enemy":
			if root.selected_unit != null and is_instance_valid(root.selected_unit) and root.enemy_units.has(root.selected_unit):
				return {"type": "enemy", "id": str(root.selected_unit.get_instance_id()), "room_id": str(root.selected_unit.current_room), "label": str(root.selected_unit.display_name)}
		"facility":
			var selected_room := str(root.selected_room)
			if v20_facility_state.get("facilities", {}).has(selected_room):
				return {"type": "facility", "id": selected_room, "room_id": selected_room, "label": _room_name(selected_room)}
			var facility_ids: Array = v20_facility_state.get("facilities", {}).keys()
			facility_ids.sort()
			if not facility_ids.is_empty():
				var facility_id := str(facility_ids[0])
				var facility: Dictionary = v20_facility_state.get("facilities", {}).get(facility_id, {})
				return {"type": "facility", "id": facility_id, "room_id": str(facility.get("room_id", facility_id)), "label": str(DataRegistry.v20_facilities.get(str(facility.get("facility_id", "")), {}).get("display_name", facility_id))}
		"room":
			var selected_room := str(root.selected_room)
			if root.rooms.has(selected_room):
				return {"type": "room", "id": selected_room, "label": _room_name(selected_room)}
	return {"type": target_type, "id": ""}


func _v20_runtime_room(node_id: String) -> String:
	var route_aliases := {
		"north_gate": "entrance",
		"north_cross": "spike_corridor",
		"south_gate": "spike_corridor",
		"south_cross": "barracks",
		"treasure": "barracks",
		"fallback": "fallback"
	}
	if route_aliases.has(node_id):
		return str(route_aliases.get(node_id, node_id))
	return node_id


func _sync_v20_command_runtime() -> void:
	var focus := V20CommandService.active_effect(v20_command_state, "v20_focus")
	if focus.is_empty():
		if root.has_meta("v20_focused_target_id"):
			root.remove_meta("v20_focused_target_id")
	else:
		root.set_meta("v20_focused_target_id", str(focus.get("target", {}).get("id", "")))
	var movement_multiplier := 1.0
	for command_id in ["v20_rally", "v20_emergency_fallback"]:
		var active := V20CommandService.active_effect(v20_command_state, command_id)
		if not active.is_empty():
			movement_multiplier = maxf(movement_multiplier, float(active.get("effect", {}).get("move_speed_multiplier", 1.0)))
	for monster in root.monster_units:
		if not is_instance_valid(monster):
			continue
		if movement_multiplier > 1.0:
			monster.set_meta("v20_command_move_multiplier", movement_multiplier)
		elif monster.has_meta("v20_command_move_multiplier"):
			monster.remove_meta("v20_command_move_multiplier")


func _refresh_v20_command_hud_if_needed() -> void:
	var current_second := int(floor(float(v20_command_state.get("elapsed_seconds", 0.0))))
	if current_second != v20_command_ui_second:
		_refresh_v20_command_hud(false)


func _refresh_v20_command_hud(force: bool) -> void:
	v20_command_ui_second = int(floor(float(v20_command_state.get("elapsed_seconds", 0.0))))
	if v20_hud == null or not is_instance_valid(v20_hud):
		return
	if force or _v20_roles_active():
		v20_hud.set_encounter_status(V20EncounterService.hud_status(v20_encounter_state, v20_encounter_definition), false)
		v20_hud.set_command_state(V20CommandService.command_rows(v20_command_state, DataRegistry.v20_commands), int(v20_command_state.get("points", 0)), int(v20_command_state.get("max_points", 3)))
		v20_hud.set_defense_stage_state(v20_defense_stage_hud_state())


func _v20_active_command_id_for_unit(unit: Node) -> String:
	for command_id in ["v20_emergency_fallback", "v20_rally", "v20_focus"]:
		var active := V20CommandService.active_effect(v20_command_state, command_id)
		if active.is_empty():
			continue
		return command_id
	return ""


func _v20_movement_command_for_unit(_unit: Node) -> Dictionary:
	for command_id in ["v20_emergency_fallback", "v20_rally"]:
		var active := V20CommandService.active_effect(v20_command_state, command_id)
		if not active.is_empty() and bool(active.get("effect", {}).get("force_move_to_target", false)):
			active["command_id"] = command_id
			return active
	return {}


func _v20_command_attack_multiplier(attacker: Node, target: Node) -> float:
	if not _v20_roles_active() or attacker.faction != Constants.FACTION_MONSTER:
		return 1.0
	var effect := V20CommandService.effect_for_target(v20_command_state, str(target.get_instance_id()), str(target.current_room))
	return maxf(0.1, float(effect.get("damage_multiplier", 1.0)))


func _record_v20_command_damage(attacker: Node, target: Node, directive_multiplier: float, command_multiplier: float, boosted_damage: int) -> void:
	if not _v20_roles_active() or attacker.faction != Constants.FACTION_MONSTER or command_multiplier <= 1.0:
		return
	var baseline := DamageService.compute(attacker, target, directive_multiplier * _facility_attack_multiplier(attacker, target))
	var bonus := maxi(0, boosted_damage - baseline)
	if bonus > 0:
		_record_v20_command_metric("v20_focus", "focus_damage", bonus)


func _record_v20_command_metric_from_sources(command_ids: Array, metric_id: String, amount: float) -> void:
	for command_id_value in command_ids:
		_record_v20_command_metric(str(command_id_value), metric_id, amount)


func _record_v20_command_metric(command_id: String, metric_id: String, amount: float) -> void:
	var recorded := V20CommandService.record_metric(v20_command_state, command_id, metric_id, amount)
	if bool(recorded.get("ok", false)):
		v20_command_state = recorded.get("state", v20_command_state)


func _v20_board() -> Dictionary:
	return DataRegistry.v20_dungeon_layouts.get("v20_day_01_05_board", {}).duplicate(true)


func _v20_encounter_context() -> Dictionary:
	var facility_context := V20FacilityService.path_context(v20_facility_state, DataRegistry.v20_facilities) if not v20_facility_state.is_empty() else {}
	var facilities: Array[Dictionary] = []
	for placement_id_value in v20_facility_state.get("facilities", {}).keys():
		var runtime: Dictionary = v20_facility_state.get("facilities", {}).get(placement_id_value, {})
		facilities.append({
			"id": str(placement_id_value),
			"section_id": str(placement_id_value),
			"facility_id": str(runtime.get("facility_id", "")),
			"node_id": str(runtime.get("room_id", "")),
			"active": float(runtime.get("disabled_seconds", 0.0)) <= 0.0
		})
	return {
		"seed": int(root.get_meta("v20_seed", 0)),
		"facilities": facilities,
		"door_state_costs": facility_context.get("door_state_costs", {}).duplicate(true),
		"facility_route_costs": facility_context.get("facility_route_costs", {}).duplicate(true),
		"temporary_hazard_costs": facility_context.get("temporary_hazard_costs", {}).duplicate(true),
		"opposite_route_costs": {"north": 8.0}
	}


func _record_v20_encounter_response(command_id: String) -> void:
	if v20_encounter_definition.is_empty() or v20_encounter_state.is_empty():
		return
	var command_tags: Array = DataRegistry.v20_commands.get(command_id, {}).get("response_tags", [])
	for phase_value in v20_encounter_definition.get("phases", []):
		var phase: Dictionary = phase_value
		var phase_id := str(phase.get("id", ""))
		var phase_state: Dictionary = v20_encounter_state.get("phases", {}).get(phase_id, {})
		if not bool(phase_state.get("telegraphed", false)) or bool(phase_state.get("resolved", false)):
			continue
		for tag_value in command_tags:
			var tag := str(tag_value)
			if not phase.get("response_tags", []).has(tag):
				continue
			var applied := V20EncounterService.apply_response(v20_encounter_state, v20_encounter_definition, phase_id, tag)
			if bool(applied.get("ok", false)):
				v20_encounter_state = applied.get("state", v20_encounter_state)

func _most_wounded_ally(unit: Node) -> Node:
	var result: Node = null
	var lowest_ratio := 0.7
	for ally in root.monster_units:
		if ally == unit or not ally.is_alive():
			continue
		var hp_ratio = float(ally.hp) / float(max(1, ally.max_hp))
		if hp_ratio < lowest_ratio:
			lowest_ratio = hp_ratio
			result = ally
	return result

func _entry_block_active() -> bool:
	return root.room_directives.get("entrance", Constants.ROOM_DIRECTIVE_NONE) == Constants.ROOM_DIRECTIVE_ENTRY_BLOCK or root.room_directives.get("spike_corridor", Constants.ROOM_DIRECTIVE_NONE) == Constants.ROOM_DIRECTIVE_ENTRY_BLOCK

func _trap_lure_point(unit: Node) -> Vector2:
	var base = root.graph.center("spike_corridor")
	if unit.unit_id == "slime":
		return root._clamp_to_combat_walkable(base + Vector2(-32, 34))
	if unit.unit_id == "goblin":
		return root._clamp_to_combat_walkable(base + Vector2(42, 26))
	return root._clamp_to_combat_walkable(base)

func _retreat_unit(unit: Node, reason: String) -> void:
	var retreat_room = _retreat_room(unit)
	move_unit_to_room(unit, retreat_room)
	if root.global_directive == Constants.DIRECTIVE_SURVIVAL:
		unit.activate_shield(0.6, 0.80)
	elif root.global_directive == Constants.DIRECTIVE_DEFENSE:
		unit.activate_shield(0.6, 0.70)
	unit.set_tactical_state(Constants.UNIT_STATE_RETREAT, reason, _room_name(retreat_room))
	if root.has_method("_onboarding_unit_retreat"):
		root._onboarding_unit_retreat(unit)

func _hero_skills_enabled() -> bool:
	return HERO_SKILL_DAYS.has(GameState.day) or (_v20_roles_active() and GameState.day == 5)

func _is_hero_unit(unit: Node) -> bool:
	return is_instance_valid(unit) and HERO_UNIT_IDS.has(str(unit.unit_id))

func _run_hero_skill(unit: Node) -> bool:
	if not _hero_skills_enabled() or not _is_hero_unit(unit):
		return false
	# 한 기술의 네 프레임이 끝나기 전에 다음 기술로 덮어쓰지 않는다.
	# 실제 전투에서도 외침·맹세·돌진이 각각 완전한 스킬 모션으로 보이게 한다.
	if float(unit.skill_anim_timer) > 0.0:
		return true
	if _try_final_oath(unit):
		return true
	if _try_brave_shout(unit):
		return true
	if not unit.skill_ready("hero_dash"):
		return false
	var target = TargetingService.nearest(unit, root.monster_units, 170.0)
	if target == null:
		return false
	var direction = (target.global_position - unit.global_position).normalized()
	if direction == Vector2.ZERO:
		return false
	var dash_end = root._clamp_to_combat_walkable(unit.global_position + direction * HERO_DASH_DISTANCE)
	unit.stop_navigation()
	unit.set_physics_process(false)
	hero_dash_states[unit.get_instance_id()] = {
		"unit": unit,
		"target": target,
		"start": unit.global_position,
		"end": dash_end,
		"elapsed": 0.0,
		"finished": false
	}
	unit.set_skill_cooldown("hero_dash", 7.0)
	unit.play_skill()
	hero_dash_activations += 1
	unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "용사의 돌진", target.display_name)
	root._log("%s가 용사의 돌진을 사용했습니다." % unit.display_name)
	return true

func _try_final_oath(unit: Node) -> bool:
	if GameState.day != 30 or str(unit.unit_id) != "official_hero_leon":
		return false
	var instance_id := unit.get_instance_id()
	if final_oath_activated_ids.has(instance_id):
		return false
	if float(unit.hp) / float(max(1, unit.max_hp)) > FINAL_OATH_HP_RATIO:
		return false
	final_oath_activated_ids[instance_id] = true
	var hp_before := int(unit.hp)
	unit.heal(max(1, int(round(float(unit.max_hp) * FINAL_OATH_HEAL_RATIO))))
	unit.activate_shield(FINAL_OATH_SHIELD_SECONDS, FINAL_OATH_DAMAGE_REDUCTION, "최후의 맹세")
	unit.play_skill()
	unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "최후의 맹세", "체력 회복 · 피해 감소")
	final_oath_activations += 1
	final_oath_healing += max(0, int(unit.hp) - hp_before)
	spawn_effect_burst("guard", unit.global_position, Vector2(0, -24), Vector2(1.42, 1.22), 16.0)
	root._log("%s의 최후의 맹세: 체력을 회복하고 방어막을 전개합니다." % unit.display_name)
	return true

func _try_roman_supply_command(unit: Node) -> bool:
	if GameState.day != 20 or str(unit.unit_id) != "roman" or not unit.skill_ready("supply_command"):
		return false
	var recipient: Node = null
	var lowest_hp_ratio := 1.0
	for enemy in root.enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive():
			continue
		if unit.global_position.distance_to(enemy.global_position) > ROMAN_SUPPLY_RADIUS:
			continue
		var hp_ratio := float(enemy.hp) / float(max(1, enemy.max_hp))
		if hp_ratio < lowest_hp_ratio:
			lowest_hp_ratio = hp_ratio
			recipient = enemy
	if recipient == null:
		return false
	var hp_before := int(recipient.hp)
	recipient.heal(max(1, int(round(float(recipient.max_hp) * ROMAN_SUPPLY_HEAL_RATIO))))
	recipient.activate_shield(ROMAN_SUPPLY_SHIELD_SECONDS, ROMAN_SUPPLY_DAMAGE_REDUCTION, "보급 방호")
	unit.set_skill_cooldown("supply_command", ROMAN_SUPPLY_COOLDOWN)
	unit.play_skill(recipient.global_position)
	unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "보급 지휘", "%s 회복 · 방어" % recipient.display_name)
	roman_supply_activations += 1
	roman_supply_healing += max(0, int(recipient.hp) - hp_before)
	roman_supply_shields += 1
	spawn_effect_burst("guard", recipient.global_position, Vector2(0, -18), Vector2(1.18, 1.04), 12.0)
	root._log("%s의 보급 지휘: %s의 체력을 회복하고 방어막을 보급합니다." % [unit.display_name, recipient.display_name])
	return true

func _hero_dash_result_line() -> String:
	if not _hero_skills_enabled() or hero_dash_activations <= 0:
		return ""
	return "레온 기술: 용사의 돌진 %d회 · 누적 피해 %d" % [hero_dash_activations, hero_dash_damage]

func _final_oath_result_line() -> String:
	if GameState.day != 30 or final_oath_activations <= 0:
		return ""
	return "레온 기술: 최후의 맹세 %d회 · 회복 %d · 방어막 %.1f초" % [final_oath_activations, final_oath_healing, FINAL_OATH_SHIELD_SECONDS]

func _roman_supply_result_line() -> String:
	if GameState.day != 20 or roman_supply_activations <= 0:
		return ""
	return "로만 기술: 보급 지휘 %d회 · 회복 %d · 방어 보급 %d회" % [roman_supply_activations, roman_supply_healing, roman_supply_shields]

func _hero_dash_active(unit: Node) -> bool:
	return is_instance_valid(unit) and hero_dash_states.has(unit.get_instance_id())

func _hero_dash_target_position(unit: Node) -> Vector2:
	if not _hero_dash_active(unit):
		return unit.global_position if is_instance_valid(unit) else Vector2.ZERO
	var state: Dictionary = hero_dash_states[unit.get_instance_id()]
	return Vector2(state.get("end", unit.global_position))

func _update_hero_dashes(delta: float) -> void:
	for instance_id_value in hero_dash_states.keys():
		var instance_id := int(instance_id_value)
		var state: Dictionary = hero_dash_states[instance_id]
		var unit = state.get("unit")
		if not is_instance_valid(unit) or not unit.is_alive():
			hero_dash_states.erase(instance_id)
			continue
		if bool(state.get("finished", false)):
			hero_dash_states.erase(instance_id)
			continue
		var elapsed := minf(HERO_DASH_DURATION, float(state.get("elapsed", 0.0)) + maxf(0.0, delta))
		var progress := clampf(elapsed / HERO_DASH_DURATION, 0.0, 1.0)
		var eased_progress := 1.0 - pow(1.0 - progress, 2.0)
		var dash_start := Vector2(state.get("start", unit.global_position))
		var dash_end := Vector2(state.get("end", unit.global_position))
		unit.global_position = dash_start.lerp(dash_end, eased_progress)
		state["elapsed"] = elapsed
		if progress >= 1.0:
			unit.global_position = dash_end
			unit.set_physics_process(true)
			_apply_hero_dash_impact(unit, dash_end, state.get("target"))
			state["finished"] = true
		hero_dash_states[instance_id] = state

func _apply_hero_dash_impact(unit: Node, dash_end: Vector2, primary_target = null) -> void:
	var primary_hit := false
	for monster in root.monster_units:
		if monster.is_alive() and monster.global_position.distance_to(dash_end) <= HERO_DASH_IMPACT_RADIUS:
			var hp_before = int(monster.hp)
			var dealt_damage = monster.receive_damage(HERO_DASH_DAMAGE)
			hero_dash_damage += int(dealt_damage)
			_record_damage_contribution(unit, monster, HERO_DASH_DAMAGE, dealt_damage, hp_before)
			monster.mark_threat(unit)
			spawn_impact(monster.global_position)
			primary_hit = primary_hit or monster == primary_target
	# The dash starts only after choosing a nearby target. If walkable-area clamping
	# shortens the visual movement at a doorway, keep the promised primary impact.
	if not primary_hit and is_instance_valid(primary_target) and primary_target.is_alive():
		var hp_before = int(primary_target.hp)
		var dealt_damage = primary_target.receive_damage(HERO_DASH_DAMAGE)
		hero_dash_damage += int(dealt_damage)
		_record_damage_contribution(unit, primary_target, HERO_DASH_DAMAGE, dealt_damage, hp_before)
		primary_target.mark_threat(unit)
		spawn_impact(primary_target.global_position)

func _has_loot_bonus() -> bool:
	for unit in root.monster_units:
		if unit.is_alive() and unit.loot_bonus_active:
			return true
	return false

func _room_name(room_id: String) -> String:
	return root.rooms.get(room_id, {}).get("display_name", room_id)

func _core_room() -> String:
	return root._room_by_type("core", "throne")

func _treasure_room() -> String:
	if _v20_roles_active():
		var objective_room := _v20_runtime_room("treasure")
		return objective_room if root.rooms.has(objective_room) else ""
	return root._room_by_facility("treasure", "")

func _nearest_active_facility_room(from_room: String, requesting_engineer_id: int = 0, allow_previously_targeted: bool = false) -> String:
	var reserved_rooms: Dictionary = {}
	for enemy in root.enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive() or enemy.unit_id != "engineer":
			continue
		var enemy_instance_id: int = enemy.get_instance_id()
		if enemy_instance_id == requesting_engineer_id:
			continue
		var reserved_room := str(root.engineer_target_rooms.get(enemy_instance_id, ""))
		if reserved_room != "":
			reserved_rooms[reserved_room] = true
	var best_room := ""
	var best_distance := 999999
	for room_id in root._engineer_target_facility_rooms():
		if reserved_rooms.has(room_id) or (not allow_previously_targeted and root.engineer_targeted_facility_rooms.has(room_id)):
			continue
		var distance := 0
		if room_id != from_room:
			var route: Array = root.graph.path_between(from_room, room_id)
			if route.is_empty():
				continue
			distance = route.size()
		if distance < best_distance or (distance == best_distance and (best_room == "" or room_id < best_room)):
			best_distance = distance
			best_room = room_id
	return best_room

func _assign_engineer_target(unit: Node) -> bool:
	var room_id := _nearest_active_facility_room(str(unit.current_room), unit.get_instance_id())
	if room_id == "":
		# 한 전투에서 이미 노린 시설은 우선 피하되, 모든 후보를 한 번씩 노린 뒤에는 재사용한다.
		room_id = _nearest_active_facility_room(str(unit.current_room), unit.get_instance_id(), true)
	if room_id == "":
		root.engineer_target_rooms.erase(unit.get_instance_id())
		unit.goal_room = _core_room()
		unit.set_path(_path_from_world_to_room(unit.global_position, unit.goal_room))
		return false
	root.engineer_target_rooms[unit.get_instance_id()] = room_id
	root.engineer_targeted_facility_rooms[room_id] = true
	unit.goal_room = room_id
	unit.set_path(_path_from_world_to_room(unit.global_position, room_id))
	unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "시설 교란 접근", _room_name(room_id))
	root._log("왕국 공병 목표: %s." % _room_name(room_id))
	root.queue_redraw()
	return true

func _update_engineer_path(unit: Node) -> bool:
	var instance_id = unit.get_instance_id()
	if root.engineer_completed_units.has(instance_id):
		return false
	var target_room := str(root.engineer_target_rooms.get(instance_id, ""))
	if target_room == "" or not root._facility_room_is_active(target_room):
		if not _assign_engineer_target(unit):
			return false
		target_room = str(root.engineer_target_rooms.get(instance_id, ""))
	if unit.current_room == target_room:
		root.engineer_completed_units[instance_id] = true
		root.engineer_target_rooms.erase(instance_id)
		root.engineers_reached_facility_this_battle += 1
		var disable_seconds := ENGINEER_DISABLE_SECONDS
		if _v20_roles_active():
			disable_seconds = float(unit.get_meta("v20_special_action", {}).get("duration_seconds", 7.0))
		root._disable_facility_room(target_room, disable_seconds)
		_roman_support_facility_completed(unit)
		unit.role = "throne"
		unit.goal_room = _core_room()
		unit.set_path(_path_from_world_to_room(unit.global_position, unit.goal_room))
		unit.play_skill(root.graph.center(target_room))
		unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "시설 무력화", _room_name(target_room))
		return true
	move_unit_to_room(unit, target_room)
	unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "시설 교란 접근", _room_name(target_room))
	return true

func _barracks_room() -> String:
	return root._room_by_facility("barracks", "barracks")

func _retreat_room(unit: Node) -> String:
	var fallback = str(unit.assigned_room)
	if fallback == "" or not root.rooms.has(fallback) or root.rooms[fallback].get("type", "") == "build_slot":
		fallback = "recovery"
	return root._room_by_facility("recovery", fallback)

func move_unit_to_room(unit: Node, room_id: String) -> void:
	if room_id == "" or not root.rooms.has(room_id):
		return
	if unit.goal_room == room_id and not unit.path_points.is_empty():
		return
	unit.goal_room = room_id
	unit.set_path(_path_from_world_to_room(unit.global_position, room_id))
	unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "방 이동", _room_name(room_id))

func move_unit_to_point(unit: Node, point: Vector2, preserve_goal: bool = false) -> void:
	point = root._clamp_to_combat_walkable(point)
	if unit.global_position.distance_to(point) <= 16.0:
		if unit.has_method("stop_navigation"):
			unit.stop_navigation()
		return
	if not unit.path_points.is_empty() and unit.path_points[-1].distance_to(point) <= 16.0:
		return
	if not preserve_goal:
		unit.goal_room = unit.current_room
	var route: Array = []
	if _point_room(point) == unit.current_room:
		route = [point]
	elif root.graph != null and root.graph.has_method("path_to_point"):
		route = root.graph.path_to_point(unit.global_position, point)
	if route.is_empty():
		route = [point]
	unit.set_path(route)
	unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET, "위치 이동")

func _hold_attack_position(unit: Node, target: Node) -> bool:
	if target == null or not is_instance_valid(target) or not target.is_alive():
		return false
	if target.current_room != unit.current_room:
		return false
	var hold_range = max(18.0, float(unit.attack_range) * 0.92)
	if unit.global_position.distance_to(target.global_position) > hold_range:
		return false
	if unit.has_method("stop_navigation"):
		unit.stop_navigation()
	unit.set_tactical_state(Constants.UNIT_STATE_ATTACK, "교전 유지", target.display_name)
	return true

func update_room_effects(delta: float) -> void:
	var recovery_rooms: Array[String] = []
	for room_id in root._rooms_by_facility("recovery"):
		if root._facility_room_is_active(room_id):
			recovery_rooms.append(room_id)
	var core_room = _core_room()
	var treasure_room = _treasure_room()
	var watch_rooms = _watch_post_pressure_rooms()
	_record_barracks_combat_time(delta)
	for unit in root.monster_units:
		if not unit.is_alive() or recovery_rooms.is_empty():
			continue
		var recovery_rate := 0.0
		var recovery_room := ""
		if _v20_roles_active():
			if recovery_rooms.has(str(unit.current_room)):
				recovery_room = str(unit.current_room)
				var recovery_effect := _v20_facility_effects_for_room(recovery_room, "v20_recovery_nest")
				recovery_rate = float(recovery_effect.get("heal_per_second", 0.0))
		else:
			if recovery_rooms.has(str(unit.current_room)):
				recovery_room = str(unit.current_room)
				recovery_rate = 8.0 * _castle_facility_scale("recovery_power_scale")
			else:
				recovery_room = _assigned_active_facility_room(unit, "recovery")
				if recovery_room != "" and root.graph.exits(recovery_room).has(unit.current_room):
					recovery_rate = 3.0 * _castle_facility_scale("recovery_power_scale")
		if recovery_rate > 0.0:
			var key = unit.get_instance_id()
			var carry = float(recovery_heal_accumulator.get(key, 0.0)) + recovery_rate * delta
			var heal_amount = int(floor(carry))
			recovery_heal_accumulator[key] = carry - float(heal_amount)
			if heal_amount > 0:
				var before_hp = unit.hp
				unit.heal(heal_amount)
				var healed = max(0, unit.hp - before_hp)
				if healed > 0 and root.has_method("_record_facility_effect_stat"):
					root._record_facility_effect_stat("recovery_healing", healed)
					root._record_monster_contribution(str(unit.unit_id), "facility_value", healed)
			if unit.current_room == recovery_room:
				unit.set_tactical_state(Constants.UNIT_STATE_RETREAT, "회복 중", _room_name(recovery_room))
	for enemy in root.enemy_units:
		if enemy.is_alive() and watch_rooms.has(enemy.current_room):
			var watch_factor := _watch_post_slow_factor()
			if _v20_roles_active():
				var watch_effect := _v20_pressure_effects("v20_watch_post", str(enemy.current_room))
				watch_factor = float(watch_effect.get("enemy_slow_multiplier", 1.0))
				watch_factor = minf(watch_factor, float(watch_effect.get("slow_multiplier", watch_factor)))
			if watch_factor < 1.0:
				if enemy.slow_timer <= 0.05 and root.has_method("_record_facility_effect_stat"):
					root._record_facility_effect_stat("watch_post_slow_applications", 1)
				enemy.apply_slow(WATCH_POST_SLOW_SECONDS, watch_factor)
		if not enemy.is_alive():
			continue
		var barricade_effect := _v20_facility_effects_for_room(str(enemy.current_room), "v20_barricade")
		if not barricade_effect.is_empty():
			enemy.apply_slow(WATCH_POST_SLOW_SECONDS, float(barricade_effect.get("enemy_slow_multiplier", 0.78)))
		if str(enemy.unit_id) == "thief":
			var decoy_effect := _v20_facility_effects_for_room(str(enemy.current_room), "v20_decoy_treasure")
			if not decoy_effect.is_empty():
				enemy.apply_slow(WATCH_POST_SLOW_SECONDS, float(decoy_effect.get("thief_slow_multiplier", 0.82)))
	if root.trap_cooldown <= 0.0:
		for enemy in root.enemy_units:
			if enemy.is_alive() and enemy.current_room == "spike_corridor":
				var trap_damage = 14
				var slow_seconds = 2.0
				var slow_factor = 0.8
				if root.room_directives.get("spike_corridor", Constants.ROOM_DIRECTIVE_NONE) == Constants.ROOM_DIRECTIVE_TRAP_LURE:
					trap_damage = 30
					slow_seconds = 3.5
					slow_factor = 0.55
				enemy.receive_damage(trap_damage)
				enemy.apply_slow(slow_seconds, slow_factor)
				root.trap_cooldown = 2.0 * root._update2_cycle_effect_value("trap_cooldown_multiplier", 1.0)
				trigger_quarter_trap("spike_corridor", "spike_floor")
				if root.has_method("_onboarding_trap_triggered"):
					root._onboarding_trap_triggered()
				root._log("가시 복도가 %s에게 피해를 주었습니다." % enemy.display_name)
				spawn_impact(enemy.global_position)
				break
	var active_defender_count := 0
	for monster in root.monster_units:
		if monster.is_alive():
			active_defender_count += 1
	for enemy in root.enemy_units:
		if enemy.is_alive() and enemy.current_room == "heart_chamber" and enemy.goal_room == "heart_chamber":
			enemy.set_tactical_state(Constants.UNIT_STATE_ATTACK, "심장 압박", _room_name("heart_chamber"))
			if float(enemy.purifying_hymn_cast_timer) <= 0.0 and float(enemy.ledger_mark_cast_timer) <= 0.0 and enemy.attack_cooldown <= 0.0 and TargetingService.nearest(enemy, root.monster_units, enemy.attack_range) == null:
				var heart_result: Dictionary = root._damage_update3_heart_chamber(maxi(6, int(enemy.atk))) if root.has_method("_damage_update3_heart_chamber") else {}
				enemy.attack_cooldown = enemy.effective_attack_interval()
				if bool(heart_result.get("disabled", false)):
					enemy.goal_room = core_room
					enemy.set_path(_path_from_world_to_room(enemy.global_position, core_room))
				root._log("%s가 마왕성 심장실에 %d 피해." % [enemy.display_name, int(heart_result.get("damage", 0))])
		if enemy.is_alive() and enemy.current_room == core_room:
			enemy.set_tactical_state(Constants.UNIT_STATE_ATTACK, "왕좌 압박", _room_name(core_room))
			if enemy.attack_cooldown <= 0.0 and TargetingService.nearest(enemy, root.monster_units, enemy.attack_range) == null:
				var throne_damage: int = maxi(8, int(enemy.atk))
				if active_defender_count == 0:
					throne_damage = int(round(float(throne_damage) * UNOPPOSED_THRONE_DAMAGE_MULTIPLIER))
				GameState.damage_throne(throne_damage)
				if root.has_method("_record_update3_throne_damage"):
					root._record_update3_throne_damage(throne_damage)
				enemy.attack_cooldown = enemy.effective_attack_interval()
				if active_defender_count == 0:
					root._log("방어 몬스터가 모두 쓰러져 %s의 왕좌 공격이 강해졌습니다." % enemy.display_name)
				else:
					root._log("%s가 왕좌의 방을 공격했습니다." % enemy.display_name)
		if enemy.is_alive() and enemy.unit_id == "thief" and treasure_room != "" and enemy.current_room == treasure_room:
			enemy.set_tactical_state(Constants.UNIT_STATE_LOOTING, "보물 약탈", "금화")
			var loot_delay_seconds := _v20_loot_delay_seconds(treasure_room)
			if not root.thief_steal_timers.has(enemy):
				root.thieves_reached_treasure_this_battle += 1
				root._log("도둑이 보물 방에 침입했습니다. 약탈까지 %.1f초 남았습니다." % loot_delay_seconds)
			var timer = float(root.thief_steal_timers.get(enemy, 0.0)) + delta
			root.thief_steal_timers[enemy] = timer
			if timer >= loot_delay_seconds:
				var stolen_gold = min(100, GameState.gold)
				GameState.gold = max(0, GameState.gold - stolen_gold)
				SignalBus.resources_changed.emit()
				root.thief_steal_timers[enemy] = -999.0
				root.treasure_gold_stolen_this_battle += stolen_gold
				root.thieves_completed_theft_this_battle += 1
				enemy.goal_room = "entrance"
				enemy.set_path(_path_from_world_to_room(enemy.global_position, "entrance"))
				if root.has_method("_onboarding_treasure_stolen"):
					root._onboarding_treasure_stolen()
				root._log("도둑이 보물을 훔쳤습니다. 금화 -%d." % stolen_gold)
		if enemy.is_alive() and enemy.unit_id == "thief" and float(root.thief_steal_timers.get(enemy, 0.0)) < -100.0 and enemy.current_room == "entrance":
			enemy.hp = 0
			enemy.down = true
			enemy.escaped = true
			enemy.visible = false
			root.thieves_escaped_this_battle += 1
			root._log("도둑이 입구로 도주했습니다.")

func _record_barracks_combat_time(delta: float) -> void:
	if not root.has_method("_record_facility_effect_time"):
		return
	for unit in root.monster_units:
		if not unit.is_alive() or _assigned_active_facility_room(unit, "barracks") == "":
			continue
		root._record_facility_effect_time("barracks_assigned_unit_seconds", delta)
		if not _unit_in_facility_room(unit, "barracks"):
			continue
		root._record_facility_effect_time("barracks_covered_unit_seconds", delta)
		var enemy_in_room := false
		var enemy_in_range := false
		for enemy in root.enemy_units:
			if not enemy.is_alive() or enemy.current_room != unit.current_room:
				continue
			enemy_in_room = true
			if unit.global_position.distance_to(enemy.global_position) <= unit.attack_range:
				enemy_in_range = true
		if enemy_in_room:
			root._record_facility_effect_time("barracks_contested_unit_seconds", delta)
		if enemy_in_range:
			root._record_facility_effect_time("barracks_in_range_unit_seconds", delta)

func update_attacks(_delta: float) -> void:
	for unit in root.monster_units:
		if unit.is_alive():
			try_attack(unit, root.enemy_units)
	for unit in root.enemy_units:
		if unit.is_alive():
			try_attack(unit, root.monster_units)

func _path_from_world_to_room(from_world: Vector2, room_id: String) -> Array:
	var target = root._clamp_to_combat_walkable(root.graph.center(room_id))
	if root.graph != null and root.graph.has_method("path_to_point"):
		return root.graph.path_to_point(from_world, target)
	return [target]

func _point_room(point: Vector2) -> String:
	if root.graph == null:
		return ""
	if root.graph.has_method("room_at_world"):
		return root.graph.room_at_world(point)
	if root.graph.has_method("closest_room"):
		return root.graph.closest_room(point)
	return ""

func _scaled_enemy_stats(enemy_id: String, wave_entry: Dictionary = {}) -> Dictionary:
	var stats = DataRegistry.enemy(enemy_id).duplicate(true)
	if stats.is_empty():
		return stats
	stats["max_hp"] = _scale_int_stat(stats, wave_entry, "max_hp", "hp_scale", 1.0)
	stats["atk"] = _scale_int_stat(stats, wave_entry, "atk", "atk_scale", 1.0)
	stats["def"] = _scale_int_stat(stats, wave_entry, "def", "def_scale", 0.0)
	stats["exp"] = _scale_int_stat(stats, wave_entry, "exp", "reward_scale", 0.0)
	stats["infamy"] = _scale_int_stat(stats, wave_entry, "infamy", "reward_scale", 0.0)
	stats["morale"] = _scale_int_stat(stats, wave_entry, "morale", "morale_scale", 0.0)
	if wave_entry.has("goal_type_override"):
		stats["goal_type"] = str(wave_entry.get("goal_type_override", stats.get("goal_type", "throne")))
	if root.has_method("_apply_update2_leon_enemy_stats"):
		root._apply_update2_leon_enemy_stats(enemy_id, stats)
	return stats

func _scale_int_stat(stats: Dictionary, wave_entry: Dictionary, stat_key: String, scale_key: String, minimum: float) -> int:
	var base_value = float(stats.get(stat_key, 0))
	var flat_bonus = float(wave_entry.get("%s_bonus" % stat_key, 0.0))
	var scale = float(wave_entry.get(scale_key, 1.0))
	var scaled_value = max(minimum, base_value * scale + flat_bonus)
	return int(round(scaled_value))

func try_attack(attacker: Node, opponents: Array) -> void:
	if attacker.has_method("duo_action_locked") and attacker.duo_action_locked():
		return
	if _hero_dash_active(attacker):
		return
	if attacker.attack_cooldown > 0.0:
		return
	if attacker.tactical_state == Constants.UNIT_STATE_STUNNED:
		return
	var fighting_retreat = attacker.tactical_state == Constants.UNIT_STATE_RETREAT
	var target = _leon_pursuit_target(attacker, opponents)
	if target == null and attacker.has_method("forced_attack_target"):
		target = attacker.forced_attack_target(opponents, attacker.attack_range)
	if target == null and attacker.has_method("preferred_attack_target"):
		target = attacker.preferred_attack_target(opponents, attacker.attack_range)
	if target == null:
		target = TargetingService.nearest(attacker, opponents, attacker.attack_range)
	if target == null:
		return
	if not fighting_retreat and attacker.has_method("stop_navigation"):
		attacker.stop_navigation()
	var base_damage = DamageService.compute(attacker, target, 1.0)
	var directive_multiplier = _directive_attack_multiplier(attacker)
	var directive_damage = DamageService.compute(attacker, target, directive_multiplier)
	_record_directive_attack_effect(attacker, base_damage, directive_damage)
	var command_multiplier := _v20_command_attack_multiplier(attacker, target)
	var damage = DamageService.compute(attacker, target, directive_multiplier * command_multiplier * _facility_attack_multiplier(attacker, target))
	_record_v20_command_damage(attacker, target, directive_multiplier, command_multiplier, damage)
	if attacker.has_method("attack_multiplier_against"):
		damage = maxi(1, int(round(float(damage) * attacker.attack_multiplier_against(target))))
	if target.has_method("damage_taken_multiplier_from"):
		damage = maxi(1, int(round(float(damage) * target.damage_taken_multiplier_from(attacker))))
	_record_facility_attack_bonus(attacker, target, directive_damage, damage, directive_multiplier)
	var damage_before_directive_reduction = damage
	damage = _apply_directive_damage_taken_modifier(target, damage)
	_record_directive_damage_taken_effect(target, damage_before_directive_reduction, damage)
	var damage_before_facility_reduction = damage
	damage = _apply_facility_damage_taken_modifier(attacker, target, damage)
	if damage < damage_before_facility_reduction and root.has_method("_record_facility_effect_stat"):
		var facility_reduction = damage_before_facility_reduction - damage
		root._record_facility_effect_stat("barracks_damage_reduced", facility_reduction)
		root._record_facility_effect_stat("barracks_damage_reduction_applications", 1)
		root._record_monster_contribution(str(target.unit_id), "facility_value", facility_reduction)
	var is_imp_projectile = attacker.faction == Constants.FACTION_MONSTER and attacker.unit_id == "imp"
	if attacker.faction == Constants.FACTION_MONSTER and attacker.unit_id == "goblin" and root.has_method("_tutorial_emit_action"):
		root._tutorial_emit_action("goblin_attacks_once", {"unit_id": attacker.unit_id, "target_id": target.unit_id})
	attacker.attack_cooldown = attacker.effective_attack_interval()
	if not fighting_retreat:
		attacker.set_tactical_state(Constants.UNIT_STATE_ATTACK, "기본 공격", target.display_name)
	_mark_action_target(attacker, target)
	if attacker.has_method("play_attack"):
		attacker.play_attack(target.global_position)
	_play_attack_sfx(attacker)
	if is_imp_projectile:
		_launch_damage_projectile(attacker, target, damage, false, "basic")
	else:
		var hp_before = int(target.hp)
		var dealt_damage = target.receive_damage(damage)
		_record_damage_contribution(attacker, target, damage, dealt_damage, hp_before)
		if attacker.faction == Constants.FACTION_MONSTER and str(attacker.unit_id) == "graveyard_hound" and float(target.scent_mark_timer) > 0.0 and root.has_method("_record_update3_duo_link_action"):
			root._record_update3_duo_link_action("monster_koko", "marked_target_damage", maxi(1, dealt_damage), "koko_marked:%d:%d" % [target.get_instance_id(), Time.get_ticks_usec()])
		if attacker.faction == Constants.FACTION_MONSTER and str(attacker.unit_id) == "stone_sentinel" and float(attacker.guard_timer) > 0.0 and root.has_method("_record_update3_duo_link_action"):
			root._record_update3_duo_link_action("mon_contract_dolkong", "fixed_attack", 1, "fixed_attack:%d:%d" % [attacker.get_instance_id(), Time.get_ticks_usec()])
		_apply_combat_hit_feedback(attacker, target, dealt_damage, false, MELEE_CONTACT_DELAY)
		if root.has_method("_onboarding_unit_damaged"):
			root._onboarding_unit_damaged(target)
		if target.has_method("mark_threat"):
			target.mark_threat(attacker)
		spawn_slash(target.global_position, MELEE_CONTACT_DELAY)
		root._log("%s가 %s에게 %d 피해." % [attacker.display_name, target.display_name, dealt_damage])
		_apply_leon_duelist_counter(attacker, target, dealt_damage)

func _leon_pursuit_target(attacker: Node, opponents: Array) -> Node:
	if leon_stance_id != "leon_stance_pursuit" or str(attacker.unit_id) != "official_hero_leon":
		return null
	var selected: Node = null
	var longest_range := -1.0
	for candidate in opponents:
		if not is_instance_valid(candidate) or not candidate.is_alive():
			continue
		if attacker.global_position.distance_to(candidate.global_position) > attacker.attack_range:
			continue
		if float(candidate.attack_range) > longest_range:
			selected = candidate
			longest_range = float(candidate.attack_range)
	return selected


func _update_leon_adaptation(delta: float) -> void:
	if leon_stance_id != "leon_stance_purification" or GameState.day != 30:
		return
	leon_purification_cooldown = maxf(0.0, leon_purification_cooldown - delta)
	if leon_purification_cooldown > 0.0:
		return
	var leon: Node = null
	for enemy in root.enemy_units:
		if is_instance_valid(enemy) and enemy.is_alive() and str(enemy.unit_id) == "official_hero_leon":
			leon = enemy
			break
	if leon == null:
		return
	var stance := DataRegistry.leon_adaptive_stance(leon_stance_id)
	var effects: Dictionary = stance.get("effects", {})
	var duration := float(effects.get("duration", 5.0))
	var strength := float(effects.get("counter_strength", 0.25))
	if root.has_method("_update2_soft_counter_strength"):
		strength = root._update2_soft_counter_strength(strength)
	var affected := 0
	for monster in root.monster_units:
		if not is_instance_valid(monster) or not monster.is_alive():
			continue
		var applied := false
		for mode_value in effects.get("counter_modes", []):
			if monster.apply_soft_counter(str(mode_value), duration, strength, "official_hero_leon") > 0.0:
				applied = true
		if applied:
			affected += 1
	if affected <= 0:
		leon_purification_cooldown = 0.5
		return
	leon_purification_cooldown = float(effects.get("cooldown", 7.0))
	leon_stance_activations += 1
	leon.play_skill()
	leon.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "정화 파동", "%d명 회복·보호 억제" % affected)
	root._log("레온의 정화 파동: %d명의 회복과 보호막 효율을 %.0f%% 낮춥니다." % [affected, strength * 100.0])


func trigger_leon_heart_response(heart_id: String) -> bool:
	if leon_heart_response_used or str(root.update3_active_run.get("front_id", "")) != "front_hero_oath":
		return false
	var leon := _official_leon_unit()
	if leon == null:
		return false
	leon_heart_response_used = true
	leon_heart_response_count += 1
	leon.activate_shield(2.5, 0.10, "심장 대응")
	leon.set_meta("update3_heart_response_id", heart_id)
	_record_leon_update3_response("leon_heart_responses")
	root._log("레온 심장 대응 · %s의 박동을 읽고 2.5초간 방어 자세를 취합니다." % heart_id)
	return true


func trigger_leon_duo_response(link_id: String) -> bool:
	if leon_duo_response_used or str(root.update3_active_run.get("front_id", "")) != "front_hero_oath":
		return false
	var leon := _official_leon_unit()
	if leon == null:
		return false
	leon_duo_response_used = true
	leon_duo_response_count += 1
	leon.activate_shield(2.0, 0.08, "합동기 대응")
	leon.set_meta("update3_duo_response_id", link_id)
	_record_leon_update3_response("leon_duo_responses")
	root._log("레온 합동기 대응 · %s의 호흡을 읽고 2초간 방어 자세를 취합니다." % link_id)
	return true


func _official_leon_unit() -> Node:
	for enemy in root.enemy_units:
		if is_instance_valid(enemy) and enemy.is_alive() and str(enemy.unit_id) == "official_hero_leon":
			return enemy
	return null


func _record_leon_update3_response(metric_id: String) -> void:
	var metrics: Dictionary = root.update3_active_run.get("run_metrics_update3", {}).duplicate(true)
	metrics[metric_id] = int(metrics.get(metric_id, 0)) + 1
	root.update3_active_run["run_metrics_update3"] = metrics


func _apply_leon_duelist_counter(attacker: Node, target: Node, dealt_damage: int) -> void:
	if leon_stance_id != "leon_stance_duelist" or dealt_damage <= 0:
		return
	if not is_instance_valid(attacker) or not is_instance_valid(target) or not target.is_alive():
		return
	if attacker.faction != Constants.FACTION_MONSTER or str(target.unit_id) != "official_hero_leon":
		return
	var effects: Dictionary = DataRegistry.leon_adaptive_stance(leon_stance_id).get("effects", {})
	var counter_damage := mini(int(effects.get("counter_damage_cap", 18)), maxi(1, int(round(float(dealt_damage) * float(effects.get("counter_damage_ratio", 0.30))))))
	var actual_damage: int = attacker.receive_damage(counter_damage)
	leon_counter_damage += actual_damage
	leon_stance_activations += 1
	target.play_attack(attacker.global_position)
	root._log("레온의 결투 반격이 %s에게 %d 피해." % [attacker.display_name, actual_damage])


func _leon_adaptation_result_line() -> String:
	if leon_stance_id == "":
		return ""
	var stance := DataRegistry.leon_adaptive_stance(leon_stance_id)
	return "레온 적응: %s · 전술 발동 %d회 · 반격 피해 %d" % [str(stance.get("display_name", leon_stance_id)), leon_stance_activations, leon_counter_damage]

func _record_facility_attack_bonus(attacker: Node, target: Node, base_damage: int, boosted_damage: int, directive_multiplier: float) -> void:
	if attacker.faction != Constants.FACTION_MONSTER or not root.has_method("_record_facility_effect_stat"):
		return
	var barracks_active = _unit_in_facility_room(attacker, "barracks")
	if barracks_active:
		root._record_facility_effect_stat("barracks_attack_applications", 1)
	if boosted_damage <= base_damage:
		return
	if barracks_active:
		var barracks_only = DamageService.compute(attacker, target, directive_multiplier * _barracks_attack_multiplier())
		var barracks_bonus = max(0, min(barracks_only, int(target.hp)) - min(base_damage, int(target.hp)))
		root._record_facility_effect_stat("barracks_bonus_damage", barracks_bonus)
		root._record_monster_contribution(str(attacker.unit_id), "facility_value", barracks_bonus)
	if target.faction == Constants.FACTION_ENEMY and _watch_post_pressure_rooms().has(target.current_room):
		var watch_only = DamageService.compute(attacker, target, directive_multiplier * _watch_post_damage_multiplier())
		var watch_bonus = max(0, min(watch_only, int(target.hp)) - min(base_damage, int(target.hp)))
		root._record_facility_effect_stat("watch_post_bonus_damage", watch_bonus)
		root._record_monster_contribution(str(attacker.unit_id), "facility_value", watch_bonus)

func _mark_action_target(attacker: Node, target: Node) -> void:
	if attacker == null or target == null:
		return
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return
	if attacker.has_method("mark_action_target"):
		attacker.mark_action_target(target)

func _record_damage_contribution(attacker: Node, target: Node, incoming_damage: int, dealt_damage: int, hp_before: int, attacker_unit_id: String = "", heart_attack_token: String = "") -> void:
	if target == null or not is_instance_valid(target) or not root.has_method("_record_monster_contribution"):
		return
	var actual_hp_loss = max(0, hp_before - int(target.hp))
	var resolved_attacker_id = attacker_unit_id
	var attacker_is_monster = false
	var attacker_is_enemy = false
	if attacker != null and is_instance_valid(attacker):
		resolved_attacker_id = str(attacker.unit_id)
		attacker_is_monster = attacker.faction == Constants.FACTION_MONSTER
		attacker_is_enemy = attacker.faction == Constants.FACTION_ENEMY
	elif resolved_attacker_id != "" and root.monster_roster.has(resolved_attacker_id):
		attacker_is_monster = true
	if attacker_is_monster and target.faction == Constants.FACTION_ENEMY:
		root._record_monster_contribution(resolved_attacker_id, "damage_dealt", actual_hp_loss)
		if heart_attack_token != "" and actual_hp_loss > 0 and root.has_method("_record_update3_dream_charge"):
			root._record_update3_dream_charge("skill_hit", heart_attack_token)
		if root.has_method("_record_update3_hungry_damage"):
			var resolved_token := heart_attack_token
			if resolved_token == "":
				resolved_token = "%s:%s:%d" % [resolved_attacker_id, str(target.get_instance_id()), Time.get_ticks_usec()]
			root._record_update3_hungry_damage(actual_hp_loss, resolved_token)
		if hp_before > 0 and not target.is_alive():
			root._record_monster_contribution(resolved_attacker_id, "finishing_blows", 1)
			if resolved_attacker_id == "goblin" and root.has_method("_record_update3_duo_link_action"):
				root._record_update3_duo_link_action("mon_core_gob", "finisher", 1, "gob_finisher:%d:%d" % [target.get_instance_id(), Time.get_ticks_usec()])
			if root.has_method("_record_update3_hungry_finish"):
				root._record_update3_hungry_finish(target)
	elif attacker_is_enemy and target.faction == Constants.FACTION_MONSTER:
		var prevented_damage = max(0, incoming_damage - dealt_damage)
		var pressure_handled = mini(incoming_damage, actual_hp_loss + prevented_damage)
		root._record_monster_contribution(str(target.unit_id), "damage_absorbed", pressure_handled)
		if root.has_method("_record_update3_heart_charge"):
			root._record_update3_heart_charge("monster_damage_absorbed", pressure_handled, str(target.get_instance_id()))
		if root.has_method("_record_update3_duo_link_action"):
			var target_instance_id: String = root._update3_unit_instance_id(target)
			root._record_update3_duo_link_action(target_instance_id, "damage_absorbed", pressure_handled, "damage:%s:%d" % [str(target.get_instance_id()), Time.get_ticks_usec()])
			if target_instance_id == "mon_core_pudding":
				root._record_update3_duo_link_action(target_instance_id, "guard_or_block", 1, "pudding_block:%s:%d" % [str(target.get_instance_id()), Time.get_ticks_usec()])

func _directive_attack_multiplier(attacker: Node) -> float:
	if attacker.faction != Constants.FACTION_MONSTER:
		return 1.0
	match root.global_directive:
		Constants.DIRECTIVE_ALL_OUT:
			return ALL_OUT_ATTACK_MULTIPLIER
		Constants.DIRECTIVE_SURVIVAL:
			return SURVIVAL_ATTACK_MULTIPLIER
		_:
			return 1.0

func _record_directive_attack_effect(attacker: Node, base_damage: int, directive_damage: int) -> void:
	if attacker.faction != Constants.FACTION_MONSTER or not root.has_method("_record_directive_effect_stat"):
		return
	if root.global_directive == Constants.DIRECTIVE_ALL_OUT and directive_damage > base_damage:
		root._record_directive_effect_stat("all_out_bonus_damage", directive_damage - base_damage)

func _apply_directive_damage_taken_modifier(target: Node, damage: int) -> int:
	if target.faction != Constants.FACTION_MONSTER:
		return damage
	var multiplier := 1.0
	var result := damage
	match root.global_directive:
		Constants.DIRECTIVE_ALL_OUT:
			result = maxi(damage + 1, int(ceil(float(damage) * ALL_OUT_DAMAGE_TAKEN_MULTIPLIER)))
		Constants.DIRECTIVE_SURVIVAL:
			multiplier = SURVIVAL_DAMAGE_TAKEN_MULTIPLIER
			result = max(1, int(round(float(damage) * multiplier)))
		_:
			multiplier = DEFENSE_DAMAGE_TAKEN_MULTIPLIER
			result = max(1, int(round(float(damage) * multiplier)))
	if _v20_roles_active():
		var command_effect := V20CommandService.effect_for_target(v20_command_state, str(target.get_instance_id()), str(target.current_room))
		var command_reduction := float(command_effect.get("damage_taken_multiplier", 1.0))
		var reduced: int = max(1, int(round(float(result) * command_reduction)))
		if reduced < result:
			_record_v20_command_metric_from_sources(command_effect.get("source_commands", []), "damage_prevented", result - reduced)
		result = reduced
	return result

func _record_directive_damage_taken_effect(target: Node, before: int, after: int) -> void:
	if target.faction != Constants.FACTION_MONSTER or not root.has_method("_record_directive_effect_stat"):
		return
	match root.global_directive:
		Constants.DIRECTIVE_ALL_OUT:
			root._record_directive_effect_stat("all_out_extra_damage_taken", max(0, after - before))
		Constants.DIRECTIVE_SURVIVAL:
			root._record_directive_effect_stat("survival_damage_reduced", max(0, before - after))
		_:
			root._record_directive_effect_stat("defense_damage_reduced", max(0, before - after))

func _facility_attack_multiplier(attacker: Node, target: Node) -> float:
	if attacker.faction != Constants.FACTION_MONSTER:
		return 1.0
	var multiplier := 1.0
	if _unit_in_facility_room(attacker, "barracks"):
		var barracks_room := _assigned_active_facility_room(attacker, "barracks")
		if _v20_roles_active():
			var barracks_effect := _v20_facility_effects_for_room(barracks_room, "v20_barracks")
			multiplier *= float(barracks_effect.get("monster_damage_multiplier", 1.0))
		else:
			multiplier *= _barracks_attack_multiplier()
	if target.faction == Constants.FACTION_ENEMY and _watch_post_pressure_rooms().has(target.current_room):
		if _v20_roles_active():
			var watch_effect := _v20_pressure_effects("v20_watch_post", str(target.current_room))
			multiplier *= float(watch_effect.get("monster_damage_multiplier", 1.0))
		else:
			multiplier *= _watch_post_damage_multiplier()
	return multiplier

func _apply_facility_damage_taken_modifier(attacker: Node, target: Node, damage: int) -> int:
	var result := damage
	if target.faction == Constants.FACTION_MONSTER:
		var barracks_room := _assigned_active_facility_room(target, "barracks")
		if barracks_room != "" and root.has_method("_record_facility_effect_stat"):
			root._record_facility_effect_stat("barracks_assigned_incoming_attacks", 1)
		if _unit_in_facility_room(target, "barracks"):
			if _v20_roles_active():
				var barracks_effect := _v20_facility_effects_for_room(barracks_room, "v20_barracks")
				result = int(round(float(result) * float(barracks_effect.get("monster_damage_taken_multiplier", 1.0))))
			else:
				result = int(round(float(result) * _barracks_damage_taken_multiplier()))
			if result >= damage and root.has_method("_record_facility_effect_stat"):
				root._record_facility_effect_stat("barracks_no_reduction_hits", 1)
		if root._facility_is_active("ward_core"):
			var before_ward := result
			result = int(round(float(result) * _castle_facility_scale("ward_damage_taken_scale")))
			if result < before_ward and root.has_method("_record_facility_effect_stat"):
				root._record_facility_effect_stat("ward_damage_reduced", before_ward - result)
		if root.has_method("_update3_modify_monster_damage"):
			result = root._update3_modify_monster_damage(target, result)
	return max(1, result)

func _castle_facility_scale(key: String) -> float:
	if root.has_method("_castle_facility_scale"):
		return float(root._castle_facility_scale(key, 1.0))
	return 1.0

func _barracks_attack_multiplier() -> float:
	return 1.0 + (BARRACKS_ATTACK_MULTIPLIER - 1.0) * _castle_facility_scale("barracks_power_scale")

func _barracks_damage_taken_multiplier() -> float:
	return 1.0 - (1.0 - BARRACKS_DAMAGE_TAKEN_MULTIPLIER) * _castle_facility_scale("barracks_power_scale")

func _watch_post_damage_multiplier() -> float:
	return 1.0 + (WATCH_POST_DAMAGE_MULTIPLIER - 1.0) * _castle_facility_scale("watch_power_scale")

func _watch_post_slow_factor() -> float:
	return clampf(1.0 - (1.0 - WATCH_POST_SLOW_FACTOR) * _castle_facility_scale("watch_power_scale"), 0.45, 0.95)

func _unit_in_facility_room(unit: Node, facility_id: String) -> bool:
	var facility_room := _assigned_active_facility_room(unit, facility_id)
	if facility_room == "":
		return false
	if unit.current_room == facility_room:
		return true
	return root.graph != null and root.graph.exits(facility_room).has(unit.current_room)

func _assigned_active_facility_room(unit: Node, facility_id: String) -> String:
	var assigned_room := str(unit.assigned_room)
	if assigned_room == "" or not root.rooms.has(assigned_room):
		return ""
	if str(root.rooms[assigned_room].get("facility_role", "")) != facility_id:
		return ""
	return assigned_room if root._facility_room_is_active(assigned_room) else ""

func _watch_post_pressure_rooms() -> Array:
	if root.has_method("_active_watch_post_pressure_rooms"):
		return root._active_watch_post_pressure_rooms()
	return []


func _v20_facility_effects_for_room(room_id: String, facility_id: String) -> Dictionary:
	if not _v20_roles_active() or room_id == "" or not root._facility_room_is_active(room_id):
		return {}
	return V20FacilityService.effects_for_room(v20_facility_state, room_id, DataRegistry.v20_facilities, facility_id)


func _v20_active_facility_effects_for_room(room_id: String, facility_id: String) -> Dictionary:
	if not _v20_roles_active() or room_id == "" or not root._facility_room_is_active(room_id):
		return {}
	for placement_id_value in v20_facility_state.get("facilities", {}).keys():
		var placement_id := str(placement_id_value)
		var runtime: Dictionary = v20_facility_state.get("facilities", {}).get(placement_id, {})
		if str(runtime.get("room_id", "")) == room_id and str(runtime.get("facility_id", "")) == facility_id:
			return V20FacilityService.combat_effects(v20_facility_state, placement_id, DataRegistry.v20_facilities)
	return {}


func _v20_pressure_effects(facility_id: String, affected_room: String) -> Dictionary:
	if not _v20_roles_active() or root.graph == null:
		return {}
	for placement_id_value in v20_facility_state.get("facilities", {}).keys():
		var placement_id := str(placement_id_value)
		var runtime: Dictionary = v20_facility_state.get("facilities", {}).get(placement_id, {})
		if str(runtime.get("facility_id", "")) != facility_id:
			continue
		var source_room := str(runtime.get("room_id", ""))
		if source_room == affected_room or root.graph.exits(source_room).has(affected_room):
			return V20FacilityService.effects_for_room(v20_facility_state, source_room, DataRegistry.v20_facilities, facility_id)
	return {}


func _v20_loot_delay_seconds(room_id: String) -> float:
	var delay := 5.0
	if _v20_roles_active():
		var decoy_effect := _v20_facility_effects_for_room(room_id, "v20_decoy_treasure")
		delay *= float(decoy_effect.get("loot_delay_multiplier", 1.0))
	return delay

func on_unit_downed(unit: Node) -> void:
	if unit.faction == Constants.FACTION_ENEMY:
		if str(unit.unit_id) == "ledger_binder":
			var cleared := _clear_ledger_marks_from_source(unit)
			for index in range(ledger_mark_casts.size() - 1, -1, -1):
				if int(ledger_mark_casts[index].get("source_id", 0)) == unit.get_instance_id():
					ledger_mark_casts.remove_at(index)
			if cleared > 0:
				root._log("장부 구속술사 격퇴로 부채 표식 %d개가 즉시 해제됐습니다." % cleared)
		root.rewards_pending["gold"] = int(root.rewards_pending.get("gold", 0)) + 60
		root.rewards_pending["mana"] = int(root.rewards_pending.get("mana", 0)) + 20
		root.rewards_pending["infamy"] = int(root.rewards_pending.get("infamy", 0)) + unit.infamy_reward
		for monster_id in root.monster_roster.keys():
			if root.has_method("_monster_available_for_defense") and not root._monster_available_for_defense(str(monster_id)):
				continue
			var shared_exp = max(5, int(unit.exp_reward / 3))
			root.monster_roster[monster_id]["exp"] = int(root.monster_roster[monster_id]["exp"]) + shared_exp
			if root.has_method("_record_monster_contribution"):
				root._record_monster_contribution(str(monster_id), "shared_exp", shared_exp)
		root._log("%s 격퇴. 악명 +%d." % [unit.display_name, unit.infamy_reward])
		if ROYAL_RALLY_DAYS.has(GameState.day) and unit.unit_id == "selen_trainee_paladin":
			_update_royal_rally(0.0)
	else:
		root._log("%s가 전투 불능이 되었습니다." % unit.display_name)

func check_combat_end() -> void:
	if GameState.defeat:
		finish_combat(false, "마왕성 체력이 0이 되었습니다.")
		return
	var alive_enemies = 0
	for enemy in root.enemy_units:
		if enemy.is_alive():
			alive_enemies += 1
	if root.wave_manager.is_done() and alive_enemies == 0:
		var win_text = "DAY %d 방어 성공." % GameState.day
		if GameState.day == GameState.max_day:
			GameState.victory = true
			win_text = "3일차 수련생 용사를 격퇴했습니다."
		finish_combat(true, win_text)

func finish_combat(win: bool, reason: String) -> void:
	if root.current_screen == Constants.SCREEN_RESULT:
		return
	for unit in root.monster_units + root.enemy_units:
		if is_instance_valid(unit):
			unit.set_physics_process(false)
	if win and _has_loot_bonus():
		var bonus_gold = int(round(float(root.rewards_pending.get("gold", 0)) * 0.1))
		if bonus_gold > 0:
			root.rewards_pending["gold"] = int(root.rewards_pending.get("gold", 0)) + bonus_gold
			root._log("고블린 약탈 본능 보너스 금화 +%d." % bonus_gold)
	var growth_summary := []
	if root.has_method("_finalize_battle_growth"):
		growth_summary = root._finalize_battle_growth(win)
	var challenge_seal_result_line := ""
	if root.has_method("_resolve_update2_challenge_seal"):
		challenge_seal_result_line = root._resolve_update2_challenge_seal(win)
	GameState.add_rewards(root.rewards_pending)
	var lines: Array[String] = []
	var alive_monsters := 0
	var total_monsters := 0
	var remaining_monster_hp := 0
	var total_monster_hp := 0
	for monster in root.monster_units:
		if not is_instance_valid(monster):
			continue
		total_monsters += 1
		remaining_monster_hp += max(0, int(monster.hp))
		total_monster_hp += int(monster.max_hp)
		if monster.is_alive():
			alive_monsters += 1
	lines.append(reason)
	if challenge_seal_result_line != "":
		lines.append(challenge_seal_result_line)
	lines.append("격퇴한 적: %d / 탈출: %d / 스폰: %d" % [count_downed_enemies(), root.thieves_escaped_this_battle, root.spawned_count])
	lines.append("전투 시간: %.1f초 / 생존 몬스터: %d/%d" % [root.combat_time, alive_monsters, total_monsters])
	lines.append("잔여 전력: HP %d / %d" % [remaining_monster_hp, total_monster_hp])
	lines.append("획득 금화: %d" % int(root.rewards_pending.get("gold", 0)))
	lines.append("획득 마력: %d" % int(root.rewards_pending.get("mana", 0)))
	lines.append("증가 악명: %d" % int(root.rewards_pending.get("infamy", 0)))
	if root.has_method("_current_security_result_line"):
		var security_result_line: String = root._current_security_result_line()
		if security_result_line != "":
			lines.append(security_result_line)
	if int(root.treasure_gold_stolen_this_battle) > 0:
		lines.append("보물 손실: 금화 %d" % int(root.treasure_gold_stolen_this_battle))
	lines.append("마왕성 체력: %d / %d" % [GameState.demon_lord_hp, GameState.demon_lord_max_hp])
	if root.has_method("_directive_effect_result_lines"):
		lines.append_array(root._directive_effect_result_lines())
	if root.has_method("_facility_effect_result_lines"):
		lines.append_array(root._facility_effect_result_lines())
	if root.has_method("_engineer_result_lines"):
		lines.append_array(root._engineer_result_lines())
	if root.has_method("_update3_heart_result_lines"):
		lines.append_array(root._update3_heart_result_lines())
	if root.has_method("_update3_duo_link_result_lines"):
		lines.append_array(root._update3_duo_link_result_lines())
	var rally_result_line := _royal_rally_result_line()
	if rally_result_line != "":
		lines.append(rally_result_line)
	var brave_shout_result_line := _brave_shout_result_line()
	if brave_shout_result_line != "":
		lines.append(brave_shout_result_line)
	var update2_counterforce_result_line := _update2_counterforce_result_line()
	if update2_counterforce_result_line != "":
		lines.append(update2_counterforce_result_line)
	var leon_adaptation_result_line := _leon_adaptation_result_line()
	if leon_adaptation_result_line != "":
		lines.append(leon_adaptation_result_line)
	var hero_dash_result_line := _hero_dash_result_line()
	if hero_dash_result_line != "":
		lines.append(hero_dash_result_line)
	var final_oath_result_line := _final_oath_result_line()
	if final_oath_result_line != "":
		lines.append(final_oath_result_line)
	var roman_supply_result_line := _roman_supply_result_line()
	if roman_supply_result_line != "":
		lines.append(roman_supply_result_line)
	if root.has_method("_campaign_result_lines"):
		lines.append_array(root._campaign_result_lines(win))
	if root.has_method("_apply_campaign_result_flags"):
		root._apply_campaign_result_flags(win)
	if root.has_method("_record_battle_run_metrics"):
		root._record_battle_run_metrics()
	for line_index in range(lines.size()):
		if str(lines[line_index]).begins_with("마왕성 체력:"):
			lines[line_index] = "마왕성 체력: %d / %d" % [GameState.demon_lord_hp, GameState.demon_lord_max_hp]
			break
	root.result_summary = {
		"win": win,
		"lines": lines,
		"growth": growth_summary,
		"metrics": {
			"combat_time": root.combat_time,
			"alive_monsters": alive_monsters,
			"total_monsters": total_monsters,
			"remaining_monster_hp": remaining_monster_hp,
			"total_monster_hp": total_monster_hp,
			"directive": root.global_directive,
			"directive_effects": root.directive_effect_stats.duplicate(true),
			"facility_effects": root.facility_effect_stats.duplicate(true),
			"monster_contributions": root.battle_contribution_stats.duplicate(true),
			"demon_lord_hp": GameState.demon_lord_hp,
			"demon_lord_hp_max": GameState.demon_lord_max_hp,
			"treasure_gold_stolen": root.treasure_gold_stolen_this_battle,
			"thieves_spawned": root.thieves_spawned_this_battle,
			"thieves_reached_treasure": root.thieves_reached_treasure_this_battle,
			"thieves_completed_theft": root.thieves_completed_theft_this_battle,
			"thieves_escaped": root.thieves_escaped_this_battle,
			"engineers_spawned": root.engineers_spawned_this_battle,
			"engineers_reached_facility": root.engineers_reached_facility_this_battle,
			"facility_disables": root.facility_disables_this_battle,
			"engineer_targeted_facilities": root.engineer_targeted_facility_rooms.size(),
			"facilities_saved": root._engineer_facilities_saved_count(),
			"royal_rally_seconds": royal_rally_active_seconds,
			"royal_rally_activations": royal_rally_activations,
			"royal_rally_stopped": royal_rally_stopped,
			"brave_shout_seconds": brave_shout_active_seconds,
			"brave_shout_activations": brave_shout_activations,
			"brave_shout_recipients": brave_shout_recipient_total,
			"hero_dash_activations": hero_dash_activations,
			"hero_dash_damage": hero_dash_damage,
			"final_oath_activations": final_oath_activations,
			"final_oath_healing": final_oath_healing,
			"roman_supply_activations": roman_supply_activations,
			"roman_supply_healing": roman_supply_healing,
			"roman_supply_shields": roman_supply_shields,
			"update2_counter_activations": update2_counter_activations.duplicate(true),
			"update2_counter_targets": update2_counter_targets,
			"update2_counter_healing": update2_counter_healing,
			"leon_stance_id": leon_stance_id,
			"leon_stance_activations": leon_stance_activations,
			"leon_counter_damage": leon_counter_damage
		}
	}
	if _v20_roles_active():
		root.result_summary["metrics"]["v20_command_points_spent"] = _v20_command_points_spent()
		root.result_summary["metrics"]["v20_encounter"] = v20_encounter_state.get("result_metrics", {}).duplicate(true)
		if root.has_method("_v20_finalize_battle_result"):
			root.result_summary = root._v20_finalize_battle_result(root.result_summary)
	SignalBus.battle_finished.emit(root.result_summary)
	root._set_screen(Constants.SCREEN_RESULT)
	if root.has_method("_onboarding_battle_finished"):
		root._onboarding_battle_finished(win)


func _v20_command_points_spent() -> int:
	var total := 0
	for row_value in v20_command_state.get("history", []):
		var command_id := str(row_value.get("command_id", ""))
		total += int(DataRegistry.v20_commands.get(command_id, {}).get("command_point_cost", 0))
	return total

func count_downed_enemies() -> int:
	var count = 0
	for enemy in root.enemy_units:
		if not enemy.is_alive() and not bool(enemy.get("escaped")):
			count += 1
	return count

func set_global_directive(directive: String) -> void:
	root.global_directive = directive
	root._log("전체 지침: %s." % DirectiveManager.directive_label(directive))
	if root.current_screen == Constants.SCREEN_COMBAT:
		root._set_screen(Constants.SCREEN_COMBAT)

func set_room_directive(directive: String) -> void:
	root.room_directives[root.selected_room] = directive
	root._log("%s 지침: %s." % [root.rooms[root.selected_room].get("display_name", root.selected_room), DirectiveManager.directive_label(directive)])
	root._set_screen(root.current_screen)

func preview_selected_skill(slot: int) -> void:
	clear_skill_preview()
	if root.selected_unit == null or not is_instance_valid(root.selected_unit) or root.selected_unit.faction != Constants.FACTION_MONSTER:
		return
	var skill_slots: Array = DataRegistry.monster(root.selected_unit.unit_id).get("skill_slots", [])
	if slot < 0 or slot >= skill_slots.size() or skill_slots[slot] == null:
		return
	var skill_id := str(skill_slots[slot])
	var skill_name := str(DataRegistry.skill(skill_id).get("display_name", skill_id))
	var preview_range := 0.0
	var preview_targets: Array = []
	match skill_id:
		"slime_shield", "hold_corridor", "loot_instinct", "rumor_boost":
			preview_range = 52.0
			preview_targets.append(root.selected_unit)
		"quick_slash":
			preview_range = root.selected_unit.attack_range + 38.0
			var slash_target = TargetingService.nearest(root.selected_unit, root.enemy_units, preview_range)
			if slash_target != null:
				preview_targets.append(slash_target)
		"fireball":
			preview_range = 320.0 + _combat_skill_float(root.selected_unit.unit_id, skill_id, "range_bonus", 0.0)
			var fire_target = TargetingService.nearest(root.selected_unit, root.enemy_units, preview_range)
			if fire_target != null:
				preview_targets.append(fire_target)
		"flame_zone":
			var barracks_room = _barracks_room()
			for enemy in root.enemy_units:
				if enemy.is_alive() and ["spike_corridor", barracks_room].has(enemy.current_room):
					preview_targets.append(enemy)
		"false_footprints":
			preview_range = 260.0
			for enemy in root.enemy_units:
				if enemy.is_alive() and root.selected_unit.global_position.distance_to(enemy.global_position) <= preview_range:
					preview_targets.append(enemy)
		"spectral_transfer":
			preview_range = 220.0
			var rescue_target = _bebe_rescue_target(root.selected_unit, 1.0)
			if rescue_target != null:
				preview_targets.append(rescue_target)
		"haunted_broom_whirl":
			preview_range = 85.0
			preview_targets = _bebe_broom_targets(root.selected_unit, preview_range)
		"scent_lock":
			preview_range = 420.0
			var scent_target = _danger_tracker_target(root.selected_unit)
			if scent_target != null:
				preview_targets.append(scent_target)
		"home_guard_bark":
			preview_range = float(DataRegistry.skill("home_guard_bark").get("radius", 145.0))
			for bark_target in root.enemy_units:
				if bark_target.is_alive() and root.selected_unit.global_position.distance_to(bark_target.global_position) <= preview_range:
					preview_targets.append(bark_target)
		"carapace_ram":
			preview_range = _toktok_ram_distance(root.selected_unit)
			var ram_target = _toktok_ram_target(root.selected_unit)
			if ram_target != null and root.selected_unit.global_position.distance_to(ram_target.global_position) <= preview_range:
				preview_targets.append(ram_target)
		"patch_plates":
			preview_range = float(DataRegistry.skill("patch_plates").get("range", 120.0))
			var patch_ally = _toktok_patch_ally_target(root.selected_unit)
			if patch_ally != null:
				preview_targets.append(patch_ally)
			elif _toktok_facility_repair_target(root.selected_unit) != "":
				preview_targets.append(root.selected_unit)
	var target_summary := "자신 강화" if preview_targets.size() == 1 and preview_targets[0] == root.selected_unit else "%d명 대상" % preview_targets.size()
	if preview_targets.is_empty() and ["quick_slash", "fireball", "flame_zone", "false_footprints", "spectral_transfer", "haunted_broom_whirl", "carapace_ram", "patch_plates"].has(skill_id):
		target_summary = "현재 대상 없음"
	root.selected_unit.set_skill_preview(preview_range, preview_targets, "%s · %s" % [skill_name, target_summary])

func clear_skill_preview() -> void:
	for monster in root.monster_units:
		if is_instance_valid(monster) and monster.has_method("clear_skill_preview"):
			monster.clear_skill_preview()

func _execute_selected_unit_skill(slot: int) -> bool:
	clear_skill_preview()
	if root.selected_unit == null or root.selected_unit.faction != Constants.FACTION_MONSTER:
		return false
	if not root.selected_unit.is_alive():
		root._log("전투 불능인 몬스터는 스킬을 사용할 수 없습니다.")
		return false
	if root.selected_unit.has_method("active_skills_locked") and root.selected_unit.active_skills_locked():
		root._log("봉인 사슬 때문에 액티브 스킬을 사용할 수 없습니다. %.1f초 남았습니다." % root.selected_unit.seal_skill_lock_timer)
		return false
	if root.selected_unit.has_method("duo_action_locked") and root.selected_unit.duo_action_locked():
		root._log("합동기 동작 중에는 다른 행동을 할 수 없습니다.")
		return false
	var monster_data = DataRegistry.monster(root.selected_unit.unit_id)
	var skills: Array = monster_data.get("skill_slots", [])
	if slot < 0 or slot >= skills.size() or skills[slot] == null:
		root._log("사용 가능한 스킬이 없습니다.")
		return false
	var skill_id = str(skills[slot])
	if not root.selected_unit.skill_ready(skill_id):
		root._log("스킬 재사용 대기 중입니다.")
		return false
	var skill = DataRegistry.skill(skill_id)
	var cost = root._current_skill_mana_cost(skill)
	if GameState.mana < cost:
		root._log("마력이 부족합니다.")
		return false
	var prepared_target: Node = null
	var prepared_zone_targets: Array = []
	if skill_id == "quick_slash":
		prepared_target = TargetingService.nearest(root.selected_unit, root.enemy_units, root.selected_unit.attack_range + 38.0)
	elif skill_id == "fireball":
		var prepared_fire_range = 320.0 + _combat_skill_float(root.selected_unit.unit_id, skill_id, "range_bonus", 0.0)
		prepared_target = TargetingService.nearest(root.selected_unit, root.enemy_units, prepared_fire_range)
	elif skill_id == "moon_mark":
		prepared_target = TargetingService.nearest(root.selected_unit, root.enemy_units, 360.0)
	elif skill_id == "scent_pursuit":
		prepared_target = TargetingService.nearest(root.selected_unit, root.enemy_units, 280.0)
	elif skill_id == "flame_zone":
		prepared_zone_targets = _flame_zone_targets()
	elif skill_id == "spectral_transfer":
		prepared_target = _bebe_rescue_target(root.selected_unit, 1.0)
	elif skill_id == "scent_lock":
		prepared_target = _danger_tracker_target(root.selected_unit)
	elif skill_id == "carapace_ram":
		prepared_target = _toktok_ram_target(root.selected_unit)
	elif skill_id == "patch_plates":
		prepared_target = _toktok_patch_ally_target(root.selected_unit)
	if ["quick_slash", "fireball", "moon_mark", "scent_pursuit", "spectral_transfer", "scent_lock", "carapace_ram"].has(skill_id) and prepared_target == null:
		root._log("사거리 안에 공격할 대상이 없습니다.")
		return false
	if skill_id == "carapace_ram" and root.selected_unit.global_position.distance_to(prepared_target.global_position) > _toktok_ram_distance(root.selected_unit):
		root._log("갑각 돌진 범위 안에 적이 없습니다.")
		return false
	if skill_id == "patch_plates" and prepared_target == null and _toktok_facility_repair_target(root.selected_unit) == "":
		root._log("수리할 시설이나 보호할 아군이 없습니다.")
		return false
	if skill_id == "flame_zone" and prepared_zone_targets.is_empty():
		root._log("화염 지대 범위에 대상이 없습니다.")
		return false
	GameState.mana -= cost
	SignalBus.resources_changed.emit()
	_play_skill_sfx(skill_id)
	match skill_id:
		"slime_shield":
			var shield_duration = 5.0 + _combat_skill_float(root.selected_unit.unit_id, skill_id, "duration_bonus", 0.0)
			var shield_reduction = 0.4 + _combat_skill_float(root.selected_unit.unit_id, skill_id, "reduction_bonus", 0.0)
			var shield_target = root.selected_unit
			var promotion_id := str(root.monster_roster.get(root.selected_unit.unit_id, {}).get("promotion_id", ""))
			if promotion_id == "slime_rescue_alchemy_gel":
				var wounded_ally = _most_wounded_ally(root.selected_unit)
				if wounded_ally != null:
					shield_target = wounded_ally
			shield_target.activate_shield(shield_duration, shield_reduction)
			root.selected_unit.play_skill()
			var shield_effect_id := "shield"
			if promotion_id == "slime_gate_bulwark":
				shield_effect_id = "slime_gate_bulwark"
			elif promotion_id == "slime_rescue_alchemy_gel":
				shield_effect_id = "slime_rescue_alchemy"
			spawn_effect_burst(shield_effect_id, shield_target.global_position, Vector2(0, -28), Vector2(1.24, 1.08), 12.0)
			root._log("슬라임이 %s에게 점액 방패를 펼쳤습니다." % shield_target.display_name)
		"hold_corridor":
			root.selected_unit.activate_guard(6.0, 3)
			root.selected_unit.play_skill()
			spawn_effect_burst("guard", root.selected_unit.global_position, Vector2(0, -18), Vector2(1.16, 1.0), 12.0)
			root._log("슬라임이 통로를 틀어막았습니다. 방어력 +3.")
		"quick_slash":
			var slash_target = prepared_target
			var goblin_promotion_id := str(root.monster_roster.get(root.selected_unit.unit_id, {}).get("promotion_id", ""))
			var slash_multiplier = 1.9 + _combat_skill_float(root.selected_unit.unit_id, skill_id, "damage_multiplier_bonus", 0.0)
			var damage = DamageService.compute(root.selected_unit, slash_target, slash_multiplier)
			var hp_before = int(slash_target.hp)
			var dealt_damage = slash_target.receive_damage(damage)
			_record_damage_contribution(root.selected_unit, slash_target, damage, dealt_damage, hp_before, "", "quick_slash:%d:%d" % [root.selected_unit.get_instance_id(), Time.get_ticks_usec()])
			slash_target.mark_threat(root.selected_unit)
			_mark_action_target(root.selected_unit, slash_target)
			root.selected_unit.play_attack(slash_target.global_position)
			_play_attack_sfx(root.selected_unit)
			_apply_combat_hit_feedback(root.selected_unit, slash_target, dealt_damage, true, MELEE_CONTACT_DELAY)
			root.selected_unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "날붙이 베기", slash_target.display_name)
			if goblin_promotion_id == "goblin_ambush_captain":
				spawn_effect_burst("goblin_ambush_captain", slash_target.global_position, Vector2(0, -18), Vector2(0.92, 0.92), 18.0)
			elif goblin_promotion_id == "goblin_vault_keeper":
				spawn_effect_burst("goblin_vault_keeper", root.selected_unit.global_position, Vector2(0, -24), Vector2(0.88, 0.88), 12.0)
			else:
				spawn_slash(slash_target.global_position, MELEE_CONTACT_DELAY)
			root._log("고블린이 날붙이 베기로 %d 피해." % damage)
		"loot_instinct":
			root.selected_unit.loot_bonus_active = true
			root.selected_unit.play_skill()
			root.selected_unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "약탈 본능", "승리 보상")
			spawn_effect_burst("loot", root.selected_unit.global_position, Vector2(0, -22), Vector2(1.05, 0.95), 13.0)
			root._log("고블린의 약탈 본능이 보상 금화를 올립니다.")
		"fireball":
			var fire_target = prepared_target
			var imp_promotion_id := str(root.monster_roster.get(root.selected_unit.unit_id, {}).get("promotion_id", ""))
			var fire_damage = 52 + int(_combat_skill_float(root.selected_unit.unit_id, skill_id, "damage_bonus", 0.0))
			_mark_action_target(root.selected_unit, fire_target)
			root.selected_unit.play_attack(fire_target.global_position)
			_play_attack_sfx(root.selected_unit)
			root.selected_unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "화염구", fire_target.display_name)
			if imp_promotion_id == "imp_flame_adept":
				spawn_effect_burst("imp_flame_adept", root.selected_unit.global_position, Vector2(0, -38), Vector2(0.86, 0.86), 14.0)
			_launch_damage_projectile(root.selected_unit, fire_target, fire_damage, true, "fireball")
			root._log("임프가 화염구를 발사했습니다.")
		"flame_zone":
			var zone_promotion_id := str(root.monster_roster.get(root.selected_unit.unit_id, {}).get("promotion_id", ""))
			_play_sfx(SFX_FIRE_BURST, "fire", -10.0, 0.12, 0.92, 1.02)
			var affected = 0
			var barracks_room = _barracks_room()
			var flame_damage = 34 + int(_combat_skill_float(root.selected_unit.unit_id, skill_id, "damage_bonus", 0.0))
			var slow_seconds = 2.5 + _combat_skill_float(root.selected_unit.unit_id, skill_id, "slow_seconds_bonus", 0.0)
			var slow_factor = max(0.4, 0.7 - _combat_skill_float(root.selected_unit.unit_id, skill_id, "slow_factor_bonus", 0.0))
			var affected_ids: Dictionary = {}
			var flame_attack_token := "flame_zone:%d:%d" % [root.selected_unit.get_instance_id(), Time.get_ticks_usec()]
			for enemy in prepared_zone_targets:
				if enemy.is_alive():
					var hp_before = int(enemy.hp)
					var dealt_damage = enemy.receive_magic_damage(flame_damage)
					_record_damage_contribution(root.selected_unit, enemy, flame_damage, dealt_damage, hp_before, "", flame_attack_token)
					enemy.mark_threat(root.selected_unit)
					enemy.apply_slow(slow_seconds, slow_factor)
					_apply_combat_hit_feedback(root.selected_unit, enemy, dealt_damage, affected == 0)
					spawn_impact(enemy.global_position)
					affected_ids[enemy.get_instance_id()] = true
					affected += 1
			root.selected_unit.play_skill()
			root.selected_unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "화염 지대", "가시 복도")
			if zone_promotion_id == "imp_ember_shaman":
				spawn_effect_burst("imp_ember_shaman", root.selected_unit.global_position, Vector2(0, 10), Vector2(1.12, 0.78), 10.0)
				var zone_duration := _combat_skill_float(root.selected_unit.unit_id, skill_id, "duration_bonus", 0.0)
				if zone_duration > 0.0:
					active_flame_zones.append({
						"remaining": zone_duration,
						"room_ids": ["spike_corridor", barracks_room],
						"damage": flame_damage,
						"slow_seconds": slow_seconds,
						"slow_factor": slow_factor,
						"source": root.selected_unit,
						"affected_ids": affected_ids
					})
			root._log("화염 지대가 %d명에게 피해를 줬습니다." % affected)
		"false_footprints":
			var affected = 0
			for enemy in root.enemy_units:
				if enemy.is_alive() and root.selected_unit.global_position.distance_to(enemy.global_position) <= 260.0:
					enemy.apply_slow(3.0, 0.62)
					enemy.mark_threat(root.selected_unit)
					spawn_effect_burst("guard", enemy.global_position, Vector2(0, -18), Vector2(0.85, 0.75), 9.0)
					affected += 1
			root.selected_unit.play_skill()
			root.selected_unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "가짜 발자국", "%d명 교란" % affected)
			root._log("로로의 가짜 발자국이 %d명을 헷갈리게 했습니다." % affected)
		"rumor_boost":
			root.rewards_pending["infamy"] = int(root.rewards_pending.get("infamy", 0)) + 8
			root.selected_unit.play_skill()
			root.selected_unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "소문 부풀리기", "악명 +8")
			spawn_effect_burst("loot", root.selected_unit.global_position, Vector2(0, -22), Vector2(1.05, 0.95), 13.0)
			root._log("로로가 원정식 과장 보고를 시작했습니다. 악명 +8.")
		"spore_mend":
			var mend_target = _lowest_health_monster(false)
			if mend_target == null:
				mend_target = root.selected_unit
			var mend_token := "spore_mend:%d:%d" % [root.selected_unit.get_instance_id(), Time.get_ticks_usec()]
			var effective_mend: int = mend_target.heal(46, mend_token)
			if root.has_method("_record_update3_duo_link_action"):
				root._record_update3_duo_link_action("mon_contract_mori", "effective_heal", effective_mend, mend_token)
			root.selected_unit.play_skill()
			spawn_effect_burst("shield", mend_target.global_position, Vector2(0, -22), Vector2(0.82, 0.82), 10.0)
			root._log("모리의 포자가 %s의 체력을 46 회복했습니다." % mend_target.display_name)
		"cleansing_bloom":
			cleanse_ledger_room(str(root.selected_unit.current_room), "모리")
			var cleansed := 0
			for ally in root.monster_units:
				if is_instance_valid(ally) and ally.is_alive() and ally.current_room == root.selected_unit.current_room:
					ally.heal(24)
					if not ally.cleanse_one_negative_status():
						ally.slow_timer = 0.0
						ally.slow_factor = 1.0
					cleansed += 1
			root.selected_unit.play_skill()
			spawn_effect_burst("shield", root.selected_unit.global_position, Vector2(0, -16), Vector2(1.2, 1.0), 11.0)
			root._log("모리의 정화 개화가 같은 방 아군 %d명을 회복·정화했습니다." % cleansed)
		"rooted_guard":
			root.selected_unit.activate_guard(8.0, 5)
			root.selected_unit.activate_shield(8.0, 0.25, "뿌리내린 수호")
			root.selected_unit.play_skill()
			spawn_effect_burst("guard", root.selected_unit.global_position, Vector2(0, -16), Vector2(1.3, 1.08), 13.0)
			root._log("돌콩이 자리를 굳혀 방어력 +5, 받는 피해 -25%를 얻었습니다.")
		"stone_pulse":
			var stone_hits := 0
			var stone_attack_token := "stone_pulse:%d:%d" % [root.selected_unit.get_instance_id(), Time.get_ticks_usec()]
			for enemy in root.enemy_units:
				if is_instance_valid(enemy) and enemy.is_alive() and root.selected_unit.global_position.distance_to(enemy.global_position) <= 180.0:
					var hp_before := int(enemy.hp)
					var dealt: int = enemy.receive_damage(32)
					_record_damage_contribution(root.selected_unit, enemy, 32, dealt, hp_before, "", stone_attack_token)
					enemy.apply_slow(2.5, 0.7)
					enemy.mark_threat(root.selected_unit)
					spawn_impact(enemy.global_position)
					stone_hits += 1
			root.selected_unit.play_skill()
			root._log("돌콩의 석맥 파동이 적 %d명에게 피해와 둔화를 줬습니다." % stone_hits)
		"war_rhythm":
			var guarded := 0
			for ally in root.monster_units:
				if is_instance_valid(ally) and ally.is_alive() and ally.current_room == root.selected_unit.current_room:
					ally.activate_guard(7.0, 2)
					guarded += 1
			root.selected_unit.play_skill()
			if guarded > 0 and root.has_method("_record_update3_duo_link_action"):
				root._record_update3_duo_link_action("mon_contract_dudum", "buffed_ally", guarded, "war_rhythm:%d:%d" % [root.selected_unit.get_instance_id(), Time.get_ticks_usec()])
			spawn_effect_burst("guard", root.selected_unit.global_position, Vector2(0, -22), Vector2(1.05, 0.95), 12.0)
			root._log("두둠의 진군 장단이 같은 방 아군 %d명의 방어력을 올렸습니다." % guarded)
		"steady_beat":
			var recovered := 0
			for ally in root.monster_units:
				if is_instance_valid(ally) and ally.is_alive() and ally.current_room == root.selected_unit.current_room:
					ally.heal(18)
					recovered += 1
			root.selected_unit.play_skill()
			spawn_effect_burst("shield", root.selected_unit.global_position, Vector2(0, -18), Vector2(0.9, 0.9), 10.0)
			root._log("두둠의 버팀 박자가 같은 방 아군 %d명을 회복했습니다." % recovered)
		"moon_mark":
			var moon_target = prepared_target
			var moon_hp_before := int(moon_target.hp)
			var moon_damage := DamageService.compute(root.selected_unit, moon_target, 1.65)
			var moon_dealt: int = moon_target.receive_magic_damage(moon_damage)
			_record_damage_contribution(root.selected_unit, moon_target, moon_damage, moon_dealt, moon_hp_before, "", "moon_mark:%d:%d" % [root.selected_unit.get_instance_id(), Time.get_ticks_usec()])
			moon_target.apply_taunt(root.selected_unit, 6.0)
			if moon_dealt > 0 and root.has_method("_record_update3_duo_link_action"):
				root._record_update3_duo_link_action("mon_contract_lumi", "mark_success", 1, "moon_mark_link:%d:%d" % [root.selected_unit.get_instance_id(), moon_target.get_instance_id()])
			_mark_action_target(root.selected_unit, moon_target)
			root.selected_unit.play_attack(moon_target.global_position)
			spawn_effect_burst("fireball", moon_target.global_position, Vector2(0, -24), Vector2(0.75, 0.75), 11.0)
			root._log("루미가 %s에게 달빛 표식을 남겨 %d 피해를 줬습니다." % [moon_target.display_name, moon_dealt])
		"scent_pursuit":
			var scent_target = prepared_target
			var scent_hp_before := int(scent_target.hp)
			var scent_damage := DamageService.compute(root.selected_unit, scent_target, 1.25)
			var scent_dealt: int = scent_target.receive_damage(scent_damage)
			_record_damage_contribution(root.selected_unit, scent_target, scent_damage, scent_dealt, scent_hp_before, "", "scent_pursuit:%d:%d" % [root.selected_unit.get_instance_id(), Time.get_ticks_usec()])
			scent_target.apply_slow(2.0, 0.75)
			scent_target.mark_threat(root.selected_unit)
			_mark_action_target(root.selected_unit, scent_target)
			root.selected_unit.play_attack(scent_target.global_position)
			spawn_slash(scent_target.global_position, MELEE_CONTACT_DELAY)
			root._log("루미가 달향을 쫓아 %s에게 %d 피해를 줬습니다." % [scent_target.display_name, scent_dealt])
		"false_treasure":
			var lured := 0
			for enemy in root.enemy_units:
				if is_instance_valid(enemy) and enemy.is_alive() and root.selected_unit.global_position.distance_to(enemy.global_position) <= 250.0:
					enemy.apply_slow(3.0, 0.66)
					enemy.apply_taunt(root.selected_unit, 5.0)
					lured += 1
			root.selected_unit.play_skill()
			if lured > 0 and root.has_method("_record_update3_duo_link_action"):
				root._record_update3_duo_link_action("mon_contract_mimi", "false_treasure_contact", 1, "false_treasure:%d:%d" % [root.selected_unit.get_instance_id(), Time.get_ticks_usec()])
			spawn_effect_burst("loot", root.selected_unit.global_position, Vector2(0, -18), Vector2(1.12, 1.0), 12.0)
			root._log("미미의 가짜 보물이 적 %d명을 유인했습니다." % lured)
		"vault_swap":
			var rescue_target = _lowest_health_monster(false)
			if rescue_target == null:
				rescue_target = root.selected_unit
			rescue_target.heal(30)
			if rescue_target != root.selected_unit:
				rescue_target.global_position = root.selected_unit.global_position + Vector2(24, 0)
				rescue_target.current_room = root.selected_unit.current_room
			root.selected_unit.play_skill()
			spawn_effect_burst("loot", rescue_target.global_position, Vector2(0, -18), Vector2(0.92, 0.92), 10.0)
			root._log("미미가 %s을 금고 뒤로 빼내고 체력을 30 회복했습니다." % rescue_target.display_name)
		"spectral_transfer":
			perform_bebe_rescue(root.selected_unit, prepared_target)
		"haunted_broom_whirl":
			perform_bebe_broom(root.selected_unit)
		"scent_lock":
			perform_koko_scent_lock(root.selected_unit, prepared_target)
		"home_guard_bark":
			perform_koko_home_guard_bark(root.selected_unit)
		"carapace_ram":
			perform_toktok_carapace_ram(root.selected_unit, prepared_target)
		"patch_plates":
			perform_toktok_patch_plates(root.selected_unit, prepared_target, _toktok_facility_repair_target(root.selected_unit))
		_:
			root.selected_unit.play_skill()
			root._log("%s 사용." % skill.get("display_name", skill_id))
	var cooldown := maxf(0.0, float(skill.get("cooldown", 5.0)) - _combat_skill_float(root.selected_unit.unit_id, skill_id, "cooldown_reduction", 0.0))
	root.selected_unit.set_skill_cooldown(skill_id, cooldown)
	record_ledger_skill_use(root.selected_unit, skill_id)
	return true


func use_unit_skill_for_ai(unit: Node, slot: int) -> bool:
	if unit == null or not is_instance_valid(unit) or unit.faction != Constants.FACTION_MONSTER or not unit.is_alive():
		return false
	var skill_slots: Array = DataRegistry.monster(unit.unit_id).get("skill_slots", [])
	if slot < 0 or slot >= skill_slots.size() or skill_slots[slot] == null:
		return false
	var skill_id := str(skill_slots[slot])
	var previous_selection = root.selected_unit
	root.selected_unit = unit
	var used := _execute_selected_unit_skill(slot)
	root.selected_unit = previous_selection
	if not used:
		return false
	if root.has_method("_tutorial_emit_action"):
		root._tutorial_emit_action("skill_used", {"skill_id": skill_id, "unit_id": unit.unit_id})
		if skill_id == "fireball":
			root._tutorial_emit_action("imp_casts_fireball", {"skill_id": skill_id, "unit_id": unit.unit_id})
	if skill_id == "fireball" and root.has_method("_onboarding_emit_trigger"):
		root._onboarding_emit_trigger("imp_fireball")
	return true


func _flame_zone_targets() -> Array:
	var result: Array = []
	var target_rooms := ["spike_corridor", _barracks_room()]
	for enemy in root.enemy_units:
		if is_instance_valid(enemy) and enemy.is_alive() and target_rooms.has(enemy.current_room):
			result.append(enemy)
	return result


func _update_active_flame_zones(delta: float) -> void:
	for index in range(active_flame_zones.size() - 1, -1, -1):
		var zone: Dictionary = active_flame_zones[index]
		zone["remaining"] = float(zone.get("remaining", 0.0)) - delta
		if float(zone["remaining"]) <= 0.0:
			active_flame_zones.remove_at(index)
			continue
		var affected_ids: Dictionary = zone.get("affected_ids", {})
		var room_ids: Array = zone.get("room_ids", [])
		var source = zone.get("source")
		for enemy in root.enemy_units:
			if not is_instance_valid(enemy) or not enemy.is_alive() or affected_ids.has(enemy.get_instance_id()) or not room_ids.has(enemy.current_room):
				continue
			var requested_damage := int(zone.get("damage", 0))
			var hp_before := int(enemy.hp)
			var dealt_damage = enemy.receive_magic_damage(requested_damage)
			if is_instance_valid(source):
				_record_damage_contribution(source, enemy, requested_damage, dealt_damage, hp_before, "", "flame_zone_tick:%d:%d" % [source.get_instance_id(), enemy.get_instance_id()])
				enemy.mark_threat(source)
			enemy.apply_slow(float(zone.get("slow_seconds", 2.5)), float(zone.get("slow_factor", 0.7)))
			_apply_combat_hit_feedback(source, enemy, dealt_damage, false)
			spawn_impact(enemy.global_position)
			affected_ids[enemy.get_instance_id()] = true
		zone["affected_ids"] = affected_ids
		active_flame_zones[index] = zone


func _lowest_health_monster(same_room_only: bool) -> Node:
	var result: Node = null
	var lowest_ratio := 2.0
	for ally in root.monster_units:
		if not is_instance_valid(ally) or not ally.is_alive():
			continue
		if same_room_only and ally.current_room != root.selected_unit.current_room:
			continue
		var ratio := float(ally.hp) / maxf(1.0, float(ally.max_hp))
		if ratio < lowest_ratio:
			lowest_ratio = ratio
			result = ally
	return result


func try_bebe_auto_rescue(bebe: Node) -> bool:
	if bebe == null or not is_instance_valid(bebe) or not bebe.is_alive() or not bebe.skill_ready("spectral_transfer"):
		return false
	if bebe.has_method("active_skills_locked") and bebe.active_skills_locked():
		return false
	var target := _bebe_rescue_target(bebe, 0.32)
	if target == null:
		return false
	var skill: Dictionary = DataRegistry.skill("spectral_transfer")
	var cost := int(skill.get("cost_mana", 16))
	if GameState.mana < cost:
		return false
	GameState.mana -= cost
	SignalBus.resources_changed.emit()
	var result := perform_bebe_rescue(bebe, target)
	var cooldown := maxf(0.0, float(skill.get("cooldown", 11.0)) - _combat_skill_float(bebe.unit_id, "spectral_transfer", "cooldown_reduction", 0.0))
	bebe.set_skill_cooldown("spectral_transfer", cooldown)
	if bool(result.get("ok", false)):
		_play_skill_sfx("spectral_transfer")
		record_ledger_skill_use(bebe, "spectral_transfer")
	return bool(result.get("ok", false))


func perform_bebe_rescue(bebe: Node, target: Node = null) -> Dictionary:
	if bebe == null or not is_instance_valid(bebe) or not bebe.is_alive():
		return {"ok": false, "moved": false, "reason": "invalid_bebe"}
	if bebe.has_method("active_skills_locked") and bebe.active_skills_locked():
		return {"ok": false, "moved": false, "reason": "skill_locked"}
	if target == null:
		target = _bebe_rescue_target(bebe, 1.0)
	if target == null or not is_instance_valid(target) or not target.is_alive():
		return {"ok": false, "moved": false, "reason": "no_target"}
	var cleansed_room := str(target.current_room)
	var ledger_cleansed := cleanse_ledger_room(cleansed_room, "베베")
	var shield := 20 + int(_combat_skill_float(bebe.unit_id, "spectral_transfer", "shield_bonus", 0.0))
	var specialization: Dictionary = root._monster_specialization(bebe.unit_id) if root.has_method("_monster_specialization") else {}
	shield = maxi(0, shield - int(specialization.get("rescue_shield_penalty", 0)))
	target.grant_duo_barrier(shield)
	var route := _bebe_safe_route(bebe, target, 110.0)
	var moved := not route.is_empty()
	if moved:
		target.set_path(route)
		var destination: Vector2 = route[-1]
		move_unit_to_point(bebe, root._clamp_to_combat_walkable(destination + Vector2(18, 0)))
		target.apply_rescue_phase(0.8)
		bebe.apply_rescue_phase(0.8)
		target.set_tactical_state(Constants.UNIT_STATE_RETREAT, "베베 긴급 구조", _room_name(str(target.assigned_room)))
	else:
		target.stop_navigation()
	bebe.play_skill()
	spawn_effect_burst("bebe_rescue", target.global_position, Vector2(0, -22), Vector2(0.9, 0.9), 11.0)
	root._log("베베가 %s을 구조했습니다%s." % [target.display_name, "" if moved else "(안전 셀 없음·보호막만 적용)"])
	if root.has_method("_record_update3_duo_link_action"):
		root._record_update3_duo_link_action("monster_bebe", "rescue_success", 1, "bebe_rescue:%d:%d" % [target.get_instance_id(), Time.get_ticks_usec()])
	return {"ok": true, "moved": moved, "target": target, "shield": shield, "route": route, "ledger_cleansed": ledger_cleansed, "cleansed_room": cleansed_room}


func _bebe_rescue_target(bebe: Node, maximum_hp_ratio: float) -> Node:
	var in_range: Array = []
	for ally in root.monster_units:
		if ally == bebe or not is_instance_valid(ally) or not ally.is_alive():
			continue
		var hp_ratio := float(ally.hp) / maxf(1.0, float(ally.max_hp))
		if hp_ratio > maximum_hp_ratio or bebe.global_position.distance_to(ally.global_position) > 220.0:
			continue
		in_range.append(ally)
	if in_range.is_empty():
		return null
	var throne_under_attack := false
	for enemy in root.enemy_units:
		if is_instance_valid(enemy) and enemy.is_alive() and str(enemy.current_room) == _core_room():
			throne_under_attack = true
			break
	in_range.sort_custom(func(a: Node, b: Node):
		if throne_under_attack and str(a.current_room) != str(b.current_room):
			if str(a.current_room) == _core_room():
				return true
			if str(b.current_room) == _core_room():
				return false
		return float(a.hp) / maxf(1.0, float(a.max_hp)) < float(b.hp) / maxf(1.0, float(b.max_hp)))
	return in_range[0]


func _bebe_safe_route(bebe: Node, target: Node, max_distance: float) -> Array:
	if root.graph == null or not root.graph.has_method("path_to_point"):
		return []
	var candidate_rooms: Array[String] = []
	for room_id_value in [target.assigned_room, root._room_by_facility("recovery", ""), bebe.assigned_room]:
		var room_id := str(room_id_value)
		if room_id != "" and root.rooms.has(room_id) and not candidate_rooms.has(room_id) and _living_enemy_count_in_room(room_id) == 0:
			candidate_rooms.append(room_id)
	for room_id in candidate_rooms:
		var route := _limited_walkable_route(target.global_position, root.graph.center(room_id), max_distance)
		if not route.is_empty():
			return route
	var away := Vector2.ZERO
	for enemy in root.enemy_units:
		if is_instance_valid(enemy) and enemy.is_alive() and str(enemy.current_room) == str(target.current_room):
			away += target.global_position - enemy.global_position
	if away.length() <= 0.01:
		return []
	return _limited_walkable_route(target.global_position, target.global_position + away.normalized() * max_distance, max_distance)


func _limited_walkable_route(from: Vector2, desired: Vector2, max_distance: float) -> Array:
	var clamped: Vector2 = root._clamp_to_combat_walkable(desired)
	var raw_route: Array = root.graph.path_to_point(from, clamped)
	if raw_route.is_empty():
		return []
	var result: Array = []
	var previous := from
	var remaining := max_distance
	for point_value in raw_route:
		var point: Vector2 = point_value
		var segment := previous.distance_to(point)
		if segment <= remaining:
			result.append(point)
			remaining -= segment
			previous = point
		else:
			if segment > 0.0:
				result.append(previous.lerp(point, remaining / segment))
			break
	if result.is_empty() or from.distance_to(result[-1]) < 4.0:
		return []
	return result


func _living_enemy_count_in_room(room_id: String) -> int:
	var count := 0
	for enemy in root.enemy_units:
		if is_instance_valid(enemy) and enemy.is_alive() and str(enemy.current_room) == room_id:
			count += 1
	return count


func perform_bebe_broom(bebe: Node) -> Dictionary:
	var skill: Dictionary = DataRegistry.skill("haunted_broom_whirl")
	var targets := _bebe_broom_targets(bebe, float(skill.get("radius", 85.0)))
	var damage_multiplier := float(skill.get("damage_multiplier", 0.9)) + _combat_skill_float(bebe.unit_id, "haunted_broom_whirl", "damage_multiplier_bonus", 0.0)
	var damage := maxi(1, int(round(float(bebe.atk) * damage_multiplier + float(skill.get("damage_flat", 8.0)))))
	var knockback := float(skill.get("knockback", 24.0)) + _combat_skill_float(bebe.unit_id, "haunted_broom_whirl", "knockback_bonus", 0.0)
	var interrupted := 0
	for enemy in targets:
		var hp_before := int(enemy.hp)
		var dealt: int = enemy.receive_damage(damage)
		_record_damage_contribution(bebe, enemy, damage, dealt, hp_before, "", "bebe_broom:%d:%d" % [bebe.get_instance_id(), enemy.get_instance_id()])
		if not _bebe_broom_boss(enemy):
			var away: Vector2 = (enemy.global_position - bebe.global_position).normalized()
			enemy.global_position += away * knockback
			enemy.stop_navigation()
			if enemy.skill_anim_timer > 0.0:
				enemy.apply_action_interrupt(float(skill.get("interrupt_seconds", 0.35)))
				interrupted += 1
		spawn_impact(enemy.global_position)
	bebe.play_skill()
	spawn_effect_burst("bebe_broom", bebe.global_position, Vector2(0, -18), Vector2(1.0, 1.0), 12.0)
	root._log("베베의 빗자루 소동이 %d명을 맞히고 %d명의 시전을 끊었습니다." % [targets.size(), interrupted])
	return {"ok": true, "targets": targets.size(), "interrupted": interrupted, "damage": damage}


func perform_koko_scent_lock(tracker: Node, target: Node = null) -> Dictionary:
	if tracker == null or not is_instance_valid(tracker) or not tracker.is_alive():
		return {"ok": false, "reason": "invalid_tracker"}
	if target == null:
		target = _danger_tracker_target(tracker)
	if target == null or not is_instance_valid(target) or not target.is_alive():
		return {"ok": false, "reason": "no_target"}
	var skill: Dictionary = DataRegistry.skill("scent_lock")
	var specialization: Dictionary = root._monster_specialization(str(tracker.unit_id)) if root.has_method("_monster_specialization") else {}
	var duration := float(skill.get("duration", 7.0)) + _combat_skill_float(str(tracker.unit_id), "scent_lock", "duration_bonus", 0.0)
	var attack_multiplier := float(skill.get("marked_basic_attack_multiplier", 1.10))
	if bool(specialization.get("remove_marked_damage_bonus", false)):
		attack_multiplier = 1.0
	else:
		attack_multiplier += _combat_skill_float(str(tracker.unit_id), "scent_lock", "marked_basic_attack_multiplier_bonus", 0.0)
	tracker.start_scent_mark(target, duration, float(skill.get("tracking_move_multiplier", 1.25)), attack_multiplier)
	tracker.play_skill(target.global_position)
	tracker.mark_action_target(target, 0.8)
	tracker.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "냄새 고정", target.display_name)
	spawn_effect_burst("koko_scent", target.global_position, Vector2(0, -22), Vector2(0.9, 0.9), 11.0)
	root._log("%s가 %s의 냄새를 %.1f초 동안 고정했습니다." % [tracker.display_name, target.display_name, duration])
	return {"ok": true, "target": target, "duration": duration, "attack_multiplier": attack_multiplier}


func perform_koko_home_guard_bark(tracker: Node) -> Dictionary:
	if tracker == null or not is_instance_valid(tracker) or not tracker.is_alive():
		return {"ok": false, "reason": "invalid_tracker"}
	var skill: Dictionary = DataRegistry.skill("home_guard_bark")
	var specialization: Dictionary = root._monster_specialization(str(tracker.unit_id)) if root.has_method("_monster_specialization") else {}
	var radius := float(skill.get("radius", 145.0))
	var max_normal := int(skill.get("max_normal_targets", 2)) + int(specialization.get("skill_upgrade", {}).get("max_targets_bonus", 0))
	var normal_taunt := float(skill.get("normal_taunt_seconds", 2.5))
	var boss_priority := float(skill.get("boss_priority_seconds", 1.5))
	var candidates: Array = []
	for enemy in root.enemy_units:
		if is_instance_valid(enemy) and enemy.is_alive() and tracker.global_position.distance_to(enemy.global_position) <= radius:
			candidates.append(enemy)
	candidates.sort_custom(func(a, b): return tracker.global_position.distance_squared_to(a.global_position) < tracker.global_position.distance_squared_to(b.global_position))
	var normal_affected := 0
	var boss_affected := 0
	for enemy in candidates:
		if _bebe_broom_boss(enemy):
			enemy.apply_taunt(tracker, boss_priority)
			boss_affected += 1
		elif normal_affected < max_normal:
			enemy.apply_taunt(tracker, normal_taunt)
			normal_affected += 1
	var shield := maxi(0, int(skill.get("shield", 18)) - int(specialization.get("skill_upgrade", {}).get("bark_shield_penalty", 0)))
	tracker.grant_duo_barrier(shield)
	var bark_reduction := float(specialization.get("bark_damage_reduction", 0.0))
	if bark_reduction > 0.0 and normal_affected > 0:
		tracker.apply_home_guard_reduction(normal_taunt, bark_reduction)
	tracker.play_skill()
	tracker.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "집 지키는 짖음", "%d명 도발" % (normal_affected + boss_affected))
	spawn_effect_burst("koko_bark", tracker.global_position, Vector2(0, -20), Vector2(1.22, 1.08), 13.0)
	root._log("%s의 집 지키는 짖음: 일반 %d명·보스 %d명, 보호막 %d." % [tracker.display_name, normal_affected, boss_affected, shield])
	return {"ok": true, "normal_targets": normal_affected, "boss_targets": boss_affected, "shield": shield}


func _toktok_patch_ally_target(toktok: Node) -> Node:
	var selected_room := str(root.selected_room)
	if selected_room != "" and root.rooms.has(selected_room):
		var selected_data: Dictionary = root.rooms[selected_room]
		var selected_max := int(selected_data.get("max_hp", selected_data.get("hp", 0)))
		if int(selected_data.get("hp", selected_max)) < selected_max and _toktok_facility_in_range(toktok, selected_room):
			return null
	var selected: Node = null
	var lowest_ratio := 1.01
	var patch_range := float(DataRegistry.skill("patch_plates").get("range", 120.0))
	for ally in root.monster_units:
		if not is_instance_valid(ally) or not ally.is_alive() or toktok.global_position.distance_to(ally.global_position) > patch_range:
			continue
		if ally.patch_plate_barrier > 0 and ally.patch_plate_barrier_timer > 0.0:
			continue
		var ratio := float(ally.hp) / maxf(1.0, float(ally.max_hp))
		if ratio < lowest_ratio:
			lowest_ratio = ratio
			selected = ally
	return selected


func _toktok_ram_path_clear(toktok: Node, desired_end: Vector2) -> bool:
	var distance: float = toktok.global_position.distance_to(desired_end)
	if distance <= 0.01:
		return false
	var sample_count := maxi(2, ceili(distance / 12.0))
	for index in range(1, sample_count + 1):
		var point: Vector2 = toktok.global_position.lerp(desired_end, float(index) / float(sample_count))
		var clamped: Vector2 = root._clamp_to_combat_walkable(point)
		if clamped.distance_to(point) > 3.0:
			return false
	return true


func _toktok_first_ram_collision(toktok: Node, desired_target: Node, max_distance: float) -> Node:
	var direction: Vector2 = (desired_target.global_position - toktok.global_position).normalized()
	if direction == Vector2.ZERO:
		return desired_target
	var selected: Node = null
	var nearest_projection := INF
	for enemy in root.enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive():
			continue
		var offset: Vector2 = enemy.global_position - toktok.global_position
		var projection := offset.dot(direction)
		if projection < 0.0 or projection > max_distance:
			continue
		var perpendicular := absf(offset.cross(direction))
		if perpendicular <= 24.0 and projection < nearest_projection:
			nearest_projection = projection
			selected = enemy
	return selected


func perform_toktok_carapace_ram(toktok: Node, desired_target: Node = null) -> Dictionary:
	if toktok == null or not is_instance_valid(toktok) or not toktok.is_alive():
		return {"ok": false, "reason": "invalid_toktok"}
	if desired_target == null:
		desired_target = _toktok_ram_target(toktok)
	if desired_target == null or not is_instance_valid(desired_target) or not desired_target.is_alive():
		return {"ok": false, "reason": "no_target"}
	var max_distance := _toktok_ram_distance(toktok)
	var target_distance: float = toktok.global_position.distance_to(desired_target.global_position)
	if target_distance > max_distance:
		return {"ok": false, "reason": "out_of_range", "max_distance": max_distance}
	var direction: Vector2 = (desired_target.global_position - toktok.global_position).normalized()
	var desired_end: Vector2 = toktok.global_position + direction * minf(max_distance, target_distance)
	if not _toktok_ram_path_clear(toktok, desired_end):
		root._log("톡톡의 갑각 돌진 경로에 벽이 있어 돌진을 취소했습니다.")
		return {"ok": false, "reason": "wall_blocked"}
	var target := _toktok_first_ram_collision(toktok, desired_target, max_distance)
	if target == null:
		return {"ok": false, "reason": "no_collision"}
	var collision_direction: Vector2 = (target.global_position - toktok.global_position).normalized()
	var stop_point: Vector2 = target.global_position - collision_direction * 22.0
	toktok.global_position = root._clamp_to_combat_walkable(stop_point)
	toktok.current_room = str(target.current_room)
	toktok.action_direction = collision_direction
	var skill: Dictionary = DataRegistry.skill("carapace_ram")
	var specialization: Dictionary = root._monster_specialization(str(toktok.unit_id)) if root.has_method("_monster_specialization") else {}
	var damage := int(round(float(skill.get("damage_flat", 20)) + float(toktok.atk) * float(skill.get("atk_multiplier", 0.8))))
	damage = maxi(1, int(round(float(damage) * (1.0 + _combat_skill_float(str(toktok.unit_id), "carapace_ram", "damage_multiplier_bonus", 0.0)))))
	var barrier_before := int(target.duo_barrier) + int(target.patch_plate_barrier)
	var hp_before := int(target.hp)
	var dealt := int(target.receive_damage(damage))
	_record_damage_contribution(toktok, target, damage, dealt, hp_before, "", "toktok_ram:%d:%d" % [toktok.get_instance_id(), target.get_instance_id()])
	var boss := _bebe_broom_boss(target)
	var reduction := int(skill.get("boss_def_reduction", 1)) if boss else int(skill.get("normal_def_reduction", 2))
	reduction += int(specialization.get("skill_upgrade", {}).get("def_reduction_bonus", 0))
	var duration := float(skill.get("boss_duration", 4.0)) if boss else float(skill.get("normal_duration", 5.0))
	var armor_applied: bool = target.is_alive() and target.apply_armor_break(reduction, duration, str(toktok.unit_id))
	var max_scrap := int(DataRegistry.skill("scrap_shell").get("max_stacks", 3))
	if armor_applied:
		toktok.add_scrap_stack(1, max_scrap)
		spawn_effect_burst("toktok_scrap", toktok.global_position, Vector2(0, -18), Vector2(0.72, 0.72), 10.0)
		if root.has_method("_record_update3_duo_link_action"):
			root._record_update3_duo_link_action("monster_toktok", "armor_break_or_repair", 1, "toktok_break:%d:%d" % [target.get_instance_id(), Time.get_ticks_usec()])
	var barrier_after := int(target.duo_barrier) + int(target.patch_plate_barrier)
	if barrier_before > 0 and barrier_after <= 0:
		toktok.add_scrap_stack(1, max_scrap)
	toktok.stop_navigation()
	toktok.play_skill(target.global_position)
	toktok.mark_action_target(target, 0.8)
	spawn_effect_burst("toktok_impact", target.global_position, Vector2(0, -18), Vector2(1.0, 0.85), 12.0)
	root._log("톡톡의 갑각 돌진: %s에게 %d 피해, 방어력 -%d(%.1f초)." % [target.display_name, dealt, reduction, duration])
	return {"ok": true, "target": target, "damage": dealt, "def_reduction": reduction, "duration": duration, "boss": boss, "scrap": toktok.scrap_stacks}


func perform_toktok_patch_plates(toktok: Node, ally_target: Node = null, facility_room_id: String = "") -> Dictionary:
	if toktok == null or not is_instance_valid(toktok) or not toktok.is_alive():
		return {"ok": false, "reason": "invalid_toktok"}
	var skill: Dictionary = DataRegistry.skill("patch_plates")
	var specialization: Dictionary = root._monster_specialization(str(toktok.unit_id)) if root.has_method("_monster_specialization") else {}
	if ally_target == null and facility_room_id == "":
		ally_target = _toktok_patch_ally_target(toktok)
	if facility_room_id == "" and ally_target == null:
		facility_room_id = _toktok_facility_repair_target(toktok)
	var stacks := int(toktok.scrap_stacks)
	var stack_bonus := stacks * int(skill.get("scrap_bonus_per_stack", 8))
	if ally_target != null and is_instance_valid(ally_target) and ally_target.is_alive() and toktok.global_position.distance_to(ally_target.global_position) <= float(skill.get("range", 120.0)):
		var shield := int(skill.get("ally_shield", 28)) + stack_bonus + int(specialization.get("ally_shield_bonus", 0))
		ally_target.grant_patch_plate_barrier(shield, float(skill.get("shield_duration", 5.0)))
		toktok.consume_scrap_stacks()
		toktok.play_skill(ally_target.global_position)
		spawn_effect_burst("toktok_patch", ally_target.global_position, Vector2(0, -18), Vector2(0.9, 0.9), 11.0)
		root._log("톡톡이 %s에게 판금 보호막 %d를 덧댔습니다." % [ally_target.display_name, shield])
		return {"ok": true, "kind": "ally", "target": ally_target, "shield": shield, "stacks_used": stacks}
	if facility_room_id != "" and _toktok_facility_in_range(toktok, facility_room_id):
		var repair := int(skill.get("facility_repair", 35)) + stack_bonus + int(specialization.get("facility_repair_bonus", 0)) - int(specialization.get("facility_repair_penalty", 0))
		repair = int(round(float(repair) * toktok.repair_output_multiplier()))
		var result: Dictionary = root._repair_update3_facility(facility_room_id, maxi(0, repair), "toktok_patch:%d:%d" % [toktok.get_instance_id(), Time.get_ticks_usec()])
		if not bool(result.get("ok", false)) or int(result.get("effective_repair", result.get("repair", 0))) <= 0:
			return {"ok": false, "reason": "repair_not_needed", "room_id": facility_room_id}
		toktok.consume_scrap_stacks()
		toktok.remove_meta("patch_facility_target")
		toktok.play_skill(root.graph.center(facility_room_id) if root.graph != null else toktok.global_position)
		spawn_effect_burst("toktok_patch", root.graph.center(facility_room_id) if root.graph != null else toktok.global_position, Vector2(0, -18), Vector2(1.0, 0.9), 12.0)
		root._log("톡톡이 %s을(를) %d 수리했습니다." % [_room_name(facility_room_id), int(result.get("effective_repair", result.get("repair", 0)))])
		if root.has_method("_record_update3_metric_count"):
			root._record_update3_metric_count("toktok_facility_repairs", 1)
		return {"ok": true, "kind": "facility", "room_id": facility_room_id, "repair": int(result.get("effective_repair", result.get("repair", 0))), "stacks_used": stacks, "room_hp": int(result.get("room_hp", 0))}
	return {"ok": false, "reason": "no_patch_target"}


func notify_toktok_facility_hit(room_id: String, damage: int) -> int:
	if damage < int(DataRegistry.skill("scrap_shell").get("facility_hit_threshold", 30)):
		return 0
	var awarded := 0
	for monster in root.monster_units:
		if is_instance_valid(monster) and monster.is_alive() and str(monster.unit_id) == "armored_beetle" and (str(monster.current_room) == room_id or str(monster.assigned_room) == room_id):
			monster.add_scrap_stack(1, int(DataRegistry.skill("scrap_shell").get("max_stacks", 3)))
			spawn_effect_burst("toktok_scrap", monster.global_position, Vector2(0, -18), Vector2(0.72, 0.72), 10.0)
			awarded += 1
	return awarded


func estimate_toktok_intercept_seconds(toktok_stats: Dictionary, target_stats: Dictionary, distance: float, armor_broken: bool = false) -> float:
	var move_seconds := maxf(0.0, distance) / maxf(1.0, float(toktok_stats.get("move_speed", 1.0)))
	var target_def := int(target_stats.get("def", 0)) - (int(DataRegistry.skill("carapace_ram").get("normal_def_reduction", 2)) if armor_broken else 0)
	var attack_damage := maxi(1, int(round(float(toktok_stats.get("atk", 1)) - float(maxi(0, target_def)) * 0.5)))
	var attacks := ceili(float(maxi(1, int(target_stats.get("max_hp", 1)))) / float(attack_damage))
	return move_seconds + float(attacks) * float(toktok_stats.get("attack_interval", 1.0))


func estimate_tracker_intercept_seconds(tracker_stats: Dictionary, target_stats: Dictionary, distance: float, marked: bool) -> float:
	var skill: Dictionary = DataRegistry.skill("scent_lock")
	var speed := maxf(1.0, float(tracker_stats.get("move_speed", 1.0)))
	var damage := maxi(1, int(tracker_stats.get("atk", 1)) - int(target_stats.get("def", 0)))
	var acquisition_seconds := 2.0
	if marked:
		speed *= float(skill.get("tracking_move_multiplier", 1.25))
		damage = maxi(1, int(round(float(damage) * float(skill.get("marked_basic_attack_multiplier", 1.10)))))
		acquisition_seconds = 0.0
	var attacks := ceili(float(maxi(1, int(target_stats.get("max_hp", 1)))) / float(damage))
	return acquisition_seconds + maxf(0.0, distance) / speed + float(attacks) * float(tracker_stats.get("attack_interval", 1.0))


func _bebe_broom_targets(bebe: Node, radius: float) -> Array:
	var result: Array = []
	var facing: Vector2 = bebe.action_direction.normalized()
	if facing == Vector2.ZERO:
		facing = Vector2.RIGHT
	for enemy in root.enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive():
			continue
		var offset: Vector2 = enemy.global_position - bebe.global_position
		if offset.length() <= radius and (offset.length() <= 0.01 or facing.dot(offset.normalized()) >= 0.5):
			result.append(enemy)
	return result


func _bebe_broom_boss(enemy: Node) -> bool:
	return str(enemy.unit_id) in ["trainee_hero", "official_hero_leon", "official_paladin_selen", "guild_commissioner_roman", "selen_trainee_paladin", "roman"]

func _combat_skill_float(monster_id: String, skill_id: String, key: String, fallback: float = 0.0) -> float:
	if root.has_method("_combat_skill_float"):
		return root._combat_skill_float(monster_id, skill_id, key, fallback)
	return fallback

func set_speed(speed: float) -> void:
	root.combat_speed = clampf(speed, 1.0, 3.0)
	_sync_unit_simulation_speed()
	root._log("전투 속도 x%.1f." % root.combat_speed)

func _visual_seconds(seconds: float) -> float:
	return seconds / clampf(root.combat_speed, 1.0, 3.0)

func toggle_pause() -> void:
	root.combat_paused = not root.combat_paused
	for unit in root.monster_units + root.enemy_units:
		if is_instance_valid(unit):
			unit.set_physics_process(not root.combat_paused)
	root._log("일시정지." if root.combat_paused else "전투 재개.")

func spawn_projectile(from_position: Vector2, to_position: Vector2, on_arrival: Callable = Callable()) -> void:
	var sprite = _make_effect_sprite("fireball", true, 14.0)
	if sprite == null:
		if on_arrival.is_valid():
			on_arrival.call()
		return
	sprite.global_position = from_position
	sprite.z_index = 3000
	sprite.rotation = from_position.angle_to_point(to_position)
	root.effect_root.add_child(sprite)
	var tween = root.create_tween()
	tween.tween_property(sprite, "global_position", to_position, _visual_seconds(PROJECTILE_TRAVEL_SECONDS))
	if on_arrival.is_valid():
		tween.tween_callback(on_arrival)
	tween.tween_callback(Callable(self, "spawn_impact").bind(to_position))
	tween.tween_callback(sprite.queue_free)

func _launch_damage_projectile(attacker: Node, target: Node, damage: int, force_camera_kick: bool, hit_kind: String) -> void:
	if attacker == null or target == null or not is_instance_valid(attacker) or not is_instance_valid(target):
		return
	_mark_action_target(attacker, target)
	var arrival = Callable(self, "_resolve_projectile_damage").bind(
		attacker.get_instance_id(),
		target.get_instance_id(),
		attacker.global_position,
		str(attacker.unit_id),
		str(attacker.display_name),
		damage,
		force_camera_kick,
		hit_kind
	)
	spawn_projectile(attacker.global_position, target.global_position, arrival)

func _resolve_projectile_damage(attacker_instance_id: int, target_instance_id: int, source_position: Vector2, attacker_unit_id: String, attacker_name: String, damage: int, force_camera_kick: bool, hit_kind: String) -> void:
	var target = instance_from_id(target_instance_id)
	if target == null or not is_instance_valid(target) or not target.is_alive():
		return
	var attacker = instance_from_id(attacker_instance_id)
	var hp_before = int(target.hp)
	var dealt_damage = target.receive_magic_damage(damage) if hit_kind == "fireball" else target.receive_damage(damage)
	_record_damage_contribution(attacker, target, damage, dealt_damage, hp_before, attacker_unit_id)
	if attacker_unit_id == "imp" and hit_kind == "fireball" and dealt_damage > 0 and root.has_method("_record_update3_duo_link_action"):
		root._record_update3_duo_link_action("mon_core_pynn", "fire_skill_hit", 1, "pynn_fire:%d:%d" % [target.get_instance_id(), Time.get_ticks_usec()])
	if attacker != null and is_instance_valid(attacker) and target.has_method("mark_threat"):
		target.mark_threat(attacker)
	if root.has_method("_onboarding_unit_damaged"):
		root._onboarding_unit_damaged(target)
	_show_combat_hit_feedback(source_position, attacker_unit_id, target, dealt_damage, force_camera_kick)
	if hit_kind == "fireball":
		root._log("화염구가 %s에게 %d 피해." % [target.display_name, dealt_damage])
	else:
		root._log("%s가 %s에게 %d 피해." % [attacker_name, target.display_name, dealt_damage])

func spawn_slash(position: Vector2, delay: float = 0.0) -> void:
	if delay > 0.0:
		var delayed_tween = root.create_tween()
		delayed_tween.tween_interval(_visual_seconds(delay))
		delayed_tween.tween_callback(Callable(self, "spawn_slash").bind(position, 0.0))
		return
	var sprite = _make_effect_sprite("slash", false, 18.0)
	if sprite == null:
		return
	sprite.global_position = position + Vector2(0, -18)
	sprite.scale = Vector2(0.72, 0.72)
	sprite.z_index = 3000
	root.effect_root.add_child(sprite)
	var tween = root.create_tween()
	tween.tween_property(sprite, "scale", Vector2(0.90, 0.90), _visual_seconds(0.10))
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, _visual_seconds(0.14))
	tween.tween_callback(sprite.queue_free)

func spawn_impact(position: Vector2) -> void:
	var sprite = _make_effect_sprite("impact", false, 16.0)
	if sprite == null:
		return
	sprite.global_position = position + Vector2(0, -20)
	sprite.scale = Vector2(0.72, 0.72)
	sprite.z_index = 3000
	root.effect_root.add_child(sprite)
	var tween = root.create_tween()
	tween.tween_property(sprite, "scale", Vector2(0.96, 0.96), _visual_seconds(0.16))
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, _visual_seconds(0.20))
	tween.tween_callback(sprite.queue_free)

func _apply_combat_hit_feedback(attacker: Node, target: Node, damage: int, force_camera_kick: bool = false, feedback_delay: float = MELEE_CONTACT_DELAY) -> void:
	if damage <= 0 or target == null or not is_instance_valid(target):
		return
	var source_position: Vector2 = attacker.global_position
	var attacker_id = str(attacker.unit_id)
	if feedback_delay > 0.0:
		var delayed_tween = root.create_tween()
		delayed_tween.tween_interval(_visual_seconds(feedback_delay))
		delayed_tween.tween_callback(Callable(self, "_show_combat_hit_feedback").bind(source_position, attacker_id, target, damage, force_camera_kick))
		return
	_show_combat_hit_feedback(source_position, attacker_id, target, damage, force_camera_kick)

func _show_combat_hit_feedback(source_position: Vector2, attacker_id: String, target, damage: int, force_camera_kick: bool) -> void:
	if target == null or not is_instance_valid(target):
		return
	if target.has_method("play_hit"):
		target.play_hit(source_position)
	spawn_damage_number(target.global_position, damage, target.faction)
	if not target.is_alive():
		_play_sfx(SFX_DOWN, "down", -7.0, 0.09, 0.94, 1.03)
	elif attacker_id == "slime":
		_play_sfx(SFX_SHIELD_BASH, "shield_bash", -8.5, 0.07, 0.94, 1.04)
	else:
		_play_sfx(SFX_HIT, "hit", -11.0, 0.045, 0.94, 1.07)
	if force_camera_kick or damage >= 30 or not target.is_alive():
		camera_kick(1.8 + min(3.2, float(damage) * 0.05))

func _play_attack_sfx(attacker: Node) -> void:
	if attacker == null or not is_instance_valid(attacker):
		return
	if attacker.faction == Constants.FACTION_MONSTER and attacker.unit_id == "slime":
		return
	if attacker.faction == Constants.FACTION_MONSTER and attacker.unit_id == "imp":
		_play_sfx(SFX_FIRE_BURST, "fire", -10.5, 0.08, 0.94, 1.04)
		return
	_play_sfx_delayed(SFX_SLASH, "slash", 0.055, -10.0, 0.055, 0.94, 1.07)

func _play_skill_sfx(skill_id: String) -> void:
	var stream: AudioStream = SKILL_SFX.get(skill_id)
	if stream == null:
		return
	_play_sfx(stream, "skill_%s" % skill_id, -7.5, 0.08, 0.98, 1.02)

func _play_sfx_delayed(stream: AudioStream, key: String, delay: float, volume_db: float, min_interval: float, pitch_min: float, pitch_max: float) -> void:
	if delay <= 0.0:
		_play_sfx(stream, key, volume_db, min_interval, pitch_min, pitch_max)
		return
	var tween = root.create_tween()
	tween.tween_interval(_visual_seconds(delay))
	tween.tween_callback(Callable(self, "_play_sfx").bind(stream, key, volume_db, min_interval, pitch_min, pitch_max))

func _play_sfx(stream: AudioStream, key: String, volume_db: float, min_interval: float, pitch_min: float = 1.0, pitch_max: float = 1.0) -> void:
	if stream == null or root == null or root.effect_root == null:
		return
	if float(sfx_cooldowns.get(key, 0.0)) > 0.0:
		return
	sfx_cooldowns[key] = min_interval
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = AudioSettings.SFX_BUS
	player.volume_db = volume_db
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	root.effect_root.add_child(player)
	player.finished.connect(Callable(player, "queue_free"))
	player.play()

func _update_sfx_cooldowns(delta: float) -> void:
	for key in sfx_cooldowns.keys():
		var remaining = max(0.0, float(sfx_cooldowns[key]) - delta)
		if remaining <= 0.0:
			sfx_cooldowns.erase(key)
		else:
			sfx_cooldowns[key] = remaining

func spawn_damage_number(position: Vector2, damage: int, target_faction: String) -> void:
	var damage_label = Label.new()
	var lane := _next_damage_number_lane(position)
	damage_label.text = "-%d" % damage
	var label_size = Vector2(66, 32)
	damage_label.position = position + Vector2(-label_size.x * 0.5, -112.0 - min(12.0, float(damage) * 0.12)) + DAMAGE_NUMBER_LANE_OFFSETS[lane]
	damage_label.size = label_size
	damage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.add_theme_font_override("font", UI_FONT)
	damage_label.add_theme_font_size_override("font_size", _damage_number_font_size(damage))
	var damage_color = Color("#ff8f84") if target_faction == Constants.FACTION_MONSTER else Color("#ffe078")
	if damage >= 40:
		damage_color = Color("#ffd2cb") if target_faction == Constants.FACTION_MONSTER else Color("#fff0a8")
	damage_label.add_theme_color_override("font_color", damage_color)
	damage_label.add_theme_color_override("font_outline_color", Color("#241522"))
	damage_label.add_theme_constant_override("outline_size", 5 if damage >= 40 else 4)
	damage_label.z_index = 3100
	damage_label.scale = Vector2(0.82, 0.82)
	damage_label.set_meta("combat_feedback_kind", "damage")
	damage_label.set_meta("damage_number_lane", lane)
	root.effect_root.add_child(damage_label)
	var tween = root.create_tween().set_parallel(true)
	tween.tween_property(damage_label, "position:y", damage_label.position.y - 32.0, 0.52).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(damage_label, "scale", Vector2.ONE * _damage_number_scale(damage), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(damage_label, "modulate:a", 0.0, 0.52).set_delay(0.15)
	tween.chain().tween_callback(damage_label.queue_free)

func spawn_growth_preparation_feedback(position: Vector2, preparation_name: String) -> void:
	var feedback_label = Label.new()
	feedback_label.text = "집중 준비 · %s" % preparation_name
	feedback_label.position = position + Vector2(-100, -126)
	feedback_label.size = Vector2(200, 30)
	feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_override("font", UI_FONT)
	feedback_label.add_theme_font_size_override("font_size", 15)
	feedback_label.add_theme_color_override("font_color", Color("#ffe08a"))
	feedback_label.add_theme_color_override("font_outline_color", Color("#241522"))
	feedback_label.add_theme_constant_override("outline_size", 5)
	feedback_label.z_index = 3200
	feedback_label.scale = Vector2(0.82, 0.82)
	feedback_label.set_meta("combat_feedback_kind", "growth_preparation")
	root.effect_root.add_child(feedback_label)
	var tween = root.create_tween().set_parallel(true)
	tween.tween_property(feedback_label, "position:y", feedback_label.position.y - 24.0, 1.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(feedback_label, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(feedback_label, "modulate:a", 0.0, 0.55).set_delay(0.80)
	tween.chain().tween_callback(feedback_label.queue_free)

func _next_damage_number_lane(position: Vector2) -> int:
	var key := "%d:%d" % [roundi(position.x / 48.0), roundi(position.y / 48.0)]
	var now := Time.get_ticks_msec()
	var row: Dictionary = damage_number_lanes.get(key, {})
	var lane := 0
	if not row.is_empty() and now - int(row.get("last_msec", 0)) <= DAMAGE_NUMBER_LANE_WINDOW_MSEC:
		lane = (int(row.get("lane", 0)) + 1) % DAMAGE_NUMBER_LANE_OFFSETS.size()
	damage_number_lanes[key] = {"lane": lane, "last_msec": now}
	return lane

func _damage_number_font_size(damage: int) -> int:
	return 16 + min(8, int(floor(float(max(0, damage)) / 12.0)))

func _damage_number_scale(damage: int) -> float:
	if damage >= 55:
		return 1.18
	if damage >= 30:
		return 1.08
	return 1.0

func camera_kick(amount: float) -> void:
	if root.combat_camera == null or not root.combat_camera.enabled:
		return
	if camera_kick_cooldown > 0.0:
		return
	camera_kick_cooldown = 0.10
	root.combat_camera.offset = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
	var tween = root.create_tween()
	tween.tween_property(root.combat_camera, "offset", Vector2.ZERO, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func spawn_effect_burst(effect_id: String, position: Vector2, offset: Vector2 = Vector2.ZERO, effect_scale: Vector2 = Vector2.ONE, fps: float = 14.0) -> void:
	var sprite = _make_effect_sprite(effect_id, false, fps)
	if sprite == null:
		return
	sprite.global_position = position + offset
	sprite.scale = effect_scale
	sprite.z_index = 3000
	root.effect_root.add_child(sprite)
	var tween = root.create_tween()
	tween.tween_interval(0.28)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.12)
	tween.tween_callback(sprite.queue_free)

func _make_effect_sprite(effect_id: String, loop: bool, fps: float) -> AnimatedSprite2D:
	var sprite = AnimatedSprite2D.new()
	var frames = SpriteFrames.new()
	frames.add_animation("play")
	frames.set_animation_loop("play", loop)
	frames.set_animation_speed("play", fps)
	var sequence: Array = root.effect_frame_sets.get(effect_id, [])
	for texture in sequence:
		if texture != null:
			frames.add_frame("play", texture)
	if frames.get_frame_count("play") == 0:
		var fallback = root.effect_textures.get(effect_id)
		if fallback == null:
			return null
		frames.add_frame("play", fallback)
	sprite.sprite_frames = frames
	sprite.animation = "play"
	sprite.play("play")
	return sprite
