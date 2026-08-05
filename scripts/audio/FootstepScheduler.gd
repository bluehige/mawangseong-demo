class_name FootstepScheduler
extends RefCounted

const FOOTSTEP_CATEGORY := "footstep"
const FOOTSTEP_PRIORITY := 50
const FOOTSTEP_GROUP := "footsteps"
const MOVEMENT_EPSILON := 1.0

const SURFACE_BY_STAGE := {
	"stage_01_cave": "cave_rough",
	"stage_02_castle": "castle_stone",
	"stage_03_keep": "castle_stone",
	"stage_04_citadel": "metal_passage"
}

const NORMAL_PITCHES := [0.96, 1.0, 1.04]
const HEAVY_PITCHES := [0.82, 0.86, 0.90]

var audio_director = null
var _unit_states: Dictionary = {}
var _contact_serial := 0


func setup(audio_director_value) -> void:
	audio_director = audio_director_value


func update(delta: float, units: Array, stage_id: String, enabled: bool = true) -> Array[String]:
	if not enabled:
		reset()
		return []
	var emitted: Array[String] = []
	var active_ids: Dictionary = {}
	for unit in units:
		if unit == null or not is_instance_valid(unit):
			continue
		var instance_id := int(unit.get_instance_id())
		active_ids[instance_id] = true
		var position := Vector2(unit.global_position)
		if not _unit_states.has(instance_id):
			_unit_states[instance_id] = {
				"last_position": position,
				"distance": 0.0,
				"cooldown": 0.0,
				"variation_index": posmod(instance_id, 3)
			}
			continue
		var state: Dictionary = _unit_states[instance_id]
		state["cooldown"] = maxf(0.0, float(state.get("cooldown", 0.0)) - delta)
		var previous_position: Vector2 = state.get("last_position", position)
		state["last_position"] = position
		if not _unit_can_step(unit):
			state["distance"] = 0.0
			continue
		var velocity_value = unit.get("velocity")
		var velocity: Vector2 = velocity_value if velocity_value is Vector2 else Vector2.ZERO
		var moved_distance := position.distance_to(previous_position)
		var plausible_distance := maxf(8.0, velocity.length() * delta * 1.5)
		state["distance"] = float(state.get("distance", 0.0)) + minf(moved_distance, plausible_distance)
		var simulation_speed := clampf(float(unit.get("simulation_speed")), 1.0, 3.0)
		var weight := weight_for_profile(unit.get("combat_visual_profile"), str(unit.get("role")))
		var profile := profile_for_weight(weight, simulation_speed)
		if float(state["distance"]) < float(profile["stride_distance"]):
			continue
		if float(state["cooldown"]) > 0.0:
			continue
		state["distance"] = fmod(float(state["distance"]), float(profile["stride_distance"]))
		state["cooldown"] = float(profile["minimum_interval"])
		var result := play_footstep_for_unit(unit, surface_for_stage(stage_id), state, profile)
		if bool(result.get("accepted", false)):
			emitted.append(str(result.get("event_id", "")))
	for instance_id_value in _unit_states.keys():
		if not active_ids.has(instance_id_value):
			_unit_states.erase(instance_id_value)
	return emitted


func play_footstep_for_unit(unit, surface: String, state: Dictionary, profile: Dictionary) -> Dictionary:
	if audio_director == null or not is_instance_valid(audio_director):
		return {"accepted": false, "reason": "audio_director_missing"}
	var variation_index := posmod(int(state.get("variation_index", 0)), 3)
	state["variation_index"] = variation_index + 1
	var pitches: Array = profile.get("pitches", NORMAL_PITCHES)
	var pitch_scale := float(pitches[variation_index])
	var event_id := "footstep.%s.%02d" % [surface, variation_index + 1]
	_contact_serial += 1
	return audio_director.play_event(
		event_id,
		float(profile["volume_db"]),
		FOOTSTEP_CATEGORY,
		FOOTSTEP_PRIORITY,
		FOOTSTEP_GROUP,
		"footstep:%d:%d" % [int(unit.get_instance_id()), _contact_serial],
		pitch_scale
	)


func surface_for_stage(stage_id: String) -> String:
	return str(SURFACE_BY_STAGE.get(stage_id, "castle_stone"))


func weight_for_profile(profile_value, role: String = "") -> String:
	var profile: Dictionary = profile_value if profile_value is Dictionary else {}
	var size_class := str(profile.get("size_class", "normal"))
	var normalized_role := role.strip_edges().to_lower()
	if size_class in ["large", "boss"] or normalized_role in ["boss", "tank", "guardian"]:
		return "heavy"
	return "normal"


func profile_for_weight(weight: String, simulation_speed: float) -> Dictionary:
	var heavy := weight == "heavy"
	var base_stride := 58.0 if heavy else 46.0
	var base_interval := 0.22 if heavy else 0.16
	var normalized_speed := clampf(simulation_speed, 1.0, 3.0)
	var density_scale := normalized_speed * 1.25 if normalized_speed > 1.5 else 1.0
	return {
		"weight": "heavy" if heavy else "normal",
		"stride_distance": base_stride * density_scale,
		"minimum_interval": base_interval * density_scale,
		"volume_db": -14.0 if heavy else -18.5,
		"pitches": HEAVY_PITCHES if heavy else NORMAL_PITCHES
	}


func reset() -> void:
	_unit_states.clear()


func _unit_can_step(unit) -> bool:
	if unit.has_method("is_alive") and not bool(unit.is_alive()):
		return false
	if bool(unit.get("down")):
		return false
	if unit is CanvasItem and not unit.is_visible_in_tree():
		return false
	var profile_value = unit.get("combat_visual_profile")
	var profile: Dictionary = profile_value if profile_value is Dictionary else {}
	if str(profile.get("motion_mode", "grounded")) == "flying":
		return false
	var velocity_value = unit.get("velocity")
	return velocity_value is Vector2 and velocity_value.length() > MOVEMENT_EPSILON
