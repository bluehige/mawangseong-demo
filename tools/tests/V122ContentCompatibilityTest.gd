extends Node

const MANIFEST_PATH := "res://data/v122/content_compatibility.json"
const SUITE_PATH := "res://tools/tests/core_verification_suite.json"

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	var manifest := _load_json(MANIFEST_PATH)
	var suite := _load_json(SUITE_PATH)
	_expect(int(manifest.get("schema_version", 0)) == 1, "content compatibility manifest schema")
	_expect(not suite.is_empty(), "core verification suite parses")
	var suite_checks := _suite_checks_by_id(suite)
	var coverage_required := 0
	var coverage_present := 0
	for update_id in ["update2", "update3", "update4"]:
		var update: Dictionary = manifest.get("updates", {}).get(update_id, {})
		_audit_catalog_counts(update_id, update.get("catalog_counts", {}))
		for check_id_value in update.get("quick_and_full_checks", []):
			coverage_required += 1
			if _audit_suite_check(str(check_id_value), suite_checks, true):
				coverage_present += 1
		for check_id_value in update.get("full_only_checks", []):
			coverage_required += 1
			if _audit_suite_check(str(check_id_value), suite_checks, false):
				coverage_present += 1
	_audit_runtime_merges()
	_audit_endings(manifest.get("endings", {}), suite_checks)
	var coverage_percent := (
		100.0 * float(coverage_present) / float(coverage_required)
		if coverage_required > 0
		else 0.0
	)
	_expect(coverage_present == coverage_required, "Update 2~4 check coverage is 100%%")
	print(
		"V122_CONTENT_COMPATIBILITY_COVERAGE: %s"
		% JSON.stringify({
			"required_checks": coverage_required,
			"covered_checks": coverage_present,
			"coverage_percent": snappedf(coverage_percent, 0.001),
			"ending_codes": 23
		})
	)
	if failed:
		print("V122_CONTENT_COMPATIBILITY_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V122_CONTENT_COMPATIBILITY_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _audit_catalog_counts(update_id: String, catalog_counts: Dictionary) -> void:
	for path_value in catalog_counts.keys():
		var path := str(path_value)
		var catalog := _load_json(path)
		_expect(
			catalog.size() == int(catalog_counts[path_value]),
			"%s catalog count %s=%d" % [update_id, path.get_file(), catalog.size()]
		)


func _audit_suite_check(check_id: String, suite_checks: Dictionary, require_quick: bool) -> bool:
	var check_value = suite_checks.get(check_id)
	var exists := check_value is Dictionary
	_expect(exists, "core suite check exists: %s" % check_id)
	if not exists:
		return false
	var check: Dictionary = check_value
	var modes: Array = check.get("modes", [])
	var mode_ok := modes.has("full") and (modes.has("quick") if require_quick else true)
	_expect(mode_ok, "core suite modes cover %s" % check_id)
	var scene := str(check.get("scene", ""))
	var scene_ok := scene != "" and ResourceLoader.exists(scene)
	_expect(scene_ok, "core suite scene exists: %s" % check_id)
	return mode_ok and scene_ok


func _audit_runtime_merges() -> void:
	_expect(DataRegistry.update2_contracts.size() == 5, "Update 2 contracts loaded by DataRegistry")
	_expect(DataRegistry.update2_counterforce.size() == 7, "Update 2 counterforce loaded by DataRegistry")
	_expect(DataRegistry.update2_seeded_campaign.size() == 3, "Update 2 seeded campaign loaded by DataRegistry")
	_expect(DataRegistry.leon_adaptive_stances.size() == 4, "Update 2 Leon stances loaded by DataRegistry")
	_expect(DataRegistry.cycle_doctrines.size() == 6, "Update 2 doctrines loaded by DataRegistry")
	_expect(DataRegistry.cycle_decrees.size() == 6, "Update 2 decrees loaded by DataRegistry")
	_expect(DataRegistry.challenge_seals.size() == 6, "Update 2 seals loaded by DataRegistry")

	_expect(_all_ids_merged(DataRegistry.update3_monster_extensions, DataRegistry.monsters), "Update 3 monsters merged into product catalog")
	_expect(_all_ids_merged(DataRegistry.update3_enemy_extensions, DataRegistry.enemies), "Update 3 enemies merged into product catalog")
	_expect(_all_ids_merged(DataRegistry.update3_endings, DataRegistry.ending_rules), "Update 3 endings merged into product catalog")
	for operation_id_value in DataRegistry.update3_front_operations.keys():
		var operation: Dictionary = DataRegistry.update3_front_operations[operation_id_value]
		var runtime_id := str(operation.get("raid_source_id", operation_id_value))
		_expect(DataRegistry.raid_missions.has(runtime_id), "Update 3 operation has product raid consumer: %s" % operation_id_value)

	_expect(_all_ids_merged(DataRegistry.update4_characters, DataRegistry.characters), "Update 4 characters merged into product catalog")
	_expect(_all_ids_merged(DataRegistry.update4_monsters, DataRegistry.monsters), "Update 4 monsters merged into product catalog")
	_expect(_all_ids_merged(DataRegistry.update4_skills, DataRegistry.skills), "Update 4 skills merged into product catalog")
	_expect(_all_ids_merged(DataRegistry.update4_enemies, DataRegistry.enemies), "Update 4 enemies merged into product catalog")
	_expect(_all_ids_merged(DataRegistry.update4_rival_bosses, DataRegistry.enemies), "Update 4 rival bosses merged into product catalog")
	_expect(_all_ids_merged(DataRegistry.update4_specializations, DataRegistry.specializations), "Update 4 specializations merged into product catalog")
	_expect(_all_ids_merged(DataRegistry.update4_monster_instances, DataRegistry.monster_instances), "Update 4 monster instances merged into product catalog")
	_expect(_all_ids_merged(DataRegistry.update4_run_metric_definitions, DataRegistry.run_metric_definitions), "Update 4 metrics merged into product catalog")
	_expect(_all_ids_merged(DataRegistry.update4_council_endings, DataRegistry.ending_rules), "Update 4 endings merged into product catalog")


func _audit_endings(endings: Dictionary, suite_checks: Dictionary) -> void:
	var expected_codes: Array = endings.get("expected_catalog_codes", [])
	var actual_codes: Array[String] = []
	for ending_id_value in DataRegistry.ending_rules.keys():
		var ending: Dictionary = DataRegistry.ending_rules[ending_id_value]
		var code := str(ending.get("catalog_code", ""))
		if code != "":
			actual_codes.append(code)
		var illustration := str(ending.get("illustration", ""))
		_expect(illustration != "" and ResourceLoader.exists(illustration), "ending illustration exists: %s" % ending_id_value)
	actual_codes.sort()
	var expected_sorted: Array[String] = []
	for code_value in expected_codes:
		expected_sorted.append(str(code_value))
	expected_sorted.sort()
	_expect(actual_codes == expected_sorted, "ending catalog is continuous E00~E22")
	for check_id_value in endings.get("required_check_ids", []):
		_expect(suite_checks.has(str(check_id_value)), "ending check registered: %s" % check_id_value)


func _suite_checks_by_id(suite: Dictionary) -> Dictionary:
	var result := {}
	for check_value in suite.get("checks", []):
		if not check_value is Dictionary:
			continue
		var check: Dictionary = check_value
		var check_id := str(check.get("id", ""))
		_expect(check_id != "" and not result.has(check_id), "core suite check ID is unique: %s" % check_id)
		result[check_id] = check
	return result


func _all_ids_merged(source: Dictionary, target: Dictionary) -> bool:
	for id_value in source.keys():
		if not target.has(id_value):
			return false
	return true


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
