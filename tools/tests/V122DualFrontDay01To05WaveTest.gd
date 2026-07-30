extends Node

const WaveManagerScript = preload("res://scripts/combat/WaveManager.gd")
const EncounterAdapter = preload("res://scripts/v122/combat/V122EncounterAdapter.gd")

const CANDIDATE_LAYOUT_ID := "stage01_dual_front_candidate_01"
const LEGACY_LAYOUT_ID := "starting_layout"
const ROOT_SOURCE := "res://scripts/game/GameRoot.gd"

var failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_catalog_selection()
	_test_day_learning_contract()
	_test_runtime_lane_annotation()
	if failed:
		print("V122_DUAL_FRONT_DAY01_TO_05_WAVE_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("V122_DUAL_FRONT_DAY01_TO_05_WAVE_TEST: PASS")
		get_tree().quit(0)


func _test_catalog_selection() -> void:
	var candidate := DataRegistry.wave_catalog_for_layout(
		CANDIDATE_LAYOUT_ID,
		2,
		DataRegistry.waves
	)
	_expect(
		candidate.get("day_2", []) == DataRegistry.v122_dual_front_waves.get("day_2", []),
		"candidate layout selects the dual-front DAY 2 wave"
	)
	_expect(
		candidate.get("day_1", []) == DataRegistry.waves.get("day_1", []),
		"only the requested candidate day is overlaid"
	)
	var legacy := DataRegistry.wave_catalog_for_layout(
		LEGACY_LAYOUT_ID,
		2,
		DataRegistry.waves
	)
	_expect(legacy == DataRegistry.waves, "the product layout keeps the legacy wave catalog")
	var day_six := DataRegistry.wave_catalog_for_layout(
		CANDIDATE_LAYOUT_ID,
		6,
		DataRegistry.waves
	)
	_expect(day_six == DataRegistry.waves, "candidate DAY 6 and later keep the product catalog")
	_expect(
		_function_body(
			FileAccess.get_file_as_string(ROOT_SOURCE),
			"_active_wave_catalog"
		).contains("wave_catalog_for_layout"),
		"the live battle catalog selector consumes the layout-specific overlay"
	)


func _test_day_learning_contract() -> void:
	var schedules := {}
	for day in range(1, 6):
		var manager = WaveManagerScript.new()
		manager.setup(
			day,
			DataRegistry.wave_catalog_for_layout(
				CANDIDATE_LAYOUT_ID,
				day,
				DataRegistry.waves
			)
		)
		schedules[day] = manager.schedule
		_expect(not manager.schedule.is_empty(), "candidate DAY %d has a wave schedule" % day)
		for entry_value in manager.schedule:
			var entry: Dictionary = entry_value
			_expect(
				str(entry.get("lane_id", "")) in ["lane_a", "lane_b"],
				"candidate DAY %d assigns every enemy to a valid lane" % day
			)

	_expect(_lane_ids(schedules[1]) == {"lane_a": true}, "DAY 1 teaches lane A alone")
	for day in range(3, 6):
		_expect(_lane_ids(schedules[day]).size() == 2, "DAY %d pressures both lanes" % day)

	var day_two: Array = schedules[2]
	_expect(_has_spawn(day_two, "explorer", "lane_a", 0.0), "DAY 2 opens with a lane A assault")
	_expect(_has_spawn(day_two, "thief", "lane_b", 14.0), "DAY 2 warns and spawns the thief on lane B")
	var late_a_times := _spawn_times(day_two, "explorer", "lane_a", 20.0)
	var late_b_times := _spawn_times(day_two, "explorer", "lane_b", 20.0)
	_expect(late_a_times == [22.0, 30.0], "DAY 2 late lane A pressure spans eight seconds")
	_expect(late_b_times == [22.0, 30.0], "DAY 2 late lane B pressure spans the same eight seconds")

	_expect(schedules[3].size() == 5, "DAY 3 keeps optional-connector pressure small")
	_expect(schedules[4].size() == 6, "DAY 4 remains a preplacement-and-command encounter")
	_expect(schedules[5].size() > schedules[4].size(), "DAY 5 raises sustained dual-front pressure")
	for day in range(1, 6):
		for entry_value in schedules[day]:
			_expect(
				not entry_value.has("requires_connector"),
				"DAY %d never blocks battle start on connector ownership" % day
			)


func _test_runtime_lane_annotation() -> void:
	var manager = WaveManagerScript.new()
	manager.setup(
		2,
		DataRegistry.wave_catalog_for_layout(
			CANDIDATE_LAYOUT_ID,
			2,
			DataRegistry.waves
		)
	)
	var annotated := EncounterAdapter.annotate_schedule(
		manager.schedule,
		_battle_plan(),
		DataRegistry.enemies
	)
	_expect(
		_has_spawn_room(annotated, "explorer", "lane_a", "entrance"),
		"lane A wave entries resolve to the main entrance"
	)
	_expect(
		_has_spawn_room(annotated, "explorer", "lane_b", "service_entrance"),
		"lane B wave entries resolve to the service entrance"
	)
	_expect(
		_has_spawn_room(annotated, "thief", "lane_b", "service_entrance"),
		"the DAY 2 thief follows the initial lane B treasure slot"
	)


func _battle_plan() -> Dictionary:
	return {
		"primary_lane_id": "lane_a",
		"lane_routes": {
			"lane_a": ["entrance", "lane_a_front", "throne_antechamber", "throne"],
			"lane_b": ["service_entrance", "lane_b_front", "throne_antechamber", "throne"]
		},
		"lane_entries": {
			"lane_a": "entrance",
			"lane_b": "service_entrance"
		},
		"lane_labels": {
			"lane_a": "정문 전선",
			"lane_b": "서비스 침입 균열 전선"
		},
		"active_route": ["entrance", "lane_a_front", "throne_antechamber", "throne"],
		"route_start": "entrance",
		"rooms": [
			"entrance",
			"service_entrance",
			"lane_a_front",
			"lane_b_front",
			"throne_antechamber",
			"throne",
			"treasure"
		],
		"enemy_goals": ["throne"],
		"defense_zones": [
			{"zone_id": "zone_a_front", "lane_id": "lane_a", "anchor_room_id": "lane_a_front"},
			{"zone_id": "zone_b_front", "lane_id": "lane_b", "anchor_room_id": "lane_b_front"}
		],
		"facility_slots": [
			{
				"slot_id": "facility_b_rear",
				"room_id": "treasure",
				"facility_instance_id": "treasure",
				"lane_id": "lane_b",
				"linked_zone_ids": ["zone_b_front"],
				"facility_role": "treasure"
			}
		],
		"world_anchors": {
			"entrance": [1.0, 1.0],
			"service_entrance": [2.0, 2.0],
			"throne": [3.0, 3.0],
			"treasure": [4.0, 4.0]
		}
	}


func _lane_ids(schedule: Array) -> Dictionary:
	var result := {}
	for entry_value in schedule:
		if entry_value is Dictionary:
			result[str(entry_value.get("lane_id", ""))] = true
	return result


func _has_spawn(
	schedule: Array,
	enemy_id: String,
	lane_id: String,
	time: float
) -> bool:
	for entry_value in schedule:
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		if (
			str(entry.get("enemy_id", "")) == enemy_id
			and str(entry.get("lane_id", "")) == lane_id
			and is_equal_approx(float(entry.get("time", -1.0)), time)
		):
			return true
	return false


func _spawn_times(
	schedule: Array,
	enemy_id: String,
	lane_id: String,
	minimum_time: float
) -> Array:
	var result: Array = []
	for entry_value in schedule:
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		if (
			str(entry.get("enemy_id", "")) == enemy_id
			and str(entry.get("lane_id", "")) == lane_id
			and float(entry.get("time", -1.0)) >= minimum_time
		):
			result.append(float(entry.get("time", 0.0)))
	return result


func _has_spawn_room(
	schedule: Array,
	enemy_id: String,
	lane_id: String,
	spawn_room_id: String
) -> bool:
	for entry_value in schedule:
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		if (
			str(entry.get("enemy_id", "")) == enemy_id
			and str(entry.get("lane_id", "")) == lane_id
			and str(entry.get("spawn_room_id", "")) == spawn_room_id
		):
			return true
	return false


func _function_body(source: String, function_name: String) -> String:
	var marker := "func %s(" % function_name
	var start := source.find(marker)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + marker.length())
	return source.substr(start, source.length() - start) if next < 0 else source.substr(start, next - start)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
