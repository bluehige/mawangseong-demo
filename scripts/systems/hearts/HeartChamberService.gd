extends RefCounted
class_name HeartChamberService

const ROOM_ID := "heart_chamber"
const PATH_ID := "heart_chamber_path"
const MODULE_ID := "room_heart_chamber_01"
const ORIGINAL_ENEMY_GOAL := "throne"
const HP_BY_STAGE := {2: 420, 3: 600, 4: 820}


static func should_spawn(active_run: Dictionary, stage_index: int) -> bool:
	return (
		stage_index >= 2
		and bool(active_run.get("front_selection_completed", false))
		and str(active_run.get("front_id", "")) not in ["", "front_hero_oath_legacy"]
	)


static func sync_active_run(active_run_value: Dictionary, stage_index: int) -> Dictionary:
	var active_run := active_run_value.duplicate(true)
	var heart: Dictionary = active_run.get("heart", {}).duplicate(true)
	if not should_spawn(active_run, stage_index):
		heart["chamber_spawned"] = false
		heart["chamber_hp"] = 0
		heart["chamber_max_hp"] = 0
		heart["disabled_this_battle"] = false
		active_run["heart"] = heart
		return active_run
	var maximum := hp_for_stage(stage_index)
	if str(heart.get("heart_id", "")) == "heart_dream_lantern" and bool(heart.get("awakened", false)):
		maximum = maxi(1, int(floor(float(maximum) * 0.85)))
	var old_maximum := int(heart.get("chamber_max_hp", 0))
	var current := int(heart.get("chamber_hp", 0))
	if old_maximum <= 0:
		current = maximum
	elif maximum > old_maximum and current > 0:
		current += maximum - old_maximum
	heart["chamber_spawned"] = true
	heart["chamber_max_hp"] = maximum
	heart["chamber_hp"] = clampi(current, 0, maximum)
	heart["disabled_this_battle"] = int(heart["chamber_hp"]) <= 0
	active_run["heart"] = heart
	return active_run


static func damage(active_run_value: Dictionary, amount: int) -> Dictionary:
	var active_run := active_run_value.duplicate(true)
	var heart: Dictionary = active_run.get("heart", {}).duplicate(true)
	if not bool(heart.get("chamber_spawned", false)) or int(heart.get("chamber_hp", 0)) <= 0:
		return {"ok": false, "active_run": active_run, "damage": 0, "castle_defeat": false, "fallback_goal": ORIGINAL_ENEMY_GOAL}
	var applied := mini(maxi(0, amount), int(heart.get("chamber_hp", 0)))
	heart["chamber_hp"] = int(heart.get("chamber_hp", 0)) - applied
	var disabled_now := int(heart["chamber_hp"]) <= 0
	heart["disabled_this_battle"] = disabled_now
	active_run["heart"] = heart
	var metrics: Dictionary = active_run.get("run_metrics_update3", {}).duplicate(true)
	metrics["heart_room_damage_taken"] = int(metrics.get("heart_room_damage_taken", 0)) + applied
	metrics["heart_room_target_events"] = int(metrics.get("heart_room_target_events", 0)) + 1
	if disabled_now:
		metrics["heart_room_disabled_count"] = int(metrics.get("heart_room_disabled_count", 0)) + 1
	active_run["run_metrics_update3"] = metrics
	return {"ok": applied > 0, "active_run": active_run, "damage": applied, "disabled": disabled_now, "castle_defeat": false, "fallback_goal": ORIGINAL_ENEMY_GOAL}


static func enemy_goal(active_run: Dictionary, original_goal: String = ORIGINAL_ENEMY_GOAL, prefers_heart: bool = true) -> String:
	var heart: Dictionary = active_run.get("heart", {})
	if prefers_heart and bool(heart.get("chamber_spawned", false)) and int(heart.get("chamber_hp", 0)) > 0:
		return ROOM_ID
	return original_goal


static func room_definition(active_run: Dictionary, stage_index: int) -> Dictionary:
	var heart: Dictionary = active_run.get("heart", {})
	var base_maximum := hp_for_stage(stage_index)
	var maximum := int(heart.get("chamber_max_hp", base_maximum)) if bool(heart.get("chamber_spawned", false)) else base_maximum
	return {
		"display_name": "마왕성 심장실",
		"type": "special",
		"hp": clampi(int(heart.get("chamber_hp", maximum)), 0, maximum),
		"max_hp": maximum,
		"max_monsters": 1,
		"facility_role": "heart_chamber",
		"castle_stage_level": stage_index,
		"fixed": true,
		"disabled": bool(heart.get("disabled_this_battle", false)),
		"debug_placeholder": true
	}


static func hp_for_stage(stage_index: int) -> int:
	return int(HP_BY_STAGE.get(clampi(stage_index, 2, 4), HP_BY_STAGE[2]))
