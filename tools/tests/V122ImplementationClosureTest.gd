extends Node

const MATRIX_PATH := "res://docs/audit/v122/V122_IMPLEMENTATION_CLOSURE_MATRIX.json"
const ENEMIES_PATH := "res://data/regular_version/update4/enemies.json"
const ASSET_MANIFEST_PATH := "res://data/regular_version/update4/asset_manifest.json"
const OUTPOST_PATH := "res://data/regular_version/update4/outpost_encounters.json"
const OUTPOST_SERVICE_PATH := "res://scripts/systems/outpost/OutpostEncounterService.gd"
const ONBOARDING_PATH := "res://data/onboarding_flow_dialogue_v0.4.json"
const GAME_ROOT_PATH := "res://scripts/game/GameRoot.gd"
const UPDATE4_REGION_ENEMY_IDS := [
	"coal_spark",
	"dusk_courier",
	"bronze_automaton",
	"shadow_duelist",
	"spore_doll",
	"root_tender",
]

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var matrix := _load_json(MATRIX_PATH)
	_expect(int(matrix.get("schema_version", 0)) == 1, "closure matrix schema")
	_expect(str(matrix.get("target_version", "")) == "1.2.2", "closure target version")
	var allowed: Array = matrix.get("allowed_statuses", [])
	var forbidden: Array = matrix.get("forbidden_statuses", [])
	var required_fields: Array = matrix.get("required_evidence_fields", [])
	_expect(allowed == ["IMPLEMENTED", "INTENTIONALLY_HIDDEN", "REMOVED"], "allowed statuses are frozen")
	_expect(forbidden.size() == 11, "all forbidden statuses are listed")
	_expect(required_fields.size() == 9, "all nine evidence fields are required")

	var feature_count := 0
	var forbidden_count := 0
	for feature_value in matrix.get("features", []):
		feature_count += 1
		if not feature_value is Dictionary:
			_expect(false, "feature row is a dictionary")
			continue
		var feature: Dictionary = feature_value
		var feature_id := str(feature.get("id", ""))
		var status := str(feature.get("status", ""))
		_expect(feature_id != "", "feature ID is present")
		_expect(allowed.has(status), "%s uses an allowed status" % feature_id)
		if forbidden.has(status):
			forbidden_count += 1
		for field_value in required_fields:
			var field := str(field_value)
			var refs := _as_array(feature.get(field, []))
			_expect(not refs.is_empty(), "%s has %s evidence" % [feature_id, field])
			for ref_value in refs:
				_audit_reference(str(ref_value), feature_id, field)
	_expect(feature_count == 15, "all 15 product feature groups are mapped")
	_expect(forbidden_count == 0, "forbidden implementation statuses are zero")

	for exception_value in matrix.get("semantic_exceptions", []):
		if not exception_value is Dictionary:
			_expect(false, "semantic exception is a dictionary")
			continue
		var exception: Dictionary = exception_value
		_expect(str(exception.get("term", "")) != "", "semantic exception term is present")
		_expect(allowed.has(str(exception.get("status", ""))), "semantic exception uses an allowed status")
		_expect(str(exception.get("reason", "")) != "", "semantic exception has a reason")

	_audit_update4_region_enemy_art()
	_audit_removed_product_placeholders()
	_audit_forbidden_runtime_literals(matrix.get("forbidden_runtime_literals", []))

	print(
		"V122_IMPLEMENTATION_CLOSURE_COVERAGE: %s"
		% JSON.stringify({
			"feature_groups": feature_count,
			"required_evidence_fields": required_fields.size(),
			"forbidden_statuses": forbidden_count,
			"region_enemy_visuals": UPDATE4_REGION_ENEMY_IDS.size()
		})
	)
	if failed:
		print("V122_IMPLEMENTATION_CLOSURE_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V122_IMPLEMENTATION_CLOSURE_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _audit_reference(ref: String, feature_id: String, field: String) -> void:
	_expect(ref.begins_with("res://"), "%s %s uses a repository resource" % [feature_id, field])
	if not ref.begins_with("res://"):
		return
	var parts := ref.split("#", false, 1)
	var path := parts[0]
	var exists := FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path))
	_expect(exists, "%s %s path exists: %s" % [feature_id, field, path])
	if parts.size() < 2 or not FileAccess.file_exists(path):
		return
	var symbol := str(parts[1])
	var source := FileAccess.get_file_as_string(path)
	_expect(
		source.contains("func %s(" % symbol),
		"%s %s handler exists: %s#%s" % [feature_id, field, path, symbol]
	)


func _audit_update4_region_enemy_art() -> void:
	var enemies := _load_json(ENEMIES_PATH)
	var manifest := _load_json(ASSET_MANIFEST_PATH)
	for enemy_id_value in UPDATE4_REGION_ENEMY_IDS:
		var enemy_id := str(enemy_id_value)
		var enemy: Dictionary = enemies.get(enemy_id, {})
		var sprite := str(enemy.get("sprite", ""))
		var manifest_id := str(enemy.get("asset_manifest_id", ""))
		_expect(not enemy.is_empty(), "Update 4 enemy exists: %s" % enemy_id)
		_expect(not bool(enemy.get("placeholder_art", true)), "%s uses production art" % enemy_id)
		_expect(int(enemy.get("frame_count", 0)) == 16, "%s uses the 4x4 frame contract" % enemy_id)
		_expect(sprite != "" and FileAccess.file_exists(sprite), "%s combat sprite exists" % enemy_id)
		_expect(manifest.has(manifest_id), "%s asset manifest entry exists" % enemy_id)
		var asset: Dictionary = manifest.get(manifest_id, {})
		_expect(str(asset.get("combat_sprite", "")) == sprite, "%s manifest points to runtime sprite" % enemy_id)
		var source_record := str(asset.get("source_record", ""))
		_expect(source_record != "" and FileAccess.file_exists(source_record), "%s source record exists" % enemy_id)
		_expect(int(asset.get("frame_contract", {}).get("frame_count", 0)) == 16, "%s manifest frame contract is complete" % enemy_id)


func _audit_removed_product_placeholders() -> void:
	var outpost := _load_json(OUTPOST_PATH)
	var encounter: Dictionary = outpost.get("outpost_fixed_four_modules", {})
	_expect(encounter.has("day10_wave"), "outpost encounter has product day10_wave key")
	_expect(not encounter.has("placeholder_wave"), "outpost placeholder_wave key is removed")
	var outpost_source := FileAccess.get_file_as_string(OUTPOST_SERVICE_PATH)
	_expect(outpost_source.contains("func run_trial("), "outpost service exposes product run_trial")
	_expect(not outpost_source.contains("run_placeholder_trial"), "outpost placeholder trial handler is removed")
	var onboarding_source := FileAccess.get_file_as_string(ONBOARDING_PATH)
	_expect(not onboarding_source.contains("정규판 TODO"), "onboarding has no exposed TODO label")
	var game_root_source := FileAccess.get_file_as_string(GAME_ROOT_PATH)
	_expect(not game_root_source.contains("다음 장 준비 중입니다"), "combat fallback has no exposed pending label")


func _audit_forbidden_runtime_literals(literals_value) -> void:
	var roots := [
		"res://scripts",
		"res://scenes",
		"res://data",
	]
	var files: Array[String] = ["res://project.godot"]
	for root_value in roots:
		_collect_files(str(root_value), files)
	var literals := _as_array(literals_value)
	for literal_value in literals:
		var literal := str(literal_value)
		var matches: Array[String] = []
		for path in files:
			var source := FileAccess.get_file_as_string(path)
			if source.to_lower().contains(literal.to_lower()):
				matches.append(path)
		_expect(matches.is_empty(), "forbidden runtime literal is absent: %s (%s)" % [literal, ", ".join(matches)])


func _collect_files(root: String, output: Array[String]) -> void:
	var dir := DirAccess.open(root)
	if dir == null:
		_expect(false, "runtime scan root exists: %s" % root)
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name != "." and name != "..":
			var path := root.path_join(name)
			if dir.current_is_dir():
				_collect_files(path, output)
			elif name.get_extension().to_lower() in ["gd", "tscn", "json", "godot"]:
				output.append(path)
		name = dir.get_next()
	dir.list_dir_end()


func _as_array(value) -> Array:
	return value if value is Array else [value]


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		return
	failed = true
	push_error(message)
