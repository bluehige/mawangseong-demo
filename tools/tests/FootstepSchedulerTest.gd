extends Node

const SchedulerScript = preload("res://scripts/audio/FootstepScheduler.gd")
const CatalogScript = preload("res://scripts/audio/AudioCatalogApi.gd")

var failed := false
var assertion_count := 0


class FakeDirector extends Node:
	var calls: Array[Dictionary] = []

	func play_event(
		event_id: String,
		volume_db: float,
		category: String,
		priority: int,
		event_group: String,
		instance_key: String,
		pitch_scale: float
	) -> Dictionary:
		calls.append({
			"event_id": event_id,
			"volume_db": volume_db,
			"category": category,
			"priority": priority,
			"event_group": event_group,
			"instance_key": instance_key,
			"pitch_scale": pitch_scale
		})
		return {"accepted": true, "event_id": event_id}


class FakeUnit extends Node2D:
	var velocity := Vector2.ZERO
	var simulation_speed := 1.0
	var combat_visual_profile: Dictionary = {"size_class": "normal", "motion_mode": "grounded"}
	var role := ""
	var down := false
	var alive := true

	func is_alive() -> bool:
		return alive


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var director := FakeDirector.new()
	add_child(director)
	var scheduler = SchedulerScript.new()
	scheduler.setup(director)
	_test_stage_and_mix_profiles(scheduler)
	_test_runtime_scheduling(scheduler, director)
	_test_catalog_resolution()
	if failed:
		print("FOOTSTEP_SCHEDULER_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("FOOTSTEP_SCHEDULER_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_stage_and_mix_profiles(scheduler) -> void:
	_expect(scheduler.surface_for_stage("stage_01_cave") == "cave_rough", "stage 01 uses rough cave footsteps")
	_expect(scheduler.surface_for_stage("stage_02_castle") == "castle_stone", "stage 02 uses castle stone footsteps")
	_expect(scheduler.surface_for_stage("stage_03_keep") == "castle_stone", "stage 03 uses castle stone footsteps")
	_expect(scheduler.surface_for_stage("stage_04_citadel") == "metal_passage", "stage 04 uses metal passage footsteps")
	_expect(scheduler.weight_for_profile({"size_class": "normal"}) == "normal", "normal size uses normal profile")
	_expect(scheduler.weight_for_profile({"size_class": "large"}) == "heavy", "large size uses heavy profile")
	_expect(scheduler.weight_for_profile({}, "boss") == "heavy", "boss role uses heavy fallback")
	var normal: Dictionary = scheduler.profile_for_weight("normal", 1.0)
	var heavy: Dictionary = scheduler.profile_for_weight("heavy", 1.0)
	var fast: Dictionary = scheduler.profile_for_weight("normal", 3.0)
	_expect(float(heavy["volume_db"]) > float(normal["volume_db"]), "heavy contact is louder")
	_expect(float(heavy["pitches"][0]) < float(normal["pitches"][0]), "heavy contact is lower pitched")
	_expect(float(fast["stride_distance"]) > float(normal["stride_distance"]) * 3.0, "x3 speed reduces contact density")
	_expect(float(fast["minimum_interval"]) > float(normal["minimum_interval"]) * 3.0, "x3 speed widens the real-time interval")


func _test_runtime_scheduling(scheduler, director: FakeDirector) -> void:
	var normal := FakeUnit.new()
	add_child(normal)
	normal.velocity = Vector2(100.0, 0.0)
	scheduler.update(0.5, [normal], "stage_01_cave", true)
	normal.global_position.x += 47.0
	var emitted: Array[String] = scheduler.update(0.5, [normal], "stage_01_cave", true)
	_expect(emitted.size() == 1, "moving grounded unit emits one footstep")
	_expect(str(emitted[0]).begins_with("footstep.cave_rough."), "runtime event follows current stage surface")
	_expect(director.calls.size() == 1, "director receives one normal contact")
	_expect(float(director.calls[0]["volume_db"]) == -18.5, "normal profile volume is routed")
	_expect(str(director.calls[0]["category"]) == "footstep", "footstep voice category is routed")

	scheduler.update(0.5, [normal], "stage_01_cave", true)
	_expect(director.calls.size() == 1, "static unit remains silent")
	normal.combat_visual_profile = {"size_class": "normal", "motion_mode": "flying"}
	normal.global_position.x += 80.0
	scheduler.update(0.5, [normal], "stage_01_cave", true)
	_expect(director.calls.size() == 1, "flying unit remains silent")

	scheduler.reset()
	var heavy := FakeUnit.new()
	heavy.combat_visual_profile = {"size_class": "large", "motion_mode": "grounded"}
	heavy.velocity = Vector2(100.0, 0.0)
	add_child(heavy)
	scheduler.update(0.6, [heavy], "stage_04_citadel", true)
	heavy.global_position.x += 59.0
	emitted = scheduler.update(0.6, [heavy], "stage_04_citadel", true)
	_expect(emitted.size() == 1, "heavy grounded unit emits one footstep")
	_expect(str(emitted[0]).begins_with("footstep.metal_passage."), "heavy contact follows stage 04 surface")
	_expect(float(director.calls[1]["volume_db"]) == -14.0, "heavy profile volume is routed")
	_expect(float(director.calls[1]["pitch_scale"]) <= 0.90, "heavy profile pitch is routed")


func _test_catalog_resolution() -> void:
	CatalogScript.reset_for_test()
	for surface in ["cave_rough", "castle_stone", "metal_passage"]:
		for variation in range(1, 4):
			var event_id := "footstep.%s.%02d" % [surface, variation]
			var resolved: Dictionary = CatalogScript.resolve_event(event_id)
			_expect(not resolved.is_empty(), "%s resolves to a runtime WAV" % event_id)


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  PASS - %s" % message)
		return
	failed = true
	push_error("  FAIL - %s" % message)
